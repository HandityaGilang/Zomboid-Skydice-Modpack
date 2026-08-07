--------------------------------------------------------------------------------
-- Better Sorting Reborn — mod-support pack: Clothes Box Redux.
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2847911733
--
-- The mod ships its clothing in the Base module under a CBX_ prefix; the
-- per-item categories differ (body/legs/feet/bags/backpacks/underwear), so
-- the mapping stays an explicit list rather than a prefix rule.
--
-- Mappings migrated from Better Sorting v2.0.4 (ClothesBox_Items.lua).
--------------------------------------------------------------------------------

BSR = BSR or {}
BSR.ModPacks = BSR.ModPacks or {}

table.insert(BSR.ModPacks, {
    name = "ClothesBox",
    mods = { "ClothesBoxRedux" },
    data = {
        ClothBack = {
            items = {
                "Base.CBX_ANAT",
                "Base.CBX_HR",
                "Base.CBX_RUKSAK1",
                "Base.CBX_RUKSAK2",
            },
        },
        ClothBag = {
            items = {
                "Base.CBX_Sumk_1M_L",
                "Base.CBX_Sumk_1M_R",
                "Base.CBX_Sumk_1_L",
                "Base.CBX_Sumk_1_R",
                "Base.CBX_Sumk_2_L",
                "Base.CBX_Sumk_2_R",
                "Base.CBX_Sumk_3_L",
                "Base.CBX_Sumk_3_R",
                "Base.CBX_Sumk_4_L",
                "Base.CBX_Sumk_4_R",
                "Base.CBX_Sumk_5_L",
                "Base.CBX_Sumk_5_R",
                "Base.CBX_Sumk_6",
                "Base.CBX_Sumk_7_L",
                "Base.CBX_Sumk_7_R",
                "Base.CBX_Sumk_8",
                "Base.CBX_Sumk_8P",
            },
        },
        ClothBody = {
            items = {
                "Base.CBX_Bomber",
                "Base.CBX_CropTop",
                "Base.CBX_CropTop_White",
                "Base.CBX_KOF1",
                "Base.CBX_KOF2",
                "Base.CBX_KOMB",
                "Base.CBX_KOS",
                "Base.CBX_Kurtk_1",
                "Base.CBX_Kurtk_10",
                "Base.CBX_Kurtk_10OP",
                "Base.CBX_Kurtk_2",
                "Base.CBX_Kurtk_3",
                "Base.CBX_Kurtk_4",
                "Base.CBX_Kurtk_5",
                "Base.CBX_Kurtk_5OP",
                "Base.CBX_Kurtk_6",
                "Base.CBX_Kurtk_6OP",
                "Base.CBX_Kurtk_7",
                "Base.CBX_Kurtk_7OP",
                "Base.CBX_Kurtk_7_1",
                "Base.CBX_Kurtk_7_1OP",
                "Base.CBX_Kurtk_8",
                "Base.CBX_Kurtk_8OP",
                "Base.CBX_Kurtk_9",
                "Base.CBX_Kurtk_9OP",
                "Base.CBX_RUB",
                "Base.CBX_RUBOP",
                "Base.CBX_Ras_army",
                "Base.CBX_Ras_ohota",
                "Base.CBX_SK1",
                "Base.CBX_SP1",
                "Base.CBX_SP1OP",
                "Base.CBX_Vest_ForemanOPEN",
                "Base.CBX_Vest_HighVizOPEN",
                "Base.CBX_Vest_Hunting_CamoGreenOPEN",
                "Base.CBX_Vest_Hunting_CamoOPEN",
                "Base.CBX_Vest_Hunting_GreyOPEN",
                "Base.CBX_Vest_Hunting_OrangeOPEN",
                "Base.CBX_kupalnuk",
            },
        },
        ClothFeet = {
            items = {
                "Base.CBX_BOOT_1",
                "Base.CBX_SHO1",
            },
        },
        ClothHead = {
            items = {
                "Base.CBX_CAPARM_1",
                "Base.CBX_CAPARM_2",
                "Base.CBX_CAPARM_3",
                "Base.CBX_CAPARM_4",
                "Base.CBX_Glasses_1",
                "Base.CBX_Glasses_2",
                "Base.CBX_Glasses_3",
                "Base.CBX_OHI_1",
                "Base.CBX_OHI_2",
                "Base.CBX_OHI_3",
                "Base.CBX_OHI_4",
                "Base.CBX_OHI_5",
                "Base.CBX_OHI_6",
                "Base.CBX_OHI_7",
                "Base.CBX_OHI_8",
            },
        },
        ClothLeg = {
            items = {
                "Base.CBX_PAN",
                "Base.CBX_PAN_2",
                "Base.CBX_PAN_3",
                "Base.CBX_PAN_4",
                "Base.CBX_SP2",
                "Base.CBX_ST2",
                "Base.CBX_ST3",
                "Base.CBX_ST4",
                "Base.CBX_ST5",
                "Base.CBX_Trousers_Worker",
                "Base.CBX_Waterproof",
            },
        },
        ClothUnder = {
            items = {
                "Base.CBX_LIF1",
                "Base.CBX_LIF1_1",
                "Base.CBX_LIF2",
                "Base.CBX_LIF3",
                "Base.CBX_PAN_5",
                "Base.CBX_PAN_6",
                "Base.CBX_PAN_7",
            },
        },
    },
})
