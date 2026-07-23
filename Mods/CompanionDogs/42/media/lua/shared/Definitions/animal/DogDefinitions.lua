AnimalDefinitions = AnimalDefinitions or {}
AnimalDefinitions.stages = AnimalDefinitions.stages or {}
AnimalDefinitions.breeds = AnimalDefinitions.breeds or {}
AnimalDefinitions.genome = AnimalDefinitions.genome or {}
AnimalDefinitions.animals = AnimalDefinitions.animals or {}

AnimalDefinitions.stages["dog"] = {}
AnimalDefinitions.stages["dog"].stages = {}
AnimalDefinitions.stages["dog"].stages["dogpup"] = {}
AnimalDefinitions.stages["dog"].stages["dogpup"].ageToGrow = 3 * 30
AnimalDefinitions.stages["dog"].stages["dogpup"].nextStage = "dogfemale"
AnimalDefinitions.stages["dog"].stages["dogpup"].nextStageMale = "dogmale"
AnimalDefinitions.stages["dog"].stages["dogmale"] = {}
AnimalDefinitions.stages["dog"].stages["dogmale"].ageToGrow = 3 * 30
AnimalDefinitions.stages["dog"].stages["dogfemale"] = {}
AnimalDefinitions.stages["dog"].stages["dogfemale"].ageToGrow = 3 * 30

AnimalDefinitions.stages["gs"] = {}
AnimalDefinitions.stages["gs"].stages = {}
AnimalDefinitions.stages["gs"].stages["gspup"] = {}
AnimalDefinitions.stages["gs"].stages["gspup"].ageToGrow = 3 * 30
AnimalDefinitions.stages["gs"].stages["gspup"].nextStage = "gsfemale"
AnimalDefinitions.stages["gs"].stages["gspup"].nextStageMale = "gsmale"
AnimalDefinitions.stages["gs"].stages["gsmale"] = {}
AnimalDefinitions.stages["gs"].stages["gsmale"].ageToGrow = 3 * 30
AnimalDefinitions.stages["gs"].stages["gsfemale"] = {}
AnimalDefinitions.stages["gs"].stages["gsfemale"].ageToGrow = 3 * 30

AnimalDefinitions.stages["retriever"] = {}
AnimalDefinitions.stages["retriever"].stages = {}
AnimalDefinitions.stages["retriever"].stages["retrieverpup"] = {}
AnimalDefinitions.stages["retriever"].stages["retrieverpup"].ageToGrow = 3 * 30
AnimalDefinitions.stages["retriever"].stages["retrieverpup"].nextStage = "retrieverfemale"
AnimalDefinitions.stages["retriever"].stages["retrieverpup"].nextStageMale = "retrievermale"
AnimalDefinitions.stages["retriever"].stages["retrievermale"] = {}
AnimalDefinitions.stages["retriever"].stages["retrievermale"].ageToGrow = 3 * 30
AnimalDefinitions.stages["retriever"].stages["retrieverfemale"] = {}
AnimalDefinitions.stages["retriever"].stages["retrieverfemale"].ageToGrow = 3 * 30

AnimalDefinitions.stages["husky"] = {}
AnimalDefinitions.stages["husky"].stages = {}
AnimalDefinitions.stages["husky"].stages["huskypup"] = {}
AnimalDefinitions.stages["husky"].stages["huskypup"].ageToGrow = 3 * 30
AnimalDefinitions.stages["husky"].stages["huskypup"].nextStage = "huskyfemale"
AnimalDefinitions.stages["husky"].stages["huskypup"].nextStageMale = "huskymale"
AnimalDefinitions.stages["husky"].stages["huskymale"] = {}
AnimalDefinitions.stages["husky"].stages["huskymale"].ageToGrow = 3 * 30
AnimalDefinitions.stages["husky"].stages["huskyfemale"] = {}
AnimalDefinitions.stages["husky"].stages["huskyfemale"].ageToGrow = 3 * 30

