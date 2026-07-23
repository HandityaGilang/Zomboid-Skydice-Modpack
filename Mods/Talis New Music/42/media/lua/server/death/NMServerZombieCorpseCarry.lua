NMServerZombieCorpseCarry = NMServerZombieCorpseCarry or {}
require "zombies/NMZombieAudioVisualSupport"
require "zombies/NMZombieDeviceVariantCatalog"
require "zombies/NMZombieMediaPayloadResolver"
require "zombies/NMZombieMediaPayloadRuntime"

local KNOWN_SPECS = NMZombieDeviceVariantCatalog and NMZombieDeviceVariantCatalog.getAllRealizationSpecs and NMZombieDeviceVariantCatalog.getAllRealizationSpecs() or {}

NMServerZombieCorpseCarry._diag = NMServerZombieCorpseCarry._diag or {
    corpseCaptureSkip = 0,
    corpseCaptureQueued = 0,
    corpseCaptureRejected = 0,
    corpseCaptureInventoryFallback = 0,
    corpseSpawnSkip = 0,
    corpseAlreadyPresent = 0,
    corpsePruned = 0,
    corpseCarrySuccess = 0,
    corpseCarryFailed = 0,
    corpseCaptureSPRuntime = 0,
    corpseCaptureMPRuntimeSupport = 0,
    corpseCaptureMPAssignment = 0,
    corpseTickReconciled = 0
}

local TICK_RECONCILE_INTERVAL = 30

local function canRunAuthoritativeMutation()
    if NMCore and NMCore.isMPClientRuntime and NMCore.isMPClientRuntime() == true then
        return false
    end
    if NMAuthorityContract and NMAuthorityContract.canMutateDurableStateAtRuntime then
        return NMAuthorityContract.canMutateDurableStateAtRuntime() == true
    end
    return true
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

