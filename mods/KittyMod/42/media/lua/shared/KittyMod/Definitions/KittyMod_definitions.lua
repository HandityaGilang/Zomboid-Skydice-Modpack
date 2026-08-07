AnimalDefinitions.stages["kttr"] = {
    stages = {
        ["babykitten"] = {
            ageToGrow = 2 * 30, 
            nextStage = "queen",
            nextStageMale = "tom",
            minWeight = 0.1,
            maxWeight = 0.25
        },
        ["queen"] = {
            minWeight = 0.25,
            maxWeight = 0.5
        },
        ["tom"] = {
            minWeight = 0.25,
            maxWeight = 0.5
        }
    }
}

AnimalDefinitions.genome["kttr"] = {
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


AnimalDefinitions.breeds["kttr"] = {
    breeds = {
        ["shorthair"] = {
            name = "shorthair",
            texture = "KittyMod/CATTO_N1",
            textureMale = "KittyMod/CATTO_N1",
            rottenTexture = "KittyMod/CATTO_N1",
            textureBaby = "KittyMod/CATTO_N1",
            invIconMale = "Item_DeerMale_Dead",
            invIconFemale = "Item_DeerFemale_Dead",
            invIconBaby = "Item_DeerFawn_Dead",
            invIconMaleDead = "Item_DeerMale_Dead",
            invIconFemaleDead = "Item_DeerFemale_Dead",
            invIconBabyDead = "Item_DeerFawn_Dead",
            canBePicked = true,
        }
    }
}

AnimalDefinitions.breeds["kttr"].breeds["orange"] = {};
AnimalDefinitions.breeds["kttr"].breeds["orange"].name = "orange";
AnimalDefinitions.breeds["kttr"].breeds["orange"].texture = "KittyMod/CATTO_N3F";
AnimalDefinitions.breeds["kttr"].breeds["orange"].textureMale = "KittyMod/CATTO_N3F";
AnimalDefinitions.breeds["kttr"].breeds["orange"].textureBaby = "KittyMod/CATTO_N3F";
AnimalDefinitions.breeds["kttr"].breeds["orange"].rottenTexture = "KittyMod/CATTO_N3F";
AnimalDefinitions.breeds["kttr"].breeds["orange"].invIconMale = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["orange"].invIconFemale = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["orange"].invIconBaby = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["orange"].invIconMaleDead = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["orange"].invIconFemaleDead = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["orange"].invIconBabyDead = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["orange"].invIconMaleSkel = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["orange"].invIconFemaleSkel = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["orange"].invIconBabySkel = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["orange"].forcedGenes = {};

AnimalDefinitions.breeds["kttr"].breeds["garf"] = {};
AnimalDefinitions.breeds["kttr"].breeds["garf"].name = "garf";
AnimalDefinitions.breeds["kttr"].breeds["garf"].texture = "KittyMod/CATTO_N3FR2";
AnimalDefinitions.breeds["kttr"].breeds["garf"].textureMale = "KittyMod/CATTO_N3FR2";
AnimalDefinitions.breeds["kttr"].breeds["garf"].textureBaby = "KittyMod/CATTO_N3FR2";
AnimalDefinitions.breeds["kttr"].breeds["garf"].rottenTexture = "KittyMod/CATTO_N3FR2";
AnimalDefinitions.breeds["kttr"].breeds["garf"].invIconMale = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["garf"].invIconFemale = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["garf"].invIconBaby = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["garf"].invIconMaleDead = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["garf"].invIconFemaleDead = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["garf"].invIconBabyDead = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["garf"].invIconMaleSkel = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["garf"].invIconFemaleSkel = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["garf"].invIconBabySkel = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["garf"].forcedGenes = {};


AnimalDefinitions.breeds["kttr"].breeds["siamese"] = {};
AnimalDefinitions.breeds["kttr"].breeds["siamese"].name = "siamese";
AnimalDefinitions.breeds["kttr"].breeds["siamese"].texture = "KittyMod/CATTO_N2S";
AnimalDefinitions.breeds["kttr"].breeds["siamese"].textureMale = "KittyMod/CATTO_N2S";
AnimalDefinitions.breeds["kttr"].breeds["siamese"].textureBaby = "KittyMod/CATTO_N2S";
AnimalDefinitions.breeds["kttr"].breeds["siamese"].rottenTexture = "KittyMod/CATTO_N2S";
AnimalDefinitions.breeds["kttr"].breeds["siamese"].invIconMale = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["siamese"].invIconFemale = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["siamese"].invIconBaby = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["siamese"].invIconMaleDead = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["siamese"].invIconFemaleDead = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["siamese"].invIconBabyDead = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["siamese"].invIconMaleSkel = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["siamese"].invIconFemaleSkel = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["siamese"].invIconBabySkel = "Item_CATTO";
AnimalDefinitions.breeds["kttr"].breeds["siamese"].forcedGenes = {};




AnimalDefinitions.animals["babykitten"] = {
    breeds = copyTable(AnimalDefinitions.breeds["kttr"].breeds);
    stages = AnimalDefinitions.stages["kttr"].stages;
    genes = AnimalDefinitions.genome["kttr"].genes;
    bodyModel = "KittyMod.DynamixKitty";
    bodyModelSkel = "KittyMod.DynamixKitty";
    textureSkeleton = "KittyMod.DynamixKitty";
    textureSkeletonBloody = "KittyMod.DynamixKitty";
    bodyModelSkelNoHead = "KittyMod.DynamixKitty";
    modelscript = "KittyMod.DynamixKitty";
    ropeBone = "Bip01_Neck";
    animset = "doe",
    group = "kttr";
    idleTypeNbr = 2;
    idleEmoteChance = 700;
    collisionSize = 1;
    animalSize = 0.1;
    minSize = 0.15;
    maxSize = 0.35;
    corpseSize = 1;
    shadoww = 0.3;
    shadowfm = 0.3;
    shadowbm = 0.3;
    minBlood = 200;
    maxBlood = 600;
    spottingDist = 15;
    wanderMul = 250;
    trailerBaseSize = 10;
    baseEncumbrance = 2;
    minWeight = 2;
    maxWeight = 4;
    distToEat = 1;
    attackDist = 2;
    maxFeather = 1;
    alwaysFleeHumans = false;
    canBePicked = true;
    collidable = false;
    sitRandomly = false;
    wild = false;
    canClimbStairs = true;
    canBeAlerted = true;
    canBeDomesticated = true;
    canThump = false;
    eatGrass = true;
    dontAttackOtherMale = true;
    knockdownAttack = true;
    attackIfStressed = true;
    attackBack = true;
    canBePet = true;
    canBeFeedByHand = true;
    stressAboveGround = false;
    litterEatTogether = true;
    stressUnderRain = false;
    canClimbFences = true;
    NeedMom = false;
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
    featherItem = "Base.ChickenFeather";
}














AnimalDefinitions.animals["tom"] = {
    bodyModel = "KittyMod.DynamixKitty";
    bodyModelSkel = "KittyMod.DynamixKitty";
    textureSkeleton = "KittyMod.DynamixKitty";
    textureSkeletonBloody = "KittyMod.DynamixKitty";
    bodyModelSkelNoHead = "KittyMod.DynamixKitty";
    animset = "doe";
    modelscript = "KittyMod.DynamixKitty";
    bodyModelHeadless = "KittyMod.DynamixKitty";
    textureSkinned = "KittyMod/DynamixKitty";
    shadoww = 0.3;
    shadowfm = 0.3;
    shadowbm = 0.3;
    minSize = 0.35;
    maxSize = 0.6;
    animalSize = 0.3;
    breeds = copyTable(AnimalDefinitions.breeds["kttr"].breeds);
    stages = AnimalDefinitions.stages["kttr"].stages;
    genes = AnimalDefinitions.genome["kttr"].genes;
    mate = "queen";
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
    minAge = AnimalDefinitions.stages["kttr"].stages["babykitten"].ageToGrow;
    maxAgeGeriatric = 19 * 30;
    minAgeForBaby = 10;
    babyType = "babykitten";
    wanderMul = 200;
    sitRandomly = true;
    canClimbStairs = true;
    idleTypeNbr = 2;
    idleEmoteChance = 700;
    wild = false;
    spottingDist = 19;
    group = "kttr";
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
    canBeFeedByHand = true;
    stressAboveGround = false;
    litterEatTogether = false;
    stressUnderRain = false;
    canClimbFences = true;
    NeedMom = false;
}
--[[
AnimalDefinitions.animals["queen"] = {
    bodyModel = "KittyMod.DynamixKitty";
    bodyModelSkel = "KittyMod.DynamixKitty";
    textureSkeleton = "KittyMod.DynamixKitty";
    textureSkeletonBloody = "KittyMod.DynamixKitty";
    bodyModelSkelNoHead = "KittyMod.DynamixKitty";
    animset = "doe"; 
    modelscript = "KittyMod.DynamixKitty";
    bodyModelHeadless = "KittyMod.DynamixKitty";
    textureSkinned = "KittyMod/DynamixKitty";
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

AnimalDefinitions.animals["queen"] = { };
AnimalDefinitions.animals["queen"].bodyModel = "KittyMod.DynamixKitty";
AnimalDefinitions.animals["queen"].bodyModelSkel = "KittyMod.DynamixKitty";
AnimalDefinitions.animals["queen"].textureSkeleton = "KittyMod.DynamixKitty";
AnimalDefinitions.animals["queen"].textureSkeletonBloody = "KittyMod.DynamixKitty";
AnimalDefinitions.animals["queen"].bodyModelSkelNoHead = "KittyMod.DynamixKitty";
AnimalDefinitions.animals["queen"].animset = "doe";
AnimalDefinitions.animals["queen"].shadoww = 0.2;
AnimalDefinitions.animals["queen"].shadowfm = 0.2;
AnimalDefinitions.animals["queen"].shadowbm = 0.2;
AnimalDefinitions.animals["queen"].wanderMul = 250;
AnimalDefinitions.animals["queen"].textureSkinned = "KittyMod/DynamixKitty";
AnimalDefinitions.animals["queen"].breeds = copyTable(AnimalDefinitions.breeds["kttr"].breeds);
AnimalDefinitions.animals["queen"].stages = AnimalDefinitions.stages["kttr"].stages;
AnimalDefinitions.animals["queen"].genes = AnimalDefinitions.genome["kttr"].genes;
AnimalDefinitions.animals["queen"].babyType = "babykitten";
AnimalDefinitions.animals["queen"].minSize = 0.4
AnimalDefinitions.animals["queen"].maxSize = 0.58;
AnimalDefinitions.animals["queen"].hungerMultiplier = 0.00008;
AnimalDefinitions.animals["queen"].thirstMultiplier = 0.00016;
AnimalDefinitions.animals["queen"].alwaysFleeHumans = false;
AnimalDefinitions.animals["queen"].collidable = false;
AnimalDefinitions.animals["queen"].group = "kttr";
AnimalDefinitions.animals["queen"].canBePicked = true;
AnimalDefinitions.animals["queen"].canBeKilledWithoutWeapon = true;
AnimalDefinitions.animals["queen"].canBePet = true;
AnimalDefinitions.animals["queen"].wild = false;
AnimalDefinitions.animals["queen"].idleTypeNbr = 2;
AnimalDefinitions.animals["queen"].canClimbStairs = true;
AnimalDefinitions.animals["queen"].eatTypeTrough = "All";
AnimalDefinitions.animals["queen"].needMom = false;
AnimalDefinitions.animals["queen"].dontAttackOtherMale = true;
AnimalDefinitions.animals["queen"].trailerBaseSize = 10;
AnimalDefinitions.animals["queen"].minWeight = 0.1;
AnimalDefinitions.animals["queen"].maxWeight = 0.3;
AnimalDefinitions.animals["queen"].animalSize = 0;
AnimalDefinitions.animals["queen"].attackDist = 0;
AnimalDefinitions.animals["queen"].attackTimer = 1500;
AnimalDefinitions.animals["queen"].baseEncumbrance = 5;
AnimalDefinitions.animals["queen"].canThump = false;
AnimalDefinitions.animals["queen"].minEnclosureSize = 20;
AnimalDefinitions.animals["queen"].hungerBoost = 25;
AnimalDefinitions.animals["queen"].thirstBoost = 30;
AnimalDefinitions.animals["queen"].thirstHungerTrigger = 0.1;
AnimalDefinitions.animals["queen"].distToEat = 1;
AnimalDefinitions.animals["queen"].eatTypeTrough = {
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
AnimalDefinitions.animals["queen"].turnDelta = 0.95;
AnimalDefinitions.animals["queen"].litterEatTogether = true;
AnimalDefinitions.animals["queen"].eatFromMother = true;
AnimalDefinitions.animals["queen"].addTrackingXp = false;
AnimalDefinitions.animals["queen"].corpseSize = 0;
AnimalDefinitions.animals["queen"].dung = "Dung_Rat";
AnimalDefinitions.animals["queen"].wildFleeTimeUntilDeadTimer = 50;
AnimalDefinitions.animals["queen"].featherItem = "Base.ChickenFeather"
AnimalDefinitions.animals["queen"].maxFeather = 1
AnimalDefinitions.animals["queen"].canBeFeedByHand = true;
AnimalDefinitions.animals["queen"].stressAboveGround = false;
AnimalDefinitions.animals["queen"].litterEatTogether = false;
AnimalDefinitions.animals["queen"].canClimbFences = true;
AnimalDefinitions.animals["queen"].NeedMom = false;

local tom_sounds = {
	death = { name = "AnimalVoiceFawnDeath", slot = "voice", priority = 100 },
	fallover = { name = "AnimalFoleyBuckBodyfall" },
	idle1 = { name = "KTTR_Kitty_Purr_Medium", intervalMin = 12, intervalMax = 64, slot = "voice" },
	idle2 = { name = "KTTR_Kitty_Long_Meow", intervalMin = 4, intervalMax = 48, slot = "voice" },
	pain = { name = "KTTR_Kitty_Purr_Lonely", slot = "voice", priority = 50 },
	pick_up = { name = "KTTR_Kitty_Meow_Smol", slot = "voice", priority = 1 },
	pick_up_corpse = { name = "PickUpAnimalDeadDeer" },
	put_down = { name = "KTTR_Kitty_Meow_hi2", slot = "voice", priority = 1 },
	put_down_corpse = { name = "PutDownAnimalDeadDeer" },
	run = { name = "AnimalFootstepsBuckRun" },
	stressed = { name = "KTTR_Kitty_Meow_Anxious", intervalMin = 5, intervalMax = 10, slot = "voice" },
	walkloop = { name = "AnimalFootstepsMouseWalk", slot = "walkloop" },
}
AnimalDefinitions.animals["tom"].breeds["shorthair"].sounds = tom_sounds

local queen_sounds = {
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
AnimalDefinitions.animals["queen"].breeds["shorthair"].sounds = queen_sounds

local babykitten_sounds = {
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
AnimalDefinitions.animals["babykitten"].breeds["shorthair"].sounds = babykitten_sounds

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

AnimalAvatarDefinition["tom"] = AVATAR_DEFINITION
AnimalAvatarDefinition["queen"] = AVATAR_DEFINITION
AnimalAvatarDefinition["babykitten"] = AVATAR_DEFINITION