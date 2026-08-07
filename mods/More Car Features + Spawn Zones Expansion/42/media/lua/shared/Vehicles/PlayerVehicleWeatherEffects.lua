
local function extraWeatherEffects()
if SandboxVars.GamestaVehicleZones.weatherEffects ~= true then return end

local function compatibleVehicleForWeatherEffects(vehicle)
	return vehicle and vehicle:getScript():getPartById("Windshield") and not string.contains(vehicle:getScriptName(), "Trailer") and not string.contains(vehicle:getScriptName(), "Boat")
end

local function clamp(_value, _min, _max)
	if _min > _max then _min, _max = _max, _min; end;
	return math.min(math.max(_value, _min), _max);
end

local function hasEyeCover(player)
	return player:getWornItem(ItemBodyLocation.EYES)
--	or player:getWornItem(ItemBodyLocation.MASK)	??? Why is there no MASK_MOUTH...
	or player:getWornItem(ItemBodyLocation.MASK_EYES)
	or player:getWornItem(ItemBodyLocation.MASK_FULL)
	or player:getWornItem(ItemBodyLocation.FULL_HAT)
	or player:getWornItem(ItemBodyLocation.FULL_SUIT_HEAD)
	or player:getWornItem(ItemBodyLocation.SCBA)
	or player:getWornItem(ItemBodyLocation.SCBANOTANK)
end

local function getLightFrontVehicle(player, vehicle, dist)
	local dir = player:getDir()
	local lightArea = vehicle:getAreaCenter(vehicle:getPartById("EngineDoor"):getArea())
	local x, y, z = lightArea:getX(), lightArea:getY(), vehicle:getZ()
	local c = dist
	local h = math.sqrt(dist)
	if     (dir == IsoDirections.N) then return getCell():getOrCreateGridSquare(x, y-c, z)
	elseif (dir == IsoDirections.NE) then return getCell():getOrCreateGridSquare(x+h, y-h, z)
	elseif (dir == IsoDirections.E) then return getCell():getOrCreateGridSquare(x+c, y, z)
	elseif (dir == IsoDirections.SE) then return getCell():getOrCreateGridSquare(x+h, y+h, z)
	elseif (dir == IsoDirections.S) then return getCell():getOrCreateGridSquare(x, y+c, z)
	elseif (dir == IsoDirections.SW) then return getCell():getOrCreateGridSquare(x-h, y+h, z)
	elseif (dir == IsoDirections.W) then return getCell():getOrCreateGridSquare(x-c, y, z)
	elseif (dir == IsoDirections.NW) then return getCell():getOrCreateGridSquare(x-h, y-h, z)
	end
end

local function getWeatherType()
	local snowStrength = getClimateManager():getSnowStrength()
	local precipitationIntensity = getClimateManager():getPrecipitationIntensity()
--	print("snowStrength:", snowStrength)
--	print("precipitationIntensity:", precipitationIntensity)
	if snowStrength > 0 then
		return {"isSnowing", snowStrength*10}
	elseif precipitationIntensity > 0 then
		return {"isRaining", precipitationIntensity*10}
	end
	return {"isNormal", nil}
end

local function remakeLightPenaltyForVehicle(_character, _square, _doReduction)
	local lightLevel = _square:getLightLevel(_character:getPlayerNum())
	local effectReduction = forageSystem.getDarknessEffectReduction(_character)
	local lightPenalty = 0
	if _doReduction then
		lightPenalty = (1 - lightLevel) * effectReduction;
	else
		lightPenalty = (1 - lightLevel)
	end
	return clamp(1 - lightPenalty, 1 - (forageSystem.lightPenaltyMax / 100), 1)
end

local ForageSystemGetLightLevelPenalty = forageSystem.getLightLevelPenalty
function forageSystem.getLightLevelPenalty(_character, _square, _doReduction)
	local vehicle = _character:getVehicle()
	if compatibleVehicleForWeatherEffects(vehicle) then
		local darkLevel = remakeLightPenaltyForVehicle(_character, getLightFrontVehicle(_character, vehicle, 4), _doReduction)
		local weather = getWeatherType()
		if weather[1] ~= "isNormal" then
			darkLevel = darkLevel - ((weather[2] / 10) * (vehicle:getSpeed2D() / 20))
		end
		darkLevel = math.max(darkLevel, 0.1)
		return darkLevel
	end

	return ForageSystemGetLightLevelPenalty(_character, _square, _doReduction)
end

