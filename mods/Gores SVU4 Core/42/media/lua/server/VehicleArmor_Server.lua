require "GoresSVU4Core/GSVU4_KI5FullBlock"
require "GoresSVU4Core/GSVU4_KI5Compatibility"
require "GoresSVU4Core/GSVU4_PZKCompatibility"
--========================================================
-- VEHICLE ARMOR SERVER  (B42.19)
-- Server only.
--
-- Handles armour/upgrade mass, Engine Scoop power and proportional
-- max-speed adjustment. The active-driver check is read-only while values
-- remain correct and reapplies them only after a genuine game reset.
--========================================================

if isClient() then return end   -- lowercase i is required

require "VehicleArmor_Config"
require "GoresSVU4Core/GSVU4_Upgrades_Config"
require "GoresSVU4Core/GSVU4_FilteredAirIntake"
require "GoresSVU4Core/GSVU4_EngineScoop"
require "GoresSVU4Core/GSVU4_AutoTuneMilitaryRadio"

----------------------------------------------------------
-- ENGINE POWER / MASS SUPPORT
----------------------------------------------------------
local GSVU4_POWER_RUNTIME_VERSION = 8

local function GSVU4_ReadPositiveNumber(object, methodName)
    if not object or not methodName or not object[methodName] then return nil end
    local ok, value = pcall(function() return object[methodName](object) end)
    value = ok and tonumber(value) or nil
    if value and value > 0 then return value end
    return nil
end

local function GSVU4_ReadEnginePower(vehicle)
    return GSVU4_ReadPositiveNumber(vehicle, "getEnginePower")
end

local function GSVU4_ReadEngineQuality(vehicle)
    local quality = GSVU4_ReadPositiveNumber(vehicle, "getEngineQuality") or 50
    return math.floor(quality + 0.5)
end


local function GSVU4_ReadScriptLoudness(script)
    local loudness = GSVU4_ReadPositiveNumber(script, "getEngineLoudness") or 100
    return math.floor(loudness + 0.5)
end

local function GSVU4_ReadMaxSpeed(vehicle, script)
    return GSVU4_ReadPositiveNumber(vehicle, "getMaxSpeed")
        or GSVU4_ReadPositiveNumber(script, "getMaxSpeed")
end





local function GSVU4_ValueTolerance(value, minimum)
    return math.max(tonumber(minimum) or 0.1, math.abs(tonumber(value) or 0) * 0.01)
end

local function GSVU4_IsCloseValue(a, b, minimum)
    a = tonumber(a)
    b = tonumber(b)
    if not a or not b then return false end
    return math.abs(a - b) <= GSVU4_ValueTolerance(b, minimum)
end

local function GSVU4_IsClosePower(a, b)
    return GSVU4_IsCloseValue(a, b, 2)
end

local function GSVU4_IsCloseSpeed(a, b)
    return GSVU4_IsCloseValue(a, b, 0.25)
end

local function GSVU4_GetMassState(vehicle, vdata, script)
    local baseMass = tonumber(script and script.getMass and script:getMass()) or 1000
    local addedMass = 0

    if vdata and vdata.gArmor then
        for partId, armor in pairs(vdata.gArmor) do
            addedMass = addedMass + (
                VehicleArmorConfig.getArmorWeight
                and VehicleArmorConfig.getArmorWeight(armor.grade, partId)
                or 0
            )
        end
    end

    if vdata and vdata.gUpgrades and GSVU4UpgradesConfig and GSVU4UpgradesConfig.getGradeConfig then
        for upgradeId, upgrade in pairs(vdata.gUpgrades) do
            local cfg = upgrade and GSVU4UpgradesConfig.getGradeConfig(upgradeId, upgrade.grade)
            addedMass = addedMass + (cfg and tonumber(cfg.weight) or tonumber(upgrade and upgrade.weight) or 0)
        end
    end

    local finalMass = math.max(1, baseMass + addedMass)
    return baseMass, addedMass, finalMass
end

local function GSVU4_GetPowerRuntime(vdata)
    local state = vdata and vdata.gEngineScoopPowerRuntime or nil
    local migrated = false
    local oldVersion = type(state) == "table" and tonumber(state.version) or nil

    if type(state) ~= "table" then
        state = {}
        vdata.gEngineScoopPowerRuntime = state
    end

    if oldVersion ~= GSVU4_POWER_RUNTIME_VERSION then
        migrated = true
        state.version = GSVU4_POWER_RUNTIME_VERSION
        -- Preserve power and max-speed baselines while clearing obsolete
        -- runtime bookkeeping from older versions.
        state.migratedFromVersion = nil
        state.lastDiagnosticMs = nil
        state.lastDrivetrainWriteMs = nil
        state.lastReason = nil
        state.lastEngineAppliedOk = nil
        state.lastMaxAppliedOk = nil
        state.lastBulletRefreshOk = nil
    end

    return state, migrated
end

local function GSVU4_GetScoopPowerState(vehicle)
    local multiplier = 1.0
    local grade = "None"
    local operational = false

    if GSVU4EngineScoop and GSVU4EngineScoop.getInstalledUpgrade then
        local installed = GSVU4EngineScoop.getInstalledUpgrade(vehicle)
        if installed then grade = tostring(installed.grade or "Unknown") end
    end

    if GSVU4EngineScoop and GSVU4EngineScoop.isOperational then
        operational = GSVU4EngineScoop.isOperational(vehicle) == true
    end

    if operational and GSVU4EngineScoop and GSVU4EngineScoop.getPowerMultiplier then
        multiplier = tonumber(GSVU4EngineScoop.getPowerMultiplier(vehicle)) or 1.0
    end

    return math.max(0.1, multiplier), grade, operational
end

local function GSVU4_RefreshBullet(vehicle)
    if not vehicle then return false, "unavailable" end

    if vehicle.updateBulletStats then
        local ok = pcall(function() vehicle:updateBulletStats() end)
        if ok then return true, "updateBulletStats" end
    end

    -- Fallback for unusual vehicle frameworks. Avoid updatePhysics on a
    -- dedicated server because B42.19 can touch client-only UI state there.
    local dedicatedServer = false
    if isServer then
        local okServer, result = pcall(function() return isServer() end)
        dedicatedServer = okServer and result == true
    end

    if vehicle.updatePhysics and not dedicatedServer then
        local ok = pcall(function() vehicle:updatePhysics() end)
        if ok then return true, "updatePhysics" end
    end

    return false, "failed"
end


----------------------------------------------------------
-- VehicleArmor_UpdateEnginePower
-- Public so Engine Scoop runtime code can restore values after game resets.
-- The active-driver check does not rewrite values that are already correct.
----------------------------------------------------------
function VehicleArmor_UpdateEnginePower(vehicle, _reason, _legacyUnused, forceBulletRefresh)
    if not vehicle or not vehicle.getModData or not vehicle.getScript then return false end

    local vdata = vehicle:getModData()
    local script = vehicle:getScript()
    if not vdata or not script then return false end

    local baseMass, addedMass, finalMass = GSVU4_GetMassState(vehicle, vdata, script)
    local massRatio = finalMass > 0 and (baseMass / finalMass) or 1.0
    local multiplier, _, operational = GSVU4_GetScoopPowerState(vehicle)
    local scriptForce = tonumber(script:getEngineForce()) or 3000
    local scriptMaxSpeed = GSVU4_ReadPositiveNumber(script, "getMaxSpeed")
    local beforePower = GSVU4_ReadEnginePower(vehicle)
    local beforeMaxSpeed = GSVU4_ReadMaxSpeed(vehicle, script)
    local scriptLoudness = GSVU4_ReadScriptLoudness(script)
    local state, migrated = GSVU4_GetPowerRuntime(vdata)

    local basePower = tonumber(state.basePower)
    local powerResetDetected = false

    if not basePower or basePower <= 0 then
        local oldBase = tonumber(vdata.gArmorBaseEnginePower) or tonumber(vdata.gArmorBaseEngineForce)
        local oldExpected = oldBase and math.floor(oldBase * massRatio * multiplier + 0.5) or nil

        if oldBase and beforePower and oldExpected and GSVU4_IsClosePower(beforePower, oldExpected) then
            basePower = oldBase
        else
            basePower = beforePower or oldBase or scriptForce
        end
    else
        local matchesRequested = GSVU4_IsClosePower(beforePower, state.lastRequestedPower)
        local matchesObserved = GSVU4_IsClosePower(beforePower, state.lastObservedAfter)

        if beforePower and not matchesRequested and not matchesObserved then
            basePower = beforePower
            powerResetDetected = true
        end
    end

    basePower = math.max(1, tonumber(basePower) or scriptForce)
    local requestedPower = math.max(1, math.floor(basePower * massRatio * multiplier + 0.5))
    local effectiveMultiplier = requestedPower / basePower

    local baseMaxSpeed = tonumber(state.baseMaxSpeed)
    local maxResetDetected = false

    if not baseMaxSpeed or baseMaxSpeed <= 0 then
        baseMaxSpeed = beforeMaxSpeed or scriptMaxSpeed
    else
        local matchesRequested = GSVU4_IsCloseSpeed(beforeMaxSpeed, state.lastRequestedMaxSpeed)
        local matchesObserved = GSVU4_IsCloseSpeed(beforeMaxSpeed, state.lastObservedMaxSpeed)

        if beforeMaxSpeed and not matchesRequested and not matchesObserved then
            baseMaxSpeed = beforeMaxSpeed
            maxResetDetected = true
        end
    end

    baseMaxSpeed = math.max(0.1, tonumber(baseMaxSpeed) or tonumber(scriptMaxSpeed) or 100)
    local requestedMaxSpeed = baseMaxSpeed
    if operational then
        requestedMaxSpeed = math.max(0.1, baseMaxSpeed * effectiveMultiplier)
    end
    requestedMaxSpeed = math.floor(requestedMaxSpeed * 100 + 0.5) / 100

    local quality = GSVU4_ReadEngineQuality(vehicle)
    local powerWrite = not GSVU4_IsClosePower(beforePower, requestedPower)
    local engineFeatureWrite = powerWrite
    local maxWrite = not GSVU4_IsCloseSpeed(beforeMaxSpeed, requestedMaxSpeed)

    local engineApplied = false
    if engineFeatureWrite and vehicle.setEngineFeature then
        engineApplied = pcall(function()
            vehicle:setEngineFeature(quality, scriptLoudness, requestedPower)
        end)
    end

    if engineFeatureWrite and not engineApplied and vehicle.setEngineForce then
        engineApplied = pcall(function() vehicle:setEngineForce(requestedPower) end)
    end

    local maxApplied = false
    if maxWrite and vehicle.setMaxSpeed then
        maxApplied = pcall(function() vehicle:setMaxSpeed(requestedMaxSpeed) end)
    end

    local bulletRefreshed = false
    if forceBulletRefresh == true or engineFeatureWrite or maxWrite then
        bulletRefreshed = GSVU4_RefreshBullet(vehicle) == true
    end

    if engineApplied and vehicle.transmitEngine then
        pcall(function() vehicle:transmitEngine() end)
    end

    local afterPower = GSVU4_ReadEnginePower(vehicle)
    local afterMaxSpeed = GSVU4_ReadMaxSpeed(vehicle, script)

    state.version = GSVU4_POWER_RUNTIME_VERSION
    state.basePower = basePower
    state.baseMaxSpeed = baseMaxSpeed
    state.lastRequestedPower = requestedPower
    state.lastObservedAfter = afterPower
    state.lastRequestedMaxSpeed = requestedMaxSpeed
    state.lastObservedMaxSpeed = afterMaxSpeed

    vdata.gArmorBaseEnginePower = basePower
    vdata.gArmorBaseEngineForce = basePower
    vdata.gArmorBaseMaxSpeed = baseMaxSpeed


    state.wasOperational = operational == true

    if (engineFeatureWrite or maxWrite or migrated or powerResetDetected or maxResetDetected)
    and vehicle.transmitModData then
        pcall(function() vehicle:transmitModData() end)
    end

    return engineApplied == true or maxApplied == true or bulletRefreshed == true
end

----------------------------------------------------------
-- VehicleArmor_UpdateMass
-- Public so timed actions can call it after armour or upgrade changes.
----------------------------------------------------------
function VehicleArmor_UpdateMass(vehicle)
    if not vehicle or not vehicle.getModData or not vehicle.getScript then return end

    local vdata = vehicle:getModData()
    local script = vehicle:getScript()
    if not vdata or not script then return end

    local _, _, finalMass = GSVU4_GetMassState(vehicle, vdata, script)

    local okMass, currentMass = pcall(function()
        if vehicle.getMass then return vehicle:getMass() end
        return nil
    end)
    local massChanged = (not okMass) or not GSVU4_IsCloseValue(currentMass, finalMass, 0.1)

    if massChanged and vehicle.setMass then
        pcall(function() vehicle:setMass(finalMass) end)
    end

    VehicleArmor_UpdateEnginePower(vehicle, "mass-update", nil, massChanged)

    if vehicle.transmitModData then
        pcall(function() vehicle:transmitModData() end)
    end
end

----------------------------------------------------------
-- DRIVER CHECK
-- B42 does not always expose character:isDriver().
----------------------------------------------------------
local function VehicleArmor_IsVehicleDriver(character, vehicle)
    if not character or not vehicle then return false end

    if character.isDriver then
        local ok, result = pcall(function()
            return character:isDriver()
        end)

        if ok and result ~= nil then
            return result == true
        end
    end

    if vehicle.getDriver then
        local ok, driver = pcall(function()
            return vehicle:getDriver()
        end)

        if ok and driver then
            return driver == character
        end
    end

    return false
end

----------------------------------------------------------
-- SERVER-SIDE GAS TANK LEAK
-- Runs on the server for multiplayer consistency. The client
-- damage checker only sets vdata.gArmorGasLeak when GasTank
-- armour reaches 0 HP.
----------------------------------------------------------
local GAA_GasLeakTimers          = {}
local GAA_GAS_LEAK_INTERVAL      = 30
local GAA_GAS_LEAK_AMOUNT        = 0.31

local function GAA_GetVehicleKey(vehicle)
    if not vehicle then return nil end

    local uid
    if vehicle.getUniqueId then
        uid = tostring(vehicle:getUniqueId())
    elseif vehicle.getId then
        uid = tostring(vehicle:getId())
    else
        uid = "0"
    end

    return "veh_"
        .. math.floor(vehicle:getX()) .. "_"
        .. math.floor(vehicle:getY()) .. "_"
        .. uid
end

local function GAA_ClearGasLeakTimer(vehicle)
    local key = GAA_GetVehicleKey(vehicle)
    if key then
        GAA_GasLeakTimers[key] = nil
    end
end

local function GAA_GetGasTankPunctureDamageServer()
    if VehicleArmorConfig
    and VehicleArmorConfig.getGasTankPunctureDamage
    then
        return VehicleArmorConfig.getGasTankPunctureDamage()
    end

    return 20
end

local function GAA_GetVehiclePartByIdServerSafe(vehicle, partId)
    if not vehicle or not vehicle.getPartById then return nil end

    local ok, part = pcall(function()
        return vehicle:getPartById(partId)
    end)

    if ok then return part end
    return nil
end

local function GAA_ApplyGasTankPunctureDamageServer(vehicle, vdata)
    if not vehicle or not vdata then return false end

    -- Only apply this real GasTank damage once for a given leak.
    if vdata.gArmorGasLeakPunctureApplied then return false end

    local gasPart = GAA_GetVehiclePartByIdServerSafe(vehicle, "GasTank")
    if not gasPart then return false end
    if not gasPart.getCondition or not gasPart.setCondition then return false end

    local okCurrent, current = pcall(function()
        return gasPart:getCondition()
    end)

    if not okCurrent or current == nil then return false end

    local damage = GAA_GetGasTankPunctureDamageServer()
    if damage <= 0 then
        vdata.gArmorGasLeakPunctureApplied = true
        return false
    end

    local nextCondition = math.max(0, (tonumber(current) or 100) - damage)

    local okSet = pcall(function()
        gasPart:setCondition(nextCondition)
    end)

    if not okSet then return false end

    if vehicle.transmitPartCondition then
        pcall(function()
            vehicle:transmitPartCondition(gasPart)
        end)
    end

    vdata.gArmorGasLeakPunctureApplied = true
    return true
