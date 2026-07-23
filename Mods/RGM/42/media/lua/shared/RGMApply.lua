
-- Shared apply functions: available on both client and server.
-- Client uses these in onServerCommand to immediately update item data after reforge.
-- Server uses these during initial item processing and reforge handling.

RGMManager = RGMManager or {}
if RGMManager.ApplyLoaded then return end
RGMManager.ApplyLoaded = true

RGMManager.testMode = RGMManager.testMode or false

local function safeSet(item, setter, value)
    if type(item[setter]) ~= "function" then return false end
    local ok = pcall(item[setter], item, value)
    return ok
end

-- Substrings matched against getBodyLocation():lower() to detect jewelry/cosmetics.
-- PZ B42 format: "base:left_ringfinger", "base:leftwrist", "base:necklace", etc.
local RGM_JEWELRY_SUBSTRINGS = {
    "ringfinger",   -- base:left_ringfinger, base:right_ringfinger
    "middlefinger", -- base:left_middlefinger, base:right_middlefinger
    "wrist",        -- base:leftwrist, base:rightwrist
    "necklace",     -- base:necklace, base:necklace_long
    "base:ears",    -- earrings
    "base:eartop",  -- earrings (top)
    "base:nose",    -- nose stud / ring
    "bellybutton",  -- base:bellybutton
    "lefteye",      -- base:lefteye
    "righteye",     -- base:righteye
    "makeup",       -- base:makeupeyes, etc.
    "make_up",      -- alternate spelling
    "base:wound",
    "base:bandage",
    "base:tail",
    "codpiece",
}

function RGMManager.isJewelry(item)
    local bodyLoc = type(item.getBodyLocation) == "function" and item:getBodyLocation() or nil
    if not bodyLoc then return false end
    local loc = tostring(bodyLoc):lower()
    for _, sub in ipairs(RGM_JEWELRY_SUBSTRINGS) do
        if loc:find(sub, 1, true) then return true end
    end
    return false
end

local function _round(num, dec)
    local m = 10^(dec or 0)
    return math.floor(num * m + 0.5) / m
end

function RGMManager.customSplit(_inputstring, _separator)
    if _separator == nil then _separator = "%s" end
    local t = {}
    for str in string.gmatch(_inputstring, "([^".._separator.."]+)") do
        table.insert(t, str)
    end
    return t
end

-- Translates modifier.modifierName from stored IGUI keys to display text if not yet done.
-- Updates item:getModData().modifier in place and returns the (possibly updated) modifier.
function RGMManager.resolveModifierName(_item)
    local modifier = _item:getModData().modifier
    if not modifier or modifier.translationChecked then return modifier end
    if not modifier.modifierName then return modifier end
    if not modifier.modifierName:find("IGUI_modifier_name_") then
        _item:getModData().modifier.translationChecked = true
        return modifier
    end
    local parts = RGMManager.customSplit(modifier.modifierName, " ")
    if parts[1] and parts[2] then
        _item:getModData().modifier.modifierName = getText(parts[1]).." "..getText(parts[2])
    elseif parts[1] then
        _item:getModData().modifier.modifierName = getText(parts[1])
    end
    if not _item:getModData().modifier.modifierName:find("IGUI_modifier_name_") then
        _item:getModData().modifier.translationChecked = true
    end
    return _item:getModData().modifier
end

