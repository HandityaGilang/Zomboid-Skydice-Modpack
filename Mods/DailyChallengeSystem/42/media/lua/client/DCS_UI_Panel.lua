if isServer() and not isClient() then return end

require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISButton"
require "DCS_UI_HelpWindow"
require "DCS_UI_Scale"
require "DCS_Translate"

DCS_UI_Panel = {}
DCS_UI_Panel.instance = nil
DCS_UI_Panel.toolbarBtn = nil
DCS_UI_Panel.everOpenedThisSession = false
DCS_UI_Panel.isWiggling = false
DCS_UI_Panel.wiggleStep = 0

local FONT_SM = UIFont.Small
local FONT_MD = UIFont.Medium
local S = DCS_UI_Scale.s
local fontHgt = DCS_UI_Scale.fontHgt
local fontHgtMd = DCS_UI_Scale.fontHgtMd

local PANEL_W = math.max(S(480), fontHgt * 25 + S(5))
local TAB_H = fontHgt + S(9)
local PAD = S(10)
local ROW_H = fontHgtMd + S(41)
local HEADER_H = fontHgt * 3 + S(7)
local FOOTER_H = fontHgt * 5 + S(9)
local BTN_H = fontHgt + S(9)
local TITLE_BAR_H = fontHgt + S(1)
local BOX_SIZE = fontHgt - S(3)
local BAR_H = math.max(S(5), fontHgt - S(12))
local CHECK_GAP = math.floor(fontHgt * 0.42)
local BAR_GAP = math.floor(fontHgt * 0.21)
local BAR_PAD = math.floor(fontHgt * 0.21)
local STATUS_X_PAD = math.floor(fontHgt * 1.68)
local QUEST_ROW_PAD = S(15)
local QUEST_TEXT_SLACK = ROW_H - fontHgtMd

local LB_BTN_EXTRA = TAB_H + S(6)
local PANEL_H = S(810) + LB_BTN_EXTRA

local TEX_CHECK = nil

local COL_BG = { r=0.12, g=0.12, b=0.12 }
local COL_BORDER = { r=0.55, g=0.55, b=0.60 }
local COL_ACCENT = { r=0.95, g=0.75, b=0.20 }
local COL_COMPLETE = { r=0.30, g=0.90, b=0.40 }
local COL_PENDING = { r=0.70, g=0.70, b=0.70 }
local COL_KILL = { r=0.90, g=0.30, b=0.30 }
local COL_FORAGE = { r=0.30, g=0.80, b=0.35 }
local COL_QUEST = { r=0.95, g=0.85, b=0.20 }
local COL_VISIT = { r=0.30, g=0.60, b=0.95 }
local COL_FISH = { r=0.70, g=0.35, b=0.90 }
local COL_CRAFT = { r=0.65, g=0.45, b=0.25 }
local COL_MISC = { r=0.95, g=0.55, b=0.15 }
local COL_TAB_ACT = { r=0.15, g=0.15, b=0.15 }
local COL_TAB_INACT = { r=0.10, g=0.10, b=0.10 }

local function drawBar(panel, x, y, w, ratio, col)
    ratio = math.max(0, math.min(1, tonumber(ratio) or 0))
    panel:drawRect(x, y, w, BAR_H, 0.30, 0, 0, 0)
    panel:drawRectBorder(x, y, w, BAR_H, 0.40, 1, 1, 1)
    panel:drawRect(x + S(1), y + S(1), math.max(0, (w - S(2)) * ratio), math.max(S(1), BAR_H - S(2)),
        0.85, col.r, col.g, col.b)
end

local function getTitleMaxWidth(rowWidth)
    return rowWidth - PAD - BOX_SIZE - STATUS_X_PAD
end

local function wrapTitle(title, maxWidth, font)
    local tmgr = getTextManager()
    if not tmgr or not title or title == "" then
        return title or "", tmgr and tmgr:getFontHeight(font) or 18
    end
    local wrapped = tmgr:WrapText(font, title, maxWidth, 3, "...")
    local textH = tmgr:MeasureStringY(font, wrapped)
    return wrapped, textH
end

