--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: DLTS (food preservation & crafting).
-- https://steamcommunity.com/sharedfiles/filedetails/?id=1962914415
--
-- Drying racks, stacks, preserved food and the crafting chain that goes with
-- them. The mod's "stack" items follow the category of what they stack.
--
-- Mappings migrated from Better Sorting v2.0.4 (DLTS_Items.lua), with the
-- original's "Cont" key remapped to "Container".
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "DLTS",
    mods = { "DLTS" },
    data = {
        Container = {
            items = {
                "DLTS.LTSBoxBlank",
                "DLTS.LTSBoxBlue",
                "DLTS.LTSBoxGray",
                "DLTS.LTSBoxGreen",
                "DLTS.LTSBoxPurple",
                "DLTS.LTSBoxRed",
                "DLTS.LTSBoxYellow",
                "DLTS.LTSChemEmpty",
                "DLTS.LTSDryingFruit",
                "DLTS.LTSDryingFruitWet",
                "DLTS.LTSDryingHerbs",
                "DLTS.LTSDryingHerbsWet",
                "DLTS.LTSDryingMeat",
                "DLTS.LTSDryingMeatWet",
                "DLTS.LTSDryingMushroom",
                "DLTS.LTSDryingMushroomWet",
                "DLTS.LTSDryingVegetable",
                "DLTS.LTSDryingVegetableWet",
                "DLTS.LTSStorageCellar00",
                "DLTS.LTSStorageCellar01",
                "DLTS.LTSStorageCellar02",
                "DLTS.LTSStorageCellar03",
                "DLTS.LTSStorageCellar04",
                "DLTS.LTSStorageCellar05",
                "DLTS.LTSStorageCellar06",
                "DLTS.LTSStorageCellar07",
                "DLTS.LTSStorageCellar08",
                "DLTS.LTSStorageCellar09",
                "DLTS.LTSStorageCellar10",
                "DLTS.LTSWaterCanEmpty",
            },
        },
        Cook = {
            items = {
                "DLTS.LTSCamomille",
                "DLTS.LTSClingWrap",
                "DLTS.LTSDandelion",
                "DLTS.LTSPropaneTankEmpty",
                "DLTS.LTSSaltDry",
                "DLTS.LTSSaltWet",
                "DLTS.LTSSeasoningFruit",
                "DLTS.LTSSeasoningHerbs",
                "DLTS.LTSSeasoningMushroom",
                "DLTS.LTSStackCamomille",
                "DLTS.LTSStackDandelion",
                "DLTS.LTSStackHoneyComb",
                "DLTS.LTSSugarWet",
                "DLTS.LTSYeastDry",
                "DLTS.LTSYeastWet",
            },
        },
        CookB = {
            items = {
                "DLTS.LTSFermentingJuiceOld",
                "DLTS.LTSFermentingJuiceYoung",
                "DLTS.LTSFermentingVinegar",
                "DLTS.LTSFermentingWine",
            },
        },
        Craft = {
            items = {
                "DLTS.LTSBirchBark",
                "DLTS.LTSCharcoalPowder",
                "DLTS.LTSGlueMixture",
                "DLTS.LTSLimestone",
                "DLTS.LTSPineCone",
                "DLTS.LTSPineTar",
                "DLTS.LTSQuicklime",
                "DLTS.LTSScrapPlastic",
                "DLTS.LTSStackBirchBark",
                "DLTS.LTSStackCharcoalPowder",
                "DLTS.LTSStackDoorknob",
                "DLTS.LTSStackHinge",
                "DLTS.LTSStackLimestone",
                "DLTS.LTSStackPineCone",
                "DLTS.LTSStackScrapPlastic",
                "DLTS.LTSStackSharpedStone",
                "DLTS.LTSStackStone",
                "DLTS.LTSStackTreeBranch",
                "DLTS.LTSStackTwigs",
                "DLTS.LTSStackWoodAsh",
                "DLTS.LTSStackWoodBits",
                "DLTS.LTSWoodAsh",
                "DLTS.LTSWoodBits",
            },
        },
        CraftCarp = {
            items = {
                "DLTS.LTSStackLog",
                "DLTS.LTSStackPlank",
            },
        },
        CraftElec = {
            items = {
                "DLTS.LTSStackElectronicsScrap",
            },
        },
        CraftMetal = {
            items = {
                "DLTS.LTSStackMetalBar",
                "DLTS.LTSStackMetalPipe",
                "DLTS.LTSStackScrapMetal",
                "DLTS.LTSStackSheetMetal",
                "DLTS.LTSStackSmallSheetMetal",
            },
        },
        CraftTailor = {
            items = {
                "DLTS.LTSRecycledThread",
            },
        },
        Drugs = {
            items = {
                "DLTS.LTSStackTobacco",
                "DLTS.LTSTobacco",
                "DLTS.LTSTobaccoLeaves",
                "DLTS.LTSTobaccoLeavesWet",
            },
        },
        FoodA = {
            items = {
                "DLTS.LTSFruitWine",
                "DLTS.LTSMoonshine",
                "DLTS.LTSMoonshineDrink",
            },
        },
        FoodB = {
            items = {
                "DLTS.LTSStackTeaServingBirch",
                "DLTS.LTSStackTeaServingFruit",
                "DLTS.LTSStackTeaServingHerbs",
                "DLTS.LTSTeaServingBirch",
                "DLTS.LTSTeaServingFruit",
                "DLTS.LTSTeaServingHerbs",
                "DLTS.LTSWaterCanFilled",
            },
        },
        FoodN = {
            items = {
                "DLTS.LTSDriedFruit",
                "DLTS.LTSDriedHerbs",
                "DLTS.LTSDriedMeat",
                "DLTS.LTSDriedMushroom",
                "DLTS.LTSDriedVegetable",
                "DLTS.LTSHoneyBar",
                "DLTS.LTSHoneyCandyEnergy",
                "DLTS.LTSHoneyCandyFruit",
                "DLTS.LTSHoneyCandyHealing",
                "DLTS.LTSHoneyComb",
                "DLTS.LTSPickledVegetable",
                "DLTS.LTSPickledVegetableWet",
                "DLTS.LTSStackCockroach",
                "DLTS.LTSStackCricket",
                "DLTS.LTSStackDriedFruit",
                "DLTS.LTSStackDriedHerbs",
                "DLTS.LTSStackDriedMeat",
                "DLTS.LTSStackDriedMushroom",
                "DLTS.LTSStackDriedVegetable",
                "DLTS.LTSStackGrapeLeaves",
                "DLTS.LTSStackGrasshopper",
                "DLTS.LTSStackHoneyBar",
                "DLTS.LTSStackHoneyCandyEnergy",
                "DLTS.LTSStackHoneyCandyFruit",
                "DLTS.LTSStackHoneyCandyHealing",
                "DLTS.LTSStackRosehips",
                "DLTS.LTSStackViolets",
                "DLTS.LTSStackWildNuts",
                "DLTS.LTSStackWorm",
                "DLTS.LTSSugarDry",
                "DLTS.LTSWildNuts",
                "DLTS.LTSWildOnion",
            },
        },
        FoodP = {
            items = {
                "DLTS.LTSBitsFruit",
                "DLTS.LTSBitsHerbs",
                "DLTS.LTSBitsMeat",
                "DLTS.LTSBitsMushroom",
                "DLTS.LTSBitsVegetable",
            },
        },
        LitS = {
            items = {
                "DLTS.LTSWorkbookElectricity",
                "DLTS.LTSWorkbookTailoring",
                "DLTS.LTSWorkbookWelding",
                "DLTS.LTSWorkbookWood",
            },
        },
        Mech = {
            items = {
                "DLTS.LTSCarParts",
                "DLTS.LTSCarTools",
            },
        },
        Med = {
            items = {
                "DLTS.LTSStackBlackSage",
                "DLTS.LTSStackComfrey",
                "DLTS.LTSStackCommonMallow",
                "DLTS.LTSStackGinseng",
                "DLTS.LTSStackLemonGrass",
                "DLTS.LTSStackPlantain",
                "DLTS.LTSStackWildGarlic",
            },
        },
        SurCamp = {
            items = {
                "DLTS.LTSBriquette",
                "DLTS.LTSStackBriquette",
                "DLTS.LTSUsedLiterature",
            },
        },
        SurFarm = {
            items = {
                "DLTS.LTSCorpseFlesh",
            },
        },
        Tool = {
            items = {
                "DLTS.LTSDryingRackEmpty",
                "DLTS.LTSLighterEmpty",
                "DLTS.LTSLighterFluid",
                "DLTS.LTSReplacementHandle",
                "DLTS.LTSScrappingSaw",
                "DLTS.LTSSharpeningStone",
                "DLTS.LTSWoodBurner",
            },
        },
        WepMelee = {
            items = {
                "DLTS.LTSBatBarbed",
                "DLTS.LTSBatHardened",
                "DLTS.LTSBatSpiked",
            },
        },
    },
})
