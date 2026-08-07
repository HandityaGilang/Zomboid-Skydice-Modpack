require "TubFluidContainer/TABAS_TubFluidContainerSystemData"

local TFC_Utils = {}
local GLOBAL_TRANSMIT_COOLDOWN_MS = 350
local lastGlobalTransmitMs = 0

----------------- Definitions -----------------
-- GlobalModData table names.
TFC_Utils.Registered = "Registered"
TFC_Utils.Activated = "Activated"
TFC_Utils.PendedRemove = "PendedRemove"

TFC_Utils.Name = "TubFluidContainer"
TFC_Utils.FluidContainerName = "TubFluidContainer"
TFC_Utils.DefaultTemperature = 22.0
TFC_Utils.DefaultColors = {r=0.529, g=0.808, b=0.98, a=0.50} -- LightSkyBlue
TFC_Utils.Filled_Low = 0.05
TFC_Utils.Filled_HalfLow = 0.30
TFC_Utils.Filled_Half = 0.55
TFC_Utils.Filled_Full = 0.80
TFC_Utils.HotWaterTemp = 40.0

TFC_Utils.FillRate = 0.08
TFC_Utils.DrainRate = 0.2
TFC_Utils.ReheatRate = 0.01
TFC_Utils.TubWaterCoolingPerHour = 1.0

TFC_Utils.RegisteredKeys = {"amount", "capacity", "temperature", "lastUpdate", "dirtyLevel", "bathSalt", "rainCatcher"}
TFC_Utils.RegisteredDeferredSyncKeys = {
    amount = true,
    temperature = true,
    lastUpdate = true,
    dirtyLevel = true,
}
TFC_Utils.RegisteredExtraKeys = {"linkedX", "linkedY", "facing"}
TFC_Utils.RegisteredLinkedKeys = {"isLinked", "mainId"}
TFC_Utils.ObjectModDataKeys = {"amount", "capacity", "temperature", "lastUpdate", "dirtyLevel", "bathSalt", "rainCatcher", "linkedX", "linkedY", "facing"}

----------------- ----------------- -----------------

function TFC_Utils.noise(title, ...)
    if not isDebugEnabled() then return end
    local t = {...}
    local str = "[TABAS TFC_System] " .. title .. ":"
    for i=1, #t do str = str .. " " .. t[i] end
    print(str)
end

function TFC_Utils.formatCoords(x, y, z)
    local text = string.format("x=%s, y=%s, z=%s", x, y, z)
    return text
end

function TFC_Utils.getIdByCoords(x, y, z)
    local id = x .. "-" .. y .. "-" .. z
    return id
end

function TFC_Utils.getCoordsById(id)
    local x, y, z = string.match(id, "([^%-]+)%-(.-)%-(.+)")
    return tonumber(x), tonumber(y), tonumber(z)
end

function TFC_Utils.getMainCoordsFromLinked(x, y, z, facing)
    if facing == "N" then
        return x, y + 1, z
    elseif facing == "S" then
        return x, y - 1, z
    elseif facing == "E" then
        return x - 1, y, z
    elseif facing == "W" then
        return x + 1, y, z
    end
    return nil
end

----------------- For Get Data -----------------
-- Read only.
-- table is "Registered" or "Activated" or "PendedRemove"
function TFC_Utils.getTFCData(x, y, z, table, key)
    local gData = GetTFCSystemData()
    if not gData or not gData[table] then return end
    local id = TFC_Utils.getIdByCoords(x, y, z)

    if not key then
        return gData[table][id]
    end
    if gData[table][id] then
        return gData[table][id][key]
    end
    return nil
end

-- Registered Data from (main/linked) square.
function TFC_Utils.getTFCRegisteredData(sq, bDirect)
    if not sq then return nil end
    local gData = GetTFCSystemData()
    if not gData or not gData.Registered then return nil end

    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local id = TFC_Utils.getIdByCoords(x, y, z)
    local data = gData.Registered[id]
    if not data then return nil end

    if not bDirect and data.isLinked and data.mainId then
        return gData.Registered[data.mainId]
    end
    return data
end

function TFC_Utils.getRegisterdIdFromSquare(sq, shouldMain)
    local data = TFC_Utils.getTFCRegisteredData(sq, true) -- direct
    if not data then return nil end

    if shouldMain and data.isLinked and data.mainId then
        return data.mainId
    end

    return TFC_Utils.getIdByCoords(sq:getX(), sq:getY(), sq:getZ())
end

-- check tfc data (main/linked) on square.
function TFC_Utils.hasTfcData(sq)
    if not sq then return false end
    local gData = GetTFCSystemData()
    if not gData or not gData.Registered then return false end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local id = TFC_Utils.getIdByCoords(x, y, z)
    return gData.Registered[id] ~= nil
end

----------------- Data Keys -----------------

function TFC_Utils.getRegisteredKeys()
    return TFC_Utils.RegisteredKeys
end

