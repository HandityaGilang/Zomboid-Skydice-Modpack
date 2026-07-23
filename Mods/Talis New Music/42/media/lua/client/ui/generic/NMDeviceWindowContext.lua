local env = _G.NMDeviceWindowEnv
setfenv(1, env)

function DeviceWindow:invalidateContextCache()
    self._nmContextCache = nil
    self._nmContextCacheEpoch = nil
    self._nmContextCacheTargetKey = nil
end

function DeviceWindow:beginFrameEpoch(reason)
    self._nmFrameEpoch = (tonumber(self._nmFrameEpoch) or 0) + 1
    self._nmFrameReason = tostring(reason or "frame")
    self._nmFrameNowMs = (getTimestampMs and tonumber(getTimestampMs()))
        or (getTimeInMillis and tonumber(getTimeInMillis()))
        or 0
    self._nmFrameResolveCount = 0
    self._nmFrameFallbackCount = 0
    self:invalidateContextCache()
end

function DeviceWindow:recordFallback(label)
    self._nmFrameFallbackCount = (tonumber(self._nmFrameFallbackCount) or 0) + 1
    if NMUIRenderProbe and NMUIRenderProbe.count then
        NMUIRenderProbe.count(self, "context.fallback", 1)
    end
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe")
        and NMCore.shouldLogEvery and NMCore.shouldLogEvery("runtimeProbe.uiContextFallback." .. tostring(label or "unknown"), self._nmFrameEpoch or 0, 240) then
        NMCore.logChannel("runtimeProbe", "ui_context_fallback", string.format("reason=%s epoch=%s", tostring(label or "unknown"), tostring(self._nmFrameEpoch or 0)))
    end
end

function DeviceWindow:logFrameDiagnostics()
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe")) then
        return
    end
    if not (NMCore.shouldLogEvery and NMCore.shouldLogEvery("runtimeProbe.uiContextFrame." .. tostring(self.playerNum or 0), self._nmFrameEpoch or 0, 180)) then
        return
    end
    local target = self.target
    local targetKey = ""
    if target then
        if target.kind == "vehicle" then
            targetKey = "vehicle:" .. tostring(target.vehicleId or "") .. ":" .. tostring(target.partId or "")
        else
            targetKey = "item:" .. tostring(target.itemId or "")
        end
    end
    NMCore.logChannel(
        "runtimeProbe",
        "ui_context_frame",
        string.format(
            "player=%s epoch=%s reason=%s resolves=%s fallbacks=%s target=%s",
            tostring(self.playerNum or 0),
            tostring(self._nmFrameEpoch or 0),
            tostring(self._nmFrameReason or "frame"),
            tostring(self._nmFrameResolveCount or 0),
            tostring(self._nmFrameFallbackCount or 0),
            tostring(targetKey)
        )
    )
end

function isItemRefValid(item, itemId)
    if not (item and item.getID and itemId) then
        return false
    end
    if tostring(item:getID() or "") ~= tostring(itemId) then
        return false
    end
    local hasContainer = item.getContainer and item:getContainer() ~= nil
    local hasWorldItem = item.getWorldItem and item:getWorldItem() ~= nil
    return hasContainer or hasWorldItem
end

function resolveItemContext(self, player)
    if not self.target or not self.target.itemId then
        return nil
    end
    local itemId = self.target.itemId
    local item = self.target.itemRef
    if not isItemRefValid(item, itemId) then
        item = nil
    end
    if item then
        local profileFast = NMDeviceProfiles.getForItem(item)
        local stateFast = profileFast and NMDeviceState.ensure(item, profileFast) or nil
        if profileFast and stateFast then
            return { player = player, item = item, profile = profileFast, state = stateFast, kind = "item" }
        end
    end

    local inv = player.getInventory and player:getInventory() or nil
    if inv then
        self:recordFallback("inventory_find")
        item = NMInventoryHelpers and NMInventoryHelpers.findItemById and NMInventoryHelpers.findItemById(inv, itemId) or nil
    end
    if not item and NMInventoryHelpers and NMInventoryHelpers.findWorldItemByIdNearPlayer then
        self:recordFallback("world_find")
        item = NMInventoryHelpers.findWorldItemByIdNearPlayer(player, itemId, 8)
    end
    if not item then
        return nil
    end
    self.target.itemRef = item

    local profile = NMDeviceProfiles.getForItem(item)
    local state = profile and NMDeviceState.ensure(item, profile) or nil
    if not (profile and state) then
        return nil
    end

    return { player = player, item = item, profile = profile, state = state, kind = "item" }
end

function resolveVehicleById(vehicleId)
    local id = tonumber(vehicleId)
    if not id or not getVehicleById then
        return nil
    end
    return getVehicleById(id)
end

