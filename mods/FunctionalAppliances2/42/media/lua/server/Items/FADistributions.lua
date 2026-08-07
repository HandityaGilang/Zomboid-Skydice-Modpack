require 'Items/SuburbsDistributions'
require "Items/ProceduralDistributions"
require "Vehicles/VehicleDistributions"

local FAKegSpawnChance = SandboxVars.FunctionalAppliances.BeerKegsChance; 
local FASyrupsSpawnChance = SandboxVars.FunctionalAppliances.SyrupsChance; 
local FATheatreSpawnChance = SandboxVars.FunctionalAppliances.FATheatreChance; 
local FAFreshTheatreSpawnChance = SandboxVars.FunctionalAppliances.FAFreshTheatreChance; 
local FAZombieItemsSpawn = SandboxVars.FunctionalAppliances.FAZombieItemsSpawn; 

if (FAKegSpawnChance == 6) then
	FAKegSpawnChance = 0;
end

if (FASyrupsSpawnChance == 6) then
	FASyrupsSpawnChance = 0;
end

if (FATheatreSpawnChance == 6) then
	FATheatreSpawnChance = 0;
end

if (FAFreshTheatreSpawnChance == 6) then
	FAFreshTheatreSpawnChance = 0;
end

if FAZombieItemsSpawn then
	table.insert(SuburbsDistributions["all"]["inventorymale"].items, "FunctionalAppliances.FABucketofButteredPopcorn");
	table.insert(SuburbsDistributions["all"]["inventorymale"].items, 0.01);
	table.insert(SuburbsDistributions["all"]["inventorymale"].items, "FunctionalAppliances.FABucketofPopcorn");
	table.insert(SuburbsDistributions["all"]["inventorymale"].items, 0.01);
	table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "FunctionalAppliances.FABucketofButteredPopcorn");
	table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, 0.01);
	table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "FunctionalAppliances.FABucketofPopcorn");
	table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, 0.01);
end

table.insert(ProceduralDistributions["list"]["CrateMagazines"].items, "FunctionalAppliances.FASodaJerkMagazine");
table.insert(ProceduralDistributions["list"]["CrateMagazines"].items, 0.05);
table.insert(ProceduralDistributions["list"]["DeskGeneric"].items, "FunctionalAppliances.FASodaJerkMagazine");
table.insert(ProceduralDistributions["list"]["DeskGeneric"].items, 0.0);
table.insert(ProceduralDistributions["list"]["MagazineRackMixed"].items, "FunctionalAppliances.FASodaJerkMagazine");
table.insert(ProceduralDistributions["list"]["MagazineRackMixed"].items, 0.025);
table.insert(ProceduralDistributions["list"]["PostOfficeMagazines"].items, "FunctionalAppliances.FASodaJerkMagazine");
table.insert(ProceduralDistributions["list"]["PostOfficeMagazines"].items, 0.025);
table.insert(ProceduralDistributions["list"]["BookstoreBooks"].items, "FunctionalAppliances.FASodaJerkMagazine");
table.insert(ProceduralDistributions["list"]["BookstoreBooks"].items, 5);
table.insert(ProceduralDistributions["list"]["LibraryBooks"].items, "FunctionalAppliances.FASodaJerkMagazine");
table.insert(ProceduralDistributions["list"]["LibraryBooks"].items, 5);
table.insert(ProceduralDistributions["list"]["PostOfficeMagazines"].items, "FunctionalAppliances.FASodaJerkMagazine");
table.insert(ProceduralDistributions["list"]["PostOfficeMagazines"].items, 0.25);

table.insert(ProceduralDistributions["list"]["TheatreKitchenFreezer"].items, "Base.Sausage");
table.insert(ProceduralDistributions["list"]["TheatreKitchenFreezer"].items, 20);
table.insert(ProceduralDistributions["list"]["TheatreKitchenFreezer"].items, "Base.Sausage");
table.insert(ProceduralDistributions["list"]["TheatreKitchenFreezer"].items, 10);
table.insert(ProceduralDistributions["list"]["TheatreKitchenFreezer"].items, "Base.BreadSlices");
table.insert(ProceduralDistributions["list"]["TheatreKitchenFreezer"].items, 10);
table.insert(ProceduralDistributions["list"]["TheatreKitchenFreezer"].items, "Base.Bread");
table.insert(ProceduralDistributions["list"]["TheatreKitchenFreezer"].items, 10);
table.insert(ProceduralDistributions["list"]["TheatreKitchenFreezer"].items, "Base.Butter");
table.insert(ProceduralDistributions["list"]["TheatreKitchenFreezer"].items, 10);

