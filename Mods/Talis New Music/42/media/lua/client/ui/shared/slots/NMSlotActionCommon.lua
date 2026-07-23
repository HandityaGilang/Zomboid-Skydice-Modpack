NMSlotActionCommon = NMSlotActionCommon or {}

local SLOT_TRACE_SEQ = 0

function NMSlotActionCommon.playSlotUISound(window, soundName, volume)
    local name = tostring(soundName or "")
    if name == "" then return end
    local vol = tonumber(volume) or 0.8
    local isWalkmanWindow = window and window.getLidRect ~= nil and window.syncLidFromMedia ~= nil
    local sm = getSoundManager and getSoundManager() or nil
    if isWalkmanWindow then
        if sm and sm.playUISound then
            pcall(sm.playUISound, sm, name)
        end
        return
    end
    local resolved = window and window.resolveContext and window:resolveContext() or nil
    local playerObj = resolved and resolved.player or nil
    local function isValidSoundId(soundId)
        if soundId == nil then return false end
        local n = tonumber(soundId)
        if n and n == 0 then return false end
        return true
    end
    if playerObj and playerObj.getEmitter then
        local okEmitter, emitter = pcall(playerObj.getEmitter, playerObj)
        if okEmitter and emitter then
            local okPlay, soundId = false, nil
            if emitter.playSoundImpl then
                okPlay, soundId = pcall(emitter.playSoundImpl, emitter, name, nil)
            end
            if (not okPlay or not isValidSoundId(soundId)) and emitter.playSound then
                okPlay, soundId = pcall(emitter.playSound, emitter, name)
            end
            if okPlay and isValidSoundId(soundId) then
                if emitter.setVolume then
                    pcall(emitter.setVolume, emitter, soundId, vol)
                end
                return
            end
        end
    end
    if playerObj and playerObj.playSoundLocal then
        local ok = pcall(playerObj.playSoundLocal, playerObj, name)
        if ok then return end
    end
    if sm and sm.playUISound then
        pcall(sm.playUISound, sm, name)
    end
end

function NMSlotActionCommon.safeDraggedPayload()
    if not ISMouseDrag then return nil, false end
    local dragging = ISMouseDrag.dragging
    if dragging == nil then return {}, true end
    if type(dragging) ~= "table" then return nil, false end
    return dragging, true
end

function NMSlotActionCommon.getDraggedInventoryItems()
    local dragging, resolved = NMSlotActionCommon.safeDraggedPayload()
    if not resolved then return nil, false end
    if not dragging or #dragging <= 0 then return {}, true end
    if not (ISInventoryPane and ISInventoryPane.getActualItems) then
        return nil, false
    end
    local ok, actual = pcall(ISInventoryPane.getActualItems, dragging)
    if not ok or type(actual) ~= "table" then
        return nil, false
    end
    local out = {}
    for i = 1, #actual do
        local item = actual[i]
        if item and item.getFullType then
            out[#out + 1] = item
        end
    end
    return out, true
end

function NMSlotActionCommon.clearMouseDragState()
    if not ISMouseDrag then return end
    ISMouseDrag.dragging = nil
    ISMouseDrag.draggingFocus = nil
end

function NMSlotActionCommon.nextSlotTraceId()
    SLOT_TRACE_SEQ = SLOT_TRACE_SEQ + 1
    return tostring(SLOT_TRACE_SEQ)
end

function NMSlotActionCommon.canQueueSlotAction(window)
    if not window then return false end
    local resolved = window.resolveContext and window:resolveContext() or nil
    local player = resolved and resolved.player or nil
    local item = resolved and resolved.item or nil
    local vehicle = resolved and resolved.vehicle or nil
    local part = resolved and resolved.part or nil
    if not player then return false end
    if vehicle and part then
        return true
    end
    if not item then return false end
    local location = NMDeviceUIRange and NMDeviceUIRange.resolvePortableTargetLocation
        and NMDeviceUIRange.resolvePortableTargetLocation(window and window.target or nil, item) or nil
    if location and location.mode == "inventory" then
        return true
    end
    if location and location.mode == "placed_world" then
        return NMDeviceUIRange and NMDeviceUIRange.isPlayerWithinSquare and NMDeviceUIRange.isPlayerWithinSquare(player, location.square) or true
    end
    if location and location.mode == "detached_placed" and player.DistToSquared then
        local distSq = tonumber(player:DistToSquared(location.x, location.y)) or 999999
        local thresholdSq = NMDeviceUIRange and NMDeviceUIRange.getWorldInteractionRangeSq and NMDeviceUIRange.getWorldInteractionRangeSq() or (2.8 * 2.8)
        return distSq <= thresholdSq
    end
    return false
end

return NMSlotActionCommon
