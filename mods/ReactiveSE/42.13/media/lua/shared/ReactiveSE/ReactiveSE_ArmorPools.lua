--//////////////////////////////////////////////////--
--    Reactive Sound Events - Armor Pools
--    Pools of armor for corpses
--//////////////////////////////////////////////////--

local Utils = require "ReactiveSE/ReactiveSE_Utils"

local ReactiveSE_ArmorPools = {}

local ARMOR_POOLS = {
    LIGHT = {
        HEAD = { "Base.Hat_HockeyMask_Wood", "Base.Hat_HardHat", "Base.Hat_BicycleHelmet" },
        TORSO = { "Base.Cuirass_Wood", "Base.Cuirass_Tire", "Base.Cuirass_Magazine", "Base.Vest_BulletCivilian" },
        LIMBS = {}
    },

    MEDIUM = {
        HEAD = { "Base.Hat_CrashHelmet", "Base.Hat_Fireman", "Base.Hat_Police" },
        TORSO = { "Base.Cuirass_Bone", "Base.Cuirass_Metal", "Base.Cuirass_MetalScrap", "Base.Vest_BulletPolice", "Base.Vest_BulletSWAT", "Base.Jacket_Fireman" },
        LIMBS = {}
    },

    HEAVY = {
        HEAD = { "Base.Hat_Army", "Base.Hat_RiotHelmet", "Base.Hat_SWAT" },
        TORSO = { "Base.Cuirass_CoatOfPlates", "Base.Vest_BulletArmy" },
        LIMBS = { "Base.Chainmail_Hand_L", "Base.Chainmail_Hand_R", "Base.Chainmail_SleeveFull_L", "Base.Chainmail_SleeveFull_R", "Base.Shoulderpad_Metal_L", "Base.Shoulderpad_Metal_R" }
    }
}

---Gets a list of armor items to equip based on class
---@param weightClass string "LIGHT", "MEDIUM", "HEAVY"
---@return table list of item types
function ReactiveSE_ArmorPools.GetArmorSet(weightClass)
    Utils.LogInfo("[ArmorPools] GetArmorSet called for: " .. tostring(weightClass))
    local pool = ARMOR_POOLS[weightClass]
    if not pool then
        Utils.LogInfo("[ArmorPools] No pool found for class: " .. tostring(weightClass))
        return {}
    end

    local items = {}
    local slotsFilled = {}

    -- Logic: 1 to 3 pieces max (Section 10.1)
    local maxPieces = ZombRand(1, 4)
    local count = 0

    -- Try to get a Torso piece first (Core protection)
    if pool.TORSO and #pool.TORSO > 0 and ZombRand(100) < 80 then
        local item = pool.TORSO[ZombRand(#pool.TORSO) + 1]
        table.insert(items, item)
        count = count + 1
        Utils.LogInfo("[ArmorPools] Selected Torso: " .. tostring(item))
    end

    -- Try Head
    if count < maxPieces and pool.HEAD and #pool.HEAD > 0 and ZombRand(100) < 70 then
        local item = pool.HEAD[ZombRand(#pool.HEAD) + 1]
        table.insert(items, item)
        count = count + 1
        Utils.LogInfo("[ArmorPools] Selected Head: " .. tostring(item))
    end

    -- Try Limbs (Heavy only usually)
    if count < maxPieces and pool.LIMBS and #pool.LIMBS > 0 then
        local item = pool.LIMBS[ZombRand(#pool.LIMBS) + 1]
        table.insert(items, item)
        Utils.LogInfo("[ArmorPools] Selected Limb: " .. tostring(item))
    end

    Utils.LogInfo("[ArmorPools] Returning " .. #items .. " items for class " .. tostring(weightClass))
    return items
end

return ReactiveSE_ArmorPools
