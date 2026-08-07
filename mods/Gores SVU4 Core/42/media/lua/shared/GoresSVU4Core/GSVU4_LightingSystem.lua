--========================================================
-- Gore's SVU4 Core - Roof Lighting System bridge
--
-- Core owns the upgrade state and injects a lightweight
-- GSVU4RoofLights vehicle part into vehicle scripts. Optional
-- visual packs, such as Gore's SVU4 Vanilla Cars, register model
-- mappings before OnGameBoot. If no visual pack is loaded, the
-- upgrade still installs and stores state, but no 3D model appears.
--========================================================

GSVU4 = GSVU4 or {}
GSVU4.RoofLights = GSVU4.RoofLights or {}

GSVU4.RoofLights.GRADE_ITEM = {
    Basic = "Base.GSVU4RoofLightsBasic",
}

function GSVU4.RoofLights.gradeToItemType(grade)
    return GSVU4.RoofLights.GRADE_ITEM[grade] or GSVU4.RoofLights.GRADE_ITEM.Basic
end

GSVU4.RoofLights.VisualModelByScriptName = GSVU4.RoofLights.VisualModelByScriptName or {}
GSVU4.RoofLights.VisualModelPatterns = GSVU4.RoofLights.VisualModelPatterns or {}

local function GSVU4_RoofLightsIsMPClient()
    return isClient and isClient() == true
end

function GSVU4.RoofLights.registerVisualModels(map, patterns)
    if type(map) == "table" then
        for scriptName, row in pairs(map) do
            if scriptName and row then
                if type(row) == "table" then
                    GSVU4.RoofLights.VisualModelByScriptName[tostring(scriptName)] = {
                        main = row.main or row[1],
                        bulbs = row.bulbs or row[2],
                    }
                else
                    GSVU4.RoofLights.VisualModelByScriptName[tostring(scriptName)] = { main = tostring(row) }
                end
            end
        end
    end

    if type(patterns) == "table" then
        for _, row in ipairs(patterns) do
            if type(row) == "table" and row[1] and row[2] then
                local model = row[2]
                if type(model) == "table" then
                    model = { main = model.main or model[1], bulbs = model.bulbs or model[2] }
                else
                    model = { main = tostring(model) }
                end
                GSVU4.RoofLights.VisualModelPatterns[#GSVU4.RoofLights.VisualModelPatterns + 1] = {
                    tostring(row[1]), model
                }
            end
        end
    end
end

function GSVU4.RoofLights.resolveVisualModel(vehicleScriptFullName)
    if not vehicleScriptFullName then return nil end
    local scriptName = tostring(vehicleScriptFullName):gsub("^[^%.]+%.", "")
    local direct = GSVU4.RoofLights.VisualModelByScriptName[scriptName]
    if direct then return direct end

    local lower = string.lower(scriptName)
    for _, row in ipairs(GSVU4.RoofLights.VisualModelPatterns or {}) do
        if row and row[1] and row[2] and string.find(lower, tostring(row[1]), 1, true) then
            return row[2]
        end
    end
    return nil
end

function GSVU4.RoofLights.setVisualVisible(vehicle, part, visible)
    if not part or not part.setModelVisible then return false end

    pcall(function()
        part:setModelVisible("Default", visible == true)
    end)
    pcall(function()
        part:setModelVisible("Bulbs", visible == true)
    end)

    if not GSVU4_RoofLightsIsMPClient()
    and vehicle
    and vehicle.transmitPartModData then
        pcall(function()
            vehicle:transmitPartModData(part)
        end)
    end

    return true
end

function GSVU4.RoofLights.setPartItem(vehicle, part, fullType)
    if not part then return false end

    -- MP clients never mutate or transmit the native mechanics item.
    if GSVU4_RoofLightsIsMPClient() then
        return GSVU4.RoofLights.setVisualVisible(
            vehicle,
            part,
            fullType ~= nil
        )
    end

    if not fullType then
        pcall(function()
            part:setInventoryItem(nil)
        end)
        GSVU4.RoofLights.setVisualVisible(
            vehicle,
            part,
            false
        )

        if vehicle and vehicle.transmitPartItem then
            pcall(function()
                vehicle:transmitPartItem(part)
            end)
        end
        return true
    end

    if not instanceItem then return false end
    local ok, item = pcall(function()
        return instanceItem(fullType)
    end)
    if not ok or not item then return false end

    pcall(function()
        part:setInventoryItem(item)
    end)
    GSVU4.RoofLights.setVisualVisible(
        vehicle,
        part,
        true
    )

    if vehicle and vehicle.transmitPartItem then
        pcall(function()
            vehicle:transmitPartItem(part)
        end)
    end

    return true
