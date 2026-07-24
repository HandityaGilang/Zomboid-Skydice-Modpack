local function registerTrueMoozicStepVan()
    if not VehicleZoneDistribution then return end

    -- Honour sandbox toggle. Default to enabled when SandboxVars/option is unavailable.
    local enabled = true
    if SandboxVars and SandboxVars.PZTrueMusicSandbox and SandboxVars.PZTrueMusicSandbox.SpawnTrueMoozicVan ~= nil then
        enabled = SandboxVars.PZTrueMusicSandbox.SpawnTrueMoozicVan and true or false
    end

    if enabled then
        -- Standard parking / road zones
        VehicleZoneDistribution.parkingstall.vehicles["Base.TrueMoozicStepVan"]  = {index = -1, spawnChance = 1};
        VehicleZoneDistribution.bad.vehicles["Base.TrueMoozicStepVan"]           = {index = -1, spawnChance = 1};
        VehicleZoneDistribution.medium.vehicles["Base.TrueMoozicStepVan"]        = {index = -1, spawnChance = 1};
        VehicleZoneDistribution.good.vehicles["Base.TrueMoozicStepVan"]          = {index = -1, spawnChance = 1};
    else
        -- Disabled: ensure no entries are present so vehicle never rolls.
        if VehicleZoneDistribution.parkingstall and VehicleZoneDistribution.parkingstall.vehicles then
            VehicleZoneDistribution.parkingstall.vehicles["Base.TrueMoozicStepVan"] = nil
        end
        if VehicleZoneDistribution.bad and VehicleZoneDistribution.bad.vehicles then
            VehicleZoneDistribution.bad.vehicles["Base.TrueMoozicStepVan"] = nil
        end
        if VehicleZoneDistribution.medium and VehicleZoneDistribution.medium.vehicles then
            VehicleZoneDistribution.medium.vehicles["Base.TrueMoozicStepVan"] = nil
        end
        if VehicleZoneDistribution.good and VehicleZoneDistribution.good.vehicles then
            VehicleZoneDistribution.good.vehicles["Base.TrueMoozicStepVan"] = nil
        end
    end
end

-- Register when sandbox vars are available. OnGameBoot runs before world vehicle spawning.
Events.OnGameBoot.Add(registerTrueMoozicStepVan)
-- Also re-apply on world load (server) in case sandbox values change between sessions.
Events.OnLoad.Add(registerTrueMoozicStepVan)

