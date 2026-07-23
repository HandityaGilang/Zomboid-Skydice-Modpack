require "recipecode"

Recipe = Recipe or {}
Recipe.GetItemTypes = Recipe.GetItemTypes or {}
Recipe.OnCanPerform = Recipe.OnCanPerform or {}
Recipe.OnCreate = Recipe.OnCreate or {}
Recipe.OnGiveXP = Recipe.OnGiveXP or {}
Recipe.OnTest = Recipe.OnTest or {}

	--FNAF Mystery Bag
local FNAList = {
    [0] = "PompsItems_FNAF.PIFoxyPlushie",
    [1] = "PompsItems_FNAF.PIBonniePlushie",
    [2] = "PompsItems_FNAF.PIChicaCupcakePlushie",
    [3] = "PompsItems_FNAF.PIChicaPlushie",
    [4] = "PompsItems_FNAF.PIFreddyPlushie",
    [5] = "PompsItems_FNAF.PIGoldenFreddyPlushie",
    [6] = "PompsItems_FNAF.PIPopgoesPlushie",
    [7] = "PompsItems_FNAF.PIBlakeBadgerPlushie",
    [8] = "PompsItems_FNAF.PICandyCatPlushie",
    [9] = "PompsItems_FNAF.PIMontyPlush",
    [10] = "PompsItems_FNAF.PIGlamFreddyPlushie",
    [11] = "PompsItems_FNAF.PIGlamChicaPlushie",
    [12] = "PompsItems_FNAF.PIRoxyPlush",
    [13] = "PompsItems_FNAF.PIVannyPlush",
    [14] = "PompsItems_FNAF.PIToyBonniePlush",
    [15] = "PompsItems_FNAF.PIToyFreddyPlush",
    [16] = "PompsItems_FNAF.PIToyChicaPlush",
    [17] = "PompsItems_FNAF.PIFuntimeFoxyPlush",
    [18] = "PompsItems_FNAF.PIMangleFigure",
	[19] = "PompsItems_FNAF.PIBalloonBoyPlush",
	[20] = "PompsItems_FNAF.PISpringBonniePlushie",
	[21] = "PompsItems_FNAF.PIFredbearPlushie",
	[22] = "PompsItems_FNAF.PISpringtrapPlushie",
	[23] = "PompsItems_FNAF.PICircusBabyPlushie",
	[24] = "PompsItems_FNAF.PIBalloraPlushie",
	[25] = "PompsItems_FNAF.PIMarionettePlushie",
	[26] = "PompsItems_FNAF.PILeftyPlushie",
	[27] = "PompsItems_FNAF.PIHelpyPlushie",
	[28] = "PompsItems_FNAF.PIMusicMan",
	[29] = "PompsItems_FNAF.PIIgnitedFreddyPlushie",
	[30] = "PompsItems_FNAF.PIIgnitedChicaPlushie",
	[31] = "PompsItems_FNAF.PIIgnitedBonniePlushie",
	[32] = "PompsItems_FNAF.PIIgnitedFoxyPlushie",
	[33] = "PompsItems_FNAF.PILolbitPlushie",
	[34] = "PompsItems_FNAF.PISunPlushie",
	[35] = "PompsItems_FNAF.PIMoonPlushie",
	[36] = "PompsItems_FNAF.PIRockstarChicaPlush",
	[37] = "PompsItems_FNAF.PIRockstarFreddyPlush",
	[38] = "PompsItems_FNAF.PIRockstarBonniePlush",
	[39] = "PompsItems_FNAF.PIRockstarFoxyPlush",
	[40] = "PompsItems_FNAF.PIHappyFrogPlush",
	[41] = "PompsItems_FNAF.PIGlamBonniePlush",
	[42] = "PompsItems_FNAF.PIOrvilleElephantPlush",
	[43] = "PompsItems_FNAF.PIMrHippoPlush",
	[44] = "PompsItems_FNAF.PIPigpatchPlush",
	[45] = "PompsItems_FNAF.PINeddBearPlush",
	[46] = "PompsItems_FNAF.PICindyCatPlush",
	[47] = "PompsItems_FNAF.PIElChipPlush",
	[48] = "PompsItems_FNAF.PIFuntimeChicaPlush",
	[49] = "PompsItems_FNAF.PIShadowBonniePlush",
	[50] = "PompsItems_FNAF.PIShadowFreddyPlush",
	[51] = "PompsItems_FNAF.PITwistedWolf",
	[52] = "PompsItems_FNAF.PIFreddlePlush",
	[53] = "PompsItems_FNAF.PIGlitchtrapPlush",
	[54] = "PompsItems_FNAF.PIGoldenCupcakePlush",
	[55] = "PompsItems_FNAF.PIRuinMontyPlush",
	[56] = "PompsItems_FNAF.PIRuinRoxyPlush",
	[57] = "PompsItems_FNAF.PIRuinChicaPlush",
	[58] = "PompsItems_FNAF.PIRuinFreddyPlush",
	[59] = "PompsItems_FNAF.PIMXESModel",
	[60] = "PompsItems_FNAF.PIPlushtrapPlush",
	[61] = "PompsItems_FNAF.PIGlamrockFoxyPlush",
	[62] = "PompsItems_FNAF.PIFanGlamBonniePlush",
	[63] = "PompsItems_FNAF.PIFanGlamFoxyPlush",
	[64] = "PompsItems_FNAF.PIFanGlamManglePlush",
	[65] = "PompsItems_FNAF.PIFanGlamManglePlush",
}

function PIFNAFRandSelect_OnCreate(craftedRecipeData, character)
    local selectedItem = FNAList[ZombRand(#FNAList)]
    local inventory = character:getInventory()
    local item = inventory:AddItem(selectedItem)
    sendAddItemToContainer(inventory, item)
end