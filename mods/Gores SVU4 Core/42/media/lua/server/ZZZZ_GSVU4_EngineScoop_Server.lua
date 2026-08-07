--========================================================
-- Gore's SVU4 Core - Engine Scoop authoritative gameplay
--
-- Extra fuel use follows observed vanilla fuel consumption, so the penalty
-- naturally scales with each vehicle. Passive wear accrues whenever the engine
-- runs, while sustained excessive speed adds the harsher stress damage defined
-- for the fitted scoop shape.
--========================================================

if isClient and isClient() then return end

require "GoresSVU4Core/GSVU4_Upgrades_Config"
require "GoresSVU4Core/GSVU4_EngineScoop"

local stressClockByVehicle = {}
local lastStressSweepMs = 0

local function getWorldAgeHours()
    if not getGameTime then return nil end
    local okTime, gameTime = pcall(getGameTime)
    if not okTime or not gameTime or not gameTime.getWorldAgeHours then return nil end
    local okHours, hours = pcall(function() return gameTime:getWorldAgeHours() end)
    if okHours then return tonumber(hours) end
    return nil
end

local function getNowMs()
    if getTimestampMs then
        local ok, value = pcall(getTimestampMs)
        if ok and tonumber(value) then return tonumber(value) end
    end
    return os.time() * 1000
end

local function getVehicleKey(vehicle)
    if not vehicle then return nil end
    if vehicle.getId then
        local ok, value = pcall(function() return vehicle:getId() end)
        if ok and value ~= nil then return "id:" .. tostring(value) end
    end
    if vehicle.getOnlineID then
        local ok, value = pcall(function() return vehicle:getOnlineID() end)
        if ok and value ~= nil then return "online:" .. tostring(value) end
    end
    return tostring(vehicle)
end

local function getDriver(vehicle)
    if not vehicle or not vehicle.getDriver then return nil end
    local ok, driver = pcall(function() return vehicle:getDriver() end)
    if ok then return driver end
    return nil
end

local function isEngineRunning(vehicle)
    if not vehicle or not vehicle.isEngineRunning then return false end
    local ok, running = pcall(function() return vehicle:isEngineRunning() end)
    return ok and running == true
end

local function getSpeedMph(vehicle)
    if not vehicle or not vehicle.getCurrentSpeedKmHour then return 0 end
    local ok, value = pcall(function() return vehicle:getCurrentSpeedKmHour() end)
    if not ok then return 0 end
    return math.abs(tonumber(value) or 0) * 0.621371
end

local function getGasPart(vehicle)
    if not vehicle or not vehicle.getPartById then return nil end
    local ok, part = pcall(function() return vehicle:getPartById("GasTank") end)
    if ok then return part end
    return nil
end

local function getEnginePart(vehicle)
    if not vehicle or not vehicle.getPartById then return nil end
    local ok, part = pcall(function() return vehicle:getPartById("Engine") end)
    if ok then return part end
    return nil
end

local function getFuelAmount(gasPart)
    if not gasPart or not gasPart.getContainerContentAmount then return 0 end
    local ok, amount = pcall(function() return gasPart:getContainerContentAmount() end)
    return ok and math.max(0, tonumber(amount) or 0) or 0
end

local function getFuelReserve(vdata)
    return math.max(0, tonumber(vdata and vdata.GSVU4_fuelReserve) or 0)
end

local function getTotalFuel(gasPart, vdata)
    return getFuelAmount(gasPart) + getFuelReserve(vdata)
end

local function syncFuel(vehicle, gasPart, reserveChanged)
    if vehicle and gasPart and vehicle.transmitPartModData then
        pcall(function() vehicle:transmitPartModData(gasPart) end)
    end
    -- Match the established gas-leak and auxiliary-fuel sync path. Main-tank
    -- changes need the vehicle update as well, while reserve changes live in
    -- vehicle modData directly.
    if vehicle and vehicle.transmitModData then
        pcall(function() vehicle:transmitModData() end)
    end
end

