--========================================================
-- Gore's SVU4 Vanilla Vehicles - Roof Lighting Visual Registration
--========================================================

GSVU4VanillaCars = GSVU4VanillaCars or {}
GSVU4VV = GSVU4VV or {}
GSVU4 = GSVU4 or {}
GSVU4.RoofLights = GSVU4.RoofLights or {}

local PREFIX = "[Gore's SVU4 Vanilla Vehicles RoofLights] "

local function row(name)
    return { main = "GSVU4_RoofLights_" .. name, bulbs = "GSVU4_RoofLightsBulbs_" .. name }
end

local map = {
    CarNormal       = row("CarNormal"),
    Taxi            = row("CarNormal"),
    Taxi2           = row("CarNormal"),
    CarTaxi         = row("CarNormal"),
    CarTaxi2        = row("CarNormal"),
    CarNormalTaxi   = row("CarNormal"),
    CarLights       = row("CarNormal"),
    CarPolice       = row("CarNormal"),
    CarRanger       = row("CarNormal"),
    CarSheriff      = row("CarNormal"),
    CarLightsKST    = row("DashRoamer"),

    CarStationWagon = row("CarWagon"),
    StationWagon    = row("CarWagon"),
    StationWagon2   = row("CarWagon"),
    Wagon           = row("CarWagon"),
    Wagon2          = row("CarWagon"),

    SmallCar        = row("SmallCar"),
    -- SmallCar2       = row("SmallCar02"),
    -- SmallCar02      = row("SmallCar02"),

    CarLuxury       = row("LuxuryCar"),
    Luxury          = row("LuxuryCar"),
    Luxury2         = row("LuxuryCar"),

    SportsCar       = row("SportsCar"),
    RaceCar         = row("RaceCar"),
    RaceCar12       = row("RaceCar"),
    RaceCar34       = row("RaceCar"),
    RaceCar58       = row("RaceCar"),

    CarModern       = row("CarModern"),
    CarModern2      = row("CarModern2"),

    SUV             = row("SUV"),
    SUV2            = row("SUV"),
    OffRoad         = row("OffRoad"),

    PickUpTruck     = row("PickUp"),
    PickUpTruckMccoy = row("PickUp"),
    PickUpTruckLights = row("PickUp"),
    PickUpTruckLightsFire = row("PickUp"),
    PickUpTruckLightsPolice = row("PickUp"),
    PickUpTruckLightsRanger = row("PickUp"),
    PickUpVan       = row("PickUp"),
    PickUpVanMccoy  = row("PickUp"),
    PickUpVanLights = row("PickUp"),
    PickUpVanLightsFire = row("PickUp"),
    PickUpVanLightsPolice = row("PickUp"),
    PickUpVanLightsRanger = row("PickUp"),

    StepVan         = row("StepVan"),
    StepVanMail     = row("StepVan"),

    Van             = row("Van"),
    VanAmbulance    = row("Van"),
    VanSeats        = row("Van"),
    VanSpecial      = row("Van"),

    DashRoamer      = row("DashRoamer"),
    DashElite       = row("DashRoamer"),
    GMCVan          = row("GMCVan"),
}

local patterns = {
    { "gmc",          row("GMCVan") },
    { "dash",         row("DashRoamer") },
    { "carlightskst", row("DashRoamer") },
    { "stationwagon", row("CarWagon") },
    { "wagon",        row("CarWagon") },
    { "luxury",       row("LuxuryCar") },
    { "race",         row("RaceCar") },
    { "sport",        row("SportsCar") },
    { "modern2",      row("CarModern2") },
    { "modern",       row("CarModern") },
    -- { "smallcar02",   row("SmallCar02") },
    -- { "smallcar2",    row("SmallCar02") },
    { "small",        row("SmallCar") },
    { "suv",          row("SUV") },
    { "offroad",      row("OffRoad") },
    { "pickup",       row("PickUp") },
    { "stepvan",      row("StepVan") },
    { "ambulance",    row("Van") },
    { "van",          row("Van") },
    { "taxi",         row("CarNormal") },
    { "police",       row("CarNormal") },
    { "ranger",       row("CarNormal") },
    { "fire",         row("CarNormal") },
    { "carnormal",    row("CarNormal") },
}