AnimalDefinitions.breeds["dog"] = {}
AnimalDefinitions.breeds["dog"].breeds = {}
AnimalDefinitions.breeds["dog"].breeds["brown"] = {}
AnimalDefinitions.breeds["dog"].breeds["brown"].name = "brown"
-- O Caramelo usa sua PROPRIA mesh de corpo (Caramelo_Body = mesh do GS com orelhas tombadas/dobradas); a textura do
-- pelo caramelo e baked nas UVs dessa mesh (mesmo layout de UV do GS). Os tipos dog* abaixo definem bodyModel = "Caramelo_Body".
AnimalDefinitions.breeds["dog"].breeds["brown"].texture = "Caramelo"
AnimalDefinitions.breeds["dog"].breeds["brown"].textureMale = "Caramelo"
AnimalDefinitions.breeds["dog"].breeds["brown"].rottenTexture = "Raccoon_Rotting"
-- Icone do item carregado nas maos. O vanilla nao tem icone de cachorro/pet (herdamos Item_Raccoon), entao usa nosso
-- proprio glifo de pata em vez de uma foto de guaxinim. O corpo morto usa nosso glifo de pata com sangue; o esqueleto
-- continua guaxinim (o modelo de esqueleto do cachorro E o Raccoon_Skeleton).
AnimalDefinitions.breeds["dog"].breeds["brown"].invIconMale = "CDDogPaw_64"
AnimalDefinitions.breeds["dog"].breeds["brown"].invIconFemale = "CDDogPaw_64"
AnimalDefinitions.breeds["dog"].breeds["brown"].invIconBaby = "CDDogPaw_64"
AnimalDefinitions.breeds["dog"].breeds["brown"].invIconMaleDead = "CDDogPawDead_64"
AnimalDefinitions.breeds["dog"].breeds["brown"].invIconFemaleDead = "CDDogPawDead_64"
AnimalDefinitions.breeds["dog"].breeds["brown"].invIconBabyDead = "CDDogPawDead_64"
AnimalDefinitions.breeds["dog"].breeds["brown"].invIconMaleSkel = "Item_Skeleton_Raccoon"
AnimalDefinitions.breeds["dog"].breeds["brown"].invIconFemaleSkel = "Item_Skeleton_Raccoon"
AnimalDefinitions.breeds["dog"].breeds["brown"].invIconBabySkel = "Item_Skeleton_Raccoon"

-- O German Shepherd e seu PROPRIO tipo de animal ("gs*") porque a engine escolhe a MESH de corpo por tipo de animal
-- (bodyModel), enquanto uma breed so troca a TEXTURA (verificado no decomp: AnimalBreed tem campos de textura, sem
-- modelo). Sua textura e mapeada por UV no GermanShepherd_Body, entao ela precisa da mesh do shepherd.
AnimalDefinitions.breeds["gs"] = {}
AnimalDefinitions.breeds["gs"].breeds = {}
AnimalDefinitions.breeds["gs"].breeds["germanshepherd"] = {}
AnimalDefinitions.breeds["gs"].breeds["germanshepherd"].name = "germanshepherd"
AnimalDefinitions.breeds["gs"].breeds["germanshepherd"].texture = "GermanShepherd"
AnimalDefinitions.breeds["gs"].breeds["germanshepherd"].textureMale = "GermanShepherd"
AnimalDefinitions.breeds["gs"].breeds["germanshepherd"].rottenTexture = "Raccoon_Rotting"
AnimalDefinitions.breeds["gs"].breeds["germanshepherd"].invIconMale = "CDDogPaw_64"
AnimalDefinitions.breeds["gs"].breeds["germanshepherd"].invIconFemale = "CDDogPaw_64"
AnimalDefinitions.breeds["gs"].breeds["germanshepherd"].invIconBaby = "CDDogPaw_64"
AnimalDefinitions.breeds["gs"].breeds["germanshepherd"].invIconMaleDead = "CDDogPawDead_64"
AnimalDefinitions.breeds["gs"].breeds["germanshepherd"].invIconFemaleDead = "CDDogPawDead_64"
AnimalDefinitions.breeds["gs"].breeds["germanshepherd"].invIconBabyDead = "CDDogPawDead_64"
AnimalDefinitions.breeds["gs"].breeds["germanshepherd"].invIconMaleSkel = "Item_Skeleton_Raccoon"
AnimalDefinitions.breeds["gs"].breeds["germanshepherd"].invIconFemaleSkel = "Item_Skeleton_Raccoon"
AnimalDefinitions.breeds["gs"].breeds["germanshepherd"].invIconBabySkel = "Item_Skeleton_Raccoon"

-- Golden Retriever (pack lowpoly Dogs): sua PROPRIA MESH de corpo (Retriever_Body) + textura de pelo propria
-- (RetrieverPoly = o atlas PolyArt compartilhado nas UVs proprias do Retriever). O tipo de animal separado
-- "retriever*" vincula a mesh.
AnimalDefinitions.breeds["retriever"] = {}
AnimalDefinitions.breeds["retriever"].breeds = {}
AnimalDefinitions.breeds["retriever"].breeds["golden"] = {}
AnimalDefinitions.breeds["retriever"].breeds["golden"].name = "golden"
AnimalDefinitions.breeds["retriever"].breeds["golden"].texture = "RetrieverPoly"
AnimalDefinitions.breeds["retriever"].breeds["golden"].textureMale = "RetrieverPoly"
AnimalDefinitions.breeds["retriever"].breeds["golden"].rottenTexture = "Raccoon_Rotting"
AnimalDefinitions.breeds["retriever"].breeds["golden"].invIconMale = "CDDogPaw_64"
AnimalDefinitions.breeds["retriever"].breeds["golden"].invIconFemale = "CDDogPaw_64"
AnimalDefinitions.breeds["retriever"].breeds["golden"].invIconBaby = "CDDogPaw_64"
AnimalDefinitions.breeds["retriever"].breeds["golden"].invIconMaleDead = "CDDogPawDead_64"
AnimalDefinitions.breeds["retriever"].breeds["golden"].invIconFemaleDead = "CDDogPawDead_64"
AnimalDefinitions.breeds["retriever"].breeds["golden"].invIconBabyDead = "CDDogPawDead_64"
AnimalDefinitions.breeds["retriever"].breeds["golden"].invIconMaleSkel = "Item_Skeleton_Raccoon"
AnimalDefinitions.breeds["retriever"].breeds["golden"].invIconFemaleSkel = "Item_Skeleton_Raccoon"
AnimalDefinitions.breeds["retriever"].breeds["golden"].invIconBabySkel = "Item_Skeleton_Raccoon"

