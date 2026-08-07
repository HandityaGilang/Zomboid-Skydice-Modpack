--========================================================
-- Gore's SVU4 Core - PZK / ATA2 Compatibility Helper
--========================================================
-- Purpose:
--   Allow normal PZK base vehicle packs to use SVU4.
--   Only block SVU4 categories when an actual ATA2/SVU3-style overlapping
--   part slot is present on the vehicle script.
--
-- This deliberately does NOT block PZK broadly.
--========================================================

GSVU4_PZKCompat = GSVU4_PZKCompat or {}

local Compat = GSVU4_PZKCompat

Compat.ArmorPartMap = Compat.ArmorPartMap or {
    EngineDoor       = { "ATA2ProtectionHood", "ATA2ProtectionFront", "ATA2ProtectionEngineDoor" },
    Hood             = { "ATA2ProtectionHood", "ATA2ProtectionFront", "ATA2ProtectionEngineDoor" },
    HeadlightLeft    = { "ATA2ProtectionHood", "ATA2Bullbar", "ATA2ProtectionFront" },
    HeadlightRight   = { "ATA2ProtectionHood", "ATA2Bullbar", "ATA2ProtectionFront" },

    Windshield       = { "ATA2ProtectionWindshield", "ATA2ProtectionWindshieldFront" },
    WindshieldFront  = { "ATA2ProtectionWindshield", "ATA2ProtectionWindshieldFront" },
    WindshieldRear   = { "ATA2ProtectionWindshieldRear" },
    RearWindshield   = { "ATA2ProtectionWindshieldRear" },

    WindowFrontLeft  = { "ATA2ProtectionWindowFrontLeft" },
    WindowFrontRight = { "ATA2ProtectionWindowFrontRight" },
    WindowRearLeft   = { "ATA2ProtectionWindowRearLeft" },
    WindowRearRight  = { "ATA2ProtectionWindowRearRight" },

    DoorFrontLeft    = { "ATA2ProtectionDoorFrontLeft" },
    DoorFrontRight   = { "ATA2ProtectionDoorFrontRight" },
    DoorRearLeft     = { "ATA2ProtectionDoorRearLeft", "ATA2ProtectionDoorsRear" },
    DoorRearRight    = { "ATA2ProtectionDoorRearRight", "ATA2ProtectionDoorsRear" },
    DoorRear         = { "ATA2ProtectionDoorRear", "ATA2ProtectionDoorsRear" },

    TrunkDoor        = { "ATA2ProtectionTrunk", "ATA2ProtectionTrunkDoor", "ATA2ProtectionRear" },
    TruckBed         = { "ATA2ProtectionTrunk", "ATA2ProtectionRear" },
    GasTank          = { "ATA2ProtectionTrunk", "ATA2ProtectionRear" },

    TireFrontLeft    = { "ATA2ProtectionWheels" },
    TireFrontRight   = { "ATA2ProtectionWheels" },
    TireRearLeft     = { "ATA2ProtectionWheels" },
    TireRearRight    = { "ATA2ProtectionWheels" },
}

