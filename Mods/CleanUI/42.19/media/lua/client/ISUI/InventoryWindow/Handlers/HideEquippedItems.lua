require "ISBaseObject"
require "ISUI/ISButton"

ISInventoryWindowControlHandler_HideEquipped = ISBaseObject:derive("ISInventoryWindowControlHandler_HideEquipped")
local Handler = ISInventoryWindowControlHandler_HideEquipped
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function Handler:shouldBeVisible()
    if getCore():getGameMode() == "Tutorial" then return false end
    
    return true
end

function Handler:getControl()
    if not self.control then
        self:createHideEquippedControl()
    end
    return self.control
end

function Handler:createHideEquippedControl()
    local buttonHeight = math.floor(FONT_HGT_SMALL * 1.2)
    
    self.control = ISButton:new(0, 0, buttonHeight, buttonHeight, "", self, Handler.perform)
    self.control:initialise()
    self.control.handler = self
    
    self.control.prerender = function(btn)
        local handler = btn.handler

        -- Background
        local brightness = btn.mouseOver and 0.2 or 0.1
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/SQBackground.png"), 0, 0, btn.width, btn.height, 0.6, brightness, brightness, brightness)
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/SQBorder.png"), 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)

        -- Icon
        local isHidden = handler:getHideState()
        local icon = isHidden and  getTexture("media/ui/CleanUI/Icon/Icon_HideEquipped.png") or getTexture("media/ui/CleanUI/Icon/Icon_ShowEquipped.png")

        local iconSize = math.floor(btn.width * 0.8)
        local iconXY = (btn.width - iconSize) / 2
        btn:drawTextureScaled(icon, iconXY, iconXY, iconSize, iconSize, 1, 1, 1, 1)
    end
end

function Handler:getWindow()
    return self.inventoryWindow
end

function Handler:perform()
    if isGamePaused() then return end

    local currentState = self:getHideState()
    self:setHideState(not currentState)

    local window = self:getWindow()
    if window and window.inventoryPane then
        window.inventoryPane:refreshContainer()
    end
end

function Handler:getHideState()
    local config = CleanUIConfig.getConfig()
    return config.hideEquipped or false
end

function Handler:setHideState(state)
    CleanUIConfig.updateConfig("hideEquipped", state)
end

function Handler:handleJoypadContextMenu(context)
    local isHidden = self:getHideState()
    local text = isHidden and getText("IGUI_CleanUI_ShowEquipped") or getText("IGUI_CleanUI_HideEquipped")
    self:addJoypadContextMenuOption(context, text)
end

function Handler:addJoypadContextMenuOption(context, text)
    -- no need for joypad
end

function Handler:new()
    local o = ISBaseObject.new(self)
    o.altColor = false
    return o
end

function ISInventoryWindowControlHandler_HideEquipped.shouldHideEquipped(playerNum)
    local config = CleanUIConfig.getConfig()
    return config.hideEquipped or false
end