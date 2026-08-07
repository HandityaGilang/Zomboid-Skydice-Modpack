----------------------------------------------------------------------------
----------------------------- KATTAJ1 - TTAJ1bl4 ---------------------------
----------------------------------------------------------------------------

require "Items/ProceduralDistributions"

function ProjFireFighter_insertItemSetsIntoDistributions(itemSets, suffixes, spawnChances, distributionNames)
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

local distributionNames = {"FireDeptLockers", "FireStorageOutfit", "FireStorageTools"} 
 
local itemSets = { 
-- Helmets
    { baseItem = "FireFighter_Helmet" },
    { baseItem = "Firefighter_Helmet_VisorDown" },

-- Masks
    { baseItem = "Firefighter_GasMask_Filter" },
    { baseItem = "Firefighter_GasMask_NoFilter" },

-- Accessories
    { baseItem = "FireFighter_Strap" },
	
-- Arms
    { baseItem = "Firefighter_ElbowPads" },
    { baseItem = "Firefighter_ShoulderPads_Patriot" },
    { baseItem = "Firefighter_ShoulderPads_Vanguard" },

-- Vests
    { baseItem = "Firefighter_BulletproofVest_Patriot" },

-- Legs
    { baseItem = "Firefighter_KneePads" },
    { baseItem = "Firefighter_HeavyKneePads" },

-- Jacket
    { baseItem = "FireFighter_Jacket" },

-- Pants
    { baseItem = "FireFighter_Pants" },

-- Boots
    { baseItem = "FireFighter_Boots" },

-- Gloves
    { baseItem = "FireFighter_Gloves" },

-- Bags
    { baseItem = "Firefighter_GasTankBackpack" },

-- AXE
    { baseItem = "1Handed_FireAxe" },
    { baseItem = "1Handed_RustyAxe" },
    { baseItem = "Viking_Axe" },
    { baseItem = "Emergency_Axe_HeavySwing" },
    { baseItem = "HeavyDuty_FireAxe" },
    { baseItem = "Modern_Axe " },
}

ProjFireFighter_insertItemSetsIntoDistributions(itemSets, emptySuffixes, spawnChances, distributionNames)