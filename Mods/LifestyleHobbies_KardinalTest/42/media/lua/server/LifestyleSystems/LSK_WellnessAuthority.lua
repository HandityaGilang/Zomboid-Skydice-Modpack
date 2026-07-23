require "LifestyleSystems/LSK_SystemDefinitions"
require "LifestyleCore/LSK_ActionAuthority"

LifestyleSecure = LifestyleSecure or {}
local Wellness = {}
local Defs = LifestyleSecure.SystemDefinitions
local Limits = Defs.Wellness

Wellness.sessions = {}
Wellness.teachingRequests = {}

function Wellness.begin(player, actionName, durationMs, context)
    if not Limits.actions[actionName] then
        return nil, "unknown_action"
    end
    local key = Defs.playerKey(player)
    if not key then
        return nil, "no_player"
    end
    -- Replace a stuck prior session (failed Complete / missing ActionState) so
    -- the next Meditation/Yoga begin is never blocked forever with action_busy.
    local existing = Wellness.sessions[key]
    if existing then
        Wellness.sessions[key] = nil
        if existing.secureName and LSK_ActionAuthority and LSK_ActionAuthority.cancel then
            LSK_ActionAuthority.cancel(player, existing.secureName)
        end
    end
    durationMs = math.floor(Defs.clamp(durationMs, 5000, Limits.maxSessionMs) or 5000)
    local secureName = "LS" .. actionName
    local nonce = LSK_ActionAuthority.begin(player, secureName, durationMs + 30000, context or {})
    if not nonce then
        return nil, "session_rejected"
    end
    Wellness.sessions[key] = {
        actionName = actionName,
        secureName = secureName,
        nonce = nonce,
        startedAt = Defs.now(),
        durationMs = durationMs,
    }
    return nonce
end

function Wellness.complete(player, nonce, requested)
    local key = Defs.playerKey(player)
    local session = key and Wellness.sessions[key] or nil
    if not session or session.nonce ~= nonce then
        return false, "invalid_session"
    end
    Wellness.sessions[key] = nil
    local elapsedMs = math.max(0, Defs.now() - session.startedAt)
    -- Body rewards scale with how long the session ran vs declared TTL.
    -- Skill XP is already accumulated from poses/ticks on the client; do not
    -- re-scale by TTL (Yoga begin uses maxSessionMs so short sessions would
    -- otherwise grant near-zero Fitness/Nimble).
    local ratio = 1
    if session.durationMs and session.durationMs > 0 then
        ratio = math.min(1, elapsedMs / session.durationMs)
    end
    requested = type(requested) == "table" and requested or {}
    local maxFit = Limits.maxFitnessXp or 250
    local maxNim = Limits.maxNimbleXp or 120
    local reward = {
        healing = math.min(Defs.clamp(requested.healing, 0, Limits.maxHeal) or 0, Limits.maxHeal * ratio),
        stiffness = math.min(Defs.clamp(requested.stiffness, 0, Limits.maxStiffnessReduction) or 0,
            Limits.maxStiffnessReduction * ratio),
        xp = Defs.clamp(requested.xp, 0, Limits.maxXp) or 0,
        fitnessXp = Defs.clamp(requested.fitnessXp, 0, maxFit) or 0,
        nimbleXp = Defs.clamp(requested.nimbleXp, 0, maxNim) or 0,
    }
    return LSK_ActionAuthority.complete(player, session.secureName, nonce, function()
        return reward
    end)
end

function Wellness.requestTeaching(teacher, student, actionName)
    if not Limits.actions[actionName] or not Defs.inRange(teacher, student, Limits.teachingRadius) then
        return false, "invalid_teaching_request"
    end
    local teacherKey = Defs.playerKey(teacher)
    local studentKey = Defs.playerKey(student)
    if not teacherKey or not studentKey or teacherKey == studentKey then
        return false, "invalid_players"
    end
    Wellness.teachingRequests[studentKey] = {
        teacherKey = teacherKey,
        actionName = actionName,
        expiresAt = Defs.now() + Defs.LIMITS.requestTtlMs,
    }
    return true
end

function Wellness.respondTeaching(student, teacher, actionName, accepted)
    local studentKey = Defs.playerKey(student)
    local teacherKey = Defs.playerKey(teacher)
    local request = studentKey and Wellness.teachingRequests[studentKey] or nil
    if studentKey then
        Wellness.teachingRequests[studentKey] = nil
    end
    if not request or request.teacherKey ~= teacherKey or request.actionName ~= actionName
        or request.expiresAt < Defs.now() then
        return false, "no_request"
    end
    if accepted ~= true then
        return true, "declined"
    end
    if not Defs.inRange(teacher, student, Limits.teachingRadius) then
        return false, "too_far"
    end
    return true, {
        teacherKey = teacherKey,
        studentKey = studentKey,
        actionName = actionName,
    }
end

function Wellness.cleanupPlayer(player)
    local key = Defs.playerKey(player)
    if not key then
        return
    end
    Wellness.sessions[key] = nil
    Wellness.teachingRequests[key] = nil
    for studentKey, request in pairs(Wellness.teachingRequests) do
        if request.teacherKey == key then
            Wellness.teachingRequests[studentKey] = nil
        end
    end
end

return Wellness
