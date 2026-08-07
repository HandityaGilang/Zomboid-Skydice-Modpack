require "Entity/TimedActions/ISHandcraftAction"
local AZB42_BAG_UPGRADE_RECIPES = {
    ["AuthenticZBackpacksPlus.Bag_ALICEpack_Army_Tier_1"] = "Upgrade Camo Alicepack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_ALICEpack_Army_Tier_2"] = "Upgrade Camo Alicepack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_ALICEpack_DesertCamo"] = "Upgrade Desert Camo Alicepack (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_ALICEpack_DesertCamo_Tier_1"] = "Upgrade Desert Camo Alicepack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_ALICEpack_DesertCamo_Tier_2"] = "Upgrade Desert Camo Alicepack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_ALICEpack_Festive"] = "Upgrade Festive Alicepack (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_ALICEpack_Festive_Tier_1"] = "Upgrade Festive Alicepack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_ALICEpack_Festive_Tier_2"] = "Upgrade Festive Alicepack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_ALICEpack_Tier_1"] = "Upgrade Alicepack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_ALICEpack_Tier_2"] = "Upgrade Alicepack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_ALICEpack_UrbanCamo"] = "Upgrade Urban Camo Alicepack (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_ALICEpack_UrbanCamo_Tier_1"] = "Upgrade Urban Camo Alicepack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_ALICEpack_UrbanCamo_Tier_2"] = "Upgrade Urban Camo Alicepack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_ARVN_Rucksack_Tier_1"] = "Upgrade Rucksack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_ARVN_Rucksack_Tier_2"] = "Upgrade Rucksack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_B4BEvangelo"] = "Upgrade Evangelos Backpack (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_B4BEvangelo_Tier_1"] = "Upgrade Evangelos Daypack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_B4BEvangelo_Tier_2"] = "Upgrade Evangelos Daypack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_B4BHoffman"] = "Upgrade Hoffmans Backpack (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_B4BHoffman_Tier_1"] = "Upgrade Hoffmans Daypack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_B4BHoffman_Tier_2"] = "Upgrade Hoffmans Daypack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_B4BHolly"] = "Upgrade Hollys Backpack (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_B4BHolly_Tier_1"] = "Upgrade Hollys Daypack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_B4BHolly_Tier_2"] = "Upgrade Hollys Daypack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_B4BMom"] = "Upgrade Casual Daypack (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_B4BMom_Tier_1"] = "Upgrade Casual Daypack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_B4BMom_Tier_2"] = "Upgrade Casual Daypack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_B4BWalker"] = "Upgrade Walkers Backpack (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_B4BWalker_Tier_1"] = "Upgrade Walkers Backpack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_B4BWalker_Tier_2"] = "Upgrade Walkers Backpack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_BigHikingBag_Tier_1"] = "Upgrade Big Hiking Bag (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_BigHikingBag_Tier_2"] = "Upgrade Big Hiking Bag (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_DuffelBagGrey_Tier_1"] = "Upgrade Grey Duffelbag Bag (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_DuffelBagGrey_Tier_2"] = "Upgrade Grey Duffelbag Bag (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_DuffelBagTINT_Tier_1"] = "Upgrade Colored Duffelbag Bag (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_DuffelBagTINT_Tier_2"] = "Upgrade Colored Duffelbag Bag (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_DuffelBag_Festive"] = "Upgrade Festive Duffelbag Bag (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_DuffelBag_Festive_Tier_1"] = "Upgrade Festive Duffelbag Bag (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_DuffelBag_Festive_Tier_2"] = "Upgrade Festive Duffelbag Bag (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_DuffelBag_Tier_1"] = "Upgrade Duffelbag Bag (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_DuffelBag_Tier_2"] = "Upgrade Duffelbag Bag (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_MedicalBag_Tier_1"] = "Upgrade Medical Duffelbag Bag (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_MedicalBag_Tier_2"] = "Upgrade Medical Duffelbag Bag (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_Military_Tier_1"] = "Upgrade Military Duffelbag Bag (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_Military_Tier_2"] = "Upgrade Military Duffelbag Bag (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_NormalHikingBag_Tier_1"] = "Upgrade Hiking Bag (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_NormalHikingBag_Tier_2"] = "Upgrade Hiking Bag (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_Packsport_Plain"] = "Upgrade Packsport Backpack (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_Packsport_Plain_Tier_1"] = "Upgrade Packsport Backpack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_Packsport_Plain_Tier_2"] = "Upgrade Packsport Backpack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_Packsport_Rim"] = "Upgrade Rimmed Packsport Backpack (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_Packsport_Rim_Tier_1"] = "Upgrade Rimmed Packsport Backpack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_Packsport_Rim_Tier_2"] = "Upgrade Rimmed Packsport Backpack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_RoadsideDuffel"] = "Upgrade Roadside Duffelbag Bag (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_RoadsideDuffel_Tier_1"] = "Upgrade Roadside Duffelbag Bag (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_RoadsideDuffel_Tier_2"] = "Upgrade Roadside Duffelbag Bag (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_SchoolBagCEDA"] = "Upgrade Green CEDA Hazmat Pack (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_SchoolBagCEDABlack"] = "Upgrade Black CEDA Hazmat Pack (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_SchoolBagCEDABlack_Tier_1"] = "Upgrade Black CEDA Hazmat Pack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_SchoolBagCEDABlack_Tier_2"] = "Upgrade Black CEDA Hazmat Pack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_SchoolBagCEDABlue"] = "Upgrade Blue CEDA Hazmat Pack (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_SchoolBagCEDABlue_Tier_1"] = "Upgrade Blue CEDA Hazmat Pack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_SchoolBagCEDABlue_Tier_2"] = "Upgrade Blue CEDA Hazmat Pack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_SchoolBagCEDARed"] = "Upgrade Red CEDA Hazmat Pack (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_SchoolBagCEDARed_Tier_1"] = "Upgrade Red CEDA Hazmat Pack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_SchoolBagCEDARed_Tier_2"] = "Upgrade Red CEDA Hazmat Pack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_SchoolBagCEDA_Tier_1"] = "Upgrade Green CEDA Hazmat Pack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_SchoolBagCEDA_Tier_2"] = "Upgrade Green CEDA Hazmat Pack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_SchoolBagNBH"] = "Upgrade NBH Hazmat Pack (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_SchoolBagNBH_Tier_1"] = "Upgrade NBH Hazmat Pack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_SchoolBagNBH_Tier_2"] = "Upgrade NBH Hazmat Pack (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_Schoolbag_Kids_Tier_1"] = "Upgrade Kids School Bag (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_Schoolbag_Kids_Tier_2"] = "Upgrade Kids School Bag (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_Schoolbag_Tier_1"] = "Upgrade School Bag (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_Schoolbag_Tier_2"] = "Upgrade School Bag (Tier 3)",
    ["AuthenticZBackpacksPlus.Bag_SpiffoBackpackAZ"] = "Upgrade Spiffo Backpack (Tier 1)",
    ["AuthenticZBackpacksPlus.Bag_SpiffoBackpackAZ_Tier_1"] = "Upgrade Spiffo Backpack (Tier 2)",
    ["AuthenticZBackpacksPlus.Bag_SpiffoBackpackAZ_Tier_2"] = "Upgrade Spiffo Backpack (Tier 3)",
    ["Bag_BigHikingBag"] = "Upgrade Big Hiking Bag (Tier 1)",
    ["Bag_BigHikingBag_Travel"] = "Upgrade Big Hiking Bag (Tier 1)",
    ["Base.Bag_ALICEpack"] = "Upgrade Alicepack (Tier 1)",
    ["Base.Bag_ALICEpack_Army"] = "Upgrade Camo Alicepack (Tier 1)",
        ["Base.Bag_DuffelBag"] = "Upgrade Duffelbag Bag (Tier 1)",
    ["Base.Bag_DuffelBagTINT"] = "Upgrade Colored Duffelbag Bag (Tier 1)",
    ["Base.Bag_FoodCanned"] = "Upgrade Grey Duffelbag Bag (Tier 1)",
    ["Base.Bag_FoodSnacks"] = "Upgrade Grey Duffelbag Bag (Tier 1)",
    ["Base.Bag_HikingBag_Travel"] = "Upgrade Hiking Bag (Tier 1)",
    ["Base.Bag_InmateEscapedBag"] = "Upgrade Colored Duffelbag Bag (Tier 1)",
    ["Base.Bag_MedicalBag"] = "Upgrade Medical Duffelbag Bag (Tier 1)",
    ["Base.Bag_Military"] = "Upgrade Military Duffelbag Bag (Tier 1)",
    ["Base.Bag_MoneyBag"] = "Upgrade Grey Duffelbag Bag (Tier 1)",
    ["Base.Bag_NormalHikingBag"] = "Upgrade Hiking Bag (Tier 1)",
    ["Base.Bag_Schoolbag"] = "Upgrade School Bag (Tier 1)",
    ["Base.Bag_Schoolbag_Kids"] = "Upgrade Kids School Bag (Tier 1)",
    ["Base.Bag_Schoolbag_Travel"] = "Upgrade School Bag (Tier 1)",
    ["Base.Bag_ShotgunBag"] = "Upgrade Grey Duffelbag Bag (Tier 1)",
    ["Base.Bag_ShotgunDblBag"] = "Upgrade Grey Duffelbag Bag (Tier 1)",
    ["Base.Bag_ShotgunDblSawnoffBag"] = "Upgrade Grey Duffelbag Bag (Tier 1)",
    ["Base.Bag_ShotgunSawnoffBag"] = "Upgrade Grey Duffelbag Bag (Tier 1)",
    ["Base.Bag_SurvivorBag"] = "Upgrade Alicepack (Tier 1)",
    ["Base.Bag_ToolBag"] = "Upgrade Grey Duffelbag Bag (Tier 1)",
    ["Base.Bag_WeaponBag"] = "Upgrade Grey Duffelbag Bag (Tier 1)",
    ["Base.Bag_WorkerBag"] = "Upgrade Colored Duffelbag Bag (Tier 1)",
}
local AZB42_MAKE_ITEMS = {
    ["Base.Hat_GasMask"] = true,
    ["Base.Hat_GasMask_nofilter"] = true,
    ["Base.PipeBomb"] = true,
    ["Base.PipeBombSensorV1"] = true,
    ["Base.PipeBombSensorV2"] = true,
    ["Base.PipeBombSensorV3"] = true,
    ["Base.PipeBombRemote"] = true,
    ["Base.Aerosolbomb"] = true,
    ["Base.AerosolbombTriggered"] = true,
    ["Base.AerosolbombSensorV1"] = true,
    ["Base.AerosolbombSensorV2"] = true,
    ["Base.AerosolbombSensorV3"] = true,
    ["Base.AerosolbombRemote"] = true,
    ["Base.FlameTrap"] = true,
    ["Base.FlameTrapTriggered"] = true,
    ["Base.FlameTrapSensorV1"] = true,
    ["Base.FlameTrapSensorV2"] = true,
    ["Base.FlameTrapSensorV3"] = true,
    ["Base.FlameTrapRemote"] = true,
    ["Base.SmokeBomb"] = true,
    ["Base.SmokeBombRemote"] = true,
    ["Base.SmokeBombSensorV1"] = true,
    ["Base.SmokeBombSensorV2"] = true,
    ["Base.SmokeBombSensorV3"] = true,
    ["Base.SmokeBombTriggered"] = true,
    ["Base.Molotov"] = true,
}
local AZB42_REVERT_ITEMS = {
    ["AuthenticZBackpacksPlus.Hat_GasMask"] = true,
    ["AuthenticZBackpacksPlus.Hat_GasMask_nofilter"] = true,
    ["AuthenticZBackpacksPlus.PipeBomb"] = true,
    ["AuthenticZBackpacksPlus.PipeBombSensorV1"] = true,
    ["AuthenticZBackpacksPlus.PipeBombSensorV2"] = true,
    ["AuthenticZBackpacksPlus.PipeBombSensorV3"] = true,
    ["AuthenticZBackpacksPlus.PipeBombRemote"] = true,
    ["AuthenticZBackpacksPlus.Aerosolbomb"] = true,
    ["AuthenticZBackpacksPlus.AerosolbombTriggered"] = true,
    ["AuthenticZBackpacksPlus.AerosolbombSensorV1"] = true,
    ["AuthenticZBackpacksPlus.AerosolbombSensorV2"] = true,
    ["AuthenticZBackpacksPlus.AerosolbombSensorV3"] = true,
    ["AuthenticZBackpacksPlus.AerosolbombRemote"] = true,
    ["AuthenticZBackpacksPlus.FlameTrap"] = true,
    ["AuthenticZBackpacksPlus.FlameTrapTriggered"] = true,
    ["AuthenticZBackpacksPlus.FlameTrapSensorV1"] = true,
    ["AuthenticZBackpacksPlus.FlameTrapSensorV2"] = true,
    ["AuthenticZBackpacksPlus.FlameTrapSensorV3"] = true,
    ["AuthenticZBackpacksPlus.FlameTrapRemote"] = true,
    ["AuthenticZBackpacksPlus.SmokeBomb"] = true,
    ["AuthenticZBackpacksPlus.SmokeBombRemote"] = true,
    ["AuthenticZBackpacksPlus.SmokeBombSensorV1"] = true,
    ["AuthenticZBackpacksPlus.SmokeBombSensorV2"] = true,
    ["AuthenticZBackpacksPlus.SmokeBombSensorV3"] = true,
    ["AuthenticZBackpacksPlus.SmokeBombTriggered"] = true,
    ["AuthenticZBackpacksPlus.Molotov"] = true,
}

