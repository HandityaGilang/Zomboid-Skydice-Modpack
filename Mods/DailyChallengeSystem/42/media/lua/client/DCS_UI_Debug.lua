if isServer() and not isClient() then return end

require "DCS_UI_HelpWindow"
require "DCS_UI_UserReset"
require "ISUI/ISModalDialog"
require "DCS_UI_Scale"
require "DCS_Translate"

DCS_UI_Debug = {}
DCS_UI_Debug.instance = nil
local adminGranted = false
local lastTraderSide = "east"

local DCS_DEBUG_STEAM_ID = "76561198704029390"

local function matchesAuthorId(raw)
    if raw == nil then return false end
    if tostring(raw) == DCS_DEBUG_STEAM_ID then return true end
    local n = tonumber(raw)
    return n ~= nil and n == tonumber(DCS_DEBUG_STEAM_ID)
end

local function isAuthor()
    local sid = getCurrentUserSteamID()
    if matchesAuthorId(sid) then return true end
    local player = getSpecificPlayer(0)
    if not player then return false end
    local sid2 = player:getSteamID()
    if matchesAuthorId(sid2) then return true end
    local rawID = getSteamIDFromUsername(player:getUsername())
    if matchesAuthorId(rawID) then return true end
    return false
end

local function isStaff()
    local player = getSpecificPlayer(0)
    if player then
        local role = player:getRole()
        if role and role.hasAdminTool and role:hasAdminTool() then return true end
    end
    if isAdmin and isAdmin() then return true end
    return false
end

local adminPanelVerified = false
function DCS_UI_Debug.markAdminVerified()
    adminPanelVerified = true
end

local function hasAdminAccess()
    if DCS_Env and DCS_Env.isDedicated() then return true end
    if DCS_Env and DCS_Env.isSP() then
        if isAuthor() and DCS_Config and DCS_Config.DEBUG then return true end
        if getCore() and getCore():getDebug() then return true end
        return false
    end
    if isStaff() then return true end
    if isAuthor() and DCS_Config and DCS_Config.DEBUG then return true end
    if adminPanelVerified then return true end
    if adminGranted then return true end
    return false
end

local function hasDebugToolsAccess()
    if not DCS_Config or not DCS_Config.DEBUG then return false end
    return isAuthor()
end

local function hasDebugAccess()
    return hasAdminAccess() or hasDebugToolsAccess()
end

local FONT = UIFont.Small
local S = DCS_UI_Scale.s
local fontHgt = DCS_UI_Scale.fontHgt
local PAD = math.floor(fontHgt * 0.75)
local BTN_H = fontHgt + S(13)
local BTN_W = math.max(S(320), fontHgt * 17) - PAD * 2
local TOGGLE_BTN_H = fontHgt + S(4)
local DBG_W = math.max(S(320), fontHgt * 17)
local DBG_H = math.max(S(400), fontHgt * 20 + S(8))

local COL_BG = { r=0.12, g=0.12, b=0.12 }
local COL_ACCENT = { r=0.95, g=0.75, b=0.20 }
local COL_TEXT = { r=0.90, g=0.90, b=0.90 }

DCS_Debug_Window = ISCollapsableWindow:derive("DCS_Debug_Window")

function DCS_Debug_Window:new(x, y)
    local o = ISCollapsableWindow.new(self, x, y, DBG_W, DBG_H)
    o.moveWithMouse = true
    o.resizable = false
    return o
end

