require "ZScienceSkill/Data"

local blacksmith = CharacterTrait and CharacterTrait.BLACKSMITH
local gardener   = CharacterTrait and CharacterTrait.GARDENER
local herbalist  = CharacterTrait and CharacterTrait.HERBALIST

ZScienceSkill.Data.add({ traits = {
    [blacksmith] = 10,
    [herbalist]  = 10,
    [gardener]   = 20,
}})

ZScienceSkill.Data.add({ literature = {
    -- Science books (full XP)
    ["Base.Book_Science"]         = 35,
    ["Base.Paperback_Science"]    = 30,
    ["Base.Magazine_Science"]     = 15,
    ["Base.Magazine_Science_New"] = 15,
    ["Base.Magazine_Tech"]        = 10,
    ["Base.Magazine_Tech_New"]    = 10,

    -- SciFi books (smaller XP - fiction inspires curiosity)
    ["Base.Book_SciFi"]           =  8,
    ["Base.Paperback_SciFi"]      =  8,

    ["Base.Book_Medical"]         = { Science = 10, Doctor = 20 },
    ["Base.Paperback_Medical"]    = { Science = 10, Doctor = 15 },
    ["Base.BookFancy_Medical"]    = { Science =  5, Doctor = 15 },
}})


local specimenXP = 30
ZScienceSkill.Data.add({ specimens = {
    -- Preserved specimens
    ["Base.Specimen_Insects"]       = specimenXP,
    ["Base.Specimen_Beetles"]       = specimenXP,
    ["Base.Specimen_Butterflies"]   = specimenXP,
    ["Base.Specimen_Centipedes"]    = specimenXP,
    ["Base.Specimen_Tapeworm"]      = specimenXP,
    ["Base.Specimen_Minerals"]      = specimenXP,
    ["Base.Specimen_Octopus"]       = specimenXP,
    ["Base.Specimen_FetalCalf"]     = specimenXP,
    ["Base.Specimen_FetalLamb"]     = specimenXP,
    ["Base.Specimen_FetalPiglet"]   = specimenXP,
    ["Base.Specimen_MonkeyHead"]    = specimenXP,
    ["Base.Specimen_Brain"]         = { Science = specimenXP * 2, Doctor = specimenXP },

    -- intestines
    ["Base.Animal_Brain"]           = specimenXP * 1.5,
    ["Base.Animal_Brain_Small"]     = specimenXP,
    ["Base.AnimalSinew"]            = specimenXP * 0.5,
    ["Base.BrainTan"]               = { Science = specimenXP,   Tailoring = specimenXP },
    ["Base.Hominid_Skull"]          = specimenXP,
    ["Base.Hominid_Skull_Fragment"] = specimenXP * 0.5,
    ["Base.Hominid_Skull_Partial"]  = specimenXP * 0.75,

    -- bones & teeth
    ["Base.HerbivoreTeeth"]         = { Science =  5, Carving =  5 },
    ["Base.PigTusk"]                = { Science =  5, Carving = 10 },
    ["Base.SmallAnimalBone"]        = { Science = 10, Carving = 10 },
    ["Base.AnimalBone"]             = { Science = 10, Carving = 10 },
    ["Base.LargeAnimalBone"]        = { Science = 10, Carving = 10 },

    -- heads
    ["Base.Bull_Head_Angus"]                = { Science = 10, Butchering = 10 },
    ["Base.Bull_Head_Holstein"]             = { Science = 10, Butchering = 10 },
    ["Base.Bull_Head_Simmental"]            = { Science = 10, Butchering = 10 },
    ["Base.Calf_Head_Angus"]                = { Science = 10, Butchering = 10 },
    ["Base.Calf_Head_Holstein"]             = { Science = 10, Butchering = 10 },
    ["Base.Calf_Head_Simmental"]            = { Science = 10, Butchering = 10 },
    ["Base.Chicken_Chick_Head"]             = { Science = 10, Butchering = 10 },
    ["Base.Chicken_Hen_Brown_Head"]         = { Science = 10, Butchering = 10 },
    ["Base.Chicken_Hen_White_Head"]         = { Science = 10, Butchering = 10 },
    ["Base.Chicken_Rooster_Head_Brown"]     = { Science = 10, Butchering = 10 },
    ["Base.Chicken_Rooster_Head_White"]     = { Science = 10, Butchering = 10 },
    ["Base.Cow_Head_Angus"]                 = { Science = 10, Butchering = 10 },
    ["Base.Cow_Head_Holstein"]              = { Science = 10, Butchering = 10 },
    ["Base.Cow_Head_Simmental"]             = { Science = 10, Butchering = 10 },
    ["Base.Deer_Buck_Head"]                 = { Science = 10, Butchering = 10 },
    ["Base.Deer_Doe_Head"]                  = { Science = 10, Butchering = 10 },
    ["Base.Deer_Fawn_Head"]                 = { Science = 10, Butchering = 10 },
    ["Base.Pig_Boar_Head_Black"]            = { Science = 10, Butchering = 10 },
    ["Base.Pig_Boar_Head_Pink"]             = { Science = 10, Butchering = 10 },
    ["Base.Pig_Piglet_Head_Black"]          = { Science = 10, Butchering = 10 },
    ["Base.Pig_Piglet_Head_Pink"]           = { Science = 10, Butchering = 10 },
    ["Base.Pig_Sow_Head_Black"]             = { Science = 10, Butchering = 10 },
    ["Base.Pig_Sow_Head_Pink"]              = { Science = 10, Butchering = 10 },
    ["Base.Rabbit_Head_Appalachian"]        = { Science = 10, Butchering = 10 },
    ["Base.Rabbit_Head_CottonTail"]         = { Science = 10, Butchering = 10 },
    ["Base.Rabbit_Head_Swamp"]              = { Science = 10, Butchering = 10 },
    ["Base.Rabbit_Kitten_Head_Appalachian"] = { Science = 10, Butchering = 10 },
    ["Base.Rabbit_Kitten_Head_CottonTail"]  = { Science = 10, Butchering = 10 },
    ["Base.Rabbit_Kitten_Head_Swamp"]       = { Science = 10, Butchering = 10 },
    ["Base.Raccoon_Boar_Head"]              = { Science = 10, Butchering = 10 },
    ["Base.Raccoon_Kit_Head"]               = { Science = 10, Butchering = 10 },
    ["Base.Raccoon_Sow_Head"]               = { Science = 10, Butchering = 10 },
    ["Base.Sheep_Ewe_Head_Black"]           = { Science = 10, Butchering = 10 },
    ["Base.Sheep_Ewe_Head_White"]           = { Science = 10, Butchering = 10 },
    ["Base.Sheep_Lamb_Head_Black"]          = { Science = 10, Butchering = 10 },
    ["Base.Sheep_Lamb_Head_White"]          = { Science = 10, Butchering = 10 },
    ["Base.Sheep_Ram_Head_Black"]           = { Science = 10, Butchering = 10 },
    ["Base.Sheep_Ram_Head_White"]           = { Science = 10, Butchering = 10 },
    ["Base.Turkey_Gobbler_Head"]            = { Science = 10, Butchering = 10 },
    ["Base.Turkey_Hen_Head"]                = { Science = 10, Butchering = 10 },
    ["Base.Turkey_Poult_Head"]              = { Science = 10, Butchering = 10 },

    -- animal skulls
    ["Base.Cow_Skull"]                      = { Science = 10, Butchering = 10 },
    ["Base.Bull_Skull"]                     = { Science = 10, Butchering = 10 },
    ["Base.Calf_Skull"]                     = { Science = 10, Butchering = 10 },
    ["Base.Sheep_Skull"]                    = { Science = 10, Butchering = 10 },
    ["Base.Ram_Skull"]                      = { Science = 10, Butchering = 10 },
    ["Base.Lamb_Skull"]                     = { Science = 10, Butchering = 10 },
    ["Base.Pig_Skull"]                      = { Science = 10, Butchering = 10 },
    ["Base.Piglet_Skull"]                   = { Science = 10, Butchering = 10 },
    ["Base.Chicken_Hen_Skull"]              = { Science = 10, Butchering = 10 },
    ["Base.Chicken_Rooster_Skull"]          = { Science = 10, Butchering = 10 },
    ["Base.Chicken_Chick_Skull"]            = { Science = 10, Butchering = 10 },
    ["Base.Turkey_PoultSkull"]              = { Science = 10, Butchering = 10 },
    ["Base.Turkey_Skull"]                   = { Science = 10, Butchering = 10 },
    ["Base.Raccoon_Skull"]                  = { Science = 10, Butchering = 10 },
    ["Base.Rabbit_KittenSkull"]             = { Science = 10, Butchering = 10 },
    ["Base.Rabbit_Skull"]                   = { Science = 10, Butchering = 10 },
    ["Base.DeerStag_Skull"]                 = { Science = 10, Butchering = 10 },
    ["Base.DeerDoe_Skull"]                  = { Science = 10, Butchering = 10 },
    ["Base.DeerFawn_Skull"]                 = { Science = 10, Butchering = 10 },

    -- corpses
    ["Base.DeadRatSkinned"]                 = { Science = 10, Butchering = 10 },
}})


