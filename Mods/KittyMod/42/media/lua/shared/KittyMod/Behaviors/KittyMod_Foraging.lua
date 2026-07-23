local KittyMod_Foraging = {}

local KittyMod_ModData = require("KittyMod/Core/KittyMod_ModData")
local KittyMod_SafeAPI = require("KittyMod/Core/KittyMod_SafeAPI")

local CatForagingItems = {
    CatToys = {
        {item = "Base.CatToy", weight = 20, environments = {"Urban", "Suburban"}},
        {item = "Base.Yarn", weight = 15, environments = {"Suburban", "Rural"}},
        {item = "Base.ToyBear", weight = 10, environments = {"Urban", "Suburban"}}
    },
    Plants = {
        {item = "Base.Catnip", weight = 25, environments = {"Rural", "Forest"}},
        {item = "Base.Grass", weight = 30, environments = {"Rural", "Forest", "Suburban"}},
        {item = "Base.Plantain", weight = 15, environments = {"Forest", "Rural"}}
    },
    Prey = {
        {item = "Base.DeadMouse", weight = 20, environments = {"Urban", "Suburban", "Rural"}},
        {item = "Base.DeadBird", weight = 15, environments = {"Forest", "Rural", "Suburban"}},
        {item = "Base.DeadRat", weight = 10, environments = {"Urban"}}
    },
    Food = {
        {item = "Base.CatTreats", weight = 5, environments = {"Urban", "Suburban"}},
        {item = "Base.CatFoodBag", weight = 3, environments = {"Urban", "Suburban"}},
        {item = "Base.TunaCan", weight = 8, environments = {"Urban", "Suburban"}}
    },
    Insects = {
        {item = "Base.Cricket", weight = 25, environments = {"Rural", "Forest"}},
        {item = "Base.Grasshopper", weight = 20, environments = {"Rural", "Forest"}},
        {item = "Base.Worm", weight = 30, environments = {"Rural", "Forest"}}
    }
}

local catForagingCooldowns = {}
local FORAGING_COOLDOWN = 1800000

function KittyMod_Foraging.initialize()
    Events.OnPlayerMove.Add(KittyMod_Foraging.checkForagingOpportunity)
    Events.EveryHours.Add(KittyMod_Foraging.resetForagingCooldowns)
end

function KittyMod_Foraging.checkForagingOpportunity(player)
    if not player then return end
    
    local nearbyAnimals = KittyMod_SafeAPI.getAnimalsInRange(player, 15)
    if nearbyAnimals then
        for i = 0, nearbyAnimals:size() - 1 do
            local animal = nearbyAnimals:get(i)
            if KittyMod_ModData.isCat(animal) then
                KittyMod_Foraging.tryForaging(animal, player)
            end
        end
    end
end

function KittyMod_Foraging.tryForaging(cat, player)
    if not cat or not player then return end
    
    local catID = cat:getOnlineID()
    local currentTime = getTimestamp()
    
    if catForagingCooldowns[catID] and currentTime - catForagingCooldowns[catID] < FORAGING_COOLDOWN then
        return
    end
    
    local personality = KittyMod_ModData.getCatData(cat, "CatPersonality")
    local huntingSkill = KittyMod_ModData.getCatData(cat, "CatHuntingSkill") or 50
    local isTamed = KittyMod_ModData.getCatData(cat, "CatIsTamed") or false
    
    if not isTamed and personality ~= "hunter" and personality ~= "curious" then
        return
    end
    
    local foragingChance = KittyMod_Foraging.calculateForagingChance(personality, huntingSkill, isTamed)
    
    if ZombRand(100) < foragingChance then
        KittyMod_Foraging.executeForaging(cat, player)
        catForagingCooldowns[catID] = currentTime
    end
end

function KittyMod_Foraging.calculateForagingChance(personality, huntingSkill, isTamed)
    local baseChance = 3
    
    local personalityModifiers = {
        hunter = 15,
        curious = 10,
        playful = 8,
        independent = 6,
        friendly = 5,
        shy = 2,
        lazy = 1,
        clingy = 4,
        aggressive = 7,
        sleepy = 1
    }
    
    local personalityBonus = personalityModifiers[personality] or 3
    local skillBonus = huntingSkill / 10
    local tameBonus = isTamed and 5 or 0
    
    return math.min(25, baseChance + personalityBonus + skillBonus + tameBonus)
end

function KittyMod_Foraging.executeForaging(cat, player)
    if not cat or not player then return end
    
    local environment = KittyMod_Foraging.getCurrentEnvironment(player)
    local foragingResult = KittyMod_Foraging.selectForagingItem(environment, cat)
    
    if foragingResult then
        KittyMod_Foraging.giveForagingReward(cat, player, foragingResult)
        KittyMod_Foraging.updateHuntingSkill(cat)
    end
end