local function balancedWrapQuest(text, font, maxW)
    local tmgr = getTextManager()
    if not tmgr or not text or text == "" then return { text or "" } end
    if tmgr:MeasureStringX(font, text) <= maxW then return { text } end

    local words = {}
    for w in text:gmatch("%S+") do words[#words + 1] = w end
    local n = #words
    if n < 2 then return { text } end

    local function width(a, b) return tmgr:MeasureStringX(font, table.concat(words, " ", a, b)) end
    local function join(a, b) return table.concat(words, " ", a, b) end

    local best2, best2Diff
    for i = 1, n - 1 do
        local w1, w2 = width(1, i), width(i + 1, n)
        if w1 <= maxW and w2 <= maxW then
            local diff = math.abs(w1 - w2)
            if not best2Diff or diff < best2Diff then
                best2Diff, best2 = diff, { join(1, i), join(i + 1, n) }
            end
        end
    end
    if best2 then return best2 end

    local m
    for k = n - 1, 2, -1 do
        if width(k + 1, n) <= maxW then
            for i = 1, k - 1 do
                if width(1, i) <= maxW and width(i + 1, k) <= maxW then m = k; break end
            end
        end
        if m then break end
    end
    if m then
        local bi, biDiff
        for i = 1, m - 1 do
            local w1, w2 = width(1, i), width(i + 1, m)
            if w1 <= maxW and w2 <= maxW then
                local diff = math.abs(w1 - w2)
                if not biDiff or diff < biDiff then biDiff, bi = diff, i end
            end
        end
        if bi then return { join(1, bi), join(bi + 1, m), join(m + 1, n) } end
    end

    local out = {}
    for line in string.gmatch(tmgr:WrapText(font, text, maxW, 99, ""), "[^\n]+") do
        out[#out + 1] = line
    end
    return #out > 0 and out or { text }
end

local function wrapQuestTitle(title, maxWidth)
    local tmgr = getTextManager()
    local mdH = (tmgr and tmgr:getFontHeight(FONT_MD)) or fontHgtMd
    if not tmgr or not title or title == "" then
        return { lines = { title or "" }, textH = mdH }
    end

    local lines
    if title:find("\n", 1, true) then
        lines = {}
        for segment in string.gmatch(title, "([^\n]+)") do
            for line in string.gmatch(tmgr:WrapText(FONT_MD, segment, maxWidth, 99, ""), "[^\n]+") do
                lines[#lines + 1] = line
            end
        end
    else
        lines = balancedWrapQuest(title, FONT_MD, maxWidth)
    end
    if #lines == 0 then lines = { title } end

    return { lines = lines, textH = #lines * mdH }
end

local function balancedWrap2(text, font, maxW)
    local tmgr = getTextManager()
    if not tmgr or not text or text == "" then return text or "" end
    if tmgr:MeasureStringX(font, text) <= maxW then return text end
    local words = {}
    for word in text:gmatch("%S+") do words[#words + 1] = word end
    if #words < 2 then return text end
    local best, bestDiff
    for i = 1, #words - 1 do
        local l1 = table.concat(words, " ", 1, i)
        local l2 = table.concat(words, " ", i + 1)
        local w1 = tmgr:MeasureStringX(font, l1)
        local w2 = tmgr:MeasureStringX(font, l2)
        if w1 <= maxW and w2 <= maxW then
            local diff = math.abs(w1 - w2)
            if not bestDiff or diff < bestDiff then
                bestDiff, best = diff, l1 .. "\n" .. l2
            end
        end
    end
    return best or tmgr:WrapText(font, text, maxW, 2, "...")
end

local function formatQuestTitle(title)
    if not title then return title end
    local tmgr = getTextManager()
    local maxTitleW = getTitleMaxWidth(PANEL_W - PAD * 2)

    if tmgr:MeasureStringX(FONT_MD, title) <= maxTitleW then
        return title
    end

    local atPos = title:find(" at ", 1, true)
    if atPos and atPos <= maxTitleW then
        local before = title:sub(1, atPos + 3)
        local after = title:sub(atPos + 4)
        return before .. "\n" .. after
    end

    for _, pattern in ipairs({ ", ", " to ", " in " }) do
        local pos = title:find(pattern, 1, true)
        if pos and pos <= maxTitleW then
            local before = title:sub(1, pos + #pattern - 1)
            local after = title:sub(pos + #pattern)
            return before .. "\n" .. after
        end
    end

    return title
end

local function formatKillCategoryTitle(title, maxWidth)
    if not title then return title end
    local tmgr = getTextManager()
    if not tmgr then return title end

    if tmgr:MeasureStringX(FONT_MD, title) <= maxWidth then return title end

    local before, after = string.match(title, "^(.+) with any (.+)$")
    if before and after then
        return before .. " with any\n" .. after
    end

    before, after = string.match(title, "^(.+) with a (.+)$")
    if before and after then
        return before .. " with a\n" .. after
    end

    before, after = string.match(title, "^(.+) with (.+)$")
    if before and after then
        return before .. " with\n" .. after
    end

    return title
end

local function formatVisitTitle(title, maxWidth)
    if not title then return title end
    local tmgr = getTextManager()
    if tmgr and tmgr:MeasureStringX(FONT_MD, title) <= maxWidth then
        return title
    end
    local atPos = title:find(" at ", 1, true)
    if atPos then
        return title:sub(1, atPos + 2) .. "\n" .. title:sub(atPos + 4)
    end
    return title
end

local MONTH_KEYS = { "IGUI_DCS_Panel_Month_January", "IGUI_DCS_Panel_Month_February",
    "IGUI_DCS_Panel_Month_March", "IGUI_DCS_Panel_Month_April",
    "IGUI_DCS_Panel_Month_May", "IGUI_DCS_Panel_Month_June",
    "IGUI_DCS_Panel_Month_July", "IGUI_DCS_Panel_Month_August",
    "IGUI_DCS_Panel_Month_September", "IGUI_DCS_Panel_Month_October",
    "IGUI_DCS_Panel_Month_November", "IGUI_DCS_Panel_Month_December" }

local function ordinalSuffix(day)
    if day >= 11 and day <= 13 then return "th" end
    local last = day % 10
    if last == 1 then return "st"
    elseif last == 2 then return "nd"
    elseif last == 3 then return "rd"
    else return "th" end
end

local function formatDCSDate()
    local day = tonumber(os.date("!%d"))
    local month = tonumber(os.date("!%m"))
    local year = tonumber(os.date("!%Y"))
    return day .. ordinalSuffix(day) .. " " .. getText(MONTH_KEYS[month]) .. " " .. year
end

local function calcRowHeight(ch, rowWidth, isComplete)
    if ch._placeholder then return ROW_H end
    local hasBar = (ch.target or 1) > 1 and not isComplete
    local maxTitleW = getTitleMaxWidth(rowWidth)
    local titleText = DCS_Translate.challengeTitle(ch)
    if ch.type == "visitLocation" then
        titleText = formatVisitTitle(titleText, maxTitleW)
    elseif ch.type == "killWithCategory" or ch.type == "killWithWeapon" or ch.type == "killZombies" then
        titleText = formatKillCategoryTitle(titleText, maxTitleW)
    end
    local titleTextH
    if ch.type == "questDeliver" or ch.type == "visitLocation" then
        local info = wrapQuestTitle(titleText, maxTitleW)
        titleTextH = info.textH
    else
        local _, h = wrapTitle(titleText, maxTitleW, FONT_MD)
        titleTextH = h
    end
    local barSpace = 0
    if hasBar then
        barSpace = BAR_GAP + fontHgt + BAR_H + BAR_PAD
    end
    local titleYOffset = hasBar and CHECK_GAP or 0
    local isQuestRow = not hasBar and (ch.type == "questDeliver" or ch.type == "visitLocation")
    local extraH = isQuestRow and QUEST_ROW_PAD or 0
    local textFloor = isQuestRow and (titleTextH + QUEST_TEXT_SLACK) or (titleYOffset + titleTextH + barSpace)
    return math.max(ROW_H + extraH, textFloor)
end

local function getResetCountdown()
    local h = (DCS_Config and DCS_Config.RESET_INTERVAL_HOURS) or 24
    if type(h) ~= "number" or h <= 0 then h = 24 end
    local interval = math.floor(h * 3600)
    local now = os.time()
    local nextReset = (math.floor(now / interval) + 1) * interval
    local remaining = nextReset - now

    local hours = math.floor(remaining / 3600)
    local minutes = math.floor((remaining % 3600) / 60)

    if hours > 0 then
        return getText("IGUI_DCS_Panel_Countdown_HM", hours, minutes)
    else
        return getText("IGUI_DCS_Panel_Countdown_M", minutes)
    end
end

DCS_Panel_Window = ISCollapsableWindow:derive("DCS_Panel_Window")

function DCS_Panel_Window:new(x, y)
    local o = ISCollapsableWindow.new(self, x, y, PANEL_W, PANEL_H)
    o.moveWithMouse = true
    o.anchorLeft = true
    o.anchorRight = true
    o.anchorTop = true
    o.anchorBottom = true
    o.resizable = false
    o.activeTab = "challenges"
    o.positionRestored = false
    return o
end

function DCS_Panel_Window:createChildren()
    ISCollapsableWindow.createChildren(self)

    local titleBarH = TITLE_BAR_H
    local isMP = getWorld and getWorld():getGameMode() == "Multiplayer"

    if self.infoButton then
        self.infoButton:setVisible(true)
        self.infoButton.onclick = DCS_Panel_Window.onHelp
        self.infoButton.target = self
        self.infoButton.tooltip = getText("IGUI_DCS_Panel_HelpButtonTooltip")
    end

    local tabW = PANEL_W - PAD * 2

    self.tabChallenges = ISButton:new(PAD, titleBarH, tabW, TAB_H,
        getText("IGUI_DCS_Panel_TabChallenges"), self, DCS_Panel_Window.onTabChallenges)
    self.tabChallenges:initialise()
    self.tabChallenges:instantiate()
    self.tabChallenges._defaultBg = { r=self.tabChallenges.backgroundColor.r, g=self.tabChallenges.backgroundColor.g, b=self.tabChallenges.backgroundColor.b, a=self.tabChallenges.backgroundColor.a }
    self:addChild(self.tabChallenges)

    local lbBtnY = titleBarH + TAB_H + S(4)
    local lbBtnW = math.floor((PANEL_W - PAD * 2) / 2)
    local lbBtnH = TAB_H

    if isMP then
        self.tabChallengeLB = ISButton:new(PAD, lbBtnY, lbBtnW, lbBtnH,
            getText("IGUI_DCS_Panel_TabLeaderboard"), self, DCS_Panel_Window.onTabChallengeLB)
        self.tabChallengeLB:initialise()
        self.tabChallengeLB:instantiate()
        self.tabChallengeLB._defaultBg = { r=self.tabChallengeLB.backgroundColor.r, g=self.tabChallengeLB.backgroundColor.g, b=self.tabChallengeLB.backgroundColor.b, a=self.tabChallengeLB.backgroundColor.a }
        self:addChild(self.tabChallengeLB)

        self.tabStreakLB = ISButton:new(PAD + lbBtnW, lbBtnY, lbBtnW, lbBtnH,
            getText("IGUI_DCS_Panel_TabStreak"), self, DCS_Panel_Window.onTabStreakLB)
        self.tabStreakLB:initialise()
        self.tabStreakLB:instantiate()
        self.tabStreakLB._defaultBg = { r=self.tabStreakLB.backgroundColor.r, g=self.tabStreakLB.backgroundColor.g, b=self.tabStreakLB.backgroundColor.b, a=self.tabStreakLB.backgroundColor.a }
        self:addChild(self.tabStreakLB)
    else
        self.tabChallengeLB = ISButton:new(PAD, lbBtnY, PANEL_W - PAD * 2, lbBtnH,
            getText("IGUI_DCS_Panel_TabHallOfFame"), self, DCS_Panel_Window.onTabChallengeLB)
        self.tabChallengeLB:initialise()
        self.tabChallengeLB:instantiate()
        self.tabChallengeLB._defaultBg = { r=self.tabChallengeLB.backgroundColor.r, g=self.tabChallengeLB.backgroundColor.g, b=self.tabChallengeLB.backgroundColor.b, a=self.tabChallengeLB.backgroundColor.a }
        self:addChild(self.tabChallengeLB)
    end

    local contentY = titleBarH + TAB_H + LB_BTN_EXTRA + HEADER_H + PAD
    local listH = PANEL_H - contentY - FOOTER_H - PAD * 2

    self.challengeList = ISScrollingListBox:new(
        PAD, contentY, PANEL_W - PAD * 2, listH)
    self.challengeList:initialise()
    self.challengeList:instantiate()
    self.challengeList.itemheight = ROW_H
    self.challengeList.selected = 0
    self.challengeList.font = FONT_SM
    self.challengeList.doDrawItem = self.drawChallengeRow
    self.challengeList.drawBorder = true
    if self.challengeList.vscroll then
        local vs = self.challengeList.vscroll
        vs.background = false
        local _origVscrollRender = vs.render
        vs.render = function(bar)
            if self._dcsShowScroll and _origVscrollRender then _origVscrollRender(bar) end
        end
        vs:setVisible(false)
    end
    self._dcsShowScroll = false
    self:addChild(self.challengeList)

    local lbH = PANEL_H - contentY - FOOTER_H - PAD * 2

    self.challengeLBList = ISScrollingListBox:new(PAD, contentY, PANEL_W - PAD * 2, lbH)
    self.challengeLBList:initialise()
    self.challengeLBList:instantiate()
    self.challengeLBList.selected = 0
    self.challengeLBList.font = FONT_SM
    self.challengeLBList.doDrawItem = self.drawLeaderboardRow
    self.challengeLBList.drawBorder = false
    self.challengeLBList:setVisible(false)
    self:addChild(self.challengeLBList)
    do
        local vs = self.challengeLBList.vscroll
        if vs then
            vs:setVisible(false)
            vs.render = function() end
            local origPrerender = self.challengeLBList.prerender
            self.challengeLBList.prerender = function(list)
                if vs:getHeight() < list:getScrollHeight() then
                    local trackX = list:getWidth() - 17
                    local trackW = 17
                    list:drawRect(trackX, 0, trackW, list:getHeight(), 0.6, 0.1, 0.1, 0.1)
                    local ratio = list:getHeight() / list:getScrollHeight()
                    local thumbH = math.max(20, list:getHeight() * ratio)
                    local thumbY = vs.pos * (list:getHeight() - thumbH)
                    list:drawRect(trackX + 3, thumbY + 3, 11, thumbH - 6, 0.8, 0.4, 0.4, 0.4)
                end
                origPrerender(list)
            end
        end
    end

    if isMP then
        self.streakLBList = ISScrollingListBox:new(PAD, contentY, PANEL_W - PAD * 2, lbH)
        self.streakLBList:initialise()
        self.streakLBList:instantiate()
        self.streakLBList.selected = 0
        self.streakLBList.font = FONT_SM
        self.streakLBList.doDrawItem = self.drawLeaderboardRow
        self.streakLBList.drawBorder = false
        self.streakLBList:setVisible(false)
        self:addChild(self.streakLBList)
        do
            local vs = self.streakLBList.vscroll
            if vs then
                vs:setVisible(false)
                vs.render = function() end
                local origPrerender = self.streakLBList.prerender
                self.streakLBList.prerender = function(list)
                    if vs:getHeight() < list:getScrollHeight() then
                        local trackX = list:getWidth() - 17
                        local trackW = 17
                        list:drawRect(trackX, 0, trackW, list:getHeight(), 0.6, 0.1, 0.1, 0.1)
                        local ratio = list:getHeight() / list:getScrollHeight()
                        local thumbH = math.max(20, list:getHeight() * ratio)
                        local thumbY = vs.pos * (list:getHeight() - thumbH)
                        list:drawRect(trackX + 3, thumbY + 3, 11, thumbH - 6, 0.8, 0.4, 0.4, 0.4)
                    end
                    origPrerender(list)
                end
            end
        end
    end
end

function DCS_Panel_Window:initialise()
    ISCollapsableWindow.initialise(self)
end

local TAB_KEY_MAP = {
    tabChallenges = "challenges",
    tabChallengeLB = "challengeLeaderboard",
    tabStreakLB = "streakLeaderboard",
}

function DCS_Panel_Window:updateTabHighlight()
    for btnName, key in pairs(TAB_KEY_MAP) do
        local btn = self[btnName]
        if btn then
            if key == self.activeTab then
                btn.backgroundColor = btn.backgroundColorMouseOver
            elseif btn._defaultBg then
                btn.backgroundColor = btn._defaultBg
            end
        end
    end
end

function DCS_Panel_Window:setTab(tab)
    self.activeTab = tab
    self.challengeList:setVisible(tab == "challenges")
    if self.challengeLBList then
        self.challengeLBList:setVisible(tab == "challengeLeaderboard")
        if tab == "challengeLeaderboard" then self:populateChallengeLeaderboard() end
    end
    if self.streakLBList then
        self.streakLBList:setVisible(tab == "streakLeaderboard")
        if tab == "streakLeaderboard" then self:populateStreakLeaderboard() end
    end
    self:updateTabHighlight()
end

function DCS_Panel_Window:onTabChallenges()
    self:setTab("challenges")
end

function DCS_Panel_Window:onTabChallengeLB()
    self:setTab("challengeLeaderboard")
end

function DCS_Panel_Window:onTabStreakLB()
    self:setTab("streakLeaderboard")
end

function DCS_Panel_Window:onHelp()
    DCS_UI_HelpWindow.open(getText("IGUI_DCS_Panel_HelpTitle"), {
        getText("IGUI_DCS_Panel_HelpHeading"),
        "",
        getText("IGUI_DCS_Panel_HelpSectionHowItWorks"),
        "",
        getText("IGUI_DCS_Panel_HelpHowItWorks"),
        "",
        getText("IGUI_DCS_Panel_HelpSectionChallenges"),
        "",
        getText("IGUI_DCS_Panel_HelpKill"),
        getText("IGUI_DCS_Panel_HelpDeliver"),
        getText("IGUI_DCS_Panel_HelpVisit"),
        getText("IGUI_DCS_Panel_HelpEat"),
        getText("IGUI_DCS_Panel_HelpFish"),
        getText("IGUI_DCS_Panel_HelpCraft"),
        getText("IGUI_DCS_Panel_HelpMisc"),
        "",
        getText("IGUI_DCS_Panel_HelpSectionStreak"),
        "",
        getText("IGUI_DCS_Panel_HelpStreak"),
        "",
        getText("IGUI_DCS_Panel_HelpSectionVendors"),
        "",
        getText("IGUI_DCS_Panel_HelpVendors"),
        "",
        getText("IGUI_DCS_Panel_HelpSectionTabs"),
        "",
        getText("IGUI_DCS_Panel_HelpTabChallenges"),
        getText("IGUI_DCS_Panel_HelpTabChallengeLB"),
        getText("IGUI_DCS_Panel_HelpTabStreakLB"),
        "",
        getText("IGUI_DCS_Panel_HelpSectionControls"),
        "",
        getText("IGUI_DCS_Panel_HelpControls"),
    })
end

function DCS_Panel_Window:switchTab(direction)
    if not self.challengeLBList then return end
    local tabs = { "challenges", "challengeLeaderboard" }
    local isMP = getWorld and getWorld():getGameMode() == "Multiplayer"
    if isMP then tabs = { "challenges", "challengeLeaderboard", "streakLeaderboard" } end
    local currentIdx = 1
    for i, t in ipairs(tabs) do
        if self.activeTab == t then currentIdx = i; break end
    end
    local newIdx
    if direction == "left" then
        newIdx = currentIdx > 1 and currentIdx - 1 or #tabs
    else
        newIdx = currentIdx < #tabs and currentIdx + 1 or 1
    end
    self:setTab(tabs[newIdx])
end

local function formatSpeedrunTime(seconds)
    if not seconds or seconds < 0 then return getText("IGUI_DCS_Panel_NoData") end
    seconds = math.floor(seconds + 0.5)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    local parts = {}
    if h > 0 then table.insert(parts, h .. "hr") end
    if m > 0 then table.insert(parts, m .. "m") end
    table.insert(parts, s .. "s")
    return table.concat(parts, " ")
end

local function formatSpeedrunDate(dateStr)
    if not dateStr or dateStr == "" then return "" end
    local day = tonumber(string.sub(dateStr, 7, 8))
    local month = tonumber(string.sub(dateStr, 5, 6))
    local year = tonumber(string.sub(dateStr, 1, 4))
    local suffix = "th"
    if day == 1 or day == 21 or day == 31 then suffix = "st"
    elseif day == 2 or day == 22 then suffix = "nd"
    elseif day == 3 or day == 23 then suffix = "rd" end
    return day .. suffix .. " " .. getText(MONTH_KEYS[month] or "") .. " " .. (year or "")
end

local function addLeaderboardSection(list, sectionKey, title, entries, scoreKey, labelFn, isSpeedrun)
    local ENTRY_COUNT = 3

    local listH = list.height or 300
    local sectionH = listH / 3
    local headerH = math.floor(sectionH * 0.25)
    local entryH = (sectionH - headerH) / ENTRY_COUNT

    local headerEntry = list:addItem(sectionKey .. "_header", { _header = true, _text = title })
    headerEntry.height = headerH

    local count = math.min(#entries, ENTRY_COUNT)
    if count == 0 then
        local emptyEntry = list:addItem(sectionKey .. "_empty", { _empty = true })
        emptyEntry.height = entryH * ENTRY_COUNT
    else
        for i = 1, count do
            local e = entries[i]
            local item
            if isSpeedrun then
                local timeStr = formatSpeedrunTime(e.time)
                item = list:addItem(sectionKey .. "_" .. i, {
                    _rank = i,
                    _name = (e.name or "Unknown") .. " - " .. timeStr,
                    _time = e.time,
                    _date = e.date or "",
                    _isSpeedrun = true,
                })
            else
                item = list:addItem(sectionKey .. "_" .. i, {
                    _rank = i,
                    _name = e.name or "Unknown",
                    _score = e[scoreKey] or e.value or 0,
                    _label = labelFn(e[scoreKey] or e.value or 0),
                })
            end
            item.height = entryH
        end
        for s = 1, ENTRY_COUNT - count do
            local spacer = list:addItem(sectionKey .. "_sp_" .. s, { _spacer = true })
            spacer.height = entryH
        end
    end
end

function DCS_Panel_Window:populateChallengeLeaderboard()
    if not self.challengeLBList then return end
    self.challengeLBList:clear()
    local lb = DCS_Sync.State.leaderboard or {}

    self.challengeLBList:setY(self.challengeList:getY())
    self.challengeLBList:setHeight(self.challengeList:getHeight())
    self.challengeLBList:setScrollHeight(self.challengeList:getHeight())

    if lb.isSP then
        local labelFn = function(count) return (count == 1) and getText("IGUI_DCS_Panel_LB_Challenge") or getText("IGUI_DCS_Panel_LB_Challenges") end
        local streakLabelFn = function(count) return (count == 1) and getText("IGUI_DCS_Panel_LB_Day") or getText("IGUI_DCS_Panel_LB_Days") end
        addLeaderboardSection(self.challengeLBList, "mc", getText("IGUI_DCS_Panel_LB_MostCompleted"),
            lb.mostCompleted or {}, "count", labelFn, false)
        addLeaderboardSection(self.challengeLBList, "hs", getText("IGUI_DCS_Panel_LB_LongestOverall"),
            lb.highestStreak or {}, "streak", streakLabelFn, false)
        addLeaderboardSection(self.challengeLBList, "sr7", getText("IGUI_DCS_Panel_LB_FastestAll"),
            lb.speedrun7 or {}, "time", nil, true)
    else
        local labelFn = function(count) return (count == 1) and getText("IGUI_DCS_Panel_LB_Challenge") or getText("IGUI_DCS_Panel_LB_Challenges") end
        addLeaderboardSection(self.challengeLBList, "mc", getText("IGUI_DCS_Panel_LB_MostCompleted"),
            lb.mostCompleted or {}, "count", labelFn, false)
        addLeaderboardSection(self.challengeLBList, "sr1", getText("IGUI_DCS_Panel_LB_FastestOne"),
            lb.speedrun1 or {}, "time", nil, true)
        addLeaderboardSection(self.challengeLBList, "sr7", getText("IGUI_DCS_Panel_LB_FastestAll"),
            lb.speedrun7 or {}, "time", nil, true)
    end
end

function DCS_Panel_Window:populateStreakLeaderboard()
    if not self.streakLBList then return end
    self.streakLBList:clear()
    local lb = DCS_Sync.State.leaderboard or {}

    self.streakLBList:setY(self.challengeList:getY())
    self.streakLBList:setHeight(self.challengeList:getHeight())
    self.streakLBList:setScrollHeight(self.challengeList:getHeight())

    local streakLabelFn = function(count) return (count == 1) and getText("IGUI_DCS_Panel_LB_Day") or getText("IGUI_DCS_Panel_LB_Days") end
    local tokenLabelFn = function(count) return (count == 1) and getText("IGUI_DCS_Panel_LB_Token") or getText("IGUI_DCS_Panel_LB_Tokens") end

    addLeaderboardSection(self.streakLBList, "cs", getText("IGUI_DCS_Panel_LB_LongestStreak"),
        lb.currentStreak or {}, "streak", streakLabelFn, false)
    addLeaderboardSection(self.streakLBList, "hs", getText("IGUI_DCS_Panel_LB_LongestOverall"),
        lb.highestStreak or {}, "streak", streakLabelFn, false)
    addLeaderboardSection(self.streakLBList, "mt", getText("IGUI_DCS_Panel_LB_MostTokens"),
        lb.mostTokens or {}, "count", tokenLabelFn, false)
end

local RANK_COLS = {
    { r=1.00, g=0.84, b=0.00 },
    { r=0.75, g=0.75, b=0.78 },
    { r=0.80, g=0.50, b=0.20 },
}

function DCS_Panel_Window:drawLeaderboardRow(y, entry, alt)
    local data = entry.item
    local w = self:getWidth()
    local rowH = entry.height or 40

    if data._spacer then
        return y + rowH
    end

    if data._header then
        self:drawRect(0, y, w, rowH - S(1), 0.70,
            COL_BG.r, COL_BG.g, COL_BG.b)
        self:drawRect(0, y, w, S(1), 0.50,
            COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
        self:drawRect(0, y + rowH - S(1), w, S(1), 0.50,
            COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
        local fontH = getTextManager():getFontHeight(FONT_SM)
        local headerMidY = y + math.floor((rowH - fontH) / 2)
        self:drawTextCentre(data._text or "", w / 2, headerMidY,
            COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 0.90, FONT_SM)
        return y + rowH
    end

    if data._empty then
        local fontH = getTextManager():getFontHeight(FONT_SM)
        local emptyMidY = y + math.floor((rowH - fontH) / 2)
        self:drawTextCentre(getText("IGUI_DCS_Panel_NoData"), w / 2, emptyMidY,
            0.50, 0.50, 0.50, 0.70, FONT_SM)
        return y + rowH
    end

    if alt then
        self:drawRect(0, y, w, rowH - S(1), 0.15,
            COL_BG.r, COL_BG.g, COL_BG.b)
    end

    local rankCol = RANK_COLS[data._rank] or { r=0.65, g=0.65, b=0.65 }
    local fontH = getTextManager():getFontHeight(FONT_SM)
    local midY = y + math.floor((rowH - fontH) / 2)
    local tmgr = getTextManager()

    local rankStr = "#" .. tostring(data._rank)
    local rankW = tmgr:MeasureStringX(FONT_SM, rankStr)
    local rankEnd = S(8) + rankW + S(8)
    self:drawText(rankStr, S(8), midY,
        rankCol.r, rankCol.g, rankCol.b, 1, FONT_SM)

    local scoreStart
    if data._isSpeedrun then
        local dateStr = formatSpeedrunDate(data._date)
        local rightW = tmgr:MeasureStringX(FONT_SM, dateStr)
        scoreStart = w - rightW - S(8)
        self:drawText(dateStr, scoreStart, midY,
            COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 0.85, FONT_SM)
    else
        local scoreStr = tostring(data._score) .. " " .. (data._label or "")
        local scoreW = tmgr:MeasureStringX(FONT_SM, scoreStr)
        scoreStart = w - scoreW - S(8)
        self:drawText(scoreStr, scoreStart, midY,
            COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 0.85, FONT_SM)
    end

    self:drawText(data._name or "", rankEnd, midY,
        0.90, 0.90, 0.90, 0.90, FONT_SM)

    return y + rowH
end

function DCS_Panel_Window:populateChallengeList()
    self.challengeList:clear()
    local challenges = DCS_Sync.getTodayChallenges()
    if #challenges == 0 then
        self.challengeList:addItem(getText("IGUI_DCS_Panel_Waiting"), {
            _placeholder = true,
            title = getText("IGUI_DCS_Panel_Connecting"),
            desc = getText("IGUI_DCS_Panel_DataAppears"),
            type = "none",
        })
        local titleBarH = TITLE_BAR_H
        local isMP = getWorld and getWorld():getGameMode() == "Multiplayer"
    local contentY = titleBarH + TAB_H + LB_BTN_EXTRA + HEADER_H + PAD
        local footerBlock = fontHgt * 11
        local footerPad = fontHgt
        local newPanelH = contentY + ROW_H + footerPad + footerBlock + footerPad
        newPanelH = math.max(PANEL_H, newPanelH)
        self:setHeight(newPanelH)
        self.challengeList:setHeight(ROW_H)
        return
    end

    local totalRowH = 0
    for _, ch in ipairs(challenges) do
        local chCopy = {}
        for k, v in pairs(ch) do chCopy[k] = v end

        if chCopy.type == "questDeliver" and chCopy.title then
            chCopy.title = formatQuestTitle(chCopy.title)
        end

        if (chCopy.type == "killWithCategory" or chCopy.type == "killWithWeapon" or chCopy.type == "killZombies") and chCopy.title then
            chCopy.title = formatKillCategoryTitle(chCopy.title,
                getTitleMaxWidth(PANEL_W - PAD * 2))
        end

        if chCopy.type == "visitLocation" and chCopy.title then
            chCopy.title = formatVisitTitle(chCopy.title,
                getTitleMaxWidth(PANEL_W - PAD * 2))
        end

        local entry = self.challengeList:addItem(chCopy.title, chCopy)

        entry.height = calcRowHeight(chCopy, PANEL_W - PAD * 2,
            DCS_Sync.isCompleted(chCopy.id or ""))
        totalRowH = totalRowH + entry.height
    end

    local titleBarH = TITLE_BAR_H
    local isMP = getWorld and getWorld():getGameMode() == "Multiplayer"
    local contentY = titleBarH + TAB_H + LB_BTN_EXTRA + HEADER_H + PAD
    local footerBlock = fontHgt * 11
    local textMaxW = PANEL_W - PAD * 2
    local completed = DCS_Sync.getCompletedCount()
    local total = DCS_Challenges and DCS_Challenges.ChallengesPerDay or 7
    if completed >= total then
        local tl = DCS_Sync.State.traderLocations or {}
        local eastName = tl.east and tl.east.name or "Unknown"
        local westName = tl.west and tl.west.name or "Unknown"
        local traderText = getText("IGUI_DCS_Panel_FooterVendorRevealEast", eastName, westName)
        if getTextManager():MeasureStringX(FONT_SM, traderText) > textMaxW then
            footerBlock = footerBlock + fontHgt
        end
    else
        local remaining = total - completed
        local revealText = getText("IGUI_DCS_Panel_FooterVendorUnlock", remaining)
        if getTextManager():MeasureStringX(FONT_SM, revealText) > textMaxW then
            footerBlock = footerBlock + fontHgt
        end
    end
    local footerPad = fontHgt
    local newPanelH = contentY + totalRowH + footerPad + footerBlock + footerPad
    newPanelH = math.max(PANEL_H, newPanelH)

    local screenH = getPlayerScreenHeight(0)
    if screenH then
        newPanelH = math.min(newPanelH, screenH - 40)
    end

    self:setHeight(newPanelH)
    local availListH = newPanelH - contentY - (footerPad + footerBlock + footerPad)
    if availListH < 0 then availListH = 0 end
    self.challengeList:setHeight(math.min(totalRowH, availListH))

    local needScroll = totalRowH > availListH
    self._dcsShowScroll = needScroll
    if self.challengeList.vscroll then
        self.challengeList.vscroll:setVisible(needScroll)
    end
end

function DCS_Panel_Window:onSyncUpdate(state)
    if self.activeTab == "challengeLeaderboard" then
        self:populateChallengeLeaderboard()
    elseif self.activeTab == "streakLeaderboard" then
        self:populateStreakLeaderboard()
    end
    if not self.positionRestored then
        local wp = state.windowPositions
        if wp and wp.panelX and wp.panelY then
            local screenW = getPlayerScreenWidth(0)
            local screenH = getPlayerScreenHeight(0)
            self:setX(math.max(0, math.min(wp.panelX, screenW - self.width)))
            self:setY(math.max(0, math.min(wp.panelY, screenH - self.height)))
        end
        self.positionRestored = true
    end
end

function DCS_Panel_Window:prerender()
    local savedTitle = self.title
    self.title = ""
    ISCollapsableWindow.prerender(self)
    self.title = savedTitle

    local title = self.title or ""
    if title ~= "" then
        local tmgr = getTextManager()
        local fontH = tmgr:getFontHeight(UIFont.Small)
        local titleY = math.floor((S(20) - fontH) / 2)
        self:drawTextCentre(title, self.width / 2, titleY,
            COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 1, UIFont.Small)
    end

    local titleBarH = TITLE_BAR_H
    local isMP = getWorld and getWorld():getGameMode() == "Multiplayer"
    local hY = titleBarH + TAB_H + LB_BTN_EXTRA
    local state = DCS_Sync.State

    self:drawRect(0, hY, self.width, HEADER_H, 0.92, COL_BG.r, COL_BG.g, COL_BG.b)
    self:drawRect(0, hY - S(2), self.width, S(2), 0.80, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)

    local done = DCS_Sync.getCompletedCount()
    local total = DCS_Challenges and DCS_Challenges.ChallengesPerDay or 7
    local doneCol = done >= total and COL_COMPLETE or COL_PENDING
    local doneStr = getText("IGUI_DCS_Panel_HeaderProgress", done, total)
    local countdown = getResetCountdown()
    local resetStr = getText("IGUI_DCS_Panel_HeaderReset", countdown:gsub("Resets in ", ""))

    self:drawText(doneStr, PAD, hY + S(12), COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 1, FONT_SM)
    self:drawText(resetStr, PAD, hY + S(30), 0.85, 0.85, 0.85, 0.90, FONT_SM)

    local tokenStr = getText("IGUI_DCS_Panel_HeaderTokens", state.currency)
    local streakStr = getText("IGUI_DCS_Panel_HeaderStreak", state.streak)
    local tmgr = getTextManager()
    local tokenW = tmgr and tmgr:MeasureStringX(FONT_SM, tokenStr) or 80
    local streakW = tmgr and tmgr:MeasureStringX(FONT_SM, streakStr) or 90
    local rightEdge = self.width - PAD

    self:drawText(tokenStr, rightEdge - tokenW, hY + S(12), COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 1, FONT_SM)
    self:drawText(streakStr, rightEdge - streakW, hY + S(30), 0.85, 0.85, 0.85, 0.90, FONT_SM)

    local fullTabW = self.width - PAD * 2
    local halfTabW = math.floor(fullTabW / 2)
    if self.activeTab == "challenges" then
        self:drawRect(PAD, titleBarH + TAB_H - S(2), fullTabW, S(2),
            1, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
    elseif isMP then
        local lbBtnY = titleBarH + TAB_H + S(4)
        if self.activeTab == "challengeLeaderboard" then
            self:drawRect(PAD, lbBtnY + TAB_H - S(8), halfTabW, S(2),
                1, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
        elseif self.activeTab == "streakLeaderboard" then
            self:drawRect(PAD + halfTabW, lbBtnY + TAB_H - S(8), halfTabW, S(2),
                1, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
        end
    end

    local rawLevel = state.streakLevel or 0
    local tier = DCS_Challenges and DCS_Challenges.getTier and
                        DCS_Challenges.getTier(math.max(1, rawLevel)) or nil
    local tPerChall = tier and tier.tokenPerChallenge or 1
    local tBonus = tier and tier.bonusAllSeven or 3

    local titleBarH = TITLE_BAR_H
    local isMP = getWorld and getWorld():getGameMode() == "Multiplayer"
    local contentY = titleBarH + TAB_H + LB_BTN_EXTRA + HEADER_H + PAD
    local footerSeparatorY = self.challengeList:getBottom() + PAD * 2

    local line1 = getText("IGUI_DCS_Panel_FooterTokenPer", tPerChall)
    local line2 = getText("IGUI_DCS_Panel_FooterTokenBonus", tBonus)
    self:drawRect(0, footerSeparatorY, self.width, self.height - footerSeparatorY, 0.92, COL_BG.r, COL_BG.g, COL_BG.b)
    self:drawRect(0, footerSeparatorY - S(2), self.width, S(1), 0.50, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)

    local navyH = self.height - footerSeparatorY
    local rewardsH = fontHgt * 3
    local traderH = fontHgt * 3
    local streakH = fontHgt * 3
    local completed = DCS_Sync.getCompletedCount()
    local total = DCS_Challenges and DCS_Challenges.ChallengesPerDay or 7
    local tl = DCS_Sync.State and DCS_Sync.State.traderLocations or {}
    local eastName = tl.east and tl.east.name or "Unknown"
    local westName = tl.west and tl.west.name or "Unknown"
    local textMaxW = self.width - PAD * 2
    local traderBody
    if completed >= total then
        traderBody = getText("IGUI_DCS_Panel_FooterVendorRevealEast", eastName, westName)
    else
        traderBody = getText("IGUI_DCS_Panel_FooterVendorUnlock", total - completed)
    end
    local traderLines = {}
    for line in string.gmatch(getTextManager():WrapText(FONT_SM, traderBody, textMaxW, 99, ""), "[^\n]+") do
        traderLines[#traderLines + 1] = line
    end
    if #traderLines == 0 then traderLines = { traderBody } end
    traderH = fontHgt * (2 + #traderLines)
    local fixedH = rewardsH + traderH + streakH
    local gap = math.max(fontHgt, math.floor((navyH - fixedH) / 4))
    local contentBlock = fixedH + gap
    local baseY = footerSeparatorY + math.floor((navyH - contentBlock) / 2)

    self:drawTextCentre(getText("IGUI_DCS_Panel_FooterCurrentRewards"), self.width / 2, baseY,
        COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 0.90, FONT_SM)
    self:drawTextCentre(line1, self.width / 2, baseY + fontHgt,
        0.75, 0.75, 0.75, 0.90, FONT_SM)
    self:drawTextCentre(line2, self.width / 2, baseY + fontHgt * 2,
        0.75, 0.75, 0.75, 0.90, FONT_SM)

    local traderBaseY = baseY + rewardsH + gap

    self:drawTextCentre(getText("IGUI_DCS_Panel_FooterVendorLocations"), self.width / 2, traderBaseY,
        COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 0.90, FONT_SM)

    local traderAlpha = (completed >= total) and 0.90 or 0.80
    for i = 1, #traderLines do
        self:drawTextCentre(traderLines[i], self.width / 2, traderBaseY + fontHgt * i,
            0.75, 0.75, 0.75, traderAlpha, FONT_SM)
    end

    local streakBaseY = baseY + rewardsH + traderH + gap
    local tierThresholds = { 1, 8, 15, 22 }
    local streakLevel = 1
    for i = #tierThresholds, 1, -1 do
        if rawLevel >= tierThresholds[i] then
            streakLevel = i
            break
        end
    end
    local nextLevel = math.min(streakLevel + 1, 4)
    local daysToNext = 0
    if streakLevel < 4 then
        daysToNext = tierThresholds[nextLevel] - rawLevel - 1
    end
    local levelStr = getText("IGUI_DCS_Panel_FooterStreakLevel", streakLevel)
    self:drawTextCentre(levelStr, self.width / 2, streakBaseY,
        COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 0.90, FONT_SM)
    local textMaxW = self.width - PAD * 2
    if streakLevel < 4 then
        local hintStr
        if daysToNext <= 0 then
            hintStr = getText("IGUI_DCS_Panel_FooterStreakHint1")
        else
            hintStr = getText("IGUI_DCS_Panel_FooterStreakHint2", daysToNext)
        end
        local wrapped = balancedWrap2(hintStr, FONT_SM, textMaxW)
        self:drawTextCentre(wrapped, self.width / 2, streakBaseY + fontHgt,
            0.75, 0.75, 0.75, 0.80, FONT_SM)
    else
        local daysLeft = 28 - rawLevel
        local hintStr
        if daysLeft <= 0 then
            hintStr = getText("IGUI_DCS_Panel_FooterStreakReward1")
        else
            hintStr = getText("IGUI_DCS_Panel_FooterStreakReward2", daysLeft)
        end
        local wrapped = balancedWrap2(hintStr, FONT_SM, textMaxW)
        self:drawTextCentre(wrapped, self.width / 2, streakBaseY + fontHgt,
            0.75, 0.75, 0.75, 0.80, FONT_SM)
    end
end

function DCS_Panel_Window:drawChallengeRow(y, entry, alt)
    local ch = entry.item
    local isComplete = DCS_Sync.isCompleted(ch.id or "")
    local rowAlpha = isComplete and 0.70 or 0.92
    local w = self:getWidth()
    local hasBar = (ch.target or 1) > 1 and not isComplete
    local boxSize = BOX_SIZE
    local tmgr = getTextManager()

    local maxTitleW = getTitleMaxWidth(w)
    local titleText = DCS_Translate.challengeTitle(ch)
    local wrappedTitle, titleTextH = titleText, fontHgtMd
    local questInfo = nil

    if not ch._placeholder then
        if ch.type == "visitLocation" then
            titleText = formatVisitTitle(titleText, maxTitleW)
        elseif ch.type == "killWithCategory" or ch.type == "killWithWeapon" or ch.type == "killZombies" then
            titleText = formatKillCategoryTitle(titleText, maxTitleW)
        end

        if ch.type == "questDeliver" or ch.type == "visitLocation" then
            questInfo = wrapQuestTitle(titleText, maxTitleW)
            titleTextH = questInfo.textH
        else
            wrappedTitle, titleTextH = wrapTitle(titleText, maxTitleW, FONT_MD)
        end
        local barSpace = 0
        if hasBar then
            barSpace = BAR_GAP + fontHgt + BAR_H + BAR_PAD
        end
        local titleYOffset = hasBar and CHECK_GAP or 0
        local isQuestRow = not hasBar and (ch.type == "questDeliver" or ch.type == "visitLocation")
        local extraH = isQuestRow and QUEST_ROW_PAD or 0
        local textFloor = isQuestRow and (titleTextH + QUEST_TEXT_SLACK) or (titleYOffset + titleTextH + barSpace)
        entry.height = math.max(ROW_H + extraH, textFloor)
    else
        entry.height = ROW_H
    end

    local rowH = entry.height
    local titleY
    local boxY
        if hasBar then
            local contentH = titleTextH + BAR_GAP + BAR_H + BAR_PAD
            local contentY = y + math.floor((rowH - contentH) / 2)
            titleY = contentY
            boxY = contentY + math.floor((contentH - boxSize) / 2)
        else
            titleY = y + math.floor((rowH - titleTextH) / 2)
            boxY = y + math.floor((rowH - boxSize) / 2)
    end
    local statusX = w - STATUS_X_PAD

    if alt then
        self:drawRect(0, y, w, rowH - S(1),
            0.25, COL_TAB_INACT.r, COL_TAB_INACT.g, COL_TAB_INACT.b)
    end

    self:drawRect(statusX, boxY, boxSize, boxSize, 0.85, 0.10, 0.11, 0.13)
    self:drawRectBorder(statusX, boxY, boxSize, boxSize, 0.55,
        COL_PENDING.r, COL_PENDING.g, COL_PENDING.b)
    if isComplete then
        if TEX_CHECK then
            self:drawTextureScaled(TEX_CHECK, statusX, boxY, boxSize, boxSize, 1)
        else
            self:drawRect(statusX + S(2), boxY + S(9), S(5), S(2), 1, COL_COMPLETE.r, COL_COMPLETE.g, COL_COMPLETE.b)
            self:drawRect(statusX + S(6), boxY + S(5), S(2), S(6), 1, COL_COMPLETE.r, COL_COMPLETE.g, COL_COMPLETE.b)
        end
    end

    if ch._placeholder then
        self:drawText(ch.title or "", PAD, titleY,
            0.60, 0.60, 0.60, 0.75, FONT_SM)
        return y + rowH
    end

    local titleCol = isComplete and COL_COMPLETE or { r = 0.95, g = 0.95, b = 0.95 }
    if questInfo then
        local curY = titleY
        for i = 1, #questInfo.lines do
            self:drawText(questInfo.lines[i], PAD, curY,
                titleCol.r, titleCol.g, titleCol.b, rowAlpha, FONT_MD)
            curY = curY + fontHgtMd
        end
    else
        self:drawText(wrappedTitle, PAD, titleY,
            titleCol.r, titleCol.g, titleCol.b, rowAlpha, FONT_MD)
    end

    if hasBar then
        local progress = 0
        if ch.type == "killWithWeapon" and ch.weaponType then
            progress = (DCS_Sync.State.dailyKillsByWeapon or {})[ch.weaponType] or 0
        elseif ch.type == "killWithCategory" and ch.weaponType then
            progress = (DCS_Sync.State.dailyKillsByCategory or {})[ch.weaponType] or 0
        elseif ch.type == "killZombies" then
            progress = DCS_Sync.State.dailyKills or 0
        else
            progress = (DCS_Sync.State.dailyProgress or {})[ch.id] or 0
        end
        local target = ch.target or 1
        local ratio = math.min(1, progress / target)
        local progressStr = progress .. " / " .. target
        local labelW = tmgr and tmgr:MeasureStringX(FONT_SM, progressStr) or 46
        local labelX = statusX - labelW - STATUS_X_PAD
        local barW = math.max(S(40), labelX - PAD - BOX_SIZE)
        local barGap = BAR_GAP + S(5)
        local barY = titleY + titleTextH + barGap
        local barCol = COL_ACCENT
        drawBar(self, PAD, barY, barW, ratio, barCol)
        self:drawText(progressStr, labelX, barY - math.floor(BAR_H / 2) - S(3),
            0.80, 0.80, 0.80, rowAlpha, FONT_SM)
    end

    return y + rowH
end

function DCS_Panel_Window:onLeaderboard()
    DCS_UI_Leaderboard.toggle()
end

function DCS_Panel_Window:close()
    DCS_dprint("[DCS] Panel closing, saving position: (" .. self:getX() .. ", " .. self:getY() .. ")")
    DCS_Sync.saveWindowPos("panel", self:getX(), self:getY())
    self:setVisible(false)
    self:removeFromUIManager()
    DCS_UI_Panel.instance = nil
    if DCS_UI_Panel.toolbarBtn then
        DCS_UI_Panel.toolbarBtn:setImage(DCS_UI_Panel.texOff)
    end
end

function DCS_UI_Panel.open()
    if DCS_UI_Panel.instance then
        DCS_UI_Panel.instance:setVisible(true)
        if DCS_UI_Panel.toolbarBtn then
            DCS_UI_Panel.toolbarBtn:setImage(DCS_UI_Panel.texOn)
        end
        return
    end

    local player = getSpecificPlayer(0)
    if not player then return end

    if not TEX_CHECK then
        TEX_CHECK = getTexture("media/textures/dcs_check_mark.png")
    end

    local screenW = getPlayerScreenWidth(0)
    local screenH = getPlayerScreenHeight(0)

    local savedWp = DCS_Sync.State.windowPositions or {}
    local hadSaved = savedWp.panelX ~= nil and savedWp.panelY ~= nil
    local x, y = DCS_Sync.getWindowPos("panel",
        math.floor((screenW - PANEL_W) / 2), math.floor((screenH - PANEL_H) / 2))
    DCS_dprint("[DCS] Panel opening, position from wp: x=" .. tostring(x) .. " y=" .. tostring(y))
    x = math.max(0, math.min(x, screenW - PANEL_W))
    y = math.max(0, math.min(y, screenH - PANEL_H))

    local win = DCS_Panel_Window:new(x, y)
    win.positionRestored = hadSaved
    win:initialise()
    win:instantiate()
    win:addToUIManager()
    win:setTitle(getText("IGUI_DCS_Panel_Title") .. " - " .. formatDCSDate())

    DCS_Sync.Events.subscribe(DCS_Sync.Events.onProgressUpdated,
        function(state) win:onSyncUpdate(state) end)
    DCS_Sync.Events.subscribe(DCS_Sync.Events.onChallengesUpdated,
        function(state) win:populateChallengeList(); win:onSyncUpdate(state) end)
    DCS_Sync.Events.subscribe(DCS_Sync.Events.onDailyReset,
        function(state) win:populateChallengeList() end)
    DCS_Sync.Events.subscribe(DCS_Sync.Events.onLeaderboardUpdated,
        function(lb)
            if win.activeTab == "challengeLeaderboard" then
                win:populateChallengeLeaderboard()
            elseif win.activeTab == "streakLeaderboard" then
                win:populateStreakLeaderboard()
            end
        end)

    win:populateChallengeList()
    win:setTab("challenges")

    sendClientCommand(player, "DailyChallengeSystem", "requestSync", {})

    DCS_UI_Panel.instance = win
    DCS_UI_Panel.everOpenedThisSession = true
    DCS_UI_Panel.isWiggling = false

    if DCS_UI_Panel.toolbarBtn then
        DCS_UI_Panel.toolbarBtn:setImage(DCS_UI_Panel.texOn)
    end
end

function DCS_UI_Panel.close()
    if DCS_UI_Panel.instance then
        DCS_UI_Panel.instance:close()
    end
end

function DCS_UI_Panel.toggle()
    if DCS_UI_Panel.instance and DCS_UI_Panel.instance:getIsVisible() then
        DCS_UI_Panel.close()
    elseif DCS_Sync and DCS_Sync.State then
        DCS_UI_Panel.open()
    else
        print("[DCS] Panel toggle: DCS_Sync not ready yet")
    end
end

function DCS_UI_Panel.triggerWiggle()
    if DCS_UI_Panel.everOpenedThisSession then return end
    DCS_UI_Panel.isWiggling = true
end

local function addToolbarButton(inst)
    inst = inst or ISEquippedItem.instance
    if not inst then return end

    if DCS_UI_Panel.toolbarBtn then
        if DCS_UI_Panel.toolbarBtn.parent then
            DCS_UI_Panel.toolbarBtn.parent:removeChild(DCS_UI_Panel.toolbarBtn)
        end
        DCS_UI_Panel.toolbarBtn = nil
    end

    DCS_UI_Panel.texOn = getTexture("media/textures/dcs_icon_on.png")
    DCS_UI_Panel.texOff = getTexture("media/textures/dcs_icon_off.png")
    local tex = DCS_UI_Panel.texOff

    local refBtn = inst.invBtn
    local iconW = (refBtn and refBtn:getWidth()) or S(48)
    local iconH = (refBtn and refBtn:getHeight()) or S(48)
    local btnX = (refBtn and refBtn:getX()) or S(1)

    if not inst._dcsBaseHeight then inst._dcsBaseHeight = inst:getHeight() end
    local extraY = (DCS_Env and DCS_Env.isSP()) and S(10) or 0
    local btnY = inst._dcsBaseHeight + S(4) + extraY

    DCS_UI_Panel.toolbarBtn = ISButton:new(
        btnX, btnY, iconW, iconH, tex and "" or "DC",
        nil, DCS_UI_Panel.toggle)
    DCS_UI_Panel.toolbarBtn:initialise()
    DCS_UI_Panel.toolbarBtn:instantiate()
    DCS_UI_Panel.toolbarBtn.Type = "ISButton"
    DCS_UI_Panel.toolbarBtn:setImage(tex)

    DCS_UI_Panel.toolbarBtn:setDisplayBackground(false)
    DCS_UI_Panel.toolbarBtn.backgroundColor = { r=0, g=0, b=0, a=0 }
    DCS_UI_Panel.toolbarBtn.backgroundColorMouseOver = { r=0, g=0, b=0, a=0 }
    DCS_UI_Panel.toolbarBtn.borderColor = { r=0, g=0, b=0, a=0 }
    DCS_UI_Panel.toolbarBtn.tooltip = getText("IGUI_DCS_Panel_ToolbarTooltip")

    function DCS_UI_Panel.toolbarBtn:render()
        local t = self.image
        if t then
            local s = math.min(self:getWidth(), self:getHeight())
            local x = (self:getWidth() - s) / 2
            local y = (self:getHeight() - s) / 2
            if DCS_UI_Panel.isWiggling then
                local fpsFraction = UIManager.getMillisSinceLastRender() / 33.3
                DCS_UI_Panel.wiggleStep = DCS_UI_Panel.wiggleStep + 0.4 * fpsFraction
                local osc = math.sin(DCS_UI_Panel.wiggleStep)
                local maxOffset = 10.4
                x = x + osc * maxOffset
            end
            self:drawTextureScaledAspect(t, x, y, s, s, 1.0, 1, 1, 1)
        end
    end

    inst:addChild(DCS_UI_Panel.toolbarBtn)
    inst:setHeight(math.max(inst._dcsBaseHeight,
        DCS_UI_Panel.toolbarBtn:getY() + iconH + S(10)))
end

local _dcsOrigEquipPrerender = ISEquippedItem.prerender
function ISEquippedItem:prerender()
    if _dcsOrigEquipPrerender then _dcsOrigEquipPrerender(self) end
    if self.playerNum ~= 0 then return end
    local btn = DCS_UI_Panel.toolbarBtn
    local refBtn = self.invBtn
    local needsAdd = (not btn) or (btn.parent ~= self)
    if (not needsAdd) and refBtn and btn and refBtn:getWidth() ~= btn:getWidth() then
        needsAdd = true
    end
    if needsAdd then addToolbarButton(self) end
end

local function onCreatePlayer(playerIndex, player)
    if playerIndex ~= 0 then return end
    addToolbarButton(ISEquippedItem.instance)
end

Events.OnCreatePlayer.Add(onCreatePlayer)
