--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Rugged Recipes.
-- The homebrew drinks land in Food - Alcohol, the four recipe magazines in
-- Literature - Recipe, the cucumber seeds in Survival - Farming.
--
-- Covers (one guard per mod in the original):
--   RuggedRecipes (RuggedRecipes) — https://steamcommunity.com/sharedfiles/filedetails/?id=2715579154
--
-- Mappings migrated from Better Sorting (RuggedRecipes_Items.lua). Most of the
-- original file (54 lines: fermenting stages, jerky, dried fruit…) is commented
-- out upstream and is deliberately not migrated — the perishable/non-perishable
-- rule already covers those. The two SEED lines are miswritten upstream
-- (TweakItem("RuggedRecipes.RuggedRecipesMagazine4","CucumberSeed","SurFarm")
-- tweaks a property named "CucumberSeed" on the magazine instead of the seed's
-- DisplayCategory, so they are no-ops in the original); they are ported here as
-- the two seed items the author clearly meant.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "RuggedRecipes",
    mods = { "RuggedRecipes" },
    data = {
        FoodA = {
            items = {
                "RuggedRecipes.BerryWine",
                "RuggedRecipes.Hooch",
                "RuggedRecipes.Kvass",
            },
        },
        LitR = {
            items = {
                "RuggedRecipes.RuggedRecipesMagazine1",
                "RuggedRecipes.RuggedRecipesMagazine2",
                "RuggedRecipes.RuggedRecipesMagazine3",
                "RuggedRecipes.RuggedRecipesMagazine4",
            },
        },
        SurFarm = {
            items = {
                "RuggedRecipes.CucumberBagSeed",
                "RuggedRecipes.CucumberSeed",
            },
        },
    },
})
