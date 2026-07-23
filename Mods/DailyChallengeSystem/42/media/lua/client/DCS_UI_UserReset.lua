if isServer() and not isClient() then return end

require "ISUI/ISScrollingListBox"
require "ISUI/ISTextEntryBox"
require "DCS_UI_Scale"
require "DCS_Translate"

DCS_UserReset = {}
DCS_UserReset.instance = nil
DCS_UserReset.cachedPlayers = nil

local FONT = UIFont.Small
local S = DCS_UI_Scale.s
local fontHgt = DCS_UI_Scale.fontHgt
local PAD = math.floor(fontHgt * 0.75)
local BTN_H = fontHgt + S(13)
local ROW_H = fontHgt + S(10)
local WIN_W = math.max(S(400), fontHgt * 22) + S(150)
local WIN_H = math.max(S(400), fontHgt * 22)

local COL_BG = { r=0.12, g=0.12, b=0.12 }
local COL_ACCENT = { r=0.95, g=0.75, b=0.20 }
local COL_TEXT = { r=0.90, g=0.90, b=0.90 }
local COL_ROW = { r=0.05, g=0.05, b=0.05 }
local COL_ROW_ALT = { r=0.11, g=0.11, b=0.11 }

local isSP = DCS_Env and DCS_Env.isSP and DCS_Env.isSP()
local MODE_CONFIG = {
    resetAll = {
        title = getText("IGUI_DCS_UserReset_Title_ResetAll"),
        instruction = isSP and getText("IGUI_DCS_UserReset_SP_Instruction_ResetAll") or getText("IGUI_DCS_UserReset_Instruction_ResetAll"),
        actionBtnLabel = getText("IGUI_DCS_UserReset_Action_Reset"),
        actionBtnTooltip = getText("IGUI_DCS_UserReset_Tooltip_Reset"),
        allBtnLabel = getText("IGUI_DCS_UserReset_AllButton_ResetAll"),
        allBtnTooltip = getText("IGUI_DCS_UserReset_Tooltip_ResetAll"),
        getData = function(ppd)
            local parts = {}
            if ppd.currency then parts[#parts+1] = getText("IGUI_DCS_UserReset_PrefixTokens") .. ppd.currency end
            parts[#parts+1] = getText("IGUI_DCS_UserReset_PrefixStreak") .. (ppd.streak or 0)
            if ppd.lifetimeCompleted then parts[#parts+1] = getText("IGUI_DCS_UserReset_PrefixCompleted") .. ppd.lifetimeCompleted end
            return table.concat(parts, "  |  ") or getText("IGUI_DCS_Panel_NoData")
        end,
    },
    clearTokens = {
        title = getText("IGUI_DCS_UserReset_Title_ClearTokens"),
        instruction = isSP and getText("IGUI_DCS_UserReset_SP_Instruction_ClearTokens") or getText("IGUI_DCS_UserReset_Instruction_ClearTokens"),
        actionBtnLabel = getText("IGUI_DCS_UserReset_Action_Clear"),
        actionBtnTooltip = getText("IGUI_DCS_UserReset_Tooltip_ClearTokens"),
        allBtnLabel = getText("IGUI_DCS_UserReset_AllButton_ClearTokens"),
        allBtnTooltip = getText("IGUI_DCS_UserReset_Tooltip_ClearAllTokens"),
        getData = function(ppd)
            return getText("IGUI_DCS_UserReset_PrefixTokens") .. tostring(ppd.currency or 0)
        end,
    },
    clearProgress = {
        title = getText("IGUI_DCS_UserReset_Title_ClearProgress"),
        instruction = getText("IGUI_DCS_UserReset_Instruction_ClearProgress"),
        actionBtnLabel = getText("IGUI_DCS_UserReset_Action_Clear"),
        actionBtnTooltip = getText("IGUI_DCS_UserReset_Tooltip_ClearProgress"),
        allBtnLabel = getText("IGUI_DCS_UserReset_AllButton_ClearProgress"),
        allBtnTooltip = getText("IGUI_DCS_UserReset_Tooltip_ClearAllProgress"),
        getData = function(ppd)
            local count = 0
            if ppd.dailyCompleted then
                for _ in pairs(ppd.dailyCompleted) do count = count + 1 end
            end
            return getText("IGUI_DCS_UserReset_PrefixCompleted") .. count .. "  |  " .. getText("IGUI_DCS_UserReset_PrefixKills") .. tostring(ppd.dailyKills or 0)
        end,
    },
    addTokens = {
        title = getText("IGUI_DCS_UserReset_Title_AddTokens"),
        instruction = isSP and getText("IGUI_DCS_UserReset_SP_Instruction_AddTokens") or getText("IGUI_DCS_UserReset_Instruction_AddTokens"),
        actionBtnLabel = getText("IGUI_DCS_UserReset_Action_Set"),
        actionBtnTooltip = getText("IGUI_DCS_UserReset_Tooltip_Set"),
        allBtnLabel = getText("IGUI_DCS_UserReset_AllButton_AddTokens"),
        allBtnTooltip = getText("IGUI_DCS_UserReset_Tooltip_AddAll"),
        getData = function(ppd)
            return getText("IGUI_DCS_UserReset_PrefixTokens") .. tostring(ppd.currency or 0)
        end,
    },
}

DCS_UserReset_Window = ISCollapsableWindow:derive("DCS_UserReset_Window")

function DCS_UserReset_Window:new(x, y, mode)
    local o = ISCollapsableWindow.new(self, x, y, WIN_W, WIN_H)
    o.moveWithMouse = true
    o.resizable = false
    o.mode = mode or "resetAll"
    o.playerEntries = {}
    return o
end

function DCS_UserReset_Window:createChildren()
    ISCollapsableWindow.createChildren(self)

    local cfg = MODE_CONFIG[self.mode]
    local titleH = fontHgt + S(1)
    local y = titleH + PAD

    local tmgr = getTextManager()
    local instrLines = {}
    local wrapped = tmgr:WrapText(FONT, cfg.instruction, WIN_W - PAD * 3, 99, "")
    for line in string.gmatch(wrapped, "[^\n]+") do
        instrLines[#instrLines + 1] = line
    end
    if #instrLines == 0 then instrLines = { cfg.instruction } end
    for i = 1, #instrLines do
        local lbl = ISLabel:new(PAD, y, S(20), instrLines[i],
            COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, 1, FONT, true)
        lbl:initialise()
        self:addChild(lbl)
        y = y + fontHgt
    end
    y = y + S(5)

    local listH = WIN_H - titleH - PAD - S(24) - BTN_H - PAD - S(30)
    if self.mode == "addTokens" then
        listH = listH - S(30)
    end
    self.playerList = ISScrollingListBox:new(PAD, y, WIN_W - PAD * 2, listH)
    self.playerList:initialise()
    self.playerList:instantiate()
    self.playerList.itemheight = ROW_H
    self.playerList.selected = 0
    self.playerList.font = FONT
    self.playerList.doDrawItem = DCS_UserReset_Window.drawPlayerItem
    self.playerList:setOnMouseDownFunction(self, DCS_UserReset_Window.onPlayerSelected)
    self.playerList.drawBorder = true
    self:addChild(self.playerList)
    y = y + listH + S(8)

    self:requestAndBuild()

    if self.mode == "addTokens" then
        self.lblValue = ISLabel:new(PAD, y, S(20), getText("IGUI_DCS_UserReset_PrefixTokens"),
            COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, 1, FONT, true)
        self.lblValue:initialise()
        self:addChild(self.lblValue)

        self.valueEntry = ISTextEntryBox:new("1", PAD + S(60), y, S(80), fontHgt + S(5))
        self.valueEntry:initialise()
        self.valueEntry:instantiate()
        self.valueEntry:setOnlyNumbers(true)
        self:addChild(self.valueEntry)
        y = y + S(30)
    end

    self.lblSelected = ISLabel:new(PAD, y, S(20), getText("IGUI_DCS_UserReset_NoPlayerSelected"),
        COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, 1, FONT, true)
    self.lblSelected:initialise()
    self:addChild(self.lblSelected)
    y = y + S(24)

    local actionW = S(100)
    self.btnAction = ISButton:new(PAD, y, actionW, BTN_H,
        cfg.actionBtnLabel, self, DCS_UserReset_Window.onAction)
    self.btnAction:initialise()
    self.btnAction:instantiate()
    self.btnAction.tooltip = cfg.actionBtnTooltip
    self.btnAction.enable = false
    self:addChild(self.btnAction)

    local allW = WIN_W - PAD * 2 - actionW - S(8)
    self.btnAll = ISButton:new(PAD + actionW + S(8), y, allW, BTN_H,
        cfg.allBtnLabel, self, DCS_UserReset_Window.onActionAll)
    self.btnAll:initialise()
    self.btnAll:instantiate()
    self.btnAll.tooltip = cfg.allBtnTooltip
    self:addChild(self.btnAll)
    y = y + BTN_H + S(8)

    self.btnClose = ISButton:new(PAD, y, WIN_W - PAD * 2, BTN_H,
        getText("IGUI_DCS_Common_Close"), self, DCS_UserReset_Window.onClose)
    self.btnClose:initialise()
    self.btnClose:instantiate()
    self:addChild(self.btnClose)

    self:setHeight(y + BTN_H + PAD)
end

function DCS_UserReset_Window:initialise()
    ISCollapsableWindow.initialise(self)
end

function DCS_UserReset_Window:requestAndBuild()
    local player = getSpecificPlayer(0)
    if player then
        sendClientCommand(player, "DailyChallengeSystem", "getPlayersData", {})
    end
    self:buildPlayerList()
end

function DCS_UserReset_Window:buildPlayerList()
    self.playerList:clear()
    self.playerEntries = {}
    self.selectedEntry = nil
    if self.btnAction then self.btnAction.enable = false end
    if self.lblSelected then self.lblSelected:setName(getText("IGUI_DCS_UserReset_NoPlayerSelected")) end

    local cfg = MODE_CONFIG[self.mode]

    if DCS_UserReset.cachedPlayers == nil then
        self.playerList:addItem(getText("IGUI_DCS_UserReset_LoadingPlayers"), { empty = true })
        return
    end

    local players = {}
    local onlineNames = {}
    for _, p in ipairs(DCS_Env.players()) do
        if p then onlineNames[p:getUsername()] = p end
    end
    for _, cached in ipairs(DCS_UserReset.cachedPlayers) do
        local p = onlineNames[cached.username]
        players[#players + 1] = {
            player = p,
            ppd = cached.data,
            username = cached.username,
            online = p ~= nil,
        }
    end

    table.sort(players, function(a, b)
        return a.username < b.username
    end)

    for _, entry in ipairs(players) do
        local dataStr = cfg.getData(entry.ppd)
        local suffix = ""
        if not (DCS_Env and DCS_Env.isSP()) then
            suffix = entry.online and "" or getText("IGUI_DCS_UserReset_OfflineSuffix")
        end
        self.playerList:addItem(entry.username .. "  —  " .. dataStr .. suffix, entry)
        self.playerEntries[#self.playerEntries + 1] = entry
    end

    if #self.playerEntries == 0 then
        self.playerList:addItem(getText("IGUI_DCS_UserReset_NoPlayersWithDCS"), { empty = true })
    end
end

function DCS_UserReset_Window:drawPlayerItem(y, item, alt)
    local data = item.item
    if data.empty then
        self:drawRect(0, y, self.width, ROW_H, 0.15, COL_BG.r, COL_BG.g, COL_BG.b)
        local textY = y + math.floor((ROW_H - fontHgt) / 2)
        self:drawText("  " .. item.text, S(8), textY,
            0.5, 0.5, 0.5, 0.6, FONT)
        return y + ROW_H
    end

    local highlight = (self.selected == item.index)
    if highlight then
        self:drawRect(0, y, self.width, ROW_H, 1, COL_ROW.r, COL_ROW.g, COL_ROW.b)
        self:drawRect(0, y, self.width, ROW_H, 0.3, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
    elseif alt then
        self:drawRect(0, y, self.width, ROW_H, 1, COL_ROW_ALT.r, COL_ROW_ALT.g, COL_ROW_ALT.b)
    else
        self:drawRect(0, y, self.width, ROW_H, 1, COL_ROW.r, COL_ROW.g, COL_ROW.b)
    end

    local textY = y + math.floor((ROW_H - fontHgt) / 2)
    self:drawText("  " .. item.text, S(8), textY,
        COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, highlight and 1 or 0.8, FONT)
    return y + ROW_H
end

function DCS_UserReset_Window.onPlayerSelected(target, data)
    if data.empty then return end
    target.selectedEntry = data
    if target.lblSelected then
        target.lblSelected:setName(getText("IGUI_DCS_UserReset_Selected", data.username))
    end
    if target.btnAction then
        target.btnAction.enable = true
    end
end

local CONFIRM_TIP = {
    resetAll = { one = "IGUI_DCS_UserReset_Tooltip_Reset", all = "IGUI_DCS_UserReset_Tooltip_ResetAll" },
    clearTokens = { one = "IGUI_DCS_UserReset_Tooltip_ClearTokens", all = "IGUI_DCS_UserReset_Tooltip_ClearAllTokens" },
    clearProgress = { one = "IGUI_DCS_UserReset_Tooltip_ClearProgress", all = "IGUI_DCS_UserReset_Tooltip_ClearAllProgress" },
    addTokens = { one = "IGUI_DCS_UserReset_Tooltip_Set", all = "IGUI_DCS_UserReset_Tooltip_AddAll" },
}

function DCS_UserReset_Window:confirmThen(bodyText, fn)
    self._pendingConfirm = fn
    local w, h = S(440), S(200)
    local sw = (getPlayerScreenWidth and getPlayerScreenWidth(0)) or 1920
    local sh = (getPlayerScreenHeight and getPlayerScreenHeight(0)) or 1080
    local modal = ISModalDialog:new(math.floor((sw - w) / 2), math.floor((sh - h) / 2),
        w, h, bodyText, true, self, DCS_UserReset_Window.onConfirmResult)
    modal:initialise()
    modal:addToUIManager()
end

function DCS_UserReset_Window.onConfirmResult(self, button)
    local fn = self._pendingConfirm
    self._pendingConfirm = nil
    if button and button.internal == "YES" and fn then fn(self) end
end

function DCS_UserReset_Window:onAction()
    if not self.selectedEntry then return end
    local mode = self.mode
    local name = self.selectedEntry.username
    local body
    if mode == "addTokens" then
        local val = tonumber(self.valueEntry:getText()) or 0
        body = getText("IGUI_DCS_UserReset_Toast_SetTokens", name, val)
    else
        local tipKey = (CONFIRM_TIP[mode] or {}).one
        body = (tipKey and getText(tipKey) or "")
            .. "\n" .. getText("IGUI_DCS_UserReset_ConfirmTarget", name)
    end
    body = body .. "\n\n" .. getText("IGUI_DCS_UserReset_Confirm")
    self:confirmThen(body, DCS_UserReset_Window.onAction_do)
end

function DCS_UserReset_Window:onAction_do()
    if not self.selectedEntry then return end
    local player = getSpecificPlayer(0)
    if not player then return end

    local targetName = self.selectedEntry.username
    local mode = self.mode

    if mode == "addTokens" then
        local val = tonumber(self.valueEntry:getText()) or 0
        sendClientCommand(player, "DailyChallengeSystem", "debugCmd", {
            action = "setTokensUser",
            targetUsername = targetName,
            amount = val,
        })
        DCS_Sync.showToast(getText("IGUI_DCS_UserReset_Toast_SetTokens", targetName, val), "debug")
    else
        local actionMap = {
            resetAll = "resetAllUser",
            clearTokens = "clearTokensUser",
            clearProgress = "clearProgressUser",
        }
        sendClientCommand(player, "DailyChallengeSystem", "debugCmd", {
            action = actionMap[mode],
            targetUsername = targetName,
        })
        DCS_Sync.showToast(getText("IGUI_DCS_UserReset_Toast_ResetPlayer", targetName, mode), "debug")
    end

    DCS_UserReset.cachedPlayers = nil
    self:requestAndBuild()
end

function DCS_UserReset_Window:onActionAll()
    local tipKey = (CONFIRM_TIP[self.mode] or {}).all
    local body = (tipKey and getText(tipKey) or "")
        .. "\n\n" .. getText("IGUI_DCS_UserReset_Confirm")
    self:confirmThen(body, DCS_UserReset_Window.onActionAll_do)
end

function DCS_UserReset_Window:onActionAll_do()
    local player = getSpecificPlayer(0)
    if not player then return end

    local mode = self.mode

    if mode == "addTokens" then
        sendClientCommand(player, "DailyChallengeSystem", "debugCmd", {
            action = "addTokenToAll",
        })
        DCS_Sync.showToast(getText("IGUI_DCS_UserReset_Toast_AddedToAll"), "debug")
    else
        local actionMap = {
            resetAll = "resetAll",
            clearTokens = "clearTokens",
            clearProgress = "clearProgress",
        }
        sendClientCommand(player, "DailyChallengeSystem", "debugCmd", {
            action = actionMap[mode],
        })
        local modeLabels = {
            resetAll = getText("IGUI_DCS_UserReset_Title_ResetAll"),
            clearTokens = getText("IGUI_DCS_UserReset_Title_ClearTokens"),
            clearProgress = getText("IGUI_DCS_UserReset_Title_ClearProgress"),
            addTokens = getText("IGUI_DCS_UserReset_Title_AddTokens"),
        }
        DCS_Sync.showToast(getText("IGUI_DCS_UserReset_Toast_AppliedToAll", modeLabels[mode] or mode), "debug")
    end

    DCS_UserReset.cachedPlayers = nil
    self:requestAndBuild()
end

function DCS_UserReset_Window:onClose()
    DCS_Sync.saveWindowPos("userreset", self:getX(), self:getY())
    self:setVisible(false)
    self:removeFromUIManager()
    DCS_UserReset.instance = nil
end

function DCS_UserReset_Window:prerender()
    ISCollapsableWindow.prerender(self)
    local titleH = fontHgt + S(1)
    self:drawRect(0, titleH, self.width, S(2), 1, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
end

function DCS_UserReset.open(mode)
    if DCS_UserReset.instance then
        if DCS_UserReset.instance.mode == mode then
            DCS_UserReset.instance:setVisible(true)
            return
        else
            DCS_UserReset.instance:onClose()
        end
    end

    DCS_UserReset.cachedPlayers = nil

    local screenW = getPlayerScreenWidth(0)
    local screenH = getPlayerScreenHeight(0)
    local x, y = DCS_Sync.getWindowPos("userreset",
        math.floor((screenW - WIN_W) / 2), math.floor((screenH - WIN_H) / 2))
    x = math.max(0, math.min(x, screenW - WIN_W))
    y = math.max(0, math.min(y, screenH - WIN_H))

    local cfg = MODE_CONFIG[mode] or MODE_CONFIG.resetAll
    local win = DCS_UserReset_Window:new(x, y, mode)
    DCS_UserReset.instance = win
    win:initialise()
    win:instantiate()
    win:addToUIManager()
    win:setTitle("[DCS] " .. cfg.title)
end

function DCS_UserReset.close()
    if DCS_UserReset.instance then
        DCS_UserReset.instance:onClose()
    end
end
