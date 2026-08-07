--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

local KATTAJ1Locations = {
  "KATTAJ1BeltLeft",
  "KATTAJ1BeltRight",
  "KATTAJ1BeltBackLeft", -- Extra locations used for back knife sheath
  "KATTAJ1BeltBackRight", -- Extra locations used for back knife sheath
  "KATTAJ1UpperLegs",
  "KATTAJ1LowerLegs",
  "KATTAJ1Knees",
  "KATTAJ1UpperArms",
  "KATTAJ1LowerArms",
  "KATTAJ1Elbows",
  "KATTAJ1BackFanny",
  "KATTAJ1Balaclava"
}

local group = BodyLocations.getGroup("Human")
for _, location in ipairs(KATTAJ1Locations) do
    local bodyLocation = BodyLocation.new(group, location)
    group:getAllLocations():add(bodyLocation)
end


------------------------------------------------------------

-- B42 Slots Exclusions
group:setExclusive("KATTAJ1UpperLegs", "Thigh_Left")
group:setExclusive("KATTAJ1UpperLegs", "Thigh_Right")
group:setExclusive("KATTAJ1LowerLegs", "Knee_Left")
group:setExclusive("KATTAJ1LowerLegs", "Knee_Right")
group:setExclusive("KATTAJ1LowerLegs", "Calf_Left")
group:setExclusive("KATTAJ1LowerLegs", "Calf_Right")

group:setExclusive("KATTAJ1Knees", "Knee_Left")
group:setExclusive("KATTAJ1Knees", "Knee_Right")
group:setExclusive("KATTAJ1Knees", "KATTAJ1LowerLegs")


------------------------------------------------------------

-- B42 Slots Exclusions
group:setExclusive("KATTAJ1UpperArms", "ShoulderpadLeft")
group:setExclusive("KATTAJ1UpperArms", "ShoulderpadRight")
group:setExclusive("KATTAJ1LowerArms", "Elbow_Left")
group:setExclusive("KATTAJ1LowerArms", "Elbow_Right")
group:setExclusive("KATTAJ1LowerArms", "ForeArm_Left")
group:setExclusive("KATTAJ1LowerArms", "ForeArm_Right")

group:setExclusive("KATTAJ1Elbows", "Elbow_Left")
group:setExclusive("KATTAJ1Elbows", "Elbow_Right")
group:setExclusive("KATTAJ1Elbows", "KATTAJ1LowerArms")


------------------------------------------------------------
group:setExclusive("KATTAJ1BackFanny", "FannyPackBack") -- KATTAJ1BackFanny and FannyPackBack cannot be worn at the same time

group:setExclusive("KATTAJ1Balaclava", "Mask")
group:setExclusive("KATTAJ1Balaclava", "MaskEyes")
