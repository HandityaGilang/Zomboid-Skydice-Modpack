ISTrunkEnterVehicle = ISBaseTimedAction:derive("ISTrunkEnterVehicle")

function ISTrunkEnterVehicle:isValid()
	if not self.vehicle then
		return false
	end

	if not (MoreCarFeatures.canEnterExitVehicleTrunk[self.fullVName] or MoreCarFeatures.canEnterExitVehicleTrunkKI51[self.fullVName] or MoreCarFeatures.canEnterExitVehicleTrunkKI52[self.fullVName] or MoreCarFeatures.canEnterExitVehicleTrunkKI53[self.fullVName]) then
		return false
	end

	local doorPart = self.vehicle:getUseablePart(self.character)
	if not (self.vehicle:getMaxPassengers() > 0 and not self.vehicle:isBurntOrSmashed() and doorPart and doorPart:getDoor() and (doorPart:getId() == "TrunkDoor" or doorPart:getId() == "TrunkDoor2" or doorPart:getId() == "DoorRear")) then
		return false
	end

	if self.started then
		if self.seat then
			return true
		end
		return false
	end

	return not self.character:getVehicle()
end

function ISTrunkEnterVehicle:start()
	local playerNum = self.character:getPlayerNum()
	getCell():setDrag(nil, playerNum)
	local contextMenu = getPlayerContextMenu(playerNum)
	if contextMenu and contextMenu:isAnyVisible() then
		contextMenu:hideAndChildren()
	end

	self.action:setBlockMovementEtc(true)

	local compSeats = {}

	if MoreCarFeatures.canEnterExitVehicleTrunk[self.fullVName] then
		local maxSeats = self.vehicle:getMaxPassengers()
		for seat=0, maxSeats-1 do
			local areaId = self.vehicle:getPassengerArea(seat)
			if maxSeats <= 2 or areaId:contains("SeatRear") then
				if seat then table.insert(compSeats, seat) end
			end
		end
	elseif MoreCarFeatures.canEnterExitVehicleTrunkKI51[self.fullVName] then
		local maxSeats = self.vehicle:getMaxPassengers()
		for seat=0, maxSeats-1 do
			table.insert(compSeats, seat)
		end
	elseif MoreCarFeatures.canEnterExitVehicleTrunkKI52[self.fullVName] then
		table.insert(compSeats, 2)
		table.insert(compSeats, 3)
	elseif MoreCarFeatures.canEnterExitVehicleTrunkKI53[self.fullVName] then
		table.insert(compSeats, 4)
		table.insert(compSeats, 5)
	end

	for _, seat in ipairs(compSeats) do
		local finalSeat = false
		if _ == #compSeats then finalSeat = true end
		local setSeat = true
		
		if self.vehicle:isSeatOccupied(seat) then
			if self.vehicle:getCharacter(seat) then
				setSeat = false
				if finalSeat then
					HaloTextHelper.addBadText(self.character, getText("IGUI_PlayerText_VehicleSomeoneInSeat"))
					break
				end
			else
				setSeat = false
				if finalSeat then
					HaloTextHelper.addBadText(self.character, getText("IGUI_PlayerText_VehicleItemInSeat"))
					break
				end
			end
		elseif not self.vehicle:isSeatInstalled(seat) then
			setSeat = false
			if finalSeat then
				HaloTextHelper.addBadText(self.character, getText("IGUI_PlayerText_VehicleSeatRemoved"))
				break
			end
		end

		if setSeat then
			self.seat = seat
			break
		end
	end
	
	self.started = true
end

function ISTrunkEnterVehicle:update()
--	if self.started and self.seat then
--		self:forceComplete()
--	end
	self.character:faceThisObject(self.vehicle)
end

function ISTrunkEnterVehicle:stop()
	ISBaseTimedAction.stop(self)
end

function ISTrunkEnterVehicle:perform()
	local stupidSwitchTo
	if not self.vehicle:getPassengerDoor(self.seat) then	--LIMITATION: SEAT MUST HAVE DOOR TO BE ENTERED.. else... well... read below
		for seat=0, self.vehicle:getMaxPassengers()-1 do
			if self.vehicle:getPassengerDoor(seat) and self.vehicle:isSeatInstalled(seat) then
				stupidSwitchTo = self.seat
				self.seat = seat
				break
			end
		end
		if not stupidSwitchTo then
		--	print("no seats with possible doors were found to get around this limitation or not being able to enter a vehicle seat from the outside if that seat has no doors")
			ISBaseTimedAction.perform(self)
			return
		end
	end

	if (self.character:getPrimaryHandItem() and self.character:getPrimaryHandItem():hasTag(ItemTag.HEAVY_ITEM)) or (self.character:getSecondaryHandItem() and self.character:getSecondaryHandItem():hasTag(ItemTag.HEAVY_ITEM)) then
		if isClient() then
			local args = { id = self.character:getOnlineID() }
			sendClientCommand(self.character, 'player', 'onDropHeavyItem', args)
		else
			forceDropHeavyItems(self.character)
		end
	end

	self.vehicle:enter(self.seat, self.character)
	self.vehicle:setCharacterPosition(self.character, self.seat, "inside")
	self.vehicle:transmitCharacterPosition(self.seat, "inside")
	self.vehicle:playPassengerAnim(self.seat, "idle")
	self.vehicle:playPassengerSound(self.seat, "enter")
	if stupidSwitchTo then
		self.vehicle:switchSeat(self.character, stupidSwitchTo)
	end
	self.character:triggerMusicIntensityEvent("VehicleEnter")
	triggerEvent("OnEnterVehicle", self.character)

	ISBaseTimedAction.perform(self)
end

function ISTrunkEnterVehicle:getDuration()
	if self.character:isTimedActionInstant() then
		return 1
	end
	return 30
end

function ISTrunkEnterVehicle:new(character, vehicle)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.stopOnWalk = false
	o.stopOnRun = false
	o.character = character
	o.vehicle = vehicle
	o.fullVName = vehicle:getScript():getFullName()
	o.maxTime = o:getDuration()
	o.started = false
	o.ignoreHandsWounds = true
	return o
end