end


GSVU4.RoofLights.Create = {}
GSVU4.RoofLights.Init = {}
GSVU4.RoofLights.Update = {}

function GSVU4.RoofLights.getUpgradeIdForPartId(partId)
    local map = {
        GSVU4RoofLights = "RoofLights",
        GSVU4RoofLightsLeft = "RoofLightsLeft",
        GSVU4RoofLightsRight = "RoofLightsRight",
        GSVU4RoofLightsRear = "RoofLightsRear",
    }
    return map[tostring(partId)] or "RoofLights"
end

function GSVU4.RoofLights.isInstalled(vehicle, upgradeId)
    if not vehicle or not vehicle.getModData then return false end
    local vdata = vehicle:getModData()
    local up = vdata and vdata.gUpgrades
    if not up then return false end
    if upgradeId then
        return up[upgradeId] ~= nil and up[upgradeId].grade ~= nil
    end
    return (up.RoofLights and up.RoofLights.grade ~= nil)
        or (up.RoofLightsLeft and up.RoofLightsLeft.grade ~= nil)
        or (up.RoofLightsRight and up.RoofLightsRight.grade ~= nil)
        or (up.RoofLightsRear and up.RoofLightsRear.grade ~= nil)
end

function GSVU4.RoofLights.isActive(vehicle)
    if not GSVU4.RoofLights.isInstalled(vehicle) then return false end
    local vdata = vehicle:getModData()
    if vdata and vdata.gRoofLightToggleActive == true then return true end
    local up = vdata and vdata.gUpgrades
    return up and up.RoofLights and up.RoofLights.active == true
end


GSVU4.RoofLights.ColorOrder = {
    "Blue",
    "Cyan",
    "Green",
    "Magenta",
    "Orange",
    "Pink",
    "Purple",
    "Red",
    "WarmWhite",
    "Yellow",
}

GSVU4.RoofLights.ColorDefs = {
    WarmWhite = { label = "Warm White", rgb = {1.0, 0.95, 0.82}, itemType = nil },
    Red       = { label = "Red",        rgb = {1.0, 0.0, 0.0},  itemType = "Base.LightBulbRed", itemCount = 2 },
    Orange    = { label = "Orange",     rgb = {1.0, 0.5, 0.0},  itemType = "Base.LightBulbOrange", itemCount = 2 },
    Yellow    = { label = "Yellow",     rgb = {1.0, 1.0, 0.0},  itemType = "Base.LightBulbYellow", itemCount = 2 },
    Green     = { label = "Green",      rgb = {0.0, 1.0, 0.0},  itemType = "Base.LightBulbGreen", itemCount = 2 },
    Cyan      = { label = "Cyan",       rgb = {0.0, 1.0, 1.0},  itemType = "Base.LightBulbCyan", itemCount = 2 },
    Blue      = { label = "Blue",       rgb = {0.0, 0.0, 1.0},  itemType = "Base.LightBulbBlue", itemCount = 2 },
    Purple    = { label = "Purple",     rgb = {0.5, 0.0, 1.0},  itemType = "Base.LightBulbPurple", itemCount = 2 },
    Pink      = { label = "Pink",       rgb = {1.0, 0.0784, 0.576}, itemType = "Base.LightBulbPink", itemCount = 2 },
    Magenta   = { label = "Magenta",    rgb = {1.0, 0.0, 1.0},  itemType = "Base.LightBulbMagenta", itemCount = 2 },
}

function GSVU4.RoofLights.getColorDef(colorKey)
    local key = tostring(colorKey or "WarmWhite")
    return GSVU4.RoofLights.ColorDefs[key] or GSVU4.RoofLights.ColorDefs.WarmWhite
end

