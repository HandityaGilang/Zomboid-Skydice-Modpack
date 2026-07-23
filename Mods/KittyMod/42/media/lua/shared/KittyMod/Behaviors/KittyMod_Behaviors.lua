local KittyMod_Behaviors = {}

local KittyMod_ModData = require("KittyMod/Core/KittyMod_ModData")
local KittyMod_SafeAPI = require("KittyMod/Core/KittyMod_SafeAPI")

local CatBehaviors = {
    hunting = false,
    playing = false,
    grooming = false,
    sleeping = false,
    exploring = false,
    affection = false
}

local catInteractionCooldowns = {}

function KittyMod_Behaviors.initialize()
    Events.OnCreateLivingCharacter.Add(KittyMod_Behaviors.onAnimalCreated)
    Events.OnPlayerMove.Add(KittyMod_Behaviors.onPlayerMovement)
    Events.OnObjectRightMouseButtonUp.Add(KittyMod_Behaviors.onPlayerInteraction)
    Events.EveryTenMinutes.Add(KittyMod_Behaviors.onTimeBasedBehaviors)
    Events.OnGameTimeLoaded.Add(KittyMod_Behaviors.onTimeUpdate)
end

function KittyMod_Behaviors.onAnimalCreated(animal)
    if not animal or not animal:isAnimal() then return end
    if not KittyMod_ModData.isCat(animal) then return end
    
    KittyMod_Behaviors.initializeCatBehavior(animal)
end

function KittyMod_Behaviors.initializeCatBehavior(cat)
    if not cat then return false end
    
    local personality = KittyMod_ModData.getCatData(cat, "CatPersonality")
    if not personality then
        personality = KittyMod_Behaviors.generateRandomPersonality()
        KittyMod_ModData.setCatData(cat, "CatPersonality", personality)
    end
    
    KittyMod_Behaviors.applyPersonalityTraits(cat, personality)
    
    return true
end

