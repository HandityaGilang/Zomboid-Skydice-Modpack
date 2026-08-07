--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: Fuel.
--
-- Applies on both builds. "Fuel" is a custom key with no vanilla equivalent
-- (B42 files the surviving PetrolCan under VehicleMaintenance), so it adds a
-- dedicated fuel header on both builds. 5 of the 6 items are the old
-- petrol-in-a-bottle variants removed in B42, marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- FUEL section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.Fuel = {
    items = {
        { "Base.PetrolBleachBottle", only = "41" },
        "Base.PetrolCan",
        { "Base.PetrolPopBottle", only = "41" },
        { "Base.WaterBottlePetrol", only = "41" },
        { "Base.WhiskeyPetrol", only = "41" },
        { "Base.WinePetrol", only = "41" },
    },
}
