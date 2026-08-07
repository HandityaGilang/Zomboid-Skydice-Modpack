require "UnoNoMercy/UNM_Core"
require "UnoNoMercy/UNM_Rules"

UNM_Host = UNM_Host or {}

local Host = {}
Host.__index = Host

local function nowMs()
    return getTimestampMs and getTimestampMs() or math.floor(os.time() * 1000)
end

function UNM_Host.new(env)
    return setmetatable({ sessions = {}, env = env or {}, tickCounter = 0 }, Host)
end

function Host:now()
    return self.env.now and self.env.now() or nowMs()
end

function Host:playerName(playerObj, args)
    if self.env.playerName then
        local value = self.env.playerName(playerObj, args or {})
        if value and value ~= "" then return tostring(value) end
    end
    return UNM.username(playerObj)
end

function Host:message(playerObj, text)
    if self.env.message then self.env.message(playerObj, tostring(text or "UNO No Mercy is unavailable.")) end
end

function Host:applyMoodRelief(playerName, boredom, stress, unhappiness)
    if self.env.applyMoodRelief then self.env.applyMoodRelief(playerName, boredom, stress, unhappiness) end
end

function Host:sendState(playerObj, session, viewerName)
    if self.env.sendState then self.env.sendState(playerObj, UNM.redactedState(session, viewerName)) end
end

function Host:broadcast(session)
    if not session then return end
    if self.env.findPlayerByName then
        for _, name in ipairs(session.players or {}) do
            if not UNM.isBot(session, name) then
                self:sendState(self.env.findPlayerByName(name), session, name)
            end
        end
        for _, name in ipairs(session.spectators or {}) do
            self:sendState(self.env.findPlayerByName(name), session, name)
        end
    elseif self.env.localBroadcast then
        self.env.localBroadcast(session)
    end
end

local function firstHumanPlayer(session)
    for _, name in ipairs(session.players or {}) do
        if not UNM.isBot(session, name) then return name end
    end
end

local function isActive(state, name)
    return name and not (state.eliminated and state.eliminated[name])
end

local function activeCount(session, state)
    local count, last = 0, nil
    for _, name in ipairs(session.players or {}) do
        if isActive(state, name) then
            count = count + 1
            last = name
        end
    end
    return count, last
end

local function nextActiveIndex(session, state, startIndex, steps)
    local count = #session.players
    if count <= 0 then return 1 end
    local index = tonumber(startIndex) or tonumber(state.turnIndex) or 1
    local remaining = math.max(1, tonumber(steps) or 1)
    local guard = 0
    while remaining > 0 and guard < count * (remaining + 2) do
        index = UNM_Rules.nextIndex({ direction = state.direction, turnIndex = index }, count, 1)
        if isActive(state, session.players[index]) then remaining = remaining - 1 end
        guard = guard + 1
    end
    return index
end

local function clearTurnFlags(state)
    state.lastDrawnBy = nil
    state.forcedCardIndex = nil
    state.drawnPlayableBy = nil
end

local function advanceTurn(session, state, steps)
    state.turnIndex = nextActiveIndex(session, state, state.turnIndex, steps or 1)
    clearTurnFlags(state)
end

function Host:createSession(anchor, ownerName)
    local session = {
        key = anchor.key,
        anchor = UNM.copy(anchor),
        owner = ownerName,
        players = { ownerName },
        spectators = {},
        bots = {},
        mercyEnabled = true,
        sevenZeroEnabled = true,
        phase = UNM.PHASE_WAITING,
        publicState = {
            title = "UNO No Mercy",
            players = { ownerName },
            spectators = {},
            handCounts = {},
            currentPlayerName = ownerName,
            currentColor = nil,
            topCard = nil,
            deckCount = 0,
            direction = 1,
            mercyEnabled = true,
            sevenZeroEnabled = true,
            roundNo = 0,
            events = {},
        },
        privateState = { uno = {} },
        seed = tostring(anchor.key) .. ":" .. tostring(self:now()),
        touched = self:now(),
    }
    UNM.addEvent(session, tostring(ownerName) .. " opened a No Mercy table.", "join")
    self.sessions[anchor.key] = session
    return session
end

