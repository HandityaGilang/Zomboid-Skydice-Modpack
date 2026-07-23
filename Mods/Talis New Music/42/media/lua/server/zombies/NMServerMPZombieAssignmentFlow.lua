NMServerMPZombieAssignmentFlow = NMServerMPZombieAssignmentFlow or NMServerZombieLegacyLootFlow or {}
NMServerZombieLegacyLootFlow = NMServerMPZombieAssignmentFlow
require "zombies/NMZombieAudioVisualSupport"
require "zombies/NMZombieDeviceVariantCatalog"
require "zombies/NMZombieMediaPayloadResolver"
require "zombies/NMZombieMediaPayloadRuntime"

local STRATEGY_NAME = "mp_assignment_flow"
local SCAN_RADIUS = 14
local MAX_ZOMBIES_PER_PLAYER = 32
local HEARTBEAT_TICKS = 900
local TICK_INTERVAL = 90
local FAILURE_COOLDOWN_TICKS = 900
local NATURAL_INTAKE_SCAN_INTERVAL = 10
local NATURAL_INTAKE_RADIUS = 24
local NATURAL_INTAKE_MAX_ZOMBIES_PER_PLAYER = 192
local NATURAL_INTAKE_PROCESS_LIMIT = 96
local SAMPLE_LIMIT = 3
local SAMPLE_RECHECK_DELAY_TICKS = 120
local KNOWN_SPECS = NMZombieDeviceVariantCatalog and NMZombieDeviceVariantCatalog.getAllRealizationSpecs and NMZombieDeviceVariantCatalog.getAllRealizationSpecs() or {}

