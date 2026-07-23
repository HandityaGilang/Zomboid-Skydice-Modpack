require 'Foraging/forageSystem'

Events.onAddForageDefs.Add(function()

local Thermos ={
	type = "SapphCooking.EmptyThermos",
    minCount=1,
	maxCount=1,
	xp=2,
        categories = { "Junk" },
	zones={ Forest=5, DeepForest=1, Vegitation=1, FarmLand=1, Farm=1, TrailerPark=5, TownZone=1},
	spawnFuncs = { doGenericItemSpawn }
};

local Blender ={
    type = "SapphCooking.Blender",
    minCount=1,
	maxCount=1,
    xp=2,
        categories = { "Junk" },
    zones={ Forest=1, DeepForest=1, Vegitation=1, FarmLand=1, Farm=1, TrailerPark=1, TownZone=1},
    spawnFuncs = { doGenericItemSpawn }
};


local TakeoutBox ={
    type = "SapphCooking.TakeoutBox",
    minCount=1,
	maxCount=1,
    xp=2,
        categories = { "Junk" },
    zones={ Forest=1, DeepForest=1, Vegitation=1, FarmLand=1, Farm=1, TrailerPark=1, TownZone=1},
    spawnFuncs = { doGenericItemSpawn }
};

local MRE ={
    type = "SapphCooking.MRE_Pack5",
    xp=2,
    minCount=1,
	maxCount=1,
        categories = { "Junk" },
    zones={ Forest=1, DeepForest=1, TrailerPark=1},
    spawnFuncs = { doGenericItemSpawn }
};
    
local Truffles = {
    type = "SapphCooking.Truffle",
    minCount=1,
    maxCount=4,
    skill = 4,
    xp = 5,
    snowChance = -30,
    categories = { "Vegetables" },
    zones = {Forest=1, DeepForest=1, Vegitation=1},
    months = { 3, 4, 5, 6, 7, 8, 9, 10},
    spawnFuncs = { doWildFoodSpawn, doRandomAgeSpawn}
};

local Sapph_WildBeets = {
    type = "SapphCooking.WildBeets",
    minCount=1,
    maxCount=4,
    skill = 4,
    xp = 5,
    snowChance = -30,
    categories = { "Vegetables" },
    zones = {Forest=2, DeepForest=4, Vegitation=2},
    months = { 3, 4, 5, 6, 7, 8, 9, 10},
    spawnFuncs = { doWildFoodSpawn, doRandomAgeSpawn}
};




forageSystem.addItemDef(Thermos);
forageSystem.addItemDef(Blender);
forageSystem.addItemDef(TakeoutBox);
forageSystem.addItemDef(MRE);

forageSystem.addItemDef(Truffles);
forageSystem.addItemDef(Sapph_WildBeets);

end);