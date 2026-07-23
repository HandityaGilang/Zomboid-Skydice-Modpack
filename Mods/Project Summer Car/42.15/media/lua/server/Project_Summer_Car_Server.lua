require "Vehicles/Vehicles"
require "Items/ProceduralDistributions"
require "Items/SuburbsDistributions"
require "Items/Distributions"

--local STARLIT_ENABLED = getActivatedMods():contains("\\StarlitLibrary")
local REALISTICCARPHYSICS_ENABLED = getActivatedMods():contains("\\RealisticCarPhysics")
local PSC_Tags = ProjectSummerCar_Tags
-- Add starlit require here?

local cachedThrottleField = nil;
function getThrottle(vehicle)
  return 0.2;
  end
  --[[ -- Reflection no longer allowed due to fun police. 
  if cachedField == nil then
    for x = 0, getNumClassFields(vehicle)-1 do
      local field = getClassField(vehicle, x)
      if tostring(field) == "public float zombie.vehicles.BaseVehicle.throttle" then
		cachedThrottleField = field;
      end
    end
  end
  
  if cachedThrottleField ~= nil then
	  --print("Throttle ", getClassFieldVal(vehicle,cachedThrottleField));
	  return getClassFieldVal(vehicle,cachedThrottleField)
  end
  print("Project Summer car: Failed to find throttle field");
  return 0.2
end
--]]


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
	return getCore():getDebug() and ISVehicleMechanics.cheat
	end
	
function VehicleUtils.chargeBattery(vehicle, delta)
	local modData = vehicle:getModData();
	modData.batteryDraw = (modData.batteryDraw or 0) - delta;
end

function UpdateEngineCondition(vehicle, part)
	if isClient() then return end

	local partCondition = part:getCondition()
	local modData = part:getModData();
	local oldCondition = modData.lastEngineCondition
	if oldCondition == nil then
		oldCondition = partCondition
		--print("Nil old condition")
	end

	local engineItems = part:getItemContainer():getItems()
	if partCondition < oldCondition and engineItems then
		local sv = SandboxVars.ProjectSummerCar	
		
		local damage = oldCondition - partCondition;
		--print("Engine damage Detected " .. damage .. " Partcondition was " .. partCondition .. " and old condition was " .. oldCondition)
		for x = 1, sv.EngineImpactDamageCount do -- Damage 4 parts in every impact since there are so many engine parts to soak up damage and damage is limited to lowest main engine parts condition.
			local partToDamage = engineItems:get(ZombRand(engineItems:size()))
			if partToDamage then
				if not partToDamage:hasTag(PSC_Tags.EnginePartInitMarker) then -- Don't damage init marker. 
					partToDamage:setCondition(math.max(0,partToDamage:getCondition() - (damage * sv.EngineImpactDamage * (ZombRandFloat(0,0.50)+0.50)))) 
					partToDamage:syncItemFields();
				end
			end
		end
	end

	
	local criticalEngineCount = 5 -- Number of critical engine components that must exist
	local minCondition = 100
	for x=0, engineItems:size()-1 do
		local item = engineItems:get(x)
		if item:hasTag(PSC_Tags.EngineCritical) then 
			minCondition = math.min(minCondition,item:getCondition())
			criticalEngineCount = criticalEngineCount-1
		end
	end
	if criticalEngineCount > 0 then
		minCondition = 0
	end
	
	modData.lastEngineCondition = minCondition;
	--print("engine condition ", minCondition)
	if minCondition ~= partCondition then
		part:setCondition(minCondition) -- Set engine to mirror lowest component. 
		if isServer() then
			vehicle:transmitPartCondition(part) -- sync if server and MP. 
		end
		--print("Setting engine condition due to part damage to ", minCondition)
	end
end

	
-- Overwrite check engine function to support new parts.
function Vehicles.CheckEngine.Engine(vehicle, part)
	
	local engineCondition = part:getCondition();
	-- Randomizer here to cause random stalls if condition of components is super low!
	local stallLevel = ZombRand(10) * ZombRand(10) * 0.1
	if ZombRand(60) == 0 then
		return engineCondition > stallLevel
	else
		return engineCondition > 0
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
			partToDamage:syncItemFields();
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
	UpdateEngineCondition(vehicle, part);
	
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

