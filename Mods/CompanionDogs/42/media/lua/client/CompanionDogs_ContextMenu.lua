require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISCDFeedDog"
require "TimedActions/ISCDPetDog"
require "TimedActions/ISCDWaterDog"
require "TimedActions/ISCDFillDish"
require "ISUI/Animal/ISAnimalContextMenu"

local CD = CompanionDogs

-- Percorre todo item que o jogador carrega: o inventario principal E cada bag aninhada. Espelha a recursao da
-- propria engine (ItemContainer.getItemById / containsRecursive descem em cada InventoryContainer), entao as listas
-- aqui ficam em sync com o server, que consome o item dado por id via getItemById recursivo, nao importa qual bag o guarda.
local function cdForEachCarriedItem(container, fn)
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        fn(item)
        if instanceof(item, "InventoryContainer") then
            local inner = item:getInventory()
            if inner then cdForEachCarriedItem(inner, fn) end
        end
    end
end

-- Itens de alimentacao validos que o jogador carrega (inclusive dentro de bags), agrupados por tipo (alimentar consome uma
-- instancia do grupo): Food, nao podre, que restaura fome. ISCDFeedDog:isValid() usa containsRecursive() para casar com esse escopo.
local function listFoods(playerObj)
    local groups, order = {}, {}
    cdForEachCarriedItem(playerObj:getInventory(), function(item)
        if instanceof(item, "Food") and not item:isRotten() and item:getHungerChange() < 0 then
            local key = item:getFullType()
            local g = groups[key]
            if g then
                g.count = g.count + 1
            else
                g = { item = item, count = 1, name = item:getName(), bad = CD.isBadDogFood(item) }
                groups[key] = g
                order[#order + 1] = g
            end
        end
    end)
    table.sort(order, function(a, b) return a.name < b.name end)
    return order
end

-- getAllWaterFluidSources nao recursa em bags (o boolean e includeTainted), entao desce em cada bag
-- reaproveitando o predicado da engine; escopo igual ao listFoods (server consome via getItemById recursivo).
local function cdFindWaterIn(container)
    local list = container:getAllWaterFluidSources(true)
    if list and list:size() > 0 then return list:get(0) end
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "InventoryContainer") then
            local inner = item:getInventory()
            local found = inner and cdFindWaterIn(inner)
            if found then return found end
        end
    end
    return nil
end

local function findWater(playerObj)
    return cdFindWaterIn(playerObj:getInventory())
end

local function onFeedDog(playerObj, animal, food)
    if not food then return end
    animal:stopAllMovementNow()
    if luautils.walkAdj(playerObj, animal:getSquare()) then
        ISTimedActionQueue.addGetUpAndThen(playerObj, ISCDFeedDog:new(playerObj, animal, food))
    end
end

-- Alimentos toxicos continuam selecionaveis (alimentar aplica uma penalidade server-side) mas ficam marcados em vermelho:
-- a engine nao tem cor de label por opcao, entao (1) tingimos o icone do alimento de vermelho (option.color), (2) gravamos
-- o label da opcao em menu.cdBadLabels para o wrapper de render (abaixo) desenhar esse label em vermelho, e (3) anexamos um tooltip vermelho.
local function cdApplyBadFoodCue(menu, opt, g)
    if not (opt and g and g.bad) then return end
    opt.color = { r = 1, g = 0.35, b = 0.35 }
    if menu then
        menu.cdBadLabels = menu.cdBadLabels or {}
        menu.cdBadLabels[opt.name] = true
    end
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip:setName(g.name)
    tooltip.description = "<RGB:1,0.35,0.35>" .. getText("IGUI_PD_BadFood")
    opt.toolTip = tooltip
end

-- Adiciona a entrada de alimentar em `parent`: acinzentada (+ dica "precisa de comida") quando nao ha nada comestivel, uma
-- opcao direta de um clique quando ha uma unica escolha, ou um submenu "escolha qual comida" (icone + contagem) quando ha varias.
local function addFeedEntry(parent, playerObj, animal, labelText)
    local foods = listFoods(playerObj)
    if #foods == 0 then
        local opt = parent:addOption(labelText, nil, nil)
        opt.notAvailable = true
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip:setName(getText("IGUI_PD_NeedFood"))
        opt.toolTip = tooltip
        return
    end
    if #foods == 1 then
        local opt = parent:addOption(labelText, playerObj, onFeedDog, animal, foods[1].item)
        opt.iconTexture = foods[1].item:getTexture()
        cdApplyBadFoodCue(parent, opt, foods[1])
        return
    end
    local header = parent:addOption(labelText, nil, nil)
    local sub = ISContextMenu:getNew(parent)
    parent:addSubMenu(header, sub)
    for _, g in ipairs(foods) do
        local label = g.count > 1 and (g.name .. " (" .. g.count .. ")") or g.name
        local opt = sub:addOption(label, playerObj, onFeedDog, animal, g.item)
        opt.iconTexture = g.item:getTexture()
        cdApplyBadFoodCue(sub, opt, g)
    end
end

local function onPetDog(playerObj, animal)
    animal:stopAllMovementNow()
    if luautils.walkAdj(playerObj, animal:getSquare()) then
        -- addGetUpAndThen levanta primeiro (limpa o sitOnGround do engine); interagir sentado no chao deixava a
        -- recuperacao de endurance na taxa de sentado (5x, sprint infinito) e o ataque bloqueado ate recarregar o save
        ISTimedActionQueue.addGetUpAndThen(playerObj, ISCDPetDog:new(playerObj, animal))
    end
end

local function onWaterDog(playerObj, animal, item)
    if not item then return end
    animal:stopAllMovementNow()
    if luautils.walkAdj(playerObj, animal:getSquare()) then
        ISTimedActionQueue.addGetUpAndThen(playerObj, ISCDWaterDog:new(playerObj, animal, item))
    end
