require "PlayablePool/PP_Core"
require "PlayablePool/PP_Skills"
require "PlayablePool/PP_Physics"
require "PlayablePool/PP_AI"
require "PlayablePool/PP_Window"
require "Vehicles/TimedActions/ISPathFindAction"

PPClient = PPClient or {}
PPClient.windows = PPClient.windows or {}
PPClient.playerNames = PPClient.playerNames or {}
PPClient.window = PPClient.window or nil
PPClient.playerName = PPClient.playerName or nil
PPClient.tickCounter = 0
PPClient.attackInputSuppressedUntil = PPClient.attackInputSuppressedUntil or {}
PPClient.localSessions = PPClient.localSessions or {}
PPClient.localAIPlans = PPClient.localAIPlans or {}

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

local function isMultiplayerClient()
    return isClient and isClient()
end

local function normalizePlayerNum(playerNum)
    playerNum = tonumber(playerNum)
    if playerNum == nil or playerNum < 0 then
        return 0
    end
    return math.floor(playerNum)
end

local function getPlayerObj(playerNum)
    playerNum = normalizePlayerNum(playerNum)
    if getSpecificPlayer then
        local playerObj = getSpecificPlayer(playerNum)
        if playerObj then
            return playerObj
        end
    end
    return getPlayer and getPlayer() or nil
end

local function clientText(key, fallback)
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

local function getLocalPlayerDisplayName(playerObj)
    if playerObj and playerObj.getDisplayName then
        local ok, name = pcall(function()
            return playerObj:getDisplayName()
        end)
        if ok and name and name ~= "" then
            return tostring(name)
        end
    end
    if playerObj and playerObj.getDescriptor then
        local ok, descriptor = pcall(function()
            return playerObj:getDescriptor()
        end)
        if ok and descriptor then
            local forename = descriptor.getForename and descriptor:getForename() or nil
            local surname = descriptor.getSurname and descriptor:getSurname() or nil
            local name = tostring(forename or "")
            if surname and surname ~= "" then
                name = name ~= "" and (name .. " " .. tostring(surname)) or tostring(surname)
            end
            if name ~= "" then
                return name
            end
        end
    end
    return nil
end

function PPClient.getPlayerName(playerObj, playerNum)
    local baseName = PP.getUsername(playerObj)
    if isMultiplayerClient() then
        return baseName
    end
    playerNum = normalizePlayerNum(playerNum)
    local displayName = getLocalPlayerDisplayName(playerObj)
    if displayName and displayName ~= "" and displayName ~= "Player" and displayName ~= baseName then
        return displayName
    end
    if playerNum > 0 then
        return tostring(baseName) .. " P" .. tostring(playerNum + 1)
    end
    return baseName
end

local function sayLocal(playerObj, text)
    if HaloTextHelper and playerObj then
        local ok = pcall(function()
            HaloTextHelper.addText(playerObj, text, "[br/]", HaloTextHelper.getColorWhite())
        end)
        if ok then
            return
        end
        ok = pcall(function()
            HaloTextHelper.addText(playerObj, text)
        end)
        if ok then
            return
        end
    end
    if playerObj and playerObj.Say then
        playerObj:Say(text)
    end
end

local function setPoolAttackSuppression(playerObj, suppressed)
    if not playerObj then
        return
    end
    pcall(function()
        playerObj:setBannedAttacking(suppressed)
    end)
    pcall(function()
        playerObj:setAuthorizeShoveStomp(not suppressed)
    end)
    if suppressed then
        pcall(function()
            playerObj:setAttackStarted(false)
        end)
        pcall(function()
            playerObj:setDoShove(false)
        end)
    end
end

function PPClient.suppressPlayerAttackInput(playerNum)
    playerNum = normalizePlayerNum(playerNum)
    local playerObj = getPlayerObj(playerNum)
    setPoolAttackSuppression(playerObj, true)
    PPClient.attackInputSuppressedUntil[playerNum] = getTimestampMs() + 450
end

function PPClient.updateAttackInputSuppression()
    local now = getTimestampMs()
    for playerNum, untilMs in pairs(PPClient.attackInputSuppressedUntil or {}) do
        local playerObj = getPlayerObj(playerNum)
        if now <= untilMs then
            setPoolAttackSuppression(playerObj, true)
        else
            PPClient.attackInputSuppressedUntil[playerNum] = nil
            setPoolAttackSuppression(playerObj, false)
        end
    end
end

local function getPlayerScreenRect(playerNum)
    playerNum = normalizePlayerNum(playerNum)
    local core = getCore()
    local x = 0
    local y = 0
    local w = core:getScreenWidth()
    local h = core:getScreenHeight()
    if getPlayerScreenLeft then
        local ok, value = pcall(function()
            return getPlayerScreenLeft(playerNum)
        end)
        if ok and value then
            x = value
        end
    end
    if getPlayerScreenTop then
        local ok, value = pcall(function()
            return getPlayerScreenTop(playerNum)
        end)
        if ok and value then
            y = value
        end
    end
    if getPlayerScreenWidth then
        local ok, value = pcall(function()
            return getPlayerScreenWidth(playerNum)
        end)
        if ok and value and value > 0 then
            w = value
        end
    end
    if getPlayerScreenHeight then
        local ok, value = pcall(function()
            return getPlayerScreenHeight(playerNum)
        end)
        if ok and value and value > 0 then
            h = value
        end
    end
    return x, y, w, h
