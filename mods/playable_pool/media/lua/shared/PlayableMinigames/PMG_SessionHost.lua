require "PlayableMinigames/PMG_Core"
require "PlayableMinigames/PMG_Registry"
require "PlayableMinigames/PMG_Anchors"
require "PlayableMinigames/PMG_Random"

PMG_SessionHost = PMG_SessionHost or {}

local Host = {}
Host.__index = Host

local function nowMs()
    if getTimestampMs then
        return getTimestampMs()
    end
    return math.floor(os.time() * 1000)
end

function PMG_SessionHost.new(env)
    env = env or {}
    return setmetatable({
        sessions = {},
        env = env,
        tickCounter = 0,
    }, Host)
end

function Host:authenticatedPlayerName(playerObj, args)
    if self.env and self.env.authenticatedPlayerName then
        local name = self.env.authenticatedPlayerName(playerObj, args or {})
        if name and name ~= "" then
            return tostring(name)
        end
    end
    return PMG.getUsername(playerObj)
end

function Host:touch(session)
    if session then
        session.touched = self:now()
    end
end

function Host:now()
    if self.env and self.env.now then
        return self.env.now()
    end
    return nowMs()
end

function Host:message(playerObj, text)
    if self.env and self.env.message then
        self.env.message(playerObj, tostring(text or "Minigame is not available."))
    end
end

function Host:presentationDelayMs(game, session)
    if not game or not game.presentationDelayMs then
        return 0
    end
    local ok, value = pcall(function()
        return game.presentationDelayMs(session)
    end)
    if not ok then
        return 0
    end
    return math.max(0, tonumber(value) or 0)
end

function Host:deferBotsForPresentation(session, game, now, baseDelayMs)
    if not session then
        return
    end
    local delayMs = math.max(tonumber(baseDelayMs) or 0, self:presentationDelayMs(game, session))
    if delayMs <= 0 then
        return
    end
    local readyAt = (tonumber(now) or self:now()) + delayMs
    session.botBusyUntil = math.max(tonumber(session.botBusyUntil) or 0, readyAt)
end

function Host:botTurnKey(game, session, botName)
    if game and game.botTurnKey then
        local ok, value = pcall(function()
            return game.botTurnKey(session, botName)
        end)
        if ok and value ~= nil and value ~= "" then
            return tostring(value)
        end
    end
    local public = session and session.publicState or {}
    return table.concat({
        tostring(session and session.gameId or ""),
        tostring(session and session.phase or ""),
        tostring(botName or ""),
        tostring(session and session.currentPlayer or ""),
        tostring(public.currentPlayerName or ""),
        tostring(session and session.eventSeq or 0),
    }, ":")
end

function Host:botThinkingDelayMs(difficulty, session, botName, turnKey)
    difficulty = difficulty or PMG.getBotDifficulty("medium")
    local game = session and PMG_Registry.get(session.gameId) or nil
    local range = game and game.botThinkingDelay or nil
    if game and game.botThinkingDelayRange then
        local ok, value = pcall(function()
            return game.botThinkingDelayRange(session, botName, difficulty, turnKey)
        end)
        if ok and type(value) == "table" then
            range = value
        end
    end

    local minDelay = tonumber(range and (range.minMs or range.minDelayMs)) or tonumber(difficulty.thinkingDelayMinMs) or 3000
    local maxDelay = tonumber(range and (range.maxMs or range.maxDelayMs)) or tonumber(difficulty.thinkingDelayMaxMs) or minDelay
    local scale = tonumber(difficulty.thinkingDelayScale) or 1
    minDelay = minDelay * scale
    maxDelay = maxDelay * scale
    if maxDelay < minDelay then
        minDelay, maxDelay = maxDelay, minDelay
    end
    minDelay = PMG.clamp(math.floor(minDelay), 750, 8000)
    maxDelay = PMG.clamp(math.floor(maxDelay), minDelay, 8000)
    if maxDelay == minDelay then
        return minDelay
    end
    local seed = tostring(session and session.seed or "") .. ":" .. tostring(botName or "") .. ":" .. tostring(turnKey or "")
    return minDelay + (PMG_Random.hash(seed) % (maxDelay - minDelay + 1))
