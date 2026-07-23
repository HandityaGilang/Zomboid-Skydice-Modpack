require "Vehicles/ISUI/ISVehicleMenu"
require "Vehicles/ISUI/ISVehicleDashboard"

--[[

require "DebugUIs/DebugChunkState/DebugChunkStateUI"
oldDebugChunkState = DebugChunkStateUI_OptionsPanel.new
function DebugChunkStateUI_OptionsPanel:new(x, y, width, height, gameState)
GlobalGameStateThingy = gameState;
return oldDebugChunkState(self,x, y, width, height, gameState);
end

function Tooljava0(func)
	return GlobalGameStateThingy:fromLua0(func)
end

function Tooljava1(func, arg0)
	return GlobalGameStateThingy:fromLua1(func, arg0)
end

function Tooljava2(func, arg0, arg1)
	return GlobalGameStateThingy:fromLua2(func, arg0, arg1)
end
--]]


function chargeBattery(vehicle, delta)
	local battery = vehicle:getBattery()
	if not battery then return end
	if not battery:getInventoryItem() then return end
	--print("battery used delta is", battery:getInventoryItem():getUseDelta())
	local chargeOld = battery:getInventoryItem():getCurrentUsesFloat()
	--battery:getInventoryItem():setUseDelta(0.0000001) -- Makes battery usage more accurate? Maybe. 
	
	local charge = chargeOld
	charge = math.min(math.max(charge + delta,0),1)
	battery:getInventoryItem():setUsedDelta(charge)
	--if charge ~= chargeOld then
		--if VehicleUtils.compareFloats(chargeOld, charge, 2) then
			--vehicle:transmitPartUsedDelta(battery)
		--end
	--end
end

--depend on self.vehicle:isStarting() and updating every frame since we can't hook starting via pressing forward on the arrow keys. (we could disable that maybe and do it ourselves?)
function RealisticStartingUpdate()
	

	local vehicle = getPlayer():getVehicle()
	--print(GlobalGameStateThingy);
	
	--startCameraLockX = startCameraLockX or 0;
	--startCameraLockY = startCameraLockY or 0;
	--[[
	-- Ignore this!
	if GlobalGameStateThingy ~= nil then
		print("GLOBAL1234");
		wasInVehicle = wasInVehicle or false;
		if vehicle then
	
			if not wasInVehicle then
				wasInVehicle = true
				-- record current position as master offset.
				print("Recording position")
				CarPositionForCameraX = vehicle:getX()
				CarPositionForCameraY = vehicle:getY()
			end
		
			local offsetX = vehicle:getX() - CarPositionForCameraX
			local offsetY = vehicle:getY() - CarPositionForCameraY
		
			Tooljava2("dragCamera", offsetX, offsetY)
		else
			wasInVehicle = false;
			--startCameraLockX = Tooljava0("getCameraDragX") + 3
			--startCameraLockY = Tooljava0("getCameraDragY")
		end
	
	end--]]
	

	if vehicle then
		local timeSince = getGameTime():getRealworldSecondsSinceLastUpdate()
		
		startingFrames = startingFrames or 0
		startingTime = startingTime or 0
		wasStarting = wasStarting or 0
		
		if vehicle:isStarting() then
			wasStarting = true;
			startingFrames = startingFrames + 1
			startingTime = startingTime + timeSince;
		else
			if wasStarting == true then
				print("startingFrames ",startingFrames , " startingTime ",startingTime);
				startingTime = 0;
				startingFrames = 0;
			end
			wasStarting = false;
		
		end
		
		
		if vehicle:isStarting() then
			--Make charge drawn depend on battery condition
			--Should check to make sure player is in seat 1 so we don't do silly things in MP?
			local engine = vehicle:getPartById("Engine");
			starter = engine:getItemContainer():getFirstTag("EngineStarter")
			if starter and starter:getCondition() > 0 then
			crankTime = crankTime or 0; 
			crankTime = crankTime + timeSince;
			
			local condition = vehicle:getBattery():getCondition()
			if crankTime > 1.0 then
				crankTime = 0; 
				--print("1 second of cranking");
				if ZombRand(5) == 0 then -- Should be aprox 1 damage per 4~ starts. (Estimated 160 calls per start? Should be corrected for FPS? Idea, keep track of cranking time and apply damage check every 0.2 seconds. 
					vehicle:getBattery():setCondition(condition-1)
				end
			end
			local sv = SandboxVars.ProjectSummerCar	
			
			condition = math.max(0,math.min(50,condition))/50 -- Clamp condition to 0 to 50 and then to 0~1
			local capacity = sv.BatteryCapacity * (sv.BatteryCapacityLowConditionMultiplier + (condition * (1-sv.BatteryCapacityLowConditionMultiplier)))
			local usage = 0.04 / capacity -- 4% per second, starting is 1~2 seconds long. 
			
			-- Maybe only execute charge battery if % builds over a certain amount?
			
			chargeBattery(vehicle, -usage * timeSince)
			end
		end
	end
end

Events.OnTick.Add(RealisticStartingUpdate)

