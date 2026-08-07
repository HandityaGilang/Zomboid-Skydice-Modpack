NewVZones = NewVZones or {}

--Map modders can hook here... or maybe you just don't want my zones registered in this area? Return true to NOT add the zone. Make the sub-mod a requirement to have this mod so it forces the load order OR delay the hook in an event.
--	local function loadmymapvzonedenyinghook()
--		local NewVZonesCheckMapMods = NewVZones.checkMapMods
--		function NewVZones.checkMapMods(x, y)
--			if (x >= 10500 and x < 11100) and (y >= 9000 and y < 10800) then
--				return true
--			end
--		
--			return NewVZonesCheckMapMods(x, y)
--		end
--	Events.OnPreMapLoad.Add(loadmymapvzonedenyinghook)	(this event should work, try an earlier one if not)

local activatedMods = getActivatedMods()
local Muldraugh = activatedMods:contains("muldraugh1993b42")		--3701834205
function NewVZones.checkMapMods(x, y)
	if Muldraugh and ((x >= 10500 and x < 11100) and (y >= 9000 and y < 10800)) then
		return true
--	elseif MOD and ((x >= ### and x < ###) and (y >= ### and y < ###)) then
--		return true
	end
	return false
end

local function loadZoneChangeFunc()
	local mapmodcheck = NewVZones.checkMapMods
	function NewVZones.changeVZone(ZoneX, ZoneY, NewName, NewWidht, NewHeight, NewX, NewY)
		if not mapmodcheck(ZoneX, ZoneY) then
			local vz = getVehicleZoneAt(ZoneX, ZoneY, 0)
			if vz then
				if NewName then
					vz:setName(NewName)
				end
				if NewWidht then
					vz:setW(NewWidht)
				end
				if NewHeight then
					vz:setH(NewHeight)
				end
				if NewX then
					vz:setX(NewX)
				end
				if NewX and NewY then
					local nvz = getVehicleZoneAt(NewX, ZoneY, 0)
					nvz:setY(NewY)
				elseif NewY then
					vz:setY(NewY)
				end
			else
				print("WARNING for MCF: Vehicle Zone Not Found to Change at (typo at): ", ZoneX, " ", ZoneY)
			end
		end
	end
end

function NewVZones.registerVZones(zoneObjs)
	local mapmodcheck = NewVZones.checkMapMods
	for _, vz in ipairs(zoneObjs) do
	--	do
	--		local x, y, name = vz.x, vz.y, vz.name
	--		if (x >= 6900 and x < 7600) and (y >= 8100 and y < 8600) then		--FL
	--			print(x, " ", y, " FL ", name)
	--		elseif (x >= 5300 and x < 7500) and (y >= 5200 and y < 6600) then	--RS
	--			print(x, " ", y, " RS ", name)
	--		elseif (x >= 9600 and x < 12900) and (y >= 8100 and y < 11300) then	--MD
	--			print(x, " ", y, " MD ", name)
	--		elseif (x >= 9200 and x < 13000) and (y >= 6600 and y < 8000) then	--WP
	--			print(x, " ", y, " WP ", name)
	--		elseif (x >= 7400 and x < 9400) and (y >= 11200 and y < 12500) then	--RW
	--			print(x, " ", y, " RW ", name)
	--		end
	--	end
		if not mapmodcheck(vz.x, vz.y) then
			if vz.type == "ParkingStall" then
				local vzone = getWorld():registerVehiclesZone(vz.name, vz.type, vz.x, vz.y, vz.z, vz.width, vz.height, vz.properties)
				if vzone == nil then
					getWorld():registerZone(vz.name, vz.type, vz.x, vz.y, vz.z, vz.width, vz.height)
				end
			end
		end
	end
end

local function RegisterVZonesLoad()
	NewVZones.registerVZones(NewVehicleZones)
	loadZoneChangeFunc()
end
Events.OnLoadMapZones.Add(RegisterVZonesLoad)
