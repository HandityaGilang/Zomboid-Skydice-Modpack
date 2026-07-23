PSC = PSC or {}

PSC.MODULE = "PlayableSurvivalCards"

PSC.CMD_START = "Start"
PSC.CMD_JOIN = "Join"
PSC.CMD_WATCH = "Watch"
PSC.CMD_LEAVE = "Leave"
PSC.CMD_RESET = "Reset"
PSC.CMD_ACTION = "Action"
PSC.CMD_STATE = "State"
PSC.CMD_MESSAGE = "Message"

PSC.ACTION_START_ROUND = "start_round"
PSC.ACTION_PLAY_CARD = "play_card"
PSC.ACTION_DRAW = "draw"
PSC.ACTION_PASS = "pass"
PSC.ACTION_ADD_BOT = "add_bot"
PSC.ACTION_REMOVE_BOT = "remove_bot"
PSC.ACTION_TOGGLE_STACKING = "toggle_stacking"
PSC.ACTION_CALL_UNO = "call_uno"

PSC.PHASE_WAITING = "waiting"
PSC.PHASE_PLAYING = "playing"
PSC.PHASE_GAME_OVER = "game_over"

PSC.MAX_PLAY_DISTANCE = 8
PSC.MIN_PLAYERS = 2
PSC.MAX_PLAYERS = 4
PSC.START_HAND_SIZE = 7
PSC.BOT_ACTION_DELAY_MS = 1300
PSC.MOOD_BOREDOM_RELIEF_PER_MINUTE = 0.5
PSC.MOOD_STRESS_RELIEF_PER_MINUTE = 0.5
PSC.MOOD_UNHAPPINESS_RELIEF_PER_MINUTE = 0.25
PSC.WINNER_UNHAPPINESS_RELIEF = 5

PSC.COLORS = { "red", "yellow", "green", "blue" }
PSC.COLOR_CODE = { red = "R", yellow = "Y", green = "G", blue = "B" }
PSC.CODE_COLOR = { R = "red", Y = "yellow", G = "green", B = "blue" }
PSC.COLOR_LABEL = { red = "Red", yellow = "Yellow", green = "Green", blue = "Blue" }

