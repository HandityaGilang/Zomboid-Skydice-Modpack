--========================================================
-- GORE'S SVU4 CORE - OPTIONAL VISUAL PROFILE REGISTRY
--
-- Core armour logic remains functional even when no visual
-- pack is installed. Dependent mods can register vehicle
-- visual profiles that map GAA/GSVU4 armour state to fitted
-- 3D model names.
--========================================================

GSVU4Core = GSVU4Core or {}
GSVU4Core.VisualProfiles = GSVU4Core.VisualProfiles or {}

VehicleArmorVisuals = VehicleArmorVisuals or {}
VehicleArmorVisuals.VisualParts = VehicleArmorVisuals.VisualParts or {}
VehicleArmorVisuals.Models = VehicleArmorVisuals.Models or {}


local function getVehicleScriptName(vehicle)
    if not vehicle or not vehicle.getScript then return nil end
    local script = vehicle:getScript()
    if not script then return nil end
    if script.getFullName then return script:getFullName() end
    if script.getName then return "Base." .. tostring(script:getName()) end
    return nil
end

local function normaliseScriptName(name)
    if not name then return nil end
    name = tostring(name)
    if not string.find(name, "\.") then return "Base." .. name end
    return name
end

local function stripBasePrefix(name)
    if not name then return nil end
    return tostring(name):gsub("^Base%.", "")
end

function GSVU4Core.RegisterVisualProfile(vehicleScript, profile)
    if not vehicleScript or type(profile) ~= "table" then return false end

    local rawName = tostring(vehicleScript)
    local normalisedName = normaliseScriptName(rawName)
    local shortName = stripBasePrefix(normalisedName)

    -- Register both forms because Build 42 vehicle script APIs are not
    -- fully consistent: depending on context getFullName()/getName() may
    -- return either "Base.SportsCar" or just "SportsCar".
    if normalisedName then GSVU4Core.VisualProfiles[normalisedName] = profile end
    if shortName then GSVU4Core.VisualProfiles[shortName] = profile end

    return true
end


GSVU4Core.ExternalVisualPacks = GSVU4Core.ExternalVisualPacks or {}

function GSVU4Core.RegisterExternalVisualPack(id, data)
    if not id or type(data) ~= "table" then return false end
    GSVU4Core.ExternalVisualPacks[tostring(id)] = data
    return true
end

function GSVU4Core.ApplyExternalVisualPacks(vehicle, partId)
    local applied = false
    GSVU4Core.ExternalVisualPacks = GSVU4Core.ExternalVisualPacks or {}
    for id, pack in pairs(GSVU4Core.ExternalVisualPacks) do
        if type(pack) == "table" then
            local ok, result = false, false
            if partId and type(pack.applySourcePart) == "function" then
                ok, result = pcall(function() return pack.applySourcePart(vehicle, partId) end)
            end
            if (not ok or result ~= true) and type(pack.applyVehicle) == "function" then
                ok, result = pcall(function() return pack.applyVehicle(vehicle) end)
            end
            applied = (ok and result == true) or applied

        end
    end
    return applied
end

function GSVU4Core.GetVisualProfile(vehicle)
    local scriptName = getVehicleScriptName(vehicle)
    if not scriptName then return nil end

    local rawName = tostring(scriptName)
    local normalisedName = normaliseScriptName(rawName)
    local shortName = stripBasePrefix(normalisedName)
    local rawShort = stripBasePrefix(rawName)

    return GSVU4Core.VisualProfiles[rawName]
        or GSVU4Core.VisualProfiles[normalisedName]
        or GSVU4Core.VisualProfiles[shortName]
        or GSVU4Core.VisualProfiles[rawShort]
end

local function getArmorGrade(vehicle, partId)
    local md = vehicle and vehicle:getModData()
    local armor = md and md.gArmor
    local entry = armor and armor[partId]
    if type(entry) == "table" then return entry.grade end
    if type(entry) == "string" then return entry end
    return nil
