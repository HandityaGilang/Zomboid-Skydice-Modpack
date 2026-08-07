-- =============================================================================
-- Gore's SVU4 Core - Tyre Chains Upgrade Context Menu
-- =============================================================================
require "GoresSVU4TyreChains/GSVU4_TyreChains_Config"
require "GSVU4_TyreChains_TimedActions"

local TC = GSVU4_TyreChains

local function getInteractVehicle(playerObj)
    if not playerObj then return nil end

    if playerObj.getVehicle then
        local v = playerObj:getVehicle()
        if v then return v end
    end

    -- Prefer vanilla vehicle interaction helper if present.
    if ISVehicleMenu and ISVehicleMenu.getVehicleToInteractWith then
        local ok, vehicle = pcall(function() return ISVehicleMenu.getVehicleToInteractWith(playerObj) end)
        if ok and vehicle then return vehicle end
    end

    return nil
end

local function sendVehicleCommand(command, playerObj, vehicle)
    if not vehicle then return end

    local args = {
        vehicleId = vehicle.getId and vehicle:getId() or nil,
        x = math.floor(vehicle:getX() or 0),
        y = math.floor(vehicle:getY() or 0),
        z = math.floor(vehicle:getZ() or 0)
    }

    if isClient and isClient() then
        sendClientCommand("GSVU4TyreChains", command, args)
        if TC.requestVisualRefresh then
            pcall(function() TC.requestVisualRefresh(vehicle, TC.Config.VisualRefreshRetryFrames or 240) end)
        end
    else
        if command == "Install" then
            if TC.hasMechanics(playerObj, TC.Config.RequiredMechanicsInstall)
                and TC.hasTools(playerObj, TC.Config.InstallTools)
                and TC.hasMaterials(playerObj, TC.Config.InstallMaterials)
            then
                TC.consumeMaterials(playerObj, TC.Config.InstallMaterials)
                TC.install(vehicle, TC.Config.ChainInstallCondition)
                TC.addMechanicsXP(playerObj, 4)
            else

            end
        elseif command == "Remove" then
            if TC.hasMechanics(playerObj, TC.Config.RequiredMechanicsRemove)
                and TC.hasTools(playerObj, TC.Config.RemoveTools)
                and TC.isInstalled(vehicle)
            then
                TC.giveReturnMaterials(playerObj, vehicle)
                TC.remove(vehicle)
                TC.addMechanicsXP(playerObj, 2)
            else

            end
        elseif command == "RepairLight" then
            if TC.hasMechanics(playerObj, TC.Config.RequiredMechanicsRepair)
                and TC.hasTools(playerObj, TC.Config.LightRepairTools)
                and TC.hasMaterials(playerObj, TC.Config.LightRepairMaterials)
            then
                TC.consumeMaterials(playerObj, TC.Config.LightRepairMaterials)
                TC.repairChains(vehicle, TC.Config.LightRepairAmount)
                TC.addMechanicsXP(playerObj, 2)
            else

            end
        elseif command == "RepairHeavy" then
            if TC.hasMechanics(playerObj, TC.Config.RequiredMechanicsRepair)
                and TC.hasTools(playerObj, TC.Config.HeavyRepairTools)
                and TC.hasMaterials(playerObj, TC.Config.HeavyRepairMaterials)
            then
                TC.consumeMaterials(playerObj, TC.Config.HeavyRepairMaterials)
                TC.repairChains(vehicle, TC.Config.HeavyRepairAmount)
                TC.addMechanicsXP(playerObj, 2)
            else

            end
        elseif command == "NoisePulse" then
            if addSound then addSound(vehicle, vehicle:getX(), vehicle:getY(), vehicle:getZ(), TC.Config.WeldingStyleNoiseRadius, TC.Config.WeldingStyleNoiseVolume) end
        elseif command == "Toggle" then
            if TC.isInstalled(vehicle) then TC.remove(vehicle) else TC.install(vehicle, TC.Config.ChainInstallCondition) end
        end
        if TC.requestVisualRefresh then
            pcall(function() TC.requestVisualRefresh(vehicle, TC.Config.VisualRefreshRetryFrames or 240) end)
        end
    end
end

function GSVU4_TyreChains.sendVehicleCommand(command, playerObj, vehicle)
    sendVehicleCommand(command, playerObj, vehicle)
end

