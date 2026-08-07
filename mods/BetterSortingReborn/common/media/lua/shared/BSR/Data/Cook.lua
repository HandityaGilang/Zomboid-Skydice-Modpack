--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: Cook (Cooking).
--
-- Applies on both builds. B42 ships a generic vanilla "Cooking"
-- category; these manual overrides win on both builds (manual overrides
-- beat vanilla B42), keeping the original's grouping. Items renamed or
-- removed in B42 42.19 are marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- COOKING section).
--
-- The B42 utensils absent from that list (whisk, ladle, strainer, clay
-- crockery, plastic/wooden cutlery, ...) are NOT enumerated here: the
-- `label-collision` rule sweeps whatever is left on the vanilla "Cooking" key
-- into Cook. Only the items whose real home is elsewhere are spelled out, in
-- their own table — mugs and cups in Container, six-packs in FoodA, bottle and
-- can openers in Tool, the cocktail umbrella in Junk.
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.Cook = {
    items = {
        "Base.BakingPan",
        "Base.BakingSoda",
        "Base.BakingTray",
        { "Base.BakingTrayBread", only = "41" },
        "Base.Bowl",
        "Base.BoxOfJars",
        "Base.CakeBatter",
        "Base.CakePrep",
        "Base.Charcoal",
        "Base.CocoaPowder",
        "Base.Coffee2",
        { "Base.Cornflour", only = "41" },
        { "Base.Cornmeal", only = "41" },
        "Base.EmptyJar",
        { "Base.Flour", only = "41" },
        "Base.GravyMix",
        "Base.GridlePan",
        "Base.Hotsauce",
        "Base.JarLid",
        "Base.Ketchup",
        "Base.Kettle",
        "Base.MapleSyrup",
        "Base.Margarine",
        "Base.Marinara",
        "Base.Mov_AntiqueStove",
        "Base.MuffinTray",
        "Base.Mustard",
        "Base.OilOlive",
        "Base.OilVegetable",
        "Base.Pan",
        "Base.PancakeMix",
        "Base.Pepper",
        "Base.PieDough",
        "Base.Pot",
        "Base.RiceVinegar",
        "Base.RoastingPan",
        "Base.RollingPin",
        "Base.Salt",
        "Base.Saucepan",
        "Base.Soysauce",
        "Base.Sugar",
        "Base.SugarBrown",
        "Base.SugarPacket",
        { "Base.Vinegar", only = "41" },
        { "Base.WaterPot", only = "41" },
        "Base.WaterPotPasta",
        "Base.WaterPotRice",
        { "Base.WaterSaucepan", only = "41" },
        "Base.WaterSaucepanPasta",
        "Base.WaterSaucepanRice",
        "Base.Yeast",
    },
}
