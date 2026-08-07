require "TimedActions/ISBaseTimedAction"

TABAS_TakeBathOut = ISBaseTimedAction:derive("TABAS_TakeBathOut")

local TABAS_Utils = require("TABAS_Utils")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_AnimVariables = require("Bathing/TABAS_AnimVariables")
local TABAS_Sounds = require("TABAS_Sounds")

function TABAS_TakeBathOut:isValid()
    return self.bathSession ~= nil
end

function TABAS_TakeBathOut:start()
    self.bathSession.isStopping = true

    local sq = self.bathObj:getSquare()
    self.tfc_Base = TFC_Utils.getTfcBaseOnClient(sq:getX(), sq:getY(), sq:getZ(), self.bathObj)

    TABAS_AnimVariables.clearVariables(self.character, "BATH")

    local getupSpeed = self.animSpeed or 1.2
    if self.character:getVariableBoolean("pressedRunButton") then
        getupSpeed = math.max(getupSpeed, 2.5)
    end
    self.character:setVariable("BathGetupSpeed", getupSpeed)
    self:setActionAnim("TABAS_BathOut")
end

function TABAS_TakeBathOut:animEvent(event, parameter)
    if event == "TABAS_PlaySound" then
        if self.tfc_Base and self.tfc_Base:hasFluid() then
            if not self.tfc_Base:hasFluid() then
                TABAS_Sounds.playPlayerSound(self.character, "SurfaceStandUp")
            elseif self.tfc_Base:isLowWater() then
                TABAS_Sounds.playPlayerSound(self.character, "tabas_bath_wave03")
            else
                TABAS_Sounds.playPlayerSound(self.character, "tabas_bath_getup")
            end
        else
            TABAS_Sounds.playPlayerSound(self.character, "SurfaceStandUp")
        end
    elseif parameter == "TABAS_BathEnded=true" then
        self:forceComplete()
    end
end

function TABAS_TakeBathOut:stop()
    setGameSpeed(1)
    TABAS_BathingUtils.endBathing(self.character, false, true)
    ISBaseTimedAction.stop(self)
end

function TABAS_TakeBathOut:endingActionQueue()
    if isServer() then return end
    if not self.bathSession then return end
    local baseSq = self.bathSession.baseSq
    local prepSq = self.bathSession.prepSq
    if not baseSq or not prepSq then return end

    local targetSq = self.bathSession.climbSq
    if targetSq and baseSq ~= targetSq then
        ISTimedActionQueue.add(ISWalkToTimedAction:new(self.character, targetSq))
    end
    ISTimedActionQueue.add(ISWalkToTimedAction:new(self.character, prepSq))

    local towel = self.bathSession.exitTowel or TABAS_Utils.getAvailableTowel(self.character)
    ISTimedActionQueue.add(TABAS_DrySelf:new(self.character, towel, false))
    local TABAS_OutfitManagement = require("TABAS_OutfitManagement")
    TABAS_OutfitManagement.onReEquipActionQueue(self.character)
end

function TABAS_TakeBathOut:perform()
    setGameSpeed(1)
    TABAS_BathingUtils.endBathing(self.character, true, true)

    self:endingActionQueue()

    ISBaseTimedAction.perform(self)
end

function TABAS_TakeBathOut:getDuration()
    return -1
end

function TABAS_TakeBathOut:new(character, bathSession, animSpeed)
    local o = ISBaseTimedAction.new(self, character)
    o.bathSession = bathSession
    o.bathObj = o.bathSession.bathObj
    o.animSpeed = animSpeed
    o.maxTime = o:getDuration()

    -- TimedAction settings
    o.stopOnWalk = false
    o.stopOnRun  = false
    o.stopOnAim  = false
    o.useProgressBar = false
    o.ignoreHandsWounds = true
    o.caloriesModifier = 0.2
    return o
end