function SendFluidSyncPacket(vehicle, part) -- For engine parts only
	if not isServer() then return end

	local fluidSync = {
		partID = part:getID(),
		vehicleID = vehicle:getId(),
	}
	-- Add Array of fluids to sync up
	local container = part:getFluidContainer();
	local sample = container:createFluidSample();
	local fluidArray = {}
	for x = 0, sample:size()-1 do
		local fluid = sample:getFluid(x);
		--local fluidInstance = sample:getFluidInstance(x)
		table.insert(fluidArray,{fluidType = fluid:getFluidTypeString(), amount = container:getSpecificFluidAmount(fluid)});
	end

	fluidSync.fluidArray = fluidArray;
	sendServerCommand("ProjectSummerCar", "UpdateFluid", fluidSync)
	--print("Sending command with vehicle ", vehicle);
	--print("Sending command with vehicleID ", vehicle:getId());
	--print("Sending command with vehicleID ", vehicle:getID());
	

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
	
	local avgEngineCond = GetAverageEngineCondition(part,{PSC_Tags.EnginePistons,PSC_Tags.EngineCylinderHead,PSC_Tags.EngineCrankshaft})
	
	local partList = {PSC_Tags.EnginePistons,PSC_Tags.EngineCylinderHead,PSC_Tags.EngineCrankshaft,PSC_Tags.EngineSparkplug}
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
	
	
	local sparkplugcond = GetPartCondition(part,PSC_Tags.EngineSparkplug);
	local startercond = GetPartCondition(part,PSC_Tags.EngineStarter);
	local flywheelcond = GetPartCondition(part,PSC_Tags.EngineFlywheel);
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
		local rpmScale = vehicle:getEngineSpeed() / maxRPM-- divided by max RPM.. 
		
		idleHeat = 0.05;
		if partData.temperature < 85 then 
			idleHeat = 0.35;
		end
		
		-- For heating, assume a min throttle depending on if the engine is cold or not. 
		partData.temperature = partData.temperature + (math.max(idleHeat,getThrottle(vehicle)) * rpmScale * elapsedMinutes * tempScale) 
		--print("Current Temp ".. partData.temperature .. " with cooling " .. cooling .. " and throttle " .. vehicle.throttle .. " At ambient " .. getClimateManager():getTemperature() .. " Delta " .. tempDelta)
		
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
		radiator = part:getItemContainer():getFirstTag(PSC_Tags.EngineRadiator)
		local radiatorUpdate = false;
		if radiator then
			local radiatorQuality = radiator:getScriptItem():getMaxItemSize();
			local radiatorCondition = radiator:getCondition() * 0.01;
			radiatorFluidLevel = radiator:getFluidContainer():getFilledRatio();
			
			cooling = cooling * radiatorQuality * radiatorCondition * math.min(1,radiatorFluidLevel/0.8) -- Cooling capacity starts degrading at <80%
			
			heatTransfer = math.min(1,GetPartCondition(part,PSC_Tags.EngineWaterPump) * 0.01); -- 100% or less is bad. 
			-- Square heattransfer just so that pump condition matters that much more, as even 25% heat transfer is still pretty good. 
			heatTransfer = heatTransfer * heatTransfer; 
			
			heatTransfer = heatTransfer * math.min(1,GetPartCondition(part,PSC_Tags.EngineFanBelt) * 0.03); -- 30% or less is bad.
			
			if partData.temperature > 125 then -- Should be based on radiator temp, but decided engine temp was easier for player to understand as it gives him a warning light. 
				radiator:getFluidContainer():adjustAmount(radiator:getFluidContainer():getAmount() - elapsedMinutes * 0.01)
				partData.temperatureRadiator = partData.temperatureRadiator - 1 * elapsedMinutes; -- Remove 1 degree per minute that venting occurs. 
				radiatorUpdate = true;
			end
			if radiatorCondition < 0.25 then
				radiator:getFluidContainer():adjustAmount(radiator:getFluidContainer():getAmount() - elapsedMinutes * 0.01 * (0.25-radiatorCondition))
				radiatorUpdate = true;
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
		-- So this is is like... 10x between new and worst engine rate.
		-- Now lets say you stay above 30%.. still 1:4 ratio vs 90% engine. Still isn't that the reward of a GOOD engine?
		-- I guess that isn't.. horrible? 1:3 might be better... 
		--local oilContaminationRate = (1.1-avgEngineCond) * 0.002 * sv.OilDecayRate -- per ingame minute rate, Could be as much as 10:1 from 100% vs 10% condition engine
		local oilContaminationRate = (1.4-avgEngineCond) * 0.0015 * sv.OilDecayRate -- per ingame minute rate, increased so its 3.5:1
		local oilfilter = part:getItemContainer():getFirstTag(PSC_Tags.EngineOilFilter)
		-- Todo: make oil contamination rate dependant on engine RPM? Then idling won't use as much oil as driving. 
		if oilfilter then
			-- same here. 
			--oilContaminationRate = oilContaminationRate * (110 - oilfilter:getCondition()) * 0.01 
			oilContaminationRate = oilContaminationRate * (130 - oilfilter:getCondition()) * 0.01 -- decrease contamination with fresh filter to about 30%
			if sv.OilFilterDecayRate > 0.001 then
				if ZombRand(100 * (avgEngineCond+0.3) / sv.OilFilterDecayRate) == 0 then -- I hate zombRand chance for condition decay. 
					oilfilter:setCondition(oilfilter:getCondition()-1);
					oilfilter:syncItemFields();
				end
			end
		end
		-- Oil filter reduces oil contamination rate but can't do anything about already dirty oil
		
		if partData.temperature > 140 then
			-- Todo: Drain radiator water too. Maybe start venting water at 130
			oilContaminationRate = oilContaminationRate * 5 -- increase oil contamination when overheating.
			-- Damage to pistons/cylinder head/headgasket. (Also increased oil wear?)
			--print("Engine damage from overheat");
			DamageRandomPart(part,{PSC_Tags.EnginePistons,PSC_Tags.EngineCylinderHead,PSC_Tags.EngineHeadGasket,PSC_Tags.EngineSparkplug,PSC_Tags.EngineWaterPump},10)
		end
		

		local oilpan = part:getItemContainer():getFirstTag(PSC_Tags.EngineOilPan)
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
			
			-- Only causes loss below 70% condition. 
			local oilLoss = math.max(0,0.7-avgEngineCond) * 0.002 * sv.OilLeakRate -- Results in 0 to 0.002L oil loss per ingame minute depending on engine condition (starts leaking below 70%)
			
			if not oilfilter then
				oilLoss = 0.2 -- Just gushing out. Don't run engine without an oil filter!
			end
			
			-- Drastically increase oil loss if oil pan is <25%
			oilLoss = oilLoss + math.max(0,25-oilpan:getCondition()) * 0.005 * sv.OilLeakRate -- Much higher due to 0~25 multipler vs 0~0.7 multiplier of above. 
			
			local headgasket = part:getItemContainer():getFirstTag(PSC_Tags.EngineHeadGasket)
			local headgasketCondition = 0
			if headgasket then
				headgasketCondition = headgasket:getCondition()
			end
			
			local headgasketloss = math.max(0,0.3 - headgasketCondition * 0.01) * 0.1 -- Loss below 30%
			oilLoss = oilLoss + headgasketloss -- Amount burnt off/lost to coolant system
				
			if radiatorFluidLevel > 0.01 then
				oilpan:getFluidContainer():addFluid(Fluid.TaintedWater,headgasketloss*0.5); -- Add tainted water from coolant system to oil. 
			end
			if radiator then -- Technically, this shouldn't depend on the oilpan being installed.. But your not going to drive without an oilpan long enough to matter that your missing the headgasketloss of coolant. 
				radiator:getFluidContainer():adjustAmount(radiator:getFluidContainer():getAmount() - headgasketloss)
				radiator:getFluidContainer():addFluid(motorOilUsed,headgasketloss * 0.5) -- Add used oil to radiator, because why not.
				-- Todo: Replace with sludge that has extra loss of cooling/oil lubricating?
				radiatorUpdate = true;
			end
			
			oilpan:getFluidContainer():adjustAmount(oilpan:getFluidContainer():getAmount() - oilLoss)
			SendFluidSyncPacket(vehicle,oilpan);
			
		end
		if radiatorUpdate then
			SendFluidSyncPacket(vehicle,radiator);
		end
		if oilLevel <= oilMax * 0.30 then
			DamageRandomPart(part,{PSC_Tags.EnginePistons,PSC_Tags.EngineCylinderHead,PSC_Tags.EngineCrankshaft},oilLevel*50) -- Somewhere around 3 in 50 chance of engine part damage when at 30%.
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



