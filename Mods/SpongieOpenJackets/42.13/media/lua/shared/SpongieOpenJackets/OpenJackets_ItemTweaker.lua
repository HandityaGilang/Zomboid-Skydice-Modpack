
-- this script has become a total mess but it somehow works


OpenJackets_ItemTweaker = {};

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

function OpenJackets_ItemTweaker.AdjustAllClothingData()	--on startup we run this function to modify every clothing item
	for k, v in pairs(ClothingDataToChange) do
		AdjustClothingOption(k, v.ClothingItemExtra, v.ClothingItemExtraOption)
	end
end

Events.OnGameBoot.Add(OpenJackets_ItemTweaker.AdjustAllClothingData)


--add our new clothing changes to the table
function OpenJackets_ItemTweaker.AddToClothingData(item, item2, contextMenu)
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

local function getTagString(item)
	local tags = item:getTags()

	local string = ""

	for i = 1, #tags, 1 do
		string = string .. ";" .. tags:get(i)
	end

	return string
end

--Automates the adding of two way items (Jacket_White <----> Jacket_WhiteOPEN)
function OpenJackets_ItemTweaker.AddNewExtraItem(originalItemName, newItemName, originalContextMenu, newContextMenu, resistanceModifier)
	local originalItem = ScriptManager.instance:getItem(originalItemName);
	local newItem = ScriptManager.instance:getItem(newItemName);
	if ((not originalItem) or (not newItem)) then return end;
	
	--add the new clothingextraitems to the table
	OpenJackets_ItemTweaker.AddToClothingData(originalItemName, newItemName, newContextMenu)
	OpenJackets_ItemTweaker.AddToClothingData(newItemName, originalItemName, originalContextMenu)
	
	--when you right click on the item while it is unequipped the default option will be "Wear" instead of something like "RollUp", you can change this after this function runs to whatever makes more sense for your item
	--Adjust(originalItemName, "clothingExtraSubmenu", "Wear");
	--Adjust(newItemName, "clothingExtraSubmenu", "Wear");
	
	-- --copy tags because im lazy
	-- newItem:DoParam("Tags = ".. getTagString(originalItem))

	if resistanceModifier then 
		-- modify resistance
		newItem:DoParam("Insulation = "..(originalItem:getInsulation()*resistanceModifier))
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
function OpenJackets_ItemTweaker.AddOpenShirt(jacket)
	local jacketOPEN = jacket .. "OPEN";
	
	OpenJackets_ItemTweaker.AddNewExtraItem(jacket, jacketOPEN, "CloseJacket", "OpenJacket",  0.75);
end

--Tuck pants
function OpenJackets_ItemTweaker.AddTuckedPants(pants)
	local pantsTUCK = pants .. "TUCK";
	
	OpenJackets_ItemTweaker.AddNewExtraItem(pants, pantsTUCK, "TuckOut", "TuckIn",  1);
end

--Tied sweater
function OpenJackets_ItemTweaker.AddTiedSweater(sweater)
	local sweaterTIED = sweater .. "TIED";
	
	OpenJackets_ItemTweaker.AddNewExtraItem(sweater, sweaterTIED, "Wear", "TieOnWaist",  1);
end
--Tied sweater
function OpenJackets_ItemTweaker.AddRolledAndTiedSweater(sweater)
	local sweaterROLL = sweater .. "ROLL";
	local sweaterTIED = sweater .. "TIED";
	
	OpenJackets_ItemTweaker.AddNewExtraItem(sweater, sweaterROLL, "RollDown", "RollUp",  1);
	
	OpenJackets_ItemTweaker.AddToClothingData(sweater, sweaterTIED, "TieOnWaist")
	OpenJackets_ItemTweaker.AddToClothingData(sweaterROLL, sweaterTIED, "TieOnWaist")
	
	OpenJackets_ItemTweaker.AddToClothingData(sweaterTIED, sweater, "Wear")
end


--Rolled shirt
function OpenJackets_ItemTweaker.AddRolledShirt(shirt)
	local shirtROLL = shirt .. "ROLL";
	
	OpenJackets_ItemTweaker.AddNewExtraItem(shirt, shirtROLL, "RollDown", "RollUp", 1);
end

