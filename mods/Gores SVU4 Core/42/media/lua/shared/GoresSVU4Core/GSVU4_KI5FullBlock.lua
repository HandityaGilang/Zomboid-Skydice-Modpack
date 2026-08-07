--========================================================
-- Gore's SVU4 Core - KI5 Full Vehicle Block Helper
--========================================================

require "GoresSVU4Core/GSVU4_KI5Compatibility"

GSVU4_KI5FullBlock = GSVU4_KI5FullBlock or {}

local KNOWN_KI5_TOKENS = {
    "ki5",
    "damn",
    "82oshkosh",
    "89defender",
    "92amgeneral",
    "93ford",
    "76chrysler",
    "m998",
    "m101a3",
}

local function sandboxEnabled()
    return SandboxVars
       and SandboxVars.GoresSVU4Core
       and SandboxVars.GoresSVU4Core.BlockAllSVU4ArmorOnKI5Vehicles == true
end

function GSVU4_KI5FullBlock.IsEnabled()
    return sandboxEnabled()
end

local function safeCall(fn)
    if not fn then return nil end
    local ok, result = pcall(fn)
    if ok then return result end
    return nil
end

function GSVU4_KI5FullBlock.GetScriptName(vehicle)
    if not vehicle then return nil end

    if GSVU4_KI5Compat and GSVU4_KI5Compat.getVehicleScriptName then
        local name = GSVU4_KI5Compat.getVehicleScriptName(vehicle)
        if name then return tostring(name) end
    end

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

local function scriptLooksKI5(scriptName)
    if not scriptName then return false end

    local lower = string.lower(tostring(scriptName))
    for _, token in ipairs(KNOWN_KI5_TOKENS) do
        if string.find(lower, token, 1, true) then
            return true
        end
    end

    return false
end

local function hasDAMNModData(vehicle)
    if not vehicle or not vehicle.getPartCount or not vehicle.getPartByIndex then return false end

    local count = safeCall(function() return vehicle:getPartCount() end)
    if not count then return false end

    for i = 0, count - 1 do
        local part = safeCall(function() return vehicle:getPartByIndex(i) end)
        if part then
            local pid = part.getId and tostring(part:getId() or "") or ""
            local lowerPid = string.lower(pid)

            if string.find(lowerPid, "damn", 1, true)
            or string.find(lowerPid, "armor", 1, true)
            or string.find(lowerPid, "armour", 1, true)
            then
                return true
            end

            if part.getModData then
                local md = safeCall(function() return part:getModData() end)
                if type(md) == "table" then
                    if md.damn or md.DAMN or md.saveCond or md.savedCondition or md["damn:savedCondition"] then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function GSVU4_KI5FullBlock.IsKI5Vehicle(vehicle)
    if not vehicle then return false, nil end

    local scriptName = GSVU4_KI5FullBlock.GetScriptName(vehicle)

    if scriptLooksKI5(scriptName) then
        return true, scriptName
    end

    if GSVU4_KI5Compat and GSVU4_KI5Compat.isAnyDAMNArmourPresent then
        local ok, result = pcall(function()
            return GSVU4_KI5Compat.isAnyDAMNArmourPresent(vehicle)
        end)
        if ok and result == true then
            return true, scriptName
        end
    end

    if hasDAMNModData(vehicle) then
        return true, scriptName
    end

    return false, scriptName
end

function GSVU4_KI5FullBlock.IsBlocked(vehicle)
    if not sandboxEnabled() then return false end
    local isKI5 = GSVU4_KI5FullBlock.IsKI5Vehicle(vehicle)
    return isKI5 == true
end

function GSVU4_KI5FullBlock.GetBlockedMessage(vehicle)
    local _, scriptName = GSVU4_KI5FullBlock.IsKI5Vehicle(vehicle)
    if scriptName and scriptName ~= "" then
        return "SVU4 armor disabled for KI5 vehicle: " .. tostring(scriptName)
    end
    return "SVU4 armor disabled for KI5 / that DAMN Library vehicles."
end
