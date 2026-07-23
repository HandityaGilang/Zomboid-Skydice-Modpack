require "ISUI/ISCollapsableWindow"
require "UnoNoMercy/UNM_Music"
require "UnoNoMercy/UNM_ResultMessages"

UNM_ResultWindow = ISCollapsableWindow:derive("UNM_ResultWindow")

local REVEAL_DELAY_MS = 4000
local CONFETTI_DURATION_MS = 4000
local CONFETTI_COLORS = {
    { 0.92, 0.12, 0.12 },
    { 0.96, 0.78, 0.12 },
    { 0.10, 0.68, 0.28 },
    { 0.10, 0.38, 0.92 },
    { 0.92, 0.92, 0.88 },
}

local function nowMs()
    return getTimestampMs and getTimestampMs() or math.floor(os.time() * 1000)
end

local function opponentName(state, winner)
    for _, name in ipairs(state and state.players or {}) do
        if tostring(name) ~= tostring(winner) then return tostring(name) end
    end
    return UNM.text("IGUI_UNM_YourOpponent", "Your opponent")
end

local function victoryMessage(state, winner, roundNo)
    local opponent = opponentName(state, winner)
    local messages = UNM_RESULT_MESSAGES or { "You survived the battle!" }
    local seed = tonumber(roundNo) or 1
    for i = 1, string.len(tostring(winner or "")) do
        seed = seed + string.byte(tostring(winner), i)
    end
    local message = tostring(messages[(seed % #messages) + 1] or "You survived the battle!")
    return string.gsub(message, "{opponent}", opponent)
end

function UNM_ResultWindow:new(x, y, width, height, mode, state)
    local o = ISCollapsableWindow.new(self, x, y, width, height)
    o.mode = mode
    o.state = state
    o.title = UNM.text("IGUI_UNM_WindowTitle", "UNO No Mercy")
    o.resizable = false
    o.alwaysOnTop = true
    o.createdAt = nowMs()
    o.cancelled = false
    o.winner = tostring(state and state.publicState and state.publicState.winner or "")
    o.message = victoryMessage(state, o.winner, state and state.publicState and state.publicState.roundNo)
    return o
end

function UNM_ResultWindow:startVictoryMusic()
    if self.mode == "winner" then
        UNM_Music.play("UNMVictoryMusic", self)
    end
end

function UNM_ResultWindow:stopVictoryMusic()
    if UNM_Music.alias == "UNMVictoryMusic" then
        UNM_Music.stop(self)
    end
end

function UNM_ResultWindow:initialise()
    ISCollapsableWindow.initialise(self)
    self:startVictoryMusic()
end

function UNM_ResultWindow:close()
    self.cancelled = true
    self:stopVictoryMusic()
    self:removeFromUIManager()
    self:setVisible(false)
end

function UNM_ResultWindow:drawConfetti(elapsed)
    if elapsed < 0 or elapsed > CONFETTI_DURATION_MS then return end
    local progress = elapsed / CONFETTI_DURATION_MS
    local areaTop = 28
    local areaHeight = self.height - 48
    for i = 1, 72 do
        local color = CONFETTI_COLORS[((i - 1) % #CONFETTI_COLORS) + 1]
        local x = ((i * 83 + math.floor(progress * 170 * ((i % 3) + 1))) % math.max(1, self.width - 16)) + 8
        local y = areaTop + ((i * 47 + math.floor(progress * areaHeight * ((i % 4) + 2))) % math.max(1, areaHeight))
        local size = 3 + (i % 4)
        self:drawRect(x, y, size, size + (i % 3), 0.86 * (1 - progress * 0.35), color[1], color[2], color[3])
    end
end

function UNM_ResultWindow:prerender()
    ISCollapsableWindow.prerender(self)
    if self.cancelled then return end
    self:drawRect(0, 16, self.width, self.height - 16, 0.98, 0.018, 0.020, 0.022)
    self:drawRectBorder(8, 26, self.width - 16, self.height - 34, 0.92, 0.64, 0.52, 0.22)

    local elapsed = nowMs() - self.createdAt
    local cx = self.width / 2
    if self.mode == "winner" then
        local revealed = elapsed >= REVEAL_DELAY_MS
        if revealed then
            self:drawConfetti(elapsed - REVEAL_DELAY_MS)
            self:drawTextCentre(UNM.text("IGUI_UNM_ResultWinner", "WINNER"), cx + 3, 112, 0.10, 0.08, 0.04, 0.92, UIFont.Large)
            self:drawTextCentre(UNM.text("IGUI_UNM_ResultWinner", "WINNER"), cx, 108, 1.00, 0.82, 0.18, 1, UIFont.Large)
            self:drawTextCentre(self.winner, cx, 172, 0.96, 0.92, 0.82, 1, UIFont.Medium)
            self:drawTextCentre(self.message, cx, 236, 0.84, 0.82, 0.74, 1, UIFont.Medium)
        else
            self:drawTextCentre(UNM.text("IGUI_UNM_ResultWinner", "WINNER"), cx, 108, 0.10, 0.10, 0.10, 0.78, UIFont.Large)
            self:drawTextCentre(UNM.text("IGUI_UNM_FinalVerdict", "The final verdict approaches..."), cx, 220, 0.46, 0.45, 0.42, 1, UIFont.Small)
        end
    elseif self.mode == "loser" then
        self:drawTextCentre(UNM.text("IGUI_UNM_ResultLoser", "LOSER"), cx + 2, 112, 0.04, 0.02, 0.02, 0.95, UIFont.Large)
        self:drawTextCentre(UNM.text("IGUI_UNM_ResultLoser", "LOSER"), cx, 108, 0.76, 0.12, 0.10, 1, UIFont.Large)
        self:drawTextCentre(string.gsub(UNM.text("IGUI_UNM_WonBattle", "%1 won the battle."), "%%1", self.winner), cx, 205, 0.76, 0.74, 0.68, 1, UIFont.Medium)
    else
        self:drawTextCentre(UNM.text("IGUI_UNM_ResultWinner", "WINNER"), cx, 108, 1.00, 0.82, 0.18, 1, UIFont.Large)
        self:drawTextCentre(self.winner, cx, 185, 0.94, 0.90, 0.80, 1, UIFont.Medium)
    end
end