local bodyPartsTable = {
	["Torso_Upper"]	=	true,
	["Torso_Lower"]	=	true,
	["Groin"]		=	true,
	["UpperArm_L"]	=	true,
	["UpperLeg_L"]	=	true,
	["UpperArm_R"]	=	true,
	["UpperLeg_R"]	=	true,
}
local function getSizeCovering(coverdParts)
	local totalSizeCover = 0
	for i = 0, coverdParts:size() - 1 do
		if bodyPartsTable[coverdParts:get(i):toString()] then
			totalSizeCover = totalSizeCover + 1
		end
	end
	return totalSizeCover
end
local getBodyPartTable = {
	["Torso_Upper"]	=	"Torso_Upper",
	["Torso_Lower"]	=	"Torso_Lower",
	["Groin"]		=	"Groin",
	["UpperArm_L"]	=	"UpperArm_L",
	["UpperLeg_L"]	=	"UpperLeg_L",
	["UpperArm_R"]	=	"UpperArm_R",
	["UpperLeg_R"]	=	"UpperLeg_R",
}
local function getBodyPartConv(bloodPart)
	return BodyPartType.FromString(getBodyPartTable[bloodPart])
end
local getBodyPartNumTable = {
	[1]	=	"Torso_Upper",
	[2]	=	"Torso_Lower",
	[3]	=	"Groin",
	[4]	=	"UpperArm_L",
	[5]	=	"UpperLeg_L",
	[6]	=	"UpperArm_R",
	[7]	=	"UpperLeg_R",
}

local function applyRainWetness(player, target, leftSide, rightSide)
	if target <= 0 then return end
	local server = isServer()
	local rainCheckMiddle = {
		["Torso_Upper"]	=	true,
		["Torso_Lower"]	=	true,
		["Groin"]		=	true,
	}
	local rainCheckLeft = {
		["UpperArm_L"]	=	true,
		["UpperLeg_L"]	=	true,
	}
	local rainCheckRight = {
		["UpperArm_R"]	=	true,
		["UpperLeg_R"]	=	true,
	}
	local alreadyInserted = {
		["Torso_Upper"]	=	true,
		["Torso_Lower"]	=	true,
		["Groin"]		=	true,
		["UpperArm_L"]	=	true,
		["UpperLeg_L"]	=	true,
		["UpperArm_R"]	=	true,
		["UpperLeg_R"]	=	true,
	}
	local subtractInserted = {
		["Torso_Upper"]	=	true,
		["Torso_Lower"]	=	true,
		["Groin"]		=	true,
		["UpperArm_L"]	=	true,
		["UpperLeg_L"]	=	true,
		["UpperArm_R"]	=	true,
		["UpperLeg_R"]	=	true,
	}
	local equippedClothing = {}
	local it = player:getInventory():getItems()
	for i = 0, it:size() - 1 do
		local item = it:get(i)
		if player:isEquipped(item)
			and item:getCategory() == "Clothing"
			and item:getClothingItem()
			and item:getCoveredParts():size() > 0
		then
			table.insert(equippedClothing, item)
		end
	end
	local resClothes = {}
	local coveredPartsBod = {}
	local bodDam = player:getBodyDamage()
	for _, item in ipairs(equippedClothing) do
		local addCloth = false
		local coverdParts = item:getCoveredParts()
		local wetRes = item:getWaterResistance()
		for i = 0, coverdParts:size() - 1 do
			local part = coverdParts:get(i)
			local partName = part:toString()
			if (leftSide and rainCheckLeft[partName] ) 
			or (rightSide and rainCheckRight[partName]) 
			or rainCheckMiddle[partName]
			then
				addCloth = true
				if alreadyInserted[partName] then
					table.insert(coveredPartsBod, partName)
					alreadyInserted[partName] = false
				end
			end
		end
		if addCloth then table.insert(resClothes, item) end
	end
	table.sort(resClothes, function(a, b)
		local aTest = getSizeCovering(a:getCoveredParts())
		local bTest = getSizeCovering(b:getCoveredParts())
		if aTest ~= bTest then
			return aTest > bTest
		end
		return a:getWaterResistance() > b:getWaterResistance()
	end)
	local totalBodyWetness = 0
	for i = 1, 7 do
		local partName = coveredPartsBod[i]
		if partName then
			subtractInserted[partName] = false
			local skipBodyPart = false
			local totalWetRes = 0
			local bodyPart = bodDam:getBodyPart(getBodyPartConv(partName))
			for _, item in ipairs(resClothes) do
	--			print("Clothing Order: ", item, " ", getSizeCovering(item:getCoveredParts()), " ", item:getWaterResistance())
				local wetRes = item:getWaterResistance()
				local coverdParts = item:getCoveredParts()
				for k = 0, coverdParts:size() - 1 do
					if partName == coverdParts:get(k):toString() then
						totalWetRes = totalWetRes + wetRes
						if totalWetRes >= 1 then
							skipBodyPart = true
							break
						end
						local wetReduction = (target*-(totalWetRes-1))/getSizeCovering(coverdParts)
						local setWetness = item:getWetness() + wetReduction/18		--18 for ALL body parts
						if setWetness <= 100 then
							item:setWetness(setWetness)		-- + to compensate for sync timing
							if server then item:syncItemFields() end		--ClothingWetnessSync(player)
						end
						break
					end
				end
				if skipBodyPart then break end
			end
			if not skipBodyPart then
				local addWet = (target*-(totalWetRes-1))/7
				totalBodyWetness = totalBodyWetness + addWet
	--			print("Wet Res Not Full Over Body Part: ", partName, " ", addWet)
			--	print(bodyPart)
			--	print("getWet ", bodyPart:getWetness())
			--	print("addWet ", addWet)
			--	print("setWetPrediction ", bodyPart:getWetness()+addWet)
		--		bodyPart:setWetness(bodyPart:getWetness()+addWet)
			--	print("setWet1 ", bodyPart:getWetness())
		--		if server then syncBodyPart(bodyPart, BodyPartSyncPacket.BD_BodyDamage) end
			--	print("setWet2 ", bodyPart:getWetness())
			end
	--		print("Total Wet Res of Body Part: ", partName, " ", totalWetRes)
		else
			for k = 1, 7 do
				partName = getBodyPartNumTable[k]
				if subtractInserted[partName] 
				and ((leftSide and rainCheckLeft[partName]) 
				or (rightSide and rainCheckRight[partName])
				or rainCheckMiddle[partName])
				then
					subtractInserted[partName] = false
					totalBodyWetness = totalBodyWetness + target/7
		--			print("No Clothing Over Body Part: ", partName, " ", target/7)
			--		local bodyPart = bodDam:getBodyPart(BodyPartType.FromString(partName))
				--	print(bodyPart)
				--	print("getWet ", bodyPart:getWetness())
				--	print("addWet ", target/7)
				--	print("setWetPrediction ", bodyPart:getWetness()+target/7)
			--		bodyPart:setWetness(bodyPart:getWetness()+target/7)
				--	print("setWet1 ", bodyPart:getWetness())
			--		if server then syncBodyPart(bodyPart, BodyPartSyncPacket.BD_BodyDamage) end
				--	print("setWet2 ", bodyPart:getWetness())
					break
				end
			end
		end
	end
	--	print("getWetness: ", player:getStats():get(CharacterStat.WETNESS))
	if totalBodyWetness > 0 then
		totalBodyWetness = totalBodyWetness/18		--18 for ALL body parts
		bodDam:increaseBodyWetness(totalBodyWetness/3)		--Less so clothing gets wet before the player gets maxed out
	--	print("totalBodyWetness: ", totalBodyWetness)
	--	print("should be wet on loop return: ", player:getStats():get(CharacterStat.WETNESS))
		if server then sendDamage(player) end
	end
