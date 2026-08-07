--========================================================
-- Gore's SVU4 Core - Roof Lights server state/battery drain
-- Side/rear options version
--========================================================

GSVU4 = GSVU4 or {}
GSVU4.RoofLightFloodServer = GSVU4.RoofLightFloodServer or {}

local BATTERY_MIN = 0.002
local DRAIN_PER_MINUTE = 0.00010
local LIGHT_IDS = { "RoofLights", "RoofLightsLeft", "RoofLightsRight", "RoofLightsRear" }

local function safeNum(value, fallback)
    local n = tonumber(value)
    if n == nil then return fallback or 0 end
    return n
end

local function valueMatches(a, b)
    if a == nil or b == nil then return false end
    if tostring(a) == tostring(b) then return true end
    local na, nb = tonumber(a), tonumber(b)
    return na ~= nil and nb ~= nil and na == nb
end

local function coordsMatch(vehicle, args)
    if not vehicle or not args or args.vehicleX == nil or args.vehicleY == nil then return false end
    if not vehicle.getX or not vehicle.getY then return false end
    local okX, vx = pcall(function() return vehicle:getX() end)
    local okY, vy = pcall(function() return vehicle:getY() end)
    if not okX or not okY then return false end
    if math.abs(safeNum(vx, 0) - safeNum(args.vehicleX, 0)) > 3 then return false end
    if math.abs(safeNum(vy, 0) - safeNum(args.vehicleY, 0)) > 3 then return false end
    return true
end

local function vehicleMatches(vehicle, args)
    if not vehicle or not args then return false end
    if args.vehicleOnlineId ~= nil and vehicle.getOnlineID then
        local ok, value = pcall(function() return vehicle:getOnlineID() end)
        if ok and valueMatches(value, args.vehicleOnlineId) then return true end
    end
    if args.vehicleId ~= nil and vehicle.getId then
        local ok, value = pcall(function() return vehicle:getId() end)
        if ok and valueMatches(value, args.vehicleId) then return true end
    end
    return coordsMatch(vehicle, args)
end

local function iterateVehicles(callback)
    local cell = getCell and getCell() or nil
    if not cell or not cell.getVehicles then return end
    local ok, vehicles = pcall(function() return cell:getVehicles() end)
    if not ok or not vehicles then return end
    if vehicles.size and vehicles.get then
        for i = 0, vehicles:size() - 1 do
            local okV, vehicle = pcall(function() return vehicles:get(i) end)
            if okV and vehicle then callback(vehicle) end
        end
    elseif type(vehicles) == "table" then
        for _, vehicle in pairs(vehicles) do callback(vehicle) end
    end
end

local function getVehicleFromArgs(args)
    local found = nil
    iterateVehicles(function(vehicle)
        if not found and vehicleMatches(vehicle, args) then found = vehicle end
    end)
    return found
end

local function anyInstalled(vehicle)
    if not vehicle or not vehicle.getModData then return false end
    local vdata = vehicle:getModData()
    local up = vdata and vdata.gUpgrades
    if not up then return false end
    for _, id in ipairs(LIGHT_IDS) do
        if up[id] and up[id].grade ~= nil then return true end
    end
    return false
end


local function lightDirectionUsable(vehicle, upgradeId)
    if not vehicle then return false end
    if not (GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.isInstalled and GSVU4.RoofLights.isInstalled(vehicle, upgradeId)) then
        return false
    end
    if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.hasLightPart then
        local ok, result = pcall(function() return GSVU4.RoofLights.hasLightPart(vehicle, upgradeId) end)
        if ok then return result == true end
    end
    return true
end

local function itemFullType(item)
    if not item then return nil end
    if item.getFullType then
        local ok, value = pcall(function() return item:getFullType() end)
        if ok and value then return tostring(value) end
    end
    local moduleName = "Base"
    if item.getModule then
        local ok, value = pcall(function() return item:getModule() end)
        if ok and value then moduleName = tostring(value) end
    end
    if item.getType then
        local ok, value = pcall(function() return item:getType() end)
        if ok and value then return moduleName .. "." .. tostring(value) end
    end
    return nil
end

local function consumePlayerItem(player, fullType, amount)
    local remaining = math.ceil(tonumber(amount) or 1)
    if remaining <= 0 then return true end
    if not player or not fullType or not player.getInventory then return false end
    local inv = player:getInventory()
    if not inv or not inv.getItems then return false end

    while remaining > 0 do
        local found = nil
        local items = inv:getItems()
        if not items then return false end
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if itemFullType(item) == fullType then found = item; break end
        end
        if not found then return false end
        local container = found.getContainer and found:getContainer() or inv
        if container and container.Remove then
            local ok = pcall(function() container:Remove(found) end)
            if not ok then return false end
        else
            return false
        end
        remaining = remaining - 1
    end
    return true
end

local function currentActive(vehicle)
    if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.isActive then
        local ok, active = pcall(function() return GSVU4.RoofLights.isActive(vehicle) end)
        if ok then return active == true end
    end
    local vdata = vehicle and vehicle.getModData and vehicle:getModData() or nil
    return vdata and vdata.gRoofLightToggleActive == true
end

local function getBatteryCharge(vehicle)
    if not vehicle or not vehicle.getBatteryCharge then return 0 end
    local ok, value = pcall(function() return vehicle:getBatteryCharge() end)
    if ok and value ~= nil then return tonumber(value) or 0 end
    return 0
end

