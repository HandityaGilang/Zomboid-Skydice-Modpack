require "TimedActions/ISBaseTimedAction"

TABAS_TubStopperRemoveAction = ISBaseTimedAction:derive("TABAS_TubStopperRemoveAction")

local TABAS_Utils = require("TABAS_Utils")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")
local TABAS_Sounds = require("TABAS_Sounds")

function TABAS_TubStopperRemoveAction:isValid()
    return self.tfc_Base ~= nil and self.tfc_Base:hasTfc()
end

function TABAS_TubStopperRemoveAction:waitToStart()
    local char = self.character
    if char:getModData().tabas_IsBathing then
        return false
    end
    if self.shouldBeStandUp == nil then
        self.shouldBeStandUp = not TABAS_Utils.isAleadyInTub(char, self.tfc_Base)
    end
    if self.shouldBeStandUp then
        local wasSneaking = char:isSneaking()
        if self.wasSneaking == nil then
            self.wasSneaking = wasSneaking
        end
        if wasSneaking then
            char:setSneaking(false)
        end
        if TABAS_Utils.waitFrames(self, 40, wasSneaking) then
            return true
        end
    end
    char:faceThisObject(self.tfc_Base.bathObject)
    return char:shouldBeTurning()
end

function TABAS_TubStopperRemoveAction:update()
end

function TABAS_TubStopperRemoveAction:start()
    self:setOverrideHandModels(nil, nil)
    self:setActionAnim("TABAS_TubHandling")
end

function TABAS_TubStopperRemoveAction:serverStart()
    emulateAnimEventOnce(self.netAction, 400, "TubStopperRemoveActionFinished", nil)
end

function TABAS_TubStopperRemoveAction:animEvent(event, parameter)
    if event == "TABAS_PlaySound" then
        if not self.sound then
            self.sound = TABAS_Sounds.playPlayerSound(self.character, "tabas_tub_putstopper")
            self:forceComplete()
        end
    elseif event == "TubStopperRemoveActionFinished" then
        self.netAction:forceComplete()
    end
end

function TABAS_TubStopperRemoveAction:stop()
    if self.wasSneaking then self.character:setSneaking(true) end
	ISBaseTimedAction.stop(self)
end

function TABAS_TubStopperRemoveAction:perform()
    if self.wasSneaking then self.character:setSneaking(true) end
    ISBaseTimedAction.perform(self)
end

function TABAS_TubStopperRemoveAction:complete()
    local tfc_Base = TFC_Utils.getTfcBaseOnServer(self.tfc_Base.x, self.tfc_Base.y, self.tfc_Base.z, self.tfc_Base.bathObject)
    if tfc_Base then
        tfc_Base:remove()
    end
    return true
end

function TABAS_TubStopperRemoveAction:getDuration()
    return -1
end

function TABAS_TubStopperRemoveAction:new(character, tfc_Base)
    local o = ISBaseTimedAction.new(self, character)
    o.tfc_Base = tfc_Base
    o.maxTime = o:getDuration()

    o.stopOnWalk = false
    o.stopOnRun  = false
    o.stopOnAim  = false
    o.ignoreHandsWounds = true
    o.useProgressBar = false
    o.caloriesModifier = 0
    return o
end