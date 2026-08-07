--Ammo Maker by STIMP_TM

local disAmmoScript = [[]];
local packAmmoPartsScript = [[]];
local unpackAmmoPartsScript = [[]];
local polCasingScript = [[]];
local makeMoldBulletsScript = [[]];
local makeHollowPointBulletScript = [[]];
local extNitreScript = [[]];
local makePipeBombScript = [[]];
local makeFirecrackerScript = [[]];
local makeAmmoScripts = {};
local produceAmmoScripts = {};
local inactiveRecipes = {};

local baseCraftingTimes = {
	["MakeBrassSheet"]					= 200,
	["MakeReloadingPressBase"]			= 500,
	["MakeReloadingPressDiePlate"]		= 400,
	["MakeReloadingPressDieSet"]		= 200,
	["MakeReloadingPressLinkage"]		= 200,
	["MakeReloadingPressHandle"]		= 300,

	["MakeBulletsRifleS"]				= 200,
	["MakeBulletsRifleSAP"]				= 200,
	["MakeBulletsRifleM"]				= 200,
	["MakeBulletsRifleL"]				= 200,
	["MakeBulletsHandgunS"]				= 200,
	["MakeBulletsHandgunM"]				= 200,
	["MakeBulletsHandgunL"]				= 200,
	["MakeBalls00"]						= 200,
	["MakeSlugs12"]						= 200,
	["MakeProjectile40HE"]				= 400,
	["MakeProjectile40INC"]				= 400,
	["MakeProjectile40MPB"]				= 200,
	["MakeCasingsBottleneckS"]			= 200,
	["MakeCasingsBottleneckM"]			= 200,
	["MakeCasingsBottleneckL"]			= 200,
	["MakeCasingsBottleneckMRim"]		= 200,
	["MakeCasingsStraightS"]			= 200,
	["MakeCasingsStraightM"]			= 200,
	["MakeCasingsStraightL"]			= 200,
	["MakeCasingsStraightSRim"]			= 200,
	["MakeCasingsStraightMRim"]			= 200,
	["MakeCasingsStraightLRim"]			= 200,
	["MakeHullsShotgunS"]				= 200,
	["MakeHullsShotgunL"]				= 200,
	["MakeCasingGrenade"]				= 200,

	["RecycleBulletsRifleS"]			= 50,
	["RecycleBulletsRifleSAP"]			= 50,
	["RecycleBulletsRifleSHP"]			= 50,
	["RecycleBulletsRifleM"]			= 50,
	["RecycleBulletsRifleL"]			= 50,
	["RecycleBulletsHandgunS"]			= 50,
	["RecycleBulletsHandgunM"]			= 50,
	["RecycleBulletsHandgunL"]			= 50,
	["RecycleBalls00"]					= 50,
	["RecycleSlugs12"]					= 50,
	["RecycleCasingsBottleneckS"]		= 50,
	["RecycleCasingsBottleneckM"]		= 50,
	["RecycleCasingsBottleneckL"]		= 50,
	["RecycleCasingsBottleneckMRim"]	= 50,
	["RecycleCasingsStraightS"]			= 50,
	["RecycleCasingsStraightM"]			= 50,
	["RecycleCasingsStraightL"]			= 50,
	["RecycleCasingsStraightSRim"]		= 50,
	["RecycleCasingsStraightMRim"]		= 50,
	["RecycleCasingsStraightLRim"]		= 50,
	["RecycleHullsShotgunS"]			= 50,
	["RecycleHullsShotgunL"]			= 50,
	["RecycleCasingGrenade"]			= 50,

	["DissolveBirdExcrement"]			= 100,
	["ExtractNitre"]					= 300,
	["MakeFilterPaper"]					= 30,
	["ExtractSulfurFromStones"]			= 300,
	["MakeCharcoalPowder"]				= 100,
	["MakeGunpowder"]					= 500,
	["WeighGunpowderGrains"]			= 200,
	["WeighGunpowderUnit"]				= 200,
	["MakeGunpowderScale"]				= 500,
	["MakeReloadingPress"]				= 500,
	["RepaintReloadingPress"]			= 100,
	["MakeBrassCatcherImprovised"]		= 100,
	["MakeBrassCatcherAdvanced"]		= 300,
	["MakeMold"]						= 100,
	["MakeMoldBullets"]					= 200,
	["DisassembleAmmo"]					= 15,
	["PackAmmoParts"]					= 15,
	["UnpackAmmoParts"]					= 15,
	["PolishCasing"]					= 10,
	["MakePolishingCompound"]			= 50,
	["MakeHollowPointBullet"]			= 10,
	["RecycleJewelryChain"]				= 50,
	["RecycleBrass"]					= 50,
	["RecyclePlastic"]					= 50,
	["RepairHullsFiredShotgunS"]		= 80,
	["RepairHullsFiredShotgunL"]		= 80,
};

