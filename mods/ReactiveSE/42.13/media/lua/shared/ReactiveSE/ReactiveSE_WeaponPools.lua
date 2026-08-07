--//////////////////////////////////////////////////--
--    Reactive Sound Events - Weapon Pools
--    Storage and access API for weapon pools
--//////////////////////////////////////////////////--

local Utils = require "ReactiveSE/ReactiveSE_Utils"
local WeaponCategorizer = require "ReactiveSE/ReactiveSE_WeaponCategorizer"

local ReactiveSE_WeaponPools = {}

--//////////////////////////////////////////////////--
--          Configuration                         --
--//////////////////////////////////////////////////--

---Melee weapon pools (hardcoded)
---@type table<string, string[]>
local MELEE_POOLS = {
    SMALL_MELEE_IMPROVISED = {
        "Base.Screwdriver", "Base.Screwdriver_Old", "Base.Screwdriver_Improvised",
        "Base.GlassShiv", "Base.Toothbrush_Shiv", "Base.KnifeShiv",
        "Base.FlintKnife", "Base.StoneKnifeLong"
    },

    SMALL_MELEE_PROPER = {
        "Base.KnifePocket", "Base.SmallKnife", "Base.CrudeKnife",
        "Base.File", "Base.SwitchKnife", "Base.ButterflyKnife", "Base.Nightstick"
    },

    MID_MELEE = {
        "Base.HuntingKnife", "Base.HuntingKnifeForged", "Base.FightingKnife",
        "Base.HandguardDagger", "Base.RailroadSpikeKnife", "Base.LongCrudeKnife",
        "Base.ShortSword", "Base.ShortSword_Crude"
    },

    LARGE_MELEE_IMPROVISED = {
        -- Blunt
        "Base.BaseballBat_Nails", "Base.BaseballBat_Spiked", "Base.BaseballBat_Sawblade",
        "Base.Cudgel_Nails", "Base.Cudgel_Railspike", "Base.LongMace", "Base.LongMace_Stone",
        "Base.Mace", "Base.Mace_Stone", "Base.ScrapMaul",
        -- Blade
        "Base.CrudeSword", "Base.Sword", "Base.Sword_Scrap", "Base.Machete_Crude", "Base.MeatCleaver_Scrap"
    },

    LARGE_MELEE_TOOLS = {
        "Base.Axe_Old", "Base.Axe", "Base.Axe_Sawblade", "Base.Axe_ScrapCleaver",
        "Base.WoodAxe", "Base.WoodAxeForged", "Base.IceAxe",
        "Base.PickAxe", "Base.PickAxeForged",
        "Base.Crowbar", "Base.CrowbarForged"
    },

    SPEARS = {
        "Base.SpearCrafted", "Base.SpearLong", "Base.SpearShort",
        "Base.SpearStone", "Base.SpearGlass", "Base.SpearFightingKnife",
        "Base.SpearHuntingKnife", "Base.SpearKnife", "Base.SpearKnifeSmall",
        "Base.SpearScrapKnife", "Base.SpearScissors", "Base.SpearSteakKnife"
    }
}

---Firearm pools (dynamically populated)
---@type table<string, string[]>
local FIREARM_POOLS = {
    CIV_PISTOL = {},
    SERVICE_PISTOL = {},
    SHOTGUN_CIV = {},
    RIFLE_CIV = {},
    ASSAULT_RIFLE = {}
}

---Fallback pools)
---@type table<string, string[]>
local FIREARM_FALLBACKS = {
    CIV_PISTOL = {
        "Base.Pistol", "Base.Pistol2", "Base.Pistol3",
        "Base.Revolver_Short", "Base.Revolver", "Base.Revolver_Long"
    },
    SERVICE_PISTOL = {
        "Base.Pistol2", "Base.Pistol3"
    },
    SHOTGUN_CIV = {
        "Base.DoubleBarrelShotgun", "Base.DoubleBarrelShotgunSawnoff",
        "Base.Shotgun", "Base.ShotgunSawnoff"
    },
    RIFLE_CIV = {
        "Base.VarmintRifle", "Base.HuntingRifle"
    },
    ASSAULT_RIFLE = {
        "Base.AssaultRifle", "Base.AssaultRifle2"
    }
}

