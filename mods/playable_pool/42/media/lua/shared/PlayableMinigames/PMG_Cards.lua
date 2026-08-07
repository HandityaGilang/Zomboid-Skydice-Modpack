require "PlayableMinigames/PMG_Core"
require "PlayableMinigames/PMG_Random"

PMG_Cards = PMG_Cards or {}

PMG_Cards.SUITS = { "S", "H", "D", "C" }
PMG_Cards.RANKS = { "A", "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K" }
PMG_Cards.RANK_VALUE = {
    ["2"] = 2, ["3"] = 3, ["4"] = 4, ["5"] = 5, ["6"] = 6, ["7"] = 7,
    ["8"] = 8, ["9"] = 9, T = 10, J = 11, Q = 12, K = 13, A = 14,
}

function PMG_Cards.card(rank, suit)
    return tostring(rank) .. tostring(suit)
end

function PMG_Cards.rank(card)
    return string.sub(tostring(card or ""), 1, 1)
end

function PMG_Cards.suit(card)
    return string.sub(tostring(card or ""), 2, 2)
end

function PMG_Cards.rankValue(card)
    return PMG_Cards.RANK_VALUE[PMG_Cards.rank(card)] or 0
end

function PMG_Cards.sequenceValue(card)
    local rank = PMG_Cards.rank(card)
    if rank == "A" then
        return 1
    end
    return PMG_Cards.RANK_VALUE[rank] or 0
end

function PMG_Cards.color(card)
    local suit = PMG_Cards.suit(card)
    if suit == "H" or suit == "D" then
        return "red"
    end
    return "black"
end

function PMG_Cards.standardDeck()
    local deck = {}
    for s = 1, #PMG_Cards.SUITS do
        for r = 1, #PMG_Cards.RANKS do
            table.insert(deck, PMG_Cards.card(PMG_Cards.RANKS[r], PMG_Cards.SUITS[s]))
        end
    end
    return deck
end

function PMG_Cards.shuffle(seed)
    return PMG_Random.shuffle(PMG_Cards.standardDeck(), PMG_Random.hash(seed or "cards"))
end

function PMG_Cards.draw(deck)
    if not deck or #deck == 0 then
        return nil
    end
    return table.remove(deck)
end

function PMG_Cards.blackjackCardValue(card)
    local rank = PMG_Cards.rank(card)
    if rank == "A" then
        return 11
    end
    local value = PMG_Cards.RANK_VALUE[rank] or 0
    return math.min(value, 10)
end

function PMG_Cards.blackjackTotal(hand)
    local total = 0
    local aces = 0
    for i = 1, #(hand or {}) do
        local rank = PMG_Cards.rank(hand[i])
        total = total + PMG_Cards.blackjackCardValue(hand[i])
        if rank == "A" then
            aces = aces + 1
        end
    end
    while total > 21 and aces > 0 do
        total = total - 10
        aces = aces - 1
    end
    return total, aces > 0
end

function PMG_Cards.isBlackjack(hand)
    return #(hand or {}) == 2 and PMG_Cards.blackjackTotal(hand) == 21
end

local function sortedValues(cards)
    local values = {}
    for i = 1, #(cards or {}) do
        table.insert(values, PMG_Cards.rankValue(cards[i]))
    end
    table.sort(values, function(a, b)
        return a > b
    end)
    return values
end

local function valueCounts(cards)
    local counts = {}
    for i = 1, #(cards or {}) do
        local value = PMG_Cards.rankValue(cards[i])
        counts[value] = (counts[value] or 0) + 1
    end
    return counts
end

local function straightHigh(values)
    local seen = {}
    for i = 1, #values do
        seen[values[i]] = true
    end
    if seen[14] then
        seen[1] = true
    end
    for high = 14, 5, -1 do
        local ok = true
        for offset = 0, 4 do
            if not seen[high - offset] then
                ok = false
                break
            end
        end
        if ok then
            return high
        end
    end
    return nil
end

local function scoreVector(category, values)
    local score = category * 10000000000
    local mult = 100000000
    for i = 1, #(values or {}) do
        score = score + values[i] * mult
        mult = math.floor(mult / 100)
    end
    return score
end