function RGMManager.applyModifierStatsToItem(item, modifier)
    if not modifier or not item then return false end
    if not modifier.statsMultipliers then return false end
    local multipliers = modifier.statsMultipliers
    -- if RGMManager.testMode then print("[RGM] Applying [" .. tostring(modifier.modifierName) .. "] to " .. tostring(item:getDisplayName())) end

    if not item:getModData().scriptStats then
        local function safeGet(obj, method)
            return type(obj[method]) == "function" and obj[method](obj) or nil
        end
        item:getModData().scriptStats = {
            ScriptName              = item:getDisplayName() or "",
            MinDamage               = safeGet(item, "getMinDamage"),
            MaxDamage               = safeGet(item, "getMaxDamage"),
            TreeDamage              = safeGet(item, "getTreeDamage"),
            DoorDamage              = safeGet(item, "getDoorDamage"),
            PushBackMod             = safeGet(item, "getPushBackMod"),
            KnockdownMod            = safeGet(item, "getKnockdownMod"),
            MaxRange                = safeGet(item, "getMaxRange"),
            MinRange                = safeGet(item, "getMinRange"),
            BaseSpeed               = safeGet(item, "getBaseSpeed"),
            EnduranceMod            = safeGet(item, "getEnduranceMod"),
            CriticalChance          = safeGet(item, "getCriticalChance"),
            ConditionLowerChance    = safeGet(item, "getConditionLowerChance"),
            HitChance               = safeGet(item, "getHitChance"),
            SoundRadius             = safeGet(item, "getSoundRadius"),
            SoundVolume             = safeGet(item, "getSoundVolume"),
            SoundGain               = safeGet(item, "getSoundGain"),
            RecoilDelay             = safeGet(item, "getRecoilDelay"),
            AimingTime              = safeGet(item, "getAimingTime"),
            ReloadTime              = safeGet(item, "getReloadTime"),
            AimingPerkRangeModifier     = safeGet(item, "getAimingPerkRangeModifier"),
            AimingPerkCritModifier      = safeGet(item, "getAimingPerkCritModifier"),
            AimingPerkHitChanceModifier = safeGet(item, "getAimingPerkHitChanceModifier"),
            JamGunChance                = safeGet(item, "getJamGunChance"),
            MaxAmmo                     = safeGet(item, "getMaxAmmo"),
        }
    end

    local scriptStats = item:getModData().scriptStats or {}

    -- Update item name only when translated (getText() is unavailable server-side)
    modifier = RGMManager.resolveModifierName(item)
    if scriptStats.ScriptName ~= item:getScriptItem():getDisplayName() then
        item:getModData().scriptStats.ScriptName = item:getScriptItem():getDisplayName()
    end
    if modifier.translationChecked then
        local baseName = item:getModData().scriptStats.ScriptName or item:getScriptItem():getDisplayName()
        local expectedName = baseName.." ["..modifier.modifierName.."]"
        if item:getName() ~= expectedName then item:setName(expectedName) end
        item:setCustomName(true)
    end

    -- Apply stats
    local dmgMult = multipliers.damage or 1
    local hitChanceOfWeaponParts, aimingTimeOfWeaponParts = 0, 0
    local reloadTimeOfWeaponParts, recoilDelayOfWeaponParts = 0, 0
    local minRangeOfWeaponParts, maxRangeOfWeaponParts, damageOfWeaponParts = 0, 0, 0

    if type(item.isRanged) == "function" and item:isRanged() then
        local partGetters = {"getCanon","getClip","getRecoilpad","getScope","getSling","getStock"}
        for _, getter in ipairs(partGetters) do
            if type(item[getter]) == "function" then
                local part = item[getter](item)
                if part then
                    if type(part.getHitChance)      == "function" then hitChanceOfWeaponParts   = hitChanceOfWeaponParts   + part:getHitChance()    end
                    if type(part.getAimingTime)     == "function" then aimingTimeOfWeaponParts  = aimingTimeOfWeaponParts  + part:getAimingTime()   end
                    if type(part.getReloadTime)     == "function" then reloadTimeOfWeaponParts  = reloadTimeOfWeaponParts  + part:getReloadTime()   end
                    if type(part.getRecoilDelay)    == "function" then recoilDelayOfWeaponParts = recoilDelayOfWeaponParts + part:getRecoilDelay()  end
                    if type(part.getMinRangeRanged) == "function" then minRangeOfWeaponParts    = minRangeOfWeaponParts    + part:getMinRangeRanged() end
                    if type(part.getMaxRange)       == "function" then maxRangeOfWeaponParts    = maxRangeOfWeaponParts    + part:getMaxRange()     end
                    if type(part.getDamage)         == "function" then damageOfWeaponParts      = damageOfWeaponParts      + part:getDamage()       end
                end
            end
        end
    end

    if scriptStats.MinDamage and _round(scriptStats.MinDamage*dmgMult, 2) ~= item:getMinDamage() then
        safeSet(item, "setMinDamage", _round(scriptStats.MinDamage*dmgMult, 2) + damageOfWeaponParts)
    end
    if scriptStats.MaxDamage and _round(scriptStats.MaxDamage*dmgMult, 2) ~= item:getMaxDamage() then
        safeSet(item, "setMaxDamage", _round(scriptStats.MaxDamage*dmgMult, 2) + damageOfWeaponParts)
        if type(item.isRanged) == "function" and not item:isRanged() then
            if scriptStats.TreeDamage then safeSet(item, "setTreeDamage", _round(scriptStats.TreeDamage*dmgMult, 2) + damageOfWeaponParts) end
            if scriptStats.DoorDamage then safeSet(item, "setDoorDamage", _round(scriptStats.DoorDamage*dmgMult, 2) + damageOfWeaponParts) end
        end
    end

    local knockbackMult = multipliers.knockback or 1
    if scriptStats.PushBackMod  and _round(scriptStats.PushBackMod*knockbackMult, 2)  ~= item:getPushBackMod()  then safeSet(item, "setPushBackMod",  _round(scriptStats.PushBackMod*knockbackMult, 2)) end
    if scriptStats.KnockdownMod and _round(scriptStats.KnockdownMod*knockbackMult, 2) ~= item:getKnockdownMod() then safeSet(item, "setKnockdownMod", _round(scriptStats.KnockdownMod*knockbackMult, 2)) end

    local maximumMult = multipliers["maximum range"] or 1
    if scriptStats.MaxRange and _round(scriptStats.MaxRange*maximumMult, 2) ~= item:getMaxRange() then
        safeSet(item, "setMaxRange", _round(scriptStats.MaxRange*maximumMult, 2) + maxRangeOfWeaponParts)
        if type(item.isRanged) == "function" and item:isRanged() and scriptStats.AimingPerkRangeModifier then
            safeSet(item, "setAimingPerkRangeModifier", _round(scriptStats.AimingPerkRangeModifier*maximumMult, 2))
        end
    end

    local minimumMult = multipliers["minimum range"] or 1
    if type(item.isRanged) == "function" and item:isRanged() and scriptStats.MinRangeRanged then
        if _round(scriptStats.MinRangeRanged*minimumMult, 2) ~= item:getMinRangeRanged() then
            safeSet(item, "setMinRangeRanged", _round(scriptStats.MinRangeRanged*minimumMult, 2) + minRangeOfWeaponParts)
        end
        if item:getMinRangeRanged() > item:getMaxRange() then safeSet(item, "setMinRangeRanged", item:getMaxRange()) end
    elseif scriptStats.MinRange then
        if _round(scriptStats.MinRange*minimumMult, 2) ~= item:getMinRange() then
            safeSet(item, "setMinRange", _round(scriptStats.MinRange*minimumMult, 2))
        end
        if item:getMinRange() > item:getMaxRange() then safeSet(item, "setMinRange", item:getMaxRange()) end
    end

    local attackspeedMult = multipliers["attack speed"] or multipliers["speed"] or 1
    if scriptStats.BaseSpeed and _round(scriptStats.BaseSpeed*attackspeedMult, 2) ~= item:getBaseSpeed() then
        safeSet(item, "setBaseSpeed", _round(scriptStats.BaseSpeed*attackspeedMult, 2))
    end

    local enduranceMult = multipliers["endurance cost"] or 1
    if scriptStats.EnduranceMod and _round(scriptStats.EnduranceMod*enduranceMult, 2) ~= item:getEnduranceMod() then
        safeSet(item, "setEnduranceMod", _round(scriptStats.EnduranceMod*enduranceMult, 2))
    end

    local criticalAdd = multipliers["critical chance"] or 0
    if scriptStats.CriticalChance then
        if math.floor(scriptStats.CriticalChance + criticalAdd + 0.5) ~= item:getCriticalChance() then
            safeSet(item, "setCriticalChance", math.max(0, math.floor(scriptStats.CriticalChance + criticalAdd + 0.5)))
        end
    end

    local durabilityMult = multipliers["durability"] or 1
    if scriptStats.ConditionLowerChance and math.floor(scriptStats.ConditionLowerChance*durabilityMult+0.6) ~= item:getConditionLowerChance() then
        safeSet(item, "setConditionLowerChance", math.floor(scriptStats.ConditionLowerChance*durabilityMult+0.6))
    end

    if type(item.isRanged) == "function" and item:isRanged() then
        local accuracyMult = multipliers.accuracy or 1
        if scriptStats.HitChance and math.floor(scriptStats.HitChance*accuracyMult + 0.5) ~= item:getHitChance() then
            safeSet(item, "setHitChance", math.floor(scriptStats.HitChance*accuracyMult + hitChanceOfWeaponParts + 0.5))
        end
        local soundMult = multipliers["sound radius"] or 1
        if soundMult ~= 1 and scriptStats.SoundRadius and math.floor(scriptStats.SoundRadius*soundMult + 0.5) ~= item:getSoundRadius() then
            safeSet(item, "setSoundRadius", math.floor(scriptStats.SoundRadius*soundMult + 0.5))
            safeSet(item, "setSoundVolume", math.floor(scriptStats.SoundVolume*soundMult + 0.5))
            safeSet(item, "setSoundGain", _round(scriptStats.SoundGain*soundMult, 2))
        end
        local recoilMult = multipliers.recoil or 1
        if scriptStats.RecoilDelay and math.floor(scriptStats.RecoilDelay*recoilMult + 0.5) ~= item:getRecoilDelay() then
            safeSet(item, "setRecoilDelay", math.floor(scriptStats.RecoilDelay*recoilMult + recoilDelayOfWeaponParts + 0.5))
        end
        local aimMult = multipliers["aim time"] or 1
        if scriptStats.AimingTime and math.floor(scriptStats.AimingTime*aimMult + 0.5) ~= item:getAimingTime() then
            safeSet(item, "setAimingTime", math.floor(scriptStats.AimingTime*aimMult + aimingTimeOfWeaponParts + 0.5))
        end
        local reloadMult = multipliers["reload time"] or 1
        if scriptStats.ReloadTime and math.floor(scriptStats.ReloadTime*reloadMult + 0.5) ~= item:getReloadTime() then
            safeSet(item, "setReloadTime", math.floor(scriptStats.ReloadTime*reloadMult + reloadTimeOfWeaponParts + 0.5))
        end
        local jamMult = multipliers["jam chance"] or 1
        if scriptStats.JamGunChance ~= nil and jamMult ~= 1 and type(item.getJamGunChance) == "function" then
            local newJam = math.floor(scriptStats.JamGunChance * jamMult + 0.5)
            if newJam ~= item:getJamGunChance() then
                if not safeSet(item, "setJamGunChance", newJam) then
                    safeSet(item, "setChanceToJam", newJam)
                end
            end
        end
        local maxAmmoAdd = multipliers["max ammo add"] or 0
        local maxAmmoPct = multipliers["max ammo pct"] or 1
        if maxAmmoAdd ~= 0 or maxAmmoPct ~= 1 then
            -- Lazy init: items saved before MaxAmmo was tracked won't have this field
            if not scriptStats.MaxAmmo or scriptStats.MaxAmmo <= 0 then
                local fresh = safeGet(item, "getMaxAmmo")
                if fresh and fresh > 0 then
                    item:getModData().scriptStats.MaxAmmo = fresh
                    scriptStats = item:getModData().scriptStats
                end
            end
            if scriptStats.MaxAmmo and scriptStats.MaxAmmo > 0 then
                local newMaxAmmo = math.max(1, math.floor(scriptStats.MaxAmmo * maxAmmoPct + maxAmmoAdd + 0.5))
                if newMaxAmmo ~= item:getMaxAmmo() then
                    safeSet(item, "setMaxAmmo", newMaxAmmo)
                    if type(item.getCurrentAmmo) == "function" then
                        local cur = item:getCurrentAmmo()
                        if cur and cur > newMaxAmmo then
                            safeSet(item, "setCurrentAmmo", newMaxAmmo)
                        end
                    end
                end
                -- For detachable magazine weapons: the clip controls actual reload capacity
                if type(item.getClip) == "function" then
                    local clip = item:getClip()
                    if clip and type(clip.getMaxAmmo) == "function" and type(clip.setMaxAmmo) == "function" then
                        local clipMax = clip:getMaxAmmo()
                        if clipMax and clipMax > 0 then
                            -- Never reduce a clip that is already larger (e.g. extended mags)
                            local newClipMax = math.max(newMaxAmmo, clipMax)
                            if newClipMax ~= clipMax then
                                pcall(function() clip:setMaxAmmo(newClipMax) end)
                            end
                        end
                    end
                end
            end
        end
    end

    if SandboxVars.RGM and SandboxVars.RGM.ClothingModifiers then
        if multipliers["capacity"] and multipliers["capacity"] ~= 0 then
            local inv = type(item.getInventory) == "function" and item:getInventory() or nil
            local baseCap = inv and type(inv.getCapacity) == "function" and inv:getCapacity() or nil
            if (baseCap == nil or baseCap <= 0) and type(item.getItemCapacity) == "function" then
                local c = item:getItemCapacity(); if c and c > 0 then baseCap = c end
            end
            if baseCap and baseCap > 0 then
                local newCap = math.max(1, math.floor(baseCap + multipliers["capacity"]))
                if inv and type(inv.setCapacity) == "function" then pcall(inv.setCapacity, inv, newCap) end
                safeSet(item, "setItemCapacity", newCap)
            end
        end
        if multipliers["weight reduction"] and multipliers["weight reduction"] ~= 0 then
            safeSet(item, "setWeightReduction", math.min(math.max(0, item:getWeightReduction() + multipliers["weight reduction"]), 99))
        end
        if multipliers["weight"] and multipliers["weight"] ~= 1 and type(item.getWeight) == "function" then
            local w = item:getWeight()
            if w and w > 0 then safeSet(item, "setWeight", math.max(0.1, w * multipliers["weight"])) end
        end
    end

    return true
