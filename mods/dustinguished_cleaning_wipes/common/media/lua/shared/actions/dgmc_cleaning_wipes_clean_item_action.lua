require ("TimedActions/ISBaseTimedAction")

---@class DGMCCleanItemAction: ISBaseTimedAction
---@field item InventoryItem
---@field wipe InventoryItem
---@field isClothing boolean
---@field isContainer boolean
local action = ISBaseTimedAction:derive("DGMC_CleaningWipesCleanItem")
local logger = require("dgmc_cleaning_wipes_logging")

local SBV = SandboxVars.DGMC_Cleaning_Wipes

---@return boolean
function action:isValid()
	return self.character ~= nil and self.item ~= nil and self.wipe ~= nil
end

function action:update()
	self.character:setMetabolicTarget(Metabolics.LightDomestic)
end

function action:start()
	self:setActionAnim("ScrubClothWithSoap")
	self:setOverrideHandModels(nil, nil)
	self.character:reportEvent("EventWashClothing")
end

function action:perform()
	self.character:resetModelNextFrame()
	triggerEvent("OnClothingUpdated", self.character);
	ISBaseTimedAction.perform(self)
end

---@return number
function action:calcTotalDirtiness()
	local item = self.item

	if self.isClothing or self.isContainer then
		local total = 0.0
		local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())

		if coveredParts ~= nil then
			for i = 0, coveredParts:size() - 1 do
				local part = coveredParts:get(i)
				total = total + item:getBlood(part)
			end
		end

		---@cast item Clothing
		if item.getDirtiness ~= nil then
			total = total + item:getDirtiness()
		end

		return total
	else
		return item:getBloodLevel()		
	end
end

function action:complete()
	local isRemoved = false
	local item = self.item

	if self.isClothing or self.isContainer then
		local coveredParts = BloodClothingType.getCoveredParts(item:getBloodClothingType())

		if coveredParts ~= nil then
			for i = 0, coveredParts:size() - 1 do
				local part = coveredParts:get(i)
				item:setBlood(part, 0)
				item:setDirt(part, 0)
			end
		end
		
		if self.isClothing then
			---@cast item Clothing
			local wetness = SBV.Wetness
			if wetness > 0 and item:getWetness() < wetness then
				item:setWetness(wetness)
			end

			item:setDirtiness(0)
		end
	else
		local newItemType = item:getItemAfterCleaning()
		if newItemType then
			isRemoved = true
			local inventory = self.character:getInventory()

			inventory:Remove(item)
			sendRemoveItemFromContainer(inventory, item)

			local newItem = inventory:AddItem(newItemType)
			if newItem ~= nil and newItem ~= false then
				---@cast newItem InventoryItem
				sendAddItemToContainer(inventory, newItem)

				if newItem.setFavorite ~= nil then
					newItem:setFavorite(item:isFavorite())
				end
			end
		end
	end

	item:setBloodLevel(0)
	if isRemoved == false then
		syncItemFields(self.character, item)
	end

	syncVisuals(self.character)
	self.character:updateHandEquips()

	if self.character:isPrimaryHandItem(item) then
		self.character:setPrimaryHandItem(item);
	end
	if self.character:isSecondaryHandItem(item) then
		self.character:setSecondaryHandItem(item);
	end

	self.wipe:UseAndSync()

	return true
end

---@return number
function action:getDuration()
	if self.character:isTimedActionInstant() then
		return 1;
	end
	local maxTime = math.min(self:calcTotalDirtiness() * 15, 500) * 5

	maxTime = math.max(math.min(800, maxTime), 100) * SBV.Speed_Mult

	return self:adjustMaxTime(maxTime)
end

---@param character IsoPlayer
---@param item InventoryItem
---@param wipe InventoryItem
---@return DGMCCleanItemAction
function action:new(character, item, wipe)
	---@type DGMCCleanItemAction
	local obj = ISBaseTimedAction.new(self, character)
	obj.item = item
	obj.wipe = wipe
	obj.isClothing = instanceof(item, "Clothing")
	obj.isContainer = instanceof(item, "InventoryContainer")
	obj.forceProgressBar = true
	obj.maxTime = obj:getDuration()

	logger.debug("CleanItemAction", "item: %s, isClothing: %s, isContainer: %s, maxTime: %f", item:getName(),
		tostring(obj.isClothing), tostring(obj.isContainer), obj.maxTime)

	return obj
end

_G[action.Type] = action
return action