Compat.UpgradePartMap = Compat.UpgradePartMap or {
    BullBar                = { "ATA2Bullbar", "ATA2BullbarTruck" },
    RoofRack               = { "ATA2InteractiveTrunkRoofRack", "ATA2RoofRack" },
    RoofLightFront         = { "ATA2RoofLightFront", "ATA2RoofLightbar", "ATA2Megaphone" },
    RoofLightSideLeft      = { "ATA2RoofLightFront", "ATA2RoofLightbar", "ATA2Megaphone" },
    RoofLightSideRight     = { "ATA2RoofLightFront", "ATA2RoofLightbar", "ATA2Megaphone" },
    RoofLightRear          = { "ATA2RoofLightFront", "ATA2RoofLightbar", "ATA2Megaphone" },
    AutoTuneMilitaryRadio  = { "ATA2PoliceAntenna", "ATA2Antenna" },
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
                if shortName and tostring(shortName):find(".", 1, true) then
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

function Compat.getArmorBlockInfo(vehicle, partId)
    if not vehicle or not partId then return nil end
    local mappedParts = Compat.ArmorPartMap[partId]
    local found, nativePartId = containsPart(vehicle, mappedParts)
    if found then
        return {
            blocked = true,
            category = "armor",
            source = "PZK / SVU3 / ATA2 vehicle armour",
            sourcePart = nativePartId,
            scriptName = Compat.getVehicleScriptName(vehicle),
            partId = partId,
            reason = "This location already has ATA2/SVU3-style armour support. SVU4 invisible armour is disabled here to prevent stacking.",
        }
    end
    return nil
end

function Compat.isArmorBlocked(vehicle, partId)
    local info = Compat.getArmorBlockInfo(vehicle, partId)
    if info and info.blocked then return true, info end
    return false, nil
end

function Compat.getUpgradeBlockInfo(vehicle, upgradeId)
    if not vehicle or not upgradeId then return nil end

    local ids = Compat.UpgradePartMap[upgradeId]

    -- All SVU4 roof light variants share the same compatibility category.
    if not ids and tostring(upgradeId):find("RoofLight", 1, true) == 1 then
        ids = Compat.UpgradePartMap.RoofLightFront
    end

    local found, nativePartId = containsPart(vehicle, ids)
    if found then
        return {
            blocked = true,
            category = "upgrade",
            source = "PZK / SVU3 / ATA2 vehicle upgrade",
            sourcePart = nativePartId,
            scriptName = Compat.getVehicleScriptName(vehicle),
            upgradeId = upgradeId,
            reason = "This upgrade overlaps an ATA2/SVU3-style vehicle upgrade slot. SVU4 blocks it here to prevent duplicate systems.",
        }
    end

    return nil
end

function Compat.isUpgradeBlocked(vehicle, upgradeId)
    local info = Compat.getUpgradeBlockInfo(vehicle, upgradeId)
    if info and info.blocked then return true, info end
    return false, nil
end

function Compat.getArmorBlockedReason(vehicle, partId, action)
    local blocked, info = Compat.isArmorBlocked(vehicle, partId)
    if not blocked then return nil end
    local sourcePart = info and info.sourcePart and (" (" .. tostring(info.sourcePart) .. ")") or ""
    local verb = action or "install"
    if verb == "install" then
        return "Blocked: PZK/SVU3 armour already covers this location" .. sourcePart .. ". SVU4 invisible armour is disabled here to prevent stacking."
    elseif verb == "repair" then
        return "Blocked: this SVU4 armour overlaps PZK/SVU3 armour" .. sourcePart .. ". Repair is disabled here for compatibility."
    elseif verb == "uninstall" then
        return "Blocked: this SVU4 armour overlaps PZK/SVU3 armour" .. sourcePart .. ". Remove it with SVU4 disabled or remove the overlapping support mod first."
    end
    return info.reason
end

function Compat.getUpgradeBlockedReason(vehicle, upgradeId, action)
    local blocked, info = Compat.isUpgradeBlocked(vehicle, upgradeId)
    if not blocked then return nil end
    local sourcePart = info and info.sourcePart and (" (" .. tostring(info.sourcePart) .. ")") or ""
    local verb = action or "install"
    if verb == "install" then
        return "Blocked: PZK/SVU3 already provides this upgrade type" .. sourcePart .. ". SVU4 blocks it here to prevent stacking."
    elseif verb == "repair" then
        return "Blocked: this SVU4 upgrade overlaps PZK/SVU3 upgrade support" .. sourcePart .. "."
    elseif verb == "uninstall" then
        return "Blocked: this SVU4 upgrade overlaps PZK/SVU3 upgrade support" .. sourcePart .. "."
    end
    return info.reason
end

function Compat.hasAnyATA2Overlap(vehicle)
    if not vehicle then return false end
    for _, ids in pairs(Compat.ArmorPartMap) do
        local found = containsPart(vehicle, ids)
        if found then return true end
    end
    for _, ids in pairs(Compat.UpgradePartMap) do
        local found = containsPart(vehicle, ids)
        if found then return true end
    end
    return false
end
