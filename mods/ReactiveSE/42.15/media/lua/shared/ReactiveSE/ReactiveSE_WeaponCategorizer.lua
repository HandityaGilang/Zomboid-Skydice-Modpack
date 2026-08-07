--//////////////////////////////////////////////////--
--    Reactive Sound Events - Weapon Categorizer
--    Dynamic weapon categorization based on properties
--//////////////////////////////////////////////////--

local ReactiveSE_WeaponCategorizer = {}

--//////////////////////////////////////////////////--
--          Configuration                         --
--//////////////////////////////////////////////////--

--- Categorization thresholds and constants
local CRITERIA = {
    -- Assault Rifle detection
    AR_MAX_RANGE = 30,

    -- Service Pistol detection
    SERVICE_MIN_RANGE_HIGH = 15,
    SERVICE_MIN_RANGE_MID = 12,
    SERVICE_MAX_WEIGHT = 1.5,

    -- Animation types
    ANIM_RIFLE = "Rifle",
    ANIM_HANDGUN = "Handgun"
}

--//////////////////////////////////////////////////--
--          Internal Helpers                      --
--//////////////////////////////////////////////////--

---Categorize shotguns based on multi-hit capability
---@param item Item
---@return boolean
local function isShotgun(item)
    local maxHitCount = item:getMaxHitCount()
    return maxHitCount and maxHitCount > 2
end

---Categorize assault rifles based on weight and range
---@param item Item
---@return boolean
local function isAssaultRifle(item)
    local swingAnim = item:getSwingAnim()
    if swingAnim ~= CRITERIA.ANIM_RIFLE then return false end

    local maxHitCount = item:getMaxHitCount()
    if maxHitCount > 2 then return false end

    local range = item:getMaxRange()

    -- Light rifles OR short-range rifles (carbines)
    if range <= CRITERIA.AR_MAX_RANGE then return true end

    return false
end

---Categorize service pistols based on range and weight
---@param item Item
---@return boolean
local function isServicePistol(item)
    local swingAnim = item:getSwingAnim()
    if swingAnim ~= CRITERIA.ANIM_HANDGUN then return false end

    local range = item:getMaxRange()
    local weight = item:getActualWeight()

    -- High-power sidearms (Magnum, Deagle, M9)
    if range >= CRITERIA.SERVICE_MIN_RANGE_HIGH then return true end

    -- Standard service pistols (M1911, Glock)
    if range > CRITERIA.SERVICE_MIN_RANGE_MID and weight < CRITERIA.SERVICE_MAX_WEIGHT then
        return true
    end

    return false
end

---Determine fallback category for rifles
---@param item Item
---@return boolean
local function isCivRifle(item)
    local swingAnim = item:getSwingAnim()
    return swingAnim == CRITERIA.ANIM_RIFLE
end

---Determine fallback category for pistols
---@param item Item
---@return boolean
local function isCivPistol(item)
    local swingAnim = item:getSwingAnim()
    return swingAnim == CRITERIA.ANIM_HANDGUN
end

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Categorize a weapon into appropriate pool category
---Evaluation order: Shotgun → Assault Rifle → Service Pistol → Civ Rifle → Civ Pistol
---@param item Item
---@return string|nil category Pool category key or nil if uncategorizable
function ReactiveSE_WeaponCategorizer.Categorize(item)
    -- Evaluate in priority order
    if isShotgun(item) then
        return "SHOTGUN_CIV"
    end

    if isAssaultRifle(item) then
        return "ASSAULT_RIFLE"
    end

    if isServicePistol(item) then
        return "SERVICE_PISTOL"
    end

    if isCivRifle(item) then
        return "RIFLE_CIV"
    end

    if isCivPistol(item) then
        return "CIV_PISTOL"
    end

    return nil
end

---Get debug info for an item (for logging uncategorized weapons)
---@param item Item
---@return table debugInfo
function ReactiveSE_WeaponCategorizer.GetDebugInfo(item)
    if not item then return {} end

    local instance = instanceItem(item)
    return {
        fullType = instance:getFullType(),
        swingAnim = item:getSwingAnim(),
        maxRange = item:getMaxRange(),
        weight = item:getActualWeight(),
        maxHitCount = item:getMaxHitCount(),
        isRanged = item:isRanged(),
        displayCategory = item:getDisplayCategory()
    }
end

return ReactiveSE_WeaponCategorizer