end

function Host:waitForBotTurn(session, game, botName, difficulty, now)
    local turnKey = self:botTurnKey(game, session, botName)
    local pending = session.pendingBotTurn
    if not pending or pending.key ~= turnKey or pending.playerName ~= botName then
        local delayMs = self:botThinkingDelayMs(difficulty, session, botName, turnKey)
        local readyAt = now + delayMs
        session.pendingBotTurn = {
            key = turnKey,
            playerName = botName,
            readyAt = readyAt,
        }
        session.botBusyUntil = math.max(tonumber(session.botBusyUntil) or 0, readyAt)
        return false
    end
    if now < (tonumber(pending.readyAt) or now) then
        session.botBusyUntil = math.max(tonumber(session.botBusyUntil) or 0, tonumber(pending.readyAt) or now)
        return false
    end
    session.pendingBotTurn = nil
    session.botBusyUntil = nil
    return true
end

function Host:sendState(playerObj, game, session, viewerName)
    if self.env and self.env.sendState then
        self.env.sendState(playerObj, PMG.redactedState(game, session, viewerName))
    end
end

function Host:broadcast(session)
    if not session then
        return
    end
    local game = PMG_Registry.get(session.gameId)
    if not game then
        return
    end
    if self.env and self.env.findPlayerByName then
        for i = 1, #(session.players or {}) do
            local name = session.players[i]
            self:sendState(self.env.findPlayerByName(name), game, session, name)
        end
        for i = 1, #(session.spectators or {}) do
            local name = session.spectators[i]
            self:sendState(self.env.findPlayerByName(name), game, session, name)
        end
    elseif self.env and self.env.localBroadcastState then
        self.env.localBroadcastState(game, session)
    end
end

function Host:abandonedTimeoutMs()
    if self.env and self.env.abandonedTimeoutMs then
        local value = tonumber(self.env.abandonedTimeoutMs())
        if value and value > 0 then
            return value
        end
    end
    return (PMG.ABANDONED_SESSION_MINUTES or 30) * 60 * 1000
end

function Host:disconnectedGraceMs()
    if self.env and self.env.disconnectedGraceMs then
        local value = tonumber(self.env.disconnectedGraceMs())
        if value and value > 0 then
            return value
        end
    end
    return (PMG.DISCONNECTED_SESSION_GRACE_SECONDS or 20) * 1000
end

function Host:sessionHasPresentViewer(session)
    if not session or not self.env or not self.env.onlineNameSet then
        return true
    end
    local online = self.env.onlineNameSet() or {}
    for i = 1, #(session.players or {}) do
        if online[session.players[i]] then
            return true
        end
    end
    for i = 1, #(session.spectators or {}) do
        if online[session.spectators[i]] then
            return true
        end
    end
    return false
end

function Host:refreshPublicPlayers(session)
    if not session then
        return
    end
    session.publicState = session.publicState or {}
    session.publicState.players = PMG.copyTable(session.players or {})
    session.publicState.spectators = PMG.copyTable(session.spectators or {})
    session.publicState.bots = PMG.copyTable(session.bots or {})
    session.publicState.currentPlayer = session.currentPlayer
    session.publicState.currentPlayerName = PMG.currentPlayerName(session)
end

function Host:humanSeatCount(session)
    return PMG.humanPlayerCount(session)
end

function Host:removeOneBot(session, game, reason)
    local botName = PMG.firstBotName(session)
    if not botName then
        return false
    end
    return self:removeBot(session, game, botName, reason)
end

