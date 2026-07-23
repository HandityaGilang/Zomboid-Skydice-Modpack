xpUpdate = {};
xpUpdate.characterInfo = nil;

xpUpdate.lastX = 0;
xpUpdate.lastY = 0;

-- used everytime the player move
xpUpdate.onPlayerMove = function(player)
    if not player then return end
    
    local x = player:getX();
    local y = player:getY();
    
    -- pacing/sprinting xp
    if (player:IsRunning() or player:isSprinting()) and player:getStats():get(CharacterStat.ENDURANCE) > player:getStats():getEnduranceWarning() then
        if xpUpdate.randXp() then
            addXp(player, Perks.Fitness, 1)
        end
        if xpUpdate.randXp() then
            addXp(player, Perks.Sprinting, 1)
        end
    end
    
    -- aiming while moving
    if player:isAiming() and xpUpdate.randXp() and (xpUpdate.lastX ~= x or xpUpdate.lastY ~= y) and not player:getVehicle() then
        addXp(player, Perks.Nimble, 1)
    end
    
    -- walking with heavy load
    if player:getInventoryWeight() > player:getMaxWeight() * 0.5 then
        if xpUpdate.randXp() then
            addXp(player, Perks.Strength, 2)
        end
    end
    
    xpUpdate.lastX = x;
    xpUpdate.lastY = y;
end

-- when you or a npc try to hit a tree
xpUpdate.OnWeaponHitTree = function(owner, weapon)
    if not owner then return end
    if not weapon then return end
    
    local success, weaponType = pcall(function()
        return weapon:getType()
    end)
    
    if success and weaponType and weaponType ~= "BareHands" then
        addXp(owner, Perks.Strength, 2)
    end
end

-- when you or a npc try to hit something
xpUpdate.onWeaponHitXp = function(owner, weapon, hitObject, damage, hitCount)
    -- Verificacoes de seguranca
    if not owner then return end
    if not weapon then return end
    if not hitObject then return end
    
    -- Obter tipo da arma com seguranca
    local weaponType = nil
    local success1, result1 = pcall(function()
        return weapon:getType()
    end)
    if success1 then
        weaponType = result1
    end
    
    if not weaponType then return end
    
    local isShove = false
    if hitObject.isOnFloor and hitObject:isOnFloor() == false and weaponType == "BareHands" then
        isShove = true
    end
    
    local exp = 1 * (damage or 0) * 0.9;
    if exp > 3 then
        exp = 3;
    end
    
    -- add info of favourite weapon
    local modData = owner:getModData();
    if modData and isShove == false then
        local scriptItem = nil
        local success2, result2 = pcall(function()
            return weapon:getScriptItem()
        end)
        if success2 then
            scriptItem = result2
        end
        
        if scriptItem then
            local displayName = nil
            local success3, result3 = pcall(function()
                return scriptItem:getDisplayName()
            end)
            if success3 then
                displayName = result3
            end
            
            if displayName then
                local key = "Fav:"..displayName
                if modData[key] == nil then
                    modData[key] = 1;
                else
                    modData[key] = modData[key] + 1;
                end
            end
        end
    end
    
    -- Verificar se e ranged com seguranca
    local isRanged = false
    local success4, result4 = pcall(function()
        return weapon:isRanged()
    end)
    if success4 then
        isRanged = result4
    end
    
    -- if you sucessful swing your non ranged weapon
    if owner:getStats():get(CharacterStat.ENDURANCE) > owner:getStats():getEnduranceWarning() and not isRanged then
        addXp(owner, Perks.Fitness, 1)
    end
    
    -- we add xp depending on how many target you hit
    local lastHitCount = owner:getLastHitCount() or 0
    if not isRanged and lastHitCount > 0 then
        addXp(owner, Perks.Strength, lastHitCount)
    end
    
    -- add xp for ranged weapon
    if isRanged then
        local xp = hitCount or 0;
        if owner:getPerkLevel(Perks.Aiming) < 5 then
            xp = xp * 2.7;
        end
        addXp(owner, Perks.Aiming, xp)
    end
    
    -- add either blunt or blade xp
    if (hitCount or 0) > 0 and not isRanged then
        local scriptItem = nil
        local success5, result5 = pcall(function()
            return weapon:getScriptItem()
        end)
        if success5 then
            scriptItem = result5
        end
        
        if scriptItem then
            local function checkCategory(category)
                local success, result = pcall(function()
                    return scriptItem:containsWeaponCategory(category)
                end)
                return success and result
            end
            
            if checkCategory(WeaponCategory.AXE) then
                addXp(owner, Perks.Axe, exp)
            end
            if checkCategory(WeaponCategory.BLUNT) then
                addXp(owner, Perks.Blunt, exp)
            end
            if checkCategory(WeaponCategory.SPEAR) then
                addXp(owner, Perks.Spear, exp)
            end
            if checkCategory(WeaponCategory.LONG_BLADE) then
                addXp(owner, Perks.LongBlade, exp)
            end
            if checkCategory(WeaponCategory.SMALL_BLADE) then
                addXp(owner, Perks.SmallBlade, exp)
            end
            if checkCategory(WeaponCategory.SMALL_BLUNT) then
                addXp(owner, Perks.SmallBlunt, exp)
            end
        end
    end
