--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: LitR (Literature - Recipe).
--
-- Both builds (see LitS for the auto-rule note). Commented out in the
-- original; migrated anyway.
--
-- B42 folded the `Radio` and `farming` modules into `Base`: the entries below
-- that carry both spellings, gated by build, are ONE item that was renamed —
-- not an item added and an item removed.
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- LITERATURE section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.LitR = {
    items = {
        "Base.CookingMag1",
        "Base.CookingMag2",
        "Base.ElectronicsMag1",
        "Base.ElectronicsMag2",
        "Base.ElectronicsMag3",
        "Base.ElectronicsMag4",
        "Base.ElectronicsMag5",
        "Base.EngineerMagazine1",
        "Base.EngineerMagazine2",
        "Base.FarmingMag1",
        "Base.FishingMag1",
        "Base.FishingMag2",
        "Base.HerbalistMag",
        "Base.HuntingMag1",
        "Base.HuntingMag2",
        "Base.HuntingMag3",
        "Base.MechanicMag1",
        "Base.MechanicMag2",
        "Base.MechanicMag3",
        "Base.MetalworkMag1",
        "Base.MetalworkMag2",
        "Base.MetalworkMag3",
        "Base.MetalworkMag4",
        { "Base.RadioMag1", only = "42" },
        { "Base.RadioMag2", only = "42" },
        { "Base.RadioMag3", only = "42" },
        { "Radio.RadioMag1", only = "41" },
        { "Radio.RadioMag2", only = "41" },
        { "Radio.RadioMag3", only = "41" },
    },
}
