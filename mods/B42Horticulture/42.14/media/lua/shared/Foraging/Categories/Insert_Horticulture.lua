require "Foraging/forageDefinitions";
require "Foraging/forageSystem";

local function generateWildPlantsDefs_Horticulture()
	local itemDefs = {
		Hemp = {
			type = "Base.HempBundle",
			minCount = 1,
			maxCount = 1,
			xp = 2,
			categories = { "WildPlants" },
			zones = {
				BirchForest  	= 1,
				DeepForest  	= 1,
				FarmLand    	= 1,
				Forest      	= 1,
				OrganicForest  	= 1,
				PHForest  		= 1,
				PRForest  		= 1,
				Vegitation  	= 1,
			},
			spawnFuncs = { forageSystem.doRandomAgeSpawn, forageSystem.doWildCropSpawn },
			altWorldTexture = forageSystem.worldSprites.wildPlants,
		},
	};
	for itemName, itemDef in pairs(itemDefs) do
		forageSystem.addForageDef(itemName, itemDef);
	end;
end

generateWildPlantsDefs_Horticulture();