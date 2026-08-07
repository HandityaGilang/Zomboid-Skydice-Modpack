require "PlayableMinigames/PMG_Core"
require "PlayableMinigames/PMG_Registry"
require "PlayableMinigames/PMG_Cards"
require "PlayableMinigames/PMG_Anchors"
require "PlayableMinigames/PMG_AI"

local game = {
    id = "holdem",
    name = "Texas Hold'em",
    shortName = "Hold'em",
    icon = "game_holdem.png",
    minPlayers = 2,
    maxPlayers = 6,
    supportsBots = true,
    botName = "Poker Bot",
    botThinkingDelay = { minMs = 4500, maxMs = 8000 },
    requiredItem = "Base.CardDeck",
    requiredItemCount = 1,
    equipmentKind = "card_deck",
    anchorKind = "card_surface",
}

local ROUNDS = { "preflop", "flop", "turn", "river" }
local FLOW_STEP_PAUSE = {
    message = 650,
    blind = 820,
    hole_card = 290,
    burn = 430,
    board_card = 680,
    action = 980,
    chips = 740,
    fold = 980,
    check = 780,
    showdown_reveal = 1150,
    award = 1300,
    turn = 850,
}
local advanceAction
local refreshPublic

local function holdem(session)
    session.privateState.holdem = session.privateState.holdem or {}
    return session.privateState.holdem
end

local function beginFlow(state, reason)
    state.flowSeq = (state.flowSeq or 0) + 1
    state.flow = {
        id = state.flowSeq,
        reason = tostring(reason or "action"),
        durationMs = 0,
        blockActions = true,
        steps = {},
        cursorMs = 0,
    }
    return state.flow
end

local function ensureFlow(state, reason)
    return state.flow or beginFlow(state, reason)
end

local function publicFlow(flow)
    if not flow or not flow.id or not flow.steps or #flow.steps == 0 then
        return nil
    end
    local result = {
        id = flow.id,
        reason = flow.reason,
        durationMs = flow.durationMs or 0,
        blockActions = flow.blockActions ~= false,
        steps = {},
    }
    for i = 1, #flow.steps do
        result.steps[i] = PMG.copyTable(flow.steps[i])
    end
    return result
end

local function addFlowStep(state, atMs, kind, text, metadata)
    local flow = ensureFlow(state, kind)
    local step = {
        atMs = math.max(0, math.floor(tonumber(atMs) or 0)),
        kind = tostring(kind or "message"),
        text = tostring(text or ""),
    }
    if type(metadata) == "table" then
        for key, value in pairs(metadata) do
            if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
                step[key] = value
            end
        end
    end
    table.insert(flow.steps, step)
    flow.durationMs = math.max(flow.durationMs or 0, step.atMs + (FLOW_STEP_PAUSE[step.kind] or 500))
    return step
end

local function appendFlowStep(state, gapMs, kind, text, metadata)
    local flow = ensureFlow(state, kind)
    flow.cursorMs = math.max(flow.cursorMs or 0, 0) + math.max(0, tonumber(gapMs) or 0)
    local step = addFlowStep(state, flow.cursorMs, kind, text, metadata)
    flow.cursorMs = flow.cursorMs + (FLOW_STEP_PAUSE[step.kind] or 500)
    flow.durationMs = math.max(flow.durationMs or 0, flow.cursorMs)
    return step
end

local function appendNextToActFlow(state)
    if state.actionPlayer then
        appendFlowStep(state, 260, "turn", "Action moves to " .. tostring(state.actionPlayer) .. ".", { player = state.actionPlayer })
    end
end

local function ensurePlayer(session, name)
    local state = holdem(session)
    state.stacks = state.stacks or {}
    state.stacks[name] = state.stacks[name] or 1000
    session.publicState.stacks = session.publicState.stacks or {}
    session.publicState.stacks[name] = state.stacks[name]
end

local function countPlayersWithChips(session)
    local state = holdem(session)
    local count = 0
    for i = 1, #(session.players or {}) do
        local name = session.players[i]
        if name and (state.stacks[name] or 0) > 0 then
            count = count + 1
        end
    end
    return count
