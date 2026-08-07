P4PickingMeisterQueue = {}

function P4PickingMeisterQueue:new()
	local obj = {first = 1, last = 0, data = {}}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function P4PickingMeisterQueue:enqueue(item)
	self.last = self.last + 1
	self.data[self.last] = item
end

function P4PickingMeisterQueue:dequeue()
	if self.first > self.last then
		return nil
	end
	local item = self.data[self.first]
	self.data[self.first] = nil
	self.first = self.first + 1
	return item
end

function P4PickingMeisterQueue:clear()
	self.first = 1
	self.last = 0
	self.data = {}
end

function P4PickingMeisterQueue:isEmpty()
	return self.first > self.last
end

function P4PickingMeisterQueue:isNotEmpty()
	return self.first <= self.last
end

function P4PickingMeisterQueue:getAllEntries()
	local entries = {}
	local n = 0
	for i = self.first, self.last do
		n = n + 1
		entries[n] = self.data[i]
	end
	return entries
end

function P4PickingMeisterQueue:print()
	if self:isEmpty() then
		print("P4PickingMeisterQueue is empty")
		return
	end
	for i = self.first, self.last do
		print("P4PickingMeisterQueue[" .. i .. "] = " .. tostring(self.data[i]))
	end
end
