local KittyMod_Commands = {}

local KittyMod_ModData = require("KittyMod/Core/KittyMod_ModData")
local KittyMod_SafeAPI = require("KittyMod/Core/KittyMod_SafeAPI")

local CatCommands = {
    "come", "stay", "sit", "follow", "hunt", "play", "sleep", "explore"
}

local catCommandStates = {}

function KittyMod_Commands.initialize()
    if Events then
        if Events.OnPlayerInput then
            Events.OnPlayerInput.Add(KittyMod_Commands.onPlayerInput)
        end
        if Events.OnKeyPressed then
            Events.OnKeyPressed.Add(KittyMod_Commands.onKeyPressed)
        end
        if Events.EveryTenMinutes then
            Events.EveryTenMinutes.Add(KittyMod_Commands.updateCommandStates)
        end
    end
end

function KittyMod_Commands.onPlayerInput(player, input)
    if not player or not input then return end
    
    local inputText = input:lower():trim()
    
    for _, command in ipairs(CatCommands) do
        if inputText:contains(command) then
            KittyMod_Commands.executeCommand(player, command)
            break
        end
    end
end

function KittyMod_Commands.onKeyPressed(key)
    local player = getPlayer()
    if not player then return end
    
    if key == Keyboard.KEY_K then
        KittyMod_Commands.showCatCommandMenu(player)
    end
end

function KittyMod_Commands.showCatCommandMenu(player)
    if not player then return end
    
    local nearestCat = KittyMod_Commands.findNearestOwnedCat(player)
    if not nearestCat then
        player:Say("No trained cats nearby")
        return
    end
    
    local catName = KittyMod_ModData.getCatData(nearestCat, "CatNickname") or "Cat"
    local commandsText = "Commands for " .. catName .. ":\n"
    commandsText = commandsText .. "1. Come  2. Stay  3. Sit  4. Follow\n"
    commandsText = commandsText .. "5. Hunt  6. Play  7. Sleep  8. Explore"
    
    player:Say(commandsText)
end

function KittyMod_Commands.findNearestOwnedCat(player)
    if not player then return nil end
    
    local nearbyAnimals = KittyMod_SafeAPI.getAnimalsInRange(player, 10)
    if not nearbyAnimals then return nil end
    
    local nearestCat = nil
    local nearestDistance = 999
    local playerUsername = player:getUsername()
    
    for i = 0, nearbyAnimals:size() - 1 do
        local animal = nearbyAnimals:get(i)
        if KittyMod_ModData.isCat(animal) then
            local isTamed = KittyMod_ModData.getCatData(animal, "CatIsTamed")
            local owner = KittyMod_ModData.getCatData(animal, "CatOwner")
            
            if isTamed and owner == playerUsername then
                local distance = IsoUtils.DistanceTo(player:getX(), player:getY(), animal:getX(), animal:getY())
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestCat = animal
                end
            end
        end
    end
    
    return nearestCat
end

function KittyMod_Commands.executeCommand(player, command)
    if not player or not command then return end
    
    local targetCat = KittyMod_Commands.findNearestOwnedCat(player)
    if not targetCat then
        player:Say("No trained cats nearby to command")
        return
    end
    
    local catName = KittyMod_ModData.getCatData(targetCat, "CatNickname") or "Cat"
    local loyalty = KittyMod_ModData.getCatData(targetCat, "CatLoyalty") or 0
    local personality = KittyMod_ModData.getCatData(targetCat, "CatPersonality")
    
    local obedienceChance = KittyMod_Commands.calculateObedienceChance(loyalty, personality, command)
    
    if ZombRand(100) < obedienceChance then
        KittyMod_Commands.executeSuccessfulCommand(targetCat, player, command, catName)
    else
        KittyMod_Commands.executeFailedCommand(targetCat, player, command, catName, personality)
    end
end

function KittyMod_Commands.calculateObedienceChance(loyalty, personality, command)
    local baseChance = 30
    local loyaltyBonus = loyalty / 2
    
    local personalityModifiers = {
        friendly = 20,
        clingy = 25,
        independent = -15,
        shy = -5,
        playful = 10,
        lazy = -10,
        aggressive = -20,
        curious = 5,
        hunter = 0,
        sleepy = -15
    }
    
    local commandDifficulty = {
        come = 0,
        follow = 5,
        sit = 10,
        stay = 15,
        play = -5,
        hunt = 20,
        sleep = 5,
        explore = 25
    }
    
    local personalityMod = personalityModifiers[personality] or 0
    local difficultyPenalty = commandDifficulty[command] or 10
    
    return math.min(95, math.max(5, baseChance + loyaltyBonus + personalityMod - difficultyPenalty))
end

