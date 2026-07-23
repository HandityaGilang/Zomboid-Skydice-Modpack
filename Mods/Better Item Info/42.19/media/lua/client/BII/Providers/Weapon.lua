local Options = require("BII/Options")
local Utils = require("BII/Utils")

local weaponTypes = {
    WeaponCategory and WeaponCategory.AXE,
    WeaponCategory and WeaponCategory.LONG_BLADE,
    WeaponCategory and WeaponCategory.SMALL_BLADE,
    WeaponCategory and WeaponCategory.SMALL_BLUNT,
    WeaponCategory and WeaponCategory.BLUNT,
    WeaponCategory and WeaponCategory.SPEAR,
    WeaponCategory and WeaponCategory.IMPROVISED,
}

local weaponSkills = {
    Perks and Perks.Axe,
    Perks and Perks.LongBlade,
    Perks and Perks.SmallBlade,
    Perks and Perks.SmallBlunt,
    Perks and Perks.Blunt,
    Perks and Perks.Spear,
}

local weaponSkillText = {
    { "IGUI_perks_Axe", "Axe" },
    { "IGUI_perks_LongBlade", "Long Blade" },
    { "IGUI_perks_SmallBlade", "Short Blade" },
    { "IGUI_perks_SmallBlunt", "Short Blunt" },
    { "IGUI_perks_Blunt", "Long Blunt" },
    { "IGUI_perks_Spear", "Spear" },
}

local function weaponSkillName(item)
    if Utils.call(item, "getSubCategory") == "Firearm" then
        return Utils.text("IGUI_perks_Aiming", "Aiming")
    end

    local scriptItem = Utils.call(item, "getScriptItem")
    for i, category in ipairs(weaponTypes) do
        if category and weaponSkillText[i] and Utils.call(scriptItem, "containsWeaponCategory", category) == true then
            return Utils.text(weaponSkillText[i][1], weaponSkillText[i][2])
        end
    end
    return nil
end

local function maintenanceLevel()
    local player = getPlayer and getPlayer() or nil
    if not player then return 10 end
    if SandboxVars and SandboxVars.BetterItemInfo and SandboxVars.BetterItemInfo.MaintenanceLevelRequirement == false then
        return 10
    end
    return Utils.call(player, "getPerkLevel", Perks and Perks.Maintenance) or 0
end

local function weaponLevel(item)
    local player = getPlayer and getPlayer() or nil
    if not player then return 10, false end
    if SandboxVars and SandboxVars.BetterItemInfo and SandboxVars.BetterItemInfo.WeaponLevelRequirement == false then
        return 10, false
    end

    local scriptItem = Utils.call(item, "getScriptItem")
    for i, category in ipairs(weaponTypes) do
        if category and Utils.call(scriptItem, "containsWeaponCategory", category) == true then
            return Utils.call(player, "getPerkLevel", weaponSkills[i]) or 0, category == (WeaponCategory and WeaponCategory.AXE)
        end
    end
    return 0, false
end

local function conditionLowerChance(item)
    local player = getPlayer and getPlayer() or nil
    if not player then return 0 end
    if Utils.call(item, "getSubCategory") == "Firearm" then
        return 1 / (60 + (Utils.call(player, "getPerkLevel", Perks and Perks.Aiming) or 0) * 2)
    end

    local level = weaponLevel(item)
    if level <= 0 then return 0 end
    local maintenance = Utils.call(player, "getPerkLevel", Perks and Perks.Maintenance) or 0
    local lowerChanceOneIn = Utils.call(item, "getConditionLowerChance") or 0
    if lowerChanceOneIn <= 0 then return 0 end
    return 1 / (lowerChanceOneIn + math.floor(math.floor(maintenance + (level / 2)) / 2) * 2)
end

local function criticalChance(item, level, isAxe)
    local base = Utils.call(item, "getCriticalChance") or 0
    if isAxe then return base + 3 * level end
    return base + 3 * math.max(level - 1, 0)
end

