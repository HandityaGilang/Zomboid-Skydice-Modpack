require "TimedActions/ISBaseTimedAction"

local CD = CompanionDogs

-- Animacao de agachar + oferecer comida quando o jogador enche uma tigela no chao, espelhando a acao de alimentar na mao (ISCDFeedDog):
-- mesma anim do jogador (adef.feedByHandAnim = "AnimalLureLow") + modelo de comida na mao + som "PutItemInBag". Ao concluir,
-- dispara o comando de fill no server (o server faz a remocao autoritativa do item / edicao do fluido). Enfileirada DEPOIS do walkAdj.
ISCDFillDish = ISBaseTimedAction:derive("ISCDFillDish")

function ISCDFillDish:isValid()
    if not self.item then return true end  -- a variante de tigela vazia nao carrega item
    return self.character:getInventory():containsRecursive(self.item)
end

function ISCDFillDish:start()
    self:setActionAnim(CD.FEED_BY_HAND_ANIM or "AnimalLureLow")
    if self.item then self:setOverrideHandModels(self.item, nil) end
    -- Mesmo motivo do ISCDFeedDog: "GiveFoodAnimal" embute mastigacao de animal; encher tigela e so manuseio.
    self.sound = self.character:playSound("PutItemInBag")
end

function ISCDFillDish:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopOrTriggerSound(self.sound)
    end
end

function ISCDFillDish:doFill()
    if self.cdDone then return end
    self.cdDone = true
    if self.item and not self.character:getInventory():containsRecursive(self.item) then return end
    local args = { x = self.x, y = self.y, z = self.z }
    if self.item then args[self.argKey or "foodId"] = self.item:getID() end
    CD.request(self.command, nil, args)
end

function ISCDFillDish:update()
    self.cdTicks = (self.cdTicks or 0) + 1
    if self.cdTicks >= self.cdMaxTicks and not self.cdDone then
        self:doFill()
        self:forceComplete()
    end
end

function ISCDFillDish:forceStop()
    self:stopSound()
    ISBaseTimedAction.forceStop(self)
end

function ISCDFillDish:stop()
    self:stopSound()
    ISBaseTimedAction.stop(self)
end

function ISCDFillDish:perform()
    self:stopSound()
    ISBaseTimedAction.perform(self)
end

function ISCDFillDish:complete()
    self:doFill()
    return true
end

function ISCDFillDish:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 150
end

function ISCDFillDish:new(character, x, y, z, item, command, argKey)
    local o = ISBaseTimedAction.new(self, character)
    o.x, o.y, o.z = x, y, z
    o.item = item
    o.command = command or "dishaddfood"
    o.argKey = argKey or "foodId"
    o.maxTime = o:getDuration()
    o.cdMaxTicks = 75
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end
