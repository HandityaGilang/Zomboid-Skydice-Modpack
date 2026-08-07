--//////////////////////////////////////////////////--
--    Reactive Sound Events - Base Kits
--    Base kits for each archetype
--//////////////////////////////////////////////////--

local Utils = require "ReactiveSE/ReactiveSE_Utils"
local WeaponPools = require "ReactiveSE/ReactiveSE_WeaponPools"

local ReactiveSE_BaseKits = {}

-- Base kits definitions. Keys MUST match the Categories in ReactiveSE_Outfits.lua
local BASE_KITS = {
    -- 1. CIVILIAN (Ordinary people)
    CIVILIAN = {
        { name = "Unarmed",  weight = 40, meleeWeapon = nil,                      rangedWeapon = "CIV_PISTOL", backpack = nil,      extra = "UTILITY_WALKIETALKIE" },
        { name = "Worker",   weight = 30, meleeWeapon = "SMALL_MELEE_IMPROVISED", rangedWeapon = "CIV_PISTOL", backpack = "SMALL",  extra = "TOOLS_LIGHT" },
        { name = "Armed",    weight = 20, meleeWeapon = "SMALL_MELEE_PROPER",     rangedWeapon = "CIV_PISTOL", backpack = "SMALL",  extra = "VICE_LIGHT",          tiers = { "MID", "LATE" } },
        { name = "Prepared", weight = 10, meleeWeapon = "MID_MELEE",              rangedWeapon = "CIV_PISTOL", backpack = "MEDIUM", extra = "UTILITY_FLASHLIGHT",  tiers = { "LATE", "END" } }
    },

    -- 2. SURVIVOR (Prepared individuals)
    SURVIVOR = {
        { name = "Scavenger", weight = 30, meleeWeapon = "LARGE_MELEE_IMPROVISED", rangedWeapon = "CIV_PISTOL",  sidearm = "SMALL_MELEE_IMPROVISED", backpack = "SMALL",  extra = "TOOLS_LIGHT",         tiers = { "EARLY", "MID", "LATE" } },
        { name = "Hunter",    weight = 20, meleeWeapon = "MID_MELEE",              rangedWeapon = "RIFLE_CIV",   sidearm = "MID_MELEE",              backpack = "MEDIUM", extra = "UTILITY_FLASHLIGHT",  tiers = { "MID", "LATE", "END" } },
        { name = "Medic",     weight = 10, meleeWeapon = "SMALL_MELEE_PROPER",     rangedWeapon = "CIV_PISTOL",  sidearm = "SMALL_MELEE_PROPER",     backpack = "MEDIUM", extra = "MEDICAL_FULL",        tiers = { "EARLY", "MID", "LATE" } },
        { name = "Nomad",     weight = 20, meleeWeapon = "SPEARS",                 rangedWeapon = "SHOTGUN_CIV", sidearm = "SMALL_MELEE_PROPER",     backpack = "LARGE",  extra = "TOOLS_HEAVY",         tiers = { "MID", "LATE", "END" } },
        { name = "Defender",  weight = 10, meleeWeapon = "LARGE_MELEE_IMPROVISED", rangedWeapon = "SHOTGUN_CIV", sidearm = "MID_MELEE",              backpack = "MEDIUM", extra = "UTILITY_FIRECRACKER", tiers = { "MID", "LATE", "END" } },
        { name = "Veteran",   weight = 10, meleeWeapon = "MID_MELEE",              rangedWeapon = "RIFLE_CIV",   sidearm = "SERVICE_PISTOL",         backpack = "LARGE",  extra = "ARMOR_MEDIUM",        tiers = { "LATE", "END" } }
    },

    -- 3. BANDIT (Hostile humans)
    BANDIT = {
        { name = "Pickpocket", weight = 20, meleeWeapon = "SMALL_MELEE_PROPER",     rangedWeapon = "CIV_PISTOL",  sidearm = nil,                      backpack = nil,      extra = "VICE_LIGHT",         tiers = { "EARLY", "MID" } },
        { name = "Mugger",     weight = 25, meleeWeapon = "LARGE_MELEE_IMPROVISED", rangedWeapon = "CIV_PISTOL",  sidearm = "SMALL_MELEE_IMPROVISED", backpack = nil,      extra = "UTILITY_FLASHLIGHT", tiers = { "EARLY", "MID", "LATE" } },
        { name = "Thug",       weight = 25, meleeWeapon = "SMALL_MELEE_PROPER",     rangedWeapon = "CIV_PISTOL",  sidearm = "SMALL_MELEE_PROPER",     backpack = "SMALL",  extra = "VICE_HEAVY",         tiers = { "MID", "LATE" } },
        { name = "Raider",     weight = 15, meleeWeapon = "MID_MELEE",              rangedWeapon = "SHOTGUN_CIV", sidearm = "MID_MELEE",              backpack = "MEDIUM", extra = "ARMOR_LIGHT",        tiers = { "MID", "LATE", "END" } },
        { name = "Enforcer",   weight = 10, meleeWeapon = "LARGE_MELEE_TOOLS",      rangedWeapon = "SHOTGUN_CIV", sidearm = "CIV_PISTOL",             backpack = "MEDIUM", extra = "ARMOR_MEDIUM",       tiers = { "LATE", "END" } },
        { name = "Warlord",    weight = 5,  meleeWeapon = "MID_MELEE",              rangedWeapon = "RIFLE_CIV",   sidearm = "MID_MELEE",              backpack = "LARGE",  extra = "ARMOR_HEAVY",        tiers = { "END" } }
    },

    -- 4. AUTHORITY (Police, Fire, Ranger)
    AUTHORITY = {
        { name = "Patrol Officer",  weight = 30, meleeWeapon = "MID_MELEE",          rangedWeapon = "SERVICE_PISTOL", sidearm = "SMALL_MELEE_PROPER", backpack = nil,      extra = "UTILITY_RADIO", tiers = { "EARLY", "MID" } },
        { name = "Dispatcher",      weight = 20, meleeWeapon = "SMALL_MELEE_PROPER", rangedWeapon = "CIV_PISTOL",     sidearm = nil,                  backpack = nil,      extra = "MEDICAL_BASIC", tiers = { "EARLY" } },
        { name = "Riot Control",    weight = 20, meleeWeapon = "MID_MELEE",          rangedWeapon = "SHOTGUN_CIV",    sidearm = "SMALL_MELEE_PROPER", backpack = "SMALL",  extra = "ARMOR_MEDIUM",  tiers = { "MID", "LATE", "END" } },
        { name = "SWAT Light",      weight = 10, meleeWeapon = "MID_MELEE",          rangedWeapon = "SERVICE_PISTOL", sidearm = "MID_MELEE",          backpack = "MEDIUM", extra = "ARMOR_MEDIUM",  tiers = { "MID", "LATE" } },
        { name = "SWAT Heavy",      weight = 10, meleeWeapon = "MID_MELEE",          rangedWeapon = "ASSAULT_RIFLE",  sidearm = "MID_MELEE",          backpack = "LARGE",  extra = "ARMOR_HEAVY",   tiers = { "LATE", "END" } },
        { name = "Field Commander", weight = 10, meleeWeapon = "MID_MELEE",          rangedWeapon = "ASSAULT_RIFLE",  sidearm = "MID_MELEE",          backpack = "LARGE",  extra = "UTILITY_RADIO", tiers = { "LATE", "END" } }
    },

    -- 5. MILITARY (Professional soldiers)
    MILITARY = {
        { name = "Reservist",      weight = 30, meleeWeapon = "SMALL_MELEE_PROPER", rangedWeapon = "RIFLE_CIV",      sidearm = "SMALL_MELEE_PROPER", backpack = "MEDIUM",   extra = "TOOLS_LIGHT",  tiers = { "EARLY", "MID" } },
        { name = "Rifleman",       weight = 20, meleeWeapon = "MID_MELEE",          rangedWeapon = "ASSAULT_RIFLE",  sidearm = "MID_MELEE",          backpack = "LARGE",    extra = "ARMOR_MEDIUM", tiers = { "LATE", "END" } },
        { name = "Breacher",       weight = 15, meleeWeapon = "LARGE_MELEE_TOOLS",  rangedWeapon = "SHOTGUN_CIV",    sidearm = "LARGE_MELEE_TOOLS",  backpack = "MILITARY", extra = "ARMOR_HEAVY",  tiers = { "MID", "LATE", "END" } },
        { name = "Medic",          weight = 15, meleeWeapon = "SMALL_MELEE_PROPER", rangedWeapon = "SERVICE_PISTOL", sidearm = "SMALL_MELEE_PROPER", backpack = "MILITARY", extra = "MEDICAL_FULL", tiers = { "MID", "LATE" } },
        { name = "Heavy Infantry", weight = 10, meleeWeapon = "MID_MELEE",          rangedWeapon = "ASSAULT_RIFLE",  sidearm = "MID_MELEE",          backpack = "MILITARY", extra = "ARMOR_HEAVY",  tiers = { "LATE", "END" } },
        { name = "Elite Operator", weight = 10, meleeWeapon = "MID_MELEE",          rangedWeapon = "ASSAULT_RIFLE",  sidearm = "MID_MELEE",          backpack = "MILITARY", extra = "ARMOR_HEAVY",  tiers = { "END" } }
    }
}

