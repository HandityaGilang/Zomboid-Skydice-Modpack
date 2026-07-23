---
--- Mod: Weapon Condition Indicator
--- Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=2619072426
--- Author: NoctisFalco
--- Profile: https://steamcommunity.com/id/NoctisFalco/
---
--- Redistribution of this mod without explicit permission from the original creator is prohibited
--- under any circumstances. This includes, but not limited to, uploading this mod to the Steam Workshop
--- or any other site, distribution as part of another mod or modpack, distribution of modified versions.
--- You are free to do whatever you want with the mod provided you do not upload any part of it anywhere.
---
--- The QualityStar_n.png icons are the property of The Indie Stone.
--- The mod overrides parts of the ISHotbar.lua, ISEquippedItem.lua files by The Indie Stone.
---

local TEXTURE_WIDTH = 0
local TEXTURE_HEIGHT = 0
local size = getCore():getOptionSidebarSize()
if size == 6 then
    size = getCore():getOptionFontSizeReal() - 1
end
    TEXTURE_WIDTH = 48
if size == 2  then
    TEXTURE_WIDTH = 64
elseif size == 3  then
    TEXTURE_WIDTH = 80
elseif size == 4  then
    TEXTURE_WIDTH = 96
elseif size == 5 then
    TEXTURE_WIDTH = 128
end

TEXTURE_HEIGHT = TEXTURE_WIDTH * 0.75


