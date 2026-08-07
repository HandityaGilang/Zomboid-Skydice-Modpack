--========================================================
-- Gore's SVU4 Vanilla Cars - Engine Scoop visual registration
--
-- Registers all supported Vanilla vehicle scripts with Core, applies one of
-- six fitted scoop meshes on the hidden lifecycle anchor, and makes the Hood
-- armour model authoritative from current gArmor + physical EngineScoop state.
--========================================================

require "GoresSVU4Core/GSVU4_EngineScoop"

-- B42.20 can resolve shared Lua files in a different order during a fresh
-- client load. Ensure the family/visual registry exists before deciding that
-- scoop support is unavailable.
if not GSVU4VV or not GSVU4VV.VisualPart then
    pcall(require, "GoresSVU4VanillaCars/GSVU4VV_SVU3HybridVisuals")
end
if not GSVU4VV or not GSVU4VV.VisualPart then return end

local SCOOPS_BY_FAMILY = {
    CarNormal = {
        Small = "SVU_Airscoop_CarNormal_Small",
        Medium = "SVU_Airscoop_CarNormal_Medium",
        SmallRound = "SVU_Airscoop_CarNormal_Small_Round",
        Large = "SVU_Airscoop_CarNormal_Large",
        LargeRound = "SVU_Airscoop_CarNormal_Large_Round",
        Piped = "SVU_Airscoop_CarNormal_Piped",
    },
    CarWagon = {
        Small = "SVU_Airscoop_CarWagon_Small",
        Medium = "SVU_Airscoop_CarWagon_Medium",
        SmallRound = "SVU_Airscoop_CarWagon_Small_Round",
        Large = "SVU_Airscoop_CarWagon_Large",
        LargeRound = "SVU_Airscoop_CarWagon_Large_Round",
        Piped = "SVU_Airscoop_CarWagon_Piped",
    },
    LuxuryCar = {
        Small = "SVU_Airscoop_LuxuryCar_Small",
        Medium = "SVU_Airscoop_LuxuryCar_Medium",
        SmallRound = "SVU_Airscoop_LuxuryCar_Small_Round",
        Large = "SVU_Airscoop_LuxuryCar_Large",
        LargeRound = "SVU_Airscoop_LuxuryCar_Large_Round",
        Piped = "SVU_Airscoop_LuxuryCar_Piped",
    },
    SUV = {
        Small = "SVU_Airscoop_SUV_Small",
        Medium = "SVU_Airscoop_SUV_Medium",
        SmallRound = "SVU_Airscoop_SUV_Small_Round",
        Large = "SVU_Airscoop_SUV_Large",
        LargeRound = "SVU_Airscoop_SUV_Large_Round",
        Piped = "SVU_Airscoop_SUV_Piped",
    },
    PickUp = {
        Small = "SVU_Airscoop_PickUp_Small",
        Medium = "SVU_Airscoop_PickUp_Medium",
        SmallRound = "SVU_Airscoop_PickUp_Small_Round",
        Large = "SVU_Airscoop_PickUp_Large",
        LargeRound = "SVU_Airscoop_PickUp_Large_Round",
        Piped = "SVU_Airscoop_PickUp_Piped",
    },
    PickUpVan = {
        Small = "SVU_Airscoop_PickUp_Small",
        Medium = "SVU_Airscoop_PickUp_Medium",
        SmallRound = "SVU_Airscoop_PickUp_Small_Round",
        Large = "SVU_Airscoop_PickUp_Large",
        LargeRound = "SVU_Airscoop_PickUp_Large_Round",
        Piped = "SVU_Airscoop_PickUp_Piped",
    },
    SmallCar = {
        Small = "SVU_Airscoop_SmallCar_Small",
        Medium = "SVU_Airscoop_SmallCar_Medium",
        SmallRound = "SVU_Airscoop_SmallCar_Small_Round",
        Large = "SVU_Airscoop_SmallCar_Large",
        LargeRound = "SVU_Airscoop_SmallCar_Large_Round",
        Piped = "SVU_Airscoop_SmallCar_Piped",
    },
    SmallCar02 = {
        Small = "SVU_Airscoop_SmallCar02_Small",
        Medium = "SVU_Airscoop_SmallCar02_Medium",
        SmallRound = "SVU_Airscoop_SmallCar02_Small_Round",
        Large = "SVU_Airscoop_SmallCar02_Large",
        LargeRound = "SVU_Airscoop_SmallCar02_Large_Round",
        Piped = "SVU_Airscoop_SmallCar02_Piped",
    },
    SportsCar = {
        Small = "GSVU4_SVU3_SportsCar_Airscoop_Small",
        Medium = "GSVU4_SVU3_SportsCar_Airscoop_Medium",
        SmallRound = "GSVU4_SVU3_SportsCar_Airscoop_Small_Round",
        Large = "GSVU4_SVU3_SportsCar_Airscoop_Large",
        LargeRound = "GSVU4_SVU3_SportsCar_Airscoop_Large_Round",
        Piped = "GSVU4_SVU3_SportsCar_Airscoop_Piped",
    },
    ModernCar = {
        Small = "SVU_Airscoop_CarModern_Small",
        Medium = "SVU_Airscoop_CarModern_Medium",
        SmallRound = "SVU_Airscoop_CarModern_Small_Round",
        Large = "SVU_Airscoop_CarModern_Large",
        LargeRound = "SVU_Airscoop_CarModern_Large_Round",
        Piped = "SVU_Airscoop_CarModern_Piped",
    },
    ModernCar2 = {
        Small = "SVU_Airscoop_CarModern2_Small",
        Medium = "SVU_Airscoop_CarModern2_Medium",
        SmallRound = "SVU_Airscoop_CarModern2_Small_Round",
        Large = "SVU_Airscoop_CarModern2_Large",
        LargeRound = "SVU_Airscoop_CarModern2_Large_Round",
        Piped = "SVU_Airscoop_CarModern2_Piped",
    },
    Van = {
        Small = "SVU_Airscoop_Van_Small",
        Medium = "SVU_Airscoop_Van_Medium",
        SmallRound = "SVU_Airscoop_Van_Small_Round",
        Large = "SVU_Airscoop_Van_Large",
        LargeRound = "SVU_Airscoop_Van_Large_Round",
        Piped = "SVU_Airscoop_Van_Piped",
    },
    StepVan = {
        Small = "SVU_Airscoop_StepVan_Small",
        Medium = "SVU_Airscoop_StepVan_Medium",
        SmallRound = "SVU_Airscoop_StepVan_Small_Round",
        Large = "SVU_Airscoop_StepVan_Large",
        LargeRound = "SVU_Airscoop_StepVan_Large_Round",
        Piped = "SVU_Airscoop_StepVan_Piped",
    },
    OffRoad = {
        Small = "SVU_Airscoop_OffRoad_Small",
        Medium = "SVU_Airscoop_OffRoad_Medium",
        SmallRound = "SVU_Airscoop_OffRoad_Small_Round",
        Large = "SVU_Airscoop_OffRoad_Large",
        LargeRound = "SVU_Airscoop_OffRoad_Large_Round",
        Piped = "SVU_Airscoop_OffRoad_Piped",
    },
    DashRoamer = {
        Small = "SVU_Airscoop_DashRoamer_Small",
        Medium = "SVU_Airscoop_DashRoamer_Medium",
        SmallRound = "SVU_Airscoop_DashRoamer_Small_Round",
        Large = "SVU_Airscoop_DashRoamer_Large",
        LargeRound = "SVU_Airscoop_DashRoamer_Large_Round",
        Piped = "SVU_Airscoop_DashRoamer_Piped",
    },
    GMCVan = {
        Small = "SVU_Airscoop_GMCVan_Small",
        Medium = "SVU_Airscoop_GMCVan_Medium",
        SmallRound = "SVU_Airscoop_GMCVan_Small_Round",
        Large = "SVU_Airscoop_GMCVan_Large",
        LargeRound = "SVU_Airscoop_GMCVan_Large_Round",
        Piped = "SVU_Airscoop_GMCVan_Piped",
    },
    RaceCar = {
        Small = "GSVU4_RaceCar_Airscoop_Small",
        Medium = "GSVU4_RaceCar_Airscoop_Medium",
        SmallRound = "GSVU4_RaceCar_Airscoop_Small_Round",
        Large = "GSVU4_RaceCar_Airscoop_Large",
        LargeRound = "GSVU4_RaceCar_Airscoop_Large_Round",
        Piped = "GSVU4_RaceCar_Airscoop_Piped",
    },
}

