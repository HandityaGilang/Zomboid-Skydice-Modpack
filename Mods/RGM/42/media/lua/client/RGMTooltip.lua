require "ISUI/ISToolTipInv"

-- B42: ISToolTipInv still exists but guard against missing methods
if not ISToolTipInv then return end

local WMT = {}

WMT.stage = 1
WMT.numRows = 0
WMT.old_y = 0
WMT.isContainer = false
WMT.isMagazine = false

WMT.item = nil
WMT.modifierName = ""
WMT.fullItemName = ""
WMT.modifierColors = {1, 1, 1}
WMT.modifier = {}
WMT.damageText = nil
WMT.rangeText = nil
WMT.hitText = nil
WMT.critText = nil
WMT.condText = nil
WMT.breakText = nil
WMT.accText = nil
WMT.gunText = nil
WMT.soundRadiusText = nil
WMT.pushBackText = nil
WMT.speedText = nil
WMT.weaponText = "TET"
WMT.swingAimToSpeed = {
    ["Bat"] = 1,
    ["Heavy"] = 0.6,
    ["Stab"] = 1.13,
    ["Spear"] = 1.13,
}
WMT.statsRange = {
    ["accuracy"] = 1,
    ["sound radius"] = 1,
    ["recoil"] = 1,
    ["aim time"] = 1,
    ["reload time"] = 1,
    ["max ammo add"] = 1,
    ["max ammo pct"] = 1,
}
WMT.statsMelee = {
    ["endurance cost"] = 1,
    ["attack speed"] = 1,
    ["knockback"] = 1,
}
WMT.statsGoodWhenNegative = {
    ["minimum range"] = 1,
    ["endurance cost"] = 1,
    ["weight"] = 1,
    ["sound radius"] = 1,
    ["recoil"] = 1,
    ["aim time"] = 1,
    ["reload time"] = 1,
    ["noise mod"] = 1,
    ["jam chance"] = 1,
    ["battery"] = 1,
}

WMT.statsTranslation = {
    damage = "Tooltip_modifier_damage",
    speed = "Tooltip_modifier_attack_speed",
    ["attack speed"] = "Tooltip_modifier_attack_speed",
    ["critical chance"] = "Tooltip_modifier_crit",
    ["minimum range"] = "Tooltip_modifier_minrange",
    ["maximum range"] = "Tooltip_modifier_maxrange",
    knockback = "Tooltip_modifier_knockback",
    ["endurance cost"] = "Tooltip_modifier_endurance_cost",
    ["durability"] = "Tooltip_modifier_durability",
    weight = "Tooltip_modifier_weight",
    accuracy = "Tooltip_modifier_accuracy",
    ["sound radius"] = "Tooltip_modifier_noise",
    recoil = "Tooltip_modifier_recoil",
    ["reload time"] = "Tooltip_modifier_reload_time",
    ["aim time"] = "Tooltip_modifier_aim_time",
    experience = "Tooltip_modifier_experience",
    capacity = "Tooltip_modifier_capacity",
    ["weight reduction"] = "Tooltip_modifier_weight_reduction",
    ["capacity pct"] = "Tooltip_modifier_capacity",
    ["noise mod"] = "Tooltip_modifier_footwear_noise",
    ["run speed"] = "Tooltip_modifier_run_speed",
    ["jam chance"] = "Tooltip_modifier_jam_chance",
    ["light"] = "Tooltip_modifier_light",
    ["battery"] = "Tooltip_modifier_battery",
    ["max ammo add"] = "Tooltip_modifier_max_ammo",
    ["max ammo pct"] = "Tooltip_modifier_max_ammo",
    ["scratch defense"] = "Tooltip_modifier_scratch_defense",
    ["bite defense"] = "Tooltip_modifier_bite_defense",
    ["bullet defense"] = "Tooltip_modifier_bullet_defense",
    ["combat speed"] = "Tooltip_modifier_combat_speed",
    ["reading speed"] = "Tooltip_modifier_reading_speed",
}

