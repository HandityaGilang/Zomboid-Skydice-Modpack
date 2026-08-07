require "DebugUIs/DebugMenu/Base/ISDebugSubPanelBase"

TABAS_DebugUI = ISDebugSubPanelBase:derive("TABAS_DebugUI")

local TABAS_Utils = require("TABAS_Utils")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_GameTimes = require("TABAS_GameTimes")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6
local SCROLL_BAR_WIDTH = 13

function TABAS_Utils:getDebugPrint()
    return self.DEBUG_PRINT and true or false
end

function TABAS_Utils:setDebugPrint(enabled)
    self.DEBUG_PRINT = enabled and true or false
    if isClient() and (isAdmin() or getAccessLevel() == "moderator") then
        sendClientCommand("tabas_debug", "setDebugPrint", { value = self.DEBUG_PRINT })
    end
end

function TABAS_Utils:getBenefitPrint()
    return self.DEBUG_BENEFIT_PRINT and true or false
end

function TABAS_Utils:setBenefitPrint(enabled)
    self.DEBUG_BENEFIT_PRINT = enabled and true or false
end

function TABAS_Utils:getAllowedAllAction()
    return self.DEBUG_ALLOWED_ALL_ACTION and true or false
end

function TABAS_Utils:setAllowedAllAction(enabled)
    self.DEBUG_ALLOWED_ALL_ACTION = enabled and true or false
end

function TABAS_DebugUI:initialise()
    ISPanel.initialise(self)
end


-- ----------------------- UI Build -----------------------

function TABAS_DebugUI:createChildren()
    ISPanel.createChildren(self)

    local x, y, w = UI_BORDER_SPACING + 1, UI_BORDER_SPACING + 1, self.width - UI_BORDER_SPACING * 2 - SCROLL_BAR_WIDTH - 1
    self:initHorzBars(x, w)

    local obj
    y, obj = ISDebugUtils.addLabel(self, "float_title", x + (w / 2), y, "Take A Bath And Shower Debug", UIFont.Medium)
    obj.center = true
    y, obj = ISDebugUtils.addLabel(self, "float_title2", x + (w / 2), y, "Items marked with (*) cannot be changed manually.", UIFont.Small)
    obj.center = true

    y = ISDebugUtils.addHorzBar(self, y + UI_BORDER_SPACING) + UI_BORDER_SPACING + 1

    local player = getPlayer()
    self.modData = player:getModData()

    self.rows = {}
    self.boolOptions = {}
    self.labelOptions = {}
    self.sliderOptions = {}

    -- -------- Rows definition (order == UI order) --------

    self:addBoolRow(TABAS_Utils, "DEBUG PRINT", true, "getDebugPrint", "setDebugPrint")
    self:addBoolRow(TABAS_Utils, "BENEFIT PRINT", true, "getBenefitPrint", "setBenefitPrint")
    self:addBoolRow(TABAS_Utils, "ALLOWED ALL ACTION (on Take Bath)", true, "getAllowedAllAction", "setAllowedAllAction")

    self:addHeaderRow("Bathing / Wet")

    self:addBoolRow("mod", "tabas_IsBathing", false)

    -- self:addLabelRow(nil, "NowH", "h5")
    self:addLabelRow("mod", "tabas_WetEndH", "mmss", nil, true)
    self:addLabelRow("mod", "tabas_WetGraceEndH", "mmss", nil, true)

    self:addHeaderRow("Body / Stats")

    self:addSliderRow("mod", "tabas_BodyGrime", 0, 100, 0.1, true)
    self:addSliderRow(nil, "Blood", 0, 100, 1, false)
    self:addSliderRow(nil, "Dirt", 0, 100, 1, false)

    self:addSliderRowEnum(CharacterStat.WETNESS, 1)

    self:addHeaderRow("Player Effects")

    self:addSliderRow(player, "BetaEffect", 0, 10000, 1, true)
    self:addSliderRow(player, "DepressEffect", 0, 10000, 1, true)
    self:addSliderRow(player, "PainEffect", 0, 10000, 1, true)
    self:addSliderRow(player, "SleepingTabletEffect", 0, 10000, 1, true)

    -- -------- Build UI --------

    local barMod = UI_BORDER_SPACING
    local y2, label, value, slider, tickbox

    for i = 1, #self.rows do
        local v = self.rows[i]

        if v.type == "header" then
            y2, v.label = ISDebugUtils.addLabel(self, v, x + (w / 2), y, v.text, v.font)
            v.label.center = true

        elseif v.type == "bool" then
            y2, v.label = ISDebugUtils.addLabel(self, v, x, y, v.text, UIFont.Small)

            local tickOptions = {}
            table.insert(tickOptions, { text = getText("IGUI_DebugMenu_Enabled"), ticked = false })
            y, tickbox = ISDebugUtils.addTickBox(self, v, x + (w - 300), y, 300, BUTTON_HGT, v.var, tickOptions, TABAS_DebugUI.onTicked)

            v.tickbox = tickbox

        elseif v.type == "label" then
            y2, v.label = ISDebugUtils.addLabel(self, v, x, y, v.text, UIFont.Small)
            y2, v.labelValue = ISDebugUtils.addLabel(self, v, x + (w - 300) - 20, y, "-", UIFont.Small, false)

        elseif v.type == "slider" then
            y2, v.label = ISDebugUtils.addLabel(self, v, x, y, v.text, UIFont.Small)
            y2, v.labelValue = ISDebugUtils.addLabel(self, v, x + (w - 300) - 20, y, "0", UIFont.Small, false)

            y, slider = ISDebugUtils.addSlider(self, v, x + (w - 300), y, 300, BUTTON_HGT, TABAS_DebugUI.onSliderChange)
            slider.valueLabel = v.labelValue

            v.slider = slider
            slider:setValues(v.min, v.max, v.step, v.step, true)

            local val = self:resolveValue(v)
            slider:setCurrentValue(val)
        end

        y = ISDebugUtils.addHorzBar(self, math.max(y, y2) + barMod) + barMod + 1
    end

    self:setScrollHeight(y + 1)