end

-- get xp when you craft something
xpUpdate.onMakeItem = function(item, resultItem, recipe)
    if not resultItem then return end
    if instanceof(resultItem, "Food") then
        addXp(getPlayer(), Perks.Cooking, 3)
    end
end

-- if we press the toggle skill panel key we gonna display the character info screen
xpUpdate.displayCharacterInfo = function(key)
    local playerObj = getSpecificPlayer(0)
    if getGameSpeed() == 0 or not playerObj or playerObj:isDead() then
        return;
    end
    if not getPlayerData(0) then return end
    if getCore():isKey("Crafting UI", key) then
        local windowInstance = ISEntityUI.GetWindowInstance(0, "HandcraftWindow");
        if windowInstance then
            windowInstance:close();
            windowInstance:removeFromUIManager();
        else
            ISEntityUI.OpenHandcraftWindow(getSpecificPlayer(0), nil);
        end
    end
    if getCore():isKey("Toggle Skill Panel", key) then
        xpUpdate.characterInfo = getPlayerInfoPanel(playerObj:getPlayerNum());
        if xpUpdate.characterInfo then
            xpUpdate.characterInfo:toggleView(xpSystemText.skills);
        end
    end
    if getCore():isKey("Toggle Health Panel", key) then
        xpUpdate.characterInfo = getPlayerInfoPanel(playerObj:getPlayerNum());
        if xpUpdate.characterInfo then
            xpUpdate.characterInfo:toggleView(xpSystemText.health);
            if xpUpdate.characterInfo.healthView then
                xpUpdate.characterInfo.healthView.doctorLevel = playerObj:getPerkLevel(Perks.Doctor);
            end
        end
    end
    if getCore():isKey("Toggle Info Panel", key) then
        xpUpdate.characterInfo = getPlayerInfoPanel(playerObj:getPlayerNum());
        if xpUpdate.characterInfo then
            xpUpdate.characterInfo:toggleView(xpSystemText.info);
        end
    end
    if getCore():isKey("Toggle Clothing Protection Panel", key) then
        xpUpdate.characterInfo = getPlayerInfoPanel(playerObj:getPlayerNum());
        if xpUpdate.characterInfo then
            xpUpdate.characterInfo:toggleView(xpSystemText.protection);
        end
    end
end

-- do we get xp ?
xpUpdate.randXp = function()
    if isServer() then
        return ZombRand(100 * GameTime.getInstance():getInvMultiplier()) == 0;
    else
        return ZombRand(700 * GameTime.getInstance():getInvMultiplier()) == 0;
    end
end

-- handle when you gain xp, we gonna apply the xp multiplier
xpUpdate.addXp = function(owner, type, amount)
    if not owner then return end
    
    local modData = xpUpdate.getModData(owner)
    if not modData then return end

    if type == Perks.Strength and amount > 0 then
        modData.strengthUpTimer = modData.strengthUpTimer - 3000;
        if modData.strengthUpTimer < -50000 then
            modData.strengthUpTimer = -50000;
        end
    end

    if type == Perks.Fitness and amount > 0 then
        modData.fitnessUpTimer = modData.fitnessUpTimer - 3000;
        if modData.fitnessUpTimer < -50000 then
            modData.fitnessUpTimer = -50000;
        end
    end

    if type == Perks.PlantScavenging and amount > 0 then
        local amount2 = round(amount, 2)
        HaloTextHelper.addTextWithArrow(owner, type:getName().." "..getText("Challenge_Challenge2_CurrentXp", amount2), "[br/]", true, HaloTextHelper.getGoodColor());
    end
