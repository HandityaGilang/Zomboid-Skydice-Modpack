require "ISUI/ISModalDialog"

local CD = CompanionDogs

local function onTameNameApply(target, button, dog)
    if button.internal == "OK" and dog then
        local text = button.parent.entry:getText()
        if text and text ~= "" then
            CD.request("rename", dog, { text = text })
        end
    end
end

-- O server transmite a KEY de raca neutra de idioma ("caramelo"/"germanshepherd"); cada client a localiza
-- para que cada jogador leia o halo no proprio idioma. Recai para o nome padrao do companheiro.
local function cdBreedNoun(args)
    if CD.breedNounFromKey then return CD.breedNounFromKey(args and args.breed) end
    return getText("IGUI_PD_DogDefaultName")
end

-- O sujeito a que um halo se dirige: o substantivo da raca, mais o nome customizado do cao quando ele tem um ("Caramelo Rex").
local function cdSubject(args)
    local breed = cdBreedNoun(args)
    local name = args and args.name
    if name and name ~= "" then return breed .. " " .. name end
    return breed
end

-- O sandbox "Show dog status texts" controla apenas o halo flutuante; efeitos colaterais (caixa de nome, alivio de humor,
-- fechar a janela de status) ficam fora destes helpers para continuarem rodando quando os textos estao desligados.
-- `p` TEM que ser o jogador: HaloTextHelper.addText indexa queuedLines[p:getIndex()] (array de 4) e o update() so
-- desenha em IsoPlayer.players[i]. Um IsoAnimal tem getIndex()==0, entao passar o cao nao flutua sobre ele -- escreve
-- no slot do jogador 1 (em split-screen, no jogador errado). Nao da pra ancorar halo num animal; use o nametag.
local function haloGood(p, txt) if CD.showNotifications() then HaloTextHelper.addGoodText(p, txt) end end
local function haloBad(p, txt) if CD.showNotifications() then HaloTextHelper.addBadText(p, txt) end end
local function haloInfo(p, txt) if CD.showNotifications() then HaloTextHelper.addText(p, txt) end end

function CD.clientNotify(command, args)
    local player = getPlayer()
    if not player then return end
    if command == "tamed" then
        haloGood(player, getText("IGUI_PD_Tamed", cdSubject(args)))
        local dog = (args and args.animal) or getAnimal(tonumber(args and args.id))
        if dog then
            local modal = ISTextBox:new(0, 0, 290, 180, getText("IGUI_PD_NameTitle"),
                "", nil, onTameNameApply, player:getPlayerNum(), dog)
            modal:initialise()
            modal:addToUIManager()
        end
    elseif command == "trust" then
        local progress = ""
        if args and args.trust and args.max then
            progress = " " .. tostring(args.trust) .. "/" .. tostring(args.max)
        end
        haloInfo(player, getText("IGUI_PD_Trust", cdSubject(args)) .. progress)
    elseif command == "fed" then
        haloGood(player, getText("IGUI_PD_Fed", cdSubject(args)))
    elseif command == "goingtomate" then
        haloInfo(player, getText("IGUI_PD_GoingToMate", (args and args.name) or ""))
    elseif command == "bred" then
        haloGood(player, getText("IGUI_PD_Bred", (args and args.name) or ""))
    elseif command == "whelped" then
        haloGood(player, getText("IGUI_PD_Whelped", (args and args.name) or ""))
    elseif command == "matured" then
        haloGood(player, getText("IGUI_PD_Matured", (args and args.name) or ""))
    elseif command == "sick" then
        haloBad(player, getText("IGUI_PD_Sick", cdSubject(args)))
    elseif command == "watered" then
        haloGood(player, getText("IGUI_PD_Watered", cdSubject(args)))
    elseif command == "bagequipped" then
        haloGood(player, getText("IGUI_PD_BagEquipped"))
    elseif command == "bagunequipped" then
        haloGood(player, getText("IGUI_PD_BagUnequipped"))
    elseif command == "bagalready" then
        haloBad(player, getText("IGUI_PD_BagAlready"))
    elseif command == "bagfull" then
        haloBad(player, getText("IGUI_PD_BagFull"))
    elseif command == "bagdata" then
        if CD.BagWindow and CD.BagWindow.onData then CD.BagWindow.onData(args) end
    elseif command == "dishplaced" then
        haloGood(player, getText("IGUI_PD_DishPlaced"))
    elseif command == "dishnospace" then
        haloBad(player, getText("IGUI_PD_DishNoSpace"))
    elseif command == "dishfilled" then
        haloGood(player, getText("IGUI_PD_DishFilled"))
    elseif command == "dishwatered" then
        haloGood(player, getText("IGUI_PD_DishWatered"))
    elseif command == "dishfull" then
        haloBad(player, getText("IGUI_PD_DishFull"))
    elseif command == "dishgone" then
        haloBad(player, getText("IGUI_PD_DishGone"))
    elseif command == "dishnowater" then
        haloBad(player, getText("IGUI_PD_DishNoWater"))
    elseif command == "dishhaswater" then
        haloBad(player, getText("IGUI_PD_BowlHasWater"))
    elseif command == "dishhasfood" then
        haloBad(player, getText("IGUI_PD_BowlHasFood"))
    elseif command == "dishemptied" then
        haloGood(player, getText("IGUI_PD_BowlEmptied"))
    elseif command == "teleported" then
        haloGood(player, getText("IGUI_PD_Teleported", cdSubject(args)))
    elseif command == "wounded" then
        haloBad(player, getText("IGUI_PD_Wounded", cdSubject(args)))
    elseif command == "woundedcritical" then
        haloBad(player, getText("IGUI_PD_WoundedCritical", cdSubject(args)))
    elseif command == "recovered" then
        haloGood(player, getText("IGUI_PD_Recovered", cdSubject(args)))
    elseif command == "panic" then
        haloBad(player, getText("IGUI_PD_PanicWarn", cdSubject(args)))
    elseif command == "petted" then
        if CD.bondingEnabled() then
            CD.relieveMood(player, CD.petMoodRelief())
        end
        haloGood(player, getText("IGUI_PD_Petted", cdSubject(args)))
    elseif command == "petcooldown" then
        haloInfo(player, getText("IGUI_PD_PetCooldown", cdSubject(args)))
    elseif command == "attacking" then
        haloGood(player, getText("IGUI_PD_Attacking", cdSubject(args)))
    elseif command == "notarget" then
        haloInfo(player, getText("IGUI_PD_NoTarget", cdSubject(args)))
    elseif command == "refused" then
        local reason = args and args.reason
        local key = "IGUI_PD_Refused_disloyal"
        if reason == "panicked" then key = "IGUI_PD_Refused_panicked"
        elseif reason == "wounded" then key = "IGUI_PD_Refused_wounded"
        elseif reason == "invehicle" then key = "IGUI_PD_Refused_invehicle"
        elseif reason == "carried" then key = "IGUI_PD_Refused_carried"
        elseif reason == "nodata" then key = "IGUI_PD_Refused_nodata"
        elseif reason == "recallcd" then key = "IGUI_PD_Refused_recallcd" end
        haloBad(player, getText(key, cdSubject(args)))
    elseif command == "lost" then
        haloBad(player, getText("IGUI_PD_DogLost", cdSubject(args)))
    elseif command == "warn" then
        local kind = args and args.kind
        local key = "IGUI_PD_Hungry"
        if kind == "thirsty" then key = "IGUI_PD_Thirsty"
        elseif kind == "disloyal" then key = "IGUI_PD_Disloyal"
        elseif kind == "refused" then key = "IGUI_PD_Ignored" end
        haloBad(player, getText(key, cdSubject(args)))
    elseif command == "alert" then
        if args and args.tier == "alarm" then
            haloBad(player, getText("IGUI_PD_AlertAlarm", cdSubject(args)))
        else
            haloInfo(player, getText("IGUI_PD_AlertAware", cdSubject(args)))
        end
    elseif command == "selected" then
        haloGood(player, getText("IGUI_PD_Selected", cdSubject(args)))
    elseif command == "inherited" then
        haloGood(player, getText("IGUI_PD_Inherited", cdSubject(args)))
    elseif command == "limitreached" then
        haloBad(player, getText("IGUI_PD_FeedLimit", tostring(args and args.max or 0)))
    elseif command == "notyourdog" then
        haloBad(player, getText("IGUI_PD_NotYourDog", cdBreedNoun(args)))
    elseif command == "released" then
        local name = (args and args.name) or getText("IGUI_PD_DogDefaultName")
        haloGood(player, getText("IGUI_PD_Released", name))
        if ISCDStatusWindow and ISCDStatusWindow.instance then
            ISCDStatusWindow.instance:close()
        end
    elseif command == "died" then
        haloBad(player, getText("IGUI_PD_Died", cdSubject(args)))
    elseif command == "spawnsreset" then
        haloGood(player, getText("IGUI_PD_SpawnsReset", tostring(args and args.count or 0)))
    elseif command == "huntmode" then
        local on = args and args.on
        haloInfo(player, getText(on and "IGUI_PD_HuntModeOnMsg" or "IGUI_PD_HuntModeOffMsg", cdSubject(args)))
    elseif command == "huntpoint" then
        haloInfo(player, getText("IGUI_PD_HuntPoint", cdSubject(args)))
    elseif command == "dogzombiekill" then
        -- roda no cliente do dono: espelha a morte no "Zombie Kills" nativo (o toggle ja foi conferido no server).
        -- Sem halo: uma mensagem por zumbi morto seria spam.
        pcall(function() player:setZombieKills(player:getZombieKills() + 1) end)
    elseif command == "huntkill" then
        haloGood(player, getText("IGUI_PD_HuntKill", cdSubject(args)))
    elseif command == "huntdelivered" then
        haloGood(player, getText("IGUI_PD_HuntDelivered", cdSubject(args)))
    elseif command == "huntwoundeddeer" then
        haloInfo(player, getText("IGUI_PD_HuntWoundedDeer", cdSubject(args)))
    elseif command == "hunttrackwounded" then
        haloInfo(player, getText("IGUI_PD_HuntTrackWounded", cdSubject(args)))
    elseif command == "foragefound" then
        haloInfo(player, getText("IGUI_PD_ForageFound", cdSubject(args)))
    end
