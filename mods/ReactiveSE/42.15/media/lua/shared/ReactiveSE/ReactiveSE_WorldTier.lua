--//////////////////////////////////////////////////--
--    Reactive Sound Events - World Tier
--    Time progression system for the world
--//////////////////////////////////////////////////--

local Config = require "ReactiveSE/ReactiveSE_Config"

local ReactiveSE_WorldTier = {}

-- Modifiers by tier
local TIER_MODIFIERS = {
    EARLY = {
        weaponConditionMod = 0.8,
        ammoMultiplier = 0.5,
        lootQualityMod = 0.7,
        armorChance = 0,
        rareWeaponChance = 0.1
    },
    MID = {
        weaponConditionMod = 0.6,
        ammoMultiplier = 0.8,
        lootQualityMod = 1.0,
        armorChance = 0.05,
        rareWeaponChance = 0.25
    },
    LATE = {
        weaponConditionMod = 0.4,
        ammoMultiplier = 1.2,
        lootQualityMod = 1.3,
        armorChance = 0.15,
        rareWeaponChance = 0.4
    },
    END = {
        weaponConditionMod = 0.2,
        ammoMultiplier = 1.5,
        lootQualityMod = 1.6,
        armorChance = 0.3,
        rareWeaponChance = 0.6
    }
}

---Determines the world 'tier' based on loot quality or time
---@return string "EARLY", "MID", "LATE", "END"
function ReactiveSE_WorldTier.GetWorldTier()
    local config = Config.Get().worldTier

    -- Default Dynamic (Time-based)
    local gameTime = getGameTime()
    local daysSurvived = gameTime:getNightsSurvived()
    local earlyEnd = config.worldTierEarlyEnd
    local midEnd = config.worldTierMidEnd
    local lateEnd = config.worldTierLateEnd

    if daysSurvived < earlyEnd then
        return "EARLY"
    elseif daysSurvived < midEnd then
        return "MID"
    elseif daysSurvived < lateEnd then
        return "LATE"
    else
        return "END"
    end
end

---Returns the next tier up, or the same if at Max
---@param currentTier string
---@return string
function ReactiveSE_WorldTier.GetNextTier(currentTier)
    if currentTier == "EARLY" then return "MID" end
    if currentTier == "MID" then return "LATE" end
    return "END"
end

---Returns the previous tier down, or the same if at Min
---@param currentTier string
---@return string
function ReactiveSE_WorldTier.GetPrevTier(currentTier)
    if currentTier == "END" then return "LATE" end
    if currentTier == "LATE" then return "MID" end
    return "EARLY"
end

---Gets modifiers for the current tier
---@param tierName string|nil Optional, if not passed uses current
---@return table
function ReactiveSE_WorldTier.GetModifiers(tierName)
    local tier = tierName or ReactiveSE_WorldTier.GetWorldTier()
    return TIER_MODIFIERS[tier] or TIER_MODIFIERS.EARLY
end

return ReactiveSE_WorldTier
