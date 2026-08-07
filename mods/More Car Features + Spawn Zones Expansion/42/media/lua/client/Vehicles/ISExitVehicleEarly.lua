--It is imperative that this mod is loaded before most others because of overwriting such as this...

--Edited lines 26-34. Force driver to stop in MP only, car desync is bad. Commented out lines for non-drivers to hop out.
local ISVehicleMenuOnExit = ISVehicleMenu.onExit
function ISVehicleMenu.onExit(playerObj, seatFrom)
	if not SandboxVars.GamestaVehicleZones.earlyExitVehicle then
		ISVehicleMenuOnExit(playerObj, seatFrom)
		return
	end

	local radialMenu = getPlayerRadialMenu(playerObj:getPlayerNum())
	if radialMenu:isReallyVisible() then
		radialMenu:undisplay()
	end

	local vehicle = playerObj:getVehicle()
	if not vehicle then return end

	if string.contains(vehicle:getScriptName(), "Boat") then
		ISVehicleMenuOnExit(playerObj, seatFrom)
		return
	end

	vehicle:updateHasExtendOffsetForExit(playerObj)
	if (not playerObj:isBlockMovement()) then
		if isClient() and vehicle:isDriver(playerObj) then
			if math.abs(vehicle:getCurrentSpeedKmHour()) > 0.8 then ISTimedActionQueue.add(ISStopVehicle:new(playerObj)) end
	--	else 
	--		if not vehicle:isStopped() then
	--			HaloTextHelper.addBadText(playerObj, getText("IGUI_PlayerText_CanNotExitFromMovingCar"))
	--			vehicle:updateHasExtendOffsetForExitEnd(playerObj)
	--			return 
	--		end
		end
		seatFrom = seatFrom or vehicle:getSeat(playerObj)
		if vehicle:isExitBlocked(playerObj, seatFrom) then
			local seatTo = ISVehicleMenu.getBestSwitchSeatExit(playerObj, vehicle, seatFrom)
			if seatTo then
				ISTimedActionQueue.add(ISSwitchVehicleSeat:new(playerObj, seatTo))
				local doorPart = vehicle:getPassengerDoor(seatTo)
				if doorPart:getDoor():isOpen() then
					ISTimedActionQueue.add(ISCloseVehicleDoor:new(playerObj, vehicle, doorPart))
				end
				ISVehicleMenu.onExitAux(playerObj, seatTo)
				return
			end
		else
			ISVehicleMenu.onExitAux(playerObj, seatFrom)
		end
	end
end

--Edited line 69. Another MP check for the driver.
local ISVehicleMenuOnSwitchSeat = ISVehicleMenu.onSwitchSeat
function ISVehicleMenu.onSwitchSeat(playerObj, seatTo)
	if not SandboxVars.GamestaVehicleZones.earlyExitVehicle then
		ISVehicleMenuOnSwitchSeat(playerObj, seatTo)
		return
	end

	local vehicle = playerObj:getVehicle()
	if not vehicle then return end

	if string.contains(vehicle:getScriptName(), "Boat") then
		ISVehicleMenuOnExit(playerObj, seatFrom)
		return
	end

	if isClient() and math.abs(vehicle:getCurrentSpeedKmHour()) > 0.8 and vehicle:isDriver(playerObj) then ISTimedActionQueue.add(ISStopVehicle:new(playerObj)) end
	ISTimedActionQueue.add(ISSwitchVehicleSeat:new(playerObj, seatTo))
	local doorPart = vehicle:getPassengerDoor(seatTo)
	if doorPart and doorPart:getDoor():isOpen() then
		ISTimedActionQueue.add(ISCloseVehicleDoor:new(playerObj, vehicle, doorPart))
	end
end

--function ISStopVehicle:start()
--end
--
--function ISStopVehicle:update()
--	self:forceComplete()
--end