end

function game.canStart(playerObj, anchor)
    local hasDeck = PMG_Anchors.hasCardDeckForAnchor(playerObj, anchor)
    if not hasDeck then
        return false, "Place a card deck on or next to the card table."
    end
    return true
end

function game.createInitialState(session)
    session.phase = PMG.PHASE_WAITING
    session.publicState.round = "waiting"
    session.publicState.board = {}
    session.publicState.pot = 0
    session.publicState.toCall = 0
    session.publicState.stacks = {}
    ensurePlayer(session, session.players[1])
end

function game.onPlayerJoined(session, name)
    ensurePlayer(session, name)
    if #(session.players or {}) >= 2 and session.phase == PMG.PHASE_WAITING then
        PMG.setPhase(session, PMG.PHASE_SETUP)
    end
end

function game.onPlayerLeft(session, name)
    local state = holdem(session)
    if state.stacks then
        state.stacks[name] = nil
    end
    if state.hole then
        state.hole[name] = nil
    end
    if state.bets then
        state.bets[name] = nil
    end
    if state.contributions then
        state.contributions[name] = nil
    end
    if state.folded then
        state.folded[name] = true
    end
    if state.actionPlayer == name and session.phase == PMG.PHASE_PLAYING then
        advanceAction(session)
    else
        refreshPublic(session)
    end
end

local function nextSeat(session, fromSeat, includeFolded)
    local state = holdem(session)
    local count = #(session.players or {})
    for step = 1, count do
        local seat = ((fromSeat + step - 1) % count) + 1
        local name = session.players[seat]
        if name and (includeFolded or not state.folded[name]) and (state.stacks[name] or 0) > 0 then
            return seat, name
        end
    end
    return nil, nil
end

local function activePlayers(session)
    local state = holdem(session)
    local result = {}
    for i = 1, #(session.players or {}) do
        local name = session.players[i]
        if not state.folded[name] then
            table.insert(result, name)
        end
    end
    return result
end

local function actionablePlayerCount(session)
    local state = holdem(session)
    local count = 0
    local active = activePlayers(session)
    for i = 1, #active do
        local name = active[i]
        if not state.allIn[name] then
            count = count + 1
        end
    end
    return count
end

local function oddChipOrder(session, winners)
    local count = #(session.players or {})
    local seats = {}
    for i = 1, count do
        seats[session.players[i]] = i
    end
    table.sort(winners, function(a, b)
        local seatA = seats[a] or 999
        local seatB = seats[b] or 999
        local dealer = (holdem(session).dealerSeat or 1)
        local distanceA = ((seatA - dealer - 1) % math.max(1, count)) + 1
        local distanceB = ((seatB - dealer - 1) % math.max(1, count)) + 1
        if distanceA == distanceB then
            return tostring(a) < tostring(b)
        end
        return distanceA < distanceB
    end)
    return winners
end

function refreshPublic(session)
    local state = holdem(session)
    session.publicState.stacks = PMG.copyTable(state.stacks or {})
    session.publicState.bets = PMG.copyTable(state.bets or {})
    session.publicState.contributions = PMG.copyTable(state.contributions or {})
    session.publicState.folded = PMG.copyTable(state.folded or {})
    session.publicState.allIn = PMG.copyTable(state.allIn or {})
    session.publicState.board = PMG.copyTable(state.board or {})
    session.publicState.pot = state.pot or 0
    session.publicState.round = state.round or "waiting"
    session.publicState.toCall = state.toCall or 0
    session.publicState.minRaise = state.minRaise or 10
    session.publicState.dealerSeat = state.dealerSeat or 1
    session.publicState.actionSeat = state.actionSeat
    session.publicState.actionPlayer = state.actionPlayer
    session.publicState.lastRaise = state.lastRaise or 10
    session.publicState.showdown = PMG.copyTable(state.showdown or nil)
    session.publicState.flow = publicFlow(state.flow)
end

