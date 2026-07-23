local CD = CompanionDogs

function CD.isDog(animal)
    if not animal then return false end
    local t = animal.getAnimalType and animal:getAnimalType()
    return t ~= nil and CD.TYPES[t] == true
end

-- Marcadores que mods de NPC (HDX Strangers etc.) setam nos IsoZombie que na verdade sao NPCs.
-- NoZombieHandling e a convencao aberta da comunidade: qualquer mod de NPC que a adote ja fica coberto.
CD.NPC_MARKER_VARS = { "IsHDXStrangerNPC", "NoZombieHandling", "SurvivorNPC" }

-- True quando o IsoZombie carrega um marcador de NPC: nao e ameaca, o cao nao mira nem alerta.
-- pcall porque o objeto pode nao expor a API de variaveis; getVariableString cobre quem seta a var como texto.
function CD.isFriendlyNPC(o)
    if not o then return false end
    local npc = false
    pcall(function()
        for i = 1, #CD.NPC_MARKER_VARS do
            local name = CD.NPC_MARKER_VARS[i]
            if (o.getVariableBoolean and o:getVariableBoolean(name))
                or (o.getVariableString and o:getVariableString(name) == "true") then
                npc = true
                return
            end
        end
    end)
    return npc
end

function CD.data(animal)
    local md = animal:getModData()
    md.CompanionDogs = md.CompanionDogs or {}
    return md.CompanionDogs
end

function CD.transmit(animal)
    if animal.transmitModData then animal:transmitModData() end
end

-- Borda sincronizada do lock de combate: so transmite quando o valor efetivo muda (padrao do alertTier),
-- ~2 transmits por briga. Contrato de addon: clients leem CD.data(dog).inCombat (ex.: moodle do Rottweiler).
function CD.setInCombat(animal, d, on)
    on = on and true or false
    if (d.inCombat and true or false) == on then return end
    d.inCombat = on
    CD.transmit(animal)
end

function CD.playerData(player)
    local md = player:getModData()
    md.CompanionDogs = md.CompanionDogs or {}
    return md.CompanionDogs
end

function CD.hasCompanion(player)
    if CD.playerData(player).token ~= nil then return true end
    return CD.findNearbyCompanion(player) ~= nil
end

-- Quantos cães vinculados o player possui (active + passive), contados a partir do conjunto de tokens guardado no
-- ModData do player (mantido em tame/release/morte; auto-curado a partir dos cães carregados). Usado pelo limite
-- MaxCompanions. O código server-side conta inline (armadilha do shared-helper-on-tick); este é para o menu/UI do client.
function CD.companionCount(player)
    local c = CD.playerData(player).companions
    if type(c) ~= "table" then return 0 end
    local n = 0
    for _ in pairs(c) do n = n + 1 end
    return n
end

function CD.atCompanionLimit(player)
    local m = CD.maxCompanions()
    if not m or m <= 0 then return false end
    return CD.companionCount(player) >= m
end

-- True somente se o token active do dono ainda mapeia para um companion REAL: um carregado perto dele, ou
-- um registro de stash (recuperação de veículo) para esse mesmo token. Um pd.token solto NÃO basta: um delete
-- de admin (ou qualquer remoção externa) o deixa pendurado num cão que não existe mais. Usado na hora do tame
-- para detectar um vínculo órfão e limpá-lo em vez de abrir um diálogo de troca para um cão fantasma.
function CD.hasRecoverableCompanion(player)
    local pd = CD.playerData(player)
    if pd.token == nil then return false end
    if CD.getCompanionAnimal(player) ~= nil then return true end
    local rec = pd.stash
    if rec ~= nil and rec.data ~= nil and rec.data.companionToken == pd.token then return true end
    -- Um companion carregado nas mãos do player (Animal item nativo) também é recuperável: seu vínculo
    -- vive no registro de carry (ver CD.Server.carry) até o cão ser largado e re-anexado.
    local car = pd.carried
    return car ~= nil and car.data ~= nil and car.data.companionToken == pd.token
end

-- O item Animal carregado pode estar dentro de mochila (getItems nao recursa): busca recursiva pelo token.
-- Exige POSSE alem do token: o token e uma sequencia POR JOGADOR (todo mundo tem um cao token 1), entao carregar
-- o cao de outro jogador com o mesmo numero de token fazia isto responder "sim" e o chamador descartar o
-- registro do MEU cao (stash/canil) -> cao sumido.
function CD.carriedTokenAnywhere(player, tok)
    if not player or tok == nil then return false end
    local function scan(cont, depth)
        if not cont or depth > 6 then return false end
        local items = cont:getItems()
        if not items then return false end
        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if it then
                if instanceof(it, "AnimalInventoryItem") then
                    local a = nil
                    pcall(function() a = it:getAnimal() end)
                    if a and CD.isDog(a) and CD.isOwnedBy(a, player) and CD.data(a).companionToken == tok then return true end
                elseif instanceof(it, "InventoryContainer") then
                    local inner = nil
                    pcall(function() inner = it:getInventory() end)
                    if inner and scan(inner, depth + 1) then return true end
                end
            end
        end
        return false
    end
    return scan(player:getInventory(), 0)
end

function CD.deepCopy(t)
    if type(t) ~= "table" then return t end
    local r = {}
    for k, v in pairs(t) do r[k] = CD.deepCopy(v) end
    return r
end

-- Identidade estavel do cao. Carimba d.uid se ausente (recipe = timestamp + random, igual ao reaper de geracao).
-- Filhotes carimbam no NASCIMENTO (nao-lazy) pra ligar ao pedigree e nao serem confundidos com um twin abandonado.
function CD.ensureUid(animal)
    local d = CD.data(animal)
    if not d.uid then
        d.uid = tostring(getTimestampMs()) .. "-" .. tostring(ZombRand(0, 2147483647))
    end
    return d.uid
end

-- Sexo derivado do TYPE nativo (autoritativo, sincroniza em MP): *female -> "female", *male -> "male", *pup -> "pup".
-- Cuidado: "female" CONTEM "male", entao checa female primeiro.
function CD.animalSex(animal)
    local t = animal and animal.getAnimalType and animal:getAnimalType()
    if not t then return nil end
    if string.sub(t, -6) == "female" then return "female" end
    if string.sub(t, -4) == "male" then return "male" end
    if string.sub(t, -3) == "pup" then return "pup" end
    return nil
end

-- Bem alimentado (fome E sede abaixo do teto): pre-requisito pra cruzar.
function CD.isWellFed(animal)
    local h, t = 1, 1
    pcall(function() h = animal:getHunger() or 1; t = animal:getThirst() or 1 end)
    local max = CD.BREED_WELLFED_MAX or 0.5
    return h < max and t < max
end

function CD.isPregnant(animal)
    return CD.data(animal).pregnant == true
end

-- Parto proximo: prenhe E dentro do ultimo pedaco da gestacao (BREED_NEARTERM_FRAC do total). Usa gestationMinutes()
-- como referencia do total (sandbox baked por save = mesmo valor da concepcao). d.gestEndMin replica ao client.
function CD.isNearTerm(animal)
    local d = CD.data(animal)
    if not d.pregnant or not d.gestEndMin then return false end
    return (d.gestEndMin - CD.worldMinutes()) <= CD.gestationMinutes() * (CD.BREED_NEARTERM_FRAC or 0.25)
end

-- Rotulo localizado da prenhez pra UI (nametag/menu): "Parto proximo" perto do termo, senao "Gravida". So client (getText).
function CD.pregnancyLabel(animal)
    return CD.isNearTerm(animal) and getText("IGUI_PD_NearTerm") or getText("IGUI_PD_Pregnant")
end

function CD.isPuppy(animal)
    return CD.data(animal).isPup == true
end

-- Idade localizada pra UI: "Filhote" (isPup) ou "Adulto". So client (getText).
function CD.ageNoun(animal)
    return CD.isPuppy(animal) and getText("IGUI_PD_Puppy") or getText("IGUI_PD_Adult")
end

-- Substantivo localizado do sexo ("Macho"/"Femea") pra UI. Pra filhote (type *pup) usa o d.sex sorteado no
-- nascimento (o sexo adulto ja esta decidido). Retorna nil se desconhecido. So client (getText).
function CD.sexNoun(animal)
    local s = CD.animalSex(animal)
    if s == "pup" then s = CD.data(animal).sex end
    if s == "female" then return getText("IGUI_PD_Sex_Female") end
    if s == "male" then return getText("IGUI_PD_Sex_Male") end
    return nil
end

-- ===== Saddlebag (cargo) ============================================================================
-- A carga do cão vive como registros planos em CD.data(dog).bag, então pega carona no re-attach do copyFrom
-- existente de graça e nunca depende de um ItemContainer vivo no animal (IsoAnimal não serializa container).
-- Um container vivo é reidratado a partir dos registros somente enquanto a UI da bag está aberta; toda mutação
-- de item é server-authoritative (anticheat). Ver memória pz-b42-animal-attached-items-and-speed.
CD.SADDLEBAG_TYPE = "Base.CompanionDogsSaddlebag"

function CD.isSaddlebagType(fullType)
    return fullType == CD.SADDLEBAG_TYPE
end

function CD.hasBag(animal)
    local b = CD.data(animal).bag
    return b ~= nil and b.equipped == true
end

-- Encontra um item saddlebag em qualquer lugar do inventário do player (incl. sub-bags). Helper do lado da UI.
function CD.findBagItem(player)
    if not player then return nil end
    local inv = player:getInventory()
    if not inv then return nil end
    local it = nil
    pcall(function() it = inv:getFirstTypeRecurse(CD.SADDLEBAG_TYPE) end)
    return it
end

