require "PlayablePool/PP_Core"
require "PlayablePool/PP_Skills"
require "PlayablePool/PP_Physics"
require "PlayablePool/PP_AI"

PPServer = PPServer or {}
PPServer.sessions = PPServer.sessions or {}
PPServer.aiPlans = PPServer.aiPlans or {}

local function clamp(value, low, high)
    value = tonumber(value) or low
    if value < low then
        return low
    end
    if value > high then
        return high
    end
    return value
end

local function message(playerObj, text)
    if playerObj then
        sendServerCommand(playerObj, PP.MODULE, PP.CMD_MESSAGE, { text = text, viewerName = PP.getUsername(playerObj) })
    end
end

local function getScaledMoodRelief(playerObj, configName)
    local configuredAmount = PP.getConfigNumber(configName)
    if not configuredAmount or configuredAmount <= 0 then
        return 0
    end
    local profile = PP.getBilliardsSkillProfile(PP.getPlayerBilliardsLevel(playerObj))
    local scaledAmount = configuredAmount * (PP.MOOD_RELIEF_SCALE or 1) * (profile.moodScale or 1)
    return math.max(1, math.floor(scaledAmount + 0.5))
end

local function relieveAfterTurn(playerObj)
    if not playerObj then
        return
    end
    local changed = false
    changed = PP.applyCharacterStat(playerObj, "BOREDOM", getScaledMoodRelief(playerObj, "BoredomReliefPerTurn")) or changed
    changed = PP.applyCharacterStat(playerObj, "STRESS", getScaledMoodRelief(playerObj, "StressReliefPerTurn")) or changed
    changed = PP.applyCharacterStat(playerObj, "UNHAPPINESS", getScaledMoodRelief(playerObj, "UnhappinessReliefPerTurn")) or changed
    if changed then
        message(playerObj, "Playing pool helped your mood.")
    end
end

local function getBilliardsXpTotal(playerObj, perk)
    if not playerObj or not perk then
        return nil
    end
    local ok, value = pcall(function()
        return playerObj:getXp():getXP(perk)
    end)
    if ok then
        return value
    end
    return nil
end

local function addBilliardsXp(playerObj, result, nextState, multiplier)
    local perk = PP.getBilliardsPerk and PP.getBilliardsPerk() or nil
    if not perk and Perks then
        perk = Perks.Billiards
    end
    if not playerObj or not result or not perk then
        print("[PlayablePool] Skipped Billiards XP: missing player, result, or perk.")
        return
    end

    local playerName = PP.getUsername(playerObj)
    local xp = PP.calculateBilliardsShotXp(playerName, result, nextState, multiplier or 1)

    if xp <= 0 then
        return
    end

    local before = getBilliardsXpTotal(playerObj, perk)
    local ok = PP.addXp(playerObj, perk, xp)
    local after = getBilliardsXpTotal(playerObj, perk)
    local changed = ok and (before == nil or after == nil or after > before)

    if changed then
        print("[PlayablePool] Awarded " .. tostring(xp) .. " Billiards XP to " .. tostring(playerName) .. " (total " .. tostring(after) .. ").")
    else
        print("[PlayablePool] Failed to award Billiards XP to " .. tostring(playerName) .. ".")
    end
end

local function xpResultSnapshot(result)
    if not result then
        return nil
    end
    return {
        legal = result.legal,
        scratch = result.scratch,
        required = result.required,
        firstHit = result.firstHit,
        sunk = PP.copyTable(result.sunk or {}),
    }
end

local function queueBilliardsXp(session, playerObj, result, multiplier)
    if not session or not playerObj or not result then
        return
    end
    session.pendingXpAward = {
        playerName = PP.getUsername(playerObj),
        result = xpResultSnapshot(result),
        multiplier = multiplier or 1,
    }
end

local function playerCanUseDebug(playerObj)
    if not PP.getConfigBoolean("AllowAdminSoloPractice") then
        return false
    end
    if getDebug and getDebug() then
        return true
    end
    if not playerObj or not playerObj.getAccessLevel then
        return false
    end
    local ok, accessLevel = pcall(function()
        return playerObj:getAccessLevel()
    end)
    if not ok or not accessLevel then
        return false
    end
    accessLevel = string.lower(tostring(accessLevel))
    return accessLevel == "admin" or accessLevel == "moderator" or accessLevel == "overseer" or accessLevel == "gm"
end

local function onlinePlayers()
    local result = {}
    local players = getOnlinePlayers()
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
        if PP.getUsername(players[i]) == name then
            return players[i]
        end
    end
    return nil
end

local function awardPendingBilliardsXp(session)
    local award = session and session.pendingXpAward
    if not award then
        return
    end
    session.pendingXpAward = nil
    local playerObj = findOnlinePlayerByName(award.playerName)
    addBilliardsXp(playerObj, award.result, session.state, award.multiplier)
end

