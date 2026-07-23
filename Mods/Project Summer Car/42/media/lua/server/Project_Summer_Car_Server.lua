require "Vehicles/Vehicles"
require "Items/ProceduralDistributions"
require "Items/SuburbsDistributions"
require "Items/Distributions"

local STARLIT_ENABLED = getActivatedMods():contains("\\StarlitLibrary")
-- Add starlit require here?

function AddItems(items)
	table.insert(items, "BottleATF"); 
	table.insert(items, 6);
	table.insert(items, "BottleMotorOil"); 
	table.insert(items, 4);
	table.insert(items, "BottleMotorOilCan"); 
	table.insert(items, 2);
	table.insert(items, "BottleAntifreeze1"); 
	table.insert(items, 3);
	table.insert(items, "BottleAntifreeze2"); 
	table.insert(items, 3);
	table.insert(items, "ToolKit"); 
	table.insert(items, 0.3);	
end

AddItems(ProceduralDistributions.list.MechanicSpecial.items)
AddItems(ProceduralDistributions.list.ToolCabinetMechanics.items)
AddItems(ProceduralDistributions.list.MechanicShelfTools.items)
AddItems(ProceduralDistributions.list.GarageMechanics.items)

function Vehicles.NeverAccessEngine(vehicle, part, chr)
	return false --getCore():getDebug() and ISEngineMechanics.cheat
	end
	
function VehicleUtils.chargeBattery(vehicle, delta)
	local modData = vehicle:getModData();
	modData.batteryDraw = (modData.batteryDraw or 0) - delta;
end

	
-- Overwrite check engine function to support new parts.
function Vehicles.CheckEngine.Engine(vehicle, part)

	local partCondition = part:getCondition()
	local modData = part:getModData();
	local oldCondition = modData.lastEngineCondition
	if oldCondition == nil then
		oldCondition = partCondition
		print("Nil old condition")
	end

	local engineItems = part:getItemContainer():getItems()
	if partCondition < oldCondition and engineItems then
		local sv = SandboxVars.ProjectSummerCar	
		
		local damage = oldCondition - partCondition;
		--print("Engine damage Detected " .. damage .. " Partcondition was " .. partCondition .. " and old condition was " .. oldCondition)
		for x = 1, sv.EngineImpactDamageCount do -- Damage 4 parts in every impact since there are so many engine parts to soak up damage and damage is limited to lowest main engine parts condition.
			local partToDamage = engineItems:get(ZombRand(engineItems:size()))
			if partToDamage then
				if not partToDamage:hasTag("EnginePartInitMarker") then -- Don't damage init marker. 
					partToDamage:setCondition(math.max(0,partToDamage:getCondition() - (damage * sv.EngineImpactDamage * (ZombRandFloat(0,0.50)+0.50)))) 
				end
			end
		end
	end

	
	local criticalEngineCount = 5 -- Number of critical engine components that must exist
	local minCondition = 100
	for x=0, engineItems:size()-1 do
		local item = engineItems:get(x)
		if item:hasTag("EngineCritical") then 
			minCondition = math.min(minCondition,item:getCondition())
			criticalEngineCount = criticalEngineCount-1
		end
	end
	if criticalEngineCount > 0 then
		minCondition = 0
	end
	
	modData.lastEngineCondition = minCondition;
	
	if minCondition ~= partCondition then
		part:setCondition(minCondition) -- Set engine to mirror lowest component. 
		print("Lowering engine condition due to part damage to ", minCondition)
	end
	
	-- Randomizer here to cause random stalls if condition of components is super low!
	local stallLevel = ZombRand(10) * ZombRand(10) * 0.1
	if ZombRand(60) == 0 then
		return minCondition > stallLevel
	else
		return minCondition > 0
	end
end


-- Results in 0~1 scale, to support future parts with different max conditions
function GetAverageEngineCondition(enginePart, partList)
	local condition = 0
	for x = 1, #partList do
		local curPart = enginePart:getItemContainer():getFirstTag(partList[x])
		if curPart then
			condition = condition + curPart:getCondition()
		end
	end
	return condition / #partList / 100.0
end

function GetPartCondition(enginePart,partname)
	local curPart = enginePart:getItemContainer():getFirstTag(partname)
	if curPart then
		return curPart:getCondition()
	end
	return 0
end



