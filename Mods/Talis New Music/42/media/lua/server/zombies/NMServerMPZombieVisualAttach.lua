NMServerMPZombieVisualAttach = NMServerMPZombieVisualAttach or {}

local MOD_DATA_KEY = "nmZombieWalkmanProof"
local PROOF_FULL_TYPE = "NewMusic.WalkmanBlue"
local ATTACHMENT_LOCATION_ID = "Walkie Belt Left"
local MODEL_ATTACHMENT_NAME = "walkie_belt_left"
local PROOF_LOCATION = ATTACHMENT_LOCATION_ID
local PROOF_MODEL_LOCATION = MODEL_ATTACHMENT_NAME
local STRATEGY_NAME = "mp_runtime_attach_with_support"
local HEARTBEAT_TICKS = 900
local SCAN_INTERVAL_TICKS = 120
local SCAN_RADIUS_SQ = 50 * 50
local SCAN_ZOMBIE_LIMIT = 32
local SCAN_PLAYER_LIMIT = 4
local FAILED_RETRY_TICKS = 600
local SAMPLE_LIMIT = 3
local SAMPLE_RECHECK_DELAY_TICKS = 120

NMServerMPZombieVisualAttach._diag = NMServerMPZombieVisualAttach._diag or {
    ticks = 0,
    attachAttempts = 0,
    attachSuccess = 0,
    attachFailure = 0,
    supportApplied = 0,
    scanCalls = 0,
    scanCandidates = 0,
    scanNearby = 0,
    strategyAssignments = 0,
    attachedListVisible = 0,
    attachedListMissing = 0,
    inventoryStillHasProof = 0,
    supportStillWorn = 0,
    sampleBudget = 0,
    pendingSamples = {},
    listCursor = 0,
    lastReportedAttachSuccess = 0,
    lastReportedAttachFailure = 0,
    lastReportedSupportApplied = 0,
    lastReportedStrategyAssignments = 0
}

local function canRunAuthoritativeMutation()
    if NMCore and NMCore.isMPClientRuntime and NMCore.isMPClientRuntime() == true then
        return false
    end
    if NMAuthorityContract and NMAuthorityContract.canMutateDurableStateAtRuntime then
        return NMAuthorityContract.canMutateDurableStateAtRuntime() == true
    end
    return true
end

local function shouldRun()
    return canRunAuthoritativeMutation()
        and NMZombieLiveStrategy
        and NMZombieLiveStrategy.shouldRunMPRuntimeAttachWithSupport
        and NMZombieLiveStrategy.shouldRunMPRuntimeAttachWithSupport() == true
end

local function shouldLogProofVerbose()
    return NMCore and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("zombieDiagnostics") == true
end

local function logProof(tag, detail, force)
    if not force and not shouldLogProofVerbose() then
        return
    end
    print("[NewMusic] [ZombieProof] " .. tostring(tag or "") .. " " .. tostring(detail or ""))
end

local function isIsoZombie(obj)
    return obj and instanceof and instanceof(obj, "IsoZombie")
end

local function isAliveZombie(zombie)
    if not isIsoZombie(zombie) then
        return false
    end
    if zombie.isDead and zombie:isDead() then
        return false
    end
    if zombie.isOnDeathDone and zombie:isOnDeathDone() then
        return false
    end
    return true
end

local function zombieDebugId(zombie)
    return tostring(zombie and zombie.getOnlineID and zombie:getOnlineID() or zombie and zombie.getObjectID and zombie:getObjectID() or "unknown")
end

local function zombieSquareSummary(zombie)
    local square = zombie and zombie.getCurrentSquare and zombie:getCurrentSquare() or nil
    if not square then
        return "square=nil"
    end
    return string.format("square=%s:%s:%s", tostring(square:getX()), tostring(square:getY()), tostring(square:getZ()))
end

local function getModData(holder)
    local root = holder and holder.getModData and holder:getModData() or nil
    if not root then
        return nil
    end
    root[MOD_DATA_KEY] = root[MOD_DATA_KEY] or {}
    return root[MOD_DATA_KEY]
end

local function transmitIfPossible(holder)
    if holder and holder.transmitModData then
        pcall(holder.transmitModData, holder)
    end
end

local function syncDescriptorHumanVisual(character)
    local humanVisual = character and character.getHumanVisual and character:getHumanVisual() or nil
    local descriptor = character and character.getDescriptor and character:getDescriptor() or nil
    local descriptorVisual = descriptor and descriptor.getHumanVisual and descriptor:getHumanVisual() or nil
    if not (humanVisual and descriptorVisual and descriptorVisual.copyFrom) then
        return false
    end
    local ok = pcall(descriptorVisual.copyFrom, descriptorVisual, humanVisual)
    return ok == true