end

local function safeSetModelVisible(part, modelName, visible)
    if not part or not modelName then return false end
    local ok, err = pcall(function()
        part:setModelVisible(modelName, visible)
    end)
    if not ok then

        return false
    end
    return true
end

local function safeTransmitVisualPart(vehicle, part)
    if not vehicle or not part then return end

    -- MP clients render locally. The server owns vehicle model state.
    -- This guard is retained from the later MP-safe builds and does not alter
    -- the original refresh sequence.
    if isClient and isClient() then return end

    pcall(function()
        if vehicle.transmitPartModData then
            vehicle:transmitPartModData(part)
        elseif part.transmitModData then
            part:transmitModData()
        end
    end)
end

-- Optional dependent visual-pack bridge.
-- Core stays functional without VV, but when the Vanilla Vehicles pack is
-- present this lets install/repair/uninstall completions use the same
-- ApplySourcePart/ApplyVehicle path that already works on OnEnterVehicle.
function VehicleArmorVisuals.ApplyExternalVisualPack(vehicle, partId)
    local applied = false

    -- New generic visual-pack bridge. Optional vehicle visual packs can register
    -- themselves with Core instead of being hardcoded here.
    if GSVU4Core and GSVU4Core.ApplyExternalVisualPacks then
        local ok, result = pcall(function()
            return GSVU4Core.ApplyExternalVisualPacks(vehicle, partId)
        end)
        applied = (ok and result == true) or applied
    end

    if GSVU4VV and GSVU4VV.VisualPart then
        if partId and GSVU4VV.VisualPart.ApplySourcePart then
            local ok, result = pcall(function()
                return GSVU4VV.VisualPart.ApplySourcePart(vehicle, partId)
            end)
            applied = (ok and result == true) or applied
        end

        if (not applied) and GSVU4VV.VisualPart.ApplyVehicle then
            local ok, result = pcall(function()
                return GSVU4VV.VisualPart.ApplyVehicle(vehicle)
            end)
            applied = (ok and result == true) or applied
        end
    end

    return applied
end

local function callVisualPackApply(vehicle, entry, grade, modelName, visualPartId)
    if not entry or not modelName then return end
    local cb = entry.applyVisual or entry.apply or entry.onApply
    if type(cb) ~= "function" then return end
    local ok, err = pcall(function()
        cb(vehicle, grade, modelName, visualPartId, entry)
    end)
    if ok then

    else

    end
end

local function hideVisualEntry(vehicle, entry)
    if not entry then return end
    local visualPartId = entry.visualPart or entry.part or entry.partId
    if not visualPartId then return end
    local part = vehicle:getPartById(visualPartId)
    if not part then return end
    local models = entry.models or entry.modelNames or {}
    for _, modelName in pairs(models) do
        if type(modelName) == "table" then
            for _, nested in pairs(modelName) do safeSetModelVisible(part, nested, false) end
        else
            safeSetModelVisible(part, modelName, false)
        end
    end
    safeTransmitVisualPart(vehicle, part)
end

local function showVisualEntry(vehicle, entry, grade)
    if not entry or not grade then return end
    local visualPartId = entry.visualPart or entry.part or entry.partId
    if not visualPartId then return end
    local part = vehicle:getPartById(visualPartId)
    if not part then

        return
    end

    local models = entry.models or {}
    local modelName = models[grade] or models[tostring(grade)]
    if type(modelName) == "table" then
        for _, nested in ipairs(modelName) do
            if safeSetModelVisible(part, nested, true) then

                callVisualPackApply(vehicle, entry, grade, nested, visualPartId)
            end
        end
    elseif modelName then
        if safeSetModelVisible(part, modelName, true) then

            callVisualPackApply(vehicle, entry, grade, modelName, visualPartId)
        end
    else

    end
    safeTransmitVisualPart(vehicle, part)
end

