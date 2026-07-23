require "ISBaseObject"
require "ISUI/ISButton"

ISInventoryCommonHandler_SortMenu = ISBaseObject:derive("ISInventoryCommonHandler_SortMenu")
local Handler = ISInventoryCommonHandler_SortMenu
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function Handler:shouldBeVisible()
    if getCore():getGameMode() == "Tutorial" then return false end
    return true
end

function Handler:getControl()
    if not self.control then
        self:createSortControl()
    end
    return self.control
end

function Handler:createSortControl()
    local buttonHeight = math.floor(FONT_HGT_SMALL * 1.2)
    
    self.control = ISButton:new(0, 0, buttonHeight, buttonHeight, "", self, Handler.perform)
    self.control:initialise()
    self.control.prerender = function(btn)
        local brightness = btn.mouseOver and 0.2 or 0.1
        local color = btn.mouseOver and {r = 1, g = 0.55, b = 0.15} or {r = 0.95, g = 0.5, b = 0.1}
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/SQBackground.png"), 0, 0, btn.width, btn.height, 0.6, brightness, brightness, brightness)
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/SQBorder.png"), 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)

        local iconSize = math.floor(btn.width * 0.8)
        local IconXY = (btn.width - iconSize) / 2
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Icon/Icon_SortButton.png"), IconXY, IconXY, iconSize, iconSize, 1, 0.6, 0.6, 0.6)
    end
end

function Handler:getWindow()
    return self.inventoryWindow or self.lootWindow
end

function Handler:perform()
    local window = self:getWindow()
    if not window then return end
    
    local x = self.control:getAbsoluteX()
    local y = self.control:getAbsoluteY() + self.control:getHeight()
    
    local context = ISContextMenu.get(self.playerNum, x, y)
    
    -- Name
    local nameOption = context:addOption(getText("IGUI_Name"), self, Handler.sortByName)
    local nameIcon = getTexture("media/ui/CleanUI/ICON/Icon_SortByName.png")
    if nameIcon then
        nameOption.iconTexture = nameIcon
    end
    
    -- Category
    local typeOption = context:addOption(getText("IGUI_invpanel_Category"), self, Handler.sortByType)
    local typeIcon = getTexture("media/ui/CleanUI/ICON/Icon_SortByType.png")
    if typeIcon then
        typeOption.iconTexture = typeIcon
    end
    
    -- Weight
    local weightOption = context:addOption(getText("IGUI_invpanel_weight"), self, Handler.sortByWeight)
    local weightIcon = getTexture("media/ui/CleanUI/ICON/Icon_Weight.png")
    if weightIcon then
        weightOption.iconTexture = weightIcon
    end
    
    if context.numOptions > 1 then 
        context:setVisible(true)

        if JoypadState.players[self.playerNum + 1] then
            context.origin = window
            context.mouseOver = 1
            setJoypadFocus(self.playerNum, context)
        end
    end
end

function Handler:sortByName()
    local window = self:getWindow()
    if not window or not window.inventoryPane then return end
    
    local pane = window.inventoryPane
    if pane.itemSortFunc == ISInventoryPane.itemSortByNameInc then
        pane.itemSortFunc = ISInventoryPane.itemSortByNameDesc
    else
        pane.itemSortFunc = ISInventoryPane.itemSortByNameInc
    end
    pane:refreshContainer()
end

function Handler:sortByType()
    local window = self:getWindow()
    if not window or not window.inventoryPane then return end
    
    local pane = window.inventoryPane
    if pane.itemSortFunc == ISInventoryPane.itemSortByCatInc then
        pane.itemSortFunc = ISInventoryPane.itemSortByCatDesc
    else
        pane.itemSortFunc = ISInventoryPane.itemSortByCatInc
    end
    pane:refreshContainer()
end

function Handler:sortByWeight()
    local window = self:getWindow()
    if not window or not window.inventoryPane then return end
    
    local pane = window.inventoryPane
    if pane.itemSortFunc == ISInventoryPane.itemSortByWeightAsc then
        pane.itemSortFunc = ISInventoryPane.itemSortByWeightDesc
    else
        pane.itemSortFunc = ISInventoryPane.itemSortByWeightAsc
    end
    pane:refreshContainer()
end

function Handler:handleJoypadContextMenu(context)
    self:addJoypadContextMenuOption(context, getText("UI_CleanUI_SortItem"))
end

function Handler:addJoypadContextMenuOption(context, text)
    local option = context:addOption(text, self, self.perform)
    return option
end

function Handler:new()
    local o = ISBaseObject.new(self)
    o.altColor = false
    return o
end