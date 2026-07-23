require "PlayableMinigames/PMG_Core"
require "PlayableMinigames/PMG_Registry"
require "PlayableMinigames/PMG_Anchors"
require "PlayableMinigames/PMG_BoardGames"
require "PlayableMinigames/PMG_AI"

local game = {
    id = "checkers",
    name = "Checkers",
    shortName = "Checkers",
    icon = "game_checkers.png",
    minPlayers = 2,
    maxPlayers = 2,
    supportsBots = true,
    botName = "Checkers Bot",
    botThinkingDelay = { minMs = 1000, maxMs = 1875 },
    requiredItem = "Base.CheckerBoard",
    requiredItemCount = 1,
    equipmentKind = "checkerboard",
    anchorKind = "checkerboard",
}

local function checkers(session)
    session.privateState.checkers = session.privateState.checkers or PMG_BoardGames.checkersInitial()
    return session.privateState.checkers
end

local function colorForPlayer(state, playerName)
    if state and state.seats then
        if state.seats.black == playerName then
            return "black"
        elseif state.seats.white == playerName then
            return "white"
        end
    end
    return nil
end

local function assignSeat(session, playerName)
    local state = checkers(session)
    if not state.seats.black then
        state.seats.black = playerName
    elseif not state.seats.white and state.seats.black ~= playerName then
        state.seats.white = playerName
    end
end

function game.canStart(playerObj, anchor)
    local ok, _, source = PMG_Anchors.hasCheckerBoardForAnchor(playerObj, anchor)
    if not ok then
        return false, "Place a checkerboard here."
    end
    return true, source
end

function game.canJoin()
    return true
end

function game.createInitialState(session, ownerName)
    session.privateState.checkers = PMG_BoardGames.checkersInitial()
    assignSeat(session, ownerName)
    game.refreshPublic(session)
end

function game.onPlayerJoined(session, name)
    assignSeat(session, name)
    local state = checkers(session)
    if state.seats.black and state.seats.white then
        state.status = "playing"
    end
    game.refreshPublic(session)
end

function game.onPlayerLeft(session, name)
    local state = checkers(session)
    if state.seats.black == name then
        state.seats.black = nil
    end
    if state.seats.white == name then
        state.seats.white = nil
    end
    state.status = "waiting"
    game.refreshPublic(session)
end

function game.refreshPublic(session)
    local state = checkers(session)
    session.publicState.board = PMG.copyTable(state.board)
    session.publicState.turnColor = state.turn
    session.publicState.seats = PMG.copyTable(state.seats)
    session.publicState.captured = PMG.copyTable(state.captured)
    session.publicState.forceFrom = PMG.copyTable(state.forceFrom)
    session.publicState.lastMove = PMG.copyTable(state.lastMove)
    session.publicState.moveCount = state.moveCount or 0
    session.publicState.boardStatus = state.status
    session.publicState.winnerColor = state.winnerColor
    session.publicState.legalMoves = PMG.copyTable(PMG_BoardGames.checkersLegalMoves(state, state.turn))
    if state.winnerColor then
        PMG.setPhase(session, PMG.PHASE_GAME_OVER)
        session.publicState.winner = state.seats[state.winnerColor]
        session.publicState.winReason = tostring(state.winnerColor) .. " won."
    elseif state.seats.black and state.seats.white then
        PMG.setPhase(session, PMG.PHASE_PLAYING)
    else
        PMG.setPhase(session, PMG.PHASE_WAITING)
    end
end

function game.applyAction(session, playerName, action, args)
    if action ~= "move" then
        return false, "Unknown checkers action."
    end
    local state = checkers(session)
    if session.phase == PMG.PHASE_GAME_OVER then
        return false, "Checkers is already over."
    end
    if not state.seats.black or not state.seats.white then
        return false, "Checkers needs two players."
    end
    local color = colorForPlayer(state, playerName)
    if color ~= state.turn then
        return false, "It is not your turn."
    end
    local ok, reason = PMG_BoardGames.applyCheckersMove(state, args or {})
    if not ok then
        return false, reason
    end
    local last = state.lastMove or {}
    local message = tostring(playerName) .. " moved " ..
        PMG_BoardGames.squareName(last.fromRow, last.fromCol) .. "-" ..
        PMG_BoardGames.squareName(last.toRow, last.toCol) .. "."
    if state.forceFrom then
        message = message .. " Continue the jump."
    elseif state.winnerColor then
        message = tostring(playerName) .. " won checkers."
    end
    PMG.addEvent(session, message, state.winnerColor and "win" or "board_move")
    game.refreshPublic(session)
    return true
end

function game.legalActions(session, viewerName)
    local state = checkers(session)
    local color = colorForPlayer(state, viewerName)
    local enabled = color == state.turn and session.phase ~= PMG.PHASE_GAME_OVER and state.seats.black and state.seats.white
    local reason = nil
    if not color then
        reason = PMG.text("IGUI_PlayableMinigames_WatchOnly", "Watch only")
    elseif not state.seats.black or not state.seats.white then
        reason = PMG.text("IGUI_PlayableMinigames_NeedTwoPlayers", "Need 2 players")
    elseif color ~= state.turn then
        reason = PMG.text("IGUI_PlayableMinigames_NotYourTurn", "Not your turn")
    elseif session.phase == PMG.PHASE_GAME_OVER then
        reason = PMG.text("IGUI_PlayableMinigames_GameOver", "Game over")
    end
    return {
        PMG.legalAction("move", PMG.text("IGUI_PlayableMinigames_ActionMove", "Move"), enabled, reason),
    }
end

function game.botPlayerToAct(session)
    local state = checkers(session)
    return state.seats and state.seats[state.turn]
end

function game.botTurnKey(session, botName)
    local state = checkers(session)
    local forceFrom = state.forceFrom or {}
    return table.concat({
        "checkers",
        tostring(botName or ""),
        tostring(state.turn or ""),
        tostring(state.moveCount or 0),
        tostring(forceFrom.row or ""),
        tostring(forceFrom.col or ""),
    }, ":")
end

function game.botAction(session, botName, difficulty)
    local state = checkers(session)
    local move = PMG_AI.chooseCheckersMove(session, state, botName, difficulty)
    if not move then
        return nil
    end
    return "move", move
end

function game.rewardForAction(session, playerName, action)
    if action ~= "move" then
        return nil
    end
    local state = checkers(session)
    local xp = state.lastMove and state.lastMove.captured and 3 or 1
    if state.winnerColor and state.seats[state.winnerColor] == playerName then
        xp = xp + 18
    end
    return { skillId = "Checkers", xp = xp, sessionCap = 180 }
end

PMG_Registry.register(game)