local ISExitVehicleIsValid = ISExitVehicle.isValid
function ISExitVehicle:isValid()
	if not SandboxVars.GamestaVehicleZones.earlyExitVehicle or (self.vehicle and string.contains(self.vehicle:getScriptName(), "Boat")) then
		return ISExitVehicleIsValid(self)
	end

	local vehicle = self.character:getVehicle()
	if self.vehicle and (self.vehicle == vehicle or (self.speed and self.speed > 10)) then
		if self.speed and self.speed > 10 then	--without, player can jump and roll in any direction, even if it's physically impossible
			self.character:setTargetAndCurrentDirection(math.cos(self.facingDir), math.sin(self.facingDir))
		end
		return true
	end
	return false
end

local ISExitVehicleStart = ISExitVehicle.start
function ISExitVehicle:start()
	if not SandboxVars.GamestaVehicleZones.earlyExitVehicle or (self.vehicle and string.contains(self.vehicle:getScriptName(), "Boat")) then
		ISExitVehicleStart(self)
		return
	end

	self.action:setBlockMovementEtc(true)

	local vDir = MoreCarFeatures.getVehicleDir(self.vehicle)
	self.facingDir = vDir
	self.speed = self.vehicle:getCurrentSpeedKmHour()
	if self.speed < 0 then
		self.speed = self.speed * -1
		self.facingDir = self.facingDir - math.pi
	end

	self.seat = self.vehicle:getSeat(self.character)
	self.vehicle:playPassengerSound(self.seat, "exit")
	self.character:triggerMusicIntensityEvent("VehicleExit")

	if self.speed <= 10 then
		self.character:SetVariable("bExitingVehicle", "true")
	else
		for _, bind in ipairs(keyBinding) do
			if bind.value == "Run" then
				self.keyRun = bind.key
			elseif bind.value == "Sprint" then
				self.keySprint = bind.key
			end
		end

		self.vehicle:exit(self.character)
		self.vehicle:setCharacterPosition(self.character, self.seat, "outside")
		self.character:PlayAnim("Idle")

		local sideDist = 0	--prevents player from hitting the vehicle on exit, which isn't an issue normally since the vehicle needs to be stopped to exit
		local exitArea = self.vehicle:getPassengerArea(self.seat)
		if exitArea:contains("Left") then
			sideDist = -1.3
		elseif exitArea:contains("Right") then
			sideDist = 1.3
		end
		local x = self.vehicle:getX() + math.cos(vDir) * 0 + -math.sin(vDir) * sideDist
		local y = self.vehicle:getY() + math.sin(vDir) * 0 + math.cos(vDir) * sideDist
		self.character:setX(x)
		self.character:setY(y)

		self.character:setTargetAndCurrentDirection(math.cos(self.facingDir), math.sin(self.facingDir))

		triggerEvent("OnExitVehicle", self.character)
		self.vehicle:updateHasExtendOffsetForExitEnd(self.character)

		local animName
		if self.speed <= 30 then
			animName = "StumbleVehicleExitRoll"
		elseif self.speed <= 50 then
			self.didDamage = false
			self:setOverrideHandModels(nil, nil)
			animName = "TripVehicleExitRoll"
		else
			self.didDamage = false
			self:setOverrideHandModels(nil, nil)
			animName = "TumbleVehicleExitRoll"
		end
		self.character:setVariable(animName, true)
		self.earlyExitAnimationFinished = false

		self.character:setIsAiming(false)
		self.character:setIgnoreMovement(true)
		self.character:setIgnoreAimingInput(true)
		self.character:setIgnoreInputsForDirection(true)

		if isClient() then
			local args = { animTypeString = animName, faceDir = self.facingDir, chrx = self.character:getX(), chry = self.character:getY() }
			sendClientCommand(self.character, 'MoreCarFeatures', "SyncFallExitVehicleAnim", args)
		end
	end
end

