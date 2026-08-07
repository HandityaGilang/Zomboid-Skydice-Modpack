--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: The Workshop.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2680473910
--
-- One of five independent Workshop mods bundled in the original's
-- DJVirus_Items.lua, one guard each. They ship as five packs so each
-- block keeps the exact scope the original gave it: The Workshop's block
-- re-categorizes the VANILLA Base.LeadPipe, which must not move when only
-- a sibling mod is installed.
--
-- `overrides`: Base.LeadPipe (vanilla, Data/ has WepMelee) -> CraftMetal —
-- the mod turns lead pipes into a smelting input. Reverts to WepMelee
-- when the mod is absent.
--
-- Mappings migrated from Better Sorting v2.0.4 (DJVirus_Items.lua),
-- with the original's "Cont" key remapped to "Container".
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "DJVirus (The Workshop)",
    mods = { "TheWorkshop(new version)" },
    overrides = {
        CraftMetal = {
            items = {
                "Base.LeadPipe",
            },
        },
    },
    data = {
        ClothAcc = {
            items = {
                "Base.Toolbelt",
            },
        },
        Craft = {
            items = {
                "TW.AirTank",
                "TW.AxeHead",
                "TW.BoxLargeBolts",
                "TW.BoxScrews",
                "TW.Chain",
                "TW.ForkHead",
                "TW.GolfClubHead",
                "TW.GunParts",
                "TW.HammerHead",
                "TW.HoeHead",
                "TW.HugePropaneTank",
                "TW.LargeBolt",
                "TW.LargePropaneTank",
                "TW.LongBlade",
                "TW.MeatCleaverHead",
                "TW.MetalWorkbench",
                "TW.Motor",
                "TW.PickaxeHead",
                "TW.PropaneGasFurnace",
                "TW.RakeHead",
                "TW.ScytheHead",
                "TW.ShovelHead",
                "TW.SledgeHammerHead",
                "TW.SmallBlade",
                "TW.SmallMetalBar",
                "TW.Spring",
            },
        },
        CraftMetal = {
            items = {
                "TW.MetalBarMold",
                "TW.MetalParts",
                "TW.MetalPipeMold",
                "TW.SmallMetalSheetMold",
            },
        },
        LitR = {
            items = {
                "TW.WorkshopMag1",
                "TW.WorkshopMag2",
                "TW.WorkshopMag3",
                "TW.WorkshopMag4",
                "TW.WorkshopMag5",
            },
        },
        Tool = {
            items = {
                "Base.CordlessDrill",
                "Base.NailGun",
                "Base.NailGunMagazine",
                "TW.File",
                "TW.MetalCutter",
                "TW.Pliers",
            },
        },
    },
})