end

-- when you gain a level you could win or lose perks
xpUpdate.levelPerk = function(owner, perk, level, addBuffer)
    if not owner then return end
    
    -- check AutoLearn craftRecipes
    getScriptManager():checkAutoLearn(owner)

    -- first Strength skill
    if perk == Perks.Strength then
        owner:getCharacterTraits():remove(CharacterTrait.WEAK);
        owner:getCharacterTraits():remove(CharacterTrait.FEEBLE);
        owner:getCharacterTraits():remove(CharacterTrait.STOUT);
        owner:getCharacterTraits():remove(CharacterTrait.STRONG);

        if level >= 0 and level <= 1 then
            owner:getCharacterTraits():add(CharacterTrait.WEAK);
        elseif level >= 2 and level <= 4 then
            owner:getCharacterTraits():add(CharacterTrait.FEEBLE);
        elseif level >= 6 and level <= 8 then
            owner:getCharacterTraits():add(CharacterTrait.STOUT);
        elseif level >= 9 then
            owner:getCharacterTraits():add(CharacterTrait.STRONG);
        end
    end

    -- then Fitness skill
    if perk == Perks.Fitness then
        owner:getCharacterTraits():remove(CharacterTrait.UNFIT);
        owner:getCharacterTraits():remove(CharacterTrait.OUT_OF_SHAPE);
        owner:getCharacterTraits():remove(CharacterTrait.FIT);
        owner:getCharacterTraits():remove(CharacterTrait.ATHLETIC);

        if level >= 0 and level <= 1 then
            owner:getCharacterTraits():add(CharacterTrait.UNFIT);
        elseif level >= 2 and level <= 4 then
            owner:getCharacterTraits():add(CharacterTrait.OUT_OF_SHAPE);
        elseif level >= 6 and level <= 8 then
            owner:getCharacterTraits():add(CharacterTrait.FIT);
        elseif level >= 9 then
            owner:getCharacterTraits():add(CharacterTrait.ATHLETIC);
        end
    end

    local modifier = 0
    if owner:hasTrait(CharacterTrait.INVENTIVE) then modifier = 1 end
    
    -- learn all the growing seasons at Farming 10
    if perk == Perks.Farming and level + modifier > 9 then
        if farming_vegetableconf and farming_vegetableconf.props then
            for typeOfSeed,props in pairs(farming_vegetableconf.props) do
                if props.seasonRecipe then
                    xpUpdate.checkForLearningRecipe(owner, props.seasonRecipe)
                end
            end
        end
    end
    
    -- learn Mechanics recipes at high levels of Mechanics
    if perk == Perks.Mechanics then
        if level + modifier > 9 then
            xpUpdate.checkForLearningRecipe(owner, "Advanced Mechanics")
        end
        if level + modifier > 8 then
            xpUpdate.checkForLearningRecipe(owner, "Intermediate Mechanics")
        end
        if level + modifier > 7 then
            xpUpdate.checkForLearningRecipe(owner, "Basic Mechanics")
        end
    end
    
    -- learn Generator at Electrical 3
    if perk == Perks.Electricity and level + modifier > 2 then
        xpUpdate.checkForLearningRecipe(owner, "Generator")
    end
end

xpUpdate.checkForLearningRecipe = function(playerObj, recipe)
    if not playerObj or not recipe then return end
    if playerObj:isRecipeActuallyKnown(recipe) then return end

    playerObj:learnRecipe(recipe)
    HaloTextHelper.addGoodText(playerObj, Translator.getText("IGUI_HaloNote_LearnedRecipe", getRecipeDisplayName(recipe)), "[br/]")
end

xpUpdate.checkForLosingLevel = function(playerObj, perk)
    if not playerObj or not perk then return end
    
    local info = playerObj:getPerkInfo(perk);
    if info then
        local level = info:getLevel()
        if level >= 1 and level <= 10 and playerObj:getXp():getXP(perk) < PerkFactory.getPerk(perk):getTotalXpForLevel(level) then
            playerObj:LoseLevel(perk);
        end
    end
end

