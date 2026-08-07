VFX = VFX or {}

VFX.AgingReplaceDebug = false
VFX.AgingReplaceMultiplayerDebug = false

VFX.HourlyTrackedItems = {}
VFX.DailyTrackedItems = {}
VFX.HourlyManagerRunning = false
VFX.DailyManagerRunning = false

local function VFXAgingReplaceDebug(message)
    if VFX.AgingReplaceDebug then
        print("[VFX Age Replace Tracking] " .. tostring(message))
    end
end

local function VFXAgingReplaceMultiplayerDebug(message)
    if VFX.AgingReplaceMultiplayerDebug then
        print("[VFX Age Replace MP] " .. tostring(message))
    end
end

local function VFXGetAgingReplaceItemDebugText(item)
    if not item then
        return "nil"
    end

    local itemType = "unknown"
    if item.getFullType then
        itemType = item:getFullType()
    end

    local itemID = "unknown"
    if item.getID then
        itemID = item:getID()
    end

    return tostring(itemType) .. " id=" .. tostring(itemID)
end

local function VFXGetAgingReplaceContainerDebugText(container)
    if not container then
        return "nil"
    end

    local containerType = "unknown"
    if container.getType then
        containerType = container:getType()
    end

    return tostring(container) .. " type=" .. tostring(containerType)
end

local function VFXGetAgingReplaceSquareDebugText(square)
    if not square then
        return "nil"
    end

    return tostring(square) .. " xyz=" .. tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
end

local function VFXGetAgingReplaceRuntimeDebugText()
    local isServerValue = "unknown"
    if isServer then
        isServerValue = tostring(isServer())
    end

    local isClientValue = "unknown"
    if isClient then
        isClientValue = tostring(isClient())
    end

    return "isServer=" .. isServerValue .. " isClient=" .. isClientValue
end

VFX.ReplaceItemTable = {
    -- Sourdough Starter
        {
        startItem = "VFX.SourdoughStarter",
        replaceItem = "VFX.SourdoughStarterUnfed",
        age = 1,
        interval = "hourly"
        },

        {
        startItem = "VFX.SourdoughStarterUnfed",
        replaceItem = "VFX.DeadSourdoughStarter",
        age = 1.5,
        interval = "hourly"
        },

    -- Vinegar

        {
        startItem = "VFX.VinegarStarterFermenting", -- No longer used, kept for phasing out old vinegar starters
        replaceItem = "VFX.VinegarStarter",         -- No longer used, kept for phasing out old vinegar starters
        age = 30,
        interval = "daily"
        },

        {
        startItem = "VFX.HomemadeVinegarFermentingVinegar",
        replaceItem = "VFX.HomemadeVinegar",
        age = 30,
        interval = "daily"
        },

        {
        startItem = "VFX.HomemadeVinegarFermentingAlcohol",
        replaceItem = "VFX.HomemadeVinegar",
        age = 60,
        interval = "daily"
        },

        {
        startItem = "VFX.HomemadeVinegarFermentingFruit",
        replaceItem = "VFX.HomemadeVinegar",
        age = 90,
        interval = "daily"
        },

    -- Homemade Beer
        {
        startItem = "VFX.HomemadeBeerPreparationFermenting",
        replaceItem = "VFX.HomemadeBeerPreparation",
        age = 7,
        interval = "daily"
        },

        {
        startItem = "VFX.BottleHomemadeBeerFermenting",
        replaceItem = "VFX.BottleHomemadeBeer",
        age = 5,
        interval = "daily"
        },

    -- Homemade Wine
        {
        startItem = "VFX.HomemadeWinePreparationFermenting",
        replaceItem = "VFX.HomemadeWinePreparation",
        age = 14,
        interval = "daily"
        },

    -- Yeast Starter

        {
        startItem = "VFX.YeastStarterFermenting",
        replaceItem = "VFX.YeastStarter",
        age = 5,
        interval = "daily"
        },

        {
        startItem = "VFX.YeastStarterShortFermenting",
        replaceItem = "VFX.YeastStarter",
        age = 2,
        interval = "hourly"
        },

        {
        startItem = "VFX.YeastStarter",
        replaceItem = "VFX.YeastStarterUnfed",
        age = 2,
        interval = "hourly"
        },

        {
        startItem = "VFX.YeastStarterUnfed",
        replaceItem = "VFX.DeadYeastStarter",
        age = 2,
        interval = "hourly"
        },
}