function Vehicles.Create.Battery(vehicle, part)
	local item = VehicleUtils.createPartInventoryItem(part);
	if SandboxVars.VehicleEasyUse then
		item:setUsedDelta(1);
		return;
	end
	

	--[[if vehicle:isGoodCar() then
		item:setUsedDelta(ZombRandFloat(0.8,1));
		return;
	end--]]
	local sv = SandboxVars.ProjectSummerCar
	if sv.BatteryChargedChance < ZombRandFloat(0,1) then 
		item:setUsedDelta(0)
		if sv.BatteryGoodChance < ZombRandFloat(0,1) then 
			item:setCondition(0)
			item:syncItemFields();
		end
		return
	end


	
	local chargeAmount = ZombRandFloat(0, 1);
	--print("Initial charge amount", chargeAmount);
	chargeAmount = 1-math.pow(chargeAmount,sv.BatteryChargedBias); -- Flip random number around so that a high bias value results in charged batteries. 
	--print("corrected charge amount", chargeAmount);
	item:setUsedDelta(math.min(math.max(chargeAmount,0), 1));
	
	
	--Old math:
	--local tot = (getGameTime():getWorldAgeHours() / 5000);
	--tot = tot + (((getSandboxOptions():getTimeSinceApo() - 1) * 30 * 24) / 4500);
	--tot = 1-ZombRandFloat(tot - 0.15, tot + 0.15);
	
