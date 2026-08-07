require "TimedActions/ISBaseTimedAction"

-- Base compartilhada das acoes de interacao manual com o cao (alimentar/dar agua/acariciar). As subclasses setam campos em new() e sobrescrevem
-- doEffect()/isValid(); a base cuida do loop de ticks, do acquire/release de blockMovement (acquire com pcall + uma
-- guarda de existencia para um animal virtualizado nao estourar), e do som opcional. ISCDFillDish e baseada em tile e fica separada.
ISCDBaseDogAction = ISBaseTimedAction:derive("ISCDBaseDogAction")

function ISCDBaseDogAction:isValid()
    return true
end

function ISCDBaseDogAction:waitToStart()
    if self.animal and self.animal:isExistInTheWorld() then
        self.character:faceThisObject(self.animal)
    end
    return self.character:shouldBeTurning()
end

function ISCDBaseDogAction:update()
    if self.animal and self.animal:isExistInTheWorld() then
        self.character:faceThisObject(self.animal)
    end
    self.cdTicks = (self.cdTicks or 0) + 1
    if self.cdTicks >= self.cdMaxTicks and not self.cdDone then
        self:doEffect()
        self:forceComplete()
    end
end

function ISCDBaseDogAction:start()
    pcall(function() self.animal:getBehavior():setBlockMovement(true) end)
    if self.animal and self.animal:isExistInTheWorld() then
        self:setActionAnim(self.animal:getFeedByHandAnim())
        if self.handModelItem then self:setOverrideHandModels(self.handModelItem, nil) end
        self.character:faceThisObject(self.animal)
    end
    if self.soundName then self.sound = self.character:playSound(self.soundName) end
end

function ISCDBaseDogAction:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopOrTriggerSound(self.sound)
    end
end

local function release(self)
    pcall(function() self.animal:getBehavior():setBlockMovement(false) end)
    self:stopSound()
end

function ISCDBaseDogAction:stop()
    release(self)
    ISBaseTimedAction.stop(self)
end

function ISCDBaseDogAction:forceStop()
    release(self)
    ISBaseTimedAction.forceStop(self)
end

function ISCDBaseDogAction:perform()
    release(self)
    ISBaseTimedAction.perform(self)
end

function ISCDBaseDogAction:complete()
    self:doEffect()
    return true
end

function ISCDBaseDogAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return self.cdDuration or 150
end

-- As subclasses sobrescrevem com o efeito real (request ao server).
function ISCDBaseDogAction:doEffect() end