function KittyMod_Commands.executeSuccessfulCommand(cat, player, command, catName)
    if not cat or not player then return end
    
    local catID = cat:getOnlineID()
    
    local successMessages = {
        come = catName .. " comes to you obediently",
        stay = catName .. " sits and waits patiently",
        sit = catName .. " sits down gracefully",
        follow = catName .. " starts following you closely",
        hunt = catName .. " begins prowling for prey",
        play = catName .. " starts playing energetically",
        sleep = catName .. " curls up for a nap",
        explore = catName .. " begins exploring the area"
    }
    
    player:Say(successMessages[command] or catName .. " follows your command")
    
    catCommandStates[catID] = {
        command = command,
        startTime = getTimestamp(),
        duration = KittyMod_Commands.getCommandDuration(command)
    }
    
    local loyalty = KittyMod_ModData.getCatData(cat, "CatLoyalty") or 0
    loyalty = math.min(100, loyalty + ZombRand(1, 3))
    KittyMod_ModData.setCatData(cat, "CatLoyalty", loyalty)
    
    KittyMod_Commands.applyCommandEffects(cat, command)
end

function KittyMod_Commands.executeFailedCommand(cat, player, command, catName, personality)
    if not cat or not player then return end
    
    local failureMessages = {
        independent = catName .. " gives you a look that says 'I'll do what I want'",
        shy = catName .. " seems too nervous to follow the command",
        lazy = catName .. " looks at you lazily and doesn't move",
        aggressive = catName .. " flicks their tail dismissively",
        sleepy = catName .. " yawns and ignores you"
    }
    
    local personalityMessage = failureMessages[personality]
    local message = personalityMessage or catName .. " doesn't seem to understand the command"
    
    player:Say(message)
    
    local loyalty = KittyMod_ModData.getCatData(cat, "CatLoyalty") or 0
    loyalty = math.max(0, loyalty - ZombRand(0, 1))
    KittyMod_ModData.setCatData(cat, "CatLoyalty", loyalty)
end

function KittyMod_Commands.getCommandDuration(command)
    local durations = {
        come = 0,
        stay = 300000,
        sit = 120000,
        follow = 1800000,
        hunt = 600000,
        play = 180000,
        sleep = 900000,
        explore = 1200000
    }
    
    return durations[command] or 300000
end

function KittyMod_Commands.applyCommandEffects(cat, command)
    if not cat or not command then return end
    
    local commandEffects = {
        hunt = function()
            local huntingSkill = KittyMod_ModData.getCatData(cat, "CatHuntingSkill") or 50
            huntingSkill = math.min(100, huntingSkill + ZombRand(1, 2))
            KittyMod_ModData.setCatData(cat, "CatHuntingSkill", huntingSkill)
        end,
        play = function()
            local playfulness = KittyMod_ModData.getCatData(cat, "CatPlayfulness") or 50
            playfulness = math.min(100, playfulness + ZombRand(2, 5))
            KittyMod_ModData.setCatData(cat, "CatPlayfulness", playfulness)
            
            local energy = KittyMod_ModData.getCatData(cat, "CatEnergy") or 50
            energy = math.max(0, energy - ZombRand(5, 10))
            KittyMod_ModData.setCatData(cat, "CatEnergy", energy)
        end,
        sleep = function()
            local energy = KittyMod_ModData.getCatData(cat, "CatEnergy") or 50
            energy = math.min(100, energy + ZombRand(20, 40))
            KittyMod_ModData.setCatData(cat, "CatEnergy", energy)
            
            KittyMod_ModData.setCatData(cat, "CatMood", "content")
        end,
        explore = function()
            local affection = KittyMod_ModData.getCatData(cat, "CatAffection") or 50
            affection = math.min(100, affection + ZombRand(1, 3))
            KittyMod_ModData.setCatData(cat, "CatAffection", affection)
        end
    }
    
    local effect = commandEffects[command]
    if effect then
        effect()
    end
end

function KittyMod_Commands.updateCommandStates()
    local currentTime = getTimestamp()
    local completedCommands = {}
    
    for catID, commandState in pairs(catCommandStates) do
        if currentTime - commandState.startTime >= commandState.duration then
            table.insert(completedCommands, catID)
            
            local cat = KittyMod_SafeAPI.safeGetAnimalByID(catID)
            if cat then
                KittyMod_Commands.completeCommand(cat, commandState.command)
            end
        end
    end
    
    for _, catID in ipairs(completedCommands) do
        catCommandStates[catID] = nil
    end
end

function KittyMod_Commands.completeCommand(cat, command)
    if not cat or not command then return end
    
    local catName = KittyMod_ModData.getCatData(cat, "CatNickname") or "Cat"
    
    local completionMessages = {
        stay = catName .. " finishes waiting and looks for you",
        sit = catName .. " stands up and stretches",
        follow = catName .. " stops following and explores",
        hunt = catName .. " finishes hunting and returns",
        play = catName .. " finishes playing and relaxes",
        sleep = catName .. " wakes up refreshed",
        explore = catName .. " finishes exploring and returns"
    }
    
    local player = getPlayer()
    if player and completionMessages[command] then
        player:Say(completionMessages[command])
    end
end

function KittyMod_Commands.getCurrentCommand(cat)
    if not cat then return nil end
    
    local catID = cat:getOnlineID()
    return catCommandStates[catID]