local function addConditionRows(rows, item)
    local level = maintenanceLevel()
    if level < 1 then return end

    local condition = Utils.call(item, "getCondition")
    local maxCondition = Utils.call(item, "getConditionMax")
    if type(condition) == "number" and type(maxCondition) == "number" and maxCondition > 0 then
        Utils.addRow(rows, Utils.row(Utils.text("Tooltip_weapon_Condition", "Condition"), tostring(condition) .. " / " .. tostring(maxCondition)))
    end

    if level >= 2 then
        local chance = conditionLowerChance(item)
        local decimals = level >= 3 and 1 or 0
        if chance > 0 then
            Utils.addRow(rows, Utils.row(Utils.text("Tooltip_BII_ConditionLowerChance", "Condition Lower Chance"), Utils.formatPercent(chance, decimals)))
        end
    end
end

local function getRows(item)
    local rows = {}
    if Utils.isInstance(item, "HandWeapon") then
        local skillName = weaponSkillName(item)
        if skillName then
            Utils.addRow(rows, Utils.row(Utils.text("Tooltip_BII_WeaponSkill", "Weapon Skill"), skillName))
        end
        addConditionRows(rows, item)
        local subCategory = Utils.call(item, "getSubCategory")

        if subCategory == "Firearm" then
            local player = getPlayer and getPlayer() or nil
            local aiming = player and (Utils.call(player, "getPerkLevel", Perks and Perks.Aiming) or 0) or 10
            local reloading = player and (Utils.call(player, "getPerkLevel", Perks and Perks.Reloading) or 0) or 10
            if aiming >= 1 then
                Utils.addRow(rows, Utils.row(Utils.text("Tooltip_weapon_Damage", "Damage"), Utils.formatNumber(Utils.call(item, "getMinDamage") or 0, 1) .. "-" .. Utils.formatNumber(Utils.call(item, "getMaxDamage") or 0, 1)))
            end
            if aiming >= 2 then Utils.addRow(rows, Utils.row(Utils.text("Tooltip_BII_CritChance", "Crit Chance"), Utils.formatPercent((Utils.call(item, "getCriticalChance") or 0) / 100, 2))) end
            if aiming >= 3 then Utils.addRow(rows, Utils.row(Utils.text("Tooltip_BII_Accuracy", "Accuracy"), Utils.formatNumber(Utils.call(item, "getHitChance") or 0, 2))) end
            if aiming >= 4 then Utils.addRow(rows, Utils.row(Utils.text("Tooltip_BII_NoiseRadius", "Noise Radius"), Utils.formatNumber(Utils.call(item, "getSoundRadius") or 0, 2))) end
            if reloading >= 1 then Utils.addRow(rows, Utils.row(Utils.text("Tooltip_BII_ReloadTime", "Reload Time"), Utils.formatNumber(Utils.call(item, "getReloadTime") or 0, 2))) end
            return rows
        end

        local level, isAxe = weaponLevel(item)
        if level >= 1 then
            Utils.addRow(rows, Utils.row(Utils.text("Tooltip_weapon_Damage", "Damage"), Utils.formatNumber(Utils.call(item, "getMinDamage") or 0, 1) .. "-" .. Utils.formatNumber(Utils.call(item, "getMaxDamage") or 0, 1)))
        end
        if level >= 2 then Utils.addRow(rows, Utils.row(Utils.text("Tooltip_BII_CritChance", "Crit Chance"), Utils.formatPercent(criticalChance(item, level, isAxe) / 100, 2))) end
        if level >= 3 then Utils.addRow(rows, Utils.row(Utils.text("Tooltip_BII_AttackSpeed", "Attack Speed"), Utils.formatNumber(Utils.call(item, "getBaseSpeed") or 0, 2))) end
        if level >= 4 then Utils.addRow(rows, Utils.row(Utils.text("Tooltip_BII_Knockback", "Knockback"), Utils.formatNumber(Utils.call(item, "getPushBackMod") or 0, 2))) end
    elseif ItemTag and Utils.hasTag(item, ItemTag.SHOW_CONDITION) then
        addConditionRows(rows, item)
    end

    return rows
end

return Utils.newProvider(Options.shouldShowWeaponInfo, 32, getRows)
