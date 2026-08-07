--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Corner Store (candies and sodas).
-- Every bottle and can -> Food - Beverage.
--
-- Covers:
--   CornerStoreCandiesAndSodas (2412050672 — this mod's ID is its Workshop ID)
--   — https://steamcommunity.com/sharedfiles/filedetails/?id=2412050672
--
-- Mappings migrated from Better Sorting (CornerStore_Items.lua). The 30 candy
-- and crisps lines are commented out upstream and deliberately not migrated:
-- the generic non-perishable food rule already sorts them.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "CornerStore",
    mods = { "2412050672" },
    data = {
        FoodB = {
            items = {
                "CCS.DrPeppaCan",
                "CCS.DrPepppa",
                "CCS.FantoGrapeCan",
                "CCS.FantoOrange",
                "CCS.FantoOrangeCan",
                "CCS.FantoPurple",
                "CCS.FantoRed",
                "CCS.FantoRedCan",
                "CCS.GingerAle",
                "CCS.GingerAleCan",
                "CCS.Haterade",
                "CCS.HateradeBl",
                "CCS.HateradeWh",
                "CCS.HateradeYl",
                "CCS.LemonLime",
                "CCS.LemonLimeCan",
                "CCS.MootinDiw",
                "CCS.MootinDiwCan",
                "CCS.MootinDiwQ",
                "CCS.MootinDiwQCan",
                "CCS.Pepso",
                "CCS.PepsoCan",
                "CCS.RCCan",
                "CCS.RedDeath",
                "CCS.RokaCola",
                "CCS.RokaColaCan",
                "CCS.RootBeer",
                "CCS.RootBeerCan",
                "CCS.YF",
                "CCS.YFCan",
                "CCS.minichugBL",
                "CCS.minichugOr",
                "CCS.minichugPi",
            },
        },
    },
})
