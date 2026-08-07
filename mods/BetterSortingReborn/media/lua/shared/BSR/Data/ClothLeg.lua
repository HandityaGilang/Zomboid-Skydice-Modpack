--------------------------------------------------------------------------------
-- Better Sorting Reborn — data: ClothLeg (Clothing - Legs).
--
-- Applies on both builds: ClothLeg ("Clothing - Legs") stays more specific than
-- B42's generic vanilla clothing buckets (Clothing / Accessory / Bag /
-- ProtectiveGear), so it stays valuable on both. Items renamed or removed
-- in B42 42.19 are marked only = "41".
--
-- Item list migrated from Better Sorting v2.0.4 (Item_Categories.lua,
-- CLOTHING section — Legs).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.Data = BSR.Data or {}

BSR.Data.ClothLeg = {
    items = {
        "Base.Dungarees",
        "Base.Ghillie_Trousers",
        "Base.LongJohns",
        "Base.LongJohns_Bottoms",
        "Base.Shorts_BoxingBlue",
        "Base.Shorts_BoxingRed",
        "Base.Shorts_CamoGreenLong",
        "Base.Shorts_CamoUrbanLong",
        "Base.Shorts_LongDenim",
        "Base.Shorts_LongSport",
        "Base.Shorts_LongSport_Red",
        "Base.Shorts_ShortDenim",
        "Base.Shorts_ShortFormal",
        "Base.Shorts_ShortSport",
        "Base.Skirt_Knees",
        "Base.Skirt_Long",
        "Base.Skirt_Mini",
        "Base.Skirt_Normal",
        "Base.Skirt_Short",
        "Base.SwimTrunks_Blue",
        "Base.SwimTrunks_Green",
        "Base.SwimTrunks_Red",
        "Base.SwimTrunks_Yellow",
        "Base.Swimsuit_TINT",
        "Base.TightsBlack",
        "Base.TightsBlackSemiTrans",
        "Base.TightsBlackTrans",
        "Base.TightsFishnets",
        "Base.Trousers",
        "Base.TrousersMesh_DenimLight",
        "Base.TrousersMesh_Leather",
        "Base.Trousers_ArmyService",
        "Base.Trousers_Black",
        "Base.Trousers_CamoDesert",
        "Base.Trousers_CamoGreen",
        "Base.Trousers_CamoUrban",
        "Base.Trousers_Chef",
        "Base.Trousers_DefaultTEXTURE",
        "Base.Trousers_DefaultTEXTURE_HUE",
        "Base.Trousers_DefaultTEXTURE_TINT",
        "Base.Trousers_Denim",
        "Base.Trousers_Fireman",
        "Base.Trousers_JeanBaggy",
        "Base.Trousers_LeatherBlack",
        "Base.Trousers_NavyBlue",
        "Base.Trousers_Padded",
        "Base.Trousers_Police",
        "Base.Trousers_PoliceGrey",
        "Base.Trousers_PrisonGuard",
        "Base.Trousers_Ranger",
        "Base.Trousers_Santa",
        { "Base.Trousers_SantaGReen", only = "41" },
        "Base.Trousers_Scrubs",
        "Base.Trousers_Shellsuit_Black",
        "Base.Trousers_Shellsuit_Blue",
        "Base.Trousers_Shellsuit_Green",
        "Base.Trousers_Shellsuit_Pink",
        "Base.Trousers_Shellsuit_TINT",
        "Base.Trousers_Shellsuit_Teal",
        "Base.Trousers_Suit",
        "Base.Trousers_SuitTEXTURE",
        "Base.Trousers_SuitWhite",
        "Base.Trousers_WhiteTEXTURE",
        "Base.Trousers_WhiteTINT",
    },
}
