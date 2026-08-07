require("TimedActions/ISBaseTimedAction")

local constants = require("dgmc_bolt_cutters_constants")
local utils = require "dgmc_bolt_cutters_utils"

---@class DGMCShutterAction: ISBaseTimedAction
---@field boltCutters InventoryItem
---@field target IsoObject
---@field animIndex integer
local action = ISBaseTimedAction:derive("DGMC_BoltCutterShutterAction")
local shutterOne = "location_shop_mall_01_19"
local shutterTwo = "location_shop_mall_01_18"

---@param target IsoObject
---@return IsoDirections
local function getSearchDirection(target)
	if target:isWallN() == true then
		return IsoDirections.W
	end

	return IsoDirections.N
end

---@param object IsoObject
---@return boolean
function action.isShutter(object)
	if object:isWall() == true then
		local str = tostring(object)
		return string.find(str, shutterOne) ~= nil or string.find(str, shutterTwo) ~= nil
	end

	return false
end

---@param objects PZArrayList<IsoObject>
---@return IsoObject?
local function findShutter(objects)
	for i = 1, objects:size() - 1 do
		local object = objects:get(i)
		if action.isShutter(object) == true then
			return object
		end
	end

	return nil
end

---@param target IsoObject
---@param direction IsoDirections
---@param results table
local function findAllAdjacentShutters(target, direction, results)
	local square = target:getSquare()
	local adjacent = square:getAdjacentSquare(direction)
	local objects = adjacent:getObjects()

	local shutter = findShutter(objects)
	if shutter ~= nil then
		table.insert(results, shutter)
		findAllAdjacentShutters(shutter, direction, results)
	end
end

---@param target IsoObject
---@return IsoObject[]
function action.findAllShutterObjects(target)
	local direction = getSearchDirection(target)

	local allShutters = {}
	findAllAdjacentShutters(target, direction, allShutters)
	findAllAdjacentShutters(target, direction:Rot180(), allShutters)
	table.insert(allShutters, target)

	return allShutters
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
	
	local targets = self.findAllShutterObjects(self.target)

	for i = 1, #targets do
		local obj = targets[i]
		local square = obj:getSquare()

		square:transmitRemoveItemFromSquare(obj)
		
		utils.removeBloodOverlays(square)

		square:RecalcAllWithNeighbours(true)
	end

	local commandArgs = { playerID = self.character:getPlayerNum() }
	if server == true then
		sendServerCommand(self.character, constants.module, constants.commands.shutter, commandArgs)
	else
		DGMC_BoltCutterClient.onServerCommand(constants.module, constants.commands.shutter, commandArgs)
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
	---@type DGMCShutterAction
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