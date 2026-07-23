local env = _G.NMWalkmanWindowEnv
setfenv(1, env)

local function autoCloseThresholdSq()
    return NMDeviceUIRange.getWorldInteractionRangeSq and NMDeviceUIRange.getWorldInteractionRangeSq() or (2.8 * 2.8)
end

local function autoCloseProbeEnabled()
    return NMCore and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("uiAutoCloseProbe") == true
end

local function autoCloseWindowKey(window)
    local target = window and window.target or nil
    if not target then
        return "none"
    end
    return table.concat({
        tostring(target.kind or "item"),
        tostring(target.itemId or ""),
        tostring(target.uuid or "")
    }, "|")
end

local function autoCloseProbe(window, tag, detail, throttleMs)
    if not autoCloseProbeEnabled() then
        return
    end
    if not (NMCore and NMCore.logChannel and NMCore.shouldLogEvery) then
        return
    end
    local nowMs = getNowMs and getNowMs() or 0
    local key = "uiAutoCloseProbe.walkman." .. tostring(tag or "unknown") .. "." .. autoCloseWindowKey(window)
    if not NMCore.shouldLogEvery(key, nowMs, throttleMs or 1000) then
        return
    end
    NMCore.logChannel("uiAutoCloseProbe", tostring(tag or "autoclose"), tostring(detail or ""))
end

function WalkmanWindow:shouldAutoCloseForDistance()
    local player = getPlayer(self.playerNum)
    if not (player and player.DistToSquared) then
        autoCloseProbe(self, "autoclose_skip", "ui=walkman reason=no_player_or_dist", 1000)
        return false
    end

    local target = self.target
    if target and target.kind == "item" then
        local item = target.itemRef
        local location = NMDeviceUIRange.resolvePortableTargetLocation and NMDeviceUIRange.resolvePortableTargetLocation(target, item) or nil
        if location and location.mode == "detached_placed" then
            local distSqDetached = tonumber(player:DistToSquared(location.x, location.y)) or 0
            local thresholdSq = autoCloseThresholdSq()
            autoCloseProbe(
                self,
                "autoclose_detached",
                string.format(
                    "ui=walkman result=%s distSq=%.3f thresholdSq=%.3f x=%.2f y=%.2f",
                    tostring(distSqDetached > thresholdSq),
                    distSqDetached,
                    thresholdSq,
                    tonumber(location.x) or 0,
                    tonumber(location.y) or 0
                ),
                750
            )
            return distSqDetached > thresholdSq
        end
        if location and location.mode == "placed_world" then
            local distSqFast = tonumber(player:DistToSquared(location.x, location.y)) or 0
            local thresholdSq = autoCloseThresholdSq()
            autoCloseProbe(
                self,
                "autoclose_fast_item",
                string.format(
                    "ui=walkman result=%s distSq=%.3f thresholdSq=%.3f square=%d,%d,%d itemId=%s",
                    tostring(distSqFast > thresholdSq),
                    distSqFast,
                    thresholdSq,
                    location.square:getX(),
                    location.square:getY(),
                    location.square:getZ(),
                    tostring(target.itemId or "")
                ),
                750
            )
            return distSqFast > thresholdSq
        end
        if location and location.mode == "inventory" then
            autoCloseProbe(self, "autoclose_skip", "ui=walkman reason=item_in_inventory", 1000)
            return false
        end
        if location and location.mode == "unresolved" then
            autoCloseProbe(self, "autoclose_item_ref", "ui=walkman reason=item_ref_unresolved", 1000)
        end
    end

    local resolved = self:resolveContext()
    if not resolved then
        autoCloseProbe(self, "autoclose_resolve", "ui=walkman result=true reason=resolved_nil", 750)
        return true
    end
    local location = NMDeviceUIRange.resolvePortableTargetLocation and NMDeviceUIRange.resolvePortableTargetLocation(target, resolved.item) or nil
    if location and location.mode == "inventory" then
        autoCloseProbe(self, "autoclose_resolve", "ui=walkman result=false reason=resolved_inventory_item", 1000)
        return false
    end
    if not location or not location.requiresDistanceCheck then
        autoCloseProbe(self, "autoclose_resolve", "ui=walkman result=false reason=no_position", 1000)
        return false
    end
    local distSq = tonumber(player:DistToSquared(location.x, location.y)) or 0
    local thresholdSq = autoCloseThresholdSq()
    autoCloseProbe(
        self,
        "autoclose_resolve",
        string.format(
            "ui=walkman result=%s mode=%s distSq=%.3f thresholdSq=%.3f x=%.2f y=%.2f",
            tostring(distSq > thresholdSq),
            tostring(location.mode or ""),
            distSq,
            thresholdSq,
            tonumber(location.x) or 0,
            tonumber(location.y) or 0
        ),
        750
    )
    return distSq > thresholdSq
