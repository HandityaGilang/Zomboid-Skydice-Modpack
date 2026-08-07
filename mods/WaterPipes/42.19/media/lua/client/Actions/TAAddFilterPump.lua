require "TimedActions/ISBaseTimedAction"

TAAddFilterPump = ISBaseTimedAction:derive("TAAddFilterPump");

function TAAddFilterPump:isValid()
    local x = self.object:getX()
    local y = self.object:getY()
    local z = self.object:getZ()
    local isoPump = WPIso.GetPump(self.square)
    local pump = WPVirtual.PumpGet(x, y, z)
    local charcoal = self.character:getInventory():getFirstTagRecurse(ItemTag.CHARCOAL)

    if isoPump and pump and charcoal then
        return true
    else
        return false
    end
end

function TAAddFilterPump:update()
end

function TAAddFilterPump:start()
    self.character:faceThisObject(self.object)
	self:setActionAnim("RemoveCurtain")
end

function TAAddFilterPump:stop()
	ISBaseTimedAction.stop(self)
end

function TAAddFilterPump:perform()

	local x = self.object:getX()
    local y = self.object:getY()
    local z = self.object:getZ()

	local isoPump = WPIso.GetPump(self.square)
    local pump = WPVirtual.PumpGet(x, y, z)
    local charcoal = self.character:getInventory():getFirstTagRecurse(ItemTag.CHARCOAL)
    if isoPump and pump and charcoal then
		WPVirtual.PumpAddFilter(x, y, z)
		charcoal:Use()
	end

	ISBaseTimedAction.perform(self)
end


function TAAddFilterPump:new(character, square, object, charcoal)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = false
	o.stopOnRun = false
	o.maxTime = 75
	-- custom fields
	o.object = object
    o.square = square
	o.charcoal = charcoal
	return o
end

return TAAddFilterPump;