end

local function onSetState(animal, playerObj, state)
    CD.request("setstate", animal, { state = state })
end

local function onCome(animal, playerObj)
    CD.request("come", animal)
end

local function onSelectDog(animal, playerObj)
    CD.request("select", animal)
end

local function onAttack(animal, playerObj)
    CD.request("attack", animal)
end

local function onInspect(animal, playerObj)
    if ISCDStatusWindow then ISCDStatusWindow.OpenFor(animal) end
end

local function onRelease(animal, playerObj)
    CD.request("release", animal)
end

-- Passa pelo pickup vanilla (restrito ao dono) para ele andar ate adjacente + enfileirar ISPickupAnimal; nosso
-- hook ISPickupAnimal:complete (CompanionDogs_Carry) entao registra o bond para restaurar ao largar.
local function onCarry(animal, playerObj)
    if AnimalContextMenu and AnimalContextMenu.onPickupAnimal then
        AnimalContextMenu.onPickupAnimal(animal, playerObj)
    end
end

local function onRenameApply(target, button, animal)
    if button.internal == "OK" then
        CD.request("rename", animal, { text = button.parent.entry:getText() })
    end
end

local function onRename(animal, playerObj)
    local modal = ISTextBox:new(0, 0, 290, 180, getText("IGUI_PD_RenameTitle", CD.breedNoun(animal)),
        CD.data(animal).name or "", nil, onRenameApply, playerObj:getPlayerNum(), animal)
    modal:initialise()
    modal:addToUIManager()
end

local function onDebugNeed(animal, playerObj, field, amount)
    CD.request("debugneeds", animal, { [field] = amount })
end

local function onDebugAllNeeds(animal, playerObj)
    CD.request("debugneeds", animal, { hunger = 0.10, thirst = 0.10, stress = 0.10 })
end

local DEBUG_SKILLS = { { key = "hunt", label = "Caca" }, { key = "combat", label = "Combate" },
                       { key = "obedience", label = "Obediencia" }, { key = "scent", label = "Faro" } }

-- set == nil -> +1 nivel; caso contrario, define direto para aquele nivel.
local function onDebugSkill(animal, playerObj, skill, set)
    if set == nil then CD.request("debugskill", animal, { skill = skill, bump = true })
    else CD.request("debugskill", animal, { skill = skill, set = set }) end
end

-- Debug de breeding (Fase A): forca gravidez do cao alvo com o cao mais proximo (gestacao curta), pari ja, ou amadurece um filhote.
local function onForceBreed(animal, playerObj) CD.request("forcebreed", animal) end
local function onForceWhelp(animal, playerObj) CD.request("forcewhelp", animal) end
local function onMaturePup(animal, playerObj) CD.request("maturepup", animal) end

-- Toggle de cruzamento por cao (liga/desliga d.breedingOff).
local function onToggleBreeding(animal, playerObj)
    CD.request("setbreedmode", animal, { off = not (CD.data(animal).breedingOff == true) })
end

-- Toggle de pausar crescimento por filhote (liga/desliga d.growthPaused).
local function onToggleGrowth(animal, playerObj)
    CD.request("setgrowthmode", animal, { paused = not (CD.data(animal).growthPaused == true) })
end

-- Diagnostico: mostra o companionToken deste cao vs o pd.token ativo do dono (e a contagem de companheiros). Se dois
-- caes leem o mesmo token == pd.token, ambos sao "ativos" e nenhum oferece Select (uma colisao que o reparo de descolisao
-- corrige). Leitura client-side do ModData sincronizado; restrito a debug como o resto deste submenu.
local function onDebugTokens(animal, playerObj)
    local pd = CD.playerData(playerObj)
    local n = 0
    if type(pd.companions) == "table" then for _ in pairs(pd.companions) do n = n + 1 end end
    local act = (CD.data(animal).companionToken ~= nil and CD.data(animal).companionToken == pd.token)
    HaloTextHelper.addText(playerObj, "dog=" .. tostring(CD.data(animal).companionToken)
        .. " active=" .. tostring(pd.token) .. " isActive=" .. tostring(act) .. " count=" .. tostring(n))
end

-- Diagnostico: o nivel de Caca do cao + animais SELVAGENS por perto (tipo + como o mod os classifica) para vermos por que uma
-- presa so e APONTADA em vez de caçada (canEngage = pequena no L3+ / grande no L6+). Espelha os prefixos huntPreyClass do
-- server; leitura client-side da skill sincronizada + os animais da cell.
local HUNT_DIAG_SMALL = { "rab", "raccoon", "mouse", "rat", "squirrel" }
local HUNT_DIAG_LARGE = { fawn = true, doe = true, buck = true, deer = true }
local function huntDiagClass(t)
    if not t then return "?" end
    if HUNT_DIAG_LARGE[t] then return "LARGE(L6)" end
    for _, p in ipairs(HUNT_DIAG_SMALL) do
        if string.sub(t, 1, string.len(p)) == p then return "small(L3)" end
    end
    return "UNHUNTABLE"
end

local function onHuntDiag(animal, playerObj)
    local lvl = CD.getSkillLevel(animal, "hunt")
    local cell = getCell()
    local ax, ay = math.floor(animal:getX()), math.floor(animal:getY())
    local found = {}
    if cell then
        for dx = -20, 20 do
            for dy = -20, 20 do
                local sq = cell:getGridSquare(ax + dx, ay + dy, 0)
                local list = sq and sq:getAnimals()
                if list then
                    for i = 0, list:size() - 1 do
                        local o = list:get(i)
                        local wild = false
                        pcall(function() wild = o:isWild() end)
                        local t = o.getAnimalType and o:getAnimalType()
                        if t then
                            local k = t .. (wild and "" or "[tame]") .. " " .. huntDiagClass(t)
                            found[k] = (found[k] or 0) + 1
                        end
                    end
                end
            end
        end
    end
    local s = "Caca lvl=" .. tostring(lvl)
    local any = false
    for k, c in pairs(found) do s = s .. " | " .. k .. " x" .. c; any = true end
    if not any then s = s .. " | nenhum animal num raio de 20" end
    HaloTextHelper.addText(playerObj, s)
