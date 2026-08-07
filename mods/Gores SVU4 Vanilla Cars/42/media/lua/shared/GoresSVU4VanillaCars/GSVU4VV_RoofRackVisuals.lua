--========================================================
-- Gore's SVU4 Vanilla Vehicles - Roof Rack Visual Registration
--
-- Core injects the native GSVU4RoofRack container part.
-- This optional visual pack supplies vanilla-vehicle model mappings.
--========================================================

GSVU4VanillaCars = GSVU4VanillaCars or {}
GSVU4VV = GSVU4VV or {}
GSVU4 = GSVU4 or {}
GSVU4.RoofRack = GSVU4.RoofRack or {}

local PREFIX = "[Gore's SVU4 Vanilla Vehicles RoofRack] "

local map = {
    CarNormal       = "GSVU4_Rack_CarNormal",
    Taxi            = "GSVU4_Rack_CarNormal",
    Taxi2           = "GSVU4_Rack_CarNormal",
    CarTaxi         = "GSVU4_Rack_CarNormal",
    CarTaxi2        = "GSVU4_Rack_CarNormal",
    CarNormalTaxi   = "GSVU4_Rack_CarNormal",
    CarLights       = "GSVU4_Rack_CarNormal",
    CarPolice       = "GSVU4_Rack_CarNormal",
    CarRanger       = "GSVU4_Rack_CarNormal",
    CarSheriff      = "GSVU4_Rack_CarNormal",
    CarLightsKST    = "GSVU4_Rack_DashRoamer",

    CarStationWagon = "GSVU4_Rack_CarWagon",
    StationWagon    = "GSVU4_Rack_CarWagon",
    StationWagon2   = "GSVU4_Rack_CarWagon",
    Wagon           = "GSVU4_Rack_CarWagon",
    Wagon2          = "GSVU4_Rack_CarWagon",

    SmallCar        = "GSVU4_Rack_SmallCar",
    SmallCar2       = {
        model = "GSVU4_Rack_SmallCar02",
        offset = "0.0000 0.0800 0.0400",
    },
    SmallCar02      = {
        model = "GSVU4_Rack_SmallCar02",
        offset = "0.0000 0.0800 0.0400",
    },

    CarLuxury       = "GSVU4_Rack_LuxuryCar",
    Luxury          = "GSVU4_Rack_LuxuryCar",
    Luxury2         = "GSVU4_Rack_LuxuryCar",

    SportsCar       = "GSVU4_Rack_SportsCar",
    RaceCar         = "GSVU4_Rack_RaceCar",
    RaceCar12       = "GSVU4_Rack_RaceCar",
    RaceCar34       = "GSVU4_Rack_RaceCar",
    RaceCar58       = "GSVU4_Rack_RaceCar",

    CarModern       = "GSVU4_Rack_CarModern",
    CarModern2      = "GSVU4_Rack_CarModern2",

    SUV             = "GSVU4_Rack_SUV",
    SUV2            = "GSVU4_Rack_SUV",
    OffRoad         = "GSVU4_Rack_OffRoad",

    PickUpTruck     = "GSVU4_Rack_PickUp",
    PickUpTruckMccoy = "GSVU4_Rack_PickUp",
    PickUpTruckLights = "GSVU4_Rack_PickUp",
    PickUpTruckLightsFire = "GSVU4_Rack_PickUp",
    PickUpTruckLightsPolice = "GSVU4_Rack_PickUp",
    PickUpTruckLightsRanger = "GSVU4_Rack_PickUp",
    PickUpVan       = "GSVU4_Rack_PickUp",
    PickUpVanMccoy  = "GSVU4_Rack_PickUp",
    PickUpVanLights = "GSVU4_Rack_PickUp",
    PickUpVanLightsFire = "GSVU4_Rack_PickUp",
    PickUpVanLightsPolice = "GSVU4_Rack_PickUp",
    PickUpVanLightsRanger = "GSVU4_Rack_PickUp",

    StepVan         = "GSVU4_Rack_StepVan",
    StepVanMail     = "GSVU4_Rack_StepVan",

    Van             = "GSVU4_Rack_Van",
    VanAmbulance    = "GSVU4_Rack_Van",
    VanSeats        = "GSVU4_Rack_Van",
    VanSpecial      = "GSVU4_Rack_Van",

    DashRoamer      = "GSVU4_Rack_DashRoamer",
    DashElite       = "GSVU4_Rack_DashRoamer",
    GMCVan          = "GSVU4_Rack_GMCVan",
}

