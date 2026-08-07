require "PlayableSurvivalCards/PSC_Core"
require "PlayableSurvivalCards/PSC_Rules"

PSC_Host = PSC_Host or {}

local Host = {}
Host.__index = Host

local function nowMs()
    if getTimestampMs then
        return getTimestampMs()
    end
    return math.floor(os.time() * 1000)
end

function PSC_Host.new(env)
    return setmetatable({
        sessions = {},
        env = env or {},
        tickCounter = 0,
    }, Host)
end

function Host:now()
    return self.env.now and self.env.now() or nowMs()
end

function Host:playerName(playerObj, args)
    if self.env.playerName then
        local value = self.env.playerName(playerObj, args or {})
        if value and value ~= "" then
            return tostring(value)
        end
    end
    return PSC.username(playerObj)
end

function Host:message(playerObj, text)
    if self.env.message then
        self.env.message(playerObj, tostring(text or "Survival Cards is not available."))
    end
end

function Host:applyMoodRelief(playerName, boredom, stress, unhappiness)
    if self.env.applyMoodRelief then
        self.env.applyMoodRelief(playerName, boredom, stress, unhappiness)
    end
end

function Host:sendState(playerObj, session, viewerName)
    if self.env.sendState then
        self.env.sendState(playerObj, PSC.redactedState(session, viewerName))
    end
end

function Host:broadcast(session)
    if not session then
        return
    end
    if self.env.findPlayerByName then
        for i = 1, #(session.players or {}) do
            local name = session.players[i]
            if not PSC.isBot(session, name) then
                self:sendState(self.env.findPlayerByName(name), session, name)
            end
        end
        for i = 1, #(session.spectators or {}) do
            local name = session.spectators[i]
            self:sendState(self.env.findPlayerByName(name), session, name)
        end
    elseif self.env.localBroadcast then
        self.env.localBroadcast(session)
    end
end

function Host:createSession(anchor, ownerName)
    local session = {
        key = anchor.key,
        anchor = PSC.copy(anchor),
        owner = ownerName,
        players = { ownerName },
        spectators = {},
        bots = {},
        stackingEnabled = false,
        phase = PSC.PHASE_WAITING,
        publicState = {
            title = "UNO",
            players = { ownerName },
            spectators = {},
            handCounts = {},
            currentPlayerName = ownerName,
            currentColor = nil,
            topCard = nil,
            deckCount = 0,
            direction = 1,
            stackingEnabled = false,
            roundNo = 0,
            events = {},
        },
        privateState = {
            uno = {},
        },
        seed = tostring(anchor.key) .. ":" .. tostring(self:now()),
        touched = self:now(),
    }
    PSC.addEvent(session, tostring(ownerName) .. " opened a UNO table.", "join")
    self.sessions[anchor.key] = session
    return session
end

function Host:refreshPublic(session)
    local state = session.privateState.uno or {}
    session.publicState.players = PSC.copy(session.players or {})
    session.publicState.spectators = PSC.copy(session.spectators or {})
    session.publicState.bots = PSC.copy(session.bots or {})
    session.publicState.phase = session.phase
    session.publicState.currentPlayerName = session.players[state.turnIndex or 1]
    session.publicState.currentColor = state.currentColor
    session.publicState.topCard = PSC_Rules.topDiscard(state)
    session.publicState.deckCount = #(state.deck or {})
    session.publicState.direction = state.direction or 1
    session.publicState.winner = state.winner
    session.publicState.lastDrawnBy = state.lastDrawnBy
    session.publicState.canPassAfterDraw = state.canPassAfterDraw
    session.publicState.pendingDraw = state.pendingDraw or 0
    session.publicState.stackingEnabled = session.stackingEnabled == true
    session.publicState.animation = PSC.copy(state.animation)
    session.publicState.animations = PSC.copy(state.animations or {})
    session.publicState.unoCalled = PSC.copy(state.unoCalled or {})
    session.publicState.roundNo = session.roundNo or 0
    session.publicState.handCounts = {}
    for i = 1, #(session.players or {}) do
        local name = session.players[i]
        session.publicState.handCounts[name] = #(state.hands and state.hands[name] or {})
    end
