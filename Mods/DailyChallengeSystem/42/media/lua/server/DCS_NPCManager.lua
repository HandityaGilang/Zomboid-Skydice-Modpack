local dcsRandom = newrandom()

DCS_NPC = DCS_NPC or {}

local NPC_SPAWN_RADIUS = 70

local RESPAWN_COOLDOWN = 5

local NPC_ZONE_CLEAR_RADIUS = 5

local NPC_ID_LO = 30000 * 65536
local NPC_ID_HI = 30001 * 65536

local MOD_ID = "DailyChallengeSystem"
local function sendToAllClients(command, args)
    if isServer() and DCS_Env.isServerNetworkReady() then
        sendServerCommand(MOD_ID, command, args)
    end
    if DCS_Env.isHost() or DCS_Env.isSP() then
        triggerEvent("OnServerCommand", MOD_ID, command, args)
    end
end

local spawnedNPCs = {}

local respawnNotBefore = {}

local dailyTraderLocations = nil

local pendingSpawns = {}

local function buildLocLookup()
    local t = {}
    if DCS_Challenges and DCS_Challenges.Locations then
        for _, loc in ipairs(DCS_Challenges.Locations) do
            t[loc.id] = loc
        end
    end
    return t
end

local function extractLocId(chId)
    local locId = chId:match("^visit_runtime_(loc_.+)$")
    if locId then return locId end
    locId = chId:match("^quest_runtime_(loc_.+)_Base_.+$")
    return locId
end

