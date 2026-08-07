local modsMilitaryZones = {}
local activeMods = getActivatedMods()

--Louisville Quarantine Zone
if activeMods:contains("Louisville_Quarantine_Zone") then
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 13442, y = 4071, z = 0, width = 4, height = 6, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 13631, y = 4072, z = 0, width = 3, height = 5, properties = { Direction = "S" } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 13830, y = 4039, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 13745, y = 4084, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 13607, y = 4105, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light_angled", type = "ParkingStall", x = 13618, y = 4124, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 13493, y = 4085, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 13967, y = 4070, z = 0, width = 3, height = 5, properties = { Direction = "S" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 13690, y = 4091, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_trailer", type = "ParkingStall", x = 14007, y = 4065, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 13997, y = 4068, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
end
--Raven Creek
if activeMods:contains("RavenCreekB42") then
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 4207, y = 15456, z = 0, width = 4, height = 15, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_trailer_light", type = "ParkingStall", x = 4207, y = 15493, z = 0, width = 4, height = 12, properties = { Direction = "W", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 4207, y = 15533, z = 0, width = 4, height = 12, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light_angled", type = "ParkingStall", x = 5913, y = 15406, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_trailer_heavy", type = "ParkingStall", x = 5080, y = 17035, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 5086, y = 16981, z = 0, width = 3, height = 15, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 4972, y = 17067, z = 0, width = 3, height = 4, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 5150, y = 17566, z = 0, width = 4, height = 3 })
end
--Echo Creek Military Base
if activeMods:contains("EchoCreek MilitaryBase") then
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 3531, y = 10362, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 3432, y = 10256, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 3414, y = 10259, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 3420, y = 10264, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_trailer", type = "ParkingStall", x = 3392, y = 10255, z = 0, width = 5, height = 9, properties = { Direction = "E", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 3481, y = 10217, z = 0, width = 3, height = 5, properties = { Direction = "S" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 3505, y = 10213, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 3493, y = 10339, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
end
--SecretZ Pandemic
	--March Rigde
