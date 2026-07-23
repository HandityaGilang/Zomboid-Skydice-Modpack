-- CONVERTED: AE_CareUI.lua
-- SESSION 3D: Enhanced with AE_DataService integration and validation

local AE_CareUI = {}
local Config = require("AnimalsEssentials/ForModders/AE_MasterConfig")
local AnimalRegistry = require("AnimalsEssentials/CoreSystems/AE_AnimalRegistry")
local TamingSystem = require("AnimalsEssentials/Taming/AE_TamingSystem")
local FriendlinessSystem = require("AnimalsEssentials/CoreSystems/AE_FriendlinessSystem")

AE_CareUI.isOpen = false
AE_CareUI.careWindow = nil
AE_CareUI.player = nil
AE_CareUI.animal = nil
AE_CareUI.animalID = nil
AE_CareUI.animalSlot = nil
AE_CareUI.onBackCallback = nil
AE_CareUI.currentMode = "feed"
AE_CareUI.selectedItem = nil
AE_CareUI.itemListBox = nil
AE_CareUI.itemList = {}
AE_CareUI.feedButton = nil
AE_CareUI.waterButton = nil
AE_CareUI.WINDOW_WIDTH = 500
AE_CareUI.WINDOW_HEIGHT = 600
AE_CareUI.FEED_DISTANCE = Config.CareUI.FeedDistance

-- CONVERTED: Enhanced validation with AE_DataService
function AE_CareUI.validateCareState()
    local dataServiceAvailable = pcall(function()
        return AE_DataService ~= nil and AE_DataService.isAnimalValid
    end)
    
    if dataServiceAvailable and AE_CareUI.animal then
        -- Enhanced validation through data service
        if not AE_DataService.isAnimalValid(AE_CareUI.animal) then
            return false, "invalid_animal"
        end
        
        if not AE_DataService.isTamed(AE_CareUI.animal) then
            return false, "not_tamed"
        end
        
        local animalID = AE_DataService.getStableID(AE_CareUI.animal)
        if not animalID or animalID == "" then
            return false, "no_stable_id"
        end
    end
    
    return true, "valid"
end

function AE_CareUI.isAcceptableFood(item)
    if not item then return false end
    local fullType = item:getFullType()
    return fullType and Config.CareUI.AcceptableFoods[fullType] ~= nil
end

function AE_CareUI.getFoodSatiety(item)
    if not item then return 0 end
    local fullType = item:getFullType()
    return fullType and Config.CareUI.AcceptableFoods[fullType] or 0
end

function AE_CareUI.scanInventoryForFood(player)
    local foodItems = {}
    local inventory = player:getInventory()
    local items = inventory:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if AE_CareUI.isAcceptableFood(item) then
            table.insert(foodItems, item)
        end
    end
    return foodItems
end

function AE_CareUI.scanInventoryForWater(player)
    local waterItems = {}
    local inventory = player:getInventory()
    local items = inventory:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local fullType = item:getFullType()
        for _, containerType in ipairs(Config.CareUI.WaterContainers) do
            if fullType == containerType then
                table.insert(waterItems, item)
                break
            end
        end
    end
    return waterItems
end

-- CONVERTED: Enhanced hunger retrieval with AE_DataService fallback
function AE_CareUI.getAnimalHungerPercent(animal)
    if not animal then return 70 end
    
    -- Try AE_DataService first if available
    local dataServiceAvailable = pcall(function()
        return AE_DataService ~= nil and AE_DataService.getHunger
    end)
    
    if dataServiceAvailable then
        local hunger = AE_DataService.getHunger(animal)
        if hunger then
            return hunger
        end
    end
    
    -- Fallback to vanilla stats
    local success, result = pcall(function()
        local stats = animal:getStats()
        if stats then
            local vanillaHunger = stats:getHunger()
            if vanillaHunger ~= nil then
                return math.floor(100 - vanillaHunger)
            end
        end
        return nil
    end)
    return (success and result) or 70