end

function KittyMod_Commands.cancelCommand(cat)
    if not cat then return false end
    
    local catID = cat:getOnlineID()
    if catCommandStates[catID] then
        catCommandStates[catID] = nil
        return true
    end
    return false
end

function KittyMod_Commands.executeEnhancedHunt(player, cat, parameters)
    if not player or not cat or not parameters then return false end
    
    local KittyMod_FrameworkBridge = require("KittyMod/Integration/KittyMod_FrameworkBridge")
    if not KittyMod_FrameworkBridge.isFeatureEnabled("commandIntegration") then
        return KittyMod_Commands.executeCommand(player, "hunt")
    end
    
    local huntingSkill = KittyMod_ModData.getCatData(cat, "CatHuntingSkill") or 50
    local personality = KittyMod_ModData.getCatData(cat, "CatPersonality") or "curious"
    
    if parameters.targetType and huntingSkill > 60 then
        KittyMod_ModData.setCatData(cat, "CatEnergy", math.max(0, (KittyMod_ModData.getCatData(cat, "CatEnergy") or 100) - 15))
        KittyMod_ModData.setCatData(cat, "CatHuntingSkill", math.min(100, huntingSkill + 2))
        
        sendServerCommand("AE_CrossModService", "statusUpdate", {
            modName = "KittyMod",
            status = "enhancedHuntCompleted",
            catID = cat:getAnimalId(),
            playerID = player:getUsername(),
            targetType = parameters.targetType,
            success = true
        })
        
        return true
    end
    
    return KittyMod_Commands.executeCommand(player, "hunt")
end

function KittyMod_Commands.executeSocialInteraction(player, cat, targetAnimal)
    if not player or not cat or not targetAnimal then return false end
    
    local KittyMod_FrameworkBridge = require("KittyMod/Integration/KittyMod_FrameworkBridge")
    if not KittyMod_FrameworkBridge.isFeatureEnabled("crossModInteraction") then
        return false
    end
    
    local personality = KittyMod_ModData.getCatData(cat, "CatPersonality") or "curious"
    local affection = KittyMod_ModData.getCatData(cat, "CatAffection") or 50
    
    if personality == "friendly" or personality == "playful" then
        KittyMod_ModData.setCatData(cat, "CatMood", "happy")
        KittyMod_ModData.setCatData(cat, "CatAffection", math.min(100, affection + 5))
        
        sendServerCommand("AE_CrossModService", "statusUpdate", {
            catID = cat:getAnimalId(),
            playerID = player:getUsername(),
            targetAnimalID = targetAnimal:getAnimalId(),
            interactionType = "friendly"
        })
        
        return true
    end
    
    return false
end

function KittyMod_Commands.executeEnvironmentalExploration(player, cat, area)
    if not player or not cat or not area then return false end
    
    local KittyMod_FrameworkBridge = require("KittyMod/Integration/KittyMod_FrameworkBridge")
    if not KittyMod_FrameworkBridge.isFeatureEnabled("behaviorEnhancement") then
        return KittyMod_Commands.executeCommand(player, "explore")
    end
    
    local curiosity = KittyMod_ModData.getCatData(cat, "CatPlayfulness") or 50
    local personality = KittyMod_ModData.getCatData(cat, "CatPersonality") or "curious"
    
    if personality == "curious" or curiosity > 60 then
        KittyMod_ModData.setCatData(cat, "CatEnergy", math.max(0, (KittyMod_ModData.getCatData(cat, "CatEnergy") or 100) - 10))
        KittyMod_ModData.setCatData(cat, "CatMood", "content")
        
        sendServerCommand("AE_CrossModService", "statusUpdate", {
            catID = cat:getAnimalId(),
            playerID = player:getUsername(),
            area = area,
            discoveries = {"interesting_scent", "hiding_spot"}
        })
        
        return true
    end
    
    return KittyMod_Commands.executeCommand(player, "explore")
end

function KittyMod_Commands.getAvailableCommands(cat, player)
    if not cat or not player then return {} end
    
    local isTamed = KittyMod_ModData.getCatData(cat, "CatIsTamed") or false
    local owner = KittyMod_ModData.getCatData(cat, "CatOwner") or ""
    
    if not isTamed or owner ~= player:getUsername() then
        return {}
    end
    
    local basicCommands = {
        {command = "come", label = "Come", description = "Call the cat to come to you"},
        {command = "stay", label = "Stay", description = "Tell the cat to stay in place"},
        {command = "sit", label = "Sit", description = "Command the cat to sit"},
        {command = "follow", label = "Follow", description = "Have the cat follow you"},
        {command = "hunt", label = "Hunt", description = "Send the cat to hunt for prey"},
        {command = "play", label = "Play", description = "Play with the cat"},
        {command = "sleep", label = "Sleep", description = "Tell the cat to rest"},
        {command = "explore", label = "Explore", description = "Let the cat explore the area"}
    }
    
    return basicCommands
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(KittyMod_Commands.initialize)
end

return KittyMod_Commands