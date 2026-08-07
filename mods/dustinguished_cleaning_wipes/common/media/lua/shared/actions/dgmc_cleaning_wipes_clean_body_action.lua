require ("TimedActions/ISBaseTimedAction")

---@class DGMCCleanBodyAction: ISBaseTimedAction
---@field dirtiness number
---@field wipe InventoryItem
local action = ISBaseTimedAction:derive("DGMC_CleaningWipesCleanBody")
local logger = require("dgmc_cleaning_wipes_logging")

local SBV = SandboxVars.DGMC_Cleaning_Wipes

---@return boolean
function action:isValid()
	return self.character ~= nil and self.wipe ~= nil
end

function action:update()
	self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function action:start()
	self:setActionAnim("WashFace")
	self:setOverrideHandModels(nil, nil)
	self.character:reportEvent("EventWashClothing")
end

---@param visual HumanVisual
---@param part BloodBodyPartType
function action:cleanPart(visual, part)
	local blood = visual:getBlood(part)
	local dirt = visual:getDirt(part)

	if blood + dirt <= 0 then
		return
	end

	visual:setBlood(part,0)
	visual:setDirt(part, 0)
end

---@param location ItemBodyLocation
function action:removeMakeup(location)
	local item = self.character:getWornItem(location)
	if item ~= nil then
		self.character:removeWornItem(item)
		self.character:getInventory():Remove(item)		
	end
end

function action:removeAllMakeup()
	self:removeMakeup(ItemBodyLocation.MAKE_UP_FULL_FACE)
	self:removeMakeup(ItemBodyLocation.MAKE_UP_EYES);
	self:removeMakeup(ItemBodyLocation.MAKE_UP_EYES_SHADOW);
	self:removeMakeup(ItemBodyLocation.MAKE_UP_LIPS);
end

function action:perform()
	self.character:resetModelNextFrame()
	ISBaseTimedAction.perform(self)
end

---@return boolean
function action:complete()
	local visual = self.character:getHumanVisual()
	local maxIndex = BloodBodyPartType.MAX:index()

	for i = 1, maxIndex do
		local part = BloodBodyPartType.FromIndex(i - 1)
		self:cleanPart(visual, part)
	end

	if SBV.Remove_Makeup == true then
		self:removeAllMakeup()
	end

	sendHumanVisual(self.character)
	self.wipe:UseAndSync()
	self.character:updateHandEquips()
	return true
end

---@return number
function action:getDuration()
	if self.character:isTimedActionInstant() then
		return 1;
	end

	local maxTime = self.dirtiness * 126 * SBV.Speed_Mult
	return self:adjustMaxTime(maxTime)
end

---@param character IsoPlayer
---@param dirtiness number
---@param wipe InventoryItem
---@return DGMCCleanBodyAction
function action:new(character, dirtiness, wipe)
	---@type DGMCCleanBodyAction
	local obj = ISBaseTimedAction.new(self, character)
	obj.dirtiness = dirtiness
	obj.wipe = wipe
	obj.forceProgressBar = true
	obj.maxTime = obj:getDuration()

	logger.debug("CleanBodyAction", "dirtiness: %f, maxTime: %f", obj.dirtiness, obj.maxTime)

	return obj
end

_G[action.Type] = action
return action