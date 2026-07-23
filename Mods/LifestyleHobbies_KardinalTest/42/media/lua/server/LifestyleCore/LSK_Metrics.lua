require "LifestyleCore/LSK_NetSchema"

LSK_Metrics = LSK_Metrics or {}

local MAX_KEYS = 128
local counters = {}
local keyCount = 0

local function safeKey(value)
    local text = tostring(value or "unknown")
    if string.len(text) > 64 then
        text = string.sub(text, 1, 64)
    end
    return text
end

function LSK_Metrics.increment(name, amount)
    local key = safeKey(name)
    if counters[key] == nil then
        if keyCount >= MAX_KEYS then
            key = "overflow"
        else
            keyCount = keyCount + 1
        end
    end
    local current = counters[key] or 0
    local delta = tonumber(amount) or 1
    if not LSK_NetSchema.isFiniteNumber(delta) then
        delta = 1
    end
    counters[key] = math.min(2147483647, math.max(0, current + delta))
end

function LSK_Metrics.get(name)
    return counters[safeKey(name)] or 0
end

function LSK_Metrics.snapshot()
    local copy = {}
    for key, value in pairs(counters) do
        copy[key] = value
    end
    return copy
end

function LSK_Metrics.printSummary()
    local accepted = LSK_Metrics.get("accepted")
    local rejected = LSK_Metrics.get("rejected")
    local failed = LSK_Metrics.get("handler_failed")
    local limited = LSK_Metrics.get("rate_limited")
    print("[LSK Security] metrics accepted=" .. tostring(accepted)
        .. " rejected=" .. tostring(rejected)
        .. " limited=" .. tostring(limited)
        .. " failed=" .. tostring(failed))
end

if Events and Events.EveryHours then
    Events.EveryHours.Add(LSK_Metrics.printSummary)
end

return LSK_Metrics
