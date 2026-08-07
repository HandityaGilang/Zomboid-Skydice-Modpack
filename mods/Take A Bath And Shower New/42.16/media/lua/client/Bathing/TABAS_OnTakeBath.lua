local TABAS_OnTakeBath = {}

local TABAS_TakeBathSession = require("Bathing/TABAS_TakeBathSession")
local TABAS_Utils = require("TABAS_Utils")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_AnimVariables = require("Bathing/TABAS_AnimVariables")
local TABAS_Sounds = require("TABAS_Sounds")
local TABAS_GameTimes = require("TABAS_GameTimes")

local noise = function(msg)
    if TABAS_Utils.DEBUG_ENABLE then TABAS_Utils.debugPrint("TakeBathDriver", msg) end
end

local AUTO_STANCE_MIN_SEC = 60
local AUTO_STANCE_MAX_SEC = 300
local AUTO_EXT_MIN_SEC = 45
local AUTO_EXT_MAX_SEC = 180
local AUTO_WASH_START_DELAY_SEC = 25
local CHARACTER_SAY_COOLDOWN_MS = 1200

local function resetIdleSchedule(session)
    session._idleStartMs = nil
    session._nextStanceDelayMs = nil
    session._nextExtDelayMs = nil
end

local function getCurrentStance(character, session)
    local stance = character:getVariableString("TABAS_BathStance")
    if stance == nil or stance == "" then
        stance = session.curStance
    end
    if stance == nil or stance == "" then
        return "Idle"
    end
    return stance
end

local function hasQueuedBathStanceChange(character)
    if not character then return false end
    local actionQueue = ISTimedActionQueue.getTimedActionQueue(character)
    local queue = actionQueue and actionQueue.queue
    if not queue then return false end

    for i = 1, #queue do
        local action = queue[i]
        if action and action.Type == "TABAS_TakeBathStanceChange" then
            return true
        end
    end

    return false
end

local function stanceUpdate(character, session, nowMs, curStance)
    if not session.autoStanceEnabled then return false end
    curStance = curStance or getCurrentStance(character, session)
    if curStance == nil or curStance == "" then
        return false
    end

    if not session._idleStartMs then
        session._idleStartMs = nowMs
    end

    if not session._nextStanceDelayMs then
        session._nextStanceDelayMs = AUTO_STANCE_MIN_SEC * 1000
    end

    if (nowMs - session._idleStartMs) < session._nextStanceDelayMs then
        return false
    end

    local stances = TABAS_AnimVariables.getStances("BATH", character:isFemale(), true)
    if not stances or #stances == 0 then
        session._idleStartMs = nowMs
        session._nextStanceDelayMs = ZombRand(AUTO_STANCE_MIN_SEC, AUTO_STANCE_MAX_SEC) * 1000
        return false
    end

    local stanceTo = nil
    for i = 1, #stances do
        if stances[i] ~= curStance then
            stanceTo = stances[i]
            break
        end
    end

    ISTimedActionQueue.add(TABAS_TakeBathStanceChange:new(character, session, stanceTo, curStance))
    session._idleStartMs = nil
    session._nextStanceDelayMs = nil
    session._nextExtDelayMs = nil

    noise("Auto stance change: " .. tostring(curStance) .. " -> " .. tostring(stanceTo))
    return true
end

local function playExtSound(character, session, nowMs)
    local sounds = session.sounds
    if not sounds then return end

    if sounds.waterSound then
        TABAS_Sounds.playPlayerSound(character, sounds.waterSound)
        sounds.waterSound = nil
    end

    if sounds.voiceSound then
        if nowMs >= sounds.voiceDelayMs then
            TABAS_Sounds.playPlayerVoiceSound(character, sounds.voiceSound)
            sounds.voiceSound = nil
            sounds.voiceDelayMs = nil
        end
    end
end

local function triggerExt(character, session, nowMs, curAction, curStance)
    if not session.autoExtEnabled then return false end
    if curAction ~= nil then return false end
    if character:isCurrentState(PlayerExtState.instance()) then return false end

    curStance = curStance or getCurrentStance(character, session)
    if curStance ~= "Idle" then
        return false
    end

    if not session._idleStartMs then
        session._idleStartMs = nowMs
    end

    if not session._nextExtDelayMs then
        session._nextExtDelayMs = ZombRand(AUTO_EXT_MIN_SEC, AUTO_EXT_MAX_SEC) * 1000
    end

    if (nowMs - session._idleStartMs) < session._nextExtDelayMs then
        return false
    end

    local exts = TABAS_AnimVariables.getExts("BATH", true)
    local ext = exts[1]
    if ext == session._lastExt then
        ext = exts[2] or exts[1]
    end

    TABAS_AnimVariables.syncAnim(character, "BATH", {EXT = ext}, true)
    character:reportEvent("EventDoExt")

    local sounds = session.sounds or {}
    sounds.waterSound = "tabas_bath_wave01"
    if ext == "BathExtStretch" then
        sounds.voiceSound = "BathStretch"
        sounds.voiceDelayMs = nowMs + 900
    elseif ext == "BathExtLookUp" then
        sounds.voiceSound = "BathSigh"
        sounds.voiceDelayMs = nowMs + 600
    end
    session.sounds = sounds

    session._lastExt = ext
    session._idleStartMs = nowMs
    session._nextExtDelayMs = ZombRand(AUTO_EXT_MIN_SEC, AUTO_EXT_MAX_SEC) * 1000

    noise("Auto triggerExt: " .. tostring(ext))
    return true