local AZB42_DIRECT_RECIPES_BY_ITEM = {
    ["Base.Dice"] = "Make Backpack Attachable Item (Dice)",
    ["Base.Rubberducky"] = "Make Backpack Attachable Item (Plushie)",
    ["Base.ToyBear"] = "Make Backpack Attachable Item (Plushie)",
    ["Base.Doll"] = "Make Backpack Attachable Item (Plushie)",
    ["Base.Spiffo"] = "Make Backpack Attachable Item (Plushie)",
    ["Base.FurbertSquirrel"] = "Make Backpack Attachable Item (Plushie)",
    ["Base.FluffyfootBunny"] = "Make Backpack Attachable Item (Plushie)",
    ["Base.MoleyMole"] = "Make Backpack Attachable Item (Plushie)",
    ["Base.PancakeHedgehog"] = "Make Backpack Attachable Item (Plushie)",
    ["Base.FreddyFox"] = "Make Backpack Attachable Item (Plushie)",
    ["Base.JacquesBeaver"] = "Make Backpack Attachable Item (Plushie)",
    ["Base.BorisBadger"] = "Make Backpack Attachable Item (Plushie)",
    ["Base.Pop"] = "Make Backpack Attachable Item (Pop Soda)",
    ["Base.Pop2"] = "Make Backpack Attachable Item (Pop Soda)",
    ["Base.Pop3"] = "Make Backpack Attachable Item (Pop Soda)",
    ["Base.Lighter"] = "Make Backpack Attachable Item (Lighter)",
}
local function AZB42_CheckItemForAttachableRecipe(item)
    if not item or not item.getFullType then return nil end
    local fullType = item:getFullType()
    if AZB42_MAKE_ITEMS[fullType] then
        return "Make Attachable Item", fullType
    end
    if AZB42_REVERT_ITEMS[fullType] then
        return "Revert Attachable Item", fullType
    end
    return nil
