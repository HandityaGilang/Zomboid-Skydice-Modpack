local env = _G.NMContextMenusEnv
setfenv(1, env)

local function isFancyUIEnabled()
    if NMRuntimeConfig and NMRuntimeConfig.getFancyUIEnabled then
        return NMRuntimeConfig.getFancyUIEnabled() == true
    end
    return true
end

local function logPortableUiProbe(tag, detail)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("portableUiProbe")) then
        return
    end
    NMCore.logChannel("portableUiProbe", tostring(tag or "portable_ui"), tostring(detail or ""))
end

function traceLooseMediaClick(player, tag, item)
    if not (NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe")) then
        return
    end
    local inv = player and player.getInventory and player:getInventory() or nil
    local itemId = item and item.getID and tostring(item:getID() or "") or ""
    local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
    local container = item and item.getContainer and item:getContainer() or nil
    local inInv = false
    if inv and itemId ~= "" and NMInventoryHelpers and NMInventoryHelpers.findItemById then
        inInv = NMInventoryHelpers.findItemById(inv, itemId) ~= nil
    end
    NMCore.logChannel(
        "runtimeProbe",
        tostring(tag or "loose_media_click"),
        string.format(
            "itemId=%s fullType=%s hasContainer=%s inRootInventory=%s",
            tostring(itemId),
            tostring(fullType),
            tostring(container ~= nil),
            tostring(inInv)
        )
    )
end

function tryQueueOpenWalkmanMediaAction(p, targetItem, actionName, args)
    if not isFancyUIEnabled() then
        return false
    end
    if not (p and targetItem and actionName and NMWalkmanWindow) then
        return false
    end
    local profile = NMDeviceProfiles and NMDeviceProfiles.getForItem and NMDeviceProfiles.getForItem(targetItem) or nil
    if not profile or tostring(profile.deviceType or "") ~= "walkman" then
        return false
    end
    local playerNum = p.getPlayerNum and p:getPlayerNum() or 0
    local win = nil
    if NMWalkmanWindow.findOpenForItem then
        win = NMWalkmanWindow.findOpenForItem(playerNum, targetItem)
    end
    if not win and NMWalkmanWindow.openForItem then
        win = NMWalkmanWindow.openForItem(playerNum, targetItem)
    end
    if not win then
        return false
    end
    local mediaEnv = rawget(_G, "NMMediaSlotEnv")
    local sharedQueue = mediaEnv and mediaEnv.queueMediaSlotAction or nil
    if not sharedQueue then
        return false
    end
    local action = tostring(actionName or "")
    local payload = args or {}
    if action == "insert_media" then
        win._nmPendingMediaSlotFullType = tostring(payload.mediaEjectFullType or payload.mediaFullType or "")
        win.isLidManuallyOpen = true
    elseif action == "eject_media" then
        win._nmSlotRemoveInFlightByType = win._nmSlotRemoveInFlightByType or {}
        if win._nmSlotRemoveInFlightByType.media then
            return false
        end
        local cassetteMediaState = win.getCassetteDisplayMediaState and win:getCassetteDisplayMediaState() or nil
        local fullType = tostring(cassetteMediaState and cassetteMediaState.fullType or payload.mediaEjectFullType or payload.mediaFullType or "")
        if fullType == "" then
            return false
        end
        win._nmSlotRemoveInFlightByType.media = true
        win._nmPendingMediaSlotFullType = fullType
        win.isLidManuallyOpen = true
    else
        return false
    end
    if win.syncLidFromMedia then
        win:syncLidFromMedia(false)
    end
    logPortableUiProbe(
        "loose_media_walkman_queue",
        string.format(
            "player=%s action=%s targetItemId=%s targetUuid=%s mediaItemId=%s mediaFullType=%s slotTraceId=%s",
            tostring(playerNum or 0),
            tostring(action or ""),
            tostring(win.target and win.target.itemId or ""),
            tostring(win.target and win.target.uuid or ""),
            tostring(payload.mediaItemId or ""),
            tostring(payload.mediaEjectFullType or payload.mediaFullType or ""),
            tostring(payload.slotTraceId or "")
        )
    )
    return sharedQueue(win, action, payload) == true
end

function tryQueueOpenWalkmanInsert(p, targetItem, args)
    return tryQueueOpenWalkmanMediaAction(p, targetItem, "insert_media", args)
end

function addLooseMediaFlipAction(subMenu, player, mediaItem, capturedItemId)
    local mediaFullType = mediaItem and mediaItem.getFullType and tostring(mediaItem:getFullType() or "") or ""
    local flipTarget = NMMediaContract.resolveMediaFlipTarget and NMMediaContract.resolveMediaFlipTarget(mediaFullType) or nil
    if not (flipTarget and tostring(flipTarget) ~= "") then
        return
    end
    subMenu:addOption(NMTranslations.ui("Flip", "Flip"), player, function(p)
        local inv = p and p.getInventory and p:getInventory() or nil
        local liveItem, liveId = resolveLiveItemByIdOrAlias(p, capturedItemId)
        traceLooseMediaClick(p, "flip_click_client", liveItem or mediaItem)
        if not inv then
            return
        end
        if not liveItem then
            local aliasOnlyId = tostring(liveId or "")
            if NMCore and NMCore.isMPClientRuntime and NMCore.isMPClientRuntime() and aliasOnlyId ~= "" and aliasOnlyId ~= tostring(capturedItemId or "") then
                if NMContextMenus._flipInFlight[aliasOnlyId] then
                    return
                end
                NMContextMenus._flipInFlight[aliasOnlyId] = true
                if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
                    NMCore.logChannel(
                        "runtimeProbe",
                        "flip_click_client_alias_only",
                        string.format(
                            "capturedItemId=%s resolvedItemId=%s target=%s",
                            tostring(capturedItemId or ""),
                            tostring(aliasOnlyId),
                            tostring(flipTarget)
                        )
                    )
                    NMCore.logChannel(
                        "runtimeProbe",
                        "flip_request_client",
                        string.format(
                            "itemId=%s fullType=%s target=%s mp=true aliasOnly=true",
                            tostring(aliasOnlyId),
                            tostring(mediaFullType),
                            tostring(flipTarget)
                        )
                    )
                end
                sendClientCommand(p, NMCore.NetModule, "media_flip", {
                    itemId = aliasOnlyId
                })
                return
            end
            if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
                NMCore.logChannel("runtimeProbe", "flip_click_client_no_live_item", "capturedItemId=" .. tostring(capturedItemId or ""))
            end
            return
        end
        if liveId and tostring(liveId) ~= "" and NMContextMenus._flipInFlight[tostring(liveId)] then
            return
        end
        local source = liveItem
        local owner = source.getContainer and source:getContainer() or nil
        if owner ~= inv then
            return
        end

        if NMCore and NMCore.isMPClientRuntime and NMCore.isMPClientRuntime() then
            local requestId = tostring(liveId or "")
            if requestId == "" and source.getID then
                requestId = tostring(source:getID() or "")
            end
            if requestId == "" then
                return
            end
            NMContextMenus._flipInFlight[requestId] = true
            if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
                NMCore.logChannel(
                    "runtimeProbe",
                    "flip_request_client",
                    string.format(
                        "itemId=%s fullType=%s target=%s mp=true",
                        tostring(requestId),
                        tostring(source.getFullType and source:getFullType() or ""),
                        tostring(flipTarget)
                    )
                )
            end
            sendClientCommand(p, NMCore.NetModule, "media_flip", {
                itemId = requestId
            })
            return
        end

        local created = NMWorldItemVisuals.addItemWithVisual and select(1, NMWorldItemVisuals.addItemWithVisual(inv, flipTarget)) or nil
        if not created then
            return
        end
        if inv.DoRemoveItem then
            inv:DoRemoveItem(source)
        else
            inv:Remove(source)
        end
    end)
end

function addLooseMediaInsertActions(subMenu, player, mediaItem, capturedItemId)
    local deviceTargets, containerTargets = collectLooseMediaInsertTargets(player, mediaItem)
    local insertRoot = subMenu:addOption(NMTranslations.ui("Insert", "Insert"), player, nil)
    local insertSub = ISContextMenu:getNew(subMenu)
    subMenu:addSubMenu(insertRoot, insertSub)
    if #deviceTargets < 1 and #containerTargets < 1 then
        local none = insertSub:addOption(NMTranslations.ui("NoValidTargets", "No valid targets"), player, function() end)
        none.notAvailable = true
        return
    end

    local function addTargetRow(target)
        local option = insertSub:addOption(target.displayName, player, function(p)
            local liveItem, liveId = resolveLiveItemByIdOrAlias(p, capturedItemId)
            traceLooseMediaClick(p, "insert_click_client", liveItem or mediaItem)
            if not liveId or tostring(liveId) == "" then
                if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
                    NMCore.logChannel("runtimeProbe", "insert_click_client_no_live_item", "capturedItemId=" .. tostring(capturedItemId or ""))
                end
                return
            end
            local args = buildCaseMediaInsertArgs(liveItem)
            logPortableUiProbe(
                "loose_media_insert_target",
                string.format(
                    "player=%s targetType=%s targetItemId=%s targetUuid=%s mediaItemId=%s mediaUuid=%s mediaFullType=%s",
                    tostring(p and p.getPlayerNum and p:getPlayerNum() or 0),
                    tostring(target.category or "device"),
                    tostring(target.item and NMCore and NMCore.itemId and NMCore.itemId(target.item) or ""),
                    tostring(target.item and NMInventoryHelpers and NMInventoryHelpers.getItemStateUuid and NMInventoryHelpers.getItemStateUuid(target.item) or ""),
                    tostring(liveId or ""),
                    tostring(liveItem and NMInventoryHelpers and NMInventoryHelpers.getItemStateUuid and NMInventoryHelpers.getItemStateUuid(liveItem) or ""),
                    tostring(args and (args.mediaEjectFullType or args.mediaFullType) or "")
                )
            )
            if args and tryQueueOpenWalkmanMediaAction(p, target.item, "insert_media", args) == true then
                return
            end
            NMClientIntentDispatch.performIntent(p, target.item, "insert_media", args or {
                mediaItemId = tostring(liveId)
            })
        end)
        setOptionIcon(option, resolveTextureByFullType(target.item and target.item.getFullType and target.item:getFullType() or ""))
    end

    for i = 1, #deviceTargets do
        addTargetRow(deviceTargets[i])
    end
    for i = 1, #containerTargets do
        addTargetRow(containerTargets[i])
    end
end

function NMContextMenus.onMediaFlipResult(player, args)
    if not (player and args and args.ok == true) then
        local failedOldId = tostring(args and args.oldItemId or "")
        if failedOldId ~= "" then
            NMContextMenus._flipInFlight[failedOldId] = nil
        end
        if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
            NMCore.logChannel(
                "runtimeProbe",
                "flip_ack_client_fail",
                string.format(
                    "ok=%s oldItemId=%s newItemId=%s reason=%s",
                    tostring(args and args.ok),
                    tostring(args and args.oldItemId or ""),
                    tostring(args and args.newItemId or ""),
                    tostring(args and args.reason or "")
                )
            )
        end
        return false
    end
    if NMCore and NMCore.logChannel and NMCore.isDebugKnobOn and NMCore.isDebugKnobOn("runtimeProbe") then
        NMCore.logChannel(
            "runtimeProbe",
            "flip_ack_client_ok",
            string.format(
                "oldItemId=%s newItemId=%s target=%s recIdx=%s",
                tostring(args.oldItemId or ""),
                tostring(args.newItemId or ""),
                tostring(args.targetFullType or ""),
                tostring(args.recordedMediaIndex or "")
            )
        )
    end
    local oldItemId = tostring(args.oldItemId or "")
    local newItemId = tostring(args.newItemId or "")
    if oldItemId ~= "" then
        NMContextMenus._flipInFlight[oldItemId] = nil
    end
    if newItemId ~= "" then
        NMContextMenus._flipInFlight[newItemId] = nil
    end
    if oldItemId ~= "" and newItemId ~= "" and oldItemId ~= newItemId then
        NMContextMenus._flipIdAlias[oldItemId] = newItemId
    end
    local inv = player and player.getInventory and player:getInventory() or nil
    if inv and inv.requestSync then
        pcall(inv.requestSync, inv)
    end
    local playerNum = player and player.getPlayerNum and tonumber(player:getPlayerNum()) or nil
    local invPage = nil
    local lootPage = nil
    if playerNum ~= nil and getPlayerInventory then
        invPage = getPlayerInventory(playerNum)
        if invPage and invPage.refreshBackpacks then
            pcall(invPage.refreshBackpacks, invPage)
        end
    end
    if playerNum ~= nil and getPlayerLoot then
        lootPage = getPlayerLoot(playerNum)
        if lootPage and lootPage.refreshBackpacks then
            pcall(lootPage.refreshBackpacks, lootPage)
        end
    end
    if ISInventoryPage and ISInventoryPage.dirtyUI then
        pcall(ISInventoryPage.dirtyUI)
    end
    if ISInventoryPage then
        ISInventoryPage.renderDirty = true
    end
    if triggerEvent then
        if invPage then
            pcall(triggerEvent, "OnRefreshInventoryWindowContainers", invPage, "begin")
            pcall(triggerEvent, "OnRefreshInventoryWindowContainers", invPage, "buttonsAdded")
        end
        if lootPage then
            pcall(triggerEvent, "OnRefreshInventoryWindowContainers", lootPage, "begin")
            pcall(triggerEvent, "OnRefreshInventoryWindowContainers", lootPage, "buttonsAdded")
        end
    end
    if NMCore and NMCore.isMPClientRuntime and NMCore.isMPClientRuntime() and sendClientCommand then
        sendClientCommand(player, NMCore.NetModule, "request_inventory_state_sync", {})
    end
    return true
end
