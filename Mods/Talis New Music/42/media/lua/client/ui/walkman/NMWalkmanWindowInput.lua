local env = _G.NMWalkmanWindowEnv
setfenv(1, env)

function WalkmanWindow:onMouseDown(x, y)
    if NMPortableMediaDropArbiter and NMPortableMediaDropArbiter.markWindowInteraction then
        NMPortableMediaDropArbiter.markWindowInteraction(self, "walkman")
    end
    if pointInRect(x, y, self:getCloseRect()) then
        self._nmClosePressed = true
        return true
    end

    if pointInRect(x, y, self:getPlayButtonHitRect()) then
        self._nmPlayButtonPressed = true
        return true
    end

    if pointInRect(x, y, self:getPrevButtonHitRect()) then
        self._nmPrevButtonPressed = true
        return true
    end

    if pointInRect(x, y, self:getNextButtonHitRect()) then
        self._nmNextButtonPressed = true
        return true
    end

    if pointInRect(x, y, self:getVolumeWheelHitRect()) then
        self._nmWheelDragging = true
        self._nmWheelDragStartMouseY = getMouseY and getMouseY() or y
        self:syncVolumeWheelFromState(true)
        self._nmWheelDragStartVolume = tonumber(self._nmWheelPreviewVolume) or tonumber(self._nmWheelStableVolume) or 1.0
        syncWalkmanVolumeClickPercent(self, volumeToPercent(self._nmWheelDragStartVolume), false)
        self._nmWheelPendingDispatchVolume = nil
        self:setVolumePreviewFromMouseY(getMouseY and getMouseY() or y)
        self:flushVolumeWheelDispatch(false)
        return true
    end

    if pointInRect(x, y, self:getLoopButtonRect()) then
        self._nmLoopButtonPressed = true
        return true
    end

    if pointInRect(x, y, self:getLidArrowRect()) then
        self._nmLidArrowPressed = true
        return true
    end

    if self:isHeaderHit(x, y) then
        if self.isAnimating == true then
            self:snapToState(self.isCollapsed)
        end
        self.headerPressed = true
        self.draggingHeader = false
        self.headerPressX = getMouseX and getMouseX() or 0
        self.headerPressY = getMouseY and getMouseY() or 0
        self.dragStartWindowX = self:getX()
        self.dragStartWindowY = self.isCollapsed == true and self:getExpandedY() or self:getY()
        self.interactionSuppressedToggle = false
        return true
    end

    return true
end

