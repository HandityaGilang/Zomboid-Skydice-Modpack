require "LifestyleSystems/LSK_SystemDefinitions"

LifestyleSecure = LifestyleSecure or {}
local Ambition = {}
local Defs = LifestyleSecure.SystemDefinitions
local Limits = Defs.Ambition

local GOALS = {
    LSBladeMaster = { 40000 }, LSTerminator = { 5000, true },
    LSMasterPainter = { 9 }, LSJuryRigger = { 1000 }, LSBrushmaster = { 30 },
    LSGrimeFighter = { 3000, 300, 150 }, LSElDorado = { 2, 200, 300 },
    LSCommando = { 6000 }, LSTheProfessional = { 6000 }, LSLordDeath = { 10000 },
    LSUnstoppable = { 1000, 200, 100, 50, 25, 10 }, LSGoodEating = { 100 },
    LSRockstar = { 10, 20 }, LSExplorer = { 400 }, LSWanderer = { 1000000 },
    LSLumberjack = { 500 }, LSKnockdown = { 4000 },
    LSPlushies = { 1, 2, 2, 2, 2 }, LSDietOfGods = { 100 },
}

local function getRecord(player, ambitionId)
    local state = Defs.systemState(player, "Ambition")
    if not state then
        return nil
    end
    state.records = type(state.records) == "table" and state.records or {}
    local record = state.records[ambitionId]
    if type(record) ~= "table" then
        record = { progress = {}, completed = false, rewarded = false }
        state.records[ambitionId] = record
    end
    record.progress = type(record.progress) == "table" and record.progress or {}
    record.completed = record.completed == true
    record.rewarded = record.rewarded == true
    return record
end

function Ambition.isKnown(ambitionId)
    return Defs.identifier(ambitionId) ~= nil and Limits.ids[ambitionId] == true
end

function Ambition.getGoals(ambitionId)
    if not Ambition.isKnown(ambitionId) then
        return nil
    end
    local copy = {}
    for i = 1, #(GOALS[ambitionId] or {}) do
        copy[i] = GOALS[ambitionId][i]
    end
    return copy
end

function Ambition.setProgress(player, ambitionId, goalIndex, value)
    if not Ambition.isKnown(ambitionId) then
        return false, "unknown_ambition"
    end
    goalIndex = math.floor(tonumber(goalIndex) or 0)
    local target = GOALS[ambitionId] and GOALS[ambitionId][goalIndex] or nil
    if goalIndex < 1 or goalIndex > Limits.maxGoals or target == nil then
        return false, "unknown_goal"
    end
    local record = getRecord(player, ambitionId)
    if record.completed then
        return true, record
    end
    if target == true then
        record.progress[goalIndex] = value == true
    else
        local progress = Defs.clamp(value, 0, math.min(target, Limits.maxProgress))
        if progress == nil then
            return false, "invalid_progress"
        end
        record.progress[goalIndex] = progress
    end
    record.completed = Ambition.isComplete(player, ambitionId)
    return true, record
end

function Ambition.addProgress(player, ambitionId, goalIndex, delta)
    local record = Ambition.isKnown(ambitionId) and getRecord(player, ambitionId) or nil
    local current = record and tonumber(record.progress[goalIndex]) or 0
    delta = Defs.clamp(delta, 0, Limits.maxProgress)
    if not record or not delta then
        return false, "invalid_progress"
    end
    return Ambition.setProgress(player, ambitionId, goalIndex, current + delta)
end

function Ambition.isComplete(player, ambitionId)
    local record = Ambition.isKnown(ambitionId) and getRecord(player, ambitionId) or nil
    local goals = GOALS[ambitionId]
    if not record or not goals then
        return false
    end
    for i = 1, #goals do
        if goals[i] == true then
            if record.progress[i] ~= true then
                return false
            end
        elseif (tonumber(record.progress[i]) or 0) < goals[i] then
            return false
        end
    end
    return true
end

function Ambition.grantCompletionReward(player, ambitionId, rewardCallback)
    if type(rewardCallback) ~= "function" or not Ambition.isComplete(player, ambitionId) then
        return false, "not_complete"
    end
    local record = getRecord(player, ambitionId)
    record.completed = true
    if record.rewarded then
        return true, "already_rewarded"
    end
    local ok, result = pcall(rewardCallback, player, ambitionId)
    if not ok or result == false then
        return false, "reward_failed"
    end
    record.rewarded = true
    record.rewardedAt = Defs.now()
    return true, result
end

return Ambition