-- Husky (pack lowpoly Dogs, remesh Tripo): sua PROPRIA MESH de corpo (Husky_Body) + textura de pelo propria
-- (Husky = o coat husky baked nas UVs continuas do remesh). Tipo de animal separado "husky*" vincula a mesh.
AnimalDefinitions.breeds["husky"] = {}
AnimalDefinitions.breeds["husky"].breeds = {}
AnimalDefinitions.breeds["husky"].breeds["husky"] = {}
AnimalDefinitions.breeds["husky"].breeds["husky"].name = "husky"
AnimalDefinitions.breeds["husky"].breeds["husky"].texture = "Husky"
AnimalDefinitions.breeds["husky"].breeds["husky"].textureMale = "Husky"
AnimalDefinitions.breeds["husky"].breeds["husky"].rottenTexture = "Raccoon_Rotting"
AnimalDefinitions.breeds["husky"].breeds["husky"].invIconMale = "CDDogPaw_64"
AnimalDefinitions.breeds["husky"].breeds["husky"].invIconFemale = "CDDogPaw_64"
AnimalDefinitions.breeds["husky"].breeds["husky"].invIconBaby = "CDDogPaw_64"
AnimalDefinitions.breeds["husky"].breeds["husky"].invIconMaleDead = "CDDogPawDead_64"
AnimalDefinitions.breeds["husky"].breeds["husky"].invIconFemaleDead = "CDDogPawDead_64"
AnimalDefinitions.breeds["husky"].breeds["husky"].invIconBabyDead = "CDDogPawDead_64"
AnimalDefinitions.breeds["husky"].breeds["husky"].invIconMaleSkel = "Item_Skeleton_Raccoon"
AnimalDefinitions.breeds["husky"].breeds["husky"].invIconFemaleSkel = "Item_Skeleton_Raccoon"
AnimalDefinitions.breeds["husky"].breeds["husky"].invIconBabySkel = "Item_Skeleton_Raccoon"

AnimalDefinitions.genome["dog"] = {}
AnimalDefinitions.genome["dog"].genes = {}
AnimalDefinitions.genome["dog"].genes["maxSize"] = "maxSize"
AnimalDefinitions.genome["dog"].genes["meatRatio"] = "meatRatio"
AnimalDefinitions.genome["dog"].genes["maxWeight"] = "maxWeight"
AnimalDefinitions.genome["dog"].genes["lifeExpectancy"] = "lifeExpectancy"
AnimalDefinitions.genome["dog"].genes["resistance"] = "resistance"
AnimalDefinitions.genome["dog"].genes["strength"] = "strength"
AnimalDefinitions.genome["dog"].genes["hungerResistance"] = "hungerResistance"
AnimalDefinitions.genome["dog"].genes["thirstResistance"] = "thirstResistance"
AnimalDefinitions.genome["dog"].genes["aggressiveness"] = "aggressiveness"
AnimalDefinitions.genome["dog"].genes["ageToGrow"] = "ageToGrow"
AnimalDefinitions.genome["dog"].genes["fertility"] = "fertility"
AnimalDefinitions.genome["dog"].genes["stress"] = "stress"

local dog_sounds = {
    death = { name = "CDDogDeath", slot = "voice", priority = 100 },
    fallover = { name = "AnimalFoleyRaccoonBodyfall" },
    -- "idle" de proposito NAO vinculado (mesmo motivo do "stressed" abaixo): a engine o toca client-side por fora do
    -- volume/mute do mod, entao mutar nao calava o resfolego. Agora e emitido pelo Lua (tickDogIdleVoice no Client).
    pain = { name = "CDDogWhine", slot = "voice", priority = 50 },
    pick_up = { name = "CDDogPickup", slot = "voice", priority = 1 },
    pick_up_corpse = { name = "PickUpAnimalDeadRaccoon" },
    put_down = { name = "CDDogPickup", slot = "voice", priority = 1 },
    put_down_corpse = { name = "PutDownAnimalDeadRaccoon" },
    runloop = { name = "AnimalFootstepsRaccoonRun", slot = "runloop" },
    -- "stressed" de proposito NAO vinculado: a engine (chooseIdleSound) o re-toca sozinha a cada 13-26s enquanto stressLevel>50, no client-side, ignorando os cooldowns/modo Silent do mod = loop de rosnado. O rosnado e dirigido pelo Lua (CD.GROWL_SOUND) no lugar.
    walkBack = { name = "AnimalFootstepsRaccoonWalkBack" },
    walkFront = { name = "AnimalFootstepsRaccoonWalkFront" },
}

