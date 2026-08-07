--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: Clean (Cleaning).
--
-- Applies on both builds: vanilla B42 lumps these under "Household".
-- Items that were renamed or removed in B42 are marked only = "41"
-- (BleachEmpty/CleaningLiquid/Soap do not exist in 42.19 scripts).
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- CLEANING section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.Clean = {
    items = {
        "Base.BathTowel",
        "Base.BathTowelWet",
        "Base.Bleach",
        { "Base.BleachEmpty", only = "41" },
        { "Base.CleaningLiquid", only = "41" },
        "Base.CleaningLiquid2",
        "Base.DishCloth",
        "Base.DishClothWet",
        "Base.Mop",
        { "Base.Soap", only = "41" },
        "Base.Soap2",
    },
}
