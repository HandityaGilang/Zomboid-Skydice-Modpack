--This can be Accessed from the Outside to see if the Mod is Active like "if LWBetterElectronics then ..."
LWBetterElectronics = LWBetterElectronics
-- ----------------------------------------------------------

local player = player
local SaveX = 0
local SaveY = 0
local RemoteLinkTable = {}

local remoteReceivers = { "RemoteDoormotor"}
local remoteTypes = {"RemoteCraftedV1","RemoteCraftedV2","RemoteCraftedV3","AdvancedRemoteCraftedV1" ,"AdvancedRemoteCraftedV2","AdvancedRemoteCraftedV3"}


local function getPlayer()
	for playerIndex = 0, getNumActivePlayers() -1 do
		
		player = getSpecificPlayer(playerIndex)		
	end
end

local function loadModData()

	local hasLoadedData =false
	getPlayer()
	print("Trying to load Moddata: ", player:getModData())
	if player:getModData() ~= nil then
		RemoteLinkTable = player:getModData()["RemoteLinkTable"]
		print("RemoteLinkTable loaded: ", RemoteLinkTable)
		if RemoteLinkTable ~= nil then
			print("ModData Loaded")
			hasLoadedData = true
		else
		print("No Remote Linktable could be found in the  ModData")
		end
	end
	return hasLoadedData
end

local function saveDoorlinkToModdata(localRemoteID, posX, posY, player)
	
	print("Player: ", player)
	loadModData()
	print("trying to save ModData of ",localRemoteID, " into RemoteLinkTable   ", RemoteLinkTable)
	if RemoteLinkTable == nil then
		print("Generating new RemoteLinkTable")
		RemoteLinkTable = {}
	end
	if RemoteLinkTable ~= nil then
		RemoteLinkTable[localRemoteID] = {posX, posY, player}	
		player:getModData()["RemoteLinkTable"] = RemoteLinkTable 	
		print("ModData Saved!")
		print("Remote ID = ", localRemoteID) 
		print("Door X = ", posX) 
		print("Door Y = ", posY) 
	end

end

local function getLinkedPosX(localRemoteID)
	
	if (RemoteLinkTable[localRemoteID] ~= nil) then
	posX = RemoteLinkTable[localRemoteID][1]	
	return posX
	else
	posX = 0
	end
	
end

local function getLinkedPosY(localRemoteID)		

	if (RemoteLinkTable[localRemoteID] ~= nil) then
	posY = RemoteLinkTable[localRemoteID][2]		
	return posY
	else
	posY = 0
	end
	
end

local function isObjectDoor(obj)

--	print(obj,instanceof(obj, "IsoDoor"))
	isDoor = false
	if (instanceof(obj, "IsoDoor") or (instanceof(obj, "IsoThumpable") and obj:isDoor())) then	
		isDoor =true
	end

return isDoor

end

local function searchDoorOnSquare(cell, square)	
	
--	print("Searching through objects on square: ", square)
	local objs = square:getObjects()
	local objs_size = objs:size()
	local obj
	
	if objs_size > 0 then
		print(objs_size)
		for i = 0, objs_size - 1, 1 do
			obj = objs:get(i)			
--			print(i, obj)
				if isObjectDoor(obj) then	
--				print("found a door on square! ", obj)
				break
			end					
		end			
	end
	return obj
end

local function RemoteToggleDoor(doorObj)
	
	doorObj:ToggleDoor(player) 
	
end



local function check_if_door(posX,posY)

	local isDoorObject = {}
	if player== nil then getPlayer() end
	
--	print(" Checking if x ",posX," and y ", posY, " is a Door")
		  isDoorObject[1] = false
	local cell = getWorld():getCell()	
	local square = cell:getGridSquare(posX , posY , player:getCurrentSquare():getZ());
	if square then
		
		local doorObj =searchDoorOnSquare(cell,square)
		
		if isObjectDoor(doorObj) then
		
								
--			print("Door found at X ", posX, ", Y ", posY)
			isDoorObject[1]=true
			isDoorObject[2]=doorObj
			
		end	
	end
	return isDoorObject
end

