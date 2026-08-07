require("TimedActions/ISBaseTimedAction")

local constants = require("dgmc_bolt_cutters_constants")
local utils = require("dgmc_bolt_cutters_utils")
local logger = require("dgmc_bolt_cutters_logger")

local rng = newrandom()

---@class DGMCFenceAction: ISBaseTimedAction
---@field boltCutters InventoryItem
---@field target IsoObject
---@field animIndex integer
---@field resourceIndex integer
local action = ISBaseTimedAction:derive("DGMC_BoltCutterFenceAction")

---@return number
function action:getDuration()
	return utils.calculateDuration(self.character)
end

---@return boolean
function action:isValid()
	if self.character == nil or self.character:isDead() == true then
		return false
	end

	if self.boltCutters == nil then
		return false
	end
	
	if self.target == nil then
		return false
	end

	return true
end

---@return boolean
function action:waitToStart()
	self.character:faceThisObject(self.target)
	return self.character:shouldBeTurning()
end

function action:update()
	self.character:setMetabolicTarget(Metabolics.HeavyWork)
end

function action:start()
	---@diagnostic disable-next-line
	self:setActionAnim(constants.anims[self.animIndex])
	self:setOverrideHandModels(self.boltCutters, nil)
end

---@return boolean
function action:complete()
	local server = isServer()
	
	local square = self.target:getSquare()

	square:transmitRemoveItemFromSquare(self.target)
	
	utils.removeBloodOverlays(square)

	square:RecalcAllWithNeighbours(true)

	local commandArgs = { playerID = self.character:getPlayerNum() }
	if server == true then
		sendServerCommand(self.character, constants.module, constants.commands.fence, commandArgs)
	else
		DGMC_BoltCutterClient.onServerCommand(constants.module, constants.commands.fence, commandArgs)
	end

	utils.handleMuscleStrain(self.character)
	utils.handleXP(self.character, self.boltCutters)

	if self.resourceIndex > 0 then
		local resourceName = constants.resources[self.resourceIndex]
		if resourceName == nil then
			logger.error("fenceAction:complete", "unknown resource index %i", self.resourceIndex)
			return true
		end

		local item = instanceItem(resourceName)

		if self.resourceIndex == constants.resourceIndices.wire then
			local uses = rng:random(1, 10) / 10.0
			logger.debug("fenceAction:complete", "setting uses to %f", uses)
			item:setCurrentUsesFloat(uses)
		else
			local condition = rng:random(1, item:getConditionMax())
			logger.debug("fenceAction:complete", "setting durability to %f", condition)
			item:setConditionNoSound(condition)
		end
		
		square:AddWorldInventoryItem(item, 0.0, 0.0, 0.0)
		item:SynchSpawn()
	end

	return true
end

---@param character IsoPlayer
---@param target IsoObject
---@param boltCutters InventoryItem
---@param animIndex AnimIndices
---@param resourceIndex ResourceIndices
---@return ISBaseTimedAction
function action:new(character, target, boltCutters, animIndex, resourceIndex)
	---@type DGMCFenceAction
	local newAction = ISBaseTimedAction.new(self, character)
	newAction.target = target
	newAction.boltCutters = boltCutters
	newAction.animIndex = animIndex
	newAction.resourceIndex = resourceIndex
	newAction.maxTime = newAction:getDuration()
	newAction.stopOnWalk = true
	newAction.stopOnRun = true
	newAction.stopOnAim = true
	newAction.useProgressBar = true

	return newAction
end

_G[action.Type] = action
return action