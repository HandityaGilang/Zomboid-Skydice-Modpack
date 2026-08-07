require "TimedActions/ISBaseTimedAction"

TABAS_TakeBathOut = ISBaseTimedAction:derive("TABAS_TakeBathOut")

local TABAS_Utils = require("TABAS_Utils")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_AnimVariables = require("Bathing/TABAS_AnimVariables")
local TABAS_Sounds = require("TABAS_Sounds")
require("TimedActions/TABAS_ReEquipItems")
local TABAS_ReEquipItemsUtils = require("TABAS_ReEquipItemsUtils")

function TABAS_TakeBathOut:isValid()
    return true
end

function TABAS_TakeBathOut:waitToStart()
    return false
end

function TABAS_TakeBathOut:update()
end

function TABAS_TakeBathOut:start()
    local sq = self.bathObj:getSquare()
    self.tfc_Base = TFC_Utils.getTfcBaseOnClient(sq:getX(), sq:getY(), sq:getZ(), self.bathObj)

    TABAS_AnimVariables.clearVariables(self.character, "BATH")

    local getupSpeed = self.animSpeed or (self.character:getVariableBoolean("pressedRunButton") and 2.5 or 1.2)
    local currentSq = self.character:getCurrentSquare()
    if currentSq then
        local movingObjects = currentSq:getMovingObjects()
        for i = 0, movingObjects:size() - 1 do
            local obj = movingObjects:get(i)
            if obj ~= self.character
            and not obj:isOnFloor()
            and (instanceof(obj, "IsoZombie") or instanceof(obj, "IsoPlayer")) then
                getupSpeed = math.max(getupSpeed, 2.5)
                break
            end
        end
    end
    self.character:setVariable("BathGetupSpeed", getupSpeed)
    self:setActionAnim("TABAS_BathOut")
end

function TABAS_TakeBathOut:animEvent(event, parameter)
    if event == "TABAS_PlaySound" then
        if self.tfc_Base then
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

function TABAS_TakeBathOut:perform()
    setGameSpeed(1)
    TABAS_BathingUtils.endBathing(self.character, true, true)

    if self.exitPrepSq then
        if self.exitTargetSq and self.baseSq ~= self.exitTargetSq then
            ISTimedActionQueue.add(ISWalkToTimedAction:new(self.character, self.exitTargetSq))
        end
        ISTimedActionQueue.add(ISWalkToTimedAction:new(self.character, self.exitPrepSq))

        local towel = self.exitTowel or TABAS_Utils.getAvailableTowel(self.character)
        ISTimedActionQueue.add(TABAS_DrySelf:new(self.character, towel))
        ISTimedActionQueue.queueActions(self.character, TABAS_ReEquipItemsUtils.queueAll)
    end

    ISBaseTimedAction.perform(self)
end

function TABAS_TakeBathOut:complete()
    return true
end

function TABAS_TakeBathOut:getDuration()
    return 150
end

function TABAS_TakeBathOut:new(character, bathObjOrSession, animSpeed, towel)
    local o = ISBaseTimedAction.new(self, character)

    local session = nil
    local bathObj = bathObjOrSession
    if bathObjOrSession and bathObjOrSession.bathObj then
        session = bathObjOrSession
        bathObj = session.bathObj
    end

    o.bathObj = bathObj
    o.baseSq = session and session.baseSq or (bathObj and bathObj:getSquare()) or nil
    o.animSpeed = animSpeed
    o.exitPrepSq = session and session.prepSq or nil
    o.exitTargetSq = session and session.climbSq or nil
    o.exitTowel = towel or (session and session.exitTowel or nil)
    o.maxTime = o:getDuration()
    o.useProgressBar = false

    -- TimedAction settings
    o.stopOnWalk = false
    o.stopOnRun  = false
    o.stopOnAim  = false
    o.ignoreHandsWounds = true
    o.caloriesModifier = 0.2
    return o
end
