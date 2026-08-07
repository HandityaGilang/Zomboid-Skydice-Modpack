--//////////////////////////////////////////////////--
--    Reactive Sound Events - Loot Simulation
--    Determines what items were stolen by the victor
--//////////////////////////////////////////////////--

local Utils = require "ReactiveSE/ReactiveSE_Utils"
local WorldTier = require "ReactiveSE/ReactiveSE_WorldTier"
local BaseKits = require "ReactiveSE/ReactiveSE_BaseKits"
local SubKits = require "ReactiveSE/ReactiveSE_SubKits"

local ReactiveSE_LootSimulation = {}

--//////////////////////////////////////////////////--
--          Loot Quality Resolution               --
--//////////////////////////////////////////////////--

-- Max number of items the winner can steal per corpse
local LOOT_CAP = 3

-- Base probability that a winner wants an item of a specific category, by WorldTier
local CATEGORY_DESIRES = {
    EARLY = {
        Food = 0.8, Water = 0.8, MeleeWeapon = 0.8, Medicine = 0.5, Tools = 0.4, Vice = 0.3
    },
    MID = {
        Food = 0.6, Water = 0.6, MeleeWeapon = 0.6, Medicine = 0.7, Tools = 0.6, Vice = 0.5
    },
    LATE = {
        Food = 0.4, Water = 0.4, MeleeWeapon = 0.6, Medicine = 0.7, Tools = 0.5, Vice = 0.7
    },
    END = {
        Food = 0.3, Water = 0.3, MeleeWeapon = 0.5, Medicine = 0.8, Tools = 0.4, Vice = 0.8
    }
}

-- Dynamic LootQuality is derived from WorldTier
local DYNAMIC_STANDARDS_BY_TIER = {
    EARLY = 0.20, -- Desperate looting
    MID   = 0.30, -- Opportunistic
    LATE  = 0.45, -- Selective
    END   = 0.60, -- Elite standards
}

---Resolves dynamic loot standards based on world tier
---@param worldTier string
---@return number
local function resolveDynamicStandards(worldTier)
    return DYNAMIC_STANDARDS_BY_TIER[worldTier] or 0.35
end

-- LootQuality enum:
-- 1 = Dynamic
-- 2 = Low
-- 3 = Normal
-- 4 = High

---Gets the winner's quality standards based on loot quality setting
---@param lootQuality number
---@param worldTier string
---@return number
local function getWinnerStandards(lootQuality, worldTier)
    if lootQuality == 1 then
        return resolveDynamicStandards(worldTier)
    elseif lootQuality == 2 then
        return 0.20
    elseif lootQuality == 3 then
        return 0.40
    elseif lootQuality == 4 then
        return 0.60
    end

    return 0.35
end

--//////////////////////////////////////////////////--
--          Internal Helpers                      --
--//////////////////////////////////////////////////--

---Calculates the virtual condition of an item based on world tier and settings
---@param tierMod number WorldTier modifier for weapon condition
---@param maxConditionSetting number Sandbox setting for max condition
---@return number condition (0.0 to 1.0)
local function calculateVirtualCondition(tierMod, maxConditionSetting)
    local maxCap = maxConditionSetting / 100
    local effectiveMax = maxCap * tierMod
    return ZombRandFloat(0.1, effectiveMax)
end

---Determines if an item is desirable to the victor
---@param itemType string
---@param baseDesire number|nil Explicit base desire override (0.0-1.0)
---@param worldTier string
---@return boolean isDesirable
local function checkDesirability(itemType, baseDesire, worldTier)
    if not itemType then return false end

    local chance = 0.35 -- Fallback default

    if baseDesire then
        chance = baseDesire
    else
        -- Resolve by category
        local cat = SubKits.GetCategory(itemType)
        if cat and CATEGORY_DESIRES[worldTier] and CATEGORY_DESIRES[worldTier][cat] then
            chance = CATEGORY_DESIRES[worldTier][cat]
        end
    end

    return ZombRand(100) < (chance * 100)
end

---Determines if an item meets the winner's quality standards
---@param isFirearm boolean
---@param virtualCondition number
---@param winnerStandards number
---@return boolean accepts
local function checkQualityStandards(isFirearm, virtualCondition, winnerStandards)
    if isFirearm and virtualCondition < winnerStandards then
        return false
    end
    return true
end

