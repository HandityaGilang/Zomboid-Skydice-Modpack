AnimalDefinitions.stages["smokeykttr"] = {
    stages = {
        ["babysmokeykitten"] = {
            ageToGrow = 2 * 30, 
            nextStage = "smokeygirly",
            nextStageMale = "smokeyboi",
            minWeight = 0.1,
            maxWeight = 0.25
        },
        ["smokeygirly"] = {
            minWeight = 0.25,
            maxWeight = 0.5
        },
        ["smokeyboi"] = {
            minWeight = 0.25,
            maxWeight = 0.5
        }
    }
}

AnimalDefinitions.genome["smokeykttr"] = {
    genes = {
        ["maxSize"] = "maxSize",
        ["meatRatio"] = "meatRatio",
        ["maxWeight"] = "maxWeight",
        ["lifeExpectancy"] = "lifeExpectancy",
        ["resistance"] = "resistance",
        ["strength"] = "strength",
        ["hungerResistance"] = "hungerResistance",
        ["thirstResistance"] = "thirstResistance",
        ["aggressiveness"] = "aggressiveness",
        ["ageToGrow"] = "ageToGrow",
        ["fertility"] = "fertility",
        ["stress"] = "stress",
        ["swiftness"] = "swiftness",
        ["endurance"] = "endurance",
        ["haulingCapacity"] = "haulingCapacity",
        ["vitality"] = "vitality"
    }
}


AnimalDefinitions.breeds["smokeykttr"] = {
    breeds = {
        ["midnight"] = {
            name = "midnight",
            texture = "KittyMod/CATTO_SMOKEYTUX",
            textureMale = "KittyMod/CATTO_SMOKEYTUX",
            rottenTexture = "KittyMod/CATTO_SMOKEYTUX",
            textureBaby = "KittyMod/CATTO_SMOKEYTUX",
            invIconMale = "Item_DeerMale_Dead",
            invIconFemale = "Item_DeerFemale_Dead",
            invIconBaby = "Item_DeerFawn_Dead",
            invIconMaleDead = "Item_DeerMale_Dead",
            invIconFemaleDead = "Item_DeerFemale_Dead",
            invIconBabyDead = "Item_DeerFawn_Dead",
        }
    }
}

AnimalDefinitions.breeds["smokeykttr"].breeds["midnight"] = {};
AnimalDefinitions.breeds["smokeykttr"].breeds["midnight"].name = "midnight";
AnimalDefinitions.breeds["smokeykttr"].breeds["midnight"].texture = "KittyMod/CATTO_SMOKEYTUX";
AnimalDefinitions.breeds["smokeykttr"].breeds["midnight"].textureMale = "KittyMod/CATTO_SMOKEYTUX";
AnimalDefinitions.breeds["smokeykttr"].breeds["midnight"].textureBaby = "KittyMod/CATTO_SMOKEYTUX";
AnimalDefinitions.breeds["smokeykttr"].breeds["midnight"].rottenTexture = "KittyMod/CATTO_SMOKEYTUX";
AnimalDefinitions.breeds["smokeykttr"].breeds["midnight"].invIconMale = "Item_CATTO";
AnimalDefinitions.breeds["smokeykttr"].breeds["midnight"].invIconFemale = "Item_CATTO";
AnimalDefinitions.breeds["smokeykttr"].breeds["midnight"].invIconBaby = "Item_CATTO";
AnimalDefinitions.breeds["smokeykttr"].breeds["midnight"].invIconMaleDead = "Item_CATTO";
AnimalDefinitions.breeds["smokeykttr"].breeds["midnight"].invIconFemaleDead = "Item_CATTO";
AnimalDefinitions.breeds["smokeykttr"].breeds["midnight"].invIconBabyDead = "Item_CATTO";
AnimalDefinitions.breeds["smokeykttr"].breeds["midnight"].invIconMaleSkel = "Item_CATTO";
AnimalDefinitions.breeds["smokeykttr"].breeds["midnight"].invIconFemaleSkel = "Item_CATTO";
AnimalDefinitions.breeds["smokeykttr"].breeds["midnight"].invIconBabySkel = "Item_CATTO";
AnimalDefinitions.breeds["smokeykttr"].breeds["midnight"].forcedGenes = {};