end


-- Todo: make headlight change optional in sandbox?
function VehicleUtils.initHeadlight(vehicle, part)
	local item = VehicleUtils.createPartInventoryItem(part)
	local xOffset = 0.5
	local yOffset = 2.0
	local distance = 36
	local intensity = 0.75
	local dot = 0.96
	local focusing = ZombRand(200)
	-- NOTE: distance,intensity values vary between 50% and 100% of the given value based on part condition.
	-- NOTE: focusing value is ignored, instead it is set based on part condition.
    local params = part:getTable("headlight")
    if params then
        xOffset = tonumber(params.xOffset) or xOffset
        yOffset = tonumber(params.yOffset) or yOffset
        distance = tonumber(params.distance) or distance
        intensity = tonumber(params.intensity) or intensity
        dot = tonumber(params.dot) or dot
        focusing = tonumber(params.focusing) or focusing
    end
	dot = 0.8
	intensity = 1.25
	
	if part:getId() == "HeadlightLeft" then
		part:createSpotLight(xOffset, yOffset, distance, intensity, dot, focusing)
	elseif part:getId() == "HeadlightRight" then
		part:createSpotLight(-xOffset, yOffset, distance, intensity, dot, focusing)
	else
		yOffset = 1.6;
		distance = 10;
		dot = 0.95
		intensity = 0.2;
		if part:getId() == "HeadlightRearLeft" then
			part:createSpotLightColor(xOffset, -yOffset, distance, intensity, dot, focusing, 1.0f, 0.2f, 0.2f)
		elseif part:getId() == "HeadlightRearRight" then
			part:createSpotLightColor(-xOffset, -yOffset, distance, intensity, dot, focusing, 1.0f, 0.2f, 0.2f)
		end
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
		
	local fanBelt = math.min(1,GetPartCondition(engine,PSC_Tags.EngineFanBelt) * 0.03); -- Scales from below 33%
	local alternator = math.min(1,GetPartCondition(engine,PSC_Tags.EngineAlternator) * 0.02); -- Alternator scales from below 50% condition. 
	
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
	
	-- Some fuel consumption specs:
	-- Cars generally use 0.5 to 1.3 liters per hour idling. 
	-- Aprox 8~11L/100km 
	local fuelUsagePerHour = 10; -- fuel consumption per ingame hour at peak output of typical engine
	-- Tests show a typical 100% engine idles at 0.5L/hour ingame. 
	
	if elapsedMinutes > 0 and amount > 0 and vehicle:isEngineRunning() then
		local engineSpeed = math.max(1000,vehicle:getEngineSpeed()); -- assume 1000 rpm min for fuel consumption to increase idle fuel consumption some.
		local amountOld = amount
		local qualityMultiplier = ((100 - vehicle:getEngineQuality()) / 100) + 1.0; -- Poor condition engines consume 2x as much fuel per HP produced (they produce less HP though, so it kinda balances out. More idle fuel usage though)

		local maxRPM = 4500;
		if vehicle:getScript():getEngineRPMType() == "firebird" or not REALISTICCARPHYSICS_ENABLED then
			maxRPM = 6000
		end
		
		-- use a min of 1000rpm to increase idle fuel consumption. maxRPM = full consumption. 
		local fuelConsumption = engineSpeed / maxRPM * fuelUsagePerHour * SandboxVars.CarGasConsumption;
		
		fuelConsumption = fuelConsumption * vehicle:getEnginePower() / 4000; -- 400hp will be the new 'vanilla' gas consumption HP. Change to 100 if operating in 'realistic' HP mode? 
			
		--print("Vehicle Throttle ", vehicle.throttle, " rpm ", vehicle:getEngineSpeed());
		
		fuelConsumption = fuelConsumption * qualityMultiplier * math.max(getThrottle(vehicle),0.2); -- Aprox 20% fuel consumption at idle (Multipled by Engine Speed this means more realistically about 3% at idle)
		
		 -- Debug test for now
		--print("throttle ",getThrottle(vehicle))
		
		--print("realistic car physics status: ", REALISTICCARPHYSICS_ENABLED);
		
		--Java RPM torque curve. 
		--float torqueCurve = Math.min(Math.max(1.0f - ((engineSpeed - maxRPM) / 1000.0f),0),1); // Reduce torque to 0 at 1000rpm above redline. 
		--torqueCurve *= Math.min(Math.max((engineSpeed / maxRPM) * 2,0.1),1); // Reach max torque at 1/2 max RPM, min 0.1x torque at startup. 

		if REALISTICCARPHYSICS_ENABLED then
			local torqueCurve = math.min(math.max(1.0 - ((engineSpeed - maxRPM) / 1000.0),0.3),1); -- Reduce fuel usage to 0.3 at 1000rpm above redline. 
			torqueCurve = torqueCurve * math.min(math.max((engineSpeed / maxRPM) * 2,0.5),1); -- Reach max torque at 1/2 max RPM, min 0.5x fuel consumption at idle 
			fuelConsumption = fuelConsumption * torqueCurve
			if SandboxVars.RealisticCarPhysics.HPWeightOverhaulBeta then
				local vehicleData = RCP_VehicleValues[vehicle:getScript():getFullType()];
				if vehicleData ~= nil then
					-- Boost fuel consumption as RCP boosts HP. 
					fuelConsumption = fuelConsumption * 4; 
				end
			end
		end
		
		fuelConsumption = fuelConsumption / BaseVehicle.getFakeSpeedModifier(); -- Scale fuel consumption by speed modifier so long trips on 'slow' servers consume the same amount of fuel. 
		
		amount = amount - (fuelConsumption * elapsedMinutes / 60); -- Convert fuel consumption from per hour to per minute. 
	
		-- if your gas tank is in bad condition, you can simply lose fuel
		if part:getCondition() < 30 then -- Lowered from 70%
			local fuelLoss = (30-part:getCondition()) / 30 * 0.05; -- 0.05 liters per minute loss
			amount = amount - (fuelLoss * elapsedMinutes); 
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
			local heaterCore = math.min(1,GetPartCondition(engine,PSC_Tags.EngineHeaterCore) * 0.02); -- Lower effiveness below 50%
			-- Todo: add requirement for water pump+fan belt+radiator fluid?
			local engineTemp = engine:getModData().temperature;
			heaterCore = partData.temperature * heaterCore * math.max((engineTemp - 50) / 50,0) -- Starts being effective at 50c, 1x output at 100c, nearly 2x at 140c (overheat)
			pcData.temperature = pcData.temperature + heaterCore * elapsedMinutes * 0.1;
		elseif partData.temperature < 0 then
			local airConditioner = math.min(1,GetPartCondition(engine,PSC_Tags.EngineAirConditioner) * 0.02); -- Lower effectiveness below 50% condition
			airConditioner = airConditioner * math.min(1,GetPartCondition(engine,PSC_Tags.EngineFanBelt) * 0.03); -- lower effectiveness below 30%
			-- Todo: add requirement for fan belt?
			-- Make output depend on condition and RPM?
			-- Ie, min(condition + rpm,1)
			pcData.temperature = pcData.temperature + partData.temperature * airConditioner * elapsedMinutes * 0.1;
		end
		pcData.temperature = pcData.temperature - (pcData.temperature * 0.1 * elapsedMinutes); -- Remove 10% of heat difference per minute. 
		
	end


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
			
			--TODO: FIXME!!!!
			--vehicle:getDriver():getBodyDamage():setWetness(vehicle:getDriver():getBodyDamage():getWetness() + math.max(0,vehicle:getCurrentSpeedKmHour()-10) * elapsedMinutes * 0.1)
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

		


