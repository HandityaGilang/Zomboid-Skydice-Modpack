FASodaFountain = FASodaFountain or {}

FASodaFountain.doBuildMenu = function(player, menu, square, SodaFountain)
	local foundCO2 = nil
	local foundSyrup1 = nil
	local foundSyrup2 = nil
	local foundSyrup3 = nil
	local foundSyrup4 = nil
	local foundWaterJug = nil

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

				if itemType == "WaterDispenserBottle" and not foundWaterJug and not item:getFluidContainer():isEmpty() then
					foundWaterJug = item
				end

				if itemType == "FACO2Tank" or itemType == "FADIYCO2Tank" and not foundCO2 then
					foundCO2 = item
				end

				if (itemType == "FAMixedBerriesSodaSyrupBox" or itemType == "FALemonLimeSodaSyrupBox" or itemType == "FARootBeerSodaSyrupBox" or itemType == "FAKYColaSodaSyrupBox") or
					(itemType == "FAOrangeSodaSyrupBox" or itemType == "FAColaSodaSyrupBox" or itemType == "FADietColaSodaSyrupBox" or itemType == "FAGingerAleSodaSyrupBox") or
					(itemType == "FABlueberrySodaSyrupBox" or itemType == "FABubblegumSodaSyrupBox" or itemType == "FALimeSodaSyrupBox" or itemType == "FAGrapeSodaSyrupBox") or
					(itemType == "FAPineappleSodaSyrupBox" or itemType == "FAStrawberrySodaSyrupBox" or itemType == "FADrPeppaSodaSyrupBox" or itemType == "FAEmptySodaSyrupBox") then

					if not foundSyrup1 then
						foundSyrup1 = item
					elseif not foundSyrup2 then
						foundSyrup2 = item
					elseif not foundSyrup3 then
						foundSyrup3 = item
					elseif not foundSyrup4 then
						foundSyrup4 = item	
					end
				end
				
				if foundCO2 and foundSyrup4 and foundWaterJug then
					break
				end
			end
		end
		if foundCO2 and foundSyrup4 and foundWaterJug then
			break
		end
	end
	
	local facing = SodaFountain:getSprite():getProperties():Val("Facing")
	local rearSquare = FA.getRearSquare(square, facing)

	if (not foundCO2 or not foundSyrup4) and rearSquare then
		for index=1,rearSquare:getObjects():size() do
			local thisObject = rearSquare:getObjects():get(index-1)
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

					if itemType == "WaterDispenserBottle" and not foundWaterJug and not item:getFluidContainer():isEmpty() then
						foundWaterJug = item
					end

					if itemType == "FACO2Tank" or itemType == "FADIYCO2Tank" and not foundCO2 then
						foundCO2 = item
					end

					if (itemType == "FAMixedBerriesSodaSyrupBox" or itemType == "FALemonLimeSodaSyrupBox" or itemType == "FARootBeerSodaSyrupBox" or itemType == "FAKYColaSodaSyrupBox") or
						(itemType == "FAOrangeSodaSyrupBox" or itemType == "FAColaSodaSyrupBox" or itemType == "FADietColaSodaSyrupBox" or itemType == "FAGingerAleSodaSyrupBox") or
						(itemType == "FABlueberrySodaSyrupBox" or itemType == "FABubblegumSodaSyrupBox" or itemType == "FALimeSodaSyrupBox" or itemType == "FAGrapeSodaSyrupBox") or
						(itemType == "FAPineappleSodaSyrupBox" or itemType == "FAStrawberrySodaSyrupBox" or itemType == "FADrPeppaSodaSyrupBox" or itemType == "FAEmptySodaSyrupBox") then

						if not foundSyrup1 then
							foundSyrup1 = item
						elseif not foundSyrup2 then
							foundSyrup2 = item
						elseif not foundSyrup3 then
							foundSyrup3 = item
						elseif not foundSyrup4 then
							foundSyrup4 = item	
						end
					end
					
					if foundCO2 and foundSyrup4 and foundWaterJug then
						break
					end
				end
			end
			if foundCO2 and foundSyrup4 and foundWaterJug then
				break
			end
		end
	end

	if not foundCO2 and not foundSyrup1 and not foundWaterJug and SodaFountain:getFluidAmount() <= 0 then
		menu:addOptionOnTop(FA.translation.nosyrupboxesconnected)
		menu:addOptionOnTop(FA.translation.noco2tankconnected)
		menu:addOptionOnTop(FA.translation.nowaterconnected)
		return
	elseif not foundCO2 then
		menu:addOptionOnTop(FA.translation.noco2tankconnected)
		return 
	elseif not foundSyrup1 then 
		menu:addOptionOnTop(FA.translation.nosyrupboxesconnected)
		return 
	elseif not foundWaterJug and SodaFountain:getFluidAmount() <= 0 then 
		menu:addOptionOnTop(FA.translation.nowaterconnected)
		return 
	end

	local playerItems = getSpecificPlayer(player):getInventory():getItems()
	local soundFile = "sodafountain_sound"

	if foundSyrup1 then
		menu:addOption(FA.translation.dispensefrom)
		local contextMenu = menu:addOption("     " .. foundSyrup1:getDisplayName())
		local subContext = ISContextMenu:getNew(menu)
		menu:addSubMenu(contextMenu, subContext)

		if playerItems ~= nil then
			for i=0, playerItems:size()-1 do
        			local item = playerItems:get(i)
				if item:getFluidContainer() ~= nil and item:getFluidContainer():isEmpty() then
					subContext:addOption(item:getDisplayName(),
						nil,	
				  		FASodaFountain.onUseSodaFountain,
				  		getSpecificPlayer(player),
				  		SodaFountain,
				  		soundFile, item, foundSyrup1, foundCO2, foundWaterJug)
				end
			end
		end
	end
	if foundSyrup2 then
		local contextMenu = menu:addOption("     " .. foundSyrup2:getDisplayName())
		local subContext = ISContextMenu:getNew(menu)
		menu:addSubMenu(contextMenu, subContext)

		if playerItems ~= nil then
			for i=0, playerItems:size()-1 do
        			local item = playerItems:get(i)
				if item:getFluidContainer() ~= nil and item:getFluidContainer():isEmpty() then
					subContext:addOption(item:getDisplayName(),
						nil,	
				  		FASodaFountain.onUseSodaFountain,
				  		getSpecificPlayer(player),
				  		SodaFountain,
				  		soundFile, item, foundSyrup2, foundCO2, foundWaterJug)
				end
			end
		end
	end
	if foundSyrup3 then
		local contextMenu = menu:addOption("     " .. foundSyrup3:getDisplayName())
		local subContext = ISContextMenu:getNew(menu)
		menu:addSubMenu(contextMenu, subContext)

		if playerItems ~= nil then
			for i=0, playerItems:size()-1 do
        			local item = playerItems:get(i)
				if item:getFluidContainer() ~= nil and item:getFluidContainer():isEmpty() then
					subContext:addOption(item:getDisplayName(),
						nil,	
				  		FASodaFountain.onUseSodaFountain,
				  		getSpecificPlayer(player),
				  		SodaFountain,
				  		soundFile, item, foundSyrup3, foundCO2, foundWaterJug)
				end
			end
		end
	end
	if foundSyrup4 then
		local contextMenu = menu:addOption("     " .. foundSyrup4:getDisplayName())
		local subContext = ISContextMenu:getNew(menu)
		menu:addSubMenu(contextMenu, subContext)

		if playerItems ~= nil then
			for i=0, playerItems:size()-1 do
        			local item = playerItems:get(i)
				if item:getFluidContainer() ~= nil and item:getFluidContainer():isEmpty() then
					subContext:addOption(item:getDisplayName(),
						nil,	
				  		FASodaFountain.onUseSodaFountain,
				  		getSpecificPlayer(player),
				  		SodaFountain,
				  		soundFile, item, foundSyrup4, foundCO2, foundWaterJug)
				end
			end
		end
	end
end

FASodaFountain.onUseSodaFountain = function(junk, player, SodaFountain, soundFile, container, syrup, tank, jug)
	if not FA.walkToFront(player, SodaFountain) then
		return
	end

	local square = SodaFountain:getSquare()

	if not ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or (SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier and square:isOutside() == false)) then
		player:Say(FA.translation.sayneedagenerator)
		return
	end

	if square:isOutside() then
		player:Say(FA.translation.saysodafountainmustbeinside)
		return
	end

	ISTimedActionQueue.add(UseSodaFountain:new(player, SodaFountain, soundFile, container, syrup, tank, jug, squareToTurn))
end