--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Keytool.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2266521599
--
-- One of four independent Workshop mods bundled in the original's
-- Planetalgol_Items.lua, one guard each. They ship as four packs so each
-- block keeps the exact scope the original gave it: Advanced GEAR's block
-- re-categorizes item names that are VANILLA in build 42 (Base.Canteen,
-- Base.Multitool, Base.P38, Base.WaterPurificationTablets — mod-added back
-- when the original was written), which must not move when only a sibling
-- mod is installed.
--
-- Mappings migrated from Better Sorting v2.0.4 (Planetalgol_Items.lua),
-- with the original's "Cont" key remapped to "Container".
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "Planetalgol (Keytool)",
    mods = { "Keytool" },
    data = {
        ClothAcc = {
            items = {
                "Keytool.KeyRing",
            },
        },
    },
})