function TFC_Utils.shouldDeferRegisteredKeySync(key)
    return TFC_Utils.RegisteredDeferredSyncKeys[key] == true
end

function TFC_Utils.getRegisteredExtraKeys()
    return TFC_Utils.RegisteredExtraKeys
end

function TFC_Utils.getRegisteredLinkedKeys()
    return TFC_Utils.RegisteredLinkedKeys
end

function TFC_Utils.getObjectModDataKeys()
    return TFC_Utils.ObjectModDataKeys
end

function TFC_Utils.isRegisteredKey(key)
    local keys = TFC_Utils.RegisteredKeys
    for i = 1, #keys do
        if keys[i] == key then return true end
    end

    local extra = TFC_Utils.RegisteredExtraKeys
    for i = 1, #extra do
        if extra[i] == key then return true end
    end

    return false
end

----------------- Sync / Transmit Data -----------------
function TFC_Utils.transmitSystemData(force, reason)
    if force or isClient() then
        TransmitTFCSystemData(reason)
        return true
    end

    local nowMs = getTimestampMs()
    if nowMs - lastGlobalTransmitMs < GLOBAL_TRANSMIT_COOLDOWN_MS then
        return false
    end

    lastGlobalTransmitMs = nowMs
    TransmitTFCSystemData(reason)
    return true
end

function TFC_Utils.syncData(x, y, z, tableName, key, value, bTransmit)
    local gData = GetTFCSystemData()
    if not gData or not gData[tableName] then return false end

    local id = TFC_Utils.getIdByCoords(x, y, z)
    local data = gData[tableName][id]
    if not data then return false end

    if data[key] == value then
        return false
    end

    data[key] = value
    if bTransmit ~= false then
        TFC_Utils.transmitSystemData(false, tableName .. "." .. tostring(key))
    end
    -- TFC_Utils.noise("Sync Data", id, tostring(key) .. " = " .. tostring(value))
    return true
end

----------------- For Tub Fluid Conatainer -----------------

TFC_Utils.ImportDefs = {
    Bathtub = {
        server = "TubFluidContainer/TABAS_STubFluidContainerBathtub",
        client = "TubFluidContainer/TABAS_CTubFluidContainerBathtub",
    }
}
TFC_Utils.ImportOrder = {"Bathtub"}
TFC_Utils.ImportCache = { server = {}, client = {} }

function TFC_Utils.registerImport(key, def)
    if not TFC_Utils.ImportDefs[key] then
        table.insert(TFC_Utils.ImportOrder, key)
    end
    TFC_Utils.ImportDefs[key] = def
    TFC_Utils.ImportCache.server[key] = nil
    TFC_Utils.ImportCache.client[key] = nil
end

local function getImportClass(side, key)
    local cache = TFC_Utils.ImportCache[side]
    if not cache then return nil end
    if cache[key] ~= nil then return cache[key] or nil end

    local def = TFC_Utils.ImportDefs[key]
    local path = def and def[side]
    if not path then return nil end

    local ok, class = pcall(require, path)
    if not ok then
        TFC_Utils.noise("require failed", tostring(key), tostring(side), tostring(path), tostring(class))
        class = false
    end

    cache[key] = class or false
    return cache[key] or nil
end

local function getTfcBaseBySide(side, x, y, z, _bathObject)
    local order = TFC_Utils.ImportOrder
    for i = 1, #order do
        local key = order[i]
        local class = getImportClass(side, key)
        if class then
            local tfc_Base = class:new(x, y, z, _bathObject)
            if tfc_Base then
                return tfc_Base
            end
        end
    end
    return nil
end


function TFC_Utils.getTfcBaseOnServer(x, y, z, _bathObject)
    if isClient() then return end
    return getTfcBaseBySide("server", x, y, z, _bathObject)
end

function TFC_Utils.getTfcBaseOnClient(x, y, z, _bathObject)
    if isServer() then return end
    return getTfcBaseBySide("client", x, y, z, _bathObject)
end

function TFC_Utils.isValidTfcObject(object)
    if not instanceof(object, "IsoObject") or not object:getName() then return false end
    return object:getName() == "TubFluidContainer"
end

function TFC_Utils.getTfcObject(x, y, z)
    local sq = getCell():getGridSquare(x, y, z)
    if not sq then return end
    for i=0,sq:getSpecialObjects():size()-1 do
        local obj = sq:getSpecialObjects():get(i)
        if TFC_Utils.isValidTfcObject(obj) then
            return obj
        end
    end
end

-- ratio (0..1) -> "empty"|"low"|"halfLow"|"half"|"full"
function TFC_Utils.getWaterLevelKeyByRatio(ratio)
    ratio = ratio or 0
    if ratio < TFC_Utils.Filled_Low then
        return "empty"
    elseif ratio >= TFC_Utils.Filled_Full then
        return "full"
    elseif ratio >= TFC_Utils.Filled_Half then
        return "half"
    elseif ratio >= TFC_Utils.Filled_HalfLow then
        return "halfLow"
    else
        return "low"
    end
end

return TFC_Utils
