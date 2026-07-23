ISInventoryPageTransferHandler = {}


local function CleanUI_safeIsItemAllowed(container, item)
    if not container or not item then
        return false
    end
    local ok, result = pcall(function()
        return container:isItemAllowed(item)
    end)
    if ok then
        return result == true
    end
    return false
end

-- ----------------------------------------------------------------------------------------------------- --
-- Get / Check Container
-- ----------------------------------------------------------------------------------------------------- --
function ISInventoryPageTransferHandler.getContainers(inventoryPage)
    local sourceContainer = inventoryPage.inventoryPane.inventory
    local targetContainer = nil
    local playerNum = inventoryPage.player
    
    if inventoryPage.onCharacter then
        local lootWindow = getPlayerLoot(playerNum)
        if lootWindow and lootWindow.inventoryPane then
            targetContainer = lootWindow.inventoryPane.inventory
        end
    else
        local inventoryWindow = getPlayerInventory(playerNum)
        if inventoryWindow and inventoryWindow.inventoryPane then
            targetContainer = inventoryWindow.inventoryPane.inventory
        end
    end
    
    return sourceContainer, targetContainer
end

function ISInventoryPageTransferHandler.getAllNearbyContainers(inventoryPage)
    local containers = {}
    local targetPage = inventoryPage.onCharacter and getPlayerLoot(inventoryPage.player) or getPlayerInventory(inventoryPage.player)
    
    if targetPage and targetPage.backpacks then
        for _, backpack in ipairs(targetPage.backpacks) do
            if backpack.inventory then
                table.insert(containers, backpack.inventory)
            end
        end
    end
    
    return containers
end

-- ----------------------------------------------------------------------------------------------------- --
-- Get / Check Items
-- ----------------------------------------------------------------------------------------------------- --
function ISInventoryPageTransferHandler.getItemsTable(container)
    local result = {}
    if not container then return result end
    
    local items = container:getItems()
    for i = 1, items:size() do
        local item = items:get(i - 1)
        local itemType = item:getFullType()
        result[itemType] = result[itemType] or {}
        table.insert(result[itemType], item)
    end
    return result
end

function ISInventoryPageTransferHandler.getItemsCategoryTable(container)
    local result = {}
    if not container then return result end
    
    local items = container:getItems()
    for i = 1, items:size() do
        local item = items:get(i - 1)
        local category = item:getDisplayCategory()
        if not category or category == "" then
            category = "Other"
        end
        result[category] = result[category] or {}
        table.insert(result[category], item)
    end
    return result
end

function ISInventoryPageTransferHandler.canTransferItem(item, targetContainer, playerObj)
    if item:isFavorite() then return false end
    if item:isEquipped() then return false end
    if not CleanUI_safeIsItemAllowed(targetContainer, item) then return false end
    if item:isFavorite() and not targetContainer:isInCharacterInventory(playerObj) then return false end
    return true
end

function ISInventoryPageTransferHandler.canPlaceItemInContainer(item, container, addedWeight, playerObj)
    if not container:hasRoomFor(playerObj, item:getUnequippedWeight() + addedWeight) then
        return false
    end
    if not CleanUI_safeIsItemAllowed(container, item) then
        return false
    end
    return true
end

function ISInventoryPageTransferHandler.containerHasItemType(container, itemType)
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        if items:get(i):getFullType() == itemType then
            return true
        end
    end
    return false
end

function ISInventoryPageTransferHandler.containerHasCategory(container, category)
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        if items:get(i):getDisplayCategory() == category then
            return true
        end
    end
    return false
end

-- ----------------------------------------------------------------------------------------------------- --
-- Highlight Helper Functions
-- ----------------------------------------------------------------------------------------------------- --
function ISInventoryPageTransferHandler.getItemsToHighlightMap(items)
    local result = {}
    for _, item in ipairs(items) do
        result[item] = true
    end
    return result
end

function ISInventoryPageTransferHandler.onOptionHighlight(option, contextMenu, isHighlighted, inventoryPane, itemsMap)
    if isHighlighted then
        inventoryPane:setItemsToHighlight(contextMenu, itemsMap)
    else
        inventoryPane:setItemsToHighlight(contextMenu, nil)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Core Transfer Logic
-- ----------------------------------------------------------------------------------------------------- --

-- Single by Type
local function transferToSingleContainerByType(sourceContainer, targetContainer, playerObj, inventoryPane)
    local itemMapSource = ISInventoryPageTransferHandler.getItemsTable(sourceContainer)
    local itemMapTarget = ISInventoryPageTransferHandler.getItemsTable(targetContainer)
    local itemsToTransfer = {}

    for itemType, targetItems in pairs(itemMapTarget) do
        if itemMapSource[itemType] then
            for _, item in ipairs(itemMapSource[itemType]) do
                if ISInventoryPageTransferHandler.canTransferItem(item, targetContainer, playerObj) then
                    table.insert(itemsToTransfer, item)
                end
            end
        end
    end

    if #itemsToTransfer > 0 then
        inventoryPane:transferItemsByWeight(itemsToTransfer, targetContainer)
    end
