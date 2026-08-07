--
-- Knox Detection Kit — Loot Distribution
-- Injects the detection kit into medical and military loot tables.
-- Spawn chances scale with the KitRarity sandbox option.
--

print("[KnoxDetectionKit] Distribution module loaded")

local RARITY_MULTIPLIERS = {
    [1] = 2.0,   -- Common
    [2] = 1.0,   -- Uncommon (default)
    [3] = 0.4,   -- Rare
    [4] = 0.15,  -- Very Rare
}

local DISTRIBUTIONS = {
    { name = "MedicalClinicDrugs",      baseChance = 1.5 },
    { name = "MedicalStorageDrugs",     baseChance = 1.5 },
    { name = "ArmyHangarTools",         baseChance = 0.5 },
    { name = "SafehouseMedical",        baseChance = 0.4 },
    { name = "ArmyStorageMedical",      baseChance = 1   },
    { name = "ArmyBunkerMedical",       baseChance = 0.3 },
    { name = "TestingLab",              baseChance = 0.3 },
    { name = "LockerArmyBedroom",       baseChance = 0.3 },
    { name = "ArmyStorageGuns",         baseChance = 0.3 },
}

local function removeExistingEntries(items)
    local i = 1
    local removed = 0
    while i <= #items do
        if items[i] == "Base.KnoxDetectionKit" then
            table.remove(items, i)
            table.remove(items, i)
            removed = removed + 1
        else
            i = i + 2
        end
    end
    return removed
end

local function injectKnoxDetectionKit()
    local procDist = ProceduralDistributions
    if not procDist or not procDist.list then
        print("[KnoxDetectionKit] WARNING: ProceduralDistributions.list not found, skipping loot injection")
        return
    end

    local rarityEnum = 2
    if SandboxVars and SandboxVars.KnoxDetectionKit and SandboxVars.KnoxDetectionKit.KitRarity then
        rarityEnum = SandboxVars.KnoxDetectionKit.KitRarity
    end
    local multiplier = RARITY_MULTIPLIERS[rarityEnum] or 1.0

    print("[KnoxDetectionKit] Rarity setting: " .. tostring(rarityEnum) .. " (multiplier " .. tostring(multiplier) .. "x)")

    local injected = 0
    for _, dist in ipairs(DISTRIBUTIONS) do
        if procDist.list[dist.name] and procDist.list[dist.name].items then
            local items = procDist.list[dist.name].items
            local removed = removeExistingEntries(items)
            if removed > 0 then
                print("[KnoxDetectionKit] Removed " .. removed .. " stale entry/entries from " .. dist.name)
            end
            local chance = dist.baseChance * multiplier
            table.insert(items, "Base.KnoxDetectionKit")
            table.insert(items, chance)
            injected = injected + 1
        else
            print("[KnoxDetectionKit] WARNING: Distribution '" .. dist.name .. "' not found, skipping")
        end
    end

    print("[KnoxDetectionKit] Loot distribution injected into " .. injected .. " location(s)")
end

Events.OnPreDistributionMerge.Add(injectKnoxDetectionKit)
