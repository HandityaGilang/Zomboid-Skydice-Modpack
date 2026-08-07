require "Entity/ISUI/Controls/ISTableLayout"
require "ShelterHold/Hold_BeehiveCompat"

Hold_ExtPanel = ISTableLayout:derive("Hold_ExtPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtPanel:initialise()
    ISTableLayout.initialise(self)
end

function Hold_ExtPanel:new(x, y, width, height, entity, parentWindow)
    local o = ISTableLayout:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.parentWindow = parentWindow
    o.player = parentWindow.player
    o.playerNum = parentWindow.playerNum
    o.entity = entity
    o.canExtract = false

    o.padding = parentWindow.padding
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --

function Hold_ExtPanel:createChildren()
    self:addColumnFill(nil)

    local spacingCol1 = self:addRow(nil)
    spacingCol1.minimumHeight = self.padding

    -- Tips Cell
    self.tipsCell = self:addRow(nil)

    local spacingCol2 = self:addRow(nil)
    spacingCol2.minimumHeight = self.padding

    -- Input Cell
    self.inputCell = self:addRow(nil)

    local spacingCol3 = self:addRow(nil)
    spacingCol3.minimumHeight = self.padding

    -- Product Cell
    self.productCell = self:addRow(nil)

    local spacingCol4 = self:addRow(nil)
    spacingCol4.minimumHeight = self.padding

    self:createTipsCell()
    self:createInputCell()
    self:createProductCell()
end

function Hold_ExtPanel:createTipsCell()
    self.tipsPanel = Hold_ExtTipsPanel:new(0, 0, 10, 10, self)
    self.tipsPanel:initialise()
    self:setElement(0, self.tipsCell:index(), self.tipsPanel)
end

function Hold_ExtPanel:createInputCell()
    self.inputPanel = Hold_ExtInputPanel:new(0, 0, 10, 10, self)
    self.inputPanel:initialise()
    self:setElement(0, self.inputCell:index(), self.inputPanel)
end

function Hold_ExtPanel:createProductCell()
    self.productCellPanel = Hold_ExtProductCell:new(0, 0, 10, 10, self)
    self.productCellPanel:initialise()
    self:setElement(0, self.productCell:index(), self.productCellPanel)
end

-- ----------------------------------------------------------------------------------------------------- --
-- Valid
-- ----------------------------------------------------------------------------------------------------- --
function Hold_ExtPanel:isValidHoneyFrame(item)
    if not item then return false end

    if HoldBeehiveCompat.isHiveFrame(item)
        and item:getCurrentUsesFloat() >= 0.5
        and item:getCondition() > 0 then
        return true
    end

    return false
end

function Hold_ExtPanel:checkCanExtract()
    if self.entity:getFluidContainer():isFull() then
        self.canExtract = false
        return
    end

    if self.actionExtract then
        self.canExtract = false
        return
    end

    local children = self.inputPanel:getChildren()
	for _,child in pairs(children) do
		if child.actionAdd or child.actionRemove then
			self.canExtract = false
            return
		end
	end

    local resources = self.entity:getComponent(ComponentType.Resources)
    local inputResources = resources:getResourcesForGroup("input_slot")

    for i = 0, inputResources:size() - 1 do
        local resource = inputResources:get(i)
        if resource and not resource:isEmpty() then
            local item = resource:peekItem()
            if item and self:isValidHoneyFrame(item) then
                self.canExtract = true
                return
            end
        end
    end
    
    return false
end

-- ----------------------------------------------------------------------------------------------------- --
-- Helper Handler
-- ----------------------------------------------------------------------------------------------------- --

function Hold_ExtPanel:walkToEntity()
    local square = self.entity:getSquare()
	local adjacent = AdjacentFreeTileFinder.FindClosest(square, self.player)
	if adjacent == nil then return false end
	local x = adjacent:getX()
	local y = adjacent:getY()
	local z = adjacent:getZ()
	if adjacent == square:getAdjacentSquare(IsoDirections.NW) then
		x = x + 0.8
		y = y + 0.8
	elseif adjacent == square:getAdjacentSquare(IsoDirections.NE) then
		x = x + 0.2
		y = y + 0.8
	elseif adjacent == square:getAdjacentSquare(IsoDirections.SE) then
		x = x + 0.2
		y = y + 0.2
	elseif adjacent == square:getAdjacentSquare(IsoDirections.SW) then
		x = x + 0.8
		y = y + 0.2
	else
		x = x + 0.5
		y = y + 0.5
	end
	if (square:getZ() == self.player:getCurrentSquare():getZ()) and
			(self.player:DistToSquared(x, y) < 0.2 * 0.2) then
		return true
	end
	ISTimedActionQueue.add(ISPathFindAction:pathToLocationF(self.player, x, y, z))
    return true
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --

function Hold_ExtPanel:update()
    self:checkCanExtract()
end

function Hold_ExtPanel:prerender()
    local bg = NinePatchTexture.getSharedTexture("media/ui/NeatUI/DefaultPanel/MainPanelBG_FlatTop.png")
    if bg then
        bg:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.15, 0.15, 0.15, 1)
    end
end

function Hold_ExtPanel:render()
    ISPanel.render(self)
end

return Hold_ExtPanel