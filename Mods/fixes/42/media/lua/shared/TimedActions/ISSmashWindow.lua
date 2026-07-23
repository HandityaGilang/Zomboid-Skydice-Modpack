require "TimedActions/ISBaseTimedAction"

ISSmashWindow = ISBaseTimedAction:derive("ISSmashWindow");

function ISSmashWindow:isValid()
    return self.window ~= nil and not self.window:isDestroyed()
end

function ISSmashWindow:waitToStart()
    return false -- Não espera virar
end

function ISSmashWindow:update()
    -- Removido para não travar
end

function ISSmashWindow:start()
    -- Executa animação IMEDIATAMENTE
    if self.vehiclePart ~= nil then
        self.character:smashCarWindow(self.vehiclePart)
    else
        self.character:smashWindow(self.window)
    end
    
    -- Som de dor instantâneo
    if isClient() then
        self.character:playerVoiceSound("PainFromGlassCut")
    end
    
    -- Completa imediatamente
    self:forceComplete()
end

function ISSmashWindow:serverStart()
    -- Servidor processa imediatamente
end

function ISSmashWindow:stop()
    ISBaseTimedAction.stop(self)
end

function ISSmashWindow:perform()
    ISBaseTimedAction.perform(self)
end

function ISSmashWindow:complete()
    if isServer() and not self.window:isDestroyed() then
        if self.vehiclePart ~= nil then
            self.window:hit(self.character)
        else
            self.window:WeaponHit(self.character, nil)
        end
        
        -- Aplica dano de vidro se não tiver arma
        if not instanceof(self.character:getPrimaryHandItem(), "HandWeapon") and 
           not instanceof(self.character:getSecondaryHandItem(), "HandWeapon") then
            self.character:getBodyDamage():setScratchedWindow()
            sendDamage(self.character)
        end
    end
    return true
end

function ISSmashWindow:getDuration()
    return 1 -- Muito rápido (antes era 35)
end

function ISSmashWindow:new(character, window, vehiclePart)
    local o = ISBaseTimedAction.new(self, character)
    o.vehiclePart = vehiclePart
    o.window = window
    o.maxTime = 1
    o.stopOnWalk = false
    o.stopOnRun = false
    o.useProgressBar = false
    o.forceProgressBar = false
    return o
end