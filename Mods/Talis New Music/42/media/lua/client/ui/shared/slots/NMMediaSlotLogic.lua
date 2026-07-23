local env = _G.NMMediaSlotEnv
setfenv(1, env)

function resolveDeviceCarrier(window)
    local resolved = window and window.resolveContext and window:resolveContext() or nil
    local profile = resolved and resolved.profile or nil
    return tostring(profile and profile.supportedCarrier or "")
end
function queueMediaSlotAction(window, actionName, args)
    if not window then return false end
    if window._nmSlotRangeGateEnabled ~= false and not canQueueSlotAction(window) then
        return false
    end
    if actionName == "insert_media"
        and window.isAwaitingAuthoritativeMediaEject
        and window:isAwaitingAuthoritativeMediaEject() == true then
        return false
    end
    if actionName == "eject_media"
        and window.clearAwaitingAuthoritativeMediaInsert then
        window:clearAwaitingAuthoritativeMediaInsert()
    end
    local payload = args or {}
    if payload.slotTraceId == nil then
        payload.slotTraceId = nextSlotTraceId()
    end
    local resolved = window.resolveContext and window:resolveContext() or nil
    local playerObj = resolved and resolved.player or nil
    if not (playerObj and ISTimedActionQueue and NMMediaSlotTimedAction) then
        return window:dispatch(actionName, payload)
    end
    ISTimedActionQueue.add(NMMediaSlotTimedAction:new(playerObj, window, actionName, payload))
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
    local mediaType = ft
    local dotPos = string.find(mediaType, "%.")
    if dotPos then
        mediaType = string.sub(mediaType, dotPos + 1)
    end
    return getTexture("Item_" .. mediaType)
        or getTexture("media/textures/Item_" .. mediaType .. ".png")
end

function resolveItemTextureForMedia(item)
    if not item then return nil end
    local fullType = item.getFullType and item:getFullType() or nil
    if not fullType then return nil end
    local key = tostring(fullType)
    if MEDIA_TEXTURE_CACHE[key] == nil then
        MEDIA_TEXTURE_CACHE[key] = resolveTextureByFullType(fullType) or false
    end
    local tex = MEDIA_TEXTURE_CACHE[key]
    return tex ~= false and tex or nil
end

function resolveMediaSlotFullType(window, state)
    local authoritative = tostring((state and (state.mediaEjectFullType or state.mediaFullType)) or "")
    local awaitingAuthoritativeInsert = window and window.isAwaitingAuthoritativeMediaInsert
        and window:isAwaitingAuthoritativeMediaInsert() == true
        or false
    if awaitingAuthoritativeInsert == true then
        local awaitingInsertFullType = tostring(window._nmAwaitingAuthoritativeMediaInsert and window._nmAwaitingAuthoritativeMediaInsert.fullType or "")
        if authoritative == awaitingInsertFullType and awaitingInsertFullType ~= "" then
            if window.clearAwaitingAuthoritativeMediaInsert then
                window:clearAwaitingAuthoritativeMediaInsert()
            else
                window._nmAwaitingAuthoritativeMediaInsert = nil
            end
            authoritative = awaitingInsertFullType
            awaitingAuthoritativeInsert = false
        elseif awaitingInsertFullType ~= "" and authoritative == "" then
            return awaitingInsertFullType
        else
            if window.clearAwaitingAuthoritativeMediaInsert then
                window:clearAwaitingAuthoritativeMediaInsert()
            else
                window._nmAwaitingAuthoritativeMediaInsert = nil
            end
            awaitingAuthoritativeInsert = false
        end
    end
    local awaitingAuthoritativeEject = window and window.isAwaitingAuthoritativeMediaEject
        and window:isAwaitingAuthoritativeMediaEject() == true
        or false
    if awaitingAuthoritativeEject == true then
        local awaitingFullType = tostring(window._nmAwaitingAuthoritativeMediaEject and window._nmAwaitingAuthoritativeMediaEject.fullType or "")
        if authoritative == "" or (awaitingFullType ~= "" and authoritative ~= awaitingFullType) then
            if window.clearAwaitingAuthoritativeMediaEject then
                window:clearAwaitingAuthoritativeMediaEject()
            else
                window._nmAwaitingAuthoritativeMediaEject = nil
            end
            awaitingAuthoritativeEject = false
        elseif awaitingFullType ~= "" and authoritative == awaitingFullType then
            return ""
        end
    end
    local pending = window and window._nmPendingMediaSlotFullType or nil
    local timed = window and window._nmMediaSlotTimedProgress or nil
    local timedAction = timed and tostring(timed.action or "") or ""
    local timedActive = timed and timed.active == true and (timedAction == "insert_media" or timedAction == "eject_media")
    if timedActive and timedAction == "eject_media" and tostring(pending or "") ~= "" then
        return tostring(pending or "")
    end
    if timedActive ~= true and pending ~= nil and tostring(pending or "") == authoritative then
        window._nmPendingMediaSlotFullType = nil
        if window._nmSlotRemoveInFlightByType then
            window._nmSlotRemoveInFlightByType.media = nil
        end
    end
    return authoritative