function ISExitVehicle:animEvent(event, parameter)
	if SandboxVars.GamestaVehicleZones.earlyExitVehicle then

	--	event == "EarlyExitVehicleFallDamage" and parameter		--moved to variable so I could use it in an OnTick event in the even the timed action ends early while the animation continues
		if self.speed and self.speed > 10 and event == "SetVariable" then
			if self.didDamage == false and self.character:getVariableBoolean("EarlyExitVehicleFallDamage") == true then
				self.character:setVariable("EarlyExitVehicleFallDamage", false)
				self.didDamage = true
				local args = { vspeed = self.speed }
				sendClientCommand(self.character, 'MoreCarFeatures', "EarlyExitVehicleFallDamage", args)
				self:stop()
			end

			if self.speed <= 30 then
				if self.character:getVariableBoolean("StumbleVehicleExitRoll") == false then
					self.earlyExitAnimationFinished = true
					self:forceComplete()
				elseif self.character:getVariableBoolean("EarlySprintAway") == true then
					if (self.keyRun and isKeyDown(self.keyRun)) or (self.keySprint and isKeyDown(self.keySprint)) then
						self.character:setVariable("StumbleVehicleExitRoll", false)
						self.character:setVariable("EarlySprintAway", false)
						self.earlyExitAnimationFinished = true
						self:forceComplete()
					end
				end
			elseif self.speed <= 50 then
				if self.character:getVariableBoolean("TripVehicleExitRoll") == false then
					self.earlyExitAnimationFinished = true
					self:forceComplete()
				end
			elseif self.character:getVariableBoolean("TumbleVehicleExitRoll") == false then
				self.earlyExitAnimationFinished = true
				self:forceComplete()
			end
		end

	end
end

local ISExitVehicleUpdate = ISExitVehicle.update
function ISExitVehicle:update()
	if not SandboxVars.GamestaVehicleZones.earlyExitVehicle or (self.vehicle and string.contains(self.vehicle:getScriptName(), "Boat")) then
		ISExitVehicleUpdate(self)
		return
	end

	if self.speed then
		if self.speed <= 10 then
			self.vehicle:playPassengerAnim(self.seat, "exit")
			if self.character:GetVariable("ExitAnimationFinished") == "true" then
				self.character:ClearVariable("ExitAnimationFinished")
				self.character:ClearVariable("bExitingVehicle")
				self:forceComplete()
			end
		elseif isClient() and self.speed > 10 then
			local args = { chrx = self.character:getX(), chry = self.character:getY() }
			sendClientCommand(self.character, 'MoreCarFeatures', "SyncFallExitVehicleCHRXY", args)
		end
	end
end