function VFX.GetReplacementData(item)
    local itemType = item:getFullType()
    for _, entry in ipairs(VFX.ReplaceItemTable) do
        if entry.startItem == itemType then
            return entry
        end
    end
    return nil
end

local function VFXGetReplacementDataByType(itemType)
    for _, entry in ipairs(VFX.ReplaceItemTable) do
        if entry.startItem == itemType then
            return entry
        end
    end

    return nil
end

local function VFXResolveAgingReplaceChain(startItemType, age)
    local currentItemType = startItemType
    local remainingAge = age
    local stepCount = 0
    local maxSteps = #VFX.ReplaceItemTable

    while true do
        local data = VFXGetReplacementDataByType(currentItemType)
        if not data then
            return currentItemType, nil, remainingAge, stepCount
        end

        if remainingAge < data.age then
            return currentItemType, data, remainingAge, stepCount
        end

        remainingAge = remainingAge - data.age
        currentItemType = data.replaceItem
        stepCount = stepCount + 1

        if stepCount > maxSteps then
            VFXAgingReplaceDebug("Stopped replacement chain because it exceeded available replacement entries: " .. tostring(startItemType))
            return currentItemType, nil, remainingAge, stepCount
        end
    end
end

local function VFXSetAgingReplaceTracked(item)
    if not item then
        return
    end

    item:getModData().VFX_AgingReplaceTracked = true
    VFXAgingReplaceDebug("Saved mod data: " .. tostring(item:getFullType()))
end

local function VFXClearAgingReplaceTracked(item)
    if not item then
        return
    end

    item:getModData().VFX_AgingReplaceTracked = false
    VFXAgingReplaceDebug("Cleared mod data: " .. tostring(item:getFullType()))
end

local function VFXAgingReplaceListHasItem(trackedList, item)
    for _, data in ipairs(trackedList) do
        if data.item == item then
            return true
        end
    end

    return false
end

local function VFXGetUpdatedAgingReplaceAge(item)
    if item and item.updateAge then
        item:updateAge()
    end

    return item:getAge()
end

local function VFXSetAgingReplaceAge(item, age)
    if item and age and item.setAge then
        item:setAge(age)
        VFXAgingReplaceDebug("Applied carried age to replacement item: " .. tostring(item:getFullType()) .. " | Age: " .. string.format("%.2f", age))
    end
end

local function VFXCreateAgingReplacementItem(replaceType, carriedAge, suppressOnCreate)
    local previousSuppressOnCreate = VFX.AgingReplaceSuppressOnCreate
    if suppressOnCreate then
        VFX.AgingReplaceSuppressOnCreate = true
    end

    local newItem = instanceItem(replaceType)

    if suppressOnCreate then
        VFX.AgingReplaceSuppressOnCreate = previousSuppressOnCreate
    end

    VFXSetAgingReplaceAge(newItem, carriedAge)
    return newItem
end

local function VFXTrackRestoredReplacementItem(item, data, source)
    if not item or not data then
        return
    end

    local interval = data.interval or "hourly"
    local trackedList = VFX.HourlyTrackedItems
    if interval == "daily" then
        trackedList = VFX.DailyTrackedItems
    end

    VFXSetAgingReplaceTracked(item)

    if VFXAgingReplaceListHasItem(trackedList, item) then
        VFXAgingReplaceDebug("Already in Lua tracking table during " .. source .. ": " .. tostring(item:getFullType()))
        return
    end

    table.insert(trackedList, {
        item = item,
        replacementData = data,
    })

    if interval == "daily" then
        VFX.StartDailyManager()
    else
        VFX.StartHourlyManager()
    end

    VFXAgingReplaceDebug("Re-tracked replacement chain result into Lua table (" .. interval .. ") during " .. source .. ": " .. tostring(item:getFullType()))
end

function VFX.TrackItemOnCreate(_item)
    if not _item then
        VFXAgingReplaceDebug("OnCreate called with nil item")
        return
    end

    if VFX.AgingReplaceSuppressOnCreate then
        VFXAgingReplaceDebug("Skipping OnCreate tracking during restore replacement: " .. tostring(_item:getFullType()))
        return
    end

    local data = VFX.GetReplacementData(_item)
    if not data then
        VFXAgingReplaceDebug("No replacement entry found for: " .. tostring(_item:getFullType()))
        return
    end

    local interval = data.interval or "hourly"
    VFXSetAgingReplaceTracked(_item)

    VFXAgingReplaceDebug("Now tracking (" .. interval .. "): " .. data.startItem .. " -> " .. data.replaceItem .. " at age " .. tostring(data.age) .. " | Current age: " .. tostring(VFXGetUpdatedAgingReplaceAge(_item)))

    local entry = {
        item = _item,
        replacementData = data,
    }

    if interval == "daily" then
        table.insert(VFX.DailyTrackedItems, entry)
        VFX.StartDailyManager()
    else
        table.insert(VFX.HourlyTrackedItems, entry)
        VFX.StartHourlyManager()
    end
