--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: CraftCarp (Crafting - Carpentry).
--
-- Applies on both builds. B42 vanilla files these under "Material"; the
-- carpentry-crafting bucket keeps them distinct on both builds. Items absent
-- from B42 scripts are marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- CRAFTING section — Carpentry).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.CraftCarp = {
    items = {
        "Base.BarbedWire",
        "Base.Drawer",
        "Base.Log",
        "Base.LogStacks2",
        "Base.LogStacks3",
        "Base.LogStacks4",
        "Base.Plank",
        "Base.Tarp",
        { "Base.WoodenStick", only = "41" },
        { "camping.TentPeg", only = "41" },
    },
}