function VehicleArmorVisuals.GetModelName(partId, grade, vehicle)
    local profile = vehicle and GSVU4Core.GetVisualProfile(vehicle) or nil
    local entry = profile and profile.parts and profile.parts[partId]
    if entry and entry.models then return entry.models[grade] end
    return nil
end

function VehicleArmorVisuals.ApplyToPart(vehicle, partId)
    if not vehicle or not partId then return end
    local profile = GSVU4Core.GetVisualProfile(vehicle)
    if profile and profile.parts then
        local entry = profile.parts[partId]
        if entry then
            hideVisualEntry(vehicle, entry)
            local grade = getArmorGrade(vehicle, partId)
            if grade then showVisualEntry(vehicle, entry, grade) end
        end
    end

    if VehicleArmorVisuals.ApplyExternalVisualPack then
        VehicleArmorVisuals.ApplyExternalVisualPack(vehicle, partId)
    end
end

function VehicleArmorVisuals.ForceInstalled(vehicle, skipExternalVisualPack)
    if not vehicle then return end
    local profile = GSVU4Core.GetVisualProfile(vehicle)
    local md = vehicle:getModData()
    local armor = md and md.gArmor

    if profile and profile.parts and type(armor) == "table" then
        for partId, armorEntry in pairs(armor) do
            local grade = type(armorEntry) == "table" and armorEntry.grade or armorEntry
            local entry = profile.parts[partId]
            if entry and grade then
                showVisualEntry(vehicle, entry, grade)
            else

            end
        end
    else
        if not profile or not profile.parts then

        end
        if type(armor) ~= "table" then

        end
    end

    -- Original behavior is retained unless the unified refresh has already
    -- applied every external visual pack and needs armor to remain the final
    -- model operation.
    if not skipExternalVisualPack
    and VehicleArmorVisuals.ApplyExternalVisualPack then
        VehicleArmorVisuals.ApplyExternalVisualPack(vehicle, nil)
    end
end


function VehicleArmorVisuals.Apply(vehicle)
    if not vehicle then return end
    -- Phase 1l: do not full-hide every profile entry on routine refresh.
    -- Full hide/show caused visible flicker on working panels and could race
    -- against models that are slow to settle. Normal install/repair refreshes
    -- should simply force the currently installed armour visuals visible.
    VehicleArmorVisuals.ForceInstalled(vehicle)
end

function VehicleArmorVisuals.ApplyFullReset(vehicle)
    if not vehicle then return end
    local profile = GSVU4Core.GetVisualProfile(vehicle)
    if not profile or not profile.parts then return end
    for partId, entry in pairs(profile.parts) do
        hideVisualEntry(vehicle, entry)
    end
    VehicleArmorVisuals.ForceInstalled(vehicle)
end

--========================================================
-- Delayed visual refresh queue
-- Some vehicle models/parts are not ready on the exact frame
-- a timed action completes. QueueApply retries the same refresh
-- a few times so normal UI installs behave like a direct visual refresh.
--========================================================
VehicleArmorVisuals.PendingRefresh = VehicleArmorVisuals.PendingRefresh or {}

local GSVU4_visualQueueTickRegistered = false

local function GSVU4_visualVehicleKey(vehicle)
    if not vehicle then return nil end
    if vehicle.getOnlineID then
        local ok, id = pcall(function() return vehicle:getOnlineID() end)
        if ok and id then return "online:" .. tostring(id) end
    end
    if vehicle.getId then
        local ok, id = pcall(function() return vehicle:getId() end)
        if ok and id then return "id:" .. tostring(id) end
    end
    if vehicle.getX and vehicle.getY and vehicle.getZ then
        return tostring(math.floor(vehicle:getX())) .. ":" .. tostring(math.floor(vehicle:getY())) .. ":" .. tostring(math.floor(vehicle:getZ()))
    end
    return tostring(vehicle)
end

local function GSVU4_visualQueueHasEntries()
    if not VehicleArmorVisuals or not VehicleArmorVisuals.PendingRefresh then return false end
    for _, _ in pairs(VehicleArmorVisuals.PendingRefresh) do
        return true
    end
    return false
