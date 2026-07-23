
-- this script has become a total mess but it somehow works


SpongieOpenJackets = {};

local function Adjust(Name, Property, Value)
    local Item = ScriptManager.instance:getItem(Name)
    if Item then
        Item:DoParam(Property.." = " .. Value)
    end
end

local function AdjustClothingOption(Name, ClothingItemExtra, ClothingItemExtraOption)
	Adjust(Name, "ClothingItemExtra", ClothingItemExtra)
	Adjust(Name, "ClothingItemExtraOption", ClothingItemExtraOption)
	Adjust(Name, "clothingExtraSubmenu", "Wear");
end


--	Have to make a table of modified clothing items and adjust them at startup to avoid other mods potentially overwriting stuff (aka if Simix's Untucked Shirts were to add an untucked version of a rolled shirt)
local ClothingDataToChange = {};

function SpongieOpenJackets.AdjustAllClothingData()	--on startup we run this function to modify every clothing item
	for k, v in pairs(ClothingDataToChange) do
		AdjustClothingOption(k, v.ClothingItemExtra, v.ClothingItemExtraOption)
	end
end

Events.OnGameBoot.Add(SpongieOpenJackets.AdjustAllClothingData)


--add our new clothing changes to the table
function SpongieOpenJackets.AddToClothingData(item, item2, contextMenu)
	if ClothingDataToChange[item] == nil then ClothingDataToChange[item] = {ClothingItemExtra = "", ClothingItemExtraOption = ""} end	--add the item to the table if it isnt already there
	
	--add the new clothing item
	local tempString = ""	--create a blank string so that ; can be added before the item name if needed
	if ClothingDataToChange[item].ClothingItemExtra ~= "" then
		tempString = ClothingDataToChange[item].ClothingItemExtra..";"	--if there is already a clothingextraitem then they must be separated by a ;	have to do all this because having ; at the start or end of the parameter will cause errors (i think?)
	end
	tempString = tempString..item2 --if there was already a table entry then the item name will be added onto the ; like ";Jacket_White", otherwise it will just be "Jacket_White"
	ClothingDataToChange[item].ClothingItemExtra = tempString
	
	--add the context menu
	tempString = ""
	if ClothingDataToChange[item].ClothingItemExtraOption ~= "" then
		tempString = ClothingDataToChange[item].ClothingItemExtraOption..";"
	end
	tempString = tempString..contextMenu
	ClothingDataToChange[item].ClothingItemExtraOption = tempString
	
end


--Automates the adding of two way items (Jacket_White <----> Jacket_WhiteOPEN)
function SpongieOpenJackets.AddNewExtraItem(originalItemName, newItemName, originalContextMenu, newContextMenu, resistanceModifier)
	local originalItem = ScriptManager.instance:getItem(originalItemName);
	local newItem = ScriptManager.instance:getItem(newItemName);
	if ((not originalItem) or (not newItem)) then return end;
	
	--add the new clothingextraitems to the table
	SpongieOpenJackets.AddToClothingData(originalItemName, newItemName, newContextMenu)
	SpongieOpenJackets.AddToClothingData(newItemName, originalItemName, originalContextMenu)
	
	--when you right click on the item while it is unequipped the default option will be "Wear" instead of something like "RollUp", you can change this after this function runs to whatever makes more sense for your item
	--Adjust(originalItemName, "clothingExtraSubmenu", "Wear");
	--Adjust(newItemName, "clothingExtraSubmenu", "Wear");
	
	
	if resistanceModifier then 
		-- modify resistance
		newItem:DoParam("Insulation = "..(originalItem:getInsulation()*resistanceModifier)) --copy the original item's weather protection values and multiply them by a modifier so that i dont have to manually change them in every single item script
		newItem:DoParam("WindResistance = "..(originalItem:getWindresist()*resistanceModifier))
		newItem:DoParam("WaterResistance = "..(originalItem:getWaterresist()*resistanceModifier))
	end;
end

-- EXAMPLE OF HOW TO USE THIS FUNCTION
--SpongieOpenJackets.AddNewExtraItem("Jacket_White", "Jacket_WhiteOPEN", "CloseJacket", "OpenJacket", 0.75);

--if you dont want a resistance modifier then set it to 1 or leave it blank




-- ITEM PRESET FUNCTIONS
--			clothing variants must have item names matching the formats in these functions otherwise they wont work

--Open jacket or shirt
function SpongieOpenJackets.AddOpenJacketOrShirt(jacket)
	jacketOPEN = jacket .. "OPEN";
	
	SpongieOpenJackets.AddNewExtraItem(jacket, jacketOPEN, "CloseJacket", "OpenJacket",  0.75);
end

--Tuck pants
function SpongieOpenJackets.AddTuckedPants(pants)
	pantsTUCK = pants .. "TUCK";
	
	SpongieOpenJackets.AddNewExtraItem(pants, pantsTUCK, "TuckOut", "TuckIn",  1);
end

--Tied sweater
function SpongieOpenJackets.AddTiedSweater(sweater)
	sweaterTIED = sweater .. "TIED";
	
	SpongieOpenJackets.AddNewExtraItem(sweater, sweaterTIED, "Wear", "TieOnWaist",  1);
end
--Tied sweater
function SpongieOpenJackets.AddRolledAndTiedSweater(sweater)
	sweaterROLL = sweater .. "ROLL";
	sweaterTIED = sweater .. "TIED";
	
	SpongieOpenJackets.AddNewExtraItem(sweater, sweaterROLL, "RollDown", "RollUp",  1);
	
	SpongieOpenJackets.AddToClothingData(sweater, sweaterTIED, "TieOnWaist")
	SpongieOpenJackets.AddToClothingData(sweaterROLL, sweaterTIED, "TieOnWaist")
	
	SpongieOpenJackets.AddToClothingData(sweaterTIED, sweater, "Wear")
end


--Rolled shirt
function SpongieOpenJackets.AddRolledShirt(shirt)
	shirtROLL = shirt .. "ROLL";
	
	SpongieOpenJackets.AddNewExtraItem(shirt, shirtROLL, "RollDown", "RollUp", 1);
end

--Open and rolled shirt
function SpongieOpenJackets.AddOpenAndRolledShirt(shirt)
	shirtROLL = shirt .. "ROLL";
	shirtOPEN = shirt .. "OPEN";
	shirtOPENROLL = shirt .. "OPENROLL";
	
	--open should be first in list for consistency
	SpongieOpenJackets.AddNewExtraItem(shirt, shirtOPEN, "CloseJacket", "OpenJacket", 0.75);
	SpongieOpenJackets.AddNewExtraItem(shirtROLL, shirtOPENROLL, "CloseJacket", "OpenJacket", 1);
	
	SpongieOpenJackets.AddNewExtraItem(shirtOPEN, shirtOPENROLL, "RollDown", "RollUp", 1);
	SpongieOpenJackets.AddNewExtraItem(shirt, shirtROLL, "RollDown", "RollUp", 1);
	
end

--Open hoodies (default hoodie names dont match my format so hoodieUP and hoodieDOWN must be input manually)
function SpongieOpenJackets.AddOpenHoodie(hoodieUP, hoodieDOWN)
	hoodieUPOPEN = hoodieUP .. "OPEN";
	hoodieDOWNOPEN = hoodieDOWN .. "OPEN";
	
	SpongieOpenJackets.AddNewExtraItem(hoodieUP, hoodieUPOPEN, "CloseJacket", "OpenJacket", 0.75);
	SpongieOpenJackets.AddNewExtraItem(hoodieDOWN, hoodieDOWNOPEN, "CloseJacket", "OpenJacket", 0.75);
	
	SpongieOpenJackets.AddNewExtraItem(hoodieUP, hoodieDOWN, "UpHoodie", "DownHoodie", 1);
	SpongieOpenJackets.AddNewExtraItem(hoodieUPOPEN, hoodieDOWNOPEN, "UpHoodie", "DownHoodie", 1);
end

function SpongieOpenJackets.AddOpenAndTiedHoodie(hoodieUP, hoodieDOWN, hoodieTIED)
	hoodieUPOPEN = hoodieUP .. "OPEN";
	hoodieDOWNOPEN = hoodieDOWN .. "OPEN";
	
	--all hoodies need to be able to turn into hoodie tied
	SpongieOpenJackets.AddToClothingData(hoodieUP, hoodieTIED, "TieOnWaist")
	SpongieOpenJackets.AddToClothingData(hoodieDOWN, hoodieTIED, "TieOnWaist")
	SpongieOpenJackets.AddToClothingData(hoodieUPOPEN, hoodieTIED, "TieOnWaist")
	SpongieOpenJackets.AddToClothingData(hoodieDOWNOPEN, hoodieTIED, "TieOnWaist")
	
	--hoodie tied should only turn back into hoodie down
	SpongieOpenJackets.AddToClothingData(hoodieTIED, hoodieDOWN, "Wear")
	
end

--Coveralls
function SpongieOpenJackets.AddOpenAndTiedCoveralls(coveralls)
	coverallsOPEN = coveralls .. "OPEN";
	coverallsTIED = coveralls .. "TIED";
	
	SpongieOpenJackets.AddNewExtraItem(coveralls, coverallsOPEN, "CloseJacket", "OpenJacket",  1);
	
	SpongieOpenJackets.AddToClothingData(coveralls, coverallsTIED, "TieOnWaist")
	SpongieOpenJackets.AddToClothingData(coverallsOPEN, coverallsTIED, "TieOnWaist")
	
	SpongieOpenJackets.AddToClothingData(coverallsTIED, coveralls, "Wear")
end


-- hoodie
SpongieOpenJackets.AddOpenHoodie("HoodieUP_WhiteTINT", "HoodieDOWN_WhiteTINT");
--hoodie tied around waist
SpongieOpenJackets.AddOpenAndTiedHoodie("HoodieUP_WhiteTINT", "HoodieDOWN_WhiteTINT", "Hoodie_WhiteTINTTIED");


-- jackets

--Messed up the name of the open variant so this is here to convert existing versions of this item into the updated one to avoid breaking saves
SpongieOpenJackets.AddToClothingData("Jacket_WhiteOPEN", "Jacket_WhiteTINT", "CloseJacket");


SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_WhiteTINT");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_NavyBlue");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_Fireman");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_Chef");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_ArmyCamoDesert");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_ArmyCamoGreen");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_CoatArmy");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_Police");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_Ranger");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_Varsity");
SpongieOpenJackets.AddOpenAndRolledShirt("JacketLong_Doctor");
SpongieOpenJackets.AddOpenAndRolledShirt("JacketLong_Random");
SpongieOpenJackets.AddOpenAndRolledShirt("JacketLong_Santa");
SpongieOpenJackets.AddOpenAndRolledShirt("JacketLong_SantaGreen");

SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_Black");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_LeatherWildRacoons");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_LeatherIronRodent");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_LeatherBarrelDogs");

SpongieOpenJackets.AddOpenAndRolledShirt("WeddingJacket");
SpongieOpenJackets.AddOpenAndRolledShirt("Suit_Jacket");
SpongieOpenJackets.AddOpenAndRolledShirt("Suit_JacketTINT");

SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_Shellsuit_Black");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_Shellsuit_Blue");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_Shellsuit_Green");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_Shellsuit_Pink");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_Shellsuit_Teal");
SpongieOpenJackets.AddOpenAndRolledShirt("Jacket_Shellsuit_TINT");



SpongieOpenJackets.AddOpenJacketOrShirt("Jacket_BlackVest");
SpongieOpenJackets.AddOpenJacketOrShirt("Jacket_LeatherWildRacoonsVest");
SpongieOpenJackets.AddOpenJacketOrShirt("Jacket_LeatherIronRodentVest");
SpongieOpenJackets.AddOpenJacketOrShirt("Jacket_LeatherBarrelDogsVest");


--boiler suit
SpongieOpenJackets.AddOpenAndTiedCoveralls("Boilersuit");
SpongieOpenJackets.AddOpenAndTiedCoveralls("Boilersuit_BlueRed");
SpongieOpenJackets.AddOpenAndTiedCoveralls("Boilersuit_Yellow");
SpongieOpenJackets.AddOpenAndTiedCoveralls("Boilersuit_Flying");
SpongieOpenJackets.AddOpenAndTiedCoveralls("Boilersuit_Prisoner");
SpongieOpenJackets.AddOpenAndTiedCoveralls("Boilersuit_PrisonerKhaki");