function KittyMod_Behaviors.generateRandomPersonality()
    local personalities = {"playful", "lazy", "curious", "shy", "aggressive", "friendly", "independent", "clingy", "hunter", "sleepy"}
    return personalities[ZombRand(1, #personalities + 1)]
end

function KittyMod_Behaviors.applyPersonalityTraits(cat, personality)
    if not cat or not personality then return end
    
    local traitMultipliers = {
        playful = {playfulness = 1.5, energy = 1.2, huntingSkill = 0.8},
        lazy = {energy = 0.6, playfulness = 0.5, loyalty = 1.2},
        curious = {playfulness = 1.2, huntingSkill = 1.1, energy = 1.1},
        shy = {affection = 0.7, loyalty = 1.3, playfulness = 0.8},
        aggressive = {huntingSkill = 1.4, affection = 0.6, energy = 1.1},
        friendly = {affection = 1.4, loyalty = 1.1, playfulness = 1.1},
        independent = {loyalty = 0.8, affection = 0.9, huntingSkill = 1.2},
        clingy = {affection = 1.5, loyalty = 1.4, playfulness = 0.9},
        hunter = {huntingSkill = 1.6, energy = 1.3, playfulness = 0.7},
        sleepy = {energy = 0.5, playfulness = 0.6, loyalty = 1.1}
    }
    
    local multipliers = traitMultipliers[personality] or {}
    
    for trait, multiplier in pairs(multipliers) do
        local currentValue = KittyMod_ModData.getCatData(cat, "Cat" .. trait:gsub("^%l", string.upper)) or 50
        local newValue = math.min(100, math.max(0, currentValue * multiplier))
        KittyMod_ModData.setCatData(cat, "Cat" .. trait:gsub("^%l", string.upper), newValue)
    end
end

function KittyMod_Behaviors.onPlayerMovement(player)
    if not player then return end
    
    local nearbyAnimals = KittyMod_SafeAPI.getAnimalsInRange(player, 10)
    if nearbyAnimals then
        for i = 0, nearbyAnimals:size() - 1 do
            local animal = nearbyAnimals:get(i)
            if KittyMod_ModData.isCat(animal) then
                KittyMod_Behaviors.checkCatReaction(animal, player)
            end
        end
    end
end

function KittyMod_Behaviors.checkCatReaction(cat, player)
    if not cat or not player then return end
    
    local personality = KittyMod_ModData.getCatData(cat, "CatPersonality")
    local tameness = KittyMod_ModData.getCatData(cat, "CatTameness") or 0
    local affection = KittyMod_ModData.getCatData(cat, "CatAffection") or 0
    
    local reactionChance = KittyMod_Behaviors.calculateReactionChance(personality, tameness, affection)
    
    if ZombRand(100) < reactionChance then
        KittyMod_Behaviors.triggerCatReaction(cat, player, personality)
    end
end

function KittyMod_Behaviors.calculateReactionChance(personality, tameness, affection)
    local baseChance = 10
    
    local personalityModifiers = {
        friendly = 25,
        clingy = 30,
        shy = 5,
        independent = 8,
        curious = 20,
        playful = 15,
        lazy = 5,
        aggressive = 12,
        hunter = 10,
        sleepy = 3
    }
    
    local personalityBonus = personalityModifiers[personality] or 10
    local tamenessBonus = tameness / 5
    local affectionBonus = affection / 10
    
    return math.min(80, baseChance + personalityBonus + tamenessBonus + affectionBonus)
end

function KittyMod_Behaviors.triggerCatReaction(cat, player, personality)
    if not cat or not player then return end
    
    local reactionTypes = {
        friendly = {"approach", "purr", "rub"},
        clingy = {"approach", "follow", "meow"},
        shy = {"hide", "retreat", "watch"},
        independent = {"ignore", "watch", "groom"},
        curious = {"approach", "investigate", "sniff"},
        playful = {"pounce", "play", "chase"},
        lazy = {"stretch", "yawn", "ignore"},
        aggressive = {"hiss", "arch", "retreat"},
        hunter = {"stalk", "crouch", "focus"},
        sleepy = {"yawn", "stretch", "nap"}
    }
    
    local reactions = reactionTypes[personality] or {"watch"}
    local reaction = reactions[ZombRand(1, #reactions + 1)]
    
    KittyMod_Behaviors.executeCatReaction(cat, player, reaction)
end

function KittyMod_Behaviors.executeCatReaction(cat, player, reaction)
    if not cat or not player then return end
    
    local catName = KittyMod_ModData.getCatData(cat, "CatNickname") or "Cat"
    
    local reactionMessages = {
        approach = catName .. " approaches you curiously",
        purr = catName .. " purrs contentedly near you", 
        rub = catName .. " rubs against your leg",
        follow = catName .. " starts following you",
        meow = catName .. " meows at you for attention",
        hide = catName .. " hides behind something",
        retreat = catName .. " moves away cautiously",
        watch = catName .. " watches you from a distance",
        ignore = catName .. " completely ignores you",
        groom = catName .. " starts grooming themselves",
        investigate = catName .. " comes to investigate you",
        sniff = catName .. " sniffs the air near you",
        pounce = catName .. " playfully pounces near you",
        play = catName .. " starts playing with something nearby",
        chase = catName .. " chases something imaginary",
        stretch = catName .. " stretches luxuriously",
        yawn = catName .. " yawns sleepily",
        hiss = catName .. " hisses softly",
        arch = catName .. " arches their back",
        stalk = catName .. " crouches in a stalking position",
        crouch = catName .. " crouches low to the ground",
        focus = catName .. " focuses intently on something",
        nap = catName .. " curls up for a nap"
    }
    
    local message = reactionMessages[reaction] or catName .. " does something cat-like"
    player:Say(message)
    
    KittyMod_Behaviors.updateCatMood(cat, reaction)
end

function KittyMod_Behaviors.updateCatMood(cat, reaction)
    if not cat then return end
    
    local currentMood = KittyMod_ModData.getCatData(cat, "CatMood") or "content"
    local affection = KittyMod_ModData.getCatData(cat, "CatAffection") or 0
    
    local positiveReactions = {"approach", "purr", "rub", "follow", "meow", "investigate", "sniff", "play"}
    local negativeReactions = {"hide", "retreat", "hiss", "arch"}
    
    if table.contains(positiveReactions, reaction) then
        affection = math.min(100, affection + ZombRand(1, 3))
        KittyMod_ModData.setCatData(cat, "CatAffection", affection)
        
        if affection > 70 and currentMood ~= "happy" then
            KittyMod_ModData.setCatData(cat, "CatMood", "happy")
        elseif affection > 40 and currentMood == "sad" then
            KittyMod_ModData.setCatData(cat, "CatMood", "content")
        end
    elseif table.contains(negativeReactions, reaction) then
        affection = math.max(0, affection - ZombRand(1, 2))
        KittyMod_ModData.setCatData(cat, "CatAffection", affection)
        
        if affection < 20 then
            KittyMod_ModData.setCatData(cat, "CatMood", "sad")
        end
    end
end

function KittyMod_Behaviors.onPlayerInteraction(object, x, y, player)
    if not object or not instanceof(object, "IsoAnimal") then return end
    if not KittyMod_ModData.isCat(object) then return end
    
    local catID = object:getOnlineID()
    local currentTime = getTimestamp()
    
    if catInteractionCooldowns[catID] and currentTime - catInteractionCooldowns[catID] < 5000 then
        return
    end
    
    catInteractionCooldowns[catID] = currentTime
    
    KittyMod_Behaviors.handleDirectCatInteraction(object, player)
end

function KittyMod_Behaviors.handleDirectCatInteraction(cat, player)
    if not cat or not player then return end
    
    local tameness = KittyMod_ModData.getCatData(cat, "CatTameness") or 0
    local personality = KittyMod_ModData.getCatData(cat, "CatPersonality")
    local isTamed = KittyMod_ModData.getCatData(cat, "CatIsTamed") or false
    
    if isTamed then
        KittyMod_Behaviors.handleTamedCatInteraction(cat, player)
    else
        KittyMod_Behaviors.handleWildCatInteraction(cat, player, tameness, personality)
    end
end

function KittyMod_Behaviors.handleTamedCatInteraction(cat, player)
    local catName = KittyMod_ModData.getCatData(cat, "CatNickname") or "Your cat"
    local affection = KittyMod_ModData.getCatData(cat, "CatAffection") or 0
    
    local interactions = {"pet", "talk", "play"}
    local interaction = interactions[ZombRand(1, #interactions + 1)]
    
    if interaction == "pet" then
        player:Say("You pet " .. catName .. " gently")
        affection = math.min(100, affection + ZombRand(2, 5))
        KittyMod_ModData.setCatData(cat, "CatAffection", affection)
    elseif interaction == "talk" then
        player:Say("You talk softly to " .. catName)
    elseif interaction == "play" then
        player:Say("You play with " .. catName .. " for a moment")
        local playfulness = KittyMod_ModData.getCatData(cat, "CatPlayfulness") or 0
        playfulness = math.min(100, playfulness + ZombRand(1, 3))
        KittyMod_ModData.setCatData(cat, "CatPlayfulness", playfulness)
    end
end

function KittyMod_Behaviors.handleWildCatInteraction(cat, player, tameness, personality)
    local trustModifiers = {
        friendly = 5,
        curious = 4,
        shy = 1,
        independent = 2,
        aggressive = 1,
        clingy = 6,
        playful = 3,
        lazy = 2,
        hunter = 2,
        sleepy = 1
    }
    
    local trustGain = trustModifiers[personality] or 2
    tameness = math.min(100, tameness + trustGain)
    KittyMod_ModData.setCatData(cat, "CatTameness", tameness)
    
    if tameness >= 80 and not KittyMod_ModData.getCatData(cat, "CatIsTamed") then
        KittyMod_Behaviors.tameCat(cat, player)
    else
        player:Say("The cat seems a bit more trusting of you")
    end
end

function KittyMod_Behaviors.tameCat(cat, player)
    if not cat or not player then return end
    
    KittyMod_ModData.setCatData(cat, "CatIsTamed", true)
    KittyMod_ModData.setCatData(cat, "CatOwner", player:getUsername())
    
    local catName = "Cat" .. ZombRand(1, 1000)
    KittyMod_ModData.setCatData(cat, "CatNickname", catName)
    
    player:Say("You have successfully tamed the cat! You decide to call it " .. catName)
    
    sendServerCommand("KittyMod_AnimalService", "animalEvent", {
        eventType = "OnCatTamed", 
        animalID = cat:getOnlineID(),
        playerID = player:getUsername(),
        animalType = "cat",
        data = {cat = cat, player = player, name = catName}
    })
end

function KittyMod_Behaviors.onTimeBasedBehaviors()
    local player = getPlayer()
    if not player then return end
    
    local nearbyAnimals = KittyMod_SafeAPI.getAnimalsInRange(player, 20)
    if nearbyAnimals then
        for i = 0, nearbyAnimals:size() - 1 do
            local animal = nearbyAnimals:get(i)
            if KittyMod_ModData.isCat(animal) then
                KittyMod_Behaviors.updateCatNeeds(animal)
            end
        end
    end
end

function KittyMod_Behaviors.updateCatNeeds(cat)
    if not cat then return end
    
    local energy = KittyMod_ModData.getCatData(cat, "CatEnergy") or 100
    local mood = KittyMod_ModData.getCatData(cat, "CatMood") or "content"
    
    energy = math.max(0, energy - ZombRand(1, 3))
    KittyMod_ModData.setCatData(cat, "CatEnergy", energy)
    
    if energy < 20 and mood ~= "tired" then
        KittyMod_ModData.setCatData(cat, "CatMood", "tired")
    elseif energy > 60 and mood == "tired" then
        KittyMod_ModData.setCatData(cat, "CatMood", "content")
    end
end

function KittyMod_Behaviors.onTimeUpdate()
    local currentTime = getTimestamp()
    
    for catID, lastInteraction in pairs(catInteractionCooldowns) do
        if currentTime - lastInteraction > 30000 then
            catInteractionCooldowns[catID] = nil
        end
    end
end

function KittyMod_Behaviors.getPersonalityInteractionData(cat, context)
    if not cat or not KittyMod_ModData.isCat(cat) then return nil end
    
    local personality = KittyMod_ModData.getCatData(cat, "CatPersonality") or "curious"
    local mood = KittyMod_ModData.getCatData(cat, "CatMood") or "content"
    local affection = KittyMod_ModData.getCatData(cat, "CatAffection") or 50
    
    local interactionData = {
        personality = personality,
        mood = mood,
        affection = affection,
        interactionProbability = 0.5,
        preferredInteractions = {},
        avoidedInteractions = {}
    }
    
    if personality == "friendly" then
        interactionData.interactionProbability = 0.8
        interactionData.preferredInteractions = {"pet", "play", "follow"}
        interactionData.avoidedInteractions = {"chase"}
    elseif personality == "shy" then
        interactionData.interactionProbability = 0.2
        interactionData.preferredInteractions = {"quiet_presence"}
        interactionData.avoidedInteractions = {"loud_interaction", "sudden_movement"}
    elseif personality == "playful" then
        interactionData.interactionProbability = 0.7
        interactionData.preferredInteractions = {"play", "chase", "toy_interaction"}
        interactionData.avoidedInteractions = {"rest_disturbance"}
    elseif personality == "independent" then
        interactionData.interactionProbability = 0.3
        interactionData.preferredInteractions = {"respect_distance"}
        interactionData.avoidedInteractions = {"forced_interaction"}
    end
    
    return interactionData
end

function KittyMod_Behaviors.handleCrossAnimalInteraction(cat, targetAnimal)
    if not cat or not targetAnimal or not KittyMod_ModData.isCat(cat) then return nil end
    
    local personality = KittyMod_ModData.getCatData(cat, "CatPersonality") or "curious"
    local mood = KittyMod_ModData.getCatData(cat, "CatMood") or "content"
    local socializable = true
    
    if personality == "aggressive" then
        socializable = false
    elseif personality == "shy" and mood ~= "happy" then
        socializable = false
    end
    
    local interactionResult = {
        success = socializable,
        interactionType = "neutral",
        moodChange = nil,
        affectionChange = 0
    }
    
    if socializable then
        if personality == "friendly" or personality == "playful" then
            interactionResult.interactionType = "positive"
            interactionResult.moodChange = "happy"
            interactionResult.affectionChange = 3
            
            KittyMod_ModData.setCatData(cat, "CatMood", "happy")
            local currentAffection = KittyMod_ModData.getCatData(cat, "CatAffection") or 50
            KittyMod_ModData.setCatData(cat, "CatAffection", math.min(100, currentAffection + 3))
        elseif personality == "curious" then
            interactionResult.interactionType = "investigative"
            interactionResult.affectionChange = 1
            
            local currentAffection = KittyMod_ModData.getCatData(cat, "CatAffection") or 50
            KittyMod_ModData.setCatData(cat, "CatAffection", math.min(100, currentAffection + 1))
        end
    end
    
    return interactionResult
end

function KittyMod_Behaviors.adaptToEnvironment(cat, environment)
    if not cat or not environment or not KittyMod_ModData.isCat(cat) then return nil end
    
    local personality = KittyMod_ModData.getCatData(cat, "CatPersonality") or "curious"
    local currentEnergy = KittyMod_ModData.getCatData(cat, "CatEnergy") or 100
    
    local adaptationData = {
        environmentType = environment.type or "unknown",
        adaptation = "neutral",
        energyCost = 5,
        skillBonus = 0,
        discoveredItems = {}
    }
    
    if environment.type == "urban" then
        if personality == "curious" or personality == "independent" then
            adaptationData.adaptation = "good"
            adaptationData.energyCost = 3
            adaptationData.discoveredItems = {"scrap", "food_remnant"}
        else
            adaptationData.energyCost = 8
        end
    elseif environment.type == "rural" or environment.type == "forest" then
        if personality == "hunter" or personality == "aggressive" then
            adaptationData.adaptation = "excellent"
            adaptationData.energyCost = 2
            adaptationData.skillBonus = 2
            adaptationData.discoveredItems = {"prey_scent", "hunting_ground"}
        elseif personality == "curious" then
            adaptationData.adaptation = "good" 
            adaptationData.discoveredItems = {"interesting_plant", "hiding_spot"}
        end
    elseif environment.type == "indoor" then
        if personality == "lazy" or personality == "sleepy" then
            adaptationData.adaptation = "excellent"
            adaptationData.energyCost = 1
        elseif personality == "playful" then
            adaptationData.discoveredItems = {"toy", "comfortable_spot"}
        end
    end
    
    KittyMod_ModData.setCatData(cat, "CatEnergy", math.max(0, currentEnergy - adaptationData.energyCost))
    
    if adaptationData.skillBonus > 0 then
        local huntingSkill = KittyMod_ModData.getCatData(cat, "CatHuntingSkill") or 50
        KittyMod_ModData.setCatData(cat, "CatHuntingSkill", math.min(100, huntingSkill + adaptationData.skillBonus))
    end
    
    return adaptationData
end

Events.OnGameStart.Add(KittyMod_Behaviors.initialize)

return KittyMod_Behaviors