function WalkmanWindow:onMouseUp(x, y)
    local portableInteraction = rawget(_G, "NMPortableMediaInteraction") or nil
    if portableInteraction and portableInteraction.finalizePendingExtract then
        portableInteraction.finalizePendingExtract()
    end
    if NMBatterySlot and NMBatterySlot.finalizeExtractDrag then
        NMBatterySlot.finalizeExtractDrag(self)
    end
    if NMHeadphoneSlot and NMHeadphoneSlot.finalizeExtractDrag then
        NMHeadphoneSlot.finalizeExtractDrag(self)
    end

    local shouldClose = self._nmClosePressed == true and pointInRect(x, y, self:getCloseRect())
    self._nmClosePressed = false
    if shouldClose then
        self:close()
        return true
    end

    local shouldTogglePlay = self._nmPlayButtonPressed == true and pointInRect(x, y, self:getPlayButtonHitRect())
    self._nmPlayButtonPressed = false
    if shouldTogglePlay then
        return self:handlePlayButtonActivate()
    end

    local shouldPressPrev = self._nmPrevButtonPressed == true and pointInRect(x, y, self:getPrevButtonHitRect())
    self._nmPrevButtonPressed = false
    if shouldPressPrev then
        return self:handlePrevButtonActivate()
    end

    local shouldPressNext = self._nmNextButtonPressed == true and pointInRect(x, y, self:getNextButtonHitRect())
    self._nmNextButtonPressed = false
    if shouldPressNext then
        return self:handleNextButtonActivate()
    end

    if self._nmWheelDragging == true then
        self._nmWheelDragging = false
        self:flushVolumeWheelDispatch(true)
        self:updateVolumeLabelVisibility()
        return true
    end

    local shouldPressLoop = self._nmLoopButtonPressed == true and pointInRect(x, y, self:getLoopButtonRect())
    self._nmLoopButtonPressed = false
    if shouldPressLoop then
        local resolved = self:resolveContextCached()
        local nextPolicy = getNextLoopPolicy(getLoopPolicy(resolved and resolved.state or nil))
        local ok = self:dispatch("set_playback_policy", { playbackPolicy = nextPolicy })
        if ok == true then
            playWalkmanTransportSound(self, false)
            self:startLoopButtonPress()
            self:updateLoopIconVisibility()
        end
        return true
    end

    local shouldPressLidArrow = self._nmLidArrowPressed == true and pointInRect(x, y, self:getLidArrowRect())
    self._nmLidArrowPressed = false
    if shouldPressLidArrow then
        if self:hasInsertedCassette() == true then
            self:ejectMediaViaLid()
        else
            self.isLidManuallyOpen = not (self.isLidManuallyOpen == true)
            self:syncLidFromMedia(false)
        end
        return true
    end

    if pointInRect(x, y, self:getLidIngressZoneRect()) and self:shouldShowLidIngressZone() then
        if self:insertDraggedMediaViaLid() == true then
            return true
        end
    end

    local shouldToggle = self.headerPressed == true
        and self.draggingHeader ~= true
        and self.interactionSuppressedToggle ~= true
        and self:isHeaderHit(x, y)
    self:finishHeaderInteraction()
    if shouldToggle then
        self:toggleCollapsed()
    end
    return true
end

function WalkmanWindow:onMouseUpOutside(x, y)
    local portableInteraction = rawget(_G, "NMPortableMediaInteraction") or nil
    if portableInteraction and portableInteraction.finalizePendingExtract then
        portableInteraction.finalizePendingExtract()
    end
    if NMBatterySlot and NMBatterySlot.finalizeExtractDrag then
        NMBatterySlot.finalizeExtractDrag(self)
    end
    if NMHeadphoneSlot and NMHeadphoneSlot.finalizeExtractDrag then
        NMHeadphoneSlot.finalizeExtractDrag(self)
    end
    self._nmClosePressed = false
    self._nmPlayButtonPressed = false
    self._nmPrevButtonPressed = false
    self._nmNextButtonPressed = false
    self._nmLoopButtonPressed = false
    self._nmLidArrowPressed = false
    if self._nmWheelDragging == true then
        self._nmWheelDragging = false
        self:flushVolumeWheelDispatch(true)
        self:updateVolumeLabelVisibility()
    end
    self:finishHeaderInteraction()
    return true
end

function WalkmanWindow:onMouseMove(dx, dy)
    if self._nmWheelDragging == true then
        self:setVolumePreviewFromMouseY(getMouseY and getMouseY() or 0)
        return true
    end
    self:updateHoverTooltip()
    self:updateHeaderDrag()
    return true
end

function WalkmanWindow:onMouseMoveOutside(dx, dy)
    if self._nmWheelDragging == true then
        self:setVolumePreviewFromMouseY(getMouseY and getMouseY() or 0)
        return true
    end
    self.tooltip = nil
    self:updateHeaderDrag()
    return true
end

function WalkmanWindow:onMouseWheel(del)
    local localX = (getMouseX and getMouseX() or 0) - (self.getAbsoluteX and self:getAbsoluteX() or 0)
    local localY = (getMouseY and getMouseY() or 0) - (self.getAbsoluteY and self:getAbsoluteY() or 0)
    if not pointInRect(localX, localY, self:getVolumeWheelHitRect()) then
        return false
    end
    local wheelDelta = math.floor(tonumber(del) or 0)
    if wheelDelta == 0 then
        return true
    end
    self:syncVolumeWheelFromState(true)
    self:adjustVolumeWheelByStep(-wheelDelta)
    return true
end
