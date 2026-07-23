AE_WanderLust = {}

local AE_DataService = require("AnimalsEssentials/DataServices/AE_DataService")

local wanderStates = {}

function AE_WanderLust.Initialize(animal)
    if not animal then return false end
    
    local animalID = AE_DataService.getStableID(animal)
    if not animalID then return false end
    
    wanderStates[animalID] = {
        isActive = false,
        scale = 0,
        previousScale = 0
    }
    
    return true
end

function AE_WanderLust.Update(animal, deltaMinutes)
    if not animal then return end
    
    local animalID = AE_DataService.getStableID(animal)
    if not animalID then return end
    
    local state = wanderStates[animalID]
    if not state then return end
end

function AE_WanderLust.IsWandering(animal)
    if not animal then return false end
    
    local animalID = AE_DataService.getStableID(animal)
    if not animalID then return false end
    
    local state = wanderStates[animalID]
    return state and state.isActive or false
end

function AE_WanderLust.GetState(animal)
    if not animal then return nil end
    
    local animalID = AE_DataService.getStableID(animal)
    if not animalID then return nil end
    
    return wanderStates[animalID]
end

function AE_WanderLust.GetTarget(animal)
    return nil, nil
end

_G.AE_WanderLust = AE_WanderLust

return AE_WanderLust