local function register()
    if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.registerVisualModels then
        GSVU4.RoofLights.registerVisualModels(map, patterns)

        return true
    end

    GSVU4.RoofLights.VisualModelByScriptName = GSVU4.RoofLights.VisualModelByScriptName or {}
    GSVU4.RoofLights.VisualModelPatterns = GSVU4.RoofLights.VisualModelPatterns or {}

    for k, v in pairs(map) do
        GSVU4.RoofLights.VisualModelByScriptName[k] = v
    end
    for _, p in ipairs(patterns) do
        GSVU4.RoofLights.VisualModelPatterns[#GSVU4.RoofLights.VisualModelPatterns + 1] = p
    end

    return true
end

register()

-- had a SmallCar02 mapping from another registration path/default table. Keep the fallback
-- bridge active, but make the normal Core RoofLights mapping empty for SmallCar02.
local function gsvu4vvBlockSmallCar02CoreRoofLightRoute()
    GSVU4 = GSVU4 or {}
    GSVU4.RoofLights = GSVU4.RoofLights or {}

    local empty = { main = "", bulbs = "" }
    local keys = {
        "SmallCar02",
        "SmallCar2",
        "Base.SmallCar02",
        "Base.SmallCar2",
        "smallcar02",
        "smallcar2",
        "base.smallcar02",
        "base.smallcar2",
    }

    GSVU4.RoofLights.VisualModelByScriptName = GSVU4.RoofLights.VisualModelByScriptName or {}
    for _, key in ipairs(keys) do
        GSVU4.RoofLights.VisualModelByScriptName[key] = empty
    end

    -- Also strip SmallCar02/SmallCar2 patterns from Core's pattern fallback table if present.
    if type(GSVU4.RoofLights.VisualModelPatterns) == "table" then
        local kept = {}
        for _, row in ipairs(GSVU4.RoofLights.VisualModelPatterns) do
            local pattern = row and row[1] and string.lower(tostring(row[1])) or ""
            if pattern ~= "smallcar02" and pattern ~= "smallcar2" then
                kept[#kept + 1] = row
            end
        end
        GSVU4.RoofLights.VisualModelPatterns = kept
    end
end

gsvu4vvBlockSmallCar02CoreRoofLightRoute()

--========================================================
-- Fallback visual bridge for Core's Roof Lighting System
--
-- The Core-injected GSVU4RoofLights part is kept, but these models are also
-- added to the existing SVU3 body-anchor parts used by the armour visuals.
-- Those anchors are already proven to update correctly, so this gives the
-- roof lights a reliable visual refresh path after install/uninstall.
--========================================================

local fallbackByModelFamily = {
    CarNormal  = { anchor = "GSVU4_SVU3_CarNormal_BodyAnchor",   main = "GSVU4_RoofLightsFallback_CarNormal",   bulbs = "GSVU4_RoofLightsFallbackBulbs_CarNormal" },
    CarWagon   = { anchor = "GSVU4_SVU3_CarWagon_BodyAnchor",    main = "GSVU4_RoofLightsFallback_CarWagon",    bulbs = "GSVU4_RoofLightsFallbackBulbs_CarWagon" },
    LuxuryCar  = { anchor = "GSVU4_SVU3_LuxuryCar_BodyAnchor",   main = "GSVU4_RoofLightsFallback_LuxuryCar",   bulbs = "GSVU4_RoofLightsFallbackBulbs_LuxuryCar" },
    SUV        = { anchor = "GSVU4_SVU3_SUV_BodyAnchor",         main = "GSVU4_RoofLightsFallback_SUV",         bulbs = "GSVU4_RoofLightsFallbackBulbs_SUV" },
    PickUp     = { anchor = "GSVU4_SVU3_PickUp_BodyAnchor",      main = "GSVU4_RoofLightsFallback_PickUp",      bulbs = "GSVU4_RoofLightsFallbackBulbs_PickUp" },
    SmallCar   = { anchor = "GSVU4_SVU3_SmallCar_BodyAnchor",    main = "GSVU4_RoofLightsFallback_SmallCar",    bulbs = "GSVU4_RoofLightsFallbackBulbs_SmallCar" },
    SmallCar02 = { anchor = "GSVU4_SVU3_SmallCar02_BodyAnchor",  main = "GSVU4_RoofLightsFallback_SmallCar02",  bulbs = "GSVU4_RoofLightsFallbackBulbs_SmallCar02" },
    SportsCar  = { anchor = "GSVU4_SVU3_SportsCar_BodyAnchor",   main = "GSVU4_RoofLightsFallback_SportsCar",   bulbs = "GSVU4_RoofLightsFallbackBulbs_SportsCar" },
    CarModern  = { anchor = "GSVU4_SVU3_CarModern_BodyAnchor",   main = "GSVU4_RoofLightsFallback_CarModern",   bulbs = "GSVU4_RoofLightsFallbackBulbs_CarModern" },
    CarModern2 = { anchor = "GSVU4_SVU3_CarModern2_BodyAnchor",  main = "GSVU4_RoofLightsFallback_CarModern2",  bulbs = "GSVU4_RoofLightsFallbackBulbs_CarModern2" },
    Van        = { anchor = "GSVU4_SVU3_Van_BodyAnchor",         main = "GSVU4_RoofLightsFallback_Van",         bulbs = "GSVU4_RoofLightsFallbackBulbs_Van" },
    StepVan    = { anchor = "GSVU4_SVU3_StepVan_BodyAnchor",     main = "GSVU4_RoofLightsFallback_StepVan",     bulbs = "GSVU4_RoofLightsFallbackBulbs_StepVan" },
    OffRoad    = { anchor = "GSVU4_SVU3_OffRoad_BodyAnchor",     main = "GSVU4_RoofLightsFallback_OffRoad",     bulbs = "GSVU4_RoofLightsFallbackBulbs_OffRoad" },
    DashRoamer = { anchor = "GSVU4_SVU3_DashRoamer_BodyAnchor",  main = "GSVU4_RoofLightsFallback_DashRoamer",  bulbs = "GSVU4_RoofLightsFallbackBulbs_DashRoamer" },
    GMCVan     = { anchor = "GSVU4_SVU3_GMCVan_BodyAnchor",      main = "GSVU4_RoofLightsFallback_GMCVan",      bulbs = "GSVU4_RoofLightsFallbackBulbs_GMCVan" },
    RaceCar    = { anchor = "GSVU4_SVU3_RaceCar_BodyAnchor",     main = "GSVU4_RoofLightsFallback_RaceCar",     bulbs = "GSVU4_RoofLightsFallbackBulbs_RaceCar" },
}

local function getVehicleScriptNameForFallback(vehicle)
    if not vehicle then return nil end
    local script = nil
    if vehicle.getScript then
        local ok, value = pcall(function() return vehicle:getScript() end)
        if ok then script = value end
    end
    if script and script.getName then
        local ok, value = pcall(function() return script:getName() end)
        if ok and value then return tostring(value) end
    end
    if script and script.getFullName then
        local ok, value = pcall(function() return script:getFullName() end)
        if ok and value then return tostring(value):gsub("^[^%.]+%.", "") end
    end
    if vehicle.getScriptName then
        local ok, value = pcall(function() return vehicle:getScriptName() end)
        if ok and value then return tostring(value):gsub("^[^%.]+%.", "") end
    end
    return nil
end

local function resolveFallbackFamily(vehicle)
    local scriptName = getVehicleScriptNameForFallback(vehicle)
    if not scriptName then return nil end
    if scriptName == "SmallCar02" or scriptName == "SmallCar2" then return "SmallCar02" end
    local direct = map[scriptName]
    if direct and direct.main then
        local family = tostring(direct.main):gsub("^GSVU4_RoofLights_", "")
        return family
    end
    local lower = string.lower(scriptName)
    for _, rowData in ipairs(patterns or {}) do
        if rowData and rowData[1] and rowData[2] and string.find(lower, tostring(rowData[1]), 1, true) then
            local family = tostring(rowData[2].main or ""):gsub("^GSVU4_RoofLights_", "")
            return family
        end
    end
    return nil
end

local function safeToggle(part, modelName, visible)
    if not part or not modelName or not part.setModelVisible then return false end
    local ok = pcall(function() part:setModelVisible(tostring(modelName), visible == true) end)
    return ok == true
end

local function hasCoreRoofLightsInstalled(vehicle)
    local md = vehicle and vehicle.getModData and vehicle:getModData() or nil
    local up = md and md.gUpgrades and md.gUpgrades.RoofLights
    return type(up) == "table" and up.grade ~= nil
end

function GSVU4VV.ApplyRoofLightsUpgradeVisual(vehicle)
    if not vehicle then return false end
    local visible = hasCoreRoofLightsInstalled(vehicle)
    local family = resolveFallbackFamily(vehicle)
    local spec = family and fallbackByModelFamily[family] or nil
    if not spec and family == "SportsCar" then spec = fallbackByModelFamily.SportsCar end
    if not spec then return false end
    local part = vehicle.getPartById and vehicle:getPartById(spec.anchor) or nil
    if not part then return false end

    safeToggle(part, spec.main, visible)
    safeToggle(part, spec.bulbs, visible)

    local pmd = part:getModData()
    pmd.GSVU4RoofLightsFallback = visible and { family = family, main = spec.main, bulbs = spec.bulbs } or nil
    -- visual-only local state; no part-model packet transmit
    -- Vanilla damage overlay is refreshed once by Core after visual retries settle.
    return true
end

-- B42.19 load-safety helper.
-- cell:getVehicles() can be a Java/userdata collection during load. In some
-- contexts size() exists but get() is nil, so every collection call is guarded.
local function gsvu4vvForEachLoadedVehicle(callback)
    if not callback or not getCell then return false end

    local cell = getCell()
    if not cell or not cell.getVehicles then return false end

    local ok, vehicles = pcall(function() return cell:getVehicles() end)
    if not ok or not vehicles then return false end

    if type(vehicles) == "table" then
        for _, vehicle in pairs(vehicles) do
            if vehicle and callback(vehicle) then return true end
        end
        return false
    end

    if vehicles.size and vehicles.get then
        local okSize, count = pcall(function() return vehicles:size() end)
        count = okSize and tonumber(count) or 0
        for i = 0, count - 1 do
            local okGet, vehicle = pcall(function() return vehicles:get(i) end)
            if okGet and vehicle and callback(vehicle) then return true end
        end
        return false
    end

    if vehicles.iterator then
        local okIterator, iterator = pcall(function() return vehicles:iterator() end)
        if okIterator and iterator then
            while iterator.hasNext do
                local okHasNext, hasNext = pcall(function() return iterator:hasNext() end)
                if not okHasNext or not hasNext then break end

                local okNext, vehicle = pcall(function() return iterator:next() end)
                if okNext and vehicle and callback(vehicle) then return true end
            end
        end
    end

    return false
end

local function gsvu4vvRefreshConcreteVehicle(vehicle)
    if vehicle then GSVU4VV.ApplyRoofLightsUpgradeVisual(vehicle) end
end

local function refreshNearbyRoofLights()
    if not getPlayer then return end
    local player = getPlayer()
    if not player then return end

    if player.getVehicle then
        local okCurrent, currentVehicle = pcall(function() return player:getVehicle() end)
        if okCurrent then gsvu4vvRefreshConcreteVehicle(currentVehicle) end
    end
    if player.getNearVehicle then
        local okNear, nearVehicle = pcall(function() return player:getNearVehicle() end)
        if okNear then gsvu4vvRefreshConcreteVehicle(nearVehicle) end
    end

    local px, py = player:getX(), player:getY()
    gsvu4vvForEachLoadedVehicle(function(vehicle)
        if vehicle and vehicle.getX and vehicle.getY then
            local okPos, vx, vy = pcall(function() return vehicle:getX(), vehicle:getY() end)
            if okPos and vx and vy and math.abs(vx - px) < 40 and math.abs(vy - py) < 40 then
                GSVU4VV.ApplyRoofLightsUpgradeVisual(vehicle)
            end
        end
        return false
    end)
end


if Events and Events.OnGameBoot then Events.OnGameBoot.Add(gsvu4vvBlockSmallCar02CoreRoofLightRoute) end
if Events and Events.OnGameStart then Events.OnGameStart.Add(gsvu4vvBlockSmallCar02CoreRoofLightRoute) end
if Events and Events.OnLoad then Events.OnLoad.Add(gsvu4vvBlockSmallCar02CoreRoofLightRoute) end

if Events and Events.OnLoad then Events.OnLoad.Add(refreshNearbyRoofLights) end
if Events and Events.OnEnterVehicle then
    Events.OnEnterVehicle.Add(function(character)
        if character and character.getVehicle then GSVU4VV.ApplyRoofLightsUpgradeVisual(character:getVehicle()) end
    end)
end
if Events and Events.OnExitVehicle then
    Events.OnExitVehicle.Add(function(character)
        if character and character.getNearVehicle then GSVU4VV.ApplyRoofLightsUpgradeVisual(character:getNearVehicle()) end
    end)
end


-- SmallCar02 roof-light load refresh.
-- On a loaded save, the vehicle can exist before the fallback body-anchor visuals
-- have been refreshed. Re-run the fallback visual pass briefly after load/start so
-- installed SmallCar02 roof lights appear without needing the player to enter the car.
local gsvu4vvSmallCar02LoadRefreshTicks = 0

local function gsvu4vvRefreshSmallCar02RoofLightsNearby()
    if not getPlayer then return end

    local player = getPlayer()
    if not player then return end

    if player.getVehicle then
        local okCurrent, currentVehicle = pcall(function() return player:getVehicle() end)
        if okCurrent and currentVehicle then
            local currentScriptName = getVehicleScriptNameForFallback(currentVehicle)
            if currentScriptName == "SmallCar02" or currentScriptName == "SmallCar2" then
                GSVU4VV.ApplyRoofLightsUpgradeVisual(currentVehicle)
            end
        end
    end
    if player.getNearVehicle then
        local okNear, nearVehicle = pcall(function() return player:getNearVehicle() end)
        if okNear and nearVehicle then
            local nearScriptName = getVehicleScriptNameForFallback(nearVehicle)
            if nearScriptName == "SmallCar02" or nearScriptName == "SmallCar2" then
                GSVU4VV.ApplyRoofLightsUpgradeVisual(nearVehicle)
            end
        end
    end

    local px, py = player:getX(), player:getY()
    gsvu4vvForEachLoadedVehicle(function(vehicle)
        if vehicle and vehicle.getX and vehicle.getY then
            local okPos, vx, vy = pcall(function() return vehicle:getX(), vehicle:getY() end)
            if okPos and vx and vy and math.abs(vx - px) < 60 and math.abs(vy - py) < 60 then
                local scriptName = getVehicleScriptNameForFallback(vehicle)
                if scriptName == "SmallCar02" or scriptName == "SmallCar2" then
                    GSVU4VV.ApplyRoofLightsUpgradeVisual(vehicle)
                end
            end
        end
        return false
    end)
end

local function gsvu4vvStartSmallCar02LoadRefresh()
    gsvu4vvSmallCar02LoadRefreshTicks = 300
    gsvu4vvBlockSmallCar02CoreRoofLightRoute()
    gsvu4vvRefreshSmallCar02RoofLightsNearby()
end

local function gsvu4vvSmallCar02LoadRefreshTick()
    if gsvu4vvSmallCar02LoadRefreshTicks <= 0 then return end
    gsvu4vvSmallCar02LoadRefreshTicks = gsvu4vvSmallCar02LoadRefreshTicks - 1

    -- Refresh every 30 ticks for a short window after load/start.
    if (gsvu4vvSmallCar02LoadRefreshTicks % 30) == 0 then
        gsvu4vvBlockSmallCar02CoreRoofLightRoute()
        gsvu4vvRefreshSmallCar02RoofLightsNearby()
    end
end

if Events and Events.OnGameStart then Events.OnGameStart.Add(gsvu4vvStartSmallCar02LoadRefresh) end
if Events and Events.OnLoad then Events.OnLoad.Add(gsvu4vvStartSmallCar02LoadRefresh) end
if Events and Events.OnCreatePlayer then Events.OnCreatePlayer.Add(gsvu4vvStartSmallCar02LoadRefresh) end
if Events and Events.OnPlayerUpdate then Events.OnPlayerUpdate.Add(gsvu4vvSmallCar02LoadRefreshTick) end