function Host:addBot(session, game, difficultyId, addedBy)
    if not session or not game or not game.supportsBots then
        return false, "This minigame does not support bots."
    end
    local _, maxPlayers = PMG_Registry.requiredPlayerCount(game)
    if #(session.players or {}) >= maxPlayers then
        return false, "This game is full."
    end
    local difficulty = PMG.getBotDifficulty(difficultyId)
    local botName = PMG.botNameFor(game, difficulty, session)
    session.bots = session.bots or {}
    session.bots[botName] = {
        difficulty = difficulty.id,
        addedBy = addedBy,
    }
    table.insert(session.players, botName)
    PMG.removeName(session.spectators, botName)
    if game.onPlayerJoined then
        game.onPlayerJoined(session, botName)
    end
    self:refreshPublicPlayers(session)
    local minPlayers = PMG_Registry.requiredPlayerCount(game)
    if #session.players >= minPlayers and session.phase == PMG.PHASE_WAITING then
        PMG.setPhase(session, PMG.PHASE_PLAYING)
    end
    PMG.addEvent(session, botName .. " joined as a " .. difficulty.name .. " bot.", "join")
    session.pendingBotTurn = nil
    session.botBusyUntil = self:now() + (difficulty.delayMs or 650)
    return true
end

function Host:removeBot(session, game, botName, reason)
    if not session or not botName or not PMG.isBotPlayer(session, botName) then
        return false, "There is no bot to remove."
    end
    session.bots[botName] = nil
    PMG.removeName(session.players, botName)
    PMG.removeName(session.spectators, botName)
    if game and game.onPlayerLeft then
        game.onPlayerLeft(session, botName)
    end
    if #(session.players or {}) == 0 or self:humanSeatCount(session) == 0 then
        self:endSession(session, reason or "The minigame ended because no human players remain.", "end")
        return true
    end
    if session.currentPlayer > #session.players then
        session.currentPlayer = 1
    end
    if tostring(session.owner or "") == tostring(botName) then
        session.owner = session.players[1]
    end
    session.pendingBotTurn = nil
    session.botBusyUntil = nil
    self:refreshPublicPlayers(session)
    PMG.addEvent(session, reason or (botName .. " left the game."), "leave")
    return true
end

function Host:endSession(session, reason, kind)
    if not session then
        return
    end
    reason = tostring(reason or "Minigame session ended.")
    PMG.setPhase(session, PMG.PHASE_GAME_OVER)
    session.pendingBotTurn = nil
    session.botBusyUntil = nil
    session.publicState.endReason = reason
    session.publicState.endedAt = self:now()
    PMG.addEvent(session, reason, kind or "end")
    self:broadcast(session)
    self.sessions[session.key] = nil
end

function Host:awardActionReward(playerObj, game, session, playerName, action, args)
    if not game or not game.rewardForAction or not self.env or not self.env.rewardPlayer then
        return
    end
    local reward = game.rewardForAction(session, playerName, action, args or {}) or nil
    if not reward or not reward.skillId or not reward.xp then
        return
    end
    session.rewardTotals = session.rewardTotals or {}
    session.rewardTotals[playerName] = session.rewardTotals[playerName] or {}
    local cap = tonumber(reward.sessionCap) or 250
    local current = tonumber(session.rewardTotals[playerName][reward.skillId]) or 0
    if current >= cap then
        return
    end
    local amount = math.min(math.floor(tonumber(reward.xp) or 0), cap - current)
    if amount <= 0 then
        return
    end
    if self.env.rewardPlayer(playerObj, reward.skillId, amount, reward) then
        session.rewardTotals[playerName][reward.skillId] = current + amount
    end
end

function Host:validateCreateSession(playerObj, game, anchor, options)
    if not game then
        return false, "Unknown minigame."
    end
    if not PMG.isGameAvailable(game) then
        return false, PMG.betaMinigamesDisabledReason()
    end
    if not anchor then
        return false, "No valid game surface."
    end
    if not PMG.playerNearAnchor(playerObj, anchor, game.maxDistance or PMG.MAX_PLAY_DISTANCE) then
        return false, "Move closer to start this game."
    end
    if self.env and self.env.validateWorldAnchor then
        local ok = self.env.validateWorldAnchor(game.id, anchor)
        if not ok then
            return false, "That world object is no longer available."
        end
    end
    local ok, reason = PMG_Registry.canStart(game, playerObj, anchor, options)
    if not ok then
        return ok, reason
    end
    local equipmentKey = self:equipmentKeyFor(game, anchor)
    if equipmentKey and self:equipmentInUse(equipmentKey) then
        return false, "That deck or table is already in use."
    end
    return true
