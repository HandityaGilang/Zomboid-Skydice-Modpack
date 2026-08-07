PMG = PMG or {}

PMG.MODULE = "PlayableMinigames"

PMG.CMD_START = "Start"
PMG.CMD_JOIN = "Join"
PMG.CMD_WATCH = "Watch"
PMG.CMD_LEAVE = "Leave"
PMG.CMD_RESET = "Reset"
PMG.CMD_ACTION = "Action"
PMG.CMD_STATE = "State"
PMG.CMD_MESSAGE = "Message"

PMG.ACTION_ADD_BOT = "add_bot"
PMG.ACTION_REMOVE_BOT = "remove_bot"

PMG.PHASE_SETUP = "setup"
PMG.PHASE_WAITING = "waiting"
PMG.PHASE_PLAYING = "playing"
PMG.PHASE_ROUND_OVER = "round_over"
PMG.PHASE_GAME_OVER = "game_over"

PMG.EVENT_LIMIT = 12
PMG.MAX_PLAY_DISTANCE = 8
PMG.DEFAULT_MOOD_RELIEF_SCALE = 0.38
PMG.ABANDONED_SESSION_MINUTES = 30
PMG.DISCONNECTED_SESSION_GRACE_SECONDS = 20

PMG.BOT_DIFFICULTY_ORDER = { "easy", "medium", "hard" }
PMG.BOT_DIFFICULTIES = {
    easy = {
        id = "easy",
        name = "Easy",
        botName = "Easy Bot",
        skillLevel = 2,
        delayMs = 650,
        thinkingDelayMinMs = 2600,
        thinkingDelayMaxMs = 4000,
        thinkingDelayScale = 1.15,
        noise = 3.5,
        risk = 0.20,
    },
    medium = {
        id = "medium",
        name = "Medium",
        botName = "Medium Bot",
        skillLevel = 5,
        delayMs = 520,
        thinkingDelayMinMs = 2000,
        thinkingDelayMaxMs = 3250,
        thinkingDelayScale = 1.0,
        noise = 1.5,
        risk = 0.42,
    },
    hard = {
        id = "hard",
        name = "Hard",
        botName = "Hard Bot",
        skillLevel = 8,
        delayMs = 420,
        thinkingDelayMinMs = 1500,
        thinkingDelayMaxMs = 2600,
        thinkingDelayScale = 0.85,
        noise = 0.45,
        risk = 0.68,
    },
}

PMG.STATUS_BY_PHASE = {
    setup = "setup",
    waiting = "waiting",
    playing = "playing",
    round_over = "round_over",
    game_over = "game_over",
}

function PMG.clamp(value, low, high)
    value = tonumber(value) or low
    if value < low then
        return low
    end
    if value > high then
        return high
    end
    return value
end

function PMG.copyTable(value, seen)
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
        result[PMG.copyTable(key, seen)] = PMG.copyTable(child, seen)
    end
    return result
end

function PMG.shallowCopy(value)
    local result = {}
    if type(value) ~= "table" then
        return result
    end
    for key, child in pairs(value) do
        result[key] = child
    end
    return result
end

function PMG.addEvent(sessionOrState, text, kind, metadata)
    if not sessionOrState then
        return
    end
    local target = sessionOrState.publicState or sessionOrState
    target.events = target.events or {}
    if sessionOrState.publicState then
        sessionOrState.eventSeq = (sessionOrState.eventSeq or 0) + 1
        target.eventSeq = sessionOrState.eventSeq
        sessionOrState.events = target.events
    end
    local event = {
        id = sessionOrState.eventSeq,
        text = tostring(text or ""),
        kind = kind or "info",
    }
    if type(metadata) == "table" then
        for key, value in pairs(metadata) do
            if key ~= "id" and key ~= "text" and key ~= "kind" and (type(value) == "string" or type(value) == "number" or type(value) == "boolean") then
                event[key] = value
            end
        end
    end
    table.insert(target.events, 1, event)
    while #target.events > PMG.EVENT_LIMIT do
        table.remove(target.events)
    end
end

function PMG.legalAction(id, label, enabled, disabledReason, args, metadata)
    return {
        id = tostring(id or ""),
        label = tostring(label or id or "Action"),
        enabled = enabled ~= false,
        disabledReason = enabled == false and tostring(disabledReason or "Unavailable now.") or nil,
        args = PMG.copyTable(args or {}),
        metadata = PMG.copyTable(metadata or {}),
    }
end

function PMG.text(key, fallback)
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

PMG.BETA_MINIGAMES_CONFIG = "EnableBetaMinigames"
PMG.BETA_MINIGAME_WARNING = "Beta minigame: active development and may not work."
PMG.BETA_MINIGAME_DISABLED_REASON = "Beta minigames are disabled by default. Enable them in Sandbox Settings > Playable Pool to try active-development games that may not work."

