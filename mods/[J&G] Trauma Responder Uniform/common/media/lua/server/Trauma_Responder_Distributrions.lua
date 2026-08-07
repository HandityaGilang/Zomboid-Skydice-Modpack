----------------------------------------------------------------------------
----------------------------- KATTAJ1 - TTAJ1bl4 ---------------------------
----------------------------------------------------------------------------

require "Items/ProceduralDistributions"

function ProjMedical_Red_insertItemSetsIntoDistributions(itemSets, suffixes, spawnChances, distributionNames)
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
    { baseItem = "Medical_Red_Helmet_Rook_FaceShield" },
    { baseItem = "Medical_Red_Helmet" },
    { baseItem = "Medical_Red_Helmet_Patriot" },

-- Hats
    { baseItem = "Medical_Red_Hat" },

-- Masks
    { baseItem = "Medical_Red_GasMask" },
    { baseItem = "Medical_Red_GasMask_NoFilter" },
    { baseItem = "Medical_Red_Balaclava_1Hole" },
    { baseItem = "Medical_Red_Balaclava_2Hole" },
    { baseItem = "Medical_Red_Balaclava_3Hole" },

-- Arms
    { baseItem = "Medical_Red_ElbowPads" },
    { baseItem = "Medical_Red_ShoulderPads_Patriot" },

-- Vests
    { baseItem = "Medical_Red_BulletproofVest_Patriot" }, 

-- Legs
    { baseItem = "Medical_Red_KneePads" },
    { baseItem = "Medical_Red_HeavyKneePads" },

-- Jacket
    { baseItem = "Medical_Red_Jacket" }, 

-- Pants
    { baseItem = "Medical_Red_Pants" },

-- Boots
    { baseItem = "Medical_Red_Boots" },
    { baseItem = "Medical_Red_TacBoots" },

-- Gloves
    { baseItem = "Medical_Red_Gloves" },

-- Bags
    { baseItem = "Medical_Red_Backpack" },

-- Accessories
    { baseItem = "Pouch_Utility_Medium-Medic_Left" },
    { baseItem = "Pouch_Utility_Medium-Medic_ArmorLeft" },
    { baseItem = "BagBack_StormPack_Large-Medic" },
    { baseItem = "BagBack_StormPack_Medium-Medic" },
    { baseItem = "BagBack_StormPack_Small-Medic" },
    { baseItem = "Medical_Red_DarkZonePack" },
}

ProjMedical_Red_insertItemSetsIntoDistributions(itemSets, emptySuffixes, spawnChances, distributionNames)