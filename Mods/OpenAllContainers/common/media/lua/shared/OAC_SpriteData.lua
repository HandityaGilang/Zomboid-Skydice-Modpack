-- From "Open All Containers [B42]" mod -- Author = carlesturo

local CountersContainers = require("OAC_SpriteData_CountersContainers")
local DrawersContainers = require("OAC_SpriteData_DrawersContainers")

-- ------------------------------------------------------------------------------------------------

-- **************** OPEN ALL CONTAINERS - SPRITE DATA - PAIRED SPRITES ****************

local SpritePairs = {
--[[ Large Modern Oven
    ["appliances_cooking_01_40"] = "appliances_cooking_01_41",
    ["appliances_cooking_01_41"] = "appliances_cooking_01_40",
    ["ct_oac_appliances_cooking_01_40"] = "ct_oac_appliances_cooking_01_41",
    ["ct_oac_appliances_cooking_01_41"] = "ct_oac_appliances_cooking_01_40",
	["appliances_cooking_01_42"] = "appliances_cooking_01_43",
	["appliances_cooking_01_43"] = "appliances_cooking_01_42",
	["ct_oac_appliances_cooking_01_42"] = "ct_oac_appliances_cooking_01_43",
	["ct_oac_appliances_cooking_01_43"] = "ct_oac_appliances_cooking_01_42",
    ["appliances_cooking_01_48"] = "appliances_cooking_01_49",
    ["appliances_cooking_01_49"] = "appliances_cooking_01_48",
    ["ct_oac_appliances_cooking_01_48"] = "ct_oac_appliances_cooking_01_49",
    ["ct_oac_appliances_cooking_01_49"] = "ct_oac_appliances_cooking_01_48",
	["appliances_cooking_01_50"] = "appliances_cooking_01_51",
	["appliances_cooking_01_51"] = "appliances_cooking_01_50",
	["ct_oac_appliances_cooking_01_50"] = "ct_oac_appliances_cooking_01_51",
	["ct_oac_appliances_cooking_01_51"] = "ct_oac_appliances_cooking_01_50",--]]
-- Dark Office Desk
    ["location_business_office_generic_01_40"] = "location_business_office_generic_01_41",
    ["location_business_office_generic_01_41"] = "location_business_office_generic_01_40",
    ["ct_oac_location_business_office_generic_01_40"] = "ct_oac_location_business_office_generic_01_56",
    ["ct_oac_location_business_office_generic_01_56"] = "ct_oac_location_business_office_generic_01_40",
    ["ct_oac_location_business_office_generic_01_41"] = "ct_oac_location_business_office_generic_01_57",
    ["ct_oac_location_business_office_generic_01_57"] = "ct_oac_location_business_office_generic_01_41",
    ["location_business_office_generic_01_42"] = "location_business_office_generic_01_43",
    ["location_business_office_generic_01_43"] = "location_business_office_generic_01_42",
    ["ct_oac_location_business_office_generic_01_42"] = "ct_oac_location_business_office_generic_01_58",
    ["ct_oac_location_business_office_generic_01_58"] = "ct_oac_location_business_office_generic_01_42",
    ["ct_oac_location_business_office_generic_01_43"] = "ct_oac_location_business_office_generic_01_59",
    ["ct_oac_location_business_office_generic_01_59"] = "ct_oac_location_business_office_generic_01_43",
    ["location_business_office_generic_01_44"] = "location_business_office_generic_01_45",
    ["location_business_office_generic_01_45"] = "location_business_office_generic_01_44",
    ["ct_oac_location_business_office_generic_01_60"] = "ct_oac_location_business_office_generic_01_45",
    ["ct_oac_location_business_office_generic_01_45"] = "ct_oac_location_business_office_generic_01_60",
    ["ct_oac_location_business_office_generic_01_61"] = "ct_oac_location_business_office_generic_01_46",
    ["ct_oac_location_business_office_generic_01_46"] = "ct_oac_location_business_office_generic_01_61",
    ["location_business_office_generic_01_46"] = "location_business_office_generic_01_47",
    ["location_business_office_generic_01_47"] = "location_business_office_generic_01_46",
    ["ct_oac_location_business_office_generic_01_62"] = "ct_oac_location_business_office_generic_01_47",
    ["ct_oac_location_business_office_generic_01_47"] = "ct_oac_location_business_office_generic_01_62",
    ["ct_oac_location_business_office_generic_01_63"] = "ct_oac_location_business_office_generic_01_55",
    ["ct_oac_location_business_office_generic_01_55"] = "ct_oac_location_business_office_generic_01_63",
-- Fancy White Wardrobe
    ["furniture_storage_01_0"] = "furniture_storage_01_1",
    ["furniture_storage_01_1"] = "furniture_storage_01_0",
    ["ct_oac_furniture_storage_01_0"] = "ct_oac_furniture_storage_01_1",
    ["ct_oac_furniture_storage_01_1"] = "ct_oac_furniture_storage_01_0",
    ["ct_oac_furniture_storage_01_8"] = "ct_oac_furniture_storage_01_9",
    ["ct_oac_furniture_storage_01_9"] = "ct_oac_furniture_storage_01_8",
    ["ct_oac_furniture_storage_01_16"] = "ct_oac_furniture_storage_01_17",
    ["ct_oac_furniture_storage_01_17"] = "ct_oac_furniture_storage_01_16",
    ["furniture_storage_01_2"] = "furniture_storage_01_3",
    ["furniture_storage_01_3"] = "furniture_storage_01_2",
    ["ct_oac_furniture_storage_01_2"] = "ct_oac_furniture_storage_01_3",
    ["ct_oac_furniture_storage_01_3"] = "ct_oac_furniture_storage_01_2",
    ["ct_oac_furniture_storage_01_10"] = "ct_oac_furniture_storage_01_11",
    ["ct_oac_furniture_storage_01_11"] = "ct_oac_furniture_storage_01_10",
    ["ct_oac_furniture_storage_01_18"] = "ct_oac_furniture_storage_01_19",
    ["ct_oac_furniture_storage_01_19"] = "ct_oac_furniture_storage_01_18",
	["furniture_storage_01_4"] = "furniture_storage_01_5",
	["furniture_storage_01_5"] = "furniture_storage_01_4",
	["ct_oac_furniture_storage_01_4"] = "ct_oac_furniture_storage_01_5",
	["ct_oac_furniture_storage_01_5"] = "ct_oac_furniture_storage_01_4",
	["ct_oac_furniture_storage_01_12"] = "ct_oac_furniture_storage_01_13",
	["ct_oac_furniture_storage_01_13"] = "ct_oac_furniture_storage_01_12",
    ["ct_oac_furniture_storage_01_20"] = "ct_oac_furniture_storage_01_21",
    ["ct_oac_furniture_storage_01_21"] = "ct_oac_furniture_storage_01_20",
    ["furniture_storage_01_6"] = "furniture_storage_01_7",
    ["furniture_storage_01_7"] = "furniture_storage_01_6",
    ["ct_oac_furniture_storage_01_6"] = "ct_oac_furniture_storage_01_7",
	["ct_oac_furniture_storage_01_7"] = "ct_oac_furniture_storage_01_6",
    ["ct_oac_furniture_storage_01_14"] = "ct_oac_furniture_storage_01_15",
	["ct_oac_furniture_storage_01_15"] = "ct_oac_furniture_storage_01_14",
    ["ct_oac_furniture_storage_01_22"] = "ct_oac_furniture_storage_01_23",
    ["ct_oac_furniture_storage_01_23"] = "ct_oac_furniture_storage_01_22",
-- Fancy Oak Wardrobe
    ["furniture_storage_01_16"] = "furniture_storage_01_17",
    ["furniture_storage_01_17"] = "furniture_storage_01_16",
    ["ct_oac_furniture_storage_01_48"] = "ct_oac_furniture_storage_01_49",
    ["ct_oac_furniture_storage_01_49"] = "ct_oac_furniture_storage_01_48",
    ["ct_oac_furniture_storage_01_56"] = "ct_oac_furniture_storage_01_57",
    ["ct_oac_furniture_storage_01_57"] = "ct_oac_furniture_storage_01_56",
    ["ct_oac_furniture_storage_01_64"] = "ct_oac_furniture_storage_01_65",
    ["ct_oac_furniture_storage_01_65"] = "ct_oac_furniture_storage_01_64",
    ["furniture_storage_01_18"] = "furniture_storage_01_19",
    ["furniture_storage_01_19"] = "furniture_storage_01_18",
    ["ct_oac_furniture_storage_01_50"] = "ct_oac_furniture_storage_01_51",
    ["ct_oac_furniture_storage_01_51"] = "ct_oac_furniture_storage_01_50",
    ["ct_oac_furniture_storage_01_58"] = "ct_oac_furniture_storage_01_59",
    ["ct_oac_furniture_storage_01_59"] = "ct_oac_furniture_storage_01_58",
    ["ct_oac_furniture_storage_01_66"] = "ct_oac_furniture_storage_01_67",
    ["ct_oac_furniture_storage_01_67"] = "ct_oac_furniture_storage_01_66",
	["furniture_storage_01_20"] = "furniture_storage_01_21",
	["furniture_storage_01_21"] = "furniture_storage_01_20",
	["ct_oac_furniture_storage_01_52"] = "ct_oac_furniture_storage_01_53",
	["ct_oac_furniture_storage_01_53"] = "ct_oac_furniture_storage_01_52",
	["ct_oac_furniture_storage_01_60"] = "ct_oac_furniture_storage_01_61",
	["ct_oac_furniture_storage_01_61"] = "ct_oac_furniture_storage_01_60",
    ["ct_oac_furniture_storage_01_68"] = "ct_oac_furniture_storage_01_69",
    ["ct_oac_furniture_storage_01_69"] = "ct_oac_furniture_storage_01_68",
    ["furniture_storage_01_22"] = "furniture_storage_01_23",
    ["furniture_storage_01_23"] = "furniture_storage_01_22",
    ["ct_oac_furniture_storage_01_54"] = "ct_oac_furniture_storage_01_55",
	["ct_oac_furniture_storage_01_55"] = "ct_oac_furniture_storage_01_54",
    ["ct_oac_furniture_storage_01_62"] = "ct_oac_furniture_storage_01_63",
	["ct_oac_furniture_storage_01_63"] = "ct_oac_furniture_storage_01_62",
    ["ct_oac_furniture_storage_01_70"] = "ct_oac_furniture_storage_01_71",
    ["ct_oac_furniture_storage_01_71"] = "ct_oac_furniture_storage_01_70",
-- Dark Fancy Wardrobe
    ["furniture_storage_01_24"] = "furniture_storage_01_25",
    ["furniture_storage_01_25"] = "furniture_storage_01_24",
    ["ct_oac_furniture_storage_01_72"] = "ct_oac_furniture_storage_01_73",
    ["ct_oac_furniture_storage_01_73"] = "ct_oac_furniture_storage_01_72",
    ["furniture_storage_01_26"] = "furniture_storage_01_27",
    ["furniture_storage_01_27"] = "furniture_storage_01_26",
    ["ct_oac_furniture_storage_01_74"] = "ct_oac_furniture_storage_01_75",
    ["ct_oac_furniture_storage_01_75"] = "ct_oac_furniture_storage_01_74",
	["furniture_storage_01_28"] = "furniture_storage_01_29",
	["furniture_storage_01_29"] = "furniture_storage_01_28",
	["ct_oac_furniture_storage_01_76"] = "ct_oac_furniture_storage_01_77",
	["ct_oac_furniture_storage_01_77"] = "ct_oac_furniture_storage_01_76",
    ["furniture_storage_01_30"] = "furniture_storage_01_31",
    ["furniture_storage_01_31"] = "furniture_storage_01_30",
    ["ct_oac_furniture_storage_01_78"] = "ct_oac_furniture_storage_01_79",
    ["ct_oac_furniture_storage_01_79"] = "ct_oac_furniture_storage_01_78",
-- Large Wardrobe
    ["furniture_storage_01_36"] = "furniture_storage_01_37",
    ["furniture_storage_01_37"] = "furniture_storage_01_36",
    ["ct_oac_furniture_storage_01_88"] = "ct_oac_furniture_storage_01_89",
    ["ct_oac_furniture_storage_01_89"] = "ct_oac_furniture_storage_01_88",
	["ct_oac_furniture_storage_01_96"] = "ct_oac_furniture_storage_01_97",
    ["ct_oac_furniture_storage_01_97"] = "ct_oac_furniture_storage_01_96",
    ["furniture_storage_01_38"] = "furniture_storage_01_39",
    ["furniture_storage_01_39"] = "furniture_storage_01_38",
    ["ct_oac_furniture_storage_01_90"] = "ct_oac_furniture_storage_01_91",
    ["ct_oac_furniture_storage_01_91"] = "ct_oac_furniture_storage_01_90",
    ["ct_oac_furniture_storage_01_98"] = "ct_oac_furniture_storage_01_99",
    ["ct_oac_furniture_storage_01_99"] = "ct_oac_furniture_storage_01_98",
	["furniture_storage_02_20"] = "furniture_storage_02_21",
	["furniture_storage_02_21"] = "furniture_storage_02_20",
	["ct_oac_furniture_storage_01_92"] = "ct_oac_furniture_storage_01_93",
	["ct_oac_furniture_storage_01_93"] = "ct_oac_furniture_storage_01_92",
    ["ct_oac_furniture_storage_01_100"] = "ct_oac_furniture_storage_01_101",
    ["ct_oac_furniture_storage_01_101"] = "ct_oac_furniture_storage_01_100",
    ["furniture_storage_02_22"] = "furniture_storage_02_23",
    ["furniture_storage_02_23"] = "furniture_storage_02_22",
    ["ct_oac_furniture_storage_01_94"] = "ct_oac_furniture_storage_01_95",
    ["ct_oac_furniture_storage_01_95"] = "ct_oac_furniture_storage_01_94",
    ["ct_oac_furniture_storage_01_102"] = "ct_oac_furniture_storage_01_103",
    ["ct_oac_furniture_storage_01_103"] = "ct_oac_furniture_storage_01_102",
-- Light Wood Wardrobe
    ["furniture_storage_01_56"] = "furniture_storage_01_57",
    ["furniture_storage_01_57"] = "furniture_storage_01_56",
    ["ct_oac_furniture_storage_01_136"] = "ct_oac_furniture_storage_01_137",
    ["ct_oac_furniture_storage_01_137"] = "ct_oac_furniture_storage_01_136",
    ["ct_oac_furniture_storage_01_144"] = "ct_oac_furniture_storage_01_145",
    ["ct_oac_furniture_storage_01_145"] = "ct_oac_furniture_storage_01_144",
    ["ct_oac_furniture_storage_01_152"] = "ct_oac_furniture_storage_01_153",
    ["ct_oac_furniture_storage_01_153"] = "ct_oac_furniture_storage_01_152",
    ["furniture_storage_01_58"] = "furniture_storage_01_59",
    ["furniture_storage_01_59"] = "furniture_storage_01_58",
    ["ct_oac_furniture_storage_01_138"] = "ct_oac_furniture_storage_01_139",
    ["ct_oac_furniture_storage_01_139"] = "ct_oac_furniture_storage_01_138",
    ["ct_oac_furniture_storage_01_146"] = "ct_oac_furniture_storage_01_147",
    ["ct_oac_furniture_storage_01_147"] = "ct_oac_furniture_storage_01_146",
    ["ct_oac_furniture_storage_01_154"] = "ct_oac_furniture_storage_01_155",
    ["ct_oac_furniture_storage_01_155"] = "ct_oac_furniture_storage_01_154",
	["furniture_storage_01_60"] = "furniture_storage_01_61",
	["furniture_storage_01_61"] = "furniture_storage_01_60",
	["ct_oac_furniture_storage_01_140"] = "ct_oac_furniture_storage_01_141",
	["ct_oac_furniture_storage_01_141"] = "ct_oac_furniture_storage_01_140",
	["ct_oac_furniture_storage_01_148"] = "ct_oac_furniture_storage_01_149",
	["ct_oac_furniture_storage_01_149"] = "ct_oac_furniture_storage_01_148",
    ["ct_oac_furniture_storage_01_156"] = "ct_oac_furniture_storage_01_157",
    ["ct_oac_furniture_storage_01_157"] = "ct_oac_furniture_storage_01_156",
    ["furniture_storage_01_62"] = "furniture_storage_01_63",
    ["furniture_storage_01_63"] = "furniture_storage_01_62",
    ["ct_oac_furniture_storage_01_142"] = "ct_oac_furniture_storage_01_143",
	["ct_oac_furniture_storage_01_143"] = "ct_oac_furniture_storage_01_142",
    ["ct_oac_furniture_storage_01_150"] = "ct_oac_furniture_storage_01_151",
	["ct_oac_furniture_storage_01_151"] = "ct_oac_furniture_storage_01_150",
    ["ct_oac_furniture_storage_01_158"] = "ct_oac_furniture_storage_01_159",
    ["ct_oac_furniture_storage_01_159"] = "ct_oac_furniture_storage_01_158",
-- China Cabinet
    ["furniture_storage_02_32"] = "furniture_storage_02_33",
    ["furniture_storage_02_33"] = "furniture_storage_02_32",
    ["ct_oac_furniture_storage_02_32"] = "ct_oac_furniture_storage_02_33",
    ["ct_oac_furniture_storage_02_33"] = "ct_oac_furniture_storage_02_32",
    ["ct_oac_furniture_storage_02_56"] = "ct_oac_furniture_storage_02_57",
    ["ct_oac_furniture_storage_02_57"] = "ct_oac_furniture_storage_02_56",
    --[[["ct_oac_furniture_storage_02_64"] = "ct_oac_furniture_storage_02_64",
    ["ct_oac_furniture_storage_02_65"] = "ct_oac_furniture_storage_02_65",
    ["ct_oac_furniture_storage_02_72"] = "ct_oac_furniture_storage_02_73",
    ["ct_oac_furniture_storage_02_73"] = "ct_oac_furniture_storage_02_72",
    ["ct_oac_furniture_storage_02_80"] = "ct_oac_furniture_storage_02_81",
    ["ct_oac_furniture_storage_02_81"] = "ct_oac_furniture_storage_02_80",
    ["ct_oac_furniture_storage_02_88"] = "ct_oac_furniture_storage_02_89",
    ["ct_oac_furniture_storage_02_89"] = "ct_oac_furniture_storage_02_88",--]]
    ["furniture_storage_02_34"] = "furniture_storage_02_35",
    ["furniture_storage_02_35"] = "furniture_storage_02_34",
    ["ct_oac_furniture_storage_02_34"] = "ct_oac_furniture_storage_02_35",
    ["ct_oac_furniture_storage_02_35"] = "ct_oac_furniture_storage_02_34",
    ["ct_oac_furniture_storage_02_58"] = "ct_oac_furniture_storage_02_59",
    ["ct_oac_furniture_storage_02_59"] = "ct_oac_furniture_storage_02_58",
    --[[["ct_oac_furniture_storage_02_66"] = "ct_oac_furniture_storage_02_66",
    ["ct_oac_furniture_storage_02_67"] = "ct_oac_furniture_storage_02_67",
    ["ct_oac_furniture_storage_02_74"] = "ct_oac_furniture_storage_02_75",
    ["ct_oac_furniture_storage_02_75"] = "ct_oac_furniture_storage_02_74",
    ["ct_oac_furniture_storage_02_82"] = "ct_oac_furniture_storage_02_83",
    ["ct_oac_furniture_storage_02_83"] = "ct_oac_furniture_storage_02_82",
    ["ct_oac_furniture_storage_02_90"] = "ct_oac_furniture_storage_02_91",
    ["ct_oac_furniture_storage_02_91"] = "ct_oac_furniture_storage_02_90",--]]
	["furniture_storage_02_36"] = "furniture_storage_02_37",
	["furniture_storage_02_37"] = "furniture_storage_02_36",
	["ct_oac_furniture_storage_02_36"] = "ct_oac_furniture_storage_02_37",
	["ct_oac_furniture_storage_02_37"] = "ct_oac_furniture_storage_02_36",
	["ct_oac_furniture_storage_02_60"] = "ct_oac_furniture_storage_02_61",
	["ct_oac_furniture_storage_02_61"] = "ct_oac_furniture_storage_02_60",
    --[[["ct_oac_furniture_storage_02_68"] = "ct_oac_furniture_storage_02_69",
    ["ct_oac_furniture_storage_02_69"] = "ct_oac_furniture_storage_02_68",
    ["ct_oac_furniture_storage_02_76"] = "ct_oac_furniture_storage_02_77",
    ["ct_oac_furniture_storage_02_77"] = "ct_oac_furniture_storage_02_76",
    ["ct_oac_furniture_storage_02_84"] = "ct_oac_furniture_storage_02_85",
    ["ct_oac_furniture_storage_02_85"] = "ct_oac_furniture_storage_02_84",
    ["ct_oac_furniture_storage_02_92"] = "ct_oac_furniture_storage_02_93",
    ["ct_oac_furniture_storage_02_93"] = "ct_oac_furniture_storage_02_92",--]]
    ["furniture_storage_02_38"] = "furniture_storage_02_39",
    ["furniture_storage_02_39"] = "furniture_storage_02_38",
    ["ct_oac_furniture_storage_02_38"] = "ct_oac_furniture_storage_02_39",
	["ct_oac_furniture_storage_02_39"] = "ct_oac_furniture_storage_02_38",
    ["ct_oac_furniture_storage_02_62"] = "ct_oac_furniture_storage_02_63",
	["ct_oac_furniture_storage_02_63"] = "ct_oac_furniture_storage_02_62",
    --[[["ct_oac_furniture_storage_02_70"] = "ct_oac_furniture_storage_02_71",
    ["ct_oac_furniture_storage_02_71"] = "ct_oac_furniture_storage_02_70",
    ["ct_oac_furniture_storage_02_78"] = "ct_oac_furniture_storage_02_79",
    ["ct_oac_furniture_storage_02_79"] = "ct_oac_furniture_storage_02_78",
    ["ct_oac_furniture_storage_02_86"] = "ct_oac_furniture_storage_02_87",
    ["ct_oac_furniture_storage_02_87"] = "ct_oac_furniture_storage_02_86",
    ["ct_oac_furniture_storage_02_94"] = "ct_oac_furniture_storage_02_95",
    ["ct_oac_furniture_storage_02_95"] = "ct_oac_furniture_storage_02_94",--]]
-- Beige Wardrobe
    ["furniture_storage_02_40"] = "furniture_storage_02_41",
    ["furniture_storage_02_41"] = "furniture_storage_02_40",
    ["ct_oac_furniture_storage_02_40"] = "ct_oac_furniture_storage_02_41",
    ["ct_oac_furniture_storage_02_41"] = "ct_oac_furniture_storage_02_40",
    ["furniture_storage_02_42"] = "furniture_storage_02_43",
    ["furniture_storage_02_43"] = "furniture_storage_02_42",
    ["ct_oac_furniture_storage_02_42"] = "ct_oac_furniture_storage_02_43",
    ["ct_oac_furniture_storage_02_43"] = "ct_oac_furniture_storage_02_42",
	["furniture_storage_02_44"] = "furniture_storage_02_45",
	["furniture_storage_02_45"] = "furniture_storage_02_44",
	["ct_oac_furniture_storage_02_44"] = "ct_oac_furniture_storage_02_45",
	["ct_oac_furniture_storage_02_45"] = "ct_oac_furniture_storage_02_44",
    ["furniture_storage_02_46"] = "furniture_storage_02_47",
    ["furniture_storage_02_47"] = "furniture_storage_02_46",
    ["ct_oac_furniture_storage_02_46"] = "ct_oac_furniture_storage_02_47",
    ["ct_oac_furniture_storage_02_47"] = "ct_oac_furniture_storage_02_46",
-- Orange Dumpster
    ["trashcontainers_01_12"] = "trashcontainers_01_13",
    ["trashcontainers_01_13"] = "trashcontainers_01_12",
    ["ct_oac_trashcontainers_01_12"] = "ct_oac_trashcontainers_01_13",
    ["ct_oac_trashcontainers_01_13"] = "ct_oac_trashcontainers_01_12",
	["trashcontainers_01_14"] = "trashcontainers_01_15",
	["trashcontainers_01_15"] = "trashcontainers_01_14",
	["ct_oac_trashcontainers_01_14"] = "ct_oac_trashcontainers_01_15",
	["ct_oac_trashcontainers_01_15"] = "ct_oac_trashcontainers_01_14"
}

