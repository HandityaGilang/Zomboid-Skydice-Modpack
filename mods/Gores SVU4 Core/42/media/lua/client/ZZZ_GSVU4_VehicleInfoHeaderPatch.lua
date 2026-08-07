--========================================================
-- Gore's SVU4 Core - Vehicle Info Header Patch
-- Phase 1T
--
-- Adds vehicle display name and Base.* script id to the
-- VehicleArmorWindow header, similar to the vanilla mechanics UI.
--
-- Separate patch file. VehicleArmor_UI.lua is not edited.
--========================================================

if not VehicleArmorWindow then
    return
end


local function tryCall(fn)
    if not fn then return nil end
    local ok, result = pcall(fn)
    if ok then return result end
    return nil
end

local function tryText(key)
    if not key or key == "" then return nil end

    if getTextOrNull then
        local text = tryCall(function() return getTextOrNull(key) end)
        if text and text ~= "" and text ~= key then
            return text
        end
    end

    if getText then
        local text = tryCall(function() return getText(key) end)
        if text and text ~= "" and text ~= key then
            return text
        end
    end

    return nil
end

local function getVehicleScriptInfo(vehicle)
    local info = {
        name = "Unknown Vehicle",
        scriptId = "Unknown",
        fullId = "Unknown",
    }

    if not vehicle then
        return info
    end

    local script = nil
    if vehicle.getScript then
        script = tryCall(function() return vehicle:getScript() end)
    end

    local scriptName = nil
    local fullName = nil

    if script then
        if script.getName then
            scriptName = tryCall(function() return script:getName() end)
        end
        if script.getFullName then
            fullName = tryCall(function() return script:getFullName() end)
        end
    end

    if not scriptName and vehicle.getScriptName then
        scriptName = tryCall(function() return vehicle:getScriptName() end)
    end

    if not fullName and scriptName then
        fullName = "Base." .. tostring(scriptName)
    end

    local displayName = nil

    if scriptName then
        -- Try the most likely vanilla vehicle translation keys first.
        displayName =
            tryText("IGUI_VehicleName" .. tostring(scriptName))
            or tryText("IGUI_VehicleName_" .. tostring(scriptName))
            or tryText("IGUI_VehicleName." .. tostring(scriptName))
    end

    -- Some vehicle script objects expose a display/name field, but not all.
    if not displayName and script and script.getDisplayName then
        displayName = tryCall(function() return script:getDisplayName() end)
    end

    if not displayName and vehicle.getName then
        displayName = tryCall(function() return vehicle:getName() end)
    end

    info.name = tostring(displayName or scriptName or fullName or "Unknown Vehicle")
    info.scriptId = tostring(scriptName or "Unknown")
    info.fullId = tostring(fullName or scriptName or "Unknown")

    return info
end

function VehicleArmorWindow:getGSVU4VehicleInfoHeader()
    local key = tostring(self.vehicle or "no-vehicle")
    if self.gsvu4VehicleInfoHeaderKey == key and self.gsvu4VehicleInfoHeader then
        return self.gsvu4VehicleInfoHeader
    end

    local info = getVehicleScriptInfo(self.vehicle)
    local line = "Vehicle: " .. tostring(info.name)
        .. "    Base ID: " .. tostring(info.fullId)

    self.gsvu4VehicleInfoHeaderKey = key
    self.gsvu4VehicleInfoHeader = line
    return line
end

local oldPrerender = VehicleArmorWindow.prerender
function VehicleArmorWindow:prerender()
    oldPrerender(self)

    local line = self:getGSVU4VehicleInfoHeader()
    self:drawTextCentre(line, self.width / 2, 32, 0.72, 0.82, 1.00, 1, UIFont.Small)
end
