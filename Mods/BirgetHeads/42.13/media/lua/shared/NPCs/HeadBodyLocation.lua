require("NPCs/BodyLocations")

local group = BodyLocations.getGroup("Human")

if getActivatedMods():contains("BirgetSPA") then --доделай

	group:setHideModel("SPNCC:Face", "BirgetCC:EyeContacts")
	group:setHideModel("SPNCC:Face", "BirgetCC:Wrinkles")
	group:setHideModel("SPNCC:Face", "BirgetCC:Freckles")
	group:setHideModel("SPNCC:Face", "BirgetCC:MolesUpperFace")
	group:setHideModel("SPNCC:Face", "BirgetCC:MolesLowerFace")
	group:setHideModel("SPNCC:Face", "BirgetCC:ScarsEyeLeft")
	group:setHideModel("SPNCC:Face", "BirgetCC:ScarsEyeRight")
	group:setHideModel("SPNCC:Face", "BirgetCC:ScarsMouth")
	group:setHideModel("SPNCC:Face", "BirgetCC:ScarsCheeckLeft")
	group:setHideModel("SPNCC:Face", "BirgetCC:ScarsCheeckRight")
	group:setHideModel("SPNCC:Face", "BirgetCC:ScarsNose")
	group:setHideModel("SPNCC:Face", "BirgetCC:ShinerEyeLeft")
	group:setHideModel("SPNCC:Face", "BirgetCC:ShinerEyeRight")
	group:setHideModel("SPNCC:Face", "BirgetCC:BruiseMouth")
	group:setHideModel("SPNCC:Face", "BirgetCC:BruiseCheeckLeft")
	group:setHideModel("SPNCC:Face", "BirgetCC:BruiseCheeckRight")
	group:setHideModel("SPNCC:Face", "BirgetCC:BruiseNose")
	group:setHideModel("SPNCC:Face", "FaceMask")
	group:setHideModel("SPNCC:Face", "MakeUp_FullFace")
	group:setHideModel("SPNCC:Face", "MakeUp_Eyes")
	group:setHideModel("SPNCC:Face", "MakeUp_EyesShadow")
	group:setHideModel("SPNCC:Face", "MakeUp_Lips")
else
return
end


