NMPortableMediaInteraction = NMPortableMediaInteraction or {}

local interaction = NMPortableMediaInteraction

local function probeEnabled()
    return NMCore and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("portableUiProbe") == true
end

local function logProbe(tag, detail)
    if not (probeEnabled() and NMCore and NMCore.logChannel) then
        return
    end
    NMCore.logChannel("portableUiProbe", tostring(tag or "portable_ui"), tostring(detail or ""))
end

local function getMousePoint()
    return getMouseX and getMouseX() or 0, getMouseY and getMouseY() or 0
end

local function resolveWindowFamily(window)
    if window and window.getLidRect and window.syncLidFromMedia then
        return "walkman"
    end
    return "generic"
end

local function resolvePlayerNum(window)
    local resolved = window and window.resolveContext and window:resolveContext() or nil
    local player = resolved and resolved.player or nil
    return player and player.getPlayerNum and player:getPlayerNum() or window and window.playerNum or 0
end

local function resolveZoneDescriptor(window, zoneKind, dragItems)
    return {
        uiFamily = resolveWindowFamily(window),
        zoneKind = tostring(zoneKind or "slot"),
        itemId = window and window.target and window.target.itemId or nil,
        uuid = window and window.target and window.target.uuid or nil,
        dragItems = dragItems
    }
end

local function winnerSummary(zone)
    if not zone then
        return "none"
    end
    return string.format(
        "%s:%s:item=%s:uuid=%s",
        tostring(zone.uiFamily or "unknown"),
        tostring(zone.zoneKind or "slot"),
        tostring(zone.itemId or ""),
        tostring(zone.uuid or "")
    )
end

function interaction.finalizePendingExtract()
    local sourceWindow = NMMediaSlot and NMMediaSlot._ghostDragWindow or nil
    local mediaEnv = rawget(_G, "NMMediaSlotEnv") or nil
    local completeFn = mediaEnv and mediaEnv.completeMediaExtractDrag or nil
    if not (sourceWindow and completeFn) then
        return false
    end
    local slotButton = sourceWindow.mediaSlot and sourceWindow.mediaSlot.button or nil
    local ok = completeFn(sourceWindow, slotButton) == true
    logProbe(
        "portable_media_finalize_extract",
        string.format(
            "sourceUi=%s sourceItemId=%s sourceUuid=%s ok=%s",
            tostring(resolveWindowFamily(sourceWindow)),
            tostring(sourceWindow and sourceWindow.target and sourceWindow.target.itemId or ""),
            tostring(sourceWindow and sourceWindow.target and sourceWindow.target.uuid or ""),
            tostring(ok)
        )
    )
    return ok
end

function interaction.handleMediaSlotMouseDown(window, zoneKind)
    if not (window and NMPortableMediaDropArbiter and NMPortableMediaDropArbiter.resolveOwningZone) then
        return true
    end
    local items = nil
    local ok = false
    if NMSlotActionCommon and NMSlotActionCommon.getDraggedInventoryItems then
        items, ok = NMSlotActionCommon.getDraggedInventoryItems()
    end
    if type(items) == "table" and #items > 0 then
        return true
    end
    local descriptor = resolveZoneDescriptor(window, zoneKind, nil)
    local mx, my = getMousePoint()
    local playerNum = resolvePlayerNum(window)
    local winner = NMPortableMediaDropArbiter.resolveOwningZone(playerNum, descriptor.zoneKind, mx, my)
    local executed = winner and winner.performBeginExtract and winner.performBeginExtract("arbiter") == true or false
    logProbe(
        "portable_media_interaction",
        string.format(
            "kind=begin_extract triggerUi=%s zone=%s winner=%s executed=%s mouse=%s,%s",
            tostring(descriptor.uiFamily),
            tostring(descriptor.zoneKind),
            winnerSummary(winner),
            tostring(executed),
            tostring(mx),
            tostring(my)
        )
    )
    return true
end

function interaction.handleMediaSlotMouseUp(window, zoneKind)
    if interaction.finalizePendingExtract() == true then
        return true
    end
    local items = nil
    local ok = false
    if NMSlotActionCommon and NMSlotActionCommon.getDraggedInventoryItems then
        items, ok = NMSlotActionCommon.getDraggedInventoryItems()
    end
    if ok ~= true or type(items) ~= "table" or #items <= 0 then
        return true
    end
    local descriptor = resolveZoneDescriptor(window, zoneKind, items)
    local mx, my = getMousePoint()
    local playerNum = resolvePlayerNum(window)
    local winner = NMPortableMediaDropArbiter and NMPortableMediaDropArbiter.resolveWinningZone
        and NMPortableMediaDropArbiter.resolveWinningZone(playerNum, items, mx, my)
        or nil
    local executed = winner and winner.performInsertFromDrag and winner.performInsertFromDrag(items, descriptor.uiFamily) == true or false
    logProbe(
        "portable_media_interaction",
        string.format(
            "kind=insert_drag triggerUi=%s zone=%s winner=%s executed=%s mouse=%s,%s",
            tostring(descriptor.uiFamily),
            tostring(descriptor.zoneKind),
            winnerSummary(winner),
            tostring(executed),
            tostring(mx),
            tostring(my)
        )
    )
    if executed ~= true and NMSlotActionCommon and NMSlotActionCommon.clearMouseDragState then
        NMSlotActionCommon.clearMouseDragState()
    end
    return true
end

function interaction.handleMediaSlotRightClick(window, zoneKind, btn, xArg, yArg)
    if not (window and NMPortableMediaDropArbiter and NMPortableMediaDropArbiter.resolveOwningZone) then
        return true
    end
    local descriptor = resolveZoneDescriptor(window, zoneKind, nil)
    local mx, my = getMousePoint()
    local playerNum = resolvePlayerNum(window)
    local winner = NMPortableMediaDropArbiter.resolveOwningZone(playerNum, descriptor.zoneKind, mx, my)
    local executed = false
    if winner then
        if winner.canEjectMedia and winner.canEjectMedia() == true and winner.performEject then
            executed = winner.performEject("arbiter") == true
        elseif winner.performShowInsertContext then
            executed = winner.performShowInsertContext(btn, xArg, yArg, "arbiter") == true
        end
    end
    logProbe(
        "portable_media_interaction",
        string.format(
            "kind=right_click triggerUi=%s zone=%s winner=%s executed=%s mouse=%s,%s",
            tostring(descriptor.uiFamily),
            tostring(descriptor.zoneKind),
            winnerSummary(winner),
            tostring(executed),
            tostring(mx),
            tostring(my)
        )
    )
    return true
end

return interaction
