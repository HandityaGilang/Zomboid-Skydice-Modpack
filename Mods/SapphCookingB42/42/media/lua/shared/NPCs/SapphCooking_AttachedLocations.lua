--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

--this code is used for attatchments on aprons!
local group = AttachedLocations.getGroup("Human")


group:getOrCreateLocation("ChefApronLeft"):setAttachmentName("ChefApronLeft")
group:getOrCreateLocation("ChefApronLeftHammer"):setAttachmentName("ChefApronLeftHammer")
group:getOrCreateLocation("ChefApronLeftCleaver"):setAttachmentName("ChefApronLeftCleaver")
group:getOrCreateLocation("ChefApronLeftTools"):setAttachmentName("ChefApronLeftTools")
group:getOrCreateLocation("ChefApronLeftHolster"):setAttachmentName("ChefApronLeftHolster") 
--holster only on the left.
--this is for balancing~ c:



group:getOrCreateLocation("ChefApronRight"):setAttachmentName("ChefApronRight")
group:getOrCreateLocation("ChefApronRightHammer"):setAttachmentName("ChefApronRightHammer")
group:getOrCreateLocation("ChefApronRightCleaver"):setAttachmentName("ChefApronRightCleaver")
group:getOrCreateLocation("ChefApronRightTools"):setAttachmentName("ChefApronRightTools")

group:getOrCreateLocation("ChefApronPencil"):setAttachmentName("ChefApronPencil")

if getDebug() then
	group:getOrCreateLocation("OnBack"):setAttachmentName("back")
end
