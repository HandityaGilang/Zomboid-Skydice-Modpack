local env = _G.NMWalkmanWindowEnv
setfenv(1, env)

local function logPortableUiProbe(tag, detail)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("portableUiProbe")) then
        return
    end
    NMCore.logChannel("portableUiProbe", tostring(tag or "portable_ui"), tostring(detail or ""))
end

function WalkmanWindow:hasInsertedCassette()
    local renderState = self:getSlotRenderState("media")
    return tostring(renderState and renderState.fullType or "") ~= ""
end

function WalkmanWindow:getCassetteDisplayMediaState()
    local renderState = self:getSlotRenderState("media")
    local fullType = tostring(renderState and renderState.fullType or "")
    if fullType == "" then
        return {
            fullType = "",
            texture = nil,
            texturePath = nil,
            visible = false,
        }
    end
    if not NMMediaWorldTextureResolver or not NMMediaWorldTextureResolver.resolveTexture then
        return {
            fullType = fullType,
            texture = nil,
            texturePath = nil,
            visible = false,
        }
    end
    local texture, texturePath = NMMediaWorldTextureResolver.resolveTexture(fullType)
    return {
        fullType = fullType,
        texture = texture,
        texturePath = texturePath,
        visible = texture ~= nil,
    }
end

function WalkmanWindow:getCassetteDisplayTexture()
    local mediaState = self:getCassetteDisplayMediaState()
    return mediaState.texture, mediaState.texturePath
end

function WalkmanWindow:markAwaitingAuthoritativeMediaEject(fullType)
    local pendingFullType = tostring(fullType or "")
    if pendingFullType == "" then
        self._nmAwaitingAuthoritativeMediaEject = nil
        return
    end
    self._nmAwaitingAuthoritativeMediaInsert = nil
    self._nmAwaitingAuthoritativeMediaEject = {
        active = true,
        fullType = pendingFullType,
        startedAtMs = getNowMs()
    }
end

function WalkmanWindow:clearAwaitingAuthoritativeMediaEject()
    self._nmAwaitingAuthoritativeMediaEject = nil
end

function WalkmanWindow:isAwaitingAuthoritativeMediaEject(fullType)
    local awaiting = self._nmAwaitingAuthoritativeMediaEject
    if not (awaiting and awaiting.active == true) then
        return false
    end
    local awaitingFullType = tostring(awaiting.fullType or "")
    if tostring(fullType or "") == "" then
        return awaitingFullType ~= ""
    end
    return awaitingFullType ~= "" and awaitingFullType == tostring(fullType or "")
end

function WalkmanWindow:markAwaitingAuthoritativeMediaInsert(fullType)
    local pendingFullType = tostring(fullType or "")
    if pendingFullType == "" then
        self._nmAwaitingAuthoritativeMediaInsert = nil
        return
    end
    self._nmAwaitingAuthoritativeMediaEject = nil
    self._nmAwaitingAuthoritativeMediaInsert = {
        active = true,
        fullType = pendingFullType,
        startedAtMs = getNowMs()
    }
end

function WalkmanWindow:clearAwaitingAuthoritativeMediaInsert()
    self._nmAwaitingAuthoritativeMediaInsert = nil
end

function WalkmanWindow:isAwaitingAuthoritativeMediaInsert(fullType)
    local awaiting = self._nmAwaitingAuthoritativeMediaInsert
    if not (awaiting and awaiting.active == true) then
        return false
    end
    local awaitingFullType = tostring(awaiting.fullType or "")
    if tostring(fullType or "") == "" then
        return awaitingFullType ~= ""
    end
    return awaitingFullType ~= "" and awaitingFullType == tostring(fullType or "")
end

function WalkmanWindow:invalidateContextCache()
    self._nmContextCache = nil
    self._nmContextCacheTargetKey = nil
end

function WalkmanWindow:beginFrameEpoch(reason)
    self._nmFrameEpoch = (tonumber(self._nmFrameEpoch) or 0) + 1
    self._nmFrameReason = tostring(reason or "frame")
    self._nmFrameNowMs = getNowMs()
    self:invalidateContextCache()
    self:invalidateSlotFrameModel()
end