local function getDoorCornerX(doorObj)
-- I promise this will totally bug out if there are multiple thumpable doors directly attached to each other --
local doorOpen 	= doorObj:IsOpen()
local doorNorth	= doorObj:getNorth()
local doorX		= doorObj:getX()

  	if (instanceof(doorObj, "IsoThumpable")) or (instanceof(doorObj, "IsoDoor")) then
  		if ((doorNorth == false) and (doorOpen == false)) then
  			return doorX
  
  		elseif ((doorNorth == true) and (doorOpen == false)) then
--  			print("Door Faces North therefor X has to be searched for the Corner")
  			if check_if_door(doorX-1,doorObj:getY())[1] then
-- 				print("Found another Door at X: ", doorX-1, "Search continues at X: ", doorX-2)
  				if check_if_door(doorX-2,doorObj:getY())[1] then
-- 					print("Found another Door at X: ", doorX-2, "Search continues at X: ", doorX-3)
  					if check_if_door(doorX-3,doorObj:getY())[1] then
--  						print("Found another Door at X: ", doorX-3, "this has to be the Cornerpiece!")
  						return doorX -3
  					else
  					
  					return doorX -2
  					end		
  				else
  				
  				return doorX -1
  				end
  			else	
  			
  			return doorX
  			end		
  		
  		elseif ((doorNorth == true) and (doorOpen == true )) then 			
 			if check_if_door(doorX-3,doorObj:getY())[1]  then 				
 				return doorX - 3
  			else 				
 				return doorX
  			end
  		else 
 		
 			if check_if_door(doorX-1,doorObj:getY())[1]  then
 				return doorX - 1
 			else
 				return doorX
 			end
  		end	
  	end

end

local function getDoorCornerY(doorObj)
-- I promise this will totally bug out if there are multiple thumpable doors directly attached to each other --
	local doorOpen 	= doorObj:IsOpen()
	local doorNorth	= doorObj:getNorth()
	local doorY		= doorObj:getY()
--	print("Looking for DoorCorner!")
--	print("Starting at Y: ", doorY)
	
	if (instanceof(doorObj, "IsoThumpable")) or (instanceof(doorObj, "IsoDoor")) then
		if  doorNorth == true and doorOpen == false then
			return doorY
		
		elseif ((doorNorth == false) and (doorOpen == false)) then
			if check_if_door(doorObj:getX(),doorY-1)[1] then
--				print("Found another Door at Y: ", doorY-1, "Search continues at Y: ", doorY-2)
				if check_if_door(doorObj:getX(),doorY-2)[1] then
--					print("Found another Door at Y: ", doorY-2, "Search continues at Y: ", doorY-3)
					if check_if_door(doorObj:getX(),doorY-3)[1] then
--						print("Found another Door at Y: ", doorY-3, "this has to be the Cornerpiece!")
						
						return doorY -3
					else
--					print("Found NO Door at Y: ", doorY-3, "The Cornerpiece must be Y: ", doorY-2)
					return doorY -2
					end		
				else
--				print("Found NO Door at Y: ", doorY-2, "The Cornerpiece must be Y: ", doorY-1)
				return doorY -1
				end
			else	
--				print("Found NO Door at Y: ", doorY-1, "The Cornerpiece must be Y: ", doorY)
				return doorY
			end
		
		elseif  ((doorNorth == true) and (doorOpen == true)) then
			if check_if_door(doorObj:getX(),doorY-1)[1] then
				return doorY - 1
			else
				return doorY
			end
		else
			if check_if_door(doorObj:getX(),doorY-3)[1] then
				return doorY - 3
			else
				return doorY	
			end
		end
	end	
	
end