function DamageRandomPart(enginePart, partlist,randomChance)
	local choice = ZombRand(math.max(#partlist,randomChance))
	if choice < #partlist then
		local partToDamage = enginePart:getItemContainer():getFirstTag(partlist[choice+1])
		if partToDamage then
			partToDamage:setCondition(partToDamage:getCondition() - 1)
		end
	end
end

function lerpHelper(start,target,value)
return start+((target-start) * value)
end

function Vehicles.Update.Engine(vehicle, part, elapsedMinutes)
	--if elapsedMinutes > 20 then
	--	print("Project Summer car - Excessive elapsedMinutes ",elapsedMinutes)
	--end
	if not Vehicles.elaspedMinutesForEngine[vehicle:getId()] then
		Vehicles.elaspedMinutesForEngine[vehicle:getId()] = 0;
	end
	-- Simulate lost time in steps since simulation is complex and does not enjoy timesteps of hundreds of minutes. 
	while elapsedMinutes > 10 do
		EngineUpdateInternal(vehicle,part,10)
		elapsedMinutes = elapsedMinutes - 10
	end
	EngineUpdateInternal(vehicle,part,elapsedMinutes)
end

function EngineUpdateInternal(vehicle, part, elapsedMinutes)

	local partData = part:getModData()
	-- Init mod data to current ambient temp
	partData.temperature = partData.temperature or getClimateManager():getTemperature()
	partData.temperatureRadiator = partData.temperatureRadiator or getClimateManager():getTemperature()
	partData.temperature = math.min(math.max(partData.temperature,-100),200); -- Sanity checking values
	partData.temperatureRadiator = math.min(math.max(partData.temperatureRadiator,-100),200);
	
	
	local previousTemp = partData.temperature;
	
	-- reset HP/engine quality (for starting purposes) and loudness.
	-- For some reason, my mod resets engine quality to 98~100 on load? and HP back to stock?
	-- Could be the engine changes? dunno. 
	
	local avgEngineCond = GetAverageEngineCondition(part,{"EnginePistons","EngineCylinderHead","EngineCrankshaft"})
	
	local partList = {"EnginePistons","EngineCylinderHead","EngineCrankshaft","EngineSparkplug"}
	local partPerformance = 0
	for x = 1, #partList do
		local curPart = part:getItemContainer():getFirstTag(partList[x])
		if curPart then
			partPerformance = partPerformance + curPart:getScriptItem():getMaxItemSize()
		end
	end
	partPerformance = partPerformance / #partList	
	--print("Performance level ", partPerformance)
	-- hp should scale from 1(standard) to 1 + (sandboxScaler * (1-partPerformance))
	local sv = SandboxVars.ProjectSummerCar
	
	local sandboxScaler = sv.PerformancePartBoost
	local performanceMod = 1 + (sandboxScaler * (partPerformance-1))
	
	
	local sparkplugcond = GetPartCondition(part,"EngineSparkplug");
	local startercond = GetPartCondition(part,"EngineStarter");
	local flywheelcond = GetPartCondition(part,"EngineFlywheel");
	local enginequality = math.min(avgEngineCond,math.min(sparkplugcond,math.min(startercond,flywheelcond)) / 100.0)
	
	local engineLoudness = vehicle:getScript():getEngineLoudness() or 100;
	engineLoudness = engineLoudness * (SandboxVars.ZombieAttractionMultiplier or 1);
	engineLoudness = engineLoudness * (1.7 - avgEngineCond) -- Good vehicles are a bit quieter, poor ones are much louder. 
	
	--print("Setting quality to ", enginequality * 100, " due to flywheel cond ", flywheelcond, " and avgcond ", avgEngineCond )
	
	
	
	local scaledCondition = avgEngineCond - sv.MinHPCondition; -- percent to 0~1
	scaledCondition = scaledCondition / ((sv.MaxHPCondition - sv.MinHPCondition))
	scaledCondition = math.min(math.max(scaledCondition,0),1);
	--print("Intermediate scaledCondition ", scaledCondition)
	
	
	scaledCondition = PZMath.lerp(sv.MinHP, sv.MaxHP, scaledCondition) -- percent to 0~1
	--print("Intermediate scaledCondition2 ", scaledCondition)
	
	vehicle:setEngineFeature(enginequality*100, engineLoudness, vehicle:getScript():getEngineForce() * scaledCondition * performanceMod)
	
	-- Setup mod data here for CarController.java
	local EngineLockupAmount = 0
	-- Todo: Consider transmission slipage for engine heating? 
	
	
	
	if vehicle:isEngineRunning() then
		
		
		--  ****************** Engine Heating code ****************** 
		local tempScale = 5 -- How fast the engine heats up and cools down. Use 10 or so for testing.
		local maxRPM = 4500; 
		if vehicle:getScript():getEngineRPMType() == "firebird" then
			maxRPM = 6000
		end
		local rpmScale = vehicle:getEngineSpeed() / maxRPM-- divided by max RPM.. except we don't even know that on server side without doing mathhh. 
		
		idleHeat = 0.05;
		if partData.temperature < 85 then 
			idleHeat = 0.35;
		end
		
		if STARLIT_ENABLED then
			-- For heating, assume a min throttle depending on if the engine is cold or not. 
			partData.temperature = partData.temperature + (math.max(idleHeat,vehicle.throttle) * rpmScale * elapsedMinutes * tempScale) 
			--print("Current Temp ".. partData.temperature .. " with cooling " .. cooling .. " and throttle " .. vehicle.throttle .. " At ambient " .. getClimateManager():getTemperature() .. " Delta " .. tempDelta)
		else
			-- Just assume rpm squared for throttle otherwise?
			local throttleFactor = math.max(idleHeat,rpmScale * rpmScale);
			partData.temperature = partData.temperature + (throttleFactor * elapsedMinutes * tempScale) 
		end
		
		
		
		--  ****************** Hood Cooling code ****************** 
		local engineDoor = vehicle:getPartById("EngineDoor");
		local cooling = 1; -- If no door exists, like modded motorbikes/etc.
		if engineDoor then
		
			if not engineDoor:getInventoryItem() then
				cooling = 0.5; -- if it should exist, but does not. 
			else
				cooling = math.min(100,engineDoor:getCondition()+50.0)/100.0
			end
		end
		local tempEngineDelta = partData.temperature - getClimateManager():getTemperature();
		partData.temperature = partData.temperature - (0.001 * elapsedMinutes * tempScale * tempEngineDelta) -- Passive Air cooling of engine. Scale with speed? Higher with open hood?

		
		
		--  ****************** Radiator Heat transfer code ****************** 
		local radiatorFluidLevel = 0
		local heatTransfer = 0;
		radiator = part:getItemContainer():getFirstTag("EngineRadiator")
		if radiator then
			local radiatorQuality = radiator:getScriptItem():getMaxItemSize();
			local radiatorCondition = radiator:getCondition() * 0.01;
			radiatorFluidLevel = radiator:getFluidContainer():getFilledRatio();
			
			cooling = cooling * radiatorQuality * radiatorCondition * math.min(1,radiatorFluidLevel/0.8) -- Cooling capacity starts degrading at <80%
			
			heatTransfer = math.min(1,GetPartCondition(part,"EngineWaterPump") * 0.01); -- 100% or less is bad. 
			-- Square heattransfer just so that pump condition matters that much more, as even 25% heat transfer is still pretty good. 
			heatTransfer = heatTransfer * heatTransfer; 
			
			heatTransfer = heatTransfer * math.min(1,GetPartCondition(part,"EngineFanBelt") * 0.03); -- 30% or less is bad.
			
			if partData.temperature > 125 then -- Should be based on radiator temp, but decided engine temp was easier for player to understand as it gives him a warning light. 
				radiator:getFluidContainer():adjustAmount(radiator:getFluidContainer():getAmount() - elapsedMinutes * 0.01)
				partData.temperatureRadiator = partData.temperatureRadiator - 1 * elapsedMinutes; -- Remove 1 degree per minute that venting occurs. 
			end
			if radiatorCondition < 0.25 then
				radiator:getFluidContainer():adjustAmount(radiator:getFluidContainer():getAmount() - elapsedMinutes * 0.01 * (0.25-radiatorCondition))
			end
				

			-- Todo: Damage radiator if fluid is not water/antifreeze.
			-- Todo: Badly damage crankcase if fluid does not have enough antifreeze for current temperature on starting. 
			-- Todo: scale radiator cooling with speed? Add radiator fan?
		end
		
		if partData.temperature < 110 then
			heatTransfer = heatTransfer * math.min(math.max((partData.temperature-90) * 0.05,0.02),1) -- Limit cooling to 2% below 110c, start to open thermostat up at 90c
		end
		
		-- Todo: Scale cooling with bloood level on front of vehicle? (Warning: likely bugged to only ever go to a certain level?)
		

		local engineCapacity = 1
		heatTransfer = math.min(math.max(heatTransfer,0),1);
		
		local avgTemp = ((partData.temperatureRadiator * radiatorFluidLevel) + (partData.temperature * engineCapacity)) / (radiatorFluidLevel+engineCapacity)
		partData.temperatureRadiator = lerpHelper(partData.temperatureRadiator,avgTemp,heatTransfer);
		partData.temperature = lerpHelper(partData.temperature,avgTemp,heatTransfer);
		
		
		local tempDelta = partData.temperatureRadiator - getClimateManager():getTemperature();
		-- Todo: simulate radiator fan (only engaged at high radiator temp, cooling depending on engine RPM?) and radiator airflow cooling varying with speed. 
		
		partData.temperatureRadiator = partData.temperatureRadiator - (cooling * elapsedMinutes * tempDelta * tempScale * 0.02)
		--print("Rad ",partData.temperatureRadiator, " engine ", partData.temperature, " cooling ", cooling, " transfer ", heatTransfer);
		
		
		--  ****************** Oil Contamination code ****************** 
		-- Scale oil consumption/contamination with piston/crank/etc condition. 
		-- Oil loss rate depends on pistons, cylinder head, crank, head gasket and oil pan
		-- avgEngineCond declared at start of class and reused here
		local oilContaminationRate = (1.1-avgEngineCond) * 0.002 * sv.OilDecayRate -- per second rate
		local oilfilter = part:getItemContainer():getFirstTag("EngineOilFilter")
		if oilfilter then
			oilContaminationRate = oilContaminationRate * (110 - oilfilter:getCondition()) * 0.01
			if sv.OilFilterDecayRate > 0.001 then
				if ZombRand(150 * avgEngineCond / sv.OilFilterDecayRate) == 0 then
					oilfilter:setCondition(oilfilter:getCondition()-1);
				end
			end
		end
		-- Oil filter reduces oil contamination rate but can't do anything about already dirty oil
		
		if partData.temperature > 140 then
			-- Todo: Drain radiator water too. Maybe start venting water at 130
			oilContaminationRate = oilContaminationRate * 5 -- increase oil contamination when overheating.
			-- Damage to pistons/cylinder head/headgasket. (Also increased oil wear?)
			print("Engine damage from overheat");
			DamageRandomPart(part,{"EnginePistons","EngineCylinderHead","EngineHeadGasket","EngineSparkplug","EngineWaterPump"},10)
		end
		

		local oilpan = part:getItemContainer():getFirstTag("EngineOilPan")
		local oilLevel = 0
		local oilLevelUsed = 0
		local oilMax = 1
		
		if oilpan then
			local motorOil = Fluid.Get("MotorOil");
			local motorOilUsed = Fluid.Get("UsedMotorOil");
			oilMax = oilpan:getFluidContainer():getCapacity();
	

			oilLevel = oilpan:getFluidContainer():getSpecificFluidAmount(motorOil)
			local amountToContaminate = math.min(oilLevel, oilContaminationRate)
			
			--print("Found oil: ", oilLevel, " out of ", oilpan:getFluidContainer():getAmount())
			oilpan:getFluidContainer():adjustSpecificFluidAmount(motorOil,oilLevel - amountToContaminate)
			
			oilLevelUsed = oilpan:getFluidContainer():getSpecificFluidAmount(motorOilUsed)
			--print("Found used oil: ", oilLevelUsed," Contamining ", amountToContaminate)
			
			oilpan:getFluidContainer():addFluid(motorOilUsed, amountToContaminate)
			
			
			-- Burns all fluids in oilpan equally. 
			--print ("Average engine part condition: ", avgEngineCond)
			
			local oilLoss = math.max(0,0.7-avgEngineCond) * 0.002 * sv.OilLeakRate -- Results in 0 to 0.002L oil loss per ingame minute depending on engine condition (starts leaking below 70%)
			
			if not oilfilter then
				oilLoss = 0.2 -- Just gushing out. Don't run engine without an oil filter!
			end
			
			-- Drastically increase oil loss if oil pan is <25%
			oilLoss = oilLoss + math.max(0,25-oilpan:getCondition()) * 0.01
			
			local headgasket = part:getItemContainer():getFirstTag("EngineHeadGasket")
			local headgasketCondition = 0
			if headgasket then
				headgasketCondition = headgasket:getCondition()
			end
			
			local headgasketloss = math.max(0,0.3 - headgasketCondition * 0.01) * 0.1
			oilLoss = oilLoss + headgasketloss -- Amount burnt off/lost to coolant system
				
			if radiatorFluidLevel > 0.01 then
				oilpan:getFluidContainer():addFluid(Fluid.TaintedWater,headgasketloss*0.5); -- Add tainted water from coolant system to oil. 
			end
			if radiator then
				radiator:getFluidContainer():adjustAmount(radiator:getFluidContainer():getAmount() - headgasketloss)
				radiator:getFluidContainer():addFluid(motorOilUsed,headgasketloss * 0.5) -- Add used oil to radiator, because why not.
				-- Todo: Replace with sludge that has extra loss of cooling/oil lubricating?
			end
			
			oilpan:getFluidContainer():adjustAmount(oilpan:getFluidContainer():getAmount() - oilLoss)	
		end

		if oilLevel <= oilMax * 0.30 then
			DamageRandomPart(part,{"EnginePistons","EngineCylinderHead","EngineCrankshaft"},oilLevel*50) -- Somewhere around 3 in 50 chance of engine part damage when at 30%.
		end
		
	elseif partData.temperature > getClimateManager():getTemperature() then
		partData.temperature = math.max(partData.temperature - 1.0 * elapsedMinutes, getClimateManager():getTemperature())
	end
	

	-- Networking stuff.
	Vehicles.elaspedMinutesForEngine[vehicle:getId()] = Vehicles.elaspedMinutesForEngine[vehicle:getId()] + elapsedMinutes;
	if isServer() and VehicleUtils.compareFloats(previousTemp, partData.temperature, 2) and Vehicles.elaspedMinutesForEngine[vehicle:getId()] > 2 then
		Vehicles.elaspedMinutesForEngine[vehicle:getId()] = 0;
		vehicle:transmitPartModData(part);
	end
	-- stop updating parts when T° reach getClimateManager():getTemperature()
	if partData.temperature <= (getClimateManager():getTemperature()+0.1) and not vehicle:isEngineRunning() and not vehicle:getDriver() then
		vehicle:setNeedPartsUpdate(false);
	end
	
end

function Vehicles.Update.Battery(vehicle, part, elapsedMinutes)
	-- Hack, there's no Lightbar part.
	Vehicles.Update.Lightbar(vehicle, part, elapsedMinutes)
	
	if part:getInventoryItem() == nil then
		return end
		
	local chargeOld = part:getInventoryItem():getCurrentUsesFloat()
	local charge = chargeOld
	
	local modData = vehicle:getModData();
	local ampScaler = 200000; 
	local batteryLoad = (modData.batteryDraw or 0) * ampScaler; -- Scales load into aprox amp minutes, based on headlights being 10A.
	modData.batteryDraw = 0; -- reset for next accumulation period. 
	
	
	-- Starting the engine drains the battery (Disabled, now done elsewhere much better)
	local engineStarted = vehicle:isEngineRunning()
	if engineStarted then
		batteryLoad = batteryLoad + elapsedMinutes * 10; -- Add 10amp engine load
	end
	
	--if engineStarted and not part:getModData().engineStarted then
	--	charge = charge - 0.025
	--end
	part:getModData().engineStarted = engineStarted
	
	local engine = vehicle:getPartById("Engine");
	if engine == nil then -- Certain RV's have batteries but no engines. So just bail out here.
		return end;
		
	local fanBelt = math.min(1,GetPartCondition(engine,"EngineFanBelt") * 0.03); -- Scales from below 33%
	local alternator = math.min(1,GetPartCondition(engine,"EngineAlternator") * 0.02); -- Alternator scales from below 50% condition. 
	
	-- Running the engine charges the battery
	local sv = SandboxVars.ProjectSummerCar	
	
	local alternatorAmps = 0;
	if vehicle:isEngineRunning() then
		alternatorAmps = alternator * fanBelt * math.min(1,vehicle:getEngineSpeed() / 2000) * 120 * elapsedMinutes; -- 120 amp max alternator. About 60~ at idle when new? Technically amp-minutes. 
	end
	--print("Battery draw ", batteryLoad, " alternator amps ", alternatorAmps, " minutes ", elapsedMinutes);

	local systemSum = alternatorAmps-batteryLoad; 
	local ampMinuteScaler = 60 * 100; -- 100 amp hour battery

	-- Do power flow reguardless of engine status. 
	if systemSum > 0 then
		local chargeSpeed = (1.2 - charge) * 50; -- 10~60A charging speed = Faster charging at lower battery, slower at higher battery. Gives an aprox 3~6 hour charge time? 
		--print("Charge Speed", chargeSpeed, " System Sum ", systemSum);
		chargeSpeed = math.min(chargeSpeed, systemSum)
		--chargeSpeed = systemSum / ampScaler * 10 
		charge = math.min(1, charge + elapsedMinutes * chargeSpeed * sv.ChargeRate / ampMinuteScaler)
	else
		charge = math.max(0, charge + systemSum / ampMinuteScaler)  -- systemSum is negative, so this is actually a subtraction. 
	end 

	if charge ~= chargeOld then
		part:getInventoryItem():setUsedDelta(charge)
		if VehicleUtils.compareFloats(chargeOld, charge, 2) then
			vehicle:transmitPartUsedDelta(part)
		end
	end
end

-- Hack, there is no Lightbar part.
function Vehicles.Update.Lightbar(vehicle, part, elapsedMinutes)
	if not vehicle:hasLightbar() then return end
	local activeLights = vehicle:getLightbarLightsMode() > 0
	local activeSiren = vehicle:getLightbarSirenMode() > 0
	-- Check anti-griefing Sandbox option.
	if activeSiren and vehicle:sirenShutoffTimeExpired() then
		vehicle:setLightbarSirenMode(0)
		activeSiren = false
	end
	if vehicle:getBatteryCharge() <= 0.0 then
		if activeLights then
--			vehicle:setLightbarLightsMode(0)
			activeLights = false
		end
		if activeSiren then
--			vehicle:setLightbarSirenMode(0)
			activeSiren = false
		end
	end
	-- Siren and lightbar drain the battery. (Now even with engine running because alternator simulation.)
	if activeLights then
		VehicleUtils.chargeBattery(vehicle, -0.000025 * elapsedMinutes) -- Draws 5A each
	end
	if activeSiren then
		VehicleUtils.chargeBattery(vehicle, -0.000025 * elapsedMinutes) -- Draws 5A each
	end
end

function Vehicles.Update.GasTank(vehicle, part, elapsedMinutes)
	local invItem = part:getInventoryItem();
	if not invItem then return; end
	local amount = part:getContainerContentAmount()
	if elapsedMinutes > 0 and amount > 0 and vehicle:isEngineRunning() then
		local amountOld = amount
		
		local qualityMultiplier = ((100 - vehicle:getEngineQuality()) / 200) + 0.5; -- Poor engines consume 3x as much fuel. 
		local newAmount = (vehicle:getEngineSpeed()/1000.0) * SandboxVars.CarGasConsumption 
		newAmount = newAmount * vehicle:getEnginePower() / 4000; -- 400hp will be the new 'vanilla' gas consumption HP. Change to 100 if operating in 'realistic' HP mode? 
			
		--print("Vehicle Throttle ", vehicle.throttle);
		if STARLIT_ENABLED then
			newAmount = newAmount * qualityMultiplier * (vehicle.throttle + 0.05); -- Aprox 5% fuel consumption at idle
		else
			newAmount = newAmount * qualityMultiplier * (math.abs(vehicle:getCurrentSpeedKmHour()) + 5) / 100.0f -- Aprox 5% fuel consumption at idle, assume speed = engine load. 
		end 
		
		newAmount = newAmount * 0.01;
		amount = amount - elapsedMinutes * newAmount;
	
		-- if your gas tank is in bad condition, you can simply lose fuel
		if part:getCondition() < 50 then -- Lowered from 70%
			if ZombRand(part:getCondition() * 2) == 0 then
				amount = amount - 0.01;
			end
		end
	
		part:setContainerContentAmount(amount, false, true);
		amount = part:getContainerContentAmount();
		local precision = (amount < 0.5) and 2 or 1
		if VehicleUtils.compareFloats(amountOld, amount, precision) then
			vehicle:transmitPartModData(part)
		end
	end
end


function Vehicles.Update.Headlight(vehicle, part, elapsedMinutes)
	local light = part:getLight()
	if not light then return end
	local active = vehicle:getHeadlightsOn()
	if active and (not part:getInventoryItem() or vehicle:getBatteryCharge() <= 0.0) then
		active = false
--		vehicle:setHeadlightsOn(VehicleUtils.anyWorkingHeadlights(vehicle))
	end
	part:setLightActive(active)
	--if active and not vehicle:isEngineRunning() then
	if active then
		--print("Discharging battery due to headligths");
		VehicleUtils.chargeBattery(vehicle, -0.000025 * elapsedMinutes)
	end
	-- TODO: burn out eventually
end

function Vehicles.Update.Heater(vehicle, part, elapsedMinutes)
	if not Vehicles.elaspedMinutesForHeater[vehicle:getId()] then
		Vehicles.elaspedMinutesForHeater[vehicle:getId()] = 0;
	end
	local pc = vehicle:getPartById("PassengerCompartment")
	local engine = vehicle:getPartById("Engine")

	if not pc or not engine then return end
	local pcData = pc:getModData()
	if not tonumber(pcData.temperature) then
		pcData.temperature = 0.0
	end
	local partData = part:getModData()
	if not tonumber(partData.temperature) then
		partData.temperature = 0
	end
--	print(elapsedMinutes)

	local previousTemp = pcData.temperature;
	if partData.active and vehicle:isEngineRunning() then
		if partData.temperature > 0 then
			local heaterCore = math.min(1,GetPartCondition(engine,"EngineHeaterCore") * 0.02); -- Lower effiveness below 50%
			-- Todo: add requirement for water pump+fan belt+radiator fluid?
			local engineTemp = engine:getModData().temperature;
			heaterCore = partData.temperature * heaterCore * math.max((engineTemp - 50) / 50,0) -- Starts being effective at 50c, 1x output at 100c, nearly 2x at 140c (overheat)
			pcData.temperature = pcData.temperature + heaterCore * elapsedMinutes * 0.1;
		elseif partData.temperature < 0 then
			local airConditioner = math.min(1,GetPartCondition(engine,"EngineAirConditioner") * 0.02); -- Lower effectiveness below 50% condition
			airConditioner = airConditioner * math.min(1,GetPartCondition(engine,"EngineFanBelt") * 0.03); -- lower effectiveness below 30%
			-- Todo: add requirement for fan belt?
			-- Make output depend on condition and RPM?
			-- Ie, min(condition + rpm,1)
			pcData.temperature = pcData.temperature + partData.temperature * airConditioner * elapsedMinutes * 0.1;
		end
		pcData.temperature = pcData.temperature - (pcData.temperature * 0.1 * elapsedMinutes); -- Remove 10% of heat difference per minute. 
		
	end

-- fixes damage in reverse. 
function Vehicles.LowerCondition(vehicle, part, elapsedMinutes)
	if vehicle:isEngineRunning() and math.abs(vehicle:getCurrentSpeedKmHour()) > 10 and part:getInventoryItem() then
		local chance = part:getInventoryItem():getConditionLowerNormal()*Vehicles.newSystemConditionLowerMult;
		if vehicle:isDoingOffroad() then chance = part:getInventoryItem():getConditionLowerOffroad()*Vehicles.newSystemConditionLowerMult / vehicle:getOffroadEfficiency(); end
		
		-- will also depend on speed/current steering
		chance = chance + (vehicle:getCurrentSpeedKmHour() / 200);
		chance = chance + math.abs(vehicle:getCurrentSteering() / 2)
		
		if part:getCondition() > 0 and ZombRandFloat(0, 100) < chance then
			part:setCondition(part:getCondition() - 1);
			vehicle:transmitPartCondition(part);
			vehicle:updatePartStats();
		end
		return chance;
	end
	return 0;
end

--[[	
function Vehicles.Create.Battery(vehicle, part)
	local item = VehicleUtils.createPartInventoryItem(part);
	if SandboxVars.VehicleEasyUse then
		item:setUsedDelta(1);
		return;
	end
	if vehicle:isGoodCar() then
		item:setUsedDelta(ZombRandFloat(0.8,1));
		return;
	end
	local tot = (getGameTime():getWorldAgeHours() / 5000);
	tot = tot + (((getSandboxOptions():getTimeSinceApo() - 1) * 30 * 24) / 4500);
	tot = ZombRandFloat(tot - 0.15, tot + 0.15);
	tot = 1 - tot;
	tot = math.min(tot, 1)
	item:setUsedDelta(math.max(0, tot));
end--]] 
	
	--[[
	local tempInc = 0.5 + (math.min(engine:getModData().temperature / 100, 0.7))
--	print("heater temp " .. partData.temperature .. " - " .. pcData.temperature .. " - " .. tempInc)
	if partData.active and vehicle:isEngineRunning() and engine:getModData().temperature > 30 and 
		((partData.temperature > 0 and pcData.temperature <= partData.temperature) or 
		(partData.temperature < 0 and pcData.temperature >= partData.temperature)) then
		
		if partData.temperature > 0 then
			pcData.temperature = math.min(pcData.temperature + tempInc * elapsedMinutes, partData.temperature)
		else
			pcData.temperature = math.max(pcData.temperature - tempInc * elapsedMinutes, partData.temperature)
		end
		if partData.temperature > 0 and pcData.temperature > partData.temperature then
			pcData.temperature = partData.temperature
		end
		if partData.temperature < 0 and pcData.temperature < partData.temperature then
			pcData.temperature = partData.temperature
		end
	else
		if pcData.temperature > 0 then
			pcData.temperature = math.max(pcData.temperature - 0.1 * elapsedMinutes, 0)
		else
			pcData.temperature = math.min(pcData.temperature + 0.1 * elapsedMinutes, 0)
		end
	end--]]
	
	-- Uses power for blower fan. 
	if partData.active and vehicle:isEngineRunning() then
		VehicleUtils.chargeBattery(vehicle, -0.000035 * elapsedMinutes)
	end
	
	Vehicles.elaspedMinutesForHeater[vehicle:getId()] = Vehicles.elaspedMinutesForHeater[vehicle:getId()] + elapsedMinutes;
	if isServer() and VehicleUtils.compareFloats(previousTemp, pcData.temperature, 2) and Vehicles.elaspedMinutesForHeater[vehicle:getId()] > 2 then
		Vehicles.elaspedMinutesForHeater[vehicle:getId()] = 0;
		vehicle:transmitPartModData(pc);
	end
end


-- windows open = cool down a bit the passengers
-- all windows closed = heat up a bit the passengers
function Vehicles.Update.PassengerCompartment(vehicle, part, elapsedMinutes)
	local pc = vehicle:getPartById("PassengerCompartment")
	
	local windowCount = 0;
	local windowOpen = 0;
	local windshield = vehicle:getPartById("Windshield")
	local windshieldBroken = false; 
	if windshield then
		windshieldBroken = windshield:getWindow():isDestroyed()
	end
	
	
	for x = 0, vehicle:getPartCount()-1 do
		local part = vehicle:getPartByIndex(x)
		--local window = part:getScriptPart().window
		--if window then -- requires starlit
		local window = part:getWindow()
		if window then
			windowCount = windowCount + 1
			if window:isDestroyed() or window:isOpen() then
				windowOpen = windowOpen + 1
			end
		end
		--print("Windows ", part:getId())
	end
	--print("Windows Count: ", windowCount, " / ", windowOpen)
	
	if RainManager.isRaining() and windshieldBroken then
		if vehicle:getDriver() then
			-- Todo: Make clothing wet too? 
			vehicle:getDriver():getBodyDamage():setWetness(vehicle:getDriver():getBodyDamage():getWetness() + math.max(0,vehicle:getCurrentSpeedKmHour()-10) * elapsedMinutes * 0.1)
		end
	end
	
	
	local heater = vehicle:getHeater();
	if not pc or not heater then return end
	
	local pcData = pc:getModData()
	if not pcData.windowtemperature then pcData.windowtemperature = 0.0; end
	if not pcData.temperature then pcData.temperature = 0.0; end
	local speedFactor = (math.abs(vehicle:getCurrentSpeedKmHour()) + 10) / 100 -- Instead add current wind speed?
	-- Todo: Apply real life windchill factor
	local windchill = speedFactor * 10;
	
	--vehicle:getSquare():isInARoom() // Was used to change temps slightly but.. why bother?
	
	if windowOpen > 0 then
		local oldtemp = pcData.temperature;
		pcData.temperature = oldtemp - (0.1 * oldtemp * speedFactor * math.min(3,windowOpen)); -- Slowly lowers the AC back to 0c
		if (oldtemp > 0) ~= (pcData.temperature > 0) then
			pcData.temperature = 0; -- reset to 0 if we crossed 0
		end
		
		pcData.windowtemperature = -windchill * math.min(3,windowOpen); --Applies windchill offset instantly. up to 3 windows being open matters. 
	else
		if not heater:getModData().active then
			pcData.windowtemperature = math.min(pcData.windowtemperature + 0.5 * elapsedMinutes, 5); -- Slowly set window offset to 5c (Body heat building up. Maybe consider sun on car?)
		else
			pcData.windowtemperature = math.max(pcData.windowtemperature - 0.5 * elapsedMinutes, 0); -- Slowly drop window offset to 0c (Body heat vented)
		end
	end
		-- IDEA: toxicity by piping exhaust
end