end

function Host:equipmentKeyFor(game, anchor)
    if not game or not game.equipmentKind then
        return nil
    end
    return PMG_Anchors.equipmentKeyForAnchor(game.equipmentKind, anchor)
end

function Host:equipmentInUse(equipmentKey)
    if not equipmentKey then
        return false
    end
    for _, session in pairs(self.sessions or {}) do
        if session.equipment and session.equipment.key == equipmentKey then
            return true
        end
    end
    return false
end

function Host:validateExistingSession(playerObj, game, anchor, session, actionName)
    actionName = tostring(actionName or "use")
    if not game then
        return false, "Unknown minigame."
    end
    if not PMG.isGameAvailable(game) then
        return false, PMG.betaMinigamesDisabledReason()
    end
    if not anchor then
        return false, "No valid game surface."
    end
    if not session then
        return false, "There is no active minigame to " .. actionName .. "."
    end
    if not PMG.playerNearAnchor(playerObj, anchor, game.maxDistance or PMG.MAX_PLAY_DISTANCE) then
        return false, "Move closer to " .. actionName .. " this game."
    end
    if self.env and self.env.validateWorldAnchor then
        local ok = self.env.validateWorldAnchor(game.id, anchor)
        if not ok then
            return false, "That world object is no longer available."
        end
    end
    return true
end

function Host:validateJoinSession(playerObj, game, anchor, session)
    return self:validateExistingSession(playerObj, game, anchor, session, "join")
end

function Host:validateWatchSession(playerObj, game, anchor, session)
    return self:validateExistingSession(playerObj, game, anchor, session, "watch")
end

function Host:getSession(key)
    return self.sessions[key]
end

function Host:ensureSession(playerObj, args)
    local anchor = PMG_Anchors.anchorFromArgs(args)
    local game = anchor and PMG_Registry.get(anchor.gameId) or nil
    local name = self:authenticatedPlayerName(playerObj, args)
    local ok, reason = self:validateCreateSession(playerObj, game, anchor, args or {})
    if not ok then
        return nil, nil, name, reason
    end
    local session = self.sessions[anchor.key]
    if not session then
        session = PMG.createSession(game, anchor, name, {
            now = self:now(),
            seed = tostring(anchor.key) .. ":" .. tostring(self:now()),
            args = args or {},
        })
        self.sessions[anchor.key] = session
        local equipmentKey = self:equipmentKeyFor(game, anchor)
        if equipmentKey then
            session.equipment = {
                key = equipmentKey,
                kind = game.equipmentKind,
                source = "anchor",
            }
            session.publicState.equipment = PMG.copyTable(session.equipment)
        end
    end
    self:touch(session)
    return session, game, name, nil
end

function Host:findExistingSession(playerObj, args, validator)
    local anchor = PMG_Anchors.anchorFromArgs(args)
    local session = anchor and self.sessions[anchor.key] or nil
    local game = session and PMG_Registry.get(session.gameId) or (anchor and PMG_Registry.get(anchor.gameId) or nil)
    local name = self:authenticatedPlayerName(playerObj, args)
    local ok, reason = validator(self, playerObj, game, anchor, session)
    if not ok then
        return nil, nil, name, reason
    end
    self:touch(session)
    return session, game, name, nil
end

function Host:canJoinAsPlayer(playerObj, game, anchor, session, name)
    if not game or not session then
        return false, "Unknown minigame."
    end
    if PMG.findNameIndex(session.players or {}, name) then
        return true
    end
    if game.canJoin then
        return game.canJoin(playerObj, anchor, session)
    end
    return true
end