AnimalDefinitions.animals["babysmokeykitten"] = {
    bodyModel = "KittyMod.SMOKEY";
    bodyModelSkel = "KittyMod.SMOKEY";
    textureSkeleton = "KittyMod.SMOKEY";
    textureSkeletonBloody = "KittyMod.SMOKEY";
    bodyModelSkelNoHead = "KittyMod.SMOKEY";
    animset = "turkeypoult", 
    animalSize = 0.1;
    modelscript = "KittyMod.SMOKEY";
    shadoww = 0.3;
    shadowfm = 0.3;
    shadowbm = 0.3;
    wanderMul = 250;
    breeds = copyTable(AnimalDefinitions.breeds["smokeykttr"].breeds);
    stages = AnimalDefinitions.stages["smokeykttr"].stages;
    genes = AnimalDefinitions.genome["smokeykttr"].genes;
    minSize = 0.15;
    maxSize = 0.35;
    alwaysFleeHumans = false;
    canBePicked = true;
    collidable = false;
    sitRandomly = false;
    idleTypeNbr = 2;
    idleEmoteChance = 700;
    wild = false;
    spottingDist = 15;
    canClimbStairs = true;
    group = "smokeykttr";
    canBeAlerted = true;
    distToEat = 1;
    eatTypeTrough = {
        "Base.CannedSardinesOpen", "Base.HamSlice", "Base.Bacon", "Base.CatTreats", "Base.CatFoodBag", "Base.Caviar", "Base.Steak", "Base.Venison",
        "Base.Rabbitmeat", "Base.TunaTinOpen", "Base.CannedMilkOpen", "Base.DogfoodOpen", "Base.CannedBologneseOpen", "Base.BaconBits", "Base.BaconRashers",
        "Base.Baloney", "Base.BaloneySlice", "Base.Beef", "Base.BeefJerky", "Base.CannedCornedBeefOpen", "Base.BeefJerky", "Base.MeatPatty", "Base.ChickenWhole",
        "Base.ChickenFillet", "Base.Chicken", "Base.ChickenNuggets", "Base.ChickenWings", "Base.MincedMeat", "Base.Ham", "Base.HamSlice", "Base.Hotdog_single", "Base.MeatDumpling",
        "Base.MuttonChop", "Base.Pepperoni", "Base.Pork", "Base.PorkChop", "Base.Salami", "Base.SalamiSlice", "Base.Sausage", "Base.TurkeyWhole", "Base.TurkeyFillet",
        "Base.TurketLegs", "Base.TurkeyWings", "Base.Venison", "Base.DeadBird", "Base.DeadMouse", "Base.DeadRabbit", "Base.DeadRat", "Base.DeadSquirrel", "Base.FrogMeat",
        "Base.DeadMousePups", "Base.DeadRatBaby", "Base.RatKing", "Base.Smallanimalmeat", "Base.DeadMouseSkinned", "Base.DeadMousePupsSkinned", "Base.DeadRatSkinned",
        "Base.DeadRatBabySkinned", "Base.Smallbirdmeat", "Base.AligatorGar", "Base.Frozen_FishFingers", "Base.BlackCrappie", "Base.BlueCatfish", "Base.Bluegill", "Base.ChannelCatfish",
        "Base.Crayfish", "Base.FishFried", "Base.FishFillet", "Base.FishFingers", "Base.FishRoe", "Base.SushiFish", "Base.FlatheadCatfish", "Base.FreshwaterDrum", "Base.ShrimpFried",
        "Base.ShrimpFriedCraft", "Base.GreenSunfish", "Base.LargemouthBass", "Base.BaitFish", "Base.Lobster", "Base.Muskellunge", "Base.Mussels", "Base.Oysters", "Base.OystersFried", "Base.Paddlefish",
        "Base.RedearSunfish", "Base.Salmon", "Base.Sauger", "Base.Shrimp", "Base.ShrimpDumpling", "Base.SmallmouthBass", "Base.SpottedBass", "Base.Squid", "Base.SquidCalamari", "Base.StripedBass",
        "Base.Walleye", "Base.WhiteBass", "Base.WhiteCrappie", "Base.YellowPerch", "Base.EggPoached", "Base.EggBoiled", "Base.EggScrambled", "Base.EggOmelette", "Base.AmericanLadyCaterpillar",
        "Base.BandedWoolyBearCaterpillar", "Base.MonarchCaterpillar", "Base.SawflyLarva", "Base.SilkMothCaterpillar", "Base.SwallowtailCaterpillar", "Base.Centipede", "Base.Centipede2", "Base.Cockroach",
        "Base.Cricket", "Base.Grasshopper", "Base.Ladybug", "Base.Millipede", "Base.Millipede2", "Base.Snail", "Base.WatermelonSliced", "Base.WatermelonSmashed",
        "Base.ChickenFoot", "Base.Corndog", "Base.Croissant", "Base.DehydratedMeatStick", "Base.DogFoodBag", "Base.SushiEgg", "Base.ChickenFried", "Base.MeatSteamBun",
        "Base.PorkRinds", "Base.Processedcheese", "Base.Tadpole"
        };
    canBeDomesticated = true;
    canThump = false;
    corpseSize = 1;
    minBlood = 200;
    maxBlood = 600;
    trailerBaseSize = 100;
    eatGrass = true;
    dontAttackOtherMale = true;
    ropeBone = "Bip01_Neck";
    attackDist = 2;
    knockdownAttack = true;
    attackIfStressed = true;
    attackBack = true;
    canBePet = true;
    collisionSize = 1;
    baseEncumbrance = 2;
    minWeight = 2;
    maxWeight = 4;
    featherItem = "Base.ChickenFeather";
    maxFeather = 1;
    canBeFeedByHand = true;
    stressAboveGround = false;
    litterEatTogether = true;
    stressUnderRain = false;
    canClimbFences = true;
    NeedMom = false;
}