end

local function GAA_ClearGasLeakIfTankRestored(vehicle)
    -- Leak clearing is handled client-side in VehicleArmor_Damage.lua,
    -- where vanilla vehicle part condition can be read safely.
end

local function GAA_ProcessGasLeak(vehicle)
    if not vehicle then return end

    local vdata = vehicle:getModData()
    if not vdata or not vdata.gArmorGasLeak then
        GAA_ClearGasLeakTimer(vehicle)
        return
    end

    local key = GAA_GetVehicleKey(vehicle)
    if not key then return end

    GAA_GasLeakTimers[key] = (GAA_GasLeakTimers[key] or 0) + 1
    if GAA_GasLeakTimers[key] < GAA_GAS_LEAK_INTERVAL then return end
    GAA_GasLeakTimers[key] = 0

    local gasPart = vehicle:getPartById("GasTank")
    if not gasPart then return end

    local current = gasPart:getContainerContentAmount()
    if current and current > 0 then
        local mult = 1.0
        if VehicleArmorConfig and VehicleArmorConfig.getGasLeakRateMultiplier then
            mult = VehicleArmorConfig.getGasLeakRateMultiplier()
        end

        local amount = GAA_GAS_LEAK_AMOUNT * mult
        if amount <= 0 then return end

        gasPart:setContainerContentAmount(math.max(0, current - amount))

        if vehicle.transmitPartModData then
            vehicle:transmitPartModData(gasPart)
        end
        vehicle:transmitModData()
    end
end


----------------------------------------------------------
-- RANDOM SURVIVOR ARMOR
-- Server/SP authoritative.  Each vehicle is checked once,
-- then marked in modData so it cannot reroll every reload.
----------------------------------------------------------
-- V1.0.3 housekeeping:
-- Removed the old unused random-survivor OnPlayerUpdate proximity scanner.
-- Random survivor armor is seeded by OnEnterVehicle and TryRandomSurvivorArmor.
local function GAA_RandomArmorSafeString(obj, methodName)
    if not obj or not methodName or not obj[methodName] then return "" end
    local ok, result = pcall(function()
        return obj[methodName](obj)
    end)
    if ok and result then return tostring(result) end
    return ""
end

local function GAA_RandomArmorIsWreckedVehicle(vehicle)
    if not vehicle then return true end

    local names = table.concat({
        GAA_RandomArmorSafeString(vehicle, "getScriptName"),
        GAA_RandomArmorSafeString(vehicle, "getName"),
    }, " "):lower()

    local script = nil
    if vehicle.getScript then
        local ok, result = pcall(function() return vehicle:getScript() end)
        if ok then script = result end
    end

    if script then
        names = names .. " " .. GAA_RandomArmorSafeString(script, "getName"):lower()
        names = names .. " " .. GAA_RandomArmorSafeString(script, "getFullName"):lower()
    end

    if names:find("wreck")
    or names:find("burnt")
    or names:find("burned")
    or names:find("smashed")
    or names:find("destroyed")
    then
        return true
    end

    local boolMethods = { "isBurnt", "isBurned", "isDestroyed", "isSmashed" }
    for _, methodName in ipairs(boolMethods) do
        if vehicle[methodName] then
            local ok, result = pcall(function()
                return vehicle[methodName](vehicle)
            end)
            if ok and result == true then return true end
        end
    end

    return false
end

local function GAA_RandomArmorVehicleHasAnyArmor(vdata)
    if not vdata or not vdata.gArmor then return false end
    for _, armor in pairs(vdata.gArmor) do
        if armor then return true end
    end
    return false
end

