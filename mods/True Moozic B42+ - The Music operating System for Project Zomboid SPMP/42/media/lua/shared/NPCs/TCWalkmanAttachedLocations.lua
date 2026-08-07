require "NPCs/AttachedLocations"

local group = AttachedLocations.getGroup("Human")

group:getOrCreateLocation("TCWalkman Belt Left"):setAttachmentName("tcwalkman_belt_left")
group:getOrCreateLocation("TCWalkman Belt Right"):setAttachmentName("tcwalkman_belt_right") 