function Host:refreshPublic(session)
    local state = session.privateState.uno or {}
    local currentName = session.players[state.turnIndex or 1]
    session.publicState.players = UNM.copy(session.players or {})
    session.publicState.spectators = UNM.copy(session.spectators or {})
    session.publicState.bots = UNM.copy(session.bots or {})
    session.publicState.phase = session.phase
    session.publicState.currentPlayerName = isActive(state, currentName) and currentName or nil
    session.publicState.currentColor = state.currentColor
    session.publicState.topCard = UNM_Rules.topDiscard(state)
    session.publicState.deckCount = #(state.deck or {})
    session.publicState.direction = state.direction or 1
    session.publicState.winner = state.winner
    session.publicState.winners = UNM.copy(state.winners or {})
    session.publicState.pendingDraw = state.pendingDraw or 0
    session.publicState.pendingDrawMinimum = state.pendingDrawMinimum or 0
    session.publicState.pendingRoulette = state.pendingRoulette == true
    session.publicState.eliminated = UNM.copy(state.eliminated or {})
    session.publicState.mercyEnabled = session.mercyEnabled ~= false
    session.publicState.sevenZeroEnabled = session.sevenZeroEnabled ~= false
    session.publicState.animation = UNM.copy(state.animation)
    session.publicState.animations = UNM.copy(state.animations or {})
    session.publicState.unoCalled = UNM.copy(state.unoCalled or {})
    session.publicState.roundNo = session.roundNo or 0
    session.publicState.handCounts = {}
    for _, name in ipairs(session.players or {}) do
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
    while #state.animations > 192 do table.remove(state.animations, 1) end
end

function Host:pushDrawAnimations(state, playerName, count)
    for _ = 1, tonumber(count) or 0 do self:pushAnimation(state, "draw", playerName) end
end

function Host:addPlayer(session, name)
    if UNM.findName(session.players, name) then return true end
    if #session.players >= UNM.MAX_PLAYERS then
        local bot = UNM.firstBot(session)
        if not bot then return false, "This table is full." end
        session.bots[bot] = nil
        UNM.removeName(session.players, bot)
        UNM.addEvent(session, bot .. " gave up a seat for " .. name .. ".", "leave")
    end
    UNM.removeName(session.spectators, name)
    table.insert(session.players, name)
    UNM.addEvent(session, name .. " joined the table.", "join")
    self:refreshPublic(session)
    return true
end

function Host:addSpectator(session, name)
    if UNM.findName(session.players, name) or UNM.findName(session.spectators, name) then return true end
    table.insert(session.spectators, name)
    UNM.addEvent(session, name .. " is watching.", "watch")
    self:refreshPublic(session)
    return true
end

function Host:addBot(session, difficulty)
    if #session.players >= UNM.MAX_PLAYERS then return false, "This table is full." end
    local n, name = 1, "Mercy Bot"
    while UNM.findName(session.players, name) do
        n = n + 1
        name = "Mercy Bot " .. tostring(n)
    end
    session.bots[name] = { difficulty = tostring(difficulty or "medium") }
    table.insert(session.players, name)
    UNM.addEvent(session, name .. " joined as a bot.", "join")
    self:refreshPublic(session)
    return true
end

function Host:removeBot(session)
    local name = UNM.firstBot(session)
    if not name then return false, "There is no bot to remove." end
    session.bots[name] = nil
    UNM.removeName(session.players, name)
    UNM.addEvent(session, name .. " left the table.", "leave")
    self:refreshPublic(session)
    return true
end

function Host:startRound(session)
    if #session.players < UNM.MIN_PLAYERS then return false, "Need at least two players." end
    session.roundNo = (session.roundNo or 0) + 1
    local seed = tostring(session.seed) .. ":round:" .. tostring(session.roundNo)
    local state = {
        seed = seed,
        deck = UNM_Rules.newDeck(seed),
        discard = {},
        eliminatedCards = {},
        hands = {},
        eliminated = {},
        unoCalled = {},
        animations = {},
        animationSeq = 0,
        direction = 1,
        turnIndex = 1,
        pendingDraw = 0,
        pendingDrawMinimum = 0,
        mercyEnabled = session.mercyEnabled ~= false,
        sevenZeroEnabled = session.sevenZeroEnabled ~= false,
    }
    for _, name in ipairs(session.players) do
        state.hands[name] = {}
        for _ = 1, UNM.START_HAND_SIZE do
            table.insert(state.hands[name], UNM_Rules.drawCard(state))
        end
    end
    local first = UNM_Rules.drawCard(state)
    while first and UNM_Rules.isActionCard(first) do
        table.insert(state.discard, first)
        first = UNM_Rules.drawCard(state)
    end
    first = first or "R1"
    table.insert(state.discard, first)
    state.currentColor = UNM_Rules.cardColor(first)
    session.privateState.uno = state
    session.phase = UNM.PHASE_PLAYING
    UNM.addEvent(session, "No Mercy began. " .. session.players[1] .. " leads.", "deal")
    self:refreshPublic(session)
    return true
