local env = _G.NMMediaSlotEnv
setfenv(1, env)

NMMediaSlotTimedAction = NMMediaSlotTimedAction or ISBaseTimedAction:derive("NMMediaSlotTimedAction")

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

function NMMediaSlotTimedAction:isValid()
    return self.window ~= nil and self.actionName ~= nil and self.actionName ~= ""
end

function NMMediaSlotTimedAction:waitToStart()
    return false
end

function NMMediaSlotTimedAction:start()
    if self.window then
        local isWalkmanWindow = self.window.getLidRect ~= nil and self.window.syncLidFromMedia ~= nil
        logPortableUiProbe(
            "timed_media_start",
            string.format(
                "ui=%s action=%s targetItemId=%s targetUuid=%s mediaItemId=%s mediaFullType=%s slotTraceId=%s",
                tostring(resolveWindowFamily(self.window)),
                tostring(self.actionName or ""),
                tostring(self.window.target and self.window.target.itemId or ""),
                tostring(self.window.target and self.window.target.uuid or ""),
                tostring(self.args and self.args.mediaItemId or ""),
                tostring(self.window._nmPendingMediaSlotFullType or self.args and (self.args.mediaEjectFullType or self.args.mediaFullType) or ""),
                tostring(self.args and self.args.slotTraceId or "")
            )
        )
        if self.window.clearAwaitingAuthoritativeMediaEject then
            self.window:clearAwaitingAuthoritativeMediaEject()
        end
        if self.window.clearAwaitingAuthoritativeMediaInsert then
            self.window:clearAwaitingAuthoritativeMediaInsert()
        end
        self.window._nmMediaEjectInterrupted = nil
        self.window._nmMediaSlotTimedProgress = { active = true, delta = 0.0, action = self.actionName }
        if isWalkmanWindow and self.actionName == "insert_media" then
            local walkmanEnv = rawget(_G, "NMWalkmanWindowEnv")
            self.window._nmSuppressNextLidCloseSound = true
            if walkmanEnv and walkmanEnv.playWalkmanLidSound then
                walkmanEnv.playWalkmanLidSound(self.window, false)
            end
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
        if self.window.syncLidFromMedia then
            self.window:syncLidFromMedia(false)
        end
    end
end