-- Backpack pools
local BACKPACK_POOLS = {
    SMALL = {
        EARLY = { "Base.Bag_Satchel", "Base.Bag_Satchel_Leather", "Base.Bag_Satchel_Medical", "Base.Bag_Satchel", "Base.Bag_Satchel_Military", "Base.Bag_Schoolbag" },
        MID = { "Base.Bag_Schoolbag", "Base.Bag_DuffelBag" },
        LATE = { "Base.Bag_DuffelBag", "Bag_NormalHikingBag" },
        END = { "Bag_NormalHikingBag" }
    },
    MEDIUM = {
        EARLY = { "Base.Bag_DuffelBag" },
        MID = { "Base.Bag_DuffelBag" },
        LATE = { "Base.Bag_NormalHikingBag", "Base.Bag_BigHikingBag" },
        END = { "Base.Bag_BigHikingBag" }
    },
    LARGE = {
        EARLY = { "Base.Bag_NormalHikingBag" },
        MID = { "Base.Bag_NormalHikingBag" },
        LATE = { "Base.Bag_BigHikingBag", "Base.Bag_ALICEpack" },
        END = { "Base.Bag_ALICEpack" }
    },
    MILITARY = {
        EARLY = { "Base.Bag_Military" },
        MID = { "Base.Bag_ALICEpack_Army", "Base.Bag_ALICEpack_DesertCamo" },
        LATE = { "Base.Bag_ALICEpack_Army", "Base.Bag_ALICEpack_DesertCamo" },
        END = { "Base.Bag_ALICEpack_Army", "Base.Bag_ALICEpack_DesertCamo" }
    }
}