end

-- animal:playSound no server e silencioso; nome+id do som sao transmitidos e tocados em cada client (via
-- CD.playAnimalSound, que respeita volume/mute e NAO reenvia o som pela rede -- ver o comentario la no Util).
function CD.playDogSound(args)
    if not args or not args.id or not args.sound then return end
    local animal = getAnimal(tonumber(args.id))
    if animal then CD.playAnimalSound(animal, args.sound) end
end

-- Para um som transmitido em loop (o foley de comer) neste client. Faz par com playDogSound: o server dispara quando
-- o cao sai do estado "eating" para o loop nao tocar para sempre.
function CD.stopDogSound(args)
    if not args or not args.id or not args.sound then return end
    local animal = getAnimal(tonumber(args.id))
    if animal then CD.stopAnimalSound(animal, args.sound) end
end

-- Define um bool de animacao cosmetica sustentada num cao (setVariable no server nao renderiza; animacao e client-side).
-- Usado para o clip de comer (var cdEat) mantido LIGADO durante a permanencia "eating" do auto-feed.
function CD.setDogAnimVar(args)
    if not args or not args.id or not args.var then return end
    local animal = getAnimal(tonumber(args.id))
    if animal then
        if args.value ~= nil then
            pcall(function() animal:setVariable(args.var, tostring(args.value)) end)
        else
            pcall(function() animal:setVariable(args.var, args.on and true or false) end)
        end
    end
end

-- O estoque de uma tigela largada (pontos de comida/agua) NAO auto-replica em dedicated server: InventoryItem nao tem
-- transmitModData, e um client mantem sua propria copia do item de mundo congelada no valor serializado quando entrou no stream. Entao
-- o server transmite o estoque a cada mudanca e nos cacheamos aqui chaveado por tile; o menu da tigela le este cache
-- (recaindo para o ModData ao vivo, que e correto em SP / VM compartilhada do coop-host).
CD.dishStock = CD.dishStock or {}
function CD.dishStockKey(x, y, z) return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z) end
function CD.cacheDishStock(args)
    if not args or args.x == nil then return end
    CD.dishStock[CD.dishStockKey(args.x, args.y, args.z)] = { food = args.food or 0, water = args.water or 0 }
    -- Repinta a tigela largada NESTE client: seu ModData de item de mundo fica congelado no stream-in num dedicated server,
    -- entao dirige o fluido cosmetico pela transmissao e re-baka localmente (localOnly = sem wo:sync de volta ao server).
    pcall(function()
        local sq = getCell() and getCell():getGridSquare(args.x, args.y, args.z)
        local wobs = sq and sq:getWorldObjects()
        if not wobs then return end
        for i = 0, wobs:size() - 1 do
            local wo = wobs:get(i)
            local item = wo.getItem and wo:getItem()
            if item and CD.isDishType and CD.isDishType(item:getFullType()) then
                local md = item:getModData()
                md.cdFoodMeals = args.food or 0
                md.cdWater = args.water or 0
                if CD.refreshDishModel then CD.refreshDishModel(item, true) end
                break
            end
        end
    end)
end

local pendingAttackClear = {}

-- A alternancia transmite uma var diferente por mordida; limpa TODAS para uma var anterior nunca vazar true (= pose de ataque travada).
local function clearAttackVars(animal)
    local vars = CD.ATTACK_ANIM_VARS or { CD.ATTACK_ANIM_VAR }
    for i = 1, #vars do
        pcall(function() animal:setVariable(vars[i], false) end)
    end
end

function CD.playDogAttack(args)
    if not args or not args.id then return end
    local animal = getAnimal(tonumber(args.id))
    if not animal then return end
    local var = args.var or CD.ATTACK_ANIM_VAR
    clearAttackVars(animal)
    pcall(function() animal:setVariable(var, true) end)
    pendingAttackClear[animal:getOnlineID()] = { animal = animal, deadlineMs = getTimestampMs() + CD.ATTACK_ANIM_MS }
end

local function processAttackClears()
    local now
    for id, e in pairs(pendingAttackClear) do
        now = now or getTimestampMs()
        if now >= e.deadlineMs then
            clearAttackVars(e.animal)
            pendingAttackClear[id] = nil
        end
    end
end

-- z:knockDown nao replica do server; derruba o zumbi vivo mais proximo do ponto do golpe client-side.
function CD.knockdownZombie(args)
    if not args or not args.zx then return end
    local cell = getCell()
    if not cell then return end
    local zx, zy = args.zx, args.zy
    local ax, ay, az = math.floor(zx), math.floor(zy), math.floor(args.zz or 0)
    local best, bestDist = nil, 1.5
    for dx = -2, 2 do
        for dy = -2, 2 do
            local sq = cell:getGridSquare(ax + dx, ay + dy, az)
            local mo = sq and sq:getMovingObjects()
            if mo then
                for i = 0, mo:size() - 1 do
                    local o = mo:get(i)
                    -- NPC de mod (IsoZombie marcado) encostado no alvo nao pode levar o knockback do golpe.
                    if instanceof(o, "IsoZombie") and not o:isDead() and not CD.isFriendlyNPC(o) then
                        local ddx, ddy = o:getX() - zx, o:getY() - zy
                        local dist = math.sqrt(ddx * ddx + ddy * ddy)
                        if dist <= bestDist then best, bestDist = o, dist end
                    end
                end
            end
        end
    end
    if best then
        pcall(function() best:knockDown(false) end)
    end
end

-- z:Kill() server-side NAO replica num dedicado (todo zumbi e client-owned, sem player-host; o dono reseta pra vivo).
-- O server manda este comando pro cliente do DONO (autoritativo pros zumbis perto dele) matar o zumbi pelo caminho
-- real, igual ao golpe do proprio jogador. Casado por onlineID + posicao: nunca mata um zumbi vizinho por engano.
-- Ver strikeExchange (server) e pz-b42-zombie-sethealth-mp-nopersist.
function CD.killZombie(args)
    if not args or not args.zx or not args.id then return end
    local cell = getCell()
    if not cell then return end
    local zx, zy = args.zx, args.zy
    local ax, ay, az = math.floor(zx), math.floor(zy), math.floor(args.zz or 0)
    local target = nil
    for dx = -3, 3 do
        for dy = -3, 3 do
            local sq = cell:getGridSquare(ax + dx, ay + dy, az)
            local mo = sq and sq:getMovingObjects()
            if mo then
                for i = 0, mo:size() - 1 do
                    local o = mo:get(i)
                    if instanceof(o, "IsoZombie") and not o:isDead() and o:getOnlineID() == args.id then
                        target = o
                        break
                    end
                end
            end
            if target then break end
        end
        if target then break end
    end
    if target then
        pcall(function() target:setHealth(0) end)
        pcall(function() target:Kill(getPlayer()) end)
    end
