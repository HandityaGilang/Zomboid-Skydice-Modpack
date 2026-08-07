-- -- ************************************************************************
-- -- **        ██████  ██████   █████  ██    ██ ███████ ███    ██          **
-- -- **        ██   ██ ██   ██ ██   ██ ██    ██ ██      ████   ██          **
-- -- **        ██████  ██████  ███████ ██    ██ █████   ██ ██  ██          **
-- -- **        ██   ██ ██   ██ ██   ██  ██  ██  ██      ██  ██ ██          **
-- -- **        ██████  ██   ██ ██   ██   ████   ███████ ██   ████          **
-- -- ************************************************************************
-- -- ** All rights reserved. This content is protected by © Copyright law. **
-- -- ************************************************************************

-- ✅ ISCampingMenu now manages ISFireplaceMenu & ISBBQMenu actions

---@param playerObj IsoPlayer
---@param target unknown?
---@param fuelItems ArrayList<InventoryItem>
---@param timedAction ISBaseTimedAction
---@param currentFuel number
---@param count integer?
local function addFuel(playerObj, target, fuelItems, timedAction, currentFuel, count)
	if fuelItems:isEmpty() then return end
	if not ISCampingMenu.walkToCampfire(playerObj, target:getSquare()) then return end
    local max = count or fuelItems:size()

	for i=1, max do
		local fuelItem = fuelItems:get(i-1)
		ISCampingMenu.toPlayerInventory(playerObj, fuelItem)

		if playerObj:isEquipped(fuelItem) then
			ISTimedActionQueue.add(ISUnequipAction:new(playerObj, fuelItem, 50))
		end

		local fuelAmt = ISCampingMenu.getFuelDurationForItem(fuelItem)

		for j=1, ISCampingMenu.getFuelItemUses(fuelItem) do
			if (currentFuel + (fuelAmt*j) > getCampingFuelMax()) then return end
			
			ISTimedActionQueue.add(timedAction:new(playerObj, target, fuelItem, fuelAmt)) --[[@diagnostic disable-line: redundant-parameter]]
		end
	end
end

---@param playerObj IsoPlayer
---@param target unknown?
---@param timedAction ISBaseTimedAction
---@param currentFuel number
function ISCampingMenu.onAddAllFuel(playerObj, target, timedAction, currentFuel)

	local fuelItemList = ArrayList.new() --[[@as ArrayList<InventoryItem>]] --[[@diagnostic disable-line: missing-parameter]]
	local containers = ISInventoryPaneContextMenu.getContainers(playerObj) --[[@as ArrayList<ItemContainer>]]

	for i=1, containers:size() do
		local container = containers:get(i-1)
		container:getAllEval(ISCampingMenu.isValidFuel, fuelItemList)
	end

	addFuel(playerObj, target, fuelItemList, timedAction, currentFuel)
end

---@param playerObj IsoPlayer
---@param target unknown?
---@param fuelType string
---@param timedAction ISBaseTimedAction
---@param currentFuel number
---@param count integer?
function ISCampingMenu.onAddMultipleFuel(playerObj, target, fuelType, timedAction, currentFuel, count)

	local fuelItemList = ArrayList.new() --[[@as ArrayList<InventoryItem>]] --[[@diagnostic disable-line: missing-parameter]]
	local containers = ISInventoryPaneContextMenu.getContainers(playerObj) --[[@as ArrayList<ItemContainer>]]

	for i=1, containers:size() do
		local container = containers:get(i-1)
		container:getAllTypeEval(fuelType, ISCampingMenu.isValidFuel, fuelItemList)
	end

	addFuel(playerObj, target, fuelItemList, timedAction, currentFuel, count)
end