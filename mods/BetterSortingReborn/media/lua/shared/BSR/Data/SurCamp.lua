--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: SurCamp (Survival - Camping).
--
-- Both builds. Custom key. The camping.* module items plus Coal and
-- FireWoodKit were removed or moved in B42 and are marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- SURVIVAL section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.SurCamp = {
    items = {
        { "Base.Coal", only = "41" },
        { "Base.FireWoodKit", only = "41" },
        "Base.PercedWood",
        "Base.Twigs",
        "Base.UnusableWood",
        { "camping.CampfireKit", only = "41" },
        { "camping.CampingTent", only = "41" },
        { "camping.CampingTentKit", only = "41" },
        { "camping.Flint", only = "41" },
        { "camping.SteelAndFlint", only = "41" },
        { "camping.SteelKnuckle", only = "41" },
    },
}
