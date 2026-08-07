require "PlayableMinigames/PMG_Core"
require "PlayableMinigames/PMG_Registry"
require "PlayableMinigames/PMG_Cards"
require "PlayableMinigames/PMG_Anchors"
require "PlayableMinigames/PMG_AI"

local game = {
    id = "blackjack",
    name = "Blackjack",
    shortName = "Blackjack",
    icon = "game_blackjack.png",
    minPlayers = 1,
    maxPlayers = 4,
    supportsBots = true,
    botName = "Blackjack Bot",
    botThinkingDelay = { minMs = 875, maxMs = 1625 },
    requiredItem = "Base.CardDeck",
    requiredItemCount = 1,
    equipmentKind = "card_deck",
    anchorKind = "card_surface",
}

local function bj(session)
    session.privateState.blackjack = session.privateState.blackjack or {}
    return session.privateState.blackjack
end

local function ensurePlayer(session, name)
    local state = bj(session)
    state.bankrolls = state.bankrolls or {}
    state.bankrolls[name] = state.bankrolls[name] or 500
    session.publicState.bankrolls = session.publicState.bankrolls or {}
    session.publicState.bankrolls[name] = state.bankrolls[name]
end

local function playerBankroll(session, name)
    local state = bj(session)
    return tonumber(state.bankrolls and state.bankrolls[name]) or 0
end

local advanceToNextHand
local dealerAndSettle
local refreshPublic

function game.canStart(playerObj, anchor)
    local hasDeck = PMG_Anchors.hasCardDeckForAnchor(playerObj, anchor)
    if not hasDeck then
        return false, "Place a card deck on or next to the card table."
    end
    return true
end

function game.createInitialState(session)
    session.phase = PMG.PHASE_SETUP
    session.publicState.bankrolls = {}
    session.publicState.round = "betting"
    session.publicState.dealer = { visible = {}, total = 0 }
    session.publicState.hands = {}
    ensurePlayer(session, session.players[1])
end

function game.onPlayerJoined(session, name)
    ensurePlayer(session, name)
end

function game.onPlayerLeft(session, name)
    local state = bj(session)
    if state.bankrolls then
        state.bankrolls[name] = nil
    end
    if state.hands then
        state.hands[name] = nil
    end
    if state.activePlayer == name then
        if not advanceToNextHand(session) then
            dealerAndSettle(session)
        end
    else
        refreshPublic(session)
    end
end

local function publicHand(hand)
    local total = PMG_Cards.blackjackTotal(hand.cards)
    return {
        bet = hand.bet,
        status = hand.status,
        total = total,
        count = #(hand.cards or {}),
        natural = hand.natural == true,
    }
end

function refreshPublic(session)
    local state = bj(session)
    session.publicState.bankrolls = PMG.copyTable(state.bankrolls or {})
    session.publicState.hands = {}
    for name, hands in pairs(state.hands or {}) do
        session.publicState.hands[name] = {}
        for i = 1, #hands do
            session.publicState.hands[name][i] = publicHand(hands[i])
        end
    end
    session.publicState.dealer = {
        visible = state.dealerRevealed and PMG.copyTable(state.dealerHand or {}) or { (state.dealerHand or {})[1] },
        total = state.dealerRevealed and PMG_Cards.blackjackTotal(state.dealerHand or {}) or nil,
    }
    session.publicState.activePlayer = state.activePlayer
    session.publicState.activeHand = state.activeHand
    session.publicState.round = state.round or "betting"
end

local function activeHumanNames(session)
    local names = {}
    local state = bj(session)
    for i = 1, #(session.players or {}) do
        local name = session.players[i]
        if state.round == "playing" and state.hands and state.hands[name] then
            table.insert(names, name)
        elseif playerBankroll(session, name) > 0 then
            table.insert(names, name)
        end
    end
    return names
end

