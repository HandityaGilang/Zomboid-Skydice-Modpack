--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: FoodB (Food - Beverage).
--
-- Applies on both builds: FoodB is more specific than vanilla B42's
-- generic Food/Water/WaterContainer buckets, so it stays valuable on
-- both. Items renamed or removed in B42 42.19 (the many water-filled
-- container variants and B41-era names) are marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- FOOD section — beverages).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.FoodB = {
    items = {
        { "Base.BeerWaterFull", only = "41" },
        { "Base.BucketWaterFull", only = "41" },
        { "Base.Coffee", only = "41" },
        { "Base.ColdCuppa", only = "41" },
        { "Base.ColdDrinkRed", only = "41" },
        { "Base.ColdDrinkSpiffo", only = "41" },
        { "Base.ColdDrinkWhite", only = "41" },
        { "Base.FullKettle", only = "41" },
        "Base.HotDrink",
        "Base.HotDrinkRed",
        "Base.HotDrinkSpiffo",
        "Base.HotDrinkTea",
        "Base.HotDrinkWhite",
        "Base.JuiceBox",
        { "Base.Mugfull", only = "41" },
        "Base.Pop",
        "Base.Pop2",
        "Base.Pop3",
        "Base.PopBottle",
        { "Base.Teabag", only = "41" },
        "Base.Teabag2",
        { "Base.WaterBleachBottle", only = "41" },
        { "Base.WaterBottleFull", only = "41" },
        { "Base.WaterBowl", only = "41" },
        { "Base.WaterMug", only = "41" },
        { "Base.WaterMugRed", only = "41" },
        { "Base.WaterMugSpiffo", only = "41" },
        { "Base.WaterMugWhite", only = "41" },
        { "Base.WaterPaintbucket", only = "41" },
        { "Base.WaterPopBottle", only = "41" },
        { "Base.WaterTeacup", only = "41" },
        { "Base.WhiskeyWaterFull", only = "41" },
        { "Base.WineWaterFull", only = "41" },
        { "farming.MayonnaiseWaterFull", only = "41" },
        { "farming.RemouladeWaterFull", only = "41" },
    },
}