-- Expostos em CD.* pro contrato de addon (racas externas reusam os mesmos defaults); ver CD.registerBreed.
CompanionDogs = CompanionDogs or {}
CompanionDogs.DOG_SOUNDS = dog_sounds

function CompanionDogs.applyDogModel(a, bodyModel)
    a.bodyModel = bodyModel or "Caramelo_Body"
    a.bodyModelSkel = "Raccoon_Skeleton"
    a.textureSkeleton = "RaccoonSkeleton"
    a.textureSkeletonBloody = "RaccoonSkeleton_Butchered"
    a.bodyModelSkelNoHead = "Raccoon_Skeleton_NoHead"
    -- Tem que continuar "raccoon": um nome de animset forkado nao carrega (sem FSM = animal congelado).
    a.animset = "raccoon"
    a.feedByHandAnim = "AnimalLureLow"
end

function CompanionDogs.applyDogBehaviour(a)
    a.group = "dog"
    a.wild = false
    a.alwaysFleeHumans = false
    a.fleeHumansMod = 0
    a.canBeAlerted = false
    a.fleeZombies = false
    -- false para um cachorro NAO-companheiro (vira-lata urbano / solto) FUGIR quando o player bate nele, em vez de se
    -- virar para revidar. attackBack=true mandava hitConsequences->goAttack(player) e fazia fleeFromAttacker se fixar em
    -- fightingOpponent=player (decomp da engine). O combate do companheiro e manual (nunca goAttack/hitConsequences) e o
    -- loop limpa setAttackedBy(nil), entao essa flag so muda o comportamento de wild/stray.
    a.attackBack = false
    -- Durabilidade ("HP"). A health do animal e 0..1 e um golpe corpo a corpo remove weaponDamage * healthLossMultiplier *
    -- (1.5-resistance) / 0.025 (= x40). No padrao 0.05 da engine isso da ~weaponDamage*2 → QUALQUER arma de verdade
    -- mata o cachorro num golpe, em hitConsequences antes dele conseguir fugir. Abaixado para um cachorro nao-companheiro
    -- SOBREVIVER a um golpe e correr (ainda matavel com golpes sustentados). Companheiros sao setIsInvincible(true) → setHealth
    -- ignora todas as reducoes, entao isso so afeta cachorros wild/stray/soltos. Ajustavel.
    a.healthLossMultiplier = 0.004
    a.canBeDomesticated = true
    a.canBePet = true
    a.canBePicked = true
    a.canClimbStairs = true
    -- FALSE: o climb nativo de animal nao translada o cachorro e trava em ClimbFence=true ("correndo no lugar"),
    -- e depender do A* para entregar o cachorro a cerca o encurralava (ele nao conseguia pathear de volta a borda = freeze).
    -- Em vez disso o mod faz o cachorro ATRAVESSAR como fantasma: findFenceTowardOwner varre do cachorro em direcao ao dono
    -- e o desliza por cima da cerca pulavel/alta-pulavel mais proxima (parando em paredes solidas), independente do A*. Ver memory.
    a.canClimbFences = false
    a.collidable = false
    a.idleTypeNbr = 2
    a.idleEmoteChance = 450
    a.sitRandomly = false
    a.turnDelta = 0.95
    a.addTrackingXp = false
    a.corpseSize = 0
    a.dung = "Dung_Raccoon"
    a.canBeKilledWithoutWeapon = true
    a.eatTypeTrough = "AnimalFeed,Grass,Hay,Vegetables,Fruits"
    a.thirstHungerTrigger = 0.1
    a.distToEat = 1
end

-- Enorme para que um cachorro isWild() atingido (um cachorro SOLTO = setWild(true)) fuja mas nunca sangre ate a
-- morte pela ferida (wildAnimalFLeeFromAttacker mata em timer<=0). Deixa um cachorro afugentado escapar VIVO. Os
-- vira-latas urbanos sao setWild(false) entao nunca sangram ate a morte de qualquer jeito; isso so importa no caso setWild(true).
local STRAY_NO_BLEEDOUT = 1000000
CompanionDogs.STRAY_NO_BLEEDOUT = STRAY_NO_BLEEDOUT

local applyDogModel = CompanionDogs.applyDogModel
local applyDogBehaviour = CompanionDogs.applyDogBehaviour

local pup = {}
applyDogModel(pup, "Caramelo_Body")
applyDogBehaviour(pup)
pup.shadoww = 0.2
pup.shadowfm = 0.2
pup.shadowbm = 0.2
pup.minSize = 0.78
pup.maxSize = 1.17
pup.wanderMul = 500
pup.hungerMultiplier = 0.001
pup.thirstMultiplier = 0.002
pup.hungerBoost = 25
pup.thirstBoost = 30
pup.baseEncumbrance = 10
pup.trailerBaseSize = 30
pup.minEnclosureSize = 40
pup.needMom = false
pup.eatFromMother = true
pup.litterEatTogether = true
pup.minWeight = 1
pup.maxWeight = 8
pup.wildFleeTimeUntilDeadTimer = STRAY_NO_BLEEDOUT
pup.breeds = AnimalDefinitions.breeds["dog"].breeds
pup.stages = AnimalDefinitions.stages["dog"].stages
pup.genes = AnimalDefinitions.genome["dog"].genes
AnimalDefinitions.animals["dogpup"] = pup

