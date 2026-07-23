local env = _G.NMBatterySlotEnv
setfenv(1, env)

function queueBatterySlotAction(window, actionName, args)
    if not window then return false end
    if window._nmSlotRangeGateEnabled ~= false and not canQueueSlotAction(window) then
        return false
    end
    local payload = args or {}
    if payload.slotTraceId == nil then
        payload.slotTraceId = nextSlotTraceId()
    end
    local resolved = window.resolveContext and window:resolveContext() or nil
    local playerObj = resolved and resolved.player or nil
    if not (playerObj and ISTimedActionQueue and NMBatterySlotTimedAction) then
        return window:dispatch(actionName, payload)
    end
    ISTimedActionQueue.add(NMBatterySlotTimedAction:new(playerObj, window, actionName, payload))
    return true
end

function getContextMenuPoint(button, x, y)
    local bx = button and button.getAbsoluteX and button:getAbsoluteX() or (getMouseX and getMouseX() or 0)
    local by = button and button.getAbsoluteY and button:getAbsoluteY() or (getMouseY and getMouseY() or 0)
    return bx + (tonumber(x) or 0), by + (tonumber(y) or 0)
end

function isCompatibleBatteryDrag(items)
    if type(items) ~= "table" or #items <= 0 then return false end
    for i = 1, #items do
        local item = items[i]
        local ft = item and item.getFullType and tostring(item:getFullType() or "") or ""
        if ft == BATTERY_FULL_TYPE then return true end
    end
    return false
end

function pickFirstBattery(items)
    if type(items) ~= "table" then return nil end
    for i = 1, #items do
        local item = items[i]
        local ft = item and item.getFullType and tostring(item:getFullType() or "") or ""
        if ft == BATTERY_FULL_TYPE then return item end
    end
    return nil
end

function normalizeBatteryIngressItem(window, item)
    local resolved = window and window.resolveContext and window:resolveContext() or nil
    local player = resolved and resolved.player or nil
    local itemId = item and NMCore and NMCore.itemId and NMCore.itemId(item) or nil
    local uuid = item and NMInventoryHelpers and NMInventoryHelpers.getItemStateUuid and NMInventoryHelpers.getItemStateUuid(item) or nil
    if not (player and itemId and NMInventoryHelpers and NMInventoryHelpers.normalizeItemToMainInventory) then
        return nil, "normalize_helper_missing"
    end
    return NMInventoryHelpers.normalizeItemToMainInventory(player, itemId, uuid)
end

function isMouseOverButton(button)
    if not button then return false end
    local mx = getMouseX and getMouseX() or 0
    local my = getMouseY and getMouseY() or 0
    local ax = button.getAbsoluteX and button:getAbsoluteX() or 0
    local ay = button.getAbsoluteY and button:getAbsoluteY() or 0
    local bw = tonumber(button.width) or 0
    local bh = tonumber(button.height) or 0
    if bw <= 0 or bh <= 0 then return false end
    return mx >= ax and mx < (ax + bw) and my >= ay and my < (ay + bh)
end

function readBatteryChargeFraction(item)
    if not item then return 1.0 end
    return NMCore.clamp(tonumber(NMCore.readDrainableFraction and NMCore.readDrainableFraction(item, 1.0) or 1.0) or 1.0, 0.0, 1.0)
end

function batteryChargePercentText(chargeFraction)
    local pct = math.floor((NMCore.clamp(tonumber(chargeFraction) or 0.0, 0.0, 1.0) * 100) + 0.5)
    if pct < 0 then pct = 0 end
    if pct > 100 then pct = 100 end

    local formatText = NMTranslations.ui("BatteryRemainingFmt", "Battery: %d%% Remaining")
    local ok, rendered = pcall(string.format, formatText, tonumber(pct) or 0)
    if ok and rendered ~= nil then
        return tostring(rendered)
    end
    return string.format("Battery: %d%% Remaining", tonumber(pct) or 0)
end