xpUpdate.everyTenMinutes = function()
    for playerIndex=0,getNumActivePlayers()-1 do
        local playerObj = getSpecificPlayer(playerIndex)
        if playerObj and not playerObj:isDead() then
            local modData = xpUpdate.getModData(playerObj)
            if modData then
                -- strength stuff
                modData.strengthUpTimer = modData.strengthUpTimer + 10;
                if modData.strengthUpTimer > 20000 and modData.strengthMod ~= math.floor(modData.strengthUpTimer / 1200) then
                    modData.strengthMod = math.floor(modData.strengthUpTimer / 1200);
                    if playerObj:getXp():getXP(Perks.Strength) > 0 then
                        sendAddXp(playerObj, Perks.Strength, -1, true);
                    end
                    xpUpdate.checkForLosingLevel(playerObj, Perks.Strength);
                end
                if modData.strengthUpTimer > 31000 then
                    modData.strengthUpTimer = 0;
                end
                
                -- fitness stuff
                modData.fitnessUpTimer = modData.fitnessUpTimer + 10;
                if modData.fitnessUpTimer > 20000 and modData.fitnessMod ~= math.floor(modData.fitnessUpTimer / 1200) then
                    modData.fitnessMod = math.floor(modData.fitnessUpTimer / 1200);
                    if playerObj:getXp():getXP(Perks.Fitness) > 0 then
                        sendAddXp(playerObj, Perks.Fitness, -1, true);
                    end
                    xpUpdate.checkForLosingLevel(playerObj, Perks.Fitness);
                end
                if modData.fitnessUpTimer > 31000 then
                    modData.fitnessUpTimer = 0;
                end
            end
        end
    end
end

-- load our losing xp timer
xpUpdate.getModData = function(playerObj)
    if playerObj then
        local modData = playerObj:getModData()
        if modData then
            modData.strengthUpTimer = tonumber(modData.strengthUpTimer) or -50000
            modData.strengthMod = modData.strengthMod or 0
            modData.fitnessUpTimer = tonumber(modData.fitnessUpTimer) or -50000
            modData.fitnessMod = modData.fitnessMod or 0
            return modData
        end
    end
    return nil
end

xpUpdate.onNewGame = function(playerObj, square)
    if playerObj and playerObj:getFitness() then
        playerObj:getFitness():init();
    end
end

xpUpdate.onLoad = function()
    local playerObj = getSpecificPlayer(0)
    if not playerObj then return end
    
    local modifier = 0
    if playerObj:hasTrait(CharacterTrait.INVENTIVE) then modifier = 1 end
    
    -- learn all the growing seasons at Farming 10
    if playerObj:getPerkLevel(Perks.Farming) + modifier > 9 then
        if farming_vegetableconf and farming_vegetableconf.props then
            for typeOfSeed,props in pairs(farming_vegetableconf.props) do
                if props.seasonRecipe then
                    playerObj:learnRecipe(props.seasonRecipe)
                end
            end
        end
    end
    
    -- learn Mechanics recipes at high levels of Mechanics
    if playerObj:getPerkLevel(Perks.Mechanics) + modifier > 9 then
        playerObj:learnRecipe("Advanced Mechanics")
    end
    if playerObj:getPerkLevel(Perks.Mechanics) + modifier > 8 then
        playerObj:learnRecipe("Intermediate Mechanics")
    end
    if playerObj:getPerkLevel(Perks.Mechanics) + modifier > 7 then
        playerObj:learnRecipe("Basic Mechanics")
    end
    
    -- learn Generator at Electrical 3
    if playerObj:getPerkLevel(Perks.Electricity) + modifier > 2 then
        playerObj:learnRecipe("Generator")
    end
end

Events.EveryTenMinutes.Add(xpUpdate.everyTenMinutes);
Events.OnPlayerMove.Add(xpUpdate.onPlayerMove);
Events.OnWeaponHitXp.Add(xpUpdate.onWeaponHitXp);
Events.OnWeaponHitTree.Add(xpUpdate.OnWeaponHitTree);
Events.OnKeyPressed.Add(xpUpdate.displayCharacterInfo);
Events.AddXP.Add(xpUpdate.addXp);
Events.LevelPerk.Add(xpUpdate.levelPerk);
Events.OnNewGame.Add(xpUpdate.onNewGame);
Events.OnLoad.Add(xpUpdate.onLoad);
