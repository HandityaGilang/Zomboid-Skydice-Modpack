
local env = _G.NMWalkmanWindowEnv
setfenv(1, env)

local function getButtonScreenRect(button)
    if not button then
        return nil
    end
    local x = button.getAbsoluteX and button:getAbsoluteX() or nil
    local y = button.getAbsoluteY and button:getAbsoluteY() or nil
    local w = tonumber(button.width) or 0
    local h = tonumber(button.height) or 0
    if x == nil or y == nil or w <= 0 or h <= 0 then
        return nil
    end
    return { x = x, y = y, w = w, h = h }
end

local function getWindowScreenRect(window, rect)
    if not (window and rect) then
        return nil
    end
    local ax = window.getAbsoluteX and window:getAbsoluteX() or nil
    local ay = window.getAbsoluteY and window:getAbsoluteY() or nil
    local w = tonumber(rect.w) or 0
    local h = tonumber(rect.h) or 0
    if ax == nil or ay == nil or w <= 0 or h <= 0 then
        return nil
    end
    return {
        x = ax + (tonumber(rect.x) or 0),
        y = ay + (tonumber(rect.y) or 0),
        w = w,
        h = h
    }
end

local function isWindowVisible(window)
    if not (window and window.javaObject) then
        return false
    end
    if window.getIsVisible then
        return window:getIsVisible() == true
    end
    if window.isVisible then
        return window:isVisible() == true
    end
    return true
end

local function getMediaSlotEnv()
    return rawget(_G, "NMMediaSlotEnv") or nil
end

local function isFancyUIEnabled()
    if NMRuntimeConfig and NMRuntimeConfig.getFancyUIEnabled then
        return NMRuntimeConfig.getFancyUIEnabled() == true
    end
    return true
end

function getOrCreateWindow(playerNum)
    local key = tostring(tonumber(playerNum) or 0)
    local existing = windowsByPlayer[key]
    if existing and existing.javaObject then
        return existing
    end

    local screenW, screenH = getScreenSize()
    local x = math.max(0, screenW - PANEL_W - DEFAULT_RIGHT_MARGIN)
    local y = math.max(0, screenH - PANEL_H - EXPANDED_BOTTOM_MARGIN)
    local win = WalkmanWindow:new(x, y, PANEL_W, PANEL_H)
    win.playerNum = tonumber(playerNum) or 0
    win:initialise()
    attachWalkmanSlots(win)
    win:addToUIManager()
    windowsByPlayer[key] = win
    return win