local function despawnAll()
    DCS_dprint("[DCS_NPC] despawnAll: removing " .. #spawnedNPCs .. " NPCs, "
        .. #pendingSpawns .. " pending cancelled")
    for _, entry in ipairs(spawnedNPCs) do
        local npc = entry.npc
        if npc and not npc:isDead() then
            pcall(function() npc:removeFromWorld() end)
            npc:removeFromSquare()
        end
    end
    spawnedNPCs = {}
    pendingSpawns = {}
    respawnNotBefore = {}
end

local function cleanupOrphanedNPCs()
    local cell = getCell and getCell()
    if not cell then return 0 end
    local zombieList = cell:getZombieList()
    if not zombieList then return 0 end
    local removed = 0
    for i = zombieList:size() - 1, 0, -1 do
        local z = zombieList:get(i)
        if z and not z:isDead() then
            local md = z:getModData()
            if md and md.IsDCSNPC then
                DCS_dprint("[DCS_NPC] cleanupOrphanedNPCs: removing orphan at "
                    .. tostring(z:getX()) .. "," .. tostring(z:getY()))
                pcall(function() z:removeFromWorld() end)
                z:removeFromSquare()
                removed = removed + 1
            end
        end
    end
    return removed
end

local function hasBoilersuit(zombie)
    local iVis = zombie:getItemVisuals()
    if not iVis then return false end
    for j = 0, iVis:size() - 1 do
        local item = iVis:get(j)
        if item and item.getType and item:getType() then
            if item:getType():find("Boilersuit") then return true end
        end
    end
    return false
end

local function findEntryBody(entry)
    local cell = getCell and getCell()
    if not cell then return nil end
    local zl = cell:getZombieList()
    if not zl then return nil end
    local nearest, bestD = nil, 1.5 * 1.5
    for i = 0, zl:size() - 1 do
        local z = zl:get(i)
        if z then
            local dead = z:isDead()
            if not dead then
                local bid = z:getPersistentOutfitID()
                if bid == entry.bodyInstanceID then return z end
                if entry.uuid then
                    local md = z:getModData()
                    if md and md.DCSNPC_UUID == entry.uuid then return z end
                end
                if bid and bid >= NPC_ID_LO and bid <= NPC_ID_HI then
                    local dx, dy = z:getX() - entry.x, z:getY() - entry.y
                    local d = dx * dx + dy * dy
                    if d <= bestD then nearest, bestD = z, d end
                end
            end
        end
    end
    return nearest
end

local function cleanupAllOrphans()
    if not (DCS_Config and DCS_Config.USE_NPC) then return 0 end
    local cell = getCell and getCell()
    if not cell then
        DCS_dprint("[DCS] CULL - no cell available")
        return 0
    end
    local zombieList = cell:getZombieList()
    if not zombieList then
        DCS_dprint("[DCS] CULL - no zombieList")
        return 0
    end
    local totalZombies = zombieList:size()
    local flaggedNPC = 0
    local trackedCount = 0
    local removedCount = 0
    local relinkedCount = 0
    local trackedIDs = {}
    local uuidToEntry = {}
    local bodyIdToEntry = {}
    for _, entry in ipairs(spawnedNPCs) do
        trackedIDs[entry.bodyInstanceID] = true
        if entry.uuid then uuidToEntry[entry.uuid] = entry end
        bodyIdToEntry[entry.bodyInstanceID] = entry
    end
    DCS_dprint("[DCS] CULL - scanning " .. totalZombies .. " zombie(s) in cell, spawnedNPCs=" .. #spawnedNPCs)
    for i = zombieList:size() - 1, 0, -1 do
        local z = zombieList:get(i)
        if z and not z:isDead() then
            local zBodyID = z:getPersistentOutfitID()
            local isTracked = trackedIDs[zBodyID] or false
            local md = z:getModData()
            if md and md.IsDCSNPC then
                flaggedNPC = flaggedNPC + 1
                if isTracked then
                    trackedCount = trackedCount + 1
                else
                    local entry = md.DCSNPC_UUID and uuidToEntry[md.DCSNPC_UUID]
                    if entry then
                        if entry.bodyInstanceID ~= zBodyID then
                            DCS_dprint("[DCS] CULL - relinking NPC by UUID: old bodyID="
                                .. tostring(entry.bodyInstanceID)
                                .. " new bodyID=" .. tostring(zBodyID)
                                .. " challengeId=" .. tostring(entry.challengeId))
                            trackedIDs[entry.bodyInstanceID] = nil
                            entry.bodyInstanceID = zBodyID
                            entry.npc = z
                            trackedIDs[zBodyID] = true
                            relinkedCount = relinkedCount + 1
                        end
                        trackedCount = trackedCount + 1
                    else
                        DCS_dprint("[DCS] CULL - removing orphan NPC at "
                            .. tostring(z:getX()) .. "," .. tostring(z:getY())
                            .. " name=" .. tostring(md.DCSNPC_Name)
                            .. " type=" .. tostring(md.DCSNPC_Type)
                            .. " challengeId=" .. tostring(md.DCSNPC_ChallengeId))
                        pcall(function() z:removeFromWorld() end)
                        z:removeFromSquare()
                        removedCount = removedCount + 1
                    end
                end
            elseif not isTracked and zBodyID >= NPC_ID_LO and zBodyID <= NPC_ID_HI then
                local entry = bodyIdToEntry[zBodyID]
                if entry then
                    local md2 = z:getModData()
                    md2.IsDCSNPC = true
                    md2.DCSNPC_UUID = entry.uuid
                    trackedIDs[zBodyID] = true
                    entry.npc = z
                    trackedCount = trackedCount + 1
                    relinkedCount = relinkedCount + 1
                    DCS_dprint("[DCS] CULL - re-flagged NPC by outfitID " .. tostring(zBodyID)
                        .. " challengeId=" .. tostring(entry.challengeId))
                end
            end
        end
    end

    local cellForLoad = getCell and getCell()
    for i = #spawnedNPCs, 1, -1 do
        local entry = spawnedNPCs[i]
        local body = findEntryBody(entry)
        if body then
            entry.npc = body
            entry.missCount = 0
        else
            local sqLoaded = false
            if cellForLoad then
                local sq = cellForLoad:getGridSquare(entry.x, entry.y, entry.z or 0)
                sqLoaded = sq ~= nil
            end
            if not sqLoaded then
                entry.missCount = 0
            else
                entry.missCount = (entry.missCount or 0) + 1
                if entry.missCount >= 2 then
                    DCS_dprint("[DCS] CULL - NPC missing (recycled) after " .. entry.missCount
                        .. " checks, re-queuing: challengeId=" .. tostring(entry.challengeId))
                    pendingSpawns[#pendingSpawns + 1] = {
                        x = entry.x,
                        y = entry.y,
                        z = entry.z or 0,
                        challengeId = entry.challengeId,
                        npcName = entry.npcName or "NPC",
                        heading = entry.heading or "S",
                        locName = entry.locName or "",
                        uuid = entry.uuid,
                        isFemale = entry.isFemale,
                    }
                    table.remove(spawnedNPCs, i)
                end
            end
        end
    end

    DCS_NPC._lastRelinked = relinkedCount
    DCS_dprint("[DCS] CULL - DONE flaggedNPC=" .. flaggedNPC
        .. " tracked=" .. trackedCount
        .. " relinked=" .. relinkedCount
        .. " removed=" .. removedCount
        .. " totalZombies=" .. totalZombies)
    return removedCount
end

function DCS_NPC.cleanupOrphans()
    return cleanupAllOrphans()
end

function DCS_NPC.persistNPCData()
    local gmd = ModData.getOrCreate("DCS_NPCData")
    gmd.npcs = {}
    for _, entry in ipairs(spawnedNPCs) do
        gmd.npcs[#gmd.npcs + 1] = {
            challengeId = entry.challengeId,
            bodyInstanceID = entry.bodyInstanceID,
            uuid = entry.uuid,
            isFemale = entry.isFemale,
            heading = entry.heading,
            x = entry.x, y = entry.y, z = entry.z,
            npcName = entry.npcName,
            outfit = entry.outfit,
            traderOutfit = entry.traderOutfit,
            tint = entry.tint,
            skinTexture = entry.skinTexture,
            hairModel = entry.hairModel,
            hairColor = entry.hairColor,
            beardModel = entry.beardModel,
            beardColor = entry.beardColor,
            locName = entry.locName,
        }
    end
    gmd.day = os.date("!%Y%m%d")
    DCS_dprint("[DCS] CULL - persisted " .. #gmd.npcs .. " NPC(s) to ModData for day " .. gmd.day)
end

function DCS_NPC.loadPersistedNPCData()
    local gmd = ModData.getOrCreate("DCS_NPCData")
    if gmd and gmd.day == os.date("!%Y%m%d") and gmd.npcs and #gmd.npcs > 0 then
        DCS_dprint("[DCS] CULL - loaded " .. #gmd.npcs .. " persisted NPC(s) for day " .. gmd.day)
        return gmd.npcs
    end
    return nil
end

function DCS_NPC.clearPersistedNPCData()
    local gmd = ModData.getOrCreate("DCS_NPCData")
    gmd.npcs = {}
    gmd.day = ""
end

local function findZombieByBodyID(bodyID)
    local cell = getCell and getCell()
    if not cell then return nil end
    local zombieList = cell:getZombieList()
    if not zombieList then return nil end
    for i = 0, zombieList:size() - 1 do
        local z = zombieList:get(i)
        if z and not z:isDead() and z:getPersistentOutfitID() == bodyID then
            return z
        end
    end
    return nil
end

local _dcsSessionSalt = nil
local function assignUniqueOutfitID(npc)
    local gmd = ModData.getOrCreate("DCS_NPCData")
    if not gmd.nextOutfitCounter then
        if not _dcsSessionSalt then _dcsSessionSalt = os.time() % 50000 end
        gmd.nextOutfitCounter = _dcsSessionSalt
    end
    local n = gmd.nextOutfitCounter + 1
    if n > 60000 then n = 1 end
    gmd.nextOutfitCounter = n
    local uniqueId = 30000 * 65536 + n
    npc:setPersistentOutfitID(uniqueId, false)
    return npc:getPersistentOutfitID()
end

local function clearZoneAroundSpawn(cx, cy, npcBodyID, radius)
    radius = radius or 3
    local cell = getCell and getCell() or nil
    if not cell then return 0 end
    local zombieList = cell:getZombieList()
    if not zombieList then return 0 end
    local toRemove = {}
    for i = 0, zombieList:size() - 1 do
        local z = zombieList:get(i)
        if z then
            local dead = z:isDead()
            if not dead then
                local dx = z:getX() - cx
                local dy = z:getY() - cy
                if dx * dx + dy * dy <= radius * radius then
                    local bid = z:getPersistentOutfitID()
                    if not (bid >= NPC_ID_LO and bid <= NPC_ID_HI) then
                        toRemove[#toRemove + 1] = z
                    end
                end
            end
        end
    end
    for _, z in ipairs(toRemove) do
        pcall(function() z:removeFromWorld() end)
    end
    if #toRemove > 0 then
        DCS_dprint("[DCS] Zone clear: removed " .. #toRemove
            .. " non-NPC zombie(s) within " .. radius .. " tiles of "
            .. math.floor(cx) .. "," .. math.floor(cy))
    end
    return #toRemove
end

local function getNPCDef(npcNameOrId)
    if not DCS_Challenges or not DCS_Challenges.NPCNames then return nil end
    if not npcNameOrId or npcNameOrId == "" or npcNameOrId == "NPC" then return nil end
    for _, npc in ipairs(DCS_Challenges.NPCNames) do
        if npc.name == npcNameOrId or npc.id == npcNameOrId then
            return npc
        end
    end
    local lowerSearch = npcNameOrId:lower()
    for _, npc in ipairs(DCS_Challenges.NPCNames) do
        if npc.name and npc.name:lower():find(lowerSearch, 1, true) then
            return npc
        end
    end
    return nil
end

local function spawnNPC(x, y, z, challengeId, heading, locName, npcName)
    local tx = math.floor(x)
    local ty = math.floor(y)
    local tz = z or 0

    for _, entry in ipairs(spawnedNPCs) do
        if entry.challengeId == challengeId then
            DCS_dprint("[DCS_NPC] spawnNPC: SKIP duplicate for challengeId=" .. tostring(challengeId))
            return true
        end
    end

    do
        local cell = getCell and getCell()
        if cell then
            local zombieList = cell:getZombieList()
            if zombieList then
                for i = 0, zombieList:size() - 1 do
                    local z = zombieList:get(i)
                    if z and not z:isDead() then
                        local dx = z:getX() - tx
                        local dy = z:getY() - ty
                        if math.abs(dx) <= 1 and math.abs(dy) <= 1 then
                            local md = z:getModData()
                            if md and md.IsDCSNPC then
                                DCS_dprint("[DCS_NPC] spawnNPC: SKIP — existing IsDCSNPC zombie at "
                                    .. z:getX() .. "," .. z:getY()
                                    .. " for challengeId=" .. tostring(challengeId))
                                return true
                            end
                        end
                    end
                end
            end
        end
    end

    local cell = getCell and getCell()
    local deadZombiesFound = 0
    local liveOrphansFound = 0
    if cell then
        local zombieList = cell:getZombieList()
        if zombieList then
            for i = zombieList:size() - 1, 0, -1 do
                local z = zombieList:get(i)
                if z then
                    local dx = z:getX() - tx
                    local dy = z:getY() - ty
                    if math.abs(dx) <= 3 and math.abs(dy) <= 3 then
                        local tracked = false
                        local zBodyID = z:getPersistentOutfitID()
                        for _, entry in ipairs(spawnedNPCs) do
                            if entry.bodyInstanceID == zBodyID then tracked = true; break end
                        end
                        if not tracked then
                            if z:isDead() then
                                deadZombiesFound = deadZombiesFound + 1
                                local zombieType = "unknown"
                                local zombieClothing = ""
                                do
                                    local md = z:getModData()
                                    if md and md.IsDCSNPC then
                                        zombieType = "IsDCSNPC=true"
                                    elseif md and md.DCSNPC_Name then
                                        zombieType = "DCSNPC_Name=" .. tostring(md.DCSNPC_Name)
                                    else
                                        zombieType = "noDCSflag"
                                    end
                                end
                                do
                                    local iVis = z:getItemVisuals()
                                    if iVis and iVis:size() > 0 then
                                        local names = {}
                                        for ci = 0, iVis:size() - 1 do
                                            local item = iVis:get(ci)
                                            if item then
                                                local itemName = "?"
                                                if item.getType then itemName = item:getType() or "?" end
                                                names[#names + 1] = itemName
                                            end
                                        end
                                        zombieClothing = " clothing=[" .. table.concat(names, ",") .. "]"
                                    else
                                        zombieClothing = " clothing=none(naked)"
                                    end
                                end
                                DCS_dprint("[DCS_NPC] spawnNPC: removing dead zombie corpse at "
                                    .. z:getX() .. "," .. z:getY()
                                    .. " (spawn=" .. tx .. "," .. ty .. ")"
                                    .. " type=" .. zombieType .. zombieClothing)
                                pcall(function()
                                    z:removeFromWorld()
                                    z:removeFromSquare()
                                end)
                            else
                                local zmd = z:getModData()
                                if zmd and zmd.IsDCSNPC then
                                    liveOrphansFound = liveOrphansFound + 1
                                    DCS_dprint("[DCS_NPC] spawnNPC: removing live orphan at "
                                        .. z:getX() .. "," .. z:getY()
                                        .. " (spawn=" .. tx .. "," .. ty .. ")"
                                        .. " name=" .. tostring(zmd.DCSNPC_Name))
                                    pcall(function() z:removeFromWorld() end)
                                    z:removeFromSquare()
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if deadZombiesFound > 0 or liveOrphansFound > 0 then
        DCS_dprint("[DCS_NPC] spawnNPC cleanup SUMMARY [" .. tostring(challengeId) .. "]: "
            .. "deadRemoved=" .. deadZombiesFound
            .. " liveOrphansRemoved=" .. liveOrphansFound)
    end

    cleanupAllOrphans()

    DCS_dprint("[DCS_NPC] Spawning NPC for challenge=" .. tostring(challengeId)
        .. " at " .. tx .. "," .. ty .. "," .. tz
        .. " heading=" .. tostring(heading)
        .. " loc=" .. tostring(locName))

    local function callIfPresent(label, target, methodName, ...)
        local fn = target and target[methodName]
        if fn then
            fn(target, ...)
        else
            DCS_dprint("[DCS_NPC] " .. label .. " FAILED: " .. tostring(methodName) .. " not available")
        end
    end

    local npcDef = getNPCDef(npcName)
    local femaleChance = (npcDef and npcDef.sex == "female") and 100 or 0
    local result = addZombiesInOutfit(tx, ty, tz, 1, "Naked", femaleChance,
        false, false, false, false, true, false, 1)

    if not result then
        print("[DCS_NPC] ERROR: addZombiesInOutfit returned nil for "
            .. tostring(challengeId))
        return false
    end

    local listSize = result:size()
    DCS_dprint("[DCS_NPC] addZombiesInOutfit list size=" .. listSize
        .. " for " .. tostring(challengeId))

    if listSize == 0 then
        print("[DCS_NPC] WARNING: list empty despite proximity check for "
            .. tostring(challengeId) .. " at " .. tx .. "," .. ty)
        return false
    end

    local npc = result:get(0)
    if not npc then
        print("[DCS_NPC] WARNING: result:get(0) returned nil for "
            .. tostring(challengeId))
        return false
    end

    local npcIsFemale = npc:isFemale()

    assignUniqueOutfitID(npc)

    local md = npc:getModData()
    md.IsDCSNPC = true
    md.DCSNPC_UUID = challengeId .. "_" .. tostring(os.time()) .. "_" .. tostring(dcsRandom:random(0, 9999))
    md.DCSNPC_Type = "challenge"
    md.DCSNPC_ChallengeId = challengeId
    md.DCSNPC_LocName = locName or ""
    local npcDef = getNPCDef(npcName)
    md.DCSNPC_Name = npcDef and npcDef.name or "NPC"
    md.DCSNPC_Outfit = npcDef and npcDef.outfit or "Base.Boilersuit"
    md.DCSNPC_Sex = npcDef and npcDef.sex or "male"
    DCS_dprint("[DCS_NPC] NPC definition: npcName=" .. tostring(npcName)
        .. " npcDef=" .. tostring(npcDef ~= nil)
        .. " md.DCSNPC_Name=" .. tostring(md.DCSNPC_Name)
        .. " md.DCSNPC_Sex=" .. tostring(md.DCSNPC_Sex))

    callIfPresent("clearItemVisuals", npc:getItemVisuals(), "clear")
    callIfPresent("clearWornItems", npc:getWornItems(), "clear")

    local npcDef = getNPCDef(npcName)
    local appearance = npcDef and npcDef.appearance or nil

    do
        local vis = npc:getHumanVisual()
        if vis then
            local skinTex = appearance and appearance.skinTexture or "MaleBody01"
            vis:setSkinTextureName(skinTex)
            local hairModel = appearance and appearance.hairModel or "Short"
            vis:setHairModel(hairModel)
            if ImmutableColor then
                local hc = appearance and appearance.hairColor or { r = 0.25, g = 0.15, b = 0.08 }
                local hairColor = ImmutableColor.new(hc.r, hc.g, hc.b, 1)
                vis:setHairColor(hairColor)
                local beardModel = appearance and appearance.beardModel
                if beardModel then
                    vis:setBeardModel(beardModel)
                end
                local bc = appearance and appearance.beardColor or hc
                local beardColor = ImmutableColor.new(bc.r, bc.g, bc.b, 1)
                vis:setBeardColor(beardColor)
            end
        end
    end

    do
        local vis = npc:getHumanVisual()
        if vis then
            vis:removeBlood()
            vis:removeDirt()
            for i = 0, BloodBodyPartType.MAX:index() - 1 do
                local part = BloodBodyPartType.FromIndex(i)
                vis:setBlood(part, 0)
                vis:setDirt(part, 0)
            end
        end
    end
    do
        local iVis = npc:getItemVisuals()
        if iVis then
            for i = 0, iVis:size() - 1 do
                local item = iVis:get(i)
                if item then
                    for j = 0, BloodBodyPartType.MAX:index() - 1 do
                        local part = BloodBodyPartType.FromIndex(j)
                        item:removeHole(j)
                        item:setBlood(part, 0)
                        item:setDirt(part, 0)
                    end
                    item:setInventoryItem(nil)
                end
            end
        end
    end
    do
        local vis = npc:getHumanVisual()
        if vis and vis.getBodyVisuals then
            local bvs = vis:getBodyVisuals()
            if bvs then
                local toRemove = {}
                for i = 0, bvs:size() - 1 do
                    local bodyVisual = bvs:get(i)
                    if bodyVisual and bodyVisual.getType then
                        toRemove[#toRemove + 1] = bodyVisual:getType()
                    end
                end
                for i = 1, #toRemove do
                    vis:removeBodyVisualFromItemType(toRemove[i])
                end
            end
        end
    end
    do
        local attached = npc:getAttachedItems()
        if attached then
            for i = attached:size() - 1, 0, -1 do
                local item = attached:get(i)
                if item and item.getItem then
                    npc:removeAttachedItem(item:getItem())
                end
            end
        end
    end

    local isTrader = (npcDef and npcDef.traderOutfit and #npcDef.traderOutfit > 0)
    local outfitItem = npcDef and npcDef.outfit or "Base.Boilersuit"
    do
        local iVis = npc:getItemVisuals()
        if iVis then
            if isTrader then
                for _, itemType in ipairs(npcDef.traderOutfit) do
                    local iv = ItemVisual.new()
                    iv:setItemType(itemType)
                    iv:setClothingItemName(itemType)
                    iVis:add(iv)
                end
            else
                local iv = ItemVisual.new()
                iv:setItemType(outfitItem)
                iv:setClothingItemName(outfitItem)
                iVis:add(iv)
                if ImmutableColor and npcDef and npcDef.tint then
                    iv:setTint(ImmutableColor.new(npcDef.tint.r, npcDef.tint.g, npcDef.tint.b, 1.0))
                end
                local shoes = ItemVisual.new()
                shoes:setItemType("Base.Shoes_ArmyBoots")
                shoes:setClothingItemName("Base.Shoes_ArmyBoots")
                iVis:add(shoes)
            end
        end
    end
    do
        local iVis = npc:getItemVisuals()
        if iVis then
            local clothingNames = {}
            for ci = 0, iVis:size() - 1 do
                local item = iVis:get(ci)
                if item then
                    local itemName = "nil"
                    if item.getType then itemName = item:getType() or "nil" end
                    local itemTint = "nil"
                    local t = item:getTint()
                    if t then
                        local r, g, b = t:getRedFloat(), t:getGreenFloat(), t:getBlueFloat()
                        itemTint = string.format("r=%.2f g=%.2f b=%.2f", r, g, b)
                    end
                    clothingNames[#clothingNames + 1] = itemName .. " (tint=" .. itemTint .. ")"
                end
            end
            DCS_dprint("[DCS_NPC] CLOTHING DEBUG [" .. tostring(challengeId) .. "]: "
                .. "items=" .. iVis:size() .. " outfit=" .. tostring(outfitItem)
                .. " tint=" .. tostring(npcDef and npcDef.tint and string.format("r=%.2f g=%.2f b=%.2f", npcDef.tint.r, npcDef.tint.g, npcDef.tint.b) or "nil")
                .. " items=[" .. table.concat(clothingNames, ", ") .. "]")
        end
    end

    local dateNum = tonumber(os.date("!%Y%m%d")) or 0
    local nameHash = 0
    if npcDef and npcDef.id then
        for i = 1, #npcDef.id do
            nameHash = nameHash + string.byte(npcDef.id, i)
        end
    end
    local pose = (dateNum + nameHash) % 4
    callIfPresent("idleState", npc, "setVariable", "DCSNPCIdleState", tostring(pose))

    callIfPresent("clearAggro", npc, "clearAggroList")
    callIfPresent("clearPath", npc, "setPath2", nil)
    callIfPresent("clearTarget", npc, "setTarget", nil)
    callIfPresent("noAlert", npc, "setTurnAlertedValues", 0, 0)
    callIfPresent("noRun", npc, "setRunning", false)

    callIfPresent("varMoving", npc, "setVariable", "bMoving", false)
    callIfPresent("varIsMoving", npc, "setVariable", "isMoving", false)
    callIfPresent("varSpeed", npc, "setVariable", "Speed", 0.0)

    callIfPresent("noTeeth", npc, "setNoTeeth", true)
    callIfPresent("varNoTeeth", npc, "setVariable", "NoTeeth", true)
    callIfPresent("varNoBite", npc, "setVariable", "CanBite", false)
    callIfPresent("varNoLunge", npc, "setVariable", "CanLunge", false)
    callIfPresent("varNoLunger", npc, "setVariable", "bLunger", false)
    callIfPresent("varNoLA", npc, "setVariable", "NoLungeAttack", true)
    callIfPresent("varNoLT", npc, "setVariable", "NoLungeTarget", true)

    callIfPresent("hitReaction", npc, "setVariable", "ZombieHitReaction", "Chainsaw")

    callIfPresent("noMoan", npc, "setVariable", "DCSNoMoan", true)

    do
        local desc = npc:getDescriptor()
        if desc then desc:setVoicePrefix("NotAZombie") end
    end
    do
        local emitter = npc:getEmitter()
        if emitter then emitter:stopAll() end
    end

    callIfPresent("varDCSNPC", npc, "setVariable", "DCSNPC", true)

    callIfPresent("noCrawler", npc, "setVariable", "bBecomeCrawler", false)
    callIfPresent("noCrawler", npc, "setVariable", "bCrawling", false)
    callIfPresent("noCrawler", npc, "setVariable", "FallOnFront", false)
    callIfPresent("forceUpright", npc, "setUseless", false)
    callIfPresent("forceUpright", npc, "setWalkType", "Walk")
    callIfPresent("forceUpright", npc, "setAnimatingBackwards", false)
    callIfPresent("forceUpright", npc, "setUseless", true)

    callIfPresent("setUseless", npc, "setUseless", true)
    callIfPresent("doStats", npc, "DoZombieStats")

    callIfPresent("onlyJawStab", npc, "setOnlyJawStab", true)
    callIfPresent("ignoreStagger", npc, "setIgnoreStaggerBack", true)
    callIfPresent("hitTime", npc, "setHitTime", 0)
    callIfPresent("closeKilled", npc, "setCloseKilled", false)
    callIfPresent("knifeDeath", npc, "setKnifeDeath", false)
    callIfPresent("jawStabAttach", npc, "setJawStabAttach", false)
    callIfPresent("solid", npc, "setSolid", true)
    callIfPresent("crawler", npc, "setCrawler", false)
    callIfPresent("onFloor", npc, "setKnockedDown", false)
    callIfPresent("idleState", npc, "changeState", ZombieIdleState.instance())

    callIfPresent("setHealth", npc, "setHealth", 1000)

    do
        local vis = npc:getHumanVisual()
        if vis and vis.getBodyVisuals then
            local bvs = vis:getBodyVisuals()
            if bvs then
                local toRemove = {}
                for i = 0, bvs:size() - 1 do
                    local bodyVisual = bvs:get(i)
                    if bodyVisual and bodyVisual.getType then
                        toRemove[#toRemove + 1] = bodyVisual:getType()
                    end
                end
                for i = 1, #toRemove do
                    vis:removeBodyVisualFromItemType(toRemove[i])
                end
            end
        end
    end

    local dir = IsoDirections[heading] or IsoDirections.S
    callIfPresent("setDir", npc, "setDir", dir)
    callIfPresent("resetModel", npc, "resetModelNextFrame")

    local preId = npc:getPersistentOutfitID()
    assignUniqueOutfitID(npc)
    local bodyInstanceID = npc:getPersistentOutfitID()
    DCS_dprint("[DCS_NPC] outfitID re-stamp: pre=" .. tostring(preId)
        .. " post=" .. tostring(bodyInstanceID)
        .. " challengeId=" .. tostring(challengeId))
    local uuid = md.DCSNPC_UUID
    local _ap = npcDef and npcDef.appearance or {}
    spawnedNPCs[#spawnedNPCs + 1] = {
        npc = npc,
        challengeId = challengeId,
        bodyInstanceID = bodyInstanceID,
        uuid = uuid,
        isFemale = npcIsFemale,
        heading = heading,
        x = tx,
        y = ty,
        z = tz,
        npcName = md.DCSNPC_Name or "NPC",
        outfit = md.DCSNPC_Outfit or "Base.Boilersuit",
        traderOutfit = npcDef and npcDef.traderOutfit,
        tint = npcDef and npcDef.tint or { r = 1.0, g = 1.0, b = 1.0 },
        skinTexture = _ap.skinTexture or "MaleBody01",
        hairModel = _ap.hairModel or "Short",
        hairColor = _ap.hairColor or { r = 0.25, g = 0.15, b = 0.08 },
        beardModel = _ap.beardModel,
        beardColor = _ap.beardColor,
        locName = locName or "",
    }

    do
        local appearance = npcDef and npcDef.appearance or {}
        sendServerCommand("DailyChallengeSystem", "syncNPCVisuals", {
            bodyInstanceID = bodyInstanceID,
            challengeId = challengeId,
            npcName = md.DCSNPC_Name or "NPC",
            outfit = md.DCSNPC_Outfit or "Base.Boilersuit",
            tint = npcDef and npcDef.tint or { r = 1.0, g = 1.0, b = 1.0 },
            isFemale = npcIsFemale,
            skinTexture = appearance.skinTexture or "MaleBody01",
            hairModel = appearance.hairModel or "Short",
            hairColor = appearance.hairColor or { r = 0.25, g = 0.15, b = 0.08 },
            beardModel = appearance.beardModel,
            beardColor = appearance.beardColor,
            x = tx, y = ty, z = tz,
            locName = locName or "",
            heading = heading or "S",
        })
    end

    DCS_dprint("[DCS_NPC] NPC spawned OK for " .. tostring(challengeId)
        .. " bodyInstanceID=" .. tostring(bodyInstanceID))

    clearZoneAroundSpawn(tx, ty, bodyInstanceID, NPC_ZONE_CLEAR_RADIUS)

    do
        local iVis = npc:getItemVisuals()
        if iVis then
            local clothingNames = {}
            for ci = 0, iVis:size() - 1 do
                local item = iVis:get(ci)
                if item then
                    local itemName = "nil"
                    if item.getType then itemName = item:getType() or "nil" end
                    local itemTint = "nil"
                    local t = item:getTint()
                    if t then
                        local r, g, b = t:getRedFloat(), t:getGreenFloat(), t:getBlueFloat()
                        itemTint = string.format("r=%.2f g=%.2f b=%.2f", r, g, b)
                    end
                    clothingNames[#clothingNames + 1] = itemName .. " (tint=" .. itemTint .. ")"
                end
            end
            DCS_dprint("[DCS_NPC] NPC FINAL STATE [" .. tostring(challengeId) .. "]: "
                .. "items=" .. iVis:size()
                .. " items=[" .. table.concat(clothingNames, ", ") .. "]")
        end
    end

    DCS_NPC.persistNPCData()
    return true
end

function DCS_NPC.spawnForDay(challenges)
    local orphaned = cleanupOrphanedNPCs()
    if orphaned > 0 then
        DCS_dprint("[DCS_NPC] spawnForDay: cleaned up " .. orphaned .. " orphaned NPC(s)")
    end

    despawnAll()
    respawnNotBefore = {}

    if not challenges or #challenges == 0 then
        DCS_dprint("[DCS_NPC] spawnForDay: no challenges, nothing to queue")
        return
    end

    local locLookup = buildLocLookup()

    for _, ch in ipairs(challenges) do
        if ch._phase2 then
            DCS_dprint("[DCS_NPC] Skipping phase2 placeholder: " .. tostring(ch.id))

        elseif ch.type == "visitLocation" then
            local locId = extractLocId(ch.id)
            local loc = locId and locLookup[locId]
            local heading = (loc and loc.heading) or "S"
            local locName = ch.locName or (loc and loc.name) or ch.id
            pendingSpawns[#pendingSpawns + 1] = {
                challengeId = ch.id,
                npcName = ch.npcName or "NPC",
                heading = heading,
                locName = locName,
                x = math.floor(ch.x), y = math.floor(ch.y), z = 0,
            }

        elseif ch.type == "questDeliver" then
            local locId = extractLocId(ch.id)
            local loc = locId and locLookup[locId]
            local heading = (loc and loc.heading) or "S"
            local locName = ch.destName or (loc and loc.name) or ch.id
            pendingSpawns[#pendingSpawns + 1] = {
                challengeId = ch.id,
                npcName = ch.npcName or "NPC",
                heading = heading,
                locName = locName,
                x = math.floor(ch.destX), y = math.floor(ch.destY), z = 0,
            }
        end
    end

    DCS_dprint("[DCS_NPC] spawnForDay: " .. #pendingSpawns
        .. " NPC(s) queued for proximity-triggered spawn (radius=" .. NPC_SPAWN_RADIUS .. ")")
end

function DCS_NPC.despawnAll()
    despawnAll()
end

function DCS_NPC.getSpawnedNPCData()
    local result = {}
    for _, entry in ipairs(spawnedNPCs) do
        result[#result + 1] = {
            challengeId = entry.challengeId,
            bodyInstanceID = entry.bodyInstanceID,
            uuid = entry.uuid,
            isFemale = entry.isFemale or false,
            npcName = entry.npcName or "NPC",
            outfit = entry.outfit or "Base.Boilersuit",
            traderOutfit = entry.traderOutfit,
            tint = entry.tint or { r = 1.0, g = 1.0, b = 1.0 },
            skinTexture = entry.skinTexture or "MaleBody01",
            hairModel = entry.hairModel or "Short",
            hairColor = entry.hairColor or { r = 0.25, g = 0.15, b = 0.08 },
            beardModel = entry.beardModel,
            beardColor = entry.beardColor,
            x = entry.x,
            y = entry.y,
            z = entry.z,
        }
    end
    return result
end

function DCS_NPC.setTraderLocations(tbl)
    dailyTraderLocations = tbl
end

function DCS_NPC.getTraderLocations()
    if not dailyTraderLocations then
        local gmd = ModData.getOrCreate("DCS_NPCData")
        if gmd.traderLocations and gmd.traderDay == os.date("!%Y%m%d") then
            dailyTraderLocations = gmd.traderLocations
        end
    end
    if dailyTraderLocations and (dailyTraderLocations.east or dailyTraderLocations.west) then
        return { east = dailyTraderLocations.east, west = dailyTraderLocations.west }
    end

    local result = { east = nil, west = nil }
    for _, entry in ipairs(spawnedNPCs) do
        if entry.npc and not entry.npc:isDead() then
            local md = entry.npc:getModData()
            if md and md.DCSNPC_Type == "trader" then
                if entry.side == "east" then
                    result.east = { x = entry.x, y = entry.y, z = entry.z, name = md.DCSNPC_LocName or "East Trader" }
                elseif entry.side == "west" then
                    result.west = { x = entry.x, y = entry.y, z = entry.z, name = md.DCSNPC_LocName or "West Trader" }
                end
            end
        end
    end
    if not result.east or not result.west then
        for _, entry in ipairs(pendingSpawns) do
            if entry.isTrader then
                if entry.side == "east" and not result.east then
                    result.east = { x = entry.x, y = entry.y, z = entry.z, name = entry.locName or "East Trader" }
                elseif entry.side == "west" and not result.west then
                    result.west = { x = entry.x, y = entry.y, z = entry.z, name = entry.locName or "West Trader" }
                end
            end
        end
    end
    DCS_dprint("[DCS_NPC] getTraderLocations: east=" .. tostring(result.east and result.east.name or "nil")
        .. " west=" .. tostring(result.west and result.west.name or "nil")
        .. " spawnedNPCs=" .. #spawnedNPCs .. " pendingSpawns=" .. #pendingSpawns)
    return result
end

local spawnTrader
function DCS_NPC.checkProximityAndSpawn(players)
    if #pendingSpawns == 0 then return 0 end

    local newSpawns = 0
    local stillPending = {}

    DCS_dprint("[DCS] CULL - checkProximity: " .. #pendingSpawns .. " pending, " .. #players .. " player(s), radius=" .. NPC_SPAWN_RADIUS)
    for _, entry in ipairs(pendingSpawns) do
        local playerNear = false
        for _, player in ipairs(players) do
            local dx = player:getX() - entry.x
            local dy = player:getY() - entry.y
            local dist = math.sqrt(dx * dx + dy * dy)
            if dist < NPC_SPAWN_RADIUS then
                playerNear = true
                break
            end
        end

        if playerNear then
            local alreadySpawned = false
            for _, existing in ipairs(spawnedNPCs) do
                if existing.x == entry.x and existing.y == entry.y
                    and (existing.z or 0) == (entry.z or 0) then
                    alreadySpawned = true
                    break
                end
            end
            if alreadySpawned then
                DCS_dprint("[DCS_NPC] checkProximityAndSpawn: skipping "
                    .. tostring(entry.challengeId or entry.traderDef and entry.traderDef.id)
                    .. " — NPC already tracked at " .. entry.x .. "," .. entry.y)
            elseif respawnNotBefore[entry.challengeId] and os.time() < respawnNotBefore[entry.challengeId] then
                stillPending[#stillPending + 1] = entry
            else
                local ok
                if entry.isTrader and entry.traderDef then
                    ok = spawnTrader(entry.x, entry.y, entry.z, entry.traderDef, entry.heading, entry.side, entry.locName)
                else
                    ok = spawnNPC(entry.x, entry.y, entry.z,
                        entry.challengeId, entry.heading, entry.locName, entry.npcName)
                end
                if ok then
                    newSpawns = newSpawns + 1
                else
                    DCS_dprint("[DCS_NPC] checkProximityAndSpawn: unexpected spawn failure "
                        .. "despite player proximity for " .. tostring(entry.challengeId))
                    stillPending[#stillPending + 1] = entry
                end
            end
        else
            stillPending[#stillPending + 1] = entry
        end
    end

    pendingSpawns = stillPending
    if newSpawns > 0 then
        DCS_dprint("[DCS_NPC] checkProximityAndSpawn: " .. newSpawns
            .. " new NPC(s) placed, " .. #pendingSpawns .. " still pending")
        cleanupAllOrphans()
    end
    return newSpawns
end

    local function onZombieDead(zombie)
    if not (DCS_Config and DCS_Config.USE_NPC) then return end
    if not DCS_Env.runsServerLogic() then return end
    if not zombie then return end
    local md = zombie:getModData()
    if not md or not md.IsDCSNPC then return end
    local players = DCS_Env.players()
    if players and #players == 0 then
        DCS_dprint("[DCS_NPC] onZombieDead: ignoring NPC death with no players online (restart context)")
        return
    end
    local challengeId = md.DCSNPC_ChallengeId
    local zBodyID = zombie:getPersistentOutfitID()
    print("[DCS_NPC] WARNING: DCS NPC was killed! challengeId="
        .. tostring(challengeId) .. " loc=" .. tostring(md.DCSNPC_LocName))
    for i, entry in ipairs(spawnedNPCs) do
        if entry.bodyInstanceID == zBodyID then
            local x, y, z = entry.x, entry.y, entry.z
            local heading = entry.heading or "S"
            local locName = md.DCSNPC_LocName or ""
            local respawnNpcName = md and md.DCSNPC_Name or "NPC"
            table.remove(spawnedNPCs, i)

            respawnNotBefore[challengeId] = os.time() + RESPAWN_COOLDOWN

            local alreadyPending = false
            for _, p in ipairs(pendingSpawns) do
                if p.challengeId == challengeId then
                    alreadyPending = true
                    break
                end
            end
            if not alreadyPending then
                pendingSpawns[#pendingSpawns + 1] = {
                    challengeId = challengeId,
                    npcName = respawnNpcName,
                    heading = heading,
                    locName = locName,
                    x = math.floor(x), y = math.floor(y), z = math.floor(z),
                }
            end

            DCS_dprint("[DCS_NPC] Queued respawn for NPC: " .. tostring(challengeId))
            DCS_NPC.persistNPCData()
            break
        end
    end
end

Events.OnZombieDead.Add(onZombieDead)

Events.OnDeadBodySpawn.Add(function(body)
    if not (DCS_Config and DCS_Config.USE_NPC) then return end
    if not DCS_Env.runsServerLogic() then return end
    if not body then return end

    local isNPC = false
    local md = body:getModData()
    if md and md.IsDCSNPC then
        isNPC = true
    end

    if isNPC then
        local sq = body:getSquare()
        if sq then
            sq:removeCorpse(body, false)
        end
    end
end)

local _tickCounter = 0
local _proximityCounter = 0
local _zoneClearCounter = 0
local function onTickNPCMaintain()
    if not DCS_Env.runsServerLogic() then return end
    if not (DCS_Config and DCS_Config.USE_NPC) then return end
    _tickCounter = _tickCounter + 1
    _proximityCounter = _proximityCounter + 1
    _zoneClearCounter = _zoneClearCounter + 1

    if _zoneClearCounter >= 60 then
        _zoneClearCounter = 0
        for _, zEntry in ipairs(spawnedNPCs) do
            if zEntry.npc and zEntry.bodyInstanceID then
                clearZoneAroundSpawn(zEntry.x, zEntry.y, zEntry.bodyInstanceID, NPC_ZONE_CLEAR_RADIUS)
            end
        end
    end

    if _proximityCounter >= 300 then
        _proximityCounter = 0
        local orphaned = cleanupAllOrphans()
        if orphaned > 0 or (DCS_NPC._lastRelinked or 0) > 0 then
            if orphaned > 0 then
                DCS_dprint("[DCS] CULL - tick cleanup: removed " .. orphaned .. " orphan(s)")
            end
            if DCS_NPC.getSpawnedNPCData then
                local npcData = DCS_NPC.getSpawnedNPCData()
                sendToAllClients("syncObjects", { npcs = npcData })
            end
        end
    end

    if #pendingSpawns > 0 and _proximityCounter == 0 then
        local players = getAllPlayers and getAllPlayers() or {}
        if #players > 0 then
            local newSpawns = DCS_NPC.checkProximityAndSpawn(players)
            if newSpawns > 0 then
                DCS_dprint("[DCS_NPC] Tick proximity spawn: " .. newSpawns .. " NPC(s)")
                if DCS_NPC.getSpawnedNPCData then
                    local npcData = DCS_NPC.getSpawnedNPCData()
                    local rawTL = DCS_NPC.getTraderLocations and DCS_NPC.getTraderLocations() or {}
                    local traderLocations = {}
                    if rawTL.east then traderLocations[#traderLocations + 1] = { side = "east", x = rawTL.east.x, y = rawTL.east.y, z = rawTL.east.z, name = rawTL.east.name } end
                    if rawTL.west then traderLocations[#traderLocations + 1] = { side = "west", x = rawTL.west.x, y = rawTL.west.y, z = rawTL.west.z, name = rawTL.west.name } end
                    sendToAllClients("syncObjects", { npcs = npcData, traderLocations = traderLocations })
                end
            end
        end
    end

    if #spawnedNPCs == 0 then return end

    for _, entry in ipairs(spawnedNPCs) do
        local npc = entry.npc
        if npc then
            if not npc:isDead() then
                if npc:getHealth() < 0.9 then npc:setHealth(1.0) end
                npc:setKnockedDown(false)
                npc:setOnFloor(false)
                npc:setStaggerBack(false)
                npc:setHitReaction("")
                npc:setVariable("FallOnFront", false)
                npc:setVariable("bBecomeCrawler", false)
                npc:setVariable("bCrawling", false)
                local dx = npc:getX() - entry.x
                local dy = npc:getY() - entry.y
                if dx * dx + dy * dy > 1.0 then
                    npc:setX(entry.x); npc:setY(entry.y); npc:setZ(entry.z or 0)
                end
            end
        end
    end

    if _tickCounter < 20 then return end
    _tickCounter = 0

    for _, entry in ipairs(spawnedNPCs) do
        local npc = entry.npc
        if npc and not npc:isDead() then
            if not npc:isUseless() then npc:setUseless(true) end
            npc:setPath2(nil)
            npc:setTarget(nil)
            npc:setVariable("DCSNPC", true)
            npc:setVariable("bMoving", false)
            npc:setVariable("isMoving", false)
            local md = npc:getModData()
            local npcDef = getNPCDef(md and md.DCSNPC_Name)
            local poseVar = "0"
            if npcDef then
                local dateNum = tonumber(os.date("!%Y%m%d")) or 0
                local nameHash = 0
                if npcDef.id then
                    for i = 1, #npcDef.id do
                        nameHash = nameHash + string.byte(npcDef.id, i)
                    end
                end
                poseVar = tostring((dateNum + nameHash) % 4)
            end
            npc:setVariable("DCSNPCIdleState", poseVar)
            npc:setOnlyJawStab(true)
            npc:setCrawler(false)
            local spawnX = entry.x
            local spawnY = entry.y
            local spawnZ = entry.z or 0
            local dx = npc:getX() - spawnX
            local dy = npc:getY() - spawnY
            local dist = dx * dx + dy * dy
            if dist > 1.0 then
                npc:setX(spawnX)
                npc:setY(spawnY)
                npc:setZ(spawnZ)
            end
            local players = DCS_Env.players()
            if players and #players > 0 then
                local bestDist = 9999
                local px, py = nil, nil
                for pi, p in ipairs(players) do
                    if p and not p:isDead() then
                        local dx = npc:getX() - p:getX()
                        local dy = npc:getY() - p:getY()
                        local dist = dx * dx + dy * dy
                        if dist < bestDist then
                            bestDist = dist
                            px, py = p:getX(), p:getY()
                        end
                    end
                end
                if px and py then
                    npc:faceLocation(px, py)
                end
            end
        end
    end
end
Events.OnTick.Add(onTickNPCMaintain)

spawnTrader = function(x, y, z, traderDef, heading, side, locName)
    if not traderDef then
        DCS_dprint("[DCS_NPC] spawnTrader: no traderDef provided")
        return false
    end

    local tx = math.floor(x)
    local ty = math.floor(y)
    local tz = z or 0

    local traderChallengeId = "trader_" .. tostring(traderDef.id)
    for _, entry in ipairs(spawnedNPCs) do
        if entry.challengeId == traderChallengeId then
            DCS_dprint("[DCS_NPC] spawnTrader: SKIP duplicate for " .. traderChallengeId)
            return true
        end
    end

    do
        local cell = getCell and getCell()
        if cell then
            local zombieList = cell:getZombieList()
            if zombieList then
                for i = 0, zombieList:size() - 1 do
                    local z = zombieList:get(i)
                    if z and not z:isDead() then
                        local dx = z:getX() - tx
                        local dy = z:getY() - ty
                        if math.abs(dx) <= 1 and math.abs(dy) <= 1 then
                            local md = z:getModData()
                            if md and md.IsDCSNPC then
                                DCS_dprint("[DCS_NPC] spawnTrader: SKIP — existing IsDCSNPC zombie at "
                                    .. z:getX() .. "," .. z:getY()
                                    .. " for " .. traderChallengeId)
                                return true
                            end
                        end
                    end
                end
            end
        end
    end

    local cell = getCell and getCell()
    local deadZombiesFound = 0
    local liveOrphansFound = 0
    if cell then
        local zombieList = cell:getZombieList()
        if zombieList then
            for i = zombieList:size() - 1, 0, -1 do
                local z = zombieList:get(i)
                if z then
                    local dx = z:getX() - tx
                    local dy = z:getY() - ty
                    if math.abs(dx) <= 3 and math.abs(dy) <= 3 then
                        local tracked = false
                        local zBodyID = z:getPersistentOutfitID()
                        for _, entry in ipairs(spawnedNPCs) do
                            if entry.bodyInstanceID == zBodyID then tracked = true; break end
                        end
                        if not tracked then
                            if z:isDead() then
                                deadZombiesFound = deadZombiesFound + 1
                                local zombieType = "unknown"
                                local zombieClothing = ""
                                do
                                    local md = z:getModData()
                                    if md and md.IsDCSNPC then
                                        zombieType = "IsDCSNPC=true"
                                    elseif md and md.DCSNPC_Name then
                                        zombieType = "DCSNPC_Name=" .. tostring(md.DCSNPC_Name)
                                    else
                                        zombieType = "noDCSflag"
                                    end
                                end
                                do
                                    local iVis = z:getItemVisuals()
                                    if iVis and iVis:size() > 0 then
                                        local names = {}
                                        for ci = 0, iVis:size() - 1 do
                                            local item = iVis:get(ci)
                                            if item then
                                                local itemName = "?"
                                                if item.getType then itemName = item:getType() or "?" end
                                                names[#names + 1] = itemName
                                            end
                                        end
                                        zombieClothing = " clothing=[" .. table.concat(names, ",") .. "]"
                                    else
                                        zombieClothing = " clothing=none(naked)"
                                    end
                                end
                                DCS_dprint("[DCS_NPC] spawnTrader: removing dead zombie corpse at "
                                    .. z:getX() .. "," .. z:getY()
                                    .. " (spawn=" .. tx .. "," .. ty .. ")"
                                    .. " type=" .. zombieType .. zombieClothing)
                                pcall(function()
                                    z:removeFromWorld()
                                    z:removeFromSquare()
                                end)
                            else
                                liveOrphansFound = liveOrphansFound + 1
                                local zombieClothing = ""
                                do
                                    local iVis = z:getItemVisuals()
                                    if iVis and iVis:size() > 0 then
                                        local names = {}
                                        for ci = 0, iVis:size() - 1 do
                                            local item = iVis:get(ci)
                                            if item then
                                                local itemName = "?"
                                                if item.getType then itemName = item:getType() or "?" end
                                                names[#names + 1] = itemName
                                            end
                                        end
                                        zombieClothing = " clothing=[" .. table.concat(names, ",") .. "]"
                                    else
                                        zombieClothing = " clothing=none(naked)"
                                    end
                                end
                                DCS_dprint("[DCS_NPC] spawnTrader: removing stale zombie at "
                                    .. z:getX() .. "," .. z:getY()
                                    .. " (spawn=" .. tx .. "," .. ty .. ")"
                                    .. zombieClothing)
                                pcall(function()
                                    z:removeFromWorld()
                                    z:removeFromSquare()
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
    if deadZombiesFound > 0 or liveOrphansFound > 0 then
        DCS_dprint("[DCS_NPC] spawnTrader cleanup SUMMARY [" .. tostring(traderDef.id) .. "]: "
            .. "deadRemoved=" .. deadZombiesFound
            .. " liveOrphansRemoved=" .. liveOrphansFound)
    end

    cleanupAllOrphans()

    DCS_dprint("[DCS_NPC] Spawning trader " .. tostring(traderDef.name)
        .. " at " .. tx .. "," .. ty .. "," .. tz)

    do
        local outfitCount = 0
        if traderDef.traderOutfit then outfitCount = #traderDef.traderOutfit end
        local tintStr = "nil"
        if traderDef.tint then
            tintStr = string.format("r=%.2f g=%.2f b=%.2f", traderDef.tint.r, traderDef.tint.g, traderDef.tint.b)
        end
        local appearanceStr = "nil"
        if traderDef.appearance then
            appearanceStr = "skin=" .. tostring(traderDef.appearance.skinTexture)
                .. " hair=" .. tostring(traderDef.appearance.hairModel)
        end
        DCS_dprint("[DCS_NPC] TRADER DEF DEBUG [" .. tostring(traderDef.id) .. "]: "
            .. "name=" .. tostring(traderDef.name)
            .. " sex=" .. tostring(traderDef.sex)
            .. " outfit=" .. tostring(traderDef.outfit)
            .. " tint=" .. tintStr
            .. " traderOutfit=" .. tostring(traderDef.traderOutfit ~= nil) .. " (" .. outfitCount .. " items)"
            .. " appearance=" .. appearanceStr)
    end

    local function callIfPresent(label, target, methodName, ...)
        local fn = target and target[methodName]
        if fn then
            fn(target, ...)
        else
            DCS_dprint("[DCS_NPC] " .. label .. " FAILED: " .. tostring(methodName) .. " not available")
        end
    end

    local femaleChance = (traderDef and traderDef.sex == "female") and 100 or 0
    local result = addZombiesInOutfit(tx, ty, tz, 1, "Naked", femaleChance,
        false, false, false, false, true, false, 1)

    if not result then
        print("[DCS_NPC] ERROR: addZombiesInOutfit returned nil for trader")
        return false
    end

    local listSize = result:size()
    if listSize == 0 then
        print("[DCS_NPC] WARNING: trader list empty at " .. tx .. "," .. ty)
        return false
    end

    local npc = result:get(0)
    if not npc then return false end

    local npcIsFemale = npc:isFemale()

    assignUniqueOutfitID(npc)

    local md = npc:getModData()
    md.IsDCSNPC = true
    md.DCSNPC_UUID = "trader_" .. tostring(traderDef.id) .. "_" .. tostring(os.time())
    md.DCSNPC_Type = "trader"
    md.DCSNPC_ChallengeId = "trader_" .. tostring(traderDef.id)
    md.DCSNPC_LocName = locName or traderDef.name or "Trader"
    md.DCSNPC_Name = traderDef.name or "Trader"
    md.DCSNPC_Outfit = "trader"

    callIfPresent("clearItemVisuals", npc:getItemVisuals(), "clear")
    callIfPresent("clearWornItems", npc:getWornItems(), "clear")

    local appearance = traderDef.appearance
    do
        local vis = npc:getHumanVisual()
        if vis then
            local skinTex = appearance and appearance.skinTexture or "MaleBody01"
            vis:setSkinTextureName(skinTex)
            local hairModel = appearance and appearance.hairModel or "Short"
            vis:setHairModel(hairModel)
            if ImmutableColor then
                local hc = appearance and appearance.hairColor or { r = 0.25, g = 0.15, b = 0.08 }
                local hairColor = ImmutableColor.new(hc.r, hc.g, hc.b, 1)
                vis:setHairColor(hairColor)
                local beardModel = appearance and appearance.beardModel
                if beardModel then
                    vis:setBeardModel(beardModel)
                end
                local bc = appearance and appearance.beardColor or hc
                local beardColor = ImmutableColor.new(bc.r, bc.g, bc.b, 1)
                vis:setBeardColor(beardColor)
            end
        end
    end

    do
        local vis = npc:getHumanVisual()
        if vis then
            vis:removeBlood()
            vis:removeDirt()
            for i = 0, BloodBodyPartType.MAX:index() - 1 do
                local part = BloodBodyPartType.FromIndex(i)
                vis:setBlood(part, 0)
                vis:setDirt(part, 0)
            end
        end
    end
    do
        local iVis = npc:getItemVisuals()
        if iVis then
            for i = 0, iVis:size() - 1 do
                local item = iVis:get(i)
                if item then
                    for j = 0, BloodBodyPartType.MAX:index() - 1 do
                        local part = BloodBodyPartType.FromIndex(j)
                        item:removeHole(j)
                        item:setBlood(part, 0)
                        item:setDirt(part, 0)
                    end
                    item:setInventoryItem(nil)
                end
            end
        end
    end
    do
        local vis = npc:getHumanVisual()
        if vis and vis.getBodyVisuals then
            local bvs = vis:getBodyVisuals()
            if bvs then
                local toRemove = {}
                for i = 0, bvs:size() - 1 do
                    local bodyVisual = bvs:get(i)
                    if bodyVisual and bodyVisual.getType then
                        toRemove[#toRemove + 1] = bodyVisual:getType()
                    end
                end
                for i = 1, #toRemove do
                    vis:removeBodyVisualFromItemType(toRemove[i])
                end
            end
        end
    end
    do
        local attached = npc:getAttachedItems()
        if attached then
            for i = attached:size() - 1, 0, -1 do
                local item = attached:get(i)
                if item and item.getItem then
                    npc:removeAttachedItem(item:getItem())
                end
            end
        end
    end

    if traderDef.traderOutfit then
        do
            local iVis = npc:getItemVisuals()
            if iVis then
                for _, itemType in ipairs(traderDef.traderOutfit) do
                    local iv = ItemVisual.new()
                    iv:setItemType(itemType)
                    iv:setClothingItemName(itemType)
                    iVis:add(iv)
                end
            end
        end
        do
            local iVis = npc:getItemVisuals()
            if iVis then
                local clothingNames = {}
                for ci = 0, iVis:size() - 1 do
                    local item = iVis:get(ci)
                    if item then
                        local itemName = "nil"
                        if item.getItemType then itemName = item:getItemType() or "nil" end
                        local itemTint = "nil"
                        local t = item:getTint()
                        if t then
                            local r, g, b = t:getRedFloat(), t:getGreenFloat(), t:getBlueFloat()
                            itemTint = string.format("r=%.2f g=%.2f b=%.2f", r, g, b)
                        end
                        clothingNames[#clothingNames + 1] = itemName .. " (tint=" .. itemTint .. ")"
                    end
                end
                DCS_dprint("[DCS_NPC] TRADER CLOTHING DEBUG [" .. tostring(traderDef.id) .. "]: "
                    .. "items=" .. iVis:size() .. " expected=" .. #traderDef.traderOutfit
                    .. " traderDef=" .. tostring(traderDef.name)
                    .. " items=[" .. table.concat(clothingNames, ", ") .. "]")
            end
        end
    else
        DCS_dprint("[DCS_NPC] TRADER CLOTHING DEBUG [" .. tostring(traderDef.id) .. "]: "
            .. "WARNING traderOutfit is nil/empty! traderDef=" .. tostring(traderDef.name))
    end

    callIfPresent("clearAggro", npc, "clearAggroList")
    callIfPresent("clearPath", npc, "setPath2", nil)
    callIfPresent("clearTarget", npc, "setTarget", nil)
    callIfPresent("noAlert", npc, "setTurnAlertedValues", 0, 0)
    callIfPresent("noRun", npc, "setRunning", false)
    callIfPresent("varMoving", npc, "setVariable", "bMoving", false)
    callIfPresent("varIsMoving", npc, "setVariable", "isMoving", false)
    callIfPresent("varSpeed", npc, "setVariable", "Speed", 0.0)
    callIfPresent("noTeeth", npc, "setNoTeeth", true)
    callIfPresent("varNoTeeth", npc, "setVariable", "NoTeeth", true)
    callIfPresent("varNoBite", npc, "setVariable", "CanBite", false)
    callIfPresent("varNoLunge", npc, "setVariable", "CanLunge", false)
    callIfPresent("varNoLunger", npc, "setVariable", "bLunger", false)
    callIfPresent("varNoLA", npc, "setVariable", "NoLungeAttack", true)
    callIfPresent("varNoLT", npc, "setVariable", "NoLungeTarget", true)
    callIfPresent("hitReaction", npc, "setVariable", "ZombieHitReaction", "Chainsaw")
    callIfPresent("noMoan", npc, "setVariable", "DCSNoMoan", true)
    do
        local desc = npc:getDescriptor()
        if desc then desc:setVoicePrefix("NotAZombie") end
    end
    do
        local emitter = npc:getEmitter()
        if emitter then emitter:stopAll() end
    end
    callIfPresent("varDCSNPC", npc, "setVariable", "DCSNPC", true)
    callIfPresent("varPose", npc, "setVariable", "DCSNPCIdleState", "0")

    callIfPresent("noCrawler", npc, "setVariable", "bBecomeCrawler", false)
    callIfPresent("noCrawler", npc, "setVariable", "bCrawling", false)
    callIfPresent("noCrawler", npc, "setVariable", "FallOnFront", false)
    callIfPresent("forceUpright", npc, "setUseless", false)
    callIfPresent("forceUpright", npc, "setWalkType", "Walk")
    callIfPresent("forceUpright", npc, "setAnimatingBackwards", false)
    callIfPresent("forceUpright", npc, "setUseless", true)

    callIfPresent("setUseless", npc, "setUseless", true)
    callIfPresent("doStats", npc, "DoZombieStats")
    callIfPresent("onlyJawStab", npc, "setOnlyJawStab", true)
    callIfPresent("ignoreStagger", npc, "setIgnoreStaggerBack", true)
    callIfPresent("hitTime", npc, "setHitTime", 0)
    callIfPresent("closeKilled", npc, "setCloseKilled", false)
    callIfPresent("knifeDeath", npc, "setKnifeDeath", false)
    callIfPresent("jawStabAttach", npc, "setJawStabAttach", false)
    callIfPresent("solid", npc, "setSolid", true)
    callIfPresent("crawler", npc, "setCrawler", false)
    callIfPresent("onFloor", npc, "setKnockedDown", false)
    callIfPresent("idleState", npc, "changeState", ZombieIdleState.instance())
    callIfPresent("setHealth", npc, "setHealth", 1000)

    local dir = IsoDirections[heading] or IsoDirections.S
    callIfPresent("setDir", npc, "setDir", dir)
    callIfPresent("resetModel", npc, "resetModelNextFrame")

    local preId = npc:getPersistentOutfitID()
    assignUniqueOutfitID(npc)
    local bodyInstanceID = npc:getPersistentOutfitID()
    DCS_dprint("[DCS_NPC] trader outfitID re-stamp: pre=" .. tostring(preId)
        .. " post=" .. tostring(bodyInstanceID)
        .. " challengeId=" .. tostring(md.DCSNPC_ChallengeId))
    local uuid = md.DCSNPC_UUID
    local _ap = traderDef and traderDef.appearance or {}
    spawnedNPCs[#spawnedNPCs + 1] = {
        npc = npc,
        challengeId = md.DCSNPC_ChallengeId,
        bodyInstanceID = bodyInstanceID,
        uuid = uuid,
        isFemale = npcIsFemale,
        heading = heading,
        side = side,
        x = tx,
        y = ty,
        z = tz,
        npcName = traderDef.name or "Trader",
        outfit = "trader",
        traderOutfit = traderDef.traderOutfit,
        tint = traderDef and traderDef.tint or { r = 1.0, g = 1.0, b = 1.0 },
        skinTexture = _ap.skinTexture or "MaleBody01",
        hairModel = _ap.hairModel or "Short",
        hairColor = _ap.hairColor or { r = 0.25, g = 0.15, b = 0.08 },
        beardModel = _ap.beardModel,
        beardColor = _ap.beardColor,
        locName = traderDef.name or "Trader",
    }

    local appearance = traderDef and traderDef.appearance or nil
    sendServerCommand("DailyChallengeSystem", "syncNPCVisuals", {
        bodyInstanceID = bodyInstanceID,
        challengeId = md.DCSNPC_ChallengeId,
        npcName = traderDef.name or "Trader",
        outfit = "trader",
        traderOutfit = traderDef.traderOutfit,
        tint = traderDef and traderDef.tint or { r = 1.0, g = 1.0, b = 1.0 },
        isFemale = npcIsFemale,
        skinTexture = appearance and appearance.skinTexture or "MaleBody01",
        hairModel = appearance and appearance.hairModel or "Short",
        hairColor = appearance and appearance.hairColor or { r = 0.25, g = 0.15, b = 0.08 },
        beardModel = appearance and appearance.beardModel,
        beardColor = appearance and appearance.beardColor or { r = 0.25, g = 0.15, b = 0.08 },
        x = tx, y = ty, z = tz,
        locName = traderDef.name or "Trader",
        heading = heading or "S",
    })

    DCS_dprint("[DCS_NPC] Trader spawned OK: " .. tostring(traderDef.name)
        .. " bodyInstanceID=" .. tostring(bodyInstanceID))

    clearZoneAroundSpawn(tx, ty, bodyInstanceID, NPC_ZONE_CLEAR_RADIUS)

    do
        local iVis = npc:getItemVisuals()
        if iVis then
            local clothingNames = {}
            for ci = 0, iVis:size() - 1 do
                local item = iVis:get(ci)
                if item then
                    local itemName = "nil"
                    if item.getItemType then itemName = item:getItemType() or "nil" end
                    local itemTint = "nil"
                    local t = item:getTint()
                    if t then
                        local r, g, b = t:getRedFloat(), t:getGreenFloat(), t:getBlueFloat()
                        itemTint = string.format("r=%.2f g=%.2f b=%.2f", r, g, b)
                    end
                    clothingNames[#clothingNames + 1] = itemName .. " (tint=" .. itemTint .. ")"
                end
            end
            DCS_dprint("[DCS_NPC] TRADER FINAL STATE [" .. tostring(traderDef.id) .. "]: "
                .. "items=" .. iVis:size()
                .. " items=[" .. table.concat(clothingNames, ", ") .. "]")
        end
    end

    DCS_NPC.persistNPCData()
    return true
end

function DCS_NPC.spawnTraders(seed)
    if not DCS_Challenges or not DCS_Challenges.pickDailyTraders then
        print("[DCS_NPC] spawnTraders: pickDailyTraders not found")
        return
    end

    local eastTrader, westTrader = DCS_Challenges.pickDailyTraders(seed)
    if not eastTrader or not westTrader then
        DCS_dprint("[DCS_NPC] spawnTraders: no traders available")
        return
    end

    if not DCS_Challenges.buildTraderLocationPools then
        print("[DCS_NPC] spawnTraders: buildTraderLocationPools not found")
        return
    end

    local pools = DCS_Challenges.buildTraderLocationPools(seed)
    if not pools or not pools.east or not pools.west then
        DCS_dprint("[DCS_NPC] spawnTraders: failed to build location pools")
        return
    end

    local eastLoc = pools.east
    local westLoc = pools.west

    DCS_dprint("[DCS_NPC] spawnTraders: East=" .. tostring(eastTrader.name)
        .. " at " .. tostring(eastLoc.name) .. " (" .. tostring(eastLoc.town) .. ")"
        .. " | West=" .. tostring(westTrader.name)
        .. " at " .. tostring(westLoc.name) .. " (" .. tostring(westLoc.town) .. ")")

    dailyTraderLocations = {
        east = { x = math.floor(eastLoc.x), y = math.floor(eastLoc.y), z = math.floor(eastLoc.z or 0), name = eastLoc.name or "East Trader" },
        west = { x = math.floor(westLoc.x), y = math.floor(westLoc.y), z = math.floor(westLoc.z or 0), name = westLoc.name or "West Trader" },
    }
    local gmd = ModData.getOrCreate("DCS_NPCData")
    gmd.traderLocations = dailyTraderLocations
    gmd.traderDay = os.date("!%Y%m%d")

    pendingSpawns[#pendingSpawns + 1] = {
        challengeId = "trader_east",
        npcName = eastTrader.name,
        heading = "S",
        locName = eastLoc.name,
        x = math.floor(eastLoc.x), y = math.floor(eastLoc.y), z = math.floor(eastLoc.z or 0),
        isTrader = true,
        traderDef = eastTrader,
        side = "east",
    }
    pendingSpawns[#pendingSpawns + 1] = {
        challengeId = "trader_west",
        npcName = westTrader.name,
        heading = "S",
        locName = westLoc.name,
        x = math.floor(westLoc.x), y = math.floor(westLoc.y), z = math.floor(westLoc.z or 0),
        isTrader = true,
        traderDef = westTrader,
        side = "west",
    }

    DCS_dprint("[DCS_NPC] spawnTraders: " .. #pendingSpawns .. " trader(s) queued")
end
