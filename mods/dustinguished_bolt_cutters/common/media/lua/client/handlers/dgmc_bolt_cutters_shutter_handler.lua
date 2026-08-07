---@type DGMCShutterAction
local Action = require("actions/dgmc_bolt_cutters_shutter_action")
local BaseHandler = require("handlers/dgmc_bolt_cutters_base_handler")

local constants = require("dgmc_bolt_cutters_constants")
local utils = require("dgmc_bolt_cutters_utils")
local logger = require("dgmc_bolt_cutters_logger")

---@class DGMCShutterHandler: DGMCBaseHandler
local handler = BaseHandler:new(getText("ContextMenu_DGMC_Bolt_Cutters_Shutter_Cut"), true, constants.sandbox.allowShutters)

---@param lhs IsoObject
---@param rhs IsoObject
---@return boolean
local function sortComparator(lhs, rhs)
	local lhsSquare = lhs:getSquare()
	local rhsSquare = rhs:getSquare()

	local lhsX = lhsSquare:getX()
	local rhsX = rhsSquare:getX()

	if lhsX == rhsX then
		return lhsSquare:getY() < rhsSquare:getY()
	end

	return lhsX < rhsX
end

---@param player IsoPlayer
---@param target IsoObject
---@param boltCutters InventoryItem
function handler.onUseBoltCutters(player, target, boltCutters)
	logger.debug("shutterHandler:onUseBoltCutters", "activating on %s", target:getObjectName())
	local allShutters = Action.findAllShutterObjects(target)

	-- need to sort all the shutter objects by position, so our walking and looking logic will work
	table.sort(allShutters, sortComparator)
	local walkToward, lookToward = utils.determineFocalObjects(player, allShutters)

	utils.createPrepatoryActions(player, boltCutters, walkToward)

	ISTimedActionQueue.add(Action:new(player, lookToward, boltCutters, constants.animIndices.lowAnimIndex))
end

---@param objects PZArrayList<IsoObject>
---@return IsoObject?
---@return StrengthIndices
function handler.getTargetObjectImpl(objects)
	for i = 0, objects:size() - 1 do
		local object = objects:get(i)
		if Action.isShutter(object) == true then
			logger.debug("shutterHandler:getTargetObjectImpl", "found shutter %s", object:getObjectName())
			return object, constants.strengthIndices.mediumIndex
		end
	end

	logger.debug("shutterHandler:getTargetObjectImpl", "did not find any shutter object")
	return nil, -1
end

local function onGameStart()
	local options = require("dgmc_bolt_cutters_options")
	options.addListener(constants.sandbox.allowShutters, function(new, old) handler:onEnabledChange(new, old) end)
end
Events.OnGameStart.Add(onGameStart)

return handler