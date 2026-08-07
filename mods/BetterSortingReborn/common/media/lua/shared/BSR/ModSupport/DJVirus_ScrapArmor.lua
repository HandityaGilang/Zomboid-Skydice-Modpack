--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Scrap Armor.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2658619264
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
    name = "DJVirus (Scrap Armor)",
    mods = { "ScrapArmor(new version)" },
    data = {
        ClothAcc = {
            items = {
                "Base.ShieldBelt",
                "Base.SwordSheath",
            },
        },
        ClothArm = {
            items = {
                "Base.ScrapHandPlate2L",
                "Base.ScrapHandPlate2R",
                "Base.ScrapHandPlateL",
                "Base.ScrapHandPlateR",
                "Base.ScrapHandPlateStuddedL",
                "Base.ScrapHandPlateStuddedR",
                "Base.ScrapPauldrons",
                "Base.ScrapPauldrons2",
                "Base.ScrapPauldrons2Studded",
                "Base.ScrapShoulderPadBoltsL",
                "Base.ScrapShoulderPadBoltsR",
                "Base.ScrapShoulderPadL",
                "Base.ScrapShoulderPadR",
                "Base.ScrapShoulderPadSawL",
                "Base.ScrapShoulderPadSawR",
                "Base.ScrapShoulderPadSignL",
                "Base.ScrapShoulderPadSignR",
            },
        },
        ClothBack = {
            items = {
                "Base.Rucksack",
            },
        },
        ClothBag = {
            items = {
                "Base.ScrapLegPouchL",
                "Base.ScrapLegPouchR",
            },
        },
        ClothBody = {
            items = {
                "Base.ScrapVest",
                "Base.ScrapVestPlated",
                "Base.ScrapVestSign",
                "Base.ScrapVestStudded",
            },
        },
        ClothHead = {
            items = {
                "Base.Hat_MotorcycleHelmet2",
                "Base.Hat_MotorcycleHelmet2open",
                "Base.Hat_Rebreather",
                "Base.Hat_ScrapHelmet",
                "Base.Hat_ScrapHelmetopen",
                "Base.Hat_ScrapKettleHelmet",
                "Base.Hat_WelderMask2",
            },
        },
        ClothLeg = {
            items = {
                "Base.ScrapKilt",
                "Base.ScrapKiltPlated",
                "Base.ScrapKiltSign",
                "Base.ScrapKiltStudded",
                "Base.ScrapLegPadBoltsL",
                "Base.ScrapLegPadBoltsR",
                "Base.ScrapLegPadL",
                "Base.ScrapLegPadR",
                "Base.ScrapLegPadSign2L",
                "Base.ScrapLegPadSign2R",
                "Base.ScrapLegPadSignL",
                "Base.ScrapLegPadSignR",
                "Base.ScrapShinPlate2L",
                "Base.ScrapShinPlate2R",
                "Base.ScrapShinPlateL",
                "Base.ScrapShinPlateR",
                "Base.ScrapShinPlateStuddedL",
                "Base.ScrapShinPlateStuddedR",
            },
        },
        LitR = {
            items = {
                "SArmor.ArmorMag1",
                "SArmor.ArmorMag2",
                "SArmor.ArmorMag3",
                "SArmor.ArmorMag4",
                "SArmor.ArmorMag5",
            },
        },
        WepShield = {
            items = {
                "Base.CarDoorShield",
                "Base.CarDoorShield1",
                "Base.CarDoorShield2",
                "Base.ScrapShield",
                "Base.ScrapShieldPainted1",
                "Base.ScrapShieldPainted2",
                "Base.ScrapShieldPainted3",
                "Base.WoodenShield",
            },
        },
    },
})
