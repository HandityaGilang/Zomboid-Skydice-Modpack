require "ISUI/ISCollapsableWindow"
require "ISUI/ISVolumeControl"
require "UnoNoMercy/UNM_Core"
require "UnoNoMercy/UNM_Rules"
require "UnoNoMercy/UNM_Music"
require "UnoNoMercy/UNM_ResultWindow"

UNM_Window = ISCollapsableWindow:derive("UNM_Window")

local FONT_HGT_SMALL = getTextManager and getTextManager():getFontHeight(UIFont.Small) or 14
local COLOR_RGB = {
    red = { 0.72, 0.08, 0.07 },
    yellow = { 0.86, 0.68, 0.08 },
    green = { 0.06, 0.48, 0.18 },
    blue = { 0.08, 0.22, 0.72 },
    wild = { 0.06, 0.06, 0.07 },
}
local TEXTURES = {}
local ANIMATION_MS = 520
local MIN_DRAW_ANIMATION_MS = 70
local STALE_ANIMATION_MS = 3000
local DIRECTION_TEXTURES = {
    [1] = "media/textures/UnoNoMercy/turn_clockwise.png",
    [-1] = "media/textures/UnoNoMercy/turn_counterclockwise.png",
}

local function clamp(value, low, high)
    value = tonumber(value) or low
    if value < low then return low end
    if value > high then return high end
    return value
end

local function measure(text, font)
    local manager = getTextManager and getTextManager() or nil
    if manager and manager.MeasureStringX then
        local ok, value = pcall(function()
            return manager:MeasureStringX(font or UIFont.Small, tostring(text or ""))
        end)
        if ok and value then
            return value
        end
    end
    return string.len(tostring(text or "")) * 7
end

local function fit(text, font, width)
    text = tostring(text or "")
    width = tonumber(width) or 0
    if width <= 0 or measure(text, font) <= width then
        return text
    end
    local suffix = "..."
    local limit = math.max(1, string.len(text) - 1)
    while limit > 1 do
        local candidate = string.sub(text, 1, limit) .. suffix
        if measure(candidate, font) <= width then
            return candidate
        end
        limit = limit - 1
    end
    return suffix
end

local function contains(rect, x, y)
    return rect and x >= rect.x and y >= rect.y and x <= rect.x + rect.w and y <= rect.y + rect.h
end

local function texture(path)
    if not path or not getTexture then
        return nil
    end
    if TEXTURES[path] == nil then
        TEXTURES[path] = getTexture(path) or false
    end
    return TEXTURES[path] or nil
end

local function playSound(alias)
    if not alias or not getSoundManager then
        return
    end
    local manager = getSoundManager()
    if manager and manager.playUISound then
        pcall(function()
            manager:playUISound(alias)
        end)
    end
end

local function nowMs()
    if getTimestampMs then
        return getTimestampMs()
    end
    return math.floor(os.time() * 1000)
end

local function cardTextureFile(card)
    local color = UNM_Rules.cardColor(card)
    local value = UNM_Rules.cardValue(card)
    local wildFiles = {
        WR4 = "wild_draw4.png",
        W6 = "wild_draw6.png",
        W10 = "wild_draw10.png",
        WCR = "wild_roulette.png",
    }
    if wildFiles[value] then
        return wildFiles[value]
    end
    local files = { S = "skip", SA = "skip_all", R = "reverse", D2 = "draw2", D4 = "draw4", DA = "discard_all" }
    return tostring(color) .. "_" .. tostring(files[value] or value) .. ".png"
end

local function specialCardKind(card, sevenZeroEnabled)
    local value = UNM_Rules.cardValue(card)
    if sevenZeroEnabled ~= false and value == "7" then
        return "swap"
    elseif sevenZeroEnabled ~= false and value == "0" then
        return "rotate"
    elseif value == "S" or value == "SA" then
        return "skip"
    elseif value == "R" then
        return "reverse"
    elseif value == "D2" then
        return "draw2"
    elseif value == "D4" or value == "WR4" then
        return "draw4"
    elseif value == "W6" then
        return "draw6"
    elseif value == "W10" then
        return "draw10"
    elseif value == "DA" then
        return "discard"
    elseif value == "WCR" then
        return "roulette"
    elseif UNM_Rules.isWild(card) then
        return "wild"
    end
    return nil
end

local function specialSound(card, sevenZeroEnabled)
    local kind = specialCardKind(card, sevenZeroEnabled)
    if kind == "swap" or kind == "rotate" then
        return "UNMHandShiftCard"
    elseif kind == "skip" then
        return "UNMSkipCard"
    elseif kind == "reverse" then
        return "UNMReverseCard"
    elseif kind == "draw2" then
        return "UNMDrawTwoCard"
    elseif kind == "draw4" then
        return "UNMDrawFourCard"
    elseif kind == "draw6" then
        return "UNMDrawSixCard"
    elseif kind == "draw10" then
        return "UNMDrawTenCard"
    elseif kind == "discard" then
        return "UNMDiscardAllCard"
    elseif kind == "roulette" then
        return "UNMRouletteCard"
    elseif kind == "wild" then
        return "UNMWildCard"
    end
    return nil
end

function UNM_Window:new(x, y, width, height, playerNum, playerObj)
    local o = ISCollapsableWindow.new(self, x, y, width, height)
    o.playerNum = playerNum or 0
    o.playerObj = playerObj
    o.title = UNM.text("IGUI_UNM_WindowTitle", "UNO No Mercy")
    o.resizable = true
    o.state = nil
    o.buttons = {}
    o.handRects = {}
    o.pendingWildIndex = nil
    o.pendingTargetIndex = nil
    o.lastAnimationSeq = nil
    o.lastEventSeq = nil
    o.lastRoundNo = nil
    o.animation = nil
    o.animationQueue = {}
    o.drawBatchRemaining = 0
    o.drawBatchAnimationMs = nil
    o.musicVolumeControl = nil
    o.resultWindow = nil
    o.lastResultRound = nil
    o.leaveRequested = false
    return o
end

function UNM_Window:startMusic()
    UNM_Music.play("UNMGameMusic", self)
end

function UNM_Window:stopMusic()
    if UNM_Music.alias == "UNMGameMusic" then
        UNM_Music.stop(self)
    end