end

local function GSVU4_unregisterVisualQueueTick()
    if not GSVU4_visualQueueTickRegistered then return end
    if Events and Events.OnTick and Events.OnTick.Remove then
        pcall(function() Events.OnTick.Remove(GSVU4_processVisualQueue) end)
    end
    GSVU4_visualQueueTickRegistered = false
end

local function GSVU4_registerVisualQueueTick()
    if GSVU4_visualQueueTickRegistered then return end
    if Events and Events.OnTick then
        Events.OnTick.Add(GSVU4_processVisualQueue)
        GSVU4_visualQueueTickRegistered = true
    end
end

function VehicleArmorVisuals.QueueApply(vehicle, partId, maxAttempts, intervalTicks)
    if not vehicle then return end
    local key = GSVU4_visualVehicleKey(vehicle)
    if not key then return end
    VehicleArmorVisuals.PendingRefresh[key] = {
        vehicle = vehicle,
        partId = partId,
        ticks = 0,
        attempts = 0,
        maxAttempts = tonumber(maxAttempts) or 3,
        intervalTicks = tonumber(intervalTicks) or 20,
    }

    -- Only register the OnTick retry worker while there is actual pending
    -- visual work. This avoids an always-on tick callback during normal play.
    GSVU4_registerVisualQueueTick()
end

function GSVU4_processVisualQueue()
    if not VehicleArmorVisuals or not VehicleArmorVisuals.PendingRefresh then
        GSVU4_unregisterVisualQueueTick()
        return
    end

    if not GSVU4_visualQueueHasEntries() then
        GSVU4_unregisterVisualQueueTick()
        return
    end

    for key, entry in pairs(VehicleArmorVisuals.PendingRefresh) do
        entry.ticks = (entry.ticks or 0) + 1
        local intervalTicks = tonumber(entry.intervalTicks) or 20
        if entry.ticks >= intervalTicks then
            entry.ticks = 0
            entry.attempts = (entry.attempts or 0) + 1
            -- Phase 1l: retry only the force-visible pass. Avoid hide/show
            -- loops, which caused rear-window flicker and could hide panels
            -- just after the visual-pack callback made them visible.
            if VehicleArmorVisuals.ApplyToPart and entry.partId then
                pcall(function() VehicleArmorVisuals.ApplyToPart(entry.vehicle, entry.partId) end)
            elseif VehicleArmorVisuals.ForceInstalled then
                pcall(function() VehicleArmorVisuals.ForceInstalled(entry.vehicle) end)
            end

            if VehicleArmorVisuals.ApplyExternalVisualPack then
                pcall(function() VehicleArmorVisuals.ApplyExternalVisualPack(entry.vehicle, entry.partId) end)
            end

            local maxAttempts = tonumber(entry.maxAttempts) or 3
            if entry.attempts >= maxAttempts then
                VehicleArmorVisuals.PendingRefresh[key] = nil
            end
        end
    end

    if not GSVU4_visualQueueHasEntries() then
        GSVU4_unregisterVisualQueueTick()
    end
end


function GSVU4Core.ApplyExternalUpgradeVisualPacks(vehicle, upgradeId, grade)
    local applied = false
    GSVU4Core.ExternalVisualPacks = GSVU4Core.ExternalVisualPacks or {}
    for id, pack in pairs(GSVU4Core.ExternalVisualPacks) do
        if type(pack) == "table" then
            local ok, result = false, false
            if upgradeId and type(pack.applyUpgrade) == "function" then
                ok, result = pcall(function() return pack.applyUpgrade(vehicle, upgradeId, grade) end)
            end
            if (not ok or result ~= true) and type(pack.applyVehicle) == "function" then
                ok, result = pcall(function() return pack.applyVehicle(vehicle) end)
            end
            applied = (ok and result == true) or applied
            if (not ok) and print then
            end
        end
    end
    return applied
end