end

function VFX.AgingOnCreate(_item)
    VFX.TrackItemOnCreate(_item)
end

function VFX.StartHourlyManager()
    if not VFX.HourlyManagerRunning then
        Events.EveryHours.Add(VFX.HourlyTrackingManager)
        VFX.HourlyManagerRunning = true
        VFXAgingReplaceDebug("Hourly manager started")
    end
end

function VFX.StartDailyManager()
    if not VFX.DailyManagerRunning then
        Events.EveryDays.Add(VFX.DailyTrackingManager)
        VFX.DailyManagerRunning = true
        VFXAgingReplaceDebug("Daily manager started")
    end
end

function VFX.HourlyTrackingManager()
    VFXAgingReplaceDebug("Hourly tick | Tracking: " .. tostring(#VFX.HourlyTrackedItems))

    if #VFX.HourlyTrackedItems == 0 then
        Events.EveryHours.Remove(VFX.HourlyTrackingManager)
        VFX.HourlyManagerRunning = false
        VFXAgingReplaceDebug("Hourly manager stopped (no items left)")
        return
    end

    VFX.ProcessTrackedItems(VFX.HourlyTrackedItems)
end

function VFX.DailyTrackingManager()
    VFXAgingReplaceDebug("Daily tick | Tracking: " .. tostring(#VFX.DailyTrackedItems))

    if #VFX.DailyTrackedItems == 0 then
        Events.EveryDays.Remove(VFX.DailyTrackingManager)
        VFX.DailyManagerRunning = false
        VFXAgingReplaceDebug("Daily manager stopped (no items left)")
        return
    end

    VFX.ProcessTrackedItems(VFX.DailyTrackedItems)
end

function VFX.ProcessTrackedItems(trackedList)
    for i = #trackedList, 1, -1 do
        local data = trackedList[i]
        local item = data.item
        local rd = data.replacementData

        if not item or (not item:getContainer() and not item:getWorldItem()) then
            VFXAgingReplaceDebug("Item removed (eaten/destroyed): " .. rd.startItem)
            VFXClearAgingReplaceTracked(item)
            table.remove(trackedList, i)
        else
            local age = VFXGetUpdatedAgingReplaceAge(item)
            VFXAgingReplaceDebug(rd.startItem .. " | Age: " .. string.format("%.2f", age) .. " / " .. tostring(rd.age))

            if age >= rd.age then
                VFXAgingReplaceDebug("Age threshold reached! Replacing with: " .. rd.replaceItem)
                VFXClearAgingReplaceTracked(item)
                VFX.ReplaceTrackedItem(item, rd.replaceItem)
                table.remove(trackedList, i)
            end
        end
    end
end

function VFX.ReplaceTrackedItem(item, replaceType, carriedAge, suppressOnCreate)
    local worldItem = item:getWorldItem()
    local newItem = nil

    if worldItem then
        local square = worldItem:getSquare()
        local container = item:getContainer()

        VFXAgingReplaceMultiplayerDebug("World replacement requested | old=" .. VFXGetAgingReplaceItemDebugText(item) .. " | worldItem=" .. tostring(worldItem) .. " | container=" .. VFXGetAgingReplaceContainerDebugText(container) .. " | square=" .. VFXGetAgingReplaceSquareDebugText(square) .. " | replaceType=" .. tostring(replaceType) .. " | " .. VFXGetAgingReplaceRuntimeDebugText())

        if square then
            local xoff = worldItem:getOffX()
            local yoff = worldItem:getOffY()
            local zoff = worldItem:getOffZ()

            newItem = VFXCreateAgingReplacementItem(replaceType, carriedAge, suppressOnCreate)

            if not newItem then
                VFXAgingReplaceMultiplayerDebug("World replacement failed to instance replacement | old=" .. VFXGetAgingReplaceItemDebugText(item) .. " | replaceType=" .. tostring(replaceType))
                return nil
            end

            square:transmitRemoveItemFromSquare(worldItem)
            square:removeWorldObject(worldItem)
            if container and container.getType and container:getType() == "floor" then
                container:Remove(item)
            end
            item:setWorldItem(nil)

            local addedItem = square:AddWorldInventoryItem(newItem, xoff, yoff, zoff)
            local addedWorldItem = nil
            if addedItem and addedItem.getWorldItem then
                addedWorldItem = addedItem:getWorldItem()
            elseif newItem.getWorldItem then
                addedWorldItem = newItem:getWorldItem()
            end

            if addedWorldItem and isServer and isServer() then
                addedWorldItem:transmitCompleteItemToClients()
            end

            VFXAgingReplaceMultiplayerDebug("World replacement completed | old=" .. VFXGetAgingReplaceItemDebugText(item) .. " | new=" .. VFXGetAgingReplaceItemDebugText(newItem) .. " | offsets=" .. tostring(xoff) .. "," .. tostring(yoff) .. "," .. tostring(zoff) .. " | addedItem=" .. tostring(addedItem) .. " | addedWorldItem=" .. tostring(addedWorldItem) .. " | square=" .. VFXGetAgingReplaceSquareDebugText(square))
            VFXAgingReplaceDebug("Replaced on ground at square: " .. tostring(square))
        else
            VFXAgingReplaceMultiplayerDebug("World replacement skipped because square was nil | old=" .. VFXGetAgingReplaceItemDebugText(item) .. " | worldItem=" .. tostring(worldItem) .. " | replaceType=" .. tostring(replaceType))
        end
    else
        local container = item:getContainer()

        VFXAgingReplaceMultiplayerDebug("Container replacement requested | old=" .. VFXGetAgingReplaceItemDebugText(item) .. " | container=" .. VFXGetAgingReplaceContainerDebugText(container) .. " | replaceType=" .. tostring(replaceType) .. " | " .. VFXGetAgingReplaceRuntimeDebugText())

        if not container then
            VFXAgingReplaceMultiplayerDebug("Container replacement skipped because container and world item were nil | old=" .. VFXGetAgingReplaceItemDebugText(item) .. " | replaceType=" .. tostring(replaceType))
            return nil
        end

        newItem = VFXCreateAgingReplacementItem(replaceType, carriedAge, suppressOnCreate)
        container:AddItem(newItem)
        container:Remove(item)
        VFXAgingReplaceMultiplayerDebug("Container replacement completed | old=" .. VFXGetAgingReplaceItemDebugText(item) .. " | new=" .. VFXGetAgingReplaceItemDebugText(newItem) .. " | container=" .. VFXGetAgingReplaceContainerDebugText(container))
        VFXAgingReplaceDebug("Replaced in container: " .. tostring(container))
    end

    return newItem
end

function VFX.RestoreAgingReplaceTracking(item, source, pendingWorldReplacements)
    if not item then
        return false
    end

    source = source or "unknown"
    local modData = item:getModData()
    local data = VFX.GetReplacementData(item)

    if modData.VFX_AgingReplaceTracked == false then
        return false
    end

    if not modData.VFX_AgingReplaceTracked then
        if not data then
            return false
        end

        VFXAgingReplaceDebug("Found legacy replacement item during " .. source .. ": " .. tostring(item:getFullType()))
        VFXSetAgingReplaceTracked(item)
    else
        VFXAgingReplaceDebug("Found saved mod data during " .. source .. ": " .. tostring(item:getFullType()))
    end

    if not data then
        VFXClearAgingReplaceTracked(item)
        VFXAgingReplaceDebug("Cleared invalid restored item: " .. tostring(item:getFullType()))
        return true
    end

    local interval = data.interval or "hourly"
    local trackedList = VFX.HourlyTrackedItems
    if interval == "daily" then
        trackedList = VFX.DailyTrackedItems
    end

    local age = VFXGetUpdatedAgingReplaceAge(item)
    VFXAgingReplaceDebug("Updated restored item age during " .. source .. ": " .. string.format("%.2f", age) .. " / " .. tostring(data.age))

    if age >= data.age then
        local finalItemType, finalData, remainingAge, stepCount = VFXResolveAgingReplaceChain(item:getFullType(), age)
        VFXAgingReplaceDebug("Restored item already reached age threshold during " .. source .. ". Resolved replacement chain to: " .. finalItemType .. " | Steps: " .. tostring(stepCount) .. " | Remaining age: " .. string.format("%.2f", remainingAge))
        local carriedAge = nil
        if finalData then
            carriedAge = remainingAge
        end

        if pendingWorldReplacements and item:getWorldItem() then
            table.insert(pendingWorldReplacements, {
                item = item,
                finalItemType = finalItemType,
                finalData = finalData,
                carriedAge = carriedAge,
                source = source,
            })
            VFXAgingReplaceMultiplayerDebug("Queued restore world replacement until after LoadGridsquare scan | item=" .. VFXGetAgingReplaceItemDebugText(item) .. " | finalItemType=" .. tostring(finalItemType) .. " | source=" .. tostring(source))
            return true
        end

        VFXClearAgingReplaceTracked(item)
        local newItem = VFX.ReplaceTrackedItem(item, finalItemType, carriedAge, true)
        VFXTrackRestoredReplacementItem(newItem, finalData, source)
        return true
    end

    if VFXAgingReplaceListHasItem(trackedList, item) then
        VFXAgingReplaceDebug("Already in Lua tracking table during " .. source .. ": " .. tostring(item:getFullType()))
        return true
    end

    table.insert(trackedList, {
        item = item,
        replacementData = data,
    })

    if interval == "daily" then
        VFX.StartDailyManager()
    else
        VFX.StartHourlyManager()
    end

    VFXAgingReplaceDebug("Re-tracked from mod data into Lua table (" .. interval .. ") during " .. source .. ": " .. tostring(item:getFullType()))
    return true
end

local function VFXRestoreAgingReplaceInventory(inventory, source)
    if not inventory then
        return 0
    end

    local foundCount = 0
    local items = inventory:getItems()
    for i = items:size() - 1, 0, -1 do
        local item = items:get(i)
        if VFX.RestoreAgingReplaceTracking(item, source) then
            foundCount = foundCount + 1
        end

        if instanceof(item, "InventoryContainer") then
            foundCount = foundCount + VFXRestoreAgingReplaceInventory(item:getInventory(), source .. " nested container")
        end
    end

    return foundCount
end

local function VFXRestoreAgingReplaceGridSquare(square)
    if not square then
        return
    end

    local source = "LoadGridsquare " .. tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ())
    local foundCount = 0
    local pendingWorldReplacements = {}

    local worldObjects = square:getWorldObjects()
    if worldObjects then
        for i = worldObjects:size() - 1, 0, -1 do
            local worldObject = worldObjects:get(i)
            local item = worldObject and worldObject:getItem()
            if VFX.RestoreAgingReplaceTracking(item, source .. " floor", pendingWorldReplacements) then
                foundCount = foundCount + 1
            end
        end
    end

    if #pendingWorldReplacements > 0 then
        VFXAgingReplaceMultiplayerDebug("Processing queued restore world replacements after LoadGridsquare scan | count=" .. tostring(#pendingWorldReplacements) .. " | square=" .. VFXGetAgingReplaceSquareDebugText(square))
        for _, pendingReplacement in ipairs(pendingWorldReplacements) do
            local item = pendingReplacement.item
            if item and item:getWorldItem() then
                VFXClearAgingReplaceTracked(item)
                local newItem = VFX.ReplaceTrackedItem(item, pendingReplacement.finalItemType, pendingReplacement.carriedAge, true)
                VFXTrackRestoredReplacementItem(newItem, pendingReplacement.finalData, pendingReplacement.source)
            else
                VFXAgingReplaceMultiplayerDebug("Skipped queued restore world replacement because item/worldItem disappeared | item=" .. VFXGetAgingReplaceItemDebugText(item) .. " | finalItemType=" .. tostring(pendingReplacement.finalItemType) .. " | source=" .. tostring(pendingReplacement.source))
            end
        end
    end

    local objects = square:getObjects()
    if objects then
        for i = objects:size() - 1, 0, -1 do
            local obj = objects:get(i)
            local container = obj and obj:getContainer()
            if container then
                foundCount = foundCount + VFXRestoreAgingReplaceInventory(container, source .. " container " .. tostring(container:getType()))
            end
        end
    end

    if foundCount > 0 then
        VFXAgingReplaceDebug("LoadGridsquare restore scan found mod data tracked items: " .. tostring(foundCount) .. " at " .. tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ()))
    end
end

Events.LoadGridsquare.Add(VFXRestoreAgingReplaceGridSquare)
