require "TimedActions/ISBaseTimedAction"

P4RestoreFloorAction = ISBaseTimedAction:derive("P4RestoreFloorAction")

function P4RestoreFloorAction:isValid()
	local characterSquare = self.character:getCurrentSquare()
	local targetSquare = getCell():getGridSquare(self.x, self.y, self.z)
	if not characterSquare or not targetSquare or characterSquare:getZ() ~= self.z then
		return false
	end
	if math.abs(characterSquare:getX() - self.x) > 2 or math.abs(characterSquare:getY() - self.y) > 2 then
		return false
	end
	if isClient() then
		return true
	end
	local worldObject = self.item and self.item:getWorldItem()
	local sourceSquare = worldObject and worldObject:getSquare()
	if not sourceSquare or sourceSquare:getZ() ~= characterSquare:getZ() then
		return false
	end
	return math.abs(characterSquare:getX() - sourceSquare:getX()) <= 2
		and math.abs(characterSquare:getY() - sourceSquare:getY()) <= 2
end

function P4RestoreFloorAction:perform()
	ISBaseTimedAction.perform(self)
end

function P4RestoreFloorAction:complete()
	if not isServer() then
		return true
	end
	if not self:isValid() then
		if self.debugOutput then
			print("[P4TidyUpMeister][Server] MP floor restore failed: validation failed.")
		end
		return false
	end
	local worldObject = self.item and self.item:getWorldItem()
	local targetSquare = getCell():getGridSquare(self.x, self.y, self.z)
	if not worldObject or not targetSquare then
		if self.debugOutput then
			print("[P4TidyUpMeister][Server] MP floor restore failed: item world object or target square not found.")
		end
		return false
	end
	local item = worldObject:getItem()
	worldObject:getSquare():transmitRemoveItemFromSquare(worldObject)
	item:setWorldXRotation(self.rotationX)
	item:setWorldYRotation(self.rotationY)
	item:setWorldZRotation(self.rotationZ)
	targetSquare:AddWorldInventoryItem(item, self.offX, self.offY, self.offZ, true)
	if self.debugOutput then
		print("[P4TidyUpMeister][Server] MP floor restore complete item=" .. tostring(self.item:getFullType())
			.. " square=" .. tostring(self.x) .. "," .. tostring(self.y) .. "," .. tostring(self.z))
	end
	return true
end

function P4RestoreFloorAction:getDuration()
	return 1
end

function P4RestoreFloorAction:new(character, item, x, y, z, offX, offY, offZ, rotationX, rotationY, rotationZ, debugOutput)
	local o = ISBaseTimedAction.new(self, character)
	o.item = item
	o.x = x
	o.y = y
	o.z = z
	o.offX = offX
	o.offY = offY
	o.offZ = offZ
	o.rotationX = rotationX
	o.rotationY = rotationY
	o.rotationZ = rotationZ
	o.debugOutput = debugOutput
	o.stopOnWalk = false
	o.stopOnRun = false
	o.maxTime = o:getDuration()
	return o
end
