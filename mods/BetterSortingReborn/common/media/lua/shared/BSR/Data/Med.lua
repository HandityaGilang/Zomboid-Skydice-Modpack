--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: Med (Medical).
--
-- Both builds. B42 vanilla splits medical items across "FirstAid", "Bandage"
-- and others with different labels; this single "Medical" grouping keeps the
-- original behaviour on both builds. WildGarlic was removed in B42.
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- MEDICAL section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.Med = {
    items = {
        "Base.AlcoholBandage",
        "Base.AlcoholRippedSheets",
        "Base.AlcoholWipes",
        "Base.AlcoholedCottonBalls",
        "Base.Antibiotics",
        "Base.Bandage",
        "Base.BandageDirty",
        "Base.Bandaid",
        "Base.BlackSage",
        "Base.Comfrey",
        "Base.ComfreyCataplasm",
        "Base.CommonMallow",
        "Base.CottonBalls",
        "Base.Disinfectant",
        "Base.FirstAidKit",
        "Base.Ginseng",
        "Base.LemonGrass",
        "Base.Pills",
        "Base.PillsAntiDep",
        "Base.PillsBeta",
        "Base.PillsSleepingTablets",
        "Base.PillsVitamins",
        "Base.Plantain",
        "Base.PlantainCataplasm",
        "Base.Splint",
        "Base.SutureNeedle",
        "Base.SutureNeedleHolder",
        "Base.Tissue",
        "Base.ToiletPaper",
        "Base.Tweezers",
        { "Base.WildGarlic", only = "41" },
        "Base.WildGarlicCataplasm",
    },
}
