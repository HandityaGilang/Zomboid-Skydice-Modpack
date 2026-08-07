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
            zoneChance              = {
                Forest          = 30,
                DeepForest      = 30,
                Vegitation      = 30,
                FarmLand        = 60,
                Farm            = 70,
                TrailerPark     = 70,
                TownZone        = 70,
                Nav             = 70,
            },
            chanceToMoveIcon        = 20.0,
            chanceToCreateIcon      = 10.0,
            focusChanceMin			= 25.0,
            focusChanceMax			= 40.0,
        },

    };

    for catName, catDef in pairs(categories) do

        if (not forageCategories[catName]) then

            forageCategories[catName] = catDef;

        end

    end

end

Events.preAddCatDefs.Add(ammoMakerAddForageCatDefs);