AnimalDefinitions.animals["smokeyboi"] = {
    bodyModel = "KittyMod.SMOKEY";
    bodyModelSkel = "KittyMod.SMOKEY";
    textureSkeleton = "KittyMod.SMOKEY";
    textureSkeletonBloody = "KittyMod.SMOKEY";
    bodyModelSkelNoHead = "KittyMod.SMOKEY";
    animset = "turkeypoult";
    modelscript = "KittyMod.SMOKEY";
    bodyModelHeadless = "KittyMod.SMOKEY";
    textureSkinned = "KittyMod/SMOKEY";
    shadoww = 0.3;
    shadowfm = 0.3;
    shadowbm = 0.3;
    minSize = 0.35;
    maxSize = 0.62;
    animalSize = 0.3;
    breeds = copyTable(AnimalDefinitions.breeds["smokeykttr"].breeds);
    stages = AnimalDefinitions.stages["smokeykttr"].stages;
    genes = AnimalDefinitions.genome["smokeykttr"].genes;
    mate = "smokeygirly";
    canBePicked = true;
    canBeKilledWithoutWeapon = true;
    hungerMultiplier = 0.0001;
    thirstMultiplier = 0.0002;
    distToEat = 1;
    eatTypeTrough = {
        "Base.CannedSardinesOpen", "Base.HamSlice", "Base.Bacon", "Base.CatTreats", "Base.CatFoodBag", "Base.Caviar", "Base.Steak", "Base.Venison",
        "Base.Rabbitmeat", "Base.TunaTinOpen", "Base.CannedMilkOpen", "Base.DogfoodOpen", "Base.CannedBologneseOpen", "Base.BaconBits", "Base.BaconRashers",
        "Base.Baloney", "Base.BaloneySlice", "Base.Beef", "Base.BeefJerky", "Base.CannedCornedBeefOpen", "Base.BeefJerky", "Base.MeatPatty", "Base.ChickenWhole",
        "Base.ChickenFillet", "Base.Chicken", "Base.ChickenNuggets", "Base.ChickenWings", "Base.MincedMeat", "Base.Ham", "Base.HamSlice", "Base.Hotdog_single", "Base.MeatDumpling",
        "Base.MuttonChop", "Base.Pepperoni", "Base.Pork", "Base.PorkChop", "Base.Salami", "Base.SalamiSlice", "Base.Sausage", "Base.TurkeyWhole", "Base.TurkeyFillet",
        "Base.TurketLegs", "Base.TurkeyWings", "Base.Venison", "Base.DeadBird", "Base.DeadMouse", "Base.DeadRabbit", "Base.DeadRat", "Base.DeadSquirrel", "Base.FrogMeat",
        "Base.DeadMousePups", "Base.DeadRatBaby", "Base.RatKing", "Base.Smallanimalmeat", "Base.DeadMouseSkinned", "Base.DeadMousePupsSkinned", "Base.DeadRatSkinned",
        "Base.DeadRatBabySkinned", "Base.Smallbirdmeat", "Base.AligatorGar", "Base.Frozen_FishFingers", "Base.BlackCrappie", "Base.BlueCatfish", "Base.Bluegill", "Base.ChannelCatfish",
        "Base.Crayfish", "Base.FishFried", "Base.FishFillet", "Base.FishFingers", "Base.FishRoe", "Base.SushiFish", "Base.FlatheadCatfish", "Base.FreshwaterDrum", "Base.ShrimpFried",
        "Base.ShrimpFriedCraft", "Base.GreenSunfish", "Base.LargemouthBass", "Base.BaitFish", "Base.Lobster", "Base.Muskellunge", "Base.Mussels", "Base.Oysters", "Base.OystersFried", "Base.Paddlefish",
        "Base.RedearSunfish", "Base.Salmon", "Base.Sauger", "Base.Shrimp", "Base.ShrimpDumpling", "Base.SmallmouthBass", "Base.SpottedBass", "Base.Squid", "Base.SquidCalamari", "Base.StripedBass",
        "Base.Walleye", "Base.WhiteBass", "Base.WhiteCrappie", "Base.YellowPerch", "Base.EggPoached", "Base.EggBoiled", "Base.EggScrambled", "Base.EggOmelette", "Base.AmericanLadyCaterpillar",
        "Base.BandedWoolyBearCaterpillar", "Base.MonarchCaterpillar", "Base.SawflyLarva", "Base.SilkMothCaterpillar", "Base.SwallowtailCaterpillar", "Base.Centipede", "Base.Centipede2", "Base.Cockroach",
        "Base.Cricket", "Base.Grasshopper", "Base.Ladybug", "Base.Millipede", "Base.Millipede2", "Base.Snail", "Base.WatermelonSliced", "Base.WatermelonSmashed",
        "Base.ChickenFoot", "Base.Corndog", "Base.Croissant", "Base.DehydratedMeatStick", "Base.DogFoodBag", "Base.SushiEgg", "Base.ChickenFried", "Base.MeatSteamBun",
        "Base.PorkRinds", "Base.Processedcheese", "Base.Tadpole"
        };
    minAge = AnimalDefinitions.stages["smokeykttr"].stages["babysmokeykitten"].ageToGrow;
    maxAgeGeriatric = 19 * 30;
    minAgeForBaby = 10;
    babyType = "babysmokeykitten";
    wanderMul = 200;
    sitRandomly = true;
    canClimbStairs = true;
    idleTypeNbr = 2;
    idleEmoteChance = 700;
    wild = false;
    spottingDist = 19;
    group = "smokeykttr";
    canBeAlerted = true;
    canBeDomesticated = true;
    canThump = false;
    corpseSize = 1;
    minBlood = 800;
    maxBlood = 2500;
    male = true;
    trailerBaseSize = 300;
    eatGrass = true;
    dontAttackOtherMale = true;
    ropeBone = "Bip01_Neck";
    attackDist = 2;
    knockdownAttack = true;
    attackIfStressed = true;
    attackBack = true;
    canBePet = true;
    collisionSize = 1;
    baseEncumbrance = 3;
    minWeight = 1;
    maxWeight = 3;
    featherItem = "Base.ChickenFeather";
    maxFeather = 1;
}
--[[
AnimalDefinitions.animals["smokeygirly"] = {
    bodyModel = "KittyMod.Dynamix";
    bodyModelSkel = "KittyMod.Dynamix";
    textureSkeleton = "KittyMod.Dynamix";
    textureSkeletonBloody = "KittyMod.Dynamix";
    bodyModelSkelNoHead = "KittyMod.Dynamix";
    animset = "doe"; 
    modelscript = "KittyMod.Dynamix";
    bodyModelHeadless = "KittyMod.Dynamix";
    textureSkinned = "KittyMod/Dynamix";
    shadoww = 0.3;
    shadowfm = 0.3;
    shadowbm = 0.3;
    minSize = 0.35;
    maxSize = 0.75;
    animalSize = 0.3;
    breeds = copyTable(AnimalDefinitions.breeds["kttr"].breeds);
    stages = AnimalDefinitions.stages["kttr"].stages;
    genes = AnimalDefinitions.genome["kttr"].genes;
    mate = "tom";
    canBePicked = true;
    minAge = AnimalDefinitions.stages["kttr"].stages["babykitten"].ageToGrow;
    maxAgeGeriatric = 19 * 30;
    minAgeForBaby = 10;
    pregnantPeriod = 1;
    babyType = "babykitten";
    wanderMul = 200;
    sitRandomly = false;
    idleTypeNbr = 2;
    idleEmoteChance = 700;
    wild = false;
    spottingDist = 19;
    canClimbStairs = true;
    group = "kttr";
    canBeAlerted = true;
    canBeDomesticated = true;
    canThump = false;
    corpseSize = 1;
    minBlood = 800;
    distToEat = 1;
    maxBlood = 2500;
    female = true;
    trailerBaseSize = 300;
    eatGrass = true;
    dontAttackOtherMale = true;
    ropeBone = "Bip01_Neck";
    attackDist = 2;
    knockdownAttack = true;
    attackIfStressed = true;
    attackBack = true;
    canBePet = true;
    collisionSize = 1;
    baseEncumbrance = 2;
    minWeight = 2;
    maxWeight = 4;
}
--]]

