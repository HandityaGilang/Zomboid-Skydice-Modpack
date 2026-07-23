local env = _G.NMHeadphoneSlotEnv
setfenv(1, env)

NMHeadphoneSlotTimedAction = NMHeadphoneSlotTimedAction or ISBaseTimedAction:derive("NMHeadphoneSlotTimedAction")

function NMHeadphoneSlotTimedAction:isValid()
    return self.window ~= nil and self.actionName ~= nil and self.actionName ~= ""
end

function NMHeadphoneSlotTimedAction:waitToStart()
    return false
end

function NMHeadphoneSlotTimedAction:start()
    if self.window then
        self.window._nmHeadphoneSlotTimedProgress = { active = true, delta = 0.0, action = self.actionName }
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

function NMHeadphoneSlotTimedAction:update()
    local delta = 0.0
    if self.action and self.action.getJobDelta then
        delta = tonumber(self.action:getJobDelta()) or 0.0
    end
    if self.window then
        self.window._nmHeadphoneSlotTimedProgress = {
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

function NMHeadphoneSlotTimedAction:stop()
    if self.window then
        self.window._nmHeadphoneSlotTimedProgress = nil
        self.window._nmHeadphoneWearSyncInFlight = false
        if self.actionName == "eject_headphones" and self.window._nmSlotRemoveInFlightByType then
            self.window._nmSlotRemoveInFlightByType.headphones = nil
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

function NMHeadphoneSlotTimedAction:perform()
    if self.window then
        self.window._nmHeadphoneSlotTimedProgress = nil
        local ok = self.window:dispatch(self.actionName, self.args or {})
        if ok == true then
            self.window._nmPendingHeadphoneSlotFullType = nil
            playSlotUISound(self.window, "NM_ButtonClick", 0.8)
        end
        if self.actionName == "eject_headphones" and self.window._nmSlotRemoveInFlightByType then
            self.window._nmSlotRemoveInFlightByType.headphones = nil
        end
        if ok == false then
            self.window._nmHeadphoneWearSyncInFlight = false
            self.window._nmPendingHeadphoneSlotFullType = nil
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

function NMHeadphoneSlotTimedAction:new(playerObj, window, actionName, args)
    local o = ISBaseTimedAction.new(self, playerObj)
    o.stopOnWalk = true
    o.stopOnRun = true
    -- Match vanilla wear/unequip action pacing.
    o.maxTime = 50
    o.playerObj = playerObj
    o.window = window
    o.actionName = tostring(actionName or "")
    o.args = args or {}
    return o
end

