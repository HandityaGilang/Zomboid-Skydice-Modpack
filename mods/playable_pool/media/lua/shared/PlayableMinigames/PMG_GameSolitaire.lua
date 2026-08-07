require "PlayableMinigames/PMG_Core"
require "PlayableMinigames/PMG_Registry"
require "PlayableMinigames/PMG_Cards"
require "PlayableMinigames/PMG_Anchors"

local game = {
    id = "solitaire",
    name = "Klondike Solitaire",
    shortName = "Solitaire",
    icon = "game_solitaire.png",
    minPlayers = 1,
    maxPlayers = 1,
    requiredItem = "Base.CardDeck",
    requiredItemCount = 1,
    equipmentKind = "card_deck",
    anchorKind = "card_surface",
}

local function sol(session)
    session.privateState.solitaire = session.privateState.solitaire or {}
    return session.privateState.solitaire
end

local function top(list)
    return list and list[#list] or nil
end

function game.canStart(playerObj, anchor)
    local hasDeck = PMG_Anchors.hasCardDeckForAnchor(playerObj, anchor)
    if not hasDeck then
        return false, "Place a card deck on or next to the card table."
    end
    return true
end

local function newGame(session, drawCount)
    session.privateState.solitaireDealNo = (tonumber(session.privateState.solitaireDealNo) or 0) + 1
    local dealSeed = tostring(session.seed or session.key) ..
        ":solitaire:" .. tostring(drawCount or 1) ..
        ":" .. tostring(session.privateState.solitaireDealNo)
    session.privateState.solitaire = PMG_Cards.newKlondike(dealSeed, drawCount)
    local state = sol(session)
    state.autoSolving = false
    state.lost = false
    state.lossReason = nil
    session.phase = PMG.PHASE_PLAYING
    PMG.setPhase(session, PMG.PHASE_PLAYING)
end

local function topFaceUpCard(pile)
    local entry = top(pile)
    if entry and entry.faceUp then
        return entry.card
    end
    return nil
end

local function wasteCardHasDestination(state, card)
    if not card then
        return false
    end

    local suit = PMG_Cards.suit(card)
    if PMG_Cards.canMoveToFoundation(card, top((state.foundations or {})[suit])) then
        return true
    end

    for col = 1, 7 do
        if PMG_Cards.canStackTableau(card, topFaceUpCard((state.tableau or {})[col] or {})) then
            return true
        end
    end

    return false
end

local function findVisibleMove(state)
    local wasteCard = top(state.waste or {})
    if wasteCardHasDestination(state, wasteCard) then
        return true
    end

    for fromCol = 1, 7 do
        local pile = (state.tableau or {})[fromCol] or {}
        local entry = top(pile)
        if entry and entry.faceUp then
            local suit = PMG_Cards.suit(entry.card)
            if PMG_Cards.canMoveToFoundation(entry.card, top((state.foundations or {})[suit])) then
                return true
            end
        end

        for index = 1, #pile do
            local stackEntry = pile[index]
            if stackEntry and stackEntry.faceUp then
                for toCol = 1, 7 do
                    local targetCard = topFaceUpCard((state.tableau or {})[toCol] or {})
                    local opensNewAccess = targetCard ~= nil or index > 1
                    if toCol ~= fromCol and opensNewAccess and PMG_Cards.canStackTableau(stackEntry.card, targetCard) then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function stockCanRevealMove(state)
    local simStock = PMG.copyTable(state.stock or {})
    local simWaste = PMG.copyTable(state.waste or {})
    local seen = {}
    local drawCount = state.drawCount or 1

    for _ = 1, 160 do
        local signature = table.concat(simStock, ",") .. "|" .. table.concat(simWaste, ",")
        if seen[signature] then
            return false
        end
        seen[signature] = true

        if #simStock == 0 then
            if #simWaste == 0 then
                return false
            end
            while #simWaste > 0 do
                table.insert(simStock, table.remove(simWaste))
            end
        else
            for _ = 1, math.min(drawCount, #simStock) do
                table.insert(simWaste, PMG_Cards.draw(simStock))
            end
            if wasteCardHasDestination(state, top(simWaste)) then
                return true
            end
        end
    end

    return false
end

local function hasSolitaireProgress(state)
    if PMG_Cards.foundationCount(state.foundations) >= 52 then
        return true
    end
    if findVisibleMove(state) then
        return true
    end
    return stockCanRevealMove(state)
end

local function allTableauCardsFaceUp(state)
    for col = 1, 7 do
        local pile = (state.tableau or {})[col] or {}
        for i = 1, #pile do
            if not pile[i].faceUp then
                return false
            end
        end
    end
    return true
end

local function findAutoSolveMove(state)
    local wasteCard = top(state.waste or {})
    if wasteCard then
        local suit = PMG_Cards.suit(wasteCard)
        if PMG_Cards.canMoveToFoundation(wasteCard, top((state.foundations or {})[suit])) then
            return { kind = "waste_to_foundation" }
        end
    end

    for fromCol = 1, 7 do
        local entry = top((state.tableau or {})[fromCol] or {})
        if entry and entry.faceUp then
            local suit = PMG_Cards.suit(entry.card)
            if PMG_Cards.canMoveToFoundation(entry.card, top((state.foundations or {})[suit])) then
                return { kind = "tableau_to_foundation", fromCol = fromCol }
            end
        end
    end

    return nil
end

local function revealTableauTop(pile)
    local card = top(pile)
    if card then
        card.faceUp = true
    end
end

local function applyAutoSolveMove(state, move)
    if not move then
        return false
    end
    if move.kind == "waste_to_foundation" then
        local card = top(state.waste or {})
        if not card then
            return false
        end
        table.insert(state.foundations[PMG_Cards.suit(card)], table.remove(state.waste))
        return true
    elseif move.kind == "tableau_to_foundation" then
        local fromCol = PMG.clamp(move.fromCol, 1, 7)
        local entry = top((state.tableau or {})[fromCol] or {})
        if not entry or not entry.faceUp then
            return false
        end
        table.insert(state.foundations[PMG_Cards.suit(entry.card)], entry.card)
        table.remove(state.tableau[fromCol])
        revealTableauTop(state.tableau[fromCol])
        return true
    end
    return false
end

local function canAutoSolve(state)
    if #(state.stock or {}) > 0 or not allTableauCardsFaceUp(state) then
        return false
    end

    local sim = {
        stock = PMG.copyTable(state.stock or {}),
        waste = PMG.copyTable(state.waste or {}),
        foundations = PMG.copyTable(state.foundations or {}),
        tableau = PMG.copyTable(state.tableau or {}),
    }

    for _ = 1, 80 do
        if PMG_Cards.foundationCount(sim.foundations) >= 52 then
            return true
        end
        local move = findAutoSolveMove(sim)
        if not applyAutoSolveMove(sim, move) then
            return false
        end
    end

    return PMG_Cards.foundationCount(sim.foundations) >= 52
end

function game.createInitialState(session, ownerName, options)
    local drawCount = options and options.args and tonumber(options.args.drawCount) or 1
    newGame(session, drawCount)
end

local function publicCard(entry)
    if not entry then
        return nil
    end
    if entry.faceUp then
        return { card = entry.card, faceUp = true }
    end
    return { faceUp = false }
end

local function refreshPublic(session)
    local state = sol(session)
    session.publicState.drawCount = state.drawCount
    session.publicState.stockCount = #(state.stock or {})
    session.publicState.waste = PMG.copyTable(state.waste or {})
    session.publicState.foundations = PMG.copyTable(state.foundations or {})
    session.publicState.tableau = {}
    for col = 1, 7 do
        session.publicState.tableau[col] = {}
        local pile = state.tableau[col] or {}
        for i = 1, #pile do
            table.insert(session.publicState.tableau[col], publicCard(pile[i]))
        end
    end
    session.publicState.foundationCount = PMG_Cards.foundationCount(state.foundations)
    session.publicState.won = state.won
    session.publicState.lost = state.lost
    session.publicState.lossReason = state.lossReason
    session.publicState.autoSolving = state.autoSolving
    session.publicState.moves = state.moves or 0
end

local function snapshot(state)
    return {
        stock = PMG.copyTable(state.stock),
        waste = PMG.copyTable(state.waste),
        foundations = PMG.copyTable(state.foundations),
        tableau = PMG.copyTable(state.tableau),
        moves = state.moves,
        won = state.won,
        lost = state.lost,
        lossReason = state.lossReason,
        autoSolving = state.autoSolving,
    }
end

local function saveUndo(state)
    state.undo = snapshot(state)
end

local function afterMove(session, message, metadata)
    local state = sol(session)
    state.moves = (state.moves or 0) + 1
    state.lost = false
    state.lossReason = nil

    if PMG_Cards.foundationCount(state.foundations) >= 52 then
        state.won = true
        state.autoSolving = false
        PMG.setPhase(session, PMG.PHASE_GAME_OVER)
        PMG.addEvent(session, "Solitaire cleared.", "win")
    elseif canAutoSolve(state) then
        local wasAutoSolving = state.autoSolving
        state.autoSolving = true
        if message then
            PMG.addEvent(session, message, "move", metadata)
        end
        if not wasAutoSolving then
            PMG.addEvent(session, "Solitaire is solved. Auto-completing.", "move")
        end
    elseif not hasSolitaireProgress(state) then
        state.autoSolving = false
        state.lost = true
        state.lossReason = "No more moves are available."
        PMG.setPhase(session, PMG.PHASE_GAME_OVER)
        PMG.addEvent(session, state.lossReason, "lose")
    elseif message then
        state.autoSolving = false
        PMG.addEvent(session, message, "move", metadata)
    end
    refreshPublic(session)
end

function game.applyAction(session, playerName, action, args)
    if session.owner ~= playerName then
        return false, "Only the solitaire player can move cards."
    end
    local state = sol(session)
    if action == "new_game" then
        newGame(session, tonumber(args and args.drawCount) == 3 and 3 or 1)
        PMG.addEvent(session, "New solitaire game started.", "deal")
        refreshPublic(session)
        return true
    elseif state.won or state.lost then
        if action ~= "undo" then
            return false, state.won and "Solitaire is already cleared." or "This solitaire deal has no more moves."
        end
    elseif state.autoSolving and action ~= "auto_solve_step" and action ~= "undo" then
        return false, "Solitaire is auto-solving."
    end

    if action == "auto_solve_step" then
        if not state.autoSolving then
            if not canAutoSolve(state) then
                return false, "Solitaire is not ready to auto-solve."
            end
            state.autoSolving = true
        end
        local move = findAutoSolveMove(state)
        if not applyAutoSolveMove(state, move) then
            state.autoSolving = false
            refreshPublic(session)
            return false, "No automatic solitaire move is available."
        end
        afterMove(session, "Auto-solved a card.")
        return true
    elseif action == "draw" then
        saveUndo(state)
        if #(state.stock or {}) == 0 then
            while #(state.waste or {}) > 0 do
                table.insert(state.stock, table.remove(state.waste))
            end
            afterMove(session, "Stock recycled.", { solitaireAction = "recycle" })
            return true
        end
        for _ = 1, math.min(state.drawCount or 1, #state.stock) do
            table.insert(state.waste, PMG_Cards.draw(state.stock))
        end
        afterMove(session, "Drew from stock.", { solitaireAction = "draw" })
        return true
    elseif action == "waste_to_foundation" then
        local card = top(state.waste)
        local suit = PMG_Cards.suit(card)
        if not PMG_Cards.canMoveToFoundation(card, top(state.foundations[suit])) then
            return false, "That card cannot move to the foundation."
        end
        saveUndo(state)
        table.insert(state.foundations[suit], table.remove(state.waste))
        afterMove(session, "Moved waste to foundation.", { solitaireAction = "waste_to_foundation" })
        return true
    elseif action == "waste_to_tableau" then
        local col = PMG.clamp(args.toCol, 1, 7)
        local card = top(state.waste)
        local target = top(state.tableau[col] or {})
        target = target and target.faceUp and target.card or nil
        if not PMG_Cards.canStackTableau(card, target) then
            return false, "That card cannot stack there."
        end
        saveUndo(state)
        table.insert(state.tableau[col], { card = table.remove(state.waste), faceUp = true })
        afterMove(session, "Moved waste to tableau.", { solitaireAction = "waste_to_tableau" })
        return true
    elseif action == "tableau_to_foundation" then
        local fromCol = PMG.clamp(args.fromCol, 1, 7)
        local entry = top(state.tableau[fromCol])
        if not entry or not entry.faceUp then
            return false, "No face-up tableau card to move."
        end
        local suit = PMG_Cards.suit(entry.card)
        if not PMG_Cards.canMoveToFoundation(entry.card, top(state.foundations[suit])) then
            return false, "That card cannot move to the foundation."
        end
        saveUndo(state)
        table.insert(state.foundations[suit], entry.card)
        table.remove(state.tableau[fromCol])
        revealTableauTop(state.tableau[fromCol])
        afterMove(session, "Moved tableau card to foundation.")
        return true
    elseif action == "tableau_to_tableau" then
        local fromCol = PMG.clamp(args.fromCol, 1, 7)
        local toCol = PMG.clamp(args.toCol, 1, 7)
        if fromCol == toCol then
            return false, "Move must go to another tableau column."
        end
        local index = PMG.clamp(args.index, 1, #(state.tableau[fromCol] or {}))
        local fromPile = state.tableau[fromCol] or {}
        local entry = fromPile[index]
        if not entry or not entry.faceUp then
            return false, "Move must start on a face-up card."
        end
        local targetEntry = top(state.tableau[toCol] or {})
        local target = targetEntry and targetEntry.faceUp and targetEntry.card or nil
        if not PMG_Cards.canStackTableau(entry.card, target) then
            return false, "That stack cannot move there."
        end
        saveUndo(state)
        local moving = {}
        while #fromPile >= index do
            table.insert(moving, table.remove(fromPile, index))
        end
        for i = 1, #moving do
            table.insert(state.tableau[toCol], moving[i])
        end
        revealTableauTop(fromPile)
        afterMove(session, "Moved tableau stack.")
        return true
    elseif action == "undo" then
        if not state.undo then
            return false, "No solitaire move to undo."
        end
        local undo = state.undo
        state.stock = undo.stock
        state.waste = undo.waste
        state.foundations = undo.foundations
        state.tableau = undo.tableau
        state.moves = undo.moves
        state.won = undo.won
        state.lost = undo.lost
        state.lossReason = undo.lossReason
        state.autoSolving = undo.autoSolving
        state.undo = nil
        PMG.setPhase(session, PMG.PHASE_PLAYING)
        PMG.addEvent(session, "Undid the last move.", "move")
        refreshPublic(session)
        return true
    end
    return false, "Unknown solitaire action."
end

function game.legalActions(session, viewerName)
    local state = sol(session)
    local isOwner = viewerName == session.owner
    local canPlay = isOwner and not state.won and not state.lost and not state.autoSolving
    local playDisabledReason = PMG.text("IGUI_PlayableMinigames_WatchOnly", "Watch only")
    if isOwner then
        if state.won then
            playDisabledReason = PMG.text("IGUI_PlayableMinigames_GameWon", "Game won")
        elseif state.lost then
            playDisabledReason = PMG.text("IGUI_PlayableMinigames_SolitaireNoMoves", "No moves remain")
        elseif state.autoSolving then
            playDisabledReason = PMG.text("IGUI_PlayableMinigames_SolitaireAutoSolving", "Auto-solving")
        end
    end
    return {
        PMG.legalAction("draw", #(state.stock or {}) > 0 and PMG.text("IGUI_PlayableMinigames_ActionDraw", "Draw") or PMG.text("IGUI_PlayableMinigames_ActionRecycle", "Recycle"), canPlay, playDisabledReason),
        PMG.legalAction("undo", PMG.text("IGUI_PlayableMinigames_ActionUndo", "Undo"), isOwner and state.undo ~= nil and not state.autoSolving, isOwner and PMG.text("IGUI_PlayableMinigames_NoUndo", "No undo") or PMG.text("IGUI_PlayableMinigames_WatchOnly", "Watch only")),
        PMG.legalAction("new_game", PMG.text("IGUI_PlayableMinigames_ActionNew1", "New 1"), isOwner, PMG.text("IGUI_PlayableMinigames_WatchOnly", "Watch only"), { drawCount = 1 }),
        PMG.legalAction("new_game", PMG.text("IGUI_PlayableMinigames_ActionNew3", "New 3"), isOwner, PMG.text("IGUI_PlayableMinigames_WatchOnly", "Watch only"), { drawCount = 3 }),
    }
end

function game.rewardForAction(session, playerName, action)
    if action == "new_game" or action == "undo" then
        return nil
    end
    local state = sol(session)
    if action == "auto_solve_step" then
        if state.won then
            return { skillId = "Cards", xp = 25, sessionCap = 260 }
        end
        return nil
    end
    local xp = action == "draw" and 1 or 2
    if state.won then
        xp = xp + 25
    end
    return { skillId = "Cards", xp = xp, sessionCap = 260 }
end

function game.redactState(session, payload, viewerName)
    if viewerName == session.owner then
        payload.privateState = payload.privateState or {}
        payload.privateState.solitaire = PMG.copyTable(sol(session))
    end
end

PMG_Registry.register(game)
