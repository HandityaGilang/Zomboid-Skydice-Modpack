require("ISUI/ISPanel")

TABAS_BathSessionPanel = ISPanel:derive("TABAS_BathSessionPanel")

local TABAS_TakeBathSession = require("Bathing/TABAS_TakeBathSession")

local CONST = require("UI/TABAS_PanelConst")
local FONT_HGT_SMALL = CONST.SCALE.HGT_SMALL
local BETWEEN_SPACING = CONST.SCALE.BETWEEN_SPACING
local BORDER_SPACING = CONST.SCALE.BORDER_SPACING

local function getSessionStateText(session, bathingPhaseActive, bathingPhaseText)
    if not session then
        return bathingPhaseActive and (bathingPhaseText or getText("ContextMenu_TABAS_BathStatusPending")) or getText("UI_No")
    end
    if session.isFinished then
        return getText("ContextMenu_TABAS_BathSessionFinished")
    end
    if session.isStopping then
        return getText("ContextMenu_TABAS_BathSessionStopping")
    end
    if session.isAutoMode then
        return getText("ContextMenu_TABAS_BathSessionAuto")
    end
    return getText("ContextMenu_TABAS_BathSessionManual")
end

function TABAS_BathSessionPanel:initialise()
    ISPanel.initialise(self)
end

function TABAS_BathSessionPanel:createChildren()
end

function TABAS_BathSessionPanel:getSession()
    return TABAS_TakeBathSession:get(self.playerObj)
end

function TABAS_BathSessionPanel:setBathingPhaseState(active, text)
    self.bathingPhaseActive = active == true
    self.bathingPhaseText = text
end

function TABAS_BathSessionPanel:prerender()
    ISPanel.prerender(self)

    local labelColor = CONST.COLOR.labelColor
    local textColor = CONST.COLOR.textColor
    self:drawText(self.title, BORDER_SPACING, BORDER_SPACING, labelColor.r, labelColor.g, labelColor.b, labelColor.a, UIFont.Small)

    local session = self:getSession()
    local remainingText = "-"
    if session and session.isAutoMode and not session.isFinished then
        remainingText = tostring(math.ceil(session:getRemainingMinutes())) .. getText("IGUI_Gametime_minutes")
    end

    local stance = session and (session.curStance or self.playerObj:getVariableString("TABAS_BathStance")) or ""
    if stance == nil or stance == "" then
        stance = self.bathingPhaseActive and (self.bathingPhaseText or getText("ContextMenu_TABAS_BathStatusPending")) or getText("ContextMenu_TABAS_BathStatusPending")
    end
    local washProgress = session and string.format("%d / %d", session.washCount or 0, session.autoWashTargetCount or 0) or "-"
    local rows = {
        { label = getText("ContextMenu_TABAS_BathSession"), value = getSessionStateText(session, self.bathingPhaseActive, self.bathingPhaseText) },
        { label = getText("ContextMenu_TABAS_BathRemainingTime"), value = remainingText },
        { label = getText("ContextMenu_TABAS_BathWashProgress"), value = washProgress },
        { label = getText("ContextMenu_TABAS_BathCurrentStance"), value = stance },
    }

    local labelWidth = 0
    for i = 1, #rows do
        labelWidth = math.max(labelWidth, getTextManager():MeasureStringX(UIFont.Small, rows[i].label .. ":"))
    end

    local x = BORDER_SPACING * 2
    local y = FONT_HGT_SMALL + BORDER_SPACING * 2
    local valueX = x + labelWidth + BETWEEN_SPACING
    for i = 1, #rows do
        local row = rows[i]
        self:drawText(row.label .. ":", x, y, labelColor.r, labelColor.g, labelColor.b, labelColor.a, UIFont.Small)
        self:drawText(row.value, valueX, y, textColor.r, textColor.g, textColor.b, textColor.a, UIFont.Small)
        y = y + FONT_HGT_SMALL + BORDER_SPACING * 0.5
    end
end

function TABAS_BathSessionPanel:render()
    ISPanel.render(self)
end

function TABAS_BathSessionPanel:new(x, y, width, height, playerObj, tfc_Base)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y
    o.width = width
    o.height = height
    o.playerObj = playerObj
    o.tfc_Base = tfc_Base
    o.title = getText("ContextMenu_TABAS_BathSession")
    o.backgroundColor = CONST.COLOR.backgroundColor
    o.bathingPhaseActive = false
    o.bathingPhaseText = nil
    return o
end