NMServerMPZombieAssignmentFlow._diag = NMServerMPZombieAssignmentFlow._diag or {
    ticks = 0,
    attachAttempts = 0,
    attachSuccess = 0,
    attachFailure = 0,
    attachExcluded = 0,
    attachExcludedScrubbed = 0,
    attachSuppressed = 0,
    supportApplied = 0,
    queueEnqueued = 0,
    queueProcessed = 0,
    queueScanned = 0,
    fallbackApplied = 0,
    strategyAssignments = 0,
    attachedListVisible = 0,
    attachedListMissing = 0,
    inventoryStillHasProof = 0,
    supportStillWorn = 0,
    sampleBudget = 0,
    pendingSamples = {},
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
        and NMZombieLiveStrategy.shouldRunMPAssignmentFlow
        and NMZombieLiveStrategy.shouldRunMPAssignmentFlow() == true
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

local function getModData(holder)
    return NMZombieAudioVisualSupport.getProofModData(holder)
end

local function transmitIfPossible(holder)
    local md = holder and getModData(holder) or nil
    if md then
        if holder and holder.transmitModData then
            pcall(holder.transmitModData, holder)
        end
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
    NMZombieAudioVisualSupport.pushZombieVisualReplication(zombie, wornItem)
end

local function getZombieQueueKey(zombie)
    return zombie and zombie.getObjectID and tostring(zombie:getObjectID() or "") or tostring(zombie)
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

local function addInventoryItem(inventory, spec)
    if type(spec) ~= "table" then
        return nil
    end
    return NMZombieAudioVisualSupport.addInventoryItem(inventory, spec)
end

local function findAttachedProofItem(zombie, spec)
    local resolved = type(spec) == "table" and spec or getStampedVariantSpec(zombie)
    if not resolved then
        return nil
    end
    return NMZombieAudioVisualSupport.findAttachedProofItem(zombie, resolved)
end

local function zombieSupportsProofLocation(zombie, spec)
    local wantedLocation = tostring(spec and spec.attachmentLocation or "")
    if wantedLocation == "" then
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
        if locationId == wantedLocation then
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

local function findInventoryProofItem(zombie, spec)
    local wantedUuid = tostring(getModData(zombie) and getModData(zombie).deviceUUID or "")
    return NMZombieAudioVisualSupport.findInventoryProofItem(zombie, spec, wantedUuid)
end

local function collectInventoryProofItems(zombie, spec)
    local wantedUuid = tostring(getModData(zombie) and getModData(zombie).deviceUUID or "")
    return NMZombieAudioVisualSupport.findInventoryProofItems(zombie, spec, wantedUuid)
end

local function inventoryHasProofUuid(zombie, wantedUuid, spec)
    local resolved = type(spec) == "table" and spec or getStampedVariantSpec(zombie)
    local inventory = zombie and zombie.getInventory and zombie:getInventory() or nil
    local items = inventory and inventory.getItems and inventory:getItems() or nil
    if not (items and items.size and resolved) then
        return false, nil
    end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        if fullType == tostring(resolved.fullType or "") then
            local state = item and NMDeviceState and NMDeviceState.peek and NMDeviceState.peek(item) or nil
            local uuid = tostring(state and state.deviceUUID or "")
            if wantedUuid == "" or uuid == wantedUuid then
                return true, item
            end
        end
    end
    return false, nil
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

local function recordTruthObservation(zombie, uuid, phase)
    local diag = NMServerMPZombieAssignmentFlow._diag
    local spec = getStampedVariantSpec(zombie)
    local attachedVisible = spec and findAttachedProofItem(zombie, spec) ~= nil or false
    local inventoryVisible = inventoryHasProofUuid(zombie, uuid, spec)
    if attachedVisible then
        diag.attachedListVisible = (diag.attachedListVisible or 0) + 1
    else
        diag.attachedListMissing = (diag.attachedListMissing or 0) + 1
    end
    if inventoryVisible then
        diag.inventoryStillHasProof = (diag.inventoryStillHasProof or 0) + 1
    end
end

local probeRefreshPaths

local function sampleAttachmentLifecycle(zombie, uuid)
    local diag = NMServerMPZombieAssignmentFlow._diag
    if (diag.sampleBudget or 0) <= 0 then
        return
    end
    diag.sampleBudget = (diag.sampleBudget or 0) - 1
    recordTruthObservation(zombie, uuid, "attach_postcheck")
    probeRefreshPaths(zombie, uuid)
    diag.pendingSamples = diag.pendingSamples or {}
    diag.pendingSamples[#diag.pendingSamples + 1] = {
        zombie = zombie,
        uuid = tostring(uuid or ""),
        recheckTick = (diag.ticks or 0) + SAMPLE_RECHECK_DELAY_TICKS
    }
end

local function tryCallNoArgMethod(target, methodName)
    local fn = target and target[methodName] or nil
    if type(fn) ~= "function" then
        return false, "missing"
    end
    local ok, err = pcall(fn, target)
    if not ok then
        return false, tostring(err or "error")
    end
    return true, nil
end

probeRefreshPaths = function(zombie, uuid)
    local hasResetModelNextFrame = type(zombie and zombie.resetModelNextFrame) == "function"
    local hasResetModel = type(zombie and zombie.resetModel) == "function"
    local hasHumanVisual = type(zombie and zombie.getHumanVisual) == "function"

    if hasResetModelNextFrame then
        tryCallNoArgMethod(zombie, "resetModelNextFrame")
        recordTruthObservation(zombie, uuid, "refresh_postcheck_resetModelNextFrame")
    end

    if hasResetModel then
        tryCallNoArgMethod(zombie, "resetModel")
        recordTruthObservation(zombie, uuid, "refresh_postcheck_resetModel")
    end
end

local function processPendingSamples()
    local diag = NMServerMPZombieAssignmentFlow._diag
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
    local _, state, reason = NMZombieAudioVisualSupport.initializeProofState(zombie, item, spec, STRATEGY_NAME, applyAttachedAuthority)
    return state, reason
end

local function getStoredPayload(zombie)
    local md = getModData(zombie)
    return NMZombieMediaPayloadResolver and NMZombieMediaPayloadResolver.resolveStoredPayload and NMZombieMediaPayloadResolver.resolveStoredPayload(md) or nil
end

local function applyPayloadToProofState(zombie, item, spec, payload)
    local state, reason = initializeProofState(zombie, item, spec)
    if reason then
        return nil, reason
    end
    NMZombieMediaPayloadRuntime.applyPayloadToState(state, payload)
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

local function removeInventoryItem(inventory, item)
    return NMZombieAudioVisualSupport.removeInventoryItem(inventory, item)
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

local function markResolved(zombie, spec, status, item, source, reason, payload)
    NMZombieAudioVisualSupport.stampZombieStatus(zombie, spec, {
        status = status,
        item = item,
        reason = reason,
        processed = status == "attached" or status == "none",
        outcome = tostring(spec and spec.variantId or ""),
        assignmentSource = source,
        strategyName = STRATEGY_NAME,
        payload = payload
    })
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("zombieDiagnostics") == true then
        local md = getModData(zombie)
        if md and tostring(md.corpseCompanionMode or "") == "device_with_media" and tostring(md.lastCompanionCaseRegistrationFailure or "") == "" then
            return
        end
        local contractSig = table.concat({
            tostring(status or ""),
            tostring(md and md.mediaMode or ""),
            tostring(md and md.caseEmptyType or ""),
            tostring(md and md.caseFullType or ""),
            tostring(md and md.deviceUUID or ""),
            tostring(md and md.corpseCompanionMode or ""),
            tostring(md and md.corpseCompanionFullType or ""),
            tostring(md and md.corpseCompanionDeviceUUID or "")
        }, "|")
        if md and md.nmLastResolvedCaseContractSig ~= contractSig then
            md.nmLastResolvedCaseContractSig = contractSig
            NMCore.logChannel(
                "zombieDiagnostics",
                "mp_case_contract_after_resolve",
                string.format(
                    "zombie=%s mode=%s mediaMode=%s caseEmpty=%s caseFull=%s deviceUUID=%s contractMode=%s contractFullType=%s contractDeviceUUID=%s",
                    tostring(zombie and zombie.getObjectID and zombie:getObjectID() or "unknown"),
                    tostring(status or ""),
                    tostring(md and md.mediaMode or ""),
                    tostring(md and md.caseEmptyType or ""),
                    tostring(md and md.caseFullType or ""),
                    tostring(md and md.deviceUUID or ""),
                    tostring(md and md.corpseCompanionMode or ""),
                    tostring(md and md.corpseCompanionFullType or ""),
                    tostring(md and md.corpseCompanionDeviceUUID or "")
                )
            )
        end
    end
end

local function tryRegisterManagedCompanionCase(zombie, payload, state, source)
    local result = NMZombieAudioVisualSupport.registerManagedCompanionCase(zombie, payload, state, source, "mp")
    if result and result.ok then
        return true
    end
    return NMZombieAudioVisualSupport.recordCompanionCaseRegistrationFailure(
        zombie,
        payload,
        state,
        source,
        "mp",
        result and result.reason or "unknown"
    )
end

local function markSelectionState(zombie, spec, source, selection, status, reason, payload)
    local resolved = spec or getSpecForVariantId(selection and selection.variantId or "") or NMZombieAudioVisualSupport.DefaultSpec
    NMZombieAudioVisualSupport.stampZombieStatus(zombie, resolved, {
        status = tostring(status or "excluded"),
        reason = tostring(reason or "selection_state"),
        processed = true,
        outcome = tostring(resolved.variantId or ""),
        assignmentSource = source,
        strategyName = STRATEGY_NAME,
        selection = selection,
        payload = payload,
        deviceUUID = ""
    })
end

local function markFailed(zombie, spec, reason, source, payload)
    local resolved = spec or getStampedVariantSpec(zombie) or NMZombieAudioVisualSupport.DefaultSpec
    NMZombieAudioVisualSupport.stampZombieStatus(zombie, resolved, {
        status = "failed",
        reason = tostring(reason or "unknown"),
        processed = false,
        outcome = tostring(resolved.variantId or ""),
        assignmentSource = source,
        strategyName = STRATEGY_NAME,
        payload = payload,
        failedTick = tonumber(NMServerMPZombieAssignmentFlow._diag.ticks or 0) or 0
    })
end

local function isProcessed(zombie)
    local md = getModData(zombie)
    local status = tostring(md and md.status or "")
    if status == "attached" then
        return tostring(md and md.mediaMode or "") ~= ""
    end
    return status == "none" or status == "suppressed" or status == "excluded" or status == "media_only"
end

local function isFailureCoolingDown(zombie)
    local md = getModData(zombie)
    local failedTick = md and tonumber(md.failedTick) or nil
    if failedTick == nil then
        return false
    end
    local nowTick = tonumber(NMServerMPZombieAssignmentFlow._diag.ticks) or 0
    return (nowTick - failedTick) < FAILURE_COOLDOWN_TICKS
end

local function shouldQueueNaturalZombie(zombie)
    if not isAliveZombie(zombie) then
        return false
    end
    if isProcessed(zombie) or isFailureCoolingDown(zombie) then
        return false
    end
    return true
end

local function ensureNaturalIntakeQueue()
    NMServerMPZombieAssignmentFlow._pendingNaturalIntake = NMServerMPZombieAssignmentFlow._pendingNaturalIntake or {}
    NMServerMPZombieAssignmentFlow._pendingNaturalIntakeSet = NMServerMPZombieAssignmentFlow._pendingNaturalIntakeSet or {}
    return NMServerMPZombieAssignmentFlow._pendingNaturalIntake, NMServerMPZombieAssignmentFlow._pendingNaturalIntakeSet
end

local function enqueueNaturalIntake(zombie, source)
    if not shouldQueueNaturalZombie(zombie) then
        return false
    end
    local queue, queueSet = ensureNaturalIntakeQueue()
    local key = getZombieQueueKey(zombie)
    if key == "" or queueSet[key] == true then
        return false
    end
    queueSet[key] = true
    queue[#queue + 1] = {
        key = key,
        zombie = zombie,
        source = tostring(source or "natural_intake")
    }
    NMServerMPZombieAssignmentFlow._diag.queueEnqueued = (NMServerMPZombieAssignmentFlow._diag.queueEnqueued or 0) + 1
    return true
end

local function dequeueNaturalIntake()
    local queue, queueSet = ensureNaturalIntakeQueue()
    while #queue > 0 do
        local entry = table.remove(queue, 1)
        if entry then
            queueSet[tostring(entry.key or "")] = nil
            return entry
        end
    end
    return nil
end

local function applyLegacyOutcome(zombie, source)
    local inventory = zombie and zombie.getInventory and zombie:getInventory() or nil
    if not inventory then
        markFailed(zombie, nil, "missing_inventory", source, nil)
        NMServerMPZombieAssignmentFlow._diag.attachFailure = (NMServerMPZombieAssignmentFlow._diag.attachFailure or 0) + 1
        return false
    end
    NMServerMPZombieAssignmentFlow._diag.attachAttempts = (NMServerMPZombieAssignmentFlow._diag.attachAttempts or 0) + 1
    local selection = NMZombieVisualTargetLedger and NMZombieVisualTargetLedger.getOrAssignZombieSelection and NMZombieVisualTargetLedger.getOrAssignZombieSelection(zombie, STRATEGY_NAME) or nil
    local spec, payload, selectionReason = resolveSelectionContext(zombie, selection)
    local previousPayload = getStoredPayload(zombie)
    if not spec then
        local removed = clearKnownProofStates(zombie)
        NMZombieAudioVisualSupport.pruneManagedCompanionCaseItems(zombie, "", "")
        NMZombieMediaPayloadRuntime.syncInventoryPayload(zombie, payload, previousPayload)
        NMZombieAudioVisualSupport.stampCorpseCaseIntent(zombie, payload)
        local status = payload and payload.mediaMode == "media_only" and "media_only" or (selectionReason == "device_disabled" and "suppressed" or "excluded")
        if selectionReason == "device_disabled" then
            NMServerMPZombieAssignmentFlow._diag.attachSuppressed = (NMServerMPZombieAssignmentFlow._diag.attachSuppressed or 0) + 1
            markSelectionState(zombie, getSpecForVariantId(selection and selection.variantId or ""), source, selection, status, removed > 0 and "device_disabled_scrubbed" or "device_disabled", payload)
            return false
        end
        NMServerMPZombieAssignmentFlow._diag.attachExcluded = (NMServerMPZombieAssignmentFlow._diag.attachExcluded or 0) + 1
        NMServerMPZombieAssignmentFlow._diag.attachExcludedScrubbed = (NMServerMPZombieAssignmentFlow._diag.attachExcludedScrubbed or 0) + removed
        markSelectionState(zombie, getSpecForVariantId(selection and selection.variantId or ""), source, selection, status, removed > 0 and "ledger_selected_false_scrubbed" or "ledger_selected_false", payload)
        return false
    end
    clearKnownProofStates(zombie, spec.variantId)
    if not zombieSupportsProofLocation(zombie, spec) then
        markFailed(zombie, spec, "missing_proof_location", source, payload)
        NMServerMPZombieAssignmentFlow._diag.attachFailure = (NMServerMPZombieAssignmentFlow._diag.attachFailure or 0) + 1
        return false
    end
    local attachedItem = findAttachedProofItem(zombie, spec)
    if attachedItem then
        local state, stateReason = applyPayloadToProofState(zombie, attachedItem, spec, payload)
        if stateReason then
            markFailed(zombie, spec, stateReason, source, payload)
            NMServerMPZombieAssignmentFlow._diag.attachFailure = (NMServerMPZombieAssignmentFlow._diag.attachFailure or 0) + 1
            return false
        end
        tryRegisterManagedCompanionCase(zombie, payload, state, source)
        NMZombieMediaPayloadRuntime.syncInventoryPayload(zombie, payload, previousPayload)
        NMZombieAudioVisualSupport.stampCorpseCaseIntent(zombie, payload)
        markResolved(zombie, spec, "attached", attachedItem, source, nil, payload)
        return true
    end
    local item = findInventoryProofItem(zombie, spec)
    if not item then
        item = addInventoryItem(inventory, spec)
        if not item then
            markFailed(zombie, spec, "item_add_failed", source, payload)
            NMServerMPZombieAssignmentFlow._diag.attachFailure = (NMServerMPZombieAssignmentFlow._diag.attachFailure or 0) + 1
            return false
        end
    end
    local state, stateReason = applyPayloadToProofState(zombie, item, spec, payload)
    if stateReason then
        markFailed(zombie, spec, stateReason, source, payload)
        NMServerMPZombieAssignmentFlow._diag.attachFailure = (NMServerMPZombieAssignmentFlow._diag.attachFailure or 0) + 1
        return false
    end
    tryRegisterManagedCompanionCase(zombie, payload, state, source)
    local ok, attachReason = attachProofItem(zombie, item, spec)
    if not ok then
        markFailed(zombie, spec, attachReason, source, payload)
        NMServerMPZombieAssignmentFlow._diag.attachFailure = (NMServerMPZombieAssignmentFlow._diag.attachFailure or 0) + 1
        return false
    end
    NMServerMPZombieAssignmentFlow._diag.attachSuccess = (NMServerMPZombieAssignmentFlow._diag.attachSuccess or 0) + 1
    NMServerMPZombieAssignmentFlow._diag.strategyAssignments = (NMServerMPZombieAssignmentFlow._diag.strategyAssignments or 0) + 1
    NMZombieMediaPayloadRuntime.syncInventoryPayload(zombie, payload, previousPayload)
    NMZombieAudioVisualSupport.stampCorpseCaseIntent(zombie, payload)
    markResolved(zombie, spec, "attached", item, source, nil, payload)
    sampleAttachmentLifecycle(zombie, tostring(item and NMDeviceState and NMDeviceState.peek and NMDeviceState.peek(item) and NMDeviceState.peek(item).deviceUUID or ""))
    return true
end

local function scanAroundCharacter(character, callback, radius, maxZombies)
    local square = character and character.getCurrentSquare and character:getCurrentSquare() or nil
    if not square then
        return 0
    end
    local seen = {}
    local processed = 0
    local scanRadius = tonumber(radius) or SCAN_RADIUS
    local scanMax = tonumber(maxZombies) or MAX_ZOMBIES_PER_PLAYER
    for x = square:getX() - scanRadius, square:getX() + scanRadius do
        for y = square:getY() - scanRadius, square:getY() + scanRadius do
            if processed >= scanMax then
                return processed
            end
            local gridSquare = getCell() and getCell():getGridSquare(x, y, square:getZ()) or nil
            if gridSquare then
                local moving = gridSquare:getMovingObjects()
                for i = 0, moving:size() - 1 do
                    local zombie = moving:get(i)
                    local id = zombie and zombie.getObjectID and tostring(zombie:getObjectID() or "") or tostring(zombie)
                    if not seen[id] and isAliveZombie(zombie) then
                        seen[id] = true
                        callback(zombie)
                        processed = processed + 1
                        if processed >= scanMax then
                            return processed
                        end
                    end
                end
            end
        end
    end
    return processed
end

local function observeNaturalCandidatesAroundCharacter(character, source)
    return scanAroundCharacter(
        character,
        function(zombie)
            enqueueNaturalIntake(zombie, source)
        end,
        NATURAL_INTAKE_RADIUS,
        NATURAL_INTAKE_MAX_ZOMBIES_PER_PLAYER
    )
end

local function processNaturalIntakeQueue(limit)
    local remaining = tonumber(limit) or NATURAL_INTAKE_PROCESS_LIMIT
    local processed = 0
    while remaining > 0 do
        local entry = dequeueNaturalIntake()
        if not entry then
            break
        end
        local zombie = entry.zombie
        if shouldQueueNaturalZombie(zombie) then
            applyLegacyOutcome(zombie, entry.source or "natural_intake")
            processed = processed + 1
            remaining = remaining - 1
        end
    end
    NMServerMPZombieAssignmentFlow._diag.queueProcessed = (NMServerMPZombieAssignmentFlow._diag.queueProcessed or 0) + processed
    return processed
end

function NMServerMPZombieAssignmentFlow.onZombieUpdate(zombie)
    if not shouldRun() then
        return
    end
    enqueueNaturalIntake(zombie, "zombie_update")
end

function NMServerMPZombieAssignmentFlow.onTick()
    if not shouldRun() then
        return
    end
    local diag = NMServerMPZombieAssignmentFlow._diag
    diag.ticks = (tonumber(diag.ticks) or 0) + 1
    processPendingSamples()

    local players = getOnlinePlayers and getOnlinePlayers() or nil
    local hasOnlinePlayers = players and players.size and players:size() > 0
    if hasOnlinePlayers and (diag.ticks % NATURAL_INTAKE_SCAN_INTERVAL) == 0 then
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player then
                diag.queueScanned = (diag.queueScanned or 0) + observeNaturalCandidatesAroundCharacter(player, "first_seen_scan")
            end
        end
    elseif (diag.ticks % NATURAL_INTAKE_SCAN_INTERVAL) == 0 then
        local player = getPlayer and getPlayer() or nil
        if player then
            diag.queueScanned = (diag.queueScanned or 0) + observeNaturalCandidatesAroundCharacter(player, "first_seen_scan")
        end
    end

    processNaturalIntakeQueue(NATURAL_INTAKE_PROCESS_LIMIT)

    if (diag.ticks % TICK_INTERVAL) ~= 0 then
        return
    end
    diag.sampleBudget = SAMPLE_LIMIT

    local fallbackApplied = 0
    if hasOnlinePlayers then
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player then
                scanAroundCharacter(player, function(zombie)
                    if applyLegacyOutcome(zombie, "fallback_scan") then
                        fallbackApplied = fallbackApplied + 1
                    end
                end, SCAN_RADIUS, MAX_ZOMBIES_PER_PLAYER)
            end
        end
    else
        local player = getPlayer and getPlayer() or nil
        if player then
            scanAroundCharacter(player, function(zombie)
                if applyLegacyOutcome(zombie, "fallback_scan") then
                    fallbackApplied = fallbackApplied + 1
                end
            end, SCAN_RADIUS, MAX_ZOMBIES_PER_PLAYER)
        end
    end
    diag.fallbackApplied = (diag.fallbackApplied or 0) + fallbackApplied

    diag.lastReportedAttachSuccess = diag.attachSuccess or 0
    diag.lastReportedAttachFailure = diag.attachFailure or 0
    diag.lastReportedSupportApplied = diag.supportApplied or 0
    diag.lastReportedStrategyAssignments = diag.strategyAssignments or 0

    if (diag.ticks % HEARTBEAT_TICKS) ~= 0 then
        return
    end
end

return NMServerMPZombieAssignmentFlow
