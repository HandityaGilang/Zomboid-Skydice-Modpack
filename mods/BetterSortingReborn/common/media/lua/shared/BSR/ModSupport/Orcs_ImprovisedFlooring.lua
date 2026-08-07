--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Improvised Flooring.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2790428261
--
-- One of four independent Workshop mods bundled in the original's
-- Orcs_Items.lua, one guard each. They ship as four packs so each block keeps
-- the exact scope the original gave it (each mod declares its items in its own
-- module, and only the mod that owns them should re-sort them).
--
-- Mappings migrated from Better Sorting v2.0.4 (Orcs_Items.lua).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "Orcs (Improvised Flooring)",
    mods = { "ImprovisedFlooring", "ImprovisedFlooringPlus" },
    data = {
        LitR = {
            items = {
                "ImprovisedFlooring.IFMagazineEasterEgg",
                "ImprovisedFlooring.IFMagazineFranchise",
                "ImprovisedFlooring.IFMagazineGarden",
                "ImprovisedFlooring.IFMagazineIndustrial",
                "ImprovisedFlooring.IFMagazineTiles",
                "ImprovisedFlooring.IFMagazineUrban",
            },
        },
    },
})
