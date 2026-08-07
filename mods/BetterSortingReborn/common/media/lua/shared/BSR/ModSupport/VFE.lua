--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: VFE (firearms expansion).
--
-- Covers:
--   VFExpansion1 (VFE)
--   — https://steamcommunity.com/sharedfiles/filedetails/?id=2667899942
--   VFExpansion2 (VFES)
--   — https://steamcommunity.com/sharedfiles/filedetails/?id=2893333090
--
-- Both Workshop items add guns in the Base module and share the same weapon
-- taxonomy, so they share one pack: none of the names below exists in vanilla
-- (they are added by the mods), so an inactive sibling costs nothing at boot.
--
-- 27 of the original's 92 lines re-state a mapping BSR's own Data/ tables
-- already make for vanilla items (Base.Shotgun, Base.AK47 attachments, the
-- vanilla scopes and magazines...); they are dropped here — Data/ covers them
-- whether or not the mod is active. 11 of the remaining items are also mapped
-- by "Arsenal-Brita (Brita)", to the same categories.
--
-- Mappings migrated from Better Sorting v2.0.4 (VFE_Items.lua).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "VFE",
    mods = { "VFExpansion1", "VFExpansion2" },
    data = {
        Ammo = {
            items = {
                "Base.22Box",
                "Base.22Bullets",
                "Base.762Box",
                "Base.762Bullets",
            },
        },
        Tool = {
            items = {
                "Base.CleaningKit",
                "Base.FireKlean",
                "Base.OilFilter",
                "Base.OilFilter2",
            },
        },
        WepAmmoMag = {
            items = {
                "Base.12Clip5",
                "Base.223Clip20",
                "Base.22ClipRifle",
                "Base.45Clip12",
                "Base.45Clip25",
                "Base.556box100",
                "Base.762Clip",
                "Base.762Clip10",
                "Base.762Clip102",
                "Base.762Clip103",
                "Base.762box100",
                "Base.939Clip10",
                "Base.9mmClip13",
                "Base.9mmClip17",
                "Base.9mmClip20",
                "Base.9mmClip30",
                "Base.9mmClip302",
                "Base.9mmClip8",
            },
        },
        WepFire = {
            items = {
                "Base.1022",
                "Base.AK47",
                "Base.AK47Folded",
                "Base.CAR15",
                "Base.CAR15D",
                "Base.Galil",
                "Base.Glock",
                "Base.HK416",
                "Base.LeverRifle",
                "Base.M249",
                "Base.MP153",
                "Base.MP153sawn",
                "Base.MP5",
                "Base.MP5SD",
                "Base.Makarov",
                "Base.Mini14",
                "Base.Mini14Folded",
                "Base.Mosin",
                "Base.P229",
                "Base.PKM",
                "Base.SKS",
                "Base.SV98",
                "Base.SVD",
                "Base.SVT40",
                "Base.Saiga12",
                "Base.ShotgunSawnoffNoStock",
                "Base.Spas12",
                "Base.Spas12Folded",
                "Base.Tec9",
                "Base.UMP45",
                "Base.USP45",
                "Base.VSS",
                "Base.Vityaz",
            },
        },
        WepPart = {
            items = {
                "Base.Bipod",
                "Base.Coupled556",
                "Base.Coupled762",
                "Base.OilFilterSuppressor",
                "Base.OilFilterSuppressor2",
                "Base.ShellHolder",
            },
        },
    },
})