end

function UNM_Window:syncMusic()
    if self.state and self.state.phase == UNM.PHASE_PLAYING and UNM_Music.enabled then
        self:startMusic()
    else
        self:stopMusic()
    end
end

function UNM_Window:toggleMusic()
    UNM_Music.setEnabled(not UNM_Music.enabled)
    self:syncMusic()
end

function UNM_Window:onMusicVolumeChanged(control, volume)
    UNM_Music.setVolume((tonumber(volume) or 0) / 10)
end

function UNM_Window:createChildren()
    ISCollapsableWindow.createChildren(self)
    self.musicVolumeControl = ISVolumeControl:new(24, self.height - 88, 210, 20, self, UNM_Window.onMusicVolumeChanged)
    self.musicVolumeControl:initialise()
    self.musicVolumeControl:setVolume(math.floor(UNM_Music.volume * 10 + 0.5))
    self:addChild(self.musicVolumeControl)
end

function UNM_Window:closeResultWindow()
    if self.resultWindow then
        self.resultWindow:close()
        self.resultWindow = nil
    end
end

function UNM_Window:syncResultWindow()
    local state = self.state or {}
    local ps = state.publicState or {}
    local roundNo = tonumber(ps.roundNo) or 0
    if state.phase ~= UNM.PHASE_GAME_OVER or not ps.winner then return end
    if self.lastResultRound == roundNo then return end
    self:closeResultWindow()
    self.lastResultRound = roundNo
    local mode = "spectator"
    if UNM.findName(ps.winners or {}, state.viewerName) or tostring(state.viewerName) == tostring(ps.winner) then
        mode = "winner"
    elseif UNM.findName(state.players or {}, state.viewerName) then
        mode = "loser"
    end
    local width, height = 620, 360
    local x = self.x + math.floor((self.width - width) / 2)
    local y = self.y + math.floor((self.height - height) / 2)
    local result = UNM_ResultWindow:new(x, y, width, height, mode, state)
    result:initialise()
    result:addToUIManager()
    self.resultWindow = result
end

function UNM_Window:setState(state)
    local oldRoundNo = self.lastRoundNo
    self.state = state
    local ps = state and state.publicState or {}
    local roundNo = tonumber(ps.roundNo) or 0
    if oldRoundNo ~= nil and roundNo ~= oldRoundNo then
        self:closeResultWindow()
        self.lastResultRound = nil
        self.animation = nil
        self.animationQueue = {}
        self.drawBatchRemaining = 0
        self.drawBatchAnimationMs = nil
        self.lastAnimationSeq = nil
    end
    self.lastRoundNo = roundNo
    self.pendingWildIndex = nil
    self.pendingTargetIndex = nil
    self:handleStateFeedback()
    self:syncMusic()
    self:syncResultWindow()
end

function UNM_Window:close()
    UNM_Music.forceStop()
    self:closeResultWindow()
    if not self.leaveRequested and self.state and self.state.anchor and UNM_Client then
        self.leaveRequested = true
        UNM_Client.leave(self.playerNum or 0, self.state)
    end
    if UNM_Client and UNM_Client.windows then
        UNM_Client.windows[self.playerNum or 0] = nil
    end
    ISCollapsableWindow.close(self)
end

function UNM_Window:statusText()
    local phase = self.state and self.state.phase or "opening"
    if phase == UNM.PHASE_PLAYING then
        return UNM.text("IGUI_UNM_Playing", "Playing")
    elseif phase == UNM.PHASE_GAME_OVER then
        return UNM.text("IGUI_UNM_GameOver", "Game over")
    elseif phase == UNM.PHASE_WAITING then
        return UNM.text("IGUI_UNM_Waiting", "Waiting for players")
    end
    return UNM.text("IGUI_UNM_Opening", "Opening...")
end

function UNM_Window:currentPlayerName()
    local ps = self.state and self.state.publicState or {}
    return tostring(ps.currentPlayerName or "-")
end

function UNM_Window:isViewerTurn()
    return self.state and self.state.viewerName and self:currentPlayerName() == tostring(self.state.viewerName)
end

function UNM_Window:findAction(id)
    for i = 1, #(self.state and self.state.legalActions or {}) do
        local action = self.state.legalActions[i]
        if action and action.id == id then
            return action
        end
    end
    return nil
end

function UNM_Window:isPlayableCardIndex(index)
    for _, action in ipairs(self.state and self.state.legalActions or {}) do
        if action and action.id == UNM.ACTION_PLAY_CARD and action.enabled and
                tonumber(action.args and action.args.cardIndex) == tonumber(index) then
            return true
        end
    end
    return false
end

function UNM_Window:sendAction(action, args)
    if UNM_Client then
        if action == UNM.ACTION_START_ROUND then
        playSound("UNMStartGame")
        end
        UNM_Client.action(self.playerNum or 0, self.state, action, args or {})
    end
end

function UNM_Window:queueAnimation(animation)
    if not animation or not animation.seq then
        return
    end
    if self.lastAnimationSeq and animation.seq <= self.lastAnimationSeq then
        return
    end
    local createdAt = tonumber(animation.createdAt)
    if not self.lastAnimationSeq and createdAt and nowMs() - createdAt > STALE_ANIMATION_MS then
        self.lastAnimationSeq = animation.seq
        return
    end
    self.lastAnimationSeq = animation.seq
    self.animationQueue = self.animationQueue or {}
    table.insert(self.animationQueue, UNM.copy(animation))
end

local function newestFeedbackEvent(events, lastEventSeq)
    local newestId = events[1] and tonumber(events[1].id) or nil
    local selected, selectedPriority = nil, 0
    local priorities = {
        win = 5,
        eliminated = 4,
        uno_penalty = 3,
        uno = 3,
        leave = 2,
        join = 2,
    }
    for i = 1, #events do
        local event = events[i]
        local eventId = tonumber(event and event.id)
        if eventId and (not lastEventSeq or eventId > tonumber(lastEventSeq)) then
            local priority = priorities[event.kind] or 0
            if priority > selectedPriority then
                selected = event
                selectedPriority = priority
            end
        end
    end
    return newestId, selected
end

