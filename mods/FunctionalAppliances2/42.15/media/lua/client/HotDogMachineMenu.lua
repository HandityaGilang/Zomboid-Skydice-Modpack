FAHotDogMachine = FAHotDogMachine or {}

FAHotDogMachine.doBuildMenu = function(player, menu, square, HotDogMachine)
	if ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or (SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier and square:isOutside() == false)) then
		HotDogMachine:getContainer():setCustomTemperature(1.5)
	else
		HotDogMachine:getContainer():setCustomTemperature(1)
	end

	HotDogMachine:getContainer():requestSync()

	local spriteName = HotDogMachine:getSprite():getName()
	local soundFile = "HotDogMachine_sound"
	menu:addOption(FA.translation.makehotdog,
				  nil,
				  FAHotDogMachine.onUseHotDogMachine,
				  getSpecificPlayer(player),
				  HotDogMachine,
				  soundFile, "Hotdog")

	local Sausage = nil
	local Wiener = nil
	local playerItems = getSpecificPlayer(player):getInventory():getItems()

	for i=0, playerItems:size()-1 do
        	local item = playerItems:get(i)
		local itemType = nil

		if item and item:getType() then
			itemType = item:getType()
		end

		if (itemType == "Sausage" or itemType == "SausageEvolved") and not item:isCooked() then
			Sausage = item
		elseif itemType == "Hotdog_single" and not item:isCooked() then
			Wiener = item
		end
	end


	local contextMenu2 = menu:addOption(FA.translation.cook)
	local subContext2 = ISContextMenu:getNew(menu)
	menu:addSubMenu(contextMenu2, subContext2)

	if Sausage then
		subContext2:addOption(FA.translation.sausage,
				  nil,	
				  FAHotDogMachine.onUseHotDogMachine,
				  getSpecificPlayer(player),
				  HotDogMachine,
				  soundFile, "Sausage")
	elseif Sausage == nil then
		subContext2:addOption(FA.translation.sausage,
				  nil,	
				  FAHotDogMachine.onUseHotDogMachine,
				  getSpecificPlayer(player),
				  HotDogMachine,
				  soundFile, "Not Found Sausage")
	end	
	if Wiener then
		subContext2:addOption(FA.translation.hotdogwiener,
				  nil,	
				  FAHotDogMachine.onUseHotDogMachine,
				  getSpecificPlayer(player),
				  HotDogMachine,
				  soundFile, "Wiener")
	elseif Wiener == nil then
		subContext2:addOption(FA.translation.hotdogwiener,
				  nil,	
				  FAHotDogMachine.onUseHotDogMachine,
				  getSpecificPlayer(player),
				  HotDogMachine,
				  soundFile, "Not Found Wiener")
	end
end

FAHotDogMachine.onUseHotDogMachine = function(junk, player, HotDogMachine, soundFile, foodType)
	if not FA.walkToFront(player, HotDogMachine) then
		return
	end

	local square = HotDogMachine:getSquare()

	if not ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or (SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier and square:isOutside() == false)) then
		player:Say(FA.translation.sayneedagenerator)
		return
	end

	if foodType == "Not Found Sausage" then
		player:Say(FA.translation.sayneedmissingingredients .. " " .. FA.translation.sausage)
		return
	elseif foodType == "Not Found Wiener" then
		player:Say(FA.translation.sayneedmissingingredients .. " " .. FA.translation.hotdogwiener)
		return
	end
	
	local inv = player:getInventory()
	local HotdogBun = inv:FindAndReturn("Base.BunsHotdog_single")
	local BreadSlices = inv:FindAndReturn("Base.BreadSlices")
	local Sausage = inv:FindAndReturn("Base.Sausage")
	local Wiener = inv:FindAndReturn("Base.Hotdog_single")

	if foodType == "Hotdog" and (HotdogBun or BreadSlices) and (Sausage or Wiener) then
		ISTimedActionQueue.add(UseHotDogMachine:new(player, HotDogMachine, soundFile, foodType, squareToTurn))
	elseif foodType == "Hotdog" and not HotdogBun and not BreadSlices and not Sausage and not Wiener then
		player:Say(FA.translation.sayneedmissingingredients .. " " .. FA.translation.hotdogbun .. " or " .. FA.translation.slicedbread .. " and " .. FA.translation.sausage .. " or " .. FA.translation.hotdogwiener)
	elseif foodType == "Hotdog" and not HotdogBun and not BreadSlices then
		player:Say(FA.translation.sayneedmissingingredients .. " " .. FA.translation.hotdogbun .. " or " .. FA.translation.slicedbread)
	elseif foodType == "Hotdog" then
		player:Say(FA.translation.sayneedmissingingredients .. " " .. FA.translation.sausage .. " or " .. FA.translation.hotdogwiener)
	else
		ISTimedActionQueue.add(UseHotDogMachine:new(player, HotDogMachine, soundFile, foodType, squareToTurn))
	end
end