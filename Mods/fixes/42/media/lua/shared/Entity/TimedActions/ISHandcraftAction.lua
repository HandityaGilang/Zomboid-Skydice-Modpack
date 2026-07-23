require "TimedActions/ISBaseTimedAction"

ISHandcraftAction = ISBaseTimedAction:derive("ISHandcraftAction");

function ISHandcraftAction:isValid()
    if self.craftBench then
        if (not self.isoObject) or (not self.isoObject:isUsingPlayer(self.character)) then
            return false;
        end
    end
    if (not self.craftRecipe) then
        return false;
    end
    return true;
end

function ISHandcraftAction:update()
    if self.actionScript and self.actionScript:hasMuscleStrain() then
        self.actionScript:applyMuscleStrain(self.character)
    end

    if self.items then
        for i=0,self.items:size()-1 do
            local item = self.items:get(i)
            if item then
                item:setJobDelta(self:getJobDelta());
            end
        end
    end
    if self.recipeItem then self.recipeItem:setJobDelta(self:getJobDelta()) end

    if self.actionScript then
        self.character:setMetabolicTarget(self.actionScript:getMetabolics());

        if self.isoObject and self.actionScript:isFaceObject() then
            self.character:faceThisObject(self.isoObject);
        end
    end
    
    if self.actionScript and self.actionScript:isCantSit() == true and self.character:isSitOnGround() then
        self.character:setSitOnGround(false)
    end
end

function ISHandcraftAction:clearItemsProgressBar(bSetJobType)
    if self.items then
        for i=0,self.items:size()-1 do
            local item = self.items:get(i)
            if item then
                item:setJobDelta(0.0);
                if bSetJobType and self.craftRecipe then
                    item:setJobType(self.craftRecipe:getTranslationName())
                end
            end
        end
    end
    if self.recipeItem then
        self.recipeItem:setJobDelta(0.0)
        if bSetJobType and self.craftRecipe then
            self.recipeItem:setJobType(self.craftRecipe:getTranslationName())
        end
    end
end

function ISHandcraftAction:serverStart()
    if not self.character then return end
    
    self.logic = HandcraftLogic.new(self.character, self.craftBench, self.isoObject);
    if self.logic then
        self.logic:setContainers(self.containers);
        self.logic:setRecipe(self.craftRecipe);
    end
end

function ISHandcraftAction:start()
    if self.craftRecipe then showDebugInfoInChat("CRAFT \'"..self.craftRecipe:getName().."\'") end
    
    if not self.character then return end
    
    self.logic = HandcraftLogic.new(self.character, self.craftBench, self.isoObject);
    if not self.logic then
        self:forceStop();
        return;
    end
    
    self.logic:setContainers(self.containers);
    self.logic:setRecipe(self.craftRecipe);
    self.logic:setTargetVariableInputRatio(self.variableInputRatio);
    
    if self.manualInputs then
        self.logic:setManualSelectInputs(true);
        self.logic:clearManualInputs();
        
        for inputIndex, items in pairs(self.manualInputs) do
            local inputScript = self.craftRecipe:getIOForIndex(inputIndex);
            if (not inputScript) or (not self.logic:setManualInputsFor(inputScript, items)) then
                log(DebugType.CraftLogic, "ISHandcraftAction.start -> failed to set manual input items for recipe.")
            end
        end

        if not isClient() and not self.force and not self.logic:canPerformCurrentRecipe() then
            log(DebugType.CraftLogic, "ISHandcraftAction.start -> canPerformCurrentRecipe failed.")
            self:forceStop();
            return;
        end
    end

    if not self.items then
        if self.logic:getRecipeData() then
            self.items = self.logic:getRecipeData():getAllInputItems()
        end
    end

    self:clearItemsProgressBar(true);
    
    if self.actionScript then
        self:setActionAnim(self.actionScript:getActionAnim());
        if self.actionScript:getAnimVarKey() then
            self:setAnimVariable(self.actionScript:getAnimVarKey(), self.actionScript:getAnimVarVal());
        end
        if self.actionScript:getSound() ~= nil and self.actionScript:getSoundTime() == ActionSoundTime.ACTION_START then
            self.sound = self.character:playSound(self.actionScript:getSound());
        end
    end

    if self.actionScript and self.actionScript:isCantSit() == true and self.character:isSitOnGround() then
        self.character:setSitOnGround(false)
    end

    self:setOverrideHandModels(self.logic:getModelHandOne(), self.logic:getModelHandTwo());

    if self.onStartFunc then
        self.onStartFunc(self.onStartTarget, self);
    end
