--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: FoodA (Food - Alcohol).
--
-- Applies on both builds: FoodA is more specific than vanilla B42's
-- generic Food category, so it stays valuable on both. Items renamed or
-- removed in B42 42.19 are marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- FOOD section — alcohol).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.FoodA = {
    items = {
        { "Base.Beer", only = "41" },
        { "Base.Beer2", only = "41" },
        "Base.BeerBottle",
        "Base.BeerCan",
        "Base.BeerCanPack",
        "Base.BeerPack",
        { "Base.WhiskeyFull", only = "41" },
        "Base.Wine",
        "Base.Wine2",
        { "Base.WineInGlass", only = "41" },
    },
}