end

-- Diagnostico de crescimento: mostra o tipo, se e filhote, sexo, daysSurvived/hoursSurvived (lever nativo: a engine
-- cresce em daysSurvived>=90), e quantos dias-de-jogo faltam pro nosso timer de maturacao disparar (d.bornMin +
-- maturityMinutes), + se o crescimento esta pausado. Leitura client-side de dado replicado + metodos do animal.
local function onGrowthDiag(animal, playerObj)
    local d = CD.data(animal)
    local t = (animal.getAnimalType and animal:getAnimalType()) or "?"
    local days, hrs = "?", "?"
    pcall(function() local dt = animal:getData(); if dt and dt.getDaysSurvived then days = dt:getDaysSurvived() end end)
    pcall(function() if animal.getHoursSurvived then hrs = string.format("%.0f", animal:getHoursSurvived()) end end)
    local s = "type=" .. tostring(t) .. " pup=" .. tostring(d.isPup == true) .. " sex=" .. tostring(d.sex)
        .. " days=" .. tostring(days) .. " hrs=" .. tostring(hrs) .. " engGrow@90"
    if d.isPup then
        local mins = (CD.maturityMinutes and CD.maturityMinutes()) or ((CD.MATURITY_DAYS or 90) * 24 * 60)
        local remain = ((d.bornMin or 0) + mins - CD.worldMinutes()) / 1440
        s = s .. string.format(" matura_em=%.2fd", remain)
        if d.growthPaused then s = s .. " [PAUSADO]" end
    end
    HaloTextHelper.addText(playerObj, s)
end

-- Submenu de debug num cao: +10% (0.10) instantaneo em fome/sede/stress para testar aviso/latido/panico.
local function addDebugEntry(parent, playerObj, animal)
    if not CD.debugAllowed() then return end
    local header = parent:addOption(getText("IGUI_PD_DebugNeeds"), nil, nil)
    local sub = ISContextMenu:getNew(parent)
    parent:addSubMenu(header, sub)
    sub:addOption(getText("IGUI_PD_DebugHunger"), animal, onDebugNeed, playerObj, "hunger", 0.10)
    sub:addOption(getText("IGUI_PD_DebugThirst"), animal, onDebugNeed, playerObj, "thirst", 0.10)
    sub:addOption(getText("IGUI_PD_DebugStress"), animal, onDebugNeed, playerObj, "stress", 0.10)
    sub:addOption(getText("IGUI_PD_DebugAllNeeds"), animal, onDebugAllNeeds, playerObj)
    sub:addOption("Tokens", animal, onDebugTokens, playerObj)
    sub:addOption("Hunt diag", animal, onHuntDiag, playerObj)
    sub:addOption("Growth diag", animal, onGrowthDiag, playerObj)

    local brHeader = sub:addOption("Breeding", nil, nil)
    local brSub = ISContextMenu:getNew(sub)
    sub:addSubMenu(brHeader, brSub)
    brSub:addOption("Force pregnancy (nearest dog)", animal, onForceBreed, playerObj)
    brSub:addOption("Whelp now", animal, onForceWhelp, playerObj)
    brSub:addOption("Mature pup", animal, onMaturePup, playerObj)

    local skHeader = sub:addOption("Skills", nil, nil)
    local skSub = ISContextMenu:getNew(sub)
    sub:addSubMenu(skHeader, skSub)
    for _, s in ipairs(DEBUG_SKILLS) do
        skSub:addOption(s.label .. " +1", animal, onDebugSkill, playerObj, s.key)
        skSub:addOption(s.label .. " -> Max", animal, onDebugSkill, playerObj, s.key, CD.SKILL_MAX_LEVEL)
    end
    skSub:addOption("Todas +1", animal, onDebugSkill, playerObj, "all")
    skSub:addOption("Todas -> Max", animal, onDebugSkill, playerObj, "all", CD.SKILL_MAX_LEVEL)
    skSub:addOption("Zerar todas", animal, onDebugSkill, playerObj, "all", 0)
end

local function onSpawnDog(worldobjects, playerObj, square, atype, kind)
    if not square then return end
    CD.request("spawn", nil, { type = atype, kind = kind, x = square:getX(), y = square:getY(), z = square:getZ() })
end

local function onResetSpawns(worldobjects, playerObj)
    CD.request("resetspawns", nil, {})
end

local function onEquipBag(animal, playerObj, bagItem)
    if not animal or not bagItem then return end
    CD.request("equipsaddlebag", animal, { itemId = bagItem:getID() })
end

local function onUnequipBag(animal, playerObj)
    if not animal then return end
    CD.request("unequipsaddlebag", animal, {})
end

local function onOpenBag(animal, playerObj)
    if not animal then return end
    if CD.openBagWindow then CD.openBagWindow(animal) end
end

