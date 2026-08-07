--========================================================
-- GORE'S SVU4 CORE - VISUAL REFRESH HOOKS
--
-- Optional visual packs register profiles in VehicleArmor_Visuals.
-- This file keeps the 3D layer in sync after installs/repairs/
-- uninstalls, including cases where model visibility is not ready
-- at the exact timed-action completion frame.
--========================================================

require "VehicleArmor/VehicleArmor_Visuals"

local GSVU4_VISUAL_REFRESH_TICK = 0
local GSVU4_VISUAL_REFRESH_INTERVAL = 999999 -- Phase 1l: periodic visual refresh disabled; queued refresh handles changes
local GSVU4_VISUAL_REFRESH_RANGE = 18

local function safeApply(vehicle)
    if not vehicle then return end

    pcall(function()
        if GSVU4Core
        and GSVU4Core.ApplyCompleteVehicleVisualState then
            GSVU4Core.ApplyCompleteVehicleVisualState(vehicle)
        elseif VehicleArmorVisuals
        and VehicleArmorVisuals.ApplyFullReset then
            VehicleArmorVisuals.ApplyFullReset(vehicle)
        elseif VehicleArmorVisuals
        and VehicleArmorVisuals.Apply then
            VehicleArmorVisuals.Apply(vehicle)
        end
    end)
end

local function getPlayerSafe()
    if not getPlayer then return nil end
    local ok, p = pcall(getPlayer)
    if ok then return p end
    return nil
end

local function refreshNearbyVehicles()
    local player = getPlayerSafe()
    if not player then return end

    -- Always refresh the currently occupied vehicle first.
    local current = player.getVehicle and player:getVehicle() or nil
    if current then safeApply(current) end

    if not getCell then return end
    local cell = getCell()
    if not cell or not cell.getVehicles then return end

    local px = player.getX and player:getX() or nil
    local py = player.getY and player:getY() or nil
    if not px or not py then return end

    local ok, vehicles = pcall(function() return cell:getVehicles() end)
    if not ok or not vehicles then return end

    local function consider(vehicle)
        if not vehicle or vehicle == current then return end
        if not vehicle.getX or not vehicle.getY then return end
        local vx, vy = vehicle:getX(), vehicle:getY()
        if not vx or not vy then return end
        if math.abs(vx - px) <= GSVU4_VISUAL_REFRESH_RANGE and math.abs(vy - py) <= GSVU4_VISUAL_REFRESH_RANGE then
            safeApply(vehicle)
        end
    end

    -- B42 can return different collection-like objects here depending on context.
    -- Do not assume it is a Lua table; ipairs() on Java userdata throws
    -- "Expected a table" and breaks the refresh hook.
    if type(vehicles) == "table" then
        for _, vehicle in pairs(vehicles) do
            consider(vehicle)
        end
        return
    end

    if vehicles.size and vehicles.get then
        local okSize, count = pcall(function() return vehicles:size() end)
        if okSize and count then
            for i = 0, count - 1 do
                local okGet, vehicle = pcall(function() return vehicles:get(i) end)
                if okGet then consider(vehicle) end
            end
        end
        return
    end

    if vehicles.getCount and vehicles.get then
        local okCount, count = pcall(function() return vehicles:getCount() end)
        if okCount and count then
            for i = 0, count - 1 do
                local okGet, vehicle = pcall(function() return vehicles:get(i) end)
                if okGet then consider(vehicle) end
            end
        end
        return
    end
end

local function onPlayerUpdate(player)
    GSVU4_VISUAL_REFRESH_TICK = GSVU4_VISUAL_REFRESH_TICK + 1
    if GSVU4_VISUAL_REFRESH_TICK < GSVU4_VISUAL_REFRESH_INTERVAL then return end
    GSVU4_VISUAL_REFRESH_TICK = 0
    refreshNearbyVehicles()
end

local function onEnterVehicle(player)
    local vehicle = player and player.getVehicle and player:getVehicle() or nil
    if vehicle then safeApply(vehicle) end
end

local function onGameStart()
    refreshNearbyVehicles()
end

if Events then
    -- No periodic OnPlayerUpdate refresh. Visuals are refreshed by explicit
    -- install/repair/remove events, OnEnterVehicle and OnGameStart only.
    if Events.OnEnterVehicle then Events.OnEnterVehicle.Add(onEnterVehicle) end
    if Events.OnGameStart then Events.OnGameStart.Add(onGameStart) end
end
