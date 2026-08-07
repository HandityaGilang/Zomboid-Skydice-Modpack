-- =============================================================================
-- Gore's SVU4 Vanilla Cars - Tyre Chains Visual Bridge
--
-- SVU3 used Wheels Protection by adding a model named ATAProtection to each
-- Tire* part.  SVU4 tyre chains now mirror that behaviour for tire-mounted
-- chain templates, while also supporting the SVU4 hidden-anchor chain models.
-- =============================================================================
require "GoresSVU4TyreChains/GSVU4_TyreChains_Config"

local TC = GSVU4_TyreChains
local refreshQueue = {}
local tickCounter = 0
local appliedVisualState = setmetatable({}, { __mode = "k" })

local VanillaChainModels = {
    "GSVU4_SVU3_SportsCar_TireChains_Left",
    "GSVU4_SVU3_SportsCar_TireChains_Right",
    "GSVU4_RaceCar_TireChains_Left",
    "GSVU4_RaceCar_TireChains_Right",
    "SVU_Chains_FL_CarModern", "SVU_Chains_FR_CarModern", "SVU_Chains_RL_CarModern", "SVU_Chains_RR_CarModern",
    "SVU_Chains_FL_CarModern2", "SVU_Chains_FR_CarModern2", "SVU_Chains_RL_CarModern2", "SVU_Chains_RR_CarModern2",
    "SVU_Chains_FL_CarNormal", "SVU_Chains_FR_CarNormal", "SVU_Chains_RL_CarNormal", "SVU_Chains_RR_CarNormal",
    "SVU_Chains_FL_CarWagon", "SVU_Chains_FR_CarWagon", "SVU_Chains_RL_CarWagon", "SVU_Chains_RR_CarWagon",
    "SVU_Chains_FL_SmallCar", "SVU_Chains_FR_SmallCar", "SVU_Chains_RL_SmallCar", "SVU_Chains_RR_SmallCar",
    "SVU_Chains_FL_SmallCar02", "SVU_Chains_FR_SmallCar02", "SVU_Chains_RL_SmallCar02", "SVU_Chains_RR_SmallCar02",
    "SVU_Chains_FL_LuxuryCar", "SVU_Chains_FR_LuxuryCar", "SVU_Chains_RL_LuxuryCar", "SVU_Chains_RR_LuxuryCar",
    "SVU_Chains_FL_OffRoad", "SVU_Chains_FR_OffRoad", "SVU_Chains_RL_OffRoad", "SVU_Chains_RR_OffRoad",
    "SVU_Chains_FL_PickUp", "SVU_Chains_FR_PickUp", "SVU_Chains_RL_PickUp", "SVU_Chains_RR_PickUp",
    "SVU_Chains_FL_SUV", "SVU_Chains_FR_SUV", "SVU_Chains_RL_SUV", "SVU_Chains_RR_SUV",
    "SVU_Chains_FL_StepVan", "SVU_Chains_FR_StepVan", "SVU_Chains_RL_StepVan", "SVU_Chains_RR_StepVan",
    "SVU_Chains_FL_Van", "SVU_Chains_FR_Van", "SVU_Chains_RL_Van", "SVU_Chains_RR_Van",
    "SVU_Chains_FL_DashRoamer", "SVU_Chains_FR_DashRoamer", "SVU_Chains_RL_DashRoamer", "SVU_Chains_RR_DashRoamer",
    "SVU_Chains_FL_GMCVan", "SVU_Chains_FR_GMCVan", "SVU_Chains_RL_GMCVan", "SVU_Chains_RR_GMCVan",
}


local function addUniqueVisualName(name)
    if not name or not TC or not TC.Config then return end
    TC.Config.VisualModelNames = TC.Config.VisualModelNames or {}
    for _, existing in ipairs(TC.Config.VisualModelNames) do
        if existing == name then return end
    end
    table.insert(TC.Config.VisualModelNames, name)
end

for _, name in ipairs(VanillaChainModels) do
    addUniqueVisualName(name)
end
addUniqueVisualName("ATAProtection")