AnimalDefinitions.animals["smokeygirly"] = { };
AnimalDefinitions.animals["smokeygirly"].bodyModel = "KittyMod.SMOKEY";
AnimalDefinitions.animals["smokeygirly"].bodyModelSkel = "KittyMod.SMOKEY";
AnimalDefinitions.animals["smokeygirly"].textureSkeleton = "KittyMod.SMOKEY";
AnimalDefinitions.animals["smokeygirly"].textureSkeletonBloody = "KittyMod.SMOKEY";
AnimalDefinitions.animals["smokeygirly"].bodyModelSkelNoHead = "KittyMod.SMOKEY";
AnimalDefinitions.animals["smokeygirly"].animset = "turkeypoult";
AnimalDefinitions.animals["smokeygirly"].shadoww = 0.2;
AnimalDefinitions.animals["smokeygirly"].shadowfm = 0.2;
AnimalDefinitions.animals["smokeygirly"].shadowbm = 0.2;
AnimalDefinitions.animals["smokeygirly"].wanderMul = 250;
AnimalDefinitions.animals["smokeygirly"].textureSkinned = "KittyMod/SMOKEY";
AnimalDefinitions.animals["smokeygirly"].breeds = copyTable(AnimalDefinitions.breeds["smokeykttr"].breeds);
AnimalDefinitions.animals["smokeygirly"].stages = AnimalDefinitions.stages["smokeykttr"].stages;
AnimalDefinitions.animals["smokeygirly"].genes = AnimalDefinitions.genome["smokeykttr"].genes;
AnimalDefinitions.animals["smokeygirly"].babyType = "babysmokeykitten";
AnimalDefinitions.animals["smokeygirly"].minSize = 0.4
AnimalDefinitions.animals["smokeygirly"].maxSize = 0.59;
AnimalDefinitions.animals["smokeygirly"].hungerMultiplier = 0.00008;
AnimalDefinitions.animals["smokeygirly"].thirstMultiplier = 0.00016;
AnimalDefinitions.animals["smokeygirly"].alwaysFleeHumans = false;
AnimalDefinitions.animals["smokeygirly"].collidable = false;
AnimalDefinitions.animals["smokeygirly"].group = "smokeykttr";
AnimalDefinitions.animals["smokeygirly"].canBePicked = true;
AnimalDefinitions.animals["smokeygirly"].canBeKilledWithoutWeapon = true;
AnimalDefinitions.animals["smokeygirly"].canBePet = true;
AnimalDefinitions.animals["smokeygirly"].wild = false;
AnimalDefinitions.animals["smokeygirly"].idleTypeNbr = 2;
AnimalDefinitions.animals["smokeygirly"].canClimbStairs = true;
AnimalDefinitions.animals["smokeygirly"].eatTypeTrough = "All";
AnimalDefinitions.animals["smokeygirly"].needMom = false;
AnimalDefinitions.animals["smokeygirly"].dontAttackOtherMale = true;
AnimalDefinitions.animals["smokeygirly"].trailerBaseSize = 10;
AnimalDefinitions.animals["smokeygirly"].minWeight = 0.1;
AnimalDefinitions.animals["smokeygirly"].maxWeight = 0.3;
AnimalDefinitions.animals["smokeygirly"].animalSize = 0;
AnimalDefinitions.animals["smokeygirly"].attackDist = 0;
AnimalDefinitions.animals["smokeygirly"].attackTimer = 1500;
AnimalDefinitions.animals["smokeygirly"].baseEncumbrance = 5;
AnimalDefinitions.animals["smokeygirly"].canThump = false;
AnimalDefinitions.animals["smokeygirly"].minEnclosureSize = 20;
AnimalDefinitions.animals["smokeygirly"].hungerBoost = 25;
AnimalDefinitions.animals["smokeygirly"].thirstBoost = 30;
AnimalDefinitions.animals["smokeygirly"].thirstHungerTrigger = 0.1;
AnimalDefinitions.animals["smokeygirly"].distToEat = 1;
AnimalDefinitions.animals["smokeygirly"].eatTypeTrough = {
        "Base.CannedSardinesOpen", "Base.HamSlice", "Base.Bacon", "Base.CatTreats", "Base.CatFoodBag", "Base.Caviar", "Base.Steak", "Base.Venison",
        "Base.Rabbitmeat", "Base.TunaTinOpen", "Base.CannedMilkOpen", "Base.DogfoodOpen", "Base.CannedBologneseOpen", "Base.BaconBits", "Base.BaconRashers",
        "Base.Baloney", "Base.BaloneySlice", "Base.Beef", "Base.BeefJerky", "Base.CannedCornedBeefOpen", "Base.BeefJerky", "Base.MeatPatty", "Base.ChickenWhole",
        "Base.ChickenFillet", "Base.Chicken", "Base.ChickenNuggets", "Base.ChickenWings", "Base.MincedMeat", "Base.Ham", "Base.HamSlice", "Base.Hotdog_single", "Base.MeatDumpling",
        "Base.MuttonChop", "Base.Pepperoni", "Base.Pork", "Base.PorkChop", "Base.Salami", "Base.SalamiSlice", "Base.Sausage", "Base.TurkeyWhole", "Base.TurkeyFillet",
        "Base.TurketLegs", "Base.TurkeyWings", "Base.Venison", "Base.DeadBird", "Base.DeadMouse", "Base.DeadRabbit", "Base.DeadRat", "Base.DeadSquirrel", "Base.FrogMeat",
        "Base.DeadMousePups", "Base.DeadRatBaby", "Base.RatKing", "Base.Smallanimalmeat", "Base.DeadMouseSkinned", "Base.DeadMousePupsSkinned", "Base.DeadRatSkinned",
        "Base.DeadRatBabySkinned", "Base.Smallbirdmeat", "Base.AligatorGar", "Base.Frozen_FishFingers", "Base.BlackCrappie", "Base.BlueCatfish", "Base.Bluegill", "Base.ChannelCatfish",
        "Base.Crayfish", "Base.FishFried", "Base.FishFillet", "Base.FishFingers", "Base.FishRoe", "Base.SushiFish", "Base.FlatheadCatfish", "Base.FreshwaterDrum", "Base.ShrimpFried",
        "Base.ShrimpFriedCraft", "Base.GreenSunfish", "Base.LargemouthBass", "Base.BaitFish", "Base.Lobster", "Base.Muskellunge", "Base.Mussels", "Base.Oysters", "Base.OystersFried", "Base.Paddlefish",
        "Base.RedearSunfish", "Base.Salmon", "Base.Sauger", "Base.Shrimp", "Base.ShrimpDumpling", "Base.SmallmouthBass", "Base.SpottedBass", "Base.Squid", "Base.SquidCalamari", "Base.StripedBass",
        "Base.Walleye", "Base.WhiteBass", "Base.WhiteCrappie", "Base.YellowPerch", "Base.EggPoached", "Base.EggBoiled", "Base.EggScrambled", "Base.EggOmelette", "Base.AmericanLadyCaterpillar",
        "Base.BandedWoolyBearCaterpillar", "Base.MonarchCaterpillar", "Base.SawflyLarva", "Base.SilkMothCaterpillar", "Base.SwallowtailCaterpillar", "Base.Centipede", "Base.Centipede2", "Base.Cockroach",
        "Base.Cricket", "Base.Grasshopper", "Base.Ladybug", "Base.Millipede", "Base.Millipede2", "Base.Snail", "Base.WatermelonSliced", "Base.WatermelonSmashed",
        "Base.ChickenFoot", "Base.Corndog", "Base.Croissant", "Base.DehydratedMeatStick", "Base.DogFoodBag", "Base.SushiEgg", "Base.ChickenFried", "Base.MeatSteamBun",
        "Base.PorkRinds", "Base.Processedcheese", "Base.Tadpole"
        };