local function onlineNameSet()
    local result = {}
    local players = onlinePlayers()
    for i = 1, #players do
        result[PP.getUsername(players[i])] = true
    end
    result["Debug Bot"] = true
    return result
end

local function sendStateToPlayer(playerObj, state)
    if playerObj and state then
        PP.refreshStatePhase(state)
        sendServerCommand(playerObj, PP.MODULE, PP.CMD_STATE, { state = PP.copyTable(state), viewerName = PP.getUsername(playerObj) })
    end
end

local function broadcastState(session)
    if not session or not session.state then
        return
    end
    for i = 1, #session.state.players do
        sendStateToPlayer(findOnlinePlayerByName(session.state.players[i]), session.state)
    end
    for i = 1, #(session.state.spectators or {}) do
        sendStateToPlayer(findOnlinePlayerByName(session.state.spectators[i]), session.state)
    end
end

local function isSessionAI(state, name)
    return state and state.ai and state.ai.playerName and name == state.ai.playerName
end

local function isResolvingShot(session)
    return session and session.resolvingUntil and getTimestampMs() < session.resolvingUntil
end

local function playableStatus(state)
    if not state then
        return "waiting"
    end
    PP.refreshStatePhase(state)
    return state.status
end

local function anchorFromArgs(args)
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
    return { x = x, y = y, z = z, key = PP.keyForTable(x, y, z) }
end

local function tableExistsNearAnchor(anchor)
    local cell = getCell()
    if not cell or not anchor then
        return false
    end
    for dx = 0, 4 do
        for dy = 0, 4 do
            local square = cell:getGridSquare(anchor.x + dx, anchor.y + dy, anchor.z)
            if square and square.getObjects then
                local objects = square:getObjects()
                for i = 0, objects:size() - 1 do
                    if PP.isPoolTableObject(objects:get(i)) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function ensureSession(anchor, playerName)
    local key = anchor.key
    local session = PPServer.sessions[key]
    if not session then
        session = { state = PP.newState(anchor, playerName), touched = getTimestampMs() }
        PPServer.sessions[key] = session
    end
    session.touched = getTimestampMs()
    return session
end

local function hasPlayer(session, name)
    return PP.findNameIndex(session.state.players, name) ~= nil
end

local function hasSpectator(session, name)
    session.state.spectators = session.state.spectators or {}
    return PP.findNameIndex(session.state.spectators, name) ~= nil
end

local function addPlayer(session, name)
    if hasPlayer(session, name) then
        return
    end
    if #session.state.players >= 2 then
        return false
    end
    PP.removeName(session.state.spectators, name)
    table.insert(session.state.players, name)
    session.state.status = playableStatus(session.state)
    session.state.message = name .. " joined the pool game."
    PP.addEvent(session.state, session.state.message, "join")
    return true
end

local function addSpectator(session, name)
    if not PP.getConfigBoolean("AllowSpectators") then
        return false
    end
    if hasPlayer(session, name) or hasSpectator(session, name) then
        return true
    end
    table.insert(session.state.spectators, name)
    session.state.message = name .. " is watching the pool game."
    PP.addEvent(session.state, session.state.message, "watch")
    return true
end

