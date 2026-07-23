require "TimedActions/ISBaseTimedAction"

ISSwitchVehicleSeat = ISBaseTimedAction:derive("ISSwitchVehicleSeat")

function ISSwitchVehicleSeat:isValid()
    local vehicle = self.character:getVehicle()
    return vehicle ~= nil and
        vehicle:getSeat(self.character) ~= -1 and
        not vehicle:isSeatOccupied(self.seatTo) and
        self.seatFrom == self.character:getVehicle():getSeat(self.character)
end

function ISSwitchVehicleSeat:update()
    -- Removido para não travar
end

function ISSwitchVehicleSeat:start()
    local vehicle = self.character:getVehicle()
    if not vehicle then return end
    
    local seat = vehicle:getSeat(self.character)
    
    self.character:SetVariable("bSwitchingSeat", "true")
    
    local sound = vehicle:getSwitchSeatSound(seat, self.seatTo)
    if sound then
        vehicle:playSound(sound)
    end
    
    -- Executa a troca IMEDIATAMENTE
    vehicle:switchSeat(self.character, self.seatTo)
    sendSwitchSeat(vehicle, self.character, seat, self.seatTo)
    vehicle:playPassengerAnim(self.seatTo, "idle")
    
    triggerEvent("OnSwitchVehicleSeat", self.character)
    
    -- Atualiza inventário
    local pdata = getPlayerData(self.character:getPlayerNum())
    if pdata ~= nil then
        pdata.playerInventory:refreshBackpacks()
        pdata.lootInventory:refreshBackpacks()
    end
    
    if not vehicle:getDriver() then 
        vehicle:onHornStop() 
    end
    
    -- Limpa variáveis
    self.character:ClearVariable("SwitchSeatAnimationFinished")
    self.character:ClearVariable("bSwitchingSeat")
    
    -- Completa instantaneamente
    self:forceComplete()
end

function ISSwitchVehicleSeat:stop()
    self.character:ClearVariable("SwitchSeatAnimationFinished")
    self.character:ClearVariable("bSwitchingSeat")
    
    local vehicle = self.character:getVehicle()
    if vehicle then
        local seat = vehicle:getSeat(self.character)
        vehicle:playPassengerAnim(seat, "idle")
    end
    
    ISBaseTimedAction.stop(self)
end

function ISSwitchVehicleSeat:perform()
    -- Já foi executado no start()
    ISBaseTimedAction.perform(self)
end

function ISSwitchVehicleSeat:new(character, seatTo, seatFrom)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.seatTo = seatTo
    
    local veh = character:getVehicle()
    if seatFrom == nil and veh ~= nil then
        o.seatFrom = veh:getSeat(character)
    else
        o.seatFrom = seatFrom
    end
    
    o.maxTime = 0 -- DURAÇÃO ZERO = INSTANTÂNEO
    o.stopOnWalk = false
    o.stopOnRun = false
    o.stopOnAim = false
    o.forceProgressBar = false
    
    return o
end