function PSC.copy(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local result = {}
    seen[value] = result
    for key, child in pairs(value) do
        result[PSC.copy(key, seen)] = PSC.copy(child, seen)
    end
    return result
end

function PSC.text(key, fallback)
    if getText then
        local ok, value = pcall(function()
            return getText(key)
        end)
        if ok and value and value ~= key then
            return value
        end
    end
    return tostring(fallback or key)
end

function PSC.username(playerObj)
    if not playerObj then
        return "Player"
    end
    if playerObj.getUsername then
        local ok, value = pcall(function()
            return playerObj:getUsername()
        end)
        if ok and value and value ~= "" then
            return tostring(value)
        end
    end
    if playerObj.getDescriptor and playerObj:getDescriptor() and playerObj:getDescriptor().getForename then
        return tostring(playerObj:getDescriptor():getForename() or "Player")
    end
    return "Player"
end

function PSC.localIdentity(playerObj, playerNum)
    local name = PSC.username(playerObj)
    if isClient and isClient() then
        return name
    end
    playerNum = tonumber(playerNum) or 0
    if playerNum > 0 then
        return name .. " " .. tostring(playerNum + 1)
    end
    return name
end

function PSC.keyForAnchor(x, y, z)
    return "survival_cards:" .. tostring(math.floor(tonumber(x) or 0)) .. ":" ..
        tostring(math.floor(tonumber(y) or 0)) .. ":" ..
        tostring(math.floor(tonumber(z) or 0))
end

function PSC.anchorFromArgs(args)
    if not args then
        return nil
    end
    local x = tonumber(args.x)
    local y = tonumber(args.y)
    local z = tonumber(args.z)
    if not x or not y or not z then
        return nil
    end
    x = math.floor(x)
    y = math.floor(y)
    z = math.floor(z)
    return {
        x = x,
        y = y,
        z = z,
        key = PSC.keyForAnchor(x, y, z),
        source = tostring(args.source or "table"),
    }
end

function PSC.anchorFromObject(isoObject)
    if not isoObject or not isoObject.getSquare then
        return nil
    end
    local square = isoObject:getSquare()
    if not square then
        return nil
    end
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    return {
        x = x,
        y = y,
        z = z,
        key = PSC.keyForAnchor(x, y, z),
        source = "table",
    }
end

function PSC.playerNearAnchor(playerObj, anchor, maxDistance)
    if not playerObj or not anchor then
        return false
    end
    local dx = playerObj:getX() - (anchor.x or 0)
    local dy = playerObj:getY() - (anchor.y or 0)
    local dz = math.abs(playerObj:getZ() - (anchor.z or 0))
    return dz < 1 and math.sqrt(dx * dx + dy * dy) <= (tonumber(maxDistance) or PSC.MAX_PLAY_DISTANCE)
end

function PSC.sendClientCommand(playerObj, module, command, args)
    if not sendClientCommand then
        return false
    end
    local ok = pcall(function()
        sendClientCommand(playerObj, module, command, args)
    end)
    if ok then
        return true
    end
    ok = pcall(function()
        sendClientCommand(module, command, args)
    end)
    return ok
end

function PSC.findName(list, name)
    if not list or not name then
        return nil
    end
    for i = 1, #list do
        if tostring(list[i]) == tostring(name) then
            return i
        end
    end
    return nil
end

function PSC.removeName(list, name)
    local index = PSC.findName(list, name)
    if index then
        table.remove(list, index)
        return true
    end
    return false
end

function PSC.isBot(session, name)
    return session and session.bots and session.bots[tostring(name or "")] ~= nil
end

function PSC.firstBot(session)
    if not session or not session.players then
        return nil
    end
    for i = 1, #session.players do
        if PSC.isBot(session, session.players[i]) then
            return session.players[i]
        end
    end
    return nil
end

function PSC.addEvent(session, text, kind)
    if not session then
        return
    end
    session.eventSeq = (session.eventSeq or 0) + 1
    session.publicState.events = session.publicState.events or {}
    table.insert(session.publicState.events, 1, {
        id = session.eventSeq,
        text = tostring(text or ""),
        kind = tostring(kind or "info"),
    })
    while #session.publicState.events > 10 do
        table.remove(session.publicState.events)
    end
end

function PSC.legalAction(id, label, enabled, reason, args)
    return {
        id = tostring(id or ""),
        label = tostring(label or id or "Action"),
        enabled = enabled ~= false,
        disabledReason = enabled == false and tostring(reason or "Unavailable.") or nil,
        args = PSC.copy(args or {}),
    }
end

function PSC.hash(text)
    text = tostring(text or "")
    local h = 2166136261
    for i = 1, string.len(text) do
        h = ((h + string.byte(text, i)) * 16777619) % 4294967296
    end
    return h
end

local function reduceLegacyValue(owner, getterName, setterName, amount)
    if not owner or not owner[getterName] or not owner[setterName] then
        return false
    end
    local ok, current = pcall(function()
        return owner[getterName](owner)
    end)
    if not ok or current == nil then
        return false
    end
    current = tonumber(current) or 0
    local delta = current > 1 and amount or (amount / 100)
    local nextValue = math.max(0, current - delta)
    ok = pcall(function()
        owner[setterName](owner, nextValue)
    end)
    return ok and nextValue ~= current
end

function PSC.reduceCharacterStat(playerObj, statName, amount)
    amount = tonumber(amount) or 0
    if not playerObj or amount <= 0 then
        return false
    end
    local stats = playerObj.getStats and playerObj:getStats() or nil
    if CharacterStat and stats and stats.add then
        local stat = nil
        if statName == "BOREDOM" then
            stat = CharacterStat.BOREDOM
        elseif statName == "STRESS" then
            stat = CharacterStat.STRESS
        elseif statName == "UNHAPPINESS" then
            stat = CharacterStat.UNHAPPINESS
        end
        if stat then
            local ok, changed = pcall(function()
                return stats:add(stat, -amount)
            end)
            if ok then
                return changed and true or false
            end
        end
    end
    if statName == "BOREDOM" then
        return reduceLegacyValue(stats, "getBoredom", "setBoredom", amount)
    elseif statName == "STRESS" then
        return reduceLegacyValue(stats, "getStress", "setStress", amount)
    elseif statName == "UNHAPPINESS" then
        local bodyDamage = playerObj.getBodyDamage and playerObj:getBodyDamage() or nil
        return reduceLegacyValue(bodyDamage, "getUnhappynessLevel", "setUnhappynessLevel", amount)
            or reduceLegacyValue(bodyDamage, "getUnhappinessLevel", "setUnhappinessLevel", amount)
    end
    return false
end

function PSC.shuffle(list, seed)
    local result = PSC.copy(list or {})
    local state = PSC.hash(seed or "survival-cards")
    for i = #result, 2, -1 do
        state = (1103515245 * state + 12345) % 2147483648
        local j = (state % i) + 1
        result[i], result[j] = result[j], result[i]
    end
    return result
end
