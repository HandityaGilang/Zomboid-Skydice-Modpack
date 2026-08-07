TMRadioClient = {}

TMRadioClient.PlaylistTerminalA = {}
TMRadioClient.PlaylistTerminalB = {}
TMRadioClient.PlaylistTerminalC = {}
TMRadioClient.PlaylistTerminalD = {}
TMRadioClient.PlaylistTerminalE = {}
TMRadioClient.PlaylistTerminalMTV = {}

TMRadioClient.Channels = {}

TMRadioClient.Blacklist = {}

TMRadioClient.FindRadio = function(args)
	if not args then
		return
	end

    	local radio = nil
	local square = getSquare(args.x, args.y, args.z)
    
    	-- Radio Device: Portable/HAM radio or vehicle radio
	if square then
        	for i = 0, square:getObjects():size()-1 do
        		local item = square:getObjects():get(i)

            		-- Portable/HAM radio or television
            		--if instanceof(item, "IsoRadio") and item:getDeviceData() ~= nil then
 			if (instanceof(item, "IsoRadio") or instanceof(item, "IsoTelevision")) and item:getDeviceData() ~= nil then
                		radio = item
                		break
            		end

            		-- Vehicle radio
            		if instanceof(item, "IsoObject") then
               			local vehicle = square:getVehicleContainer()
                		if vehicle then
                    			local part = vehicle:getPartById("Radio");
                    			if part and part:getDeviceData() then
                      				radio = part
                      				break
                    			end
                		end
			end
            	end
        end

	return radio
end

TMRadioClient.Stop = function(args)
	if not args then
		return
	end

	print("TMRadio Client: Received stop command at " .. args.x .. " " .. args.y .. " " .. args.z)

	if #TMRadio.soundCache > 0 then
		for index = #TMRadio.soundCache, 1, -1 do 
			t = TMRadio.soundCache[index]  
			if t.x == args.x and t.y == args.y and t.z == args.z then
				t.sound:setVolume(0)
				t.muted = true
                		TMRadio.updateVolume(t)
				t.sound:stop()
				table.remove(TMRadio.soundCache, index)
			end
		end
	end
end

TMRadioClient.Play = function(args)
	if not args then
		return
	end

	TMRadio.Channels[args.channel] = args.number

	print("TMRadio Client: Received play command")

	local radio = nil

	if #TMRadio.soundCache > 0 then
		for _,t in ipairs(TMRadio.soundCache) do
			if t.x == args.x and t.y == args.y and t.z == args.z then
				radio = t.device
			end
		end	
	end	

	if radio == nil then
		radio = TMRadioClient.FindRadio(args)
	end

	if radio == nil then
		return
	end

	print("TMRadio Client: Play " .. args.number)
	TMRadio.PlaySound(args.number, radio)
end

TMRadioClient.PlayNext = function(args)
	if not args then
		return
	end

	TMRadio.Channels[args.channel] = args.number

	print("TMRadio Client: Received playnext command")

	if #TMRadio.soundCache > 0 then
		--print("TMRadio Client: Soundcache updating channel: " .. args.channel)
		TMRadio.UpdateSoundCache(args.number, args.channel)
	end

	local radio = nil

	if #TMRadio.soundCache > 0 then
		for _,t in ipairs(TMRadio.soundCache) do
			if t.x == args.x and t.y == args.y and t.z == args.z then
				radio = t.device
			end
		end	
	end	

	if radio == nil then
		radio = TMRadioClient.FindRadio(args)
	end

	if radio == nil then
		return
	end

	--print("TMRadio Client: Playnext on new radio: " .. args.number)
	TMRadio.PlaySound(args.number, radio)
end

TMRadioClient.UpdatePlaylistTerminalA = function(args)
	print("TMRadio Client: getting update for A")
	TMRadioClient.PlaylistTerminalA = args
	ModData.add("TMRadioA", TMRadioClient.PlaylistTerminalA)
end

TMRadioClient.UpdatePlaylistTerminalB = function(args)
	print("TMRadio Client: getting update for B")
	TMRadioClient.PlaylistTerminalB = args
	ModData.add("TMRadioB", TMRadioClient.PlaylistTerminalB)
end

TMRadioClient.UpdatePlaylistTerminalC = function(args)
	print("TMRadio Client: getting update for C")
	TMRadioClient.PlaylistTerminalC = args
	ModData.add("TMRadioC", TMRadioClient.PlaylistTerminalC)