function NMMediaSlotTimedAction:update()
    local delta = 0.0
    if self.action and self.action.getJobDelta then
        delta = tonumber(self.action:getJobDelta()) or 0.0
    end
    if self.window then
        self.window._nmMediaSlotTimedProgress = {
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

function NMMediaSlotTimedAction:stop()
    if self.window then
        logPortableUiProbe(
            "timed_media_stop",
            string.format(
                "ui=%s action=%s targetItemId=%s targetUuid=%s pendingMedia=%s slotTraceId=%s",
                tostring(resolveWindowFamily(self.window)),
                tostring(self.actionName or ""),
                tostring(self.window.target and self.window.target.itemId or ""),
                tostring(self.window.target and self.window.target.uuid or ""),
                tostring(self.window._nmPendingMediaSlotFullType or ""),
                tostring(self.args and self.args.slotTraceId or "")
            )
        )
        self.window._nmMediaSlotTimedProgress = nil
        if self.window.clearAwaitingAuthoritativeMediaEject then
            self.window:clearAwaitingAuthoritativeMediaEject()
        end
        if self.window.clearAwaitingAuthoritativeMediaInsert then
            self.window:clearAwaitingAuthoritativeMediaInsert()
        end
        if self.actionName == "insert_media" then
            self.window._nmSuppressNextLidCloseSound = nil
        end
        if self.actionName == "eject_media" and self.window._nmSlotRemoveInFlightByType then
            self.window._nmMediaEjectInterrupted = true
            self.window._nmSlotRemoveInFlightByType.media = nil
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
        if self.window.syncLidFromMedia then
            self.window:syncLidFromMedia(true)
        end
    end
    ISBaseTimedAction.stop(self)
end

function NMMediaSlotTimedAction:perform()
    if self.window then
        local isWalkmanWindow = self.window.getLidRect ~= nil and self.window.syncLidFromMedia ~= nil
        local pendingInsertFullType = tostring(self.window._nmPendingMediaSlotFullType or "")
        local pendingEjectFullType = tostring(self.window._nmPendingMediaSlotFullType or "")
        logPortableUiProbe(
            "timed_media_perform_begin",
            string.format(
                "ui=%s action=%s targetItemId=%s targetUuid=%s mediaItemId=%s pendingMedia=%s slotTraceId=%s",
                tostring(resolveWindowFamily(self.window)),
                tostring(self.actionName or ""),
                tostring(self.window.target and self.window.target.itemId or ""),
                tostring(self.window.target and self.window.target.uuid or ""),
                tostring(self.args and self.args.mediaItemId or ""),
                tostring(self.window._nmPendingMediaSlotFullType or ""),
                tostring(self.args and self.args.slotTraceId or "")
            )
        )
        self.window._nmMediaSlotTimedProgress = nil
        if self.actionName == "eject_media" then
            self.window._nmMediaEjectInterrupted = nil
        end
        local ok = self.window:dispatch(self.actionName, self.args or {})
        logPortableUiProbe(
            "timed_media_perform_result",
            string.format(
                "ui=%s action=%s ok=%s targetItemId=%s targetUuid=%s mediaItemId=%s pendingBefore=%s slotTraceId=%s",
                tostring(resolveWindowFamily(self.window)),
                tostring(self.actionName or ""),
                tostring(ok == true),
                tostring(self.window.target and self.window.target.itemId or ""),
                tostring(self.window.target and self.window.target.uuid or ""),
                tostring(self.args and self.args.mediaItemId or ""),
                tostring(self.actionName == "insert_media" and pendingInsertFullType or pendingEjectFullType),
                tostring(self.args and self.args.slotTraceId or "")
            )
        )
        if ok == true then
            self.window._nmPendingMediaSlotFullType = nil
            if self.actionName == "insert_media"
                and isWalkmanWindow
                and NMCore
                and NMCore.isMPClientRuntime
                and NMCore.isMPClientRuntime()
                and pendingInsertFullType ~= ""
                and self.window.markAwaitingAuthoritativeMediaInsert then
                self.window:markAwaitingAuthoritativeMediaInsert(pendingInsertFullType)
            end
            if self.actionName == "eject_media"
                and isWalkmanWindow
                and NMCore
                and NMCore.isMPClientRuntime
                and NMCore.isMPClientRuntime()
                and pendingEjectFullType ~= ""
                and self.window.markAwaitingAuthoritativeMediaEject then
                self.window:markAwaitingAuthoritativeMediaEject(pendingEjectFullType)
            end
            if not isWalkmanWindow then
                if self.actionName == "insert_media" then
                    playSlotUISound(self.window, "NM_ButtonClick", 0.8)
                elseif self.actionName == "eject_media" then
                    playSlotUISound(self.window, "NM_ButtonClick2", 0.8)
                end
            end
        end
        if self.actionName == "eject_media" and self.window._nmSlotRemoveInFlightByType then
            self.window._nmSlotRemoveInFlightByType.media = nil
        end
        if ok == false or self.actionName ~= "insert_media" then
            self.window._nmSuppressNextLidCloseSound = nil
        end
        if ok == false then
            if self.window.clearAwaitingAuthoritativeMediaEject then
                self.window:clearAwaitingAuthoritativeMediaEject()
            end
            if self.window.clearAwaitingAuthoritativeMediaInsert then
                self.window:clearAwaitingAuthoritativeMediaInsert()
            end
            self.window._nmPendingMediaSlotFullType = nil
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
        if self.window.syncLidFromMedia then
            self.window:syncLidFromMedia(false)
        end
    end
    ISBaseTimedAction.perform(self)
end

function NMMediaSlotTimedAction:new(playerObj, window, actionName, args)
    local o = ISBaseTimedAction.new(self, playerObj)
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = 40
    o.playerObj = playerObj
    o.window = window
    o.actionName = tostring(actionName or "")
    o.args = args or {}
    return o
end