end

function UNM.currentState(session)
    return session and session.privateState and session.privateState.uno or {}
end

function Host:finishGame(session, state, winner)
    if not winner then return false end
    state.winner = winner
    state.winners = { winner }
    session.phase = UNM.PHASE_GAME_OVER
    if not UNM.isBot(session, winner) then
        self:applyMoodRelief(winner, 0, 0, UNM.WINNER_UNHAPPINESS_RELIEF)
    end
    UNM.addEvent(session, winner .. " won No Mercy.", "win")
    return true
end

function Host:checkLastSurvivor(session, state)
    local count, last = activeCount(session, state)
    if count == 1 then return self:finishGame(session, state, last) end
    return false
end

function Host:finishEmptyHand(session, state)
    for _, name in ipairs(session.players or {}) do
        if isActive(state, name) and #(state.hands[name] or {}) == 0 then
            return self:finishGame(session, state, name)
        end
    end
    return false
end

function Host:finishExhaustedGame(session, state)
    local winners, lowest = {}, nil
    for _, name in ipairs(session.players or {}) do
        if isActive(state, name) then
            local count = #(state.hands[name] or {})
            if lowest == nil or count < lowest then
                winners, lowest = { name }, count
            elseif count == lowest then
                table.insert(winners, name)
            end
        end
    end
    if #winners == 0 then return false end
    UNM.addEvent(session, "No cards remain to draw. Lowest hand wins.", "draw")
    if #winners == 1 then return self:finishGame(session, state, winners[1]) end
    state.winners = winners
    state.winner = table.concat(winners, " & ")
    session.phase = UNM.PHASE_GAME_OVER
    for _, winner in ipairs(winners) do
        if not UNM.isBot(session, winner) then
            self:applyMoodRelief(winner, 0, 0, UNM.WINNER_UNHAPPINESS_RELIEF)
        end
    end
    UNM.addEvent(session, state.winner .. " tied for the No Mercy win.", "win")
    return true
end

local function drawSupplyExhausted(state)
    return #(state.deck or {}) == 0
end

function Host:eliminateIfNeeded(session, state, name)
    local hand = state.hands[name] or {}
    if session.mercyEnabled == false or state.mercyEnabled == false then return false end
    if state.eliminated[name] or #hand < UNM.MERCY_HAND_LIMIT then return false end
    state.eliminated[name] = true
    state.eliminatedCards = state.eliminatedCards or {}
    for _, card in ipairs(hand) do table.insert(state.eliminatedCards, card) end
    state.hands[name] = {}
    state.unoCalled[name] = nil
    UNM.addEvent(session, name .. " reached 25 cards and was eliminated.", "eliminated")
    return self:checkLastSurvivor(session, state)
end

function Host:drawIntoHand(session, state, name, count)
    local hand = state.hands[name] or {}
    state.hands[name] = hand
    local drawn = 0
    for _ = 1, tonumber(count) or 0 do
        local card = UNM_Rules.drawCard(state)
        if card then
            table.insert(hand, card)
            drawn = drawn + 1
        end
    end
    self:pushDrawAnimations(state, name, drawn)
    self:eliminateIfNeeded(session, state, name)
    return drawn
end

local function rotateHands(session, state)
    local activeIndices = {}
    for i, name in ipairs(session.players) do
        if isActive(state, name) then table.insert(activeIndices, i) end
    end
    if #activeIndices < 2 then return end
    local old = {}
    for _, index in ipairs(activeIndices) do old[index] = state.hands[session.players[index]] end
    for _, index in ipairs(activeIndices) do
        local source = nextActiveIndex(session, { direction = -(state.direction or 1), eliminated = state.eliminated }, index, 1)
        state.hands[session.players[index]] = old[source]
    end
end

local function discardMatchingColor(state, hand, color)
    local count = 0
    for i = #hand, 1, -1 do
        if UNM_Rules.cardColor(hand[i]) == color then
            table.insert(state.discard, table.remove(hand, i))
            count = count + 1
        end
    end
    return count
end

function Host:resolveRoulette(session, state, playerName, color)
    local drawn, matched = 0, false
    while true do
        local card = UNM_Rules.drawCard(state)
        if not card then break end
        table.insert(state.hands[playerName], card)
        drawn = drawn + 1
        if UNM_Rules.cardColor(card) == color then
            matched = true
            break
        end
    end
    self:pushDrawAnimations(state, playerName, drawn)
    state.pendingRoulette = nil
    state.currentColor = color
    UNM.addEvent(session, playerName .. " chose " .. UNM.COLOR_LABEL[color] .. " and drew " .. drawn .. " roulette cards.", "draw")
    if not matched then
        self:finishExhaustedGame(session, state)
    elseif not self:eliminateIfNeeded(session, state, playerName) then
        advanceTurn(session, state, 1)
    end
