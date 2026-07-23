local CarsToRecheck = {}


function setupSpawnZones()
	local sv = SandboxVars.ProjectSummerCar
	if sv.TakeOverSpawning == false then
		return end;
	
	if sv.RemoveWreckedCars == true then
		SmashedCarDefinitions.cars = {}
	end
	
	VehicleZoneDistribution.trafficjamw.chanceToSpawnBurnt = sv.BurntCarChance * 100;
	VehicleZoneDistribution.trafficjame.chanceToSpawnBurnt = sv.BurntCarChance * 100;
	VehicleZoneDistribution.trafficjamn.chanceToSpawnBurnt = sv.BurntCarChance * 100;
	VehicleZoneDistribution.trafficjams.chanceToSpawnBurnt = sv.BurntCarChance * 100;
	VehicleZoneDistribution.junkyard.chanceToSpawnBurnt = sv.BurntCarChance * 100; -- Doesn't do anything? Nobody seems to use junkyard zones. 
end
Events.OnInitGlobalModData.Add(setupSpawnZones)


function VehicleSpawnSetup(vehicle)
	-- Gets called every time a vehicle spawns or is loaded from save. 
	local sv = SandboxVars.ProjectSummerCar
	
	if sv.TakeOverSpawning == false then
		return end;
	
	--[[
	if vehicle:isSmashed() then
		-- See if we can spawn unsmashed version.
		print("Smashed name ", vehicle:getScriptName(), " or maybe ", vehicle:getScript():getFullType());
	
	end
	--]]
	
	--[[
	print("Vehicletype ", vehicle:getVehicleType(), " zone ", vehicle:getZone());
	local vehicleZone = getVehicleZoneAt(vehicle:getX(), vehicle:getY(), vehicle:getZ())	
	if vehicleZone then
		print("BackupZone ", vehicleZone:getName(), " type ", vehicleZone:getType(), " Jam ", vehicle:isInTrafficJam());
	end 	
		
		
	local targetZone = VehicleZoneDistribution[vehicle:getVehicleType()];
	if targetZone ~= nil then
		print("Quality of car in zone: ", targetZone.baseVehicleQuality);
		-- Sometimes is nil. 0.5 is bad quality, 1.2 is best, 0.8 is average, 0.2~0.3 is junkyard/traffic jam. 
		-- Maybe add 0.3 to quality? Set to 1 if nil?
	else
		print("Could not find zone ",  vehicle:getVehicleType())
	end
	
	--]]
	
	local modData = vehicle:getModData();
	if modData.SpawnChecked ~= nil then 
		return end
	modData.SpawnChecked = true; 
	-- check if user has gotten into car before and skip it
	if vehicle:isPreviouslyEntered() == true then
		return end; 
		
	--print("Setting up vehicle");
	
	local averageCondition = 0;
	local totalCond = 0
		for x = 0, vehicle:getPartCount()-1 do
			totalCond = totalCond + vehicle:getPartByIndex(x):getCondition();
		end
	averageCondition = totalCond / math.max(1,vehicle:getPartCount()) / 100
	--print("Existing Avg condition is ", averageCondition);
	
	
	averageCondition = 0;
	totalCond = 0
	for x = 0, vehicle:getPartCount()-1 do
		totalCond = totalCond + vehicle:getPartByIndex(x):getCondition();
	end
	averageCondition = totalCond / math.max(1,vehicle:getPartCount()) / 100
	--print("New Avg condition is ", averageCondition);
	table.insert(CarsToRecheck,{cond = averageCondition, time = 0, vehicle = vehicle});
end