local function calculateCraftingTime(baseCraftingTime)

    local craftingTime = math.floor(baseCraftingTime / SandboxVars.ammomakerOptions.CraftingSpeed + 0.5);

    if craftingTime < 10 then

        craftingTime = 10;

    end

    return craftingTime;

end

local function updateCraftingTimes()

    for recipeName, baseCraftingTime in pairs(baseCraftingTimes) do

        local craftingTime = calculateCraftingTime(baseCraftingTime);

        ScriptManager.instance:getCraftRecipe(recipeName):Load(recipeName, "{ Time = " .. craftingTime .. ", }");

    end

end

local function updateCraftRecipes()

    local disAmmoInputItems = "";
    local disAmmoCasingTypeMap = {};
    local disAmmoBulletTypeMap = {};

    local packAmmoPartsInputItems = "";
    local packAmmoPartsTypeMap = {};

    local unpackAmmoPartsInputItems = "";
    local unpackAmmoPartsTypeMap = {};

    local polCasingInputItems = "";
    local polCasingCasingTypeMap = {};

    local makeMoldBulletsBulletInputItems = "";
    local makeMoldBulletsMoldInputItems = "";
    local makeMoldBulletsTypeMap = {};

    local makeHollowPointBulletInputItems = "";
    local makeHollowPointBulletTypeMap = {};

    for ammoItemType, ammoItemData in pairs(ammoMakerAmmoTypes) do

        if ammoMakerGetAmmoTypeActive(ammoItemType) == true then

            local ammoType = ammoItemData.ammoTypes[ammoMakerGetAmmoTypeIndexActive(ammoItemType)];
            local ammoData = ammoMakerAmmoData[ammoType];
            local casingOldType = ammoMakerAmmoParts[ammoData.casingType].partOld;

            --get disassemble ammo recipe data
            disAmmoInputItems = disAmmoInputItems .. ammoItemType .. ";";
            table.insert(disAmmoCasingTypeMap, ammoData.casingType .. " = " .. ammoItemType .. ",");
            table.insert(disAmmoBulletTypeMap, ammoData.bulletType .. " = " .. ammoItemType .. ",");

            --get polish casing recipe data
            if ammoMakerAmmoParts[ammoData.casingType].partClass == "Casing" then

                local polCasingCasingTypeMapNew = ammoData.casingType .. " = " .. casingOldType .. ",";
                if not ammoMakerIsValueInTable(polCasingCasingTypeMap, polCasingCasingTypeMapNew) then

                    polCasingInputItems = polCasingInputItems .. casingOldType .. ";";
                    table.insert(polCasingCasingTypeMap, polCasingCasingTypeMapNew);

                end

            end

            --get pack and unpack ammo parts recipe data
            if ammoMakerAmmoParts[ammoData.bulletType].boxType then

                local bulletBoxType = ammoMakerAmmoParts[ammoData.bulletType].boxType;

                local packAmmoPartsTypeMapNew = bulletBoxType .. " = " .. ammoData.bulletType .. ",";
                if not ammoMakerIsValueInTable(packAmmoPartsTypeMap, packAmmoPartsTypeMapNew) then

                    packAmmoPartsInputItems = packAmmoPartsInputItems .. ammoData.bulletType .. ";";
                    table.insert(packAmmoPartsTypeMap, packAmmoPartsTypeMapNew);

                end

                local unpackAmmoPartsTypeMapNew = ammoData.bulletType .. " = " .. bulletBoxType .. ",";
                if not ammoMakerIsValueInTable(unpackAmmoPartsTypeMap, unpackAmmoPartsTypeMapNew) then

                    unpackAmmoPartsInputItems = unpackAmmoPartsInputItems .. bulletBoxType .. ";";
                    table.insert(unpackAmmoPartsTypeMap, unpackAmmoPartsTypeMapNew);

                end

            end

            if ammoMakerAmmoParts[ammoData.casingType].boxType then

                local casingBoxType = ammoMakerAmmoParts[ammoData.casingType].boxType;

                local packAmmoPartsTypeMapNew = casingBoxType .. " = " .. ammoData.casingType .. ",";
                if not ammoMakerIsValueInTable(packAmmoPartsTypeMap, packAmmoPartsTypeMapNew) then

                    packAmmoPartsInputItems = packAmmoPartsInputItems .. ammoData.casingType .. ";";
                    table.insert(packAmmoPartsTypeMap, packAmmoPartsTypeMapNew);

                end

                local unpackAmmoPartsTypeMapNew = ammoData.casingType .. " = " .. casingBoxType .. ",";
                if not ammoMakerIsValueInTable(unpackAmmoPartsTypeMap, unpackAmmoPartsTypeMapNew) then

                    unpackAmmoPartsInputItems = unpackAmmoPartsInputItems .. casingBoxType .. ";";
                    table.insert(unpackAmmoPartsTypeMap, unpackAmmoPartsTypeMapNew);

                end

            end

            if ammoMakerAmmoParts[ammoData.casingType].bagType then

                local casingBagType = ammoMakerAmmoParts[ammoData.casingType].bagType;

                local packAmmoPartsTypeMapNew = casingBagType .. " = " .. casingOldType .. ",";
                if not ammoMakerIsValueInTable(packAmmoPartsTypeMap, packAmmoPartsTypeMapNew) then

                    packAmmoPartsInputItems = packAmmoPartsInputItems .. casingOldType .. ";";
                    table.insert(packAmmoPartsTypeMap, packAmmoPartsTypeMapNew);

                end

                local unpackAmmoPartsTypeMapNew = casingOldType .. " = " .. casingBagType .. ",";
                if not ammoMakerIsValueInTable(unpackAmmoPartsTypeMap, unpackAmmoPartsTypeMapNew) then

                    unpackAmmoPartsInputItems = unpackAmmoPartsInputItems .. casingBagType .. ";";
                    table.insert(unpackAmmoPartsTypeMap, unpackAmmoPartsTypeMapNew);

                end

            end

            --get make mold bullets recipe data
            if ammoMakerAmmoParts[ammoData.bulletType].moldType then

                local bulletMoldType = ammoMakerAmmoParts[ammoData.bulletType].moldType;

                local makeMoldBulletsTypeMapNew = bulletMoldType .. " = " .. ammoData.bulletType .. ",";
                if not ammoMakerIsValueInTable(makeMoldBulletsTypeMap, makeMoldBulletsTypeMapNew) then

                    makeMoldBulletsBulletInputItems = makeMoldBulletsBulletInputItems .. ammoData.bulletType .. ";";
                    makeMoldBulletsMoldInputItems = makeMoldBulletsMoldInputItems .. bulletMoldType .. ";";
                    table.insert(makeMoldBulletsTypeMap, makeMoldBulletsTypeMapNew);

                end

            end

            --get make hollow poin bullet recipe data
            if ammoMakerAmmoParts[ammoData.bulletType].partExtraClass == "HollowPoint" then

                local bulletBaseType = ammoMakerAmmoParts[ammoData.bulletType].baseType;

                local makeHollowPointBulletTypeMapNew = ammoData.bulletType .. " = " .. bulletBaseType .. ",";
                if not ammoMakerIsValueInTable(makeHollowPointBulletTypeMap, makeHollowPointBulletTypeMapNew) then

                    makeHollowPointBulletInputItems = makeHollowPointBulletInputItems .. bulletBaseType .. ";";
                    table.insert(makeHollowPointBulletTypeMap, makeHollowPointBulletTypeMapNew);

                end

            end

            local makeAmmoScript = [[
                {
                    Time = ]] .. calculateCraftingTime(30) .. [[,
                    inputs
                    {
                        item ]] .. ammoData.grainsAmount .. [[ [ammomaker.ammomaker_GunPowderGrains],
                        item 1 []] .. ammoData.casingType .. [[],
                        item ]] .. ammoData.bulletCount .. [[ []] .. ammoData.bulletType .. [[],
                        item 1 tags[base:hammer] mode:keep flags[MayDegradeLight],
                    }
                    outputs
                    {
                        item 1 ]] .. ammoItemType .. [[,
                    }
                }
            ]];

            makeAmmoScripts["Make" .. ammoType] = makeAmmoScript;

            if ammoData.bulkCrafting == true then

                local produceAmmoScript = [[
                    {
                        Time = ]] .. calculateCraftingTime(10 * SandboxVars.ammomakerOptions.ProduceAmmoBulkSize) .. [[,
                        inputs
                        {
                            item ]] .. ammoData.grainsAmount * SandboxVars.ammomakerOptions.ProduceAmmoBulkSize .. [[ [ammomaker.ammomaker_GunPowderGrains],
                            item ]] .. SandboxVars.ammomakerOptions.ProduceAmmoBulkSize .. [[ []] .. ammoData.casingType .. [[],
                            item ]] .. ammoData.bulletCount * SandboxVars.ammomakerOptions.ProduceAmmoBulkSize .. [[ []] .. ammoData.bulletType .. [[],
                            item 1 tags[ammomaker:reloadingpress] mode:keep,
                        }
                        outputs
                        {
                            item ]] .. SandboxVars.ammomakerOptions.ProduceAmmoBulkSize .. [[ ]] .. ammoItemType .. [[,
                        }
                    }
                ]];

                produceAmmoScripts["Produce" .. ammoType] = produceAmmoScript;

            end

        end

    end

    for ammoType, ammoData in pairs(ammoMakerAmmoData) do

        if not makeAmmoScripts["Make" .. ammoType] then

            inactiveRecipes["Make" .. ammoType] = true;

        end

        if not produceAmmoScripts["Produce" .. ammoType] and ammoData.bulkCrafting == true then

            inactiveRecipes["Produce" .. ammoType] = true;

        end

    end

    disAmmoInputItems = disAmmoInputItems:sub(1, -2);
    disAmmoCasingTypeMap = table.concat(disAmmoCasingTypeMap, "\n");
    disAmmoBulletTypeMap = table.concat(disAmmoBulletTypeMap, "\n");

    disAmmoScript = [[
        {
            inputs
            {
                item 1 []] .. disAmmoInputItems .. [[] mappers[casingType;bulletType] mode:destroy,
                item 1 tags[base:pliers;base:visegrips] mode:keep,
            }
            outputs
            {
                item 1 mapper:casingType,
                item 1 mapper:bulletType flags[HasOneUse],
            }
            itemMapper casingType
            {
                ]] .. disAmmoCasingTypeMap .. [[
            }
            itemMapper bulletType
            {
                ]] .. disAmmoBulletTypeMap .. [[
            }
        }
    ]];

    packAmmoPartsInputItems = packAmmoPartsInputItems:sub(1, -2);
    packAmmoPartsTypeMap = table.concat(packAmmoPartsTypeMap, "\n");

    packAmmoPartsScript = [[
        {
            inputs
            {
                item 25 []] .. packAmmoPartsInputItems .. [[] flags[IsFull;ItemCount;IsExclusive] mappers[ammoPartType] mode:destroy,
            }
            outputs
            {
                item 1 mapper:ammoPartType,
            }
            itemMapper ammoPartType
            {
                ]] .. packAmmoPartsTypeMap .. [[
            }
        }
    ]];

    unpackAmmoPartsInputItems = unpackAmmoPartsInputItems:sub(1, -2);
    unpackAmmoPartsTypeMap = table.concat(unpackAmmoPartsTypeMap, "\n");

    unpackAmmoPartsScript = [[
        {
            inputs
            {
                item 1 []] .. unpackAmmoPartsInputItems .. [[] mappers[ammoPackType] mode:destroy,
            }
            outputs
            {
                item 25 mapper:ammoPackType,
            }
            itemMapper ammoPackType
            {
                ]] .. unpackAmmoPartsTypeMap .. [[
            }
        }
    ]];

    polCasingInputItems = polCasingInputItems:sub(1, -2);
    polCasingCasingTypeMap = table.concat(polCasingCasingTypeMap, "\n");

    polCasingScript = [[
        {
            inputs
            {
                item 1 []] .. polCasingInputItems .. [[] mappers[casingType] mode:destroy,
                item 1 [ammomaker.ammomaker_PolishingCompound],
                item 1 [Base.Toothbrush;Base.GrillBrush;Base.SteelWool] mode:keep,
            }
            outputs
            {
                item 1 mapper:casingType,
            }
            itemMapper casingType
            {
                ]] .. polCasingCasingTypeMap .. [[
            }
        }
    ]];

    makeMoldBulletsBulletInputItems = makeMoldBulletsBulletInputItems:sub(1, -2);
    makeMoldBulletsMoldInputItems = makeMoldBulletsMoldInputItems:sub(1, -2);
    makeMoldBulletsTypeMap = table.concat(makeMoldBulletsTypeMap, "\n");

    makeMoldBulletsScript = [[
        {
		    inputs
		    {
		    	item 1 [ammomaker.ammomaker_Mold;]] .. makeMoldBulletsMoldInputItems .. [[] mode:destroy,
		    	item 1 []] .. makeMoldBulletsBulletInputItems .. [[] flags[ItemCount] mappers[bulletType] mode:keep,
                item 1 [*] mode:keep flags[ItemIsFluid;HandcraftOnly],
		    	-fluid 0.5 categories[Water] mode:mixture,
		    }
		    outputs
		    {
		    	item 1 mapper:bulletType,
		    }
		    itemMapper bulletType
		    {
		    	]] .. makeMoldBulletsTypeMap .. [[
		    }
        }
    ]];

    if makeHollowPointBulletInputItems ~= "" then --makeHollowPointBulletTypeMap ~= {} then --testV == true then --makeHollowPointBulletTypeMap:size() > 0

        makeHollowPointBulletInputItems = makeHollowPointBulletInputItems:sub(1, -2);
        makeHollowPointBulletTypeMap = table.concat(makeHollowPointBulletTypeMap, "\n");

        makeHollowPointBulletScript = [[
            {
	    	    inputs
	    	    {
	    	    	item 1 []] .. makeHollowPointBulletInputItems .. [[] mappers[bulletType] mode:destroy,
                    item 1 [Base.SmallFileSet] mode:keep,
	    	    }
	    	    outputs
	    	    {
	    	    	item 1 mapper:bulletType,
	    	    }
	    	    itemMapper bulletType
	    	    {
	    	    	]] .. makeHollowPointBulletTypeMap .. [[
	    	    }
            }
        ]];

    else

        inactiveRecipes["MakeHollowPointBullet"] = true;

    end

    extNitreScript = [[
        {
            inputs
		    {
		    	item 1 [ammomaker.ammomaker_PotOfBirdExcrement;ammomaker.ammomaker_PotForgedOfBirdExcrement],
		    	item 2 [ammomaker.ammomaker_FilterPaper],
		    	item 2 [Base.RippedSheets],
		    }
		    outputs
		    {
                item ]] .. SandboxVars.ammomakerOptions.NitreYield .. [[ ammomaker.ammomaker_Nitre,
		    }
        }
    ]];

    makePipeBombScript = [[
        {
            inputs
		    {
                item 3 [Base.ElectronicsScrap],
                item 1 [Base.MetalPipe;Base.MetalPipe_Broken],
                item 80 [ammomaker.ammomaker_GunPowderGrains],
                item 1 [Base.Twine],
                item 1 tags[base:metalsaw;base:smallsaw] mode:keep flags[MayDegradeLight],
		    }
		    outputs
		    {
                item 1 Base.PipeBomb,
		    }
        }
    ]];

    makeFirecrackerScript = [[
        {
            inputs
            {
                item 1 tags[base:scissors] mode:keep flags[IsNotDull],
                item 1 [Base.Glue],
                item 2 [ammomaker.ammomaker_GunPowderGrains],
                item 1 [Base.SheetPaper2;Base.GraphPaper;Base.Brochure;Base.Flier;Base.Paperwork;Base.LetterHandwritten;Base.Doodle;Base.DoodleKids;Base.GenericMail],
                item 1 [Base.Twine],
            }
            outputs
            {
                item 1 Base.Firecracker_Crafted,
            }
        }
    ]];

