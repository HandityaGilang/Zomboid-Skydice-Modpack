--//////////////////////////////////////////////////--
--    Reactive Sound Events - Outfit System 2.0
--    Refactored Data-Driven Architecture
--//////////////////////////////////////////////////--

local Utils = require "ReactiveSE/ReactiveSE_Utils"
local OutfitData = require "ReactiveSE/ReactiveSE_OutfitData"

local ReactiveSE_Outfits = {}

--//////////////////////////////////////////////////--
--    Outfit Pool
--//////////////////////////////////////////////////--

local OUTFITS = OutfitData.OUTFITS
local MALE_ONLY_OUTFITS = OutfitData.MALE_ONLY_OUTFITS
local TIER_CONFIG = OutfitData.TIER_CONFIG
local SUBTIER_WEIGHTS = OutfitData.SUBTIER_WEIGHTS

--//////////////////////////////////////////////////--
--   Outfit Selection Logic
--//////////////////////////////////////////////////--

---Selects a key from a weighted table
---@param weightTable table<string, number>
---@return string|nil selectedKey
---@return number roll
local function selectByWeight(weightTable)
    if not weightTable then return nil, 0 end

    local totalWeight = 0
    for _, weight in pairs(weightTable) do
        totalWeight = totalWeight + weight
    end

    if totalWeight <= 0 then return nil, 0 end

    local roll = ZombRand(1, totalWeight + 1)
    Utils.LogInfo(string.format("  [WeightSystem] TotalWeight=%d Roll=%d", totalWeight, roll))
    local current = 0

    for key, weight in pairs(weightTable) do
        current = current + weight
        if roll <= current then
            return key, roll
        end
    end

    return nil, roll
end

---Checks if an outfit is restricted for females
---@param outfitName string
---@param isFemale boolean
---@return boolean
local function isValidGender(outfitName, isFemale)
    if not isFemale then return true end

    for i = 1, #MALE_ONLY_OUTFITS do
        local maleOutfit = MALE_ONLY_OUTFITS[i]
        if outfitName == maleOutfit then
            return false
        end
    end
    return true
end

---Main selection function
---@param tier string "EARLY"|"MID"|"LATE"|"END"
---@param isFemale boolean
---@param categoryFilter string|nil Optional: specific category to force
---@param subTierFilter string|nil Optional: specific subTier to force
---@return string outfitName
---@return string category
---@return string subTier
function ReactiveSE_Outfits.SelectOutfit(tier, isFemale, categoryFilter, subTierFilter)
    local tierData = TIER_CONFIG[tier] or TIER_CONFIG.EARLY

    -- 1. Select Category
    local categoryKey
    local catRoll = 0

    if categoryFilter and OUTFITS[categoryFilter] then
        categoryKey = categoryFilter
        catRoll = -1 -- Forced
    else
        categoryKey, catRoll = selectByWeight(tierData.CategoryWeights)
    end

    if not categoryKey then
        categoryKey = "SURVIVOR" -- Absolute fallback
    end

    Utils.LogInfo(string.format("[Outfits] Tier=%s Roll=%d -> Category=%s", tier, catRoll, categoryKey))

    -- 2. Select Sub-Tier (Strict Tiering)
    local categoryWeights = SUBTIER_WEIGHTS[categoryKey] or SUBTIER_WEIGHTS.SURVIVOR
    local tierSubWeights = categoryWeights[tier] or categoryWeights.EARLY

    local subTierKey
    local subRoll = 0

    if subTierFilter then
        subTierKey = subTierFilter
        subRoll = -1
    else
        subTierKey, subRoll = selectByWeight(tierSubWeights)
    end

    -- Fallback if selection failed (e.g. weights sum to 0 or config error)
    if not subTierKey then
        for k, w in pairs(tierSubWeights) do
            if w > 0 then
                subTierKey = k
                break
            end
        end
    end

    -- Absolute fallback
    if not subTierKey then
        for k, _ in pairs(OUTFITS[categoryKey] or {}) do
            subTierKey = k
            break
        end
    end

    Utils.LogInfo(string.format("  -> Category=%s Roll=%d -> SubTier=%s", categoryKey, subRoll, tostring(subTierKey)))

    -- 3. Build Candidate Pool
    local categoryPools = OUTFITS[categoryKey]
    if not categoryPools then
        Utils.LogWarning("[Outfits] Missing pools for category: " .. tostring(categoryKey))
        return "Survivalist", "SURVIVOR", "LOW" -- Emergency exit
    end

    local rawPool = categoryPools[subTierKey]
    local candidatePool = {}

    if rawPool then
        for i = 1, #rawPool do
            local outfit = rawPool[i]
            if isValidGender(outfit, isFemale) then
                table.insert(candidatePool, outfit)
            end
        end
    end

    Utils.LogInfo(string.format("  -> Candidate Pool Size: %d", #candidatePool))

    -- 4. Final Selection & Fallback
    if #candidatePool == 0 then
        Utils.LogWarning(string.format("[Outfits] Empty pool for %s-%s (Female=%s). Using Fallback.",
            categoryKey, tostring(subTierKey), tostring(isFemale)))

        -- Fallback: Use Survivalist (Base)
        return "Survivalist", "SURVIVOR", "LOW"
    end

    local selected = candidatePool[ZombRand(#candidatePool) + 1]
    Utils.LogInfo(string.format("  -> Selected Outline: %s", selected))

    return selected, categoryKey, subTierKey
end

return ReactiveSE_Outfits
