local __refillContainer = require("YAPZLib/Utils").refillContainer

local tent = {}

local addCurtain = function(self, offsetX, offsetY, z, spriteName, north)
	local square = self:getSquare(offsetX, offsetY, z)
	
	local obj = IsoCurtain.new(square:getCell(), square, IsoSpriteManager.instance:getSprite(spriteName), north, false)
	
	return self:addTileObject(offsetX, offsetY, z, obj, false, false, square)
end

local addWindowFrame = function(self, offsetX, offsetY, z, spriteName, north)
	local square = self:getSquare(offsetX, offsetY, z)
	
	local obj = IsoWindowFrame.new(square:getCell(), square, IsoSpriteManager.instance:getSprite(spriteName), north)
	
	return self:addTileObject(offsetX, offsetY, z, obj, false, false, square)
end

local addContainer = function(self, offsetX, offsetY, z, spriteName, roomName, containerType, procName, junk)
	local square = self:getSquare(offsetX, offsetY, z)
	local obj = IsoObject.getNew(square, spriteName, nil, false)
	
	if obj then
		square:AddTileObject(obj)
		__refillContainer(obj, roomName, containerType, procName, junk)
		if isMultiplayer() and isServer() then
			obj:transmitCompleteItemToClients()
		end
	end
	
	MapObjects.newGridSquare(square)
	MapObjects.loadGridSquare(square)
	
	return obj
end

local getTopTable = function(square)
    for i = square:getObjects():size(), 1, -1 do
        local obj = square:getObjects():get(i  -1)
        local sprite = obj:getSprite()
		
        if sprite and sprite:getProperties() then
            local props = sprite:getProperties()
            if props:has("IsTable") and props:has("Surface") and tonumber(props:get("Surface")) then
                return obj
            end
        end
    end
	
    return nil
end

local getTotalTableHeight = function(square)
    local obj = getTopTable(square)
    if not obj then return 0 end
    local props = obj:getSprite():getProperties()
	
    return obj:getRenderYOffset() + tonumber(props:get("Surface"))
end

local getSurface = function(obj)
	local sprite = obj:getSprite()
	
	if sprite and sprite:getProperties() then
		local props = sprite:getProperties()
		return props:has("Surface") and tonumber(props:get("Surface"))
	end
	
    return 0
end

local addRadio = function(self, offsetX, offsetY, z, spriteName)
	local square = self:getSquare(offsetX, offsetY, z)
	
	local obj = IsoRadio.new(square:getCell(), square, IsoSpriteManager.instance:getSprite(spriteName))
	obj:setRenderYOffset(getTotalTableHeight(square) - getSurface(obj))
	obj = self:addTileObject(offsetX, offsetY, z, obj, false, false, square)
	
	return obj
end

local crateProcs = { "ArmyStorageGuns", "ArmyStorageAmmunition", "ArmyStorageMedical", "ArmyStorageOutfit", "ArmyStorageElectronics" }

