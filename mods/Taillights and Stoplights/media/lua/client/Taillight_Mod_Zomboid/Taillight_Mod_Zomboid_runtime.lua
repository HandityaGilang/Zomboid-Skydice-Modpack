local M = {
    currentVehicle = nil,
    currentTrailer = nil,
    vehicles = {},
    vehiclesKeyIdList = {},
    tick = 1
}

local lights
local ISTimer

function M.initRuntime()
    lights = require "Taillight_Mod_Zomboid/Taillight_Mod_Zomboid_lights.lua"
    ISTimer = require "Taillight_Mod_Zomboid/Taillight_Mod_Zomboid_ISTimer.lua"
    M.scanForVehicles()
end

function M.scanForVehicles()
    local vehicleList = getCell():getVehicles()
    for i = 0, vehicleList:size() - 1 do
        local vehicle = vehicleList:get(i)
        
        if M.isVehicleCloseToPlayer(vehicle) then
            M.addVehicleToRuntime(vehicle)
        end
    end
end

function M.isVehicleCloseToPlayer(vehicle)
    local player = getPlayer()
    local px, py = player:getX(), player:getY()
    local vx, vy = vehicle:getX(), vehicle:getY()        
    local dx = vx - px
    local dy = vy - py
    local dist = dx*dx + dy*dy
    local max_dist = 100^2

    return dist <= max_dist
end

function M.flagFarVehicles()
    for i = 1, #M.vehiclesKeyIdList do
        local vehicle = M.getVehicleByKeyId(M.vehiclesKeyIdList[i])
        local isVehicleClose = M.isVehicleCloseToPlayer(vehicle)

        if not isVehicleClose then
            M.setDeleteFlag(vehicle)
        end
    end
end

function M.updateTrailerLights(trailer)
if trailer then
        local keyId = trailer:getKeyId()
        local lightData = M.vehicles[keyId].lightData
        local otherData = M.vehicles[keyId].otherData
        

        if otherData.isATrailer then
            otherData.beingTowedBy = trailer:getVehicleTowedBy()
            if M.currentVehicle == trailer:getVehicleTowedBy() then
                M.currentTrailer = trailer
            end

            if otherData.beingTowedBy then
                local towingVehicle = otherData.beingTowedBy
                local isLightOn = towingVehicle:getHeadlightsOn()
                local isStopLightOn = towingVehicle:getStoplightsOn()
                local isReverseLightOn = M.isReverseLightOn(towingVehicle)
                lightData.isLightOn = isLightOn
                lightData.isStopLightOn = isStopLightOn
                lightData.isReverseLightOn = isReverseLightOn
                return         
            else
                lightData.isLightOn = false
                lightData.isStopLightOn = false

                local isLightOn = false
                local isStopLightOn = false

                if isLightOn == false and isStopLightOn == false then
                    if lightData.isLightOn == false and lightData.isStopLightOn == false then
                        return
                    end
                else
                    lightData.isLightOn = false
                    lightData.isStopLightOn = false
                    return
                end
            end
        else 
            -- M.updateVehicleLights(trailer)
        end
    end
end

function M.updateVehicleLights(vehicle)
    if vehicle then
        local keyId = vehicle:getKeyId()
        if not M.vehicles[keyId] then M.addVehicleToRuntime(vehicle) end

        local lightData = M.vehicles[keyId].lightData

        lightData.isLightOn = vehicle:getHeadlightsOn()
        lightData.isStopLightOn = vehicle:getStoplightsOn()
        lightData.isReverseLightOn = M.isReverseLightOn(vehicle)

    end
end

function M.turnOffLights(vehicle)

    if not M.isATrailer(vehicle) then
        local keyId = vehicle:getKeyId()
        local lightData = M.vehicles[keyId].lightData
        lightData.isLightOn = false
        lightData.isStopLightOn = false
        lightData.isReverseLightOn = false
        lights.addRefreshLightInstances(vehicle)
    end
end

function M.isReverseLightOn(vehicle)
        if not TaillightsHaibane.SETTINGS.options.reverseLight then
            return false
        end

        local keyId = vehicle:getKeyId()
        if not M.vehicles[keyId] then M.addVehicleToRuntime(vehicle) end
        local lightData = M.vehicles[keyId].lightData

        if vehicle:getTransmissionNumber() > 0 then
            return false
        elseif vehicle:getTransmissionNumber() == -1 then
            return true
        elseif lightData.isReverseLightOn == true then
            return true
        end  
