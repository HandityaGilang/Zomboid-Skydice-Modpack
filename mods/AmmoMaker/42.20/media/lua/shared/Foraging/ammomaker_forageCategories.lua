--Ammo Maker by STIMP_TM, based on Project Zomboid forageCategories by eris

require 'Foraging/forageSystem'

local function ammoMakerAddForageCatDefs()

    local categories = {
    
        ["BirdProducts"] = {
            name                    = "BirdProducts",
            typeCategory            = "Materials",
            identifyCategoryPerk    = "PlantScavenging",
            identifyCategoryLevel   = 0,
            categoryHidden          = false,
            validFloors             = { "ANY" },
            zones                   = {
                BirchForest     = 30,
                DeepForest      = 30,
                FarmLand        = 60,
                ForagingNav     = 80,
                Forest          = 30,
			    OrganicForest	= 30,
			    PHForest        = 30,
			    PRForest        = 30,
                TownZone        = 80,
                TrailerPark     = 80,
                Vegitation      = 30,
            },
            chanceToMoveIcon        = 20.0,
            chanceToCreateIcon      = 10.0,
            focusChanceMin			= 25.0,
            focusChanceMax			= 40.0,
        },
        ["Casings"] = {
            name                    = "Casings",
            typeCategory            = "Materials",
            identifyCategoryPerk    = "PlantScavenging",
            identifyCategoryLevel   = 0,
            categoryHidden          = false,
            validFloors             = { "ANY" },
            zones                   = {
                BirchForest     = 5,
                DeepForest      = 5,
                FarmLand        = 7,
                ForagingNav     = 30,
                Forest          = 5,
			    OrganicForest	= 5,
			    PHForest        = 5,
			    PRForest        = 5,
                TownZone        = 30,
                TrailerPark     = 20,
                Vegitation      = 5,
            },
            chanceToMoveIcon        = 20.0,
            chanceToCreateIcon      = 10.0,
            focusChanceMin			= 25.0,
            focusChanceMax			= 40.0,
        },

    };

    forageSystem.populateCatDefs(categories);

end

Events.preAddCatDefs.Add(ammoMakerAddForageCatDefs);