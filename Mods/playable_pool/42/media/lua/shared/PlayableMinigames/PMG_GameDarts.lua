require "PlayableMinigames/PMG_Core"
require "PlayableMinigames/PMG_Registry"
require "PlayableMinigames/PMG_Darts"
require "PlayableMinigames/PMG_AI"
require "PlayableMinigames/PMG_Anchors"

local game = {
    id = "darts_501",
    name = "Darts 501",
    shortName = "Darts",
    icon = "game_darts.png",
    minPlayers = 1,
    maxPlayers = 4,
    supportsBots = true,
    botName = "Darts Bot",
    botThinkingDelay = { minMs = 750, maxMs = 1500 },
    requiredItem = "Base.Dart",
    requiredItemCount = 3,
    anchorKind = "dartboard",
}

function game.canStart(playerObj, anchor)
    local hasDarts, count = PMG_Anchors.hasDartsForAnchor(playerObj, anchor)
    if not hasDarts then
        return false, "Place three darts by the dartboard."
    end
    return true, count
end

function game.canJoin()
    return true
end

function game.createInitialState(session)
    PMG_Darts.createState(session)
end

function game.onPlayerJoined(session, name)
    PMG_Darts.onPlayerJoined(session, name)
end

function game.onPlayerLeft(session, name)
    local ps = session.publicState or {}
    if ps.scores then
        ps.scores[name] = nil
    end
    if ps.turnStartPlayer == name then
        ps.turnThrows = {}
        ps.turnScore = 0
        ps.turnStartPlayer = PMG.currentPlayerName(session)
        ps.turnStartScore = ps.scores and ps.scores[ps.turnStartPlayer] or PMG_Darts.START_SCORE
    end
end

function game.applyAction(session, playerName, action, args, context)
    if action == "throw" then
        return PMG_Darts.applyThrow(session, playerName, args, context)
    end
    return false, "Unknown darts action."
end

function game.legalActions(session, viewerName)
    local isPlayer = PMG.findNameIndex(session.players or {}, viewerName) ~= nil
    local isTurn = PMG.currentPlayerName(session) == viewerName
    local gameOver = session.phase == PMG.PHASE_GAME_OVER
    local reason = nil
    if not isPlayer then
        reason = PMG.text("IGUI_PlayableMinigames_WatchOnly", "Watch only")
    elseif gameOver then
        reason = PMG.text("IGUI_PlayableMinigames_GameOver", "Game over")
    elseif not isTurn then
        reason = PMG.text("IGUI_PlayableMinigames_NotYourTurn", "Not your turn")
    end
    return {
        PMG.legalAction("throw", PMG.text("IGUI_PlayableMinigames_ActionThrow", "Throw"), isPlayer and isTurn and not gameOver, reason),
    }
end

function game.botPlayerToAct(session)
    return PMG.currentPlayerName(session)
end

function game.botTurnKey(session, botName)
    local ps = session.publicState or {}
    return table.concat({
        "darts_501",
        tostring(session.phase or ""),
        tostring(botName or ""),
        tostring(session.currentPlayer or ""),
        tostring(ps.turnStartPlayer or ""),
        tostring(#(ps.turnThrows or {})),
        tostring(ps.turnStartScore or ""),
    }, ":")
end

function game.botAction(session, botName, difficulty)
    return "throw", PMG_AI.chooseDartThrow(session, botName, difficulty)
end

function game.rewardForAction(session, playerName, action)
    if action ~= "throw" then
        return nil
    end
    local throw = session.publicState and session.publicState.lastThrow or nil
    local xp = 1
    if throw and (tonumber(throw.score) or 0) >= 50 then
        xp = xp + 2
    end
    if session.publicState and session.publicState.winner == playerName then
        xp = xp + 20
    end
    return { skillId = "Darts", xp = xp, sessionCap = 180 }
end

PMG_Registry.register(game)
