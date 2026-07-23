if isServer() and not isClient() then return end

require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISButton"
require "DCS_UI_Scale"

DCS_UI_HelpWindow = {}
DCS_UI_HelpWindow.instance = nil

local S = DCS_UI_Scale.s
local FONT = UIFont.Small
local FONT_H = DCS_UI_Scale.fontHgt
local HELP_W = S(540)
local HELP_H = S(420)
local PAD = S(10)
local TEXT_PAD = S(10)
local SCROLL_W = S(30)
local LINE_H = FONT_H + S(4)

local COL_BG = { r = 0.12, g = 0.12, b = 0.12 }
local COL_ACCENT = { r = 0.95, g = 0.75, b = 0.20 }
local COL_TEXT = { r = 0.90, g = 0.90, b = 0.90 }
local COL_DIM = { r = 0.60, g = 0.60, b = 0.60 }
local COL_YELLOW = { r = 0.95, g = 0.80, b = 0.20 }
local COL_LIGHTGREY = { r = 0.75, g = 0.75, b = 0.75 }
local COL_WHITE = { r = 1.0, g = 1.0, b = 1.0 }

DCS_HelpInfo_Window = ISCollapsableWindow:derive("DCS_HelpInfo_Window")

function DCS_HelpInfo_Window:new(x, y, title, lines)
    local o = ISCollapsableWindow.new(self, x, y, HELP_W, HELP_H)
    o.moveWithMouse = true
    o.resizable = false
    o.helpLines = lines or {}
    o.helpTitle = title or "Help"
    return o
end

function DCS_HelpInfo_Window:createChildren()
    ISCollapsableWindow.createChildren(self)

    local titleH = FONT_H + S(1)
    local y = titleH + PAD
    local winW = self:getWidth()
    local winH = self:getHeight()
    local listW = winW - PAD * 2
    local listH = winH - titleH - PAD - S(30) - PAD

    self.helpList = ISScrollingListBox:new(PAD, y, listW, listH)
    self.helpList:initialise()
    self.helpList:instantiate()
    self.helpList.itemheight = LINE_H
    self.helpList.selected = 0
    self.helpList.font = FONT
    self.helpList.drawBorder = true
    self.helpList.doDrawItem = DCS_HelpInfo_Window.drawHelpLine
    self:addChild(self.helpList)

    local maxW = listW - TEXT_PAD * 2 - SCROLL_W
    for _, line in ipairs(self.helpLines) do
        if line == "" or string.sub(line, 1, 3) == "---" then
            self.helpList:addItem(line, line)
        else
            local wrapped = self:wrapLine(line, maxW)
            for _, wl in ipairs(wrapped) do
                self.helpList:addItem(wl, wl)
            end
        end
    end

    self.btnClose = ISButton:new(winW - PAD - S(90), winH - S(30), S(90), FONT_H + S(5),
        getText("IGUI_DCS_Common_Close"), self, DCS_HelpInfo_Window.onClose)
    self.btnClose:initialise()
    self.btnClose:instantiate()
    self:addChild(self.btnClose)
end

function DCS_HelpInfo_Window:wrapLine(line, maxW)
    local tmgr = getTextManager()
    if tmgr:MeasureStringX(FONT, line) <= maxW then
        return { line }
    end
    local wrapped = tmgr:WrapText(FONT, line, maxW, 10, "")
    local result = {}
    for segment in string.gmatch(wrapped, "[^\n]+") do
        result[#result + 1] = segment
    end
    return #result > 0 and result or { line }
end

function DCS_HelpInfo_Window:initialise()
    ISCollapsableWindow.initialise(self)
end

function DCS_HelpInfo_Window:drawHelpLine(y, item, alt)
    local text = item.item or ""
    local w = self:getWidth()

    self:drawRect(0, y, w, LINE_H - S(1), 1, 0.0, 0.0, 0.0)

    local isHeader = string.sub(text, 1, 3) == "---"
    if isHeader then
        self:drawText(text, TEXT_PAD, y + S(2),
            COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 1, FONT)
    elseif text == "" then
    else
        local sep = string.find(text, ":")
        if sep then
            local label = string.sub(text, 1, sep)
            local rest = string.sub(text, sep + 1)
            self:drawText(label, TEXT_PAD, y + S(2),
                COL_WHITE.r, COL_WHITE.g, COL_WHITE.b, 1, FONT)
            local labelW = getTextManager():MeasureStringX(FONT, label)
            self:drawText(rest, TEXT_PAD + labelW, y + S(2),
                COL_LIGHTGREY.r, COL_LIGHTGREY.g, COL_LIGHTGREY.b, 1, FONT)
        else
            self:drawText(text, TEXT_PAD, y + S(2),
                COL_LIGHTGREY.r, COL_LIGHTGREY.g, COL_LIGHTGREY.b, 1, FONT)
        end
    end

    return y + LINE_H
end

function DCS_HelpInfo_Window:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
    DCS_UI_HelpWindow.instance = nil
end

function DCS_HelpInfo_Window:prerender()
    ISCollapsableWindow.prerender(self)
    local titleH = FONT_H + S(1)
    self:drawRect(0, titleH, self.width, S(2), 1, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
end

function DCS_HelpInfo_Window:close()
    self:setVisible(false)
    self:removeFromUIManager()
    DCS_UI_HelpWindow.instance = nil
end

function DCS_UI_HelpWindow.open(title, lines)
    if DCS_UI_HelpWindow.instance then
        DCS_UI_HelpWindow.instance:close()
    end
    local screenW = getPlayerScreenWidth(0)
    local screenH = getPlayerScreenHeight(0)
    local w = math.min(HELP_W, screenW - 40)
    local h = math.min(HELP_H, screenH - 40)
    local x = math.floor((screenW - w) / 2)
    local y = math.floor((screenH - h) / 2)
    local win = DCS_HelpInfo_Window:new(x, y, title, lines)
    win:setWidth(w)
    win:setHeight(h)
    win:initialise()
    win:instantiate()
    win:addToUIManager()
    win:setTitle(title)
    DCS_UI_HelpWindow.instance = win
end