end

-- CONVERTED: Enhanced thirst retrieval with AE_DataService fallback
function AE_CareUI.getAnimalThirstPercent(animal)
    if not animal then return 70 end
    
    -- Try AE_DataService first if available
    local dataServiceAvailable = pcall(function()
        return AE_DataService ~= nil and AE_DataService.getThirst
    end)
    
    if dataServiceAvailable then
        local thirst = AE_DataService.getThirst(animal)
        if thirst then
            return thirst
        end
    end
    
    -- Fallback to vanilla stats
    local success, result = pcall(function()
        local stats = animal:getStats()
        if stats then
            local vanillaThirst = stats:getThirst()
            if vanillaThirst ~= nil then
                return math.floor(100 - vanillaThirst)
            end
        end
        return nil
    end)
    return (success and result) or 70
end

-- CONVERTED: Enhanced UI opening with AE_DataService validation
function AE_CareUI.open(player, animal, animalID, animalSlot, onBackCallback)
    if AE_CareUI.isOpen then
        AE_CareUI.close()
    end
    
    AE_CareUI.player = player
    AE_CareUI.animal = animal
    AE_CareUI.animalID = animalID
    AE_CareUI.animalSlot = animalSlot
    AE_CareUI.onBackCallback = onBackCallback
    AE_CareUI.currentMode = "feed"
    
    -- CONVERTED: Validate care UI state using AE_DataService
    local isValid, reason = AE_CareUI.validateCareState()
    if not isValid then
        if player and player.Say then
            if reason == "not_tamed" then
                player:Say("Animal must be tamed for care interactions")
            elseif reason == "invalid_animal" then
                player:Say("Invalid animal selected")
            elseif reason == "no_stable_id" then
                player:Say("Animal not properly registered")
            else
                player:Say("Cannot provide care for this animal")
            end
        end
        return
    end
    
    local core = getCore()
    local x = (core:getScreenWidth() - AE_CareUI.WINDOW_WIDTH) / 2
    local y = (core:getScreenHeight() - AE_CareUI.WINDOW_HEIGHT) / 2
    AE_CareUI.careWindow = ISPanel:new(x, y, AE_CareUI.WINDOW_WIDTH, AE_CareUI.WINDOW_HEIGHT)
    AE_CareUI.careWindow:initialise()
    AE_CareUI.careWindow:instantiate()
    AE_CareUI.careWindow.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    AE_CareUI.careWindow.backgroundColor = {r=0, g=0, b=0, a=0.8}
    AE_CareUI.careWindow.moveWithMouse = true
    
    local animalName = TamingSystem.GetName(animal) or "Animal"
    local animalType = AnimalRegistry.GetAnimalType(animal)
    local displayType = animalType and animalType:gsub("^%l", string.upper) or "Animal"
    local titleLabel = ISLabel:new(10, 10, 20, displayType .. " Care: " .. animalName, 1, 1, 1, 1, UIFont.Medium, true)
    titleLabel:initialise()
    titleLabel:instantiate()
    AE_CareUI.careWindow:addChild(titleLabel)
    
    local closeButton = ISButton:new(AE_CareUI.WINDOW_WIDTH - 25, 5, 20, 20, "X", nil, AE_CareUI.close)
    closeButton:initialise()
    closeButton:instantiate()
    closeButton.borderColor = {r=1, g=1, b=1, a=0.3}
    AE_CareUI.careWindow:addChild(closeButton)
    
    local backButton = ISButton:new(10, 5, 60, 20, "< Back", nil, AE_CareUI.onBack)
    backButton:initialise()
    backButton:instantiate()
    backButton.borderColor = {r=1, g=1, b=1, a=0.3}
    AE_CareUI.careWindow:addChild(backButton)
    
    local statsY = 40
    local hungerPercent = AE_CareUI.getAnimalHungerPercent(animal)
    local thirstPercent = AE_CareUI.getAnimalThirstPercent(animal)
    local hungerColor = {r=1, g=1, b=0.7}
    local hungerText = "Hunger: " .. hungerPercent .. "%"
    if hungerPercent >= 75 then
        hungerColor = {r=0.2, g=1, b=0.2}
        hungerText = "Well Fed (" .. hungerPercent .. "%)"
    elseif hungerPercent >= 50 then
        hungerColor = {r=1, g=1, b=0.5}
    elseif hungerPercent >= 25 then
        hungerColor = {r=1, g=0.6, b=0.2}
    else
        hungerColor = {r=1, g=0.2, b=0.2}
        hungerText = "Starving! (" .. hungerPercent .. "%)"
    end
    
    local hungerLabel = ISLabel:new(10, statsY, 18, hungerText, hungerColor.r, hungerColor.g, hungerColor.b, 1, UIFont.Small, true)
    hungerLabel:initialise()
    hungerLabel:instantiate()
    AE_CareUI.careWindow:addChild(hungerLabel)
    
    local thirstColor = {r=0.7, g=1, b=1}
    local thirstText = "Thirst: " .. thirstPercent .. "%"
    if thirstPercent >= 75 then
        thirstColor = {r=0.2, g=0.7, b=1}
        thirstText = "Well Hydrated (" .. thirstPercent .. "%)"
    elseif thirstPercent >= 50 then
        thirstColor = {r=0.5, g=0.8, b=1}
    elseif thirstPercent >= 25 then
        thirstColor = {r=1, g=0.6, b=0.2}
    else
        thirstColor = {r=1, g=0.2, b=0.2}
        thirstText = "Dehydrated! (" .. thirstPercent .. "%)"
    end
    
    local thirstLabel = ISLabel:new(10, statsY + 20, 18, thirstText, thirstColor.r, thirstColor.g, thirstColor.b, 1, UIFont.Small, true)
    thirstLabel:initialise()
    thirstLabel:instantiate()
    AE_CareUI.careWindow:addChild(thirstLabel)
    
    local modeY = statsY + 50
    AE_CareUI.feedButton = ISButton:new(10, modeY, 100, 30, "Feed", nil, function()
        AE_CareUI.switchMode("feed")
    end)
    AE_CareUI.feedButton:initialise()
    AE_CareUI.feedButton:instantiate()
    AE_CareUI.feedButton.borderColor = {r=0.2, g=1, b=0.2, a=1}
    AE_CareUI.feedButton.backgroundColor = {r=0.1, g=0.4, b=0.1, a=0.8}
    AE_CareUI.careWindow:addChild(AE_CareUI.feedButton)
    
    AE_CareUI.waterButton = ISButton:new(120, modeY, 100, 30, "Water", nil, function()
        AE_CareUI.switchMode("water")
    end)
    AE_CareUI.waterButton:initialise()
    AE_CareUI.waterButton:instantiate()
    AE_CareUI.waterButton.borderColor = {r=0.2, g=0.6, b=1, a=1}
    AE_CareUI.waterButton.backgroundColor = {r=0.1, g=0.3, b=0.5, a=0.8}
    AE_CareUI.careWindow:addChild(AE_CareUI.waterButton)
    
    local itemListY = modeY + 40
    AE_CareUI.itemListBox = ISScrollingListBox:new(10, itemListY, AE_CareUI.WINDOW_WIDTH - 20, 350)
    AE_CareUI.itemListBox:initialise()
    AE_CareUI.itemListBox:instantiate()
    AE_CareUI.itemListBox.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.8}
    AE_CareUI.itemListBox.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    AE_CareUI.itemListBox.itemheight = 22
    AE_CareUI.itemListBox:setOnMouseDownFunction(AE_CareUI, AE_CareUI.onItemSelect)
    AE_CareUI.careWindow:addChild(AE_CareUI.itemListBox)
    
    local actionButtonY = itemListY + 360
    local actionButton = ISButton:new(10, actionButtonY, AE_CareUI.WINDOW_WIDTH - 20, 40, "Feed Animal", nil, function()
        AE_CareUI.performCareAction()
    end)
    actionButton:initialise()
    actionButton:instantiate()
    actionButton.borderColor = {r=1, g=0.6, b=0.2, a=1}
    actionButton.backgroundColor = {r=0.5, g=0.3, b=0.1, a=0.8}
    actionButton.font = UIFont.Large
    AE_CareUI.actionButton = actionButton
    AE_CareUI.careWindow:addChild(actionButton)
    
    AE_CareUI.careWindow.onMouseDownOutside = function(self, x, y)
        local mouseX = self:getMouseX()
        local mouseY = self:getMouseY()
        if mouseX < 0 or mouseX > self.width or mouseY < 0 or mouseY > self.height then
            AE_CareUI.close()
            return true
        end
        return false
    end
    
    AE_CareUI.careWindow.onRightMouseDownOutside = function(self, x, y)
        AE_CareUI.close()
        return true
    end
    
    AE_CareUI.careWindow:addToUIManager()
    AE_CareUI.careWindow:setVisible(true)
    AE_CareUI.isOpen = true
    
    AE_CareUI.refreshItemList()
    AE_CareUI.updateModeButtons()