local function onAnimalMenu(player, context, animals)
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end
    for _, animal in ipairs(animals) do
        if CD.isDog(animal) then
            addDebugEntry(context, playerObj, animal)
            if CD.isCompanion(animal) and CD.isOwnedBy(animal, playerObj) then
                local name = CD.data(animal).name or CD.breedNoun(animal)
                -- Gravida tambem no cabecalho (nivel topo do menu), nao so na linha de identidade do submenu: fica
                -- visivel sem abrir o submenu e independe dos textos flutuantes (que o jogador pode desligar).
                if CD.isPregnant(animal) then name = name .. " (" .. CD.pregnancyLabel(animal) .. ")" end
                local header = context:addOption(name, nil, nil)
                local menu = ISContextMenu:getNew(context)
                context:addSubMenu(header, menu)
                -- Linha de identidade (desabilitada): raca (+ "Mestico" quando misturado), sexo, Filhote, Gravida.
                do
                    local breedTxt = CD.breedNoun(animal)
                    if CD.isMestico(animal) then breedTxt = breedTxt .. " (" .. getText("IGUI_PD_Mestico") .. ")" end
                    local bits = { breedTxt }
                    local sx = CD.sexNoun(animal)
                    if sx then bits[#bits + 1] = sx end
                    if CD.isPuppy(animal) then bits[#bits + 1] = getText("IGUI_PD_Puppy") end
                    if CD.isPregnant(animal) then bits[#bits + 1] = CD.pregnancyLabel(animal) end
                    local infoOpt = menu:addOption(table.concat(bits, ", "), nil, nil)
                    infoOpt.notAvailable = true
                end
                -- Liga/desliga o cruzamento deste cao (so adultos; filhote nao cruza).
                if CD.animalSex(animal) ~= "pup" then
                    local off = CD.data(animal).breedingOff == true
                    local lbl = off and getText("IGUI_PD_BreedingEnable") or getText("IGUI_PD_BreedingDisable")
                    menu:addOption(lbl, animal, onToggleBreeding, playerObj)
                end
                -- Pausa/retoma o crescimento deste filhote (so filhotes; adulto ja cresceu). Legenda na tooltip.
                if CD.isPuppy(animal) then
                    local paused = CD.data(animal).growthPaused == true
                    local glbl = paused and getText("IGUI_PD_ResumeGrowth") or getText("IGUI_PD_PauseGrowth")
                    local gOpt = menu:addOption(glbl, animal, onToggleGrowth, playerObj)
                    local gTip = ISWorldObjectContextMenu.addToolTip()
                    gTip.description = getText("IGUI_PD_PauseGrowthTip")
                    gOpt.toolTip = gTip
                end
                local tok = CD.data(animal).companionToken
                local active = tok ~= nil and tok == CD.playerData(playerObj).token
                if not active then
                    -- Companheiro passivo (outro cao com vinculo do jogador, nao o ativo): oferece tornar
                    -- ativo ("Select"), acariciar, e as opcoes de admin. Feed/Water sao omitidos: um cao
                    -- passivo e invencivel + ignorado por updateUpkeep, entao a fome/sede dele ficam congeladas
                    -- (nada a alimentar). Follow/Stay/Come/Attack sao so do ativo, entao tambem ficam ocultos aqui.
                    menu:addOption(getText("IGUI_PD_Select", name), animal, onSelectDog, playerObj)
                    if CD.bondingEnabled() then
                        menu:addOption(getText("IGUI_PD_Pet"), playerObj, onPetDog, animal)
                    end
                    menu:addOption(getText("IGUI_PD_Inspect"), animal, onInspect, playerObj)
                    menu:addOption(getText("IGUI_PD_Rename"), animal, onRename, playerObj)
                    menu:addOption(getText("IGUI_PD_Carry"), animal, onCarry, playerObj)
                    menu:addOption(getText("IGUI_PD_Release"), animal, onRelease, playerObj)
                else
                    addFeedEntry(menu, playerObj, animal, getText("IGUI_PD_FeedCompanion"))
                    local water = findWater(playerObj)
                    local waterOpt = menu:addOption(getText("IGUI_PD_Water"), playerObj, onWaterDog, animal, water)
                    if not water then
                        waterOpt.notAvailable = true
                        local tooltip = ISWorldObjectContextMenu.addToolTip()
                        tooltip:setName(getText("IGUI_PD_NeedWater"))
                        waterOpt.toolTip = tooltip
                    end
                    if CD.bondingEnabled() then
                        menu:addOption(getText("IGUI_PD_Pet"), playerObj, onPetDog, animal)
                    end
                    if CD.getState(animal) == CD.STATE_FOLLOW then
                        menu:addOption(getText("IGUI_PD_Stay"), animal, onSetState, playerObj, CD.STATE_STAY)
                    else
                        menu:addOption(getText("IGUI_PD_Follow"), animal, onSetState, playerObj, CD.STATE_FOLLOW)
                    end
                    menu:addOption(getText("IGUI_PD_CmdCome"), animal, onCome, playerObj)
                    if CD.combatEnabled() then
                        menu:addOption(getText("IGUI_PD_CmdAttack"), animal, onAttack, playerObj)
                    end
                    -- Alforje (cargo): abrir/desequipar quando equipado, senao oferece equipar uma bag do inventario.
                    if CD.hasBag(animal) then
                        menu:addOption(getText("IGUI_PD_OpenBag"), animal, onOpenBag, playerObj)
                        menu:addOption(getText("IGUI_PD_UnequipBag"), animal, onUnequipBag, playerObj)
                    else
                        local bag = CD.findBagItem(playerObj)
                        if bag then
                            menu:addOption(getText("IGUI_PD_EquipBag"), animal, onEquipBag, playerObj, bag)
                        end
                    end
                    menu:addOption(getText("IGUI_PD_Inspect"), animal, onInspect, playerObj)
                    menu:addOption(getText("IGUI_PD_Rename"), animal, onRename, playerObj)
                    menu:addOption(getText("IGUI_PD_Carry"), animal, onCarry, playerObj)
                    menu:addOption(getText("IGUI_PD_Release"), animal, onRelease, playerObj)
                end
            elseif not CD.isCompanion(animal) then
                if CD.atCompanionLimit(playerObj) then
                    -- No limite de MaxCompanions: fazer amizade com um novo vira-lata fica bloqueado. Mostra a opcao de
                    -- alimentar em VERMELHO + desabilitada com um tooltip (reusa o wrapper de render de label vermelho, cdBadLabels).
                    local label = getText("IGUI_PD_Feed")
                    local opt = context:addOption(label, nil, nil)
                    opt.notAvailable = true
                    context.cdBadLabels = context.cdBadLabels or {}
                    context.cdBadLabels[label] = true
                    local tooltip = ISWorldObjectContextMenu.addToolTip()
                    tooltip:setName(getText("IGUI_PD_FeedLimit", tostring(CD.maxCompanions())))
                    opt.toolTip = tooltip
                else
                    addFeedEntry(context, playerObj, animal, getText("IGUI_PD_Feed"))
                end
            end
        end
    end
end

local function onWorldMenu(player, context, worldobjects)
    if not CD.debugAllowed() then return end
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local square
    for _, o in ipairs(worldobjects) do
        if o.getSquare and o:getSquare() then square = o:getSquare(); break end
    end
    square = square or playerObj:getCurrentSquare()
    if not square then return end

    local header = context:addOption(getText("IGUI_PD_DebugRoot"), nil, nil)
    local menu = ISContextMenu:getNew(context)
    context:addSubMenu(header, menu)
    -- Uma dupla macho/femea por raca registrada (inclui racas de addon via CD.registerBreed).
    for _, breedKey in ipairs(CD.BREED_ORDER) do
        local noun = CD.breedNounFromKey(breedKey)
        menu:addOption(getText("IGUI_PD_SpawnBreedMale", noun), worldobjects, onSpawnDog, playerObj, square, CD.breedAnimalType(breedKey, "male"), breedKey)
        menu:addOption(getText("IGUI_PD_SpawnBreedFemale", noun), worldobjects, onSpawnDog, playerObj, square, CD.breedAnimalType(breedKey, "female"), breedKey)
    end
    local resetOpt = menu:addOption(getText("IGUI_PD_ResetSpawns"), worldobjects, onResetSpawns, playerObj)
    local resetTip = ISWorldObjectContextMenu.addToolTip()
    resetTip.description = getText("IGUI_PD_ResetSpawnsTip")
    resetOpt.toolTip = resetTip
    -- Registro global dono -> caes (tela admin; o server re-checa CD.debugAllowed no handler).
    menu:addOption(getText("IGUI_PD_AdminKennel"), playerObj, function(p) CD.openAdminKennel(p) end)
end

-- Renderiza opcoes de comida ruim com TEXTO DE LABEL VERMELHO. A engine colore labels de menu por estado fixo (branco /
-- verde quando destacado / vermelho quando notAvailable), sem cor de texto por opcao, e notAvailable tambem mata o clique.
-- Entao envolvemos o render: so para um menu que carrega cdBadLabels, interceptamos brevemente o drawText dele e recolorimos
-- exatamente esses labels de vermelho, depois restauramos. Todo outro context menu cai no early-out, zero overhead.
if ISContextMenu and ISContextMenu.render and not ISContextMenu.cdRedRenderWrapped then
    local vanillaRender = ISContextMenu.render
    function ISContextMenu:render()
        local bad = self.cdBadLabels
        if not bad then return vanillaRender(self) end
        local origDrawText = self.drawText
        self.drawText = function(s, text, x, y, r, g, b, a, font)
            if text ~= nil and bad[text] then r, g, b = 1, 0.35, 0.35 end
            return origDrawText(s, text, x, y, r, g, b, a, font)
        end
        vanillaRender(self)
        self.drawText = origDrawText
    end
    ISContextMenu.cdRedRenderWrapped = true
end

-- Suprime o submenu vanilla de animal (Animal Info / Pick up / Pet / Kill Animal) para QUALQUER cao do mod,
-- selvagem ou companheiro. O mod fornece suas proprias interacoes (domar via o "fazer amizade" pela comida; o submenu
-- de companheiro); e o "Pick up" vanilla carrega-e-larga um companheiro, corrompendo o vinculo (o copyFrom da engine perde
-- o ModData Lua). Caes selvagens mantem apenas a entrada de topo do mod "alimentar para fazer amizade" (adicionada em onAnimalMenu).
if AnimalContextMenu and AnimalContextMenu.doMenu and not AnimalContextMenu.cd_doMenuWrapped then
    local vanillaDoMenu = AnimalContextMenu.doMenu
    AnimalContextMenu.doMenu = function(player, context, animal, test)
        if CD.isDog(animal) then
            return
        end
        return vanillaDoMenu(player, context, animal, test)
    end
    AnimalContextMenu.cd_doMenuWrapped = true
end

-- O DONO pode carregar seu companheiro (o vinculo e restaurado ao largar, veja CompanionDogs_Carry/recoverCarriedDogs).
-- Um nao-dono NAO pode pegar o companheiro de outra pessoa. Cobre todo caminho de pickup (opcao do contexto, nossa propria
-- opcao "Carry", e a fatia de gamepad em ISAnimalContextMenu, que passam todas por onPickupAnimal).
if AnimalContextMenu and AnimalContextMenu.onPickupAnimal and not AnimalContextMenu.cd_pickupWrapped then
    local vanillaPickup = AnimalContextMenu.onPickupAnimal
    AnimalContextMenu.onPickupAnimal = function(animal, chr)
        if chr and CD.isDog(animal) and CD.isCompanion(animal) and not CD.isOwnedBy(animal, chr) then
            HaloTextHelper.addBadText(chr, getText("IGUI_PD_NoCarryOther", CD.breedNoun(animal)))
            return
        end
        return vanillaPickup(animal, chr)
    end
    AnimalContextMenu.cd_pickupWrapped = true
end

-- O menu do ITEM-de-inventario do cao companheiro carregado (clique direito no item "Animal") e construido inteiro pelo
-- AnimalContextMenu.doInventoryMenu vanilla: Animal Info / Drop / Feed / Give Water / Kill Animal. Dois deles sao errados
-- para um companheiro: "Kill Animal" mataria seu proprio cao, e o "Drop" vanilla trava para sempre ("Dropping") de
-- dentro de um veiculo. Reconstroi o menu para um companheiro PROPRIO: MANTEM as entradas em-maos que funcionam (Animal Info /
-- Feed / Give Water, a unica forma de inspecionar e cuidar de um cao carregado, o cao esta fora do mundo entao o menu
-- de mundo nao o alcanca), REMOVE "Kill Animal", e SUBSTITUI Drop por um Drop seguro so a pe (num veiculo o cao e
-- guardado automaticamente, entao nenhum drop e oferecido). Outros animais (caes selvagens, gado, companheiro de outra pessoa) mantem o
-- menu vanilla completo.
if AnimalContextMenu and AnimalContextMenu.doInventoryMenu and not AnimalContextMenu.cd_invMenuWrapped then
    local vanillaInvMenu = AnimalContextMenu.doInventoryMenu
    AnimalContextMenu.doInventoryMenu = function(player, context, animalInv, test)
        local animal = nil
        pcall(function() animal = animalInv:getAnimal() end)
        local playerObj = getSpecificPlayer(player)
        if animal and playerObj and CD.isDog(animal) and CD.isCompanion(animal) and CD.isOwnedBy(animal, playerObj) then
            local info = context:addOption(getText("ContextMenu_AnimalInfo"), animal, AnimalContextMenu.onAnimalInfo, playerObj)
            info.iconTexture = getTexture("media/ui/inventoryPanes/Button_Info.png")
            -- Drop no chao so a pe (o vinculo e restaurado ao largar por recoverCarriedDogs). Num veiculo o cao e
            -- guardado automaticamente, entao nenhum drop manual e oferecido (o drop vanilla dentro do veiculo trava / cai embaixo do carro).
            if not CD.isMounted(playerObj) then
                local drop = context:addOption(getText("ContextMenu_Drop"), { animalInv }, ISInventoryPaneContextMenu.onDropItems, player)
                drop.iconTexture = getTexture("media/ui/AnimalActions_Grab.png")
            end
            -- Mantem o Feed / Give Water vanilla em-maos (agem direto no animal carregado). Kill omitido.
            pcall(function() AnimalContextMenu.doFeedFromHandMenu(playerObj, animal, context) end)
            pcall(function() AnimalContextMenu.doWaterAnimalMenu(context, animal, playerObj) end)
            return
        end
        return vanillaInvMenu(player, context, animalInv, test)
    end
    AnimalContextMenu.cd_invMenuWrapped = true
end

-- Larga a tigela no tile/offset/rotacao escolhidos no cursor abaixo. Espelha o ISDropWorldItemAction vanilla (mesmo som),
-- mas NAO larga o item aqui: a request vai pro server, que remove do container REAL da tigela (uma bolsa/alforje, nao so o
-- inventario principal) antes de adicionar ao mundo. O drop vanilla usa ItemContainer:Remove, que nao e recursivo, e por
-- isso duplicava a tigela guardada numa mochila.
-- Mora aqui (e nao num arquivo proprio) porque .lua NOVO nao e carregado: o PZ cacheia a lista de arquivos do mod.
ISCDPlaceDish = ISBaseTimedAction:derive("ISCDPlaceDish")

function ISCDPlaceDish:isValid()
    return self.item and self.character:getInventory():containsRecursive(self.item)
end

function ISCDPlaceDish:start()
    self.item:setJobType(getText("IGUI_JobType_Dropping"))
    self.item:setJobDelta(0.0)
    self.sound = self.character:playSound("PutItemInBag")
end

function ISCDPlaceDish:update()
    self.item:setJobDelta(self:getJobDelta())
end

function ISCDPlaceDish:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopOrTriggerSound(self.sound)
    end
end

function ISCDPlaceDish:doPlace()
    if self.cdDone then return end
    self.cdDone = true
    if not self.character:getInventory():containsRecursive(self.item) then return end
    CD.request("placedish", nil, {
        x = self.x, y = self.y, z = self.z,
        itemId = self.item:getID(),
        xo = self.xoffset, yo = self.yoffset, rot = self.rotation,
    })
end

function ISCDPlaceDish:stop()
    self:stopSound()
    self.item:setJobDelta(0.0)
    ISBaseTimedAction.stop(self)
end

function ISCDPlaceDish:perform()
    self:stopSound()
    self.item:setJobDelta(0.0)
    ISInventoryPage.renderDirty = true
    ISBaseTimedAction.perform(self)
end

function ISCDPlaceDish:complete()
    self:doPlace()
    return true
end

function ISCDPlaceDish:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return 30
end

function ISCDPlaceDish:new(character, item, sq, xoffset, yoffset, rotation)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.x, o.y, o.z = sq:getX(), sq:getY(), sq:getZ()
    o.xoffset = xoffset
    o.yoffset = yoffset
    o.rotation = rotation
    o.maxTime = o:getDuration()
    o.stopOnWalk = false
    o.stopOnRun = false
    return o
end

-- Cursor de posicionamento da tigela: o mesmo cursor 3D do "Colocar item no chao" vanilla (ghost do modelo seguindo o
-- mouse, offset livre dentro do tile, R/Shift-R pra girar), mas a colocacao vai pela ISCDPlaceDish acima.
-- Construido SOB DEMANDA no primeiro clique, nunca no load: o ISPlace3DItemCursor vive em media/lua/server/, que a
-- engine carrega DEPOIS de media/lua/client/ (e nenhum arquivo vanilla o requer), entao derivar dele aqui em cima
-- estoura "attempted index: derive of non-table" ao carregar o mod.
local CDPlaceDishCursor

local function getPlaceDishCursorClass()
    if CDPlaceDishCursor then return CDPlaceDishCursor end
    if not ISPlace3DItemCursor then return nil end
    local cursor = ISPlace3DItemCursor:derive("CDPlaceDishCursor")

    -- Tigela e sempre de chao: sem alturas de superficie, senao ela pousaria num balcao que o auto-feed enxerga (varre
    -- por tile) mas o cao nao alcanca. Zerar surfacesPossible tambem apaga o prompt "trocar superficie" herdado.
    function cursor:getSurface(square)
        self.surfacesPossible = {}
        return 0
    end

    function cursor:create(x, y, z, north, sprite)
        local item = self.items[1]
        local sq = self.selectedSqDrop
        if not (item and sq) then return end
        if not luautils.walkAdjAltTest(self.chr, sq, self.itemSq, true) then return end
        if self.chr:isEquipped(item) then
            ISTimedActionQueue.add(ISUnequipAction:new(self.chr, item, 1, "place"))
        end
        ISTimedActionQueue.addGetUpAndThen(self.chr,
            ISCDPlaceDish:new(self.chr, item, sq, self.render3DItemXOffset, self.render3DItemYOffset, self:clamp(self.render3DItemRot)))
        self.keepOnSquare = false
    end

    function cursor:new(character, item)
        local o = ISPlace3DItemCursor.new(self, character, { item })
        o.placeAll = false
        return o
    end

    CDPlaceDishCursor = cursor
    return cursor
end

-- Abre o cursor 3D de posicionamento (CDPlaceDishCursor): o jogador escolhe o tile, a posicao dentro dele e a rotacao,
-- como no "Colocar item no chao" vanilla. A colocacao sai no fim da ISCDPlaceDish, e o server re-adiciona a MESMA
-- instancia do item ao mundo (mantendo seu ModData de estoque); a vasilha largada E a estacao de alimentacao que o auto-feed varre.
local function onPlaceDishClick(playerObj, item)
    if not playerObj or not item then return end
    local cursorClass = getPlaceDishCursorClass()
    if not cursorClass then return end
    local playerNum = playerObj:getPlayerNum()
    -- Espelha o onPlaceItemOnGround vanilla: recolhe inventario/loot pra eles nao cobrirem o cursor.
    for _, ui in ipairs({ getPlayerInventory(playerNum), getPlayerLoot(playerNum) }) do
        if ui and ui:isVisible() and not ui.isCollapsed and not ui.pin then
            ui.isCollapsed = true
            ui:setMaxDrawHeight(ui:titleBarHeight())
        end
    end
    getCell():setDrag(cursorClass:new(playerObj, item), playerNum)
end

-- Oferece "Place dish" na nossa tigela carregada no inventario.
local function onInventoryDishMenu(playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end
    local dish
    for _, v in ipairs(items) do
        local it = v
        if not instanceof(v, "InventoryItem") then it = v.items and v.items[1] end
        if it and it.getFullType and CD.isDishType(it:getFullType()) then dish = it; break end
    end
    if not dish then return end
    context:addOption(getText("IGUI_PD_PlaceDish"), playerObj, onPlaceDishClick, dish)
    -- Remove o "Place item on ground" vanilla (a tigela se qualifica via WorldStaticModel): seu remove de inventario nao-recursivo
    -- duplica uma tigela FluidContainer colocada a partir de uma mochila, entao a colocacao precisa passar por placedish.
    if context.removeOptionByName then context:removeOptionByName(getText("ContextMenu_PlaceItemOnGround")) end
end

-- As comidas comestiveis por cao do jogador (agrupadas por tipo), para o submenu "Add food" da tigela: qualquer comida que um cao pode comer (nao so
-- racao); as toxicas ainda aparecem mas marcadas como ruins (vermelho + bloqueadas). Veja CD.isBowlFood.
local function listDishFoods(playerObj)
    local groups, order = {}, {}
    cdForEachCarriedItem(playerObj:getInventory(), function(item)
        if CD.isBowlFood(item) then
            local key = item:getFullType()
            local g = groups[key]
            if g then g.count = g.count + 1
            else g = { item = item, count = 1, name = item:getName(), bad = CD.isBadDogFood(item) }; groups[key] = g; order[#order + 1] = g end
        end
    end)
    table.sort(order, function(a, b) return a.name < b.name end)
    return order
end

-- Anda ate a vasilha, agacha e "oferece comida" (a mesma animacao de alimentar na mao), ENTAO manda o server despejar um item de
-- comida nela (convertido em refeicoes). O server faz a remocao do item de forma autoritativa (anticheat-safe); a request
-- dispara na conclusao da acao (ISCDFillDish:doFill), entao so despeja quando o jogador esta agachado na tigela.
local function onAddDishFood(playerObj, x, y, z, item)
    if not (playerObj and item) then return end
    local sq = getCell():getGridSquare(x, y, z)
    if sq then luautils.walkAdj(playerObj, sq) end
    ISTimedActionQueue.addGetUpAndThen(playerObj, ISCDFillDish:new(playerObj, x, y, z, item, "dishaddfood", "foodId"))
end

local function onAddDishWater(playerObj, x, y, z, water)
    if not (playerObj and water) then return end
    local sq = getCell():getGridSquare(x, y, z)
    if sq then luautils.walkAdj(playerObj, sq) end
    ISTimedActionQueue.addGetUpAndThen(playerObj, ISCDFillDish:new(playerObj, x, y, z, water, "dishaddwater", "waterId"))
end

-- Esvazia o conteudo atual da tigela para que ela possa alternar entre comida e agua (uma tigela guarda um OU o outro).
local function onEmptyDish(playerObj, x, y, z)
    if not playerObj then return end
    local sq = getCell():getGridSquare(x, y, z)
    if sq then luautils.walkAdj(playerObj, sq) end
    ISTimedActionQueue.addGetUpAndThen(playerObj, ISCDFillDish:new(playerObj, x, y, z, nil, "dishempty", nil))
end

-- Clique direito na NOSSA tigela largada (um objeto de inventario do mundo): a tigela guarda comida OU agua (como o cocho
-- vanilla), entao oferece a que cabe no conteudo atual e bloqueia a outra ate ser esvaziada. O pickup e a
-- opcao "Grab" vanilla que a engine ja adiciona para qualquer item do mundo (mantem o ModData da tigela).
local function onDishWorldMenu(playerNum, context, worldobjects, test)
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end
    local dsq, dish
    for _, o in ipairs(worldobjects) do
        local sq = o.getSquare and o:getSquare()
        if sq then
            local wobs = sq:getWorldObjects()
            if wobs then
                for i = 0, wobs:size() - 1 do
                    local wo = wobs:get(i)
                    local item = wo.getItem and wo:getItem()
                    if item and CD.isDishType(item:getFullType()) then dsq = sq; dish = item; break end
                end
            end
        end
        if dsq then break end
    end
    if not dsq then return end
    -- Passe "test" do controle: registra a interacao para que as opcoes apareçam para usuarios de gamepad tambem.
    if test and ISWorldObjectContextMenu and ISWorldObjectContextMenu.setTest then return ISWorldObjectContextMenu.setTest() end
    local x, y, z = dsq:getX(), dsq:getY(), dsq:getZ()

    -- A tigela guarda comida OU agua, nunca os dois. Seu "kind" = o que estiver nela agora (vazia = aceita qualquer um). O
    -- estoque e um orcamento de restauracao 0..100 (quanto de fome/sede ela ainda pode devolver). Num server DEDICATED a
    -- copia de ModData do item de mundo fica congelada no stream-in (InventoryItem nao tem transmitModData), entao prefere o cache
    -- de broadcast do server (CD.cacheDishStock); o ModData e o fallback para SP / coop-host (VM compartilhada, ao vivo) e uma
    -- tigela que o client recebeu no stream antes de qualquer broadcast.
    local md = dish and dish:getModData() or {}
    local foodPts = md.cdFoodMeals or 0
    local waterPts = md.cdWater or 0
    local cached = CD.dishStock and CD.dishStockKey and CD.dishStock[CD.dishStockKey(x, y, z)]
    if cached then foodPts = cached.food or 0; waterPts = cached.water or 0 end
    local hasFood = foodPts > 0
    local hasWater = waterPts > 0

    -- Linha de status (nao clicavel): mostra so o que ha dentro (atual/max), ou que esta vazia.
    if hasFood then
        context:addOption(getText("IGUI_PD_BowlStatusFood", tostring(math.floor(foodPts)), tostring(CD.DISH_MAX_MEALS or 100)), nil, nil)
    elseif hasWater then
        context:addOption(getText("IGUI_PD_BowlStatusWater", tostring(math.floor(waterPts)), tostring(CD.DISH_MAX_WATER or 100)), nil, nil)
    else
        context:addOption(getText("IGUI_PD_BowlStatusEmpty"), nil, nil)
    end

    -- Adicionar comida: bloqueado enquanto a tigela guarda agua (esvazie primeiro). Comidas ruins para o cao aparecem em vermelho + desabilitadas.
    if hasWater then
        local opt = context:addOption(getText("IGUI_PD_AddBowlFood"), nil, nil)
        opt.notAvailable = true
        local tip = ISWorldObjectContextMenu.addToolTip()
        tip:setName(getText("IGUI_PD_BowlHasWater"))
        opt.toolTip = tip
    else
        local foods = listDishFoods(playerObj)
        if #foods > 0 then
            local header = context:addOption(getText("IGUI_PD_AddBowlFood"), nil, nil)
            local sub = ISContextMenu:getNew(context)
            context:addSubMenu(header, sub)
            for _, g in ipairs(foods) do
                local label = (g.count > 1) and (g.name .. " (" .. g.count .. ")") or g.name
                local opt = sub:addOption(label, playerObj, onAddDishFood, x, y, z, g.item)
                pcall(function() opt.iconTexture = g.item:getTexture() end)
                if g.bad then
                    opt.notAvailable = true
                    cdApplyBadFoodCue(sub, opt, g)
                end
            end
        else
            local opt = context:addOption(getText("IGUI_PD_AddBowlFood"), nil, nil)
            opt.notAvailable = true
            local tip = ISWorldObjectContextMenu.addToolTip()
            tip:setName(getText("IGUI_PD_BowlNeedFood"))
            opt.toolTip = tip
        end
    end

    -- Adicionar agua: bloqueado enquanto a tigela guarda comida (esvazie primeiro), senao acinzentado se nenhuma fonte de agua for carregada.
    if hasFood then
        local opt = context:addOption(getText("IGUI_PD_AddBowlWater"), nil, nil)
        opt.notAvailable = true
        local tip = ISWorldObjectContextMenu.addToolTip()
        tip:setName(getText("IGUI_PD_BowlHasFood"))
        opt.toolTip = tip
    else
        local water = findWater(playerObj)
        local wopt = context:addOption(getText("IGUI_PD_AddBowlWater"), playerObj, onAddDishWater, x, y, z, water)
        if not water then
            wopt.notAvailable = true
            local tip = ISWorldObjectContextMenu.addToolTip()
            tip:setName(getText("IGUI_PD_NeedWater"))
            wopt.toolTip = tip
        end
    end

    -- Esvazia a tigela para que ela possa alternar entre comida e agua.
    if hasFood or hasWater then
        context:addOption(getText("IGUI_PD_EmptyBowl"), playerObj, onEmptyDish, x, y, z)
    end
end

if isClient() or not isServer() then
    Events.OnClickedAnimalForContext.Add(onAnimalMenu)
    Events.OnFillWorldObjectContextMenu.Add(onWorldMenu)
    Events.OnFillInventoryObjectContextMenu.Add(onInventoryDishMenu)
    Events.OnFillWorldObjectContextMenu.Add(onDishWorldMenu)
end