end

function WalkmanWindow:update()
    ISPanel.update(self)

    local nowMs = getNowMs()
    local lastDistanceCheckMs = tonumber(self._nmLastDistanceCheckMs) or 0
    if (nowMs - lastDistanceCheckMs) >= 250 then
        self._nmLastDistanceCheckMs = nowMs
        autoCloseProbe(
            self,
            "autoclose_tick",
            string.format(
                "ui=walkman polled=true nowMs=%s lastMs=%s delta=%s",
                tostring(nowMs),
                tostring(lastDistanceCheckMs),
                tostring(nowMs - lastDistanceCheckMs)
            ),
            750
        )
        if self:shouldAutoCloseForDistance() then
            self:close()
            return
        end
    else
        autoCloseProbe(
            self,
            "autoclose_tick",
            string.format(
                "ui=walkman polled=false nowMs=%s lastMs=%s delta=%s",
                tostring(nowMs),
                tostring(lastDistanceCheckMs),
                tostring(nowMs - lastDistanceCheckMs)
            ),
            2000
        )
    end

    self:updateHoverTooltip()
    self:updateTooltipUI()
    self:updateCassetteSpoolAngles(nowMs)
    self:setX(self:clampWindowX(self:getX()))
    self._nmExpandedY = self:getExpandedY()
    if self._nmWheelDragging ~= true then
        self:syncVolumeWheelFromState(false)
    end
    self:syncPlayButtonFromTransport(nil, true, false)
    self:syncLidFromMedia(false)

    if self.isLidAnimating == true then
        local elapsed = math.max(0, nowMs - (tonumber(self.lidAnimStartTime) or 0))
        local t = math.min(1.0, elapsed / LID_ANIMATION_DURATION_MS)
        local eased = 1.0 - ((1.0 - t) * (1.0 - t))
        local startY = tonumber(self.lidAnimStartY) or (self.isLidOpen == true and LID_Y or LID_OPEN_Y)
        local targetY = tonumber(self.lidAnimTargetY) or (self.isLidOpen == true and LID_OPEN_Y or LID_Y)
        local startH = tonumber(self.lidAnimStartH) or (self.isLidOpen == true and LID_H or LID_OPEN_H)
        local targetH = tonumber(self.lidAnimTargetH) or (self.isLidOpen == true and LID_OPEN_H or LID_H)
        local nextY = startY + ((targetY - startY) * eased)
        local nextH = startH + ((targetH - startH) * eased)
        self.lidCurrentY = math.floor(nextY + 0.5)
        self.lidCurrentH = math.floor(nextH + 0.5)
        if t >= 1.0 then
            self.isLidAnimating = false
            self.lidCurrentY = targetY
            self.lidCurrentH = targetH
        end
    end

    if self.isPlayButtonAnimating == true then
        local elapsed = math.max(0, nowMs - (tonumber(self.playButtonAnimStartTime) or 0))
        local t = math.min(1.0, elapsed / PLAY_BUTTON_ANIMATION_DURATION_MS)
        local eased = 1.0 - ((1.0 - t) * (1.0 - t))
        local startY = tonumber(self.playButtonAnimStartY) or self:getPlayButtonY(not self.isPlayButtonDown)
        local targetY = tonumber(self.playButtonAnimTargetY) or self:getPlayButtonY(self.isPlayButtonDown)
        local y = startY + ((targetY - startY) * eased)
        self.playButtonCurrentY = math.floor(y + 0.5)
        if t >= 1.0 then
            if self.playButtonPhase == "down" then
                self.playButtonPhase = "up"
                self.playButtonAnimStartY = targetY
                self.playButtonAnimTargetY = self:getPlayButtonY(false)
                self.playButtonAnimStartTime = getNowMs()
            else
                self.isPlayButtonAnimating = false
                self.playButtonPhase = nil
                self.playButtonCurrentY = self:getPlayButtonY(self.isPlayButtonDown == true)
                self.playButtonAnimStartY = nil
                self.playButtonAnimTargetY = nil
                self.playButtonAnimStartTime = nil
            end
        end
    end

    if self.isPrevButtonAnimating == true then
        local elapsed = math.max(0, nowMs - (tonumber(self.prevButtonAnimStartTime) or 0))
        local t = math.min(1.0, elapsed / PREV_BUTTON_ANIMATION_PHASE_MS)
        local eased = 1.0 - ((1.0 - t) * (1.0 - t))
        local startY = tonumber(self.prevButtonAnimStartY) or self:getPrevButtonY(false)
        local targetY = tonumber(self.prevButtonAnimTargetY) or self:getPrevButtonY(false)
        local y = startY + ((targetY - startY) * eased)
        self.prevButtonCurrentY = math.floor(y + 0.5)
        if t >= 1.0 then
            if self.prevButtonPhase == "down" then
                self.prevButtonPhase = "up"
                self.prevButtonAnimStartY = targetY
                self.prevButtonAnimTargetY = self:getPrevButtonY(false)
                self.prevButtonAnimStartTime = getNowMs()
            else
                self.isPrevButtonAnimating = false
                self.prevButtonPhase = nil
                self.prevButtonCurrentY = self:getPrevButtonY(false)
                self.prevButtonAnimStartY = nil
                self.prevButtonAnimTargetY = nil
                self.prevButtonAnimStartTime = nil
            end
        end
    end

    if self.isNextButtonAnimating == true then
        local elapsed = math.max(0, nowMs - (tonumber(self.nextButtonAnimStartTime) or 0))
        local t = math.min(1.0, elapsed / PREV_BUTTON_ANIMATION_PHASE_MS)
        local eased = 1.0 - ((1.0 - t) * (1.0 - t))
        local startY = tonumber(self.nextButtonAnimStartY) or self:getNextButtonY(false)
        local targetY = tonumber(self.nextButtonAnimTargetY) or self:getNextButtonY(false)
        local y = startY + ((targetY - startY) * eased)
        self.nextButtonCurrentY = math.floor(y + 0.5)
        if t >= 1.0 then
            if self.nextButtonPhase == "down" then
                self.nextButtonPhase = "up"
                self.nextButtonAnimStartY = targetY
                self.nextButtonAnimTargetY = self:getNextButtonY(false)
                self.nextButtonAnimStartTime = getNowMs()
            else
                self.isNextButtonAnimating = false
                self.nextButtonPhase = nil
                self.nextButtonCurrentY = self:getNextButtonY(false)
                self.nextButtonAnimStartY = nil
                self.nextButtonAnimTargetY = nil
                self.nextButtonAnimStartTime = nil
            end
        end
    end

    if self.isLoopButtonAnimating == true then
        local elapsed = math.max(0, nowMs - (tonumber(self.loopButtonAnimStartTime) or 0))
        local t = math.min(1.0, elapsed / LOOP_BUTTON_ANIMATION_PHASE_MS)
        local eased = 1.0 - ((1.0 - t) * (1.0 - t))
        local startX = tonumber(self.loopButtonAnimStartX) or self:getLoopButtonX(false)
        local targetX = tonumber(self.loopButtonAnimTargetX) or self:getLoopButtonX(false)
        local x = startX + ((targetX - startX) * eased)
        self.loopButtonCurrentX = math.floor(x + 0.5)
        if t >= 1.0 then
            if self.loopButtonPhase == "down" then
                self.loopButtonPhase = "up"
                self.loopButtonAnimStartX = targetX
                self.loopButtonAnimTargetX = self:getLoopButtonX(false)
                self.loopButtonAnimStartTime = getNowMs()
            else
                self.isLoopButtonAnimating = false
                self.loopButtonPhase = nil
                self.loopButtonCurrentX = self:getLoopButtonX(false)
                self.loopButtonAnimStartX = nil
                self.loopButtonAnimTargetX = nil
                self.loopButtonAnimStartTime = nil
            end
        end
    end

    if self._nmWheelDragging == true then
        self:flushVolumeWheelDispatch(false)
    end

    if self.draggingHeader == true then
        self:setY(self:getExpandedY())
        return
    end

    if self.isAnimating == true then
        local elapsed = math.max(0, nowMs - (tonumber(self.animStartTime) or 0))
        local t = math.min(1.0, elapsed / ANIMATION_DURATION_MS)
        local eased = 1.0 - ((1.0 - t) * (1.0 - t))
        local startY = tonumber(self.animStartY) or self:getY()
        local targetY = tonumber(self.animTargetY) or self:getStateY(self.isCollapsed)
        local y = startY + ((targetY - startY) * eased)
        self:setY(math.floor(y + 0.5))
        if t >= 1.0 then
            self.isAnimating = false
            self:setY(targetY)
        end
        return
    end

    self:setY(self:getStateY(self.isCollapsed))
end