end
local function AZB42_CheckBagLookupKey(key)
    if not key then return nil end
    local recipeName = AZB42_BAG_UPGRADE_RECIPES[key]
    if recipeName then return recipeName, key end
    local bare = tostring(key):match("^[^.]+%.(.+)$")
    if bare then
        recipeName = AZB42_BAG_UPGRADE_RECIPES[bare]
        if recipeName then return recipeName, key .. " -> " .. bare end
    else
        recipeName = AZB42_BAG_UPGRADE_RECIPES["Base." .. key]
            or AZB42_BAG_UPGRADE_RECIPES["AuthenticZBackpacksPlus." .. key]
        if recipeName then return recipeName, key end
    end
    return nil
end
local function AZB42_CheckItemForBagUpgradeRecipe(item)
    if not item or not item.getFullType then return nil end
    return AZB42_CheckBagLookupKey(item:getFullType())
end
local function AZB42_CheckItemForDirectRecipe(item)
    if not item or not item.getFullType then return nil end
    local fullType = item:getFullType()
    local recipeName = AZB42_DIRECT_RECIPES_BY_ITEM[fullType]
    if recipeName then return recipeName, fullType end
    return nil
end
local function AZB42_ScanItemList(itemList, checkItem)
    if not itemList then return nil end
    if itemList.size and itemList.get then
        for i = 0, itemList:size() - 1 do
            local recipeName, fullType = checkItem(itemList:get(i))
            if recipeName then return recipeName, fullType end
        end
        return nil
    end
    for _, item in pairs(itemList) do
        local recipeName, fullType = checkItem(item)
        if recipeName then return recipeName, fullType end
    end
    return nil