local female = {}
applyDogModel(female, "Caramelo_Body")
applyDogBehaviour(female)
female.female = true
female.mate = "dogmale"
female.babyType = "dogpup"
female.shadoww = 0.3
female.shadowfm = 0.5
female.shadowbm = 0.5
female.minSize = 1.17
female.maxSize = 1.56
female.wanderMul = 600
female.hungerMultiplier = 0.008
female.thirstMultiplier = 0.016
female.hungerBoost = 20
female.thirstBoost = 25
female.baseEncumbrance = 20
female.trailerBaseSize = 50
female.minEnclosureSize = 40
female.minAge = 3 * 30
female.maxAgeGeriatric = 19 * 30
female.minAgeForBaby = 3 * 30
female.timeBeforeNextPregnancy = 7
female.pregnantPeriod = 35
female.minWeight = 9
female.maxWeight = 16
female.wildFleeTimeUntilDeadTimer = STRAY_NO_BLEEDOUT
female.breeds = AnimalDefinitions.breeds["dog"].breeds
female.stages = AnimalDefinitions.stages["dog"].stages
female.genes = AnimalDefinitions.genome["dog"].genes
AnimalDefinitions.animals["dogfemale"] = female

local male = {}
applyDogModel(male, "Caramelo_Body")
applyDogBehaviour(male)
male.male = true
male.mate = "dogfemale"
male.babyType = "dogpup"
male.dontAttackOtherMale = true
male.shadoww = 0.3
male.shadowfm = 0.5
male.shadowbm = 0.5
male.minSize = 1.17
male.maxSize = 1.69
male.wanderMul = 600
male.hungerMultiplier = 0.008
male.thirstMultiplier = 0.016
male.hungerBoost = 20
male.thirstBoost = 25
male.baseEncumbrance = 20
male.trailerBaseSize = 50
male.minEnclosureSize = 40
male.minAge = 3 * 30
male.maxAgeGeriatric = 19 * 30
male.minAgeForBaby = 3 * 30
male.minWeight = 10
male.maxWeight = 18
male.wildFleeTimeUntilDeadTimer = STRAY_NO_BLEEDOUT
male.breeds = AnimalDefinitions.breeds["dog"].breeds
male.stages = AnimalDefinitions.stages["dog"].stages
male.genes = AnimalDefinitions.genome["dog"].genes
AnimalDefinitions.animals["dogmale"] = male

AnimalDefinitions.animals["dogpup"].breeds["brown"].sounds = dog_sounds
AnimalDefinitions.animals["dogfemale"].breeds["brown"].sounds = dog_sounds
AnimalDefinitions.animals["dogmale"].breeds["brown"].sounds = dog_sounds

-- Tipos German Shepherd: mesmo esqueleto/animset/comportamento de cachorro, mas sua propria MESH de corpo
-- (GermanShepherd_Body) e textura de breed. O tipo separado e obrigatorio porque a engine vincula a mesh por tipo de animal, nao por breed.
local gspup = {}
applyDogModel(gspup, "GermanShepherd_Body")
applyDogBehaviour(gspup)
gspup.shadoww = 0.2
gspup.shadowfm = 0.2
gspup.shadowbm = 0.2
gspup.minSize = 1.12
gspup.maxSize = 1.68
gspup.wanderMul = 500
gspup.hungerMultiplier = 0.001
gspup.thirstMultiplier = 0.002
gspup.hungerBoost = 25
gspup.thirstBoost = 30
gspup.baseEncumbrance = 10
gspup.trailerBaseSize = 30
gspup.minEnclosureSize = 40
gspup.needMom = false
gspup.eatFromMother = true
gspup.litterEatTogether = true
gspup.minWeight = 1
gspup.maxWeight = 8
gspup.wildFleeTimeUntilDeadTimer = STRAY_NO_BLEEDOUT
gspup.breeds = AnimalDefinitions.breeds["gs"].breeds
gspup.stages = AnimalDefinitions.stages["gs"].stages
gspup.genes = AnimalDefinitions.genome["dog"].genes
AnimalDefinitions.animals["gspup"] = gspup

