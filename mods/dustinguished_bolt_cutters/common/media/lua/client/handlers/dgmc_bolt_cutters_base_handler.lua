local logger = require("dgmc_bolt_cutters_logger")

---@class DGMCBaseHandler
---@field text string
---@field lookAdjacent boolean
---@field sandboxOption string
local handler = {}

---@param objects PZArrayList<IsoObject>
---@return IsoObject?
---@return StrengthIndices
function handler.getTargetObjectImpl(objects)
	logger.error("baseHandler:getTargetObjectImpl", "base function was called")
	return nil, -1
end

---@param objects PZArrayList<IsoObject>
---@return IsoObject?
---@return StrengthIndices
function handler.getTargetObject(objects)
	logger.error("baseHandler:getTargetObject", "base function was called")
	return nil, -1
end

---@param player IsoPlayer
---@param target IsoObject
---@param boltCutters InventoryItem
function handler.onUseBoltCutters(player, target, boltCutters)
	logger.error("baseHandler:onUseBoltCutters", "base function was called")
end

---@return IsoObject?
---@return integer
local function disabled()
	return nil, -1
end

---@param new boolean
---@param _old boolean
function handler:onEnabledChange(new, _old)
	if new == true then
		logger.info("handler:onEnabledChange", "enabling via %s", self.sandboxOption)
		self.getTargetObject = self.getTargetObjectImpl
	else
		logger.info("handler:onEnabledChange", "disabling via %s", self.sandboxOption)
		self.getTargetObject = disabled
	end
end

---@param text string
---@param lookAdjacent boolean
---@param sandbox string
---@return DGMCBaseHandler
function handler:new(text, lookAdjacent, sandbox)
	local newHandler = setmetatable({}, { __index = self })
	
	newHandler.text = text
	newHandler.lookAdjacent = lookAdjacent
	newHandler.sandboxOption = sandbox

	---@cast newHandler DGMCBaseHandler
	return newHandler
end

return handler