local insectXP = 10
ZScienceSkill.Data.add({ specimens = {
    -- Insects (entomology)
    ["Base.AmericanLadyCaterpillar"]    = insectXP,
    ["Base.BandedWoolyBearCaterpillar"] = insectXP,
    ["Base.Centipede"]                  = insectXP,
    ["Base.Centipede2"]                 = insectXP,
    ["Base.Cockroach"]                  = insectXP,
    ["Base.Cricket"]                    = insectXP,
    ["Base.Grasshopper"]                = insectXP,
    ["Base.Ladybug"]                    = insectXP,
    ["Base.Leech"]                      = insectXP,
    ["Base.Maggots"]                    = insectXP * 0.5,
    ["Base.Millipede"]                  = insectXP,
    ["Base.Millipede2"]                 = insectXP,
    ["Base.MonarchCaterpillar"]         = insectXP,
    ["Base.Pillbug"]                    = insectXP * 0.5,
    ["Base.SawflyLarva"]                = insectXP,
    ["Base.SilkMothCaterpillar"]        = insectXP,
    ["Base.SwallowtailCaterpillar"]     = insectXP,
    ["Base.Termites"]                   = insectXP,
    ["Base.Worm"]                       = insectXP * 0.5,

    -- Zoology
    ["Base.Frog"]                       = insectXP * 2,
    ["Base.Snail"]                      = insectXP,
    ["Base.Slug"]                       = insectXP,
    ["Base.Slug2"]                      = insectXP,
}})


