--[[
NOTE: remove the above comment brackets if using this template for your own mod!


local CyberDoggyUtilities = {}

-- defines valid CyberDoggy animal types
local VALID_CyberDoggy_ANIMAL_TYPES = {
    ["cyberdogpup"] = true,
    ["cyberdoggirl"] = true,
    ["cyberdog"] = true
}

--- Validates and identifies whether or not a given animal entity is a 
--- @param animalEntity IsoAnimal The animal entity to validate
--- @return boolean currentAnimalCyberDoggy True if the animal is actually a CyberDoggy, false otherwise
function CyberDoggyUtilities.currentAnimalCyberDoggy(animalEntity)
    if not animalEntity then
        return false
    end
    
    local animalType = animalEntity:getAnimalType()
    return VALID_CyberDoggy_ANIMAL_TYPES[animalType] == true
end

return CyberDoggyUtilities

--]]