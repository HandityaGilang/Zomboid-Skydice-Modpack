local env = _G.NMHeadphoneSlotEnv
setfenv(1, env)

function isAllowedHeadphoneType(fullType)
    return HEADPHONE_TYPES[tostring(fullType or "")] == true
end

function resolveTextureByFullType(fullType)
    local ft = tostring(fullType or "")
    if ft == "" or not getTexture then
        return nil
    end
    local scriptItem = ScriptManager and ScriptManager.instance and ScriptManager.instance.FindItem
        and ScriptManager.instance:FindItem(ft) or nil
    if scriptItem and scriptItem.getIcon then
        local iconName = tostring(scriptItem:getIcon() or "")
        if iconName ~= "" then
            local tex = getTexture("Item_" .. iconName) or getTexture("media/textures/Item_" .. iconName .. ".png")
            if tex then return tex end
        end
    end
    local itemType = ft
    local dotPos = string.find(itemType, "%.")
    if dotPos then
        itemType = string.sub(itemType, dotPos + 1)
    end
    return getTexture("Item_" .. itemType) or getTexture("media/textures/Item_" .. itemType .. ".png")
end

function resolveItemTextureForFullType(fullType)
    local key = tostring(fullType or "")
    if key == "" then return nil end
    if HEADPHONE_TEXTURE_CACHE[key] == nil then
        HEADPHONE_TEXTURE_CACHE[key] = resolveTextureByFullType(key) or false
    end
    local tex = HEADPHONE_TEXTURE_CACHE[key]
    return tex ~= false and tex or nil
end

function resolveInsertedHeadphoneTooltip(fullType)
    local resolvedType = tostring(fullType or "")
    if resolvedType == "" then
        return NMTranslations.ui("InsertHeadphones", "Insert Headphones")
    end
    if resolvedType == "Base.Earbuds" then
        local item = ScriptManager and ScriptManager.instance and ScriptManager.instance.FindItem
            and ScriptManager.instance:FindItem(resolvedType) or nil
        if item and item.getDisplayName then
            local ok, displayName = pcall(item.getDisplayName, item)
            if ok and tostring(displayName or "") ~= "" then
                return tostring(displayName)
            end
        end
        return "Earbuds"
    end
    return NMTranslations.ui("HeadphonesInserted", "Headphones Inserted")
end

function drawEmptyHeadphoneVector(self)
    local icon = NMBatterySlotVectors.icons and NMBatterySlotVectors.icons.headphone_placeholder or nil
    local bounds = NMBatterySlotVectors.bounds and NMBatterySlotVectors.bounds.headphone_placeholder or nil
    if not (icon and bounds) then
        return false
    end
    if EMPTY_HEADPHONE_VECTOR_SHAPES == nil then
        EMPTY_HEADPHONE_VECTOR_SHAPES = {}
        for i = 1, #icon do
            EMPTY_HEADPHONE_VECTOR_SHAPES[i] = NMVectorDraw.prepareShape(icon[i], NMBatterySlotVectors.viewBox, bounds) or false
        end
    end
    local w = tonumber(self.width) or 0
    local h = tonumber(self.height) or 0
    local size = math.max(10, math.floor(math.min(w, h) * EMPTY_HEADPHONE_ICON_SCALE + 0.5))
    local left = math.floor((w - size) * 0.5 + 0.5)
    local top = math.floor((h - size) * 0.5 + 0.5)
    for i = 1, #EMPTY_HEADPHONE_VECTOR_SHAPES do
        local prepared = EMPTY_HEADPHONE_VECTOR_SHAPES[i]
        if prepared and prepared ~= false then
            NMVectorDraw.drawPreparedShape(self, prepared, EMPTY_SLOT_VECTOR_COLOR, left, top, size, size)
        end
    end
    return true
end

