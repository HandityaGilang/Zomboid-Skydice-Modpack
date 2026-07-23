-- This code is built on Yuhiko’s BodyLocationsTweaker API, All credit goes to him/her. 
-- Augmented by GanydeBielovzki to accommodate for changes post B42.12.
-- This code is augmented for the Frockin' Splendor! franchise.

require("NPCs/BodyLocations")

local group = BodyLocations.getGroup("Human")
local locations = group:getAllLocations()

-- Helper function: create or move a body location before/after a reference
local function AddOrMoveBodyLocation(name, reference, after)
    if type(name) ~= "string" then
        error("Argument 1 must be a string (body location name).", 2)
    end
    if type(reference) ~= "string" then
        error("Argument 2 must be a string (reference location).", 2)
    end

    -- Check if the reference location exists
    local refLocation = group:getLocation(reference)
    if not refLocation then
        error("Could not find the BodyLocation [" .. reference .. "] - please check the name.", 2)
    end

    -- Get existing or create new body location
    local bodyLocation = group:getLocation(name)
    if not bodyLocation then
        bodyLocation = BodyLocation.new(group, name)
    else
        locations:remove(bodyLocation) -- remove old instance if it already exists
    end

    -- Find reference index and insert before/after
    local index = group:indexOf(reference)
    if after then index = index + 1 end
    locations:add(index, bodyLocation)

    return bodyLocation
