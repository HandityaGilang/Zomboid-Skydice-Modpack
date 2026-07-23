--[[
NOTE: remove the above comment brackets if using this template for your own mod!

local CyberDoggyCoreUtilities = require("CyberDoggyMod/CyberDoggyModCoreUtilities")

local CyberDogInteractionHandler = {}


--- @param contextMenu ISContextMenu
--- @param targetPlayer IsoPlayer
--- @param targetAnimal IsoAnimal
function CyberDogInteractionHandler.buildCyberDogContextMenu(contextMenu, targetPlayer, targetAnimal)
    -- Validate that target is a CyberDoggy using the utility function
    if not CyberDoggyCoreUtilities.currentAnimalCyberDoggy(targetAnimal) then
        return
    end
    

end

--- Event callback for animal context menu creation
--- @type Callback_OnClickedAnimalForContext
local function onAnimalContextMenuRequested(playerIndex, contextMenu, animalList, testMode)
    -- Validate inputs
    if not animalList or animalList[1] == nil then
        return
    end
    
    -- Get the player and first animal from the list
    local targetPlayer = getSpecificPlayer(playerIndex)
    local primaryAnimal = animalList[1]
    
    -- Build CyberDoggy-specific menu options
    CyberDogInteractionHandler.buildCyberDogContextMenu(contextMenu, targetPlayer, primaryAnimal)
end

-- Register event listener
Events.OnClickedAnimalForContext.Add(onAnimalContextMenuRequested)

return CyberDogInteractionHandler

--]]