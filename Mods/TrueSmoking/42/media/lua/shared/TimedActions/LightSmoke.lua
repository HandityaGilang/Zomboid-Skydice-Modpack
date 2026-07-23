require "TimedActions/ISBaseTimedAction"

LightSmoke = ISBaseTimedAction:derive("LightSmoke")

function LightSmoke:isValid()
    local valid = self.hasLighter or self.carLighter or not not self.openFlame
    -- print('TRUESMOKING::LightSmoke isValid: ' .. tostring(self.hasLighter) .. ' | CarLighter: ' .. tostring(self.carLighter) .. ' | OpenFlame: ' .. tostring(self.openFlame) .. ' | Result: ' .. tostring(valid))
    return valid
end

function LightSmoke:update()
     if self.eatSound ~= "" and self.eatAudio ~= 0 and not self.character:getEmitter():isPlaying(self.eatAudio) then
        self.eatAudio = self.character:getEmitter():playSound(self.eatSound);
    end
end

function LightSmoke:waitToStart()
    if not self.character:isStrafing() and not self.character:isRunning() and not self.character:isSprinting()
        and not self.character:isAiming() and not self.character:isAsleep() and not self.character:isPerformingAnAction()
    then
        return false
    else
        return true
    end
end

local function predicateNotEmpty(item)
    return item:getCurrentUsesFloat() > 0
end

function LightSmoke:getRequiredItem()
    if not self.item:getRequireInHandOrInventory() then
        return
    end
    local types = self.item:getRequireInHandOrInventory()
    for i = 1, types:size() do
        local fullType = moduleDotType(self.item:getModule(), types:get(i - 1))
        local item2 = self.character:getInventory():getFirstTypeEvalRecurse(fullType, predicateNotEmpty)
        if item2 then
            return item2
        end
    end
    return nil
end

function LightSmoke:start()
    if self.item:getRequireInHandOrInventory() or self.carLighter or not not self.openFlame then
        local lighter = self:getRequiredItem()
        if not lighter then
            self.hasLighter = false
        elseif (lighter and not self.carLighter and not self.openFlame) then
            lighter:setUsedDelta(lighter:getCurrentUsesFloat() - lighter:getUseDelta())
        end

        print('TRUESMOKING::LightSmoke started')
        local anim = getActivatedMods():contains("\\SmokingSoundsOverhaul") and 'Smoke_Quiet' or
            CharacterActionAnims.Eat
        self:setActionAnim(anim)
        self:setAnimVariable("FoodType", self.item:getEatType())

        if TrueSmoking.Config.HideAllActionBars then
            self.action:setUseProgressBar(false)
        end
        local hasPrimary = self.character:getPrimaryHandItem()
        if hasPrimary then
            self:setOverrideHandModels(hasPrimary, self.item)
        else
            self:setOverrideHandModels(nil, self.item)
        end

        if self.eatSound ~= '' then
            self.eatAudio = self.character:getEmitter():playSound(self.eatSound);
        end

        -- Play custom sound when no sound is playing
        if getActivatedMods():contains("\\SmokingSoundsOverhaul") then
            local sound = SmokingSoundsOverhaul:getLightingSound(self.character)
            if self.eatSound == '' or self.eatSound == nil then -- No sound running for first time
                self.eatSound = sound
                if not self.character:getEmitter():isPlaying(self.table.lightingEatSound) then
                    self.table.lightingEatSound = self.eatSound
                    self.eatAudio = self.character:getEmitter():playSound(self.eatSound);
                end
            end
        end
        -- self.character:reportEvent("EventEating");
    end
end

function LightSmoke:stop()
    ISBaseTimedAction.stop(self)
end

function LightSmoke:perform()
    self.smokable.smokeLit = true
    self.smokable.puffTimeMark = os.time()
    if self.smokable.burnRate == 0 then
        self.smokable.burnRate = ZombRandFloat(self.smokable.burnMin,
        self.smokable.burnMax)
    end
    ISBaseTimedAction.perform(self)
end

function LightSmoke:complete()
    self.table.lightingEatSound = ''

    self.smokable:start()
    return true
end

function LightSmoke:new(character)
    local o = {
        stopOnWalk = false,
        stopOnRun = true,
        stopOnAim = true,
        forceProgressBar = false,
        character = character,
    }

    o.table = TrueSmoking:getPlayerReference(character)
    o.smokable = o.table.Smokable
    o.item = o.smokable.item
    o.eatSound = o.item:getCustomEatSound() or ''
    o.eatAudio = 0
    o.maxTime = TrueSmoking.lightTime
    o.carLighter = o.item:hasTag("Smokable") and o.character:getVehicle() and
        o.character:getVehicle():canLightSmoke(o.character)
    o.openFlame = false
    if o.item:hasTag("Smokable") then o.openFlame = ISInventoryPaneContextMenu.hasOpenFlame(o.character) end

    o.ignoreHandsWounds = true
    o.isEating = true
    o.hasLighter = true

    setmetatable(o, self)
    self.__index = self

    return o
end