local gsfemale = {}
applyDogModel(gsfemale, "GermanShepherd_Body")
applyDogBehaviour(gsfemale)
gsfemale.female = true
gsfemale.mate = "gsmale"
gsfemale.babyType = "gspup"
gsfemale.shadoww = 0.3
gsfemale.shadowfm = 0.5
gsfemale.shadowbm = 0.5
gsfemale.minSize = 1.68
gsfemale.maxSize = 2.24
gsfemale.wanderMul = 600
gsfemale.hungerMultiplier = 0.008
gsfemale.thirstMultiplier = 0.016
gsfemale.hungerBoost = 20
gsfemale.thirstBoost = 25
gsfemale.baseEncumbrance = 20
gsfemale.trailerBaseSize = 50
gsfemale.minEnclosureSize = 40
gsfemale.minAge = 3 * 30
gsfemale.maxAgeGeriatric = 19 * 30
gsfemale.minAgeForBaby = 3 * 30
gsfemale.timeBeforeNextPregnancy = 7
gsfemale.pregnantPeriod = 35
gsfemale.minWeight = 9
gsfemale.maxWeight = 16
gsfemale.wildFleeTimeUntilDeadTimer = STRAY_NO_BLEEDOUT
gsfemale.breeds = AnimalDefinitions.breeds["gs"].breeds
gsfemale.stages = AnimalDefinitions.stages["gs"].stages
gsfemale.genes = AnimalDefinitions.genome["dog"].genes
AnimalDefinitions.animals["gsfemale"] = gsfemale

local gsmale = {}
applyDogModel(gsmale, "GermanShepherd_Body")
applyDogBehaviour(gsmale)
gsmale.male = true
gsmale.mate = "gsfemale"
gsmale.babyType = "gspup"
gsmale.dontAttackOtherMale = true
gsmale.shadoww = 0.3
gsmale.shadowfm = 0.5
gsmale.shadowbm = 0.5
gsmale.minSize = 1.68
gsmale.maxSize = 2.43
gsmale.wanderMul = 600
gsmale.hungerMultiplier = 0.008
gsmale.thirstMultiplier = 0.016
gsmale.hungerBoost = 20
gsmale.thirstBoost = 25
gsmale.baseEncumbrance = 20
gsmale.trailerBaseSize = 50
gsmale.minEnclosureSize = 40
gsmale.minAge = 3 * 30
gsmale.maxAgeGeriatric = 19 * 30
gsmale.minAgeForBaby = 3 * 30
gsmale.minWeight = 10
gsmale.maxWeight = 18
gsmale.wildFleeTimeUntilDeadTimer = STRAY_NO_BLEEDOUT
gsmale.breeds = AnimalDefinitions.breeds["gs"].breeds
gsmale.stages = AnimalDefinitions.stages["gs"].stages
gsmale.genes = AnimalDefinitions.genome["dog"].genes
AnimalDefinitions.animals["gsmale"] = gsmale

AnimalDefinitions.animals["gspup"].breeds["germanshepherd"].sounds = dog_sounds
AnimalDefinitions.animals["gsfemale"].breeds["germanshepherd"].sounds = dog_sounds
AnimalDefinitions.animals["gsmale"].breeds["germanshepherd"].sounds = dog_sounds

-- Tipos Golden Retriever: mesmo esqueleto/animset/comportamento de cachorro, propria MESH de corpo (Retriever_Body) + textura de breed.
-- Os tamanhos ficam entre o caramelo e o GS (um cachorro grande robusto). Tipo separado porque a engine vincula a mesh por tipo.
local retrieverpup = {}
applyDogModel(retrieverpup, "Retriever_Body")
applyDogBehaviour(retrieverpup)
retrieverpup.shadoww = 0.2
retrieverpup.shadowfm = 0.2
retrieverpup.shadowbm = 0.2
retrieverpup.minSize = 1.05
retrieverpup.maxSize = 1.55
retrieverpup.wanderMul = 500
retrieverpup.hungerMultiplier = 0.001
retrieverpup.thirstMultiplier = 0.002
retrieverpup.hungerBoost = 25
retrieverpup.thirstBoost = 30
retrieverpup.baseEncumbrance = 10
retrieverpup.trailerBaseSize = 30
retrieverpup.minEnclosureSize = 40
retrieverpup.needMom = false
retrieverpup.eatFromMother = true
retrieverpup.litterEatTogether = true
retrieverpup.minWeight = 1
retrieverpup.maxWeight = 8
retrieverpup.wildFleeTimeUntilDeadTimer = STRAY_NO_BLEEDOUT
retrieverpup.breeds = AnimalDefinitions.breeds["retriever"].breeds
retrieverpup.stages = AnimalDefinitions.stages["retriever"].stages
retrieverpup.genes = AnimalDefinitions.genome["dog"].genes
AnimalDefinitions.animals["retrieverpup"] = retrieverpup

