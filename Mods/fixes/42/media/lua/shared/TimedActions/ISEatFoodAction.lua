require "TimedActions/ISBaseTimedAction"

ISEatFoodAction = ISBaseTimedAction:derive("ISEatFoodAction");

local function predicateNotEmpty(item)
    return item:getCurrentUsesFloat() > 0
end

local function predicateNotBroken(item)
    return not item:isBroken()
end

function ISEatFoodAction:isValidStart()
    if not self.character then return false end
    local moodles = self.character:getMoodles()
    if not moodles then return true end
    return moodles:getMoodleLevel(MoodleType.FOOD_EATEN) < 3
end

function ISEatFoodAction:waitToStart()
    if not self.openFlame then return false end
    if not self.character then return false end
    self.character:faceThisObject(self.openFlame)
    return self.character:shouldBeTurning()
end

function ISEatFoodAction:isValid()
    if not self.item then return false end
    if not self.character then return false end
    
    local inventory = self.character:getInventory()
    if not inventory then return false end
    
    if isClient() then
        return inventory:containsID(self.item:getID())
    else
        return inventory:contains(self.item)
    end
end

function ISEatFoodAction:update()
    if not self.item then return end
    if not self.character then return end
    
    local jobDelta = 0
    if self.getJobDelta then
        local success, result = pcall(function() return self:getJobDelta() end)
        if success and result then
            jobDelta = result
        end
    end
    
    self.item:setJobDelta(jobDelta)
    
    if self.eatSound and self.eatSound ~= "" and self.eatAudio and self.eatAudio ~= 0 then
        local emitter = self.character:getEmitter()
        if emitter and not emitter:isPlaying(self.eatAudio) then
            self.eatAudio = emitter:playSound(self.eatSound)
        end
    end
    
    local eatType = self.item:getEatType()
    if self.useUtensil and (eatType == "Can" or eatType == "Candrink") and self:isEatingRemaining(self.item) then
        if not self.playedScrapeSound and (jobDelta >= 0.7) then
            self.scrapeSound = self.character:playSound("ScrapeCannedFood")
            self.playedScrapeSound = true
        end
    end
end

function ISEatFoodAction:start()
    if not self.character then return end
    
    if isClient() and self.item then
        local inventory = self.character:getInventory()
        if inventory then
            self.item = inventory:getItemById(self.item:getID())
        end
    end

    if not self.item then return end

    if not self.fromRelaunch and self.item:getRequireInHandOrInventory() and not (self.carLighter or self.openFlame) then
        local lighter = self:getRequiredItem()
        if lighter then
            lighter:setUsedDelta(lighter:getCurrentUsesFloat() - lighter:getUseDelta())
        end
    end

    if self.eatSound and self.eatSound ~= '' then
        local emitter = self.character:getEmitter()
        if emitter then
            self.eatAudio = emitter:playSound(self.eatSound)
        end
    end
    
    if self.item:getCustomMenuOption() then
        self.item:setJobType(self.item:getCustomMenuOption())
    else
        self.item:setJobType(getText("ContextMenu_Eat"))
    end
    self.item:setJobDelta(0.0)

    local secondItem = nil
    local eatType = self.item:getEatType()
    if eatType and eatType ~= "" then
        if eatType == "Can" or eatType == "Candrink" or eatType == "2hand" or eatType == "Plate" or eatType == "2handbowl" then
            if eatType == "2handbowl" and self.spoon then
                self:setAnimVariable("FoodType", "2handbowl")
                secondItem = self.spoon
            elseif eatType == "2handbowl" then
                self:setAnimVariable("FoodType", "bowl")
            else
                secondItem = self.fork or self.spoon
                if eatType == "Plate" then
                    if secondItem then
                        self:setAnimVariable("FoodType", "plate")
                    else
                        self:setAnimVariable("FoodType", "NoSpoon")
                    end
                elseif eatType == "2hand" then
                    self:setAnimVariable("FoodType", "2hand")
                elseif eatType == "plate" then
                    self:setAnimVariable("FoodType", "Plate")
                elseif eatType == "Candrink" then
                    if secondItem then
                        self:setAnimVariable("FoodType", "can")
                    else
                        self:setAnimVariable("FoodType", "drink")
                    end
                elseif eatType == "Popcan" then
                    self:setAnimVariable("FoodType", "drink")
                elseif eatType == "EatSmall" then
                    self:setAnimVariable("FoodType", "EatSmall")
                elseif eatType == "EatBox" then
                    self:setAnimVariable("FoodType", "eatBox")
                end
            end
        else
            self:setAnimVariable("FoodType", eatType)
        end
    end
    
    self:setOverrideHandModels(secondItem, self.item)
    if eatType == "Pot" or eatType == "PotForged" then
        self:setOverrideHandModels(self.item, nil)
    end
    
    if self.item:getCustomMenuOption() == getText("ContextMenu_Drink") and eatType ~= "2handbowl" then
        self:setActionAnim(CharacterActionAnims.Drink)
    else
        self:setActionAnim(CharacterActionAnims.Eat)
    end
    self.character:reportEvent("EventEating")
