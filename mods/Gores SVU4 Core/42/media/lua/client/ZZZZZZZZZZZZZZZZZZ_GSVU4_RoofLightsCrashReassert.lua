--========================================================
-- Gore's SVU4 Core - Roof Lights Crash Reassert
--
-- In B42.19 MP, a vehicle impact can occasionally knock the native
-- VehiclePart light emitter inactive while SVU4 modData still says the
-- roof lights are on. This lightweight watchdog re-applies the intended
-- active state for the local player's current vehicle.
--========================================================

require "GoresSVU4Core/GSVU4_LightingSystem"

local tick = 0
local LIGHT_IDS = { "RoofLights", "RoofLightsLeft", "RoofLightsRight", "RoofLightsRear" }

local function reassertRoofLights(player)
    if not player or not player.isLocalPlayer or not player:isLocalPlayer() then return end
    tick = tick + 1
    if tick % 60 ~= 0 then return end

    local vehicle = player.getVehicle and player:getVehicle() or nil
    if not vehicle or not GSVU4 or not GSVU4.RoofLights then return end
    if not GSVU4.RoofLights.isInstalled or not GSVU4.RoofLights.isInstalled(vehicle) then return end
    if not GSVU4.RoofLights.isActive or GSVU4.RoofLights.isActive(vehicle) ~= true then return end

    if GSVU4.RoofLights.applyLightActive then
        pcall(function() GSVU4.RoofLights.applyLightActive(vehicle, true) end)
    end
    if GSVU4.RoofLights.applySingleLight then
        for _, upgradeId in ipairs(LIGHT_IDS) do
            if GSVU4.RoofLights.isInstalled(vehicle, upgradeId) then
                pcall(function() GSVU4.RoofLights.applySingleLight(vehicle, upgradeId, true, true) end)
            end
        end
    end
end

Events.OnPlayerUpdate.Add(reassertRoofLights)