end

local SHOOTABLE_THROTTLE = 15
local shootableTick = 0
local function clearCompanionShootable()
    shootableTick = shootableTick + 1
    if shootableTick < SHOOTABLE_THROTTLE then return end
    shootableTick = 0
    local cell = getCell()
    if not cell then return end
    local list = cell:getAnimals()
    if not list then return end
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if CD.isDog(a) and CD.isCompanion(a) then
            pcall(function() a:setShootable(false) end)
        end
    end
end

-- Imunidade a arma de fogo, lado client (so MP, registrado sob isClient(), entao nunca roda em SP onde o
-- tickGunGuard do loop do server cuida disso). A LISTA DE ALVOS da arma e computada no client do atirador
-- (CombatManager roda para o jogador local), e a engine ignora setShootable para armas miradas, entao nos
-- damos GOD_MODE nos companheiros proximos NESTA copia enquanto o jogador local mira: isGodMod() os tira da
-- lista de alvos da arma (CombatManager.removeTargetObjects), entao a bala nunca os mira. O reset de fome do GOD_MODE
-- nao importa no client (o server cuida da fome do cao e a re-sincroniza). Unico gerente aqui; libera
-- o que definiu quando a mira para. Helper local (nao CD.* do Util compartilhado) de proposito, veja a nota em
-- CompanionDogs_Companion.lua: um helper CD.* compartilhado recem-adicionado pode ler nil via o cache do integrated-server.
-- Cache de identidade da arma: getPrimaryHandItem retorna o MESMO objeto enquanto a arma continua equipada, entao a
-- classificacao instanceof/isRanged so re-roda quando o objeto muda. Corpos hoisted em helpers nomeados (sem closure
-- nova por tick, sem GC churn); ranged-first mantido (quem so luta melee/mao vazia nunca paga as sondas de mira).
local lastWeapon, lastWeaponRanged = nil, false
local function cdWeaponOf(p) return p:getPrimaryHandItem() end
local function cdRangedOf(w) return w ~= nil and instanceof(w, "HandWeapon") and w:isRanged() == true end
local function cdThreatOf(p)
    return p:isAiming() == true
        or (p.isAttacking and p:isAttacking() == true)
        or (p.isPerformingHostileAnimation and p:isPerformingHostileAnimation() == true)
end
local function isFirearmThreat(player)
    if not player then return false end
    local ok, w = pcall(cdWeaponOf, player)
    if not ok or w == nil then lastWeapon = nil; lastWeaponRanged = false; return false end
    if w ~= lastWeapon then
        local ok2, r = pcall(cdRangedOf, w)
        lastWeapon, lastWeaponRanged = w, (ok2 and r == true)
    end
    if not lastWeaponRanged then return false end
    -- Engaja ao mirar OU em meio a um ataque OU na animacao hostil, para um tiro rapido de clique esquerdo tambem ser coberto.
    local ok3, t = pcall(cdThreatOf, player)
    return ok3 and t == true
end

-- Divide "ha ameaca?" (barato, por tick) de "quais caes estao perto?" (caro, por cadencia). A lista de alvos da arma
-- so e recomputada NO DISPARO, entao a deteccao de ameaca precisa rodar por tick E o guard tem que estar ON antes de um
-- tiro rapido resolver; mas isso vale so pro CHECK de ameaca. ENUMERAR caes (o sweep) nao precisa de frescor por tick:
-- caes andam ~1 tile/0.25s, o raio tem folga, e o setIsInvincible do server e o backstop de dano de qualquer jeito. Entao:
-- check por tick + rebuild da lista a cada ~15 ticks + re-afirma o guard na lista cacheada por tick (idempotente, mantem
-- a garantia "guardado no tick em que a ameaca aparece"). Uma passada por cell:getAnimals() (lista pequena no client)
-- substitui o sweep 21x21 de getGridSquare (~880 calls/tick -> ~2N).
local GUN_GUARD_REFRESH = 15   -- reconstroi a lista de caes proximos a cada N ticks enquanto sob ameaca
local GUN_HINT_RADIUS = 30     -- so pinga o server se ha cao neste raio (cobre o scan de follow ~28 + o guard 10)
local gunGuardTick = 0
local clientGunGuarded = {}
local nearDogs, nearIds, nearCount = {}, {}, 0   -- arrays paralelos, reusados (sem garbage por rebuild)
local hintDogNear = false
local dogsBuiltTick = -1000
-- Enquanto o jogador local mira, pinga o server (que nao le input de mira remoto) SO se ha cao perto: a maioria de quem
-- mira num server cheio nao tem cao -> ping = zero. Primeiro ping imediato (contador primado); re-preparado quando nao mira.
local AIM_HINT_SEND_INTERVAL = 45   -- ~0.75s @ 60 fps; par com CD.GUN_AIM_HINT_TTL=120 no server
local aimHintSendTick = 1000

-- Rebuild da lista de caes proximos numa passada por cell:getAnimals() (padrao ja usado em clearCompanionShootable/
-- tickBagVisuals). Preenche nearDogs/nearIds (dentro do raio de guard) e hintDogNear (dentro do raio de ping).
local function rebuildNearDogs(player)
    nearCount = 0
    hintDogNear = false
    local cell = getCell(); if not cell then return end
    local list = cell:getAnimals(); if not list then return end
    local px, py = player:getX(), player:getY()
    local R = CD.GUN_RISK_RADIUS or 10
    local R2, H2 = R * R, GUN_HINT_RADIUS * GUN_HINT_RADIUS
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if a and CD.isDog(a) and CD.isCompanion(a) then
            local dx, dy = a:getX() - px, a:getY() - py
            local d2 = dx * dx + dy * dy
            if d2 <= H2 then hintDogNear = true end
            if d2 <= R2 then
                nearCount = nearCount + 1
                nearDogs[nearCount], nearIds[nearCount] = a, a:getOnlineID()
            end
        end
    end
end

-- setInvulnerable envolvido no padrao pcall(function() ... end) do arquivo (comprovado, 68 usos): so dispara ao mirar
-- perto de um cao (raro, poucos caes), entao a alocacao de closure aqui e irrelevante. O ganho de closure-zero do §3.2
-- fica no isFirearmThreat (caminho quente de TODO player por tick).
local function releaseClientGunGuarded()
    for id, a in pairs(clientGunGuarded) do
        pcall(function() a:setInvulnerable(false) end)
        clientGunGuarded[id] = nil
    end
end
local function tickGunGuardClient()
    gunGuardTick = gunGuardTick + 1 -- relogio monotonico (nunca zera) pra a cadencia de rebuild
    local player = getPlayer()
    if not player or not isFirearmThreat(player) then
        releaseClientGunGuarded()
        aimHintSendTick = 1000 -- re-prepara para a proxima mira pingar imediatamente (>= qualquer intervalo)
        return
    end
    -- Enumera caes na cadencia (imediato na 1a passada sob ameaca: dogsBuiltTick comeca -1000; a cache so fica velha no MEIO da mira)
    if gunGuardTick - dogsBuiltTick >= GUN_GUARD_REFRESH then
        dogsBuiltTick = gunGuardTick
        rebuildNearDogs(player)
        -- diff: solta os caes que sairam do raio de guard desde o ultimo rebuild
        for id, a in pairs(clientGunGuarded) do
            local still = false
            for j = 1, nearCount do if nearIds[j] == id then still = true; break end end
            if not still then
                pcall(function() a:setInvulnerable(false) end)
                clientGunGuarded[id] = nil
            end
        end
    end
    -- Re-afirma o GOD_MODE por tick na lista cacheada (idempotente; garante o guard ja no tick em que a ameaca aparece)
    for j = 1, nearCount do
        local a, id = nearDogs[j], nearIds[j]
        clientGunGuarded[id] = a
        pcall(function() a:setInvulnerable(true) end)
    end
    -- Ping do aim SO com cao dentro de GUN_HINT_RADIUS. Primeiro ping imediato (aimHintSendTick primado em 1000).
    if hintDogNear then
        aimHintSendTick = aimHintSendTick + 1
        if aimHintSendTick >= AIM_HINT_SEND_INTERVAL then
            aimHintSendTick = 0
            CD.request("aimhint")
        end
    end
