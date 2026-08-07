TMItemMPSync = TMItemMPSync or {}
TMItemMPSync._hooked = false

local DEBUG = false
local function log(msg)
    if DEBUG then
        print(msg)
    end
end

if isServer() then
    local function removeFirstMatchingItemRecursive(container, matcher)
        if not container or not matcher then return false end
        local items = container.getItems and container:getItems() or nil
        if not items then return false end

        for i = 0, items:size() - 1 do
            local it = items:get(i)
            if it and matcher(it) then
                container:DoRemoveItem(it)
                if sendRemoveItemFromContainer then
                    sendRemoveItemFromContainer(container, it)
                end
                return true
            end
        end

        for i = 0, items:size() - 1 do
            local it = items:get(i)
            local sub = it and it.getItemContainer and it:getItemContainer() or nil
            if sub and removeFirstMatchingItemRecursive(sub, matcher) then
                return true
            end
        end

        return false
    end

    local function onClientCommand(module, command, player, args)
        if module ~= "TMItemMPSync" then return end

        if command == "giveTape" and args and args.fullType then
            local inv = player and player:getInventory()
            if inv then
                local item = instanceItem(args.fullType)
                if item then
                    inv:AddItem(item)
                    sendAddItemToContainer(inv, item)
                end
            end
        elseif command == "giveBattery" and args then
            local inv = player and player:getInventory()
            if inv then
                local item = instanceItem("Base.Battery")
                if item then
                    if item.setUsedDelta and args.power then
                        item:setUsedDelta(args.power)
                    end
                    inv:AddItem(item)
                    sendAddItemToContainer(inv, item)
                end
            end
        elseif command == "consumeBattery" and args and args.itemId then
            local inv = player and player:getInventory()
            local removed = false
            if inv then
                removed = removeFirstMatchingItemRecursive(inv, function(it)
                    return it and it.getID and it:getID() == args.itemId
                end)
                if not removed then
                    removeFirstMatchingItemRecursive(inv, function(it)
                        return it and it.getFullType and it:getFullType() == "Base.Battery"
                    end)
                end
            end
        elseif command == "giveHeadphones" and args and args.fullType then
            local inv = player and player:getInventory()
            if inv then
                local item = instanceItem(args.fullType)
                if item then
                    inv:AddItem(item)
                    sendAddItemToContainer(inv, item)
                end
            end
        elseif command == "consumeHeadphones" and args then
            local inv = player and player:getInventory()
            local removed = false
            if inv and args.itemId then
                removed = removeFirstMatchingItemRecursive(inv, function(it)
                    return it and it.getID and it:getID() == args.itemId
                end)
            end
            if (not removed) and inv then
                local fallbackType = args.fullType
                if fallbackType ~= "Base.Headphones" and fallbackType ~= "Base.Earbuds" then
                    fallbackType = "Base.Headphones"
                end
                removeFirstMatchingItemRecursive(inv, function(it)
                    return it and it.getFullType and it:getFullType() == fallbackType
                end)
            end
        elseif command == "consumeTape" and args then
            local inv = player and player:getInventory()
            local removed = false
            if inv and args.itemId then
                removed = removeFirstMatchingItemRecursive(inv, function(it)
                    return it and it.getID and it:getID() == args.itemId
                end)
            end
            if (not removed) and inv and args.fullType then
                removeFirstMatchingItemRecursive(inv, function(it)
                    return it and it.getFullType and it:getFullType() == args.fullType
                end)
            end
        elseif command == "giveCD" and args and args.fullType then
            local inv = player and player:getInventory()
            if inv then
                local item = instanceItem(args.fullType)
                if item then
                    -- Restore scratch state server-side so it survives the
                    -- broadcast (client-side relabeling never reaches others).
                    if args.scratch and TCMusic and TCMusic.applyScratchSnapshot then
                        TCMusic.applyScratchSnapshot(item, {
                            tier = args.scratch,
                            delay = args.scratchDelay,
                            safeRoll = args.scratchSafeRoll,
                        })
                    end
                    inv:AddItem(item)
                    sendAddItemToContainer(inv, item)
                end
            end
        elseif command == "consumeCD" and args then
            local inv = player and player:getInventory()
            local removed = false
            if inv and args.itemId then
                removed = removeFirstMatchingItemRecursive(inv, function(it)
                    return it and it.getID and it:getID() == args.itemId
                end)
            end
            if (not removed) and inv and args.fullType then
                removeFirstMatchingItemRecursive(inv, function(it)
                    return it and it.getFullType and it:getFullType() == args.fullType
                end)
            end
        elseif command == "setDeviceMedia" and args and args.itemId and args.mediaItem then
            local inv = player and player:getInventory()
            local items = inv and inv:getItems()
            if items then
                for i = 0, items:size() - 1 do
                    local it = items:get(i)
                    if it and it.getID and it:getID() == args.itemId then
                        local md = it:getModData()
                        md.tcmusic = md.tcmusic or {}
                        md.tcmusic.mediaItem = args.mediaItem
                        md.tcmusic.deviceType = "InventoryItem"
                        md.tcmusic.isPlaying = false
                        if it.transmitModData then
                            it:transmitModData()
                        end
                        break
                    end
                end
            end
        elseif command == "clearDeviceMedia" and args and args.itemId then
            local inv = player and player:getInventory()
            local items = inv and inv:getItems()
            if items then
                for i = 0, items:size() - 1 do
                    local it = items:get(i)
                    if it and it.getID and it:getID() == args.itemId then
                        local md = it:getModData()
                        if md and md.tcmusic then
                            md.tcmusic.mediaItem = nil
                            md.tcmusic.isPlaying = false
                            if it.transmitModData then
                                it:transmitModData()
                            end
                        end
                        break
                    end
                end
            end
        elseif command == "setDeviceHeadphones" and args and args.itemId then
            local inv = player and player:getInventory()
            local items = inv and inv:getItems()
            if items then
                for i = 0, items:size() - 1 do
                    local it = items:get(i)
                    if it and it.getID and it:getID() == args.itemId then
                        local md = it:getModData()
                        md.tcmusic = md.tcmusic or {}
                        md.tcmusic.deviceType = "InventoryItem"
                        md.tcmusic.isPlaying = false
                        md.tcmusic.headphoneType = (args.headphoneType ~= nil) and args.headphoneType or -1
                        md.tm_headphoneType = md.tcmusic.headphoneType
                        md.tm_hasHeadphones = md.tcmusic.headphoneType >= 0
                        if md.tm_hasHeadphones then
                            md.tcmusic.headphoneItemFullType = args.headphoneItemFullType or "Base.Headphones"
                        else
                            md.tcmusic.headphoneItemFullType = nil
                        end
                        if it.transmitModData then
                            it:transmitModData()
                        end
                        break
                    end
                end
            end
        end
    end

    Events.OnClientCommand.Add(onClientCommand)
