require "TimedActions/ISBaseTimedAction"

TABAS_ClimbOverTubEdge = ISBaseTimedAction:derive("TABAS_ClimbOverTubEdge")

local TABAS_GameTimes = require("TABAS_GameTimes")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")

function TABAS_ClimbOverTubEdge:isValid()
	if self.prepSq == nil or self.targetSq == nil then return false end
    if TABAS_BathingUtils.isWaterTooHot(self.tfc_Base) then return false end
	return true
end

function TABAS_ClimbOverTubEdge:waitToStart()
    local char = self.character
    local dir = self:getFacingDirection()
    char:faceDirection(dir)
    return char:shouldBeTurning() or char:isWalking()
end

function TABAS_ClimbOverTubEdge:start()
    self.started = false
    self.outcome = nil
    if TABAS_BathingUtils.isWaterTooHot(self.tfc_Base) then
        TABAS_BathingUtils.sayTooHot(self.character)
        self:forceComplete()
    end
end

function TABAS_ClimbOverTubEdge:update()
    local char = self.character
    local dir = self:getFacingDirection()

    char:setMetabolicTarget(Metabolics.JumpFence)

    if not self.started then
        char:faceDirection(dir)

        if self.startDelay > 0 then
            self.startDelay = self.startDelay - 1
            return
        end
        if char:getDir() ~= dir or char:isWalking() or char:isTurning() or char:shouldBeTurning() then
            return
        end

        self.started = true
        char:climbOverFence(dir)
        return
    end

    if self.character:getVariableBoolean("ClimbFenceStarted") and not self.outcome then
        self.outcome = self.character:getVariableString("ClimbFenceOutcome")
        if self.outcome and self.outcome ~= "success" then
            self.recover = 0.5
        end
    end
    if self.character:getVariableBoolean("ClimbFenceFinished") then
        if self.recover > 0 then
            self.recover = self.recover - TABAS_GameTimes.getRealworldSecondsSinceLastUpdate()
        else
            self:forceComplete()
        end
    end
end

function TABAS_ClimbOverTubEdge:stop()
    ISBaseTimedAction.stop(self)
end

function TABAS_ClimbOverTubEdge:perform()
    setGameSpeed(1)
    ISBaseTimedAction.perform(self)
end

function TABAS_ClimbOverTubEdge:getFacingDirection()
    if self.faceDir then return self.faceDir end

    local faceDir = IsoDirections.N
    local dx = self.targetSq:getX() - self.prepSq:getX()
    local dy = self.targetSq:getY() - self.prepSq:getY()

    if dx == 1 then faceDir = IsoDirections.E end
    if dx == -1 then faceDir = IsoDirections.W end
    if dy == 1 then faceDir = IsoDirections.S end
    return faceDir
end

function TABAS_ClimbOverTubEdge:new(character, prepSq, targetSq, tfc_Base)
    local o = ISBaseTimedAction.new(self, character)
    o.prepSq = prepSq
    o.targetSq = targetSq
    o.tfc_Base = tfc_Base
    o.startDelay = 60
    o.recover = 0
    o.maxTime = 200
    return o
end