GSVU4.RoofLights.UpgradeIds = { "RoofLights", "RoofLightsLeft", "RoofLightsRight", "RoofLightsRear" }
GSVU4.RoofLights.PartIdToUpgradeId = {
    GSVU4RoofLights = "RoofLights",
    GSVU4RoofLightsLeft = "RoofLightsLeft",
    GSVU4RoofLightsRight = "RoofLightsRight",
    GSVU4RoofLightsRear = "RoofLightsRear",
}

function GSVU4.RoofLights.normalizeUpgradeId(upgradeIdOrPartId)
    local key = tostring(upgradeIdOrPartId or "RoofLights")
    return GSVU4.RoofLights.PartIdToUpgradeId[key] or key
end

function GSVU4.RoofLights.getVehicleColorKey(vehicle, upgradeIdOrPartId)
    local upgradeId = GSVU4.RoofLights.normalizeUpgradeId(upgradeIdOrPartId)
    if not vehicle or not vehicle.getModData then return "WarmWhite" end
    local vdata = vehicle:getModData()
    local colors = vdata and vdata.gRoofLightColorKeys or nil
    local legacy = tostring((vdata and vdata.gRoofLightColorKey) or "WarmWhite")
    if type(colors) == "table" and colors[upgradeId] then
        return tostring(colors[upgradeId])
    end
    return legacy
end

function GSVU4.RoofLights.setVehicleColor(vehicle, colorKey, upgradeIdOrPartId)
    if not vehicle or not vehicle.getModData then return false end
    local def = GSVU4.RoofLights.getColorDef(colorKey)
    if not def then return false end
    local upgradeId = GSVU4.RoofLights.normalizeUpgradeId(upgradeIdOrPartId)
    local vdata = vehicle:getModData()
    vdata.gRoofLightColorKeys = vdata.gRoofLightColorKeys or {}
    vdata.gRoofLightColorKeys[upgradeId] = tostring(colorKey or "WarmWhite")
    if upgradeId == "RoofLights" then
        vdata.gRoofLightColorKey = tostring(colorKey or "WarmWhite")
    elseif not vdata.gRoofLightColorKey then
        vdata.gRoofLightColorKey = tostring(colorKey or "WarmWhite")
    end
    if vehicle.transmitModData then pcall(function() vehicle:transmitModData() end) end
    return true
end

function GSVU4.RoofLights.getVehicleColor(vehicle, upgradeIdOrPartId)
    local key = GSVU4.RoofLights.getVehicleColorKey(vehicle, upgradeIdOrPartId)
    local def = GSVU4.RoofLights.getColorDef(key)
    return def and def.rgb or {1.0, 0.95, 0.82}
end

GSVU4.RoofLights.PartDefs = {
    GSVU4RoofLights = {
        xOffset = 0.0, yOffset = 2.2, distance = 43.2, intensity = 1.224, dot = 0.72, focusing = 200,
        color = {1.0, 0.95, 0.82}, visual = true,
    },
    GSVU4RoofLightsLeft = {
        -- B42 spotlight X offsets are mirrored versus the UI side labels, so
        -- the left/right emitters intentionally use the opposite sign here.
        xOffset = 2.2, yOffset = 0.0, distance = 21.6, intensity = 0.612, dot = 0.55, focusing = 160,
        color = {1.0, 0.95, 0.82}, visual = false,
    },
    GSVU4RoofLightsRight = {
        -- B42 spotlight X offsets are mirrored versus the UI side labels, so
        -- the left/right emitters intentionally use the opposite sign here.
        xOffset = -2.2, yOffset = 0.0, distance = 21.6, intensity = 0.612, dot = 0.55, focusing = 160,
        color = {1.0, 0.95, 0.82}, visual = false,
    },
    GSVU4RoofLightsRear = {
        -- Pull the rear cone origin closer to the car body. The previous -3.4
        -- made the beam start too far behind the vehicle.
        xOffset = 0.0, yOffset = -1.6, distance = 38.0, intensity = 0.82, dot = 0.55, focusing = 160,
        color = {1.0, 0.95, 0.82}, visual = false,
    },
}

