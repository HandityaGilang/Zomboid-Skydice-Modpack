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
                        Time = ]] .. 20 * SandboxVars.ammomakerOptions.ProduceAmmoBulkSize .. [[,
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

        inactiveRecipes["ConvertAmmo"]              = true; --2256623447/firearmmod
        inactiveRecipes["Covert556to223"]           = true; --3183820077/guns93
        inactiveRecipes["Covert20556to20223"]       = true; --3183820077/guns93
        inactiveRecipes["Covert556Boxto223Box"]     = true; --3183820077/guns93
        inactiveRecipes["Convert556to223"]          = true; --3183820077/guns93 (corrected)
        inactiveRecipes["Convert20556to20223"]      = true; --3183820077/guns93 (corrected)
        inactiveRecipes["Convert556Boxto223Box"]    = true; --3183820077/guns93 (corrected)
        inactiveRecipes["Convert.223to5.56"]        = true; --3387222454/B42RainsFirearmsAndGunParts4213
        inactiveRecipes["Convert5.56to.223"]        = true; --3387222454/B42RainsFirearmsAndGunParts4213
        inactiveRecipes["Convert.308to7.62x51"]     = true; --3387222454/B42RainsFirearmsAndGunParts4213
        inactiveRecipes["Convert7.62x51to.308"]     = true; --3387222454/B42RainsFirearmsAndGunParts4213
        inactiveRecipes["Convert.223Boxto5.56Box"]  = true; --3387222454/B42RainsFirearmsAndGunParts4213
        inactiveRecipes["Convert5.56Boxto.223Box"]  = true; --3387222454/B42RainsFirearmsAndGunParts4213
        inactiveRecipes["Convert50.308to7.62x51"]   = true; --3387222454/B42RainsFirearmsAndGunPartsExpanded4213
        inactiveRecipes["Convert507.62x51to.308"]   = true; --3387222454/B42RainsFirearmsAndGunPartsExpanded4213

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

    updateCraftRecipes();
    updateRecipesInactive();

    local recipes = getScriptManager():getAllCraftRecipes();

    for i=0,recipes:size()-1 do

        local recipe = recipes:get(i);
        local recipeName = recipe:getName();

        --override recipes icon textures with gunpowder jar icon
        if recipeName == "MakeGunpowder" or recipeName == "WeighGunpowderUnit" then

            recipe:overrideIconTexture(getTexture("Item_GunpowderJar"));

        --update disassemble ammo recipe
        elseif recipeName == "DisassembleAmmo" then

            recipe:Load(recipeName, disAmmoScript);

        --update pack ammo parts recipe
        elseif recipeName == "PackAmmoParts" then

            recipe:Load(recipeName, packAmmoPartsScript);

        --update unpack ammo parts recipe
        elseif recipeName == "UnpackAmmoParts" then

            recipe:Load(recipeName, unpackAmmoPartsScript);

        --update polish casings recipe
        elseif recipeName == "PolishCasing" then

            recipe:Load(recipeName, polCasingScript);

        --update make mold bullets recipe
        elseif recipeName == "MakeMoldBullets" then

            recipe:Load(recipeName, makeMoldBulletsScript);

        --update extract nitre recipe
        elseif recipeName == "ExtractNitre" then

            recipe:Load(recipeName, extNitreScript);

        --update make pipe bomb recipe
        elseif recipeName == "MakePipeBomb" then

            recipe:getInputs():clear();
            recipe:getOutputs():clear();

            recipe:Load(recipeName, makePipeBombScript);

        --update make firecracker recipe
        elseif recipeName == "MakeFirecracker" then

            recipe:getInputs():clear();
            recipe:getOutputs():clear();

            recipe:Load(recipeName, makeFirecrackerScript);

        --update make ammo recipes
        elseif makeAmmoScripts[recipeName] then

            recipe:Load(recipeName, makeAmmoScripts[recipeName]);

        --update produce ammo recipes
        elseif produceAmmoScripts[recipeName] then

            recipe:Load(recipeName, produceAmmoScripts[recipeName]);

        --update make hollow point bullet recipe
        elseif recipeName == "MakeHollowPointBullet" and not inactiveRecipes["MakeHollowPointBullet"] then

            recipe:Load(recipeName, makeHollowPointBulletScript);

        --deactivate recipes
        elseif inactiveRecipes[recipeName] then

            deactivateRecipe(recipeName, recipe);

        end

    end

end

Events.OnInitGlobalModData.Add(initRecipes);