function collectEligibleBatteryItems(player)
    local inv = player and player.getInventory and player:getInventory() or nil
    if not inv then return {} end
    local all = {}
    NMInventoryHelpers.collectItemsRecursive(inv, all)
    local out = {}
    for i = 1, #all do
        local item = all[i]
        local ft = item and item.getFullType and tostring(item:getFullType() or "") or ""
        if ft == BATTERY_FULL_TYPE then
            out[#out + 1] = item
        end
    end
    table.sort(out, function(a, b)
        return readBatteryChargeFraction(a) > readBatteryChargeFraction(b)
    end)
    return out
end

function slotMenuItemLabel(item)
    return batteryChargePercentText(readBatteryChargeFraction(item))
end

function openEmptySlotContextMenu(window, button, x, y)
    if not ISContextMenu then return false end
    local resolved = window and window.resolveContext and window:resolveContext() or nil
    local player = resolved and resolved.player or nil
    local playerNum = player and player.getPlayerNum and tonumber(player:getPlayerNum()) or 0
    local cx, cy = getContextMenuPoint(button, x, y)
    local context = ISContextMenu.get(playerNum or 0, cx, cy)
    if not context then return false end

    local actionOption = context:addOption(NMTranslations.ui("InsertBattery", "Insert Battery"), nil, nil)
    if NMUIRenderProbe and NMUIRenderProbe.count then
        NMUIRenderProbe.count(window, "slot.candidate_scan", 1)
    end
    local items = collectEligibleBatteryItems(player)
    if #items <= 0 then
        actionOption.notAvailable = true
        return true
    end

    local sub = context:getNew(context)
    context:addSubMenu(actionOption, sub)
    for i = 1, #items do
        local item = items[i]
        local option = sub:addOption(slotMenuItemLabel(item), window, function(targetWin, targetItem)
            local liveItem = normalizeBatteryIngressItem(targetWin, targetItem)
            if not liveItem then
                targetWin._nmPendingBatterySlotFullType = nil
                return
            end
            targetWin._nmPendingBatterySlotFullType = BATTERY_FULL_TYPE
            if queueBatterySlotAction(targetWin, "insert_battery", { batteryItemId = NMCore.itemId(liveItem) }) ~= true then
                targetWin._nmPendingBatterySlotFullType = nil
            end
        end, item)
        option.itemForTexture = item
    end
    return true
end

function drawEmptyBatteryVector(button)
    local icon = NMBatterySlotVectors.icons and NMBatterySlotVectors.icons.battery or nil
    local bounds = NMBatterySlotVectors.bounds and NMBatterySlotVectors.bounds.battery or nil
    if not (icon and bounds) then return end
    if EMPTY_BATTERY_VECTOR_SHAPES == nil then
        EMPTY_BATTERY_VECTOR_SHAPES = {}
        for i = 1, #icon do
            EMPTY_BATTERY_VECTOR_SHAPES[i] = NMVectorDraw.prepareShape(icon[i], NMBatterySlotVectors.viewBox, bounds) or false
        end
    end
    local w = tonumber(button.width) or 0
    local h = tonumber(button.height) or 0
    local size = math.max(10, math.floor(math.min(w, h) * EMPTY_BATTERY_ICON_SCALE + 0.5))
    local left = math.floor((w - size) * 0.5 + 0.5)
    local top = math.floor((h - size) * 0.5 + 0.5)
    for i = 1, #EMPTY_BATTERY_VECTOR_SHAPES do
        local prepared = EMPTY_BATTERY_VECTOR_SHAPES[i]
        if prepared and prepared ~= false then
            NMVectorDraw.drawPreparedShape(button, prepared, EMPTY_SLOT_VECTOR_COLOR, left, top, size, size)
        end
    end
end

function drawEmptyBatteryTexture(button)
    if not EMPTY_BATTERY_PLACEHOLDER_TEXTURE then
        EMPTY_BATTERY_PLACEHOLDER_TEXTURE = getTexture and (
            getTexture("media/textures/UI/UI_NM_SlotEmpty_Battery.png")
            or getTexture("UI/UI_NM_SlotEmpty_Battery")
            or getTexture("UI_NM_SlotEmpty_Battery")
        ) or nil
    end
    local tex = EMPTY_BATTERY_PLACEHOLDER_TEXTURE
    if not tex then return false end
    local texW = tex.getWidthOrig and tex:getWidthOrig() or (tex.getWidth and tex:getWidth()) or 32
    local texH = tex.getHeightOrig and tex:getHeightOrig() or (tex.getHeight and tex:getHeight()) or 32
    local maxW = (tonumber(button.width) or 0) - 8
    local maxH = (tonumber(button.height) or 0) - 8
    local scale = math.min(maxW / texW, maxH / texH)
    if scale > 1 then scale = 1 end
    local drawW = texW * scale
    local drawH = texH * scale
    local left = (button.width - drawW) / 2
    local top = (button.height - drawH) / 2
    button:drawTextureScaled(tex, left, top, drawW, drawH, 0.55, 0.12, 0.12, 0.12)
    return true
end

function drawBatteryTexture(button)
    if not BATTERY_TEXTURE then
        BATTERY_TEXTURE = getTexture and (getTexture("Item_Battery") or getTexture("media/textures/Item_Battery.png")) or nil
    end
    local tex = BATTERY_TEXTURE
    if not tex then return end
    local w = tonumber(button.width) or 0
    local h = tonumber(button.height) or 0
    -- Match TVM slot item icon sizing lane.
    local size = math.max(10, math.min(32, math.min(w, h) - 6))
    local left = math.floor((w - size) * 0.5 + 0.5)
    local top = math.floor((h - size) * 0.5 + 0.5)
    button:drawTextureScaledAspect(tex, left, top, size, size, 1.0, 1.0, 1.0, 1.0)
end

function resolveBatterySlotFullType(window, state)
    local authoritative = (state and state.batteryPresent == true) and BATTERY_FULL_TYPE or ""
    local pending = window and window._nmPendingBatterySlotFullType or nil
    local timed = window and window._nmBatterySlotTimedProgress or nil
    local timedActive = timed and timed.active == true
    local timedAction = timedActive and tostring(timed.action or "") or ""
    if timedActive and timedAction == "eject_battery" and tostring(pending or "") ~= "" then
        return tostring(pending or "")
    end
    if timedActive ~= true and pending ~= nil and tostring(pending or "") == authoritative then
        window._nmPendingBatterySlotFullType = nil
        if window._nmSlotRemoveInFlightByType then
            window._nmSlotRemoveInFlightByType.battery = nil
        end
    end
    return authoritative
end

function resolveSlotStyle(window, button, resolved)
    local state = resolved and resolved.state or nil
    local fullType = resolveBatterySlotFullType(window, state)
    local mouseOver = isMouseOverButton(button)
    if fullType == "" and timed == nil and not mouseOver then
        return "slot"
    end
    if mouseOver then
        if NMUIRenderProbe and NMUIRenderProbe.count then
            NMUIRenderProbe.count(window, "slot.drag_check", 1)
        end
        local items, ok = getDraggedInventoryItems()
        if ok and type(items) == "table" and #items > 0 and isCompatibleBatteryDrag(items) then
            return "slot_drag"
        end
    end
    if fullType ~= "" then
        return "slot_filled"
    end
    if mouseOver then
        return "slot_hover"
    end
    return "slot"
end

function resolveBatteryTint(fullType)
    return { r = 1.0, g = 1.0, b = 1.0 }
end

function NMBatterySlot.buildRenderState(window, frame)
    local resolved = frame and frame.resolved or (window and window.resolveContextCached and window:resolveContextCached()) or nil
    local state = resolved and resolved.state or nil
    local button = window and window.batterySlot and window.batterySlot.button or nil
    local fullType = resolveBatterySlotFullType(window, state)
    local mouseOver = isMouseOverButton(button)
    local styleKey = "slot"
    if fullType == "" and mouseOver and frame and frame.dragOk and type(frame.dragItems) == "table" and #frame.dragItems > 0
        and isCompatibleBatteryDrag(frame.dragItems) then
        styleKey = "slot_drag"
    elseif fullType ~= "" then
        styleKey = "slot_filled"
    elseif mouseOver then
        styleKey = "slot_hover"
    end
    local timed = window and window._nmBatterySlotTimedProgress or nil
    local fillPct = nil
    if timed and timed.active == true and timed.delta then
        fillPct = NMCore.clamp(tonumber(timed.delta) or 0.0, 0.0, 1.0)
    end
    local tooltip = NMTranslations.ui("InsertBattery", "Insert Battery")
    local batteryPct = NMCore.clamp(tonumber(state and state.batteryCharge or 0.0) or 0.0, 0.0, 1.0)
    if fullType ~= "" then
        tooltip = batteryChargePercentText(batteryPct)
    end
    return {
        styleKey = styleKey,
        fullType = fullType,
        fillPct = fillPct,
        tooltip = tooltip,
        batteryPct = batteryPct,
    }
end

