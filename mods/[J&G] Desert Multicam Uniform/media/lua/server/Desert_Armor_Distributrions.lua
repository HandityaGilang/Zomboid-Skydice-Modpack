----------------------------------------------------------------------------
----------------------------- KATTAJ1 - TTAJ1bl4 ---------------------------
----------------------------------------------------------------------------

require "Items/ProceduralDistributions"


function ProjDesert_Camo_insertItemSetsIntoDistributions(itemSets, suffixes, spawnChances, distributionNames)
    local currentIndex = 1 

    for _, distributionName in ipairs(distributionNames) do
        local distribution = ProceduralDistributions.list[distributionName]

        for i, itemSet in ipairs(itemSets) do
            local baseItem = itemSet.baseItem
            local continuation = itemSet.continuation or ""

            for _, suffix in ipairs(suffixes) do
                local fullItem = "Base." .. baseItem .. suffix .. continuation

                local currentSpawnChance = spawnChances[currentIndex]
                currentIndex = (currentIndex % #spawnChances) + 1

                table.insert(distribution.items, fullItem)
                table.insert(distribution.items, currentSpawnChance)
            end
        end
    end
end

local commonSuffixes = {""} 
local militarySuffixesPlusMedic = {""} 
local militarySuffixesPlusPress = {""} 
local pressSuffixes = {""} 
local emptySuffixes = {""} 
 
local spawnChances = {1, 1, 1} 
local spawnChancesBagBacks = {1, 1, 1, 1, 1} 
local spawnChancesEqual = {1} 
local spawnChancesEqual05 = {1} 
 

local distributionNames = {"ArmySurplusOutfit", "LockerArmyBedroom", "ArmyStorageOutfit", "GunStoreCounter"} 
local policePlusArmyDistributions = {"ArmySurplusOutfit", "LockerArmyBedroom", "ArmyStorageOutfit","PoliceStorageOutfit", "PoliceLockers", "PoliceStorageGuns", "GunStoreCounter"} 
local policeDistributions = {"PoliceStorageOutfit", "PoliceLockers", "PoliceStorageGuns"} 
local storesDistributions = {"ClothingStorageAllShirts", "ClothingStorageLegwear", "ClothingStoresJeans"}

-- PoliceStorageOutfit
-- PoliceLockers
-- PoliceStorageGuns

 
local itemSets = { 
-- Helmets 
    { baseItem = "Desert_Camo_Helmet" },

-- Hats 
    { baseItem = "Desert_Camo_Hat" },
	
-- Arms protection lower     
    { baseItem = "Desert_Camo_Elbow_Pads" }, 

-- Vests 
    { baseItem = "Desert_Camo_Vest" }, 
	{ baseItem = "Desert_Camo_LightVest" }, 

-- Legs Protection Lower 
    { baseItem = "Desert_Camo_Knee_Pads" }, 

-- Jacket
    { baseItem = "Desert_Camo_Jacket" }, 

-- Pants
    { baseItem = "Desert_Camo_Pants" },

-- Boots
    { baseItem = "Desert_Camo_Boots" },
    { baseItem = "Desert_Camo_TacBoots" },

-- Gloves
    { baseItem = "Desert_Camo_Gloves" },

} 
ProjDesert_Camo_insertItemSetsIntoDistributions(itemSets, emptySuffixes, spawnChances, distributionNames)