-- Part-model names normally resolve to a same-named global model. These aliases
-- preserve existing special-family naming while pointing at the actual cut hood.
local HOOD_SCOOP_FILE_OVERRIDES = {
    GSVU4_SC02_NATIVE_Hood_Scrap_Scoop = "SVU_Hood_SmallCar02_Paper_Scoop",
    GSVU4_SC02_NATIVE_Hood_Standard_Scoop = "SVU_Hood_SmallCar02_Light_Spiked_Scoop",
    GSVU4_SC02_NATIVE_Hood_Reinforced_Scoop = "SVU_Hood_SmallCar02_Reinforced_Scoop",
    GSVU4_SC02_NATIVE_Hood_Apocalypse_Scoop = "SVU_Hood_SmallCar02_Heavy_Spiked_Scoop",

    GSVU4_SVU3_SportsCar_Hood_Apocalypse_Base_Scoop = "GSVU4_SVU3_SportsCar_Hood_Apocalypse_ScoopBase",
    GSVU4_SVU3_SportsCar_Hood_Apocalypse_Spiked_Scoop = "GSVU4_SVU3_SportsCar_Hood_Apocalypse_ScoopSpiked",
}

local function stripBase(name)
    if not name then return nil end
    return tostring(name):gsub("^[^%.]+%.", "")