end

local function initializeTrueMusicMediaFix()
    -- MP-only hook. SP uses vanilla/local behavior.
    if not isClient() then return end
    if TMItemMPSync._hooked then return end

    local ISTCBoomboxAction = _G["ISTCBoomboxAction"]
    if not ISTCBoomboxAction then return end
    if not ISTCBoomboxAction.perform then return end

    local original_perform = ISTCBoomboxAction.perform

    local function isHeadphonesFullType(fullType)
        return fullType == "Base.Headphones" or fullType == "Base.Earbuds"
    end

    local function isInPlayerInventory(item, character)
        if not item then return false end
        if item.isInPlayerInventory then
            local ok, result = pcall(function() return item:isInPlayerInventory() end)
            if ok and result then
                return true
            end
        end
        local container = item.getContainer and item:getContainer() or nil
        return (container ~= nil) and (character ~= nil) and (container == character:getInventory())
    end

    -- Resolve a tcmusic.mediaItem value (full OR short type) to a real,
    -- loaded item script full type. Old saves and some code paths stored the
    -- SHORT type; "Tsarcraft."..name only covers the base pack - third-party
    -- music packs (TM_SpegHeddy.*, etc.) failed FindItem and the eject gave
    -- NOTHING back (tape eaten). The lazy map below covers every module.
    local shortTypeMap = nil
    local function resolveMediaFullType(name)
        if not name then return nil end
        local s = tostring(name)
        local sm = getScriptManager()
        if string.find(s, "%.") then
            if sm:FindItem(s) then return s end
        else
            local guess = "Tsarcraft." .. s
            if sm:FindItem(guess) then return guess end
        end
        if not shortTypeMap then
            shortTypeMap = {}
            local ok, all = pcall(function() return sm:getAllItems() end)
            if ok and all then
                for i = 0, all:size() - 1 do
                    local script = all:get(i)
                    if script and script.getFullName then
                        local fn = script:getFullName()
                        local shortName = string.match(fn, "%.([^%.]+)$") or fn
                        if shortName and not shortTypeMap[shortName] then
                            shortTypeMap[shortName] = fn
                        end
                    end
                end
            end
        end
        local short = string.match(s, "%.([^%.]+)$") or s
        return shortTypeMap[short]
    end

    function ISTCBoomboxAction:perform()
        local addMediaItemBefore = nil
        local addMediaWasInPlayer = false
        local tmMediaNameBefore = nil
        local addBatteryItemBefore = nil
        local addBatteryWasInPlayer = false
        local addHeadphonesItemBefore = nil
        local addHeadphonesWasInPlayer = false
        local batteryPowerBefore = nil
        local batteryHadBefore = nil
        local batteryIdsBefore = nil
        local headphonesIdsBefore = nil
        local headphonesHadBefore = false
        local headphoneFullTypeBefore = nil

        if self.mode == "AddMedia" and self.secondaryItem then
            addMediaItemBefore = self.secondaryItem
            addMediaWasInPlayer = isInPlayerInventory(addMediaItemBefore, self.character)
        elseif self.mode == "AddBattery" and self.secondaryItem then
            addBatteryItemBefore = self.secondaryItem
            addBatteryWasInPlayer = isInPlayerInventory(addBatteryItemBefore, self.character)
        elseif self.mode == "AddHeadphones" and self.secondaryItem then
            addHeadphonesItemBefore = self.secondaryItem
            addHeadphonesWasInPlayer = isInPlayerInventory(addHeadphonesItemBefore, self.character)
        elseif type(self.mode) == "string" and string.find(self.mode, "^RemoveMedia") then
            -- Covers RemoveMedia AND the bag/glovebox variants the context menu
            -- queues (RemoveMediaToGlove is what a CAR radio eject uses). Their
            -- old complete* server pass is dead B41 code vanilla never calls,
            -- so without this the tape was eaten in MP.
            if self.device and self.device.getModData then
                local md = self.device:getModData()
                if md and md.tcmusic and md.tcmusic.mediaItem then
                    tmMediaNameBefore = md.tcmusic.mediaItem
                end
            end
        elseif self.mode == "RemoveBattery" then
            if self.deviceData then
                if self.deviceData.getPower then
                    batteryPowerBefore = self.deviceData:getPower()
                end
                if self.deviceData.getHasBattery then
                    batteryHadBefore = self.deviceData:getHasBattery()
                end
            end
            local inv = self.character and self.character:getInventory()
            local items = inv and inv:getItems()
            if items then
                batteryIdsBefore = {}
                for i = 0, items:size() - 1 do
                    local it = items:get(i)
                    if it and it.getFullType and it:getFullType() == "Base.Battery" and it.getID then
                        batteryIdsBefore[it:getID()] = true
                    end
                end
            end
        elseif self.mode == "RemoveHeadphones" then
            if self.deviceData and self.deviceData.getHeadphoneType then
                headphonesHadBefore = self.deviceData:getHeadphoneType() >= 0
            end
            if self.device and self.device.getModData then
                local md = self.device:getModData()
                if md and md.tcmusic and isHeadphonesFullType(md.tcmusic.headphoneItemFullType) then
                    headphoneFullTypeBefore = md.tcmusic.headphoneItemFullType
                end
            end
            local inv = self.character and self.character:getInventory()
            local items = inv and inv:getItems()
            if items then
                headphonesIdsBefore = {}
                for i = 0, items:size() - 1 do
                    local it = items:get(i)
                    if it and it.getFullType and it.getID then
                        local ft = it:getFullType()
                        if ft == "Base.Headphones" or ft == "Base.Earbuds" then
                            headphonesIdsBefore[it:getID()] = true
                        end
                    end
                end
            end
        end

        original_perform(self)

        if self.mode == "AddMedia" and addMediaItemBefore and addMediaWasInPlayer then
            sendClientCommand(self.character, "TMItemMPSync", "consumeTape", {
                itemId = addMediaItemBefore.getID and addMediaItemBefore:getID() or nil,
                fullType = addMediaItemBefore.getFullType and addMediaItemBefore:getFullType() or nil
            })
            -- NOTE: do NOT call sendRemoveItemFromContainer here. On a client it fires a
            -- SyncItemDelete packet that B42.20 anti-cheat rejects ("no capability" kick).
            -- The server-side consumeTape handler performs the authoritative removal.

            if not isServer() then
                local playerNum = self.character:getPlayerNum()
                local inventoryPane = getPlayerInventory(playerNum)
                if inventoryPane then
                    inventoryPane:refreshBackpacks()
                end
            end

            if self.device and self.device.getModData then
                local md = self.device:getModData()
                if md and md.tcmusic and md.tcmusic.deviceType == "InventoryItem" and self.device.getID then
                    sendClientCommand(self.character, "TMItemMPSync", "setDeviceMedia", {
                        itemId = self.device:getID(),
                        mediaItem = md.tcmusic.mediaItem
                    })
                end
            end

        elseif self.mode == "AddBattery" and addBatteryItemBefore and addBatteryWasInPlayer then
            if addBatteryItemBefore.getID then
                sendClientCommand(self.character, "TMItemMPSync", "consumeBattery", {
                    itemId = addBatteryItemBefore:getID()
                })
            end
            -- Client-side sendRemoveItemFromContainer removed (anti-cheat SyncItemDelete kick).
            local inv = self.character:getInventory()
            if inv and addBatteryItemBefore then
                inv:DoRemoveItem(addBatteryItemBefore)
            end
        elseif self.mode == "AddHeadphones" and addHeadphonesItemBefore and addHeadphonesWasInPlayer then
            if addHeadphonesItemBefore.getID then
                sendClientCommand(self.character, "TMItemMPSync", "consumeHeadphones", {
                    itemId = addHeadphonesItemBefore:getID(),
                    fullType = addHeadphonesItemBefore.getFullType and addHeadphonesItemBefore:getFullType() or "Base.Headphones"
                })
            end
            if self.device and self.device.getModData then
                local md = self.device:getModData()
                md.tcmusic = md.tcmusic or {}
                md.tcmusic.headphoneItemFullType = addHeadphonesItemBefore.getFullType and addHeadphonesItemBefore:getFullType() or "Base.Headphones"
                if md.tcmusic.deviceType == "InventoryItem" and self.device.getID then
                    sendClientCommand(self.character, "TMItemMPSync", "setDeviceHeadphones", {
                        itemId = self.device:getID(),
                        headphoneType = (self.deviceData and self.deviceData.getHeadphoneType and self.deviceData:getHeadphoneType()) or 0,
                        headphoneItemFullType = md.tcmusic.headphoneItemFullType,
                    })
                end
                if self.device.transmitModData then
                    self.device:transmitModData()
                end
            end
            -- Client-side sendRemoveItemFromContainer removed (anti-cheat SyncItemDelete kick).
            local inv = self.character:getInventory()
            if inv and addHeadphonesItemBefore then
                inv:DoRemoveItem(addHeadphonesItemBefore)
            end

        elseif self.mode == "RemoveBattery" then
            local inv = self.character:getInventory()
            local clientItem = nil
            local items = inv and inv:getItems()
            if items then
                for i = items:size() - 1, 0, -1 do
                    local it = items:get(i)
                    if it and it.getFullType and it:getFullType() == "Base.Battery" and it.getID then
                        if not batteryIdsBefore or not batteryIdsBefore[it:getID()] then
                            clientItem = it
                            break
                        end
                    end
                end
            end

            if batteryHadBefore then
                if clientItem then
                    inv:DoRemoveItem(clientItem)
                end
                sendClientCommand(self.character, "TMItemMPSync", "giveBattery", {
                    power = batteryPowerBefore
                })
            elseif clientItem then
                inv:DoRemoveItem(clientItem)
            end

            if not isServer() then
                local playerNum = self.character:getPlayerNum()
                local inventoryPane = getPlayerInventory(playerNum)
                if inventoryPane then
                    inventoryPane:refreshBackpacks()
                end
            end
        elseif self.mode == "RemoveHeadphones" then
            local inv = self.character:getInventory()
            local clientItem = nil
            local items = inv and inv:getItems()
            if items then
                for i = items:size() - 1, 0, -1 do
                    local it = items:get(i)
                    if it and it.getFullType and it.getID then
                        local ft = it:getFullType()
                        if isHeadphonesFullType(ft) then
                            if not headphonesIdsBefore or not headphonesIdsBefore[it:getID()] then
                                clientItem = clientItem or it
                                inv:DoRemoveItem(it)
                            end
                        end
                    end
                end
            end

            if headphonesHadBefore then
                local fullType = (clientItem and clientItem.getFullType and clientItem:getFullType()) or headphoneFullTypeBefore or "Base.Headphones"
                sendClientCommand(self.character, "TMItemMPSync", "giveHeadphones", {
                    fullType = fullType
                })
            end
            if self.device and self.device.getModData then
                local md = self.device:getModData()
                if md and md.tcmusic then
                    md.tcmusic.headphoneItemFullType = nil
                    if md.tcmusic.deviceType == "InventoryItem" and self.device.getID then
                        sendClientCommand(self.character, "TMItemMPSync", "setDeviceHeadphones", {
                            itemId = self.device:getID(),
                            headphoneType = -1,
                            headphoneItemFullType = nil,
                        })
                    end
                    if self.device.transmitModData then
                        self.device:transmitModData()
                    end
                end
            end

            if not isServer() then
                local playerNum = self.character:getPlayerNum()
                local inventoryPane = getPlayerInventory(playerNum)
                if inventoryPane then
                    inventoryPane:refreshBackpacks()
                end
            end

        elseif tmMediaNameBefore then
            -- Eject (any RemoveMedia* variant): the tape is created SERVER-side
            -- only. No client-side scan/removal here: since nothing creates a
            -- local copy anymore, any inventory match would be a legitimately
            -- owned item - deleting it is exactly the "tape appears then
            -- vanishes a moment later" bug.
            local finalFullType = resolveMediaFullType(tmMediaNameBefore)

            if finalFullType then
                sendClientCommand(self.character, "TMItemMPSync", "giveTape", {
                    fullType = finalFullType
                })
            else
                log("TMItemMPSync: Unknown item type: " .. tostring(tmMediaNameBefore))
            end

            if not isServer() then
                local playerNum = self.character:getPlayerNum()
                local inventoryPane = getPlayerInventory(playerNum)
                if inventoryPane then
                    inventoryPane:refreshBackpacks()
                end
            end

            if self.device and self.device.getModData then
                local md = self.device:getModData()
                if md and md.tcmusic and md.tcmusic.deviceType == "InventoryItem" and self.device.getID then
                    sendClientCommand(self.character, "TMItemMPSync", "clearDeviceMedia", {
                        itemId = self.device:getID()
                    })
                end
            end
        end
    end

    -- Hook SWTCPlayerAction for CD player MP sync
    local SWTCPlayerActionClass = _G["SWTCPlayerAction"]
    if SWTCPlayerActionClass and SWTCPlayerActionClass.perform then
        local original_swtc_perform = SWTCPlayerActionClass.perform

        function SWTCPlayerActionClass:perform()
            local cdFullTypeBefore = nil
            local cdItemIdsBefore = nil
            local addCDItemBefore = nil
            local addCDWasInPlayer = false
            local scratchBefore, scratchDelayBefore, scratchSafeRollBefore = nil, nil, nil

            if self.mode == "RemoveMedia" then
                if self.device and self.device.getModData then
                    local md = self.device:getModData()
                    if md and md.customMusic then
                        if md.customMusic.fullItemType then
                            cdFullTypeBefore = md.customMusic.fullItemType
                        elseif md.customMusic.cdType then
                            cdFullTypeBefore = self:getItemFullType(md.customMusic.cdType)
                        end
                        -- Snapshot scratch BEFORE perform: performRemoveMedia
                        -- clears it off the device, and the server-side giveCD
                        -- must restamp it or the ejected CD loses its wear.
                        scratchBefore = md.customMusic.scratch
                        scratchDelayBefore = md.customMusic.scratchDelay
                        scratchSafeRollBefore = md.customMusic.scratchSafeRoll
                    end
                end
                if cdFullTypeBefore then
                    local targetInv = self.targetContainer or (self.character and self.character:getInventory())
                    local items = targetInv and targetInv:getItems()
                    if items then
                        cdItemIdsBefore = {}
                        for i = 0, items:size() - 1 do
                            local it = items:get(i)
                            if it and it.getID then
                                cdItemIdsBefore[it:getID()] = true
                            end
                        end
                    end
                end
            elseif self.mode == "AddMedia" and self.secondaryItem then
                addCDItemBefore = self.secondaryItem
                addCDWasInPlayer = isInPlayerInventory(addCDItemBefore, self.character)
            end

            original_swtc_perform(self)

            if self.mode == "RemoveMedia" and cdFullTypeBefore then
                local targetInv = self.targetContainer or (self.character and self.character:getInventory())
                local phantomItem = nil
                local items = targetInv and targetInv:getItems()
                if items then
                    for i = items:size() - 1, 0, -1 do
                        local it = items:get(i)
                        if it and it.getID and (not cdItemIdsBefore or not cdItemIdsBefore[it:getID()]) then
                            local itFull = it.getFullType and it:getFullType() or nil
                            if itFull and itFull == cdFullTypeBefore then
                                phantomItem = it
                                break
                            end
                        end
                    end
                end

                if phantomItem then
                    targetInv:DoRemoveItem(phantomItem)
                end

                local scriptItem = getScriptManager():FindItem(cdFullTypeBefore)
                if scriptItem then
                    sendClientCommand(self.character, "TMItemMPSync", "giveCD", {
                        fullType = cdFullTypeBefore,
                        scratch = scratchBefore,
                        scratchDelay = scratchDelayBefore,
                        scratchSafeRoll = scratchSafeRollBefore,
                    })
                end

                if not isServer() then
                    local playerNum = self.character:getPlayerNum()
                    local inventoryPane = getPlayerInventory(playerNum)
                    if inventoryPane then
                        inventoryPane:refreshBackpacks()
                    end
                end

                if self.device and self.device.transmitModData then
                    self.device:transmitModData()
                end

            elseif self.mode == "AddMedia" and addCDItemBefore and addCDWasInPlayer then
                sendClientCommand(self.character, "TMItemMPSync", "consumeCD", {
                    itemId = addCDItemBefore.getID and addCDItemBefore:getID() or nil,
                    fullType = addCDItemBefore.getFullType and addCDItemBefore:getFullType() or nil
                })
                -- Client-side sendRemoveItemFromContainer removed (anti-cheat SyncItemDelete kick).

                if not isServer() then
                    local playerNum = self.character:getPlayerNum()
                    local inventoryPane = getPlayerInventory(playerNum)
                    if inventoryPane then
                        inventoryPane:refreshBackpacks()
                    end
                end

                if self.device and self.device.transmitModData then
                    self.device:transmitModData()
                end
            end
        end
    end

    TMItemMPSync._hooked = true
end

-- Try hook at both boot/start to avoid load-order misses.
Events.OnGameBoot.Add(initializeTrueMusicMediaFix)
Events.OnGameStart.Add(initializeTrueMusicMediaFix)