local function dealInitial(session, bet)
    local state = bj(session)
    local names = activeHumanNames(session)
    if #names == 0 then
        return false, "Need chips to deal blackjack."
    end
    state.deck = PMG_Cards.shuffle(session.key .. ":blackjack:" .. tostring((state.handNo or 0) + 1))
    state.handNo = (state.handNo or 0) + 1
    state.hands = {}
    state.dealerHand = {}
    state.dealerRevealed = false
    state.round = "playing"
    for i = 1, #names do
        ensurePlayer(session, names[i])
        local playerBet = math.min(math.max(1, tonumber(bet) or 10), state.bankrolls[names[i]] or 0)
        state.bankrolls[names[i]] = (state.bankrolls[names[i]] or 0) - playerBet
        local cards = { PMG_Cards.draw(state.deck), PMG_Cards.draw(state.deck) }
        state.hands[names[i]] = {
            { cards = cards, bet = playerBet, status = "playing", natural = PMG_Cards.isBlackjack(cards) },
        }
    end
    state.dealerHand = { PMG_Cards.draw(state.deck), PMG_Cards.draw(state.deck) }
    state.activePlayer = names[1]
    state.activeHand = 0
    PMG.setPhase(session, PMG.PHASE_PLAYING)
    PMG.addEvent(session, "Blackjack hand started.", "deal")
    for i = 1, #names do
        local hand = state.hands[names[i]] and state.hands[names[i]][1]
        if hand and hand.natural then
            hand.status = "blackjack"
        end
    end
    if PMG_Cards.isBlackjack(state.dealerHand) or not advanceToNextHand(session) then
        dealerAndSettle(session)
    else
        refreshPublic(session)
    end
    return true
end

local function handIsDone(hand)
    return not hand or hand.status ~= "playing"
end

local function isNaturalBlackjack(hand)
    return hand and hand.natural == true and PMG_Cards.isBlackjack(hand.cards)
end