function PMG_Cards.evaluateFive(cards)
    local values = sortedValues(cards)
    local counts = valueCounts(cards)
    local flush = true
    local suit = PMG_Cards.suit(cards[1])
    for i = 2, #cards do
        if PMG_Cards.suit(cards[i]) ~= suit then
            flush = false
            break
        end
    end
    local straight = straightHigh(values)
    if flush and straight then
        return { category = 8, name = "Straight Flush", values = { straight }, score = scoreVector(8, { straight }) }
    end

    local groups = {}
    for value, count in pairs(counts) do
        table.insert(groups, { value = value, count = count })
    end
    table.sort(groups, function(a, b)
        if a.count == b.count then
            return a.value > b.value
        end
        return a.count > b.count
    end)

    if groups[1].count == 4 then
        local kicker = 0
        for i = 1, #groups do
            if groups[i].count == 1 then
                kicker = groups[i].value
            end
        end
        return { category = 7, name = "Four of a Kind", values = { groups[1].value, kicker }, score = scoreVector(7, { groups[1].value, kicker }) }
    end
    if groups[1].count == 3 and groups[2] and groups[2].count == 2 then
        return { category = 6, name = "Full House", values = { groups[1].value, groups[2].value }, score = scoreVector(6, { groups[1].value, groups[2].value }) }
    end
    if flush then
        return { category = 5, name = "Flush", values = values, score = scoreVector(5, values) }
    end
    if straight then
        return { category = 4, name = "Straight", values = { straight }, score = scoreVector(4, { straight }) }
    end
    if groups[1].count == 3 then
        local kickers = { groups[1].value }
        for i = 1, #groups do
            if groups[i].count == 1 then
                table.insert(kickers, groups[i].value)
            end
        end
        return { category = 3, name = "Three of a Kind", values = kickers, score = scoreVector(3, kickers) }
    end
    if groups[1].count == 2 and groups[2] and groups[2].count == 2 then
        local pairHigh = math.max(groups[1].value, groups[2].value)
        local pairLow = math.min(groups[1].value, groups[2].value)
        local kicker = 0
        for i = 1, #groups do
            if groups[i].count == 1 then
                kicker = groups[i].value
            end
        end
        return { category = 2, name = "Two Pair", values = { pairHigh, pairLow, kicker }, score = scoreVector(2, { pairHigh, pairLow, kicker }) }
    end
    if groups[1].count == 2 then
        local kickers = { groups[1].value }
        for i = 1, #groups do
            if groups[i].count == 1 then
                table.insert(kickers, groups[i].value)
            end
        end
        return { category = 1, name = "Pair", values = kickers, score = scoreVector(1, kickers) }
    end
    return { category = 0, name = "High Card", values = values, score = scoreVector(0, values) }
end

local function fiveCardCombinations(cards)
    local result = {}
    for a = 1, #cards - 4 do
        for b = a + 1, #cards - 3 do
            for c = b + 1, #cards - 2 do
                for d = c + 1, #cards - 1 do
                    for e = d + 1, #cards do
                        table.insert(result, { cards[a], cards[b], cards[c], cards[d], cards[e] })
                    end
                end
            end
        end
    end
    return result
end

function PMG_Cards.evaluateBest(cards)
    local best = nil
    local combos = fiveCardCombinations(cards or {})
    for i = 1, #combos do
        local score = PMG_Cards.evaluateFive(combos[i])
        if not best or score.score > best.score then
            best = score
            best.cards = combos[i]
        end
    end
    return best or { category = 0, name = "High Card", values = {}, score = 0, cards = {} }
end

function PMG_Cards.canStackTableau(card, target)
    if not card then
        return false
    end
    if not target then
        return PMG_Cards.rank(card) == "K"
    end
    return PMG_Cards.color(card) ~= PMG_Cards.color(target) and PMG_Cards.sequenceValue(card) + 1 == PMG_Cards.sequenceValue(target)
end

function PMG_Cards.canMoveToFoundation(card, topCard)
    if not card then
        return false
    end
    if not topCard then
        return PMG_Cards.rank(card) == "A"
    end
    return PMG_Cards.suit(card) == PMG_Cards.suit(topCard) and PMG_Cards.sequenceValue(card) == PMG_Cards.sequenceValue(topCard) + 1
end

function PMG_Cards.newKlondike(seed, drawCount)
    local deck = PMG_Cards.shuffle(seed)
    local tableau = {}
    for col = 1, 7 do
        tableau[col] = {}
        for row = 1, col do
            table.insert(tableau[col], {
                card = PMG_Cards.draw(deck),
                faceUp = row == col,
            })
        end
    end
    return {
        drawCount = drawCount == 3 and 3 or 1,
        stock = deck,
        waste = {},
        foundations = { S = {}, H = {}, D = {}, C = {} },
        tableau = tableau,
        moves = 0,
        undo = nil,
        won = false,
    }
end

function PMG_Cards.foundationCount(foundations)
    local count = 0
    for _, pile in pairs(foundations or {}) do
        count = count + #pile
    end
    return count
end