function KittyMod_Foraging.getCurrentEnvironment(player)
    if not player then return "Urban" end
    
    local cell = player:getCell()
    if not cell then return "Urban" end
    
    local square = player:getSquare()
    if not square then return "Urban" end
    
    if square:isIndustrial() or square:haveBuilding() then
        return "Urban"
    elseif square:getProperties():Val("IsOutside") then
        if square:haveGrass() or square:haveTrees() then
            return "Forest"
        else
            return "Rural"
        end
    else
        return "Suburban"
    end
end

function KittyMod_Foraging.selectForagingItem(environment, cat)
    if not environment or not cat then return nil end
    
    local personality = KittyMod_ModData.getCatData(cat, "CatPersonality")
    local availableCategories = {}
    
    local personalityPreferences = {
        hunter = {"Prey", "Insects"},
        playful = {"CatToys", "Insects"},
        curious = {"Plants", "CatToys", "Prey"},
        lazy = {"Food"},
        independent = {"Prey", "Plants"},
        friendly = {"CatToys", "Food"},
        shy = {"Plants", "Insects"},
        clingy = {"CatToys", "Food"},
        aggressive = {"Prey", "Insects"},
        sleepy = {"Food", "Plants"}
    }
    
    local preferredCategories = personalityPreferences[personality] or {"CatToys", "Food"}
    
    for _, category in ipairs(preferredCategories) do
        if CatForagingItems[category] then
            table.insert(availableCategories, category)
        end
    end
    
    if #availableCategories == 0 then
        availableCategories = {"CatToys", "Food"}
    end
    
    local selectedCategory = availableCategories[ZombRand(1, #availableCategories + 1)]
    local categoryItems = CatForagingItems[selectedCategory]
    
    if not categoryItems then return nil end
    
    local environmentItems = {}
    for _, itemData in ipairs(categoryItems) do
        if not itemData.environments or table.contains(itemData.environments, environment) then
            table.insert(environmentItems, itemData)
        end
    end
    
    if #environmentItems == 0 then return nil end
    
    local totalWeight = 0
    for _, itemData in ipairs(environmentItems) do
        totalWeight = totalWeight + itemData.weight
    end
    
    local randomWeight = ZombRand(totalWeight)
    local currentWeight = 0
    
    for _, itemData in ipairs(environmentItems) do
        currentWeight = currentWeight + itemData.weight
        if randomWeight < currentWeight then
            return {item = itemData.item, category = selectedCategory}
        end
    end
    
    return environmentItems[1]
end

function KittyMod_Foraging.giveForagingReward(cat, player, foragingResult)
    if not cat or not player or not foragingResult then return end
    
    local catName = KittyMod_ModData.getCatData(cat, "CatNickname") or "Cat"
    local item = foragingResult.item
    local category = foragingResult.category
    
    local inventory = player:getInventory()
    if inventory then
        inventory:AddItem(item)
        
        local categoryMessages = {
            CatToys = catName .. " found a toy and brought it to you!",
            Plants = catName .. " found some interesting plants for you",
            Prey = catName .. " caught something and proudly presents it to you",
            Food = catName .. " found some food and shared it with you",
            Insects = catName .. " caught some insects for you"
        }
        
        local message = categoryMessages[category] or catName .. " brought you something interesting!"
        player:Say(message)
        
        local affection = KittyMod_ModData.getCatData(cat, "CatAffection") or 0
        affection = math.min(100, affection + ZombRand(3, 8))
        KittyMod_ModData.setCatData(cat, "CatAffection", affection)
    end
end

function KittyMod_Foraging.updateHuntingSkill(cat)
    if not cat then return end
    
    local huntingSkill = KittyMod_ModData.getCatData(cat, "CatHuntingSkill") or 50
    local skillGain = ZombRand(1, 3)
    
    huntingSkill = math.min(100, huntingSkill + skillGain)
    KittyMod_ModData.setCatData(cat, "CatHuntingSkill", huntingSkill)
    
    if huntingSkill >= 90 then
        local catName = KittyMod_ModData.getCatData(cat, "CatNickname") or "Cat"
        local player = getPlayer()
        if player then
            player:Say(catName .. " has become an expert hunter!")
        end
    end
end

function KittyMod_Foraging.resetForagingCooldowns()
    catForagingCooldowns = {}
end

function KittyMod_Foraging.getCatForagingInfo(cat)
    if not cat then return nil end
    
    local catID = cat:getOnlineID()
    local currentTime = getTimestamp()
    local lastForaging = catForagingCooldowns[catID]
    
    return {
        huntingSkill = KittyMod_ModData.getCatData(cat, "CatHuntingSkill") or 50,
        canForage = not lastForaging or (currentTime - lastForaging) >= FORAGING_COOLDOWN,
        nextForagingTime = lastForaging and (lastForaging + FORAGING_COOLDOWN) or currentTime,
        cooldownRemaining = lastForaging and math.max(0, (lastForaging + FORAGING_COOLDOWN) - currentTime) or 0
    }
end

Events.OnGameStart.Add(KittyMod_Foraging.initialize)

return KittyMod_Foraging