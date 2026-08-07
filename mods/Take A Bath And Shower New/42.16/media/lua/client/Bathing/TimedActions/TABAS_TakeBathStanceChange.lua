require "TimedActions/ISBaseTimedAction"

TABAS_TakeBathStanceChange = ISBaseTimedAction:derive("TABAS_TakeBathStanceChange")

local TABAS_Utils = require("TABAS_Utils")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_AnimVariables = require("Bathing/TABAS_AnimVariables")
local TABAS_Sounds = require("TABAS_Sounds")

function TABAS_TakeBathStanceChange:isValid()
    if self.prevStance == self.stanceTo then return false end
    return self.bathSession ~= nil and TABAS_BathingUtils.isTakingBath(self.character)
end

function TABAS_TakeBathStanceChange:start()
    local stanceTo = self.stanceTo
    local stanceFrom = self.prevStance
    local animSpeed = self.animSpeed

    if stanceFrom ~= "Idle" and stanceTo ~= "Idle" then
        -- after, idle to stance
        local afterAction = TABAS_TakeBathStanceChange:new(self.character, self.bathSession, stanceTo, "Idle", 1.2)
        self:addAfter(afterAction)

        stanceTo = "Idle"
        animSpeed = 1.6
    end

    self.segmentTargetStance = stanceTo
    if self.bathSession then
        self.bathSession.curStance = stanceTo
    end

    self.character:setVariable("TABAS_StanceChangeFinished", false)
    self.character:setVariable("StanceChangeSpeed", animSpeed)

    TABAS_AnimVariables.syncAnim(self.character, "BATH", { STANCE = stanceTo}, true)

    local stanceKey = ""
    if stanceFrom == "Idle" then
        stanceKey = "to" .. stanceTo
    elseif stanceTo == "Idle" then
        stanceKey = "from" .. stanceFrom
    end

    self:setActionAnim("TABAS_StanceChange")
    self:setAnimVariable("TABAS_StanceTo", stanceKey)

    TABAS_Utils.debugPrint("TakeBathStanceChange: ", stanceKey)
end

function TABAS_TakeBathStanceChange:stop()
    self.character:setVariable("StanceChangeSpeed", 1.0)
    self.character:setVariable("TABAS_StanceChangeFinished", false)
    if self.bathSession then
        self.bathSession.curStance = self.character:getVariableString("TABAS_BathStance")
    end
    ISBaseTimedAction.stop(self)
end

function TABAS_TakeBathStanceChange:perform()
    self.character:setVariable("StanceChangeSpeed", 1.0)
    self.character:setVariable("TABAS_StanceChangeFinished", false)
    if self.bathSession then
        self.bathSession.curStance = self.segmentTargetStance
    end
    ISBaseTimedAction.perform(self)
end

function TABAS_TakeBathStanceChange:animEvent(event, parameter)
    if event == "TABAS_PlaySound" then
        if not self.sound then
            self.sound = TABAS_Sounds.playPlayerSound(self.character, parameter)
        end
    elseif parameter == "TABAS_StanceChangeFinished=true" then
        self:forceComplete()
    end
end

function TABAS_TakeBathStanceChange:getDuration()
    return -1
end

function TABAS_TakeBathStanceChange:new(character, bathSession, stanceTo, prevStance, animSpeed)
    local o = ISBaseTimedAction.new(self, character)
    o.bathSession = bathSession
    o.stanceTo = stanceTo
    o.prevStance = prevStance or character:getVariableString("TABAS_BathStance")
    o.animSpeed = animSpeed or 1.0
    o.maxTime = o:getDuration()
    o.useProgressBar = false

    o.stopOnWalk = false
    o.stopOnRun  = false
    o.stopOnAim  = false
    o.ignoreHandsWounds = true
    return o
end