end

function RGMManager.applyContainerStats(_item)
    if not _item then return end
    local modifier = _item:getModData().modifier
    if not modifier then return end
    modifier = RGMManager.resolveModifierName(_item)
    if modifier.modifierName and modifier.translationChecked and modifier.modifierName ~= getText("Tooltip_modifier_standard") then
        local base = _item:getModData().scriptStats or {}
        local baseName = base.ScriptName or (_item:getScriptItem() and _item:getScriptItem():getDisplayName() or _item:getDisplayName())
        local expectedName = baseName .. " [" .. modifier.modifierName .. "]"
        if _item:getName() ~= expectedName then
            _item:setName(expectedName)
            _item:setCustomName(true)
        end
    end
    if not modifier.statsMultipliers then return end
    local mult = modifier.statsMultipliers
    local base = _item:getModData().scriptStats or {}
    local inv = type(_item.getInventory) == "function" and _item:getInventory() or nil

    -- fix bad base capacity saved from a previous session (e.g. first load with old RGM version)
    if (not base.ItemCapacity or base.ItemCapacity <= 0) and inv and type(inv.getCapacity) == "function" then
        local fresh = inv:getCapacity()
        if fresh and fresh > 0 then
            _item:getModData().scriptStats = _item:getModData().scriptStats or {}
            _item:getModData().scriptStats.ItemCapacity = fresh
            base = _item:getModData().scriptStats
        end
    end

    if base.ItemCapacity and base.ItemCapacity > 0 then
        local absBonus = (mult["capacity"] and mult["capacity"] ~= 0) and mult["capacity"] or 0
        local pctMult  = (mult["capacity pct"] and mult["capacity pct"] ~= 1) and mult["capacity pct"] or 1
        if absBonus ~= 0 or pctMult ~= 1 then
            local newCap = math.max(1, math.floor(base.ItemCapacity * pctMult + absBonus + 0.5))
            if inv and type(inv.setCapacity) == "function" then pcall(inv.setCapacity, inv, newCap) end
            safeSet(_item, "setItemCapacity", newCap)
        end
    end
    if mult["weight reduction"] and mult["weight reduction"] ~= 0 and base.WeightReduction then
        safeSet(_item, "setWeightReduction", math.min(math.max(0, base.WeightReduction + mult["weight reduction"]), 99))
    end
    if mult["weight"] and mult["weight"] ~= 1 then
        -- fix bad/missing base Weight from previous session
        if not base.Weight or base.Weight <= 0 then
            local fw = (type(_item.getActualWeight) == "function" and _item:getActualWeight())
                    or (type(_item.getWeight) == "function" and _item:getWeight())
            if fw and fw > 0 then
                _item:getModData().scriptStats = _item:getModData().scriptStats or {}
                _item:getModData().scriptStats.Weight = fw
                base = _item:getModData().scriptStats
            end
        end
        if base.Weight and base.Weight > 0 then
            local newW = math.max(0.1, base.Weight * mult["weight"])
            if type(_item.setActualWeight) == "function" then safeSet(_item, "setActualWeight", newW)
            else safeSet(_item, "setWeight", newW) end
        end
    end
