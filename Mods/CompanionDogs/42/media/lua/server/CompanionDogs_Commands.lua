local CD = CompanionDogs

CD.Server = CD.Server or {}

local function resolveAnimal(args)
    if args.__animal then return args.__animal end
    if args.id then return getAnimal(tonumber(args.id)) end
    return nil
end

local function notifyOwner(owner, command, args)
    if isServer() then
        sendServerCommand(owner, CD.MODULE, command, args)
    elseif owner and CD.clientNotify then
        CD.clientNotify(command, args)
    end
end

CD.Server.spawn = function(player, args)
    if not CD.debugAllowed(player) then return end
    local atype = args.type or "dogmale"
    if not CD.TYPES[atype] then return end
    local kind = (args.kind and CD.BREEDS[args.kind]) and args.kind or CD.DEFAULT_BREED
    local animal = CD.spawnDog(args.x, args.y, args.z, atype, CD.breedEngineName(kind))
    if animal then
        CD.setBreed(animal, kind)
        CD.transmit(animal)
    end
end

-- Consome o item alimentado AUTORITATIVAMENTE no server (espelha IsoGameCharacter:Eat). Fazer a remocao aqui (nunca
-- no client) significa que um jogador normal nunca emite o pacote SyncItemDelete bloqueado por EditItem que o
-- papel "user" padrao nao tem permissao e que o AntiCheatPermission kicka (primeira ofensa). UseAndSync
-- tambem roteia comida embalada por ReplaceOnUse (deixa a lata vazia), diferente do antigo inv:Remove do client que
-- deletava o container inteiro. Retorna true quando o chamador deve creditar o cao: true se nao havia nada a
-- consumir (fallback legado/SP/foodVal<=0: sem foodId) OU o item foi achado e consumido; false quando um foodId foi
-- dado mas o item ja sumiu (uma requisicao duplicada de spam-click chegando apos o primeiro consumo) para o
-- cao nao ser alimentado/domado duas vezes com um item.
local function cdConsumeFood(player, args)
    local id = tonumber(args.foodId)
    if not id then return true end
    local inv = player and player:getInventory()
    local food = inv and inv:getItemById(id)
    if not food then return false end
    local frac = tonumber(args.partialFrac)
    if frac and frac > 0 and frac < 0.99 then
        pcall(function()
            food:multiplyFoodValues(1 - frac)
            food:syncItemFields()
        end)
    else
        pcall(function()
            food:setHungChange(0)
            food:UseAndSync()
        end)
    end
    return true
end

-- Gasta a fonte de agua no server (edicao de fluido, segura contra anticheat). waterId resolve recursivamente, senao a primeira fonte.
local function cdConsumeWater(player, args)
    local inv = player and player:getInventory()
    if not inv then return false end
    local id = args and tonumber(args.waterId)
    local water = id and inv:getItemById(id)
    if not (water and water.getFluidContainer and water:getFluidContainer()) then
        local list = inv:getAllWaterFluidSources(true)
        water = (list and list:size() > 0) and list:get(0) or nil
    end
    if not water then return false end
    local ok = false
    pcall(function()
        local fc = water:getFluidContainer()
        if fc and not fc:isEmpty() then fc:removeFluid(0.2, false); ok = true end
        if water.syncItemFields then water:syncItemFields() end
    end)
    return ok
end

-- Define fome/sede de um companheiro com o fallback CharacterStat-ou-setter-legado, encapsulado para um handle defasado nao dar erro.
local function setNeed(animal, kind, value)
    pcall(function()
        local stats = animal:getStats()
        if kind == "thirst" then
            if CharacterStat then stats:set(CharacterStat.THIRST, value)
            elseif stats.setThirst then stats:setThirst(value) end
        else
            if CharacterStat then stats:set(CharacterStat.HUNGER, value)
            elseif stats.setHunger then stats:setHunger(value) end
        end
    end)
end

-- Se o item prestes a ser alimentado e toxico para caes. PRECISA ser lido antes de cdConsumeFood remove-lo/edita-lo.
local function cdFeedIsToxic(player, args)
    local id = tonumber(args.foodId)
    if not id or not player then return false end
    local food = player:getInventory():getItemById(id)
    return food ~= nil and CD.isBadDogFood(food)
end

-- Quantos caes vinculados o jogador possui, a partir do conjunto de tokens no ModData do jogador (mantido em tame/release/morte).
-- Local do mesmo arquivo (NAO um novo helper CD.* compartilhado) para ser seguro na VM do server (armadilha conhecida de cache defasado).
local function cdCompanionCount(player)
    local c = CD.playerData(player).companions
    if type(c) ~= "table" then return 0 end
    local n = 0
    for _ in pairs(c) do n = n + 1 end
    return n
end

CD.Server.feed = function(player, args)
    -- Resolve + checa posse ANTES de consumir comida: um companheiro ja-possuido nao pode ser alimentado (muito menos
    -- re-domado) por ninguem alem do dono. Backstop autoritativo de MP: o menu de contexto ja esconde a opcao de feed
    -- no companheiro de outra pessoa, isto cobre lag de sync / clients defasados. Retorna antes de consumir para o
    -- estranho nao desperdicar sua comida. Um cao selvagem (nao companheiro) passa para o caminho de domesticacao abaixo.
    local animal = resolveAnimal(args)
    if animal and CD.isDog(animal) and CD.isCompanion(animal) and not CD.isOwnedBy(animal, player) then
        notifyOwner(player, "notyourdog", { breed = CD.getBreed(animal) })
        return
    end
    local bad = cdFeedIsToxic(player, args)
    if not cdConsumeFood(player, args) then return end
    if not animal or not CD.isDog(animal) then return end

    -- O cao mastiga o que acabou de receber: pulsa a animacao de comer (cobre TANTO alimentar um companheiro na mao quanto alimentar um
    -- vadio para doma-lo, ja que ambos caem aqui). Cosmetico, transmitido + auto-limpante; dispara para comida boa OU ruim.
    if CD.pulseEatAnim then CD.pulseEatAnim(animal) end

    -- feed proporcional: o valor de fome da comida (fracao negativa 0..1) dirige o corte de fome e a confianca; recai para config fixa
    local raw = tonumber(args.hunger) or 0
    local red = (raw < 0) and math.min(-raw, 3.0) or 0
    local V = math.floor(red * 100 + 0.5)
    local trustGain = (V > 0) and (V * CD.feedTrustPerHunger()) or nil
    -- sede vem do ThirstChange do item (frutas hidratam, pao nao); ausente/positivo = sede intacta
    local rawT = tonumber(args.thirst) or 0
    local tCut = (rawT < 0) and math.min(-rawT, 1.0) or 0

    if CD.isCompanion(animal) then
        local d = CD.data(animal)
        pcall(function()
            local hungerCut = (red > 0) and red or CD.feedHungerRestore()
            setNeed(animal, "hunger", math.max(0, animal:getHunger() - hungerCut))
            if tCut > 0 then
                setNeed(animal, "thirst", math.max(0, animal:getThirst() - tCut))
            end
            local cap = d.maxHealth or 1
            -- Comida ruim nao custa vida DE IMEDIATO: a intoxicacao a drena gradualmente em updateUpkeep
            -- (ate o piso de 20%). So uma refeicao BOA cura, e nao enquanto ainda intoxicado (sem cura ate
            -- a doenca passar, casando com a regeneracao passiva suprimida).
            if not bad and not CD.isSick(animal) then
                animal:setHealth(math.min(cap, animal:getHealth() + CD.feedHealthBonus()))
            end
        end)
        if bad then
            CD.setLoyalty(animal, math.max(0, CD.loyalty(animal) - CD.TOXIC_LOYALTY_PENALTY))
            CD.addCombatStress(animal, CD.TOXIC_STRESS)
            d.sickUntilMin = CD.worldMinutes() + CD.TOXIC_SICK_MIN
            notifyOwner(player, "sick", { id = animal:getOnlineID(), breed = CD.getBreed(animal) })
        else
            CD.setLoyalty(animal, math.min(CD.TRUST_MAX, CD.loyalty(animal) + (trustGain or CD.FEED_LOYALTY_GAIN)))
            CD.addCombatStress(animal, -0.4)
            d.lastWarn = nil
            notifyOwner(player, "fed", { id = animal:getOnlineID(), breed = CD.getBreed(animal) })
        end
        CD.transmit(animal)
        return
    end

    -- Comida toxica nunca constroi confianca com um vadio; em vez disso azeda o cao contra voce.
    if bad then
        CD.setTrust(animal, math.max(0, CD.getTrust(animal) - CD.TOXIC_TRUST_PENALTY))
        notifyOwner(player, "sick", { id = animal:getOnlineID(), breed = CD.getBreed(animal) })
        CD.transmit(animal)
        return
    end

    CD.setTrust(animal, CD.getTrust(animal) + (trustGain or CD.feedTrustGain()))

    if CD.getTrust(animal) >= CD.tameThreshold() then
        -- limite MaxCompanions (0 = desligado): bloqueia domar um cao NOVO quando o jogador esta no seu teto. A opcao de feed
        -- do cao selvagem ja esta vermelha/desabilitada client-side; este e o backstop autoritativo do server.
        local lim = CD.maxCompanions()
        if lim > 0 and cdCompanionCount(player) >= lim then
            notifyOwner(player, "limitreached", { max = lim })
            CD.transmit(animal)
            return
        end
        -- Um delete de admin (ou qualquer remocao externa) deixa pd.token pendurado num cao que nao
        -- existe mais; limpa o vinculo orfao para esta domesticacao seguir limpa.
        local pd = CD.playerData(player)
        if pd.token ~= nil and not CD.hasRecoverableCompanion(player) then
            pd.token = nil
            pd.name = nil
            pd.stash = nil
            player:transmitModData()
        end
        -- Multi-cao: domar NUNCA abandona o companheiro atual. O cao novo se torna o ATIVO; o
        -- cao ativo anterior (se carregado) se torna um fica-em-casa passivo. Sem dialogo de troca, sem release.
        local prev = CD.getCompanionAnimal(player)
        CD.makeCompanion(animal, player)
        if prev and prev ~= animal then
            CD.setState(prev, CD.STATE_STAY)
            CD.transmit(prev)
        end
        -- Sincroniza o novo token ativo do dono (pd.token/name/companions, setado por makeCompanion) para o client. Num
        -- dedicated server o ModData do jogador nao e compartilhado entre VMs, entao sem isto o cao recem-domado le
        -- como nao-ativo client-side (sem auto-select, cor errada no marcador do mapa). SP/coop-host so funcionavam compartilhando uma VM.
        player:transmitModData()
        local targs = { id = animal:getOnlineID(), breed = CD.getBreed(animal) }
        if not isServer() then targs.animal = animal end
        notifyOwner(player, "tamed", targs)
    else
        notifyOwner(player, "trust",
            { id = animal:getOnlineID(), trust = CD.getTrust(animal), max = CD.tameThreshold(), breed = CD.getBreed(animal) })
    end
    CD.transmit(animal)