function WalkmanWindow:resolveContext()
    local key = targetCacheKey(self.target)
    if self._nmContextCache and self._nmContextCacheTargetKey == key then
        return self._nmContextCache
    end
    local resolved = resolveContextFreshUncached(self)
    self._nmContextCache = resolved
    self._nmContextCacheTargetKey = key
    return resolved
end

function WalkmanWindow:invalidateSlotFrameModel()
    self._nmSlotFrameModel = nil
    self._nmSlotFrameModelEpoch = nil
end

function WalkmanWindow:buildSlotFrameModel()
    local epoch = tonumber(self._nmFrameEpoch) or 0
    if self._nmSlotFrameModel and self._nmSlotFrameModelEpoch == epoch then
        return self._nmSlotFrameModel
    end
    local resolved = self:resolveContextCached()
    local dragItems, dragOk = resolveDraggedInventoryItemsSnapshot()
    local frame = {
        resolved = resolved,
        dragItems = dragItems,
        dragOk = dragOk == true,
        nowMs = tonumber(self._nmFrameNowMs) or getNowMs(),
        epoch = epoch,
        window = self,
    }
    local model = {}
    if NMMediaSlot and NMMediaSlot.buildRenderState then
        model.media = NMMediaSlot.buildRenderState(self, frame)
    end
    if NMHeadphoneSlot and NMHeadphoneSlot.buildRenderState then
        model.headphones = NMHeadphoneSlot.buildRenderState(self, frame)
    end
    if NMBatterySlot and NMBatterySlot.buildRenderState then
        model.battery = NMBatterySlot.buildRenderState(self, frame)
    end
    self._nmSlotFrameModel = model
    self._nmSlotFrameModelEpoch = epoch
    return model
end

function WalkmanWindow:getSlotRenderState(slotKey)
    local model = self:buildSlotFrameModel()
    return model and model[slotKey] or nil
end

function WalkmanWindow:dispatch(action, args)
    local resolved = self:resolveContextFresh()
    if not resolved then
        logPortableUiProbe(
            "walkman_dispatch_missing_context",
            string.format(
                "action=%s targetItemId=%s targetUuid=%s mediaItemId=%s slotTraceId=%s",
                tostring(action or ""),
                tostring(self.target and self.target.itemId or ""),
                tostring(self.target and self.target.uuid or ""),
                tostring(args and args.mediaItemId or ""),
                tostring(args and args.slotTraceId or "")
            )
        )
        return false, "missing_context"
    end
    logPortableUiProbe(
        "walkman_dispatch",
        string.format(
            "action=%s targetItemId=%s targetUuid=%s resolvedItemId=%s mediaItemId=%s mediaFullType=%s pending=%s slotTraceId=%s",
            tostring(action or ""),
            tostring(self.target and self.target.itemId or ""),
            tostring(self.target and self.target.uuid or ""),
            tostring(resolved.item and NMCore and NMCore.itemId and NMCore.itemId(resolved.item) or ""),
            tostring(args and args.mediaItemId or ""),
            tostring(args and (args.mediaEjectFullType or args.mediaFullType) or ""),
            tostring(self._nmPendingMediaSlotFullType or ""),
            tostring(args and args.slotTraceId or "")
        )
    )
    local ok, reason = NMClientIntentDispatch.performIntent(resolved.player, resolved.item, action, args or {})
    if ok == true then
        self:invalidateContextCache()
        self:invalidateSlotFrameModel()
    end
    logPortableUiProbe(
        "walkman_dispatch_result",
        string.format(
            "action=%s ok=%s reason=%s targetItemId=%s targetUuid=%s pending=%s slotTraceId=%s",
            tostring(action or ""),
            tostring(ok == true),
            tostring(reason or ""),
            tostring(self.target and self.target.itemId or ""),
            tostring(self.target and self.target.uuid or ""),
            tostring(self._nmPendingMediaSlotFullType or ""),
            tostring(args and args.slotTraceId or "")
        )
    )
    return ok, reason
end

function WalkmanWindow:resolveContextCached()
    return self:resolveContext()
end

function WalkmanWindow:resolveContextFresh()
    self:invalidateContextCache()
    return resolveContextFreshUncached(self)
end
