--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "ISUI/LootWindow/ISLootWindowObjectControlHandler"

ISLootWindowObjectControlHandler_StoveSettings = ISLootWindowObjectControlHandler:derive("ISLootWindowObjectControlHandler_StoveSettings")
local Handler = ISLootWindowObjectControlHandler_StoveSettings
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function Handler:shouldBeVisible()
    if getCore():getGameMode() == "Tutorial" then return false end
    return instanceof(self.object, "IsoStove") and (self.container ~= nil) and self.container:isPowered()
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
    self.control.tooltip = getText("ContextMenu_StoveSetting")
    self.control:initialise()
    self.control.handler = self
    
    self.control.prerender = function(btn)
        -- Background
        local alpha = btn.mouseOver and 0.8 or 0.6
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/SQBackground.png"), 0, 0, btn.width, btn.height, alpha, 0.6, 0.3, 0.1)
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/SQBorder.png"), 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)
        
        -- Icon
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Icon/Icon_StoveSettings.png"), 0, 0, btn.width, btn.height, 1, 0.8, 0.8, 0.8)
        btn:updateTooltip()
    end
end

function Handler:handleJoypadContextMenu(context)
    local option = self:addJoypadContextMenuOption(context, getText("ContextMenu_StoveSetting"))
    option.iconTexture = ContainerButtonIcons[self.container:getType()]
end

function Handler:perform()
    if self.object:isMicrowave() then
        ISWorldObjectContextMenu.onMicrowaveSetting(nil, self.object, self.playerNum)
    else
        ISWorldObjectContextMenu.onStoveSetting(nil, self.object, self.playerNum)
    end
end

function Handler:new()
    local o = ISLootWindowObjectControlHandler.new(self)
    o.altColor = false
    return o
end
