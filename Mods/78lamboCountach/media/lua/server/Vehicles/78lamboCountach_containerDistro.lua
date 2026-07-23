local distributionTable = VehicleDistributions[1]

VehicleDistributions.LP400distro = {

	GloveBox = VehicleDistributions.GloveBox;
	LP400Trunk = VehicleDistributions.TrunkStandard;
	LP400TrunkFront = VehicleDistributions.GloveBox;
    LP400Roofrack = VehicleDistributions.GloveBox;
}

distributionTable["78lamboCountachLP400"] = { Normal = VehicleDistributions.LP400distro; }
distributionTable["78lamboCountachLP400S"] = { Normal = VehicleDistributions.LP400distro; }
distributionTable["78lamboCountachLP400Scb"] = { Normal = VehicleDistributions.LP400distro; }