end

function RGMManager.applyClothingStats(_item, _modifierList)
    if not _item then return end
    local modifier = _item:getModData().modifier
    if modifier and modifier.modifierName then
        modifier = RGMManager.resolveModifierName(_item)
        if modifier.translationChecked and modifier.modifierName ~= getText("Tooltip_modifier_standard") then
            local base = _item:getModData().scriptStats or {}
            local si = _item:getScriptItem()
            local baseName = base.ScriptName or (si and si:getDisplayName())
            if baseName then
                local expectedName = baseName .. " [" .. modifier.modifierName .. "]"
                if _item:getName() ~= expectedName then
                    _item:setName(expectedName)
                    _item:setCustomName(true)
                end
            end
        end
    end
    if modifier and modifier.statsMultipliers then
        local mult = modifier.statsMultipliers
        local base = _item:getModData().scriptStats or {}
        if mult["noise mod"] and base.NoiseMod then
            safeSet(_item, "setNoiseMod", base.NoiseMod * mult["noise mod"])
        end
        if mult["run speed"] and base.RunSpeedModifier then
            safeSet(_item, "setRunSpeedModifier", base.RunSpeedModifier * mult["run speed"])
        end
        if base.ConditionMax then
            local durMult = mult["durability"] or 1
            local newMax = math.max(1, math.floor(base.ConditionMax * durMult))
            local curMax = type(_item.getConditionMax) == "function" and (_item:getConditionMax() or base.ConditionMax) or base.ConditionMax
            local curCond = type(_item.getCondition) == "function" and (_item:getCondition() or curMax) or curMax
            local ratio = curMax > 0 and (curCond / curMax) or 1
            safeSet(_item, "setConditionMax", newMax)
            safeSet(_item, "setCondition", math.max(0, math.min(newMax, math.floor(ratio * newMax + 0.5))))
        end
        if mult["scratch defense"] and base.ScratchDefense then
            safeSet(_item, "setScratchDefense", math.max(0, math.floor(base.ScratchDefense + mult["scratch defense"])))
        end
        if mult["bite defense"] and base.BiteDefense then
            safeSet(_item, "setBiteDefense", math.max(0, math.floor(base.BiteDefense + mult["bite defense"])))
        end
        if mult["bullet defense"] and base.BulletDefense then
            safeSet(_item, "setBulletDefense", math.max(0, math.floor(base.BulletDefense + mult["bullet defense"])))
        end
        if mult["combat speed"] and base.CombatSpeedModifier then
            safeSet(_item, "setCombatSpeedModifier", base.CombatSpeedModifier * mult["combat speed"])
        end
    end