-- SVU3/ATA2 did not place chain meshes on the body anchor. It added a model
-- called ATAProtection directly to each Tire* part, with a different file per
-- wheel. SVU4 now injects those same tire-slot model blocks into the vehicle
-- scripts, then toggles ATAProtection on the Tire* parts.
local TyreTemplateInjected = {}
local TyreChainFamilies = {
    CarNormal = { FL="SVU_Chains_FL_CarNormal", FR="SVU_Chains_FR_CarNormal", RL="SVU_Chains_RL_CarNormal", RR="SVU_Chains_RR_CarNormal" },
    CarWagon = { FL="SVU_Chains_FL_CarWagon", FR="SVU_Chains_FR_CarWagon", RL="SVU_Chains_RL_CarWagon", RR="SVU_Chains_RR_CarWagon" },
    SmallCar = { FL="SVU_Chains_FL_SmallCar", FR="SVU_Chains_FR_SmallCar", RL="SVU_Chains_RL_SmallCar", RR="SVU_Chains_RR_SmallCar" },
    SmallCar02 = { FL="SVU_Chains_FL_SmallCar02", FR="SVU_Chains_FR_SmallCar02", RL="SVU_Chains_RL_SmallCar02", RR="SVU_Chains_RR_SmallCar02" },
    SmallCar2 = { FL="SVU_Chains_FL_SmallCar02", FR="SVU_Chains_FR_SmallCar02", RL="SVU_Chains_RL_SmallCar02", RR="SVU_Chains_RR_SmallCar02" },
    LuxuryCar = { FL="SVU_Chains_FL_LuxuryCar", FR="SVU_Chains_FR_LuxuryCar", RL="SVU_Chains_RL_LuxuryCar", RR="SVU_Chains_RR_LuxuryCar" },
    SUV = { FL="SVU_Chains_FL_SUV", FR="SVU_Chains_FR_SUV", RL="SVU_Chains_RL_SUV", RR="SVU_Chains_RR_SUV" },
    PickUp = { FL="SVU_Chains_FL_PickUp", FR="SVU_Chains_FR_PickUp", RL="SVU_Chains_RL_PickUp", RR="SVU_Chains_RR_PickUp" },
    PickUpVan = { FL="SVU_Chains_FL_PickUp", FR="SVU_Chains_FR_PickUp", RL="SVU_Chains_RL_PickUp", RR="SVU_Chains_RR_PickUp" },
    ModernCar = { FL="SVU_Chains_FL_CarModern", FR="SVU_Chains_FR_CarModern", RL="SVU_Chains_RL_CarModern", RR="SVU_Chains_RR_CarModern" },
    CarModern = { FL="SVU_Chains_FL_CarModern", FR="SVU_Chains_FR_CarModern", RL="SVU_Chains_RL_CarModern", RR="SVU_Chains_RR_CarModern" },
    ModernCar2 = { FL="SVU_Chains_FL_CarModern2", FR="SVU_Chains_FR_CarModern2", RL="SVU_Chains_RL_CarModern2", RR="SVU_Chains_RR_CarModern2" },
    CarModern2 = { FL="SVU_Chains_FL_CarModern2", FR="SVU_Chains_FR_CarModern2", RL="SVU_Chains_RL_CarModern2", RR="SVU_Chains_RR_CarModern2" },
    Van = { FL="SVU_Chains_FL_Van", FR="SVU_Chains_FR_Van", RL="SVU_Chains_RL_Van", RR="SVU_Chains_RR_Van" },
    StepVan = { FL="SVU_Chains_FL_StepVan", FR="SVU_Chains_FR_StepVan", RL="SVU_Chains_RL_StepVan", RR="SVU_Chains_RR_StepVan" },
    OffRoad = { FL="SVU_Chains_FL_OffRoad", FR="SVU_Chains_FR_OffRoad", RL="SVU_Chains_RL_OffRoad", RR="SVU_Chains_RR_OffRoad" },
    DashRoamer = { FL="SVU_Chains_FL_DashRoamer", FR="SVU_Chains_FR_DashRoamer", RL="SVU_Chains_RL_DashRoamer", RR="SVU_Chains_RR_DashRoamer" },
    GMCVan = { FL="SVU_Chains_FL_GMCVan", FR="SVU_Chains_FR_GMCVan", RL="SVU_Chains_RL_GMCVan", RR="SVU_Chains_RR_GMCVan" },
    SportsCar = { FL="GSVU4_SVU3_SportsCar_TireChains_Left", FR="GSVU4_SVU3_SportsCar_TireChains_Right", RL="GSVU4_SVU3_SportsCar_TireChains_Left", RR="GSVU4_SVU3_SportsCar_TireChains_Right" },
    RaceCar = { FL="GSVU4_RaceCar_TireChains_Left", FR="GSVU4_RaceCar_TireChains_Right", RL="GSVU4_RaceCar_TireChains_Left", RR="GSVU4_RaceCar_TireChains_Right" },
}