---Selects a base kit
---@param category string The main archetype category ("CIVILIAN", "SURVIVOR", etc)
---@param subTier string The sub-tier variant (e.g. "LOW", "WARLORD") - unused for now but passed for context
---@param worldTier string "EARLY"|"MID"|"LATE"|"END"
---@return table
function ReactiveSE_BaseKits.SelectKit(category, subTier, worldTier)
    local kits = BASE_KITS[category]
    if not kits then
        Utils.LogWarning("[BaseKits] Unknown category: " .. tostring(category) .. ". Defaulting to CIVILIAN.")
        kits = BASE_KITS.CIVILIAN
    end -- Fallback

    -- Filter by WorldTier
    local validKits = {}
    local totalWeight = 0

    for i = 1, #kits do
        local kit = kits[i]
        local isValid = true
        if kit.tiers and worldTier then
            isValid = false
            for j = 1, #kit.tiers do
                local tier = kit.tiers[j]
                if tier == worldTier then
                    isValid = true
                    break
                end
            end
        end

        if isValid then
            table.insert(validKits, kit)
            totalWeight = totalWeight + kit.weight
        end
    end

    -- Fallback: If no kits match the tier (e.g. EARLY Military?), use all kits
    if #validKits == 0 then
        Utils.LogWarning("  [BaseKits] No valid kits for " ..
            category .. " in " .. tostring(worldTier) .. ". Using all.")
        validKits = kits
        for i = 1, #validKits do
            local kit = validKits[i]
            totalWeight = totalWeight + kit.weight
        end
    end

    local roll = ZombRand(totalWeight)
    local currentWeight = 0

    for i = 1, #validKits do
        local kit = validKits[i]
        currentWeight = currentWeight + kit.weight
        if roll < currentWeight then
            Utils.LogInfo("  [BaseKits] Selected " .. kit.name .. " (Roll: " .. roll .. "/" .. totalWeight .. ")")
            return kit
        end
    end

    return validKits[1]
end

---Get a weapon from the pool
---@param weaponCategory string
---@param worldTier string
---@return string|nil
function ReactiveSE_BaseKits.GetWeapon(weaponCategory, worldTier)
    if not weaponCategory then return nil end
    return WeaponPools.GetWeapon(weaponCategory)
end

---Get a backpack from the pool
---@param backpackCategory string
---@param worldTier string
---@return string|nil
function ReactiveSE_BaseKits.GetBackpack(backpackCategory, worldTier)
    local pool = BACKPACK_POOLS[backpackCategory]
    if not pool then return nil end

    local tierPool = pool[worldTier] or pool.EARLY
    if #tierPool == 0 then return nil end

    return tierPool[ZombRand(#tierPool) + 1]
end

---Checks if a weapon category is a firearm/ranged category
---@param category string
---@return boolean
function ReactiveSE_BaseKits.IsRangedCategory(category)
    local rangedCategories = {
        CIV_PISTOL = true,
        SERVICE_PISTOL = true,
        SHOTGUN_CIV = true,
        RIFLE_CIV = true,
        ASSAULT_RIFLE = true
    }
    return rangedCategories[category] == true
end

return ReactiveSE_BaseKits