local retrieverfemale = {}
applyDogModel(retrieverfemale, "Retriever_Body")
applyDogBehaviour(retrieverfemale)
retrieverfemale.female = true
retrieverfemale.mate = "retrievermale"
retrieverfemale.babyType = "retrieverpup"
retrieverfemale.shadoww = 0.3
retrieverfemale.shadowfm = 0.5
retrieverfemale.shadowbm = 0.5
retrieverfemale.minSize = 1.5
retrieverfemale.maxSize = 2.0
retrieverfemale.wanderMul = 600
retrieverfemale.hungerMultiplier = 0.008
retrieverfemale.thirstMultiplier = 0.016
retrieverfemale.hungerBoost = 20
retrieverfemale.thirstBoost = 25
retrieverfemale.baseEncumbrance = 20
retrieverfemale.trailerBaseSize = 50
retrieverfemale.minEnclosureSize = 40
retrieverfemale.minAge = 3 * 30
retrieverfemale.maxAgeGeriatric = 19 * 30
retrieverfemale.minAgeForBaby = 3 * 30
retrieverfemale.timeBeforeNextPregnancy = 7
retrieverfemale.pregnantPeriod = 35
retrieverfemale.minWeight = 9
retrieverfemale.maxWeight = 16
retrieverfemale.wildFleeTimeUntilDeadTimer = STRAY_NO_BLEEDOUT
retrieverfemale.breeds = AnimalDefinitions.breeds["retriever"].breeds
retrieverfemale.stages = AnimalDefinitions.stages["retriever"].stages
retrieverfemale.genes = AnimalDefinitions.genome["dog"].genes
AnimalDefinitions.animals["retrieverfemale"] = retrieverfemale

local retrievermale = {}
applyDogModel(retrievermale, "Retriever_Body")
applyDogBehaviour(retrievermale)
retrievermale.male = true
retrievermale.mate = "retrieverfemale"
retrievermale.babyType = "retrieverpup"
retrievermale.dontAttackOtherMale = true
retrievermale.shadoww = 0.3
retrievermale.shadowfm = 0.5
retrievermale.shadowbm = 0.5
retrievermale.minSize = 1.5
retrievermale.maxSize = 2.15
retrievermale.wanderMul = 600
retrievermale.hungerMultiplier = 0.008
retrievermale.thirstMultiplier = 0.016
retrievermale.hungerBoost = 20
retrievermale.thirstBoost = 25
retrievermale.baseEncumbrance = 20
retrievermale.trailerBaseSize = 50
retrievermale.minEnclosureSize = 40
retrievermale.minAge = 3 * 30
retrievermale.maxAgeGeriatric = 19 * 30
retrievermale.minAgeForBaby = 3 * 30
retrievermale.minWeight = 10
retrievermale.maxWeight = 18
retrievermale.wildFleeTimeUntilDeadTimer = STRAY_NO_BLEEDOUT
retrievermale.breeds = AnimalDefinitions.breeds["retriever"].breeds
retrievermale.stages = AnimalDefinitions.stages["retriever"].stages
retrievermale.genes = AnimalDefinitions.genome["dog"].genes
AnimalDefinitions.animals["retrievermale"] = retrievermale

AnimalDefinitions.animals["retrieverpup"].breeds["golden"].sounds = dog_sounds
AnimalDefinitions.animals["retrieverfemale"].breeds["golden"].sounds = dog_sounds
AnimalDefinitions.animals["retrievermale"].breeds["golden"].sounds = dog_sounds

-- Tipos Husky: mesmo esqueleto/animset/comportamento de cachorro, propria MESH (Husky_Body) + textura de breed.
-- Cao de trenó: tamanho ~Retriever (grande) e APETITE ALTO (hungerMultiplier 0.011 vs 0.008) como custo simetrico
-- do cao de carga/resistencia. Tipo separado porque a engine vincula a mesh por tipo de animal.
local huskypup = {}
applyDogModel(huskypup, "Husky_Body")
applyDogBehaviour(huskypup)
huskypup.shadoww = 0.2
huskypup.shadowfm = 0.2
huskypup.shadowbm = 0.2
huskypup.minSize = 1.05
huskypup.maxSize = 1.55
huskypup.wanderMul = 500
huskypup.hungerMultiplier = 0.0013
huskypup.thirstMultiplier = 0.002
huskypup.hungerBoost = 25
huskypup.thirstBoost = 30
huskypup.baseEncumbrance = 10
huskypup.trailerBaseSize = 30
huskypup.minEnclosureSize = 40
huskypup.needMom = false
huskypup.eatFromMother = true
huskypup.litterEatTogether = true
huskypup.minWeight = 1
huskypup.maxWeight = 8
huskypup.wildFleeTimeUntilDeadTimer = STRAY_NO_BLEEDOUT
huskypup.breeds = AnimalDefinitions.breeds["husky"].breeds
huskypup.stages = AnimalDefinitions.stages["husky"].stages
huskypup.genes = AnimalDefinitions.genome["dog"].genes
AnimalDefinitions.animals["huskypup"] = huskypup