end

TMRadioClient.UpdatePlaylistTerminalD = function(args)
	print("TMRadio Client: getting update for D")
	TMRadioClient.PlaylistTerminalD = args
	ModData.add("TMRadioD", TMRadioClient.PlaylistTerminalD)
end

TMRadioClient.UpdatePlaylistTerminalE = function(args)
	print("TMRadio Client: getting update for E")
	TMRadioClient.PlaylistTerminalE = args
	ModData.add("TMRadioE", TMRadioClient.PlaylistTerminalE)
end

TMRadioClient.UpdatePlaylistTerminalMTV = function(args)
	print("TMRadio Client: getting update for MTV")
	TMRadioClient.PlaylistTerminalMTV = args
	ModData.add("TMRadioMTV", TMRadioClient.PlaylistTerminalMTV)
end

TMRadioClient.UpdateChannels = function(args)
	print("TMRadio Client: getting update for channels")
	TMRadioClient.Channels = args
	TMRadio.Channels = args
	ModData.add("TMRadioChannels", TMRadioClient.Channels)
end

TMRadioClient.UpdateBlacklist = function(args)
	print("TMRadio Client: getting update for the blacklist")
	TMRadioClient.Blacklist = args
	TMRadio.Blacklist= args
	ModData.add("TMRadioBlacklist", TMRadioClient.Blacklist)
end

TMRadioClient.OnServerCommand = function(module, command, args)
    	if not (module == "TMRadio" and TMRadioClient[command]) then
		return
	end
	--print("TMRadio Client: Getting a " .. command .. " from the server")
        TMRadioClient[command](args)
end

Events.OnServerCommand.Add(TMRadioClient.OnServerCommand)

TMRadioClient.OnReceiveGlobalModDataClient = function(module, args)
	if not args then
		return
	end
	
    	if module == "TMRadioA" then
		TMRadioClient.PlaylistTerminalA = args
		TMRadio.PlaylistTerminalA = args
		ModData.add("TMRadioA", TMRadioClient.PlaylistTerminalA)
	elseif module == "TMRadioB" then
		TMRadioClient.PlaylistTerminalB = args
		TMRadio.PlaylistTerminalB = args
		ModData.add("TMRadioB", TMRadioClient.PlaylistTerminalB)
	elseif module == "TMRadioC" then
		TMRadioClient.PlaylistTerminalC = args
		TMRadio.PlaylistTerminalC = args
		ModData.add("TMRadioC", TMRadioClient.PlaylistTerminalC)
	elseif module == "TMRadioD" then
		TMRadioClient.PlaylistTerminalD = args
		TMRadio.PlaylistTerminalD = args
		ModData.add("TMRadioD", TMRadioClient.PlaylistTerminalD)
	elseif module == "TMRadioE" then
		TMRadioClient.PlaylistTerminalE = args
		TMRadio.PlaylistTerminalE = args
		ModData.add("TMRadioE", TMRadioClient.PlaylistTerminalE)
	elseif module == "TMRadioMTV" then
		TMRadioClient.PlaylistTerminalMTV = args
		TMRadio.PlaylistTerminalMTV = args
		ModData.add("TMRadioMTV", TMRadioClient.PlaylistTerminalMTV)
	elseif module == "TMRadioBlacklist" then
		TMRadioClient.Blacklist = args
		TMRadio.Blacklist = args
		ModData.add("TMRadioBlacklist", TMRadioClient.Blacklist)
	end
end

Events.OnReceiveGlobalModData.Add(TMRadioClient.OnReceiveGlobalModDataClient)

TMRadioClient.UpdatePlaylistFromServer = function()
	print("TMRadio Client: Sending request for terminal playlist from the server")
	sendClientCommand("TMRadio", "UpdatePlaylistTerminalA", {request = true})
	sendClientCommand("TMRadio", "UpdatePlaylistTerminalB", {request = true})
	sendClientCommand("TMRadio", "UpdatePlaylistTerminalC", {request = true})
	sendClientCommand("TMRadio", "UpdatePlaylistTerminalD", {request = true})
	sendClientCommand("TMRadio", "UpdatePlaylistTerminalE", {request = true})
	sendClientCommand("TMRadio", "UpdatePlaylistTerminalMTV", {request = true})
	sendClientCommand("TMRadio", "UpdateChannels", {request = true})
	sendClientCommand("TMRadio", "UpdateBlacklist", {request = true})
end

return TMRadioClient