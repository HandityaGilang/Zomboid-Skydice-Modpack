require "UnoNoMercy/UNM_Core"
require "UnoNoMercy/UNM_Rules"
require "UnoNoMercy/UNM_Host"

UNM_Server = UNM_Server or {}

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
        if UNM.username(players[i]) == name then
            return players[i]
        end
    end
    return nil
end

local function sendState(playerObj, state)
    if playerObj and state then
        sendServerCommand(playerObj, UNM.MODULE, UNM.CMD_STATE, { state = UNM.copy(state) })
    end
end

local function message(playerObj, text)
    if playerObj then
        sendServerCommand(playerObj, UNM.MODULE, UNM.CMD_MESSAGE, {
            text = tostring(text or "UNO No Mercy is not available."),
            viewerName = UNM.username(playerObj),
        })
    end
end

local function applyMoodRelief(playerName, boredom, stress, unhappiness)
    local playerObj = findPlayerByName(playerName)
    if not playerObj then
        return
    end
    UNM.reduceCharacterStat(playerObj, "BOREDOM", boredom)
    UNM.reduceCharacterStat(playerObj, "STRESS", stress)
    UNM.reduceCharacterStat(playerObj, "UNHAPPINESS", unhappiness)
end

UNM_Server.host = UNM_Server.host or UNM_Host.new({
    playerName = function(playerObj)
        return UNM.username(playerObj)
    end,
    sendState = sendState,
    message = message,
    findPlayerByName = findPlayerByName,
    applyMoodRelief = applyMoodRelief,
})

local function onClientCommand(module, command, playerObj, args)
    if module ~= UNM.MODULE then
        return
    end
    UNM_Server.host:handleCommand(playerObj, command, args or {})
end

function UNM_Server.onTick()
    if UNM_Server.host then
        UNM_Server.host:onTick()
    end
end

function UNM_Server.everyOneMinute()
    if UNM_Server.host then
        UNM_Server.host:relieveActivePlayers()
    end
end

Events.OnClientCommand.Add(onClientCommand)
Events.OnTick.Add(UNM_Server.onTick)
Events.EveryOneMinute.Add(UNM_Server.everyOneMinute)