local function stripBaseVehicleName(name)
    if not name then return nil end
    return tostring(name):gsub("^Base%.", "")
end

local function getTyreModelSetForFamily(family)
    if not family then return nil end
    return TyreChainFamilies[tostring(family.id or "")]
        or TyreChainFamilies[tostring(family.suffix or "")]
        or TyreChainFamilies[tostring(family.vehicleFamily or "")]
end

local function isSmallCar02TyreFamily(family)
    if not family then return false end
    local id = tostring(family.id or "")
    local suffix = tostring(family.suffix or "")
    local vehicleFamily = tostring(family.vehicleFamily or "")
    return id == "SmallCar02" or suffix == "SmallCar02" or vehicleFamily == "SmallCar02"
end
local function isSportsCarTyreFamily(family)
    if not family then return false end
    local id = tostring(family.id or "")
    local suffix = tostring(family.suffix or "")
    local vehicleFamily = tostring(family.vehicleFamily or "")
    return id == "SportsCar" or suffix == "SportsCar" or vehicleFamily == "SportsCar"
end

local function isRaceCarTyreFamily(family)
    if not family then return false end
    local id = tostring(family.id or "")
    local suffix = tostring(family.suffix or "")
    local vehicleFamily = tostring(family.vehicleFamily or "")
    return id == "RaceCar" or suffix == "RaceCar" or vehicleFamily == "RaceCar"
end

local function isBodyAnchorChainFamily(family)
    -- B42.20 accepts body-anchor visibility calls for these vehicles but does
    -- not render the attached chain meshes. Use the same per-tyre
    -- ATAProtection route as the working CarNormal family.
    return false
end


local function buildTyreParam(files)
    if not files then return nil end
    return "part TireFrontLeft { model ATAProtection { file = " .. tostring(files.FL) .. ", } } " ..
           "part TireRearLeft { model ATAProtection { file = " .. tostring(files.RL) .. ", } } " ..
           "part TireFrontRight { model ATAProtection { file = " .. tostring(files.FR) .. ", } } " ..
           "part TireRearRight { model ATAProtection { file = " .. tostring(files.RR) .. ", } }"
end

local function injectTyreParam(vehicleName, files)
    if not ScriptManager or not ScriptManager.instance or not vehicleName or not files then return false end
    local short = stripBaseVehicleName(vehicleName)
    if not short or short == "" then return false end
    local key = short .. ":GSVU4TyreChainsTireSlots"
    if TyreTemplateInjected[key] then return true end
    local vehicleScript = ScriptManager.instance:getVehicle("Base." .. short)
    if not vehicleScript then return false end
    local param = buildTyreParam(files)
    if not param then return false end
    local ok, err = pcall(function() vehicleScript:Load(short, "{" .. param .. "}") end)
    if ok then
        TyreTemplateInjected[key] = true
        return true
    end

    return false
end

local function injectVanillaTyreChainSlots()
    if not GSVU4VV or type(GSVU4VV.Families) ~= "table" then return end
    local attempted, applied = 0, 0
    for _, family in ipairs(GSVU4VV.Families) do
        local files = getTyreModelSetForFamily(family)
        if files and not isBodyAnchorChainFamily(family) then
            for _, vehicleName in ipairs(family.vehicles or {}) do
                attempted = attempted + 1
                if injectTyreParam(vehicleName, files) then applied = applied + 1 end
            end
        end
    end

end

