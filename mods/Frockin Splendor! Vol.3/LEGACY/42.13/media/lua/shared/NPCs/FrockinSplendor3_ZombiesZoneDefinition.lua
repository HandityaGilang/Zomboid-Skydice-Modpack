require 'NPCs/ZombiesZoneDefinition'

FrockinSplendor3_ZombiesZoneDefinition = ZombiesZoneDefinition or {};

table.insert(ZombiesZoneDefinition.Default,{name = "FrockinSplendor_courier_leather", chance= 0.10});
table.insert(ZombiesZoneDefinition.Default,{name = "FrockinSplendor_leatherclad", chance= 0.25});
table.insert(ZombiesZoneDefinition.Default,{name = "FrockinSplendor_leatherbunny", gender="female", chance= 0.055});

table.insert(ZombiesZoneDefinition.Stripclub,{name = "FrockinSplendor_leatherbunny", gender="female", chance= 25});
table.insert(ZombiesZoneDefinition.Stripclub,{name = "FrockinSplendor_leatherclad", chance= 20});


