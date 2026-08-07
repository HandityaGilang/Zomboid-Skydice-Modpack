---@type DGMCGarageAction
local Action = require "actions/dgmc_bolt_cutters_garage_action"
local BaseHandler = require("handlers/dgmc_bolt_cutters_base_handler")

local constants = require("dgmc_bolt_cutters_constants")
local utils = require("dgmc_bolt_cutters_utils")
local logger = require("dgmc_bolt_cutters_logger")

---@class DGMCGarageHandler: DGMCBaseHandler
local handler = BaseHandler:new(getText("ContextMenu_DGMC_Bolt_Cutters_Garage_Cut"), true, constants.sandbox.allowGarageDoors)

---@param objects PZArrayList<IsoObject>
---@return IsoObject?
---@return StrengthIndices
function handler.getTargetObjectImpl(objects)
	for i = 0, objects:size() - 1 do
		local object = objects:get(i)
		
		-- if it's a door, and it's closed and locked
		---@diagnostic disable-next-line
		if instanceof(object, "IsoDoor") == true and object:IsOpen() == false and object:isLocked() == true then
			local str = tostring(object)
			logger.debug("garageHandler:getTargetObjectImpl", "found potential door %s", str)

			-- make sure it's a garage door
			if string.find(str, "garage") ~= nil or string.find(str, "industry_truck") ~= nil then
				logger.debug("garageHandler:getTargetObjectImpl", "found garage door %s", str)
				return object, constants.strengthIndices.mediumIndex
			end
		end
	end

	return nil, -1
end

---@param player IsoPlayer
---@param target IsoObject
---@param boltCutters InventoryItem
function handler.onUseBoltCutters(player, target, boltCutters)
	logger.debug("garageHandler:onUseBoltCutters", "activating on %s", target:getObjectName())

	local targets = Action.getAllGarageDoorObjects(target)
	local walkToward, lookToward = utils.determineFocalObjects(player, targets)

	utils.createPrepatoryActions(player, boltCutters, walkToward)
	ISTimedActionQueue.add(Action:new(player, lookToward, boltCutters, constants.animIndices.lowAnimIndex))
end

local function onGameStart()
	local options = require("dgmc_bolt_cutters_options")
	options.addListener(constants.sandbox.allowGarageDoors, function(new, old) handler:onEnabledChange(new, old) end)
end
Events.OnGameStart.Add(onGameStart)

return handler