local function drainExtraFuel(vehicle, gasPart, vdata, amount)
    amount = math.max(0, tonumber(amount) or 0)
    if amount <= 0.000001 then return 0 end

    local main = getFuelAmount(gasPart)
    local reserve = getFuelReserve(vdata)
    local requested = math.min(amount, main + reserve)
    if requested <= 0 then return 0 end

    local fromMain = math.min(main, requested)
    local remaining = requested - fromMain
    local reserveChanged = false

    if fromMain > 0 and gasPart and gasPart.setContainerContentAmount then
        pcall(function() gasPart:setContainerContentAmount(math.max(0, main - fromMain)) end)
    end

    if remaining > 0 then
        vdata.GSVU4_fuelReserve = math.max(0, reserve - remaining)
        reserveChanged = true
    end

    syncFuel(vehicle, gasPart, reserveChanged)
    return requested
end

local function applyEngineDamage(vehicle, damage)
    damage = math.floor(math.max(0, tonumber(damage) or 0))
    if damage <= 0 then return false end

    local engine = getEnginePart(vehicle)
    if not engine or not engine.getCondition or not engine.setCondition then return false end

    local okCondition, current = pcall(function() return engine:getCondition() end)
    current = okCondition and tonumber(current) or nil
    if not current or current <= 0 then return false end

    local newCondition = math.max(0, current - damage)
    if newCondition == current then return false end

    pcall(function() engine:setCondition(newCondition) end)
    if vehicle and vehicle.transmitPartCondition then
        pcall(function() vehicle:transmitPartCondition(engine) end)
    end
    return true
end

local function applyPassiveWear(vehicle, state, deltaHours, hoursPerCondition)
    deltaHours = math.max(0, tonumber(deltaHours) or 0)
    hoursPerCondition = tonumber(hoursPerCondition)
    if deltaHours <= 0 or not hoursPerCondition or hoursPerCondition <= 0 then return false end

    state.wearHours = math.max(0, tonumber(state.wearHours) or 0) + deltaHours
    local damage = math.floor(state.wearHours / hoursPerCondition)
    if damage <= 0 then return false end

    state.wearHours = state.wearHours - (damage * hoursPerCondition)
    return applyEngineDamage(vehicle, damage)
end

local function ensureRuntime(vdata)
    local state = vdata and vdata.gEngineScoopRuntime or nil
    if type(state) ~= "table" then
        state = {
            wearHours = 0,
            stressSeconds = 0,
            stressDamageSeconds = 0,
        }
        vdata.gEngineScoopRuntime = state
    end
    state.wearHours = math.max(0, tonumber(state.wearHours) or 0)
    state.stressSeconds = math.max(0, tonumber(state.stressSeconds) or 0)
    state.stressDamageSeconds = math.max(0, tonumber(state.stressDamageSeconds) or 0)
    return state
end

local function resetStress(state)
    if not state then return end
    state.stressSeconds = 0
    state.stressDamageSeconds = 0
end

local function resetObservation(state, gasPart, vdata, grade, operational)
    state.lastWorldAgeHours = getWorldAgeHours()
    state.lastTotalFuel = getTotalFuel(gasPart, vdata)
    state.grade = tostring(grade or "")
    state.operational = operational == true
end

local function getInstalledState(vehicle)
    if not vehicle or not vehicle.getModData then return nil end
    local okData, vdata = pcall(function() return vehicle:getModData() end)
    if not okData or not vdata then return nil end

    local installed = vdata.gUpgrades and vdata.gUpgrades.EngineScoop or nil
    if not installed then return vdata, nil, nil, false end

    local cfg = GSVU4EngineScoop.getGradeConfig(installed.grade)
    local operational = cfg ~= nil and (tonumber(installed.health) or 100) > 0
    return vdata, installed, cfg, operational
end

