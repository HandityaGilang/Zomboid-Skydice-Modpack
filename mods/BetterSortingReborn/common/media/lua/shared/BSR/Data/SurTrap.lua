--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: SurTrap (Survival - Trapping).
--
-- Both builds. Custom key. BaconBits only moved module in B42 (see below);
-- it is kept in Trapping, as bait, following the original's grouping.
--
-- B42 folded the `Radio` and `farming` modules into `Base`: the entries below
-- that carry both spellings, gated by build, are ONE item that was renamed —
-- not an item added and an item removed.
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- SURVIVAL section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.SurTrap = {
    items = {
        { "Base.BaconBits", only = "42" },
        "Base.TrapBox",
        "Base.TrapCage",
        "Base.TrapCrate",
        "Base.TrapMouse",
        "Base.TrapSnare",
        "Base.TrapStick",
        { "farming.BaconBits", only = "41" },
    },
}