end
function NMWalkmanWindow.openForItem(playerNum, item)
    if not isFancyUIEnabled() then
        return nil
    end
    local player = getPlayer(playerNum)
    if not (player and item) then
        return nil
    end
    local profile = NMDeviceProfiles and NMDeviceProfiles.getForItem and NMDeviceProfiles.getForItem(item) or nil
    if not profile or tostring(profile.deviceType or "") ~= "walkman" then
        return nil
    end

    local win = getOrCreateWindow(playerNum)
    local currentX = tonumber(win:getX())
    local currentY = tonumber(win._nmExpandedY)
    if not currentX then
        local screenW = getScreenSize()
        currentX = math.max(0, screenW - PANEL_W - DEFAULT_RIGHT_MARGIN)
    end
    if currentY == nil then
        currentY = win:getDefaultExpandedY()
    end
    win:setX(win:clampWindowX(currentX))
    win._nmExpandedY = win:clampWindowY(currentY)
    win:snapToState(false)
    win._nmHasObservedPlayState = false
    win._nmAuthoritativePlayDown = false
    win.isPlayButtonAnimating = false
    win.playButtonAnimStartY = nil
    win.playButtonAnimTargetY = nil
    win.playButtonAnimStartTime = nil
    win.playButtonCurrentY = win:getPlayButtonY(false)
    win.isPrevButtonAnimating = false
    win.prevButtonPhase = nil
    win.prevButtonCurrentY = win:getPrevButtonY(false)
    win.prevButtonAnimStartY = nil
    win.prevButtonAnimTargetY = nil
    win.prevButtonAnimStartTime = nil
    win.isNextButtonAnimating = false
    win.nextButtonPhase = nil
    win.nextButtonCurrentY = win:getNextButtonY(false)
    win.nextButtonAnimStartY = nil
    win.nextButtonAnimTargetY = nil
    win.nextButtonAnimStartTime = nil
    win._nmWheelDragging = false
    win._nmWheelStableVolume = nil
    win._nmWheelPreviewVolume = nil
    win._nmWheelPendingDispatchVolume = nil
    win._nmWheelLastDispatchMs = 0
    win._nmWheelLastDispatchedVolume = nil
    win._nmWheelLastClickPercent = nil
    win._nmWheelLastClickSoundMs = 0
    win._nmWheelLabelVisibleUntil = 0
    win._nmLoopIconVisibleUntil = 0
    win._nmWheelDragStartMouseY = nil
    win._nmWheelDragStartVolume = nil
    win._nmLoopButtonPressed = false
    win.isLoopButtonAnimating = false
    win.loopButtonPhase = nil
    win.loopButtonCurrentX = win:getLoopButtonX(false)
    win.loopButtonAnimStartX = nil
    win.loopButtonAnimTargetX = nil
    win.loopButtonAnimStartTime = nil
    win._nmLeftSpoolAngle = 0.0
    win._nmRightSpoolAngle = 0.0
    win._nmSpoolLastUpdateMs = getNowMs()
    win.isLidAnimating = false
    win.lidAnimStartY = nil
    win.lidAnimStartH = nil
    win.lidAnimTargetY = nil
    win.lidAnimTargetH = nil
    win.lidAnimStartTime = nil
    win.lidCurrentY = LID_OPEN_Y
    win.lidCurrentH = LID_OPEN_H
    win.isLidOpen = true
    win.target = {
        kind = "item",
        itemId = NMCore and NMCore.itemId and NMCore.itemId(item) or nil,
        uuid = NMInventoryHelpers and NMInventoryHelpers.getItemStateUuid and NMInventoryHelpers.getItemStateUuid(item) or nil,
        itemRef = item
    }
    win:invalidateContextCache()
    win:invalidateSlotFrameModel()
    win._nmPendingMediaSlotFullType = nil
    win._nmPendingHeadphoneSlotFullType = nil
    win._nmPendingBatterySlotFullType = nil
    win._nmSlotRemoveInFlightByType = {}
    win._nmLidHadMedia = false
    win._nmMediaEjectInterrupted = nil
    win._nmAwaitingAuthoritativeMediaEject = nil
    win._nmAwaitingAuthoritativeMediaInsert = nil
    win.isLidManuallyOpen = true
    win:syncVolumeWheelFromState(true)
    win:syncPlayButtonFromTransport(nil, false, true)
    win:syncLidFromMedia(true)
    win:setVisible(true)
    win:bringToTop()
    if NMPortableMediaDropArbiter and NMPortableMediaDropArbiter.markWindowInteraction then
        NMPortableMediaDropArbiter.markWindowInteraction(win, "walkman")
    end
    persistWindowState(win, true)
    return win
end

function NMWalkmanWindow.findOpenForItem(playerNum, item)
    local itemId = tostring(NMCore and NMCore.itemId and NMCore.itemId(item) or "")
    if itemId == "" then
        return nil
    end
    local win = windowsByPlayer[tostring(playerNum or 0)] or nil
    if not win then
        return nil
    end
    local target = win.target or nil
    local targetItemId = tostring(target and target.itemId or "")
    if targetItemId ~= itemId then
        return nil
    end
    return win
end