local berryXP = 10
ZScienceSkill.Data.add({ specimens = {
    -- Berries (botany)
    ["Base.BeautyBerry"]    = { trait = herbalist, Science = berryXP },
    ["Base.HollyBerry"]     = { trait = herbalist, Science = berryXP },
    ["Base.WinterBerry"]    = { trait = herbalist, Science = berryXP },
    ["Base.BerryBlack"]     = { trait = herbalist, Science = berryXP },
    ["Base.BerryBlue"]      = { trait = herbalist, Science = berryXP },
    ["Base.BerryGeneric1"]  = { trait = herbalist, Science = berryXP * 2 },  -- Unknown berry, more XP for identification
    ["Base.BerryGeneric2"]  = { trait = herbalist, Science = berryXP * 2 },
    ["Base.BerryGeneric3"]  = { trait = herbalist, Science = berryXP * 2 },
    ["Base.BerryGeneric4"]  = { trait = herbalist, Science = berryXP * 2 },
    ["Base.BerryGeneric5"]  = { trait = herbalist, Science = berryXP * 2 },
    ["Base.BerryPoisonIvy"] = { trait = herbalist, Science = berryXP * 3 },  -- Toxic, extra XP for toxicology
}})


-- Mushrooms (mycology)
local mushroomXP = 15
ZScienceSkill.Data.add({ specimens = {
    ["Base.MushroomsButton"]  = { trait = herbalit, Science = mushroomXP },
    ["Base.MushroomGeneric1"] = { trait = herbalit, Science = mushroomXP * 2 },  -- Unknown, more XP
    ["Base.MushroomGeneric2"] = { trait = herbalit, Science = mushroomXP * 2 },
    ["Base.MushroomGeneric3"] = { trait = herbalit, Science = mushroomXP * 2 },
    ["Base.MushroomGeneric4"] = { trait = herbalit, Science = mushroomXP * 2 },
    ["Base.MushroomGeneric5"] = { trait = herbalit, Science = mushroomXP * 2 },
    ["Base.MushroomGeneric6"] = { trait = herbalit, Science = mushroomXP * 2 },
    ["Base.MushroomGeneric7"] = { trait = herbalit, Science = mushroomXP * 2 },
}})


-- Medicinal plants (pharmacology)
local sciXP = 10
local docXP = 10
ZScienceSkill.Data.add({ specimens = {
    ["Base.BlackSage"]         = { Science = sciXP, Doctor = docXP, trait = herbalist },
    ["Base.BlackSageDried"]    = { Science = sciXP, Doctor = docXP, trait = herbalist },
    ["Base.CommonMallow"]      = { Science = sciXP, Doctor = docXP, trait = herbalist },
    ["Base.CommonMallowDried"] = { Science = sciXP, Doctor = docXP, trait = herbalist },
    ["Base.Comfrey"]           = { Science = sciXP, Doctor = docXP, trait = herbalist },
    ["Base.ComfreyDried"]      = { Science = sciXP, Doctor = docXP, trait = herbalist },
    ["Base.Ginseng"]           = { Science = sciXP, Doctor = docXP, trait = herbalist },
    ["Base.LemonGrass"]        = { Science = sciXP, Doctor = docXP, trait = herbalist },
    ["Base.Marigold"]          = { Science = sciXP, Doctor = docXP, trait = herbalist },
    ["Base.Plantain"]          = { Science = sciXP, Doctor = docXP, trait = herbalist },
    ["Base.PlantainDried"]     = { Science = sciXP, Doctor = docXP, trait = herbalist },
    ["Base.WildGarlic2"]       = { Science = sciXP, Doctor = docXP, trait = herbalist },
    ["Base.WildGarlicDried"]   = { Science = sciXP, Doctor = docXP, trait = herbalist },
}})


-- pills & other medical stuff
local sciXP = 10
local docXP = 20
ZScienceSkill.Data.add({ specimens = {
    ["Base.Antibiotics"]          = { Science = sciXP, Doctor = docXP },
    ["Base.Coffee2"]              = { Science = sciXP/2 },
    ["Base.Coldpack"]             = { Science = sciXP, Doctor = docXP/2 }, -- TODO: recipe?
    ["Base.Hat_HeadMirrorDOWN"]   = { Science = sciXP, Doctor = docXP, key = "Base.Hat_HeadMirror" },
    ["Base.Hat_HeadMirrorUP"]     = { Science = sciXP, Doctor = docXP, key = "Base.Hat_HeadMirror" },
    ["Base.Pills"]                = { Science = sciXP, Doctor = docXP },
    ["Base.PillsAntiDep"]         = { Science = sciXP, Doctor = docXP },
    ["Base.PillsBeta"]            = { Science = sciXP, Doctor = docXP },
    ["Base.PillsSleepingTablets"] = { Science = sciXP, Doctor = docXP },
    ["Base.PillsVitamins"]        = { Science = sciXP, Doctor = docXP }, -- caffeine pills
    ["Base.Stethoscope"]          = { Science = sciXP, Doctor = docXP },
    ["Base.SutureNeedle"]         = { Science = sciXP, Doctor = docXP },
    ["Base.TongueDepressor"]      = { Science = sciXP/2, Doctor = docXP/2 }, -- make it useful for something

    -- movables
    ["Base.location_community_medical_01_24"] = { Science = sciXP, Doctor = docXP*2, key = "Base.iv_stand" },
    ["Base.location_community_medical_01_25"] = { Science = sciXP, Doctor = docXP*2, key = "Base.iv_stand" },
    ["Base.location_community_medical_01_26"] = { Science = sciXP, Doctor = docXP*2, key = "Base.iv_stand" },
    ["Base.location_community_medical_01_27"] = { Science = sciXP, Doctor = docXP*2, key = "Base.iv_stand" },
}})


