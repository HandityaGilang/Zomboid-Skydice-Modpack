--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: Container (the original's "Cont" key).
--
-- Applies on both builds. Reuses the vanilla "Container" key (Reborn drops the
-- original's parallel "Cont" key in favor of it). On B42 vanilla scatters these
-- across Container, WaterContainer, Memento, Cooking and Bag, so consolidating
-- them under one Container header adds grouping value there too. Items renamed
-- or removed in B42 are marked only = "41".
--
-- B42 folded the `Radio` and `farming` modules into `Base`: the entries below
-- that carry both spellings, gated by build, are ONE item that was renamed —
-- not an item added and an item removed.
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- CONTAINERS section; "Cont" -> "Container"). 19 duplicate lines in the
-- original (GroceryBag1-4, RifleCase1-3, ShotgunCase1-2) were deduplicated.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.Container = {
    items = {
        "Base.Bag_BowlingBallBag",
        "Base.Bag_DoctorBag",
        "Base.Bag_JanitorToolbox",
        "Base.BeerEmpty",
        "Base.Briefcase",
        "Base.BucketEmpty",
        "Base.CeramicTeacup",
        "Base.ClayMug",
        "Base.Cooler",
        "Base.CopperCup",
        { "Base.Crate", only = "41" },
        { "Base.EmptyPetrolCan", only = "41" },
        "Base.EmptySandbag",
        "Base.Flightcase",
        "Base.GlassTumbler",
        "Base.GlassWine",
        "Base.GoldCup",
        "Base.GroceryBag1",
        "Base.GroceryBag2",
        "Base.GroceryBag3",
        "Base.GroceryBag4",
        "Base.GroceryBag5",
        "Base.Guitarcase",
        "Base.Handbag",
        "Base.KeyRing",
        "Base.Lunchbag",
        "Base.Lunchbox",
        "Base.Lunchbox2",
        { "Base.MayonnaiseEmpty", only = "42" },
        "Base.MetalCup",
        { "Base.MugRed", only = "41" },
        "Base.MugSpiffo",
        "Base.MugWhite",
        "Base.Mugl",
        "Base.PaintbucketEmpty",
        "Base.PaperBag",
        "Base.Paperbag_Jays",
        "Base.Paperbag_Spiffos",
        "Base.PistolCase1",
        "Base.PistolCase2",
        "Base.PistolCase3",
        "Base.PlasticCup",
        "Base.Plasticbag",
        { "Base.PopBottleEmpty", only = "41" },
        "Base.Purse",
        { "Base.RemouladeEmpty", only = "42" },
        "Base.RevolverCase1",
        "Base.RevolverCase2",
        "Base.RevolverCase3",
        "Base.RifleCase1",
        "Base.RifleCase2",
        "Base.RifleCase3",
        { "Base.SackCabbages", only = "41" },
        { "Base.SackCarrots", only = "41" },
        { "Base.SackOnions", only = "41" },
        { "Base.SackPotatoes", only = "41" },
        "Base.SewingKit",
        "Base.ShotgunCase1",
        "Base.ShotgunCase2",
        "Base.SilverCup",
        "Base.Suitcase",
        "Base.Teacup",
        "Base.Toolbox",
        "Base.Tote",
        { "Base.WaterBottleEmpty", only = "41" },
        { "Base.WhiskeyEmpty", only = "41" },
        { "Base.WineEmpty", only = "41" },
        { "Base.WineEmpty2", only = "41" },
        { "farming.MayonnaiseEmpty", only = "41" },
        { "farming.RemouladeEmpty", only = "41" },
    },
}
