local VZUtils = require("YAPZLib/VehicleZone")
local vanillaMilitaryZones = require("VMZ/Zones/Vanilla_Map")
local modsMilitaryZones = require("VMZ/Zones/Map_Mods")

Events.OnLoadMapZones.Add(function()
	VZUtils.register(vanillaMilitaryZones, true)
end)

Events.OnLoadMapZones.Add(function()
	VZUtils.register(modsMilitaryZones, false)
end)

print(modsMilitaryZones)