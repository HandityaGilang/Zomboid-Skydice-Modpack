VehicleDistributions.TrueMoozicStepVanTruckBed = {
    rolls = 25,
    items = {
        "PopBottle", 10,

    },
    junk = {
        rolls = 5,
        items = {
            "WaterRationCan_Box", 10,
            "ProduceBox_Large", 10,
 

        },
    }
}

VehicleDistributions.TrueMoozicStepVanGloveBox = {
    rolls = 5,
    items = {
        "Crisps", 20,

    },
    junk = {
        rolls = 5,
        items = {

            "Money", 10,

        },
    },
}

VehicleDistributions.TrueMoozicStepVan = {
    TruckBed = VehicleDistributions.TrueMoozicStepVanTruckBed,
    GloveBox = VehicleDistributions.TrueMoozicStepVanGloveBox,
}

VehicleDistributions[1] = VehicleDistributions[1] or {}
VehicleDistributions[1]["TrueMoozicStepVan"] = {
    Normal = VehicleDistributions.TrueMoozicStepVan,
}