local huskyfemale = {}
applyDogModel(huskyfemale, "Husky_Body")
applyDogBehaviour(huskyfemale)
huskyfemale.female = true
huskyfemale.mate = "huskymale"
huskyfemale.babyType = "huskypup"
huskyfemale.shadoww = 0.3
huskyfemale.shadowfm = 0.5
huskyfemale.shadowbm = 0.5
huskyfemale.minSize = 1.5
huskyfemale.maxSize = 2.0
huskyfemale.wanderMul = 600
huskyfemale.hungerMultiplier = 0.011
huskyfemale.thirstMultiplier = 0.016
huskyfemale.hungerBoost = 20
huskyfemale.thirstBoost = 25
huskyfemale.baseEncumbrance = 20
huskyfemale.trailerBaseSize = 50
huskyfemale.minEnclosureSize = 40
huskyfemale.minAge = 3 * 30
huskyfemale.maxAgeGeriatric = 19 * 30
huskyfemale.minAgeForBaby = 3 * 30
huskyfemale.timeBeforeNextPregnancy = 7
huskyfemale.pregnantPeriod = 35
huskyfemale.minWeight = 9
huskyfemale.maxWeight = 16
huskyfemale.wildFleeTimeUntilDeadTimer = STRAY_NO_BLEEDOUT
huskyfemale.breeds = AnimalDefinitions.breeds["husky"].breeds
huskyfemale.stages = AnimalDefinitions.stages["husky"].stages
huskyfemale.genes = AnimalDefinitions.genome["dog"].genes
AnimalDefinitions.animals["huskyfemale"] = huskyfemale

local huskymale = {}
applyDogModel(huskymale, "Husky_Body")
applyDogBehaviour(huskymale)
huskymale.male = true
huskymale.mate = "huskyfemale"
huskymale.babyType = "huskypup"
huskymale.dontAttackOtherMale = true
huskymale.shadoww = 0.3
huskymale.shadowfm = 0.5
huskymale.shadowbm = 0.5
huskymale.minSize = 1.5
huskymale.maxSize = 2.15
huskymale.wanderMul = 600
huskymale.hungerMultiplier = 0.011
huskymale.thirstMultiplier = 0.016
huskymale.hungerBoost = 20
huskymale.thirstBoost = 25
huskymale.baseEncumbrance = 20
huskymale.trailerBaseSize = 50
huskymale.minEnclosureSize = 40
huskymale.minAge = 3 * 30
huskymale.maxAgeGeriatric = 19 * 30
huskymale.minAgeForBaby = 3 * 30
huskymale.minWeight = 10
huskymale.maxWeight = 18
huskymale.wildFleeTimeUntilDeadTimer = STRAY_NO_BLEEDOUT
huskymale.breeds = AnimalDefinitions.breeds["husky"].breeds
huskymale.stages = AnimalDefinitions.stages["husky"].stages
huskymale.genes = AnimalDefinitions.genome["dog"].genes
AnimalDefinitions.animals["huskymale"] = huskymale

AnimalDefinitions.animals["huskypup"].breeds["husky"].sounds = dog_sounds
AnimalDefinitions.animals["huskyfemale"].breeds["husky"].sounds = dog_sounds
AnimalDefinitions.animals["huskymale"].breeds["husky"].sounds = dog_sounds

AnimalAvatarDefinition = AnimalAvatarDefinition or {}
function CompanionDogs.applyDogAvatar(t)
    t.zoom = 10
    t.xoffset = -0.1
    t.yoffset = -0.2
    t.avatarWidth = 200
    t.avatarDir = IsoDirections.SE
    t.trailerDir = IsoDirections.SW
    t.trailerZoom = 8.5
    t.trailerXoffset = 0.2
    t.trailerYoffset = -0.3
end
local applyDogAvatar = CompanionDogs.applyDogAvatar
AnimalAvatarDefinition["dogpup"] = {}
AnimalAvatarDefinition["dogfemale"] = {}
AnimalAvatarDefinition["dogmale"] = {}
applyDogAvatar(AnimalAvatarDefinition["dogpup"])
applyDogAvatar(AnimalAvatarDefinition["dogfemale"])
applyDogAvatar(AnimalAvatarDefinition["dogmale"])
AnimalAvatarDefinition["gspup"] = {}
AnimalAvatarDefinition["gsfemale"] = {}
AnimalAvatarDefinition["gsmale"] = {}
applyDogAvatar(AnimalAvatarDefinition["gspup"])
applyDogAvatar(AnimalAvatarDefinition["gsfemale"])
applyDogAvatar(AnimalAvatarDefinition["gsmale"])
AnimalAvatarDefinition["retrieverpup"] = {}
AnimalAvatarDefinition["retrieverfemale"] = {}
AnimalAvatarDefinition["retrievermale"] = {}
applyDogAvatar(AnimalAvatarDefinition["retrieverpup"])
applyDogAvatar(AnimalAvatarDefinition["retrieverfemale"])
applyDogAvatar(AnimalAvatarDefinition["retrievermale"])
AnimalAvatarDefinition["huskypup"] = {}
AnimalAvatarDefinition["huskyfemale"] = {}
AnimalAvatarDefinition["huskymale"] = {}
applyDogAvatar(AnimalAvatarDefinition["huskypup"])
applyDogAvatar(AnimalAvatarDefinition["huskyfemale"])
applyDogAvatar(AnimalAvatarDefinition["huskymale"])
