require "ISUI/ISCollapsableWindow"
require "PlayableMinigames/PMG_Core"
require "PlayableMinigames/PMG_Cards"
require "PlayableMinigames/PMG_Darts"

PMGWindow = ISCollapsableWindow:derive("PMGWindow")

local FONT_HGT_SMALL = getTextManager and getTextManager():getFontHeight(UIFont.Small) or 14
local CARD_ANIMATION_MS = 260
local SOLITAIRE_AUTO_SOLVE_INITIAL_STEP_MS = 620
local SOLITAIRE_AUTO_SOLVE_MIN_STEP_MS = 140
local SOLITAIRE_AUTO_SOLVE_INITIAL_ANIMATION_MS = 340
local SOLITAIRE_AUTO_SOLVE_MIN_ANIMATION_MS = 115
local SOLITAIRE_AUTO_SOLVE_ACCELERATION_STEPS = 18
local BOARD_MOVE_ANIMATION_MS = 340
local DART_RELEASE_PERIOD_MS = 1420
local HOLDEM_POPUP_MS = 1900
local HOLDEM_POPUP_RISE = 36
local HOLDEM_TURN_PULSE_MS = 1150
local TEXTURES = {}
local SUITS = { "S", "H", "D", "C" }
local SOUND_BY_EVENT = {
    deal = "PMGCardDeal",
    score = "PMGDartScore",
    bust = "PMGLose",
    settle = "PMGTurn",
    win = "PMGWin",
    lose = "PMGLose",
    fold = "PMGChipMove",
    check = "PMGTurn",
    call = "PMGChipMove",
    raise = "PMGChipMove",
    move = "PMGCardDraw",
    board_move = "PMGTurn",
}
local SOUND_AUDIENCE_PLAYERS = "players"
local SOUND_AUDIENCE_VIEWERS = "viewers"
local SOUND_AUDIENCE_BY_EVENT = {
    deal = SOUND_AUDIENCE_VIEWERS,
    score = SOUND_AUDIENCE_VIEWERS,
    settle = SOUND_AUDIENCE_VIEWERS,
    fold = SOUND_AUDIENCE_VIEWERS,
    check = SOUND_AUDIENCE_VIEWERS,
    call = SOUND_AUDIENCE_VIEWERS,
    raise = SOUND_AUDIENCE_VIEWERS,
    move = SOUND_AUDIENCE_VIEWERS,
    board_move = SOUND_AUDIENCE_VIEWERS,
    bust = SOUND_AUDIENCE_PLAYERS,
    win = SOUND_AUDIENCE_PLAYERS,
    lose = SOUND_AUDIENCE_PLAYERS,
}
local HOLDEM_FLOW_SOUND_BY_STEP = {
    blind = "PMGChipMove",
    hole_card = "PMGCardDeal",
    burn = "PMGCardDraw",
    board_card = "PMGCardDeal",
    action = "PMGTurn",
    chips = "PMGChipMove",
    fold = "PMGChipMove",
    check = "PMGTurn",
    showdown_reveal = "PMGCardDeal",
    award = "PMGWin",
    turn = "PMGTurn",
}
local CARD_DRAW_SOUND_ALIASES = {
    "PMGCardDraw",
    "PMGCardDrawLow",
    "PMGCardDrawHigh",
}

local function clamp(value, low, high)
    value = tonumber(value) or low
    return math.max(low, math.min(high, value))
end

local function texture(name)
    if not name then
        return nil
    end
    if not TEXTURES[name] then
        TEXTURES[name] = getTexture("media/textures/PlayableMinigames/" .. name) or getTexture("media/textures/PlayablePool/" .. name)
    end
    return TEXTURES[name]
end