local function processVehicleMinute(vehicle)
    local vdata, installed, cfg, operational = getInstalledState(vehicle)
    if not vdata then return end

    if not installed then
        local powerState = vdata.gEngineScoopPowerRuntime
        if type(powerState) == "table" and powerState.wasOperational == true
        and VehicleArmor_UpdateEnginePower then
            pcall(VehicleArmor_UpdateEnginePower, vehicle, "scoop-removal-detected", nil, true)
        end
        vdata.gEngineScoopRuntime = nil
        return
    end
    if not cfg then return end

    local gasPart = getGasPart(vehicle)
    local state = ensureRuntime(vdata)
    local grade = tostring(installed.grade or "")

    if state.grade ~= grade or state.operational ~= operational then
        resetObservation(state, gasPart, vdata, grade, operational)
        resetStress(state)
        if VehicleArmor_UpdateMass then pcall(VehicleArmor_UpdateMass, vehicle) end
        return
    end

    local now = getWorldAgeHours()
    if not now then return end

    if not operational or not isEngineRunning(vehicle) then
        state.lastWorldAgeHours = now
        state.lastTotalFuel = getTotalFuel(gasPart, vdata)
        return
    end

    local previousHours = tonumber(state.lastWorldAgeHours)
    local previousFuel = tonumber(state.lastTotalFuel)
    local currentFuel = getTotalFuel(gasPart, vdata)

    if not previousHours or previousFuel == nil then
        state.lastWorldAgeHours = now
        state.lastTotalFuel = currentFuel
        return
    end

    -- Prevent unusual load-order pauses from retroactively charging large blocks
    -- of wear. Under normal play this event advances by about one game minute.
    local deltaHours = math.max(0, math.min(0.5, now - previousHours))

    -- lastTotalFuel is stored after our own surcharge, so a positive difference
    -- is fuel consumed by the game or another legitimate vehicle system.
    local observedConsumption = math.max(0, previousFuel - currentFuel)
    local extraFraction = math.max(0, tonumber(cfg.extraFuelFraction) or 0)
    if observedConsumption > 0 and extraFraction > 0 then
        drainExtraFuel(vehicle, gasPart, vdata, observedConsumption * extraFraction)
    end

    local damaged = applyPassiveWear(
        vehicle,
        state,
        deltaHours,
        tonumber(cfg.wearHoursPerCondition)
    )

    state.lastWorldAgeHours = now
    state.lastTotalFuel = getTotalFuel(gasPart, vdata)

    if damaged and vehicle.transmitModData then
        pcall(function() vehicle:transmitModData() end)
    end
end

local function forEachActiveDriverVehicle(callback)
    local seen = {}

    if getOnlinePlayers then
        local okPlayers, players = pcall(getOnlinePlayers)
        if okPlayers and players and players.size and players.get then
            local okSize, count = pcall(function() return players:size() end)
            count = okSize and tonumber(count) or 0
            if count and count > 0 then
                for i = 0, count - 1 do
                    local okPlayer, player = pcall(function() return players:get(i) end)
                    local vehicle = okPlayer and player and player.getVehicle and player:getVehicle() or nil
                    local key = getVehicleKey(vehicle)
                    if vehicle and key and not seen[key] and getDriver(vehicle) == player then
                        seen[key] = true
                        callback(vehicle, key)
                    end
                end
                return
            end
        end
    end

    local count = getNumActivePlayers and getNumActivePlayers() or 1
    for i = 0, math.max(0, tonumber(count) or 1) - 1 do
        local player = getSpecificPlayer and getSpecificPlayer(i) or (i == 0 and getPlayer and getPlayer() or nil)
        local vehicle = player and player.getVehicle and player:getVehicle() or nil
        local key = getVehicleKey(vehicle)
        if vehicle and key and not seen[key] and getDriver(vehicle) == player then
            seen[key] = true
            callback(vehicle, key)
        end
    end
end

local function forEachLoadedVehicle(callback)
    local seen = {}
    local foundAny = false

    if getCell then
        local okCell, cell = pcall(getCell)
        if okCell and cell and cell.getVehicles then
            local okVehicles, vehicles = pcall(function() return cell:getVehicles() end)
            if okVehicles and vehicles then
                if vehicles.size and vehicles.get then
                    local okSize, count = pcall(function() return vehicles:size() end)
                    count = okSize and tonumber(count) or 0
                    for i = 0, math.max(0, count or 0) - 1 do
                        local okVehicle, vehicle = pcall(function() return vehicles:get(i) end)
                        local key = okVehicle and getVehicleKey(vehicle) or nil
                        if vehicle and key and not seen[key] then
                            seen[key] = true
                            foundAny = true
                            callback(vehicle, key)
                        end
                    end
                elseif type(vehicles) == "table" then
                    for _, vehicle in pairs(vehicles) do
                        local key = getVehicleKey(vehicle)
                        if vehicle and key and not seen[key] then
                            seen[key] = true
                            foundAny = true
                            callback(vehicle, key)
                        end
                    end
                end
            end
        end
    end

    -- Dedicated servers do not always expose an iterable global vehicle list.
    -- Active driver vehicles remain a safe fallback in that case.
    if not foundAny then
        forEachActiveDriverVehicle(callback)
    end