function UNM_Window:handleStateFeedback()
    local ps = self.state and self.state.publicState or {}
    local animations = ps.animations or {}
    if #animations > 0 then
        for i = 1, #animations do
            self:queueAnimation(animations[i])
        end
    else
        self:queueAnimation(ps.animation)
    end
    local events = ps.events or {}
    local newestId, feedback = newestFeedbackEvent(events, self.lastEventSeq)
    if newestId and newestId ~= self.lastEventSeq then
        self.lastEventSeq = newestId
        if feedback and feedback.kind == "win" then
            if ps.winner and self.state and (UNM.findName(ps.winners or {}, self.state.viewerName) or tostring(ps.winner) == tostring(self.state.viewerName)) then
                playSound("UNMWin")
            else
                playSound("UNMLose")
            end
        elseif feedback and feedback.kind == "join" then
            playSound("UNMPlayerJoin")
        elseif feedback and feedback.kind == "leave" then
            playSound("UNMPlayerLeave")
        elseif feedback and feedback.kind == "uno" then
            playSound("UNMUno")
        elseif feedback and feedback.kind == "eliminated" then
            playSound("UNMEliminated")
        end
    end
end

function UNM_Window:addButton(label, x, y, w, h, enabled, callback, reason, color)
    self.buttons = self.buttons or {}
    local rect = {
        x = x,
        y = y,
        w = w,
        h = h,
        label = label,
        enabled = enabled ~= false,
        callback = callback,
        reason = reason,
        color = color,
    }
    table.insert(self.buttons, rect)
    local a = rect.enabled and 0.92 or 0.42
    local fill = color or { 0.12, 0.10, 0.08 }
    local border = color or { 0.90, 0.74, 0.42 }
    self:drawRect(x, y, w, h, a, fill[1], fill[2], fill[3])
    self:drawRectBorder(x, y, w, h, a,
        rect.enabled and border[1] or 0.35,
        rect.enabled and border[2] or 0.34,
        rect.enabled and border[3] or 0.22)
    local textR, textG, textB = 0.98, 0.88, 0.58
    if color then
        local luminance = color[1] * 0.299 + color[2] * 0.587 + color[3] * 0.114
        textR, textG, textB = luminance > 0.55 and 0.08 or 1, luminance > 0.55 and 0.07 or 1, luminance > 0.55 and 0.05 or 1
    end
    if not rect.enabled then
        textR, textG, textB = 0.56, 0.54, 0.48
    end
    self:drawTextCentre(fit(label, UIFont.Small, w - 8), x + w / 2, y + math.floor((h - FONT_HGT_SMALL) / 2), textR, textG, textB, 1, UIFont.Small)
    return rect
end

function UNM_Window:drawPanel(x, y, w, h)
    self:drawRect(x, y, w, h, 0.96, 0.025, 0.030, 0.028)
    self:drawRectBorder(x, y, w, h, 0.86, 0.42, 0.34, 0.24)
end

function UNM_Window:drawCardBack(x, y, w, h)
    local back = texture("media/textures/UnoNoMercy/cards/card_back.png")
    if back then
        self:drawTextureScaled(back, x, y, w, h, 1, 1, 1, 1)
        return
    end
    self:drawRect(x, y, w, h, 1, 0.08, 0.10, 0.13)
    self:drawRectBorder(x, y, w, h, 0.95, 0.66, 0.52, 0.22)
    self:drawRect(x + 7, y + 7, w - 14, h - 14, 0.78, 0.16, 0.18, 0.24)
    self:drawTextCentre("SC", x + w / 2, y + h / 2 - 7, 0.90, 0.84, 0.68, 1, UIFont.Small)
end

function UNM_Window:drawCard(card, x, y, w, h, selected, playable)
    if not card then
        self:drawCardBack(x, y, w, h)
        return
    end
    local cardTexture = texture("media/textures/UnoNoMercy/cards/" .. cardTextureFile(card))
    if cardTexture then
        self:drawTextureScaled(cardTexture, x, y, w, h, 1, 1, 1, 1)
        if selected then
            self:drawRectBorder(x - 1, y - 1, w + 2, h + 2, 1, 1.00, 0.86, 0.32)
        elseif playable then
            local pulse = 0.78 + math.sin(nowMs() / 240) * 0.18
            self:drawRectBorder(x - 2, y - 2, w + 4, h + 4, 1, 0.30, pulse, 0.34)
        end
        return
    end
    local color = UNM_Rules.cardColor(card)
    local value = UNM_Rules.cardValue(card)
    local rgb = COLOR_RGB[color] or COLOR_RGB.wild
    self:drawRect(x, y, w, h, 1, 0.88, 0.84, 0.72)
    local borderR = selected and 1.00 or (playable and 0.30 or 0.18)
    local borderG = selected and 0.86 or (playable and 0.92 or 0.14)
    local borderB = selected and 0.32 or (playable and 0.34 or 0.10)
    self:drawRectBorder(x, y, w, h, selected and 1 or 0.95, borderR, borderG, borderB)
    self:drawRect(x + 6, y + 6, w - 12, h - 12, 0.96, rgb[1], rgb[2], rgb[3])
    if color == "wild" then
        local qW = math.floor((w - 14) / 2)
        local qH = math.floor((h - 14) / 2)
        self:drawRect(x + 7, y + 7, qW, qH, 0.95, COLOR_RGB.red[1], COLOR_RGB.red[2], COLOR_RGB.red[3])
        self:drawRect(x + 7 + qW, y + 7, qW, qH, 0.95, COLOR_RGB.yellow[1], COLOR_RGB.yellow[2], COLOR_RGB.yellow[3])
        self:drawRect(x + 7, y + 7 + qH, qW, qH, 0.95, COLOR_RGB.green[1], COLOR_RGB.green[2], COLOR_RGB.green[3])
        self:drawRect(x + 7 + qW, y + 7 + qH, qW, qH, 0.95, COLOR_RGB.blue[1], COLOR_RGB.blue[2], COLOR_RGB.blue[3])
    end
    local label = value
    local labels = {
        S = "SKIP", SA = "SKIP ALL", R = "REV", D2 = "+2", D4 = "+4",
        DA = "DISCARD", WR4 = "REV +4", W6 = "WILD +6",
        W10 = "WILD +10", WCR = "ROULETTE",
    }
    label = labels[value] or label
    self:drawTextCentre(label, x + w / 2, y + h / 2 - 8, 1, 1, 1, 1, UIFont.Small)