--- Initialization state
local isInitialized = false

--//////////////////////////////////////////////////--
--          Internal Helpers                      --
--//////////////////////////////////////////////////--

---Add weapon to specified pool if not already present
---@param pool string[] Target pool array
---@param weaponType string Full item type
local function addToPool(pool, weaponType)
    if not pool or not weaponType then return end

    -- Avoid duplicates
    for i = 1, #pool do
        if pool[i] == weaponType then
            return
        end
    end

    table.insert(pool, weaponType)
end

---Apply fallback to a category if its pool is empty
---@param category string Category name
local function applyFallbackIfEmpty(category)
    local pool = FIREARM_POOLS[category]
    local fallback = FIREARM_FALLBACKS[category]

    if pool and fallback and #pool == 0 then
        Utils.LogInfo(string.format("[WeaponPools] Category %s is empty, using fallback (%d weapons)", category,
            #fallback))
        FIREARM_POOLS[category] = fallback
    end
end

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Initialize dynamic firearm pools by scanning all game items
function ReactiveSE_WeaponPools.InitializeDynamicPools()
    if isInitialized then
        Utils.LogInfo("[WeaponPools] Dynamic pools already initialized, skipping")
        return
    end

    Utils.LogInfo("[WeaponPools] Initializing dynamic weapon pools...")

    local allItems = getScriptManager():getAllItems()
    if not allItems then
        Utils.LogWarning("[WeaponPools] ERROR: Could not retrieve item list from script manager")
        return
    end

    local stats = {
        total = 0,
        scanned = 0,
        CIV_PISTOL = 0,
        SERVICE_PISTOL = 0,
        SHOTGUN_CIV = 0,
        RIFLE_CIV = 0,
        ASSAULT_RIFLE = 0
    }

    -- Scan all items
    for i = allItems:size() - 1, 0, -1 do
        local item = allItems:get(i)
        stats.scanned = stats.scanned + 1

        local isRanged = item:isRanged()
        local displayCategory = item:getDisplayCategory()
        if isRanged and displayCategory == "Weapon" then
            local category = WeaponCategorizer.Categorize(item)
            if category then
                local pool = FIREARM_POOLS[category]
                if pool then
                    local instance = instanceItem(item)
                    local instanceName = instance:getFullType()
                    if instanceName then
                        addToPool(pool, instanceName)
                        stats[category] = stats[category] + 1
                        stats.total = stats.total + 1
                    end
                end
            end
        end
    end

    isInitialized = true

    applyFallbackIfEmpty("CIV_PISTOL")
    applyFallbackIfEmpty("SERVICE_PISTOL")
    applyFallbackIfEmpty("SHOTGUN_CIV")
    applyFallbackIfEmpty("RIFLE_CIV")
    applyFallbackIfEmpty("ASSAULT_RIFLE")

    Utils.LogInfo(string.format("[WeaponPools] Scanned %d total items", stats.scanned))
end

---Get a random weapon from specified category
---@param category string Pool category key
---@return string|nil weaponType Full item type or nil if pool empty
function ReactiveSE_WeaponPools.GetWeapon(category)
    if not category then return nil end

    -- Check firearm pools first
    local pool = FIREARM_POOLS[category]

    -- Fall back to melee pools
    if not pool then
        pool = MELEE_POOLS[category]
    end

    if not pool or #pool == 0 then
        return nil
    end

    return pool[ZombRand(#pool) + 1]
end

---Get all weapons from specified category
---@param category string Pool category key
---@return string[]|nil Array of weapon types or nil if pool doesn't exist
function ReactiveSE_WeaponPools.GetPool(category)
    if not category then return nil end

    local pool = FIREARM_POOLS[category] or MELEE_POOLS[category]
    return pool
end

---Check if dynamic pools have been initialized
---@return boolean
function ReactiveSE_WeaponPools.IsInitialized()
    return isInitialized
end

return ReactiveSE_WeaponPools
