---@type DGMCGateAction
local Action = require("actions/dgmc_bolt_cutters_gate_action")
local BaseHandler = require("handlers/dgmc_bolt_cutters_base_handler")

local constants = require("dgmc_bolt_cutters_constants")
local utils = require("dgmc_bolt_cutters_utils")
local logger = require("dgmc_bolt_cutters_logger")

---@class DGMCGateHandler: DGMCBaseHandler
local handler = BaseHandler:new(getText("ContextMenu_DGMC_Bolt_Cutters_Gate_Cut"), false, constants.sandbox.allowFenceGates)

---@param objects PZArrayList<IsoObject>
---@return IsoObject?
---@return StrengthIndices
function handler.getTargetObjectImpl(objects)
	for i = 0, objects:size() - 1 do
		local object = objects:get(i)
		
		---@diagnostic disable-next-line
		if instanceof(object, "IsoDoor") or (instanceof(object, "IsoThumpable") and object:isDoor()) then
			if object:IsOpen() == false and object:isLocked() == true then
				local str = tostring(object)
				logger.debug("gateHandler:getTargetObjectImpl", "found potential door %s", str)

				if string.find(str, "fence") ~= nil then
					logger.debug("gateHandler:getTargetObjectImpl", "found gate %s", str)
					return object, constants.strengthIndices.mediumIndex
				end
			end
		end
	end

	return nil, -1
end

---@param player IsoPlayer
---@param target IsoObject
---@param boltCutters InventoryItem
function handler.onUseBoltCutters(player, target, boltCutters)
	logger.debug("gateHandler:onUseBoltCutters", "activating on %s", target:getObjectName())

	local targets = Action.getAllFenceGateObjects(target)
	local walkToward, lookToward = utils.determineFocalObjects(player, targets)

	utils.createPrepatoryActions(player, boltCutters, walkToward)
	ISTimedActionQueue.add(Action:new(player, lookToward, boltCutters, constants.animIndices.midAnimIndex))
end

local function onGameStart()
	local options = require("dgmc_bolt_cutters_options")
	options.addListener(constants.sandbox.allowFenceGates, function(new, old) handler:onEnabledChange(new, old) end)
end
Events.OnGameStart.Add(onGameStart)

return handler