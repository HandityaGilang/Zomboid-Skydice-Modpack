--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: MediaA (Media - Audio).
--
-- Both builds. Custom key. Base.Disc was removed in B42 (only the Retail
-- variant remains) and is marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- MEDIA section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.MediaA = {
    items = {
        { "Base.Disc", only = "41" },
        "Base.Disc_Retail",
    },
}