end

function Host:pushAnimation(state, kind, playerName, card)
    state.animationSeq = (state.animationSeq or 0) + 1
    local animation = {
        seq = state.animationSeq,
        createdAt = self:now(),
        kind = tostring(kind or "play"),
        playerName = tostring(playerName or ""),
        card = card,
    }
    state.animation = animation
    state.animations = state.animations or {}
    table.insert(state.animations, animation)
    while #state.animations > 192 do
        table.remove(state.animations, 1)
    end
    return animation
end

function Host:pushDrawAnimations(state, playerName, count)
    for _ = 1, tonumber(count) or 0 do
        self:pushAnimation(state, "draw", playerName, nil)
    end
end

local function firstHumanPlayer(session)
    for i = 1, #(session.players or {}) do
        local name = session.players[i]
        if not PSC.isBot(session, name) then
            return name
        end
    end
    return nil
end

function Host:addPlayer(session, name)
    if PSC.findName(session.players, name) then
        return true
    end
    if #session.players >= PSC.MAX_PLAYERS then
        local bot = PSC.firstBot(session)
        if bot then
            session.bots[bot] = nil
            PSC.removeName(session.players, bot)
            PSC.addEvent(session, tostring(bot) .. " gave up a seat for " .. tostring(name) .. ".", "leave")
        else
            return false, "This table is full."
        end
    end
    PSC.removeName(session.spectators, name)
    table.insert(session.players, name)
    PSC.addEvent(session, tostring(name) .. " joined the table.", "join")
    self:refreshPublic(session)
    return true
end

function Host:addSpectator(session, name)
    if PSC.findName(session.players, name) or PSC.findName(session.spectators, name) then
        return true
    end
    table.insert(session.spectators, name)
    PSC.addEvent(session, tostring(name) .. " is watching.", "watch")
    self:refreshPublic(session)
    return true
end

function Host:addBot(session, difficulty)
    if #session.players >= PSC.MAX_PLAYERS then
        return false, "This table is full."
    end
    local n = 1
    local name = "Card Bot"
    while PSC.findName(session.players, name) do
        n = n + 1
        name = "Card Bot " .. tostring(n)
    end
    session.bots[name] = { difficulty = tostring(difficulty or "medium") }
    table.insert(session.players, name)
    PSC.addEvent(session, name .. " joined as a bot.", "join")
    self:refreshPublic(session)
    return true
end

function Host:removeBot(session)
    local name = PSC.firstBot(session)
    if not name then
        return false, "There is no bot to remove."
    end
    session.bots[name] = nil
    PSC.removeName(session.players, name)
    PSC.addEvent(session, name .. " left the table.", "leave")
    self:refreshPublic(session)
    return true
end

