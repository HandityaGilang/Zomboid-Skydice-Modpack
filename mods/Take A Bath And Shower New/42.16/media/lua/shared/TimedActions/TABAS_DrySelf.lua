require "TimedActions/ISBaseTimedAction"

TABAS_DrySelf = ISBaseTimedAction:derive("TABAS_DrySelf")

local TABAS_Utils = require("TABAS_Utils")

function TABAS_DrySelf.hasBathingWet(character)
    local md = character:getModData()
    return md.tabas_HasBathingWet == true
end

function TABAS_DrySelf:isValid()
    if not self.isManual then
        return true
    end

    local wetActive = TABAS_DrySelf.hasBathingWet(self.character)
    local curWet = self.character:getStats():get(CharacterStat.WETNESS) or 0
    if not wetActive and curWet <= 20 then
        return false
    end

    local towel = self.towel
    if isClient() and self.towelId then
        local inv = self.character:getInventory()
        if inv then
            towel = inv:getItemById(self.towelId) or towel
        end
    end

    return towel ~= nil and TABAS_Utils.isAvailableBathTowel(towel)
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
        return
    end

    if self.towel and not self.isBTO then
        self.towel:setJobDelta(self:getJobDelta())
    end
end

function TABAS_DrySelf:serverStart()
    local wetActive = TABAS_DrySelf.hasBathingWet(self.character)
    local curWet = self.character:getStats():get(CharacterStat.WETNESS) or 0
    self.doDry = (self.towel ~= nil) and (wetActive or curWet > 20)
end

function TABAS_DrySelf:start()
    if isClient() and self.towelId then
        local inv = self.character:getInventory()
        if inv then
            self.towel = inv:getItemById(self.towelId) or self.towel
        end
    end
    self.isBTO = TABAS_Compat.BTO and self.towel and self.towel:hasTag(BTO_Tag.Wipeable)

    local wetActive = TABAS_DrySelf.hasBathingWet(self.character)
    local curWet = self.character:getStats():get(CharacterStat.WETNESS) or 0
    self.doDry = (self.towel ~= nil) and (wetActive or curWet > 20)

    if self.doDry then
        if self.isBTO then
            local altAction = BTO_WipeMySelf:new(self.character, self.towel, true, false, 70)
            self:addAfter(altAction)
        else
            self:setActionAnim("TABAS_DryYourSelf")
            self:setOverrideHandModels(nil, self.towel)
            self.sound = self.character:playSound("FirstAidCleanBurn")
        end
    end

    if (not self.doDry) and (not (MF and MF.getMoodle ~= nil)) and wetActive and curWet < 50 then
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
    if self.towel then
        self.towel:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function TABAS_DrySelf:perform()
    self:stopSound()
    if self.towel then
        self.towel:setJobDelta(0.0)
    end
    if self.doDry then
        triggerEvent("OnBathingStateFinished", self.character)
    end
    ISBaseTimedAction.perform(self)
end

function TABAS_DrySelf:syncItemUses()
    if not self.towel or not isServer() then
        return
    end

    local numberOfUses = self.towel:getCurrentUses()
    for i = 1, numberOfUses do
        if i == numberOfUses then
            self.towel:UseAndSync()
        else
            self.towel:Use()
        end
    end
end

function TABAS_DrySelf:complete()
    if self.doDry and not self.isBTO then
        local curWet = self.character:getStats():get(CharacterStat.WETNESS) or 0
        if curWet > 0 then
            TABAS_Utils.decreaseCharacterWetness(self.character, curWet)
        end
        self:syncItemUses()
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

function TABAS_DrySelf:new(character, towel, isManual)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self

    o.character = character
    o.towel = towel
    o.towelId = towel and towel:getID() or nil
    o.isBTO = TABAS_Compat.BTO and towel and towel:hasTag(BTO_Tag.Wipeable)
    o.isManual = isManual == true

    o.doDry = false
    o.maxTime = o:getDuration()

    o.ignoreHandsWounds = true
    return o
end
