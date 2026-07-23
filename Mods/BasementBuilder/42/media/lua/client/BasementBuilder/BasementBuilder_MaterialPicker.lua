require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISComboBox"
require "ISUI/ISLabel"

BasementBuilder = BasementBuilder or {}
BasementBuilderMaterialPicker = ISCollapsableWindow:derive("BasementBuilderMaterialPicker")

local UI_BORDER_SPACING = 10
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local BUTTON_HGT = FONT_HGT_SMALL + 6

local function translateOrFallback(key, fallback)
    local translated = getTextOrNull(key)
    if translated and translated ~= "" then
        return translated
    end
    return fallback
end

local function materialLabel(entry)
    if not entry then
        return translateOrFallback("UI_BB_Material_Unknown", "Unknown")
    end

    local label = translateOrFallback("UI_BB_Material_" .. tostring(entry.id or ""), entry.label or entry.id or "Material")
    local summary = translateOrFallback("UI_BB_Material_" .. tostring(entry.id or "") .. "_Desc", entry.summary or "")

    if summary and summary ~= "" then
        return label .. " - " .. summary
    end
    return label
end

function BasementBuilderMaterialPicker:onPickConfirm()
    local wallOption = self.wallCombo.options[self.wallCombo.selected]
    local floorOption = self.floorCombo.options[self.floorCombo.selected]
    if not wallOption or not floorOption then
        return
    end

    local palette = BasementBuilder.buildPaletteFromMaterials(wallOption.data, floorOption.data)
    if self.onConfirmCallback then
        self.onConfirmCallback(self.playerObj, palette)
    end
    self:close()
end

function BasementBuilderMaterialPicker:onPickCancel()
    self:close()
end

function BasementBuilderMaterialPicker:close()
    ISCollapsableWindow.close(self)
    if BasementBuilderMaterialPicker.instance == self then
        BasementBuilderMaterialPicker.instance = nil
    end
end

function BasementBuilderMaterialPicker:createChildren()
    ISCollapsableWindow.createChildren(self)

    local contentWidth = self.width - UI_BORDER_SPACING * 2
    local x = UI_BORDER_SPACING
    local y = self:titleBarHeight() + UI_BORDER_SPACING

    self.wallLabel = ISLabel:new(x, y, FONT_HGT_SMALL, getText("UI_BB_MaterialPicker_Wall"), 1, 1, 1, 1, UIFont.Small, true)
    self.wallLabel:initialise()
    self:addChild(self.wallLabel)

    y = self.wallLabel:getBottom() + 4
    self.wallCombo = ISComboBox:new(x, y, contentWidth, BUTTON_HGT, self, nil)
    self.wallCombo:initialise()
    self:addChild(self.wallCombo)

    local wallPresets = BasementBuilder.getWallMaterialPresets and BasementBuilder.getWallMaterialPresets() or {}
    for _, wallEntry in ipairs(wallPresets) do
        self.wallCombo:addOptionWithData(materialLabel(wallEntry), wallEntry.id)
    end
    self.wallCombo.selected = 1

    y = self.wallCombo:getBottom() + UI_BORDER_SPACING
    self.floorLabel = ISLabel:new(x, y, FONT_HGT_SMALL, getText("UI_BB_MaterialPicker_Floor"), 1, 1, 1, 1, UIFont.Small, true)
    self.floorLabel:initialise()
    self:addChild(self.floorLabel)

    y = self.floorLabel:getBottom() + 4
    self.floorCombo = ISComboBox:new(x, y, contentWidth, BUTTON_HGT, self, nil)
    self.floorCombo:initialise()
    self:addChild(self.floorCombo)

    local floorPresets = BasementBuilder.getFloorMaterialPresets and BasementBuilder.getFloorMaterialPresets() or {}
    for _, floorEntry in ipairs(floorPresets) do
        self.floorCombo:addOptionWithData(materialLabel(floorEntry), floorEntry.id)
    end
    self.floorCombo.selected = 1

    y = self.floorCombo:getBottom() + UI_BORDER_SPACING * 2
    local buttonWidth = math.floor((contentWidth - UI_BORDER_SPACING) / 2)

    self.confirmButton = ISButton:new(x, y, buttonWidth, BUTTON_HGT, getText("UI_BB_MaterialPicker_Confirm"), self, BasementBuilderMaterialPicker.onPickConfirm)
    self.confirmButton:initialise()
    self.confirmButton:instantiate()
    self.confirmButton:enableAcceptColor()
    self:addChild(self.confirmButton)

    self.cancelButton = ISButton:new(x + buttonWidth + UI_BORDER_SPACING, y, buttonWidth, BUTTON_HGT, getText("UI_BB_MaterialPicker_Cancel"), self, BasementBuilderMaterialPicker.onPickCancel)
    self.cancelButton:initialise()
    self.cancelButton:instantiate()
    self.cancelButton:enableCancelColor()
    self:addChild(self.cancelButton)

    self:setHeight(self.confirmButton:getBottom() + UI_BORDER_SPACING)
end

function BasementBuilderMaterialPicker:new(playerObj, onConfirmCallback)
    local width = 420
    local height = 220
    local x = math.floor((getCore():getScreenWidth() - width) / 2)
    local y = math.floor((getCore():getScreenHeight() - height) / 2)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.playerObj = playerObj
    o.onConfirmCallback = onConfirmCallback
    o.title = getText("UI_BB_MaterialPicker_Title")
    o.resizable = false
    o:setResizable(false)
    o:setDrawFrame(true)
    o.moveWithMouse = true
    return o
end

function BasementBuilder.openMaterialPicker(playerObj, onConfirmCallback)
    if BasementBuilderMaterialPicker.instance then
        BasementBuilderMaterialPicker.instance:close()
    end

    local picker = BasementBuilderMaterialPicker:new(playerObj, onConfirmCallback)
    BasementBuilderMaterialPicker.instance = picker
    picker:initialise()
    picker:addToUIManager()
    picker:setVisible(true)
    picker:bringToTop()
    return picker
end