end

function ISEatFoodAction:stop()
    if ISBaseTimedAction.stop then
        ISBaseTimedAction.stop(self)
    end
    
    if self.character then
        local emitter = self.character:getEmitter()
        if emitter then
            if self.eatAudio and self.eatAudio ~= 0 and emitter:isPlaying(self.eatAudio) then
                self.character:stopOrTriggerSound(self.eatAudio)
            end
            if self.scrapeSound and emitter:isPlaying(self.scrapeSound) then
                self.character:stopOrTriggerSound(self.scrapeSound)
            end
        end
    end
    
    if self.item and self.item.setJobDelta then
        self.item:setJobDelta(0.0)
    end

    if not isClient() and not isServer() then
        self:serverStop()
    end
end

function ISEatFoodAction:serverStop()
    if not self then return end
    if not self.item then return end
    if not self.character then return end
    
    local applyEat = true
    
    -- Verificar tipo do item com seguranca
    local fullType = nil
    if self.item.getFullType then
        local success, result = pcall(function() return self.item:getFullType() end)
        if success then fullType = result end
    end
    
    if fullType and fullType == "Base.Cigarettes" then
        applyEat = false
    end
    
    -- Verificar hungerChange com seguranca
    local hungerChange = 0
    if self.item.getHungerChange then
        local success, result = pcall(function() return self.item:getHungerChange() end)
        if success and result then
            hungerChange = math.abs(result * 100)
        end
    end
    
    local baseHunger = 0
    if self.item.getBaseHunger then
        local success, result = pcall(function() return self.item:getBaseHunger() end)
        if success and result then
            baseHunger = result
        end
    end
    
    if hungerChange <= 1 and baseHunger == 0 then
        applyEat = false
    end
    
    -- Verificar inventario e aplicar
    if applyEat then
        local inventory = self.character:getInventory()
        if inventory and inventory:contains(self.item) then
            local jobDelta = 0
            
            -- Tentar obter jobDelta de varias formas
            if self.item and self.item.getJobDelta then
                local success, result = pcall(function() return self.item:getJobDelta() end)
                if success and result then
                    jobDelta = result
                end
            end
            
            -- Fallback: calcular baseado no tempo
            if jobDelta == 0 and self.action and self.maxTime and self.maxTime > 0 then
                local currentTime = self.action:getCurrentTime()
                if currentTime then
                    jobDelta = currentTime / self.maxTime
                end
            end
            
            self:eat(self.item, jobDelta)
        end
    end
end

function ISEatFoodAction:perform()
    if self.character then
        local emitter = self.character:getEmitter()
        if emitter then
            if self.eatAudio and self.eatAudio ~= 0 and emitter:isPlaying(self.eatAudio) then
                self.character:stopOrTriggerSound(self.eatAudio)
            end
            if self.scrapeSound and emitter:isPlaying(self.scrapeSound) then
                self.character:stopOrTriggerSound(self.scrapeSound)
            end
        end
    end
    
    if self.item then
        if self.container then
            self.container:setDrawDirty(true)
        end
        self.item:setJobDelta(0.0)
    end
    
    if ISBaseTimedAction.perform then
        ISBaseTimedAction.perform(self)
    end
end

function ISEatFoodAction:complete()
    if not self.character then return false end
    if not self.item then return false end
    
    local percentage = self.percentage or 1
    local useUtensil = self.useUtensil or false
    
    self.character:Eat(self.item, percentage, useUtensil)
    return true
end

function ISEatFoodAction:getRequiredItem()
    if not self.item then return nil end
    if not self.character then return nil end
    
    local requireItems = self.item:getRequireInHandOrInventory()
    if not requireItems then return nil end
    
    local inventory = self.character:getInventory()
    if not inventory then return nil end
    
    for i = 1, requireItems:size() do
        local itemModule = self.item:getModule()
        local fullType = moduleDotType(itemModule, requireItems:get(i - 1))
        local item2 = inventory:getFirstTypeEvalRecurse(fullType, predicateNotEmpty)
        if item2 then
            return item2
        end
    end
    return nil
end

function ISEatFoodAction:eat(food, percentage)
    if not food then return end
    if not self.character then return end
    
    if percentage and percentage > 0.95 then
        percentage = 1.0
    end
    
    local selfPercentage = self.percentage or 1
    percentage = selfPercentage * (percentage or 1)
    
    local useUtensil = self.useUtensil or false
    self.character:Eat(food, percentage, useUtensil)
