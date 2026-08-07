require "ISUI/ISPanel"

NB_BuildingInfoPanel = ISTableLayout:derive("NB_BuildingInfoPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)


require "neat_building/nb_inputpickerpanel"
local NB_InputSwitch_Panel = require "neat_building/nb_inputswitch_panel"

-- Singleton picker instance (prevents multiple orphan panels)
NB_PICKER_SINGLETON = NB_PICKER_SINGLETON or nil
NB_UI_UNION = NB_UI_UNION or nil

-- Debug logging
local NB_DEBUG = false
local function dprint(...)
    if NB_DEBUG then
        print(...)
    end
end

local function NB_safeCall(obj, methodName, ...)
    -- Call a method if it exists; returns nil on failure
    if not obj then return nil end
    local fn = obj[methodName]
    if not fn then return nil end
    local ok, res = pcall(fn, obj, ...)
    if ok then return res end
    return nil
end

local function NB_isPanelVisible(panel)
    -- Return true if panel exists, is visible and has a positive size.
    if not panel then return false end
    if panel.isVisible and not panel:isVisible() then return false end
    local w = panel.getWidth and panel:getWidth() or panel.width or 0
    local h = panel.getHeight and panel:getHeight() or panel.height or 0
    if w <= 0 or h <= 0 then return false end
    return true
end

local function NB_leftMouseDown()
    -- Cross-build check for "left mouse button is down"
    if isMouseButtonDown then
        local ok, res = pcall(isMouseButtonDown, 0)
        if ok then return res == true end
    end
    if Mouse and Mouse.isButtonDown then
        local ok, res = pcall(Mouse.isButtonDown, 0)
        if ok then return res == true end
    end
    return false
end

local function NB_hidePicker()
    -- Hide the singleton and clear union state
    if NB_PICKER_SINGLETON then
        NB_PICKER_SINGLETON:setVisible(false)
    end
    NB_UI_UNION = nil
end

local function NB_getOrCreatePicker(player, logic)
    -- Create a single top-level picker and reuse it
    if not NB_PICKER_SINGLETON then
        NB_PICKER_SINGLETON = NB_InputSwitch_Panel:new(0, 0, 260, 180, player, logic)
        NB_PICKER_SINGLETON:initialise()
        NB_PICKER_SINGLETON:addToUIManager()
        NB_PICKER_SINGLETON:setVisible(false)
        if NB_PICKER_SINGLETON.setAlwaysOnTop then
            NB_PICKER_SINGLETON:setAlwaysOnTop(true)
        end
    end

    -- Always keep references updated
    NB_PICKER_SINGLETON.player = player
    NB_PICKER_SINGLETON.logic = logic
    return NB_PICKER_SINGLETON
end


-- ----------------------------------------------------------------------------------------------------- --
-- Update Position
-- ----------------------------------------------------------------------------------------------------- --

-- Keep NB's BuildingInfoPanel open while the mouse is over the floating input picker.
local _XP_NB_oldIsMouseOver = NB_BuildingInfoPanel.isMouseOver
function NB_BuildingInfoPanel:isMouseOver()
    -- First, keep original behavior
    if _XP_NB_oldIsMouseOver and _XP_NB_oldIsMouseOver(self) then
        return true
    end

    -- Then extend to include the picker
    local picker = self.NB_inputPicker
    if picker and NB_isPanelVisible(picker) and picker.isMouseOver and picker:isMouseOver() then
        return true
    end

    return false
end


function NB_BuildingInfoPanel:updatePosition()
    if not self.BuildingPanel then return end

    local ScreenPadding = 2
    local sw = math.floor(getCore():getScreenWidth() + 0.5)

    -- Use integer geometry to prevent 1px jitter when docking to the right.
    local buildX = math.floor(self.BuildingPanel:getAbsoluteX() + 0.5)
    local buildW = math.floor(self.BuildingPanel:getWidth() + 0.5)
    local infoW  = math.floor(self:getWidth() + 0.5)

    local rightX = buildX + buildW + ScreenPadding
    local leftX  = buildX - infoW - ScreenPadding

    local fitsRight = (rightX + infoW) <= sw
    local fitsLeft  = leftX >= 0

    -- Remember last side, so it stays stable when both sides fit.
    self.NB_dockSide = self.NB_dockSide or "right"
    local newX

    if fitsRight and fitsLeft then
        newX = (self.NB_dockSide == "left") and leftX or rightX
    elseif fitsRight then
        newX = rightX
        self.NB_dockSide = "right"
    elseif fitsLeft then
        newX = leftX
        self.NB_dockSide = "left"
    else
        -- Neither fits: clamp to screen edge, depending on chosen side
        if self.NB_dockSide == "left" then
            newX = 0
        else
            newX = math.max(0, sw - infoW)
        end
    end

    -- Keep NB's original Y behavior (centered vs BuildingPanel, clamped to its bottom)
    local buildCenterY = self.BuildingPanel:getAbsoluteY() + self.BuildingPanel:getHeight() / 2
    local newY = buildCenterY - self.height / 2

    local buildBottom = self.BuildingPanel:getAbsoluteY() + self.BuildingPanel:getHeight()
    if newY + self.height > buildBottom then
        newY = buildBottom - self.height
    end

    -- Round computed positions to keep stable gaps.
    newX = math.floor(newX + 0.5)
    newY = math.floor(newY + 0.5)

    self:setX(newX)
    self:setY(newY)

    -- Also dock the picker to this panel every frame (so it follows dragging)
    local picker = self.NB_inputPicker
    if picker and NB_isPanelVisible(picker) then
        local gap = 1
        local pickerW = picker.width or 0

        local px
        if self.NB_dockSide == "left" then
            -- Picker left of InfoPanel; if it doesn't fit, clamp to 0 (overlap)
            px = newX - pickerW - gap
            if px < 0 then px = 0 end
        else
            -- Picker right of InfoPanel; if it doesn't fit, clamp to right edge (overlap)
            px = newX + infoW + gap
            if (px + pickerW) > sw then
                px = math.max(0, sw - pickerW)
            end
        end

        -- Keep picker top aligned to InfoPanel top
        local py = newY

        px = math.floor(px + 0.5)
        py = math.floor(py + 0.5)

        picker:setX(px)
        picker:setY(py)
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- initialise
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingInfoPanel:initialise()
    ISTableLayout.initialise(self)
    self:updatePosition()
end

function NB_BuildingInfoPanel:new(x, y, width, height, BuildingPanel)
    local o = ISTableLayout:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.BuildingPanel = BuildingPanel
    o.logic = BuildingPanel.logic
    o.player = BuildingPanel.player

    o.padding = BuildingPanel.padding
    o.iconSize = math.floor(FONT_HGT_SMALL * 4/16)*16

    o.lvlRecipePanelminH = o.iconSize + FONT_HGT_MEDIUM + o.padding * 4

    o.iunputItemHeight = FONT_HGT_SMALL + o.padding + FONT_HGT_MEDIUM

    o.minimumWidth = (o.iunputItemHeight * 3 ) * 2 + o.padding*3
    
    return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- createChildren
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingInfoPanel:createChildren()
    self.mainColumn = self:addColumn(nil)
    self.mainColumn.minimumWidth = self.minimumWidth

    self.lvlRecipeRow = self:addRow(nil)
    self.lvlRecipeRow.minimumHeight = self.lvlRecipePanelminH

    self.detailRow = self:addRow(nil)
    self.detailRow.minimumHeight = 0

    self.inputRow = self:addRow(nil)
    local inputRowMax = 3
    self.inputRow.minimumHeight = (inputRowMax +1) * self.padding + self.iunputItemHeight * inputRowMax

    self:createLvlRecipePanel()
    self:createDetailPanel()
    self:createInputPanel()
end

function NB_BuildingInfoPanel:createLvlRecipePanel()
    self.lvlRecipePanel = NB_LevelRecipePanel:new(0, 0, 10, 10, self)
    self.lvlRecipePanel:initialise()
    self:setElement(self.mainColumn:index(), self.lvlRecipeRow:index(), self.lvlRecipePanel)
end

function NB_BuildingInfoPanel:createDetailPanel()
    self.detailPanel = NB_BuildingInfoDetailPanel:new(0, 0, 10, 10, self)
    self.detailPanel:initialise()
    self:setElement(self.mainColumn:index(), self.detailRow:index(), self.detailPanel)
end

function NB_BuildingInfoPanel:createInputPanel()
    self.inputPanel = NB_BuildingInput_Panel:new(0, 0, 10, 10, self)
    self.inputPanel:initialise()
    self:setElement(self.mainColumn:index(), self.inputRow:index(), self.inputPanel)
end
-- ----------------------------------------------------------------------------------------------------- --
-- Update
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingInfoPanel:update()
    ISTableLayout.update(self)
end

function NB_BuildingInfoPanel:onRecipeChanged()
    if self.lvlRecipePanel and self.lvlRecipePanel.onRecipeChanged then
        self.lvlRecipePanel:onRecipeChanged()
    end

    if self.inputPanel and self.inputPanel.onRecipeChanged then
        self.inputPanel:onRecipeChanged()
    end

    self:calculateLayout()
end


function NB_BuildingInfoPanel:NB_togglePickerForSlot(slot)
    -- Validate input slot / script
    if not slot or not slot.inputScript then return end
    if not self.BuildingPanel then return end

    -- Use singleton picker (prevents multiple orphan panels)
    local picker = NB_getOrCreatePicker(self.player, self.logic)

    -- Also store on the info panel so isMouseOver() can include it
    self.NB_inputPicker = picker

    -- Toggle off if clicking the same slot again
    if picker:isVisible() and picker.ownerSlot == slot then
        picker:setVisible(false)
        NB_UI_UNION = nil
        return
    end

    -- Refresh panel contents for this InputScript
    if picker.setContext then
        picker:setContext(slot.inputScript, slot)
    end

    -- Position: near the clicked slot (will be re-docked by updatePosition())
    local gap = 6
    local sw = getCore():getScreenWidth()
    local sh = getCore():getScreenHeight()

    local px = slot:getAbsoluteX() + slot:getWidth() + gap
    local py = slot:getAbsoluteY() - 10

    px = math.max(gap, math.min(px, sw - picker.width - gap))
    py = math.max(gap, math.min(py, sh - picker.height - gap))

    picker:setX(px)
    picker:setY(py)
    picker:setVisible(true)
    picker:bringToTop()

    -- Track union panels for auto-close logic
    NB_UI_UNION = {
        buildingPanel = self.BuildingPanel,
        infoPanel = self,
        picker = picker,
        anchorOffsetY = 0,
        ignoreClickCloseUntilMouseUp = NB_leftMouseDown(),
    }
end


function NB_BuildingInfoPanel:close()
    -- Hide picker so we don't leave orphan UI around
    if self.NB_inputPicker then
        self.NB_inputPicker:setVisible(false)
        self.NB_inputPicker = nil
    end

    NB_UI_UNION = nil

    self:setVisible(false)
    self:removeFromUIManager()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Render
-- ----------------------------------------------------------------------------------------------------- --
function NB_BuildingInfoPanel:prerender()
    self:updatePosition()

    if not self.BuildingPanel or not self.BuildingPanel:isReallyVisible() then
        self:setVisible(false)
    end
    local panelBG = NinePatchTexture.getSharedTexture("media/ui/Neat_Building/Panel/MainPanelBG_RoundTop.png")
    if panelBG then
        panelBG:render(self:getAbsoluteX(), self:getAbsoluteY(), self.width, self.height, 0.1, 0.1, 0.1, 0.7)
    end
end


return NB_BuildingInfoPanel