-- trousers
SpongieOpenJackets.AddTuckedPants("Trousers");
SpongieOpenJackets.AddTuckedPants("TrousersMesh_DenimLight");
SpongieOpenJackets.AddTuckedPants("Trousers_LeatherBlack");
SpongieOpenJackets.AddTuckedPants("Trousers_CamoDesert");
SpongieOpenJackets.AddTuckedPants("Trousers_CamoGreen");
SpongieOpenJackets.AddTuckedPants("Trousers_CamoUrban");
SpongieOpenJackets.AddTuckedPants("Trousers_Chef");
SpongieOpenJackets.AddTuckedPants("Trousers_Denim");
SpongieOpenJackets.AddTuckedPants("Trousers_Fireman");
SpongieOpenJackets.AddTuckedPants("Trousers_JeanBaggy");
SpongieOpenJackets.AddTuckedPants("Trousers_Padded");
SpongieOpenJackets.AddTuckedPants("Trousers_Police");
SpongieOpenJackets.AddTuckedPants("Trousers_PoliceGrey");
SpongieOpenJackets.AddTuckedPants("Trousers_PrisonGuard");
SpongieOpenJackets.AddTuckedPants("Trousers_Ranger");
SpongieOpenJackets.AddTuckedPants("Trousers_Scrubs");
SpongieOpenJackets.AddTuckedPants("Trousers_Suit");
SpongieOpenJackets.AddTuckedPants("Trousers_SuitWhite");
SpongieOpenJackets.AddTuckedPants("Trousers_WhiteTINT");
SpongieOpenJackets.AddTuckedPants("Trousers_ArmyService");
SpongieOpenJackets.AddTuckedPants("Trousers_Black");
SpongieOpenJackets.AddTuckedPants("Trousers_NavyBlue");


