require "Entity/ISUI/Components/ISBaseComponentPanel"

NC_CraftLogicPanel = ISBaseComponentPanel:derive("NC_CraftLogicPanel")

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --

function NC_CraftLogicPanel:initialise()
    ISBaseComponentPanel.initialise(self)
end

function NC_CraftLogicPanel:new(x, y, width, height, player, entity, component, componentUiStyle)
    local o = ISBaseComponentPanel:new(x, y, width, height, player, entity, component, componentUiStyle)
    setmetatable(o, self)
    self.__index = self

    o.inputsGroupName = component:getInputsGroupName()
    o.outputsGroupName = component:getOutputsGroupName()
    o.resourcesComponent = entity and entity:getComponent(ComponentType.Resources)
    o.craftLogicComponent = component
    o.logic = CraftLogicUILogic.new(player, entity, component)

    o.logic:addEventListener("onRecipeChanged", o.onRecipeChanged, o)
    o.logic:addEventListener("onUpdateRecipeList", o.onUpdateRecipeList, o)
    o.logic:addEventListener("onShowManualSelectChanged", o.onShowManualSelectChanged, o)
    o.logic:addEventListener("onResourceSlotContentsChanged", o.onResourceSlotContentsChanged, o)

    o.minimumWidth = 400
    o.minimumHeight = 300
    
    return o
end

function NC_CraftLogicPanel:createChildren()

    self.tableLayout = ISXuiSkin.build(self.xuiSkin, "S_TableLayout_Main", ISTableLayout, 0, 0, 10, 10)
    self.tableLayout:addRowFill(nil)
    self.tableLayout:initialise()
    self.tableLayout:instantiate()
    self:addChild(self.tableLayout)

    self:createInventoryPanel()

    self:updateContainers()
end

function NC_CraftLogicPanel:updateContainers()
    local containers = ISInventoryPaneContextMenu.getContainers(self.player)
    self.logic:setContainers(containers)

    if self.inventoryPanel then
        self.inventoryPanel:updateContainers(containers)
    end
end

function NC_CraftLogicPanel:createInventoryPanel()
    self.inventoryPanel = ISXuiSkin.build(self.xuiSkin, "S_NeedsAStyle", NC_CraftLogicInventoryPanel, 0, 0, 400, 500, self.player, self.logic)
    self.inventoryPanel:initialise()
    self.inventoryPanel:instantiate()

    local column = self.tableLayout:addColumn(nil)
    self.tableLayout:setElement(column:index(), 0, self.inventoryPanel)
end

function NC_CraftLogicPanel:calculateLayout(_preferredWidth, _preferredHeight)
    local width = math.max(self.minimumWidth, _preferredWidth or 0)
    local height = math.max(self.minimumHeight, _preferredHeight or 0)

        self.tableLayout:setX(0)
        self.tableLayout:setY(headerHeight)
        self.tableLayout:calculateLayout(width, height)

        width = math.max(width, self.tableLayout:getWidth())
        height = math.max(height, self.tableLayout:getHeight())

    self:setWidth(width)
    self:setHeight(height)
end

function NC_CraftLogicPanel:update()
    ISBaseComponentPanel.update(self)
end

function NC_CraftLogicPanel:onRecipeChanged(_recipe)
    if self.inventoryPanel then
        self.inventoryPanel:onRecipeChanged()
    end
end

function NC_CraftLogicPanel:onUpdateRecipeList(_recipeList)
    if self.inventoryPanel then
        self.inventoryPanel:onUpdateRecipeList()
    end
end

function NC_CraftLogicPanel:onResourceSlotContentsChanged()
    if self.inventoryPanel then
        self.inventoryPanel:onContainersChanged()
    end
end

function NC_CraftLogicPanel:onShowManualSelectChanged(_showManualSelectInputs)
end
-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NC_CraftLogicPanel:prerender()
    ISBaseComponentPanel.prerender(self)
end