end


if isServer() then
	local function onClientCommand(module, command, playerObj, args)
		if module == 'MoreCarFeatures' and command == "applyRainWetness" then
			args = args or {}
			if args[1] then
				local totalTargetBoth, totalTargetLeft, totalTargetRight, totalTargetCenter = 0, 0, 0, 0
				for _, stats in ipairs(args[1]) do
	--				print(playerObj, " ", stats[1], " ", stats[2], " ", stats[3])
					if stats[2] and stats[3] then
						totalTargetBoth = totalTargetBoth + stats[1]
					elseif stats[2] then
						totalTargetLeft = totalTargetLeft + stats[1]
					elseif stats[3] then
						totalTargetRight = totalTargetRight + stats[1]
					else
						totalTargetCenter = totalTargetCenter + stats[1]
					end
				end
				if totalTargetBoth > 0 then
					applyRainWetness(playerObj, totalTargetBoth, true, true)
				end
				if totalTargetLeft > 0 then
					applyRainWetness(playerObj, totalTargetLeft, true, false)
				end
				if totalTargetRight > 0 then
					applyRainWetness(playerObj, totalTargetRight, false, true)
				end
				if totalTargetCenter > 0 then
					applyRainWetness(playerObj, totalTargetRight, false, false)
				end
			end
		end
	end
	Events.OnClientCommand.Add(onClientCommand)

	return		--The rest of the file is for the Client (or just Singleplayer)
end