end


local function getBodyBloodOrDirt(var)
    local visual = getPlayer():getHumanVisual()
    local total = 0
    local maxIndex = BloodBodyPartType.MAX:index()
    if var == "Blood" then
        for i = 1, maxIndex do
            local part = BloodBodyPartType.FromIndex(i - 1)
            total = total + visual:getBlood(part)
        end
    elseif var == "Dirt" then
        for i = 1, maxIndex do
            local part = BloodBodyPartType.FromIndex(i - 1)
            total = total + visual:getDirt(part)
        end
    end
    return math.ceil(total / BloodBodyPartType.MAX:index() * 100)
end

local function fmtMMSS(sec)
    sec = math.floor(sec or 0)
    if sec <= 0 then return "0:00" end
    local m = math.floor(sec / 60)
    local s = sec - m * 60
    return string.format("%d:%02d", m, s)
end

local function remainingSeconds(endH)
    if endH <= 0 then return 0 end
    local sec = (endH - TABAS_GameTimes.getWorldAgeHours()) * 3600
    if sec <= 0 then return 0 end
    return sec
end

function TABAS_DebugUI:formatValue(v, val)
    if v.kind == "mmss" then
        return string.format("%s (%.1fs)", fmtMMSS(val), val)
    elseif v.kind == "h5" then
        return string.format("%.5f", val)
    else
        return ISDebugUtils.printval(val, 3)
    end
end

function TABAS_DebugUI:resolveValue(v)
    -- Special (by var key)
    if v.var == "NowH" then
        return TABAS_GameTimes.getWorldAgeHours()
    end

    if v.var == "Blood" or v.var == "Dirt" then
        return getBodyBloodOrDirt(v.var)
    elseif v.java == "mod" then
        local raw = self.modData[v.var] or 0
        if v.asRemaining then
            return remainingSeconds(raw)
        end
        return raw
    elseif v.enum then
        return getPlayer():getStats():get(v.enum) or 0
    elseif v.java and v.get then
        return v.java[v.get](v.java)
    end
    return 0
end

-- ----------------------- Rows API -----------------------

function TABAS_DebugUI:_normalizeText(_var, _manually)
    local text = _var
    if string.find(_var, "tabas_") then
        text = string.gsub(text, "tabas_", "")
    end
    if not _manually then
        text = text .. " (*)"
    end
    return text
end