end

function UNM_Window:viewerIndex()
    local state = self.state or {}
    local viewer = tostring(state.viewerName or "")
    for i = 1, #(state.players or {}) do
        if tostring(state.players[i]) == viewer then
            return i
        end
    end
    return 1
end

function UNM_Window:relativeSeatForIndex(index)
    local players = self.state and self.state.players or {}
    local count = #players
    if count <= 0 then
        return "bottom"
    end
    local viewerIndex = self:viewerIndex()
    local relative = (tonumber(index) or viewerIndex) - viewerIndex
    while relative < 0 do
        relative = relative + count
    end
    relative = relative % count
    if relative == 0 then
        return "bottom"
    end
    if count == 2 then
        return "top"
    end
    local seats = {
        [3] = { "left", "right" },
        [4] = { "left", "top", "right" },
        [5] = { "left-bottom", "left-top", "right-top", "right-bottom" },
        [6] = { "left-bottom", "left-top", "top", "right-top", "right-bottom" },
    }
    return seats[count] and seats[count][relative] or "top"
end

function UNM_Window:seatPoint(seat)
    local layout = self.tableLayout
    if not layout then
        return self.width / 2, self.height / 2
    end
    local cx = layout.x + layout.w / 2
    local cy = layout.y + layout.h / 2
    if seat == "top" then
        return cx, layout.y + 28
    elseif seat == "left" then
        return layout.x + 36, cy
    elseif seat == "right" then
        return layout.x + layout.w - 36, cy
    elseif seat == "left-top" then
        return layout.x + 64, layout.y + layout.h * 0.30
    elseif seat == "left-bottom" then
        return layout.x + 64, layout.y + layout.h * 0.70
    elseif seat == "right-top" then
        return layout.x + layout.w - 64, layout.y + layout.h * 0.30
    elseif seat == "right-bottom" then
        return layout.x + layout.w - 64, layout.y + layout.h * 0.70
    end
    local hand = self.handArea
    if hand then
        return hand.x + hand.w / 2, hand.y + 32
    end
    return cx, layout.y + layout.h - 28
end

function UNM_Window:drawHeader()
    local state = self.state or {}
    local ps = state.publicState or {}
    local x = 14
    local y = 28
    self:drawText(self.title, x, y, 0.98, 0.82, 0.42, 1, UIFont.Medium)
    self:drawText(self:statusText(), x, y + 24, 0.78, 0.76, 0.68, 1, UIFont.Small)
    self:drawText(UNM.text("IGUI_UNM_Turn", "Turn") .. ": " .. self:currentPlayerName(), x + 180, y + 24, self:isViewerTurn() and 0.98 or 0.78, self:isViewerTurn() and 0.86 or 0.76, 0.58, 1, UIFont.Small)
    local color = ps.currentColor or "-"
    local colorLabel = UNM.text("IGUI_UNM_" .. string.upper(string.sub(tostring(color), 1, 1)) .. string.sub(tostring(color), 2), UNM.COLOR_LABEL[color] or color)
    self:drawText(UNM.text("IGUI_UNM_CurrentColor", "Color") .. ": " .. tostring(colorLabel), x + 390, y + 24, 0.78, 0.76, 0.68, 1, UIFont.Small)
    local dir = tonumber(ps.direction) == -1 and UNM.text("IGUI_UNM_CounterClockwise", "Counter") or UNM.text("IGUI_UNM_Clockwise", "Clockwise")
    self:drawText(UNM.text("IGUI_UNM_Direction", "Direction") .. ": " .. dir, x + 520, y + 24, 0.78, 0.76, 0.68, 1, UIFont.Small)
    if self.state and self.state.phase ~= UNM.PHASE_PLAYING then
        local mercy = ps.mercyEnabled ~= false and UNM.text("IGUI_UNM_MercyOn", "Mercy ON") or UNM.text("IGUI_UNM_MercyOff", "Mercy OFF")
        local sevenZero = ps.sevenZeroEnabled ~= false and UNM.text("IGUI_UNM_SevenZeroOn", "0/7 ON") or UNM.text("IGUI_UNM_SevenZeroOff", "0/7 OFF")
        self:drawTextRight(mercy .. "  |  " .. sevenZero, self.width - 18, y + 24, 0.92, 0.68, 0.38, 1, UIFont.Small)
    end
    if (tonumber(ps.pendingDraw) or 0) > 0 then
        self:drawTextRight(UNM.text("IGUI_UNM_Penalty", "Penalty") .. ": +" .. tostring(ps.pendingDraw), self.width - 18, y + 24, 1.00, 0.48, 0.28, 1, UIFont.Small)
    end
    if ps.winner then
        self:drawTextRight(UNM.text("IGUI_UNM_Winner", "Winner") .. ": " .. tostring(ps.winner), self.width - 18, y, 0.98, 0.86, 0.58, 1, UIFont.Small)
    end
end

function UNM_Window:drawPlayers(x, y, w, h)
    local state = self.state or {}
    local ps = state.publicState or {}
    self:drawPanel(x, y, w, h)
    self:drawText(UNM.text("IGUI_UNM_Players", "Players"), x + 10, y + 9, 0.96, 0.78, 0.40, 1, UIFont.Small)
    local rowY = y + 34
    for i = 1, UNM.MAX_PLAYERS do
        local name = state.players and state.players[i] or UNM.text("IGUI_UNM_OpenSeat", "Open seat")
        local active = name == ps.currentPlayerName
        local cards = ps.handCounts and ps.handCounts[name] or 0
        local eliminated = name and ps.eliminated and ps.eliminated[name]
        self:drawRect(x + 8, rowY, w - 16, 28, active and 0.76 or 0.42, active and 0.14 or 0.04, active and 0.10 or 0.035, active and 0.04 or 0.028)
        self:drawRectBorder(x + 8, rowY, w - 16, 28, 0.62, active and 0.88 or 0.34, active and 0.64 or 0.28, active and 0.30 or 0.20)
        local displayName = eliminated and (tostring(name) .. " [" .. UNM.text("IGUI_UNM_Out", "OUT") .. "]") or tostring(name)
        self:drawText(fit(displayName, UIFont.Small, w - 92), x + 16, rowY + 7, eliminated and 0.54 or (active and 0.98 or 0.78), eliminated and 0.52 or (active and 0.86 or 0.78), eliminated and 0.50 or 0.64, 1, UIFont.Small)
        if state.players and state.players[i] then
            self:drawTextRight(tostring(cards), x + w - 18, rowY + 7, 0.92, 0.84, 0.62, 1, UIFont.Small)
        end
        rowY = rowY + 34
    end
