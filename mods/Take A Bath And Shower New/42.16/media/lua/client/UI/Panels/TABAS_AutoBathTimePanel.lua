require("ISUI/ISPanelJoypad")

TABAS_AutoBathTimePanel = ISPanelJoypad:derive("TABAS_AutoBathTimePanel")

local TABAS_Panel = require("UI/TABAS_PanelUtils")

local CONST = require("UI/TABAS_PanelConst")
local FONT_HGT_SMALL = CONST.SCALE.HGT_SMALL
local BORDER_SPACING = CONST.SCALE.BORDER_SPACING
local HGT_BUTTON = CONST.SCALE.HGT_BUTTON

function TABAS_AutoBathTimePanel:initialise()
    ISPanelJoypad.initialise(self)
end

function TABAS_AutoBathTimePanel:createChildren()
    ISPanelJoypad.createChildren(self)

    local x = BORDER_SPACING
    local y = BORDER_SPACING
	self.btnMinus = TABAS_Panel.addButton(x, y, FONT_HGT_SMALL, FONT_HGT_SMALL, self.tex_minusIcon, nil, nil, self, self.onClick, true)
	self.btnMinus.internal = "TIMEMINUS"


    self.entryBoxX = self.btnMinus:getRight() + BORDER_SPACING
    self.entryBoxWidth = FONT_HGT_SMALL * 2 + BORDER_SPACING
    self.bathTimeEntry = ISLabel:new(self.entryBoxX + self.entryBoxWidth / 2, y, FONT_HGT_SMALL, tostring(self.selectedBathTime), 1, 1, 1, 1, UIFont.Small, true)
    self.bathTimeEntry:initialise()
    self.bathTimeEntry:instantiate()
    self.bathTimeEntry.center = true
    self:addChild(self.bathTimeEntry)

    x = self.entryBoxX + self.entryBoxWidth + BORDER_SPACING
	self.btnPlus = TABAS_Panel.addButton(x, y, FONT_HGT_SMALL, FONT_HGT_SMALL, self.tex_plusIcon, nil, nil, self, self.onClick, true)
	self.btnPlus.internal = "TIMEPLUS"

    self:updateEntryLabel()
    self:setWidth(self.btnPlus:getRight() + BORDER_SPACING)
end

function TABAS_AutoBathTimePanel:prerender()
    ISPanelJoypad.prerender(self)
    self:drawTextureScaled(self.bg_label, self.entryBoxX, self.bathTimeEntry:getY()+FONT_HGT_SMALL*0.2, self.entryBoxWidth, FONT_HGT_SMALL*0.8, 0.4,0.2,0.2,0.2)
end

function TABAS_AutoBathTimePanel:render()
    ISPanelJoypad.render(self)
    -- self:renderJoypadFocus()
end

function TABAS_AutoBathTimePanel:onClick(_btn)
    if not self.enabled then
        return
    end
    local currentTime = self.selectedBathTime
    if _btn.internal == "TIMEPLUS" and currentTime < 120 then
        currentTime = currentTime + 10
    elseif _btn.internal == "TIMEMINUS" and currentTime > 10 then
        currentTime = currentTime - 10
    else
        return
    end
    self.selectedBathTime = currentTime
    self:updateEntryLabel()
end

function TABAS_AutoBathTimePanel:getEntryTime()
    if not self:isAutoModeEnabled() then
        return 0
    end
    return self.selectedBathTime
end

function TABAS_AutoBathTimePanel:isInteractionDisabled()
    return self._entryPanel and self._entryPanel.interactionDisabled == true
end

function TABAS_AutoBathTimePanel:isAutoModeEnabled()
    local toggle = self._entryPanel and self._entryPanel.tglAutoMode
    if not toggle then
        return true
    end
    if toggle.toggleState ~= nil then
        return toggle.toggleState == true
    end
    return toggle.value == true
end

function TABAS_AutoBathTimePanel:updateEntryLabel()
    local label = self:isAutoModeEnabled() and tostring(self.selectedBathTime) or "-"
    self.bathTimeEntry:setName(label)
end

function TABAS_AutoBathTimePanel:syncEnabled()
    self.enabled = self:isAutoModeEnabled() and not self:isInteractionDisabled()
    self.btnMinus:setEnable(self.enabled)
    self.btnPlus:setEnable(self.enabled)
    self:updateEntryLabel()
end

function TABAS_AutoBathTimePanel:update()
    if self._managedByParent then return end
    self:syncEnabled()
end

function TABAS_AutoBathTimePanel:new(x, y, playerObj, tfc_Base)
    local width = FONT_HGT_SMALL * 4 + BORDER_SPACING * 4
    local height = FONT_HGT_SMALL + BORDER_SPACING * 2

    local o = ISPanelJoypad:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y
    o.width = width
    o.height = height
    o.playerObj = playerObj
    o.tfc_Base = tfc_Base
    o.tex_plusIcon = CONST.TEXTURE.plusIcon
    o.tex_minusIcon = CONST.TEXTURE.minusIcon
    o.bg_label = CONST.TEXTURE.bg_label
    o.backgroundColor = CONST.COLOR.backgroundColor
    o.selectedBathTime = 20
    o.enabled = true
    return o
end
