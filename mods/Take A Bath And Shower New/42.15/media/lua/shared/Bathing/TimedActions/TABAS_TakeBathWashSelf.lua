require "TimedActions/ISBaseTimedAction"

TABAS_TakeBathWashSelf = ISBaseTimedAction:derive("TABAS_TakeBathWashSelf")

local TABAS_Utils = require("TABAS_Utils")
local TABAS_Sounds = require("TABAS_Sounds")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_AnimVariables = require("Bathing/TABAS_AnimVariables")

function TABAS_TakeBathWashSelf:isValid()
    return TABAS_BathingUtils.isTakingBath(self.character)
end

function TABAS_TakeBathWashSelf:update()
end

function TABAS_TakeBathWashSelf:getWashPart()
    if self.washPart and self.washPart ~= "" then
        self.bathSession.prevWashPart = self.washPart
        return self.washPart
    end

    local part = self.washParts[1]
    local session = self.bathSession
    if not session or (self.makeOff and TABAS_BathingUtils.hasMakeUp(self.character)) then
        part = "Face"
    elseif session.prevWashPart and session.prevWashPart == part then
        part = self.washParts[2]
    end
    session.prevWashPart = part
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
    if not self.bathSession then
        local TABAS_TakeBathSession = require("Bathing/TABAS_TakeBathSession")
        self.bathSession = TABAS_TakeBathSession:get(self.character)
    end
    local washPart = self:getWashPart()
    TABAS_Utils.debugPrint("TakeBathWashSelf", "WashPart = ".. washPart)

	self:setActionAnim("TABAS_TakeBath_Wash")
    self:setAnimVariable("TABAS_WashPart", washPart)
	self:setOverrideHandModels(nil, nil)
    if washPart == "Arms" then
        self.character:playSound("WashYourself")
    end
    self.waterRequired = self.getRequiredWater(self.character)
end

function TABAS_TakeBathWashSelf:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

function TABAS_TakeBathWashSelf:stop()
    self:stopSound()
    if self.tabasAutoModeAction and self.bathSession then
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
        local wornItems = self.character:getWornItems()
        TABAS_BathingUtils.washCleansedBody(self.character, wornItems, 1, 0.85, self.makeOff)

        -- The water used is consumed of when player get out of the bath.
        local tfc_Base = self.bathSession and self.bathSession.getTfc and self.bathSession:getTfc() or nil
        local currentAmount = tfc_Base and (tfc_Base:getAmount() or 0) or 0
        local consumed = math.min(self.waterRequired or 0, currentAmount)
        self.bathSession.consumedWater = self.bathSession.consumedWater + consumed
        self.bathSession.makeOff = false
        TABAS_Utils.debugPrint(
            "BathWashWater",
            string.format(
                "required=%.2f, current=%.2f, added=%.2f, total=%.2f",
                self.waterRequired or 0,
                currentAmount,
                consumed,
                self.bathSession.consumedWater or 0
            )
        )

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

function TABAS_TakeBathWashSelf:complete()
    self.character:getStats():remove(CharacterStat.UNHAPPINESS, 2)
    return true
end

function TABAS_TakeBathWashSelf:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
    return 700
end

function TABAS_TakeBathWashSelf:new(character, bathSession, makeOff, washPart)
    local o = ISBaseTimedAction.new(self, character)
    o.washParts = TABAS_AnimVariables.getWashParts("BATH", character:isFemale(), true)
    o.bathSession = bathSession
    o.makeOff = makeOff or bathSession.makeOff
    o.washPart = washPart
    o.maxTime = o:getDuration()
    o.ignoreHandsWounds = true
    o.useProgressBar = false
    -- o.stopOnWalk = false
    -- o.stopOnRun = false
    -- o.stopOnAim = false
    return o
end