local function postBlind(state, name, amount)
    if not name then
        return
    end
    amount = math.min(amount, state.stacks[name] or 0)
    state.stacks[name] = (state.stacks[name] or 0) - amount
    state.bets[name] = (state.bets[name] or 0) + amount
    state.contributions[name] = (state.contributions[name] or 0) + amount
    state.pot = (state.pot or 0) + amount
    if state.stacks[name] <= 0 then
        state.allIn[name] = true
    end
end

local function beginHand(session)
    local state = holdem(session)
    for i = 1, #(session.players or {}) do
        ensurePlayer(session, session.players[i])
    end
    local activeChipPlayers = countPlayersWithChips(session)
    if activeChipPlayers < 2 then
        return false, "Poker needs at least two players with chips."
    end
    state.handNo = (state.handNo or 0) + 1
    state.deck = PMG_Cards.shuffle(session.key .. ":holdem:" .. tostring(state.handNo))
    state.board = {}
    state.hole = {}
    state.bets = {}
    state.contributions = {}
    state.folded = {}
    state.allIn = {}
    state.acted = {}
    state.showdown = nil
    state.burn = {}
    state.pot = 0
    state.round = "preflop"
    state.toCall = 0
    state.minRaise = 10
    state.lastRaise = 10
    state.dealerSeat = ((state.dealerSeat or 0) % #session.players) + 1
    local dealerName = session.players[state.dealerSeat]
    if not dealerName or (state.stacks[dealerName] or 0) <= 0 then
        state.dealerSeat = nextSeat(session, state.dealerSeat, true) or state.dealerSeat
    end
    for i = 1, #session.players do
        local name = session.players[i]
        if (state.stacks[name] or 0) > 0 then
            state.hole[name] = { PMG_Cards.draw(state.deck), PMG_Cards.draw(state.deck) }
        else
            state.folded[name] = true
        end
    end
    local sbSeat, sbName = nil, nil
    local bbSeat, bbName = nil, nil
    if activeChipPlayers == 2 then
        sbSeat = state.dealerSeat
        sbName = session.players[sbSeat]
        bbSeat, bbName = nextSeat(session, sbSeat, true)
    else
        sbSeat, sbName = nextSeat(session, state.dealerSeat, true)
        bbSeat, bbName = nextSeat(session, sbSeat, true)
    end
    postBlind(state, sbName, 5)
    postBlind(state, bbName, 10)
    state.toCall = math.max(state.bets[sbName] or 0, state.bets[bbName] or 0)
    state.actionSeat, state.actionPlayer = nextSeat(session, bbSeat, false)
    beginFlow(state, "start_hand")
    appendFlowStep(state, 0, "message", "Starting hand #" .. tostring(state.handNo) .. ".")
    appendFlowStep(state, 120, "blind", tostring(sbName) .. " posts the small blind.", { player = sbName, amount = 5 })
    appendFlowStep(state, 80, "blind", tostring(bbName) .. " posts the big blind.", { player = bbName, amount = 10 })
    for cardIndex = 1, 2 do
        for seat = 1, #session.players do
            local name = session.players[seat]
            if state.hole[name] then
                appendFlowStep(state, 20, "hole_card", "Dealing to " .. tostring(name) .. ".", {
                    player = name,
                    seat = seat,
                    cardIndex = cardIndex,
                })
            end
        end
    end
    appendNextToActFlow(state)
    PMG.setPhase(session, PMG.PHASE_PLAYING)
    PMG.addEvent(session, "Poker hand started. Blinds are 5/10.", "deal")
    refreshPublic(session)
    return true
end

local function burnCard(state)
    state.burn = state.burn or {}
    table.insert(state.burn, PMG_Cards.draw(state.deck))
end

local function everyoneSettled(session)
    local state = holdem(session)
    state.acted = state.acted or {}
    local active = activePlayers(session)
    local canAct = 0
    for i = 1, #active do
        local name = active[i]
        if not state.allIn[name] then
            canAct = canAct + 1
            if (state.bets[name] or 0) < (state.toCall or 0) then
                return false
            end
            if not state.acted[name] then
                return false
            end
        end
    end
    return true
end

local function awardSingleWinner(session, winner)
    local state = holdem(session)
    ensureFlow(state, "award")
    appendFlowStep(state, 140, "award", tostring(winner) .. " collects the pot.", { player = winner, amount = state.pot or 0 })
    state.stacks[winner] = (state.stacks[winner] or 0) + (state.pot or 0)
    state.showdown = { winners = { winner }, reason = "All other players folded." }
    state.round = "settled"
    PMG.setPhase(session, PMG.PHASE_ROUND_OVER)
    PMG.addEvent(session, winner .. " won the pot.", "win")
    refreshPublic(session)
end

local function settleShowdown(session)
    local state = holdem(session)
    local contenders = activePlayers(session)
    ensureFlow(state, "showdown")
    appendFlowStep(state, 220, "message", "Showdown.")
    local evaluations = {}
    for i = 1, #contenders do
        local name = contenders[i]
        local cards = PMG.copyTable(state.board or {})
        table.insert(cards, state.hole[name][1])
        table.insert(cards, state.hole[name][2])
        evaluations[name] = PMG_Cards.evaluateBest(cards)
        appendFlowStep(state, 120, "showdown_reveal", tostring(name) .. " shows " .. tostring(evaluations[name].name) .. ".", {
            player = name,
        })
    end

    local levels = {}
    local seen = {}
    for _, amount in pairs(state.contributions or {}) do
        amount = tonumber(amount) or 0
        if amount > 0 and not seen[amount] then
            seen[amount] = true
            table.insert(levels, amount)
        end
    end
    table.sort(levels)

    local allWinners = {}
    local previous = 0
    for l = 1, #levels do
        local level = levels[l]
        local participants = {}
        local eligible = {}
        for i = 1, #(session.players or {}) do
            local name = session.players[i]
            if (state.contributions[name] or 0) >= level then
                table.insert(participants, name)
                if not state.folded[name] then
                    table.insert(eligible, name)
                end
            end
        end
        local pot = (level - previous) * #participants
        previous = level
        local bestScore = nil
        local winners = {}
        for i = 1, #eligible do
            local name = eligible[i]
            local score = evaluations[name] and evaluations[name].score or 0
            if not bestScore or score > bestScore then
                bestScore = score
                winners = { name }
            elseif score == bestScore then
                table.insert(winners, name)
            end
        end
        if pot > 0 and #winners > 0 then
            winners = oddChipOrder(session, winners)
            local share = math.floor(pot / #winners)
            local remainder = pot - (share * #winners)
            for i = 1, #winners do
                local extra = i <= remainder and 1 or 0
                state.stacks[winners[i]] = (state.stacks[winners[i]] or 0) + share + extra
                allWinners[winners[i]] = true
            end
        end
    end

    local winnerList = {}
    for name, _ in pairs(allWinners) do
        table.insert(winnerList, name)
    end
    table.sort(winnerList)
    appendFlowStep(state, 160, "award", table.concat(winnerList, ", ") .. " wins the showdown.", { amount = state.pot or 0 })
    state.showdown = { winners = winnerList, evaluations = evaluations, pot = state.pot, sidePots = true }
    state.round = "settled"
    PMG.setPhase(session, PMG.PHASE_ROUND_OVER)
    PMG.addEvent(session, table.concat(winnerList, ", ") .. " won showdown.", "win")
    refreshPublic(session)
end

local function nextRound(session)
    local state = holdem(session)
    state.bets = {}
    state.toCall = 0
    state.acted = {}
    ensureFlow(state, "round")
    local index = 1
    for i = 1, #ROUNDS do
        if ROUNDS[i] == state.round then
            index = i
            break
        end
    end
    if state.round == "preflop" then
        appendFlowStep(state, 260, "message", "Dealing the flop.")
        burnCard(state)
        appendFlowStep(state, 80, "burn", "Burn card.")
        table.insert(state.board, PMG_Cards.draw(state.deck))
        appendFlowStep(state, 40, "board_card", "Flop card 1.", { boardIndex = #state.board })
        table.insert(state.board, PMG_Cards.draw(state.deck))
        appendFlowStep(state, 40, "board_card", "Flop card 2.", { boardIndex = #state.board })
        table.insert(state.board, PMG_Cards.draw(state.deck))
        appendFlowStep(state, 40, "board_card", "Flop card 3.", { boardIndex = #state.board })
        state.round = "flop"
    elseif state.round == "flop" then
        appendFlowStep(state, 280, "message", "Dealing the turn.")
        burnCard(state)
        appendFlowStep(state, 80, "burn", "Burn card.")
        table.insert(state.board, PMG_Cards.draw(state.deck))
        appendFlowStep(state, 60, "board_card", "Turn card.", { boardIndex = #state.board })
        state.round = "turn"
    elseif state.round == "turn" then
        appendFlowStep(state, 280, "message", "Dealing the river.")
        burnCard(state)
        appendFlowStep(state, 80, "burn", "Burn card.")
        table.insert(state.board, PMG_Cards.draw(state.deck))
        appendFlowStep(state, 60, "board_card", "River card.", { boardIndex = #state.board })
        state.round = "river"
    else
        settleShowdown(session)
        return
    end
    state.actionSeat, state.actionPlayer = nextSeat(session, state.dealerSeat, false)
    appendNextToActFlow(state)
    refreshPublic(session)
end

local function runOutBoardAndShowdown(session)
    while session.phase == PMG.PHASE_PLAYING do
        nextRound(session)
        local state = holdem(session)
        if state.round == "settled" then
            return
        end
        state.acted = {}
        if #activePlayers(session) <= 1 then
            advanceAction(session)
            return
        end
    end
end

function advanceAction(session)
    local state = holdem(session)
    local active = activePlayers(session)
    if #active == 1 then
        awardSingleWinner(session, active[1])
        return
    end
    if everyoneSettled(session) then
        if actionablePlayerCount(session) <= 1 then
            runOutBoardAndShowdown(session)
            return
        end
        nextRound(session)
        return
    end
    local seat, name = nextSeat(session, state.actionSeat or 1, false)
    state.actionSeat = seat
    state.actionPlayer = name
    appendNextToActFlow(state)
    refreshPublic(session)
end

local function putChips(state, name, amount)
    amount = math.max(0, math.min(tonumber(amount) or 0, state.stacks[name] or 0))
    state.stacks[name] = (state.stacks[name] or 0) - amount
    state.bets[name] = (state.bets[name] or 0) + amount
    state.contributions[name] = (state.contributions[name] or 0) + amount
    state.pot = (state.pot or 0) + amount
    if state.stacks[name] <= 0 then
        state.allIn[name] = true
    end
    return amount
end

function game.applyAction(session, playerName, action, args)
    local state = holdem(session)
    ensurePlayer(session, playerName)
    if action == "start_hand" then
        return beginHand(session)
    end
    if state.round == "waiting" or state.round == "settled" or session.phase ~= PMG.PHASE_PLAYING then
        return false, "Start a poker hand first."
    end
    if state.actionPlayer ~= playerName then
        return false, "It is not your poker action."
    end
    state.acted = state.acted or {}
    if action == "fold" then
        beginFlow(state, "action")
        appendFlowStep(state, 0, "fold", tostring(playerName) .. " folds.", { player = playerName })
        state.folded[playerName] = true
        state.acted[playerName] = true
        PMG.addEvent(session, playerName .. " folded.", "fold")
        advanceAction(session)
        return true
    end
    local owed = math.max(0, (state.toCall or 0) - (state.bets[playerName] or 0))
    if action == "check" then
        if owed > 0 then
            return false, "You must call or fold."
        end
        beginFlow(state, "action")
        appendFlowStep(state, 0, "check", tostring(playerName) .. " checks.", { player = playerName })
        state.acted[playerName] = true
        PMG.addEvent(session, playerName .. " checked.", "check")
        advanceAction(session)
        return true
    elseif action == "call" then
        beginFlow(state, "action")
        putChips(state, playerName, owed)
        appendFlowStep(state, 0, "action", tostring(playerName) .. " calls.", { player = playerName, action = "call", amount = owed })
        appendFlowStep(state, 80, "chips", tostring(playerName) .. " moves " .. tostring(owed) .. " chips in.", { player = playerName, amount = owed })
        state.acted[playerName] = true
        PMG.addEvent(session, playerName .. " called.", "call")
        advanceAction(session)
        return true
    elseif action == "bet" or action == "raise" then
        local target = math.floor(tonumber(args.amount) or 0)
        local maxTarget = (state.bets[playerName] or 0) + (state.stacks[playerName] or 0)
        if target > maxTarget then
            return false, "Raise target exceeds your stack."
        end
        if target <= (state.toCall or 0) then
            return false, "Raise must exceed the current call."
        end
        local raiseBy = target - (state.toCall or 0)
        if raiseBy < (state.minRaise or 10) then
            return false, "Raise is below the minimum."
        end
        beginFlow(state, "action")
        local add = target - (state.bets[playerName] or 0)
        putChips(state, playerName, add)
        state.toCall = math.max(state.toCall or 0, state.bets[playerName] or 0)
        state.lastRaise = raiseBy
        state.minRaise = raiseBy
        state.acted = { [playerName] = true }
        appendFlowStep(state, 0, "action", tostring(playerName) .. " raises to " .. tostring(state.toCall) .. ".", { player = playerName, action = "raise", amount = state.toCall })
        appendFlowStep(state, 80, "chips", tostring(playerName) .. " pushes chips forward.", { player = playerName, amount = add })
        PMG.addEvent(session, playerName .. " raised to " .. tostring(state.toCall) .. ".", "raise")
        advanceAction(session)
        return true
    elseif action == "all_in" then
        beginFlow(state, "action")
        local previousToCall = state.toCall or 0
        local target = (state.bets[playerName] or 0) + (state.stacks[playerName] or 0)
        local add = state.stacks[playerName] or 0
        putChips(state, playerName, state.stacks[playerName] or 0)
        target = state.bets[playerName] or target
        if target > previousToCall then
            local raiseBy = target - previousToCall
            state.toCall = target
            if raiseBy >= (state.minRaise or 10) then
                state.lastRaise = raiseBy
                state.minRaise = raiseBy
                state.acted = { [playerName] = true }
            else
                state.acted[playerName] = true
            end
        else
            state.acted[playerName] = true
        end
        appendFlowStep(state, 0, "action", tostring(playerName) .. " moves all in.", { player = playerName, action = "all_in", amount = target })
        appendFlowStep(state, 80, "chips", tostring(playerName) .. " pushes " .. tostring(add) .. " chips in.", { player = playerName, amount = add })
        PMG.addEvent(session, playerName .. " moved all in.", "raise")
        advanceAction(session)
        return true
    end
    return false, "Unknown poker action."
end

function game.legalActions(session, viewerName)
    local state = holdem(session)
    local isPlayer = PMG.findNameIndex(session.players or {}, viewerName) ~= nil
    local actions = {}
    local enoughPlayers = #(session.players or {}) >= 2
    local enoughChips = countPlayersWithChips(session) >= 2
    local canStart = isPlayer and enoughPlayers and enoughChips and ((state.round or "waiting") == "waiting" or (state.round or "") == "settled" or session.phase ~= PMG.PHASE_PLAYING)
    local startReason = PMG.text("IGUI_PlayableMinigames_NeedTwoPlayers", "Need 2 players")
    if enoughPlayers and not enoughChips then
        startReason = PMG.text("IGUI_PlayableMinigames_NeedTwoPlayersWithChips", "Need 2 players with chips")
    elseif not isPlayer then
        startReason = PMG.text("IGUI_PlayableMinigames_WatchOnly", "Watch only")
    end
    table.insert(actions, PMG.legalAction("start_hand", PMG.text("IGUI_PlayableMinigames_ActionStartHand", "Start Hand"), canStart, startReason))

    local folded = state.folded or {}
    local allIn = state.allIn or {}
    local bets = state.bets or {}
    local stacks = state.stacks or {}
    local acting = isPlayer and state.actionPlayer == viewerName and session.phase == PMG.PHASE_PLAYING and not folded[viewerName] and not allIn[viewerName]
    local owed = math.max(0, (state.toCall or 0) - (bets[viewerName] or 0))
    local stack = stacks[viewerName] or 0
    local callAmount = math.min(owed, stack)
    local reason = isPlayer and PMG.text("IGUI_PlayableMinigames_NotYourAction", "Not your action") or PMG.text("IGUI_PlayableMinigames_WatchOnly", "Watch only")
    table.insert(actions, PMG.legalAction("check", PMG.text("IGUI_PlayableMinigames_ActionCheck", "Check"), acting and owed <= 0, owed > 0 and PMG.text("IGUI_PlayableMinigames_MustCall", "Must call") or reason))
    table.insert(actions, PMG.legalAction("call", PMG.text("IGUI_PlayableMinigames_ActionCall", "Call"), acting and owed > 0 and stack > 0, owed <= 0 and PMG.text("IGUI_PlayableMinigames_NothingToCall", "Nothing to call") or reason, nil, { amount = callAmount, owed = owed }))
    table.insert(actions, PMG.legalAction("fold", PMG.text("IGUI_PlayableMinigames_ActionFold", "Fold"), acting, reason))
    local minTarget = (state.toCall or 0) + (state.minRaise or 10)
    local maxTarget = (bets[viewerName] or 0) + stack
    table.insert(actions, PMG.legalAction("raise", PMG.text("IGUI_PlayableMinigames_ActionRaise", "Raise"), acting and maxTarget >= minTarget, acting and PMG.text("IGUI_PlayableMinigames_NeedChips", "Need chips") or reason, { amount = minTarget }, { min = minTarget, max = maxTarget, step = state.minRaise or 10 }))
    table.insert(actions, PMG.legalAction("all_in", PMG.text("IGUI_PlayableMinigames_ActionAllIn", "All In"), acting and stack > 0, reason))
    return actions
end

function game.botPlayerToAct(session)
    local state = holdem(session)
    if session.phase == PMG.PHASE_PLAYING then
        return state.actionPlayer
    end
    return nil
end

function game.botTurnKey(session, botName)
    local state = holdem(session)
    local bets = state.bets or {}
    local stacks = state.stacks or {}
    return table.concat({
        "holdem",
        tostring(state.handNo or 0),
        tostring(state.round or ""),
        tostring(state.actionPlayer or ""),
        tostring(state.actionSeat or ""),
        tostring(state.toCall or 0),
        tostring(state.minRaise or 0),
        tostring(bets[botName] or 0),
        tostring(stacks[botName] or 0),
        tostring(#(state.board or {})),
    }, ":")
end

function game.botAction(session, botName, difficulty)
    return PMG_AI.chooseHoldemAction(session, holdem(session), botName, difficulty)
end

function game.presentationDelayMs(session)
    local flow = holdem(session).flow
    if flow and flow.blockActions ~= false then
        return math.max(0, tonumber(flow.durationMs) or 0)
    end
    return 0
end

function game.rewardForAction(session, playerName, action)
    if action == "start_hand" then
        return nil
    end
    local xp = 1
    local state = holdem(session)
    local winners = state.showdown and state.showdown.winners or {}
    if PMG.findNameIndex(winners, playerName) then
        xp = xp + 8
    end
    return { skillId = "Cards", xp = xp, sessionCap = 220 }
end

function game.redactState(session, payload, viewerName)
    local state = holdem(session)
    payload.privateState = payload.privateState or {}
    if viewerName and state.hole and state.hole[viewerName] then
        payload.privateState.hole = PMG.copyTable(state.hole[viewerName])
    end
    if state.showdown then
        payload.privateState.revealedHole = PMG.copyTable(state.hole or {})
    end
end

PMG_Registry.register(game)
