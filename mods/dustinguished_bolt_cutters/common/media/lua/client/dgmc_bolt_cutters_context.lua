require("ISUI/ISToolTip")

local constants = require("dgmc_bolt_cutters_constants")
local utils = require("dgmc_bolt_cutters_utils")
local logger = require("dgmc_bolt_cutters_logger")

---@type DGMCBaseHandler[]
local handlers = {}
table.insert(handlers, require("handlers/dgmc_bolt_cutters_garage_handler"))
table.insert(handlers, require("handlers/dgmc_bolt_cutters_gate_handler"))
table.insert(handlers, require("handlers/dgmc_bolt_cutters_shutter_handler"))
table.insert(handlers, require("handlers/dgmc_bolt_cutters_fence_handler"))

local tooltipText = getText("ContextMenu_DGMC_Bolt_Cutters_Strength_Tooltip")

---@type integer[]
local strengthReqs = { 0, 1, 2 }

---@param context ISContextMenu
---@param player IsoPlayer
---@param boltCutters InventoryItem
---@param square IsoGridSquare
---@param icon Texture
---@param adjacent boolean
---@return boolean
local function processSquare(context, player, boltCutters, square, icon, adjacent)
	local objects = square:getObjects()
	if (adjacent == true) then
		logger.debug("processSquare", "processing %i adjacent objects", objects:size())
	else
		logger.debug("processSquare", "processing %i initial objects", objects:size())
	end

	for i = 1, #handlers do
		local handler = handlers[i]
		if (adjacent == false or handler.lookAdjacent == adjacent) then
			logger.debug("processObjects", "processing %s", handler.sandboxOption)
			
			local targetObj, strIndex = handler.getTargetObject(objects)

			if targetObj ~= nil then
				local playerStr = player:getPerkLevel(Perks.Strength)
				---@cast strIndex integer
				local strengthReq = strengthReqs[strIndex]

				local option = context:addOption(handler.text, player, handler.onUseBoltCutters, targetObj, boltCutters)
				option.iconTexture = icon

				if strengthReq > playerStr then
					logger.debug("processObjects", "player did not meet strength req %i/%i", playerStr, strengthReq)
					option.notAvailable = true
					local tooltip = ISToolTip:new()
					tooltip:initialise()
					tooltip.description = string.format("%s (%i/%i)", tooltipText, playerStr, strengthReq)
					option.toolTip = tooltip
				end

				return true
			end
		end
	end

	return false
end

---@param playerIndex integer
---@param context ISContextMenu
---@param worldObjects IsoObject[]
---@param test boolean
local function onContextEvent(playerIndex, context, worldObjects, test)
	if worldObjects == nil or #worldObjects == 0 then
		logger.debug("onContextEvent", "no world objects")
		return
	end

	local player = getSpecificPlayer(playerIndex)
	if player == nil or player:isDead() then
		logger.debug("onContextEvent", "player was nil or dead")
		return
	end

	local boltCutters = utils.findBoltCutters(player)
	if boltCutters == nil then
		logger.debug("onContextEvent", "no bolt cutters")
		return
	end
	local icon = boltCutters:getIcon()

	local firstObject = worldObjects[1]
	if firstObject == nil then
		logger.error("onContextEvent", "first object was nil")
		return
	end
	local initialSquare = firstObject:getSquare()

	if (processSquare(context, player, boltCutters, initialSquare, icon, false) == true) then
		return
	end

	local square = initialSquare:getAdjacentSquare(IsoDirections.S)
	if (processSquare(context, player, boltCutters, square, icon, true) == true) then
		return
	end

	square = initialSquare:getAdjacentSquare(IsoDirections.E)
	processSquare(context, player, boltCutters, square, icon, true)
end

---@param new integer
---@param old integer
local function updateEasyStrength(new, old)
	logger.debug("updateEasyStrength", "updating from %i to %i", old, new)
	strengthReqs[constants.strengthIndices.easyIndex] = new
end

---@param new integer
---@param old integer
local function updateMediumStrength(new, old)
	logger.debug("updateMediumStrength", "updating from %i to %i", old, new)
	strengthReqs[constants.strengthIndices.mediumIndex] = new
end

---@param new integer
---@param old integer
local function updateHardStrength(new, old)
	logger.debug("updateHardStrength", "updating from %i to %i", old, new)
	strengthReqs[constants.strengthIndices.hardIndex] = new
end

local function onGameStart()
	local options = require("dgmc_bolt_cutters_options")
	options.addListener(constants.sandbox.easyStrengthReq, updateEasyStrength)
	options.addListener(constants.sandbox.mediumStrengthReq, updateMediumStrength)
	options.addListener(constants.sandbox.hardStrengthReq, updateHardStrength)
end

Events.OnGameStart.Add(onGameStart)
Events.OnFillWorldObjectContextMenu.Add(onContextEvent)
