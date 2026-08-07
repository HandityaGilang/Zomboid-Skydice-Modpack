local RenderConfig = require "render/IH_RenderConfig"

local UI_SPARK = RenderConfig.SPARK

local M = {}

function M.rollKickMagnitude(minValue, maxValue)
    local minKick = minValue or UI_SPARK.KICK_MIN
    local maxKick = maxValue or UI_SPARK.KICK_MAX
    if maxKick < minKick then
        maxKick = minKick
    end
    return minKick + ZombRand((maxKick - minKick) + 1)
end

function M.kickSignFromDrag(startX, endX)
    if endX < startX then
        return 1
    elseif endX > startX then
        return -1
    end
    return 1
end

function M.applyKick(wire, baseAngle, sign, magnitude, limit)
    local angleLimit = limit or UI_SPARK.KICK_MAX
    local current = wire.lastAngleDeg or baseAngle
    local relative = current - baseAngle
    local dir = sign or 1
    if dir == 0 then
        dir = 1
    end
    local kickMag = magnitude or UI_SPARK.KICK_MAX
    relative = relative + (kickMag * dir)
    relative = math.max(-angleLimit, math.min(angleLimit, relative))
    wire.lastAngleDeg = baseAngle + relative
end

function M.apply(state)
    state:playUISound("IH_Spark")
end

return M
