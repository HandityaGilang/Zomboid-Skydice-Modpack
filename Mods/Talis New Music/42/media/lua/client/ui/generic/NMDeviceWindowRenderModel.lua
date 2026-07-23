local env = _G.NMDeviceWindowEnv
setfenv(1, env)

local function logPortableUiProbe(tag, detail)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("portableUiProbe")) then
        return
    end
    NMCore.logChannel("portableUiProbe", tostring(tag or "portable_ui"), tostring(detail or ""))
end

function resolveDraggedInventoryItemsSnapshot()
    if not ISMouseDrag then return {}, true end
    local dragging = ISMouseDrag.dragging
    if dragging == nil then return {}, true end
    if type(dragging) ~= "table" then return nil, false end
    if #dragging <= 0 then return {}, true end
    if not (ISInventoryPane and ISInventoryPane.getActualItems) then
        return nil, false
    end
    local ok, actual = pcall(ISInventoryPane.getActualItems, dragging)
    if not ok or type(actual) ~= "table" then
        return nil, false
    end
    local out = {}
    for i = 1, #actual do
        local item = actual[i]
        if item and item.getFullType then
            out[#out + 1] = item
        end
    end
    return out, true
end

function DeviceWindow:buildSlotFrameModel()
    local epoch = tonumber(self._nmFrameEpoch) or 0
    if self._nmSlotFrameModel and self._nmSlotFrameModelEpoch == epoch then
        return self._nmSlotFrameModel
    end

    local perfStart = NMUIRenderProbe and NMUIRenderProbe.beginWindow and NMUIRenderProbe.beginWindow(self) or nil
    local resolved = self:resolveContextCached()
    local dragItems, dragOk = resolveDraggedInventoryItemsSnapshot()
    local frame = {
        resolved = resolved,
        dragItems = dragItems,
        dragOk = dragOk == true,
    }

    local model = {}
    if NMBatterySlot and NMBatterySlot.buildRenderState then
        model.battery = NMBatterySlot.buildRenderState(self, frame)
    end
    if NMMediaSlot and NMMediaSlot.buildRenderState then
        model.media = NMMediaSlot.buildRenderState(self, frame)
    end
    if NMHeadphoneSlot and NMHeadphoneSlot.buildRenderState then
        model.headphones = NMHeadphoneSlot.buildRenderState(self, frame)
    end

    self._nmSlotFrameModel = model
    self._nmSlotFrameModelEpoch = epoch
    if NMUIRenderProbe and NMUIRenderProbe.endWindow then
        NMUIRenderProbe.endWindow(self, "device.buildSlotFrameModel", perfStart)
    end
    return model
end

function DeviceWindow:getSlotRenderState(slotKey)
    local model = self:buildRenderModel()
    return model and model[slotKey] or nil
end

function DeviceWindow:buildRenderModel()
    local epoch = tonumber(self._nmFrameEpoch) or 0
    if self._nmRenderModel and self._nmRenderModelEpoch == epoch then
        return self._nmRenderModel
    end

    local perfStart = NMUIRenderProbe and NMUIRenderProbe.beginWindow and NMUIRenderProbe.beginWindow(self) or nil
    local resolved = self:resolveContextCached()
    local dragItems, dragOk = resolveDraggedInventoryItemsSnapshot()
    local frame = {
        resolved = resolved,
        dragItems = dragItems,
        dragOk = dragOk == true,
        nowMs = tonumber(self._nmFrameNowMs) or 0,
        epoch = epoch,
        window = self,
    }

    local model = {
        resolved = resolved,
        dragItems = dragItems,
        dragOk = dragOk == true,
        nowMs = frame.nowMs,
    }
    if NMBatterySlot and NMBatterySlot.buildRenderState then
        model.battery = NMBatterySlot.buildRenderState(self, frame)
    end
    if NMMediaSlot and NMMediaSlot.buildRenderState then
        model.media = NMMediaSlot.buildRenderState(self, frame)
    end
    if NMHeadphoneSlot and NMHeadphoneSlot.buildRenderState then
        model.headphones = NMHeadphoneSlot.buildRenderState(self, frame)
    end
    if NMReadoutPane and NMReadoutPane.buildRenderState then
        model.readout = NMReadoutPane.buildRenderState(self, frame)
    end
    if NMCoverPane and NMCoverPane.buildRenderState then
        model.cover = NMCoverPane.buildRenderState(self, frame)
    end
    if NMTransportButtonRow and NMTransportButtonRow.buildRenderState then
        model.transport = NMTransportButtonRow.buildRenderState(self, frame)
    end
    if NMPowerButton and NMPowerButton.buildRenderState then
        model.power = NMPowerButton.buildRenderState(self, frame)
    end
    if NMVolumeFader and NMVolumeFader.buildRenderState then
        model.fader = NMVolumeFader.buildRenderState(self, frame)
    end

    self._nmRenderModel = model
    self._nmRenderModelEpoch = epoch
    self._nmSlotFrameModel = model
    self._nmSlotFrameModelEpoch = epoch
    if NMUIRenderProbe and NMUIRenderProbe.endWindow then
        NMUIRenderProbe.endWindow(self, "device.buildRenderModel", perfStart)
    end
    return model
end

function DeviceWindow:getRenderModel()
    return self:buildRenderModel()
end

function DeviceWindow:getRenderState(key)
    local model = self:buildRenderModel()
    return model and model[key] or nil
end

function DeviceWindow:dispatch(action, args)
    local resolved = self:resolveContextFresh()
    if not resolved then
        logPortableUiProbe(
            "generic_dispatch_missing_context",
            string.format(
                "action=%s targetKind=%s targetItemId=%s targetUuid=%s mediaItemId=%s slotTraceId=%s",
                tostring(action or ""),
                tostring(self.target and self.target.kind or ""),
                tostring(self.target and self.target.itemId or ""),
                tostring(self.target and self.target.uuid or ""),
                tostring(args and args.mediaItemId or ""),
                tostring(args and args.slotTraceId or "")
            )
        )
        return false, "missing_context"
    end
    logPortableUiProbe(
        "generic_dispatch",
        string.format(
            "action=%s targetKind=%s targetItemId=%s targetUuid=%s resolvedItemId=%s mediaItemId=%s mediaFullType=%s pending=%s slotTraceId=%s",
            tostring(action or ""),
            tostring(self.target and self.target.kind or ""),
            tostring(self.target and self.target.itemId or ""),
            tostring(self.target and self.target.uuid or ""),
            tostring(resolved.item and NMCore and NMCore.itemId and NMCore.itemId(resolved.item) or ""),
            tostring(args and args.mediaItemId or ""),
            tostring(args and (args.mediaEjectFullType or args.mediaFullType) or ""),
            tostring(self._nmPendingMediaSlotFullType or ""),
            tostring(args and args.slotTraceId or "")
        )
    )
    local ok, reason = false, "missing_context"
    if resolved.kind == "vehicle" then
        ok, reason = NMClientIntentDispatch.performVehicleIntent(
            resolved.player,
            resolved.vehicle,
            resolved.part,
            action,
            args or {}
        )
    else
        ok, reason = NMClientIntentDispatch.performIntent(resolved.player, resolved.item, action, args or {})
    end
    self:invalidateContextCache()
    self:invalidateSlotFrameModel()
    self:invalidateRenderModel()
    logPortableUiProbe(
        "generic_dispatch_result",
        string.format(
            "action=%s ok=%s reason=%s targetKind=%s targetItemId=%s targetUuid=%s pending=%s slotTraceId=%s",
            tostring(action or ""),
            tostring(ok == true),
            tostring(reason or ""),
            tostring(self.target and self.target.kind or ""),
            tostring(self.target and self.target.itemId or ""),
            tostring(self.target and self.target.uuid or ""),
            tostring(self._nmPendingMediaSlotFullType or ""),
            tostring(args and args.slotTraceId or "")
        )
    )
    return ok, reason
end
