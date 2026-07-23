--***********************************************************
--**                    THE INDIE STONE                    **
--***********************************************************

require "ISUI/LootWindow/ISLootWindowObjectControlHandler"

ISLootWindowObjectControlHandler_VehicleLockTrunk = ISLootWindowObjectControlHandler:derive("ISLootWindowObjectControlHandler_VehicleLockTrunk")
local Handler = ISLootWindowObjectControlHandler_VehicleLockTrunk
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

function Handler:shouldBeVisible()
    if getCore():getGameMode() == "Tutorial" then return false end
    if not instanceof(self.object, "BaseVehicle") then return false end
    local doorPart = self.object:getUseablePart(self.playerObj)
    if doorPart and doorPart:getDoor() and doorPart:getInventoryItem() then
        if not self.object:canLockDoor(doorPart, self.playerObj) then return false end
        return doorPart:getId() == "TrunkDoor" or doorPart:getId() == "DoorRear"
    end
    return false
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
    self.control.tooltip = getText("IGUI_LockTrunk")
    self.control:initialise()
    self.control.handler = self
    
    self.control.prerender = function(btn)
        -- Background
        local alpha = btn.mouseOver and 0.8 or 0.6
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/SQBackground.png"), 0, 0, btn.width, btn.height, alpha, 0.6, 0.3, 0.1)
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Button/2_3Border.png"), 0, 0, btn.width, btn.height, 1, 0.4, 0.4, 0.4)
        
        -- Icon
        btn:drawTextureScaled(getTexture("media/ui/CleanUI/Icon/Icon_LockTruckDoor.png"), 0, 0, btn.width, btn.height, 1, 0.7, 0.7, 0.7)
        btn:updateTooltip()
    end
end

function Handler:handleJoypadContextMenu(context)
    local option = self:addJoypadContextMenuOption(context, getText("IGUI_LockTrunk"))
    option.iconTexture = ContainerButtonIcons[self.container:getType()]
end

function Handler:perform()
    if isGamePaused() then return end
    local doorPart = self.object:getUseablePart(self.playerObj)
	ISTimedActionQueue.add(ISCloseVehicleDoor:new(self.playerObj, self.object, doorPart))
	ISTimedActionQueue.add(ISLockVehicleDoor:new(self.playerObj, doorPart))
end

function Handler:new()
    local o = ISLootWindowObjectControlHandler.new(self)
    o.altColor = true
    return o
end
