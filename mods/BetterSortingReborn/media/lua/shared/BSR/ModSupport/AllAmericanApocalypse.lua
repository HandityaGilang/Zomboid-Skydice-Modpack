--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: All American Apocalypse.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2026187681
--
-- Cooking-focused food mod. The original left ~90 of its lines commented
-- out (the perishable/non-perishable auto rules already sort those
-- prepared foods); only the active lines are migrated here.
--
-- The two TPaste.* items belong to another mod but sat under this guard in
-- the original; they are kept as-is (the guard decides, and items of an
-- absent mod are skipped at boot).
--
-- Mappings migrated from Better Sorting v2.0.4
-- (AllAmericanApocalypse_Items.lua), with the original's "Cont" key
-- remapped to "Container".
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "AllAmericanApocalypse",
    mods = { "AAApoc" },
    data = {
        Container = {
            items = {
                "AAApoc.AAAEmptyIceTray",
                "AAApoc.AAAEmptyJar",
            },
        },
        Cook = {
            items = {
                "AAApoc.AAABreadingBowl",
                "AAApoc.AAABreadingMix",
                "AAApoc.AAABurgerBunPan",
                "AAApoc.AAABurgerBunPanPrepRaw",
                "AAApoc.AAAButterPot",
                "AAApoc.AAACheeseGrater",
                "AAApoc.AAACheesePowder",
                "AAApoc.AAACheeseWheelChdr",
                "AAApoc.AAAChiliDogPrep",
                "AAApoc.AAACornbreadPrep",
                "AAApoc.AAACorndogRaw",
                "AAApoc.AAACorndogStick",
                "AAApoc.AAAEggBeater",
                "AAApoc.AAAFrenchFrySlicer",
                "AAApoc.AAAGelatinBoxApple",
                "AAApoc.AAAGelatinBoxBanana",
                "AAApoc.AAAGelatinBoxBerry",
                "AAApoc.AAAGelatinBoxCherry",
                "AAApoc.AAAGelatinBoxChocolate",
                "AAApoc.AAAGelatinBoxGrape",
                "AAApoc.AAAGelatinBoxLemon",
                "AAApoc.AAAGelatinBoxOrange",
                "AAApoc.AAAGelatinBoxPineapple",
                "AAApoc.AAAGelatinBoxVanilla",
                "AAApoc.AAAGelatinMix",
                "AAApoc.AAAGelatinPrepApple",
                "AAApoc.AAAGelatinPrepBanana",
                "AAApoc.AAAGelatinPrepBerry",
                "AAApoc.AAAGelatinPrepCherry",
                "AAApoc.AAAGelatinPrepChocolate",
                "AAApoc.AAAGelatinPrepGrape",
                "AAApoc.AAAGelatinPrepLemon",
                "AAApoc.AAAGelatinPrepOrange",
                "AAApoc.AAAGelatinPrepPineapple",
                "AAApoc.AAAGelatinPrepVanilla",
                "AAApoc.AAAHeavyCreamPowder",
                "AAApoc.AAAHomemadeGelatin",
                "AAApoc.AAAHotDogBunPan",
                "AAApoc.AAAHotDogBunPanPrepRaw",
                "AAApoc.AAAHotDogCasings",
                "AAApoc.AAAHotDogPrep",
                "AAApoc.AAAIntestines",
                "AAApoc.AAAJarOfCherries",
                "AAApoc.AAAJarOfHeavyCream",
                "AAApoc.AAAMeatGrinder",
                "AAApoc.AAAMilkPowder",
                "AAApoc.AAAPancakeMixHMade",
                "AAApoc.AAAWaffleIron",
                "TPaste.TPasteBSoda",
            },
        },
        FoodB = {
            items = {
                "AAApoc.AAAFullIceTrayIce",
                "AAApoc.AAAFullIceTrayWater",
                "AAApoc.AAAIceCube",
                "AAApoc.AAAIceCubeMelted",
                "AAApoc.AAAJarOfMilk",
                "AAApoc.AAAPlasticIceBag",
            },
        },
        Junk = {
            items = {
                "AAApoc.AAABreadingMixEmpty",
                "AAApoc.AAACoffeeCreamerEmpty",
                "AAApoc.AAACookieDoughEmpty",
                "AAApoc.AAACreamOfTartarEmpty",
                "AAApoc.AAAEmptyMacBox",
                "AAApoc.AAAFoodDyes",
                "AAApoc.AAAFoodDyesEmpty",
                "AAApoc.AAAGelatinBoxAppleEmpty",
                "AAApoc.AAAGelatinBoxBananaEmpty",
                "AAApoc.AAAGelatinBoxBerryEmpty",
                "AAApoc.AAAGelatinBoxCherryEmpty",
                "AAApoc.AAAGelatinBoxChocolateEmpty",
                "AAApoc.AAAGelatinBoxGrapeEmpty",
                "AAApoc.AAAGelatinBoxLemonEmpty",
                "AAApoc.AAAGelatinBoxOrangeEmpty",
                "AAApoc.AAAGelatinBoxPineappleEmpty",
                "AAApoc.AAAGelatinBoxVanillaEmpty",
                "AAApoc.AAAGelatinMixEmpty",
                "AAApoc.AAAHeavyCreamPowderEmpty",
                "AAApoc.AAAJarOfAJellyEmpty",
                "AAApoc.AAAJarOfCherriesEmpty",
                "AAApoc.AAAJarOfGJellyEmpty",
                "AAApoc.AAAJarOfPicklesEmpty",
                "AAApoc.AAAMilkPowderEmpty",
                "AAApoc.AAAVanillaExtractEmpty",
                "AAApoc.AAAWhippedCreamEmpty",
                "TPaste.TPasteBSodaEmpty",
            },
        },
    },
})