function WMT.round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function WMT.setHeight(self, num, ...)
    if WMT.stage == 1 then
        WMT.stage = 2
        if not self.followMouse and self.anchorBottomLeft then
            local my = self.anchorBottomLeft.y
            local y = 0
            if WMT.modifier and WMT.modifier.modifierName and WMT.modifier.modifierName ~= getText("Tooltip_modifier_standard") then
                if not WMT.isContainer and type(self.item.isRanged) == "function" and self.item:isRanged() then
                    y = y + 2;
                    if self.item:getMagazineType() ~= nil then y = y + 1; end
                    if self.item:getFireMode() ~= nil then y = y + 1; end
                    if self.item:getAllWeaponParts():size() > 0 then
                        y = y + self.item:getAllWeaponParts():size() + 1
                    end
                end
                if self.item:getModID() ~= "pz-vanilla" then y = y + 1 end
                if not WMT.isContainer and type(self.item.isTwoHandWeapon) == "function" and self.item:isTwoHandWeapon() then y = y + 1 end
                self.tooltip:setY(my - (WMT.numRows + y) * self.tooltip:getLineSpacing());
            else
                if not WMT.isContainer and type(self.item.isRanged) == "function" and self.item:isRanged() then
                    y = y + 2;
                    if self.item:getMagazineType() ~= nil then y = y + 1; end
                    if self.item:getFireMode() ~= nil then y = y + 1; end
                    if self.item:getAllWeaponParts():size() > 0 then
                        y = y + self.item:getAllWeaponParts():size() + 1
                    end
                end
                if self.item:getModID() ~= "pz-vanilla" then y = y + 1 end
                if self.item:isTwoHandWeapon() then y = y + 1 end
                self.tooltip:setY(my - (WMT.numRows + y) * self.tooltip:getLineSpacing());
            end
        elseif self.followMouse and WMT.numRows > 0 then
            -- followMouse mode (e.g. Icons Inventory): vanilla clamping used original height
            -- without extra RGM rows, so the modifier text may be cut off at the screen bottom.
            -- Re-clamp tooltip position using the full height including RGM rows.
            local totalHeight = num + WMT.numRows * self.tooltip:getLineSpacing()
            local screenH = getCore():getScreenHeight()
            local curY = self.tooltip:getY()
            if curY + totalHeight > screenH - 1 then
                local newY = math.max(0, screenH - totalHeight - 1)
                self.tooltip:setY(newY)
                self:setY(newY)
            end
        end
        WMT.old_y = num
        num = num + WMT.numRows * self.tooltip:getLineSpacing()
    else
        WMT.stage = -1
    end
    return ISToolTipInv.setHeight(self, num, ...)
end

WMT.ISToolTipInv = {}
WMT.ISToolTipInv.render = ISToolTipInv.render
WMT.ISToolTipInv.setHeight = ISToolTipInv.setHeight
WMT.ISToolTipInv.drawRectBorder = ISToolTipInv.drawRectBorder

-- Guard: if B42 removed any of these, skip the entire tooltip extension
if not WMT.ISToolTipInv.render or not WMT.ISToolTipInv.setHeight or not WMT.ISToolTipInv.drawRectBorder then
    return
end

