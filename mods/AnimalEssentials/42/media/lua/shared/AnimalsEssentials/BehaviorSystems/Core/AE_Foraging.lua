AE_Foraging = {}

local AE_DataService = require("AnimalsEssentials/DataServices/AE_DataService")

-- Minimal stub for AE_Foraging to satisfy AE_BehaviorManager requirements
-- This is a compatibility stub that provides basic foraging interface

local activeForaging = {}

-- Check if animal has active foraging
function AE_Foraging.HasActiveForaging(animalID)
    if not animalID then return false end
    return activeForaging[animalID] ~= nil
end

-- Get foraging state for animal
function AE_Foraging.GetForagingState(animalID)
    if not animalID then return nil end
    return activeForaging[animalID] or {
        active = false,
        progress = 0,
        type = "none"
    }
end

-- Update foraging for animal
function AE_Foraging.Update(animal, animalID, deltaMinutes)
    if not animal or not animalID then return end
    
    -- Stub update - no actual foraging logic
    -- This prevents crashes while maintaining interface compatibility
    if activeForaging[animalID] then
        activeForaging[animalID].progress = math.min(100, 
            (activeForaging[animalID].progress or 0) + (deltaMinutes or 0))
    end
end

-- Start foraging for animal
function AE_Foraging.StartForaging(animalID, foragingType)
    if not animalID then return false end
    
    activeForaging[animalID] = {
        active = true,
        progress = 0,
        type = foragingType or "basic"
    }
    return true
end

-- Stop foraging for animal
function AE_Foraging.StopForaging(animalID)
    if not animalID then return false end
    
    activeForaging[animalID] = nil
    return true
end

-- Initialize behavior system for an animal
function AE_Foraging.Initialize(animal)
    if not animal then return false end
    
    local animalID = AE_DataService.getStableID(animal)
    if not animalID then return false end
    
    return true
end

-- Export for global access
_G.AE_Foraging = AE_Foraging

return AE_Foraging