local function search_for_door(localRemoteID,posX,posY,player)
	
	local doorfound = false	
	
	if check_if_door( posX    , posY    )[1] then doorfound =true local doorObj = check_if_door( posX    , posY    )[2] saveDoorlinkToModdata(localRemoteID, getDoorCornerX(doorObj), getDoorCornerY(doorObj), player) 	return doorfound end 
	if check_if_door( posX -1 , posY -1 )[1] then doorfound =true local doorObj = check_if_door( posX -1 , posY -1 )[2] saveDoorlinkToModdata(localRemoteID, getDoorCornerX(doorObj), getDoorCornerY(doorObj), player)  return doorfound end 
	if check_if_door( posX -1 , posY    )[1] then doorfound =true local doorObj = check_if_door( posX -1 , posY    )[2] saveDoorlinkToModdata(localRemoteID, getDoorCornerX(doorObj), getDoorCornerY(doorObj), player)  return doorfound end 
	if check_if_door( posX -1 , posY +1 )[1] then doorfound =true local doorObj = check_if_door( posX -1 , posY +1 )[2] saveDoorlinkToModdata(localRemoteID, getDoorCornerX(doorObj), getDoorCornerY(doorObj), player)  return doorfound end 
	if check_if_door( posX    , posY -1 )[1] then doorfound =true local doorObj = check_if_door( posX    , posY -1 )[2] saveDoorlinkToModdata(localRemoteID, getDoorCornerX(doorObj), getDoorCornerY(doorObj), player)  return doorfound end 
	if check_if_door( posX    , posY +1 )[1] then doorfound =true local doorObj = check_if_door( posX    , posY +1 )[2] saveDoorlinkToModdata(localRemoteID, getDoorCornerX(doorObj), getDoorCornerY(doorObj), player)  return doorfound end 
	if check_if_door( posX +1 , posY -1 )[1] then doorfound =true local doorObj = check_if_door( posX +1 , posY -1 )[2] saveDoorlinkToModdata(localRemoteID, getDoorCornerX(doorObj), getDoorCornerY(doorObj), player)  return doorfound end 
	if check_if_door( posX +1 , posY    )[1] then doorfound =true local doorObj = check_if_door( posX +1 , posY    )[2] saveDoorlinkToModdata(localRemoteID, getDoorCornerX(doorObj), getDoorCornerY(doorObj), player)  return doorfound end 
	if check_if_door( posX +1 , posY +1 )[1] then doorfound =true local doorObj = check_if_door( posX +1 , posY +1 )[2] saveDoorlinkToModdata(localRemoteID, getDoorCornerX(doorObj), getDoorCornerY(doorObj), player)  return doorfound end 

end



local function LWBetterElectronics_HelloWorld()

	getPlayer()
	loadModData()
	
end

local function RigDoorToRemote(localRemoteID)

	getPlayer()
	loadModData()
	
	local position = player:getCurrentSquare()
	local posX = position:getX()	
	local posY = position:getY()
--	print("Searching for Door im x ",posX,"and y", posY)
	
	search_for_door(localRemoteID, posX, posY, player)
		
	
end

local function CalculateDistance(x1,y1,x2,y2)

local dx = x1-x2
local dy = y1-y2
local dist = (dx^2+dy^2)^(0.5)

return dist
end

local function OpenDoorWithRemote(localRemoteID, range)
	
	getPlayer()
	if loadModData() then
		print("Check if Remote ID has Doordata attached...",RemoteLinkTable[localRemoteID])
		
		if (RemoteLinkTable[localRemoteID] ~= nil) then		
			local posX = getLinkedPosX(localRemoteID)
			local posY = getLinkedPosY(localRemoteID)
			if 	posX ~= null and posY ~= null then 
				local dist = CalculateDistance(posX,posY,player:getCurrentSquare():getX(),player:getCurrentSquare():getY())
				
--				print("Door X:", posX)
--				print("Door Y:", posY)
--				print("Door to Player Distance is: ", dist)
				
				if dist <= range then		
					if check_if_door(posX,posY)[1] then
					RemoteToggleDoor(check_if_door(posX,posY)[2])
					end
					
				else
					player:Say("I think I am out of Range")
				end
			else
			player:Say("This Remote has no Motor Connected to it")			
			end
		else
		
		end
	end
end

local function OnClientCommand(module, command, player, args)
	if command == 'triggerRemote' then 	
		
		local remote_id = 0
		local range = 0
		
		for _,i in pairs(args) do
			if remote_id == 0 then 
				remote_id = i;
				print("Remote ID: ",remote_id)
			else 
				if range == 0 then 
					range = i;
