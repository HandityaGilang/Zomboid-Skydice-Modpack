require "Map/CGlobalObject"

CBeehiveGlobalObject = CGlobalObject:derive("CBeehiveGlobalObject")

function CBeehiveGlobalObject:new(luaSystem, globalObject)
	local o = CGlobalObject.new(self, luaSystem, globalObject)
	return o
end

function CBeehiveGlobalObject:getObject()
	return self:getIsoObject()
end