end

local function normaliseVehicleName(name)
    local short = stripBase(name)
    if not short or short == "" then return nil end
    return "Base." .. short
end

local function getVehicleScriptName(vehicle)
    if GSVU4EngineScoop and GSVU4EngineScoop.getVehicleScriptName then
        return GSVU4EngineScoop.getVehicleScriptName(vehicle)
    end
    if vehicle and vehicle.getScriptName then
        local ok, value = pcall(function() return vehicle:getScriptName() end)
        if ok and value then return tostring(value) end
    end
    return nil
end

local function getFamilyForVehicle(vehicle)
    local name = getVehicleScriptName(vehicle)
    if not name or not GSVU4VV.FamilyByVehicle then return nil end
    return GSVU4VV.FamilyByVehicle[name]
        or GSVU4VV.FamilyByVehicle[normaliseVehicleName(name)]
        or GSVU4VV.FamilyByVehicle[stripBase(name)]
end

local function getFamilyScoopModels(family)
    if not family then return nil end
    return SCOOPS_BY_FAMILY[family.id] or SCOOPS_BY_FAMILY[family.suffix]
end

local function getLifecyclePart(vehicle, family)
    if not vehicle or not family or not family.lifecycleAnchor or not vehicle.getPartById then return nil end
    local ok, part = pcall(function() return vehicle:getPartById(family.lifecycleAnchor) end)
    if ok then return part end
    return nil
end

local function getHoodGroup(family)
    if not family then return nil end
    local hood = family.GroupByName and family.GroupByName.Hood or nil
    if hood then return hood end
    for _, group in ipairs(family.groups or {}) do
        if tostring(group and group.group or "") == "Hood" then return group end
    end
    return nil
end

local function getHoodVisualPartId(family, hood)
    return hood and hood.visualAnchor
        or family and family.visualAnchor
        or family and family.lifecycleAnchor
end

local function eachModel(spec, callback)
    if not spec or not callback then return end
    if type(spec) == "table" then
        for _, modelName in pairs(spec) do
            if modelName then callback(modelName) end
        end
    else
        callback(spec)
    end
end