end

-- Nearby by Type
local function transferToNearbyContainersByType(sourceContainer, targetContainers, playerObj)
    if #targetContainers == 0 then return end

    local existingTypes = {}
    for _, container in ipairs(targetContainers) do
        local items = container:getItems()
        for i = 0, items:size() - 1 do
            existingTypes[items:get(i):getFullType()] = true
        end
    end

    local itemMapSource = ISInventoryPageTransferHandler.getItemsTable(sourceContainer)
    local addedWeight = {}
    for _, container in ipairs(targetContainers) do
        addedWeight[container] = 0.0
    end

    for itemType, _ in pairs(existingTypes) do
        if itemMapSource[itemType] then
            for _, item in ipairs(itemMapSource[itemType]) do
                if not item:isFavorite() and not item:isEquipped() then
                    for _, container in ipairs(targetContainers) do
                        if ISInventoryPageTransferHandler.containerHasItemType(container, itemType) and
                           ISInventoryPageTransferHandler.canPlaceItemInContainer(item, container, addedWeight[container], playerObj) then
                            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, sourceContainer, container))
                            addedWeight[container] = addedWeight[container] + item:getUnequippedWeight()
                            break
                        end
                    end
                end
            end
        end
    end
end

-- Single by Category
local function transferToSingleContainerByCategory(sourceContainer, targetContainer, playerObj, inventoryPane)
    local categoryMapSource = ISInventoryPageTransferHandler.getItemsCategoryTable(sourceContainer)
    local categoryMapTarget = ISInventoryPageTransferHandler.getItemsCategoryTable(targetContainer)
    local itemsToTransfer = {}

    for category, targetItems in pairs(categoryMapTarget) do
        if categoryMapSource[category] then
            for _, item in ipairs(categoryMapSource[category]) do
                if ISInventoryPageTransferHandler.canTransferItem(item, targetContainer, playerObj) then
                    table.insert(itemsToTransfer, item)
                end
            end
        end
    end

    if #itemsToTransfer > 0 then
        inventoryPane:transferItemsByWeight(itemsToTransfer, targetContainer)
    end
end

-- Nearby by Category
local function transferToNearbyContainersByCategory(sourceContainer, targetContainers, playerObj)
    if #targetContainers == 0 then return end

    local existingCategories = {}
    for _, container in ipairs(targetContainers) do
        local items = container:getItems()
        for i = 0, items:size() - 1 do
            existingCategories[items:get(i):getDisplayCategory()] = true
        end
    end

    local categoryMapSource = ISInventoryPageTransferHandler.getItemsCategoryTable(sourceContainer)
    local addedWeight = {}
    for _, container in ipairs(targetContainers) do
        addedWeight[container] = 0.0
    end

    for category, _ in pairs(existingCategories) do
        if categoryMapSource[category] then
            for _, item in ipairs(categoryMapSource[category]) do
                if not item:isFavorite() and not item:isEquipped() then
                    for _, container in ipairs(targetContainers) do
                        if ISInventoryPageTransferHandler.containerHasCategory(container, category) and
                           ISInventoryPageTransferHandler.canPlaceItemInContainer(item, container, addedWeight[container], playerObj) then
                            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, sourceContainer, container))
                            addedWeight[container] = addedWeight[container] + item:getUnequippedWeight()
                            break
                        end
                    end
                end
            end
        end
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Public Transfer Functions
-- ----------------------------------------------------------------------------------------------------- --

function ISInventoryPageTransferHandler.transferSameType(inventoryPage)
    if isGamePaused() then return end
    local sourceContainer, targetContainer = ISInventoryPageTransferHandler.getContainers(inventoryPage)
    if not sourceContainer or not targetContainer then return end
    
    local playerObj = getSpecificPlayer(inventoryPage.player)
    local transferMethod = CleanUI_getTransferMethod()
    
    if transferMethod == "2" then
        local targetContainers = ISInventoryPageTransferHandler.getAllNearbyContainers(inventoryPage)
        transferToNearbyContainersByType(sourceContainer, targetContainers, playerObj)
    else
        transferToSingleContainerByType(sourceContainer, targetContainer, playerObj, inventoryPage.inventoryPane)
    end
end

