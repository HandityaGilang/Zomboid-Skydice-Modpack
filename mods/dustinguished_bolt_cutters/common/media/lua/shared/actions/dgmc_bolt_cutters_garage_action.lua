require("TimedActions/ISBaseTimedAction")

local constants = require("dgmc_bolt_cutters_constants")
local utils = require("dgmc_bolt_cutters_utils")

---@class DGMCGarageAction: ISBaseTimedAction
---@field boltCutters InventoryItem
---@field target IsoDoor
---@field animIndex integer
local action = ISBaseTimedAction:derive("DGMC_BoltCutterGarageAction")

---@param target IsoDoor
---@return IsoDoor[]
function action.getAllGarageDoorObjects(target)
	local doors = {}

	local door = IsoDoor.getGarageDoorFirst(target)
	if door ~= nil then
		while door ~= nil do
			table.insert(doors, door)
			door = IsoDoor.getGarageDoorNext(door)
		end
	end

	return doors
end

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

	if self.target:IsOpen() == true or self.target:isLocked() == false then
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

	local targets = self.getAllGarageDoorObjects(self.target)
	utils.unlockTargets(targets, server)

	local commandArgs = { playerID = self.character:getPlayerNum() }
	if server == true then
		sendServerCommand(self.character, constants.module, constants.commands.garage, commandArgs)
	else
		DGMC_BoltCutterClient.onServerCommand(constants.module, constants.commands.garage, commandArgs)
	end

	utils.handleMuscleStrain(self.character)
	utils.handleXP(self.character, self.boltCutters)
	
	return true
end

---@param character IsoPlayer
---@param target IsoObject
---@param boltCutters InventoryItem
---@param animIndex integer
---@return ISBaseTimedAction
function action:new(character, target, boltCutters, animIndex)
	---@type DGMCGarageAction
	local newAction = ISBaseTimedAction.new(self, character)
	newAction.target = target
	newAction.boltCutters = boltCutters
	newAction.animIndex = animIndex
	newAction.maxTime = newAction:getDuration()
	newAction.stopOnWalk = true
	newAction.stopOnRun = true
	newAction.stopOnAim = true
	newAction.useProgressBar = true

	return newAction
end

_G[action.Type] = action
return action