function resolveVehicleContext(self, player)
    if not self.target then
        return nil
    end
    local vehicle = self.target.vehicleRef
    if vehicle and vehicle.getId and self.target.vehicleId and tostring(vehicle:getId()) ~= tostring(self.target.vehicleId) then
        vehicle = nil
    end
    if not vehicle then
        self:recordFallback("vehicle_find")
        vehicle = resolveVehicleById(self.target.vehicleId)
    end
    if not vehicle and player and player.getVehicle then
        local playerVehicle = player:getVehicle()
        if playerVehicle and playerVehicle.getId and tostring(playerVehicle:getId()) == tostring(self.target.vehicleId or "") then
            vehicle = playerVehicle
        end
    end
    if not vehicle then
        return nil
    end
    self.target.vehicleRef = vehicle

    local partId = tostring(self.target.partId or "Radio")
    local part = self.target.partRef
    if part and part.getId and tostring(part:getId() or "") ~= partId then
        part = nil
    end
    if not part then
        self:recordFallback("vehicle_part_find")
        part = vehicle.getPartById and vehicle:getPartById(partId) or nil
    end
    if not part then
        return nil
    end
    self.target.partRef = part

    local profile = NMDeviceProfiles.getVehicleProfile(part)
    local state = profile and NMDeviceState.ensure(part, profile) or nil
    if not (profile and state) then
        return nil
    end

    return { player = player, vehicle = vehicle, part = part, profile = profile, state = state, kind = "vehicle" }
end

function targetCacheKey(target)
    if not target then
        return ""
    end
    if target.kind == "vehicle" then
        return "vehicle:" .. tostring(target.vehicleId or "") .. ":" .. tostring(target.partId or "")
    end
    return "item:" .. tostring(target.itemId or "")
end

function resolveContextUncached(self)
    local player = getPlayer(self.playerNum)
    if not player or not self.target then
        return nil
    end
    self._nmFrameResolveCount = (tonumber(self._nmFrameResolveCount) or 0) + 1
    if self.target.kind == "vehicle" then
        return resolveVehicleContext(self, player)
    end
    if self.target.kind == "item" then
        return resolveItemContext(self, player)
    end
    return nil
end

function DeviceWindow:resolveContext()
    local perfStart = NMUIRenderProbe and NMUIRenderProbe.beginWindow and NMUIRenderProbe.beginWindow(self) or nil
    local epoch = tonumber(self._nmFrameEpoch) or 0
    local key = targetCacheKey(self.target)
    if self._nmContextCache
        and self._nmContextCacheEpoch == epoch
        and self._nmContextCacheTargetKey == key then
        if NMUIRenderProbe and NMUIRenderProbe.count then
            NMUIRenderProbe.count(self, "context.cache_hit", 1)
        end
        if NMUIRenderProbe and NMUIRenderProbe.endWindow then
            NMUIRenderProbe.endWindow(self, "device.resolveContext", perfStart)
        end
        return self._nmContextCache
    end
    if NMUIRenderProbe and NMUIRenderProbe.count then
        NMUIRenderProbe.count(self, "context.cache_miss", 1)
    end
    local resolved = resolveContextUncached(self)
    self._nmContextCache = resolved
    self._nmContextCacheEpoch = epoch
    self._nmContextCacheTargetKey = key
    if NMUIRenderProbe and NMUIRenderProbe.endWindow then
        NMUIRenderProbe.endWindow(self, "device.resolveContext", perfStart)
    end
    return resolved
end

function resolveLiveItemByTarget(player, target)
    if not (player and target) then
        return nil
    end
    local uuid = tostring(target.uuid or "")
    local itemId = tostring(target.itemId or "")
    local inv = player.getInventory and player:getInventory() or nil
    local item = nil
    if inv and uuid ~= "" and NMInventoryHelpers and NMInventoryHelpers.findItemByUuid then
        item = NMInventoryHelpers.findItemByUuid(inv, uuid)
    end
    if not item and inv and itemId ~= "" and NMInventoryHelpers and NMInventoryHelpers.findItemById then
        item = NMInventoryHelpers.findItemById(inv, itemId)
    end
    if not item and uuid ~= "" and NMInventoryHelpers and NMInventoryHelpers.findWorldItemByUuidNearPlayer then
        item = NMInventoryHelpers.findWorldItemByUuidNearPlayer(player, uuid, 8)
    end
    if not item and itemId ~= "" and NMInventoryHelpers and NMInventoryHelpers.findWorldItemByIdNearPlayer then
        item = NMInventoryHelpers.findWorldItemByIdNearPlayer(player, itemId, 8)
    end
    return item
end

function DeviceWindow:resolveContextCached()
    return self:resolveContext()
end

function DeviceWindow:resolveContextFresh()
    self:invalidateContextCache()
    return resolveContextUncached(self)
end

function DeviceWindow:invalidateSlotFrameModel()
    self._nmSlotFrameModel = nil
    self._nmSlotFrameModelEpoch = nil
end

function DeviceWindow:invalidateRenderModel()
    self._nmRenderModel = nil
    self._nmRenderModelEpoch = nil
end

function NMDeviceWindow.invalidateOpenItemWindow(itemId, uuid)
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
                    win:invalidateRenderModel()
                    invalidated = true
                end
            end
        end
    end
    return invalidated
end

function NMDeviceWindow.rebindOpenPortableItemWindow(itemId, uuid)
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
                        win:invalidateRenderModel()
                        rebound = true
                    end
                end
            end
        end
    end
    return rebound
end

function NMDeviceWindow.inspectOpenItemWindowTarget(playerNum)
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
        awaitingMediaInsert = false,
        awaitingMediaEject = false
    }
end

function NMDeviceWindow.closeOpenForItemTarget(playerNum, itemId, uuid)
    local key = tostring(playerNum or 0)
    local win = windowsByPlayer[key] or nil
    if not (win and win.javaObject and win.target and win.target.kind == "item") then
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

    if win.close then
        win:close()
    elseif win.removeFromUIManager then
        win:removeFromUIManager()
    end
    return true
end
