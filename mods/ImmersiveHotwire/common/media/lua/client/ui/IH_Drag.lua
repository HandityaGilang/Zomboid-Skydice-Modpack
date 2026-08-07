local RenderConfig = require "render/IH_RenderConfig"
local Utils = require "util/IH_Utils"
local WireModel = require "gameplay/IH_WireModel"
local SparkGameplay = require "gameplay/IH_SparkGameplay"
local SparkVfx = require "render/IH_SparkVfx"

local ANGLES = RenderConfig.ANGLES
local WIRES = RenderConfig.WIRES

local M = {}

function M.trySpark(state, context)
    local chance = state:getElectronicsSparkChance()
    if not Utils.rollChance(chance) then
        return { didSpark = false }
    end
    if not SparkGameplay.apply(state) then
        return { didSpark = false }
    end
    SparkVfx.apply(state)
    local sign = SparkVfx.kickSignFromDrag(context.startX, context.endX)
    local magnitude = SparkVfx.rollKickMagnitude(context.kickMin, context.kickMax)
    return {
        didSpark = true,
        sign = sign,
        magnitude = magnitude,
    }
end

function M.begin(state, slot, index, mouseX, mouseY)
    local wire = state.wires[index]
    if wire.homeX == nil then
        wire.homeX = slot.x
    end
    if wire.homeY == nil then
        wire.homeY = slot.y
    end
    if wire.lastAngleDeg == nil then
        wire.lastAngleDeg = 0
    end
    state.dragging = {
        index = index,
        slot = slot,
        offsetX = mouseX - slot.x,
        offsetY = mouseY - slot.y,
        startMouseX = mouseX,
        startMouseY = mouseY,
        homeX = wire.homeX,
        homeY = wire.homeY,
        angleDeg = wire.lastAngleDeg,
        targetAngleDeg = wire.lastAngleDeg,
    }
    slot.visible = false
end

function M.update(state, mouseX, mouseY)
    local dragging = state.dragging
    local slot = dragging.slot
    local wire = state.wires[dragging.index]
    local scale = slot.scale or 1
    local baseAngle = WireModel.getBaseAngle(wire, ANGLES)
    local pivotX, pivotY = Utils.getWirePivot(slot.x, slot.y, slot.h, scale, WIRES.PIVOT_X, WIRES.PIVOT_Y)
    local dx = pivotX - mouseX
    local dy = pivotY - mouseY
    local targetAngle = math.deg(math.atan2(-dx, dy))
    targetAngle = Utils.clamp(targetAngle, -ANGLES.LIMIT, ANGLES.LIMIT)
    dragging.targetAngleDeg = targetAngle + baseAngle
    return dragging.targetAngleDeg
end

function M.cancel(state)
    local dragging = state.dragging
    local wire = state.wires[dragging.index]
    wire.lastAngleDeg = dragging.angleDeg
    local slot = dragging.slot
    slot.x = dragging.homeX
    slot.y = dragging.homeY
    slot.visible = true
    state.dragging = nil
end

function M.finish(state, mouseX, mouseY)
    local dragging = state.dragging
    local dragIndex = dragging.index
    local draggingWire = state.wires[dragIndex]
    if state:attemptTapeOnTail(dragIndex, mouseX, mouseY) then
        return true
    end
    local _, targetIndex = state:getWireButtonAt(mouseX, mouseY, dragIndex)
    if not targetIndex then
        if state:wireHasRole(draggingWire, "battery") then
            local spark = M.trySpark(state, {
                startX = dragging.startMouseX,
                endX = mouseX,
            })
            M.cancel(state)
            if spark.didSpark then
                local baseAngle = WireModel.getBaseAngle(draggingWire, ANGLES)
                SparkVfx.applyKick(draggingWire, baseAngle, spark.sign, spark.magnitude, ANGLES.LIMIT)
            end
            state:raiseWireToFront(dragIndex)
            return true
        end
        M.cancel(state)
        state:raiseWireToFront(dragIndex)
        return true
    end

    local merged = state:attemptDropOnTarget(dragIndex, targetIndex, mouseX, mouseY)
    if not merged then
        state:raiseWireToFront(dragIndex)
    end
    return true
end

return M



