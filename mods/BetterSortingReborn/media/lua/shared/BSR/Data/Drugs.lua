--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: Drugs (Drugs).
--
-- Both builds. Custom key. The sole item (Cigarettes) was renamed/removed in
-- 42.19, so it is marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- DRUGS section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.Drugs = {
    items = {
        { "Base.Cigarettes", only = "41" },
    },
}
