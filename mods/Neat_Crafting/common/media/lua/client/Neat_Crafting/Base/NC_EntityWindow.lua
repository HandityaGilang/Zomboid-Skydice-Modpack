require "ISUI/ISPanel"

NC_EntityWindow = ISPanel:derive("NC_EntityWindow")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

function NC_EntityWindow.CanOpenWindowFor(_player, _entity)
    if _player and _entity then
        return ISEntityUI.HasComponentPanels(_player, _entity)
    end
    return false
end

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NC_EntityWindow:initialise()
    ISPanel.initialise(self)
end

function NC_EntityWindow:new(x, y, width, height, player, entity, entityUiStyle)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.player = player
    o.playerNum = player:getPlayerNum()
    o.entity = entity
    o.entityUiStyle = entityUiStyle
    o.hasClosedWindowInstance = false
    
    o:setWantKeyEvents(true)
    
    o.padding = NCConfig.padding
    o.headerHeight = math.floor(FONT_HGT_MEDIUM * 1.5)
    
    o.entity:setUsingPlayer(o.player)
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --

function NC_EntityWindow:createChildren()
    self:createComponentPanels()
    self:createHeader()
    self:createResizeWidget()
end

-- create Header
function NC_EntityWindow:createHeader()
    self.header = NC_CraftHeader:new(0, 0, self.width, self.headerHeight, self)
    self.header:initialise()
    self:addChild(self.header)
end

-- create Components
function NC_EntityWindow:createComponentPanels()
    self.componentPanels = ISEntityUI.GetComponentPanels(self.player, self.entity, false)
    if self.componentPanels and #self.componentPanels > 0 then
        for i, panelInfo in ipairs(self.componentPanels) do
            if panelInfo.panel then
                self:addChild(panelInfo.panel)
            end
        end
    end
end

function NC_EntityWindow:createResizeWidget()
    local resizeSize = self.padding
    self.resizeWidget = ISResizeWidget:new(self.width - resizeSize-2, self.height - resizeSize-2, resizeSize, resizeSize, self, false)
    self.resizeWidget.anchorRight = true
    self.resizeWidget.anchorBottom = true
    self.resizeWidget:initialise()
    self.resizeWidget.prerender = function(widget)
        local alpha = widget.mouseOver and 0.8 or 0.6
        widget:drawTextureScaledAspect(getTexture("media/ui/NeatUI/Resize/ResizeIcon.png"), 0, 0, widget.width, widget.height, alpha, 1, 1, 1)
    end
    self.resizeWidget.resizeFunction = function(target, newWidth, newHeight)
        target:calculateLayout(newWidth, newHeight)
    end
    self:addChild(self.resizeWidget)
end


function NC_EntityWindow:onSearchChanged(searchString)
    if self.componentPanels then
        for _, panelInfo in ipairs(self.componentPanels) do
            if panelInfo.panel and panelInfo.panel.HandCraftPanel and panelInfo.panel.HandCraftPanel.onSearchTextChanged then
                panelInfo.panel.HandCraftPanel:onSearchTextChanged(searchString)
            end
        end
    end
end


function NC_EntityWindow:calculateLayout(_preferredWidth, _preferredHeight)
    -- Debug print removed: layout can run frequently during resize.
    local width = _preferredWidth or self.width
    local height = _preferredHeight or self.height

    local minWidth = NCConfig.minPanelWidth
    local minHeight = NCConfig.windowMinHeight or NCConfig.contentMinHeight

    if width <= minWidth and height <= minHeight and 
       self.width == minWidth and self.height == minHeight then
        return
    end

    width = math.max(width, minWidth)
    height = math.max(height, minHeight)

    if self.header then
        self.header:setX(0)
        self.header:setY(0)
        self.header:calculateLayout(width, self.headerHeight)
        width = math.max(width, self.header:getWidth())
    end
    
    local y = self.headerHeight
    if self.componentPanels and #self.componentPanels > 0 then
        for i, panelInfo in ipairs(self.componentPanels) do
            if panelInfo.panel then
                panelInfo.panel:setX(0)
                panelInfo.panel:setY(y)
                panelInfo.panel:calculateLayout(width, height - y)
                
                width = math.max(width, panelInfo.panel:getWidth())
                height = math.max(height, panelInfo.panel:getHeight() + y)
            end
        end
    end
    
    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Get info
-- ----------------------------------------------------------------------------------------------------- --

-- Get TitleTexts
function NC_EntityWindow:getWindowTitle()
    if self.entityUiStyle and self.entityUiStyle:getDisplayName() then
        return self.entityUiStyle:getDisplayName()
    end
    return getText("IGUI_CraftUI_Title")
end

-- Get Icon
function NC_EntityWindow:getWindowIcon()
    if self.entityUiStyle and self.entityUiStyle:getIcon() then
        return self.entityUiStyle:getIcon()
    end
    return nil
end

-- ----------------------------------------------------------------------------------------------------- --
-- Keyboard function
-- ----------------------------------------------------------------------------------------------------- --

function NC_EntityWindow:onKeyRelease(key)
    if key == Keyboard.KEY_ESCAPE or getCore():isKey("Crafting UI", key) then
        self:close()
        return true
    end
    return false
end

function NC_EntityWindow:isKeyConsumed(key)
    return key == Keyboard.KEY_ESCAPE or getCore():isKey("Crafting UI", key)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Update:get Distance and close window
-- ----------------------------------------------------------------------------------------------------- --

function NC_EntityWindow:update()
    ISPanel.update(self)

    local valid = false
    
    if self.entity and self.player then
        local dist = 4
        
        if self.entity:getGameEntityType() == GameEntityType.IsoObject or
           self.entity:getGameEntityType() == GameEntityType.VehiclePart then
            if self.player:DistToProper(self.entity) <= dist then
                valid = true
            end
        else
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
    
    return valid
end

function NC_EntityWindow:close()
    if self.hasClosedWindowInstance then
        return
    end
    self.hasClosedWindowInstance = true

    if self.componentPanels then
        for i, panelInfo in ipairs(self.componentPanels) do
            if panelInfo.panel and panelInfo.panel.OnCloseWindow then
                panelInfo.panel:OnCloseWindow()
            end
        end
    end
    
    ISEntityUI.OnCloseWindow(self)
    
    if JoypadState.players[self.playerNum+1] then
        if isJoypadFocusOnElementOrDescendant(self.playerNum, self) then
            setJoypadFocus(self.playerNum, nil)
        end
    end
    
    if self.entity then
        self.entity:setUsingPlayer(nil)
    end
    
    self:removeFromUIManager()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --

function NC_EntityWindow:prerender()
    
    local panelbackground = NinePatchTexture.getSharedTexture("media/ui/Neat_Crafting/Panel/MainPanelBG_FlatTop.png")
    if panelbackground then
        panelbackground:render(self:getAbsoluteX(), self:getAbsoluteY() + self.headerHeight, self.width, self.height - self.headerHeight, 0.15, 0.15, 0.15, NCConfig.windowBackgroundAlpha)
    end
end

function NC_EntityWindow:render()
end