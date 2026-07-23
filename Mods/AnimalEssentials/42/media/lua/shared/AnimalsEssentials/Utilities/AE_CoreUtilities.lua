-- CONVERTED: AE_CoreUtilities.lua
-- SESSION 3B: Enhanced with AE_DataService integration for animal validation

------------------------------------------------------------------------------
-- _______  _______ _________                   _______  _______  ______    --
-- (  ____ \(  ___  )\__   __/                  (       )(  ___  )(  __  \  --
-- | (    \/| (   ) |   ) (                     | () () || (   ) || (  \  ) --
-- | |      | (___) |   | |                     | || || || |   | || |   ) | --
-- | |      |  ___  |   | |                     | |(_)| || |   | || |   | | --
-- | |      | (   ) |   | |                     | |   | || |   | || |   ) | --
-- | (____/\| )   ( |   | |                     | )   ( || (___) || (__/  ) --
-- (_______/|/     \|   )_(                     |/     \|(_______)(______/  --
------------------------------------------------------------------------------
-- NOTE FOR MODDERS: 
-- This module defines valid IsoAnimal types for the cat category
-- IMPORTANT: This file MUST be edited by modders for each animal type:
-- ^^^^^ ALL Animal Mods MUST have their own unique "CORE_UTILITIES" file
--- The IsoAnimal types must match the definitions in your animal definitions file
---- Furthermore, you must edit the comments below from "cat" to whatever your animal is
-------------------------------------------------------------------------------------------

local AE_CoreUtilities = {}

-- Defines valid cat IsoAnimal types (from KittyMod_definitions.lua) --
-- These are the actual animal types that getAnimalType() returns --
local VALID_KTTR_ANIMAL_TYPES = {
    ["tom"] = true,
    ["queen"] = true,
    ["babykitten"] = true,
    ["kttr"] = true,
    ["tommanx"] = true,
    ["queenmanx"] = true,
    ["babykittenmanx"] = true,
    ["kttrmanx"] = true
}

--- CONVERTED: Enhanced animal validation with AE_DataService integration
--- Validates and identifies whether a given animal entity is a cat
--- @param animalEntity IsoAnimal The animal entity to validate
--- @return boolean True if the animal is a cat (tom/queen/babykitten/kttr/tommanx/queenmanx/babykittenmanx/kttrmanx), false otherwise
function AE_CoreUtilities.ValidAnimalScan(animalEntity)
    if not animalEntity then
        return false
    end

    -- CONVERTED: Use AE_DataService for enhanced animal validation if available
    local dataServiceAvailable = pcall(function()
        return AE_DataService ~= nil and AE_DataService.isAnimalValid
    end)
    
    if dataServiceAvailable then
        -- Enhanced validation through data service
        if not AE_DataService.isAnimalValid(animalEntity) then
            return false
        end
    end

    local success, animalType = pcall(function()
        return animalEntity:getAnimalType()
    end)
    
    if not success or not animalType then
        return false
    end
    
    return VALID_KTTR_ANIMAL_TYPES[animalType] == true
end

--- CONVERTED: Enhanced framework animal detection
--- Validates if animal is both a valid cat type and framework-managed
--- @param animalEntity IsoAnimal The animal entity to validate
--- @return boolean True if animal is valid cat and framework-managed
function AE_CoreUtilities.ValidFrameworkAnimal(animalEntity)
    -- Basic type validation first
    if not AE_CoreUtilities.ValidAnimalScan(animalEntity) then
        return false
    end
    
    -- CONVERTED: Check if animal is framework-managed through data service
    local dataServiceAvailable = pcall(function()
        return AE_DataService ~= nil
    end)
    
    if dataServiceAvailable then
        -- Verify framework registration through modern data service
        local key = AE_DataConfig.ModDataKeys.AnimalType
        local namespace = "AE_DATA"
        local animalType = AE_NamespaceManager.getModData(animalEntity, key, namespace, "AE_FrameworkData")
        return animalType ~= nil
    end
    
    -- Fallback validation for systems without data service
    return true
end

--- Get all valid IsoAnimal types for this category
--- @return table Array of valid IsoAnimal type strings
function AE_CoreUtilities.GetValidTypes()
    local types = {}
    for animalType, _ in pairs(VALID_KTTR_ANIMAL_TYPES) do
        table.insert(types, animalType)
    end
    return types
end

--- CONVERTED: Enhanced type checking with data service integration
--- Check if specific animal type is valid for this category
--- @param animalType string The animal type to validate
--- @return boolean True if type is valid for this category
function AE_CoreUtilities.IsValidType(animalType)
    if not animalType then return false end
    return VALID_KTTR_ANIMAL_TYPES[animalType] == true
end

--- CONVERTED: Get category statistics for framework integration
--- @return table Statistics about valid animal types and framework integration
function AE_CoreUtilities.GetCategoryStats()
    local typeCount = 0
    for _ in pairs(VALID_KTTR_ANIMAL_TYPES) do
        typeCount = typeCount + 1
    end
    
    local dataServiceAvailable = pcall(function()
        return AE_DataService ~= nil
    end)
    
    return {
        category = "cat",
        validTypeCount = typeCount,
        validTypes = AE_CoreUtilities.GetValidTypes(),
        dataServiceIntegration = dataServiceAvailable,
        frameworkCompatible = true
    }
end

return AE_CoreUtilities