end

local function cancelDisallowedCursor(character)
    if not character then return end
    if not TABAS_BathingUtils.isTakingBath(character) then return end

    local cell = getCell()
    local playerNum = character:getPlayerNum()
    local drag = cell and cell:getDrag(playerNum)
    if not drag then return end

    if not TABAS_BathingUtils.isAllowedCursor(drag) then
        cell:setDrag(nil, playerNum)
        TABAS_BathingUtils.setBathingSuppression(character, true)
    end
end

local function approach(current, target, speed)
    local value = current + (target - current) * speed
    if math.abs(target - value) < 0.01 then
        return target
    end
    return value
end

local function applyBathHeadLook(character, session, stance)
    if not character or not session then return end
    local targetH = 0.0
    local targetV = 0.0
    if stance == "ElbowLF" or stance == "ElbowL" then
        targetH = -1.0
    elseif stance == "ElbowRF" or stance == "ElbowR" then
        targetH = 1.0
    elseif stance == "LookUpF" or stance == "LookUp" then
        targetV = 0.20
    end
    local headLook = session.headLook
    local h = approach(headLook.h, targetH, 0.02)
    local v = approach(headLook.v, targetV, 0.02)
    if headLook.h ~= h or headLook.v ~= v then
        character:setHeadLookAroundDirection(headLook.h, headLook.v)
        headLook.h = h
        headLook.v = v
    end
end

local function updatePopupText(character, session, nowMs)
    if not session.pendingNotAllowedSay then
        session.notAllowedSayCooldownUntilMs = nil
        return
    end

    if session.notAllowedSayCooldownUntilMs == nil then
        character:Say(getText("IGUI_TABAS_NotAllowedAction"))
        session.notAllowedSayCooldownUntilMs = nowMs + CHARACTER_SAY_COOLDOWN_MS
        return
    end

    if nowMs >= session.notAllowedSayCooldownUntilMs then
        session.pendingNotAllowedSay = false
        session.notAllowedSayCooldownUntilMs = nil
    end
end

local function disableAutoMode(session, reason)
    if not session or not session.isAutoMode then return false end
    session.isAutoMode = false
    noise("Auto mode disabled: " .. tostring(reason))
    return true
end

local function autoModeUpdate(character, session)
    if not session.isAutoMode then return false end
    if session.isStopping or session.isFinished then return true end

    if session.endH and session.endH > 0 and TABAS_GameTimes.getWorldAgeHours() >= session.endH then
        local action = TABAS_TakeBathOut:new(character, session)
        action.tabasAutoModeAction = true
        ISTimedActionQueue.add(action)
        session.isStopping = true
        noise("Auto get out")
        return true
    end

    if session.washCount < session.autoWashTargetCount then
        local nowH = TABAS_GameTimes.getWorldAgeHours()
        local elapsedSec = (nowH - session.startH) * 3600
        if not (elapsedSec >= AUTO_WASH_START_DELAY_SEC) then
            return false
        end
        local action = TABAS_TakeBathWashSelf:new(character, session)
        action.tabasAutoModeAction = true
        ISTimedActionQueue.add(action)
        noise("Auto wash self")
        return true
    end

    return false
end