function NMWalkmanWindow.invalidateOpenItemWindow(itemId, uuid)
    local incomingItemId = tostring(itemId or "")
    local incomingUuid = tostring(uuid or "")
    local invalidated = false
    for key, win in pairs(windowsByPlayer) do
        if win and win.javaObject and win.target and win.target.kind == "item" then
            local targetItemId = tostring(win.target.itemId or "")
            if incomingItemId ~= "" and targetItemId ~= "" and incomingItemId == targetItemId then
                local resolved = win.resolveContextFresh and win:resolveContextFresh() or (win.resolveContext and win:resolveContext()) or nil
                local state = resolved and resolved.state or nil
                local targetUuid = tostring(state and state.deviceUUID or "")
                if incomingUuid == "" or targetUuid == "" or incomingUuid == targetUuid then
                    win:invalidateContextCache()
                    win:invalidateSlotFrameModel()
                    invalidated = true
                end
            end
        end
    end
    return invalidated
end

function NMWalkmanWindow.rebindOpenPortableItemWindow(itemId, uuid)
    local incomingItemId = tostring(itemId or "")
    local incomingUuid = tostring(uuid or "")
    if incomingItemId == "" and incomingUuid == "" then
        return false
    end
    local rebound = false
    for key, win in pairs(windowsByPlayer) do
        if win and win.javaObject and win.target and win.target.kind == "item" then
            local targetItemId = tostring(win.target.itemId or "")
            local targetUuid = tostring(win.target.uuid or "")
            if targetItemId == "" or incomingItemId == "" or targetItemId == incomingItemId or targetUuid == incomingUuid then
                local player = getPlayer(win.playerNum)
                if player then
                    local item = resolveLiveItemByTarget(player, {
                        itemId = incomingItemId ~= "" and incomingItemId or targetItemId,
                        uuid = incomingUuid ~= "" and incomingUuid or targetUuid
                    })
                    if item then
                        win.target.itemId = NMCore.itemId(item)
                        win.target.uuid = NMInventoryHelpers and NMInventoryHelpers.getItemStateUuid and NMInventoryHelpers.getItemStateUuid(item) or incomingUuid
                        win.target.itemRef = item
                        win:invalidateContextCache()
                        win:invalidateSlotFrameModel()
                        rebound = true
                    end
                end
            end
        end
    end
    return rebound
end

function NMWalkmanWindow.inspectOpenItemWindowTarget(playerNum)
    local key = tostring(playerNum or 0)
    local win = windowsByPlayer[key] or nil
    if not (win and win.javaObject and win.target and win.target.kind == "item") then
        return nil
    end
    return {
        playerNum = tonumber(win.playerNum) or 0,
        itemId = tostring(win.target.itemId or ""),
        uuid = tostring(win.target.uuid or ""),
        hasItemRef = win.target.itemRef ~= nil,
        mediaTimedAction = tostring(win._nmMediaSlotTimedProgress and win._nmMediaSlotTimedProgress.action or ""),
        pendingMediaFullType = tostring(win._nmPendingMediaSlotFullType or ""),
        awaitingMediaInsert = win:isAwaitingAuthoritativeMediaInsert() == true,
        awaitingMediaEject = win:isAwaitingAuthoritativeMediaEject() == true
    }
end

function NMWalkmanWindow.closeOpenForItemTarget(playerNum, itemId, uuid)
    local win = windowsByPlayer[tostring(playerNum or 0)] or nil
    if not (win and win.target and win.target.kind == "item") then
        return false
    end

    local targetItemId = tostring(win.target.itemId or "")
    local incomingItemId = tostring(itemId or "")
    if incomingItemId == "" or incomingItemId ~= targetItemId then
        return false
    end

    local targetUuid = tostring(win.target.uuid or "")
    local incomingUuid = tostring(uuid or "")
    if incomingUuid ~= "" and targetUuid ~= "" and incomingUuid ~= targetUuid then
        return false
    end

    if NMBatterySlot and NMBatterySlot.cancelExtractDrag then
        NMBatterySlot.cancelExtractDrag(win)
    end
    if NMMediaSlot and NMMediaSlot.cancelExtractDrag then
        NMMediaSlot.cancelExtractDrag(win)
    end
    if NMHeadphoneSlot and NMHeadphoneSlot.cancelExtractDrag then
        NMHeadphoneSlot.cancelExtractDrag(win)
    end
    if win.setVisible then
        win:setVisible(false)
    end
    if win.removeFromUIManager then
        win:removeFromUIManager()
    end
    windowsByPlayer[tostring(playerNum or 0)] = nil
    return true