-- Farming / Agriculture
local sciXP  =  5
local farmXP = 10
ZScienceSkill.Data.add({ specimens = {
    ["Base.Fertilizer"]            = { Science = sciXP,   Farming = farmXP*2 }, -- TODO: recipe?
    ["Base.GardeningSprayEmpty"]   = { Science = sciXP,   Farming = farmXP*2 },
    ["Base.HandScythe"]            = { Science = sciXP/2, Farming = farmXP },
    ["Base.HandShovel"]            = { Science = sciXP/2, Farming = farmXP },
    ["Base.SlugRepellent"]         = { Science = sciXP,   Farming = farmXP*2 },

    -- wild foraged plants
    ["Base.Acorn"]                 = { Science = sciXP, Farming = farmXP, trait = herbalist },
    ["Base.Dandelions"]            = { Science = sciXP, Farming = farmXP, trait = herbalist },
    ["Base.GrapeLeaves"]           = { Science = sciXP, Farming = farmXP, trait = herbalist },
    ["Base.Nettles"]               = { Science = sciXP, Farming = farmXP, trait = herbalist },
    ["Base.Rosehips"]              = { Science = sciXP, Farming = farmXP, trait = herbalist },
    ["Base.Thistle"]               = { Science = sciXP, Farming = farmXP, trait = herbalist },
    ["Base.Violets"]               = { Science = sciXP, Farming = farmXP, trait = herbalist },
    ["Base.WheatSheaf"]            = { Science = sciXP, Farming = farmXP },
    ["Base.WheatSheafDried"]       = { Science = sciXP, Farming = farmXP },

    -- seeds
    ["Base.BarleySeed"]            = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.BasilSeed"]             = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.BellPepperSeed"]        = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.BlackSageSeed"]         = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.BroadleafPlantainSeed"] = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.BroccoliSeed"]          = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.CabbageSeed"]           = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.CarrotSeed"]            = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.CauliflowerSeed"]       = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.ChamomileSeed"]         = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.ChivesSeed"]            = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.CilantroSeed"]          = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.ComfreySeed"]           = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.CommonMallowSeed"]      = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.CornSeed"]              = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.CucumberSeed"]          = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.FlaxSeed"]              = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.GarlicSeed"]            = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.GreenpeasSeed"]         = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.HabaneroSeed"]          = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.HempSeed"]              = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.HopsSeed"]              = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.JalapenoSeed"]          = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.KaleSeed"]              = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.LavenderSeed"]          = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.LeekSeed"]              = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.LemonGrassSeed"]        = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.LettuceSeed"]           = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.MarigoldSeed"]          = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.MintSeed"]              = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.OnionSeed"]             = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.OreganoSeed"]           = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.ParsleySeed"]           = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.PoppySeed"]             = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.PotatoSeed"]            = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.PumpkinSeed"]           = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.RedRadishSeed"]         = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.RosemarySeed"]          = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.RoseSeed"]              = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.RyeSeed"]               = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.SageSeed"]              = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.SoybeansSeed"]          = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.SpinachSeed"]           = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.StrewberrieSeed"]       = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.SugarBeetSeed"]         = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.SweetPotatoSeed"]       = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.ThymeSeed"]             = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.TobaccoSeed"]           = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.TomatoSeed"]            = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.TurnipSeed"]            = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.WatermelonSeed"]        = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.WheatSeed"]             = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.WildGarlicSeed"]        = { Science = sciXP, Farming = farmXP, trait = gardener },
    ["Base.ZucchiniSeed"]          = { Science = sciXP, Farming = farmXP, trait = gardener },
}})


local smallCorpseXP = 15
ZScienceSkill.Data.add({ specimens = {
    -- Small animal corpses (anatomy/dissection)
    ["Base.CorpseAnimal"]  = smallCorpseXP * 2, -- generic animal corpse, same for sheep/rat/...
    ["Base.DeadRat"]       = smallCorpseXP,
    ["Base.DeadRatBaby"]   = smallCorpseXP * 0.75,
    ["Base.DeadMouse"]     = smallCorpseXP,
    ["Base.DeadMousePups"] = smallCorpseXP * 0.5,
    ["Base.DeadBird"]      = smallCorpseXP,
    ["Base.DeadSquirrel"]  = smallCorpseXP * 1.25,
}})


local seafoodXP = 10
ZScienceSkill.Data.add({ specimens = {
    -- Marine biology
    ["Base.Crayfish"] = seafoodXP,
    ["Base.Mussels"]  = seafoodXP,
    ["Base.Oysters"]  = seafoodXP,
    ["Base.Seaweed"]  = seafoodXP,
    ["Base.Shrimp"]   = seafoodXP,
    ["Base.Squid"]    = seafoodXP * 1.5,
}})

