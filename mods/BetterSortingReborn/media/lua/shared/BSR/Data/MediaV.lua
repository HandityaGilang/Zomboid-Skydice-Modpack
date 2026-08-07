--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: MediaV (Media - Video).
--
-- Both builds. Custom key. Base.VHS was removed in B42 (only the Home/Retail
-- variants remain) and is marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- MEDIA section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.MediaV = {
    items = {
        { "Base.VHS", only = "41" },
        "Base.VHS_Home",
        "Base.VHS_Retail",
    },
}
