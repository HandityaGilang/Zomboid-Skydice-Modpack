require "PlayableMinigames/PMG_Core"
require "PlayableMinigames/PMG_Anchors"
require "PlayableMinigames/PMG_Skills"
require "PlayableMinigames/PMG_Games"
require "PlayableMinigames/PMG_SessionHost"

PMGServer = PMGServer or {}

local function onlinePlayers()
    local result = {}
    local players = getOnlinePlayers and getOnlinePlayers() or nil
    if not players then
        return result
    end
    for i = 0, players:size() - 1 do
        table.insert(result, players:get(i))
    end
    return result
end

local function findOnlinePlayerByName(name)
    local players = onlinePlayers()
    for i = 1, #players do
        if PMG.getUsername(players[i]) == name then
            return players[i]
        end
    end
    return nil
end

local function onlineNameSet()
    local result = {}
    local players = onlinePlayers()
    for i = 1, #players do
        result[PMG.getUsername(players[i])] = true
    end
    return result
end

local function sendState(playerObj, state)
    if playerObj and state then
        sendServerCommand(playerObj, PMG.MODULE, PMG.CMD_STATE, { state = PMG.copyTable(state) })
    end
end

local function message(playerObj, text)
    if playerObj then
        sendServerCommand(playerObj, PMG.MODULE, PMG.CMD_MESSAGE, { text = tostring(text or "Minigame is not available."), viewerName = PMG.getUsername(playerObj) })
    end
end

local function validateWorldAnchor(gameId, anchor)
    return PMG_Anchors.validateAnchorForGame(gameId, anchor)
end

PMGServer.host = PMGServer.host or PMG_SessionHost.new({
    authenticatedPlayerName = function(playerObj)
        return PMG.getUsername(playerObj)
    end,
    sendState = sendState,
    message = message,
    findPlayerByName = findOnlinePlayerByName,
    onlineNameSet = onlineNameSet,
    rewardPlayer = function(playerObj, skillId, amount, reward)
        return PMG_Skills.rewardPlayer(playerObj, skillId, amount, reward)
    end,
    validateWorldAnchor = validateWorldAnchor,
})

local function onClientCommand(module, command, playerObj, args)
    if module ~= PMG.MODULE then
        return
    end
    PMGServer.host:handleCommand(playerObj, command, args or {})
end

function PMGServer.onTick()
    if PMGServer.host then
        PMGServer.host:onTick()
    end
end

Events.OnClientCommand.Add(onClientCommand)
Events.OnTick.Add(PMGServer.onTick)
