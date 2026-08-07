local utils = {}

local bloodOverlays = 
	{
		"overlay_blood_fence_01",
		"overlay_blood_wall_01"
	}

local baseDuration = 0
local baseMuscleStrain = 0.0

---@param player IsoPlayer
---@param boltCutters InventoryItem
---@param target IsoObject
function utils.createPrepatoryActions(player, boltCutters, target)
	-- make sure we equip the bolt cutters, potentially dropping heavy objects
	if player:hasEquipped(boltCutters:getFullType()) == false then
		ISInventoryPaneContextMenu.equipWeapon(boltCutters, true, true, player:getPlayerNum(), false)
	end

	luautils.walkToObject(player, target, false)
end

---@param item InventoryItem
---@return boolean
local function checkIfBroken(item)
	return item:isBroken() == false
end

---@param player IsoPlayer
---@return InventoryItem?
function utils.findBoltCutters(player)
	local playerInventory = player:getInventory()
	if playerInventory == nil then
		return nil
	end

	--- @type ArrayList<InventoryItem>
	local results = ArrayList.new(1)
	playerInventory:getAllTagEvalRecurse(DGMC_Bolt_Cutters_Tag, checkIfBroken, results)

	if results:size() > 0 then
		return results:get(0)
	end

	return nil
end

---@param player IsoPlayer
---@return number
function utils.calculateDuration(player)
	if player:isTimedActionInstant() == true then
		return 1
	end

	local strengthReductionFactor = baseDuration / 11.0
	local actualDuration = baseDuration - (player:getPerkLevel(Perks.Strength) * strengthReductionFactor)

	return actualDuration * 60
end

---@param player IsoPlayer
function utils.handleMuscleStrain(player)
	local strengthReductionFactor = baseMuscleStrain / 11.0
	local actualStrain = baseMuscleStrain - (player:getPerkLevel(Perks.Strength) * strengthReductionFactor)

	player:addBothArmMuscleStrain(actualStrain)
end

---@param player IsoPlayer
---@param boltCutters InventoryItem
function utils.handleXP(player, boltCutters)
	player:getXp():AddXP(Perks.Strength, 2)
	if boltCutters:damageCheck(0, 1, true, true, player) == true then
		player:getXp():AddXP(Perks.Maintenance, 2)
	end
end

---@param player IsoPlayer
---@param targets table
---@return IsoObject, IsoObject
--- first object returned is the object we will walk toward, and second object is the one we will look at
function utils.determineFocalObjects(player, targets)
	local numObjects = #targets

	-- doing this generically so it works with any multi-tile length
	-- for even numbers of objects, we'll walk toward the closest middle object tile
	-- and we'll look at the other middle object
	if numObjects % 2 == 0 then
		local indexA = (numObjects / 2) + 1
		local indexB = indexA - 1

		local objectA = targets[indexA]
		local objectB = targets[indexB]

		local squareA = objectA:getSquare()
		local squareB = objectB:getSquare()

		-- we'll walk toward whichever is the closer of the two tiles
		---@diagnostic disable-next-line
		if squareA:DistToProper(player) < squareB:DistToProper(player) then
			return objectA, objectB
		else
			return objectB, objectA
		end

	-- for odd numbers of objects, we can just walk toward and look at the very middle tile
	else
		local focalIndex = math.floor(numObjects / 2) + 1
		return targets[focalIndex], targets[focalIndex]
	end
end

---@param square IsoGridSquare
function utils.removeBloodOverlays(square)
	local objects = square:getObjects()
	for i = objects:size() - 1, 0, -1 do
		local object = objects:get(i)
		local str = tostring(object)

		for j = 1, #bloodOverlays do
			if string.find(str, bloodOverlays[j]) ~= nil then
				square:transmitRemoveItemFromSquare(object)
				break
			end
		end
	end
end

---@param targets table
---@param server boolean
function utils.unlockTargets(targets, server)
	for i = 1, #targets do
		local target = targets[i]

		target:setLockedByKey(false)
		target:setLocked(false)

		if server == true then
			target:sync()
		end
	end
end

---@param new integer
---@param _old integer
local function onBaseDurationChange(new, _old)
	baseDuration = new
end

---@param new number
---@param _old number
local function onBaseMuscleStrainChange(new, _old)
	baseMuscleStrain = new
end

local function initialize()
	local constants = require("dgmc_bolt_cutters_constants")
	local options = require("dgmc_bolt_cutters_options")
	options.addListener(constants.sandbox.baseDuration, onBaseDurationChange)
	options.addListener(constants.sandbox.baseMuscleStrain, onBaseMuscleStrainChange)
end

if isServer() == false then
	Events.OnGameStart.Add(initialize)
else
	Events.OnServerStarted.Add(initialize)
end

return utils