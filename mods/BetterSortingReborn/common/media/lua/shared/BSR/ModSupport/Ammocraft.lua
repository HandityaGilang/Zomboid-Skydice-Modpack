--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Ammocraft.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2245813444
--
-- Mappings migrated from Better Sorting (Ammocraft_Items.lua): 77 lines, no
-- repeats -> 77 items. The mod declares its casings, tips, primers, moulds and
-- reloading literature in the Base module, but they are mod items: none of them
-- appears in the vanilla tables under Data/, so they all belong in `data` and
-- no `overrides` entry is needed. The single exception is Base.Pliers, a real
-- 42.19 vanilla item (DisplayCategory = Tool) that BSR's own tables do not map
-- -- the pack's Tool mapping matches vanilla, and only applies with the mod on.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "Ammocraft",
    mods = { "ammocraft", "ammocraftfirearms" },
    data = {
        CraftAmmo = {
            items = {
                "Base.223Bullets_casing",
                "Base.223Bullets_casing_spent",
                "Base.223Bullets_casing_spent_noprimer",
                "Base.223Bullets_casingbox",
                "Base.223Bullets_tip",
                "Base.223Bullets_tipbox",
                "Base.308Bullets_casing",
                "Base.308Bullets_casing_spent",
                "Base.308Bullets_casing_spent_noprimer",
                "Base.308Bullets_casingbox",
                "Base.308Bullets_tip",
                "Base.308Bullets_tipbox",
                "Base.38BulletsMold",
                "Base.44BulletsMold",
                "Base.45BulletsMold",
                "Base.556BulletsMold",
                "Base.556Bullets_casing",
                "Base.556Bullets_casing_spent",
                "Base.556Bullets_casing_spent_noprimer",
                "Base.556Bullets_casingbox",
                "Base.556Bullets_tip",
                "Base.556Bullets_tipbox",
                "Base.Bullets38_casing",
                "Base.Bullets38_casing_spent",
                "Base.Bullets38_casing_spent_noprimer",
                "Base.Bullets38_casingbox",
                "Base.Bullets38_tip",
                "Base.Bullets38_tipbox",
                "Base.Bullets44_casing",
                "Base.Bullets44_casing_spent",
                "Base.Bullets44_casing_spent_noprimer",
                "Base.Bullets44_casingbox",
                "Base.Bullets44_tip",
                "Base.Bullets44_tipbox",
                "Base.Bullets45_casing",
                "Base.Bullets45_casing_spent",
                "Base.Bullets45_casing_spent_noprimer",
                "Base.Bullets45_casingbox",
                "Base.Bullets45_tip",
                "Base.Bullets45_tipbox",
                "Base.Bullets9mm_casing",
                "Base.Bullets9mm_casing_spent",
                "Base.Bullets9mm_casing_spent_noprimer",
                "Base.Bullets9mm_casingbox",
                "Base.Bullets9mm_tip",
                "Base.Bullets9mm_tipbox",
                "Base.GunpowderJar",
                "Base.LP_Primers",
                "Base.LP_Primers_Spent",
                "Base.LP_Primers_box",
                "Base.Lead",
                "Base.R_Primers",
                "Base.R_Primers_Spent",
                "Base.R_Primers_box",
                "Base.SG_Primers",
                "Base.SG_Primers_Spent",
                "Base.SG_Primers_box",
                "Base.SP_Primers",
                "Base.SP_Primers_Spent",
                "Base.SP_Primers_box",
                "Base.Saltpeter",
                "Base.ShotgunShells_casing",
                "Base.ShotgunShells_casing_spent",
                "Base.ShotgunShells_casing_spent_noprimer",
                "Base.ShotgunShells_casingbox",
                "Base.ShotgunShells_tip",
                "Base.ShotgunShells_tipbox",
                "Base.Sulfur",
            },
        },
        LitR = {
            items = {
                "Base.GunnutBible",
                "Base.GunnutMonthly1",
                "Base.GunnutMonthly2",
                "Base.GunnutMonthly3",
                "Base.GunnutMonthly4",
                "Base.GunnutMonthly5",
                "Base.GunnutMonthly6",
            },
        },
        Tool = {
            items = {
                "Base.Pliers",
                "Base.Reloadingpress",
            },
        },
    },
})
