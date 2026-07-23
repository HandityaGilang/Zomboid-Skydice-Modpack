require 'NPCs/ZombiesZoneDefinition'


--SapphCooking_ZombiesZoneDefinition = ZombiesZoneDefinition or {};


--[[ name of the zone for the zone type ZombiesType (in worldzed)

ZombiesZoneDefinition.CoffeeShop = { --Name of a custom zone on the map
	CoffeShop_Sapph_ChefApron = { -- Reference name
		name="Sapph_ChefApron", -- name of the outfit in Clothing.XML
		chance=15,			-- chance to spawn from 1 to 10(guarenteed chance to spawn)
        room="restaurantkitchen",
	},
}

ZombiesZoneDefinition.Gigamart = {
	Gigamart_Sapph_ChefApron = {
		name="Sapph_ChefApron",
		toSpawn=1,
		mandatory="true",
		room="gigamartkitchen",
	},
}
    ]]--

-- total chance can be over 100% we don't care as we'll roll on the totalChance and not a 100 (unlike the specific outfits on top of this)
--SapphCooking_ZombiesZoneDefinition.Default = ZombiesZoneDefinition.Default or {};
-------------------------- Random World Spawns --------------------------
--table.insert(ZombiesZoneDefinition.Default,{name = "Sapph_ChefApron", chance=0.09,});
-------------------------- Restaurant Spawns --------------------------
--table.insert(ZombiesZoneDefinition.Default,{name = "Sapph_ChefApron", chance=10, room="icecream"});
--table.insert(ZombiesZoneDefinition.Default,{name = "Sapph_ChefApron", chance=10, room="gigamartkitchen"});
--table.insert(ZombiesZoneDefinition.Default,{name = "Sapph_ChefApron", chance=10, room="restaurantkitchen"});
--table.insert(ZombiesZoneDefinition.Default,{name = "Sapph_ChefApron", chance=10, room="cafe"});
--table.insert(ZombiesZoneDefinition.Default,{name = "Sapph_ChefApron", chance=10, room="kitchen"});
--table.insert(ZombiesZoneDefinition.Default,{name = "Sapph_ChefApron", chance=10, room="cafeteria"});


-- sapph(12/15/2025): removed this for peace of mind.