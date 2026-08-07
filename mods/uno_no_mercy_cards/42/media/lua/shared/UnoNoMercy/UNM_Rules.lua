require "UnoNoMercy/UNM_Core"

UNM_Rules = UNM_Rules or {}

local LABELS = {
    S = "Skip",
    SA = "Skip Everyone",
    R = "Reverse",
    D2 = "+2",
    D4 = "+4",
    DA = "Discard All",
    WR4 = "Wild Reverse +4",
    W6 = "Wild +6",
    W10 = "Wild +10",
    WCR = "Wild Color Roulette",
}

local DRAW_VALUE = {
    D2 = 2,
    D4 = 4,
    WR4 = 4,
    W6 = 6,
    W10 = 10,
}

function UNM_Rules.card(color, value)
    if color == "wild" then
        return tostring(value)
    end
    return tostring(UNM.COLOR_CODE[color] or color) .. tostring(value)
end

function UNM_Rules.cardColor(card)
    card = tostring(card or "")
    return UNM.CODE_COLOR[string.sub(card, 1, 1)] or "wild"
end

function UNM_Rules.cardValue(card)
    card = tostring(card or "")
    if UNM_Rules.cardColor(card) == "wild" then
        return card
    end
    return string.sub(card, 2)
end

function UNM_Rules.cardLabel(card)
    local color = UNM_Rules.cardColor(card)
    local value = UNM_Rules.cardValue(card)
    local label = LABELS[value] or tostring(value)
    if color == "wild" then
        return label
    end
    return (UNM.COLOR_LABEL[color] or color) .. " " .. label
end

local function insertCopies(deck, card, count)
    for _ = 1, count do
        table.insert(deck, card)
    end
end

function UNM_Rules.newDeck(seed)
    local deck = {}
    for _, color in ipairs(UNM.COLORS) do
        for number = 0, 9 do
            insertCopies(deck, UNM_Rules.card(color, tostring(number)), 2)
        end
        insertCopies(deck, UNM_Rules.card(color, "D2"), 3)
        insertCopies(deck, UNM_Rules.card(color, "D4"), 2)
        insertCopies(deck, UNM_Rules.card(color, "S"), 3)
        insertCopies(deck, UNM_Rules.card(color, "SA"), 2)
        insertCopies(deck, UNM_Rules.card(color, "R"), 3)
        insertCopies(deck, UNM_Rules.card(color, "DA"), 3)
    end
    insertCopies(deck, "WR4", 8)
    insertCopies(deck, "W6", 4)
    insertCopies(deck, "W10", 4)
    insertCopies(deck, "WCR", 8)
    return UNM.shuffle(deck, seed)
end

function UNM_Rules.drawCard(state)
    state.deck = state.deck or {}
    return #state.deck > 0 and table.remove(state.deck) or nil
end

function UNM_Rules.topDiscard(state)
    return state and state.discard and state.discard[#state.discard] or nil
end

function UNM_Rules.drawValue(card)
    return DRAW_VALUE[UNM_Rules.cardValue(card)] or 0
end

function UNM_Rules.isDrawCard(card)
    return UNM_Rules.drawValue(card) > 0
end

function UNM_Rules.isWild(card)
    return UNM_Rules.cardColor(card) == "wild"
end

function UNM_Rules.isActionCard(card)
    return tonumber(UNM_Rules.cardValue(card)) == nil
end

function UNM_Rules.requiresColor(card)
    local value = UNM_Rules.cardValue(card)
    return value == "WR4" or value == "W6" or value == "W10"
end

function UNM_Rules.requiresTarget(card, state)
    return UNM_Rules.cardValue(card) == "7" and not (state and state.sevenZeroEnabled == false)
end

function UNM_Rules.canStack(card, state)
    local pending = tonumber(state and state.pendingDraw) or 0
    if pending <= 0 then
        return false
    end
    return UNM_Rules.drawValue(card) >= (tonumber(state.pendingDrawMinimum) or 0)
end

function UNM_Rules.canPlay(card, state)
    if not card or not state then
        return false
    end
    if (tonumber(state.pendingDraw) or 0) > 0 then
        return UNM_Rules.canStack(card, state)
    end
    if UNM_Rules.isWild(card) then
        return true
    end
    local color = UNM_Rules.cardColor(card)
    local value = UNM_Rules.cardValue(card)
    if color == state.currentColor then
        return true
    end
    local top = UNM_Rules.topDiscard(state)
    return top and value == UNM_Rules.cardValue(top)
end

function UNM_Rules.nextIndex(state, playerCount, steps)
    playerCount = math.max(1, tonumber(playerCount) or 1)
    local direction = tonumber(state.direction) == -1 and -1 or 1
    local index = math.floor(tonumber(state.turnIndex) or 1)
    steps = math.max(0, math.floor(tonumber(steps) or 1))
    for _ = 1, steps do
        index = index + direction
        if index < 1 then index = playerCount end
        if index > playerCount then index = 1 end
    end
    return index
end

function UNM_Rules.bestColorForHand(hand)
    local counts = { red = 0, yellow = 0, green = 0, blue = 0 }
    for _, card in ipairs(hand or {}) do
        local color = UNM_Rules.cardColor(card)
        if counts[color] ~= nil then
            counts[color] = counts[color] + 1
        end
    end
    local best = "red"
    for _, color in ipairs(UNM.COLORS) do
        if counts[color] > counts[best] then best = color end
    end
    return best
end

function UNM_Rules.scoreCard(card)
    local value = UNM_Rules.cardValue(card)
    if value == "W10" then return 100 end
    if value == "W6" or value == "WR4" or value == "WCR" then return 80 end
    if value == "D4" or value == "D2" then return 60 end
    if LABELS[value] then return 35 end
    if value == "7" or value == "0" then return 25 end
    return tonumber(value) or 0
end
