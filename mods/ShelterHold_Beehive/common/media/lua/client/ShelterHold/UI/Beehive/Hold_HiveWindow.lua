require "ISUI/ISPanel"

Hold_HiveWindow = ISPanel:derive("Hold_HiveWindow")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_HiveWindow:initialise()
    ISPanel.initialise(self)
    self.entity:setUsingPlayer(self.player)
end

function Hold_HiveWindow:new(x, y, width, height, player, entity, entityUiStyle)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o:noBackground()
    o.player = player
    o.playerNum = player:getPlayerNum()
    o.entity = entity
    o.entityUiStyle = entityUiStyle
    o:setWantKeyEvents(true)

    o.padding = math.floor(FONT_HGT_SMALL * 0.4)
    
    return o
end

function Hold_HiveWindow:calculateLayout(_preferredWidth, _preferredHeight)
    local width = 0 or self.width
    local height = 0 or self.height

    if self.header then
        self.header:calculateLayout(0, 0)
    end

    if self.hivePanel then
        self.hivePanel:setX(0)
        self.hivePanel:setY(self.header:getHeight())
        self.hivePanel:calculateLayout(0, 0)
    end

    width = math.max(width, self.header:getWidth(), self.hivePanel:getWidth())
    height = math.max(height, self.header:getHeight() + self.hivePanel:getHeight())

    self.header:calculateLayout(width, 0)
    
    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --

function Hold_HiveWindow:createChildren()
    -- Header
    self.header = Hold_HiveWindowHeader:new(0, 0, 10, 10, self)
    self.header:initialise()
    self:addChild(self.header)

    -- CraftPanel
    self.hivePanel = Hold_HivePanel:new(0, 0, 10, 10, self.entity, self)
    self.hivePanel:initialise()
    self:addChild(self.hivePanel)
end

-- ----------------------------------------------------------------------------------------------------- --
-- entityUiStyle
-- ----------------------------------------------------------------------------------------------------- --

function Hold_HiveWindow:getWindowTitle()
    if self.entityUiStyle and self.entityUiStyle:getDisplayName() then
        return self.entityUiStyle:getDisplayName()
    end
    return getText("IGUI_HiveUI_Title")
end

function Hold_HiveWindow:getWindowIcon()
    if self.entityUiStyle and self.entityUiStyle:getIcon() then
        return self.entityUiStyle:getIcon()
    end
    return nil
end

-- ----------------------------------------------------------------------------------------------------- --
-- KeyBoard Function
-- ----------------------------------------------------------------------------------------------------- --

function Hold_HiveWindow:onKeyRelease(key)
    if key == Keyboard.KEY_ESCAPE then
        self:close()
        return true
    end
    return false
end

function Hold_HiveWindow:isKeyConsumed(key)
    return key == Keyboard.KEY_ESCAPE
end

-- ----------------------------------------------------------------------------------------------------- --
-- Other
-- ----------------------------------------------------------------------------------------------------- --

function Hold_HiveWindow:update()
    ISPanel.update(self)
    
    local valid = false
    
    if self.entity and self.player then
        local dist = 4

        if self.player:DistToProper(self.entity) <= dist then
            valid = true
        end
        
        if (not self.entity:getUsingPlayer()) or (self.entity:getUsingPlayer() ~= self.player) then
            valid = false
        end

        if self.player and self.player:getVehicle() then
            valid = false
        end
    else
        valid = false
    end
    
    if not valid then
        self:close()
    end
end

function Hold_HiveWindow:close()
    ISEntityUI.OnCloseWindow(self)

    if self.entity then
        self.entity:setUsingPlayer(nil)
    end
    
    self:removeFromUIManager()
end