function drawEmptyPlaceholder(self)
    if drawEmptyHeadphoneVector(self) then
        return
    end

    if not EMPTY_PLACEHOLDER_HEADPHONE_TEXTURE then
        EMPTY_PLACEHOLDER_HEADPHONE_TEXTURE = getTexture and (
            getTexture("media/textures/UI/UI_NM_SlotEmpty_Headphones.png")
            or getTexture("UI/UI_NM_SlotEmpty_Headphones")
            or getTexture("UI_NM_SlotEmpty_Headphones")
            or getTexture("Item_NM_Headphones")
            or getTexture("media/textures/Item_NM_Headphones.png")
            or getTexture("Item_Headphones")
            or getTexture("media/textures/Item_Headphones.png")
        ) or nil
    end
    if EMPTY_PLACEHOLDER_HEADPHONE_TEXTURE then
        local tex = EMPTY_PLACEHOLDER_HEADPHONE_TEXTURE
        local texW = tex.getWidthOrig and tex:getWidthOrig() or 32
        local texH = tex.getHeightOrig and tex:getHeightOrig() or 32
        local maxW = self.width - 8
        local maxH = self.height - 8
        local scale = math.min(maxW / texW, maxH / texH)
        if scale > 1 then scale = 1 end
        local drawW = texW * scale
        local drawH = texH * scale
        local dx = (self.width - drawW) / 2
        local dy = (self.height - drawH) / 2
        self:drawTextureScaled(tex, dx, dy, drawW, drawH, 0.55, 0.12, 0.12, 0.12)
        return
    end

    if not EMPTY_PLACEHOLDER_BATTERY_TEXTURE then
        EMPTY_PLACEHOLDER_BATTERY_TEXTURE = getTexture and (getTexture("Item_Battery") or getTexture("media/textures/Item_Battery.png")) or nil
    end
    local tex = EMPTY_PLACEHOLDER_BATTERY_TEXTURE
    if not tex then
        return
    end
    local texW = tex.getWidthOrig and tex:getWidthOrig() or 32
    local texH = tex.getHeightOrig and tex:getHeightOrig() or 32
    local maxW = self.width - 8
    local maxH = self.height - 8
    local scale = math.min(maxW / texW, maxH / texH)
    if scale > 1 then scale = 1 end
    local drawW = texW * scale
    local drawH = texH * scale
    local dx = (self.width - drawW) / 2
    local dy = (self.height - drawH) / 2
    self:drawTextureScaled(tex, dx, dy, drawW, drawH, 0.85, 0.85, 0.85, 0.85)
end

function queueHeadphoneSlotAction(window, actionName, args, options)
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
    local immediate = options and options.immediate == true
    if immediate or not (playerObj and ISTimedActionQueue and NMHeadphoneSlotTimedAction) then
        return window:dispatch(actionName, payload)
    end
    ISTimedActionQueue.add(NMHeadphoneSlotTimedAction:new(playerObj, window, actionName, payload))
    return true
end

function getContextMenuPoint(button, x, y)
    local bx = button and button.getAbsoluteX and button:getAbsoluteX() or (getMouseX and getMouseX() or 0)
    local by = button and button.getAbsoluteY and button:getAbsoluteY() or (getMouseY and getMouseY() or 0)
    return bx + (tonumber(x) or 0), by + (tonumber(y) or 0)
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

function resolveGroundContext(window, state, resolved)
    local authoritativeMode = tostring(state and state.authoritativeMode or "")
    if NMInsertedHeadphonePolicy and NMInsertedHeadphonePolicy.isGroundContext(authoritativeMode) then
        return true
    end
    local ctx = resolved
    if not ctx then
        ctx = window and window.resolveContextCached and window:resolveContextCached()
            or (window and window.resolveContext and window:resolveContext() or nil)
    end
    local item = ctx and ctx.item or nil
    local worldItem = item and item.getWorldItem and item:getWorldItem() or nil
    local square = worldItem and worldItem.getSquare and worldItem:getSquare() or nil
    return square ~= nil
end

