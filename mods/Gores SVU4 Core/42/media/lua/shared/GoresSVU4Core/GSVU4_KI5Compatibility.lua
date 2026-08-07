-- KI5 / that DAMN Library compatibility helpers
-- Blocks SVU4 armour on overlapping native KI5/DAMN protected parts.

GSVU4_KI5Compat = GSVU4_KI5Compat or {}

local Compat = GSVU4_KI5Compat

Compat.NativePartMap = Compat.NativePartMap or {
    EngineDoor      = { "DAMNBumperFront" },
    Hood            = { "DAMNBumperFront" },
    HeadlightLeft   = { "DAMNBumperFront" },
    HeadlightRight  = { "DAMNBumperFront" },
    TrunkDoor       = { "DAMNBumperRear" },
    Windshield      = { "DAMNWindshieldArmor" },
    WindshieldFront = { "DAMNWindshieldArmor" },
    WindshieldRear  = { "DAMNWindshieldRearArmor" },
    RearWindshield  = { "DAMNWindshieldRearArmor" },
    WindowFrontLeft = { "DAMNFrontLeftArmor" },
    WindowFrontRight= { "DAMNFrontRightArmor" },
    WindowRearLeft  = { "DAMNRearLeftArmor" },
    WindowRearRight = { "DAMNRearRightArmor" },
}

Compat.ScriptOverrides = Compat.ScriptOverrides or {
    ["Base.92amgeneralM998"] = {
        GasTank = {
            reason = "KI5 native armour already preserves the Gas Tank on this vehicle.",
            nativePart = "DAMNBumperFront",
        },
    },
}

local function safeCall(fn)
    if not fn then return nil end
    local ok, value = pcall(fn)
    if ok then return value end
    return nil
end

function Compat.getVehicleScriptName(vehicle)
    if not vehicle then return nil end

    local scriptName = nil
    if vehicle.getScriptName then
        scriptName = safeCall(function() return vehicle:getScriptName() end)
    end

    if not scriptName and vehicle.getScript then
        local script = safeCall(function() return vehicle:getScript() end)
        if script then
            if script.getFullName then
                scriptName = safeCall(function() return script:getFullName() end)
            end
            if not scriptName and script.getName then
                local shortName = safeCall(function() return script:getName() end)
                if shortName and tostring(shortName):find("%.", 1, true) then
                    scriptName = shortName
                elseif shortName then
                    scriptName = "Base." .. tostring(shortName)
                end
            end
        end
    end

    return scriptName and tostring(scriptName) or nil
end

function Compat.hasVehiclePart(vehicle, partId)
    if not vehicle or not partId or not vehicle.getPartById then return false end
    local part = safeCall(function() return vehicle:getPartById(partId) end)
    return part ~= nil
end

local function containsPart(vehicle, ids)
    if not ids then return false, nil end
    for _, nativePartId in ipairs(ids) do
        if Compat.hasVehiclePart(vehicle, nativePartId) then
            return true, nativePartId
        end
    end
    return false, nil
end

function Compat.getBlockInfo(vehicle, partId)
    if not vehicle or not partId then return nil end

    local scriptName = Compat.getVehicleScriptName(vehicle)
    local overrides = scriptName and Compat.ScriptOverrides[scriptName]
    local override = overrides and overrides[partId]
    if override then
        return {
            blocked = true,
            source = "KI5 / DAMN native armour",
            sourcePart = override.nativePart,
            reason = override.reason or "This part is already protected by KI5 native armour.",
            scriptName = scriptName,
            partId = partId,
        }
    end

    local mappedParts = Compat.NativePartMap[partId]
    local found, nativePartId = containsPart(vehicle, mappedParts)
    if found then
        return {
            blocked = true,
            source = "KI5 / DAMN native armour",
            sourcePart = nativePartId,
            reason = "This location already has KI5 native armour support and SVU4 invisible armour is disabled here to prevent stacking.",
            scriptName = scriptName,
            partId = partId,
        }
    end

    return nil
end

function Compat.isBlocked(vehicle, partId)
    local info = Compat.getBlockInfo(vehicle, partId)
    if info and info.blocked then
        return true, info
    end
    return false, nil
end

function Compat.getBlockedReason(vehicle, partId, action)
    local blocked, info = Compat.isBlocked(vehicle, partId)
    if not blocked then return nil end

    local actionWord = action or "install"
    local sourcePart = info and info.sourcePart and (" (" .. tostring(info.sourcePart) .. ")") or ""

    if actionWord == "install" then
        return "Blocked: KI5 native armour already covers this location" .. sourcePart .. ". SVU4 invisible armour is disabled here to prevent stacking."
    elseif actionWord == "repair" then
        return "Blocked: This SVU4 part overlaps a KI5 native armour location" .. sourcePart .. ". Repair is disabled here to avoid compatibility issues."
    elseif actionWord == "uninstall" then
        return "Blocked: This SVU4 part overlaps a KI5 native armour location" .. sourcePart .. ". Uninstall is disabled here to avoid compatibility issues."
    end

    return info.reason or "Blocked by KI5 native armour compatibility mode."
end

function Compat.isAnyDAMNArmourPresent(vehicle)
    if not vehicle then return false end
    for _, ids in pairs(Compat.NativePartMap) do
        local found = containsPart(vehicle, ids)
        if found then return true end
    end

    local scriptName = Compat.getVehicleScriptName(vehicle)
    return scriptName ~= nil and Compat.ScriptOverrides[scriptName] ~= nil
end