-- shirts
SpongieOpenJackets.AddOpenJacketOrShirt("Shirt_Bowling_Blue");
SpongieOpenJackets.AddOpenJacketOrShirt("Shirt_Bowling_Brown");
SpongieOpenJackets.AddOpenJacketOrShirt("Shirt_Bowling_Green");
SpongieOpenJackets.AddOpenJacketOrShirt("Shirt_Bowling_LimeGreen");
SpongieOpenJackets.AddOpenJacketOrShirt("Shirt_Bowling_Pink");
SpongieOpenJackets.AddOpenJacketOrShirt("Shirt_Bowling_White");
SpongieOpenJackets.AddOpenJacketOrShirt("Shirt_Baseball_KY");
SpongieOpenJackets.AddOpenJacketOrShirt("Shirt_Baseball_Rangers");
SpongieOpenJackets.AddOpenJacketOrShirt("Shirt_Baseball_Z");
SpongieOpenJackets.AddOpenJacketOrShirt("Shirt_FormalWhite_ShortSleeve");
SpongieOpenJackets.AddOpenJacketOrShirt("Shirt_FormalWhite_ShortSleeveTINT");
SpongieOpenJackets.AddOpenJacketOrShirt("Shirt_HawaiianRed");
SpongieOpenJackets.AddOpenJacketOrShirt("Shirt_HawaiianTINT");
SpongieOpenJackets.AddOpenJacketOrShirt("Shirt_HawaiianRed");
SpongieOpenJackets.AddOpenJacketOrShirt("Tshirt_PoliceBlue");
SpongieOpenJackets.AddOpenJacketOrShirt("Tshirt_PoliceGrey");
SpongieOpenJackets.AddOpenJacketOrShirt("Tshirt_Ranger");


SpongieOpenJackets.AddRolledShirt("Tshirt_WhiteLongSleeve");
SpongieOpenJackets.AddRolledShirt("Tshirt_WhiteLongSleeveTINT");
SpongieOpenJackets.AddRolledShirt("Shirt_Scrubs");


SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_CamoUrban");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_CamoDesert");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_CamoGreen");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_Denim");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_Lumberjack");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_OfficerWhite");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_PoliceBlue");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_PoliceGrey");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_PrisonGuard");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_Priest");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_Ranger");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_FormalTINT");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_FormalWhite");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_Workman");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_Jockey01");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_Jockey02");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_Jockey03");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_Jockey04");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_Jockey05");
SpongieOpenJackets.AddOpenAndRolledShirt("Shirt_Jockey06");


-- sweaters
SpongieOpenJackets.AddRolledAndTiedSweater("Jumper_DiamondPatternTINT")
SpongieOpenJackets.AddRolledAndTiedSweater("Jumper_PoloNeck");
SpongieOpenJackets.AddRolledAndTiedSweater("Jumper_RoundNeck");
SpongieOpenJackets.AddRolledAndTiedSweater("Jumper_VNeck");



-- shirt ripped
SpongieOpenJackets.AddOpenJacketOrShirt("Shirt_DenimVest");
SpongieOpenJackets.AddOpenJacketOrShirt("Shirt_LumberjackVest");


SpongieOpenJackets.AddOpenJacketOrShirt("Vest_HighViz");
SpongieOpenJackets.AddOpenJacketOrShirt("Vest_Foreman");
SpongieOpenJackets.AddOpenJacketOrShirt("Vest_Hunting_CamoGreen");
SpongieOpenJackets.AddOpenJacketOrShirt("Vest_Hunting_Camo");
SpongieOpenJackets.AddOpenJacketOrShirt("Vest_Hunting_Orange");
SpongieOpenJackets.AddOpenJacketOrShirt("Vest_Hunting_Grey");
SpongieOpenJackets.AddOpenJacketOrShirt("Vest_Waistcoat_GigaMart");
SpongieOpenJackets.AddOpenJacketOrShirt("Vest_WaistcoatTINT");
SpongieOpenJackets.AddOpenJacketOrShirt("Vest_Waistcoat");


SpongieOpenJackets.AddNewExtraItem("Dungarees", "DungareesDOWN", "WearUp", "WearDown", 1);
