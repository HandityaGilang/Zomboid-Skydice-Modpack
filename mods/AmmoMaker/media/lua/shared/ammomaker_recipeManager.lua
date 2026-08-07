--Ammo Maker by STIMP_TM

local function ammoMakerRecipeManager()

    --disable base module recipes

    local RecipeNamesBaseDisable = {
        [1] = "Gather Gunpowder",
    };

    local function recipesBaseDisable()

        local recipes = getScriptManager():getAllRecipes();

        for i=0,recipes:size()-1 do

            local recipe = recipes:get(i);

            for _, RecipeNameBaseDisable in ipairs(RecipeNamesBaseDisable) do

                if string.find(recipe:getOriginalname(), RecipeNameBaseDisable) ~= nil then

                    recipe:setLuaTest("Recipe.OnTest.disabled");
                    recipe:setIsHidden(true);
                    recipe:setNeedToBeLearn(false);

                end

            end

        end

    end

    recipesBaseDisable();

    --set recipes 'is hidden'

    local function recipesSetIsHidden(RecipeNames, isHidden)

        for _, RecipeName in ipairs(RecipeNames) do
    
            local recipe = ScriptManager.instance:getRecipe(RecipeName);

            if recipe then

                recipe:setIsHidden(isHidden);

            end
                
        end
    
    end

    --charcoal

    if SandboxVars.ammomakerOptions.DeactivateCharcoalRecipes == true then

        local RecipeNamesCharcoalHide = {
            [1] = "ammomaker.Make Charcoal from Logs",
            [2] = "ammomaker.Make Charcoal from Branches",
        };

        recipesSetIsHidden(RecipeNamesCharcoalHide, true);

    end

    --archery

    if SandboxVars.ammomakerOptions.ActivateArchery == true then

        local RecipeNamesArcheryShow = {
            [1] = "ammomaker.Make Arrow Head [AM]",
            [2] = "ammomaker.Make Arrow Fletching [AM]",
            [3] = "ammomaker.Make Arrow Wooden [AM]",
            [4] = "ammomaker.Make Bolt Wooden [AM]",
            [5] = "ammomaker.Recycle Arrow Head [AM]",
            [6] = "ammomaker.Recycle Arrow Wooden [AM]",
            [7] = "ammomaker.Recycle Bolt Wooden [AM]",
        };

        recipesSetIsHidden(RecipeNamesArcheryShow, false);

    end

    --afr

    if getActivatedMods():contains("AdditonalFirearmsR") or getActivatedMods():contains("AdditonalFirearmsR rebalance") then

        local RecipeNamesAFRShow = {
            [1] = "ammomaker.Make 5.7x28 [AFR]",
            [2] = "ammomaker.Make 7.62x51 NATO [AFR]",
            [3] = "ammomaker.Recycle 5.7x28 [AFR]",
            [4] = "ammomaker.Recycle 7.62x51 NATO [AFR]",
        };
    
        recipesSetIsHidden(RecipeNamesAFRShow, false);

    end

    --agf

    if getActivatedMods():contains("Arsenal(26)GunFighter") or getActivatedMods():contains("Arsenal(26)GunFighter[MAIN MOD 2.0]") then

        local RecipeNamesAGFShow = {
            [1] = "ammomaker.Make .177 BB [AGF]",
            [2] = "ammomaker.Make 5.45x39 [AGF]",
            [3] = "ammomaker.Make 5.7x28 [AGF]",
            [4] = "ammomaker.Make .22 LR [AGF]",
            [5] = "ammomaker.Make 7.62x51 NATO [AGF]",
            [6] = "ammomaker.Make .30-06 Spring [AGF]",
            [7] = "ammomaker.Make 7.62x39 [AGF]",
            [8] = "ammomaker.Make 7.62x54 R [AGF]",
            [9] = "ammomaker.Make .380 ACP [AGF]",
            [10] = "ammomaker.Make .357 Mag [AGF]",
            [11] = "ammomaker.Make .410 G Buck 00 [AGF]",
            [12] = "ammomaker.Make .45 LC [AGF]",
            [13] = "ammomaker.Make .45-70 Gov [AGF]",
            [14] = "ammomaker.Make .50 AE [AGF]",
            [15] = "ammomaker.Make .50 BMG [AGF]",
            [16] = "ammomaker.Make 20 G Buck 00 [AGF]",
            [17] = "ammomaker.Make .68 Paintballs [AGF]",
            [18] = "ammomaker.Make 10 G Buck 00 [AGF]",
            [19] = "ammomaker.Make 4 G Buck 00 [AGF]",
            [20] = "ammomaker.Make 40mm HE [AGF]",
            [21] = "ammomaker.Make 40mm INC [AGF]",
            [22] = "ammomaker.Make HE Rocket [AGF]",
            [23] = "ammomaker.Recycle .177 BB [AGF]",
            [24] = "ammomaker.Recycle 5.45x39 [AGF]",
            [25] = "ammomaker.Recycle 5.7x28 [AGF]",
            [26] = "ammomaker.Recycle .22 LR [AGF]",
            [27] = "ammomaker.Recycle 7.62x51 NATO [AGF]",
            [28] = "ammomaker.Recycle .30-06 Spring [AGF]",
            [29] = "ammomaker.Recycle 7.62x39 [AGF]",
            [30] = "ammomaker.Recycle 7.62x54 R [AGF]",
            [31] = "ammomaker.Recycle .380 ACP [AGF]",
            [32] = "ammomaker.Recycle .357 Mag [AGF]",
            [33] = "ammomaker.Recycle .410 G Buck 00 [AGF]",
            [34] = "ammomaker.Recycle .45 LC [AGF]",
            [35] = "ammomaker.Recycle .45-70 Gov [AGF]",
            [36] = "ammomaker.Recycle .50 AE [AGF]",
            [37] = "ammomaker.Recycle .50 BMG [AGF]",
            [38] = "ammomaker.Recycle 20 G Buck 00 [AGF]",
            [39] = "ammomaker.Recycle 10 G Buck 00 [AGF]",
            [40] = "ammomaker.Recycle 4 G Buck 00 [AGF]",
            [41] = "ammomaker.Recycle 40mm HE [AGF]",
            [42] = "ammomaker.Recycle 40mm INC [AGF]",
            [43] = "ammomaker.Recycle HE Rocket [AGF]",
            [44] = "ammomaker.Make Parts Bottleneck L",
            [45] = "ammomaker.Make Parts Bottleneck M Rim",
            [46] = "ammomaker.Make Parts Straight L",
            [47] = "ammomaker.Make Parts Straight S Rim",
            [48] = "ammomaker.Make Parts Straight L Rim",
            [49] = "ammomaker.Make Hull Shotgun L",
            [50] = "ammomaker.Make Parts Grenade",
            [51] = "ammomaker.Make Arrow Head [AGF]",
            [52] = "ammomaker.Make Arrow Fletching [AGF]",
            [53] = "ammomaker.Make Arrow Shaft [AGF]",
            [54] = "ammomaker.Make Bolt Shaft [AGF]",
            [55] = "ammomaker.Recycle Parts Bottleneck L",
            [56] = "ammomaker.Recycle Parts Bottleneck M Rim",
            [57] = "ammomaker.Recycle Parts Straight L",
            [58] = "ammomaker.Recycle Parts Straight S Rim",
            [59] = "ammomaker.Recycle Parts Straight L Rim",
            [60] = "ammomaker.Recycle Hull Shotgun L",
            [61] = "ammomaker.Recycle Parts Grenade",
            [62] = "ammomaker.Recycle Arrow Head [AGF]",
            [63] = "ammomaker.Recycle Casing 5.45x39 [AGF]",
            [64] = "ammomaker.Recycle Casing .223 Rem [AGF]",
            [65] = "ammomaker.Recycle Casing 5.56x45 NATO [AGF]",
            [66] = "ammomaker.Recycle Casing 5.7x28 [AGF]",
            [67] = "ammomaker.Recycle Casing .22 LR [AGF]",
            [68] = "ammomaker.Recycle Casing 7.62x51 NATO [AGF]",
            [69] = "ammomaker.Recycle Casing .30-06 Spring [AGF]",
            [70] = "ammomaker.Recycle Casing .308 Win [AGF]",
            [71] = "ammomaker.Recycle Casing 7.62x39 [AGF]",
            [72] = "ammomaker.Recycle Casing 7.62x54 R [AGF]",
            [73] = "ammomaker.Recycle Casing .380 ACP [AGF]",
            [74] = "ammomaker.Recycle Casing 9mm Luger [AGF]",
            [75] = "ammomaker.Recycle Casing .38 SP [AGF]",
            [76] = "ammomaker.Recycle Casing .357 Mag [AGF]",
            [77] = "ammomaker.Recycle Hull 410 G Buck [AGF]",
            [78] = "ammomaker.Recycle Casing .44 Mag [AGF]",
            [79] = "ammomaker.Recycle Casing .45 ACP [AGF]",
            [80] = "ammomaker.Recycle Casing .45 LC [AGF]",
            [81] = "ammomaker.Recycle Casing .45-70 Gov [AGF]",
            [82] = "ammomaker.Recycle Casing .50 AE [AGF]",
            [83] = "ammomaker.Recycle Casing .50 BMG [AGF]",
            [84] = "ammomaker.Recycle Hull 20 G Buck [AGF]",
            [85] = "ammomaker.Recycle Hull 12 G Buck [AGF]",
            [86] = "ammomaker.Recycle Hull 10 G Buck [AGF]",
            [87] = "ammomaker.Recycle Hull 4 G Buck [AGF]",
            [88] = "Base.Make 5.7x28mm Ammunition",
            [89] = "Base.Make 380-ACP Ammunition",
            [90] = "Base.Make 9mm Ammunition",
            [91] = "Base.Make 38-SPC Ammunition",
            [92] = "Base.Make 357-MAG Ammunition",
            [93] = "Base.Make 45-ACP Ammunition",
            [94] = "Base.Make 45-LC Ammunition",
            [95] = "Base.Make 44-MAG Ammunition",
            [96] = "Base.Make 50-MAG Ammunition",
            [97] = "Base.Make 45-70 GOV Ammunition",
            [98] = "Base.Make 223-REM Ammunition",
            [99] = "Base.Make 5.56x45mm Ammunition",
            [100] = "Base.Make 5.45x39mm Ammunition",
            [101] = "Base.Make 7.62x39mm Ammunition",
            [102] = "Base.Make 308-WIN Ammunition",
            [103] = "Base.Make 7.62x51mm Ammunition",
            [104] = "Base.Make 7.62x54mm-R Ammunition",
            [105] = "Base.Make 30-06 SPG Ammunition",
            [106] = "Base.Make 50-BMG Ammunition",
            [107] = "Base.Make 410g ShotShell",
            [108] = "Base.Make 20g ShotShell",
            [109] = "Base.Make 12g ShotShell",
            [110] = "Base.Make 10g ShotShell",
            [111] = "Base.Make 4g ShotShell",
        };

        recipesSetIsHidden(RecipeNamesAGFShow, false);

        if SandboxVars.ammomakerOptions.ActivateArchery == true then

            local RecipeNamesAGFArcheryShow = {
                [1] = "ammomaker.Make Arrow [AGF]",
                [2] = "ammomaker.Make Bolt [AGF]",
            };

            recipesSetIsHidden(RecipeNamesAGFArcheryShow, false);

        end

    end

    --agf2

    if getActivatedMods():contains("Arsenal(26)GunFighter[MAIN MOD 2.0]") then

        local RecipeNamesAGF2Show = {
            [1] = "ammomaker.Make 12 G Flare [AGF]",
            [2] = "ammomaker.Recycle 12 G Flare [AGF]",
        };

        recipesSetIsHidden(RecipeNamesAGF2Show, false);

    end

    --cj

    if getActivatedMods():contains("CaptainJuezo1") or getActivatedMods():contains("CaptainJuezo1_WIP") then

        local RecipeNamesCJShow = {
            [1] = "ammomaker.Make 5.45x39 [CJ]",
            [2] = "ammomaker.Make .22 LR [CJ]",
            [3] = "ammomaker.Make 7.62x51 NATO [CJ]",
            [4] = "ammomaker.Make 7.62x39 [CJ]",
            [5] = "ammomaker.Make 7.62x54 R [CJ]",
            [6] = "ammomaker.Make .357 Mag [CJ]",
            [7] = "ammomaker.Recycle 5.45x39 [CJ]",
            [8] = "ammomaker.Recycle .22 LR [CJ]",
            [9] = "ammomaker.Recycle 7.62x51 NATO [CJ]",
            [10] = "ammomaker.Recycle 7.62x39 [CJ]",
            [11] = "ammomaker.Recycle 7.62x54 R [CJ]",
            [12] = "ammomaker.Recycle .357 Mag [CJ]",
            [13] = "ammomaker.Make Parts Bottleneck M Rim",
            [14] = "ammomaker.Make Parts Straight S Rim",
            [15] = "ammomaker.Recycle Parts Bottleneck M Rim",
            [16] = "ammomaker.Recycle Parts Straight S Rim",
        };

        recipesSetIsHidden(RecipeNamesCJShow, false);

    end

    if getActivatedMods():contains("CaptainJuezo1_WIP") then

        local RecipeNamesCJWIPShow = {
            [1] = "ammomaker.Make 9x39 [CJ]",
            [2] = "ammomaker.Make .50 BMG [CJ]",
            [3] = "ammomaker.Recycle 9x39 [CJ]",
            [4] = "ammomaker.Recycle .50 BMG [CJ]",
            [5] = "ammomaker.Make Parts Bottleneck L",
            [6] = "ammomaker.Recycle Parts Bottleneck L",
            [7] = "ammomaker.Recycle Casing 9mm Luger [CJ]",
        };

        recipesSetIsHidden(RecipeNamesCJWIPShow, false);

    end

    --ek2

    if getActivatedMods():contains("EscapeFromKentucky2") then

        local RecipeNamesEK2Show = {
            [2] = "ammomaker.Make 5.8x42mm [EK2]",
            [4] = "ammomaker.Make 7.62x39 [EK2]",
            [3] = "ammomaker.Make 8.6mm BLK [EK2]",
            [1] = "ammomaker.Make .50 BMG [EK2]",
            [5] = "ammomaker.Make 40mm HE [EK2]",
            [7] = "ammomaker.Recycle 5.8x42mm [EK2]",
            [9] = "ammomaker.Recycle 7.62x39 [EK2]",
            [8] = "ammomaker.Recycle 8.6mm BLK [EK2]",
            [6] = "ammomaker.Recycle .50 BMG [EK2]",
            [10] = "ammomaker.Recycle 40mm HE [EK2]",
            [11] = "ammomaker.Make Parts Bottleneck L",
            [12] = "ammomaker.Make Parts Grenade",
            [13] = "ammomaker.Recycle Parts Bottleneck L",
            [14] = "ammomaker.Recycle Parts Grenade",
        };

        local RecipeNamesEK2Hide = {
            [1] = "ammomaker.Make .223 Rem [Base]",
            [2] = "ammomaker.Make .308 Win [Base]",
            [3] = "ammomaker.Make .38 SP [Base]",
        };

        recipesSetIsHidden(RecipeNamesEK2Show, false);
        recipesSetIsHidden(RecipeNamesEK2Hide, true);

    end

    --fa

    if getActivatedMods():contains("firearmmod") then

        local RecipeNamesFAShow = {
            [1] = "ammomaker.Make .22 LR [FA]",
            [2] = "ammomaker.Make 7.62x51 NATO [FA]",
            [3] = "ammomaker.Make .30-06 Spring [FA]",
            [4] = "ammomaker.Make 7.62x39 [FA]",
            [5] = "ammomaker.Make .357 Mag [FA]",
            [6] = "ammomaker.Make .44-40 WCF [FA]",
            [7] = "ammomaker.Recycle .22 LR [FA]",
            [8] = "ammomaker.Recycle 7.62x51 NATO [FA]",
            [9] = "ammomaker.Recycle .30-06 Spring [FA]",
            [10] = "ammomaker.Recycle 7.62x39 [FA]",
            [11] = "ammomaker.Recycle .357 Mag [FA]",
            [12] = "ammomaker.Recycle .44-40 WCF [FA]",
            [13] = "ammomaker.Make Parts Straight S Rim",
            [14] = "ammomaker.Recycle Parts Straight S Rim",
        };

        recipesSetIsHidden(RecipeNamesFAShow, false);

    end

    --far

    if getActivatedMods():contains("firearmmodRevamp") then

        local RecipeNamesFARShow = {
            [1] = "ammomaker.Make .22 LR [FAR]",
            [2] = "ammomaker.Make 7.62x51 NATO [FAR]",
            [3] = "ammomaker.Make .30-06 Spring [FAR]",
            [4] = "ammomaker.Make 7.62x39 [FAR]",
            [5] = "ammomaker.Make .357 Mag [FAR]",
            [6] = "ammomaker.Make .44-40 WCF [FAR]",
            [7] = "ammomaker.Recycle .22 LR [FAR]",
            [8] = "ammomaker.Recycle 7.62x51 NATO [FAR]",
            [9] = "ammomaker.Recycle .30-06 Spring [FAR]",
            [10] = "ammomaker.Recycle 7.62x39 [FAR]",
            [11] = "ammomaker.Recycle .357 Mag [FAR]",
            [12] = "ammomaker.Recycle .44-40 WCF [FAR]",
            [13] = "ammomaker.Make Parts Straight S Rim",
            [14] = "ammomaker.Recycle Parts Straight S Rim",
        };
    
        recipesSetIsHidden(RecipeNamesFARShow, false);
    
    end

    --g93

    if getActivatedMods():contains("Guns93") then

        local RecipeNamesFAShow = {
            [1] = "ammomaker.Make .22 LR [G93]",
            [2] = "ammomaker.Make .25 ACP [G93]",
            [3] = "ammomaker.Make .30-30 Win [G93]",
            [4] = "ammomaker.Make .30 Carbine [G93]",
            [5] = "ammomaker.Make .30-06 Spring [G93]",
            [6] = "ammomaker.Make 7.62x39 [G93]",
            [7] = "ammomaker.Make 7.92x57 Maus [G93]",
            [8] = "ammomaker.Make .380 ACP [G93]",
            [9] = "ammomaker.Make .357 Mag [G93]",
            [10] = "ammomaker.Make 10mm Auto [G93]",
            [11] = "ammomaker.Make .40 S&W [G93]",
            [12] = "ammomaker.Make .45 LC [G93]",
            [13] = "ammomaker.Make 12 G Slug [G93]",
            [14] = "ammomaker.Recycle .22 LR [G93]",
            [15] = "ammomaker.Recycle .25 ACP [G93]",
            [16] = "ammomaker.Recycle .30-30 Win [G93]",
            [17] = "ammomaker.Recycle .30 Carbine [G93]",
            [18] = "ammomaker.Recycle .30-06 Spring [G93]",
            [19] = "ammomaker.Recycle 7.62x39 [G93]",
            [20] = "ammomaker.Recycle 7.92x57 Maus [G93]",
            [21] = "ammomaker.Recycle .380 ACP [G93]",
            [22] = "ammomaker.Recycle .357 Mag [G93]",
            [23] = "ammomaker.Recycle 10mm Auto [G93]",
            [24] = "ammomaker.Recycle .40 S&W [G93]",
            [25] = "ammomaker.Recycle .45 LC [G93]",
            [26] = "ammomaker.Recycle 12 G Slug [G93]",
            [27] = "ammomaker.Make Slug 12",
            [28] = "ammomaker.Make Parts Straight S Rim",
            [29] = "ammomaker.Recycle Slug 12",
            [30] = "ammomaker.Recycle Parts Straight S Rim",
        };

        recipesSetIsHidden(RecipeNamesFAShow, false);

    end

    --hfe

    if getActivatedMods():contains("HayesFirearmsExtension") then

        local RecipeNamesHFEShow = {
            [1] = "ammomaker.Make 5.45x39 [HFE]",
            [2] = "ammomaker.Make 5.7x28 [HFE]",
            [3] = "ammomaker.Make .22 LR [HFE]",
            [4] = "ammomaker.Make 7.62x51 NATO [HFE]",
            [5] = "ammomaker.Make .30-06 Spring [HFE]",
            [6] = "ammomaker.Make 7.62x39 [HFE]",
            [7] = "ammomaker.Make 7.62x54 R [HFE]",
            [8] = "ammomaker.Make 7.92x33 Kurz [HFE]",
            [9] = "ammomaker.Make 7.92x57 Maus [HFE]",
            [10] = "ammomaker.Make .380 ACP [HFE]",
            [11] = "ammomaker.Make 9x39 [HFE]",
            [12] = "ammomaker.Make .50 BMG [HFE]",
            [13] = "ammomaker.Make .58 Minie [HFE]",
            [14] = "ammomaker.Make 12 G Buck 00 [HFE]",
            [15] = "ammomaker.Make 12 G Slug [HFE]",
            [16] = "ammomaker.Recycle 5.45x39 [HFE]",
            [17] = "ammomaker.Recycle 5.7x28 [HFE]",
            [18] = "ammomaker.Recycle .22 LR [HFE]",
            [19] = "ammomaker.Recycle 7.62x51 NATO [HFE]",
            [20] = "ammomaker.Recycle .30-06 Spring [HFE]",
            [21] = "ammomaker.Recycle 7.62x39 [HFE]",
            [22] = "ammomaker.Recycle 7.62x54 R [HFE]",
            [23] = "ammomaker.Recycle 7.92x33 Kurz [HFE]",
            [24] = "ammomaker.Recycle 7.92x57 Maus [HFE]",
            [25] = "ammomaker.Recycle .380 ACP [HFE]",
            [26] = "ammomaker.Recycle 9x39 [HFE]",
            [27] = "ammomaker.Recycle .50 BMG [HFE]",
            [28] = "ammomaker.Recycle .58 Minie [HFE]",
            [29] = "ammomaker.Recycle 12 G Buck 00 [HFE]",
            [30] = "ammomaker.Recycle 12 G Slug [HFE]",
            [31] = "ammomaker.Recycle Blunderbuss Pellets [HFE]",
            [32] = "ammomaker.Make Parts Straight S Rim",
            [33] = "ammomaker.Make Parts Bottleneck M Rim",
            [34] = "ammomaker.Make Parts Bottleneck L",
            [35] = "ammomaker.Make Slug 12",
            [36] = "ammomaker.Recycle Parts Straight S Rim",
            [37] = "ammomaker.Recycle Parts Bottleneck M Rim",
            [38] = "ammomaker.Recycle Parts Bottleneck L",
            [39] = "ammomaker.Recycle Slug 12",
            [40] = "Base.Craft Crossbow Bolts",
            [41] = "Base.Craft Wood Crossbow Bolts",
            [42] = "Base.Craft Blunderbuss Ammo with Scrap Metal",
            [43] = "Base.Craft Blunderbuss Ammo with Nails",
            [44] = "Base.Craft Blunderbuss Ammo with Screws",
            [45] = "Base.Craft Blowgun Darts",
            [46] = "ammomaker.Make Bolt Wooden [HFE]",
            [47] = "ammomaker.Recycle Bolt [HFE]",
            [48] = "ammomaker.Recycle Bolt Wooden [HFE]",
            [49] = "ammomaker.Recycle Blowgun Darts [HFE]",
        };

        recipesSetIsHidden(RecipeNamesHFEShow, false);

    end

    --psa

    if getActivatedMods():contains("PRitemtest") then

        local RecipeNamesPSAShow = {
            [1] = "ammomaker.Make 5.45x39 [PSA]",
            [2] = "ammomaker.Make .22 LR [PSA]",
            [3] = "ammomaker.Make 7.62x25 Tok [PSA]",
            [4] = "ammomaker.Make 7.62x38 R Nag [PSA]",
            [5] = "ammomaker.Make 7.62x39 [PSA]",
            [6] = "ammomaker.Make 7.62x54 R [PSA]",
            [7] = "ammomaker.Make 9x39 [PSA]",
            [8] = "ammomaker.Make 9x18 Mak [PSA]",
            [9] = "ammomaker.Make 4 G Buck 00 [PSA]",
            [10] = "ammomaker.Recycle 5.45x39 [PSA]",
            [11] = "ammomaker.Recycle .22 LR [PSA]",
            [12] = "ammomaker.Recycle 7.62x25 Tok [PSA]",
            [13] = "ammomaker.Recycle 7.62x38 R Nag [PSA]",
            [14] = "ammomaker.Recycle 7.62x39 [PSA]",
            [15] = "ammomaker.Recycle 7.62x54 R [PSA]",
            [16] = "ammomaker.Recycle 9x39 [PSA]",
            [17] = "ammomaker.Recycle 9x18 Mak [PSA]",
            [18] = "ammomaker.Recycle 4 G Buck 00 [PSA]",
            [19] = "ammomaker.Make Parts Straight S Rim",
            [20] = "ammomaker.Make Hull Shotgun L",
            [21] = "ammomaker.Recycle Parts Straight S Rim",
            [22] = "ammomaker.Recycle Hull Shotgun L",
        };

        recipesSetIsHidden(RecipeNamesPSAShow, false);

    end

    --rf

    if getActivatedMods():contains("Real Firearms") then

        local RecipeNamesRFShow = {
            [1] = "ammomaker.Make 7.62x51 NATO [RF]",
            [2] = "ammomaker.Make .30-06 Spring [RF]",
            [3] = "ammomaker.Make 7.62x39 [RF]",
            [4] = "ammomaker.Make 7.62x54 R [RF]",
            [5] = "ammomaker.Make 7.92x57 Maus [RF]",
            [6] = "ammomaker.Make .357 Mag [RF]",
            [7] = "ammomaker.Make 9x18 Mak [RF]",
            [8] = "ammomaker.Recycle 7.62x51 NATO [RF]",
            [9] = "ammomaker.Recycle .30-06 Spring [RF]",
            [10] = "ammomaker.Recycle 7.62x39 [RF]",
            [11] = "ammomaker.Recycle 7.62x54 R [RF]",
            [12] = "ammomaker.Recycle 7.92x57 Maus [RF]",
            [13] = "ammomaker.Recycle .357 Mag [RF]",
            [14] = "ammomaker.Recycle 9x18 Mak [RF]",
            [15] = "ammomaker.Make Parts Bottleneck M Rim",
            [16] = "ammomaker.Recycle Parts Bottleneck M Rim",
        };
        
        recipesSetIsHidden(RecipeNamesRFShow, false);
        
    end

    --rfg

    if getActivatedMods():contains("RainsFirearmsandGunParts") or getActivatedMods():contains("RainsFirearmsandGunPartsApocalyPZe") then

        local RecipeNamesRFGShow = {
            [1] = "ammomaker.Make 7.62x51 NATO [RFG]",
            [2] = "ammomaker.Make 7.62x39 [RFG]",
            [3] = "ammomaker.Recycle 7.62x51 NATO [RFG]",
            [4] = "ammomaker.Recycle 7.62x39 [RFG]",
        };
        
        recipesSetIsHidden(RecipeNamesRFGShow, false);
        
    end

    --sg

    if getActivatedMods():contains("ScrapGuns(new version)") then

        local RecipeNamesSGShow = {
            [1] = "ammomaker.Recycle Salvaged Bullets [SG]",
            [2] = "ammomaker.Recycle Scrap Bullets [SG]",
            [3] = "ammomaker.Recycle Nail Bomb [SG]",
            [4] = "ammomaker.Recycle Glass Bomb [SG]",
            [5] = "ammomaker.Recycle Pipe Bomb [SG]",
            [6] = "ammomaker.Recycle Decoy [SG]",
            [7] = "SGuns.Make Salvaged Bullets",
            [8] = "SGuns.Make Scrap Bullets",
            [9] = "SGuns.Make Nail Bomb",
            [10] = "SGuns.Make Glass Bomb",
            [11] = "SGuns.Assemble Pipe Bomb",
            [12] = "SGuns.Make Decoy",
        };

        recipesSetIsHidden(RecipeNamesSGShow, false);

    end

    --sp

    if getActivatedMods():contains("Swatpack") then

        local RecipeNamesSPShow = {
            [1] = "ammomaker.Make 12 G Rubber [SP]",
            [2] = "ammomaker.Recycle 12 G Rubber [SP]",
            [3] = "ammomaker.Recycle Rubber"
        };

        recipesSetIsHidden(RecipeNamesSPShow, false);

    end

    --thc

    if getActivatedMods():contains("TIHFP") then

        local RecipeNamesTHCShow = {
            [1] = "ammomaker.Make .30 Carbine [TF]",
            [2] = "ammomaker.Make .30-06 Spring [TF]",
            [3] = "ammomaker.Make .303 British [TF]",
            [4] = "ammomaker.Make 9x18 Mak [TF]",
            [5] = "ammomaker.Recycle .30 Carbine [TF]",
            [6] = "ammomaker.Recycle .30-06 Spring [TF]",
            [7] = "ammomaker.Recycle .303 British [TF]",
            [8] = "ammomaker.Recycle 9x18 Mak [TF]",
            [9] = "ammomaker.Make Parts Bottleneck M Rim",
            [10] = "ammomaker.Recycle Parts Bottleneck M Rim",
        };

        recipesSetIsHidden(RecipeNamesTHCShow, false);

    end

    --thww2

    if getActivatedMods():contains("TIHFPWW2AF") then

        local RecipeNamesTHWW2Show = {
            [1] = "ammomaker.Make 6.5x50SR Aris [TF]",
            [2] = "ammomaker.Make 6.5x52 Carc [TF]",
            [3] = "ammomaker.Make 7.92x33 Kurz [TF]",
            [4] = "ammomaker.Make 7.92x57 Maus [TF]",
            [5] = "ammomaker.Make 9x25 Maus [TF]",
            [6] = "ammomaker.Recycle 6.5x50SR Aris [TF]",
            [7] = "ammomaker.Recycle 6.5x52 Carc [TF]",
            [8] = "ammomaker.Recycle 7.92x33 Kurz [TF]",
            [9] = "ammomaker.Recycle 7.92x57 Maus [TF]",
            [10] = "ammomaker.Recycle 9x25 Maus [TF]",
        };

        recipesSetIsHidden(RecipeNamesTHWW2Show, false);

    end

    --teb

    if getActivatedMods():contains("TEBFP") then

        local RecipeNamesTEBShow = {
            [1] = "ammomaker.Make 5.45x39 [TF]",
            [2] = "ammomaker.Make 7.62x54 R [TF]",
            [3] = "ammomaker.Make .32 ACP [TF]",
            [4] = "ammomaker.Recycle 5.45x39 [TF]",
            [5] = "ammomaker.Recycle 7.62x54 R [TF]",
            [6] = "ammomaker.Recycle .32 ACP [TF]",
        };

        recipesSetIsHidden(RecipeNamesTEBShow, false);

    end

    --tfr

    if getActivatedMods():contains("TIHFPA3R") then

        local RecipeNamesTFRShow = {
            [1] = "ammomaker.Make 7.5x54mm [TFR]",
            [2] = "ammomaker.Make 8x50mmR Lebel [TFR]",
            [3] = "ammomaker.Make .32 ACP [TFR]",
            [4] = "ammomaker.Make 8x27mmR Lebel [TFR]",
            [5] = "ammomaker.Recycle 7.5x54mm [TFR]",
            [6] = "ammomaker.Recycle 8x50mmR Lebel [TFR]",
            [7] = "ammomaker.Recycle .32 ACP [TFR]",
            [8] = "ammomaker.Recycle 8x27mmR Lebel [TFR]",
            [9] = "ammomaker.Make Parts Bottleneck M Rim",
            [10] = "ammomaker.Recycle Parts Bottleneck M Rim",
        };

        recipesSetIsHidden(RecipeNamesTFRShow, false);

    end

    --tac

    if getActivatedMods():contains("TFACP") then

        local RecipeNamesTACShow = {
            [1] = "ammomaker.Make 7.5x54mm [TAC]",
            [2] = "ammomaker.Make 7.62x54 R [TAC]",
            [3] = "ammomaker.Make 7.62x39 [TAC]",
            [4] = "ammomaker.Make 7.62x25 Tok [TAC]",
            [5] = "ammomaker.Recycle 7.5x54mm [TAC]",
            [6] = "ammomaker.Recycle 7.62x54 R [TAC]",
            [7] = "ammomaker.Recycle 7.62x39 [TAC]",
            [8] = "ammomaker.Recycle 7.62x25 Tok [TAC]",
            [9] = "ammomaker.Make Parts Bottleneck M Rim",
            [10] = "ammomaker.Recycle Parts Bottleneck M Rim",
        };

        recipesSetIsHidden(RecipeNamesTACShow, false);

    end

    --tpf

    if getActivatedMods():contains("PFF") then

        local RecipeNamesTPFShow = {
            [1] = "ammomaker.Make 7.5x54mm [TPF]",
            [2] = "ammomaker.Make 8x50mmR Lebel [TPF]",
            [3] = "ammomaker.Make .32 ACP [TPF]",
            [4] = "ammomaker.Make 8x27mmR Lebel [TPF]",
            [5] = "ammomaker.Recycle 7.5x54mm [TPF]",
            [6] = "ammomaker.Recycle 8x50mmR Lebel [TPF]",
            [7] = "ammomaker.Recycle .32 ACP [TPF]",
            [8] = "ammomaker.Recycle 8x27mmR Lebel [TPF]",
            [9] = "ammomaker.Make Parts Bottleneck M Rim",
            [10] = "ammomaker.Recycle Parts Bottleneck M Rim",
        };

        recipesSetIsHidden(RecipeNamesTPFShow, false);

    end

    --vfe

    if getActivatedMods():contains("VFExpansion1") then

        local RecipeNamesVFEShow = {
            [1] = "ammomaker.Make .22 LR [VFE]",
            [2] = "ammomaker.Make 7.62x39 [VFE]",
            [3] = "ammomaker.Recycle .22 LR [VFE]",
            [4] = "ammomaker.Recycle 7.62x39 [VFE]",
            [5] = "ammomaker.Make Parts Straight S Rim",
            [6] = "ammomaker.Recycle Parts Straight S Rim",
        };

        recipesSetIsHidden(RecipeNamesVFEShow, false);

    end

    --vfe2

    if getActivatedMods():contains("VFExpansion2") then

        local RecipeNamesVFE2Show = {
            [1] = "ammomaker.Make 5.45x39 [VFE]",
            [2] = "ammomaker.Recycle 5.45x39 [VFE]",
        };

        recipesSetIsHidden(RecipeNamesVFE2Show, false);

    end

    --gwp

    if getActivatedMods():contains("GunrunnersWeaponPack") then

        local RecipeNamesGWPShow = {
            [1] = "ammomaker.Make .357 Mag [GWP]",
            [2] = "ammomaker.Recycle .357 Mag [GWP]",
        };

        recipesSetIsHidden(RecipeNamesGWPShow, false);

    end

    --vfeid

    if getActivatedMods():contains("VFExpansion1ID") then

        local RecipeNamesVFEIDShow = {
            [1] = "ammomaker.Make .338 Lapua [VFE]",
            [2] = "ammomaker.Make .357 Mag [VFE]",
            [3] = "ammomaker.Recycle .338 Lapua [VFE]",
            [4] = "ammomaker.Recycle .357 Mag [VFE]",
            [5] = "ammomaker.Make Parts Bottleneck L",
            [6] = "ammomaker.Recycle Parts Bottleneck L",
        };

        recipesSetIsHidden(RecipeNamesVFEIDShow, false);

    end

    --vfesid

    if getActivatedMods():contains("VFExpansion2ID") then

        local RecipeNamesVFESIDShow = {
            [1] = "ammomaker.Make 5.45x39 [VFE]",
            [2] = "ammomaker.Make 7.62x25 Tok [VFE]",
            [3] = "ammomaker.Make 7.62x54 R [VFE]",
            [4] = "ammomaker.Make 9x39 [VFE]",
            [5] = "ammomaker.Make 9x18 Mak [VFE]",
            [6] = "ammomaker.Make 12.7x55 [VFE]",
            [7] = "ammomaker.Make 4 G Buck 00 [VFE]",
            [8] = "ammomaker.Recycle 5.45x39 [VFE]",
            [9] = "ammomaker.Recycle 7.62x25 Tok [VFE]",
            [10] = "ammomaker.Recycle 7.62x54 R [VFE]",
            [11] = "ammomaker.Recycle 9x39 [VFE]",
            [12] = "ammomaker.Recycle 9x18 Mak [VFE]",
            [13] = "ammomaker.Recycle 12.7x55 [VFE]",
            [14] = "ammomaker.Recycle 4 G Buck 00 [VFE]",
            [15] = "ammomaker.Make Parts Bottleneck M Rim",
            [16] = "ammomaker.Make Parts Straight L",
            [17] = "ammomaker.Make Hull Shotgun L",
            [18] = "ammomaker.Recycle Parts Bottleneck M Rim",
            [19] = "ammomaker.Recycle Parts Straight L",
            [20] = "ammomaker.Recycle Hull Shotgun L",
        };

        recipesSetIsHidden(RecipeNamesVFESIDShow, false);

    end

    --sc

    if getActivatedMods():contains("spentcasingsvfe") or getActivatedMods():contains("spentcasingsguns93") then

        local RecipeNamesSCShow = {
            [1] = "ammomaker.Recycle Casing .223 Rem [SC]",
            [2] = "ammomaker.Recycle Casing 5.56x45 NATO [SC]",
            [3] = "ammomaker.Recycle Casing .308 Win [SC]",
            [4] = "ammomaker.Recycle Casing 9mm Luger [SC]",
            [5] = "ammomaker.Recycle Casing .38 SP [SC]",
            [6] = "ammomaker.Recycle Casing .44 Mag [SC]",
            [7] = "ammomaker.Recycle Casing .45 ACP [SC]",
            [8] = "ammomaker.Recycle Hull 12 G Buck [SC]",
        };

        recipesSetIsHidden(RecipeNamesSCShow, false);

    end

    --scv vfe

    if getActivatedMods():contains("spentcasingsvfe") and getActivatedMods():contains("VFExpansion1") then

        local RecipeNamesSCVVFEShow = {
            [1] = "ammomaker.Recycle Casing 5.45x39 [SCV]",
            [2] = "ammomaker.Recycle Casing .22 LR [SCV]",
            [3] = "ammomaker.Recycle Casing 7.62x39 [SCV]",
        };

        recipesSetIsHidden(RecipeNamesSCVVFEShow, false);

    end

    --scv afr

    if getActivatedMods():contains("spentcasingsvfe") and (getActivatedMods():contains("AdditonalFirearmsR") or getActivatedMods():contains("AdditonalFirearmsR rebalance")) then

        local RecipeNamesSCVAFRShow = {
            [1] = "ammomaker.Recycle Casing 5.7x28 [SCV]",
            [2] = "ammomaker.Recycle Casing 7.62x51 NATO [SCV]",
        };

        recipesSetIsHidden(RecipeNamesSCVAFRShow, false);

    end

    --scv gwp

    if getActivatedMods():contains("spentcasingsvfe") and getActivatedMods():contains("GunrunnersWeaponPack") then

        local RecipeNamesSCVGWPShow = {
            [1] = "ammomaker.Recycle Casing .357 Mag [SCV]",
        };

        recipesSetIsHidden(RecipeNamesSCVGWPShow, false);

    end

    --scg g93

    if getActivatedMods():contains("spentcasingsguns93") and getActivatedMods():contains("Guns93") then

        local RecipeNamesSCGG93Show = {
            [1] = "ammomaker.Recycle Casing .22 LR [SCG]",
            [2] = "ammomaker.Recycle Casing .25 ACP [SCG]",
            [3] = "ammomaker.Recycle Casing .30-30 Win [SCG]",
            [4] = "ammomaker.Recycle Casing .30 Carbine [SCG]",
            [5] = "ammomaker.Recycle Casing .30-06 Spring [SCG]",
            [6] = "ammomaker.Recycle Casing 7.62x39 [SCG]",
            [7] = "ammomaker.Recycle Casing 7.92x57 Maus [SCG]",
            [8] = "ammomaker.Recycle Casing .380 ACP [SCG]",
            [9] = "ammomaker.Recycle Casing .357 Mag [SCG]",
            [10] = "ammomaker.Recycle Casing 10mm Auto [SCG]",
            [11] = "ammomaker.Recycle Casing .40 S&W [SCG]",
            [12] = "ammomaker.Recycle Casing .45 LC [SCG]",
            [13] = "ammomaker.Recycle Hull 12 G Slug [SCG]",
        };
    
        recipesSetIsHidden(RecipeNamesSCGG93Show, false);
    
    end

end

Events.OnGameStart.Add(ammoMakerRecipeManager);