local group = BodyLocations.getGroup("Human")

group:getOrCreateLocation("Face_Model")
group:getOrCreateLocation("EyeContacts")
group:getOrCreateLocation("Wrinkles")
group:getOrCreateLocation("Freckles")
group:getOrCreateLocation("MolesUpperFace")
group:getOrCreateLocation("MolesLowerFace")

group:getOrCreateLocation("ScarsEyeLeft")
group:getOrCreateLocation("ScarsEyeRight")
group:getOrCreateLocation("ScarsMouth")
group:getOrCreateLocation("ScarsCheeckLeft")
group:getOrCreateLocation("ScarsCheeckRight")
group:getOrCreateLocation("ScarsNose")
group:getOrCreateLocation("ShinerEyeLeft")
group:getOrCreateLocation("ShinerEyeRight")
group:getOrCreateLocation("BruiseMouth")
group:getOrCreateLocation("BruiseCheeckLeft")
group:getOrCreateLocation("BruiseCheeckRight")
group:getOrCreateLocation("BruiseNose")
group:getOrCreateLocation("FaceMask")

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

if getActivatedMods():contains("TransmogDE") then
require("TransmogDE");

TransmogDE.addBodyLocationToIgnore("EyeContacts");
TransmogDE.addBodyLocationToIgnore("Wrinkles");
TransmogDE.addBodyLocationToIgnore("Freckles");
TransmogDE.addBodyLocationToIgnore("MolesUpperFace");
TransmogDE.addBodyLocationToIgnore("MolesLowerFace");


TransmogDE.addBodyLocationToIgnore("ScarsEyeLeft");
TransmogDE.addBodyLocationToIgnore("ScarsEyeRight");
TransmogDE.addBodyLocationToIgnore("ScarsCheeckLeft");
TransmogDE.addBodyLocationToIgnore("ScarsCheeckRight");
TransmogDE.addBodyLocationToIgnore("ScarsMouth");
TransmogDE.addBodyLocationToIgnore("ScarsNose");

TransmogDE.addBodyLocationToIgnore("ShinerEyeLeft");
TransmogDE.addBodyLocationToIgnore("ShinerEyeRight");
TransmogDE.addBodyLocationToIgnore("BruiseCheeckLeft");
TransmogDE.addBodyLocationToIgnore("BruiseCheeckRight");
TransmogDE.addBodyLocationToIgnore("BruiseMouth");
TransmogDE.addBodyLocationToIgnore("BruiseNose");



TransmogDE.addBodyLocationToIgnore("FaceMask");
TransmogDE.addBodyLocationToIgnore("NailPolish");
TransmogDE.addBodyLocationToIgnore("NailPolishFeet");

else
return -- End script if TransmogDE is not active
end