local function addStatusOption(context, vehicle)
    local data = TC.getData(vehicle)
    local label = "Tyre Chains: Not installed"
    if data and data.installed then
        label = "Tyre Chains: " .. tostring(data.condition or 0) .. "%"
        if data.state then label = label .. " / " .. tostring(data.state) end
    elseif data and data.state == "BROKEN" then
        label = "Tyre Chains: Broken"
    end

    local opt = context:addOption(label, nil, nil)
    if opt then opt.notAvailable = true end
end

local function addDisabledRequirement(context, text)
    local opt = context:addOption(text, nil, nil)
    if opt then opt.notAvailable = true end
end

local function isInstallReady(playerObj)
    return TC.hasMechanics(playerObj, TC.Config.RequiredMechanicsInstall)
        and TC.hasTools(playerObj, TC.Config.InstallTools)
        and TC.hasMaterials(playerObj, TC.Config.InstallMaterials)
end

local function isRemoveReady(playerObj, vehicle)
    return TC.isInstalled(vehicle)
        and TC.hasMechanics(playerObj, TC.Config.RequiredMechanicsRemove)
        and TC.hasTools(playerObj, TC.Config.RemoveTools)
end

local function isLightRepairReady(playerObj)
    return TC.hasMechanics(playerObj, TC.Config.RequiredMechanicsRepair)
        and TC.hasTools(playerObj, TC.Config.LightRepairTools)
        and TC.hasMaterials(playerObj, TC.Config.LightRepairMaterials)
end

local function isHeavyRepairReady(playerObj)
    return TC.hasMechanics(playerObj, TC.Config.RequiredMechanicsRepair)
        and TC.hasTools(playerObj, TC.Config.HeavyRepairTools)
        and TC.hasMaterials(playerObj, TC.Config.HeavyRepairMaterials)
end

local function getCondition(vehicle)
    local data = TC.getData(vehicle)
    if data then return data.condition or 0 end
    return 0
end

local function queueTyreChainAction(playerObj, vehicle, command, totalTime, actionLabel)
    if not GSVU4_TyreChains.queueTimedVehicleAction then
        sendVehicleCommand(command, playerObj, vehicle)
        return
    end

    GSVU4_TyreChains.queueTimedVehicleAction(playerObj, vehicle, command, totalTime, actionLabel)
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, isPreflight)
    if isPreflight then return end

    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    local vehicle = getInteractVehicle(playerObj)
    if not vehicle then return end

    local sub = nil
    local root = context:addOption("SVU4 Vehicle Upgrades", nil, nil)
    if ISContextMenu and ISContextMenu.getNew and context.addSubMenu then
        sub = ISContextMenu:getNew(context)
        context:addSubMenu(root, sub)
    else
        sub = context
    end

    addStatusOption(sub, vehicle)

    if TC.isInstalled(vehicle) then
        local remove = sub:addOption("Remove Tyre Chains", playerObj, function()
            queueTyreChainAction(playerObj, vehicle, "Remove", TC.Config.RemoveTime, "Removing tyre chains")
        end)
        if not isRemoveReady(playerObj, vehicle) and remove then remove.notAvailable = true end
        addDisabledRequirement(sub, "Remove requires: " .. TC.getRequirementText("Remove", vehicle))

        if getCondition(vehicle) < TC.Config.ChainInstallCondition then
            local light = sub:addOption("Repair Tyre Chains - Light", playerObj, function()
                queueTyreChainAction(playerObj, vehicle, "RepairLight", TC.Config.LightRepairTime, "Repairing tyre chains")
            end)
            if not isLightRepairReady(playerObj) and light then light.notAvailable = true end
            addDisabledRequirement(sub, "Light repair: " .. TC.getRequirementText("RepairLight", vehicle))

            local heavy = sub:addOption("Repair Tyre Chains - Heavy", playerObj, function()
                queueTyreChainAction(playerObj, vehicle, "RepairHeavy", TC.Config.HeavyRepairTime, "Repairing tyre chains")
            end)
            if not isHeavyRepairReady(playerObj) and heavy then heavy.notAvailable = true end
            addDisabledRequirement(sub, "Heavy repair: " .. TC.getRequirementText("RepairHeavy", vehicle))
        end
    else
        local install = sub:addOption("Install Tyre Chains", playerObj, function()
            queueTyreChainAction(playerObj, vehicle, "Install", TC.Config.InstallTime, "Installing tyre chains")
        end)
        if not isInstallReady(playerObj) and install then install.notAvailable = true end
        addDisabledRequirement(sub, "Install requires: " .. TC.getRequirementText("Install", vehicle))
    end

end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