function PMG.getPlayablePoolSandboxValue(name, defaultValue)
    if SandboxVars and SandboxVars.PlayablePool and SandboxVars.PlayablePool[name] ~= nil then
        return SandboxVars.PlayablePool[name]
    end
    return defaultValue
end

function PMG.toBoolean(value)
    if value == false or value == nil then
        return false
    end
    if value == true then
        return true
    end
    if value == 0 or value == "0" then
        return false
    end
    local text = string.lower(tostring(value))
    if text == "false" or text == "no" or text == "off" then
        return false
    end
    return true
end

function PMG.betaMinigamesEnabled()
    return PMG.toBoolean(PMG.getPlayablePoolSandboxValue(PMG.BETA_MINIGAMES_CONFIG, false))
end

function PMG.isBetaMinigame(gameOrId)
    local gameId = type(gameOrId) == "table" and gameOrId.id or gameOrId
    return tostring(gameId or "") ~= "" and tostring(gameId) ~= "pool"
end

function PMG.isGameAvailable(gameOrId)
    if PMG.isBetaMinigame(gameOrId) then
        return PMG.betaMinigamesEnabled()
    end
    return true
end

function PMG.betaMinigamesDisabledReason()
    return PMG.BETA_MINIGAME_DISABLED_REASON
end

function PMG.statusForPhase(phase)
    return PMG.STATUS_BY_PHASE[phase or PMG.PHASE_WAITING] or "waiting"
end

function PMG.setPhase(session, phase)
    if not session then
        return
    end
    session.phase = phase or PMG.PHASE_WAITING
    session.status = PMG.statusForPhase(session.phase)
    session.publicState = session.publicState or {}
    session.publicState.phase = session.phase
    session.publicState.status = session.status
end

function PMG.findNameIndex(list, name)
    if not list or not name then
        return nil
    end
    for i = 1, #list do
        if list[i] == name then
            return i
        end
    end
    return nil
end

function PMG.removeName(list, name)
    local index = PMG.findNameIndex(list, name)
    if index then
        table.remove(list, index)
        return true
    end
    return false
end

function PMG.getBotDifficulty(difficultyId)
    return PMG.BOT_DIFFICULTIES[difficultyId or "medium"] or PMG.BOT_DIFFICULTIES.medium
end

function PMG.isBotDifficulty(difficultyId)
    return difficultyId and PMG.BOT_DIFFICULTIES[difficultyId] ~= nil
end

function PMG.isBotPlayer(session, playerName)
    return session and playerName and session.bots and session.bots[playerName] ~= nil
end

function PMG.botCount(session)
    local count = 0
    for _ in pairs(session and session.bots or {}) do
        count = count + 1
    end
    return count
end

function PMG.humanPlayerCount(session)
    local count = 0
    for i = 1, #(session and session.players or {}) do
        if not PMG.isBotPlayer(session, session.players[i]) then
            count = count + 1
        end
    end
    return count
end

function PMG.firstBotName(session)
    for i = 1, #(session and session.players or {}) do
        local name = session.players[i]
        if PMG.isBotPlayer(session, name) then
            return name
        end
    end
    return nil
end

function PMG.botNameFor(game, difficulty, session)
    difficulty = difficulty or PMG.getBotDifficulty("medium")
    local baseName = tostring((game and game.botName) or difficulty.botName or "Bot")
    local candidate = baseName
    local index = 2
    while PMG.findNameIndex(session and session.players or {}, candidate) or PMG.findNameIndex(session and session.spectators or {}, candidate) do
        candidate = baseName .. " " .. tostring(index)
        index = index + 1
    end
    return candidate
end

function PMG.botLegalActions(game, session, viewerName)
    local actions = {}
    if not game or not game.supportsBots or not session then
        return actions
    end
    if not PMG.findNameIndex(session.players or {}, viewerName) or PMG.isBotPlayer(session, viewerName) then
        return actions
    end
    if session.phase == PMG.PHASE_GAME_OVER then
        return actions
    end
    local _, maxPlayers = PMG_Registry.requiredPlayerCount(game)
    local botName = PMG.firstBotName(session)
    if botName then
        table.insert(actions, PMG.legalAction(PMG.ACTION_REMOVE_BOT, PMG.text("IGUI_PlayableMinigames_ActionRemoveBot", "Remove Bot"), true, nil, { botName = botName }, { bot = true }))
    end
    if #(session.players or {}) < maxPlayers then
        for i = 1, #(PMG.BOT_DIFFICULTY_ORDER or {}) do
            local difficulty = PMG.getBotDifficulty(PMG.BOT_DIFFICULTY_ORDER[i])
            table.insert(actions, PMG.legalAction(
                PMG.ACTION_ADD_BOT,
                PMG.text("IGUI_PlayableMinigames_ActionAddBot_" .. difficulty.id, "Add " .. difficulty.name .. " Bot"),
                true,
                nil,
                { difficulty = difficulty.id },
                { bot = true, difficulty = difficulty.id }
            ))
        end
    elseif not botName then
        table.insert(actions, PMG.legalAction(PMG.ACTION_ADD_BOT, PMG.text("IGUI_PlayableMinigames_ActionAddBot", "Add Bot"), false, PMG.text("IGUI_PlayableMinigames_GameFull", "This game is full."), { difficulty = "medium" }, { bot = true }))
    end
    return actions