function GSVU4.RoofLights.getPartId(partOrId)
    if not partOrId then return "GSVU4RoofLights" end
    if type(partOrId) == "string" then return tostring(partOrId) end
    if partOrId.getId then
        local ok, v = pcall(function() return partOrId:getId() end)
        if ok and v then return tostring(v) end
    end
    return tostring(partOrId)
end

local function getPartDef(partOrId)
    local id = GSVU4.RoofLights.getPartId(partOrId)
    return GSVU4.RoofLights.PartDefs[tostring(id)] or GSVU4.RoofLights.PartDefs.GSVU4RoofLights
end

local function setPartLightActiveBool(part, active)
    if not part or not part.setLightActive then return false end
    local boolActive = (active == true)
    local ok, err = pcall(function() part:setLightActive(boolActive) end)
    if not ok then
        return false
    end
    return true
end

function GSVU4.RoofLights.ensureVehicleSpotlight(part, def, vehicle, forceRebuild)
    if not part then return false end
    def = def or getPartDef(part)
    local focusing = def.focusing or 200
    local partId = GSVU4.RoofLights.getPartId(part)
    local upgradeId = GSVU4.RoofLights.getUpgradeIdForPartId(partId)
    local colorKey = GSVU4.RoofLights.getVehicleColorKey and GSVU4.RoofLights.getVehicleColorKey(vehicle, upgradeId) or "WarmWhite"
    local cacheKey = tostring(colorKey or "WarmWhite") .. "|" .. tostring(def.xOffset or 0) .. "|" .. tostring(def.yOffset or 0) .. "|" .. tostring(def.distance or 0) .. "|" .. tostring(def.intensity or 0) .. "|" .. tostring(def.dot or 0) .. "|" .. tostring(focusing)

    local pdata = nil
    if part.getModData then
        local ok, md = pcall(function() return part:getModData() end)
        if ok then pdata = md end
    end

    local hasLight = false
    if part.getLight then
        local ok, light = pcall(function() return part:getLight() end)
        hasLight = ok and light ~= nil
    end

    -- Important for the four-direction picker:
    -- do not recreate every emitter on every refresh. In B42.19 this can make
    -- the last-created emitter colour win visually. Rebuild only when a part's
    -- own stored colour/settings changed, or when its light does not exist yet.
    if not forceRebuild and pdata and pdata.GSVU4_RoofLightCacheKey == cacheKey and hasLight then
        return true
    end

    local rgb = nil
    if vehicle and GSVU4.RoofLights.getVehicleColor then
        rgb = GSVU4.RoofLights.getVehicleColor(vehicle, upgradeId)
    end
    if not rgb then rgb = def.color or {1.0, 0.95, 0.82} end
    local r = tonumber(rgb[1]) or 1.0
    local g = tonumber(rgb[2]) or 0.95
    local b = tonumber(rgb[3]) or 0.82

    local created = false
    if part.createSpotLightColor then
        local ok = pcall(function()
            part:createSpotLightColor(def.xOffset or 0.0, def.yOffset or 0.0, def.distance or 36.0, def.intensity or 0.85, def.dot or 0.72, focusing, r, g, b)
        end)
        created = ok or created
    end

    if not created and part.createSpotLight then
        local ok = pcall(function()
            part:createSpotLight(def.xOffset or 0.0, def.yOffset or 0.0, def.distance or 36.0, def.intensity or 0.85, def.dot or 0.72, focusing)
        end)
        created = ok or created
    end

    if created and pdata then
        pdata.GSVU4_RoofLightCacheKey = cacheKey
        pdata.GSVU4_RoofLightColorKey = tostring(colorKey or "WarmWhite")
        pdata.GSVU4_RoofLightUpgradeId = tostring(upgradeId or "RoofLights")
    end

    return created
end

function GSVU4.RoofLights.getPartById(vehicle, partId)
    if not vehicle or not vehicle.getPartById then return nil end
    local ok, part = pcall(function() return vehicle:getPartById(partId) end)
    if ok then return part end
    return nil
end

