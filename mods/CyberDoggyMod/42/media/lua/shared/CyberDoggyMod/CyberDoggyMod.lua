--[[
NOTE: remove the above comment brackets if using this template for your own mod!

local CyberDoggyCoreUtilities = require("CyberDoggyMod/CyberDoggyModCoreUtilities")

--- Initializes CyberDoggy-specific properties on an animal entity
--- @param animalEntity IsoAnimal
local function initializeCyberDoggyProperties(animalEntity)
    -- Set CyberDoggy identification flag
    animalEntity:setVariable("currentAnimalCyberDoggy", true)
    
    -- Initialize swiftness gene value
    local swiftnessGene = animalEntity:getUsedGene("swiftness")
    local swiftnessValue = swiftnessGene:getCurrentValue()
    animalEntity:setVariable("geneswiftness", swiftnessValue)
end

-- Queue system for processing newly spawned animals
local AnimalProcessingQueue = {}

---@type IsoAnimal[]
AnimalProcessingQueue.pendingAnimals = table.newarray()

--- Adds an animal to the processing queue
--- @param animalEntity IsoAnimal
function AnimalProcessingQueue.enqueue(animalEntity)
    table.insert(AnimalProcessingQueue.pendingAnimals, animalEntity)
end

--- Processes all queued animals and initializes CyberDoggy-specific properties
function AnimalProcessingQueue.processQueue()
    -- Early exit if queue is empty
    if #AnimalProcessingQueue.pendingAnimals == 0 then
        return
    end
    
    local queueSize = #AnimalProcessingQueue.pendingAnimals
    
    -- Process queue in reverse to safely remove elements
    for index = queueSize, 1, -1 do
        local currentAnimal = AnimalProcessingQueue.pendingAnimals[index]
        
        -- Safety check: ensure animal is valid
        if currentAnimal and CyberDoggyCoreUtilities.currentAnimalCyberDoggy(currentAnimal) then
            initializeCyberDoggyProperties(currentAnimal)
        end
        
        -- Clear processed animal from queue (matches original approach)
        AnimalProcessingQueue.pendingAnimals[index] = nil
    end
end

-- Event Registration: Character Creation
Events.OnCreateLivingCharacter.Add(function(characterEntity, characterDescriptor)
    if characterEntity:isAnimal() then
        ---@cast characterEntity IsoAnimal
        AnimalProcessingQueue.enqueue(characterEntity)
    end
end)

-- Event Registration: Game Tick (Queue Processing)
Events.OnTick.Add(function()
    AnimalProcessingQueue.processQueue()
end)


--]]