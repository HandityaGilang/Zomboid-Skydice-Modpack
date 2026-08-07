--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

-- Locations must be declared in render-order.
-- Location IDs must match BodyLocation= and CanBeEquipped= values in items.txt.
local group = BodyLocations.getGroup("Human")

-- Can use belt location from vanilla or write function to check rendering order...

group:getOrCreateLocation("KATTAJ1BeltLeft")
group:getOrCreateLocation("KATTAJ1BeltRight")

group:getOrCreateLocation("KATTAJ1BeltBackLeft") -- Extra locations used for back knife sheath
group:getOrCreateLocation("KATTAJ1BeltBackRight") -- Extra locations used for back knife sheath

group:getOrCreateLocation("KATTAJ1UpperLegs")
group:getOrCreateLocation("KATTAJ1LowerLegs")
group:getOrCreateLocation("KATTAJ1UpperArms")
group:getOrCreateLocation("KATTAJ1LowerArms")

group:getOrCreateLocation("KATTAJ1BackFanny") -- Location for Lower Back Things. Items here will not be hidden by Bulletproof vests
group:setExclusive("KATTAJ1BackFanny", "FannyPackBack") -- KATTAJ1BackFanny and FannyPackBack cannot be worn at the same time

group:getOrCreateLocation("KATTAJ1Balaclava")
group:setExclusive("KATTAJ1Balaclava", "Mask")
group:setExclusive("KATTAJ1Balaclava", "MaskEyes")
