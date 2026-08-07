--Ammo Maker by STIMP_TM

require 'recipecode'

--recipe on create recycle ammo

function Recipe.OnCreate.DisassembleAmmo(craftRecipeData, character)

	local ammoItemType = craftRecipeData:getAllConsumedItems():get(0):getModule() .. "." .. craftRecipeData:getAllConsumedItems():get(0):getType();
	
	local bulletType = ammoMakerGetBulletType(ammoItemType);
	local bulletCount = ammoMakerGetBulletCount(ammoItemType);
	local grainsAmount = ammoMakerGetGrainsAmount(ammoItemType);

	local grainsItems = math.floor(grainsAmount);
	local grainsUnits = grainsAmount - grainsItems;

	if grainsItems > 0 then

		character:getInventory():AddItems("ammomaker.ammomaker_GunPowderGrains", grainsItems);

	end

	if grainsUnits > 0 then

		local grains = instanceItem("ammomaker.ammomaker_GunPowderGrains", grainsUnits);
		character:getInventory():AddItem(grains);
	
	end

	if bulletCount > 1 then

		local balls = instanceItem("ammomaker.ammomaker_Balls00", ((bulletCount - 1) / 100));
		character:getInventory():AddItem(balls);

	end

end

--recipe on create items

function Recipe.OnCreate.ExtractNitre(craftRecipeData, character)

	local inputPot = craftRecipeData:getAllConsumedItems():get(0);
	local inputPotType = inputPot:getType();
	local inputPotCondition = inputPot:getCondition();
	local outputPot;

	if inputPotType == "ammomaker_PotOfBirdExcrement" then

		outputPot = instanceItem("Base.Pot");

	elseif inputPotType == "ammomaker_PotForgedOfBirdExcrement" then

		outputPot = instanceItem("Base.PotForged");

	end

	outputPot:setCondition(inputPotCondition);
	character:getInventory():AddItem(outputPot);

end

function Recipe.OnCreate.MakeBrassCatcher(craftRecipeData, character)

	--might need to be updated for multiplayer
	ISInventoryPage.renderDirty = true;

end

function Recipe.OnCreate.MakeBullets(craftRecipeData, character)

	local inputMold = craftRecipeData:getAllConsumedItems():get(0);
	local outputMold = craftRecipeData:getAllCreatedItems():get(craftRecipeData:getAllCreatedItems():size() - 1);

	if inputMold:getWorldItem() then

		ammoMakerWorldAddItemAtItemPos(outputMold, inputMold);

	end

	--might need to be updated for multiplayer
	ISInventoryPage.renderDirty = true;

end

function Recipe.OnCreate.MakeMoldBullets(craftRecipeData, character)

	local inputMold = craftRecipeData:getAllConsumedItems():get(0);
	local outputMold = craftRecipeData:getAllCreatedItems():get(0);

	if inputMold:getWorldItem() then

		ammoMakerWorldAddItemAtItemPos(outputMold, inputMold);

	end

	--might need to be updated for multiplayer
	ISInventoryPage.renderDirty = true;

end