function Host:handleStartExisting(playerObj, args, anchor, session, game, name)
    local ok, reason = self:validateExistingSession(playerObj, game, anchor, session, "play or watch")
    if not ok then
        self:message(playerObj, reason)
        return
    end
    self:touch(session)

    local joinedAsPlayer = PMG.findNameIndex(session.players or {}, name) ~= nil
    if not joinedAsPlayer then
        local canJoin = self:canJoinAsPlayer(playerObj, game, anchor, session, name)
        if canJoin then
            local added = self:addPlayer(session, game, name)
            joinedAsPlayer = added == true or PMG.findNameIndex(session.players or {}, name) ~= nil
        end
    end
    if not joinedAsPlayer then
        self:addSpectator(session, game, name)
    end

    self:sendState(playerObj, game, session, name)
    self:broadcast(session)
end

function Host:addPlayer(session, game, name)
    if PMG.findNameIndex(session.players, name) then
        return true
    end
    local _, maxPlayers = PMG_Registry.requiredPlayerCount(game)
    if #session.players >= maxPlayers then
        if game and game.supportsBots and self:removeOneBot(session, game, "A bot gave up its seat for " .. tostring(name) .. ".") then
            -- Seat replacement succeeded; continue adding the human player.
        else
            return false, "This game is full."
        end
    end
    PMG.removeName(session.spectators, name)
    table.insert(session.players, name)
    if game.onPlayerJoined then
        game.onPlayerJoined(session, name)
    end
    self:refreshPublicPlayers(session)
    local minPlayers = PMG_Registry.requiredPlayerCount(game)
    if #session.players >= minPlayers and session.phase == PMG.PHASE_WAITING then
        PMG.setPhase(session, PMG.PHASE_PLAYING)
    end
    PMG.addEvent(session, name .. " joined " .. tostring(game.name or "the game") .. ".", "join")
    return true
end

function Host:addSpectator(session, game, name)
    if PMG.findNameIndex(session.players, name) or PMG.findNameIndex(session.spectators, name) then
        return true
    end
    table.insert(session.spectators, name)
    self:refreshPublicPlayers(session)
    PMG.addEvent(session, name .. " is watching " .. tostring(game.name or "the game") .. ".", "watch")
    return true
end

function Host:handleStart(playerObj, args)
    local anchor = PMG_Anchors.anchorFromArgs(args)
    local existing = anchor and self.sessions[anchor.key] or nil
    if existing then
        local game = PMG_Registry.get(existing.gameId)
        local name = self:authenticatedPlayerName(playerObj, args)
        self:handleStartExisting(playerObj, args, anchor, existing, game, name)
        return
    end

    local session, game, name, reason = self:ensureSession(playerObj, args)
    if not session then
        self:message(playerObj, reason)
        return
    end
    local ok, addReason = self:addPlayer(session, game, name)
    if not ok then
        self:message(playerObj, addReason)
    end
    self:sendState(playerObj, game, session, name)
    self:broadcast(session)
end

function Host:handleJoin(playerObj, args)
    local session, game, name, reason = self:findExistingSession(playerObj, args, Host.validateJoinSession)
    if not session then
        self:message(playerObj, reason)
        return
    end
    local canJoin, joinReason = self:canJoinAsPlayer(playerObj, game, session.anchor, session, name)
    if not canJoin then
        self:message(playerObj, joinReason or "You can watch this minigame, but cannot join as a player.")
        self:sendState(playerObj, game, session, name)
        return
    end
    local ok, addReason = self:addPlayer(session, game, name)
    if not ok then
        self:message(playerObj, addReason)
    end
    self:sendState(playerObj, game, session, name)
    self:broadcast(session)
end

function Host:handleWatch(playerObj, args)
    local session, game, name, reason = self:findExistingSession(playerObj, args, Host.validateWatchSession)
    if not session then
        self:message(playerObj, reason)
        return
    end
    self:addSpectator(session, game, name)
    self:sendState(playerObj, game, session, name)
    self:broadcast(session)
end

