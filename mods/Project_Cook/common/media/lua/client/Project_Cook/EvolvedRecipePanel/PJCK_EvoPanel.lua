require "Entity/ISUI/Controls/ISTableLayout"
require "Project_Cook/Cell/PJCK_BaseItemColumn"
require "Project_Cook/Cell/PJCK_InputColumn"
require "Project_Cook/PJCK_CookingEligibility"
PJCK_EvoPanel = ISTableLayout:derive("PJCK_EvoPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------- --
-- initialise
-- ----------------------------------------- --
function PJCK_EvoPanel:initialise()
    ISTableLayout.initialise(self)
end

function PJCK_EvoPanel:new(x, y, width, height, Window)
    local o = ISTableLayout:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o:noBackground()
    o.Window = Window
    o.player = Window.player
    o.baseItem = nil
    o.recipe = nil
    o.preCookItems = {}
    o.switchItems = {}
    o.showPossible = {Ingredient = false,Seasoning = false}

    o.innerTitleHeight = math.floor(FONT_HGT_SMALL * 1.5)
    o.padding = math.floor(FONT_HGT_SMALL * 0.4)

    return o
end

-- ----------------------------------------- --
-- createChildren
-- ----------------------------------------- --
function PJCK_EvoPanel:createChildren()
    self:addRowFill(nil)

    local spacingColumn1 = self:addColumn(nil)
    spacingColumn1.minimumWidth = self.padding

    self.leftColumn = self:addColumn(nil)

    local spacingColumn2 = self:addColumn(nil)
    spacingColumn2.minimumWidth = self.padding

    self.rightColumn = self:addColumn(nil)

    local spacingColumn3 = self:addColumn(nil)
    spacingColumn3.minimumWidth = self.padding

    self:createBaseItemColumn()
    self:createInputColumn()
end

function PJCK_EvoPanel:createBaseItemColumn()
    self.baseItemColumn = PJCK_BaseItemColumn:new(0, 0, 10, 10, self)
    self.baseItemColumn:initialise()
    self:setElement(self.leftColumn:index(), 0, self.baseItemColumn)

    self.baseItemPanel = self.baseItemColumn.baseItemPanel
    self.cookingInfoPanel = self.baseItemColumn.cookingInfoPanel
end

function PJCK_EvoPanel:createInputColumn()
    self.inputColumn = PJCK_InputColumn:new(0, 0, 10, 10, self)
    self.inputColumn:initialise()
    self:setElement(self.rightColumn:index(), 0, self.inputColumn)
    
    self.ingredientsPanel = self.inputColumn.ingredientsPanel
    self.seasoningsPanel = self.inputColumn.seasoningsPanel
end

-- ----------------------------------------- --
-- Logic Helper
-- ----------------------------------------- --

function PJCK_EvoPanel:getItemStatusRatio(item)
    if not item then return 0 end
    
    -- Drainable Item
    if item:IsDrainable() then
        return math.max(0, math.min(1, item:getCurrentUsesFloat()))
    end
    
    -- Food
    if instanceof(item, "Food") then
        local actualWeight = item:getActualWeight()
        local maxWeight = item:getScriptItem():getActualWeight()
        return maxWeight > 0 and actualWeight / maxWeight or 0
    end
    
    return 1
end

function PJCK_EvoPanel:getCookStatus()
    local cookStatus = self.cookingInfoPanel.contentType
    return cookStatus or nil
    -- "noBaseItem", "noRecipe", "addOneFirst", "showRecipes"，"showNutrition"， "needWater"
end

function PJCK_EvoPanel:isValidForPanel(item, panelType)
    -- Keep technical food items, such as tobacco/smoking items, out of both ingredient panels.
    if PJCK_CookingEligibility and PJCK_CookingEligibility.isTechnicalNonCookingFood(item) then
        return false
    end

    if panelType == "Ingredient" then
        return self:isValidIngredient(item)
    elseif panelType == "Seasoning" then
        return self:isValidSeasoning(item)
    end
    return false
end

function PJCK_EvoPanel:toggleShowPossible(panelType)
    self.showPossible[panelType] = not self.showPossible[panelType]
end

local function PJCK_itemInContainersById(containers, itemId)
    if not containers or not itemId then return nil end
    for i = 0, containers:size() - 1 do
        local container = containers:get(i)
        if container and container.getItemById then
            local found = container:getItemById(itemId)
            if found then
                return found
            end
        end
    end
    return nil
end

local function PJCK_snapshotContainerItemIds(containers)
    local ids = {}
    if not containers then return ids end
    for i = 0, containers:size() - 1 do
        local container = containers:get(i)
        if container and container.getItems then
            local items = container:getItems()
            for j = 0, items:size() - 1 do
                local it = items:get(j)
                if it and it.getID then
                    ids[it:getID()] = true
                end
            end
        end
    end
    return ids
end

local function PJCK_toFullTypeLikeBaseItem(baseItem, typeOrFullType)
    if not baseItem or not typeOrFullType then return nil end
    if string.find(typeOrFullType, '%.') then return typeOrFullType end
    if baseItem.getModule then
        return moduleDotType(baseItem:getModule(), typeOrFullType)
    end
    return typeOrFullType
end

function PJCK_EvoPanel:tryResolvePendingBaseItemReplacement(containers)
    local pending = self.pendingBaseItemReplacement
    if not pending then return nil end

    if pending["until"] and getTimestampMs() > pending["until"] then
        self.pendingBaseItemReplacement = nil
        return nil
    end

    if pending.expectedId then
        local byId = PJCK_itemInContainersById(containers, pending.expectedId)
        if byId then
            self.pendingBaseItemReplacement = nil
            return byId
        end
    end

    if not containers then return nil end

    local candidates = {}
    for i = 0, containers:size() - 1 do
        local container = containers:get(i)
        if container and container.getItems then
            local items = container:getItems()
            for j = 0, items:size() - 1 do
                local it = items:get(j)
                if it and it.getID and (not pending.beforeIds or not pending.beforeIds[it:getID()]) then
                    table.insert(candidates, it)
                end
            end
        end
    end

    if pending.expectedFullType then
        for _, it in ipairs(candidates) do
            if it.getFullType and it:getFullType() == pending.expectedFullType then
                self.pendingBaseItemReplacement = nil
                return it
            end
        end
    end

    local function looksLikeUsableBaseItem(it)
        local recipes = RecipeManager.getEvolvedRecipe(it, self.player, containers, false)
        return recipes and recipes:size() > 0
    end

    for _, it in ipairs(candidates) do
        if looksLikeUsableBaseItem(it) and (not pending.usedItemFullType or it:getFullType() ~= pending.usedItemFullType) then
            self.pendingBaseItemReplacement = nil
            return it
        end
    end

    return nil
end

-- ----------------------------------------- --
-- Evolved Logic
-- ----------------------------------------- --
function PJCK_EvoPanel:setContainers(containers)
    local function isItemInContainers(item)
        if not containers then return false end
        for i = 0, containers:size() - 1 do
            if containers:get(i):contains(item) then
                return true
            end
        end
        return false
    end

    local function isBaseItemTransferPending()
        if not self.baseItem or not self.pendingBaseItemTransferId then return false end
        if self.baseItem:getID() ~= self.pendingBaseItemTransferId then return false end

        if self.baseItem:getContainer() == self.player:getInventory() then
            self.pendingBaseItemTransferId = nil
            self.pendingBaseItemTransferUntil = nil
            return false
        end

        if self.pendingBaseItemTransferUntil and getTimestampMs() <= self.pendingBaseItemTransferUntil then
            return true
        end

        self.pendingBaseItemTransferId = nil
        self.pendingBaseItemTransferUntil = nil
        return false
    end

    if self.pendingBaseItemReplacement then
        local resolvedBaseItem = self:tryResolvePendingBaseItemReplacement(containers)
        if resolvedBaseItem then
            self.baseItem = resolvedBaseItem
            self.pendingBaseItemTransferId = nil
            self.pendingBaseItemTransferUntil = nil
            local recipes = self:getRecipes(resolvedBaseItem)
            if recipes and recipes:size() == 1 then
                self:setRecipe(recipes:get(0))
            end
        end
    end

    if self.baseItem and not isItemInContainers(self.baseItem) then
        if not isBaseItemTransferPending() then
            local resolvedBaseItem = self:tryResolvePendingBaseItemReplacement(containers)
            if resolvedBaseItem then
                self.baseItem = resolvedBaseItem
            else
                self:setBaseItem(nil)
            end
        end
    elseif not self.baseItem and self.pendingBaseItemReplacement then
        local resolvedBaseItem = self:tryResolvePendingBaseItemReplacement(containers)
        if resolvedBaseItem then
            self.baseItem = resolvedBaseItem
        end
    end

    if self.preCookItems and #self.preCookItems > 0 then
        for i = #self.preCookItems, 1, -1 do
            if not isItemInContainers(self.preCookItems[i]) then
                self:removePreCookItems(self.preCookItems[i])
            end
        end
    end
    
    self:onUpdateContainers()
end

-- Resolve the currently selected base item to a live inventory instance before running actions.
function PJCK_EvoPanel:resolveCurrentBaseItem(preferPlayerInventory)
    local baseItem = self.baseItem
    if not baseItem then return nil end

    if baseItem.getContainer and baseItem:getContainer() then
        return baseItem
    end

    local itemId = baseItem.getID and baseItem:getID() or nil
    local playerInv = self.player and self.player:getInventory() or nil

    -- Prefer the player inventory copy because MP transfers can replace the client-side item instance.
    if preferPlayerInventory and itemId and playerInv and playerInv.getItemById then
        local invItem = playerInv:getItemById(itemId)
        if invItem then
            self.baseItem = invItem
            return invItem
        end
    end

    -- Fall back to every currently accessible container tracked by the vanilla inventory context.
    local containers = ISInventoryPaneContextMenu.getContainers(self.player)
    local resolvedBaseItem = PJCK_itemInContainersById(containers, itemId)
    if not resolvedBaseItem and self.tryResolvePendingBaseItemReplacement then
        resolvedBaseItem = self:tryResolvePendingBaseItemReplacement(containers)
    end

    if resolvedBaseItem then
        self.baseItem = resolvedBaseItem
        return resolvedBaseItem
    end

    return nil
end

function PJCK_EvoPanel:preparePendingBaseItemReplacement(expectedFullType, usedItemFullType)
    local baseItem = self:getBaseItem()
    if not baseItem or not expectedFullType then return end

    local containers = ISInventoryPaneContextMenu.getContainers(self.player)
    self.pendingBaseItemReplacement = {
        beforeIds = PJCK_snapshotContainerItemIds(containers),
        oldBaseId = baseItem.getID and baseItem:getID() or nil,
        oldBaseFullType = baseItem.getFullType and baseItem:getFullType() or nil,
        expectedFullType = PJCK_toFullTypeLikeBaseItem(baseItem, expectedFullType),
        usedItemFullType = usedItemFullType,
        ["until"] = getTimestampMs() + 12000,
    }
end

function PJCK_EvoPanel:setBaseItem(baseItem)
    self.baseItem = baseItem
    self.pendingBaseItemTransferId = nil
    self.pendingBaseItemTransferUntil = nil
    self.pendingBaseItemReplacement = nil

    if baseItem then
        if luautils.haveToBeTransfered(self.player, baseItem, true) then
            self.pendingBaseItemTransferId = baseItem:getID()
            self.pendingBaseItemTransferUntil = getTimestampMs() + 6000
        end

        ISInventoryPaneContextMenu.transferIfNeeded(self.player, baseItem)

        local recipes = self:getRecipes(baseItem)
        if recipes and recipes:size() == 1 then
            self:setRecipe(recipes:get(0))
        else
            self:setRecipe(nil)
        end
    else
        self:setRecipe(nil)
    end
    self:onUpdateBaseItem()
end

function PJCK_EvoPanel:refreshBaseItemAfterRecipeAction(baseItem, replacementInfo)
    self.baseItem = baseItem
    self.pendingBaseItemTransferId = nil
    self.pendingBaseItemTransferUntil = nil
    self.pendingBaseItemReplacement = nil

    if replacementInfo then
        replacementInfo["until"] = getTimestampMs() + 8000
        replacementInfo.expectedId = baseItem and baseItem.getID and baseItem:getID() or nil
        self.pendingBaseItemReplacement = replacementInfo
    end

    if self.baseItem then
        self.pendingBaseItemTransferId = self.baseItem:getID()
        self.pendingBaseItemTransferUntil = getTimestampMs() + 6000

        local invItem = self.player and self.player:getInventory() and self.player:getInventory():getItemById(self.baseItem:getID()) or nil
        if invItem then
            self.baseItem = invItem
            self.pendingBaseItemReplacement = nil
        end
    end

    self:onUpdateBaseItem()
    self:onUpdateContainers()
end

function PJCK_EvoPanel:getBaseItem()
    return self.baseItem or nil
end

function PJCK_EvoPanel:setRecipe(recipe)
    self.recipe = recipe
    self:onUpdateRecipe()
end

function PJCK_EvoPanel:getRecipes(baseItem)
    if not baseItem then return nil end

    local containers = ISInventoryPaneContextMenu.getContainers(self.player)
    return RecipeManager.getEvolvedRecipe(baseItem, self.player, containers, false)
end

function PJCK_EvoPanel:getRecipe()
    return self.recipe or nil
end

function PJCK_EvoPanel:getInputList(panelType)
    local recipe = self:getRecipe()
    local baseItem = self:getBaseItem()
    
    local itemInfo = {}

    -- not baseitem show all food
    if not baseItem then
        local containers = ISInventoryPaneContextMenu.getContainers(self.player)
        local allItems = ArrayList.new()
        CraftRecipeManager.getAllItemsFromContainers(containers, allItems)
        
        for i = 0, allItems:size() - 1 do
            local item = allItems:get(i)
            if item and self:isValidForPanel(item, panelType) and PJCK_CookingEligibility.isLooseCookingFood(item, self.player) then
                local itemName = item:getName()
                self:addToItemInfo(itemInfo, item, itemName, true)
            end
        end
    else
        -- return blank if not recipe but baseitem
        if not recipe then return {} end
        
        local containers = ISInventoryPaneContextMenu.getContainers(self.player)
        local availableItems = recipe:getItemsCanBeUse(self.player, baseItem, containers)
        
        -- getItemsCanBeUse
        if availableItems and availableItems:size() > 0 then
            for i = 0, availableItems:size() - 1 do
                local item = availableItems:get(i)
                if item and self:isValidForPanel(item, panelType) then
                    local itemName = item:getName()
                    self:addToItemInfo(itemInfo, item, itemName, true, false)
                end
            end
        end

        -- Frozen items are intentionally not returned by vanilla getItemsCanBeUse()
        -- when the evolved recipe does not allow frozen ingredients.  They are
        -- still useful to show as thaw-first candidates, so scan nearby
        -- containers and add compatible frozen items as visible but non-addable.
        self:addFrozenPreviewItems(itemInfo, panelType, recipe, baseItem, containers)
        
        -- getPossibleItems
        if self.showPossible[panelType] then
            local possibleItems = recipe:getPossibleItems()
            if possibleItems and possibleItems:size() > 0 then
                for i = 0, possibleItems:size() - 1 do
                    local itemType = possibleItems:get(i):getFullType()
                    local scriptItem = ScriptManager.instance:FindItem(itemType)
                    
                    if scriptItem then
                        local dummyItem = scriptItem:InstanceItem(nil)
                        if dummyItem and self:isValidForPanel(dummyItem, panelType) then
                            local itemName = dummyItem:getName()

                            if not itemInfo[itemName] or (itemInfo[itemName] and itemInfo[itemName].count == 0) then
                                self:addToItemInfo(itemInfo, dummyItem, itemName, false)
                            end
                        end
                    end
                end
            end
        end
    end

    local inputList = {}
    for _, data in pairs(itemInfo) do
        table.insert(inputList, data)
    end
    
    return inputList
end

function PJCK_EvoPanel:isFrozenBlockedForRecipe(item, recipe)
    return item
        and recipe
        and instanceof(item, "Food")
        and item:isFrozen()
        and not recipe:isAllowFrozenItem()
end

function PJCK_EvoPanel:isFrozenPreviewItem(item, recipe, baseItem, panelType)
    if not item or not recipe or not baseItem then return false end
    if not self:isValidForPanel(item, panelType) then return false end
    if not self:isFrozenBlockedForRecipe(item, recipe) then return false end

    if PJCK_CookingEligibility and PJCK_CookingEligibility.isTechnicalNonCookingFood and PJCK_CookingEligibility.isTechnicalNonCookingFood(item) then
        return false
    end

    local itemRecipe = recipe:getItemRecipe(item)
    if not itemRecipe then return false end

    if instanceof(item, "Food") then
        if item:isBurnt() then return false end
        if item:isRotten() and self.player:getPerkLevel(Perks.Cooking) < 7 then return false end
        if not recipe:needToBeCooked(item) then return false end

        if item:isSpice() then
            if recipe.isResultItem and recipe:isResultItem(baseItem) and recipe.isSpiceAdded and recipe:isSpiceAdded(baseItem, item) then
                return false
            end
        elseif baseItem.haveExtraItems and baseItem:haveExtraItems() and baseItem.getExtraItems and baseItem:getExtraItems():size() >= recipe:getMaxItems() then
            return false
        end
    end

    if self.player and item.isNoRecipes and item:isNoRecipes(self.player) then
        return false
    end

    return true
end

function PJCK_EvoPanel:addFrozenPreviewItems(itemInfo, panelType, recipe, baseItem, containers)
    if not itemInfo or not recipe or not baseItem or not containers then return end

    local allItems = ArrayList.new()
    if CraftRecipeManager and CraftRecipeManager.getAllItemsFromContainers then
        CraftRecipeManager.getAllItemsFromContainers(containers, allItems)
    end

    if not allItems then return end

    for i = 0, allItems:size() - 1 do
        local item = allItems:get(i)
        if self:isFrozenPreviewItem(item, recipe, baseItem, panelType) then
            self:addToItemInfo(itemInfo, item, item:getName(), false, true)
        end
    end
end

function PJCK_EvoPanel:addToItemInfo(itemInfo, item, itemName, available, frozenPreview)
    frozenPreview = frozenPreview == true

    if itemInfo[itemName] then
        if available or frozenPreview then
            itemInfo[itemName].count = itemInfo[itemName].count + 1

            -- A stack with at least one usable item should remain addable. Frozen
            -- preview state is only used when every matching item is frozen.
            if available and itemInfo[itemName].frozenPreview then
                itemInfo[itemName].frozenPreview = false
                itemInfo[itemName].isPossible = false
                itemInfo[itemName].item = item
            end
            
            -- keep select items
            local switchItems = self.switchItems[itemName]
            if switchItems and switchItems:getID() == item:getID() then
                itemInfo[itemName].item = item
            elseif not switchItems then
                local currentRatio = self:getItemStatusRatio(itemInfo[itemName].item)
                local newRatio = self:getItemStatusRatio(item)
                if newRatio < currentRatio and not (itemInfo[itemName].frozenPreview == false and frozenPreview) then
                    itemInfo[itemName].item = item
                end
            end
        end
    else
        itemInfo[itemName] = {
            item = item,
            count = available and 1 or (frozenPreview and 1 or 0),
            isPossible = (not available) and (not frozenPreview),
            frozenPreview = frozenPreview
        }
    end
end

function PJCK_EvoPanel:canQueueIngredients()
    local cookStatus = self:getCookStatus()
    return self:getBaseItem() ~= nil
        and self:getRecipe() ~= nil
        and cookStatus ~= "showRecipes"
        and cookStatus ~= "needWater"
end

function PJCK_EvoPanel:addPreCookItems(item)
    if not item or not self:canQueueIngredients() then return end
    table.insert(self.preCookItems, item)
end

function PJCK_EvoPanel:removePreCookItems(item)
    if not item then return end
    
    for i = #self.preCookItems, 1, -1 do
        if self.preCookItems[i]:getID() == item:getID() then
            table.remove(self.preCookItems, i)
            break
        end
    end
end

function PJCK_EvoPanel:getPreCookItems(type)
    if not self.preCookItems then
        return {}
    end

    if not type then
        return self.preCookItems
    end
    
    local filteredItems = {}
    for _, item in ipairs(self.preCookItems) do
        if item then
            local shouldInclude = false
            if type == "Ingredient" and self:isValidIngredient(item) then
                shouldInclude = true
            elseif type == "Seasoning" and self:isValidSeasoning(item) then
                shouldInclude = true
            end
            
            if shouldInclude then
                table.insert(filteredItems, item)
            end
        end
    end
    
    return filteredItems
end

function PJCK_EvoPanel:getContainItems(baseItem, type)
    local containItems = {}
    if not baseItem then return containItems end
    
    local function addTexturesFromList(itemList)
        if not itemList or itemList:size() == 0 then return end
        
        for i = 0, itemList:size() - 1 do
            local itemScript = getScriptManager():getItem(itemList:get(i))
            if itemScript then
                local icon = itemScript:getIcon()
                if itemScript:getIconsForTexture() and not itemScript:getIconsForTexture():isEmpty() then
                    icon = itemScript:getIconsForTexture():get(0)
                end
                
                if icon then
                    local texture = getTexture("Item_" .. icon)
                    if texture then
                        table.insert(containItems, texture)
                    end
                end
            end
        end
    end
    
    if type == "Ingredient" then
        addTexturesFromList(baseItem:getExtraItems())
    elseif type == "Seasoning" and instanceof(baseItem, "Food") then
        addTexturesFromList(baseItem:getSpices())
    end
    
    return containItems
end

local function PJCK_itemListContainsItemById(itemList, item)
    -- Check recipe availability by item ID to survive MP-side object replacement.
    if not itemList or not item then return false end

    if itemList.contains and itemList:contains(item) then
        return true
    end

    local itemId = item.getID and item:getID() or nil
    if not itemId then return false end

    for i = 0, itemList:size() - 1 do
        local candidate = itemList:get(i)
        if candidate and candidate.getID and candidate:getID() == itemId then
            return true
        end
    end

    return false
end

local function PJCK_filterUsableIngredients(player, recipe, baseItem, ingredients)
    -- Re-check the vanilla evolved-recipe availability immediately before queuing actions.
    if not player or not recipe or not baseItem or not ingredients then return {} end

    local containers = ISInventoryPaneContextMenu.getContainers(player)
    local availableItems = recipe:getItemsCanBeUse(player, baseItem, containers)
    local filtered = {}

    for _, ingredient in ipairs(ingredients) do
        if ingredient
                and PJCK_itemListContainsItemById(availableItems, ingredient)
                and not (PJCK_CookingEligibility and PJCK_CookingEligibility.isTechnicalNonCookingFood(ingredient)) then
            table.insert(filtered, ingredient)
        end
    end

    return filtered
end

function PJCK_EvoPanel:addIngredients(ingredients, recipe, baseItem)
    if not ingredients or not recipe or not baseItem then
        return
    end

    ingredients = PJCK_filterUsableIngredients(self.player, recipe, baseItem, ingredients)
    if not ingredients or #ingredients == 0 then
        return
    end

    local returnToContainer = {}

    -- transfer if need
    ISInventoryPaneContextMenu.transferIfNeeded(self.player, ingredients)
    ISInventoryPaneContextMenu.transferIfNeeded(self.player, baseItem)

    for _, ingredient in ipairs(ingredients) do
        if ingredient and ingredient:getContainer() ~= self.player:getInventory() then
            ISInventoryPaneContextMenu.transferIfNeeded(self.player, ingredient)
            table.insert(returnToContainer, ingredient)
        end
    end

    -- sort TimeAction
    local itemGroups = {}
    local itemOrder = {}
    
    for _, ingredient in ipairs(ingredients) do
        if ingredient then
            local itemType = ingredient:getFullType()
            
            if not itemGroups[itemType] then
                itemGroups[itemType] = {}
                table.insert(itemOrder, itemType)
            end
            
            table.insert(itemGroups[itemType], ingredient)
        end
    end
    
    -- 1.add different type
    for _, itemType in ipairs(itemOrder) do
        local items = itemGroups[itemType]
        if items and #items > 0 then
            local firstItem = items[1]
            local resultItemType = recipe and recipe.getResultItem and recipe:getResultItem() or nil
            if resultItemType and baseItem and baseItem.getType and baseItem:getType() ~= resultItemType and self.preparePendingBaseItemReplacement then
                self:preparePendingBaseItemReplacement(resultItemType, firstItem and firstItem.getFullType and firstItem:getFullType() or nil)
            end
            ISTimedActionQueue.add(ISAddItemInRecipe:new(self.player, recipe, baseItem, firstItem))
        end
    end
    
    -- 2. add same type
    for _, itemType in ipairs(itemOrder) do
        local items = itemGroups[itemType]
        if items and #items > 1 then
            for i = 2, #items do
                ISTimedActionQueue.add(ISAddItemInRecipe:new(self.player, recipe, baseItem, items[i]))
            end
        end
    end

    ISCraftingUI.ReturnItemsToOriginalContainer(self.player, returnToContainer)

    self.preCookItems = {}
end

-- isIngredient
function PJCK_EvoPanel:isValidIngredient(item)
    if instanceof(item, "Food") and not item:isSpice() then
        return true
    end
    return false
end

-- isSeasoning
function PJCK_EvoPanel:isValidSeasoning(item)
    if instanceof(item, "Food") and item:isSpice() then
        return true
    end
    return false
end

-- isUsableForRecip
function PJCK_EvoPanel:isUsableForRecipe(item, recipe)
    if not item or not recipe then
        return true
    end

    if instanceof(item, "Food") then
        if not recipe:needToBeCooked(item) then
            return false
        end
        
        if item:isFrozen() and not recipe:isAllowFrozenItem() then
            return false
        end

        if item:isRotten() and self.player:getPerkLevel(Perks.Cooking) < 7 then
            return false
        end
    end
    
    return true
end

-- ----------------------------------------- --
-- Evolved Logic Update
-- ----------------------------------------- --
function PJCK_EvoPanel:onUpdateContainers()

    if self.ingredientsPanel then
        self.ingredientsPanel:onUpdateContainers()
    end
    if self.seasoningsPanel then
        self.seasoningsPanel:onUpdateContainers()
    end
end

function PJCK_EvoPanel:onUpdateBaseItem()
    self.preCookItems = {}

    if self.ingredientsPanel then
        self.ingredientsPanel:onUpdateBaseItem()
    end
    if self.seasoningsPanel then
        self.seasoningsPanel:onUpdateBaseItem()
    end
end

function PJCK_EvoPanel:onUpdateRecipe()
    self.switchItems = {}

    if self.ingredientsPanel then
        self.ingredientsPanel:onUpdateRecipe()
    end
    if self.seasoningsPanel then
        self.seasoningsPanel:onUpdateRecipe()
    end
end

return PJCK_EvoPanel