end

function ISEatFoodAction:getDuration()
    if self.character and self.character:isTimedActionInstant() then
        return 1
    end

    if not self.item then return 100 end

    local baseHunger = self.item:getBaseHunger() or 0
    local percentage = self.percentage or 1
    local maxTime = math.abs(baseHunger * 150 * percentage) * 8

    local hungerChange = self.item:getHungerChange() or 0
    if maxTime > math.abs(hungerChange * 150 * 8) then
        maxTime = math.abs(hungerChange * 150 * 8)
    end

    local hungerConsumed = math.abs(baseHunger * percentage * 100)
    local eatingLoop = 1
    if hungerConsumed >= 30 then
        eatingLoop = 2
    end
    if hungerConsumed >= 80 then
        eatingLoop = 3
    end

    if self.useUtensil and eatingLoop >= 2 then
        eatingLoop = eatingLoop - 1
    end

    local timerForOne = 232
    local thirstChange = self.item:getThirstChange() or 0
    if self.item:getCustomMenuOption() == getText("ContextMenu_Drink") then
        hungerConsumed = math.abs(thirstChange * percentage * 100)
        timerForOne = 171
        if hungerConsumed >= 3 then
            eatingLoop = 2
        end
        if hungerConsumed >= 6 then
            eatingLoop = 3
        end
    end

    maxTime = timerForOne * eatingLoop

    if hungerConsumed == 0 then maxTime = 460 end
    
    local eatTime = self.item:getEatTime()
    if eatTime and eatTime > 0 then 
        maxTime = eatTime 
    end

    local eatType = self.item:getEatType()
    if eatType == "popcan" then
        maxTime = 160
    end
    return maxTime
end

function ISEatFoodAction:getSecondItem()
    if not self.item then return nil end
    
    local eatType = self.item:getEatType()
    if not eatType or eatType == "" then return nil end
    
    if eatType == "2handbowl" and self.spoon then
        return self.spoon
    end
    if eatType == "Can" or eatType == "Candrink" or eatType == "2hand" or eatType == "Plate" then
        return self.fork or self.spoon
    end
    return nil
end

function ISEatFoodAction:isEatingRemaining(item)
    if not item then return false end
    
    local percent = PZMath.clamp_01(self.percentage or 1)
    local baseHunger = item:getBaseHunger() or 0
    local hungChange = item:getHungChange() or 0
    
    if (baseHunger ~= 0.0) and (hungChange ~= 0.0) then
        local hungChangeCalc = baseHunger * percent
        local usedPercent = hungChangeCalc / hungChange
        percent = PZMath.clamp_01(usedPercent)
    end
    if (hungChange < 0.0) and (hungChange * (1.0 - percent) > -0.01) then
        percent = 1.0
    end
    
    local thirstChange = item:getThirstChange() or 0
    if (hungChange == 0.0) and (thirstChange < 0.0) and (thirstChange * (1 - percent) > -0.01) then
        percent = 1.0
    end
    return percent == 1.0
end

function ISEatFoodAction:new(character, item, percentage)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.container = item and item:getContainer() or (character and character:getInventory())
    o.stopOnWalk = false
    o.stopOnRun = true
    o.stopOnAim = false
    o.percentage = percentage or 1
    o.carLighter = false
    o.openFlame = false
    o.useUtensil = false
    o.isEating = true
    o.spoon = nil
    o.fork = nil
    o.eatSound = "Eating"
    o.eatAudio = 0
    o.ignoreHandsWounds = true
    o.maxTime = 100
    
    if item and character then
        o.carLighter = item:hasTag(ItemTag.SMOKABLE) and character:getVehicle() and character:getVehicle():canLightSmoke(character)
        
        if not isServer() then
            if item:hasTag(ItemTag.SMOKABLE) then 
                o.openFlame = ISInventoryPaneContextMenu.hasOpenFlame(character) 
            end
        end
        
        local playerInv = character:getInventory()
        if playerInv then
            o.spoon = playerInv:getFirstTagEvalRecurse(ItemTag.SPOON, predicateNotBroken) or playerInv:getFirstTypeEvalRecurse("Base.Spoon", predicateNotBroken)
            o.fork = playerInv:getFirstTagEvalRecurse(ItemTag.FORK, predicateNotBroken) or playerInv:getFirstTypeEvalRecurse("Base.Fork", predicateNotBroken)
        end
        
        if ISEatFoodAction.getSecondItem(o) then
            o.useUtensil = true
        end
        
        o.maxTime = ISEatFoodAction.getDuration(o)
        o.eatSound = item:getCustomEatSound() or "Eating"
    end
    
    return o
end
