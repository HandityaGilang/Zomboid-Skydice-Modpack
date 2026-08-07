require "TimedActions/ISBaseTimedAction"

TABAS_ClimbOverTubEdge = ISBaseTimedAction:derive("TABAS_ClimbOverTubEdge")

local TABAS_Utils = require("TABAS_Utils")
local TABAS_GameTimes = require("TABAS_GameTimes")

function TABAS_ClimbOverTubEdge:isValid()
	return self.prepSq ~= nil and self.targetSq ~= nil
end

function TABAS_ClimbOverTubEdge:waitToStart()
    local char = self.character
    if self.waitDelay == nil then
        self.waitDelay = true
    end
    if TABAS_Utils.waitFrames(self, 30, self.waitDelay) then
        self.waitDelay = false
        return true
    end
	local dir = self:getFacingDirection()
	char:faceDirection(dir)

    local shouldBeTurning = char:shouldBeTurning()
    if TABAS_Utils.waitFrames(self, 30, shouldBeTurning) then
        self.waitDelay = false
        return true
    end
	return shouldBeTurning
end

function TABAS_ClimbOverTubEdge:start()
    self.started = false
    self.outcome = nil
end

function TABAS_ClimbOverTubEdge:update()
    self.character:setMetabolicTarget(Metabolics.JumpFence)

    if not self.started then
        self.started = true
        local dir = self:getFacingDirection()
        self.character:climbOverFence(dir)
    end

    if self.character:getVariableBoolean("ClimbFenceStarted") and not self.outcome then
        self.outcome = self.character:getVariableString("ClimbFenceOutcome")
        if self.outcome and self.outcome ~= "success" then
            self.recover = 0.6
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
    local dx = self.targetSq:getX() - self.prepSq:getX()
    local dy = self.targetSq:getY() - self.prepSq:getY()

    if dx == 1 then return IsoDirections.E end
    if dx == -1 then return IsoDirections.W end
    if dy == 1 then return IsoDirections.S end
    return IsoDirections.N
end

function TABAS_ClimbOverTubEdge:new(character, prepSq, targetSq)
    local o = ISBaseTimedAction.new(self, character)
    o.prepSq = prepSq
    o.targetSq = targetSq
    o.recover = 0
    o.maxTime = 200
    return o
end