end

function RGMManager.applyFlashlightStats(_item)
    if not _item then return end
    local modifier = _item:getModData().modifier
    if not modifier then return end
    modifier = RGMManager.resolveModifierName(_item)
    if modifier.modifierName and modifier.translationChecked and modifier.modifierName ~= getText("Tooltip_modifier_standard") then
        local base = _item:getModData().scriptStats or {}
        local si = type(_item.getScriptItem) == "function" and _item:getScriptItem() or nil
        local baseName = base.ScriptName or (si and si:getDisplayName()) or _item:getDisplayName()
        local expectedName = baseName .. " [" .. modifier.modifierName .. "]"
        if _item:getName() ~= expectedName then
            _item:setName(expectedName)
            _item:setCustomName(true)
        end
    end
    if not modifier.statsMultipliers then return end
    local mult = modifier.statsMultipliers
    local base = _item:getModData().scriptStats or {}
    if mult["light"] and mult["light"] ~= 1 then
        if base.LightDistance and base.LightDistance > 0 then
            safeSet(_item, "setLightDistance", math.max(0.1, base.LightDistance * mult["light"]))
        end
        if base.LightStrength and base.LightStrength > 0 then
            safeSet(_item, "setLightStrength", math.max(0.1, base.LightStrength * mult["light"]))
        end
    end
    if mult["battery"] and mult["battery"] ~= 1 and base.UseDelta and base.UseDelta > 0 then
        safeSet(_item, "setUseDelta", math.max(0.00001, base.UseDelta * mult["battery"]))
    end
    local durMult = mult["durability"] or 1
    if base.ConditionLowerChance then
        safeSet(_item, "setConditionLowerChance", math.max(1, math.floor(base.ConditionLowerChance * durMult + 0.5)))
    end
    if base.ConditionMax then
        local newMax = math.max(1, math.floor(base.ConditionMax * durMult))
        local curMax = type(_item.getConditionMax) == "function" and (_item:getConditionMax() or base.ConditionMax) or base.ConditionMax
        local curCond = type(_item.getCondition) == "function" and (_item:getCondition() or curMax) or curMax
        local ratio = curMax > 0 and (curCond / curMax) or 1
        safeSet(_item, "setConditionMax", newMax)
        safeSet(_item, "setCondition", math.max(0, math.min(newMax, math.floor(ratio * newMax + 0.5))))
    end
