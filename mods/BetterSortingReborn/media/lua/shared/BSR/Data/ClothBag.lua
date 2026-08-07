--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: ClothBag (Clothing - Bag).
--
-- Applies on both builds: ClothBag ("Clothing - Bag") stays more specific than
-- B42's generic vanilla clothing buckets (Clothing / Accessory / Bag /
-- ProtectiveGear), so it stays valuable on both. Every item still exists
-- in B42 42.19, so none are build-gated.
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- CLOTHING section — Bag).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.ClothBag = {
    items = {
        "Base.Bag_FannyPackBack",
        "Base.Bag_FannyPackFront",
    },
}
