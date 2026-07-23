require "TimedActions/ISBaseTimedAction"

ISAddBaitAction = ISBaseTimedAction:derive("ISAddBaitAction");

function ISAddBaitAction:isValid()
    self.trap:updateFromIsoObject()
    return self.trap:getIsoObject() ~= nil
end

function ISAddBaitAction:waitToStart()
    self.character:faceThisObject(self.trap:getIsoObject())
    return self.character:shouldBeTurning()
end

function ISAddBaitAction:update()
    self.character:faceThisObject(self.trap:getIsoObject())
    self.character:setMetabolicTarget(Metabolics.LightDomestic);
end

function ISAddBaitAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Low")
    self:setOverrideHandModels(nil, nil)
end

function ISAddBaitAction:stop()
    ISBaseTimedAction.stop(self);
end

function ISAddBaitAction:perform()
    ISBaseTimedAction.perform(self);
end

function ISAddBaitAction:complete()
    -- Verificar se bait existe
    if not self.bait then
        print("[ISAddBaitAction] ERROR: bait is nil")
        return false
    end
    
    local useAndSync = false
    local bait = self.bait
    
    -- Obter hungChange com verificacao de nil
    local hungChange = bait:getHungChange()
    if not hungChange or hungChange == 0 then
        hungChange = -0.05  -- Valor padrao se nil ou zero
    end
    
    local baitAmountMulti = hungChange
    
    -- Calcular multiplicador com seguranca
    local multiplier = 1.0 - math.min(-0.05 / hungChange, 1.0)
    multiplier = math.max(0.0, math.min(1.0, multiplier))  -- Clamp entre 0 e 1
    
    bait:multiplyFoodValues(multiplier)
    
    -- Verificar hungerChange apos multiplicacao
    local newHungerChange = bait:getHungerChange()
    if newHungerChange and newHungerChange > -0.01 then
        useAndSync = true
    end
    
    -- Recalcular baitAmountMulti
    local newHungChange = bait:getHungChange()
    if newHungChange then
        baitAmountMulti = math.min(hungChange - newHungChange, 0)
    else
        baitAmountMulti = 0
    end

    local trap = STrapSystem.instance:getLuaObjectAt(self.trap.x, self.trap.y, self.trap.z)
    if trap then
        trap:addBait(bait:getFullType(), bait:getAge(), baitAmountMulti, self.character)
    else
        print('[ISAddBaitAction] no trap found at ', self.trap.x, ',', self.trap.y, ',', self.trap.z)
    end

    if useAndSync then 
        bait:UseAndSync() 
    end

    return true
end

function ISAddBaitAction:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end
    return 20
end

function ISAddBaitAction:new(character, bait, trap)
    local o = ISBaseTimedAction.new(self, character)
    o.trap = trap
    o.bait = bait
    o.stopOnWalk = false
    o.stopOnRun = false
    o.maxTime = o:getDuration()
    return o
end
