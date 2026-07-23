require "TimedActions/ISBaseTimedAction"

PutOut = ISBaseTimedAction:derive("PutOut")

function PutOut:isValid()
    --Check if we have a smoke lit
    return self.table.isSmoking
end

function PutOut:update()
    -- Take smoke from mouth sync timer
    local curTime = os.time()
    if not self.visualItemFlag then
        if os.difftime(curTime, self.timer) > self.visualItemTimer then
            self.smokable:removeVisualItem()
            self.visualItemFlag = true
            local hasPrimary = self.character:getPrimaryHandItem()
            if hasPrimary then
                self:setOverrideHandModels(hasPrimary, self.item)
            else
                self:setOverrideHandModels(nil, self.item)
            end
            -- self:setOverrideHandModels(self.character:getPrimaryHandItem():getStaticModel(), self.item)
        end
    end

    if self.eatSound ~= "" and self.eatAudio ~= 0 and not self.character:getEmitter():isPlaying(self.eatAudio) then
        self.eatAudio = self.character:getEmitter():playSound(self.eatSound);
    end
end

function PutOut:waitToStart()
    --Wait for timed actions to finish
    if self.character:isStrafing() or self.character:isRunning() or self.character:isSprinting() or self.character:isAiming()
        or self.character:isAsleep() or self.character:isPerformingAnAction() then
            return true
    else
        return false
    end
end

function PutOut:start()
    if TrueSmoking.Config.HideAllActionBars then
        self.action:setUseProgressBar(false)
    end
    self.timer = os.time()
    --Set the animation
    self:setActionAnim(CharacterActionAnims.Eat)
    self:setAnimVariable("FoodType", self.item:getEatType())
    if not self.table.visualItem then
        self:setOverrideHandModels(nil, self.item)
    end

    if self.eatSound ~= '' then
        self.eatAudio = self.character:getEmitter():playSound(self.eatSound);
    end
end

function PutOut:stop()
    ISBaseTimedAction.stop(self)
    -- If we are cancelling the action and the smoke is finished just get rid of it
    if self.item:getModData().SmokeLength <= 0 then
        self.smokable:stop()
    end
    self:forceComplete()
end

function PutOut:complete()
    self.smokable:stop()
    return true
end

function PutOut:perform()
    ISBaseTimedAction.perform(self)
end

function PutOut:new(character)
    local o = {
        stopOnWalk = false,
        stopOnRun = true,
        stopOnAim = true,
        forceProgressBar = false,
        character = character,
    }

    o.table = TrueSmoking:getPlayerReference(character)
    o.smokable = o.table.Smokable
    o.item = o.table.Smokable.item
    o.maxTime = 120

    o.eatSound = o.item:getCustomEatSound() or ''
    o.eatAudio = 0

    o.visualItemTimer = 0.7
    o.visualItemFlag = false

    setmetatable(o, self)
    self.__index = self

    return o
end