table.insert(ProceduralDistributions["list"]["TheatreSnacks"].items, "FunctionalAppliances.FABucketofPopcorn");
table.insert(ProceduralDistributions["list"]["TheatreSnacks"].items, 10);
table.insert(ProceduralDistributions["list"]["TheatreSnacks"].items, "FunctionalAppliances.FABucketofButteredPopcorn");
table.insert(ProceduralDistributions["list"]["TheatreSnacks"].items, 10);
table.insert(ProceduralDistributions["list"]["TheatreSnacks"].items, "FunctionalAppliances.FABucketofButteredPopcorn");
table.insert(ProceduralDistributions["list"]["TheatreSnacks"].items, 10);

table.insert(ProceduralDistributions["list"]["TheatrePopcorn"].items, "FunctionalAppliances.FABucketofPopcorn");
table.insert(ProceduralDistributions["list"]["TheatrePopcorn"].items, 10);
table.insert(ProceduralDistributions["list"]["TheatrePopcorn"].items, "FunctionalAppliances.FABucketofButteredPopcorn");
table.insert(ProceduralDistributions["list"]["TheatrePopcorn"].items, 10);
table.insert(ProceduralDistributions["list"]["TheatrePopcorn"].items, "Base.Butter");
table.insert(ProceduralDistributions["list"]["TheatrePopcorn"].items, 20);
table.insert(ProceduralDistributions["list"]["TheatrePopcorn"].items, "FunctionalAppliances.FAEmptyBucketPopcorn");
table.insert(ProceduralDistributions["list"]["TheatrePopcorn"].items, 10);

table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "FunctionalAppliances.FATheaterPopcorn");
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, 10);

table.insert(ProceduralDistributions["list"]["StoreCounterCleaning"].items, "Base.TinOpener");
table.insert(ProceduralDistributions["list"]["StoreCounterCleaning"].items, 10);

table.insert(ProceduralDistributions["list"]["GasStorageCombo"].items, "FunctionalAppliances.FAEmptySodaSyrupBox");
table.insert(ProceduralDistributions["list"]["GasStorageCombo"].items, 1);
table.insert(ProceduralDistributions["list"]["GasStorageCombo"].items, "FunctionalAppliances.EmptyFACO2Tank");
table.insert(ProceduralDistributions["list"]["GasStorageCombo"].items, 1);

table.insert(ProceduralDistributions["list"]["BarCounterGlasses"].items, "FunctionalAppliances.FABeerMug");
table.insert(ProceduralDistributions["list"]["BarCounterGlasses"].items, 10);
table.insert(ProceduralDistributions["list"]["BarCounterGlasses"].items, "FunctionalAppliances.FAEmptyKeg");
table.insert(ProceduralDistributions["list"]["BarCounterGlasses"].items, 0.5);

table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, "FunctionalAppliances.FAEmptyKeg");
table.insert(ProceduralDistributions["list"]["BarShelfLiquor"].items, 0.5);

table.insert(ProceduralDistributions["list"]["FridgeBeer"].items, "Base.Yeast");
table.insert(ProceduralDistributions["list"]["FridgeBeer"].items, 5);