local function mapModelSpec(spec, mapper)
    if type(spec) == "table" then
        local result = {}
        for key, modelName in pairs(spec) do
            result[key] = modelName and mapper(modelName) or modelName
        end
        return result
    end
    return spec and mapper(spec) or spec
end

local function toScoopModel(modelName)
    modelName = tostring(modelName or "")
    if modelName == "" or modelName:sub(-6) == "_Scoop" then return modelName end
    return modelName .. "_Scoop"
end

local function makeScoopHoodModels(models)
    local result = {}
    for grade, spec in pairs(models or {}) do
        result[grade] = mapModelSpec(spec, toScoopModel)
    end
    return result
end

local function setVisible(part, modelName, visible)
    if not part or not modelName or not part.setModelVisible then return false end
    local ok = pcall(function() part:setModelVisible(tostring(modelName), visible == true) end)
    return ok == true
end

local function getInstalledScoopEntry(vehicle)
    -- Physical installation controls the body cut-out. A zero-condition scoop
    -- remains bolted through the Hood until it is actually removed.
    local md = vehicle and vehicle.getModData and vehicle:getModData() or nil
    local upgrades = md and md.gUpgrades or nil
    local installed = type(upgrades) == "table" and upgrades.EngineScoop or nil
    if type(installed) == "table" and installed.grade then return installed end
    installed = GSVU4EngineScoop and GSVU4EngineScoop.getInstalledUpgrade
        and GSVU4EngineScoop.getInstalledUpgrade(vehicle) or nil
    return type(installed) == "table" and installed.grade and installed or nil
end

local function hasInstalledScoop(vehicle)
    return getInstalledScoopEntry(vehicle) ~= nil
end

local AppliedScoopState = setmetatable({}, { __mode = "k" })

local function applyScoop(vehicle, force)
    local family = getFamilyForVehicle(vehicle)
    local models = getFamilyScoopModels(family)
    if not family or not models then return false end
    local part = getLifecyclePart(vehicle, family)
    if not part then return false end

    local installed = getInstalledScoopEntry(vehicle)
    local grade = installed and tostring(installed.grade or "") or nil
    local target = grade and models[grade] or nil
    local state = tostring(grade or "none") .. ":" .. tostring(target or "none")

    if not force and AppliedScoopState[vehicle] == state then
        if target then setVisible(part, target, true) end
        return true
    end
    AppliedScoopState[vehicle] = state

    local seen = {}
    for _, modelName in pairs(models) do
        if modelName and not seen[modelName] then
            seen[modelName] = true
            setVisible(part, modelName, false)
        end
    end
    if target then setVisible(part, target, true) end
    return true
end

-- Public bridge used by the coordinated Core/Vanilla initial visual pass.
GSVU4VV.ApplyEngineScoopVisual = applyScoop

local function hideNormalAndScoopHoods(vehicle, family, group)
    local partId = getHoodVisualPartId(family, group)
    if not vehicle or not partId or not vehicle.getPartById then return end
    local ok, part = pcall(function() return vehicle:getPartById(partId) end)
    if not ok or not part then return end
    for _, spec in pairs(group.models or {}) do
        eachModel(spec, function(modelName)
            setVisible(part, modelName, false)
            setVisible(part, toScoopModel(modelName), false)
        end)
    end
end


local function getGroupGrade(vehicle, group)
    local md = vehicle and vehicle.getModData and vehicle:getModData() or nil
    local armor = md and md.gArmor or nil
    if type(armor) ~= "table" then return nil end
    for _, partId in ipairs(group and group.sourceParts or {}) do
        local entry = armor[partId]
        if type(entry) == "table" and entry.grade then return tostring(entry.grade) end
        if type(entry) == "string" then return tostring(entry) end
    end
    return nil
end

