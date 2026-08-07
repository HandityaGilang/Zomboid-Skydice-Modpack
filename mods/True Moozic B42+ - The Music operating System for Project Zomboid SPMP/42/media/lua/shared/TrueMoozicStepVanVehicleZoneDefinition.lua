local function registerTrueMoozicStepVan()
    if not VehicleZoneDistribution then return end

    -- Honour sandbox toggle. Default DISABLED when SandboxVars/option is unavailable
    -- (on dedicated servers OnGameBoot can run before SandboxVars are loaded; a
    -- true-fallback there made the van spawn even when the option was off).
    local enabled = false
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

-- Register when sandbox vars are available. OnGameBoot runs before world vehicle
-- spawning but (on dedicated servers) can run BEFORE SandboxVars load, so re-apply
-- on later events too — the function is idempotent and removes entries when disabled.
Events.OnGameBoot.Add(registerTrueMoozicStepVan)
if Events.OnInitWorld then
    Events.OnInitWorld.Add(registerTrueMoozicStepVan)
end
if Events.OnLoadedMapZones then
    Events.OnLoadedMapZones.Add(registerTrueMoozicStepVan)
end
if Events.OnGameStart then
    Events.OnGameStart.Add(registerTrueMoozicStepVan)
end
if Events.OnServerStarted then
    Events.OnServerStarted.Add(registerTrueMoozicStepVan)
end

