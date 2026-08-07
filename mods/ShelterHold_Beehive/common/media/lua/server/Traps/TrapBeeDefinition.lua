
Traps = Traps or {}
local BaitHive = {}
BaitHive.type = "Hold.BaitHive"
BaitHive.sprite = "Hold_BaitHive_0"
BaitHive.closedSprite = "Hold_BaitHive_1"
BaitHive.trapStrength = 500
BaitHive.destroyItem = "Base.UnusableWood"
table.insert(Traps, BaitHive)

-- Bees definition
TrapAnimals = TrapAnimals or {}
--[[
local Honeybee = {}
Honeybee.type = "Honeybee"
Honeybee.strength = 20
Honeybee.item = "Hold.Honeybee"
Honeybee.minHour = 19
Honeybee.maxHour = 5
Honeybee.minSize = 10
Honeybee.maxSize = 60
Honeybee.zone = {}
Honeybee.zone["TownZone"] = 2
Honeybee.zone["TrailerPark"] = 2
Honeybee.zone["Vegitation"] = 10
Honeybee.zone["Forest"] = 12
Honeybee.zone["DeepForest"] = 15
Honeybee.zone["BirchForest"] = 12
Honeybee.zone["BirchMixForest"] = 12
Honeybee.zone["FarmForest"] = 12
Honeybee.zone["FarmMixForest"] = 12
Honeybee.zone["PRForest"] = 12
Honeybee.zone["PHForest"] = 12
Honeybee.zone["PHMixForest"] = 12
Honeybee.zone["OrganicForest"] = 15
Honeybee.traps = {}
Honeybee.traps["Hold.BaitHive"] = 40
Honeybee.baits = {}
Honeybee.baits["Base.Honey"] = 45

local Zombee = {}
Zombee.type = "Zombee"
Zombee.strength = 20
Zombee.item = "Hold.Zombee"
Zombee.minHour = 19
Zombee.maxHour = 5
Zombee.minSize = 10
Zombee.maxSize = 60
Zombee.zone = {}
Zombee.zone["TownZone"] = 2
Zombee.zone["TrailerPark"] = 2
Zombee.zone["Vegitation"] = 10
Zombee.zone["Forest"] = 12
Zombee.zone["DeepForest"] = 15
Zombee.zone["BirchForest"] = 12
Zombee.zone["BirchMixForest"] = 12
Zombee.zone["FarmForest"] = 12
Zombee.zone["FarmMixForest"] = 12
Zombee.zone["PRForest"] = 12
Zombee.zone["PHForest"] = 12
Zombee.zone["PHMixForest"] = 12
Zombee.zone["OrganicForest"] = 15
Zombee.traps = {}
Zombee.traps["Hold.BaitHive"] = 40
Zombee.baits = {}
Zombee.baits["Base.Honey"] = 45

local Bumblebee = {}
Bumblebee.type = "Bumblebee"
Bumblebee.strength = 20
Bumblebee.item = "Hold.Bumblebee"
Bumblebee.minHour = 19
Bumblebee.maxHour = 5
Bumblebee.minSize = 10
Bumblebee.maxSize = 60
Bumblebee.zone = {}
Bumblebee.zone["TownZone"] = 2
Bumblebee.zone["TrailerPark"] = 2
Bumblebee.zone["Vegitation"] = 10
Bumblebee.zone["Forest"] = 12
Bumblebee.zone["DeepForest"] = 15
Bumblebee.zone["BirchForest"] = 12
Bumblebee.zone["BirchMixForest"] = 12
Bumblebee.zone["FarmForest"] = 12
Bumblebee.zone["FarmMixForest"] = 12
Bumblebee.zone["PRForest"] = 12
Bumblebee.zone["PHForest"] = 12
Bumblebee.zone["PHMixForest"] = 12
Bumblebee.zone["OrganicForest"] = 15
Bumblebee.traps = {}
Bumblebee.traps["Hold.BaitHive"] = 40
Bumblebee.baits = {}
Bumblebee.baits["Base.Honey"] = 45

table.insert(TrapAnimals, Honeybee)
table.insert(TrapAnimals, Zombee)
table.insert(TrapAnimals, Bumblebee)
]]


local WildHoneyComb = {}
WildHoneyComb.type = "WildHoneyComb"
WildHoneyComb.strength = 20
WildHoneyComb.item = "Hold.WildHoneyComb"
WildHoneyComb.minHour = 19
WildHoneyComb.maxHour = 5
WildHoneyComb.minSize = 10
WildHoneyComb.maxSize = 60
WildHoneyComb.zone = {}
WildHoneyComb.zone["TownZone"] = 2
WildHoneyComb.zone["TrailerPark"] = 2
WildHoneyComb.zone["Vegitation"] = 10
WildHoneyComb.zone["Forest"] = 12
WildHoneyComb.zone["DeepForest"] = 15
WildHoneyComb.zone["BirchForest"] = 12
WildHoneyComb.zone["BirchMixForest"] = 12
WildHoneyComb.zone["FarmForest"] = 12
WildHoneyComb.zone["FarmMixForest"] = 12
WildHoneyComb.zone["PRForest"] = 12
WildHoneyComb.zone["PHForest"] = 12
WildHoneyComb.zone["PHMixForest"] = 12
WildHoneyComb.zone["OrganicForest"] = 15
WildHoneyComb.traps = {}
WildHoneyComb.traps["Hold.BaitHive"] = 40
WildHoneyComb.baits = {}
WildHoneyComb.baits["Base.Honey"] = 45
WildHoneyComb.baits["Hold.Beeswax"] = 35
WildHoneyComb.baits["Base.Sugar"] = 25
WildHoneyComb.baits["Base.SugarBrown"] = 25
WildHoneyComb.baits["Base.SugarCubes"] = 25
WildHoneyComb.baits["Base.SugarPacket"] = 25


table.insert(TrapAnimals, WildHoneyComb)