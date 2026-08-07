require "Entity/ISUI/Components/ISBaseComponentPanel"

NC_CraftBenchPanel = ISBaseComponentPanel:derive("NC_CraftBenchPanel")

function NC_CraftBenchPanel.CanCreatePanelFor(_player, _entity, _component, _componentUiScript)
    if _player and _entity and _component then
        return _component:getComponentType() == ComponentType.CraftBench
    end
    return false
end

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --

function NC_CraftBenchPanel:initialise()
    ISBaseComponentPanel.initialise(self)
end

function NC_CraftBenchPanel:new(x, y, width, height, player, entity, component, componentUiStyle)
    local o = ISBaseComponentPanel:new(x, y, width, height, player, entity, component, componentUiStyle)
    setmetatable(o, self)
    self.__index = self

    o.enableHeader = false
    o:noBackground()
    
    o.minimumWidth = NCConfig.minPanelWidth
    o.minimumHeight = NCConfig.contentMinHeight
    
    return o
end

function NC_CraftBenchPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(_preferredWidth or 0, self.minimumWidth)
    local height = math.max(_preferredHeight or 0, self.minimumHeight)

    if self.HandCraftPanel then
        self.HandCraftPanel:setX(0)
        self.HandCraftPanel:setY(0)
        self.HandCraftPanel:calculateLayout(width, height)

        width = math.max(width, self.HandCraftPanel:getWidth())
        height = self.HandCraftPanel:getHeight()
    end
    
    self:setWidth(width)
    self:setHeight(height)
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --

function NC_CraftBenchPanel:createChildren()
    ISBaseComponentPanel.createChildren(self)
    
    self.HandCraftPanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", NC_HandCraftPanel, 0, 0, self.minimumWidth, self.minimumHeight, self, self.player, self.component, self.entity)
    self.HandCraftPanel:initialise()
    self:addChild(self.HandCraftPanel)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Others
-- ----------------------------------------------------------------------------------------------------- --

function NC_CraftBenchPanel:OnCloseWindow()
    if self.HandCraftPanel and self.HandCraftPanel.OnCloseWindow then
        self.HandCraftPanel:OnCloseWindow()
    end
end