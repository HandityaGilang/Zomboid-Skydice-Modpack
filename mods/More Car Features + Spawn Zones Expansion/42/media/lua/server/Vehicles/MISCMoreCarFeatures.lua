MoreCarFeatures = MoreCarFeatures or {}

function MoreCarFeatures.getVehicleDir(v)
	local y = v:getAngleY()
	if y < 0.00001 and y > 0 then
		y = 0.0001
	elseif y > -0.00001 and y < 0 then
		y = -0.0001
	end
	local angle = y - 90
	if math.abs(v:getAngleZ()) > 90 then  angle = 90 - y end
	return -angle*(math.pi/180)
end

local activatedMods = getActivatedMods()

if not isServer() then
	--Manages which vehicles can be entered/exited through the trunk by seeing if the code runs for it from the script
	MoreCarFeatures.canEnterExitVehicleTrunk = {}
	local VehiclesContainerAccessTruckBedOpenInside = Vehicles.ContainerAccess.TruckBedOpenInside
	function Vehicles.ContainerAccess.TruckBedOpenInside(vehicle, part, chr)
		local fullVName = vehicle:getScript():getFullName()
		if not MoreCarFeatures.canEnterExitVehicleTrunk[fullVName] then
			MoreCarFeatures.canEnterExitVehicleTrunk[fullVName] = true
		end

		return VehiclesContainerAccessTruckBedOpenInside(vehicle, part, chr)
	end

	MoreCarFeatures.canEnterExitVehicleTrunkKI51 = {}
	MoreCarFeatures.canEnterExitVehicleTrunkKI52 = {}
	MoreCarFeatures.canEnterExitVehicleTrunkKI53 = {}
	local function onInitGlobalModData()	--KI5 Versions / DAMNLIB
		if activatedMods:contains("damnlib") then	--3171167894
			local DAMNContainerAccessTrunkInner = DAMN.ContainerAccess.TrunkInner
			function DAMN.ContainerAccess.TrunkInner(vehicle, part, chr)
				local fullVName = vehicle:getScript():getFullName()
				if not MoreCarFeatures.canEnterExitVehicleTrunkKI51[fullVName] then
					MoreCarFeatures.canEnterExitVehicleTrunkKI51[fullVName] = true
				end

				return DAMNContainerAccessTrunkInner(vehicle, part, chr)
			end

			local DAMNContainerAccessTrunkSecondRow = DAMN.ContainerAccess.TrunkSecondRow
			function DAMN.ContainerAccess.TrunkSecondRow(vehicle, part, chr)
				local fullVName = vehicle:getScript():getFullName()
				if not MoreCarFeatures.canEnterExitVehicleTrunkKI52[fullVName] then
					MoreCarFeatures.canEnterExitVehicleTrunkKI52[fullVName] = true
				end

				return DAMNContainerAccessTrunkSecondRow(vehicle, part, chr)
			end

			local DAMNContainerAccessTrunkThirdRow = DAMN.ContainerAccess.TrunkThirdRow
			function DAMN.ContainerAccess.TrunkThirdRow(vehicle, part, chr)
				local fullVName = vehicle:getScript():getFullName()
				if not MoreCarFeatures.canEnterExitVehicleTrunkKI53[fullVName] then
					MoreCarFeatures.canEnterExitVehicleTrunkKI53[fullVName] = true
				end

				return DAMNContainerAccessTrunkThirdRow(vehicle, part, chr)
			end
		end
	end
	Events.OnInitGlobalModData.Add(onInitGlobalModData)

end


--Jackie Jaye's Van
if not isServer() then ISCarMechanicsOverlay.CarList["Base.VanRadioJJ"] = {imgPrefix="van_", x=10, y=0} end	--mechanics / car seat UI

VehicleDistributions[1]["VanRadioJJ"] = { Normal = VehicleDistributions.Radio }								--item distribution list, for containers

if not isClient() and not (activatedMods:contains("NoVanillaVehicles") or activatedMods:contains("VVR")) then
	Events.OnInitGlobalModData.Add(function()
		if not ModData.getOrCreate("UniqueVehiclesSpawned")["Base.VanRadioJJ"] then
			local function addJJVanAndTrailer(chunk)
				if chunk and chunk:containsPoint(12488, 3904) then
					if chunk:isNewChunk() then
						local jjvan = addVehicleDebug("Base.VanRadioJJ", IsoDirections.S, -1, chunk:getGridSquare(2, 6, 0))
						jjvan:addKeyToGloveBox()
						jjvan:setLocked(false)
						local jjtrailer = addVehicleDebug("Base.TrailerAdvert", IsoDirections.S, 3, chunk:getGridSquare(2, 1, 0))
						
						local jjvanID, jjtrailerID = jjvan:getId(), jjtrailer:getId()
						local timeOutTicks = 100
						local function attachCreatedVehicles()
							timeOutTicks = timeOutTicks - 1
							jjvan, jjtrailer = getVehicleById(jjvanID), getVehicleById(jjtrailerID)
							if jjvan and jjtrailer and timeOutTicks >= 0 then
								if not (jjvan:isCreated() and jjtrailer:isCreated()) then return end
								jjvan:addPointConstraint(nil, jjtrailer, "trailer", "trailer")
							end
							Events.OnTick.Remove(attachCreatedVehicles)
						end
						Events.OnTick.Add(attachCreatedVehicles)
					end

					ModData.getOrCreate("UniqueVehiclesSpawned")["Base.VanRadioJJ"] = true
					Events.LoadChunk.Remove(addJJVanAndTrailer)
				end
			end
			Events.LoadChunk.Add(addJJVanAndTrailer)
		end
	end)