end

function UNM_Window:drawEvents(x, y, w, h)
    local events = self.state and self.state.publicState and self.state.publicState.events or {}
    self:drawPanel(x, y, w, h)
    self:drawText(UNM.text("IGUI_UNM_TableLog", "Table Log"), x + 10, y + 9, 0.96, 0.78, 0.40, 1, UIFont.Small)
    local rowY = y + 32
    for i = 1, math.min(#events, math.floor((h - 38) / 18)) do
        self:drawText(fit(events[i].text or "", UIFont.Small, w - 20), x + 10, rowY, 0.72, 0.76, 0.70, 1, UIFont.Small)
        rowY = rowY + 18
    end
end

function UNM_Window:drawTable(x, y, w, h)
    local state = self.state or {}
    local ps = state.publicState or {}
    self:drawPanel(x, y, w, h)
    self:drawRect(x + 8, y + 8, w - 16, h - 16, 0.94, 0.02, 0.20, 0.12)
    local cardW = clamp(math.floor(w * 0.12), 58, 78)
    local cardH = math.floor(cardW * 1.42)
    local midY = y + math.floor((h - cardH) / 2)
    local drawX = x + math.floor(w / 2) - cardW - 24
    local discardX = x + math.floor(w / 2) + 24
    self.tableLayout = { x = x, y = y, w = w, h = h, drawX = drawX, discardX = discardX, cardY = midY, cardW = cardW, cardH = cardH }
    self:drawDirectionIndicator(x, y, w, h, ps.direction)
    self:drawSeatMarkers()
    self:drawCard(nil, drawX, midY, cardW, cardH)
    self:drawTextCentre(UNM.text("IGUI_UNM_DrawPile", "Draw") .. " " .. tostring(ps.deckCount or 0), drawX + cardW / 2, midY + cardH + 8, 0.88, 0.82, 0.62, 1, UIFont.Small)
    self:drawCard(ps.topCard, discardX, midY, cardW, cardH)
    self:drawTextCentre(UNM.text("IGUI_UNM_DiscardPile", "Discard"), discardX + cardW / 2, midY + cardH + 8, 0.88, 0.82, 0.62, 1, UIFont.Small)
    if ps.currentColor and COLOR_RGB[ps.currentColor] then
        local rgb = COLOR_RGB[ps.currentColor]
        self:drawRect(discardX + cardW + 22, midY + 10, 32, 32, 1, rgb[1], rgb[2], rgb[3])
        self:drawRectBorder(discardX + cardW + 22, midY + 10, 32, 32, 0.92, 0.92, 0.82, 0.46)
    end
    self:drawTableNotice(x, y, w)
end

function UNM_Window:drawTableNotice(x, y, w)
    local events = self.state and self.state.publicState and self.state.publicState.events or {}
    local event = events[1]
    if not event or (event.kind ~= "uno" and event.kind ~= "uno_penalty" and event.kind ~= "eliminated") then
        return
    end
    local text = tostring(event.text or "")
    local noticeW = math.min(360, w - 36)
    local noticeX = x + math.floor((w - noticeW) / 2)
    local noticeY = y + 18
    local r, g, b = 0.10, 0.12, 0.12
    local tr, tg, tb = 0.96, 0.82, 0.42
    if event.kind == "uno_penalty" or event.kind == "eliminated" then
        r, g, b = 0.20, 0.05, 0.04
        tr, tg, tb = 1.00, 0.62, 0.42
    end
    self:drawRect(noticeX, noticeY, noticeW, 28, 0.86, r, g, b)
    self:drawRectBorder(noticeX, noticeY, noticeW, 28, 0.84, tr, tg, tb)
    self:drawTextCentre(fit(text, UIFont.Small, noticeW - 16), noticeX + noticeW / 2, noticeY + 7, tr, tg, tb, 1, UIFont.Small)
end

function UNM_Window:drawSeatMarkers()
    local state = self.state or {}
    local ps = state.publicState or {}
    local players = state.players or {}
    for i = 1, #players do
        local name = players[i]
        local seat = self:relativeSeatForIndex(i)
        local px, py = self:seatPoint(seat)
        local cards = ps.handCounts and ps.handCounts[name] or 0
        local eliminated = ps.eliminated and ps.eliminated[name]
        local label = fit(tostring(name), UIFont.Small, 92)
        if tostring(name) == tostring(state.viewerName) then
            label = UNM.text("IGUI_UNM_You", "You")
        end
        local boxW = 116
        local boxH = 24
        local bx = px - boxW / 2
        local by = py - boxH / 2
        if seat == "bottom" then
            by = by + 18
        end
        if eliminated then
            label = label .. " [OUT]"
        end
        local active = name == ps.currentPlayerName
        self:drawRect(bx, by, boxW, boxH, active and 0.76 or 0.45, 0.03, 0.035, 0.035)
        self:drawRectBorder(bx, by, boxW, boxH, 0.72, active and 0.92 or 0.48, active and 0.76 or 0.42, active and 0.32 or 0.28)
        self:drawText(fit(label, UIFont.Small, boxW - 34), bx + 7, by + 5, eliminated and 0.52 or (active and 0.98 or 0.82), eliminated and 0.52 or (active and 0.86 or 0.80), eliminated and 0.50 or 0.62, 1, UIFont.Small)
        self:drawTextRight(tostring(cards), bx + boxW - 7, by + 5, 0.94, 0.84, 0.56, 1, UIFont.Small)
        if ps.unoCalled and ps.unoCalled[name] then
            self:drawTextCentre("UNO", bx + boxW / 2, by - 15, 1.00, 0.88, 0.32, 1, UIFont.Small)
        end
    end
end

function UNM_Window:drawDirectionIndicator(x, y, w, h, direction)
    direction = tonumber(direction) == -1 and -1 or 1
    local tex = texture(DIRECTION_TEXTURES[direction])
    local pulse = 1 + (math.sin(nowMs() / 420) * 0.035)
    local size = clamp(math.floor(math.min(w, h) * 0.56 * pulse), 150, 286)
    local cx = x + math.floor((w - size) / 2)
    local cy = y + math.floor((h - size) / 2)
    if tex then
        self:drawTextureScaled(tex, cx, cy, size, size, 0.38, 1, 1, 1)
        return
    end
    local left = direction == 1 and "<" or ">"
    local right = direction == 1 and ">" or "<"
    self:drawTextCentre(left, cx + size * 0.25, cy + size * 0.48, 0.95, 0.80, 0.36, 0.30, UIFont.Large)
    self:drawTextCentre(right, cx + size * 0.75, cy + size * 0.48, 0.95, 0.80, 0.36, 0.30, UIFont.Large)
end

function UNM_Window:playerAnimationPoint(name)
    local state = self.state or {}
    local players = state.players or {}
    for i = 1, #players do
        if players[i] and tostring(players[i]) == tostring(name) then
            return self:seatPoint(self:relativeSeatForIndex(i))
        end
    end
    return self:seatPoint("top")
end

function UNM_Window:drawAnimation()
    if not self.animation and self.animationQueue and #self.animationQueue > 0 then
        self.animation = table.remove(self.animationQueue, 1)
        self.animation.startedAt = nowMs()
        if self.animation.kind == "draw" then
            if not self.drawBatchRemaining or self.drawBatchRemaining <= 0 then
                local batchSize = 1
                for i = 1, #self.animationQueue do
                    local queued = self.animationQueue[i]
                    if not queued or queued.kind ~= "draw" or
                            tostring(queued.playerName) ~= tostring(self.animation.playerName) then
                        break
                    end
                    batchSize = batchSize + 1
                end
                self.drawBatchRemaining = batchSize
                if batchSize <= 3 then
                    self.drawBatchAnimationMs = ANIMATION_MS
                else
                    self.drawBatchAnimationMs = math.max(
                        MIN_DRAW_ANIMATION_MS,
                        math.floor(ANIMATION_MS / (1 + (batchSize - 3) * 0.26))
                    )
                end
                playSound("UNMDrawCard")
            end
            self.animation.durationMs = self.drawBatchAnimationMs or ANIMATION_MS
        elseif self.animation.kind == "play" then
            self.drawBatchRemaining = 0
            self.drawBatchAnimationMs = nil
            local ps = self.state and self.state.publicState or {}
            playSound(specialSound(self.animation.card, ps.sevenZeroEnabled) or "UNMThrowCard")
        end
    end
    local animation = self.animation
    local layout = self.tableLayout
    if not animation or not layout then
        return
    end
    local elapsed = nowMs() - (animation.startedAt or nowMs())
    local t = clamp(elapsed / (animation.durationMs or ANIMATION_MS), 0, 1)
    local cardW = layout.cardW
    local cardH = layout.cardH
    local fromX = layout.drawX
    local fromY = layout.cardY
    local toX = layout.discardX
    local toY = layout.cardY
    if animation.kind == "play" then
        local px, py = self:playerAnimationPoint(animation.playerName)
        fromX = px - cardW / 2
        fromY = py - cardH / 2
    elseif animation.kind == "draw" then
        local px, py = self:playerAnimationPoint(animation.playerName)
        toX = px - cardW / 2
        toY = py - cardH / 2
    end
    local x = fromX + (toX - fromX) * t
    local y = fromY + (toY - fromY) * t
    local ps = self.state and self.state.publicState or {}
    local specialKind = specialCardKind(animation.card, ps.sevenZeroEnabled)
    if animation.kind == "play" and specialKind then
        local handChange = specialKind == "swap" or specialKind == "rotate"
        local scale = (handChange and 1.24 or 1.18) + math.sin(math.min(1, t) * math.pi) * (handChange and 0.16 or 0.10)
        local oldW = cardW
        local oldH = cardH
        cardW = math.floor(cardW * scale)
        cardH = math.floor(cardH * scale)
        x = x - (cardW - oldW) / 2
        y = y - (cardH - oldH) / 2
        self:drawSpecialParticles(animation, x + cardW / 2, y + cardH / 2, cardW, cardH, t)
        self:drawSpecialFlash(animation, layout, t)
    end
    if animation.kind == "play" and animation.card then
        self:drawCard(animation.card, x, y, cardW, cardH)
    else
        self:drawCard(nil, x, y, cardW, cardH)
    end
    if t >= 1 then
        if animation.kind == "draw" then
            self.drawBatchRemaining = math.max(0, (self.drawBatchRemaining or 1) - 1)
            if self.drawBatchRemaining == 0 then
                self.drawBatchAnimationMs = nil
            end
        end
        self.animation = nil
    end
end

function UNM_Window:drawSpecialParticles(animation, cx, cy, cardW, cardH, t)
    local ps = self.state and self.state.publicState or {}
    local kind = specialCardKind(animation.card, ps.sevenZeroEnabled)
    if animation.kind ~= "play" or not kind then
        return
    end
    local color = UNM_Rules.cardColor(animation.card)
    local colors = {}
    if color == "wild" then
        colors = { COLOR_RGB.red, COLOR_RGB.yellow, COLOR_RGB.green, COLOR_RGB.blue }
    else
        colors = { COLOR_RGB[color] or COLOR_RGB.wild }
    end
    local amount = (kind == "swap" or kind == "rotate") and 20 or 10
    local base = tonumber(animation.seq) or 1
    for i = 1, amount do
        local rgb = colors[((i - 1) % #colors) + 1]
        local angle = (base * 0.73 + i * 2.399) % (math.pi * 2)
        local radius = (cardW * 0.42) + (t * cardW * 0.55) + ((i % 3) * 5)
        local px = cx + math.cos(angle) * radius
        local py = cy + math.sin(angle) * radius * 0.62
        local alpha = math.max(0, 0.52 * (1 - t))
        local size = 3 + (i % 3)
        self:drawRect(px, py, size, size, alpha, rgb[1], rgb[2], rgb[3])
    end
end

function UNM_Window:drawSpecialFlash(animation, layout, t)
    local ps = self.state and self.state.publicState or {}
    local kind = specialCardKind(animation.card, ps.sevenZeroEnabled)
    if not kind or not layout then
        return
    end
    local color = UNM_Rules.cardColor(animation.card)
    local rgb = COLOR_RGB[color] or COLOR_RGB.wild
    local handChange = kind == "swap" or kind == "rotate"
    local label = kind == "swap" and "SWAP HANDS" or (kind == "rotate" and "PASS HANDS" or UNM_Rules.cardLabel(animation.card))
    local alpha = math.max(0, (handChange and 0.58 or 0.42) * (1 - t))
    local pulse = math.sin(math.min(1, t) * math.pi)
    local cx = layout.x + layout.w / 2
    local cy = layout.y + layout.h / 2
    local radiusW = layout.w * ((handChange and 0.24 or 0.18) + (handChange and 0.30 or 0.20) * t)
    local radiusH = layout.h * ((handChange and 0.18 or 0.12) + (handChange and 0.24 or 0.16) * t)
    self:drawRect(cx - radiusW, cy - radiusH, radiusW * 2, radiusH * 2, alpha, rgb[1], rgb[2], rgb[3])
    self:drawRectBorder(cx - radiusW, cy - radiusH, radiusW * 2, radiusH * 2, alpha + 0.18, 0.98, 0.86, 0.42)
    self:drawTextCentre(label, cx, cy - 9 - (pulse * 16), 1.00, 0.88, 0.38, math.max(0, 1 - t * 0.35), UIFont.Medium)
end

function UNM_Window:drawWildPicker(x, y, w)
    if not self.pendingWildIndex then
        return y
    end
    self:drawText(UNM.text("IGUI_UNM_ChooseColor", "Choose Color"), x, y, 0.96, 0.78, 0.40, 1, UIFont.Small)
    y = y + 22
    local bw = math.floor((w - 18) / 4)
    for i, color in ipairs(UNM.COLORS) do
        local rgb = COLOR_RGB[color]
        local bx = x + (i - 1) * (bw + 6)
        self.buttons = self.buttons or {}
        table.insert(self.buttons, {
            x = bx,
            y = y,
            w = bw,
            h = 28,
            enabled = true,
            callback = function()
                self:sendAction(UNM.ACTION_PLAY_CARD, { cardIndex = self.pendingWildIndex, color = color })
                self.pendingWildIndex = nil
            end,
        })
        self:drawRect(bx, y, bw, 28, 0.94, rgb[1], rgb[2], rgb[3])
        self:drawRectBorder(bx, y, bw, 28, 0.90, 0.96, 0.86, 0.46)
        self:drawTextCentre(UNM.COLOR_LABEL[color], bx + bw / 2, y + 7, 1, 1, 1, 1, UIFont.Small)
    end
    return y + 38
end

function UNM_Window:drawTargetPicker(x, y, w)
    if not self.pendingTargetIndex then
        return y
    end
    local state = self.state or {}
    local ps = state.publicState or {}
    local targets = {}
    for _, name in ipairs(state.players or {}) do
        if tostring(name) ~= tostring(state.viewerName) and not (ps.eliminated and ps.eliminated[name]) then
            table.insert(targets, name)
        end
    end
    self:drawText(UNM.text("IGUI_UNM_SwapHandsWith", "Swap hands with"), x, y, 0.96, 0.78, 0.40, 1, UIFont.Small)
    y = y + 22
    local gap = 6
    local bw = math.floor((w - gap * math.max(0, #targets - 1)) / math.max(1, #targets))
    for i, name in ipairs(targets) do
        local bx = x + (i - 1) * (bw + gap)
        self:addButton(tostring(name), bx, y, bw, 28, true, function()
            self:sendAction(UNM.ACTION_PLAY_CARD, { cardIndex = self.pendingTargetIndex, targetName = name })
            self.pendingTargetIndex = nil
        end)
    end
    return y + 38
end

function UNM_Window:drawHand(x, y, w, h)
    local hand = self.state and self.state.privateState and self.state.privateState.hand or {}
    self.handArea = { x = x, y = y, w = w, h = h }
    self:drawPanel(x, y, w, h)
    self:drawText(UNM.text("IGUI_UNM_YourHand", "Your Hand"), x + 10, y + 9, 0.96, 0.78, 0.40, 1, UIFont.Small)
    local pickerY = self:drawWildPicker(x + 120, y + 8, w - 132)
    pickerY = self:drawTargetPicker(x + 120, pickerY, w - 132)
    local availableW = math.max(1, w - 24)
    local cardGap = #hand > 80 and 0 or (#hand > 24 and 1 or 4)
    local cardW = clamp(math.floor((availableW - cardGap * math.max(0, #hand - 1)) / math.max(1, #hand)), 4, 72)
    local cardH = math.floor(cardW * 1.42)
    local cardStep = cardW + cardGap
    if #hand > 1 then cardStep = math.min(cardStep, (availableW - cardW) / (#hand - 1)) end
    local totalW = cardW + cardStep * math.max(0, #hand - 1)
    local startX = x + math.max(12, math.floor((w - totalW) / 2))
    local cardY = math.max(y + 42, pickerY + 4)
    self.handRects = {}
    for i = 1, #hand do
        local cx = startX + (i - 1) * cardStep
        local selected = self.pendingWildIndex == i or self.pendingTargetIndex == i
        local playable = not selected and self:isPlayableCardIndex(i)
        self:drawCard(hand[i], cx, cardY, cardW, cardH, selected, playable)
        self.handRects[i] = { x = cx, y = cardY, w = cardW, h = cardH, card = hand[i] }
    end
end

function UNM_Window:drawActions(x, y, w, h)
    self:drawPanel(x, y, w, h)
    self:drawText(UNM.text("IGUI_UNM_Actions", "Actions"), x + 10, y + 9, 0.96, 0.78, 0.40, 1, UIFont.Small)
    local actions = {}
    for _, action in ipairs(self.state and self.state.legalActions or {}) do
        if action and action.id ~= UNM.ACTION_PLAY_CARD then
            table.insert(actions, action)
        end
    end
    local rouletteActive = actions[1] and actions[1].id == UNM.ACTION_ROULETTE_COLOR
    local actionTop = y + 36
    if rouletteActive then
        self:drawTextCentre(
            UNM.text("IGUI_UNM_ColorRoulette", "COLOR ROULETTE"),
            x + w / 2,
            y + 28,
            1.00, 0.76, 0.28, 1,
            UIFont.Small
        )
        self:drawTextCentre(
            UNM.text("IGUI_UNM_ChooseColor", "Choose Color"),
            x + w / 2,
            y + 44,
            0.82, 0.80, 0.72, 1,
            UIFont.Small
        )
        actionTop = y + 58
    end
    local bw = math.floor((w - 28) / 2)
    for i = 1, #actions do
        local action = actions[i]
        local label = action.label
        local buttonColor = nil
        if action.id == UNM.ACTION_START_ROUND then label = UNM.text("IGUI_UNM_Start", "Start") end
        if action.id == UNM.ACTION_ADD_BOT then label = UNM.text("IGUI_UNM_AddBot", "Add Bot") end
        if action.id == UNM.ACTION_REMOVE_BOT then label = UNM.text("IGUI_UNM_RemoveBot", "Remove Bot") end
        if action.id == UNM.ACTION_CALL_UNO then label = UNM.text("IGUI_UNM_CallUno", "Call UNO") end
        if action.id == UNM.ACTION_TOGGLE_MERCY then
            label = (self.state.publicState or {}).mercyEnabled ~= false and UNM.text("IGUI_UNM_MercyOn", "Mercy ON") or UNM.text("IGUI_UNM_MercyOff", "Mercy OFF")
        end
        if action.id == UNM.ACTION_TOGGLE_SEVEN_ZERO then
            label = (self.state.publicState or {}).sevenZeroEnabled ~= false and UNM.text("IGUI_UNM_SevenZeroOn", "0/7 ON") or UNM.text("IGUI_UNM_SevenZeroOff", "0/7 OFF")
        end
        if action.id == UNM.ACTION_DRAW then
            local pending = tonumber((self.state.publicState or {}).pendingDraw) or 0
            label = UNM.text("IGUI_UNM_Draw", "Draw") .. (pending > 0 and (" +" .. tostring(pending)) or "")
        end
        if action.id == UNM.ACTION_ROULETTE_COLOR and action.args and action.args.color then
            local color = tostring(action.args.color)
            local key = "IGUI_UNM_" .. string.upper(string.sub(color, 1, 1)) .. string.sub(color, 2)
            label = UNM.text(key, UNM.COLOR_LABEL[color] or color)
            buttonColor = COLOR_RGB[color]
        end
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        self:addButton(label, x + 10 + col * (bw + 8), actionTop + row * 34, bw, 26, action.enabled, function()
            self:sendAction(action.id, action.args or {})
        end, action.disabledReason, buttonColor)
    end
    local musicLabel = UNM.text("IGUI_UNM_MusicVolume", "Music") .. (UNM_Music.enabled and ": ON" or ": OFF")
    self:addButton(musicLabel, x + 10, y + h - 88, w - 20, 22, true, function()
        self:toggleMusic()
    end)
    self:drawText(UNM.text("IGUI_UNM_MusicVolume", "Music Volume") .. " " .. tostring(math.floor(UNM_Music.volume * 100 + 0.5)) .. "%", x + 10, y + h - 60, 0.76, 0.74, 0.68, 1, UIFont.Small)
    if self.musicVolumeControl then
        self.musicVolumeControl:setX(x + 82)
        self.musicVolumeControl:setY(y + h - 62)
        self.musicVolumeControl:setWidth(w - 92)
        self.musicVolumeControl:setVisible(true)
    end
    self:addButton(UNM.text("IGUI_UNM_Reset", "Reset"), x + 10, y + h - 34, bw, 26, self.state and self.state.owner == self.state.viewerName, function()
        UNM_Client.reset(self.playerNum or 0, self.state)
    end, nil)
    self:addButton(UNM.text("IGUI_UNM_Leave", "Leave"), x + 18 + bw, y + h - 34, bw, 26, true, function()
        self:close()
    end)
end

function UNM_Window:prerender()
    ISCollapsableWindow.prerender(self)
    self.buttons = {}
    self.handRects = {}
    if self.musicVolumeControl then
        self.musicVolumeControl:setVisible(false)
    end
    self:drawRect(0, 16, self.width, self.height - 16, 1, 0.015, 0.018, 0.020)
    if not self.state then
        self:drawTextCentre(UNM.text("IGUI_UNM_OpeningGame", "Opening UNO No Mercy..."), self.width / 2, self.height / 2, 0.9, 0.85, 0.7, 1, UIFont.Medium)
        return
    end
    self:drawHeader()
    local margin = 14
    local top = 82
    local sidebarW = 230
    local actionsH = 210
    local handH = 210
    self:drawPlayers(margin, top, sidebarW, 244)
    self:drawEvents(margin, top + 254, sidebarW, self.height - top - actionsH - 266)
    self:drawActions(margin, self.height - actionsH - margin, sidebarW, actionsH)
    self:drawTable(margin + sidebarW + 12, top, self.width - sidebarW - margin * 2 - 12, self.height - top - handH - margin - 8)
    self:drawHand(margin + sidebarW + 12, self.height - handH - margin, self.width - sidebarW - margin * 2 - 12, handH)
    self:drawAnimation()
end

function UNM_Window:onMouseDown(x, y)
    for i = #self.buttons, 1, -1 do
        local button = self.buttons[i]
        if contains(button, x, y) then
            if button.enabled and button.callback then
                button.callback()
            elseif button.reason and self.playerObj and self.playerObj.Say then
                self.playerObj:Say(tostring(button.reason))
            end
            return true
        end
    end
    for i = #self.handRects, 1, -1 do
        local rect = self.handRects[i]
        if contains(rect, x, y) then
            local card = rect.card
            if UNM_Rules.requiresColor(card) then
                self.pendingWildIndex = i
                self.pendingTargetIndex = nil
            elseif UNM_Rules.requiresTarget(card, self.state and self.state.publicState) then
                self.pendingTargetIndex = i
                self.pendingWildIndex = nil
            else
                self:sendAction(UNM.ACTION_PLAY_CARD, { cardIndex = i })
            end
            return true
        end
    end
    return ISCollapsableWindow.onMouseDown(self, x, y)
end
