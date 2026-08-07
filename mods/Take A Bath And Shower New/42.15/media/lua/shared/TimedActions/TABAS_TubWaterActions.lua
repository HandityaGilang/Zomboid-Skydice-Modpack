require "TimedActions/ISBaseTimedAction"

TABAS_TubWaterAction = ISBaseTimedAction:derive("TABAS_TubWaterAction")

local TABAS_Utils = require("TABAS_Utils")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")
local TABAS_Sounds = require("TABAS_Sounds")

function TABAS_TubWaterAction:isValid()
    if not self.tfc_Base then return false end
    if self.tfc_Base:hasTfc() then
        if self.turnOn then
            if self.state == "empty" or self.state == "reheat" then
                return not self.tfc_Base:isEmpty()
            elseif self.state == "fill" then
                return not self.tfc_Base:isFull()
            end
        else
            return self.tfc_Base:isActivated(self.state)
        end
    end
    return false
end

function TABAS_TubWaterAction:waitToStart()
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

function TABAS_TubWaterAction:update()
end

function TABAS_TubWaterAction:start()
    self:setOverrideHandModels(nil, nil)
    self:setActionAnim("TABAS_TubHandling")
end

function TABAS_TubWaterAction:serverStart()
    emulateAnimEventOnce(self.netAction, 1500, "TABAS_PlaySound", nil)
end

function TABAS_TubWaterAction:animEvent(event, parameter)
    if event == "TABAS_PlaySound" then
        if isServer() then
            self.netAction:forceComplete()
        elseif not self.sound then
            local sound = ""
            if self.state == "fill" then
                 sound = "tabas_turntap"
            elseif self.state == "reheat" then
                 sound = "ToggleStove"
            elseif self.state == "empty" then
                if self.turnOn then
                    sound = "tabas_tub_removestopper"
                else
                    sound = "tabas_tub_putstopper"
                end
            end
            self.sound = TABAS_Sounds.playPlayerSound(self.character, sound)
            self:forceComplete()
        end
    end
end

function TABAS_TubWaterAction:stop()
    if self.wasSneaking then self.character:setSneaking(true) end
    ISBaseTimedAction.stop(self)
end

function TABAS_TubWaterAction:perform()
    if self.wasSneaking then self.character:setSneaking(true) end
    ISBaseTimedAction.perform(self)
end

function TABAS_TubWaterAction:complete()
    local tfc_Base = TFC_Utils.getTfcBaseOnServer(self.tfc_Base.x, self.tfc_Base.y, self.tfc_Base.z, self.tfc_Base.bathObject)
    if tfc_Base then
        tfc_Base:triggerActivate(self.character, self.state, self.turnOn)
    end
    return true
end

function TABAS_TubWaterAction:adjustMaxTime(maxTime)
    return maxTime
end

function TABAS_TubWaterAction:getDuration()
    return 20
end

function TABAS_TubWaterAction:new(character, tfc_Base, state, turnOn)
    local o = ISBaseTimedAction.new(self, character)
    o.tfc_Base = tfc_Base
    o.state = state
    o.turnOn = turnOn
    o.maxTime = o:getDuration()

    o.stopOnWalk = false
    o.stopOnRun  = false
    o.stopOnAim  = false
    o.ignoreHandsWounds = true
    o.useProgressBar = false
    o.caloriesModifier = 0
    return o
end