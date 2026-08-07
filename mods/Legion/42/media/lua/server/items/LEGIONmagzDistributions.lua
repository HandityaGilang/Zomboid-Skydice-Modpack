require "Items/SuburbsDistributions"
require "Items/ProceduralDistributions"
require "Vehicles/VehicleDistributions"

-- Get the rarity multiplier based on Sandbox settings
local function getRarityMultiplier()
    local rarity = 2
    if SandboxVars and SandboxVars.LG and SandboxVars.LG.SpawnChance then
        rarity = SandboxVars.LG.SpawnChance
    end

    if rarity == 1 then
        return 1.5  -- Common
    elseif rarity == 2 then
        return 1.0  -- Uncommon
    elseif rarity == 3 then
        return 0.5  -- Rare
    elseif rarity == 4 then
        return 0.25 -- Extremely Rare
    elseif rarity == 5 then
        return 0.0  -- Never
    else
        return 1.0  -- Fallback
    end
end

-- Helper function to add items with multiple weights
local function addItems(distName, item, weights)
    local dist = ProceduralDistributions.list[distName]
    if not dist or not dist.items then return end

    for _, weight in ipairs(weights) do
        table.insert(dist.items, item)
        table.insert(dist.items, weight)
    end
end

-- Add your items when distributions merge
Events.OnPreDistributionMerge.Add(function()
    local rarityMultiplier = getRarityMultiplier()
    if rarityMultiplier <= 0 then return end -- "Never" selected

    -- POLICE STORAGE / LOCKERS
    addItems("PoliceStorageOutfit", "LG.LEGIONcommonMag",   {4, 2, 1})
    addItems("PoliceStorageOutfit", "LG.LEGIONadvancedMag", {4, 2, 1})
    addItems("PoliceStorageOutfit", "LG.LEGIONIngotMag",    {4, 2, 1})


    addItems("PoliceLockers", "LG.LEGIONcommonMag",   {4, 2, 1})
    addItems("PoliceLockers", "LG.LEGIONadvancedMag", {4, 2, 1})
    addItems("PoliceLockers", "LG.LEGIONIngotMag",    {4, 2, 1})


    -- ARMY STORAGE
    addItems("ArmyStorageOutfit", "LG.LEGIONcommonMag",   {6, 4, 3, 1})
    addItems("ArmyStorageOutfit", "LG.LEGIONadvancedMag", {6, 4, 3, 1})
    addItems("ArmyStorageOutfit", "LG.LEGIONIngotMag",    {6, 4, 3, 1})


    addItems("LockerArmyBedroom", "LG.LEGIONcommonMag",   {7})
    addItems("LockerArmyBedroom", "LG.LEGIONadvancedMag", {7})
    addItems("LockerArmyBedroom", "LG.LEGIONIngotMag",    {7})


    -- FIREARMS / GUN STORES
    addItems("FirearmWeapons", "LG.LEGIONcommonMag",   {4, 2, 1})
    addItems("FirearmWeapons", "LG.LEGIONadvancedMag", {4, 2, 1})
    addItems("FirearmWeapons", "LG.LEGIONIngotMag",    {4, 2, 1})


    addItems("PawnShopGunsSpecial", "LG.LEGIONcommonMag",   {3})
    addItems("PawnShopGunsSpecial", "LG.LEGIONadvancedMag", {3})
    addItems("PawnShopGunsSpecial", "LG.LEGIONIngotMag",    {3})


    addItems("ArmySurplusOutfit", "LG.LEGIONcommonMag",   {3})
    addItems("ArmySurplusOutfit", "LG.LEGIONadvancedMag", {3})
    addItems("ArmySurplusOutfit", "LG.LEGIONIngotMag",    {3})


    addItems("GunStoreShelf", "LG.LEGIONcommonMag",   {3})
    addItems("GunStoreShelf", "LG.LEGIONadvancedMag", {3})
    addItems("GunStoreShelf", "LG.LEGIONIngotMag",    {3})


    addItems("GunStoreDisplayCase", "LG.LEGIONcommonMag",   {3})
    addItems("GunStoreDisplayCase", "LG.LEGIONadvancedMag", {3})
    addItems("GunStoreDisplayCase", "LG.LEGIONIngotMag",    {3})


    -- APPLY LN-ONLY MULTIPLIER
    for _, dist in pairs(ProceduralDistributions.list) do
        local items = dist.items
        if items then
            for i = 1, #items - 1, 2 do
                local item = items[i]
                local weight = items[i + 1]

                if type(item) == "string"
                and string.sub(item, 1, 3) == "LG."
                and type(weight) == "number" then
                    items[i + 1] = weight * rarityMultiplier
                end
            end
        end
    end
end) -- closes Events.OnPreDistributionMerge.Add