end

-- Caes vadios latem ocasionalmente para dar atmosfera ao bairro. Puramente cosmetico e client-local
-- (som posicional pela rota do mod, sem addSound) entao NUNCA atrai zumbis; companheiros sao excluidos
-- (eles ja latem em combate/sentinela/estresse). Cooldown randomizado por cao mantem isso esparso.
local WILD_BARK_THROTTLE = 30
local wildBarkTick = 0
local wildBarkNext = {}
local function tickWildDogBark()
    if not CD.WILD_BARK_ENABLED then return end
    wildBarkTick = wildBarkTick + 1
    if wildBarkTick < WILD_BARK_THROTTLE then return end
    wildBarkTick = 0
    local cell = getCell()
    if not cell then return end
    local list = cell:getAnimals()
    if not list then return end
    local now = getTimestampMs()
    local seen
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if CD.isDog(a) and not CD.isCompanion(a) and not a:isDead() then
            local id = a:getOnlineID()
            seen = seen or {}
            seen[id] = true
            local nextMs = wildBarkNext[id]
            if nextMs == nil then
                -- escalona o primeiro latido para vadios recem-carregados nao dispararem todos de uma vez
                wildBarkNext[id] = now + ZombRand(CD.WILD_BARK_MIN_SEC, CD.WILD_BARK_MAX_SEC + 1) * 1000
            elseif now >= nextMs then
                CD.playAnimalSound(a, CD.WILD_BARK_SOUND)
                wildBarkNext[id] = now + ZombRand(CD.WILD_BARK_MIN_SEC, CD.WILD_BARK_MAX_SEC + 1) * 1000
            end
        end
    end
    -- esquece caes que nao estao mais carregados para a tabela de agenda ficar limitada
    for id in pairs(wildBarkNext) do
        if not (seen and seen[id]) then wildBarkNext[id] = nil end
    end
end

-- Bufo ocioso. Era o binding "idle" de dog_sounds, tocado pela ENGINE (chooseIdleSound) e portanto imune ao volume/mute
-- do mod -- o jogador mutava e continuava ouvindo o cao resfolegar. Desvinculado la e reemitido aqui, no mesmo molde do
-- latido ambiente (throttle + agenda por onlineID + GC pelo set seen), passando pela rota de som do mod. Vale pra todo
-- cao nosso (companheiro e vadio), no mesmo intervalo que a engine usava.
local IDLE_VOICE_THROTTLE = 30
local idleVoiceTick = 0
local idleVoiceNext = {}
local function tickDogIdleVoice()
    if not CD.IDLE_VOICE_ENABLED then return end
    idleVoiceTick = idleVoiceTick + 1
    if idleVoiceTick < IDLE_VOICE_THROTTLE then return end
    idleVoiceTick = 0
    local cell = getCell()
    if not cell then return end
    local list = cell:getAnimals()
    if not list then return end
    local now = getTimestampMs()
    local seen
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if CD.isDog(a) and not a:isDead() then
            local id = a:getOnlineID()
            seen = seen or {}
            seen[id] = true
            local nextMs = idleVoiceNext[id]
            if nextMs == nil then
                idleVoiceNext[id] = now + ZombRand(CD.IDLE_VOICE_MIN_SEC, CD.IDLE_VOICE_MAX_SEC + 1) * 1000
            elseif now >= nextMs then
                CD.playAnimalSound(a, CD.IDLE_VOICE_SOUND)
                idleVoiceNext[id] = now + ZombRand(CD.IDLE_VOICE_MIN_SEC, CD.IDLE_VOICE_MAX_SEC + 1) * 1000
            end
        end
    end
    for id in pairs(idleVoiceNext) do
        if not (seen and seen[id]) then idleVoiceNext[id] = nil end
    end
end

