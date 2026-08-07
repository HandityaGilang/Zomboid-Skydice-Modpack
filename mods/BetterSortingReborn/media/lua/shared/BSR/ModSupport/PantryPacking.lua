--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Pantry Packing.
-- Boxed groceries -> Food - Non-Perishable, the boxed skill books ->
-- Literature - Skill, the boxed wall/table maps -> Literature - Cartography.
--
-- Covers:
--   PantryPacking (PantryPacking) — https://steamcommunity.com/sharedfiles/filedetails/?id=2637692469
--
-- Mappings migrated from Better Sorting (PantryPacking_Items.lua). All of the
-- mod's items live in the Base module. Four upstream lines are deliberately
-- changed: BookBoxTest, BoxOfComicBooks, BoxOfMagazines and NewspaperStack sit
-- inside the FoodN run upstream (a copy/paste slip — a box of comic books is not
-- food). They are mapped here to LitS (with the other twelve book boxes) and
-- LitE, matching Data/LitE.lua, which files ComicBook/Magazine/Newspaper there.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "PantryPacking",
    mods = { "PantryPacking" },
    data = {
        FoodN = {
            items = {
                "Base.BoxOfBeans",
                "Base.BoxOfBlueCrisps",
                "Base.BoxOfBolognese",
                "Base.BoxOfCanBeef",
                "Base.BoxOfCanCarrots",
                "Base.BoxOfCanChili",
                "Base.BoxOfCanCocktail",
                "Base.BoxOfCanCorn",
                "Base.BoxOfCanMushroomSoup",
                "Base.BoxOfCanPeaches",
                "Base.BoxOfCanPeas",
                "Base.BoxOfCanPineapple",
                "Base.BoxOfCanPotato",
                "Base.BoxOfCanSardines",
                "Base.BoxOfCanSoup",
                "Base.BoxOfCanTomato",
                "Base.BoxOfCanTuna",
                "Base.BoxOfCereal",
                "Base.BoxOfChocolate",
                "Base.BoxOfCocoaPowder",
                "Base.BoxOfCoffee2",
                "Base.BoxOfCookie",
                "Base.BoxOfCookieJelly",
                "Base.BoxOfCupcake",
                "Base.BoxOfDogFood",
                "Base.BoxOfDriedBlackBeans",
                "Base.BoxOfDriedChickPeas",
                "Base.BoxOfDriedKidneyBeans",
                "Base.BoxOfDriedLentils",
                "Base.BoxOfDriedSplitPeas",
                "Base.BoxOfDriedWhiteBeans",
                "Base.BoxOfFlour",
                "Base.BoxOfGreenCrisps",
                "Base.BoxOfHottieZ",
                "Base.BoxOfJamFruit",
                "Base.BoxOfJamMarmalade",
                "Base.BoxOfMacandcheese",
                "Base.BoxOfMapleSyrup",
                "Base.BoxOfPasta",
                "Base.BoxOfPeanutButter",
                "Base.BoxOfPopcorn",
                "Base.BoxOfRamen",
                "Base.BoxOfRedCrisps",
                "Base.BoxOfRice",
                "Base.BoxOfSoySauce",
                "Base.BoxOfSugar",
                "Base.BoxOfTVDinner",
                "Base.BoxOfTeabag2",
                "Base.BoxOfVegOil",
                "Base.BoxOfVinegar",
                "Base.BoxOfYellowCrisps",
            },
        },
        LitC = {
            items = {
                "Base.TableMapMarchRidge",
                "Base.TableMapMuldragh",
                "Base.TableMapRiverside",
                "Base.TableMapRosewood",
                "Base.TableMapWestPoint",
                "Base.WallMapMarchRidge",
                "Base.WallMapMuldragh",
                "Base.WallMapRiverside",
                "Base.WallMapRosewood",
                "Base.WallMapWestPoint",
            },
        },
        LitE = {
            items = {
                "Base.BoxOfComicBooks",
                "Base.BoxOfMagazines",
                "Base.NewspaperStack",
            },
        },
        LitS = {
            items = {
                "Base.BookBox",
                "Base.BookBoxCarpentry",
                "Base.BookBoxCooking",
                "Base.BookBoxElectricity",
                "Base.BookBoxFarming",
                "Base.BookBoxFirstAid",
                "Base.BookBoxFishing",
                "Base.BookBoxForaging",
                "Base.BookBoxMechanics",
                "Base.BookBoxMetalwork",
                "Base.BookBoxTailoring",
                "Base.BookBoxTest",
                "Base.BookBoxTrapping",
            },
        },
    },
})
