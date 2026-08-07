--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: WepPart (Weapon - Part).
--
-- B41 only (whole-table only = "41"). B42 vanilla already ships a "WeaponPart"
-- category that groups these exact weapon attachments at the same granularity,
-- so overriding them to WepPart on B42 would be a pure relabel with no grouping
-- gain — the one Wep* table that is a rename rather than a refinement. On B42
-- the items keep their vanilla "WeaponPart" category. (FiberglassStock,
-- IronSight and Sling do not exist in B42 42.19 scripts anyway.)
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- WEAPONS section — Part).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.WepPart = {
    only = "41",
    items = {
        "Base.AmmoStraps",
        "Base.ChokeTubeFull",
        "Base.ChokeTubeImproved",
        "Base.FiberglassStock",
        "Base.GunLight",
        "Base.IronSight",
        "Base.Laser",
        "Base.RecoilPad",
        "Base.RedDot",
        "Base.Sling",
        "Base.x2Scope",
        "Base.x4Scope",
        "Base.x8Scope",
    },
}
