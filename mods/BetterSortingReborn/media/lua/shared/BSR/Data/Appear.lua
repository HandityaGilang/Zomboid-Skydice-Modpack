--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: Appear (Appearance).
--
-- Format (enforced by tools/validate.py — one quoted item per line):
--   BSR.Data.<CategoryKey> = {
--       only = "41" | "42",          -- optional, whole-table build filter
--       items = {
--           "Module.Item",
--           { "Module.Item", only = "41" },   -- optional per-item filter
--       },
--   }
--
-- 41-only: vanilla B42 already ships an "Appearance" category covering hair
-- dye, makeup and the like — recategorizing them would only churn the key
-- without changing what players see.
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- APPEARANCE section + one stray in MISC).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.Appear = {
    only = "41",
    items = {
        "Base.HairDyeBlack",
        "Base.HairDyeBlonde",
        "Base.HairDyeBlue",
        "Base.HairDyeGinger",
        "Base.HairDyeGreen",
        "Base.HairDyeLightBrown",
        "Base.HairDyePink",
        "Base.HairDyeRed",
        "Base.HairDyeWhite",
        "Base.HairDyeYellow",
        "Base.Hairgel",
        "Base.Lipstick",
        "Base.MakeupEyeshadow",
        "Base.MakeupFoundation",
        "Base.MakeUp_BraveHeart",
        "Base.MakeUp_CamoEyes1",
        "Base.MakeUp_CamoEyes2",
        "Base.MakeUp_CamoFullFace1",
        "Base.MakeUp_CamoFullFace2",
        "Base.MakeUp_CamoStripes",
        "Base.MakeUp_ClownFace1",
        "Base.MakeUp_ClownFace2",
        "Base.MakeUp_Crow",
        "Base.MakeUp_EyesShadowBlue",
        "Base.MakeUp_EyesShadowGreen",
        "Base.MakeUp_EyesShadowLightBlue",
        "Base.MakeUp_EyesShadowPink",
        "Base.MakeUp_EyesShadowRed",
        "Base.MakeUp_EyesShadowWhite",
        "Base.MakeUp_EyesShadowYellow",
        "Base.MakeUp_Football",
        "Base.MakeUp_GreenCamo",
        "Base.MakeUp_LipsBlack",
        "Base.MakeUp_LipsBlue",
        "Base.MakeUp_LipsGreen",
        "Base.MakeUp_LipsLightBlue",
        "Base.MakeUp_LipsPink",
        "Base.MakeUp_LipsRed",
        "Base.MakeUp_RedStripes1",
        "Base.MakeUp_RedStripes2",
        "Base.MakeUp_SkullFace1",
        "Base.MakeUp_SkullFace2",
    },
}