function Recipe.OnCreate.RecyclePlastic(craftRecipeData, character)

	local itemType = craftRecipeData:getAllConsumedItems():get(0):getType();

	local plasticData = {
		["CatToy"]											= 1,
		["Comb"]											= 1,
		["Dice"]											= 1,
		["PokerChips"]										= 1,
		["Razor"]											= 1,
		["Toothbrush"]										= 1,
		["MeasuringTape"]									= 1,
		["Yoyo"]											= 1,
		["PonchoGarbageBag"]								= 1,
		["Skirt_Normal_Garbage"]							= 1,
		["Skirt_Long_Garbage"]								= 1,
		["Bleach"]											= 1,
		["Hat_DustMask"]									= 1,
		["MarkerBlack"]										= 1,
		["MarkerBlue"]										= 1,
		["MarkerGreen"]										= 1,
		["MarkerRed"]										= 1,
		["Disc_Retail"]										= 2,
		["Funnel"]											= 2,
		["TakeoutBox_Styrofoam"]							= 2,
		["DogChew"]											= 2,
		["CleaningLiquid2"]									= 2,
		["Cube"]											= 4,
		["VHS_Retail"]										= 4,
		["VHS_Home"]										= 4,
		["ToiletBrush"]										= 5,
		["Bag_FluteCase"]									= 9,
		["Bag_ProtectiveCase"]								= 9,
		["Bag_ProtectiveCase_Survivalist"]					= 9,
		["Bag_ProtectiveCase_Tools"]						= 9,
		["Bag_ProtectiveCaseBulky"]							= 9,
		["Bag_ProtectiveCaseBulky_Audio"]					= 9,
		["Bag_ProtectiveCaseBulky_HAMRadio1"]				= 9,
		["Bag_ProtectiveCaseBulky_SCBA"]					= 9,
		["Bag_ProtectiveCaseBulky_Survivalist"]				= 9,
		["Bag_ProtectiveCaseBulkyAmmo"]						= 9,
		["Bag_ProtectiveCaseBulkyAmmo_223"]					= 9,
		["Bag_ProtectiveCaseBulkyAmmo_308"]					= 9,
		["Bag_ProtectiveCaseBulkyAmmo_38"]					= 9,
		["Bag_ProtectiveCaseBulkyAmmo_44"]					= 9,
		["Bag_ProtectiveCaseBulkyAmmo_45"]					= 9,
		["Bag_ProtectiveCaseBulkyAmmo_556"]					= 9,
		["Bag_ProtectiveCaseBulkyAmmo_9mm"]					= 9,
		["Bag_ProtectiveCaseBulkyAmmo_Hunting"]				= 9,
		["Bag_ProtectiveCaseBulkyAmmo_ShotgunShells"]		= 9,
		["Bag_ProtectiveCaseBulkyHazard"]					= 9,
		["Bag_ProtectiveCaseBulkyMilitary"]					= 9,
		["Bag_ProtectiveCaseBulkyMilitary_HAMRadio2"]		= 9,
		["Bag_ProtectiveCaseMilitary"]						= 9,
		["Bag_ProtectiveCaseMilitary_Medical"]				= 9,
		["Bag_ProtectiveCaseMilitary_Tools"]				= 9,
		["Bag_ProtectiveCaseSmall"]							= 9,
		["Bag_ProtectiveCaseSmall_Armorer"]					= 9,
		["Bag_ProtectiveCaseSmall_Electronics"]				= 9,
		["Bag_ProtectiveCaseSmall_FirstAid"]				= 9,
		["Bag_ProtectiveCaseSmall_KeyCutting"]				= 9,
		["Bag_ProtectiveCaseSmall_Pistol1"]					= 9,
		["Bag_ProtectiveCaseSmall_Pistol2"]					= 9,
		["Bag_ProtectiveCaseSmall_Pistol3"]					= 9,
		["Bag_ProtectiveCaseSmall_Revolver1"]				= 9,
		["Bag_ProtectiveCaseSmall_Revolver2"]				= 9,
		["Bag_ProtectiveCaseSmall_Revolver3"]				= 9,
		["Bag_ProtectiveCaseSmall_Survivalist"]				= 9,
		["Bag_ProtectiveCaseSmall_WalkieTalkie"]			= 9,
		["Bag_ProtectiveCaseSmall_WalkieTalkiePolice"]		= 9,
		["Bag_ProtectiveCaseSmallMilitary"]					= 9,
		["Bag_ProtectiveCaseSmallMilitary_FirstAid"]		= 9,
		["Bag_ProtectiveCaseSmallMilitary_Pistol1"]			= 9,
		["Bag_ProtectiveCaseSmallMilitary_WalkieTalkie"]	= 9,
		["Bag_RifleCase"]									= 9,
		["Bag_RifleCase_Police"]							= 9,
		["Bag_RifleCase_Police2"]							= 9,
		["Bag_RifleCase_Police3"]							= 9,
		["Bag_RifleCaseGreen"]								= 9,
		["Bag_RifleCaseGreen2"]								= 9,
		["Bag_SaxophoneCase"]								= 9,
		["Bag_ShotgunCase_Police"]							= 9,
		["Bag_ShotgunCaseGreen"]							= 9,
		["Bag_TrumpetCase"]									= 9,
		["Bag_ViolinCase"]									= 9,
		["Lunchbox"]										= 9,
		["Lunchbox2"]										= 9,
		["Pipe"]											= 9,
		["PlasticTray"]										= 9,
		["RifleCase1"]										= 9,
		["RifleCase2"]										= 9,
		["RifleCase3"]										= 9,
		["RifleCase4"]										= 9,
		["ShotgunCase1"]									= 9,
		["ShotgunCase2"]									= 9,
		["CuttingBoardPlastic"]								= 9,
		["Cooler"]											= 14,
		["Cooler_Beer"]										= 14,
		["Cooler_Meat"]										= 14,
		["Cooler_Seafood"]									= 14,
		["Cooler_Soda"]										= 14,
		["Tacklebox"]										= 14,
		["PetrolCan"]										= 15,
		["ShinKneeGuard_L"]									= 19,
		["ShinKneeGuard_L_Baseball"]						= 19,
		["ShinKneeGuard_L_Baseball"]						= 19,
		["ShinKneeGuard_L_IceHockey"]						= 19,
		["ShinKneeGuard_L_Protective"]						= 19,
		["ShinKneeGuard_L_TINT"]							= 19,
		["ShinKneeGuard_R"]									= 19,
		["ShinKneeGuard_R_Baseball"]						= 19,
		["ShinKneeGuard_R_Baseball"]						= 19,
		["ShinKneeGuard_R_IceHockey"]						= 19,
		["ShinKneeGuard_R_Protective"]						= 19,
		["ShinKneeGuard_R_TINT"]							= 19,
	};

	if plasticData[itemType] then

		character:getInventory():AddItems("ammomaker.ammomaker_RecPlastic", plasticData[itemType]);

	end

