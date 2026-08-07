--***********************************************************
--**                THE Jordanal Mess                      **
--***********************************************************

require("NPCs/BodyLocations")

-- 42.13

local group = BodyLocations.getGroup("Human")

    -- Hips
group:getOrCreateLocation(Jordanals_BodyLocation.Jordans_BackBeltLeft)
group:getOrCreateLocation(Jordanals_BodyLocation.Jordans_BackBeltRight)
group:getOrCreateLocation(Jordanals_BodyLocation.Jordans_HipPouchBags)