end

function AE_CareUI.close()
    if AE_CareUI.careWindow then
        AE_CareUI.careWindow:setVisible(false)
        AE_CareUI.careWindow:removeFromUIManager()
        AE_CareUI.careWindow = nil
    end
    AE_CareUI.isOpen = false
    AE_CareUI.player = nil
    AE_CareUI.animal = nil
    AE_CareUI.animalID = nil
    AE_CareUI.animalSlot = nil
    AE_CareUI.onBackCallback = nil
    AE_CareUI.selectedItem = nil
    AE_CareUI.itemList = {}
end

function AE_CareUI.onBack()
    AE_CareUI.close()
    if AE_CareUI.onBackCallback then
        AE_CareUI.onBackCallback()
    end
end

function AE_CareUI.switchMode(mode)
    AE_CareUI.currentMode = mode
    AE_CareUI.selectedItem = nil
    AE_CareUI.refreshItemList()
    AE_CareUI.updateModeButtons()
end

function AE_CareUI.updateModeButtons()
    if not AE_CareUI.feedButton or not AE_CareUI.waterButton or not AE_CareUI.actionButton then
        return
    end
    
    if AE_CareUI.currentMode == "feed" then
        AE_CareUI.feedButton.backgroundColor = {r=0.1, g=0.4, b=0.1, a=0.8}
        AE_CareUI.waterButton.backgroundColor = {r=0.05, g=0.15, b=0.25, a=0.6}
        AE_CareUI.actionButton:setTitle("Feed Animal")
        AE_CareUI.actionButton.borderColor = {r=0.2, g=1, b=0.2, a=1}
        AE_CareUI.actionButton.backgroundColor = {r=0.1, g=0.4, b=0.1, a=0.8}
    else
        AE_CareUI.feedButton.backgroundColor = {r=0.05, g=0.2, b=0.05, a=0.6}
        AE_CareUI.waterButton.backgroundColor = {r=0.1, g=0.3, b=0.5, a=0.8}
        AE_CareUI.actionButton:setTitle("Give Water")
        AE_CareUI.actionButton.borderColor = {r=0.2, g=0.6, b=1, a=1}
        AE_CareUI.actionButton.backgroundColor = {r=0.1, g=0.3, b=0.5, a=0.8}
    end
