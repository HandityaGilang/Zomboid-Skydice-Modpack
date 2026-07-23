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

	Whittler = {
		name                    = "base:whittler",
		type                    = "trait",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Firewood"]            = 30,
		},
	},
	
	Formerscout = {
		name                    = "base:formerscout",
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
		name                    = "soto:formerscout2",
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
		name                    = "base:hiker",
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
		name                    = "base:hunter",
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
		name                    = "soto:hunter2",
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
		name                    = "base:eagleeyed",
		type                    = "trait",
		visionBonus             = 2.0,
		weatherEffect           = 3,
		darknessEffect          = 3,
		specialisations         = {},
	},
	EagleEyed2 = {
		name                    = "soto:eagleeyed2",
		type                    = "trait",
		visionBonus             = 2.0,
		weatherEffect           = 3,
		darknessEffect          = 3,
		specialisations         = {},
	},	
	
	Gardener = {
		name                    = "base:gardener",
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
		name                    = "soto:gardener2",
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
		name                    = "base:outdoorsman",
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
		name                    = "soto:outdoorsman2",
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
		name                    = "base:wildernessknowledge",
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
		name                    = "base:cook",
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
		name                    = "base:cook2",
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
		name                    = "base:nightvision",
		type                    = "trait",
		visionBonus             = 0.4,
		weatherEffect           = 0,
		darknessEffect          = 10,  --this gets a "built in" reduction by increasing minimum ambient level ~10%
		specialisations         = {},
	},
	NightVision2 = {
		name                    = "soto:nightvision2",
		type                    = "trait",
		visionBonus             = 0.4,
		weatherEffect           = 0,
		darknessEffect          = 10,  --this gets a "built in" reduction by increasing minimum ambient level ~10%
		specialisations         = {},
	},	

	Nutritionist = {
		name                    = "base:nutritionist",
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
		name                    = "base:nutritionist2",
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
		name                    = "base:herbalist",
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
		name                    = "soto:herbalist2",
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
		name                    = "base:agoraphobic",
		type                    = "trait",
		visionBonus             = -1,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {},
	},
	HeartyAppetite = {
		name                    = "base:heartyappetite",
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
		name                    = "base:marksman",
		type                    = "trait",
		visionBonus             = 0.5,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Ammunition"]          = 3,
		},
	},	

	FirstAid = {
		name                    = "base:firstaid",
		type                    = "trait",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Medical"]             = 3,
		},
	},
	FirstAid2 = {
		name                    = "soto:firstaid2",
		type                    = "trait",
		visionBonus             = 0,
		weatherEffect           = 0,
		darknessEffect          = 0,
		specialisations         = {
			["Medical"]             = 3,
		},
	},	

	ShortSighted = {
		name                    = "base:shortsighted",
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
		name 					= "soto:mushroompicker",
		type 					= "trait",
		visionBonus 			= 0.3,
		weatherEffect 			= 3,
		darknessEffect 			= 3,
		specialisations 		= {
			["Mushrooms"] = 35
		},
	},	
	Entomologist = {
		name 					= "soto:entomologist",
		type 					= "trait",
		visionBonus 			= 0.3,
		weatherEffect 			= 3,
		darknessEffect 			= 3,
		specialisations 		= {
			["Insects"] = 35,
			["FishBait"] = 35,
		},
	},

	Forager = {
		name 					= "soto:forager",
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
		},
	},
	Trapper = {	
		name 					= "soto:trapper",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,		
		specialisations 		= {
			["Animals"] 		= 5
		},
	},
	
	ElectricalMechanic = {	
		name 					= "soto:electricalmechanic",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Trash"] 			= 5				
		},
	},
	AutoMechanic = {	
		name 					= "soto:automechanic",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Trash"] 			= 5				
		},
	},
	Woodworker = {
		name 					= "soto:woodworker",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Trash"] 			= 5		
		},
	},	
	
	MetalWelder = {
		name 					= "soto:metalwelder",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Trash"] 			= 5			
		},
	},
	Culinary = {
		name 					= "soto:culinary",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["JunkFood"]		= 3,
			["Animals"]			= 3,
			["Berries"]			= 3,
			["Mushrooms"]		= 3,			
			
		},
	},
	FearoftheDark = {
		name 					= "soto:fearofthedark",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,		
		darknessEffect 			= -10,
	},	
	
	
	-- TRAITS

	Blacksmith = {
		name 					= "base:blacksmith",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Trash"]			= 5,
				},
	},
	
	Blacksmith2 = {
		name 					= "base:blacksmith2",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Trash"]			= 5,
				},
	},	
	
	KnappingBasics = {
		name 					= "soto:knappingbasics",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Stones"]			= 10,
				},
	},
	
	Masonry = {
		name 					= "soto:masonry",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Stones"]			= 5,
				},
	},	
	
	Potter = {
		name 					= "soto:potter",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Trash"]			= 5,
				},
	},
	Glassblower = {
		name 					= "soto:glassblower",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Trash"]			= 5,
				},
	},	
	
	AnimalFriend = {
		name 					= "soto:animalfriend",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Animals"]			= 3,
			["Berries"]			= 3,
				},
	},
	AnimalFriend2 = {
		name 					= "soto:animalfriend2",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Animals"]			= 3,
			["Berries"]			= 3,
				},
	},
	
	Slaughterer = {
		name 					= "soto:slaughterer",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Animals"]			= 5,
				},
	},
	Slaughterer2 = {
		name 					= "soto:slaughterer2",
		type 					= "trait",
		visionBonus 			= 0,
		weatherEffect 			= 0,
		darknessEffect 			= 0,	
		specialisations 		= {
			["Animals"]			= 5,
				},
	},	
	
	
	
	
	
	-- VANILLA OCCUPATIONS	
	parkranger = {
		name                    = CharacterProfession.PARK_RANGER:getName(),
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
		name                    = CharacterProfession.VETERAN:getName(),
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
		name                    = CharacterProfession.FARMER:getName(),
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
		name                    = CharacterProfession.LUMBERJACK:getName(),
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
		name                    = CharacterProfession.CHEF:getName(),
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
		name                    = CharacterProfession.FISHERMAN:getName(),
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
		name                    = CharacterProfession.UNEMPLOYED:getName(),
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
		name                    = CharacterProfession.BURGER_FLIPPER:getName(),
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
		name                    = CharacterProfession.DOCTOR:getName(),
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
		name                    = CharacterProfession.NURSE:getName(),
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
	fitnessinstructor = {
		name                    = CharacterProfession.FITNESS_INSTRUCTOR:getName(),
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
		name                    = CharacterProfession.REPAIRMAN:getName(),
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
		name                    = CharacterProfession.MECHANICS:getName(),
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
		name                    = CharacterProfession.ELECTRICIAN:getName(),
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
		name                    = CharacterProfession.ENGINEER:getName(),
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
		name                    = CharacterProfession.METALWORKER:getName(),
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
		name                    = CharacterProfession.CONSTRUCTION_WORKER:getName(),
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
		name                    = CharacterProfession.CARPENTER:getName(),
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
		name                    = CharacterProfession.BURGLAR:getName(),
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
		name                    = CharacterProfession.SECURITY_GUARD:getName(),
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
		name                    = CharacterProfession.POLICE_OFFICER:getName(),
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
		name                    = CharacterProfession.FIRE_OFFICER:getName(),
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
		name                    = CharacterProfession.RANCHER:getName(),
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
		name                    = CharacterProfession.SMITHER:getName(),
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

	tailor = {
		name                    = CharacterProfession.TAILOR:getName(),
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

	deliveryman = {
		name                    = SOTO.CharacterProfession.DELIVERYMAN:getName(),
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
	loader = {
		name                    = SOTO.CharacterProfession.LOADER:getName(),
		type                    = "occupation",
		visionBonus             = 0,
		weatherEffect           = 15,
		darknessEffect          = 5,
		specialisations         = {
			["Trash"]               = 30,
			["Junk"]                = 30,				
		},
	},
	truckdriver = {
		name                    = SOTO.CharacterProfession.TRUCK_DRIVER:getName(),
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
	soldier = {
		name                    = SOTO.CharacterProfession.SOLDIER:getName(),
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
	botanist = {
		name                    = SOTO.CharacterProfession.BOTANIST:getName(),
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
	gravedigger = {
		name                    = SOTO.CharacterProfession.GRAVEDIGGER:getName(),
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
	dancer = {
		name                    = SOTO.CharacterProfession.DANCER:getName(),
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
	priest = {
		name                    = SOTO.CharacterProfession.PRIEST:getName(),
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
	detective = {
		name                    = SOTO.CharacterProfession.DETECTIVE:getName(),
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
	weightliftinginstructor = {
		name                    = SOTO.CharacterProfession.WEIGHTLIFTING_INSTRUCTOR:getName(),
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
	schoolteacher = {
		name                    = SOTO.CharacterProfession.SCHOOL_TEACHER:getName(),
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
	janitor = {
		name                    = SOTO.CharacterProfession.JANITOR:getName(),
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
	stuntman = {
		name                    = SOTO.CharacterProfession.STUNTMAN:getName(),
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
	gasstationoperator = {
		name                    = SOTO.CharacterProfession.GAS_STATION_OPERATOR:getName(),
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
	campcounselor = {
		name                    = SOTO.CharacterProfession.CAMP_COUNSELOR:getName(),
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
	dragracer = {
		name                    = SOTO.CharacterProfession.DRAG_RACER:getName(),
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
	junkyardworker = {
		name                    = SOTO.CharacterProfession.JUNKYARD_WORKER:getName(),
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
	lifeguard = {
		name                    = SOTO.CharacterProfession.LIFEGUARD:getName(),
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
	demolitionworker = {
		name                    = SOTO.CharacterProfession.DEMOLITION_WORKER:getName(),
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
	butcher = {
		name                    = SOTO.CharacterProfession.BUTCHER:getName(),
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
	
	paparazzi = {
		name                    = SOTO.CharacterProfession.PAPARAZZI:getName(),
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
	
	miner = {
		name                    = SOTO.CharacterProfession.MINER:getName(),
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
	
	storeemployee = {
		name                    = SOTO.CharacterProfession.STORE_EMPLOYEE:getName(),
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

	criminal = {
		name                    = SOTO.CharacterProfession.CRIMINAL:getName(),
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
	
	animalcontrolofficer = {
		name                    = SOTO.CharacterProfession.ANIMAL_CONTROL_OFFICER:getName(),
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
	
	huntsman = {
		name                    = SOTO.CharacterProfession.HUNTSMAN:getName(),
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

	veterinarian = {
		name                    = SOTO.CharacterProfession.VETERINARIAN:getName(),
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