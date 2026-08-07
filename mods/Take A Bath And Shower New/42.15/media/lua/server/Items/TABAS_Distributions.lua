require "Items/ProceduralDistributions"

local TABAS_Distributions = {}

local bathItemsLootTables = {
    BathroomCounter = 8,
    BathroomCounterMotel = 20,
    BathroomShelf = 10,
    ChangeroomCounters = 10,
    DaycareCounter = 10,
    GigamartBathing = 20,
    -- PharmacyCosmetics = 4,
    -- PrisonCellRandom = 4,
    -- PrisonCellRandomClassy = 4,
    -- StoreKitchenCleaning = 8,
}

local chanceMultiplier = {0, 0.1, 0.25, 0.6, 1, 1.2}


function TABAS_Distributions.addBathItemDistribution(item)
    local distributions = ProceduralDistributions.list
    local mul = chanceMultiplier[SandboxVars.TakeABathAndShower.BathItemSpawnChance]
    if mul == 0 then return end

    for k, v in pairs(bathItemsLootTables) do
        table.insert(distributions[k].items, item)
        table.insert(distributions[k].items, v * mul)
    end
end

function TABAS_Distributions.addBathSaltDistribution(item)
    local distributions = ProceduralDistributions.list
    local mul = chanceMultiplier[SandboxVars.TakeABathAndShower.BathSaltSpawnChance]
    if mul == 0 then return end

    for k, v in pairs(bathItemsLootTables) do
        table.insert(distributions[k].items, item)
        table.insert(distributions[k].items, v * mul)
    end
end

TABAS_Distributions.addBathItemDistribution("TABAS.BodyShampoo")

TABAS_Distributions.addBathSaltDistribution("TABAS.BathSalt_Lavender")
TABAS_Distributions.addBathSaltDistribution("TABAS.BathSalt_Citrus")
TABAS_Distributions.addBathSaltDistribution("TABAS.BathSalt_Floral")
TABAS_Distributions.addBathSaltDistribution("TABAS.BathSalt_Forest")
TABAS_Distributions.addBathSaltDistribution("TABAS.BathSalt_Herb")
TABAS_Distributions.addBathSaltDistribution("TABAS.BathSalt_Rose")
