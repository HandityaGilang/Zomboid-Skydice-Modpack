--//////////////////////////////////////////////////--
--    Reactive Sound Events - Virtual Kit Generator
--    Generates the logical representation of a survivor's belongings
--    before any looting or physics is applied.
--//////////////////////////////////////////////////--

local Utils = require "ReactiveSE/ReactiveSE_Utils"
local WorldTier = require "ReactiveSE/ReactiveSE_WorldTier"
local BaseKits = require "ReactiveSE/ReactiveSE_BaseKits"
local SubKits = require "ReactiveSE/ReactiveSE_SubKits"
local ArmorPools = require "ReactiveSE/ReactiveSE_ArmorPools"

local ReactiveSE_VirtualKit = {}

--//////////////////////////////////////////////////--
--          Internal Helpers                      --
--//////////////////////////////////////////////////--

-- Helper to resolve Extra into items and subkits
---@param extraName string
---@param subKitsToUnlock table (ref to list)
---@return table explicitItems Items to spawn immediately (e.g. Armor, Radio)
local function resolveExtra(extraName, subKitsToUnlock)
    local items = {}
    if not extraName then return items end

    -- 8.1.1 Utility Extras
    if extraName == "UTILITY_FLASHLIGHT" then
        table.insert(items, "Base.HandTorch")
        table.insert(items, "Base.Battery")
    elseif extraName == "UTILITY_WALKIETALKIE" then
        table.insert(items, "Base.WalkieTalkieMakeShift")
        table.insert(items, "Base.Battery")
    elseif extraName == "UTILITY_FIRECRACKER" then
        table.insert(items, "Base.Firecracker")
    elseif extraName == "UTILITY_RADIO" then
        table.insert(items, "Base.RadioMakeShift")
        table.insert(items, "Base.Battery")

        -- 8.1.2 Tooling Extras
    elseif extraName == "TOOLS_LIGHT" then
        table.insert(subKitsToUnlock, "Tools")
    elseif extraName == "TOOLS_MEDIUM" then
        table.insert(subKitsToUnlock, "Tools")
        table.insert(subKitsToUnlock, "Tools")
    elseif extraName == "TOOLS_HEAVY" then
        table.insert(subKitsToUnlock, "Tools")
        table.insert(subKitsToUnlock, "Tools")
        table.insert(subKitsToUnlock, "Tools")

        -- 8.1.3 Medical Extras
    elseif extraName == "MEDICAL_BASIC" then
        table.insert(subKitsToUnlock, "Medicine")
    elseif extraName == "MEDICAL_FULL" then
        table.insert(subKitsToUnlock, "Medicine")
        table.insert(subKitsToUnlock, "Medicine")
        table.insert(subKitsToUnlock, "Medicine")

        -- 8.1.4 Vice Extras
    elseif extraName == "VICE_LIGHT" then
        table.insert(subKitsToUnlock, "Vice")
    elseif extraName == "VICE_HEAVY" then
        table.insert(subKitsToUnlock, "Vice")
        table.insert(subKitsToUnlock, "Vice")
        table.insert(subKitsToUnlock, "Vice")

        -- 8.1.5 Armor Extras (Section 10.5)
    elseif string.find(extraName, "ARMOR_") then
        local weightClass = string.sub(extraName, 7) -- Remove "ARMOR_"
        local armorSet = ArmorPools.GetArmorSet(weightClass)
        for i = 1, #armorSet do
            local armor = armorSet[i]
            table.insert(items, armor)
        end
    end

    return items
end

--//////////////////////////////////////////////////--
--          Public Functions                      --
--//////////////////////////////////////////////////--

