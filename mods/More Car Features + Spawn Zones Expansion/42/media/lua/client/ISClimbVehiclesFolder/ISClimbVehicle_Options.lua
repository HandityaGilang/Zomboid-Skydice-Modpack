if getActivatedMods():contains("ClimbableVehicles") then return end

local WayMoreCarsOptions = PZAPI.ModOptions:create("WayMoreCarsOptionsID", "More Car Features + Spawn Zones Expansion")

WayMoreCarsOptions:addTitle("Climbable Vehicles - Cars:")
WayMoreCarsOptions:addKeyBind("UpCarsID", "Climb Up", Keyboard.KEY_UP, "From the ground to the top of the vehicle.")
WayMoreCarsOptions:addKeyBind("DownCarsID", "Drop Down", Keyboard.KEY_DOWN, "From the top of the vehicle to the ground.")

WayMoreCarsOptions:addTitle("Climbable Vehicles - Hatches/Sunroofs:")
WayMoreCarsOptions:addKeyBind("UpHatchesID", "Climb Up (Inside)", Keyboard.KEY_UP, "From the seat of the vehicle to the top.")
WayMoreCarsOptions:addKeyBind("DownHatchesID", "Drop Down (Inside)", Keyboard.KEY_DOWN, "From the top of the vehicle to the seat.")
WayMoreCarsOptions:addKeyBind("SidesHatchesConditionalID", "Drop Down (Outside) Conditional", Keyboard.KEY_LEFT, "Used in Combination with 'Drop Down (Outside)' keybind. If set to NONE, it only uses one key press for the 'Drop Down (Outside)' keybind.")
WayMoreCarsOptions:addKeyBind("SidesHatchesID", "Drop Down (Outside) + Conditional (Above Option)", Keyboard.KEY_RIGHT, "From the top of the vehicle to the ground.")
