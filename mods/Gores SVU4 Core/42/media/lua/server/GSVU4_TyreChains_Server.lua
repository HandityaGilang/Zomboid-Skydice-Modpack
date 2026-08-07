-- =============================================================================
-- Gore's SVU4 Core - Tyre Chains Server Authority
-- =============================================================================
require "GoresSVU4TyreChains/GSVU4_TyreChains_Config"

local TC = GSVU4_TyreChains
local Config = TC.Config

local function safeSound(vehicle, radius, volume)
    if not vehicle or not addSound then return end
    local ok = pcall(function()
        addSound(vehicle, vehicle:getX(), vehicle:getY(), vehicle:getZ(), radius or 10, volume or 10)
    end)
    if not ok then
        pcall(function()
            addSound(nil, vehicle:getX(), vehicle:getY(), vehicle:getZ(), radius or 10, volume or 10)
        end)
    end
end

local function rememberTyreConditions(vehicle, data)
    data.lastTyreConditions = data.lastTyreConditions or {}
    local tyres = TC.getTyreParts(vehicle)
    for _, part in ipairs(tyres) do
        if part and part.getId and part.getCondition then
            data.lastTyreConditions[part:getId()] = part:getCondition() or 0
        end
    end
end

local function applySnowBenefit(vehicle)
    local data = TC.getData(vehicle)
    if not data then return end

    data.state = "SNOW_BENEFIT"
    data.lastTyreConditions = data.lastTyreConditions or {}

    local tyres = TC.getTyreParts(vehicle)
    for _, part in ipairs(tyres) do
        if part and part.getId and part.getCondition then
            local id = part:getId()
            local current = part:getCondition() or 0
            local previous = data.lastTyreConditions[id]

            -- Soft tyre-wear protection: if the tyre dropped since the last check, sometimes restore 1 point.
            -- This avoids trying to directly edit live handling/braking while still making chains useful in snow.
            if previous and current < previous and current > 0 then
                if ZombRand(100) < Config.SnowTyreRestoreChance then
                    TC.setTyreCondition(part, math.min(previous, current + Config.SnowTyreRestoreAmount))
                    TC.syncPartCondition(vehicle, part)
                end
            end

            data.lastTyreConditions[id] = part:getCondition() or current
        end
    end

    if ZombRand(100) < Config.SnowChainWearChance then
        TC.damageChains(vehicle, Config.ChainWearPerHit)
    else
        if vehicle.transmitModData then vehicle:transmitModData() end
    end
end

local function applyDryRoadPenalty(vehicle)
    local data = TC.getData(vehicle)
    if not data then return end

    local tier = TC.getPenaltyTier(vehicle)
    data.state = "NORMAL_" .. tier
    rememberTyreConditions(vehicle, data)

    if tier == "IDLE" then
        data.dryRoadChecks = 0
        if vehicle.transmitModData then vehicle:transmitModData() end
        return
    end

    data.dryRoadChecks = (data.dryRoadChecks or 0) + 1

    local tyreChance = 0
    local chainChance = 0
    local noiseChance = 0
    local noiseRadius = 0
    local noiseVolume = 0
    local breakChance = 0

    if tier == "LOW" then
        tyreChance = Config.LowSpeedTyreDamageChance
        chainChance = Config.LowSpeedChainWearChance
        noiseChance = Config.LowSpeedNoiseChance
        noiseRadius = Config.LowSpeedNoiseRadius
        noiseVolume = Config.LowSpeedNoiseVolume
    elseif tier == "HIGH" then
        tyreChance = Config.HighSpeedTyreDamageChance
        chainChance = Config.HighSpeedChainWearChance
        noiseChance = Config.HighSpeedNoiseChance
        noiseRadius = Config.HighSpeedNoiseRadius
        noiseVolume = Config.HighSpeedNoiseVolume
    else
        tyreChance = Config.AbuseTyreDamageChance
        chainChance = Config.AbuseChainWearChance
        noiseChance = Config.AbuseNoiseChance
        noiseRadius = Config.AbuseNoiseRadius
        noiseVolume = Config.AbuseNoiseVolume
        breakChance = Config.AbuseBreakChance
    end

    local guaranteedTyreEvery = Config.DryRoadGuaranteedTyreWearCheckCount or 0
    local guaranteedChainEvery = Config.DryRoadGuaranteedChainWearCheckCount or 0

    if guaranteedTyreEvery > 0 and (data.dryRoadChecks % guaranteedTyreEvery) == 0 then
        TC.damageRandomTyre(vehicle, 1)
    elseif tyreChance > 0 and ZombRand(100) < tyreChance then
        TC.damageRandomTyre(vehicle, 1)
    end

    if guaranteedChainEvery > 0 and (data.dryRoadChecks % guaranteedChainEvery) == 0 then
        TC.damageChains(vehicle, Config.ChainWearPerHit)
    elseif chainChance > 0 and ZombRand(100) < chainChance then
        TC.damageChains(vehicle, Config.ChainWearPerHit)
    end

    if breakChance > 0 and ZombRand(100) < breakChance then
        TC.damageChains(vehicle, 999)
        TC.damageRandomTyre(vehicle, Config.BrokenChainExtraTyreDamage)
        data.state = "BROKEN_SPEED_ABUSE"
    end

    if noiseChance > 0 and ZombRand(100) < noiseChance then
        safeSound(vehicle, noiseRadius, noiseVolume)
    end

    if vehicle.transmitModData then vehicle:transmitModData() end
