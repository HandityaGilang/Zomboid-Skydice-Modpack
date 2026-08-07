require "VVR/Data"
require "VVR/Utils"

VVR = VVR or {}
VVR.Replace = {}
VVR.Replace.List = {}

function VVR.Replace.ParseSmashed(vehicle, scriptName)
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

function VVR.Replace.ParseBurnt(vehicle, scriptName)
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
		scriptName = scriptName:gsub("Burnt$", "")
	end
	return scriptName
end

function VVR.Replace.GetRandomVehicle(scriptName)
	local ReplaceData
    if VVR.Data.Tab[scriptName] then
        ReplaceData = VVR.Data.Tab[scriptName]
    end
    if not ReplaceData then return end
	local VehicleData
	local randomChance = ZombRandFloat(0, 100)
	local cumulativeChance = 0
	for _, vehicleData in ipairs(ReplaceData) do
		if vehicleData.chance then
			cumulativeChance = cumulativeChance+vehicleData.chance
		else
			cumulativeChance = 100
		end
        if randomChance <= cumulativeChance then
            VehicleData = vehicleData
			break
        end
	end
	return VehicleData
end

function VVR.Replace.SetSkin(vehicle, VehicleData)
	if VehicleData.skinIndexes ~= nil then
		local skinIndex = VehicleData.skinIndexes[ZombRand(#VehicleData.skinIndexes)+1]
		vehicle:setSkinIndex(skinIndex)
	else
		local skinCount = ScriptManager.instance:getVehicle(VehicleData.vehicleName):getSkinCount()
		if skinCount > 1 then
			vehicle:setSkinIndex(ZombRand(skinCount))
		end
	end
	vehicle:transmitSkinIndex()
end

function VVR.Replace.RestoreParams(vehicle, VehicleParams)
	vehicle:setGoodCar(VehicleParams.isGood)
	vehicle:setBloodIntensity("Front", VehicleParams.bloodIntFront)
	vehicle:setBloodIntensity("Right", VehicleParams.bloodIntRight)
	vehicle:setBloodIntensity("Left", VehicleParams.bloodIntLeft)
	vehicle:setBloodIntensity("Rear", VehicleParams.bloodIntRear)
	vehicle:transmitBlood()
	vehicle:setRust(VehicleParams.rust)
	vehicle:transmitRust()
	if VehicleParams.isBurnt then
		vehicle:setGeneralPartCondition(SandboxVars.VVR.VehiCond*2/100, 100)
	end
	if VehicleParams.partsStats then
		for i=0, vehicle:getPartCount()-1 do
			local part = vehicle:getPartByIndex(i)
			local partStats = VehicleParams.partsStats[part:getId()]
			if partStats then
				if not partStats.isMissing then
					part:setCondition(partStats.condition)
					vehicle:transmitPartCondition(part)
					if partStats.contentAmount then
						part:setContainerContentAmount(round(part:getContainerCapacity()*partStats.contentAmount, 0))
					end
				else
					part:setInventoryItem(nil)
					vehicle:transmitPartItem(part)
				end
			else
				local cond = round(VehicleParams.overallCondition, 0)
				part:setCondition(ZombRand(round(cond-cond/2, 0), cond+1))
				vehicle:transmitPartCondition(part)
			end
		end
	end
	local battery = vehicle:getBattery()
	if battery then
		local batteryItem = battery:getInventoryItem()
		if batteryItem then
			batteryItem:setUsedDelta(VehicleParams.batteryCharge)
		end
	end
end

function VVR.Replace.ChangingTireStoryFix(vehicle)
	local squares = VVR.Utils.GetSquaresInRadius(vehicle, 7)
	for _, square in ipairs(squares) do
		local worldObjs = square:getWorldObjects()
		for i = 0, worldObjs:size()-1 do
			local worldObj = worldObjs:get(i)
			if worldObj then
				local item = worldObj:getItem()
				if item and item:getType():contains("OldTire") and item:getCondition() == 0 then
					local newItem = VVR.Utils.GetRearTire(vehicle)
					if newItem then
						newItem:setCondition(0)
						worldObj:swapItem(newItem)
					end
				elseif item and item:getType():contains("ModernTire") then
					local newItem = VVR.Utils.GetRandomRearTire(vehicle)
					if newItem then
						newItem:setItemCapacity(newItem:getMaxCapacity())
						worldObj:swapItem(newItem)
					end
				end
			end
		end
	end
end

function VVR.Replace.GroundKeyFix(vehicle)
	local squares = VVR.Utils.GetSquaresInRadius(vehicle, 10)
	for _, square in ipairs(squares) do
		local worldObjs = square:getWorldObjects()
		for i = 0, worldObjs:size()-1 do
			local worldObj = worldObjs:get(i)
			if worldObj then
				local item = worldObj:getItem()
				if item and item:getType():contains("CarKey") and item:getKeyId() == vehicle:getKeyId() then
					local newItem = vehicle:createVehicleKey()
					if newItem then
						worldObj:swapItem(newItem)
					end
				end
			end
		end
	end
end

function VVR.Replace.OnFillContainer(roomType, containerType, container)
	if not container then return end
	local vehicle = container:getParent()
	if not vehicle then return end
	if not instanceof(vehicle, "BaseVehicle") then return end
    local scriptName = vehicle:getScriptName()
    if not scriptName then return end
	local id = tostring(scriptName..vehicle:getSqlId()..vehicle:getId())
	if VVR.Replace.List[id] then return end
	VVR.Replace.List[id] = true
	local VehicleData = VVR.Replace.GetRandomVehicle(scriptName)
	if not VehicleData then return end
	if not ScriptManager.instance:getVehicle(VehicleData.vehicleName) then return end
	if getWorld():getGameMode() == "Multiplayer" then
		if isServer() then
			VVR.Delay.Add(function(vehicle, id, VehicleData)
				local VehicleParams = VVR.Utils.GetVehicleParams(vehicle)
				if (SandboxVars.VVR.NoBurntTJ ~= 0 or SandboxVars.VVR.NoBurntJY ~= 0 or SandboxVars.VVR.NoBurntTP ~= 0) and VehicleParams.isBurnt then VVR.Replace.List[id] = nil return end
				VVR.Utils.ScriptReloaded(vehicle, VehicleData.vehicleName)
				VVR.Replace.SetSkin(vehicle, VehicleData)
				VVR.Replace.RestoreParams(vehicle, VehicleParams)
				VVR.Replace.List[id] = nil
			end, 5, { vehicle, id, VehicleData })
			VVR.Delay.Add(VVR.Replace.GroundKeyFix, 5, { vehicle })
		end
	else
		VVR.Delay.Add(function(vehicle, id, VehicleData)
			local VehicleParams = VVR.Utils.GetVehicleParams(vehicle)
			if (SandboxVars.VVR.NoBurntTJ ~= 0 or SandboxVars.VVR.NoBurntJY ~= 0 or SandboxVars.VVR.NoBurntTP ~= 0) and VehicleParams.isBurnt then VVR.Replace.List[id] = nil return end
			vehicle:setScriptName(VehicleData.vehicleName)
			vehicle:scriptReloaded()
			VVR.Replace.SetSkin(vehicle, VehicleData)
			VVR.Replace.RestoreParams(vehicle, VehicleParams)
			VVR.Replace.List[id] = nil
		end, 5, { vehicle, id, VehicleData })
		VVR.Delay.Add(VVR.Replace.GroundKeyFix, 5, { vehicle })
	end
end

Events.OnFillContainer.Add(VVR.Replace.OnFillContainer)

Events.OnFillContainer.Add(function(roomType, containerType, container) 
	if not container then return end
	local vehicle = container:getParent()
	if not vehicle then return end
	if not instanceof(vehicle, "BaseVehicle") then return end
	VVR.Delay.Add(VVR.Replace.ChangingTireStoryFix, 5, { vehicle })
end)