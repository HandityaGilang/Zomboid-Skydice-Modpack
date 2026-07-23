local env = _G.NMMediaSlotEnv
setfenv(1, env)

local function logPortableUiProbe(tag, detail)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("portableUiProbe")) then
        return
    end
    NMCore.logChannel("portableUiProbe", tostring(tag or "portable_ui"), tostring(detail or ""))
end

local function resolveWindowFamily(window)
    if window and window.getLidRect and window.syncLidFromMedia then
        return "walkman"
    end
    return "generic"
end

function queueDraggedMediaInsert(window, items, sourceTag)
    if not (window and type(items) == "table" and #items > 0) then
        return false
    end
    if not isCompatibleMediaDrag(window, items) then
        return false
    end
    local mediaItem = pickFirstCompatibleMedia(window, items)
    if not mediaItem then
        return false
    end
    local liveItem = normalizeMediaIngressItem(window, mediaItem)
    if not liveItem then
        window._nmPendingMediaSlotFullType = nil
        clearMouseDragState()
        return false
    end
    local payload = NMMediaHelpers.resolveMediaInsertPayload(liveItem)
    if not payload then
        return false
    end
    window._nmPendingMediaSlotFullType = tostring(payload.mediaEjectFullType or payload.mediaFullType or "")
    window.isLidManuallyOpen = true
    if window.syncLidFromMedia then
        window:syncLidFromMedia(false)
    end
    local args = {
        mediaItemId = NMCore.itemId(liveItem),
        mediaFullType = payload.mediaFullType,
        mediaCarrier = payload.mediaCarrier,
        mediaEjectFullType = payload.mediaEjectFullType,
        mediaCanonicalFullType = payload.mediaCanonicalFullType,
        mediaRecordedMediaIndex = payload.mediaRecordedMediaIndex,
        mediaDisplayName = payload.mediaDisplayName
    }
    logPortableUiProbe(
        "slot_insert_drag_queue",
        string.format(
            "ui=%s targetItemId=%s targetUuid=%s mediaItemId=%s mediaUuid=%s mediaFullType=%s slotTraceId=%s source=%s",
            tostring(resolveWindowFamily(window)),
            tostring(window and window.target and window.target.itemId or ""),
            tostring(window and window.target and window.target.uuid or ""),
            tostring(args.mediaItemId or ""),
            tostring(liveItem and NMInventoryHelpers and NMInventoryHelpers.getItemStateUuid and NMInventoryHelpers.getItemStateUuid(liveItem) or ""),
            tostring(args.mediaEjectFullType or args.mediaFullType or ""),
            tostring(args.slotTraceId or ""),
            tostring(sourceTag or "direct")
        )
    )
    if queueMediaSlotAction(window, "insert_media", args) ~= true then
        window._nmPendingMediaSlotFullType = nil
        return false
    end
    clearMouseDragState()
    return true
end

function queueMediaSlotEject(window, sourceTag)
    if not window then
        return false
    end
    if window.isAwaitingAuthoritativeMediaEject and window:isAwaitingAuthoritativeMediaEject() == true then
        return false
    end
    local resolved = window and window.resolveContext and window:resolveContext() or nil
    local state = resolved and resolved.state or nil
    local renderState = window and window.getSlotRenderState and window:getSlotRenderState("media") or nil
    local fullType = tostring(renderState and renderState.fullType or "")
    if fullType == "" then
        fullType = resolveMediaSlotFullType(window, state)
    end
    if fullType == "" then
        return false
    end
    window._nmSlotRemoveInFlightByType = window._nmSlotRemoveInFlightByType or {}
    if window._nmSlotRemoveInFlightByType.media then
        return true
    end
    window._nmSlotRemoveInFlightByType.media = true
    window._nmPendingMediaSlotFullType = tostring(fullType or "")
    logPortableUiProbe(
        "slot_eject_click_queue",
        string.format(
            "ui=%s targetItemId=%s targetUuid=%s mediaFullType=%s source=%s",
            tostring(resolveWindowFamily(window)),
            tostring(window and window.target and window.target.itemId or ""),
            tostring(window and window.target and window.target.uuid or ""),
            tostring(fullType or ""),
            tostring(sourceTag or "direct")
        )
    )
    if queueMediaSlotAction(window, "eject_media", {}) ~= true then
        window._nmPendingMediaSlotFullType = nil
        window._nmSlotRemoveInFlightByType.media = nil
        return false
    end
    return true
end

function showMediaInsertContextMenu(window, btn, xArg, yArg)
    if not window then
        return false
    end
    local resolvedCtx = window.resolveContext and window:resolveContext() or nil
    local player = resolvedCtx and resolvedCtx.player or nil
    local playerNum = player and player.getPlayerNum and tonumber(player:getPlayerNum()) or 0
    local cx, cy = getContextMenuPoint(btn, xArg, yArg)
    local context = ISContextMenu and ISContextMenu.get and ISContextMenu.get(playerNum or 0, cx, cy) or nil
    if not context then
        return false
    end
    local actionOption = context:addOption(NMTranslations.ui("InsertMedia", "Insert Media"), nil, nil)
    if NMUIRenderProbe and NMUIRenderProbe.count then
        NMUIRenderProbe.count(window, "slot.candidate_scan", 1)
    end
    local items = collectEligibleMediaItems(window)
    if #items <= 0 then
        actionOption.notAvailable = true
        return true
    end
    local sub = context:getNew(context)
    context:addSubMenu(actionOption, sub)
    for i = 1, #items do
        local item = items[i]
        local label = item.getDisplayName and item:getDisplayName() or NMTranslations.ui("Media", "Media")
        local option = sub:addOption(label, window, function(targetWin, targetItem)
            local liveItem = normalizeMediaIngressItem(targetWin, targetItem)
            if not liveItem then
                targetWin._nmPendingMediaSlotFullType = nil
                return
            end
            local payload = NMMediaHelpers.resolveMediaInsertPayload(liveItem)
            if not payload then return end
            targetWin._nmPendingMediaSlotFullType = tostring(payload.mediaEjectFullType or payload.mediaFullType or "")
            targetWin.isLidManuallyOpen = true
            if targetWin.syncLidFromMedia then
                targetWin:syncLidFromMedia(false)
            end
            local args = {
                mediaItemId = NMCore.itemId(liveItem),
                mediaFullType = payload.mediaFullType,
                mediaCarrier = payload.mediaCarrier,
                mediaEjectFullType = payload.mediaEjectFullType,
                mediaCanonicalFullType = payload.mediaCanonicalFullType,
                mediaRecordedMediaIndex = payload.mediaRecordedMediaIndex,
                mediaDisplayName = payload.mediaDisplayName
            }
            logPortableUiProbe(
                "slot_insert_context_queue",
                string.format(
                    "ui=%s targetItemId=%s targetUuid=%s mediaItemId=%s mediaUuid=%s mediaFullType=%s slotTraceId=%s",
                    tostring(resolveWindowFamily(targetWin)),
                    tostring(targetWin and targetWin.target and targetWin.target.itemId or ""),
                    tostring(targetWin and targetWin.target and targetWin.target.uuid or ""),
                    tostring(args.mediaItemId or ""),
                    tostring(liveItem and NMInventoryHelpers and NMInventoryHelpers.getItemStateUuid and NMInventoryHelpers.getItemStateUuid(liveItem) or ""),
                    tostring(args.mediaEjectFullType or args.mediaFullType or ""),
                    tostring(args.slotTraceId or "")
                )
            )
            if queueMediaSlotAction(targetWin, "insert_media", args) ~= true then
                targetWin._nmPendingMediaSlotFullType = nil
            end
        end, item)
        option.itemForTexture = item
    end
    return true
end

function beginMediaExtractDrag(window, fullType)
    local resolved = window and window.resolveContext and window:resolveContext() or nil
    local playerObj = resolved and resolved.player or nil
    local playerNum = playerObj and playerObj.getPlayerNum and playerObj:getPlayerNum() or 0
    local invPage = getPlayerInventory and getPlayerInventory(playerNum) or nil
    if invPage and invPage.pin == false and invPage.setPinned then
        invPage:setPinned()
        window._nmMediaDragPinnedInventory = true
    end
    local mx = getMouseX and getMouseX() or 0
    local my = getMouseY and getMouseY() or 0
    local tex = resolveTextureByFullType(fullType)
    window._nmMediaExtractDrag = {
        slotType = "media",
        fullType = tostring(fullType or ""),
        iconTex = tex,
        iconTint = { r = 1.0, g = 1.0, b = 1.0 },
        startX = mx,
        startY = my,
        moved = false
    }
    NMMediaSlot._ghostDragWindow = window
end

function stepMediaExtractDrag(window)
    local drag = window and window._nmMediaExtractDrag or nil
    if not drag then return end
    local mx = getMouseX and getMouseX() or drag.startX
    local my = getMouseY and getMouseY() or drag.startY
    if (not drag.moved) and (math.abs(mx - (drag.startX or mx)) > DRAG_THRESHOLD or math.abs(my - (drag.startY or my)) > DRAG_THRESHOLD) then
        drag.moved = true
        window._nmMediaExtractDrag = drag
    end
end

function collapsePinnedInventory(window, resolvedPlayer)
    if window and window._nmMediaDragPinnedInventory then
        local playerObj = resolvedPlayer
        if not playerObj then
            local resolved = window and window.resolveContext and window:resolveContext() or nil
            playerObj = resolved and resolved.player or nil
        end
        local playerNum = playerObj and playerObj.getPlayerNum and playerObj:getPlayerNum() or 0
        local invPage = getPlayerInventory and getPlayerInventory(playerNum) or nil
        if invPage and invPage.collapse then
            invPage:collapse()
        end
        window._nmMediaDragPinnedInventory = nil
    end
end

function cancelMediaExtractDrag(window)
    if window then
        window._nmMediaExtractDrag = nil
        if window._nmSlotRemoveInFlightByType then
            window._nmSlotRemoveInFlightByType.media = nil
        end
        collapsePinnedInventory(window, nil)
    end
    NMMediaSlot._ghostDragWindow = nil
end

function completeMediaExtractDrag(window, slotButton)
    local drag = window and window._nmMediaExtractDrag or nil
    if not drag then return false end
    local releaseOverSourceSlot = isMouseOverButton(slotButton)
    window._nmMediaExtractDrag = nil
    collapsePinnedInventory(window, nil)
    NMMediaSlot._ghostDragWindow = nil
    if drag.moved ~= true then return false end
    if releaseOverSourceSlot then return false end
    window._nmSlotRemoveInFlightByType = window._nmSlotRemoveInFlightByType or {}
    if window._nmSlotRemoveInFlightByType.media then
        return false
    end
    window._nmSlotRemoveInFlightByType.media = true
    window._nmPendingMediaSlotFullType = tostring(drag.fullType or "")
    if queueMediaSlotAction(window, "eject_media", {}) ~= true then
        window._nmPendingMediaSlotFullType = nil
        window._nmSlotRemoveInFlightByType.media = nil
        return false
    end
    return true
end

function NMMediaSlot.cancelExtractDrag(window)
    cancelMediaExtractDrag(window)
end

function NMMediaSlot.ensureGhostOverlay()
    local batteryActive = false
    local batterySrc = NMBatterySlot and NMBatterySlot._ghostDragWindow or nil
    local batteryDrag = batterySrc and batterySrc._nmBatteryExtractDrag or nil
    if batteryDrag and batteryDrag.moved and batteryDrag.iconTex then
        batteryActive = true
    end
    local mediaActive = false
    local mediaSrc = NMMediaSlot._ghostDragWindow
    local mediaDrag = mediaSrc and mediaSrc._nmMediaExtractDrag or nil
    if mediaDrag and mediaDrag.moved and mediaDrag.iconTex then
        mediaActive = true
    end
    local headphoneActive = false
    local headphoneSrc = NMHeadphoneSlot and NMHeadphoneSlot._ghostDragWindow or nil
    local headphoneDrag = headphoneSrc and headphoneSrc._nmHeadphoneExtractDrag or nil
    if headphoneDrag and headphoneDrag.moved and headphoneDrag.iconTex then
        headphoneActive = true
    end
    local active = batteryActive or mediaActive or headphoneActive

    if (not active) and NMSlotGhostOverlay and NMSlotGhostOverlay.instance then
        local overlay = NMSlotGhostOverlay.instance
        if overlay.setVisible then overlay:setVisible(false) end
        if overlay.removeFromUIManager then overlay:removeFromUIManager() end
        NMSlotGhostOverlay.instance = nil
        return
    end

    if not active then return end
    if not NMSlotGhostOverlay then return end
    if not NMSlotGhostOverlay.instance then
        local ui = NMSlotGhostOverlay:new()
        ui:initialise()
        ui:instantiate()
        ui:addToUIManager()
        NMSlotGhostOverlay.instance = ui
    else
        local ui = NMSlotGhostOverlay.instance
        if ui.setVisible then ui:setVisible(true) end
        if ui.bringToTop then ui:bringToTop() end
    end
end

function NMMediaSlot.attach(window, x, y, size)
    local slotBtn = ISButton:new(x, y, size, size, "", window, function() end)
    slotBtn:initialise()
    slotBtn:instantiate()
    window:addChild(slotBtn)

    function onMediaSlotMouseDown()
        handlePortableMediaSlotMouseDown(window, "slot")
        return true
    end

    function onMediaSlot()
        return handlePortableMediaSlotMouseUp(window, "slot")
    end

    function onMediaSlotRightClick(btn, xArg, yArg)
        return handlePortableMediaSlotRightClick(window, "slot", btn, xArg, yArg)
    end

    slotBtn.onMouseDown = function(btn, xArg, yArg)
        return onMediaSlotMouseDown()
    end
    slotBtn.onMouseUp = function(btn, xArg, yArg)
        return onMediaSlot()
    end
    slotBtn.onMouseUpOutside = function(btn, xArg, yArg)
        return handlePortableMediaSlotMouseUp(window, "slot")
    end
    slotBtn.onRightMouseDown = function(btn, xArg, yArg)
        return true
    end
    slotBtn.onRightMouseUp = function(btn, xArg, yArg)
        return onMediaSlotRightClick(btn, xArg, yArg)
    end
    slotBtn.onMouseMove = function(btn, dx, dy)
        stepMediaExtractDrag(window)
        NMMediaSlot.ensureGhostOverlay()
    end
    slotBtn.onMouseMoveOutside = function(btn, dx, dy)
        stepMediaExtractDrag(window)
        NMMediaSlot.ensureGhostOverlay()
    end

    local baseRender = slotBtn.render
    slotBtn.render = function(self)
        local perfStart = NMUIRenderProbe and NMUIRenderProbe.beginWindow and NMUIRenderProbe.beginWindow(window) or nil
        self:setTitle("")
        local renderState = window.getSlotRenderState and window:getSlotRenderState("media") or nil
        local styleKey = renderState and renderState.styleKey or "slot"
        NMSlotButtonStyles.apply(self, styleKey)

        local fullType = renderState and renderState.fullType or ""
        local fillPct = renderState and renderState.fillPct or nil
        if fillPct ~= nil then
            local fillH = math.floor((self.height * fillPct) + 0.5)
            if fillH > 0 then
                self:drawRect(0, self.height - fillH, self.width, fillH, SLOT_PROGRESS_FILL.a, SLOT_PROGRESS_FILL.r, SLOT_PROGRESS_FILL.g, SLOT_PROGRESS_FILL.b)
            end
        end

        baseRender(self)

        if fullType ~= "" then
            drawMediaTexture(self, fullType)
            self.tooltip = renderState and renderState.tooltip or tostring(fullType)
        else
            local placeholderKey = renderState and renderState.placeholderKey or resolvePlaceholderKey(window)
            if not drawEmptyMediaVector(self, placeholderKey) then
                drawEmptyMediaTexture(self, placeholderKey)
            end
            self.tooltip = renderState and renderState.tooltip or resolveEmptyInsertTooltip(window)
        end
        if NMUIRenderProbe and NMUIRenderProbe.endWindow then
            NMUIRenderProbe.endWindow(window, "slot.media.render", perfStart)
        end
    end

    return {
        button = slotBtn,
        cancelDrag = function() cancelMediaExtractDrag(window) end,
    }
end
