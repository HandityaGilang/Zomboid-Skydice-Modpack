require "TimedActions/ISBaseTimedAction"

ISOpenCloseCurtain = ISBaseTimedAction:derive("ISOpenCloseCurtain");

function ISOpenCloseCurtain:isValid()
    return self.item and self.item:getSquare() ~= nil
end

function ISOpenCloseCurtain:waitToStart()
    return false -- Não espera virar
end

function ISOpenCloseCurtain:update()
    -- Removido para não travar
end

function ISOpenCloseCurtain:start()
    -- Executa IMEDIATAMENTE
    if instanceof(self.item, "IsoDoor") then
        self.item:toggleCurtain()
    elseif instanceof(self.item, "IsoWindow") then
        self.item:openCloseCurtain(self.character)
    else
        self.item:ToggleDoor(self.character)
    end
    self:forceComplete()
end

function ISOpenCloseCurtain:stop()
    ISBaseTimedAction.stop(self)
end

function ISOpenCloseCurtain:perform()
    ISBaseTimedAction.perform(self)
end

function ISOpenCloseCurtain:complete()
    return true
end

function ISOpenCloseCurtain:getDuration()
    return 0 -- Duração ZERO
end

function ISOpenCloseCurtain:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.ignoreHandsWounds = true
    o.stopOnWalk = false
    o.stopOnRun = false
    o.stopOnAim = false
    o.forceProgressBar = false
    o.maxTime = 0
    o.retriggerLastAction = true
    return o
end