if isClient() then return end

require "Map/SGlobalObjectSystem"
require "GlobalObject/SBeehiveGlobalObject"

SBeehiveSystem = SGlobalObjectSystem:derive("SBeehiveSystem")

function SBeehiveSystem:new()
	local o = SGlobalObjectSystem.new(self, "beehive")
	return o
end

function SBeehiveSystem:initSystem()
	SGlobalObjectSystem.initSystem(self)

	self.system:setModDataKeys(nil)

    self.system:setObjectModDataKeys({'queenBee', 'exterior', 'boostPlantArea', 'produceFactor', 'frameSlots'})
end

function SBeehiveSystem:newLuaObject(globalObject)
	return SBeehiveGlobalObject:new(self, globalObject)
end

function SBeehiveSystem:isValidIsoObject(isoObject)
    return isoObject and isoObject:getName() == "Hold_Hive"
end
function SBeehiveSystem:addBeehive(square, spriteName)
	local luaObject = self:newLuaObjectOnSquare(square)
	luaObject:initNew()
	luaObject.exterior = square:isOutside()
	luaObject:addObject(spriteName)
	luaObject:syncModData()
end

function SBeehiveSystem:updateProduction()
    for i=1, self:getLuaObjectCount() do
        local luaObject = self:getLuaObjectByIndex(i)
        
        if luaObject.queenBee then
            luaObject:updateFrameProduction()
        end
    end
end

function SBeehiveSystem:boostNearbyPlants()
	    for i=1, SBeehiveSystem.instance:getLuaObjectCount() do
        local luaObject = SBeehiveSystem.instance:getLuaObjectByIndex(i)
        if luaObject.queenBee then
            luaObject:boostNearbyPlants()
        end
    end
end

local function EveryDays()
    SBeehiveSystem.instance:boostNearbyPlants()
end

local function EveryTenMinutes()
	SBeehiveSystem.instance:updateProduction()
end



SGlobalObjectSystem.RegisterSystemClass(SBeehiveSystem)

Events.EveryDays.Add(EveryDays)
Events.EveryTenMinutes.Add(EveryTenMinutes)