end

function AE_CareUI.refreshItemList()
    if not AE_CareUI.itemListBox then return end
    
    AE_CareUI.itemListBox:clear()
    AE_CareUI.itemList = {}
    
    if not AE_CareUI.player then return end
    
    if AE_CareUI.currentMode == "feed" then
        local foodItems = AE_CareUI.scanInventoryForFood(AE_CareUI.player)
        for _, item in ipairs(foodItems) do
            local displayName = item:getDisplayName()
            local satiety = AE_CareUI.getFoodSatiety(item)
            local listText = displayName .. " (+" .. satiety .. "% hunger)"
            AE_CareUI.itemListBox:addItem(listText, item)
            table.insert(AE_CareUI.itemList, item)
        end
    else
        local waterItems = AE_CareUI.scanInventoryForWater(AE_CareUI.player)
        for _, item in ipairs(waterItems) do
            local displayName = item:getDisplayName()
            local listText = displayName .. " (+100% thirst)"
            AE_CareUI.itemListBox:addItem(listText, item)
            table.insert(AE_CareUI.itemList, item)
        end
    end
end

function AE_CareUI.onItemSelect(item)
    AE_CareUI.selectedItem = item
end

function AE_CareUI.performCareAction()
    if AE_CareUI.currentMode == "feed" then
        AE_CareUI.feedAnimal()
    else
        AE_CareUI.waterAnimal()
    end