function Host:handleLeave(playerObj, args)
    local anchor = PMG_Anchors.anchorFromArgs(args)
    local name = self:authenticatedPlayerName(playerObj, args)
    local session = anchor and self.sessions[anchor.key] or nil
    local game = session and PMG_Registry.get(session.gameId) or nil
    if not session then
        return
    end
    local wasPlayer = PMG.removeName(session.players, name)
    PMG.removeName(session.spectators, name)
    if wasPlayer and game and game.onPlayerLeft then
        game.onPlayerLeft(session, name)
    end
    if #session.players == 0 or self:humanSeatCount(session) == 0 then
        local reason = wasPlayer and (name .. " left; the minigame ended.") or "The minigame ended."
        self:endSession(session, reason, wasPlayer and "forfeit" or "end")
        return
    end
    if tostring(session.owner or "") == tostring(name) then
        session.owner = session.players[1]
        PMG.addEvent(session, tostring(session.owner) .. " is now the table owner.", "join")
    end
    if session.currentPlayer > #session.players then
        session.currentPlayer = 1
    end
    self:refreshPublicPlayers(session)
    PMG.addEvent(session, name .. " left the game.", "leave")
    self:broadcast(session)
end

function Host:handleReset(playerObj, args)
    local anchor = PMG_Anchors.anchorFromArgs(args)
    local game = anchor and PMG_Registry.get(anchor.gameId) or nil
    local old = anchor and self.sessions[anchor.key] or nil
    if not old or not game then
        return
    end
    local name = self:authenticatedPlayerName(playerObj, args)
    if not PMG.findNameIndex(old.players, name) then
        self:message(playerObj, "Join the game before resetting it.")
        return
    end
    local ownerName = old.owner or old.players[1] or name
    if tostring(ownerName) ~= tostring(name) then
        self:message(playerObj, "Only the table owner can reset this game.")
        return
    end
    local session = PMG.createSession(game, anchor, ownerName, {
        now = self:now(),
        seed = tostring(anchor.key) .. ":" .. tostring(self:now()),
        args = args or {},
    })
    session.players = PMG.copyTable(old.players)
    session.spectators = PMG.copyTable(old.spectators)
    session.bots = PMG.copyTable(old.bots)
    session.equipment = PMG.copyTable(old.equipment)
    session.publicState.equipment = PMG.copyTable(session.equipment)
    if game.onPlayerJoined then
        for i = 1, #session.players do
            local playerName = session.players[i]
            if playerName ~= ownerName then
                game.onPlayerJoined(session, playerName)
            end
        end
    end
    session.currentPlayer = 1
    self:refreshPublicPlayers(session)
    self.sessions[anchor.key] = session
    PMG.addEvent(session, name .. " reset the game.", "reset")
    self:broadcast(session)
end

function Host:handleAction(playerObj, args)
    local anchor = PMG_Anchors.anchorFromArgs(args)
    local session = anchor and self.sessions[anchor.key] or nil
    local game = session and PMG_Registry.get(session.gameId) or nil
    local name = self:authenticatedPlayerName(playerObj, args)
    if not session or not game then
        self:message(playerObj, "This minigame session is not active.")
        return
    end
    if not PMG.findNameIndex(session.players, name) then
        self:message(playerObj, "Join the game before taking actions.")
        return
    end
    self:touch(session)
    if args.action == PMG.ACTION_ADD_BOT then
        local ok, reason = self:addBot(session, game, args.difficulty, name)
        if not ok then
            self:message(playerObj, reason or "Could not add a bot.")
            self:sendState(playerObj, game, session, name)
            return
        end
        self:broadcast(session)
        return
    elseif args.action == PMG.ACTION_REMOVE_BOT then
        local ok, reason = self:removeBot(session, game, args.botName or PMG.firstBotName(session), "Bot removed by " .. tostring(name) .. ".")
        if not ok then
            self:message(playerObj, reason or "Could not remove a bot.")
            self:sendState(playerObj, game, session, name)
            return
        end
        self:broadcast(session)
        return
    end
    local actionNow = self:now()
    local ok, reason = game.applyAction(session, name, tostring(args.action or ""), args or {}, {
        playerObj = playerObj,
        host = self,
        now = actionNow,
    })
    if not ok then
        self:message(playerObj, reason or "That action is not legal now.")
        self:sendState(playerObj, game, session, name)
        return
    end
    self:deferBotsForPresentation(session, game, actionNow, 0)
    self:awardActionReward(playerObj, game, session, name, tostring(args.action or ""), args or {})
    self:broadcast(session)