end

local function pushZombieVisualReplication(zombie, wornLocation, wornItem)
    if wornItem and wornItem.synchWithVisual then
        pcall(wornItem.synchWithVisual, wornItem)
    end
    if zombie and zombie.resetEquippedHandsModels then
        pcall(zombie.resetEquippedHandsModels, zombie)
    end
    if zombie and zombie.resetModelNextFrame then
        pcall(zombie.resetModelNextFrame, zombie)
    end
    if zombie and zombie.resetModel then
        pcall(zombie.resetModel, zombie)
    end
    if zombie and zombie.doInventorySync then
        pcall(zombie.doInventorySync, zombie)
    end
end

local function collectCandidatePlayers()
    local out = {}
    local seen = {}
    local onlinePlayers = getOnlinePlayers and getOnlinePlayers() or nil
    if onlinePlayers and onlinePlayers.size then
        for i = 0, onlinePlayers:size() - 1 do
            local player = onlinePlayers:get(i)
            if player then
                out[#out + 1] = player
                seen[player] = true
                if #out >= SCAN_PLAYER_LIMIT then
                    return out
                end
            end
        end
    end
    for i = 0, SCAN_PLAYER_LIMIT - 1 do
        local player = getSpecificPlayer and getSpecificPlayer(i) or nil
        if player and not seen[player] then
            out[#out + 1] = player
            seen[player] = true
            if #out >= SCAN_PLAYER_LIMIT then
                return out
            end
        end
    end
    return out
end

local function isZombieNearAnyPlayer(zombie, players)
    if not (zombie and zombie.getX and zombie.getY) then
        return false
    end
    local zx = tonumber(zombie:getX()) or 0
    local zy = tonumber(zombie:getY()) or 0
    local zz = tonumber(zombie.getZ and zombie:getZ() or 0) or 0
    for i = 1, #players do
        local player = players[i]
        local square = player and player.getSquare and player:getSquare() or nil
        if square then
            local pz = tonumber(square:getZ()) or 0
            if math.abs(zz - pz) <= 2 then
                local dx = (tonumber(square:getX()) or 0) + 0.5 - zx
                local dy = (tonumber(square:getY()) or 0) + 0.5 - zy
                if ((dx * dx) + (dy * dy)) <= SCAN_RADIUS_SQ then
                    return true
                end
            end
        end
    end
    return false
end

local function countZombiesWithModulo(zombies, startIndex, count, visitor)
    if not (zombies and zombies.size and visitor) then
        return 0
    end
    local total = zombies:size()
    if total <= 0 then
        return 0
    end
    local processed = 0
    for offset = 0, math.min(count, total) - 1 do
        local index = (startIndex + offset) % total
        visitor(zombies:get(index), index)
        processed = processed + 1
    end
    return processed
end

local function getWornInventoryItem(entry)
    return entry and entry.getItem and entry:getItem() or entry and entry.getInventoryItem and entry:getInventoryItem() or entry
end

local function verifyWornItem(character, fullType)
    local wanted = tostring(fullType or "")
    if wanted == "" then
        return nil
    end
    local wornItems = character and character.getWornItems and character:getWornItems() or nil
    if not wornItems then
        return nil
    end
    local size = wornItems.size and tonumber(wornItems:size()) or wornItems.getSize and tonumber(wornItems:getSize()) or -1
    if size <= 0 then
        return nil
    end
    for i = 0, size - 1 do
        local entry = wornItems.get and wornItems:get(i) or wornItems.getItemByIndex and wornItems:getItemByIndex(i) or nil
        local item = getWornInventoryItem(entry)
        local itemFullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        if itemFullType == wanted then
            return item
        end
    end
    return nil
end

local function addInventoryItem(inventory, fullType)
    if not (inventory and inventory.AddItem) then
        return nil
    end
    local item = NMWorldItemVisuals and NMWorldItemVisuals.addItemWithVisual and select(1, NMWorldItemVisuals.addItemWithVisual(inventory, fullType)) or inventory:AddItem(fullType)
    return item
end

local function findAttachedProofItem(zombie)
    local attached = zombie and zombie.getAttachedItems and zombie:getAttachedItems() or nil
    if attached and attached.size then
        for i = 0, attached:size() - 1 do
            local entry = attached:get(i)
            local location = entry and entry.getLocation and tostring(entry:getLocation() or "") or ""
            local item = entry and entry.getItem and entry:getItem() or nil
            local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
            if location == ATTACHMENT_LOCATION_ID and fullType == PROOF_FULL_TYPE then
                return item
            end
        end
    end
    return nil
end

local function inventoryHasProofUuid(zombie, wantedUuid)
    local inventory = zombie and zombie.getInventory and zombie:getInventory() or nil
    local items = inventory and inventory.getItems and inventory:getItems() or nil
    if not (items and items.size) then
        return false, nil
    end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        if fullType == PROOF_FULL_TYPE then
            local state = item and NMDeviceState and NMDeviceState.peek and NMDeviceState.peek(item) or nil
            local uuid = tostring(state and state.deviceUUID or "")
            if wantedUuid == "" or uuid == wantedUuid then
                return true, item
            end
        end
    end
    return false, nil
end

local function findInventoryProofItem(zombie)
    local wantedUuid = tostring(getModData(zombie) and getModData(zombie).deviceUUID or "")
    local ok, item = inventoryHasProofUuid(zombie, wantedUuid)
    if ok then
        return item
    end
    return nil
end

local function zombieSupportsProofLocation(zombie)
    local attachedItems = zombie and zombie.getAttachedItems and zombie:getAttachedItems() or nil
    local group = attachedItems and attachedItems.getGroup and attachedItems:getGroup() or nil
    if not (group and group.size and group.getLocationByIndex) then
        return false
    end
    for i = 0, group:size() - 1 do
        local entry = group:getLocationByIndex(i)
        local locationId = entry and entry.getId and tostring(entry:getId() or "") or ""
        if locationId == ATTACHMENT_LOCATION_ID then
            return true
        end
    end
    return false
end

local function describeAttachedProofItem(zombie)
    local attached = zombie and zombie.getAttachedItems and zombie:getAttachedItems() or nil
    if not (attached and attached.size) then
        return "attachedItem=nil"
    end
    for i = 0, attached:size() - 1 do
        local entry = attached:get(i)
        local location = entry and entry.getLocation and tostring(entry:getLocation() or "") or ""
        local item = entry and entry.getItem and entry:getItem() or nil
        local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        if location == ATTACHMENT_LOCATION_ID and fullType == PROOF_FULL_TYPE then
            local modelName = item and item.getAttachedToModel and tostring(item:getAttachedToModel() or "") or ""
            return string.format(
                "attachedItem=present location=%s fullType=%s model=%s",
                tostring(location),
                tostring(fullType),
                tostring(modelName)
            )
        end
    end
    return "attachedItem=missing"
end

local function applyAttachedAuthority(zombie, item, state)
    local authority = NMAuthorityV4 or NMAuthorityV3
    if not (authority and authority.applyIntent and state) then
        return
    end
    local square = zombie and zombie.getCurrentSquare and zombie:getCurrentSquare() or nil
    authority.applyIntent(state, "request_attached", {
        sourceX = square and (square:getX() + 0.5) or zombie and zombie.getX and zombie:getX() or 0,
        sourceY = square and (square:getY() + 0.5) or zombie and zombie.getY and zombie:getY() or 0,
        sourceZ = square and square:getZ() or zombie and zombie.getZ and zombie:getZ() or 0,
        sourceOwner = tostring(zombie and zombie.getOnlineID and zombie:getOnlineID() or zombie and zombie.getObjectID and zombie:getObjectID() or ""),
        sourceMode = "attached"
    })
end

local function initializeProofState(zombie, item)
    local profile = NMDeviceProfiles and NMDeviceProfiles.getForItem and NMDeviceProfiles.getForItem(item) or nil
    local state = profile and NMDeviceState and NMDeviceState.ensureInitialized and NMDeviceState.ensureInitialized(item, profile, "explicit_init") or nil
    if not (profile and state) then
        return nil, "device_state_init_failed"
    end
    state.mediaFullType = nil
    state.mediaEjectFullType = nil
    state.mediaRecordedMediaIndex = nil
    state.mediaDisplayName = nil
    state.isOn = false
    state.desiredIsOn = false
    state.isPlaying = false
    state.desiredIsPlaying = false
    state.lastStopReason = "zombie_walkman_proof"
    if profile.supportsBattery == true then
        state.batteryPresent = true
        state.batteryCharge = 1.0
    end
    if NMDeviceState and NMDeviceState.setZombieDormant then
        NMDeviceState.setZombieDormant(state, true, "zombie_walkman_proof", STRATEGY_NAME)
    end
    applyAttachedAuthority(zombie, item, state)
    if NMDeviceState and NMDeviceState.bumpRevision then
        NMDeviceState.bumpRevision(state)
    end
    return state, nil
end

local function attachProofItem(zombie, item)
    if item and item.setAttachedToModel then
        pcall(item.setAttachedToModel, item, MODEL_ATTACHMENT_NAME)
    end
    if not (zombie and zombie.setAttachedItem) then
        return false, "missing_setAttachedItem"
    end
    local ok, err = pcall(zombie.setAttachedItem, zombie, ATTACHMENT_LOCATION_ID, item)
    if not ok then
        return false, tostring(err or "setAttachedItem_failed")
    end
    pushZombieVisualReplication(zombie, nil, nil)
    return true, nil
end

local function markZombieState(zombie, status, item, reason)
    local md = getModData(zombie)
    if not md then
        return
    end
    local state = item and NMDeviceState and NMDeviceState.peek and NMDeviceState.peek(item) or nil
    md.status = tostring(status or "")
    md.fullType = item and item.getFullType and tostring(item:getFullType() or "") or PROOF_FULL_TYPE
    md.attachmentLocation = ATTACHMENT_LOCATION_ID
    md.deviceUUID = tostring(state and state.deviceUUID or "")
    md.reason = reason ~= nil and tostring(reason) or nil
    md.strategy = STRATEGY_NAME
    md.liveVisualStrategy = STRATEGY_NAME
    md.lastAttemptTick = tonumber(NMServerMPZombieVisualAttach._diag and NMServerMPZombieVisualAttach._diag.ticks or 0) or 0
    transmitIfPossible(zombie)
end

local function shouldAttemptAttach(zombie)
    local md = getModData(zombie)
    local status = tostring(md and md.status or "")
    if status == "attached" and tostring(md and md.strategy or "") == STRATEGY_NAME and findAttachedProofItem(zombie) then
        return false
    end
    if status ~= "failed" then
        return true
    end
    local currentTick = tonumber(NMServerMPZombieVisualAttach._diag and NMServerMPZombieVisualAttach._diag.ticks or 0) or 0
    local lastAttemptTick = tonumber(md and md.lastAttemptTick or 0) or 0
    return (currentTick - lastAttemptTick) >= FAILED_RETRY_TICKS
end

local function recordTruthObservation(zombie, uuid, phase)
    local diag = NMServerMPZombieVisualAttach._diag
    local attachedVisible = findAttachedProofItem(zombie) ~= nil
    local inventoryVisible = inventoryHasProofUuid(zombie, uuid)
    if attachedVisible then
        diag.attachedListVisible = (diag.attachedListVisible or 0) + 1
    else
        diag.attachedListMissing = (diag.attachedListMissing or 0) + 1
    end
    if inventoryVisible then
        diag.inventoryStillHasProof = (diag.inventoryStillHasProof or 0) + 1
    end
end

local function sampleAttachmentLifecycle(zombie, uuid)
    local diag = NMServerMPZombieVisualAttach._diag
    if (diag.sampleBudget or 0) <= 0 then
        return
    end
    diag.sampleBudget = (diag.sampleBudget or 0) - 1
    recordTruthObservation(zombie, uuid, "attach_postcheck")
    diag.pendingSamples = diag.pendingSamples or {}
    diag.pendingSamples[#diag.pendingSamples + 1] = {
        zombie = zombie,
        uuid = tostring(uuid or ""),
        recheckTick = (diag.ticks or 0) + SAMPLE_RECHECK_DELAY_TICKS
    }
end

local function processPendingSamples()
    local diag = NMServerMPZombieVisualAttach._diag
    local pending = diag.pendingSamples or {}
    local keep = {}
    for i = 1, #pending do
        local entry = pending[i]
        if entry and entry.zombie and isAliveZombie(entry.zombie) then
            if (diag.ticks or 0) >= (tonumber(entry.recheckTick) or 0) then
                recordTruthObservation(entry.zombie, entry.uuid, "attach_recheck")
            else
                keep[#keep + 1] = entry
            end
        end
    end
    diag.pendingSamples = keep
end

local function ensureZombieHasProofWalkman(zombie)
    NMServerMPZombieVisualAttach._diag.attachAttempts = (NMServerMPZombieVisualAttach._diag.attachAttempts or 0) + 1
    if not zombieSupportsProofLocation(zombie) then
        NMServerMPZombieVisualAttach._diag.attachFailure = (NMServerMPZombieVisualAttach._diag.attachFailure or 0) + 1
        markZombieState(zombie, "failed", nil, "missing_proof_location")
        logProof("mp_visual_attach_failed", "reason=missing_proof_location strategy=" .. STRATEGY_NAME, true)
        return false
    end
    local attachedItem = findAttachedProofItem(zombie)
    if attachedItem then
        markZombieState(zombie, "attached", attachedItem, nil)
        return true
    end
    local inventory = zombie and zombie.getInventory and zombie:getInventory() or nil
    if not inventory then
        NMServerMPZombieVisualAttach._diag.attachFailure = (NMServerMPZombieVisualAttach._diag.attachFailure or 0) + 1
        markZombieState(zombie, "failed", nil, "missing_inventory")
        return false
    end
    local item = findInventoryProofItem(zombie)
    if not item then
        item = addInventoryItem(inventory, PROOF_FULL_TYPE)
        if not item then
            NMServerMPZombieVisualAttach._diag.attachFailure = (NMServerMPZombieVisualAttach._diag.attachFailure or 0) + 1
            markZombieState(zombie, "failed", nil, "item_add_failed")
            return false
        end
    end
    local state, stateReason = initializeProofState(zombie, item)
    if stateReason then
        NMServerMPZombieVisualAttach._diag.attachFailure = (NMServerMPZombieVisualAttach._diag.attachFailure or 0) + 1
        markZombieState(zombie, "failed", item, stateReason)
        return false
    end
    local ok, attachReason = attachProofItem(zombie, item)
    if not ok then
        NMServerMPZombieVisualAttach._diag.attachFailure = (NMServerMPZombieVisualAttach._diag.attachFailure or 0) + 1
        markZombieState(zombie, "failed", item, attachReason)
        logProof("mp_visual_attach_failed", "reason=" .. tostring(attachReason) .. " strategy=" .. STRATEGY_NAME, true)
        return false
    end
    NMServerMPZombieVisualAttach._diag.attachSuccess = (NMServerMPZombieVisualAttach._diag.attachSuccess or 0) + 1
    NMServerMPZombieVisualAttach._diag.strategyAssignments = (NMServerMPZombieVisualAttach._diag.strategyAssignments or 0) + 1
    markZombieState(zombie, "attached", item, nil)
    sampleAttachmentLifecycle(zombie, tostring(state and state.deviceUUID or ""))
    return true
end

function NMServerMPZombieVisualAttach.onTick()
    if not shouldRun() then
        return
    end
    local diag = NMServerMPZombieVisualAttach._diag
    diag.ticks = (tonumber(diag.ticks) or 0) + 1
    processPendingSamples()
    if (diag.ticks % SCAN_INTERVAL_TICKS) == 0 then
        diag.sampleBudget = SAMPLE_LIMIT
        local players = collectCandidatePlayers()
        local cell = getCell and getCell() or nil
        local zombies = cell and cell.getZombieList and cell:getZombieList() or nil
        diag.scanCalls = (diag.scanCalls or 0) + 1
        if zombies and zombies.size and #players > 0 then
            local processed = 0
            local nearby = 0
            local candidates = 0
            local total = zombies:size()
            local startIndex = tonumber(diag.listCursor or 0) or 0
            countZombiesWithModulo(zombies, startIndex, total, function(zombie)
                if isAliveZombie(zombie) then
                    candidates = candidates + 1
                    if isZombieNearAnyPlayer(zombie, players) then
                        nearby = nearby + 1
                        if processed < SCAN_ZOMBIE_LIMIT and shouldAttemptAttach(zombie) then
                            processed = processed + 1
                            ensureZombieHasProofWalkman(zombie)
                        end
                    end
                end
            end)
            diag.listCursor = total > 0 and ((startIndex + SCAN_ZOMBIE_LIMIT) % total) or 0
            diag.scanCandidates = (diag.scanCandidates or 0) + candidates
            diag.scanNearby = (diag.scanNearby or 0) + nearby
            diag.lastReportedAttachSuccess = diag.attachSuccess or 0
            diag.lastReportedAttachFailure = diag.attachFailure or 0
            diag.lastReportedSupportApplied = diag.supportApplied or 0
            diag.lastReportedStrategyAssignments = diag.strategyAssignments or 0
        end
    end
    if (diag.ticks % HEARTBEAT_TICKS) ~= 0 then
        return
    end
end

return NMServerMPZombieVisualAttach
