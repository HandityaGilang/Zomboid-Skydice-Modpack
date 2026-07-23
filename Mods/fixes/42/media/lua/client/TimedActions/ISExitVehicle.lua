require "TimedActions/ISBaseTimedAction"

ISExitVehicle = ISBaseTimedAction:derive("ISExitVehicle")

function ISExitVehicle:isValid()
    self.vehicle = self.character:getVehicle()
    if self.vehicle and self.vehicle:isStopped() then
        return true
    end
    return false
end

function ISExitVehicle:update()
    -- Removido para não travar
end

function ISExitVehicle:start()
    self.action:setBlockMovementEtc(true)
    
    local vehicle = self.character:getVehicle()
    if not vehicle then return end
    
    local seat = vehicle:getSeat(self.character)
    
    self.character:SetVariable("bExitingVehicle", "true")
    vehicle:playPassengerSound(seat, "exit")
    self.character:triggerMusicIntensityEvent("VehicleExit")
    
    -- SAI INSTANTANEAMENTE
    vehicle:exit(self.character)
    vehicle:setCharacterPosition(self.character, seat, "outside")
    self.character:PlayAnim("Idle")
    
    -- Trigger evento
    triggerEvent("OnExitVehicle", self.character)
    
    vehicle:updateHasExtendOffsetForExitEnd(self.character)
    
    -- Limpa variáveis
    self.character:ClearVariable("ExitAnimationFinished")
    self.character:ClearVariable("bExitingVehicle")
    
    self.vehicle = vehicle
    
    -- Completa instantaneamente
    self:forceComplete()
end

function ISExitVehicle:stop()
    self.character:clearVariable("bExitingVehicle")
    self.character:clearVariable("ExitAnimationFinished")
    
    local vehicle = self.character:getVehicle()
    if vehicle then
        local seat = vehicle:getSeat(self.character)
        vehicle:playPassengerAnim(seat, "idle")
    end
    
    ISBaseTimedAction.stop(self)
end

function ISExitVehicle:perform()
    -- Já foi executado no start()
    ISBaseTimedAction.perform(self)
end

function ISExitVehicle:getExtraLogData()
    if self.vehicle then
        return {
            self.vehicle:getScript():getName(),
        }
    end
end

function ISExitVehicle:new(character)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.maxTime = 0 -- DURAÇÃO ZERO = INSTANTÂNEO
    o.stopOnWalk = false
    o.stopOnRun = false
    o.stopOnAim = false
    o.forceProgressBar = false
    return o
end