local function removePlayer(session, name)
    local removedPlayer = PP.removeName(session.state.players, name)
    local removedSpectator = PP.removeName(session.state.spectators, name)
    if #session.state.players == 0 then
        return true
    end
    session.state.currentPlayer = math.min(session.state.currentPlayer or 1, #session.state.players)
    session.state.status = playableStatus(session.state)
    if removedPlayer or removedSpectator then
        session.state.message = name .. " left the pool game."
        PP.addEvent(session.state, session.state.message, "leave")
    end
    return false
end

local function resetSession(session, playerName, options)
    options = options or {}
    local previousModeId = session.state.modeSelected and session.state.modeId or nil
    local previousBreakerName = session.state.breakerName or PP.currentPlayerName(session.state) or playerName
    local previousRackNumber = tonumber(session.state.rackNumber) or 1
    local players = PP.copyTable(session.state.players or {})
    local spectators = PP.copyTable(session.state.spectators or {})
    local ai = PP.copyTable(session.state.ai)
    if not options.force and not PP.findNameIndex(players, playerName) then
        table.insert(players, 1, playerName)
    end
    session.state = PP.newState(session.state.anchor, players[1] or playerName, previousModeId)
    session.state.players = players
    session.state.spectators = spectators
    if ai and PP.findNameIndex(players, ai.playerName) then
        session.state.ai = ai
    end
    session.state.rackNumber = previousRackNumber + 1
    PP.applyRackBreaker(session.state, PP.nextRackBreakerName(players, previousBreakerName, playerName), playerName)
    PP.refreshRack(session.state, session.state.modeId, PP.createRackSeed(session.state.anchor, session.state.modeId, session.state.rackNumber, session.state.breakerName))
    session.state.status = playableStatus(session.state)
    session.state.message = previousModeId and (playerName .. " reset the rack.") or (playerName .. " reset the rack. Choose a mode.")
    PP.addEvent(session.state, session.state.message, "reset")
    PPServer.aiPlans[session.state.key] = nil
    session.aiBusyUntil = nil
end

local function selectMode(session, playerName, modeId)
    if not session or not PP.isValidGameMode(modeId) then
        return false
    end
    PP.applyGameMode(session.state, modeId)
    session.state.message = playerName .. " chose " .. PP.getGameModeName(modeId) .. "."
    PP.addEvent(session.state, session.state.message, "mode")
    return true
end

local function setAIPlayer(session, playerName, difficultyId)
    local difficulty = PP.getAIDifficulty(difficultyId)
    if not session or not session.state or not difficulty then
        return false
    end

    local state = session.state
    local botName = difficulty.playerName or "Pool Bot"
    local previousAI = state.ai and state.ai.playerName or nil
    if not hasPlayer(session, playerName) then
        state.players = { playerName }
    end

    local previousIndex = previousAI and PP.findNameIndex(state.players, previousAI) or nil
    if previousIndex then
        state.players[previousIndex] = botName
    elseif #state.players >= 2 then
        local second = state.players[2]
        if second and not isSessionAI(state, second) then
            return false
        end
        state.players[2] = botName
    else
        table.insert(state.players, botName)
    end

    if previousAI and previousAI ~= botName and state.modeState and state.modeState.groups then
        state.modeState.groups[botName] = state.modeState.groups[previousAI]
        state.modeState.groups[previousAI] = nil
    end
    if state.breakerName == previousAI then
        state.breakerName = botName
    end
    if state.ballInHandPlayer == previousAI then
        state.ballInHandPlayer = botName
    end
    if state.aim and state.aim.playerName == previousAI then
        state.aim = nil
    end

    state.ai = {
        playerName = botName,
        difficulty = difficulty.id,
        xpScale = difficulty.xpScale or 1,
    }
    state.currentPlayer = math.min(state.currentPlayer or 1, #state.players)
    state.status = playableStatus(state)
    if previousAI then
        state.message = "AI opponent changed to " .. difficulty.name .. "."
        PP.addEvent(state, state.message, "debug")
    else
        state.message = botName .. " joined as a " .. difficulty.name .. " AI opponent."
        PP.addEvent(state, state.message, "join")
    end
    PPServer.aiPlans[state.key] = nil
    return true
end

local function removeAIPlayer(session)
    local state = session and session.state
    local ai = state and state.ai
    if not ai or not ai.playerName then
        return false
    end

    local botName = ai.playerName
    PP.removeName(state.players, botName)
    PP.removeName(state.spectators, botName)
    if state.modeState and state.modeState.groups then
        state.modeState.groups[botName] = nil
    end
    if state.ballInHandPlayer == botName then
        PP.clearBallInHand(state)
    end
    if state.aim and state.aim.playerName == botName then
        state.aim = nil
    end

    state.ai = nil
    if state.breakerName == botName then
        PP.applyRackBreaker(state, PP.currentPlayerName(state), state.players and state.players[1])
    end
    state.currentPlayer = math.max(1, math.min(state.currentPlayer or 1, math.max(1, #state.players)))
    state.status = playableStatus(state)
    state.message = botName .. " left the pool game."
    PP.addEvent(state, state.message, "leave")
    PPServer.aiPlans[state.key] = nil
    session.aiBusyUntil = nil
    return true
end

local function ensureDebugBot(session)
    local botName = "Debug Bot"
    if not hasPlayer(session, botName) then
        if #session.state.players >= 2 then
            session.state.players[2] = botName
        else
            table.insert(session.state.players, botName)
        end
    end
    session.state.status = playableStatus(session.state)
    session.state.message = "Debug Bot joined for solo testing."
    PP.addEvent(session.state, session.state.message, "debug")
end

local function validateRequest(playerObj, anchor)
    if not playerObj then
        return false, "Missing player."
    end
    if not anchor then
        return false, "Missing pool table."
    end
    if not PP.playerNearTable(playerObj, anchor) then
        return false, "Move closer to the pool table."
    end
    if not tableExistsNearAnchor(anchor) then
        return false, "This does not look like a pool table."
    end
    return true, nil
end

local function placeAICueBall(session, botName, difficulty)
    local state = session and session.state
    if not state then
        return false
    end
    local placement = PP_AI.chooseCuePlacement(state, botName, difficulty)
    local cue = PP.findBall(state, "cue")
    if not cue or not placement then
        return false
    end

    cue.x = placement.x
    cue.y = placement.y
    cue.vx = 0
    cue.vy = 0
    cue.pocketed = false
    PP.clearBallInHand(state)
    PP.setPhase(state, PP.PHASE_TURN_READY)
    state.message = botName .. " placed the cue ball."
    PP.addEvent(state, state.message, "place")
    session.aiBusyUntil = getTimestampMs() + 650
    broadcastState(session)
    return true
end

local function setAIAimState(session, botName, angle, power)
    local state = session and session.state
    if not state then
        return
    end
    state.aim = {
        playerName = botName,
        angle = angle,
        power = clamp(power, 30, PP.MAX_POWER),
        updatedAt = getTimestampMs(),
    }
    PP.setPhase(state, PP.PHASE_AIMING)
    broadcastState(session)
end

local function updateAIAim(session, plan, botName, difficulty, now)
    local angle, power = PP_AI.nextAim(plan, difficulty, now)
    if angle and power then
        setAIAimState(session, botName, angle, power)
    end
end

local function performAIShot(session, plan, botName, difficulty)
    local state = session and session.state
    if not state then
        return
    end

    state.aim = nil
    if PP.eightBallCallRequired(state) then
        local shotCall = PP.buildShotCallForAim(state, botName, plan.finalAngle)
        local ok = PP.setShotCall(state, botName, shotCall)
        if not ok then
            PP.clearShotCall(state)
        end
    else
        PP.clearShotCall(state)
    end
    PP.setPhase(state, PP.PHASE_SHOT_COMMITTED)
    local nextState, result = PP.simulateShot(state, plan.finalAngle, plan.finalPower, {
        skillLevel = difficulty.skillLevel or 5,
        spinX = 0,
        spinY = 0,
    })
    if not result.ok then
        state.message = botName .. " could not take the shot."
        PP.addEvent(state, state.message, "foul")
        PP.advanceTurn(state)
        state.status = playableStatus(state)
        broadcastState(session)
        return
    end

    local animationPayload = {
        shotNumber = nextState.shotNumber,
        frameMs = PP.ANIMATION_FRAME_MS,
        frames = result.frames,
        sounds = {
            impacts = result.impactCount or 0,
            rails = result.railCount or 0,
            pockets = result.pocketCount or 0,
            events = result.soundEvents or {},
        },
    }
    local finalState = PP.copyTable(nextState)
    animationPayload.finalState = PP.copyTable(finalState)
    local simulatingState = PP.copyTable(state)
    simulatingState.message = tostring(botName) .. "'s shot is in motion..."
    simulatingState.shotInMotion = true
    simulatingState.aim = nil
    simulatingState.animation = animationPayload
    PP.setPhase(simulatingState, PP.PHASE_SIMULATING)
    session.state = simulatingState
    session.pendingFinalState = finalState
    session.resolvingUntil = getTimestampMs() + (#result.frames * PP.ANIMATION_FRAME_MS) + 120
    session.touched = getTimestampMs()
    session.aiBusyUntil = nil
    PPServer.aiPlans[finalState.key] = nil
    broadcastState(session)
end

local function canRunServerAI(session)
    if not session or not session.state then
        return false
    end
    local state = session.state
    local phase = PP.phaseForState(state)
    if not state.modeSelected or state.winner or (phase ~= PP.PHASE_TURN_READY and phase ~= PP.PHASE_READY and phase ~= PP.PHASE_AIMING) or #state.players < 2 then
        return false
    end
    local ai = PP.getStateAI(state)
    if not ai then
        return false
    end
    return PP.currentPlayerName(state) == ai.playerName
end

local function updateServerAI(session, now)
    if not canRunServerAI(session) then
        if session and session.state then
            PPServer.aiPlans[session.state.key] = nil
        end
        return
    end

    local state = session.state
    local ai, difficulty = PP.getStateAI(state)
    local botName = ai.playerName
    local key = state.key
    if session.aiBusyUntil and now < session.aiBusyUntil then
        return
    end
    if state.ballInHand and state.ballInHandPlayer == botName then
        PPServer.aiPlans[key] = nil
        placeAICueBall(session, botName, difficulty)
        return
    end

    local plan = PPServer.aiPlans[key]
    if not plan then
        plan = PP_AI.createShotPlanner(state, botName, difficulty, now)
        PPServer.aiPlans[key] = plan
        state.message = botName .. " is lining up a shot."
        setAIAimState(session, botName, plan.startAngle, plan.startPower)
        return
    end

    PP_AI.advanceShotPlanner(state, botName, difficulty, plan, now, 8)
    updateAIAim(session, plan, botName, difficulty, now)
    if now >= (plan.shootAt or 0) then
        PP_AI.advanceShotPlanner(state, botName, difficulty, plan, now + 999999, 18)
        if not plan.finalAimSettled then
            setAIAimState(session, botName, plan.finalAngle, plan.finalPower)
            plan.finalAimSettled = true
            plan.shootAt = now + 360
            return
        end
        performAIShot(session, plan, botName, difficulty)
    end
end

local function handleJoin(playerObj, args)
    local anchor = anchorFromArgs(args)
    local ok, reason = validateRequest(playerObj, anchor)
    if not ok then
        message(playerObj, reason)
        return
    end

    local playerName = PP.getUsername(playerObj)
    local session = ensureSession(anchor, playerName)
    local joined = addPlayer(session, playerName)
    if joined == false then
        message(playerObj, "That pool table already has two players. Use Watch Pool to spectate.")
        sendStateToPlayer(playerObj, session.state)
        return
    end
    sendStateToPlayer(playerObj, session.state)
    broadcastState(session)
end

local function handleWatch(playerObj, args)
    local anchor = anchorFromArgs(args)
    local ok, reason = validateRequest(playerObj, anchor)
    if not ok then
        message(playerObj, reason)
        return
    end
    if not PP.getConfigBoolean("AllowSpectators") then
        message(playerObj, "Spectating pool is disabled on this server.")
        return
    end

    local session = PPServer.sessions[anchor.key]
    if not session then
        message(playerObj, "No one is playing at that pool table yet.")
        return
    end
    local playerName = PP.getUsername(playerObj)
    if not addSpectator(session, playerName) then
        message(playerObj, "Could not watch that pool game.")
        return
    end
    session.touched = getTimestampMs()
    sendStateToPlayer(playerObj, session.state)
    broadcastState(session)
end

local function handleLeave(playerObj, args)
    local anchor = anchorFromArgs(args)
    if not anchor then
        return
    end
    local session = PPServer.sessions[anchor.key]
    if not session then
        return
    end
    local delete = removePlayer(session, PP.getUsername(playerObj))
    if delete then
        PPServer.sessions[anchor.key] = nil
    else
        broadcastState(session)
    end
end

local function handleReset(playerObj, args)
    local anchor = anchorFromArgs(args)
    local ok, reason = validateRequest(playerObj, anchor)
    if not ok then
        message(playerObj, reason)
        return
    end

    local playerName = PP.getUsername(playerObj)
    local session = PPServer.sessions[anchor.key]
    if not session then
        message(playerObj, "There is no active pool rack to reset.")
        return
    end
    local force = playerCanUseDebug(playerObj)
    local resetOk, resetReason = PP.canResetRack(session.state, playerName, { resolving = isResolvingShot(session), force = force })
    if not resetOk then
        message(playerObj, resetReason)
        sendStateToPlayer(playerObj, session.state)
        return
    end
    resetSession(session, playerName, { force = force })
    session.resolvingUntil = nil
    session.pendingFinalState = nil
    session.pendingXpAward = nil
    sendStateToPlayer(playerObj, session.state)
    broadcastState(session)
end

local function handleSetMode(playerObj, args)
    local anchor = anchorFromArgs(args)
    local ok, reason = validateRequest(playerObj, anchor)
    if not ok then
        message(playerObj, reason)
        return
    end

    local playerName = PP.getUsername(playerObj)
    local session = ensureSession(anchor, playerName)
    if isResolvingShot(session) then
        message(playerObj, "Wait for the shot to finish.")
        return
    end
    if session.state.shotNumber and session.state.shotNumber > 0 and not session.state.winner then
        message(playerObj, "Finish or reset this rack before changing modes.")
        sendStateToPlayer(playerObj, session.state)
        return
    end
    if not hasPlayer(session, playerName) then
        message(playerObj, "Join this pool game before choosing a mode.")
        return
    end
    if not selectMode(session, playerName, args.modeId) then
        message(playerObj, "That pool mode is not available.")
        return
    end
    session.resolvingUntil = nil
    session.pendingFinalState = nil
    session.pendingXpAward = nil
    session.touched = getTimestampMs()
    sendStateToPlayer(playerObj, session.state)
    broadcastState(session)
end

local function handleAddAI(playerObj, args)
    local anchor = anchorFromArgs(args)
    local ok, reason = validateRequest(playerObj, anchor)
    if not ok then
        message(playerObj, reason)
        return
    end

    local playerName = PP.getUsername(playerObj)
    local session = ensureSession(anchor, playerName)
    if isResolvingShot(session) then
        message(playerObj, "Wait for the shot to finish.")
        return
    end
    if not hasPlayer(session, playerName) then
        message(playerObj, "Join this pool game before adding an AI opponent.")
        return
    end
    if not PP.isAIDifficulty(args.difficulty) then
        message(playerObj, "That AI difficulty is not available.")
        return
    end
    local ai = PP.getStateAI(session.state)
    if #session.state.players >= 2 and not ai then
        message(playerObj, "That pool table already has two players.")
        return
    end
    if not setAIPlayer(session, playerName, args.difficulty) then
        message(playerObj, "Could not add an AI opponent at this table.")
        sendStateToPlayer(playerObj, session.state)
        return
    end
    session.touched = getTimestampMs()
    sendStateToPlayer(playerObj, session.state)
    broadcastState(session)
end

local function handleRemoveAI(playerObj, args)
    local anchor = anchorFromArgs(args)
    local ok, reason = validateRequest(playerObj, anchor)
    if not ok then
        message(playerObj, reason)
        return
    end

    local playerName = PP.getUsername(playerObj)
    local session = PPServer.sessions[anchor.key]
    if not session or not hasPlayer(session, playerName) then
        message(playerObj, "Join this pool game before removing an AI opponent.")
        return
    end
    if isResolvingShot(session) then
        message(playerObj, "Wait for the shot to finish.")
        return
    end
    if not removeAIPlayer(session) then
        message(playerObj, "There is no AI opponent at this table.")
        sendStateToPlayer(playerObj, session.state)
        return
    end
    session.touched = getTimestampMs()
    sendStateToPlayer(playerObj, session.state)
    broadcastState(session)
end

local function handlePlaceCue(playerObj, args)
    local anchor = anchorFromArgs(args)
    local ok, reason = validateRequest(playerObj, anchor)
    if not ok then
        message(playerObj, reason)
        return
    end

    local session = PPServer.sessions[anchor.key]
    local playerName = PP.getUsername(playerObj)
    if not session or not hasPlayer(session, playerName) then
        message(playerObj, "Join this pool game before placing the cue ball.")
        return
    end
    if not session.state.modeSelected then
        message(playerObj, "Choose a pool mode before placing the cue ball.")
        sendStateToPlayer(playerObj, session.state)
        return
    end
    if isResolvingShot(session) then
        message(playerObj, "Wait for the shot to finish.")
        return
    end
    if PP.currentPlayerName(session.state) ~= playerName or session.state.ballInHandPlayer ~= playerName then
        message(playerObj, "It is not your ball-in-hand.")
        sendStateToPlayer(playerObj, session.state)
        return
    end

    local x = tonumber(args.tableX)
    local y = tonumber(args.tableY)
    local clear, clearReason = PP.isCuePlacementClear(session.state, x, y)
    if not clear then
        message(playerObj, clearReason)
        return
    end

    local cue = PP.findBall(session.state, "cue")
    if cue then
        cue.x = x
        cue.y = y
        cue.vx = 0
        cue.vy = 0
        cue.pocketed = false
    end
    PP.clearBallInHand(session.state)
    session.state.message = playerName .. " placed the cue ball."
    PP.addEvent(session.state, session.state.message, "place")
    session.touched = getTimestampMs()
    sendStateToPlayer(playerObj, session.state)
    broadcastState(session)
end

local function handleAim(playerObj, args)
    local anchor = anchorFromArgs(args)
    local ok, reason = validateRequest(playerObj, anchor)
    if not ok then
        message(playerObj, reason)
        return
    end

    local session = PPServer.sessions[anchor.key]
    local playerName = PP.getUsername(playerObj)
    if not session or not hasPlayer(session, playerName) then
        return
    end
    if not session.state.modeSelected then
        return
    end
    if isResolvingShot(session) then
        return
    end

    local current = PP.currentPlayerName(session.state)
    if args.active == false or args.active == "false" or args.active == 0 or args.active == "0" then
        if session.state.aim and session.state.aim.playerName == playerName then
            session.state.aim = nil
            PP.setPhase(session.state, PP.PHASE_TURN_READY)
            session.touched = getTimestampMs()
            broadcastState(session)
        end
        return
    end

    if current ~= playerName or session.state.winner or #session.state.players < 2 then
        return
    end
    if session.state.ballInHand and session.state.ballInHandPlayer == playerName then
        return
    end

    local angle = tonumber(args.angle)
    local power = tonumber(args.power)
    if not angle or not power then
        return
    end

    session.state.aim = {
        playerName = playerName,
        angle = angle,
        power = math.max(30, math.min(PP.MAX_POWER, power)),
        updatedAt = getTimestampMs(),
    }
    PP.setPhase(session.state, PP.PHASE_AIMING)
    session.touched = getTimestampMs()
    broadcastState(session)
end

local function handleSetShotCall(playerObj, args)
    local anchor = anchorFromArgs(args)
    local ok, reason = validateRequest(playerObj, anchor)
    if not ok then
        message(playerObj, reason)
        return
    end

    local session = PPServer.sessions[anchor.key]
    local playerName = PP.getUsername(playerObj)
    if not session or not hasPlayer(session, playerName) then
        message(playerObj, "Join this pool game before calling a shot.")
        return
    end
    if isResolvingShot(session) then
        message(playerObj, "Wait for the shot to finish.")
        return
    end
    if PP.currentPlayerName(session.state) ~= playerName then
        message(playerObj, "It is not your turn.")
        sendStateToPlayer(playerObj, session.state)
        return
    end

    local setOk, setReason = PP.setShotCall(session.state, playerName, args.shotCall)
    if not setOk then
        message(playerObj, setReason)
        sendStateToPlayer(playerObj, session.state)
        return
    end
    session.state.message = args.shotCall and args.shotCall.safety and (playerName .. " called safety.") or (playerName .. " called " .. PP.shotCallLabel(session.state.shotCall) .. ".")
    PP.addEvent(session.state, session.state.message, "call")
    session.touched = getTimestampMs()
    sendStateToPlayer(playerObj, session.state)
    broadcastState(session)
end

local function handleShoot(playerObj, args)
    local anchor = anchorFromArgs(args)
    local ok, reason = validateRequest(playerObj, anchor)
    if not ok then
        message(playerObj, reason)
        return
    end
    if not PP.playerAtShotDistance(playerObj, anchor) then
        message(playerObj, "Walk up to the pool table before taking your shot.")
        return
    end

    local session = PPServer.sessions[anchor.key]
    local playerName = PP.getUsername(playerObj)
    if not session or not hasPlayer(session, playerName) then
        message(playerObj, "Join this pool game before shooting.")
        return
    end
    if not session.state.modeSelected then
        message(playerObj, "Choose a pool mode before shooting.")
        sendStateToPlayer(playerObj, session.state)
        return
    end
    if isResolvingShot(session) then
        message(playerObj, "Wait for the shot to finish.")
        return
    end
    if PP.currentPlayerName(session.state) ~= playerName then
        message(playerObj, "It is not your turn.")
        sendStateToPlayer(playerObj, session.state)
        return
    end
    if #session.state.players < 2 then
        message(playerObj, "A second player needs to join first.")
        return
    end
    if session.state.ballInHand and session.state.ballInHandPlayer == playerName then
        message(playerObj, "Place the cue ball before shooting.")
        sendStateToPlayer(playerObj, session.state)
        return
    end
    if PP.eightBallCallRequired(session.state) then
        local shotCall = args.shotCall or session.state.shotCall or PP.buildShotCallForAim(session.state, playerName, args.angle)
        local callOk, callReason = PP.setShotCall(session.state, playerName, shotCall)
        if not callOk then
            message(playerObj, callReason)
            sendStateToPlayer(playerObj, session.state)
            return
        end
    else
        PP.clearShotCall(session.state)
    end

    session.state.aim = nil
    PP.setPhase(session.state, PP.PHASE_SHOT_COMMITTED)
    local skillLevel = PP.getPlayerBilliardsLevel(playerObj)
    local shotAngle = tonumber(args.angle)
    local shotPower = tonumber(args.power)
    if not (args.aimCheat and playerCanUseDebug(playerObj)) then
        shotAngle, shotPower = PP.applyBilliardsShotSkill(shotAngle, shotPower, skillLevel)
    else
        shotPower = math.max(0, math.min(PP.MAX_POWER, shotPower or 0))
    end
    local spinX, spinY = PP.clampCueSpin(args.spinX, args.spinY, skillLevel)
    local nextState, result = PP.simulateShot(session.state, shotAngle, shotPower, {
        skillLevel = skillLevel,
        spinX = spinX,
        spinY = spinY,
    })
    if not result.ok then
        message(playerObj, result.reason or "Shot failed.")
        return
    end
    local animationPayload = {
        shotNumber = nextState.shotNumber,
        frameMs = PP.ANIMATION_FRAME_MS,
        frames = result.frames,
        sounds = {
            impacts = result.impactCount or 0,
            rails = result.railCount or 0,
            pockets = result.pocketCount or 0,
            events = result.soundEvents or {},
        },
    }
    local finalState = PP.copyTable(nextState)
    animationPayload.finalState = PP.copyTable(finalState)
    local simulatingState = PP.copyTable(session.state)
    simulatingState.message = tostring(playerName) .. "'s shot is in motion..."
    simulatingState.shotInMotion = true
    simulatingState.aim = nil
    simulatingState.animation = animationPayload
    PP.setPhase(simulatingState, PP.PHASE_SIMULATING)
    session.state = simulatingState
    session.pendingFinalState = finalState
    queueBilliardsXp(session, playerObj, result, 1)
    session.resolvingUntil = getTimestampMs() + (#result.frames * PP.ANIMATION_FRAME_MS) + 120
    session.touched = getTimestampMs()
    relieveAfterTurn(playerObj)
    broadcastState(session)
end

local function handleDebugAddBot(playerObj, args)
    if not playerCanUseDebug(playerObj) then
        message(playerObj, "Pool debug controls require debug mode or admin access.")
        return
    end

    local anchor = anchorFromArgs(args)
    local ok, reason = validateRequest(playerObj, anchor)
    if not ok then
        message(playerObj, reason)
        return
    end

    local playerName = PP.getUsername(playerObj)
    local session = ensureSession(anchor, playerName)
    if not hasPlayer(session, playerName) then
        session.state.players = { playerName }
    end
    ensureDebugBot(session)
    session.resolvingUntil = nil
    session.pendingFinalState = nil
    session.pendingXpAward = nil
    session.state.currentPlayer = 1
    sendStateToPlayer(playerObj, session.state)
    broadcastState(session)
end

local function handleDebugMyTurn(playerObj, args)
    if not playerCanUseDebug(playerObj) then
        message(playerObj, "Pool debug controls require debug mode or admin access.")
        return
    end

    local anchor = anchorFromArgs(args)
    local ok, reason = validateRequest(playerObj, anchor)
    if not ok then
        message(playerObj, reason)
        return
    end

    local session = PPServer.sessions[anchor.key]
    local playerName = PP.getUsername(playerObj)
    if not session or not hasPlayer(session, playerName) then
        message(playerObj, "Join this pool game before changing turns.")
        return
    end

    for i = 1, #session.state.players do
        if session.state.players[i] == playerName then
            session.state.currentPlayer = i
            break
        end
    end
    session.state.status = playableStatus(session.state)
    session.resolvingUntil = nil
    session.pendingFinalState = nil
    session.pendingXpAward = nil
    session.state.message = "Debug: forced turn to " .. playerName .. "."
    PP.addEvent(session.state, session.state.message, "debug")
    sendStateToPlayer(playerObj, session.state)
    broadcastState(session)
end

local function onClientCommand(module, command, playerObj, args)
    if module ~= PP.MODULE then
        return
    end
    args = args or {}
    if command == PP.CMD_JOIN then
        handleJoin(playerObj, args)
    elseif command == PP.CMD_WATCH then
        handleWatch(playerObj, args)
    elseif command == PP.CMD_LEAVE then
        handleLeave(playerObj, args)
    elseif command == PP.CMD_RESET then
        handleReset(playerObj, args)
    elseif command == PP.CMD_SET_MODE then
        handleSetMode(playerObj, args)
    elseif command == PP.CMD_ADD_AI then
        handleAddAI(playerObj, args)
    elseif command == PP.CMD_REMOVE_AI then
        handleRemoveAI(playerObj, args)
    elseif command == PP.CMD_PLACE_CUE then
        handlePlaceCue(playerObj, args)
    elseif command == PP.CMD_AIM then
        handleAim(playerObj, args)
    elseif command == PP.CMD_SET_SHOT_CALL then
        handleSetShotCall(playerObj, args)
    elseif command == PP.CMD_SHOOT then
        handleShoot(playerObj, args)
    elseif command == PP.CMD_DEBUG_ADD_BOT then
        handleDebugAddBot(playerObj, args)
    elseif command == PP.CMD_DEBUG_MY_TURN then
        handleDebugMyTurn(playerObj, args)
    end
end

function PPServer.onTick()
    PPServer.tickCounter = (PPServer.tickCounter or 0) + 1
    local now = getTimestampMs()
    for _, session in pairs(PPServer.sessions) do
        if session.pendingFinalState and (not session.resolvingUntil or now >= session.resolvingUntil) then
            session.state = session.pendingFinalState
            session.pendingFinalState = nil
            session.resolvingUntil = nil
            awardPendingBilliardsXp(session)
            session.touched = now
            broadcastState(session)
        end
        updateServerAI(session, now)
    end

    if PPServer.tickCounter % 600 ~= 0 then
        return
    end

    local online = onlineNameSet()
    local timeoutMs = math.max(1, PP.getConfigNumber("AbandonedSessionMinutes")) * 60 * 1000
    for key, session in pairs(PPServer.sessions) do
        local state = session.state
        local changed = false
        if state then
            for i = #(state.players or {}), 1, -1 do
                if state.players[i] ~= "Debug Bot" and not isSessionAI(state, state.players[i]) and not online[state.players[i]] then
                    local name = state.players[i]
                    table.remove(state.players, i)
                    PP.addEvent(state, name .. " disconnected from the pool game.", "leave")
                    changed = true
                end
            end
            for i = #(state.spectators or {}), 1, -1 do
                if not online[state.spectators[i]] then
                    table.remove(state.spectators, i)
                    changed = true
                end
            end
            if #state.players == 0 or now - (session.touched or now) > timeoutMs then
                PPServer.sessions[key] = nil
            else
                state.currentPlayer = math.max(1, math.min(state.currentPlayer or 1, #state.players))
                if state.ballInHandPlayer and not hasPlayer(session, state.ballInHandPlayer) then
                    PP.clearBallInHand(state)
                end
                state.status = playableStatus(state)
                if session.pendingFinalState and not session.resolvingUntil then
                    session.pendingFinalState = nil
                    session.pendingXpAward = nil
                end
                if changed then
                    state.message = "Pool session updated."
                    broadcastState(session)
                end
            end
        end
    end
end

Events.OnClientCommand.Add(onClientCommand)
Events.OnTick.Add(PPServer.onTick)
