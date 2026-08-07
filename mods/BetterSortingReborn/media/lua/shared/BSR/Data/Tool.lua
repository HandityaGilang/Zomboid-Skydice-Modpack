--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: Tool.
--
-- Applies on both builds. Reuses the vanilla "Tool" key. On B42 vanilla
-- scatters these across ToolWeapon, LightSource, FireSource, Household,
-- VehicleMaintenance, GardeningWeapon and more (only 6/45 are already "Tool"),
-- so consolidating them under Tool is a genuine refinement on B42, not a
-- relabel. Items absent from B42 scripts are marked only = "41".
--
-- B42 folded the `Radio` and `farming` modules into `Base`: the entries below
-- that carry both spellings, gated by build, are ONE item that was renamed —
-- not an item added and an item removed.
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- TOOLS section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.Tool = {
    items = {
        "Base.BallPeenHammer",
        "Base.Bellows",
        "Base.BlowTorch",
        "Base.BottleOpener",
        "Base.BottleOpener_Keychain",
        "Base.Candle",
        "Base.CandleLit",
        "Base.CarBatteryCharger",
        "Base.Crowbar",
        "Base.Extinguisher",
        "Base.GardenSaw",
        "Base.GardeningSprayAphids",
        { "Base.GardeningSprayCigarettes", only = "42" },
        { "Base.GardeningSprayEmpty", only = "42" },
        { "Base.GardeningSprayMilk", only = "42" },
        "Base.Hammer",
        "Base.HammerStone",
        { "Base.HandShovel", only = "42" },
        "Base.HandTorch",
        "Base.Jack",
        "Base.Lighter",
        "Base.LugWrench",
        "Base.Matches",
        "Base.MortarPestle",
        "Base.Needle",
        "Base.P38",
        "Base.PipeWrench",
        "Base.Saw",
        "Base.Scissors",
        "Base.Screwdriver",
        "Base.Scythe",
        "Base.ScytheForged",
        "Base.SheetRope",
        "Base.Shovel",
        "Base.Shovel2",
        "Base.Sledgehammer",
        "Base.Sledgehammer2",
        "Base.SlugRepellent",
        { "Base.Spanner", only = "41" },
        "Base.TinOpener",
        "Base.TirePump",
        "Base.Torch",
        { "Base.Umbrella", only = "41" },
        "Base.UmbrellaBlack",
        "Base.UmbrellaBlue",
        "Base.UmbrellaRed",
        "Base.UmbrellaWhite",
        { "Base.WateredCan", only = "42" },
        "Base.WeldingMask",
        "Base.Wrench",
        { "farming.GardeningSprayCigarettes", only = "41" },
        { "farming.GardeningSprayEmpty", only = "41" },
        { "farming.GardeningSprayFull", only = "41" },
        { "farming.GardeningSprayMilk", only = "41" },
        { "farming.HandShovel", only = "41" },
        { "farming.WateredCan", only = "41" },
        { "farming.WateredCanFull", only = "41" },
    },
}