local function onEnterVehicle(player)
	local vehicle = player:getVehicle()
	if not vehicle then return end

	local client = isClient()
	local wetQ = {}
	local everyXTickQ = 50
	local function queuedWetness()
		for _, test in ipairs(wetQ) do		--Easiest way to search for an empty table, not a loop
			sendClientCommand(player, "MoreCarFeatures", "applyRainWetness", {wetQ})
			wetQ = {}
			return
		end
	end

	local getVehicle, origSeat = vehicle, vehicle:getSeat(player)
	local door, seatPart = vehicle:getPassengerDoor(origSeat), vehicle:getAllSeatParts():get(origSeat)
	local weather, speed, side = getWeatherType(), (vehicle:getCurrentSpeedKmHour()/10)*3, string.lower(seatPart:getId())
	local function OnSwitchSeatExitVehicle()
		getVehicle = player:getVehicle()
		if getVehicle and vehicle == getVehicle then
			if isClient then
				everyXTickQ = everyXTickQ - 1
				if everyXTickQ <= 0 then
					queuedWetness()
					everyXTickQ = 50
				end
			end
			weather = getWeatherType()
			speed = vehicle:getCurrentSpeedKmHour()/2
			local getSeat = vehicle:getSeat(player)
			if origSeat == getSeat then return end		--Still in same seat, nothing changed.
			origSeat, seatPart = getSeat, vehicle:getAllSeatParts():get(getSeat)
			side = string.lower(seatPart:getId())
			local doorPart = vehicle:getPassengerDoor(getSeat)
			if doorPart and doorPart:getDoor() and (doorPart:getItemType() and not doorPart:getItemType():isEmpty()) then
				door = doorPart
			else
				door = nil
			end
			return		--continue loop
		end
		Events.OnTick.Remove(OnSwitchSeatExitVehicle)
	end
	Events.OnTick.Add(OnSwitchSeatExitVehicle)		--Not using OnSwitchVehicleSeat or OnExitVehicle because shift + e entering (or other modded events) places the character in a different seat, this is more reliable

	local tPast1, tPast2 = 0, 0
	local tGame = GameTime.getInstance()

	local function DoorWindowCheck()
		if getVehicle and vehicle == getVehicle then
			local newtPast = tPast1 + tGame:getTimeDelta()
			if round(tPast1, 1.7) == round(newtPast, 1.7) then
				tPast1 = newtPast
				return
			else
				tPast1 = newtPast
			end

			if not door then return end
			local wetnessFactor = 0
			if not door:getInventoryItem() then		--No Door
				wetnessFactor = 10
			else
				if door:getDoor():isOpen() then		--Open Door
					wetnessFactor = 6
				end
				local windowPart = VehicleUtils.getChildWindow(door)
				if windowPart and windowPart:getWindow() and (windowPart:getItemType() and not windowPart:getItemType():isEmpty()) then
					local window = windowPart:getWindow()
					if not windowPart:getInventoryItem() or window:isDestroyed() or (window:isOpenable() and window:isOpen()) then		--Open/No Window
						if wetnessFactor == 6 then		--Door is Open
							wetnessFactor = 8
						else							--Door is Closed
							wetnessFactor = 4
						end
					end
				end
				if wetnessFactor == 0 then return end
			end

			if weather[1] ~= "isNormal" then
				if speed > 0 and (wetnessFactor == 6 or wetnessFactor == 8) then speed = speed - speed/wetnessFactor end		--Less wet if car driven backwards (leaning back in seat makes it safer) or forwards (since the open door blocks rain)
				if isClient() then
					table.insert(wetQ, {((wetnessFactor*(weather[2]+speed))/300), string.contains(side, "left"), string.contains(side, "right")})
				else
					applyRainWetness(player, ((wetnessFactor*(weather[2]+speed))/300), string.contains(side, "left"), string.contains(side, "right"))
				end
			end

			return
		end
		Events.OnTick.Remove(DoorWindowCheck)
	end
	Events.OnTick.Add(DoorWindowCheck)

	local manager = ISSearchManager.getManager(player)
	local windshieldPart
	local function WindshieldCheck()	--TODO: add some sort of signal "Status_VisionImpaired.png"
		if getVehicle and vehicle == getVehicle then
			if not windshieldPart:getInventoryItem() then
				manager:toggleSearchMode(true)

				local newtPast = tPast2 + tGame:getTimeDelta()
				if round(tPast2, 1.7) == round(newtPast, 1.7) then
					tPast2 = newtPast
					return
				else
					tPast2 = newtPast
				end

				if weather[1] ~= "isNormal" and string.contains(side, "front") and speed >= 0 then	--Reverse can be used to avoid rain
					if isClient() then
						table.insert(wetQ, {((10*(weather[2]+speed))/300), true, true})
					else
						applyRainWetness(player, ((20*(weather[2]+speed))/300), true, true)
					end
				end
			else
				manager:toggleSearchMode(false)
			end
			return
		end
		manager:toggleSearchMode(false)
		Events.OnTick.Remove(WindshieldCheck)
	end
	if compatibleVehicleForWeatherEffects(vehicle) then		--WINDSHIELD CHECK
		windshieldPart = vehicle:getPartById("Windshield")
		Events.OnTick.Add(WindshieldCheck)
	end