function setupParts(vehicle)
	
	local sv = SandboxVars.ProjectSummerCar
	-- Recalculate new condition based on a few factors.

	-- Maybe give player access to biases for each major zone?
	
	--[[
	print("Vehicletype ", vehicle:getVehicleType(), " zone ", vehicle:getZone());
	local vehicleZone = getVehicleZoneAt(vehicle:getX(), vehicle:getY(), vehicle:getZ())	
	if vehicleZone then
		print("BackupZone ", vehicleZone:getName(), " type ", vehicleZone:getType(), " Jam ", vehicle:isInTrafficJam());
	end 
	--]]
	
	--VehicleZoneDistribution.bad.
	
	local BiasFactor = 1 
	--getVehicleType() returns things like parkingstall, trafficjams/trafficjame/trafficjamw/trafficjamn, bad, good, a few others? 
	-- Will be nil after vehicle is saved and loaded however.
	local targetZone = VehicleZoneDistribution[vehicle:getVehicleType()];
	if targetZone ~= nil then
		--print("Quality of car in zone: ", targetZone.baseVehicleQuality);
		-- Sometimes is nil. 0.5 is bad quality, 1.2 is best, 0.8 is average, 0.2~0.3 is junkyard/traffic jam. 
		-- add 0.3 to quality. Set to 1 if nil.
		if targetZone.baseVehicleQuality then
			BiasFactor = math.max(0.7,targetZone.baseVehicleQuality + 0.3);
		end
	end
	
	if vehicle:isInTrafficJam() then
		BiasFactor = 0.7
	end
	
	
	
	if sv.LowOrHigh < (ZombRandFloat(0,1)^BiasFactor) then
		-- RNG between low and med
		averageCondition = sv.LowCondition + ((ZombRandFloat(0,1) ^ BiasFactor) ^ (1/sv.LowToMid)) * (sv.MidCondition-sv.LowCondition);  
	else
		-- RNG between med and high
		averageCondition = sv.MidCondition + ((ZombRandFloat(0,1) ^ BiasFactor) ^ (1/sv.MidToHigh)) * (sv.HighCondition-sv.MidCondition); 
	end
	--print("Vehicle is smashed - ", vehicle:isSmashed());
	-- Todo: if smashed, replace vehicle if disable wrecked is on. 
	
	local survivorCar = vehicle:isGoodCar() and (averageCondition > 0.5)
	adjustedCondition = (averageCondition - sv.PartChanceLowCond) / (sv.PartChanceHighCond-sv.PartChanceLowCond)
	adjustedCondition = math.min(math.max(adjustedCondition,0),1)
	local partChance = sv.PartChanceLowCondChance + (sv.PartChanceHighCondChance - sv.PartChanceLowCondChance) * adjustedCondition;
	if survivorCar == true then
		--print("Survivor Car");
		partChance = ZombRandFloat(sv.PartChanceSurvivorMin,sv.PartChanceSurvivorMax);
	end	

	local modData = vehicle:getModData();
	modData.averageCondition = averageCondition; 
	modData.partChance = partChance; 

	--print ("Part chance is ", partChance); 
	
	-- Find better check 
	--local zones = getZones(x, y, z)

	
	local trafficJamPartChance = vehicle:isInTrafficJam() and ZombRandFloat(sv.PartChanceTrafficMin,sv.PartChanceTrafficMax) or 1

	for x = 0, vehicle:getPartCount()-1 do
		local part = vehicle:getPartByIndex(x);
		local isTrunk = part:getId() == "TrunkDoor" or part:getId() == "DoorRear" -- Disable removal of trunk doors/rear doors. Due to the fact it screws up rear windows in vehicles animated, and disables access to trunk. 
		-- Alternatively, edit trunk access code and remove rear window whenever you remove rear door. 
		-- Todo: remove tarps as well? (Filibuster vehicle mod)
		
		if ((ZombRandFloat(0,1) > partChance) or (ZombRandFloat(0,1) > trafficJamPartChance)) and not isTrunk then
			local window = part:getChildWindow();
			if window then
				window:setInventoryItem(nil)
				vehicle:transmitPartItem(window)
			end
			part:setInventoryItem(nil)
			vehicle:transmitPartItem(part)
		else
			if ZombRandFloat(0,1) < sv.RandomPartChance then
				part:setCondition(ZombRand(101)); 
			else
				part:setCondition((averageCondition + ZombRandFloat(0,sv.ConditionRandom) - ZombRandFloat(0,sv.ConditionRandom))*100); 
			end
		end
	end
end


function DelayedVehicleCheck()
	
	for x = #CarsToRecheck, 1, -1 do
		local averageCondition = 0;
		local totalCond = 0
		vehicle = CarsToRecheck[x].vehicle;
		-- todo: remove vehicle if null (despawns due to distance/etc)
		if vehicle and not vehicle:isRemovedFromWorld() and CarsToRecheck[x].time < 5 then
			CarsToRecheck[x].time = CarsToRecheck[x].time + 1;

			for x = 0, vehicle:getPartCount()-1 do
				totalCond = totalCond + vehicle:getPartByIndex(x):getCondition();
			end
			averageCondition = totalCond / math.max(1,vehicle:getPartCount()) / 100
			
			if math.abs(averageCondition - CarsToRecheck[x].cond) > 0.01 then
				-- These tend to be story cars. Maybe we should notify the setupParts so that it knows they are not standard 'trafficjam' cars?
				
				--print("Condition change detected after ", CarsToRecheck[x].time, " old cond ", CarsToRecheck[x].cond, " new cond ", averageCondition);
				--print("type ", vehicle:getVehicleType(), " zone ", vehicle:getZone());
				setupParts(vehicle);
				table.remove(CarsToRecheck,x) 
			end
		else
			--print("Car expired with no changes ", vehicle:getVehicleType() , " zone ", vehicle:getZone() , " Jammed ", vehicle:isInTrafficJam())
			setupParts(vehicle);
			table.remove(CarsToRecheck,x) 
		end
	end