end

function Host:applyCardEffect(session, state, playerName, card, args)
    local value = UNM_Rules.cardValue(card)
    local color = UNM_Rules.cardColor(card)
    if color == "wild" then
        state.currentColor = args.color or UNM_Rules.bestColorForHand(state.hands[playerName])
    else
        state.currentColor = color
    end

    if UNM_Rules.isDrawCard(card) then
        local amount = UNM_Rules.drawValue(card)
        state.pendingDraw = (state.pendingDraw or 0) + amount
        state.pendingDrawMinimum = amount
        if value == "WR4" then
            state.direction = -(state.direction or 1)
            if activeCount(session, state) == 2 then
                clearTurnFlags(state)
            else
                advanceTurn(session, state, 1)
            end
        else
            advanceTurn(session, state, 1)
        end
        UNM.addEvent(session, playerName .. " stacked +" .. amount .. ". Total penalty: " .. state.pendingDraw .. ".", "play")
    elseif value == "S" then
        advanceTurn(session, state, 2)
        UNM.addEvent(session, playerName .. " skipped the next player.", "play")
    elseif value == "SA" then
        clearTurnFlags(state)
        UNM.addEvent(session, playerName .. " skipped everyone and plays again.", "play")
    elseif value == "R" then
        state.direction = -(state.direction or 1)
        if activeCount(session, state) == 2 then
            clearTurnFlags(state)
        else
            advanceTurn(session, state, 1)
        end
        UNM.addEvent(session, playerName .. " reversed direction.", "play")
    elseif value == "DA" then
        local count = discardMatchingColor(state, state.hands[playerName], color)
        advanceTurn(session, state, 1)
        UNM.addEvent(session, playerName .. " discarded " .. count .. " additional " .. UNM.COLOR_LABEL[color] .. " cards.", "play")
    elseif value == "7" and state.sevenZeroEnabled ~= false then
        local target = tostring(args.targetName or "")
        if target ~= "" and target ~= playerName and UNM.findName(session.players, target) and isActive(state, target) then
            state.hands[playerName], state.hands[target] = state.hands[target], state.hands[playerName]
            UNM.addEvent(session, playerName .. " swapped hands with " .. target .. ".", "play")
            self:eliminateIfNeeded(session, state, playerName)
            self:eliminateIfNeeded(session, state, target)
        end
        advanceTurn(session, state, 1)
    elseif value == "0" and state.sevenZeroEnabled ~= false then
        rotateHands(session, state)
        for _, name in ipairs(session.players) do self:eliminateIfNeeded(session, state, name) end
        advanceTurn(session, state, 1)
        UNM.addEvent(session, "All hands passed in the direction of play.", "play")
    elseif value == "WCR" then
        advanceTurn(session, state, 1)
        state.pendingRoulette = true
        UNM.addEvent(session, session.players[state.turnIndex] .. " must choose a roulette color.", "play")
    else
        advanceTurn(session, state, 1)
        UNM.addEvent(session, playerName .. " played " .. UNM_Rules.cardLabel(card) .. ".", "play")
    end
end

function Host:relieveActivePlayers()
    for _, session in pairs(self.sessions) do
        if session.phase == UNM.PHASE_PLAYING then
            local state = UNM.currentState(session)
            for _, name in ipairs(session.players or {}) do
                if isActive(state, name) and not UNM.isBot(session, name) then
                    self:applyMoodRelief(name, UNM.MOOD_BOREDOM_RELIEF_PER_MINUTE, UNM.MOOD_STRESS_RELIEF_PER_MINUTE, UNM.MOOD_UNHAPPINESS_RELIEF_PER_MINUTE)
                end
            end
        end
    end
end

