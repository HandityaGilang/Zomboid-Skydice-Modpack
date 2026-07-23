--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "ISUI/LootWindow/ISLootWindowObjectControlHandler"

ISLootWindowObjectControlHandler_PropaneBarbecueAddTank = ISLootWindowObjectControlHandler:derive("ISLootWindowObjectControlHandler_PropaneBarbecueAddTank")
local Handler = ISLootWindowObjectControlHandler_PropaneBarbecueAddTank
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function Handler:shouldBeVisible()
    return self.object:isPropaneBBQ() and (not self.object:hasPropaneTank()) and (ISBBQMenu.FindPropaneTank(self.playerObj, self.object) ~= nil)
end

function Handler:getControl()
    if not self.control then
        self:createIconControl()
    end
    return self.control
end

function Handler:createIconControl()
    local buttonHeight = math.floor(FONT_HGT_SMALL * 1.2)
    
    self.control = ISButton:new(0, 0, buttonHeight, buttonHeight, "", self, Handler.perform)
    self.control.tooltip = getText("ContextMenu_Insert_Propane_Tank")
    self.control:initialise()
    self.control.handler = self
    
    self.control.prerender = function(btn)
        -- Background
        local alpha = btn.mouseOver and 0.8 or 0.6
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/SQBackground.png"), 0, 0, btn.width, btn.height, alpha, 0.6, 0.3, 0.1)
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/SQBorder.png"), 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)
        
        -- Icon
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Icon/Icon_AddTank.png"), 0, 0, btn.width, btn.height, 1, 0.7, 0.7, 0.7)
        btn:updateTooltip()
    end
end

function Handler:handleJoypadContextMenu(context)
    local option = self:addJoypadContextMenuOption(context, getText("ContextMenu_Insert_Propane_Tank"))
    option.iconTexture = ContainerButtonIcons[self.container:getType()]
end

function Handler:perform()
	if isGamePaused() then
		return
	end
    local tank = ISBBQMenu.FindPropaneTank(self.playerObj, self.object)
	if not tank then return end
	ISBBQMenu.onInsertPropaneTank(nil, self.playerNum, self.object, tank)
end

function Handler:new()
    local o = ISLootWindowObjectControlHandler.new(self)
    o.altColor = true
    return o
end