function TABAS_DebugUI:addHeaderRow(_text, _font)
    local row = {
        type = "header",
        text = _text,
        font = _font or UIFont.Medium,
    }
    table.insert(self.rows, row)
    return row
end

function TABAS_DebugUI:addBoolRow(_java, _var, _manually, _get, _set)
    local row = {
        type = "bool",
        java = _java,
        var = _var,
        manually = _manually,
        get = _get or ("get" .. _var),
        set = _set or ("set" .. _var),
        text = self:_normalizeText(_var, _manually),
        label = nil,
        tickbox = nil,
    }
    table.insert(self.rows, row)
    table.insert(self.boolOptions, row)
    return row
end

function TABAS_DebugUI:addLabelRow(_java, _var, _kind, _get, _asRemaining)
    local row = {
        type = "label",
        java = _java,
        var = _var,
        get = _get or ("get" .. _var),
        text = self:_normalizeText(_var, false), -- always display-only
        kind = _kind, -- "mmss" / "h5" / "raw"
        asRemaining = _asRemaining or false,
        label = nil,
        labelValue = nil,
    }
    table.insert(self.rows, row)
    table.insert(self.labelOptions, row)
    return row
end

function TABAS_DebugUI:addSliderRow(_java, _var, _min, _max, _step, _manually, _get, _set)
    local row = {
        type = "slider",
        java = _java,
        var = _var,
        min = _min,
        max = _max,
        step = _step or 0.01,
        manually = _manually,
        get = _get or ("get" .. _var),
        set = _set or ("set" .. _var),
        text = self:_normalizeText(_var, _manually),
        label = nil,
        labelValue = nil,
        slider = nil,
    }
    table.insert(self.rows, row)
    table.insert(self.sliderOptions, row)
    return row
end

function TABAS_DebugUI:addSliderRowEnum(_enum, _step)
    local row = {
        type = "slider",
        enum = _enum,
        var = _enum:getId(),
        min = _enum:getMinimumValue(),
        max = _enum:getMaximumValue(),
        step = _step or 0.01,
        manually = true,
        text = _enum:getId(), -- keep raw id
        label = nil,
        labelValue = nil,
        slider = nil,
    }
    table.insert(self.rows, row)
    table.insert(self.sliderOptions, row)
    return row
end

-- ----------------------- Update UI -----------------------

function TABAS_DebugUI:prerender()
    ISDebugSubPanelBase.prerender(self)

    for i = 1, #self.rows do
        local v = self.rows[i]

        if v.type == "slider" then
            local val = self:resolveValue(v)
            v.slider.currentValue = val
            if v.labelValue then
                v.labelValue:setName(ISDebugUtils.printval(val, 3))
            end

        elseif v.type == "bool" then
            if v.java == "mod" then
                v.tickbox.selected[1] = (self.modData[v.var] and true or false)
            else
                v.tickbox.selected[1] = v.java[v.get](v.java) and true or false
            end

        elseif v.type == "label" then
            local val = self:resolveValue(v)
            if v.labelValue then
                v.labelValue:setName(self:formatValue(v, val))
            end
        end
    end
end

-- ----------------------- Handlers -----------------------

function TABAS_DebugUI:onSliderChange(_newVal, _slider)
    local v = _slider.customData
    if not v.manually then return end

    if v.java == "mod" then
        self.modData[v.var] = _newVal

    elseif v.enum then
        getPlayer():getStats():set(v.enum, _newVal)
        if isClient() then
            sendPlayerStat(getPlayer(), v.enum)
        end

    else
        v.java[v.set](v.java, _newVal)
    end
end

function TABAS_DebugUI:onTicked(_index, _selected, _arg1, _arg2, _tickbox)
    local v = _tickbox.customData
    if not v.manually then return end

    local newValue = _selected and true or false

    if v.java == "mod" then
        self.modData[v.var] = newValue
    else
        v.java[v.set](v.java, newValue)
    end
end

function TABAS_DebugUI:update()
    ISPanel.update(self)
end

function TABAS_DebugUI:new(x, y, width, height, doStencil)
    local o = {}
    o = ISDebugSubPanelBase:new(x, y, width, height, doStencil)
    setmetatable(o, self)
    self.__index = self
    return o
end