local originalInitialise = ISEquippedItem.initialise
function ISEquippedItem:initialise()
    originalInitialise(self)

    local fontSize = 16
    local fontSizeOption = getCore():getOptionFontSize()
    if fontSizeOption == 6 then
      fontSizeOption = getCore():getOptionFontSizeReal() - 1
    end
    if fontSizeOption == 2 then
      fontSize = 19
    elseif fontSizeOption == 3 then
      fontSize = 26
    elseif fontSizeOption == 4 then
      fontSize = 33
    elseif fontSizeOption == 5 then
      fontSize = 38
    end

    -- self.handMainExtensionUI = UIHandMainExtension:new(44, 11)
    self.handMainExtensionUI = UIHandMainExtension:new(TEXTURE_WIDTH - 4, (TEXTURE_WIDTH / 2) - (fontSize / 2))
    self.handMainExtensionUI:initialise()
    self:addChild(self.handMainExtensionUI)
    self.handMainExtensionUI:setVisible(false)

    -- self.handSecondaryExtensionUI = UIHandSecondaryExtension:new(39, 58)
    self.handSecondaryExtensionUI = UIHandSecondaryExtension:new((TEXTURE_WIDTH - 4) * 0.865, (TEXTURE_WIDTH * 1.6) - (fontSize / 2))
    self.handSecondaryExtensionUI:initialise()
    self:addChild(self.handSecondaryExtensionUI)
    self.handSecondaryExtensionUI:setVisible(false)
  end

  function ISEquippedItem:render()
    local primaryItem = self.chr:getPrimaryHandItem();
    local secondaryItem = self.chr:getSecondaryHandItem();

    if ISMouseDrag.dragging and self:isMouseOver() then
        local item1, item2 = self:getDraggedEquippableItems()
        if item1 and secondaryItem and (primaryItem == secondaryItem or item1 == secondaryItem) then
            secondaryItem = nil;
        end
        if item2 and primaryItem and (primaryItem == secondaryItem or primaryItem == item2) then
            primaryItem = nil;
        end
        primaryItem = item1 or primaryItem
        secondaryItem = item2 or secondaryItem
    end

    if primaryItem then
        local item = primaryItem

        local isHandWeapon = TheStar.Utils.isHandWeapon(item)
        local isWaterSource = TheStar.Utils.isWaterSource(item)

        local conditionLevel
        if isHandWeapon or isWaterSource then
            conditionLevel = item:getCondition() / item:getConditionMax()
            if isWaterSource then
                conditionLevel = item:getCurrentUsesFloat()
            end
            if conditionLevel < 0.0 then conditionLevel = 0.0 end
            if conditionLevel > 1.0 then conditionLevel = 1.0 end
        end

        -- * Blinker
        if isHandWeapon and TheStar.Options.blinkOnConditionDrop then
            local hasConditionDropped = false
            if self.previousItem == item then
                self.isNewItem = false
                hasConditionDropped = conditionLevel < self.previousConditionLevel
            else
                self.isNewItem = true
            end
            self.previousItem = item
            self.previousConditionLevel = conditionLevel

            -- In case the player equips other item during blinking
            if self.isNewItem then self.isBlinking = false end

            if (not self.isNewItem and hasConditionDropped and conditionLevel <= TheStar.Options.blinkCondition)
                    or self.isBlinking then
                -- Init counter/reset counter every time condition drops
                if not self.blinkCount or hasConditionDropped then self.blinkCount = 0 end

                -- Blink
                if self.blinkCount <= TheStar.Config.BLINK_COUNT_MAX then
                    self.isBlinking = true

                    if not self.blinkAlpha then self.blinkAlpha = TheStar.Config.BLINK_ALPHA_MAX end

                    local overlayTexture
                    -- if TheStar.Options.showProgressBar then
                    if TheStarB42.Options:getOption("showProgressBar"):getValue() then
                        local n = math.ceil(conditionLevel * 10)
                        overlayTexture = TheStar.Utils.getHandMainOverlayReversedTexture(n, TEXTURE_WIDTH, "HandMain")
                    else
                        overlayTexture = TheStar.Utils.getHandMainOverlayTexture(10, TEXTURE_WIDTH, "HandMain")
                    end
                    local blinkColor = TheStar.Utils.getProgressColor(conditionLevel)
                    self.mainHand:drawTexture(overlayTexture, 0, 0, self.blinkAlpha, blinkColor.r, blinkColor.g, blinkColor.b)

                    if not self.blinkAlphaIncrease then
                        self.blinkAlpha = self.blinkAlpha - 0.05 * (UIManager.getMillisSinceLastRender() / 22.2)
                        if self.blinkAlpha < 0 then
                            self.blinkAlpha = 0

                            -- Don't increase blinkAlpha on the last blink
                            if self.blinkCount < TheStar.Config.BLINK_COUNT_MAX then
                                self.blinkAlphaIncrease = true
                            end

                            -- Last blink
                            if self.blinkCount == TheStar.Config.BLINK_COUNT_MAX then
                                self.isBlinking = false
                            end
                        end
                    else
                        self.blinkAlpha = self.blinkAlpha + 0.05 * (UIManager.getMillisSinceLastRender() / 22.2)
                        if self.blinkAlpha > TheStar.Config.BLINK_ALPHA_MAX then
                            self.blinkAlpha = TheStar.Config.BLINK_ALPHA_MAX
                            self.blinkAlphaIncrease = false
                            -- Increase counter
                            self.blinkCount = self.blinkCount + 1
                        end
                    end
                end
            end
        end

        -- * 컨디션 상태 배경
        -- if (isHandWeapon or isWaterSource) and TheStar.Options.showProgressBar then
        if (isHandWeapon or isWaterSource) and TheStarB42.Options:getOption("showProgressBar"):getValue() then
            local n = math.ceil(conditionLevel * 10)
            local overlayTexture = TheStar.Utils.getHandMainOverlayTexture(n, TEXTURE_WIDTH, "HandMain")
            local progressColor = TheStar.Utils.getProgressColor(conditionLevel, isWaterSource)

            self.mainHand:drawTexture(overlayTexture, 1.5, 1.5, TheStarB42.percentValues[TheStarB42.Options:getOption("progressBarOpacityEquipped"):getValue()], progressColor.r, progressColor.g, progressColor.b)
        end

        -- * Item Texture
        -- True - 바닐라(근접무기), False - 모드(화기)
        -- self:drawTextureScaled(item:getTex(), x, y, TEXTURE_WIDTH / 1.5, TEXTURE_WIDTH / 1.5, item:getA(), item:getR(), item:getG(), item:getB());

        local scale = TEXTURE_WIDTH * 0.75
        local hand = self.mainHand
        self:drawTextureScaledAspect(item:getTex(), hand.x+(hand.width/2) - (scale/2), hand.y+(hand.height/2)-(scale/2), scale, scale, item:getA(),item:getR(),item:getG(),item:getB());


        if isHandWeapon and TheStarB42.Options:getOption("showIcon"):getValue() then
            local n = math.ceil(conditionLevel * 5)
            local iconTexture = TheStar.Utils.getIconTexture(n)

            if TheStarB42.Options:getOption("equippedItemIconPosition"):getValue() == 1 then
                -- top left (original)
                self:drawTexture(iconTexture, 7, 10, 1, 1, 1, 1)
            else
                -- top right
                self:drawTexture(iconTexture, TEXTURE_WIDTH - iconTexture:getWidth(), 10, 1, 1, 1, 1)
            end
        end
    else
        -- Reset
        self.previousItem = nil
    end
    -- 보조무기
    if secondaryItem then
        local item = secondaryItem

        local isHandWeapon = TheStar.Utils.isHandWeapon(item)
        local isWaterSource = TheStar.Utils.isWaterSource(item)

        local conditionLevel
        if isHandWeapon or isWaterSource then
            conditionLevel = item:getCondition() / item:getConditionMax()
            if isWaterSource then
                conditionLevel = item:getCurrentUsesFloat()
            end
            if conditionLevel < 0.0 then conditionLevel = 0.0 end
            if conditionLevel > 1.0 then conditionLevel = 1.0 end
        end

        local scale = TEXTURE_HEIGHT * 0.75
        local hand = self.offHand

        -- * 컨디션 상태 배경
        -- if (isHandWeapon or isWaterSource) and TheStarB42.Options:getOption("showProgressBar"):getValue() then
        --   local n = math.ceil(conditionLevel * 10)
        --   local overlayTexture = TheStar.Utils.getHandMainOverlayTexture(n, TEXTURE_WIDTH, "OffHand")
        --   local progressColor = TheStar.Utils.getProgressColor(conditionLevel, isWaterSource)

        --   self.offHand:drawTexture(overlayTexture, 3, 1.5, TheStarB42.percentValues[TheStarB42.Options:getOption("progressBarOpacityEquipped"):getValue()], progressColor.r, progressColor.g, progressColor.b)
        -- end


        self:drawTextureScaledAspect(item:getTex(), hand.x+(hand.width/2) - (scale/2), hand.y+(hand.height/2)-(scale/2), scale, scale, item:getA(),item:getR(),item:getG(),item:getB());
    end

    if self.chr:getBodyDamage():getHealth() ~= self.previousHealth then
        if self.previousHealth > self.chr:getBodyDamage():getHealth() then
            self.healthIconOscillatorLevel = 1;
        end
        self.previousHealth = self.chr:getBodyDamage():getHealth()
    end

    --code for the oscillation of the heart icon when attacked
    if not self.healthBtn then
        -- Player 1/2/3
    elseif self.healthIconOscillatorLevel > 0.01 then
        local fpsFrac = PerformanceSettings.getLockFPS() / 30.0;
        self.healthIconOscillatorLevel = self.healthIconOscillatorLevel * self.healthIconOscillatorDecelerator
        self.healthIconOscillatorLevel = self.healthIconOscillatorLevel - (self.healthIconOscillatorLevel * (1 - self.healthIconOscillatorDecelerator) / fpsFrac)
        self.healthIconOscillatorStep = self.healthIconOscillatorStep + self.healthIconOscillatorRate / fpsFrac
        self.healthIconOscillator = math.sin(self.healthIconOscillatorStep)
        self.healthBtn:setX(self.healthIconOscillator * self.healthIconOscillatorLevel * self.healthIconOscillatorScalar)
    elseif self.healthIconOscillatorLevel < 0.01 then
        self.healthIconOscillatorLevel = 0
        self.healthBtn:setX(self.healthIconOscillator * self.healthIconOscillatorLevel * self.healthIconOscillatorScalar)
    end

    if self.invBtn == nil then
        return ;
    end

    if ISEquippedItem.text then
        self:drawText(ISEquippedItem.text, TEXTURE_WIDTH, 0, 1, 1, 1, 1, UIFont.Medium);
    end

    self:checkToolTip();

    self:renderFPS();
