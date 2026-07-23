require "PlayableSurvivalCards/PSC_Core"
require "PlayableSurvivalCards/PSC_Rules"
require "PlayableSurvivalCards/PSC_Host"

PSC_Server = PSC_Server or {}

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

local function findPlayerByName(name)
    local players = onlinePlayers()
    for i = 1, #players do
        if PSC.username(players[i]) == name then
            return players[i]
        end
    end
    return nil
end

local function sendState(playerObj, state)
    if playerObj and state then
        sendServerCommand(playerObj, PSC.MODULE, PSC.CMD_STATE, { state = PSC.copy(state) })
    end
end

local function message(playerObj, text)
    if playerObj then
        sendServerCommand(playerObj, PSC.MODULE, PSC.CMD_MESSAGE, {
            text = tostring(text or "UNO is not available."),
            viewerName = PSC.username(playerObj),
        })
    end
end

local function applyMoodRelief(playerName, boredom, stress, unhappiness)
    local playerObj = findPlayerByName(playerName)
    if not playerObj then
        return
    end
    PSC.reduceCharacterStat(playerObj, "BOREDOM", boredom)
    PSC.reduceCharacterStat(playerObj, "STRESS", stress)
    PSC.reduceCharacterStat(playerObj, "UNHAPPINESS", unhappiness)
end

PSC_Server.host = PSC_Server.host or PSC_Host.new({
    playerName = function(playerObj)
        return PSC.username(playerObj)
    end,
    sendState = sendState,
    message = message,
    findPlayerByName = findPlayerByName,
    applyMoodRelief = applyMoodRelief,
})

local function onClientCommand(module, command, playerObj, args)
    if module ~= PSC.MODULE then
        return
    end
    PSC_Server.host:handleCommand(playerObj, command, args or {})
end

function PSC_Server.onTick()
    if PSC_Server.host then
        PSC_Server.host:onTick()
    end
end

function PSC_Server.everyOneMinute()
    if PSC_Server.host then
        PSC_Server.host:relieveActivePlayers()
    end
end

Events.OnClientCommand.Add(onClientCommand)
Events.OnTick.Add(PSC_Server.onTick)
Events.EveryOneMinute.Add(PSC_Server.everyOneMinute)
