NMServerSPZombieAssignmentFlow = NMServerSPZombieAssignmentFlow or NMServerZombieWalkmanAttach or {}
NMServerZombieWalkmanAttach = NMServerSPZombieAssignmentFlow
require "zombies/NMZombieAudioVisualSupport"
require "zombies/NMZombieDeviceVariantCatalog"
require "zombies/NMZombieMediaPayloadResolver"
require "zombies/NMZombieMediaPayloadRuntime"

local STRATEGY_NAME = "sp_runtime_attach"
local HEARTBEAT_TICKS = 900
local SCAN_INTERVAL_TICKS = 120
local SCAN_RADIUS_SQ = 50 * 50
local SCAN_ZOMBIE_LIMIT = 32
local SCAN_PLAYER_LIMIT = 4
local FAILED_RETRY_TICKS = 600
local LOADED_SWEEP_LIMIT = 12
local KNOWN_SPECS = NMZombieDeviceVariantCatalog and NMZombieDeviceVariantCatalog.getAllRealizationSpecs and NMZombieDeviceVariantCatalog.getAllRealizationSpecs() or {}

NMServerSPZombieAssignmentFlow._diag = NMServerSPZombieAssignmentFlow._diag or {
    ticks = 0,
    updateCalls = 0,
    attachAttempts = 0,
    attachSuccess = 0,
    attachFailure = 0,
    locationFailures = 0,
    scanCalls = 0,
    scanCandidates = 0,
    scanNearby = 0,
    scanLoadedSweep = 0,
    listCursor = 0,
    attachInventoryFallback = 0,
    attachExcluded = 0,
    attachExcludedScrubbed = 0,
    lastReportedAttachSuccess = 0,
    lastReportedAttachFailure = 0,
    lastReportedAttachFallback = 0,
    attachSuppressed = 0
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
        and NMZombieLiveStrategy.shouldRunSPRuntimeAttach
        and NMZombieLiveStrategy.shouldRunSPRuntimeAttach() == true
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

local function zombieDebugId(zombie)
    return tostring(zombie and zombie.getOnlineID and zombie:getOnlineID() or zombie and zombie.getObjectID and zombie:getObjectID() or "unknown")
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

local function getModData(holder)
    return NMZombieAudioVisualSupport.getProofModData(holder)
end

local function transmitIfPossible(holder)
    local md = holder and getModData(holder) or nil
    if md and holder and holder.transmitModData then
        pcall(holder.transmitModData, holder)
    end
end

local function pushZombieVisualReplication(zombie)
    NMZombieAudioVisualSupport.pushZombieVisualReplication(zombie)
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

    local localPlayer = getPlayer and getPlayer() or nil
    if localPlayer and not seen[localPlayer] then
        out[#out + 1] = localPlayer
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

local function getSpecForVariantId(variantId)
    return NMZombieDeviceVariantCatalog and NMZombieDeviceVariantCatalog.getSpec and NMZombieDeviceVariantCatalog.getSpec(variantId) or nil
end

local function getStampedVariantSpec(zombie)
    local md = getModData(zombie)
    return NMZombieDeviceVariantCatalog and NMZombieDeviceVariantCatalog.resolveStoredSpec and NMZombieDeviceVariantCatalog.resolveStoredSpec(md) or nil
end

local function isMusicSelection(selection)
    return NMZombieDeviceVariantCatalog and NMZombieDeviceVariantCatalog.isMusicSelection and NMZombieDeviceVariantCatalog.isMusicSelection(selection) == true
end

local function shouldRealizeSelection(selection)
    return NMZombieDeviceVariantCatalog and NMZombieDeviceVariantCatalog.shouldRealizeSelection and NMZombieDeviceVariantCatalog.shouldRealizeSelection(selection)
end

local function resolveSelectionContext(zombie, selection)
    if not isMusicSelection(selection) then
        return nil, nil, "ledger_selected_false"
    end
    local zombieId = NMZombieVisualTargetContract and NMZombieVisualTargetContract.getZombieId and NMZombieVisualTargetContract.getZombieId(zombie) or zombieDebugId(zombie)
    local baseSpec = NMZombieDeviceVariantCatalog and NMZombieDeviceVariantCatalog.resolveRealization and NMZombieDeviceVariantCatalog.resolveRealization(selection, zombieId) or nil
    if not baseSpec then
        return nil, nil, "unknown_variant"
    end
    local shouldRealize = shouldRealizeSelection(selection)
    local spec = shouldRealize == true and baseSpec or nil
    local payload = NMZombieMediaPayloadResolver and NMZombieMediaPayloadResolver.resolveZombiePayload and NMZombieMediaPayloadResolver.resolveZombiePayload(selection, zombieId, spec) or nil
    return spec, payload, shouldRealize == true and nil or "device_disabled"
end

local function findAttachedProofItem(zombie, spec)
    local resolved = type(spec) == "table" and spec or getStampedVariantSpec(zombie)
    if not resolved then
        return nil
    end
    local attachedItem = NMZombieAudioVisualSupport.findAttachedProofItem(zombie, resolved)
    if attachedItem then
        return attachedItem
    end

    local md = getModData(zombie)
    local status = tostring(md and md.status or "")
    local wantedUuid = tostring(md and md.deviceUUID or "")
    if status == "attached" then
        local inventory = zombie and zombie.getInventory and zombie:getInventory() or nil
        local items = inventory and inventory.getItems and inventory:getItems() or nil
        if items and items.size then
            for i = 0, items:size() - 1 do
                local item = items:get(i)
                local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
                if fullType == tostring(resolved.fullType or "") then
                    if wantedUuid == "" then
                        return item
                    end
                    local state = item and NMDeviceState and NMDeviceState.peek and NMDeviceState.peek(item) or nil
                    local uuid = tostring(state and state.deviceUUID or "")
                    if uuid == wantedUuid then
                        NMServerSPZombieAssignmentFlow._diag.attachInventoryFallback = (NMServerSPZombieAssignmentFlow._diag.attachInventoryFallback or 0) + 1
                        return item
                    end
                end
            end
        end
    end

    return nil
end

local function findInventoryProofItem(zombie, spec)
    return NMZombieAudioVisualSupport.findInventoryProofItem(zombie, spec)
end

local function zombieSupportsProofLocation(zombie, spec)
    local locationIdWanted = tostring(spec and spec.attachmentLocation or "")
    if locationIdWanted == "" then
        return false
    end
    local attachedItems = zombie and zombie.getAttachedItems and zombie:getAttachedItems() or nil
    local group = attachedItems and attachedItems.getGroup and attachedItems:getGroup() or nil
    if not (group and group.size and group.getLocationByIndex) then
        return false
    end
    for i = 0, group:size() - 1 do
        local entry = group:getLocationByIndex(i)
        local locationId = entry and entry.getId and tostring(entry:getId() or "") or ""
        if locationId == locationIdWanted then
            return true
        end
    end
    return false
end

local function dumpAvailableAttachmentLocations(zombie)
    local attachedItems = zombie and zombie.getAttachedItems and zombie:getAttachedItems() or nil
    local group = attachedItems and attachedItems.getGroup and attachedItems:getGroup() or nil
    if not (group and group.size and group.getLocationByIndex) then
        return "locations=nil"
    end
    local out = {}
    for i = 0, group:size() - 1 do
        local entry = group:getLocationByIndex(i)
        out[#out + 1] = tostring(entry and entry.getId and entry:getId() or "")
    end
    return table.concat(out, ",")
end

local function addInventoryProofItem(zombie, spec)
    local inventory = zombie and zombie.getInventory and zombie:getInventory() or nil
    if not (inventory and inventory.AddItem) then
        return nil, "missing_inventory"
    end
    local item = NMZombieAudioVisualSupport.addInventoryItem(inventory, spec)
    if not item then
        return nil, "item_add_failed"
    end
    return item, nil
end

local function removeInventoryItem(zombie, item)
    local inventory = zombie and zombie.getInventory and zombie:getInventory() or nil
    NMZombieAudioVisualSupport.removeInventoryItem(inventory, item)
end

local function clearKnownProofStates(zombie, keepVariantId)
    local removed = 0
    for i = 1, #KNOWN_SPECS do
        local spec = KNOWN_SPECS[i]
        if tostring(spec.variantId or "") ~= tostring(keepVariantId or "") then
            removed = removed + NMZombieAudioVisualSupport.scrubZombieProofState(zombie, spec, "")
        end
    end
    return removed
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

local function initializeProofState(zombie, item, spec)
    return NMZombieAudioVisualSupport.initializeProofState(zombie, item, spec, STRATEGY_NAME, applyAttachedAuthority)
end

local function getStoredPayload(zombie)
    local md = getModData(zombie)
    return NMZombieMediaPayloadResolver and NMZombieMediaPayloadResolver.resolveStoredPayload and NMZombieMediaPayloadResolver.resolveStoredPayload(md) or nil
end

local function applyPayloadToProofState(zombie, item, spec, payload)
    local profile, state, stateReason = initializeProofState(zombie, item, spec)
    if stateReason then
        return nil, stateReason
    end
    NMZombieMediaPayloadRuntime.applyPayloadToState(state, payload)
    if profile and profile.defaultPlaybackMode then
        state.playbackMode = tostring(profile.defaultPlaybackMode)
    end
    if spec and spec.variantId == "boombox" then
        state.playbackMode = "world"
    elseif spec and (spec.variantId == "walkman" or spec.variantId == "cd_player") then
        state.playbackMode = "personal"
    end
    if NMDeviceState and NMDeviceState.bumpRevision then
        NMDeviceState.bumpRevision(state)
    end
    return state, nil
end

local function attachProofItem(zombie, item, spec)
    return NMZombieAudioVisualSupport.attachProofItem(zombie, item, spec)
end

local function tryRegisterManagedCompanionCase(zombie, payload, state, source)
    local result = NMZombieAudioVisualSupport.registerManagedCompanionCase(zombie, payload, state, source, "sp")
    if result and result.ok then
        return true
    end
    return NMZombieAudioVisualSupport.recordCompanionCaseRegistrationFailure(
        zombie,
        payload,
        state,
        source,
        "sp",
        result and result.reason or "unknown"
    )
end

local function markZombieState(zombie, spec, status, item, reason, selection)
    local payload = reason and type(reason) == "table" and reason.payload or nil
    local detail = reason and type(reason) == "table" and reason.reason or reason
    NMZombieAudioVisualSupport.stampZombieStatus(zombie, spec, {
        status = status,
        item = item,
        reason = detail,
        strategyName = STRATEGY_NAME,
        selection = selection,
        payload = payload,
        lastAttemptTick = tonumber(NMServerSPZombieAssignmentFlow._diag and NMServerSPZombieAssignmentFlow._diag.ticks or 0) or 0
    })
end

local function markSelectionStatus(zombie, spec, status, selection, reason, payload)
    local resolved = spec or getSpecForVariantId(selection and selection.variantId or "") or NMZombieAudioVisualSupport.DefaultSpec
    NMZombieAudioVisualSupport.stampZombieStatus(zombie, resolved, {
        status = status,
        reason = tostring(reason or "selection_state"),
        strategyName = STRATEGY_NAME,
        selection = selection,
        payload = payload,
        processed = status == "excluded" or status == "suppressed" or status == "media_only",
        lastAttemptTick = tonumber(NMServerSPZombieAssignmentFlow._diag and NMServerSPZombieAssignmentFlow._diag.ticks or 0) or 0,
        deviceUUID = ""
    })
end

local function shouldAttemptAttach(zombie)
    local md = getModData(zombie)
    local status = tostring(md and md.status or "")
    local spec = getStampedVariantSpec(zombie)
    local mediaMode = tostring(md and md.mediaMode or "")
    if status == "attached" then
        local selected = md and md.selected == true
        local selectionSource = tostring(md and md.selectionSource or "")
        if selected and selectionSource == "server_ledger" and spec and findAttachedProofItem(zombie, spec) and mediaMode ~= "" then
            return false
        end
        return true
    end
    if status == "media_only" then
        return mediaMode == ""
    end
    if status == "excluded" or status == "suppressed" then
        if spec and (findAttachedProofItem(zombie, spec) or findInventoryProofItem(zombie, spec)) then
            return true
        end
        return false
    end
    if status ~= "failed" then
        return true
    end
    local currentTick = tonumber(NMServerSPZombieAssignmentFlow._diag and NMServerSPZombieAssignmentFlow._diag.ticks or 0) or 0
    local lastAttemptTick = tonumber(md and md.lastAttemptTick or 0) or 0
    return (currentTick - lastAttemptTick) >= FAILED_RETRY_TICKS
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

local function ensureZombieHasProofDevice(zombie)
    NMServerSPZombieAssignmentFlow._diag.attachAttempts = (NMServerSPZombieAssignmentFlow._diag.attachAttempts or 0) + 1
    local selection = NMZombieVisualTargetLedger and NMZombieVisualTargetLedger.getOrAssignZombieSelection and NMZombieVisualTargetLedger.getOrAssignZombieSelection(zombie, STRATEGY_NAME) or nil
    local spec, payload, selectionReason = resolveSelectionContext(zombie, selection)
    local previousPayload = getStoredPayload(zombie)
    if not spec then
        local removed = clearKnownProofStates(zombie)
        NMZombieMediaPayloadRuntime.syncInventoryPayload(zombie, payload, previousPayload)
        NMZombieAudioVisualSupport.stampCorpseCaseIntent(zombie, payload)
        local status = payload and payload.mediaMode == "media_only" and "media_only" or (selectionReason == "device_disabled" and "suppressed" or "excluded")
        if selectionReason == "device_disabled" then
            NMServerSPZombieAssignmentFlow._diag.attachSuppressed = (NMServerSPZombieAssignmentFlow._diag.attachSuppressed or 0) + 1
            markSelectionStatus(zombie, getSpecForVariantId(selection and selection.variantId or ""), status, selection, removed > 0 and "device_disabled_scrubbed" or "device_disabled", payload)
            return false
        end
        NMServerSPZombieAssignmentFlow._diag.attachExcluded = (NMServerSPZombieAssignmentFlow._diag.attachExcluded or 0) + 1
        NMServerSPZombieAssignmentFlow._diag.attachExcludedScrubbed = (NMServerSPZombieAssignmentFlow._diag.attachExcludedScrubbed or 0) + removed
        markSelectionStatus(zombie, getSpecForVariantId(selection and selection.variantId or ""), status, selection, removed > 0 and "ledger_selected_false_scrubbed" or "ledger_selected_false", payload)
        return false
    end

    clearKnownProofStates(zombie, spec.variantId)

    if not zombieSupportsProofLocation(zombie, spec) then
        NMServerSPZombieAssignmentFlow._diag.attachFailure = (NMServerSPZombieAssignmentFlow._diag.attachFailure or 0) + 1
        NMServerSPZombieAssignmentFlow._diag.locationFailures = (NMServerSPZombieAssignmentFlow._diag.locationFailures or 0) + 1
        markZombieState(zombie, spec, "failed", nil, { reason = "missing_proof_location", payload = payload }, selection)
        logProof(
            "attach_failed",
            string.format(
                "zombie=%s reason=missing_proof_location location=%s model=%s locations=%s",
                zombieDebugId(zombie),
                tostring(spec.attachmentLocation or ""),
                tostring(spec.modelAttachmentName or ""),
                dumpAvailableAttachmentLocations(zombie)
            ),
            true
        )
        return false
    end

    local attachedItem = findAttachedProofItem(zombie, spec)
    if attachedItem then
        local state, stateReason = applyPayloadToProofState(zombie, attachedItem, spec, payload)
        if stateReason then
            NMServerSPZombieAssignmentFlow._diag.attachFailure = (NMServerSPZombieAssignmentFlow._diag.attachFailure or 0) + 1
            markZombieState(zombie, spec, "failed", attachedItem, { reason = stateReason, payload = payload }, selection)
            return false
        end
        tryRegisterManagedCompanionCase(zombie, payload, state, "sp_runtime_attach")
        NMZombieMediaPayloadRuntime.syncInventoryPayload(zombie, payload, previousPayload)
        NMZombieAudioVisualSupport.stampCorpseCaseIntent(zombie, payload)
        markZombieState(zombie, spec, "attached", attachedItem, { payload = payload }, selection)
        return true
    end

    local item = findInventoryProofItem(zombie, spec)
    local createdItem = false
    if not item then
        local addReason = nil
        item, addReason = addInventoryProofItem(zombie, spec)
        if not item then
            NMServerSPZombieAssignmentFlow._diag.attachFailure = (NMServerSPZombieAssignmentFlow._diag.attachFailure or 0) + 1
            markZombieState(zombie, spec, "failed", nil, { reason = addReason, payload = payload }, selection)
            logProof("attach_failed", string.format("zombie=%s reason=%s", zombieDebugId(zombie), tostring(addReason or "unknown")), true)
            return false
        end
        createdItem = true
    end

    local state, stateReason = applyPayloadToProofState(zombie, item, spec, payload)
    if stateReason then
        NMServerSPZombieAssignmentFlow._diag.attachFailure = (NMServerSPZombieAssignmentFlow._diag.attachFailure or 0) + 1
        markZombieState(zombie, spec, "failed", item, { reason = stateReason, payload = payload }, selection)
        logProof("attach_failed", string.format("zombie=%s reason=%s", zombieDebugId(zombie), tostring(stateReason)), true)
        return false
    end
    tryRegisterManagedCompanionCase(zombie, payload, state, "sp_runtime_attach")

    local ok, attachReason = attachProofItem(zombie, item, spec)
    if not ok then
        if createdItem then
            removeInventoryItem(zombie, item)
        end
        NMServerSPZombieAssignmentFlow._diag.attachFailure = (NMServerSPZombieAssignmentFlow._diag.attachFailure or 0) + 1
        markZombieState(zombie, spec, "failed", item, { reason = attachReason, payload = payload }, selection)
        logProof(
            "attach_failed",
            string.format(
                "zombie=%s reason=%s locations=%s",
                zombieDebugId(zombie),
                tostring(attachReason or "unknown"),
                dumpAvailableAttachmentLocations(zombie)
            ),
            true
        )
        return false
    end

    NMServerSPZombieAssignmentFlow._diag.attachSuccess = (NMServerSPZombieAssignmentFlow._diag.attachSuccess or 0) + 1
    NMZombieMediaPayloadRuntime.syncInventoryPayload(zombie, payload, previousPayload)
        NMZombieAudioVisualSupport.stampCorpseCaseIntent(zombie, payload)
    markZombieState(zombie, spec, "attached", item, { payload = payload }, selection)
    return true
end

function NMServerSPZombieAssignmentFlow.onZombieUpdate(zombie)
    if not shouldRun() then
        return
    end
    if not isAliveZombie(zombie) then
        return
    end
    NMServerSPZombieAssignmentFlow._diag.updateCalls = (NMServerSPZombieAssignmentFlow._diag.updateCalls or 0) + 1
    if not shouldAttemptAttach(zombie) then
        return
    end

    ensureZombieHasProofDevice(zombie)
end

function NMServerSPZombieAssignmentFlow.onTick()
    if not shouldRun() then
        return
    end
    local diag = NMServerSPZombieAssignmentFlow._diag
    diag.ticks = (tonumber(diag.ticks) or 0) + 1
    if (diag.ticks % SCAN_INTERVAL_TICKS) == 0 then
        local players = collectCandidatePlayers()
        local cell = getCell and getCell() or nil
        local zombies = cell and cell.getZombieList and cell:getZombieList() or nil
        diag.scanCalls = (diag.scanCalls or 0) + 1
        if zombies and zombies.size and #players > 0 then
            local processed = 0
            local nearby = 0
            local candidates = 0
            local loadedSweepProcessed = 0
            local total = zombies:size()
            local startIndex = tonumber(diag.listCursor or 0) or 0
            countZombiesWithModulo(zombies, startIndex, total, function(zombie)
                if isAliveZombie(zombie) then
                    candidates = candidates + 1
                    if isZombieNearAnyPlayer(zombie, players) then
                        nearby = nearby + 1
                        if processed < SCAN_ZOMBIE_LIMIT and shouldAttemptAttach(zombie) then
                            processed = processed + 1
                            ensureZombieHasProofDevice(zombie)
                        end
                    end
                end
            end)
            diag.listCursor = total > 0 and ((startIndex + LOADED_SWEEP_LIMIT) % total) or 0
            if processed < SCAN_ZOMBIE_LIMIT and total > 0 then
                countZombiesWithModulo(zombies, startIndex, LOADED_SWEEP_LIMIT, function(zombie)
                    if processed >= SCAN_ZOMBIE_LIMIT then
                        return
                    end
                    if isAliveZombie(zombie) and shouldAttemptAttach(zombie) and not isZombieNearAnyPlayer(zombie, players) then
                        processed = processed + 1
                        loadedSweepProcessed = loadedSweepProcessed + 1
                        ensureZombieHasProofDevice(zombie)
                    end
                end)
            end
            diag.scanCandidates = (diag.scanCandidates or 0) + candidates
            diag.scanNearby = (diag.scanNearby or 0) + nearby
            diag.scanLoadedSweep = (diag.scanLoadedSweep or 0) + loadedSweepProcessed
            diag.lastReportedAttachSuccess = diag.attachSuccess or 0
            diag.lastReportedAttachFailure = diag.attachFailure or 0
            diag.lastReportedAttachFallback = diag.attachInventoryFallback or 0
        else
            diag.scanCandidates = (diag.scanCandidates or 0) + 0
        end
    end
    if (diag.ticks % HEARTBEAT_TICKS) ~= 0 then
        return
    end
end

return NMServerSPZombieAssignmentFlow