--					print("Remote Range: ",range)
				end
			end
		end
		OpenDoorWithRemote(remote_id,range)
	end
end




local function checkIfInstallationPossible(obj)

	local isDoor = false
--	print("Doorobject: ",obj)
	check_if_door(obj:getX(),obj:getY())
	if (instanceof(obj, "IsoDoor") or (instanceof(obj, "IsoThumpable") and obj:isDoor())) then
--	print("Installation possible!")
	isDoor =true

	else
--	print("Can't Install here")
	end
	return isDoor
end




local function RigDoor(localPlayer, doorObj)
	
	local localdistance
	local receiver
	local localRemoteID
    for _,name in ipairs(remoteReceivers) do
        receiver = localPlayer:getInventory():getFirstType(name)
        if receiver then		
			localRemoteID = receiver:getRemoteControlID()
				if localRemoteID >= 0 then
--				print("Receiver found AGAIN!! :>", localRemoteID)
				
				break
			end
        end
        receiver = nil
	end

	
    localdistance = CalculateDistance(localPlayer:getCurrentSquare():getX(),localPlayer:getCurrentSquare():getY(),doorObj:getX(),doorObj:getY())

--	print("----Player to Door Distance: ",localdistance)	

	if localdistance <= 1.1 then
--		if (doorObjopen()) then
--		print("The door is open")
--		end
		localPlayer:Say("Linked door to Remote")
		if(doorObj:IsOpen()) then
			doorObj:ToggleDoor(localPlayer) 
		end
		RigDoorToRemote(localRemoteID)
		localPlayer:getInventory():DoRemoveItem(receiver)
	else
	
		localPlayer:Say("I need to be closer to the door to install this")
	end
end



function getInventoryRemoteIDs(playerIdx)

	local remoteIDs ={}
	local localPlayer = getSpecificPlayer(playerIdx)
	local remoteIndex = 1
--	print("GetInventoryRemotes: looking for Remote in the Inventory of ", localPlayer)

    for i,name in ipairs(remoteTypes) do
        local remote = localPlayer:getInventory():getFirstType(name)
        if remote then		
			localRemoteID = remote:getRemoteControlID()
				if localRemoteID >= 0 then
--				print("Run: ",i," Remote found in Inventory :>", localRemoteID)
				remoteIDs[remoteIndex] ={ localRemoteID , remote:getRemoteRange()}
				remoteIndex = remoteIndex + 1
			end
        end        
	end
	
	return remoteIDs

end

function hasRemoteInInventory(playerIdx) 

local localPlayer = getSpecificPlayer(playerIdx)
hasRemote= false
--print("looking for Remote in the Inventory")

    for _,name in ipairs(remoteTypes) do
        remote = localPlayer:getInventory():getFirstType(name)
        if remote then		
			localRemoteID = remote:getRemoteControlID()
				if localRemoteID >= 0 then
--				print("Remote found in Inventory :>", localRemoteID)
				hasRemote = true
				break
			end
        end        
	end
	return hasRemote
end

local function toggleDoorFromContextMenu(localPlayer, doorObj)
-- This one is a crutch I know x.x --
RemoteToggleDoor(doorObj)

end

local function removeMotorFromContextMenu(localPlayer, doorObj)
	
--	print("Removing Motor from door with ID: ", doorObj)
		
	local localdistance	
	local localRemoteID
	

		


	
    localdistance = CalculateDistance(localPlayer:getCurrentSquare():getX(),localPlayer:getCurrentSquare():getY(),doorObj:getX(),doorObj:getY())
	if localdistance <= 1.1 then

		localPlayer:Say("Removing the Doormotor")
		for _,name in ipairs(remoteTypes) do
	
			local receiver	 = localPlayer:getInventory():getFirstType(name)
			
		  	if receiver then		
				localRemoteID = receiver:getRemoteControlID()
				print("Receiver: ", localRemoteID)
				if localRemoteID >= 0 then
				RemoteLinkTable[localRemoteID] = {nil, nil, nil}			
				end
			end
		end
		
		
		localPlayer:getInventory():AddItem("LWBetterElectronics.RemoteDoormotor");
	else
	
		localPlayer:Say("I need to be closer to the door to do this")
	end
	