local function getVehicleFamilyForTyres(vehicle)
    if not vehicle or not GSVU4VV or not GSVU4VV.FamilyByVehicle then return nil end
    local scriptName = nil
    if vehicle.getScriptName then
        local ok, value = pcall(function() return vehicle:getScriptName() end)
        if ok and value then scriptName = tostring(value) end
    end
    if not scriptName and vehicle.getScript then
        local ok, script = pcall(function() return vehicle:getScript() end)
        if ok and script then
            if script.getFullName then local ok2, value = pcall(function() return script:getFullName() end); if ok2 and value then scriptName = tostring(value) end end
            if not scriptName and script.getName then local ok2, value = pcall(function() return script:getName() end); if ok2 and value then scriptName = tostring(value) end end
        end
    end
    if not scriptName then return nil end
    return GSVU4VV.FamilyByVehicle[scriptName] or GSVU4VV.FamilyByVehicle["Base." .. stripBaseVehicleName(scriptName)] or GSVU4VV.FamilyByVehicle[stripBaseVehicleName(scriptName)]
end

local function vehicleHasChains(vehicle)
    if TC and TC.isInstalled and TC.isInstalled(vehicle) then return true end
    if vehicle and vehicle.getModData then
        local md = vehicle:getModData()
        local entry = md and md.gUpgrades and md.gUpgrades.TyreChains
        if type(entry) == "table" and entry.installed ~= false then
            local hp = tonumber(entry.condition or entry.health or entry.hp or 0) or 0
            if hp > 0 or entry.grade ~= nil then return true end
        end
    end
    return false
end

local function setPartModelVisible(part, modelName, visible)
    if not part or not modelName or not part.setModelVisible then return false end
    local ok = pcall(function() part:setModelVisible(tostring(modelName), visible == true) end)
    return ok == true
end

local function getPartId(part)
    if not part or not part.getId then return nil end
    local ok, id = pcall(function() return part:getId() end)
    if ok and id then return tostring(id) end
    return nil
end

local function forEachVehiclePart(vehicle, callback)
    if not vehicle or not callback then return end

    local seen = {}
    if vehicle.getPartCount and vehicle.getPartByIndex then
        local okCount, count = pcall(function() return vehicle:getPartCount() end)
        if okCount and count then
            for i = 0, count - 1 do
                local okPart, part = pcall(function() return vehicle:getPartByIndex(i) end)
                if okPart and part then
                    local id = getPartId(part)
                    if id then seen[id] = true end
                    callback(part, id)
                end
            end
        end
    end

    if vehicle.getPartById then
        for _, partId in ipairs(TC.Config.TyrePartIds or {}) do
            if partId and not seen[tostring(partId)] then
                local okPart, part = pcall(function() return vehicle:getPartById(partId) end)
                if okPart and part then callback(part, tostring(partId)) end
            end
        end
    end
end

local function applyKnownHiddenAnchorModels(vehicle, visible)
    -- Do not show SVU_Chains_* on body anchors. The SVU3/ATA2 method puts
    -- wheel protection on the Tire* parts as ATAProtection; showing the raw
    -- chain models on body anchors causes misplaced side-of-vehicle chains.
    -- We still hide any old/body-anchor chain models for saves from earlier
    if not vehicle then return 0 end
    local hits = 0
    forEachVehiclePart(vehicle, function(part)
        for _, modelName in ipairs(TC.Config.VisualModelNames or {}) do
            local name = tostring(modelName or "")
            if name ~= "ATAProtection" then
                local isChain = string.find(name, "SVU_Chains_", 1, true) or string.find(name, "TireChains", 1, true)
                if isChain then
                    if setPartModelVisible(part, name, false) then hits = hits + 1 end
                elseif setPartModelVisible(part, name, visible) then
                    hits = hits + 1
                end
            end
        end
    end)
    return hits
end

local function applySVU3TireProtectionModels(vehicle, visible)
    if not vehicle then return 0 end
    local family = getVehicleFamilyForTyres(vehicle)
    if isBodyAnchorChainFamily(family) then
        -- SportsCar and RaceCar keep their tyre-chain visuals on hidden
        -- body-anchor routes.
        -- The ATAProtection route still flashes visible during spawn/stream on this family.
        local hits = 0
        forEachVehiclePart(vehicle, function(part, id)
            if id and string.find(id, "^Tire") then
                if setPartModelVisible(part, "ATAProtection", false) then hits = hits + 1 end
            end
        end)
        return hits
    end
    local files = getTyreModelSetForFamily(family)

    if family and files then
        local scriptName = nil
        if vehicle.getScriptName then local ok, value = pcall(function() return vehicle:getScriptName() end); if ok and value then scriptName = tostring(value) end end
        if scriptName then injectTyreParam(scriptName, files) end
    end
    local hits = 0
    forEachVehiclePart(vehicle, function(part, id)
        if id and string.find(id, "^Tire") then
            -- This is the actual SVU3 / ATA2 Wheels Protection model slot.
            -- The model file is different per wheel, but the visible model name
            -- on the part is always ATAProtection.
            if setPartModelVisible(part, "ATAProtection", visible) then hits = hits + 1 end
        end
    end)
    return hits