local sciXP  = 25
local knapXP = 25
ZScienceSkill.Data.add({ specimens = {
    -- Gems, minerals & geology
    ["Base.Diamond"]        = { Science = sciXP, FlintKnapping = knapXP },
    ["Base.Emerald"]        = { Science = sciXP, FlintKnapping = knapXP },
    ["Base.Ruby"]           = { Science = sciXP, FlintKnapping = knapXP },
    ["Base.Sapphire"]       = { Science = sciXP, FlintKnapping = knapXP },
    ["Base.Amethyst"]       = { Science = sciXP, FlintKnapping = knapXP },
    ["Base.Crystal"]        = { Science = sciXP, FlintKnapping = knapXP },
    ["Base.Crystal_Large"]  = { Science = sciXP * 2, FlintKnapping = knapXP * 2 },
    ["Base.LargeMeteorite"] = { Science = sciXP * 8, FlintKnapping = knapXP * 8 },  -- Rare space rock
}})


local sciXP = 10
local traXP = 15
ZScienceSkill.Data.add({ specimens = {
    -- Animal dung (tracking/scat analysis)
    ["Base.Dung_Turkey"]          = { Science = sciXP, Tracking = traXP },
    ["Base.Dung_Chicken"]         = { Science = sciXP, Tracking = traXP },
    ["Base.Dung_Cow"]             = { Science = sciXP, Tracking = traXP },
    ["Base.Dung_Deer"]            = { Science = sciXP, Tracking = traXP },
    ["Base.Dung_Mouse"]           = { Science = sciXP, Tracking = traXP },
    ["Base.Dung_Pig"]             = { Science = sciXP, Tracking = traXP },
    ["Base.Dung_Rabbit"]          = { Science = sciXP, Tracking = traXP },
    ["Base.Dung_Raccoon"]         = { Science = sciXP, Tracking = traXP },
    ["Base.Dung_Rat"]             = { Science = sciXP, Tracking = traXP },
    ["Base.Dung_Sheep"]           = { Science = sciXP, Tracking = traXP },
}})


-- cooking / household
ZScienceSkill.Data.add({ specimens = {
    ["Base.BouillonCube"]    = { Science =  5, Cooking = 10 },  -- recipe?
    ["Base.Flour2"]          = { Science =  5, Cooking = 10 },
    ["Base.SugarCubes"]      = { Science =  5, Cooking = 10 },  -- recipe?

    ["Base.BakingSoda"]      = { Science = 20, Cooking = 20, AppliedChemistry = 10 },  -- sodium bicarbonate
    ["Base.Hairspray2"]      = 10,                              -- TODO: learn recipe?
    ["Base.InsectRepellent"] = 20,
    ["Base.Vinegar2"]        = { Science = 20, Cooking = 20, key = "Base.Vinegar" },
    ["Base.Vinegar_Jug"]     = { Science = 20, Cooking = 20, key = "Base.Vinegar" },
    ["Base.Yeast"]           = { Science = 10, Cooking = 10 },
}})


-- Industrial / gas equipment
ZScienceSkill.Data.add({ specimens = {
    ["Base.BlowTorch"]      = { Science =  5, MetalWelding = 10 },
    ["Base.Extinguisher"]   =  5,
    ["Base.LighterFluid"]   =  5, -- TODO: make bomb?
    ["Base.Oxygen_Tank"]    = { Science = 25, AppliedChemistry = 10 },
    ["Base.Propane_Refill"] = 20,
    ["Base.PropaneTank"]    = { Science = 30, MetalWelding = 30 },
    ["Base.WeldingMask"]    = { Science =  5, MetalWelding = 10 },
    ["Base.WeldingRods"]    = { Science =  5, MetalWelding = 10 },
}})


-- fluids don't have "Base." prefix nor getFullType() method
ZScienceSkill.Data.add({ fluids = {
    ["Acid"]            = { Science =  50, AppliedChemistry = 25 },
    ["AnimalBlood"]     = { Science =  50, Doctor = 25, Husbandry = 25 },
    ["Bleach"]          = { Science =  30, AppliedChemistry = 10 },
    ["Blood"]           = { Science =  50, Doctor = 50 },
    ["Cologne"]         = { Science =  10 }, -- TODO: learn recipeL disinfect rags with cologne
    ["IndustrialDye"]   = { Science =  10, Maintenance = 10 },
    ["SecretFlavoring"] = { Science = 200, Cooking = 50, AppliedChemistry = 25 },
}})

