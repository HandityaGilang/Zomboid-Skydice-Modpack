--========================================================
-- Gore's SVU4 Core - Engine Scoop shared support
--
-- Optional vehicle packs register exact vehicle scripts that have fitted
-- scoop meshes. Core owns install validation and gameplay effects.
--========================================================

GSVU4EngineScoop = GSVU4EngineScoop or {}
GSVU4EngineScoop.SupportedVehicles = GSVU4EngineScoop.SupportedVehicles or {}

local function stripBase(name)
    if not name then return nil end
    return tostring(name):gsub("^Base%.", "")
end

local function getVehicleScriptName(vehicle)
    if not vehicle then return nil end

    if vehicle.getScriptName then
        local ok, value = pcall(function() return vehicle:getScriptName() end)
        if ok and value and tostring(value) ~= "" then return tostring(value) end
    end

    if vehicle.getScript then
        local okScript, script = pcall(function() return vehicle:getScript() end)
        if okScript and script then
            if script.getFullName then
                local okName, value = pcall(function() return script:getFullName() end)
                if okName and value and tostring(value) ~= "" then return tostring(value) end
            end
            if script.getName then
                local okName, value = pcall(function() return script:getName() end)
                if okName and value and tostring(value) ~= "" then return tostring(value) end
            end
        end
    end

    return nil
end

local function getVehiclePart(vehicle, partId)
    if not vehicle or not partId or not vehicle.getPartById then return nil end
    local ok, part = pcall(function() return vehicle:getPartById(partId) end)
    if ok then return part end
    return nil
end

function GSVU4EngineScoop.registerVehicleScript(scriptName)
    local short = stripBase(scriptName)
    if not short or short == "" then return false end
    GSVU4EngineScoop.SupportedVehicles[short] = true
    GSVU4EngineScoop.SupportedVehicles["Base." .. short] = true
    return true
end

function GSVU4EngineScoop.registerVehicleScripts(scriptNames)
    local count = 0
    for _, scriptName in ipairs(scriptNames or {}) do
        if GSVU4EngineScoop.registerVehicleScript(scriptName) then count = count + 1 end
    end
    return count
end

function GSVU4EngineScoop.getVehicleScriptName(vehicle)
    return getVehicleScriptName(vehicle)
end

function GSVU4EngineScoop.isSupportedVehicle(vehicle)
    local scriptName = getVehicleScriptName(vehicle)
    if not scriptName then return false end
    local short = stripBase(scriptName)
    return GSVU4EngineScoop.SupportedVehicles[scriptName] == true
        or GSVU4EngineScoop.SupportedVehicles[short] == true
        or GSVU4EngineScoop.SupportedVehicles["Base." .. tostring(short)] == true
end

function GSVU4EngineScoop.getInstalledUpgrade(vehicle)
    if not vehicle or not vehicle.getModData then return nil end
    local ok, vdata = pcall(function() return vehicle:getModData() end)
    if not ok or not vdata or not vdata.gUpgrades then return nil end
    return vdata.gUpgrades.EngineScoop
end

function GSVU4EngineScoop.isOperational(vehicle)
    local installed = GSVU4EngineScoop.getInstalledUpgrade(vehicle)
    if not installed then return false end
    return (tonumber(installed.health) or 100) > 0
end

function GSVU4EngineScoop.canInstallOnVehicle(vehicle)
    if not vehicle then return false, "Vehicle unavailable." end
    if not GSVU4EngineScoop.isSupportedVehicle(vehicle) then
        return false, "No fitted Engine Scoop model is registered for this vehicle."
    end

    if not getVehiclePart(vehicle, "Engine") then
        return false, "Engine Scoop requires a vehicle with a serviceable engine."
    end

    if not getVehiclePart(vehicle, "GasTank") then
        return false, "Engine Scoop requires a fuel-powered vehicle."
    end

    return true, nil
end

function GSVU4EngineScoop.getGradeConfig(grade)
    if not GSVU4UpgradesConfig or not GSVU4UpgradesConfig.getGradeConfig then return nil end
    return GSVU4UpgradesConfig.getGradeConfig("EngineScoop", grade)
end

function GSVU4EngineScoop.getPowerMultiplier(vehicle)
    local installed = GSVU4EngineScoop.getInstalledUpgrade(vehicle)
    if not installed or not GSVU4EngineScoop.isOperational(vehicle) then return 1.0 end
    local cfg = GSVU4EngineScoop.getGradeConfig(installed.grade)
    return math.max(0.1, tonumber(cfg and cfg.engineForceMultiplier) or 1.0)
end

function GSVU4EngineScoop.getFuelPenalty(vehicle)
    local installed = GSVU4EngineScoop.getInstalledUpgrade(vehicle)
    if not installed or not GSVU4EngineScoop.isOperational(vehicle) then return 0 end
    local cfg = GSVU4EngineScoop.getGradeConfig(installed.grade)
    return math.max(0, tonumber(cfg and cfg.extraFuelFraction) or 0)
end

function GSVU4EngineScoop.getWearHoursPerCondition(vehicle)
    local installed = GSVU4EngineScoop.getInstalledUpgrade(vehicle)
    if not installed or not GSVU4EngineScoop.isOperational(vehicle) then return nil end
    local cfg = GSVU4EngineScoop.getGradeConfig(installed.grade)
    local hours = tonumber(cfg and cfg.wearHoursPerCondition)
    if not hours or hours <= 0 then return nil end
    return hours
end

function GSVU4EngineScoop.resetRuntime(vehicle, clearWear)
    if not vehicle or not vehicle.getModData then return end
    local ok, vdata = pcall(function() return vehicle:getModData() end)
    if not ok or not vdata then return end
    local old = vdata.gEngineScoopRuntime
    local wear = (not clearWear and old and tonumber(old.wearHours)) or 0
    vdata.gEngineScoopRuntime = {
        wearHours = wear or 0,
        stressSeconds = 0,
        stressDamageSeconds = 0,
    }
end