function ISInventoryPageTransferHandler.transferSameCategory(inventoryPage)
    if isGamePaused() then return end
    local sourceContainer, targetContainer = ISInventoryPageTransferHandler.getContainers(inventoryPage)
    if not sourceContainer or not targetContainer then return end
    
    local playerObj = getSpecificPlayer(inventoryPage.player)
    local transferMethod = CleanUI_getTransferMethod()
    
    if transferMethod == "2" then
        local targetContainers = ISInventoryPageTransferHandler.getAllNearbyContainers(inventoryPage)
        transferToNearbyContainersByCategory(sourceContainer, targetContainers, playerObj)
    else
        transferToSingleContainerByCategory(sourceContainer, targetContainer, playerObj, inventoryPage.inventoryPane)
    end
end

ISInventoryPageTransferHandler.takeSameType = ISInventoryPageTransferHandler.transferSameType
ISInventoryPageTransferHandler.takeSameCategory = ISInventoryPageTransferHandler.transferSameCategory

-- ----------------------------------------------------------------------------------------------------- --
-- Move to Floor
-- ----------------------------------------------------------------------------------------------------- --
function ISInventoryPageTransferHandler.moveToFloor(inventoryPage)
    if isGamePaused() then return end
    
    local sourceContainer = inventoryPage.inventoryPane.inventory
    if not sourceContainer or sourceContainer:isEmpty() then return end
    
    local items = {}
    local itemArrayList = sourceContainer:getItems()
    for i = 1, itemArrayList:size() do
        table.insert(items, itemArrayList:get(i - 1))
    end
    
    local playerNum = inventoryPage.player
    ISInventoryPaneContextMenu.onMoveItemsTo(items, ISInventoryPage.floorContainer[playerNum + 1], playerNum)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Context Menu 
-- ----------------------------------------------------------------------------------------------------- --

local function getTransferableItemsByType(inventoryPage, sourceContainer, isNearby)
    local playerObj = getSpecificPlayer(inventoryPage.player)
    local itemMapSource = ISInventoryPageTransferHandler.getItemsTable(sourceContainer)
    local transferMethod = CleanUI_getTransferMethod()
    local existingTypes = {}
    local sameTypeItems = {}
    
    if isNearby or transferMethod == "2" then
        local targetContainers = ISInventoryPageTransferHandler.getAllNearbyContainers(inventoryPage)
        for _, container in ipairs(targetContainers) do
            local items = container:getItems()
            for i = 0, items:size() - 1 do
                existingTypes[items:get(i):getFullType()] = container
            end
        end
    else
        local _, targetContainer = ISInventoryPageTransferHandler.getContainers(inventoryPage)
        if targetContainer and not targetContainer:isEmpty() then
            local itemMapTarget = ISInventoryPageTransferHandler.getItemsTable(targetContainer)
            for itemType, _ in pairs(itemMapTarget) do
                existingTypes[itemType] = targetContainer
            end
        end
    end
    
    for itemType, container in pairs(existingTypes) do
        if itemMapSource[itemType] then
            for _, item in ipairs(itemMapSource[itemType]) do
                if ISInventoryPageTransferHandler.canTransferItem(item, container, playerObj) then
                    table.insert(sameTypeItems, item)
                end
            end
        end
    end
    
    return sameTypeItems
end

local function getTransferableItemsByCategory(inventoryPage, sourceContainer, isNearby)
    local playerObj = getSpecificPlayer(inventoryPage.player)
    local categoryMapSource = ISInventoryPageTransferHandler.getItemsCategoryTable(sourceContainer)
    local transferMethod = CleanUI_getTransferMethod()
    local existingCategories = {}
    local sameCategoryItems = {}
    
    if isNearby or transferMethod == "2" then
        local targetContainers = ISInventoryPageTransferHandler.getAllNearbyContainers(inventoryPage)
        for _, container in ipairs(targetContainers) do
            local items = container:getItems()
            for i = 0, items:size() - 1 do
                existingCategories[items:get(i):getDisplayCategory()] = container
            end
        end
    else
        local _, targetContainer = ISInventoryPageTransferHandler.getContainers(inventoryPage)
        if targetContainer and not targetContainer:isEmpty() then
            local categoryMapTarget = ISInventoryPageTransferHandler.getItemsCategoryTable(targetContainer)
            for category, _ in pairs(categoryMapTarget) do
                existingCategories[category] = targetContainer
            end
        end
    end
    
    for category, container in pairs(existingCategories) do
        if categoryMapSource[category] then
            for _, item in ipairs(categoryMapSource[category]) do
                if ISInventoryPageTransferHandler.canTransferItem(item, container, playerObj) then
                    table.insert(sameCategoryItems, item)
                end
            end
        end
    end
    
    return sameCategoryItems
end

