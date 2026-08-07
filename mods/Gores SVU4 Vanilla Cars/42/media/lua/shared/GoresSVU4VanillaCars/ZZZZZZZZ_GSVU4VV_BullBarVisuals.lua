--========================================================
-- Gore's SVU4 Vanilla Vehicles - Bull / Push Bar visuals
-- Uses existing SVU3 bullbar/pushbar meshes where available.
--========================================================

GSVU4VV = GSVU4VV or {}
GSVU4VanillaCars = GSVU4VanillaCars or {}

local PREFIX = "[Gore's SVU4 Vanilla Vehicles BullBar] "

local BullBarModelsByFamily = {
    CarNormal  = { Basic = "SVU_Bullbar_CarNormal_Small",  Standard = "SVU_Bullbar_CarNormal_Medium",  Military = "SVU_Bullbar_CarNormal_Large_Spiked" },
    CarWagon   = { Basic = "SVU_Bullbar_CarWagon_Small",   Standard = "SVU_Bullbar_CarWagon_Medium",   Military = "SVU_Bullbar_CarWagon_Large_Spiked" },
    LuxuryCar  = { Basic = "SVU_Bullbar_LuxuryCar_Small",  Standard = "SVU_Bullbar_LuxuryCar_Medium",  Military = "SVU_Bullbar_LuxuryCar_Large_Spiked" },
    SUV        = { Basic = "SVU_Bullbar_SUV_Small",        Standard = "SVU_Bullbar_SUV_Medium",        Military = "SVU_Bullbar_SUV_Large_Spiked" },
    PickUp     = { Basic = "SVU_Bullbar_PickUp_Small",     Standard = "SVU_Bullbar_PickUp_Medium",     Military = "SVU_Bullbar_PickUp_Large_Spiked" },
    CarModern  = { Basic = "SVU_Bullbar_CarModern_Small",  Standard = "SVU_Bullbar_CarModern_Medium",  Military = "SVU_Bullbar_CarModern_Large_Spiked" },
    CarModern2 = { Basic = "SVU_Bullbar_CarModern2_Small", Standard = "SVU_Bullbar_CarModern2_Medium", Military = "SVU_Bullbar_CarModern2_Large_Spiked" },
    Van        = { Basic = "SVU_Bullbar_Van_Small",        Standard = "SVU_Bullbar_Van_Medium",        Military = "SVU_Bullbar_Van_Large_Spiked" },
    StepVan    = { Basic = "SVU_Bullbar_StepVan_Small",    Standard = "SVU_Bullbar_StepVan_Medium",    Military = "SVU_Bullbar_StepVan_Large_Spiked" },
    OffRoad    = { Basic = "SVU_Bullbar_OffRoad_Small",    Standard = "SVU_Bullbar_OffRoad_Medium",    Military = "SVU_Bullbar_OffRoad_Large_Spiked" },
    SmallCar02 = {
        Basic = "GSVU4_SC02_NATIVE_BullBar_Basic",
        Standard = "GSVU4_SC02_NATIVE_BullBar_Standard",
        Military = "GSVU4_SC02_NATIVE_BullBar_Military",
    },
    SportsCar  = { Basic = "GSVU4_SVU3_SportsCar_Bullbar_LargeSpiked", Standard = "GSVU4_SVU3_SportsCar_Bullbar_LargeSpiked", Military = "GSVU4_SVU3_SportsCar_Bullbar_LargeSpiked" },
    RaceCar    = { Basic = "GSVU4_SVU3_SportsCar_Bullbar_LargeSpiked", Standard = "GSVU4_SVU3_SportsCar_Bullbar_LargeSpiked", Military = "GSVU4_SVU3_SportsCar_Bullbar_LargeSpiked" },
}

local function stripBase(name)
    if not name then return nil end
    return tostring(name):gsub("^[^%.]+%.", "")
end

local function getVehicleScriptName(vehicle)
    if not vehicle then return nil end
    if vehicle.getScriptName then
        local ok, value = pcall(function() return vehicle:getScriptName() end)
        if ok and value then return stripBase(value) end
    end
    if vehicle.getScript then
        local okS, script = pcall(function() return vehicle:getScript() end)
        if okS and script then
            if script.getName then local ok, value = pcall(function() return script:getName() end); if ok and value then return stripBase(value) end end
            if script.getFullName then local ok, value = pcall(function() return script:getFullName() end); if ok and value then return stripBase(value) end end
        end
    end
    return nil
end

local function getFamily(vehicle)
    local name = getVehicleScriptName(vehicle)
    if not name then return nil end
    if GSVU4VV and GSVU4VV.FamilyByVehicle then
        return GSVU4VV.FamilyByVehicle[name] or GSVU4VV.FamilyByVehicle[stripBase(name)]
    end
    for _, family in ipairs(GSVU4VV.Families or {}) do
        for _, v in ipairs(family.vehicles or {}) do
            if stripBase(v) == name then return family end
        end
    end
    return nil
end