end

-- CONVERTED: Enhanced feeding with AE_DataService integration
function AE_CareUI.feedAnimal()
    if not AE_CareUI.selectedItem or not AE_CareUI.animal or not AE_CareUI.player then
        return
    end
    
    -- Validate care state before feeding
    local isValid, reason = AE_CareUI.validateCareState()
    if not isValid then
        if AE_CareUI.player and AE_CareUI.player.Say then
            AE_CareUI.player:Say("Cannot feed animal: " .. (reason or "unknown error"))
        end
        AE_CareUI.close()
        return
    end
    
    local animalSquare = AE_CareUI.animal:getSquare()
    local playerSquare = AE_CareUI.player:getSquare()
    if not animalSquare or not playerSquare then
        return
    end
    
    local distance = math.sqrt(
        math.pow(animalSquare:getX() - playerSquare:getX(), 2) +
        math.pow(animalSquare:getY() - playerSquare:getY(), 2)
    )
    
    if distance > AE_CareUI.FEED_DISTANCE then
        AE_CareUI.player:Say("Too far away!")
        return
    end
    
    local nutritionValue = AE_CareUI.getFoodSatiety(AE_CareUI.selectedItem)
    local hungerBefore = AE_CareUI.getAnimalHungerPercent(AE_CareUI.animal)
    
    local success = pcall(function()
        -- CONVERTED: Use AE_DataService for hunger management if available
        local dataServiceAvailable = pcall(function()
            return AE_DataService ~= nil and AE_DataService.setHunger
        end)
        
        if dataServiceAvailable then
            local newHunger = math.min(100, hungerBefore + nutritionValue)
            AE_DataService.setHunger(AE_CareUI.animal, newHunger)
        else
            -- Fallback to vanilla stats
            local stats = AE_CareUI.animal:getStats()
            if stats and stats.setHunger then
                local newHunger = math.min(100, hungerBefore + nutritionValue)
                local vanillaValue = 100 - newHunger
                stats:setHunger(vanillaValue)
            end
        end
        
        local newHunger = AE_CareUI.getAnimalHungerPercent(AE_CareUI.animal)
        local hungerRestored = newHunger - hungerBefore
        
        if hungerRestored > 0 then
            FriendlinessSystem.OnFeeding(AE_CareUI.player, AE_CareUI.animal, hungerRestored)
        end
    end)

    if not success then
        AE_CareUI.player:Say("Feeding failed - system error")
        return
    end

    -- CONVERTED: Data synchronization handled by AE_DataService
    -- No need for direct transmitModData() call
    
    AE_CareUI.player:getInventory():Remove(AE_CareUI.selectedItem)
    local animalName = TamingSystem.GetName(AE_CareUI.animal) or "Animal"
    AE_CareUI.player:Say("Here you go, " .. animalName .. "!")
    AE_CareUI.close()