WMT.newDrawRectBorder = function(self, ...)
    if WMT.numRows > 0 then
        local lineSpacing = self.tooltip:getLineSpacing()
        local linePosition = lineSpacing
        local font = UIFont[getCore():getOptionTooltipFont()];
        if WMT.modifier and WMT.modifier.statsMultipliers then
            linePosition = linePosition + lineSpacing/2
            self.tooltip:DrawText(font, WMT.fullItemName, 5, WMT.old_y + lineSpacing/2, WMT.modifierColors[1], WMT.modifierColors[2], WMT.modifierColors[3], 1);
            if WMT.modifier.modifierName ~= getText("Tooltip_modifier_standard") then
                for k,v in pairs(WMT.modifier.statsMultipliers) do
                    local text, currentColor;
                    if k:sub(1, 3) == "xp " then
                        local perkName = k:sub(4)
                        local pct = math.floor(v * 100 + 0.5)
                        local perkDisplay = getText("IGUI_modifier_xp_perk_" .. perkName)
                        text = " +" .. pct .. "% " .. perkDisplay .. " " .. getText("Tooltip_modifier_xp_bonus")
                        currentColor = RarityColors.positiveStats
                    elseif k == "critical chance" then
                        if v >= 0 then
                            text = " +".. v .. " % " .. getText(WMT.statsTranslation[k])
                            currentColor = RarityColors.positiveStats
                        else
                            text = " ".. v .. " % " .. getText(WMT.statsTranslation[k])
                            currentColor = RarityColors.negativeStats
                        end
                    elseif k == "weight" or k == "capacity pct" or k == "scratch defense" or k == "bite defense" or k == "bullet defense" or k == "max ammo add" then
                        -- handled below with container-specific labels
                    elseif not WMT.isContainer and (WMT.statsRange[k] and not self.item:isRanged() or WMT.statsMelee[k] and self.item:isRanged()) then
                        break
                    else
                        if v >= 1 then
                            text = " +"..WMT.round(v*100-100,2) .. " % " .. getText(WMT.statsTranslation[k])
                            currentColor = WMT.statsGoodWhenNegative[k] and RarityColors.negativeStats or RarityColors.positiveStats
                        else
                            text = " "..WMT.round(v*100-100,2) .. " % " .. getText(WMT.statsTranslation[k])
                            currentColor = WMT.statsGoodWhenNegative[k] and RarityColors.positiveStats or RarityColors.negativeStats
                        end
                    end
                    if k == "capacity" or k == "weight reduction" or k == "scratch defense" or k == "bite defense" or k == "bullet defense" or k == "max ammo add" then
                        if v >= 0 then
                            text = " +".. v .. " " .. getText(WMT.statsTranslation[k])
                            currentColor = RarityColors.positiveStats
                        else
                            text = " ".. v .. " " .. getText(WMT.statsTranslation[k])
                            currentColor = RarityColors.negativeStats
                        end
                    end
                    -- percentage stats with container-specific labels
                    if k == "weight" then
                        local pct = WMT.round(v*100-100, 0)
                        local weightLabel = WMT.isMagazine and getText("Tooltip_modifier_weight") or getText("Tooltip_modifier_container_weight")
                        if pct >= 0 then
                            text = " +".. pct .. "% " .. weightLabel
                            currentColor = RarityColors.negativeStats
                        else
                            text = " ".. pct .. "% " .. weightLabel
                            currentColor = RarityColors.positiveStats
                        end
                    end
                    if k == "capacity pct" then
                        local pct = WMT.round(v*100-100, 0)
                        if pct >= 0 then
                            text = " +".. pct .. "% " .. getText("Tooltip_modifier_container_capacity")
                            currentColor = RarityColors.positiveStats
                        else
                            text = " ".. pct .. "% " .. getText("Tooltip_modifier_container_capacity")
                            currentColor = RarityColors.negativeStats
                        end
                    end
                    self.tooltip:DrawText(font, text, 5, WMT.old_y + linePosition, currentColor[1], currentColor[2], currentColor[3], 1);
                    linePosition = linePosition + lineSpacing;
                end
            end
        else
            linePosition = linePosition - lineSpacing;
        end

        if not WMT.isContainer then
            linePosition = linePosition + lineSpacing/2;
            local color = RarityColors.infoStats
            self.tooltip:DrawText(font, WMT.weaponText, 5, WMT.old_y + linePosition, color[1], color[2], color[3], 1);
            linePosition = linePosition + lineSpacing;
            self.tooltip:DrawText(font, WMT.damageText, 5, WMT.old_y + linePosition, color[1], color[2], color[3], 1);
            linePosition = linePosition + lineSpacing;
            if type(self.item.isRanged) == "function" and not self.item:isRanged() then
                self.tooltip:DrawText(font, WMT.speedText, 5, WMT.old_y + linePosition, color[1], color[2], color[3], 1);
                linePosition = linePosition + lineSpacing;
                self.tooltip:DrawText(font, WMT.pushBackText, 5, WMT.old_y + linePosition, color[1], color[2], color[3], 1);
                linePosition = linePosition + lineSpacing;
            end
            self.tooltip:DrawText(font, WMT.rangeText, 5, WMT.old_y + linePosition, color[1], color[2], color[3], 1);
            linePosition = linePosition + lineSpacing;
            self.tooltip:DrawText(font, WMT.critText, 5, WMT.old_y + linePosition, color[1], color[2], color[3], 1);
            linePosition = linePosition + lineSpacing;
            if type(self.item.isRanged) == "function" and self.item:isRanged() then
                self.tooltip:DrawText(font, WMT.accText, 5, WMT.old_y + linePosition, color[1], color[2], color[3], 1);
                linePosition = linePosition + lineSpacing;
                self.tooltip:DrawText(font, WMT.gunText, 5, WMT.old_y + linePosition, color[1], color[2], color[3], 1);
                linePosition = linePosition + lineSpacing;
                self.tooltip:DrawText(font, WMT.soundRadiusText, 5, WMT.old_y + linePosition, color[1], color[2], color[3], 1);
                linePosition = linePosition + lineSpacing;
            else
                self.tooltip:DrawText(font, WMT.enduranceText, 5, WMT.old_y + linePosition, color[1], color[2], color[3], 1);
                linePosition = linePosition + lineSpacing;
            end
            self.tooltip:DrawText(font, WMT.condText, 5, WMT.old_y + linePosition, color[1], color[2], color[3], 1);
            linePosition = linePosition + lineSpacing;
            self.tooltip:DrawText(font, WMT.breakText, 5, WMT.old_y + linePosition, color[1], color[2], color[3], 1);
            linePosition = linePosition + lineSpacing;
        end

        WMT.isContainer = false
        WMT.isMagazine = false
        WMT.stage = 3
    else
        WMT.stage = -1
    end
    return ISToolTipInv.drawRectBorder(self, ...)
