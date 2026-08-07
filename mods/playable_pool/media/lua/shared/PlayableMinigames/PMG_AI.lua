require "PlayableMinigames/PMG_Core"
require "PlayableMinigames/PMG_Random"
require "PlayableMinigames/PMG_Cards"
require "PlayableMinigames/PMG_Darts"
require "PlayableMinigames/PMG_BoardGames"

PMG_AI = PMG_AI or {}

local PIECE_VALUES = {
    P = 100,
    N = 320,
    B = 330,
    R = 500,
    Q = 900,
    K = 0,
    m = 100,
    M = 180,
}

local function pieceColor(piece)
    if not piece then
        return nil
    end
    return string.sub(tostring(piece), 1, 1) == "w" and "white" or "black"
end

local function pieceKind(piece)
    return piece and string.sub(tostring(piece), 2, 2) or nil
end

local function rngFor(session, botName, salt)
    local seed = tostring(session and session.seed or session and session.key or "pmg") ..
        ":" .. tostring(botName or "bot") ..
        ":" .. tostring(salt or "turn")
    return PMG_Random.new(PMG_Random.hash(seed))
end

local function chooseScored(scored, difficulty, rng)
    if #scored == 0 then
        return nil
    end
    local noise = tonumber(difficulty and difficulty.noise) or 1
    local best = nil
    for i = 1, #scored do
        local roll = (PMG_Random.next(rng) * 2 - 1) * noise
        scored[i].choiceScore = (tonumber(scored[i].score) or 0) + roll
        if not best or scored[i].choiceScore > best.choiceScore then
            best = scored[i]
        end
    end
    return best and best.value or nil
end

local function boardMaterial(board, color)
    local score = 0
    for row = 1, 8 do
        for col = 1, 8 do
            local piece = board and board[row] and board[row][col] or nil
            if piece then
                local value = PIECE_VALUES[pieceKind(piece)] or 0
                if pieceColor(piece) == color then
                    score = score + value
                else
                    score = score - value
                end
            end
        end
    end
    return score
end

function PMG_AI.chooseChessMove(session, state, botName, difficulty)
    local color = state and state.turn
    local moves = PMG_BoardGames.chessLegalMoves(state, color)
    local scored = {}
    for i = 1, #moves do
        local move = moves[i]
        local sim = PMG.copyTable(state)
        PMG_BoardGames.applyChessMove(sim, move)
        local score = boardMaterial(sim.board, color)
        local captured = state.board[move.toRow] and state.board[move.toRow][move.toCol] or nil
        if captured then
            score = score + (PIECE_VALUES[pieceKind(captured)] or 0) * 0.4
        end
        if sim.checkmate then
            score = score + 100000
        elseif sim.stalemate then
            score = score - 500
        elseif sim.check then
            score = score + 80
        end
        table.insert(scored, { value = move, score = score / 100 })
    end
    return chooseScored(scored, difficulty, rngFor(session, botName, "chess:" .. tostring(state and state.moveCount or 0)))
end

function PMG_AI.chooseCheckersMove(session, state, botName, difficulty)
    local color = state and state.turn
    local moves = PMG_BoardGames.checkersLegalMoves(state, color)
    local scored = {}
    for i = 1, #moves do
        local move = moves[i]
        local sim = PMG.copyTable(state)
        PMG_BoardGames.applyCheckersMove(sim, move)
        local score = boardMaterial(sim.board, color) / 100
        if move.captureRow then
            score = score + 3
        end
        if sim.forceFrom then
            score = score + 1.4
        end
        if sim.winnerColor == color then
            score = score + 1000
        end
        table.insert(scored, { value = move, score = score })
    end
    return chooseScored(scored, difficulty, rngFor(session, botName, "checkers:" .. tostring(state and state.moveCount or 0)))
end

local function dartTargetForScore(score, dartsLeft)
    score = tonumber(score) or 501
    local target = PMG_Darts.checkoutTarget(score, dartsLeft or 3)
    return PMG_Darts.targetPoint(target.base, target.ring)
end