end

local function updateRecipesInactive()

    --add base game gather gunpowder recipe to inactive recipes table
    inactiveRecipes["GatherGunpowder"] = true;

    --add inactive make ammo parts recipes to inactive recipes table
    local inactiveMakePartRecipes = ammoMakerGetMakePartRecipesInactive();

    for makePartRecipeType, makePartRecipeData in pairs(inactiveMakePartRecipes) do

        inactiveRecipes[makePartRecipeType] = true;

    end

    --add inactive recycle ammo parts recipes to inactive recipes table
    local inactiveRecyclePartRecipes = ammoMakerGetRecyclePartRecipesInactive();

    for recyclePartRecipeType, recyclePartRecipeData in pairs(inactiveRecyclePartRecipes) do

        inactiveRecipes[recyclePartRecipeType] = true;

    end

    --add inactive repair ammo parts recipes to inactive recipes table
    local inactiveRepairPartRecipes = ammoMakerGetRepairPartRecipesInactive();

    for repairPartRecipeType, repairPartRecipeData in pairs(inactiveRepairPartRecipes) do

        inactiveRecipes[repairPartRecipeType] = true;

    end

    --add convert ammo recipes from supported mods to inactive recipes table dependent on sandbox option
    if SandboxVars.ammomakerOptions.AllowConvertRecipes == false then

        --add inactive convert ammo recipes to inactive recipes table

    end
    
