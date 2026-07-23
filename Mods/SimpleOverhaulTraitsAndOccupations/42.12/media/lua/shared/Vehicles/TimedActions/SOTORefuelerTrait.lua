require "TimedActions/ISBaseTimedAction"

--ISAddGasolineToVehicle
local old_ISAddGasolineToVehicle_getDuration = ISAddGasolineToVehicle.getDuration
function ISAddGasolineToVehicle:getDuration()
    local baseDuration = old_ISAddGasolineToVehicle_getDuration(self)
    if self.character:HasTrait("GasManagement") then
        baseDuration = baseDuration * 0.75
    end
    return baseDuration
end

--ISTakeGasolineFromVehicle
local old_ISTakeGasolineFromVehicle_getDuration = ISTakeGasolineFromVehicle.getDuration
function ISTakeGasolineFromVehicle:getDuration()
    local baseDuration = old_ISTakeGasolineFromVehicle_getDuration(self)
    if self.character:HasTrait("GasManagement") then
        baseDuration = baseDuration * 0.75
    end
    return baseDuration
end

--ISRefuelFromGasPump
local old_ISRefuelFromGasPump_getDuration = ISRefuelFromGasPump.getDuration
function ISRefuelFromGasPump:getDuration()
    local baseDuration = old_ISRefuelFromGasPump_getDuration(self)
    if self.character:HasTrait("GasManagement") then
        baseDuration = baseDuration * 0.75	
    end
    return baseDuration
end

--ISTakeFuel
local old_ISTakeFuel_getDuration = ISTakeFuel.getDuration
function ISTakeFuel:getDuration()
    local baseDuration = old_ISTakeFuel_getDuration(self)
    if self.character:HasTrait("GasManagement") then
        baseDuration = baseDuration * 0.75
    end
    return baseDuration
end