end

-- Debug: aumenta as necessidades do cao sob demanda para validar comportamento de warn/bark/panic sem esperar o relogio do mundo.
-- Bloqueado exatamente como CD.Server.spawn (sandbox AllowDebugSpawn + admin num dedicated server). Deltas sao fracoes
-- 0..1 (o menu envia 0.10 = "+10"). Fome/sede sao nativas (setadas como CD.Server.feed/water); estresse passa
-- por addCombatStress, o acumulador aditivo que persiste e que CD.getStress soma (d.stress seria
-- recomputado das necessidades a cada tick de upkeep e perdido).
CD.Server.debugneeds = function(player, args)
    if not CD.debugAllowed(player) then return end
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    local dh = tonumber(args.hunger) or 0
    local dt = tonumber(args.thirst) or 0
    local ds = tonumber(args.stress) or 0
    pcall(function()
        if dh ~= 0 then setNeed(animal, "hunger", math.max(0, math.min(1, animal:getHunger() + dh))) end
        if dt ~= 0 then setNeed(animal, "thirst", math.max(0, math.min(1, animal:getThirst() + dt))) end
    end)
    if ds ~= 0 then CD.addCombatStress(animal, ds) end
    CD.transmit(animal)
end

-- Debug: aumenta (+1) ou define um nivel de skill. args.skill = uma key de skill ou "all"; args.bump ou args.set = <nivel>.
CD.Server.debugskill = function(player, args)
    if not CD.debugAllowed(player) then return end
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    local list = (args.skill == "all") and { "scent", "combat", "obedience", "hunt" } or { args.skill }
    for _, sk in ipairs(list) do
        if sk then
            local target
            if args.bump then target = CD.getSkillLevel(animal, sk) + 1
            elseif args.set ~= nil then target = tonumber(args.set) end
            if target then CD.setSkillLevel(animal, sk, target) end
        end
    end
end

CD.Server.water = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isCompanion(animal) or not CD.isOwnedBy(animal, player) then return end
    if not cdConsumeWater(player, args) then return end
    pcall(function()
        setNeed(animal, "thirst", math.max(0, animal:getThirst() - CD.waterThirstRestore()))
    end)
    if CD.pulseDrinkAnim then CD.pulseDrinkAnim(animal) end
    CD.setLoyalty(animal, math.min(CD.TRUST_MAX, CD.loyalty(animal) + CD.PET_LOYALTY_GAIN))
    CD.addCombatStress(animal, -0.2)
    local d = CD.data(animal)
    if d.lastWarn == "thirsty" then d.lastWarn = nil end
    notifyOwner(player, "watered", { id = animal:getOnlineID(), breed = CD.getBreed(animal) })
    CD.transmit(animal)
end

-- Equipa uma bolsa lateral num companheiro: remove o item da bolsa do inventario do dono server-side (seguro contra anticheat,
-- espelha placedish), migra qualquer coisa que o jogador pre-carregou na bolsa para os registros da bolsa, e guarda
-- a bolsa no ModData do cao. A carga vive em CD.data(dog).bag (acompanha o re-attach do copyFrom); um container vivo
-- nunca e mantido no animal. O attach visual e aplicado pela camada visual (CD.applyBagVisual), se presente.
CD.Server.equipsaddlebag = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isCompanion(animal) or not CD.isOwnedBy(animal, player) then return end
    if CD.hasBag(animal) then notifyOwner(player, "bagalready", {}); return end
    local inv = player and player:getInventory()
    local item = inv and args.itemId and inv:getItemById(tonumber(args.itemId))
    if not item or not CD.isSaddlebagType(item:getFullType()) then return end
    -- Mantem qualquer coisa que o jogador pre-carregou no proprio container da bolsa.
    local records = {}
    pcall(function()
        if item.getInventory and item:getInventory() then records = CD.serializeBag(item:getInventory()) end
    end)
    -- Remove do container REAL do item (pode ser uma sub-bolsa), em rede server-side -> sem kick de anticheat.
    local cont = (item.getContainer and item:getContainer()) or inv
    if isServer() then pcall(function() sendRemoveItemFromContainer(cont, item) end) end
    pcall(function() cont:Remove(item) end)
    CD.data(animal).bag = { equipped = true, cap = CD.bagCapacity(animal), items = records }
    if CD.applyBagVisual then pcall(function() CD.applyBagVisual(animal) end) end
    if CD.kennelSnapshot then CD.kennelSnapshot(player, animal) end
    CD.transmit(animal)
    notifyOwner(player, "bagequipped", { id = animal:getOnlineID(), name = CD.data(animal).name })
end

-- Desequipa: reconstroi o item da bolsa lateral com sua carga de volta dentro e a larga no tile do cao (drop no mundo
-- seguro contra anticheat, como placedish), depois limpa a bolsa do cao.
CD.Server.unequipsaddlebag = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isCompanion(animal) or not CD.isOwnedBy(animal, player) then return end
    if not CD.hasBag(animal) then return end
    local d = CD.data(animal)
    local sq = nil
    pcall(function() sq = animal:getCurrentSquare() end)
    if not sq then pcall(function() sq = animal:getSquare() end) end
    if not sq then pcall(function() sq = player:getCurrentSquare() end) end
    if sq then
        pcall(function()
            local bagItem = instanceItem(CD.SADDLEBAG_TYPE)
            if bagItem then
                CD.rehydrateBag(bagItem:getInventory(), d.bag.items)
                sq:AddWorldInventoryItem(bagItem, 0.5, 0.5, 0.0)
            end
        end)
    end
    d.bag = nil
    if CD.kennelSnapshot then CD.kennelSnapshot(player, animal) end   -- sem isto o recall re-equiparia a bolsa largada
    if CD.removeBagVisual then pcall(function() CD.removeBagVisual(animal) end) end
    CD.transmit(animal)
    notifyOwner(player, "bagunequipped", { id = animal:getOnlineID(), name = d.name })