end

function initVehicleEngine(vehicle, forcebest)

	

	itemContainer = vehicle:getPartById("Engine"):getItemContainer()
	local item = instanceItem("Base.EnginePartInitMarker")
	itemContainer:AddItem(item);
	
	local sv = SandboxVars.ProjectSummerCar
	
	local spawnList = {"OilPan","OilFilter","Radiator","Sparkplug","Crankshaft","CylinderHead","HeadGasket","Pistons","Flywheel","Transmission",
						"TorqueConverter", "Alternator","Starter","FanBelt","WaterPump","BrakeBooster","PowerSteeringPump","AirConditioner","HeaterCore"}
	
	--local carCondition = getSandboxOptions():getOptionByName("CarGeneralCondition"):getValue()
	-- Ignoring sandbox settings for now, instead looking at existing car parts. 
	--print("Car quality ", carCondition)
	local averageCondition = 0;--carCondition*20

	local totalCond = 0
	-- Guess condition based on existing car parts. 
	if vehicle:getPartCount() then
		for x = 1, vehicle:getPartCount() do
			totalCond = totalCond + vehicle:getPartByIndex(x-1):getCondition();
		end
	end
	averageCondition = totalCond / math.max(1,vehicle:getPartCount()) / 100
	
	local modData = vehicle:getModData();
	averageCondition = modData.averageCondition or averageCondition; 
	

	
	--print("Avg body part condition ", averageCondition);
	
	local survivorCar = vehicle:isGoodCar() and (averageCondition > 0.5) -- Prevents considering cars that got reset to 0.1 condition by stories as survivor cars. 

	if forcebest == true then
		averageCondition = 10000
	end
	
	local trafficPartChance = vehicle:isInTrafficJam() and ZombRandFloat(sv.PartChanceTrafficMin,sv.PartChanceTrafficMax) or 1
	--print("Traffic part chance parts ",trafficJamChance); 
	
	
	local adjustedCondition = (averageCondition - sv.PartChanceLowCond) / (sv.PartChanceHighCond-sv.PartChanceLowCond)
	adjustedCondition = math.min(math.max(adjustedCondition,0),1)
	local partChance = sv.PartChanceLowCondChance + (sv.PartChanceHighCondChance - sv.PartChanceLowCondChance) * adjustedCondition;
	
	if survivorCar == true then
		--print("Survivor Car");
		partChance = ZombRandFloat(sv.PartChanceSurvivorMin,sv.PartChanceSurvivorMax);
	end
	
	partChance = modData.partChance or partChance; -- Use the part chance that was generated during the part setup stage, if it exists. 
	
	
	for a,b in pairs(spawnList) do
		local condition = 0;
		if ZombRandFloat(0,1) < sv.RandomPartChance then
			condition = ZombRand(101) -- fully random chance, to simulate early failures/previously replaced parts. 
		else -- Regular condition distribution
			condition = math.min(math.max(averageCondition + ZombRandFloat(0,sv.ConditionRandom) - ZombRandFloat(0,sv.ConditionRandom),0),1)
		end
		
		
		
		--print("part Chance ", partChance, " adjust cond ", adjustedCondition, " High chance ", sv.MissingPartChanceHighCondChance, " low chance ", );
		
		if ((ZombRandFloat(0,1) < partChance) and (ZombRandFloat(0,1) < trafficPartChance)) or forcebest then
			local vehicleType = vehicle:getScript():getMechanicType();
			
			newItemName = "Base."..b
			if newItemName == "Base.Transmission" then
				if vehicle:getScript():getEngineRPMType() == "firebird" then 
					newItemName = newItemName .. 4 .. "_" .. vehicleType; -- pick 5 speed. Maybe make it only sometimes pick this one? or only 4/4ht/5 speed?
				elseif vehicle:getScript():getEngineRPMType() == "Rotators.SemiTruckRPM" then
					newItemName = newItemName .. 5 .. "_" .. vehicleType 
				else
					newItemName = newItemName .. ZombRand(3)+1 .. "_" .. vehicleType; -- Randomly pick transmission 1~3. Maybe base it off the cars gear ratio count instead?
				end
			elseif newItemName == "Base.TorqueConverter" then
				local converter = 1;
				if ZombRand(5) == 0 then -- Low chance of other type of torque converter. 
					converter = 2
				end
				
				if vehicle:getScript():getEngineRPMType() == "firebird" then 
					newItemName = newItemName .. converter+1 .. "_" .. vehicleType; -- pick medium or high stall. (2 or 3)
				else
					newItemName = newItemName .. converter .. "_" .. vehicleType; -- pick low or medium stall (1 or 2)
				end
			elseif (newItemName == "Base.Radiator") or (newItemName == "Base.Sparkplug")  or (newItemName == "Base.Crankshaft") or (newItemName == "Base.CylinderHead") or (newItemName == "Base.Pistons") or (newItemName == "Base.Flywheel") then
				if vehicle:isGoodCar() and (ZombRand(6)) == 0 then
					newItemName = newItemName .. (ZombRand(3)+1) .. "_" .. vehicleType -- one in 10 chance of upgraded part
				elseif (ZombRand(60) == 0) then
					newItemName = newItemName .. (ZombRand(3)+1) .. "_" .. vehicleType -- one in 100 chance of upgraded part. 
				else
					newItemName = newItemName .. 1 .. "_" .. vehicleType -- Standard part
				end
			else
				newItemName = newItemName .. "1_" .. vehicleType -- Default prefix
			end
			item = instanceItem(newItemName)
			if item == nil then
				print("Could not find ", newItemName, " to spawn");
			else
				if item:getFluidContainer() then
					fluidAmount = averageCondition + ZombRandFloat(0,sv.ConditionRandom) - ZombRandFloat(0,sv.ConditionRandom) ; -- Makes a nice bell curve by using random twice. 
					fluidAmount = math.min(math.max(fluidAmount,0),1);
					--print("Creating fluid ".. item:getFluidContainer():getPrimaryFluid():getFluidTypeString() .. " with capacity " .. fluidAmount)
					item:getFluidContainer():adjustAmount(fluidAmount * item:getFluidContainer():getCapacity())
					
					if item:getFluidContainer():contains(Fluid.Get("MotorOil")) then -- Small side effect is vehicles with no good oil will have no used oil either. 
						local usedOil = ZombRandFloat(0,0.5) * item:getFluidContainer():getFreeCapacity()
						print("Adding " .. usedOil .. " used oil");
						item:getFluidContainer():addFluid("UsedMotorOil",usedOil)
					end
					if item:getFluidContainer():contains(Fluid.Get("Water")) then
						item:getFluidContainer():adjustAmount(fluidAmount * item:getFluidContainer():getCapacity() * 0.5f)
						local antifreeze = ZombRandFloat(0.5,1.7) * fluidAmount * item:getFluidContainer():getCapacity() * 0.5f
						print("Adding " .. antifreeze .. " antifreeze");
						item:getFluidContainer():addFluid("Antifreeze",antifreeze)
					end

				end
				if not item:hasTag("EnginePartInitMarker") then -- Don't set EnginePartInitMarker condition. 
					item:setCondition(condition*100)
				end
				itemContainer:AddItem(item);
			end
			
		end
	end