function TABAS_OnTakeBath.update(character)
    if not character then return end
    if not TABAS_BathingUtils.isTakingBath(character) then return end

    local session = TABAS_TakeBathSession:get(character)
    if not session or session.isFinished then return end

    if not session:isValid() then
        TABAS_BathingUtils.endBathing(character, false, true)
        return
    end

    local tfc_Base = session:getTfc()
    if TABAS_BathingUtils.isWaterTooHot(tfc_Base) then
        if not session._tooHotNotified then
            TABAS_BathingUtils.sayTooHot(character)
            session._tooHotNotified = true
        end
        if not session.isStopping then
            disableAutoMode(session, "water too hot")
            ISTimedActionQueue.clear(character)
            ISTimedActionQueue.add(TABAS_TakeBathOut:new(character, session, 2.8))
            session.isStopping = true
        end
        return
    end

    if character:getForwardIsoDirection() ~= session.facingDir then
        character:faceDirection(session.facingDir)
    end
    TABAS_BathingUtils.setBathingSuppression(character, true)
    cancelDisallowedCursor(character)

    local nowMs = getTimestampMs()
    local curStance = getCurrentStance(character, session)

    local actionQueue = ISTimedActionQueue.getTimedActionQueue(character)
    local curAction = (actionQueue and actionQueue.queue) and actionQueue.queue[1]

    if not session.isStopping then
        local currentSq = character:getCurrentSquare()
        if currentSq then
            local movingObjects = currentSq:getMovingObjects()
            for i = 0, movingObjects:size() - 1 do
                local obj = movingObjects:get(i)
                if obj ~= character and not obj:isOnFloor() and (instanceof(obj, "IsoZombie") or instanceof(obj, "IsoPlayer")) then
                    disableAutoMode(session, "square intruder")
                    ISTimedActionQueue.clear(character)
                    ISTimedActionQueue.add(TABAS_TakeBathOut:new(character, session, 2.8))
                    session.isStopping = true
                    noise("Forced get out: square intruder")
                    return
                end
            end
        end
    end

    if curAction ~= nil then
        if curAction.Type == "ISWalkToTimedAction" or curAction.Type == "ISWalkToTimedActionF" then
            TABAS_BathingUtils.endBathing(character, false, true)
            return
        end
        if curAction.Type == "TABAS_TakeBathStanceChange" then
            if not curAction.tabasAutoModeAction then
                curAction.tabasAutoModeAction = true
            end
        -- elseif not character:getVariableBoolean("TABAS_HasBathTimedActions") then
        --     TABAS_AnimVariables.syncAnim(character, "BATH", {HAS_TIMED_ACTIONS = true}, true)
        end
        if session.isAutoMode and not curAction.tabasAutoModeAction then
            disableAutoMode(session, curAction.Type or "manual action")
        end
    else
        -- if character:getVariableBoolean("TABAS_HasBathTimedActions") then
        --     TABAS_AnimVariables.syncAnim(character, "BATH", {HAS_TIMED_ACTIONS = false}, true)
        -- end

        if not autoModeUpdate(character, session) then
            if stanceUpdate(character, session, nowMs, curStance) then
                curStance = actionQueue and actionQueue.queue and actionQueue.queue[1] and actionQueue.queue[1].stanceTo or curStance
            else
                -- triggerExt(character, session, nowMs, curAction)
            end
        end
    end

    updatePopupText(character, session, nowMs)

    triggerExt(character, session, nowMs, curAction, curStance)
    playExtSound(character, session, nowMs)

    applyBathHeadLook(character, session, curStance)

end

function TABAS_OnTakeBath.onKeyStartPressed(_key)
    local character = getPlayer()
    if not character or not TABAS_BathingUtils.isTakingBath(character) then return end

    if _key == Keyboard.KEY_W or _key == Keyboard.KEY_A or _key == Keyboard.KEY_S or _key == Keyboard.KEY_D then
        local session = TABAS_TakeBathSession:get(character)
        if not session then return end
        local actionQueue = ISTimedActionQueue.getTimedActionQueue(character)
        local queue = actionQueue and actionQueue.queue
        local doAction = queue and queue[1] ~= nil

        if _key == Keyboard.KEY_D and hasQueuedBathStanceChange(character) then
            return
        end

        if doAction then
            disableAutoMode(session, "key input cancel")
            ISTimedActionQueue.clear(character)
        else
            if _key == Keyboard.KEY_W then
                ISTimedActionQueue.add(TABAS_TakeBathOut:new(character, session))

            elseif _key == Keyboard.KEY_A then
                ISTimedActionQueue.add(TABAS_TakeBathWashSelf:new(character, session))

            elseif _key == Keyboard.KEY_S then
                session.autoStanceEnabled = not session.autoStanceEnabled
                local answer = session.autoStanceEnabled and "ON" or "OFF"
                character:Say(getText("ContextMenu_TABAS_BathAutoStance") .. ": " .. answer)

            elseif _key == Keyboard.KEY_D then
                local curStance = getCurrentStance(character, session)
                local stanceTo = "Idle"
                if curStance == "Idle" then
                    local stances = TABAS_AnimVariables.getStances("BATH", character:isFemale(), true)
                    stanceTo = stances and stances[1]
                    if stanceTo == nil then
                        return
                    elseif curStance == stanceTo then
                        stanceTo = stances[2]
                    end
                end
                if stanceTo then
                    ISTimedActionQueue.add(TABAS_TakeBathStanceChange:new(character, session, stanceTo, curStance, 1.3))
                    resetIdleSchedule(session)
                end
            end
        end
    end
end

-- The character must not be "IsBathing" and more when game start and re-start.
function TABAS_OnTakeBath.onCreatePlayer(playerIndex, player)
    if not player then return end
    TABAS_BathingUtils.endBathing(player, true)
end

Events.OnCreatePlayer.Add(TABAS_OnTakeBath.onCreatePlayer)
Events.OnPlayerUpdate.Add(TABAS_OnTakeBath.update)
Events.OnKeyStartPressed.Add(TABAS_OnTakeBath.onKeyStartPressed)

return TABAS_OnTakeBath
