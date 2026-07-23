require "ISBaseObject"
require "ISUI/ISButton"

ISInventoryWindowControlHandler_AutoLoot = ISBaseObject:derive("ISInventoryWindowControlHandler_AutoLoot")
local Handler = ISInventoryWindowControlHandler_AutoLoot

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function Handler:shouldBeVisible()
    if getCore():getGameMode() == "Tutorial" then return false end
    if AutoLoot then return true end
    return false
end

function Handler:getControl()
    if not self.control then
        self:createAutoLootControl()
    end
    return self.control
end

function Handler:createAutoLootControl()
    local buttonHeight = math.floor(FONT_HGT_SMALL * 1.2)
    
    self.control = ISButton:new(0, 0, buttonHeight *(3/2), buttonHeight, "", self, Handler.perform)
    self.control:initialise()
    self.control.prerender = function(btn)
        local alpha = btn.mouseOver and 0.8 or 0.6
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/2_3Background.png"), 0, 0, btn.width, btn.height, alpha, 0.2, 0.2, 0.2)
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/2_3Border.png"), 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)

        local color = AutoLoot.isOn() and {r=0.95, g=0.5, b=0.1} or {r=0.7, g=0.7, b=0.7}
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Icon/Icon_AutoLoot.png"), 0, 0, btn.width, btn.height, 1, color.r, color.g, color.b)
    end
end

function Handler:getWindow()
    return self.inventoryWindow
end

function Handler:perform()
    AutoLoot.setOn( not AutoLoot.isOn() )
end


function Handler:addJoypadContextMenuOption(context, text)
    -- no need for joypad
end

function Handler:new()
    local o = ISBaseObject.new(self)
    o.altColor = false
    return o
end

ISInventoryWindowContainerControls.AddHandler(ISInventoryWindowControlHandler_AutoLoot)

-- Remove AutoLoot Button

local function detectAutoLootMod()
    local activatedMods = getActivatedMods()
    for i=0, activatedMods:size()-1 do
        local modName = activatedMods:get(i)
        if string.find(string.lower(modName), "autoloot") then
            return true
        end
    end
    return false
end

local function applyAutoLootPatch()
    if detectAutoLootMod() then
        local original_createChildren = ISInventoryPage.createChildren
        function ISInventoryPage:createChildren()
            original_createChildren(self)
            if self.onCharacter then
                self.swapAutoLoot = CleanUI_LongButton:new(0, math.floor((self:titleBarHeight() - self.titleButtonSize) / 2), 50, self.titleButtonSize, "", self, ISInventoryPage.swapAutoLoot)
                self.swapAutoLoot:initialise()
                self:addChild(self.swapAutoLoot)
                self.swapAutoLoot:setVisible(false)
                self.swapAutoLoot:setFont(UIFont.Small)
            end
            
            if not self.onCharacter and self.stackItemsButtonIcon then
                self.stackItemsButtonIcon:setVisible(false)
            end
        end

        local original_prerender = ISInventoryPage.prerender
        function ISInventoryPage:prerender()
            original_prerender(self)
            --[[
            if self.onCharacter and self.swapAutoLoot then
                local autoLootText = getText("Sandbox_AutoLoot_LootMode_option2")
                self.swapAutoLoot:setTitle(autoLootText)

                if AutoLoot and AutoLoot.isOn and not AutoLoot.isOn() then
                    self.swapAutoLoot:setActive(false)
                else
                    self.swapAutoLoot:setActive(true)
                end

                local autoLootWid = getTextManager():MeasureStringX(UIFont.Small, autoLootText) + self.padding * 4
                local newX = self.transferButton:getX() - autoLootWid - self.padding
                self.swapAutoLoot:setX(newX)
                self.swapAutoLoot:setWidth(autoLootWid)
                self.swapAutoLoot:setVisible(true)
            end
            ]]
            if self.onCharacter and self.swapAutoLoot then
                self.swapAutoLoot:setVisible(false)
            end

            if not self.onCharacter and self.stackItemsButtonIcon then
                self.stackItemsButtonIcon:setVisible(false)
            end
            
        end
    end
end

Events.OnGameBoot.Add(function()applyAutoLootPatch()end)