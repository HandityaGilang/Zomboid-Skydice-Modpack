----------------------------------------------------------------------------
----------------------------- Jordanal ---------------------------
----------------------------------------------------------------------------

require "Items/ProceduralDistributions"

function ProjSWAT_insertItemSetsIntoDistributions(itemSets, suffixes, spawnChances, distributionNames)
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
    { baseItem = "SWAT_Helmet" },
    { baseItem = "SWAT_Helmet_Rook_FaceShield" },
    { baseItem = "SWAT_Helmet_AM-95_VisorDown" },
    { baseItem = "SWAT_Helmet_Patriot" },

-- Hats
    { baseItem = "SWAT_Hat" },

-- Masks 
    { baseItem = "SWAT_GasMask-M80" },
    { baseItem = "SWAT_GasMask-M80_NoFilter" },
    { baseItem = "SWAT_Balaclava" },

-- Arms
    { baseItem = "SWAT_Elbow_Pads" },
    { baseItem = "SWAT_ShoulderPads_Patriot" },
    { baseItem = "SWAT_ShoulderPads_Vanguard" },

-- Vests
    { baseItem = "SWAT_Vest" }, 
	{ baseItem = "SWAT_LightVest" }, 

-- Legs
    { baseItem = "SWAT_Knee_Pads" },
    { baseItem = "SWAT_KneePads_Defender" },
    { baseItem = "SWAT_Thigh_Pads" },

-- Jacket
    { baseItem = "SWAT_Jacket" }, 

-- Pants
    { baseItem = "SWAT_Pants" },

-- Boots
    { baseItem = "SWAT_Boots" },
    { baseItem = "SWAT_TacBoots" },

-- Gloves
    { baseItem = "SWAT_Gloves" },

-- Bags
    { baseItem = "SWAT_Backpack_Ranger_Tight" },
}

ProjSWAT_insertItemSetsIntoDistributions(itemSets, emptySuffixes, spawnChances, distributionNames)