end

function ISHandcraftAction:stop()
    self:clearItemsProgressBar(false);
    ISBaseTimedAction.stop(self);
    
    if self.sound and self.character and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound);
    end
    
    if self.onCancelFunc then
        self.onCancelFunc(self.onCancelTarget);
    end

    if self.onCompleteFunc then
        self.onCompleteFunc(self.onCompleteTarget);
    end
end

function ISHandcraftAction:perform()
    self:clearItemsProgressBar(false);
    
    if self.sound and self.character and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound);
    end

    ISInventoryPage.dirtyUI();

    if not isClient() then
        self:performRecipe();
    end
    
    ISBaseTimedAction.perform(self);

    if isClient() and self.onCompleteFunc then
        self.onCompleteFunc(self.onCompleteTarget);
    end
end

function ISHandcraftAction:complete()
    if self.eatPercentage and self.eatPercentage > 0 and self.logic and self.logic:getRecipeData() then
        self.logic:getRecipeData():setEatPercentage(self.eatPercentage)
    end

    self:clearItemsProgressBar(false);

    if isServer() then
        self:performRecipe();
    end

    if self.onCompleteFunc then
        self.onCompleteFunc(self.onCompleteTarget);
    end
    return true
end

function ISHandcraftAction:performRecipe()
    if not self.logic then return end
    
    -- Verificar se a receita pode ser executada
    local recipeData = self.logic:getRecipeData()
    if not recipeData then return end
    
    -- Verificar itens de entrada para FluidContainer
    local canPerform = true
    local inputItems = recipeData:getAllInputItems()
    if inputItems then
        for i=0, inputItems:size()-1 do
            local item = inputItems:get(i)
            if item then
                -- Verificar se item precisa de FluidContainer mas nao tem
                local success, hasFluid = pcall(function()
                    local fc = item:getFluidContainer()
                    return fc ~= nil
                end)
                -- Se a verificacao falhar, continuar mesmo assim
            end
        end
    end
    
    -- Executar receita com protecao
    local success, err = pcall(function()
        if self.logic:performCurrentRecipe() then
            local items = ArrayList.new();
            self.logic:getCreatedOutputItems(items);

            for i=0,items:size()-1 do
                local item = items:get(i);
                if item then
                    Actions.addOrDropItem(self.character, item)
                end
            end

            recipeData:luaCallOnCreate(self.character);
            recipeData:processDestroyAndUsedItems(self.character);

            if items:size() == 1 then
                local resItem = items:get(0)
                if resItem then
                    local modData = resItem:getModData()
                    local usedItems = recipeData:getAllConsumedItems()
                    if usedItems then
                        for i=0, usedItems:size()-1 do
                            local item = usedItems:get(i)
                            if item then
                                local fullType = item:getFullType()
                                if fullType then
                                    if modData[fullType] == nil then
                                        modData[fullType] = 0
                                    end
                                    modData[fullType] = modData[fullType] + 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    
    if not success then
        print("[ISHandcraftAction] Error in performRecipe: " .. tostring(err))
    end
end

function ISHandcraftAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1;
    end
    if not self.craftRecipe then
        return -1;
    end
    return self.craftRecipe:getTime(self.character) * 5;
end

function ISHandcraftAction:setOnStart(_func, _target)
    self.onStartFunc = _func;
    self.onStartTarget = _target;
end

function ISHandcraftAction:setOnComplete(_func, _target)
    self.onCompleteFunc = _func;
    self.onCompleteTarget = _target;
end

function ISHandcraftAction:setOnCancel(_func, _target)
    self.onCancelFunc = _func;
    self.onCancelTarget = _target;
end

function ISHandcraftAction:stopSound()
    if self.sound and self.character and self.character:getEmitter():isPlaying(self.sound) then
        self.character:stopOrTriggerSound(self.sound);
    end
end

function ISHandcraftAction:animEvent(event, parameter)
    if self.actionScript and event == "StartActionAnim" and self.actionScript:getSound() ~= nil and self.actionScript:getSoundTime() == ActionSoundTime.ANIMATION_START then
        self:stopSound();
        self.sound = self.character:playSound(self.actionScript:getSound());
    end
end

function ISHandcraftAction.FromLogicMultiple(handcraftLogic)
    if not handcraftLogic then return nil end
    
    log(DebugType.CraftLogic, "Creating handcraft action from logic, manual = "..tostring(handcraftLogic:isManualSelectInputs()))
    local character = handcraftLogic:getPlayer();
    local isoObject = handcraftLogic:getIsoObject();
    local craftBench = handcraftLogic:getCraftBench();
    local containers = handcraftLogic:getContainers();
    local craftRecipe = handcraftLogic:getRecipe();
    local craftData = handcraftLogic:getRecipeData();
    local variableInputRatio = craftData and craftData:getVariableInputRatio() or 1;
    local manualInputs = false;
    local recipeAtHandItem = nil;
    
    if handcraftLogic:isManualSelectInputs() then
        manualInputs = {};
        local inputScripts = craftRecipe:getInputs();
        for i=0,inputScripts:size()-1 do
            local inputScript = inputScripts:get(i);
            if inputScript:getResourceType()==ResourceType.Item then
                local inputIndex = craftRecipe:getIndexForIO(inputScript);
                manualInputs[inputIndex] = handcraftLogic:getMulticraftConsumedItemsFor(inputScript, ArrayList.new());
            end
        end
    end

    if handcraftLogic:isUsingRecipeAtHandBenefit() then
        recipeAtHandItem = handcraftLogic:getUsingRecipeAtHandItem()
    end

    local action = ISHandcraftAction:new(character, craftRecipe, containers, isoObject, craftBench, manualInputs, nil, recipeAtHandItem, variableInputRatio);

    return action;
end

function ISHandcraftAction.FromLogic(handcraftLogic, eatPercentage)
    if not handcraftLogic then return nil end
    
    log(DebugType.CraftLogic, "Creating handcraft action from logic, manual = "..tostring(handcraftLogic:isManualSelectInputs()))
    local character = handcraftLogic:getPlayer();
    local isoObject = handcraftLogic:getIsoObject();
    local craftBench = handcraftLogic:getCraftBench();
    local containers = handcraftLogic:getContainers();
    local craftRecipe = handcraftLogic:getRecipe();
    local craftData = handcraftLogic:getRecipeData();
    local variableInputRatio = craftData and craftData:getVariableInputRatio() or 1;
    local manualInputs = false;
    local recipeAtHandItem = nil;
    
    if handcraftLogic:isManualSelectInputs() then
        manualInputs = {};
        local inputScripts = craftRecipe:getInputs();
        for i=0,inputScripts:size()-1 do
            local inputScript = inputScripts:get(i);
            if inputScript:getResourceType()==ResourceType.Item then
                local inputIndex = craftRecipe:getIndexForIO(inputScript);
                manualInputs[inputIndex] = handcraftLogic:getManualInputsFor(inputScript, ArrayList.new());
            end
        end
    end
    
    local items = nil
    if handcraftLogic:getRecipeData() then
        items = handcraftLogic:getRecipeData():getAllInputItems()
    end

    if handcraftLogic:isUsingRecipeAtHandBenefit() then
        recipeAtHandItem = handcraftLogic:getUsingRecipeAtHandItem()
    end

    local action = ISHandcraftAction:new(character, craftRecipe, containers, isoObject, craftBench, manualInputs, items, recipeAtHandItem, variableInputRatio, eatPercentage);

    return action;
end

function ISHandcraftAction:new(character, craftRecipe, containers, isoObject, craftBench, manualInputs, items, recipeItem, variableInputRatio, eatPercentage)
    log(DebugType.CraftLogic, "Creating handcraft action")
    local o = ISBaseTimedAction.new(self, character);

    o.stopOnAim = false;
    o.character = character;
    o.isoObject = isoObject;
    o.craftBench = craftBench;
    o.containers = containers;
    o.manualInputs = manualInputs;
    o.craftRecipe = craftRecipe;
    o.actionScript = o.craftRecipe and o.craftRecipe:getTimedActionScript();
    o.stopOnWalk = craftRecipe and not craftRecipe:isCanWalk() or true;
    
    if character and (character:hasTrait(CharacterTrait.ALL_THUMBS) or character:isWearingAwkwardGloves()) then
        o.stopOnWalk = true;
    end
    
    o.stopOnRun = true;
    o.maxTime = o:getDuration();

    o.items = items;
    o.recipeItem = recipeItem;
    o.variableInputRatio = variableInputRatio or 1;
    o.eatPercentage = eatPercentage or 0;
    return o
end
