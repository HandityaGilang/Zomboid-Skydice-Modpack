FA = FA or {}

FA.sodaMachines = {
	"location_shop_accessories_01_18",
	"location_shop_accessories_01_19",
	"location_shop_accessories_01_30",
	"location_shop_accessories_01_31"
}

FA.vendingMachines = {
	"location_shop_accessories_01_16",
	"location_shop_accessories_01_17",
	"location_shop_accessories_01_28",
	"location_shop_accessories_01_29"
}

FA.buffetCounters = {
	"location_restaurant_generic_01_16",
	"location_restaurant_generic_01_17",
	"location_restaurant_generic_01_18",
	"location_restaurant_generic_01_19",
	"location_restaurant_generic_01_20",
	"location_restaurant_generic_01_21",
	"location_restaurant_generic_01_22",
	"location_restaurant_generic_01_23"
}

FA.metalDisplayCounters = {
	"location_restaurant_generic_01_24",
	"location_restaurant_generic_01_25",
	"location_restaurant_generic_01_26",
	"location_restaurant_generic_01_27",
	"location_restaurant_generic_01_28",
	"location_restaurant_generic_01_29",
	"location_restaurant_generic_01_32",
	"location_restaurant_generic_01_33",
	"location_restaurant_generic_01_34",
	"location_restaurant_generic_01_35",
	"location_restaurant_generic_01_36",
	"location_restaurant_generic_01_37"
}

FA.roundedDisplayCounters = {
	"location_shop_generic_01_32",
	"location_shop_generic_01_33",
	"location_shop_generic_01_34",
	"location_shop_generic_01_35",
	"location_restaurant_pie_01_48",
	"location_restaurant_pie_01_49",
	"location_restaurant_pie_01_50",
	"location_restaurant_pie_01_51",
	"location_restaurant_seahorse_01_56",
	"location_restaurant_seahorse_01_57",
	"location_restaurant_seahorse_01_58",
	"location_restaurant_seahorse_01_59",
	"location_restaurant_pizzawhirled_01_64",
	"location_restaurant_pizzawhirled_01_65",
	"location_restaurant_pizzawhirled_01_66",
	"location_restaurant_pizzawhirled_01_67"
}

FA.loadMachineTemp = function(Machine)
	local square = Machine:getSquare()

	Machine:getModData()['Loaded'] = true
	if square:isOutside() == false then
		if square:getRoom() ~= nil then
			local roomName = square:getRoom():getName()
			if roomName == "icecreamkitchen" or roomName == "candystore" or roomName == "cafe" or roomName == "cafekitchen" or roomName == "bakery" or roomName == "gigamart" or roomName == "grocery" then
				Machine:getContainer():setCustomTemperature(0.25)
				Machine:getModData()['CustomTemp'] = "Cold" -- set to activate cold mode asap for ice cream shops
			else
				Machine:getContainer():setCustomTemperature(1.5)
				Machine:getModData()['CustomTemp'] = "Warm" -- else it's a warming coounter
			end
		end
	end

	if Machine:getSprite():getProperties():Val("CustomName") == "Machine" then
		if Machine:getSprite():getProperties():Val("GroupName") == "Small Soda" then
			Machine:getContainer():setCustomTemperature(0.25)
			Machine:getModData()['CustomTemp'] = "Cold" -- set to activate cold mode by default
		elseif Machine:getSprite():getProperties():Val("GroupName") == "Large" then
			Machine:getContainer():setCustomTemperature(1) -- room temp
			Machine:getModData()['CustomTemp'] = "Off"
		end
	end

	Machine = FA.updateMachineTemp(Machine)
	return Machine
end

FA.updateMachineTemp = function(Machine)
	local square = Machine:getSquare()

	Machine:getModData()['Loaded'] = true
	if Machine:getModData()['CustomTemp'] == "Warm" and ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or (SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier)) then
		Machine:getContainer():setCustomTemperature(1.5) 	-- just below cooking
		Machine:getModData()['CustomTemp'] = "Warm" 
	elseif Machine:getModData()['CustomTemp'] == "Hot" and ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or (SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier)) then
		Machine:getContainer():setCustomTemperature(1.61) 	-- just enough to start cooking
		Machine:getModData()['CustomTemp'] = "Hot" 
	elseif Machine:getModData()['CustomTemp'] == "Cold" and ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or (SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier)) then
		Machine:getContainer():setCustomTemperature(0.25) 	-- cold
		Machine:getModData()['CustomTemp'] = "Cold" 
	else
		Machine:getContainer():setCustomTemperature(1) -- room temp
		Machine:getModData()['CustomTemp'] = "Off"
	end

	Machine:getSquare():transmitModdata()
	Machine:transmitModData()
	Machine:getContainer():requestSync()

	return Machine