function PMG_AI.chooseDartThrow(session, botName, difficulty)
    local scores = session and session.publicState and session.publicState.scores or {}
    local score = scores[botName] or PMG_Darts.START_SCORE
    local throws = session and session.publicState and session.publicState.turnThrows or {}
    local dartsLeft = math.max(1, PMG_Darts.THROWS_PER_TURN - #throws)
    local x, y = dartTargetForScore(score, dartsLeft)
    local rng = rngFor(session, botName, "darts:" .. tostring(session.publicState and session.publicState.throwNo or 0))
    local n = math.max(0, (tonumber(difficulty and difficulty.noise) or 1) * 0.012)
    x = PMG.clamp(x + (PMG_Random.next(rng) * 2 - 1) * n, -0.99, 0.99)
    y = PMG.clamp(y + (PMG_Random.next(rng) * 2 - 1) * n, -0.99, 0.99)
    local quality = PMG.clamp(0.70 + (1 - (tonumber(difficulty and difficulty.noise) or 1) / 4) * 0.25, 0.45, 0.95)
    return { x = x, y = y, releaseQuality = quality, releaseOffset = (PMG_Random.next(rng) * 2 - 1) * (1 - quality) }
end

function PMG_AI.chooseBlackjackAction(session, state, botName, difficulty)
    local hands = state and state.hands and state.hands[botName] or {}
    local hand = hands[state and state.activeHand or 1]
    if not hand then
        return nil
    end
    local total, soft = PMG_Cards.blackjackTotal(hand.cards or {})
    local dealerUp = state.dealerHand and state.dealerHand[1] or nil
    local dealerValue = math.min(PMG_Cards.blackjackCardValue(dealerUp), 10)
    local bankroll = state.bankrolls and state.bankrolls[botName] or 0
    local canDouble = #(hand.cards or {}) == 2 and bankroll >= (hand.bet or 0)
    local canSplit = #hands < 2 and #(hand.cards or {}) == 2
        and PMG_Cards.rank(hand.cards[1]) == PMG_Cards.rank(hand.cards[2])
        and bankroll >= (hand.bet or 0)

    if canSplit then
        local rank = PMG_Cards.rank(hand.cards[1])
        if rank == "A" or rank == "8" then
            return "split", {}
        end
    end
    if canDouble and (total == 11 or (total == 10 and dealerValue <= 9) or (soft and total == 18 and dealerValue >= 3 and dealerValue <= 6)) then
        return "double", {}
    end
    if soft then
        if total <= 17 or (total == 18 and dealerValue >= 9) then
            return "hit", {}
        end
        return "stand", {}
    end
    if total <= 11 then
        return "hit", {}
    end
    if total == 12 then
        return (dealerValue >= 4 and dealerValue <= 6) and "stand" or "hit", {}
    end
    if total >= 13 and total <= 16 then
        return dealerValue <= 6 and "stand" or "hit", {}
    end
    return "stand", {}
end

local function holeStrength(hole)
    local a = hole and hole[1]
    local b = hole and hole[2]
    if not a or not b then
        return 0
    end
    local av = PMG_Cards.rankValue(a)
    local bv = PMG_Cards.rankValue(b)
    local high = math.max(av, bv)
    local low = math.min(av, bv)
    local score = (high + low) / 28
    if PMG_Cards.rank(a) == PMG_Cards.rank(b) then
        score = score + 0.45 + high / 40
    end
    if PMG_Cards.suit(a) == PMG_Cards.suit(b) then
        score = score + 0.08
    end
    if math.abs(av - bv) == 1 then
        score = score + 0.06
    end
    return score
end

function PMG_AI.chooseHoldemAction(session, state, botName, difficulty)
    local bets = state.bets or {}
    local stacks = state.stacks or {}
    local owed = math.max(0, (state.toCall or 0) - (bets[botName] or 0))
    local stack = stacks[botName] or 0
    local strength = holeStrength(state.hole and state.hole[botName])
    if #(state.board or {}) >= 3 and state.hole and state.hole[botName] then
        local cards = PMG.copyTable(state.board)
        table.insert(cards, state.hole[botName][1])
        table.insert(cards, state.hole[botName][2])
        local eval = PMG_Cards.evaluateBest(cards)
        strength = math.max(strength, ((eval.category or 0) / 8) + (((eval.values or {})[1] or 0) / 80))
    end
    local rng = rngFor(session, botName, "holdem:" .. tostring(state.handNo or 0) .. ":" .. tostring(state.round or "") .. ":" .. tostring(state.actionPlayer or ""))
    strength = strength + (PMG_Random.next(rng) - 0.5) * ((difficulty and difficulty.noise or 1) * 0.08)
    local risk = tonumber(difficulty and difficulty.risk) or 0.4
    if owed <= 0 then
        if strength > (0.82 - risk * 0.18) and stack > 20 then
            local target = math.min((bets[botName] or 0) + stack, (state.toCall or 0) + (state.minRaise or 10))
            return "raise", { amount = target }
        end
        return "check", {}
    end
    if strength < 0.42 and owed > math.max(10, stack * (0.10 + risk * 0.05)) then
        return "fold", {}
    end
    if strength > (0.90 - risk * 0.15) and stack > owed + (state.minRaise or 10) then
        local target = math.min((bets[botName] or 0) + stack, (state.toCall or 0) + (state.minRaise or 10))
        return "raise", { amount = target }
    end
    if stack <= owed then
        return "all_in", {}
    end
    return "call", {}
end