-- ------------------------------------------------------------------------------------------------

-- **************** OPEN ALL CONTAINERS - SPRITE DATA - COOKING APPLIANCES ****************

--[[local GreenOvenEast = {
    originalSprite = "appliances_cooking_01_0",
	openSprite = "ct_oac_appliances_cooking_01_0"
}

local GreenOvenSouth = {
    originalSprite = "appliances_cooking_01_1",
	openSprite = "ct_oac_appliances_cooking_01_1"
}

local GreenOvenWest = {
    originalSprite = "appliances_cooking_01_2",
	openSprite = "ct_oac_appliances_cooking_01_2"
}

local GreenOvenNorth = {
    originalSprite = "appliances_cooking_01_3",
	openSprite = "ct_oac_appliances_cooking_01_3"
}
-- ------------------------------------------------------------------------------------------------
local GrayOvenEast = {
    originalSprite = "appliances_cooking_01_4",
	openSprite = "ct_oac_appliances_cooking_01_4"
}

local GrayOvenSouth = {
    originalSprite = "appliances_cooking_01_5",
	openSprite = "ct_oac_appliances_cooking_01_5"
}

local GrayOvenWest = {
    originalSprite = "appliances_cooking_01_6",
	openSprite = "ct_oac_appliances_cooking_01_6"
}

local GrayOvenNorth = {
    originalSprite = "appliances_cooking_01_7",
	openSprite = "ct_oac_appliances_cooking_01_7"
}
-- ------------------------------------------------------------------------------------------------
local RedOvenEast = {
    originalSprite = "appliances_cooking_01_8",
	openSprite = "ct_oac_appliances_cooking_01_8"
}

local RedOvenSouth = {
    originalSprite = "appliances_cooking_01_9",
	openSprite = "ct_oac_appliances_cooking_01_9"
}

local RedOvenWest = {
    originalSprite = "appliances_cooking_01_10",
	openSprite = "ct_oac_appliances_cooking_01_10"
}

local RedOvenNorth = {
    originalSprite = "appliances_cooking_01_11",
	openSprite = "ct_oac_appliances_cooking_01_11"
}
-- ------------------------------------------------------------------------------------------------
local ModernOvenEast = {
    originalSprite = "appliances_cooking_01_12",
	openSprite = "ct_oac_appliances_cooking_01_12"
}

local ModernOvenSouth = {
    originalSprite = "appliances_cooking_01_13",
	openSprite = "ct_oac_appliances_cooking_01_13"
}

local ModernOvenWest = {
    originalSprite = "appliances_cooking_01_14",
	openSprite = "ct_oac_appliances_cooking_01_14"
}

local ModernOvenNorth = {
    originalSprite = "appliances_cooking_01_15",
	openSprite = "ct_oac_appliances_cooking_01_15"
}
-- ------------------------------------------------------------------------------------------------
local OldStoveEast = {
    originalSprite = "appliances_cooking_01_16",
	openSprite = "ct_oac_appliances_cooking_01_16"
}

local OldStoveSouth = {
    originalSprite = "appliances_cooking_01_17",
	openSprite = "ct_oac_appliances_cooking_01_17"
}

local OldStoveNorth = {
    originalSprite = "appliances_cooking_01_18",
	openSprite = "ct_oac_appliances_cooking_01_18"
}

local OldStoveWest = {
    originalSprite = "appliances_cooking_01_19",
	openSprite = "ct_oac_appliances_cooking_01_19"
}
-- ------------------------------------------------------------------------------------------------
local IndustrialOvenEast = {
    originalSprite = "appliances_cooking_01_20",
	openSprite = "ct_oac_appliances_cooking_01_20"
}

local IndustrialOvenSouth = {
    originalSprite = "appliances_cooking_01_21",
	openSprite = "ct_oac_appliances_cooking_01_21"
}

local IndustrialOvenWest = {
    originalSprite = "appliances_cooking_01_22",
	openSprite = "ct_oac_appliances_cooking_01_22"
}

local IndustrialOvenNorth = {
    originalSprite = "appliances_cooking_01_23",
	openSprite = "ct_oac_appliances_cooking_01_23"
}
-- ------------------------------------------------------------------------------------------------
local WhiteMicrowaveEast = {
    originalSprite = "appliances_cooking_01_24",
	openSprite = "ct_oac_appliances_cooking_01_24"
}

local WhiteMicrowaveSouth = {
    originalSprite = "appliances_cooking_01_25",
	openSprite = "ct_oac_appliances_cooking_01_25"
}

local WhiteMicrowaveWest = {
    originalSprite = "appliances_cooking_01_26",
	openSprite = "ct_oac_appliances_cooking_01_26"
}

local WhiteMicrowaveNorth = {
    originalSprite = "appliances_cooking_01_27",
	openSprite = "ct_oac_appliances_cooking_01_27"
}
-- ------------------------------------------------------------------------------------------------
local ChromeMicrowaveSouth = {
    originalSprite = "appliances_cooking_01_28",
	openSprite = "ct_oac_appliances_cooking_01_28"
}

local ChromeMicrowaveEast = {
    originalSprite = "appliances_cooking_01_29",
	openSprite = "ct_oac_appliances_cooking_01_29"
}

local ChromeMicrowaveWest = {
    originalSprite = "appliances_cooking_01_30",
	openSprite = "ct_oac_appliances_cooking_01_30"
}

local ChromeMicrowaveNorth = {
    originalSprite = "appliances_cooking_01_31",
	openSprite = "ct_oac_appliances_cooking_01_31"
}--]]
-- ------------------------------------------------------------------------------------------------
--[[local Barbecue = {
    originalSprite = "appliances_cooking_01_35",
	openSprite = "ct_oac_appliances_cooking_01_35"
}
-- ------------------------------------------------------------------------------------------------
local JorgeForeguyBarbecueSouth = {
    originalSprite = "appliances_cooking_01_36",
	openSprite = "ct_oac_appliances_cooking_01_36"
}

local JorgeForeguyBarbecueEast = {
    originalSprite = "appliances_cooking_01_37",
	openSprite = "ct_oac_appliances_cooking_01_37"
}

local JorgeForeguyBarbecueNorth = {
    originalSprite = "appliances_cooking_01_38",
	openSprite = "ct_oac_appliances_cooking_01_38"
}

local JorgeForeguyBarbecueWest = {
    originalSprite = "appliances_cooking_01_39",
	openSprite = "ct_oac_appliances_cooking_01_39"
}
-- ------------------------------------------------------------------------------------------------
local EmptyJorgeForeguyBarbecueSouth = {
    originalSprite = "appliances_cooking_01_44",
	openSprite = "ct_oac_appliances_cooking_01_44"
}

local EmptyJorgeForeguyBarbecueEast = {
    originalSprite = "appliances_cooking_01_45",
	openSprite = "ct_oac_appliances_cooking_01_45"
}

local EmptyJorgeForeguyBarbecueNorth = {
    originalSprite = "appliances_cooking_01_46",
	openSprite = "ct_oac_appliances_cooking_01_46"
}

local EmptyJorgeForeguyBarbecueWest = {
    originalSprite = "appliances_cooking_01_47",
	openSprite = "ct_oac_appliances_cooking_01_47"
}--]]
-- ------------------------------------------------------------------------------------------------
--[[local LargeModernOvenLeftEast = {
    originalSprite = "appliances_cooking_01_40",
	openSprite = "ct_oac_appliances_cooking_01_40",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local LargeModernOvenRightEast = {
    originalSprite = "appliances_cooking_01_41",
	openSprite = "ct_oac_appliances_cooking_01_41",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local LargeModernOvenLeftSouth = {
    originalSprite = "appliances_cooking_01_42",
	openSprite = "ct_oac_appliances_cooking_01_42",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local LargeModernOvenRightSouth = {
    originalSprite = "appliances_cooking_01_43",
	openSprite = "ct_oac_appliances_cooking_01_43",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}

local LargeModernOvenLeftWest = {
    originalSprite = "appliances_cooking_01_48",
	openSprite = "ct_oac_appliances_cooking_01_48",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local LargeModernOvenRightWest = {
    originalSprite = "appliances_cooking_01_49",
	openSprite = "ct_oac_appliances_cooking_01_49",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local LargeModernOvenLeftNorth = {
    originalSprite = "appliances_cooking_01_50",
	openSprite = "ct_oac_appliances_cooking_01_50",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local LargeModernOvenRightNorth = {
    originalSprite = "appliances_cooking_01_51",
	openSprite = "ct_oac_appliances_cooking_01_51",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}--]]
-- ------------------------------------------------------------------------------------------------
--[[local CraftedStoveNorth = {
    originalSprite = "crafted_05_4",
	openSprite = "ct_oac_crafted_05_4"
}

local CraftedStoveWest = {
    originalSprite = "crafted_05_5",
	openSprite = "ct_oac_crafted_05_5"
}

local CraftedStoveEast = {
    originalSprite = "crafted_05_6",
	openSprite = "ct_oac_crafted_05_6"
}

local CraftedStoveSouth = {
    originalSprite = "crafted_05_7",
	openSprite = "ct_oac_crafted_05_7"
}--]]
-- ------------------------------------------------------------------------------------------------

-- **************** OPEN ALL CONTAINERS - SPRITE DATA - FRIDGES APPLIANCES ****************

--[[local WhiteFridgeSouth = {
    originalSprite = "appliances_refrigeration_01_0",
	openSprite = "ct_oac_appliances_refrigeration_01_1",
	doorSprite = {dx = 1, dy = 1, sprite = "ct_oac_appliances_refrigeration_01_0"},
    overlayOpenSprite = {
        ["appliances_01_0"] = "ct_oac_appliances_01_13",
        ["appliances_01_2"] = "ct_oac_appliances_01_2",
        ["appliances_02_16"] = "ct_oac_appliances_01_13",
		["appliances_01_18"] = "ct_oac_appliances_01_5",
		["appliances_01_12"] = "ct_oac_appliances_01_7",
		["appliances_01_14"] = "ct_oac_appliances_01_13"
    },
    overlayDoorSprite = {
        ["appliances_01_0"] = "ct_oac_appliances_01_0",
        ["appliances_01_2"] = "ct_oac_appliances_01_1",
        ["appliances_02_16"] = "ct_oac_appliances_01_3",
		["appliances_01_18"] = "ct_oac_appliances_01_4",
		["appliances_01_12"] = "ct_oac_appliances_01_6",
		["appliances_01_14"] = "ct_oac_appliances_01_8"
    },
	autoClosed = true
}

local WhiteFridgeEast = {
    originalSprite = "appliances_refrigeration_01_1",
	openSprite = "ct_oac_appliances_refrigeration_01_2",
	doorSprite = {dx = 1, dy = 0, sprite = "ct_oac_appliances_refrigeration_01_3"},
    overlayOpenSprite = {
        ["appliances_01_1"] = "ct_oac_appliances_01_9",
        ["appliances_01_3"] = "ct_oac_appliances_01_10",
        ["appliances_02_13"] = "ct_oac_appliances_01_11",
		["appliances_01_15"] = "ct_oac_appliances_01_13",
		["appliances_01_17"] = "ct_oac_appliances_01_12",
		["appliances_01_19"] = "ct_oac_appliances_01_13"
    },
	autoClosed = true
}

local WhiteFridgeNorth = {
    originalSprite = "appliances_refrigeration_01_2",
	openSprite = "ct_oac_appliances_refrigeration_01_4",
	doorSprite = {dx = 0, dy = -1, sprite = "ct_oac_appliances_refrigeration_01_5"},
	autoClosed = true
}

local WhiteFridgeWest = {
    originalSprite = "appliances_refrigeration_01_3",
	openSprite = "ct_oac_appliances_refrigeration_01_7",
	doorSprite = {dx = -1, dy = 1, sprite = "ct_oac_appliances_refrigeration_01_6"},
	autoClosed = true
}--]]

-- ------------------------------------------------------------------------------------------------

-- **************** OPEN ALL CONTAINERS - SPRITE DATA - WASHING MACHINES APPLIANCES ****************

local BlueComboWasherDryerSouth = {
    originalSprite = "appliances_laundry_01_0",
	openSprite = "ct_oac_appliances_laundry_01_0",
    overlayOpenSprite = {
		["appliances_01_48"] = "ct_oac_appliances_01_48",
		["appliances_01_50"] = "ct_oac_appliances_01_50"
    }
}

local BlueComboWasherDryerEast = {
    originalSprite = "appliances_laundry_01_1",
	openSprite = "ct_oac_appliances_laundry_01_1",
    overlayOpenSprite = {
		["appliances_01_49"] = "ct_oac_appliances_01_49",
		["appliances_01_51"] = "ct_oac_appliances_01_51"
    }
}

local BlueComboWasherDryerNorth = {
    originalSprite = "appliances_laundry_01_2",
	openSprite = "ct_oac_appliances_laundry_01_2"
}

local BlueComboWasherDryerWest = {
    originalSprite = "appliances_laundry_01_3",
	openSprite = "ct_oac_appliances_laundry_01_3"
}
-- ------------------------------------------------------------------------------------------------
local WashingMachineSouth = {
    originalSprite = "appliances_laundry_01_4",
	openSprite = "ct_oac_appliances_laundry_01_4",
    overlayOpenSprite = {
		["appliances_01_52"] = "ct_oac_appliances_01_52"
    }
}

local WashingMachineEast = {
    originalSprite = "appliances_laundry_01_5",
	openSprite = "ct_oac_appliances_laundry_01_5",
    overlayOpenSprite = {
		["appliances_01_53"] = "ct_oac_appliances_01_53"
    }
}

local WashingMachineNorth = {
    originalSprite = "appliances_laundry_01_6",
	openSprite = "ct_oac_appliances_laundry_01_6",
    overlayOpenSprite = {
		["appliances_01_54"] = "ct_oac_appliances_01_54"
    }
}

local WashingMachineWest = {
    originalSprite = "appliances_laundry_01_7",
	openSprite = "ct_oac_appliances_laundry_01_7",
    overlayOpenSprite = {
		["appliances_01_55"] = "ct_oac_appliances_01_55"
    }
}
-- ------------------------------------------------------------------------------------------------
local ClothesDryerSouth = {
    originalSprite = "appliances_laundry_01_12",
	openSprite = "ct_oac_appliances_laundry_01_12",
    overlayOpenSprite = {
		["appliances_01_60"] = "ct_oac_appliances_01_60"
    }
}

local ClothesDryerEast = {
    originalSprite = "appliances_laundry_01_13",
	openSprite = "ct_oac_appliances_laundry_01_13",
    overlayOpenSprite = {
		["appliances_01_61"] = "ct_oac_appliances_01_61"
    }
}

local ClothesDryerNorth = {
    originalSprite = "appliances_laundry_01_14",
	openSprite = "ct_oac_appliances_laundry_01_14"
}

local ClothesDryerWest = {
    originalSprite = "appliances_laundry_01_15",
	openSprite = "ct_oac_appliances_laundry_01_15"
}

-- ------------------------------------------------------------------------------------------------

-- **************** OPEN ALL CONTAINERS - SPRITE DATA - BINS CONTAINERS ****************

local PizzaWhirledGarbageBinSouth = {
    originalSprite = "location_restaurant_pizzawhirled_01_17",
	openSprite = "ct_oac_location_restaurant_pizzawhirled_01_17",
	autoClosed = true
}

local PizzaWhirledGarbageBinEast = {
    originalSprite = "location_restaurant_pizzawhirled_01_18",
	openSprite = "ct_oac_location_restaurant_pizzawhirled_01_18",
	autoClosed = true
}
-- ------------------------------------------------------------------------------------------------
local SeahorseCoffeeGarbageBinSouth = {
    originalSprite = "location_restaurant_seahorse_01_38",
	openSprite = "ct_oac_location_restaurant_seahorse_01_38",
	autoClosed = true
}

local SeahorseCoffeeGarbageBinEast = {
    originalSprite = "location_restaurant_seahorse_01_39",
	openSprite = "ct_oac_location_restaurant_seahorse_01_39",
	autoClosed = true
}
-- ------------------------------------------------------------------------------------------------
local SpiffosGarbageBinSouth = {
    originalSprite = "location_restaurant_spiffos_01_30",
	openSprite = "ct_oac_location_restaurant_spiffos_01_30",
	autoClosed = true
}

local SpiffosGarbageBinEast = {
    originalSprite = "location_restaurant_spiffos_01_31",
	openSprite = "ct_oac_location_restaurant_spiffos_01_31",
	autoClosed = true
}
-- ------------------------------------------------------------------------------------------------
local FossoilGarbageBinSouth = {
    originalSprite = "location_shop_fossoil_01_32",
	openSprite = "ct_oac_location_shop_fossoil_01_32",
	autoClosed = true
}

local FossoilGarbageBinEast = {
    originalSprite = "location_shop_fossoil_01_33",
	openSprite = "ct_oac_location_shop_fossoil_01_33",
	autoClosed = true
}
-- ------------------------------------------------------------------------------------------------
local WheelieBinSouth = {
    originalSprite = "trashcontainers_01_0",
	openSprite = "ct_oac_trashcontainers_01_0"
}

local WheelieBinEast = {
    originalSprite = "trashcontainers_01_1",
	openSprite = "ct_oac_trashcontainers_01_1"
}

local WheelieBinNorth = {
    originalSprite = "trashcontainers_01_2",
	openSprite = "ct_oac_trashcontainers_01_2"
}

local WheelieBinWest = {
    originalSprite = "trashcontainers_01_3",
	openSprite = "ct_oac_trashcontainers_01_3"
}
-- ------------------------------------------------------------------------------------------------
local RecycleBin = {
    originalSprite = "trashcontainers_01_16",
	openSprite = "ct_oac_trashcontainers_01_16"
}
-- ------------------------------------------------------------------------------------------------
local GrayGarbageBinSouth = {
    originalSprite = "trashcontainers_01_18",
	openSprite = "ct_oac_trashcontainers_01_18",
	autoClosed = true
}

local GrayGarbageBinEast = {
    originalSprite = "trashcontainers_01_19",
	openSprite = "ct_oac_trashcontainers_01_19",
	autoClosed = true
}

-- ------------------------------------------------------------------------------------------------

-- **************** OPEN ALL CONTAINERS - SPRITE DATA - OTHER CONTAINERS ****************

local CraftedTableWithDrawerEast = {
    originalSprite = "carpentry_02_4",
	openSprite = "ct_oac_carpentry_02_4",
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close"
}

local CraftedTableWithDrawerSouth = {
    originalSprite = "carpentry_02_5",
	openSprite = "ct_oac_carpentry_02_5",
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close"
}

local CraftedTableWithDrawerWest = {
    originalSprite = "carpentry_02_6",
	openSprite = "ct_oac_carpentry_02_6",
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close"
}

local CraftedTableWithDrawerNorth = {
    originalSprite = "carpentry_02_7",
	openSprite = "ct_oac_carpentry_02_7",
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close"
}
-- ------------------------------------------------------------------------------------------------
local QualityCraftedTableWithDrawerEast = {
    originalSprite = "carpentry_02_8",
	openSprite = "ct_oac_carpentry_02_8",
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close"
}

local QualityCraftedTableWithDrawerSouth = {
    originalSprite = "carpentry_02_9",
	openSprite = "ct_oac_carpentry_02_9",
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close"
}

local QualityCraftedTableWithDrawerWest = {
    originalSprite = "carpentry_02_10",
	openSprite = "ct_oac_carpentry_02_10",
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close"
}

local QualityCraftedTableWithDrawerNorth = {
    originalSprite = "carpentry_02_11",
	openSprite = "ct_oac_carpentry_02_11",
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close"
}
-- ------------------------------------------------------------------------------------------------
--[[local MetalCrateNorth = {
    originalSprite = "constructedobjects_01_44",
	openSprite = "ct_oac_constructedobjects_01_44"
}

local MetalCrateWest = {
    originalSprite = "constructedobjects_01_45",
	openSprite = "ct_oac_constructedobjects_01_45"
}

local MetalCrateSouth = {
    originalSprite = "constructedobjects_01_46",
	openSprite = "ct_oac_constructedobjects_01_46"
}

local MetalCrateEast = {
    originalSprite = "constructedobjects_01_47",
	openSprite = "ct_oac_constructedobjects_01_47"
}--]]
-- ------------------------------------------------------------------------------------------------
--crafted_04
-- ------------------------------------------------------------------------------------------------
--crafted_05
-- ------------------------------------------------------------------------------------------------
local MedicineCabinetSouth = {
    originalSprite = "fixtures_bathroom_01_28",
	openSprite = "ct_oac_fixtures_bathroom_01_28"
}

local MedicineCabinetEast = {
    originalSprite = "fixtures_bathroom_01_29",
	openSprite = "ct_oac_fixtures_bathroom_01_29"
}

local MedicineCabinetNorth = {
    originalSprite = "fixtures_bathroom_01_37",
	openSprite = "ct_oac_fixtures_bathroom_01_37"
}

local MedicineCabinetWest = {
    originalSprite = "fixtures_bathroom_01_38",
	openSprite = "ct_oac_fixtures_bathroom_01_38"
}
-- ------------------------------------------------------------------------------------------------
local MetalLockerSouth = {
    originalSprite = "furniture_storage_02_0",
	openSprite = "ct_oac_furniture_storage_02_0",
    overlayOpenSprite = {
        ["storage_01_24"] = "ct_oac_storage_01_48",
		["storage_01_28"] = "ct_oac_storage_01_52",
		["storage_01_30"] = "ct_oac_storage_01_54"
    },
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetalLarge",
	soundOpen = "Open",
	soundClose = "Close"
}

local MetalLockerEast = {
    originalSprite = "furniture_storage_02_1",
	openSprite = "ct_oac_furniture_storage_02_1",
    overlayOpenSprite = {
        ["storage_01_25"] = "ct_oac_storage_01_49",
		["storage_01_29"] = "ct_oac_storage_01_53",
		["storage_01_31"] = "ct_oac_storage_01_55"
    },
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetalLarge",
	soundOpen = "Open",
	soundClose = "Close"
}

local MetalLockerNorth = {
    originalSprite = "furniture_storage_02_2",
	openSprite = "ct_oac_furniture_storage_02_2",
    overlayOpenSprite = {
		["storage_01_26"] = "ct_oac_storage_01_50"
    },
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetalLarge",
	soundOpen = "Open",
	soundClose = "Close"
}

local MetalLockerWest = {
    originalSprite = "furniture_storage_02_3",
	openSprite = "ct_oac_furniture_storage_02_3",
    overlayOpenSprite = {
		["storage_01_27"] = "ct_oac_storage_01_51"
    },
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetalLarge",
	soundOpen = "Open",
	soundClose = "Close"
}
-- ------------------------------------------------------------------------------------------------
local BlueWallLockerEast = {
    originalSprite = "furniture_storage_02_4",
	openSprite = "ct_oac_furniture_storage_02_4",
	openSprite2 = "ct_oac_furniture_storage_02_52",
    overlayOpenSprite = {
        ["storage_01_38"] = "ct_oac_storage_01_74"
    },
    overlayOpenSprite2 = {
        ["storage_01_38"] = "ct_oac_storage_01_78"
    },
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetal",
	soundOpen = "Open",
	soundClose = "Close"
}

local BlueWallLockerSouth = {
    originalSprite = "furniture_storage_02_5",
	openSprite = "ct_oac_furniture_storage_02_5",
	openSprite2 = "ct_oac_furniture_storage_02_53",
    overlayOpenSprite = {
        ["storage_01_39"] = "ct_oac_storage_01_75"
    },
    overlayOpenSprite2 = {
        ["storage_01_39"] = "ct_oac_storage_01_79"
    },
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetal",
	soundOpen = "Open",
	soundClose = "Close"
}

local BlueWallLockerWest = {
    originalSprite = "furniture_storage_02_6",
	openSprite = "ct_oac_furniture_storage_02_6",
	openSprite2 = "ct_oac_furniture_storage_02_54",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetal",
	soundOpen = "Open",
	soundClose = "Close"
}

local BlueWallLockerNorth = {
    originalSprite = "furniture_storage_02_7",
	openSprite = "ct_oac_furniture_storage_02_7",
	openSprite2 = "ct_oac_furniture_storage_02_55",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetal",
	soundOpen = "Open",
	soundClose = "Close"
}
-- ------------------------------------------------------------------------------------------------
local SmallMilitaryLockerSouth = {
    originalSprite = "furniture_storage_02_8",
	openSprite = "ct_oac_furniture_storage_02_8",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetalLarge",
	soundOpen = "Open",
	soundClose = "Close"
}

local SmallMilitaryLockerEast = {
    originalSprite = "furniture_storage_02_9",
	openSprite = "ct_oac_furniture_storage_02_9",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetalLarge",
	soundOpen = "Open",
	soundClose = "Close"
}

local SmallMilitaryLockerNorth = {
    originalSprite = "furniture_storage_02_10",
	openSprite = "ct_oac_furniture_storage_02_10",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetalLarge",
	soundOpen = "Open",
	soundClose = "Close"
}

local SmallMilitaryLockerWest = {
    originalSprite = "furniture_storage_02_11",
	openSprite = "ct_oac_furniture_storage_02_11",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetalLarge",
	soundOpen = "Open",
	soundClose = "Close"
}
-- ------------------------------------------------------------------------------------------------
local YellowWallLockerEast = {
    originalSprite = "furniture_storage_02_12",
	openSprite = "ct_oac_furniture_storage_02_12",
	openSprite2 = "ct_oac_furniture_storage_02_20",
    overlayOpenSprite = {
        ["storage_01_36"] = "ct_oac_storage_01_72"
    },
    overlayOpenSprite2 = {
        ["storage_01_36"] = "ct_oac_storage_01_76"
    },
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetal",
	soundOpen = "Open",
	soundClose = "Close"
}

local YellowWallLockerSouth = {
    originalSprite = "furniture_storage_02_13",
	openSprite = "ct_oac_furniture_storage_02_13",
	openSprite2 = "ct_oac_furniture_storage_02_21",
    overlayOpenSprite = {
        ["storage_01_37"] = "ct_oac_storage_01_73"
    },
    overlayOpenSprite2 = {
        ["storage_01_37"] = "ct_oac_storage_01_77"
    },
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetal",
	soundOpen = "Open",
	soundClose = "Close"
}

local YellowWallLockerWest = {
    originalSprite = "furniture_storage_02_14",
	openSprite = "ct_oac_furniture_storage_02_14",
	openSprite2 = "ct_oac_furniture_storage_02_22",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetal",
	soundOpen = "Open",
	soundClose = "Close"
}

local YellowWallLockerNorth = {
    originalSprite = "furniture_storage_02_15",
	openSprite = "ct_oac_furniture_storage_02_15",
	openSprite2 = "ct_oac_furniture_storage_02_23",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetal",
	soundOpen = "Open",
	soundClose = "Close"
}
-- ------------------------------------------------------------------------------------------------
local LargeCardboardBoxOne = {
    originalSprite = "furniture_storage_02_16",
	openSprite = "ct_oac_furniture_storage_02_16",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/CardboardLarge",
	soundOpen = "Open",
	soundClose = "Close"
}

local LargeCardboardBoxTwo = {
    originalSprite = "furniture_storage_02_17",
	openSprite = "ct_oac_furniture_storage_02_17",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/CardboardLarge",
	soundOpen = "Open",
	soundClose = "Close"
}

local LargeCardboardBoxThree = {
    originalSprite = "furniture_storage_02_18",
	openSprite = "ct_oac_furniture_storage_02_18",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/CardboardLarge",
	soundOpen = "Open",
	soundClose = "Close"
}

local LargeCardboardBoxFour = {
    originalSprite = "furniture_storage_02_19",
	openSprite = "ct_oac_furniture_storage_02_19",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/CardboardLarge",
	soundOpen = "Open",
	soundClose = "Close"
}
-- ------------------------------------------------------------------------------------------------
--[[local LargeCardboardBoxAboveOne = {
    originalSprite = "furniture_storage_02_24",
	openSprite = "ct_oac_furniture_storage_02_24",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/CardboardLarge",
	soundOpen = "Open",
	soundClose = "Close"
}

local LargeCardboardBoxAboveTwo = {
    originalSprite = "furniture_storage_02_25",
	openSprite = "ct_oac_furniture_storage_02_25",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/CardboardLarge",
	soundOpen = "Open",
	soundClose = "Close"
}

local LargeCardboardBoxAboveThree = {
    originalSprite = "furniture_storage_02_26",
	openSprite = "ct_oac_furniture_storage_02_26",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/CardboardLarge",
	soundOpen = "Open",
	soundClose = "Close"
}

local LargeCardboardBoxAboveFour = {
    originalSprite = "furniture_storage_02_27",
	openSprite = "ct_oac_furniture_storage_02_27",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/CardboardLarge",
	soundOpen = "Open",
	soundClose = "Close"
}--]]
-- ------------------------------------------------------------------------------------------------
local SmallChestSouth = {
    originalSprite = "furniture_storage_02_28",
	openSprite = "ct_oac_furniture_storage_02_28",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/ChestMetal",
	soundOpen = "Open",
	soundClose = "Close"
}

local SmallChestEast = {
    originalSprite = "furniture_storage_02_29",
	openSprite = "ct_oac_furniture_storage_02_29",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/ChestMetal",
	soundOpen = "Open",
	soundClose = "Close"
}

local SmallChestNorth = {
    originalSprite = "furniture_storage_02_30",
	openSprite = "ct_oac_furniture_storage_02_30",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/ChestMetal",
	soundOpen = "Open",
	soundClose = "Close"
}

local SmallChestWest = {
    originalSprite = "furniture_storage_02_31",
	openSprite = "ct_oac_furniture_storage_02_31",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/ChestMetal",
	soundOpen = "Open",
	soundClose = "Close"
}
-- ------------------------------------------------------------------------------------------------
local ChinaCabinetLeftEast = {
    originalSprite = "furniture_storage_02_32",
	openSprite = "ct_oac_furniture_storage_02_32",
	openSprite2 = "ct_oac_furniture_storage_02_56",
	--openSprite3 = "ct_oac_furniture_storage_02_64",
	--openSprite4 = "ct_oac_furniture_storage_02_72",
	--openSprite5 = "ct_oac_furniture_storage_02_80",
	--openSprite6 = "ct_oac_furniture_storage_02_88",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local ChinaCabinetRightEast = {
    originalSprite = "furniture_storage_02_33",
	openSprite = "ct_oac_furniture_storage_02_33",
	openSprite2 = "ct_oac_furniture_storage_02_57",
	--openSprite3 = "ct_oac_furniture_storage_02_65",
	--openSprite4 = "ct_oac_furniture_storage_02_73",
	--openSprite5 = "ct_oac_furniture_storage_02_81",
	--openSprite6 = "ct_oac_furniture_storage_02_89",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local ChinaCabinetLeftSouth = {
    originalSprite = "furniture_storage_02_34",
	openSprite = "ct_oac_furniture_storage_02_34",
	openSprite2 = "ct_oac_furniture_storage_02_58",
	--openSprite3 = "ct_oac_furniture_storage_02_66",
	--openSprite4 = "ct_oac_furniture_storage_02_74",
	--openSprite5 = "ct_oac_furniture_storage_02_82",
	--openSprite6 = "ct_oac_furniture_storage_02_90",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local ChinaCabinetRightSouth = {
    originalSprite = "furniture_storage_02_35",
	openSprite = "ct_oac_furniture_storage_02_35",
	openSprite2 = "ct_oac_furniture_storage_02_59",
	--openSprite3 = "ct_oac_furniture_storage_02_67",
	--openSprite4 = "ct_oac_furniture_storage_02_75",
	--openSprite5 = "ct_oac_furniture_storage_02_83",
	--openSprite6 = "ct_oac_furniture_storage_02_91",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}

local ChinaCabinetLeftWest = {
    originalSprite = "furniture_storage_02_36",
	openSprite = "ct_oac_furniture_storage_02_36",
	openSprite2 = "ct_oac_furniture_storage_02_60",
	--openSprite3 = "ct_oac_furniture_storage_02_68",
	--openSprite4 = "ct_oac_furniture_storage_02_76",
	--openSprite5 = "ct_oac_furniture_storage_02_84",
	--openSprite6 = "ct_oac_furniture_storage_02_92",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local ChinaCabinetRightWest = {
    originalSprite = "furniture_storage_02_37",
	openSprite = "ct_oac_furniture_storage_02_37",
	openSprite2 = "ct_oac_furniture_storage_02_61",
	--openSprite3 = "ct_oac_furniture_storage_02_69",
	--openSprite4 = "ct_oac_furniture_storage_02_77",
	--openSprite5 = "ct_oac_furniture_storage_02_85",
	--openSprite6 = "ct_oac_furniture_storage_02_93",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local ChinaCabinetLeftNorth = {
    originalSprite = "furniture_storage_02_38",
	openSprite = "ct_oac_furniture_storage_02_38",
	openSprite2 = "ct_oac_furniture_storage_02_62",
	--openSprite3 = "ct_oac_furniture_storage_02_70",
	--openSprite4 = "ct_oac_furniture_storage_02_78",
	--openSprite5 = "ct_oac_furniture_storage_02_86",
	--openSprite6 = "ct_oac_furniture_storage_02_94",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local ChinaCabinetRightNorth = {
    originalSprite = "furniture_storage_02_39",
	openSprite = "ct_oac_furniture_storage_02_39",
	openSprite2 = "ct_oac_furniture_storage_02_63",
	--openSprite3 = "ct_oac_furniture_storage_02_71",
	--openSprite4 = "ct_oac_furniture_storage_02_79",
	--openSprite5 = "ct_oac_furniture_storage_02_87",
	--openSprite6 = "ct_oac_furniture_storage_02_95",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}
-- ------------------------------------------------------------------------------------------------
local RedMobileToolCabinetSouth = {
    originalSprite = "location_business_machinery_01_32",
	openSprite = "ct_oac_location_business_machinery_01_32",
	openSprite2 = "ct_oac_location_business_machinery_01_36",
	openSprite3 = "ct_oac_location_business_machinery_01_28"
}

local RedMobileToolCabinetEast = {
    originalSprite = "location_business_machinery_01_33",
	openSprite = "ct_oac_location_business_machinery_01_33",
	openSprite2 = "ct_oac_location_business_machinery_01_37",
	openSprite3 = "ct_oac_location_business_machinery_01_29"
}

local RedMobileToolCabinetNorth = {
    originalSprite = "location_business_machinery_01_34",
	openSprite = "ct_oac_location_business_machinery_01_34",
	openSprite2 = "ct_oac_location_business_machinery_01_38",
	openSprite3 = "ct_oac_location_business_machinery_01_30"
}

local RedMobileToolCabinetWest = {
    originalSprite = "location_business_machinery_01_35",
	openSprite = "ct_oac_location_business_machinery_01_35",
	openSprite2 = "ct_oac_location_business_machinery_01_39",
	openSprite3 = "ct_oac_location_business_machinery_01_31"
}
-- ------------------------------------------------------------------------------------------------
local OfficeDeskEast = {
    originalSprite = "location_business_office_generic_01_0",
	openSprite = "ct_oac_location_business_office_generic_01_0",
	openSprite2 = "ct_oac_location_business_office_generic_01_1",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close"
}

local OfficeDeskSouth = {
    originalSprite = "location_business_office_generic_01_5",
	openSprite = "ct_oac_location_business_office_generic_01_5",
	openSprite2 = "ct_oac_location_business_office_generic_01_6",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close"
}

local OfficeDeskNorth = {
    originalSprite = "location_business_office_generic_01_10",
	openSprite = "ct_oac_location_business_office_generic_01_10",
	openSprite2 = "ct_oac_location_business_office_generic_01_11",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close"
}

local OfficeDeskWest = {
    originalSprite = "location_business_office_generic_01_13",
	openSprite = "ct_oac_location_business_office_generic_01_13",
	openSprite2 = "ct_oac_location_business_office_generic_01_14",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close"
}
-- ------------------------------------------------------------------------------------------------
local GrayFileCabinetSouth = {
    originalSprite = "location_business_office_generic_01_16",
	openSprite = "ct_oac_location_business_office_generic_01_16",
	openSprite2 = "ct_oac_location_business_office_generic_01_18",
	openSprite3 = "ct_oac_location_business_office_generic_01_20",
    overlayOpenSprite = {
        ["office_01_0"] = "ct_oac_office_01_0",
		["office_01_1"] = "ct_oac_office_01_1"
    },
    overlayOpenSprite2 = {
		["office_01_0"] = "ct_oac_office_01_16",
        ["office_01_1"] = "ct_oac_office_01_17"
    },
    overlayOpenSprite3 = {
		["office_01_0"] = "ct_oac_office_01_32",
        ["office_01_1"] = "ct_oac_office_01_33"
    },
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerMetal",
	soundOpen = "Open",
	soundClose = "Close"
}

local GrayFileCabinetEast = {
    originalSprite = "location_business_office_generic_01_17",
	openSprite = "ct_oac_location_business_office_generic_01_17",
	openSprite2 = "ct_oac_location_business_office_generic_01_19",
	openSprite3 = "ct_oac_location_business_office_generic_01_21",
    overlayOpenSprite = {
        ["office_01_2"] = "ct_oac_office_01_2",
		["office_01_3"] = "ct_oac_office_01_3"
    },
    overlayOpenSprite2 = {
        ["office_01_2"] = "ct_oac_office_01_18",
		["office_01_3"] = "ct_oac_office_01_19"
    },
    overlayOpenSprite3 = {
        ["office_01_2"] = "ct_oac_office_01_34",
		["office_01_3"] = "ct_oac_office_01_35"
    },
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerMetal",
	soundOpen = "Open",
	soundClose = "Close"
}

local GrayFileCabinetNorth = {
    originalSprite = "location_business_office_generic_01_24",
	openSprite = "ct_oac_location_business_office_generic_01_24",
	openSprite2 = "ct_oac_location_business_office_generic_01_26",
	openSprite3 = "ct_oac_location_business_office_generic_01_28",
    overlayOpenSprite = {
        ["office_01_8"] = "ct_oac_office_01_8",
        ["office_01_9"] = "ct_oac_office_01_9"
    },
    overlayOpenSprite2 = {
        ["office_01_8"] = "ct_oac_office_01_24",
        ["office_01_9"] = "ct_oac_office_01_25"
    },
    overlayOpenSprite3 = {
        ["office_01_8"] = "ct_oac_office_01_40",
        ["office_01_9"] = "ct_oac_office_01_41"
    },
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerMetal",
	soundOpen = "Open",
	soundClose = "Close"
}

local GrayFileCabinetWest = {
    originalSprite = "location_business_office_generic_01_25",
	openSprite = "ct_oac_location_business_office_generic_01_25",
	openSprite2 = "ct_oac_location_business_office_generic_01_27",
	openSprite3 = "ct_oac_location_business_office_generic_01_29",
    overlayOpenSprite = {
        ["office_01_10"] = "ct_oac_office_01_10",
		["office_01_11"] = "ct_oac_office_01_11"
    },
    overlayOpenSprite2 = {
		["office_01_10"] = "ct_oac_office_01_26",
        ["office_01_11"] = "ct_oac_office_01_27"
    },
    overlayOpenSprite3 = {
		["office_01_10"] = "ct_oac_office_01_42",
        ["office_01_11"] = "ct_oac_office_01_43"
    },
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerMetal",
	soundOpen = "Open",
	soundClose = "Close"
}
-- ------------------------------------------------------------------------------------------------
local WhiteFileCabinetSouth = {
    originalSprite = "location_business_office_generic_01_32",
	openSprite = "ct_oac_location_business_office_generic_01_32",
	openSprite2 = "ct_oac_location_business_office_generic_01_36",
	openSprite3 = "ct_oac_location_business_office_generic_01_48",
    overlayOpenSprite = {
        ["office_01_4"] = "ct_oac_office_01_4",
		["office_01_5"] = "ct_oac_office_01_5"
    },
    overlayOpenSprite2 = {
        ["office_01_4"] = "ct_oac_office_01_20",
        ["office_01_5"] = "ct_oac_office_01_21"
    },
    overlayOpenSprite3 = {
        ["office_01_4"] = "ct_oac_office_01_36",
        ["office_01_5"] = "ct_oac_office_01_37"
    },
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerMetal",
	soundOpen = "Open",
	soundClose = "Close"
}

local WhiteFileCabinetEast = {
    originalSprite = "location_business_office_generic_01_33",
	openSprite = "ct_oac_location_business_office_generic_01_33",
	openSprite2 = "ct_oac_location_business_office_generic_01_37",
	openSprite3 = "ct_oac_location_business_office_generic_01_49",
    overlayOpenSprite = {
        ["office_01_6"] = "ct_oac_office_01_6",
        ["office_01_7"] = "ct_oac_office_01_7"
    },
    overlayOpenSprite2 = {
        ["office_01_6"] = "ct_oac_office_01_22",
        ["office_01_7"] = "ct_oac_office_01_23"
    },
    overlayOpenSprite3 = {
        ["office_01_6"] = "ct_oac_office_01_38",
        ["office_01_7"] = "ct_oac_office_01_39"
    },
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerMetal",
	soundOpen = "Open",
	soundClose = "Close"
}

local WhiteFileCabinetNorth = {
    originalSprite = "location_business_office_generic_01_34",
	openSprite = "ct_oac_location_business_office_generic_01_34",
	openSprite2 = "ct_oac_location_business_office_generic_01_38",
	openSprite3 = "ct_oac_location_business_office_generic_01_50",
    overlayOpenSprite = {
        ["office_01_12"] = "ct_oac_office_01_12",
        ["office_01_13"] = "ct_oac_office_01_13"
    },
    overlayOpenSprite2 = {
        ["office_01_12"] = "ct_oac_office_01_28",
        ["office_01_13"] = "ct_oac_office_01_29"
    },
    overlayOpenSprite3 = {
        ["office_01_12"] = "ct_oac_office_01_44",
        ["office_01_13"] = "ct_oac_office_01_45"
    },
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerMetal",
	soundOpen = "Open",
	soundClose = "Close"
}

local WhiteFileCabinetWest = {
    originalSprite = "location_business_office_generic_01_35",
	openSprite = "ct_oac_location_business_office_generic_01_35",
	openSprite2 = "ct_oac_location_business_office_generic_01_39",
	openSprite3 = "ct_oac_location_business_office_generic_01_51",
    overlayOpenSprite = {
		["office_01_14"] = "ct_oac_office_01_14",
        ["office_01_15"] = "ct_oac_office_01_15"
    },
    overlayOpenSprite2 = {
		["office_01_14"] = "ct_oac_office_01_30",
        ["office_01_15"] = "ct_oac_office_01_31"
    },
    overlayOpenSprite3 = {
        ["office_01_14"] = "ct_oac_office_01_46",
        ["office_01_15"] = "ct_oac_office_01_47"
    },
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerMetal",
	soundOpen = "Open",
	soundClose = "Close"
}
-- ------------------------------------------------------------------------------------------------
local DarkOfficeDeskLeftEast = {
    originalSprite = "location_business_office_generic_01_40",
	openSprite = "ct_oac_location_business_office_generic_01_40",
	openSprite2 = "ct_oac_location_business_office_generic_01_41",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local DarkOfficeDeskRightEast = {
    originalSprite = "location_business_office_generic_01_41",
	openSprite = "ct_oac_location_business_office_generic_01_56",
	openSprite2 = "ct_oac_location_business_office_generic_01_57",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local DarkOfficeDeskLeftSouth = {
    originalSprite = "location_business_office_generic_01_42",
	openSprite = "ct_oac_location_business_office_generic_01_42",
	openSprite2 = "ct_oac_location_business_office_generic_01_43",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local DarkOfficeDeskRightSouth = {
    originalSprite = "location_business_office_generic_01_43",
	openSprite = "ct_oac_location_business_office_generic_01_58",
	openSprite2 = "ct_oac_location_business_office_generic_01_59",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}

local DarkOfficeDeskLeftNorth = {
    originalSprite = "location_business_office_generic_01_44",
	openSprite = "ct_oac_location_business_office_generic_01_60",
	openSprite2 = "ct_oac_location_business_office_generic_01_61",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local DarkOfficeDeskRightNorth = {
    originalSprite = "location_business_office_generic_01_45",
	openSprite = "ct_oac_location_business_office_generic_01_45",
	openSprite2 = "ct_oac_location_business_office_generic_01_46",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}

local DarkOfficeDeskLeftWest = {
    originalSprite = "location_business_office_generic_01_46",
	openSprite = "ct_oac_location_business_office_generic_01_62",
	openSprite2 = "ct_oac_location_business_office_generic_01_63",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local DarkOfficeDeskRightWest = {
    originalSprite = "location_business_office_generic_01_47",
	openSprite = "ct_oac_location_business_office_generic_01_47",
	openSprite2 = "ct_oac_location_business_office_generic_01_55",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}
-- ------------------------------------------------------------------------------------------------
local MedicalToolDrawersEast = {
    originalSprite = "location_community_medical_01_36",
	openSprite = "ct_oac_location_community_medical_01_36",
	openSprite2 = "ct_oac_location_community_medical_01_40",
	openSprite3 = "ct_oac_location_community_medical_01_44",
    overlayOpenSprite = {
		["storage_01_64"] = "ct_oac_storage_01_136",
        ["storage_01_68"] = "ct_oac_storage_01_140"
    },
    overlayOpenSprite2 = {
        ["storage_01_64"] = "ct_oac_storage_01_144",
		["storage_01_68"] = "ct_oac_storage_01_148"
    },
    overlayOpenSprite3 = {
        ["storage_01_64"] = "ct_oac_storage_01_152",
		["storage_01_68"] = "ct_oac_storage_01_156"
    },
	--hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close"
}

local MedicalToolDrawersSouth = {
    originalSprite = "location_community_medical_01_37",
	openSprite = "ct_oac_location_community_medical_01_37",
	openSprite2 = "ct_oac_location_community_medical_01_41",
	openSprite3 = "ct_oac_location_community_medical_01_45",
    overlayOpenSprite = {
        ["storage_01_65"] = "ct_oac_storage_01_137",
        ["storage_01_69"] = "ct_oac_storage_01_141"
    },
    overlayOpenSprite2 = {
		["storage_01_65"] = "ct_oac_storage_01_145",
        ["storage_01_69"] = "ct_oac_storage_01_149"
    },
    overlayOpenSprite3 = {
		["storage_01_65"] = "ct_oac_storage_01_153",
        ["storage_01_69"] = "ct_oac_storage_01_157"
    },
	--hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close"
}

local MedicalToolDrawersWest = {
    originalSprite = "location_community_medical_01_38",
	openSprite = "ct_oac_location_community_medical_01_38",
	openSprite2 = "ct_oac_location_community_medical_01_42",
	openSprite3 = "ct_oac_location_community_medical_01_46",
    overlayOpenSprite = {
        ["storage_01_66"] = "ct_oac_storage_01_138",
        ["storage_01_70"] = "ct_oac_storage_01_142"
    },
    overlayOpenSprite2 = {
		["storage_01_66"] = "ct_oac_storage_01_146",
        ["storage_01_70"] = "ct_oac_storage_01_150"
    },
    overlayOpenSprite3 = {
		["storage_01_66"] = "ct_oac_storage_01_154",
        ["storage_01_70"] = "ct_oac_storage_01_158"
    },
	--hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close"
}

local MedicalToolDrawersNorth = {
    originalSprite = "location_community_medical_01_39",
	openSprite = "ct_oac_location_community_medical_01_39",
	openSprite2 = "ct_oac_location_community_medical_01_43",
	openSprite3 = "ct_oac_location_community_medical_01_47",
    overlayOpenSprite = {
        ["storage_01_67"] = "ct_oac_storage_01_139",
        ["storage_01_71"] = "ct_oac_storage_01_143"
    },
    overlayOpenSprite2 = {
		["storage_01_67"] = "ct_oac_storage_01_147",
        ["storage_01_71"] = "ct_oac_storage_01_151"
    },
    overlayOpenSprite3 = {
		["storage_01_67"] = "ct_oac_storage_01_155",
        ["storage_01_71"] = "ct_oac_storage_01_159"
    },
	--hasVanillaSound = true,
	soundBase = "Object/LargeContainers/DrawerWood",
	soundOpen = "Open",
	soundClose = "Close"
}
-- ------------------------------------------------------------------------------------------------
local FirstAidSouth = {
    originalSprite = "location_community_medical_01_88",
	openSprite = "ct_oac_location_community_medical_01_88"
}

local FirstAidEast = {
    originalSprite = "location_community_medical_01_89",
	openSprite = "ct_oac_location_community_medical_01_89"
}

local FirstAidNorth = {
    originalSprite = "location_community_medical_01_90",
	openSprite = "ct_oac_location_community_medical_01_90"
}

local FirstAidWest = {
    originalSprite = "location_community_medical_01_91",
	openSprite = "ct_oac_location_community_medical_01_91"
}
-- ------------------------------------------------------------------------------------------------
local MedicalDeskEast = {
    originalSprite = "location_community_medical_01_106",
	openSprite = "ct_oac_location_community_medical_01_106"
}

local MedicalDeskSouth = {
    originalSprite = "location_community_medical_01_107",
	openSprite = "ct_oac_location_community_medical_01_107"
}
-- ------------------------------------------------------------------------------------------------
local MedicalCabinetWideLeftEast = {
    originalSprite = "location_community_medical_01_152",
	openSprite = "ct_oac_location_community_medical_01_152"
}

local MedicalCabinetWideRightEast = {
    originalSprite = "location_community_medical_01_153",
	openSprite = "ct_oac_location_community_medical_01_153"
}

local MedicalCabinetWideLeftSouth = {
    originalSprite = "location_community_medical_01_154",
	openSprite = "ct_oac_location_community_medical_01_154"
}

local MedicalCabinetWideRightSouth = {
    originalSprite = "location_community_medical_01_155",
	openSprite = "ct_oac_location_community_medical_01_155"
}
-- ------------------------------------------------------------------------------------------------
local MilitaryLockerSouth = {
    originalSprite = "location_military_generic_01_22",
	openSprite = "ct_oac_location_military_generic_01_22",
	openSprite2 = "ct_oac_location_military_generic_01_20",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetalLarge",
	soundOpen = "Open",
	soundClose = "Close"
}

local MilitaryLockerEast = {
    originalSprite = "location_military_generic_01_23",
	openSprite = "ct_oac_location_military_generic_01_23",
	openSprite2 = "ct_oac_location_military_generic_01_21",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetalLarge",
	soundOpen = "Open",
	soundClose = "Close"
}

local MilitaryLockerNorth = {
    originalSprite = "location_military_generic_01_30",
	openSprite = "ct_oac_location_military_generic_01_30",
	openSprite2 = "ct_oac_location_military_generic_01_28",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetalLarge",
	soundOpen = "Open",
	soundClose = "Close"
}

local MilitaryLockerWest = {
    originalSprite = "location_military_generic_01_31",
	openSprite = "ct_oac_location_military_generic_01_31",
	openSprite2 = "ct_oac_location_military_generic_01_29",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/LockerMetalLarge",
	soundOpen = "Open",
	soundClose = "Close"
}
-- ------------------------------------------------------------------------------------------------
local CashRegisterEast = {
    originalSprite = "location_shop_accessories_01_0",
	openSprite = "ct_oac_location_shop_accessories_01_0"
}

local CashRegisterSouth = {
    originalSprite = "location_shop_accessories_01_1",
	openSprite = "ct_oac_location_shop_accessories_01_1"
}

local CashRegisterNorth = {
    originalSprite = "location_shop_accessories_01_2",
	openSprite = "ct_oac_location_shop_accessories_01_2"
}

local CashRegisterWest = {
    originalSprite = "location_shop_accessories_01_3",
	openSprite = "ct_oac_location_shop_accessories_01_3"
}
-- ------------------------------------------------------------------------------------------------
local BlackCashRegisterEast = {
    originalSprite = "location_shop_accessories_01_20",
	openSprite = "ct_oac_location_shop_accessories_01_20"
}

local BlackCashRegisterSouth = {
    originalSprite = "location_shop_accessories_01_21",
	openSprite = "ct_oac_location_shop_accessories_01_21"
}

local BlackCashRegisterNorth = {
    originalSprite = "location_shop_accessories_01_22",
	openSprite = "ct_oac_location_shop_accessories_01_22"
}

local BlackCashRegisterWest = {
    originalSprite = "location_shop_accessories_01_23",
	openSprite = "ct_oac_location_shop_accessories_01_23"
}
-- ------------------------------------------------------------------------------------------------
--LargeMachine
-- ------------------------------------------------------------------------------------------------
--SmallSodaMachine
-- ------------------------------------------------------------------------------------------------
local PublicMailBoxSouth = {
    originalSprite = "street_decoration_01_8",
	openSprite = "ct_oac_street_decoration_01_8"
}

local PublicMailBoxEast = {
    originalSprite = "street_decoration_01_9",
	openSprite = "ct_oac_street_decoration_01_9"
}

local PublicMailBoxNorth = {
    originalSprite = "street_decoration_01_10",
	openSprite = "ct_oac_street_decoration_01_10"
}

local PublicMailBoxWest = {
    originalSprite = "street_decoration_01_11",
	openSprite = "ct_oac_street_decoration_01_11"
}
-- ------------------------------------------------------------------------------------------------
local MailBoxEast = {
    originalSprite = "street_decoration_01_18",
	openSprite = "ct_oac_street_decoration_01_18",
	openSprite4PostFlag = "ct_oac_street_decoration_01_24"
}

local MailBoxSouth = {
    originalSprite = "street_decoration_01_19",
	openSprite = "ct_oac_street_decoration_01_19",
	openSprite4PostFlag = "ct_oac_street_decoration_01_25"
}

local MailBoxWest = {
    originalSprite = "street_decoration_01_20",
	openSprite = "ct_oac_street_decoration_01_20",
	openSprite4PostFlag = "ct_oac_street_decoration_01_26"
}

local MailBoxNorth = {
    originalSprite = "street_decoration_01_21",
	openSprite = "ct_oac_street_decoration_01_21",
	openSprite4PostFlag = "ct_oac_street_decoration_01_27"
}
-- ------------------------------------------------------------------------------------------------
--[[local NewspaperKnewsEast = {
    originalSprite = "street_decoration_01_80",
	openSprite = "ct_oac_street_decoration_01_80",
	autoClosed = true
}

local NewspaperKnewsSouth = {
    originalSprite = "street_decoration_01_81",
	openSprite = "ct_oac_street_decoration_01_81",
	autoClosed = true
}

local NewspaperKnewsWest = {
    originalSprite = "street_decoration_01_82",
	openSprite = "ct_oac_street_decoration_01_82",
	autoClosed = true
}

local NewspaperKnewsNorth = {
    originalSprite = "street_decoration_01_83",
	openSprite = "ct_oac_street_decoration_01_83",
	autoClosed = true
}
-- ------------------------------------------------------------------------------------------------
local NewspaperDispatchEast = {
    originalSprite = "street_decoration_01_84",
	openSprite = "ct_oac_street_decoration_01_84",
	autoClosed = true
}

local NewspaperDispatchSouth = {
    originalSprite = "street_decoration_01_85",
	openSprite = "ct_oac_street_decoration_01_85",
	autoClosed = true
}

local NewspaperDispatchNorth = {
    originalSprite = "street_decoration_01_86",
	openSprite = "ct_oac_street_decoration_01_86",
	autoClosed = true
}

local NewspaperDispatchWest = {
    originalSprite = "street_decoration_01_87",
	openSprite = "ct_oac_street_decoration_01_87",
	autoClosed = true
}
-- ------------------------------------------------------------------------------------------------
local NewspaperHeraldEast = {
    originalSprite = "street_decoration_01_88",
	openSprite = "ct_oac_street_decoration_01_88",
	autoClosed = true
}

local NewspaperHeraldSouth = {
    originalSprite = "street_decoration_01_89",
	openSprite = "ct_oac_street_decoration_01_89",
	autoClosed = true
}

local NewspaperHeraldWest = {
    originalSprite = "street_decoration_01_90",
	openSprite = "ct_oac_street_decoration_01_90",
	autoClosed = true
}

local NewspaperHeraldNorth = {
    originalSprite = "street_decoration_01_91",
	openSprite = "ct_oac_street_decoration_01_91",
	autoClosed = true
}
-- ------------------------------------------------------------------------------------------------
local NewspaperTimesEast = {
    originalSprite = "street_decoration_01_92",
	openSprite = "ct_oac_street_decoration_01_92",
	autoClosed = true
}

local NewspaperTimesSouth = {
    originalSprite = "street_decoration_01_93",
	openSprite = "ct_oac_street_decoration_01_93",
	autoClosed = true
}

local NewspaperTimesNorth = {
    originalSprite = "street_decoration_01_94",
	openSprite = "ct_oac_street_decoration_01_94",
	autoClosed = true
}

local NewspaperTimesWest = {
    originalSprite = "street_decoration_01_95",
	openSprite = "ct_oac_street_decoration_01_95",
	autoClosed = true
}--]]
-- ------------------------------------------------------------------------------------------------
local BlueDumpsterLeftEast = {
    originalSprite = "trashcontainers_01_8",
	openSprite = "ct_oac_trashcontainers_01_8"
}

local BlueDumpsterRightEast = {
    originalSprite = "trashcontainers_01_9",
	openSprite = "ct_oac_trashcontainers_01_9"
}

local BlueDumpsterLeftSouth = {
    originalSprite = "trashcontainers_01_10",
	openSprite = "ct_oac_trashcontainers_01_10"
}

local BlueDumpsterRightSouth = {
    originalSprite = "trashcontainers_01_11",
	openSprite = "ct_oac_trashcontainers_01_11"
}
-- ------------------------------------------------------------------------------------------------
local OrangeDumpsterLeftEast = {
    originalSprite = "trashcontainers_01_12",
	openSprite = "ct_oac_trashcontainers_01_12",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local OrangeDumpsterRightEast = {
    originalSprite = "trashcontainers_01_13",
	openSprite = "ct_oac_trashcontainers_01_13",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local OrangeDumpsterLeftSouth = {
    originalSprite = "trashcontainers_01_14",
	openSprite = "ct_oac_trashcontainers_01_14",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local OrangeDumpsterRightSouth = {
    originalSprite = "trashcontainers_01_15",
	openSprite = "ct_oac_trashcontainers_01_15",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}
-- ------------------------------------------------------------------------------------------------
local CardboardBoxSouth = {
    originalSprite = "trashcontainers_01_24",
	openSprite = "ct_oac_trashcontainers_01_24",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/Cardboard",
	soundOpen = "Open",
	soundClose = "Close"
}

local CardboardBoxEast = {
    originalSprite = "trashcontainers_01_25",
	openSprite = "ct_oac_trashcontainers_01_25",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/Cardboard",
	soundOpen = "Open",
	soundClose = "Close"
}
-- ------------------------------------------------------------------------------------------------
local BatteredCardboardBoxSouth = {
    originalSprite = "trashcontainers_01_26",
	openSprite = "ct_oac_trashcontainers_01_26",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/Cardboard",
	soundOpen = "Open",
	soundClose = "Close"
}

local BatteredCardboardBoxEast = {
    originalSprite = "trashcontainers_01_27",
	openSprite = "ct_oac_trashcontainers_01_27",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/Cardboard",
	soundOpen = "Open",
	soundClose = "Close"
}

-- ------------------------------------------------------------------------------------------------

-- **************** OPEN ALL CONTAINERS - SPRITE DATA - WARDROBES CONTAINERS ****************

local FancyWhiteWardrobeLeftEast = {
    originalSprite = "furniture_storage_01_0",
	openSprite = "ct_oac_furniture_storage_01_0",
	openSprite2 = "ct_oac_furniture_storage_01_8",
	openSprite3 = "ct_oac_furniture_storage_01_16",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local FancyWhiteWardrobeRightEast = {
    originalSprite = "furniture_storage_01_1",
	openSprite = "ct_oac_furniture_storage_01_1",
	openSprite2 = "ct_oac_furniture_storage_01_9",
	openSprite3 = "ct_oac_furniture_storage_01_17",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local FancyWhiteWardrobeLeftSouth = {
    originalSprite = "furniture_storage_01_2",
	openSprite = "ct_oac_furniture_storage_01_2",
	openSprite2 = "ct_oac_furniture_storage_01_10",
	openSprite3 = "ct_oac_furniture_storage_01_18",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local FancyWhiteWardrobeRightSouth = {
    originalSprite = "furniture_storage_01_3",
	openSprite = "ct_oac_furniture_storage_01_3",
	openSprite2 = "ct_oac_furniture_storage_01_11",
	openSprite3 = "ct_oac_furniture_storage_01_19",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}

local FancyWhiteWardrobeLeftWest = {
    originalSprite = "furniture_storage_01_4",
	openSprite = "ct_oac_furniture_storage_01_4",
	openSprite2 = "ct_oac_furniture_storage_01_12",
	openSprite3 = "ct_oac_furniture_storage_01_20",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local FancyWhiteWardrobeRightWest = {
    originalSprite = "furniture_storage_01_5",
	openSprite = "ct_oac_furniture_storage_01_5",
	openSprite2 = "ct_oac_furniture_storage_01_13",
	openSprite3 = "ct_oac_furniture_storage_01_21",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local FancyWhiteWardrobeLeftNorth = {
    originalSprite = "furniture_storage_01_6",
	openSprite = "ct_oac_furniture_storage_01_6",
	openSprite2 = "ct_oac_furniture_storage_01_14",
	openSprite3 = "ct_oac_furniture_storage_01_22",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local FancyWhiteWardrobeRightNorth = {
    originalSprite = "furniture_storage_01_7",
	openSprite = "ct_oac_furniture_storage_01_7",
	openSprite2 = "ct_oac_furniture_storage_01_15",
	openSprite3 = "ct_oac_furniture_storage_01_23",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}
-- ------------------------------------------------------------------------------------------------
local FancyOakWardrobeLeftEast = {
    originalSprite = "furniture_storage_01_16",
	openSprite = "ct_oac_furniture_storage_01_48",
	openSprite2 = "ct_oac_furniture_storage_01_56",
	openSprite3 = "ct_oac_furniture_storage_01_64",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local FancyOakWardrobeRightEast = {
    originalSprite = "furniture_storage_01_17",
	openSprite = "ct_oac_furniture_storage_01_49",
	openSprite2 = "ct_oac_furniture_storage_01_57",
	openSprite3 = "ct_oac_furniture_storage_01_65",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local FancyOakWardrobeLeftSouth = {
    originalSprite = "furniture_storage_01_18",
	openSprite = "ct_oac_furniture_storage_01_50",
	openSprite2 = "ct_oac_furniture_storage_01_58",
	openSprite3 = "ct_oac_furniture_storage_01_66",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local FancyOakWardrobeRightSouth = {
    originalSprite = "furniture_storage_01_19",
	openSprite = "ct_oac_furniture_storage_01_51",
	openSprite2 = "ct_oac_furniture_storage_01_59",
	openSprite3 = "ct_oac_furniture_storage_01_67",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}

local FancyOakWardrobeLeftWest = {
    originalSprite = "furniture_storage_01_20",
	openSprite = "ct_oac_furniture_storage_01_52",
	openSprite2 = "ct_oac_furniture_storage_01_60",
	openSprite3 = "ct_oac_furniture_storage_01_68",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local FancyOakWardrobeRightWest = {
    originalSprite = "furniture_storage_01_21",
	openSprite = "ct_oac_furniture_storage_01_53",
	openSprite2 = "ct_oac_furniture_storage_01_61",
	openSprite3 = "ct_oac_furniture_storage_01_69",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local FancyOakWardrobeLeftNorth = {
    originalSprite = "furniture_storage_01_22",
	openSprite = "ct_oac_furniture_storage_01_54",
	openSprite2 = "ct_oac_furniture_storage_01_62",
	openSprite3 = "ct_oac_furniture_storage_01_70",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local FancyOakWardrobeRightNorth = {
    originalSprite = "furniture_storage_01_23",
	openSprite = "ct_oac_furniture_storage_01_55",
	openSprite2 = "ct_oac_furniture_storage_01_63",
	openSprite3 = "ct_oac_furniture_storage_01_71",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}
-- ------------------------------------------------------------------------------------------------
local DarkFancyWardrobeLeftEast = {
    originalSprite = "furniture_storage_01_24",
	openSprite = "ct_oac_furniture_storage_01_72",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local DarkFancyWardrobeRightEast = {
    originalSprite = "furniture_storage_01_25",
	openSprite = "ct_oac_furniture_storage_01_73",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local DarkFancyWardrobeLeftSouth = {
    originalSprite = "furniture_storage_01_26",
	openSprite = "ct_oac_furniture_storage_01_74",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local DarkFancyWardrobeRightSouth = {
    originalSprite = "furniture_storage_01_27",
	openSprite = "ct_oac_furniture_storage_01_75",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}

local DarkFancyWardrobeLeftWest = {
    originalSprite = "furniture_storage_01_28",
	openSprite = "ct_oac_furniture_storage_01_76",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local DarkFancyWardrobeRightWest = {
    originalSprite = "furniture_storage_01_29",
	openSprite = "ct_oac_furniture_storage_01_77",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local DarkFancyWardrobeLeftNorth = {
    originalSprite = "furniture_storage_01_30",
	openSprite = "ct_oac_furniture_storage_01_78",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local DarkFancyWardrobeRightNorth = {
    originalSprite = "furniture_storage_01_31",
	openSprite = "ct_oac_furniture_storage_01_79",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}
-- ------------------------------------------------------------------------------------------------
local LargeWardrobeLeftEast = {
    originalSprite = "furniture_storage_01_36",
	openSprite = "ct_oac_furniture_storage_01_88",
	openSprite2 = "ct_oac_furniture_storage_01_96",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local LargeWardrobeRightEast = {
    originalSprite = "furniture_storage_01_37",
	openSprite = "ct_oac_furniture_storage_01_89",
	openSprite2 = "ct_oac_furniture_storage_01_97",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local LargeWardrobeLeftSouth = {
    originalSprite = "furniture_storage_01_38",
	openSprite = "ct_oac_furniture_storage_01_90",
	openSprite2 = "ct_oac_furniture_storage_01_98",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local LargeWardrobeRightSouth = {
    originalSprite = "furniture_storage_01_39",
	openSprite = "ct_oac_furniture_storage_01_91",
	openSprite2 = "ct_oac_furniture_storage_01_99",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}

local LargeWardrobeLeftWest = {
    originalSprite = "furniture_storage_02_20",
	openSprite = "ct_oac_furniture_storage_01_92",
	openSprite2 = "ct_oac_furniture_storage_01_100",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local LargeWardrobeRightWest = {
    originalSprite = "furniture_storage_02_21",
	openSprite = "ct_oac_furniture_storage_01_93",
	openSprite2 = "ct_oac_furniture_storage_01_101",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local LargeWardrobeLeftNorth = {
    originalSprite = "furniture_storage_02_22",
	openSprite = "ct_oac_furniture_storage_01_94",
	openSprite2 = "ct_oac_furniture_storage_01_102",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local LargeWardrobeRightNorth = {
    originalSprite = "furniture_storage_02_23",
	openSprite = "ct_oac_furniture_storage_01_95",
	openSprite2 = "ct_oac_furniture_storage_01_103",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}
-- ------------------------------------------------------------------------------------------------
local LightWoodWardrobeLeftEast = {
    originalSprite = "furniture_storage_01_56",
	openSprite = "ct_oac_furniture_storage_01_136",
	openSprite2 = "ct_oac_furniture_storage_01_144",
	openSprite3 = "ct_oac_furniture_storage_01_152",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local LightWoodWardrobeRightEast = {
    originalSprite = "furniture_storage_01_57",
	openSprite = "ct_oac_furniture_storage_01_137",
	openSprite2 = "ct_oac_furniture_storage_01_145",
	openSprite3 = "ct_oac_furniture_storage_01_153",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local LightWoodWardrobeLeftSouth = {
    originalSprite = "furniture_storage_01_58",
	openSprite = "ct_oac_furniture_storage_01_138",
	openSprite2 = "ct_oac_furniture_storage_01_146",
	openSprite3 = "ct_oac_furniture_storage_01_154",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local LightWoodWardrobeRightSouth = {
    originalSprite = "furniture_storage_01_59",
	openSprite = "ct_oac_furniture_storage_01_139",
	openSprite2 = "ct_oac_furniture_storage_01_147",
	openSprite3 = "ct_oac_furniture_storage_01_155",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}

local LightWoodWardrobeLeftWest = {
    originalSprite = "furniture_storage_01_60",
	openSprite = "ct_oac_furniture_storage_01_140",
	openSprite2 = "ct_oac_furniture_storage_01_148",
	openSprite3 = "ct_oac_furniture_storage_01_156",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local LightWoodWardrobeRightWest = {
    originalSprite = "furniture_storage_01_61",
	openSprite = "ct_oac_furniture_storage_01_141",
	openSprite2 = "ct_oac_furniture_storage_01_149",
	openSprite3 = "ct_oac_furniture_storage_01_157",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local LightWoodWardrobeLeftNorth = {
    originalSprite = "furniture_storage_01_62",
	openSprite = "ct_oac_furniture_storage_01_142",
	openSprite2 = "ct_oac_furniture_storage_01_150",
	openSprite3 = "ct_oac_furniture_storage_01_158",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local LightWoodWardrobeRightNorth = {
    originalSprite = "furniture_storage_01_63",
	openSprite = "ct_oac_furniture_storage_01_143",
	openSprite2 = "ct_oac_furniture_storage_01_151",
	openSprite3 = "ct_oac_furniture_storage_01_159",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}
-- ------------------------------------------------------------------------------------------------
local BeigeWardrobeLeftEast = {
    originalSprite = "furniture_storage_02_40",
	openSprite = "ct_oac_furniture_storage_02_40",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local BeigeWardrobeRightEast = {
    originalSprite = "furniture_storage_02_41",
	openSprite = "ct_oac_furniture_storage_02_41",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local BeigeWardrobeLeftSouth = {
    originalSprite = "furniture_storage_02_42",
	openSprite = "ct_oac_furniture_storage_02_42",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local BeigeWardrobeRightSouth = {
    originalSprite = "furniture_storage_02_43",
	openSprite = "ct_oac_furniture_storage_02_43",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}

local BeigeWardrobeLeftWest = {
    originalSprite = "furniture_storage_02_44",
	openSprite = "ct_oac_furniture_storage_02_44",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = -1}
}

local BeigeWardrobeRightWest = {
    originalSprite = "furniture_storage_02_45",
	openSprite = "ct_oac_furniture_storage_02_45",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 0, y = 1}
}

local BeigeWardrobeLeftNorth = {
    originalSprite = "furniture_storage_02_46",
	openSprite = "ct_oac_furniture_storage_02_46",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = 1, y = 0}
}

local BeigeWardrobeRightNorth = {
    originalSprite = "furniture_storage_02_47",
	openSprite = "ct_oac_furniture_storage_02_47",
	hasVanillaSound = true,
	soundBase = "Object/LargeContainers/WardrobeWoodLarge",
	soundOpen = "Open",
	soundClose = "Close",
	isPaired = true,
	pairedOffset = {x = -1, y = 0}
}

-- ------------------------------------------------------------------------------------------------

-- **************** OPEN ALL CONTAINERS - SPRITE DATA ****************

--local CookingAppliances = {
	--[[GreenOvenEast = GreenOvenEast,
    GreenOvenSouth = GreenOvenSouth,
    GreenOvenWest = GreenOvenWest,
    GreenOvenNorth = GreenOvenNorth,
	GrayOvenEast = GrayOvenEast,
    GrayOvenSouth = GrayOvenSouth,
    GrayOvenWest = GrayOvenWest,
    GrayOvenNorth = GrayOvenNorth,
	RedOvenEast = RedOvenEast,
    RedOvenSouth = RedOvenSouth,
    RedOvenWest = RedOvenWest,
    RedOvenNorth = RedOvenNorth,
	ModernOvenEast = ModernOvenEast,
    ModernOvenSouth = ModernOvenSouth,
    ModernOvenWest = ModernOvenWest,
    ModernOvenNorth = ModernOvenNorth,
	OldStoveEast = OldStoveEast,
    OldStoveSouth = OldStoveSouth,
    OldStoveNorth = OldStoveNorth,
    OldStoveWest = OldStoveWest,
	IndustrialOvenEast = IndustrialOvenEast,
    IndustrialOvenSouth = IndustrialOvenSouth,
    IndustrialOvenWest = IndustrialOvenWest,
    IndustrialOvenNorth = IndustrialOvenNorth,
	WhiteMicrowaveEast = WhiteMicrowaveEast,
    WhiteMicrowaveSouth = WhiteMicrowaveSouth,
    WhiteMicrowaveWest = WhiteMicrowaveWest,
    WhiteMicrowaveNorth = WhiteMicrowaveNorth,
    ChromeMicrowaveSouth = ChromeMicrowaveSouth,
	ChromeMicrowaveEast = ChromeMicrowaveEast,
    ChromeMicrowaveWest = ChromeMicrowaveWest,
    ChromeMicrowaveNorth = ChromeMicrowaveNorth,--]]
    --[[Barbecue = Barbecue,
	JorgeForeguyBarbecueSouth = JorgeForeguyBarbecueSouth,
    JorgeForeguyBarbecueEast = JorgeForeguyBarbecueEast,
    JorgeForeguyBarbecueNorth = JorgeForeguyBarbecueNorth,
    JorgeForeguyBarbecueWest = JorgeForeguyBarbecueWest,
    EmptyJorgeForeguyBarbecueSouth = EmptyJorgeForeguyBarbecueSouth,
    EmptyJorgeForeguyBarbecueEast = EmptyJorgeForeguyBarbecueEast,
    EmptyJorgeForeguyBarbecueNorth = EmptyJorgeForeguyBarbecueNorth,
    EmptyJorgeForeguyBarbecueWest = EmptyJorgeForeguyBarbecueWest,--]]
	--[[LargeModernOvenLeftEast = LargeModernOvenLeftEast,
	LargeModernOvenRightEast = LargeModernOvenRightEast,
	LargeModernOvenLeftSouth = LargeModernOvenLeftSouth,
	LargeModernOvenRightSouth = LargeModernOvenRightSouth,
	LargeModernOvenLeftWest = LargeModernOvenLeftWest,
	LargeModernOvenRightWest = LargeModernOvenRightWest,
	LargeModernOvenLeftNorth = LargeModernOvenLeftNorth,
	LargeModernOvenRightNorth = LargeModernOvenRightNorth,--]]
	--[[CraftedStoveNorth = CraftedStoveNorth,
	CraftedStoveWest = CraftedStoveWest,
	CraftedStoveEast = CraftedStoveEast,
	CraftedStoveSouth = CraftedStoveSouth--]]
--}

--[[local FridgesAppliances = {
	WhiteFridgeSouth = WhiteFridgeSouth,
	WhiteFridgeEast = WhiteFridgeEast,
    WhiteFridgeNorth = WhiteFridgeNorth,
    WhiteFridgeWest = WhiteFridgeWest
}--]]

local WashingMachinesAppliances = {
	BlueComboWasherDryerSouth = BlueComboWasherDryerSouth,
	BlueComboWasherDryerEast = BlueComboWasherDryerEast,
    BlueComboWasherDryerNorth = BlueComboWasherDryerNorth,
    BlueComboWasherDryerWest = BlueComboWasherDryerWest,
	WashingMachineSouth = WashingMachineSouth,
	WashingMachineEast = WashingMachineEast,
    WashingMachineNorth = WashingMachineNorth,
    WashingMachineWest = WashingMachineWest,
	ClothesDryerSouth = ClothesDryerSouth,
	ClothesDryerEast = ClothesDryerEast,
    ClothesDryerNorth = ClothesDryerNorth,
    ClothesDryerWest = ClothesDryerWest
}

local BinsContainers = {
    PizzaWhirledGarbageBinSouth = PizzaWhirledGarbageBinSouth,
	PizzaWhirledGarbageBinEast = PizzaWhirledGarbageBinEast,
    SeahorseCoffeeGarbageBinSouth = SeahorseCoffeeGarbageBinSouth,
	SeahorseCoffeeGarbageBinEast = SeahorseCoffeeGarbageBinEast,
    SpiffosGarbageBinSouth = SpiffosGarbageBinSouth,
	SpiffosGarbageBinEast = SpiffosGarbageBinEast,
    FossoilGarbageBinSouth = FossoilGarbageBinSouth,
	FossoilGarbageBinEast = FossoilGarbageBinEast,
	WheelieBinSouth = WheelieBinSouth,
	WheelieBinEast = WheelieBinEast,
	WheelieBinNorth = WheelieBinNorth,
	WheelieBinWest = WheelieBinWest,
	RecycleBin = RecycleBin,
    GrayGarbageBinSouth = GrayGarbageBinSouth,
	GrayGarbageBinEast = GrayGarbageBinEast
}

local OtherContainers = {
	CraftedTableWithDrawerEast = CraftedTableWithDrawerEast,
	CraftedTableWithDrawerSouth = CraftedTableWithDrawerSouth,
	CraftedTableWithDrawerWest = CraftedTableWithDrawerWest,
	CraftedTableWithDrawerNorth = CraftedTableWithDrawerNorth,
	QualityCraftedTableWithDrawerEast = QualityCraftedTableWithDrawerEast,
	QualityCraftedTableWithDrawerSouth = QualityCraftedTableWithDrawerSouth,
	QualityCraftedTableWithDrawerWest = QualityCraftedTableWithDrawerWest,
	QualityCraftedTableWithDrawerNorth = QualityCraftedTableWithDrawerNorth,
	--[[MetalCrateNorth = MetalCrateNorth,
	MetalCrateWest = MetalCrateWest,
	MetalCrateSouth = MetalCrateSouth,
	MetalCrateEast = MetalCrateEast,--]]
	--crafted_04
	--crafted_05
	MedicineCabinetSouth = MedicineCabinetSouth,
	MedicineCabinetEast = MedicineCabinetEast,
	MedicineCabinetNorth = MedicineCabinetNorth,
	MedicineCabinetWest = MedicineCabinetWest,
	MetalLockerSouth = MetalLockerSouth,
	MetalLockerEast = MetalLockerEast,
	MetalLockerNorth = MetalLockerNorth,
	MetalLockerWest = MetalLockerWest,
	BlueWallLockerEast = BlueWallLockerEast,
	BlueWallLockerSouth = BlueWallLockerSouth,
	BlueWallLockerWest = BlueWallLockerWest,
	BlueWallLockerNorth = BlueWallLockerNorth,
	SmallMilitaryLockerSouth = SmallMilitaryLockerSouth,
	SmallMilitaryLockerEast = SmallMilitaryLockerEast,
	SmallMilitaryLockerNorth = SmallMilitaryLockerNorth,
	SmallMilitaryLockerWest = SmallMilitaryLockerWest,
	YellowWallLockerEast = YellowWallLockerEast,
	YellowWallLockerSouth = YellowWallLockerSouth,
	YellowWallLockerWest = YellowWallLockerWest,
	YellowWallLockerNorth = YellowWallLockerNorth,
	LargeCardboardBoxOne = LargeCardboardBoxOne,
	LargeCardboardBoxTwo = LargeCardboardBoxTwo,
	LargeCardboardBoxThree = LargeCardboardBoxThree,
	LargeCardboardBoxFour = LargeCardboardBoxFour,
	--[[LargeCardboardBoxAboveOne = LargeCardboardBoxAboveOne,
	LargeCardboardBoxAboveTwo = LargeCardboardBoxAboveTwo,
	LargeCardboardBoxAboveThree = LargeCardboardBoxAboveThree,
	LargeCardboardBoxAboveFour = LargeCardboardBoxAboveFour,--]]
	SmallChestSouth = SmallChestSouth,
	SmallChestEast = SmallChestEast,
	SmallChestNorth = SmallChestNorth,
	SmallChestWest = SmallChestWest,
	ChinaCabinetLeftEast = ChinaCabinetLeftEast,
	ChinaCabinetRightEast = ChinaCabinetRightEast,
	ChinaCabinetLeftSouth = ChinaCabinetLeftSouth,
	ChinaCabinetRightSouth = ChinaCabinetRightSouth,
	ChinaCabinetLeftWest = ChinaCabinetLeftWest,
	ChinaCabinetRightWest = ChinaCabinetRightWest,
	ChinaCabinetLeftNorth = ChinaCabinetLeftNorth,
	ChinaCabinetRightNorth = ChinaCabinetRightNorth,
    RedMobileToolCabinetSouth = RedMobileToolCabinetSouth,
	RedMobileToolCabinetEast = RedMobileToolCabinetEast,
	RedMobileToolCabinetNorth = RedMobileToolCabinetNorth,
	RedMobileToolCabinetWest = RedMobileToolCabinetWest,
    OfficeDeskEast = OfficeDeskEast,
	OfficeDeskSouth = OfficeDeskSouth,
	OfficeDeskNorth = OfficeDeskNorth,
	OfficeDeskWest = OfficeDeskWest,
    GrayFileCabinetSouth = GrayFileCabinetSouth,
	GrayFileCabinetEast = GrayFileCabinetEast,
	GrayFileCabinetNorth = GrayFileCabinetNorth,
	GrayFileCabinetWest = GrayFileCabinetWest,
    WhiteFileCabinetSouth = WhiteFileCabinetSouth,
	WhiteFileCabinetEast = WhiteFileCabinetEast,
	WhiteFileCabinetNorth = WhiteFileCabinetNorth,
	WhiteFileCabinetWest = WhiteFileCabinetWest,
	DarkOfficeDeskLeftEast = DarkOfficeDeskLeftEast,
	DarkOfficeDeskRightEast = DarkOfficeDeskRightEast,
	DarkOfficeDeskLeftSouth = DarkOfficeDeskLeftSouth,
	DarkOfficeDeskRightSouth = DarkOfficeDeskRightSouth,
	DarkOfficeDeskLeftNorth = DarkOfficeDeskLeftNorth,
	DarkOfficeDeskRightNorth = DarkOfficeDeskRightNorth,
	DarkOfficeDeskLeftWest = DarkOfficeDeskLeftWest,
	DarkOfficeDeskRightWest = DarkOfficeDeskRightWest,
    MedicalToolDrawersEast = MedicalToolDrawersEast,
	MedicalToolDrawersSouth = MedicalToolDrawersSouth,
	MedicalToolDrawersWest = MedicalToolDrawersWest,
	MedicalToolDrawersNorth = MedicalToolDrawersNorth,
	FirstAidSouth = FirstAidSouth,
	FirstAidEast = FirstAidEast,
	FirstAidNorth = FirstAidNorth,
	FirstAidWest = FirstAidWest,
	MedicalDeskEast = MedicalDeskEast,
	MedicalDeskSouth = MedicalDeskSouth,
	MedicalCabinetWideLeftEast = MedicalCabinetWideLeftEast,
	MedicalCabinetWideRightEast = MedicalCabinetWideRightEast,
	MedicalCabinetWideLeftSouth = MedicalCabinetWideLeftSouth,
	MedicalCabinetWideRightSouth = MedicalCabinetWideRightSouth,
	MilitaryLockerSouth = MilitaryLockerSouth,
	MilitaryLockerEast = MilitaryLockerEast,
	MilitaryLockerNorth = MilitaryLockerNorth,
	MilitaryLockerWest = MilitaryLockerWest,
	CashRegisterEast = CashRegisterEast,
	CashRegisterSouth = CashRegisterSouth,
	CashRegisterNorth = CashRegisterNorth,
	CashRegisterWest = CashRegisterWest,
	BlackCashRegisterEast = BlackCashRegisterEast,
	BlackCashRegisterSouth = BlackCashRegisterSouth,
	BlackCashRegisterNorth = BlackCashRegisterNorth,
	BlackCashRegisterWest = BlackCashRegisterWest,
	--[[LargeMachineEast = LargeMachineEast,
	LargeMachineSouth = LargeMachineSouth,
	LargeMachineWest = LargeMachineWest,
	LargeMachineNorth = LargeMachineNorth,
	SmallSodaMachineEast = SmallSodaMachineEast,
	SmallSodaMachineSouth = SmallSodaMachineSouth,
	SmallSodaMachineWest = SmallSodaMachineWest,
	SmallSodaMachineNorth = SmallSodaMachineNorth,--]]
	PublicMailBoxSouth = PublicMailBoxSouth,
	PublicMailBoxEast = PublicMailBoxEast,
	PublicMailBoxNorth = PublicMailBoxNorth,
	PublicMailBoxWest = PublicMailBoxWest,
	MailBoxEast = MailBoxEast,
	MailBoxSouth = MailBoxSouth,
	MailBoxWest = MailBoxWest,
	MailBoxNorth = MailBoxNorth,
	--[[NewspaperKnewsEast = NewspaperKnewsEast,
	NewspaperKnewsSouth = NewspaperKnewsSouth,
	NewspaperKnewsWest = NewspaperKnewsWest,
	NewspaperKnewsNorth = NewspaperKnewsNorth,
	NewspaperDispatchEast = NewspaperDispatchEast,
	NewspaperDispatchSouth = NewspaperDispatchSouth,
	NewspaperDispatchNorth = NewspaperDispatchNorth,
	NewspaperDispatchWest = NewspaperDispatchWest,
	NewspaperHeraldEast = NewspaperHeraldEast,
	NewspaperHeraldSouth = NewspaperHeraldSouth,
	NewspaperHeraldWest = NewspaperHeraldWest,
	NewspaperHeraldNorth = NewspaperHeraldNorth,
	NewspaperTimesEast = NewspaperTimesEast,
	NewspaperTimesSouth = NewspaperTimesSouth,
	NewspaperTimesNorth = NewspaperTimesNorth,
	NewspaperTimesWest = NewspaperTimesWest,--]]
	BlueDumpsterLeftEast = BlueDumpsterLeftEast,
	BlueDumpsterRightEast = BlueDumpsterRightEast,
	BlueDumpsterLeftSouth = BlueDumpsterLeftSouth,
	BlueDumpsterRightSouth = BlueDumpsterRightSouth,
	OrangeDumpsterLeftEast = OrangeDumpsterLeftEast,
	OrangeDumpsterRightEast = OrangeDumpsterRightEast,
	OrangeDumpsterLeftSouth = OrangeDumpsterLeftSouth,
	OrangeDumpsterRightSouth = OrangeDumpsterRightSouth,
	CardboardBoxSouth = CardboardBoxSouth,
	CardboardBoxEast = CardboardBoxEast,
	BatteredCardboardBoxSouth = BatteredCardboardBoxSouth,
	BatteredCardboardBoxEast = BatteredCardboardBoxEast
}

local WardrobesContainers = {
	FancyWhiteWardrobeLeftEast = FancyWhiteWardrobeLeftEast,
	FancyWhiteWardrobeRightEast = FancyWhiteWardrobeRightEast,
	FancyWhiteWardrobeLeftSouth = FancyWhiteWardrobeLeftSouth,
	FancyWhiteWardrobeRightSouth = FancyWhiteWardrobeRightSouth,
    FancyWhiteWardrobeLeftWest = FancyWhiteWardrobeLeftWest,
    FancyWhiteWardrobeRightWest = FancyWhiteWardrobeRightWest,
	FancyWhiteWardrobeLeftNorth = FancyWhiteWardrobeLeftNorth,
	FancyWhiteWardrobeRightNorth = FancyWhiteWardrobeRightNorth,
	FancyOakWardrobeLeftEast = FancyOakWardrobeLeftEast,
	FancyOakWardrobeRightEast = FancyOakWardrobeRightEast,
	FancyOakWardrobeLeftSouth = FancyOakWardrobeLeftSouth,
	FancyOakWardrobeRightSouth = FancyOakWardrobeRightSouth,
    FancyOakWardrobeLeftWest = FancyOakWardrobeLeftWest,
    FancyOakWardrobeRightWest = FancyOakWardrobeRightWest,
	FancyOakWardrobeLeftNorth = FancyOakWardrobeLeftNorth,
	FancyOakWardrobeRightNorth = FancyOakWardrobeRightNorth,
	DarkFancyWardrobeLeftEast = DarkFancyWardrobeLeftEast,
	DarkFancyWardrobeRightEast = DarkFancyWardrobeRightEast,
	DarkFancyWardrobeLeftSouth = DarkFancyWardrobeLeftSouth,
	DarkFancyWardrobeRightSouth = DarkFancyWardrobeRightSouth,
    DarkFancyWardrobeLeftWest = DarkFancyWardrobeLeftWest,
    DarkFancyWardrobeRightWest = DarkFancyWardrobeRightWest,
	DarkFancyWardrobeLeftNorth = DarkFancyWardrobeLeftNorth,
	DarkFancyWardrobeRightNorth = DarkFancyWardrobeRightNorth,
	LargeWardrobeLeftEast = LargeWardrobeLeftEast,
	LargeWardrobeRightEast = LargeWardrobeRightEast,
	LargeWardrobeLeftSouth = LargeWardrobeLeftSouth,
	LargeWardrobeRightSouth = LargeWardrobeRightSouth,
    LargeWardrobeLeftWest = LargeWardrobeLeftWest,
    LargeWardrobeRightWest = LargeWardrobeRightWest,
	LargeWardrobeLeftNorth = LargeWardrobeLeftNorth,
	LargeWardrobeRightNorth = LargeWardrobeRightNorth,
	LightWoodWardrobeLeftEast = LightWoodWardrobeLeftEast,
	LightWoodWardrobeRightEast = LightWoodWardrobeRightEast,
	LightWoodWardrobeLeftSouth = LightWoodWardrobeLeftSouth,
	LightWoodWardrobeRightSouth = LightWoodWardrobeRightSouth,
	LightWoodWardrobeLeftWest = LightWoodWardrobeLeftWest,
	LightWoodWardrobeRightWest = LightWoodWardrobeRightWest,
	LightWoodWardrobeLeftNorth = LightWoodWardrobeLeftNorth,
	LightWoodWardrobeRightNorth = LightWoodWardrobeRightNorth,
	BeigeWardrobeLeftEast = BeigeWardrobeLeftEast,
	BeigeWardrobeRightEast = BeigeWardrobeRightEast,
	BeigeWardrobeLeftSouth = BeigeWardrobeLeftSouth,
	BeigeWardrobeRightSouth = BeigeWardrobeRightSouth,
	BeigeWardrobeLeftWest = BeigeWardrobeLeftWest,
	BeigeWardrobeRightWest = BeigeWardrobeRightWest,
	BeigeWardrobeLeftNorth = BeigeWardrobeLeftNorth,
	BeigeWardrobeRightNorth = BeigeWardrobeRightNorth
}

local FastSpriteLookup = {}

local function buildFastLookup()
    local allGroups = {
        --CookingAppliances,
        --FridgesAppliances,
        WashingMachinesAppliances,
        BinsContainers,
        CountersContainers,
		DrawersContainers,
        OtherContainers,
		WardrobesContainers
    }

    for _, group in ipairs(allGroups) do
        for _, spriteTable in pairs(group) do
            for _, spriteName in pairs(spriteTable) do
                FastSpriteLookup[spriteName] = spriteTable
            end
        end
    end
end

local function getSpriteDataByOriginalSprite(spriteName)
    return FastSpriteLookup[spriteName]
end

buildFastLookup()

return {
	SpritePairs = SpritePairs,
	--CookingAppliances = CookingAppliances,
    --FridgesAppliances = FridgesAppliances,
	WashingMachinesAppliances = WashingMachinesAppliances,
	BinsContainers = BinsContainers,
	CountersContainers = CountersContainers,
	DrawersContainers = DrawersContainers,
	OtherContainers = OtherContainers,
	WardrobesContainers = WardrobesContainers,
    getSpriteDataByOriginalSprite = getSpriteDataByOriginalSprite
}

-- ------------------------------------------------------------------------------------------------