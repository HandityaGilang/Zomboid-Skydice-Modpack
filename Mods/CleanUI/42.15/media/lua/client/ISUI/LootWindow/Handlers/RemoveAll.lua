--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "ISUI/LootWindow/ISLootWindowObjectControlHandler"

ISLootWindowObjectControlHandler_RemoveAll = ISLootWindowObjectControlHandler:derive("ISLootWindowObjectControlHandler_RemoveAll")
local Handler = ISLootWindowObjectControlHandler_RemoveAll
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function Handler:shouldBeVisible()
	if self.lootWindow.onCharacter then return false end
	if self.lootWindow.inventory:isEmpty() then return false end
	if isClient() and not getServerOptions():getBoolean("TrashDeleteAll") then return false end
	if not instanceof(self.object, "IsoObject") then return false end
	local sprite = self.object:getSprite()
	return sprite and sprite:getProperties() and sprite:getProperties():has("IsTrashCan")
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
    self.control.tooltip = getText("IGUI_invpage_RemoveAll")
    self.control:initialise()
    self.control.handler = self
    
    self.control.prerender = function(btn)
        -- Background
        local alpha = btn.mouseOver and 0.8 or 0.6
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/SQBackground.png"), 0, 0, btn.width, btn.height, alpha, 0.8, 0.2, 0.2)
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/SQBorder.png"), 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)
        
        -- Icon
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Icon/Icon_TrashBin.png"), 0, 0, btn.width, btn.height, 1, 0.8, 0.8, 0.8)
        btn:updateTooltip()
    end
end

function Handler:handleJoypadContextMenu(context)
    local option = self:addJoypadContextMenuOption(context, getText("IGUI_invpage_RemoveAll"))
    option.iconTexture = ContainerButtonIcons.bin
end

function Handler:perform()
    if isGamePaused() then return end
    self.lootWindow.inventoryPane:removeAll(self.playerNum)
end

function Handler:new()
    local o = ISLootWindowObjectControlHandler.new(self)
    o.altColor = false
    return o
end