local function forceApplyScoopHood(vehicle, family, group)
    local partId = getHoodVisualPartId(family, group)
    if not vehicle or not group or not partId or not vehicle.getPartById then return false end
    local ok, part = pcall(function() return vehicle:getPartById(partId) end)
    if not ok or not part then return false end

    local grade = getGroupGrade(vehicle, group)
    local modelSpec = grade and group.models and (group.models[grade] or group.models[tostring(grade)]) or nil
    if not modelSpec then return false end

    hideNormalAndScoopHoods(vehicle, family, group)
    local shown = false
    eachModel(modelSpec, function(modelName)
        if setVisible(part, toScoopModel(modelName), true) then shown = true end
    end)
    return shown
end

-- Inject only the scoop-cut Hood aliases. Scoop body models are static members
-- of each lifecycle-anchor template, so every alias inheriting that template
-- receives the full six-model set automatically.
GSVU4VV.EngineScoopInjectedHoods = GSVU4VV.EngineScoopInjectedHoods or {}

local function doVehicleParam(vehicleName, param)
    if not ScriptManager or not ScriptManager.instance then return false end
    local short = stripBase(vehicleName)
    if not short or short == "" then return false end
    local script = ScriptManager.instance:getVehicle("Base." .. short)
    if not script then return false end
    local ok = pcall(function() script:Load(short, "{" .. param .. "}") end)
    return ok == true
end

