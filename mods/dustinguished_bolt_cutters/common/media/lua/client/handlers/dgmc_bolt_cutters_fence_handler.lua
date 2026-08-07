local Action = require("actions/dgmc_bolt_cutters_fence_action")
local BaseHandler = require("handlers/dgmc_bolt_cutters_base_handler")

local utils = require("dgmc_bolt_cutters_utils")
local constants = require("dgmc_bolt_cutters_constants")
local logger = require("dgmc_bolt_cutters_logger")
local fenceData = require("handlers/dgmc_bolt_cutters_fence_data")

local wireChance = 0
local rng = newrandom()

---@class DGMCFenceHandler: DGMCBaseHandler
local handler = BaseHandler:new(getText("ContextMenu_DGMC_Bolt_Cutters_Fence_Cut"), false, constants.sandbox.allowFences)

---@param objects PZArrayList<IsoObject>
---@return IsoObject?
---@return StrengthIndices
function handler.getTargetObjectImpl(objects)
	for i = 0, objects:size() - 1 do
		local object = objects:get(i)
		local sprite = object:getSprite()

		if sprite ~= nil then
			local spriteName = sprite:getName()
			local data = fenceData[spriteName]

			if data ~= nil then
				logger.debug("fenceHandler:getTargetObjectImpl", "%s has [%i, %i]", spriteName, data[1], data[2])
				return object, data[2]
			else
				logger.debug("fenceHandler:getTargetObjectImpl", "no data for %s", spriteName)
			end
		else
			logger.debug("fenceHandler:getTargetObjectImpl", "sprite was nil for %s", object:getObjectName())
		end
	end

	return nil, -1
end

---@param player IsoPlayer
---@param target IsoObject
---@param boltCutters InventoryItem
function handler.onUseBoltCutters(player, target, boltCutters)
	local name = target:getSprite():getName()	
	logger.debug("fenceHandler:onUseBoltCutters", "activating on %s", name)
	
	local data = fenceData[name]
	if data == nil then
		logger.error("fenceHandler:onUseBoltCutters", "data was nil for %s", name)
		return
	end

	utils.createPrepatoryActions(player, boltCutters, target)

	local resourceIndex = -1
	if rng:random(1, 100) <= wireChance then
		local resourceIndices = data[3]
		local chosen = rng:random(1, #resourceIndices)

		---@diagnostic disable-next-line
		resourceIndex = resourceIndices[chosen]
	end

	local animIndex = data[1]
	ISTimedActionQueue.add(Action:new(player, target, boltCutters, animIndex, resourceIndex))
end

---@param new integer
---@param old integer
local function onWireChanceChange(new, old)
	logger.debug("onwWireChanceChange", "changing from %i to %i", old, new)
	wireChance = new
end

local function onGameStart()
	local options = require("dgmc_bolt_cutters_options")
	options.addListener(constants.sandbox.allowFences, function(new, old) handler:onEnabledChange(new, old) end)
	options.addListener(constants.sandbox.fenceWireChance, onWireChanceChange)
end
Events.OnGameStart.Add(onGameStart)

return handler