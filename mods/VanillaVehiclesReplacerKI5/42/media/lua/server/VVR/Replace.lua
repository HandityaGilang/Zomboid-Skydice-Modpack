local Data = require("VVR/Data")
local Utils = require("VVR/Utils")
local __vehicleUtils = require("YAPZLib/VehicleUtils")
local __utils = require("YAPZLib/Utils")

local parseSmashed = function(vehicle, scriptName)
	if scriptName:find("Lights") then
		if vehicle:getSkin():lower():find("police") then
			scriptName = scriptName:gsub("Lights%a+$", "LightsPolice")
		elseif vehicle:getSkin():lower():find("ranger") then
			scriptName = scriptName:gsub("Lights%a+$", "LightsRanger")
		elseif vehicle:getSkin():lower():find("fire") then
			scriptName = scriptName:gsub("Lights%a+$", "LightsFire")
		elseif vehicle:getSkin():lower():find("fossoil") then
			scriptName = scriptName:gsub("Lights%a+$", "LightsFossoil")
		end
	else
		if scriptName:find("CarSmall") then
			scriptName = "Base.SmallCar"
		else
			scriptName = scriptName:gsub("Smashed%a+$", "")
		end
	end
	
	return scriptName
end

local parseBurnt = function(vehicle, scriptName)
	if scriptName == "Base.PickupSpecialBurnt" then
		if vehicle:getSkin():lower():find("police") then
			scriptName = "Base.PickUpVanLightsPolice"
		elseif vehicle:getSkin():lower():find("ranger") then
			scriptName = "Base.PickUpVanLightsRanger"
		elseif vehicle:getSkin():lower():find("fire") then
			scriptName = "Base.PickUpVanLightsFire"
		elseif vehicle:getSkin():lower():find("fossoil") then
			scriptName = "Base.PickUpVanLightsFossoil"
		end
	elseif scriptName == "Base.NormalCarBurntPolice" then
		scriptName = "Base.CarLightsPolice"
	elseif scriptName == "Base.AmbulanceBurnt" then
		scriptName = "Base.VanAmbulance"
	elseif scriptName == "Base.LuxuryCarBurnt" then
		scriptName = "Base.CarLuxury"
	elseif scriptName == "Base.PickUpVanLightsBurnt" then
		scriptName = "Base.PickUpVanLightsPolice"
	elseif scriptName == "Base.PickupBurnt" then
		scriptName = "Base.PickUpTruck"
	elseif scriptName == "Base.TaxiBurnt" then
		scriptName = "Base.CarTaxi"
	elseif scriptName == "Base.RaceCarBurnt" then
		scriptName = "Base.RaceCar12"
	else
		scriptName = scriptName:gsub("Burnt$", "")
	end
	
	return scriptName
end

local getRandomVehicle = function(scriptName, region)
	local replaceData
	
    if Data.Tab[scriptName] then
        replaceData = Data.Tab[scriptName][region] or Data.Tab[scriptName]["General"]
    end
	
    if not replaceData then return end
	local vehicleData
	local randomChance = ZombRandFloat(0, 100)
	local cumulativeChance = 0
	
	for _, data in ipairs(replaceData) do
		if data.chance then
			cumulativeChance = cumulativeChance + data.chance
		else
			cumulativeChance = 100
		end
        if randomChance <= cumulativeChance then
            vehicleData = data
			break
        end
	end
	
	return vehicleData
end