AnimalDefinitions.animals["smokeygirly"].turnDelta = 0.95;
AnimalDefinitions.animals["smokeygirly"].litterEatTogether = true;
AnimalDefinitions.animals["smokeygirly"].eatFromMother = true;
AnimalDefinitions.animals["smokeygirly"].addTrackingXp = false;
AnimalDefinitions.animals["smokeygirly"].corpseSize = 0;
AnimalDefinitions.animals["smokeygirly"].dung = "Dung_Rat";
AnimalDefinitions.animals["smokeygirly"].wildFleeTimeUntilDeadTimer = 50;
AnimalDefinitions.animals["smokeygirly"].featherItem = "Base.ChickenFeather"
AnimalDefinitions.animals["smokeygirly"].maxFeather = 1
AnimalDefinitions.animals["smokeygirly"].canBeFeedByHand = true;
AnimalDefinitions.animals["smokeygirly"].stressAboveGround = false;
AnimalDefinitions.animals["smokeygirly"].litterEatTogether = false;
AnimalDefinitions.animals["smokeygirly"].canClimbFences = true;
AnimalDefinitions.animals["smokeygirly"].NeedMom = false;

local smokeyboi_sounds = {
	death = { name = "AnimalVoiceFawnDeath", slot = "voice", priority = 100 },
	fallover = { name = "AnimalFoleyBuckBodyfall" },
	idle = { name = "KTTR_Kitty_Purr_Medium", intervalMin = 12, intervalMax = 64, slot = "voice" },
	pain = { name = "KTTR_Kitty_Purr_Lonely", slot = "voice", priority = 50 },
	pick_up = { name = "KTTR_Kitty_Meow_Smol", slot = "voice", priority = 1 },
	pick_up_corpse = { name = "PickUpAnimalDeadDeer" },
	put_down = { name = "KTTR_Kitty_Meow_hi2", slot = "voice", priority = 1 },
	put_down_corpse = { name = "PutDownAnimalDeadDeer" },
	run = { name = "AnimalFootstepsBuckRun" },
	stressed = { name = "KTTR_Kitty_Meow_Anxious", intervalMin = 5, intervalMax = 10, slot = "voice" },
	walkloop = { name = "AnimalFootstepsMouseWalk", slot = "walkloop" },
}
AnimalDefinitions.animals["smokeyboi"].breeds["midnight"].sounds = smokeyboi_sounds

