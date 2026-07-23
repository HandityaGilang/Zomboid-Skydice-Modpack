--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "ISUI/LootWindow/ISLootWindowObjectControlHandler"

ISLootWindowObjectControlHandler_StoveToggle = ISLootWindowObjectControlHandler:derive("ISLootWindowObjectControlHandler_StoveToggle")
local Handler = ISLootWindowObjectControlHandler_StoveToggle

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function Handler:shouldBeVisible()
    if getCore():getGameMode() == "Tutorial" then return false end
    return instanceof(self.object, "IsoStove") and (self.container ~= nil)
end

function Handler:getControl()
    if not self.control then
        self:createIconControl()
    end
    return self.control
end

function Handler:createIconControl()
    local buttonHeight = math.floor(FONT_HGT_SMALL * 1.2)
    
    self.control = ISButton:new(0, 0, buttonHeight * (3/2), buttonHeight, "", self, Handler.perform)
    self.control:initialise()
    self.control.handler = self
    
    self.control.prerender = function(btn)
        local isActivated = self.object:Activated()
        
        -- Background
        local alpha = btn.mouseOver and 0.8 or 0.6
        local color = isActivated and {r=0.2, g=0.6, b=0.2} or {r=0.6, g=0.2, b=0.2}
        if not self.container:isPowered() then
            color = {r=0.15, g=0.15, b=0.15}
        end
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/2_3Background.png"), 0, 0, btn.width, btn.height, alpha, color.r, color.g, color.b)
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/2_3Border.png"), 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)
        
        -- Icon
        local iconPath = isActivated and "media/ui/CleanUI/Icon/Icon_ON.png" or "media/ui/CleanUI/Icon/Icon_OFF.png"
        if not self.container:isPowered() then
            iconPath = "media/ui/CleanUI/Icon/Icon_PowerDisconnect.png"
        end
        local icon = getTexture(iconPath)
        btn:drawTextureScaled(icon, 0, 0, btn.width, btn.height, 1, 0.8, 0.8, 0.8)

        if isActivated then
            self.control.tooltip = getText("ContextMenu_Turn_Off")
        else
            self.control.tooltip = getText("ContextMenu_Turn_On")
        end
        btn:updateTooltip()
    end
end

function Handler:handleJoypadContextMenu(context)
    local xln = nil
    if self.object:Activated() then
        xln = "ContextMenu_Turn_Off"
    else
        xln = "ContextMenu_Turn_On"
    end
    local option = self:addJoypadContextMenuOption(context, getText(xln))
    option.iconTexture = ContainerButtonIcons[self.container:getType()]
end

function Handler:perform()
    if self.object:getSquare()  and self.container:isPowered() and luautils.walkAdj(self.playerObj, self.object:getSquare()) then
        ISTimedActionQueue.add(ISToggleStoveAction:new(self.playerObj, self.object))
    end
end

function Handler:new()
    local o = ISLootWindowObjectControlHandler.new(self)
    o.altColor = false
    return o
end