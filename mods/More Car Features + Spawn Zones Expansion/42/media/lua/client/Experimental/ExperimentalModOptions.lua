local WayMoreCarsExtraOptions = PZAPI.ModOptions:create("WayMoreCarsExtraOptionsID", "More Car Features + Spawn Zones Expansion (DOES NOT WORK OUTSIDE OF DEBUG MODE)")

WayMoreCarsExtraOptions:addTitle("Launchable Vehicles - Hydraulic Cars:")
WayMoreCarsExtraOptions:addKeyBind("jumpCarsID", "Jump Car", Keyboard.KEY_NONE, "Press once to make the car you are in jump while in it.")
WayMoreCarsExtraOptions:addKeyBind("launchCarsID", "Launch Car", Keyboard.KEY_NONE, "Press once to make the car you are in flip while in it.")
WayMoreCarsExtraOptions:addKeyBind("carsCondID", "Car Conditional", Keyboard.KEY_NONE, "Hold before both previous commands to only affect other cars in a set radius around the car you are in rather than only the car you are in.")
