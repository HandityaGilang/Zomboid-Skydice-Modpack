-- media/lua/server/ZombieCigLoot.lua
-- Zombies Have Cigarettes - B42.19

if isClient() then return end

local MOD = "ZombsHaveCigs"
local PROCESSED_KEY = MOD .. "_LootRolled"

local function opt(name, default)
    if SandboxVars and SandboxVars[MOD] and SandboxVars[MOD][name] ~= nil then
        return SandboxVars[MOD][name]
    end

    local flat = MOD .. "_" .. name
    if SandboxVars and SandboxVars[flat] ~= nil then
        return SandboxVars[flat]
    end

    return default
end

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local function applyUses(item, config)
    if not item or not config then return nil end

    local minUses = clamp(config.defaultMin, 1, config.maxUses)
    local maxUses = clamp(config.defaultMax, 1, config.maxUses)
    local uses = ZombRand(minUses, maxUses + 1)

    item:setUsedDelta(uses / config.maxUses)
    return uses
end

local LOOT = {
    {
        weight = 58,
        item = "Base.CigarettePack",
        logName = "CigPack",
        uses = {
            defaultMin = 4,
            defaultMax = 19,
            maxUses = 20,
        },
    },
    {
        weight = 13,
        category = "fire",
        item = "Base.Lighter",
        logName = "Lighter",
        uses = {
            defaultMin = 8,
            defaultMax = 28,
            maxUses = 32,
        },
    },
    {
        weight = 8,
        category = "fire",
        item = "Base.LighterDisposable",
        logName = "DispLighter",
        uses = {
            defaultMin = 3,
            defaultMax = 11,
            maxUses = 12,
        },
    },
    {
        weight = 12,
        category = "fire",
        item = "Base.Matches",
        logName = "Matches",
        uses = {
            defaultMin = 5,
            defaultMax = 15,
            maxUses = 20,
        },
    },
    {
        weight = 5,
        category = "fire",
        item = "Base.Matchbox",
        logName = "Matchbox",
        uses = {
            defaultMin = 10,
            defaultMax = 45,
            maxUses = 50,
        },
    },
    {
        weight = 2,
        category = "rare",
        item = "Base.TobaccoChewing",
        logName = "ChewingTobacco",
        uses = {
            defaultMin = 4,
            defaultMax = 18,
            maxUses = 20,
        },
    },
    {
        weight = 1,
        category = "rare",
        item = "Base.Cigarillo",
        logName = "Cheroot",
    },
    {
        weight = 1,
        category = "rare",
        item = "Base.Cigar",
        logName = "Cigar",
    },
}

local function isEntryEnabled(entry)
    if entry.category == "fire" then
        return opt("EnableFireSources", true)
    end

    if entry.category == "rare" then
        return opt("EnableRareTobacco", true)
    end

    return true
end

local function pickLootEntry()
    local totalWeight = 0

    for i = 1, #LOOT do
        local entry = LOOT[i]
        if isEntryEnabled(entry) and entry.weight > 0 then
            totalWeight = totalWeight + entry.weight
        end
    end

    if totalWeight <= 0 then return nil end

    local roll = ZombRand(totalWeight)
    local cumulative = 0

    for i = 1, #LOOT do
        local entry = LOOT[i]
        if isEntryEnabled(entry) and entry.weight > 0 then
            cumulative = cumulative + entry.weight
            if roll < cumulative then
                return entry
            end
        end
    end

    return nil
end

local function zombiePosition(zombie)
    local square = zombie:getSquare()
    if square then
        return square:getX() .. "," .. square:getY()
    end

    return "unknown"
end

local function addLootToZombie(zombie)
    if not zombie then return end

    local modData = zombie:getModData()
    if modData and modData[PROCESSED_KEY] then return end
    if modData then
        modData[PROCESSED_KEY] = true
    end

    local inv = zombie:getInventory()
    if not inv then return end

    local globalChance = clamp(opt("GlobalChance", 16), 0, 100)
    if ZombRand(100) >= globalChance then return end

    local entry = pickLootEntry()
    if not entry then return end

    local item = inv:AddItem(entry.item)
    if not item then return end

    if opt("DebugLogging", false) then
        local log = "[ZombsHaveCigs] Loot added to zombie at " .. zombiePosition(zombie) .. " | " .. entry.logName
        local uses = applyUses(item, entry.uses)
        if uses then
            log = log .. "(" .. uses .. ")"
        end
        print(log)
    else
        applyUses(item, entry.uses)
    end
end

Events.OnZombieDead.Add(addLootToZombie)

print("[ZombsHaveCigs] Mod loaded for Build 42.19")