local function shouldLogCorpseRuntimeIdentity()
    return (NMCore and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") == true)
        or shouldLogProofVerbose()
end

local function logCorpseRuntimeIdentity(stage, item, profile, state, record)
    if not shouldLogCorpseRuntimeIdentity() then
        return
    end
    local payload = type(record) == "table" and type(record.payload) == "table" and record.payload or nil
    local detail = string.format(
        "stage=%s fullType=%s deviceUUID=%s media=%s mediaMode=%s payloadMedia=%s mediaIndex=%s headphones=%s batteryPresent=%s batteryCharge=%.3f authoritativeMode=%s sourceKind=%s sourceOwner=%s sourceGeneration=%s playbackMode=%s zombieDormant=%s",
        tostring(stage or "unknown"),
        tostring(item and item.getFullType and item:getFullType() or record and record.fullType or ""),
        tostring(state and state.deviceUUID or ""),
        tostring(state and state.mediaFullType or "nil"),
        tostring(payload and payload.mediaMode or "nil"),
        tostring(payload and payload.insertedMediaFullType or "nil"),
        tostring(state and state.mediaRecordedMediaIndex or "nil"),
        tostring(state and state.headphoneItemFullType or "nil"),
        tostring(state and state.batteryPresent == true),
        tonumber(state and state.batteryCharge) or 0.0,
        tostring(state and state.authoritativeMode or ""),
        tostring(state and state.sourceKind or ""),
        tostring(state and state.sourceOwner or ""),
        tostring(state and state.sourceGeneration or 0),
        tostring(state and state.playbackMode or ""),
        tostring(state and state.zombieDormant == true)
    )
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") == true then
        NMCore.logChannel("runtimeProbe", "corpse_item_identity", detail)
    end
    if shouldLogProofVerbose() then
        logProof("corpse_item_identity", detail, true)
    end
end

local function logCorpseSummary(tag)
    if not shouldLogProofVerbose() then
        return
    end
    local d = NMServerZombieCorpseCarry._diag or {}
    logProof(
        tag or "corpse_summary",
        string.format(
            "captureSkip=%s queued=%s rejected=%s inventoryFallback=%s spawnSkip=%s alreadyPresent=%s pruned=%s carrySuccess=%s carryFailed=%s spRuntime=%s mpRuntimeSupport=%s mpAssignment=%s",
            tostring(d.corpseCaptureSkip or 0),
            tostring(d.corpseCaptureQueued or 0),
            tostring(d.corpseCaptureRejected or 0),
            tostring(d.corpseCaptureInventoryFallback or 0),
            tostring(d.corpseSpawnSkip or 0),
            tostring(d.corpseAlreadyPresent or 0),
            tostring(d.corpsePruned or 0),
            tostring(d.corpseCarrySuccess or 0),
            tostring(d.corpseCarryFailed or 0),
            tostring(d.corpseCaptureSPRuntime or 0),
            tostring(d.corpseCaptureMPRuntimeSupport or 0),
            tostring(d.corpseCaptureMPAssignment or 0)
        )
    )
end

local function entityDebugId(entity)
    return tostring(entity and entity.getOnlineID and entity:getOnlineID() or entity and entity.getObjectID and entity:getObjectID() or "unknown")
end

local function isIsoZombie(obj)
    return obj and instanceof and instanceof(obj, "IsoZombie")
end

local function isIsoDeadBody(obj)
    return obj and instanceof and instanceof(obj, "IsoDeadBody")
end

local function getModData(holder)
    return NMZombieAudioVisualSupport.getProofModData(holder)
end

local function getRootModData(holder)
    return holder and holder.getModData and holder:getModData() or nil
end

local function getCorpseLooseLootFullTypes(holder)
    local contract = NMZombieAudioVisualSupport.resolveCompanionCaseContract and NMZombieAudioVisualSupport.resolveCompanionCaseContract(getModData(holder)) or nil
    if contract and contract.mode == "media_only" and tostring(contract.fullType or "") ~= "" then
        return { tostring(contract.fullType) }
    end
    local root = getRootModData(holder)
    local zombieLoot = root and root.nmZombieLoot or nil
    local fullTypes = zombieLoot and zombieLoot.corpseLooseLootFullTypes or nil
    if type(fullTypes) ~= "table" then
        return {}
    end
    local out = {}
    for i = 1, #fullTypes do
        local fullType = tostring(fullTypes[i] or "")
        if fullType ~= "" then
            out[#out + 1] = fullType
        end
    end
    return out
end

local function getCompanionCaseContract(holder)
    return NMZombieAudioVisualSupport.resolveCompanionCaseContract and NMZombieAudioVisualSupport.resolveCompanionCaseContract(getModData(holder)) or nil
end

local function getCompanionCaseRegistrationState(holder)
    return NMZombieAudioVisualSupport.getCompanionCaseRegistrationState and NMZombieAudioVisualSupport.getCompanionCaseRegistrationState(holder) or nil
end

local function getSquareKey(x, y, z)
    return table.concat({ tostring(x or 0), tostring(y or 0), tostring(z or 0) }, ":")
end

local function parseSquareKey(key)
    local x, y, z = tostring(key or ""):match("^([^:]+):([^:]+):([^:]+)$")
    return tonumber(x), tonumber(y), tonumber(z)
end

local function getEntitySquare(entity)
    return entity and entity.getCurrentSquare and entity:getCurrentSquare()
        or entity and entity.getSquare and entity:getSquare()
        or nil
end

local function getSpecForVariantId(variantId)
    return NMZombieDeviceVariantCatalog and NMZombieDeviceVariantCatalog.getSpec and NMZombieDeviceVariantCatalog.getSpec(variantId) or nil
end

local function findAnyKnownProofItem(container)
    local items = container and container.getItems and container:getItems() or nil
    if not (items and items.size) then
        return nil, nil
    end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        local spec = NMZombieDeviceVariantCatalog and NMZombieDeviceVariantCatalog.findSpecByFullType and NMZombieDeviceVariantCatalog.findSpecByFullType(fullType) or nil
        if spec then
            return item, spec
        end
    end
    return nil, nil
end

local function findAttachedProofRecord(zombie)
    local md = getModData(zombie)
    local registration = getCompanionCaseRegistrationState(zombie)
    local spec = NMZombieDeviceVariantCatalog and NMZombieDeviceVariantCatalog.resolveStoredSpec and NMZombieDeviceVariantCatalog.resolveStoredSpec(md) or nil
    local payload = NMZombieMediaPayloadResolver and NMZombieMediaPayloadResolver.resolveStoredPayload and NMZombieMediaPayloadResolver.resolveStoredPayload(md) or nil
    if not spec then
        for i = 1, #KNOWN_SPECS do
            local candidate = KNOWN_SPECS[i]
            if NMZombieAudioVisualSupport.findAttachedProofItem(zombie, candidate) then
                spec = candidate
                break
            end
        end
    end
    if not spec then
        return nil
    end
    local attachedItem = NMZombieAudioVisualSupport.findAttachedProofItem(zombie, spec)
    if attachedItem then
        local state = attachedItem and NMDeviceState and NMDeviceState.peek and NMDeviceState.peek(attachedItem) or nil
        local exported = state and NMDeviceState and NMDeviceState.export and NMDeviceState.export(state) or nil
        if exported then
            exported.isOn = false
            exported.desiredIsOn = false
            exported.isPlaying = false
            exported.desiredIsPlaying = false
            exported.lastStopReason = "corpse_reconcile"
        end
        return {
            fullType = tostring(spec.fullType or ""),
            attachmentLocation = tostring(spec.attachmentLocation or ""),
            modelAttachmentName = tostring(spec.modelAttachmentName or ""),
            deviceUUID = tostring(exported and exported.deviceUUID or ""),
            strategy = tostring(md and (md.strategy or md.liveVisualStrategy) or ""),
            variantId = tostring(spec.variantId or ""),
            state = exported,
            payload = payload,
            companionCaseContract = getCompanionCaseContract(zombie),
            spawnAtDeathCompanionAttempted = tostring(registration and registration.deviceUUID or ""),
            spawnAtDeathCompanionRegistered = registration and registration.registered == true or false,
            spawnAtDeathCompanionRoute = tostring(registration and registration.createRoute or ""),
            corpseLooseLootFullTypes = getCorpseLooseLootFullTypes(zombie)
        }
    end

    local wantedUuid = tostring(md and md.deviceUUID or "")
    local status = tostring(md and md.status or "")
    if status == "attached" and wantedUuid ~= "" then
        local item = NMZombieAudioVisualSupport.findInventoryProofItem(zombie, spec, wantedUuid)
        if item then
            local state = item and NMDeviceState and NMDeviceState.peek and NMDeviceState.peek(item) or nil
            local exported = state and NMDeviceState and NMDeviceState.export and NMDeviceState.export(state) or nil
            if exported then
                exported.isOn = false
                exported.desiredIsOn = false
                exported.isPlaying = false
                exported.desiredIsPlaying = false
                exported.lastStopReason = "corpse_reconcile"
                NMServerZombieCorpseCarry._diag.corpseCaptureInventoryFallback = (NMServerZombieCorpseCarry._diag.corpseCaptureInventoryFallback or 0) + 1
                return {
                    fullType = tostring(spec.fullType or ""),
                    attachmentLocation = tostring(spec.attachmentLocation or ""),
                    modelAttachmentName = tostring(spec.modelAttachmentName or ""),
                    deviceUUID = tostring(exported.deviceUUID or ""),
                    strategy = tostring(md and (md.strategy or md.liveVisualStrategy) or ""),
                    variantId = tostring(spec.variantId or ""),
                    state = exported,
                    payload = payload,
                    companionCaseContract = getCompanionCaseContract(zombie),
                    spawnAtDeathCompanionAttempted = tostring(registration and registration.deviceUUID or ""),
                    spawnAtDeathCompanionRegistered = registration and registration.registered == true or false,
                    spawnAtDeathCompanionRoute = tostring(registration and registration.createRoute or ""),
                    corpseLooseLootFullTypes = getCorpseLooseLootFullTypes(zombie)
                }
            end
        end
    end

    if payload and tostring(payload.mediaMode or "") == "media_only" and tostring(payload.caseFullType or "") ~= "" then
        return {
            fullType = "",
            attachmentLocation = "",
            modelAttachmentName = "",
            deviceUUID = "",
            strategy = tostring(md and (md.strategy or md.liveVisualStrategy) or ""),
            variantId = tostring(md and md.variantId or ""),
            state = nil,
            payload = payload,
            companionCaseContract = getCompanionCaseContract(zombie),
            spawnAtDeathCompanionAttempted = tostring(registration and registration.deviceUUID or ""),
            spawnAtDeathCompanionRegistered = registration and registration.registered == true or false,
            spawnAtDeathCompanionRoute = tostring(registration and registration.createRoute or ""),
            corpseLooseLootFullTypes = getCorpseLooseLootFullTypes(zombie)
        }
    end

    return nil
end

local function shouldCarryCorpseProof(zombie, record, selection)
    if type(selection) == "table" then
        return selection.selected == true or selection.musicSelected == true
    end
    local stamped = NMZombieVisualTargetLedger and NMZombieVisualTargetLedger.getStampedSelection and NMZombieVisualTargetLedger.getStampedSelection(zombie) or nil
    if stamped then
        return stamped.selected == true or stamped.musicSelected == true
    end
    return false
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
        local item = entry and entry.getItem and entry:getItem() or entry and entry.getInventoryItem and entry:getInventoryItem() or entry
        local itemFullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        if itemFullType == wanted then
            return item
        end
    end
    return nil
end

local function logLiveCaptureProbe(zombie, record)
    if not shouldLogProofVerbose() then
        return
    end
    local inventory = zombie and zombie.getInventory and zombie:getInventory() or nil
    local items = inventory and inventory.getItems and inventory:getItems() or nil
    local wantedUuid = tostring(record and record.deviceUUID or "")
    local inventoryHasProof = false
    if items and items.size then
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
            if fullType == tostring(record and record.fullType or "") then
                local state = item and NMDeviceState and NMDeviceState.peek and NMDeviceState.peek(item) or nil
                local uuid = tostring(state and state.deviceUUID or "")
                if wantedUuid == "" or uuid == wantedUuid then
                    inventoryHasProof = true
                    break
                end
            end
        end
    end
    local supportWorn = verifyWornItem(zombie, "Base.Belt2") ~= nil
    local square = getEntitySquare(zombie)
    local selection = NMZombieVisualTargetLedger and NMZombieVisualTargetLedger.getOrAssignZombieSelection and NMZombieVisualTargetLedger.getOrAssignZombieSelection(zombie, tostring(record and record.strategy or "")) or nil
    logProof(
        "live_capture_probe",
        string.format(
            "zombie=%s square=%s:%s:%s strategy=%s selected=%s proofUuid=%s attachedRecord=%s inventoryHasProof=%s supportWorn=%s",
            tostring(entityDebugId(zombie)),
            tostring(square and square:getX() or "nil"),
            tostring(square and square:getY() or "nil"),
            tostring(square and square:getZ() or "nil"),
            tostring(record and record.strategy or ""),
            tostring(selection and (selection.selected == true or selection.musicSelected == true)),
            tostring(record and record.deviceUUID or ""),
            tostring(record ~= nil),
            tostring(inventoryHasProof),
            tostring(supportWorn)
        )
    )
end

local function logCorpseLooseLoot(tag, entity, record)
    if not shouldLogProofVerbose() then
        return
    end
    local looseLoot = type(record and record.corpseLooseLootFullTypes) == "table" and record.corpseLooseLootFullTypes or {}
    local joined = (#looseLoot > 0) and table.concat(looseLoot, ",") or "(none)"
    local payload = record and record.payload or nil
    local contract = type(record and record.companionCaseContract) == "table" and record.companionCaseContract or nil
    local spawnAttempted = tostring(record and record.spawnAtDeathCompanionAttempted or "")
    local spawnRegistered = record and record.spawnAtDeathCompanionRegistered == true or false
    local spawnRoute = tostring(record and record.spawnAtDeathCompanionRoute or "")
    logProof(
        tag,
        string.format(
            "id=%s variant=%s mediaMode=%s looseLoot=%s contractMode=%s contractFullType=%s contractDeviceUUID=%s spawnAttempted=%s spawnRegistered=%s spawnRoute=%s fullType=%s",
            tostring(entityDebugId(entity)),
            tostring(record and record.variantId or ""),
            tostring(payload and payload.mediaMode or ""),
            tostring(joined),
            tostring(contract and contract.mode or ""),
            tostring(contract and contract.fullType or ""),
            tostring(contract and contract.deviceUUID or ""),
            tostring(spawnAttempted ~= ""),
            tostring(spawnRegistered),
            tostring(spawnRoute),
            tostring(record and record.fullType or "")
        ),
        true
    )
end

local function logCorpseSpawnPath(tag, body, detail)
    if not shouldLogProofVerbose() then
        return
    end
    local square = getEntitySquare(body)
    logProof(
        tag,
        string.format(
            "id=%s square=%s:%s:%s detail=%s",
            tostring(entityDebugId(body)),
            tostring(square and square:getX() or "nil"),
            tostring(square and square:getY() or "nil"),
            tostring(square and square:getZ() or "nil"),
            tostring(detail or "")
        ),
        true
    )
end

local function addItemToContainer(container, fullType)
    if not (container and container.AddItem) then
        return nil
    end
    local item = container:AddItem(fullType)
    logProof("corpse_add_item", "fullType=" .. tostring(fullType or ""), true)
    if item and sendAddItemToContainer then
        pcall(sendAddItemToContainer, container, item)
    end
    return item
end

local function countItemsByFullType(container, fullType)
    local wanted = tostring(fullType or "")
    if wanted == "" then
        return 0
    end
    local items = container and container.getItems and container:getItems() or nil
    if not (items and items.size) then
        return 0
    end
    local count = 0
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local itemFullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        if itemFullType == wanted then
            count = count + 1
        end
    end
    return count
end

local function collectItemsByFullType(container, fullType, limit)
    local wanted = tostring(fullType or "")
    local out = {}
    if wanted == "" then
        return out
    end
    local items = container and container.getItems and container:getItems() or nil
    if not (items and items.size) then
        return out
    end
    local maxCount = math.max(0, math.floor(tonumber(limit) or 0))
    for i = 0, items:size() - 1 do
        if #out >= maxCount then
            break
        end
        local item = items:get(i)
        local itemFullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        if itemFullType == wanted then
            out[#out + 1] = item
        end
    end
    return out
end

local function containerHasManagedCompanionCase(container, fullType, deviceUUID)
    local wantedType = tostring(fullType or "")
    local wantedUuid = tostring(deviceUUID or "")
    if wantedType == "" then
        return false
    end
    local items = container and container.getItems and container:getItems() or nil
    if not (items and items.size) then
        return false
    end
    local sawFullType = false
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local itemFullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        if itemFullType == wantedType then
            sawFullType = true
            local md = item and item.getModData and item:getModData() or nil
            local marked = md and md.nmZombieManagedCompanionCase == true
            local markedUuid = tostring(md and md.nmZombieManagedCompanionCaseDeviceUUID or "")
            if marked and (wantedUuid == "" or markedUuid == wantedUuid) then
                return true
            end
        end
    end
    return sawFullType
end

local function syncMediaOnlyCorpseLooseLoot(container, record)
    if not (container and record) then
        return
    end
    local explicitLooseLoot = type(record.corpseLooseLootFullTypes) == "table" and record.corpseLooseLootFullTypes or {}
    local companionContract = type(record.companionCaseContract) == "table" and record.companionCaseContract or nil
    local candidates = {}

    local function addCandidate(fullType)
        local key = tostring(fullType or "")
        if key ~= "" then
            candidates[key] = true
        end
    end

    if #explicitLooseLoot > 0 then
        for i = 1, #explicitLooseLoot do
            addCandidate(explicitLooseLoot[i])
        end
    elseif companionContract and companionContract.mode == "media_only" and tostring(companionContract.fullType or "") ~= "" then
        addCandidate(companionContract.fullType)
    elseif record.payload then
        addCandidate(record.payload.caseFullType)
    end

    for fullType in pairs(candidates) do
        local wantedCount = 0
        for i = 1, #explicitLooseLoot do
            if fullType == tostring(explicitLooseLoot[i] or "") then
                wantedCount = wantedCount + 1
            end
        end
        if wantedCount == 0 and companionContract and companionContract.mode == "media_only" and fullType == tostring(companionContract.fullType or "") then
            wantedCount = 1
        end
        if wantedCount == 0 and record.payload and companionContract == nil then
            local wantedFull = tostring(record.payload.mediaMode or "") == "media_only" and tostring(record.payload.caseFullType or "") or ""
            if fullType == wantedFull then
                wantedCount = 1
            end
        end
        local currentCount = countItemsByFullType(container, fullType)
        if currentCount > wantedCount then
            local removals = collectItemsByFullType(container, fullType, currentCount - wantedCount)
            for i = 1, #removals do
                removeItemFromContainer(container, removals[i])
            end
        elseif currentCount < wantedCount then
            for _ = currentCount + 1, wantedCount do
                addItemToContainer(container, fullType)
            end
        end
    end
end

local containerHasMatchingRecord

local function logCompanionCaseOutcome(record, outcome)
    local contract = type(record and record.companionCaseContract) == "table" and record.companionCaseContract or nil
    local expectedUuid = tostring(contract and contract.deviceUUID or "")
    local expectedCase = tostring(contract and contract.fullType or "")
    logProof(
        "corpse_case_spawn_at_death_outcome",
        "uuid=" .. expectedUuid .. " caseFullType=" .. expectedCase .. " outcome=" .. tostring(outcome or "neither") .. " registered=" .. tostring(record and record.spawnAtDeathCompanionRegistered == true) .. " route=" .. tostring(record and record.spawnAtDeathCompanionRoute or ""),
        true
    )
end

local function validateInheritedCompanionLoot(container, record)
    local companionContract = type(record and record.companionCaseContract) == "table" and record.companionCaseContract or nil
    if not companionContract then
        return true
    end
    local expectedUuid = tostring(companionContract.deviceUUID or "")
    local expectedCase = tostring(companionContract.fullType or "")
    local hasDevice = expectedUuid ~= "" and containerHasMatchingRecord(container, record) or false
    local hasCase = expectedCase ~= "" and containerHasManagedCompanionCase(container, expectedCase, expectedUuid) or false
    local outcome = "neither"
    if hasDevice and hasCase then
        outcome = "both"
    elseif hasCase then
        outcome = "inventory_only"
    elseif hasDevice and tostring(record.spawnAtDeathCompanionAttempted or "") ~= "" then
        outcome = "visual_only"
    end
    logCompanionCaseOutcome(record, outcome)
    if expectedUuid ~= "" and not hasDevice then
        logProof("corpse_companion_failed", "reason=missing_expected_device uuid=" .. expectedUuid, true)
        return false
    end
    if expectedCase ~= "" and not hasCase then
        logProof(
            "corpse_companion_failed",
            "reason=missing_inherited_case fullType=" .. expectedCase .. " uuid=" .. expectedUuid,
            true
        )
        return false
    end
    logProof(
        "corpse_companion_realized",
        "device=" .. tostring(record.fullType or "") .. " case=" .. expectedCase .. " mode=inherited",
        true
    )
    return true
end

local function ensureImmediateCompanionLoot(container, record)
    if not (container and record) then
        return true
    end
    local companionContract = type(record.companionCaseContract) == "table" and record.companionCaseContract or nil
    if companionContract and companionContract.mode == "device_with_media" then
        return validateInheritedCompanionLoot(container, record)
    end
    syncMediaOnlyCorpseLooseLoot(container, record)
    logProof(
        "corpse_companion_realized",
        "device=" .. tostring(record.fullType or "") .. " case=" .. tostring(companionContract and companionContract.fullType or ""),
        true
    )
    return true
end

local function removeItemFromContainer(container, item)
    local owner = container and container.getParent and container:getParent() or nil
    local removed = NMZombieAudioVisualSupport.removeInventoryItem(container, item)
    if removed and isIsoDeadBody(owner) and sendRemoveItemFromContainer then
        pcall(sendRemoveItemFromContainer, container, item)
    end
    return removed
end

local function removeMatchingRecordItems(container, record)
    local items = container and container.getItems and container:getItems() or nil
    if not (items and items.size and record) then
        return 0
    end
    local wantedUuid = tostring(record.deviceUUID or "")
    local wantedType = tostring(record.fullType or "")
    local removals = {}
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        local state = item and NMDeviceState and NMDeviceState.peek and NMDeviceState.peek(item) or nil
        local uuid = tostring(state and state.deviceUUID or "")
        if (wantedUuid ~= "" and uuid == wantedUuid) or (wantedUuid == "" and fullType == wantedType) then
            removals[#removals + 1] = item
        end
    end
    for i = 1, #removals do
        removeItemFromContainer(container, removals[i])
    end
    return #removals
end

containerHasMatchingRecord = function(container, record)
    local items = container and container.getItems and container:getItems() or nil
    if not (items and items.size) then
        return false
    end
    local wantedUuid = tostring(record and record.deviceUUID or "")
    local wantedType = tostring(record and record.fullType or "")
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        local state = item and NMDeviceState and NMDeviceState.peek and NMDeviceState.peek(item) or nil
        local uuid = tostring(state and state.deviceUUID or "")
        if wantedUuid ~= "" and uuid == wantedUuid then
            return true
        end
        if wantedUuid == "" and fullType == wantedType then
            return true
        end
    end
    return false
end

local function applyStateToCorpseItem(item, record)
    local profile = NMDeviceProfiles and NMDeviceProfiles.getForItem and NMDeviceProfiles.getForItem(item) or nil
    local state = profile and NMDeviceState and NMDeviceState.ensureInitialized and NMDeviceState.ensureInitialized(item, profile, "explicit_init") or nil
    local itemMd = item and item.getModData and item:getModData() or nil
    if not (profile and state) then
        return false, "device_state_init_failed"
    end
    if NMDeviceState and NMDeviceState.import then
        NMDeviceState.import(state, record.state or {})
    end
    if record and record.payload and NMZombieMediaPayloadRuntime and NMZombieMediaPayloadRuntime.applyPayloadToState then
        NMZombieMediaPayloadRuntime.applyPayloadToState(state, record.payload)
    end
    if NMDeviceState and NMDeviceState.setZombieDormant then
        NMDeviceState.setZombieDormant(state, false, nil, nil)
    end
    local portableTracked = NMDeviceProfiles and NMDeviceProfiles.isPortableTrackedProfile and NMDeviceProfiles.isPortableTrackedProfile(profile) == true
    state.authoritativeMode = "off"
    state.sourceKind = "inventory"
    state.sourceOwner = nil
    state.sourceX = nil
    state.sourceY = nil
    state.sourceZ = nil
    if portableTracked then
        state.sourceGeneration = 0
        state.playbackMode = tostring(profile.defaultPlaybackMode or "inventory")
    end
    state._nmCorpseRecovered = true
    if itemMd then
        itemMd.nmCorpseRecovered = true
        itemMd.nmCorpseRecoveredFullType = tostring(item and item.getFullType and item:getFullType() or record and record.fullType or "")
        itemMd.nmCorpseRecoveredDeviceUUID = tostring(state.deviceUUID or "")
    end
    state.isOn = false
    state.desiredIsOn = false
    state.isPlaying = false
    state.desiredIsPlaying = false
    state.lastStopReason = "corpse_reconcile"
    if NMDeviceState and NMDeviceState.bumpRevision then
        NMDeviceState.bumpRevision(state)
    end
    logCorpseRuntimeIdentity("rehydrated", item, profile, state, record)
    return true, tostring(state.deviceUUID or "")
end

local function findSingleProofItemByType(container, fullType)
    local items = container and container.getItems and container:getItems() or nil
    if not (items and items.size) then
        return nil
    end
    local found = nil
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local itemType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        if itemType == tostring(fullType or "") then
            if found then
                return nil
            end
            found = item
        end
    end
    return found
end

local function findMatchingRecordItem(container, record)
    local items = container and container.getItems and container:getItems() or nil
    if not (items and items.size) then
        return nil
    end
    local wantedUuid = tostring(record and record.deviceUUID or "")
    local wantedType = tostring(record and record.fullType or "")
    local typeMatch = nil
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        local state = item and NMDeviceState and NMDeviceState.peek and NMDeviceState.peek(item) or nil
        local uuid = tostring(state and state.deviceUUID or "")
        if wantedUuid ~= "" and uuid == wantedUuid then
            return item
        end
        if not typeMatch and wantedType ~= "" and fullType == wantedType then
            typeMatch = item
        end
    end
    return typeMatch
end

local function pruneExtraProofItems(container, keepItem)
    local items = container and container.getItems and container:getItems() or nil
    if not (items and items.size) then
        return 0
    end
    local removals = {}
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item ~= keepItem then
            local fullType = item.getFullType and tostring(item:getFullType() or "") or ""
            if NMZombieDeviceVariantCatalog and NMZombieDeviceVariantCatalog.findSpecByFullType and NMZombieDeviceVariantCatalog.findSpecByFullType(fullType) then
                removals[#removals + 1] = item
            end
        end
    end
    for i = 1, #removals do
        removeItemFromContainer(container, removals[i])
    end
    return #removals
end

local function enforceSingleCorpseProofItem(container, record, preferredItem)
    local keeper = preferredItem
    if not keeper then
        keeper = findMatchingRecordItem(container, record)
    end
    if not keeper and record and tostring(record.fullType or "") ~= "" then
        keeper = findSingleProofItemByType(container, record.fullType)
    end
    if not keeper then
        return 0, nil
    end
    return pruneExtraProofItems(container, keeper), keeper
end

local function applyCorpseRecord(container, record)
    if tostring(record and record.fullType or "") == "" then
        syncMediaOnlyCorpseLooseLoot(container, record)
        return true, ""
    end
    local existing = findSingleProofItemByType(container, record.fullType)
    if existing then
        local ok, detail = applyStateToCorpseItem(existing, record)
        if ok then
            pruneExtraProofItems(container, existing)
            syncMediaOnlyCorpseLooseLoot(container, record)
        end
        return ok, detail
    end
    local item = addItemToContainer(container, record.fullType)
    if not item then
        return false, "item_add_failed"
    end
    local ok, detail = applyStateToCorpseItem(item, record)
    if ok then
        pruneExtraProofItems(container, item)
        syncMediaOnlyCorpseLooseLoot(container, record)
        return true, detail
    end
    removeItemFromContainer(container, item)
    return false, detail
end

local function markCorpseSettled(body, record, deviceUUID, carried)
    local md = getModData(body)
    if not md then
        return
    end
    md.corpseSettled = true
    md.corpseHadProof = carried == true
    md.fullType = tostring(record and record.fullType or "")
    md.attachmentLocation = tostring(record and record.attachmentLocation or "")
    md.modelAttachmentName = tostring(record and record.modelAttachmentName or "")
    md.deviceUUID = tostring(deviceUUID or record and record.deviceUUID or "")
    md.strategy = tostring(record and record.strategy or "")
    local root = getRootModData(body)
    if root then
        root.nmZombieLoot = root.nmZombieLoot or {}
        root.nmZombieLoot.corpseLooseLootFullTypes = {}
        local looseLoot = type(record and record.corpseLooseLootFullTypes) == "table" and record.corpseLooseLootFullTypes or {}
        for i = 1, #looseLoot do
            root.nmZombieLoot.corpseLooseLootFullTypes[#root.nmZombieLoot.corpseLooseLootFullTypes + 1] = looseLoot[i]
        end
    end
    local settledStatus = carried == true and "attached" or "excluded"
    if record and record.payload and tostring(record.payload.mediaMode or "") == "media_only" then
        settledStatus = carried == true and "media_only" or settledStatus
    end
    md.status = settledStatus
    if record and record.payload then
        md.mediaCategory = tostring(record.payload.mediaCategory or "")
        md.deviceEnabled = record.payload.deviceEnabled == true
        md.mediaEnabled = record.payload.mediaEnabled == true
        md.mediaMode = tostring(record.payload.mediaMode or "none")
        md.mediaFullType = tostring(record.payload.insertedMediaFullType or "") ~= "" and tostring(record.payload.insertedMediaFullType) or nil
        md.mediaEjectFullType = tostring(record.payload.mediaEjectFullType or "") ~= "" and tostring(record.payload.mediaEjectFullType) or nil
        md.mediaRecordedMediaIndex = tonumber(record.payload.mediaRecordedMediaIndex) or nil
        md.caseFullType = tostring(record.payload.caseFullType or "") ~= "" and tostring(record.payload.caseFullType) or nil
        md.caseEmptyType = tostring(record.payload.caseEmptyType or "") ~= "" and tostring(record.payload.caseEmptyType) or nil
        md.headphoneItemFullType = tostring(record.payload.headphoneItemFullType or "") ~= "" and tostring(record.payload.headphoneItemFullType) or nil
        md.batteryPresent = record.payload.batteryPresent == true
        md.batteryCharge = tonumber(record.payload.batteryCharge) or 0.0
    end
    local companionContract = type(record and record.companionCaseContract) == "table" and record.companionCaseContract or nil
    md.corpseCompanionMode = companionContract and tostring(companionContract.mode or "") or nil
    md.corpseCompanionFullType = companionContract and tostring(companionContract.fullType or "") or nil
    md.corpseCompanionDeviceUUID = companionContract and tostring(companionContract.deviceUUID or "") or nil
    if NMZombieVisualTargetLedger and NMZombieVisualTargetLedger.stampCorpseSelection then
        local ledgerRecord = record and record.selection or nil
        if ledgerRecord then
            NMZombieVisualTargetLedger.stampCorpseSelection(body, ledgerRecord, carried == true)
            md = getModData(body) or md
            md.fullType = tostring(record and record.fullType or "")
            md.attachmentLocation = tostring(record and record.attachmentLocation or "")
            md.modelAttachmentName = tostring(record and record.modelAttachmentName or "")
            md.deviceUUID = tostring(deviceUUID or record and record.deviceUUID or "")
            md.strategy = tostring(record and record.strategy or "")
            md.status = settledStatus
            if record and record.payload then
                md.mediaCategory = tostring(record.payload.mediaCategory or "")
                md.deviceEnabled = record.payload.deviceEnabled == true
                md.mediaEnabled = record.payload.mediaEnabled == true
                md.mediaMode = tostring(record.payload.mediaMode or "none")
                md.mediaFullType = tostring(record.payload.insertedMediaFullType or "") ~= "" and tostring(record.payload.insertedMediaFullType) or nil
                md.mediaEjectFullType = tostring(record.payload.mediaEjectFullType or "") ~= "" and tostring(record.payload.mediaEjectFullType) or nil
                md.mediaRecordedMediaIndex = tonumber(record.payload.mediaRecordedMediaIndex) or nil
                md.caseFullType = tostring(record.payload.caseFullType or "") ~= "" and tostring(record.payload.caseFullType) or nil
                md.caseEmptyType = tostring(record.payload.caseEmptyType or "") ~= "" and tostring(record.payload.caseEmptyType) or nil
                md.headphoneItemFullType = tostring(record.payload.headphoneItemFullType or "") ~= "" and tostring(record.payload.headphoneItemFullType) or nil
                md.batteryPresent = record.payload.batteryPresent == true
                md.batteryCharge = tonumber(record.payload.batteryCharge) or 0.0
            end
            md.corpseCompanionMode = companionContract and tostring(companionContract.mode or "") or nil
            md.corpseCompanionFullType = companionContract and tostring(companionContract.fullType or "") or nil
            md.corpseCompanionDeviceUUID = companionContract and tostring(companionContract.deviceUUID or "") or nil
            return
        end
    end
    if body and body.transmitModData then
        pcall(body.transmitModData, body)
    end
end

local function getBodySelection(body)
    if not body then
        return nil
    end
    if NMZombieVisualTargetLedger and NMZombieVisualTargetLedger.getStampedSelection then
        local stamped = NMZombieVisualTargetLedger.getStampedSelection(body)
        if stamped then
            return stamped
        end
    end
    return nil
end

local function getBodyStoredPayload(body)
    local md = getModData(body)
    return NMZombieMediaPayloadResolver and NMZombieMediaPayloadResolver.resolveStoredPayload and NMZombieMediaPayloadResolver.resolveStoredPayload(md) or nil
end

local function containerHasAnyProof(container)
    local item = findAnyKnownProofItem(container)
    return item ~= nil
end

local function removeProofItemsByType(container)
    local items = container and container.getItems and container:getItems() or nil
    if not (items and items.size) then
        return 0
    end
    local removals = {}
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        if NMZombieDeviceVariantCatalog and NMZombieDeviceVariantCatalog.findSpecByFullType and NMZombieDeviceVariantCatalog.findSpecByFullType(fullType) then
            removals[#removals + 1] = item
        end
    end
    for i = 1, #removals do
        removeItemFromContainer(container, removals[i])
    end
    return #removals
end

local function findBestPendingForBody(body)
    local square = getEntitySquare(body)
    if not square then
        return nil, nil
    end
    local bodyX = body and body.getX and tonumber(body:getX()) or square:getX() + 0.5
    local bodyY = body and body.getY and tonumber(body:getY()) or square:getY() + 0.5
    local squareX = square:getX()
    local squareY = square:getY()
    local squareZ = square:getZ()
    local bestKey = nil
    local bestIndex = nil
    local bestDistance = nil

    for dx = -1, 1 do
        for dy = -1, 1 do
            local key = getSquareKey(squareX + dx, squareY + dy, squareZ)
            local queue = NMServerZombieCorpseCarry._pendingBySquare and NMServerZombieCorpseCarry._pendingBySquare[key] or nil
            if type(queue) == "table" then
                for i = 1, #queue do
                    local pending = queue[i]
                    if pending then
                        local ddx = (tonumber(pending.sourceX) or 0) - bodyX
                        local ddy = (tonumber(pending.sourceY) or 0) - bodyY
                        local distance = (ddx * ddx) + (ddy * ddy)
                        if bestDistance == nil or distance < bestDistance then
                            bestKey = key
                            bestIndex = i
                            bestDistance = distance
                        end
                    end
                end
            end
        end
    end

    if not bestKey or not bestIndex then
        return nil, nil
    end
    local queue = NMServerZombieCorpseCarry._pendingBySquare[bestKey]
    return queue and queue[bestIndex] or nil, { key = bestKey, index = bestIndex }
end

local function removePending(handle)
    if not handle then
        return
    end
    local queue = NMServerZombieCorpseCarry._pendingBySquare and NMServerZombieCorpseCarry._pendingBySquare[handle.key] or nil
    if type(queue) ~= "table" then
        return
    end
    table.remove(queue, handle.index)
    if #queue == 0 then
        NMServerZombieCorpseCarry._pendingBySquare[handle.key] = nil
    end
end

local function processCorpseBody(body)
    if not canRunAuthoritativeMutation() then
        return false
    end
    if not isIsoDeadBody(body) then
        return false
    end
    logCorpseSpawnPath("corpse_spawn_enter", body, "enter")
    local container = body.getContainer and body:getContainer() or nil
    if not container then
        logCorpseSpawnPath("corpse_spawn_skip", body, "missing_container")
        NMServerZombieCorpseCarry._diag.corpseSpawnSkip = (NMServerZombieCorpseCarry._diag.corpseSpawnSkip or 0) + 1
        return false
    end

    local md = getModData(body)
    if md and md.corpseSettled == true then
        logCorpseSpawnPath("corpse_spawn_skip", body, "already_settled")
        NMServerZombieCorpseCarry._diag.corpseSpawnSkip = (NMServerZombieCorpseCarry._diag.corpseSpawnSkip or 0) + 1
        return false
    end

    local pending, handle = findBestPendingForBody(body)
    if not pending then
        logCorpseSpawnPath("corpse_spawn_no_pending", body, "no_pending_match")
        local bodySelection = getBodySelection(body)
        local bodySpec = getSpecForVariantId(bodySelection and bodySelection.variantId or "")
        local _, bodyProofSpec = findAnyKnownProofItem(container)
        if bodySelection and (bodySelection.selected == true or bodySelection.musicSelected == true) and containerHasAnyProof(container) then
            local bodyRecord = {
                fullType = tostring(bodyProofSpec and bodyProofSpec.fullType or bodySpec and bodySpec.fullType or ""),
                attachmentLocation = tostring(bodyProofSpec and bodyProofSpec.attachmentLocation or bodySpec and bodySpec.attachmentLocation or ""),
                modelAttachmentName = tostring(bodyProofSpec and bodyProofSpec.modelAttachmentName or bodySpec and bodySpec.modelAttachmentName or ""),
                deviceUUID = "",
                strategy = tostring(bodySelection.strategy or ""),
                selection = bodySelection,
                payload = getBodyStoredPayload(body),
                companionCaseContract = getCompanionCaseContract(body),
                spawnAtDeathCompanionAttempted = tostring(md and md.spawnAtDeathCompanionCaseDeviceUUID or ""),
                spawnAtDeathCompanionRegistered = md and md.spawnAtDeathCompanionRegistered == true or false,
                spawnAtDeathCompanionRoute = tostring(md and md.spawnAtDeathCompanionCreateRoute or ""),
                corpseLooseLootFullTypes = getCorpseLooseLootFullTypes(body)
            }
            logCorpseLooseLoot("corpse_spawn_existing", body, bodyRecord)
            ensureImmediateCompanionLoot(container, bodyRecord)
            markCorpseSettled(body, bodyRecord, nil, true)
            NMServerZombieCorpseCarry._diag.corpseAlreadyPresent = (NMServerZombieCorpseCarry._diag.corpseAlreadyPresent or 0) + 1
            return true
        end
        if bodySelection and bodySelection.selected ~= true and bodySelection.musicSelected ~= true and containerHasAnyProof(container) then
            logCorpseSpawnPath("corpse_spawn_prune", body, "selection_not_selected_but_has_proof")
            local pruned = removeProofItemsByType(container)
            if pruned > 0 then
                NMServerZombieCorpseCarry._diag.corpsePruned = (NMServerZombieCorpseCarry._diag.corpsePruned or 0) + pruned
            end
            markCorpseSettled(body, {
                fullType = tostring(bodySpec and bodySpec.fullType or ""),
                attachmentLocation = tostring(bodySpec and bodySpec.attachmentLocation or ""),
                modelAttachmentName = tostring(bodySpec and bodySpec.modelAttachmentName or ""),
                deviceUUID = "",
                strategy = tostring(bodySelection.strategy or ""),
                selection = bodySelection
            }, nil, false)
            return true
        end
        logCorpseSpawnPath("corpse_spawn_skip", body, "no_pending_no_existing_path")
        NMServerZombieCorpseCarry._diag.corpseSpawnSkip = (NMServerZombieCorpseCarry._diag.corpseSpawnSkip or 0) + 1
        return false
    end

    logCorpseSpawnPath("corpse_spawn_match", body, "pending_match")
    if pending.shouldCarry ~= true then
        logCorpseSpawnPath("corpse_spawn_reject", body, "pending_shouldCarry_false")
        local pruned = removeMatchingRecordItems(container, pending.record)
        if pruned > 0 then
            NMServerZombieCorpseCarry._diag.corpsePruned = (NMServerZombieCorpseCarry._diag.corpsePruned or 0) + pruned
        end
        markCorpseSettled(body, pending.record, nil, false)
        removePending(handle)
        return true
    end

    logCorpseLooseLoot("corpse_spawn_pending", body, pending.record)
    if containerHasMatchingRecord(container, pending.record) then
        logCorpseSpawnPath("corpse_spawn_match_existing", body, "container_already_has_record")
        local existing = findMatchingRecordItem(container, pending.record)
        if existing then
            local ok, detail = applyStateToCorpseItem(existing, pending.record)
            if not ok then
                logCorpseSpawnPath("corpse_spawn_match_existing_reconcile_failed", body, tostring(detail or "unknown"))
                NMServerZombieCorpseCarry._diag.corpseCarryFailed = (NMServerZombieCorpseCarry._diag.corpseCarryFailed or 0) + 1
                logProof("corpse_carry_failed", "reason=" .. tostring(detail or "existing_reconcile_failed"), true)
                return false
            end
            pending.record.deviceUUID = tostring(detail or pending.record.deviceUUID or "")
            local pruned = enforceSingleCorpseProofItem(container, pending.record, existing)
            if tonumber(pruned) and pruned > 0 then
                NMServerZombieCorpseCarry._diag.corpsePruned = (NMServerZombieCorpseCarry._diag.corpsePruned or 0) + pruned
            end
        else
            logCorpseSpawnPath("corpse_spawn_match_existing_missing_item", body, "match_detected_but_item_not_found")
        end
        ensureImmediateCompanionLoot(container, pending.record)
        markCorpseSettled(body, pending.record, pending.record.deviceUUID, true)
        NMServerZombieCorpseCarry._diag.corpseAlreadyPresent = (NMServerZombieCorpseCarry._diag.corpseAlreadyPresent or 0) + 1
        removePending(handle)
        return true
    end

    local ok, detail = applyCorpseRecord(container, pending.record)
    if ok then
        local keeper = findMatchingRecordItem(container, pending.record)
        local pruned = enforceSingleCorpseProofItem(container, pending.record, keeper)
        if tonumber(pruned) and pruned > 0 then
            NMServerZombieCorpseCarry._diag.corpsePruned = (NMServerZombieCorpseCarry._diag.corpsePruned or 0) + pruned
        end
        ensureImmediateCompanionLoot(container, pending.record)
        logCorpseSpawnPath("corpse_spawn_apply_ok", body, tostring(detail or "ok"))
        markCorpseSettled(body, pending.record, detail, true)
        NMServerZombieCorpseCarry._diag.corpseCarrySuccess = (NMServerZombieCorpseCarry._diag.corpseCarrySuccess or 0) + 1
        removePending(handle)
        return true
    end

    logCorpseSpawnPath("corpse_spawn_apply_failed", body, tostring(detail or "unknown"))
    NMServerZombieCorpseCarry._diag.corpseCarryFailed = (NMServerZombieCorpseCarry._diag.corpseCarryFailed or 0) + 1
    logProof("corpse_carry_failed", "reason=" .. tostring(detail or "unknown"), true)
    return false
end

function NMServerZombieCorpseCarry.onZombieDead(zombie)
    if not canRunAuthoritativeMutation() then
        return
    end
    if not isIsoZombie(zombie) then
        return
    end
    local square = getEntitySquare(zombie)
    local record = findAttachedProofRecord(zombie)
    if not (square and record) then
        NMServerZombieCorpseCarry._diag.corpseCaptureSkip = (NMServerZombieCorpseCarry._diag.corpseCaptureSkip or 0) + 1
        return
    end
    logLiveCaptureProbe(zombie, record)
    logCorpseLooseLoot("corpse_capture", zombie, record)
    NMServerZombieCorpseCarry._pendingBySquare = NMServerZombieCorpseCarry._pendingBySquare or {}
    local key = getSquareKey(square:getX(), square:getY(), square:getZ())
    local queue = NMServerZombieCorpseCarry._pendingBySquare[key]
    if type(queue) ~= "table" then
        queue = {}
        NMServerZombieCorpseCarry._pendingBySquare[key] = queue
    end
    queue[#queue + 1] = {
        record = record,
        selection = NMZombieVisualTargetLedger and NMZombieVisualTargetLedger.getOrAssignZombieSelection and NMZombieVisualTargetLedger.getOrAssignZombieSelection(zombie, tostring(record and record.strategy or "")) or nil,
        sourceX = zombie and zombie.getX and tonumber(zombie:getX()) or square:getX() + 0.5,
        sourceY = zombie and zombie.getY and tonumber(zombie:getY()) or square:getY() + 0.5,
        sourceZ = zombie and zombie.getZ and tonumber(zombie:getZ()) or square:getZ()
    }
    NMServerZombieCorpseCarry._diag.corpseCaptureQueued = (NMServerZombieCorpseCarry._diag.corpseCaptureQueued or 0) + 1
    queue[#queue].record.selection = queue[#queue].selection
    queue[#queue].shouldCarry = shouldCarryCorpseProof(zombie, record, queue[#queue].selection) == true
    if queue[#queue].shouldCarry ~= true then
        NMServerZombieCorpseCarry._diag.corpseCaptureRejected = (NMServerZombieCorpseCarry._diag.corpseCaptureRejected or 0) + 1
    end
    if tostring(record and record.strategy or "") == "sp_runtime_attach" then
        NMServerZombieCorpseCarry._diag.corpseCaptureSPRuntime = (NMServerZombieCorpseCarry._diag.corpseCaptureSPRuntime or 0) + 1
    elseif tostring(record and record.strategy or "") == "mp_runtime_attach_with_support" then
        NMServerZombieCorpseCarry._diag.corpseCaptureMPRuntimeSupport = (NMServerZombieCorpseCarry._diag.corpseCaptureMPRuntimeSupport or 0) + 1
    elseif tostring(record and record.strategy or "") == "mp_assignment_flow"
        or tostring(record and record.strategy or "") == "mp_legacy_assignment_flow" then
        NMServerZombieCorpseCarry._diag.corpseCaptureMPAssignment = (NMServerZombieCorpseCarry._diag.corpseCaptureMPAssignment or 0) + 1
    end
    if ((NMServerZombieCorpseCarry._diag.corpseCaptureQueued or 0) % 10) == 0 then
        logCorpseSummary("corpse_capture_summary")
    end
end

function NMServerZombieCorpseCarry.onDeadBodySpawn(body)
    processCorpseBody(body)
end

local function reconcilePendingCorpseSquares()
    local pendingBySquare = NMServerZombieCorpseCarry._pendingBySquare or nil
    if type(pendingBySquare) ~= "table" then
        return 0
    end
    local cell = getCell and getCell() or nil
    if not cell then
        return 0
    end
    local reconciled = 0
    for key, queue in pairs(pendingBySquare) do
        if type(queue) == "table" and #queue > 0 then
            local x, y, z = parseSquareKey(key)
            if x and y and z then
                for dx = -1, 1 do
                    for dy = -1, 1 do
                        local square = cell:getGridSquare(x + dx, y + dy, z)
                        local bodies = square and square.getStaticMovingObjects and square:getStaticMovingObjects() or nil
                        if bodies and bodies.size then
                            for i = 0, bodies:size() - 1 do
                                local body = bodies:get(i)
                                if isIsoDeadBody(body) and processCorpseBody(body) then
                                    reconciled = reconciled + 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return reconciled
end

function NMServerZombieCorpseCarry.onTick()
    NMServerZombieCorpseCarry._tickCounter = (tonumber(NMServerZombieCorpseCarry._tickCounter) or 0) + 1
    if (NMServerZombieCorpseCarry._tickCounter % TICK_RECONCILE_INTERVAL) ~= 0 then
        return
    end
    local reconciled = reconcilePendingCorpseSquares()
    if reconciled > 0 then
        NMServerZombieCorpseCarry._diag.corpseTickReconciled = (NMServerZombieCorpseCarry._diag.corpseTickReconciled or 0) + reconciled
        logProof("corpse_tick_reconcile", "reconciled=" .. tostring(reconciled), true)
    end
end

return NMServerZombieCorpseCarry