end

function M.updateTimerFunction()
    
    local vehicle = M.currentVehicle
    local trailer = M.currentTrailer
    local deleteList = {}
    -- local otherData = M.vehicles[trailer:getKeyId()].otherData
    M.tick = M.tick + 1

    if M.tick > 60 then M.tick = 1 end
    
    if M.tick % 1 == 0 and vehicle then 
        M.updateVehicleLights(vehicle) 
        lights.addRefreshLightInstances(vehicle)
        if trailer then
                M.updateTrailerLights(trailer)
                lights.addRefreshLightInstances(trailer)
        end
    end

    if M.tick % 4 == 0 then
        for i = 1, #M.vehiclesKeyIdList do
            vehicle = M.getVehicleByKeyId(M.vehiclesKeyIdList[i])
            if M.vehicles[M.vehiclesKeyIdList[i]].lightData.deleteFlag then
                deleteList[#deleteList + 1] = M.vehiclesKeyIdList[i]
            elseif vehicle ~= M.currentVehicle and vehicle ~= M.currentTrailer then
                local otherData = M.vehicles[M.vehiclesKeyIdList[i]].otherData
                if otherData.isATrailer then
                    M.updateTrailerLights(vehicle)
                    lights.addRefreshLightInstances(vehicle)
                else
                    M.updateVehicleLights(vehicle)
                    lights.addRefreshLightInstances(vehicle)
                end
            end
        end
    end

    if M.tick % 60 == 0 then
        M.flagFarVehicles()
        M.scanForVehicles()
        if ModOptions and ModOptions.getInstance then
            ModOptions:loadFile()
        end
    end

    for i = 1, #deleteList do
        vehicle = M.getVehicleByKeyId(deleteList[i])
        M.deleteInstance(vehicle)
    end
end

function M.createRuntimeTimer()
    M.runtimeUpdateTimer = ISTimer:new(
        "Update Timer",
        nil,
        M.updateTimerFunction,
        0.0167,
        true,
        false
    )   
end

function M.findVehicleInCache(keyId)    
    if M.vehicles[keyId] and M.vehicles[keyId].vehicle then
        return M.vehicles[keyId].vehicle
    end
    return nil
end

function M.findVehicleInCellList(keyId)
    local vehicleList = getCell():getVehicles()
    
    for i = 0, vehicleList:size() - 1 do
        if vehicleList:get(i):getKeyId() == keyId then
            return vehicleList:get(i)
        end
    end
    return nil
end

function M.isInRuntime(vehicle)
    local keyId = vehicle:getKeyId()
    for i = 1, #M.vehiclesKeyIdList do
        if M.vehiclesKeyIdList[i] == keyId then
                return true
        end
    end
    return false
end

function M.getVehicleByKeyId(keyId)
    if M.findVehicleInCache(keyId) then
        return M.findVehicleInCache(keyId)
    else
        return M.findVehicleInCellList(keyId)
    end
end

function M.setDeleteFlag(vehicle)
    local keyId = vehicle:getKeyId()
    if M.vehicles[keyId] then
        M.vehicles[keyId].lightData.deleteFlag = true
    end
end

function M.deleteInstance(vehicle)
    local keyId = vehicle:getKeyId()

    for i = 1, #M.vehiclesKeyIdList do
        if M.vehiclesKeyIdList[i] == keyId then
            table.remove(M.vehiclesKeyIdList, i)
            return
        end
    end
end

function M.isATrailer(vehicle)
    local scriptName = vehicle:getScriptName()
    local pattern = "[Tt]railer"
    local f1 = string.find(scriptName, pattern)
    return f1 ~= nil
end

function M.addVehicleToRuntime(vehicle)
    
    if M.isInRuntime(vehicle) then
        return false
    end
        
    local keyId = vehicle:getKeyId()
    M.vehicles[keyId] = {
        vehicle = vehicle,
        otherData = {
            beingTowedBy = vehicle:getVehicleTowedBy(),
            isATrailer = M.isATrailer(vehicle),
            position = {0, 0}
        },
        lightData = {
            lightInstances = {},
            timer = nil,
            isLightOn = vehicle:getHeadlightsOn(),
            isStopLightOn = vehicle:getStoplightsOn(),
            isReverseLightOn = nil,
            reverseFlag = nil,
            deleteFlag = nil
        }
    }

    M.vehiclesKeyIdList[#M.vehiclesKeyIdList + 1] = keyId
end 

return M