end

function PPClient.ensureWindow(playerNum)
    playerNum = normalizePlayerNum(playerNum)
    local playerObj = getPlayerObj(playerNum)
    local name = PPClient.getPlayerName(playerObj, playerNum)
    PPClient.playerNames[playerNum] = name
    if playerNum == 0 then
        PPClient.playerName = name
    end
    local existing = PPClient.windows[playerNum]
    if existing then
        existing.playerName = name
        existing.playerObj = playerObj
        existing.playerNum = playerNum
        if playerNum == 0 then
            PPClient.window = existing
        end
        if getJoypadData and setJoypadFocus and getJoypadData(playerNum) then
            setJoypadFocus(playerNum, existing)
        end
        return existing
    end

    local screenX, screenY, screenW, screenH = getPlayerScreenRect(playerNum)
    local width, height = PPPoolWindow.getDefaultWindowSize(screenW, screenH)
    width = math.min(width, math.max(320, screenW - 16))
    height = math.min(height, math.max(240, screenH - 16))
    local x = math.max(screenX + 8, screenX + (screenW - width) / 2)
    local y = math.max(screenY + 8, screenY + (screenH - height) / 2)
    local ui = PPPoolWindow:new(x, y, width, height, name, playerNum, playerObj)
    ui:initialise()
    ui:addToUIManager()
    PPClient.windows[playerNum] = ui
    if playerNum == 0 then
        PPClient.window = ui
    end
    if getJoypadData and setJoypadFocus and getJoypadData(playerNum) then
        setJoypadFocus(playerNum, ui)
    end
    return ui
end

local function localPlayableStatus(state)
    if not state then
        return "waiting"
    end
    PP.refreshStatePhase(state)
    return state.status
end

local function localRefreshState(state)
    if state then
        PP.refreshStatePhase(state)
    end
    return state
end

local function localSendState(state, playerNum)
    localRefreshState(state)
    local sent = false
    local stateKey = state and state.key or nil
    for windowPlayerNum, ui in pairs(PPClient.windows or {}) do
        local windowKey = ui and ui.state and ui.state.anchor and ui.state.anchor.key or nil
        local interested = stateKey and windowKey == stateKey
        if not interested and ui and ui.playerName and state then
            interested = PP.findNameIndex(state.players or {}, ui.playerName) or PP.findNameIndex(state.spectators or {}, ui.playerName)
        end
        if interested then
            ui:setState(PP.copyTable(state))
            sent = true
        elseif playerNum ~= nil and normalizePlayerNum(windowPlayerNum) == normalizePlayerNum(playerNum) then
            ui:setState(PP.copyTable(state))
            sent = true
        end
    end
    if not sent and playerNum ~= nil then
        local ui = PPClient.ensureWindow(playerNum)
        ui:setState(PP.copyTable(state))
    end
end

local function localEnsureSession(anchor, playerName)
    local key = anchor.key
    local session = PPClient.localSessions[key]
    if not session then
        session = { state = PP.newState(anchor, playerName), touched = getTimestampMs() }
        PPClient.localSessions[key] = session
    end
    session.touched = getTimestampMs()
    return session
end

local function localHasPlayer(session, name)
    return PP.findNameIndex(session.state.players or {}, name) ~= nil
end

local function localAddPlayer(session, name)
    if localHasPlayer(session, name) then
        return true
    end
    if #session.state.players >= 2 then
        return false
    end
    table.insert(session.state.players, name)
    session.state.status = localPlayableStatus(session.state)
    session.state.message = name .. " joined the pool game."
    PP.addEvent(session.state, session.state.message, "join")
    return true
end

local function localResetSession(session, playerName, options)
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
    session.state.status = localPlayableStatus(session.state)
    session.state.message = previousModeId and (playerName .. " reset the rack.") or (playerName .. " reset the rack. Choose a mode.")
    PP.addEvent(session.state, session.state.message, "reset")
    PPClient.localAIPlans[session.state.key] = nil
    session.aiBusyUntil = nil
    session.pendingXpAward = nil
end

local function localEnsureDebugBot(session)
    local botName = "Debug Bot"
    if not localHasPlayer(session, botName) then
        if #session.state.players >= 2 then
            session.state.players[2] = botName
        else
            table.insert(session.state.players, botName)
        end
    end
    session.state.ai = nil
    session.state.status = localPlayableStatus(session.state)
    session.state.message = "Debug Bot joined for solo testing."
    PP.addEvent(session.state, session.state.message, "debug")
    PPClient.localAIPlans[session.state.key] = nil
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
        sayLocal(playerObj, "Playing pool helped your mood.")
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

