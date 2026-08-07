require "TimedActions/ISBaseTimedAction"

TABAS_TubStopperPutAction = ISBaseTimedAction:derive("TABAS_TubStopperPutAction")

local TABAS_Utils = require("TABAS_Utils")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")
local TABAS_Sounds = require("TABAS_Sounds")

function TABAS_TubStopperPutAction:isValid()
    if self.tfc_Base then
        local tfc_Base = TFC_Utils.getTfcBaseOnClient(self.tfc_Base.x, self.tfc_Base.y, self.tfc_Base.z, self.tfc_Base.bathObject)
        if tfc_Base and tfc_Base:hasTfc() then
            return false
        end
    end
    return self.tfc_Base and not self.tfc_Base:hasTfc()
end

function TABAS_TubStopperPutAction:waitToStart()
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

function TABAS_TubStopperPutAction:update()
end

function TABAS_TubStopperPutAction:start()
    self:setOverrideHandModels(nil, nil)
    self:setActionAnim("TABAS_TubHandling")
end

function TABAS_TubStopperPutAction:serverStart()
    emulateAnimEventOnce(self.netAction, 1500, "TABAS_PlaySound", nil)
end

function TABAS_TubStopperPutAction:animEvent(event, parameter)
    if event == "TABAS_PlaySound" then
        if isServer() then
            self.netAction:forceComplete()
        elseif not self.sound then
            self.sound = TABAS_Sounds.playPlayerSound(self.character, "tabas_tub_putstopper")
            self:forceComplete()
        end
    end
end

function TABAS_TubStopperPutAction:stop()
    if self.wasSneaking then self.character:setSneaking(true) end
	ISBaseTimedAction.stop(self)
end

function TABAS_TubStopperPutAction:perform()
    if self.wasSneaking then self.character:setSneaking(true) end
    ISBaseTimedAction.perform(self)
end

function TABAS_TubStopperPutAction:complete()
    local tfc_Base = TFC_Utils.getTfcBaseOnServer(self.tfc_Base.x, self.tfc_Base.y, self.tfc_Base.z, self.tfc_Base.bathObject)
    if tfc_Base then
        tfc_Base:create()
    end
    return true
end

function TABAS_TubStopperPutAction:adjustMaxTime(maxTime)
    return maxTime
end

function TABAS_TubStopperPutAction:getDuration()
    return 20
end

function TABAS_TubStopperPutAction:new(character, tfc_Base)
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