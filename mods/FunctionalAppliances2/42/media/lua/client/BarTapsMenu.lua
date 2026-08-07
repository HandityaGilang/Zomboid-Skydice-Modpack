FABarTaps = FABarTaps or {}

FABarTaps.doBuildMenu = function(player, menu, square, BarTaps)
	local foundKeg1 = nil
	local foundKeg2 = nil
	local foundKeg3 = nil
	local foundKeg4 = nil

	local texture = BarTaps:getTextureName() or nil
	if texture == "location_restaurant_bar_01_32" then
		local properties = BarTaps:getSprite():getProperties()
		properties:Set("Facing", "W")
	end

	for index=1,square:getObjects():size() do
		local thisObject = square:getObjects():get(index-1)
		local containerItems = nil
		
		if thisObject:getContainer() then
			containerItems = thisObject:getItemContainer():getItems()
		end

		if containerItems ~= nil then
			for i=0, containerItems:size()-1 do
        			local item = containerItems:get(i)
				local itemType = nil

				if item and item:getType() then
					itemType = item:getType()
				end

				if (itemType == "FABubKeg" or itemType == "FABubLiteKeg" or itemType == "FASwillerKeg" or itemType == "FASwillerLiteKeg" or itemType == "FAHomeBrewKeg") then
					if not foundKeg1 then
						foundKeg1 = item
					elseif not foundKeg2 then
						foundKeg2 = item
					elseif not foundKeg3 then
						foundKeg3 = item
					elseif not foundKeg4 then
						foundKeg4 = item
						break
					end
				end
			end
		end
		if foundKeg4 then
			break
		end
	end

	if not foundKeg1 then 
		return 
	end

	local playerItems = getSpecificPlayer(player):getInventory():getItems()
	local soundFile = "sodafountain_sound"

	if foundKeg1 then
		menu:addOption(FA.translation.dispensefrom)
		local contextMenu = menu:addOption("     " .. foundKeg1:getDisplayName())
		local subContext = ISContextMenu:getNew(menu)
		menu:addSubMenu(contextMenu, subContext)

		if playerItems ~= nil then
			for i=0, playerItems:size()-1 do
        			local item = playerItems:get(i)
				if item:getFluidContainer() ~= nil and item:getFluidContainer():isEmpty() then
					subContext:addOption(item:getDisplayName(),
				 		nil,	
				  		FABarTaps.onUseBarTaps,			
				  		getSpecificPlayer(player),
				  		BarTaps,
				  		soundFile, foundKeg1, item)
				end
			end
		end
	end
	if foundKeg2 then
		local contextMenu = menu:addOption("     " .. foundKeg2:getDisplayName())
		local subContext = ISContextMenu:getNew(menu)
		menu:addSubMenu(contextMenu, subContext)

		if playerItems ~= nil then
			for i=0, playerItems:size()-1 do
        			local item = playerItems:get(i)
				if item:getFluidContainer() ~= nil and item:getFluidContainer():isEmpty() then
					subContext:addOption(item:getDisplayName(),
				 		nil,	
				  		FABarTaps.onUseBarTaps,			
				  		getSpecificPlayer(player),
				  		BarTaps,
				  		soundFile, foundKeg2, item)
				end
			end
		end
	end
	if foundKeg3 then
		local contextMenu = menu:addOption("     " .. foundKeg3:getDisplayName())
		local subContext = ISContextMenu:getNew(menu)
		menu:addSubMenu(contextMenu, subContext)

		if playerItems ~= nil then
			for i=0, playerItems:size()-1 do
        			local item = playerItems:get(i)
				if item:getFluidContainer() ~= nil and item:getFluidContainer():isEmpty() then
					subContext:addOption(item:getDisplayName(),
				 		nil,	
				  		FABarTaps.onUseBarTaps,			
				  		getSpecificPlayer(player),
				  		BarTaps,
				  		soundFile, foundKeg3, item)
				end
			end
		end
	end
	if foundKeg4 then
		local contextMenu = menu:addOption("     " .. foundKeg4:getDisplayName())
		local subContext = ISContextMenu:getNew(menu)
		menu:addSubMenu(contextMenu, subContext)

		if playerItems ~= nil then
			for i=0, playerItems:size()-1 do
        			local item = playerItems:get(i)
				if item:getFluidContainer() ~= nil and item:getFluidContainer():isEmpty() then
					subContext:addOption(item:getDisplayName(),
				 		nil,	
				  		FABarTaps.onUseBarTaps,			
				  		getSpecificPlayer(player),
				  		BarTaps,
				  		soundFile, foundKeg4, item)
				end
			end
		end
	end
end

FABarTaps.onUseBarTaps = function(junk, player, BarTaps, soundFile, foundKeg, container)
	if not FA.walkToFront(player, BarTaps) then
		return
	end

	local square = BarTaps:getSquare()
		
	if not ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or (SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier and square:isOutside() == false)) then
		player:Say(FA.translation.sayneedagenerator)
		return
	end

	ISTimedActionQueue.add(UseBarTaps:new(player, BarTaps, soundFile, foundKeg, container, squareToTurn))
end