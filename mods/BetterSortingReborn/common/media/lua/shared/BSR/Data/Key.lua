--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: Key (Key).
--
-- Both builds. Custom key. Key2..Key5 do not exist in 42.19 scripts and are
-- marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- KEY section).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.Key = {
    items = {
        "Base.CarKey",
        "Base.Key1",
        { "Base.Key2", only = "41" },
        { "Base.Key3", only = "41" },
        { "Base.Key4", only = "41" },
        { "Base.Key5", only = "41" },
    },
}
