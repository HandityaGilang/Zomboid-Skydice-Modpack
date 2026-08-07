--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: LitE (Literature - Entertainment).
--
-- Both builds (see LitS for the auto-rule note). Commented out in the
-- original; migrated anyway. The crossword/wordsearch magazines were removed
-- in B42 and are marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- LITERATURE section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.LitE = {
    items = {
        "Base.Book",
        "Base.ComicBook",
        "Base.HottieZ",
        "Base.Magazine",
        { "Base.MagazineCrossword1", only = "41" },
        { "Base.MagazineCrossword2", only = "41" },
        { "Base.MagazineCrossword3", only = "41" },
        { "Base.MagazineWordsearch1", only = "41" },
        { "Base.MagazineWordsearch2", only = "41" },
        { "Base.MagazineWordsearch3", only = "41" },
        "Base.Newspaper",
        "Base.TVMagazine",
    },
}