end

function RGMManager.applyMagazineStats(_item)
    if not _item then return end
    local modifier = _item:getModData().modifier
    if not modifier or not modifier.statsMultipliers then return end
    modifier = RGMManager.resolveModifierName(_item) or modifier
    -- Apply MaxAmmo only when base is known; never fall back to getMaxAmmo() (already modified)
    local pct = modifier.statsMultipliers["max ammo pct"] or 1
    if pct ~= 1 then
        local base = (_item:getModData().scriptStats or {}).MaxAmmo or 0
        if base > 0 then
            local newMax = math.max(1, math.floor(base * pct + 0.5))
            pcall(function() _item:setMaxAmmo(newMax) end)
            if type(_item.getCurrentAmmo) == "function" then
                local cur = _item:getCurrentAmmo()
                if cur and cur > newMax then
                    pcall(function() _item:setCurrentAmmo(newMax) end)
                end
            end
        end
    end
    -- Update name independently of MaxAmmo. Use ScriptItem name, never getDisplayName()
    -- (getDisplayName may already contain the modifier suffix, causing duplication).
    if modifier.translationChecked then
        local si = type(_item.getScriptItem) == "function" and _item:getScriptItem() or nil
        local baseName = (_item:getModData().scriptStats or {}).ScriptName
            or (si and type(si.getDisplayName) == "function" and si:getDisplayName() or nil)
        if baseName then
            local expectedName = baseName .. " [" .. modifier.modifierName .. "]"
            if _item:getName() ~= expectedName then
                _item:setName(expectedName)
                _item:setCustomName(true)
            end
        end
    end
