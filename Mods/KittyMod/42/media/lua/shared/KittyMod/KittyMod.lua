local KittyMod_Core = require("KittyMod/Core/KittyMod_Core")
local KittyMod_ModData = require("KittyMod/Core/KittyMod_ModData")
local KittyMod_Behaviors = require("KittyMod/Behaviors/KittyMod_Behaviors")
local KittyMod_Foraging = require("KittyMod/Behaviors/KittyMod_Foraging")
local KittyMod_Commands = require("KittyMod/Behaviors/KittyMod_Commands")
local KittyMod_FrameworkBridge = require("KittyMod/Integration/KittyMod_FrameworkBridge")
local KittyMod_IntegrationValidator = require("KittyMod/Integration/KittyMod_IntegrationValidator")
local KittyMod_IntegrationTest = require("KittyMod/Integration/KittyMod_IntegrationTest")

local function initializeCatProperties(animalEntity)
    if not animalEntity or not animalEntity:isAnimal() then return end
    
    local animalType = animalEntity:getAnimalType()
    if animalType ~= "cat" then return end
    
    if not KittyMod_ModData.isCat(animalEntity) then
        local breed = KittyMod_Core.selectRandomBreed()
        KittyMod_ModData.initializeCatData(animalEntity, breed)
    end
    
    local success, swiftnessGene = pcall(function()
        return animalEntity:getUsedGene("swiftness")
    end)
    if success and swiftnessGene then
        local swiftnessValue = swiftnessGene:getCurrentValue()
        animalEntity:setVariable("geneswiftness", swiftnessValue)
    end
end

local CatProcessingCache = {
    priorityQueue = {
        high = {},
        medium = {},
        low = {}
    },
    frameProcessingBudget = 3,
    lastProcessTime = 0
}

local function categorizeCatByPriority(cat)
    if not KittyMod_ModData.isCat(cat) then
        return "high"
    elseif not KittyMod_ModData.hasValidCatData(cat) then
        return "medium"
    else
        return "low"
    end
end

local function processPriorityCats()
    if getTimestamp() - CatProcessingCache.lastProcessTime < 100 then
        return
    end
    
    local processed = 0
    
    while #CatProcessingCache.priorityQueue.high > 0 and processed < CatProcessingCache.frameProcessingBudget do
        local cat = table.remove(CatProcessingCache.priorityQueue.high, 1)
        if cat and cat:isAnimal() then
            initializeCatProperties(cat)
            processed = processed + 1
        end
    end
    
    while #CatProcessingCache.priorityQueue.medium > 0 and processed < CatProcessingCache.frameProcessingBudget do
        local cat = table.remove(CatProcessingCache.priorityQueue.medium, 1)
        if cat and cat:isAnimal() then
            if not KittyMod_ModData.hasValidCatData(cat) then
                local breed = KittyMod_ModData.getCatData(cat, "CatBreed") or KittyMod_Core.selectRandomBreed()
                KittyMod_ModData.initializeCatData(cat, breed)
            end
            processed = processed + 1
        end
    end
    
    while #CatProcessingCache.priorityQueue.low > 0 and processed < CatProcessingCache.frameProcessingBudget do
        local cat = table.remove(CatProcessingCache.priorityQueue.low, 1)
        if cat and cat:isAnimal() then
            local success, swiftnessGene = pcall(function()
                return cat:getUsedGene("swiftness")
            end)
            if success and swiftnessGene then
                local swiftnessValue = swiftnessGene:getCurrentValue()
                cat:setVariable("geneswiftness", swiftnessValue)
            end
            processed = processed + 1
        end
    end
    
    CatProcessingCache.lastProcessTime = getTimestamp()
    
    if processed == 0 and #CatProcessingCache.priorityQueue.high == 0 
       and #CatProcessingCache.priorityQueue.medium == 0 
       and #CatProcessingCache.priorityQueue.low == 0 then
        Events.OnTick.Remove(processPriorityCats)
        CatProcessingCache.lastProcessTime = 0
    end
end

function enqueueCatForProcessing(cat)
    if not cat or not cat:isAnimal() or cat:getAnimalType() ~= "cat" then return end
    
    local priority = categorizeCatByPriority(cat)
    table.insert(CatProcessingCache.priorityQueue[priority], cat)
    
    if CatProcessingCache.lastProcessTime == 0 then
        Events.OnTick.Add(processPriorityCats)
        CatProcessingCache.lastProcessTime = getTimestamp()
    end
end

Events.OnCreateLivingCharacter.Add(function(characterEntity, characterDescriptor)
    if characterEntity:isAnimal() and characterEntity:getAnimalType() == "cat" then
        enqueueCatForProcessing(characterEntity)
    end
end)

Events.OnGameStart.Add(function()
    
    local frameworkStatus = KittyMod_FrameworkBridge.isFrameworkAvailable()
    
    if frameworkStatus then
        local components = KittyMod_FrameworkBridge.getFrameworkComponents()
        local features = KittyMod_FrameworkBridge.getEnhancedFeatures()
    end
    
    Events.OnKeyPressed.Add(function(key)
        if key == 116 and isDebugEnabled() then
            KittyMod_IntegrationTest.runAllTests()
        end
    end)
end)

function getKeysFromTable(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

function getEnabledFeatures(features)
    local enabled = {}
    for feature, status in pairs(features) do
        if status then
            table.insert(enabled, feature)
        end
    end
    return enabled
end