end

local function applySmallCar02BodyAnchorChains(vehicle, visible)
    if not vehicle then return 0 end
    local family = getVehicleFamilyForTyres(vehicle)
    if not isSmallCar02TyreFamily(family) then return 0 end
    if not vehicle.getPartById then return 0 end
    local ok, part = pcall(function() return vehicle:getPartById("GSVU4_SVU3_SmallCar02_BodyAnchor") end)
    if ok and part then
        return setPartModelVisible(part, "GSVU4_ChainsFallback_SmallCar02", visible == true) and 1 or 0
    end
    return 0
end

local function applyPerformanceCarBodyAnchorChains(vehicle, visible)
    if not vehicle or not vehicle.getPartById then return 0 end
    local family = getVehicleFamilyForTyres(vehicle)
    local anchorId, leftModel, rightModel = nil, nil, nil

    if isSportsCarTyreFamily(family) then
        anchorId = "GSVU4_SVU3_SportsCar_BodyAnchor"
        leftModel = "GSVU4_SVU3_SportsCar_TireChains_Left"
        rightModel = "GSVU4_SVU3_SportsCar_TireChains_Right"
    elseif isRaceCarTyreFamily(family) then
        anchorId = "GSVU4_SVU3_RaceCar_BodyAnchor"
        leftModel = "GSVU4_RaceCar_TireChains_Left"
        rightModel = "GSVU4_RaceCar_TireChains_Right"
    else
        return 0
    end

    local ok, part = pcall(function() return vehicle:getPartById(anchorId) end)
    if not ok or not part then return 0 end
    local hits = 0
    if setPartModelVisible(part, leftModel, visible == true) then hits = hits + 1 end
    if setPartModelVisible(part, rightModel, visible == true) then hits = hits + 1 end
    return hits
end

local function callVanillaVisualRefresh(vehicle)
    if not vehicle then return end

    local candidates = {
        "GSVU4VV_ApplyVehicle",
        "GSVU4_VanillaCars_ApplyVehicle",
        "GSVU4_ApplyVehicleVisuals",
        "VehicleArmor_ApplyVehicleVisuals"
    }

    for _, name in ipairs(candidates) do
        local fn = _G[name]
        if type(fn) == "function" then pcall(fn, vehicle) end
    end

    if VehicleArmor_Visuals and VehicleArmor_Visuals.ApplyVehicle then
        pcall(function() VehicleArmor_Visuals.ApplyVehicle(vehicle) end)
    end
end

local function callExternalTyreChainVisuals(vehicle)
    if not vehicle then return end
    if GSVU4Core and GSVU4Core.ApplyExternalUpgradeVisualPacks then
        pcall(function() GSVU4Core.ApplyExternalUpgradeVisualPacks(vehicle, "TyreChains", "Standard") end)
    elseif GSVU4Core and GSVU4Core.ApplyExternalVisualPacks then
        pcall(function() GSVU4Core.ApplyExternalVisualPacks(vehicle, nil) end)
    end
end

function TC.applyVisuals(vehicle, force)
    if not vehicle then return false end

    local visible = vehicleHasChains(vehicle)
    local state = visible and "installed" or "removed"

    -- B42.20 can visibly rebuild a vehicle model when setModelVisible is
    -- repeatedly called with the same value. Skip stable-state polling passes;
    -- explicit install/spawn retries may still force a short reassertion.
    if force ~= true and appliedVisualState[vehicle] == state then
        return false
    end

    -- Keep this pass limited to the chain routes themselves. SportsCar and
    -- RaceCar now use ATAProtection on the four Tire* parts; their obsolete
    -- body-anchor chain aliases must remain hidden.
    applyKnownHiddenAnchorModels(vehicle, visible)
    applySVU3TireProtectionModels(vehicle, visible)
    applySmallCar02BodyAnchorChains(vehicle, visible)
    appliedVisualState[vehicle] = state
    return true
end