if activeMods:contains("Secretz42") or activeMods:contains("SZ_MarchRidge_ResearchFacility") then
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 10362, y = 12386, z = 0, width = 4, height = 6, properties = { Direction = "S", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 10349, y = 12417, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light_angled", type = "ParkingStall", x = 10354, y = 12352, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 10368, y = 12417, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 10373, y = 12381, z = 0, width = 4, height = 6, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 10370, y = 12484, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 10384, y = 12485, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_trailer_heavy", type = "ParkingStall", x = 10399, y = 12473, z = 0, width = 5, height = 9, properties = { Direction = "W", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 10390, y = 12466, z = 0, width = 3, height = 5, properties = { Direction = "S" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light_angled", type = "ParkingStall", x = 10406, y = 12494, z = 0, width = 3, height = 5, properties = { Direction = "N" } })	
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 10105, y = 12601, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_trailer_heavy", type = "ParkingStall", x = 10092, y = 12601, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 10077, y = 12601, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light_angled", type = "ParkingStall", x = 10360, y = 12271, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 10315, y = 12252, z = 0, width = 6, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 10347, y = 12216, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 10313, y = 12235, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 10264, y = 12252, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 10270, y = 12252, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 10276, y = 12252, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 10279, y = 12252, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 10283, y = 12215, z = 0, width = 3, height = 5, properties = { Direction = "S" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 10259, y = 12213, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_trailer_heavy", type = "ParkingStall", x = 10261, y = 12189, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_trailer_heavy", type = "ParkingStall", x = 10265, y = 12189, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light_angled", type = "ParkingStall", x = 10265, y = 12228, z = 0, width = 3, height = 5, properties = { Direction = "S" } })
end
	--Muldraugh
if activeMods:contains("Secretz42") or activeMods:contains("SZ_MuldraughCrossroads_Checkpoint") then
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 10583, y = 11341, z = 0, width = 3, height = 5, properties = { Direction = "S" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 10762, y = 11205, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 10769, y = 11191, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light_angled", type = "ParkingStall", x = 10641, y = 11176, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 10530, y = 11181, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 10886, y = 11194, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 10932, y = 11214, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 10904, y = 11245, z = 0, width = 17, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 10918, y = 11215, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_trailer_heavy", type = "ParkingStall", x = 10904, y = 11236, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 10952, y = 11139, z = 0, width = 3, height = 15, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 10940, y = 11151, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 10911, y = 11128, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
end

if activeMods:contains("Secretz42") or activeMods:contains("SZ_Muldraugh_Traindepot_EVAC") then
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 11505, y = 10038, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 11518, y = 10062, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 11635, y = 10210, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 11647, y = 10226, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 11664, y = 10221, z = 0, width = 3, height = 5, properties = { Direction = "S" } })
end
	--Deerhead Lake
if activeMods:contains("Secretz42") or activeMods:contains("SZ_DeerheadLake_Base") then
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 4708, y = 8668, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 4672, y = 8553, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 4648, y = 8530, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 4648, y = 8520, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 4650, y = 8450, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light_angled", type = "ParkingStall", x = 4644, y = 8506, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 4635, y = 8479, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 4713, y = 8499, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light_angled", type = "ParkingStall", x = 4710, y = 8527, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light_angled", type = "ParkingStall", x = 4715, y = 8573, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 4743, y = 8589, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 4722, y = 8611, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 4730, y = 8571, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 4662, y = 8499, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
end
	--North Checkpoint
if activeMods:contains("Secretz42") or activeMods:contains("SZ_North_Checkpoint") then
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 3858, y = 7015, z = 0, width = 3, height = 15, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 3818, y = 7001, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_container_angled", type = "ParkingStall", x = 3768, y = 7001, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
end
	--Railroad Checkpoint
if activeMods:contains("Secretz42") or activeMods:contains("SZ_Checkpoint1") then
	table.insert(modsMilitaryZones, { name = "military_container_angled", type = "ParkingStall", x = 12131, y = 8315, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 12157, y = 8314, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
end
	--Riverside Checkpoint
if activeMods:contains("Secretz42") or activeMods:contains("SZ_Checkpoint6") then
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 5833, y = 5804, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 5865, y = 5775, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_trailer", type = "ParkingStall", x = 5787, y = 5795, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 5726, y = 5703, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 5720, y = 5743, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 5779, y = 5743, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
end
	--Bunker
if activeMods:contains("Secretz42") or activeMods:contains("SZ_Bunker_3") then
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 6071, y = 11860, z = 0, width = 13, height = 5, properties = { Direction = "N" } })
end
	--Mall
if activeMods:contains("Secretz42") or activeMods:contains("SZ_The_Mall") then
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 13900, y = 5902, z = 0, width = 5, height = 6, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 13882, y = 5949, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 13894, y = 5954, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 13970, y = 5906, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 14029, y = 5954, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 13900, y = 5735, z = 0, width = 5, height = 3, properties = { Direction = "W", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 13924, y = 5731, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light_angled", type = "ParkingStall", x = 13938, y = 5733, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 13957, y = 5949, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
end
	--Louisville Military Complex
if activeMods:contains("Secretz42") or activeMods:contains("SZ_Louisville_Military_Complex") then
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 14007, y = 1913, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_burnt", type = "ParkingStall", x = 14048, y = 1922, z = 0, width = 5, height = 3 })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 13984, y = 1970, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 13985, y = 1957, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 13992, y = 1964, z = 0, width = 3, height = 5, properties = { Direction = "S" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light_angled", type = "ParkingStall", x = 14010, y = 1954, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 14010, y = 1975, z = 0, width = 3, height = 12, properties = { Direction = "S" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 14017, y = 1963, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 14426, y = 1989, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
end
-- Foxtrot Warehouse
if activeMods:contains("FoxtrotWarehouse") then
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 10605, y = 13360, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 10667, y = 13442, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 10653, y = 13453, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 10653, y = 13468, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 10723, y = 13417, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 10728, y = 13439, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 10727, y = 13426, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 10691, y = 13386, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 10670, y = 13390, z = 0, width = 3, height = 5, properties = { Direction = "S" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 10606, y = 13284, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light_angled", type = "ParkingStall", x = 10732, y = 13263, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 10741, y = 13363, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 10712, y = 13363, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_trailer_light", type = "ParkingStall", x = 10751, y = 13401, z = 0, width = 9, height = 5, properties = { Direction = "N", FaceDirection = true } })
end
-- Falcon Ridge
if activeMods:contains("FalconRidgeB42") then
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 11383, y = 14261, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 11392, y = 14249, z = 0, width = 4, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 11514, y = 14330, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 11510, y = 14294, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 11499, y = 14315, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 11525, y = 14294, z = 0, width = 4, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_trailer_heavy", type = "ParkingStall", x = 11582, y = 14388, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_trailer_light", type = "ParkingStall", x = 11587, y = 14375, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_trailer_light", type = "ParkingStall", x = 11618, y = 14373, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy_angled", type = "ParkingStall", x = 11627, y = 14374, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_trailer_heavy", type = "ParkingStall", x = 11636, y = 14388, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_container_angled", type = "ParkingStall", x = 11633, y = 14368, z = 0, width = 3, height = 5, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_trailer_light_angled", type = "ParkingStall", x = 11663, y = 14374, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 11674, y = 14378, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_container_angled", type = "ParkingStall", x = 11537, y = 14491, z = 0, width = 14, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_trailer_light_angled", type = "ParkingStall", x = 11531, y = 14475, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_trailer_heavy_angled", type = "ParkingStall", x = 11498, y = 14474, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 11509, y = 14494, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_trailer_light_angled", type = "ParkingStall", x = 11470, y = 14476, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 11453, y = 14490, z = 0, width = 3, height = 5, properties = { Direction = "S" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 11459, y = 14492, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 11261, y = 14563, z = 0, width = 3, height = 5, properties = { Direction = "S" } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 11196, y = 14426, z = 0, width = 3, height = 33, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_trailer_heavy_angled", type = "ParkingStall", x = 11288, y = 14516, z = 0, width = 3, height = 5, properties = { Direction = "N", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_light", type = "ParkingStall", x = 11760, y = 14226, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
end
--Anruisi Town
if activeMods:contains("AnruisiTown") then
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 12492, y = 11506, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 12508, y = 11625, z = 0, width = 3, height = 5, properties = { Direction = "S" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 12570, y = 11455, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 12586, y = 11477, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 12580, y = 11497, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 12589, y = 11497, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 12600, y = 11530, z = 0, width = 3, height = 5, properties = { Direction = "S" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 12515, y = 11691, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_trailer_light", type = "ParkingStall", x = 12579, y = 11472, z = 0, width = 5, height = 3, properties = { Direction = "E", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 12532, y = 11541, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
end
--Safeharbor Garrison
if activeMods:contains("modid") then
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 12167, y = 10895, z = 0, width = 3, height = 5, properties = { Direction = "S" } })
	table.insert(modsMilitaryZones, { name = "military_container_angled", type = "ParkingStall", x = 12235, y = 10906, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_container_angled", type = "ParkingStall", x = 12147, y = 10892, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 12171, y = 10981, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_trailer_light", type = "ParkingStall", x = 12182, y = 10904, z = 0, width = 3, height = 5, properties = { Direction = "S", FaceDirection = true } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_angled", type = "ParkingStall", x = 12155, y = 10912, z = 0, width = 5, height = 3, properties = { Direction = "E" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle", type = "ParkingStall", x = 12575, y = 10883, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
	table.insert(modsMilitaryZones, { name = "military_container", type = "ParkingStall", x = 12586, y = 10865, z = 0, width = 3, height = 5, properties = { Direction = "N" } })
	table.insert(modsMilitaryZones, { name = "military_vehicle_heavy", type = "ParkingStall", x = 11772, y = 10983, z = 0, width = 3, height = 5, properties = { Direction = "S" } })
	table.insert(modsMilitaryZones, { name = "military_container_angled", type = "ParkingStall", x = 12229, y = 10954, z = 0, width = 5, height = 3, properties = { Direction = "W" } })
end

return modsMilitaryZones


  