end


function ISToolTipInv:render()
    WMT.numRows = 0
    if self.item ~= nil then
        local item = self.item
        local player = getPlayer() or getSpecificPlayer(0)
        if item and type(item.getDisplayCategory) == "function" and item:getDisplayCategory() == "LightSource" then
            local showMod = item:getModData().modifierChecked
            if not showMod then
                return WMT.ISToolTipInv.render(self)
            end
            WMT.isContainer = true
            WMT.modifier = item:getModData().modifier
            if WMT.modifier and WMT.modifier.modifierName then
                WMT.modifierName = WMT.modifier.modifierName
                WMT.numRows = WMT.numRows + 1.5
                WMT.modifierColors = WMT.modifier.fontColor or {1, 1, 1}
                if WMT.modifier.statsMultipliers then
                    for k, v in pairs(WMT.modifier.statsMultipliers) do
                        WMT.numRows = WMT.numRows + 1
                    end
                end
            else
                WMT.modifierName = getText("Tooltip_modifier_standard")
                WMT.modifierColors = {1, 1, 1}
            end
            WMT.fullItemName = item:getDisplayName()
        elseif item and instanceof(item, "HandWeapon") then
            if item:getSwingAnim() == "Throw" then
                return WMT.ISToolTipInv.render(self)
            end
            WMT.modifier = item:getModData().modifier
            if WMT.modifier then
                WMT.modifierName = WMT.modifier.modifierName or getText("Tooltip_modifier_standard");
                WMT.numRows = WMT.numRows + 1.5
                WMT.modifierColors = WMT.modifier.fontColor or {1, 1, 1}
                for k, v in pairs(WMT.modifier.statsMultipliers) do
                    if not (WMT.statsRange[k] and not item:isRanged()) and not (WMT.statsMelee[k] and item:isRanged()) then
                        WMT.numRows = WMT.numRows + 1
                    end
                end
            else
                WMT.modifierName = getText("Tooltip_modifier_standard")
                WMT.modifierColors = {1, 1, 1}
            end
            WMT.fullItemName = item:getDisplayName()
            local weaponLevel = 0
            -- B42: getPerk() returns perk/category name directly
            local perk = type(item.getPerk) == "function" and tostring(item:getPerk()) or nil
            if perk == "Axe" then
                weaponLevel = player:getPerkLevel(Perks.Axe)
                WMT.weaponText = getText("Tooltip_modifier_type")..": "..getText("IGUI_perks_Axe")
            elseif perk == "LongBlade" then
                weaponLevel = player:getPerkLevel(Perks.LongBlade)
                WMT.weaponText = getText("Tooltip_modifier_type")..": "..getText("IGUI_perks_LongBlade")
            elseif perk == "SmallBlade" then
                weaponLevel = player:getPerkLevel(Perks.SmallBlade)
                WMT.weaponText = getText("Tooltip_modifier_type")..": "..getText("IGUI_perks_SmallBlade")
            elseif perk == "SmallBlunt" then
                weaponLevel = player:getPerkLevel(Perks.SmallBlunt)
                WMT.weaponText = getText("Tooltip_modifier_type")..": "..getText("IGUI_perks_SmallBlunt")
            elseif perk == "Blunt" then
                weaponLevel = player:getPerkLevel(Perks.Blunt)
                WMT.weaponText = getText("Tooltip_modifier_type")..": "..getText("IGUI_perks_Blunt")
            elseif perk == "Spear" then
                weaponLevel = player:getPerkLevel(Perks.Spear)
                WMT.weaponText = getText("Tooltip_modifier_type")..": "..getText("IGUI_perks_Spear")
            elseif perk == "Aiming" then
                WMT.weaponText = getText("Tooltip_modifier_type")..": "..getText("IGUI_perks_Firearm")
            else
                WMT.weaponText = getText("Tooltip_modifier_type")..": "..getText("IGUI_category_unknown")
            end

            local minDamage = WMT.round(item:getMinDamage(), 3)
            local maxDamage = WMT.round(item:getMaxDamage(), 3)
            local bonusDamage = 75 + 5 * player:getPerkLevel(Perks.Strength)
            if RSW_hasTrait(player, "Strong") then
                bonusDamage = bonusDamage*1.4
            elseif RSW_hasTrait(player, "Weak") then
                bonusDamage = bonusDamage*0.6
            end
            bonusDamage = bonusDamage - 100
            local minRange;
            local maxRange = WMT.round(item:getMaxRange(), 3)

            if item:isRanged() then
                minRange = WMT.round(item:getMinRangeRanged(), 3)
            else
                minRange = WMT.round(item:getMinRange(), 3)
            end
            local critChance = WMT.round(item:getCriticalChance(), 3)
            -- B42: getCritDmgMultiplier may not exist
            local critDmg = type(item.getCritDmgMultiplier) == "function" and WMT.round(item:getCritDmgMultiplier(), 3) or 1
            local condition = item:getCondition()
            local conditionMax = item:getConditionMax()
            -- B42: getConditionLowerChance may not exist
            local conditionLowerChance = type(item.getConditionLowerChance) == "function" and item:getConditionLowerChance() or 0
            WMT.numRows = WMT.numRows + 5
            WMT.damageText = getText("Tooltip_weapon_Damage")..": " .. minDamage .. " - " .. maxDamage .. " (x" .. 30+weaponLevel*10 .."% +".. bonusDamage.."%)"
            WMT.rangeText = getText("Tooltip_weapon_Range")..": " .. minRange .. " - " .. maxRange
            WMT.critText = getText("Tooltip_item_stats_crit")..": " .. critChance .. "% (+" .. 3*weaponLevel .. "%), x" .. critDmg
            WMT.condText = getText("Tooltip_weapon_Condition")..": " .. condition .. "/" .. conditionMax
            if item:isRanged() then
                WMT.weaponText = getText("Tooltip_modifier_type")..": ".. getText("IGUI_perks_Firearm")
                weaponLevel = player:getPerkLevel(Perks.Aiming)
                local hitChance = item:getHitChance()
                local aimingTime = item:getAimingTime()
                local reloadTime = item:getReloadTime()
                local recoilDelay = item:getRecoilDelay()
                local critModifier = item:getAimingPerkCritModifier()
                local hitChanceModifier = item:getAimingPerkHitChanceModifier()
                local rangeModifier = item:getAimingPerkRangeModifier()
                local soundRadius = item:getSoundRadius()

                WMT.critText = getText("Tooltip_item_stats_crit")..": " .. critChance .. "% (+" .. critModifier*weaponLevel .. "%), " .. critDmg .. "x"
                WMT.rangeText = WMT.rangeText .. "(+" .. rangeModifier*weaponLevel .. ")"
                WMT.accText = getText("Tooltip_item_stats_accuracy")..": " .. hitChance .. "% (+" .. hitChanceModifier*weaponLevel .. ")%"
                WMT.gunText = getText("Tooltip_item_stats_recoil_aim_reload")..": " .. aimingTime .. "/" .. reloadTime .. "/" .. recoilDelay
                WMT.soundRadiusText = getText("Tooltip_item_stats_sound_radius")..": ".. soundRadius .. " "..getText("Tooltip_item_stats_tiles")
                WMT.numRows = WMT.numRows + 3
            else
                local swingAnimSpeed = WMT.swingAimToSpeed[item:getSwingAnim()] or 1
                local enduranceMod = item:getEnduranceMod()
                local speed = item:getBaseSpeed()*swingAnimSpeed
                local bonusSpeed = player:getPerkLevel(Perks.Fitness)*2 + weaponLevel*3
                local bonusKnockback = -25 + 5*player:getPerkLevel(Perks.Strength)
                WMT.pushBackText = getText("Tooltip_item_stats_knockback")..": "..WMT.round(item:getPushBackMod(), 3) .. "(+"..bonusKnockback .."%)"
                WMT.speedText = getText("Tooltip_item_stats_attack_speed")..": ".. WMT.round(speed, 3) .. " (+"..bonusSpeed.."%)"
                WMT.enduranceText = getText("Tooltip_item_stats_endurance_used")..": x".. WMT.round(enduranceMod, 3)
                WMT.numRows = WMT.numRows + 3
            end

            local bonusConditionLowerChance = math.floor((player:getPerkLevel(Perks.Maintenance) + math.floor(weaponLevel/2))/2)*2
            WMT.numRows = WMT.numRows + 2
            WMT.breakText = getText("Tooltip_item_stats_break_chance")..": "..getText("Tooltip_item_stats_break_chance_one_in").." " .. conditionLowerChance .. " (+"..bonusConditionLowerChance..")"

        elseif item and instanceof(item, "InventoryContainer") then
            WMT.isContainer = true
            WMT.modifier = item:getModData().modifier
            if WMT.modifier and WMT.modifier.modifierName then
                WMT.modifierName = WMT.modifier.modifierName
                WMT.numRows = WMT.numRows + 1.5
                WMT.modifierColors = WMT.modifier.fontColor or {1, 1, 1}
                if WMT.modifier.statsMultipliers then
                    for k, v in pairs(WMT.modifier.statsMultipliers) do
                        WMT.numRows = WMT.numRows + 1
                    end
                end
            else
                WMT.modifierName = getText("Tooltip_modifier_standard")
                WMT.modifierColors = {1, 1, 1}
            end
            WMT.fullItemName = item:getDisplayName()
        elseif item and instanceof(item, "Clothing") then
            local bodyLoc = type(item.getBodyLocation) == "function" and item:getBodyLocation() or nil
            local bodyLocStr = bodyLoc and tostring(bodyLoc) or ""
            local isShoe = bodyLocStr == "Shoes"
                or bodyLocStr:lower():find("shoe") ~= nil
                or bodyLocStr:lower():find("boot") ~= nil
            local showModifier = item:getModData().modifierChecked
                and SandboxVars.RGM and SandboxVars.RGM.ClothingModifiers
            if showModifier then
                WMT.isContainer = true
                WMT.modifier = item:getModData().modifier
                if WMT.modifier and WMT.modifier.modifierName then
                    WMT.modifierName = WMT.modifier.modifierName
                    WMT.numRows = WMT.numRows + 1.5
                    WMT.modifierColors = WMT.modifier.fontColor or {1, 1, 1}
                    if WMT.modifier.statsMultipliers then
                        for k, v in pairs(WMT.modifier.statsMultipliers) do
                            WMT.numRows = WMT.numRows + 1
                        end
                    end
                else
                    WMT.modifierName = getText("Tooltip_modifier_standard")
                    WMT.modifierColors = {1, 1, 1}
                end
                WMT.fullItemName = item:getDisplayName()
            else
                return WMT.ISToolTipInv.render(self)
            end
        elseif item and type(item.getAmmoType) == "function" and item:getAmmoType() ~= nil
            and type(item.getMaxAmmo) == "function" and (item:getMaxAmmo() or 0) > 0
            and not (type(item.isRanged) == "function" and item:isRanged())
            and item:getModData().modifierChecked
        then
            WMT.isContainer = true
            WMT.isMagazine = true
            WMT.modifier = item:getModData().modifier
            if WMT.modifier and WMT.modifier.modifierName then
                WMT.modifierName = WMT.modifier.modifierName
                WMT.numRows = WMT.numRows + 1.5
                WMT.modifierColors = WMT.modifier.fontColor or {1, 1, 1}
                if WMT.modifier.statsMultipliers then
                    for k, v in pairs(WMT.modifier.statsMultipliers) do
                        WMT.numRows = WMT.numRows + 1
                    end
                end
            else
                WMT.modifierName = getText("Tooltip_modifier_standard")
                WMT.modifierColors = {1, 1, 1}
            end
            WMT.fullItemName = item:getDisplayName()
        else
            return WMT.ISToolTipInv.render(self)
        end
    end

    WMT.stage = 1
    self.setHeight = WMT.setHeight
    self.drawRectBorder = WMT.newDrawRectBorder
    WMT.ISToolTipInv.render(self)
    self.setHeight = nil
    self.drawRectBorder = nil
end

-- Re-install our tooltip hook if another mod overwrote ISToolTipInv.render after us.
local RGM_tooltip_render = ISToolTipInv.render
local rgm_tooltip_tick = 0
Events.OnTick.Add(function()
    rgm_tooltip_tick = rgm_tooltip_tick + 1
    if rgm_tooltip_tick < 120 then return end
    rgm_tooltip_tick = 0
    if ISToolTipInv and ISToolTipInv.render ~= RGM_tooltip_render then
        ISToolTipInv.render = RGM_tooltip_render
    end
end)

return WMT