end

function Host:updateBot(session, game, now)
    if not session or not game or not game.supportsBots or not game.botPlayerToAct or not game.botAction then
        return
    end
    if session.phase == PMG.PHASE_GAME_OVER then
        session.pendingBotTurn = nil
        session.botBusyUntil = nil
        return
    end
    if session.botBusyUntil and now < session.botBusyUntil then
        return
    end
    local botName = game.botPlayerToAct(session)
    if not PMG.isBotPlayer(session, botName) then
        session.pendingBotTurn = nil
        session.botBusyUntil = nil
        return
    end
    local bot = session.bots[botName] or {}
    local difficulty = PMG.getBotDifficulty(bot.difficulty)
    if not self:waitForBotTurn(session, game, botName, difficulty, now) then
        return
    end
    local action, actionArgs = game.botAction(session, botName, difficulty, {
        host = self,
        now = now,
        bot = bot,
    })
    if not action then
        session.botBusyUntil = now + (difficulty.delayMs or 650)
        return
    end
    actionArgs = actionArgs or {}
    local ok, reason = game.applyAction(session, botName, tostring(action), actionArgs, {
        host = self,
        now = now,
        bot = true,
        difficulty = difficulty,
        skillLevel = difficulty.skillLevel or 5,
    })
    if ok then
        self:deferBotsForPresentation(session, game, now, difficulty.delayMs or 650)
        self:broadcast(session)
    else
        session.botBusyUntil = now + math.max(1000, (difficulty.delayMs or 650) * 2)
        PMG.addEvent(session, tostring(botName) .. " could not act: " .. tostring(reason or "no legal action") .. ".", "info")
        self:broadcast(session)
    end
end

function Host:handleCommand(playerObj, command, args)
    args = args or {}
    if command == PMG.CMD_START then
        self:handleStart(playerObj, args)
    elseif command == PMG.CMD_JOIN then
        self:handleJoin(playerObj, args)
    elseif command == PMG.CMD_WATCH then
        self:handleWatch(playerObj, args)
    elseif command == PMG.CMD_LEAVE then
        self:handleLeave(playerObj, args)
    elseif command == PMG.CMD_RESET then
        self:handleReset(playerObj, args)
    elseif command == PMG.CMD_ACTION then
        self:handleAction(playerObj, args)
    end
end

function Host:onTick()
    self.tickCounter = (self.tickCounter or 0) + 1
    for _, session in pairs(self.sessions) do
        local game = PMG_Registry.get(session.gameId)
        if game then
            self:updateBot(session, game, self:now())
        end
        if game and self.env and self.env.onTickGame then
            self.env.onTickGame(game, session, self)
        end
    end
    if self.tickCounter % 150 == 0 then
        self:cleanupSessions()
    end
end

function Host:cleanupSessions()
    local now = self:now()
    local timeoutMs = self:abandonedTimeoutMs()
    local disconnectedGraceMs = self:disconnectedGraceMs()
    for key, session in pairs(self.sessions) do
        local playerCount = #(session.players or {})
        local idleMs = now - (session.touched or now)
        if playerCount == 0 then
            self:endSession(session, "Minigame session ended because no players remain.", "end")
        elseif idleMs >= disconnectedGraceMs and not self:sessionHasPresentViewer(session) then
            self:endSession(session, "Minigame session ended because all players left or disconnected.", "abandoned")
        elseif idleMs >= timeoutMs and not self:sessionHasPresentViewer(session) then
            self:endSession(session, "Minigame session ended because all players left or disconnected.", "abandoned")
        elseif idleMs >= timeoutMs * 4 then
            self:endSession(session, "Minigame session ended after a long period of inactivity.", "abandoned")
        else
            self.sessions[key] = session
        end
    end
end
