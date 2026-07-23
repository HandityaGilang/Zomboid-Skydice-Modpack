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

 AddOrMoveBodyLocation("KIU3", "UnderwearExtra1");
 AddOrMoveBodyLocation("KIU3", "UnderwearExtra1");
 AddOrMoveBodyLocation("KIU2", "UnderwearExtra1");
 AddOrMoveBodyLocation("KIU1", "UnderwearExtra1");
 AddOrMoveBodyLocation("KIU0", "UnderwearExtra1");
 AddOrMoveBodyLocation("KIUA", "Hat");
 AddOrMoveBodyLocation("KIUB", "Hat");
 AddOrMoveBodyLocation("KIUC", "Hat");
 AddOrMoveBodyLocation("RightLeg", "Neck"); --leg sleeve
 AddOrMoveBodyLocation("LeftLeg", "Neck"); --leg sleeve
 
 AddOrMoveBodyLocation("KIUX", "Sweater"); -- corset above clothes
 
 AddOrMoveBodyLocation("Shoes", "Skirt");



 local group = BodyLocations.getGroup("Human")
 group:setExclusive("TankTop", "KIUX")