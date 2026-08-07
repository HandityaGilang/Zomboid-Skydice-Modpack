--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: SurFish (Survival - Fishing).
--
-- Both builds. Custom key. The twine-line rods and tackle variants do not
-- exist in 42.19 and are marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- SURVIVAL section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.SurFish = {
    items = {
        "Base.BaitFish",
        "Base.BrokenFishingNet",
        "Base.CraftedFishingRod",
        { "Base.CraftedFishingRodTwineLine", only = "41" },
        "Base.FishingLine",
        "Base.FishingNet",
        "Base.FishingRod",
        "Base.FishingRodBreak",
        { "Base.FishingRodTwineLine", only = "41" },
        { "Base.FishingTackle", only = "41" },
        { "Base.FishingTackle2", only = "41" },
    },
}
