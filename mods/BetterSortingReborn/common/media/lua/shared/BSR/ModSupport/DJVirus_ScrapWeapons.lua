--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Scrap Weapons.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2122265954
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
    name = "DJVirus (Scrap Weapons)",
    mods = { "ScrapWeapons(new version)" },
    data = {
        LitR = {
            items = {
                "SWeapons.WeaponMag1",
                "SWeapons.WeaponMag2",
                "SWeapons.WeaponMag3",
                "SWeapons.WeaponMag4",
                "SWeapons.WeaponMag5",
                "SWeapons.WeaponMag6",
            },
        },
        WepMelee = {
            items = {
                "SWeapons.2x4",
                "SWeapons.2x4Bolt",
                "SWeapons.2x4Can",
                "SWeapons.2x4Nail",
                "SWeapons.2x4SScrewdriver",
                "SWeapons.2x4Scissors",
                "SWeapons.2x4Screwdriver",
                "SWeapons.BigScrapPickaxe",
                "SWeapons.BoltBat",
                "SWeapons.ChainBat",
                "SWeapons.GearMace",
                "SWeapons.GlassShiv",
                "SWeapons.HugeScrapPickaxe",
                "SWeapons.Micromaul",
                "SWeapons.PipewithScissors",
                "SWeapons.SalvagedBlade",
                "SWeapons.SalvagedCleaver",
                "SWeapons.SalvagedClimbingAxe",
                "SWeapons.SalvagedClub",
                "SWeapons.SalvagedCrowbar",
                "SWeapons.SalvagedMachete",
                "SWeapons.SalvagedNightstick",
                "SWeapons.SalvagedPipe",
                "SWeapons.SalvagedPipeWrench",
                "SWeapons.SalvagedShiv",
                "SWeapons.SalvagedShivO",
                "SWeapons.SalvagedSledgehammer",
                "SWeapons.ScrapBlade",
                "SWeapons.ScrapClub",
                "SWeapons.ScrapMachete",
                "SWeapons.ScrapPickaxe",
                "SWeapons.ScrapShiv",
                "SWeapons.ScrapSpear",
                "SWeapons.ScrapSword",
                "SWeapons.SharpenedScrewdriver",
                "SWeapons.SharpenedStopSign",
                "SWeapons.SpearSalvaged",
                "SWeapons.SpearScrapMachete",
                "SWeapons.SpearScrapShiv",
                "SWeapons.SpearSharpenedScrewdriver",
                "SWeapons.TinCanClub",
                "SWeapons.TireIronAxe",
                "SWeapons.WireBat",
            },
        },
    },
})