end

-- Envia a bolsa atual do cao (capacidade + registros) ao dono para a janela de bolsa do client poder abrir/refrescar.
local function cdSendBagData(player, animal)
    local b = CD.data(animal).bag
    if not b or not b.equipped then return end
    b.cap = CD.bagCapacity(animal)   -- re-deriva do gene ao vivo; nunca confie no client
    notifyOwner(player, "bagdata", { id = animal:getOnlineID(), cap = b.cap, items = b.items or {} })
end

CD.Server.bagopen = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isCompanion(animal) or not CD.isOwnedBy(animal, player) then return end
    if not CD.hasBag(animal) then return end
    cdSendBagData(player, animal)
end

-- Deposita um item do inventario do dono na bolsa do cao (autoritativo no server): remove o item
-- de forma segura contra anticheat e anexa seu registro. Recusa quando cheia ou quando o item e um container nao-vazio (os
-- registros planos nao conseguem preservar conteudos aninhados).
CD.Server.bagput = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isCompanion(animal) or not CD.isOwnedBy(animal, player) then return end
    if not CD.hasBag(animal) then return end
    local inv = player and player:getInventory()
    local item = inv and args.itemId and inv:getItemById(tonumber(args.itemId))
    if not item or CD.isSaddlebagType(item:getFullType()) then return end
    if instanceof(item, "AnimalInventoryItem") then return end       -- nunca deposita o proprio cao
    local equipped = false
    pcall(function() equipped = item:isEquipped() end)               -- bloqueia roupa vestida / arma na mao
    if equipped then return end
    local nested = false
    pcall(function() local ci = item.getInventory and item:getInventory(); if ci and ci:getItems():size() > 0 then nested = true end end)
    if nested then return end
    local d = CD.data(animal)
    d.bag.items = d.bag.items or {}
    if CD.bagWeight(d.bag.items) + CD.itemWeight(item) > CD.bagCapacity(animal) then notifyOwner(player, "bagfull", {}); return end
    local rec = CD.serializeItem(item)
    local cont = (item.getContainer and item:getContainer()) or inv
    if isServer() then pcall(function() sendRemoveItemFromContainer(cont, item) end) end
    pcall(function() cont:Remove(item) end)
    table.insert(d.bag.items, rec)
    if CD.kennelSnapshot then CD.kennelSnapshot(player, animal) end   -- bolsa fresca no canil (recall preserva o cargo)
    CD.transmit(animal)
    cdSendBagData(player, animal)
end

-- Retira um item (por indice) da bolsa do cao de volta ao inventario do dono (autoritativo no server, sincronizado em MP
-- via InventoryItem:SynchSpawn -> sendAddItemToContainer).
CD.Server.bagtake = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isCompanion(animal) or not CD.isOwnedBy(animal, player) then return end
    if not CD.hasBag(animal) then return end
    local d = CD.data(animal)
    local idx = tonumber(args.index)
    if not idx or not d.bag.items or not d.bag.items[idx] then return end
    local rec = table.remove(d.bag.items, idx)
    local it = CD.bagItemFromRecord(rec)
    if it then
        local inv = player:getInventory()
        pcall(function() inv:AddItem(it) end)
        pcall(function() it:SynchSpawn() end)
    end
    if CD.kennelSnapshot then CD.kennelSnapshot(player, animal) end   -- bolsa fresca no canil (recall nao ressuscita item retirado)
    CD.transmit(animal)
    cdSendBagData(player, animal)
end

CD.Server.pet = function(player, args)
    if not CD.bondingEnabled() then return end
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isCompanion(animal) or not CD.isOwnedBy(animal, player) then return end
    local d = CD.data(animal)
    local now = CD.worldMinutes()
    if d.lastPetMin and (now - d.lastPetMin) < CD.petCooldownMin() then
        notifyOwner(player, "petcooldown", { id = animal:getOnlineID(), breed = CD.getBreed(animal) })
        return
    end
    d.lastPetMin = now
    d.petCalmMin = now

    pcall(function() animal:petAnimal(player) end)
    CD.addCombatStress(animal, -CD.PET_STRESS_RELIEF)
    CD.setLoyalty(animal, math.min(CD.TRUST_MAX, CD.loyalty(animal) + CD.PET_LOYALTY_GAIN))
    notifyOwner(player, "petted", { id = animal:getOnlineID(), breed = CD.getBreed(animal) })
    CD.transmit(animal)
end

CD.Server.setstate = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isOwnedBy(animal, player) then return end
    local state = args.state
    if state ~= CD.STATE_FOLLOW and state ~= CD.STATE_STAY and state ~= CD.STATE_GUARD then return end
    CD.setState(animal, state)
    -- Mantem o estado do snapshot de recuperacao do cao ativo correto AGORA (senao so refresca a cada ~20 ticks), para uma
    -- saida de RV logo apos um Stay/Guard nao ler um FOLLOW defasado e arrastar o cao estacionado para fora do interior.
    if CD.stampActiveSnapshotState then CD.stampActiveSnapshotState(player, animal, state) end
    if state == CD.STATE_STAY or state == CD.STATE_GUARD then
        -- Para AGORA em vez de esperar o loop de companheiro throttled, e levanta a flag blockMovement do behavior
        -- para o wanderIdle() da engine (que senao re-pateia o cao para um tile aleatorio +-8 a cada tick,
        -- sem gate isWild) o deixar parado. Esta e a metade instantanea do fix "Stay realmente fica"; o
        -- loop a re-afirma a cada tick que o cao deve segurar.
        pcall(function()
            local b = animal:getBehavior()
            if b and b.setBlockMovement then b:setBlockMovement(true) else animal:stopAllMovementNow() end
        end)
        if CD.clearClimbVars then CD.clearClimbVars(animal) end -- nao estaciona um cao em meio-salto em climbfence
    end
    if state == CD.STATE_GUARD then
        local d = CD.data(animal)
        d.guardX, d.guardY, d.guardZ = animal:getX(), animal:getY(), animal:getZ()
    end
    local d = CD.data(animal)
    d.standDown = (state ~= CD.STATE_GUARD) and true or nil
    local now = CD.worldMinutes()
    if not d.lastObeyXpMin or (now - d.lastObeyXpMin) >= CD.OBEDIENCE_XP_COOLDOWN_MIN then
        d.lastObeyXpMin = now
        CD.addSkillXP(animal, "obedience", CD.OBEDIENCE_XP_PER_CMD)
    end
    -- Estacionar/mudar de modo carimba o canil (posicao+estado frescos pro "visto por ultimo" da tela Meus Caes).
    if CD.kennelSnapshot then CD.kennelSnapshot(player, animal) end
    CD.transmit(animal)
end

CD.Server.setalertmode = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isOwnedBy(animal, player) then return end
    if args.mode then
        CD.setAlertMode(animal, args.mode)
    else
        CD.setSentinelSilent(animal, args.silent == true)
    end
    CD.transmit(animal)
end

CD.Server.setautoprotect = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isOwnedBy(animal, player) then return end
    CD.setAutoProtect(animal, args.on == true)
    CD.transmit(animal)
end

CD.Server.sethuntmode = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isOwnedBy(animal, player) then return end
    local on = args.on == true
    CD.setHuntMode(animal, on)
    if not on then
        -- sair do modo de caca descarta qualquer perseguicao/rastreio em andamento para o cao voltar ao dono limpo.
        local d = CD.data(animal)
        d.hunting = nil; d.huntTargetId = nil; d.woundedPrey = nil
        d.huntGoingSinceMin = nil; d.huntDeliverUntilMin = nil; d.huntCooling = nil
    end
    notifyOwner(player, "huntmode", { id = animal:getOnlineID(), on = on, breed = CD.getBreed(animal) })
    CD.transmit(animal)
end

-- Heartbeat do client do dono: o dono esta (ou acabou de parar de estar) numa acao vulneravel/estacionaria.
-- args.off limpa a janela imediatamente (acao terminou) para uma liberacao pronta; senao (re)armamos uma janela
-- de failsafe generosa. updateCompanion checa d.autoProtect + esta janela para fazer guarda-ancora no dono. Estado de
-- controle so do server, entao sem transmit (o behavior do cao e autoritativo no host).
CD.Server.setprotectactive = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isOwnedBy(animal, player) then return end
    if args.off then
        CD.data(animal).protectUntilMin = nil
    else
        CD.data(animal).protectUntilMin = CD.worldMinutes() + CD.AUTO_PROTECT_WINDOW_MIN
    end