-- Electronics / tech components
ZScienceSkill.Data.add({ literatureReadOnce = {
    ["Base.ElectronicsMag4"] = 20 -- how to use generators
}})
ZScienceSkill.Data.add({ specimens = {
    ["Base.CameraDisposable"]    =  5,
    ["Base.CameraExpensive"]     = 15,
    ["Base.CameraFilm"]          =  5,
    ["Base.Disc_Retail"]         = { Science =  5, Electricity =  5, Music = 5 },
    ["Base.Earbuds"]             = { Science =  5, Electricity =  5, Music = 5 },
    ["Base.ElectricWire"]        = { Science =  5, Electricity =  5 },
    ["Base.HairDryer"]           = { Science =  5, Electricity =  5 },
    ["Base.Headphones"]          = { Science =  5, Electricity =  5, Music = 5 },
    ["Base.LightBulb"]           = { Science =  5, Electricity =  5 },
    ["Base.PowerBar"]            = { Science =  5, Electricity =  5 },

    ["Base.Battery"]             = { Science = 10, Electricity = 10 },
    ["Base.BlowerFan"]           = { Science = 10, Electricity = 10 },
    ["Base.Bullhorn"]            = { Science = 10, Electricity = 10 }, -- megaphone
    ["Base.CarBattery1"]         = { Science = 10, Electricity = 10 },
    ["Base.CarBattery2"]         = { Science = 10, Electricity = 10 },
    ["Base.CarBattery3"]         = { Science = 10, Electricity = 10 },
    ["Base.CordlessPhone"]       = { Science = 10, Electricity = 10 },
    ["Base.ElectronicsScrap"]    = { Science = 10, Electricity = 10 },
    ["Base.Microphone"]          = { Science = 10, Electricity = 10, Music = 5 },
    ["Base.Remote"]              = { Science = 10, Electricity = 10 },
    ["Base.Speaker"]             = { Science = 10, Electricity = 10, Music = 5 },

    ["Base.VideoGame"]           = { Science = 10, Electricity = 15 },

    ["Base.Amplifier"]           = { Science = 15, Electricity = 20 },
    ["Base.Camera"]              = { Science = 10, Electricity = 20 },
    ["Base.CarBatteryCharger"]   = { Science = 10, Electricity = 20 },
    ["Base.CDplayer"]            = { Science = 10, Electricity = 20, Music = 5 },
    ["Base.Timer"]               = { Science =  5 },
    ["Base.TimerCrafted"]        = { Science = 15, Electricity = 20 },
    ["Base.TriggerCrafted"]      = { Science = 15, Electricity = 20 }, -- TODO: learn recipe?
    ["Base.HamRadio1"]           = { Science = 20, Electricity = 25 },
    ["Base.HamRadio2"]           = { Science = 20, Electricity = 25 },
    ["Base.HomeAlarm"]           = { Science = 15, Electricity = 20, Hacking = 15 },
    ["Base.MotionSensor"]        = { Science = 20, Electricity = 20 },
    ["Base.RadioRed"]            = { Science = 20, Electricity = 20 },
    ["Base.RadioReceiver"]       = { Science = 20, Electricity = 20 },
    ["Base.RadioTransmitter"]    = { Science = 20, Electricity = 20 },
    ["Base.Receiver"]            = { Science = 20, Electricity = 20 }, -- seems like there are both Receiver and RadioReceiver
    ["Base.RemoteCraftedV1"]     = { Science = 10, Electricity = 10 },
    ["Base.RemoteCraftedV2"]     = { Science = 15, Electricity = 15 },
    ["Base.RemoteCraftedV3"]     = { Science = 20, Electricity = 20 },
    ["Base.ScannerModule"]       = { Science = 20, Electricity = 20 },
    ["Base.SheepElectricShears"] = { Science =  5, Electricity =  5 },

    ["Base.WalkieTalkie1"]       = { Science = 20, Electricity = 20, key = "Base.WalkieTalkie" },
    ["Base.WalkieTalkie2"]       = { Science = 20, Electricity = 20, key = "Base.WalkieTalkie" },
    ["Base.WalkieTalkie3"]       = { Science = 20, Electricity = 20, key = "Base.WalkieTalkie" },
    ["Base.WalkieTalkie4"]       = { Science = 20, Electricity = 20, key = "Base.WalkieTalkie" },
    ["Base.WalkieTalkie5"]       = { Science = 20, Electricity = 20, key = "Base.WalkieTalkie" },

    ["Base.Generator"]           = { Science = 15, Electricity = 30 }, -- TODO: learn generators use from 2 gens?

    -- movables)))
    ["Base.appliances_com_01_47"] = { Science = 25, Electricity = 25 }, -- big camera
    ["Base.Mov_DesktopComputer"]  = { Science = 25, Electricity = 25 },
    ["Base.Mov_SatelliteDish"]    = { Science = 25, Electricity = 25 },

    ["Base.location_community_medical_01_136"] = { Science = 25, key = "microscope" },
    ["Base.location_community_medical_01_137"] = { Science = 25, key = "microscope" },
    ["Base.location_community_medical_01_138"] = { Science = 25, key = "microscope" },
    ["Base.location_community_medical_01_139"] = { Science = 25, key = "microscope" },
}})


