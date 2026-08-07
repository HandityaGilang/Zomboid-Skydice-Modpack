--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Easy Packing.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2438225189
--
-- Bulk packs of vanilla items (Packing.*), sorted like the item they bundle:
-- ammo boxes to Ammo, crafting stacks to the Craft* keys, six-packs to the Food*
-- keys, and so on.
--
-- The original's single guard also covers the ammo and hardcore variants, so all
-- three mod IDs are kept on one pack. Its GidOrganized.* / GidOrganizedFood.*
-- lines belong to a DIFFERENT Workshop mod (Gid's Organized Storage, shipped in
-- the OGSN Orphanage pack); they are kept as upstream wrote them, which makes 23
-- items overlap with "OGSN (Orphanage)". All but one map to the same category in
-- both packs; GidOrganizedFood.OS4pkCoffee is Cook here and FoodB there, and with
-- both mods active the later pack name wins (FoodB).
--
-- Mappings migrated from Better Sorting v2.0.4 (EasyPacking_Items.lua), with the
-- original's "Cont" key remapped to "Container".
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "EasyPacking",
    mods = { "EasyPacking", "EasyPackingAmmo", "EasyPackingHC" },
    data = {
        Ammo = {
            items = {
                "Packing.10pk223",
                "Packing.10pk308",
                "Packing.10pk38",
                "Packing.10pk44",
                "Packing.10pk45",
                "Packing.10pk556",
                "Packing.10pk9",
                "Packing.10pkShotgun",
                "Packing.5pk223",
                "Packing.5pk308",
                "Packing.5pk38",
                "Packing.5pk44",
                "Packing.5pk45",
                "Packing.5pk556",
                "Packing.5pk9",
                "Packing.5pkShotgun",
            },
        },
        Clean = {
            items = {
                "Packing.10pkSoap",
                "Packing.5pkSoap",
            },
        },
        Container = {
            items = {
                "GidOrganizedFood.OS12pkWineEmpty",
                "GidOrganizedFood.OS12pkWineEmpty2",
                "GidOrganizedFood.OS24pkWaterBottleEmpty",
                "GidOrganizedFood.OS8pkWhiskeyEmpty",
                "Packing.10pkSheetRopeEmptyPetrolCan",
                "Packing.5pkSheetRopeEmptyPetrolCan",
            },
        },
        Cook = {
            items = {
                "GidOrganizedFood.OS4pkCoffee",
            },
        },
        Craft = {
            items = {
                "GidOrganizedFood.OS4pkDuctTape",
                "Packing.10pkBarbedWire",
                "Packing.10pkBattery",
                "Packing.10pkGarbage",
                "Packing.10pkGlue",
                "Packing.10pkNailsBox",
                "Packing.10pkRope",
                "Packing.10pkRopeBranch",
                "Packing.10pkRopePropaneTank",
                "Packing.10pkScrewsBox",
                "Packing.10pkSheetRope",
                "Packing.10pkSheetRopeBranch",
                "Packing.10pkSheetRopePropaneTank",
                "Packing.10pkTwine",
                "Packing.10pkWire",
                "Packing.10pkWoodGlue",
                "Packing.5pkBarbedWire",
                "Packing.5pkBattery",
                "Packing.5pkGarbage",
                "Packing.5pkGlue",
                "Packing.5pkNailsBox",
                "Packing.5pkRope",
                "Packing.5pkRopeBranch",
                "Packing.5pkRopePropaneTank",
                "Packing.5pkScrewsBox",
                "Packing.5pkSheetRope",
                "Packing.5pkSheetRopeBranch",
                "Packing.5pkSheetRopePropaneTank",
                "Packing.5pkTwine",
                "Packing.5pkWire",
                "Packing.5pkWoodGlue",
            },
        },
        CraftCarp = {
            items = {
                "Packing.10pkRopePlank",
                "Packing.10pkSheetRopePlank",
                "Packing.5pkRopePlank",
                "Packing.5pkSheetRopePlank",
            },
        },
        CraftElec = {
            items = {
                "Packing.100pkElectronicsScrap",
                "Packing.10pkElectricWire",
                "Packing.10pkElectronicsScrap",
                "Packing.50pkElectronicsScrap",
                "Packing.5pkElectricWire",
            },
        },
        CraftMetal = {
            items = {
                "Packing.10pkMetalBar",
                "Packing.10pkMetalPipe",
                "Packing.10pkRopeMetalBar",
                "Packing.10pkRopeMetalPipe",
                "Packing.10pkRopeSheetMetal",
                "Packing.10pkScrapMetal",
                "Packing.10pkSheetMetal",
                "Packing.10pkSheetMetalSmall",
                "Packing.10pkSheetRopeMetalBar",
                "Packing.10pkSheetRopeMetalPipe",
                "Packing.10pkSheetRopeSheetMetal",
                "Packing.10pkWeldingRods",
                "Packing.5pkMetalBar",
                "Packing.5pkMetalPipe",
                "Packing.5pkRopeMetalBar",
                "Packing.5pkRopeMetalPipe",
                "Packing.5pkRopeSheetMetal",
                "Packing.5pkScrapMetal",
                "Packing.5pkSheetMetal",
                "Packing.5pkSheetMetalSmall",
                "Packing.5pkSheetRopeMetalBar",
                "Packing.5pkSheetRopeMetalPipe",
                "Packing.5pkSheetRopeSheetMetal",
                "Packing.5pkWeldingRods",
            },
        },
        CraftTailor = {
            items = {
                "Packing.100pkDenim",
                "Packing.100pkLeather",
                "Packing.100pkRag",
                "Packing.10pkDenim",
                "Packing.10pkLeather",
                "Packing.10pkRag",
                "Packing.10pkThread",
                "Packing.50pkDenim",
                "Packing.50pkLeather",
                "Packing.50pkRag",
                "Packing.5pkThread",
            },
        },
        Drugs = {
            items = {
                "Packing.20pkCigarettes",
            },
        },
        FoodA = {
            items = {
                "Packing.10pkRedWine",
                "Packing.10pkWhiskey",
                "Packing.10pkWhiteWine",
                "Packing.5pkRedWine",
                "Packing.5pkWhiskey",
                "Packing.5pkWhiteWine",
                "Packing.6pkBeer",
                "Packing.6pkBeerCan",
            },
        },
        FoodB = {
            items = {
                "GidOrganizedFood.OS24pkWaterBottleFull",
                "GidOrganizedFood.OS6pkFizz",
                "GidOrganizedFood.OS6pkPop",
                "GidOrganizedFood.OS6pkPopDiet",
                "Packing.10pkOrangeSoda",
                "Packing.5pkOrangeSoda",
            },
        },
        FoodN = {
            items = {
                "GidOrganizedFood.OS4pkSardines",
                "GidOrganizedFood.OS6pkCannedBeans",
                "GidOrganizedFood.OS6pkCannedBolognese",
                "GidOrganizedFood.OS6pkCannedCarrots",
                "GidOrganizedFood.OS6pkCannedChili",
                "GidOrganizedFood.OS6pkCannedCorn",
                "GidOrganizedFood.OS6pkCannedCornedBeef",
                "GidOrganizedFood.OS6pkCannedMushSoup",
                "GidOrganizedFood.OS6pkCannedPeas",
                "GidOrganizedFood.OS6pkCannedPotato",
                "GidOrganizedFood.OS6pkCannedSoup",
                "GidOrganizedFood.OS6pkCannedTomato",
                "GidOrganizedFood.OS8pkCannedTuna",
                "Packing.6pkCannedFruitBeverage",
                "Packing.6pkCannedFruitCocktail",
                "Packing.6pkCannedMilk",
                "Packing.6pkCannedPeaches",
                "Packing.6pkCannedPineapple",
                "Packing.6pkDogFood",
            },
        },
        LitE = {
            items = {
                "Packing.10pkBook",
                "Packing.10pkMagazine",
                "Packing.10pkNewspaper",
                "Packing.5pkBook",
                "Packing.5pkMagazine",
                "Packing.5pkNewspaper",
            },
        },
        LitS = {
            items = {
                "Packing.pkCarpentry",
                "Packing.pkCooking",
                "Packing.pkElectricity",
                "Packing.pkFarming",
                "Packing.pkFirstaid",
                "Packing.pkFishing",
                "Packing.pkForaging",
                "Packing.pkMechanics",
                "Packing.pkMetalwork",
                "Packing.pkTailoring",
                "Packing.pkTrapping",
            },
        },
        LitW = {
            items = {
                "Packing.10pkBluePen",
                "Packing.10pkNotebook",
                "Packing.10pkPen",
                "Packing.10pkPencil",
                "Packing.10pkRedPen",
                "Packing.10pkSheetPaper",
                "Packing.5pkBluePen",
                "Packing.5pkNotebook",
                "Packing.5pkPen",
                "Packing.5pkPencil",
                "Packing.5pkRedPen",
                "Packing.5pkSheetPaper",
            },
        },
        Mech = {
            items = {
                "Packing.10pkRopeEmptyPetrolCan",
                "Packing.10pkRopePetrolCan",
                "Packing.10pkSheetRopePetrolCan",
                "Packing.5pkRopeEmptyPetrolCan",
                "Packing.5pkRopePetrolCan",
                "Packing.5pkSheetRopePetrolCan",
            },
        },
        Med = {
            items = {
                "GidOrganized.OS12pkAdhesiveBandages",
                "GidOrganized.OS12pkCottonBalls",
                "GidOrganized.OS30pkAlcoholWipes",
                "GidOrganized.OS30pkAntibiotics",
                "GidOrganized.OS4pkDisinfectant",
                "GidOrganized.OS50pkAntidepressants",
                "GidOrganized.OS50pkBetaBlockers",
                "GidOrganized.OS50pkPainkillers",
                "GidOrganized.OS50pkSleepingPills",
                "GidOrganized.OS50pkVitamins",
                "GidOrganized.OS9pkBandages",
                "GidOrganized.OS9pkBandagesDirty",
                "GidOrganized.OS9pkSterileBandages",
                "Packing.10pkTissue",
                "Packing.4pkToiletPaper",
                "Packing.5pkTissue",
            },
        },
        SurFish = {
            items = {
                "Packing.10pkFishingLine",
                "Packing.10pkFishingNet",
                "Packing.5pkFishingLine",
                "Packing.5pkFishingNet",
            },
        },
        Tool = {
            items = {
                "Packing.10pkLighter",
                "Packing.10pkMatches",
                "Packing.5pkLighter",
                "Packing.5pkMatches",
            },
        },
    },
})