local patterns = {
    { "gmc",          "GSVU4_Rack_GMCVan" },
    { "dash",         "GSVU4_Rack_DashRoamer" },
    { "carlightskst",  "GSVU4_Rack_DashRoamer" },
    { "stationwagon", "GSVU4_Rack_CarWagon" },
    { "wagon",        "GSVU4_Rack_CarWagon" },
    { "luxury",       "GSVU4_Rack_LuxuryCar" },
    { "race",         "GSVU4_Rack_RaceCar" },
    { "sport",        "GSVU4_Rack_SportsCar" },
    { "modern2",      "GSVU4_Rack_CarModern2" },
    { "modern",       "GSVU4_Rack_CarModern" },
    { "smallcar02", {
        model = "GSVU4_Rack_SmallCar02",
        offset = "0.0000 0.0800 0.0400",
    } },
    { "smallcar2", {
        model = "GSVU4_Rack_SmallCar02",
        offset = "0.0000 0.0800 0.0400",
    } },
    { "small",        "GSVU4_Rack_SmallCar" },
    { "suv",          "GSVU4_Rack_SUV" },
    { "offroad",      "GSVU4_Rack_OffRoad" },
    { "pickup",       "GSVU4_Rack_PickUp" },
    { "stepvan",      "GSVU4_Rack_StepVan" },
    { "ambulance",    "GSVU4_Rack_Van" },
    { "van",          "GSVU4_Rack_Van" },
    { "taxi",         "GSVU4_Rack_CarNormal" },
    { "police",       "GSVU4_Rack_CarNormal" },
    { "ranger",       "GSVU4_Rack_CarNormal" },
    { "fire",         "GSVU4_Rack_CarNormal" },
    { "carnormal",    "GSVU4_Rack_CarNormal" },
}