-- metals
local sciXP = 10
local blkXP = 20
local metals = {
    Aluminum = { "Aluminum", "AluminumFragments", "AluminumScrap" },
    Brass    = { "BrassIngot", "BrassScrap", "Needle_Brass", "BrassNameplate" },
    Bronze   = { "TrophyBronze", "Medal_Bronze" },
    Copper   = { "CopperOre", "CopperIngot", "CopperSheet", "SmallCopperSheet", "CopperScrap" },
    Gold     = { "GoldBar", "SmallGoldBar", "GoldScrap", "GoldSheet", "GoldCoin", "Medal_Gold", "TrophyGold" },
    Iron     = { "IronBar", "IronBarHalf", "IronBarQuarter", "IronBlock", "IronChunk", "IronIngot", "IronOre", "IronPiece", "IronScrap" },
    Lead     = { "LeadPipe" },
    Silver   = { "SilverBar", "SmallSilverBar", "SilverScrap", "SilverSheet", "SilverCoin", "Spoon_Silver", "TrophySilver", "Medal_Silver", "Hat_HockeyMask_Silver" },
    Steel    = { "MetalBar", "SteelBar", "SteelBarHalf", "SteelBarQuarter", "SteelBlock", "SteelChunk", "SteelIngot", "SteelPiece", "SteelScrap", "SteelSlug" },
    Tin      = { "TinCanEmpty" },
}
for metal, variants in pairs(metals) do
    local metalKey = "Base." .. metal
    for _, variant in ipairs(variants) do
        ZScienceSkill.Data.add({ specimens = {
            ["Base." .. variant] = { Science = sciXP, Blacksmith = blkXP, key = metalKey, trait = blacksmith }
        }})
    end
end


-- Glassmaking
ZScienceSkill.Data.add({ specimens = {
    ["Base.BrokenGlass"]              = { Science = 10, Glassmaking = 20 }, -- TODO: learn recipe
    ["Base.GlassBlowingPipe"]         = { Science = 10, Glassmaking = 20 },
    ["Base.GlassBlowingPipeUnfired"]  = { Science = 10, Glassmaking = 20, key = "Base.GlassBlowingPipe" },
    ["Base.GlassPanel"]               = { Science =  5, Glassmaking = 20 },
    ["Base.Loupe"]                    = { Science = 10, Glassmaking = 10 },
    ["Base.MagnifyingGlass"]          = { Science = 15, Glassmaking = 15 },
}})


-- maintenance stuff
ZScienceSkill.Data.add({ specimens = {
    ["Base.CorrectionFluid"]   = { Science =  5 },
    ["Base.Epoxy"]             = { Science = 10, Maintenance = 15 },
    ["Base.FiberglassTape"]    = { Science = 10, Maintenance = 15 },
    ["Base.Plunger"]           = { Science =  1, Maintenance = 25 }, -- ^_^
    ["Base.RespiratorFilters"] = { Science =  5, Maintenance = 10 },
    ["Base.SteelWool"]         = { Science =  5, Maintenance = 10 },
    ["Base.Whetstone"]         = { Science =  5, Maintenance = 10 },
    ["Base.WoodGlue"]          = { Science =  5, Maintenance =  5, Woodwork =  5 },
}})


-- Mechanics and stuff
ZScienceSkill.Data.add({ specimens = {
    ["Base.Bellows"]            = { Mechanics =  5, Blacksmith = 5 },
    ["Base.BenchAnvil"]         = { Blacksmith = 20 },
    ["Base.CarpentryChisel"]    = { Woodwork = 10 },
    ["Base.CircularSawblade"]   = { Woodwork = 10 },
    ["Base.CombinationPadlock"] = { Mechanics = 10, Science =  5 },
    ["Base.Doorknob"]           = { Mechanics =  1, Woodwork = 5 },
    ["Base.EngineParts"]        = { Mechanics = 20, Science = 10, Maintenance = 10 },
    ["Base.File"]               = { Mechanics =  5 },
    ["Base.HandDrill"]          = { Mechanics = 10, Woodwork = 10, Science = 5 },
    ["Base.Hinge"]              = { Mechanics =  5, Woodwork = 5 },
    ["Base.Jack"]               = { Mechanics = 10 },
    ["Base.LargeHook"]          = { Mechanics =  5 },
    ["Base.LugWrench"]          = { Mechanics =  5 },
    ["Base.Padlock"]            = { Mechanics = 10, Science =  5 },
    ["Base.PipeWrench"]         = { Mechanics = 10, Maintenance = 10 },
    ["Base.Pliers"]             = { Mechanics = 10, Science =  5 },
    ["Base.Ratchet"]            = { Mechanics = 15, Science =  5 },
    ["Base.TireIron"]           = { Mechanics =  5 },
    ["Base.TirePump"]           = { Mechanics = 15, Science = 10 },
    ["Base.SheetMetalSnips"]    = { Mechanics = 10, Science =  5 },
    ["Base.ViseGrips"]          = { Mechanics =  5, Blacksmith = 5 },
    ["Base.Wrench"]             = { Mechanics = 10, Science =  5 },

    ["Base.Pocketwatch"]                   = { Mechanics = 5, Science = 5 },
    ["Base.WristWatch_Left_ClassicBrown"]  = { Mechanics = 5, Science = 5, key = "Base.WristWatch" },
    ["Base.WristWatch_Right_ClassicBrown"] = { Mechanics = 5, Science = 5, key = "Base.WristWatch" },
}})


-- Trapping
ZScienceSkill.Data.add({ specimens = {
    ["Base.RatPoison"]      = { Science =  5, Trapping =  5 }, -- recipes?
    ["Base.TrapCage"]       = { Science =  5, Trapping = 15 },
    ["Base.TrapMouse"]      = { Science =  5, Trapping = 10 },
}})


-- science stuff
ZScienceSkill.Data.add({ specimens = {
    ["Base.Calipers"]           = { Science = 20, Mechanics = 20 },
    ["Base.CompassDirectional"] = { Science = 20, Tracking = 10 },
    ["Base.CompassGeometry"]    = { Science = 20 },
    ["Base.LighterBBQ"]         = { Science =  5 },
    ["Base.Sparklers"]          = { Science = 10 },
}})