end

function isCompatibleMediaItem(window, item)
    if not (window and item and item.getFullType) then return false end
    local profile = NMDeviceProfiles and NMDeviceProfiles.getForItem and NMDeviceProfiles.getForItem(item) or nil
    if profile and profile.isMediaContainerOnly ~= true then
        return false
    end
    local requiredCarrier = resolveDeviceCarrier(window)
    if requiredCarrier == "" then return false end
    local fullType = item:getFullType()
    local typeName = item.getType and item:getType() or nil
    local resolvedCarrier = NMMediaContract and NMMediaContract.resolveMediaCarrier and NMMediaContract.resolveMediaCarrier(fullType or typeName) or nil
    return tostring(resolvedCarrier or "") == requiredCarrier
end

function isCompatibleMediaDrag(window, items)
    if type(items) ~= "table" or #items <= 0 then return false end
    for i = 1, #items do
        if isCompatibleMediaItem(window, items[i]) then
            return true
        end
    end
    return false
end

function pickFirstCompatibleMedia(window, items)
    if type(items) ~= "table" then return nil end
    for i = 1, #items do
        if isCompatibleMediaItem(window, items[i]) then
            return items[i]
        end
    end
    return nil
end

function normalizeMediaIngressItem(window, item)
    local resolved = window and window.resolveContext and window:resolveContext() or nil
    local player = resolved and resolved.player or nil
    local itemId = item and NMCore and NMCore.itemId and NMCore.itemId(item) or nil
    local uuid = item and NMInventoryHelpers and NMInventoryHelpers.getItemStateUuid and NMInventoryHelpers.getItemStateUuid(item) or nil
    if not (player and itemId and NMInventoryHelpers and NMInventoryHelpers.normalizeItemToMainInventory) then
        return nil, "normalize_helper_missing"
    end
    return NMInventoryHelpers.normalizeItemToMainInventory(player, itemId, uuid)
end