local function getVisualPart(vehicle, family)
    if not vehicle or not family or not vehicle.getPartById then return nil end

    -- Most bull/push bar meshes live on the hidden SVU4/SVU3 body-anchor part.
    -- Some older vanilla-family profiles use EngineDoor as their armour visual anchor,
    -- which is fine for armour panels but can miss bullbar meshes on newer variants
    -- such as StepVan_Citr8 and StepVan_MobileLibrary. Prefer the lifecycle/body
    -- anchor for StepVan bullbars, then fall back to the original visual anchor.
    local partIds = {}

    -- SmallCar02 bullbars now live on EngineDoor beside its armor aliases.
    -- StepVan remains the only family that deliberately prefers lifecycleAnchor.
    if family.id == "SmallCar02" or family.suffix == "SmallCar02" then
        partIds[#partIds + 1] = "EngineDoor"
        partIds[#partIds + 1] = family.visualAnchor
        partIds[#partIds + 1] = family.lifecycleAnchor
    elseif family.id == "StepVan" or family.suffix == "StepVan" then
        partIds[#partIds + 1] = family.lifecycleAnchor
        partIds[#partIds + 1] = family.visualAnchor
    else
        partIds[#partIds + 1] = family.visualAnchor
        partIds[#partIds + 1] = family.lifecycleAnchor
    end

    local seen = {}
    for _, partId in ipairs(partIds) do
        if partId and not seen[partId] then
            seen[partId] = true
            local ok, part = pcall(function() return vehicle:getPartById(partId) end)
            if ok and part then return part end
        end
    end
    return nil
end

local function setModel(part, model, visible)
    if not part or not model or not part.setModelVisible then return false end
    local ok, err = pcall(function() part:setModelVisible(tostring(model), visible == true) end)
    if not ok then

        return false
    end
    return true
end

local function getInstalledBullBar(vehicle)
    local md = vehicle and vehicle.getModData and vehicle:getModData() or nil
    local up = md and md.gUpgrades and md.gUpgrades.BullBar or nil
    if type(up) == "table" and up.grade and (tonumber(up.health) or 100) > 0 then return up end
    return nil
end

local function getModelSpecForFamily(family)
    if not family then return nil end
    return BullBarModelsByFamily[family.id] or BullBarModelsByFamily[family.suffix]
end

local AppliedBullBarState = {}

local function getVehicleCacheKey(vehicle)
    if not vehicle then return nil end
    if vehicle.getOnlineID then
        local ok, value = pcall(function() return vehicle:getOnlineID() end)
        if ok and value ~= nil and tonumber(value) and tonumber(value) >= 0 then return "online:" .. tostring(value) end
    end
    if vehicle.getId then
        local ok, value = pcall(function() return vehicle:getId() end)
        if ok and value ~= nil then return "id:" .. tostring(value) end
    end
    local x, y, z = 0, 0, 0
    if vehicle.getX then local ok, value = pcall(function() return vehicle:getX() end); if ok then x = math.floor(tonumber(value) or 0) end end
    if vehicle.getY then local ok, value = pcall(function() return vehicle:getY() end); if ok then y = math.floor(tonumber(value) or 0) end end
    if vehicle.getZ then local ok, value = pcall(function() return vehicle:getZ() end); if ok then z = math.floor(tonumber(value) or 0) end end
    return "pos:" .. tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)
end

local function getTargetBullBarModel(vehicle, family, spec)
    local upgrade = getInstalledBullBar(vehicle)
    if not upgrade then return nil, "none" end
    local grade = tostring(upgrade.grade or "Basic")
    return spec[grade] or spec.Military or spec.Standard or spec.Basic, grade
end

function GSVU4_ApplyBullBarVisual(vehicle, force)
    if not vehicle then return false end
    local family = getFamily(vehicle)
    local spec = getModelSpecForFamily(family)
    if not family or not spec then return false end
    local part = getVisualPart(vehicle, family)
    if not part then return false end

    local targetModel, grade = getTargetBullBarModel(vehicle, family, spec)

    if force
    and (family.id == "SmallCar02" or family.suffix == "SmallCar02") then
        local partId = "unknown"
        if part.getId then
            local okId, value = pcall(function() return part:getId() end)
            if okId and value then partId = tostring(value) end
        end

    end

    local cacheKey = getVehicleCacheKey(vehicle) or tostring(vehicle)
    local stateKey = tostring(grade or "none") .. ":" .. tostring(targetModel or "none")

    -- Prevent visible flicker: do not repeatedly hide/re-show all bullbar models
    -- if the requested model is already the same as the last applied state.
    if not force and AppliedBullBarState[cacheKey] == stateKey then
        return true
    end
    AppliedBullBarState[cacheKey] = stateKey

    local seen = {}
    for _, model in pairs(spec) do
        if model and not seen[model] then
            seen[model] = true
            setModel(part, model, false)
        end
    end

    if targetModel then
        setModel(part, targetModel, true)
    end
    -- visual-only local state; no part-model packet transmit
    -- Core performs one delayed vanilla damage-overlay refresh after all upgrade visuals settle.
    return true
end

local function onServerCommand(module, command, args)
    if module ~= "GoresSVU4Core" or command ~= "UpgradeActionApplied" then return end
    if not args or args.upgradeId ~= "BullBar" then return end
    if not getCell then return end
    local cell = getCell()
    if not cell or not cell.getVehicles then return end
    local vehicles = cell:getVehicles()
    if not vehicles or not vehicles.size or not vehicles.get then return end
    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle and vehicle.getId and args.vehicleId ~= nil then
            local ok, id = pcall(function() return vehicle:getId() end)
            if ok and tostring(id) == tostring(args.vehicleId) then GSVU4_ApplyBullBarVisual(vehicle, true); return end
        end
        if vehicle and vehicle.getOnlineID and args.vehicleOnlineId ~= nil then
            local ok, id = pcall(function() return vehicle:getOnlineID() end)
            if ok and tostring(id) == tostring(args.vehicleOnlineId) then GSVU4_ApplyBullBarVisual(vehicle, true); return end
        end
    end
end

Events.OnServerCommand.Add(onServerCommand)
if Events.OnEnterVehicle then
    Events.OnEnterVehicle.Add(function(player) local v = player and player.getVehicle and player:getVehicle() or nil; if v then GSVU4_ApplyBullBarVisual(v, true) end end)
end
