--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Last Call for Alcohol.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=1997978868
--
-- The mod's spirits, beers and wines, each in three states: the full bottle
-- (FoodA), the empty bottle it leaves behind (Container) and the water-filled
-- one (FoodB). The two beer cans go to Junk once emptied, as upstream.
--
-- Mappings migrated from Better Sorting v2.0.4 (LastCall_Items.lua), with the
-- original's "Cont" key remapped to "Container".
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "LastCall",
    mods = { "LCFAV2" },
    data = {
        Container = {
            items = {
                "CCS.AbsintheEmpty",
                "CCS.BourbonEmpty",
                "CCS.BrandyEmpty",
                "CCS.ChampangneEmpty",
                "CCS.CognacEmpty",
                "CCS.GinEmpty",
                "CCS.MoonshineEmpty",
                "CCS.RumEmpty",
                "CCS.SakeEmpty",
                "CCS.SojuEmpty",
                "CCS.TequilaEmpty",
                "CCS.TripleSecEmpty",
                "CCS.VodkaEmpty",
                "CCS.WhiskeyBlackLabelEmpty",
                "CCS.WhiteWineEmpty",
            },
        },
        FoodA = {
            items = {
                "CCS.AbsintheFull",
                "CCS.Beer",
                "CCS.BeerCanSixPack",
                "CCS.BourbonFull",
                "CCS.BrandyFull",
                "CCS.ChampangneFull",
                "CCS.CognacFull",
                "CCS.DarkBeer",
                "CCS.DarkBeerCanSixPack",
                "CCS.GinFull",
                "CCS.MoonshineFull",
                "CCS.RumFull",
                "CCS.SakeFull",
                "CCS.SojuFull",
                "CCS.TequilaFull",
                "CCS.TripleSecFull",
                "CCS.VodkaFull",
                "CCS.WhiskeyBlackLabelFull",
                "CCS.WhiteWineFull",
            },
        },
        FoodB = {
            items = {
                "CCS.AbsintheWaterFull",
                "CCS.BourbonBottleWater",
                "CCS.BrandyBottleWater",
                "CCS.ChampangneBottleWater",
                "CCS.CognacBottleWater",
                "CCS.GinWaterFull",
                "CCS.MoonshineBottleWater",
                "CCS.RumBottleWater",
                "CCS.SakeWaterFull",
                "CCS.SojuWaterFull",
                "CCS.TequilaBottleWater",
                "CCS.TripleSecBottleWater",
                "CCS.VodkaVodka",
                "CCS.WhiskeyBlackLabelBottleWater",
                "CCS.WhiteWineBottleWater",
            },
        },
        Junk = {
            items = {
                "CCS.BeerCanEmpty",
                "CCS.DarkBeerCanEmpty",
            },
        },
    },
})