end

local function processHighSpeedStress(vehicle, key, nowMs)
    local vdata, installed, cfg, operational = getInstalledState(vehicle)
    if not vdata or not installed or not cfg then
        stressClockByVehicle[key] = nil
        return
    end

    local state = ensureRuntime(vdata)
    if not operational or not isEngineRunning(vehicle) or not getDriver(vehicle) then
        resetStress(state)
        stressClockByVehicle[key] = nowMs
        return
    end

    local previousMs = tonumber(stressClockByVehicle[key])
    stressClockByVehicle[key] = nowMs
    if not previousMs then return end

    local deltaSeconds = math.max(0, math.min(2.5, (nowMs - previousMs) / 1000))
    if deltaSeconds <= 0 then return end

    local threshold = tonumber(cfg.stressSpeedMph)
    local grace = tonumber(cfg.stressGraceSeconds)
    local interval = tonumber(cfg.stressDamageIntervalSeconds)
    if not threshold or not grace or not interval or interval <= 0 then
        resetStress(state)
        return
    end

    if getSpeedMph(vehicle) < threshold then
        resetStress(state)
        return
    end

    state.stressSeconds = state.stressSeconds + deltaSeconds
    if state.stressSeconds < grace then return end

    state.stressDamageSeconds = state.stressDamageSeconds + deltaSeconds
    local damage = math.floor(state.stressDamageSeconds / interval)
    if damage <= 0 then return end

    state.stressDamageSeconds = state.stressDamageSeconds - (damage * interval)
    if applyEngineDamage(vehicle, damage) and vehicle.transmitModData then
        pcall(function() vehicle:transmitModData() end)
    end
end

local function onEveryOneMinute()
    forEachLoadedVehicle(processVehicleMinute)
end

local function onTick()
    local nowMs = getNowMs()
    if nowMs - lastStressSweepMs < 1000 then return end
    lastStressSweepMs = nowMs

    local active = {}
    forEachActiveDriverVehicle(function(vehicle, key)
        active[key] = true

        -- Check the drivetrain once per second while actively driven. This is
        -- read-only while power and max speed remain correct, and refreshes
        -- Bullet only after a genuine drivetrain reset.
        local _, installed, cfg, operational = getInstalledState(vehicle)
        if installed and cfg and operational and isEngineRunning(vehicle)
        and VehicleArmor_UpdateEnginePower then
            pcall(VehicleArmor_UpdateEnginePower, vehicle, "active-driver-check", nil, false)
        end

        processHighSpeedStress(vehicle, key, nowMs)
    end)

    for key in pairs(stressClockByVehicle) do
        if not active[key] then stressClockByVehicle[key] = nil end
    end
end

local function onEnterVehicle(character)
    if not character or not character.getVehicle then return end
    local vehicle = character:getVehicle()
    if not vehicle or getDriver(vehicle) ~= character then return end

    local vdata, installed, cfg, operational = getInstalledState(vehicle)
    if not vdata or not installed or not cfg then return end

    local state = ensureRuntime(vdata)
    resetStress(state)
    resetObservation(state, getGasPart(vehicle), vdata, installed.grade, operational)
    stressClockByVehicle[getVehicleKey(vehicle)] = getNowMs()

    if VehicleArmor_UpdateMass then pcall(VehicleArmor_UpdateMass, vehicle) end
end

if Events and Events.EveryOneMinute then Events.EveryOneMinute.Add(onEveryOneMinute) end
if Events and Events.OnTick then Events.OnTick.Add(onTick) end
if Events and Events.OnEnterVehicle then Events.OnEnterVehicle.Add(onEnterVehicle) end
