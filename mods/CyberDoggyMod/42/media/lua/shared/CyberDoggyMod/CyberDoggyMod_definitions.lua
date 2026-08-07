--[[
NOTE: remove the above comment brackets if using this template for your own mod!


AnimalDefinitions.stages["cyberdoggie"] = {
    stages = {
        ["cyberdogpup"] = {
            ageToGrow = 2 * 30, 
            nextStage = "cyberdoggirl",
            nextStageMale = "cyberdog",
            minWeight = 0.1,
            maxWeight = 0.25
        },
        ["cyberdoggirl"] = {
            minWeight = 0.25,
            maxWeight = 0.5
        },
        ["cyberdog"] = {
            minWeight = 0.25,
            maxWeight = 0.5
        }
    }
}

AnimalDefinitions.genome["cyberdoggie"] = {
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


AnimalDefinitions.breeds["cyberdoggie"] = {
    breeds = {
        ["cyberdoggie"] = {
            name = "cyberdoggie",
            texture = "CyberDoggyMod/CyberDog",
            textureMale = "CyberDoggyMod/CyberDog",
            rottenTexture = "CyberDoggyMod/CyberDog",
            textureBaby = "CyberDoggyMod/CyberDog",
            invIconMale = "item_CyberDog",
            invIconFemale = "item_CyberDog",
            invIconBaby = "item_CyberDog",
            invIconMaleDead = "item_CyberDog",
            invIconFemaleDead = "item_CyberDog",
            invIconBabyDead = "item_CyberDog",
            canBePicked = true,
        }
    }
}



AnimalDefinitions.animals["cyberdogpup"] = {
    bodyModel = "CyberDoggyMod.CyberDog";
    bodyModelSkel = "CyberDoggyMod.CyberDog";
    textureSkeleton = "CyberDoggyMod.CyberDog";
    textureSkeletonBloody = "CyberDoggyMod.CyberDog";
    bodyModelSkelNoHead = "CyberDoggyMod.CyberDog";
    animset = "pig", 
    animalSize = 0.1;
    modelscript = "CyberDoggyMod.CyberDog";
    shadoww = 0.3;
    shadowfm = 0.3;
    shadowbm = 0.3;
    wanderMul = 12;
    needMom = false;
    breeds = copyTable(AnimalDefinitions.breeds["cyberdoggie"].breeds);
    stages = AnimalDefinitions.stages["cyberdoggie"].stages;
    genes = AnimalDefinitions.genome["cyberdoggie"].genes;
    minSize = 0.35;
    maxSize = 0.75;
    alwaysFleeHumans = false;
    canBePicked = true;
    collidable = false;
    sitRandomly = false;
    idleTypeNbr = 2;
    idleEmoteChance = 700;
    wild = false;
    spottingDist = 15;
    canClimbStairs = true;
    group = "cyberdoggie";
    canBeAlerted = true;
    distToEat = 1;
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
}














AnimalDefinitions.animals["cyberdog"] = {
    bodyModel = "CyberDoggyMod.CyberDog";
    bodyModelSkel = "CyberDoggyMod.CyberDog";
    textureSkeleton = "CyberDoggyMod.CyberDog";
    textureSkeletonBloody = "CyberDoggyMod.CyberDog";
    bodyModelSkelNoHead = "CyberDoggyMod.CyberDog";
    animset = "pig";
    modelscript = "CyberDoggyMod.CyberDog";
    bodyModelHeadless = "CyberDoggyMod.CyberDog";
    textureSkinned = "CyberDoggyMod/CyberDog";
    shadoww = 0.3;
    shadowfm = 0.3;
    shadowbm = 0.3;
    minSize = 1;
    maxSize = 1;
    animalSize = 0.3;
    breeds = copyTable(AnimalDefinitions.breeds["cyberdoggie"].breeds);
    stages = AnimalDefinitions.stages["cyberdoggie"].stages;
    genes = AnimalDefinitions.genome["cyberdoggie"].genes;
    mate = "cyberdoggirl";
    canBePicked = true;
    canBeKilledWithoutWeapon = true;
    hungerMultiplier = 0.0001;
    thirstMultiplier = 0.0002;
    distToEat = 1;
    eatTypeTrough = "AnimalFeed,Grass,Hay,Vegetables,Fruits,Seeds,Nuts,Nut,Insect";
    minAge = AnimalDefinitions.stages["cyberdoggie"].stages["cyberdogpup"].ageToGrow;
    maxAgeGeriatric = 19 * 30;
    minAgeForBaby = 10;
    babyType = "cyberdogpup";
    wanderMul = 12;
    sitRandomly = true;
    canClimbStairs = true;
    idleTypeNbr = 2;
    idleEmoteChance = 700;
    wild = false;
    spottingDist = 19;
    group = "cyberdoggie";
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
}
--[[
AnimalDefinitions.animals["cyberdoggirl"] = {
    bodyModel = "CyberDoggyMod.CyberDog";
    bodyModelSkel = "CyberDoggyMod.CyberDog";
    textureSkeleton = "CyberDoggyMod.CyberDog";
    textureSkeletonBloody = "CyberDoggyMod.CyberDog";
    bodyModelSkelNoHead = "CyberDoggyMod.CyberDog";
    animset = "pig"; 
    modelscript = "CyberDoggyMod.CyberDog";
    bodyModelHeadless = "CyberDoggyMod.CyberDog";
    textureSkinned = "CyberDoggyMod/CyberDog";
    shadoww = 0.3;
    shadowfm = 0.3;
    shadowbm = 0.3;
    minSize = 0.35;
    maxSize = 0.75;
    animalSize = 0.3;
    breeds = copyTable(AnimalDefinitions.breeds["cyberdoggie"].breeds);
    stages = AnimalDefinitions.stages["cyberdoggie"].stages;
    genes = AnimalDefinitions.genome["cyberdoggie"].genes;
    mate = "cyberdog";
    canBePicked = true;
    minAge = AnimalDefinitions.stages["cyberdoggie"].stages["cyberdogpup"].ageToGrow;
    maxAgeGeriatric = 19 * 30;
    minAgeForBaby = 10;
    pregnantPeriod = 1;
    babyType = "cyberdogpup";
    wanderMul = 200;
    sitRandomly = false;
    idleTypeNbr = 2;
    idleEmoteChance = 700;
    wild = false;
    spottingDist = 19;
    canClimbStairs = true;
    group = "cyberdoggie";
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



--[[


AnimalDefinitions.animals["cyberdoggirl"] = { };
AnimalDefinitions.animals["cyberdoggirl"].bodyModel = "CyberDoggyMod.CyberDog";
AnimalDefinitions.animals["cyberdoggirl"].bodyModelSkel = "CyberDoggyMod.CyberDog";
AnimalDefinitions.animals["cyberdoggirl"].textureSkeleton = "CyberDoggyMod.CyberDog";
AnimalDefinitions.animals["cyberdoggirl"].textureSkeletonBloody = "CyberDoggyMod.CyberDog";
AnimalDefinitions.animals["cyberdoggirl"].bodyModelSkelNoHead = "CyberDoggyMod.CyberDog";
AnimalDefinitions.animals["cyberdoggirl"].animset = "pig";
AnimalDefinitions.animals["cyberdoggirl"].shadoww = 0.2;
AnimalDefinitions.animals["cyberdoggirl"].shadowfm = 0.2;
AnimalDefinitions.animals["cyberdoggirl"].shadowbm = 0.2;
AnimalDefinitions.animals["cyberdoggirl"].wanderMul = 250;
AnimalDefinitions.animals["cyberdoggirl"].textureSkinned = "CyberDoggyMod/CyberDog";
AnimalDefinitions.animals["cyberdoggirl"].breeds = copyTable(AnimalDefinitions.breeds["cyberdoggie"].breeds);
AnimalDefinitions.animals["cyberdoggirl"].stages = AnimalDefinitions.stages["cyberdoggie"].stages;
AnimalDefinitions.animals["cyberdoggirl"].genes = AnimalDefinitions.genome["cyberdoggie"].genes;
AnimalDefinitions.animals["cyberdoggirl"].babyType = "cyberdogpup";
AnimalDefinitions.animals["cyberdoggirl"].minSize = 0.4
AnimalDefinitions.animals["cyberdoggirl"].maxSize = 0.7;
AnimalDefinitions.animals["cyberdoggirl"].hungerMultiplier = 0.00008;
AnimalDefinitions.animals["cyberdoggirl"].thirstMultiplier = 0.00016;
AnimalDefinitions.animals["cyberdoggirl"].alwaysFleeHumans = false;
AnimalDefinitions.animals["cyberdoggirl"].collidable = false;
AnimalDefinitions.animals["cyberdoggirl"].group = "cyberdoggie";
AnimalDefinitions.animals["cyberdoggirl"].canBePicked = true;
AnimalDefinitions.animals["cyberdoggirl"].canBeKilledWithoutWeapon = true;
AnimalDefinitions.animals["cyberdoggirl"].canBePet = true;
AnimalDefinitions.animals["cyberdoggirl"].wild = true;
AnimalDefinitions.animals["cyberdoggirl"].idleTypeNbr = 2;
AnimalDefinitions.animals["cyberdoggirl"].canClimbStairs = true;
AnimalDefinitions.animals["cyberdoggirl"].eatTypeTrough = "All";
AnimalDefinitions.animals["cyberdoggirl"].needMom = false;
AnimalDefinitions.animals["cyberdoggirl"].dontAttackOtherMale = true;
AnimalDefinitions.animals["cyberdoggirl"].trailerBaseSize = 10;
AnimalDefinitions.animals["cyberdoggirl"].minWeight = 0.1;
AnimalDefinitions.animals["cyberdoggirl"].maxWeight = 0.3;
AnimalDefinitions.animals["cyberdoggirl"].animalSize = 0;
AnimalDefinitions.animals["cyberdoggirl"].attackDist = 0;
AnimalDefinitions.animals["cyberdoggirl"].attackTimer = 1500;
AnimalDefinitions.animals["cyberdoggirl"].baseEncumbrance = 5;
AnimalDefinitions.animals["cyberdoggirl"].canThump = false;
AnimalDefinitions.animals["cyberdoggirl"].minEnclosureSize = 20;
AnimalDefinitions.animals["cyberdoggirl"].hungerBoost = 25;
AnimalDefinitions.animals["cyberdoggirl"].thirstBoost = 30;
AnimalDefinitions.animals["cyberdoggirl"].thirstHungerTrigger = 0.1;
AnimalDefinitions.animals["cyberdoggirl"].distToEat = 1;
AnimalDefinitions.animals["cyberdoggirl"].turnDelta = 0.95;
AnimalDefinitions.animals["cyberdoggirl"].litterEatTogether = true;
AnimalDefinitions.animals["cyberdoggirl"].eatFromMother = true;
AnimalDefinitions.animals["cyberdoggirl"].addTrackingXp = false;
AnimalDefinitions.animals["cyberdoggirl"].corpseSize = 0;
AnimalDefinitions.animals["cyberdoggirl"].dung = "Dung_Rat";
AnimalDefinitions.animals["cyberdoggirl"].wildFleeTimeUntilDeadTimer = 50;

local cyberdog_sounds = {
	death = { name = "AnimalVoiceFawnDeath", slot = "voice", priority = 100 },
	fallover = { name = "AnimalFoleyBuckBodyfall" },
	idle = { name = "cyberdoggie_Kitty_Purr_Medium", intervalMin = 3, intervalMax = 32, slot = "voice" },
	pain = { name = "cyberdoggie_Kitty_Purr_Lonely", slot = "voice", priority = 50 },
	pick_up = { name = "cyberdoggie_Kitty_Meow_Smol", slot = "voice", priority = 1 },
	pick_up_corpse = { name = "PickUpAnimalDeadDeer" },
	put_down = { name = "cyberdoggie_Kitty_Meow_hi2", slot = "voice", priority = 1 },
	put_down_corpse = { name = "PutDownAnimalDeadDeer" },
	run = { name = "AnimalFootstepsBuckRun" },
	stressed = { name = "cyberdoggie_Kitty_Meow_Anxious", intervalMin = 5, intervalMax = 10, slot = "voice" },
	walkloop = { name = "AnimalFootstepsMouseWalk", slot = "walkloop" },
}
AnimalDefinitions.animals["cyberdog"].breeds["cyberdoggie"].sounds = cyberdog_sounds

local cyberdoggirl_sounds = {
	death = { name = "AnimalVoiceFawnDeath", slot = "voice", priority = 100 },
	fallover = { name = "AnimalFoleypigBodyfall" },
	idle = { name = "cyberdoggie_Kitty_Purr_Medium", intervalMin = 3, intervalMax = 32, slot = "voice" },
	pain = { name = "cyberdoggie_Kitty_Purr_Lonely", slot = "voice", priority = 50 },
	pick_up = { name = "cyberdoggie_Kitty_Meow_Smol", slot = "voice", priority = 1 },
	pick_up_corpse = { name = "PickUpAnimalDeadDeer" },
	put_down = { name = "cyberdoggie_Kitty_Meow_hi2", slot = "voice", priority = 1 },
	put_down_corpse = { name = "PutDownAnimalDeadDeer" },
	run = { name = "AnimalFootstepspigRun" },
	stressed = { name = "cyberdoggie_Kitty_Meow_Anxious", intervalMin = 5, intervalMax = 10, slot = "voice" },
	walkloop = { name = "AnimalFootstepsMouseWalk", slot = "walkloop" },
}
AnimalDefinitions.animals["cyberdoggirl"].breeds["cyberdoggie"].sounds = cyberdoggirl_sounds

local babykitten_sounds = {
	death = { name = "AnimalVoiceFawnDeath", slot = "voice", priority = 100 },
	fallover = { name = "AnimalFoleyFawnBodyfall" },
	idle = { name = "cyberdoggie_Kitty_Purr_Medium", intervalMin = 3, intervalMax = 32, slot = "voice" },
	pain = { name = "cyberdoggie_Kitty_Purr_Lonely", slot = "voice", priority = 50 },
	pick_up = { name = "cyberdoggie_Kitty_Meow_Smol", slot = "voice", priority = 1 },
	pick_up_corpse = { name = "PickUpAnimalDeadFawn" },
	put_down = { name = "cyberdoggie_Kitty_Meow_hi", slot = "voice", priority = 1 },
	put_down_corpse = { name = "PutDownAnimalDeadFawn" },
	run = { name = "AnimalFootstepsFawnRun" },
	stressed = { name = "cyberdoggie_Kitty_Meow_Anxious", intervalMin = 3, intervalMax = 8, slot = "voice" },
	walkloop = { name = "AnimalFootstepsMouseWalk", slot = "walkloop" },
}
AnimalDefinitions.animals["cyberdogpup"].breeds["cyberdoggie"].sounds = babykitten_sounds

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

AnimalAvatarDefinition["cyberdog"] = AVATAR_DEFINITION
AnimalAvatarDefinition["cyberdoggirl"] = AVATAR_DEFINITION
AnimalAvatarDefinition["cyberdogpup"] = AVATAR_DEFINITION

--]]