local function sendState(player, vehicle, active)
    if not player or not sendServerCommand then return end
    local args = { active = active == true }
    if vehicle then
        if vehicle.getId then local ok, value = pcall(function() return vehicle:getId() end); if ok then args.vehicleId = value end end
        if vehicle.getOnlineID then local ok, value = pcall(function() return vehicle:getOnlineID() end); if ok then args.vehicleOnlineId = value end end
    end
    sendServerCommand(player, "GoresSVU4Core", "RoofLightsActiveState", args)
end


local function sendColorState(player, vehicle, colorKey, targetUpgradeId)
    if not player or not sendServerCommand then return end
    local args = { colorKey = tostring(colorKey or "WarmWhite"), targetUpgradeId = tostring(targetUpgradeId or "RoofLights") }
    if vehicle then
        if vehicle.getId then local ok, value = pcall(function() return vehicle:getId() end); if ok then args.vehicleId = value end end
        if vehicle.getOnlineID then local ok, value = pcall(function() return vehicle:getOnlineID() end); if ok then args.vehicleOnlineId = value end end
    end
    sendServerCommand(player, "GoresSVU4Core", "RoofLightColorState", args)
end

local function setActive(player, vehicle, active)
    if not vehicle or not anyInstalled(vehicle) then return end
    local vdata = vehicle:getModData()
    vdata.gUpgrades = vdata.gUpgrades or {}
    vdata.gRoofLightToggleActive = active == true
    for _, id in ipairs(LIGHT_IDS) do
        if vdata.gUpgrades[id] then vdata.gUpgrades[id].active = active == true end
    end
    if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.applyLightActive then
        pcall(function() GSVU4.RoofLights.applyLightActive(vehicle, active == true) end)
    end
    if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.applySingleLight and lightDirectionUsable(vehicle, "RoofLightsRear") then
        pcall(function() GSVU4.RoofLights.applySingleLight(vehicle, "RoofLightsRear", active == true, true) end)
    end
    if vehicle.transmitModData then pcall(function() vehicle:transmitModData() end) end
    sendState(player, vehicle, active)
end

local function onClientCommand(module, command, player, args)
    if module ~= "GoresSVU4Core" then return end
    local vehicle = getVehicleFromArgs(args)
    if not vehicle then return end

    if command == "SetRoofLightsActive" then
        setActive(player, vehicle, args and args.active == true)
        return
    end

    if command == "SetRoofLightColor" then
        if not anyInstalled(vehicle) then return end
        local targetUpgradeId = tostring((args and args.targetUpgradeId) or "RoofLights")
        if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.normalizeUpgradeId then
            targetUpgradeId = GSVU4.RoofLights.normalizeUpgradeId(targetUpgradeId)
        end
        if not lightDirectionUsable(vehicle, targetUpgradeId) then
            return
        end
        local colorKey = tostring((args and args.colorKey) or "WarmWhite")
        local def = GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.getColorDef and GSVU4.RoofLights.getColorDef(colorKey) or nil
        if not def then return end
        local currentKey = GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.getVehicleColorKey and GSVU4.RoofLights.getVehicleColorKey(vehicle, targetUpgradeId) or "WarmWhite"
        local changed = tostring(currentKey or "WarmWhite") ~= tostring(colorKey)
        local neededBulbs = tonumber(def.itemCount) or 1
        if changed and def.itemType and not consumePlayerItem(player, def.itemType, neededBulbs) then
            return
        end
        if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.setVehicleColor then
            pcall(function() GSVU4.RoofLights.setVehicleColor(vehicle, colorKey, targetUpgradeId) end)
        end
        if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.applySingleLight then
            pcall(function() GSVU4.RoofLights.applySingleLight(vehicle, targetUpgradeId, currentActive(vehicle), true) end)
        elseif GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.applyLightActive then
            pcall(function() GSVU4.RoofLights.applyLightActive(vehicle, currentActive(vehicle)) end)
        end
        if vehicle.transmitModData then pcall(function() vehicle:transmitModData() end) end
        sendColorState(player, vehicle, colorKey, targetUpgradeId)
        return
    end
end

local function chargeBattery(vehicle, amount)
    if not vehicle then return end
    if VehicleUtils and VehicleUtils.chargeBattery then
        pcall(function() VehicleUtils.chargeBattery(vehicle, amount) end)
    end
end

local function drainActiveRoofLights()
    iterateVehicles(function(vehicle)
        if not anyInstalled(vehicle) then return end
        local vdata = vehicle:getModData()
        if not vdata or vdata.gRoofLightToggleActive ~= true then return end

        if getBatteryCharge(vehicle) <= BATTERY_MIN then
            vdata.gRoofLightToggleActive = false
            if vdata.gUpgrades then
                for _, id in ipairs(LIGHT_IDS) do
                    if vdata.gUpgrades[id] then vdata.gUpgrades[id].active = false end
                end
            end
            if GSVU4 and GSVU4.RoofLights and GSVU4.RoofLights.applyLightActive then
                pcall(function() GSVU4.RoofLights.applyLightActive(vehicle, false) end)
            end
            if vehicle.transmitModData then pcall(function() vehicle:transmitModData() end) end
            return
        end

        local engineRunning = false
        if vehicle.isEngineRunning then
            local ok, running = pcall(function() return vehicle:isEngineRunning() end)
            engineRunning = ok and running == true
        end

        if not engineRunning then
            chargeBattery(vehicle, -(DRAIN_PER_MINUTE * 10))
        end
    end)
end

Events.OnClientCommand.Add(onClientCommand)
Events.EveryTenMinutes.Add(drainActiveRoofLights)
