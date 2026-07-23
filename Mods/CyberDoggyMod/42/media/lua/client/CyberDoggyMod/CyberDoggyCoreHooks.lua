--[[
NOTE: remove the above comment brackets if using this template for your own mod!

local CyberDoggyCoreUtilities = require("CyberDoggyMod/CyberDoggyModCoreUtilities")

-- UI Hook Module
local UIHooks = {}

--- Configures the animal UI panel with CyberDog-specific settings
--- @param uiInstance ISAnimalUI
function UIHooks.configureAnimalUIForCyberDoggy(uiInstance)
    if not uiInstance or not uiInstance.animal then
        return
    end
    
    local currentAnimal = uiInstance.animal
    
    -- Validate animal is a CyberDog before configuring UI
    if CyberDoggyCoreUtilities.currentAnimalCyberDoggy(currentAnimal) then
        if uiInstance.avatarPanel and uiInstance.avatarPanel.setVariable then
            pcall(function()
                uiInstance.avatarPanel:setVariable("currentAnimalCyberDoggy", true)
            end)
        end
    end
end

-- Store original ISAnimalUI.create method
local originalCreateMethod = ISAnimalUI.create

-- Override ISAnimalUI.create with our enhanced version
---@diagnostic disable-next-line: duplicate-set-field
ISAnimalUI.create = function(selfInstance)
    -- Execute original creation logic with error handling
    local success = pcall(function()
        originalCreateMethod(selfInstance)
    end)
    
    if not success then
        print("[CyberDogCoreHooks] ERROR: Failed to execute original ISAnimalUI.create")
        return
    end
    
    -- Apply CyberDog-specific configuration with error handling
    pcall(function()
        UIHooks.configureAnimalUIForCyberDoggy(selfInstance)
    end)
end

print("[CyberDogCoreHooks] CyberDoggy UI hooks initialized with safe error handling")

return UIHooks

--]]