-- Capacidade de PESO por cão a partir do gene Strength (caramelo fraco ~ base, GS forte ~ base+span), como um
-- container vanilla: o limite é o peso total, não a contagem de itens. Re-derivada server-side a cada abertura;
-- nunca confiada vinda do client. Limitada a 1..100.
function CD.bagCapacity(animal)
    local sv = CD.sandbox and CD.sandbox() or nil
    local base = (sv and sv.CargoCapacityBase) or 4
    local span = (sv and sv.CargoCapacitySpan) or 8
    local ratio = 0.5
    pcall(function() ratio = CD.geneRatio(animal, "strength") end)
    -- multiplicador por raca (cao de carga): husky = 1.5 (+50%); demais racas sem o campo = 1.0
    local mult = 1
    pcall(function() mult = CD.getBreedDef(animal).bagMult or 1 end)
    local cap = math.floor((base + span * (ratio or 0.5)) * mult + 0.5)
    if cap < 1 then cap = 1 elseif cap > 100 then cap = 100 end
    return cap
end

-- Peso canônico por item usado tanto para exibição quanto para o teste de capacidade de peso (peso unequipped,
-- caindo para o peso base), para que a UI e o server concordem sobre quanto custa um depósito.
function CD.itemWeight(it)
    if not it then return 0 end
    local w = 0
    pcall(function() w = it:getUnequippedWeight() end)
    if not w or w <= 0 then pcall(function() w = it:getWeight() end) end
    return w or 0
end

-- Peso total atualmente guardado na bag. Os registros fazem cache do seu peso (r.w); registros legados sem ele
-- são pesados instanciando o tipo (VM-safe no client e no server).
function CD.bagWeight(records)
    local total = 0
    for _, r in ipairs(records or {}) do
        local w = r.w
        if not w then local it = instanceItem(r.t); if it then w = CD.itemWeight(it) end end
        total = total + (w or 0)
    end
    return total
end

