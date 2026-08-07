--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: Junk (Junk).
--
-- Both builds. "Junk" is a vanilla B42 key adopted here, but the override is
-- still useful on both builds for items B42 does not already file under Junk.
--
-- Deduplicated (the original listed Spatula and Tongs more than once). Three
-- originally-commented lines (GlassTumbler, GlassWine, PlasticCup) are left
-- out: they are containers, migrated in Container.lua. Two entries the
-- original placed in this section but tagged otherwise live in their own
-- files (Crayons/Doodle -> LitW, Lipstick -> Appear).
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- JUNK section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.Junk = {
    items = {
        "Base.BackgammonBoard",
        "Base.Baseball",
        "Base.Basketball",
        "Base.BeerCanEmpty",
        "Base.Bell",
        "Base.Bricktoys",
        "Base.Button",
        "Base.CameraFilm",
        { "Base.CarvingFork", only = "41" },
        "Base.CatToy",
        "Base.CheckerBoard",
        "Base.ChessBlack",
        "Base.ChessWhite",
        "Base.Chopsticks",
        "Base.CocktailUmbrella",
        "Base.Cologne",
        "Base.Comb",
        "Base.Cork",
        "Base.Corkscrew",
        "Base.CreditCard",
        "Base.Cube",
        "Base.CuttingBoardPlastic",
        "Base.CuttingBoardWooden",
        "Base.Dart",
        "Base.DogChew",
        "Base.Doll",
        "Base.Football",
        { "Base.Football2", only = "41" },
        "Base.FountainCup",
        "Base.Frame",
        "Base.GamePieceBlack",
        "Base.GamePieceRed",
        "Base.GamePieceWhite",
        "Base.GolfBall",
        "Base.GrillBrush",
        "Base.HolePuncher",
        "Base.KatePic",
        "Base.KitchenTongs",
        "Base.KnittingNeedles",
        { "Base.Lamp", only = "41" },
        "Base.Leash",
        { "Base.Male_Undies", only = "41" },
        "Base.MetalDrum",
        "Base.Mirror",
        "Base.Money",
        "Base.OvenMitt",
        { "Base.PaperNapkins", only = "41" },
        "Base.Perfume",
        "Base.Pinecone",
        "Base.PlasticTray",
        "Base.Plate",
        { "Base.PlateBlue", only = "41" },
        { "Base.PlateFancy", only = "41" },
        { "Base.PlateOrange", only = "41" },
        "Base.PokerChips",
        "Base.PoolBall",
        "Base.Pop2Empty",
        "Base.Pop3Empty",
        "Base.PopEmpty",
        "Base.Razor",
        "Base.RubberBand",
        "Base.Rubberducky",
        { "Base.Rubberducky2", only = "41" },
        "Base.SoccerBall",
        "Base.Spatula",
        "Base.Sponge",
        "Base.Stapler",
        "Base.Staples",
        { "Base.Straw", only = "41" },
        "Base.TennisBall",
        "Base.TinCanEmpty",
        "Base.Tongs",
        "Base.Toothbrush",
        "Base.Toothpaste",
        "Base.ToyBear",
        "Base.ToyCar",
        "Base.UnusableMetal",
        "Base.Wallet",
        { "Base.Wallet2", only = "41" },
        { "Base.Wallet3", only = "41" },
        { "Base.Wallet4", only = "41" },
        "Base.WaterDish",
        "Base.Yoyo",
    },
}