-- Masonry
ZScienceSkill.Data.add({ specimens = {
    ["Base.Clay"]            = { Science = 5, Masonry = 15 },
}})


-- Tailoring
ZScienceSkill.Data.add({ specimens = {
    ["Base.Buckle"]                       = { Science =  1, Tailoring =  5 },
    ["Base.BurlapPiece"]                  = { Science =  2, Tailoring = 10 },
    ["Base.CheeseCloth"]                  = { Science =  2, Tailoring =  5 },
    ["Base.Dogbane"]                      = { Science =  2, Tailoring = 10 },
    ["Base.MeasuringTape"]                = { Science =  1, Tailoring = 10 },
    ["Base.RubberStrips"]                 = { Tailoring = 5 },
    ["Base.Tarp"]                         = { Science =  2, Tailoring =  7 },
    ["Base.Thimble"]                      = { Tailoring =  5 },
    ["Base.Thread_Aramid"]                = { Science = 10, Tailoring = 15 },
    ["Base.Thread_Sinew"]                 = { Science =  5, Tailoring =  5 },
    ["Base.Twine"]                        = { Science =  2, Tailoring =  5 },
    ["Base.Yarn"]                         = { Science =  2, Tailoring =  5 },

    ["Base.Fleshing_Tool"]                = { Tailoring = 10 },

    ["Base.DeerLeather_Fur_Tan"]          = { Science = 10, Tailoring = 15 }, -- TODO: convert to scraps / other leather types

    ["Base.Leather_Crude_Medium"]         = { Science = 10, Tailoring = 10 },
    ["Base.Leather_Crude_Medium_Tan"]     = { Science = 10, Tailoring = 10 },
    ["Base.Leather_Crude_Medium_Tan_Wet"] = { Science = 10, Tailoring = 10 },

    ["Base.crafted_04_36"]                = { Science = 5, Tailoring = 20, key = "spinning_wheel" },
    ["Base.crafted_04_37"]                = { Science = 5, Tailoring = 20, key = "spinning_wheel" },
    ["Base.crafted_04_38"]                = { Science = 5, Tailoring = 20, key = "spinning_wheel" },
    ["Base.crafted_04_39"]                = { Science = 5, Tailoring = 20, key = "spinning_wheel" },
}})


-- Animal Care
ZScienceSkill.Data.add({ specimens = {
    ["Base.AnimalFeedBag"]    = { Science = 5, Husbandry = 10 }, -- recipe?
    ["Base.AnimalMilkPowder"] = { Science = 5, Husbandry = 10, Cooking = 5 },
    ["Base.GrassTuft"]        = { Science = 5, Husbandry = 10 },
    ["Base.HayTuft"]          = { Science = 5, Husbandry = 10 },
    ["Base.Mov_SaltLick"]     = { Science = 5, Husbandry = 20 }, -- craft salt for preserved food?
}})


-- Fishing
ZScienceSkill.Data.add({ specimens = {
    ["Base.Bobber"]             = { Science = 1, Fishing = 10 },
    ["Base.JigLure"]            = { Science = 1, Fishing = 10 },
    ["Base.FishingHook"]        = { Science = 1, Fishing = 10 },
    ["Base.FishingLine"]        = { Science = 1, Fishing = 10 },
    ["Base.FishingNet"]         = { Science = 1, Fishing = 20 }, -- recipes?
    ["Base.FishingRod"]         = { Science = 5, Fishing = 20 },
    ["Base.MinnowLure"]         = { Science = 1, Fishing = 10 },
    ["Base.PremiumFishingLine"] = { Science = 1, Fishing = 15 },
}})


-- Music
ZScienceSkill.Data.add({ specimens = {
    ["Base.Banjo"]              = { Science =  5, Music = 10 },
    ["Base.Flute"]              = { Science =  5, Music = 10 },
    ["Base.GuitarAcoustic"]     = { Science =  5, Music = 10 },
    ["Base.GuitarElectric"]     = { Science =  5, Music = 10, Electricity = 10 },
    ["Base.GuitarElectricBass"] = { Science =  5, Music = 10, Electricity = 10 },
    ["Base.Keytar"]             = { Science =  5, Music = 10 },
    ["Base.Saxophone"]          = { Science =  5, Music = 10 },
    ["Base.Trumpet"]            = { Science =  5, Music = 10 },
    ["Base.TuningFork"]         = { Science = 15, Music = 20 },
    ["Base.Violin"]             = { Science = 10, Music = 15 },

    ["Base.Drumstick"]          = { Science =  1, Music = 10 }, -- recipe?
    ["Base.GuitarPick"]         = { Science =  1, Music = 10 },
    ["Base.Harmonica"]          = { Science =  1, Music = 10 },
}})


-- lulz
ZScienceSkill.Data.add({ specimens = {
    ["Base.BorisBadger"]     = { randomPerk =  50 },
    ["Base.EyeOfCthulhu"]    = { randomPerk = 200 },
    ["Base.FreddyFox"]       = { randomPerk =  50 },
    ["Base.MoleyMole"]       = { randomPerk =  50 },
    ["Base.PanchoDog"]       = { randomPerk =  50 },
    ["Base.PancakeHedgehog"] = { randomPerk =  50 },
}})
