require "Map/CGlobalObjectSystem"
require "ShelterHold/GlobalObject/CBeehiveGlobalObject"

CBeehiveSystem = CGlobalObjectSystem:derive("CBeehiveSystem")

function CBeehiveSystem:new()
	local o = CGlobalObjectSystem.new(self, "beehive")
	return o
end

function CBeehiveSystem:isValidIsoObject(isoObject)
	return isoObject and isoObject:getName() == "Hold_Hive"
end

function CBeehiveSystem:newLuaObject(globalObject)
	return CBeehiveGlobalObject:new(self, globalObject)
end

CGlobalObjectSystem.RegisterSystemClass(CBeehiveSystem)