end

-- Hook here so that whenever you get into a vehicle it is setup.
function EngineSetupEnterVehicle(character)
	local vehicle = character:getVehicle()
	if not vehicle then return; end
	local engine = vehicle:getPartById("Engine")
	if engine then
		local itemContainer = engine:getItemContainer()
		if itemContainer then
			if not itemContainer:containsTag("EnginePartInitMarker") then	
				if instanceof(character, 'IsoPlayer') and character:isLocalPlayer() then
					initVehicleEngine(vehicle, false)
				end
			end
		end
	end
end


-- Hook here so that the vehicle is inited whenever you open the mechanic menu
oldVehicleMechanicsinitParts = ISVehicleMechanics.initParts
function ISVehicleMechanics:initParts()

	if not self.vehicle then return; end
	local engine = self.vehicle:getPartById("Engine")
	if engine then
		local itemContainer = engine:getItemContainer()
		if itemContainer then
			if not itemContainer:containsTag("EnginePartInitMarker") then
				initVehicleEngine(self.vehicle, false)
			end
		end
	end
	oldVehicleMechanicsinitParts(self)
end


Events.OnTick.Add(DelayedVehicleCheck);

Events.OnSpawnVehicleEnd.Add(VehicleSpawnSetup);
Events.OnEnterVehicle.Add(EngineSetupEnterVehicle)