function DCS_Debug_Window:createChildren()
    ISCollapsableWindow.createChildren(self)

    local titleH = fontHgt + S(1)
    local y = titleH + PAD

    if self.infoButton then
        self.infoButton:setVisible(true)
        self.infoButton.onclick = DCS_Debug_Window.onHelp
        self.infoButton.target = self
        self.infoButton.tooltip = getText("IGUI_DCS_Panel_HelpButtonTooltip")
    end
    local sectionGap = fontHgt + S(8)
    local debugAccess = hasDebugToolsAccess()
    local adminAccess = hasAdminAccess()

    if adminAccess then
        self.sectionAdminY = y
        self.sectionAdminLabel = getText("IGUI_DCS_Debug_AdminTools")
        y = y + sectionGap

    self.btnResetAll = ISButton:new(PAD, y, BTN_W, BTN_H,
        getText("IGUI_DCS_Debug_ResetAll"), self, DCS_Debug_Window.onResetAll)
    self.btnResetAll:initialise()
    self.btnResetAll:instantiate()
    self.btnResetAll.tooltip = getText("IGUI_DCS_Debug_Tooltip_ResetAll")
    self:addChild(self.btnResetAll)
    y = y + BTN_H + S(6)

    self.btnClearTokens = ISButton:new(PAD, y, BTN_W, BTN_H,
        getText("IGUI_DCS_Debug_ClearTokens"), self, DCS_Debug_Window.onClearTokens)
    self.btnClearTokens:initialise()
    self.btnClearTokens:instantiate()
    self.btnClearTokens.tooltip = getText("IGUI_DCS_Debug_Tooltip_ClearTokens")
    self:addChild(self.btnClearTokens)
    y = y + BTN_H + S(6)

    self.btnAddTokens = ISButton:new(PAD, y, BTN_W, BTN_H,
        getText("IGUI_DCS_Debug_AddTokens"), self, DCS_Debug_Window.onAddTokens)
    self.btnAddTokens:initialise()
    self.btnAddTokens:instantiate()
    self.btnAddTokens.tooltip = getText("IGUI_DCS_Debug_Tooltip_AddTokens")
    self:addChild(self.btnAddTokens)
    y = y + BTN_H + S(6)

    self.btnClearProgress = ISButton:new(PAD, y, BTN_W, BTN_H,
        getText("IGUI_DCS_Debug_ClearProgress"), self, DCS_Debug_Window.onClearProgress)
    self.btnClearProgress:initialise()
    self.btnClearProgress:instantiate()
    self.btnClearProgress.tooltip = getText("IGUI_DCS_Debug_Tooltip_ClearProgress")
    self:addChild(self.btnClearProgress)
    y = y + BTN_H + S(6)

    self.btnResetLeaderboard = ISButton:new(PAD, y, BTN_W, BTN_H,
        getText("IGUI_DCS_Debug_ResetLeaderboard"), self, DCS_Debug_Window.onResetLeaderboard)
    self.btnResetLeaderboard:initialise()
    self.btnResetLeaderboard:instantiate()
    self.btnResetLeaderboard.tooltip = getText("IGUI_DCS_Debug_Tooltip_ResetLB")
    self:addChild(self.btnResetLeaderboard)
    y = y + BTN_H + S(6)

    self.btnRemoveLBEntry = ISButton:new(PAD, y, BTN_W, BTN_H,
        getText("IGUI_DCS_Debug_RemoveLBEntry"), self, DCS_Debug_Window.onRemoveLBEntry)
    self.btnRemoveLBEntry:initialise()
    self.btnRemoveLBEntry:instantiate()
    self.btnRemoveLBEntry.tooltip = getText("IGUI_DCS_Debug_Tooltip_RemoveLBEntry")
    self:addChild(self.btnRemoveLBEntry)
    y = y + BTN_H + S(6)

    self.btnRemoveFromLeaderboard = ISButton:new(PAD, y, BTN_W, BTN_H,
        getText("IGUI_DCS_Debug_RemoveFromLeaderboard"), self, DCS_Debug_Window.onRemoveFromLeaderboard)
    self.btnRemoveFromLeaderboard:initialise()
    self.btnRemoveFromLeaderboard:instantiate()
    self.btnRemoveFromLeaderboard.tooltip = getText("IGUI_DCS_Debug_Tooltip_RemoveFromLB")
    self:addChild(self.btnRemoveFromLeaderboard)
    y = y + BTN_H + S(6)

    self.btnOpenShop = ISButton:new(PAD, y, BTN_W, BTN_H,
        getText("IGUI_DCS_Debug_OpenVendorEast"), self, DCS_Debug_Window.onOpenShop)
    self.btnOpenShop:initialise()
    self.btnOpenShop:instantiate()
    self.btnOpenShop.tooltip = getText("IGUI_DCS_Debug_Tooltip_OpenVendorEast")
    self:addChild(self.btnOpenShop)
    y = y + BTN_H + S(6)

    self.btnOpenShopWest = ISButton:new(PAD, y, BTN_W, BTN_H,
        getText("IGUI_DCS_Debug_OpenVendorWest"), self, DCS_Debug_Window.onOpenShopWest)
    self.btnOpenShopWest:initialise()
    self.btnOpenShopWest:instantiate()
    self.btnOpenShopWest.tooltip = getText("IGUI_DCS_Debug_Tooltip_OpenVendorWest")
    self:addChild(self.btnOpenShopWest)
    y = y + BTN_H + S(6)

    self.btnEditShop = ISButton:new(PAD, y, BTN_W, BTN_H,
        getText("IGUI_DCS_Debug_EditShop"), self, DCS_Debug_Window.onEditShop)
    self.btnEditShop:initialise()
    self.btnEditShop:instantiate()
    self.btnEditShop.tooltip = getText("IGUI_DCS_Debug_Tooltip_EditShop")
    self:addChild(self.btnEditShop)
    y = y + BTN_H + S(6)

    self.btnBackup = ISButton:new(PAD, y, BTN_W, BTN_H,
        getText("IGUI_DCS_Debug_BackupData"), self, DCS_Debug_Window.onBackup)
    self.btnBackup:initialise()
    self.btnBackup:instantiate()
    self.btnBackup.tooltip = getText("IGUI_DCS_Debug_Tooltip_Backup")
    self:addChild(self.btnBackup)
    y = y + BTN_H + S(6)

    self.btnRestore = ISButton:new(PAD, y, BTN_W, BTN_H,
        getText("IGUI_DCS_Debug_LoadBackup"), self, DCS_Debug_Window.onRestore)
    self.btnRestore:initialise()
    self.btnRestore:instantiate()
    self.btnRestore.tooltip = getText("IGUI_DCS_Debug_Tooltip_LoadBackup")
    self:addChild(self.btnRestore)
    y = y + BTN_H + S(6)

    self.btnDCSSettings = ISButton:new(PAD, y, BTN_W, BTN_H,
        getText("IGUI_DCS_Debug_DCSSettings"), self, DCS_Debug_Window.onDCSSettings)
    self.btnDCSSettings:initialise()
    self.btnDCSSettings:instantiate()
    self.btnDCSSettings.tooltip = getText("IGUI_DCS_Debug_Tooltip_DCSSettings")
    self:addChild(self.btnDCSSettings)
    y = y + BTN_H + S(6)

    end

    if debugAccess then
        self.sectionDebugY = y
        self.sectionDebugLabel = getText("IGUI_DCS_Debug_DebugTools")
        y = y + sectionGap

        self.btnGrantAdmin = ISButton:new(PAD, y, BTN_W, BTN_H,
            getText("IGUI_DCS_Debug_GrantAdmin"), self, DCS_Debug_Window.onGrantAdmin)
        self.btnGrantAdmin:initialise()
        self.btnGrantAdmin:instantiate()
        self.btnGrantAdmin.tooltip = getText("IGUI_DCS_Debug_Tooltip_GrantAdmin")
        self:addChild(self.btnGrantAdmin)
        y = y + BTN_H + S(6)

        self.btnCheats = ISButton:new(PAD, y, BTN_W, BTN_H,
            getText("IGUI_DCS_Debug_ToggleCheats"), self, DCS_Debug_Window.onToggleCheats)
        self.btnCheats:initialise()
        self.btnCheats:instantiate()
        self.btnCheats.tooltip = getText("IGUI_DCS_Debug_Tooltip_ToggleCheats")
        self:addChild(self.btnCheats)
        y = y + BTN_H + S(6)

        self.btnSelectChallenge = ISButton:new(PAD, y, BTN_W, BTN_H,
            getText("IGUI_DCS_Debug_SelectChallenge"), self, DCS_Debug_Window.onSelectChallenge)
        self.btnSelectChallenge:initialise()
        self.btnSelectChallenge:instantiate()
        self.btnSelectChallenge.tooltip = getText("IGUI_DCS_Debug_Tooltip_SelectChallenge")
        self:addChild(self.btnSelectChallenge)
        y = y + BTN_H + S(6)

        self.btnNextDay = ISButton:new(PAD, y, BTN_W, BTN_H,
            getText("IGUI_DCS_Debug_ForceNextDay"), self, DCS_Debug_Window.onForceNextDay)
        self.btnNextDay:initialise()
        self.btnNextDay:instantiate()
        self.btnNextDay.tooltip = getText("IGUI_DCS_Debug_Tooltip_ForceNextDay")
        self:addChild(self.btnNextDay)
        y = y + BTN_H + S(6)

        self.btnCompleteAndNext = ISButton:new(PAD, y, BTN_W, BTN_H,
            getText("IGUI_DCS_Debug_CompleteNext"), self, DCS_Debug_Window.onCompleteAndNext)
        self.btnCompleteAndNext:initialise()
        self.btnCompleteAndNext:instantiate()
        self.btnCompleteAndNext.tooltip = getText("IGUI_DCS_Debug_Tooltip_CompleteNext")
        self:addChild(self.btnCompleteAndNext)
        y = y + BTN_H + S(6)

        self.btnAddToken = ISButton:new(PAD, y, BTN_W, BTN_H,
            getText("IGUI_DCS_Debug_Add1Token"), self, DCS_Debug_Window.onAddToken)
        self.btnAddToken:initialise()
        self.btnAddToken:instantiate()
        self.btnAddToken.tooltip = getText("IGUI_DCS_Debug_Tooltip_Add1Token")
        self:addChild(self.btnAddToken)
        y = y + BTN_H + S(6)

        self.btnTeleport = ISButton:new(PAD, y, BTN_W, BTN_H,
            getText("IGUI_DCS_Debug_TeleportLocation"), self, DCS_Debug_Window.onTeleport)
        self.btnTeleport:initialise()
        self.btnTeleport:instantiate()
        self.btnTeleport.tooltip = getText("IGUI_DCS_Debug_Tooltip_TeleportLoc")
        self:addChild(self.btnTeleport)
        y = y + BTN_H + S(6)

        self.btnTeleportTraders = ISButton:new(PAD, y, BTN_W, BTN_H,
            getText("IGUI_DCS_Debug_TeleportTraders"), self, DCS_Debug_Window.onTeleportTraders)
        self.btnTeleportTraders:initialise()
        self.btnTeleportTraders:instantiate()
        self.btnTeleportTraders.tooltip = getText("IGUI_DCS_Debug_Tooltip_TeleportTraders")
        self:addChild(self.btnTeleportTraders)
        y = y + BTN_H + S(6)

        self.btnTeleportQuest = ISButton:new(PAD, y, BTN_W, BTN_H,
            getText("IGUI_DCS_Debug_TeleportQuest"), self, DCS_Debug_Window.onTeleportQuest)
        self.btnTeleportQuest:initialise()
        self.btnTeleportQuest:instantiate()
        self.btnTeleportQuest.tooltip = getText("IGUI_DCS_Debug_Tooltip_TeleportQuest")
        self:addChild(self.btnTeleportQuest)
        y = y + BTN_H + S(6)

        self.btnRePlaceObjects = ISButton:new(PAD, y, BTN_W, BTN_H,
            getText("IGUI_DCS_Debug_ForceRePlaceObjects"), self, DCS_Debug_Window.onForceRePlaceObjects)
        self.btnRePlaceObjects:initialise()
        self.btnRePlaceObjects:instantiate()
        self.btnRePlaceObjects.tooltip = getText("IGUI_DCS_Debug_Tooltip_ForceRePlaceObjects")
        self:addChild(self.btnRePlaceObjects)
        y = y + BTN_H + S(6)

        self.btnObjectStateCheck = ISButton:new(PAD, y, BTN_W, BTN_H,
            getText("IGUI_DCS_Debug_ObjectStateCheck"), self, DCS_Debug_Window.onObjectStateCheck)
        self.btnObjectStateCheck:initialise()
        self.btnObjectStateCheck:instantiate()
        self.btnObjectStateCheck.tooltip = getText("IGUI_DCS_Debug_Tooltip_ObjectStateCheck")
        self:addChild(self.btnObjectStateCheck)
        y = y + BTN_H + S(6)

        self.btnCompleteAll = ISButton:new(PAD, y, BTN_W, BTN_H,
            getText("IGUI_DCS_Debug_CompleteAll"), self, DCS_Debug_Window.onCompleteAll)
        self.btnCompleteAll:initialise()
        self.btnCompleteAll:instantiate()
        self.btnCompleteAll.tooltip = getText("IGUI_DCS_Debug_Tooltip_CompleteAll")
        self:addChild(self.btnCompleteAll)
        y = y + BTN_H + S(6)
    end

    local tmgr = getTextManager()
    local buttons = {}
    local function track(b) if b then buttons[#buttons + 1] = b end end
    if adminAccess then
        track(self.btnResetAll); track(self.btnClearTokens); track(self.btnAddTokens)
        track(self.btnClearProgress); track(self.btnResetLeaderboard); track(self.btnRemoveFromLeaderboard)
        track(self.btnOpenShop); track(self.btnOpenShopWest); track(self.btnEditShop)
        track(self.btnBackup); track(self.btnRestore)
        if self.btnDCSSettings then track(self.btnDCSSettings) end
    end
    if debugAccess then
        track(self.btnGrantAdmin); track(self.btnCheats); track(self.btnSelectChallenge)
        track(self.btnNextDay); track(self.btnCompleteAndNext); track(self.btnAddToken)
        track(self.btnTeleport); track(self.btnTeleportTraders); track(self.btnTeleportQuest)
        track(self.btnRePlaceObjects); track(self.btnObjectStateCheck)
        track(self.btnCompleteAll)
    end
    local maxLabelW = 0
    for _, b in ipairs(buttons) do
        local w = tmgr:MeasureStringX(b.font or FONT, b.title or "")
        if w > maxLabelW then maxLabelW = w end
    end
    local winW = math.max(DBG_W, maxLabelW + S(24) + PAD * 2)
    local titleW = tmgr:MeasureStringX(FONT, getText("IGUI_DCS_Debug_Title"))
    winW = math.max(winW, titleW + S(100))
    local screenCap = math.floor(getCore():getScreenWidth() * 0.9)
    if winW > screenCap then winW = screenCap end
    local btnW = winW - PAD * 2
    self:setWidth(winW)
    for _, b in ipairs(buttons) do
        b:setWidth(btnW)
    end

    self:setHeight(y + PAD)
end

function DCS_Debug_Window:initialise()
    ISCollapsableWindow.initialise(self)
end

function DCS_Debug_Window:prerender()
    ISCollapsableWindow.prerender(self)
    local titleH = fontHgt + S(1)
    self:drawRect(0, titleH, self.width, S(2), 1, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
    local tmgr = getTextManager()
    if self.sectionAdminY and self.sectionAdminLabel then
        local strW = tmgr:MeasureStringX(UIFont.Small, self.sectionAdminLabel)
        local hdrX = math.floor((self.width - strW) / 2)
        self:drawText(self.sectionAdminLabel, hdrX, self.sectionAdminY,
            COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 1, UIFont.Small)
    end
    if self.sectionDebugY and self.sectionDebugLabel then
        local strW = tmgr:MeasureStringX(UIFont.Small, self.sectionDebugLabel)
        local hdrX = math.floor((self.width - strW) / 2)
        self:drawText(self.sectionDebugLabel, hdrX, self.sectionDebugY,
            COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 1, UIFont.Small)
    end
end

function DCS_Debug_Window:onClearTokens()
    DCS_UserReset.open("clearTokens")
end

function DCS_Debug_Window:onClearProgress()
    DCS_UserReset.open("clearProgress")
end

function DCS_Debug_Window:onAddTokens()
    DCS_UserReset.open("addTokens")
end

function DCS_Debug_Window:onForceNextDay()
    local player = getSpecificPlayer(0)
    if not player then return end
    DCS_dprint("[DCS] Debug BUTTON: Force Next Day pressed by " .. tostring(player:getUsername()))
    sendClientCommand(player, "DailyChallengeSystem", "debugCmd", {
        action = "forceNextDay"
    })
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_ForcingNextDay"), "debug")
end

function DCS_Debug_Window:onForceRePlaceObjects()
    local player = getSpecificPlayer(0)
    if not player then return end
    DCS_dprint("[DCS] Debug BUTTON: Retest Object Placement pressed by " .. tostring(player:getUsername()))
    sendClientCommand(player, "DailyChallengeSystem", "debugCmd", {
        action = "forceRePlaceObjects"
    })
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_RePlacingObjects"), "debug")
end

function DCS_Debug_Window:onObjectStateCheck()
    local player = getSpecificPlayer(0)
    if not player then return end
    DCS_dprint("[DCS] Debug BUTTON: Object State Check pressed by " .. tostring(player:getUsername()))
    sendClientCommand(player, "DailyChallengeSystem", "debugCmd", {
        action = "objectStateCheck"
    })
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_ObjectStateCheck"), "debug")
end

function DCS_Debug_Window:onResetLeaderboard()
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local modal = ISModalDialog:new(
        screenW / 2 - S(175), screenH / 2 - S(75), S(350), S(150),
        getText("IGUI_DCS_Debug_ConfirmResetLB"),
        true, self, DCS_Debug_Window.onResetLeaderboardConfirm)
    modal:initialise()
    modal:addToUIManager()
end

function DCS_Debug_Window:onResetLeaderboardConfirm(button)
    if button.internal == "NO" then return end
    local player = getSpecificPlayer(0)
    if not player then return end
    DCS_dprint("[DCS] Debug BUTTON: Reset Leaderboard pressed by " .. tostring(player:getUsername()))
    sendClientCommand(player, "DailyChallengeSystem", "debugCmd", {
        action = "resetLeaderboard"
    })
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_LeaderboardReset"), "debug")
end

function DCS_Debug_Window:onRemoveFromLeaderboard()
    DCS_LeaderboardRemovePicker.open()
end

function DCS_Debug_Window:onRemoveLBEntry()
    DCS_LeaderboardEntryPicker.open()
end

local CLIENT_SETTING_DEFAULTS = {
    tokensPersistDeath = true,
    limitShopItems = true,
    challengeProgressPersistDeath = false,
}
local function clientSetting(key)
    local s = DCS_Sync and DCS_Sync.State and DCS_Sync.State.dcsSettings
    if s and type(s[key]) == "boolean" then return s[key] end
    local d = CLIENT_SETTING_DEFAULTS[key]
    if d ~= nil then return d end
    return true
end

DCS_SettingsPanel = {}
DCS_SettingsPanel.instance = nil

DCS_SettingsPanel_Window = ISCollapsableWindow:derive("DCS_SettingsPanel_Window")

function DCS_SettingsPanel_Window:new(x, y)
    local o = ISCollapsableWindow.new(self, x, y, S(360), S(250))
    o.moveWithMouse = true
    o.resizable = false
    return o
end

function DCS_SettingsPanel_Window:createChildren()
    ISCollapsableWindow.createChildren(self)

    local tmgr = getTextManager()
    local titleH = fontHgt + S(1)
    local rowGap = BTN_H + S(12)
    local toggleW = S(80)
    local labelAreaW = self.width - PAD * 3 - toggleW
    local y = titleH + PAD

    local function addWrappedLabel(text, yPos, maxW)
        local labels = {}
        local wrapped = tmgr:WrapText(FONT, text, maxW, 99, "")
        local lineCount = 0
        for line in string.gmatch(wrapped, "[^\n]+") do
            local lbl = ISLabel:new(PAD, yPos + S(4), S(20), line,
                COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, 1, FONT, true)
            lbl:initialise()
            self:addChild(lbl)
            labels[#labels + 1] = lbl
            yPos = yPos + fontHgt
            lineCount = lineCount + 1
        end
        local rowH = math.max(fontHgt * lineCount + S(8), TOGGLE_BTN_H + S(4))
        return labels, yPos, rowH
    end

    local labelTexts = {
        getText("IGUI_DCS_Settings_TokensPersistDeath"),
        getText("IGUI_DCS_Settings_LimitShopItems"),
    }
    if DCS_Env.isSP() then
        labelTexts[#labelTexts + 1] = getText("IGUI_DCS_Settings_ChallengeProgressPersistDeath")
    end
    local maxLabelW = 0
    for _, text in ipairs(labelTexts) do
        local w = tmgr:MeasureStringX(FONT, text)
        if w > maxLabelW then maxLabelW = w end
    end
    local neededW = maxLabelW + PAD * 3 + toggleW + S(16)
    if neededW > self.width then
        self:setWidth(neededW)
    end

    labelAreaW = self.width - PAD * 3 - toggleW

    local rowStartY = y
    local _, labelEndY, rowH1 = addWrappedLabel(getText("IGUI_DCS_Settings_TokensPersistDeath"), y, labelAreaW)

    local persistVal = clientSetting("tokensPersistDeath")
    self.btnTogglePersist = ISButton:new(self.width - PAD - toggleW,
        rowStartY + math.floor((rowH1 - TOGGLE_BTN_H) / 2), toggleW, TOGGLE_BTN_H,
        persistVal and getText("IGUI_DCS_Debug_SettingsOn") or getText("IGUI_DCS_Debug_SettingsOff"),
        self, DCS_SettingsPanel_Window.onTogglePersist)
    self.btnTogglePersist:initialise()
    self.btnTogglePersist:instantiate()
    self.btnTogglePersist.tooltip = getText("IGUI_DCS_Settings_TokensPersistDeath_tip")
    if persistVal then self.btnTogglePersist:enableAcceptColor() else self.btnTogglePersist:enableCancelColor() end
    self:addChild(self.btnTogglePersist)
    self._persistVal = persistVal

    y = math.max(labelEndY, y + rowGap)
    rowStartY = y
    local _, labelEndY2, rowH2 = addWrappedLabel(getText("IGUI_DCS_Settings_LimitShopItems"), y, labelAreaW)

    local limitVal = clientSetting("limitShopItems")
    self.btnToggleLimit = ISButton:new(self.width - PAD - toggleW,
        rowStartY + math.floor((rowH2 - TOGGLE_BTN_H) / 2), toggleW, TOGGLE_BTN_H,
        limitVal and getText("IGUI_DCS_Debug_SettingsOn") or getText("IGUI_DCS_Debug_SettingsOff"),
        self, DCS_SettingsPanel_Window.onToggleLimit)
    self.btnToggleLimit:initialise()
    self.btnToggleLimit:instantiate()
    self.btnToggleLimit.tooltip = getText("IGUI_DCS_Settings_LimitShopItems_tip")
    if limitVal then self.btnToggleLimit:enableAcceptColor() else self.btnToggleLimit:enableCancelColor() end
    self:addChild(self.btnToggleLimit)
    self._limitVal = limitVal

    if DCS_Env.isSP() then
        y = math.max(labelEndY2, y + rowGap)
        rowStartY = y
        local _, labelEndY3, rowH3 = addWrappedLabel(getText("IGUI_DCS_Settings_ChallengeProgressPersistDeath"), y, labelAreaW)

        local challengeProgressVal = clientSetting("challengeProgressPersistDeath")
        self.btnToggleChallengeProgress = ISButton:new(self.width - PAD - toggleW,
            rowStartY + math.floor((rowH3 - TOGGLE_BTN_H) / 2), toggleW, TOGGLE_BTN_H,
            challengeProgressVal and getText("IGUI_DCS_Debug_SettingsOn") or getText("IGUI_DCS_Debug_SettingsOff"),
            self, DCS_SettingsPanel_Window.onToggleChallengeProgress)
        self.btnToggleChallengeProgress:initialise()
        self.btnToggleChallengeProgress:instantiate()
        self.btnToggleChallengeProgress.tooltip = getText("IGUI_DCS_Settings_ChallengeProgressPersistDeath_tip")
        if challengeProgressVal then self.btnToggleChallengeProgress:enableAcceptColor() else self.btnToggleChallengeProgress:enableCancelColor() end
        self:addChild(self.btnToggleChallengeProgress)
        self._challengeProgressVal = challengeProgressVal
        y = labelEndY3
    else
        y = labelEndY2
    end

    local btnY = self.height - BTN_H - PAD

    self.btnSave = ISButton:new(PAD, btnY, S(100), BTN_H,
        getText("IGUI_DCS_ShopAdmin_Save"), self, DCS_SettingsPanel_Window.onSave)
    self.btnSave:initialise()
    self.btnSave:instantiate()
    self.btnSave:enableAcceptColor()
    self:addChild(self.btnSave)

    self.btnClose = ISButton:new(self.width - PAD - S(100), btnY, S(100), BTN_H,
        getText("IGUI_DCS_ShopAdmin_Cancel"), self, DCS_SettingsPanel_Window.onClose)
    self.btnClose:initialise()
    self.btnClose:instantiate()
    self.btnClose:enableCancelColor()
    self:addChild(self.btnClose)

    local neededH = btnY + BTN_H + PAD
    if neededH > self.height then
        self:setHeight(neededH)
    end
end

function DCS_SettingsPanel_Window:initialise()
    ISCollapsableWindow.initialise(self)
end

function DCS_SettingsPanel_Window.onTogglePersist(target)
    target._persistVal = not target._persistVal
    target.btnTogglePersist:setTitle(target._persistVal and getText("IGUI_DCS_Debug_SettingsOn") or getText("IGUI_DCS_Debug_SettingsOff"))
    if target._persistVal then
        target.btnTogglePersist:enableAcceptColor()
    else
        target.btnTogglePersist:enableCancelColor()
    end
end

function DCS_SettingsPanel_Window.onToggleLimit(target)
    target._limitVal = not target._limitVal
    target.btnToggleLimit:setTitle(target._limitVal and getText("IGUI_DCS_Debug_SettingsOn") or getText("IGUI_DCS_Debug_SettingsOff"))
    if target._limitVal then
        target.btnToggleLimit:enableAcceptColor()
    else
        target.btnToggleLimit:enableCancelColor()
    end
end

function DCS_SettingsPanel_Window.onToggleChallengeProgress(target)
    target._challengeProgressVal = not target._challengeProgressVal
    target.btnToggleChallengeProgress:setTitle(target._challengeProgressVal and getText("IGUI_DCS_Debug_SettingsOn") or getText("IGUI_DCS_Debug_SettingsOff"))
    if target._challengeProgressVal then
        target.btnToggleChallengeProgress:enableAcceptColor()
    else
        target.btnToggleChallengeProgress:enableCancelColor()
    end
end

function DCS_SettingsPanel_Window.onSave(target)
    local player = getPlayer()
    if player then
        sendClientCommand(player, "DailyChallengeSystem", "applyDCSSettings", {
            tokensPersistDeath = target._persistVal,
            limitShopItems = target._limitVal,
            challengeProgressPersistDeath = target._challengeProgressVal or false,
        })
    end
    DCS_dprint("[DCS] DCS Settings save: TokensPersistDeath=" .. tostring(target._persistVal)
        .. " LimitShopItems=" .. tostring(target._limitVal)
        .. " ChallengeProgressPersistDeath=" .. tostring(target._challengeProgressVal))
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_SettingsSaved"), "debug")
    target:close()
end

function DCS_SettingsPanel_Window.onClose(target)
    target:setVisible(false)
    target:removeFromUIManager()
    DCS_SettingsPanel.instance = nil
    if DCS_UI_Debug.instance then
        DCS_UI_Debug.instance:setVisible(true)
    end
end

function DCS_SettingsPanel_Window:prerender()
    ISCollapsableWindow.prerender(self)
end

function DCS_SettingsPanel.open()
    if DCS_SettingsPanel.instance then
        DCS_SettingsPanel.instance:setVisible(true)
        return
    end

    local win = DCS_SettingsPanel_Window:new(0, 0)
    win:initialise()
    win:instantiate()
    win:setTitle(getText("IGUI_DCS_Debug_DCSSettingsTitle"))

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    win:setX(math.floor((screenW - win.width) / 2))
    win:setY(math.floor((screenH - win.height) / 2))

    win:addToUIManager()
    win:setVisible(true)

    DCS_SettingsPanel.instance = win
end

function DCS_Debug_Window:onDCSSettings()
    DCS_SettingsPanel.open()
end

function DCS_Debug_Window:onResetAll()
    DCS_UserReset.open("resetAll")
end

function DCS_Debug_Window:onSelectChallenge()
    DCS_DebugChallengePicker.open()
end

function DCS_Debug_Window:onGrantAdmin()
    if DCS_Env and DCS_Env.isSP() then return end
    local player = getSpecificPlayer(0)
    if not player then return end
    local username = player:getUsername()
    DCS_dprint("[DCS] Debug BUTTON: Grant Admin pressed by " .. username)
    SendCommandToServer('/setaccesslevel "' .. username .. '" admin')
    sendClientCommand(player, "DailyChallengeSystem", "debugCmd", {
        action = "grantAdmin"
    })
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_AdminGranted"), "debug")
    adminGranted = true
    local px, py = self:getX(), self:getY()
    DCS_UI_Debug.close()
    DCS_UI_Debug.instance = nil
    local win = DCS_Debug_Window:new(px, py)
    win:initialise()
    win:instantiate()
    win:addToUIManager()
    win:setTitle(getText("IGUI_DCS_Debug_Title"))
    DCS_UI_Debug.instance = win
end

function DCS_Debug_Window:onTeleport()
    DCS_TeleportPicker.open()
end

function DCS_Debug_Window:onToggleCheats()
    if not hasAdminAccess() then
        DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_NeedAdmin"), "debug")
        return
    end
    local player = getSpecificPlayer(0)
    if not player then return end

    local currentlyOn = player:isUnlimitedAmmo()
    local newState = not currentlyOn

    player:setFastMoveCheat(newState)
    ISFastTeleportMove.cheat = newState
    player:setUnlimitedAmmo(newState)
    player:setBuildCheat(newState)
    ISBuildMenu.cheat = newState
    player:setAnimalCheat(newState)
    getCore():setAnimalCheat(newState)
    player:setFishingCheat(newState)
    player:setMechanicsCheat(newState)
    ISVehicleMechanics.cheat = newState

    local label = newState and "ON" or "OFF"
    DCS_dprint("[DCS] Debug: Testing cheats toggled " .. label .. " by " .. tostring(player:getUsername()))
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_CheatsToggled", label), "debug")
end

function DCS_Debug_Window:onOpenShop()
    DCS_UI_Shop.open("east")
end

function DCS_Debug_Window:onOpenShopWest()
    DCS_UI_Shop.open("west")
end

function DCS_Debug_Window:onEditShop()
    DCS_UI_ShopAdmin.open()
end

function DCS_Debug_Window:onBackup()
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local modal = ISModalDialog:new(
        screenW / 2 - S(175), screenH / 2 - S(75), S(350), S(150),
        getText("IGUI_DCS_Debug_ConfirmBackup"),
        true, self, DCS_Debug_Window.onBackupConfirm)
    modal:initialise()
    modal:addToUIManager()
end

function DCS_Debug_Window:onBackupConfirm(button)
    if button.internal == "NO" then return end
    local player = getSpecificPlayer(0)
    if not player then return end
    DCS_dprint("[DCS] Admin BUTTON: Backup DCS Data pressed by " .. tostring(player:getUsername()))
    sendClientCommand(player, "DailyChallengeSystem", "backupDCS", {})
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_BackingUp"), "debug")
end

function DCS_Debug_Window:onRestore()
    DCS_BackupPicker.open()
end

function DCS_Debug_Window:onHelp()
    DCS_UI_HelpWindow.open(getText("IGUI_DCS_Debug_Title"), {
        getText("IGUI_DCS_Debug_Title"),
        "",
        getText("IGUI_DCS_Debug_HelpDescription"),
        "",
        getText("IGUI_DCS_Debug_HelpSectionAdminTools"),
        "",
        getText("IGUI_DCS_Debug_HelpResetAll"),
        "",
        getText("IGUI_DCS_Debug_HelpClearTokens"),
        "",
        getText("IGUI_DCS_Debug_HelpClearProgress"),
        "",
        getText("IGUI_DCS_Debug_HelpOfflinePlayers"),
        "",
        getText("IGUI_DCS_Debug_HelpOfflineLeaderboard"),
        "",
        getText("IGUI_DCS_Debug_HelpResetLeaderboard"),
        "",
        getText("IGUI_DCS_Debug_HelpRemoveFromLeaderboard"),
        "",
        getText("IGUI_DCS_Debug_HelpOpenVendor"),
        "",
        getText("IGUI_DCS_Debug_HelpEditShop"),
        "",
        getText("IGUI_DCS_Debug_HelpBackup"),
        "",
        getText("IGUI_DCS_Debug_HelpLoadBackup"),
    })
end

function DCS_Debug_Window:onAddToken()
    local player = getSpecificPlayer(0)
    if not player then return end
    sendClientCommand(player, "DailyChallengeSystem", "debugCmd", {
        action = "addToken",
        amount = 1,
    })
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_PlusOneToken"), "debug")
end

function DCS_Debug_Window:onCompleteAndNext()
    local player = getSpecificPlayer(0)
    if not player then return end
    DCS_dprint("[DCS] Debug BUTTON: Complete Challenge + Force Next Day pressed by " .. tostring(player:getUsername()))
    sendClientCommand(player, "DailyChallengeSystem", "debugCmd", {
        action = "completeAndNext"
    })
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_CompleteAndNext"), "debug")
end

function DCS_Debug_Window:onCompleteAll()
    local player = getSpecificPlayer(0)
    if not player then return end
    DCS_dprint("[DCS] Debug BUTTON: Complete All 7 Challenges pressed by " .. tostring(player:getUsername()))
    sendClientCommand(player, "DailyChallengeSystem", "debugCmd", {
        action = "completeAllChallenges"
    })
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_CompletingAll"), "debug")
end

function DCS_Debug_Window:onTeleportTraders()
    local player = getSpecificPlayer(0)
    if not player then return end
    local traderLocations = DCS_Sync and DCS_Sync.State and DCS_Sync.State.traderLocations
    if not traderLocations or (not traderLocations.east and not traderLocations.west) then
        DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_VendorsNotSynced"), "debug")
        return
    end
    local loc
    if lastTraderSide == "east" then
        loc = traderLocations.west or traderLocations.east
        lastTraderSide = "west"
    else
        loc = traderLocations.east or traderLocations.west
        lastTraderSide = "east"
    end
    if not loc then
        DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_NoTraderFound"), "debug")
        return
    end
    player:teleportTo(loc.x, loc.y, 0)
    DCS_dprint("[DCS] Teleported to " .. loc.name .. " (" .. loc.x .. "," .. loc.y .. ")")
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_Teleported", loc.name), "debug")
end

local lastQuestSide = nil

function DCS_Debug_Window:onTeleportQuest()
    local player = getSpecificPlayer(0)
    if not player then return end

    local challenges = DCS_Sync.getTodayChallenges and DCS_Sync.getTodayChallenges() or {}
    if #challenges == 0 then
        DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_ChallengesNotLoaded"), "debug")
        return
    end

    local questLocations = {}
    for _, ch in ipairs(challenges) do
        if ch.type == "visitLocation" and ch.x and ch.y then
            questLocations[#questLocations + 1] = {
                x = ch.x,
                y = ch.y,
                name = ch.title or ch.locName or ch.id,
                type = ch.type,
            }
        elseif ch.type == "questDeliver" and ch.destX and ch.destY then
            questLocations[#questLocations + 1] = {
                x = ch.destX,
                y = ch.destY,
                name = ch.title or ch.destName or ch.id,
                type = ch.type,
            }
        end
    end

    if #questLocations == 0 then
        DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_NoQuestLocations"), "debug")
        return
    end

    local loc
    if lastQuestSide == "east" and #questLocations >= 2 then
        loc = questLocations[2]
        lastQuestSide = "west"
    else
        loc = questLocations[1]
        lastQuestSide = "east"
    end
    if not loc then
        DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_NoQuestLocations"), "debug")
        return
    end
    player:teleportTo(loc.x, loc.y, 0)
    DCS_dprint("[DCS] Teleported to " .. loc.name .. " (" .. loc.x .. "," .. loc.y .. ")")
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_Teleported", loc.name), "debug")
end

function DCS_Debug_Window:close()
    DCS_Sync.saveWindowPos("debug", self:getX(), self:getY())
    self:setVisible(false)
    self:removeFromUIManager()
    DCS_UI_Debug.instance = nil
end

function DCS_UI_Debug.open()
    if not hasDebugAccess() then
        print("[DCS] Debug panel: access denied")
        return
    end

    if DCS_UI_Debug.instance then
        DCS_UI_Debug.instance:setVisible(true)
        return
    end

    local screenW = getPlayerScreenWidth(0)
    local screenH = getPlayerScreenHeight(0)

    local x, y = DCS_Sync.getWindowPos("debug",
        math.floor((screenW - DBG_W) / 2), math.floor((screenH - DBG_H) / 2))
    x = math.max(0, math.min(x, screenW - DBG_W))
    y = math.max(0, math.min(y, screenH - DBG_H))

    local win = DCS_Debug_Window:new(x, y)
    win:initialise()
    win:instantiate()
    win:addToUIManager()
    win:setTitle(getText("IGUI_DCS_Debug_Title"))
    DCS_UI_Debug.instance = win
end

function DCS_UI_Debug.close()
    if DCS_UI_Debug.instance then
        DCS_UI_Debug.instance:close()
    end
end

function DCS_UI_Debug.toggle()
    if DCS_UI_Debug.instance and DCS_UI_Debug.instance:getIsVisible() then
        DCS_UI_Debug.close()
    else
        DCS_UI_Debug.open()
    end
end

DCS_DebugChallengePicker = {}
DCS_DebugChallengePicker.instance = nil

local PICKER_W = math.max(S(320), fontHgt * 17)
local PICKER_H = S(520)
local CATEGORY_NAMES = {
    [1] = getText("IGUI_DCS_Debug_Category_Kill"),
    [2] = getText("IGUI_DCS_Debug_Category_Quest"),
    [3] = getText("IGUI_DCS_Debug_Category_Visit"),
    [4] = getText("IGUI_DCS_Debug_Category_EatDrink"),
    [5] = getText("IGUI_DCS_Debug_Category_FishHunt"),
    [6] = getText("IGUI_DCS_Debug_Category_Craft"),
    [7] = getText("IGUI_DCS_Debug_Category_Misc"),
}

DCS_ChallengePicker_Window = ISCollapsableWindow:derive("DCS_ChallengePicker_Window")

function DCS_ChallengePicker_Window:new(x, y)
    local o = ISCollapsableWindow.new(self, x, y, PICKER_W, PICKER_H)
    o.moveWithMouse = true
    o.resizable = false
    return o
end

function DCS_ChallengePicker_Window:createChildren()
    ISCollapsableWindow.createChildren(self)

    local titleH = fontHgt + S(1)
    local y = titleH + PAD

    self.lblInfo = ISLabel:new(PAD, y, S(20), getText("IGUI_DCS_Debug_PickerInstruction"), COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, 1, FONT, true)
    self.lblInfo:initialise()
    self:addChild(self.lblInfo)
    y = y + S(24)

    local listH = PICKER_H - titleH - PAD - S(24) - S(24) - BTN_H - PAD - S(20)
    self.challengeList = ISScrollingListBox:new(PAD, y, BTN_W, listH)
    self.challengeList:initialise()
    self.challengeList:instantiate()
    self.challengeList.doDrawItem = DCS_ChallengePicker_Window.drawChallengeItem
    self.challengeList:setOnMouseDownFunction(self, DCS_ChallengePicker_Window.onChallengeSelected)
    self.challengeList.selected = 0
    self:addChild(self.challengeList)
    y = y + listH + S(8)

    self.selectedChallenge = nil
    self.selectedSlot = nil
    self:buildChallengeList()

    self.lblSlot = ISLabel:new(PAD, y, S(20), getText("IGUI_DCS_Debug_PickerNoSelected"), COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, 1, FONT, true)
    self.lblSlot:initialise()
    self:addChild(self.lblSlot)
    y = y + S(24)

    self.btnConfirm = ISButton:new(PAD, y, BTN_W, BTN_H,
        getText("IGUI_DCS_Debug_ReplaceSlot"), self, DCS_ChallengePicker_Window.onConfirm)
    self.btnConfirm:initialise()
    self.btnConfirm:instantiate()
    self.btnConfirm.enable = false
    self:addChild(self.btnConfirm)
end

function DCS_ChallengePicker_Window:initialise()
    ISCollapsableWindow.initialise(self)
end

function DCS_ChallengePicker_Window:buildChallengeList()
    self.challengeList:clear()
    self.selectedChallenge = nil
    self.selectedSlot = nil
    if self.btnConfirm then self.btnConfirm.enable = false end
    if self.lblSlot then self.lblSlot:setName(getText("IGUI_DCS_Debug_PickerNoSelected")) end

    for catIndex, pool in ipairs(DCS_Challenges.CategoryPools) do
        if pool and #pool > 0 then
            local catName = CATEGORY_NAMES[catIndex] or ("Category " .. catIndex)
            self.challengeList:addItem("── " .. catName .. " ──", { isHeader = true, catIndex = catIndex })
            for _, ch in ipairs(pool) do
                self.challengeList:addItem(ch.title or ch.id, {
                    isHeader = false,
                    challenge = ch,
                    catIndex = catIndex,
                    catName = catName,
                })
            end
        end
    end
end

function DCS_ChallengePicker_Window:drawChallengeItem(y, item, alt)
    local data = item.item
    if data.isHeader then
        self:drawRect(0, y, self.width, S(20), 0.3, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
        self:drawText(data.text, S(8), y + S(2), COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 1, FONT)
        return y + S(20)
    end
    local highlight = (self.selected == item.index)
    if highlight then
        self:drawRect(0, y, self.width, S(20), 0.3, 0.2, 0.4, 0.6)
    end
    local label = "  " .. (data.challenge and (data.challenge.title or data.challenge.id) or data.text or "???")
    self:drawText(label, S(8), y + S(2),
        COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, highlight and 1 or 0.8, FONT)
    return y + S(20)
end

function DCS_ChallengePicker_Window.onChallengeSelected(target, data)
    if data.isHeader then return end
    target.selectedChallenge = data.challenge
    target.selectedSlot = data.catIndex
    local catName = data.catName or ("Slot " .. data.catIndex)
    if target.lblSlot then
        target.lblSlot:setName(getText("IGUI_DCS_Debug_PickerWillReplace", data.catIndex, catName))
    end
    if target.btnConfirm then
        target.btnConfirm.enable = true
        target.btnConfirm:setTitle(getText("IGUI_DCS_Debug_ReplaceSlot") .. " " .. data.catIndex .. " (" .. catName .. ")")
    end
end

function DCS_ChallengePicker_Window:onConfirm()
    if not self.selectedChallenge or not self.selectedSlot then return end
    local player = getSpecificPlayer(0)
    if not player then return end
    DCS_dprint("[DCS] Debug BUTTON: Force Challenge pressed by " .. tostring(player:getUsername()) ..
          " → slot " .. self.selectedSlot .. " challenge " .. self.selectedChallenge.id)
    sendClientCommand(player, "DailyChallengeSystem", "debugCmd", {
        action = "forceChallenge",
        challengeId = self.selectedChallenge.id,
        slot = self.selectedSlot,
    })
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_ReplacedSlot", self.selectedSlot, self.selectedChallenge.title or self.selectedChallenge.id), "debug")
    self.selectedChallenge = nil
    self.selectedSlot = nil
    self.challengeList.selected = 0
    if self.lblSlot then self.lblSlot:setName(getText("IGUI_DCS_Debug_PickerNoSelected")) end
    if self.btnConfirm then
        self.btnConfirm.enable = false
        self.btnConfirm:setTitle(getText("IGUI_DCS_Debug_ReplaceSlot"))
    end
end

function DCS_ChallengePicker_Window:prerender()
    ISCollapsableWindow.prerender(self)
    local titleH = fontHgt + S(1)
    self:drawRect(0, titleH, self.width, S(2), 1, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
end

function DCS_ChallengePicker_Window:close()
    DCS_Sync.saveWindowPos("picker", self:getX(), self:getY())
    self:setVisible(false)
    self:removeFromUIManager()
    DCS_DebugChallengePicker.instance = nil
end

function DCS_DebugChallengePicker.open()
    if not hasDebugAccess() then
        print("[DCS] Challenge picker: access denied")
        return
    end
    if DCS_DebugChallengePicker.instance then
        DCS_DebugChallengePicker.instance:setVisible(true)
        return
    end
    local screenW = getPlayerScreenWidth(0)
    local screenH = getPlayerScreenHeight(0)

    local x, y = DCS_Sync.getWindowPos("picker",
        math.floor((screenW - PICKER_W) / 2), math.floor((screenH - PICKER_H) / 2))
    x = math.max(0, math.min(x, screenW - PICKER_W))
    y = math.max(0, math.min(y, screenH - PICKER_H))

    local win = DCS_ChallengePicker_Window:new(x, y)
    win:initialise()
    win:instantiate()
    win:addToUIManager()
    win:setTitle(getText("IGUI_DCS_Debug_PickerTitle"))
    DCS_DebugChallengePicker.instance = win
end

function DCS_DebugChallengePicker.close()
    if DCS_DebugChallengePicker.instance then
        DCS_DebugChallengePicker.instance:close()
    end
end

DCS_TeleportPicker = {}
DCS_TeleportPicker.instance = nil

local TPICKER_W = S(480)
local TPICKER_H = S(520)

DCS_TeleportPicker_Window = ISCollapsableWindow:derive("DCS_TeleportPicker_Window")

function DCS_TeleportPicker_Window:new(x, y)
    local o = ISCollapsableWindow.new(self, x, y, TPICKER_W, TPICKER_H)
    o.moveWithMouse = true
    o.resizable = false
    return o
end

function DCS_TeleportPicker_Window:createChildren()
    ISCollapsableWindow.createChildren(self)

    local titleH = fontHgt + S(1)
    local y = titleH + PAD

    self.lblInfo = ISLabel:new(PAD, y, S(20), getText("IGUI_DCS_Debug_TeleportInstruction"), COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, 1, FONT, true)
    self.lblInfo:initialise()
    self:addChild(self.lblInfo)
    y = y + S(24)

    local listH = TPICKER_H - titleH - PAD - S(24) - S(24) - BTN_H - PAD - S(20)
    self.locationList = ISScrollingListBox:new(PAD, y, TPICKER_W - PAD * 2, listH)
    self.locationList:initialise()
    self.locationList:instantiate()
    self.locationList.doDrawItem = DCS_TeleportPicker_Window.drawLocationItem
    self.locationList:setOnMouseDownFunction(self, DCS_TeleportPicker_Window.onLocationSelected)
    self.locationList.selected = 0
    self:addChild(self.locationList)
    y = y + listH + S(8)

    self.selectedLocation = nil
    self:buildLocationList()

    self.lblPreview = ISLabel:new(PAD, y, S(20),"No location selected", COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, 1, FONT, true)
    self.lblPreview:initialise()
    self:addChild(self.lblPreview)
    y = y + S(24)

    self.btnTeleport = ISButton:new(PAD, y, TPICKER_W - PAD * 2, BTN_H,
        getText("IGUI_DCS_Debug_Teleport"), self, DCS_TeleportPicker_Window.onTeleport)
    self.btnTeleport:initialise()
    self.btnTeleport:instantiate()
    self.btnTeleport.enable = false
    self:addChild(self.btnTeleport)
end

function DCS_TeleportPicker_Window:initialise()
    ISCollapsableWindow.initialise(self)
end

function DCS_TeleportPicker_Window:buildLocationList()
    self.locationList:clear()
    self.selectedLocation = nil
    if self.btnTeleport then self.btnTeleport.enable = false end
    if self.lblPreview then self.lblPreview:setName("No location selected") end

    local regions = {}
    for _, loc in ipairs(DCS_Challenges.Locations) do
        local region = getText("IGUI_DCS_Debug_Region_Other")
        local id = loc.id or ""
        if id:find("louisville_airport") then
            region = getText("IGUI_DCS_Debug_Region_LouisvilleAirport")
        elseif id:find("louisville") then
            region = getText("IGUI_DCS_Debug_Region_Louisville")
        elseif id:find("valley_station") then
            region = getText("IGUI_DCS_Debug_Region_ValleyStation")
        elseif id:find("west_point") or id:find("westpoint") then
            region = getText("IGUI_DCS_Debug_Region_WestPoint")
        elseif id:find("muldraugh") then
            region = getText("IGUI_DCS_Debug_Region_Muldraugh")
        elseif id:find("march_ridge") then
            region = getText("IGUI_DCS_Debug_Region_MarchRidge")
        elseif id:find("rosewood") then
            region = getText("IGUI_DCS_Debug_Region_Rosewood")
        elseif id:find("fallas_lake") then
            region = getText("IGUI_DCS_Debug_Region_FallasLake")
        elseif id:find("riverside") then
            region = getText("IGUI_DCS_Debug_Region_Riverside")
        elseif id:find("brandenburg") then
            region = getText("IGUI_DCS_Debug_Region_Brandenburg")
        elseif id:find("ekron") then
            region = getText("IGUI_DCS_Debug_Region_Ekron")
        elseif id:find("echo_creek") then
            region = getText("IGUI_DCS_Debug_Region_EchoCreek")
        elseif id:find("irvington") then
            region = getText("IGUI_DCS_Debug_Region_Irvington")
        elseif id:find("misc") then
            region = getText("IGUI_DCS_Debug_Region_Misc")
        end

        if not regions[region] then
            regions[region] = {}
        end
        regions[region][#regions[region] + 1] = loc
    end

    local regionOrder = {
        getText("IGUI_DCS_Debug_Region_Louisville"), getText("IGUI_DCS_Debug_Region_LouisvilleAirport"), getText("IGUI_DCS_Debug_Region_ValleyStation"), getText("IGUI_DCS_Debug_Region_WestPoint"),
        getText("IGUI_DCS_Debug_Region_Muldraugh"), getText("IGUI_DCS_Debug_Region_MarchRidge"), getText("IGUI_DCS_Debug_Region_Rosewood"), getText("IGUI_DCS_Debug_Region_FallasLake"),
        getText("IGUI_DCS_Debug_Region_Riverside"), getText("IGUI_DCS_Debug_Region_Brandenburg"), getText("IGUI_DCS_Debug_Region_Ekron"), getText("IGUI_DCS_Debug_Region_EchoCreek"),
        getText("IGUI_DCS_Debug_Region_Irvington"), getText("IGUI_DCS_Debug_Region_Misc"), getText("IGUI_DCS_Debug_Region_Other")
    }

    for _, regionName in ipairs(regionOrder) do
        local locs = regions[regionName]
        if locs and #locs > 0 then
            self.locationList:addItem("── " .. regionName .. " ──", { isHeader = true })
            for _, loc in ipairs(locs) do
                self.locationList:addItem(loc.name, {
                    isHeader = false,
                    location = loc,
                    region = regionName,
                })
            end
        end
    end
end

function DCS_TeleportPicker_Window:drawLocationItem(y, item, alt)
    local data = item.item
    if data.isHeader then
        self:drawRect(0, y, self.width, S(20), 0.3, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
        self:drawText(data.text, S(8), y + S(2), COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 1, FONT)
        return y + S(20)
    end
    local highlight = (self.selected == item.index)
    if highlight then
        self:drawRect(0, y, self.width, S(20), 0.3, 0.2, 0.4, 0.6)
    end
    self:drawText("  " .. data.location.name, S(8), y + S(2),
        COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, highlight and 1 or 0.8, FONT)
    return y + S(20)
end

function DCS_TeleportPicker_Window.onLocationSelected(target, data)
    if data.isHeader then return end
    target.selectedLocation = data.location
    if target.lblPreview then
        target.lblPreview:setName(data.location.name .. " (" .. data.location.x .. ", " .. data.location.y .. ")")
    end
    if target.btnTeleport then
        target.btnTeleport.enable = true
    end
end

function DCS_TeleportPicker_Window.onTeleport(target)
    if not target.selectedLocation then return end
    local player = getSpecificPlayer(0)
    if not player then
        DCS_dprint("[DCS] No player found")
        return
    end

    local loc = target.selectedLocation
    player:teleportTo(loc.x, loc.y, 0)

    DCS_dprint("[DCS] Teleported to: " .. loc.name .. " (" .. loc.x .. ", " .. loc.y .. ")")
end

function DCS_TeleportPicker_Window:prerender()
    ISCollapsableWindow.prerender(self)
    local titleH = fontHgt + S(1)
    self:drawRect(0, titleH, self.width, S(2), 1, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
end

function DCS_TeleportPicker_Window:close()
    DCS_Sync.saveWindowPos("teleport", self:getX(), self:getY())
    self:setVisible(false)
    self:removeFromUIManager()
    DCS_TeleportPicker.instance = nil
end

function DCS_TeleportPicker.open()
    if not hasDebugAccess() then
        print("[DCS] Teleport picker: access denied")
        return
    end
    if DCS_TeleportPicker.instance then
        DCS_TeleportPicker.instance:setVisible(true)
        return
    end
    local screenW = getPlayerScreenWidth(0)
    local screenH = getPlayerScreenHeight(0)

    local x, y = DCS_Sync.getWindowPos("teleport",
        math.floor((screenW - TPICKER_W) / 2), math.floor((screenH - TPICKER_H) / 2))
    x = math.max(0, math.min(x, screenW - TPICKER_W))
    y = math.max(0, math.min(y, screenH - TPICKER_H))

    local win = DCS_TeleportPicker_Window:new(x, y)
    win:initialise()
    win:instantiate()
    win:addToUIManager()
    win:setTitle(getText("IGUI_DCS_Debug_TeleportTitle"))
    DCS_TeleportPicker.instance = win
end

function DCS_TeleportPicker.close()
    if DCS_TeleportPicker.instance then
        DCS_TeleportPicker.instance:close()
    end
end

DCS_BackupPicker = {}
DCS_BackupPicker.instance = nil

local BPICKER_W = S(480)
local BPICKER_H = S(420)

DCS_BackupPicker_Window = ISCollapsableWindow:derive("DCS_BackupPicker_Window")

function DCS_BackupPicker_Window:new(x, y)
    local o = ISCollapsableWindow.new(self, x, y, BPICKER_W, BPICKER_H)
    o.moveWithMouse = true
    o.resizable = false
    return o
end

function DCS_BackupPicker_Window:createChildren()
    ISCollapsableWindow.createChildren(self)

    local titleH = fontHgt + S(1)
    local y = titleH + PAD

    self.lblInfo = ISLabel:new(PAD, y, S(20), getText("IGUI_DCS_Debug_BackupInstruction"), COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, 1, FONT, true)
    self.lblInfo:initialise()
    self:addChild(self.lblInfo)
    y = y + S(24)

    local listH = BPICKER_H - titleH - PAD - S(24) - S(24) - BTN_H - PAD - S(20)
    self.fileList = ISScrollingListBox:new(PAD, y, BPICKER_W - PAD * 2, listH)
    self.fileList:initialise()
    self.fileList:instantiate()
    self.fileList.itemheight = fontHgt + S(9)
    self.fileList.selected = 0
    self.fileList.drawBorder = true
    self.fileList.doDrawItem = DCS_BackupPicker_Window.drawFileItem
    self.fileList:setOnMouseDownFunction(self, DCS_BackupPicker_Window.onFileSelected)
    self:addChild(self.fileList)
    y = y + listH + S(8)

    self.lblPreview = ISLabel:new(PAD, y, S(20), getText("IGUI_DCS_Debug_BackupNoSelected") or "No backup selected", COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, 1, FONT, true)
    self.lblPreview:initialise()
    self:addChild(self.lblPreview)
    y = y + S(24)

    self.btnLoad = ISButton:new(PAD, y, BPICKER_W - PAD * 2, BTN_H,
        getText("IGUI_DCS_Debug_Load"), self, DCS_BackupPicker_Window.onLoad)
    self.btnLoad:initialise()
    self.btnLoad:instantiate()
    self.btnLoad.enable = false
    self:addChild(self.btnLoad)

    self.selectedFile = nil
    self:refreshList()
end

function DCS_BackupPicker_Window:initialise()
    ISCollapsableWindow.initialise(self)
end

function DCS_BackupPicker_Window:refreshList()
    self.fileList:clear()
    self.selectedFile = nil
    if self.btnLoad then self.btnLoad.enable = false end
    if self.lblPreview then self.lblPreview:setName(getText("IGUI_DCS_Debug_BackupNoSelected") or "No backup selected") end
    local player = getSpecificPlayer(0)
    if player then
        sendClientCommand(player, "DailyChallengeSystem", "listBackups", {})
    end
end

function DCS_BackupPicker_Window:populateList(backups)
    self.fileList:clear()
    self.selectedFile = nil
    if self.btnLoad then self.btnLoad.enable = false end
    if self.lblPreview then self.lblPreview:setName(getText("IGUI_DCS_Debug_BackupNoSelected") or "No backup selected") end

    if not backups or #backups == 0 then
        if self.lblInfo then self.lblInfo:setName(getText("IGUI_DCS_Debug_BackupNoneFound")) end
        return
    end
    self.lblInfo:setName(getText("IGUI_DCS_Debug_BackupInstruction"))

    local autoSave = nil
    local manual = {}
    for _, entry in ipairs(backups) do
        if entry.filename:find("auto_backup") then
            autoSave = entry
        else
            manual[#manual + 1] = entry
        end
    end

    if autoSave then
        self.fileList:addItem(getText("IGUI_DCS_Debug_BackupAutoSave"), { filename = autoSave.filename, timestamp = autoSave.timestamp, isAuto = true })
    end

    for _, entry in ipairs(manual) do
        self.fileList:addItem(entry.filename, { filename = entry.filename, timestamp = entry.timestamp })
    end
end

function DCS_BackupPicker_Window:drawFileItem(y, item, alt)
    local data = item.item
    if not data then return y + fontHgt + S(9) end
    local isAuto = data.isAuto
    local label = isAuto and getText("IGUI_DCS_Debug_BackupAutoSave") or (item.name or data.filename or "?")
    local h = self.itemheight or (fontHgt + S(9))
    local w = self:getWidth()

    self:drawRect(0, y, w, h, 1, 0.08, 0.08, 0.08)

    if self.selected == item.index then
        self:drawRect(0, y, w, h, 0.3, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
    end

    if isAuto then
        self:drawText(label, S(8), y + S(6), COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 1, UIFont.Small)
    else
        self:drawText(label, S(8), y + S(6), 1, 1, 1, 1, UIFont.Small)
    end

    return y + h
end

function DCS_BackupPicker_Window.onFileSelected(target, data)
    if not data or not data.filename then return end
    target.selectedFile = data.filename
    if target.btnLoad then target.btnLoad.enable = true end
    if target.lblPreview then target.lblPreview:setName(data.filename) end
end

function DCS_BackupPicker_Window.onLoad(target)
    if not target.selectedFile then return end
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local modal = ISModalDialog:new(
        screenW / 2 - S(175), screenH / 2 - S(75), S(350), S(150),
        getText("IGUI_DCS_Debug_ConfirmLoadBackup"),
        true, target, DCS_BackupPicker_Window.onLoadConfirm)
    modal:initialise()
    modal:addToUIManager()
end

function DCS_BackupPicker_Window.onLoadConfirm(target, button)
    if button.internal == "NO" then return end
    if not target.selectedFile then return end
    local player = getSpecificPlayer(0)
    if not player then return end
    DCS_dprint("[DCS] Admin: Load DCS Data from Backup — " .. target.selectedFile)
    sendClientCommand(player, "DailyChallengeSystem", "restoreDCS", { filename = target.selectedFile })
    local displayPath = target.selectedFile:gsub("/([^/]+)$", " %1")
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_RestoringFrom", displayPath), "debug")
    target:close()
end

function DCS_BackupPicker_Window:prerender()
    ISCollapsableWindow.prerender(self)
end

function DCS_BackupPicker_Window:close()
    DCS_Sync.saveWindowPos("backuppicker", self:getX(), self:getY())
    ISCollapsableWindow.close(self)
    if DCS_UI_Debug.instance then
        DCS_UI_Debug.instance:setVisible(true)
    end
end

function DCS_BackupPicker.open()
    local player = getSpecificPlayer(0)
    if not player then return end

    if DCS_BackupPicker.instance then
        DCS_BackupPicker.instance:setVisible(true)
        DCS_BackupPicker.instance:refreshList()
        return
    end

    local screenW = getPlayerScreenWidth(0)
    local screenH = getPlayerScreenHeight(0)
    local x, y = DCS_Sync.getWindowPos("backuppicker",
        math.floor((screenW - BPICKER_W) / 2), math.floor((screenH - BPICKER_H) / 2))
    x = math.max(0, math.min(x, screenW - BPICKER_W))
    y = math.max(0, math.min(y, screenH - BPICKER_H))

    local win = DCS_BackupPicker_Window:new(x, y)
    win:initialise()
    win:instantiate()
    win:setTitle(getText("IGUI_DCS_Debug_BackupTitle"))
    win:addToUIManager()
    win:setVisible(true)

    DCS_BackupPicker.instance = win
end

function DCS_BackupPicker.close()
    if DCS_BackupPicker.instance then
        DCS_BackupPicker.instance:close()
    end
end

function DCS_BackupPicker.onBackupList(backups)
    DCS_dprint("[DCS] DCS_BackupPicker.onBackupList: Called with " .. tostring(backups and #backups or "nil") .. " backups")
    if DCS_BackupPicker.instance then
        DCS_dprint("[DCS] DCS_BackupPicker.onBackupList: Instance exists, calling populateList")
        DCS_BackupPicker.instance:populateList(backups)
    else
        DCS_dprint("[DCS] DCS_BackupPicker.onBackupList: Instance is nil!")
    end
end

DCS_LeaderboardRemovePicker = {}
DCS_LeaderboardRemovePicker.instance = nil

local LBRPICKER_W = S(480)
local LBRPICKER_H = S(420)

DCS_LeaderboardRemovePicker_Window = ISCollapsableWindow:derive("DCS_LeaderboardRemovePicker_Window")

local function collectLeaderboardNames()
    local names = {}
    local seen = {}
    local lb = DCS_Sync and DCS_Sync.State and DCS_Sync.State.leaderboard
    if type(lb) ~= "table" then return names end
    local keys = { "mostCompleted", "highestStreak", "currentStreak", "mostTokens", "speedrun1", "speedrun7" }
    for _, k in ipairs(keys) do
        local arr = lb[k]
        if type(arr) == "table" then
            for _, entry in ipairs(arr) do
                local n = entry and entry.name
                if n and n ~= "" and not seen[n] then
                    seen[n] = true
                    names[#names + 1] = n
                end
            end
        end
    end
    table.sort(names, function(a, b) return string.lower(a) < string.lower(b) end)
    return names
end

function DCS_LeaderboardRemovePicker_Window:new(x, y)
    local o = ISCollapsableWindow.new(self, x, y, LBRPICKER_W, LBRPICKER_H)
    o.moveWithMouse = true
    o.resizable = false
    return o
end

function DCS_LeaderboardRemovePicker_Window:createChildren()
    ISCollapsableWindow.createChildren(self)

    local titleH = fontHgt + S(1)
    local y = titleH + PAD

    self.lblInfo = ISLabel:new(PAD, y, S(20), getText("IGUI_DCS_Debug_RemoveLBInstruction"), COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, 1, FONT, true)
    self.lblInfo:initialise()
    self:addChild(self.lblInfo)
    y = y + S(24)

    local listH = LBRPICKER_H - titleH - PAD - S(24) - S(24) - BTN_H - PAD - S(20)
    self.nameList = ISScrollingListBox:new(PAD, y, LBRPICKER_W - PAD * 2, listH)
    self.nameList:initialise()
    self.nameList:instantiate()
    self.nameList.itemheight = fontHgt + S(9)
    self.nameList.selected = 0
    self.nameList.drawBorder = true
    self.nameList.doDrawItem = DCS_LeaderboardRemovePicker_Window.drawNameItem
    self.nameList:setOnMouseDownFunction(self, DCS_LeaderboardRemovePicker_Window.onNameSelected)
    self:addChild(self.nameList)
    y = y + listH + S(8)

    self.lblPreview = ISLabel:new(PAD, y, S(20), getText("IGUI_DCS_Debug_RemoveLBNoSelected"), COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, 1, FONT, true)
    self.lblPreview:initialise()
    self:addChild(self.lblPreview)
    y = y + S(24)

    self.btnRemove = ISButton:new(PAD, y, LBRPICKER_W - PAD * 2, BTN_H,
        getText("IGUI_DCS_Debug_Remove"), self, DCS_LeaderboardRemovePicker_Window.onRemove)
    self.btnRemove:initialise()
    self.btnRemove:instantiate()
    self.btnRemove.enable = false
    self:addChild(self.btnRemove)

    self.selectedName = nil
    self:refreshList()
end

function DCS_LeaderboardRemovePicker_Window:initialise()
    ISCollapsableWindow.initialise(self)
end

function DCS_LeaderboardRemovePicker_Window:refreshList()
    self.nameList:clear()
    self.selectedName = nil
    if self.btnRemove then self.btnRemove.enable = false end
    if self.lblPreview then self.lblPreview:setName(getText("IGUI_DCS_Debug_RemoveLBNoSelected")) end

    local names = collectLeaderboardNames()
    if #names == 0 then
        if self.lblInfo then self.lblInfo:setName(getText("IGUI_DCS_Debug_RemoveLBNone")) end
        return
    end
    if self.lblInfo then self.lblInfo:setName(getText("IGUI_DCS_Debug_RemoveLBInstruction")) end
    for _, n in ipairs(names) do
        self.nameList:addItem(n, { name = n })
    end
end

function DCS_LeaderboardRemovePicker_Window:drawNameItem(y, item, alt)
    local data = item.item
    local label = item.name or (data and data.name) or "?"
    local h = self.itemheight or (fontHgt + S(9))
    local w = self:getWidth()

    self:drawRect(0, y, w, h, 1, 0.08, 0.08, 0.08)

    if self.selected == item.index then
        self:drawRect(0, y, w, h, 0.3, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
    end

    self:drawText(label, S(8), y + S(6), 1, 1, 1, 1, UIFont.Small)

    return y + h
end

function DCS_LeaderboardRemovePicker_Window.onNameSelected(target, data)
    if not data or not data.name then return end
    target.selectedName = data.name
    if target.btnRemove then target.btnRemove.enable = true end
    if target.lblPreview then target.lblPreview:setName(data.name) end
end

function DCS_LeaderboardRemovePicker_Window.onRemove(target)
    if not target.selectedName then return end
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local modal = ISModalDialog:new(
        screenW / 2 - S(175), screenH / 2 - S(75), S(350), S(150),
        getText("IGUI_DCS_Debug_ConfirmRemoveFromLB", target.selectedName),
        true, target, DCS_LeaderboardRemovePicker_Window.onRemoveConfirm)
    modal:initialise()
    modal:addToUIManager()
end

function DCS_LeaderboardRemovePicker_Window.onRemoveConfirm(target, button)
    if button.internal == "NO" then return end
    if not target.selectedName then return end
    local player = getSpecificPlayer(0)
    if not player then return end
    DCS_dprint("[DCS] Admin: Remove from leaderboard — " .. tostring(target.selectedName))
    sendClientCommand(player, "DailyChallengeSystem", "adminRemoveFromLeaderboard", { displayName = target.selectedName })
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_RemovingFromLB", target.selectedName), "debug")
    target:close()
end

function DCS_LeaderboardRemovePicker_Window:prerender()
    ISCollapsableWindow.prerender(self)
end

function DCS_LeaderboardRemovePicker_Window:close()
    DCS_Sync.saveWindowPos("lbremovepicker", self:getX(), self:getY())
    self:setVisible(false)
    self:removeFromUIManager()
    DCS_LeaderboardRemovePicker.instance = nil
    if DCS_UI_Debug.instance then
        DCS_UI_Debug.instance:setVisible(true)
    end
end

function DCS_LeaderboardRemovePicker.open()
    local player = getSpecificPlayer(0)
    if not player then return end

    if DCS_LeaderboardRemovePicker.instance then
        DCS_LeaderboardRemovePicker.instance:setVisible(true)
        DCS_LeaderboardRemovePicker.instance:refreshList()
        return
    end

    local screenW = getPlayerScreenWidth(0)
    local screenH = getPlayerScreenHeight(0)
    local x, y = DCS_Sync.getWindowPos("lbremovepicker",
        math.floor((screenW - LBRPICKER_W) / 2), math.floor((screenH - LBRPICKER_H) / 2))
    x = math.max(0, math.min(x, screenW - LBRPICKER_W))
    y = math.max(0, math.min(y, screenH - LBRPICKER_H))

    local win = DCS_LeaderboardRemovePicker_Window:new(x, y)
    win:initialise()
    win:instantiate()
    win:setTitle(getText("IGUI_DCS_Debug_RemoveLBTitle"))
    win:addToUIManager()
    win:setVisible(true)

    DCS_LeaderboardRemovePicker.instance = win
end

function DCS_LeaderboardRemovePicker.close()
    if DCS_LeaderboardRemovePicker.instance then
        DCS_LeaderboardRemovePicker.instance:close()
    end
end

DCS_LeaderboardEntryPicker = {}
DCS_LeaderboardEntryPicker.instance = nil

local LBRPICKER_W = S(480)
local LBRPICKER_H = S(420)

DCS_LeaderboardEntryPicker_Window = ISCollapsableWindow:derive("DCS_LeaderboardEntryPicker_Window")

local ENTRY_CATEGORIES = {
    { key = "mostCompleted", labelKey = "IGUI_DCS_Panel_LB_MostCompleted", field = "count", isSpeedrun = false },
    { key = "highestStreak", labelKey = "IGUI_DCS_Panel_LB_LongestOverall", field = "streak", isSpeedrun = false },
    { key = "speedrun7", labelKey = "IGUI_DCS_Panel_LB_FastestAll", field = "time", isSpeedrun = true },
    { key = "speedrun1", labelKey = "IGUI_DCS_Panel_LB_FastestOne", field = "time", isSpeedrun = true },
    { key = "currentStreak", labelKey = "IGUI_DCS_Panel_LB_LongestStreak", field = "streak", isSpeedrun = false },
    { key = "mostTokens", labelKey = "IGUI_DCS_Panel_LB_MostTokens", field = "count", isSpeedrun = false },
}

local function countLabel(count)
    return (count == 1) and getText("IGUI_DCS_Panel_LB_Challenge") or getText("IGUI_DCS_Panel_LB_Challenges")
end
local function streakLabel(count)
    return (count == 1) and getText("IGUI_DCS_Panel_LB_Day") or getText("IGUI_DCS_Panel_LB_Days")
end
local function tokenLabel(count)
    return (count == 1) and getText("IGUI_DCS_Panel_LB_Token") or getText("IGUI_DCS_Panel_LB_Tokens")
end

local function fmtTime(seconds)
    if not seconds or seconds < 0 then return "?" end
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

local function fmtDate(dateStr)
    if not dateStr or dateStr == "" then return "" end
    local day = tonumber(string.sub(dateStr, 7, 8))
    local month = tonumber(string.sub(dateStr, 5, 6))
    local year = tonumber(string.sub(dateStr, 1, 4))
    local suffix = "th"
    if day == 1 or day == 21 or day == 31 then suffix = "st"
    elseif day == 2 or day == 22 then suffix = "nd"
    elseif day == 3 or day == 23 then suffix = "rd" end
    local monthKeys = { "IGUI_DCS_Panel_Month_January", "IGUI_DCS_Panel_Month_February",
        "IGUI_DCS_Panel_Month_March", "IGUI_DCS_Panel_Month_April",
        "IGUI_DCS_Panel_Month_May", "IGUI_DCS_Panel_Month_June",
        "IGUI_DCS_Panel_Month_July", "IGUI_DCS_Panel_Month_August",
        "IGUI_DCS_Panel_Month_September", "IGUI_DCS_Panel_Month_October",
        "IGUI_DCS_Panel_Month_November", "IGUI_DCS_Panel_Month_December" }
    local monthName = (month and month >= 1 and month <= 12) and getText(monthKeys[month] or "") or ""
    return day .. suffix .. " " .. monthName .. " " .. (year or "")
end

local function collectLeaderboardEntries()
    local result = {}
    local lb = DCS_Sync and DCS_Sync.State and DCS_Sync.State.leaderboard
    if type(lb) ~= "table" then return result end

    local MAX_ENTRIES = 3

    for _, cat in ipairs(ENTRY_CATEGORIES) do
        local data = lb[cat.key]
        if type(data) == "table" and #data > 0 then
            local entries = {}
            for rank, entry in ipairs(data) do
                if rank > MAX_ENTRIES then break end
                if entry and entry.name and entry.name ~= "" then
                    local display
                    if cat.isSpeedrun then
                        local timeStr = fmtTime(entry.time)
                        local dateStr = fmtDate(entry.date)
                        display = "#" .. rank .. " " .. entry.name .. " — " .. timeStr
                        if dateStr ~= "" then display = display .. " (" .. dateStr .. ")" end
                        entries[#entries + 1] = {
                            display = display,
                            displayName = entry.name,
                            time = entry.time,
                            date = entry.date,
                            rank = rank,
                        }
                    else
                        local value = entry[cat.field] or 0
                        local label
                        if cat.key == "mostTokens" then
                            label = tokenLabel(value)
                        elseif cat.key == "currentStreak" or cat.key == "highestStreak" then
                            label = streakLabel(value)
                        else
                            label = countLabel(value)
                        end
                        display = "#" .. rank .. " " .. entry.name .. " — " .. value .. " " .. label
                        entries[#entries + 1] = {
                            display = display,
                            displayName = entry.name,
                            value = value,
                            rank = rank,
                        }
                    end
                end
            end
            if #entries > 0 then
                result[#result + 1] = {
                    category = cat.key,
                    label = getText(cat.labelKey),
                    entries = entries,
                }
            end
        end
    end
    return result
end

function DCS_LeaderboardEntryPicker_Window:new(x, y)
    local o = ISCollapsableWindow.new(self, x, y, LBRPICKER_W, LBRPICKER_H)
    o.moveWithMouse = true
    o.resizable = false
    return o
end

function DCS_LeaderboardEntryPicker_Window:createChildren()
    ISCollapsableWindow.createChildren(self)

    local titleH = fontHgt + S(1)
    local y = titleH + PAD

    self.lblInfo = ISLabel:new(PAD, y, S(20), getText("IGUI_DCS_Debug_RemoveLBEntryInstruction"), COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, 1, FONT, true)
    self.lblInfo:initialise()
    self:addChild(self.lblInfo)
    y = y + S(24)

    local listH = LBRPICKER_H - titleH - PAD - S(24) - S(24) - BTN_H - PAD - S(20)
    self.entryList = ISScrollingListBox:new(PAD, y, LBRPICKER_W - PAD * 2, listH)
    self.entryList:initialise()
    self.entryList:instantiate()
    self.entryList.itemheight = fontHgt + S(9)
    self.entryList.selected = 0
    self.entryList.drawBorder = true
    self.entryList.doDrawItem = DCS_LeaderboardEntryPicker_Window.drawEntryItem
    self.entryList:setOnMouseDownFunction(self, DCS_LeaderboardEntryPicker_Window.onEntrySelected)
    self:addChild(self.entryList)
    y = y + listH + S(8)

    self.lblPreview = ISLabel:new(PAD, y, S(20), getText("IGUI_DCS_Debug_RemoveLBNoSelected"), COL_TEXT.r, COL_TEXT.g, COL_TEXT.b, 1, FONT, true)
    self.lblPreview:initialise()
    self:addChild(self.lblPreview)
    y = y + S(24)

    self.btnRemove = ISButton:new(PAD, y, LBRPICKER_W - PAD * 2, BTN_H,
        getText("IGUI_DCS_Debug_Remove"), self, DCS_LeaderboardEntryPicker_Window.onRemove)
    self.btnRemove:initialise()
    self.btnRemove:instantiate()
    self.btnRemove.enable = false
    self:addChild(self.btnRemove)

    self.selectedEntry = nil
    self:refreshList()

    self._lbListener = function(lb)
        if DCS_LeaderboardEntryPicker.instance then
            DCS_LeaderboardEntryPicker.instance:refreshList()
        end
    end
    DCS_Sync.Events.subscribe(DCS_Sync.Events.onLeaderboardUpdated, self._lbListener)
end

function DCS_LeaderboardEntryPicker_Window:initialise()
    ISCollapsableWindow.initialise(self)
end

function DCS_LeaderboardEntryPicker_Window:refreshList()
    self.entryList:clear()
    self.selectedEntry = nil
    if self.btnRemove then self.btnRemove.enable = false end
    if self.lblPreview then self.lblPreview:setName(getText("IGUI_DCS_Debug_RemoveLBNoSelected")) end

    local categories = collectLeaderboardEntries()
    if #categories == 0 then
        if self.lblInfo then self.lblInfo:setName(getText("IGUI_DCS_Debug_RemoveLBEntryNone")) end
        return
    end
    if self.lblInfo then self.lblInfo:setName(getText("IGUI_DCS_Debug_RemoveLBEntryInstruction")) end

    for _, cat in ipairs(categories) do
        self.entryList:addItem("── " .. cat.label .. " ──", {
            isHeader = true,
            category = cat.category,
        })
        for _, entry in ipairs(cat.entries) do
            self.entryList:addItem(entry.display, {
                isHeader = false,
                category = cat.category,
                displayName = entry.displayName,
                time = entry.time,
                date = entry.date,
                value = entry.value,
                rank = entry.rank,
            })
        end
    end
end

function DCS_LeaderboardEntryPicker_Window:drawEntryItem(y, item, alt)
    local data = item and item.item
    local h = self.itemheight or (fontHgt + S(9))
    local w = self:getWidth()
    local label = (item and item.text) or "?"

    self:drawRect(0, y, w, h, 1, 0.08, 0.08, 0.08)

    if item and self.selected == item.index then
        self:drawRect(0, y, w, h, 0.3, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
    end

    if data and data.isHeader then
        self:drawRect(0, y, w, h, 1, 0.12, 0.12, 0.12)
        self:drawText(label, S(8), y + S(6), COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 1, UIFont.Small)
    else
        self:drawText(label, S(8), y + S(6), 1, 1, 1, 1, UIFont.Small)
    end

    return y + h
end

function DCS_LeaderboardEntryPicker_Window.onEntrySelected(target, data)
    if not data or data.isHeader then return end
    target.selectedEntry = data
    if target.btnRemove then target.btnRemove.enable = true end
    if target.lblPreview then
        local catLabel = data.category
        for _, cat in ipairs(ENTRY_CATEGORIES) do
            if cat.key == data.category then
                catLabel = getText(cat.labelKey)
                break
            end
        end
        local valueStr = ""
        if data.time then
            valueStr = fmtTime(data.time)
        elseif data.value then
            if data.category == "mostTokens" then
                valueStr = data.value .. " " .. tokenLabel(data.value)
            elseif data.category == "currentStreak" or data.category == "highestStreak" then
                valueStr = data.value .. " " .. streakLabel(data.value)
            else
                valueStr = data.value .. " " .. countLabel(data.value)
            end
        end
        target.lblPreview:setName(catLabel .. " - " .. data.displayName .. " (" .. valueStr .. ")")
    end
end

function DCS_LeaderboardEntryPicker_Window.onRemove(target)
    if not target.selectedEntry then return end
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local modal = ISModalDialog:new(
        screenW / 2 - S(175), screenH / 2 - S(75), S(350), S(150),
        getText("IGUI_DCS_Debug_ConfirmRemoveLBEntry", target.selectedEntry.category),
        true, target, DCS_LeaderboardEntryPicker_Window.onRemoveConfirm)
    modal:initialise()
    modal:addToUIManager()
end

function DCS_LeaderboardEntryPicker_Window.onRemoveConfirm(target, button)
    if button.internal == "NO" then return end
    if not target.selectedEntry then return end
    local player = getSpecificPlayer(0)
    if not player then return end
    local entry = target.selectedEntry
    DCS_dprint("[DCS] Admin: Remove LB entry — " .. tostring(entry.displayName) .. " from " .. tostring(entry.category))
    sendClientCommand(player, "DailyChallengeSystem", "adminRemoveEntryFromLeaderboard", {
        category = entry.category,
        displayName = entry.displayName,
        time = entry.time,
        date = entry.date,
        value = entry.value,
    })
    DCS_Sync.showToast(getText("IGUI_DCS_Debug_Toast_RemovingLBEntry", entry.displayName), "debug")
    target:refreshList()
end

function DCS_LeaderboardEntryPicker_Window:prerender()
    ISCollapsableWindow.prerender(self)
end

function DCS_LeaderboardEntryPicker_Window:close()
    if self._lbListener then
        DCS_Sync.Events.unsubscribe(DCS_Sync.Events.onLeaderboardUpdated, self._lbListener)
        self._lbListener = nil
    end
    DCS_Sync.saveWindowPos("lbentrypicker", self:getX(), self:getY())
    self:setVisible(false)
    self:removeFromUIManager()
    DCS_LeaderboardEntryPicker.instance = nil
    if DCS_UI_Debug.instance then
        DCS_UI_Debug.instance:setVisible(true)
    end
end

function DCS_LeaderboardEntryPicker.open()
    local player = getSpecificPlayer(0)
    if not player then return end

    if DCS_LeaderboardEntryPicker.instance then
        DCS_LeaderboardEntryPicker.instance:setVisible(true)
        DCS_LeaderboardEntryPicker.instance:refreshList()
        return
    end

    local screenW = getPlayerScreenWidth(0)
    local screenH = getPlayerScreenHeight(0)
    local x, y = DCS_Sync.getWindowPos("lbentrypicker",
        math.floor((screenW - LBRPICKER_W) / 2), math.floor((screenH - LBRPICKER_H) / 2))
    x = math.max(0, math.min(x, screenW - LBRPICKER_W))
    y = math.max(0, math.min(y, screenH - LBRPICKER_H))

    local win = DCS_LeaderboardEntryPicker_Window:new(x, y)
    win:initialise()
    win:instantiate()
    win:setTitle(getText("IGUI_DCS_Debug_RemoveLBEntryTitle"))
    win:addToUIManager()
    win:setVisible(true)

    DCS_LeaderboardEntryPicker.instance = win
end

function DCS_LeaderboardEntryPicker.close()
    if DCS_LeaderboardEntryPicker.instance then
        DCS_LeaderboardEntryPicker.instance:close()
    end
end

local function onFillWorldObjectContextMenu(playerIndex, context, worldobjects)
    if not hasDebugAccess() then return end
    context:addOption(getText("IGUI_DCS_AdminPanelHook_Button"), nil, function()
        DCS_UI_Debug.toggle()
    end)
    if hasDebugToolsAccess() then
        local sq = nil
        for _, o in ipairs(worldobjects or {}) do
            local s = o.getSquare and o:getSquare()
            if s then sq = s; break end
        end
        if sq then
            local x, y, z = sq:getX(), sq:getY(), sq:getZ()
            context:addOption("DCS: Room Test", nil, function()
                local p = getSpecificPlayer(0)
                if p then
                    sendClientCommand(p, "DailyChallengeSystem", "debugCmd",
                        { action = "testSeal", x = x, y = y, z = z })
                end
            end)
            if DCS_RoomTestViz and DCS_RoomTestViz.active and #DCS_RoomTestViz.active > 0 then
                context:addOption("DCS: Clear Highlights", nil, function()
                    if DCS_RoomTestViz then DCS_RoomTestViz.clear() end
                end)
            end
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