end

function TC.processVehicle(vehicle)
    if not TC.shouldRunForVehicle(vehicle) then return end

    if TC.isSnowCondition() then
        applySnowBenefit(vehicle)
    else
        applyDryRoadPenalty(vehicle)
    end
end

local function processPlayerVehicle(playerObj)
    if not playerObj or not playerObj.getVehicle then return end
    local vehicle = playerObj:getVehicle()
    if not vehicle then return end
    TC.processVehicle(vehicle)
end

local function onEveryOneMinute()
    if not Config.Enabled then return end

    -- Dedicated / MP server path
    if isServer and isServer() then
        if getOnlinePlayers then
            local players = getOnlinePlayers()
            if players then
                for i = 0, players:size() - 1 do
                    processPlayerVehicle(players:get(i))
                end
            end
        end
        return
    end

    -- Single-player path
    if getNumActivePlayers and getSpecificPlayer then
        for i = 0, getNumActivePlayers() - 1 do
            processPlayerVehicle(getSpecificPlayer(i))
        end
    end
end

local function findVehicleForCommand(playerObj, args)
    if not args then args = {} end

    if playerObj and playerObj.getVehicle then
        local pv = playerObj:getVehicle()
        if pv then return pv end
    end

    -- Try global vehicle resolver if available.
    if args.vehicleId and getVehicleById then
        local ok, vehicle = pcall(function() return getVehicleById(args.vehicleId) end)
        if ok and vehicle then return vehicle end
    end

    -- Try the local square supplied by the client context menu.
    if args.x and args.y and getCell then
        local square = getCell():getGridSquare(args.x, args.y, args.z or 0)
        if square and square.getMovingObjects then
            local moving = square:getMovingObjects()
            if moving then
                for i = 0, moving:size() - 1 do
                    local obj = moving:get(i)
                    if obj and obj.getScriptName and obj.getPartById then
                        return obj
                    end
                end
            end
        end
    end

    return nil
end

local function reject(command, reason)

end

local function validateInstall(playerObj, vehicle)
    if TC.isInstalled(vehicle) then return false, "chains already installed" end
    if not TC.hasMechanics(playerObj, Config.RequiredMechanicsInstall) then return false, "Mechanics 5 required" end
    if not TC.hasTools(playerObj, Config.InstallTools) then return false, "missing install tools" end
    if not TC.hasMaterials(playerObj, Config.InstallMaterials) then return false, "missing install materials" end
    return true
end

local function validateRemove(playerObj, vehicle)
    if not TC.isInstalled(vehicle) then return false, "chains are not installed" end
    if not TC.hasMechanics(playerObj, Config.RequiredMechanicsRemove) then return false, "Mechanics 5 required" end
    if not TC.hasTools(playerObj, Config.RemoveTools) then return false, "missing removal tools" end
    return true
end

local function validateRepair(playerObj, vehicle, heavy)
    if not TC.isInstalled(vehicle) then return false, "chains are not installed" end
    if not TC.hasMechanics(playerObj, Config.RequiredMechanicsRepair) then return false, "Mechanics 2 required" end

    local data = TC.getData(vehicle)
    if data and (data.condition or 0) >= Config.ChainInstallCondition then return false, "chains are already repaired" end

    if heavy then
        if not TC.hasTools(playerObj, Config.HeavyRepairTools) then return false, "missing heavy repair tools" end
        if not TC.hasMaterials(playerObj, Config.HeavyRepairMaterials) then return false, "missing heavy repair materials" end
    else
        if not TC.hasTools(playerObj, Config.LightRepairTools) then return false, "missing light repair tools" end
        if not TC.hasMaterials(playerObj, Config.LightRepairMaterials) then return false, "missing light repair materials" end
    end

    return true
end

local function tyreChainActorUsername(playerObj)
    if playerObj and playerObj.getUsername then
        local ok, value = pcall(function() return playerObj:getUsername() end)
        if ok and value then return tostring(value) end
    end
    return nil
end

local function addTyreChainVehicleArgs(args, vehicle)
    if vehicle and vehicle.getId then
        local ok, value = pcall(function() return vehicle:getId() end)
        if ok and value ~= nil then args.vehicleId = tonumber(value) or tostring(value) end
    end
    if vehicle and vehicle.getOnlineID then
        local ok, value = pcall(function() return vehicle:getOnlineID() end)
        if ok and value ~= nil then args.vehicleOnlineId = tonumber(value) or tostring(value) end
    end
    if vehicle and vehicle.getX then args.vehicleX = vehicle:getX() end
    if vehicle and vehicle.getY then args.vehicleY = vehicle:getY() end
    if vehicle and vehicle.getZ then args.vehicleZ = vehicle:getZ() end