end

function Recipe.OnCreate.MakeFilterPaper(craftRecipeData, character)

	local itemType = craftRecipeData:getAllConsumedItems():get(0):getType();

	local paperData = {
		["Notepad"]											= 1,
		["Notebook"]										= 9,
		["Journal"]											= 19,
	};

	if paperData[itemType] then

		character:getInventory():AddItems("ammomaker.ammomaker_FilterPaper", paperData[itemType]);

	end

end

function Recipe.OnCreate.RecycleJewelryChain(craftRecipeData, character)

	local itemType = craftRecipeData:getAllConsumedItems():get(0):getType();

	local jewelryChainData = {
		["Necklace_Gold"]									= 1,
		["Necklace_Silver"]									= 1,
		["Necklace_DogTag"]									= 1,
		["Necklace_GoldRuby"]								= 1,
		["Necklace_GoldDiamond"]							= 1,
		["Necklace_SilverSapphire"]							= 1,
		["Necklace_SilverCrucifix"]							= 1,
		["Necklace_SilverDiamond"]							= 1,
		["NecklaceLong_Gold"]								= 2,
		["NecklaceLong_Silver"]								= 2,
		["NecklaceLong_GoldDiamond"]						= 2,
		["NecklaceLong_SilverEmerald"]						= 2,
		["NecklaceLong_SilverSapphire"]						= 2,
		["Necklace_SilverSapphire"]							= 2,
		["Necklace_SilverCrucifix"]							= 2,
		["NecklaceLong_SilverDiamond"]						= 2,
	};

	if jewelryChainData[itemType] then

		character:getInventory():AddItems("ammomaker.ammomaker_JewelryChain", jewelryChainData[itemType]);

	end

end