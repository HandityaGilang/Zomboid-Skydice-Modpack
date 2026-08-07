--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: OGSN Orphanage.
-- One Workshop item, five mod IDs: the dairy and wild-food add-ons, Organized
-- Storage (bulk medical/food packs) and Rod's Store (glassware, bar drinks,
-- kitchenware, bags).
--
-- Covers:
--   ForkMJdairy, ForkMJfoodWild, ForkMJjarMeat, OGSN_Orphan_OrganizedStorage,
--   OGSN_Orphan_RodsStore — https://steamcommunity.com/sharedfiles/filedetails/?id=2079001985
--
-- The original bundles several unrelated Workshop items in one file
-- (OGSN_Items.lua); they are split here into one pack per Workshop item, so
-- each mod only re-sorts its own items (several of those blocks touch
-- Base-module items that also exist in vanilla B42).
--
-- Mappings migrated from Better Sorting (OGSN_Items.lua), with the original's
-- "Cont" key remapped to "Container". Rod's Store's four backpacks use the key
-- "ClothB" upstream, which is not a category in the original either; they are
-- remapped by item type to ClothBack. The 91 commented-out food lines (plus the
-- entirely commented ForkMJjarMeat block) are deliberately not migrated: the
-- perishable/non-perishable rule already sorts them.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "OGSN (Orphanage)",
    mods = { "ForkMJdairy", "ForkMJfoodWild", "ForkMJjarMeat", "OGSN_Orphan_OrganizedStorage", "OGSN_Orphan_RodsStore" },
    data = {
        Clean = {
            items = {
                "RS.DishWashingLiquid",
            },
        },
        ClothBack = {
            items = {
                "RS.AliceBackpack",
                "RS.HikingBackpack",
                "RS.MolleBackpack",
                "RS.NormalBackpack",
            },
        },
        Container = {
            items = {
                "GidOrganizedFood.OS12pkWineEmpty",
                "GidOrganizedFood.OS12pkWineEmpty2",
                "GidOrganizedFood.OS24pkWaterBottleEmpty",
                "GidOrganizedFood.OS8pkWhiskeyEmpty",
                "RS.BeerBottleEmpty",
                "RS.Briefcase",
                "RS.Glass",
                "RS.LunchBox",
                "RS.RockGlass",
                "RS.ShotGlass",
                "RS.SmallLeatherBag",
                "RS.SodaBottleEmpty",
                "RS.Suitcase",
            },
        },
        Cook = {
            items = {
                "Base.Strainer",
                "RS.MetalBowl",
            },
        },
        Craft = {
            items = {
                "GidOrganizedFood.OS4pkDuctTape",
                "RS.GlassPanel",
                "RS.ShardsOfBrokenGlass",
            },
        },
        FoodB = {
            items = {
                "GidOrganizedFood.OS24pkWaterBottleFull",
                "GidOrganizedFood.OS4pkCoffee",
                "GidOrganizedFood.OS6pkFizz",
                "GidOrganizedFood.OS6pkPop",
                "GidOrganizedFood.OS6pkPopDiet",
                "RS.Aguaardiente",
                "RS.Beer1",
                "RS.Beer2",
                "RS.Beer3",
                "RS.BeerSixPack1",
                "RS.BeerSixPack2",
                "RS.BeerSixPack3",
                "RS.Beercan1",
                "RS.Beercan2",
                "RS.Beercan3",
                "RS.Beercan4",
                "RS.Cachaza",
                "RS.CoffeeLiquor",
                "RS.DryVermouth",
                "RS.Ginebra",
                "RS.Rum",
                "RS.SodaBottle",
                "RS.TripleSec",
                "RS.Vodka",
                "RS.WaterGlass",
                "RS.WaterMetalBowl",
                "RS.WaterRockGlass",
                "RS.WaterShotGlass",
                "RS.WaterSodaBottle",
                "RS.WhiteRum",
                "RS.WhiteTequila",
            },
        },
        Junk = {
            items = {
                "RS.BabyFormula",
                "RS.BakingMold",
                "RS.BarSqueezer",
                "RS.BeerCanEmpty",
                "RS.ChoppingBoard",
                "RS.CocktailSpoon",
                "RS.CookieMold",
                "RS.DirtyPlate",
                "RS.EmptyMediumTuperware",
                "RS.EmptySmallTuperware",
                "RS.FryingBasket",
                "RS.Grater",
                "RS.Icecubes",
                "RS.IcecubesMelted",
                "RS.MargaritaGlass",
                "RS.MartiniGlass",
                "RS.MilkPowder",
                "RS.MilkPowder2",
                "RS.PileOfPlates",
                "RS.PizzaTray",
                "RS.Plasticicebag",
                "RS.PlasticicebagMelted",
                "RS.Plate",
                "RS.Shaker",
                "RS.SmallGlassBottle",
                "RS.SoySauce",
                "RS.Squeezer",
                "RS.Stir",
                "RS.Strainer",
                "RS.WoodenSpoon",
            },
        },
        LitR = {
            items = {
                "Base.DairyCookingMag",
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
                "RS.Aloe",
                "RS.AloeCataplasm",
            },
        },
        Misc = {
            items = {
                "FMJ.QRollUps",
                "FMJ.RollUps",
                "FMJ.Tobacco",
            },
        },
        SurCamp = {
            items = {
                "FMJ.BirchBark",
            },
        },
        WepMelee = {
            items = {
                "RS.ButcherKnife",
                "RS.CombatKnife",
                "RS.GardeningScissors",
                "RS.ImprovisedShardOfBrokenGlassWeapon",
                "RS.KnuckleKnife",
                "RS.Machete",
                "RS.PoliceKnife",
                "RS.Wok",
            },
        },
    },
})