end

 AddOrMoveBodyLocation("BathRobeCoat", "BathRobe");
 AddOrMoveBodyLocation("JacketSuitSlim", "JacketSuit");
 AddOrMoveBodyLocation("FSJacketSuit", "JacketSuit");
 
 AddOrMoveBodyLocation("Shoes", "Skirt");

 local group = BodyLocations.getGroup("Human")
			group:setExclusive("FullSuitHead", "BathRobeCoat")
			group:setExclusive("FullSuit", "BathRobeCoat")
			group:setExclusive("FullTop", "BathRobeCoat")
			group:setExclusive("Boilersuit", "BathRobeCoat")
			
			group:setExclusive("BathRobeCoat", "BathRobe")
			
			group:setExclusive("BathRobeCoat", "Sweater")
			group:setExclusive("BathRobeCoat", "SweaterHat")
			group:setExclusive("BathRobeCoat", "Jersey")
			group:setExclusive("BathRobeCoat", "Jacket")
			group:setExclusive("BathRobeCoat", "Jacket_Down")
			group:setExclusive("BathRobeCoat", "JacketSuit")
			group:setExclusive("BathRobeCoat", "JacketHat")
			group:setExclusive("BathRobeCoat", "Jacket_Bulky")
			group:setExclusive("BathRobeCoat", "JacketHat_Bulky")
			group:setExclusive("BathRobeCoat", "PantsExtra")
			group:setExclusive("BathRobeCoat", "TorsoExtra")
			group:setExclusive("BathRobeCoat", "TorsoExtraVest")
			group:setExclusive("BathRobeCoat", "TorsoExtraVestBullet")
			group:setExclusive("BathRobeCoat", "Cuirass")
			group:setExclusive("BathRobeCoat", "Boilersuit")
			group:setExclusive("BathRobeCoat", "Webbing")
			group:setExclusive("BathRobeCoat", "SCBA")
			group:setExclusive("BathRobeCoat", "SCBAnotank")
			group:setExclusive("BodyCostume", "BathRobeCoat")
			group:setExclusive("BathRobeCoat", "SportShoulderpad")
			
			group:setHideModel("BathRobeCoat", "LeftWrist")
			group:setHideModel("BathRobeCoat", "RightWrist")
			group:setHideModel("BathRobeCoat", "FannyPackFront")
			group:setHideModel("BathRobeCoat", "Codpiece")
			group:setAltModel("BathRobeCoat", "ForeArm_Left")
			group:setAltModel("BathRobeCoat", "ForeArm_Right")
			
			
			group:setExclusive("FullSuit", "JacketSuitSlim")
			group:setExclusive("FullTop", "JacketSuitSlim")
			group:setExclusive("Boilersuit", "JacketSuitSlim")
			group:setExclusive("BathRobe", "JacketSuitSlim")
			group:setExclusive("FullRobe", "JacketSuitSlim")
			
			group:setExclusive("JacketSuitSlim", "JacketSuit")
			
			group:setExclusive("JacketSuitSlim", "Jacket")
			group:setExclusive("JacketSuitSlim", "Jacket_Down")
			group:setExclusive("JacketSuitSlim", "Jacket_Bulky")
			group:setExclusive("JacketSuitSlim", "JacketHat")
			group:setExclusive("JacketSuitSlim", "JacketHat_Bulky")
			group:setExclusive("JacketSuitSlim", "Sweater")
			group:setExclusive("JacketSuitSlim", "SweaterHat")
			group:setExclusive("JacketSuitSlim", "TorsoExtra")
			group:setExclusive("JacketSuitSlim", "TorsoExtraVest")
			group:setExclusive("JacketSuitSlim", "TorsoExtraVestBullet")
			group:setExclusive("JacketSuitSlim", "PantsExtra")
			group:setHideModel("JacketSuitSlim", "LeftWrist")
			group:setHideModel("JacketSuitSlim", "RightWrist")
			group:setHideModel("JacketSuitSlim", "FannyPackFront")
			group:setHideModel("JacketSuitSlim", "FannyPackBack")
			group:setHideModel("JacketSuitSlim", "Codpiece")
			group:setHideModel("JacketSuitSlim", "Jersey")
			group:setAltModel("JacketSuitSlim", "ForeArm_Left")
			group:setAltModel("JacketSuitSlim", "ForeArm_Right")
			group:setAltModel("JacketSuitSlim", "Cuirass")
			
			
			group:setExclusive("FullSuit", "FSJacketSuit")
			group:setExclusive("FullTop", "FSJacketSuit")
			group:setExclusive("Boilersuit", "FSJacketSuit")
			group:setExclusive("BathRobe", "FSJacketSuit")
			group:setExclusive("FullRobe", "FSJacketSuit")
			
			group:setExclusive("FSJacketSuit", "JacketSuit")
			group:setExclusive("FSJacketSuit", "JacketSuitSlim")
			group:setExclusive("FSJacketSuit", "BathRobeCoat")
			
			group:setExclusive("FSJacketSuit", "Jacket")
			group:setExclusive("FSJacketSuit", "Jacket_Down")
			group:setExclusive("FSJacketSuit", "Jacket_Bulky")
			group:setExclusive("FSJacketSuit", "JacketHat")
			group:setExclusive("FSJacketSuit", "JacketHat_Bulky")
			group:setExclusive("FSJacketSuit", "Sweater")
			group:setExclusive("FSJacketSuit", "SweaterHat")
			group:setExclusive("FSJacketSuit", "TorsoExtra")
			group:setExclusive("FSJacketSuit", "TorsoExtraVest")
			group:setExclusive("FSJacketSuit", "TorsoExtraVestBullet")
			group:setExclusive("FSJacketSuit", "PantsExtra")
			group:setHideModel("FSJacketSuit", "LeftWrist")
			group:setHideModel("FSJacketSuit", "RightWrist")
			group:setHideModel("FSJacketSuit", "FannyPackFront")
			group:setHideModel("FSJacketSuit", "FannyPackBack")
			group:setHideModel("FSJacketSuit", "Codpiece")
			group:setHideModel("FSJacketSuit", "Jersey")
			group:setAltModel("FSJacketSuit", "ForeArm_Left")
			group:setAltModel("FSJacketSuit", "ForeArm_Right")
			group:setAltModel("FSJacketSuit", "Cuirass")