function Host:startRound(session)
    if #session.players < PSC.MIN_PLAYERS then
        return false, "Need at least two players."
    end
    local state = {
        seed = tostring(session.seed) .. ":round:" .. tostring((session.roundNo or 0) + 1),
        deck = PSC_Rules.newDeck(tostring(session.seed) .. ":round:" .. tostring((session.roundNo or 0) + 1)),
        discard = {},
        hands = {},
        unoCalled = {},
        animations = {},
        animation = nil,
        animationSeq = 0,
        direction = 1,
        turnIndex = 1,
        canPassAfterDraw = false,
        forcedCardIndex = nil,
        drawnPlayableBy = nil,
        pendingDraw = 0,
        pendingDrawValue = 0,
        stackingEnabled = session.stackingEnabled == true,
    }
    session.roundNo = (session.roundNo or 0) + 1
    for i = 1, #session.players do
        local name = session.players[i]
        state.hands[name] = {}
        for _ = 1, PSC.START_HAND_SIZE do
            table.insert(state.hands[name], PSC_Rules.drawCard(state))
        end
    end
    local first = PSC_Rules.drawCard(state)
    while first and PSC_Rules.cardColor(first) == "wild" do
        table.insert(state.deck, 1, first)
        first = PSC_Rules.drawCard(state)
    end
    if not first then
        first = "R0"
    end
    table.insert(state.discard, first)
    state.currentColor = PSC_Rules.cardColor(first)
    local openingValue = PSC_Rules.cardValue(first)
    if openingValue == "S" then
        state.turnIndex = PSC_Rules.nextIndex(state, #session.players, 1)
        PSC.addEvent(session, tostring(session.players[1]) .. " was skipped by the opening card.", "play")
    elseif openingValue == "R" then
        state.direction = -1
        state.turnIndex = PSC_Rules.nextIndex(state, #session.players, 1)
        PSC.addEvent(session, "The opening card reversed direction.", "play")
    elseif openingValue == "D2" then
        local drawnCount = 0
        for _ = 1, 2 do
            local drawn = PSC_Rules.drawCard(state)
            if drawn then
                table.insert(state.hands[session.players[1]], drawn)
                drawnCount = drawnCount + 1
            end
        end
        self:pushDrawAnimations(state, session.players[1], drawnCount)
        state.turnIndex = PSC_Rules.nextIndex(state, #session.players, 1)
        PSC.addEvent(session, tostring(session.players[1]) .. " drew two cards from the opening card.", "draw")
    end
    session.privateState.uno = state
    session.phase = PSC.PHASE_PLAYING
    PSC.addEvent(session, "Round started. " .. tostring(session.players[state.turnIndex]) .. " leads.", "deal")
    self:refreshPublic(session)
    return true
end

function PSC.currentState(session)
    return session and session.privateState and session.privateState.uno or {}
end

local function clearTurnFlags(state)
    state.lastDrawnBy = nil
    state.canPassAfterDraw = false
    state.forcedCardIndex = nil
    state.drawnPlayableBy = nil
end

local function advanceTurn(session, state, steps)
    state.turnIndex = PSC_Rules.nextIndex(state, #session.players, steps or 1)
    clearTurnFlags(state)
end

local function drawIntoHand(state, hand, count)
    local drawnCount = 0
    for _ = 1, tonumber(count) or 0 do
        local drawn = PSC_Rules.drawCard(state)
        if drawn then
            table.insert(hand, drawn)
            drawnCount = drawnCount + 1
        end
    end
    return drawnCount
end

local function applyCardEffect(host, session, state, playerName, card, chosenColor)
    local value = PSC_Rules.cardValue(card)
    local color = PSC_Rules.cardColor(card)
    if color == "wild" then
        state.currentColor = chosenColor or PSC_Rules.bestColorForHand(state.hands[playerName] or {})
    else
        state.currentColor = color
    end
    if value == "S" then
        advanceTurn(session, state, 2)
        PSC.addEvent(session, tostring(playerName) .. " played Skip.", "play")
    elseif value == "R" then
        if #session.players == 2 then
            advanceTurn(session, state, 2)
        else
            state.direction = -(state.direction or 1)
            advanceTurn(session, state, 1)
        end
        PSC.addEvent(session, tostring(playerName) .. " reversed direction.", "play")
    elseif value == "D2" and state.stackingEnabled then
        state.pendingDraw = (state.pendingDraw or 0) + 2
        state.pendingDrawValue = 2
        advanceTurn(session, state, 1)
        PSC.addEvent(session, tostring(playerName) .. " stacked +2. Total penalty: +" .. tostring(state.pendingDraw) .. ".", "play")
    elseif value == "D2" then
        local targetIndex = PSC_Rules.nextIndex(state, #session.players, 1)
        local target = session.players[targetIndex]
        local drawnCount = drawIntoHand(state, state.hands[target], 2)
        host:pushDrawAnimations(state, target, drawnCount)
        advanceTurn(session, state, 2)
        PSC.addEvent(session, tostring(target) .. " drew two cards.", "draw")
    elseif value == "WD4" and state.stackingEnabled then
        state.pendingDraw = (state.pendingDraw or 0) + 4
        state.pendingDrawValue = 4
        advanceTurn(session, state, 1)
        PSC.addEvent(session, tostring(playerName) .. " stacked +4. Total penalty: +" .. tostring(state.pendingDraw) .. ".", "play")
    elseif value == "WD4" then
        local targetIndex = PSC_Rules.nextIndex(state, #session.players, 1)
        local target = session.players[targetIndex]
        local drawnCount = drawIntoHand(state, state.hands[target], 4)
        host:pushDrawAnimations(state, target, drawnCount)
        advanceTurn(session, state, 2)
        PSC.addEvent(session, tostring(target) .. " drew four cards.", "draw")
    else
        advanceTurn(session, state, 1)
        PSC.addEvent(session, tostring(playerName) .. " played " .. PSC_Rules.cardLabel(card) .. ".", "play")
    end
end

function Host:finishGame(session, state, playerName)
    state.winner = playerName
    session.phase = PSC.PHASE_GAME_OVER
    if not PSC.isBot(session, playerName) then
        self:applyMoodRelief(playerName, 0, 0, PSC.WINNER_UNHAPPINESS_RELIEF)
    end
    PSC.addEvent(session, tostring(playerName) .. " won the round.", "win")
    return true
end

function Host:finishIfWon(session, state, playerName)
    if #(state.hands[playerName] or {}) > 0 then
        return false
    end
    return self:finishGame(session, state, playerName)
end

function Host:finishExhaustedGame(session, state)
    local winner, lowest = nil, nil
    for _, name in ipairs(session.players or {}) do
        local count = #(state.hands[name] or {})
        if lowest == nil or count < lowest then
            winner, lowest = name, count
        end
    end
    if not winner then return false end
    PSC.addEvent(session, "No cards remain to draw. Lowest hand wins.", "draw")
    return self:finishGame(session, state, winner)
end

function Host:relieveActivePlayers()
    for _, session in pairs(self.sessions) do
        if session.phase == PSC.PHASE_PLAYING then
            for i = 1, #(session.players or {}) do
                local name = session.players[i]
                if not PSC.isBot(session, name) then
                    self:applyMoodRelief(
                        name,
                        PSC.MOOD_BOREDOM_RELIEF_PER_MINUTE,
                        PSC.MOOD_STRESS_RELIEF_PER_MINUTE,
                        PSC.MOOD_UNHAPPINESS_RELIEF_PER_MINUTE
                    )
                end
            end
        end
    end
end

function Host:applyAction(session, playerName, action, args)
    args = args or {}
    if action == PSC.ACTION_ADD_BOT then
        if session.owner ~= playerName then
            return false, "Only the table owner can add bots."
        end
        if session.phase == PSC.PHASE_PLAYING then
            return false, "Bots cannot be changed during a round."
        end
        return self:addBot(session, args.difficulty)
    end
    if action == PSC.ACTION_REMOVE_BOT then
        if session.owner ~= playerName then
            return false, "Only the table owner can remove bots."
        end
        if session.phase == PSC.PHASE_PLAYING then
            return false, "Bots cannot be changed during a round."
        end
        return self:removeBot(session)
    end
    if action == PSC.ACTION_TOGGLE_STACKING then
        if session.owner ~= playerName then
            return false, "Only the table owner can change rules."
        end
        if session.phase == PSC.PHASE_PLAYING then
            return false, "Rules cannot change during a round."
        end
        session.stackingEnabled = not (session.stackingEnabled == true)
        local status = session.stackingEnabled and "enabled" or "disabled"
        PSC.addEvent(session, tostring(playerName) .. " " .. status .. " draw stacking.", "rule")
        self:refreshPublic(session)
        return true
    end
    if action == PSC.ACTION_START_ROUND then
        if session.owner ~= playerName then
            return false, "Only the table owner can start."
        end
        if session.phase == PSC.PHASE_PLAYING then
            return false, "A round is already in progress."
        end
        return self:startRound(session)
    end
    local state = PSC.currentState(session)
    if session.phase ~= PSC.PHASE_PLAYING then
        return false, "The round has not started."
    end
    if session.players[state.turnIndex or 1] ~= playerName then
        return false, "It is not your turn."
    end
    local hand = state.hands and state.hands[playerName] or {}
    state.unoCalled = state.unoCalled or {}
    if action == PSC.ACTION_CALL_UNO then
        if #hand ~= 2 then
            return false, "Call UNO before playing your second-to-last card."
        end
        if state.unoCalled[playerName] then
            return false, "You already called UNO."
        end
        state.unoCalled[playerName] = true
        PSC.addEvent(session, tostring(playerName) .. " called UNO.", "uno")
        self:refreshPublic(session)
        return true
    end
    if action == PSC.ACTION_DRAW then
        if (state.pendingDraw or 0) > 0 then
            local penalty = state.pendingDraw
            state.pendingDraw = 0
            state.pendingDrawValue = 0
            local drawnCount = drawIntoHand(state, hand, penalty)
            self:pushDrawAnimations(state, playerName, drawnCount)
            state.unoCalled[playerName] = nil
            PSC.addEvent(session, tostring(playerName) .. " took the +" .. tostring(penalty) .. " penalty.", "draw")
            advanceTurn(session, state, 1)
            self:refreshPublic(session)
            return true
        end
        if state.lastDrawnBy == playerName then
            return false, "You already drew this turn."
        end
        local drawn = PSC_Rules.drawCard(state)
        if drawn then
            table.insert(hand, drawn)
            state.lastDrawnBy = playerName
            state.canPassAfterDraw = true
            if PSC_Rules.canPlay(drawn, state) then
                state.forcedCardIndex = #hand
                state.drawnPlayableBy = playerName
            end
            state.unoCalled[playerName] = nil
            self:pushAnimation(state, "draw", playerName, nil)
            PSC.addEvent(session, tostring(playerName) .. " drew a card.", "draw")
            self:refreshPublic(session)
            return true
        end
        self:finishExhaustedGame(session, state)
        self:refreshPublic(session)
        return true
    end
    if action == PSC.ACTION_PASS then
        if (state.pendingDraw or 0) > 0 then
            return false, "Take or stack the draw penalty."
        end
        if state.lastDrawnBy ~= playerName or not state.canPassAfterDraw then
            return false, "Draw before passing."
        end
        PSC.addEvent(session, tostring(playerName) .. " passed.", "pass")
        state.unoCalled[playerName] = nil
        advanceTurn(session, state, 1)
        self:refreshPublic(session)
        return true
    end
    if action == PSC.ACTION_PLAY_CARD then
        local index = tonumber(args.cardIndex)
        if not index or index < 1 or index > #hand then
            return false, "Choose a card from your hand."
        end
        if state.forcedCardIndex and (state.drawnPlayableBy ~= playerName or index ~= state.forcedCardIndex) then
            return false, "You may only play the card you just drew."
        end
        local card = hand[index]
        if not PSC_Rules.canPlay(card, state) then
            return false, "That card cannot be played now."
        end
        local value = PSC_Rules.cardValue(card)
        local chosenColor = tostring(args.color or "")
        if (value == "W" or value == "WD4") and not PSC.COLOR_CODE[chosenColor] then
            return false, "Choose a color for the wild card."
        end
        local hadCalledUno = state.unoCalled[playerName] == true
        table.remove(hand, index)
        table.insert(state.discard, card)
        clearTurnFlags(state)
        self:pushAnimation(state, "play", playerName, card)
        applyCardEffect(self, session, state, playerName, card, chosenColor ~= "" and chosenColor or nil)
        if session.phase ~= PSC.PHASE_GAME_OVER and #(hand or {}) == 1 then
            if hadCalledUno then
                state.unoCalled[playerName] = nil
            else
                local drawnCount = drawIntoHand(state, hand, 2)
                self:pushDrawAnimations(state, playerName, drawnCount)
                PSC.addEvent(session, tostring(playerName) .. " forgot to call UNO and drew two cards.", "uno_penalty")
                state.unoCalled[playerName] = nil
            end
        else
            state.unoCalled[playerName] = nil
        end
        self:finishIfWon(session, state, playerName)
        self:refreshPublic(session)
        return true
    end
    return false, "Unknown action."
end

function PSC.legalActions(session, viewerName)
    local actions = {}
    local isPlayer = PSC.findName(session.players or {}, viewerName) ~= nil
    local isOwner = session.owner == viewerName
    if session.phase ~= PSC.PHASE_PLAYING then
        table.insert(actions, PSC.legalAction(PSC.ACTION_START_ROUND, PSC.text("IGUI_PSC_Start", "Start"), isPlayer and isOwner and #session.players >= PSC.MIN_PLAYERS, isOwner and "Need at least two players." or "Owner only."))
        local stackingLabel = session.stackingEnabled and "Stacking: ON" or "Stacking: OFF"
        table.insert(actions, PSC.legalAction(PSC.ACTION_TOGGLE_STACKING, stackingLabel, isPlayer and isOwner, "Owner only."))
        table.insert(actions, PSC.legalAction(PSC.ACTION_ADD_BOT, PSC.text("IGUI_PSC_AddBot", "Add Bot"), isPlayer and isOwner and #session.players < PSC.MAX_PLAYERS, isOwner and "Table is full." or "Owner only."))
        table.insert(actions, PSC.legalAction(PSC.ACTION_REMOVE_BOT, PSC.text("IGUI_PSC_RemoveBot", "Remove Bot"), isPlayer and isOwner and PSC.firstBot(session) ~= nil, isOwner and "No bots." or "Owner only."))
        return actions
    end
    local state = PSC.currentState(session)
    local active = isPlayer and session.players[state.turnIndex or 1] == viewerName
    local hand = state.hands and state.hands[viewerName] or {}
    for i = 1, #hand do
        local card = hand[i]
        local forced = not state.forcedCardIndex or (state.drawnPlayableBy == viewerName and state.forcedCardIndex == i)
        table.insert(actions, PSC.legalAction(PSC.ACTION_PLAY_CARD, PSC_Rules.cardLabel(card), active and forced and PSC_Rules.canPlay(card, state), active and "Not playable." or "Not your turn.", { cardIndex = i }))
    end
    local drawLabel = (state.pendingDraw or 0) > 0 and ("Take +" .. tostring(state.pendingDraw)) or PSC.text("IGUI_PSC_Draw", "Draw")
    table.insert(actions, PSC.legalAction(PSC.ACTION_DRAW, drawLabel, active and ((state.pendingDraw or 0) > 0 or state.lastDrawnBy ~= viewerName), state.lastDrawnBy == viewerName and "You already drew this turn." or "Not your turn."))
    table.insert(actions, PSC.legalAction(PSC.ACTION_PASS, PSC.text("IGUI_PSC_Pass", "Pass"), active and (state.pendingDraw or 0) == 0 and state.lastDrawnBy == viewerName and state.canPassAfterDraw, "Draw before passing."))
    table.insert(actions, PSC.legalAction(PSC.ACTION_CALL_UNO, PSC.text("IGUI_PSC_CallUno", "Call UNO"), active and #hand == 2 and not (state.unoCalled and state.unoCalled[viewerName]), "Call UNO when you have two cards."))
    return actions
end

function PSC.redactedState(session, viewerName)
    if not session then
        return nil
    end
    local state = PSC.currentState(session)
    local payload = {
        key = session.key,
        anchor = PSC.copy(session.anchor),
        owner = session.owner,
        phase = session.phase,
        players = PSC.copy(session.players or {}),
        spectators = PSC.copy(session.spectators or {}),
        viewerName = viewerName,
        publicState = PSC.copy(session.publicState or {}),
        legalActions = PSC.legalActions(session, viewerName),
        privateState = {
            hand = PSC.copy(state.hands and state.hands[viewerName] or {}),
        },
    }
    return payload
end

function Host:botAction(session, botName)
    local state = PSC.currentState(session)
    local hand = state.hands and state.hands[botName] or {}
    if state.lastDrawnBy == botName and state.canPassAfterDraw then
        if state.forcedCardIndex and state.drawnPlayableBy == botName then
            local card = hand[state.forcedCardIndex]
            if card and PSC_Rules.canPlay(card, state) then
                local args = { cardIndex = state.forcedCardIndex }
                local value = PSC_Rules.cardValue(card)
                if value == "W" or value == "WD4" then
                    args.color = PSC_Rules.bestColorForHand(hand)
                end
                return PSC.ACTION_PLAY_CARD, args
            end
        end
        return PSC.ACTION_PASS, {}
    end
    local bestIndex = nil
    local bestScore = -1
    for i = 1, #hand do
        local card = hand[i]
        if PSC_Rules.canPlay(card, state) then
            local score = PSC_Rules.scoreCard(card)
            if score > bestScore then
                bestScore = score
                bestIndex = i
            end
        end
    end
    if bestIndex then
        if #hand == 2 then
            state.unoCalled = state.unoCalled or {}
            state.unoCalled[botName] = true
            PSC.addEvent(session, tostring(botName) .. " called UNO.", "uno")
        end
        local card = hand[bestIndex]
        local args = { cardIndex = bestIndex }
        local value = PSC_Rules.cardValue(card)
        if value == "W" or value == "WD4" then
            args.color = PSC_Rules.bestColorForHand(hand)
        end
        return PSC.ACTION_PLAY_CARD, args
    end
    return PSC.ACTION_DRAW, {}
end

function Host:updateBots()
    for _, session in pairs(self.sessions) do
        if session.phase == PSC.PHASE_PLAYING then
            local state = PSC.currentState(session)
            local current = session.players[state.turnIndex or 1]
            if PSC.isBot(session, current) then
                local due = tonumber(session.botDueAt) or 0
                local now = self:now()
                if due <= 0 then
                    session.botDueAt = now + PSC.BOT_ACTION_DELAY_MS
                elseif now >= due then
                    session.botDueAt = nil
                    local action, args = self:botAction(session, current)
                    self:applyAction(session, current, action, args or {})
                    self:broadcast(session)
                end
            else
                session.botDueAt = nil
            end
        end
    end
end

function Host:handleStart(playerObj, args)
    local anchor = PSC.anchorFromArgs(args)
    local name = self:playerName(playerObj, args)
    if not anchor then
        self:message(playerObj, "No valid table.")
        return
    end
    if not PSC.playerNearAnchor(playerObj, anchor, PSC.MAX_PLAY_DISTANCE) then
        self:message(playerObj, PSC.text("IGUI_PSC_MoveCloser", "Move closer to the table."))
        return
    end
    local session = self.sessions[anchor.key] or self:createSession(anchor, name)
    if session.phase == PSC.PHASE_PLAYING and not PSC.findName(session.players, name) then
        self:addSpectator(session, name)
    else
        self:addPlayer(session, name)
    end
    self:sendState(playerObj, session, name)
    self:broadcast(session)
end

function Host:handleJoin(playerObj, args)
    return self:handleStart(playerObj, args)
end

function Host:handleWatch(playerObj, args)
    local anchor = PSC.anchorFromArgs(args)
    local name = self:playerName(playerObj, args)
    local session = anchor and self.sessions[anchor.key] or nil
    if not session then
        self:message(playerObj, "There is no active table to watch.")
        return
    end
    if not PSC.playerNearAnchor(playerObj, session.anchor, PSC.MAX_PLAY_DISTANCE) then
        self:message(playerObj, PSC.text("IGUI_PSC_MoveCloser", "Move closer to the table."))
        return
    end
    self:addSpectator(session, name)
    self:sendState(playerObj, session, name)
    self:broadcast(session)
end

function Host:removeParticipant(session, name)
    if not session or not name then return false end
    local state = PSC.currentState(session)
    local leavingIndex = PSC.findName(session.players, name)
    local spectatorIndex = PSC.findName(session.spectators, name)
    if not leavingIndex and not spectatorIndex then return false end
    local currentName = session.players[state.turnIndex or 1]
    local wasCurrent = currentName == name
    PSC.removeName(session.players, name)
    PSC.removeName(session.spectators, name)
    local nextOwner = firstHumanPlayer(session)
    if #session.players == 0 or not nextOwner then
        self.sessions[session.key] = nil
        return true
    end
    if session.owner == name then
        session.owner = nextOwner
    end
    state.hands = state.hands or {}
    state.hands[name] = nil
    if state.unoCalled then state.unoCalled[name] = nil end
    session.botDueAt = nil
    if session.phase == PSC.PHASE_PLAYING and leavingIndex then
        if #session.players == 1 then
            self:finishGame(session, state, session.players[1])
        elseif wasCurrent then
            if (state.direction or 1) < 0 then
                state.turnIndex = leavingIndex - 1
                if state.turnIndex < 1 then state.turnIndex = #session.players end
            else
                state.turnIndex = leavingIndex
                if state.turnIndex > #session.players then state.turnIndex = 1 end
            end
            clearTurnFlags(state)
        elseif currentName then
            state.turnIndex = PSC.findName(session.players, currentName) or 1
        end
    elseif (state.turnIndex or 1) > #session.players then
        state.turnIndex = 1
    end
    PSC.addEvent(session, tostring(name) .. " left the table.", "leave")
    self:refreshPublic(session)
    return true
end

function Host:handleLeave(playerObj, args)
    local anchor = PSC.anchorFromArgs(args)
    local name = self:playerName(playerObj, args)
    local session = anchor and self.sessions[anchor.key] or nil
    if not session or not self:removeParticipant(session, name) then return end
    if self.sessions[session.key] then
        self:broadcast(session)
    end
end

function Host:pruneDisconnected()
    if not self.env.findPlayerByName then return end
    for _, session in pairs(self.sessions) do
        local missing = {}
        for _, name in ipairs(session.players or {}) do
            if not PSC.isBot(session, name) and not self.env.findPlayerByName(name) then
                table.insert(missing, name)
            end
        end
        for _, name in ipairs(session.spectators or {}) do
            if not self.env.findPlayerByName(name) then
                table.insert(missing, name)
            end
        end
        local changed = false
        for _, name in ipairs(missing) do
            changed = self:removeParticipant(session, name) or changed
            if not self.sessions[session.key] then break end
        end
        if changed and self.sessions[session.key] then
            self:broadcast(session)
        end
    end
end

function Host:validateTableDistance(playerObj, session)
    if PSC.playerNearAnchor(playerObj, session and session.anchor, PSC.MAX_PLAY_DISTANCE) then
        return true
    end
    self:message(playerObj, PSC.text("IGUI_PSC_MoveCloser", "Move closer to the table."))
    return false
end

function Host:handleReset(playerObj, args)
    local anchor = PSC.anchorFromArgs(args)
    local name = self:playerName(playerObj, args)
    local old = anchor and self.sessions[anchor.key] or nil
    if not old then
        return
    end
    if not self:validateTableDistance(playerObj, old) then return end
    if old.owner ~= name then
        self:message(playerObj, "Only the table owner can reset.")
        return
    end
    local session = self:createSession(anchor, name)
    session.players = PSC.copy(old.players)
    session.spectators = PSC.copy(old.spectators)
    session.bots = PSC.copy(old.bots)
    session.stackingEnabled = old.stackingEnabled == true
    session.owner = name
    PSC.addEvent(session, tostring(name) .. " reset the table.", "reset")
    self:refreshPublic(session)
    self:broadcast(session)
end

function Host:handleAction(playerObj, args)
    local anchor = PSC.anchorFromArgs(args)
    local name = self:playerName(playerObj, args)
    local session = anchor and self.sessions[anchor.key] or nil
    if not session then
        self:message(playerObj, "This table is not active.")
        return
    end
    if not self:validateTableDistance(playerObj, session) then return end
    if not PSC.findName(session.players, name) then
        self:message(playerObj, "Join the table before playing.")
        return
    end
    local ok, reason = self:applyAction(session, name, tostring(args.action or ""), args or {})
    if not ok then
        self:message(playerObj, reason or "That action is not legal.")
        self:sendState(playerObj, session, name)
        return
    end
    self:broadcast(session)
end

function Host:handleCommand(playerObj, command, args)
    args = args or {}
    if command == PSC.CMD_START then
        self:handleStart(playerObj, args)
    elseif command == PSC.CMD_JOIN then
        self:handleJoin(playerObj, args)
    elseif command == PSC.CMD_WATCH then
        self:handleWatch(playerObj, args)
    elseif command == PSC.CMD_LEAVE then
        self:handleLeave(playerObj, args)
    elseif command == PSC.CMD_RESET then
        self:handleReset(playerObj, args)
    elseif command == PSC.CMD_ACTION then
        self:handleAction(playerObj, args)
    end
end

function Host:onTick()
    self.tickCounter = (self.tickCounter or 0) + 1
    if self.tickCounter % 600 == 0 then
        self:pruneDisconnected()
    end
    self:updateBots()
end
