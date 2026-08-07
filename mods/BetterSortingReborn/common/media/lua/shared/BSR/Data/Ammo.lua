--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: Ammo (Ammo).
--
-- "Ammo" is an adopted vanilla B42 key (ships no label override — the game
-- translates it). The entries stay useful on both builds: they pin loose rounds
-- to Ammo on B41 (which has no such vanilla category) and correct any B42 item
-- vanilla files elsewhere. .223 boxes/rounds and the generic BulletsBox do not
-- exist in B42 42.19 scripts and are marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- WEAPONS section — Ammo).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.Ammo = {
    items = {
        { "Base.223Box", only = "41" },
        { "Base.223Bullets", only = "41" },
        "Base.308Box",
        "Base.308Bullets",
        "Base.556Box",
        "Base.556Bullets",
        "Base.Bullets38",
        "Base.Bullets38Box",
        "Base.Bullets44",
        "Base.Bullets44Box",
        "Base.Bullets45",
        "Base.Bullets45Box",
        "Base.Bullets9mm",
        "Base.Bullets9mmBox",
        { "Base.BulletsBox", only = "41" },
        "Base.ShotgunShells",
        "Base.ShotgunShellsBox",
    },
}
