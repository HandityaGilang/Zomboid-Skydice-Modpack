require "PlayableMinigames/PMG_Core"
require "PlayableMinigames/PMG_Registry"
require "PlayableMinigames/PMG_Anchors"
require "PlayableMinigames/PMG_BoardGames"
require "PlayableMinigames/PMG_AI"

local game = {
    id = "chess",
    name = "Chess",
    shortName = "Chess",
    icon = "game_chess.png",
    minPlayers = 2,
    maxPlayers = 2,
    supportsBots = true,
    botName = "Chess Bot",
    botThinkingDelay = { minMs = 5000, maxMs = 8000 },
    requiredItem = "Base.ChessWhite",
    requiredItemCount = 1,
    equipmentKind = "checkerboard",
    anchorKind = "checkerboard",
}

local function chess(session)
    session.privateState.chess = session.privateState.chess or PMG_BoardGames.chessInitial()
    return session.privateState.chess
end

local function colorForPlayer(state, playerName)
    if state and state.seats then
        if state.seats.white == playerName then
            return "white"
        elseif state.seats.black == playerName then
            return "black"
        end
    end
    return nil
end

local function assignSeat(session, playerName)
    local state = chess(session)
    if not state.seats.white then
        state.seats.white = playerName
    elseif not state.seats.black and state.seats.white ~= playerName then
        state.seats.black = playerName
    end
end

function game.canStart(playerObj, anchor)
    local ok, _, reason = PMG_Anchors.hasChessSetForAnchor(playerObj, anchor)
    if not ok then
        return false, reason or "You need a checkerboard plus white and black chess pieces to play chess."
    end
    return true
end

function game.canJoin()
    return true
end

function game.createInitialState(session, ownerName)
    session.privateState.chess = PMG_BoardGames.chessInitial()
    assignSeat(session, ownerName)
    game.refreshPublic(session)
end

function game.onPlayerJoined(session, name)
    assignSeat(session, name)
    local state = chess(session)
    if state.seats.white and state.seats.black then
        state.status = "playing"
    end
    game.refreshPublic(session)
end

function game.onPlayerLeft(session, name)
    local state = chess(session)
    if state.seats.white == name then
        state.seats.white = nil
    end
    if state.seats.black == name then
        state.seats.black = nil
    end
    state.status = "waiting"
    game.refreshPublic(session)
end

function game.refreshPublic(session)
    local state = chess(session)
    session.publicState.board = PMG.copyTable(state.board)
    session.publicState.turnColor = state.turn
    session.publicState.seats = PMG.copyTable(state.seats)
    session.publicState.captured = PMG.copyTable(state.captured)
    session.publicState.lastMove = PMG.copyTable(state.lastMove)
    session.publicState.moveCount = state.moveCount or 0
    session.publicState.check = state.check == true
    session.publicState.checkmate = state.checkmate == true
    session.publicState.stalemate = state.stalemate == true
    session.publicState.winnerColor = state.winnerColor
    session.publicState.boardStatus = state.status
    session.publicState.legalMoves = PMG.copyTable(PMG_BoardGames.chessLegalMoves(state, state.turn))
    if state.checkmate then
        PMG.setPhase(session, PMG.PHASE_GAME_OVER)
        session.publicState.winner = state.seats[state.winnerColor or ""]
        session.publicState.winReason = tostring(state.winnerColor or "A player") .. " won by checkmate."
    elseif state.stalemate then
        PMG.setPhase(session, PMG.PHASE_GAME_OVER)
        session.publicState.winReason = "Stalemate."
    elseif state.seats.white and state.seats.black then
        PMG.setPhase(session, PMG.PHASE_PLAYING)
    else
        PMG.setPhase(session, PMG.PHASE_WAITING)
    end
end

function game.applyAction(session, playerName, action, args)
    if action ~= "move" then
        return false, "Unknown chess action."
    end
    local state = chess(session)
    if session.phase == PMG.PHASE_GAME_OVER then
        return false, "Chess is already over."
    end
    if not state.seats.white or not state.seats.black then
        return false, "Chess needs two players."
    end
    local color = colorForPlayer(state, playerName)
    if color ~= state.turn then
        return false, "It is not your turn."
    end
    local ok, reason = PMG_BoardGames.applyChessMove(state, args or {})
    if not ok then
        return false, reason
    end
    local last = state.lastMove or {}
    local message = tostring(playerName) .. " moved " ..
        PMG_BoardGames.squareName(last.fromRow, last.fromCol) .. "-" ..
        PMG_BoardGames.squareName(last.toRow, last.toCol) .. "."
    if state.checkmate then
        message = tostring(playerName) .. " delivered checkmate."
    elseif state.stalemate then
        message = "Chess ended in stalemate."
    elseif state.check then
        message = message .. " Check."
    end
    PMG.addEvent(session, message, state.checkmate and "win" or "board_move")
    game.refreshPublic(session)
    return true
end

function game.legalActions(session, viewerName)
    local state = chess(session)
    local color = colorForPlayer(state, viewerName)
    local enabled = color == state.turn and session.phase ~= PMG.PHASE_GAME_OVER and state.seats.white and state.seats.black
    local reason = nil
    if not color then
        reason = PMG.text("IGUI_PlayableMinigames_WatchOnly", "Watch only")
    elseif not state.seats.white or not state.seats.black then
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
    local state = chess(session)
    return state.seats and state.seats[state.turn]
end

function game.botTurnKey(session, botName)
    local state = chess(session)
    return table.concat({
        "chess",
        tostring(botName or ""),
        tostring(state.turn or ""),
        tostring(state.moveCount or 0),
        tostring(state.check == true),
    }, ":")
end

function game.botAction(session, botName, difficulty)
    local state = chess(session)
    local move = PMG_AI.chooseChessMove(session, state, botName, difficulty)
    if not move then
        return nil
    end
    return "move", move
end

function game.rewardForAction(session, playerName, action)
    if action ~= "move" then
        return nil
    end
    local state = chess(session)
    local xp = state.check and 3 or 1
    if state.winnerColor and state.seats[state.winnerColor] == playerName then
        xp = xp + 20
    end
    return { skillId = "Chess", xp = xp, sessionCap = 220 }
end

PMG_Registry.register(game)
