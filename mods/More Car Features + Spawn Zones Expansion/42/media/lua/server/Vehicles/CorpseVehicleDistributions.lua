--if getActivatedMods():contains("SpecLoot") then --3457132019
--	require "RegisterSpecificLootTables"
--end

local CORPSE_VALUE = 0
local AMBULANCE_MULTIPLIER = 0
local patchedForThisSave = false

local function updateCorpseVars()
	local sv = SandboxVars and SandboxVars.GamestaVehicleZones
	if sv and sv.vehicleCorpseDistribution then
		local value = sv.vehicleCorpseDistribution
		if value == 1 then
			CORPSE_VALUE = 0
			AMBULANCE_MULTIPLIER = 0
		elseif value == 2 then
			CORPSE_VALUE = 1
			AMBULANCE_MULTIPLIER = 1000
		elseif value == 3 then
			CORPSE_VALUE = 6
			AMBULANCE_MULTIPLIER = 3000
		elseif value == 4 then
			CORPSE_VALUE = 36
			AMBULANCE_MULTIPLIER = 9000
		end
	else
		CORPSE_VALUE = 0
		AMBULANCE_MULTIPLIER = 0
	end
end

local function isItemsArray(t)
	return type(t) == "table" and #t >= 2 and type(t[1]) == "string" and type(t[2]) == "number"
end

local function patchItemsArray(items)
	for i = 1, #items, 2 do
		if items[i] == "CorpseMale" or items[i] == "CorpseFemale" then
			items[i + 1] = CORPSE_VALUE
		end
	end
end

local function deepPatch(root)
	local seen = {}
	local function walk(t, path)
		if type(t) ~= "table" or seen[t] then return end
		seen[t] = true

		local pathLower = (path and path:lower()) or ""
		if isItemsArray(t) and pathLower:find("seat", 1, true) then
			patchItemsArray(t)
		end

		local items = rawget(t, "items")
		if type(items) == "table" and isItemsArray(items) and pathLower:find("seat", 1, true) then
			patchItemsArray(items)
		end

		for k, v in pairs(t) do
			if type(v) == "table" then
				local keystr = tostring(k)
				walk(v, path and path ~= "" and (path .. "." .. keystr) or keystr)
			end
		end
	end
	walk(root, "")
end

local function multiplyAmbulanceTrunkCorpse()
	local amb = VehicleDistributions
		and VehicleDistributions.AmbulanceTruckBed
		and VehicleDistributions.AmbulanceTruckBed.junk

	if amb and isItemsArray(amb.items) then
		local items = amb.items
		for i = 1, #items, 2 do
			if items[i] == "CorpseMale" or items[i] == "CorpseFemale" then
				items[i + 1] = items[i + 1] * AMBULANCE_MULTIPLIER
			end
		end
	end
end

local function runPatch()
	if patchedForThisSave then return end
	updateCorpseVars()

	if _G.ClutterTables then
		deepPatch(_G.ClutterTables)
	end
	if _G.VehicleDistributions then
		deepPatch(_G.VehicleDistributions)
	end

	multiplyAmbulanceTrunkCorpse()

	if ItemPickerJava and ItemPickerJava.Parse then
		ItemPickerJava.Parse()
	end

	patchedForThisSave = true
end

Events.OnInitGlobalModData.Add(runPatch)
Events.OnGameStart.Add(runPatch)
