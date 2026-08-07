--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Vac's Drinks.
-- Beer cans -> Food - Alcohol, sodas and energy drinks -> Food - Beverage,
-- every empty can or bottle -> Junk.
--
-- Covers:
--   VacsDrinks (VDK) — https://steamcommunity.com/sharedfiles/filedetails/?id=2689863681
--
-- Mappings migrated from Better Sorting (VacsDrinks_Items.lua). The
-- water-filled vodka bottle is FoodB and the sealed one FoodA, as upstream.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "VacsDrinks",
    mods = { "VDK" },
    data = {
        FoodA = {
            items = {
                "VDK.VAC_Bottle_AbsolutVodkaFull",
                "VDK.VAC_Can_BlueMoon",
                "VDK.VAC_Can_BlueRibbon",
                "VDK.VAC_Can_Budlight",
                "VDK.VAC_Can_Budweiser",
                "VDK.VAC_Can_CoorsLight",
                "VDK.VAC_Can_CoronaExtra",
                "VDK.VAC_Can_Heineken",
                "VDK.VAC_Can_Karhu",
                "VDK.VAC_Can_LongDrink",
                "VDK.VAC_Can_MillerLite",
                "VDK.VAC_Can_Modelo",
            },
        },
        FoodB = {
            items = {
                "VDK.VAC_Bottle_AbsolutVodkaWaterFull",
                "VDK.VAC_Can_5HourEnergyDrink",
                "VDK.VAC_Can_Burn",
                "VDK.VAC_Can_CocaCola",
                "VDK.VAC_Can_DietCoke",
                "VDK.VAC_Can_DietPepsi",
                "VDK.VAC_Can_DrPepper",
                "VDK.VAC_Can_Fanta",
                "VDK.VAC_Can_Monster",
                "VDK.VAC_Can_MountainDew",
                "VDK.VAC_Can_MugRootBeer",
                "VDK.VAC_Can_Nos",
                "VDK.VAC_Can_Pepsi",
                "VDK.VAC_Can_RedBull",
                "VDK.VAC_Can_Rockstar",
                "VDK.VAC_Can_Sprite",
            },
        },
        Junk = {
            items = {
                "VDK.VAC_5HourEnergyDrink_BeerCanEmpty",
                "VDK.VAC_BlueMoon_BeerCanEmpty",
                "VDK.VAC_BlueRibbon_BeerCanEmpty",
                "VDK.VAC_Bottle_AbsolutVodkaEmpty",
                "VDK.VAC_Budlight_BeerCanEmpty",
                "VDK.VAC_Budweiser_BeerCanEmpty",
                "VDK.VAC_Burn_BeerCanEmpty",
                "VDK.VAC_CocaCola_BeerCanEmpty",
                "VDK.VAC_CoorsLight_BeerCanEmpty",
                "VDK.VAC_CoronaExtra_BeerCanEmpty",
                "VDK.VAC_DietCoke_BeerCanEmpty",
                "VDK.VAC_DietPepsi_BeerCanEmpty",
                "VDK.VAC_DrPepper_BeerCanEmpty",
                "VDK.VAC_Fanta_BeerCanEmpty",
                "VDK.VAC_Heineken_BeerCanEmpty",
                "VDK.VAC_Karhu_BeerCanEmpty",
                "VDK.VAC_LongDrink_BeerCanEmpty",
                "VDK.VAC_MillerLite_BeerCanEmpty",
                "VDK.VAC_Modelo_BeerCanEmpty",
                "VDK.VAC_Monster_BeerCanEmpty",
                "VDK.VAC_MountainDew_BeerCanEmpty",
                "VDK.VAC_MugRootBeer_BeerCanEmpty",
                "VDK.VAC_Nos_BeerCanEmpty",
                "VDK.VAC_Pepsi_BeerCanEmpty",
                "VDK.VAC_RedBull_BeerCanEmpty",
                "VDK.VAC_Rockstar_BeerCanEmpty",
                "VDK.VAC_Sprite_BeerCanEmpty",
            },
        },
    },
})