-- Serializa um registro por INSTÂNCIA de item (stacks do PZ são N instâncias, sem campo de contagem). Faz o
-- round-trip dos campos que silenciosamente voltam ao default se omitidos (o item e recriado via instanceItem):
-- condition, afiacao de lamina, used-delta do drainable, fluidos (FluidContainer), municao/pente/camara, keyId (senao vira chave aleatoria),
-- food (valor parcial + idade + cozido/queimado), paginas escritas de livro, midia gravada, reparos, pecas de arma
-- anexadas (recursivo), estado de roupa (sujeira/sangue/molhado + furos por parte + remendos de costura), ModData.
function CD.serializeItem(it)
    local r = { t = it:getFullType() }
    r.w = CD.itemWeight(it)
    -- guarda o nome quando difere do padrao do script: cobre renome do jogador (isCustomName) e
    -- nomes gerados por OnCreate/descritor (cracha, dog tags trazem o nome da pessoa). getDisplayName e o nome cru.
    pcall(function()
        local nm = it:getDisplayName()
        local custom = it:isCustomName()
        local def = it:getScriptItem() and it:getScriptItem():getDisplayName()
        if nm and nm ~= "" and (custom or (def and nm ~= def)) then
            r.name = nm
            if custom then r.custom = true end
        end
    end)
    pcall(function() r.cond = it:getCondition() end)
    -- afiacao vive nos Attributes (nao no ModData), entao some no round-trip: faca volta no maximo. Cobre qualquer lamina.
    pcall(function() if it:hasSharpness() then r.sharp = it:getSharpness() end end)
    pcall(function() if instanceof(it, "DrainableComboItem") then r.delta = it:getUsedDelta() end end)
    -- FluidContainer (B42): instanceItem recria com o fluido do SCRIPT (PetrolCan nasce CHEIO de Petrol), entao
    -- o estado real (vazio/parcial/mistura) precisa de round-trip explicito.
    pcall(function()
        local fc = it:getFluidContainer()
        if fc then
            local fl = {}
            local s = fc:createFluidSample()
            if s then
                for i = 0, s:size() - 1 do
                    local inst = s:getFluidInstance(i)
                    if inst then fl[#fl + 1] = { f = inst:getFluid():getFluidTypeString(), a = inst:getAmount() } end
                end
                pcall(function() s:release() end)
            end
            r.fluids = fl
        end
    end)
    pcall(function() if instanceof(it, "Food") then
        r.hung = it:getHungerChange(); r.age = it:getAge()
        if it:isCooked() then r.cooked = true end
        if it:isBurnt() then r.burnt = true end
    end end)
    pcall(function() local a = it:getCurrentAmmoCount(); if a and a ~= 0 then r.ammo = a end end)
    pcall(function() if instanceof(it, "HandWeapon") then
        if it:isRoundChambered() then r.chamber = true end
        if it:isContainsClip() then r.clip = true end
    end end)
    -- pecas anexadas (mira/luneta/lanterna/laser/etc): cada peca e um InventoryItem -> recursao no serializeItem.
    pcall(function() if instanceof(it, "HandWeapon") then
        local parts = it:getAllWeaponParts()
        if parts and parts:size() > 0 then
            local list = {}
            for i = 0, parts:size() - 1 do
                local p = parts:get(i)
                if p then list[#list + 1] = CD.serializeItem(p) end
            end
            if #list > 0 then
                r.parts = list
                -- attach(doChange=true) reaplica todos os deltas MENOS clipSize; guarda a capacidade real.
                pcall(function() r.clipsz = it:getClipSize() end)
            end
        end
    end end)
    -- keyId pareia a chave com a fechadura; setKeyId(-1) num item novo SORTEIA outro id -> chave inutil. Restaura o real.
    pcall(function() local k = it:getKeyId(); if k and k >= 0 then r.key = k end end)
    pcall(function() if instanceof(it, "Key") then local n = it:getNumberOfKey(); if n and n ~= 0 then r.keyn = n end end end)
    pcall(function() local m = it:getRecordedMediaIndex(); if m and m ~= -1 then r.media = m end end)
    pcall(function() local h = it:getHaveBeenRepaired(); if h and h ~= 0 then r.repaired = h end end)
    -- texto escrito pelo jogador em diario/caderno (irrecuperavel); serializa pagina a pagina via seePage.
    pcall(function() if instanceof(it, "Literature") then
        local pages
        for i = 1, (it:getNumberOfPages() or 0) do
            local t = it:seePage(i)
            if t and t ~= "" then pages = pages or {}; pages[i] = t end
        end
        if pages then r.pages = pages; r.canwrite = it:canBeWrite() end
        if it:getLockedBy() then r.locked = it:getLockedBy() end
    end end)
    -- roupa: sujeira/sangue/molhado (nivel-item), distribuicao por parte (visual; best-effort) e remendos de costura (defesa).
    pcall(function() if instanceof(it, "Clothing") then
        local c = {}
        pcall(function() local x = it:getBloodlevel(); if x and x > 0 then c.blood = x end end)
        pcall(function() local x = it:getDirtiness();  if x and x > 0 then c.dirt = x end end)
        pcall(function() local x = it:getWetness();    if x and x > 0 then c.wet = x end end)
        local v = it:getVisual()   -- pode ser nil em servidor dedicado (asset do modelo nao carregado)
        if v then
            pcall(function() local t = v:getBaseTexture();   if t and t ~= -1 then c.tex = t end end)
            pcall(function() local t = v:getTextureChoice(); if t and t ~= -1 then c.texc = t end end)
            local holes, blood, dirt
            for i = 0, 17 do
                local part = BloodBodyPartType.FromIndex(i)
                if v:getHole(part) > 0 then holes = holes or {}; holes[i + 1] = true end
                local b = v:getBlood(part); if b and b > 0 then blood = blood or {}; blood[i + 1] = b end
                local d = v:getDirt(part);  if d and d > 0 then dirt = dirt or {}; dirt[i + 1] = d end
            end
            if holes then c.holes = holes end
            if blood then c.pblood = blood end
            if dirt  then c.pdirt = dirt end
        end
        if it:getPatchesNumber() > 0 then
            local patches
            for i = 0, 17 do
                local p = it:getPatchType(BloodBodyPartType.FromIndex(i))
                if p then pcall(function()
                    patches = patches or {}
                    patches[#patches + 1] = { part = i, lvl = p.tailorLvl, fab = p:getFabricType(), hole = p.hasHole == true, cg = p.conditionGain }
                end) end
            end
            if patches then c.patches = patches end
        end
        local any = false; for _ in pairs(c) do any = true; break end
        if any then r.cloth = c end
    end end)
    pcall(function()
        local md = it:getModData()
        if md then
            local any = false
            for _ in pairs(md) do any = true; break end
            if any then r.md = CD.deepCopy(md) end
        end
    end)
    return r
end

function CD.serializeBag(container)
    local out = {}
    if not container then return out end
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it then out[#out + 1] = CD.serializeItem(it) end
    end
    return out
end

-- Reconstrói um item vivo a partir de um registro (instanceItem é seguro na VM do server). Retorna o item ou nil.
function CD.bagItemFromRecord(r)
    if not r or not r.t then return nil end
    local it = instanceItem(r.t)
    if not it then return nil end
    if r.cond  then pcall(function() it:setCondition(r.cond) end) end
    -- DEPOIS de setCondition: setSharpness limita por getMaxSharpness() (razao da condition).
    if r.sharp then pcall(function() it:setSharpness(r.sharp) end) end
    if r.delta then pcall(function() it:setUsedDelta(r.delta) end) end
    -- Empty() SEMPRE antes de repor: o item novo pode ja nascer com fluido do script.
    if r.fluids then pcall(function()
        local fc = it:getFluidContainer()
        if fc then
            fc:Empty()
            for _, f in ipairs(r.fluids) do pcall(function() fc:addFluid(f.f, f.a) end) end
        end
    end) end
    if r.hung  then pcall(function() it:setHungChange(r.hung) end) end
    if r.age   then pcall(function() it:setAge(r.age) end) end
    if r.cooked   then pcall(function() it:setCooked(true) end) end
    if r.burnt    then pcall(function() it:setBurnt(true) end) end
    if r.ammo     then pcall(function() it:setCurrentAmmoCount(r.ammo) end) end
    if r.chamber  then pcall(function() it:setRoundChambered(true) end) end
    if r.clip     then pcall(function() it:setContainsClip(true) end) end
    -- arma de stats-base recem-criada: attachWeaponPart(part) usa char=nil + doChange=true e reaplica os deltas.
    if r.parts then pcall(function()
        pcall(function() it:clearAllWeaponParts() end)
        for _, pr in ipairs(r.parts) do
            local part = CD.bagItemFromRecord(pr)
            if part and instanceof(part, "WeaponPart") then pcall(function() it:attachWeaponPart(part) end) end
        end
        if r.clipsz then pcall(function() it:setClipSize(r.clipsz) end) end
    end) end
    if r.key      then pcall(function() it:setKeyId(r.key) end) end
    if r.keyn     then pcall(function() it:setNumberOfKey(r.keyn) end) end
    if r.media    then pcall(function() it:setRecordedMediaIndexInteger(r.media) end) end
    if r.repaired then pcall(function() it:setHaveBeenRepaired(r.repaired) end) end
    if r.pages then pcall(function()
        for i, t in pairs(r.pages) do it:addPage(i, t) end
        if r.canwrite ~= nil then it:setCanBeWrite(r.canwrite) end
    end) end
    if r.locked then pcall(function() it:setLockedBy(r.locked) end) end
    if r.cloth then pcall(function()
        local c = r.cloth
        local v = it:getVisual()   -- por parte so quando o visual existe (nao em servidor dedicado headless)
        if v then
            if c.holes  then for i in pairs(c.holes)   do pcall(function() v:setHole(BloodBodyPartType.FromIndex(i - 1)) end) end end
            if c.pblood then for i, b in pairs(c.pblood) do pcall(function() v:setBlood(BloodBodyPartType.FromIndex(i - 1), b) end) end end
            if c.pdirt  then for i, d in pairs(c.pdirt)  do pcall(function() v:setDirt(BloodBodyPartType.FromIndex(i - 1), d) end) end end
            if c.tex  then pcall(function() v:setBaseTexture(c.tex) end) end
            if c.texc then pcall(function() v:setTextureChoice(c.texc) end) end
        end
        -- nivel-item sempre (robusto mesmo sem visual); NAO chamamos synchWithVisual pra nao sobrescrever isto.
        if c.blood then pcall(function() it:setBloodLevel(c.blood) end) end
        if c.dirt  then pcall(function() it:setDirtiness(c.dirt) end) end
        if c.wet   then pcall(function() it:setWetness(c.wet) end) end
        if c.patches then for _, p in ipairs(c.patches) do
            pcall(function() it:addPatchForSync(p.part, p.lvl, p.fab, p.hole == true) end)
            if p.cg and p.cg ~= 0 then pcall(function()
                local cp = it:getPatchType(BloodBodyPartType.FromIndex(p.part))
                if cp then cp.conditionGain = p.cg end
            end) end
        end end
    end) end
    if r.md    then pcall(function() local m = it:getModData(); for k, v in pairs(r.md) do m[k] = v end end) end
    if r.name  then pcall(function() it:setName(r.name); if r.custom then it:setCustomName(true) end end) end
    return it
end

function CD.rehydrateBag(container, records)
    if not container then return end
    for _, r in ipairs(records or {}) do
        local it = CD.bagItemFromRecord(r)
        if it then pcall(function() container:addItem(it) end) end
    end
end

-- Larga o item saddlebag (com sua carga dentro) no tile do cão, para recuperação em morte / release.
-- Server/SP somente; o chamador protege com uma flag one-shot para que morte + a varredura da engine não derramem em dobro.
function CD.spillBag(animal)
    if isClient() then return end
    local d = CD.data(animal)
    local b = d.bag
    if not b or not b.equipped then return end
    local sq = nil
    pcall(function() sq = animal:getCurrentSquare() end)
    if not sq then pcall(function() sq = animal:getSquare() end) end
    if sq then
        pcall(function()
            local bagItem = instanceItem(CD.SADDLEBAG_TYPE)
            if bagItem then
                CD.rehydrateBag(bagItem:getInventory(), b.items)
                sq:AddWorldInventoryItem(bagItem, 0.5, 0.5, 0.0)
            end
        end)
    end
    d.bag = nil
    CD.transmit(animal)
end

-- O visual do saddlebag: uma mesh estática CrudeLeatherBag_Ground anexada a cada lado da espinha do cão (Spine_03),
-- via o mecanismo de animal-attach da engine (o mesmo cosmético de chapéu de vaca / gravata borboleta, ver
-- CompanionDogs_Attach.lua + models_dog.txt). Lado autoritativo somente (SP: isClient false; dedicated: o server),
-- depois replicado para clients remotos com o comando vanilla "animal"/"attach" (espelha ClientCommands
-- Commands.animal.attach). Re-aplicado nos sites de rebuild do copyFrom (a engine descarta itens anexados ali exatamente como ModData).
CD.SADDLEBAG_STRAP_TYPE = "Base.CompanionDogsSaddlebagStrap"
-- location -> tipo de item anexado: as duas bags laterais mais a correia de couro central que as liga sobre a espinha.
CD.SADDLEBAG_PARTS = {
    { loc = "saddlebags_l", item = CD.SADDLEBAG_TYPE },
    { loc = "saddlebags_r", item = CD.SADDLEBAG_TYPE },
    { loc = "saddlebags_c", item = CD.SADDLEBAG_STRAP_TYPE },
}

function CD.applyBagVisual(animal)
    if isClient() then return end
    if not animal or not CD.hasBag(animal) then return end
    local oid = animal:getOnlineID()
    for _, p in ipairs(CD.SADDLEBAG_PARTS) do
        pcall(function() animal:setAttachedItem(p.loc, instanceItem(p.item)) end)
        if isServer() then
            pcall(function()
                sendServerCommandV("animal", "attach",
                    "id", tostring(oid), "location", p.loc, "item", p.item)
            end)
        end
    end
end

function CD.removeBagVisual(animal)
    if isClient() then return end
    if not animal then return end
    for _, p in ipairs(CD.SADDLEBAG_PARTS) do
        pcall(function() animal:setAttachedItem(p.loc, nil) end)
    end
end

-- Attach/detach local-only (sem comando, sem guard de VM): um client renderiza a mesh da bag direto do ModData
-- replicado via estes, independente do broadcast one-shot "animal"/"attach" do server (que um client que carrega
-- o cão depois perderia). Ver o tick visual do client em CompanionDogs_Client.lua.
function CD.applyBagVisualLocal(animal)
    if not animal then return end
    for _, p in ipairs(CD.SADDLEBAG_PARTS) do
        pcall(function() animal:setAttachedItem(p.loc, instanceItem(p.item)) end)
    end
end

function CD.removeBagVisualLocal(animal)
    if not animal then return end
    for _, p in ipairs(CD.SADDLEBAG_PARTS) do
        pcall(function() animal:setAttachedItem(p.loc, nil) end)
    end
end

-- O pickup nativo transforma o cão num AnimalInventoryItem segurado nas duas mãos. Encontra ele (e o
-- IsoAnimal vivo que ele encapsula) no inventário do dono para que o upkeep continue rodando enquanto carregado.
function CD.findCarriedDogItem(player)
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

function CD.isCarrying(player)
    if not player then return false end
    if CD.playerData(player).carried ~= nil then return true end
    return CD.findCarriedDogItem(player) ~= nil
end

function CD.getTrust(animal)
    return CD.data(animal).trust or 0
end

function CD.setTrust(animal, value)
    if value < 0 then value = 0 end
    if value > CD.TRUST_MAX then value = CD.TRUST_MAX end
    CD.data(animal).trust = value
end

function CD.isCompanion(animal)
    return CD.data(animal).companion == true
end

-- Marcador de dono fixo por save, usado só como fallback de SP quando não há Steam ID (-nosteam):
-- há um único player em SP, então todos os cães compartilham a mesma chave sem ambiguidade.
CD.SP_OWNER_MARKER = "cd_sp_owner"

-- Chave de dono ESTÁVEL, resolvida de forma SÍNCRONA (sem comando/sync assíncrono do cliente, que no dedicado deixava
-- a chave de GRAVAÇÃO diferente da de LEITURA -> o reclaim procurava no bucket errado e o cão não voltava no reconnect):
--  - MP (server OU client): o username de CONEXÃO. Exato, único por player no servidor e PERSISTE na morte e na
--    reconexão (é a conta de login, não o nome do personagem). Disponível na hora, server-side.
--  - SP: getUsername é o NOME do personagem (muda na morte), então usa o Steam ID LOCAL por-conta
--    (getCurrentUserSteamID = string exata, sobrevive à morte), com marcador fixo de save como fallback (-nosteam; há um
--    só player em SP). getSteamID() do IsoPlayer NÃO serve (0 em SP; long = perda de precisão/colisão no Lua).
function CD.ownerKey(player)
    if player == nil then return nil end
    if isServer() or isClient() then
        return player:getUsername()
    end
    local sid = getCurrentUserSteamID and getCurrentUserSteamID()
    if sid ~= nil and sid ~= "" then return sid end
    return CD.SP_OWNER_MARKER
end

-- A posse é chaveada pela ownerKey ESTÁVEL, por PRECEDÊNCIA (nunca por união):
--   1. d.ownerKey existe -> é a ÚNICA autoridade. Em MP = username de conexão; em SP = Steam ID.
--   2. sem ownerKey (save legado, até a migração de processNearbyDogs carimbar) -> ownerName (username).
--
-- d.ownerId (getOnlineID do dono) NÃO participa mais. Era um id de SESSÃO gravado num registro PERMANENTE: o
-- servidor entrega o onlineID pelo índice do slot de conexão livre (GameServer.receiveClientConnect:
-- `playerID = getFreeSlot() * 4`), então quem entra depois que o dono sai HERDA o id dele e passava a casar com
-- todos os cães do dono. Daí saía o roubo de cão em MP: o intruso adotava os cães, eles entravam no "Meus Cães"
-- dele, o espelho gravava a posse errada no canil durável e o recall dele reescrevia o dono de vez.
--
-- União também era perigosa por si só: um cão podia casar com DOIS players ao mesmo tempo, e o getOwnerPlayer
-- devolve o primeiro da lista de online, então nem o dono verdadeiro estar logado protegia.
function CD.isOwnedBy(animal, player)
    if player == nil then return false end
    local d = CD.data(animal)
    local key = d.ownerKey
    if key ~= nil and key ~= "" then
        return key == CD.ownerKey(player)
    end
    local name = d.ownerName
    return name ~= nil and name ~= "" and name == player:getUsername()
end

function CD.getState(animal)
    return CD.data(animal).state or CD.STATE_FOLLOW
end

function CD.setState(animal, state)
    local d = CD.data(animal)
    d.state = state
    -- Um comando do dono (Follow/Stay/Guard/select) é a ÚNICA coisa que tira um cão da auto-alimentação. Carimba uma
    -- janela curta de yield para que tryAutoFeed saia de cena e o cão obedeça a ordem AGORA, em vez de terminar primeiro
    -- a caminhada até uma tigela (ou sua refeição). Só handlers de comando chamam CD.setState, então isto nunca dispara sozinho.
    d.feedYieldUntilMin = CD.worldMinutes() + (CD.FEED_COMMAND_YIELD_MIN or 5)
end

function CD.loyalty(animal)
    return CD.getTrust(animal)
end

function CD.setLoyalty(animal, value)
    CD.setTrust(animal, value)
end

-- Calma do carinho: derivada so do timestamp (shared), entao client e server calculam o mesmo valor sem sync extra.
function CD.petCalm(animal)
    local stamp = CD.data(animal).petCalmMin
    if not stamp then return 0 end
    local elapsed = CD.worldMinutes() - stamp
    if elapsed < 0 then elapsed = 0 end
    local c = CD.PET_CALM_RELIEF * (1 - elapsed / CD.PET_CALM_DURATION_MIN)
    if c < 0 then c = 0 end
    return c
end

function CD.getStress(animal)
    local d = CD.data(animal)
    local s = (d.stress or 0) + (d.combatStress or 0) - CD.petCalm(animal)
    if s < 0 then s = 0 elseif s > 1 then s = 1 end
    return s
end

function CD.setStress(animal, value)
    if value < 0 then value = 0 end
    if value > 1 then value = 1 end
    CD.data(animal).stress = value
end

function CD.addCombatStress(animal, delta)
    local d = CD.data(animal)
    local v = (d.combatStress or 0) + delta
    if v < 0 then v = 0 elseif v > 1 then v = 1 end
    d.combatStress = v
end

-- Anti-fuga-ao-grito: a engine faz um companion FUGIR quando um humano grita perto (IsoAnimal.respondToSound pega o
-- WorldSound do Callout e pathea o cao pra LONGE + animalRunning + stress, persistindo ate parar). O unico ramo que NAO
-- foge e quando a aceitacao do cao pelo gritante e > 40 -> ai ele VEM (ja casa com o follow). Nasce 0-20 (< 40), entao
-- fixamos alta. respondToSound so roda no server/SP -> cobre SP e MP. Mesmo gate (>= 40) cobre fleeFromChr (dono correndo).
CD.CALM_ACCEPTANCE = 100
function CD.calmAcceptance(animal, player)
    if not (animal and player and animal.setDebugAcceptance) then return end
    pcall(function() animal:setDebugAcceptance(player, CD.CALM_ACCEPTANCE) end)
end

-- Alimentos tóxicos / não saudáveis para cães (lista de toxicidade canina do mundo real). Casados de duas formas
-- porque alguns itens tóxicos não carregam um FoodType dedicado (ex.: Chocolate / PeanutButter / PowderedGarlic base
-- são NoExplicit, e onion/garlic/grapes compartilham os tipos genéricos Vegetables/Fruits/Herb com alimentos seguros).
CD.BAD_FOOD_TYPES = {
    Candy = true, Sugar = true, Coffee = true, Tea = true,
    Cocoa = true, Chocolate = true, HotPepper = true, Nut = true,
}
CD.BAD_FOOD_NAME_PARTS = {
    "onion", "garlic", "leek", "chive", "shallot", "scallion",
    "grape", "raisin", "chocolate", "cocoa", "coffee", "peanut",
}

-- True se alimentar com este item deve deixar um cão doente (vermelho no menu de alimentar; penalidade no server).
function CD.isBadDogFood(item)
    if not item then return false end
    local isFood = false
    pcall(function() isFood = instanceof(item, "Food") end)
    if not isFood then return false end

    local ft
    pcall(function() ft = item:getFoodType() end)
    if ft and CD.BAD_FOOD_TYPES[ft] then return true end

    local t
    pcall(function() t = item:getType() end)
    if t then
        local lt = string.lower(t)
        for _, part in ipairs(CD.BAD_FOOD_NAME_PARTS) do
            if string.find(lt, part, 1, true) then
                -- "grapefruit" (cítrico) carrega o substring "grape" mas NÃO é a uva tóxica: pular.
                if not (part == "grape" and string.find(lt, "grapefruit", 1, true)) then
                    return true
                end
            end
        end
    end
    return false
end

-- True se um cão vai comer este item de uma tigela/cocho. Fonte única de verdade compartilhada pela auto-alimentação
-- (server) e pelo menu "Add food" da tigela (client): itens específicos de ração de cão por full type (incl. a lata
-- selada) + AnimalFeedType / Food FoodType em CD.TROUGH_EAT_TYPES. Exclui comida podre.
function CD.isTroughFood(item)
    if not item then return false end
    local ok = false
    pcall(function()
        if instanceof(item, "Food") and item:isRotten() then return end
        local ft0 = item.getFullType and item:getFullType()
        if ft0 and CD.TROUGH_EAT_ITEMS and CD.TROUGH_EAT_ITEMS[ft0] then ok = true; return end
        local aft = item.getAnimalFeedType and item:getAnimalFeedType()
        if aft and aft ~= "" and CD.TROUGH_EAT_TYPES and CD.TROUGH_EAT_TYPES[aft] then ok = true; return end
        if instanceof(item, "Food") then
            local ftype = item.getFoodType and item:getFoodType()
            if ftype and CD.TROUGH_EAT_TYPES and CD.TROUGH_EAT_TYPES[ftype] then ok = true end
        end
    end)
    return ok
end

-- Dimensionamento da mordida para alimentação à mão/stashed: quanto de `food` consumir para um cão que precisa de
-- `need` de fome (nil = valor inteiro). Retorna { hunger = restauro negativo, partialFrac = nil para mordida cheia },
-- ou { fallback = true, hunger } para um item não-comestível (chamador envia a fome do item inteiro). Fonte única para
-- ISCDFeedDog e o caminho de drive-feed.
function CD.computeBite(food, need)
    local foodVal = 0
    pcall(function() foodVal = -(food:getHungerChange() or 0) end)
    if foodVal <= 0 then
        local hung = 0
        pcall(function() hung = food:getHungerChange() or 0 end)
        return { fallback = true, hunger = hung }
    end
    local consumed = need or foodVal
    if consumed < 0 then consumed = 0 end
    local minBite = math.min(foodVal, CD.FEED_MIN_BITE or 0.05)
    if consumed < minBite then consumed = minBite end
    if consumed > foodVal then consumed = foodVal end
    local partialFrac
    if foodVal - consumed >= 0.01 then partialFrac = consumed / foodVal end
    -- Sede vem do proprio item (frutas hidratam, pao nao); positivo (salgado) nao penaliza o cao
    local thirstBite
    pcall(function()
        local thirstVal = -(food:getThirstChange() or 0)
        if thirstVal > 0 then thirstBite = -(thirstVal * (consumed / foodVal)) end
    end)
    return { hunger = -consumed, thirst = thirstBite, partialFrac = partialFrac }
end

-- Reduz Unhappiness + Boredom (escala 0-100) do player em n. Protege n<=0 para que um alívio não-positivo nunca ADICIONE humor.
function CD.relieveMood(player, n)
    if not player or not n or n <= 0 then return end
    pcall(function()
        local stats = player:getStats()
        stats:remove(CharacterStat.UNHAPPINESS, n)
        stats:remove(CharacterStat.BOREDOM, n)
    end)
end

-- Buff "Bem Descansado": dormir perto do cao abre uma janela temporizada gravada no ModData do player.
-- worldMinutes() e monotonico (idade do mundo), entao o timestamp continua valido apos relog.
function CD.startRestedBuff(player)
    if not player then return end
    CD.playerData(player).restedUntilMin = CD.worldMinutes() + CD.restedBuffDurationMin()
end

-- Aplica o buff por tick (elapsedMin ja vem throttled/capado do loop de moodles). Tudo e remocao instantanea
-- e clampada pela engine (Panic/Unhappy/Boredom 0-100; Stress/Fatigue 0-1), entao nao ha estado a limpar:
-- quando o timestamp passa, o moodle some e o efeito para sozinho. Endurance fica de fora (evita stamina infinita).
function CD.applyRestedBuff(player, elapsedMin)
    if not player or not elapsedMin or elapsedMin <= 0 then return end
    pcall(function()
        local s = player:getStats()
        s:remove(CharacterStat.PANIC, CD.RESTED_PANIC_PER_MIN * elapsedMin)
        s:remove(CharacterStat.STRESS, CD.RESTED_STRESS_PER_MIN * elapsedMin)
        s:remove(CharacterStat.FATIGUE, CD.RESTED_FATIGUE_PER_MIN * elapsedMin)
    end)
    CD.relieveMood(player, CD.RESTED_MOOD_PER_MIN * elapsedMin)
end

-- O que o player pode despejar no lado de comida da NOSSA tigela: QUALQUER comida não-podre que restaura fome (carne,
-- ovos, refeições cozidas, vegetais...), já que uma vez despejado são só pontos de restauro, o tipo original do item
-- deixa de importar. Também mantém o whitelist explícito de ração de cão (isTroughFood) para itens que podem ler 0 de
-- fome (ex.: o saco seco CantEat). Comidas tóxicas NÃO são excluídas aqui: o menu/server as marca + bloqueia separadamente (isBadDogFood) para o player ver o porquê.
function CD.isBowlFood(item)
    if not item then return false end
    if CD.isTroughFood(item) then return true end
    local ok = false
    pcall(function()
        if instanceof(item, "Food") and not item:isRotten() and (item:getHungerChange() or 0) < 0 then ok = true end
    end)
    return ok
end

-- Este full type é a NOSSA tigela (CompanionDogs_Config.DISH_TYPE)? Usado pelo scan de auto-alimentação e pelo
-- menu de contexto da tigela. Uma única tigela contém comida e água; o que ela oferece é decidido por estoque + necessidade, não pelo tipo de item.
function CD.isDishType(fullType)
    return fullType == CD.DISH_TYPE
end

-- Quantos "pontos" de comida um item de comida adiciona a uma tigela (a tigela é um orçamento de restauro de fome
-- 0..100): seu valor de fome em runtime (0..1) como porcentagem 0-100, então um DogFoodBag (-0.6) = 60 pontos e um vegetal pequeno (-0.1) = 10. Mín 1.
function CD.dishMealsForFood(item)
    local hc = 0
    pcall(function() hc = (item.getHungerChange and item:getHungerChange()) or 0 end)
    local points = math.floor((math.abs(hc) * 100) + 0.5)
    if points < 1 then points = 1 end
    return points
end

-- Faz uma tigela largada refletir seu conteúdo (vazia / comida marrom / água azul) acionando um FluidContainer
-- COSMÉTICO (a tigela é declarada como um em companiondogs_bowl.txt). O WorldItemAtlas da engine auto-renderiza o
-- modelo vanilla WaterDish_Fluid tingido pela COR do fluido sobre o octágono FLUIDTINT quando o fluido é >50%, e (este é
-- o ponto todo) re-tira um snapshot do item largado AO VIVO sempre que o nível/cor do fluido muda (ItemTexture.isStillValid()
-- observa getFilledRatio()/getColor()). Este é o MESMO caminho nativo que tigelas de água / panelas vanilla usam, então é
-- crash-safe (diferente do hack anterior setWorldStaticModel+worldScale, que forçava um rebuild da render-thread do nosso
-- modelo custom e crashava). O fluido é puramente visual; o gameplay fica no ModData. cdVisual rastreia o último estado para
-- só mexermos no fluido numa mudança real (não a cada tick de consumo). syncItemFields replica o fluido para clients de co-op.
function CD.refreshDishModel(item, localOnly)
    if not item then return end
    pcall(function()
        local md = item:getModData()
        local want
        if (md.cdFoodMeals or 0) > 0 then want = "food"
        elseif (md.cdWater or 0) > 0 then want = "water"
        else want = "empty" end
        -- Resolve o FluidContainer a partir do item OU do seu world object largado. Quando a tigela está no chão a
        -- engine TRANSFERE o componente FluidContainer do InventoryItem para seu IsoWorldInventoryObject (ver o
        -- construtor de IsoWorldInventoryObject), então item:getFluidContainer() é nil ali e o fluido nunca seria
        -- atualizado. getFluidContainerFromSelfOrWorldItem() é o helper da própria engine para exatamente isso (o mesmo fallback
        -- que o WorldItemAtlas usa para renderizar o fluido), então funciona tanto no inventário quanto no chão.
        local fc
        if item.getFluidContainerFromSelfOrWorldItem then fc = item:getFluidContainerFromSelfOrWorldItem()
        else fc = item.getFluidContainer and item:getFluidContainer() end
        if not fc then md.cdVisual = want; return end
        -- Guard idempotente: re-aplica quando o estado desejado mudou OU o fluido fisicamente discorda (um refresh anterior
        -- pode ter rodado enquanto o componente ainda estava vazio / no item). Não confie no cdVisual sozinho, ou uma tigela presa
        -- no meio da transição nunca repintaria.
        local applied = false
        pcall(function()
            local empty = fc:isEmpty()
            if want == "empty" then applied = (md.cdVisual == "empty") and empty
            else applied = (md.cdVisual == want) and (not empty) end
        end)
        if applied then return end
        pcall(function() fc:removeFluid() end)
        if want ~= "empty" then
            local fluidName = (want == "food") and (CD.DISH_FLUID_FOOD or "CompanionDogsKibble")
                or (CD.DISH_FLUID_WATER or "CompanionDogsBowlWater")
            -- Fluidos modded resolvem por STRING (Fluid.Get -> fluidStringMap); o enum FluidType não tem constante para eles
            -- (FromNameLower retorna nil), então passe o nome puro e deixe a sobrecarga String do container resolver.
            pcall(function() fc:addFluid(fluidName, fc:getCapacity()) end)
        end
        -- No chão o fluido vive no world object: invalida seu render chunk para que o FBO re-renderize a nova
        -- cor (a re-checagem ao vivo do atlas é ignorada enquanto cacheado por chunk). sync()/syncItemFields pulado quando localOnly.
        local wo = item.getWorldItem and item:getWorldItem()
        if wo then
            pcall(function() local rsq = wo:getRenderSquare(); if rsq then rsq:invalidateRenderChunkLevel(68) end end)
            if not localOnly and wo.sync then pcall(function() wo:sync() end) end
        elseif not localOnly then
            pcall(function() if item.syncItemFields then item:syncItemFields() end end)
        end
        md.cdVisual = want
    end)
end

function CD.isDisloyal(animal)
    return CD.isCompanion(animal) and CD.loyalty(animal) < CD.effectiveLoyaltyFloor(animal)
end

function CD.isWounded(animal)
    return CD.data(animal).wounded == true
end

-- Intoxicado por uma refeição tóxica: um estado temporizado setado no feed ruim (server), mostrado pelo moodle de
-- doente do HUD e limpo quando a janela passa (updateUpkeep). Compara contra a idade do mundo, que é sincronizada em
-- MP, então um client lendo o d.sickUntilMin transmitido concorda com o server.
function CD.isSick(animal)
    local u = CD.data(animal).sickUntilMin
    return u ~= nil and CD.worldMinutes() < u
end

function CD.isWoundedCritical(animal)
    return CD.data(animal).woundedCritical == true
end

function CD.woundLevel(animal)
    local d = CD.data(animal)
    if d.woundedCritical == true then return "critical" end
    if d.wounded == true then return "hurt" end
    return nil
end

function CD.refusalReason(animal)
    if CD.isDisloyal(animal) then return "disloyal" end
    if CD.getStress(animal) >= CD.breedPanicThreshold(animal) then return "panicked" end
    if CD.isWoundedCritical(animal) then return "wounded" end
    return nil
end

-- Nível de pânico graduado a partir do stress total: 0=calmo, 1=Nervoso (>=50%), 2=Panicando (>=80%, pânico funcional), 3=Apavorado (>=100%).
function CD.panicTier(animal)
    local s = CD.getStress(animal)
    if s >= CD.PANIC_TIER3_FRAC then return 3
    elseif s >= CD.PANIC_TIER2_FRAC then return 2
    elseif s >= CD.PANIC_TIER1_FRAC then return 1 end
    return 0
end

function CD.statusBadge(animal)
    if CD.isWoundedCritical(animal) then
        return { key = "IGUI_PD_StatusWoundedCritical", r = 0.90, g = 0.30, b = 0.26 }
    end
    local tier = CD.panicTier(animal)
    if tier >= 3 then
        return { key = "IGUI_PD_StatusTerrified", r = 0.92, g = 0.22, b = 0.18 }
    end
    if tier >= 2 then
        return { key = "IGUI_PD_StatusPanicked", r = 0.95, g = 0.45, b = 0.20 }
    end
    if CD.isDisloyal(animal) then
        return { key = "IGUI_PD_StatusDisloyal", r = 0.95, g = 0.80, b = 0.25 }
    end
    if CD.isWounded(animal) then
        return { key = "IGUI_PD_StatusWounded", r = 0.94, g = 0.66, b = 0.24 }
    end
    if tier >= 1 then
        return { key = "IGUI_PD_StatusNervous", r = 0.95, g = 0.85, b = 0.30 }
    end
    return nil
end

function CD.getAlertMode(animal)
    local d = CD.data(animal)
    if d.alertMode == "full" or d.alertMode == "quiet" or d.alertMode == "silent" then
        return d.alertMode
    end
    if d.alertSilent == true then return "silent" end
    return "full"
end

function CD.setAlertMode(animal, mode)
    if mode ~= "full" and mode ~= "quiet" and mode ~= "silent" then return end
    local d = CD.data(animal)
    d.alertMode = mode
    d.alertSilent = (mode == "silent")
end

function CD.setSentinelSilent(animal, silent)
    CD.setAlertMode(animal, silent and "silent" or "full")
end

-- Toggle de auto-protect por cão (default ON no tame): quando ligado, o cão auto-guarda ancorado no dono
-- enquanto o dono faz uma ação vulnerável/estacionária (dormir/comer/ler/sentar/pescar). Espelha o toggle
-- de alertMode (ModData + transmit). makeCompanion liga por padrão; setAutoProtect(false) grava nil -> off.
function CD.getAutoProtect(animal)
    return CD.data(animal).autoProtect == true
end

function CD.setAutoProtect(animal, on)
    CD.data(animal).autoProtect = (on == true) or nil
end

-- Toggle de "Hunt mode" por cão (opt-in, default off): quando ligado e o cão está em FOLLOW, ele rastreia/aponta caça
-- selvagem e (no nível de Hunt desbloqueado) persegue e abate presas pequenas/grandes. Espelha o padrão
-- ModData+transmit de alertMode/autoProtect. NÃO setado em makeCompanion para que um cão recém-domado comece desligado.
-- O XP passivo por abate do dono + bônus de forrageamento rodam independente deste toggle (o toggle só controla o comportamento ativo de rastrear/perseguir).
function CD.getHuntMode(animal)
    return CD.data(animal).huntMode == true
end

function CD.setHuntMode(animal, on)
    CD.data(animal).huntMode = (on == true) or nil
end

function CD.notifyOwner(owner, command, args)
    if not owner then return end
    if isServer() then
        sendServerCommand(owner, CD.MODULE, command, args)
    elseif CD.clientNotify then
        CD.clientNotify(command, args)
    end
end

-- Contabiliza uma morte de zumbi feita pelo cao: contador por-cao (d.zombieKills, mostrado no cabecalho da janela)
-- e, com o toggle, espelho no stat nativo "Zombie Kills" do dono. Split display/autoritativo pra nao contar 2x: o
-- write autoritativo (setZombieKills) roda server-side SO pra dono que NAO e o jogador local (dedicado: todos;
-- co-op host: os clientes), e o de display roda no cliente do dono via clientNotify.
function CD.recordDogZombieKill(animal)
    local d = CD.data(animal)
    d.zombieKills = (d.zombieKills or 0) + 1
    if not CD.countDogKillsForPlayer() then return end
    local owner = CD.getOwnerPlayer(animal)
    if not owner then return end
    if isServer() then
        local me = getPlayer()
        if not (me and owner:getUsername() == me:getUsername()) then
            pcall(function() owner:setZombieKills(owner:getZombieKills() + 1) end)
        end
    end
    CD.notifyOwner(owner, "dogzombiekill", {})
end

-- ===== Canil persistente (kennel) =================================================================
-- Rede de seguranca duravel contra a perda de vinculo/skills quando o copyFrom da engine descarta o ModData do cao.
-- Vive no ModData do JOGADOR (persiste no save, ja ancora a posse via pd.companions), chaveado pelo companionToken.
-- Skills sao marca d'agua: nunca regridem. Server-only.
local KENNEL_FIELDS = {
    -- Dono de origem: o snapshot precisa dizer de QUEM ele e, senao uma entrada gravada no bucket errado
    -- (posse mal resolvida) fica indistinguivel de uma legitima. E a base do reparo (CD.repairOwnership).
    "ownerKey", "ownerName",
    "uid", "breed", "sex", "genes", "lineage", "generation",
    "motherUid", "fatherUid", "motherName", "fatherName", "motherBreed", "fatherBreed",
    "name", "trust", "state",
    -- Campos pro recall-respawn fiel (tela Meus Caes): filhote, bolsa, limiar de ferido e preferencias por-cao.
    "isPup", "bornMin", "growthPaused", "bag", "maxHealth", "autoProtect", "alertMode", "huntMode",
    -- Contadores de morte do cao (mostrados na janela): sobrevivem ao respawn-from-kennel.
    "zombieKills", "preyKills",
}

-- Fingerprint estavel por cao pra desempate quando o token se perde num reload (wipe total). So consultiva.
function CD.kennelFingerprint(animal)
    local d = CD.data(animal)
    local g = ""
    if type(d.genes) == "table" then
        local keys = {}
        for k in pairs(d.genes) do keys[#keys + 1] = k end
        table.sort(keys)
        for _, k in ipairs(keys) do
            g = g .. k .. ":" .. tostring(math.floor((d.genes[k] or 0) * 100 + 0.5)) .. ","
        end
    end
    return tostring(CD.getBreed(animal)) .. "|" .. tostring(d.sex or CD.animalSex(animal) or "?")
        .. "|" .. tostring(d.name or "") .. "|" .. g
end

-- Grava/atualiza o snapshot durável do cao no canil do dono. Merge de skills por MAXIMO (nunca reduz XP).
function CD.kennelSnapshot(player, animal)
    if isClient() then return end
    if not player or not animal then return end
    local d = CD.data(animal)
    local token = d.companionToken
    if token == nil then return end
    -- Identidade compartilhada corpo<->snapshot: sem uid no cao VIVO, um recall cunharia um uid novo e o corpo
    -- abandonado (sem uid) nunca seria comido pelo reaper keeper-by-uid -> duplicata permanente. Cunha AGORA.
    if not d.uid then
        CD.ensureUid(animal)
        CD.transmit(animal)
    end
    local pd = CD.playerData(player)
    pd.kennel = pd.kennel or {}
    local snap = pd.kennel[token] or {}
    for _, f in ipairs(KENNEL_FIELDS) do
        if d[f] ~= nil then snap[f] = CD.deepCopy(d[f]) end
    end
    -- Estado deliberadamente NIL-avel espelha incluindo nil: a marca d'agua ressuscitaria bolsa largada /
    -- filhote ja maturado / toggles desligados no recall. Cao com ModData wipado nem chega aqui (sem companionToken).
    snap.bag = CD.deepCopy(d.bag)
    snap.isPup = d.isPup
    snap.growthPaused = d.growthPaused
    snap.autoProtect = d.autoProtect
    snap.huntMode = d.huntMode
    -- d.sex so existe em filhote (makePuppy); adulto domado depende do TYPE da engine. Sem isto o recall de
    -- longe respawnaria toda femea domada como MACHO (mesh errada + inelegivel como matriz no breeding).
    if snap.sex == nil then
        local sx = CD.animalSex(animal)
        if sx == "male" or sx == "female" then snap.sex = sx end
    end
    snap.companionToken = token
    snap.fp = CD.kennelFingerprint(animal)
    snap.savedAtMin = CD.worldMinutes()
    -- Ultima posicao/idade/needs vistas (recall + "visto por ultimo" da tela Meus Caes). Padrao de leitura de
    -- buildStashRecord (gunHungerSave cobre o snapshot de gun-guard). Snapshot de animal vivo prova que nao esta perdido.
    pcall(function()
        snap.x, snap.y, snap.z = math.floor(animal:getX()), math.floor(animal:getY()), math.floor(animal:getZ())
        snap.age = animal:getAge()
        snap.hunger = d.gunHungerSave or animal:getHunger()
        snap.thirst = animal:getThirst()
        snap.hp = animal:getHealth()
    end)
    snap.lost = nil
    snap.skills = snap.skills or {}
    if type(d.skills) == "table" then CD.mergeSkillsMax(snap.skills, d.skills) end
    pd.kennel[token] = snap
    -- Espelho durável de nível-mundo (sobrevive à morte do personagem), keyed pela chave estável do dono.
    if CD.kennelGlobalPut then CD.kennelGlobalPut(CD.ownerKey(player), token, snap) end
    pcall(function() player:transmitModData() end)
end

-- Espelho throttled do canil pra caes PASSIVOS (o espelho do ativo vive em updateCompanion, que so roda pro
-- pd.token). Chamado do present-loop de processNearbyDogs; e tambem o backfill de saves anteriores a tela Meus Caes.
function CD.kennelMirror(player, animal)
    if isClient() then return end
    local d = CD.data(animal)
    local now = CD.worldMinutes()
    if d.lastKennelMin and (now - d.lastKennelMin) < (CD.KENNEL_MIRROR_MIN or 30) then return end
    d.lastKennelMin = now
    CD.kennelSnapshot(player, animal)
end

-- Decide se o slot pd.companions[vt] de um CLONE ceifado pode ser limpo. So quando o token e orfao SO do clone
-- (caso legado de token re-mintado pela de-colisao): clone e canonico sao o MESMO cao, entao na regra geral
-- compartilham o token -- limpar orfanaria o cao sobrevivente do conjunto de vinculo (ele some da tela Meus Caes
-- e o re-attach de trailer/colo/stash passa a julga-lo stale -> volta selvagem). Token com entrada no canil
-- pertence a uma identidade real (do canonico deste uid ou de outro cao): nunca limpa.
function CD.cloneSlotShouldClear(pd, vt, keeperTok)
    if vt == nil or type(pd.companions) ~= "table" then return false end
    if vt == pd.token then return false end
    if keeperTok ~= nil and vt == keeperTok then return false end
    if type(pd.kennel) == "table" and pd.kennel[vt] ~= nil then return false end
    return true
end

-- Semeia um snapshot a partir do ModData cru de um registro orfao (colo/stash), sem animal vivo. Melhor-esforco
-- (sem posicao/idade/needs; sexo de adulto pode faltar), mas torna o cao recuperavel pelo recall.
function CD.kennelSeedFromData(player, tok, data)
    if isClient() then return false end
    if not player or tok == nil or type(data) ~= "table" then return false end
    local pd = CD.playerData(player)
    if type(pd.kennel) == "table" and type(pd.kennel[tok]) == "table" then return false end
    pd.kennel = pd.kennel or {}
    local snap = {}
    for _, f in ipairs(KENNEL_FIELDS) do snap[f] = CD.deepCopy(data[f]) end
    snap.companionToken = tok
    snap.savedAtMin = CD.worldMinutes()
    snap.skills = CD.deepCopy(data.skills) or {}
    pd.kennel[tok] = snap
    if CD.kennelGlobalPut then CD.kennelGlobalPut(CD.ownerKey(player), tok, snap) end
    return true
end

-- Marca um companheiro como PERDIDO (sumiu do mundo mas o snapshot do canil permite o recall) em vez de apagar o
-- vinculo. Mantem pd.companions/pd.kennel/anchor; so solta o ponteiro ativo. Retorna true na PRIMEIRA marcacao
-- (o chamador notifica o dono uma vez). Sem snapshot no canil nao ha o que recuperar: retorna nil e o chamador
-- segue com a limpeza legada.
function CD.markCompanionLost(player, token)
    if not player or token == nil then return nil end
    local pd = CD.playerData(player)
    local snap = pd.kennel and pd.kennel[token]
    if not snap then return nil end
    if snap.lost == true then return false end
    snap.lost = true
    if CD.kennelGlobalPut then CD.kennelGlobalPut(CD.ownerKey(player), token, snap) end
    if token == pd.token then pd.token = nil; pd.name = nil end
    pcall(function() player:transmitModData() end)
    return true
end

-- Reidrata campos AUSENTES de d.* a partir do canil e faz merge de skills por MAXIMO. Retorna true se aplicou algo.
function CD.restoreFromKennel(player, animal)
    if isClient() then return false end
    if not player or not animal then return false end
    local d = CD.data(animal)
    local token = d.companionToken
    if token == nil then return false end
    local pd = CD.playerData(player)
    local snap = pd.kennel and pd.kennel[token]
    if not snap then return false end
    local changed = false
    for _, f in ipairs(KENNEL_FIELDS) do
        if d[f] == nil and snap[f] ~= nil then d[f] = CD.deepCopy(snap[f]); changed = true end
    end
    if type(snap.skills) == "table" then
        d.skills = d.skills or {}
        CD.mergeSkillsMax(d.skills, snap.skills)
        changed = true
    end
    return changed
end

function CD.clearKennel(player, token)
    if not player or token == nil then return end
    local pd = CD.playerData(player)
    if type(pd.kennel) == "table" then pd.kennel[token] = nil end
    -- Poda o espelho durável de nível-mundo também: cão solto/morto-sem-snapshot não deve ser reclaimado depois.
    if CD.kennelGlobalDrop then CD.kennelGlobalDrop(CD.ownerKey(player), token) end
end

function CD.makeCompanion(animal, player)
    local d = CD.data(animal)
    d.companion = true
    d.ownerId = nil   -- id de SESSAO: nunca mais gravado (ver CD.isOwnedBy); limpa residuo de save antigo
    d.ownerName = player:getUsername()
    d.ownerKey = CD.ownerKey(player)
    d.state = CD.STATE_FOLLOW
    d.autoProtect = true   -- ligada por padrao no tame; desligar grava nil (setAutoProtect) e volta a off
    d.maxHealth = animal:getHealth()
    CD.initSkills(animal)
    CD.rollBreedGenes(animal)
    -- Ascendencia: um cao domado e puro da sua raca (raiz da linhagem). Filhotes recebem um lineage blendado dos pais.
    d.lineage = d.lineage or { [CD.getBreed(animal)] = 1.0 }

    local pd = CD.playerData(player)
    -- Cunha um token estritamente maior que todo token que o dono já possui. Um (pd.seq + 1) solto pode COLIDIR
    -- com um cão existente se pd.seq foi resetado abaixo de um token vivo (ex.: morte do personagem apaga o pd
    -- por personagem mas os cães antigos mantêm seus tokens) -> dois cães compartilham um token, ambos lidos como
    -- "active", e nenhum oferece a opção Select. Pular além de max(pd.companions) torna o token único.
    local m = pd.seq or 0
    if type(pd.companions) == "table" then for k in pairs(pd.companions) do if k > m then m = k end end end
    pd.seq = m + 1
    pd.token = pd.seq
    pd.name = d.name
    d.companionToken = pd.token
    -- Contabiliza este cão na contagem de companions do dono (limite MaxCompanions). Conjunto chaveado por token;
    -- removido em release/morte. Mantido inline (não via um novo helper CD.*) para ser seguro na VM do server.
    pd.companions = pd.companions or {}
    pd.companions[d.companionToken] = true

    if animal.setWild then animal:setWild(false) end
    -- Recem-domado comeca saciado e calmo: zera fome/sede nativas (replicam pela sync de animal da engine) e o
    -- estresse herdado da vida selvagem, pra nao nascer no gate de panico (0.80) nem aparecer faminto.
    pcall(function()
        local stats = animal:getStats()
        if CharacterStat then
            stats:set(CharacterStat.HUNGER, 0)
            stats:set(CharacterStat.THIRST, 0)
        else
            if stats.setHunger then stats:setHunger(0) end
            if stats.setThirst then stats:setThirst(0) end
        end
    end)
    d.stress = 0
    d.combatStress = 0
    pcall(function() if animal.setDebugStress then animal:setDebugStress(0) end end)
    -- Imunidade permanente a atropelamento: um companion é sempre invencível (re-afirmado por tickCompanionInvincible).
    -- O loop de upkeep dirige fome/sede/morte-por-negligência à mão já que isto congela os nativos da engine.
    pcall(function() animal:setIsInvincible(true) end)
    CD.calmAcceptance(animal, player)   -- nao foge ao grito do dono (re-afirmado por tickCompanionInvincible p/ todos os players)
    CD.kennelSnapshot(player, animal)   -- semeia a base durável (canil)
end

-- Cria o vinculo de um FILHOTE recem-nascido (irmao do makeCompanion). Diferencas: nasce PASSIVO (STATE_STAY,
-- nunca rouba o cao ativo pd.token), injeta genes blendados ANTES do initSkills (rollBreedGenes vira no-op), grava
-- a ascendencia (lineage) e o pedigree, e carimba o uid AGORA (nao-lazy). Conta no limite MaxCompanions (decisao:
-- filhote ocupa slot desde o nascimento). Server-only (chamado por CD.whelpLitter). info = ver CD.whelpLitter.
function CD.makePuppy(animal, player, info)
    local d = CD.data(animal)
    d.companion = true
    d.ownerId = nil
    d.ownerName = player:getUsername()
    d.ownerKey = CD.ownerKey(player)
    d.state = CD.STATE_STAY
    d.maxHealth = animal:getHealth()
    d.trust = CD.PUPPY_BORN_LOYALTY or 50   -- nasce com meia lealdade (criado, nao domado do zero)
    d.isPup = true
    d.bornMin = CD.worldMinutes()
    d.sex = info.sex
    d.breed = info.breed
    d.genes = info.genes        -- injetado ANTES de initSkills -> rollBreedGenes sai cedo (idempotente)
    d.lineage = info.lineage
    -- pedigree
    d.generation = info.generation
    d.motherUid = info.motherUid
    d.fatherUid = info.fatherUid
    d.motherName = info.motherName
    d.fatherName = info.fatherName
    d.motherBreed = info.motherBreed
    d.fatherBreed = info.fatherBreed
    CD.ensureUid(animal)
    CD.initSkills(animal)       -- d.breed ja setado; cria d.skills = {} (filhote comeca sem skill)

    local pd = CD.playerData(player)
    local m = pd.seq or 0
    if type(pd.companions) == "table" then for k in pairs(pd.companions) do if k > m then m = k end end end
    pd.seq = m + 1
    d.companionToken = pd.seq
    pd.companions = pd.companions or {}
    pd.companions[d.companionToken] = true
    -- NAO seta pd.token: o cao de trabalho ativo do dono continua o mesmo; o filhote nasce parado.

    if animal.setWild then animal:setWild(false) end
    d.stress = 0
    d.combatStress = 0
    pcall(function()
        local stats = animal:getStats()
        if CharacterStat then
            stats:set(CharacterStat.HUNGER, 0)
            stats:set(CharacterStat.THIRST, 0)
        end
    end)
    pcall(function() animal:setIsInvincible(true) end)
    CD.kennelSnapshot(player, animal)   -- filhote entra no canil durável ao nascer
end

-- Herança em SP: re-chaveia um companion órfão (seu antigo dono = um personagem morto cujo username não bate
-- mais) para o player ATUAL, preservando skills/genes/loyalty. NÃO é um tame novo: sem initSkills/rollBreedGenes,
-- e o limite MaxCompanions é intencionalmente ignorado (herdar nunca deve descartar um cão silenciosamente). Espelha
-- a cunhagem de token único do makeCompanion (um personagem morto apaga o pd por personagem mas os cães antigos mantêm
-- seus tokens, então um seq+1 solto poderia colidir). O primeiro cão herdado vira ACTIVE (pd.token); os demais ficam parados (STATE_STAY).
function CD.adoptOrphan(animal, player)
    local d = CD.data(animal)
    d.companion = true
    d.ownerId = nil
    d.ownerName = player:getUsername()
    d.ownerKey = CD.ownerKey(player)

    local pd = CD.playerData(player)
    local m = pd.seq or 0
    if type(pd.companions) == "table" then for k in pairs(pd.companions) do if k > m then m = k end end end
    pd.seq = m + 1
    d.companionToken = pd.seq
    pd.companions = pd.companions or {}
    pd.companions[d.companionToken] = true

    if pd.token == nil then
        pd.token = d.companionToken
        pd.name = d.name
        d.state = CD.STATE_FOLLOW
    else
        d.state = CD.STATE_STAY
    end

    if animal.setWild then animal:setWild(false) end
    pcall(function() animal:setIsInvincible(true) end)
    CD.transmit(animal)
    CD.kennelSnapshot(player, animal)   -- órfão herdado entra/atualiza o canil durável
    pcall(function() player:transmitModData() end)
end

-- Reverte um companion para um animal selvagem. Os chamadores DEVEM limpar pd.companions[token] antes: demote nunca toca em pd.* então não libera slot de MaxCompanions.
function CD.demote(animal)
    -- Cães liberados largam seu saddlebag (item + cargo) no seu tile para ser recuperável, e perdem o vínculo.
    -- spillBag é idempotente e limpa d.bag; server/SP somente (protegido internamente).
    pcall(function() CD.spillBag(animal) end)
    local d = CD.data(animal)
    d.companion = false
    d.ownerId = nil
    d.ownerName = nil
    d.ownerKey = nil
    d.companionToken = nil
    d.state = nil
    d.inCombat = nil
    d.retreating = nil
    d.recallUntilMin = nil
    d.attackUntilMin = nil
    d.attackArmed = nil
    d.standDown = nil
    d.alertTier = nil
    d.mounted = nil
    d.gunHungerSave = nil
    d.huntMode = nil
    d.hunting = nil
    d.huntCooling = nil
    d.huntTargetId = nil
    d.huntAlerted = nil
    d.huntSniffXp = nil
    d.woundedPrey = nil
    d.huntRetrieve = nil
    d.huntGoingSinceMin = nil
    d.huntRetryMin = nil
    d.huntDeerHeldSinceMin = nil
    d.huntDeerHeldNotified = nil
    d.forageSpot = nil
    d.foragePointSinceMin = nil
    d.forageGoingSinceMin = nil
    d.forageRetryMin = nil
    d.forageAlerted = nil
    d.forageScoutTarget = nil
    if animal.setWild then animal:setWild(true) end
    pcall(function() animal:setShootable(true) end)
    pcall(function() animal:setIsInvincible(false) end)
    -- limpa também o GOD_MODE do guard de arma de fogo, para que um cão liberado volte a ser um animal selvagem normal e alvejável.
    pcall(function() animal:setInvulnerable(false) end)
    pcall(function() animal:setCollidable(true) end)
    pcall(function() animal:setInvisible(false, true) end)
    -- Limpa a pose de deitar/comer/farejar para que um cão liberado no meio do descanso não fique preso deitado (nada mais
    -- a limpa quando ele não é mais um companion). Broadcast como emitRestVar (server -> clients; SP seta direto).
    pcall(function()
        local oid = animal:getOnlineID()
        if isServer() then
            sendServerCommand(CD.MODULE, "animvar", { id = oid, var = CD.REST_ANIM_VAR, on = false })
            sendServerCommand(CD.MODULE, "animvar", { id = oid, var = CD.EAT_ANIM_VAR, on = false })
            sendServerCommand(CD.MODULE, "animvar", { id = oid, var = CD.SNIFF_ANIM_VAR, on = false })
        else
            animal:setVariable(CD.REST_ANIM_VAR, false)
            animal:setVariable(CD.EAT_ANIM_VAR, false)
            animal:setVariable(CD.SNIFF_ANIM_VAR, false)
        end
    end)
    CD.transmit(animal)
end

function CD.getOwnerPlayer(animal)
    if isClient() or isServer() then
        -- Resolve pela MESMA lógica de união do isOwnedBy (chave estável OU ownerName/ownerId legado), varrendo os
        -- players online. Usar exclusivamente a ownerKey aqui derrubava o dono pra nil durante a janela de sync do
        -- Steam ID (cão migrado pra key, pd.ownerKey do player ainda não sincronizado) -> "dono offline" -> churn.
        -- Dono OFFLINE (nenhum online casa) retorna nil de propósito: o maintainFollowers dirige por isto e não pode
        -- seguir o player errado (getOnlineID é por-sessão e reciclado).
        local players = getOnlinePlayers()
        if players then
            for i = 0, players:size() - 1 do
                local p = players:get(i)
                if p and CD.isOwnedBy(animal, p) then return p end
            end
        end
        return nil
    end
    return getPlayer()
end

function CD.dist2D(a, b)
    local dx = a:getX() - b:getX()
    local dy = a:getY() - b:getY()
    return math.sqrt(dx * dx + dy * dy)
end

-- O dono está montado somente quando realmente dentro de um veículo. getVehicle() é preciso (proximidade a um
-- carro estacionado NÃO deve contar).
function CD.isMounted(player)
    if not player then return false end
    local v = nil
    pcall(function() v = player:getVehicle() end)
    if v ~= nil then return true end
    local seated = false
    pcall(function() seated = player:isSeatedInVehicle() == true end)
    return seated
end

function CD.worldMinutes()
    return getGameTime():getWorldAgeHours() * 60
end

function CD.findNearbyCompanion(playerObj, radius)
    if not playerObj then return nil end
    local cell = getCell()
    if not cell then return nil end
    local px = math.floor(playerObj:getX())
    local py = math.floor(playerObj:getY())
    local pz = math.floor(playerObj:getZ())
    local best, bestDist = nil, 9999
    local R = radius or 14
    for dx = -R, R do
        for dy = -R, R do
            local sq = cell:getGridSquare(px + dx, py + dy, pz)
            if sq then
                local list = sq:getAnimals()
                if list then
                    for i = 0, list:size() - 1 do
                        local a = list:get(i)
                        if CD.isDog(a) and CD.isCompanion(a) and CD.isOwnedBy(a, playerObj) then
                            local d = CD.dist2D(a, playerObj)
                            if d < bestDist then best, bestDist = a, d end
                        end
                    end
                end
            end
        end
    end
    return best
end

function CD.getCompanionAnimal(playerObj)
    if not playerObj then return nil end
    local cell = getCell()
    if not cell then return nil end
    local list = cell:getAnimals()
    if not list then return nil end
    -- Multi-dog: prefere o companion ACTIVE (companionToken == pd.token do dono); cai para qualquer companion
    -- próprio só se nenhum bater (saves legados/pré-select). Com vários cães vinculados carregados de uma vez,
    -- "primeiro próprio" apontaria os chamadores (StatusUI/AutoProtect/MapMarker/radial) para o cão errado.
    local token = CD.playerData(playerObj).token
    local anyOwned = nil
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if CD.isDog(a) and CD.isCompanion(a) and CD.isOwnedBy(a, playerObj) then
            if token ~= nil and CD.data(a).companionToken == token then return a end
            anyOwned = anyOwned or a
        end
    end
    return anyOwned
end

function CD.spawnDog(x, y, z, atype, breedName)
    atype = atype or "dogmale"
    if not CD.TYPES[atype] then return nil end
    local def = AnimalDefinitions.getDef(atype)
    if not def then return nil end
    local breed = (breedName and def:getBreedByName(breedName)) or def:getRandomBreed()
    local animal = addAnimal(getCell(), tonumber(x), tonumber(y), tonumber(z), atype, breed, false)
    if not animal or not animal:getSquare() then return nil end
    animal:addToWorld()
    animal:randomizeAge()
    if animal.setWild then animal:setWild(false) end
    return animal
end

-- Rota UNICA de som de cao (client e SP). NUNCA usar emitter:playSound aqui: num objeto movel (o cao) o cliente
-- reenvia um PlaySoundPacket que o servidor RETRANSMITE pros outros clientes, que tocam via playSoundImpl em volume
-- CHEIO, ignorando o volume/mute deles -- e duplicado, ja que o mod ja faz o proprio broadcast. Era por isso que
-- mutar "nao fazia nada" em co-op. playSoundImpl e o mesmo caminho que a engine usa ao RECEBER o pacote: toca so aqui.
-- Mutado (fator 0) nao toca nada, em vez de tocar e baixar o volume pra zero.
CD.soundRefs = CD.soundRefs or {}   -- [onlineID][nome] = ref, so dos sons em loop (pro slider valer ao vivo neles)

function CD.playAnimalSound(animal, sound)
    if not animal or not sound then return 0 end
    local f = (CD.Settings and CD.Settings.getVolumeFactor and CD.Settings.getVolumeFactor(sound)) or 1.0
    if f <= 0 then return 0 end
    local ref = 0
    pcall(function()
        local emitter = animal:getEmitter()
        if CD.noSoundImpl then
            ref = emitter:playSound(sound)
        else
            local ok, r = pcall(function() return emitter:playSoundImpl(sound, nil) end)
            if ok then
                ref = r or 0
            else
                -- metodo nao exposto ao Lua: cai no caminho antigo (que reenvia o som pela rede e fura o mute em MP).
                -- Avisa uma vez no log: se isso aparecer, o mute volta a falhar em co-op e o fix precisa de outra rota.
                CD.noSoundImpl = true
                print("CompanionDogs: playSoundImpl indisponivel, usando playSound (mute pode falhar em MP)")
                ref = emitter:playSound(sound)
            end
        end
        if ref and ref ~= 0 then
            if f ~= 1.0 then emitter:setVolume(ref, f) end
            if CD.SOUND_LOOPED and CD.SOUND_LOOPED[sound] then
                local id = animal:getOnlineID()
                CD.soundRefs[id] = CD.soundRefs[id] or {}
                CD.soundRefs[id][sound] = ref
            end
        end
    end)
    return ref or 0
end

-- Par de CD.playAnimalSound. stopSoundByName e LOCAL (nao gera pacote), entao cada client para o seu proprio som.
function CD.stopAnimalSound(animal, sound)
    if not animal or not sound then return end
    pcall(function()
        animal:getEmitter():stopSoundByName(sound)
        local refs = CD.soundRefs[animal:getOnlineID()]
        if refs then refs[sound] = nil end
    end)
end

-- Reaplica o volume aos sons em LOOP que ja estao tocando (comer/beber): sem isso o slider so surtiria efeito no
-- proximo play, e o jogador le isso como "mexer no volume nao funciona". Chamado pelos setters do Settings.
function CD.refreshSoundVolumes()
    for id, refs in pairs(CD.soundRefs) do
        local animal = getAnimal(id)
        for name, ref in pairs(refs) do
            local f = (CD.Settings and CD.Settings.getVolumeFactor and CD.Settings.getVolumeFactor(name)) or 1.0
            if not animal then
                refs[name] = nil
            else
                pcall(function()
                    local em = animal:getEmitter()
                    if f <= 0 then
                        em:stopSoundByName(name)
                        refs[name] = nil
                    else
                        em:setVolume(ref, f)
                    end
                end)
            end
        end
        local empty = true
        for _ in pairs(refs) do empty = false; break end   -- Kahlua nao expoe next()
        if empty then CD.soundRefs[id] = nil end
    end
end

function CD.request(command, animal, extra)
    extra = extra or {}
    if isClient() then
        if animal then extra.id = animal:getOnlineID() end
        sendClientCommand(CD.MODULE, command, extra)
    elseif CD.Server and CD.Server[command] then
        if animal then extra.__animal = animal end
        CD.Server[command](getPlayer(), extra)
    end
end

-- Irmão escopado por player de CD.request para a janela "em veículo": enquanto o dono dirige, o companion é
-- DELETADO do mundo (sem animal vivo, então o getOnlineID() de CD.request não roda). Estes comandos operam no
-- registro de stash do dono (CD.playerData(player).stash) em vez de resolver um animal.
function CD.requestStashed(command, extra)
    extra = extra or {}
    if isClient() then
        sendClientCommand(CD.MODULE, command, extra)
    elseif CD.Server and CD.Server[command] then
        CD.Server[command](getPlayer(), extra)
    end
end
