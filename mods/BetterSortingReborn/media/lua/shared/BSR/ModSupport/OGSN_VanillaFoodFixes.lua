--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: OGSN — Vanilla Food Fixes.
-- Herbal teas and teabags -> Food - Beverage, the dried medicinal herbs -> Medical.
--
-- Covers (one guard, two mod IDs, in the original):
--   VFFogsn / VFFogsn_herbsNoRot — https://steamcommunity.com/sharedfiles/filedetails/?id=2072147750
--
-- The original bundles several unrelated Workshop items in one file
-- (OGSN_Items.lua); they are split here into one pack per Workshop item, so
-- each mod only re-sorts its own items (several of those blocks touch
-- Base-module items that also exist in vanilla B42).
-- That split matters most here: some of these Base-module names (e.g.
-- CommonMallowDried, WildGarlicDried) also exist in vanilla 42.19, so the
-- mapping must stay scoped to this mod. No Data/ table owns any of them, so they
-- are plain `data` entries rather than `overrides`.
--
-- Mappings migrated from Better Sorting (OGSN_Items.lua); the 5 commented-out
-- upstream lines (cooked dishes, dried petals) are not migrated.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "OGSN (Vanilla Food Fixes)",
    mods = { "VFFogsn", "VFFogsn_herbsNoRot" },
    data = {
        FoodB = {
            items = {
                "Base.Tea_BlackSage",
                "Base.Tea_CommonMallow",
                "Base.Tea_Energizing",
                "Base.Tea_Ginseng",
                "Base.Tea_LemonGrass",
                "Base.Tea_Medicinal",
                "Base.Teabag_Energizing",
                "Base.Teabag_EnergizingDried",
                "Base.Teabag_Medicinal",
                "Base.Teabag_MedicinalDried",
            },
        },
        Med = {
            items = {
                "Base.BlackSageDried",
                "Base.CommonMallowDried",
                "Base.GinsengDried",
                "Base.LemonGrassDried",
                "Base.PlantainDried",
                "Base.WildGarlicDried",
            },
        },
    },
})