end


local function validateDoor(localRemoteID, doorToToggle)
	local doorvalid = false
	local posX = getLinkedPosX(localRemoteID)
	local posY = getLinkedPosY(localRemoteID)
--	print("DatabasePosX: ",posX,"  DoorToTogglePosX: ", getDoorCornerX(doorToToggle))
--	print("DatabasePosY: ",posY,"  DoorToTogglePosY: ", getDoorCornerY(doorToToggle))

	
	if posX == getDoorCornerX(doorToToggle) and posY == getDoorCornerY(doorToToggle) then	
		doorvalid = true
--		print("The Opening of the door seems Valid")
	end
	
	return doorvalid	
end

function AutoDoorMenu(playerIdx, context, worldObjects, test)
 
	
	local localPlayer = getSpecificPlayer(playerIdx)
    local receiver
--	print("looking for a Receiver in Inventory! ", playerIdx)
    for _,name in ipairs(remoteReceivers) do
        receiver = localPlayer:getInventory():getFirstType(name)
        if receiver then		
			local localRemoteID = receiver:getRemoteControlID()
				if localRemoteID >= 0 then
--				print("Receiver! :>", localRemoteID)
				
				break
			end
        end
        receiver = nil
    end
    
    if receiver then
 
		for i, v in ipairs(worldObjects) do		
		
--		print(i," -- ",v)
			if checkIfInstallationPossible(worldObjects[i]) then
				if receiver then
					context:addOption("Install Remote Door Motor", localPlayer,RigDoor,worldObjects[i])
					break
				end	
			end		
		end
    else
	
--	print("No Receiver in Inventory :<")
	end
	
	
	

	
	for i, v in ipairs(worldObjects) do		
		if isObjectDoor(worldObjects[i]) then 
--			print("found a door -look through Inventory for a Remote")
--			print("Door: ", worldObjects[i])
			if hasRemoteInInventory(playerIdx) then
				local localRemotes = getInventoryRemoteIDs(playerIdx)
				print (getInventoryRemoteIDs(playerIdx)[1][1])
				for i,id in ipairs(localRemotes) do					
					if (RemoteLinkTable[localRemotes[i][1]] ~= nil) then
--						print("Remote has Doordata attached!: ", localRemotes[i])
--						print("It is connected to: X: ", getLinkedPosX(localRemotes[i]), " and Y: ", getLinkedPosY(localRemotes[i]))					
						if isObjectDoor(worldObjects[i]) then							
--							print("Checking if the door is valid for Remote")
							if (validateDoor(localRemotes[i][1],worldObjects[i])) then
								if worldObjects[i]:IsOpen() then
							context:addOption("Close Door with Remote", localPlayer,toggleDoorFromContextMenu,worldObjects[i])								
								else
								context:addOption("Open Door with Remote", localPlayer,toggleDoorFromContextMenu,worldObjects[i])
								context:addOption("Remove Doormotor", localPlayer,removeMotorFromContextMenu,worldObjects[i])
								end
								
							end
								
						end
					else
--					print("Remote has no Doordata :< : ", localRemotes[i])
					end
				end
			end	
			break			
		end		
    end
end

--
local function toggleFirstRemote(key)
    if key == getCore():getKey('Toggle_Remote') then
		
			for playerIndex = 0, getNumActivePlayers() -1 do		
				localPlayerIdx = playerIndex		
			end
	   				
		if hasRemoteInInventory(localPlayerIdx) then
			local localRemotes = getInventoryRemoteIDs(localPlayerIdx)
			for i,id in ipairs(localRemotes) do	
--				print("Remote !!", localRemotes[i][1])
				OpenDoorWithRemote(localRemotes[i][1],localRemotes[i][2])
			end
			print(localRemotes)
		end
		
    end
end

Events.OnKeyPressed.Add(toggleFirstRemote)

Events.OnFillWorldObjectContextMenu.Add(AutoDoorMenu)
Events.EveryHours.Add(LWBetterElectronics_HelloWorld)
Events.OnClientCommand.Add(OnClientCommand)