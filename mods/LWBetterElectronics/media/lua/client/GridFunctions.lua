
local player = player

function checkIfIsBatteryPowered(obj)

local isBatteryPowered = false
	if obj:getDeviceData():getIsBatteryPowered() then
		isBatteryPowered = true		
	end	
	return isBatteryPowered
end

function connectDeviceToPowerGrid(localPlayer, obj)

--	print(obj, " should be connected to the grid now!!!!!")
	if 	checkIfIsBatteryPowered(obj) then
		obj:getDeviceData():setIsBatteryPowered(false)
	else
--		print("How did you end up here?")
	end
end

function disconnectDeviceFromPowerGrid(localPlayer, obj)

--	print(obj, " should be Disconnected from the grid now")	
	obj:getDeviceData():setIsBatteryPowered(true)
end

function GridMenu(playerIdx, context, worldObjects, test)
 	
	local localPlayer = getSpecificPlayer(playerIdx)
	
	for i, v in ipairs(worldObjects) do				
	
--		print("Check what Objects Player has Clicked")
--		print("Clicked On: ", worldObjects[i])	
		obj = worldObjects[i]	
--		testBool = checkIfIsAGridObject(obj)		
		if obj:getObjectName() == "Radio" then
			if checkIfIsBatteryPowered(obj) then
				context:addOption("Connect device to the power grid", localPlayer,connectDeviceToPowerGrid,worldObjects[i])
				break
			else
				context:addOption("Disconnect device from the power grid", localPlayer,disconnectDeviceFromPowerGrid,worldObjects[i])
				break
			end			
		elseif obj:getObjectName() == "IsoGenerator" then
--			print("The Player has clicked on a Generator: ", obj:getProperties():getPropertyNames())	
		
		elseif obj:getObjectName() == "LightSwitch" then
			print("LIGHTSWITCH FOUDN!")
			print(obj:canSwitchLight())
			print(obj.lightRoom)
			print(obj:getSquare())
			print(obj:getSquare():getRoomID())
		else 
--			if (instanceof(obj, "IsoDoor") or (instanceof(obj, "IsoThumpable") and obj:isDoor())) then
--				print("------------------",obj:getWorldObjectIndex(),"------------")
--			end
		print("Nothing found that needs Verkabelung")
		print(obj:getObjectName())
		end
    end
end


Events.OnFillWorldObjectContextMenu.Add(GridMenu)
