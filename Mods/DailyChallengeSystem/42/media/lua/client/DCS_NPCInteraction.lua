if isServer() and not isClient() then return end

local function reportNPCChallenge(challengeId)
    local player = getSpecificPlayer(0)
    if not player then return end
    DCS_dprint("[DCS] reportNPCChallenge: sending challengeId=" .. tostring(challengeId))
    sendClientCommand(player, "DailyChallengeSystem", "reportChallengeNPC", {
        challengeId = challengeId,
        day = os.date("!%Y%m%d"),
    })
end

local function getChallengeById(id)
    if not DCS_Sync or not DCS_Sync.getTodayChallenges then return nil end
    for _, ch in ipairs(DCS_Sync.getTodayChallenges()) do
        if ch.id == id then return ch end
    end
    return nil
end

local function scanSquare(sq, npcList, processedIDs)
    if not sq then return end

    if DCS_Config and DCS_Config.USE_OBJECTS then
        local objs = sq:getObjects()
        if objs then
            for i = 0, objs:size() - 1 do
                local o = objs:get(i)
                if o then
                    local md = o:getModData()
                    if md and md.IsDCSObject and md.DCSChallengeId then
                        local uid = "obj:" .. tostring(md.DCSChallengeId)
                        if not processedIDs[uid] then
                            npcList[#npcList + 1] = o
                            processedIDs[uid] = true
                        end
                    end
                end
            end
        end
    end

    if not (DCS_Config and DCS_Config.USE_NPC) then return end

    local movingObjects = sq:getMovingObjects()
    if not movingObjects then return end
    local sz = movingObjects:size()
    if sz > 0 then
        DCS_dprint("[DCS_NPC] scanSquare " .. sq:getX() .. "," .. sq:getY() .. ": "
            .. sz .. " movingObject(s)")
    end
    for i = 0, sz - 1 do
        local obj = movingObjects:get(i)
        if obj then
            local isZombie = instanceof(obj, "IsoZombie")
            DCS_dprint("[DCS_NPC]   obj[" .. i .. "] isZombie=" .. tostring(isZombie))
            if isZombie then
                local md = obj:getModData()
                local isNPC = (md and md.IsDCSNPC == true)

                if not isNPC and DCS_Sync and DCS_Sync.resolveNPCChallengeId then
                    if DCS_Sync.resolveNPCChallengeId(obj) then
                        isNPC = true
                        DCS_dprint("[DCS_NPC]     Resolver hit: challengeId="
                            .. tostring(DCS_Sync.resolveNPCChallengeId(obj)))
                    end
                end

                DCS_dprint("[DCS_NPC]     modData.IsDCSNPC=" .. tostring(md and md.IsDCSNPC)
                    .. " isNPC=" .. tostring(isNPC))

                if isNPC then
                    local uid = tostring(obj:getPersistentOutfitID() or obj:getID())
                    if not processedIDs[uid] then
                        npcList[#npcList + 1] = obj
                        processedIDs[uid] = true
                    end
                end
            end
        end
    end
end

local function buildNPCOption(context, npc, player)
    local md = npc:getModData()
    local chId = md.DCSChallengeId or md.DCSNPC_ChallengeId
    local npcName = md.DCSObjectName or md.DCSNPC_Name
    if npcName and string.sub(npcName, 1, 4) == "the " then
        npcName = string.sub(npcName, 5)
    end
    if chId and (not npcName or npcName == "NPC") then
        local ch = getChallengeById(chId)
        if ch and ch.npcName then npcName = ch.npcName end
        if not npcName then
            for _, npcDef in ipairs(DCS_Challenges.NPCNames or {}) do
                if ("trader_" .. tostring(npcDef.id)) == chId then npcName = npcDef.name; break end
            end
        end
        npcName = npcName or "NPC"
    end

    DCS_dprint("[DCS_NPC] buildNPCOption: modData chId=" .. tostring(chId) .. " npcName=" .. tostring(npcName))

    if (not chId or not npcName or npcName == "NPC") and DCS_Sync and DCS_Sync.resolveNPCChallengeId then
        chId = chId or DCS_Sync.resolveNPCChallengeId(npc)
        DCS_dprint("[DCS_NPC] buildNPCOption: resolver chId=" .. tostring(chId))
        if chId and not npcName then
            local ch = getChallengeById(chId)
            if ch and ch.npcName then
                npcName = ch.npcName
            end
            if not npcName then
                for _, npcDef in ipairs(DCS_Challenges.NPCNames or {}) do
                    local traderId = "trader_" .. tostring(npcDef.id)
                    if traderId == chId then
                        npcName = npcDef.name
                        break
                    end
                end
            end
        end
    end

    local dx, dy = math.abs(player:getX() - npc:getX()), math.abs(player:getY() - npc:getY())
    local withinRange = dx <= 3 and dy <= 3

    if chId and string.sub(chId, 1, 7) == "trader_" then
        if not withinRange then return end
        local traderName = npcName or "Token Vendor"
        local side = (chId == "trader_west") and "west" or "east"
        DCS_dprint("[DCS_NPC] buildNPCOption: TRADER detected! name=" .. traderName .. " side=" .. side)
        local txt = DCS_Config.getText()
        local opt = context:addOption(getText(txt.CONTEXT_OPEN_SHOP, traderName), npc, function()
            DCS_UI_Shop.open(side, npc)
            if DCS_ObjectOverlay and DCS_ObjectOverlay.markTraderVisited then
                DCS_ObjectOverlay.markTraderVisited(chId)
            end
        end)
        local icon = getTexture("media/textures/dcs_vendor_icon.png")
        if icon then opt.iconTexture = icon end
        return
    end

    if not chId then
        DCS_dprint("[DCS_NPC] buildNPCOption: no DCSNPC_ChallengeId (modData) or registry entry for NPC id=" .. tostring(npc:getID()))
        return
    end

    local ch = getChallengeById(chId)
    if not ch then return end

    if DCS_Sync and DCS_Sync.isCompleted and DCS_Sync.isCompleted(chId) then
        local txt = DCS_Config.getText()
        local opt = context:addOption(getText(txt.CONTEXT_CHALLENGE_DONE, npcName), npc, nil)
        opt.notAvailable = true
        return
    end

    if not withinRange then return end

    if ch.type == "visitLocation" then
        local txt = DCS_Config.getText()
        local opt = context:addOption(getText(txt.CONTEXT_VISIT_COMPLETE, npcName), npc, function()
            reportNPCChallenge(chId)
        end)
        local icon = getTexture("media/textures/dcs_gnome_icon.png")
        if icon then opt.iconTexture = icon end

    elseif ch.type == "questDeliver" then
        local inv = player:getInventory()
        local have = 0
        for _, variantId in ipairs(ch.itemVariants or { ch.itemId }) do
            have = have + inv:getCountTypeRecurse(variantId)
        end
        local need = ch.count or 1

        local txt = DCS_Config.getText()
        if have >= need then
            local opt = context:addOption(getText(txt.CONTEXT_QUEST_COMPLETE, npcName), npc, function()
                reportNPCChallenge(chId)
            end)
            local icon = getTexture("media/textures/dcs_safe_icon.png")
            if icon then opt.iconTexture = icon end
        else
            local itemName = ch.itemName or ch.itemId
            if DCS_Translate and DCS_Translate.addCountX then
                itemName = DCS_Translate.addCountX(itemName)
            end
            local opt = context:addOption(
                getText(txt.CONTEXT_QUEST_NEED, npcName, itemName),
                npc, nil
            )
            opt.notAvailable = true
            local icon = getTexture("media/textures/dcs_safe_icon.png")
            if icon then opt.iconTexture = icon end
        end
    end
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    if test then return end

    local player = getSpecificPlayer(playerNum)
    if not player then return end

    local woCount = 0
    local hasZombie = false
    for _, obj in ipairs(worldObjects) do
        woCount = woCount + 1
        if obj and instanceof(obj, "IsoZombie") then hasZombie = true end
    end
    DCS_dprint("[DCS_NPC] OnFillWorldObjectContextMenu: playerNum=" .. tostring(playerNum)
        .. " worldObjects=" .. woCount .. " hasZombie=" .. tostring(hasZombie))

    local square = nil
    for _, obj in ipairs(worldObjects) do
        if obj and obj.getSquare and obj:getSquare() then
            square = obj:getSquare()
            break
        end
    end
    if not square then
        DCS_dprint("[DCS_NPC] No square found in worldObjects — aborting")
        return
    end

    DCS_dprint("[DCS_NPC] Clicked square: " .. square:getX() .. "," .. square:getY() .. "," .. square:getZ())

    local npcList = {}
    local processedIDs = {}

    local sx = square:getX()
    local sy = square:getY()
    local sz = square:getZ()
    for dx = -1, 1 do
        for dy = -1, 1 do
            local cell = getCell()
            if cell then
                local nb = cell:getGridSquare(sx + dx, sy + dy, sz)
                if nb then
                    scanSquare(nb, npcList, processedIDs)
                end
            end
        end
    end

    DCS_dprint("[DCS_NPC] scan complete: " .. #npcList .. " DCS NPC(s) found")

    for _, npc in ipairs(npcList) do
        buildNPCOption(context, npc, player)
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