end

-- Capture magazine modifier at INSERT time (before magazine item is consumed).
-- Stores it in gun modData so it can be restored on eject (PZ creates a fresh item via instanceItem).
if ISInsertMagazine then
    local _RGM_origLoadAmmo = ISInsertMagazine.loadAmmo
    ISInsertMagazine.loadAmmo = function(self)
        if self.gun and self.magazine then
            local mod = self.magazine:getModData().modifier
            if mod then
                self.gun:getModData().rgm_lastMagMod  = mod
                self.gun:getModData().rgm_lastMagBase = (self.magazine:getModData().scriptStats or {}).MaxAmmo or self.magazine:getMaxAmmo()
            else
                self.gun:getModData().rgm_lastMagMod  = nil
                self.gun:getModData().rgm_lastMagBase = nil
            end
            if type(self.gun.transmitModData) == "function" then self.gun:transmitModData() end
        end
        _RGM_origLoadAmmo(self)
    end
end

-- Restore magazine modifier on eject. PZ creates a brand-new item via instanceItem() which has
-- no modData. We restore it from rgm_lastMagMod and send a server command so the client can
-- immediately apply translated name and MaxAmmo (getText works in client-Lua, not server-Lua).
if ISEjectMagazine then
    local _RGM_origUnload = ISEjectMagazine.unloadAmmo
    ISEjectMagazine.unloadAmmo = function(self)
        local storedMod  = self.gun and self.gun:getModData().rgm_lastMagMod
        local storedBase = self.gun and self.gun:getModData().rgm_lastMagBase

        _RGM_origUnload(self)

        if not storedMod then return end

        local inv = self.character and type(self.character.getInventory) == "function" and self.character:getInventory()
        if not inv then return end
        local items = type(inv.getItems) == "function" and inv:getItems()
        if not items then return end

        -- Find the newly created magazine (no modifierChecked = fresh instanceItem)
        for i = items:size() - 1, 0, -1 do
            local item = items:get(i)
            if item
                and not item:getModData().modifierChecked
                and type(item.getAmmoType) == "function" and item:getAmmoType() ~= nil
                and not (type(item.isRanged) == "function" and item:isRanged())
            then
                local scriptMax = storedBase or item:getMaxAmmo() or 0
                if scriptMax > 0 then
                    local pct = storedMod.statsMultipliers and (storedMod.statsMultipliers["max ammo pct"] or 1) or 1
                    local newMax = math.max(1, math.floor(scriptMax * pct + 0.5))
                    local si = type(item.getScriptItem) == "function" and item:getScriptItem()
                    local baseName = (si and si:getDisplayName()) or item:getDisplayName()
                    item:getModData().modifier    = storedMod
                    item:getModData().scriptStats = { MaxAmmo = scriptMax, ScriptName = baseName }
                    item:getModData().modifierChecked = true
                    pcall(function() item:setMaxAmmo(newMax) end)
                    local resolvedMod = type(RGMManager.resolveModifierName) == "function" and RGMManager.resolveModifierName(item) or storedMod
                    if resolvedMod and resolvedMod.translationChecked then
                        item:setName(baseName .. " [" .. resolvedMod.modifierName .. "]")
                        item:setCustomName(true)
                    end
                    if type(item.transmitModData) == "function" then item:transmitModData() end
                    if type(sendServerCommand) == "function"
                        and self.character and instanceof(self.character, "IsoPlayer")
                    then
                        sendServerCommand(self.character, "RGM", "ApplyMagStats", {
                            modifierName     = storedMod.modifierName,
                            statsMultipliers = storedMod.statsMultipliers,
                            fontColor        = storedMod.fontColor,
                            scriptMaxAmmo    = scriptMax,
                            scriptName       = baseName,
                        })
                    end
                end
                break
            end
        end
    end
end