table.insert(ProceduralDistributions["list"]["BandPracticeFridge"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["BandPracticeFridge"].items, 1);
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, 1);
table.insert(ProceduralDistributions["list"]["CafeDiningFridge"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["CafeDiningFridge"].items, 1);
table.insert(ProceduralDistributions["list"]["CafeteriaDrinks"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["CafeteriaDrinks"].items, 2);
table.insert(ProceduralDistributions["list"]["CrateEmptyMixed"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["CrateEmptyMixed"].items, 4);
table.insert(ProceduralDistributions["list"]["CrateSodaBottles"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["CrateSodaBottles"].items, 10);
table.insert(ProceduralDistributions["list"]["DerelictHouseParty"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["DerelictHouseParty"].items, 0.1);
table.insert(ProceduralDistributions["list"]["FridgeBottles"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["FridgeBottles"].items, 8);
table.insert(ProceduralDistributions["list"]["FridgeBreakRoom"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["FridgeBreakRoom"].items, 0.1);
table.insert(ProceduralDistributions["list"]["FridgeFarmStorage"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["FridgeFarmStorage"].items, 1);
table.insert(ProceduralDistributions["list"]["FridgeGarage"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["FridgeGarage"].items, 1);
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["FridgeGeneric"].items, 0.5);
table.insert(ProceduralDistributions["list"]["FridgeOffice"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["FridgeOffice"].items, 0.1);
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["FridgeRich"].items, 0.1);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, 4);
table.insert(ProceduralDistributions["list"]["FridgeTrailerPark"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["FridgeTrailerPark"].items, 0.05);
table.insert(ProceduralDistributions["list"]["GasStorageCombo"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["GasStorageCombo"].items, 0.1);
table.insert(ProceduralDistributions["list"]["GigamartBottles"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["GigamartBottles"].items, 2);
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["GroceryStorageCrate1"].items, 0.01);
table.insert(ProceduralDistributions["list"]["HospitalRoomFridge"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["HospitalRoomFridge"].items, 0.01);
table.insert(ProceduralDistributions["list"]["HotdogStandDrinks"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["HotdogStandDrinks"].items, 0.1);
table.insert(ProceduralDistributions["list"]["KitchenBottles"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["KitchenBottles"].items, 0.1);
table.insert(ProceduralDistributions["list"]["MotelFridge"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["MotelFridge"].items, 0.1);
table.insert(ProceduralDistributions["list"]["SafehouseFood"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["SafehouseFood"].items, 4);
table.insert(ProceduralDistributions["list"]["SafehouseFood_Mid"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["SafehouseFood_Mid"].items, 0.5);
table.insert(ProceduralDistributions["list"]["SafehouseFridge"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["SafehouseFridge"].items, 4);
table.insert(ProceduralDistributions["list"]["SafehouseFridge_Mid"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["SafehouseFridge_Mid"].items, 0.1);
table.insert(ProceduralDistributions["list"]["StoreShelfCombo"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["StoreShelfCombo"].items, 0.05);
table.insert(ProceduralDistributions["list"]["StoreShelfDrinks"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["StoreShelfDrinks"].items, 2);
table.insert(ProceduralDistributions["list"]["TheatreDrinks"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["TheatreDrinks"].items, 1);
table.insert(ProceduralDistributions["list"]["UniversityFridge"].items, "FunctionalAppliances.PopBottleFA");
table.insert(ProceduralDistributions["list"]["UniversityFridge"].items, 0.1);

table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, "FunctionalAppliances.SodaCanFA");
table.insert(ProceduralDistributions["list"]["BarCounterMisc"].items, 1);
table.insert(ProceduralDistributions["list"]["CafeteriaDrinks"].items, "FunctionalAppliances.SodaCanFA");
table.insert(ProceduralDistributions["list"]["CafeteriaDrinks"].items, 2);
table.insert(ProceduralDistributions["list"]["CrateSodaCans"].items, "FunctionalAppliances.SodaCanFA");
table.insert(ProceduralDistributions["list"]["CrateSodaCans"].items, 10);
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, "FunctionalAppliances.SodaCanFA");
table.insert(ProceduralDistributions["list"]["FridgeSoda"].items, 4);
table.insert(ProceduralDistributions["list"]["KitchenBottles"].items, "FunctionalAppliances.SodaCanFA");
table.insert(ProceduralDistributions["list"]["KitchenBottles"].items, 0.1);
table.insert(ProceduralDistributions["list"]["SafehouseFood"].items, "FunctionalAppliances.SodaCanFA");
table.insert(ProceduralDistributions["list"]["SafehouseFood"].items, 4);
table.insert(ProceduralDistributions["list"]["SafehouseFood_Mid"].items, "FunctionalAppliances.SodaCanFA");
table.insert(ProceduralDistributions["list"]["SafehouseFood_Mid"].items, 0.5);
table.insert(ProceduralDistributions["list"]["SafehouseFridge"].items, "FunctionalAppliances.SodaCanFA");
table.insert(ProceduralDistributions["list"]["SafehouseFridge"].items, 4);
table.insert(ProceduralDistributions["list"]["SafehouseFridge_Mid"].items, "FunctionalAppliances.SodaCanFA");
table.insert(ProceduralDistributions["list"]["SafehouseFridge_Mid"].items, 0.1);
table.insert(ProceduralDistributions["list"]["StoreShelfDrinks"].items, "FunctionalAppliances.SodaCanFA");
table.insert(ProceduralDistributions["list"]["StoreShelfDrinks"].items, 2);
table.insert(ProceduralDistributions["list"]["TheatreDrinks"].items, "FunctionalAppliances.SodaCanFA");
table.insert(ProceduralDistributions["list"]["TheatreDrinks"].items, 1);

local FABaseCandyList = {
	"Base.Chocolate",
	"Base.CandyPackage",
	"Base.HardCandies",
	"Base.LicoriceRed",
	"Base.LicoriceBlack",
	"Base.GummyBears",
	"Base.Modjeska",
	"Base.Jujubes",
	"Base.ChocolateCoveredCoffeeBeans",
	"Base.GummyWorms",
}

local FAPopcornList = {
	"FunctionalAppliances.FABucketofButteredPopcorn",
	"FunctionalAppliances.FABucketofPopcorn",
	"Base.Butter",
	"Base.Popcorn",
	"FunctionalAppliances.FAEmptyBucketPopcorn",
}

local FAFreshList = {
	"Base.Butter",
	"Base.Hotdog",
	"Base.Sausage",
	"Base.Hotdog_single",
	"Base.HotdogPack",
	"Base.BunsHotdog",
	"Base.BunsHotdog_single",
	"Base.BreadSlices",
}

local FABarTapsKegsList = {
	"FunctionalAppliances.FABubKeg",
	"FunctionalAppliances.FABubLiteKeg",
	"FunctionalAppliances.FASwillerKeg",
	"FunctionalAppliances.FASwillerLiteKeg",
	"FunctionalAppliances.FAHomeBrewKeg",
}

local FASodaFountainSyrupsList = {
	"FunctionalAppliances.FAMixedBerriesSodaSyrupBox",
	"FunctionalAppliances.FAOrangeSodaSyrupBox",
	"FunctionalAppliances.FALemonLimeSodaSyrupBox",
	"FunctionalAppliances.FARootBeerSodaSyrupBox",
	"FunctionalAppliances.FAKYColaSodaSyrupBox",
	"FunctionalAppliances.FAColaSodaSyrupBox",
	"FunctionalAppliances.FADietColaSodaSyrupBox",
	"FunctionalAppliances.FAGingerAleSodaSyrupBox",
	"FunctionalAppliances.FABlueberrySodaSyrupBox",
	"FunctionalAppliances.FABubblegumSodaSyrupBox",
	"FunctionalAppliances.FALimeSodaSyrupBox",
	"FunctionalAppliances.FAGrapeSodaSyrupBox",
	"FunctionalAppliances.FAPineappleSodaSyrupBox",
	"FunctionalAppliances.FAStrawberrySodaSyrupBox",
	"FunctionalAppliances.FADrPeppaSodaSyrupBox",
}

local FATheatrespawns = {
	theatrestorage = {shelves=60,crate=60,counter=60,fridge=60},
    	theatre = {counter=60,fridge=60,crate=60,freezer=60},
   	theatrekitchen = {counter=60,crate=60,fridge=60,metal_shelves=60}
}

local FABarTapsspawns = {
	bar = {counter=80},
	restaurant = {counter=80},
	kitchen = {counter=80}
}

local FASyrupsspawns = {
	zippeestore = {counter=80, slurpNBurp=100},
	theatrestorage = {counter=80, slurpNBurp=100},
    	theatre = {counter=80, slurpNBurp=100},
  	theatrekitchen = {counter=80, slurpNBurp=100},
	spiffo_dining = {counter=80, slurpNBurp=100},
    	spiffoskitchen = {counter=80, slurpNBurp=100},
	gasstore = {counter=80, slurpNBurp=100},
	restaurant = {counter=80, slurpNBurp=100},
	bar = {counter=80, slurpNBurp=100},
	kitchen = {counter=80, slurpNBurp=100}
}

FA = FA or {}

FA.ApplySpawnChance = function(value)
	if ZombRand(100)+1 >= (100 - value) then
		return true
	else
		return false
	end
end

FA.PickOne = function(index)
	return ZombRand(index)+1
end

FA.depleteSpawnedKeg = function(keg)
	if not keg or not keg.getUseDelta or keg:getUseDelta() == nil then
		return
	end

	local filledAmount = SandboxVars.FunctionalAppliances.BeerKegsFilledAmount
	local randomNumb = 0

	if filledAmount == 6 then
		randomNumb = ZombRand(2,48)
	elseif filledAmount == 5 then
		randomNumb = 48
	elseif filledAmount == 4 then
		randomNumb = ZombRand(30,47)
	elseif filledAmount == 3 then
		randomNumb = ZombRand(20,32)
	elseif filledAmount == 2 then
		randomNumb = ZombRand(10,22)
	elseif filledAmount == 1 then
		randomNumb = ZombRand(2,12)
	end

	local kegDelta = keg:getUseDelta()
	local newWeightAmount = 2 + (randomNumb * 0.375)

	keg:setCurrentUsesFloat(randomNumb * kegDelta)
	keg:setCustomWeight(true)
	keg:setActualWeight(newWeightAmount)
end	

FA.depleteSpawnedTank = function(tank)
	if not tank or not tank.getUseDelta or tank:getUseDelta() == nil then
		return
	end

	local filledAmount = SandboxVars.FunctionalAppliances.SyrupsFilledAmount
	local randomNumb = 0

	if filledAmount == 6 then
		randomNumb = ZombRand(2,100)
	elseif filledAmount == 5 then
		randomNumb = 100
	elseif filledAmount == 4 then
		randomNumb = ZombRand(73,98)
	elseif filledAmount == 3 then
		randomNumb = ZombRand(48,77)
	elseif filledAmount == 2 then
		randomNumb = ZombRand(23,52)
	elseif filledAmount == 1 then
		randomNumb = ZombRand(2,27)
	end

	local tankDelta = tank:getUseDelta()
	local newWeightAmount = 5 + (randomNumb * 0.05)

	tank:setCurrentUsesFloat(randomNumb * tankDelta)
	tank:setCustomWeight(true)
	tank:setActualWeight(newWeightAmount)
end

FA.depleteSpawnedSyrup = function(syrup)
	if not syrup or not syrup.getUseDelta or syrup:getUseDelta() == nil then
		return
	end

	local filledAmount = SandboxVars.FunctionalAppliances.SyrupsFilledAmount
	local randomNumb = 0

	if filledAmount == 6 then
		randomNumb = ZombRand(2,48)
	elseif filledAmount == 5 then
		randomNumb = 48
	elseif filledAmount == 4 then
		randomNumb = ZombRand(30,47)
	elseif filledAmount == 3 then
		randomNumb = ZombRand(20,32)
	elseif filledAmount == 2 then
		randomNumb = ZombRand(10,22)
	elseif filledAmount == 1 then
		randomNumb = ZombRand(2,12)
	end

	local syrupDelta = syrup:getUseDelta()
	local newWeightAmount = 1 + (randomNumb * 0.1875)

	syrup:setCurrentUsesFloat(randomNumb * syrupDelta)
	syrup:setCustomWeight(true)
	syrup:setActualWeight(newWeightAmount)
end

local function FASpawn(roomName, containerType, containerFilled)
	if FATheatrespawns[roomName] == nil and FABarTapsspawns[roomName] == nil and FASyrupsspawns[roomName] == nil then
		return
	end

	local RollRand = 0
	
	if FATheatrespawns[roomName] ~= nil and FATheatrespawns[roomName][containerType] ~= nil then
		if FA.ApplySpawnChance(FATheatrespawns[roomName][containerType]) then
			if containerType == "fridge" then
				RollRand = ZombRand(1,100)+(FAFreshTheatreSpawnChance*10)
				if RollRand >= 101 then
					containerFilled:AddItem(FAFreshList[FA.PickOne(#FAFreshList)])
					if RollRand >= 121 then
						containerFilled:AddItem(FAFreshList[FA.PickOne(#FAFreshList)])
						if RollRand >= 131 then
							containerFilled:AddItem(FAFreshList[FA.PickOne(#FAFreshList)])
						end
					end
				end
			else
				RollRand = ZombRand(1,100)+(FAFreshTheatreSpawnChance*10)
				if RollRand >= 101 then
					containerFilled:AddItem(FAFreshList[FA.PickOne(#FAFreshList)])
					if RollRand >= 121 then
						containerFilled:AddItem(FAFreshList[FA.PickOne(#FAFreshList)])
					end
				end
				RollRand = ZombRand(1,100)+(FATheatreSpawnChance*10)
				if RollRand >= 101 then
					containerFilled:AddItem(FAPopcornList[FA.PickOne(#FAPopcornList)])
					if RollRand >= 121 then
						containerFilled:AddItem(FAPopcornList[FA.PickOne(#FAPopcornList)])
						if RollRand >= 131 then
							containerFilled:AddItem(FAPopcornList[FA.PickOne(#FAPopcornList)])
						end
					end
				end
				RollRand = ZombRand(1,100)+(FATheatreSpawnChance*10)
				if RollRand >= 101 then
					containerFilled:AddItem(FABaseCandyList[FA.PickOne(#FABaseCandyList)])
					if RollRand >= 121 then
						containerFilled:AddItem(FABaseCandyList[FA.PickOne(#FABaseCandyList)])
						if RollRand >= 131 then
							containerFilled:AddItem(FABaseCandyList[FA.PickOne(#FABaseCandyList)])
						end
					end
				end
			end

		end
	end

	if FABarTapsspawns[roomName] ~= nil and FABarTapsspawns[roomName][containerType] ~= nil then
		if FA.ApplySpawnChance(FABarTapsspawns[roomName][containerType]) then
			local BarTapsObject = nil
			local square = containerFilled:getParent():getSquare()
			for i=1,square:getObjects():size() do
				local thisObject = square:getObjects():get(i-1)
				if thisObject:getSprite() then
					local properties = thisObject:getSprite():getProperties()
					local spr = thisObject:getSprite():getName()  
					local groupName = nil
					if properties ~= nil then
						if properties:Is("GroupName") then
							groupName = properties:Val("GroupName")
						end				
						if groupName == "Bar Tap" then				
							BarTapsObject = thisObject
							break
						end
					end
				end
			end
			if BarTapsObject ~= nil then
				RollRand = ZombRand(1,100)+(FAKegSpawnChance*20)
				if RollRand >= 101 then
					local keg1 = containerFilled:AddItem(FABarTapsKegsList[FA.PickOne(#FABarTapsKegsList)])
					FA.depleteSpawnedKeg(keg1)
					if RollRand >= 121 then
						local keg2 = containerFilled:AddItem(FABarTapsKegsList[FA.PickOne(#FABarTapsKegsList)])
						FA.depleteSpawnedKeg(keg2)
						if RollRand >= 131 then
							local keg3 = containerFilled:AddItem(FABarTapsKegsList[FA.PickOne(#FABarTapsKegsList)])
							FA.depleteSpawnedKeg(keg3)
							if RollRand >= 141 then
								local keg4 = containerFilled:AddItem(FABarTapsKegsList[FA.PickOne(#FABarTapsKegsList)])
								FA.depleteSpawnedKeg(keg4)
							end
						end
					end
				end
			end
		end
	end

	if FASyrupsspawns[roomName] ~= nil and FASyrupsspawns[roomName][containerType] ~= nil then
		if FA.ApplySpawnChance(FASyrupsspawns[roomName][containerType]) then
			local SodaFountainObject = nil
			local square = containerFilled:getParent():getSquare()
			for i=1,square:getObjects():size() do
				local thisObject = square:getObjects():get(i-1)
				if thisObject:getSprite() then
					local properties = thisObject:getSprite():getProperties()
					local spr = thisObject:getSprite():getName()  
					local groupName = nil
					if properties ~= nil then
						if properties:Is("GroupName") then
							groupName = properties:Val("GroupName")
						end				
						if groupName == "Tabletop Soda" then				
							SodaFountainObject = thisObject
							break
						end
					end
				end
			end
			if SodaFountainObject ~= nil or containerType == "slurpNBurp" then
				RollRand = ZombRand(1,100)+(FASyrupsSpawnChance*20)
				if RollRand >= 101 or (containerType == "slurpNBurp" and FASyrupsSpawnChance > 0) then
					local addItem1 = containerFilled:AddItem(FASodaFountainSyrupsList[FA.PickOne(#FASodaFountainSyrupsList)])
					FA.depleteSpawnedSyrup(addItem1)
					local addItem2 = containerFilled:AddItem("FunctionalAppliances.FACO2Tank")
					FA.depleteSpawnedTank(addItem2)
					if RollRand >= 121 then
						local addItem3 = containerFilled:AddItem(FASodaFountainSyrupsList[FA.PickOne(#FASodaFountainSyrupsList)])
						FA.depleteSpawnedSyrup(addItem3)
						if RollRand >= 131 then
							local addItem4 = containerFilled:AddItem(FASodaFountainSyrupsList[FA.PickOne(#FASodaFountainSyrupsList)])
							FA.depleteSpawnedSyrup(addItem4)
							if RollRand >= 141 then
								local addItem5 = containerFilled:AddItem(FASodaFountainSyrupsList[FA.PickOne(#FASodaFountainSyrupsList)])
								FA.depleteSpawnedSyrup(addItem5)
							end
						end
					end
				end
			end
		end
	end
end

Events.OnFillContainer.Add(FASpawn)