local function localAIXpScale(state, playerName)
    local ai, difficulty = PP.getStateAI(state)
    if ai and difficulty and ai.playerName ~= playerName then
        return difficulty.xpScale or 1
    end
    return 1
end

local function addBilliardsXp(playerObj, playerNum, result, nextState, multiplier)
    local perk = PP.getBilliardsPerk and PP.getBilliardsPerk() or nil
    if not perk and Perks then
        perk = Perks.Billiards
    end
    if not playerObj or not result or not perk then
        print("[PlayablePool] Skipped local Billiards XP: missing player, result, or perk.")
        return
    end

    local playerName = PPClient.getPlayerName(playerObj, playerNum)
    local xp = PP.calculateBilliardsShotXp(playerName, result, nextState, multiplier or 1)
    if xp <= 0 then
        return
    end

    local before = getBilliardsXpTotal(playerObj, perk)
    local ok = PP.addXp(playerObj, perk, xp)
    local after = getBilliardsXpTotal(playerObj, perk)
    if ok and (before == nil or after == nil or after > before) then
        print("[PlayablePool] Awarded " .. tostring(xp) .. " local Billiards XP to " .. tostring(playerName) .. " (total " .. tostring(after) .. ").")
    else
        print("[PlayablePool] Failed to award local Billiards XP to " .. tostring(playerName) .. ".")
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