end

-- Alvo de scout de forrageio do client do dono (o icone de forrageio REAL mais proximo perto do cao; veja
-- CompanionDogs_ForageScout.lua). O tryForagePoint do loop de companheiro leva o cao ate ele e aponta. Estado de controle
-- so do server com um TTL curto (o client re-envia a cada minuto de jogo enquanto fica), entao sem transmit.
CD.Server.foragescout = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isOwnedBy(animal, player) then return end
    if not args.x or not args.y then return end
    CD.data(animal).forageScoutTarget = {
        x = math.floor(args.x), y = math.floor(args.y), z = math.floor(args.z or 0),
        untilMin = CD.worldMinutes() + CD.HUNT_FORAGE_SCOUT_TTL_MIN,
    }
end

-- Recall/bring re-dispara o broadcast do attach da bag: o reapply server por-load e o broadcast "animal"/"attach"
-- sao one-shot (o slot fica non-nil pela sessao), entao um client que deu stream-out/in no cao parado perdeu a malha.
-- Idempotente e ja early-return em isClient dentro do applyBagVisual; o client tickBagVisuals e o backstop duravel.
local function reapplyBagVisual(animal)
    if animal and CD.hasBag(animal) then pcall(function() CD.applyBagVisual(animal) end) end
end

CD.Server.come = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isOwnedBy(animal, player) then return end
    CD.setState(animal, CD.STATE_FOLLOW)
    if not CD.isDisloyal(animal) then
        local d = CD.data(animal)
        local now = CD.worldMinutes()
        d.recallUntilMin = now + CD.RECALL_OVERRIDE_MIN
        d.standDown = true
        -- Limpa qualquer blockMovement segurado para o caminho de recall realmente dirigir o cao em nossa direcao (senao ele
        -- fica sem caminho e o root motion o manda na direcao errada).
        pcall(function()
            local b = animal:getBehavior()
            if b and b.setBlockMovement then b:setBlockMovement(false) end
        end)
        pcall(function() animal:pathToCharacter(player) end)
        -- Mesma correcao de causa-raiz do followOwner: pathToAux seta bPathfind=false numa linha livre, jogando o cao
        -- no AnimalWalkState sem caminho onde o root motion o leva PARA LONGE. Re-afirma bPathfind=true para ele entrar
        -- no AnimalPathFindState e o node mover o leve EM NOSSA DIRECAO (sintoma do "come" = "so um passo").
        pcall(function() animal:setVariable("bPathfind", true) end)
        if not d.lastObeyXpMin or (now - d.lastObeyXpMin) >= CD.OBEDIENCE_XP_COOLDOWN_MIN then
            d.lastObeyXpMin = now
            CD.addSkillXP(animal, "obedience", CD.OBEDIENCE_XP_PER_CMD)
        end
    else
        notifyOwner(player, "refused", { reason = CD.refusalReason(animal), name = CD.data(animal).name, breed = CD.getBreed(animal) })
    end
    reapplyBagVisual(animal)
    CD.transmit(animal)
end

-- Multi-cao: torna um companheiro possuido especifico o ATIVO do jogador (o cao que segue/luta/faz upkeep).
-- A ativacao e explicita (este comando ou domesticacao), nunca por proximidade. O cao ativo anterior vira
-- passivo e e fixado onde esta (tickCompanionInvincible o segura). Decisao: o cao selecionado tambem
-- comeca a FOLLOW para vir ate o dono (espelha o caminho de recall do CD.Server.come).
CD.Server.select = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isCompanion(animal) or not CD.isOwnedBy(animal, player) then return end
    local d = CD.data(animal)
    local pd = CD.playerData(player)
    -- Resolve o cao ativo antigo ANTES de trocar o token (getCompanionAnimal e ciente do token).
    local prev = CD.getCompanionAnimal(player)
    -- Torna este cao o ativo. Um companheiro legado pode ainda nao ter token -> cunha um.
    if d.companionToken == nil then
        pd.seq = (pd.seq or 0) + 1
        d.companionToken = pd.seq
    end
    pd.seq = math.max(pd.seq or 0, d.companionToken)
    -- Mantem o conjunto do limite de companheiros em sincronia (espelha makeCompanion).
    pd.companions = pd.companions or {}
    pd.companions[d.companionToken] = true
    pd.token = d.companionToken
    pd.name = d.name
    -- O cao ativo anterior (se for um diferente e carregado) vira um fica-em-casa passivo.
    if prev and prev ~= animal then
        CD.setState(prev, CD.STATE_STAY)
        -- Captura o XP mais recente do cao que vai congelar ANTES do handoff (passivo nao acumula mais).
        if CD.kennelSnapshot then CD.kennelSnapshot(player, prev) end
        CD.transmit(prev)
    end
    -- Se o cao ativo deslocado nao esta no mundo (carregado na mao / guardado num veiculo), getCompanionAnimal
    -- nao o enxerga, entao carimba o registro offline dele como passivo direto: ele restaura como STAY (nao FOLLOW) no drop/dismount.
    if pd.carried and pd.carried.data and pd.carried.data.companionToken ~= pd.token then
        pd.carried.data.state = CD.STATE_STAY
    end
    if pd.stash and pd.stash.data and pd.stash.data.companionToken ~= pd.token then
        pd.stash.data.state = CD.STATE_STAY
    end
    -- Ativa + vem ate mim. Reseta o relogio de upkeep para um cao muito tempo passivo nao despejar um catch-up de
    -- necessidades no instante em que e reativado.
    CD.setState(animal, CD.STATE_FOLLOW)
    d.lastUpkeepMin = nil
    d.standDown = true
    if not CD.isDisloyal(animal) then
        local now = CD.worldMinutes()
        d.recallUntilMin = now + CD.RECALL_OVERRIDE_MIN
        -- Limpa qualquer blockMovement segurado (a fixacao passiva) para o caminho de recall realmente dirigir o cao ate aqui.
        pcall(function()
            local b = animal:getBehavior()
            if b and b.setBlockMovement then b:setBlockMovement(false) end
        end)
        pcall(function() animal:pathToCharacter(player) end)
        pcall(function() animal:setVariable("bPathfind", true) end)
    end
    reapplyBagVisual(animal)
    CD.transmit(animal)
    if CD.kennelSnapshot then CD.kennelSnapshot(player, animal) end
    player:transmitModData()
    notifyOwner(player, "selected", { id = animal:getOnlineID(), name = d.name, breed = CD.getBreed(animal) })
end