end

-- CONVERTED: Enhanced watering with AE_DataService integration
function AE_CareUI.waterAnimal()
    if not AE_CareUI.selectedItem or not AE_CareUI.animal or not AE_CareUI.player then
        return
    end
    
    -- Validate care state before watering
    local isValid, reason = AE_CareUI.validateCareState()
    if not isValid then
        if AE_CareUI.player and AE_CareUI.player.Say then
            AE_CareUI.player:Say("Cannot water animal: " .. (reason or "unknown error"))
        end
        AE_CareUI.close()
        return
    end
    
    local animalSquare = AE_CareUI.animal:getSquare()
    local playerSquare = AE_CareUI.player:getSquare()
    if not animalSquare or not playerSquare then
        return
    end
    
    local distance = math.sqrt(
        math.pow(animalSquare:getX() - playerSquare:getX(), 2) +
        math.pow(animalSquare:getY() - playerSquare:getY(), 2)
    )
    
    if distance > AE_CareUI.FEED_DISTANCE then
        AE_CareUI.player:Say("Too far away!")
        return
    end
    
    local containerType = AE_CareUI.selectedItem:getFullType()
    local thirstBefore = AE_CareUI.getAnimalThirstPercent(AE_CareUI.animal)
    local hydrationValue = 100
    
    local success = pcall(function()
        -- CONVERTED: Use AE_DataService for thirst management if available
        local dataServiceAvailable = pcall(function()
            return AE_DataService ~= nil and AE_DataService.setThirst
        end)
        
        if dataServiceAvailable then
            local newThirst = math.min(100, thirstBefore + hydrationValue)
            AE_DataService.setThirst(AE_CareUI.animal, newThirst)
        else
            -- Fallback to vanilla stats
            local stats = AE_CareUI.animal:getStats()
            if stats and stats.setThirst then
                local newThirst = math.min(100, thirstBefore + hydrationValue)
                local vanillaValue = 100 - newThirst
                stats:setThirst(vanillaValue)
            end
        end
        
        local newThirst = AE_CareUI.getAnimalThirstPercent(AE_CareUI.animal)
        local thirstRestored = newThirst - thirstBefore
        
        if thirstRestored > 0 then
            FriendlinessSystem.OnGivingWater(AE_CareUI.player, AE_CareUI.animal, thirstRestored)
        end
    end)
    
    if not success then
        AE_CareUI.player:Say("Watering failed - system error")
        return
    end

    -- CONVERTED: Data synchronization handled by AE_DataService
    -- No need for direct transmitModData() call
    
    AE_CareUI.player:getInventory():Remove(AE_CareUI.selectedItem)
    
    local emptyContainerMap = {
        ["Base.WaterBottle"] = "Base.WaterBottle",
        ["Base.WaterBottleFull"] = "Base.WaterBottle",
        ["Base.Saucepan"] = "Base.Saucepan",
        ["Base.Pot"] = "Base.Pot",
        ["Base.Kettle"] = "Base.Kettle",
        ["Base.Bowl"] = "Base.Bowl",
        ["Base.BowlWhite"] = "Base.BowlWhite",
        ["Base.BowlRed"] = "Base.BowlRed",
        ["Base.MugWhite"] = "Base.MugWhite",
        ["Base.MugBlue"] = "Base.MugBlue",
        ["Base.MugSpiffo"] = "Base.MugSpiffo"
    }
    
    local emptyContainer = emptyContainerMap[containerType]
    if emptyContainer then
        local inv = AE_CareUI.player:getInventory()
        inv:AddItem(emptyContainer)
    end
    
    local animalName = TamingSystem.GetName(AE_CareUI.animal) or "Animal"
    AE_CareUI.player:Say("Drink up, " .. animalName .. "!")
    AE_CareUI.close()
end

return AE_CareUI