local function queueLocalBilliardsXp(session, playerObj, playerNum, result, nextState, multiplier)
    if not session or not playerObj or not result then
        return
    end
    local frames = result.frames or {}
    session.pendingXpAward = {
        playerName = PPClient.getPlayerName(playerObj, playerNum),
        playerNum = normalizePlayerNum(playerNum),
        result = xpResultSnapshot(result),
        nextState = PP.copyTable(nextState),
        multiplier = multiplier or 1,
        awardAt = getTimestampMs() + (#frames * PP.ANIMATION_FRAME_MS) + 120,
    }
end

local function awardPendingLocalXp(session, now)
    local award = session and session.pendingXpAward
    if not award or (award.awardAt and now < award.awardAt) then
        return
    end
    session.pendingXpAward = nil
    local playerObj = getPlayerObj(award.playerNum)
    if not playerObj or PPClient.getPlayerName(playerObj, award.playerNum) ~= award.playerName then
        print("[PlayablePool] Skipped delayed local Billiards XP: player changed or unavailable.")
        return
    end
    addBilliardsXp(playerObj, award.playerNum, award.result, award.nextState or session.state, award.multiplier)
end

local function updateLocalXpAwards(now)
    for _, session in pairs(PPClient.localSessions) do
        awardPendingLocalXp(session, now)
    end
end

local function localSetAIPlayer(session, playerName, difficultyId)
    local difficulty = PP.getAIDifficulty(difficultyId)
    local botName = difficulty.playerName or "Pool Bot"
    local previousAI = session.state.ai and session.state.ai.playerName or nil
    if not localHasPlayer(session, playerName) then
        session.state.players = { playerName }
    end
    local previousIndex = previousAI and PP.findNameIndex(session.state.players, previousAI) or nil
    if previousIndex then
        session.state.players[previousIndex] = botName
    elseif #session.state.players >= 2 then
        session.state.players[2] = botName
    else
        table.insert(session.state.players, botName)
    end
    if previousAI and previousAI ~= botName and session.state.modeState and session.state.modeState.groups then
        session.state.modeState.groups[botName] = session.state.modeState.groups[previousAI]
        session.state.modeState.groups[previousAI] = nil
    end
    if session.state.breakerName == previousAI then
        session.state.breakerName = botName
    end
    if session.state.ballInHandPlayer == previousAI then
        session.state.ballInHandPlayer = botName
    end
    if session.state.aim and session.state.aim.playerName == previousAI then
        session.state.aim = nil
    end
    session.state.ai = {
        playerName = botName,
        difficulty = difficulty.id,
        xpScale = difficulty.xpScale or 1,
    }
    session.state.currentPlayer = math.min(session.state.currentPlayer or 1, #session.state.players)
    session.state.status = localPlayableStatus(session.state)
    if previousAI then
        session.state.message = "AI opponent changed to " .. difficulty.name .. "."
        PP.addEvent(session.state, session.state.message, "debug")
    else
        session.state.message = botName .. " joined as a " .. difficulty.name .. " AI opponent."
        PP.addEvent(session.state, session.state.message, "join")
    end
    PPClient.localAIPlans[session.state.key] = nil
end

local function localRemoveAIPlayer(session)
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
    state.status = localPlayableStatus(state)
    state.message = botName .. " left the pool game."
    PP.addEvent(state, state.message, "leave")
    PPClient.localAIPlans[state.key] = nil
    session.aiBusyUntil = nil
    return true
end

local function localPlaceAICueBall(session, botName, difficulty)
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
    localSendState(state)
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
    localSendState(state)
end

local function updateAIAim(session, plan, botName, difficulty, now)
    local angle, power = PP_AI.nextAim(plan, difficulty, now)
    if angle and power then
        setAIAimState(session, botName, angle, power)
    end
end

local function localPerformAIShot(session, plan, botName, difficulty)
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
        state.status = localPlayableStatus(state)
        localSendState(state)
        return
    end

    nextState.animation = {
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
    session.state = nextState
    session.aiBusyUntil = nil
    PPClient.localAIPlans[nextState.key] = nil
    localSendState(session.state)
    session.state.animation = nil
end

local function canRunLocalAI(session)
    if not session or not session.state then
        return false
    end
    if isMultiplayerClient() then
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

local function anyPoolWindowAnimating()
    for _, window in pairs(PPClient.windows or {}) do
        if window and window.isAnimating and window:isAnimating() then
            return true
        end
    end
    return false
end

local function updateLocalAI()
    if isMultiplayerClient() then
        return
    end
    if anyPoolWindowAnimating() then
        return
    end

    local now = getTimestampMs()
    for key, session in pairs(PPClient.localSessions) do
        if not canRunLocalAI(session) then
            PPClient.localAIPlans[key] = nil
        else
            local state = session.state
            local ai, difficulty = PP.getStateAI(state)
            local botName = ai.playerName
            if session.aiBusyUntil and now < session.aiBusyUntil then
                return
            end
            if state.ballInHand and state.ballInHandPlayer == botName then
                PPClient.localAIPlans[key] = nil
                localPlaceAICueBall(session, botName, difficulty)
                return
            end

            local plan = PPClient.localAIPlans[key]
            if not plan then
                plan = PP_AI.createShotPlanner(state, botName, difficulty, now)
                PPClient.localAIPlans[key] = plan
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
                localPerformAIShot(session, plan, botName, difficulty)
                return
            end
        end
    end
end

local function localHandleCommand(playerObj, playerNum, command, anchor, args)
    if not playerObj or not anchor then
        return
    end
    playerNum = normalizePlayerNum(playerNum)
    local playerName = PPClient.getPlayerName(playerObj, playerNum)
    local createSession = command == PP.CMD_JOIN
        or command == PP.CMD_SET_MODE
        or command == PP.CMD_ADD_AI
        or command == PP.CMD_DEBUG_ADD_BOT
    local session = createSession and localEnsureSession(anchor, playerName) or PPClient.localSessions[anchor.key]
    if not session then
        if command == PP.CMD_WATCH then
            sayLocal(playerObj, "No one is playing at that pool table yet.")
        elseif command ~= PP.CMD_LEAVE then
            sayLocal(playerObj, "No pool game is active at that table.")
        end
        return
    end
    local state = session.state

    if command == PP.CMD_JOIN then
        local joined = localAddPlayer(session, playerName)
        if joined == false then
            sayLocal(playerObj, "That pool table already has two players.")
        end
        localSendState(state, playerNum)
    elseif command == PP.CMD_WATCH then
        sayLocal(playerObj, "Spectating is only useful in multiplayer.")
        localSendState(state, playerNum)
    elseif command == PP.CMD_LEAVE then
        PP.removeName(state.players, playerName)
        PP.removeName(state.spectators, playerName)
        PPClient.localAIPlans[anchor.key] = nil
        session.pendingXpAward = nil
        if #state.players == 0 then
            PPClient.localSessions[anchor.key] = nil
        else
            state.currentPlayer = math.min(state.currentPlayer or 1, #state.players)
            state.status = localPlayableStatus(state)
            localSendState(state, playerNum)
        end
    elseif command == PP.CMD_RESET then
        local resetOk, resetReason = PP.canResetRack(session.state, playerName, { resolving = anyPoolWindowAnimating() })
        if not resetOk then
            sayLocal(playerObj, resetReason)
            localSendState(session.state, playerNum)
            return
        end
        localResetSession(session, playerName)
        localSendState(session.state, playerNum)
    elseif command == PP.CMD_SET_MODE then
        if state.shotNumber and state.shotNumber > 0 and not state.winner then
            sayLocal(playerObj, "Finish or reset this rack before changing modes.")
        elseif PP.isValidGameMode(args.modeId) then
            PP.applyGameMode(state, args.modeId)
            state.message = playerName .. " chose " .. PP.getGameModeName(args.modeId) .. "."
            PP.addEvent(state, state.message, "mode")
        else
            sayLocal(playerObj, "That pool mode is not available.")
        end
        PPClient.localAIPlans[anchor.key] = nil
        session.pendingXpAward = nil
        localSendState(state, playerNum)
    elseif command == PP.CMD_ADD_AI then
        if isMultiplayerClient() then
            sayLocal(playerObj, "AI opponents are only available in singleplayer.")
        elseif not PP.isAIDifficulty(args.difficulty) then
            sayLocal(playerObj, "That AI difficulty is not available.")
        else
            localSetAIPlayer(session, playerName, args.difficulty)
        end
        localSendState(state, playerNum)
    elseif command == PP.CMD_REMOVE_AI then
        if isMultiplayerClient() then
            sayLocal(playerObj, "AI opponents are only available in singleplayer.")
        elseif not localRemoveAIPlayer(session) then
            sayLocal(playerObj, "There is no AI opponent at this table.")
        end
        localSendState(state, playerNum)
    elseif command == PP.CMD_DEBUG_ADD_BOT then
        if isDebugEnabled and isDebugEnabled() or getDebug and getDebug() then
            if not localHasPlayer(session, playerName) then
                state.players = { playerName }
            end
            localEnsureDebugBot(session)
        else
            sayLocal(playerObj, "Pool debug controls require debug mode.")
        end
        localSendState(state, playerNum)
    elseif command == PP.CMD_DEBUG_MY_TURN then
        for i = 1, #state.players do
            if state.players[i] == playerName then
                state.currentPlayer = i
                break
            end
        end
        state.status = localPlayableStatus(state)
        state.message = "Debug: forced turn to " .. playerName .. "."
        PP.addEvent(state, state.message, "debug")
        localSendState(state, playerNum)
    elseif command == PP.CMD_PLACE_CUE then
        if state.ballInHandPlayer ~= playerName then
            sayLocal(playerObj, "It is not your ball-in-hand.")
            localSendState(state, playerNum)
            return
        end
        local x = tonumber(args.tableX)
        local y = tonumber(args.tableY)
        local clear, reason = PP.isCuePlacementClear(state, x, y)
        if not clear then
            sayLocal(playerObj, reason)
            return
        end
        local cue = PP.findBall(state, "cue")
        if cue then
            cue.x = x
            cue.y = y
            cue.vx = 0
            cue.vy = 0
            cue.pocketed = false
        end
        PP.clearBallInHand(state)
        state.message = playerName .. " placed the cue ball."
        PP.addEvent(state, state.message, "place")
        localSendState(state, playerNum)
    elseif command == PP.CMD_AIM then
        if args.active == false or args.active == "false" or args.active == 0 or args.active == "0" then
            state.aim = nil
            PP.setPhase(state, PP.PHASE_TURN_READY)
        elseif PP.currentPlayerName(state) == playerName and state.modeSelected and #state.players >= 2 and not state.winner then
            state.aim = {
                playerName = playerName,
                angle = tonumber(args.angle) or 0,
                power = math.max(30, math.min(PP.MAX_POWER, tonumber(args.power) or 300)),
                updatedAt = getTimestampMs(),
            }
            PP.setPhase(state, PP.PHASE_AIMING)
        end
        -- Singleplayer has no remote observers, and echoing aim state back into
        -- the same window can recursively trigger aim cancellation during setState.
        session.touched = getTimestampMs()
    elseif command == PP.CMD_SET_SHOT_CALL then
        if PP.currentPlayerName(state) ~= playerName then
            sayLocal(playerObj, "It is not your turn.")
            localSendState(state, playerNum)
            return
        end
        local ok, reason = PP.setShotCall(state, playerName, args.shotCall)
        if not ok then
            sayLocal(playerObj, reason)
            return
        end
        state.message = args.shotCall and args.shotCall.safety and (playerName .. " called safety.") or (playerName .. " called " .. PP.shotCallLabel(state.shotCall) .. ".")
        PP.addEvent(state, state.message, "call")
        localSendState(state, playerNum)
    elseif command == PP.CMD_SHOOT then
        if not state.modeSelected then
            sayLocal(playerObj, "Choose a pool mode before shooting.")
            localSendState(state, playerNum)
            return
        end
        if PP.currentPlayerName(state) ~= playerName then
            sayLocal(playerObj, "It is not your turn.")
            localSendState(state, playerNum)
            return
        end
        if #state.players < 2 then
            sayLocal(playerObj, "A second player needs to join first.")
            return
        end
        if state.ballInHand and state.ballInHandPlayer == playerName then
            sayLocal(playerObj, "Place the cue ball before shooting.")
            localSendState(state, playerNum)
            return
        end
        if PP.eightBallCallRequired(state) then
            local shotCall = args.shotCall or state.shotCall or PP.buildShotCallForAim(state, playerName, args.angle)
            local ok, reason = PP.setShotCall(state, playerName, shotCall)
            if not ok then
                sayLocal(playerObj, reason)
                localSendState(state, playerNum)
                return
            end
        else
            PP.clearShotCall(state)
        end
        state.aim = nil
        PP.setPhase(state, PP.PHASE_SHOT_COMMITTED)
        local skillLevel = PP.getPlayerBilliardsLevel(playerObj)
        local shotAngle = tonumber(args.angle)
        local shotPower = tonumber(args.power)
        if not args.aimCheat then
            shotAngle, shotPower = PP.applyBilliardsShotSkill(shotAngle, shotPower, skillLevel)
        else
            shotPower = math.max(0, math.min(PP.MAX_POWER, shotPower or 0))
        end
        local spinX, spinY = PP.clampCueSpin(args.spinX, args.spinY, skillLevel)
        local nextState, result = PP.simulateShot(state, shotAngle, shotPower, {
            skillLevel = skillLevel,
            spinX = spinX,
            spinY = spinY,
        })
        if not result.ok then
            sayLocal(playerObj, result.reason or "Shot failed.")
            return
        end
        relieveAfterTurn(playerObj)
        queueLocalBilliardsXp(session, playerObj, playerNum, result, nextState, localAIXpScale(state, playerName))
        nextState.animation = {
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
        session.state = nextState
        localSendState(session.state, playerNum)
        session.state.animation = nil
    end
end

local function sendPoolCommand(playerNum, command, anchor, args)
    playerNum = normalizePlayerNum(playerNum)
    local playerObj = getPlayerObj(playerNum)
    if not playerObj or not anchor then
        return
    end
    args = args or {}
    args.x = anchor.x
    args.y = anchor.y
    args.z = anchor.z
    args.key = anchor.key
    args.playerName = PPClient.getPlayerName(playerObj, playerNum)
    if not isMultiplayerClient() then
        localHandleCommand(playerObj, playerNum, command, anchor, args)
        return
    end
    PP.sendClientCommand(playerObj, PP.MODULE, command, args)
end

local function findWalkTarget(anchor, playerObj)
    local cell = getCell()
    if not cell or not anchor or not playerObj then
        return anchor and (anchor.x + 1.5), anchor and (anchor.y + 1.5), anchor and anchor.z
    end

    local bestSquare = nil
    local bestDist = nil
    local bestShotSquare = nil
    local bestShotDist = nil
    for dx = -1, 4 do
        for dy = -1, 4 do
            local square = cell:getGridSquare(anchor.x + dx, anchor.y + dy, anchor.z)
            if square and square.getObjects then
                local nearTable = false
                for ox = -1, 1 do
                    for oy = -1, 1 do
                        local tableSquare = cell:getGridSquare(square:getX() + ox, square:getY() + oy, anchor.z)
                        if tableSquare and tableSquare.getObjects then
                            local objects = tableSquare:getObjects()
                            for i = 0, objects:size() - 1 do
                                if PP.isPoolTableObject(objects:get(i)) then
                                    nearTable = true
                                    break
                                end
                            end
                        end
                    end
                end
                if nearTable and not square:isSolid() and not square:isSolidTrans() then
                    local dist = playerObj:DistToSquared(square:getX() + 0.5, square:getY() + 0.5)
                    if not bestDist or dist < bestDist then
                        bestDist = dist
                        bestSquare = square
                    end
                    local shotDx = square:getX() + 0.5 - (anchor.x + 1)
                    local shotDy = square:getY() + 0.5 - (anchor.y + 1)
                    local shotDist = math.sqrt(shotDx * shotDx + shotDy * shotDy)
                    if shotDist <= PP.SHOT_MAX_DISTANCE and (not bestShotDist or dist < bestShotDist) then
                        bestShotDist = dist
                        bestShotSquare = square
                    end
                end
            end
        end
    end

    if bestShotSquare then
        return bestShotSquare:getX() + 0.5, bestShotSquare:getY() + 0.5, bestShotSquare:getZ()
    end
    if bestSquare then
        return bestSquare:getX() + 0.5, bestSquare:getY() + 0.5, bestSquare:getZ()
    end
    return anchor.x + 1.5, anchor.y + 1.5, anchor.z
end

local function onWalkToShotComplete(playerNum, anchor, angle, power, spinX, spinY, aimCheat, shotCall)
    PPClient.sendShootNow(playerNum, anchor, angle, power, spinX, spinY, aimCheat, shotCall)
end

local function onWalkToShotFail(playerNum)
    sayLocal(getPlayerObj(playerNum), "Couldn't reach the pool table.")
end

function PPClient.joinTable(playerNum, anchor)
    playerNum = normalizePlayerNum(playerNum)
    PPClient.ensureWindow(playerNum)
    local playerObj = getPlayerObj(playerNum)
    if playerObj and playerObj.faceLocation then
        playerObj:faceLocation(anchor.x + 1, anchor.y + 1)
    end
    sendPoolCommand(playerNum, PP.CMD_JOIN, anchor, {})
end

function PPClient.watchTable(playerNum, anchor)
    playerNum = normalizePlayerNum(playerNum)
    PPClient.ensureWindow(playerNum)
    sendPoolCommand(playerNum, PP.CMD_WATCH, anchor, {})
end

function PPClient.leaveTable(playerNum, anchor)
    sendPoolCommand(playerNum, PP.CMD_LEAVE, anchor, {})
end

function PPClient.sendShootNow(playerNum, anchor, angle, power, spinX, spinY, aimCheat, shotCall)
    local playerObj = getPlayerObj(playerNum)
    if playerObj and playerObj.faceLocation then
        playerObj:faceLocation(anchor.x + 1, anchor.y + 1)
    end
    sendPoolCommand(playerNum, PP.CMD_SHOOT, anchor, { angle = angle, power = power, spinX = spinX, spinY = spinY, aimCheat = aimCheat and true or false, shotCall = shotCall })
end

function PPClient.sendAim(playerNum, anchor, angle, power, active)
    sendPoolCommand(playerNum, PP.CMD_AIM, anchor, { angle = angle, power = power, active = active and true or false })
end

function PPClient.shoot(playerNum, anchor, angle, power, spinX, spinY, aimCheat, shotCall)
    playerNum = normalizePlayerNum(playerNum)
    local playerObj = getPlayerObj(playerNum)
    if not playerObj or not anchor then
        return
    end
    if PP.playerAtShotDistance(playerObj, anchor) then
        PPClient.sendShootNow(playerNum, anchor, angle, power, spinX, spinY, aimCheat, shotCall)
        return
    end
    local x, y, z = findWalkTarget(anchor, playerObj)
    if playerObj.Say then
        playerObj:Say("Walking up to the table.")
    end
    local action = ISPathFindAction:pathToLocationF(playerObj, x, y, z)
    action:setOnComplete(onWalkToShotComplete, playerNum, PP.copyTable(anchor), angle, power, spinX, spinY, aimCheat and true or false, shotCall)
    action:setOnFail(onWalkToShotFail, playerNum)
    ISTimedActionQueue.add(action)
end

function PPClient.placeCue(playerNum, anchor, tableX, tableY)
    sendPoolCommand(playerNum, PP.CMD_PLACE_CUE, anchor, { tableX = tableX, tableY = tableY })
end

function PPClient.reset(playerNum, anchor)
    sendPoolCommand(playerNum, PP.CMD_RESET, anchor, {})
end

function PPClient.setMode(playerNum, anchor, modeId)
    sendPoolCommand(playerNum, PP.CMD_SET_MODE, anchor, { modeId = modeId })
end

function PPClient.setShotCall(playerNum, anchor, shotCall)
    sendPoolCommand(playerNum, PP.CMD_SET_SHOT_CALL, anchor, { shotCall = shotCall })
end

function PPClient.addAI(playerNum, anchor, difficulty)
    sendPoolCommand(playerNum, PP.CMD_ADD_AI, anchor, { difficulty = difficulty })
end

function PPClient.removeAI(playerNum, anchor)
    sendPoolCommand(playerNum, PP.CMD_REMOVE_AI, anchor, {})
end

function PPClient.debugAddBot(playerNum, anchor)
    sendPoolCommand(playerNum, PP.CMD_DEBUG_ADD_BOT, anchor, {})
end

function PPClient.debugMyTurn(playerNum, anchor)
    sendPoolCommand(playerNum, PP.CMD_DEBUG_MY_TURN, anchor, {})
end

local function onPlayPool(playerNum, anchor)
    PPClient.joinTable(playerNum, anchor)
end

local function onWatchPool(playerNum, anchor)
    PPClient.watchTable(playerNum, anchor)
end

local function onResetPool(playerNum, anchor)
    PPClient.reset(playerNum, anchor)
end

local POOL_CONTEXT_ICON_PATH = "media/textures/PlayablePool/ball_8.png"
local poolContextIconTexture = nil
local poolContextIconLoaded = false

local function setPoolOptionIcon(option)
    if not option then
        return option
    end
    if not poolContextIconLoaded then
        poolContextIconLoaded = true
        if getTexture then
            poolContextIconTexture = getTexture(POOL_CONTEXT_ICON_PATH)
        end
    end
    option.iconTexture = poolContextIconTexture
    return option
end

local function addPoolOption(context, label, ...)
    return setPoolOptionIcon(context:addOption(label, ...))
end

local function addUnavailableOption(context, label, reason)
    local option = context:addOption(label)
    setPoolOptionIcon(option)
    option.notAvailable = true
    if ISWorldObjectContextMenu and ISWorldObjectContextMenu.addToolTip then
        local toolTip = ISWorldObjectContextMenu.addToolTip()
        toolTip.description = tostring(reason or "Unavailable.")
        option.toolTip = toolTip
    end
    return option
end

local function isActiveKnownPoolState(state, anchor)
    if not state or not anchor or state.key ~= anchor.key then
        return false
    end
    return #(state.players or {}) > 0
end

local function hasKnownPoolSession(anchor)
    if not anchor then
        return false
    end
    local session = PPClient.localSessions and PPClient.localSessions[anchor.key] or nil
    if session and isActiveKnownPoolState(session.state, anchor) then
        return true
    end
    for _, window in pairs(PPClient.windows or {}) do
        if window and isActiveKnownPoolState(window.state, anchor) then
            return true
        end
    end
    return false
end

local function addContextMenu(playerNum, context, worldobjects, test)
    if test then
        return
    end
    local playerObj = getSpecificPlayer(playerNum)
    local tableObject = PP.findPoolTableFromWorldObjects(worldobjects)
    local anchor = PP.getTableAnchor(tableObject)
    if not anchor then
        return
    end
    local canWatch = PP.getConfigBoolean("AllowSpectators") and hasKnownPoolSession(anchor)
    if playerObj and not PP.playerNearTable(playerObj, anchor) then
        addUnavailableOption(context, clientText("IGUI_PlayablePool_PlayPool", "Play Pool"), clientText("IGUI_PlayablePool_MoveCloserPool", "Move closer to the pool table."))
        if canWatch then
            addUnavailableOption(context, clientText("IGUI_PlayablePool_WatchPool", "Watch Pool"), clientText("IGUI_PlayablePool_MoveCloserPool", "Move closer to the pool table."))
        end
        addUnavailableOption(context, clientText("IGUI_PlayablePool_ResetRack", "Reset Pool Rack"), clientText("IGUI_PlayablePool_MoveCloserPool", "Move closer to the pool table."))
        return
    end

    addPoolOption(context, clientText("IGUI_PlayablePool_PlayPool", "Play Pool"), playerNum, onPlayPool, anchor)
    if canWatch then
        addPoolOption(context, clientText("IGUI_PlayablePool_WatchPool", "Watch Pool"), playerNum, onWatchPool, anchor)
    end
    addPoolOption(context, clientText("IGUI_PlayablePool_ResetRack", "Reset Pool Rack"), playerNum, onResetPool, anchor)
end

function PPClient.resolvePlayerNumForViewer(viewerName)
    viewerName = viewerName and tostring(viewerName) or nil
    if viewerName and viewerName ~= "" then
        for playerNum = 0, 3 do
            local playerObj = getPlayerObj(playerNum)
            if playerObj then
                if PP.getUsername(playerObj) == viewerName or PPClient.getPlayerName(playerObj, playerNum) == viewerName then
                    return playerNum
                end
            end
        end
        for playerNum, window in pairs(PPClient.windows or {}) do
            if window and window.playerName == viewerName then
                return normalizePlayerNum(playerNum)
            end
        end
    end
    return 0
end

function PPClient.resolvePlayerNumForState(state, viewerName)
    if viewerName then
        return PPClient.resolvePlayerNumForViewer(viewerName)
    end
    if state and state.key then
        for playerNum, window in pairs(PPClient.windows or {}) do
            if window and window.state and window.state.key == state.key then
                return normalizePlayerNum(playerNum)
            end
        end
    end
    return 0
end

local function onServerCommand(module, command, args)
    if module ~= PP.MODULE then
        return
    end
    args = args or {}
    if command == PP.CMD_STATE then
        local playerNum = PPClient.resolvePlayerNumForState(args.state, args.viewerName)
        local ui = PPClient.ensureWindow(playerNum)
        ui:setState(args.state)
        return
    end
    if command == PP.CMD_MESSAGE then
        local playerNum = PPClient.resolvePlayerNumForViewer(args.viewerName)
        sayLocal(getPlayerObj(playerNum), tostring(args.text or "Pool table is not available."))
    end
end

function PPClient.onTick()
    PPClient.tickCounter = (PPClient.tickCounter or 0) + 1
    local now = getTimestampMs()
    PPClient.updateAttackInputSuppression()
    updateLocalXpAwards(now)
    updateLocalAI()
    if PPClient.tickCounter % 30 ~= 0 then
        return
    end

    for playerNum, window in pairs(PPClient.windows or {}) do
        if window and window.state and window.state.anchor then
            local playerObj = getPlayerObj(playerNum)
            if not playerObj or not PP.playerNearTable(playerObj, window.state.anchor) then
                sayLocal(playerObj, clientText("IGUI_PlayablePool_ClosedTooFar", "Closed pool: too far from the table."))
                window:close()
            end
        end
    end
end

function PPClient.onKeyStartPressed(key)
    local window = PPClient.window
    if window and window.handleKeyStartPressed and window:handleKeyStartPressed(key) then
        PPClient.suppressPlayerAttackInput(0)
    end
end

function PPClient.onKeyPressed(key)
    if PPClient.window and PPClient.window.handleKeyPressed and PPClient.window:handleKeyPressed(key) then
        if Keyboard and key == Keyboard.KEY_SPACE then
            PPClient.suppressPlayerAttackInput(0)
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(addContextMenu)
Events.OnServerCommand.Add(onServerCommand)
Events.OnTick.Add(PPClient.onTick)
Events.OnKeyStartPressed.Add(PPClient.onKeyStartPressed)
Events.OnKeyPressed.Add(PPClient.onKeyPressed)
