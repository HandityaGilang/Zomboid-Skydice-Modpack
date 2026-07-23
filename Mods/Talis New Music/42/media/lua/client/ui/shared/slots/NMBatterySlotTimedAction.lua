local env = _G.NMBatterySlotEnv
setfenv(1, env)

NMBatterySlotTimedAction = NMBatterySlotTimedAction or ISBaseTimedAction:derive("NMBatterySlotTimedAction")

function NMBatterySlotTimedAction:isValid()
    return self.window ~= nil and self.actionName ~= nil and self.actionName ~= ""
end

function NMBatterySlotTimedAction:waitToStart()
    return false
end

function NMBatterySlotTimedAction:start()
    if self.window then
        self.window._nmBatterySlotTimedProgress = { active = true, delta = 0.0, action = self.actionName }
        if self.window.invalidateContextCache then
            self.window:invalidateContextCache()
        end
        if self.window.invalidateSlotFrameModel then
            self.window:invalidateSlotFrameModel()
        end
        if self.window.invalidateRenderModel then
            self.window:invalidateRenderModel()
        end
    end
end

function NMBatterySlotTimedAction:update()
    local delta = 0.0
    if self.action and self.action.getJobDelta then
        delta = tonumber(self.action:getJobDelta()) or 0.0
    end
    if self.window then
        self.window._nmBatterySlotTimedProgress = {
            active = true,
            delta = NMCore.clamp(delta, 0.0, 1.0),
            action = self.actionName
        }
        if self.window.invalidateSlotFrameModel then
            self.window:invalidateSlotFrameModel()
        end
        if self.window.invalidateRenderModel then
            self.window:invalidateRenderModel()
        end
    end
end

function NMBatterySlotTimedAction:stop()
    if self.window then
        self.window._nmBatterySlotTimedProgress = nil
        if self.actionName == "eject_battery" and self.window._nmSlotRemoveInFlightByType then
            self.window._nmSlotRemoveInFlightByType.battery = nil
        end
        if self.window.invalidateContextCache then
            self.window:invalidateContextCache()
        end
        if self.window.invalidateSlotFrameModel then
            self.window:invalidateSlotFrameModel()
        end
        if self.window.invalidateRenderModel then
            self.window:invalidateRenderModel()
        end
    end
    ISBaseTimedAction.stop(self)
end

function NMBatterySlotTimedAction:perform()
    if self.window then
        self.window._nmBatterySlotTimedProgress = nil
        local ok = self.window:dispatch(self.actionName, self.args or {})
        if ok == true then
            self.window._nmPendingBatterySlotFullType = nil
            if self.actionName == "insert_battery" then
                playSlotUISound(self.window, "NM_BatteryIn", 0.8)
            elseif self.actionName == "eject_battery" then
                playSlotUISound(self.window, "NM_BatteryOut", 0.8)
            end
        end
        if self.actionName == "eject_battery" and self.window._nmSlotRemoveInFlightByType then
            self.window._nmSlotRemoveInFlightByType.battery = nil
        end
        if ok == false then
            self.window._nmPendingBatterySlotFullType = nil
        end
        if self.window.invalidateContextCache then
            self.window:invalidateContextCache()
        end
        if self.window.invalidateSlotFrameModel then
            self.window:invalidateSlotFrameModel()
        end
        if self.window.invalidateRenderModel then
            self.window:invalidateRenderModel()
        end
    end
    ISBaseTimedAction.perform(self)
end

function NMBatterySlotTimedAction:new(playerObj, window, actionName, args)
    local o = ISBaseTimedAction.new(self, playerObj)
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 80
    o.playerObj = playerObj
    o.window = window
    o.actionName = tostring(actionName or "")
    o.args = args or {}
    return o
end

