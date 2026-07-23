local distributionTable = VehicleDistributions[1]

VehicleDistributions.LP400GloveBox = {
    rolls = 1,
    items = {
        "Base.78lamboCountachMagazine", 60,
        "Base.Pen", 4,
        "Base.Pencil", 4,
        "Base.Cigarettes", 5,
        "Base.Lighter", 5,
        "Base.Matches", 3,
        "Base.Tissue", 2,
    },
    junk = ClutterTables.GloveBoxJunk,
}

VehicleDistributions.LP400distro = {

	GloveBox = VehicleDistributions.LP400GloveBox;
	LP400Trunk = VehicleDistributions.TrunkStandard;
	LP400TrunkFront = VehicleDistributions.GloveBox;
    LP400Roofrack = VehicleDistributions.GloveBox;
}

distributionTable["78lamboCountachLP400"] = { Normal = VehicleDistributions.LP400distro; }
distributionTable["78lamboCountachLP400S"] = { Normal = VehicleDistributions.LP400distro; }
distributionTable["78lamboCountachLP400Scb"] = { Normal = VehicleDistributions.LP400distro; }