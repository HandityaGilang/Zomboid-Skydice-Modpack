require "TimedActions/ISCDBaseDogAction"

local CD = CompanionDogs

ISCDFeedDog = ISCDBaseDogAction:derive("ISCDFeedDog")

function ISCDFeedDog:isValid()
    return self.character:getInventory():containsRecursive(self.food)
end

function ISCDFeedDog:doEffect()
    if self.cdDone then return end
    self.cdDone = true
    pcall(function() self.animal:getBehavior():setBlockMovement(false) end)
    local inv = self.character:getInventory()
    if not (self.food and inv:containsRecursive(self.food)) then
        return
    end

    -- quanto morder: companheiro -> sua fome atual; vira-lata -> confianca suficiente para cruzar o limiar de domesticar (+1 de folga)
    local need
    if CD.isCompanion(self.animal) then
        pcall(function() need = self.animal:getHunger() end)
    else
        local fpH = CD.feedTrustPerHunger()
        if fpH and fpH > 0 then
            local remaining = CD.tameThreshold() - CD.getTrust(self.animal)
            if remaining < 0 then remaining = 0 end
            need = (remaining + 1) / (100 * fpH)
        end
    end

    -- O server consome o item de forma autoritativa (sem SyncItemDelete no client -> sem kick por AntiCheatPermission).
    -- Alimentar na mao come so a mordida que o cao precisa e encolhe a comida (sem desperdicio); partialFrac dirige o consumo proporcional, itens de fallback vao inteiros.
    local bite = CD.computeBite(self.food, need)
    CompanionDogs.request("feed", self.animal, { hunger = bite.hunger, thirst = bite.thirst, partialFrac = bite.partialFrac, foodId = self.food:getID() })
end

function ISCDFeedDog:new(character, animal, food)
    local o = ISBaseTimedAction.new(self, character)
    o.animal = animal
    o.food = food
    o.handModelItem = food
    -- NAO usar "GiveFoodAnimal": o event FMOD embute fucado/mastigacao generica de animal ("guaxinim"); o comer
    -- audivel vem do proprio cao (pulso CDDogEat), aqui fica so o rustle de pegar a comida.
    o.soundName = "PutItemInBag"
    o.cdMaxTicks = 75
    o.cdDuration = 150
    o.maxTime = o:getDuration()
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end
