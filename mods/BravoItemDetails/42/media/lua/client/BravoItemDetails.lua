-- get the config
local config = require("BravoItemDetailsConfig")

--- Get the color for a progress bar used to display an items condition or uses
--
-- @param fraction float Between 0 and 1
-- @param highGood bool True if a high value of fraction corresponds to a good value, false othervise
-- @return table with RGB values calculated depending on the fraction given
local function getRGB(fraction, highGood)
    local color = ColorInfo.new(0, 0, 0, 1)
	if highGood then
		getCore():getBadHighlitedColor():interp(getCore():getGoodHighlitedColor(), fraction, color)
	else
		getCore():getGoodHighlitedColor():interp(getCore():getBadHighlitedColor(), fraction, color)
	end

    return {r = color:getR(), g = color:getG(), b = color:getB(), a = 1}
end

local oldDrawItemDetails = ISInventoryPane.drawItemDetails;
function ISInventoryPane:drawItemDetails(item, y, xoff, yoff, red)

    -- return vanilla/orginal function
    if item == nil or (config.showLabels == false and config.showBars == false and config.showNumeric == false) then return oldDrawItemDetails(self, item, y, xoff, yoff, red) end

    -- TODO some "caching" would be nice
    local ghc = getCore():getGoodHighlitedColor()
    local bhc = getCore():getBadHighlitedColor()
    local fgBar = {r = ghc:getR(), g = ghc:getG(), b = ghc:getB(), a = 1}
    local fgText = {r = 0.6, g = 0.6, b = 0.8, a = 0.5}
    if red then fgText = {r = bhc:getR(), g = bhc:getG(), b = bhc:getB(), a = 0.5} end

    -- itemHgt = 31, fontHgt = 23
    local hdrHgt = self.headerHgt
    local top = hdrHgt + y * self.itemHgt + yoff

    local spacer = 10
    local currentX = xoff + 40 + 30 -- magical numbers
    local pbHeight = 3 -- progress bar height
    local pbWidth = 80 -- progress bar width

    local textY = (self.itemHgt - self.fontHgt) / 2
    local pbY = (self.itemHgt - pbHeight) / 2 + 1
    local iconSize = self.itemHgt - 4
    local iconY = (self.itemHgt - iconSize) / 2

    -- items which have uses/max TODO: not item:hasTag("HideRemaining")
    if (instanceof(item, "Drainable") and item:getUseDelta() > 0) then
        local currentUses = item:getCurrentUses()
        local maxUses = item:getMaxUses()
        local fraction = currentUses / maxUses --item:getCurrentUsesFloat() some items like small battery dont spawn with this set to exactly 1
        local percent = round(fraction * 100)

        -- label "Remaining"
        if config.showLabels == true then
            local label = getText("IGUI_invpanel_Remaining") .. ":"
            local labelWidth = getTextManager():MeasureStringX(self.font, label)
            self:drawText(label, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
            -- update current x position
            currentX = currentX + labelWidth + spacer
        end

        -- progress bar
        if config.showBars == true then
            self:drawProgressBar(currentX, top + pbY, pbWidth, pbHeight, fraction, getRGB(fraction, true))
            -- update current x position
            currentX = currentX + pbWidth + spacer
        end

        -- uses/max or % text
        if config.showNumeric then
            local usesText, usesTextMax
            -- if maxUses is bigger than 100, show the percentage instead of uses/max
            if item:getMaxUses() > 100 then
                usesText = percent .. "%"
                usesTextMax = '100%'
            else
                usesText = currentUses .. "/" .. maxUses
                usesTextMax = maxUses .. "/" .. maxUses
            end
            local usesTextWidth = getTextManager():MeasureStringX(self.font, usesText)
            local usesTextMaxWidth = getTextManager():MeasureStringX(self.font, usesTextMax)
            -- update before to right align the text
            currentX = currentX + usesTextMaxWidth - usesTextWidth
            self:drawText(usesText, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
            -- update current x position
            currentX = currentX + usesTextWidth + spacer
        end

        -- new experimental compact view under development
        if false then
            local completeText = (percent < 100 and "  " or "") .. percent .. '%'
            local completeTextWidth = getTextManager():MeasureStringX(self.font, completeText)

            self:drawProgressBar(currentX, top + textY + 1, completeTextWidth + 10, self.fontHgt, 1, getRGB(fraction, true))
            self:drawText(completeText, currentX + 5, top + textY, 0.1, 0.1, 0.1, 0.7, self.font)
        end

        return
    end

    -- weapons, tools, vehicle parts, not gasoline cans, light bulbs
    -- TODO hasTag("ToolHead")? if statement is getting out of hand
    if instanceof(item, "HandWeapon") or
        item:hasTag("ShowCondition") or
        item:hasTag("Sharpenable") or
        item:getDisplayCategory() == "Tool" or
        (item:getDisplayCategory() == "VehicleMaintenance" and item:getFullType() ~= "Base.PetrolCan" and item:getFullType() ~= "Base.JerryCan") or
        luautils.stringStarts(item:getFullType(), "Base.LightBulb") then
        -- label "Condition"
        if config.showLabels == true then
            local condLabel = getText("Tooltip_weapon_Condition") .. ":"
            local condLabelWidth = getTextManager():MeasureStringX(self.font, condLabel)
            self:drawText(condLabel, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
            -- update current x position
            currentX = currentX + condLabelWidth + spacer
        end

        -- progress bar
        if config.showBars == true then
            local condFraction = item:getCurrentCondition() / 100
            self:drawProgressBar(currentX, top + pbY, pbWidth, pbHeight, condFraction, getRGB(condFraction, true))
            -- update current x position
            currentX = currentX + pbWidth + spacer
        end

        -- condition text
        if config.showNumeric then
            local condText = round(item:getCurrentCondition()) .. "%"
            local condTextWidth = getTextManager():MeasureStringX(self.font, condText)
            local condTextMax = "100%"
            local condTextMaxWidth = getTextManager():MeasureStringX(self.font, condTextMax)
            -- update before to right align the text
            currentX = currentX + condTextMaxWidth - condTextWidth
            self:drawText(condText, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
            -- update current x position
            currentX = currentX + condTextWidth + spacer
        end

        -- head
        if item:hasHeadCondition() then
            -- label
            if config.showLabels == true then
                --local label = getText("Tooltip_weapon_HeadCondition") .. ":"
                -- for now use this shorter label to conserve space
                local headLabel = getText("IGUI_health_Head") .. ":"
                local headLabelWidth = getTextManager():MeasureStringX(self.font, headLabel)
                self:drawText(headLabel, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
                -- update current x position
                currentX = currentX + headLabelWidth + spacer
            end

            local headFraction = item:getHeadCondition() / item:getHeadConditionMax()

            -- progress bar
            if config.showBars == true then
                self:drawProgressBar(currentX, top + pbY, pbWidth, pbHeight, headFraction, getRGB(headFraction, true))
                -- update current x position
                currentX = currentX + pbWidth + spacer
            end

            -- head condition text
            if config.showNumeric then
                local headText = round(headFraction * 100) .. "%"
                local headTextWidth = getTextManager():MeasureStringX(self.font, headText)
                local headTextMax = "100%"
                local headTextMaxWidth = getTextManager():MeasureStringX(self.font, headTextMax)
                -- update before to right align the text
                currentX = currentX + headTextMaxWidth - headTextWidth
                self:drawText(headText, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
                -- update current x position
                currentX = currentX + headTextWidth + spacer
            end
        end

        -- sharpness
        if item:hasSharpness() then
            -- label
            if config.showLabels == true then
                local sharpLabel = getText("Tooltip_weapon_Sharpness") .. ":"
                local sharpLabelWidth = getTextManager():MeasureStringX(self.font, sharpLabel)
                self:drawText(sharpLabel, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
                -- update current x position
                currentX = currentX + sharpLabelWidth + spacer
            end

            local sharpFraction = item:getSharpness() / 1 -- item:getMaxSharpness() is dependend on condition

            -- progress bar
            if config.showBars == true then
                self:drawProgressBar(currentX, top + pbY, pbWidth, pbHeight, sharpFraction, getRGB(sharpFraction, true))
                -- update current x position
                currentX = currentX + pbWidth + spacer
            end

            -- sharpness text
            if config.showNumeric then
                local sharpText = round(sharpFraction * 100) .. "%"
                local sharpTextWidth = getTextManager():MeasureStringX(self.font, sharpText)
                local sharpTextMax = "100%"
                local sharpTextMaxWidth = getTextManager():MeasureStringX(self.font, sharpTextMax)
                -- update before to right align the text
                currentX = currentX + sharpTextMaxWidth - sharpTextWidth
                self:drawText(sharpText, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
                -- update current x position
                currentX = currentX + sharpTextWidth + spacer
            end
        end

        -- guns
        if item:getMaxAmmo() > 0 then
            -- apparently getCurrentAmmoCount() dont account for chambered
            local chamber = item:isRoundChambered() and 1 or 0
            -- ammo text ammo count/ammo max
            local ammoText = item:getCurrentAmmoCount() + chamber .. "/" .. item:getMaxAmmo()
            local ammoTextWidth = getTextManager():MeasureStringX(self.font, ammoText)
            local ammoTextMax = item:getMaxAmmo() .. '/' .. item:getMaxAmmo()
            local ammoTextMaxWidth = getTextManager():MeasureStringX(self.font, ammoTextMax)

            -- right aligning
            currentX = currentX + ammoTextMaxWidth - ammoTextWidth
            self:drawText(ammoText, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
            -- update current x position
            currentX = currentX + ammoTextWidth + spacer

            -- magazine
            if item:isContainsClip() then
                -- magazine item so we can get the icon
                local magItem = ScriptManager.instance:getItem(item:getMagazineType())
                --render the magazine icon
                ISInventoryItem.renderScriptItemIcon(self, magItem, currentX, top + iconY, 1.0, iconSize, iconSize)
                -- update current x position
                currentX = currentX + iconSize + spacer
            end

            -- attachments
            local weaponParts = item:getAllWeaponParts()
            for i = 0, weaponParts:size() - 1 do
                -- render attachment icon
                ISInventoryItem.renderItemIcon(self, weaponParts:get(i), currentX, top + iconY, 1.0, iconSize, iconSize)
                -- update current x position
                currentX = currentX + iconSize + (spacer / 2)
            end
        end

        return
    end

    -- Magazines/clips
    if item:getMaxAmmo() > 0 then
        -- label
        if config.showLabels == true then
            local label = getText("Tooltip_weapon_AmmoCount") .. ":"
            -- get the ammo item so we can get the display name
            local ammoItem = getItem(item:getAmmoType())
            if ammoItem then label = ammoItem:getDisplayName() .. ":" end
            local labelWidth = getTextManager():MeasureStringX(self.font, label)
            self:drawText(label, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
            -- update current x position
            currentX = currentX + labelWidth + spacer
        end

        -- progress bar
        if config.showBars == true then
            local fraction = item:getCurrentAmmoCount() / item:getMaxAmmo()
            self:drawProgressBar(currentX, top + pbY, pbWidth, pbHeight, fraction, getRGB(fraction, true))
            -- update current x position
            currentX = currentX + pbWidth + spacer
        end

        -- uses/max text for ammo
        if config.showNumeric then
            local usesText = item:getCurrentAmmoCount() .. "/" .. item:getMaxAmmo()
            local usesTextWidth = getTextManager():MeasureStringX(self.font, usesText)
            local usesTextMax = item:getMaxAmmo() .. "/" .. item:getMaxAmmo()
            local usesTextMaxWidth = getTextManager():MeasureStringX(self.font, usesTextMax)
            -- update before to right align the text
            currentX = currentX + usesTextMaxWidth - usesTextWidth
            self:drawText(usesText, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
            -- update current x position
            currentX = currentX + usesTextWidth + spacer
        end

        return
    end

    -- Food
    if instanceof(item, "Food") then
        local shouldHandle = false
        local hunger = item:getHungerChange()
        if item:isIsCookable() and not item:isFrozen() and item:getHeat() > 1.6 then -- we are cooking
            local label = getText("IGUI_invpanel_Cooking") .. ":"
            local ct = item:getCookingTime()
            local mtc = item:getMinutesToCook()
            local mtb = item:getMinutesToBurn()
            local fraction = ct / mtc
            if ct > mtb then
                label = getText("IGUI_invpanel_Burnt")
            elseif ct > mtc then
                label = getText("IGUI_invpanel_Burning") .. ":"
                fraction = (ct - mtc) / (mtb - mtc)
                fgBar.r = getCore():getBadHighlitedColor():getR()
                fgBar.g = getCore():getBadHighlitedColor():getG()
                fgBar.b = getCore():getBadHighlitedColor():getB()
            end
            local labelWidth = getTextManager():MeasureStringX(self.font, label)

            -- label
            if config.showLabels == true then
                self:drawText(label, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
                -- update current x position
                currentX = currentX + labelWidth + spacer
            end

            if item:isBurnt() then return end

            -- progress bar this should always be shown ?
            if true then
                self:drawProgressBar(currentX, top + pbY, pbWidth, pbHeight, fraction, fgBar)
                -- update current x position
                currentX = currentX + pbWidth + spacer
            end

            -- percentage cooked
            if config.showNumeric then
                local percentageText = round(fraction * 100) .. '%'
                local percentageTextMaxWidth = getTextManager():MeasureStringX(self.font, "100%")

                self:drawTextCentre(percentageText, currentX + percentageTextMaxWidth / 2, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
                -- update current x position
                currentX = currentX + percentageTextMaxWidth + spacer
            end

            shouldHandle = true
        elseif item:getFreezingTime() > 0 then
            local label = getText("IGUI_invpanel_FreezingTime") .. ":"
            local labelWidth = getTextManager():MeasureStringX(self.font, label)
            local fraction = item:getFreezingTime() / 100

            -- label
            if config.showLabels == true then
                self:drawText(label, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
                -- update current x position
                currentX = currentX + labelWidth + spacer
            end

            -- progress bar
            if config.showBars == true then
                self:drawProgressBar(currentX, top + pbY, pbWidth, pbHeight, fraction, {r=0, g=0, b=1, a=1})
                -- update current x position
                currentX = currentX + pbWidth + spacer
            end

             -- percentage frozen
            if config.showNumeric then
                local percentageText = round(fraction * 100) .. '%'
                local percentageTextMaxWidth = getTextManager():MeasureStringX(self.font, "100%")

                self:drawTextCentre(percentageText, currentX + percentageTextMaxWidth / 2, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
                -- update current x position
                currentX = currentX + percentageTextMaxWidth + spacer
            end

            shouldHandle = true
        elseif(hunger ~= 0) then
            local label = getText("IGUI_invpanel_Nutrition") .. ":"
            local labelWidth = getTextManager():MeasureStringX(self.font, label)
            local fraction = (-hunger) / 1.0

            -- label
            if config.showLabels == true then
                self:drawText(label, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
                -- update current x position
                currentX = currentX + labelWidth + spacer
            end

            -- progress bar
            if config.showBars == true then
                self:drawProgressBar(currentX, top + pbY, pbWidth, pbHeight, fraction, fgBar)
                -- update current x position
                currentX = currentX + pbWidth + spacer
            end

            shouldHandle = true
        end

        -- display common values TODO fix the spaghetti
        if shouldHandle == true then
             -- hunger value
            if config.showNumeric then
                local hungerText = "" .. round(hunger * 100)
                local hungerTextMaxWidth = getTextManager():MeasureStringX(self.font, "-000")

                self:drawTextCentre(hungerText, currentX + hungerTextMaxWidth / 2, top + textY, ghc:getR(), ghc:getG(), ghc:getB(), 0.5, self.font)
                -- update current x position
                currentX = currentX + hungerTextMaxWidth + spacer
            end

            --- Traits
            local traits = getPlayer():getTraits()
            -- Nutritionist trait values
            if config.showNutritionist == true and (traits:contains("Nutritionist2") == true or traits:contains("Nutritionist") == true) then

                local cals = round(item:getCalories())
                local carbs = round(item:getCarbohydrates())
                local proteins = round(item:getProteins())
                local fats = round(item:getLipids())

                -- TODO cache textures?
                if cals > 0 or carbs > 0 or proteins > 0 or fats > 0 then
                    -- calories
                    self:drawTextureScaled(getTexture('media/ui/bravo/calories.png'), currentX, top + textY, self.fontHgt, self.fontHgt, 1, 1, 1, 1)
                    -- update current x position
                    currentX = currentX + self.fontHgt + spacer

                    local calsText = "" .. cals
                    local calsTextMaxWidth = getTextManager():MeasureStringX(self.font, "0000")

                    self:drawTextCentre(calsText, currentX + calsTextMaxWidth / 2, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
                    -- update current x position
                    currentX = currentX + calsTextMaxWidth + spacer

                    -- carbs
                    self:drawTextureScaled(getTexture('media/ui/bravo/carbs.png'), currentX, top + textY, self.fontHgt, self.fontHgt, 1, 1, 1, 1)
                    -- update current x position
                    currentX = currentX + self.fontHgt + spacer

                    local carbsText = "" .. carbs
                    local carbsTextMaxWidth = getTextManager():MeasureStringX(self.font, "0000")

                    self:drawTextCentre(carbsText, currentX + carbsTextMaxWidth / 2, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
                    -- update current x position
                    currentX = currentX + carbsTextMaxWidth + spacer

                    -- proteins
                    self:drawTextureScaled(getTexture('media/ui/bravo/proteins.png'), currentX, top + textY, self.fontHgt, self.fontHgt, 1, 1, 1, 1)
                    -- update current x position
                    currentX = currentX + self.fontHgt + spacer

                    local proteinsText = "" .. proteins
                    local proteinsTextMaxWidth = getTextManager():MeasureStringX(self.font, "0000")

                    self:drawTextCentre(proteinsText, currentX + proteinsTextMaxWidth / 2, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
                    -- update current x position
                    currentX = currentX + proteinsTextMaxWidth + spacer

                    -- fats (lipids)
                    self:drawTextureScaled(getTexture('media/ui/bravo/lipids.png'), currentX, top + textY, self.fontHgt, self.fontHgt, 1, 1, 1, 1)
                    -- update current x position
                    currentX = currentX + self.fontHgt + spacer

                    local fatsText = "" .. fats
                    local fatsTextMaxWidth = getTextManager():MeasureStringX(self.font, "0000")

                    self:drawTextCentre(fatsText, currentX + fatsTextMaxWidth / 2, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
                    -- update current x position
                    currentX = currentX + fatsTextMaxWidth + spacer
                end
            end

            -- this item has been handled
            return
        end
    end

    -- Fluid Containers
    if item:isFluidContainer() or (instanceof(item:getWorldItem(), "IsoWorldInventoryObject") and item:getWorldItem():getFluidContainer()) then
        -- get fluid container from inventory or ground
        local fc = item:getFluidContainer() or item:getWorldItem():getFluidContainer()
        local amount = fc:getAmount()
        local capacity = fc:getCapacity()
        local fraction = amount / capacity

        -- label
        if config.showLabels == true then
            -- default label
            local label = getText("Fluid_Empty") .. ": "

            -- why no getAllFluids() ? maybe there is somewhere
            if (amount > 0) then
                local allFluids = Fluid.getAllFluids()
                local t = { }
                for i = 0, allFluids:size() - 1 do
                    local fluid = allFluids:get(i)
                    if (fc:contains(fluid)) then
                        t[#t+1] = fluid:getDisplayName()
                    end
                end
                -- TODO Label can become to long?
                label = table.concat(t,"/") .. ":"
            end

            self:drawText(label, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)

            local labelWidth = getTextManager():MeasureStringX(self.font, label)
            currentX = currentX + labelWidth + spacer
        end

        -- progress bar aka fluid amount
        if config.showBars == true then
            local fluidColor = fc:getColor()
            fgBar = {r=fluidColor:getR(), g=fluidColor:getG(), b=fluidColor:getB(), a=1}
            self:drawProgressBar(currentX, top + pbY, pbWidth, pbHeight, fraction, fgBar)
            -- update current x position
            currentX = currentX + pbWidth + spacer
        end

        -- fluid amount / capacity
        if config.showNumeric then
            -- have to force 2 deciamls for aligning
            local amountText = string.format("%.2f", round(amount, 2))
            local capacityText = string.format("%.2f", round(capacity, 2))
            local usesText = amountText .. "/" .. capacityText
            local usesTextWidth = getTextManager():MeasureStringX(self.font, usesText)
            local usesTextMax = capacityText .. "/" .. capacityText
            -- TO DO: Do we need this now that we are forcing 2 decimals
            local usesTextMaxWidth = getTextManager():MeasureStringX(self.font, usesTextMax)
            -- update before to right align the text
            currentX = currentX + usesTextMaxWidth - usesTextWidth
            self:drawText(usesText, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
            -- update current x position
            currentX = currentX + usesTextWidth + spacer
        end

        return
    end

    -- Clothing and not jewelry
    if instanceof(item, "Clothing") and item:isCosmetic() == false then
        -- label
        if config.showLabels == true then
            local label = getText("IGUI_invpanel_Condition") .. ":"
            local labelWidth = getTextManager():MeasureStringX(self.font, label)
            self:drawText(label, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
            -- update current x position
            currentX = currentX + labelWidth + spacer
        end

        -- progress bar
        if config.showBars == true then
            local fraction = item:getCurrentCondition() / 100
            fgBar = getRGB(fraction, true)
            self:drawProgressBar(currentX, top + pbY, pbWidth, pbHeight, fraction, fgBar)
            -- update current x position
            currentX = currentX + pbWidth + spacer
        end

        -- uses/max text
        if config.showNumeric then
            local usesText = tostring(round(item:getCurrentCondition())) .. "%"
            local usesTextWidth = getTextManager():MeasureStringX(self.font, usesText)
            local usesTextMax = "100%"
            local usesTextMaxWidth = getTextManager():MeasureStringX(self.font, usesTextMax)
            -- update before to right align the text
            currentX = currentX + usesTextMaxWidth - usesTextWidth
            self:drawText(usesText, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
            -- update current x position
            currentX = currentX + usesTextWidth + spacer
        end

        -- holes text
        local holes = item:getHolesNumber()
        if (holes > 0) then
            -- TO DO: Could we have 2 digit number of holes? (aligning)
            local holesText = "(" .. tostring(holes) .. ")"
            local holesTextWidth = getTextManager():MeasureStringX(self.font, holesText)
            -- red text
            fgText = {r = bhc:getR(), g = bhc:getG(), b = bhc:getB(), a = 0.5}

            self:drawText(holesText, currentX, top + textY, fgText.r, fgText.g, fgText.b, fgText.a, self.font)
            -- update current x position
            currentX = currentX + holesTextWidth + spacer
        end

        return
    end

    -- if we reached here, its because we have not handled the item. Therefor we pass to original function for further handling
    oldDrawItemDetails(self, item, y, xoff, yoff, red)
end

-- sort functions
local Sorter = require('BravoItemDetailsSorter')

-- table shortcuts
local tSort = table.sort
local tRem = table.remove
local tIns = table.insert

-- Returns a sort function or false when no sort is needed
local function getSortFunction(item)
    if (instanceof(item, "Drainable") and item:getUseDelta() > 0) then
        return Sorter.uses[config.usesSortDir]
    elseif instanceof(item, "HandWeapon") then
        return Sorter.weapon[config.weaponSortDir]
    elseif item:hasTag("ShowCondition") or item:hasTag("Sharpenable") or item:getDisplayCategory() == "Tool" then
        return Sorter.tools[config.weaponSortDir]
    elseif (item:getDisplayCategory() == "VehicleMaintenance" and item:getFullType() ~= "Base.PetrolCan" and item:getFullType() ~= "Base.JerryCan") or luautils.stringStarts(item:getFullType(), "Base.LightBulb") then
        return Sorter.condition[config.vehicleSortDir]
    elseif item:getMaxAmmo() > 0 then
        return Sorter.ammo[1]
    elseif (instanceof(item, "Food") and item:getHungerChange() ~= 0) then
        return Sorter.hunger[config.foodSortDir]
    elseif item:isFluidContainer() or (instanceof(item:getWorldItem(), "IsoWorldInventoryObject") and item:getWorldItem():getFluidContainer()) then
        return Sorter.fluid[config.fluidSortDir]
    elseif instanceof(item, "Clothing") and item:isCosmetic() == false then
        return Sorter.clothes[config.clothesSortDir]
    end

    return false
end

local oldRefreshContainer = ISInventoryPane.refreshContainer
function ISInventoryPane:refreshContainer()
    -- call original function
    oldRefreshContainer(self)

    -- only sort if enabled in mod settings
    if not config.enableSort then return end

    -- maximum number of items sorted in a stack.. Needed for performance
    local maxSort = tonumber(config.maxSort) or ISInventoryPane.MAX_ITEMS_IN_STACK_TO_RENDER

    -- list of item stacks
    local iList = self.itemslist

    -- loop the item stacks
    for k, v in ipairs(iList) do

        -- only sort expanded stacks that contains 3 or more items (First item is a dummy used for the header in the detail view)
        if v ~= nil and self.collapsed[v.name] ~= true and #v.items > 2 and v.items[1] ~= nil then

            -- get sort function
            local sortFunction = getSortFunction(v.items[1])

            if sortFunction ~= false then
                -- stack-items
                local items = v.items

                -- remove the dummy because we want to sort
                local dummy = tRem(items, 1)

                -- temporarely store items to sort
                local sortItems = {}
                for i = 1, math.min(#items, maxSort) do
                    tIns(sortItems, items[i])
                end

                -- sort
                tSort(sortItems, sortFunction)

                --Add new dummy back
                dummy = sortItems[1]
                tIns(sortItems, 1, dummy);

                -- add back unsorted elements if any
                -- TO DO could we just loop sortItems[i] and overwrite v.items[i]?
                for i = maxSort + 1, (#items - maxSort) do
                    tIns(sortItems, items[i])
                end

                -- store new sorted elements
                v.items = sortItems
            end
        end
    end
end
