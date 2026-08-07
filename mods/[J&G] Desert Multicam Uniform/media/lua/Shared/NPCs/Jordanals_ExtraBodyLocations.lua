--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

-- Locations must be declared in render-order.
-- Location IDs must match BodyLocation= and CanBeEquipped= values in items.txt.
local group = BodyLocations.getGroup("Human")

group:getOrCreateLocation("Belt419")
group:getOrCreateLocation("Belt420")
group:getOrCreateLocation("Belt421")
group:getOrCreateLocation("Belt422")
group:getOrCreateLocation("Belt423")
group:getOrCreateLocation("Kneepads")
group:getOrCreateLocation("Elbowpads")
group:getOrCreateLocation("Uparml")
group:getOrCreateLocation("Uparmr")
group:getOrCreateLocation("Uparml2")
group:getOrCreateLocation("Uparmr2")
group:getOrCreateLocation("Darml")
group:getOrCreateLocation("Darmr")
group:getOrCreateLocation("Dlegl")
group:getOrCreateLocation("Dlegr")
group:getOrCreateLocation("Footl")
group:getOrCreateLocation("Footr")
group:getOrCreateLocation("Handl")
group:getOrCreateLocation("Handr")
group:getOrCreateLocation("Back001")
group:getOrCreateLocation("Head001")
group:getOrCreateLocation("Tail001")
group:getOrCreateLocation("Ears001")
group:getOrCreateLocation("Chin001")
group:getOrCreateLocation("TorsoExtraVest")

group:getOrCreateLocation("Jordans_BackBeltLeft")
group:getOrCreateLocation("Jordans_BackBeltRight")
group:getOrCreateLocation("Jordans_HipPouchBags")

group:getOrCreateLocation("KnifeySheatheFix")
group:getOrCreateLocation("KnifeSheathLeg")
--group:setExclusive("KnifeSheathLeg", "KnifeSheathLeg")
group:getOrCreateLocation("KnifeSheathBack")
--group:setExclusive("KnifeSheathBack", "KnifeSheathBack")
group:getOrCreateLocation("KatanaSheath")
--group:setExclusive("KatanaSheath", "KatanaSheath")
group:getOrCreateLocation("KatanaSheathHip")
--group:setExclusive("KatanaSheathHip", "KatanaSheathHip")

group:getOrCreateLocation("KATTAJ1UpperLegs")
group:getOrCreateLocation("KATTAJ1LowerLegs")
group:getOrCreateLocation("KATTAJ1UpperArms")
group:getOrCreateLocation("KATTAJ1LowerArms")

group:getOrCreateLocation("KATTAJ1Balaclava")
group:setExclusive("KATTAJ1Balaclava", "Mask")
group:setExclusive("KATTAJ1Balaclava", "MaskEyes")
