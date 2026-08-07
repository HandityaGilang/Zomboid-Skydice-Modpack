--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Nuka-Cola Collection.
-- Sealed, opened and water-filled bottles -> Food - Beverage, the empty
-- bottles -> Container, the bottle caps -> Junk.
--
-- Covers:
--   NukaColaCollection (NukaColaCollection) — https://steamcommunity.com/sharedfiles/filedetails/?id=2613274731
--
-- Mappings migrated from Better Sorting (NukaColaCollection_Items.lua), with the
-- original's "Cont" key remapped to "Container".
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "NukaColaCollection",
    mods = { "NukaColaCollection" },
    data = {
        Container = {
            items = {
                "nuka.EmptyNukaCherry",
                "nuka.EmptyNukaCola",
                "nuka.EmptyNukaCranberry",
                "nuka.EmptyNukaDark",
                "nuka.EmptyNukaGrape",
                "nuka.EmptyNukaOrange",
                "nuka.EmptyNukaQuantum",
                "nuka.EmptyNukaQuartz",
                "nuka.EmptyNukaVictory",
                "nuka.EmptyNukaWild",
                "nuka.NukaShineEmpty",
            },
        },
        FoodB = {
            items = {
                "nuka.NukaCherry",
                "nuka.NukaCherryOpen",
                "nuka.NukaCherryWater",
                "nuka.NukaCola",
                "nuka.NukaColaOpen",
                "nuka.NukaColaWater",
                "nuka.NukaCranberry",
                "nuka.NukaCranberryOpen",
                "nuka.NukaCranberryWater",
                "nuka.NukaDark",
                "nuka.NukaDarkOpen",
                "nuka.NukaDarkWater",
                "nuka.NukaGrape",
                "nuka.NukaGrapeOpen",
                "nuka.NukaGrapeWater",
                "nuka.NukaOrange",
                "nuka.NukaOrangeOpen",
                "nuka.NukaOrangeWater",
                "nuka.NukaQuantum",
                "nuka.NukaQuantumOpen",
                "nuka.NukaQuantumWater",
                "nuka.NukaQuartz",
                "nuka.NukaQuartzOpen",
                "nuka.NukaQuartzWater",
                "nuka.NukaShine",
                "nuka.NukaShineOpen",
                "nuka.NukaShineWater",
                "nuka.NukaVictory",
                "nuka.NukaVictoryOpen",
                "nuka.NukaVictoryWater",
                "nuka.NukaWild",
                "nuka.NukaWildOpen",
                "nuka.NukaWildWater",
            },
        },
        Junk = {
            items = {
                "nuka.NukaCherryCap",
                "nuka.NukaColaCap",
                "nuka.NukaCranberryCap",
                "nuka.NukaDarkCap",
                "nuka.NukaGrapeCap",
                "nuka.NukaOrangeCap",
                "nuka.NukaQuantumCap",
                "nuka.NukaQuartzCap",
                "nuka.NukaVictoryCap",
                "nuka.NukaWildCap",
            },
        },
    },
})
