require "ISBaseObject"
require "ISUI/ISButton"
ISInventoryCommonHandler_CollapseExpand = ISBaseObject:derive("ISInventoryCommonHandler_CollapseExpand")
local Handler = ISInventoryCommonHandler_CollapseExpand
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function Handler:shouldBeVisible()
    if getCore():getGameMode() == "Tutorial" then return false end
    return true
end

function Handler:getControl()
    if not self.control then
        self:createCollapseExpandControl()
    end
    return self.control
end

function Handler:createCollapseExpandControl()
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
        local isAllCollapsed = handler:isAllCollapsed()
        local icon = isAllCollapsed and getTexture("media/ui/CleanUI/Icon/Icon_ExpandedIcon.png") or getTexture("media/ui/CleanUI/Icon/Icon_CollapsedIcon.png")

        local iconSize = math.floor(btn.width * 0.8)
        local iconXY = (btn.width - iconSize) / 2
        btn:drawTextureScaled(icon, iconXY, iconXY, iconSize, iconSize, 1, 1, 1, 1)
    end
end

function Handler:getWindow()
    return self.inventoryWindow or self.lootWindow
end

function Handler:perform()
    local window = self:getWindow()
    if not window or not window.inventoryPane then return end
    local pane = window.inventoryPane

    if self:isAllCollapsed() then
        pane:expandAll()
    else
        pane:collapseAll()
    end
end

function Handler:isAllCollapsed()
    local window = self:getWindow()
    if not window or not window.inventoryPane then return false end
    
    local pane = window.inventoryPane
    if not pane.collapsed then return false end

    local expandedItems = 0
    for k, v in pairs(pane.collapsed) do
        if not pane.collapsed[k] then
            expandedItems = 1
            break
        end
    end

    return expandedItems == 0
end

function Handler:handleJoypadContextMenu(context)
    local isAllCollapsed = self:isAllCollapsed()
    local text = isAllCollapsed and getText("UI_CleanUI_ExpandAll") or getText("UI_CleanUI_CollapseAll")
    self:addJoypadContextMenuOption(context, text)
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