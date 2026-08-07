--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Scrap Guns.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2125659488
--
-- One of five independent Workshop mods bundled in the original's
-- DJVirus_Items.lua, one guard each. They ship as five packs so each
-- block keeps the exact scope the original gave it: The Workshop's block
-- re-categorizes the VANILLA Base.LeadPipe, which must not move when only
-- a sibling mod is installed.
--
-- Mappings migrated from Better Sorting v2.0.4 (DJVirus_Items.lua),
-- with the original's "Cont" key remapped to "Container".
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "DJVirus (Scrap Guns)",
    mods = { "ScrapGuns(new version)" },
    data = {
        Ammo = {
            items = {
                "SGuns.MetalScraps",
                "SGuns.SBBox",
                "SGuns.SBullets",
                "SGuns.SSBox",
                "SGuns.ScrapBBox",
                "SGuns.ScrapBullets",
                "SGuns.ShrapnelShell",
            },
        },
        LitR = {
            items = {
                "SGuns.ScrapGunMag1",
                "SGuns.ScrapGunMag2",
                "SGuns.ScrapGunMag3",
                "SGuns.ScrapGunMag4",
            },
        },
        WepAmmoMag = {
            items = {
                "SGuns.GatlingBoxMagazine",
                "SGuns.HRMagazine",
                "SGuns.SSMGMagazine",
                "SGuns.ScrapPistolMagazine",
                "SGuns.ScrapSMGMagazine",
            },
        },
        WepBomb = {
            items = {
                "SGuns.GlassBomb",
                "SGuns.HD",
                "SGuns.HPB",
                "SGuns.NailBomb",
            },
        },
        WepFire = {
            items = {
                "SGuns.HDBS",
                "SGuns.HP",
                "SGuns.HPS",
                "SGuns.HR",
                "SGuns.HRB",
                "SGuns.SAR",
                "SGuns.SARB",
                "SGuns.SARBO",
                "SGuns.SSMGFolded",
                "SGuns.SSMGUnfolded",
                "SGuns.SSR",
                "SGuns.ScrapGatling",
                "SGuns.ScrapPistol",
                "SGuns.ScrapSMG",
                "SGuns.SlamFire",
            },
        },
        WepRange = {
            items = {
                "SGuns.TBottle",
            },
        },
    },
})