---Generates the initial Virtual Kit based on BaseKit and settings
---@param baseKit table The selected BaseKit definition
---@param settings table Sandbox settings (rangedChance, etc)
---@param archetype string|nil The archetype category (e.g. "CIVILIAN", "MILITARY")
---@return table virtualKit Data structure
function ReactiveSE_VirtualKit.GenerateBase(baseKit, settings, archetype)
    local data = {
        primaryWeapon = nil,
        primaryCategory = nil,
        sidearm = nil,
        sidearmCategory = nil,
        backpack = nil,
        extraItems = {},
        unlockedSubKits = {}
    }

    local currentTier = WorldTier.GetWorldTier()

    -- 1. Backpack
    if baseKit.backpack then
        data.backpack = BaseKits.GetBackpack(baseKit.backpack, currentTier)
    end

    -- 2. Primary Weapon
    local primaryCat = baseKit.meleeWeapon
    local rangedChance = settings.rangedChance or 50

    -- Roll for Ranged Primary (skip if noFirearms is set)
    if baseKit.rangedWeapon and not settings.noFirearms then
        if ZombRand(100) < rangedChance then
            primaryCat = baseKit.rangedWeapon
        end
    end

    if primaryCat then
        data.primaryCategory = primaryCat
        data.primaryWeapon = BaseKits.GetWeapon(primaryCat, currentTier)
        Utils.LogInfo(string.format("    > VirtualKit: Resolved Primary Weapon: %s", tostring(data.primaryWeapon)))
    end

    -- 3. Sidearm
    if baseKit.sidearm then
        local checkSidearm = baseKit.sidearm
        local primaryIsRanged = data.primaryCategory and BaseKits.IsRangedCategory(data.primaryCategory)

        if settings.noFirearms and BaseKits.IsRangedCategory(checkSidearm) then
            checkSidearm = "SMALL_MELEE_PROPER"
            Utils.LogInfo("    > VirtualKit: Sidearm forced to melee (noFirearms setting)")
        elseif BaseKits.IsRangedCategory(checkSidearm) then
            local rangedChance = settings.rangedChance or 50
            if primaryIsRanged or ZombRand(100) >= rangedChance then
                checkSidearm = "SMALL_MELEE_PROPER"
                Utils.LogInfo("    > VirtualKit: Sidearm Ranged Gate (Primary Ranged: " ..
                    tostring(primaryIsRanged) .. "). Downgraded to Knife.")
            end
        end

        data.sidearmCategory = checkSidearm
        data.sidearm = BaseKits.GetWeapon(checkSidearm, currentTier)
        Utils.LogInfo(string.format("    > VirtualKit: Resolved Sidearm: %s (Category: %s)", tostring(data.sidearm),
            checkSidearm))
    end

    -- 4. Extras
    if baseKit.extra then
        data.extraItems = resolveExtra(baseKit.extra, data.unlockedSubKits)
    end

    return data
end

---Populates the subkit items for the virtual kit
---@param allowedSubKits table List of allowed subkit names
---@param subKitChances table Map of subkit chances
---@param unlockedSubKits table List of unconditionally unlocked subkits
---@param worldTier string
---@param lootQuality number
---@return table items List of item types
function ReactiveSE_VirtualKit.GenerateSubKits(allowedSubKits, subKitChances, unlockedSubKits, worldTier, lootQuality)
    local items = {}
    local usedSubKits = {}

    local function addSubKitItems(name)
        -- Select item TYPE string or table {item, count}
        local result = SubKits.SelectSubKitItem(name, worldTier, lootQuality)
        if result then
            if type(result) == "table" and result.item then
                -- Count based addition
                local count = result.count or 1
                for _ = 1, count do
                    table.insert(items, result.item)
                end
                Utils.LogInfo(string.format("      > SubKit Item: %s (Count: %d)", result.item, count))
            elseif type(result) == "string" then
                -- Legacy fallback
                table.insert(items, result)
                Utils.LogInfo(string.format("      > SubKit Item: %s", result))
            end
        end
    end

    -- Guaranteed
    for i = 1, #unlockedSubKits do
        local name = unlockedSubKits[i]
        addSubKitItems(name)
    end

    -- Random
    for i = 1, #allowedSubKits do
        local subKitName = allowedSubKits[i]
        local chance = subKitChances[subKitName] or 0
        local roll = ZombRand(100)
        if roll < chance then
            if not usedSubKits[subKitName] then
                addSubKitItems(subKitName)
                usedSubKits[subKitName] = true
                Utils.LogInfo("      + Added SubKit: " .. subKitName .. " (Roll " .. roll .. " < " .. chance .. ")")
            end
        else
            Utils.LogInfo("      - Failed SubKit: " .. subKitName .. " (Roll " .. roll .. " >= " .. chance .. ")")
        end
    end

    return items
end

return ReactiveSE_VirtualKit
