require("Foraging/forageDefinitions")
require("Foraging/forageSystem")
local logger = require("dgmc_cleaning_wipes_logging")

local function injectWipes()
	local def =
	{
		type = "DGMC.CleaningWipes",
		skill = 0,
		chance = 5,
		xp = 5,
		categories = { "Junk", "Trash" },
		zones = 
		{
			TrailerPark = 5,
			TownZone = 5,
		},
		forceOutside = false,
		canBeAboveFloor = true,
		spawnFuncs	= { forageSystem.doGenericItemSpawn },
	}

	local type, result = forageSystem.addItemDef(def)
	if result == true then
		logger.info("initialization", "added wipes to foraging tables")
	else
		logger.error("initialization", "unable to add wipes to foraging tables")
	end
end

Events.onAddForageDefs.Add(injectWipes)