end
local function AZB42_InferRecipe(recipeItem, manualInputs, items, checkItem)
    local recipeName, fullType = checkItem(recipeItem)
    if recipeName then return recipeName, fullType end
    recipeName, fullType = AZB42_ScanItemList(items, checkItem)
    if recipeName then return recipeName, fullType end
    if manualInputs then
        for _, itemList in pairs(manualInputs) do
            recipeName, fullType = AZB42_ScanItemList(itemList, checkItem)
            if recipeName then return recipeName, fullType end
        end
    end
    return nil
end
local function AZB42_GetCraftRecipe(recipeName)
    if not recipeName or not getScriptManager then return nil end
    local scriptManager = getScriptManager()
    if not scriptManager or not scriptManager.getCraftRecipe then return nil end
    return scriptManager:getCraftRecipe(recipeName)
        or scriptManager:getCraftRecipe("AuthenticZRecipes." .. recipeName)
        or scriptManager:getCraftRecipe("AuthenticZBackpacksPlus." .. recipeName)
        or scriptManager:getCraftRecipe("Base." .. recipeName)
end
local function AZB42_RecoverCraftRecipe(craftRecipe, manualInputs, items, recipeItem)
    if craftRecipe then return craftRecipe end
    if not isServer or not isServer() then return craftRecipe end
    local recipeName = nil
    recipeName = AZB42_InferRecipe(recipeItem, manualInputs, items, AZB42_CheckItemForDirectRecipe)
    if not recipeName then
        recipeName = AZB42_InferRecipe(recipeItem, manualInputs, items, AZB42_CheckItemForAttachableRecipe)
    end
    if not recipeName then
        recipeName = AZB42_InferRecipe(recipeItem, manualInputs, items, AZB42_CheckItemForBagUpgradeRecipe)
    end
    if recipeName then
        return AZB42_GetCraftRecipe(recipeName)
    end
    return nil
end
if ISHandcraftAction and ISHandcraftAction.new and not ISHandcraftAction.AZB42RecipeRecoveryWrapped then
    ISHandcraftAction.AZB42RecipeRecoveryWrapped = true
    local originalNew = ISHandcraftAction.new
    function ISHandcraftAction:new(character, craftRecipe, containers, isoObject, craftBench, manualInputs, items, recipeItem, variableInputRatio, eatPercentage)
        craftRecipe = AZB42_RecoverCraftRecipe(craftRecipe, manualInputs, items, recipeItem)
        return originalNew(self, character, craftRecipe, containers, isoObject, craftBench, manualInputs, items, recipeItem, variableInputRatio, eatPercentage)
    end
end
