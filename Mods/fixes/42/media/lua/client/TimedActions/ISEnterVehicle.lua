require "TimedActions/ISBaseTimedAction"

ISEnterVehicle = ISBaseTimedAction:derive("ISEnterVehicle")

function ISEnterVehicle:isValid()
    if self.started then
        return self.vehicle:getCharacter(self.seat) == self.character
    end
    return self.character:getVehicle() == nil and not self.vehicle:isSeatOccupied(self.seat)
end

function ISEnterVehicle:update()
    -- Removido para não travar
end

function ISEnterVehicle:start()
    if not isServer() then
        local playerNum = self.character:getPlayerNum()
        getCell():setDrag(nil, playerNum)
        local contextMenu = getPlayerContextMenu(playerNum)
        if contextMenu and contextMenu:isAnyVisible() then
            contextMenu:hideAndChildren()
        end
    end
    
    self.started = true
    
    -- Validação de distância
    local outside = self.vehicle:getPassengerPosition(self.seat, "outside")
    local worldPos = Vector3f.new()
    self.vehicle:getWorldPos(outside:getOffset(), worldPos)
    
    if self.character:DistTo(worldPos:x(), worldPos:y()) > 2 then
        return
    end
    
    self.action:setBlockMovementEtc(true)
    
    -- ENTRA INSTANTANEAMENTE
    self.vehicle:enter(self.seat, self.character)
    self.vehicle:playPassengerSound(self.seat, "enter")
    self.character:SetVariable("bEnteringVehicle", "true")
    self.character:triggerMusicIntensityEvent("VehicleEnter")
    
    -- Posiciona dentro do veículo
    self.vehicle:setCharacterPosition(self.character, self.seat, "inside")
    self.vehicle:transmitCharacterPosition(self.seat, "inside")
    self.vehicle:playPassengerAnim(self.seat, "idle")
    
    -- Drop heavy items
    local primaryItem = self.character:getPrimaryHandItem()
    local secondaryItem = self.character:getSecondaryHandItem()
    
    if (primaryItem and primaryItem:hasTag(ItemTag.HEAVY_ITEM)) or 
       (secondaryItem and secondaryItem:hasTag(ItemTag.HEAVY_ITEM)) then
        if isClient() then
            local args = { id = self.character:getOnlineID() }
            sendClientCommand(self.character, 'player', 'onDropHeavyItem', args)
        else
            forceDropHeavyItems(self.character)
        end
    end
    
    -- Trigger evento
    triggerEvent("OnEnterVehicle", self.character)
    
    -- Limpa variáveis
    self.character:ClearVariable("EnterAnimationFinished")
    self.character:ClearVariable("bEnteringVehicle")
    
    -- Completa instantaneamente
    self:forceComplete()
end

function ISEnterVehicle:stop()
    self.character:ClearVariable("EnterAnimationFinished")
    self.character:ClearVariable("bEnteringVehicle")
    self.vehicle:exit(self.character)
    ISBaseTimedAction.stop(self)
end

function ISEnterVehicle:perform()
    -- Já foi executado no start()
    ISBaseTimedAction.perform(self)
end

function ISEnterVehicle:getExtraLogData()
    if self.vehicle then
        return {
            self.vehicle:getScript():getName(),
        }
    end
end

function ISEnterVehicle:new(character, vehicle, seat)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.stopOnWalk = false
    o.stopOnRun = false
    o.stopOnAim = false
    o.forceProgressBar = false
    o.character = character
    o.vehicle = vehicle
    o.seat = seat
    o.maxTime = 0 -- DURAÇÃO ZERO = INSTANTÂNEO
    o.started = false
    o.ignoreHandsWounds = true
    return o
end