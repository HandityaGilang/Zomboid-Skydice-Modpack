AE_Flee = {}

local AE_DataService = require("AnimalsEssentials/DataServices/AE_DataService")

local fleeStates = {}

function AE_Flee.Initialize(animal)
    if not animal then return false end
    
    local animalID = AE_DataService.getStableID(animal)
    if not animalID then return false end
    
    fleeStates[animalID] = {
        isFleeing = false
    }
    
    return true
end

function AE_Flee.Update(animal, deltaSeconds)
    if not animal then return end
    
    local animalID = AE_DataService.getStableID(animal)
    if not animalID then return end
end

function AE_Flee.IsFleeing(animal)
    if not animal then return false end
    
    local animalID = AE_DataService.getStableID(animal)
    if not animalID then return false end
    
    local state = fleeStates[animalID]
    return state and state.isFleeing or false
end

function AE_Flee.GetFleeTarget(animal)
    return nil, nil
end

_G.AE_Flee = AE_Flee

return AE_Flee