local function buildHoodModelParam(family, hood)
    local partId = getHoodVisualPartId(family, hood)
    if not partId then return nil end
    local seen = {}
    local lines = { "        part " .. tostring(partId), "        {", "            setAllModelsVisible = false," }
    for _, spec in pairs(hood.models or {}) do
        eachModel(spec, function(normalModel)
            local scoopModel = toScoopModel(normalModel)
            if scoopModel and not seen[scoopModel] then
                seen[scoopModel] = true
                local fileModel = HOOD_SCOOP_FILE_OVERRIDES[scoopModel] or scoopModel
                lines[#lines + 1] = "            model " .. tostring(scoopModel)
                lines[#lines + 1] = "            {"
                lines[#lines + 1] = "                file = " .. tostring(fileModel) .. ","
                lines[#lines + 1] = "            }"
            end
        end)
    end
    lines[#lines + 1] = "        }"
    return table.concat(lines, "\n")
end

function GSVU4VV.InjectEngineScoopHoodModels()
    if GSVU4VV.AddLoadedVanillaVariantAliases then
        GSVU4VV.AddLoadedVanillaVariantAliases()
    end
    local count = 0
    for _, family in ipairs(GSVU4VV.Families or {}) do
        if getFamilyScoopModels(family) then
            local hood = getHoodGroup(family)
            local param = hood and buildHoodModelParam(family, hood) or nil
            if param then
                for _, vehicleName in ipairs(family.vehicles or {}) do
                    local short = stripBase(vehicleName)
                    local key = tostring(short) .. ":" .. tostring(getHoodVisualPartId(family, hood))
                    if short and not GSVU4VV.EngineScoopInjectedHoods[key] then
                        if doVehicleParam(short, param) then
                            GSVU4VV.EngineScoopInjectedHoods[key] = true
                            count = count + 1
                        end
                    end
                end
            end
        end
    end
    return count
end

function GSVU4VV.RegisterEngineScoopVehicles()
    if GSVU4VV.AddLoadedVanillaVariantAliases then
        GSVU4VV.AddLoadedVanillaVariantAliases()
    end
    local count = 0
    for _, family in ipairs(GSVU4VV.Families or {}) do
        if getFamilyScoopModels(family) then
            for _, vehicleName in ipairs(family.vehicles or {}) do
                if GSVU4EngineScoop.registerVehicleScript(vehicleName) then
                    count = count + 1
                end
            end
        end
    end
    return count
end

if not GSVU4VV.VisualPart.GSVU4VV_EngineScoopHoodWrapped then
    local originalApplyGroup = GSVU4VV.VisualPart.ApplyGroup
    local AppliedHoodMode = setmetatable({}, { __mode = "k" })

    function GSVU4VV.VisualPart.ApplyGroup(vehicle, family, group)
        if not originalApplyGroup or not group or tostring(group.group or "") ~= "Hood" then
            return originalApplyGroup and originalApplyGroup(vehicle, family, group) or false
        end

        local scoopInstalled = hasInstalledScoop(vehicle)
        local desiredMode = scoopInstalled and "scoop" or "normal"

        -- Hide both hood sets only when the physical scoop state actually changes
        -- or when this vehicle is first resolved. Routine refreshes now reassert
        -- the desired model without producing a visible hide/show pulse.
        if AppliedHoodMode[vehicle] ~= desiredMode then
            hideNormalAndScoopHoods(vehicle, family, group)
            AppliedHoodMode[vehicle] = desiredMode
        end

        if not scoopInstalled then
            return originalApplyGroup(vehicle, family, group)
        end

        local normalModels = group.models
        group.models = makeScoopHoodModels(normalModels)
        local ok, result = pcall(originalApplyGroup, vehicle, family, group)
        group.models = normalModels
        if not ok then return false end

        -- Reassert the scoop-cut hood directly on the visual part so the
        -- installed scoop state cannot fall back to the normal hood shell.
        local forced = forceApplyScoopHood(vehicle, family, group)
        return forced or result
    end

    GSVU4VV.VisualPart.GSVU4VV_EngineScoopHoodWrapped = true
end

function GSVU4VV.ResolveEngineScoopHoodVisual(vehicle, reason)
    local family = getFamilyForVehicle(vehicle)
    local hood = getHoodGroup(family)
    if not family or not hood or not GSVU4VV.VisualPart.ApplyGroup then return false end
    return GSVU4VV.VisualPart.ApplyGroup(vehicle, family, hood)
end

-- Full vehicle refresh authority: armour first, then authoritative Hood state.
if not GSVU4VV.VisualPart.GSVU4VV_EngineScoopVehicleWrapped then
    local originalApplyVehicle = GSVU4VV.VisualPart.ApplyVehicle

    function GSVU4VV.VisualPart.ApplyVehicle(vehicle)
        local result = originalApplyVehicle and originalApplyVehicle(vehicle) or false
        local hoodResult = GSVU4VV.ResolveEngineScoopHoodVisual(vehicle, "vehicle-refresh")
        return result or hoodResult
    end

    GSVU4VV.VisualPart.GSVU4VV_EngineScoopVehicleWrapped = true
end

local pack = {
    applyUpgrade = function(vehicle, upgradeId, grade)
        if tostring(upgradeId or "") ~= "EngineScoop" then return false end
        local scoopResult = applyScoop(vehicle, true)
        local hoodResult = GSVU4VV.ResolveEngineScoopHoodVisual(vehicle, "upgrade-action")
        return scoopResult or hoodResult
    end,
    applyVehicle = function(vehicle)
        local scoopResult = applyScoop(vehicle, false)
        local hoodResult = GSVU4VV.ResolveEngineScoopHoodVisual(vehicle, "external-refresh")
        return scoopResult or hoodResult
    end,
}

local function registerPack()
    GSVU4VV.InjectEngineScoopHoodModels()
    GSVU4VV.RegisterEngineScoopVehicles()
    if GSVU4Core and GSVU4Core.RegisterExternalVisualPack then
        GSVU4Core.RegisterExternalVisualPack("GSVU4VanillaEngineScoop", pack)
    else
        GSVU4Core = GSVU4Core or {}
        GSVU4Core.ExternalVisualPacks = GSVU4Core.ExternalVisualPacks or {}
        GSVU4Core.ExternalVisualPacks.GSVU4VanillaEngineScoop = pack
    end
end

registerPack()
if Events and Events.OnGameStart then Events.OnGameStart.Add(registerPack) end
if Events and Events.OnLoad then Events.OnLoad.Add(registerPack) end
if Events and Events.OnEnterVehicle then
    Events.OnEnterVehicle.Add(function(character)
        local vehicle = character and character.getVehicle and character:getVehicle() or nil
        if vehicle then
            applyScoop(vehicle, true)
            GSVU4VV.ResolveEngineScoopHoodVisual(vehicle, "enter-vehicle")
        end
    end)
end