-- Cruzar (concepcao explicita): o jogador escolhe dois companheiros seus (um macho + uma femea). Gate estrito
-- (reusa os helpers de posse/lealdade/saude/cap). Em sucesso a FEMEA ANDA ate o macho (CD.startBreedingApproach)
-- e concebe ao chegar; depois pari sozinha via CD.tickGestation. args.mateId = onlineID do segundo cao.
-- Gate PURO de elegibilidade de um par pra cruzar (sem notificar): resolve dam=femea-adulta / sire=macho-adulto
-- (so *female/*male tem esses sufixos -> filhote nunca entra), mesmo dono, toggle "Bloquear cruzamento", mesmo andar +
-- leash, saude, lealdade, alimentacao, femea nao-prenhe/sem breedTarget, cooldown e slot livre de cap. Retorna
-- ok, reason, dam, sire. Reusado pela acao explicita (CD.Server.breed) e pelo cruzamento passivo (tickPassiveBreeding).
function CD.breedEligible(a, b)
    if not a or not b or a == b or not CD.isDog(a) or not CD.isDog(b) then return false, "invalid" end
    if not (CD.isCompanion(a) and CD.isCompanion(b)) then return false, "invalid" end
    local sa, sb = CD.animalSex(a), CD.animalSex(b)
    local dam, sire
    if sa == "female" and sb == "male" then dam, sire = a, b
    elseif sa == "male" and sb == "female" then dam, sire = b, a
    else return false, "sex" end
    local owner = CD.getOwnerPlayer(dam)
    if not owner or not CD.isOwnedBy(sire, owner) then return false, "owner", dam, sire end
    local dd, sd = CD.data(dam), CD.data(sire)
    if dd.breedingOff or sd.breedingOff then return false, "off", dam, sire end
    if math.floor(dam:getZ()) ~= math.floor(sire:getZ()) or CD.dist2D(dam, sire) > (CD.BREED_LEASH or 40) then return false, "far", dam, sire end
    if CD.isWoundedCritical(dam) or CD.isWoundedCritical(sire) or CD.isSick(dam) or CD.isSick(sire) then return false, "health", dam, sire end
    local floor = CD.breedLoyaltyFloor()
    if CD.loyalty(dam) < floor or CD.loyalty(sire) < floor then return false, "loyalty", dam, sire end
    if not (CD.isWellFed(dam) and CD.isWellFed(sire)) then return false, "hunger", dam, sire end
    if dd.pregnant or dd.breedTarget then return false, "pregnant", dam, sire end
    local now = CD.worldMinutes()
    if dd.lastWhelpMin and now < dd.lastWhelpMin + CD.breedCooldownMinutes() then return false, "cooldown", dam, sire end
    local lim = CD.maxCompanions()
    if lim > 0 and cdCompanionCount(owner) >= lim then return false, "limit", dam, sire end
    return true, nil, dam, sire
end

CD.Server.breed = function(player, args)
    if not CD.breedingEnabled() then return end
    local a = resolveAnimal(args)
    local b = args.mateId and getAnimal(tonumber(args.mateId)) or nil
    if not a or not b or a == b or not CD.isDog(a) or not CD.isDog(b) then return end
    if not (CD.isCompanion(a) and CD.isOwnedBy(a, player)) then return end
    if not (CD.isCompanion(b) and CD.isOwnedBy(b, player)) then return end
    local ok, reason, dam, sire = CD.breedEligible(a, b)
    if not ok then notifyOwner(player, "breedfail", { reason = reason }); return end
    CD.startBreedingApproach(dam, sire)
    notifyOwner(player, "goingtomate", { name = CD.data(dam).name, breed = CD.getBreed(dam) })
end

-- Cruzamento PASSIVO (resolve o "botao morto": nao ha UI de Cruzar pra player normal). A cada HORA-de-jogo, cada
-- femea-companheira elegivel com um macho elegivel do mesmo dono por perto tem chance BreedChancePerDay/24 de
-- conceber sozinha. Server-only, so roda carregado. Hookado no bloco pesado do companionTick.
local lastBreedHour
function CD.tickPassiveBreeding()
    if isClient() then return end
    if not CD.breedingEnabled() then return end
    local chanceDay = CD.breedChancePerDay()
    if not chanceDay or chanceDay <= 0 then return end
    local h = math.floor(CD.worldMinutes() / 60)
    if lastBreedHour == nil then lastBreedHour = h; return end   -- 1a passada so ancora a hora (sem burst no load)
    if h == lastBreedHour then return end
    lastBreedHour = h
    local cell = getCell()
    if not cell then return end
    local list = cell:getAnimals()
    if not list then return end
    local females, dogs = {}, {}
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if a and CD.isDog(a) and CD.isCompanion(a) then
            dogs[#dogs + 1] = a
            local d = CD.data(a)
            if CD.animalSex(a) == "female" and not d.pregnant and not d.breedTarget then females[#females + 1] = a end
        end
    end
    if #females == 0 then return end
    local pHour = chanceDay / 100 / 24
    for _, dam in ipairs(females) do
        local best, bestDist = nil, 99999
        for _, sire in ipairs(dogs) do
            if sire ~= dam and CD.breedEligible(dam, sire) then
                local dist = CD.dist2D(dam, sire)
                if dist < bestDist then bestDist, best = dist, sire end
            end
        end
        if best and (ZombRand(0, 1000000) / 1000000) < pHour then
            CD.conceive(dam, best)
            local owner = CD.getOwnerPlayer(dam)
            if owner then CD.notifyOwner(owner, "bred", { name = CD.data(dam).name }) end
        end
    end
end

-- ===== Debug de teste de breeding (atras de debugAllowed) ==========================================
-- "Forcar gravidez (cao mais proximo)": a femea ANDA ate o cao mais proximo e concebe ao chegar, ignorando o gate.
-- Se voce clicou num macho e o mais proximo e femea, ela e que anda ate ele. Gestacao normal -> use "Parir agora".
CD.Server.forcebreed = function(player, args)
    if not CD.debugAllowed(player) then return end
    local target = resolveAnimal(args) or CD.findNearbyCompanion(player, 16)
    if not target or not CD.isDog(target) then return end
    if CD.isPuppy(target) then return end   -- filhote nao cruza
    local cell = getCell()
    if not cell then return end
    local other, best = nil, 99999
    local dx0, dy0, dz0 = math.floor(target:getX()), math.floor(target:getY()), math.floor(target:getZ())
    for dx = -16, 16 do
        for dy = -16, 16 do
            local sq = cell:getGridSquare(dx0 + dx, dy0 + dy, dz0)
            local list = sq and sq:getAnimals()
            if list then
                for i = 0, list:size() - 1 do
                    local cand = list:get(i)
                    if cand and CD.isDog(cand) and cand ~= target and not CD.isPuppy(cand) then   -- pula filhotes
                        local dist = CD.dist2D(cand, target)
                        if dist < best then best, other = dist, cand end
                    end
                end
            end
        end
    end
    if not other then return end
    -- a femea e quem anda ate o macho (quando der pra distinguir os sexos)
    local dam, sire
    if CD.animalSex(target) == "male" and CD.animalSex(other) == "female" then dam, sire = other, target
    else dam, sire = target, other end
    CD.startBreedingApproach(dam, sire)
end

-- Pari a ninhada AGORA (sem esperar a gestacao).
CD.Server.forcewhelp = function(player, args)
    if not CD.debugAllowed(player) then return end
    local dam = resolveAnimal(args) or CD.findNearbyCompanion(player, 16)
    if not dam or not CD.isDog(dam) then return end
    local owner = CD.getOwnerPlayer(dam) or player
    CD.whelpLitter(dam, owner)
end

-- Debug "crescer agora": vence o prazo de maturacao do filhote empurrando d.bornMin pro passado (e limpando a pausa),
-- pra tickMaturation maturar no proximo sweep. Usa CD.maturityMinutes (sandbox). NAO chama setAge (IsoAnimal nao tem;
-- era no-op) -- quem faz a troca pro adulto, preservando o vinculo, e o tickMaturation.
CD.Server.maturepup = function(player, args)
    if not CD.debugAllowed(player) then return end
    local pup = resolveAnimal(args) or CD.findNearbyCompanion(player, 16)
    if not pup or not CD.isDog(pup) then return end
    local d = CD.data(pup)
    d.growthPaused = nil
    d.bornMin = CD.worldMinutes() - (CD.maturityMinutes and CD.maturityMinutes() or (CD.MATURITY_DAYS or 90) * 24 * 60) - 1
    CD.transmit(pup)
end

-- Toggle por-cao: liga/desliga a permissao de cruzar deste companheiro (d.breedingOff). Gate em CD.Server.breed.
CD.Server.setbreedmode = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isCompanion(animal) or not CD.isOwnedBy(animal, player) then return end
    CD.data(animal).breedingOff = (args and args.off == true) and true or nil
    CD.transmit(animal)
end

-- Toggle por-cao: pausa/retoma o crescimento deste filhote (d.growthPaused). Lido pelo pin em
-- tickCompanionInvincible, que segura hoursSurvived abaixo do limite de maturacao pra a engine nunca
-- chamar checkStages->grow (filhote pra sempre).
CD.Server.setgrowthmode = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isCompanion(animal) or not CD.isOwnedBy(animal, player) then return end
    CD.data(animal).growthPaused = (args and args.paused == true) and true or nil
    CD.transmit(animal)
end

CD.Server.teleport = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isOwnedBy(animal, player) then return end
    if CD.isDisloyal(animal) then
        notifyOwner(player, "refused", { reason = CD.refusalReason(animal), name = CD.data(animal).name, breed = CD.getBreed(animal) })
        return
    end
    local sq = player:getCurrentSquare()
    if not sq then return end
    local d = CD.data(animal)
    CD.setState(animal, CD.STATE_FOLLOW)
    CD.setInCombat(animal, d, false)
    d.retreating = false
    d.standDown = true
    local bx, by, bz = sq:getX() + 0.5, sq:getY() + 0.5, sq:getZ()
    local tsq = sq
    pcall(function()
        local f = player:getForwardDirection()
        if f then
            local nx, ny = bx - f:getX(), by - f:getY()
            local s = getCell():getGridSquare(math.floor(nx), math.floor(ny), bz)
            if s and (not CD.squareHasFloor or CD.squareHasFloor(s)) then bx, by, tsq = nx, ny, s end
        end
    end)
    if CD.clearClimbVars then CD.clearClimbVars(animal) end -- um Trazer no meio do salto nao pode deixar o cao preso escalando
    pcall(function()
        animal:stopAllMovementNow()
        animal:setX(bx)
        animal:setY(by)
        animal:setZ(bz)
        animal:setCurrent(tsq)
    end)
    reapplyBagVisual(animal)
    notifyOwner(player, "teleported", { id = animal:getOnlineID(), breed = CD.getBreed(animal) })
    CD.transmit(animal)
end

CD.Server.attack = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isOwnedBy(animal, player) then return end
    if not CD.combatEnabled() then return end
    if CD.isDisloyal(animal) or CD.getStress(animal) >= CD.breedPanicThreshold(animal) or CD.isWoundedCritical(animal) then
        notifyOwner(player, "refused", { reason = CD.refusalReason(animal), name = CD.data(animal).name, breed = CD.getBreed(animal) })
        return
    end
    CD.setState(animal, CD.STATE_FOLLOW)
    local d = CD.data(animal)
    local now = CD.worldMinutes()
    d.attackUntilMin = now + CD.attackCommandWindowMin()
    d.attackArmed = true
    d.recallUntilMin = nil
    d.standDown = nil
    if not d.lastObeyXpMin or (now - d.lastObeyXpMin) >= CD.OBEDIENCE_XP_COOLDOWN_MIN then
        d.lastObeyXpMin = now
        CD.addSkillXP(animal, "obedience", CD.OBEDIENCE_XP_PER_CMD)
    end
    notifyOwner(player, "attacking", { id = animal:getOnlineID(), breed = CD.getBreed(animal) })
    CD.transmit(animal)
end

CD.Server.rename = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isOwnedBy(animal, player) then return end
    local text = args.text
    if type(text) ~= "string" then return end
    if #text > 30 then text = string.sub(text, 1, 30) end
    CD.data(animal).name = text
    if animal.setCustomName then animal:setCustomName(text) end
    local pd = CD.playerData(player)
    if CD.data(animal).companionToken == pd.token then pd.name = text end
    if CD.kennelSnapshot then CD.kennelSnapshot(player, animal) end   -- nome fresco no canil
    CD.transmit(animal)
end

-- Comandos com escopo de jogador para a janela de status "no veiculo". Enquanto o dono dirige, o companheiro e
-- DELETADO do mundo (animais sempre renderizam) e seu estado completo vive em pd.stash no jogador, entao nao ha
-- animal vivo para resolver. Estes mutam o registro do stash direto; respawnCompanion o re-aplica no
-- dismount (rename/lealdade/estresse fluem pela tabela compartilhada pd.stash.data; necessidades alimentadas via rec.hunger/
-- thirst/hp). Protegido ao token do companheiro ATIVO e a estar de fato montado, para um registro defasado/liberado
-- nao poder ser alimentado. Espelha a matematica de CD.Server.feed/water, mas sem getters de animal.
-- Espelho de recordStillBonded (server/CompanionDogs_Companion.lua): um registro do stash ainda e nosso se seu token
-- for de qualquer cao vinculado (ativo OU passivo), nao so o ativo: um Select no meio da viagem pode rebaixar o cao
-- guardado para passivo. Local do mesmo arquivo de proposito (armadilha de cache da VM compartilhada em helpers CD.* recem-adicionados).
local function cdRecordStillBonded(pd, tok)
    if tok == nil then return false end
    if type(pd.companions) == "table" and pd.companions[tok] then return true end
    return tok == pd.token
end

local function stashRecordFor(player)
    if not player then return nil end
    local pd = CD.playerData(player)
    local rec = pd.stash
    if not rec or not rec.data then return nil, pd end
    if not cdRecordStillBonded(pd, rec.data.companionToken) then return nil, pd end
    if not CD.isMounted(player) then return nil, pd end
    return rec, pd
end

CD.Server.renamestashed = function(player, args)
    local rec, pd = stashRecordFor(player)
    if not rec then return end
    local text = args.text
    if type(text) ~= "string" then return end
    if #text > 30 then text = string.sub(text, 1, 30) end
    rec.data.name = text
    pd.name = text
    player:transmitModData()
end

CD.Server.feedstashed = function(player, args)
    -- Resolve o registro do stash ANTES de consumir a comida: se nao ha cao guardado valido (ex.: o cao ativo
    -- foi trocado no meio da viagem), a acao nao faz nada e NAO pode desperdicar a comida do jogador.
    local rec = stashRecordFor(player)
    if not rec then return end
    local bad = cdFeedIsToxic(player, args)
    if not cdConsumeFood(player, args) then return end
    local raw = tonumber(args.hunger) or 0
    local red = (raw < 0) and math.min(-raw, 3.0) or 0
    local hungerCut = (red > 0) and red or CD.feedHungerRestore()
    rec.hunger = math.max(0, (rec.hunger or 0) - hungerCut)
    -- sede vem do ThirstChange do item (frutas hidratam, pao nao); ausente/positivo = sede intacta
    local rawT = tonumber(args.thirst) or 0
    local tCut = (rawT < 0) and math.min(-rawT, 1.0) or 0
    if tCut > 0 then
        rec.thirst = math.max(0, (rec.thirst or 0) - tCut)
    end
    local cap = rec.data.maxHealth or 1
    if bad then
        -- Sem perda de vida imediata; o dreno gradual de intoxicacao recomeca em updateUpkeep quando o cao volta ao
        -- mundo no dismount (a vida dele fica congelada durante a viagem de qualquer forma).
        rec.data.trust = math.max(0, (rec.data.trust or 0) - CD.TOXIC_LOYALTY_PENALTY)
        rec.data.combatStress = math.min(1, (rec.data.combatStress or 0) + CD.TOXIC_STRESS)
        rec.data.sickUntilMin = CD.worldMinutes() + CD.TOXIC_SICK_MIN
        player:transmitModData()
        notifyOwner(player, "sick", { breed = rec.data.breed })
        return
    end
    local V = math.floor(red * 100 + 0.5)
    local trustGain = (V > 0) and (V * CD.feedTrustPerHunger()) or CD.FEED_LOYALTY_GAIN
    rec.hp = math.min(cap, (rec.hp or cap) + CD.feedHealthBonus())
    rec.data.trust = math.min(CD.TRUST_MAX, (rec.data.trust or 0) + trustGain)
    rec.data.combatStress = math.max(0, (rec.data.combatStress or 0) - 0.4)
    rec.data.lastWarn = nil
    player:transmitModData()
    notifyOwner(player, "fed", { breed = rec.data.breed })
end

CD.Server.waterstashed = function(player, args)
    local rec = stashRecordFor(player)
    if not rec then return end
    if not cdConsumeWater(player, args) then return end
    rec.thirst = math.max(0, (rec.thirst or 0) - CD.waterThirstRestore())
    rec.data.trust = math.min(CD.TRUST_MAX, (rec.data.trust or 0) + CD.PET_LOYALTY_GAIN)
    rec.data.combatStress = math.max(0, (rec.data.combatStress or 0) - 0.2)
    if rec.data.lastWarn == "thirsty" then rec.data.lastWarn = nil end
    player:transmitModData()
    notifyOwner(player, "watered", { breed = rec.data.breed })
end

CD.Server.release = function(player, args)
    local animal = resolveAnimal(args)
    if not animal or not CD.isDog(animal) then return end
    if not CD.isOwnedBy(animal, player) then return end
    local pd = CD.playerData(player)
    local name = CD.data(animal).name
    local tok = CD.data(animal).companionToken
    if tok == pd.token then
        pd.token = nil
        pd.name = nil
    end
    -- Libera o slot do limite de companheiros (MaxCompanions).
    if tok ~= nil and type(pd.companions) == "table" then pd.companions[tok] = nil end
    if CD.clearKennel then CD.clearKennel(player, tok) end   -- some com o snapshot durável do cao liberado
    pcall(function() player:transmitModData() end)
    CD.demote(animal)
    notifyOwner(player, "released", { name = name })
end

-- Carry: a engine reconstroi o cao via copyFrom no drop (DESCARTA nosso ModData), entao guardamos o vinculo por onlineID para recoverCarriedDogs.
-- Local do mesmo arquivo (nao CD.deepCopy): um arquivo shared/ em cache defasado pode ler um helper CD.* como nil; um local nao pode.
local function cdDeepCopy(t)
    if type(t) ~= "table" then return t end
    local r = {}
    for k, v in pairs(t) do r[k] = cdDeepCopy(v) end
    return r
end
local function cdFindCarriedDogItem(player)
    if not player then return nil end
    local inv = player:getInventory()
    if not inv then return nil end
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and instanceof(it, "AnimalInventoryItem") then
            local a = nil
            pcall(function() a = it:getAnimal() end)
            if a and CD.isDog(a) then return it, a end
        end
    end
    return nil
end

CD.Server.carry = function(player, args)
    if not player then return end
    local onlineID = tonumber(args.onlineID)
    if not onlineID then return end
    -- Captura o vinculo no server a partir do item carregado (autoritativo). O `data` enviado pelo client e uma
    -- tabela profundamente aninhada; via `sendClientCommand` pode chegar com perdas (descartando companionToken/skills),
    -- o que fazia o cao largado voltar sem vinculo em dedicated/co-op (SP passa a tabela por
    -- referencia, entao funcionava la). O item, reconstruido do pacote de pickup, mantem o ModData completo
    -- do cao. Recai para o data do client so se o item ainda nao for resolvivel (recoverCarriedDogs
    -- tambem cura o registro a partir do item a cada tick enquanto carregado).
    local data, src
    local _, held = cdFindCarriedDogItem(player)
    if held and CD.isDog(held) and CD.isCompanion(held) and CD.isOwnedBy(held, player) then
        data = cdDeepCopy(CD.data(held)); src = "item"
    elseif type(args.data) == "table" and args.data.companion then
        data = args.data; src = "client"
    end
    if not data then
        return
    end
    -- Guarda de posse ciente da chave estável (espelha CD.isOwnedBy em cima de uma tabela de dados crua): rejeita só
    -- quando há identificador de dono e NENHUM (key OU name) bate.
    if (data.ownerKey ~= nil and data.ownerKey ~= "") or (data.ownerName ~= nil and data.ownerName ~= "") then
        local owned = (data.ownerKey ~= nil and data.ownerKey ~= "" and data.ownerKey == CD.ownerKey(player))
            or (data.ownerName ~= nil and data.ownerName ~= "" and data.ownerName == player:getUsername())
        if not owned then return end
    end
    local pd = CD.playerData(player)
    pd.carried = {
        onlineID = onlineID,
        animalId = tonumber(args.animalId),
        data = data,
    }
    -- carried (na mao) e stashed (num veiculo) sao estados mutuamente exclusivos.
    pd.stash = nil
    -- Semeia o canil durável a partir dos dados crus (idempotente, não sobrescreve um snapshot mais rico): garante uma
    -- entrada global recuperável se o dono MORRER com o cão no colo (o pd.carried some com o personagem; ver L725).
    if CD.kennelSeedFromData and data.companionToken then CD.kennelSeedFromData(player, data.companionToken, data) end
    pcall(function() player:transmitModData() end)
end

-- Acha NOSSA tigela largada num tile: retorna (worldObj, item) ou nil. A tigela E o world inventory item; ela guarda
-- tanto comida quanto agua no seu ModData. Usado pelos comandos de place/fill abaixo.
local function cdDishAtSquare(sq)
    if not sq then return nil end
    local wobs = sq.getWorldObjects and sq:getWorldObjects()
    if not wobs then return nil end
    for i = 0, wobs:size() - 1 do
        local wo = wobs:get(i)
        local item = wo.getItem and wo:getItem()
        if item and CD.isDishType and CD.isDishType(item:getFullType()) then return wo, item end
    end
    return nil
end

-- Replica o estoque de uma tigela largada para os clients. O ModData do world item NAO auto-sincroniza num dedicated server
-- (InventoryItem nao tem transmitModData; IsoObject.transmitModData sincroniza a tabela do objeto, nao a do item), entao a
-- copia do world item no client fica congelada no stream-in: o menu da tigela mostrava vazio. Faz broadcast para cada client
-- (como os pacotes de som/anim); o client cacheia por tile (CD.cacheDishStock). No-op em SP, onde o menu le
-- o ModData compartilhado ao vivo. Substitui as antigas (mortas) chamadas `dish:transmitModData()` (InventoryItem nao tem tal metodo).
function CD.broadcastDishStock(x, y, z, md)
    if isServer() and x and y and z and md then
        sendServerCommand(CD.MODULE, "dishstock",
            { x = x, y = y, z = z, food = md.cdFoodMeals or 0, water = md.cdWater or 0 })
    end
end

-- Coloca um item de tigela NO tile escolhido como world object (a mesma instancia do item, entao seu ModData/estoque vai junto).
-- A tigela E a estacao de alimentacao; o auto-feed a escaneia diretamente. AddWorldInventoryItem faz broadcast do novo
-- world object para os clients (padrao vanilla de drop server-side: SCampfireGlobalObject/camping/Vehicles). Lado server/SP.
-- xo/yo/rot vem do cursor de posicionamento (CDPlaceDishCursor); sao clampados aqui porque a request e do client.
CD.Server.placedish = function(player, args)
    if not player or not args then return end
    local cell = getCell()
    local x, y, z = tonumber(args.x), tonumber(args.y), tonumber(args.z)
    if not (cell and x and y and z) then return end
    -- O cursor so aceita tiles alcancaveis, mas nada impede um client de pedir um tile distante: exige adjacencia folgada.
    if z ~= math.floor(player:getZ()) or math.abs(x + 0.5 - player:getX()) > 2.5 or math.abs(y + 0.5 - player:getY()) > 2.5 then
        notifyOwner(player, "dishnospace", {}); return
    end
    local sq = cell:getGridSquare(x, y, z)
    if not sq or not sq:getFloor() then notifyOwner(player, "dishnospace", {}); return end
    local blocked = false
    pcall(function() blocked = sq:isSolid() or sq:isSolidTrans() end)
    if blocked then notifyOwner(player, "dishnospace", {}); return end
    local xo = math.max(0.05, math.min(0.95, tonumber(args.xo) or 0.5))
    local yo = math.max(0.05, math.min(0.95, tonumber(args.yo) or 0.5))
    local rot = math.max(0, math.min(360, tonumber(args.rot) or 0))
    local id = tonumber(args.itemId)
    local inv = player:getInventory()
    local item = id and inv and inv:getItemById(id)
    if not item or not CD.isDishType(item:getFullType()) then return end
    -- Casa o world model com seu estoque ANTES de largar, para o objeto largado renderizar cheio/vazio corretamente desde
    -- o inicio (o nome do model viaja no ModData do item que AddWorldInventoryItem serializa para os clients).
    if CD.refreshDishModel then CD.refreshDishModel(item) end
    -- Remove do container REAL do item (uma mochila/bolsa lateral, nao so o inventario principal): ItemContainer:Remove
    -- nao e recursivo, entao remover de `inv` perderia uma tigela guardada numa sub-bolsa e AddWorldInventoryItem entao
    -- largaria a mesma instancia deixando uma duplicata presa na bolsa. Remove em rede server-side: sem kick de anticheat.
    local cont = (item.getContainer and item:getContainer()) or inv
    if isServer() then pcall(function() sendRemoveItemFromContainer(cont, item) end) end
    pcall(function() cont:Remove(item) end)
    -- Rotacao setada ANTES do add pra viajar no broadcast do proprio AddWorldInventoryItem, e de novo depois (o vanilla so
    -- faz depois, mas la ele segue com transmitCompleteItemToClients, que aqui zeraria o ModData de estoque da tigela).
    pcall(function() item:setWorldZRotation(rot) end)
    pcall(function()
        local wi = sq:AddWorldInventoryItem(item, xo, yo, 0.0)
        if wi then wi:setWorldZRotation(rot) end
    end)
    pcall(function() CD.broadcastDishStock(x, y, z, item:getModData()) end)
    notifyOwner(player, "dishplaced", {})
end

-- Despeja um item de comida do inventario do dono numa Tigela de Comida largada: remove o item de comida inteiro no server
-- (seguro contra anticheat) e adiciona seu valor em refeicoes (CD.dishMealsForFood) ao ModData da tigela. Roda em OnClientCommand.
CD.Server.dishaddfood = function(player, args)
    if not player or not args then return end
    local cell = getCell()
    local x, y, z = tonumber(args.x), tonumber(args.y), tonumber(args.z)
    if not (cell and x and y and z) then return end
    local _, dish = cdDishAtSquare(cell:getGridSquare(x, y, z))
    if not dish then notifyOwner(player, "dishgone", {}); return end
    local inv = player:getInventory()
    local food = inv and args.foodId and inv:getItemById(tonumber(args.foodId))
    if not food or not CD.isBowlFood(food) then return end
    if CD.isBadDogFood(food) then return end
    local md = dish:getModData()
    -- Uma tigela guarda comida OU agua, nunca os dois: recusa comida enquanto guarda agua (esvazie primeiro).
    if (md.cdWater or 0) > 0 then notifyOwner(player, "dishhaswater", {}); return end
    local cur, cap = md.cdFoodMeals or 0, CD.DISH_MAX_MEALS or 100
    local space = cap - cur
    if space <= 0 then notifyOwner(player, "dishfull", {}); return end
    -- Enche ate o limite e deixa o RESTANTE no item de comida (sem desperdicio): se o item inteiro cabe, consome ele;
    -- se for maior que o espaco livre, credita so `space` pontos e encolhe o item para o que sobrou.
    local add = CD.dishMealsForFood(food)
    local credited = math.min(add, space)
    md.cdFoodMeals = cur + credited
    if CD.refreshDishModel then CD.refreshDishModel(dish) end
    CD.broadcastDishStock(x, y, z, md)
    if credited >= add then
        -- Item inteiro consumido ciente de ReplaceOnUse (espelha cdConsumeFood): uma comida embalada deixa seu
        -- container vazio (panela/lata) em vez de sumir; UseAndSync e server-side + seguro contra anticheat.
        pcall(function() food:setHungChange(0); food:UseAndSync() end)
    else
        -- Parcial: mantem o item, reduz seus valores de comida para a fracao restante (edicao segura contra anticheat, espelha
        -- o caminho parcial de cdConsumeFood). dishMealsForFood le getHungerChange, entao isto deixa o restante certo.
        pcall(function() food:multiplyFoodValues((add - credited) / add); food:syncItemFields() end)
    end
    notifyOwner(player, "dishfilled", {})
end

-- Enche uma Tigela de Agua largada ate o maximo a partir de uma fonte de agua carregada (drenando um pedaco dela). EDICAO de fluid-container,
-- nao um delete de item, entao e seguro contra anticheat; feito server-side por autoridade (como cdConsumeWater).
CD.Server.dishaddwater = function(player, args)
    if not player or not args then return end
    local cell = getCell()
    local x, y, z = tonumber(args.x), tonumber(args.y), tonumber(args.z)
    if not (cell and x and y and z) then return end
    local _, dish = cdDishAtSquare(cell:getGridSquare(x, y, z))
    if not dish then notifyOwner(player, "dishgone", {}); return end
    local md = dish:getModData()
    -- Uma tigela guarda agua OU comida, nunca os dois: recusa agua enquanto guarda comida (esvazie primeiro).
    if (md.cdFoodMeals or 0) > 0 then notifyOwner(player, "dishhasfood", {}); return end
    local cap = CD.DISH_MAX_WATER or 100
    if (md.cdWater or 0) >= cap then notifyOwner(player, "dishfull", {}); return end
    local inv = player:getInventory()
    local water = inv and args.waterId and inv:getItemById(tonumber(args.waterId))
    if not (water and water.getFluidContainer and water:getFluidContainer()) then
        local list = inv and inv:getAllWaterFluidSources(true)
        water = (list and list:size() > 0) and list:get(0) or nil
    end
    if not water then notifyOwner(player, "dishnowater", {}); return end
    pcall(function()
        local fc = water:getFluidContainer()
        if fc and not fc:isEmpty() then fc:removeFluid(CD.DISH_WATER_SOURCE_DRAIN or 0.5, false) end
        if water.syncItemFields then water:syncItemFields() end
    end)
    md.cdWater = cap
    if CD.refreshDishModel then CD.refreshDishModel(dish) end
    CD.broadcastDishStock(x, y, z, md)
    notifyOwner(player, "dishwatered", {})
end

-- Descarta o conteudo de uma tigela largada (refeicoes de comida OU agua) para o jogador poder reaproveita-la. Descarta o estoque (o custo de
-- trocar), reseta o world model para vazio, e sincroniza.
CD.Server.dishempty = function(player, args)
    if not player or not args then return end
    local cell = getCell()
    local x, y, z = tonumber(args.x), tonumber(args.y), tonumber(args.z)
    if not (cell and x and y and z) then return end
    local _, dish = cdDishAtSquare(cell:getGridSquare(x, y, z))
    if not dish then notifyOwner(player, "dishgone", {}); return end
    local md = dish:getModData()
    if (md.cdFoodMeals or 0) <= 0 and (md.cdWater or 0) <= 0 then return end
    md.cdFoodMeals = 0
    md.cdWater = 0
    if CD.refreshDishModel then CD.refreshDishModel(dish) end
    CD.broadcastDishStock(x, y, z, md)
    notifyOwner(player, "dishemptied", {})
end

-- Persiste o "visto por ultimo" dos marcadores de mapa (delta enviado pelo client dono; ver CompanionDogs_MapMarker.lua).
-- Grava a copia autoritativa de pd.dogPositions sem o client transmitir o ModData inteiro do player. Sem transmit de
-- volta: o client dono ja tem a copia viva e um relog recebe o pd do server no login.
CD.Server.dogpos = function(player, args)
    if not player or type(args) ~= "table" or type(args.list) ~= "table" then return end
    local pd = CD.playerData(player)
    local own = pd.companions
    local n = 0
    for _, e in ipairs(args.list) do
        n = n + 1
        if n > 16 then return end
        if type(e) == "table" and e.t ~= nil and ((type(own) == "table" and own[e.t]) or pd.token == e.t) then
            local x, y, z = tonumber(e.x), tonumber(e.y), tonumber(e.z)
            if x and y then
                local name = e.name
                if type(name) ~= "string" then name = nil
                elseif #name > 30 then name = string.sub(name, 1, 30) end
                pd.dogPositions = pd.dogPositions or {}
                pd.dogPositions[e.t] = { x = x, y = y, z = z or 0, name = name }
            end
        end
    end
end

-- Tela admin: devolve o canil global inteiro (dono -> caes) pro client que pediu. Gate re-checado aqui: so
-- admin (MP) ou -debug (SP) recebe os dados. Em SP invoca o handler de client direto (mesmo espelho do notifyOwner).
CD.Server.kenneladmin = function(player, args)
    if not player then return end
    if not (CD.debugAllowed and CD.debugAllowed(player)) then return end
    local onlineSet = {}
    pcall(function()
        local list = getOnlinePlayers()
        if list then
            for i = 0, list:size() - 1 do
                local p = list:get(i)
                if p then onlineSet[p:getUsername()] = true end
            end
        end
    end)
    local owners = {}
    local all = (CD.kennelGlobalAll and CD.kennelGlobalAll()) or {}
    for key, bucket in pairs(all) do
        if type(bucket) == "table" then
            local o = { key = tostring(key), name = nil, online = (not isServer()) or onlineSet[key] == true, dogs = {} }
            for _, snap in pairs(bucket) do
                if type(snap) == "table" then
                    if o.name == nil and type(snap.ownerName) == "string" and snap.ownerName ~= "" then o.name = snap.ownerName end
                    o.dogs[#o.dogs + 1] = {
                        name = snap.name, breed = snap.breed, sex = snap.sex,
                        isPup = snap.isPup == true, lost = snap.lost == true,
                        x = snap.x, y = snap.y, z = snap.z,
                        savedAtMin = snap.savedAtMin, hp = snap.hp,
                        skills = snap.skills,
                    }
                end
            end
            if #o.dogs > 0 then owners[#owners + 1] = o end
        end
    end
    local payload = { owners = owners, now = CD.worldMinutes() }
    if isServer() then
        sendServerCommand(player, CD.MODULE, "kenneladminlist", payload)
    elseif CD.onKennelAdminList then
        CD.onKennelAdminList(payload)
    end
end

-- Preferencia de auto-feed do player (gatilho de fome/sede lido pelo server em troughFeedTrigger): grava a copia
-- autoritativa aqui em vez de o client transmitir o ModData inteiro (ver CompanionDogs_Settings.lua).
CD.Server.feedtrigger = function(player, args)
    if not player or type(args) ~= "table" or type(args.value) ~= "number" then return end
    player:getModData().cdFeedTrigger = math.max(0.1, math.min(1.0, args.value))
end

local function OnClientCommand(module, command, player, args)
    if module ~= CD.MODULE then return end
    local fn = CD.Server[command]
    if fn then fn(player, args) end
end

if isServer() then
    Events.OnClientCommand.Add(OnClientCommand)
end
