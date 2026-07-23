require "TimedActions/ISBaseTimedAction"

ISOpenCloseWindow = ISBaseTimedAction:derive("ISOpenCloseWindow");

function ISOpenCloseWindow:isValid()
    return self.object and self.object:getSquare() ~= nil
end

function ISOpenCloseWindow:waitToStart()
    return false -- Não espera virar
end

function ISOpenCloseWindow:update()
    -- Removido para não travar
end

function ISOpenCloseWindow:start()
    -- Executa IMEDIATAMENTE
    if self.object:IsOpen() then
        self.character:closeWindow(self.object)
    else
        self.character:openWindow(self.object)
    end
    self:forceComplete()
end

function ISOpenCloseWindow:stop()
    ISBaseTimedAction.stop(self)
end

function ISOpenCloseWindow:perform()
    ISBaseTimedAction.perform(self)
end

function ISOpenCloseWindow:complete()
    return true
end

function ISOpenCloseWindow:getDuration()
    return 0 -- Duração ZERO
end

function ISOpenCloseWindow:new(character, object)
    local o = ISBaseTimedAction.new(self, character)
    o.object = object
    o.stopOnWalk = false
    o.stopOnRun = false
    o.stopOnAim = false
    o.useProgressBar = false
    o.forceProgressBar = false
    o.ignoreHandsWounds = true
    o.maxTime = 0
    return o
end