function Host:applyAction(session, playerName, action, args)
    args = args or {}
    if action == UNM.ACTION_ADD_BOT then
        if session.owner ~= playerName then return false, "Only the table owner can add bots." end
        if session.phase == UNM.PHASE_PLAYING then return false, "Bots cannot be changed during a round." end
        return self:addBot(session, args.difficulty)
    elseif action == UNM.ACTION_REMOVE_BOT then
        if session.owner ~= playerName then return false, "Only the table owner can remove bots." end
        if session.phase == UNM.PHASE_PLAYING then return false, "Bots cannot be changed during a round." end
        return self:removeBot(session)
    elseif action == UNM.ACTION_TOGGLE_MERCY then
        if session.owner ~= playerName then return false, "Only the table owner can change rules." end
        if session.phase == UNM.PHASE_PLAYING then return false, "Rules cannot change during a round." end
        session.mercyEnabled = not (session.mercyEnabled ~= false)
        local status = session.mercyEnabled and "enabled" or "disabled"
        UNM.addEvent(session, playerName .. " " .. status .. " the 25-card Mercy Rule.", "rule")
        self:refreshPublic(session)
        return true
    elseif action == UNM.ACTION_TOGGLE_SEVEN_ZERO then
        if session.owner ~= playerName then return false, "Only the table owner can change rules." end
        if session.phase == UNM.PHASE_PLAYING then return false, "Rules cannot change during a round." end
        session.sevenZeroEnabled = not (session.sevenZeroEnabled ~= false)
        local status = session.sevenZeroEnabled and "enabled" or "disabled"
        UNM.addEvent(session, playerName .. " " .. status .. " the 0/7 hand rules.", "rule")
        self:refreshPublic(session)
        return true
    elseif action == UNM.ACTION_START_ROUND then
        if session.owner ~= playerName then return false, "Only the table owner can start." end
        if session.phase == UNM.PHASE_PLAYING then return false, "A round is already in progress." end
        return self:startRound(session)
    end

    local state = UNM.currentState(session)
    if session.phase ~= UNM.PHASE_PLAYING then return false, "The round has not started." end
    if state.eliminated[playerName] then return false, "You were eliminated by the Mercy Rule." end

    local hand = state.hands[playerName] or {}
    state.unoCalled = state.unoCalled or {}
    if action == UNM.ACTION_CALL_UNO then
        if state.unoVulnerable == playerName then
            state.unoVulnerable = nil
            UNM.addEvent(session, playerName .. " called UNO.", "uno")
            self:refreshPublic(session)
            return true
        end
        if session.players[state.turnIndex or 1] ~= playerName or #hand ~= 2 then
            return false, "Call UNO before playing your second-to-last card."
        end
        if state.unoCalled[playerName] then return false, "You already called UNO." end
        state.unoCalled[playerName] = true
        UNM.addEvent(session, playerName .. " called UNO.", "uno")
        self:refreshPublic(session)
        return true
    elseif action == UNM.ACTION_CATCH_UNO then
        local target = state.unoVulnerable
        if not target or target == playerName then return false, "There is nobody to catch." end
        state.unoVulnerable = nil
        local drawn = self:drawIntoHand(session, state, target, 2)
        UNM.addEvent(session, playerName .. " caught " .. target .. " without UNO. " .. target .. " drew two cards.", "uno_penalty")
        if session.phase == UNM.PHASE_PLAYING and drawn < 2 then
            self:finishExhaustedGame(session, state)
        end
        self:refreshPublic(session)
        return true
    end

    if session.players[state.turnIndex or 1] ~= playerName then return false, "It is not your turn." end
    state.unoVulnerable = nil

    if state.pendingRoulette then
        if action ~= UNM.ACTION_ROULETTE_COLOR or not UNM.COLOR_CODE[tostring(args.color or "")] then
            return false, "Choose a color for Color Roulette."
        end
        self:resolveRoulette(session, state, playerName, tostring(args.color))
        self:refreshPublic(session)
        return true
    end

    if action == UNM.ACTION_DRAW then
        if (state.pendingDraw or 0) > 0 then
            local penalty = state.pendingDraw
            state.pendingDraw, state.pendingDrawMinimum = 0, 0
            UNM.addEvent(session, playerName .. " took the +" .. penalty .. " penalty.", "draw")
            local drawn = self:drawIntoHand(session, state, playerName, penalty)
            if session.phase == UNM.PHASE_PLAYING and drawn < penalty then
                self:finishExhaustedGame(session, state)
            elseif session.phase == UNM.PHASE_PLAYING then
                advanceTurn(session, state, 1)
            end
            self:refreshPublic(session)
            return true
        end
        local drawn = 0
        while true do
            local card = UNM_Rules.drawCard(state)
            if not card then break end
            table.insert(hand, card)
            drawn = drawn + 1
            self:pushAnimation(state, "draw", playerName)
            if self:eliminateIfNeeded(session, state, playerName) then break end
            if state.eliminated[playerName] then break end
            if UNM_Rules.canPlay(card, state) then
                state.forcedCardIndex = #hand
                state.drawnPlayableBy = playerName
                break
            end
        end
        UNM.addEvent(session, playerName .. " drew " .. drawn .. " card" .. (drawn == 1 and "" or "s") .. " to find a playable card.", "draw")
        if session.phase == UNM.PHASE_PLAYING and not state.forcedCardIndex and drawSupplyExhausted(state) then
            self:finishExhaustedGame(session, state)
        elseif session.phase == UNM.PHASE_PLAYING and state.eliminated[playerName] then
            advanceTurn(session, state, 1)
        end
        self:refreshPublic(session)
        return true
    elseif action == UNM.ACTION_PLAY_CARD then
        local index = tonumber(args.cardIndex)
        if not index or index < 1 or index > #hand then return false, "Choose a card from your hand." end
        if state.forcedCardIndex and (state.drawnPlayableBy ~= playerName or index ~= state.forcedCardIndex) then
            return false, "You must play the card you just drew."
        end
        local card = hand[index]
        if not UNM_Rules.canPlay(card, state) then return false, "That card cannot be played now." end
        if UNM_Rules.requiresColor(card) and not UNM.COLOR_CODE[tostring(args.color or "")] then
            return false, "Choose a color."
        end
        if UNM_Rules.requiresTarget(card, state) then
            local target = tostring(args.targetName or "")
            if target == "" or target == playerName or not UNM.findName(session.players, target) or not isActive(state, target) then
                return false, "Choose another active player for the hand swap."
            end
        end
        local calledUno = state.unoCalled[playerName] == true
        table.remove(hand, index)
        table.insert(state.discard, card)
        clearTurnFlags(state)
        self:pushAnimation(state, "play", playerName, card)
        self:applyCardEffect(session, state, playerName, card, args)
        if session.phase == UNM.PHASE_PLAYING and self:finishEmptyHand(session, state) then
        elseif session.phase == UNM.PHASE_PLAYING and #state.hands[playerName] == 1 then
            if not calledUno then state.unoVulnerable = playerName end
            state.unoCalled[playerName] = nil
        else
            state.unoCalled[playerName] = nil
        end
        self:refreshPublic(session)
        return true
    end
    return false, "Unknown action."