function isGroundInsertionBlocked(fullType)
    return NMInsertedHeadphonePolicy
        and NMInsertedHeadphonePolicy.shouldDetachOnGround(fullType)
        or false
end

function isAllowedHeadphoneTypeForContext(fullType, groundContext)
    if not isAllowedHeadphoneType(fullType) then
        return false
    end
    if groundContext and isGroundInsertionBlocked(fullType) then
        return false
    end
    return true
end

function collectEligibleHeadphoneItems(window, resolved, state)
    local ctx = resolved
    if not ctx then
        ctx = window and window.resolveContext and window:resolveContext() or nil
    end
    local groundContext = resolveGroundContext(window, state or (ctx and ctx.state or nil), ctx)
    local profile = ctx and ctx.profile or nil
    local player = ctx and ctx.player or nil
    if not (profile and NMDeviceProfiles.supportsHeadphones(profile)) then
        return {}
    end
    local inv = player and player.getInventory and player:getInventory() or nil
    if not inv then return {} end
    local all = {}
    NMInventoryHelpers.collectItemsRecursive(inv, all)
    local out = {}
    local seenById = {}
    for i = 1, #all do
        local item = all[i]
        local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        local itemId = item and item.getID and tostring(item:getID() or "") or ""
        if isAllowedHeadphoneTypeForContext(fullType, groundContext) and itemId ~= "" and not seenById[itemId] then
            seenById[itemId] = true
            out[#out + 1] = item
        end
    end
    return out
end

function resolveHeadphoneSlotFullType(window, state, allowSync)
    local authoritative = tostring((state and state.headphoneItemFullType) or "")
    local resolved = window and window.resolveContextCached and window:resolveContextCached()
        or (window and window.resolveContext and window:resolveContext() or nil)
    local profile = resolved and resolved.profile or nil
    if not (profile and NMDeviceProfiles and NMDeviceProfiles.supportsHeadphones(profile)) then
        if isAllowedHeadphoneType(authoritative) then
            return authoritative
        end
        return ""
    end
    local player = resolved and resolved.player or nil
    local wornHeadphones = NMAttachmentHelpers and NMAttachmentHelpers.findWornHeadphones
        and NMAttachmentHelpers.findWornHeadphones(player) or nil
    local isWearingHeadphones = wornHeadphones ~= nil
    local nowMs = (getTimestampMs and tonumber(getTimestampMs()))
        or (getTimeInMillis and tonumber(getTimeInMillis()))
        or 0
    local syncCooldownMs = 600
    local timed = window and window._nmHeadphoneSlotTimedProgress or nil
    local syncBusy = timed and timed.active == true
    local groundContext = resolveGroundContext(window, state, resolved)
    local canSync = (allowSync == true)
        and window
        and (not groundContext)
        and (not syncBusy)
        and ((window._nmHeadphoneWearSyncInFlight == true) ~= true)
        and (nowMs - tonumber(window._nmHeadphoneWearSyncLastMs or 0) >= syncCooldownMs)

    if canSync and authoritative == "" and isWearingHeadphones and wornHeadphones and wornHeadphones.getFullType
        and tostring(wornHeadphones:getFullType() or "") == "Base.Headphones" then
        local hpItemId = NMCore and NMCore.itemId and NMCore.itemId(wornHeadphones) or nil
        if hpItemId then
            window._nmHeadphoneWearSyncInFlight = true
            window._nmHeadphoneWearSyncLastMs = nowMs
            window._nmPendingHeadphoneSlotFullType = "Base.Headphones"
            local ok = queueHeadphoneSlotAction(
                window,
                "insert_headphones",
                { headphoneItemId = hpItemId },
                { immediate = true }
            )
            if ok ~= true then
                window._nmHeadphoneWearSyncInFlight = false
                window._nmPendingHeadphoneSlotFullType = nil
            end
        end
    elseif canSync and authoritative == "Base.Headphones" and (not isWearingHeadphones) then
        window._nmHeadphoneWearSyncInFlight = true
        window._nmHeadphoneWearSyncLastMs = nowMs
        window._nmPendingHeadphoneSlotFullType = ""
        local ok = queueHeadphoneSlotAction(window, "eject_headphones", {}, { immediate = true })
        if ok ~= true then
            window._nmHeadphoneWearSyncInFlight = false
            window._nmPendingHeadphoneSlotFullType = nil
        end
    end

    if groundContext and NMInsertedHeadphonePolicy and NMInsertedHeadphonePolicy.shouldDetachOnGround(authoritative) then
        authoritative = ""
    end
    if authoritative == "" and isWearingHeadphones and not groundContext then
        authoritative = "Base.Headphones"
    elseif authoritative == "Base.Headphones" and not isWearingHeadphones then
        authoritative = ""
    end
    local pending = window and window._nmPendingHeadphoneSlotFullType or nil
    local timed = window and window._nmHeadphoneSlotTimedProgress or nil
    local timedActive = timed and timed.active == true
    local timedAction = timedActive and tostring(timed.action or "") or ""
    if timedActive and timedAction == "eject_headphones" and tostring(pending or "") ~= "" then
        return tostring(pending or "")
    end
    if timedActive ~= true and pending ~= nil and tostring(pending or "") == authoritative then
        window._nmPendingHeadphoneSlotFullType = nil
        window._nmHeadphoneWearSyncInFlight = false
        if window._nmSlotRemoveInFlightByType then
            window._nmSlotRemoveInFlightByType.headphones = nil
        end
    end
    if isAllowedHeadphoneType(authoritative) then
        return authoritative
    end
    return ""
end

function NMHeadphoneSlot.tickWearSync(window, resolved)
    local perfStart = NMUIRenderProbe and NMUIRenderProbe.beginWindow and NMUIRenderProbe.beginWindow(window) or nil
    if not window then return false end
    local ctx = resolved
    if not ctx then
        ctx = window.resolveContextCached and window:resolveContextCached()
            or (window.resolveContext and window:resolveContext() or nil)
    end
    local state = ctx and ctx.state or nil
    if not state then
        if NMUIRenderProbe and NMUIRenderProbe.endWindow then
            NMUIRenderProbe.endWindow(window, "slot.headphone.sync_tick", perfStart)
        end
        return false
    end
    -- Run wearable reconciliation from an update tick, not from render.
    local fullType = resolveHeadphoneSlotFullType(window, state, true)
    if tostring(fullType or "") ~= "" then
        if NMUIRenderProbe and NMUIRenderProbe.count then
            NMUIRenderProbe.count(window, "slot.headphone.sync_active", 1)
        end
        if NMUIRenderProbe and NMUIRenderProbe.endWindow then
            NMUIRenderProbe.endWindow(window, "slot.headphone.sync_tick", perfStart)
        end
        return true
    end
    if window._nmHeadphoneWearSyncInFlight == true then
        if NMUIRenderProbe and NMUIRenderProbe.endWindow then
            NMUIRenderProbe.endWindow(window, "slot.headphone.sync_tick", perfStart)
        end
        return true
    end
    if window._nmPendingHeadphoneSlotFullType ~= nil then
        if NMUIRenderProbe and NMUIRenderProbe.endWindow then
            NMUIRenderProbe.endWindow(window, "slot.headphone.sync_tick", perfStart)
        end
        return true
    end
    if NMUIRenderProbe and NMUIRenderProbe.endWindow then
        NMUIRenderProbe.endWindow(window, "slot.headphone.sync_tick", perfStart)
    end
    return false
end

function isCompatibleHeadphoneItem(item)
    local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
    return isAllowedHeadphoneType(fullType)
end

function isCompatibleHeadphoneDrag(window, items, resolved, state)
    if type(items) ~= "table" or #items <= 0 then return false end
    local groundContext = resolveGroundContext(window, state, resolved)
    for i = 1, #items do
        local item = items[i]
        local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        if isCompatibleHeadphoneItem(item) and isAllowedHeadphoneTypeForContext(fullType, groundContext) then
            return true
        end
    end
    return false
end

function pickFirstCompatibleHeadphone(window, items, resolved, state)
    if type(items) ~= "table" then return nil end
    local groundContext = resolveGroundContext(window, state, resolved)
    for i = 1, #items do
        local item = items[i]
        local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
        if isCompatibleHeadphoneItem(item) and isAllowedHeadphoneTypeForContext(fullType, groundContext) then
            return item
        end
    end
    return nil
end

function normalizeHeadphoneIngressItem(window, item)
    local resolved = window and window.resolveContext and window:resolveContext() or nil
    local player = resolved and resolved.player or nil
    local itemId = item and NMCore and NMCore.itemId and NMCore.itemId(item) or nil
    local uuid = item and NMInventoryHelpers and NMInventoryHelpers.getItemStateUuid and NMInventoryHelpers.getItemStateUuid(item) or nil
    if not (player and itemId and NMInventoryHelpers and NMInventoryHelpers.normalizeItemToMainInventory) then
        return nil, "normalize_helper_missing"
    end
    return NMInventoryHelpers.normalizeItemToMainInventory(player, itemId, uuid)
end

function resolveSlotStyle(window, button, resolved)
    local profile = resolved and resolved.profile or nil
    if not (profile and NMDeviceProfiles.supportsHeadphones(profile)) then
        return "slot"
    end
    local mouseOver = isMouseOverButton(button)
    if mouseOver then
        if NMUIRenderProbe and NMUIRenderProbe.count then
            NMUIRenderProbe.count(window, "slot.drag_check", 1)
        end
        local items, ok = getDraggedInventoryItems()
        local state = resolved and resolved.state or nil
        if ok and type(items) == "table" and #items > 0 and isCompatibleHeadphoneDrag(window, items, resolved, state) then
            return "slot_drag"
        end
    end
    local state = resolved and resolved.state or nil
    local fullType = resolveHeadphoneSlotFullType(window, state)
    if fullType ~= "" then
        return "slot_filled"
    end
    if mouseOver then
        return "slot_hover"
    end
    return "slot"
end

function NMHeadphoneSlot.buildRenderState(window, frame)
    local resolved = frame and frame.resolved or (window and window.resolveContextCached and window:resolveContextCached()) or nil
    local state = resolved and resolved.state or nil
    local profile = resolved and resolved.profile or nil
    local button = window and window.headphoneSlot and window.headphoneSlot.button or nil
    local fullType = resolveHeadphoneSlotFullType(window, state)
    local supported = profile and NMDeviceProfiles.supportsHeadphones(profile) or false
    local mouseOver = isMouseOverButton(button)
    local styleKey = "slot"
    if supported then
        if mouseOver and frame and frame.dragOk and type(frame.dragItems) == "table" and #frame.dragItems > 0
            and isCompatibleHeadphoneDrag(window, frame.dragItems, resolved, state) then
            styleKey = "slot_drag"
        elseif fullType ~= "" then
            styleKey = "slot_filled"
        elseif mouseOver then
            styleKey = "slot_hover"
        end
    end
    local timed = window and window._nmHeadphoneSlotTimedProgress or nil
    local fillPct = nil
    if timed and timed.active == true and timed.delta then
        fillPct = NMCore.clamp(tonumber(timed.delta) or 0.0, 0.0, 1.0)
    end
    local tooltip = nil
    local texture = nil
        if supported then
            if fullType ~= "" then
                texture = resolveItemTextureForFullType(fullType)
                tooltip = resolveInsertedHeadphoneTooltip(fullType)
            else
                tooltip = NMTranslations.ui("InsertHeadphones", "Insert Headphones")
            end
    end
    return {
        styleKey = styleKey,
        fullType = fullType,
        fillPct = fillPct,
        supported = supported == true,
        tooltip = tooltip,
        texture = texture,
    }
end