local setSkin = function(vehicle, vehicleData)
	local stype = type(vehicleData.skinIndexes)
	if vehicleData.skinIndexes ~= nil and (stype == "table" or stype == "number") then
		local skinIndex
		if stype == "table" then
			skinIndex = vehicleData.skinIndexes[ZombRand(#vehicleData.skinIndexes) + 1]
		elseif stype == "number" then
			skinIndex = vehicleData.skinIndexes
		end
		vehicle:setSkinIndex(skinIndex)
	else
		local skinCount = ScriptManager.instance:getVehicle(vehicleData.vehicleName):getSkinCount()
		if skinCount > 1 then
			vehicle:setSkinIndex(ZombRand(skinCount))
		end
	end
	vehicle:transmitSkinIndex()
end

local restoreParams = function(vehicle, vehicleParams)
	vehicle:setGoodCar(vehicleParams.isGood)
	vehicle:setBloodIntensity("Front", vehicleParams.bloodIntFront)
	vehicle:setBloodIntensity("Right", vehicleParams.bloodIntRight)
	vehicle:setBloodIntensity("Left", vehicleParams.bloodIntLeft)
	vehicle:setBloodIntensity("Rear", vehicleParams.bloodIntRear)
	vehicle:transmitBlood()
	vehicle:setRust(vehicleParams.rust)
	vehicle:transmitRust()
	
	if vehicleParams.keySpawned then
		vehicle:addKeyToWorld()
	end
	
	if vehicleParams.isBurnt then
		vehicle:setGeneralPartCondition(SandboxVars.VVR.VehiCond * 2 / 100, 100)
	end
	
	if vehicleParams.partsStats then
		for i = 0, vehicle:getPartCount() - 1 do
			local part = vehicle:getPartByIndex(i)
			local partStats = vehicleParams.partsStats[part:getId()]
			if partStats then
				part:setCondition(partStats.condition)
				vehicle:transmitPartCondition(part)
				if partStats.contentAmount then
					part:setContainerContentAmount(round(part:getContainerCapacity() * partStats.contentAmount, 0))
				end
				if partStats.isMissing then
					part:setInventoryItem(nil)
					vehicle:transmitPartItem(part)
				end
			else
				local cond = round(vehicleParams.overallCondition, 0)
				part:setCondition(ZombRand(round(cond-cond / 2, 0), cond + 1))
				vehicle:transmitPartCondition(part)
			end
		end
	end
	
	__vehicleUtils.setBatteryCharge(vehicle, vehicleParams.batteryCharge)
end

local changingTireStoryFix = function(vehicle)
	if isMultiplayer() and not isServer() then return end
	if not __vehicleUtils.checkChunk(vehicle) then return end
	local squares = __vehicleUtils.getSquaresInRadius(vehicle, 5)
	for _, square in ipairs(squares) do
		local worldObjs = square:getWorldObjects()
		for i = 0, worldObjs:size() - 1 do
			local worldObj = worldObjs:get(i)
			if worldObj then
				local item = worldObj:getItem()
				if item and item:getType():contains("OldTire") and item:getCondition() == 0 then
					local newItem = Utils.GetRearTire(vehicle)
					if newItem then
						newItem:setCondition(0)
						worldObj:swapItem(newItem)
					end
				elseif item and item:getType():contains("ModernTire") then
					local newItem = Utils.GetRandomRearTire(vehicle)
					if newItem then
						newItem:setItemCapacity(newItem:getMaxCapacity())
						worldObj:swapItem(newItem)
					end
				end
			end
		end
	end
end

local replaceNew = function(vehicle)
	if isMultiplayer() and not isServer() then return end
	if not __vehicleUtils.isVanilla(vehicle) then return end
	if vehicle:isCreated() then return end
	if not SandboxVars.VVR.NoBurnt and vehicle:isBurnt() then return end
    local square = vehicle:getSquare()
    if not square then return end
    local region = square:getSquareRegion()
    if not region then region = "General" end
    local scriptName = vehicle:getScriptName()
    if not scriptName then return end
	local vehicleData = getRandomVehicle(scriptName, region)
	if not vehicleData then return end
	if not ScriptManager.instance:getVehicle(vehicleData.vehicleName) then return end
    vehicle:setScriptName(vehicleData.vehicleName)
    vehicle:scriptReloaded(true)
	setSkin(vehicle, vehicleData)
end

local replaceSpawned = function(vehicle)
	if isMultiplayer() and not isServer() then return end
	if not __vehicleUtils.isVanilla(vehicle) then return end
	if not vehicle:isCreated() then return end
	local vehicleParams = Utils.GetVehicleParams(vehicle)
	if not SandboxVars.VVR.NoBurnt and vehicleParams.isBurnt then return end
    local square = vehicle:getSquare()
    if not square then return end
    local region = square:getSquareRegion()
    if not region then region = "General" end
    local scriptName = vehicle:getScriptName()
    if not scriptName then return end
	if vehicleParams.isSmashed then
		scriptName = parseSmashed(vehicle, scriptName)
	end
	if SandboxVars.VVR.NoBurnt then
		if vehicleParams.isBurnt then
			scriptName = parseBurnt(vehicle, scriptName)
		end
	end
	local vehicleData = getRandomVehicle(scriptName, region)
	if not vehicleData then return end
	if not ScriptManager.instance:getVehicle(vehicleData.vehicleName) then return end
    vehicle:setScriptName(vehicleData.vehicleName)
    vehicle:scriptReloaded(true)
	setSkin(vehicle, vehicleData)
	restoreParams(vehicle, vehicleParams)
end

local doStoryFix = function(vehicle)
	local delay = 2
	if isMultiplayer() then
		if not isServer() then return end
		delay = 5
	end
	
	__utils.delay(changingTireStoryFix, delay, vehicle)
end

local vehiclesToCivil = { ["Base.78amgeneralM50A3"] = { 7 }, ["Base.78amgeneralM62"] = { 7 }, ["Base.80manKat1"] = { 0, 2, 3 }, ["Base.86chevyM1010"] = { 4 } }

local removeGunrackIfCivil = function(vehicle)
	if isMultiplayer() and not isServer() then return end
	if not __vehicleUtils.checkChunk(vehicle) then return end
	__utils.delay(function(vehicle)
		local scriptName = vehicle:getScriptName()
		if not __utils.tableHas(vehiclesToCivil, scriptName) then return end
		if __utils.tableHas(vehiclesToCivil[scriptName], vehicle:getSkinIndex()) then
			local zoneName = __vehicleUtils.getVehicleZone(vehicle)
			if not zoneName or not zoneName:lower():contains("military") then
				local gunrack = vehicle:getPartById("DAMNGunrack")
				if gunrack then
					__utils.clearContainer(gunrack:getItemContainer())
					gunrack:setCategory("nodisplay")
					gunrack:setInventoryItem(nil)
					gunrack:setItemContainer(nil)
				end
			end
		end
	end, 1, vehicle)
end

Events.OnSpawnVehicleStart.Add(replaceNew)
Events.OnSpawnVehicleStart.Add(replaceSpawned)
Events.OnSpawnVehicleEnd.Add(removeGunrackIfCivil)
Events.OnSpawnVehicleEnd.Add(doStoryFix)