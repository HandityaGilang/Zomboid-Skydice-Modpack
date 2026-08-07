--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Better Belts.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2127583399
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
    name = "DJVirus (Better Belts)",
    mods = { "Better Belts" },
    data = {
        ClothAcc = {
            items = {
                "Base.Belt3",
                "Base.Belt4",
                "Base.HolsterSimpleL",
                "Base.QuiverB",
            },
        },
        ClothBag = {
            items = {
                "Base.AFAKB",
                "Base.FirstAidKitB",
                "Base.Lunchbox2B",
                "Base.LunchboxB",
                "Base.PistolCase1B",
                "Base.ToolBoxB",
            },
        },
        Container = {
            items = {
                "Base.AFAK",
                "Base.HookedWaterBottleEmptyGreen",
                "Base.HookedWaterBottleEmptyOrange",
                "Base.HookedWaterBottleEmptyPurple",
                "Base.HookedWaterBottleEmptyRed",
                "Base.HookedWaterBottleEmptyYellow",
            },
        },
        Craft = {
            items = {
                "Base.HookB",
            },
        },
        Elec = {
            items = {
                "Radio.CDplayer",
            },
        },
        FoodB = {
            items = {
                "Base.HookedWaterBottleFullGreen",
                "Base.HookedWaterBottleFullOrange",
                "Base.HookedWaterBottleFullPurple",
                "Base.HookedWaterBottleFullRed",
                "Base.HookedWaterBottleFullYellow",
            },
        },
        SurCamp = {
            items = {
                "Base.TentKitGreen",
            },
        },
    },
})
