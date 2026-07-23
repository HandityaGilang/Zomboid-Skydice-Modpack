local distributionTable = VehicleDistributions[1]

VehicleDistributions.CAM79Ghost = {
    rolls = 4,
    items = {
        "Base.Shoes_ArmyBoots", 60,
        "Base.Jacket_ArmyCamoGreen", 60,
        "Base.Trousers_CamoGreen", 60,
        "Base.Gloves_LeatherGlovesBlack", 60,
    },
}

VehicleDistributions.CAM79 = {

	GloveBox = VehicleDistributions.GloveBox;
	CAM79Trunk = VehicleDistributions.TrunkStandard;
	CAM79Roofrack = VehicleDistributions.TrunkStandard;
}

VehicleDistributions.CAM79GH = {

	GloveBox = VehicleDistributions.GloveBox;
	CAM79Trunk = VehicleDistributions.CAM79Ghost;
	CAM79Roofrack = VehicleDistributions.TrunkStandard;
}

distributionTable["79camaro"] = { Normal = VehicleDistributions.CAM79; }
distributionTable["79camaroRS"] = { Normal = VehicleDistributions.CAM79; }
distributionTable["79camaroZ28"] = { Normal = VehicleDistributions.CAM79; }
distributionTable["79camaroGhost"] = { Normal = VehicleDistributions.CAM79GH; }