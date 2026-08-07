--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: WepAmmoMag (Weapon - Magazine).
--
-- Applies on both builds: B42 vanilla files magazines under the generic "Ammo"
-- category; WepAmmoMag ("Weapon - Magazine") separates removable magazines from
-- loose rounds, so it stays valuable on B42. .223/.308 clips do not exist in
-- B42 42.19 scripts and are marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- WEAPONS section — Magazine).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.WepAmmoMag = {
    items = {
        { "Base.223Clip", only = "41" },
        { "Base.308Clip", only = "41" },
        "Base.44Clip",
        "Base.45Clip",
        "Base.556Clip",
        "Base.9mmClip",
        "Base.M14Clip",
    },
}
