local env = _G.NMWalkmanWindowEnv
setfenv(1, env)

function WalkmanWindow:getLoopIconTexture()
    local resolved = self:resolveContextCached()
    local policy = getLoopPolicy(resolved and resolved.state or nil)
    if policy == "loop_song" then
        return UI_TEXTURES.loopIconSong
    end
    if policy == "loop_album" then
        return UI_TEXTURES.loopIconAlbum
    end
    return UI_TEXTURES.loopIconNone
end

function WalkmanWindow:getLoopIconRect()
    local loopRect = self:getLoopButtonRect()
    local tex = self:getLoopIconTexture()
    local w = tex and tex.getWidthOrig and tex:getWidthOrig() or 39
    local h = tex and tex.getHeightOrig and tex:getHeightOrig() or 29
    local y = loopRect.y + math.floor(((loopRect.h - h) * 0.5) + 0.5)
    return {
        x = LOOP_ICON_X,
        y = y,
        w = w,
        h = h
    }
end

function WalkmanWindow:getLoopModeTooltip()
    local resolved = self:resolveContextCached()
    local policy = getLoopPolicy(resolved and resolved.state or nil)
    if policy == "loop_song" then
        return NMTranslations.ui("WalkmanLoopModeSong", "Loop Mode: Song")
    end
    if policy == "loop_album" then
        return NMTranslations.ui("WalkmanLoopModeAlbum", "Loop Mode: Album")
    end
    return NMTranslations.ui("WalkmanLoopModeNone", "Loop Mode: None")
end

function WalkmanWindow:getPlayButtonTooltip()
    local transport = self:buildTransportState()
    if transport.isPlaying == true then
        return NMTranslations.ui("WalkmanStopPowerOff", "Stop / Power Off")
    end
    return NMTranslations.ui("WalkmanPlayPowerOn", "Play / Power ON")
end

function WalkmanWindow:getHoverTooltipAt(x, y)
    if pointInRect(x, y, self:getLoopButtonRect()) then
        return self:getLoopModeTooltip()
    end
    if pointInRect(x, y, self:getPlayButtonHitRect()) then
        return self:getPlayButtonTooltip()
    end
    if pointInRect(x, y, self:getPrevButtonHitRect()) then
        return NMTranslations.ui("PreviousTrack", "Previous Track")
    end
    if pointInRect(x, y, self:getNextButtonHitRect()) then
        return NMTranslations.ui("NextTrack", "Next Track")
    end
    return nil
end

function WalkmanWindow:updateHoverTooltip()
    local absX = self.getAbsoluteX and self:getAbsoluteX() or 0
    local absY = self.getAbsoluteY and self:getAbsoluteY() or 0
    local localX = (getMouseX and getMouseX() or 0) - absX
    local localY = (getMouseY and getMouseY() or 0) - absY
    if localX < 0 or localY < 0 or localX >= self.width or localY >= self.height then
        self.tooltip = nil
        return
    end
    self.tooltip = self:getHoverTooltipAt(localX, localY)
end

function WalkmanWindow:updateTooltipUI()
    local text = tostring(self.tooltip or "")
    if text ~= "" then
        if not self.tooltipUI then
            self.tooltipUI = ISToolTip:new()
            self.tooltipUI:initialise()
            self.tooltipUI:instantiate()
            self.tooltipUI:setOwner(self)
            self.tooltipUI:setVisible(false)
            self.tooltipUI:setAlwaysOnTop(true)
            self.tooltipUI.followMouse = false
        end
        if not self.tooltipUI:getIsVisible() then
            if string.contains and string.contains(text, "\n") then
                self.tooltipUI.maxLineWidth = 1000
            else
                self.tooltipUI.maxLineWidth = 300
            end
            self.tooltipUI:addToUIManager()
            self.tooltipUI:setVisible(true)
        end
        self.tooltipUI.description = text
        self.tooltipUI:setDesiredPosition(getMouseX and getMouseX() or 0, (getMouseY and getMouseY() or 0) + 24)
    elseif self.tooltipUI and self.tooltipUI:getIsVisible() then
        self.tooltipUI:setVisible(false)
        self.tooltipUI:removeFromUIManager()
    end
end

function WalkmanWindow:startPlayButtonAnimation(down)
    local targetY = self:getPlayButtonY(down)
    local currentY = tonumber(self.playButtonCurrentY) or self:getPlayButtonY(self.isPlayButtonDown)
    self.isPlayButtonDown = (down == true)
    if currentY == targetY then
        self.isPlayButtonAnimating = false
        self.playButtonCurrentY = targetY
        return
    end
    self.isPlayButtonAnimating = true
    self.playButtonAnimStartY = currentY
    self.playButtonAnimTargetY = targetY
    self.playButtonAnimStartTime = getNowMs()
end

function WalkmanWindow:canUseTransportButtons()
    return self:hasInsertedCassette() == true
end

function WalkmanWindow:playTransportNoMediaFeedback()
    playWalkmanTransportSound(self, false)
end

