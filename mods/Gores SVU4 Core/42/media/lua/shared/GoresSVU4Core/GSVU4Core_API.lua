--========================================================
-- GORE'S SVU4 CORE - PUBLIC API SKELETON
--
-- This file is intentionally small and safe. It gives future
-- visual/compatibility packs a stable place to register vehicle
-- profiles and upgrade types without editing Core files.
--========================================================

GSVU4Core = GSVU4Core or {}
GSVU4Core.API_VERSION = 1
GSVU4Core.VisualProfiles = GSVU4Core.VisualProfiles or {}
GSVU4Core.UpgradeTypes = GSVU4Core.UpgradeTypes or {}
GSVU4Core.CompatibilityPacks = GSVU4Core.CompatibilityPacks or {}
GSVU4Core.ExternalVisualPacks = GSVU4Core.ExternalVisualPacks or {}

local function normaliseScriptName(name)
    if not name then return nil end
    name = tostring(name)
    if not string.find(name, "\.") then return "Base." .. name end
    return name
end

function GSVU4Core.RegisterUpgradeType(id, data)
    if not id or type(data) ~= "table" then return false end
    GSVU4Core.UpgradeTypes[tostring(id)] = data
    return true
end

function GSVU4Core.GetUpgradeType(id)
    if not id then return nil end
    return GSVU4Core.UpgradeTypes[tostring(id)]
end

function GSVU4Core.RegisterVisualProfile(vehicleScript, profile)
    vehicleScript = normaliseScriptName(vehicleScript)
    if not vehicleScript or type(profile) ~= "table" then return false end
    GSVU4Core.VisualProfiles[vehicleScript] = profile
    return true
end


function GSVU4Core.RegisterExternalVisualPack(id, data)
    if not id or type(data) ~= "table" then return false end
    GSVU4Core.ExternalVisualPacks = GSVU4Core.ExternalVisualPacks or {}
    GSVU4Core.ExternalVisualPacks[tostring(id)] = data
    return true
end

function GSVU4Core.GetExternalVisualPack(id)
    if not id then return nil end
    GSVU4Core.ExternalVisualPacks = GSVU4Core.ExternalVisualPacks or {}
    return GSVU4Core.ExternalVisualPacks[tostring(id)]
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
            if (not ok) and print then
            end
        end
    end
    return applied
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

function GSVU4Core.RegisterCompatibilityPack(id, data)
    if not id then return false end
    GSVU4Core.CompatibilityPacks[tostring(id)] = data or {}
    return true
end
