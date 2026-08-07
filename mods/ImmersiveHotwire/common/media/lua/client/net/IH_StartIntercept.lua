IH_StartIntercept = IH_StartIntercept or {}
IH_StartIntercept.nextOpenMs = IH_StartIntercept.nextOpenMs or 0
IH_StartIntercept.blockUntilMs = IH_StartIntercept.blockUntilMs or 0
IH_StartIntercept.blockSentUntilMs = IH_StartIntercept.blockSentUntilMs or 0
IH_StartIntercept._inited = IH_StartIntercept._inited == true

local SandboxSettings = require "config/IH_SandboxSettings"
local WireSeed = require "util/IH_WireSeed"
local HotwireWindow = require "ui/IH_HotwireWindow"
local DBG = require "IH_Debug"

local OPEN_DEBOUNCE_MS = 400
local BLOCK_MS = 400
local function getForwardKey()
    local core = getCore()
    if core and core.getKey then
        return core:getKey("Forward")
    end
    return Keyboard.KEY_W -- fallback
end
local lastEngineStateById = {}
local batterySnapshotsById = {}
local batteryStableById = {}

local function nowMs()
    return getTimestampMs()
end

local function shouldBlock()
    return nowMs() < IH_StartIntercept.blockUntilMs
end

local function setBlockNow()
    local now = nowMs()
    IH_StartIntercept.blockUntilMs = now + BLOCK_MS
end

local function isBatteryIgnitionConnected(vehicle)
    local map = WireSeed.getRoleIndexMap(vehicle)
    local batteryIndex = map.battery
    local ignitionIndex = map.ignition
    local data = vehicle:getModData().IH
    local wires = data and data.wires or nil
    if type(wires) ~= "table" then
        local connections = data and data.connections or nil
        local batteryTarget = connections and connections[batteryIndex] or batteryIndex
        local ignitionTarget = connections and connections[ignitionIndex] or ignitionIndex
        return batteryTarget == ignitionTarget
    end
    local batteryEntry = wires and wires[batteryIndex] or nil
    local ignitionEntry = wires and wires[ignitionIndex] or nil
    local batteryTarget = batteryIndex
    local ignitionTarget = ignitionIndex
    if type(batteryEntry) == "table" and type(batteryEntry.target) == "number" then
        batteryTarget = batteryEntry.target
    end
    if type(ignitionEntry) == "table" and type(ignitionEntry.target) == "number" then
        ignitionTarget = ignitionEntry.target
    end
    return batteryTarget == ignitionTarget
end

local function isStarterCut(vehicle)
    local map = WireSeed.getRoleIndexMap(vehicle)
    local starterIndex = map.starter
    local data = vehicle:getModData().IH
    local wires = data and data.wires or nil
    if type(wires) ~= "table" then
        local cuts = data and data.cuts or nil
        return cuts and cuts[starterIndex] == true
    end
    local entry = wires and wires[starterIndex] or nil
    return entry == "cut"
end

local function shouldInterceptHotwire(vehicle)
    if not vehicle:isHotwired() then
        return false
    end
    if SandboxSettings.isHotwireEveryTime() then
        return true
    end
    return not (isBatteryIgnitionConnected(vehicle) and isStarterCut(vehicle))
end

local function hookStartEngine()
    if ISVehicleMenu == nil then
        return
    end
    if ISVehicleMenu._IH_onStartEngineWrapped then
        return
    end
    local original = ISVehicleMenu.onStartEngine
    if not original then
        return
    end
    ISVehicleMenu._IH_onStartEngineWrapped = true
    ISVehicleMenu.onStartEngine = function(playerObj, vehicle, ...)
        if vehicle and shouldInterceptHotwire(vehicle) then
            DBG.log("Start", "intercept", { source = "menu", vehicleId = vehicle:getId() })
            HotwireWindow.showHotwireWindow(playerObj)
            return
        end
        return original(playerObj, vehicle, ...)
    end
end

local function hookDashboardKeys()
    if ISVehicleDashboard == nil then
        return
    end
    if ISVehicleDashboard._IH_onClickKeysWrapped then
        return
    end
    local original = ISVehicleDashboard.onClickKeys
    if not original then
        return
    end
    ISVehicleDashboard._IH_onClickKeysWrapped = true
    ISVehicleDashboard.onClickKeys = function(self, ...)
        if getGameSpeed() == 0 then
            return
        end
        if getGameSpeed() > 1 then
            setGameSpeed(1)
        end
        local vehicle = self.vehicle
        if vehicle and vehicle:isHotwired() and (not vehicle:isEngineRunning()) and (not vehicle:isStarting()) then
            DBG.log("Start", "intercept", { source = "dashboard", vehicleId = vehicle:getId() })
            HotwireWindow.showHotwireWindow(self.character)
            return
        end
        return original(self, ...)
    end
end

