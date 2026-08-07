function VMZ_isModdedCell(cellX, cellY)
	local dirs = getLotDirectories()
    for i=dirs:size(), 1, -1 do
		local dirName = dirs:get(i-1)
		if dirName ~= "Muldraugh, KY" then
			local lotfile = 'media/maps/'..dirName..'/'..cellX..'_'..cellY..'.lotheader'
			if fileExists(lotfile) then
				return true
			end
		end
	end
	return false
end

function VMZ_registerVehZonesForVanilla(zoneObjs)
	for _, vz in ipairs(zoneObjs) do
		if not VMZ_isModdedCell(math.floor(vz.x/300), math.floor(vz.y/300)) and vz.type == "ParkingStall" then
			local milzone = getWorld():registerVehiclesZone(vz.name, vz.type, vz.x, vz.y, vz.z, vz.width, vz.height, vz.properties)
			if milzone == nil then
				getWorld():registerZone(vz.name, vz.type, vz.x, vz.y, vz.z, vz.width, vz.height)
			end
		end
	end
end

function VMZ_registerVehZonesForMods(zoneObjs)
	for _, vz in ipairs(zoneObjs) do
		if vz.type == "ParkingStall" then
			local milzone = getWorld():registerVehiclesZone(vz.name, vz.type, vz.x, vz.y, vz.z, vz.width, vz.height, vz.properties)
			if milzone == nil then
				getWorld():registerZone(vz.name, vz.type, vz.x, vz.y, vz.z, vz.width, vz.height)
			end
		end
	end
end

local function VMZ_registerVanilla()
	VMZ_registerVehZonesForVanilla(v_milzones)
end

local function VMZ_registerModded()
	VMZ_registerVehZonesForMods(m_milzones)
end

Events.OnLoadMapZones.Add(VMZ_registerVanilla)
Events.OnLoadMapZones.Add(VMZ_registerModded)