end


local originalCheckTooltip = ISEquippedItem.checkToolTip
function ISEquippedItem:checkToolTip()
    if not TheStar.Options.showItemTooltipEquippedItem then
        if self.tooltipRender then
            self.tooltipRender:removeFromUIManager()
            self.tooltipRender:setVisible(false)
            self.tooltipRender = nil
        end
        return
    end

    local mx, my = getMouseX(), getMouseY()
    local mouseOverID = -1
    if self.mouseOverList ~= nil then
        for k, v in ipairs(self.mouseOverList) do
            if self:checkBounds(v.object, mx, my) then
                mouseOverID = k
            end
        end
    end
    if mouseOverID > 2 then
        originalCheckTooltip(self)
    else
        -- Remove the original tooltip
        if self.toolTip and self.toolTip:getIsVisible() then
            self.toolTip:removeFromUIManager()
            self.toolTip:setVisible(false)
        end
    end

    self:updateTooltip(mouseOverID)
end

function ISEquippedItem:updateTooltip(mouseOverID)
    local item
    if mouseOverID == 1 then item = self.chr:getPrimaryHandItem()
    elseif mouseOverID == 2 then item = self.chr:getSecondaryHandItem()
    end

    if getPlayerContextMenu(self.chr:getPlayerNum()) and getPlayerContextMenu(self.chr:getPlayerNum()):isAnyVisible() then
        item = nil
    end

    if item and self.tooltipRender and item == self.tooltipRender.item and self.tooltipRender:isVisible() then
        return
    end
    if item then
        if self.tooltipRender then
            self.tooltipRender:setItem(item)
            self.tooltipRender:setVisible(true)
            self.tooltipRender:addToUIManager()
            self.tooltipRender:bringToTop()
        else
            self.tooltipRender = ISToolTipInv:new(item)
            self.tooltipRender.backgroundColor.a = 0.7
            self.tooltipRender.followMouse = true
            self.tooltipRender:initialise()
            self.tooltipRender:addToUIManager()
            self.tooltipRender:setVisible(true)
            self.tooltipRender:setOwner(self)
            self.tooltipRender:setCharacter(self.chr)
        end
    elseif self.tooltipRender and self.tooltipRender:isVisible() then
        self.tooltipRender:removeFromUIManager()
        self.tooltipRender:setVisible(false)
    end
end
