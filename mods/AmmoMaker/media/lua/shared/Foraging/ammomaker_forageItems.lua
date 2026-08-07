--Ammo Maker by STIMP_TM, based on Project Zomboid forageDefinitions by eris

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
				Forest          = 4,
				DeepForest      = 4,
				Vegitation      = 4,
				FarmLand        = 4,
				Farm            = 4,
				TrailerPark     = 4,
				TownZone        = 4,
				Nav				= 4,
			},
			itemSizeModifier = 0.6,
		},

	};

	if SandboxVars.ammomakerOptions.ActivateArchery == true or getActivatedMods():contains("Arsenal(26)GunFighter") or getActivatedMods():contains("Arsenal(26)GunFighter[MAIN MOD 2.0]") then

		items.ammomaker_BirdFeather = {
			type = "ammomaker.ammomaker_BirdFeather",
			minCount = SandboxVars.ammomakerOptions.BirdFeatherSpawnMin,
			maxCount = SandboxVars.ammomakerOptions.BirdFeatherSpawnMax,
			xp = 2,
			categories = { "BirdProducts" },
			zones = {
				Forest          = 1,
				DeepForest      = 1,
				Vegitation      = 1,
				FarmLand        = 1,
				Farm            = 1,
				TrailerPark     = 1,
				TownZone        = 1,
				Nav             = 1,
			},
			itemSizeModifier = 0.6,
		};

	end

	for itemName, itemDef in pairs(items) do

		if (not forageDefs[itemName]) then

			forageDefs[itemName] = itemDef;

		end

    end

end

Events.preAddItemDefs.Add(ammoMakerAddForageItemDefs);