function WalkmanWindow:startPlayButtonTap()
    if self.isPlayButtonAnimating == true then
        return
    end
    self.isPlayButtonAnimating = true
    self.playButtonPhase = "down"
    self.playButtonAnimStartY = tonumber(self.playButtonCurrentY) or self:getPlayButtonY(false)
    self.playButtonAnimTargetY = self:getPlayButtonY(true)
    self.playButtonAnimStartTime = getNowMs()
end

function WalkmanWindow:handlePlayButtonActivate()
    if self:canUseTransportButtons() ~= true then
        self:playTransportNoMediaFeedback()
        self:startPlayButtonTap()
        return true
    end
    local transport = self:buildTransportState()
    if transport.isPlaying == true then
        self:dispatch("toggle_power", { isOn = false })
    else
        local canStartPlayback = true
        if transport.isOn ~= true then
            local poweredOn = self:dispatch("toggle_power", { isOn = true })
            canStartPlayback = (poweredOn == true)
        end
        if canStartPlayback == true then
            self:dispatch("start_playback", { isPlaying = true, trackCount = transport.trackCount })
        end
    end
    self:syncPlayButtonFromTransport(nil, true, false)
    return true
end

function WalkmanWindow:handlePrevButtonActivate()
    if self:canUseTransportButtons() ~= true then
        self:playTransportNoMediaFeedback()
        self:startPrevButtonPress()
        return true
    end
    local transport = self:buildTransportState()
    local ok = self:dispatch("prev_track", { trackCount = transport.trackCount })
    if ok == true then
        playWalkmanTransportSound(self, false)
        self:startPrevButtonPress()
    end
    return true
end

function WalkmanWindow:handleNextButtonActivate()
    if self:canUseTransportButtons() ~= true then
        self:playTransportNoMediaFeedback()
        self:startNextButtonPress()
        return true
    end
    local transport = self:buildTransportState()
    local ok = self:dispatch("next_track", { trackCount = transport.trackCount })
    if ok == true then
        playWalkmanTransportSound(self, false)
        self:startNextButtonPress()
    end
    return true
end

function WalkmanWindow:buildTransportState(resolved)
    local ctx = resolved or self:resolveContextCached()
    local state = ctx and ctx.state or nil
    return {
        isPlaying = state and state.isPlaying == true,
        isOn = state and state.isOn == true,
        trackCount = resolveTrackCount(state),
        playbackPolicy = getLoopPolicy(state),
        volume = clamp01(state and state.volume or 1.0),
    }
end

function WalkmanWindow:syncPlayButtonFromTransport(resolved, playSound, snap)
    local transport = self:buildTransportState(resolved)
    local shouldBeDown = transport.isPlaying == true
    local hasObserved = self._nmHasObservedPlayState == true
    local previous = self._nmAuthoritativePlayDown == true

    self._nmAuthoritativePlayDown = shouldBeDown
    self._nmHasObservedPlayState = true

    if (not hasObserved) or snap == true then
        self.isPlayButtonDown = shouldBeDown
        self.isPlayButtonAnimating = false
        self.playButtonAnimStartY = nil
        self.playButtonAnimTargetY = nil
        self.playButtonAnimStartTime = nil
        self.playButtonCurrentY = self:getPlayButtonY(shouldBeDown)
        return transport
    end

    if previous ~= shouldBeDown then
        self:startPlayButtonAnimation(shouldBeDown)
        if playSound ~= false then
            playWalkmanTransportSound(self, not shouldBeDown)
        end
    elseif self.isPlayButtonAnimating ~= true then
        self.isPlayButtonDown = shouldBeDown
        self.playButtonCurrentY = self:getPlayButtonY(shouldBeDown)
    end

    return transport
end

function WalkmanWindow:startPrevButtonPress()
    if self.isPrevButtonAnimating == true then
        return
    end
    self.isPrevButtonAnimating = true
    self.prevButtonPhase = "down"
    self.prevButtonAnimStartY = tonumber(self.prevButtonCurrentY) or self:getPrevButtonY(false)
    self.prevButtonAnimTargetY = self:getPrevButtonY(true)
    self.prevButtonAnimStartTime = getNowMs()
end

function WalkmanWindow:startNextButtonPress()
    if self.isNextButtonAnimating == true then
        return
    end
    self.isNextButtonAnimating = true
    self.nextButtonPhase = "down"
    self.nextButtonAnimStartY = tonumber(self.nextButtonCurrentY) or self:getNextButtonY(false)
    self.nextButtonAnimTargetY = self:getNextButtonY(true)
    self.nextButtonAnimStartTime = getNowMs()
end

function WalkmanWindow:startLoopButtonPress()
    if self.isLoopButtonAnimating == true then
        return
    end
    self.isLoopButtonAnimating = true
    self.loopButtonPhase = "down"
    self.loopButtonAnimStartX = tonumber(self.loopButtonCurrentX) or self:getLoopButtonX(false)
    self.loopButtonAnimTargetX = self:getLoopButtonX(true)
    self.loopButtonAnimStartTime = getNowMs()
end

