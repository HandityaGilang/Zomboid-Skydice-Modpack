local distributionTable = VehicleDistributions[1]

VehicleDistributions.CAM79GloveBox = {
    rolls = 1,
    items = {
        "Base.79camaroMagazine", 60,
        "Base.Pen", 4,
        "Base.Pencil", 4,
        "Base.Cigarettes", 5,
        "Base.Lighter", 5,
        "Base.Matches", 3,
        "Base.Tissue", 2,
    },
    junk = ClutterTables.GloveBoxJunk,
}

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