tent.N = function(self)
	for x = 3, 5 do
		self:addTileObjectBySpriteName(x, -3, self.spawnPoint.z, "location_military_tent_01_1", false, false)
	end
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(6, y, self.spawnPoint.z, "location_military_tent_01_0", false, false)
	end
	
	for x = 2, 5 do
		self:addTileObjectBySpriteName(x, -9, self.spawnPoint.z, "location_military_tent_01_1", false, false)
	end
	
	self:addTileObjectBySpriteName(2, -8, self.spawnPoint.z, "location_military_tent_01_0", false, false)
	self:addTileObjectBySpriteName(2, -7, self.spawnPoint.z, "location_military_tent_01_0", false, false)
	addWindowFrame(self, 2, -6, self.spawnPoint.z, "location_military_tent_01_8", false)
	self:addTileObjectBySpriteName(2, -5, self.spawnPoint.z, "location_military_tent_01_0", false, false)
	self:addTileObjectBySpriteName(2, -4, self.spawnPoint.z, "location_military_tent_01_10", false, false)
	self:addTileObjectBySpriteName(2, -3, self.spawnPoint.z, "location_military_tent_01_2", false, false)
	
	self:addTileObjectBySpriteName(6, -2, self.spawnPoint.z, "location_military_tent_01_35", false, false)
	self:addTileObjectBySpriteName(6, -3, self.spawnPoint.z, "location_military_tent_01_34", false, false)
	self:addTileObjectBySpriteName(6, -4, self.spawnPoint.z, "location_military_tent_01_32", false, false)
	self:addTileObjectBySpriteName(6, -5, self.spawnPoint.z, "location_military_tent_01_33", false, false)
	self:addTileObjectBySpriteName(6, -6, self.spawnPoint.z, "location_military_tent_01_32", false, false)
	self:addTileObjectBySpriteName(6, -7, self.spawnPoint.z, "location_military_tent_01_32", false, false)
	self:addTileObjectBySpriteName(6, -8, self.spawnPoint.z, "location_military_tent_01_33", false, false)
	self:addTileObjectBySpriteName(6, -9, self.spawnPoint.z, "location_military_tent_01_3", false, false)
	
	self:addTileObjectBySpriteName(2, -3, self.spawnPoint.z + 1, "location_military_tent_01_48", false, false)
	self:addTileObjectBySpriteName(3, -3, self.spawnPoint.z + 1, "location_military_tent_01_49", false, false)
	self:addTileObjectBySpriteName(4, -3, self.spawnPoint.z + 1, "location_military_tent_01_52", false, false)
	self:addTileObjectBySpriteName(5, -3, self.spawnPoint.z + 1, "location_military_tent_01_53", false, false)
	
	self:addTileObjectBySpriteName(2, -9, self.spawnPoint.z + 1, "location_military_tent_01_48", false, false)
	self:addTileObjectBySpriteName(3, -9, self.spawnPoint.z + 1, "location_military_tent_01_49", false, false)
	self:addTileObjectBySpriteName(4, -9, self.spawnPoint.z + 1, "location_military_tent_01_52", false, false)
	self:addTileObjectBySpriteName(5, -9, self.spawnPoint.z + 1, "location_military_tent_01_53", false, false)
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(2, y, self.spawnPoint.z + 1, "location_military_tent_01_16", false, false)
	end
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(3, y, self.spawnPoint.z + 1, "location_military_tent_01_22", false, false)
	end
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(4, y, self.spawnPoint.z + 1, "location_military_tent_01_23", false, false)
	end
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(5, y, self.spawnPoint.z + 1, "location_military_tent_01_21", false, false)
	end
	
	addContainer(self, 3, -3, self.spawnPoint.z, "furniture_storage_02_31", "armytent", "locker", "LockerArmyBedroom", false)
	self:addTileObjectBySpriteName(2, -8, self.spawnPoint.z, "location_military_generic_01_23", false, false)
	self:addTileObjectBySpriteName(2, -7, self.spawnPoint.z, "location_military_generic_01_23", false, false)
	addContainer(self, 3, -9, self.spawnPoint.z, "location_military_generic_01_1", "armystorage", "militarycrate", crateProcs[ZombRand(#crateProcs) + 1], false)
	
	self:addTileObjectBySpriteName(4, -3, self.spawnPoint.z, "furniture_bedding_01_58", false, false)
	self:addTileObjectBySpriteName(5, -3, self.spawnPoint.z, "furniture_bedding_01_59", false, false)
	self:addTileObjectBySpriteName(4, -8, self.spawnPoint.z, "furniture_bedding_01_58", false, false)
	self:addTileObjectBySpriteName(5, -8, self.spawnPoint.z, "furniture_bedding_01_59", false, false)
	
	self:addTileObjectBySpriteName(5, -5, self.spawnPoint.z, "furniture_tables_high_01_49", false, false)
	self:addTileObjectBySpriteName(5, -6, self.spawnPoint.z, "furniture_tables_high_01_48", false, false)
	addRadio(self, 5, -6, self.spawnPoint.z, "appliances_com_01_11")
	
	self:addTileObjectBySpriteName(4, -6, self.spawnPoint.z, "furniture_seating_indoor_01_61", false, false)
end

tent.W = function(self)
	for x = 2, 5 do
		self:addTileObjectBySpriteName(x, -2, self.spawnPoint.z, "location_military_tent_01_0", false, false)
	end
	
	self:addTileObjectBySpriteName(6, -2, self.spawnPoint.z, "location_military_tent_01_3", false, false)
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(6, y, self.spawnPoint.z, "location_military_tent_01_1", false, false)
	end
	
	for x = 3, 5 do
		self:addTileObjectBySpriteName(x, -8, self.spawnPoint.z, "location_military_tent_01_0", false, false)
	end
	
	self:addTileObjectBySpriteName(2, -8, self.spawnPoint.z, "location_military_tent_01_2", false, false)
	self:addTileObjectBySpriteName(2, -7, self.spawnPoint.z, "location_military_tent_01_11", false, false)
	self:addTileObjectBySpriteName(2, -6, self.spawnPoint.z, "location_military_tent_01_1", false, false)
	addWindowFrame(self, 1, -5, self.spawnPoint.z, "location_military_tent_01_9", false)
	self:addTileObjectBySpriteName(2, -4, self.spawnPoint.z, "location_military_tent_01_1", false, false)
	self:addTileObjectBySpriteName(2, -3, self.spawnPoint.z, "location_military_tent_01_1", false, false)
	
	self:addTileObjectBySpriteName(6, -9, self.spawnPoint.z, "location_military_tent_01_36", false, false)
	self:addTileObjectBySpriteName(6, -8, self.spawnPoint.z, "location_military_tent_01_37", false, false)
	self:addTileObjectBySpriteName(6, -7, self.spawnPoint.z, "location_military_tent_01_39", false, false)
	self:addTileObjectBySpriteName(6, -6, self.spawnPoint.z, "location_military_tent_01_38", false, false)
	self:addTileObjectBySpriteName(6, -5, self.spawnPoint.z, "location_military_tent_01_39", false, false)
	self:addTileObjectBySpriteName(6, -4, self.spawnPoint.z, "location_military_tent_01_39", false, false)
	self:addTileObjectBySpriteName(6, -3, self.spawnPoint.z, "location_military_tent_01_38", false, false)
	
	self:addTileObjectBySpriteName(5, -2, self.spawnPoint.z + 1, "location_military_tent_01_40", false, false)
	self:addTileObjectBySpriteName(4, -2, self.spawnPoint.z + 1, "location_military_tent_01_41", false, false)
	self:addTileObjectBySpriteName(3, -2, self.spawnPoint.z + 1, "location_military_tent_01_44", false, false)
	self:addTileObjectBySpriteName(2, -2, self.spawnPoint.z + 1, "location_military_tent_01_45", false, false)
	
	self:addTileObjectBySpriteName(5, -8, self.spawnPoint.z + 1, "location_military_tent_01_40", false, false)
	self:addTileObjectBySpriteName(4, -8, self.spawnPoint.z + 1, "location_military_tent_01_41", false, false)
	self:addTileObjectBySpriteName(3, -8, self.spawnPoint.z + 1, "location_military_tent_01_44", false, false)
	self:addTileObjectBySpriteName(2, -8, self.spawnPoint.z + 1, "location_military_tent_01_45", false, false)
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(5, y, self.spawnPoint.z + 1, "location_military_tent_01_24", false, false)
	end
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(4, y, self.spawnPoint.z + 1, "location_military_tent_01_30", false, false)
	end
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(3, y, self.spawnPoint.z + 1, "location_military_tent_01_31", false, false)
	end
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(2, y, self.spawnPoint.z + 1, "location_military_tent_01_29", false, false)
	end
	
	addContainer(self, 3, -3, self.spawnPoint.z, "furniture_storage_02_30", "armytent", "locker", "LockerArmyBedroom", false)
	self:addTileObjectBySpriteName(2, -8, self.spawnPoint.z, "location_military_generic_01_22", false, false)
	self:addTileObjectBySpriteName(2, -7, self.spawnPoint.z, "location_military_generic_01_22", false, false)
	addContainer(self, 3, -9, self.spawnPoint.z, "location_military_generic_01_1", "armystorage", "militarycrate", crateProcs[ZombRand(#crateProcs) + 1], false)
	
	self:addTileObjectBySpriteName(4, -3, self.spawnPoint.z, "furniture_bedding_01_57", false, false)
	self:addTileObjectBySpriteName(5, -3, self.spawnPoint.z, "furniture_bedding_01_56", false, false)
	self:addTileObjectBySpriteName(4, -8, self.spawnPoint.z, "furniture_bedding_01_57", false, false)
	self:addTileObjectBySpriteName(5, -8, self.spawnPoint.z, "furniture_bedding_01_56", false, false)
	
	self:addTileObjectBySpriteName(5, -5, self.spawnPoint.z, "furniture_tables_high_01_51", false, false)
	self:addTileObjectBySpriteName(5, -6, self.spawnPoint.z, "furniture_tables_high_01_50", false, false)
	addRadio(self, 5, -6, self.spawnPoint.z, "appliances_com_01_10")
	
	self:addTileObjectBySpriteName(4, -6, self.spawnPoint.z, "furniture_seating_indoor_01_60", false, false)
end

tent.S = function(self)
	for x = 2, 5 do
		self:addTileObjectBySpriteName(x, -2, self.spawnPoint.z, "location_military_tent_01_1", false, false)
	end
	
	for y = -7, -3 do
		self:addTileObjectBySpriteName(5, y, self.spawnPoint.z, "location_military_tent_01_0", false, false)
	end
	
	self:addTileObjectBySpriteName(5, -8, self.spawnPoint.z, "location_military_tent_01_2", false, false)
	
	for x = 2, 4 do
		self:addTileObjectBySpriteName(x, -8, self.spawnPoint.z, "location_military_tent_01_1", false, false)
	end
	
	self:addTileObjectBySpriteName(1, -8, self.spawnPoint.z, "location_military_tent_01_0", false, false)
	self:addTileObjectBySpriteName(1, -7, self.spawnPoint.z, "location_military_tent_01_0", false, false)
	addWindowFrame(self, 1, -6, self.spawnPoint.z, "location_military_tent_01_8", false)
	addCurtain(self, 1, -6, self.spawnPoint.z, "location_military_tent_01_60", false)
	self:addTileObjectBySpriteName(1, -5, self.spawnPoint.z, "location_military_tent_01_0", false, false)
	self:addTileObjectBySpriteName(1, -4, self.spawnPoint.z, "location_military_tent_01_10", false, false)
	self:addTileObjectBySpriteName(1, -3, self.spawnPoint.z, "location_military_tent_01_0", false, false)
	self:addTileObjectBySpriteName(1, -2, self.spawnPoint.z, "location_military_tent_01_3", false, false)
	
	self:addTileObjectBySpriteName(1, -3, self.spawnPoint.z, "location_military_tent_01_33", false, false)
	self:addTileObjectBySpriteName(1, -4, self.spawnPoint.z, "location_military_tent_01_32", false, false)
	self:addTileObjectBySpriteName(1, -5, self.spawnPoint.z, "location_military_tent_01_32", false, false)
	self:addTileObjectBySpriteName(1, -6, self.spawnPoint.z, "location_military_tent_01_33", false, false)
	self:addTileObjectBySpriteName(1, -7, self.spawnPoint.z, "location_military_tent_01_32", false, false)
	self:addTileObjectBySpriteName(1, -8, self.spawnPoint.z, "location_military_tent_01_34", false, false)
	self:addTileObjectBySpriteName(1, -9, self.spawnPoint.z, "location_military_tent_01_35", false, false)
	
	self:addTileObjectBySpriteName(5, -2, self.spawnPoint.z + 1, "location_military_tent_01_48", false, false)
	self:addTileObjectBySpriteName(4, -2, self.spawnPoint.z + 1, "location_military_tent_01_49", false, false)
	self:addTileObjectBySpriteName(3, -2, self.spawnPoint.z + 1, "location_military_tent_01_52", false, false)
	self:addTileObjectBySpriteName(2, -2, self.spawnPoint.z + 1, "location_military_tent_01_53", false, false)
	
	self:addTileObjectBySpriteName(5, -8, self.spawnPoint.z + 1, "location_military_tent_01_48", false, false)
	self:addTileObjectBySpriteName(4, -8, self.spawnPoint.z + 1, "location_military_tent_01_49", false, false)
	self:addTileObjectBySpriteName(3, -8, self.spawnPoint.z + 1, "location_military_tent_01_52", false, false)
	self:addTileObjectBySpriteName(2, -8, self.spawnPoint.z + 1, "location_military_tent_01_53", false, false)
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(5, y, self.spawnPoint.z + 1, "location_military_tent_01_16", false, false)
	end
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(4, y, self.spawnPoint.z + 1, "location_military_tent_01_22", false, false)
	end
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(3, y, self.spawnPoint.z + 1, "location_military_tent_01_23", false, false)
	end
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(2, y, self.spawnPoint.z + 1, "location_military_tent_01_21", false, false)
	end
	
	addContainer(self, 3, -3, self.spawnPoint.z, "furniture_storage_02_29", "armytent", "locker", "LockerArmyBedroom", false)
	self:addTileObjectBySpriteName(2, -8, self.spawnPoint.z, "location_military_generic_01_31", false, false)
	self:addTileObjectBySpriteName(2, -7, self.spawnPoint.z, "location_military_generic_01_31", false, false)
	addContainer(self, 3, -9, self.spawnPoint.z, "location_military_generic_01_1", "armystorage", "militarycrate", crateProcs[ZombRand(#crateProcs) + 1], false)
	
	self:addTileObjectBySpriteName(4, -3, self.spawnPoint.z, "furniture_bedding_01_59", false, false)
	self:addTileObjectBySpriteName(5, -3, self.spawnPoint.z, "furniture_bedding_01_58", false, false)
	self:addTileObjectBySpriteName(4, -8, self.spawnPoint.z, "furniture_bedding_01_59", false, false)
	self:addTileObjectBySpriteName(5, -8, self.spawnPoint.z, "furniture_bedding_01_58", false, false)
	
	self:addTileObjectBySpriteName(5, -5, self.spawnPoint.z, "furniture_tables_high_01_48", false, false)
	self:addTileObjectBySpriteName(5, -6, self.spawnPoint.z, "furniture_tables_high_01_49", false, false)
	addRadio(self, 5, -6, self.spawnPoint.z, "appliances_com_01_9")
	
	self:addTileObjectBySpriteName(4, -6, self.spawnPoint.z, "furniture_seating_indoor_01_63", false, false)
end

tent.E = function(self)
	for x = 2, 4 do
		self:addTileObjectBySpriteName(x, -3, self.spawnPoint.z, "location_military_tent_01_0", false, false)
	end
	
	self:addTileObjectBySpriteName(5, -3, self.spawnPoint.z, "location_military_tent_01_2", false, false)
	
	for y = -8, -4 do
		self:addTileObjectBySpriteName(5, y, self.spawnPoint.z, "location_military_tent_01_1", false, false)
	end
	
	for x = 2, 5 do
		self:addTileObjectBySpriteName(x, -9, self.spawnPoint.z, "location_military_tent_01_0", false, false)
	end
	
	self:addTileObjectBySpriteName(1, -9, self.spawnPoint.z, "location_military_tent_01_3", false, false)
	self:addTileObjectBySpriteName(1, -8, self.spawnPoint.z, "location_military_tent_01_1", false, false)
	self:addTileObjectBySpriteName(1, -7, self.spawnPoint.z, "location_military_tent_01_1", false, false)
	addWindowFrame(self, 1, -6, self.spawnPoint.z, "location_military_tent_01_9", false)
	addCurtain(self, 1, -6, self.spawnPoint.z, "location_military_tent_01_62", false)
	self:addTileObjectBySpriteName(1, -5, self.spawnPoint.z, "location_military_tent_01_1", false, false)
	self:addTileObjectBySpriteName(1, -4, self.spawnPoint.z, "location_military_tent_01_11", false, false)
	self:addTileObjectBySpriteName(1, -3, self.spawnPoint.z, "location_military_tent_01_1", false, false)
	
	self:addTileObjectBySpriteName(1, -2, self.spawnPoint.z, "location_military_tent_01_36", false, false)
	self:addTileObjectBySpriteName(1, -3, self.spawnPoint.z, "location_military_tent_01_37", false, false)
	self:addTileObjectBySpriteName(1, -4, self.spawnPoint.z, "location_military_tent_01_39", false, false)
	self:addTileObjectBySpriteName(1, -5, self.spawnPoint.z, "location_military_tent_01_38", false, false)
	self:addTileObjectBySpriteName(1, -6, self.spawnPoint.z, "location_military_tent_01_39", false, false)
	self:addTileObjectBySpriteName(1, -7, self.spawnPoint.z, "location_military_tent_01_39", false, false)
	self:addTileObjectBySpriteName(1, -8, self.spawnPoint.z, "location_military_tent_01_38", false, false)
	
	self:addTileObjectBySpriteName(2, -3, self.spawnPoint.z + 1, "location_military_tent_01_40", false, false)
	self:addTileObjectBySpriteName(3, -3, self.spawnPoint.z + 1, "location_military_tent_01_41", false, false)
	self:addTileObjectBySpriteName(4, -3, self.spawnPoint.z + 1, "location_military_tent_01_44", false, false)
	self:addTileObjectBySpriteName(5, -3, self.spawnPoint.z + 1, "location_military_tent_01_45", false, false)
	
	self:addTileObjectBySpriteName(2, -9, self.spawnPoint.z + 1, "location_military_tent_01_40", false, false)
	self:addTileObjectBySpriteName(3, -9, self.spawnPoint.z + 1, "location_military_tent_01_41", false, false)
	self:addTileObjectBySpriteName(4, -9, self.spawnPoint.z + 1, "location_military_tent_01_44", false, false)
	self:addTileObjectBySpriteName(5, -9, self.spawnPoint.z + 1, "location_military_tent_01_45", false, false)
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(2, y, self.spawnPoint.z + 1, "location_military_tent_01_24", false, false)
	end
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(3, y, self.spawnPoint.z + 1, "location_military_tent_01_30", false, false)
	end
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(4, y, self.spawnPoint.z + 1, "location_military_tent_01_31", false, false)
	end
	
	for y = -8, -3 do
		self:addTileObjectBySpriteName(5, y, self.spawnPoint.z + 1, "location_military_tent_01_29", false, false)
	end
	
	addContainer(self, 3, -3, self.spawnPoint.z, "furniture_storage_02_28", "armytent", "locker", "LockerArmyBedroom", false)
	self:addTileObjectBySpriteName(2, -8, self.spawnPoint.z, "location_military_generic_01_30", false, false)
	self:addTileObjectBySpriteName(2, -7, self.spawnPoint.z, "location_military_generic_01_30", false, false)
	addContainer(self, 3, -9, self.spawnPoint.z, "location_military_generic_01_1", "armystorage", "militarycrate", crateProcs[ZombRand(#crateProcs) + 1], false)
	
	self:addTileObjectBySpriteName(4, -3, self.spawnPoint.z, "furniture_bedding_01_56", false, false)
	self:addTileObjectBySpriteName(5, -3, self.spawnPoint.z, "furniture_bedding_01_57", false, false)
	self:addTileObjectBySpriteName(4, -8, self.spawnPoint.z, "furniture_bedding_01_56", false, false)
	self:addTileObjectBySpriteName(5, -8, self.spawnPoint.z, "furniture_bedding_01_57", false, false)
	
	self:addTileObjectBySpriteName(5, -5, self.spawnPoint.z, "furniture_tables_high_01_50", false, false)
	self:addTileObjectBySpriteName(5, -6, self.spawnPoint.z, "furniture_tables_high_01_51", false, false)
	addRadio(self, 5, -6, self.spawnPoint.z, "appliances_com_01_8")
	
	self:addTileObjectBySpriteName(4, -6, self.spawnPoint.z, "furniture_seating_indoor_01_62", false, false)
end

return tent