function TC.requestVisualRefresh(vehicle, frames)
    if not vehicle then return end
    local key = TC.getVehicleKey(vehicle)
    -- One immediate pass plus at most two one-second retries is enough for
    -- B42.20 to bind the injected Tire* slots without causing periodic pulsing.
    local retryFrames = math.min(tonumber(frames) or 60, 60)
    refreshQueue[key] = {
        vehicle = vehicle,
        frames = retryFrames,
        step = 0
    }
    TC.applyVisuals(vehicle, true)
end

local function processRefreshQueue()
    for key, row in pairs(refreshQueue) do
        if not row or not row.vehicle or (row.frames or 0) <= 0 then
            refreshQueue[key] = nil
        else
            row.frames = row.frames - 30
            row.step = (row.step or 0) + 1
            TC.applyVisuals(row.vehicle, true)
        end
    end
end

local function processPlayerVehicle(playerObj)
    if not playerObj then return end
    if playerObj.getVehicle then
        local vehicle = playerObj:getVehicle()
        if vehicle then TC.applyVisuals(vehicle, false) end
    end
end

local function onEveryOneMinute()
    if getNumActivePlayers and getSpecificPlayer then
        for i = 0, getNumActivePlayers() - 1 do
            processPlayerVehicle(getSpecificPlayer(i))
        end
    end
end

local function onTick()
    tickCounter = tickCounter + 1
    if tickCounter < 30 then return end
    tickCounter = 0
    processRefreshQueue()
end

local function onEnterVehicle(character)
    processPlayerVehicle(character)
end


-- -----------------------------------------------------------------------------
-- v8 proximity / paused-tick cleanup
--
-- The Tire* ATAProtection slot is the only vanilla route found so far that both
-- positions the chain meshes correctly and shows them after SVU4 install.
-- Its weakness is that B42 makes the new model visible by default on newly
-- spawned vehicles until a vehicle interaction refresh occurs.  Earlier tests
-- tried hiding the model in the Tire* script itself, but that could hide the
-- normal tyre meshes too.  This version leaves the tyre script alone and instead
-- performs a small client-side visibility correction around local players, even
-- -----------------------------------------------------------------------------
local proximityRefreshCounter = 0
local proximityRefreshState = {}

local function safeGetVehicleXY(vehicle)
    if not vehicle then return nil, nil end
    local x, y = nil, nil
    if vehicle.getX then local ok, value = pcall(function() return vehicle:getX() end); if ok then x = tonumber(value) end end
    if vehicle.getY then local ok, value = pcall(function() return vehicle:getY() end); if ok then y = tonumber(value) end end
    return x, y
end

local function safeGetPlayerXY(playerObj)
    if not playerObj then return nil, nil end
    local x, y = nil, nil
    if playerObj.getX then local ok, value = pcall(function() return playerObj:getX() end); if ok then x = tonumber(value) end end
    if playerObj.getY then local ok, value = pcall(function() return playerObj:getY() end); if ok then y = tonumber(value) end end
    return x, y
end

local function refreshVehicleStateIfNeeded(vehicle, force)
    if not vehicle then return end
    local key = TC.getVehicleKey and TC.getVehicleKey(vehicle) or tostring(vehicle)
    local visible = vehicleHasChains(vehicle)
    local state = tostring(visible)
    local row = proximityRefreshState[key]

    -- Reassert several times for newly noticed vehicles because the model slots
    -- can finish binding a few frames after the vehicle object becomes visible.
    if force or not row or row.state ~= state or (row.passes or 0) < 3 then
        TC.applyVisuals(vehicle, true)
        if not row or row.state ~= state then
            row = { state = state, passes = 1 }
        else
            row.passes = (row.passes or 0) + 1
        end
        proximityRefreshState[key] = row
    end
end

local function processInteractVehicleForPlayer(playerObj, force)
    if not playerObj then return end

    if playerObj.getVehicle then
        local ok, vehicle = pcall(function() return playerObj:getVehicle() end)
        if ok and vehicle then refreshVehicleStateIfNeeded(vehicle, force == true) end
    end

    -- Use the vanilla interaction helper where available. This usually catches
    -- exactly the vehicle the player is looking at without scanning the
    -- whole cell.
    if ISVehicleMenu and ISVehicleMenu.getVehicleToInteractWith then
        local ok, vehicle = pcall(function() return ISVehicleMenu.getVehicleToInteractWith(playerObj) end)
        if ok and vehicle then refreshVehicleStateIfNeeded(vehicle, force == true) end
    end
