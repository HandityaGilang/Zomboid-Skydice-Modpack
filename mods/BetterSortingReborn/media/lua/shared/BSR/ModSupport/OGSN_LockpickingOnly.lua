--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: OGSN — Lockpicking Only.
-- The two lockpicking magazines -> Literature - Recipe, the bobby pins -> Tool.
--
-- Covers:
--   LockpickingOnly (LockpickingOnly) — https://steamcommunity.com/sharedfiles/filedetails/?id=2056238799
--
-- The original bundles several unrelated Workshop items in one file
-- (OGSN_Items.lua); they are split here into one pack per Workshop item, so
-- each mod only re-sorts its own items (several of those blocks touch
-- Base-module items that also exist in vanilla B42).
--
-- Mappings migrated from Better Sorting (OGSN_Items.lua).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "OGSN (Lockpicking Only)",
    mods = { "LockpickingOnly" },
    data = {
        LitR = {
            items = {
                "FMJ.LockPickingMag",
                "FMJ.LockPickingMag2",
            },
        },
        Tool = {
            items = {
                "FMJ.BobbyPin",
                "FMJ.BobbyPinRaw",
            },
        },
    },
})
