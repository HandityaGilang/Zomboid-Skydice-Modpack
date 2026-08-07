require "TimedActions/ISBaseTimedAction"

TABAS_DrySelf = ISBaseTimedAction:derive("TABAS_DrySelf")

local TABAS_Utils = require("TABAS_Utils")
local TABAS_GameTimes = require("TABAS_GameTimes")

function TABAS_DrySelf.hasBathingWet(character)
    local md = character:getModData()
    local wetEndH = md.tabas_WetEndH
    return wetEndH and wetEndH > TABAS_GameTimes.getWorldAgeHours()
end

function TABAS_DrySelf:isValid()
    return true
end

function TABAS_DrySelf:waitToStart()
    if self.character:isCurrentState(ClimbOverFenceState.instance()) then
        return true
    end
    return self.character:shouldBeTurning()
end

function TABAS_DrySelf:update()
    if not self.doDry then
        self:forceComplete()
    end
end

function TABAS_DrySelf:serverStart()
    local wetActive = TABAS_DrySelf.hasBathingWet(self.character)
    local curWet = self.character:getStats():get(CharacterStat.WETNESS) or 0
    self.doDry = (self.towel ~= nil) and (wetActive or curWet > 20)
end

function TABAS_DrySelf:start()
    local wetActive = TABAS_DrySelf.hasBathingWet(self.character)
    local curWet = self.character:getStats():get(CharacterStat.WETNESS) or 0
    self.doDry = (self.towel ~= nil) and (wetActive or curWet > 20)

    if self.doDry and not self.isBTO then
        self:setActionAnim("TABAS_DryYourSelf")
        self:setOverrideHandModels(nil, self.towel)
        self.sound = self.character:playSound("FirstAidCleanBurn")
    end

    if (not self.doDry) and (not (MF or TABAS_Compat.MF)) and wetActive and curWet < 50 then
        TABAS_Utils.increaseCharacterWetness(self.character, 50 - curWet)
    end
end

function TABAS_DrySelf:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound)
    end
end

function TABAS_DrySelf:stop()
    self:stopSound()
    ISBaseTimedAction.stop(self)
end

function TABAS_DrySelf:perform()
    self:stopSound()
    if self.doDry and self.isBTO then
        -- Queue the BTO wipe immediately after this action, before any later queueActions wrappers.
        self:beginAddingActions()
        ISTimedActionQueue.add(BTO_WipeMySelf:new(self.character, self.towel, true, false, 70))
        self:endAddingActions()
    end
    ISBaseTimedAction.perform(self)
end

function TABAS_DrySelf:complete()
    if self.doDry then
        self.character:getModData().tabas_WetEndH = nil
        self.character:transmitModData()

        if not self.isBTO then
            local curWet = self.character:getStats():get(CharacterStat.WETNESS) or 0
            if curWet > 0 then
                TABAS_Utils.decreaseCharacterWetness(self.character, curWet)
            end
            self.towel:setCurrentUsesFloat(0)
            self.towel:syncItemFields()
        end
    end
    return true
end

function TABAS_DrySelf:adjustMaxTime(maxTime)
    return maxTime
end

function TABAS_DrySelf:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    if self.towel and not self.isBTO then
        return 160
    end
    return 0
end

function TABAS_DrySelf:new(character, towel)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self

    o.character = character
    o.towel = towel
    o.isBTO = TABAS_Compat.BTO and towel and towel:hasTag(BTO_Tag.Wipeable)

    o.doDry = false
    o.maxTime = o:getDuration()

    o.ignoreHandsWounds = true
    return o
end
