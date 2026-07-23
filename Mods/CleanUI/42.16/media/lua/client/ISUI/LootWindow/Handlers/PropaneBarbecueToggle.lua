--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "ISUI/LootWindow/ISLootWindowObjectControlHandler"

ISLootWindowObjectControlHandler_PropaneBarbecueToggle = ISLootWindowObjectControlHandler:derive("ISLootWindowObjectControlHandler_PropaneBarbecueToggle")
local Handler = ISLootWindowObjectControlHandler_PropaneBarbecueToggle
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
function Handler:shouldBeVisible()
    return self.object:isPropaneBBQ() and self.object:hasFuel()
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
        local isLit = self.object:isLit()
        
        -- Background
        local alpha = btn.mouseOver and 0.8 or 0.6
        local color = isLit and {r=0.2, g=0.6, b=0.2} or {r=0.6, g=0.2, b=0.2}
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/2_3Background.png"), 0, 0, btn.width, btn.height, alpha, color.r, color.g, color.b)
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/2_3Border.png"), 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)
        
        -- Icon
        local iconPath = isLit and "media/ui/CleanUI/Icon/Icon_ON.png" or "media/ui/CleanUI/Icon/Icon_OFF.png"
        local icon = getTexture(iconPath)
        btn:drawTextureScaled(icon, 0, 0, btn.width, btn.height, 1, 0.8, 0.8, 0.8)

        if isLit then
            self.control.tooltip = getText("ContextMenu_Turn_Off")
        else
            self.control.tooltip = getText("ContextMenu_Turn_On")
        end
        btn:updateTooltip()
    end
end

function Handler:handleJoypadContextMenu(context)
    local xln = nil
    if self.object:isLit() then
        xln = "ContextMenu_Turn_Off"
    else
        xln = "ContextMenu_Turn_On"
    end
    local option = self:addJoypadContextMenuOption(context, getText(xln))
    option.iconTexture = ContainerButtonIcons[self.container:getType()]
end

function Handler:perform()
	if isGamePaused() then
		return
	end
	ISBBQMenu.onToggle(nil, self.playerNum, self.object, nil)
end

function Handler:new()
    local o = ISLootWindowObjectControlHandler.new(self)
    o.altColor = false
    return o
end
