require "PlayableSurvivalCards/PSC_Core"

PSC_Rules = PSC_Rules or {}

local VALUES = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "S", "R", "D2" }

function PSC_Rules.card(color, value)
    if color == "wild" then
        return tostring(value)
    end
    return tostring(PSC.COLOR_CODE[color] or color) .. tostring(value)
end

function PSC_Rules.cardColor(card)
    card = tostring(card or "")
    local code = string.sub(card, 1, 1)
    return PSC.CODE_COLOR[code] or "wild"
end

function PSC_Rules.cardValue(card)
    card = tostring(card or "")
    local color = PSC_Rules.cardColor(card)
    if color == "wild" then
        return card
    end
    return string.sub(card, 2)
end

function PSC_Rules.cardLabel(card)
    local color = PSC_Rules.cardColor(card)
    local value = PSC_Rules.cardValue(card)
    if value == "S" then
        value = "Skip"
    elseif value == "R" then
        value = "Reverse"
    elseif value == "D2" then
        value = "+2"
    elseif value == "W" then
        return "Wild"
    elseif value == "WD4" then
        return "Wild +4"
    end
    if color == "wild" then
        return value
    end
    return (PSC.COLOR_LABEL[color] or color) .. " " .. tostring(value)
end

function PSC_Rules.newDeck(seed)
    local deck = {}
    for _, color in ipairs(PSC.COLORS) do
        table.insert(deck, PSC_Rules.card(color, "0"))
        for i = 2, #VALUES do
            table.insert(deck, PSC_Rules.card(color, VALUES[i]))
            table.insert(deck, PSC_Rules.card(color, VALUES[i]))
        end
    end
    for _ = 1, 4 do
        table.insert(deck, "W")
        table.insert(deck, "WD4")
    end
    return PSC.shuffle(deck, seed)
end

function PSC_Rules.drawCard(state)
    if not state.deck then
        state.deck = {}
    end
    if #state.deck == 0 then
        PSC_Rules.recycleDiscard(state)
    end
    if #state.deck == 0 then
        return nil
    end
    return table.remove(state.deck)
end

function PSC_Rules.recycleDiscard(state)
    if not state or not state.discard or #state.discard <= 1 then
        return
    end
    local top = table.remove(state.discard)
    state.deck = PSC.shuffle(state.discard, tostring(state.seed or "") .. ":recycle:" .. tostring(state.recycleNo or 0))
    state.recycleNo = (state.recycleNo or 0) + 1
    state.discard = { top }
end

function PSC_Rules.topDiscard(state)
    return state and state.discard and state.discard[#state.discard] or nil
end

function PSC_Rules.drawValue(card)
    local value = PSC_Rules.cardValue(card)
    if value == "D2" then return 2 end
    if value == "WD4" then return 4 end
    return 0
end

function PSC_Rules.canPlay(card, state)
    if not card or not state then
        return false
    end
    local value = PSC_Rules.cardValue(card)
    if (tonumber(state.pendingDraw) or 0) > 0 then
        return PSC_Rules.drawValue(card) == (tonumber(state.pendingDrawValue) or 0)
    end
    if value == "W" or value == "WD4" then
        return true
    end
    local color = PSC_Rules.cardColor(card)
    if color == state.currentColor then
        return true
    end
    local top = PSC_Rules.topDiscard(state)
    return top and value == PSC_Rules.cardValue(top)
end

function PSC_Rules.nextIndex(state, playerCount, steps)
    playerCount = math.max(1, tonumber(playerCount) or 1)
    steps = tonumber(steps) or 1
    local direction = tonumber(state.direction) == -1 and -1 or 1
    local index = math.floor(tonumber(state.turnIndex) or 1)
    if index < 1 or index > playerCount then
        index = 1
    end
    for _ = 1, math.abs(steps) do
        index = index + direction
        if index < 1 then
            index = playerCount
        elseif index > playerCount then
            index = 1
        end
    end
    return index
end

function PSC_Rules.bestColorForHand(hand)
    local counts = { red = 0, yellow = 0, green = 0, blue = 0 }
    for i = 1, #(hand or {}) do
        local color = PSC_Rules.cardColor(hand[i])
        if counts[color] ~= nil then
            counts[color] = counts[color] + 1
        end
    end
    local best = "red"
    for _, color in ipairs(PSC.COLORS) do
        if counts[color] > counts[best] then
            best = color
        end
    end
    return best
end

function PSC_Rules.scoreCard(card)
    local value = PSC_Rules.cardValue(card)
    if value == "W" or value == "WD4" then
        return 50
    end
    if value == "S" or value == "R" or value == "D2" then
        return 20
    end
    return tonumber(value) or 0
end
