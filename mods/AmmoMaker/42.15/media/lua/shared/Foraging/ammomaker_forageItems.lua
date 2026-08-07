--Ammo Maker by STIMP_TM, based on Project Zomboid forageItemDefs by eris

require "Foraging/forageDefinitions"
require 'Foraging/forageSystem'

local function ammoMakerAddForageItemDefs()

	local items = {

		ammomaker_birdExcrement = {
			type = "ammomaker.ammomaker_BirdExcrement",
			minCount = SandboxVars.ammomakerOptions.BirdExSpawnMin,
			maxCount = SandboxVars.ammomakerOptions.BirdExSpawnMax,
			xp = 2,
			categories = { "BirdProducts" },
			zones = {
                BirchForest     = 5,
			    PHForest        = 5,
			    PRForest        = 5,
                DeepForest      = 5,
                FarmLand        = 5,
                ForagingNav     = 5,
                Forest          = 5,
			    OrganicForest	= 5,
                TownZone        = 5,
                TrailerPark     = 5,
                Vegitation      = 5,
			},
			itemSizeModifier = 0.6,
		},

		ammomaker_birdFeather = {
			type = "ammomaker.ammomaker_BirdFeather",
			minCount = SandboxVars.ammomakerOptions.BirdFeatherSpawnMin,
			maxCount = SandboxVars.ammomakerOptions.BirdFeatherSpawnMax,
			xp = 2,
			categories = { "BirdProducts" },
			zones = {
                BirchForest     = 1,
			    PHForest        = 1,
			    PRForest        = 1,
                DeepForest      = 1,
                FarmLand        = 1,
                ForagingNav     = 1,
                Forest          = 1,
			    OrganicForest	= 1,
                TownZone        = 1,
                TrailerPark     = 1,
                Vegitation      = 1,
			},
			itemSizeModifier = 0.6,
		},

	};

	local forageCasingTypes = ammoMakerGetCasingTypesActive();

	if forageCasingTypes["ammomaker.ammomaker_CasingBottleneckS"] then

		items.ammomaker_casingBottleneckS = {
			type = "ammomaker.ammomaker_CasingBottleneckSOld",
			minCount = SandboxVars.ammomakerOptions.CasingsSpawnMin,
			maxCount = SandboxVars.ammomakerOptions.CasingsSpawnMax,
			xp = 5,
			categories = { "Casings" },
			zones = {
                BirchForest     = 1,
			    PHForest        = 1,
			    PRForest        = 1,
                DeepForest      = 1,
                FarmLand        = 3,
                ForagingNav     = 5,
                Forest          = 1,
			    OrganicForest	= 1,
                TownZone        = 5,
                TrailerPark     = 4,
                Vegitation      = 1,
			},
			itemSizeModifier = 0.3,
		};

	end

	if forageCasingTypes["ammomaker.ammomaker_CasingBottleneckM"] then

		items.ammomaker_casingBottleneckM = {
			type = "ammomaker.ammomaker_CasingBottleneckMOld",
			minCount = SandboxVars.ammomakerOptions.CasingsSpawnMin,
			maxCount = SandboxVars.ammomakerOptions.CasingsSpawnMax,
			xp = 5,
			categories = { "Casings" },
			zones = {
                BirchForest     = 1,
			    PHForest        = 1,
			    PRForest        = 1,
                DeepForest      = 1,
                FarmLand        = 3,
                ForagingNav     = 5,
                Forest          = 1,
			    OrganicForest	= 1,
                TownZone        = 5,
                TrailerPark     = 4,
                Vegitation      = 1,

			},
			itemSizeModifier = 0.3,
		};

	end

	if forageCasingTypes["ammomaker.ammomaker_CasingBottleneckL"] then

		items.ammomaker_casingBottleneckL = {
			type = "ammomaker.ammomaker_CasingBottleneckLOld",
			minCount = SandboxVars.ammomakerOptions.CasingsSpawnMin,
			maxCount = SandboxVars.ammomakerOptions.CasingsSpawnMax,
			xp = 5,
			categories = { "Casings" },
			zones = {
                BirchForest     = 1,
			    PHForest        = 1,
			    PRForest        = 1,
                DeepForest      = 1,
                FarmLand        = 2,
                ForagingNav     = 4,
                Forest          = 1,
			    OrganicForest	= 1,
                TownZone        = 4,
                TrailerPark     = 3,
                Vegitation      = 1,

			},
			itemSizeModifier = 0.3,
		};

	end

	if forageCasingTypes["ammomaker.ammomaker_CasingBottleneckMRim"] then

		items.ammomaker_casingBottleneckMRim = {
			type = "ammomaker.ammomaker_CasingBottleneckMRimOld",
			minCount = SandboxVars.ammomakerOptions.CasingsSpawnMin,
			maxCount = SandboxVars.ammomakerOptions.CasingsSpawnMax,
			xp = 5,
			categories = { "Casings" },
			zones = {
                BirchForest     = 1,
			    PHForest        = 1,
			    PRForest        = 1,
                DeepForest      = 1,
                FarmLand        = 3,
                ForagingNav     = 5,
                Forest          = 1,
			    OrganicForest	= 1,
                TownZone        = 5,
                TrailerPark     = 4,
                Vegitation      = 1,
			},
			itemSizeModifier = 0.3,
		};

	end

	if forageCasingTypes["ammomaker.ammomaker_CasingStraightS"] then

		items.ammomaker_casingStraightS = {
			type = "ammomaker.ammomaker_CasingStraightSOld",
			minCount = SandboxVars.ammomakerOptions.CasingsSpawnMin,
			maxCount = SandboxVars.ammomakerOptions.CasingsSpawnMax,
			xp = 5,
			categories = { "Casings" },
			zones = {
                BirchForest     = 1,
			    PHForest        = 1,
			    PRForest        = 1,
                DeepForest      = 1,
                FarmLand        = 3,
                ForagingNav     = 5,
                Forest          = 1,
			    OrganicForest	= 1,
                TownZone        = 5,
                TrailerPark     = 4,
                Vegitation      = 1,
			},
			itemSizeModifier = 0.3,
		};

	end

	if forageCasingTypes["ammomaker.ammomaker_CasingStraightM"] then

		items.ammomaker_casingStraightM = {
			type = "ammomaker.ammomaker_CasingStraightMOld",
			minCount = SandboxVars.ammomakerOptions.CasingsSpawnMin,
			maxCount = SandboxVars.ammomakerOptions.CasingsSpawnMax,
			xp = 5,
			categories = { "Casings" },
			zones = {
                BirchForest     = 1,
			    PHForest        = 1,
			    PRForest        = 1,
                DeepForest      = 1,
                FarmLand        = 3,
                ForagingNav     = 5,
                Forest          = 1,
			    OrganicForest	= 1,
                TownZone        = 5,
                TrailerPark     = 4,
                Vegitation      = 1,
			},
			itemSizeModifier = 0.3,
		};

	end

	if forageCasingTypes["ammomaker.ammomaker_CasingStraightL"] then

		items.ammomaker_casingStraightL = {
			type = "ammomaker.ammomaker_CasingStraightLOld",
			minCount = SandboxVars.ammomakerOptions.CasingsSpawnMin,
			maxCount = SandboxVars.ammomakerOptions.CasingsSpawnMax,
			xp = 5,
			categories = { "Casings" },
			zones = {
                BirchForest     = 1,
			    PHForest        = 1,
			    PRForest        = 1,
                DeepForest      = 1,
                FarmLand        = 3,
                ForagingNav     = 5,
                Forest          = 1,
			    OrganicForest	= 1,
                TownZone        = 5,
                TrailerPark     = 4,
                Vegitation      = 1,
			},
			itemSizeModifier = 0.3,
		};

	end

	if forageCasingTypes["ammomaker.ammomaker_CasingStraightSRim"] then

		items.ammomaker_casingStraightSRim = {
			type = "ammomaker.ammomaker_CasingStraightSRimOld",
			minCount = SandboxVars.ammomakerOptions.CasingsSpawnMin,
			maxCount = SandboxVars.ammomakerOptions.CasingsSpawnMax,
			xp = 5,
			categories = { "Casings" },
			zones = {
                BirchForest     = 1,
			    PHForest        = 1,
			    PRForest        = 1,
                DeepForest      = 1,
                FarmLand        = 3,
                ForagingNav     = 5,
                Forest          = 1,
			    OrganicForest	= 1,
                TownZone        = 5,
                TrailerPark     = 4,
                Vegitation      = 1,
			},
			itemSizeModifier = 0.3,
		};

	end

	if forageCasingTypes["ammomaker.ammomaker_CasingStraightMRim"] then

		items.ammomaker_casingStraightMRim = {
			type = "ammomaker.ammomaker_CasingStraightMRimOld",
			minCount = SandboxVars.ammomakerOptions.CasingsSpawnMin,
			maxCount = SandboxVars.ammomakerOptions.CasingsSpawnMax,
			xp = 5,
			categories = { "Casings" },
			zones = {
                BirchForest     = 1,
			    PHForest        = 1,
			    PRForest        = 1,
                DeepForest      = 1,
                FarmLand        = 3,
                ForagingNav     = 5,
                Forest          = 1,
			    OrganicForest	= 1,
                TownZone        = 5,
                TrailerPark     = 4,
                Vegitation      = 1,
			},
			itemSizeModifier = 0.3,
		};

	end

	if forageCasingTypes["ammomaker.ammomaker_CasingStraightLRim"] then

		items.ammomaker_casingStraightLRim = {
			type = "ammomaker.ammomaker_CasingStraightLRimOld",
			minCount = SandboxVars.ammomakerOptions.CasingsSpawnMin,
			maxCount = SandboxVars.ammomakerOptions.CasingsSpawnMax,
			xp = 5,
			categories = { "Casings" },
			zones = {
				BirchForest     = 1,
			    PHForest        = 1,
			    PRForest        = 1,
                DeepForest      = 1,
                FarmLand        = 4,
                ForagingNav     = 5,
                Forest          = 1,
			    OrganicForest	= 1,
                TownZone        = 5,
                TrailerPark     = 4,
                Vegitation      = 1,
			},
			itemSizeModifier = 0.3,
		};

	end

	if forageCasingTypes["ammomaker.ammomaker_HullShotgunS"] then

		items.ammomaker_hullFiredShotgunS = {
			type = "ammomaker.ammomaker_HullFiredShotgunS",
			minCount = SandboxVars.ammomakerOptions.CasingsSpawnMin,
			maxCount = SandboxVars.ammomakerOptions.CasingsSpawnMax,
			xp = 5,
			categories = { "Casings" },
			zones = {
				BirchForest     = 2,
			    PHForest        = 2,
			    PRForest        = 2,
                DeepForest      = 2,
                FarmLand        = 4,
                ForagingNav     = 4,
                Forest          = 2,
			    OrganicForest	= 2,
                TownZone        = 4,
                TrailerPark     = 5,
                Vegitation      = 2,
			},
			itemSizeModifier = 0.3,
		};

	end

	if forageCasingTypes["ammomaker.ammomaker_HullShotgunL"] then

		items.ammomaker_hullFiredShotgunL = {
			type = "ammomaker.ammomaker_HullFiredShotgunL",
			minCount = SandboxVars.ammomakerOptions.CasingsSpawnMin,
			maxCount = SandboxVars.ammomakerOptions.CasingsSpawnMax,
			xp = 5,
			categories = { "Casings" },
			zones = {
				BirchForest     = 2,
			    PHForest        = 2,
			    PRForest        = 2,
                DeepForest      = 2,
                FarmLand        = 4,
                ForagingNav     = 4,
                Forest          = 2,
			    OrganicForest	= 2,
                TownZone        = 4,
                TrailerPark     = 5,
                Vegitation      = 2,
			},
			itemSizeModifier = 0.3,
		};

	end

	if forageCasingTypes["ammomaker.ammomaker_CasingGrenade"] then

		items.ammomaker_casingGrenade = {
			type = "ammomaker.ammomaker_CasingGrenadeOld",
			minCount = SandboxVars.ammomakerOptions.CasingsSpawnMin,
			maxCount = SandboxVars.ammomakerOptions.CasingsSpawnMax,
			xp = 5,
			categories = { "Casings" },
			zones = {
				BirchForest     = 1,
			    PHForest        = 1,
			    PRForest        = 1,
                DeepForest      = 1,
                FarmLand        = 2,
                ForagingNav     = 3,
                Forest          = 1,
			    OrganicForest	= 1,
                TownZone        = 2,
                TrailerPark     = 2,
                Vegitation      = 1,
			},
			itemSizeModifier = 0.3,
		};

	end

	forageSystem.populateItemDefs(items);

end

Events.preAddItemDefs.Add(ammoMakerAddForageItemDefs);