end

local function deactivateRecipe(recipeName, recipe)

    recipe:overrideIconTexture(getTexture(""));
    recipe:getInputs():clear();
    recipe:getOutputs():clear();

    local deactivatedRecipe = "{ NeedToBeLearn = True, inputs {item 1 [ammomaker.ammomaker_NA],} outputs {} }";
    
    recipe:Load(recipeName, deactivatedRecipe);
    recipe:overrideTranslationName("_ N/A _ " .. recipe:getTranslationName());

end

local function initRecipes()

    updateCraftingTimes();
    updateCraftRecipes();
    updateRecipesInactive();

    --update recipe icons
    ScriptManager.instance:getCraftRecipe("MakeGunpowder"):overrideIconTexture(getTexture("Item_GunpowderJar"));
    ScriptManager.instance:getCraftRecipe("WeighGunpowderUnit"):overrideIconTexture(getTexture("Item_GunpowderJar"));

    --update recipe scripts
    ScriptManager.instance:getCraftRecipe("DisassembleAmmo"):Load("DisassembleAmmo", disAmmoScript);
    ScriptManager.instance:getCraftRecipe("PackAmmoParts"):Load("PackAmmoParts", packAmmoPartsScript);
    ScriptManager.instance:getCraftRecipe("UnpackAmmoParts"):Load("UnpackAmmoParts", unpackAmmoPartsScript);
    ScriptManager.instance:getCraftRecipe("PolishCasing"):Load("PolishCasing", polCasingScript);
    ScriptManager.instance:getCraftRecipe("MakeMoldBullets"):Load("MakeMoldBullets", makeMoldBulletsScript);
    ScriptManager.instance:getCraftRecipe("ExtractNitre"):Load("ExtractNitre", extNitreScript);

    if not inactiveRecipes["MakeHollowPointBullet"] then

        ScriptManager.instance:getCraftRecipe("MakeHollowPointBullet"):Load("MakeHollowPointBullet", makeHollowPointBulletScript);

    end

	for makeAmmoRecipeName, makeAmmoScript in pairs(makeAmmoScripts) do

        local makeAmmoRecipe = ScriptManager.instance:getCraftRecipe(makeAmmoRecipeName);
        makeAmmoRecipe:Load(makeAmmoRecipeName, makeAmmoScript);

    end

    for produceAmmoRecipeName, produceAmmoScript in pairs(produceAmmoScripts) do

        local produceAmmoRecipe = ScriptManager.instance:getCraftRecipe(produceAmmoRecipeName);
        produceAmmoRecipe:Load(produceAmmoRecipeName, produceAmmoScript);

    end

    --update inactive recipes
    for recipeName, recipeInactive in pairs(inactiveRecipes) do

        local recipe = ScriptManager.instance:getCraftRecipe(recipeName);
        deactivateRecipe(recipeName, recipe);

    end

    --update base game recipes
    local makePipeBombRecipe = ScriptManager.instance:getCraftRecipe("MakePipeBomb");
    makePipeBombRecipe:getInputs():clear();
    makePipeBombRecipe:getOutputs():clear();
    makePipeBombRecipe:Load("MakePipeBomb", makePipeBombScript);

    local makeFirecrackerRecipe = ScriptManager.instance:getCraftRecipe("MakeFirecracker");
    makeFirecrackerRecipe:getInputs():clear();
    makeFirecrackerRecipe:getOutputs():clear();
    makeFirecrackerRecipe:Load("MakeFirecracker", makeFirecrackerScript);

end

Events.OnInitGlobalModData.Add(initRecipes);