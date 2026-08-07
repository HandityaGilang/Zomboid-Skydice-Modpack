require "TimedActions/ISBaseTimedAction"

TABAS_TakeBathWashSelf = ISBaseTimedAction:derive("TABAS_TakeBathWashSelf")

local TABAS_Utils = require("TABAS_Utils")
local TABAS_Sounds = require("TABAS_Sounds")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_AnimVariables = require("Bathing/TABAS_AnimVariables")

function TABAS_TakeBathWashSelf:isValid()
    return self.bathSession ~= nil and TABAS_BathingUtils.isTakingBath(self.character)
end

function TABAS_TakeBathWashSelf:update()
end

function TABAS_TakeBathWashSelf:getWashPart()
    if not self.bathSession then return "Face" end

    if self.washPart and self.washPart ~= "" then
        self.bathSession.prevWashPart = self.washPart
        return self.washPart
    end

    local part = self.washParts[1]
    local makeOff = self.bathSession.makeOff
    if makeOff and TABAS_BathingUtils.hasMakeUp(self.character) then
        part = "Face"
    elseif self.bathSession.prevWashPart and self.bathSession.prevWashPart == part then
        part = self.washParts[2]
    end
    self.bathSession.prevWashPart = part
    return part
end

function TABAS_TakeBathWashSelf.getRequiredWater(playerObj, includeCloth)
    local blood, dirt = TABAS_Utils.getBodyBloodAndDirt(playerObj)
    local grime = TABAS_Utils.getBodyGrimeDisplay(playerObj) * 0.5
    local total = (blood + dirt + grime) * SandboxVars.TakeABathAndShower.WashInBathConsumeWater

    if includeCloth then
        blood, dirt = TABAS_Utils.getClothingBloodAndDirt(playerObj)
        total = total + ((blood + dirt) * SandboxVars.TakeABathAndShower.WashInBathConsumeWater)
    end
    return math.ceil(total)
end

function TABAS_TakeBathWashSelf:start()
    local washPart = self:getWashPart()
    TABAS_Utils.debugPrint("TakeBathWashSelf", "WashPart = ".. washPart)

	self:setActionAnim("TABAS_TakeBath_Wash")
    self:setAnimVariable("TABAS_WashPart", washPart)
	self:setOverrideHandModels(nil, nil)

    self.waterRequired = self.getRequiredWater(self.character)
end

function TABAS_TakeBathWashSelf:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

function TABAS_TakeBathWashSelf:stop()
    self:stopSound()
    if self.bathSession.isAutoMode == true then
        self.bathSession.isAutoMode = false
    end
    ISBaseTimedAction.stop(self)
end

function TABAS_TakeBathWashSelf:animEvent(event, parameter)
    if event == "TABAS_PlayWashSound" then
        if not self.sound then
            self.sound = TABAS_Sounds.playPlayerSound(self.character, "tabas_bath_wash")
        end
    elseif event == "TABAS_PlaySound" and parameter ~= "" then
        TABAS_Sounds.playPlayerSound(self.character, parameter)

    elseif event == "TABAS_WashCleansed" then
        TABAS_BathingUtils.washCleansedBody(self.character, nil, 1, 0.85, self.makeOff)

        -- The water used is consumed of when player get out of the bath.
        local tfc_Base = self.bathSession and self.bathSession.getTfc and self.bathSession:getTfc() or nil
        local currentAmount = tfc_Base and (tfc_Base:getAmount() or 0) or 0
        local consumed = math.min(self.waterRequired or 0, currentAmount)
        self.bathSession.consumedWater = self.bathSession.consumedWater + consumed
        self.bathSession.makeOff = false
        TABAS_Utils.debugPrint("TABAS_WashCleansed", "Done")

    elseif parameter == "TABAS_WashPartFinished=true" then
        self:forceComplete()
    end
end

function TABAS_TakeBathWashSelf:perform()
    self:stopSound()
    if self.bathSession then
        self.bathSession.washCount = (self.bathSession.washCount or 0) + 1
    end
    ISBaseTimedAction.perform(self)
end

function TABAS_TakeBathWashSelf:getDuration()
    return -1
end

function TABAS_TakeBathWashSelf:new(character, bathSession, washPart)
    local o = ISBaseTimedAction.new(self, character)
    o.bathSession = bathSession
    o.washParts = TABAS_AnimVariables.getWashParts("BATH", character:isFemale(), true)
    o.washPart = washPart
    o.maxTime = o:getDuration()
    o.ignoreHandsWounds = true
    o.useProgressBar = false
    -- o.stopOnWalk = false
    -- o.stopOnRun = false
    -- o.stopOnAim = false
    return o
end