local function GAA_RandomArmorGetCandidates(vehicle)
    local candidates = {}
    if not vehicle or not VehicleArmorConfig or not VehicleArmorConfig.isAllowedPart then return candidates end

    local added = {}
    local function addCandidate(partId)
        if not partId or added[partId] then return end
        if not VehicleArmorConfig.isAllowedPart(partId) then return end
        if not vehicle.getPartById then return end

        local ok, part = pcall(function()
            return vehicle:getPartById(partId)
        end)
        if ok and part then
            candidates[#candidates + 1] = partId
            added[partId] = true
        end
    end

    -- Prefer real part IDs from the vehicle script so modded vehicles
    -- get any compatible IDs they actually contain.
    local script = nil
    if vehicle.getScript then
        local ok, result = pcall(function() return vehicle:getScript() end)
        if ok then script = result end
    end

    if script and script.getPartCount and script.getPart then
        pcall(function()
            for i = 0, script:getPartCount() - 1 do
                local sp = script:getPart(i)
                if sp then
                    local id = nil
                    if sp.getPartId then
                        id = sp:getPartId()
                    elseif sp.getId then
                        id = sp:getId()
                    end
                    addCandidate(id)
                end
            end
        end)
    end

    -- Fallback to the shared allow-list.  This catches vehicles whose
    -- script part iterator is unavailable but getPartById works.
    if VehicleArmorConfig.AllowedParts then
        for partId, allowed in pairs(VehicleArmorConfig.AllowedParts) do
            if allowed then addCandidate(partId) end
        end
    end

    -- Final hood fallback if something strange prevented normal detection.
    if #candidates == 0 then
        addCandidate("EngineDoor")
        addCandidate("Hood")
    end

    return candidates
end

local function GAA_RandomArmorPickGrade()
    if not VehicleArmorConfig or not VehicleArmorConfig.getRandomSurvivorArmorChance then return nil end

    local passed = {}
    for _, grade in ipairs(VehicleArmorConfig.Grades or {}) do
        local chance = VehicleArmorConfig.getRandomSurvivorArmorChance(grade) or 0
        local roll = ZombRand(10000) / 100
        if chance > 0 and roll < chance then
            passed[#passed + 1] = grade
        end
    end

    if #passed == 0 then return nil end
    return passed[ZombRand(#passed) + 1]
end

local function GAA_RandomArmorPickHealth()
    local minHp, maxHp = 10, 65
    if VehicleArmorConfig and VehicleArmorConfig.getRandomSurvivorArmorHealthRange then
        minHp, maxHp = VehicleArmorConfig.getRandomSurvivorArmorHealthRange()
    end

    minHp = math.max(1, math.min(100, tonumber(minHp) or 10))
    maxHp = math.max(1, math.min(100, tonumber(maxHp) or 65))
    if minHp > maxHp then minHp, maxHp = maxHp, minHp end

    return ZombRand(minHp, maxHp + 1)
end

local function GAA_TrySeedRandomSurvivorArmor(vehicle)
    if not vehicle then return end
    if not VehicleArmorConfig or not VehicleArmorConfig.isRandomSurvivorArmorEnabled then return end
    if not VehicleArmorConfig.isRandomSurvivorArmorEnabled() then return end
    if GAA_RandomArmorIsWreckedVehicle(vehicle) then return end

    local vdata = vehicle:getModData()
    if not vdata then return end

    -- This marker is intentionally separate from gArmor so existing old
    -- saves can be checked once after the feature is enabled, without
    -- rerolling every time the vehicle streams in or a player walks past.
    if vdata.gArmorRandomSurvivorChecked then return end
    vdata.gArmorRandomSurvivorChecked = true

    -- Do not add random armor to vehicles that already have mod armor.
    if GAA_RandomArmorVehicleHasAnyArmor(vdata) then
        vehicle:transmitModData()
        return
    end

    local candidates = GAA_RandomArmorGetCandidates(vehicle)
    if #candidates == 0 then
        vehicle:transmitModData()
        return
    end

    local maxPanels = 1
    if VehicleArmorConfig.getRandomSurvivorArmorMaxPanels then
        maxPanels = VehicleArmorConfig.getRandomSurvivorArmorMaxPanels()
    end
    maxPanels = math.max(1, math.min(#candidates, tonumber(maxPanels) or 1))

    vdata.gArmor = vdata.gArmor or {}
    local installed = 0

    for _ = 1, maxPanels do
        if #candidates == 0 then break end

        -- Pick grade first, then choose only parts that can actually use that
        -- grade according to the normal install recipe rules. This prevents
        -- random survivor armor from creating invalid combinations such as
        -- Scrap/Apocalypse GasTank armor, because GasTank only has Standard
        -- and Reinforced recipes.
        local grade = GAA_RandomArmorPickGrade()
        if not grade then break end

        local gradeCandidates = {}
        for _, candidatePartId in ipairs(candidates) do
            if candidatePartId
            and not vdata.gArmor[candidatePartId]
            and VehicleArmorConfig.isGradeAllowedForPart
            and VehicleArmorConfig.isGradeAllowedForPart(candidatePartId, grade)
            then
                gradeCandidates[#gradeCandidates + 1] = candidatePartId
            end
        end

        if #gradeCandidates == 0 then
            -- This grade rolled successfully, but this vehicle has no valid
            -- parts for it. Try the next requested random panel without
            -- installing an invalid part/grade pair.
            break
        end

        local chosen = gradeCandidates[ZombRand(#gradeCandidates) + 1]
        local partId = chosen

        -- Remove the selected part from the master candidate list so multiple
        -- panels on the same vehicle cannot target the same part.
        for idx = #candidates, 1, -1 do
            if candidates[idx] == partId then
                table.remove(candidates, idx)
                break
            end
        end

        if partId and not vdata.gArmor[partId] then
            vdata.gArmor[partId] = {
                grade = grade,
                health = GAA_RandomArmorPickHealth(),
                survivorSpawned = true,
            }
            installed = installed + 1
        end
    end

    if installed > 0 then
        vehicle:transmitModData()
        VehicleArmor_UpdateMass(vehicle)
        if VehicleArmorConfig and VehicleArmorConfig.areAdminLogsEnabled and VehicleArmorConfig.areAdminLogsEnabled() then
        end
    else
        vehicle:transmitModData()
    end
end

local function GAA_OnPlayerUpdateServer(character)
    if not character then return end

    -- B42.19 safety note:
    -- Do not scan getCell():getVehicles() from OnPlayerUpdate. In some SP/MP
    -- contexts the vehicle collection can throw a Java/Kahlua RuntimeException
    -- while chunks are still settling after world load. Random survivor armor is
    -- now seeded by OnEnterVehicle and by explicit client requests for the
    -- interacted/near vehicle, both of which pass a concrete vehicle reference.

    local vehicle = nil
    if character.getVehicle then
        vehicle = character:getVehicle()
    end

    if vehicle and VehicleArmor_IsVehicleDriver(character, vehicle) then
        -- Random survivor armour is seeded on OnEnterVehicle where we already
        -- have a concrete vehicle reference. Do not repeat that check every
        -- player update.
        GAA_ProcessGasLeak(vehicle)
    end
end

Events.OnPlayerUpdate.Add(GAA_OnPlayerUpdateServer)

----------------------------------------------------------
-- Recalculate mass each time a driver enters a vehicle.
-- Catches vehicles that had armour applied in a previous
-- session before the server had a chance to recalculate.
----------------------------------------------------------
local function onEnterVehicle(character)
    if not character then return end

    local vehicle = nil
    if character.getVehicle then
        vehicle = character:getVehicle()
    end

    if vehicle and VehicleArmor_IsVehicleDriver(character, vehicle) then
        GAA_TrySeedRandomSurvivorArmor(vehicle)
        VehicleArmor_UpdateMass(vehicle)
    end
end

Events.OnEnterVehicle.Add(onEnterVehicle)


----------------------------------------------------------
-- SERVER-AUTHORITATIVE ARMOR STATE COMMANDS
-- Timed actions consume local materials/fuel/XP, then ask
-- the server to apply final vehicle modData and mass state.
----------------------------------------------------------
local function GAA_ServerVehicleValueMatches(vehicleValue, argValue)
    if argValue == nil or vehicleValue == nil then return false end
    return tostring(vehicleValue) == tostring(argValue)
end

local function GAA_ServerVehicleCoordsMatch(vehicle, args)
    if not vehicle or not args then return false end
    if args.vehicleX == nil or args.vehicleY == nil then return false end
    if not vehicle.getX or not vehicle.getY then return false end

    local okX, vx = pcall(function() return vehicle:getX() end)
    local okY, vy = pcall(function() return vehicle:getY() end)
    if not okX or not okY or vx == nil or vy == nil then return false end

    local dx = math.abs(tonumber(vx) - tonumber(args.vehicleX))
    local dy = math.abs(tonumber(vy) - tonumber(args.vehicleY))
    if dx > 2 or dy > 2 then return false end

    if args.vehicleZ ~= nil and vehicle.getZ then
        local okZ, vz = pcall(function() return vehicle:getZ() end)
        if okZ and vz ~= nil and math.abs(tonumber(vz) - tonumber(args.vehicleZ)) > 1 then
            return false
        end
    end

    return true
end

local function GAA_ServerVehicleMatchesArgs(vehicle, args)
    if not vehicle or not args then return false end

    if args.vehicleOnlineId ~= nil and vehicle.getOnlineID then
        local ok, value = pcall(function() return vehicle:getOnlineID() end)
        if ok and GAA_ServerVehicleValueMatches(value, args.vehicleOnlineId) then
            return true
        end
    end

    if args.vehicleId ~= nil and vehicle.getId then
        local ok, value = pcall(function() return vehicle:getId() end)
        if ok and GAA_ServerVehicleValueMatches(value, args.vehicleId) then
            return true
        end
    end

    return GAA_ServerVehicleCoordsMatch(vehicle, args)
end

local function GAA_ServerGetLoadedVehicles()
    if not getCell then return nil end
    local cell = getCell()
    if not cell or not cell.getVehicles then return nil end

    local ok, vehicles = pcall(function() return cell:getVehicles() end)
    if ok then return vehicles end
    return nil
end

local function GAA_ServerLooksLikeVehicle(obj)
    return obj ~= nil
       and obj.getX ~= nil
       and obj.getY ~= nil
       and obj.getModData ~= nil
       and obj.getPartById ~= nil
end

local function GAA_ServerTryVehicleCandidate(candidate, args)
    if GAA_ServerLooksLikeVehicle(candidate) and GAA_ServerVehicleMatchesArgs(candidate, args) then
        return candidate
    end
    return nil
end

local function GAA_ServerGetVehicleNearPlayer(player, args)
    if not player or not args then return nil end

    -- Best case: the player is already in the vehicle.
    if player.getVehicle then
        local ok, vehicle = pcall(function() return player:getVehicle() end)
        local match = ok and GAA_ServerTryVehicleCandidate(vehicle, args) or nil
        if match then return match end
    end

    -- Some contexts expose the nearest/interacted vehicle directly.
    if player.getNearVehicle then
        local ok, vehicle = pcall(function() return player:getNearVehicle() end)
        local match = ok and GAA_ServerTryVehicleCandidate(vehicle, args) or nil
        if match then return match end
    end

    -- Dedicated MP safety fallback:
    -- getCell():getVehicles() is not consistently iterable from Lua in B42.19.
    -- Scan only nearby squares around the player instead. This avoids the old
    -- "vehicle not found" false-positive when a vehicle exists near the player
    -- but the global vehicle collection cannot be walked safely.
    if not getCell or not player.getSquare then return nil end

    local okSq, playerSquare = pcall(function() return player:getSquare() end)
    if not okSq or not playerSquare then return nil end

    local cell = getCell()
    if not cell or not cell.getGridSquare then return nil end

    local sx, sy, sz = playerSquare:getX(), playerSquare:getY(), playerSquare:getZ()
    local radius = 8

    for x = sx - radius, sx + radius do
        for y = sy - radius, sy + radius do
            local okGrid, square = pcall(function() return cell:getGridSquare(x, y, sz) end)
            if okGrid and square and square.getMovingObjects then
                local okObjs, objects = pcall(function() return square:getMovingObjects() end)
                if okObjs and objects then
                    local okSize, size = pcall(function() return objects:size() end)
                    if okSize and tonumber(size) then
                        for i = 0, tonumber(size) - 1 do
                            local okObj, obj = pcall(function() return objects:get(i) end)
                            local match = okObj and GAA_ServerTryVehicleCandidate(obj, args) or nil
                            if match then return match end
                        end
                    end
                end
            end
        end
    end

    return nil
end

local function GAA_ServerGetVehicleFromArgs(args, player)
    if not args then return nil end

    -- Fallback for SP/listen/local contexts only. Dedicated MP cannot
    -- receive BaseVehicle objects through client command args.
    if args.vehicle and type(args.vehicle) ~= "table" then
        return args.vehicle
    end

    -- Prefer player-local resolution first. It is safer than iterating the
    -- global vehicle collection and matches armor actions, which require the
    -- player to be next to the vehicle anyway.
    local nearby = GAA_ServerGetVehicleNearPlayer(player, args)
    if nearby then return nearby end

    local vehicles = GAA_ServerGetLoadedVehicles()
    if not vehicles then return nil end

    local okCount, count = pcall(function()
        return vehicles:size()
    end)

    if okCount and tonumber(count) then
        if not vehicles.get then
            return nil
        end

        for i = 0, tonumber(count) - 1 do
            local okVehicle, vehicle = pcall(function()
                return vehicles:get(i)
            end)

            if okVehicle and vehicle and GAA_ServerVehicleMatchesArgs(vehicle, args) then
                return vehicle
            end
        end

        return nil
    end

    if type(vehicles) == "table" then
        for _, vehicle in ipairs(vehicles) do
            if GAA_ServerVehicleMatchesArgs(vehicle, args) then
                return vehicle
            end
        end
    end

    return nil
end

local function GAA_ServerAddVehicleCommandArgs(args, vehicle)
    args = args or {}
    if not vehicle then return args end

    if vehicle.getId then
        local ok, value = pcall(function() return vehicle:getId() end)
        if ok and value ~= nil then args.vehicleId = tonumber(value) or tostring(value) end
    end

    if vehicle.getOnlineID then
        local ok, value = pcall(function() return vehicle:getOnlineID() end)
        if ok and value ~= nil then args.vehicleOnlineId = tonumber(value) or tostring(value) end
    end

    if vehicle.getX then
        local ok, value = pcall(function() return vehicle:getX() end)
        if ok and value ~= nil then args.vehicleX = tonumber(value) end
    end

    if vehicle.getY then
        local ok, value = pcall(function() return vehicle:getY() end)
        if ok and value ~= nil then args.vehicleY = tonumber(value) end
    end

    if vehicle.getZ then
        local ok, value = pcall(function() return vehicle:getZ() end)
        if ok and value ~= nil then args.vehicleZ = tonumber(value) end
    end

    return args
end

local function GAA_ServerActorUsername(player)
    if player and player.getUsername then
        local ok, value = pcall(function() return player:getUsername() end)
        if ok and value then return tostring(value) end
    end
    return nil
end

local function GAA_ServerBroadcastCommand(fallbackPlayer, module, command, args)
    if not sendServerCommand then return end
    local sent = false
    if getOnlinePlayers then
        local okPlayers, players = pcall(getOnlinePlayers)
        if okPlayers and players and players.size and players.get then
            local okSize, count = pcall(function() return players:size() end)
            if okSize and count then
                for i = 0, count - 1 do
                    local okPlayer, target = pcall(function() return players:get(i) end)
                    if okPlayer and target then
                        pcall(function() sendServerCommand(target, module, command, args) end)
                        sent = true
                    end
                end
            end
        end
    end
    if not sent and fallbackPlayer then
        sendServerCommand(fallbackPlayer, module, command, args)
    end
end

local function GAA_ServerSendArmorApplied(player, vehicle, action, partId, armor)
    if not sendServerCommand then return end

    local args = {
        action = action,
        partId = partId,
    }

    if armor then
        args.grade = armor.grade
        args.health = armor.health
    end

    args.actorUsername = GAA_ServerActorUsername(player)
    GAA_ServerAddVehicleCommandArgs(args, vehicle)
    GAA_ServerBroadcastCommand(
        player,
        "GoresSVU4Core",
        "ArmorActionApplied",
        args
    )

    if GSVU4_ServerQueueVisualRefreshReady then
        GSVU4_ServerQueueVisualRefreshReady(
            player,
            vehicle,
            "armor:" .. tostring(partId)
        )
    end
end


local function GAA_ServerApplyVisualSafe(vehicle, partId)
    -- Visuals are client-side cosmetic; server does not need
    -- to toggle models here. Clients refresh from transmitted
    -- vehicle modData.
end

----------------------------------------------------------
-- SERVER / ADMIN ACTION LOGGING
----------------------------------------------------------
local function GAA_AdminLogsEnabled()
    if VehicleArmorConfig
    and VehicleArmorConfig.areAdminLogsEnabled
    then
        return VehicleArmorConfig.areAdminLogsEnabled()
    end

    return true
end

local function GAA_GetPlayerLogName(player)
    if not player then return "unknown player" end

    if player.getUsername then
        local ok, username = pcall(function()
            return player:getUsername()
        end)
        if ok and username and tostring(username) ~= "" then
            return tostring(username)
        end
    end

    if player.getDisplayName then
        local ok, name = pcall(function()
            return player:getDisplayName()
        end)
        if ok and name and tostring(name) ~= "" then
            return tostring(name)
        end
    end

    return tostring(player)
end

local function GAA_GetVehicleLogName(vehicle)
    if not vehicle then return "unknown vehicle" end

    local scriptName = nil

    if vehicle.getScriptName then
        local ok, value = pcall(function()
            return vehicle:getScriptName()
        end)
        if ok and value then scriptName = tostring(value) end
    end

    if not scriptName and vehicle.getScript then
        local ok, script = pcall(function()
            return vehicle:getScript()
        end)

        if ok and script then
            if script.getFullName then
                local okName, value = pcall(function()
                    return script:getFullName()
                end)
                if okName and value then scriptName = tostring(value) end
            elseif script.getName then
                local okName, value = pcall(function()
                    return script:getName()
                end)
                if okName and value then scriptName = tostring(value) end
            end
        end
    end

    scriptName = scriptName or "vehicle"

    local x, y = "?", "?"
    if vehicle.getX then
        local ok, value = pcall(function() return vehicle:getX() end)
        if ok and value then x = tostring(math.floor(value)) end
    end
    if vehicle.getY then
        local ok, value = pcall(function() return vehicle:getY() end)
        if ok and value then y = tostring(math.floor(value)) end
    end

    return scriptName .. " @ " .. x .. "," .. y
end

local function GAA_AdminLog(message)
    if not GAA_AdminLogsEnabled() then return end

    local text = "[GAA] " .. tostring(message or "")

    if writeLog then writeLog("GoresSVU4Core", text) end
end

local function GAA_AdminLogAction(player, action, vehicle, partId, grade, extra)
    local message = GAA_GetPlayerLogName(player)
        .. " "
        .. tostring(action or "updated")
        .. " "
        .. tostring(grade or "armor")
        .. " armor on "
        .. tostring(partId or "?")
        .. " ("
        .. GAA_GetVehicleLogName(vehicle)
        .. ")"

    if extra and tostring(extra) ~= "" then
        message = message .. " - " .. tostring(extra)
    end

    GAA_AdminLog(message)
end

local function GAA_IsVehicleNotFoundMessage(message)
    local text = tostring(message or ""):lower()
    return text == "vehicle not found" or text == "vehicle not found."
end

local function GAA_ServerReject(player, reason, silent)
    local message = tostring(reason or "Armor action rejected by server.")
    GAA_AdminLog("Rejected action for " .. GAA_GetPlayerLogName(player) .. ": " .. message)

    -- MP hybrid fallback:
    -- A late client-applied install/repair/uninstall command can sometimes
    -- arrive after the server can no longer resolve the vehicle object, even
    -- though the timed action already completed and modData/material changes
    -- were valid.  Keep the server/admin log, but do not show the old
    -- player-facing "Vehicle not found" warning because it is usually a
    -- false-positive in that path.
    if silent or GAA_IsVehicleNotFoundMessage(message) then
        return
    end

    if sendServerCommand then
        sendServerCommand(player, "GoresSVU4Core", "ArmorActionRejected", {
            message = message,
        })
    end

end


----------------------------------------------------------
-- SERVER-SIDE INVENTORY / MATERIAL HELPERS
-- Mirrors the client consume helpers so MP servers, not
-- clients, own final fuel/material consumption.
----------------------------------------------------------
local function GAA_NotNull(item)
    return item ~= nil and item.getType ~= nil
end

local function GAA_FindItem(inv, ...)
    if not inv then return nil end

    for _, fullType in ipairs({...}) do
        local item = inv:FindAndReturn(fullType)
        if GAA_NotNull(item) then return item end
    end

    return nil
end

local function GAA_GetItemFullType(item)
    if not item then return nil end

    if item.getFullType then
        local ok, ft = pcall(function()
            return item:getFullType()
        end)
        if ok and ft then return ft end
    end

    return nil
end


local function GAA_RemoveGroundItem(item)
    if not item then return false end

    if item.getWorldItem then
        local okWorld, worldItem = pcall(function()
            return item:getWorldItem()
        end)

        if okWorld and worldItem then
            local square = nil

            if worldItem.getSquare then
                local okSquare, foundSquare = pcall(function()
                    return worldItem:getSquare()
                end)
                if okSquare then square = foundSquare end
            end

            if square and square.transmitRemoveItemFromSquare then
                square:transmitRemoveItemFromSquare(worldItem)
                return true
            end

            if worldItem.removeFromWorld then
                worldItem:removeFromWorld()
                if worldItem.removeFromSquare then
                    worldItem:removeFromSquare()
                end
                return true
            end
        end
    end

    if item.removeFromWorld then
        item:removeFromWorld()
        if item.removeFromSquare then
            item:removeFromSquare()
        end
        return true
    end

    return false
end

----------------------------------------------------------
-- SERVER ACCESSIBLE INVENTORY SCOPE
-- Mirrors the client-side helper: main inventory, nested bags,
-- and nearby world containers within 1 tile.
----------------------------------------------------------
local function GAA_AddInventory(list, seen, inv)
    if not inv then return end

    local key = tostring(inv)
    if seen[key] then return end

    seen[key] = true
    table.insert(list, inv)

    if not inv.getItems then return end

    local okItems, items = pcall(function()
        return inv:getItems()
    end)

    if not okItems or not items then return end

    for i = 0, items:size() - 1 do
        local item = items:get(i)

        if item and item.getInventory then
            local okInv, childInv = pcall(function()
                return item:getInventory()
            end)

            if okInv and childInv then
                GAA_AddInventory(list, seen, childInv)
            end
        end
    end
end

local function GAA_AddSquareContainers(list, seen, square)
    if not square or not square.getObjects then return end

    local okObjects, objects = pcall(function()
        return square:getObjects()
    end)

    if not okObjects or not objects then return end

    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)

        if obj and obj.getContainer then
            local okContainer, container = pcall(function()
                return obj:getContainer()
            end)

            if okContainer and container then
                GAA_AddInventory(list, seen, container)
            end
        end
    end
end


local function GAA_AddGroundItems(items, seen, square)
    if not square then return end

    local function addFromList(list)
        if not list then return end

        for i = 0, list:size() - 1 do
            local obj = list:get(i)
            local item = nil

            if obj then
                if obj.getItem then
                    local okItem, found = pcall(function()
                        return obj:getItem()
                    end)
                    if okItem then item = found end
                elseif obj.getType then
                    item = obj
                end
            end

            if item and item.getType then
                local key = tostring(item)
                if not seen[key] then
                    seen[key] = true
                    table.insert(items, item)
                end
            end
        end
    end

    if square.getWorldObjects then
        local okWorld, worldObjects = pcall(function()
            return square:getWorldObjects()
        end)
        if okWorld then addFromList(worldObjects) end
    end

    if square.getStaticMovingObjects then
        local okMoving, movingObjects = pcall(function()
            return square:getStaticMovingObjects()
        end)
        if okMoving then addFromList(movingObjects) end
    end
end

local function GAA_GetAccessibleInventories(character)
    local list = {}
    local seen = {}

    if not character then return list end

    if character.getInventory then
        local okInv, inv = pcall(function()
            return character:getInventory()
        end)

        if okInv and inv then
            GAA_AddInventory(list, seen, inv)
        end
    end

    if character.getSquare and getCell then
        local okSquare, square = pcall(function()
            return character:getSquare()
        end)

        if okSquare and square then
            local z = square:getZ()
            local x = square:getX()
            local y = square:getY()

            for dx = -1, 1 do
                for dy = -1, 1 do
                    local near = getCell():getGridSquare(x + dx, y + dy, z)
                    GAA_AddSquareContainers(list, seen, near)
                end
            end
        end
    end

    return list
end


local function GAA_GetAccessibleGroundItems(character)
    local items = {}
    local seen = {}

    if not character or not character.getSquare or not getCell then
        return items
    end

    local okSquare, square = pcall(function()
        return character:getSquare()
    end)

    if not okSquare or not square then
        return items
    end

    local z = square:getZ()
    local x = square:getX()
    local y = square:getY()

    for dx = -1, 1 do
        for dy = -1, 1 do
            local near = getCell():getGridSquare(x + dx, y + dy, z)
            GAA_AddGroundItems(items, seen, near)
        end
    end

    return items
end

local function GAA_ForEachAccessibleItem(character, fn)
    local snapshot = {}
    local inventories = GAA_GetAccessibleInventories(character)

    -- Snapshot first. Some callbacks consume/remove items, which mutates
    -- the Java item list and can otherwise cause index errors.
    for _, inv in ipairs(inventories) do
        if inv and inv.getItems then
            local items = inv:getItems()
            if items then
                for i = 0, items:size() - 1 do
                    local item = items:get(i)
                    if item then
                        table.insert(snapshot, {item=item, inv=inv})
                    end
                end
            end
        end
    end

    if GAA_GetAccessibleGroundItems then
        for _, item in ipairs(GAA_GetAccessibleGroundItems(character)) do
            table.insert(snapshot, {item=item, inv=nil})
        end
    end

    for _, entry in ipairs(snapshot) do
        if entry and entry.item then
            fn(entry.item, entry.inv)
        end
    end
end

local GAA_SHEET_VALUES = {
    SheetMetal      = 1.00,
    SteelSheet      = 1.00,
    SmallSheetMetal = 0.25,
}

local GAA_BAR_VALUES = {
    MetalBar         = 1.00,
    SteelBar         = 1.00,
    IronBar          = 1.00,
    SteelBarHalf     = 0.50,
    IronBarHalf      = 0.50,
    SteelBarQuarter  = 0.25,
    IronBarQuarter   = 0.25,
}

local function GAA_GetRodAmount(item)
    if not item then return 0 end

    if item.getModData then
        local md = item:getModData()
        if md then
            if md.GAA_RodAmount == nil then
                md.GAA_RodAmount = 1.0
            end

            local amount = tonumber(md.GAA_RodAmount) or 0
            if amount > 0 then
                return amount
            end
        end
    end

    if item.getUsedDelta then
        local okDelta, delta = pcall(function()
            return item:getUsedDelta()
        end)

        if okDelta and delta and delta > 0 then
            return delta
        end
    end

    return 1.0
end

local function GAA_SetRodAmount(inv, item, amount)
    if not inv or not item then return end

    local remaining = tonumber(amount) or 0

    if remaining > 0.0001 then
        if item.getModData then
            local md = item:getModData()
            if md then
                md.GAA_RodAmount = remaining
                return
            end
        end

        if item.setUsedDelta then
            local okSet = pcall(function()
                item:setUsedDelta(remaining)
            end)

            if okSet then return end
        end

        return
    end

    inv:Remove(item)
end

local function GAA_CountMaterials(inv)
    local report = {
        scrap  = 0,
        sheets = 0,
        bars   = 0,
        screws = 0,
        wire   = 0,
        electricWire = 0,
        bulbs = 0,
        autoTuneMilitaryRadio = 0,
        rods   = 0,
    }

    if not inv then return report end

    local items = inv:getItems()
    if not items then return report end

    for i = 0, items:size() - 1 do
        local item = items:get(i)

        if item then
            local t  = item.getType and item:getType() or nil
            local ft = GAA_GetItemFullType(item)

            if t == "ScrapMetal" then
                report.scrap = report.scrap + 1
            elseif t == "Screws" then
                report.screws = report.screws + 1
            elseif t == "Wire" or ft == "Base.Wire" then
                report.wire = report.wire + 1
            elseif t == "ElectricWire" or ft == "Base.ElectricWire" then
                report.electricWire = (report.electricWire or 0) + 1
            elseif t == "LightBulb" or ft == "Base.LightBulb" then
                report.bulbs = (report.bulbs or 0) + 1
            elseif t == "GSVU4AutoTuneMilitaryRadio" or ft == "Base.GSVU4AutoTuneMilitaryRadio" then
                report.autoTuneMilitaryRadio = (report.autoTuneMilitaryRadio or 0) + 1
            elseif t == "WeldingRods" or ft == "Base.WeldingRods" then
                report.rods = report.rods + GAA_GetRodAmount(item)
            end

            if GAA_SHEET_VALUES[t] then
                report.sheets = report.sheets + GAA_SHEET_VALUES[t]
            end

            if GAA_BAR_VALUES[t] then
                report.bars = report.bars + GAA_BAR_VALUES[t]
            end
        end
    end

    return report
end


local function GAA_CountMaterialsForCharacter(character)
    local report = {
        scrap  = 0,
        sheets = 0,
        bars   = 0,
        screws = 0,
        wire   = 0,
        electricWire = 0,
        bulbs = 0,
        autoTuneMilitaryRadio = 0,
        rods   = 0,
    }

    GAA_ForEachAccessibleItem(character, function(item)
        local t  = item.getType and item:getType() or nil
        local ft = GAA_GetItemFullType(item)

        if t == "ScrapMetal" then
            report.scrap = report.scrap + 1
        elseif t == "Screws" then
            report.screws = report.screws + 1
        elseif t == "Wire" or ft == "Base.Wire" then
            report.wire = report.wire + 1
        elseif t == "ElectricWire" or ft == "Base.ElectricWire" then
            report.electricWire = (report.electricWire or 0) + 1
        elseif t == "LightBulb" or ft == "Base.LightBulb" then
            report.bulbs = (report.bulbs or 0) + 1
        elseif t == "GSVU4AutoTuneMilitaryRadio" or ft == "Base.GSVU4AutoTuneMilitaryRadio" then
            report.autoTuneMilitaryRadio = (report.autoTuneMilitaryRadio or 0) + 1
        elseif t == "WeldingRods" or ft == "Base.WeldingRods" then
            report.rods = report.rods + GAA_GetRodAmount(item)
        end

        if GAA_SHEET_VALUES[t] then
            report.sheets = report.sheets + GAA_SHEET_VALUES[t]
        end

        if GAA_BAR_VALUES[t] then
            report.bars = report.bars + GAA_BAR_VALUES[t]
        end
    end)

    return report
end


local function GAA_GetAdjustedRecipe(recipe)
    if not recipe then return recipe end

    local mult = 1.0
    if VehicleArmorConfig and VehicleArmorConfig.getMaterialCostMultiplier then
        mult = VehicleArmorConfig.getMaterialCostMultiplier()
    end

    local adjusted = {}

    for mat, req in pairs(recipe) do
        local value = tonumber(req) or 0

        if value <= 0 then
            adjusted[mat] = 0
        elseif mat == "autoTuneMilitaryRadio" then
            adjusted[mat] = math.max(1, math.ceil(value))
        elseif mat == "rods" then
            adjusted[mat] = math.max(0.01, math.floor((value * mult * 100) + 0.5) / 100)
        else
            adjusted[mat] = math.max(1, math.ceil(value * mult))
        end
    end

    return adjusted
end

local function GAA_HasRecipe(inv, recipe)
    if not recipe then return true end

    local have = GAA_CountMaterials(inv)
    local adjusted = GAA_GetAdjustedRecipe(recipe)

    for mat, req in pairs(adjusted) do
        if (have[mat] or 0) + 0.0001 < (req or 0) then
            return false
        end
    end

    return true
end


local function GAA_HasRecipeForCharacter(character, recipe)
    if not recipe then return true end

    local have = GAA_CountMaterialsForCharacter(character)
    local adjusted = GAA_GetAdjustedRecipe(recipe)

    for mat, req in pairs(adjusted) do
        if (have[mat] or 0) + 0.0001 < (req or 0) then
            return false
        end
    end

    return true
end


local function GAA_IsHammerItem(item)
    if not item then return false end

    local t  = item.getType and item:getType() or ""
    local ft = GAA_GetItemFullType(item) or ""

    return t == "Hammer"
        or t == "BallPeenHammer"
        or ft == "Base.Hammer"
        or ft == "Base.BallPeenHammer"
        or string.find(t, "Hammer") ~= nil
        or string.find(ft, "Hammer") ~= nil
end


local function GAA_IsScrewdriverItemForArmor(item)
    if not item then return false end
    local t  = item.getType and item:getType() or ""
    local ft = GAA_GetItemFullType(item) or ""
    local lowT = string.lower(tostring(t))
    local lowFt = string.lower(tostring(ft))
    return lowT == "screwdriver"
        or lowFt == "base.screwdriver"
        or string.find(lowT, "screwdriver", 1, true) ~= nil
        or string.find(lowFt, "screwdriver", 1, true) ~= nil
end

local function GAA_GetArmorToolRequirements(grade)
    if tostring(grade or "") == "Scrap" then
        return { hammer = true, screwdriver = true, weldingMask = false, blowTorch = false }
    end
    return { hammer = true, screwdriver = false, weldingMask = true, blowTorch = true }
end

local function GAA_HasRequiredTools(character, grade)
    local hasMask = false
    local hasHammer = false
    local hasScrewdriver = false
    local req = GAA_GetArmorToolRequirements(grade)

    GAA_ForEachAccessibleItem(character, function(item)
        local t  = item.getType and item:getType() or ""
        local ft = GAA_GetItemFullType(item) or ""

        if t == "WeldingMask" or ft == "Base.WeldingMask" then
            hasMask = true
        end

        if GAA_IsHammerItem(item) then
            hasHammer = true
        end

        if GAA_IsScrewdriverItemForArmor(item) then
            hasScrewdriver = true
        end
    end)

    if req.hammer and not hasHammer then return false end
    if req.screwdriver and not hasScrewdriver then return false end
    if req.weldingMask and not hasMask then return false end
    return true
end

local function GAA_GetTorchFuel(item)
    if not item then return 0 end
    if not item.getCurrentUses then return 0 end

    local ok, uses = pcall(function()
        return item:getCurrentUses()
    end)

    if ok and uses and uses > 0 then
        return uses
    end

    return 0
end

local function GAA_FindTorch(character)
    if not character then return nil end

    local best, bestAmt = nil, 0

    GAA_ForEachAccessibleItem(character, function(item)
        local t  = item.getType and item:getType() or nil
        local ft = GAA_GetItemFullType(item)

        if t == "BlowTorch" or ft == "Base.BlowTorch" then
            local amt = GAA_GetTorchFuel(item)
            if amt > bestAmt then
                best    = item
                bestAmt = amt
            end
        end
    end)

    return best
end

local function GAA_ConsumeTorchFuel(item, amount)
    if not item or not item.Use then return end

    local useCount = math.floor((amount or 0) + 0.5)
    if useCount <= 0 then return end

    for _ = 1, useCount do
        if GAA_GetTorchFuel(item) <= 0 then break end
        item:Use()
    end
end

local function GAA_GetTotalTorchFuel(character)
    if not character then return 0 end
    local total = 0

    GAA_ForEachAccessibleItem(character, function(item)
        local t  = item.getType and item:getType() or nil
        local ft = GAA_GetItemFullType(item)

        if t == "BlowTorch" or ft == "Base.BlowTorch" then
            total = total + (GAA_GetTorchFuel(item) or 0)
        end
    end)

    return total
end

local function GAA_ConsumeTorchFuelFromCharacter(character, amount)
    local remaining = tonumber(amount) or 0
    if not character or remaining <= 0 then return 0 end
    local consumed = 0

    while remaining > 0.0001 do
        local torch = GAA_FindTorch(character)
        if not torch or (GAA_GetTorchFuel(torch) or 0) <= 0 then
            break
        end

        GAA_ConsumeTorchFuel(torch, 1)
        remaining = remaining - 1
        consumed = consumed + 1
    end

    return consumed
end

local function GAA_ConsumeSheets(inv, needed)
    local remaining = tonumber(needed) or 0

    while remaining > 0.0001 do
        local full = GAA_FindItem(inv, "Base.SheetMetal", "Base.SteelSheet")
        if full then
            inv:Remove(full)
            remaining = remaining - 1
        else
            local small = GAA_FindItem(inv, "Base.SmallSheetMetal")
            if small then
                inv:Remove(small)
                remaining = remaining - 0.25
            else
                break
            end
        end
    end
end

local function GAA_ConsumeBars(inv, needed)
    local remaining = tonumber(needed) or 0

    while remaining > 0.0001 do
        local full = GAA_FindItem(inv, "Base.MetalBar", "Base.SteelBar", "Base.IronBar")
        if full then
            inv:Remove(full)
            remaining = remaining - 1
        else
            local half = GAA_FindItem(inv, "Base.SteelBarHalf", "Base.IronBarHalf")
            if half then
                inv:Remove(half)
                remaining = remaining - 0.5
            else
                local qtr = GAA_FindItem(inv, "Base.SteelBarQuarter", "Base.IronBarQuarter")
                if qtr then
                    inv:Remove(qtr)
                    remaining = remaining - 0.25
                else
                    break
                end
            end
        end
    end
end

local function GAA_ConsumeWhole(inv, fullType, needed)
    local remaining = math.ceil(tonumber(needed) or 0)

    while remaining > 0 do
        local item = inv:FindAndReturn(fullType)
        if not GAA_NotNull(item) then break end

        inv:Remove(item)
        remaining = remaining - 1
    end
end

local function GAA_ConsumeRods(inv, needed)
    local remaining = tonumber(needed) or 0
    if remaining <= 0 then return end

    while remaining > 0.0001 do
        local rods = GAA_FindItem(inv, "Base.WeldingRods")
        if not rods then break end

        local available = GAA_GetRodAmount(rods)

        if available <= 0.0001 then
            inv:Remove(rods)
        else
            local take = math.min(available, remaining)
            GAA_SetRodAmount(inv, rods, available - take)
            remaining = remaining - take
        end
    end
end

local function GAA_ConsumeRecipe(inv, recipe)
    if not inv or not recipe then return end

    local adjusted = GAA_GetAdjustedRecipe(recipe)

    for mat, req in pairs(adjusted) do
        if mat == "rods" then
            GAA_ConsumeRods(inv, req)
        elseif mat == "sheets" then
            GAA_ConsumeSheets(inv, req)
        elseif mat == "bars" then
            GAA_ConsumeBars(inv, req)
        elseif mat == "scrap" then
            GAA_ConsumeWhole(inv, "Base.ScrapMetal", req)
        elseif mat == "screws" then
            GAA_ConsumeWhole(inv, "Base.Screws", req)
        elseif mat == "wire" then
            GAA_ConsumeWhole(inv, "Base.Wire", req)
        elseif mat == "electricWire" then
            GAA_ConsumeWhole(inv, "Base.ElectricWire", req)
        elseif mat == "bulbs" then
            GAA_ConsumeWhole(inv, "Base.LightBulb", req)
        elseif mat == "autoTuneMilitaryRadio" then
            GAA_ConsumeWhole(inv, "Base.GSVU4AutoTuneMilitaryRadio", req)
        end
    end
end


-- The ground-capable resource consumer below is authoritative.

local function GAA_ConsumeGroundCapableWhole(character, fullType, needed)
    local remaining = math.ceil(tonumber(needed) or 0)

    GAA_ForEachAccessibleItem(character, function(item, inv)
        if remaining <= 0 then return end

        local ft = GAA_GetItemFullType(item)
        if ft == fullType then
            if inv then inv:Remove(item) else GAA_RemoveGroundItem(item) end
            remaining = remaining - 1
        end
    end)
end

local function GAA_ConsumeGroundCapableRods(character, needed)
    local remaining = tonumber(needed) or 0

    GAA_ForEachAccessibleItem(character, function(item, inv)
        if remaining <= 0.0001 then return end

        local t = item.getType and item:getType() or nil
        local ft = GAA_GetItemFullType(item)

        if t == "WeldingRods" or ft == "Base.WeldingRods" then
            local available = GAA_GetRodAmount(item)
            local take = math.min(available, remaining)
            local left = available - take

            if left > 0.0001 then
                local md = item.getModData and item:getModData() or nil
                if md then md.GAA_RodAmount = left end
            else
                if inv then inv:Remove(item) else GAA_RemoveGroundItem(item) end
            end

            remaining = remaining - take
        end
    end)
end

local function GAA_ConsumeGroundCapableSheets(character, needed)
    local remaining = tonumber(needed) or 0

    GAA_ForEachAccessibleItem(character, function(item, inv)
        if remaining <= 0.0001 then return end

        local t = item.getType and item:getType() or nil
        local value = GAA_SHEET_VALUES[t]

        if value then
            if inv then inv:Remove(item) else GAA_RemoveGroundItem(item) end
            remaining = remaining - value
        end
    end)
end

local function GAA_ConsumeGroundCapableBars(character, needed)
    local remaining = tonumber(needed) or 0

    GAA_ForEachAccessibleItem(character, function(item, inv)
        if remaining <= 0.0001 then return end

        local t = item.getType and item:getType() or nil
        local value = GAA_BAR_VALUES[t]

        if value then
            if inv then inv:Remove(item) else GAA_RemoveGroundItem(item) end
            remaining = remaining - value
        end
    end)
end

local function GAA_ConsumeRecipeForCharacter(character, recipe)
    if not character or not recipe then return end

    local adjusted = GAA_GetAdjustedRecipe(recipe)

    for mat, req in pairs(adjusted) do
        if mat == "rods" then
            GAA_ConsumeGroundCapableRods(character, req)
        elseif mat == "sheets" then
            GAA_ConsumeGroundCapableSheets(character, req)
        elseif mat == "bars" then
            GAA_ConsumeGroundCapableBars(character, req)
        elseif mat == "scrap" then
            GAA_ConsumeGroundCapableWhole(character, "Base.ScrapMetal", req)
        elseif mat == "screws" then
            GAA_ConsumeGroundCapableWhole(character, "Base.Screws", req)
        elseif mat == "wire" then
            GAA_ConsumeGroundCapableWhole(character, "Base.Wire", req)
        elseif mat == "electricWire" then
            GAA_ConsumeGroundCapableWhole(character, "Base.ElectricWire", req)
        elseif mat == "bulbs" then
            GAA_ConsumeGroundCapableWhole(character, "Base.LightBulb", req)
        elseif mat == "autoTuneMilitaryRadio" then
            GAA_ConsumeGroundCapableWhole(character, "Base.GSVU4AutoTuneMilitaryRadio", req)
        end
    end
end


local function GAA_ServerHasFuelAndMaterials(player, recipe, fuelUse, needsTools, grade)
    if not player then return false end

    if needsTools and not GAA_HasRequiredTools(player, grade) then
        return false
    end

    if recipe and not GAA_HasRecipeForCharacter(player, recipe) then
        return false
    end

    local needFuel = tonumber(fuelUse) or 0
    local totalFuel = GAA_GetTotalTorchFuel(player)
    if needFuel > 0 and totalFuel < needFuel then
        return false
    end

    return true
end

local function GAA_ServerBoolText(value)
    return value and "yes" or "no"
end

local function GAA_ServerGetToolReport(player, grade)
    local req = GAA_GetArmorToolRequirements(grade)
    local hasMask = false
    local hasHammer = false
    local hasScrewdriver = false

    GAA_ForEachAccessibleItem(player, function(item)
        local t  = item.getType and item:getType() or ""
        local ft = GAA_GetItemFullType(item) or ""

        if t == "WeldingMask" or ft == "Base.WeldingMask" then hasMask = true end
        if GAA_IsHammerItem(item) then hasHammer = true end
        if GAA_IsScrewdriverItemForArmor(item) then hasScrewdriver = true end
    end)

    return {
        reqHammer = req.hammer == true,
        reqScrewdriver = req.screwdriver == true,
        reqMask = req.weldingMask == true,
        reqTorch = req.blowTorch == true,
        hasHammer = hasHammer,
        hasScrewdriver = hasScrewdriver,
        hasMask = hasMask,
    }
end

local function GAA_ServerBuildRequirementReport(player, recipe, fuelUse, needsTools, grade)
    local parts = {}
    local adjusted = GAA_GetAdjustedRecipe(recipe or {})
    local have = GAA_CountMaterialsForCharacter(player)
    local tools = GAA_ServerGetToolReport(player, grade)
    local needFuel = tonumber(fuelUse) or 0
    local totalFuel = GAA_GetTotalTorchFuel(player)

    table.insert(parts, "grade=" .. tostring(grade))
    table.insert(parts, "fuel=" .. tostring(totalFuel) .. "/" .. tostring(needFuel))

    if needsTools then
        table.insert(parts, "hammer=" .. GAA_ServerBoolText(tools.hasHammer) .. "/" .. GAA_ServerBoolText(tools.reqHammer))
        table.insert(parts, "screwdriver=" .. GAA_ServerBoolText(tools.hasScrewdriver) .. "/" .. GAA_ServerBoolText(tools.reqScrewdriver))
        table.insert(parts, "mask=" .. GAA_ServerBoolText(tools.hasMask) .. "/" .. GAA_ServerBoolText(tools.reqMask))
    end

    local keys = { "scrap", "sheets", "bars", "screws", "wire", "electricWire", "bulbs", "autoTuneMilitaryRadio", "rods" }
    for _, key in ipairs(keys) do
        local need = adjusted and adjusted[key] or 0
        if need and need > 0 then
            table.insert(parts, tostring(key) .. "=" .. tostring(have[key] or 0) .. "/" .. tostring(need))
        end
    end

    return table.concat(parts, " ")
end

local function GAA_ServerConsumeFuelAndMaterials(player, recipe, fuelUse, needsTools, grade)
    if not GAA_ServerHasFuelAndMaterials(player, recipe, fuelUse, needsTools, grade) then
        return false
    end

    local needFuel = tonumber(fuelUse) or 0
    if needFuel > 0 then
        GAA_ConsumeTorchFuelFromCharacter(player, needFuel)
    end
    GAA_ConsumeRecipeForCharacter(player, recipe)

    return true
end

local function GAA_ServerGiveUninstallReturns(player, returns)
    if not player or not returns then return end

    local inv = player:getInventory()
    if not inv then return end

    for mat, qty in pairs(returns) do
        for _ = 1, qty do
            if     mat == "scrap"  then inv:AddItem("Base.ScrapMetal")
            elseif mat == "sheets" then inv:AddItem("Base.SheetMetal")
            elseif mat == "bars"   then inv:AddItem("Base.MetalBar")
            elseif mat == "screws" then inv:AddItem("Base.Screws")
            elseif mat == "wire"   then inv:AddItem("Base.Wire")
            elseif mat == "electricWire" then inv:AddItem("Base.ElectricWire")
            elseif mat == "bulbs" then inv:AddItem("Base.LightBulb")
            end
        end
    end
end

----------------------------------------------------------
-- SERVER-SIDE SKILL REQUIREMENT HELPERS
----------------------------------------------------------
local function GAA_GetPerkLevel(character, perk)
    if not character or not perk then return 0 end
    if not character.getPerkLevel then return 0 end

    local ok, level = pcall(function()
        return character:getPerkLevel(perk)
    end)

    if ok and level then
        return level
    end

    return 0
end

local function GAA_ServerHasSkillRequirements(player, grade)
    if VehicleArmorConfig
    and VehicleArmorConfig.areSkillRequirementsEnabled
    and not VehicleArmorConfig.areSkillRequirementsEnabled()
    then
        return true
    end

    local reqs = VehicleArmorConfig.LevelRequirements
        and VehicleArmorConfig.LevelRequirements[grade]

    if not reqs then
        return true
    end

    local metalRequired = reqs.MetalWelding or 0
    local mechRequired  = reqs.Mechanics or 0

    local metalLevel = 0
    local mechLevel  = 0

    if Perks and Perks.MetalWelding then
        metalLevel = GAA_GetPerkLevel(player, Perks.MetalWelding)
    end

    if Perks and Perks.Mechanics then
        mechLevel = GAA_GetPerkLevel(player, Perks.Mechanics)
    end

    return metalLevel >= metalRequired
       and mechLevel >= mechRequired
end

----------------------------------------------------------
-- SERVER-SIDE ARMOR ACTION VALIDATION
----------------------------------------------------------
local GAA_MAX_ACTION_DISTANCE = 8

local function GAA_ServerIsPlayerNearVehicle(player, vehicle)
    if not player or not vehicle then return false end
    if not player.getX or not vehicle.getX then return false end

    local dx = player:getX() - vehicle:getX()
    local dy = player:getY() - vehicle:getY()
    local distSq = (dx * dx) + (dy * dy)

    return distSq <= (GAA_MAX_ACTION_DISTANCE * GAA_MAX_ACTION_DISTANCE)
end

local function GAA_ServerHasVehiclePart(vehicle, partId)
    return vehicle
       and partId
       and vehicle.getPartById
       and vehicle:getPartById(partId) ~= nil
end

local function GAA_ServerValidateCommon(player, vehicle, partId)
    if not vehicle then return false, "Vehicle not found." end
    if not partId then return false, "Armor part not selected." end
    if not GAA_ServerHasVehiclePart(vehicle, partId) then
        return false, "Vehicle part not found."
    end
    if not GAA_ServerIsPlayerNearVehicle(player, vehicle) then
        return false, "Too far from vehicle."
    end

    return true
end


local function GAA_ServerValidateKI5Compat(vehicle, partId, action)
    if not vehicle or not partId then return true, nil end
    if GSVU4_KI5Compat and GSVU4_KI5Compat.isBlocked then
        local blocked, _ = GSVU4_KI5Compat.isBlocked(vehicle, partId)
        if blocked then
            local reason = GSVU4_KI5Compat.getBlockedReason and GSVU4_KI5Compat.getBlockedReason(vehicle, partId, action)
            return false, reason or "Blocked by KI5 native armour compatibility mode."
        end
    end
    return true, nil
end

local function GAA_ServerValidatePZKCompat(vehicle, partId, action)
    if not vehicle or not partId then return true, nil end
    if GSVU4_PZKCompat and GSVU4_PZKCompat.isArmorBlocked then
        local blocked, _ = GSVU4_PZKCompat.isArmorBlocked(vehicle, partId)
        if blocked then
            local reason = GSVU4_PZKCompat.getArmorBlockedReason and GSVU4_PZKCompat.getArmorBlockedReason(vehicle, partId, action)
            return false, reason or "Blocked by PZK/SVU3 armour compatibility mode."
        end
    end
    return true, nil
end

local function GAA_ServerValidatePZKUpgradeCompat(vehicle, upgradeId, action)
    if not vehicle or not upgradeId then return true, nil end
    if GSVU4_PZKCompat and GSVU4_PZKCompat.isUpgradeBlocked then
        local blocked, _ = GSVU4_PZKCompat.isUpgradeBlocked(vehicle, upgradeId)
        if blocked then
            local reason = GSVU4_PZKCompat.getUpgradeBlockedReason and GSVU4_PZKCompat.getUpgradeBlockedReason(vehicle, upgradeId, action)
            return false, reason or "Blocked by PZK/SVU3 upgrade compatibility mode."
        end
    end
    return true, nil
end

local function GAA_ServerValidateInstall(player, vehicle, partId, grade)
    local ok, reason = GAA_ServerValidateCommon(player, vehicle, partId)
    if not ok then return false, reason end

    if GSVU4_KI5FullBlock and GSVU4_KI5FullBlock.IsBlocked and GSVU4_KI5FullBlock.IsBlocked(vehicle) then
        local msg = GSVU4_KI5FullBlock.GetBlockedMessage and GSVU4_KI5FullBlock.GetBlockedMessage(vehicle)
        return false, msg or "SVU4 armor disabled for KI5 vehicles."
    end

    local compatOk, compatReason = GAA_ServerValidateKI5Compat(vehicle, partId, "install")
    if not compatOk then return false, compatReason end

    local pzkOk, pzkReason = GAA_ServerValidatePZKCompat(vehicle, partId, "install")
    if not pzkOk then return false, pzkReason end

    if not grade then return false, "Armor grade not selected." end
    if not VehicleArmorConfig.getInstallRecipe(partId, grade) then
        return false, "This armor grade is not valid for this part."
    end
    if not GAA_ServerHasSkillRequirements(player, grade) then
        return false, "Insufficient skill requirements."
    end

    local vdata = vehicle:getModData()
    if vdata.gArmor and vdata.gArmor[partId] then
        return false, "Armor is already installed on this part."
    end

    return true
end

local function GAA_ServerValidateRepair(player, vehicle, partId)
    local ok, reason = GAA_ServerValidateCommon(player, vehicle, partId)
    if not ok then return false, reason end

    local compatOk, compatReason = GAA_ServerValidateKI5Compat(vehicle, partId, "repair")
    if not compatOk then return false, compatReason end

    local pzkOk, pzkReason = GAA_ServerValidatePZKCompat(vehicle, partId, "repair")
    if not pzkOk then return false, pzkReason end

    local vdata = vehicle:getModData()
    if not vdata.gArmor or not vdata.gArmor[partId] then
        return false, "No armor installed on this part."
    end

    local armor = vdata.gArmor[partId]
    if not armor or not armor.grade then
        return false, "Armor data is invalid."
    end
    if (armor.health or 100) >= 100 then
        return false, "Armor is already fully repaired."
    end
    if not VehicleArmorConfig.getRepairRecipe(partId, armor.grade) then
        return false, "This armor cannot be repaired."
    end

    return true
end

local function GAA_ServerValidateUninstall(player, vehicle, partId)
    local ok, reason = GAA_ServerValidateCommon(player, vehicle, partId)
    if not ok then return false, reason end

    local compatOk, compatReason = GAA_ServerValidateKI5Compat(vehicle, partId, "uninstall")
    if not compatOk then return false, compatReason end

    local pzkOk, pzkReason = GAA_ServerValidatePZKCompat(vehicle, partId, "uninstall")
    if not pzkOk then return false, pzkReason end

    local vdata = vehicle:getModData()
    if not vdata.gArmor or not vdata.gArmor[partId] then
        return false, "No armor installed on this part."
    end

    return true
end

----------------------------------------------------------
-- SERVER-SIDE ARMOR ACTION LOCKS
-- Prevents multiple players from modifying the same armor
-- part at the same time in multiplayer.
----------------------------------------------------------
local GAA_LOCK_TIMEOUT_SECONDS = 300
local GAA_ActiveArmorLocks = {}

local function GAA_GetPlayerKey(player)
    if not player then return "unknown" end

    if player.getUsername then
        local ok, username = pcall(function()
            return player:getUsername()
        end)
        if ok and username then
            return tostring(username)
        end
    end

    if player.getDisplayName then
        local ok, name = pcall(function()
            return player:getDisplayName()
        end)
        if ok and name then
            return tostring(name)
        end
    end

    return tostring(player)
end

local function GAA_IndexArmorLock(owner, vehicle, partId)
    if not owner or not vehicle or not partId then return end

    GAA_ActiveArmorLocks[owner] = GAA_ActiveArmorLocks[owner] or {}

    table.insert(GAA_ActiveArmorLocks[owner], {
        vehicle = vehicle,
        partId  = partId,
    })
end

local function GAA_UnindexArmorLock(owner, vehicle, partId)
    if not owner or not GAA_ActiveArmorLocks[owner] then return end

    local list = GAA_ActiveArmorLocks[owner]

    for i = #list, 1, -1 do
        local entry = list[i]
        if entry
        and entry.vehicle == vehicle
        and entry.partId == partId
        then
            table.remove(list, i)
        end
    end

    if #list <= 0 then
        GAA_ActiveArmorLocks[owner] = nil
    end
end

local function GAA_ClearAllArmorLocksForOwner(owner)
    if not owner then return end

    local list = GAA_ActiveArmorLocks[owner]
    if not list then return end

    for i = #list, 1, -1 do
        local entry = list[i]
        if entry and entry.vehicle and entry.partId then
            local vehicle = entry.vehicle
            local partId = entry.partId
            local vdata = vehicle:getModData()

            if vdata and vdata.gArmorLocks then
                local lock = vdata.gArmorLocks[partId]
                if lock and lock.owner == owner then
                    vdata.gArmorLocks[partId] = nil
                    vehicle:transmitModData()
                end
            end
        end
    end

    GAA_ActiveArmorLocks[owner] = nil
end

local function GAA_NowSeconds()
    if os and os.time then
        return os.time()
    end

    return 0
end

----------------------------------------------------------
-- SERVER COMMAND RATE LIMIT
-- Prevents malicious/buggy clients from spamming armor
-- command validation and inventory paths.
----------------------------------------------------------
local GAA_CommandRate = {}
local GAA_COMMAND_COOLDOWN_SECONDS = 1
local GAA_COMMAND_RATE_TTL_SECONDS = 3600
local GAA_COMMAND_RATE_PRUNE_INTERVAL_SECONDS = 300
local GAA_CommandRateLastPrune = 0

local function GAA_PruneCommandRate(now)
    now = tonumber(now) or GAA_NowSeconds()
    if now <= 0 then return end

    if GAA_CommandRateLastPrune > 0
    and (now - GAA_CommandRateLastPrune) < GAA_COMMAND_RATE_PRUNE_INTERVAL_SECONDS
    then
        return
    end

    GAA_CommandRateLastPrune = now

    for owner, commands in pairs(GAA_CommandRate) do
        local newest = 0

        if type(commands) == "table" then
            for command, timestamp in pairs(commands) do
                local t = tonumber(timestamp) or 0

                if t <= 0 or (now - t) > GAA_COMMAND_RATE_TTL_SECONDS then
                    commands[command] = nil
                elseif t > newest then
                    newest = t
                end
            end
        end

        if type(commands) ~= "table"
        or newest <= 0
        or (now - newest) > GAA_COMMAND_RATE_TTL_SECONDS
        then
            GAA_CommandRate[owner] = nil
        end
    end
end

local function GAA_IsRateLimited(owner, command)
    if not owner or not command then return false end

    local now = GAA_NowSeconds()
    if now <= 0 then return false end

    GAA_PruneCommandRate(now)

    GAA_CommandRate[owner] = GAA_CommandRate[owner] or {}

    local last = GAA_CommandRate[owner][command]
    if last and (now - last) < GAA_COMMAND_COOLDOWN_SECONDS then
        return true
    end

    GAA_CommandRate[owner][command] = now
    return false
end

local function GAA_ClearCommandRateForOwner(owner)
    if owner then
        GAA_CommandRate[owner] = nil
    end
end

local function GAA_EnsureArmorLocks(vdata)
    vdata.gArmorLocks = vdata.gArmorLocks or {}
    return vdata.gArmorLocks
end

local function GAA_IsLockStale(lock)
    if not lock or not lock.time then return false end
    local now = GAA_NowSeconds()
    if now <= 0 then return false end
    return (now - tonumber(lock.time)) > GAA_LOCK_TIMEOUT_SECONDS
end

local function GAA_ServerCanUseLock(vdata, partId, owner)
    local locks = GAA_EnsureArmorLocks(vdata)
    local lock = locks[partId]

    if not lock then return true end

    if GAA_IsLockStale(lock) then
        locks[partId] = nil
        return true
    end

    return lock.owner == owner
end

local function GAA_ServerSetLock(vehicle, partId, owner, action)
    if not vehicle or not partId or not owner then return false end

    local vdata = vehicle:getModData()
    local locks = GAA_EnsureArmorLocks(vdata)
    local lock = locks[partId]

    if lock and not GAA_IsLockStale(lock) and lock.owner ~= owner then
        return false
    end

    locks[partId] = {
        owner  = owner,
        action = action or "unknown",
        time   = GAA_NowSeconds(),
    }

    GAA_IndexArmorLock(owner, vehicle, partId)

    vehicle:transmitModData()
    return true
end

local function GAA_ServerClearLock(vehicle, partId, owner)
    if not vehicle or not partId then return end

    local vdata = vehicle:getModData()
    if not vdata or not vdata.gArmorLocks then return end

    local lock = vdata.gArmorLocks[partId]
    if not lock then return end

    if not owner or lock.owner == owner or GAA_IsLockStale(lock) then
        local lockOwner = lock.owner
        vdata.gArmorLocks[partId] = nil

        if lockOwner then
            GAA_UnindexArmorLock(lockOwner, vehicle, partId)
        end

        vehicle:transmitModData()
    end
end

local function GAA_ServerBeginArmorAction(player, args)
    local vehicle = GAA_ServerGetVehicleFromArgs(args, player)
    local partId  = args and args.partId
    local action  = args and args.action
    local owner   = GAA_GetPlayerKey(player)

    local ok, reason = GAA_ServerValidateCommon(player, vehicle, partId)
    if not ok then
        GAA_ServerReject(player, reason)
        return
    end

    local validAction = action == "Install"
        or action == "Repair"
        or action == "Uninstall"

    if not validAction then
        GAA_ServerReject(player, "Invalid armor action.")
        return
    end

    if not GAA_ServerSetLock(vehicle, partId, owner, action) then
        GAA_ServerReject(player, "This armor part is already being worked on.")
    end
end

local function GAA_ServerClearArmorAction(player, args)
    local vehicle = GAA_ServerGetVehicleFromArgs(args, player)
    local partId  = args and args.partId
    local owner   = GAA_GetPlayerKey(player)

    GAA_ServerClearLock(vehicle, partId, owner)
end


----------------------------------------------------------
-- LOCK CLEANUP ON PLAYER EXIT / DEATH
-- Stale-lock timeout is still kept as a fallback, but this
-- clears locks immediately when the server can detect exit.
----------------------------------------------------------
local function GAA_ClearLocksForPlayer(player)
    if not player then return end
    GAA_ClearAllArmorLocksForOwner(GAA_GetPlayerKey(player))
end

local function GAA_OnPlayerDeathForLocks(player)
    local owner = GAA_GetPlayerKey(player)
    GAA_ClearLocksForPlayer(player)
    GAA_ClearCommandRateForOwner(owner)
end

local function GAA_OnDisconnectForLocks(playerOrId, username)
    if username then
        GAA_ClearAllArmorLocksForOwner(tostring(username))
        GAA_ClearCommandRateForOwner(tostring(username))
        return
    end

    if playerOrId and type(playerOrId) ~= "number" then
        local owner = GAA_GetPlayerKey(playerOrId)
        GAA_ClearLocksForPlayer(playerOrId)
        GAA_ClearCommandRateForOwner(owner)
    end
end

if Events.OnPlayerDeath then
    Events.OnPlayerDeath.Add(GAA_OnPlayerDeathForLocks)
end

if Events.OnDisconnect then
    Events.OnDisconnect.Add(GAA_OnDisconnectForLocks)
end

local function GAA_ServerGetScaledRepairRecipe(partId, armor)
    if not partId or not armor then return nil end

    local base = VehicleArmorConfig.getRepairRecipe(partId, armor.grade)
    if not base then return nil end

    local missingHP = math.max(0, 100 - (armor.health or 0))
    local ratio = missingHP / 100
    local scaled = {}

    for mat, req in pairs(base) do
        scaled[mat] = math.max(1, math.ceil(math.floor(req) * ratio))
    end

    return scaled
end

local function GAA_ClientAlreadyApplied(args)
    return args and args.clientApplied == true
end

----------------------------------------------------------
-- SERVER-SIDE XP HELPERS
-- MP authoritative actions must award XP on the server,
-- because clients no longer mutate inventory/vehicle state.
----------------------------------------------------------
local function GAA_ServerAddXP(player, perk, amount)
    if not player or not perk or not amount or amount <= 0 then return end
    if not player.getXp then return end

    local mult = 1.0
    if VehicleArmorConfig and VehicleArmorConfig.getXPRewardMultiplier then
        mult = VehicleArmorConfig.getXPRewardMultiplier()
    end

    local finalAmount = amount * mult
    if finalAmount <= 0 then return end

    local okXP, xpObj = pcall(function() return player:getXp() end)
    if okXP and xpObj and xpObj.AddXP then
        pcall(function() xpObj:AddXP(perk, finalAmount) end)
    end
end

local function GAA_ServerAddMetalWeldingXP(player, amount)
    if Perks and Perks.MetalWelding then
        GAA_ServerAddXP(player, Perks.MetalWelding, amount)
    end
end

local function GAA_ServerAddMechanicsXP(player, amount)
    if Perks and Perks.Mechanics then
        GAA_ServerAddXP(player, Perks.Mechanics, amount)
    end
end

local function GAA_ServerAddElectricityXP(player, amount)
    if Perks and Perks.Electricity then
        GAA_ServerAddXP(player, Perks.Electricity, amount)
    end
end

local function GAA_ServerGetArmorInstallXP(grade)
    local xp = { Scrap = 0, Standard = 8, Reinforced = 14, Apocalypse = 25 }
    return xp[grade] or 0
end

local function GAA_ServerGetArmorInstallMechanicsXP(grade)
    local xp = { Scrap = 1, Standard = 2, Reinforced = 3, Apocalypse = 5 }
    return xp[grade] or 1
end

local function GAA_ServerGetArmorRepairXP(grade, missingHP)
    local base = { Scrap = 0, Standard = 2, Reinforced = 3, Apocalypse = 4 }
    local amount = base[grade] or 0
    if amount <= 0 then return 0 end
    local ratio = math.max(0.1, math.min(1.0, (missingHP or 0) / 100))
    return math.max(1, math.ceil(amount * ratio))
end

local function GAA_ServerGetArmorRepairMechanicsXP(grade, missingHP)
    local base = { Scrap = 1, Standard = 1, Reinforced = 2, Apocalypse = 3 }
    local ratio = math.max(0.1, math.min(1.0, (missingHP or 0) / 100))
    return math.max(1, math.ceil((base[grade] or 1) * ratio))
end

local function GAA_ServerGetArmorUninstallXP(grade)
    local xp = { Scrap = 0, Standard = 1, Reinforced = 2, Apocalypse = 3 }
    return xp[grade] or 0
end

local function GAA_ServerGetArmorUninstallMechanicsXP(grade)
    local xp = { Scrap = 1, Standard = 1, Reinforced = 1, Apocalypse = 2 }
    return xp[grade] or 1
end

local function GAA_ServerAwardInstallXP(player, grade)
    GAA_ServerAddMetalWeldingXP(player, GAA_ServerGetArmorInstallXP(grade))
    GAA_ServerAddMechanicsXP(player, GAA_ServerGetArmorInstallMechanicsXP(grade))
end

local function GAA_ServerAwardRepairXP(player, grade, missingHP)
    GAA_ServerAddMetalWeldingXP(player, GAA_ServerGetArmorRepairXP(grade, missingHP))
    GAA_ServerAddMechanicsXP(player, GAA_ServerGetArmorRepairMechanicsXP(grade, missingHP))
end

local function GAA_ServerAwardUninstallXP(player, grade)
    GAA_ServerAddMetalWeldingXP(player, GAA_ServerGetArmorUninstallXP(grade))
    GAA_ServerAddMechanicsXP(player, GAA_ServerGetArmorUninstallMechanicsXP(grade))
end

local function GAA_ServerRejectAndClear(player, vehicle, partId, owner, reason, silent)
    GAA_ServerClearLock(vehicle, partId, owner)
    GAA_ServerReject(player, reason, silent)
end

local function GAA_ServerAcceptClientAppliedInstall(player, vehicle, partId, grade)
    local vdata = vehicle:getModData()
    vdata.gArmor = vdata.gArmor or {}

    local existing = vdata.gArmor[partId]
    if existing and existing.grade == grade then
        existing.health = tonumber(existing.health) or 100
    else
        vdata.gArmor[partId] = {
            grade  = grade,
            health = 100,
        }
    end

    vehicle:transmitModData()
    VehicleArmor_UpdateMass(vehicle)
    GAA_ServerSendArmorApplied(player, vehicle, "InstallArmor", partId, vdata.gArmor[partId])
end


local function GAA_ServerInstallArmor(player, args)
    local vehicle = GAA_ServerGetVehicleFromArgs(args, player)
    local partId  = args and args.partId
    local grade   = args and args.grade
    local owner   = GAA_GetPlayerKey(player)

    local ok, reason = GAA_ServerValidateInstall(player, vehicle, partId, grade)

    -- When a client has already applied/transmitted the result,
    -- the server may see the armor in modData before this command
    -- is handled. Treat matching existing armor as idempotent
    -- success instead of rejecting or consuming materials twice.
    if not ok and GAA_ClientAlreadyApplied(args) then
        local vdataExisting = vehicle and vehicle:getModData()
        local existing = vdataExisting and vdataExisting.gArmor and vdataExisting.gArmor[partId]
        if existing and existing.grade == grade then
            GAA_ServerClearLock(vehicle, partId, owner)
            GAA_ServerSendArmorApplied(player, vehicle, "InstallArmor", partId, existing)
            return
        end
    end

    if not ok then
        GAA_ServerRejectAndClear(player, vehicle, partId, owner, reason)
        return
    end

    local vdata = vehicle:getModData()
    if not GAA_ServerCanUseLock(vdata, partId, owner) then
        GAA_ServerRejectAndClear(player, vehicle, partId, owner, "This armor part is locked by another player.")
        return
    end

    if GAA_ClientAlreadyApplied(args) then
        GAA_ServerAcceptClientAppliedInstall(player, vehicle, partId, grade)
        GAA_ServerClearLock(vehicle, partId, owner)
        GAA_AdminLogAction(player, "accepted client-applied install of", vehicle, partId, grade)
        return
    end

    local recipe = VehicleArmorConfig.getInstallRecipe(partId, grade)
    local fuelUse = VehicleArmorConfig.getInstallFuelUse and VehicleArmorConfig.getInstallFuelUse(partId, grade) or (VehicleArmorConfig.FuelUse.Install[grade] or 0)

    if not GAA_ServerConsumeFuelAndMaterials(player, recipe, fuelUse, true, grade) then
        GAA_ServerRejectAndClear(player, vehicle, partId, owner, "Missing tools, materials, or blowtorch fuel.")
        return
    end

    vdata.gArmor = vdata.gArmor or {}

    vdata.gArmor[partId] = {
        grade  = grade,
        health = 100,
    }

    GAA_ServerClearLock(vehicle, partId, owner)
    vehicle:transmitModData()
    VehicleArmor_UpdateMass(vehicle)
    GAA_ServerAwardInstallXP(player, grade)

    GAA_AdminLogAction(player, "installed", vehicle, partId, grade)
    GAA_ServerSendArmorApplied(player, vehicle, "InstallArmor", partId, vdata.gArmor[partId])
end

local function GAA_ServerRepairArmor(player, args)
    local vehicle = GAA_ServerGetVehicleFromArgs(args, player)
    local partId  = args and args.partId
    local owner   = GAA_GetPlayerKey(player)

    local ok, reason = GAA_ServerValidateRepair(player, vehicle, partId)
    if not ok then
        GAA_ServerRejectAndClear(player, vehicle, partId, owner, reason)
        return
    end

    local vdata = vehicle:getModData()
    if not GAA_ServerCanUseLock(vdata, partId, owner) then
        GAA_ServerRejectAndClear(player, vehicle, partId, owner, "This armor part is locked by another player.")
        return
    end

    local armor = vdata.gArmor[partId]
    if not GAA_ClientAlreadyApplied(args) then
        local recipe = GAA_ServerGetScaledRepairRecipe(partId, armor)
        local fuelUse = VehicleArmorConfig.FuelUse.Repair[armor.grade] or 1

        if not GAA_ServerConsumeFuelAndMaterials(player, recipe, fuelUse, true, armor.grade) then
            GAA_ServerRejectAndClear(player, vehicle, partId, owner, "Missing repair materials or blowtorch fuel.")
            return
        end
    end

    local repairGrade = armor.grade
    local repairMissingHP = math.max(0, 100 - (armor.health or 0))

    armor.health = 100

    local clearedLeak = false
    if partId == "GasTank" and vdata.gArmorGasLeak then
        vdata.gArmorGasLeak = nil
        vdata.gArmorGasLeakPunctureApplied = nil
        GAA_ClearGasLeakTimer(vehicle)
        clearedLeak = true
    end

    GAA_ServerClearLock(vehicle, partId, owner)
    -- VehicleArmor_UpdateMass transmits modData at the end; avoid a redundant
    -- extra transmit packet here, especially for GasTank repairs that clear leaks.
    VehicleArmor_UpdateMass(vehicle)
    GAA_ServerAwardRepairXP(player, repairGrade, repairMissingHP)

    GAA_AdminLogAction(
        player,
        "repaired",
        vehicle,
        partId,
        armor.grade,
        clearedLeak and "gas leak cleared" or nil
    )
    GAA_ServerSendArmorApplied(player, vehicle, "RepairArmor", partId, armor)
end

local function GAA_ServerUninstallArmor(player, args)
    local vehicle = GAA_ServerGetVehicleFromArgs(args, player)
    local partId  = args and args.partId
    local owner   = GAA_GetPlayerKey(player)
    local clientApplied = GAA_ClientAlreadyApplied(args)

    local ok, reason

    if clientApplied then
        -- The client has already removed/transmitted the armor state
        -- as part of the MP hybrid path. At this point the server may
        -- already see gArmor[partId] as nil, so validate only the
        -- common vehicle/part rules. The server still remains
        -- authoritative for refund item creation to avoid client-only
        -- ghost inventory items.
        ok, reason = GAA_ServerValidateCommon(player, vehicle, partId)
    else
        ok, reason = GAA_ServerValidateUninstall(player, vehicle, partId)
    end

    if not ok then
        GAA_ServerRejectAndClear(player, vehicle, partId, owner, reason)
        return
    end

    local vdata = vehicle:getModData()
    if not GAA_ServerCanUseLock(vdata, partId, owner) then
        GAA_ServerRejectAndClear(player, vehicle, partId, owner, "This armor part is locked by another player.")
        return
    end

    vdata.gArmor = vdata.gArmor or {}

    local armor = vdata.gArmor[partId]
    local grade = (armor and armor.grade) or (args and args.grade) or "Scrap"
    local fuelUse = VehicleArmorConfig.FuelUse.Uninstall[grade] or 1
    local returns = VehicleArmorConfig.getUninstallReturn(partId, grade)

    if clientApplied then
        -- Do not consume torch fuel again: the timed action already
        -- did that locally. Do give the salvage from the server so the
        -- returned items are real MP inventory items.
        GAA_ServerGiveUninstallReturns(player, returns)
    else
        if not GAA_ServerConsumeFuelAndMaterials(player, nil, fuelUse, false) then
            GAA_ServerRejectAndClear(player, vehicle, partId, owner, "Missing blowtorch fuel.")
            return
        end

        GAA_ServerGiveUninstallReturns(player, returns)
    end

    -- Do not clear gArmorGasLeak here. If GasTank armour was
    -- destroyed, the tank has already been punctured.
    vdata.gArmor[partId] = nil

    GAA_ServerClearLock(vehicle, partId, owner)
    vehicle:transmitModData()
    VehicleArmor_UpdateMass(vehicle)
    GAA_ServerAwardUninstallXP(player, grade)

    GAA_AdminLogAction(player, clientApplied and "accepted client-applied uninstall of" or "uninstalled", vehicle, partId, grade)
    GAA_ServerSendArmorApplied(player, vehicle, "UninstallArmor", partId, nil)
end

----------------------------------------------------------
-- SERVER-SIDE VEHICLE UPGRADES
----------------------------------------------------------
local function GAA_ServerSendUpgradeApplied(player, vehicle, upgradeId, grade)
    if not player or not vehicle or not upgradeId or not grade then return end
    local cfg = GSVU4UpgradesConfig.getGradeConfig(upgradeId, grade)
    local vdata = vehicle:getModData()
    local current = vdata and vdata.gUpgrades and vdata.gUpgrades[upgradeId] or nil
    local args = {
        upgradeId = upgradeId,
        grade = grade,
        capacity = cfg and cfg.capacity or 0,
        weight = cfg and cfg.weight or 0,
        health = current and current.health or cfg and cfg.health or 100,
    }
    if upgradeId == "FilteredAirIntake" and current then
        args.filterCapacity = current.filterCapacity
        args.filterMaxCapacity = current.filterMaxCapacity
        args.filterMedia = current.filterMedia
        args.filterMediaVersion = current.filterMediaVersion
    end
    args.actorUsername = GAA_ServerActorUsername(player)
    GAA_ServerAddVehicleCommandArgs(args, vehicle)
    GAA_ServerBroadcastCommand(
        player,
        "GoresSVU4Core",
        "UpgradeActionApplied",
        args
    )

    if GSVU4_ServerQueueVisualRefreshReady then
        GSVU4_ServerQueueVisualRefreshReady(
            player,
            vehicle,
            "upgrade:" .. tostring(upgradeId)
        )
    end
end

local function GAA_ServerRejectUpgrade(player, reason)
    if player then
        sendServerCommand(player, "GoresSVU4Core", "UpgradeActionRejected", {
            message = reason or "Upgrade action rejected."
        })
    end
end

local function GAA_IsScrewdriverItem(item)
    if not item then return false end
    local t  = item.getType and tostring(item:getType()) or ""
    local ft = GAA_GetItemFullType and tostring(GAA_GetItemFullType(item) or "") or ""
    local lowT = string.lower(t)
    local lowFt = string.lower(ft)
    return lowT == "screwdriver"
        or lowFt == "base.screwdriver"
        or string.find(lowT, "screwdriver", 1, true) ~= nil
        or string.find(lowFt, "screwdriver", 1, true) ~= nil
end

local function GAA_ServerHasUpgradeTools(player, upgradeId, grade)
    local upgDef = GSVU4UpgradesConfig and GSVU4UpgradesConfig.getUpgrade and GSVU4UpgradesConfig.getUpgrade(upgradeId) or nil
    local cfg = GSVU4UpgradesConfig and GSVU4UpgradesConfig.getGradeConfig and GSVU4UpgradesConfig.getGradeConfig(upgradeId, grade) or nil
    local req = (cfg and cfg.tools) or (upgDef and upgDef.tools) or { weldingMask = true, blowTorch = true, hammer = true, screwdriver = true }

    local hasMask = false
    local hasHammer = false
    local hasScrewdriver = false
    local hasTorch = (GAA_GetTotalTorchFuel(player) or 0) > 0

    GAA_ForEachAccessibleItem(player, function(item)
        local t  = item.getType and item:getType() or ""
        local ft = GAA_GetItemFullType(item) or ""

        if t == "WeldingMask" or ft == "Base.WeldingMask" then hasMask = true end
        if GAA_IsHammerItem(item) then hasHammer = true end
        if GAA_IsScrewdriverItem(item) then hasScrewdriver = true end
    end)

    if req.weldingMask and not hasMask then return false end
    if req.blowTorch and not hasTorch then return false end
    if req.hammer and not hasHammer then return false end
    if req.screwdriver and not hasScrewdriver then return false end
    return true
end

local function GAA_ServerHasUpgradeSkills(player, cfg)
    if not player or not cfg then return false end
    local skills = cfg.skills or {}
    local mwNeed = tonumber(skills.MetalWelding) or 0
    local meNeed = tonumber(skills.Mechanics) or 0
    local elNeed = tonumber(skills.Electricity) or 0
    local mw = Perks and Perks.MetalWelding and GAA_GetPerkLevel(player, Perks.MetalWelding) or 0
    local me = Perks and Perks.Mechanics and GAA_GetPerkLevel(player, Perks.Mechanics) or 0
    local el = Perks and Perks.Electricity and GAA_GetPerkLevel(player, Perks.Electricity) or 0
    return mw >= mwNeed and me >= meNeed and el >= elNeed
end

local function GAA_ServerAwardUpgradeXP(player, cfg)
    if not player or not cfg or not cfg.xp then return end
    GAA_ServerAddMetalWeldingXP(player, cfg.xp.MetalWelding or 0)
    GAA_ServerAddMechanicsXP(player, cfg.xp.Mechanics or 0)
    GAA_ServerAddElectricityXP(player, cfg.xp.Electricity or 0)
end

local function GAA_ServerInstallUpgrade(player, args)
    local vehicle = GAA_ServerGetVehicleFromArgs(args, player)
    local upgradeId = args and args.upgradeId
    local grade = args and args.grade

    if not vehicle then GAA_ServerRejectUpgrade(player, "Vehicle not found for upgrade.") return end
    if not GAA_ServerIsPlayerNearVehicle(player, vehicle) then GAA_ServerRejectUpgrade(player, "Move closer to the vehicle.") return end

    local pzkOk, pzkReason = GAA_ServerValidatePZKUpgradeCompat(vehicle, upgradeId, "install")
    if not pzkOk then GAA_ServerRejectUpgrade(player, pzkReason) return end

    local cfg = GSVU4UpgradesConfig.getGradeConfig(upgradeId, grade)
    if not cfg then GAA_ServerRejectUpgrade(player, "Invalid upgrade request.") return end

    if upgradeId == "FilteredAirIntake"
    and GSVU4FilteredAirIntake
    and GSVU4FilteredAirIntake.canInstallOnVehicle then
        local vehicleOk, vehicleReason = GSVU4FilteredAirIntake.canInstallOnVehicle(vehicle)
        if not vehicleOk then
            GAA_ServerRejectUpgrade(player, vehicleReason or "Filtered Air Intake requires a fully enclosed cab.")
            return
        end
    end

    if upgradeId == "EngineScoop"
    and GSVU4EngineScoop
    and GSVU4EngineScoop.canInstallOnVehicle then
        local vehicleOk, vehicleReason = GSVU4EngineScoop.canInstallOnVehicle(vehicle)
        if not vehicleOk then
            GAA_ServerRejectUpgrade(player, vehicleReason or "No fitted Engine Scoop model is available for this vehicle.")
            return
        end
    end

    if GSVU4UpgradesConfig.isUpgradePrerequisiteMet and not GSVU4UpgradesConfig.isUpgradePrerequisiteMet(vehicle, upgradeId) then
        local label = GSVU4UpgradesConfig.getUpgradePrerequisiteLabel and GSVU4UpgradesConfig.getUpgradePrerequisiteLabel(upgradeId) or "required upgrade"
        GAA_ServerRejectUpgrade(player, tostring(label) .. " must be installed first.")
        return
    end

    if GSVU4UpgradesConfig.canInstallFrontFixture then
        local fixtureOk, fixtureReason = GSVU4UpgradesConfig.canInstallFrontFixture(vehicle, upgradeId)
        if not fixtureOk then GAA_ServerRejectUpgrade(player, fixtureReason) return end
    end

    local vdata = vehicle:getModData()
    vdata.gUpgrades = vdata.gUpgrades or {}

    local current = vdata.gUpgrades[upgradeId]
    if current and not GSVU4UpgradesConfig.canUpgrade(upgradeId, current.grade, grade) then
        local upgDef = GSVU4UpgradesConfig.getUpgrade and GSVU4UpgradesConfig.getUpgrade(upgradeId) or nil
        local label = upgDef and upgDef.label or "Upgrade"
        GAA_ServerRejectUpgrade(player, tostring(current.grade or "A") .. " " .. label .. " installed")
        return
    end

    if upgradeId == "ExtraFuelStorage"
    and GSVU4UpgradesConfig.canAffordTrunkPenalty then
        local trunkOk, trunkReason = GSVU4UpgradesConfig.canAffordTrunkPenalty(vehicle, upgradeId, grade)
        if not trunkOk then
            GAA_ServerRejectUpgrade(player, trunkReason or "The target cargo compartment must be completely empty.")
            return
        end
    end

    if not GAA_ServerHasUpgradeSkills(player, cfg) then
        GAA_ServerRejectUpgrade(player, "Skill requirement not met for this upgrade.")
        return
    end

    if not GAA_ServerHasUpgradeTools(player, upgradeId, grade) then
        GAA_ServerRejectUpgrade(player, "Missing required upgrade tools.")
        return
    end

    local filterNeed = 0
    local consumedFilterMedia = nil
    if upgradeId == "FilteredAirIntake" and not current and GSVU4FilteredAirIntake then
        filterNeed = tonumber(cfg.filterCapacityMax) or tonumber(cfg.capacity) or 0
        if GSVU4FilteredAirIntake.getAvailableFilterCapacity(player) < filterNeed then
            GAA_ServerRejectUpgrade(player, "Not enough filter media. Factory filters provide 50; crafted or recharged filters provide 25.")
            return
        end
        local selected = GSVU4FilteredAirIntake.selectFilterItems(player, filterNeed)
        if not selected then
            GAA_ServerRejectUpgrade(player, "No valid filter combination can fill the intake.")
            return
        end
    end

    local newUpgrade = {
        grade = grade,
        capacity = cfg.capacity or 0,
        weight = cfg.weight or 0,
        health = cfg.health or 100,
        maxHealth = cfg.health or 100,
        wearRemainder = 0,
    }
    if upgradeId == "FilteredAirIntake" and GSVU4FilteredAirIntake then
        GSVU4FilteredAirIntake.initialiseUpgradeState(newUpgrade, cfg, current)
    end

    if upgradeId == "ExtraFuelStorage" then
        -- Capacity is changed before materials are consumed so a setter failure
        -- cannot eat the installer's resources. The server remains authoritative.
        if not GAA_ServerHasFuelAndMaterials(player, cfg.recipe, cfg.fuelUse or 1, false, grade) then
            GAA_ServerRejectUpgrade(player, "Missing materials or blowtorch fuel for upgrade.")
            return
        end

        vdata.gUpgrades[upgradeId] = newUpgrade
        local applied, applyReason = GSVU4UpgradesConfig.applyExtraFuelStorage(vehicle)
        if not applied then
            vdata.gUpgrades[upgradeId] = current
            if current then
                pcall(function() GSVU4UpgradesConfig.applyExtraFuelStorage(vehicle) end)
            else
                pcall(function() GSVU4UpgradesConfig.removeExtraFuelStorage(vehicle) end)
            end
            GAA_ServerRejectUpgrade(player, applyReason or "Unable to apply the cargo-capacity penalty.")
            return
        end

        if not GAA_ServerConsumeFuelAndMaterials(player, cfg.recipe, cfg.fuelUse or 1, false, grade) then
            vdata.gUpgrades[upgradeId] = current
            if current then
                pcall(function() GSVU4UpgradesConfig.applyExtraFuelStorage(vehicle) end)
            else
                pcall(function() GSVU4UpgradesConfig.removeExtraFuelStorage(vehicle) end)
            end
            GAA_ServerRejectUpgrade(player, "Missing materials or blowtorch fuel for upgrade.")
            return
        end
    else
        if upgradeId == "FilteredAirIntake" and filterNeed > 0 then
            if not GAA_ServerHasFuelAndMaterials(player, cfg.recipe, cfg.fuelUse or 1, false, grade) then
                GAA_ServerRejectUpgrade(player, "Missing materials or blowtorch fuel for upgrade.")
                return
            end
            local filtersOk, added, consumed, filterReason, media = GSVU4FilteredAirIntake.consumeFilterCapacity(player, filterNeed)
            if not filtersOk then
                GAA_ServerRejectUpgrade(player, filterReason or "Unable to consume filter media.")
                return
            end
            consumedFilterMedia = media
        end
        if not GAA_ServerConsumeFuelAndMaterials(player, cfg.recipe, cfg.fuelUse or 1, false, grade) then
            GAA_ServerRejectUpgrade(player, "Missing materials or blowtorch fuel for upgrade.")
            return
        end
        if consumedFilterMedia and upgradeId == "FilteredAirIntake" and GSVU4FilteredAirIntake then
            GSVU4FilteredAirIntake.setInstalledFilterMedia(newUpgrade, consumedFilterMedia)
        end
        vdata.gUpgrades[upgradeId] = newUpgrade
    end

    if upgradeId == "RoofRack" then
        -- Clear any legacy modData storage and activate the native TrunkBag2 container
        vdata.gExternalStorage = vdata.gExternalStorage or {}
        vdata.gExternalStorage.RoofRack = { items = {}, used = 0, capacity = cfg.capacity or 0 }
        GSVU4_ApplyRoofRackContainer(vehicle)
    elseif upgradeId == "BullBar" or upgradeId == "Plow" then
        -- Front-fixture visibility is client-local in MP.
    elseif upgradeId == "AutoTuneMilitaryRadio" and GSVU4 and GSVU4.AutoTuneMilitaryRadio then
        -- Replace the actual vehicle Radio part item, return the removed radio
        -- to the installer, and program the AEBS preset immediately. The radio
        -- only auto-tunes to the channel when the engine is running.
        pcall(function() GSVU4.AutoTuneMilitaryRadio.replaceVehicleRadioItem(vehicle, player) end)
        pcall(function() GSVU4.AutoTuneMilitaryRadio.programEmergencyPreset(vehicle) end)
        -- Cosmetic aerial visibility is client-local in MP.
        if vehicle.isEngineRunning then
            local okRun, running = pcall(function() return vehicle:isEngineRunning() end)
            if okRun and running == true then
                pcall(function() GSVU4.AutoTuneMilitaryRadio.autoTuneVehicleRadio(vehicle) end)
            end
        end
    elseif (GSVU4UpgradesConfig.isRoofLightUpgradeId and GSVU4UpgradesConfig.isRoofLightUpgradeId(upgradeId)) and GSVU4_ApplyRoofLightsVisual then
        GSVU4_ApplyRoofLightsVisual(vehicle)
    end

    if upgradeId == "EngineScoop" and GSVU4EngineScoop and GSVU4EngineScoop.resetRuntime then
        GSVU4EngineScoop.resetRuntime(vehicle, current == nil)
    end

    vehicle:transmitModData()
    VehicleArmor_UpdateMass(vehicle)
    GAA_ServerAwardUpgradeXP(player, cfg)
    GAA_AdminLogAction(player, "installed upgrade", vehicle, upgradeId, grade)
    GAA_ServerSendUpgradeApplied(player, vehicle, upgradeId, grade)
end

local function GAA_ServerGiveUpgradeUninstallReturns(player, cfg, health)
    if not player or not cfg then return end
    local inv = player:getInventory()
    if not inv then return end

    health = tonumber(health) or 0
    local maxHealth = tonumber(cfg.health) or 100
    local healthPercent = maxHealth > 0 and (health / maxHealth) * 100 or 0
    if healthPercent < 50 then
        inv:AddItem("Base.ScrapMetal")
        inv:AddItem("Base.ScrapMetal")
        return
    end

    local recipe = cfg.recipe or {}
    local function giveMany(fullType, count)
        count = math.floor(tonumber(count) or 0)
        for _ = 1, count do inv:AddItem(fullType) end
    end

    giveMany("Base.ScrapMetal", math.floor((recipe.scrap or 0) * 0.5))
    giveMany("Base.SheetMetal", math.floor((recipe.sheets or 0) * 0.5))
    giveMany("Base.MetalBar", math.floor((recipe.bars or 0) * 0.5))
    giveMany("Base.Screws", math.floor((recipe.screws or 0) * 0.5))
    giveMany("Base.Wire", math.floor((recipe.wire or 0) * 0.5))
    giveMany("Base.ElectricWire", math.floor((recipe.electricWire or 0) * 0.5))
    giveMany("Base.LightBulb", math.floor((recipe.bulbs or 0) * 0.5))
    giveMany("Base.GSVU4AutoTuneMilitaryRadio", math.floor((recipe.autoTuneMilitaryRadio or 0) * 1.0))
end

local function GAA_ServerRepairUpgrade(player, args)
    local vehicle = GAA_ServerGetVehicleFromArgs(args, player)
    local upgradeId = args and args.upgradeId or "RoofRack"
    if not vehicle then GAA_ServerRejectUpgrade(player, "Vehicle not found for upgrade repair.") return end
    if not GAA_ServerIsPlayerNearVehicle(player, vehicle) then GAA_ServerRejectUpgrade(player, "Move closer to the vehicle.") return end

    local pzkOk, pzkReason = GAA_ServerValidatePZKUpgradeCompat(vehicle, upgradeId, "repair")
    if not pzkOk then GAA_ServerRejectUpgrade(player, pzkReason) return end

    local vdata = vehicle:getModData()
    local upgrade = vdata and vdata.gUpgrades and vdata.gUpgrades[upgradeId]
    if not upgrade then GAA_ServerRejectUpgrade(player, "No roof rack installed.") return end

    local cfg = GSVU4UpgradesConfig.getGradeConfig(upgradeId, upgrade.grade)
    local maxHealth = tonumber(cfg and cfg.health) or tonumber(upgrade.maxHealth) or 100
    upgrade.health = maxHealth
    upgrade.maxHealth = maxHealth
    upgrade.wearRemainder = 0
    vehicle:transmitModData()
    VehicleArmor_UpdateMass(vehicle)
    GAA_ServerSendUpgradeApplied(player, vehicle, upgradeId, upgrade.grade)
end

local function GAA_ServerUninstallUpgrade(player, args)
    local vehicle = GAA_ServerGetVehicleFromArgs(args, player)
    local upgradeId = args and args.upgradeId or "RoofRack"
    if not vehicle then GAA_ServerRejectUpgrade(player, "Vehicle not found for upgrade removal.") return end
    if not GAA_ServerIsPlayerNearVehicle(player, vehicle) then GAA_ServerRejectUpgrade(player, "Move closer to the vehicle.") return end

    local pzkOk, pzkReason = GAA_ServerValidatePZKUpgradeCompat(vehicle, upgradeId, "uninstall")
    if not pzkOk then GAA_ServerRejectUpgrade(player, pzkReason) return end

    local vdata = vehicle:getModData()
    local upgrade = vdata and vdata.gUpgrades and vdata.gUpgrades[upgradeId]
    if not upgrade then GAA_ServerRejectUpgrade(player, "No roof rack installed.") return end

    local cfg = GSVU4UpgradesConfig.getGradeConfig(upgradeId, upgrade.grade)

    if upgradeId == "ExtraFuelStorage"
    and GSVU4UpgradesConfig.removeExtraFuelStorage then
        local restored, restoreReason = GSVU4UpgradesConfig.removeExtraFuelStorage(vehicle)
        if not restored then
            GAA_ServerRejectUpgrade(player, restoreReason or "Unable to restore the original cargo capacity.")
            return
        end
    end

    GAA_ServerGiveUpgradeUninstallReturns(player, cfg, upgrade.health or 100)
    if upgradeId == "FilteredAirIntake" and GSVU4FilteredAirIntake then
        GSVU4FilteredAirIntake.returnInstalledFilterMedia(player, upgrade)
    end

    if upgradeId == "RoofRack" then
        -- Drain TrunkBag2 items to player and zero capacity
        GSVU4_DrainRoofRackContainer(vehicle, player)
    end

    vdata.gUpgrades[upgradeId] = nil
    if upgradeId == "EngineScoop" then
        vdata.gEngineScoopRuntime = nil
    end
    if vdata.gExternalStorage and upgradeId == "RoofRack" then
        vdata.gExternalStorage.RoofRack = nil
    end
    if upgradeId == "BullBar" or upgradeId == "Plow" then
        -- Front-fixture visibility is client-local in MP.
    end
    if upgradeId == "AutoTuneMilitaryRadio" then
        -- Cosmetic aerial visibility is client-local in MP.
    end
    if (GSVU4UpgradesConfig.isRoofLightUpgradeId and GSVU4UpgradesConfig.isRoofLightUpgradeId(upgradeId)) and GSVU4_ApplyRoofLightsVisual then
        GSVU4_ApplyRoofLightsVisual(vehicle)
    end

    vehicle:transmitModData()
    VehicleArmor_UpdateMass(vehicle)
    GAA_ServerSendUpgradeApplied(player, vehicle, upgradeId, "Removed")
end

local function GAA_ServerGetDisplayCategory(item)
    if not item then return "" end
    if item.getDisplayCategory then local ok, value = pcall(function() return item:getDisplayCategory() end); if ok and value then return tostring(value) end end
    if item.getCategory then local ok, value = pcall(function() return item:getCategory() end); if ok and value then return tostring(value) end end
    return ""
end

local function GAA_ServerGetItemWeight(item)
    if not item then return 1 end
    if item.getActualWeight then local ok, value = pcall(function() return item:getActualWeight() end); if ok and tonumber(value) then return tonumber(value) end end
    if item.getWeight then local ok, value = pcall(function() return item:getWeight() end); if ok and tonumber(value) then return tonumber(value) end end
    return 1
end

local function GAA_ServerIsEquippedOrWornItem(player, item)
    if not player or not item then return true end

    if item.isEquipped then
        local ok, value = pcall(function() return item:isEquipped() end)
        if ok and value == true then return true end
    end

    if player.getPrimaryHandItem then
        local ok, value = pcall(function() return player:getPrimaryHandItem() end)
        if ok and value == item then return true end
    end

    if player.getSecondaryHandItem then
        local ok, value = pcall(function() return player:getSecondaryHandItem() end)
        if ok and value == item then return true end
    end

    if player.getClothingItem_Back then
        local ok, value = pcall(function() return player:getClothingItem_Back() end)
        if ok and value == item then return true end
    end

    if player.getWornItems then
        local ok, worn = pcall(function() return player:getWornItems() end)
        if ok and worn then
            local size = 0
            if worn.size then size = worn:size()
            elseif worn.getSize then size = worn:getSize() end

            for i = 0, size - 1 do
                local wi = worn.get and worn:get(i) or nil
                if wi then
                    local okItem, wornItem = pcall(function()
                        if wi.getItem then return wi:getItem() end
                        return nil
                    end)
                    if okItem and wornItem == item then return true end
                end
            end
        end
    end

    return false
end

local function GAA_ServerRoundWeight2(value)
    value = tonumber(value) or 0
    return math.floor((value * 100) + 0.5) / 100
end

-- ── Roof Rack: native GSVU4RoofRack part slot ────────────────────────────────
-- The roof rack is now a real vehicle part (GSVU4RoofRack) injected into every
-- vehicle script at game boot by GSVU4_RoofRack_Container.lua (shared).
-- so the vanilla loot window surfaces it automatically when the player stands
-- next to the vehicle.
--
-- On install: call part:setInventoryItem(gradeItemFullType) to populate the slot.
--   The item's MaxCapacity becomes the container's effective capacity.
-- On uninstall: drain the container's items to the player, clear the slot.

local GSVU4_RACK_PART = "GSVU4RoofRack"

local GSVU4_GRADE_ITEM = {
    Basic    = "Base.GSVU4RoofRackBasic",
    Standard = "Base.GSVU4RoofRackStandard",
    Military = "Base.GSVU4RoofRackMilitary",
}

local function GSVU4_GetRoofRackPart(vehicle)
    if not vehicle or not vehicle.getPartById then return nil end
    local ok, part = pcall(function() return vehicle:getPartById(GSVU4_RACK_PART) end)
    return (ok and part) or nil
end

local function GSVU4_GetRoofRackContainer(vehicle)
    local part = GSVU4_GetRoofRackPart(vehicle)
    if not part then return nil end
    if part.getItemContainer then
        local ok, ic = pcall(function() return part:getItemContainer() end)
        if ok and ic then return ic end
    end
    return nil
end

-- Sets the installed item in the GSVU4RoofRack part slot, activating the container.
-- Also migrates any legacy modData items into the real container.
local function GSVU4_ApplyRoofRackContainer(vehicle)
    if not vehicle then return end
    local vdata = vehicle:getModData()
    local rack  = vdata and vdata.gUpgrades and vdata.gUpgrades.RoofRack
    if not rack or not rack.grade then return end

    local part = GSVU4_GetRoofRackPart(vehicle)
    if not part then
        return
    end

    -- instanceItem() creates a Java InventoryItem from a full type string.
    -- part:setInventoryItem() requires the Java object, not a string.
    local itemType = GSVU4_GRADE_ITEM[rack.grade] or GSVU4_GRADE_ITEM.Basic
    local ok, item = pcall(function() return instanceItem(itemType) end)
    if ok and item then
        pcall(function()
            part:setInventoryItem(item)
            vehicle:transmitPartItem(part)
        end)
    else
    end

    -- Migrate legacy modData items into the real container (one-time)
    local legacy = vdata.gExternalStorage and vdata.gExternalStorage.RoofRack
    if legacy and legacy.items and #legacy.items > 0 then
        local ic = GSVU4_GetRoofRackContainer(vehicle)
        if ic then
            for _, entry in ipairs(legacy.items) do
                if entry and entry.fullType then
                    pcall(function() ic:AddItem(entry.fullType) end)
                end
            end
        end
        legacy.items = {}
        legacy.used  = 0
        vehicle:transmitModData()
    end
end

-- Drains all items from the GSVU4RoofRack container back to the player,
-- then clears the part slot (hiding the container from the vanilla UI).
local function GSVU4_DrainRoofRackContainer(vehicle, player)
    if not vehicle then return end
    local ic = GSVU4_GetRoofRackContainer(vehicle)
    if ic then
        local inv = player and player.getInventory and player:getInventory()
        if inv then
            local ok, items = pcall(function() return ic:getItems() end)
            if ok and items then
                local toMove = {}
                for i = 0, items:size() - 1 do
                    local okI, it = pcall(function() return items:get(i) end)
                    if okI and it then table.insert(toMove, it) end
                end
                for _, it in ipairs(toMove) do
                    pcall(function() ic:Remove(it); inv:AddItem(it) end)
                end
            end
        end
    end
    -- Clear the slot with nil — this is the accepted form (nil is a Java null)
    local part = GSVU4_GetRoofRackPart(vehicle)
    if part then
        pcall(function()
            part:setInventoryItem(nil)
            vehicle:transmitPartItem(part)
        end)
    end
    -- Clear legacy modData storage
    local vdata = vehicle:getModData()
    if vdata.gExternalStorage then vdata.gExternalStorage.RoofRack = nil end
end

local function GAA_ServerReplaceFilteredAirIntakeFilters(player, args)
    local vehicle = GAA_ServerGetVehicleFromArgs(args, player)
    if not vehicle then GAA_ServerRejectUpgrade(player, "Vehicle not found for filter replacement.") return end
    if not GAA_ServerIsPlayerNearVehicle(player, vehicle) then GAA_ServerRejectUpgrade(player, "Move closer to the vehicle.") return end
    if not GSVU4FilteredAirIntake then GAA_ServerRejectUpgrade(player, "Filtered Air Intake system unavailable.") return end

    local ok, added, consumed, reason = GSVU4FilteredAirIntake.replaceFilterSetFromCharacter(player, vehicle)
    if not ok then GAA_ServerRejectUpgrade(player, reason or "Unable to replace filters.") return end
    vehicle:transmitModData()
    local upgrade = GSVU4FilteredAirIntake.getInstalled(vehicle)
    GAA_AdminLogAction(player, "replaced filtered air intake filters", vehicle, "FilteredAirIntake", upgrade and upgrade.grade or nil)
    GAA_ServerSendUpgradeApplied(player, vehicle, "FilteredAirIntake", upgrade and upgrade.grade or nil)
end

local function GAA_ServerDrainFilteredAirIntake(player, args)
    local vehicle = GAA_ServerGetVehicleFromArgs(args, player)
    if not vehicle or not GSVU4FilteredAirIntake then return end
    local occupied = player and player.getVehicle and player:getVehicle() or nil
    if occupied ~= vehicle then return end
    local status = GSVU4FilteredAirIntake.getStatus(vehicle)
    if not status or not status.active then return end
    local amount = math.max(1, math.min(5, math.floor(tonumber(args and args.amount) or 1)))
    local upgrade = GSVU4FilteredAirIntake.getInstalled(vehicle)
    if not upgrade then return end
    local current = tonumber(upgrade.filterCapacity) or tonumber(status.capacity) or 0
    local updated = math.max(0, current - amount)
    if updated == current then return end
    upgrade.filterCapacity = updated
    vehicle:transmitModData()
end

local function GAA_OnClientCommand(module, command, player, args)
    if module ~= "GoresSVU4Core" then return end

    local owner = GAA_GetPlayerKey(player)

    -- ClearArmorAction is deliberately not rate-limited so
    -- cancelled actions can always release their locks.
    if command ~= "ClearArmorAction"
    and command ~= "TryRandomSurvivorArmor"
    and command ~= "BullBarZombieImpact"
    and command ~= "BullBarVehicleImpact"
    and command ~= "BullBarFrontDamage"
    and command ~= "PlowPushZombie"
    and GAA_IsRateLimited(owner, tostring(command or "unknown"))
    then
        GAA_ServerReject(player, "Armor command rate limited.")
        return
    end

    if command == "BeginArmorAction" then
        GAA_ServerBeginArmorAction(player, args)
    elseif command == "ClearArmorAction" then
        GAA_ServerClearArmorAction(player, args)
    elseif command == "InstallArmor" then
        GAA_ServerInstallArmor(player, args)
    elseif command == "RepairArmor" then
        GAA_ServerRepairArmor(player, args)
    elseif command == "UninstallArmor" then
        GAA_ServerUninstallArmor(player, args)
    elseif command == "InstallUpgrade" then
        GAA_ServerInstallUpgrade(player, args)
    elseif command == "RepairUpgrade" then
        GAA_ServerRepairUpgrade(player, args)
    elseif command == "ReplaceFilteredAirIntakeFilters" or command == "RechargeFilteredAirIntake" then
        GAA_ServerReplaceFilteredAirIntakeFilters(player, args)
    elseif command == "DrainFilteredAirIntake" then
        GAA_ServerDrainFilteredAirIntake(player, args)
    elseif command == "UninstallUpgrade" then
        GAA_ServerUninstallUpgrade(player, args)
    elseif command == "TryRandomSurvivorArmor" then
        local vehicle = GAA_ServerGetVehicleFromArgs(args, player)
        if vehicle then
            GAA_TrySeedRandomSurvivorArmor(vehicle)
        end
    end
end

Events.OnClientCommand.Add(GAA_OnClientCommand)