end

function NMWalkmanWindow.collectOpenMediaIngressZones(playerNum, dragItems)
    local key = tostring(tonumber(playerNum) or 0)
    local win = windowsByPlayer[key] or nil
    if not isWindowVisible(win) then
        return {}
    end
    if not (win.target and win.target.kind == "item") then
        return {}
    end
    local mediaEnv = getMediaSlotEnv()
    local resolveMediaSlotFullTypeFn = mediaEnv and mediaEnv.resolveMediaSlotFullType or nil
    local queueDraggedMediaInsertFn = mediaEnv and mediaEnv.queueDraggedMediaInsert or nil
    local queueMediaSlotEjectFn = mediaEnv and mediaEnv.queueMediaSlotEject or nil
    if not (resolveMediaSlotFullTypeFn and queueDraggedMediaInsertFn and queueMediaSlotEjectFn) then
        return {}
    end
    local zones = {}
    local slotRect = getButtonScreenRect(win.mediaSlot and win.mediaSlot.button or nil)
    if slotRect then
        local resolved = win.resolveContextCached and win:resolveContextCached() or nil
        local state = resolved and resolved.state or nil
        zones[#zones + 1] = {
            uiFamily = "walkman",
            zoneKind = "slot",
            priority = 10,
            zOrder = NMPortableMediaDropArbiter and NMPortableMediaDropArbiter.getWindowZOrder and NMPortableMediaDropArbiter.getWindowZOrder(win) or 0,
            playerNum = tonumber(win.playerNum) or 0,
            itemId = win.target.itemId,
            uuid = win.target.uuid,
            window = win,
            rect = slotRect,
            visible = true,
            enabled = true,
            interactive = true,
            canAccept = type(dragItems) == "table"
                and #dragItems > 0
                and isCompatibleWalkmanMediaDrag(win, dragItems)
                and resolveMediaSlotFullTypeFn(win, state) == ""
                and not (win.isAwaitingAuthoritativeMediaEject and win:isAwaitingAuthoritativeMediaEject() == true),
            canAcceptDraggedMedia = function(items)
                return type(items) == "table"
                    and #items > 0
                    and isCompatibleWalkmanMediaDrag(win, items)
                    and resolveMediaSlotFullTypeFn(win, state) == ""
                    and not (win.isAwaitingAuthoritativeMediaEject and win:isAwaitingAuthoritativeMediaEject() == true)
            end,
            canEjectMedia = function()
                return resolveMediaSlotFullTypeFn(win, state) ~= ""
            end,
            canStartExtractDrag = function()
                return resolveMediaSlotFullTypeFn(win, state) ~= ""
            end,
            performInsertFromDrag = function(items, sourceTag)
                return queueDraggedMediaInsertFn(win, items, sourceTag or "arbiter") == true
            end,
            performBeginExtract = function()
                local resolvedNow = win.resolveContext and win:resolveContext() or nil
                local stateNow = resolvedNow and resolvedNow.state or nil
                local fullTypeNow = resolveMediaSlotFullTypeFn(win, stateNow)
                if fullTypeNow == "" then
                    return false
                end
                if queueDraggedMediaInsertFn and mediaEnv and mediaEnv.beginMediaExtractDrag then
                    mediaEnv.beginMediaExtractDrag(win, fullTypeNow)
                    return true
                end
                return false
            end,
            performEject = function(sourceTag)
                return queueMediaSlotEjectFn(win, sourceTag or "arbiter") == true
            end,
            performShowInsertContext = function(btn, xArg, yArg)
                return mediaEnv and mediaEnv.showMediaInsertContextMenu and mediaEnv.showMediaInsertContextMenu(win, btn, xArg, yArg) == true or false
            end,
            consumeDraggedMediaInsert = function(items, sourceDescriptor)
                return queueDraggedMediaInsertFn(win, items, sourceDescriptor and sourceDescriptor.uiFamily or "handoff") == true
            end,
            beginMediaExtractDrag = function()
                local resolvedNow = win.resolveContext and win:resolveContext() or nil
                local stateNow = resolvedNow and resolvedNow.state or nil
                local fullTypeNow = resolveMediaSlotFullTypeFn(win, stateNow)
                if fullTypeNow == "" then
                    return false
                end
                if queueDraggedMediaInsertFn and mediaEnv and mediaEnv.beginMediaExtractDrag then
                    mediaEnv.beginMediaExtractDrag(win, fullTypeNow)
                    return true
                end
                return false
            end,
            handleRightClick = function(btn, xArg, yArg)
                local resolvedNow = win.resolveContext and win:resolveContext() or nil
                local stateNow = resolvedNow and resolvedNow.state or nil
                local fullTypeNow = resolveMediaSlotFullTypeFn(win, stateNow)
                if fullTypeNow ~= "" then
                    return queueMediaSlotEjectFn(win, "handoff") == true
                end
                return false
            end
        }
    end
    local auxRect = win.getLidIngressZoneRect and getWindowScreenRect(win, win:getLidIngressZoneRect()) or nil
    if auxRect then
        zones[#zones + 1] = {
            uiFamily = "walkman",
            zoneKind = "aux",
            priority = 20,
            zOrder = NMPortableMediaDropArbiter and NMPortableMediaDropArbiter.getWindowZOrder and NMPortableMediaDropArbiter.getWindowZOrder(win) or 0,
            playerNum = tonumber(win.playerNum) or 0,
            itemId = win.target.itemId,
            uuid = win.target.uuid,
            window = win,
            rect = auxRect,
            visible = true,
            enabled = true,
            interactive = true,
            canAccept = win.canAcceptDraggedMediaViaLid and win:canAcceptDraggedMediaViaLid() == true,
            canAcceptDraggedMedia = function(items)
                return win.canAcceptDraggedMediaViaLid and win:canAcceptDraggedMediaViaLid() == true
                    and type(items) == "table"
                    and #items > 0
            end,
            performInsertFromDrag = function(items, sourceTag)
                return queueDraggedMediaInsertFn(win, items, sourceTag or "arbiter") == true
            end,
            consumeDraggedMediaInsert = function(items, sourceDescriptor)
                return queueDraggedMediaInsertFn(win, items, sourceDescriptor and sourceDescriptor.uiFamily or "handoff") == true
            end
        }
    end
    return zones
