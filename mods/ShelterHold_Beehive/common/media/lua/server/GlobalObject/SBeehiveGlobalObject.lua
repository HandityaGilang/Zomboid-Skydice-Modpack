if isClient() then return end
require "Map/SGlobalObject"
require "ShelterHold/Hold_BeehiveCompat"

SBeehiveGlobalObject = SGlobalObject:derive("SBeehiveGlobalObject")

function SBeehiveGlobalObject:new(luaSystem, globalObject)
	local o = SGlobalObject.new(self, luaSystem, globalObject)
	return o
end

-- ----------------------------------------------------------------------------------------------------- --
-- GolbalObject Data Management
-- ----------------------------------------------------------------------------------------------------- --
function SBeehiveGlobalObject:initNew()
	self.queenBee = nil
	self.exterior = true
	self.produceFactor = 0
	self.boostPlantArea = 5
	self.frameSlots = {}
	for i = 0, 5 do
		self.frameSlots[i] = nil
	end
end

-- Call from Events.OnObjectAdded ,register a new Object when it not have GlobalObject
function SBeehiveGlobalObject:stateFromIsoObject(isoObject)
	if isoObject then
		local modData = isoObject:getModData()
		modData.exterior = isoObject:isOutside()
		self:fromModData(modData)
		isoObject:transmitModData()
	end
end

-- Call from Events.OnObjectAdded ,restore Data (GolbalObject -> ModData)
function SBeehiveGlobalObject:stateToIsoObject(isoObject)
	if isoObject then
		local modData = isoObject:getModData()
		self:toModData(modData)
		isoObject:transmitModData()
	end
end

function SBeehiveGlobalObject:fromModData(modData)
    modData = modData or {}

    self.queenBee = modData.queenBee
	self.exterior = (modData.exterior ~= false)
	self.boostPlantArea = modData.boostPlantArea or 5
    self.produceFactor = modData.produceFactor or 0

    local frameSlots = modData.frameSlots or {}
    self.frameSlots = {}
    for i = 0, 5 do
        self.frameSlots[i] = frameSlots[i]
    end
end

function SBeehiveGlobalObject:toModData(modData)
    modData.queenBee = self.queenBee
    modData.exterior = self.exterior
	modData.boostPlantArea = self.boostPlantArea
    modData.produceFactor = self.produceFactor
    if not modData.frameSlots then
        modData.frameSlots = {}
    end
    for i = 0, 5 do
        modData.frameSlots[i] = self.frameSlots[i]
    end
end

function SBeehiveGlobalObject:syncModData()
	local isoObject = self:getIsoObject()
	if isoObject then
		self:toModData(isoObject:getModData())
		isoObject:transmitModData()
	end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Add/Remove Beehive Object
-- ----------------------------------------------------------------------------------------------------- --

function SBeehiveGlobalObject:addObject(spriteName)
	if self:getIsoObject() then return end
	local square = self:getSquare()
	if not square then return end

	local beehive = IsoObject.new(square, spriteName, "Hold_Hive")
	self:toModData(beehive:getModData())
	square:AddSpecialObject(beehive)
end

function SBeehiveGlobalObject:removeObject()
	self:removeIsoObject()
end

-- ----------------------------------------------------------------------------------------------------- --
-- Environment Checks
-- ----------------------------------------------------------------------------------------------------- --

function SBeehiveGlobalObject:isTimeGood()
	return getGameTime():isDay() or self.queenBee == "Zombee"
end

function SBeehiveGlobalObject:isTemperatureGood()
	local temperature = getClimateManager():getTemperature()
	return (temperature >= 12 and temperature <= 32) or self.queenBee == "Bumblebee"
end

function SBeehiveGlobalObject:isWeatherGood()
	if self.queenBee == "Zombee" then return true end
	if getClimateManager():isRaining() then return false end
	if getClimateManager():isSnowing() then return false end

	return true
end

-- ----------------------------------------------------------------------------------------------------- --
-- Queen Management
-- ----------------------------------------------------------------------------------------------------- --
function SBeehiveGlobalObject:addQueen(queenItem)
    self.queenBee = queenItem:getType()
	self:calculateProductionFactor()
    self:syncModData()
end

function SBeehiveGlobalObject:removeQueen()
    self.queenBee = nil
	self.produceFactor = 0
    self:syncModData()
end

function SBeehiveGlobalObject:getQueenSpeedMultiplier()
    if not self.queenBee then return 0 end

    if self.queenBee == "Zombee" then
        return 0.7
    elseif self.queenBee == "Bumblebee" then
        return 0.9
    elseif self.queenBee == "Honeybee" then
        return 1.0
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- Frame Management
-- ----------------------------------------------------------------------------------------------------- --
function SBeehiveGlobalObject:addFrame(frameItem, slotIndex)
    local progress = frameItem:getCurrentUsesFloat() or 0
    self.frameSlots[slotIndex] = progress
	self:calculateProductionFactor()
    self:syncModData()
    return true
end