local ISExitVehicleStop = ISExitVehicle.stop
function ISExitVehicle:stop()
	if not SandboxVars.GamestaVehicleZones.earlyExitVehicle or (self.vehicle and string.contains(self.vehicle:getScriptName(), "Boat")) then
		ISExitVehicleStop(self)
		return
	end

	if self.character:getVehicle() or not self.speed or self.speed <= 10 then
		self.character:clearVariable("bExitingVehicle")
		self.character:clearVariable("ExitAnimationFinished")
		self.vehicle:playPassengerAnim(self.seat, "idle")

	elseif self.earlyExitAnimationFinished == false then
		local function localOnCompleteDropItems()
			self.didDamage = "finished"
		end
		local function continueAnimChecksOnCancel()
			if self.didDamage ~= "dropping" then
				ISTimedActionQueue.clear(self.character)
			end

			if isClient() then
				local args = { chrx = self.character:getX(), chry = self.character:getY() }
				sendClientCommand(self.character, 'MoreCarFeatures', "SyncFallExitVehicleCHRXY", args)
			end

			if self.didDamage == true then
				local itemPrimary = self.character:getPrimaryHandItem()
				local itemSecondary = self.character:getSecondaryHandItem()
				if itemPrimary then
					local playerNum = self.character:getPlayerNum()
					self.character:removeAttachedItem(itemPrimary)
					local action = ISInventoryTransferUtil.newInventoryTransferAction(self.character, itemPrimary, itemPrimary:getContainer(), ISInventoryPage.GetFloorContainer(playerNum), 1)
					if not itemSecondary or self.character:isItemInBothHands(itemPrimary) then
						action:setOnComplete(localOnCompleteDropItems)
					end
					action:MCFsetOnCancel(localOnCompleteDropItems)
					ISTimedActionQueue.add(action)
				end
				if itemSecondary and not self.character:isItemInBothHands(itemPrimary) then
					local playerNum = self.character:getPlayerNum()
					self.character:removeAttachedItem(itemSecondary)
					local action = ISInventoryTransferUtil.newInventoryTransferAction(self.character, itemSecondary, itemSecondary:getContainer(), ISInventoryPage.GetFloorContainer(playerNum), 1)
					action:setOnComplete(localOnCompleteDropItems)
					action:MCFsetOnCancel(localOnCompleteDropItems)
					ISTimedActionQueue.add(action)
				end
				if itemPrimary or itemSecondary then
					self.didDamage = "dropping"
				else
					self.didDamage = "finished"
				end

			elseif self.didDamage == false and self.character:getVariableBoolean("EarlyExitVehicleFallDamage") == true then
				self.character:setVariable("EarlyExitVehicleFallDamage", false)
				self.didDamage = true
				local args = { vspeed = self.speed }
				sendClientCommand(self.character, 'MoreCarFeatures', "EarlyExitVehicleFallDamage", args)
			end

			if self.speed <= 30 then
				if self.character:getVariableBoolean("EarlySprintAway") == true and ((self.keyRun and isKeyDown(self.keyRun)) or (self.keySprint and isKeyDown(self.keySprint))) then
					self.character:setVariable("StumbleVehicleExitRoll", false)
					self.character:setVariable("EarlySprintAway", false)
				elseif self.character:getVariableBoolean("StumbleVehicleExitRoll") ~= false then
					return
				end
			elseif self.speed <= 50 then
				if self.character:getVariableBoolean("TripVehicleExitRoll") ~= false then
					return
				end
			elseif self.character:getVariableBoolean("TumbleVehicleExitRoll") ~= false then
				return
			end

			self.character:setIgnoreMovement(false)
			self.character:setIgnoreAimingInput(false)
			self.character:setIgnoreInputsForDirection(false)

			if isClient() then
				sendClientCommand(self.character, 'MoreCarFeatures', "SyncFallExitVehicleEND", { } )
			end

			Events.OnTick.Remove(continueAnimChecksOnCancel)
		end
		Events.OnTick.Add(continueAnimChecksOnCancel)
	else
		self.character:setIgnoreMovement(false)
		self.character:setIgnoreAimingInput(false)
		self.character:setIgnoreInputsForDirection(false)
	end

	ISBaseTimedAction.stop(self)
end

local ISExitVehiclePerform = ISExitVehicle.perform
function ISExitVehicle:perform()
	if not SandboxVars.GamestaVehicleZones.earlyExitVehicle or (self.vehicle and string.contains(self.vehicle:getScriptName(), "Boat")) then
		ISExitVehiclePerform(self)
		return
	end

	if self.speed <= 10 then
		self.vehicle:exit(self.character)
		self.vehicle:setCharacterPosition(self.character, self.seat, "outside")
		self.character:PlayAnim("Idle")
		triggerEvent("OnExitVehicle", self.character)
		self.vehicle:updateHasExtendOffsetForExitEnd(self.character)

	else
		self.character:setIgnoreMovement(false)
		self.character:setIgnoreAimingInput(false)
		self.character:setIgnoreInputsForDirection(false)

		if isClient() then
			sendClientCommand(self.character, 'MoreCarFeatures', "SyncFallExitVehicleEND", { } )
		end

		ISTimedActionQueue.clear(self.character)
	end

	ISBaseTimedAction.perform(self)
end

ISExitVehicleNew = ISExitVehicle.new
function ISExitVehicle:new(character)
	if not SandboxVars.GamestaVehicleZones.earlyExitVehicle or (self.vehicle and string.contains(self.vehicle:getScriptName(), "Boat")) then
		return ISExitVehicleNew(self, character)
	end

	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.vehicle = o.character:getVehicle()
	o.stopOnWalk = false
	o.stopOnRun = false
	o.stopOnAim = false
	o.maxTime = -1
	return o
end


local ISInventoryTransferActionStop = ISInventoryTransferAction.stop
function ISInventoryTransferAction:stop()
	ISInventoryTransferActionStop(self)

	if self.MCFonCancelFunc then
		self.MCFonCancelFunc()
	end
end

function ISInventoryTransferAction:MCFsetOnCancel(_func)
	self.MCFonCancelFunc = _func
end