local smokeygirly_sounds = {
	death = { name = "AnimalVoiceFawnDeath", slot = "voice", priority = 100 },
	fallover = { name = "AnimalFoleyDoeBodyfall" },
	idle = { name = "KTTR_Kitty_Purr_Medium", intervalMin = 12, intervalMax = 64, slot = "voice" },
	pain = { name = "KTTR_Kitty_Purr_Lonely", slot = "voice", priority = 50 },
	pick_up = { name = "KTTR_Kitty_Meow_Smol", slot = "voice", priority = 1 },
	pick_up_corpse = { name = "PickUpAnimalDeadDeer" },
	put_down = { name = "KTTR_Kitty_Meow_hi2", slot = "voice", priority = 1 },
	put_down_corpse = { name = "PutDownAnimalDeadDeer" },
	run = { name = "AnimalFootstepsDoeRun" },
	stressed = { name = "KTTR_Kitty_Meow_Anxious", intervalMin = 5, intervalMax = 10, slot = "voice" },
	walkloop = { name = "AnimalFootstepsMouseWalk", slot = "walkloop" },
}
AnimalDefinitions.animals["smokeygirly"].breeds["midnight"].sounds = smokeygirly_sounds


local babysmokeykitten_sounds = {
	death = { name = "AnimalVoiceFawnDeath", slot = "voice", priority = 100 },
	fallover = { name = "AnimalFoleyFawnBodyfall" },
	idle = { name = "KTTR_Kitty_Purr_Medium", intervalMin = 12, intervalMax = 64, slot = "voice" },
	pain = { name = "KTTR_Kitty_Purr_Lonely", slot = "voice", priority = 50 },
	pick_up = { name = "KTTR_Kitty_Meow_Smol", slot = "voice", priority = 1 },
	pick_up_corpse = { name = "PickUpAnimalDeadFawn" },
	put_down = { name = "KTTR_Kitty_Meow_hi", slot = "voice", priority = 1 },
	put_down_corpse = { name = "PutDownAnimalDeadFawn" },
	run = { name = "AnimalFootstepsFawnRun" },
	stressed = { name = "KTTR_Kitty_Meow_Anxious", intervalMin = 3, intervalMax = 8, slot = "voice" },
	walkloop = { name = "AnimalFootstepsMouseWalk", slot = "walkloop" },
}
AnimalDefinitions.animals["babysmokeykitten"].breeds["midnight"].sounds = babysmokeykitten_sounds

local AVATAR_DEFINITION = {
    zoom = 3,
    xoffset = 0,
    yoffset = -1,
    avatarWidth = 180,
    avatarDir = IsoDirections.SE,
    trailerDir = IsoDirections.SW,
    trailerZoom = 3,
    trailerXoffset = 0,
    trailerYoffset = 0,
    hook = true,
    butcherHookZoom = 3,
    butcherHookXoffset = 0,
    butcherHookYoffset = 0,
    animalPositionSize = 0.6,
    animalPositionX = 0,
    animalPositionY = 0.5,
    animalPositionZ = 0.7
}

AnimalAvatarDefinition["smokeyboi"] = AVATAR_DEFINITION
AnimalAvatarDefinition["smokeygirly"] = AVATAR_DEFINITION
AnimalAvatarDefinition["babykitten"] = AVATAR_DEFINITION