function collectEligibleMediaItems(window)
    local resolved = window and window.resolveContext and window:resolveContext() or nil
    local player = resolved and resolved.player or nil
    local inv = player and player.getInventory and player:getInventory() or nil
    if not inv then return {} end
    local all, out, seen = {}, {}, {}
    NMInventoryHelpers.collectItemsRecursive(inv, all)
    for i = 1, #all do
        local item = all[i]
        local key = nil
        if item and item.getID then
            key = "id:" .. tostring(item:getID() or "")
        end
        if not key or key == "id:" then
            local ft = item and item.getFullType and tostring(item:getFullType() or "") or "?"
            local dn = item and item.getDisplayName and tostring(item:getDisplayName() or "") or "?"
            key = "fallback:" .. ft .. "|" .. dn
        end
        if isCompatibleMediaItem(window, item) and not seen[key] then
            seen[key] = true
            out[#out + 1] = item
        end
    end
    return out
end

function resolveMediaVectorBounds(iconKey)
    local viewBox = tonumber(NMBatterySlotVectors.viewBox) or 23
    if tostring(iconKey or "") == "vinyl_placeholder" then
        return { minX = 0, minY = 0, maxX = viewBox, maxY = viewBox }
    end
    return NMBatterySlotVectors.bounds and NMBatterySlotVectors.bounds[iconKey] or nil
end

function drawEmptyMediaVector(button, iconKey)
    local icon = NMBatterySlotVectors.icons and NMBatterySlotVectors.icons[iconKey] or nil
    local bounds = resolveMediaVectorBounds(iconKey)
    if not (icon and bounds) then return false end
    local preparedShapes = EMPTY_MEDIA_VECTOR_CACHE[iconKey]
    if preparedShapes == nil then
        preparedShapes = {}
        for i = 1, #icon do
            preparedShapes[i] = NMVectorDraw.prepareShape(icon[i], NMBatterySlotVectors.viewBox, bounds) or false
        end
        EMPTY_MEDIA_VECTOR_CACHE[iconKey] = preparedShapes
    end
    local w = tonumber(button.width) or 0
    local h = tonumber(button.height) or 0
    local scale = EMPTY_MEDIA_ICON_SCALE
    local key = tostring(iconKey or "")
    if key == "cd_placeholder" then
        scale = EMPTY_MEDIA_ICON_SCALE_CD
    elseif key == "cassette_placeholder" then
        scale = EMPTY_MEDIA_ICON_SCALE_CASSETTE
    end
    local size = math.max(10, math.floor(math.min(w, h) * scale + 0.5))
    local left = math.floor((w - size) * 0.5 + 0.5)
    local top = math.floor((h - size) * 0.5 + 0.5)
    for i = 1, #preparedShapes do
        local prepared = preparedShapes[i]
        if prepared and prepared ~= false then
            NMVectorDraw.drawPreparedShape(button, prepared, EMPTY_SLOT_VECTOR_COLOR, left, top, size, size)
        end
    end
    return true
end

function resolveEmptyMediaTexture(iconKey)
    local key = tostring(iconKey or "")
    if key == "" then return nil end
    if EMPTY_MEDIA_PLACEHOLDER_TEXTURES[key] == nil then
        local tex = nil
        if key == "cd_placeholder" then
            tex = getTexture and (
                getTexture("media/textures/UI/UI_NM_SlotEmpty_CD.png")
                or getTexture("UI/UI_NM_SlotEmpty_CD")
                or getTexture("UI_NM_SlotEmpty_CD")
            ) or nil
        elseif key == "vinyl_placeholder" then
            tex = getTexture and (
                getTexture("media/textures/UI/UI_NM_SlotEmpty_Vinyl.png")
                or getTexture("UI/UI_NM_SlotEmpty_Vinyl")
                or getTexture("UI_NM_SlotEmpty_Vinyl")
            ) or nil
        else
            tex = getTexture and (
                getTexture("media/textures/UI/UI_NM_SlotEmpty_Cassette.png")
                or getTexture("UI/UI_NM_SlotEmpty_Cassette")
                or getTexture("UI_NM_SlotEmpty_Cassette")
            ) or nil
        end
        EMPTY_MEDIA_PLACEHOLDER_TEXTURES[key] = tex or false
    end
    local cached = EMPTY_MEDIA_PLACEHOLDER_TEXTURES[key]
    return cached ~= false and cached or nil
end

function drawEmptyMediaTexture(button, iconKey)
    local tex = resolveEmptyMediaTexture(iconKey)
    if not tex then return false end
    local texW = tex.getWidthOrig and tex:getWidthOrig() or (tex.getWidth and tex:getWidth()) or 32
    local texH = tex.getHeightOrig and tex:getHeightOrig() or (tex.getHeight and tex:getHeight()) or 32
    local maxW = (tonumber(button.width) or 0) - 8
    local maxH = (tonumber(button.height) or 0) - 8
    local scale = math.min(maxW / texW, maxH / texH)
    if tostring(iconKey or "") == "cassette_placeholder" then
        scale = scale * EMPTY_MEDIA_TEXTURE_SCALE_CASSETTE
    end
    if scale > 1 then scale = 1 end
    local drawW = texW * scale
    local drawH = texH * scale
    local left = (button.width - drawW) / 2
    local top = (button.height - drawH) / 2
    button:drawTextureScaled(tex, left, top, drawW, drawH, 0.55, 0.12, 0.12, 0.12)
    return true
end

function drawMediaTexture(button, fullType)
    local tex = resolveTextureByFullType(fullType)
    if not tex then return end
    local w = tonumber(button.width) or 0
    local h = tonumber(button.height) or 0
    -- Match TVM slot item icon sizing lane.
    local size = math.max(10, math.min(32, math.min(w, h) - 6))
    local left = math.floor((w - size) * 0.5 + 0.5)
    local top = math.floor((h - size) * 0.5 + 0.5)
    button:drawTextureScaledAspect(tex, left, top, size, size, 1.0, 1.0, 1.0, 1.0)
end

function resolvePlaceholderKey(window)
    local carrier = resolveDeviceCarrier(window)
    if carrier == tostring(CARRIER_KEYS.cd) then
        return "cd_placeholder"
    end
    if carrier == tostring(CARRIER_KEYS.vinyl) then
        return "vinyl_placeholder"
    end
    return "cassette_placeholder"
end

function resolveEmptyInsertTooltip(window)
    local carrier = resolveDeviceCarrier(window)
    if carrier == tostring(CARRIER_KEYS.cd) then
        return NMTranslations.ui("InsertCD", "Insert CD")
    end
    if carrier == tostring(CARRIER_KEYS.vinyl) then
        return NMTranslations.ui("InsertVinyl", "Insert Vinyl")
    end
    return NMTranslations.ui("InsertCassette", "Insert Cassette")
end

function resolveMediaTooltipLabel(state, fullType)
    local display = tostring(state and state.mediaDisplayName or "")
    if display ~= "" then
        return display
    end
    local ft = tostring(fullType or "")
    if ft ~= "" and NMMediaContract and NMMediaContract.getDisplayNameForFullType then
        local resolved = tostring(NMMediaContract.getDisplayNameForFullType(ft) or "")
        if resolved ~= "" then
            return resolved
        end
    end
    return ft
end

function resolveSlotStyle(window, button, resolved)
    local mouseOver = isMouseOverButton(button)
    if mouseOver then
        if NMUIRenderProbe and NMUIRenderProbe.count then
            NMUIRenderProbe.count(window, "slot.drag_check", 1)
        end
        local items, ok = getDraggedInventoryItems()
        if ok and type(items) == "table" and #items > 0 and isCompatibleMediaDrag(window, items) then
            return "slot_drag"
        end
    end
    local state = resolved and resolved.state or nil
    local fullType = resolveMediaSlotFullType(window, state)
    if fullType ~= "" then
        return "slot_filled"
    end
    if mouseOver then
        return "slot_hover"
    end
    return "slot"
end

function NMMediaSlot.buildRenderState(window, frame)
    local resolved = frame and frame.resolved or (window and window.resolveContextCached and window:resolveContextCached()) or nil
    local state = resolved and resolved.state or nil
    local button = window and window.mediaSlot and window.mediaSlot.button or nil
    local fullType = resolveMediaSlotFullType(window, state)
    local mouseOver = isMouseOverButton(button)
    local styleKey = "slot"
    if mouseOver and frame and frame.dragOk and type(frame.dragItems) == "table" and #frame.dragItems > 0
        and isCompatibleMediaDrag(window, frame.dragItems) then
        styleKey = "slot_drag"
    elseif fullType ~= "" then
        styleKey = "slot_filled"
    elseif mouseOver then
        styleKey = "slot_hover"
    end
    local timed = window and window._nmMediaSlotTimedProgress or nil
    local fillPct = nil
    if timed and timed.active == true and timed.delta then
        fillPct = NMCore.clamp(tonumber(timed.delta) or 0.0, 0.0, 1.0)
    end
    local placeholderKey = nil
    local tooltip = nil
    if fullType ~= "" then
        tooltip = resolveMediaTooltipLabel(state, fullType)
    else
        placeholderKey = resolvePlaceholderKey(window)
        tooltip = resolveEmptyInsertTooltip(window)
    end
    return {
        styleKey = styleKey,
        fullType = fullType,
        fillPct = fillPct,
        placeholderKey = placeholderKey,
        tooltip = tooltip,
    }
end