end

local function broadcastTyreChainVisualState(playerObj, vehicle, removed)
    if not sendServerCommand or not vehicle then return end
    local data = TC.getData(vehicle)
    local args = {
        upgradeId = "TyreChains",
        grade = removed and "Removed" or "Standard",
        capacity = 0,
        weight = 0,
        health = removed and 0 or tonumber(data and data.condition) or 100,
        actorUsername = tyreChainActorUsername(playerObj),
    }
    addTyreChainVehicleArgs(args, vehicle)

    local sent = false
    if getOnlinePlayers then
        local okPlayers, players = pcall(getOnlinePlayers)
        if okPlayers and players and players.size and players.get then
            local okSize, count = pcall(function() return players:size() end)
            if okSize and count then
                for i = 0, count - 1 do
                    local okTarget, target = pcall(function() return players:get(i) end)
                    if okTarget and target then
                        pcall(function() sendServerCommand(target, "GoresSVU4Core", "UpgradeActionApplied", args) end)
                        sent = true
                    end
                end
            end
        end
    end
    if not sent and playerObj then
        sendServerCommand(playerObj, "GoresSVU4Core", "UpgradeActionApplied", args)
    end
end

local function doInstall(playerObj, vehicle, command)
    local ok, reason = validateInstall(playerObj, vehicle)
    if not ok then reject(command, reason); return end

    if not TC.consumeMaterials(playerObj, Config.InstallMaterials) then reject(command, "failed to consume install materials"); return end
    TC.install(vehicle, Config.ChainInstallCondition)
    TC.addMechanicsXP(playerObj, 4)
    safeSound(vehicle, Config.WeldingStyleNoiseRadius, Config.WeldingStyleNoiseVolume)

    broadcastTyreChainVisualState(playerObj, vehicle, false)
end

local function doRemove(playerObj, vehicle, command)
    local ok, reason = validateRemove(playerObj, vehicle)
    if not ok then reject(command, reason); return end

    TC.giveReturnMaterials(playerObj, vehicle)
    TC.remove(vehicle)
    TC.addMechanicsXP(playerObj, 2)
    safeSound(vehicle, Config.WeldingStyleNoiseRadius, Config.WeldingStyleNoiseVolume)

    broadcastTyreChainVisualState(playerObj, vehicle, true)
end

local function doRepair(playerObj, vehicle, command, heavy)
    local ok, reason = validateRepair(playerObj, vehicle, heavy)
    if not ok then reject(command, reason); return end

    if heavy then
        if not TC.consumeMaterials(playerObj, Config.HeavyRepairMaterials) then reject(command, "failed to consume heavy repair materials"); return end
        TC.repairChains(vehicle, Config.HeavyRepairAmount)
    else
        if not TC.consumeMaterials(playerObj, Config.LightRepairMaterials) then reject(command, "failed to consume light repair materials"); return end
        TC.repairChains(vehicle, Config.LightRepairAmount)
    end

    TC.addMechanicsXP(playerObj, 2)
    safeSound(vehicle, Config.WeldingStyleNoiseRadius, Config.WeldingStyleNoiseVolume)

    broadcastTyreChainVisualState(playerObj, vehicle, false)
end

local function onClientCommand(module, command, playerObj, args)
    if module ~= "GSVU4TyreChains" then return end

    local vehicle = findVehicleForCommand(playerObj, args)
    if not vehicle then
        reject(command, "vehicle not found")
        return
    end

    if command == "Install" then
        doInstall(playerObj, vehicle, command)
    elseif command == "Remove" then
        doRemove(playerObj, vehicle, command)
    elseif command == "RepairLight" then
        doRepair(playerObj, vehicle, command, false)
    elseif command == "RepairHeavy" then
        doRepair(playerObj, vehicle, command, true)
    elseif command == "NoisePulse" then
        safeSound(vehicle, Config.WeldingStyleNoiseRadius, Config.WeldingStyleNoiseVolume)
    elseif command == "Toggle" then
        if TC.isInstalled(vehicle) then
            TC.remove(vehicle)

            broadcastTyreChainVisualState(playerObj, vehicle, true)
        else
            TC.install(vehicle, Config.ChainInstallCondition)

            broadcastTyreChainVisualState(playerObj, vehicle, false)
        end
    end
end

Events.EveryOneMinute.Add(onEveryOneMinute)

local GSVU4_TyreChains_TickCounter = 0
local function onTickTyreChains()
    GSVU4_TyreChains_TickCounter = GSVU4_TyreChains_TickCounter + 1
    if GSVU4_TyreChains_TickCounter < 60 then return end
    GSVU4_TyreChains_TickCounter = 0
    onEveryOneMinute()
end

if Events.OnTick then
    Events.OnTick.Add(onTickTyreChains)
end

Events.OnClientCommand.Add(onClientCommand)
