--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Ramen.
-- Only the leftovers are mapped: empty wrappers, packets and flavour sachets
-- all go to Junk.
--
-- Covers:
--   Ramen (Ramen) — https://steamcommunity.com/sharedfiles/filedetails/?id=2382777667
--
-- Mappings migrated from Better Sorting (Ramen_Items.lua). The 28 food lines of
-- the original (the ramen itself -> FoodN/FoodP) are commented out upstream and
-- deliberately not migrated: the generic perishable/non-perishable rule already
-- sorts them.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "Ramen",
    mods = { "Ramen" },
    data = {
        Junk = {
            items = {
                "Ramen.RamenBeefFlatEmpty",
                "Ramen.RamenBeefFlavEmpty",
                "Ramen.RamenBeefPackEmpty",
                "Ramen.RamenCheeseFlatEmpty",
                "Ramen.RamenCheeseFlavEmpty",
                "Ramen.RamenCheesePackEmpty",
                "Ramen.RamenChickenFlatEmpty",
                "Ramen.RamenChickenFlavEmpty",
                "Ramen.RamenChickenPackEmpty",
                "Ramen.RamenChiliFlatEmpty",
                "Ramen.RamenOrientalFlatEmpty",
                "Ramen.RamenPorkFlatEmpty",
                "Ramen.RamenShrimpFlatEmpty",
                "Ramen.RamenShrimpFlavEmpty",
                "Ramen.RamenShrimpPackEmpty",
            },
        },
    },
})