-- Mata o foley nativo de "pastar" em qualquer cao nosso. O AnimalEatState da engine toca AnimalFoleyEatGrass
-- (o "barulho de guaxinim") client-side SEMPRE que um animal come por caminho nativo (trough via eatTypeTrough,
-- item no chao, zona de animais); needs nativas ativas (vadio, filhote, cao em zona) disparam isso. Nao da pra
-- desligar o caminho por definicao, entao o client para o som por nome a cada poucos ticks (stop de som que nao
-- esta tocando e no-op barato). O beber nativo ja e mudo na engine; as refeicoes do mod tocam CDDogEat/CDDogDrink.
local EAT_FOLEY_KILL_THROTTLE = 5
local eatFoleyKillTick = 0
local function tickEatFoleyKill()
    eatFoleyKillTick = eatFoleyKillTick + 1
    if eatFoleyKillTick < EAT_FOLEY_KILL_THROTTLE then return end
    eatFoleyKillTick = 0
    local cell = getCell()
    if not cell then return end
    local list = cell:getAnimals()
    if not list then return end
    -- Backstop de mute: as vozes que sobraram em dog_sounds (dor/morte/colo) sao tocadas pela ENGINE, fora do
    -- volume/mute do mod. Quando o jogador mutou, mata elas por nome aqui do mesmo jeito (so roda mutado).
    local muted
    for _, name in ipairs(CD.ENGINE_VOICES) do
        if CD.Settings.getVolumeFactor(name) <= 0 then
            muted = muted or {}
            muted[#muted + 1] = name
        end
    end
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if CD.isDog(a) and not a:isDead() then
            pcall(function()
                local em = a:getEmitter()
                em:stopSoundByName("AnimalFoleyEatGrass")
                if muted then
                    for _, name in ipairs(muted) do em:stopSoundByName(name) end
                end
            end)
        end
    end
end

-- Caes escondidos num veiculo. A colisao do veiculo roda no client do motorista, entao cancela a batida pendente aqui
-- a cada tick tambem (o cancelamento do lado server nao chega a este client); evita o carro bater no proprio cao.
local stashedDogs = {}
local function tickStashedDogs()
    for id, animal in pairs(stashedDogs) do
        local ok = pcall(function()
            animal:setVehicle4TestCollision(nil)
            animal:setCollidable(false)
        end)
        if not ok then stashedDogs[id] = nil end
    end
end

-- ===== Salto de cerca MP: glide client-side ====================================================================
-- O tickFenceHops do server conduz o cao AUTORITATIVO (funciona em SP + e a fonte da verdade do MP), mas um glide manual
-- de setX por tick NAO replica suavemente para clients remotos (pos do animal sincroniza ~1x/s, o glide de velocidade zero
-- nao carrega dead-reckoning, o arco Z e arredondado no fio). Entao o server transmite o salto e CADA client
-- reproduz o mesmo glide na sua copia local aqui. Registrado SO sob isClient(), entao a VM de server de um coop host
-- (o glide do server) e sua VM de client (esta) nunca conduzem o objeto juntas. Veja memory pz-b42-animal-mp-position-sync.
--
-- LIMITACAO CONHECIDA (cliente remoto MP / dedicated server): a ANIMACAO do salto ainda NAO bate totalmente com single-player.
-- SP e perfeito porque o cao e o objeto LOCAL autoritativo (maquina de estados de animacao completa). Num IsoAnimal remoto
-- (nao-proprio) a engine conduz facing/cabeca/root-motion de forma diferente e este replay so consegue sobrescrever
-- parcialmente: o angulo do corpo e um tween suave em direcao a forwardDirection (giro visivel), a cabeca e uma torcao Bip01_Head segurando o
-- residual corpo-vs-alvo (cabeca "olha para a cerca" / se contorce), e o root motion do clip da idle-layer cdJump e somado
-- por cima do nosso glide. As alavancas setTargetAndCurrentDirection / setMaxTwist(0) / setDeferredMovementEnabled abaixo sao
-- os hooks corretos da engine e ajudam, mas NAO resolveram totalmente nos testes de dedicated-server: o residual e
-- aceito como uma restricao de MP do lado da engine (animais nao sao suaves como jogador em MP; pos sync ~1x/s, Z em byte). SP nao afetado.
local clientFenceHops = {}
local clientBlinkHops = {}   -- CD.FENCE_HOP_MP_BLINK: caes escondidos durante o salto (id -> {animal, untilMs}); re-exibidos ao pousar
local clientFenceNear = {}   -- id -> untilMs : supressao de APROXIMACAO. Enquanto uma cerca transponivel esta na linha o server
                             -- envia "fencenear"; soltamos o A* do proprio client para ele dead-reckonar RETO na cerca
                             -- em vez de pace-la como parede (o "para, da dois passos, pensa"). Auto-expira (TTL).
local clientFenceSettle = {} -- id -> {animal,x,y,z,untilMs} : segura POUSO. Fixa o tile de pouso por uma janela curta para
                             -- o pacote nativo defasado de ~800ms nao arrastar o cao de volta a cerca antes de um novo chegar.

-- engine-redirect EXPERIMENTAL (CD.FENCE_HOP_REDIRECT). A engine conduz um animal remoto a cada frame EM DIRECAO ao
-- target/direction do networkAi (sobrescrevendo nosso setX). Em vez de so brigar com isso, escreve esses targets no NOSSO ponto do arco para a
-- engine convergir o cao ao longo do salto. Os campos do networkAi podem nao ser graviaveis por Lua (kahlua nao expoe todo
-- campo publico); sondamos uma vez (read+write-back) e auto-desabilitamos se der erro, para isto nunca quebrar o replay seguro.
local naiWritable = nil   -- nil = nao testado; true/false depois da primeira sondagem
local function redirectInit(animal)
    if naiWritable == false then return nil end
    local nai
    local ok = pcall(function() nai = animal:getNetworkCharacterAI() end)
    if not ok or not nai then naiWritable = false; return nil end
    if naiWritable == nil then
        local w = pcall(function() local t = nai.targetX; nai.targetX = t end)
        naiWritable = w and true or false
    end
    if naiWritable == false then return nil end
    pcall(function() nai.usePathFind = false end)               -- moveToPoint direto, nao A* (que rota AO REDOR da cerca)
    pcall(function() nai.forcePathFinder = false end)
    pcall(function() nai.needToMovingUsingPathFinder = false end)
    return nai
end

local function redirectTick(h, nx, ny, nz)
    local nai = h.nai
    pcall(function()
        nai.targetX = nx; nai.targetY = ny
        if nai.targetZ ~= nil then nai.targetZ = math.floor(nz) end
        nai.forcePathFinder = false; nai.needToMovingUsingPathFinder = false
        if h.ux and h.uy and nai.direction and nai.direction.set then nai.direction:set(h.ux, h.uy) end
    end)
end

-- Fixa o facing do cao remoto durante o salto. Num animal remoto (nao-proprio) setDir so define o angulo ALVO; o
-- angulo do corpo entao interpola em direcao a ele (~0.15/frame = um GIRO visivel). setTargetAndCurrentDirection encaixa angulo:=alvo
-- num frame, entao o salto fica de frente para a frente como em SP. Quando o indice IsoDirections falhou no round-trip (dir == nil)
-- viramos para o vetor cru de cruzamento (ux,uy) em vez de encaixar no rumo ANTIGO (o "pula de lado"). Re-emitido por frame.
local function snapHopFacing(animal, dir, ux, uy)
    pcall(function()
        if dir then
            animal:setDir(dir)
        elseif ux and uy then
            animal:setForwardDirection(ux, uy)
        end
        local f = animal:getForwardDirection()
        if not f then return end
        local fx, fy = f:getX(), f:getY()
        local ok = pcall(function() animal:setTargetAndCurrentDirection(fx, fy) end)
        if not ok then
            animal:setForwardDirection(fx, fy)
            local ap = animal:getAnimationPlayer()
            if ap then ap:setTargetAndCurrentDirection(fx, fy) end
        end
    end)
end

-- Desfaz as supressoes so-do-salto + assenta uma pose de descanso neutra. Chamado ao pousar por qualquer caminho de saida.
local function restoreHopState(animal, h)
    pcall(function()
        if animal.setDeferredMovementEnabled then animal:setDeferredMovementEnabled(true) end
        -- Deixa maxTwist em 0, NAO restaura o default ~15: animais bloqueiam a torcao (allowsTwist()==false) entao 0 e
        -- a pose neutra de SP; restaurar um valor diferente de zero deixava o residual corpo-vs-alvo esticar a cabeca ao pousar.
        if animal.setMaxTwist then animal:setMaxTwist(0) end
        animal:setVariable("cdJump", false)   -- encerra o clip de salto localmente (uma transmissao "animvar off" perdida nao pode travar a pose)
        local f = animal:getForwardDirection()
        if f and animal.setTargetAndCurrentDirection then
            animal:setTargetAndCurrentDirection(f:getX(), f:getY())
        end
    end)
end

-- APROXIMACAO (Fix A): o server viu uma cerca transponivel na linha ate o dono. Solta o A* client-side deste cao para o
-- remote-mover da engine dead-reckona-lo RETO na cerca (moveToPoint linear) em vez de pathToLocationF, que
-- trata a cerca pulavel como parede e a pace/desvia = o visivel "para, da dois passos, pensa". A transmissao real do salto
-- (clientFenceHops) assume daqui; o TTL cobre o intervalo e auto-limpa se o cao se afastar.
function CD.onFenceNear(args)
    local id = tonumber(args and args.id)
    if not id then return end
    clientFenceNear[id] = getTimestampMs() + (CD.FENCE_NEAR_TTL or 1200)
    local a = getAnimal(id)
    if a then pcall(function() a:setHasObstacleOnPath(false) end) end
end

-- POUSO (Fix C): segura o cao no seu tile de pouso por uma janela curta apos o salto. Sem isto o
-- remote-mover da engine persegue o realx DEFASADO de ~800ms (ainda perto/na cerca) no instante em que devolvemos o cao -> ele anda
-- DE VOLTA em direcao a cerca e a encara ("volta pra cerca, gira") ate um pacote novo o encaixar para frente. Fixar setX
-- a cada frame (o OnTick do client roda depois do update da engine, entao ele ganha) + A* desligado faz a ponte; o
-- sendExtraUpdateToClients forcado do server faz o realx novo chegar em ~100ms. restoreHopState devolve o movimento no fim do settle.
local function beginFenceSettle(id, animal, x, y, z, fx, fy, src)
    if not animal or not x then if animal then pcall(function() restoreHopState(animal, nil) end) end; return end
    clientFenceSettle[id] = { animal = animal, x = x, y = y, z = z, fx = fx, fy = fy,
                              untilMs = getTimestampMs() + (CD.FENCE_HOP_SETTLE_MS or 700) }
    -- Mantem o A* do client DESLIGADO por um tempo apos o pouso tambem (nao so durante o hold): reativar enquanto o cao
    -- ainda esta ao lado da cerca faz ele grudar na cerca (que pro A* do client e uma parede), o "anda colado na cerca 1-2s".
    clientFenceNear[id] = getTimestampMs() + (CD.FENCE_POST_LAND_ASTAR_OFF_MS or 2000)
    pcall(function() if animal.setHasObstacleOnPath then animal:setHasObstacleOnPath(false) end end)
end

function CD.startFenceHopLocal(args)
    if not args or not args.id then return end
    local id = tonumber(args.id)
    local animal = getAnimal(id)
    if not animal then return end   -- cao nao streamado neste client: pula; o server o pousa autoritativamente
    clientFenceSettle[id] = nil     -- um salto novo (cerca encadeada) substitui qualquer settle-de-pouso anterior
    -- fallback BLINK: pula o salto animado, esconde o cao durante o salto, re-exibe no tile de pouso (endFenceHopLocal).
    -- Um cruzamento instantaneo e sem artefatos para clients onde o replay ainda fica ruim. untilMs = re-exibicao de seguranca.
    if CD.FENCE_HOP_MP_BLINK then
        clientBlinkHops[id] = { animal = animal, untilMs = getTimestampMs() + 3000 }
        pcall(function() animal:setInvisible(true, true) end)
        return
    end
    local dir; pcall(function() dir = IsoDirections.fromIndex(args.dir) end)
    local h = {
        animal = animal, sx = args.sx, sy = args.sy, sz = args.sz, cx = args.cx, cy = args.cy, z = args.z,
        dir = dir, ux = args.dx, uy = args.dy, prog = 0, step = args.step or 0.05, arc = args.arc or 0.5,
        startMs = getTimestampMs(),
    }
    clientFenceHops[id] = h
    -- espelha SP (mostra o clip de salto cdJump) e silencia os caminhos da engine de animal remoto que brigam com o replay
    pcall(function()
        animal:setVariable("animalRunning", false)                 -- clip de salto, nao o deslize de corrida
        animal:setVariable("cdJump", true)                         -- pose de salto (re-afirmada por frame: clearVariables a apaga)
        if animal.setMaxTwist then animal:setMaxTwist(0) end
        if animal.setDeferredMovementEnabled then animal:setDeferredMovementEnabled(false) end  -- impede o root motion do Rac_Jump arrastar o glide
    end)
    if CD.FENCE_HOP_REDIRECT then h.nai = redirectInit(animal) end   -- EXPERIMENTAL: conduz a propria convergencia da engine
    snapHopFacing(animal, dir, h.ux, h.uy)
end

function CD.endFenceHopLocal(args)
    if not args or not args.id then return end
    local id = tonumber(args.id)
    local animal = getAnimal(id)
    local h = clientFenceHops[id]
    local lx, ly, lz
    if animal and args.x then
        lx, ly, lz = args.x, args.y, args.z
        pcall(function()
            animal:setX(lx); animal:setY(ly); animal:setNextX(lx); animal:setNextY(ly)
            if animal.setZ then animal:setZ(lz) end
            if animal.setNextZ then animal:setNextZ(lz) end
        end)
    elseif h then
        lx, ly, lz = h.cx, h.cy, h.z   -- sem coords no comando: recai para o alvo do glide local
    end
    local blink = clientBlinkHops[id]
    if blink then
        clientBlinkHops[id] = nil
        pcall(function() (animal or blink.animal):setInvisible(false, true) end)   -- re-exibe no tile de pouso
    end
    clientFenceHops[id] = nil
    if animal then
        -- encerra o clip de salto + quaisquer vars de escalada soltas imediatamente (uma transmissao perdida nao pode travar a pose de salto/escalada)
        pcall(function()
            animal:setVariable("cdJump", false)
            animal:setVariable("ClimbFence", false)
            animal:setVariable("climbDown", false)
            animal:setVariable("ClimbingFence", false)
        end)
        -- Segura o tile de pouso por um settle curto em vez de devolver direto a engine (Fix C). restoreHopState
        -- roda no fim do settle (beginFenceSettle recai para ele imediatamente se nao temos coords de pouso).
        beginFenceSettle(id, animal, lx, ly, lz, h and h.ux, h and h.uy, "SRVEND")
    end
end

-- Espelho fiel da matematica do glide do tickFenceHops do server (smoothstep horizontal + arco Z parabolico) na copia local.
-- O clip de salto cdJump e dirigido separadamente pela transmissao "animvar" do server, entao isto so move/vira o cao.
local function tickClientFenceHops()
    -- seguranca BLINK: re-exibe qualquer cao em blink cujo comando de pouso nunca chegou (pacote perdido). Sem next() no Lua do PZ.
    local nowMs = getTimestampMs()
    for bid, rec in pairs(clientBlinkHops) do
        if nowMs >= rec.untilMs then
            clientBlinkHops[bid] = nil
            pcall(function() if rec.animal then rec.animal:setInvisible(false, true) end end)
        end
    end
    local landBlend = CD.FENCE_HOP_LAND_BLEND or 0.82
    for id, h in pairs(clientFenceHops) do
        local stop = true
        pcall(function()
            local animal = h.animal
            if not animal or not animal:isExistInTheWorld() then return end
            h.prog = h.startMs and math.min(1, (getTimestampMs() - h.startMs) / (CD.FENCE_HOP_DURATION_MS or 800))
                     or math.min(1, h.prog + (h.step or 0.05))
            local p = h.prog
            local ph = p * p * (3 - 2 * p)
            local arc = (h.arc or 0.5) * 4 * p * (1 - p)
            local nx = h.sx + (h.cx - h.sx) * ph
            local ny = h.sy + (h.cy - h.sy) * ph
            local nz = h.sz + (h.z - h.sz) * ph + arc
            animal:setX(nx); animal:setY(ny); animal:setNextX(nx); animal:setNextY(ny)
            pcall(function() animal:setZ(nz); if animal.setNextZ then animal:setNextZ(nz) end end)
            -- Re-afirma a cada tick: um sync defasado de ~0.8s define animalRunning, e NetworkCharacterAI.resetState no timeout
            -- chama clearVariables() que APAGA cdJump -> a FSM cai para o clip idle de cabeca erguida ("cabeca para cima
            -- depois de um tempo"). Re-fixar mantem o clip de salto sem cabeca ganhando; mistura de volta para idle antes do toque no chao.
            pcall(function()
                animal:setVariable("animalRunning", false)
                animal:setVariable("cdJump", p < landBlend)
                if animal.setMaxTwist then animal:setMaxTwist(0) end
            end)
            snapHopFacing(animal, h.dir, h.ux, h.uy)   -- fixa o facing a cada frame (setDir sozinho so define o alvo = giro)
            if h.nai then redirectTick(h, nx, ny, nz) end   -- EXPERIMENTAL: conduz a propria convergencia da engine ao longo do nosso arco
            if p >= 1 then
                animal:setX(h.cx); animal:setY(h.cy); animal:setNextX(h.cx); animal:setNextY(h.cy)
                pcall(function() animal:setZ(h.z); if animal.setNextZ then animal:setNextZ(h.z) end end)
                pcall(function() animal:setVariable("cdJump", false) end)   -- encerra o clip de salto
                beginFenceSettle(id, animal, h.cx, h.cy, h.z, h.ux, h.uy, "LOCAL")    -- segura o tile de pouso (Fix C), restaura no fim do settle
                return
            end
            stop = false
        end)
        if stop then clientFenceHops[id] = nil end
    end
end

-- Settle pos-pouso (Fix C): fixa cada cao recem-pousado no seu tile de pouso por uma janela curta para o remote-
-- mover da engine nao perseguir o realx defasado de ~800ms de volta a cerca. setX a cada frame ganha (o OnTick do client roda depois do update
-- da engine); A* desligado + twist 0 + deferred-off impedem o rota/estica. restoreHopState devolve o movimento no fim.
local function tickClientFenceSettle()
    local nowMs = getTimestampMs()
    for id, s in pairs(clientFenceSettle) do
        local done = false
        pcall(function()
            local a = s.animal
            if not a or not a:isExistInTheWorld() or nowMs >= s.untilMs then done = true; return end
            a:setX(s.x); a:setY(s.y); a:setNextX(s.x); a:setNextY(s.y)
            pcall(function()
                if a.setZ then a:setZ(s.z) end
                if a.setNextZ then a:setNextZ(s.z) end
                a:setVariable("animalRunning", false)   -- fica em pe no tile de pouso (sem foot-slide correndo no lugar enquanto segurado)
                if a.setMaxTwist then a:setMaxTwist(0) end
                if a.setDeferredMovementEnabled then a:setDeferredMovementEnabled(false) end
                if a.setHasObstacleOnPath then a:setHasObstacleOnPath(false) end
            end)
            if s.fx then snapHopFacing(a, nil, s.fx, s.fy) end   -- vira para FRENTE (dir do cruzamento), nao de volta para a cerca
        end)
        if done then
            local a = s.animal
            if a then pcall(function() restoreHopState(a, nil) end) end
            clientFenceSettle[id] = nil
        end
    end
end

local function OnServerCommand(module, command, args)
    if module ~= CD.MODULE then return end
    if command == "fencehop" then
        CD.startFenceHopLocal(args)
        return
    end
    if command == "fencehopend" then
        CD.endFenceHopLocal(args)
        return
    end
    if command == "fencenear" then
        CD.onFenceNear(args)
        return
    end
    if command == "follow" then
        CD.onFollowFrame(args)
        return
    end
    if command == "followstop" then
        CD.onFollowStop(args)
        return
    end
    if command == "astar" then
        CD.onAstarFlag(args)
        return
    end
    if command == "astarstop" then
        CD.onAstarStop(args)
        return
    end
    if command == "sound" then
        CD.playDogSound(args)
        return
    end
    if command == "stopsound" then
        CD.stopDogSound(args)
        return
    end
    if command == "animvar" then
        CD.setDogAnimVar(args)
        return
    end
    if command == "dishstock" then
        CD.cacheDishStock(args)
        return
    end
    if command == "anim" then
        CD.playDogAttack(args)
        return
    end
    if command == "knockdown" then
        CD.knockdownZombie(args)
        return
    end
    if command == "killzombie" then
        CD.killZombie(args)
        return
    end
    if command == "kenneladminlist" then
        if CD.onKennelAdminList then CD.onKennelAdminList(args) end
        return
    end
    if command == "invisible" then
        local animal = getAnimal(tonumber(args and args.id))
        if animal then
            local on = args.on == true
            -- forma forcada (2 args): setInvisible(b) e no-op sem a capability ToggleInvisibleHimself, que animais nao tem.
            pcall(function() animal:setInvisible(on, true) end)
            local id = animal:getOnlineID()
            if on then
                stashedDogs[id] = animal
            else
                stashedDogs[id] = nil
                pcall(function() animal:setCollidable(true) end)
            end
        end
        return
    end
    CD.clientNotify(command, args)
end

-- Sem esconder a montaria client-side: o cao montado agora e DELETADO no server (delete() transmite o despawn
-- a cada client) e uma copia nova e respawnada ao desmontar. O antigo hack client-side removeFromSquare
-- brigava com o re-sync do server e causava flicker em dedicated servers, entao foi removido.

-- Repinta a malha da bolsa lateral a partir do ModData replicado. A engine reconstroi um modelo de animal (cull/uncull de cena, reload)
-- sem re-anexar cosmeticos mas mantem getAttachedItem nao-nil, entao a malha some silenciosamente: repintamos quando a
-- INSTANCIA do modelo muda (token = hash de identidade via tostring, entao um rebuild = um repaint, sem churn por tick) ou uma parte
-- esta faltando (reload). Roda em clients + SP, nao no dedicated server (ele nunca renderiza, getModelInstance e nil la).
local bagVisualTick = 0
-- Estado por onlineID: tok (ModelInstance memoizado), act (ativo na ultima passada), ms (ultimo repaint),
-- burst (inicio da rajada de repaint).
local bagPaint = {}
local function tickBagVisuals()
    bagVisualTick = bagVisualTick + 1
    if bagVisualTick < 10 then return end
    bagVisualTick = 0
    local cell = getCell()
    local list = cell and cell:getAnimals()
    if not list then return end
    -- Agrega por onlineID preferindo a entrada com modelo ATIVO: cell:getAnimals() pode conter uma copia
    -- fantasma INATIVA do mesmo cao (geracao antiga), e ela sobrescrevia o estado da copia real toda passada ->
    -- justActivated eterno -> repaint a cada 10 ticks, cujo setAttachedItem derruba a selecao do inventario
    -- vanilla (bug "saddlebag rouba selecao", roadmap bugs #5).
    local best, order = {}, {}
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if a and CD.isDog(a) then
            local id = tostring(a:getOnlineID())
            local active = false
            pcall(function() active = a:hasActiveModel() == true end)
            local cur = best[id]
            if not cur then
                best[id] = { a = a, active = active }
                order[#order + 1] = id
            elseif active and not cur.active then
                cur.a = a; cur.active = true
            end
        end
    end
    local nowMs = getTimestampMs()
    for _, id in ipairs(order) do
        local e = best[id]
        local a = e.a
        local st = bagPaint[id]
        if not st then st = {}; bagPaint[id] = st end
        if CD.hasBag(a) then
            if e.active then
                local token = nil
                pcall(function() local mi = a:getModelInstance(); if mi then token = tostring(mi) end end)
                local missing = false
                for _, p in ipairs(CD.SADDLEBAG_PARTS) do
                    local at = nil
                    pcall(function() at = a:getAttachedItem(p.loc) end)
                    if at == nil then missing = true; break end
                end
                -- Gatilhos: attachment sumido (data), transicao inativo->ativo (todo rebuild passa por ela), ou
                -- troca de ModelInstance que NAO veio do nosso proprio repaint (o reset settla em <1s).
                local justActivated = st.act ~= true
                local tokenChanged = token ~= nil and st.tok ~= nil and token ~= st.tok
                    and (not st.ms or (nowMs - st.ms) > 1000)
                if missing or justActivated or tokenChanged then
                    st.burst = nowMs
                end
                -- Rajada curta: setAttachedItem durante a janela de re-stream do modelo e no-op silencioso (e
                -- getAttachedItem segue non-nil, indetectavel), entao repinta por ~0.8s apos o gatilho pra colar.
                if st.burst and (nowMs - st.burst) < 800 then
                    CD.applyBagVisualLocal(a)
                    st.ms = nowMs
                end
                if token ~= nil then st.tok = token end
                st.act = true
            else
                st.act = false
            end
        else
            local attached = false
            pcall(function() attached = a:getAttachedItem("saddlebags_l") ~= nil end)
            if attached then CD.removeBagVisualLocal(a) end
            bagPaint[id] = nil
        end
    end
    for id in pairs(bagPaint) do
        if not best[id] then bagPaint[id] = nil end
    end
end

-- ===== Follow MP: replicacao de posicao customizada (glide continuo no client) ======================================
-- A engine sincroniza a pos de um animal para clients remotos so ~1Hz e o client a extrapola em linha RETA
-- (dead-reckoning de Prediction), entao um caminho curvo interno/de porta renderiza como o cao andando para uma parede e depois encaixando.
-- Nos contornamos isso: o server faz stream do transform autoritativo a ~15Hz (OnServerCommand "follow") e aqui cada
-- client buffeia as amostras e renderiza o cao FOLLOW_INTERP_DELAY_MS no PASSADO, INTERPOLANDO entre duas amostras
-- reais (nunca extrapolando) re-afirmando setX/setNextX/setZ + facing a cada OnTick. O glide de salto de cerca ja comprovado
-- generalizado para follow continuo; so isClient() (a VM de server de um coop host nunca conduz esta copia tambem).
-- Residuais da engine (foot-slide, torcao de cabeca) sao aceitos, igual ao salto de cerca. Veja memory
-- companiondogs-custom-mp-position-replication.
local followStream = {}   -- onlineID -> { buf = {amostras crescentes por rt}, lastSeq }
function CD.onFollowFrame(args)
    if not args or not args.id then return end
    local id = tonumber(args.id)
    if not id then return end
    local st = followStream[id]
    if not st then st = { buf = {}, lastSeq = -1 }; followStream[id] = st end
    local seq = tonumber(args.seq) or 0
    if seq <= st.lastSeq and (st.lastSeq - seq) < 1000 then return end   -- fora de ordem/dup (gap >1000 = reset do server)
    st.lastSeq = seq
    local buf = st.buf
    buf[#buf + 1] = {
        x = args.x, y = args.y, z = args.z, fx = args.fx or 0, fy = args.fy or 1,
        run = args.run == true, rt = getTimestampMs(),
    }
    local maxN = CD.FOLLOW_STREAM_BUF or 12
    while #buf > maxN do table.remove(buf, 1) end
end

function CD.onFollowStop(args)
    if not args or not args.id then return end
    local id = tonumber(args.id)
    if not id then return end
    local animal = getAnimal(id)
    if animal and args.x then
        pcall(function()
            animal:setX(args.x); animal:setY(args.y); animal:setNextX(args.x); animal:setNextY(args.y)
            if animal.setZ then animal:setZ(args.z) end
            if animal.setNextZ then animal:setNextZ(args.z) end
        end)
    end
    if animal then pcall(function() restoreHopState(animal, nil) end) end   -- devolve movimento/torcao a engine
    followStream[id] = nil
end

-- Replay por OnTick: renderiza cada cao streamado FOLLOW_INTERP_DELAY_MS no passado, interpolando pelo buffer.
local function tickFollowStreamClient()
    local nowMs = getTimestampMs()
    local delay = CD.FOLLOW_INTERP_DELAY_MS or 100
    local timeout = CD.FOLLOW_STREAM_TIMEOUT_MS or 500
    for id, st in pairs(followStream) do
        local release = false
        pcall(function()
            -- o salto de cerca controla o setX deste cao enquanto ele salta: cede e descarta amostras buffeadas para rebaselinarmos
            -- limpo no seu tile de pouso quando ele termina (sem snap de volta a posicao pre-salto).
            if clientFenceHops[id] or clientBlinkHops[id] then st.buf = {}; return end
            local buf = st.buf
            local n = #buf
            if n == 0 then return end
            if (nowMs - buf[n].rt) > timeout then release = true; return end   -- stream ficou em silencio -> de volta a engine
            local animal = getAnimal(id)
            if not animal or not animal:isExistInTheWorld() then return end    -- cao nao streamado aqui (virtualizado)
            local renderTime = nowMs - delay
            local a, b
            for i = 1, n do
                if buf[i].rt <= renderTime then a = buf[i] else b = buf[i]; break end
            end
            local nx, ny, nz, fx, fy, run
            if not a then
                local s = buf[1]; nx, ny, nz, fx, fy, run = s.x, s.y, s.z, s.fx, s.fy, s.run   -- faminto: encaixa na mais antiga
            elseif not b then
                -- alem da amostra mais nova (fome breve): continua ao longo da velocidade do ultimo segmento por uma janela
                -- LIMITADA para um frame atrasado/irregular nao CONGELAR o cao (o "stutter"), depois SEGURA. Curto + limitado,
                -- entao nunca corre para uma parede como a prediction ilimitada da engine.
                nx, ny, nz, fx, fy, run = a.x, a.y, a.z, a.fx, a.fy, a.run
                local prev = buf[n - 1]
                local ahead = renderTime - a.rt
                if prev and ahead > 0 then
                    local dt = a.rt - prev.rt
                    if dt > 0 then
                        local k = math.min(ahead, CD.FOLLOW_EXTRAP_MAX_MS or 80) / dt
                        nx = a.x + (a.x - prev.x) * k
                        ny = a.y + (a.y - prev.y) * k
                        nz = a.z + (a.z - prev.z) * k
                    end
                end
            else
                local span = b.rt - a.rt
                local al = span > 0 and ((renderTime - a.rt) / span) or 0
                if al < 0 then al = 0 elseif al > 1 then al = 1 end
                nx = a.x + (b.x - a.x) * al; ny = a.y + (b.y - a.y) * al; nz = a.z + (b.z - a.z) * al
                fx = a.fx + (b.fx - a.fx) * al; fy = a.fy + (b.fy - a.fy) * al; run = b.run
            end
            animal:setX(nx); animal:setY(ny); animal:setNextX(nx); animal:setNextY(ny)   -- setar cur+next zera o
            pcall(function()                                                              -- integrador da engine (sem add)
                if animal.setZ then animal:setZ(nz) end
                if animal.setNextZ then animal:setNextZ(nz) end
            end)
            pcall(function()
                animal:setVariable("animalRunning", run == true)
                if animal.setMaxTwist then animal:setMaxTwist(0) end
                -- impede o root motion do clip de ser SOMADO por cima do nosso setX (a copia remota ainda toca clips)
                if animal.setDeferredMovementEnabled then animal:setDeferredMovementEnabled(false) end
            end)
            local len = math.sqrt(fx * fx + fy * fy)
            if len > 0.0001 then snapHopFacing(animal, nil, fx / len, fy / len) end
        end)
        if release then
            local animal = getAnimal(id)
            if animal then pcall(function() restoreHopState(animal, nil) end) end
            followStream[id] = nil
        end
    end
end

-- dense-native MP: o server marca quais ids de cao sao seguidores ativos perto deste client; viramos o remote-
-- mover da engine para A* client-side (setHasObstacleOnPath) para ele renderizar o caminho curvo real em vez de dead-reckonar uma
-- linha reta para paredes/moveis. A flag persiste (AnimalPacket nunca a limpa); re-afirmamos por tick e
-- a expiramos se o server parar de sinalizar. Veja companiondogs-custom-mp-position-replication.
local astarRenderDogs = {}   -- onlineID -> lastSignalMs (refresh do server)
local astarState = {}        -- onlineID -> { px, py, stuckSince, coolUntil } watchdog de progresso de render

function CD.onAstarFlag(args)
    local id = tonumber(args and args.id)
    if not id then return end
    astarRenderDogs[id] = getTimestampMs()
end

local function clearAstarFlag(id)
    astarRenderDogs[id] = nil
    astarState[id] = nil
    clientFenceNear[id] = nil
    local a = getAnimal(id)
    if a then pcall(function() a:setHasObstacleOnPath(false) end) end
end

function CD.onAstarStop(args)
    local id = tonumber(args and args.id)
    if id then clearAstarFlag(id) end
end

local function tickAstarRenderClient()
    local nowMs = getTimestampMs()
    local timeout = (CD.ASTAR_FLAG_MS or 400) * 3   -- expira se o server parar de refrescar (un-follow / fora de alcance)
    local stuckMs = CD.ASTAR_STUCK_MS or 600
    local coolMs = CD.ASTAR_STUCK_COOL_MS or 1500
    local eps = CD.ASTAR_STUCK_EPS or 0.01
    for id, last in pairs(astarRenderDogs) do
        if clientFenceNear[id] and nowMs >= clientFenceNear[id] then clientFenceNear[id] = nil end   -- expira a dica de aproximacao
        if (nowMs - last) > timeout then
            clearAstarFlag(id)
        elseif clientFenceHops[id] or clientBlinkHops[id] or clientFenceSettle[id] or clientFenceNear[id] then
            -- APROXIMACAO do salto / glide / settle de pouso: o cao e dirigido pelo nosso setX ou precisa dead-reckonar reto na
            -- cerca; o A* do client pace/rota a cerca pulavel como parede, entao libera a flag (Fix A + Fix C).
            local a = getAnimal(id)
            if a then pcall(function() a:setHasObstacleOnPath(false) end) end
            astarState[id] = nil
        else
            local a = getAnimal(id)
            if a and a:isExistInTheWorld() then
                local st = astarState[id]; if not st then st = {}; astarState[id] = st end
                local x, y = a:getX(), a:getY()
                local moved = st.px and (math.abs(x - st.px) + math.abs(y - st.py)) or 999
                st.px, st.py = x, y
                -- preso = flagado mas nao avancando (pfb2 andando no lugar numa porta fechada/estrangulamento)
                if moved >= eps then st.stuckSince = nil elseif not st.stuckSince then st.stuckSince = nowMs end
                local inCooldown = st.coolUntil and nowMs < st.coolUntil
                if not inCooldown and st.stuckSince and (nowMs - st.stuckSince) > stuckMs then
                    st.coolUntil = nowMs + coolMs   -- libera A*; o sync nativo passa o cao pelo estrangulamento
                    st.stuckSince = nil
                    inCooldown = true
                end
                if inCooldown then
                    pcall(function() a:setHasObstacleOnPath(false) end)
                else
                    pcall(function() a:setHasObstacleOnPath(true) end)
                end
            end
        end
    end
end

if isClient() then
    Events.OnServerCommand.Add(OnServerCommand)
    Events.OnTick.Add(processAttackClears)
    Events.OnTick.Add(tickStashedDogs)
    -- so MP: nossa replicacao de posicao customizada para o cao ativo (caminho interpolado suave vs o snap de 1Hz da engine)
    Events.OnTick.Add(tickFollowStreamClient)
    -- dense-native MP: renderiza o caminho curvo real do cao ativo via o A* client-side da engine (setHasObstacleOnPath)
    Events.OnTick.Add(tickAstarRenderClient)
    -- so MP: faz o glide da copia local de um cao saltando (o glide do server nao replica suavemente). so isClient()
    -- para a VM de server de um coop host (que roda o glide do server) e esta VM de client nunca conduzirem o mesmo objeto juntas.
    Events.OnTick.Add(tickClientFenceHops)
    -- so MP (Fix C): fixa um cao recem-pousado no seu tile de pouso por um settle curto para o pacote nativo defasado de ~0.8s
    -- nao o arrastar de volta a cerca ("volta pra cerca, gira") antes de um pacote autoritativo novo chegar.
    Events.OnTick.Add(tickClientFenceSettle)
    -- so MP: a bala resolve no client do atirador, entao o cao precisa estar invencivel AQUI enquanto mira.
    -- Em SP (isClient() == false) o tickGunGuard do loop do server cuida disso; registra-lo la tambem
    -- faria os dois brigarem pela flag de invencibilidade compartilhada.
    Events.OnTick.Add(tickGunGuardClient)
end

if isClient() or not isServer() then
    Events.OnTick.Add(clearCompanionShootable)
    Events.OnTick.Add(tickWildDogBark)
    Events.OnTick.Add(tickDogIdleVoice)
    Events.OnTick.Add(tickEatFoleyKill)
    Events.OnTick.Add(tickBagVisuals)
end