function ISInventoryPageTransferHandler.getQuickTransferItems(inventoryPage, mode)
    -- Build the hover highlight list once for a quick button. The click action recalculates again for safety.
    local sourceContainer = inventoryPage and inventoryPage.inventoryPane and inventoryPage.inventoryPane.inventory
    if not sourceContainer then
        return {}
    end

    if mode == "type" then
        return getTransferableItemsByType(inventoryPage, sourceContainer, false)
    elseif mode == "category" then
        return getTransferableItemsByCategory(inventoryPage, sourceContainer, false)
    elseif mode == "floor" then
        local items = {}
        if sourceContainer:getType() == "floor" then
            return items
        end
        local itemArrayList = sourceContainer:getItems()
        for i = 1, itemArrayList:size() do
            local item = itemArrayList:get(i - 1)
            if item and (not item.isFavorite or not item:isFavorite()) and (not item.isEquipped or not item:isEquipped()) then
                table.insert(items, item)
            end
        end
        return items
    end

    return {}
end

function ISInventoryPageTransferHandler.clearQuickButtonHighlight(inventoryPage, button)
    -- Reset cached hover data and remove the visual highlight owned by this button.
    if inventoryPage and inventoryPage.inventoryPane and button then
        inventoryPage.inventoryPane:setItemsToHighlight(button, nil)
    end
    if button then
        button.cleanUIHoverTransferMode = nil
        button.cleanUIHoverItemsMap = nil
        button.cleanUIHoverHasItems = false
    end
end

function ISInventoryPageTransferHandler.updateQuickButtonHighlight(inventoryPage, button, mode)
    -- Compute affected items only once per hover session. Do not recalculate until the mouse leaves or the button is clicked.
    if not inventoryPage or not inventoryPage.inventoryPane or not button then
        return
    end

    if not button.mouseOver then
        ISInventoryPageTransferHandler.clearQuickButtonHighlight(inventoryPage, button)
        return
    end

    if button.cleanUIHoverTransferMode ~= mode then
        button.cleanUIHoverTransferMode = mode
        button.cleanUIHoverItemsMap = nil
        button.cleanUIHoverHasItems = false
    end

    if button.cleanUIHoverItemsMap == nil then
        local items = ISInventoryPageTransferHandler.getQuickTransferItems(inventoryPage, mode)
        local itemsMap = ISInventoryPageTransferHandler.getItemsToHighlightMap(items)
        button.cleanUIHoverItemsMap = itemsMap
        button.cleanUIHoverHasItems = #items > 0
    end

    if button.cleanUIHoverHasItems then
        inventoryPage.inventoryPane:setItemsToHighlight(button, button.cleanUIHoverItemsMap)
    else
        inventoryPage.inventoryPane:setItemsToHighlight(button, nil)
    end
end

function ISInventoryPageTransferHandler.showTransferMenu(inventoryPage, x, y)
    local player = inventoryPage.player
    local context = ISContextMenu.get(player, x, y)
    local sourceContainer = inventoryPage.inventoryPane.inventory

    local isInventory = inventoryPage.onCharacter
    local typeText = getText("UI_CleanUI_TransferByName")
    local categoryText = getText("UI_CleanUI_TransferByCategory")
    local typeFunc = isInventory and ISInventoryPageTransferHandler.transferSameType or ISInventoryPageTransferHandler.takeSameType
    local categoryFunc = isInventory and ISInventoryPageTransferHandler.transferSameCategory or ISInventoryPageTransferHandler.takeSameCategory
    
    -- Transfer/Take Same Type
    if sourceContainer then
        local sameTypeItems = getTransferableItemsByType(inventoryPage, sourceContainer, false)
        local sameTypeItemsMap = ISInventoryPageTransferHandler.getItemsToHighlightMap(sameTypeItems)
        
        local transferSameTypeOption = context:addOption(typeText, inventoryPage, typeFunc)
        if #sameTypeItems > 0 then
            transferSameTypeOption.onHighlight = ISInventoryPageTransferHandler.onOptionHighlight
            transferSameTypeOption.onHighlightParams = {inventoryPage.inventoryPane, sameTypeItemsMap}
        end
        
        -- Transfer/Take Same Category
        local sameCategoryItems = getTransferableItemsByCategory(inventoryPage, sourceContainer, false)
        local sameCategoryItemsMap = ISInventoryPageTransferHandler.getItemsToHighlightMap(sameCategoryItems)
        
        local transferSameCategoryOption = context:addOption(categoryText, inventoryPage, categoryFunc)
        if #sameCategoryItems > 0 then
            transferSameCategoryOption.onHighlight = ISInventoryPageTransferHandler.onOptionHighlight
            transferSameCategoryOption.onHighlightParams = {inventoryPage.inventoryPane, sameCategoryItemsMap}
        end
    end
    
    -- Move to Floor
    if not isInventory then
        local moveToFloorText = getText("ContextMenu_MoveToFloor")
        local moveToFloorOption = context:addOption(moveToFloorText, inventoryPage, ISInventoryPageTransferHandler.moveToFloor)
        if sourceContainer and sourceContainer:getType() == "floor" then
            moveToFloorOption.notAvailable = true
        end
    end
    
    return context
end

return ISInventoryPageTransferHandler