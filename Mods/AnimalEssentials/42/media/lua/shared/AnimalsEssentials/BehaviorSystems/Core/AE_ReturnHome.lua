AE_ReturnHome = {}

local AE_DataService = require("AnimalsEssentials/DataServices/AE_DataService")

local returnStates = {}

function AE_ReturnHome.Initialize(animal)
    if not animal then return false end
    
    local animalID = AE_DataService.getStableID(animal)
    if not animalID then return false end
    
    returnStates[animalID] = {
        isReturning = false,
        isResting = false
    }
    
    return true
end

function AE_ReturnHome.Update(animal)
    if not animal then return end
    
    local animalID = AE_DataService.getStableID(animal)
    if not animalID then return end
end

function AE_ReturnHome.IsReturning(animal)
    if not animal then return false end
    
    local animalID = AE_DataService.getStableID(animal)
    if not animalID then return false end
    
    local state = returnStates[animalID]
    return state and state.isReturning or false
end

function AE_ReturnHome.IsResting(animal)
    if not animal then return false end
    
    local animalID = AE_DataService.getStableID(animal)
    if not animalID then return false end
    
    local state = returnStates[animalID]
    return state and state.isResting or false
end

function AE_ReturnHome.GetHomeTarget(animal)
    return nil, nil
end

function AE_ReturnHome.OnWanderCompleted(animal)
    if not animal then return end
end

_G.AE_ReturnHome = AE_ReturnHome

return AE_ReturnHome