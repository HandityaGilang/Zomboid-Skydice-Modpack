require("NPCs/BodyLocations")

local group = BodyLocations.getGroup("Human")

if getActivatedMods():contains("BirgetSPA") then

	group:setHideModel("Face_Model", "EyeContacts")
	group:setHideModel("Face_Model", "Wrinkles")
	group:setHideModel("Face_Model", "Freckles")
	group:setHideModel("Face_Model", "MolesUpperFace")
	group:setHideModel("Face_Model", "MolesLowerFace")
	group:setHideModel("Face_Model", "ScarsEyeLeft")
	group:setHideModel("Face_Model", "ScarsEyeRight")
	group:setHideModel("Face_Model", "ScarsMouth")
	group:setHideModel("Face_Model", "ScarsCheeckLeft")
	group:setHideModel("Face_Model", "ScarsCheeckRight")
	group:setHideModel("Face_Model", "ScarsNose")
	group:setHideModel("Face_Model", "ShinerEyeLeft")
	group:setHideModel("Face_Model", "ShinerEyeRight")
	group:setHideModel("Face_Model", "BruiseMouth")
	group:setHideModel("Face_Model", "BruiseCheeckLeft")
	group:setHideModel("Face_Model", "BruiseCheeckRight")
	group:setHideModel("Face_Model", "BruiseNose")
	group:setHideModel("Face_Model", "FaceMask")
	group:setHideModel("Face_Model", "MakeUp_FullFace")
	group:setHideModel("Face_Model", "MakeUp_Eyes")
	group:setHideModel("Face_Model", "MakeUp_EyesShadow")
	group:setHideModel("Face_Model", "MakeUp_Lips")
else
return
end


