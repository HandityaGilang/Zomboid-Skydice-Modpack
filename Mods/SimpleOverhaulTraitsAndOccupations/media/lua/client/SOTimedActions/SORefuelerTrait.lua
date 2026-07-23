require "TimedActions/ISBaseTimedAction"

--old_predicateEmptyPetrol_start = predicateEmptyPetrol
local function predicateEmptyPetrol(item)
	return item:hasTag("EmptyPetrol") or item:getType() == "EmptyPetrolCan"
end

-- ISAddGasolineToVehicle
local old_ISAddGasolineToVehicle_start = ISAddGasolineToVehicle.start
function ISAddGasolineToVehicle:start()
	
	-- adjust for units in container and Vehicles.JerryCanLitres
	local unitsPerCan = math.floor(1/self.item:getUseDelta())
	self.JerryCanLitres = Vehicles.JerryCanLitres * (unitsPerCan/8)
	
	self.tankStart = self.part:getContainerContentAmount()
	self.itemStart = self.item:getUsedDelta()
	local add = self.part:getContainerCapacity() - self.tankStart
	local take = math.min(add, self.itemStart * self.JerryCanLitres)
	self.tankTarget = self.tankStart + take
	self.itemTarget = self.itemStart - take / self.JerryCanLitres
	self.amountSent = self.tankStart

	if self.character:HasTrait("GasManagement") then
	self.action:setTime((take * 50) * 0.75)	
	else self.action:setTime(take * 50)
	end

	self:setActionAnim("refuelgascan")
	self:setOverrideHandModels(self.item:getStaticModel(), nil)
	self.sound = self.character:playSound("VehicleAddFuelFromCanister")
end

-- ISRefuelFromGasPump
local old_ISRefuelFromGasPump_start = ISRefuelFromGasPump.start
function ISRefuelFromGasPump:start()
	self.tankStart = self.part:getContainerContentAmount()
	-- Pumps start with 100 units of fuel.  8 pump units = 1 PetrolCan according to ISTakeFuel.
	self.pumpStart = self.fuelStation:getPipedFuelAmount();
	local pumpLitresAvail = self.pumpStart * (Vehicles.JerryCanLitres / 8)
	local tankLitresFree = self.part:getContainerCapacity() - self.tankStart
	local takeLitres = math.min(tankLitresFree, pumpLitresAvail)
	self.tankTarget = self.tankStart + takeLitres
	self.pumpTarget = self.pumpStart - takeLitres / (Vehicles.JerryCanLitres / 8)
	self.amountSent = self.tankStart

	if self.character:HasTrait("GasManagement") then
		self.action:setTime((takeLitres * 50) * 0.75)
	else self.action:setTime(takeLitres * 50)
	end

	self:setActionAnim("fill_container_tap")
	self:setOverrideHandModels(nil, nil)

	self.character:reportEvent("EventTakeWater");

	self.sound = self.character:playSound("VehicleAddFuelFromGasPump")
end

-- ISTakeFuel
local old_ISTakeFuel_start = ISTakeFuel.start
function ISTakeFuel:start()
	if predicateEmptyPetrol(self.petrolCan) then
		local chr = self.character
		local emptyCan = self.petrolCan
		local newType = emptyCan:getReplaceType("PetrolSource") or "Base.PetrolCan"
		self.petrolCan = chr:getInventory():AddItem(newType)
		self.petrolCan:setUsedDelta(0)
		if chr:getPrimaryHandItem() == emptyCan then
			chr:setPrimaryHandItem(self.petrolCan)
		end
		if chr:getSecondaryHandItem() == emptyCan then
			chr:setSecondaryHandItem(self.petrolCan)
		end
		chr:getInventory():Remove(emptyCan)
	end

	self.petrolCan:setJobType(getText("ContextMenu_TakeGasFromPump"))
	self.petrolCan:setJobDelta(0.0)

	local pumpCurrent = tonumber(self.fuelStation:getPipedFuelAmount())
	local itemCurrent = math.floor(self.petrolCan:getUsedDelta() / self.petrolCan:getUseDelta() + 0.001)
	local itemMax = math.floor(1 / self.petrolCan:getUseDelta() + 0.001)
	local take = math.min(pumpCurrent, itemMax - itemCurrent)

	if self.character:HasTrait("GasManagement") then
		self.action:setTime((take * 50) * 0.75)
	else self.action:setTime(take * 50)
	end

	self.itemStart = itemCurrent
	self.itemTarget = itemCurrent + take
	
	self:setOverrideHandModels(nil, self.petrolCan:getStaticModel())
	self:setActionAnim("TakeGasFromPump")

	self.sound = self.character:playSound("CanisterAddFuelFromGasPump")
end

-- ISTakeGasolineFromVehicle
local old_ISTakeGasolineFromVehicle_start = ISTakeGasolineFromVehicle.start
function ISTakeGasolineFromVehicle:start()
	local unitsPerCan = 0
	if predicateEmptyPetrol(self.item) then
		local wasPrimary = self.character:getPrimaryHandItem() == self.item
		local wasSecondary = self.character:getSecondaryHandItem() == self.item
		self.character:getInventory():DoRemoveItem(self.item)
		local newType = self.item:getReplaceType("PetrolSource") or "Base.PetrolCan"
		self.item = self.character:getInventory():AddItem(newType)
		self.item:setUsedDelta(0)
		if wasPrimary then
			self.character:setPrimaryHandItem(self.item)
		end
		if wasSecondary then
			self.character:setSecondaryHandItem(self.item)
		end
	end
	
	-- adjust for units in container and Vehicles.JerryCanLitres
	local unitsPerCan = math.floor(1/self.item:getUseDelta())
	self.JerryCanLitres = Vehicles.JerryCanLitres * (unitsPerCan/8)
	
	self.tankStart = self.part:getContainerContentAmount()
	self.itemStart = self.item:getUsedDelta()
	local add = (1.0 - self.itemStart) * self.JerryCanLitres
	local take = math.min(add, self.tankStart)
	self.tankTarget = self.tankStart - take
	self.itemTarget = self.itemStart + take / self.JerryCanLitres
	self.amountSent = math.ceil(self.tankStart)

	if self.character:HasTrait("GasManagement") then
		self.action:setTime((take * 50) * 0.75)	
	else self.action:setTime(take * 50)
	end	

	self:setActionAnim("TakeGasFromVehicle")
	self:setOverrideHandModels(nil, self.item:getStaticModel())

	self.sound = self.character:playSound("CanisterAddFuelSiphon")
end