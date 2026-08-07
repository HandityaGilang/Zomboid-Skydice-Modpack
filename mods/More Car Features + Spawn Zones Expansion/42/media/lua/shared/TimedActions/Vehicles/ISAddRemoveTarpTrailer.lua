ISAddRemoveTarpTrailer = ISBaseTimedAction:derive("ISAddRemoveTarpTrailer")

function ISAddRemoveTarpTrailer:isValid()
	if not self.vehicle then
		return false
	end

	if self.startedVName then
		if self.vehicle ~= self.character:getNearVehicle() then
			return false
		end

		if self.reqItems then
			if #self.reqItems ~= 5 or self.startedVName == "Base.TrailerCover" or self.character:getPerkLevel(Perks.Mechanics) < 1 then
				return false
			end

			local tarpCount = 0
			local ropeCount = 0
			for _, item in ipairs(self.reqItems) do
				local itemName = item:getScriptItem():getFullName()
				if itemName == "Base.Tarp" then
					tarpCount = tarpCount + 1
				elseif itemName == "Base.Rope" then
					ropeCount = ropeCount + 1
				end

				if isClient() then
					if not self.character:getInventory():containsID(item:getID()) then
						return false
					end
				elseif not self.character:getInventory():contains(item) then
					return false
				end
			end

			if tarpCount ~= 2 or ropeCount ~= 3 then
				return false
			end

		elseif self.startedVName == "Base.Trailer" then
			return false
		end
	end

	return self.vehicle:isStopped()
end

function ISAddRemoveTarpTrailer:waittostart()
	self.character:faceThisObject(self.vehicle)
	return self.character:shouldBeTurning()
end

function ISAddRemoveTarpTrailer:start()
	self.startedVName = self.vehicle:getScriptName()

	self:setOverrideHandModels(nil, nil)
	self:setActionAnim("Loot")
	self.character:SetVariable("LootPosition", "Low")
end

function ISAddRemoveTarpTrailer:update()
	self.character:faceThisObject(self.vehicle)

	if self.reqItems then
		for _, item in ipairs(self.reqItems) do
			item:setJobDelta(self:getJobDelta())
		end
	end

	self.character:setMetabolicTarget(Metabolics.UsingTools)
end

function ISAddRemoveTarpTrailer:stop()
	if self.reqItems then
		for _, item in ipairs(self.reqItems) do
			item:setJobDelta(0.0)
		end
	end

	ISBaseTimedAction.stop(self)
end

function ISAddRemoveTarpTrailer:perform()
	if self.reqItems then
		for _, item in ipairs(self.reqItems) do
			item:setJobDelta(0.0)
		end
	end

	ISBaseTimedAction.perform(self)
end

function ISAddRemoveTarpTrailer:complete()
	local charInv = self.character:getInventory()
	if self.reqItems then
		if not isServer() then
			for _, item in ipairs(self.reqItems) do
				self.character:removeFromHands(item)
				charInv:Remove(item)
			end
		else	--self.reqItems table is not filled on the server, re-get items and break if items missing from desync
			local tarpCount = {}
			local ropeCount = {}
			local it = self.character:getInventory():getItems()
			for i = 0, it:size()-1 do
				local item = it:get(i)
				local itemName = item:getScriptItem():getFullName()
				if #tarpCount < 2 and itemName == "Base.Tarp" then
					table.insert(tarpCount, item)
				elseif #ropeCount < 3 and itemName == "Base.Rope" then
					table.insert(ropeCount, item)
				end
				if #tarpCount >= 2 and #ropeCount >= 3 then
					break
				end
			end
			if #tarpCount < 2 or #ropeCount < 3 then
				return false
			end
			for _, tarp in ipairs(tarpCount) do
				self.character:removeFromHands(tarp)
				charInv:Remove(tarp)
				sendRemoveItemFromContainer(charInv, tarp)
			end
			for _, rope in ipairs(ropeCount) do
				self.character:removeFromHands(rope)
				charInv:Remove(rope)
				sendRemoveItemFromContainer(charInv, rope)
			end
		end
		self.vehicle:setScript("Base.TrailerCover")
		if isServer() then
			local args = {vehId = self.vehicle:getId(), type = "Add"}
			sendServerCommand("MoreCarFeatures", "SyncTrailerTarpScript", args)
		end
	else
		local TrailerCoverMaterialsRemoved = { "Base.Rope", "Base.Rope", "Base.Rope", "Base.Tarp", "Base.Tarp" }
		for _, item in ipairs(TrailerCoverMaterialsRemoved) do
			item = instanceItem(item)
			charInv:AddItem(item)
			sendAddItemToContainer(charInv, item)
		end
		self.vehicle:setScript("Base.Trailer")
		if isServer() then
			local args = {vehId = self.vehicle:getId(), type = "Remove"}
			sendServerCommand("MoreCarFeatures", "SyncTrailerTarpScript", args)
		end
	end

	return true
end

function ISAddRemoveTarpTrailer:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end

	return 500 - self.character:getPerkLevel(Perks.Mechanics) * 20
end

function ISAddRemoveTarpTrailer:new(character, vehicle, reqItems)
	local o = ISBaseTimedAction.new(self, character)
	o.stopOnWalk = true
	o.stopOnRun = true
	o.vehicle = vehicle
	o.reqItems = reqItems
	o.maxTime = o:getDuration()
	return o
end


if isClient() then	--Couldn't get scriptReloaded() to work properly on complete() and it randomizes the part conditions on the client side only if done in perform() while still not actually reloading the damn script
	local function onServerCommand(module, command, args)
		if module == 'MoreCarFeatures' and command == 'SyncTrailerTarpScript' then
			local trailer = getVehicleById(args.vehId)
			if trailer then
				if args.type == "Add" then
					trailer:setScript("Base.TrailerCover")
				elseif args.type == "Remove" then
					trailer:setScript("Base.Trailer")
			--	else == nil for some reason
				end
			end
		end
	end
	Events.OnServerCommand.Add(onServerCommand)
end