end

function PMG.currentPlayerName(session)
    if not session or not session.players or #session.players == 0 then
        return nil
    end
    local index = PMG.clamp(session.currentPlayer or 1, 1, #session.players)
    return session.players[index]
end

function PMG.advanceTurn(session)
    if not session or not session.players or #session.players == 0 then
        return nil
    end
    session.currentPlayer = (session.currentPlayer or 1) + 1
    if session.currentPlayer > #session.players then
        session.currentPlayer = 1
    end
    session.publicState = session.publicState or {}
    session.publicState.currentPlayer = session.currentPlayer
    session.publicState.currentPlayerName = PMG.currentPlayerName(session)
    return session.publicState.currentPlayerName
end

function PMG.keyForAnchor(gameId, x, y, z)
    return tostring(gameId or "game") .. ":" ..
        tostring(math.floor(tonumber(x) or 0)) .. ":" ..
        tostring(math.floor(tonumber(y) or 0)) .. ":" ..
        tostring(math.floor(tonumber(z) or 0))
end

function PMG.getUsername(playerObj)
    if not playerObj then
        return "Unknown"
    end
    if playerObj.getUsername then
        local ok, name = pcall(function()
            return playerObj:getUsername()
        end)
        if ok and name and name ~= "" then
            return tostring(name)
        end
    end
    if playerObj.getDisplayName then
        local ok, name = pcall(function()
            return playerObj:getDisplayName()
        end)
        if ok and name and name ~= "" then
            return tostring(name)
        end
    end
    return "Player"
end

function PMG.localPlayerIdentity(playerObj, playerNum)
    local name = PMG.getUsername(playerObj)
    playerNum = tonumber(playerNum)
    if playerNum and playerNum > 0 then
        return tostring(name) .. " P" .. tostring(math.floor(playerNum) + 1)
    end
    return name
end

function PMG.getSpriteName(isoObject)
    if not isoObject or not isoObject.getSprite then
        return nil
    end
    local ok, sprite = pcall(function()
        return isoObject:getSprite()
    end)
    if not ok or not sprite or not sprite.getName then
        return nil
    end
    ok, sprite = pcall(function()
        return sprite:getName()
    end)
    if ok then
        return sprite
    end
    return nil
end

function PMG.getObjectProperty(isoObject, name)
    if not isoObject or not isoObject.getProperties then
        return nil
    end
    local ok, props = pcall(function()
        return isoObject:getProperties()
    end)
    if not ok or not props or not props.get then
        return nil
    end
    ok, props = pcall(function()
        return props:get(name)
    end)
    if ok then
        return props
    end
    return nil
end

function PMG.hasInventoryItem(playerObj, fullType, minimum)
    minimum = tonumber(minimum) or 1
    if not playerObj or not fullType or not playerObj.getInventory then
        return false, 0
    end
    local inv = playerObj:getInventory()
    if not inv then
        return false, 0
    end
    local shortType = tostring(fullType):gsub("^Base%.", "")
    local count = 0
    if inv.getCountType then
        local ok, value = pcall(function()
            return inv:getCountType(shortType)
        end)
        if ok and value then
            count = tonumber(value) or 0
        end
    end
    if count < minimum and inv.getItems then
        local ok, items = pcall(function()
            return inv:getItems()
        end)
        if ok and items then
            count = 0
            for i = 0, items:size() - 1 do
                local item = items:get(i)
                local itemType = nil
                if item and item.getFullType then
                    itemType = item:getFullType()
                end
                if itemType == fullType or itemType == shortType or itemType == ("Base." .. shortType) then
                    count = count + 1
                end
            end
        end
    end
    return count >= minimum, count
end

function PMG.sendClientCommand(playerObj, module, command, args)
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

function PMG.addXp(playerObj, perk, amount)
    amount = math.floor(tonumber(amount) or 0)
    if not playerObj or not perk or amount <= 0 or not playerObj.getXp then
        return false
    end
    local xp = playerObj:getXp()
    if not xp or not xp.AddXP then
        return false
    end
    local ok = pcall(function()
        xp:AddXP(perk, amount, false, false, false, false)
    end)
    if ok then
        return true
    end
    ok = pcall(function()
        xp:AddXP(perk, amount)
    end)
    return ok
end

function PMG.itemMatchesFullType(item, fullType)
    if not item or not fullType or not item.getFullType then
        return false
    end
    local ok, itemType = pcall(function()
        return item:getFullType()
    end)
    if not ok or not itemType then
        return false
    end
    local shortType = tostring(fullType):gsub("^Base%.", "")
    itemType = tostring(itemType)
    return itemType == fullType or itemType == shortType or itemType == ("Base." .. shortType)
end

function PMG.getWorldInventoryItem(worldObject)
    if not worldObject or not worldObject.getItem then
        return nil
    end
    local ok, item = pcall(function()
        return worldObject:getItem()
    end)
    if ok then
        return item
    end
    return nil
end

function PMG.isWorldInventoryItemType(worldObject, fullType)
    return PMG.itemMatchesFullType(PMG.getWorldInventoryItem(worldObject), fullType)
end

function PMG.playerNearAnchor(playerObj, anchor, maxDistance)
    if not playerObj or not anchor then
        return false
    end
    local dx = playerObj:getX() - (anchor.x or 0)
    local dy = playerObj:getY() - (anchor.y or 0)
    local dz = math.abs(playerObj:getZ() - (anchor.z or 0))
    return dz < 1 and math.sqrt(dx * dx + dy * dy) <= (tonumber(maxDistance) or PMG.MAX_PLAY_DISTANCE)
end

function PMG.createSession(game, anchor, ownerName, options)
    options = options or {}
    local key = anchor.key or PMG.keyForAnchor(game.id, anchor.x, anchor.y, anchor.z)
    local session = {
        version = 1,
        key = key,
        gameId = game.id,
        anchor = PMG.copyTable(anchor),
        owner = ownerName,
        players = { ownerName },
        spectators = {},
        bots = {},
        currentPlayer = 1,
        phase = PMG.PHASE_WAITING,
        status = PMG.statusForPhase(PMG.PHASE_WAITING),
        publicState = {},
        privateState = {},
        events = {},
        seed = options.seed or (tostring(key) .. ":" .. tostring(options.now or 0)),
        touched = options.now or 0,
    }
    if game.createInitialState then
        game.createInitialState(session, ownerName, options)
    end
    session.publicState = session.publicState or {}
    session.privateState = session.privateState or {}
    session.publicState.events = session.events
    session.publicState.gameId = game.id
    session.publicState.gameName = game.name
    session.publicState.anchor = PMG.copyTable(anchor)
    session.publicState.players = PMG.copyTable(session.players)
    session.publicState.spectators = PMG.copyTable(session.spectators)
    session.publicState.bots = PMG.copyTable(session.bots)
    session.publicState.currentPlayer = session.currentPlayer
    session.publicState.currentPlayerName = PMG.currentPlayerName(session)
    PMG.setPhase(session, session.phase or PMG.PHASE_WAITING)
    PMG.addEvent(session, tostring(ownerName or "Player") .. " started " .. tostring(game.name or "a game") .. ".", "join")
    return session
end

function PMG.redactedState(game, session, viewerName)
    if not session then
        return nil
    end
    local payload = {
        key = session.key,
        gameId = session.gameId,
        anchor = PMG.copyTable(session.anchor),
        owner = session.owner,
        players = PMG.copyTable(session.players or {}),
        spectators = PMG.copyTable(session.spectators or {}),
        currentPlayer = session.currentPlayer,
        currentPlayerName = PMG.currentPlayerName(session),
        phase = session.phase,
        status = session.status,
        publicState = PMG.copyTable(session.publicState or {}),
        events = PMG.copyTable((session.publicState or {}).events or {}),
        viewerName = viewerName,
    }
    if game and game.legalActions then
        payload.legalActions = game.legalActions(session, viewerName) or {}
    end
    local botActions = PMG.botLegalActions(game, session, viewerName)
    if #botActions > 0 then
        local gameplayActions = payload.legalActions or {}
        payload.legalActions = {}
        for i = 1, #botActions do
            table.insert(payload.legalActions, botActions[i])
        end
        for i = 1, #gameplayActions do
            table.insert(payload.legalActions, gameplayActions[i])
        end
    end
    if game and game.redactState then
        game.redactState(session, payload, viewerName)
    end
    return payload
end
