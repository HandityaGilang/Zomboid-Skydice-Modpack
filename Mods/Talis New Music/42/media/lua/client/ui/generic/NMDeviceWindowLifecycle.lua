local env = _G.NMDeviceWindowEnv
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
    if target.kind == "vehicle" then
        return table.concat({
            "vehicle",
            tostring(target.vehicleId or ""),
            tostring(target.partId or "")
        }, "|")
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
    local nowMs = 0
    if getTimestampMs then
        nowMs = tonumber(getTimestampMs()) or 0
    end
    if nowMs <= 0 and getTimestamp then
        nowMs = (tonumber(getTimestamp()) or 0) * 1000
    end
    if nowMs <= 0 and getTimeInMillis then
        nowMs = tonumber(getTimeInMillis()) or 0
    end
    local key = "uiAutoCloseProbe.generic." .. tostring(tag or "unknown") .. "." .. autoCloseWindowKey(window)
    if not NMCore.shouldLogEvery(key, nowMs, throttleMs or 1000) then
        return
    end
    NMCore.logChannel("uiAutoCloseProbe", tostring(tag or "autoclose"), tostring(detail or ""))
end

function DeviceWindow:prerender()
    local perfStart = NMUIRenderProbe and NMUIRenderProbe.beginWindow and NMUIRenderProbe.beginWindow(self) or nil
    self:beginFrameEpoch("prerender")
    self:invalidateSlotFrameModel()
    self:invalidateRenderModel()
    self:buildRenderModel()
    if NMHeadphoneSlot and NMHeadphoneSlot.ensureGhostOverlay then
        NMHeadphoneSlot.ensureGhostOverlay()
    end
    ISCollapsableWindow.prerender(self)
    if NMUIRenderProbe and NMUIRenderProbe.endWindow then
        NMUIRenderProbe.endWindow(self, "device.prerender", perfStart)
    end
end

function DeviceWindow:render()
    local perfFrame = NMUIRenderProbe and NMUIRenderProbe.beginWindow and NMUIRenderProbe.beginWindow(self) or nil
    local perfRender = NMUIRenderProbe and NMUIRenderProbe.beginWindow and NMUIRenderProbe.beginWindow(self) or nil
    if self.volumeFader then
        self.volumeFader:setX(self.width - EDGE_PAD - FADER_W)
    end
    ISCollapsableWindow.render(self)
    self:logFrameDiagnostics()
    if NMUIRenderProbe and NMUIRenderProbe.endWindow then
        NMUIRenderProbe.endWindow(self, "device.render", perfRender)
        NMUIRenderProbe.endWindow(self, "device.frame", perfFrame)
    end
    if NMUIRenderProbe and NMUIRenderProbe.flush then
        NMUIRenderProbe.flush(self)
    end
end

function DeviceWindow:onMouseUp(x, y)
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
    return ISCollapsableWindow.onMouseUp(self, x, y)
end

function DeviceWindow:onMouseDown(x, y)
    if NMPortableMediaDropArbiter and NMPortableMediaDropArbiter.markWindowInteraction then
        NMPortableMediaDropArbiter.markWindowInteraction(self, "generic")
    end
    return ISCollapsableWindow.onMouseDown(self, x, y)
end

function DeviceWindow:onMouseUpOutside(x, y)
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
    return ISCollapsableWindow.onMouseUpOutside(self, x, y)
end

function DeviceWindow:close()
    autoCloseProbe(
        self,
        "autoclose_close",
        string.format(
            "ui=generic player=%s target=%s",
            tostring(self.playerNum or 0),
            tostring(autoCloseWindowKey(self))
        ),
        250
    )
    if NMBatterySlot and NMBatterySlot.cancelExtractDrag then
        NMBatterySlot.cancelExtractDrag(self)
    end
    if NMMediaSlot and NMMediaSlot.cancelExtractDrag then
        NMMediaSlot.cancelExtractDrag(self)
    end
    if NMHeadphoneSlot and NMHeadphoneSlot.cancelExtractDrag then
        NMHeadphoneSlot.cancelExtractDrag(self)
    end
    ISCollapsableWindow.close(self)
end