end

function UNM.legalActions(session, viewerName)
    local actions = {}
    local isPlayer = UNM.findName(session.players or {}, viewerName) ~= nil
    local isOwner = session.owner == viewerName
    if session.phase ~= UNM.PHASE_PLAYING then
        table.insert(actions, UNM.legalAction(UNM.ACTION_START_ROUND, UNM.text("IGUI_UNM_Start", "Start"), isPlayer and isOwner and #session.players >= UNM.MIN_PLAYERS, isOwner and "Need at least two players." or "Owner only."))
        local mercyLabel = session.mercyEnabled ~= false and "Mercy Rule: ON" or "Mercy Rule: OFF"
        table.insert(actions, UNM.legalAction(UNM.ACTION_TOGGLE_MERCY, mercyLabel, isPlayer and isOwner, "Owner only."))
        local sevenZeroLabel = session.sevenZeroEnabled ~= false and "0/7 Rules: ON" or "0/7 Rules: OFF"
        table.insert(actions, UNM.legalAction(UNM.ACTION_TOGGLE_SEVEN_ZERO, sevenZeroLabel, isPlayer and isOwner, "Owner only."))
        table.insert(actions, UNM.legalAction(UNM.ACTION_ADD_BOT, UNM.text("IGUI_UNM_AddBot", "Add Bot"), isPlayer and isOwner and #session.players < UNM.MAX_PLAYERS, isOwner and "Table is full." or "Owner only."))
        table.insert(actions, UNM.legalAction(UNM.ACTION_REMOVE_BOT, UNM.text("IGUI_UNM_RemoveBot", "Remove Bot"), isPlayer and isOwner and UNM.firstBot(session) ~= nil, isOwner and "No bots." or "Owner only."))
        return actions
    end
    local state = UNM.currentState(session)
    local active = isPlayer and not state.eliminated[viewerName] and session.players[state.turnIndex or 1] == viewerName
    local hand = state.hands[viewerName] or {}
    if isPlayer and not state.eliminated[viewerName] and state.unoVulnerable then
        if state.unoVulnerable == viewerName then
            table.insert(actions, UNM.legalAction(UNM.ACTION_CALL_UNO, "Call UNO", true))
        else
            table.insert(actions, UNM.legalAction(UNM.ACTION_CATCH_UNO, "Catch " .. tostring(state.unoVulnerable), true))
        end
    end
    if state.pendingRoulette and active then
        for _, color in ipairs(UNM.COLORS) do
            table.insert(actions, UNM.legalAction(UNM.ACTION_ROULETTE_COLOR, "Roulette: " .. UNM.COLOR_LABEL[color], true, nil, { color = color }))
        end
        return actions
    end
    for i, card in ipairs(hand) do
        local forced = not state.forcedCardIndex or (state.drawnPlayableBy == viewerName and state.forcedCardIndex == i)
        table.insert(actions, UNM.legalAction(UNM.ACTION_PLAY_CARD, UNM_Rules.cardLabel(card), active and forced and UNM_Rules.canPlay(card, state), active and "Not playable." or "Not your turn.", { cardIndex = i }))
    end
    table.insert(actions, UNM.legalAction(UNM.ACTION_DRAW, (state.pendingDraw or 0) > 0 and ("Take +" .. state.pendingDraw) or "Draw Until Playable", active and not state.forcedCardIndex, "Play the drawn card first."))
    if not (state.unoVulnerable == viewerName) then
        table.insert(actions, UNM.legalAction(UNM.ACTION_CALL_UNO, "Call UNO", active and #hand == 2 and not state.unoCalled[viewerName], "Call UNO with two cards."))
    end
    return actions
end

function UNM.redactedState(session, viewerName)
    local state = UNM.currentState(session)
    return {
        key = session.key,
        anchor = UNM.copy(session.anchor),
        owner = session.owner,
        phase = session.phase,
        players = UNM.copy(session.players or {}),
        spectators = UNM.copy(session.spectators or {}),
        viewerName = viewerName,
        publicState = UNM.copy(session.publicState or {}),
        legalActions = UNM.legalActions(session, viewerName),
        privateState = { hand = UNM.copy(state.hands and state.hands[viewerName] or {}) },
    }
end

function Host:botAction(session, botName)
    local state = UNM.currentState(session)
    if state.pendingRoulette then
        return UNM.ACTION_ROULETTE_COLOR, { color = UNM_Rules.bestColorForHand(state.hands[botName]) }
    end
    local hand = state.hands[botName] or {}
    local bestIndex, bestScore = nil, -1
    for i, card in ipairs(hand) do
        if (not state.forcedCardIndex or state.forcedCardIndex == i) and UNM_Rules.canPlay(card, state) then
            local score = UNM_Rules.scoreCard(card)
            if score > bestScore then bestIndex, bestScore = i, score end
        end
    end
    if not bestIndex then return UNM.ACTION_DRAW, {} end
    local card = hand[bestIndex]
    local args = { cardIndex = bestIndex }
    if UNM_Rules.requiresColor(card) then args.color = UNM_Rules.bestColorForHand(hand) end
    if UNM_Rules.requiresTarget(card, state) then
        local target, largest = nil, -1
        for _, name in ipairs(session.players) do
            if name ~= botName and isActive(state, name) and #(state.hands[name] or {}) > largest then
                target, largest = name, #(state.hands[name] or {})
            end
        end
        args.targetName = target
    end
    if #hand == 2 then
        state.unoCalled[botName] = true
        UNM.addEvent(session, botName .. " called UNO.", "uno")
    end
    return UNM.ACTION_PLAY_CARD, args
end

function Host:updateBots()
    for _, session in pairs(self.sessions) do
        if session.phase == UNM.PHASE_PLAYING then
            local state = UNM.currentState(session)
            local current = session.players[state.turnIndex or 1]
            if UNM.isBot(session, current) and isActive(state, current) then
                local now = self:now()
                if not session.botDueAt then
                    session.botDueAt = now + UNM.BOT_ACTION_DELAY_MS
                elseif now >= session.botDueAt then
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
    local anchor = UNM.anchorFromArgs(args)
    local name = self:playerName(playerObj, args)
    if not anchor then return self:message(playerObj, "No valid table.") end
    if not UNM.playerNearAnchor(playerObj, anchor, UNM.MAX_PLAY_DISTANCE) then
        return self:message(playerObj, "Move closer to the table.")
    end
    local session = self.sessions[anchor.key] or self:createSession(anchor, name)
    if session.phase == UNM.PHASE_PLAYING and not UNM.findName(session.players, name) then
        self:addSpectator(session, name)
    else
        self:addPlayer(session, name)
    end
    self:sendState(playerObj, session, name)
    self:broadcast(session)
end

function Host:handleWatch(playerObj, args)
    local anchor = UNM.anchorFromArgs(args)
    local name = self:playerName(playerObj, args)
    local session = anchor and self.sessions[anchor.key]
    if not session then return self:message(playerObj, "There is no active table to watch.") end
    if not UNM.playerNearAnchor(playerObj, session.anchor, UNM.MAX_PLAY_DISTANCE) then
        return self:message(playerObj, "Move closer to the table.")
    end
    self:addSpectator(session, name)
    self:sendState(playerObj, session, name)
    self:broadcast(session)
end

function Host:removeParticipant(session, name)
    if not session or not name then return false end
    local state = UNM.currentState(session)
    local index = UNM.findName(session.players, name)
    local spectatorIndex = UNM.findName(session.spectators, name)
    if not index and not spectatorIndex then return false end
    local currentName = session.players[state.turnIndex or 1]
    local wasCurrent = currentName == name
    UNM.removeName(session.players, name)
    UNM.removeName(session.spectators, name)
    if #session.players == 0 or not firstHumanPlayer(session) then
        self.sessions[session.key] = nil
        return true
    end
    if session.owner == name then session.owner = firstHumanPlayer(session) end
    if state.hands then state.hands[name] = nil end
    if state.eliminated then state.eliminated[name] = nil end
    if state.unoCalled then state.unoCalled[name] = nil end
    if state.unoVulnerable == name then state.unoVulnerable = nil end
    session.botDueAt = nil
    if session.phase == UNM.PHASE_PLAYING and index then
        if wasCurrent then
            if (state.direction or 1) < 0 then
                state.turnIndex = index - 1
                if state.turnIndex < 1 then state.turnIndex = #session.players end
            else
                state.turnIndex = index
                if state.turnIndex > #session.players then state.turnIndex = 1 end
            end
            state.pendingRoulette = nil
            clearTurnFlags(state)
        elseif currentName then
            state.turnIndex = UNM.findName(session.players, currentName) or 1
        end
        self:checkLastSurvivor(session, state)
    elseif (state.turnIndex or 1) > #session.players then
        state.turnIndex = 1
    end
    UNM.addEvent(session, name .. " left the table.", "leave")
    self:refreshPublic(session)
    return true
end

function Host:handleLeave(playerObj, args)
    local anchor = UNM.anchorFromArgs(args)
    local name = self:playerName(playerObj, args)
    local session = anchor and self.sessions[anchor.key]
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
            if not UNM.isBot(session, name) and not self.env.findPlayerByName(name) then
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
    if UNM.playerNearAnchor(playerObj, session and session.anchor, UNM.MAX_PLAY_DISTANCE) then
        return true
    end
    self:message(playerObj, "Move closer to the table.")
    return false
end

function Host:handleReset(playerObj, args)
    local anchor = UNM.anchorFromArgs(args)
    local name = self:playerName(playerObj, args)
    local old = anchor and self.sessions[anchor.key]
    if not old then return end
    if not self:validateTableDistance(playerObj, old) then return end
    if old.owner ~= name then return self:message(playerObj, "Only the table owner can reset.") end
    local session = self:createSession(anchor, name)
    session.players = UNM.copy(old.players)
    session.spectators = UNM.copy(old.spectators)
    session.bots = UNM.copy(old.bots)
    session.mercyEnabled = old.mercyEnabled ~= false
    session.sevenZeroEnabled = old.sevenZeroEnabled ~= false
    UNM.addEvent(session, name .. " reset the table.", "reset")
    self:refreshPublic(session)
    self:broadcast(session)
end

function Host:handleAction(playerObj, args)
    local anchor = UNM.anchorFromArgs(args)
    local name = self:playerName(playerObj, args)
    local session = anchor and self.sessions[anchor.key]
    if not session then return self:message(playerObj, "This table is not active.") end
    if not self:validateTableDistance(playerObj, session) then return end
    if not UNM.findName(session.players, name) then return self:message(playerObj, "Join the table before playing.") end
    local ok, reason = self:applyAction(session, name, tostring(args.action or ""), args)
    if not ok then
        self:message(playerObj, reason or "That action is not legal.")
        return self:sendState(playerObj, session, name)
    end
    self:broadcast(session)
end

function Host:handleCommand(playerObj, command, args)
    args = args or {}
    if command == UNM.CMD_START or command == UNM.CMD_JOIN then
        self:handleStart(playerObj, args)
    elseif command == UNM.CMD_WATCH then
        self:handleWatch(playerObj, args)
    elseif command == UNM.CMD_LEAVE then
        self:handleLeave(playerObj, args)
    elseif command == UNM.CMD_RESET then
        self:handleReset(playerObj, args)
    elseif command == UNM.CMD_ACTION then
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