function SBeehiveGlobalObject:removeFrame(slotIndex)
    self.frameSlots[slotIndex] = nil
	self:calculateProductionFactor()
    self:syncModData()
    return true
end

function SBeehiveGlobalObject:getFrame(slotIndex)
	if not self.frameSlots[slotIndex] then return nil end

	local isoObject = self:getIsoObject()
	if not isoObject or not isoObject:hasComponent(ComponentType.Resources) then return nil end
	
	local resources = isoObject:getComponent(ComponentType.Resources)
	local targetResourceId = "hive_frame_" .. slotIndex
	local frameResource = resources:getResource(targetResourceId)
	if not frameResource:isEmpty() then
		return frameResource
	end

	self.frameSlots[slotIndex] = nil
	self:syncModData()
	return nil
end

-- ----------------------------------------------------------------------------------------------------- --
-- Production System
-- ----------------------------------------------------------------------------------------------------- --

function SBeehiveGlobalObject:calculateProductionFactor()
	if not self.queenBee or
		not self:isTimeGood() or
		not self:isTemperatureGood() or
		not self:isWeatherGood() then
		self.produceFactor = 0
		return 0
	end

    local factor = self:getQueenSpeedMultiplier()
	local bonus = 1

    local frameCount = 0
    for slotIndex = 0, 5 do
        if self.frameSlots[slotIndex] then
            frameCount = frameCount + 1
        end
    end

    bonus = bonus + (frameCount * 0.15)

	local bonusMonths = {4,5,6,7,9}
	local currentMonth = getGameTime():getMonth() + 1
	for _, month in ipairs(bonusMonths) do
		if currentMonth == month then
			bonus = bonus + 0.2
			break
		end
	end

    if not self.exterior then
        bonus = bonus * 0.5
    end

	factor = math.floor(factor * bonus * 10) / 10
    
    self.produceFactor = factor
    return factor
end

function SBeehiveGlobalObject:updateFrameProduction()
	local validSlots = {}
	for slotIndex = 0, 5 do
		if self.frameSlots[slotIndex] and self.frameSlots[slotIndex] < 1.0 then
			table.insert(validSlots, slotIndex)
		end
	end
	
	if #validSlots == 0 then
		self:calculateProductionFactor()
		self:syncModData()
		return
	end
	
	local factor = self:calculateProductionFactor()
	local baseProgress = 0.0022
	local totalProgress = baseProgress * factor

	local randomIndex = ZombRand(#validSlots) + 1
	local selectedSlot = validSlots[randomIndex]

	local currentProgress = self.frameSlots[selectedSlot] or 0
	local newProgress = math.min(currentProgress + totalProgress, 1.0)
	if newProgress > 1.0 then newProgress = 1.0 end
	self.frameSlots[selectedSlot] = newProgress
	self:syncModData()

	for slotIndex = 0, 5 do
		if self.frameSlots[slotIndex] then
			local frameResource = self:getFrame(slotIndex)
			local frame = frameResource and frameResource:peekItem()
			if frame then
				self:modifyFrame(frame,frameResource,self.frameSlots[slotIndex])
			end
		end
	end
end

function SBeehiveGlobalObject:modifyFrame(item, frameResource, newUsesFloat)
    local itemCondition = item:getCondition()
    local needsChange = false
    local newType = nil

    if newUsesFloat >= 1.0 then
        needsChange = not HoldBeehiveCompat.isFullHiveFrame(item)
        newType = "Hold.HiveFrame_Full"
    elseif newUsesFloat >= 0.25 then
        needsChange = not HoldBeehiveCompat.isWaxHiveFrame(item)
        newType = "Hold.HiveFrame_Wax"
    else
        needsChange = not HoldBeehiveCompat.isEmptyHiveFrame(item)
        newType = "Hold.HiveFrame_Basic"
    end

    if needsChange then
        frameResource:removeItem(item)
        local newitem = instanceItem(newType)
        newitem:setCondition(itemCondition)
        newitem:setCurrentUsesFloat(newUsesFloat)
        frameResource:offerItem(newitem)
    else
        item:setCurrentUsesFloat(newUsesFloat)
        frameResource:sync()
    end
end

-- ----------------------------------------------------------------------------------------------------- --
-- boostNearbyPlants
-- ----------------------------------------------------------------------------------------------------- --

function SBeehiveGlobalObject:boostNearbyPlants()
    if not self.queenBee then return end
    
    local x = self.x
    local y = self.y
    local z = self.z

	local range = math.floor(self.boostPlantArea / 2)

    for dx = -range, range do
        for dy = -range, range do
            local targetX = x + dx
            local targetY = y + dy
            local plant = SFarmingSystem.instance:getLuaObjectAt(targetX, targetY, z)
            
            if plant and plant.nextGrowing then
                if not plant.hasVegetable and not plant.hasSeed then
                    local boost = 6
                    local newTime = plant.nextGrowing - boost
                    plant.nextGrowing = math.max(SFarmingSystem.instance.hoursElapsed + 1, newTime)
					-- self:noise(newTime)
                    plant:saveData()
                end
            end
        end
    end
end