function DeviceWindow:shouldAutoCloseForDistance()
    local perfStart = NMUIRenderProbe and NMUIRenderProbe.beginWindow and NMUIRenderProbe.beginWindow(self) or nil
    local player = getPlayer(self.playerNum)
    if not (player and player.DistToSquared) then
        autoCloseProbe(self, "autoclose_skip", "ui=generic reason=no_player_or_dist", 1000)
        if NMUIRenderProbe and NMUIRenderProbe.endWindow then
            NMUIRenderProbe.endWindow(self, "device.autoCloseCheck", perfStart)
        end
        return false
    end

    -- Fast path: avoid full context resolution for common cases.
    local target = self.target
    if target and target.kind == "item" then
        local item = target.itemRef
        local location = NMDeviceUIRange.resolvePortableTargetLocation and NMDeviceUIRange.resolvePortableTargetLocation(target, item) or nil
        if location and location.mode == "detached_placed" then
            if NMUIRenderProbe and NMUIRenderProbe.count then
                NMUIRenderProbe.count(self, "autoclose.detached", 1)
            end
            local distSqDetached = tonumber(player:DistToSquared(location.x, location.y)) or 0
            local thresholdSq = autoCloseThresholdSq()
            autoCloseProbe(
                self,
                "autoclose_detached",
                string.format(
                    "ui=generic result=%s distSq=%.3f thresholdSq=%.3f x=%.2f y=%.2f",
                    tostring(distSqDetached > thresholdSq),
                    distSqDetached,
                    thresholdSq,
                    tonumber(location.x) or 0,
                    tonumber(location.y) or 0
                ),
                750
            )
            if NMUIRenderProbe and NMUIRenderProbe.endWindow then
                NMUIRenderProbe.endWindow(self, "device.autoCloseCheck", perfStart)
            end
            return distSqDetached > thresholdSq
        end
        if location and location.mode == "placed_world" then
            if NMUIRenderProbe and NMUIRenderProbe.count then
                NMUIRenderProbe.count(self, "autoclose.fast", 1)
            end
            local distSqFast = tonumber(player:DistToSquared(location.x, location.y)) or 0
            local thresholdSq = autoCloseThresholdSq()
            autoCloseProbe(
                self,
                "autoclose_fast_item",
                string.format(
                    "ui=generic result=%s distSq=%.3f thresholdSq=%.3f square=%d,%d,%d itemId=%s",
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
            if NMUIRenderProbe and NMUIRenderProbe.endWindow then
                NMUIRenderProbe.endWindow(self, "device.autoCloseCheck", perfStart)
            end
            return distSqFast > thresholdSq
        end
        if location and location.mode == "inventory" then
            autoCloseProbe(self, "autoclose_skip", "ui=generic reason=item_in_inventory", 1000)
            return false
        end
        if location and location.mode == "unresolved" then
            autoCloseProbe(self, "autoclose_item_ref", "ui=generic reason=item_ref_unresolved", 1000)
        end
    elseif target and target.kind == "vehicle" then
        local vehicle = target.vehicleRef
        if vehicle and vehicle.getX and vehicle.getY then
            if NMUIRenderProbe and NMUIRenderProbe.count then
                NMUIRenderProbe.count(self, "autoclose.fast", 1)
            end
            local distSqFast = tonumber(player:DistToSquared(tonumber(vehicle:getX()) or 0, tonumber(vehicle:getY()) or 0)) or 0
            local thresholdSq = autoCloseThresholdSq()
            autoCloseProbe(
                self,
                "autoclose_fast_vehicle",
                string.format(
                    "ui=generic result=%s distSq=%.3f thresholdSq=%.3f vehicleId=%s",
                    tostring(distSqFast > thresholdSq),
                    distSqFast,
                    thresholdSq,
                    tostring(target.vehicleId or "")
                ),
                750
            )
            if NMUIRenderProbe and NMUIRenderProbe.endWindow then
                NMUIRenderProbe.endWindow(self, "device.autoCloseCheck", perfStart)
            end
            return distSqFast > thresholdSq
        end
    end

    -- Slow path fallback: resolve through canonical context when fast refs are unavailable.
    if NMUIRenderProbe and NMUIRenderProbe.count then
        NMUIRenderProbe.count(self, "autoclose.slow", 1)
    end
    local resolved = self:resolveContext()
    if not resolved then
        autoCloseProbe(self, "autoclose_resolve", "ui=generic result=true reason=resolved_nil", 750)
        if NMUIRenderProbe and NMUIRenderProbe.endWindow then
            NMUIRenderProbe.endWindow(self, "device.autoCloseCheck", perfStart)
        end
        return true
    end
    if resolved.kind == "item" then
        local location = NMDeviceUIRange.resolvePortableTargetLocation and NMDeviceUIRange.resolvePortableTargetLocation(target, resolved.item) or nil
        if location and location.mode == "inventory" then
            autoCloseProbe(self, "autoclose_resolve", "ui=generic result=false reason=resolved_inventory_item", 1000)
            return false
        end
        if not location or not location.requiresDistanceCheck then
            autoCloseProbe(
                self,
                "autoclose_resolve",
                string.format("ui=generic result=false reason=no_position kind=%s", tostring(resolved.kind or "")),
                1000
            )
            return false
        end
        local distSq = tonumber(player:DistToSquared(location.x, location.y)) or 0
        local thresholdSq = autoCloseThresholdSq()
        autoCloseProbe(
            self,
            "autoclose_resolve",
            string.format(
                "ui=generic result=%s kind=%s mode=%s distSq=%.3f thresholdSq=%.3f x=%.2f y=%.2f",
                tostring(distSq > thresholdSq),
                tostring(resolved.kind or ""),
                tostring(location.mode or ""),
                distSq,
                thresholdSq,
                tonumber(location.x) or 0,
                tonumber(location.y) or 0
            ),
            750
        )
        if NMUIRenderProbe and NMUIRenderProbe.endWindow then
            NMUIRenderProbe.endWindow(self, "device.autoCloseCheck", perfStart)
        end
        return distSq > thresholdSq
    end
    autoCloseProbe(self, "autoclose_resolve", "ui=generic result=false reason=non_portable_resolved", 1000)
    if NMUIRenderProbe and NMUIRenderProbe.endWindow then
        NMUIRenderProbe.endWindow(self, "device.autoCloseCheck", perfStart)
    end
    return false
end

function DeviceWindow:update()
    local perfStart = NMUIRenderProbe and NMUIRenderProbe.beginWindow and NMUIRenderProbe.beginWindow(self) or nil
    ISCollapsableWindow.update(self)
    local nowMs = (getTimestampMs and tonumber(getTimestampMs()))
        or (getTimeInMillis and tonumber(getTimeInMillis()))
        or 0
    local lastDistanceCheckMs = tonumber(self._nmLastDistanceCheckMs) or 0
    if (nowMs - lastDistanceCheckMs) >= 250 then
        self._nmLastDistanceCheckMs = nowMs
        autoCloseProbe(
            self,
            "autoclose_tick",
            string.format(
                "ui=generic polled=true nowMs=%s lastMs=%s delta=%s",
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
                "ui=generic polled=false nowMs=%s lastMs=%s delta=%s",
                tostring(nowMs),
                tostring(lastDistanceCheckMs),
                tostring(nowMs - lastDistanceCheckMs)
            ),
            2000
        )
    end

    local lastHeadphoneSyncMs = tonumber(self._nmLastHeadphoneWearSyncMs) or 0
    local idleHeadphonePollMs = 1000
    local activeHeadphonePollMs = 200
    local headphonePollMs = (self._nmHeadphoneWearSyncActive == true) and activeHeadphonePollMs or idleHeadphonePollMs
    if (nowMs - lastHeadphoneSyncMs) >= headphonePollMs then
        self._nmLastHeadphoneWearSyncMs = nowMs
        if NMHeadphoneSlot and NMHeadphoneSlot.tickWearSync and self._nmShowHeadphoneSlot == true then
            self._nmHeadphoneWearSyncActive = (NMHeadphoneSlot.tickWearSync(self, self:resolveContext()) == true)
        else
            self._nmHeadphoneWearSyncActive = false
        end
    end
    if NMUIRenderProbe and NMUIRenderProbe.endWindow then
        NMUIRenderProbe.endWindow(self, "device.update", perfStart)
    end
end