end
Events.OnEnterVehicle.Add(onEnterVehicle)


--local ISSearchManagerRenderEye = ISSearchManager.renderEye	--I have no idea what this function does if not to update the eye texture...
--function ISSearchManager:renderEye()
--	local vehicle = self.character:getVehicle()
--	if compatibleVehicleForWeatherEffects(vehicle) and not vehicle:getPartById("Windshield"):getInventoryItem() then
--		print("swapping eye")
--		self.texture = getTexture("media/ui/Moodles/64/Status_VisionImpaired.png")
--	else
--		print("original eye")
--		self.texture = getTexture("media/ui/foraging/eyeconOn.png")
--	end
--	ISSearchManagerRenderEye(self)
--end

local ISSearchManagerToggleSearchMode = ISSearchManager.toggleSearchMode
function ISSearchManager:toggleSearchMode(_isSearchMode)
	ISSearchManagerToggleSearchMode(self, _isSearchMode)

	local vehicle = self.character:getVehicle()
	if compatibleVehicleForWeatherEffects(vehicle) then
		self.MCFWasInVehicle = true
	else
		self.MCFWasInVehicle = false
	end
end

local ISSearchManagerUpdateOverlay = ISSearchManager.updateOverlay
function ISSearchManager:updateOverlay()
	ISSearchManagerUpdateOverlay(self)

	local vehicle = self.character:getVehicle()
	if compatibleVehicleForWeatherEffects(vehicle) then
		local speed = vehicle:getSpeed2D()
		local blurLevel = math.max(forageSystem.getPanicPenalty(self.character), forageSystem.getExhaustionPenalty(self.character))
		local darkLevel = 1
		if self.modifiers and self.modifiers.lightPenalty then	--mod conflict?
			darkLevel = self.modifiers.lightPenalty
		end
		local radius = math.max((blurLevel / 10) / math.max(speed, 0.1) * darkLevel * 7000, 3)	--The last large number can be used to tweak the radius overall slightly
		blurLevel = math.min(math.max(1 - blurLevel, speed / 30, 0.1), 1.0)
		darkLevel = math.min(math.max((1 - darkLevel - 0.3) * (10/7), 0.1), 1.0)
		if hasEyeCover(self.character) then
			radius = radius * 1.5
			blurLevel = blurLevel / 1.5
		end
		radius = math.min(radius, 100)	--Takes a while to switch from high to low radius levels, so it needs a cap
--	print("radius:", radius)
		local smo = self.searchModeOverlay
		smo:getDesat():setTargets(0, 0)
		smo:getBlur():setTargets(blurLevel, blurLevel)
		smo:getDarkness():setTargets(darkLevel, darkLevel)
		smo:getRadius():setTargets(radius, radius)
	elseif self.MCFWasInVehicle then
		local smo = self.searchModeOverlay
		smo:getDesat():setTargets(0, 0)
		smo:getBlur():setTargets(0, 0)
		smo:getDarkness():setTargets(0, 0)
		smo:getRadius():setTargets(0, 0)
	end
end

function ISSearchManager:doDisableCheck()
	local vehicle = self.character:getVehicle()
	if vehicle and (not vehicle:getScript():getPartById("Windshield") or string.contains(vehicle:getScriptName(), "Trailer")) then self:toggleSearchMode(false) return end
	local disableTick = -1;
	if self:checkShouldDisable() then disableTick = 1; end;
	self.disableTick = clamp(self.disableTick + disableTick, 0, self.disableTickMax);
	if self.disableTick >= self.disableTickMax then self:toggleSearchMode(false); end;
end

local ISSearchManagerCheckShouldDisable = ISSearchManager.checkShouldDisable
function ISSearchManager:checkShouldDisable()
	local vehicle = self.character:getVehicle()
	if compatibleVehicleForWeatherEffects(vehicle) then
		return false
	end

	return ISSearchManagerCheckShouldDisable(self)
end


end
Events.OnInitGlobalModData.Add(extraWeatherEffects)