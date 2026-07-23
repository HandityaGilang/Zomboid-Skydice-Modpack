require "PlayableMinigames/PMG_Core"

PMG_Registry = PMG_Registry or {}
PMG_Registry.games = PMG_Registry.games or {}
PMG_Registry.order = PMG_Registry.order or {}

function PMG_Registry.register(game)
    if not game or not game.id then
        error("Minigame registration requires an id.")
    end
    if not PMG_Registry.games[game.id] then
        table.insert(PMG_Registry.order, game.id)
    end
    PMG_Registry.games[game.id] = game
    return game
end

function PMG_Registry.get(gameId)
    return PMG_Registry.games[gameId]
end

function PMG_Registry.list()
    local result = {}
    for i = 1, #PMG_Registry.order do
        local game = PMG_Registry.games[PMG_Registry.order[i]]
        if game then
            table.insert(result, game)
        end
    end
    return result
end

function PMG_Registry.canStart(game, playerObj, anchor, options)
    if not game then
        return false, "Unknown minigame."
    end
    if not PMG.isGameAvailable(game) then
        return false, PMG.betaMinigamesDisabledReason()
    end
    if game.canStart then
        return game.canStart(playerObj, anchor, options or {})
    end
    return true
end

function PMG_Registry.requiredPlayerCount(game)
    return tonumber(game and game.minPlayers) or 1, tonumber(game and game.maxPlayers) or 1
end
