-- RGMXpBonus: adds bonus XP on top of vanilla grants.
-- Vanilla XpUpdate.lua runs first and awards base XP normally.
-- This file only adds the delta from weapon modifiers and clothing.

RGMManager = RGMManager or {}
if RGMManager.XPBonusLoaded then return end
RGMManager.XPBonusLoaded = true

local function onWeaponHitXpBonus(owner, weapon, hitObject, damage, hitCount)
    if not weapon then return end

    local xpMultiplier = 1
    local weaponModifier = weapon:getModData().modifier
    if weaponModifier and weaponModifier.statsMultipliers and weaponModifier.statsMultipliers.experience then
        xpMultiplier = weaponModifier.statsMultipliers.experience
    end

    local wb = instanceof(owner, "IsoPlayer") and RGMManager.getWornXpBonuses(owner) or nil

    -- Nothing to add
    if xpMultiplier == 1 and not wb then return end

    local exp = math.min(damage * 0.9, 3)

    local function addBonus(perk, baseAmount)
        local bonus = baseAmount * (xpMultiplier - 1)
                    + (wb and baseAmount * (wb["xp " .. tostring(perk)] or 0) or 0)
        if bonus > 0 then addXp(owner, perk, bonus) end
    end

    if weapon:isRanged() then
        local baseXp = hitCount
        if owner:getPerkLevel(Perks.Aiming) < 5 then baseXp = baseXp * 2.7 end
        addBonus(Perks.Aiming, baseXp)
    end
    if hitCount > 0 and not weapon:isRanged() then
        local si = weapon:getScriptItem()
        if si then
            if si:containsWeaponCategory(WeaponCategory.AXE)         then addBonus(Perks.Axe,        exp) end
            if si:containsWeaponCategory(WeaponCategory.BLUNT)       then addBonus(Perks.Blunt,      exp) end
            if si:containsWeaponCategory(WeaponCategory.SPEAR)       then addBonus(Perks.Spear,      exp) end
            if si:containsWeaponCategory(WeaponCategory.LONG_BLADE)  then addBonus(Perks.LongBlade,  exp) end
            if si:containsWeaponCategory(WeaponCategory.SMALL_BLADE) then addBonus(Perks.SmallBlade, exp) end
            if si:containsWeaponCategory(WeaponCategory.SMALL_BLUNT) then addBonus(Perks.SmallBlunt, exp) end
        end
    end
end

Events.OnWeaponHitXp.Add(onWeaponHitXpBonus)
