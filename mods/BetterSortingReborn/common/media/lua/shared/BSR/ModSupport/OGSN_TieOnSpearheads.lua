--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: OGSN — Tie-On Spearheads.
-- The mod's chipped-stone spear (a Base-module item of its own) -> Weapon - Melee.
--
-- Covers (one guard, three mod IDs, in the original):
--   TieOnSpearheads / TieOnSpearheads_MP / TieOnSpearheads_Crafting
--   — https://steamcommunity.com/sharedfiles/filedetails/?id=2036922754
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
    name = "OGSN (Tie-On Spearheads)",
    mods = { "TieOnSpearheads", "TieOnSpearheads_MP", "TieOnSpearheads_Crafting" },
    data = {
        WepMelee = {
            items = {
                "Base.SpearChippedStone",
            },
        },
    },
})