end

local function iterLoadedVehicles(callback)
    if not callback or not getCell then return end
    local cell = getCell()
    if not cell or not cell.getVehicles then return end
    local ok, vehicles = pcall(function() return cell:getVehicles() end)
    if not ok or not vehicles then return end

    if vehicles.size and vehicles.get then
        local okSize, size = pcall(function() return vehicles:size() end)
        if okSize and size then
            for i = 0, size - 1 do
                local okVehicle, vehicle = pcall(function() return vehicles:get(i) end)
                if okVehicle and vehicle then callback(vehicle) end
            end
        end
    elseif type(vehicles) == "table" then
        for _, vehicle in pairs(vehicles) do
            if vehicle then callback(vehicle) end
        end
    end
end

local function isVehicleNearAnyLocalPlayer(vehicle, maxDistSq)
    local vx, vy = safeGetVehicleXY(vehicle)
    if not vx or not vy then return false end
    if not getNumActivePlayers or not getSpecificPlayer then return false end

    for i = 0, getNumActivePlayers() - 1 do
        local playerObj = getSpecificPlayer(i)
        local px, py = safeGetPlayerXY(playerObj)
        if px and py then
            local dx, dy = vx - px, vy - py
            if (dx * dx + dy * dy) <= maxDistSq then return true end
        end
    end
    return false
end

local function processNearbyVehicles(force)
    if getNumActivePlayers and getSpecificPlayer then
        for i = 0, getNumActivePlayers() - 1 do
            processInteractVehicleForPlayer(getSpecificPlayer(i), force)
        end
    end

    -- Secondary safety net for cars that are on-screen/nearby but not currently
    -- returned by ISVehicleMenu.getVehicleToInteractWith.  Kept radius-limited to
    -- avoid bringing back the old expensive full-map visual polling behaviour.
    iterLoadedVehicles(function(vehicle)
        if isVehicleNearAnyLocalPlayer(vehicle, 35 * 35) then
            refreshVehicleStateIfNeeded(vehicle, force == true)
        end
    end)
end

local function onTickEvenPaused()
    proximityRefreshCounter = proximityRefreshCounter + 1
    -- Poll nearby state about twice per second, but stable vehicles are not
    -- repainted after their finite initial passes.
    if proximityRefreshCounter % 15 == 0 then
        processNearbyVehicles(false)
    end
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, _isPreflight)
    local playerObj = nil
    if type(playerNum) == "number" and getSpecificPlayer then
        playerObj = getSpecificPlayer(playerNum)
    elseif playerNum and playerNum.getX then
        playerObj = playerNum
    end
    processInteractVehicleForPlayer(playerObj, true)
end

local function onCreatePlayer(playerNum, playerObj)
    processNearbyVehicles(true)
end

local function onVehicleCreated(vehicle)
    if not vehicle then return end

    -- OnVehicleCreated is the earliest practical client hook for newly spawned
    -- or streamed cars. The request performs one immediate correction and then
    -- keeps only a short finite retry window while visual parts finish binding.
    TC.requestVisualRefresh(vehicle, 60)
end

injectVanillaTyreChainSlots()
if Events.OnGameBoot then Events.OnGameBoot.Add(injectVanillaTyreChainSlots) end
if Events.OnGameStart then Events.OnGameStart.Add(injectVanillaTyreChainSlots) end
if Events.OnLoad then Events.OnLoad.Add(injectVanillaTyreChainSlots) end

Events.EveryOneMinute.Add(onEveryOneMinute)
if Events.OnTick then Events.OnTick.Add(onTick) end
if Events.OnTickEvenPaused then Events.OnTickEvenPaused.Add(onTickEvenPaused) end
if Events.OnEnterVehicle then Events.OnEnterVehicle.Add(onEnterVehicle) end
if Events.OnExitVehicle then Events.OnExitVehicle.Add(onEnterVehicle) end
if Events.OnFillWorldObjectContextMenu then Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu) end
if Events.OnCreatePlayer then Events.OnCreatePlayer.Add(onCreatePlayer) end
if Events.OnVehicleCreated then Events.OnVehicleCreated.Add(onVehicleCreated) end