---Consolidated check: Is this item taken?
---@param itemType string
---@param baseDesire number|nil
---@param isFirearm boolean
---@param context table "settings, tierMod, winnerStandars, worldTier, itemsStolen"
---@return boolean taken
local function isItemTaken(itemType, baseDesire, isFirearm, context)
    if not itemType then return false end

    if context.itemsStolen >= LOOT_CAP then
        return false
    end

    local virtualCondition = calculateVirtualCondition(
        context.tierMod,
        context.settings.weaponMaxCondition
    )

    if not checkQualityStandards(isFirearm, virtualCondition, context.winnerStandards) then
        return false
    end

    local stealMod = context.settings.stealChanceMod or 1.0

    if not checkDesirability(itemType, baseDesire, context.worldTier) then
        return false
    end

    if stealMod < 1.0 then
        if ZombRandFloat(0, 1) > stealMod then
            return false
        end
    end

    return true
end

--//////////////////////////////////////////////////--
--          Public API                            --
--//////////////////////////////////////////////////--

---Simulates the looting of the loser by the winner. Modifies the virtualKit in place by removing items that were taken.
---@param virtualKit table The generated virtual kit
---@param settings table Sandbox settings (lootQuality, weaponMaxCondition)
function ReactiveSE_LootSimulation.Simulate(virtualKit, settings)
    local worldTier = WorldTier.GetWorldTier()
    local mod = WorldTier.GetModifiers(worldTier)

    local standards = getWinnerStandards(settings.lootQuality, worldTier)
    local context = {
        settings = settings,
        tierMod = mod.weaponConditionMod or 1.0,
        winnerStandards = standards,
        worldTier = worldTier,
        itemsStolen = 0
    }

    Utils.LogInfo("  [LootSim] Standards: " ..
        standards .. " (Tier: " .. worldTier .. ", Mod: " .. context.tierMod .. ")")

    -- 0. Backpack
    if virtualKit.backpack then
        local maxChance = settings.maxBackpackStealChance or 80
        local minChance = settings.minBackpackStealChance or 10

        local ratio = (standards - 0.2) / 0.4

        ratio = ratio < 0 and 0 or (ratio > 1 and 1 or ratio)

        local backpackStealChance = maxChance - (ratio * (maxChance - minChance))

        if ZombRand(100) < backpackStealChance then
            Utils.LogInfo(string.format("    > Backpack (%s) STOLEN. (Chance: %.1f%%)", virtualKit.backpack,
                backpackStealChance))
            virtualKit.backpack = nil
            context.itemsStolen = 1
        else
            Utils.LogInfo(string.format("    > Backpack (%s) LEFT. (Chance: %.1f%%)", virtualKit.backpack,
                backpackStealChance))
        end
    end

    -- 1. Primary Weapon
    if virtualKit.primaryWeapon then
        local baseDesire = 0.6
        local isFirearm = true

        if virtualKit.primaryCategory and not BaseKits.IsRangedCategory(virtualKit.primaryCategory) then
            baseDesire = 0.3
            isFirearm = false
        end

        if isItemTaken(virtualKit.primaryWeapon, baseDesire, isFirearm, context) then
            Utils.LogInfo("    > Primary (" .. virtualKit.primaryWeapon .. ") STOLEN by victor.")
            virtualKit.primaryWeapon = nil
            context.itemsStolen = context.itemsStolen + 1
        else
            Utils.LogInfo("    > Primary (" .. virtualKit.primaryWeapon .. ") LEFT on corpse.")
        end
    end

    -- 2. Sidearm
    if virtualKit.sidearm then
        local baseDesire = 0.5
        local isFirearm = true

        if virtualKit.sidearmCategory and not BaseKits.IsRangedCategory(virtualKit.sidearmCategory) then
            baseDesire = 0.2
            isFirearm = false
        end

        if isItemTaken(virtualKit.sidearm, baseDesire, isFirearm, context) then
            Utils.LogInfo("    > Sidearm (" .. virtualKit.sidearm .. ") STOLEN by victor.")
            virtualKit.sidearm = nil
            context.itemsStolen = context.itemsStolen + 1
        else
            Utils.LogInfo("    > Sidearm (" .. virtualKit.sidearm .. ") LEFT on corpse.")
        end
    end

    -- 3. SubKit Items
    local remainingItems = {}
    for i = 1, #virtualKit.subKitItems do
        local item = virtualKit.subKitItems[i]
        if isItemTaken(item, nil, false, context) then
            Utils.LogInfo("    > Item (" .. item .. ") STOLEN by victor.")
            context.itemsStolen = context.itemsStolen + 1
        else
            table.insert(remainingItems, item)
        end
    end
    virtualKit.subKitItems = remainingItems

    if context.itemsStolen > 0 then
        Utils.LogInfo("  [LootSim] Total items stolen: " .. context.itemsStolen .. "/" .. LOOT_CAP)
    end
end

return ReactiveSE_LootSimulation