local function hookTimedActionQueue()
    if ISTimedActionQueue == nil then
        return
    end
    if ISTimedActionQueue._IH_addWrapped then
        return
    end
    local original = ISTimedActionQueue.add
    if not original then
        return
    end
    local function ih_getVehicleFromAction(action)
        if action.vehicle then
            return action.vehicle
        end
        local chr = action.character
        return chr:getVehicle()
    end
    ISTimedActionQueue._IH_addWrapped = true
    ISTimedActionQueue.add = function(action)
        if action.Type == "ISStartVehicleEngine" then
            local vehicle = ih_getVehicleFromAction(action)
            if vehicle and shouldInterceptHotwire(vehicle) then
                DBG.log("Start", "intercept", { source = "timedAction", vehicleId = vehicle:getId() })
                HotwireWindow.showHotwireWindow(action.character)
                return
            end
        end
        return original(action)
    end
end

local function getBatteryPartAndItem(vehicle)
    local part = vehicle:getPartById("Battery")
    if not part then
        return nil, nil, "batteryPartMissing=true"
    end
    local item = part:getInventoryItem()
    if not item then
        return part, nil, "batteryItemMissing=true"
    end
    return part, item, nil
end

local function snapshotBattery(vehicle)
    local id = vehicle:getId()
    if batterySnapshotsById[id] ~= nil then
        return batterySnapshotsById[id]
    end
    local stable = batteryStableById[id]
    if stable ~= nil then
        batterySnapshotsById[id] = stable
        return stable
    end
    local part, item, err = getBatteryPartAndItem(vehicle)
    if not item then
        return nil, err
    end
    local usesFloat = item:getCurrentUsesFloat()
    if usesFloat == nil then
        return nil, "batteryNotDrainable=true"
    end
    batterySnapshotsById[id] = usesFloat
    return usesFloat
end

local function restoreBattery(vehicle)
    local id = vehicle:getId()
    local snap = batterySnapshotsById[id]
    if snap == nil then
        return false, nil, nil
    end
    local part, item, err = getBatteryPartAndItem(vehicle)
    if not item then
        return false, err, nil
    end
    local before = item:getCurrentUsesFloat()
    if before == nil then
        batterySnapshotsById[id] = nil
        return false, "batteryNotDrainable=true", nil
    end
    item:setCurrentUsesFloat(snap)
    vehicle:transmitPartUsedDelta(part)
    batterySnapshotsById[id] = nil
    local after = item:getCurrentUsesFloat()
    return true, nil, { before = before, after = after }
end

local function onPlayerUpdate(player)
    local vehicle = player:getVehicle()
    if not vehicle then
        return
    end
    if not shouldInterceptHotwire(vehicle) then
        return
    end
    local seat = vehicle:getSeat(player)
    if seat ~= 0 then
        return
    end
    local vehicleId = vehicle:getId()
    local last = lastEngineStateById[vehicleId] or { starting = false }
    local starting = vehicle:isStarting()
    local forwardKey = getForwardKey()
    local forwardDown = forwardKey and GameKeyboard.isKeyDown(forwardKey)

    if (not starting) and (not forwardDown) and (not shouldBlock()) then
        local part, item = getBatteryPartAndItem(vehicle)
        if item then
            local usesFloat = item:getCurrentUsesFloat()
            if usesFloat ~= nil then
                batteryStableById[vehicleId] = usesFloat
            end
        end
    end

    if (not last.starting) and starting then
        snapshotBattery(vehicle)
        vehicle:engineDoStartingFailed()
        vehicle:engineDoIdle()
        restoreBattery(vehicle)
    end

    last.starting = starting
    lastEngineStateById[vehicleId] = last

    if not forwardDown then
        return
    end

    if vehicle:isEngineRunning() or vehicle:isStarting() then
        return
    end

    if shouldBlock() then
        local forwardKey = getForwardKey()
        if forwardKey then
            GameKeyboard.eatKeyPress(forwardKey)
        end
        return
    end

    snapshotBattery(vehicle)
    local forwardKey = getForwardKey()
    if forwardKey then
        GameKeyboard.eatKeyPress(forwardKey)
    end
    setBlockNow()
    if isClient() then
        local untilMs = IH_StartIntercept.blockUntilMs
        if untilMs > (IH_StartIntercept.blockSentUntilMs or 0) then
            sendClientCommand("IH", "BlockStart", {
                vehicleId = vehicle:getId(),
                untilMs = untilMs,
                reason = "W",
            })
            IH_StartIntercept.blockSentUntilMs = untilMs
        end
    end

    if vehicle:isStarting() then
        vehicle:engineDoStartingFailed()
        vehicle:engineDoIdle()
    end

    local now = nowMs()
    if now < IH_StartIntercept.nextOpenMs then
        return
    end
    IH_StartIntercept.nextOpenMs = now + OPEN_DEBOUNCE_MS
    DBG.log("Start", "intercept", { source = "forward", vehicleId = vehicle:getId() })
    HotwireWindow.showHotwireWindow(player)
    restoreBattery(vehicle)
end

function IH_StartIntercept.init()
    if IH_StartIntercept._inited then
        return
    end
    IH_StartIntercept._inited = true
    Events.OnPlayerUpdate.Add(onPlayerUpdate)
    Events.OnGameBoot.Add(hookStartEngine)
    Events.OnGameBoot.Add(hookDashboardKeys)
    Events.OnGameBoot.Add(hookTimedActionQueue)
end

return IH_StartIntercept




