AE_HomeLocation = {}

local AE_DataService = require("AnimalsEssentials/DataServices/AE_DataService")

-- Minimal stub for AE_HomeLocation to satisfy TamingSystem and CommandsUI requirements
-- This is a compatibility stub that provides basic home location interface

local homeLocations = {}

-- Set home location for an animal
function AE_HomeLocation.setHomeLocation(animalID, x, y, z)
    if not animalID then return false end
    
    homeLocations[animalID] = {
        x = x or 0,
        y = y or 0,
        z = z or 0,
        timestamp = os.time()
    }
    return true
end

-- Get home location for an animal
function AE_HomeLocation.getHomeLocation(animalID)
    if not animalID then return nil end
    return homeLocations[animalID]
end

-- Check if animal has home location
function AE_HomeLocation.hasHomeLocation(animalID)
    if not animalID then return false end
    return homeLocations[animalID] ~= nil
end

-- Remove home location for an animal
function AE_HomeLocation.removeHomeLocation(animalID)
    if not animalID then return false end
    homeLocations[animalID] = nil
    return true
end

-- Calculate distance to home
function AE_HomeLocation.getDistanceToHome(animal)
    if not animal then return nil end
    
    local animalID = animal:getID()
    local home = homeLocations[animalID]
    if not home then return nil end
    
    local dx = animal:getX() - home.x
    local dy = animal:getY() - home.y
    local dz = animal:getZ() - home.z
    
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- Periodic update function for behavior system compatibility
function AE_HomeLocation.HourlyUpdate()
    -- Stub implementation - no periodic processing needed for basic home location tracking
    return true
end

-- Cleanup expired home locations (optional periodic maintenance)
function AE_HomeLocation.cleanupExpiredLocations(maxAge)
    if not maxAge then return 0 end
    
    local currentTime = os.time()
    local cleaned = 0
    
    for animalID, location in pairs(homeLocations) do
        if location.timestamp and (currentTime - location.timestamp) > maxAge then
            homeLocations[animalID] = nil
            cleaned = cleaned + 1
        end
    end
    
    return cleaned
end

-- Initialize behavior system for an animal
function AE_HomeLocation.Initialize(animal)
    if not animal then return false end
    
    local animalID = AE_DataService.getStableID(animal)
    if not animalID then return false end
    
    return true
end

-- Export for global access
_G.AE_HomeLocation = AE_HomeLocation

return AE_HomeLocation