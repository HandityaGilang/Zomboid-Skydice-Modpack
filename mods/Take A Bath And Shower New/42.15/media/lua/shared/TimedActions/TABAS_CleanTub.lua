require "TimedActions/ISBaseTimedAction"

TABAS_CleanTub = ISBaseTimedAction:derive("TABAS_CleanTub")

local TABAS_Utils = require "TABAS_Utils"

function TABAS_CleanTub:isValid()
	local playerInv = self.character:getInventory()
	return (playerInv:containsEvalRecurse(TABAS_Utils.predicateBleach) or playerInv:containsEvalRecurse(TABAS_Utils.predicateCleaningLiquid)) and (playerInv:containsTagEval(ItemTag.CLEAN_STAINS, TABAS_Utils.predicateNotBroken))
end

function TABAS_CleanTub:waitToStart()
    self.character:faceLocation(self.faucetSq:getX(), self.faucetSq:getY())
	return self.character:shouldBeTurning()
end

function TABAS_CleanTub:update()
    local jobDelta = self:getJobDelta()
    if jobDelta < 0.5  then
        self.character:faceLocation(self.faucetSq:getX() + 0.5, self.faucetSq:getY() + 0.5)
    else
        self.character:faceLocation(self.tubSq:getX() + 0.5, self.tubSq:getY() + 0.5)
    end
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function TABAS_CleanTub:start()
    local primaryItem = self.character:getPrimaryHandItem()
    self:setActionAnim("ScrubFloor")
    self:setOverrideHandModels(primaryItem, self.cleaner)
    self.sound = self.character:playSound("CleanBloodBleach")
end

function TABAS_CleanTub:stop()
    self.character:stopOrTriggerSound(self.sound)
	ISBaseTimedAction.stop(self)
end


function TABAS_CleanTub:perform()
    self.character:stopOrTriggerSound(self.sound)

    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

function TABAS_CleanTub:complete()
    local cleaner = self.cleaner
    if cleaner then
		cleaner:getFluidContainer():adjustAmount(cleaner:getFluidContainer():getAmount() - ZomboidGlobals.CleanBloodBleachAmount)
    end

    local md = self.faucetObj:getModData()
    local newSpriteKey = md.isImproved and "tabas_fixtures_bathroom_03" or "tabas_fixtures_bathroom_01"
    local modData = {isClean = true}
    TABAS_ImprovedTubAction.replaceObject(self.faucetObj, self.faucetSq, newSpriteKey, modData)
    TABAS_ImprovedTubAction.replaceObject(self.tubObj, self.tubSq, newSpriteKey, modData)
	return true
end


function TABAS_CleanTub:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 500
end

function TABAS_CleanTub:new(character, faucetObj, tubObj, cleaner, container)
    local o = ISBaseTimedAction.new(self, character)
    o.faucetObj = faucetObj
    o.tubObj = tubObj
    o.faucetSq = faucetObj:getSquare()
    o.tubSq = tubObj:getSquare()
    o.cleaner = cleaner

    o.maxTime = o:getDuration()
    o.caloriesModifier = 5
    return o
end