local function register()
    if GSVU4 and GSVU4.RoofRack and GSVU4.RoofRack.registerVisualModels then
        GSVU4.RoofRack.registerVisualModels(map, patterns)

        return true
    end

    GSVU4.RoofRack.VisualModelByScriptName = GSVU4.RoofRack.VisualModelByScriptName or {}
    GSVU4.RoofRack.VisualModelPatterns = GSVU4.RoofRack.VisualModelPatterns or {}

    for k, v in pairs(map) do
        GSVU4.RoofRack.VisualModelByScriptName[k] = v
    end
    for _, row in ipairs(patterns) do
        GSVU4.RoofRack.VisualModelPatterns[#GSVU4.RoofRack.VisualModelPatterns + 1] = row
    end

    return true
end

register()

-- SmallCar02 uses the same native GSVU4RoofRack lifecycle as CarNormal.
-- The visual pack only supplies the fitted model and offset. Core owns install,
-- uninstall, MP state and visibility.
local function gsvu4vvGetVehicleScriptName(vehicle)
    if not vehicle then return nil end
    if vehicle.getScriptName then
        local ok, value = pcall(function()
            return vehicle:getScriptName()
        end)
        if ok and value then
            return tostring(value):gsub("^Base%.", "")
        end
    end
    if vehicle.getScript then
        local okScript, script = pcall(function()
            return vehicle:getScript()
        end)
        if okScript and script then
            if script.getFullName then
                local ok, value = pcall(function()
                    return script:getFullName()
                end)
                if ok and value then
                    return tostring(value):gsub("^Base%.", "")
                end
            end
            if script.getName then
                local ok, value = pcall(function()
                    return script:getName()
                end)
                if ok and value then
                    return tostring(value):gsub("^Base%.", "")
                end
            end
        end
    end
    return nil
end

local function gsvu4vvForEachLoadedVehicle(callback)
    if not callback or not getCell then return end
    local cell = getCell()
    if not cell or not cell.getVehicles then return end
    local okVehicles, vehicles = pcall(function()
        return cell:getVehicles()
    end)
    if not okVehicles or not vehicles then return end

    if vehicles.size and vehicles.get then
        local okSize, size = pcall(function()
            return vehicles:size()
        end)
        if okSize and size then
            for i = 0, size - 1 do
                local okVehicle, vehicle = pcall(function()
                    return vehicles:get(i)
                end)
                if okVehicle and vehicle then callback(vehicle) end
            end
        end
    elseif type(vehicles) == "table" then
        for _, vehicle in pairs(vehicles) do
            if vehicle then callback(vehicle) end
        end
    end
end

local function gsvu4vvApplySmallCar02NativeRack(vehicle)
    local scriptName = gsvu4vvGetVehicleScriptName(vehicle)
    if scriptName ~= "SmallCar02" and scriptName ~= "SmallCar2" then
        return false
    end
    if GSVU4
    and GSVU4.RoofRack
    and GSVU4.RoofRack.SyncVisualOnly then
        return GSVU4.RoofRack.SyncVisualOnly(vehicle) == true
    end
    return false
end

-- RaceCar rack fallback visual route.
-- RaceCar variants need their own anchor instead of borrowing SportsCar's rack route.
local gsvu4vvRaceCarRackRefreshTicks = 0

local function gsvu4vvIsRaceCar(vehicle)
    local scriptName = gsvu4vvGetVehicleScriptName(vehicle)
    return scriptName == "RaceCar" or scriptName == "RaceCar12" or scriptName == "RaceCar34" or scriptName == "RaceCar58"
end

local function gsvu4vvRaceCarHasRack(vehicle)
    local md = vehicle and vehicle.getModData and vehicle:getModData() or nil
    local rack = md and md.gUpgrades and md.gUpgrades.RoofRack or nil
    if type(rack) == "table" then
        return rack.installed ~= false and rack.grade ~= nil
    end
    return rack ~= nil and rack ~= false
end

local function gsvu4vvApplyRaceCarRackFallback(vehicle)
    if not gsvu4vvIsRaceCar(vehicle) then return false end
    if not vehicle.getPartById then return false end
    local okPart, part = pcall(function() return vehicle:getPartById("GSVU4_SVU3_RaceCar_BodyAnchor") end)
    if not okPart or not part or not part.setModelVisible then return false end
    local visible = gsvu4vvRaceCarHasRack(vehicle)
    local ok = pcall(function() part:setModelVisible("GSVU4_RackFallback_RaceCar", visible == true) end)
    -- visual-only local state; no part-model packet transmit
    return ok == true
end

local function gsvu4vvRefreshRaceCarRackNearby()
    if getNumActivePlayers and getSpecificPlayer then
        for i = 0, getNumActivePlayers() - 1 do
            local playerObj = getSpecificPlayer(i)
            if playerObj and playerObj.getVehicle then
                local okVehicle, vehicle = pcall(function() return playerObj:getVehicle() end)
                if okVehicle and vehicle then gsvu4vvApplyRaceCarRackFallback(vehicle) end
            end
            if ISVehicleMenu and ISVehicleMenu.getVehicleToInteractWith then
                local okNear, nearVehicle = pcall(function() return ISVehicleMenu.getVehicleToInteractWith(playerObj) end)
                if okNear and nearVehicle then gsvu4vvApplyRaceCarRackFallback(nearVehicle) end
            end
        end
    end

    gsvu4vvForEachLoadedVehicle(function(vehicle)
        if gsvu4vvIsRaceCar(vehicle) then gsvu4vvApplyRaceCarRackFallback(vehicle) end
    end)
end

local function gsvu4vvStartRaceCarRackRefresh()
    gsvu4vvRaceCarRackRefreshTicks = 300
    gsvu4vvRefreshRaceCarRackNearby()
end

local function gsvu4vvRaceCarRackRefreshTick()
    if gsvu4vvRaceCarRackRefreshTicks <= 0 then return end
    gsvu4vvRaceCarRackRefreshTicks = gsvu4vvRaceCarRackRefreshTicks - 1
    if (gsvu4vvRaceCarRackRefreshTicks % 30) == 0 then gsvu4vvRefreshRaceCarRackNearby() end
end

GSVU4VV = GSVU4VV or {}
function GSVU4VV.ApplyRoofRackUpgradeVisual(vehicle)
    local a = gsvu4vvApplySmallCar02NativeRack(vehicle)
    local b = gsvu4vvApplyRaceCarRackFallback(vehicle)
    return a == true or b == true
end

if Events and Events.OnGameStart then Events.OnGameStart.Add(gsvu4vvStartRaceCarRackRefresh) end
if Events and Events.OnLoad then Events.OnLoad.Add(gsvu4vvStartRaceCarRackRefresh) end
if Events and Events.OnCreatePlayer then Events.OnCreatePlayer.Add(gsvu4vvStartRaceCarRackRefresh) end
if Events and Events.OnEnterVehicle then Events.OnEnterVehicle.Add(function(character)
    if character and character.getVehicle then
        local ok, vehicle = pcall(function() return character:getVehicle() end)
        if ok and vehicle then gsvu4vvApplyRaceCarRackFallback(vehicle) end
    end
end) end
if Events and Events.OnPlayerUpdate then Events.OnPlayerUpdate.Add(gsvu4vvRaceCarRackRefreshTick) end