end


if not isClient() then
	--Based on Copy Building Key crafting recipe
	function RecipeCodeOnCreate.copyVehicleKey(CraftRecipeData, playerObj)
		local item = CraftRecipeData:getViableItem(0)
	--	local cloneItem = item:createCloneItem()		Doesn't work in MP or outside of debug? (returns nil)
		local cloneItem = instanceItem(item:getScriptItem():getFullName())
		cloneItem:setKeyId(item:getKeyId())
	--	cloneItem:setName(item:getName())				Client side only
		playerObj:getInventory():addItem(cloneItem)
		sendAddItemToContainer(playerObj:getInventory(), cloneItem)
	end

	function RecipeCodeOnCreate.CraftTireStack(CraftRecipeData, playerObj)	--Unused
		local tires = CraftRecipeData:getAllInputItems()
		local totalTires = tires:size()
		local tireStack

		if totalTires == 1 then
			tireStack = "_48"
		elseif totalTires == 2 then
			tireStack = "_50"
		elseif totalTires == 3 then
			tireStack = "_51"
		elseif totalTires == 4 then
			tireStack = "_52"
		end
		tireStack = instanceItem("Moveables.location_business_machinery_01"..tireStack)

		local tireToMD = {}
		for i=0, totalTires-1 do
			local tire = tires:get(i)
			local tireToVar = {tire:getScriptItem():getFullName(), tire:getCondition(), math.max(tire:getItemCapacity(), 0), tire:getMaxCapacity()}
			table.insert(tireToMD, tireToVar)
		end
		tireStack:getModData().TireStackContents = tireToMD
		--tireStack:transmitModData()	Transmit not needed if item not added yet, also it errors

		local charInv = playerObj:getInventory()
		charInv:AddItem(tireStack)
		sendAddItemToContainer(charInv, tireStack)
	end

	function RecipeCodeOnCreate.smeltIronOrSteelLargePlus(CraftRecipeData, playerObj)	--add 0.25
		local inputCrucible = CraftRecipeData:getViableItem(0)
		local outputCrucible = CraftRecipeData:getFirstCreatedItem()
		local finalUses = 0.25
		if inputCrucible:getScriptItem():getName():contains("Steel") then
			finalUses = finalUses + inputCrucible:getCurrentUsesFloat()
		end
		outputCrucible:setCurrentUsesFloat(finalUses)
		outputCrucible:syncItemFields()
	end
	--(normal large adds 0.2, medium plus 0.15, medium 0.1, and I'll just assume what small does)
	function RecipeCodeOnCreate.smeltIronOrSteelVeryLarge(CraftRecipeData, playerObj)	--add 0.3
		local inputCrucible = CraftRecipeData:getViableItem(0)
		local outputCrucible = CraftRecipeData:getFirstCreatedItem()
		local finalUses = 0.3
		if inputCrucible:getScriptItem():getName():contains("Steel") then
			finalUses = finalUses + inputCrucible:getCurrentUsesFloat()
		end
		outputCrucible:setCurrentUsesFloat(finalUses)
		outputCrucible:syncItemFields()
	end
end

--Requires either a function overwrite or scripting a new trunk part, which I'm not doing. I just edited the advert trailer script itself and added it in there.
--local function addAdvertStorage()
--	local vehicleScripts = getScriptManager():getAllVehicleScripts()
--	for i = 0, vehicleScripts:size() - 1 do
--		local vehicleScript = vehicleScripts:get(i)
--		if vehicleScript then
--			local vsName = vehicleScript:getName()
--			if vsName == "TrailerAdvert" then
--			--	vehicleScript:Load(vsName, [[{***NAME OF VALUE TO CHANGE/ADD*** = ]] .. ***NEW VALUE*** .. [[,}]])
--				vehicleScript:Load(vsName, [[{area TruckBed { xywh = 0.0 0.0 0.9 6.0, } }]])
--				vehicleScript:Load(vsName, [[{template = Trunk/part/TrailerTrunk,}]])
--				break
--			end
--		end
--	end
--end
--Events.OnInitGlobalModData.Add(addAdvertStorage)

--cd "C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid"
--start ProjectZomboid64.exe -nosteam -debug