local function top(list)
    return list and list[#list] or nil
end

local function nowMs()
    if getTimestampMs then
        return getTimestampMs()
    end
    return math.floor(os.time() * 1000)
end

local function easeOutCubic(t)
    t = clamp(t, 0, 1)
    local inv = 1 - t
    return 1 - inv * inv * inv
end

local function lerp(a, b, t)
    t = clamp(t, 0, 1)
    return a + (b - a) * t
end

local function randomListItem(list)
    if not list or #list == 0 then
        return nil
    end
    if ZombRand then
        return list[ZombRand(#list) + 1]
    end
    return list[math.random(#list)]
end

local function soundAliasForPlayback(alias)
    if alias == "PMGCardDraw" then
        return randomListItem(CARD_DRAW_SOUND_ALIASES) or alias
    end
    return alias
end

local function playPMGSound(alias, fallback)
    local requestedAlias = alias
    alias = soundAliasForPlayback(alias)
    if alias and getSoundManager then
        local manager = getSoundManager()
        if manager and manager.playUISound then
            local ok, sound = pcall(function()
                return manager:playUISound(alias)
            end)
            if ok and sound then
                return true
            end
        end
    end
    if requestedAlias and requestedAlias ~= alias and getSoundManager then
        local manager = getSoundManager()
        if manager and manager.playUISound then
            local ok, sound = pcall(function()
                return manager:playUISound(requestedAlias)
            end)
            if ok and sound then
                return true
            end
        end
    end
    if fallback and getSoundManager then
        local manager = getSoundManager()
        if manager and manager.playUISound then
            local ok, sound = pcall(function()
                return manager:playUISound(fallback)
            end)
            return ok and sound ~= nil
        end
    end
    return false
end

local function shorten(text, maxChars)
    text = tostring(text or "")
    maxChars = math.max(4, tonumber(maxChars) or 32)
    if string.len(text) <= maxChars then
        return text
    end
    return string.sub(text, 1, maxChars - 3) .. "..."
end

local function measureText(text, font)
    local manager = getTextManager and getTextManager() or nil
    if manager and manager.MeasureStringX then
        local ok, width = pcall(function()
            return manager:MeasureStringX(font or UIFont.Small, tostring(text or ""))
        end)
        if ok and width then
            return width
        end
    end
    return string.len(tostring(text or "")) * 7
end

local function uiText(key, fallback)
    return PMG and PMG.text and PMG.text(key, fallback) or tostring(fallback or key)
end

local function fitText(text, font, maxWidth)
    text = tostring(text or "")
    maxWidth = tonumber(maxWidth) or 0
    if maxWidth <= 0 or measureText(text, font) <= maxWidth then
        return text
    end
    local suffix = "..."
    local limit = math.max(1, string.len(text) - 1)
    while limit > 1 do
        local candidate = string.sub(text, 1, limit) .. suffix
        if measureText(candidate, font) <= maxWidth then
            return candidate
        end
        limit = limit - 1
    end
    return suffix
end

local function wrappedTextLines(text, font, maxWidth, maxLines)
    text = tostring(text or "")
    maxWidth = tonumber(maxWidth) or 0
    maxLines = math.max(1, tonumber(maxLines) or 1)
    local lines = {}
    local current = ""
    for word in string.gmatch(text, "%S+") do
        local candidate = current == "" and word or (current .. " " .. word)
        if maxWidth <= 0 or measureText(candidate, font) <= maxWidth then
            current = candidate
        else
            if current ~= "" then
                table.insert(lines, current)
                current = word
            else
                table.insert(lines, fitText(word, font, maxWidth))
                current = ""
            end
            if #lines >= maxLines then
                lines[#lines] = fitText(lines[#lines], font, maxWidth)
                return lines
            end
        end
    end
    if current ~= "" and #lines < maxLines then
        table.insert(lines, current)
    end
    if #lines == 0 then
        table.insert(lines, "")
    end
    if #lines > maxLines then
        lines[maxLines] = fitText(lines[maxLines], font, maxWidth)
    end
    return lines
end

local function eventText(event)
    if type(event) == "table" then
        return tostring(event.text or "")
    elseif event ~= nil then
        return tostring(event)
    end
    return ""
end

local function formatMoney(value)
    return "$" .. tostring(math.floor((tonumber(value) or 0) + 0.5))
end

local function titleCaseToken(value)
    value = tostring(value or "")
    value = value:gsub("_", " ")
    return value:gsub("(%a)([%w']*)", function(first, rest)
        return string.upper(first) .. string.lower(rest or "")
    end)
end

local function phaseLabel(phase)
    if phase == PMG.PHASE_SETUP then
        return uiText("IGUI_PlayableMinigames_PhaseSetup", "Setup")
    elseif phase == PMG.PHASE_WAITING then
        return uiText("IGUI_PlayableMinigames_PhaseWaiting", "Waiting")
    elseif phase == PMG.PHASE_PLAYING then
        return uiText("IGUI_PlayableMinigames_PhasePlaying", "Playing")
    elseif phase == PMG.PHASE_ROUND_OVER then
        return uiText("IGUI_PlayableMinigames_PhaseRoundOver", "Round over")
    elseif phase == PMG.PHASE_GAME_OVER then
        return uiText("IGUI_PlayableMinigames_PhaseGameOver", "Game over")
    end
    return titleCaseToken(phase or "-")
end

local function roundLabel(value)
    if value == "preflop" then
        return uiText("IGUI_PlayableMinigames_RoundPreflop", "Preflop")
    elseif value == "flop" then
        return uiText("IGUI_PlayableMinigames_RoundFlop", "Flop")
    elseif value == "turn" then
        return uiText("IGUI_PlayableMinigames_RoundTurn", "Turn")
    elseif value == "river" then
        return uiText("IGUI_PlayableMinigames_RoundRiver", "River")
    elseif value == "settled" then
        return uiText("IGUI_PlayableMinigames_RoundSettled", "Settled")
    elseif value == "betting" then
        return uiText("IGUI_PlayableMinigames_RoundBetting", "Betting")
    end
    return titleCaseToken(value or "")
end

local function viewerName(state)
    return state and tostring(state.viewerName or "") or ""
end

local function listContains(list, value)
    if not list or not value then
        return false
    end
    for i = 1, #list do
        if tostring(list[i]) == tostring(value) then
            return true
        end
    end
    return false
end

local function isBoardGameId(gameId)
    return gameId == "chess" or gameId == "checkers"
end

local function pieceColor(piece)
    if not piece then
        return nil
    end
    return string.sub(tostring(piece), 1, 1) == "w" and "white" or "black"
end

local function pieceKind(piece)
    return piece and string.sub(tostring(piece), 2, 2) or nil
end

local function colorLabel(color)
    if color == "white" then
        return uiText("IGUI_PlayableMinigames_White", "White")
    elseif color == "black" then
        return uiText("IGUI_PlayableMinigames_Black", "Black")
    end
    return "-"
end

local function boardPieceLabel(gameId, piece)
    local kind = pieceKind(piece)
    if not kind then
        return ""
    end
    if gameId == "checkers" then
        return kind == "M" and "K" or ""
    end
    return kind
end

local function sameSquare(move, row, col)
    return move and move.toRow == row and move.toCol == col
end

local function boardSquareKey(row, col)
    return tostring(row or "") .. ":" .. tostring(col or "")
end

local function boardMoveSignature(state, ps)
    local move = ps and ps.lastMove or nil
    if not move or not move.fromRow or not move.fromCol or not move.toRow or not move.toCol then
        return nil
    end
    return table.concat({
        tostring(state and state.key or ""),
        tostring(ps.moveCount or 0),
        tostring(move.fromRow),
        tostring(move.fromCol),
        tostring(move.toRow),
        tostring(move.toCol),
        tostring(move.piece or ""),
        tostring(move.resultPiece or ""),
        tostring(move.castle or ""),
        tostring(move.crowned or false),
        tostring(move.promotion or ""),
    }, ":")
end

function PMGWindow:drawRightText(text, rightX, y, r, g, b, a, font)
    text = tostring(text or "")
    self:drawText(text, rightX - measureText(text, font or UIFont.Small), y, r, g, b, a, font or UIFont.Small)
end

function PMGWindow:drawLabelValue(label, value, x, y, w, labelW)
    labelW = labelW or math.min(92, math.floor(w * 0.42))
    self:drawText(fitText(label, UIFont.Small, labelW), x, y, 0.96, 0.78, 0.40, 1, UIFont.Small)
    self:drawText(fitText(value, UIFont.Small, w - labelW - 8), x + labelW + 8, y, 0.86, 0.84, 0.75, 1, UIFont.Small)
end

function PMGWindow:drawWrappedText(text, x, y, w, maxLines, r, g, b, a, font, lineH)
    font = font or UIFont.Small
    lineH = lineH or 17
    local lines = wrappedTextLines(text, font, w, maxLines)
    for i = 1, math.min(#lines, maxLines or #lines) do
        self:drawText(fitText(lines[i], font, w), x, y + (i - 1) * lineH, r, g, b, a, font)
    end
    return y + math.min(#lines, maxLines or #lines) * lineH
end

function PMGWindow:drawSectionLabel(label, x, y)
    self:drawText(tostring(label or ""), x, y, 0.96, 0.78, 0.40, 1, UIFont.Small)
end

function PMGWindow:drawBadge(text, x, y, w, active)
    self:drawRect(x, y, w, 22, active and 0.82 or 0.58, active and 0.18 or 0.04, active and 0.12 or 0.035, active and 0.04 or 0.026)
    self:drawRectBorder(x, y, w, 22, 0.82, active and 0.96 or 0.48, active and 0.70 or 0.36, active and 0.30 or 0.20)
    self:drawTextCentre(fitText(text, UIFont.Small, w - 12), x + w / 2, y + 4, active and 0.98 or 0.78, active and 0.88 or 0.78, active and 0.62 or 0.68, 1, UIFont.Small)
end

function PMGWindow:drawProgressBar(x, y, w, h, value, maxValue, r, g, b)
    maxValue = math.max(1, tonumber(maxValue) or 1)
    value = clamp(tonumber(value) or 0, 0, maxValue)
    self:drawRect(x, y, w, h, 0.50, 0.02, 0.02, 0.02)
    self:drawRect(x, y, math.floor(w * (value / maxValue)), h, 0.82, r or 0.85, g or 0.64, b or 0.26)
    self:drawRectBorder(x, y, w, h, 0.72, 0.46, 0.34, 0.18)
end

local function cardIdentity(card, faceUp)
    if card and faceUp ~= false then
        return tostring(card)
    end
    return nil
end

local function cardDisplayRank(card)
    local rank = tostring(PMG_Cards.rank(card) or "")
    return rank == "T" and "10" or rank
end

local function cardSlotSignature(card, faceUp)
    if card and faceUp ~= false then
        return tostring(card)
    end
    return faceUp == false and "__back" or "__empty"
end

local function responsiveCardWidth(rect, widthUnits, heightUnits, minW, maxW)
    local widthFit = (rect.w - 48) / math.max(1, widthUnits)
    local heightFit = (rect.h - 42) / math.max(1, heightUnits)
    return clamp(math.floor(math.min(widthFit, heightFit)), minW, maxW)
end

local function topPublicCard(pile)
    local entry = top(pile)
    if entry and entry.faceUp then
        return entry.card
    end
    return nil
end

function PMGWindow:legalActionById(actionId)
    if not self.state or not self.state.legalActions then
        return nil
    end
    for i = 1, #self.state.legalActions do
        local action = self.state.legalActions[i]
        if action and action.id == actionId then
            return action
        end
    end
    return nil
end

function PMGWindow:canPerformAction(actionId)
    if not actionId or string.sub(tostring(actionId), 1, 1) == "_" then
        return true
    end
    if self:holdemActionBlocked() then
        return false
    end
    local action = self:legalActionById(actionId)
    if not action then
        return true
    end
    return action.enabled ~= false
end

function PMGWindow:gameStatusLabel()
    local state = self.state or {}
    local ps = state.publicState or {}
    if state.gameId == "darts_501" then
        if ps.winner then
            return uiText("IGUI_PlayableMinigames_PhaseGameOver", "Game over")
        end
        return tostring(ps.variant or "501")
    elseif state.gameId == "blackjack" then
        if ps.round == "playing" then
            return uiText("IGUI_PlayableMinigames_PhasePlaying", "Playing")
        elseif ps.round == "settled" then
            return uiText("IGUI_PlayableMinigames_RoundSettled", "Settled")
        end
        return uiText("IGUI_PlayableMinigames_RoundBetting", "Betting")
    elseif state.gameId == "holdem" then
        return roundLabel(ps.round or state.phase)
    elseif state.gameId == "solitaire" then
        if ps.autoSolving then
            return uiText("IGUI_PlayableMinigames_SolitaireAutoSolving", "Auto-solving")
        elseif ps.won then
            return uiText("IGUI_PlayableMinigames_SolitaireCleared", "Solitaire Cleared")
        elseif ps.lost then
            return uiText("IGUI_PlayableMinigames_SolitaireLost", "No More Moves")
        end
    elseif isBoardGameId(state.gameId) then
        if ps.checkmate then
            return uiText("IGUI_PlayableMinigames_Checkmate", "Checkmate")
        elseif ps.stalemate then
            return uiText("IGUI_PlayableMinigames_Stalemate", "Stalemate")
        elseif ps.check then
            return uiText("IGUI_PlayableMinigames_Check", "Check")
        elseif ps.forceFrom then
            return uiText("IGUI_PlayableMinigames_MustJump", "Must jump")
        elseif ps.winnerColor then
            return uiText("IGUI_PlayableMinigames_GameOver", "Game over")
        end
        return colorLabel(ps.turnColor) .. " " .. uiText("IGUI_PlayableMinigames_ToMove", "to move")
    end
    return phaseLabel(state.phase)
end

function PMGWindow:isViewerPlayer()
    return listContains(self.state and self.state.players, viewerName(self.state))
end

function PMGWindow:isViewerParticipant()
    local name = viewerName(self.state)
    return listContains(self.state and self.state.players, name) or listContains(self.state and self.state.spectators, name)
end

function PMGWindow:canHearStateSound(event)
    local audience = event and event.soundAudience or SOUND_AUDIENCE_BY_EVENT[event and event.kind or ""] or SOUND_AUDIENCE_PLAYERS
    if audience == SOUND_AUDIENCE_VIEWERS then
        return self:isViewerParticipant()
    end
    return self:isViewerPlayer()
end

function PMGWindow:canResetSession()
    local state = self.state
    if not state then
        return false
    end
    local localName = viewerName(state)
    if localName == "" then
        return false
    end
    if not state.owner or tostring(state.owner) == "" then
        return self:isViewerPlayer()
    end
    return tostring(state.owner) == localName
end

function PMGWindow:getHint()
    local state = self.state
    local ps = state and state.publicState or {}
    if not state then
        return uiText("IGUI_PlayableMinigames_Opening", "Opening minigame...")
    end
    local localName = viewerName(state)
    if state.gameId == "darts_501" then
        if ps.winner then
            return tostring(ps.winReason or (tostring(ps.winner) .. " finished 501."))
        end
        if not self:isViewerPlayer() then
            return uiText("IGUI_PlayableMinigames_WatchOnly", "Watch only")
        end
        if state.currentPlayerName == localName then
            return uiText("IGUI_PlayableMinigames_DartsHintTurn", "Click or drag to aim. Press Throw as the release marker crosses center. Finish on a double.")
        end
        return uiText("IGUI_PlayableMinigames_DartsHintWait", "Waiting for ") .. tostring(state.currentPlayerName or "-") .. "."
    elseif state.gameId == "blackjack" then
        if ps.round == "playing" then
            if ps.activePlayer == localName then
                return uiText("IGUI_PlayableMinigames_BlackjackHintTurn", "Choose hit, stand, double, or split for the active hand.")
            end
            return tostring(ps.activePlayer or "-") .. " " .. uiText("IGUI_PlayableMinigames_BlackjackHintOther", "is playing a blackjack hand.")
        elseif ps.round == "settled" then
            return uiText("IGUI_PlayableMinigames_BlackjackHintSettled", "Hand settled. Deal again when ready.")
        end
        return uiText("IGUI_PlayableMinigames_BlackjackHintBet", "Deal a hand when you are ready.")
    elseif state.gameId == "holdem" then
        local flowText = self:holdemCurrentFlowText()
        if flowText then
            return flowText
        end
        if ps.showdown and ps.showdown.winners then
            return uiText("IGUI_PlayableMinigames_HoldemHintShowdown", "Showdown settled. Start the next hand when ready.")
        elseif ps.actionPlayer == localName then
            if (ps.toCall or 0) > 0 then
                return uiText("IGUI_PlayableMinigames_HoldemHintCall", "Call, raise, all in, or fold.")
            end
            return uiText("IGUI_PlayableMinigames_HoldemHintCheck", "Check, raise, all in, or fold.")
        elseif ps.actionPlayer then
            return uiText("IGUI_PlayableMinigames_HoldemHintWait", "Waiting on ") .. tostring(ps.actionPlayer) .. "."
        elseif #(state.players or {}) < 2 then
            return uiText("IGUI_PlayableMinigames_NeedTwoPlayers", "Need 2 players")
        end
        return uiText("IGUI_PlayableMinigames_HoldemHintStart", "Start a hand when the table is ready.")
    elseif state.gameId == "solitaire" then
        if ps.autoSolving then
            return uiText("IGUI_PlayableMinigames_SolitaireHintAuto", "Solved position. Cards are auto-completing.")
        elseif ps.won then
            return uiText("IGUI_PlayableMinigames_SolitaireClearedDetail", "All foundations are complete.")
        elseif ps.lost then
            return tostring(ps.lossReason or uiText("IGUI_PlayableMinigames_SolitaireLostDetail", "This deal cannot make progress."))
        elseif state.owner ~= localName then
            return uiText("IGUI_PlayableMinigames_WatchOnly", "Watch only")
        end
        return uiText("IGUI_PlayableMinigames_SolitaireHintPlay", "Click stock to draw; click a playable waste or tableau card to auto-move it.")
    elseif isBoardGameId(state.gameId) then
        if ps.winnerColor then
            return tostring(ps.winReason or (colorLabel(ps.winnerColor) .. " " .. uiText("IGUI_PlayableMinigames_Won", "won") .. "."))
        elseif ps.stalemate then
            return uiText("IGUI_PlayableMinigames_StalemateHint", "No legal moves remain; the game is drawn.")
        elseif not self:isViewerPlayer() then
            return uiText("IGUI_PlayableMinigames_WatchOnly", "Watch only")
        elseif #(state.players or {}) < 2 then
            return uiText("IGUI_PlayableMinigames_NeedTwoPlayers", "Need 2 players")
        elseif ps.check then
            return colorLabel(ps.turnColor) .. " " .. uiText("IGUI_PlayableMinigames_InCheckHint", "is in check.")
        elseif ps.forceFrom then
            return uiText("IGUI_PlayableMinigames_CheckersContinueJump", "Continue the jump with the highlighted piece.")
        elseif self:viewerBoardColor() == ps.turnColor then
            return uiText("IGUI_PlayableMinigames_BoardHintTurn", "Select one of your pieces, then choose a highlighted destination.")
        end
        return uiText("IGUI_PlayableMinigames_BoardHintWait", "Waiting for ") .. colorLabel(ps.turnColor) .. "."
    end
    return tostring(ps.message or state.status or "")
end

function PMGWindow:updateHoldemFlow(state)
    if not state or state.gameId ~= "holdem" then
        self.holdemFlow = nil
        self.holdemFlowPlayed = nil
        return
    end
    local flow = state.publicState and state.publicState.flow or nil
    if not flow or not flow.id then
        self.holdemFlow = nil
        self.holdemFlowPlayed = nil
        return
    end
    local id = tostring(flow.id)
    if not self.holdemFlow or self.holdemFlow.id ~= id then
        self.holdemFlow = {
            id = id,
            startedAt = nowMs(),
            flow = flow,
        }
        self.holdemFlowPlayed = {}
    else
        self.holdemFlow.flow = flow
    end
end

function PMGWindow:holdemFlowElapsed()
    if not self.holdemFlow then
        return 0
    end
    return math.max(0, nowMs() - (self.holdemFlow.startedAt or nowMs()))
end

function PMGWindow:holdemFlowActive()
    local flow = self.holdemFlow and self.holdemFlow.flow or nil
    if not flow then
        return false
    end
    return self:holdemFlowElapsed() < (tonumber(flow.durationMs) or 0)
end

function PMGWindow:holdemActionBlocked()
    local flow = self.holdemFlow and self.holdemFlow.flow or nil
    return self:holdemFlowActive() and flow and flow.blockActions ~= false
end

function PMGWindow:holdemCurrentFlowText()
    local flow = self.holdemFlow and self.holdemFlow.flow or nil
    local steps = flow and flow.steps or nil
    if not steps or #steps == 0 or not self:holdemFlowActive() then
        return nil
    end
    local elapsed = self:holdemFlowElapsed()
    local current = steps[1]
    for i = 1, #steps do
        local step = steps[i]
        if (tonumber(step.atMs) or 0) <= elapsed then
            current = step
        else
            break
        end
    end
    return current and current.text and tostring(current.text) or nil
end

function PMGWindow:holdemFlowDrawingActive()
    local flow = self.holdemFlow and self.holdemFlow.flow or nil
    if not flow then
        return false
    end
    return self:holdemFlowElapsed() < ((tonumber(flow.durationMs) or 0) + HOLDEM_POPUP_MS)
end

function PMGWindow:holdemStepVisible(kind, matcher)
    local flow = self.holdemFlow and self.holdemFlow.flow or nil
    local steps = flow and flow.steps or nil
    if not steps or #steps == 0 or not self:holdemFlowActive() then
        return true
    end
    local elapsed = self:holdemFlowElapsed()
    local found = false
    for i = 1, #steps do
        local step = steps[i]
        if step and step.kind == kind and (not matcher or matcher(step)) then
            found = true
            if elapsed >= (tonumber(step.atMs) or 0) then
                return true
            end
        end
    end
    return not found
end

function PMGWindow:holdemHoleCardVisible(playerName, cardIndex)
    return self:holdemStepVisible("hole_card", function(step)
        return tostring(step.player or "") == tostring(playerName or "") and tonumber(step.cardIndex) == tonumber(cardIndex)
    end)
end

function PMGWindow:holdemBoardCardVisible(boardIndex)
    return self:holdemStepVisible("board_card", function(step)
        return tonumber(step.boardIndex) == tonumber(boardIndex)
    end)
end

function PMGWindow:holdemShowdownVisible(playerName)
    return self:holdemStepVisible("showdown_reveal", function(step)
        return tostring(step.player or "") == tostring(playerName or "")
    end)
end

function PMGWindow:playHoldemFlowSounds()
    local flowState = self.holdemFlow
    local flow = flowState and flowState.flow or nil
    local steps = flow and flow.steps or nil
    if not steps or #steps == 0 then
        return
    end
    local elapsed = self:holdemFlowElapsed()
    self.holdemFlowPlayed = self.holdemFlowPlayed or {}
    for i = 1, #steps do
        local step = steps[i]
        local key = tostring(flowState.id) .. ":" .. tostring(i)
        if step and not self.holdemFlowPlayed[key] and elapsed >= (tonumber(step.atMs) or 0) then
            self.holdemFlowPlayed[key] = true
            local alias = HOLDEM_FLOW_SOUND_BY_STEP[step.kind or ""]
            if alias then
                playPMGSound(alias, "UIActivateMainMenuItem")
            end
        end
    end
end

function PMGWindow:holdemPopupText(step)
    if not step then
        return nil
    end
    local kind = tostring(step.kind or "")
    local action = tostring(step.action or "")
    if kind == "fold" then
        return uiText("IGUI_PlayableMinigames_Folded", "Folded")
    elseif kind == "check" then
        return uiText("IGUI_PlayableMinigames_ActionCheck", "Check")
    elseif kind == "blind" then
        return formatMoney(step.amount or 0)
    elseif kind == "showdown_reveal" then
        return uiText("IGUI_PlayableMinigames_Show", "Show")
    elseif kind == "award" then
        return uiText("IGUI_PlayableMinigames_Won", "Won")
    elseif kind == "action" then
        if action == "raise" then
            return uiText("IGUI_PlayableMinigames_ActionRaise", "Raise") .. " " .. formatMoney(step.amount or 0)
        elseif action == "call" then
            return uiText("IGUI_PlayableMinigames_ActionCall", "Call") .. " " .. formatMoney(step.amount or 0)
        elseif action == "all_in" then
            return uiText("IGUI_PlayableMinigames_ActionAllIn", "All In")
        end
    end
    return nil
end

function PMGWindow:recordHoldemPlayerAnchor(name, x, y, w, h, cardX, cardY, cardW, cardH)
    if not name then
        return
    end
    self.holdemPlayerAnchors = self.holdemPlayerAnchors or {}
    self.holdemPlayerAnchors[tostring(name)] = {
        x = x,
        y = y,
        w = w,
        h = h,
        cardX = cardX or x,
        cardY = cardY or y,
        cardW = cardW or w,
        cardH = cardH or h,
    }
end

function PMGWindow:drawHoldemFloatingPopup(label, anchor, ageMs)
    if not label or not anchor then
        return
    end
    local progress = clamp((tonumber(ageMs) or 0) / HOLDEM_POPUP_MS, 0, 1)
    local fade = progress < 0.68 and 1 or clamp(1 - ((progress - 0.68) / 0.32), 0, 1)
    if fade <= 0 then
        return
    end
    local width = clamp(measureText(label, UIFont.Small) + 28, 70, 172)
    local height = 24
    local centerX = (anchor.cardX or anchor.x) + (anchor.cardW or anchor.w) / 2
    local x = centerX - width / 2
    local y = (anchor.cardY or anchor.y) - 24 - HOLDEM_POPUP_RISE * easeOutCubic(progress)
    self:drawRect(x, y, width, height, fade * 0.78, 0.05, 0.04, 0.018)
    self:drawRectBorder(x, y, width, height, fade * 0.95, 1.00, 0.86, 0.22)
    self:drawTextCentre(fitText(label, UIFont.Small, width - 12), x + width / 2, y + 5, 1.00, 0.91, 0.28, fade, UIFont.Small)
end

function PMGWindow:drawHoldemFlowPopups()
    local flowState = self.holdemFlow
    local flow = flowState and flowState.flow or nil
    local steps = flow and flow.steps or nil
    if not steps or #steps == 0 or not self:holdemFlowDrawingActive() then
        return
    end
    local elapsed = self:holdemFlowElapsed()
    for i = 1, #steps do
        local step = steps[i]
        local player = step and step.player or nil
        local label = self:holdemPopupText(step)
        local age = elapsed - (tonumber(step and step.atMs) or 0)
        if player and label and age >= 0 and age <= HOLDEM_POPUP_MS then
            self:drawHoldemFloatingPopup(label, self.holdemPlayerAnchors and self.holdemPlayerAnchors[tostring(player)], age)
        end
    end
end

function PMGWindow:drawHoldemTurnSpotlight(ps, localName)
    local player = ps and ps.actionPlayer or nil
    local round = ps and ps.round
    local actionRound = round == "preflop" or round == "flop" or round == "turn" or round == "river"
    if not player or not actionRound then
        self.holdemAttentionPlayer = nil
        self.holdemAttentionStartedAt = nil
        return
    end
    local anchor = self.holdemPlayerAnchors and self.holdemPlayerAnchors[tostring(player)] or nil
    if not anchor then
        return
    end
    local now = nowMs()
    if self.holdemAttentionPlayer ~= tostring(player) then
        self.holdemAttentionPlayer = tostring(player)
        self.holdemAttentionStartedAt = now
    end
    local intro = clamp((now - (self.holdemAttentionStartedAt or now)) / HOLDEM_TURN_PULSE_MS, 0, 1)
    local phase = (now % HOLDEM_TURN_PULSE_MS) / HOLDEM_TURN_PULSE_MS
    local pulse = 0.5 + 0.5 * math.sin(phase * math.pi * 2)
    local alpha = 0.58 + 0.34 * pulse
    local expand = math.floor(4 + 10 * pulse + 16 * (1 - intro))
    self:drawRect(anchor.x - 4, anchor.y - 4, anchor.w + 8, anchor.h + 8, 0.08 + 0.07 * pulse, 1.00, 0.78, 0.16)
    self:drawRectBorder(anchor.x - 5, anchor.y - 5, anchor.w + 10, anchor.h + 10, alpha, 1.00, 0.88, 0.24)
    self:drawRectBorder(anchor.x - expand, anchor.y - expand, anchor.w + expand * 2, anchor.h + expand * 2, 0.46 * (1 - intro + 0.35 * pulse), 1.00, 0.82, 0.18)
    local cardX = anchor.cardX or anchor.x
    local cardY = anchor.cardY or anchor.y
    local cardW = anchor.cardW or anchor.w
    local cardH = anchor.cardH or anchor.h
    self:drawRectBorder(cardX - 4, cardY - 4, cardW + 8, cardH + 8, alpha, 1.00, 0.92, 0.32)
    local label = tostring(player) == tostring(localName) and uiText("IGUI_PlayableMinigames_YourTurn", "Your Turn") or uiText("IGUI_PlayableMinigames_ActiveSeat", "TURN")
    local width = clamp(measureText(label, UIFont.Small) + 26, 72, 150)
    local x = cardX + cardW / 2 - width / 2
    local y = cardY - 31 - math.floor(4 * pulse)
    self:drawRect(x, y, width, 24, 0.82, 0.06, 0.045, 0.016)
    self:drawRectBorder(x, y, width, 24, alpha, 1.00, 0.88, 0.26)
    self:drawTextCentre(fitText(label, UIFont.Small, width - 12), x + width / 2, y + 5, 1.00, 0.90, 0.30, 1, UIFont.Small)
end

function PMGWindow:buildBoardMoveAnimation(state, ps, signature)
    local move = ps and ps.lastMove or nil
    local board = ps and ps.board or nil
    if not move or not board then
        return nil
    end
    local steps = {}
    local function appendStep(step)
        if not step or not step.fromRow or not step.fromCol or not step.toRow or not step.toCol then
            return
        end
        local piece = step.piece or (board[step.toRow] and board[step.toRow][step.toCol]) or step.resultPiece
        if not piece then
            return
        end
        steps[#steps + 1] = {
            piece = piece,
            resultPiece = step.resultPiece or piece,
            fromRow = step.fromRow,
            fromCol = step.fromCol,
            toRow = step.toRow,
            toCol = step.toCol,
        }
    end
    appendStep(move)
    appendStep(move.rookMove)
    if #steps == 0 then
        return nil
    end
    return {
        gameId = state and state.gameId,
        signature = signature,
        startedAt = nowMs(),
        durationMs = BOARD_MOVE_ANIMATION_MS,
        steps = steps,
    }
end

function PMGWindow:updateBoardMoveAnimation(previousState, nextState)
    if not (nextState and isBoardGameId(nextState.gameId)) then
        self.boardMoveAnimation = nil
        self.boardMoveSignature = nil
        return
    end

    local ps = nextState.publicState or {}
    local signature = boardMoveSignature(nextState, ps)
    if not signature then
        self.boardMoveAnimation = nil
        self.boardMoveSignature = nil
        return
    end
    if self.boardMoveSignature == signature then
        return
    end

    local previousPs = previousState and previousState.publicState or nil
    local canAnimate = previousState
        and previousState.gameId == nextState.gameId
        and previousState.key == nextState.key
        and previousPs
        and tonumber(ps.moveCount or 0) > tonumber(previousPs.moveCount or -1)
    self.boardMoveSignature = signature
    if canAnimate then
        self.boardMoveAnimation = self:buildBoardMoveAnimation(nextState, ps, signature)
    else
        self.boardMoveAnimation = nil
    end
end

function PMGWindow:solitaireAutoSolveRunKey(state)
    if not state or state.gameId ~= "solitaire" then
        return nil
    end
    return table.concat({
        tostring(state.key or ""),
        tostring(state.owner or ""),
    }, ":")
end

function PMGWindow:resetSolitaireAutoSolveCadence()
    self.nextSolitaireAutoSolveAt = nil
    self.solitaireAutoSolveCadence = nil
end

function PMGWindow:ensureSolitaireAutoSolveCadence(state)
    local ps = state and state.publicState or {}
    if not state or state.gameId ~= "solitaire" or not ps.autoSolving or ps.won or ps.lost then
        self:resetSolitaireAutoSolveCadence()
        return nil
    end

    local runKey = self:solitaireAutoSolveRunKey(state)
    local moveCount = tonumber(ps.moves) or 0
    local cadence = self.solitaireAutoSolveCadence
    if not cadence or cadence.runKey ~= runKey or moveCount < (cadence.startMoveCount or 0) then
        cadence = {
            runKey = runKey,
            startedAt = nowMs(),
            startMoveCount = moveCount,
            stepCount = 0,
        }
        self.solitaireAutoSolveCadence = cadence
    else
        cadence.stepCount = math.max(tonumber(cadence.stepCount) or 0, moveCount - (cadence.startMoveCount or moveCount))
    end
    return cadence
end

function PMGWindow:solitaireAutoSolveProgress()
    local cadence = self.solitaireAutoSolveCadence
    local steps = cadence and tonumber(cadence.stepCount) or 0
    return easeOutCubic(steps / SOLITAIRE_AUTO_SOLVE_ACCELERATION_STEPS)
end

function PMGWindow:solitaireAutoSolveStepDelayMs()
    return math.floor(lerp(SOLITAIRE_AUTO_SOLVE_INITIAL_STEP_MS, SOLITAIRE_AUTO_SOLVE_MIN_STEP_MS, self:solitaireAutoSolveProgress()) + 0.5)
end

function PMGWindow:cardAnimationDurationMs()
    local ps = self.state and self.state.publicState or {}
    if self.state and self.state.gameId == "solitaire" and ps.autoSolving and self.solitaireAutoSolveCadence then
        return math.floor(lerp(SOLITAIRE_AUTO_SOLVE_INITIAL_ANIMATION_MS, SOLITAIRE_AUTO_SOLVE_MIN_ANIMATION_MS, self:solitaireAutoSolveProgress()) + 0.5)
    end
    return CARD_ANIMATION_MS
end

function PMGWindow:setState(state)
    local previousState = self.state
    self:updateBoardMoveAnimation(previousState, state)
    self:updateHoldemFlow(state)
    self.state = state
    self.title = state and state.publicState and state.publicState.gameName or uiText("IGUI_PlayableMinigames_WindowTitle", "Playable Minigame")
    local ps = state and state.publicState or {}
    if state and state.gameId == "solitaire" then
        self.selected = nil
    end
    if state and isBoardGameId(state.gameId) then
        local signature = tostring(state.key or "") .. ":" .. tostring(ps.moveCount or 0) .. ":" .. tostring(ps.turnColor or "")
        if self.boardStateSignature ~= signature then
            self.boardSelection = nil
            self.pendingPromotion = nil
            self.boardStateSignature = signature
        end
    else
        self.boardSelection = nil
        self.pendingPromotion = nil
        self.boardStateSignature = nil
    end
    if not state or state.gameId ~= "solitaire" then
        self:resetSolitaireAutoSolveCadence()
    elseif ps.won or ps.lost or ps.autoSolving then
        self.selected = nil
        self:ensureSolitaireAutoSolveCadence(state)
        if ps.autoSolving and not self.nextSolitaireAutoSolveAt then
            self.nextSolitaireAutoSolveAt = nowMs() + self:solitaireAutoSolveStepDelayMs()
        end
    elseif not ps.autoSolving then
        self:resetSolitaireAutoSolveCadence()
    end
    if not (state and state.gameId == "holdem" and state.publicState and state.publicState.flow) then
        self:playStateSound(state)
    end
end

function PMGWindow:playStateSound(state)
    local event = state and state.events and state.events[1]
    if not event then
        return
    end
    if not self:canHearStateSound(event) then
        return
    end
    local eventIdentity = event.id or event.seq or event.sequence or tostring(event.kind or "") .. ":" .. tostring(event.text or "")
    local signature = tostring(state.key or "") .. ":" .. tostring(eventIdentity)
    if signature == self.lastEventSound then
        return
    end
    self.lastEventSound = signature
    if state.gameId == "darts_501" and event.kind == "score" then
        playPMGSound("PMGDartHit", "UIActivateMainMenuItem")
    end
    local alias = SOUND_BY_EVENT[event.kind or ""]
    if state.gameId == "solitaire" and event.kind == "deal" then
        alias = "PMGCardDraw"
    end
    if alias then
        playPMGSound(alias, "UIActivateMainMenuItem")
    end
end

function PMGWindow:layout()
    local topY = self:titleBarHeight()
    local margin = 10
    local contentW = math.max(1, self.width - margin * 2)
    local contentH = math.max(1, self.height - topY - margin * 2)
    local sidebarW = clamp(math.floor(contentW * 0.22), 220, 340)
    local playW = math.max(1, contentW - sidebarW - 10)
    self.playRect = { x = margin, y = topY + margin, w = playW, h = contentH }
    self.sidebarRect = { x = margin + playW + 10, y = topY + margin, w = sidebarW, h = contentH }
end

function PMGWindow:addActionButton(label, x, y, w, h, action, args, enabled, disabledReason)
    enabled = enabled ~= false
    if enabled and self:holdemActionBlocked() and action and string.sub(tostring(action), 1, 1) ~= "_" then
        enabled = false
        disabledReason = self:holdemCurrentFlowText() or uiText("IGUI_PlayableMinigames_HoldemHintWait", "Waiting on ")
    end
    self.actionButtons = self.actionButtons or {}
    table.insert(self.actionButtons, { x = x, y = y, w = w, h = h, label = label, action = action, args = args or {}, enabled = enabled, disabledReason = disabledReason })
    if not enabled and disabledReason and disabledReason ~= "" and not self.sidebarActionHint then
        self.sidebarActionHint = tostring(label or action) .. ": " .. tostring(disabledReason)
    end
    self:drawRect(x, y, w, h, enabled and 0.70 or 0.46, enabled and 0.08 or 0.04, enabled and 0.07 or 0.04, enabled and 0.05 or 0.045)
    self:drawRectBorder(x, y, w, h, enabled and 0.86 or 0.44, enabled and 0.62 or 0.36, enabled and 0.44 or 0.30, enabled and 0.23 or 0.18)
    local text = fitText(label, UIFont.Small, w - 10)
    self:drawTextCentre(text, x + w / 2, y + math.floor((h - FONT_HGT_SMALL) / 2), enabled and 0.94 or 0.62, enabled and 0.86 or 0.58, enabled and 0.66 or 0.50, 1, UIFont.Small)
end

function PMGWindow:addClickZone(kind, x, y, w, h, data)
    self.clickZones = self.clickZones or {}
    data = data or {}
    data.kind = kind
    data.x = x
    data.y = y
    data.w = w
    data.h = h
    table.insert(self.clickZones, data)
    return data
end

function PMGWindow:holdemRaiseAction()
    if not self.state or not self.state.legalActions then
        return nil
    end
    for i = 1, #self.state.legalActions do
        local action = self.state.legalActions[i]
        if action and action.id == "raise" then
            return action
        end
    end
    return nil
end

function PMGWindow:holdemRaiseAmount(action)
    action = action or self:holdemRaiseAction()
    if not action then
        return nil
    end
    local metadata = action.metadata or {}
    local minAmount = tonumber(metadata.min) or tonumber(action.args and action.args.amount) or 0
    local maxAmount = tonumber(metadata.max) or minAmount
    local amount = tonumber(self.holdemRaiseSelectedAmount) or tonumber(action.args and action.args.amount) or minAmount
    amount = clamp(amount, minAmount, maxAmount)
    self.holdemRaiseSelectedAmount = amount
    return amount, minAmount, maxAmount, tonumber(metadata.step) or 10
end

function PMGWindow:adjustHoldemRaiseAmount(direction)
    local action = self:holdemRaiseAction()
    if not action or action.enabled == false then
        return true
    end
    local amount, minAmount, maxAmount, step = self:holdemRaiseAmount(action)
    if not amount then
        return true
    end
    self.holdemRaiseSelectedAmount = clamp(amount + (tonumber(direction) or 0) * math.max(1, step or 1), minAmount, maxAmount)
    playPMGSound("PMGChipMove", "UIActivateMainMenuItem")
    return true
end

function PMGWindow:focusKeyForAction(button)
    return "action:" .. tostring(button.action or "") .. ":" .. tostring(button.label or "") .. ":" .. tostring(math.floor(button.x or 0)) .. ":" .. tostring(math.floor(button.y or 0))
end

function PMGWindow:focusKeyForZone(zone)
    return "zone:" .. tostring(zone.kind or "") .. ":" .. tostring(zone.row or "") .. ":" .. tostring(zone.col or "") .. ":" .. tostring(zone.index or "") .. ":" .. tostring(zone.suit or "") .. ":" .. tostring(zone.hand or "")
end

function PMGWindow:buildFocusTargets()
    local oldKey = self.focusTargets and self.focusIndex and self.focusTargets[self.focusIndex] and self.focusTargets[self.focusIndex].key or nil
    local targets = {}
    for i = 1, #(self.actionButtons or {}) do
        local button = self.actionButtons[i]
        targets[#targets + 1] = {
            kind = "action",
            key = self:focusKeyForAction(button),
            x = button.x,
            y = button.y,
            w = button.w,
            h = button.h,
            button = button,
            enabled = button.enabled ~= false,
        }
    end
    for i = 1, #(self.clickZones or {}) do
        local zone = self.clickZones[i]
        targets[#targets + 1] = {
            kind = "zone",
            key = self:focusKeyForZone(zone),
            x = zone.x,
            y = zone.y,
            w = zone.w,
            h = zone.h,
            zone = zone,
            enabled = true,
        }
    end
    if self.state and self.state.gameId == "darts_501" and self.dartBoardRect then
        local r = self.dartBoardRect
        targets[#targets + 1] = {
            kind = "dart_board",
            key = "dart_board",
            x = r.x,
            y = r.y,
            w = r.size,
            h = r.size,
            enabled = self:canPerformAction("throw"),
        }
    end
    self.focusTargets = targets
    if #targets == 0 then
        self.focusIndex = nil
        return
    end
    if oldKey then
        for i = 1, #targets do
            if targets[i].key == oldKey then
                self.focusIndex = i
                return
            end
        end
    end
    self.focusIndex = clamp(self.focusIndex or 1, 1, #targets)
end

function PMGWindow:focusedTarget()
    if not self.focusTargets or #self.focusTargets == 0 then
        return nil
    end
    self.focusIndex = clamp(self.focusIndex or 1, 1, #self.focusTargets)
    return self.focusTargets[self.focusIndex]
end

function PMGWindow:drawFocusTarget()
    local target = self:focusedTarget()
    if not target then
        return
    end
    local alpha = target.enabled == false and 0.42 or 0.92
    self:drawRectBorder(target.x - 3, target.y - 3, target.w + 6, target.h + 6, alpha, 0.98, 0.86, 0.34)
    self:drawRectBorder(target.x - 1, target.y - 1, target.w + 2, target.h + 2, alpha, 0.20, 0.55, 0.92)
    if target.kind == "dart_board" then
        local aim = self:getDartAim(true)
        if aim then
            local cx = target.x + target.w / 2
            local cy = target.y + target.h / 2
            local radius = target.w / 2
            local ax = cx + aim.x * radius
            local ay = cy + aim.y * radius
            self:drawRectBorder(ax - 10, ay - 10, 20, 20, 0.90, 0.98, 0.86, 0.34)
            self:drawRect(ax - 2, ay - 2, 4, 4, 0.92, 0.98, 0.86, 0.34)
        end
    end
end

function PMGWindow:drawTablePanel(rect)
    local felt = texture("card_table_felt.png")
    self:drawRect(rect.x, rect.y, rect.w, rect.h, 0.96, 0.04, 0.035, 0.03)
    if felt then
        self:drawTextureScaled(felt, rect.x + 6, rect.y + 6, rect.w - 12, rect.h - 12, 0.90, 1, 1, 1)
    else
        self:drawRect(rect.x + 6, rect.y + 6, rect.w - 12, rect.h - 12, 0.90, 0.02, 0.22, 0.12)
    end
    self:drawRectBorder(rect.x, rect.y, rect.w, rect.h, 0.92, 0.58, 0.38, 0.18)
end

function PMGWindow:drawCard(card, x, y, w, h, faceUp, selected)
    faceUp = faceUp ~= false
    if not faceUp then
        local back = texture("card_back.png")
        if back then
            self:drawTextureScaled(back, x, y, w, h, 1, 1, 1, 1)
        else
            self:drawRect(x, y, w, h, 1, 0.12, 0.15, 0.20)
        end
        self:drawRectBorder(x, y, w, h, selected and 1 or 0.50, selected and 0.86 or 0.10, selected and 0.74 or 0.16, selected and 0.48 or 0.18)
        return
    end
    local front = texture("cards/" .. tostring(card or "") .. ".png")
    if front then
        self:drawTextureScaled(front, x, y, w, h, 1, 1, 1, 1)
        if selected then
            self:drawRectBorder(x - 1, y - 1, w + 2, h + 2, 1, 1.00, 0.82, 0.32)
        end
        return
    end
    self:drawRect(x, y, w, h, 1, 0.86, 0.82, 0.70)
    self:drawRectBorder(x, y, w, h, selected and 1 or 0.95, selected and 1 or 0.15, selected and 0.82 or 0.12, selected and 0.32 or 0.09)
    local color = PMG_Cards.color(card) == "red" and { 0.70, 0.08, 0.06 } or { 0.04, 0.04, 0.04 }
    self:drawText(cardDisplayRank(card) .. tostring(PMG_Cards.suit(card)), x + 6, y + 5, color[1], color[2], color[3], 1, UIFont.Small)
end

function PMGWindow:sourceRect(sourceKey, fallback)
    if sourceKey and self.currentCardSources and self.currentCardSources[sourceKey] then
        return self.currentCardSources[sourceKey]
    end
    if sourceKey and self.previousCardSources and self.previousCardSources[sourceKey] then
        return self.previousCardSources[sourceKey]
    end
    return fallback
end

function PMGWindow:recordCardSlot(slotKey, card, faceUp, rect)
    self.currentCardSlots = self.currentCardSlots or {}
    self.currentCardById = self.currentCardById or {}
    local slot = {
        key = slotKey,
        card = card,
        faceUp = faceUp ~= false,
        signature = cardSlotSignature(card, faceUp),
        x = rect.x,
        y = rect.y,
        w = rect.w,
        h = rect.h,
    }
    self.currentCardSlots[slotKey] = slot
    local id = cardIdentity(card, faceUp)
    if id then
        self.currentCardById[id] = slot
    end
end

function PMGWindow:findCardStart(slotKey, card, faceUp, target, sourceKey)
    local previous = self.previousCardSlots and self.previousCardSlots[slotKey] or nil
    local id = cardIdentity(card, faceUp)
    if id then
        if self.previousCardById and self.previousCardById[id] then
            return self.previousCardById[id]
        end
        if previous and previous.signature == "__back" then
            return previous
        end
        return self:sourceRect(sourceKey, target)
    end
    if previous then
        if sourceKey and previous.signature == "__empty" then
            return self:sourceRect(sourceKey, target)
        end
        return previous
    end
    return self:sourceRect(sourceKey, target)
end

function PMGWindow:drawCardSlot(slotKey, card, x, y, w, h, faceUp, selected, sourceKey)
    local target = { x = x, y = y, w = w, h = h }
    local signature = cardSlotSignature(card, faceUp)
    self.cardAnimations = self.cardAnimations or {}
    self.lastCardSignatures = self.lastCardSignatures or {}
    local anim = self.cardAnimations[slotKey]
    if self.lastCardSignatures[slotKey] ~= signature then
        local from = self:findCardStart(slotKey, card, faceUp, target, sourceKey)
        if from and (math.abs((from.x or x) - x) > 2 or math.abs((from.y or y) - y) > 2 or math.abs((from.w or w) - w) > 2) then
            anim = {
                signature = signature,
                started = nowMs(),
                from = { x = from.x or x, y = from.y or y, w = from.w or w, h = from.h or h },
                to = target,
            }
            self.cardAnimations[slotKey] = anim
        else
            self.cardAnimations[slotKey] = nil
            anim = nil
        end
        self.lastCardSignatures[slotKey] = signature
    end

    if anim and anim.signature == signature then
        local t = easeOutCubic((nowMs() - anim.started) / self:cardAnimationDurationMs())
        if t < 1 then
            local from = anim.from
            local to = anim.to
            x = from.x + (to.x - from.x) * t
            y = from.y + (to.y - from.y) * t
            w = from.w + (to.w - from.w) * t
            h = from.h + (to.h - from.h) * t
        else
            self.cardAnimations[slotKey] = nil
        end
    end

    self:recordCardSlot(slotKey, card, faceUp, target)
    self:drawCard(card, x, y, w, h, faceUp, selected)
end

function PMGWindow:recordCardSource(sourceKey, x, y, w, h)
    if not sourceKey then
        return
    end
    self.currentCardSources = self.currentCardSources or {}
    self.currentCardSources[sourceKey] = { x = x, y = y, w = w, h = h }
end

function PMGWindow:beginCardFrame()
    self.currentCardSlots = {}
    self.currentCardById = {}
    self.currentCardSources = {}
end

function PMGWindow:endCardFrame()
    self.previousCardSlots = self.currentCardSlots or {}
    self.previousCardById = self.currentCardById or {}
    self.previousCardSources = self.currentCardSources or {}
end

function PMGWindow:drawEmptySlot(x, y, w, h, label)
    self:drawRect(x, y, w, h, 0.30, 0.02, 0.02, 0.02)
    self:drawRectBorder(x, y, w, h, 0.38, 0.16, 0.22, 0.18)
    if label then
        self:drawTextCentre(tostring(label), x + w / 2, y + math.floor((h - FONT_HGT_SMALL) / 2), 0.80, 0.74, 0.58, 0.95, UIFont.Small)
    end
end

function PMGWindow:drawChip(x, y, size)
    local chip = texture("chip.png")
    if chip then
        self:drawTextureScaled(chip, x, y, size, size, 1, 1, 1, 1)
    else
        self:drawRect(x, y, size, size, 0.90, 0.55, 0.08, 0.08)
        self:drawRectBorder(x, y, size, size, 0.95, 0.95, 0.72, 0.42)
    end
end

local dartsCheckoutHint

function PMGWindow:drawSidebar()
    local state = self.state
    local ps = state and state.publicState or {}
    local s = self.sidebarRect
    self.sidebarActionHint = nil
    self:drawRect(s.x, s.y, s.w, s.h, 0.82, 0.03, 0.025, 0.018)
    self:drawRectBorder(s.x, s.y, s.w, s.h, 0.78, 0.50, 0.36, 0.18)
    local x = s.x + 14
    local y = s.y + 14
    local innerW = s.w - 28
    local actionTop = s.y + s.h - (state and state.gameId == "holdem" and 284 or 178)
    local maxChars = math.floor(innerW / 8)
    local title = ps.gameName or uiText("IGUI_PlayableMinigames_WindowTitle", "Playable Minigame")
    self:drawText(fitText(title, UIFont.Small, innerW - 94), x, y, 0.98, 0.82, 0.42, 1, UIFont.Small)
    self:drawBadge(self:gameStatusLabel(), s.x + s.w - 104, y - 2, 90, state and state.phase == PMG.PHASE_PLAYING)
    y = y + 31
    self:drawRect(x, y, innerW, 40, 0.55, 0.18, 0.09, 0.025)
    self:drawRectBorder(x, y, innerW, 40, 0.82, 0.95, 0.62, 0.28)
    self:drawWrappedText(PMG.BETA_MINIGAME_WARNING or "Beta minigame: active development and may not work.", x + 8, y + 6, innerW - 16, 2, 0.98, 0.86, 0.58, 1, UIFont.Small, 16)
    y = y + 48
    self:drawLabelValue(uiText("IGUI_PlayableMinigames_Status", "Status"), self:gameStatusLabel(), x, y, innerW, 54)
    y = y + 22
    self:drawLabelValue(uiText("IGUI_PlayableMinigames_Turn", "Turn"), tostring(state and state.currentPlayerName or "-"), x, y, innerW, 54)
    y = y + 28

    for i = 1, math.max(1, #(state and state.players or {})) do
        local name = state and state.players and state.players[i] or "Open seat"
        local active = name == (state and state.currentPlayerName)
        self:drawRect(x, y, innerW, 30, active and 0.78 or 0.55, active and 0.18 or 0.04, active and 0.11 or 0.035, active and 0.04 or 0.025)
        self:drawRectBorder(x, y, innerW, 30, 0.82, active and 0.95 or 0.46, active and 0.68 or 0.34, active and 0.28 or 0.18)
        local seatLabel = active and uiText("IGUI_PlayableMinigames_ActiveSeat", "TURN") or (i == 1 and uiText("IGUI_PlayableMinigames_Player1", "PLAYER 1") or uiText("IGUI_PlayableMinigames_Player", "PLAYER ") .. tostring(i))
        self:drawText(seatLabel, x + 10, y + 7, 0.96, 0.78, 0.40, 1, UIFont.Small)
        self:drawText(fitText(name, UIFont.Small, innerW - 102), x + 92, y + 7, 0.86, 0.84, 0.75, 1, UIFont.Small)
        y = y + 35
        if y + 34 > actionTop then
            break
        end
    end

    y = self:drawGameStats(x, y + 6, innerW)
    if y + 58 < actionTop then
        y = y + 12
        self:drawSectionLabel(uiText("IGUI_PlayableMinigames_Now", "Now"), x, y)
        y = y + 22
        local nowH = state and state.gameId == "holdem" and 68 or 42
        self:drawRect(x, y, innerW, nowH, 0.42, 0.02, 0.02, 0.018)
        self:drawRectBorder(x, y, innerW, nowH, 0.66, 0.38, 0.30, 0.18)
        local textY = self:drawWrappedText(self:getHint(), x + 7, y + 7, innerW - 14, state and state.gameId == "holdem" and 2 or 1, 0.90, 0.88, 0.78, 1, UIFont.Small, 17)
        local latest = state and state.events and eventText(state.events[1]) or nil
        if latest and latest ~= "" then
            self:drawWrappedText(latest, x + 7, textY, innerW - 14, state and state.gameId == "holdem" and 2 or 1, 0.72, 0.82, 0.86, 1, UIFont.Small, 17)
        end
        y = y + nowH + 12
    end
    if y + 52 < actionTop then
        local events = state and state.events or {}
        local rowH = 18
        local rows = math.min(#events, math.max(0, math.floor((actionTop - y - 12) / rowH)))
        for i = 2, rows + 1 do
            self:drawText(fitText(eventText(events[i]), UIFont.Small, innerW), x, y, 0.72, 0.74, 0.68, 0.95, UIFont.Small)
            y = y + rowH
        end
    end

    local actionHint = nil
    local hasEnabledAction = false
    for i = 1, #(state and state.legalActions or {}) do
        local action = state.legalActions[i]
        if action and action.enabled ~= false then
            hasEnabledAction = true
        end
    end
    for i = 1, #(state and state.legalActions or {}) do
        local action = state.legalActions[i]
        if not hasEnabledAction and action and action.enabled == false and action.disabledReason and action.disabledReason ~= "" then
            actionHint = tostring(action.label or action.id) .. ": " .. tostring(action.disabledReason)
            break
        end
    end
    self:drawSectionLabel(uiText("IGUI_PlayableMinigames_Actions", "Actions"), x, actionTop - 42)
    if actionHint then
        self:drawText(fitText(actionHint, UIFont.Small, innerW), x, actionTop - 21, 0.76, 0.78, 0.70, 1, UIFont.Small)
    end
    self:drawSidebarActions(s.x + 12, actionTop, s.w - 24)
    self:addActionButton(uiText("IGUI_PlayableMinigames_ActionReset", "Reset"), s.x + 12, s.y + s.h - 42, math.floor((s.w - 34) / 2), 26, "_reset", {}, self:canResetSession(), uiText("IGUI_PlayableMinigames_OwnerOnly", "Owner only"))
    self:addActionButton(uiText("IGUI_PlayableMinigames_ActionLeave", "Leave"), s.x + s.w - 12 - math.floor((s.w - 34) / 2), s.y + s.h - 42, math.floor((s.w - 34) / 2), 26, "_leave", {})
end

function PMGWindow:drawGameStats(x, y, w)
    local state = self.state or {}
    local ps = state.publicState or {}
    if state.gameId == "darts_501" then
        self:drawText(uiText("IGUI_PlayableMinigames_Scores", "Scores"), x, y, 0.96, 0.78, 0.40, 1, UIFont.Small)
        y = y + 24
        for i = 1, #(state.players or {}) do
            local name = state.players[i]
            local active = name == state.currentPlayerName
            self:drawText(fitText(name, UIFont.Small, w - 68), x, y, active and 0.96 or 0.82, active and 0.86 or 0.80, active and 0.62 or 0.72, 1, UIFont.Small)
            self:drawRightText(tostring(ps.scores and ps.scores[name] or 501), x + w, y, 0.96, 0.86, 0.62, 1, UIFont.Small)
            y = y + 20
        end
        local throws = #(ps.turnThrows or {})
        self:drawLabelValue(uiText("IGUI_PlayableMinigames_Throws", "Throws"), tostring(throws) .. "/3", x, y + 4, w, 72)
        y = y + 26
        self:drawLabelValue(uiText("IGUI_PlayableMinigames_DartsTurnScore", "This turn"), tostring(ps.turnScore or 0), x, y, w, 72)
        y = y + 22
        local current = state.currentPlayerName
        local currentScore = ps.scores and ps.scores[current] or 501
        self:drawLabelValue(uiText("IGUI_PlayableMinigames_DartsFinish", "Finish"), dartsCheckoutHint(currentScore), x, y, w, 72)
        y = y + 22
    elseif state.gameId == "blackjack" then
        self:drawText(uiText("IGUI_PlayableMinigames_Bankroll", "Bankroll"), x, y, 0.96, 0.78, 0.40, 1, UIFont.Small)
        y = y + 24
        for i = 1, #(state.players or {}) do
            local name = state.players[i]
            local amount = ps.bankrolls and ps.bankrolls[name] or 0
            self:drawText(fitText(name, UIFont.Small, w - 78), x, y, 0.82, 0.80, 0.72, 1, UIFont.Small)
            self:drawRightText(formatMoney(amount), x + w, y, 0.96, 0.86, 0.62, 1, UIFont.Small)
            y = y + 20
        end
        if ps.activePlayer then
            self:drawLabelValue(uiText("IGUI_PlayableMinigames_Hand", "Hand"), tostring(ps.activePlayer) .. " #" .. tostring(ps.activeHand or 1), x, y + 4, w, 52)
            y = y + 26
        end
    elseif state.gameId == "holdem" then
        self:drawText(uiText("IGUI_PlayableMinigames_Pot", "Pot"), x, y, 0.96, 0.78, 0.40, 1, UIFont.Small)
        self:drawRightText(formatMoney(ps.pot or 0), x + w, y, 0.96, 0.86, 0.62, 1, UIFont.Small)
        y = y + 26
        for i = 1, #(state.players or {}) do
            local name = state.players[i]
            local active = name == ps.actionPlayer
            self:drawText(fitText(name, UIFont.Small, w - 82), x, y, active and 0.96 or 0.82, active and 0.86 or 0.80, active and 0.62 or 0.72, 1, UIFont.Small)
            self:drawRightText(formatMoney(ps.stacks and ps.stacks[name] or 0), x + w, y, 0.96, 0.86, 0.62, 1, UIFont.Small)
            y = y + 20
        end
        self:drawLabelValue(uiText("IGUI_PlayableMinigames_ToCall", "To call"), formatMoney(ps.toCall or 0), x, y + 4, w, 72)
        y = y + 26
    elseif state.gameId == "solitaire" then
        self:drawText(uiText("IGUI_PlayableMinigames_Foundations", "Foundations"), x, y, 0.96, 0.78, 0.40, 1, UIFont.Small)
        self:drawRightText(tostring(ps.foundationCount or 0) .. "/52", x + w, y, 0.96, 0.86, 0.62, 1, UIFont.Small)
        y = y + 24
        self:drawText(uiText("IGUI_PlayableMinigames_Moves", "Moves"), x, y, 0.96, 0.78, 0.40, 1, UIFont.Small)
        self:drawRightText(tostring(ps.moves or 0), x + w, y, 0.82, 0.80, 0.72, 1, UIFont.Small)
        y = y + 22
        self:drawLabelValue(uiText("IGUI_PlayableMinigames_DrawMode", "Draw"), tostring(ps.drawCount or 1), x, y, w, 72)
        y = y + 22
        self:drawProgressBar(x, y + 2, w, 8, ps.foundationCount or 0, 52, 0.86, 0.68, 0.30)
        y = y + 18
    elseif isBoardGameId(state.gameId) then
        self:drawText(uiText("IGUI_PlayableMinigames_Turn", "Turn"), x, y, 0.96, 0.78, 0.40, 1, UIFont.Small)
        self:drawRightText(colorLabel(ps.turnColor), x + w, y, 0.96, 0.86, 0.62, 1, UIFont.Small)
        y = y + 24
        local seats = ps.seats or {}
        local first = state.gameId == "checkers" and "black" or "white"
        local second = first == "white" and "black" or "white"
        for _, color in ipairs({ first, second }) do
            self:drawText(colorLabel(color), x, y, 0.96, 0.78, 0.40, 1, UIFont.Small)
            self:drawRightText(fitText(tostring(seats[color] or "-"), UIFont.Small, math.floor(w * 0.58)), x + w, y, 0.82, 0.80, 0.72, 1, UIFont.Small)
            y = y + 20
        end
        self:drawLabelValue(uiText("IGUI_PlayableMinigames_Moves", "Moves"), tostring(ps.moveCount or 0), x, y + 4, w, 72)
        y = y + 26
        if state.gameId == "chess" then
            local capW = #(ps.captured and ps.captured.white or {})
            local capB = #(ps.captured and ps.captured.black or {})
            self:drawLabelValue(uiText("IGUI_PlayableMinigames_Captured", "Captured"), tostring(capW) .. "/" .. tostring(capB), x, y, w, 72)
            y = y + 22
        elseif state.gameId == "checkers" then
            local captured = ps.captured or {}
            self:drawLabelValue(uiText("IGUI_PlayableMinigames_Captured", "Captured"), tostring(captured.black or 0) .. "/" .. tostring(captured.white or 0), x, y, w, 72)
            y = y + 22
        end
    end
    return y
end

function PMGWindow:drawHoldemSidebarActions(x, y, w)
    local state = self.state or {}
    local sourceActions = state.legalActions or {}
    local gameplayById = {}
    local botActions = {}
    for i = 1, #sourceActions do
        local action = sourceActions[i]
        if action and action.metadata and action.metadata.bot then
            table.insert(botActions, action)
        elseif action and action.id then
            gameplayById[action.id] = action
        end
    end

    local actions = {}
    for _, id in ipairs({ "start_hand", "check", "call", "raise", "all_in", "fold" }) do
        if gameplayById[id] then
            table.insert(actions, gameplayById[id])
        end
    end

    local bw = math.floor((w - 8) / 2)
    local rowH = 29
    local buttonH = 24
    for i = 1, #actions do
        local action = actions[i]
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local label = action.label
        local args = action.args or {}
        if action.id == "call" then
            local amount = tonumber(action.metadata and action.metadata.amount)
            if amount and amount > 0 then
                label = uiText("IGUI_PlayableMinigames_ActionCall", "Call") .. " " .. formatMoney(amount)
            end
        elseif action.id == "raise" then
            local amount = self:holdemRaiseAmount(action)
            if amount then
                label = uiText("IGUI_PlayableMinigames_ActionRaise", "Raise") .. " $" .. tostring(amount)
                args = PMG.copyTable(args)
                args.amount = amount
            end
        end
        self:addActionButton(label, x + col * (bw + 8), y + row * rowH, bw, buttonH, action.id, args, action.enabled, action.disabledReason)
    end

    local cursorY = y + math.ceil(#actions / 2) * rowH
    local raise = self:holdemRaiseAction()
    if raise and raise.metadata then
        local amount, minAmount, maxAmount = self:holdemRaiseAmount(raise)
        local enabled = raise.enabled ~= false and maxAmount and minAmount and maxAmount > minAmount
        self:addActionButton("-", x, cursorY, 34, buttonH, "_raise_down", {}, enabled, raise.disabledReason)
        self:drawRect(x + 42, cursorY, w - 84, buttonH, 0.58, 0.02, 0.018, 0.014)
        self:drawRectBorder(x + 42, cursorY, w - 84, buttonH, 0.72, 0.46, 0.34, 0.18)
        self:drawTextCentre("$" .. tostring(amount or 0) .. " / $" .. tostring(maxAmount or 0), x + w / 2, cursorY + 4, 0.86, 0.84, 0.74, 1, UIFont.Small)
        self:addActionButton("+", x + w - 34, cursorY, 34, buttonH, "_raise_up", {}, enabled, raise.disabledReason)
        cursorY = cursorY + rowH
    end

    if #botActions > 0 then
        cursorY = cursorY + 4
        self:drawSectionLabel(uiText("IGUI_PlayableMinigames_Bots", "Bots"), x, cursorY)
        cursorY = cursorY + 19
        for i = 1, #botActions do
            local action = botActions[i]
            local col = (i - 1) % 2
            local row = math.floor((i - 1) / 2)
            self:addActionButton(action.label, x + col * (bw + 8), cursorY + row * rowH, bw, buttonH, action.id, action.args or {}, action.enabled, action.disabledReason)
        end
    end
end

function PMGWindow:drawSidebarActions(x, y, w)
    local state = self.state or {}
    local actions = state.legalActions or {}
    if state.gameId == "holdem" and actions and #actions > 0 then
        self:drawHoldemSidebarActions(x, y, w)
        return
    end
    if isBoardGameId(state.gameId) then
        actions = {}
        for i = 1, #(state.legalActions or {}) do
            local action = state.legalActions[i]
            if action and action.metadata and action.metadata.bot then
                table.insert(actions, action)
            end
        end
    end
    if actions and #actions > 0 then
        local bw = math.floor((w - 8) / 2)
        for i = 1, math.min(8, #actions) do
            local action = actions[i]
            local col = (i - 1) % 2
            local row = math.floor((i - 1) / 2)
            local label = action.label
            local args = action.args or {}
            if state.gameId == "holdem" and action.id == "raise" then
                local amount = self:holdemRaiseAmount(action)
                if amount then
                    label = uiText("IGUI_PlayableMinigames_ActionRaise", "Raise") .. " $" .. tostring(amount)
                    args = PMG.copyTable(args)
                    args.amount = amount
                end
            end
            self:addActionButton(label, x + col * (bw + 8), y + row * 32, bw, 26, action.id, args, action.enabled, action.disabledReason)
        end
        if state.gameId == "holdem" and #actions <= 6 then
            local raise = self:holdemRaiseAction()
            if raise and raise.metadata then
                local amount, minAmount, maxAmount = self:holdemRaiseAmount(raise)
                local controlY = y + 96
                local enabled = raise.enabled ~= false and maxAmount and minAmount and maxAmount > minAmount
                self:addActionButton("-", x, controlY, 34, 24, "_raise_down", {}, enabled, raise.disabledReason)
                self:drawRect(x + 42, controlY, w - 84, 24, 0.58, 0.02, 0.018, 0.014)
                self:drawRectBorder(x + 42, controlY, w - 84, 24, 0.72, 0.46, 0.34, 0.18)
                self:drawTextCentre("$" .. tostring(amount or 0) .. " / $" .. tostring(maxAmount or 0), x + w / 2, controlY + 4, 0.86, 0.84, 0.74, 1, UIFont.Small)
                self:addActionButton("+", x + w - 34, controlY, 34, 24, "_raise_up", {}, enabled, raise.disabledReason)
            end
        end
        return
    end
    if state.gameId == "blackjack" then
        local bw = math.floor((w - 8) / 2)
        self:addActionButton(uiText("IGUI_PlayableMinigames_ActionDeal10", "Deal $10"), x, y, bw, 26, "start_round", { bet = 10 })
        self:addActionButton(uiText("IGUI_PlayableMinigames_ActionHit", "Hit"), x + bw + 8, y, bw, 26, "hit", {})
        self:addActionButton(uiText("IGUI_PlayableMinigames_ActionStand", "Stand"), x, y + 32, bw, 26, "stand", {})
        self:addActionButton(uiText("IGUI_PlayableMinigames_ActionDouble", "Double"), x + bw + 8, y + 32, bw, 26, "double", {})
    elseif state.gameId == "holdem" then
        local bw = math.floor((w - 8) / 2)
        local ps = state.publicState or {}
        self:addActionButton(uiText("IGUI_PlayableMinigames_ActionStart", "Start"), x, y, bw, 26, "start_hand", {})
        self:addActionButton(uiText("IGUI_PlayableMinigames_ActionFold", "Fold"), x + bw + 8, y, bw, 26, "fold", {})
        self:addActionButton(uiText("IGUI_PlayableMinigames_ActionCall", "Call"), x, y + 32, bw, 26, "call", {})
        self:addActionButton(uiText("IGUI_PlayableMinigames_ActionRaise", "Raise"), x + bw + 8, y + 32, bw, 26, "raise", { amount = (ps.toCall or 0) + 20 })
    elseif state.gameId == "solitaire" then
        local bw = math.floor((w - 8) / 2)
        self:addActionButton(uiText("IGUI_PlayableMinigames_ActionUndo", "Undo"), x, y, bw, 26, "undo", {})
        self:addActionButton(uiText("IGUI_PlayableMinigames_ActionNew1", "New 1"), x + bw + 8, y, bw, 26, "new_game", { drawCount = 1 })
        self:addActionButton(uiText("IGUI_PlayableMinigames_ActionNew3", "New 3"), x, y + 32, bw, 26, "new_game", { drawCount = 3 })
    end
end

dartsCheckoutHint = function(score)
    score = tonumber(score) or 501
    if score == 50 then
        return uiText("IGUI_PlayableMinigames_DartsFinishBull", "Finish: Bull")
    end
    if score >= 2 and score <= 40 and score % 2 == 0 then
        return uiText("IGUI_PlayableMinigames_DartsFinishDouble", "Finish: D") .. tostring(math.floor(score / 2))
    end
    if score <= 1 then
        return uiText("IGUI_PlayableMinigames_DartsNeedReset", "Bust risk")
    end
    local target = PMG_Darts.checkoutTarget(score, 3)
    return uiText("IGUI_PlayableMinigames_DartsAim", "Aim") .. " " .. tostring(target.label or "T20")
end

function PMGWindow:drawDartMarker(cx, cy, radius, throw, alpha, size)
    if not throw then
        return
    end
    local hx = cx + (tonumber(throw.x) or 0) * radius
    local hy = cy + (tonumber(throw.y) or 0) * radius
    local dart = texture("dart.png")
    size = size or 22
    if dart then
        self:drawTextureScaled(dart, hx - size / 2, hy - size / 2, size, size, alpha or 1, 1, 1, 1)
    else
        self:drawRect(hx - 3, hy - 3, 6, 6, alpha or 1, 0.92, 0.82, 0.24)
    end
end

function PMGWindow:drawDartAimReticle(cx, cy, radius)
    if not self:canPerformAction("throw") then
        return
    end
    local aim = self:getDartAim(true)
    if not aim then
        return
    end
    local ax = cx + (aim.x or 0) * radius
    local ay = cy + (aim.y or 0) * radius
    local timing = self:dartTiming()
    local spread = 13 + math.floor((1 - (timing.quality or 0)) * 24)
    self:drawRectBorder(ax - spread, ay - spread, spread * 2, spread * 2, 0.34, 0.96, 0.82, 0.36)
    self:drawRectBorder(ax - 12, ay - 12, 24, 24, 0.86, 0.96, 0.82, 0.36)
    self:drawRectBorder(ax - 3, ay - 3, 6, 6, 0.95, 0.96, 0.82, 0.36)
    self:drawRect(ax - 1, ay - 15, 2, 8, 0.85, 0.96, 0.82, 0.36)
    self:drawRect(ax - 1, ay + 7, 2, 8, 0.85, 0.96, 0.82, 0.36)
    self:drawRect(ax - 15, ay - 1, 8, 2, 0.85, 0.96, 0.82, 0.36)
    self:drawRect(ax + 7, ay - 1, 8, 2, 0.85, 0.96, 0.82, 0.36)
end

function PMGWindow:drawDartTimingMeter(x, y, w, h)
    if not self:canPerformAction("throw") then
        return
    end
    local timing = self:dartTiming()
    local centerX = x + w / 2
    local needleX = x + (timing.offset + 1) * 0.5 * w
    self:drawRect(x, y, w, h, 0.62, 0.025, 0.020, 0.016)
    self:drawRect(centerX - 18, y, 36, h, 0.38, 0.20, 0.58, 0.24)
    self:drawRectBorder(x, y, w, h, 0.72, 0.46, 0.34, 0.18)
    self:drawRect(needleX - 2, y - 4, 4, h + 8, 0.96, 0.96, 0.82, 0.36)
    local label = uiText("IGUI_PlayableMinigames_DartsRelease", "Release")
    local quality = math.floor((timing.quality or 0) * 100 + 0.5)
    self:drawTextCentre(fitText(label .. " " .. tostring(quality) .. "%", UIFont.Small, w), centerX, y + h + 5, 0.86, 0.84, 0.75, 1, UIFont.Small)
end

function PMGWindow:drawDarts()
    local r = self.playRect
    local ps = self.state.publicState or {}
    self:drawTablePanel(r)
    local boardAreaW = math.max(1, r.w)
    local radius = math.floor(math.min(r.w, r.h) * 0.43)
    local cx = r.x + math.floor(r.w * 0.47)
    local cy = r.y + math.floor(r.h * 0.50)
    local board = texture("dartboard.png")
    if board then
        self:drawTextureScaled(board, cx - radius, cy - radius, radius * 2, radius * 2, 1, 1, 1, 1)
    else
        self:drawRect(cx - radius, cy - radius, radius * 2, radius * 2, 0.85, 0.14, 0.13, 0.10)
        self:drawRectBorder(cx - radius, cy - radius, radius * 2, radius * 2, 0.9, 0.80, 0.70, 0.42)
    end
    self.dartBoardRect = { x = cx - radius, y = cy - radius, size = radius * 2 }

    local throws = ps.turnThrows or {}
    for i = 1, #throws do
        self:drawDartMarker(cx, cy, radius, throws[i], i == #throws and 1 or 0.62, i == #throws and 26 or 18)
    end
    self:drawDartAimReticle(cx, cy, radius)
    if self:canPerformAction("throw") then
        local meterW = math.min(360, math.max(180, r.w - 48))
        local meterX = cx - meterW / 2
        local meterY = math.min(r.y + r.h - 48, cy + radius + 14)
        self:drawDartTimingMeter(meterX, meterY, meterW, 12)
        local aim = self:getDartAim(false)
        if aim then
            local planned = PMG_Darts.scorePoint(aim.x, aim.y)
            local label = uiText("IGUI_PlayableMinigames_DartsAim", "Aim") .. ": " .. tostring(planned.label or "-")
            self:drawTextCentre(fitText(label, UIFont.Small, meterW), cx, meterY - 18, 0.92, 0.84, 0.58, 1, UIFont.Small)
        end
    end

    if ps.lastThrow then
        if ps.lastThrow.aimX and ps.lastThrow.aimY then
            local ax = cx + (tonumber(ps.lastThrow.aimX) or 0) * radius
            local ay = cy + (tonumber(ps.lastThrow.aimY) or 0) * radius
            self:drawRectBorder(ax - 8, ay - 8, 16, 16, 0.70, 0.90, 0.82, 0.42)
        end
        local label = uiText("IGUI_PlayableMinigames_LastThrow", "Last throw") .. ": " .. tostring(ps.lastThrow.label or "-") .. " / " .. tostring(ps.lastThrow.score or 0)
        local tagW = math.min(300, math.max(160, measureText(label, UIFont.Small) + 26))
        local tagX = r.x + r.w - tagW - 18
        local tagY = r.y + 18
        self:drawRect(tagX, tagY, tagW, 30, 0.62, 0.025, 0.020, 0.016)
        self:drawRectBorder(tagX, tagY, tagW, 30, 0.72, 0.46, 0.34, 0.18)
        self:drawTextCentre(fitText(label, UIFont.Small, tagW - 16), tagX + tagW / 2, tagY + 7, 0.86, 0.84, 0.74, 1, UIFont.Small)
    end
    if ps.winner then
        local bannerW = math.min(440, boardAreaW - 42)
        local bx = r.x + math.floor((r.w - bannerW) / 2)
        local by = r.y + r.h - 60
        self:drawRect(bx, by, bannerW, 36, 0.80, 0.06, 0.045, 0.028)
        self:drawRectBorder(bx, by, bannerW, 36, 0.92, 0.82, 0.66, 0.30)
        self:drawTextCentre(fitText(tostring(ps.winReason or (tostring(ps.winner) .. " finished 501.")), UIFont.Small, bannerW - 24), bx + bannerW / 2, by + 9, 0.96, 0.88, 0.66, 1, UIFont.Small)
    end
end

local function blackjackHands(state)
    return state.privateState and state.privateState.blackjackHands or {}
end

local function blackjackDisplayHands(state)
    local privateHands = blackjackHands(state)
    if #privateHands > 0 then
        return privateHands, uiText("IGUI_PlayableMinigames_YourHands", "Your hands"), true
    end
    local ps = state and state.publicState or {}
    local name = ps.activePlayer or (state and state.players and state.players[1]) or nil
    local publicHands = name and ps.hands and ps.hands[name] or {}
    local hands = {}
    for i = 1, #publicHands do
        local hand = publicHands[i]
        hands[i] = {
            cardCount = hand.count or 0,
            bet = hand.bet,
            status = hand.status,
            total = hand.total,
        }
    end
    local title = name and (tostring(name) .. " " .. uiText("IGUI_PlayableMinigames_Hands", "hands")) or uiText("IGUI_PlayableMinigames_Hands", "Hands")
    return hands, title, false
end

function PMGWindow:drawBlackjack()
    local r = self.playRect
    local ps = self.state.publicState or {}
    self:drawTablePanel(r)
    local hands, handsTitle, showCards = blackjackDisplayHands(self.state)
    local largestHand = 2
    for i = 1, #hands do
        largestHand = math.max(largestHand, #((hands[i] or {}).cards or {}), tonumber((hands[i] or {}).cardCount) or 0)
    end
    local cardW = responsiveCardWidth(r, math.max(6.2, largestHand + 2.2), math.max(3.2, #hands * 1.05 + 2.1), 54, 124)
    local cardH = math.floor(cardW * 1.4)
    local gap = clamp(math.floor(cardW * 0.16), 8, 18)
    local x = r.x + math.max(22, math.floor(r.w * 0.06))
    local dealerY = r.y + math.max(36, math.floor(r.h * 0.12))
    local handY = r.y + math.max(dealerY + cardH + 70, math.floor(r.h * 0.55))
    self:drawText(uiText("IGUI_PlayableMinigames_Dealer", "Dealer"), x, dealerY - 31, 0.96, 0.82, 0.46, 1, UIFont.Medium)
    local visible = ps.dealer and ps.dealer.visible or {}
    local dealerTotal = ps.dealer and ps.dealer.total or nil
    if dealerTotal then
        self:drawBadge(uiText("IGUI_PlayableMinigames_Total", "Total") .. " " .. tostring(dealerTotal), x + 96, dealerY - 32, 92, true)
    end
    for i = 1, math.max(2, #visible) do
        self:drawCardSlot("blackjack:dealer:" .. tostring(i), visible[i], x + (i - 1) * (cardW + gap), dealerY, cardW, cardH, visible[i] ~= nil, false, "blackjack:shoe")
    end
    self:addClickZone("blackjack_stand", x, dealerY, cardW * 3, cardH, {})

    local shoeX = r.x + r.w - cardW - math.max(28, math.floor(r.w * 0.04))
    self:recordCardSource("blackjack:shoe", shoeX, dealerY, cardW, cardH)
    self:drawCardSlot("blackjack:shoe", nil, shoeX, dealerY, cardW, cardH, false)
    self:addClickZone("blackjack_shoe", shoeX, dealerY, cardW, cardH, {})
    local chipSize = clamp(math.floor(cardW * 0.42), 28, 44)
    self:drawChip(shoeX + math.floor((cardW - chipSize) / 2), dealerY + cardH + math.floor(cardW * 0.20), chipSize)
    self:drawTextCentre(uiText("IGUI_PlayableMinigames_Shoe", "Shoe"), shoeX + cardW / 2, dealerY - 21, 0.80, 0.78, 0.68, 1, UIFont.Small)

    self:drawText(handsTitle, x, handY - 31, 0.96, 0.82, 0.46, 1, UIFont.Medium)
    for h = 1, math.max(1, #hands) do
        local hand = hands[h] or { cards = {} }
        local rowY = handY + (h - 1) * (cardH + math.floor(cardW * 0.32))
        local active = ps.activeHand == h and ps.activePlayer == viewerName(self.state)
        local cardCount = math.max(#(hand.cards or {}), tonumber(hand.cardCount) or 0)
        local total = hand.total or PMG_Cards.blackjackTotal(hand.cards or {})
        local info = uiText("IGUI_PlayableMinigames_Hand", "Hand") .. " " .. tostring(h) ..
            "  " .. uiText("IGUI_PlayableMinigames_Total", "Total") .. " " .. tostring(total or 0) ..
            "  " .. uiText("IGUI_PlayableMinigames_Bet", "Bet") .. " " .. formatMoney(hand.bet or 0)
        if hand.status and hand.status ~= "playing" then
            info = info .. "  " .. titleCaseToken(hand.status)
        end
        self:drawRect(x - 8, rowY - 24, math.min(r.w - 44, math.max(cardW * 3, measureText(info, UIFont.Small) + 24)), 22, active and 0.72 or 0.42, active and 0.16 or 0.02, active and 0.10 or 0.02, active and 0.035 or 0.018)
        self:drawRectBorder(x - 8, rowY - 24, math.min(r.w - 44, math.max(cardW * 3, measureText(info, UIFont.Small) + 24)), 22, 0.62, active and 0.92 or 0.42, active and 0.68 or 0.32, active and 0.28 or 0.18)
        self:drawText(fitText(info, UIFont.Small, r.w - 64), x, rowY - 20, 0.84, 0.82, 0.72, 1, UIFont.Small)
        for c = 1, cardCount do
            local card = hand.cards and hand.cards[c] or nil
            self:drawCardSlot("blackjack:hand:" .. tostring(h) .. ":" .. tostring(c), card, x + (c - 1) * (cardW + gap), rowY, cardW, cardH, showCards and card ~= nil, false, "blackjack:shoe")
        end
        self:addClickZone("blackjack_hand", x, rowY, math.max(cardW, cardCount * (cardW + gap)), cardH, { hand = h })
    end
    if ps.round == "settled" then
        local bannerW = math.min(420, r.w - 80)
        local bx = r.x + math.floor((r.w - bannerW) / 2)
        local by = r.y + r.h - 58
        self:drawRect(bx, by, bannerW, 34, 0.76, 0.06, 0.045, 0.028)
        self:drawRectBorder(bx, by, bannerW, 34, 0.88, 0.82, 0.66, 0.30)
        self:drawTextCentre(uiText("IGUI_PlayableMinigames_BlackjackSettled", "Blackjack hand settled"), bx + bannerW / 2, by + 8, 0.96, 0.88, 0.66, 1, UIFont.Small)
    end
end

local function holdemRoundHasCards(round)
    return round == "preflop" or round == "flop" or round == "turn" or round == "river"
end

function PMGWindow:drawHoldemSeatPanel(name, seatIndex, x, y, w, h, cardW, cardH, gap, ps, revealedHole, localName)
    local folded = ps.folded and ps.folded[name]
    local allIn = ps.allIn and ps.allIn[name]
    local acting = ps.actionPlayer == name
    local dealer = ps.dealerSeat == seatIndex
    local bet = ps.bets and ps.bets[name] or 0
    local shown = revealedHole and revealedHole[name] or nil
    local liveCards = holdemRoundHasCards(ps.round) and not folded
    local cardAreaW = cardW * 2 + gap
    local textW = math.max(70, w - cardAreaW - 24)

    self:drawRect(x, y, w, h, acting and 0.80 or 0.62, acting and 0.16 or 0.035, acting and 0.105 or 0.030, acting and 0.040 or 0.022)
    self:drawRectBorder(x, y, w, h, acting and 0.92 or 0.72, acting and 0.94 or 0.48, acting and 0.70 or 0.36, acting and 0.30 or 0.18)
    self:drawText(fitText(name, UIFont.Small, textW), x + 10, y + 8, folded and 0.54 or 0.88, folded and 0.54 or 0.85, folded and 0.50 or 0.74, 1, UIFont.Small)
    self:drawText(formatMoney(ps.stacks and ps.stacks[name] or 0), x + 10, y + 27, 0.96, 0.82, 0.46, 1, UIFont.Small)

    local status = ""
    if acting then
        status = uiText("IGUI_PlayableMinigames_ActiveSeat", "TURN")
    elseif folded then
        status = uiText("IGUI_PlayableMinigames_Folded", "Folded")
    elseif allIn then
        status = uiText("IGUI_PlayableMinigames_AllIn", "All in")
    elseif dealer then
        status = "D"
    end
    if status ~= "" then
        self:drawBadge(status, x + 10, y + h - 29, math.min(86, textW), acting)
    elseif bet > 0 then
        self:drawText(fitText(uiText("IGUI_PlayableMinigames_Bet", "Bet") .. " " .. formatMoney(bet), UIFont.Small, textW), x + 10, y + h - 24, 0.74, 0.86, 0.82, 1, UIFont.Small)
    end
    if dealer and status ~= "D" then
        self:drawBadge("D", x + math.min(104, textW + 2), y + h - 29, 28, false)
    end

    local cardX = x + w - cardAreaW - 10
    local cardY = y + math.floor((h - cardH) / 2)
    self:recordHoldemPlayerAnchor(name, x, y, w, h, cardX, cardY, cardAreaW, cardH)
    if shown and #shown > 0 then
        for i = 1, 2 do
            local xCard = cardX + (i - 1) * (cardW + gap)
            if self:holdemShowdownVisible(name) then
                self:drawCardSlot("holdem:seat:" .. tostring(seatIndex) .. ":" .. tostring(i), shown[i], xCard, cardY, cardW, cardH, true, false, "holdem:deck")
            elseif liveCards then
                self:drawCardSlot("holdem:seat:" .. tostring(seatIndex) .. ":" .. tostring(i), nil, xCard, cardY, cardW, cardH, false, false, "holdem:deck")
            else
                self:drawEmptySlot(xCard, cardY, cardW, cardH, "")
            end
        end
    elseif liveCards and tostring(name) ~= tostring(localName) then
        for i = 1, 2 do
            local xCard = cardX + (i - 1) * (cardW + gap)
            if self:holdemHoleCardVisible(name, i) then
                self:drawCardSlot("holdem:seat:" .. tostring(seatIndex) .. ":" .. tostring(i), nil, xCard, cardY, cardW, cardH, false, false, "holdem:deck")
            else
                self:drawEmptySlot(xCard, cardY, cardW, cardH, "")
            end
        end
    end
end

function PMGWindow:drawHoldem()
    local r = self.playRect
    local ps = self.state.publicState or {}
    local localName = viewerName(self.state)
    local players = self.state.players or {}
    local viewerIsPlayer = listContains(players, localName)
    self.holdemPlayerAnchors = {}
    self:drawTablePanel(r)

    local cardW = responsiveCardWidth(r, 8.2, 5.45, 46, 108)
    local cardH = math.floor(cardW * 1.4)
    local gap = clamp(math.floor(cardW * 0.16), 8, 16)
    local opponentCardW = clamp(math.floor(cardW * 0.54), 34, 62)
    local opponentCardH = math.floor(opponentCardW * 1.4)
    local opponentGap = clamp(math.floor(opponentCardW * 0.14), 5, 9)
    local seatGap = clamp(math.floor(r.w * 0.018), 12, 28)
    local seatW = clamp(math.min(math.floor(r.w * 0.24), math.floor((r.w - seatGap * 2 - 30) / 3)), 172, 326)
    local seatH = math.max(86, opponentCardH + 20)
    local topBandH = seatH + 98
    local heroY = viewerIsPlayer and (r.y + r.h - cardH - 46) or (r.y + r.h - seatH - 28)
    local boardAreaTop = r.y + topBandH
    local boardAreaBottom = heroY - 24
    local boardY = boardAreaTop + math.max(18, math.floor((boardAreaBottom - boardAreaTop - cardH) / 2))
    boardY = clamp(boardY, r.y + topBandH, math.max(r.y + topBandH, heroY - cardH - 42))
    local boardW = cardW * 5 + gap * 4
    local boardX = r.x + math.floor((r.w - boardW) / 2)
    local deckX = r.x + r.w - cardW - math.max(26, math.floor(r.w * 0.035))
    local deckY = boardY
    self:recordCardSource("holdem:deck", deckX, deckY, cardW, cardH)

    local statusW = math.min(420, r.w - 120)
    local statusX = r.x + math.floor((r.w - statusW) / 2)
    local statusY = boardY - 58
    self:drawRect(statusX, statusY, statusW, 38, 0.62, 0.025, 0.020, 0.016)
    self:drawRectBorder(statusX, statusY, statusW, 38, 0.72, 0.50, 0.38, 0.18)
    self:drawTextCentre(fitText(self:holdemCurrentFlowText() or roundLabel(ps.round or "waiting"), UIFont.Small, statusW - 20), statusX + statusW / 2, statusY + 5, 0.76, 0.86, 0.72, 1, UIFont.Small)
    local potLine = uiText("IGUI_PlayableMinigames_Pot", "Pot") .. " " .. formatMoney(ps.pot or 0)
    if (ps.toCall or 0) > 0 then
        potLine = potLine .. "    " .. uiText("IGUI_PlayableMinigames_ToCall", "To call") .. " " .. formatMoney(ps.toCall)
    end
    self:drawTextCentre(fitText(potLine, UIFont.Small, statusW - 20), statusX + statusW / 2, statusY + 21, 0.96, 0.82, 0.46, 1, UIFont.Small)

    for i = 1, 5 do
        local card = (ps.board or {})[i]
        local x = boardX + (i - 1) * (cardW + gap)
        if card and self:holdemBoardCardVisible(i) then
            self:drawCardSlot("holdem:board:" .. tostring(i), card, x, boardY, cardW, cardH, true, false, "holdem:deck")
        else
            self:drawEmptySlot(x, boardY, cardW, cardH, "")
        end
    end
    self:drawCardSlot("holdem:deck", nil, deckX, deckY, cardW, cardH, false)
    self:drawTextCentre(uiText("IGUI_PlayableMinigames_Deck", "Deck"), deckX + cardW / 2, deckY + cardH + 8, 0.80, 0.78, 0.68, 1, UIFont.Small)
    local chipSize = clamp(math.floor(cardW * 0.40), 28, 42)
    self:drawChip(r.x + r.w / 2 - math.floor(chipSize / 2), boardY + cardH + clamp(math.floor(cardW * 0.16), 14, 24), chipSize)

    local hole = self.state.privateState and self.state.privateState.hole or {}
    local revealedHole = self.state.privateState and self.state.privateState.revealedHole or {}
    if viewerIsPlayer then
        local holeW = cardW * 2 + gap
        local holeX = r.x + math.floor((r.w - holeW) / 2)
        local heroName = localName ~= "" and localName or uiText("IGUI_PlayableMinigames_YourHand", "Your hand")
        local heroMeta = heroName .. "  " .. formatMoney(ps.stacks and ps.stacks[localName] or 0)
        local heroBet = ps.bets and ps.bets[localName] or 0
        if heroBet > 0 then
            heroMeta = heroMeta .. "  " .. uiText("IGUI_PlayableMinigames_Bet", "Bet") .. " " .. formatMoney(heroBet)
        end
        self:drawTextCentre(fitText(heroMeta, UIFont.Small, math.max(180, holeW + 130)), r.x + r.w / 2, heroY - 24, 0.96, 0.82, 0.46, 1, UIFont.Small)
        for i = 1, 2 do
            local x = holeX + (i - 1) * (cardW + gap)
            if hole[i] and self:holdemHoleCardVisible(localName, i) then
                self:drawCardSlot("holdem:hole:" .. tostring(i), hole[i], x, heroY, cardW, cardH, true, false, "holdem:deck")
            else
                self:drawEmptySlot(x, heroY, cardW, cardH, "")
            end
        end
        self:recordHoldemPlayerAnchor(localName, holeX - 16, heroY - 32, holeW + 32, cardH + 48, holeX, heroY, holeW, cardH)
        self:addClickZone("holdem_call", holeX, heroY, holeW, cardH, {})
    end

    local opponents = {}
    for i = 1, #players do
        local name = players[i]
        if not (viewerIsPlayer and tostring(name) == tostring(localName)) then
            table.insert(opponents, { name = name, seat = i })
        end
    end
    local topCount = #opponents <= 3 and #opponents or 3
    local topW = topCount * seatW + math.max(0, topCount - 1) * seatGap
    local topX = r.x + math.floor((r.w - topW) / 2)
    for i = 1, topCount do
        local seat = opponents[i]
        self:drawHoldemSeatPanel(seat.name, seat.seat, topX + (i - 1) * (seatW + seatGap), r.y + 24, seatW, seatH, opponentCardW, opponentCardH, opponentGap, ps, revealedHole, localName)
    end
    local sideY = boardY + cardH + clamp(math.floor(cardW * 0.52), 30, 58)
    local sideSlots = {
        { x = r.x + 28, y = sideY },
        { x = r.x + r.w - seatW - 28, y = sideY },
        { x = r.x + math.floor((r.w - seatW) / 2), y = r.y + r.h - seatH - 28 },
    }
    for i = topCount + 1, #opponents do
        local slot = sideSlots[i - topCount]
        if slot then
            local seat = opponents[i]
            self:drawHoldemSeatPanel(seat.name, seat.seat, slot.x, slot.y, seatW, seatH, opponentCardW, opponentCardH, opponentGap, ps, revealedHole, localName)
        end
    end

    self:drawHoldemTurnSpotlight(ps, localName)
    self:drawHoldemFlowPopups()

    if #players < 2 then
        local bannerW = math.min(420, r.w - 80)
        local bx = r.x + math.floor((r.w - bannerW) / 2)
        local by = boardY + cardH + math.floor(cardW * 0.55)
        self:drawRect(bx, by, bannerW, 34, 0.72, 0.025, 0.020, 0.016)
        self:drawRectBorder(bx, by, bannerW, 34, 0.78, 0.48, 0.34, 0.18)
        self:drawTextCentre(uiText("IGUI_PlayableMinigames_NeedTwoPlayers", "Need 2 players"), bx + bannerW / 2, by + 8, 0.96, 0.88, 0.66, 1, UIFont.Small)
    elseif ps.showdown and ps.showdown.winners then
        local winners = table.concat(ps.showdown.winners or {}, ", ")
        local bannerW = math.min(520, r.w - 80)
        local bx = r.x + math.floor((r.w - bannerW) / 2)
        local by = boardY + cardH + math.floor(cardW * 0.62)
        self:drawRect(bx, by, bannerW, 34, 0.76, 0.06, 0.045, 0.028)
        self:drawRectBorder(bx, by, bannerW, 34, 0.88, 0.82, 0.66, 0.30)
        self:drawTextCentre(fitText(uiText("IGUI_PlayableMinigames_Showdown", "Showdown") .. ": " .. winners, UIFont.Small, bannerW - 24), bx + bannerW / 2, by + 8, 0.96, 0.88, 0.66, 1, UIFont.Small)
    end
end

function PMGWindow:drawSolitaireEndOverlay(ps)
    ps = ps or {}
    if not ps.lost and not ps.won then
        return
    end

    local r = self.playRect
    local w = math.max(220, math.min(390, r.w - 56))
    local h = 128
    local x = r.x + math.floor((r.w - w) / 2)
    local y = r.y + math.floor((r.h - h) / 2)
    local title = ps.lost and uiText("IGUI_PlayableMinigames_SolitaireLost", "No More Moves") or uiText("IGUI_PlayableMinigames_SolitaireCleared", "Solitaire Cleared")
    local detail = ps.lost and tostring(ps.lossReason or uiText("IGUI_PlayableMinigames_SolitaireLostDetail", "This deal cannot make progress."))
        or uiText("IGUI_PlayableMinigames_SolitaireClearedDetail", "All foundations are complete.")

    self:drawRect(r.x, r.y, r.w, r.h, 0.28, 0.0, 0.0, 0.0)
    self:drawRect(x, y, w, h, 0.94, 0.035, 0.030, 0.026)
    self:drawRectBorder(x, y, w, h, 0.92, 0.82, 0.66, 0.42)
    self:drawTextCentre(title, x + w / 2, y + 28, 0.98, 0.88, 0.62, 1, UIFont.Medium)
    self:drawTextCentre(shorten(detail, math.floor(w / 8)), x + w / 2, y + 67, 0.84, 0.82, 0.72, 1, UIFont.Small)
    self:drawTextCentre(uiText("IGUI_PlayableMinigames_SolitaireNewGameHint", "Start a new deal from the side buttons."), x + w / 2, y + 91, 0.74, 0.72, 0.64, 1, UIFont.Small)
end

function PMGWindow:minigameResult()
    local state = self.state
    local ps = state and state.publicState or {}
    if not state then
        return nil
    end

    local localName = viewerName(state)
    local isPlayer = self:isViewerPlayer()
    local winnerName = nil
    local winnerLabel = nil
    local reason = nil
    local isDraw = false

    if state.gameId == "darts_501" then
        if not ps.winner then
            return nil
        end
        winnerName = tostring(ps.winner)
        winnerLabel = winnerName
        reason = tostring(ps.winReason or (winnerName .. " " .. uiText("IGUI_PlayableMinigames_Won", "won") .. "."))
    elseif isBoardGameId(state.gameId) then
        if ps.stalemate then
            isDraw = true
            reason = tostring(ps.winReason or uiText("IGUI_PlayableMinigames_StalemateHint", "No legal moves remain; the game is drawn."))
        elseif ps.winnerColor then
            winnerName = ps.winner and tostring(ps.winner) or nil
            winnerLabel = colorLabel(ps.winnerColor)
            reason = tostring(ps.winReason or (winnerLabel .. " " .. uiText("IGUI_PlayableMinigames_Won", "won") .. "."))
        else
            return nil
        end
    else
        return nil
    end

    local localWin = false
    if winnerName and localName ~= "" then
        localWin = winnerName == localName
    elseif ps.winnerColor then
        localWin = self:viewerBoardColor() == ps.winnerColor
    end
    local localLoss = winnerName ~= nil and isPlayer and not localWin
    local title
    if isDraw then
        title = uiText("IGUI_PlayableMinigames_ResultDraw", "DRAW")
    elseif localWin then
        title = uiText("IGUI_PlayableMinigames_ResultWon", "YOU WON")
    elseif localLoss then
        title = uiText("IGUI_PlayableMinigames_ResultLost", "YOU LOST")
    else
        title = uiText("IGUI_PlayableMinigames_ResultGameOver", "GAME OVER")
    end

    return {
        title = title,
        reason = reason,
        winner = winnerName,
        winnerLabel = winnerLabel,
        localWin = localWin,
        localLoss = localLoss,
        isDraw = isDraw,
    }
end

function PMGWindow:addResultButton(rect, label, action, args, primary, enabled, disabledReason)
    if not rect then
        return
    end
    enabled = enabled ~= false
    self.actionButtons = self.actionButtons or {}
    table.insert(self.actionButtons, {
        x = rect.x,
        y = rect.y,
        w = rect.w,
        h = rect.h,
        label = label,
        action = action,
        args = args or {},
        enabled = enabled,
        disabledReason = disabledReason,
    })
    if primary then
        self:drawRect(rect.x, rect.y, rect.w, rect.h, enabled and 0.92 or 0.42, 0.30, 0.18, 0.04)
        self:drawRectBorder(rect.x, rect.y, rect.w, rect.h, enabled and 1.00 or 0.52, 1.00, 0.74, 0.30)
        self:drawRectBorder(rect.x + 2, rect.y + 2, rect.w - 4, rect.h - 4, enabled and 0.45 or 0.18, 0.98, 0.88, 0.52)
        self:drawTextCentre(fitText(label, UIFont.Small, rect.w - 10), rect.x + rect.w / 2, rect.y + 7, enabled and 1.00 or 0.60, enabled and 0.94 or 0.58, enabled and 0.76 or 0.50, 1, UIFont.Small)
    else
        self:drawRect(rect.x, rect.y, rect.w, rect.h, enabled and 0.72 or 0.42, 0.08, 0.07, 0.055)
        self:drawRectBorder(rect.x, rect.y, rect.w, rect.h, enabled and 0.82 or 0.42, 0.56, 0.44, 0.26)
        self:drawTextCentre(fitText(label, UIFont.Small, rect.w - 10), rect.x + rect.w / 2, rect.y + 7, enabled and 0.86 or 0.58, enabled and 0.82 or 0.56, enabled and 0.70 or 0.48, 1, UIFont.Small)
    end
end

function PMGWindow:drawMinigameResultOverlay()
    local result = self:minigameResult()
    self.resultOverlayRect = nil
    self.resultOverlayActive = result ~= nil
    if not result then
        return false
    end

    local r = self.playRect
    self.clickZones = {}
    self.dartBoardRect = nil
    self:drawRect(r.x, r.y, r.w, r.h, 0.70, 0.02, 0.02, 0.02)

    local panelW = math.min(460, math.max(300, r.w - 64))
    local panelH = 238
    local x = r.x + math.floor((r.w - panelW) / 2)
    local y = r.y + math.floor((r.h - panelH) / 2)
    local cx = x + panelW / 2
    self.resultOverlayRect = { x = r.x, y = r.y, w = r.w, h = r.h }

    self:drawRect(x + 6, y + 8, panelW, panelH, 0.45, 0, 0, 0)
    self:drawRect(x, y, panelW, panelH, 0.96, 0.09, 0.07, 0.04)
    self:drawRectBorder(x, y, panelW, panelH, 1, 0.88, 0.68, 0.33)
    self:drawRectBorder(x + 3, y + 3, panelW - 6, panelH - 6, 0.65, 0.32, 0.22, 0.12)

    local iconName = result.localWin and "victory_icon.png" or "defeat_icon.png"
    local icon = texture(iconName)
    if icon then
        self:drawTextureScaled(icon, cx - 32, y + 22, 64, 64, 1, 1, 1, 1)
    else
        self:drawRect(cx - 24, y + 28, 48, 48, 0.82, result.localWin and 0.32 or 0.18, result.localWin and 0.26 or 0.05, result.localWin and 0.08 or 0.06)
        self:drawRectBorder(cx - 24, y + 28, 48, 48, 0.86, 0.92, 0.76, 0.30)
    end
    self:drawTextCentre(result.title, cx, y + 90, 1.00, result.localWin and 0.86 or 0.42, result.localWin and 0.36 or 0.32, 1, UIFont.Large)
    local lines = wrappedTextLines(result.reason or "", UIFont.Medium, panelW - 64, 2)
    for i = 1, #lines do
        self:drawTextCentre(lines[i], cx, y + 122 + (i - 1) * 22, 0.94, 0.92, 0.80, 1, UIFont.Medium)
    end
    if result.winnerLabel and not result.isDraw then
        self:drawTextCentre(fitText(uiText("IGUI_PlayableMinigames_ResultWinner", "Winner") .. ": " .. tostring(result.winnerLabel), UIFont.Small, panelW - 64), cx, y + 166, 0.68, 0.82, 0.72, 1, UIFont.Small)
    end

    local buttonH = 30
    local resetW = 132
    local closeW = 96
    local gap = 14
    local resetEnabled = self:canResetSession()
    local totalW = resetEnabled and (resetW + closeW + gap) or closeW
    local buttonY = y + panelH - buttonH - 16
    if resetEnabled then
        self:addResultButton({ x = cx - totalW / 2, y = buttonY, w = resetW, h = buttonH }, uiText("IGUI_PlayableMinigames_ActionPlayAgain", "Play Again"), "_reset", {}, true, true)
    end
    self:addResultButton({ x = cx - totalW / 2 + (resetEnabled and resetW + gap or 0), y = buttonY, w = closeW, h = buttonH }, uiText("IGUI_PlayableMinigames_ActionClose", "Close"), "_leave", {}, false, true)
    return true
end

function PMGWindow:drawSolitaire()
    local r = self.playRect
    local ps = self.state.publicState or {}
    self:drawTablePanel(r)
    self.solitaireZones = {}
    local maxRows = 0
    for col = 1, 7 do
        maxRows = math.max(maxRows, #((ps.tableau or {})[col] or {}))
    end
    local cardW = responsiveCardWidth(r, 8.7, 2.45 + math.max(0, maxRows - 1) * 0.30, 42, 122)
    local cardH = math.floor(cardW * 1.4)
    local gap = clamp(math.floor(cardW * 0.28), 10, 34)
    local topLabelGap = FONT_HGT_SMALL + clamp(math.floor(cardW * 0.14), 12, 18)
    local topY = r.y + math.max(topLabelGap + 6, math.floor(cardW * 0.30))
    local leftX = r.x + math.max(20, math.floor(r.w * 0.018))
    local wasteX = leftX + cardW + gap
    self:recordCardSource("solitaire:stock", leftX, topY, cardW, cardH)
    self:drawCardSlot("solitaire:stock", nil, leftX, topY, cardW, cardH, false)
    self:addClickZone("sol_stock", leftX, topY, cardW, cardH, {})
    self:drawTextCentre(uiText("IGUI_PlayableMinigames_Stock", "Stock") .. " " .. tostring(ps.stockCount or 0), leftX + cardW / 2, topY - topLabelGap, 0.80, 0.78, 0.68, 1, UIFont.Small)
    local wasteCard = top(ps.waste)
    local latestEvent = self.state and self.state.events and self.state.events[1] or nil
    local wasteSourceKey = latestEvent and latestEvent.solitaireAction == "draw" and "solitaire:stock" or nil
    self:drawCardSlot("solitaire:waste", wasteCard, wasteX, topY, cardW, cardH, wasteCard ~= nil, self.selected and self.selected.kind == "waste", wasteSourceKey)
    self:addClickZone("sol_waste", wasteX, topY, cardW, cardH, {})
    self:drawTextCentre(uiText("IGUI_PlayableMinigames_Waste", "Waste"), wasteX + cardW / 2, topY - topLabelGap, 0.80, 0.78, 0.68, 1, UIFont.Small)

    local foundationX = r.x + r.w - (cardW * 4 + gap * 3) - math.max(20, math.floor(r.w * 0.018))
    for i = 1, #SUITS do
        local suit = SUITS[i]
        local x = foundationX + (i - 1) * (cardW + gap)
        local card = top((ps.foundations or {})[suit])
        if card then
            self:drawCardSlot("solitaire:foundation:" .. suit, card, x, topY, cardW, cardH, true)
        else
            self:drawEmptySlot(x, topY, cardW, cardH, suit)
        end
        self:addClickZone("sol_foundation", x, topY, cardW, cardH, { suit = suit })
    end
    self:drawTextCentre(uiText("IGUI_PlayableMinigames_Foundations", "Foundations"), foundationX + (cardW * 4 + gap * 3) / 2, topY - topLabelGap, 0.80, 0.78, 0.68, 1, UIFont.Small)

    local tabTop = topY + cardH + clamp(math.floor(cardW * 0.42), 28, 58)
    local colGap = math.floor((r.w - (leftX - r.x) * 2 - cardW * 7) / 6)
    colGap = clamp(colGap, 8, math.floor(cardW * 0.45))
    local rowGap = clamp(math.floor((r.y + r.h - tabTop - cardH - 22) / math.max(1, maxRows)), 16, math.floor(cardH * 0.38))
    for col = 1, 7 do
        local pile = (ps.tableau or {})[col] or {}
        local x = leftX + (col - 1) * (cardW + colGap)
        if #pile == 0 then
            self:drawEmptySlot(x, tabTop, cardW, cardH, "")
            self:addClickZone("sol_tableau", x, tabTop, cardW, cardH, { col = col, index = 1, empty = true })
        end
        for row = 1, #pile do
            local entry = pile[row]
            local y = tabTop + (row - 1) * rowGap
            local selected = self.selected and self.selected.kind == "tableau" and self.selected.col == col and self.selected.index == row
            self:drawCardSlot("solitaire:tableau:" .. tostring(col) .. ":" .. tostring(row), entry.card, x, y, cardW, cardH, entry.faceUp, selected, "solitaire:stock")
            self:addClickZone("sol_tableau", x, y, cardW, cardH, { col = col, index = row, faceUp = entry.faceUp })
        end
    end
    if self.selected then
        local text = uiText("IGUI_PlayableMinigames_SolitaireSelected", "Selected") .. ": "
        if self.selected.kind == "waste" then
            text = text .. uiText("IGUI_PlayableMinigames_Waste", "Waste")
        else
            text = text .. uiText("IGUI_PlayableMinigames_Tableau", "Tableau") .. " " .. tostring(self.selected.col or "")
        end
        self:drawText(fitText(text, UIFont.Small, r.w - 40), r.x + 20, r.y + r.h - 24, 0.96, 0.82, 0.46, 1, UIFont.Small)
    end
    self:drawSolitaireEndOverlay(ps)
end

function PMGWindow:viewerBoardColor()
    local ps = self.state and self.state.publicState or {}
    local name = viewerName(self.state)
    if name == "" or not ps.seats then
        return nil
    end
    if ps.seats.white == name then
        return "white"
    elseif ps.seats.black == name then
        return "black"
    end
    return nil
end

function PMGWindow:boardDisplayToModel(displayRow, displayCol)
    local viewerColor = self:viewerBoardColor()
    if viewerColor == "black" then
        return 9 - displayRow, 9 - displayCol
    end
    return displayRow, displayCol
end

function PMGWindow:boardModelToDisplay(row, col)
    local viewerColor = self:viewerBoardColor()
    if viewerColor == "black" then
        return 9 - row, 9 - col
    end
    return row, col
end

function PMGWindow:boardCoordinateLabels()
    if self:viewerBoardColor() == "black" then
        return { "h", "g", "f", "e", "d", "c", "b", "a" }, { "1", "2", "3", "4", "5", "6", "7", "8" }
    end
    return { "a", "b", "c", "d", "e", "f", "g", "h" }, { "8", "7", "6", "5", "4", "3", "2", "1" }
end

function PMGWindow:legalBoardMovesFrom(row, col)
    local moves = {}
    local ps = self.state and self.state.publicState or {}
    for i = 1, #(ps.legalMoves or {}) do
        local move = ps.legalMoves[i]
        if move.fromRow == row and move.fromCol == col then
            table.insert(moves, move)
        end
    end
    return moves
end

function PMGWindow:findBoardMove(fromRow, fromCol, toRow, toCol)
    local moves = self:legalBoardMovesFrom(fromRow, fromCol)
    for i = 1, #moves do
        if sameSquare(moves[i], toRow, toCol) then
            return moves[i]
        end
    end
    return nil
end

function PMGWindow:canSelectBoardPiece(row, col)
    local ps = self.state and self.state.publicState or {}
    local board = ps.board or {}
    local piece = board[row] and board[row][col] or nil
    local color = pieceColor(piece)
    return color and color == self:viewerBoardColor() and color == ps.turnColor and #self:legalBoardMovesFrom(row, col) > 0
end

function PMGWindow:drawBoardPiece(gameId, piece, x, y, size)
    if not piece then
        return
    end
    local color = pieceColor(piece)
    local dark = color == "black"
    local margin = math.max(4, math.floor(size * 0.14))
    self:drawRect(x + margin, y + margin, size - margin * 2, size - margin * 2, 0.92, dark and 0.045 or 0.86, dark and 0.04 or 0.82, dark and 0.035 or 0.72)
    self:drawRectBorder(x + margin, y + margin, size - margin * 2, size - margin * 2, 0.95, dark and 0.90 or 0.40, dark and 0.78 or 0.30, dark and 0.50 or 0.18)
    local label = boardPieceLabel(gameId, piece)
    if label ~= "" then
        self:drawTextCentre(label, x + size / 2, y + math.floor((size - FONT_HGT_SMALL) / 2), dark and 0.96 or 0.18, dark and 0.86 or 0.13, dark and 0.58 or 0.09, 1, UIFont.Small)
    end
end

function PMGWindow:drawPromotionOverlay()
    local pending = self.pendingPromotion
    if not pending then
        return
    end
    local r = self.playRect
    local w = math.min(360, r.w - 60)
    local h = 94
    local x = r.x + math.floor((r.w - w) / 2)
    local y = r.y + math.floor((r.h - h) / 2)
    self:drawRect(r.x, r.y, r.w, r.h, 0.32, 0.0, 0.0, 0.0)
    self:drawRect(x, y, w, h, 0.94, 0.035, 0.030, 0.026)
    self:drawRectBorder(x, y, w, h, 0.92, 0.82, 0.66, 0.42)
    self:drawTextCentre(uiText("IGUI_PlayableMinigames_PromotePawn", "Promote pawn"), x + w / 2, y + 15, 0.98, 0.88, 0.62, 1, UIFont.Small)
    local labels = { Q = "Q", R = "R", B = "B", N = "N" }
    local order = { "Q", "R", "B", "N" }
    local buttonW = math.floor((w - 44) / 4)
    for i = 1, #order do
        self:addActionButton(labels[order[i]], x + 14 + (i - 1) * (buttonW + 6), y + 46, buttonW, 28, "_promote_" .. order[i], {})
    end
end

function PMGWindow:boardSquareRect(row, col, x0, y0, square)
    local displayRow, displayCol = self:boardModelToDisplay(row, col)
    if not displayRow or not displayCol then
        return nil
    end
    return {
        x = x0 + (displayCol - 1) * square,
        y = y0 + (displayRow - 1) * square,
        w = square,
        h = square,
    }
end

function PMGWindow:activeBoardMoveAnimation()
    local animation = self.boardMoveAnimation
    if not animation or not animation.steps or #animation.steps == 0 then
        return nil
    end
    local elapsed = nowMs() - (animation.startedAt or nowMs())
    local duration = math.max(1, tonumber(animation.durationMs) or BOARD_MOVE_ANIMATION_MS)
    local t = elapsed / duration
    if t >= 1 then
        self.boardMoveAnimation = nil
        return nil
    end
    animation.t = easeOutCubic(t)
    return animation
end

function PMGWindow:boardAnimationHiddenSquares(animation)
    local hidden = {}
    for i = 1, #(animation and animation.steps or {}) do
        local step = animation.steps[i]
        hidden[boardSquareKey(step.toRow, step.toCol)] = true
    end
    return hidden
end

function PMGWindow:drawBoardMoveAnimation(animation, x0, y0, square)
    local t = animation and animation.t or 0
    for i = 1, #(animation and animation.steps or {}) do
        local step = animation.steps[i]
        local from = self:boardSquareRect(step.fromRow, step.fromCol, x0, y0, square)
        local to = self:boardSquareRect(step.toRow, step.toCol, x0, y0, square)
        if from and to then
            local x = from.x + (to.x - from.x) * t
            local y = from.y + (to.y - from.y) * t
            local lift = math.sin(t * math.pi) * math.max(2, square * 0.07)
            self:drawBoardPiece(self.state.gameId, step.piece, x, y - lift, square)
        end
    end
end

function PMGWindow:drawBoardGame()
    local r = self.playRect
    local ps = self.state.publicState or {}
    local board = ps.board or {}
    self:drawTablePanel(r)
    local size = math.floor(math.min(r.w - 54, r.h - 54))
    local square = math.floor(size / 8)
    size = square * 8
    local x0 = r.x + math.floor((r.w - size) / 2)
    local y0 = r.y + math.floor((r.h - size) / 2)
    local selected = self.boardSelection
    local legalTargets = {}
    local animation = self:activeBoardMoveAnimation()
    local hiddenSquares = self:boardAnimationHiddenSquares(animation)
    if selected then
        local moves = self:legalBoardMovesFrom(selected.row, selected.col)
        for i = 1, #moves do
            legalTargets[tostring(moves[i].toRow) .. ":" .. tostring(moves[i].toCol)] = true
        end
    end
    local last = ps.lastMove or {}
    for displayRow = 1, 8 do
        for displayCol = 1, 8 do
            local row, col = self:boardDisplayToModel(displayRow, displayCol)
            local x = x0 + (displayCol - 1) * square
            local y = y0 + (displayRow - 1) * square
            local dark = (row + col) % 2 == 1
            local highlight = selected and selected.row == row and selected.col == col
            local target = legalTargets[tostring(row) .. ":" .. tostring(col)] == true
            local lastSq = (last.fromRow == row and last.fromCol == col) or (last.toRow == row and last.toCol == col)
            self:drawRect(x, y, square, square, 1, dark and 0.23 or 0.62, dark and 0.13 or 0.48, dark and 0.075 or 0.31)
            if lastSq then
                self:drawRect(x + 2, y + 2, square - 4, square - 4, 0.34, 0.96, 0.76, 0.30)
            end
            if target then
                self:drawRect(x + 5, y + 5, square - 10, square - 10, 0.30, 0.58, 0.88, 0.62)
            end
            if highlight then
                self:drawRectBorder(x + 2, y + 2, square - 4, square - 4, 0.96, 0.96, 0.86, 0.44)
                self:drawRectBorder(x + 4, y + 4, square - 8, square - 8, 0.86, 0.96, 0.86, 0.44)
            end
            self:drawRectBorder(x, y, square, square, 0.24, 0.06, 0.04, 0.03)
            if not hiddenSquares[boardSquareKey(row, col)] then
                self:drawBoardPiece(self.state.gameId, board[row] and board[row][col] or nil, x, y, square)
            end
            self:addClickZone("board_square", x, y, square, square, { row = row, col = col })
        end
    end
    self:drawBoardMoveAnimation(animation, x0, y0, square)
    local files, ranks = self:boardCoordinateLabels()
    for displayCol = 1, 8 do
        self:drawTextCentre(files[displayCol], x0 + (displayCol - 0.5) * square, y0 + size + 6, 0.72, 0.70, 0.62, 1, UIFont.Small)
    end
    for displayRow = 1, 8 do
        self:drawRightText(ranks[displayRow], x0 - 8, y0 + (displayRow - 0.5) * square - math.floor(FONT_HGT_SMALL / 2), 0.72, 0.70, 0.62, 1, UIFont.Small)
    end
    if #(self.state.players or {}) < 2 then
        local bannerW = math.min(420, r.w - 80)
        local bx = r.x + math.floor((r.w - bannerW) / 2)
        local by = r.y + 18
        self:drawRect(bx, by, bannerW, 34, 0.72, 0.025, 0.020, 0.016)
        self:drawRectBorder(bx, by, bannerW, 34, 0.78, 0.48, 0.34, 0.18)
        self:drawTextCentre(uiText("IGUI_PlayableMinigames_NeedTwoPlayers", "Need 2 players"), bx + bannerW / 2, by + 8, 0.96, 0.88, 0.66, 1, UIFont.Small)
    end
    self:drawPromotionOverlay()
end

function PMGWindow:render()
    ISCollapsableWindow.render(self)
    self:layout()
    self.actionButtons = {}
    self.clickZones = {}
    self.dartBoardRect = nil
    self.resultOverlayRect = nil
    self.resultOverlayActive = false
    self:beginCardFrame()
    self:drawRect(0, self:titleBarHeight(), self.width, self.height - self:titleBarHeight(), 0.96, 0.04, 0.035, 0.03)
    if not self.state then
        self:drawTextCentre(uiText("IGUI_PlayableMinigames_Opening", "Opening minigame..."), self.width / 2, self.height / 2, 0.90, 0.86, 0.72, 1, UIFont.Medium)
        self:endCardFrame()
        return
    end
    if self.state.gameId == "holdem" then
        self:playHoldemFlowSounds()
    end
    if self.state.gameId == "darts_501" then
        self:drawDarts()
    elseif self.state.gameId == "blackjack" then
        self:drawBlackjack()
    elseif self.state.gameId == "holdem" then
        self:drawHoldem()
    elseif self.state.gameId == "solitaire" then
        self:drawSolitaire()
    elseif isBoardGameId(self.state.gameId) then
        self:drawBoardGame()
    else
        self:drawText(uiText("IGUI_PlayableMinigames_UnsupportedView", "Unsupported minigame view: ") .. tostring(self.state.gameId), 32, 80, 1, 1, 1, 1, UIFont.Small)
    end
    self:drawSidebar()
    self:drawMinigameResultOverlay()
    self:buildFocusTargets()
    self:drawFocusTarget()
    self:endCardFrame()
    self:continueSolitaireAutoSolve()
end

function PMGWindow:performAction(action, args)
    if not self:canPerformAction(action) then
        return false
    end
    if action == "_reset" then
        PMGClient.reset(self.playerNum, self.state)
    elseif action == "_leave" then
        self:close()
    elseif action == "_raise_down" then
        return self:adjustHoldemRaiseAmount(-1)
    elseif action == "_raise_up" then
        return self:adjustHoldemRaiseAmount(1)
    elseif string.sub(tostring(action or ""), 1, 9) == "_promote_" then
        if not self.pendingPromotion then
            return true
        end
        local promotion = string.sub(tostring(action), 10, 10)
        local pending = self.pendingPromotion
        self.pendingPromotion = nil
        self.boardSelection = nil
        playPMGSound("PMGTurn", "UIActivateMainMenuItem")
        PMGClient.action(self.playerNum, self.state, "move", {
            fromRow = pending.fromRow,
            fromCol = pending.fromCol,
            toRow = pending.toRow,
            toCol = pending.toCol,
            promotion = promotion,
        })
        return true
    else
        if self.state and self.state.gameId == "darts_501" and action == "throw" then
            args = PMG.copyTable(args or {})
            local aim = self:getDartAim(true) or { x = 0, y = 0 }
            local timing = self:dartTiming()
            args.x = clamp(tonumber(args.x) or aim.x or 0, -0.99, 0.99)
            args.y = clamp(tonumber(args.y) or aim.y or 0, -0.99, 0.99)
            args.releaseOffset = clamp(tonumber(args.releaseOffset) or timing.offset or 0, -1, 1)
            args.releaseQuality = clamp(tonumber(args.releaseQuality) or timing.quality or 0, 0, 1)
            self.dartAim = { x = args.x, y = args.y }
            playPMGSound("PMGDartThrow", "UIActivateMainMenuItem")
            PMGClient.action(self.playerNum, self.state, "throw", args)
            return true
        end
        PMGClient.action(self.playerNum, self.state, action, PMG.copyTable(args or {}))
    end
    return true
end

function PMGWindow:isLocalSolitaireOwner()
    if not self.state or self.state.gameId ~= "solitaire" then
        return false
    end
    if not self.state.owner then
        return true
    end
    local viewerName = PMG.localPlayerIdentity and PMG.localPlayerIdentity(self.playerObj, self.playerNum) or nil
    return viewerName ~= nil and tostring(viewerName) == tostring(self.state.owner)
end

function PMGWindow:continueSolitaireAutoSolve()
    local ps = self.state and self.state.publicState or {}
    if not self.state or self.state.gameId ~= "solitaire" or not ps.autoSolving or ps.won or ps.lost then
        self:resetSolitaireAutoSolveCadence()
        return
    end
    if not self:isLocalSolitaireOwner() then
        return
    end

    local now = nowMs()
    local cadence = self:ensureSolitaireAutoSolveCadence(self.state)
    if not self.nextSolitaireAutoSolveAt then
        self.nextSolitaireAutoSolveAt = now + self:solitaireAutoSolveStepDelayMs()
        return
    end
    if now < self.nextSolitaireAutoSolveAt then
        return
    end

    self.selected = nil
    if self:performAction("auto_solve_step", {}) ~= false then
        if cadence then
            cadence.stepCount = (tonumber(cadence.stepCount) or 0) + 1
        end
        self.nextSolitaireAutoSolveAt = now + self:solitaireAutoSolveStepDelayMs()
    else
        self.nextSolitaireAutoSolveAt = now + SOLITAIRE_AUTO_SOLVE_INITIAL_STEP_MS
    end
end

function PMGWindow:close()
    if not self._pmgClosing then
        self._pmgClosing = true
        if PMGClient and PMGClient.leave and self.state and self.state.anchor then
            PMGClient.leave(self.playerNum, self.state)
        end
    end
    if setJoypadFocus and getFocusForPlayer and self.playerNum ~= nil and getFocusForPlayer(self.playerNum) == self then
        setJoypadFocus(self.playerNum, nil)
    end
    self:setVisible(false)
    self:removeFromUIManager()
    if PMGClient and PMGClient.windows then
        PMGClient.windows[self.playerNum or 0] = nil
    end
end

function PMGWindow:tryAutoMoveWaste()
    local ps = self.state and self.state.publicState or {}
    local card = top(ps.waste)
    if not card then
        return false
    end
    local suit = PMG_Cards.suit(card)
    if PMG_Cards.canMoveToFoundation(card, top((ps.foundations or {})[suit])) then
        self:performAction("waste_to_foundation", {})
        return true
    end
    for col = 1, 7 do
        if PMG_Cards.canStackTableau(card, topPublicCard((ps.tableau or {})[col])) then
            self:performAction("waste_to_tableau", { toCol = col })
            return true
        end
    end
    return false
end

function PMGWindow:tryAutoMoveTableau(col, index)
    local ps = self.state and self.state.publicState or {}
    local pile = (ps.tableau or {})[col] or {}
    local entry = pile[index]
    if not entry or not entry.faceUp or not entry.card then
        return false
    end
    if index == #pile then
        local suit = PMG_Cards.suit(entry.card)
        if PMG_Cards.canMoveToFoundation(entry.card, top((ps.foundations or {})[suit])) then
            self:performAction("tableau_to_foundation", { fromCol = col })
            return true
        end
    end
    for toCol = 1, 7 do
        local targetCard = topPublicCard((ps.tableau or {})[toCol])
        local opensNewAccess = targetCard ~= nil or index > 1
        if toCol ~= col and opensNewAccess and PMG_Cards.canStackTableau(entry.card, targetCard) then
            self:performAction("tableau_to_tableau", { fromCol = col, toCol = toCol, index = index })
            return true
        end
    end
    return false
end

function PMGWindow:handleSolitaireClick(zone)
    local ps = self.state and self.state.publicState or {}
    self.selected = nil
    if ps.won or ps.lost or ps.autoSolving then
        return true
    end

    if zone.kind == "sol_stock" then
        self:performAction("draw", {})
        return true
    elseif zone.kind == "sol_waste" then
        if top(ps.waste) and self:tryAutoMoveWaste() then
            playPMGSound("PMGCardDraw", "UIActivateMainMenuItem")
        end
        return true
    elseif zone.kind == "sol_foundation" then
        return true
    elseif zone.kind == "sol_tableau" then
        if zone.faceUp and self:tryAutoMoveTableau(zone.col, zone.index) then
            playPMGSound("PMGCardDraw", "UIActivateMainMenuItem")
        end
        return true
    end
    return false
end

function PMGWindow:handleBoardSquareClick(zone)
    if not zone or not self.state or not isBoardGameId(self.state.gameId) then
        return false
    end
    if self.pendingPromotion then
        return true
    end
    local ps = self.state.publicState or {}
    local board = ps.board or {}
    local row = zone.row
    local col = zone.col
    local selected = self.boardSelection
    if selected then
        local move = self:findBoardMove(selected.row, selected.col, row, col)
        if move then
            local piece = board[selected.row] and board[selected.row][selected.col] or nil
            if self.state.gameId == "chess" and pieceKind(piece) == "P" and (row == 1 or row == 8) then
                self.pendingPromotion = {
                    fromRow = selected.row,
                    fromCol = selected.col,
                    toRow = row,
                    toCol = col,
                }
                return true
            end
            self.boardSelection = nil
            playPMGSound("PMGTurn", "UIActivateMainMenuItem")
            PMGClient.action(self.playerNum, self.state, "move", {
                fromRow = selected.row,
                fromCol = selected.col,
                toRow = row,
                toCol = col,
            })
            return true
        end
    end
    if self:canSelectBoardPiece(row, col) then
        self.boardSelection = { row = row, col = col }
    else
        self.boardSelection = nil
    end
    return true
end

function PMGWindow:handleClickZone(zone)
    if zone.kind == "blackjack_shoe" then
        local ps = self.state and self.state.publicState or {}
        if ps.round == "playing" then
            return self:performAction("hit", {})
        else
            return self:performAction("start_round", { bet = 10 })
        end
    elseif zone.kind == "blackjack_hand" then
        return self:performAction("hit", {})
    elseif zone.kind == "blackjack_stand" then
        return self:performAction("stand", {})
    elseif zone.kind == "holdem_call" then
        local ps = self.state and self.state.publicState or {}
        return self:performAction((ps.toCall or 0) > 0 and "call" or "check", {})
    elseif string.sub(zone.kind or "", 1, 4) == "sol_" then
        return self:handleSolitaireClick(zone)
    elseif zone.kind == "board_square" then
        return self:handleBoardSquareClick(zone)
    end
    return false
end

function PMGWindow:getDartAim(create)
    if not self.dartAim and create ~= false then
        local lastThrow = self.state and self.state.publicState and self.state.publicState.lastThrow or nil
        local defaultX, defaultY = PMG_Darts.targetPoint(20, "triple")
        self.dartAim = {
            x = clamp(lastThrow and lastThrow.aimX or defaultX, -PMG_Darts.GEOMETRY.boardRadius, PMG_Darts.GEOMETRY.boardRadius),
            y = clamp(lastThrow and lastThrow.aimY or defaultY, -PMG_Darts.GEOMETRY.boardRadius, PMG_Darts.GEOMETRY.boardRadius),
        }
    end
    return self.dartAim
end

function PMGWindow:dartTiming()
    local phase = ((nowMs() % DART_RELEASE_PERIOD_MS) / DART_RELEASE_PERIOD_MS)
    local offset = math.sin(phase * math.pi * 2)
    local quality = math.max(0, 1 - math.abs(offset))
    return {
        offset = offset,
        quality = quality,
    }
end

local function pointInRect(x, y, r)
    return r and x >= r.x and x <= r.x + (r.w or r.size or 0) and y >= r.y and y <= r.y + (r.h or r.size or 0)
end

function PMGWindow:absoluteOffset()
    local x = 0
    local y = 0
    if self.getAbsoluteX then
        local ok, value = pcall(function()
            return self:getAbsoluteX()
        end)
        if ok and value then
            x = tonumber(value) or x
        end
    elseif self.getX then
        local ok, value = pcall(function()
            return self:getX()
        end)
        if ok and value then
            x = tonumber(value) or x
        end
    end
    if self.getAbsoluteY then
        local ok, value = pcall(function()
            return self:getAbsoluteY()
        end)
        if ok and value then
            y = tonumber(value) or y
        end
    elseif self.getY then
        local ok, value = pcall(function()
            return self:getY()
        end)
        if ok and value then
            y = tonumber(value) or y
        end
    end
    return x, y
end

function PMGWindow:localPointer(x, y)
    x = tonumber(x) or 0
    y = tonumber(y) or 0
    if pointInRect(x, y, self.dartBoardRect) or pointInRect(x, y, self.playRect) or pointInRect(x, y, self.sidebarRect) then
        return x, y
    end
    local ox, oy = self:absoluteOffset()
    local localX = x - ox
    local localY = y - oy
    if pointInRect(localX, localY, self.dartBoardRect) or pointInRect(localX, localY, self.playRect) or pointInRect(localX, localY, self.sidebarRect) then
        return localX, localY
    end
    return x, y
end

function PMGWindow:dartAimFromPointer(x, y)
    local r = self.dartBoardRect
    if not r or not r.size or r.size <= 0 then
        return nil
    end
    local localX, localY = self:localPointer(x, y)
    if not pointInRect(localX, localY, r) then
        return nil
    end
    local nx = ((localX - r.x) / r.size) * 2 - 1
    local ny = ((localY - r.y) / r.size) * 2 - 1
    local boardRadius = PMG_Darts.GEOMETRY.boardRadius
    if nx * nx + ny * ny > boardRadius * boardRadius then
        return nil
    end
    return {
        x = clamp(nx, -boardRadius, boardRadius),
        y = clamp(ny, -boardRadius, boardRadius),
    }
end

function PMGWindow:focusDartBoard()
    for i = 1, #(self.focusTargets or {}) do
        local target = self.focusTargets[i]
        if target and target.kind == "dart_board" then
            self.focusIndex = i
            return
        end
    end
end

function PMGWindow:setDartAimFromPointer(x, y)
    local aim = self:dartAimFromPointer(x, y)
    if not aim then
        return false
    end
    if not self:canPerformAction("throw") then
        return true
    end
    self.dartAim = aim
    self:focusDartBoard()
    return true
end

function PMGWindow:nudgeDartAim(dx, dy, fine)
    local aim = self:getDartAim(true)
    if not aim then
        return false
    end
    local step = fine and 0.025 or 0.075
    local boardRadius = PMG_Darts.GEOMETRY.boardRadius
    aim.x = clamp((aim.x or 0) + dx * step, -boardRadius, boardRadius)
    aim.y = clamp((aim.y or 0) + dy * step, -boardRadius, boardRadius)
    return true
end

function PMGWindow:moveFocus(delta)
    if not self.focusTargets or #self.focusTargets == 0 then
        self:buildFocusTargets()
    end
    if not self.focusTargets or #self.focusTargets == 0 then
        return false
    end
    local count = #self.focusTargets
    self.focusIndex = ((self.focusIndex or 1) - 1 + delta) % count + 1
    return true
end

function PMGWindow:activateFocused()
    local target = self:focusedTarget()
    if not target then
        return false
    end
    if target.kind == "action" then
        local button = target.button
        if button.enabled == false then
            return true
        end
        return self:performAction(button.action, button.args)
    elseif target.kind == "zone" then
        return self:handleClickZone(target.zone)
    elseif target.kind == "dart_board" then
        if not self:canPerformAction("throw") then
            return true
        end
        local aim = self:getDartAim(true)
        return self:performAction("throw", { x = aim.x, y = aim.y })
    end
    return false
end

function PMGWindow:cancelFocused()
    if self.selected then
        self.selected = nil
        return true
    end
    if self.focusTargets and #self.focusTargets > 0 then
        for i = #self.focusTargets, 1, -1 do
            local target = self.focusTargets[i]
            if target.kind == "action" and target.button and target.button.action == "_leave" then
                self.focusIndex = i
                return true
            end
        end
    end
    return false
end

function PMGWindow:handleKeyPressed(key)
    if not Keyboard then
        return false
    end
    local target = self:focusedTarget()
    local fine = isKeyDown and ((Keyboard.KEY_LSHIFT and isKeyDown(Keyboard.KEY_LSHIFT)) or (Keyboard.KEY_RSHIFT and isKeyDown(Keyboard.KEY_RSHIFT))) or false
    if target and target.kind == "dart_board" and self:canPerformAction("throw") then
        if key == Keyboard.KEY_LEFT then
            return self:nudgeDartAim(-1, 0, fine)
        elseif key == Keyboard.KEY_RIGHT then
            return self:nudgeDartAim(1, 0, fine)
        elseif key == Keyboard.KEY_UP then
            return self:nudgeDartAim(0, -1, fine)
        elseif key == Keyboard.KEY_DOWN then
            return self:nudgeDartAim(0, 1, fine)
        end
    end
    if key == Keyboard.KEY_TAB or key == Keyboard.KEY_RIGHT or key == Keyboard.KEY_DOWN then
        return self:moveFocus(1)
    elseif key == Keyboard.KEY_LEFT or key == Keyboard.KEY_UP then
        return self:moveFocus(-1)
    elseif key == Keyboard.KEY_SPACE or key == Keyboard.KEY_RETURN then
        return self:activateFocused()
    elseif key == Keyboard.KEY_ESCAPE then
        return self:cancelFocused()
    end
    return false
end

function PMGWindow:onGainJoypadFocus(joypadData)
    self.joypadFocused = true
    self.joypadData = joypadData
    if not self.focusIndex then
        self.focusIndex = 1
    end
end

function PMGWindow:onLoseJoypadFocus(joypadData)
    self.joypadFocused = false
    self.joypadData = nil
end

function PMGWindow:handleJoypadDirection(dx, dy)
    local target = self:focusedTarget()
    if target and target.kind == "dart_board" and self:canPerformAction("throw") then
        return self:nudgeDartAim(dx, dy, false)
    end
    if math.abs(dx or 0) + math.abs(dy or 0) == 0 then
        return false
    end
    return self:moveFocus((dx or 0) + (dy or 0) > 0 and 1 or -1)
end

function PMGWindow:onJoypadDown(button, joypadData)
    if not Joypad then
        return false
    end
    self.joypadData = joypadData
    if button == Joypad.AButton then
        return self:activateFocused()
    elseif button == Joypad.BButton then
        return self:cancelFocused()
    elseif button == Joypad.DPadLeft then
        return self:handleJoypadDirection(-1, 0)
    elseif button == Joypad.DPadRight then
        return self:handleJoypadDirection(1, 0)
    elseif button == Joypad.DPadUp then
        return self:handleJoypadDirection(0, -1)
    elseif button == Joypad.DPadDown then
        return self:handleJoypadDirection(0, 1)
    end
    return false
end

function PMGWindow:onJoypadDirLeft(joypadData)
    return self:handleJoypadDirection(-1, 0)
end

function PMGWindow:onJoypadDirRight(joypadData)
    return self:handleJoypadDirection(1, 0)
end

function PMGWindow:onJoypadDirUp(joypadData)
    return self:handleJoypadDirection(0, -1)
end

function PMGWindow:onJoypadDirDown(joypadData)
    return self:handleJoypadDirection(0, 1)
end

function PMGWindow:onMouseDown(x, y)
    for i = 1, #(self.actionButtons or {}) do
        local button = self.actionButtons[i]
        if x >= button.x and x <= button.x + button.w and y >= button.y and y <= button.y + button.h then
            if button.enabled == false then
                return true
            end
            self:performAction(button.action, button.args)
            return true
        end
    end
    if self.resultOverlayActive and pointInRect(x, y, self.resultOverlayRect) then
        return true
    end
    for i = #(self.clickZones or {}), 1, -1 do
        local zone = self.clickZones[i]
        if x >= zone.x and x <= zone.x + zone.w and y >= zone.y and y <= zone.y + zone.h then
            if self:handleClickZone(zone) then
                return true
            end
        end
    end
    if self.state and self.state.gameId == "darts_501" and self.dartBoardRect then
        if self:setDartAimFromPointer(x, y) then
            self.dartMouseAiming = self:canPerformAction("throw")
            return true
        end
    end
    return ISCollapsableWindow.onMouseDown(self, x, y)
end

function PMGWindow:onMouseMove(dx, dy)
    ISCollapsableWindow.onMouseMove(self, dx, dy)
    if self.dartMouseAiming and self.state and self.state.gameId == "darts_501" then
        return self:setDartAimFromPointer(self:getMouseX(), self:getMouseY())
    end
    return false
end

function PMGWindow:onMouseMoveOutside(dx, dy)
    return self:onMouseMove(dx, dy)
end

function PMGWindow:onMouseUp(x, y)
    self.dartMouseAiming = false
    return ISCollapsableWindow.onMouseUp(self, x, y)
end

function PMGWindow:onMouseUpOutside(x, y)
    return self:onMouseUp(x, y)
end

function PMGWindow:new(x, y, width, height, playerNum, playerObj)
    local o = ISCollapsableWindow.new(self, x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = playerNum or 0
    o.playerObj = playerObj
    o.resizable = true
    o.minimumWidth = 820
    o.minimumHeight = 520
    o.title = uiText("IGUI_PlayableMinigames_WindowTitle", "Playable Minigame")
    return o
end