end

function WalkmanWindow:close()
    if NMBatterySlot and NMBatterySlot.cancelExtractDrag then
        NMBatterySlot.cancelExtractDrag(self)
    end
    if NMMediaSlot and NMMediaSlot.cancelExtractDrag then
        NMMediaSlot.cancelExtractDrag(self)
    end
    if NMHeadphoneSlot and NMHeadphoneSlot.cancelExtractDrag then
        NMHeadphoneSlot.cancelExtractDrag(self)
    end
    if self.tooltipUI then
        self.tooltipUI:setVisible(false)
        if self.tooltipUI.removeFromUIManager then
            self.tooltipUI:removeFromUIManager()
        end
    end
    if self.setVisible then
        self:setVisible(false)
    end
    if self.removeFromUIManager then
        self:removeFromUIManager()
    end
    windowsByPlayer[tostring(self.playerNum or 0)] = nil
end

function WalkmanWindow:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o:noBackground()
    o.keepOnScreen = false
    o.anchorRight = false
    o.anchorBottom = false
    o.moveWithMouse = false
    o.backgroundColor = { a = 0.0, r = 0.0, g = 0.0, b = 0.0 }
    o.borderColor = { a = 0.0, r = 0.0, g = 0.0, b = 0.0 }
    o.playerNum = 0
    o.target = nil
    o._nmClosePressed = false
    o._nmPlayButtonPressed = false
    o._nmPrevButtonPressed = false
    o._nmNextButtonPressed = false
    o._nmLoopButtonPressed = false
    o._nmLidArrowPressed = false
    o.isCollapsed = false
    o.isAnimating = false
    o.animStartY = nil
    o.animTargetY = nil
    o.animStartTime = nil
    o.isPlayButtonDown = false
    o._nmHasObservedPlayState = false
    o._nmAuthoritativePlayDown = false
    o.isPlayButtonAnimating = false
    o.playButtonCurrentY = PLAY_BUTTON_UP_Y
    o.playButtonAnimStartY = nil
    o.playButtonAnimTargetY = nil
    o.playButtonAnimStartTime = nil
    o.isPrevButtonAnimating = false
    o.prevButtonPhase = nil
    o.prevButtonCurrentY = PREV_BUTTON_UP_Y
    o.prevButtonAnimStartY = nil
    o.prevButtonAnimTargetY = nil
    o.prevButtonAnimStartTime = nil
    o.isNextButtonAnimating = false
    o.nextButtonPhase = nil
    o.nextButtonCurrentY = NEXT_BUTTON_UP_Y
    o.nextButtonAnimStartY = nil
    o.nextButtonAnimTargetY = nil
    o.nextButtonAnimStartTime = nil
    o.isLoopButtonAnimating = false
    o.loopButtonPhase = nil
    o.loopButtonCurrentX = LOOP_BUTTON_UP_X
    o.loopButtonAnimStartX = nil
    o.loopButtonAnimTargetX = nil
    o.loopButtonAnimStartTime = nil
    o._nmLeftSpoolAngle = 0.0
    o._nmRightSpoolAngle = 0.0
    o._nmSpoolLastUpdateMs = nil
    o.isLidAnimating = false
    o.lidAnimStartY = nil
    o.lidAnimStartH = nil
    o.lidAnimTargetY = nil
    o.lidAnimTargetH = nil
    o.lidAnimStartTime = nil
    o.lidCurrentY = LID_OPEN_Y
    o.lidCurrentH = LID_OPEN_H
    o.isLidOpen = true
    o.isLidManuallyOpen = true
    o._nmLidHadMedia = false
    o._nmWheelDragging = false
    o._nmWheelStableVolume = 1.0
    o._nmWheelPreviewVolume = 1.0
    o._nmWheelPendingDispatchVolume = nil
    o._nmWheelLastDispatchMs = 0
    o._nmWheelLastDispatchedVolume = nil
    o._nmWheelLastClickPercent = nil
    o._nmWheelLastClickSoundMs = 0
    o._nmWheelLabelVisibleUntil = 0
    o._nmLoopIconVisibleUntil = 0
    o._nmWheelDragStartMouseY = nil
    o._nmWheelDragStartVolume = nil
    o._nmLastDistanceCheckMs = 0
    o.headerPressed = false
    o.draggingHeader = false
    o.headerPressX = nil
    o.headerPressY = nil
    o.dragStartWindowX = nil
    o.dragStartWindowY = nil
    o.interactionSuppressedToggle = false
    o._nmExpandedY = nil
    o._nmLastHeadphoneWearSyncMs = 0
    o._nmHeadphoneWearSyncActive = false
    o._nmFrameEpoch = 0
    o._nmFrameNowMs = 0
    o._nmContextCache = nil
    o._nmContextCacheTargetKey = nil
    o._nmSlotFrameModel = nil
    o._nmSlotFrameModelEpoch = nil
    o._nmPendingMediaSlotFullType = nil
    o._nmPendingHeadphoneSlotFullType = nil
    o._nmPendingBatterySlotFullType = nil
    o._nmSlotRemoveInFlightByType = {}
    o._nmMediaEjectInterrupted = nil
    o._nmAwaitingAuthoritativeMediaEject = nil
    o._nmAwaitingAuthoritativeMediaInsert = nil
    o._nmSlotsAttached = false
    return o
end

return NMWalkmanWindow
