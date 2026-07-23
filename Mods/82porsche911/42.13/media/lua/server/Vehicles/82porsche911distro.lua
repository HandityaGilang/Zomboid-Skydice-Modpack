local distributionTable = VehicleDistributions[1]

VehicleDistributions.PRS82GloveBox = {
    rolls = 1,
    items = {
        "Base.82porsche911Magazine", 60,
        "Base.Pen", 4,
        "Base.Pencil", 4,
        "Base.Cigarettes", 5,
        "Base.Lighter", 5,
        "Base.Matches", 3,
        "Base.Tissue", 2,
    },
    junk = ClutterTables.GloveBoxJunk,
}

VehicleDistributions.PRS82 = {

	GloveBox = VehicleDistributions.PRS82GloveBox;
	PRS82Trunk = VehicleDistributions.TrunkSports;
    PRS82Roofrack  = VehicleDistributions.GloveBox;
}

distributionTable["82porsche911turbo"] = { Normal = VehicleDistributions.PRS82; }
distributionTable["82porsche911rwb"] = { Normal = VehicleDistributions.PRS82; }
distributionTable["82porsche911sc"] = { Normal = VehicleDistributions.PRS82; }
distributionTable["82porsche911targa"] = { Normal = VehicleDistributions.PRS82; }