end

FA.newMachineTemp = function(Machine)
	if Machine:getModData()['Loaded'] ~= true then
		FA.loadMachineTemp(Machine)
	else
		FA.updateMachineTemp(Machine)
	end
end

MapObjects.OnLoadWithSprite(FA.vendingMachines, FA.newMachineTemp, 5)
MapObjects.OnLoadWithSprite(FA.sodaMachines, FA.newMachineTemp, 5)
MapObjects.OnLoadWithSprite(FA.buffetCounters, FA.newMachineTemp, 5)
MapObjects.OnLoadWithSprite(FA.metalDisplayCounters, FA.newMachineTemp, 5)
MapObjects.OnLoadWithSprite(FA.roundedDisplayCounters, FA.newMachineTemp, 5)

FA.exhaustVentList = {}

FA.exhaustVents = {
	"appliances_cooking_01_68",
	"appliances_cooking_01_69",
	"appliances_cooking_01_70",
	"appliances_cooking_01_71",
}

FA.updateExhaustVents = function(ExhaustVent)
	local foundExhaustVent = false
	if #FA.exhaustVentList > 0 then
		for index,x in ipairs(FA.exhaustVentList) do
			if x.x == ExhaustVent:getX() and x.y == ExhaustVent:getY() and x.z == ExhaustVent:getZ() then
				foundExhaustVent = true
				break
			end
		end
	end

	if not foundExhaustVent then
		local t = t or {}
		t.x = ExhaustVent:getX()
		t.y = ExhaustVent:getY()
		t.z = ExhaustVent:getZ()
		table.insert(FA.exhaustVentList, 1, t)
	end

	return ExhaustVent
end

MapObjects.OnLoadWithSprite(FA.exhaustVents, FA.updateExhaustVents, 5)

FA.checkExhaustVents = function()
	if #FA.exhaustVentList < 1 then
		return
	end

	local removedFromSquare = nil

	for index,t in ipairs(FA.exhaustVentList) do
		local square = getSquare(t.x, t.y, t.z)
		if square ~= nil then 
			if square:getBuilding() then
				local ExhaustVent = nil
				local objects = square:getObjects()

        			for i=1, objects:size()-1 do
        				local thisObject = objects:get(i)
					local texture = thisObject:getTextureName() or nil

              				if texture == "appliances_cooking_01_68" or texture == "appliances_cooking_01_69" or texture == "appliances_cooking_01_70" or texture == "appliances_cooking_01_71" then
						ExhaustVent = thisObject
						--print("found vent: " .. t.x .. "/" .. t.y .. "/" .. t.z)
						break
                			end
				end

				if ExhaustVent ~= nil then
					if (SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or (SandboxVars.ElecShutModifier > -1 and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier and square:isOutside() == false) then
						--print("has power")
						local otherObjects = square:getObjects()
						for i=1, otherObjects:size()-1 do
        						local otherObject = otherObjects:get(i)
					
							if instanceof(otherObject, "IsoGenerator") and otherObject:isActivated() then
								--print("found generator: " .. t.x .. "/" .. t.y .. "/" .. t.z)
								--print("removing toxicity")
								square:getBuilding():setToxic(false)
							end
						end
					end
				else
					removedFromSquare = square
				end
			else
				removedFromSquare = square
			end
		else
			removedFromSquare = square
		end
	end
	if #FA.exhaustVentList > 0 and removedFromSquare ~= nil then
		for index,x in ipairs(FA.exhaustVentList) do
			if x.x == removedFromSquare:getX() and x.y == removedFromSquare:getY() and x.z == removedFromSquare:getZ() then
				--print("removing vent: " .. x.x .. "/" .. x.y .. "/" .. x.z)
				table.remove(FA.exhaustVentList, index)
				break
			end
		end
	end
end

Events.EveryOneMinute.Add(FA.checkExhaustVents)