--Open and rolled shirt
function OpenJackets_ItemTweaker.AddOpenAndRolledShirt(shirt)
	local shirtROLL = shirt .. "ROLL";
	local shirtOPEN = shirt .. "OPEN";
	local shirtOPENROLL = shirt .. "OPENROLL";
	
	--open should be first in list for consistency
	OpenJackets_ItemTweaker.AddNewExtraItem(shirt, shirtOPEN, "CloseJacket", "OpenJacket", 0.75);
	OpenJackets_ItemTweaker.AddNewExtraItem(shirtROLL, shirtOPENROLL, "CloseJacket", "OpenJacket", 1);
	
	OpenJackets_ItemTweaker.AddNewExtraItem(shirtOPEN, shirtOPENROLL, "RollDown", "RollUp", 1);
	OpenJackets_ItemTweaker.AddNewExtraItem(shirt, shirtROLL, "RollDown", "RollUp", 1);
	
end

--Open hoodies (default hoodie names dont match my format so hoodieUP and hoodieDOWN must be input manually)
function OpenJackets_ItemTweaker.AddOpenHoodie(hoodieUP, hoodieDOWN)
	local hoodieUPOPEN = hoodieUP .. "OPEN";
	local hoodieDOWNOPEN = hoodieDOWN .. "OPEN";
	
	OpenJackets_ItemTweaker.AddNewExtraItem(hoodieUP, hoodieUPOPEN, "CloseJacket", "OpenJacket", 0.75);
	OpenJackets_ItemTweaker.AddNewExtraItem(hoodieDOWN, hoodieDOWNOPEN, "CloseJacket", "OpenJacket", 0.75);
	
	OpenJackets_ItemTweaker.AddNewExtraItem(hoodieUP, hoodieDOWN, "UpHoodie", "DownHoodie", 1);
	OpenJackets_ItemTweaker.AddNewExtraItem(hoodieUPOPEN, hoodieDOWNOPEN, "UpHoodie", "DownHoodie", 1);
end

function OpenJackets_ItemTweaker.AddOpenAndTiedHoodie(hoodieUP, hoodieDOWN, hoodieTIED)
	OpenJackets_ItemTweaker.AddOpenHoodie(hoodieUP, hoodieDOWN)
	local hoodieUPOPEN = hoodieUP .. "OPEN";
	local hoodieDOWNOPEN = hoodieDOWN .. "OPEN";
	
	--all hoodies need to be able to turn into hoodie tied
	OpenJackets_ItemTweaker.AddToClothingData(hoodieUP, hoodieTIED, "TieOnWaist")
	OpenJackets_ItemTweaker.AddToClothingData(hoodieDOWN, hoodieTIED, "TieOnWaist")
	OpenJackets_ItemTweaker.AddToClothingData(hoodieUPOPEN, hoodieTIED, "TieOnWaist")
	OpenJackets_ItemTweaker.AddToClothingData(hoodieDOWNOPEN, hoodieTIED, "TieOnWaist")
	
	--hoodie tied should only turn back into hoodie down
	OpenJackets_ItemTweaker.AddToClothingData(hoodieTIED, hoodieDOWN, "Wear")
	
end

--Coveralls
function OpenJackets_ItemTweaker.AddOpenAndTiedCoveralls(coveralls)
	local coverallsOPEN = coveralls .. "OPEN";
	local coverallsTIED = coveralls .. "TIED";
	
	OpenJackets_ItemTweaker.AddNewExtraItem(coveralls, coverallsOPEN, "CloseJacket", "OpenJacket",  1);
	
	OpenJackets_ItemTweaker.AddToClothingData(coveralls, coverallsTIED, "TieOnWaist")
	OpenJackets_ItemTweaker.AddToClothingData(coverallsOPEN, coverallsTIED, "TieOnWaist")
	
	OpenJackets_ItemTweaker.AddToClothingData(coverallsTIED, coveralls, "Wear")
end


--Dungarees
function OpenJackets_ItemTweaker.AddUpAndDownDungarees(item)
	local itemDOWN = item .. "DOWN";
	
	OpenJackets_ItemTweaker.AddNewExtraItem(item, itemDOWN, "WearUp", "WearDown", 1);
end

return OpenJackets_ItemTweaker