function GSVU4.RoofLights.getPartIdForUpgrade(upgradeIdOrPartId)
    local upgradeId = GSVU4.RoofLights.normalizeUpgradeId and GSVU4.RoofLights.normalizeUpgradeId(upgradeIdOrPartId) or tostring(upgradeIdOrPartId or "RoofLights")
    local partIdByUpgrade = {
        RoofLights = "GSVU4RoofLights",
        RoofLightsLeft = "GSVU4RoofLightsLeft",
        RoofLightsRight = "GSVU4RoofLightsRight",
        RoofLightsRear = "GSVU4RoofLightsRear",
    }
    return partIdByUpgrade[upgradeId] or tostring(upgradeIdOrPartId or "GSVU4RoofLights")
end

function GSVU4.RoofLights.hasLightPart(vehicle, upgradeIdOrPartId)
    local partId = GSVU4.RoofLights.getPartIdForUpgrade(upgradeIdOrPartId)
    return GSVU4.RoofLights.getPartById(vehicle, partId) ~= nil
end

function GSVU4.RoofLights.getAllLightParts(vehicle)
    if not vehicle then return {} end
    local ids = {"GSVU4RoofLights", "GSVU4RoofLightsLeft", "GSVU4RoofLightsRight", "GSVU4RoofLightsRear"}
    local out = {}
    for _, id in ipairs(ids) do
        local part = GSVU4.RoofLights.getPartById(vehicle, id)
        if part then out[#out + 1] = part end
    end
    return out
end

function GSVU4.RoofLights.applySingleLight(vehicle, upgradeIdOrPartId, active, forceRebuild)
    if not vehicle then return false end
    local upgradeId = GSVU4.RoofLights.normalizeUpgradeId and GSVU4.RoofLights.normalizeUpgradeId(upgradeIdOrPartId) or tostring(upgradeIdOrPartId or "RoofLights")
    local partId = GSVU4.RoofLights.getPartIdForUpgrade and GSVU4.RoofLights.getPartIdForUpgrade(upgradeId) or tostring(upgradeIdOrPartId or "GSVU4RoofLights")
    local part = GSVU4.RoofLights.getPartById(vehicle, partId)
    if not part then return false end

    local allowed = (active == true and GSVU4.RoofLights.isInstalled(vehicle, upgradeId) == true)
    if allowed and vehicle.getBatteryCharge then
        local ok, charge = pcall(function() return vehicle:getBatteryCharge() end)
        if ok and tonumber(charge) and tonumber(charge) <= 0.00010 then
            allowed = false
        end
    end

    local def = getPartDef(partId)
    GSVU4.RoofLights.ensureVehicleSpotlight(part, def, vehicle, forceRebuild == true)
    setPartLightActiveBool(part, allowed)
    if not GSVU4_RoofLightsIsMPClient()
    and vehicle.transmitPartModData then
        pcall(function()
            vehicle:transmitPartModData(part)
        end)
    end
    return true
end

function GSVU4.RoofLights.applyLightActive(vehicle, active)
    if not vehicle then return false end

    local parts = GSVU4.RoofLights.getAllLightParts(vehicle)
    if not parts or #parts == 0 then return false end

    local anyInstalled = GSVU4.RoofLights.isInstalled(vehicle)
    local allowed = (anyInstalled == true and active == true)

    if allowed and vehicle.getBatteryCharge then
        local ok, charge = pcall(function() return vehicle:getBatteryCharge() end)
        if ok and tonumber(charge) and tonumber(charge) <= 0.00010 then
            allowed = false
        end
    end

    for _, part in ipairs(parts) do
        local partId = GSVU4.RoofLights.getPartId(part)
        local upgradeId = GSVU4.RoofLights.getUpgradeIdForPartId(partId)
        local partAllowed = (allowed == true and GSVU4.RoofLights.isInstalled(vehicle, upgradeId) == true)
        GSVU4.RoofLights.ensureVehicleSpotlight(part, getPartDef(partId), vehicle, false)
        setPartLightActiveBool(part, partAllowed)
        if not GSVU4_RoofLightsIsMPClient()
        and vehicle.transmitPartModData then
            pcall(function()
                vehicle:transmitPartModData(part)
            end)
        end
    end
    return true
end

local function roofLightCreateCommon(vehicle, part)
    if not vehicle or not part then return end
    pcall(function() part:setInventoryItem(nil) end)
    local def = getPartDef(part)
    GSVU4.RoofLights.ensureVehicleSpotlight(part, def, vehicle)
    setPartLightActiveBool(part, false)
end

local function roofLightInitCommon(vehicle, part)
    if not vehicle or not part then return end
    local def = getPartDef(part)
    GSVU4.RoofLights.ensureVehicleSpotlight(part, def, vehicle)

    local vdata = vehicle:getModData()
    local upgrade = vdata and vdata.gUpgrades and vdata.gUpgrades.RoofLights
    if not upgrade or not upgrade.grade then
        if def.visual then
            GSVU4.RoofLights.setPartItem(vehicle, part, nil)
        end
        setPartLightActiveBool(part, false)
        return
    end

    if def.visual then
        GSVU4.RoofLights.setPartItem(vehicle, part, GSVU4.RoofLights.gradeToItemType(upgrade.grade))
    else
        pcall(function() part:setInventoryItem(nil) end)
    end
    GSVU4.RoofLights.applyLightActive(vehicle, upgrade.active == true)
end

local function roofLightUpdateCommon(vehicle, part, elapsedMinutes)
    if not vehicle or not part then return end
    local active = GSVU4.RoofLights.isActive(vehicle)
    GSVU4.RoofLights.applyLightActive(vehicle, active)

    if active and vehicle.isEngineRunning and not vehicle:isEngineRunning() then
        if VehicleUtils and VehicleUtils.chargeBattery then
            pcall(function() VehicleUtils.chargeBattery(vehicle, -0.000035 * (tonumber(elapsedMinutes) or 0)) end)
        end
    end
end

for partId, _ in pairs(GSVU4.RoofLights.PartDefs) do
    GSVU4.RoofLights.Create[partId] = roofLightCreateCommon
    GSVU4.RoofLights.Init[partId] = roofLightInitCommon
    GSVU4.RoofLights.Update[partId] = roofLightUpdateCommon
end

local function GSVU4_BuildRoofLightsInjection(visualRow)
    -- Build ONE vehicle-script block containing the area and all linked roof-light parts.
    -- The previous SideRear build concatenated several separate root blocks; B42 only
    -- reliably kept the first block, which meant the front emitter existed but the
    -- side/rear emitter parts were missing.
    local lines = {
        "{",
            "area Rooflights { xywh = 0.0000 -0.1222 3.1333 1.9556, }",
    }

    local function addPart(partId, def)
        lines[#lines + 1] = "part " .. tostring(partId)
        lines[#lines + 1] = "{"
        lines[#lines + 1] = "category = Other,"
        lines[#lines + 1] = "area = Rooflights,"
        lines[#lines + 1] = "specificItem = false,"
        lines[#lines + 1] = "itemType = Base.GSVU4RoofLightsBasic,"
        lines[#lines + 1] = "mechanicRequireKey = false,"
        lines[#lines + 1] = "setAllModelsVisible = false,"

        if def and def.visual and visualRow and visualRow.main and tostring(visualRow.main) ~= "" then
            lines[#lines + 1] = "model Default { file = " .. tostring(visualRow.main) .. ", }"
        end
        if def and def.visual and visualRow and visualRow.bulbs and tostring(visualRow.bulbs) ~= "" then
            lines[#lines + 1] = "model Bulbs { file = " .. tostring(visualRow.bulbs) .. ", }"
        end

        lines[#lines + 1] = "lua { create = GSVU4.RoofLights.Create." .. tostring(partId) .. ", init = GSVU4.RoofLights.Init." .. tostring(partId) .. ", update = GSVU4.RoofLights.Update." .. tostring(partId) .. ", }"
        lines[#lines + 1] = "}"
    end

    local order = {"GSVU4RoofLights", "GSVU4RoofLightsLeft", "GSVU4RoofLightsRight", "GSVU4RoofLightsRear"}
    for _, partId in ipairs(order) do
        addPart(partId, GSVU4.RoofLights.PartDefs[partId])
    end

    lines[#lines + 1] = "}"
    return table.concat(lines, " ")
end

local GSVU4_roofLightsInjectedScripts = {}

local function GSVU4_InjectRoofLightsPart(vehicleScriptFullName)
    if GSVU4_roofLightsInjectedScripts[vehicleScriptFullName] then return false end
    GSVU4_roofLightsInjectedScripts[vehicleScriptFullName] = true

    local vscript = getScriptManager():getVehicle(vehicleScriptFullName)
    if not vscript then return false end
    if vscript:getPartById("GSVU4RoofLights") and vscript:getPartById("GSVU4RoofLightsLeft") and vscript:getPartById("GSVU4RoofLightsRight") and vscript:getPartById("GSVU4RoofLightsRear") then return false end

    local scriptName = string.gsub(vehicleScriptFullName, "^[^%.]+%.", "")
    local visualRow = GSVU4.RoofLights.resolveVisualModel(vehicleScriptFullName)
    local injection = GSVU4_BuildRoofLightsInjection(visualRow)
    local ok, err = pcall(function() vscript:Load(scriptName, injection) end)
    if not ok then
        return false
    end
    return true
end

Events.OnGameBoot.Add(function()
    local sm = getScriptManager()
    if not sm then return end
    local vehicles = nil
    if sm.getAllVehicleScripts then
        local ok, v = pcall(function() return sm:getAllVehicleScripts() end)
        if ok then vehicles = v end
    end
    if not vehicles and sm.getVehicles then
        local ok, v = pcall(function() return sm:getVehicles() end)
        if ok then vehicles = v end
    end
    if not vehicles then
        return
    end

    local total, injected = 0, 0
    if vehicles.size and vehicles.get then
        total = vehicles:size()
        for i = 0, total - 1 do
            local ok, vs = pcall(function() return vehicles:get(i) end)
            if ok and vs and vs.getFullName then
                local fn = vs:getFullName()
                if fn and GSVU4_InjectRoofLightsPart(fn) then injected = injected + 1 end
            end
        end
    else
        for _, vs in pairs(vehicles) do
            total = total + 1
            local fn = vs.getFullName and vs:getFullName() or nil
            if fn and GSVU4_InjectRoofLightsPart(fn) then injected = injected + 1 end
        end
    end
end)

function GSVU4.RoofLights.getPart(vehicle)
    return GSVU4.RoofLights.getPartById(vehicle, "GSVU4RoofLights")
end


function GSVU4.RoofLights.syncVisualOnly(vehicle)
    if not vehicle then return false end

    local parts =
        GSVU4.RoofLights.getAllLightParts
        and GSVU4.RoofLights.getAllLightParts(vehicle)
        or {}

    if not parts or #parts == 0 then return false end

    for _, part in ipairs(parts) do
        local partId =
            part.getId and part:getId()
            or "GSVU4RoofLights"

        local upgradeId =
            GSVU4.RoofLights.getUpgradeIdForPartId(partId)

        GSVU4.RoofLights.setVisualVisible(
            vehicle,
            part,
            GSVU4.RoofLights.isInstalled(
                vehicle,
                upgradeId
            )
        )
    end

    return true
end

function GSVU4.RoofLights.syncVehicle(vehicle)
    local parts = GSVU4.RoofLights.getAllLightParts and GSVU4.RoofLights.getAllLightParts(vehicle) or {}
    if not parts or #parts == 0 then return false end
    for _, part in ipairs(parts) do
        local partId = part.getId and part:getId() or "GSVU4RoofLights"
        local init = GSVU4.RoofLights.Init[partId]
        if init then init(vehicle, part) end
    end
    return true
end

function GSVU4_ApplyRoofLightsVisual(vehicle)
    local ok = false

    if GSVU4
    and GSVU4.RoofLights then
        local syncFunction =
            GSVU4_RoofLightsIsMPClient()
            and GSVU4.RoofLights.syncVisualOnly
            or GSVU4.RoofLights.syncVehicle

        if syncFunction then
            local ran, result = pcall(function()
                return syncFunction(vehicle)
            end)
            ok = (ran and result == true) or ok
        end
    end

    -- Gore's SVU4 Vanilla Cars also exposes a fallback that uses its existing
    -- SVU3 body-anchor visual part. This is more reliable for visual-only
    -- upgrades because those anchors are already known to refresh correctly
    -- for the armour panels.
    if GSVU4VV and GSVU4VV.ApplyRoofLightsUpgradeVisual then
        local ran, result = pcall(function() return GSVU4VV.ApplyRoofLightsUpgradeVisual(vehicle) end)
        ok = (ran and result == true) or ok
    end

    return ok
end
