require "TMRadio"

UseTerminalMenu = {}

UseTerminalMenu.doBuildMenu = function(player, context, worldobjects)
	local Terminal = nil
	local X = nil
	local Y = nil
	local Z = nil

	for _,object in ipairs(worldobjects) do
		local square = object:getSquare()

		if not square then
			return
		end

		X = square:getX()
		Y = square:getY()
		Z = square:getZ()

		for i=1,square:getObjects():size() do
			local thisObject = square:getObjects():get(i-1)
			
			if thisObject:getSprite() then
				local properties = thisObject:getSprite():getProperties()
				local spr = thisObject:getSprite():getName()  

				if properties == nil then
					return
				end

				local customName = nil
				local groupName = nil

				if properties:has("CustomName") then
					customName = properties:get("CustomName")
				end

				if properties:has("GroupName") then
					groupName = properties:get("GroupName")
				end
			
				if customName == "Terminal" and groupName == "Security" then				
					Terminal = thisObject
					Terminal:getModData()

					if not Terminal:getModData()['StationControl'] then
						Terminal:getModData()['StationControl'] = 0
					end

					if not Terminal:getContainer() and ((X == 4833 and Y == 6277 and Z == 0) or (X == 4834 and Y == 6277 and Z == 0) or (X == 4832 and Y == 6279 and Z == 0) or (X == 4837 and Y == 6278 and Z == 0) or (X == 4837 and Y == 6279 and Z == 0) or 
						Terminal:getModData()['StationControl'] == SandboxVars.TrueMusicRadio.TMRChannel1 or Terminal:getModData()['StationControl'] == SandboxVars.TrueMusicRadio.TMRChannel2 or
						Terminal:getModData()['StationControl'] == SandboxVars.TrueMusicRadio.TMRChannel3 or Terminal:getModData()['StationControl'] == SandboxVars.TrueMusicRadio.TMRChannel4 or
						Terminal:getModData()['StationControl'] == SandboxVars.TrueMusicRadio.TMRChannel5 or Terminal:getModData()['StationControl'] == SandboxVars.TrueMusicRadio.TMRMTV) then

						local index = Terminal:getObjectIndex()
						local stationControl = Terminal:getModData()['StationControl']
               					sledgeDestroy(Terminal)
						Terminal:getSquare():transmitRemoveItemFromSquare(Terminal)            

                				Terminal = IsoThumpable.new(getCell(), square, spr, false, ISWoodenContainer:new(spr, nil))  
                				Terminal:setIsContainer(true)
                				Terminal:getContainer():setType("securityterminal")
                				Terminal:getContainer():setCapacity(50)
						Terminal:getModData()['StationControl'] = stationControl

                				--square:AddTileObject(Terminal, index)
						--square:transmitAddObjectToSquare(Terminal, Terminal:getObjectIndex())
						square:transmitAddObjectToSquare(Terminal, index)
						square:transmitModdata()

						local tempGlobalPlaylist = {}
						for k,v in pairs(GlobalMusic) do
    							tempGlobalPlaylist[#tempGlobalPlaylist + 1] = k
						end

						local maxMusic = SandboxVars.TrueMusicRadio.TMRMusicTerminalFilledAmount

						if maxMusic == 6 then
							maxMusic = 0
							Terminal:getModData()['LoadedCapacity'] = 0
						elseif maxMusic == 5 then
							maxMusic = ZombRand(1,111)
							Terminal:getModData()['LoadedCapacity'] = ZombRand(1,111)
						elseif maxMusic == 4 then
							maxMusic = ZombRand(75,111)
							Terminal:getModData()['LoadedCapacity'] = ZombRand(75,111)
						elseif maxMusic == 3 then
							maxMusic = ZombRand(25,75)
							Terminal:getModData()['LoadedCapacity'] = ZombRand(25,75)
						elseif maxMusic == 2 then
							maxMusic = ZombRand(10,25)
							Terminal:getModData()['LoadedCapacity'] = ZombRand(10,25)
						elseif maxMusic == 1 then
							maxMusic = ZombRand(1,10)
							Terminal:getModData()['LoadedCapacity'] = ZombRand(1,10)
						end
				
						local canEject = SandboxVars.TrueMusicRadio.TMRTerminalEjectsMusic
						if not canEject then
							Terminal:getModData()['LoadedCapacity'] = 0
						end
						Terminal:transmitModData()

						local musicItems = 0
						while musicItems < maxMusic do
							local musicItem = "Tsarcraft." .. tempGlobalPlaylist[ZombRand(1, #tempGlobalPlaylist+1)]
							local addItem = Terminal:getItemContainer():AddItem(musicItem)
							if isClient() then
								Terminal:getItemContainer():addItemOnServer(addItem)
							end
							musicItems = musicItems + 1
						end
					end
					break
				end
			end 
		end 
	end

	if not Terminal then 
		return 
	end

	if not Terminal:getModData()['LoadedCapacity'] then
		Terminal:getModData()['LoadedCapacity'] = 0
	end

	if (X == 4833 and Y == 6277 and Z == 0) or Terminal:getModData()['StationControl'] == SandboxVars.TrueMusicRadio.TMRChannel1 then
		if Terminal:getModData()['StationControl'] == 0 then
			Terminal:getModData()['StationControl'] = SandboxVars.TrueMusicRadio.TMRChannel1
		end
		context:addOption(SandboxVars.TrueMusicRadio.TMRChannel1/1000 .. "FM: " .. TMRadio.translation.update,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "UpdateA",
				  nil)
		context:addOption(SandboxVars.TrueMusicRadio.TMRChannel1/1000 .. "FM: " .. TMRadio.translation.revert,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "RevertA",
				  nil)
	elseif (X == 4834 and Y == 6277 and Z == 0) or Terminal:getModData()['StationControl'] == SandboxVars.TrueMusicRadio.TMRChannel2 then
		if Terminal:getModData()['StationControl'] == 0 then
			Terminal:getModData()['StationControl'] = SandboxVars.TrueMusicRadio.TMRChannel2
		end
		context:addOption(SandboxVars.TrueMusicRadio.TMRChannel2/1000 .. "FM: " .. TMRadio.translation.update,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "UpdateB",
				  nil)
		context:addOption(SandboxVars.TrueMusicRadio.TMRChannel2/1000 .. "FM: " .. TMRadio.translation.revert,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "RevertB",
				  nil)
	elseif (X == 4837 and Y == 6278 and Z == 0) or Terminal:getModData()['StationControl'] == SandboxVars.TrueMusicRadio.TMRChannel3 then
		if Terminal:getModData()['StationControl'] == 0 then
			Terminal:getModData()['StationControl'] = SandboxVars.TrueMusicRadio.TMRChannel3
		end
		context:addOption(SandboxVars.TrueMusicRadio.TMRChannel3/1000 .. "FM: " .. TMRadio.translation.update,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "UpdateC",
				  nil)
		context:addOption(SandboxVars.TrueMusicRadio.TMRChannel3/1000 .. "FM: " .. TMRadio.translation.revert,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "RevertC",
				  nil)
	elseif (X == 4837 and Y == 6279 and Z == 0) or Terminal:getModData()['StationControl'] == SandboxVars.TrueMusicRadio.TMRChannel4 then
		if Terminal:getModData()['StationControl'] == 0 then
			Terminal:getModData()['StationControl'] = SandboxVars.TrueMusicRadio.TMRChannel4
		end
		context:addOption(SandboxVars.TrueMusicRadio.TMRChannel4/1000 .. "FM: " .. TMRadio.translation.update,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "UpdateD",
				  nil)
		context:addOption(SandboxVars.TrueMusicRadio.TMRChannel4/1000 .. "FM: " .. TMRadio.translation.revert,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "RevertD",
				  nil)
	elseif (X == 4832 and Y == 6279 and Z == 0) or Terminal:getModData()['StationControl'] == SandboxVars.TrueMusicRadio.TMRChannel5 then
		if Terminal:getModData()['StationControl'] == 0 then
			Terminal:getModData()['StationControl'] = SandboxVars.TrueMusicRadio.TMRChannel5
		end
		context:addOption(SandboxVars.TrueMusicRadio.TMRChannel5/1000 .. "FM: " .. TMRadio.translation.update,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "UpdateE",
				  nil)
		context:addOption(SandboxVars.TrueMusicRadio.TMRChannel5/1000 .. "FM: " .. TMRadio.translation.revert,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "RevertE",
				  nil)
	elseif Terminal:getModData()['StationControl'] == SandboxVars.TrueMusicRadio.TMRMTV then
		context:addOption(SandboxVars.TrueMusicRadio.TMRMTV .. "TV: " .. TMRadio.translation.update,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "UpdateMTV",
				  nil)
		context:addOption(SandboxVars.TrueMusicRadio.TMRMTV .. "TV: " .. TMRadio.translation.revert,
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "RevertMTV",
				  nil)
	end

	if PZAPI.ModOptions:getOptions("TrueMusicRadio"):getOption("TMRterminalEject"):getValue() and Terminal:getModData()['LoadedCapacity'] > 0 and Terminal:getModData()['StationControl'] ~= 0 then
		local contextMenu2 = context:addOption(TMRadio.translation.ejectmedia)
		local subContext2 = ISContextMenu:getNew(context)
		context:addSubMenu(contextMenu2, subContext2)

		local tempGlobalPlaylist = {}
		for k,v in pairs(GlobalMusic) do
			tempGlobalPlaylist[#tempGlobalPlaylist + 1] = "Tsarcraft." .. k
		end

		for k,v in pairs(tempGlobalPlaylist) do
			subContext2:addOption(getItemNameFromFullType(v),
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "Eject",
				  v)
		end
	elseif Terminal:getModData()['LoadedCapacity'] > 0 and Terminal:getModData()['StationControl'] ~= 0 then
		local contextMenu2 = context:addOption(TMRadio.translation.ejectmedia .. " (reactivate in mod options)")
	elseif Terminal:getModData()['StationControl'] ~= 0 then
		local contextMenu2 = context:addOption(TMRadio.translation.ejectmedia .. " (Empty)")
	end

	if (getCore():getDebug() or isAdmin()) then
		local contextMenu = nil
		local subContext = nil

		contextMenu = context:addOption("TMRadio Admin Menu")
		subContext = ISContextMenu:getNew(context)
		context:addSubMenu(contextMenu, subContext)

		subContext:addOption("Disconnect Terminal",
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "Disconnect",
				  nil)
		subContext:addOption("Set Terminal To " .. SandboxVars.TrueMusicRadio.TMRChannel1/1000 .. "FM",
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "SetTerminalA",
				  nil)
		subContext:addOption("Set Terminal To " .. SandboxVars.TrueMusicRadio.TMRChannel2/1000 .. "FM",
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "SetTerminalB",
				  nil)
		subContext:addOption("Set Terminal To " .. SandboxVars.TrueMusicRadio.TMRChannel3/1000 .. "FM",
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "SetTerminalC",
				  nil)
		subContext:addOption("Set Terminal To " .. SandboxVars.TrueMusicRadio.TMRChannel4/1000 .. "FM",
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "SetTerminalD",
				  nil)
		subContext:addOption("Set Terminal To " .. SandboxVars.TrueMusicRadio.TMRChannel5/1000 .. "FM",
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "SetTerminalE",
				  nil)
		if SandboxVars.TrueMusicRadio.ActivateTMRMTV then
			subContext:addOption("Set Terminal To " .. SandboxVars.TrueMusicRadio.TMRMTV .. "TV",
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "SetTerminalMTV",
				  nil)
		end
		subContext:addOption("Empty Terminal Media",
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "EmptyCapacity",
				  nil)
		subContext:addOption("Reset Terminal Media Capacity [Currently: " .. Terminal:getModData()['LoadedCapacity'] .. " of 111]",
				  worldobjects,
				  UseTerminalMenu.onUseTerminal,
				  getSpecificPlayer(player),
				  Terminal,
				  "ReloadCapacity",
				  nil)

		if PZAPI.ModOptions:getOptions("TrueMusicRadio"):getOption("TMRterminalBlacklist"):getValue() then
			local contextMenu3 = subContext:addOption("Globally Blacklist Song: ")
			local subContext3 = ISContextMenu:getNew(subContext)
			context:addSubMenu(contextMenu3, subContext3)

			local tempGlobalPlaylistBlacklist = {}
			for k,v in pairs(GlobalMusic) do
				tempGlobalPlaylistBlacklist[#tempGlobalPlaylistBlacklist + 1] = k
			end

			if SandboxVars.TrueMusicRadio.TMRExcludeThemeSongs then
				for k,v in pairs(TMRadio.BlacklistThemeSongs) do
					for index = #tempGlobalPlaylistBlacklist, 1, -1 do 
						value = tempGlobalPlaylistBlacklist[index]
						if value == v then 
							table.remove(tempGlobalPlaylistBlacklist, index)
							break
						end
					end
				end
			end
			if SandboxVars.TrueMusicRadio.TMRExcludeTCCacheMPSongs then
				for k,v in pairs(TMRadio.BlacklistTCCacheMPSongs) do
					for index = #tempGlobalPlaylistBlacklist, 1, -1 do 
						value = tempGlobalPlaylistBlacklist[index]
						if value == v then 
							table.remove(tempGlobalPlaylistBlacklist, index)
							break
						end
					end
				end
			end
			if SandboxVars.TrueMusicRadio.TMRExcludeHolidaySongs then
				for k,v in pairs(TMRadio.BlacklistHolidaySongs) do
					for index = #tempGlobalPlaylistBlacklist, 1, -1 do 
						value = tempGlobalPlaylistBlacklist[index]
						if value == v then 
							table.remove(tempGlobalPlaylistBlacklist, index)
							break
						end
					end
				end
			end
			if TMRadio.Blacklist ~= nil and #TMRadio.Blacklist > 0 then
				for k,v in pairs(TMRadio.Blacklist) do
					for index = #tempGlobalPlaylistBlacklist, 1, -1 do 
						value = tempGlobalPlaylistBlacklist[index]
						if value == v then 
							table.remove(tempGlobalPlaylistBlacklist, index)
							break
						end
					end
				end
			end

			for k,v in pairs(tempGlobalPlaylistBlacklist) do
				subContext3:addOption(getItemNameFromFullType("Tsarcraft." .. v),
				  	worldobjects,
				  	UseTerminalMenu.onUseTerminal,
				  	getSpecificPlayer(player),
				  	Terminal,
				  	"Blacklist",
				  	v)
			end

			local contextMenu4 = subContext:addOption("Remove Globally Blacklisted Song: ")
			local subContext4 = ISContextMenu:getNew(subContext)
			context:addSubMenu(contextMenu4, subContext4)

			if TMRadio.Blacklist ~= nil and #TMRadio.Blacklist > 0 then
				local tempBlacklist = {}
				for k,v in pairs(TMRadio.Blacklist) do
					if v ~= "Test" then
						tempBlacklist[#tempBlacklist + 1] = v
					end
				end

				for k,v in pairs(tempBlacklist) do
					subContext4:addOption(getItemNameFromFullType("Tsarcraft." .. v),
					  	worldobjects,
					  	UseTerminalMenu.onUseTerminal,
					  	getSpecificPlayer(player),
				  		Terminal,
				  		"RemoveBlacklist",
				  		v)
				end
			end
		else
			local contextMenu3 = subContext:addOption("Globally Blacklist Song: (reactivate in mod options)")
			local contextMenu4 = subContext:addOption("Remove Globally Blacklisted Song: (reactivate in mod options)")
		end
	end
end

UseTerminalMenu.getFrontSquare = function(square, facing)
	local value = nil
	
	if facing == "S" then
		value = square:getS()
	elseif facing == "E" then
		value = square:getE()
	elseif facing == "W" then
		value = square:getW()
	elseif facing == "N" then
		value = square:getN()
	end
	
	return value
end

UseTerminalMenu.getFacing = function(properties, square)

	local facing = nil

	if properties:has("Facing") then
		facing = properties:get("Facing")
	end

	if square:getE() and facing == "E" then
		facing = "E"
	elseif square:getS() and facing == "S" then
		facing = "S" 
	elseif square:getW() and facing == "W" then
		facing = "W"
	elseif square:getN() and facing == "N" then
		facing = "N"
	else 
		facing = nil
	end

	return facing
end

UseTerminalMenu.walkToFront = function(thisPlayer, Terminal)
	local spriteName = Terminal:getSprite():getName()
	if not spriteName then
		return false
	end

	local properties = Terminal:getSprite():getProperties()
	local facing = UseTerminalMenu.getFacing(properties, Terminal:getSquare())
	if facing == nil then
		thisPlayer:Say(TMRadio.translation.sayaccessblocked)
		return false
	end
	
	local frontSquare = UseTerminalMenu.getFrontSquare(Terminal:getSquare(), facing)
	local turn = UseTerminalMenu.getFrontSquare(frontSquare, facing)
	
	if not frontSquare then
		return false
	end

	local terminalSquare = Terminal:getSquare()

	if AdjacentFreeTileFinder.privTrySquare(terminalSquare, frontSquare) then
		ISTimedActionQueue.add(ISWalkToTimedAction:new(thisPlayer, frontSquare))
		if turn then
			thisPlayer:faceLocation(terminalSquare:getX(), terminalSquare:getY())
		end
		return true
	end

	return false
end

UseTerminalMenu.onUseTerminal = function(worldobjects, player, terminal, MyChoice, music)
	if (not UseTerminalMenu.walkToFront(player, terminal) and terminal:getContainer()) then 
		return 
	end

	local square = terminal:getSquare()

	if not ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or (SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier and square:isOutside() == false)) then
		player:Say(TMRadio.translation.sayneedsgenerator)
		return
	end

	if MyChoice == "RevertA" then
		square:playSound("LightSwitch")
		TMRadio.PlaylistTerminalA = TMRadio.CreatePlaylist()
		if isClient() then
			sendClientCommand("TMRadio", "UpdatePlaylistTerminalA", TMRadio.PlaylistTerminalA)
		end
		ModData.add("TMRadioA", TMRadio.PlaylistTerminalA)
		--ModData.transmit("TMRadioA", TMRadio.PlaylistTerminalA)
		local songNumber = ZombRand(1, #TMRadio.PlaylistTerminalA+1)
		if isClient() then
			local args = {x = terminal:getX(), y = terminal:getY(), z = terminal:getZ(), channel = SandboxVars.TrueMusicRadio.TMRChannel1, number = songNumber}	
			sendClientCommand("TMRadio", "PlayNext", args)
		else
			TMRadio.UpdateSoundCache(songNumber, SandboxVars.TrueMusicRadio.TMRChannel1)
		end
	elseif MyChoice == "RevertB" then
		square:playSound("LightSwitch")
		TMRadio.PlaylistTerminalB = TMRadio.CreatePlaylist()
		if isClient() then
			sendClientCommand("TMRadio", "UpdatePlaylistTerminalB", TMRadio.PlaylistTerminalB)
		end
		ModData.add("TMRadioB", TMRadio.PlaylistTerminalB)
		--ModData.transmit("TMRadioB", TMRadio.PlaylistTerminalB)	
		local songNumber = ZombRand(1, #TMRadio.PlaylistTerminalB+1)
		if isClient() then
			local args = {x = terminal:getX(), y = terminal:getY(), z = terminal:getZ(), channel = SandboxVars.TrueMusicRadio.TMRChannel2, number = songNumber}	
			sendClientCommand("TMRadio", "PlayNext", args)
		else
			TMRadio.UpdateSoundCache(songNumber, SandboxVars.TrueMusicRadio.TMRChannel2)
		end
	elseif MyChoice == "RevertC" then
		square:playSound("LightSwitch")
		TMRadio.PlaylistTerminalC = TMRadio.CreatePlaylist()
		if isClient() then
			sendClientCommand("TMRadio", "UpdatePlaylistTerminalC", TMRadio.PlaylistTerminalC)
		end
		ModData.add("TMRadioC", TMRadio.PlaylistTerminalC)
		--ModData.transmit("TMRadioC", TMRadio.PlaylistTerminalC)	
		local songNumber = ZombRand(1, #TMRadio.PlaylistTerminalC+1)
		if isClient() then
			local args = {x = terminal:getX(), y = terminal:getY(), z = terminal:getZ(), channel = SandboxVars.TrueMusicRadio.TMRChannel3, number = songNumber}	
			sendClientCommand("TMRadio", "PlayNext", args)
		else
			TMRadio.UpdateSoundCache(songNumber, SandboxVars.TrueMusicRadio.TMRChannel3)
		end
	elseif MyChoice == "RevertD" then
		square:playSound("LightSwitch")
		TMRadio.PlaylistTerminalD = TMRadio.CreatePlaylist()
		if isClient() then
			sendClientCommand("TMRadio", "UpdatePlaylistTerminalD", TMRadio.PlaylistTerminalD)
		end
		ModData.add("TMRadioD", TMRadio.PlaylistTerminalD)
		--ModData.transmit("TMRadioD", TMRadio.PlaylistTerminalD)	
		local songNumber = ZombRand(1, #TMRadio.PlaylistTerminalD+1)
		if isClient() then
			local args = {x = terminal:getX(), y = terminal:getY(), z = terminal:getZ(), channel = SandboxVars.TrueMusicRadio.TMRChannel4, number = songNumber}	
			sendClientCommand("TMRadio", "PlayNext", args)
		else
			TMRadio.UpdateSoundCache(songNumber, SandboxVars.TrueMusicRadio.TMRChannel4)
		end
	elseif MyChoice == "RevertE" then
		square:playSound("LightSwitch")
		TMRadio.PlaylistTerminalE = TMRadio.CreatePlaylist()
		if isClient() then
			sendClientCommand("TMRadio", "UpdatePlaylistTerminalE", TMRadio.PlaylistTerminalE)
		end
		ModData.add("TMRadioE", TMRadio.PlaylistTerminalE)
		--ModData.transmit("TMRadioE", TMRadio.PlaylistTerminalE)	
		local songNumber = ZombRand(1, #TMRadio.PlaylistTerminalE+1)
		if isClient() then
			local args = {x = terminal:getX(), y = terminal:getY(), z = terminal:getZ(), channel = SandboxVars.TrueMusicRadio.TMRChannel5, number = songNumber}	
			sendClientCommand("TMRadio", "PlayNext", args)
		else
			TMRadio.UpdateSoundCache(songNumber, SandboxVars.TrueMusicRadio.TMRChannel5)
		end
	elseif MyChoice == "RevertMTV" then
		square:playSound("LightSwitch")
		TMRadio.PlaylistTerminalMTV = TMRadio.CreatePlaylist()
		if isClient() then
			sendClientCommand("TMRadio", "UpdatePlaylistTerminalMTV", TMRadio.PlaylistTerminalMTV)
		end
		ModData.add("TMRadioMTV", TMRadio.PlaylistTerminalMTV)
		--ModData.transmit("TMRadioMTV", TMRadio.PlaylistTerminalMTV)	
		local songNumber = ZombRand(1, #TMRadio.PlaylistTerminalMTV+1)
		if isClient() then
			local args = {x = terminal:getX(), y = terminal:getY(), z = terminal:getZ(), channel = SandboxVars.TrueMusicRadio.TMRMTV, number = songNumber}	
			sendClientCommand("TMRadio", "PlayNext", args)
		else
			TMRadio.UpdateSoundCache(songNumber, SandboxVars.TrueMusicRadio.TMRMTV)
		end
	elseif MyChoice == "UpdateA" or MyChoice == "UpdateB" or MyChoice == "UpdateC" or MyChoice == "UpdateD" or MyChoice == "UpdateE" or MyChoice == "UpdateMTV" then
		square:playSound("LightSwitch")
		local terminalItems = nil

		if terminal:getContainer() then
			terminalItems = terminal:getItemContainer():getItems()
		end

		if terminalItems:size() == 0 then
			player:Say("There are no items in this terminal.")
			return
		end

		if MyChoice == "UpdateA" then
			TMRadio.PlaylistTerminalA = {}
			for i=0, terminalItems:size()-1 do
				local item = terminalItems:get(i)
				TMRadio.PlaylistTerminalA[#TMRadio.PlaylistTerminalA + 1] = item:getType()
			end
			ModData.add("TMRadioA", TMRadio.PlaylistTerminalA)
			local songNumber = ZombRand(1, #TMRadio.PlaylistTerminalA+1)
			if isClient() then
				--ModData.transmit("TMRadioA", TMRadio.PlaylistTerminalA)
				sendClientCommand("TMRadio", "UpdatePlaylistTerminalA", TMRadio.PlaylistTerminalA)
				local args = {x = terminal:getX(), y = terminal:getY(), z = terminal:getZ(), channel = SandboxVars.TrueMusicRadio.TMRChannel1, number = songNumber}	
				sendClientCommand("TMRadio", "PlayNext", args)
				print("TMRadio Client: Transmitting A to server")
			else
				TMRadio.UpdateSoundCache(songNumber, SandboxVars.TrueMusicRadio.TMRChannel1)
			end
		elseif MyChoice == "UpdateB" then
			TMRadio.PlaylistTerminalB = {}
			for i=0, terminalItems:size()-1 do
				local item = terminalItems:get(i)
				TMRadio.PlaylistTerminalB[#TMRadio.PlaylistTerminalB + 1] = item:getType()
			end
			ModData.add("TMRadioB", TMRadio.PlaylistTerminalB)
			local songNumber = ZombRand(1, #TMRadio.PlaylistTerminalB+1)
			if isClient() then
				--ModData.transmit("TMRadioB", TMRadio.PlaylistTerminalB)
				sendClientCommand("TMRadio", "UpdatePlaylistTerminalB", TMRadio.PlaylistTerminalB)
				local args = {x = terminal:getX(), y = terminal:getY(), z = terminal:getZ(), channel = SandboxVars.TrueMusicRadio.TMRChannel2, number = songNumber}	
				sendClientCommand("TMRadio", "PlayNext", args)
				print("TMRadio Client: Transmitting B to server")
			else
				TMRadio.UpdateSoundCache(songNumber, SandboxVars.TrueMusicRadio.TMRChannel2)
			end
		elseif MyChoice == "UpdateC" then
			TMRadio.PlaylistTerminalC = {}
			for i=0, terminalItems:size()-1 do
				local item = terminalItems:get(i)
				TMRadio.PlaylistTerminalC[#TMRadio.PlaylistTerminalC + 1] = item:getType()
			end
			ModData.add("TMRadioC", TMRadio.PlaylistTerminalC)
			local songNumber = ZombRand(1, #TMRadio.PlaylistTerminalC+1)
			if isClient() then
				--ModData.transmit("TMRadioC", TMRadio.PlaylistTerminalC)
				sendClientCommand("TMRadio", "UpdatePlaylistTerminalC", TMRadio.PlaylistTerminalC)
				local args = {x = terminal:getX(), y = terminal:getY(), z = terminal:getZ(), channel = SandboxVars.TrueMusicRadio.TMRChannel3, number = songNumber}	
				sendClientCommand("TMRadio", "PlayNext", args)
				print("TMRadio Client: Transmitting C to server")
			else
				TMRadio.UpdateSoundCache(songNumber, SandboxVars.TrueMusicRadio.TMRChannel3)
			end
		elseif MyChoice == "UpdateD" then
			TMRadio.PlaylistTerminalD = {}
			for i=0, terminalItems:size()-1 do
				local item = terminalItems:get(i)
				TMRadio.PlaylistTerminalD[#TMRadio.PlaylistTerminalD + 1] = item:getType()
			end
			ModData.add("TMRadioD", TMRadio.PlaylistTerminalD)
			local songNumber = ZombRand(1, #TMRadio.PlaylistTerminalD+1)
			if isClient() then
				--ModData.transmit("TMRadioD", TMRadio.PlaylistTerminalD)
				sendClientCommand("TMRadio", "UpdatePlaylistTerminalD", TMRadio.PlaylistTerminalD)
				local args = {x = terminal:getX(), y = terminal:getY(), z = terminal:getZ(), channel = SandboxVars.TrueMusicRadio.TMRChannel4, number = songNumber}	
				sendClientCommand("TMRadio", "PlayNext", args)
				print("TMRadio Client: Transmitting D to server")
			else
				TMRadio.UpdateSoundCache(songNumber, SandboxVars.TrueMusicRadio.TMRChannel4)
			end
		elseif MyChoice == "UpdateE" then
			TMRadio.PlaylistTerminalE = {}
			for i=0, terminalItems:size()-1 do
				local item = terminalItems:get(i)
				TMRadio.PlaylistTerminalE[#TMRadio.PlaylistTerminalE + 1] = item:getType()
			end
			ModData.add("TMRadioE", TMRadio.PlaylistTerminalE)
			local songNumber = ZombRand(1, #TMRadio.PlaylistTerminalE+1)
			if isClient() then
				--ModData.transmit("TMRadioE", TMRadio.PlaylistTerminalE)
				sendClientCommand("TMRadio", "UpdatePlaylistTerminalE", TMRadio.PlaylistTerminalE)
				local args = {x = terminal:getX(), y = terminal:getY(), z = terminal:getZ(), channel = SandboxVars.TrueMusicRadio.TMRChannel5, number = songNumber}	
				sendClientCommand("TMRadio", "PlayNext", args)
				print("TMRadio Client: Transmitting E to server")
			else
				TMRadio.UpdateSoundCache(songNumber, SandboxVars.TrueMusicRadio.TMRChannel5)
			end
		elseif MyChoice == "UpdateMTV" then
			TMRadio.PlaylistTerminalMTV = {}
			for i=0, terminalItems:size()-1 do
				local item = terminalItems:get(i)
				TMRadio.PlaylistTerminalMTV[#TMRadio.PlaylistTerminalMTV + 1] = item:getType()
			end
			ModData.add("TMRadioMTV", TMRadio.PlaylistTerminalMTV)
			local songNumber = ZombRand(1, #TMRadio.PlaylistTerminalMTV+1)
			if isClient() then
				--ModData.transmit("TMRadioMTV", TMRadio.PlaylistTerminalMTV)
				sendClientCommand("TMRadio", "UpdatePlaylistTerminalMTV", TMRadio.PlaylistTerminalMTV)
				local args = {x = terminal:getX(), y = terminal:getY(), z = terminal:getZ(), channel = SandboxVars.TrueMusicRadio.TMRMTV, number = songNumber}	
				sendClientCommand("TMRadio", "PlayNext", args)
				print("TMRadio Client: Transmitting MTV to server")
			else
				TMRadio.UpdateSoundCache(songNumber, SandboxVars.TrueMusicRadio.TMRMTV)
			end
		end
	elseif MyChoice == "Disconnect" then
		terminal:getModData()['StationControl'] = 0
		terminal:transmitModData()
	elseif MyChoice == "SetTerminalA" then
		terminal:getModData()['StationControl'] = SandboxVars.TrueMusicRadio.TMRChannel1
		terminal:transmitModData()
	elseif MyChoice == "SetTerminalB" then
		terminal:getModData()['StationControl'] = SandboxVars.TrueMusicRadio.TMRChannel2
		terminal:transmitModData()
	elseif MyChoice == "SetTerminalC" then
		terminal:getModData()['StationControl'] = SandboxVars.TrueMusicRadio.TMRChannel3
		terminal:transmitModData()
	elseif MyChoice == "SetTerminalD" then
		terminal:getModData()['StationControl'] = SandboxVars.TrueMusicRadio.TMRChannel4
		terminal:transmitModData()
	elseif MyChoice == "SetTerminalE" then
		terminal:getModData()['StationControl'] = SandboxVars.TrueMusicRadio.TMRChannel5
		terminal:transmitModData()
	elseif MyChoice == "SetTerminalMTV" then
		terminal:getModData()['StationControl'] = SandboxVars.TrueMusicRadio.TMRMTV
		terminal:transmitModData()
	elseif MyChoice == "ReloadCapacity" then
		terminal:getModData()['LoadedCapacity'] = 111
		terminal:transmitModData()
	elseif MyChoice == "EmptyCapacity" then
		terminal:getModData()['LoadedCapacity'] = 0
		terminal:transmitModData()
	elseif MyChoice == "Eject" then
		terminal:getModData()['LoadedCapacity'] = terminal:getModData()['LoadedCapacity'] - 1
		terminal:transmitModData()
		square:playSound("TCBoombox_stop")
		if isClient() then
			sendClientCommand("TMRadio", "EjectMedia", {media = music})
		else
			player:getInventory():AddItem(music)
		end
	elseif MyChoice == "Blacklist" then
		local found = false
		if TMRadio.Blacklist ~= nil and #TMRadio.Blacklist > 0 then
			for index = #TMRadio.Blacklist, 1, -1 do 
				value = TMRadio.Blacklist[index]
				if value == music then
					found = true
				end
			end
    		end 
		if found == false then
			if TMRadio.Blacklist == nil then
				TMRadio.Blacklist = { "Test" }
			end
    			table.insert(TMRadio.Blacklist, 1, music)
		end
		ModData.add("TMRadioBlacklist", TMRadio.Blacklist)
		if isClient() then
			--ModData.transmit("TMRadioBlacklist", TMRadio.Blacklist)
			sendClientCommand("TMRadio", "UpdateBlacklist", TMRadio.Blacklist)
			print("TMRadio Client: Transmitting blacklist to server")
		end
	elseif MyChoice == "RemoveBlacklist" then
		if TMRadio.Blacklist ~= nil and #TMRadio.Blacklist > 0 then
			for index = #TMRadio.Blacklist, 1, -1 do 
				value = TMRadio.Blacklist[index]
				if value == music then
					table.remove(TMRadio.Blacklist, index)
				end
			end
    		end 
		ModData.add("TMRadioBlacklist", TMRadio.Blacklist)
		if isClient() then
			--ModData.transmit("TMRadioBlacklist", TMRadio.Blacklist)
			sendClientCommand("TMRadio", "UpdateBlacklist", TMRadio.Blacklist)
			print("TMRadio Client: Transmitting blacklist to server")
		end
	end
end

Events.OnPreFillWorldObjectContextMenu.Add(UseTerminalMenu.doBuildMenu)