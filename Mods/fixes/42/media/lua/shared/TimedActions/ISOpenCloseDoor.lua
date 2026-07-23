require "TimedActions/ISBaseTimedAction"

ISOpenCloseDoor = ISBaseTimedAction:derive("ISOpenCloseDoor");

function ISOpenCloseDoor:isValid()
    return self.item and self.item:getSquare() ~= nil
end

function ISOpenCloseDoor:update()
    -- Removido para não travar personagem
end

function ISOpenCloseDoor:start()
    -- Executa IMEDIATAMENTE sem animação
    self.item:ToggleDoor(self.character);
    self:forceComplete()
end

function ISOpenCloseDoor:stop()
    ISBaseTimedAction.stop(self);
end

function ISOpenCloseDoor:perform()
    ISBaseTimedAction.perform(self);
end

function ISOpenCloseDoor:complete()
    return true;
end

function ISOpenCloseDoor:getDuration()
    return 0; -- Duração ZERO = instantâneo
end

function ISOpenCloseDoor:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item;
    o.stopOnWalk = false;
    o.stopOnRun = false;
    o.stopOnAim = false;
    o.ignoreHandsWounds = true;
    o.forceProgressBar = false; -- Remove barra de progresso
    o.maxTime = 0; -- Tempo zero
    return o;
end