--========================================================
-- Gore's SVU4 Vanilla Cars - Filtered Air Intake visuals
--========================================================

GSVU4VV = GSVU4VV or {}
GSVU4Core = GSVU4Core or {}

local MODELS = {
    CarNormal = "GSVU4_FilteredAirIntake_CarNormal",
    CarWagon = "GSVU4_FilteredAirIntake_CarWagon",
    LuxuryCar = "GSVU4_FilteredAirIntake_LuxuryCar",
    SUV = "GSVU4_FilteredAirIntake_SUV",
    PickUp = "GSVU4_FilteredAirIntake_PickUp",
    PickUpVan = "GSVU4_FilteredAirIntake_PickUp",
    SmallCar = "GSVU4_FilteredAirIntake_SmallCar",
    SmallCar02 = "GSVU4_FilteredAirIntake_SmallCar02",
    SportsCar = "GSVU4_FilteredAirIntake_SportsCar",
    ModernCar = "GSVU4_FilteredAirIntake_CarModern",
    CarModern = "GSVU4_FilteredAirIntake_CarModern",
    ModernCar2 = "GSVU4_FilteredAirIntake_CarModern2",
    CarModern2 = "GSVU4_FilteredAirIntake_CarModern2",
    Van = "GSVU4_FilteredAirIntake_Van",
    StepVan = "GSVU4_FilteredAirIntake_StepVan",
    OffRoad = "GSVU4_FilteredAirIntake_OffRoad",
    DashRoamer = "GSVU4_FilteredAirIntake_DashRoamer",
    GMCVan = "GSVU4_FilteredAirIntake_GMCVan",
    RaceCar = "GSVU4_FilteredAirIntake_RaceCar",
}

local function stripBase(name)
    if not name then return nil end
    return tostring(name):gsub("^[^%.]+%.", "")
end

local function scriptName(vehicle)
    if not vehicle then return nil end
    if vehicle.getScriptName then
        local ok, value = pcall(function() return vehicle:getScriptName() end)
        if ok and value then return stripBase(value) end
    end
    if vehicle.getScript then
        local ok, script = pcall(function() return vehicle:getScript() end)
        if ok and script then
            if script.getName then
                local okN, value = pcall(function() return script:getName() end)
                if okN and value then return stripBase(value) end
            end
            if script.getFullName then
                local okN, value = pcall(function() return script:getFullName() end)
                if okN and value then return stripBase(value) end
            end
        end
    end
    return nil
end

local function familyFor(vehicle)
    local name = scriptName(vehicle)
    if not name then return nil end
    if GSVU4VV.FamilyByVehicle then
        local family = GSVU4VV.FamilyByVehicle[name] or GSVU4VV.FamilyByVehicle[stripBase(name)]
        if family then return family end
    end
    for _, family in ipairs(GSVU4VV.Families or {}) do
        for _, vehicleName in ipairs(family.vehicles or {}) do
            if stripBase(vehicleName) == name then return family end
        end
    end
    return nil
end

local function visualPart(vehicle, family)
    if not vehicle or not family or not vehicle.getPartById then return nil end
    local ids = { family.lifecycleAnchor, family.visualAnchor, "EngineDoor" }
    local seen = {}
    for _, id in ipairs(ids) do
        if id and not seen[id] then
            seen[id] = true
            local ok, part = pcall(function() return vehicle:getPartById(id) end)
            if ok and part then return part end
        end
    end
    return nil
end

local function installed(vehicle)
    local md = vehicle and vehicle.getModData and vehicle:getModData() or nil
    local upgrade = md and md.gUpgrades and md.gUpgrades.FilteredAirIntake or nil
    return type(upgrade) == "table" and (tonumber(upgrade.health) or 100) > 0
end

local Applied = setmetatable({}, { __mode = "k" })

local function apply(vehicle, force)
    local family = familyFor(vehicle)
    if not family then return false end
    local model = MODELS[family.id] or MODELS[family.suffix]
    if not model then return false end
    local part = visualPart(vehicle, family)
    if not part or not part.setModelVisible then return false end
    local visible = installed(vehicle)
    if not force and Applied[vehicle] == visible then return true end
    Applied[vehicle] = visible
    local ok = pcall(function() part:setModelVisible(model, visible) end)
    return ok
end

GSVU4_ApplyFilteredAirIntakeVisual = apply

local pack = {
    applyUpgrade = function(vehicle, upgradeId, grade)
        if tostring(upgradeId or "") ~= "FilteredAirIntake" then return false end
        return apply(vehicle, true)
    end,
    applyVehicle = function(vehicle)
        return apply(vehicle, false)
    end,
}

if GSVU4Core.RegisterExternalVisualPack then
    GSVU4Core.RegisterExternalVisualPack("GSVU4VanillaFilteredAirIntake", pack)
else
    GSVU4Core.ExternalVisualPacks = GSVU4Core.ExternalVisualPacks or {}
    GSVU4Core.ExternalVisualPacks.GSVU4VanillaFilteredAirIntake = pack
end

if Events and Events.OnEnterVehicle then
    Events.OnEnterVehicle.Add(function(player)
        local vehicle = player and player.getVehicle and player:getVehicle() or nil
        if vehicle then apply(vehicle, true) end
    end)
end
