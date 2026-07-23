	----------------------------
	--- FORAGING INTEGRATION ---
	----------------------------

--[[
local function doGlassesCheck(_character, _skillDef, _bonusEffect)
	if _bonusEffect == "visionBonus" then
		local visualAids = {
			["Base.Glasses_Normal"]     = true,
			["Base.Glasses_Reading"]    = true,
		};
		local wornItem = _character:getWornItem("Eyes");
		if wornItem and visualAids[wornItem:getFullType()] then
			return false;
		end;
	end;
	return true;
end]]
	
require "Foraging/forageDefinitions";

forageSystem.forageSkillDefinitions = {

	-- VANILLA TRAITS
	Whittler = {
		name                    = "Whittler",
		type                    = "trait",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Firewood"]            = 30,
		},
	},
	Unlucky = {
		name                    = "Unlucky",
		type                    = "trait",
		visionBonus             = -1.0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["ForestRarities"]      = -5,
			["Medical"]             = -5,
			["Ammunition"]          = -5,
			["JunkWeapons"]         = -5,
		},
	},
	Lucky = {
		name                    = "Lucky",
		type                    = "trait",
		visionBonus             = 1.0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["ForestRarities"]      = 5,
			["Medical"]             = 5,
			["Ammunition"]          = 5,
			["JunkWeapons"]         = 5,
		},
	},
	Formerscout = {
		name                    = "Formerscout",
		type                    = "trait",
		visionBonus             = 0.7,
		weatherEffect           = 13,
		darknessEffect          = 3,
		specialisations         = {
			["MedicinalPlants"]     = 5,
			["Trash"]               = 10,
		},
	},
	Formerscout2 = {
		name                    = "Formerscout2",
		type                    = "trait",
		visionBonus             = 0.7,
		weatherEffect           = 13,
		darknessEffect          = 3,
		specialisations         = {
			["MedicinalPlants"]     = 5,
			["Trash"]               = 10,
		},
	},	
	Hiker = {
		name                    = "Hiker",
		type                    = "trait",
		visionBonus             = 0.7,
		weatherEffect           = 13,
		darknessEffect          = 3,
		specialisations         = {
			["MedicinalPlants"]     = 3,
			["Berries"]             = 3,
			["Mushrooms"]           = 3,
		},
	},
	Hunter = {
		name                    = "Hunter",
		type                    = "trait",
		visionBonus             = 0.5,
		weatherEffect           = 13,
		darknessEffect          = 5,
		specialisations         = {
			["Animals"]             = 15,
			["Berries"]             = 3,
			["Mushrooms"]           = 3,
			["MedicinalPlants"]     = 3,
		},
	},
	Hunter2 = {
		name                    = "Hunter2",
		type                    = "trait",
		visionBonus             = 0.5,
		weatherEffect           = 13,
		darknessEffect          = 5,
		specialisations         = {
			["Animals"]             = 15,
			["Berries"]             = 3,
			["Mushrooms"]           = 3,
			["MedicinalPlants"]     = 3,
		},
	},
	
	EagleEyed = {
		name                    = "EagleEyed",
		type                    = "trait",
		visionBonus             = 2.0,
		weatherEffect           = 3,
		darknessEffect          = 3,
		specialisations         = {},
	},
	EagleEyed2 = {
		name                    = "EagleEyed2",
		type                    = "trait",
		visionBonus             = 2.0,
		weatherEffect           = 3,
		darknessEffect          = 3,
		specialisations         = {},
	},	
	Gardener = {
		name                    = "Gardener",
		type                    = "trait",
		visionBonus             = 0.4,
		weatherEffect           = 13,
		darknessEffect          = 0,
		specialisations         = {
			["MedicinalPlants"]     = 3,
			["Crops"]               = 5,
			["Fruits"]              = 5,
			["Vegetables"]          = 5,
		},
	},
	Gardener2 = {
		name                    = "Gardener2",
		type                    = "trait",
		visionBonus             = 0.4,
		weatherEffect           = 13,
		darknessEffect          = 0,
		specialisations         = {
			["MedicinalPlants"]     = 3,
			["Crops"]               = 5,
			["Fruits"]              = 5,
			["Vegetables"]          = 5,
		},
	},	
	Outdoorsman = {
		name                    = "Outdoorsman",
		type                    = "trait",
		visionBonus             = 0.4,
		weatherEffect           = 13,
		darknessEffect          = 5,
		specialisations         = {
			["Animals"]             = 5,
			["Berries"]             = 5,
			["Mushrooms"]           = 5,
			["MedicinalPlants"]     = 5,
			["WildPlants"]			= 5,
			["WildHerbs"]			= 5,
		},
	},
	Outdoorsman2 = {
		name                    = "Outdoorsman2",
		type                    = "trait",
		visionBonus             = 0.4,
		weatherEffect           = 13,
		darknessEffect          = 5,
		specialisations         = {
			["Animals"]             = 5,
			["Berries"]             = 5,
			["Mushrooms"]           = 5,
			["MedicinalPlants"]     = 5,
			["WildPlants"]			= 5,
			["WildHerbs"]			= 5,
		},
	},
	WildernessKnowledge = {
		name                    = "WildernessKnowledge",
		type                    = "trait",
		visionBonus             = 0.4,
		weatherEffect           = 13,
		darknessEffect          = 5,
		specialisations         = {
			["Animals"]             = 5,
			["Berries"]             = 5,
			["Mushrooms"]           = 5,
			["MedicinalPlants"]     = 5,
			["WildPlants"]			= 5,
			["WildHerbs"]			= 5,
			["Firewood"]            = 5,
			["Stones"]              = 5,
		},
	},
	Cook = {
		name                    = "Cook",
		type                    = "trait",
		visionBonus             = 0.2,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Animals"]             = 5,
			["Berries"]             = 5,
			["Mushrooms"]           = 5,
			["JunkFood"]            = 5,
			["MedicinalPlants"]     = 3,
			["WildPlants"]			= 5,
			["WildHerbs"]			= 5,
		},
	},
	Cook2 = {
		name                    = "Cook2",
		type                    = "trait",
		visionBonus             = 0.2,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Animals"]             = 5,
			["Berries"]             = 5,
			["Mushrooms"]           = 5,
			["JunkFood"]            = 5,
			["MedicinalPlants"]     = 3,
			["WildPlants"]			= 5,
			["WildHerbs"]			= 5,
		},
	},
	NightVision = {
		name                    = "NightVision",
		type                    = "trait",
		visionBonus             = 0.4,
		weatherEffect           = 0,
		darknessEffect          = 10,  --this gets a "built in" reduction by increasing minimum ambient level ~10%
		specialisations         = {},
	},
	NightVision2 = {
		name                    = "NightVision2",
		type                    = "trait",
		visionBonus             = 0.4,
		weatherEffect           = 0,
		darknessEffect          = 10,  --this gets a "built in" reduction by increasing minimum ambient level ~10%
		specialisations         = {},
	},	
	Nutritionist = {
		name                    = "Nutritionist",
		type                    = "trait",
		visionBonus             = 0.2,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["JunkFood"]            = 5,
			["MedicinalPlants"]     = 5,
			["WildPlants"]			= 5,
			["WildHerbs"]			= 5,
		},
	},
	Nutritionist2 = {
		name                    = "Nutritionist2",
		type                    = "trait",
		visionBonus             = 0.2,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["JunkFood"]            = 5,
			["MedicinalPlants"]     = 5,
			["WildPlants"]			= 5,
			["WildHerbs"]			= 5,
		},
	},
	Herbalist = {
		name                    = "Herbalist",
		type                    = "trait",
		visionBonus             = 0.2,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["MedicinalPlants"]     = 15,
			["WildPlants"]			= 5,
			["WildHerbs"]			= 5,
			["Crops"]               = 5,
			["Berries"]             = 5,
			["Mushrooms"]           = 5,
		},
	},
	Herbalist2 = {
		name                    = "Herbalist2",
		type                    = "trait",
		visionBonus             = 0.2,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["MedicinalPlants"]     = 15,
			["WildPlants"]			= 5,
			["WildHerbs"]			= 5,
			["Crops"]               = 5,
			["Berries"]             = 5,
			["Mushrooms"]           = 5,
		},
	},	
	Agoraphobic = {
		name                    = "Agoraphobic",
		type                    = "trait",
		visionBonus             = -1,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {},
	},
	HeartyAppitite = {
		name                    = "HeartyAppitite",
		type                    = "trait",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Animals"]             = 3,
			["Berries"]             = 3,
			["Mushrooms"]           = 3,
			["JunkFood"]            = 3,
		},
	},
	Marksman = {
		name                    = "Marksman",
		type                    = "trait",
		visionBonus             = 0.5,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Ammunition"]          = 3,
		},
	},
	FirstAid = {
		name                    = "FirstAid",
		type                    = "trait",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Medical"]             = 3,
		},
	},
	FirstAid2 = {
		name                    = "FirstAid2",
		type                    = "trait",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Medical"]             = 3,
		},
	},	
	Fishing = {
		name                    = "Fishing",
		type                    = "trait",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Insects"]             = 5,
			["FishBait"]            = 5,
		},
	},
	ShortSighted = {
		name                    = "ShortSighted",
		type                    = "trait",
		visionBonus             = -3,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Animals"] 		= -5,
			["JunkFood"] 		= -5,	
			["Berries"] 		= -5,
			["Mushrooms"] 		= -5,
			["MedicinalPlants"] = -5,
			["ForestRarities"] 	= -5,	
			["Insects"] 		= -5,	
			["WildPlants"]		= -5,	
			["Trash"]			= -5,
			["Junk"]			= -5,				
		},
		testFuncs               = { forageSystem.doGlassesCheck},
	},
	
	-- NEW TRAITS
	MushroomPicker = {
		name 					= "MushroomPicker",
		type 					= "trait",
		visionBonus 			= 0.3,
		weatherEffect 			= 3,
		darknessEffect 			= 3,
		specialisations 		= {
			["Mushrooms"] = 35
		}
	},	
	Entomologist = {
		name 					= "Entomologist",
		type 					= "trait",
		visionBonus 			= 0.3,
		weatherEffect 			= 3,
		darknessEffect 			= 3,
		specialisations 		= {
			["Insects"] = 35,
			["FishBait"] = 35,
		}
	},		
	Forager = {
		name 					= "Forager",
		type 					= "trait",
		visionBonus 			= 0.5,
		weatherEffect 			= 5,
		darknessEffect 			= 3,
		specialisations 		= {
			["Animals"] 		= 3,
			["JunkFood"] 		= 3,	
			["Berries"] 		= 3,
			["Mushrooms"] 		= 3,
			["MedicinalPlants"] = 3,
			["ForestRarities"] 	= 3,	
			["Insects"] 		= 3,	
			["WildPlants"]		= 3,	
			["Trash"] 			= 3				
		}
	},
	Trapper = {	
		name 					= "Trapper",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,		
		specialisations 		= {
			["Animals"] 		= 5
		}
	},
	ElectricTech = {	
		name 					= "ElectricTech",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Trash"] 			= 5				
		}
	},
	AutoMechanic = {	
		name 					= "AutoMechanic",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Trash"] 			= 5				
		}
	},
	Woodworker = {
		name 					= "Woodworker",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Trash"] 			= 5		
		}
	},
	MetalWelder = {
		name 					= "MetalWelder",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Trash"] 			= 5			
		}
	},
	Culinary = {
		name 					= "Culinary",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["JunkFood"]		= 3,
			["Animals"]			= 3,
			["Berries"]			= 3,
			["Mushrooms"]		= 3,			
			
		}
	},
	FearoftheDark = {
		name 					= "FearoftheDark",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,		
		darknessEffect 			= -10,
	},	
	
	
	-- TRAITS

	Blacksmith = {
		name 					= "Blacksmith",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Trash"]			= 5,
				}
	},
	
	KnappingBasics = {
		name 					= "KnappingBasics",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Stones"]			= 10,
				}
	},
	
	Masonry = {
		name 					= "Masonry",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Stones"]			= 5,
				}
	},	
	
	Potter = {
		name 					= "Potter",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Trash"]			= 5,
				}
	},
	Glassblower = {
		name 					= "Glassblower",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Trash"]			= 5,
				}
	},
	
	AnimalFriend = {
		name 					= "AnimalFriend",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Animals"]			= 3,
			["Berries"]			= 3,
				}
	},
	Slaughterer = {
		name 					= "Slaughterer",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Animals"]			= 5,
				}
	},
	
	-- VANILLA OCCUPATIONS	
	parkranger = {
		name                    = "parkranger",
		type                    = "occupation",
		visionBonus             = 2,
		weatherEffect           = 25,
		darknessEffect          = 10,
		specialisations         = {
			["Animals"]             = 10,
			["Berries"]             = 15,
			["Mushrooms"]           = 10,
			["MedicinalPlants"]     = 70,
			["WildPlants"]			= 40,
			["WildHerbs"]			= 40,
			["ForestRarities"]      = 10,
			["Stones"]      		= 10,
		},
	},
	veteran = {
		name                    = "veteran",
		type                    = "occupation",
		visionBonus             = 1.75,
		weatherEffect           = 30,
		darknessEffect          = 15,
		specialisations         = {
			["Animals"]             = 5,
			["Ammunition"]          = 50,
			["MedicinalPlants"]     = 20,
			["WildPlants"]			= 10,
			["WildHerbs"]			= 10,
			["ForestRarities"]      = 5,
		},
	},
	farmer = {
		name                    = "farmer",
		type                    = "occupation",
		visionBonus             = 1.5,
		weatherEffect           = 25,
		darknessEffect          = 10,
		specialisations         = {
			["Animals"]             = 5,
			["Crops"]               = 50,
			["JunkFood"]            = 5,
			["MedicinalPlants"]     = 5,
			["WildPlants"]			= 10,
			["WildHerbs"]			= 10,
			["Fruits"]              = 10,
			["Vegetables"]          = 10,
		},
	},
	lumberjack = {
		name                    = "lumberjack",
		type                    = "occupation",
		visionBonus             = 1.25,
		weatherEffect           = 35,
		darknessEffect          = 15,
		specialisations         = {
			["Firewood"]            = 60,
			["Mushrooms"]           = 20,
			["WildPlants"]			= 5,
			["WildHerbs"]			= 5,
		},
	},
	chef = {
		name                    = "chef",
		type                    = "occupation",
		visionBonus             = 0.5,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Animals"]             = 10,
			["Berries"]             = 20,
			["Mushrooms"]           = 55,
			["JunkFood"]            = 30,
			["MedicinalPlants"]     = 15,
			["WildPlants"]			= 20,
			["WildHerbs"]			= 20,
		},
	},
	fisherman = {
		name                    = "fisherman",
		type                    = "occupation",
		visionBonus             = 1.0,
		weatherEffect           = 40,
		darknessEffect          = 10,
		specialisations         = {
			["Insects"]             = 60,
			["FishBait"]            = 60,
			["Berries"]             = 10,
			["Mushrooms"]           = 10,
			["MedicinalPlants"]     = 10,			
		},
	},
	unemployed = {
		name                    = "unemployed",
		type                    = "occupation",
		visionBonus             = 0.5,
		weatherEffect           = 10,
		darknessEffect          = 5,
		specialisations         = {
			["Berries"]             = 5,
			["Mushrooms"]           = 5,		
			["MedicinalPlants"]     = 5,
			["WildPlants"]			= 5,
			["WildHerbs"]			= 5,
			["JunkFood"]            = 10,
			["Trash"]               = 10,
			["Junk"]                = 10,
			["JunkWeapons"]         = 5,
		},
	},
	burgerflipper = {
		name                    = "burgerflipper",
		type                    = "occupation",
		visionBonus             = 0.25,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Animals"]             = 10,
			["Berries"]             = 10,
			["Mushrooms"]           = 20,
			["JunkFood"]            = 25,
			["MedicinalPlants"]     = 5,
			["WildPlants"]			= 5,
			["WildHerbs"]			= 5,			
		},
	},
	doctor = {
		name                    = "doctor",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Medical"]             = 60,
			["MedicinalPlants"]     = 20,
		},
	},
	nurse = {
		name                    = "nurse",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Medical"]             = 40,
			["MedicinalPlants"]     = 10,
			["Trash"]               = 10,
			["Junk"]                = 10,	
			["JunkFood"]            = 10,			
		},
	},
	fitnessInstructor = {
		name                    = "fitnessInstructor",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Berries"]             = 5,		
			["Medical"]             = 15,
			["JunkFood"]            = 25,
			["MedicinalPlants"]     = 15,
			["WildPlants"]			= 10,
			["WildHerbs"]			= 10,
			["Trash"]               = 5,
			["Junk"]                = 5,				
		},
	},
	repairman = {
		name                    = "repairman",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Trash"]               = 40,
			["Junk"]                = 40,
		},
	},
	mechanics = {
		name                    = "mechanics",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Trash"]               = 40,
			["Junk"]                = 40,
		},
	},
	electrician = {
		name                    = "electrician",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Trash"]               = 40,
			["Junk"]                = 40,
		},
	},
	engineer = {
		name                    = "engineer",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Trash"]               = 35,
			["Junk"]                = 35,
			["JunkWeapons"]         = 10,			
		},
	},
	metalworker = {
		name                    = "metalworker",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Trash"]               = 40,
			["Junk"]                = 40,
		},
	},
	constructionworker = {
		name                    = "constructionworker",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 10,
		darknessEffect          = 10,
		specialisations         = {
			["Trash"]               = 20,
			["Junk"]                = 20,
			["Stones"]				= 20,		
		},
	},
	carpenter = {
		name                    = "carpenter",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Firewood"]            = 50,
			["Trash"]               = 15,			
			["Junk"]                = 15,
		},
	},
	burglar = {
		name                    = "burglar",
		type                    = "occupation",
		visionBonus             = 0.25,
		weatherEffect           = 5,
		darknessEffect          = 20,
		specialisations         = {
			["Trash"]               = 10,
			["Junk"]                = 10,
			["JunkWeapons"]         = 10,
			["Ammunition"]          = 20,
		},
	},
	securityguard = {
		name                    = "securityguard",
		type                    = "occupation",
		visionBonus             = 0.5,
		weatherEffect           = 10,
		darknessEffect          = 20,
		specialisations         = {
			["Trash"]               = 10,
			["Junk"]                = 10,
			["JunkWeapons"]         = 10,
			["Ammunition"]          = 10,
		},
	},
	policeofficer = {
		name                    = "policeofficer",
		type                    = "occupation",
		visionBonus             = 0.5,
		weatherEffect           = 10,
		darknessEffect          = 10,
		specialisations         = {
			["Trash"]               = 10,
			["Junk"]                = 10,
			["JunkWeapons"]         = 10,
			["Ammunition"]          = 20,
		},
	},
	fireofficer = {
		name                    = "fireofficer",
		type                    = "occupation",
		visionBonus             = 0.5,
		weatherEffect           = 10,
		darknessEffect          = 10,
		specialisations         = {
			["Firewood"]            = 30,
			["Trash"]               = 10,			
			["Junk"]                = 10,
		},
	},

	rancher = {
		name                    = "rancher",
		type                    = "occupation",
		visionBonus             = 1.5,
		weatherEffect           = 15,
		darknessEffect          = 20,
		specialisations         = {
			["Animals"]             = 40,
			["Crops"]               = 20,
			["JunkFood"]            = 5,
			["MedicinalPlants"]     = 5,
			["WildPlants"]			= 5,
			["WildHerbs"]			= 5,
			["Fruits"]              = 10,
			["Vegetables"]          = 10,
		},
	},	
	smither = {
		name                    = "smither",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Trash"]               = 30,
			["Junk"]                = 30,
			["Stones"]                = 10,
		},
	},	

	tailorProfession = {
		name                    = "tailorProfession",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Trash"]               = 40,
			["Junk"]                = 40,		
		},
	},

	-- NEW OCCUPATIONS

	deliverymanocc = {
		name                    = "deliverymanocc",
		type                    = "occupation",
		visionBonus             = 0.5,
		weatherEffect           = 10,
		darknessEffect          = 5,
		specialisations         = {
			["Trash"]               = 15,
			["Junk"]                = 15,
			["JunkFood"]            = 15,	
			["Ammunition"]          = 5,
			["JunkWeapons"]         = 5,
			
		},
	},
	loaderocc = {
		name                    = "loaderocc",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 15,
		darknessEffect          = 5,
		specialisations         = {
			["Trash"]               = 30,
			["Junk"]                = 30,				
		},
	},
	truckerocc = {
		name                    = "truckerocc",
		type                    = "occupation",
		visionBonus             = 0.25,
		weatherEffect           = 15,
		darknessEffect          = 15,
		specialisations         = {
			["Trash"]               = 15,
			["Junk"]                = 15,		
			["JunkFood"]            = 15,				
		},
	},
	soldierocc = {
		name                    = "soldierocc",
		type                    = "occupation",
		visionBonus             = 1.5,
		weatherEffect           = 30,
		darknessEffect          = 15,
		specialisations         = {
			["Animals"]             = 5,
			["Ammunition"]          = 40,
			["Firewood"]            = 20,			
			["MedicinalPlants"]     = 10,
			["WildPlants"]			= 5,
			["WildHerbs"]			= 5,
			["ForestRarities"]      = 5,		
		},
	},
	botanistocc = {
		name                    = "botanistocc",
		type                    = "occupation",
		visionBonus             = 1.75,
		weatherEffect           = 10,
		darknessEffect          = 10,
		specialisations         = {	
			["Berries"]             = 15,
			["Mushrooms"]           = 15,
			["MedicinalPlants"]     = 80,
			["WildPlants"]			= 75,
			["WildHerbs"]			= 75,
		},	
	},	
	gravemanocc = {
		name                    = "gravemanocc",
		type                    = "occupation",
		visionBonus             = 0.75,
		weatherEffect           = 15,
		darknessEffect          = 25,
		specialisations         = {
			["MedicinalPlants"]     = 10,
			["WildPlants"]			= 10,
			["WildHerbs"]			= 10,
			["JunkFood"]            = 15,
			["Trash"]               = 10,
			["Junk"]                = 10,
			["Firewood"]            = 20,
			["Insects"]             = 20,
			["FishBait"]            = 20,	
			["Stones"]				= 10,			
		},
	},	
	dancerocc = {
		name                    = "dancerocc",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 10,
		specialisations         = {	
			["MedicinalPlants"]     = 5,
			["WildPlants"]			= 5,
			["WildHerbs"]			= 5,
			["JunkFood"]            = 20,
			["Trash"]               = 20,
			["Junk"]                = 20,
		},	
	},	
	priestocc = {
		name                    = "priestocc",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Medical"]             = 10,
			["MedicinalPlants"]     = 30,
			["WildPlants"]			= 10,
			["WildHerbs"]			= 10,
			["Trash"]               = 10,
			["Junk"]                = 10,
			["Stones"]  			= 10,			
		},
	},
	detectiveocc = {
		name                    = "detectiveocc",
		type                    = "occupation",
		visionBonus             = 2.25,
		weatherEffect           = 20,
		darknessEffect          = 20,
		specialisations         = {
			["Ammunition"]          = 40,
			["ForestRarities"]      = 25,		
			["Trash"]               = 25,
			["Junk"]                = 25,		
			["JunkFood"]            = 20,	
			["JunkWeapons"]         = 20,			
		},
	},
	heavyathinstructorocc = {
		name                    = "heavyathinstructorocc",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Medical"]             = 5,
			["JunkFood"]            = 45,
			["MedicinalPlants"]     = 10,
			["WildPlants"]			= 10,
			["WildHerbs"]			= 10,
		},
	},	
	teacherocc = {
		name                    = "teacherocc",
		type                    = "occupation",
		visionBonus             = 0.25,
		weatherEffect           = 0,
		darknessEffect          = 0,		
		specialisations         = {
			["Berries"]             = 5,		
			["Mushrooms"]           = 5,
			["Medical"]             = 10,			
			["MedicinalPlants"]     = 15,
			["WildPlants"]			= 10,
			["WildHerbs"]			= 10,
			["JunkFood"]            = 10,
			["Trash"]               = 10,
			["Junk"]                = 10,
		},
	},	
	cleanermanocc = {
		name                    = "cleanermanocc",
		type                    = "occupation",
		visionBonus             = 1.0,
		weatherEffect           = 15,
		darknessEffect          = 10,
		specialisations         = {
			["Firewood"]            = 30,		
			["Trash"]               = 30,
			["Junk"]                = 30,
			["JunkFood"]            = 15,			
			["Insects"]             = 10,	
			["FishBait"]            = 10,				
		},
	},	
	stuntmanocc = {
		name                    = "stuntmanocc",
		type                    = "occupation",
		visionBonus             = 0.25,
		weatherEffect           = 15,
		darknessEffect          = 0,
		specialisations         = {
			["JunkFood"]            = 20,
			["Trash"]               = 20,
			["Junk"]                = 20,
		},
	},	
	gasstationoperatorocc = {
		name                    = "gasstationoperatorocc",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 10,
		darknessEffect          = 10,
		specialisations         = {
			["Trash"]               = 20,
			["Junk"]                = 20,		
			["JunkFood"]            = 20,				
		},
	},	
	campcounsocc = {
		name                    = "campcounsocc",
		type                    = "occupation",
		visionBonus             = 1.25,
		weatherEffect           = 30,
		darknessEffect          = 10,
		specialisations         = {
			["Berries"]             = 20,
			["Mushrooms"]           = 20,
			["Firewood"]            = 25,
			["Stones"]				= 5,				
			["MedicinalPlants"]     = 45,
			["WildPlants"]			= 45,
			["WildHerbs"]			= 45,
			["ForestRarities"]      = 10,
			["Trash"]               = 5,
			["Junk"]                = 5,
		},
	},	
	dragracerocc = {
		name                    = "dragracerocc",
		type                    = "occupation",
		visionBonus             = 0.5,
		weatherEffect           = 0,
		darknessEffect          = 5,
		specialisations         = {
			["Trash"]               = 25,
			["Junk"]                = 25,		
			["JunkFood"]            = 15,				
		},
	},
	junkyardworkerocc = {
		name                    = "junkyardworkerocc",
		type                    = "occupation",
		visionBonus             = 1.5,
		weatherEffect           = 15,
		darknessEffect          = 15,
		specialisations         = {
			["Trash"]               = 55,
			["Junk"]                = 55,
			["JunkFood"]            = 30,
			["JunkWeapons"]         = 30,	
			["Stones"]         		= 10,			
		},
	},	
	lifeguardocc = {
		name                    = "lifeguardocc",
		type                    = "occupation",
		visionBonus             = 1.0,
		weatherEffect           = 15,
		darknessEffect          = 5,
		specialisations         = {
			["Berries"]             = 5,
			["Mushrooms"]           = 5,
			["MedicinalPlants"]     = 15,
			["Trash"]               = 5,
			["Junk"]                = 5,
			["JunkFood"]			= 5,			
		},
	},		
	demoworkerocc = {
		name                    = "demoworkerocc",
		type                    = "occupation",
		visionBonus             = 0.25,
		weatherEffect           = 5,
		darknessEffect          = 10,
		specialisations         = {
			["Trash"]               = 25,
			["Junk"]                = 25,
			["Stones"]              = 10,			
		},
	},	
	butcherocc = {
		name                    = "butcherocc",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Animals"]             = 30,
			["JunkFood"]            = 40,
			["Berries"]             = 5,
			["Mushrooms"]           = 5,			
		},
	},	
	
	paparazziocc = {
		name                    = "paparazziocc",
		type                    = "occupation",
		visionBonus             = 1.0,
		weatherEffect           = 10,
		darknessEffect          = 20,
		specialisations         = {
			["Trash"]               = 10,
			["Junk"]                = 10,
			["JunkFood"]			= 10,			
		},
	},		
	
	minerocc = {
		name                    = "minerocc",
		type                    = "occupation",
		visionBonus             = 0.25,
		weatherEffect           = 0,
		darknessEffect          = 35,
		specialisations         = {
			["Trash"]               = 15,
			["Junk"]                = 15,
			["Stones"]              = 10,	
		},
	},		
	
	cashierocc = {
		name                    = "cashierocc",
		type                    = "occupation",
		visionBonus             = 0.25,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Trash"]               = 30,
			["Junk"]                = 30,
			["JunkFood"]			= 15,			
		},
	},		

	criminalocc = {
		name                    = "criminalocc",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 5,
		darknessEffect          = 15,
		specialisations         = {
			["Trash"]               = 15,
			["Junk"]                = 15,
			["JunkWeapons"]         = 15,
			["Ammunition"]          = 15,			
		},
	},
	
	animalcontrolofficerocc = {
		name                    = "animalcontrolofficerocc",
		type                    = "occupation",
		visionBonus             = 1.5,
		weatherEffect           = 10,
		darknessEffect          = 15,
		specialisations         = {
			["Animals"]             = 70,
			["Junk"]                = 10,
			["Trash"]               = 10,			
			["JunkFood"]            = 20,
			["ForestRarities"]      = 5,			
			["Insects"]             = 10,					
			["FishBait"]            = 10,			
		},
	},	
	
	hunterocc = {
		name                    = "hunterocc",
		type                    = "occupation",
		visionBonus             = 1.5,
		weatherEffect           = 10,
		darknessEffect          = 15,
		specialisations         = {
			["Animals"]             = 70,
			["Junk"]                = 10,
			["Trash"]               = 10,			
			["JunkFood"]            = 20,
			["ForestRarities"]      = 5,			
			["Insects"]             = 10,					
			["FishBait"]            = 10,			
		},
	},

	veterinarianocc = {
		name                    = "veterinarianocc",
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Animals"]             = 20,
			["Medical"]             = 50,
			["MedicinalPlants"]     = 10,
		},
	},
	
};