function advanceToNextHand(session)
    local state = bj(session)
    local names = activeHumanNames(session)
    for p = 1, #names do
        local start = PMG.findNameIndex(names, state.activePlayer) or 1
        local index = ((start + p - 2) % #names) + 1
        local name = names[index]
        local hands = state.hands[name] or {}
        local firstHand = index == start and (state.activeHand or 1) + 1 or 1
        for h = firstHand, #hands do
            if not handIsDone(hands[h]) then
                state.activePlayer = name
                state.activeHand = h
                refreshPublic(session)
                return true
            end
        end
    end
    return false
end

local function settleHand(state, hand, dealerTotal, dealerBlackjack)
    local total = PMG_Cards.blackjackTotal(hand.cards)
    local playerBlackjack = isNaturalBlackjack(hand)
    local payout = 0
    if playerBlackjack and dealerBlackjack then
        payout = hand.bet
        hand.status = "push"
    elseif dealerBlackjack then
        hand.status = "lost"
    elseif playerBlackjack then
        payout = hand.bet * 2.5
        hand.status = "blackjack"
    elseif total > 21 then
        hand.status = "lost"
    elseif dealerTotal > 21 or total > dealerTotal then
        payout = hand.bet * 2
        hand.status = "won"
    elseif total == dealerTotal then
        payout = hand.bet
        hand.status = "push"
    else
        hand.status = "lost"
    end
    return math.floor(payout + 0.5)
end

function dealerAndSettle(session)
    local state = bj(session)
    state.dealerRevealed = true
    local total = PMG_Cards.blackjackTotal(state.dealerHand)
    while total < 17 do
        table.insert(state.dealerHand, PMG_Cards.draw(state.deck))
        total = PMG_Cards.blackjackTotal(state.dealerHand)
    end
    local dealerBlackjack = PMG_Cards.isBlackjack(state.dealerHand)
    for name, hands in pairs(state.hands or {}) do
        for h = 1, #hands do
            local payout = settleHand(state, hands[h], total, dealerBlackjack)
            state.bankrolls[name] = (state.bankrolls[name] or 0) + payout
        end
    end
    state.round = "settled"
    state.activePlayer = nil
    state.activeHand = nil
    PMG.setPhase(session, PMG.PHASE_ROUND_OVER)
    PMG.addEvent(session, "Dealer settled the blackjack hand.", "settle")
    refreshPublic(session)
end

local function getActiveHand(session, playerName)
    local state = bj(session)
    if state.activePlayer ~= playerName then
        return nil, "It is not your blackjack turn."
    end
    local hand = state.hands and state.hands[playerName] and state.hands[playerName][state.activeHand or 1]
    if not hand or hand.status ~= "playing" then
        return nil, "That blackjack hand is not active."
    end
    return hand
end

function game.legalActions(session, viewerName)
    local state = bj(session)
    local isPlayer = PMG.findNameIndex(session.players or {}, viewerName) ~= nil
    local actions = {}
    local round = state.round or "betting"
    local betting = round ~= "playing"
    local hasChips = playerBankroll(session, viewerName) > 0
    local dealReason = isPlayer and PMG.text("IGUI_PlayableMinigames_FinishHand", "Finish hand") or PMG.text("IGUI_PlayableMinigames_WatchOnly", "Watch only")
    if isPlayer and betting and not hasChips then
        dealReason = PMG.text("IGUI_PlayableMinigames_NeedChips", "Need chips")
    end
    table.insert(actions, PMG.legalAction("start_round", PMG.text("IGUI_PlayableMinigames_ActionDeal10", "Deal $10"), isPlayer and betting and hasChips, dealReason, { bet = 10 }))

    local hand = nil
    if isPlayer and state.activePlayer == viewerName then
        local hands = state.hands and state.hands[viewerName] or {}
        hand = hands[state.activeHand or 1]
    end
    local active = hand and hand.status == "playing"
    local turnReason = isPlayer and PMG.text("IGUI_PlayableMinigames_NotYourHand", "Not your hand") or PMG.text("IGUI_PlayableMinigames_WatchOnly", "Watch only")
    table.insert(actions, PMG.legalAction("hit", PMG.text("IGUI_PlayableMinigames_ActionHit", "Hit"), active, turnReason))
    table.insert(actions, PMG.legalAction("stand", PMG.text("IGUI_PlayableMinigames_ActionStand", "Stand"), active, turnReason))
    local canDouble = active and #(hand.cards or {}) == 2 and (state.bankrolls[viewerName] or 0) >= (hand.bet or 0)
    table.insert(actions, PMG.legalAction("double", PMG.text("IGUI_PlayableMinigames_ActionDouble", "Double"), canDouble, active and PMG.text("IGUI_PlayableMinigames_NeedChips", "Need chips") or turnReason))
    local hands = state.hands and state.hands[viewerName] or {}
    local canSplit = active
        and #hands < 2
        and #(hand.cards or {}) == 2
        and PMG_Cards.rank(hand.cards[1]) == PMG_Cards.rank(hand.cards[2])
        and (state.bankrolls[viewerName] or 0) >= (hand.bet or 0)
    table.insert(actions, PMG.legalAction("split", PMG.text("IGUI_PlayableMinigames_ActionSplit", "Split"), canSplit, active and PMG.text("IGUI_PlayableMinigames_NeedPairChips", "Need pair/chips") or turnReason))
    return actions
end

function game.botPlayerToAct(session)
    local state = bj(session)
    if state.round == "playing" then
        return state.activePlayer
    end
    return nil
end

function game.botTurnKey(session, botName)
    local state = bj(session)
    local hand = state.hands and state.hands[botName] and state.hands[botName][state.activeHand or 1] or {}
    return table.concat({
        "blackjack",
        tostring(state.round or ""),
        tostring(state.handNo or 0),
        tostring(state.activePlayer or ""),
        tostring(state.activeHand or ""),
        tostring(#(hand.cards or {})),
        tostring(hand.status or ""),
    }, ":")
end

function game.botAction(session, botName, difficulty)
    return PMG_AI.chooseBlackjackAction(session, bj(session), botName, difficulty)
end

function game.rewardForAction(session, playerName, action)
    if action == "start_round" then
        return nil
    end
    local xp = 1
    local state = bj(session)
    local hands = state.hands and state.hands[playerName] or {}
    for i = 1, #hands do
        if hands[i].status == "won" or hands[i].status == "blackjack" then
            xp = xp + 4
        end
    end
    return { skillId = "Cards", xp = xp, sessionCap = 220 }
end

function game.applyAction(session, playerName, action, args)
    local state = bj(session)
    ensurePlayer(session, playerName)
    if action == "start_round" then
        if state.round == "playing" then
            return false, "Finish the current hand first."
        end
        return dealInitial(session, args.bet)
    end
    local hand, reason = getActiveHand(session, playerName)
    if not hand then
        return false, reason
    end
    if action == "hit" then
        table.insert(hand.cards, PMG_Cards.draw(state.deck))
        local total = PMG_Cards.blackjackTotal(hand.cards)
        if total > 21 then
            hand.status = "bust"
            PMG.addEvent(session, playerName .. " busted.", "bust")
            if not advanceToNextHand(session) then
                dealerAndSettle(session)
            end
        else
            refreshPublic(session)
        end
        return true
    elseif action == "stand" then
        hand.status = "stand"
        if not advanceToNextHand(session) then
            dealerAndSettle(session)
        end
        return true
    elseif action == "double" then
        local bankroll = state.bankrolls[playerName] or 0
        if #hand.cards ~= 2 or bankroll < hand.bet then
            return false, "You can only double with two cards and enough chips."
        end
        state.bankrolls[playerName] = bankroll - hand.bet
        hand.bet = hand.bet * 2
        table.insert(hand.cards, PMG_Cards.draw(state.deck))
        local total = PMG_Cards.blackjackTotal(hand.cards)
        hand.status = total > 21 and "bust" or "stand"
        if not advanceToNextHand(session) then
            dealerAndSettle(session)
        end
        return true
    elseif action == "split" then
        if #(state.hands[playerName] or {}) >= 2 then
            return false, "Split is allowed once per hand."
        end
        if #hand.cards ~= 2 or PMG_Cards.rank(hand.cards[1]) ~= PMG_Cards.rank(hand.cards[2]) then
            return false, "Only matching two-card hands can split."
        end
        if (state.bankrolls[playerName] or 0) < hand.bet then
            return false, "You need enough chips to match the split bet."
        end
        state.bankrolls[playerName] = state.bankrolls[playerName] - hand.bet
        local splitRank = PMG_Cards.rank(hand.cards[1])
        local card = table.remove(hand.cards)
        hand.natural = false
        table.insert(hand.cards, PMG_Cards.draw(state.deck))
        local hands = state.hands[playerName]
        local splitHand = { cards = { card, PMG_Cards.draw(state.deck) }, bet = hand.bet, status = "playing", natural = false }
        if splitRank == "A" then
            hand.status = "stand"
            splitHand.status = "stand"
        end
        table.insert(hands, state.activeHand + 1, splitHand)
        if splitRank == "A" and not advanceToNextHand(session) then
            dealerAndSettle(session)
        else
            refreshPublic(session)
        end
        return true
    end
    return false, "Unknown blackjack action."
end

function game.redactState(session, payload, viewerName)
    local state = bj(session)
    payload.privateState = payload.privateState or {}
    if viewerName and state.hands and state.hands[viewerName] then
        payload.privateState.blackjackHands = PMG.copyTable(state.hands[viewerName])
    end
    if state.dealerRevealed then
        payload.privateState.dealerHand = PMG.copyTable(state.dealerHand or {})
    end
end

PMG_Registry.register(game)
