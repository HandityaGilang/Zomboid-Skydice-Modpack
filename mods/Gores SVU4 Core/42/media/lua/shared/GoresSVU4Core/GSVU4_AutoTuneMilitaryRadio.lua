--========================================================
-- Gore's SVU4 Core - Auto Tune Military Radio
-- Shared helpers. The installed SVU4 upgrade replaces the
-- vehicle's existing Radio part item with the Auto Tune unit,
-- then programs/tunes that actual vehicle radio device.
--========================================================

GSVU4 = GSVU4 or {}
GSVU4.AutoTuneMilitaryRadio = GSVU4.AutoTuneMilitaryRadio or {}

local Radio = GSVU4.AutoTuneMilitaryRadio
Radio.AEBS_UUID = "EMRG-711984"
Radio.UNLIMITED_RANGE = 1000000
Radio.PRESET_NAME = "Emergency Broadcast"
Radio.ITEM_TYPE = "Base.GSVU4AutoTuneMilitaryRadio"


local function nowMs()
    if getTimestampMs then
        local ok, value = pcall(function() return getTimestampMs() end)
        if ok and tonumber(value) then return tonumber(value) end
    end
    return 0
end


local function safeGetField(obj, name)
    if not obj or not name then return nil end
    local ok, value = pcall(function() return obj[name] end)
    if ok then return value end
    return nil
end

local function callMethod(obj, name, ...)
    local fn = safeGetField(obj, name)
    if not fn then return false, nil end
    local n = select("#", ...)
    local a, b = ...
    local ok, result
    if n <= 0 then
        ok, result = pcall(function() return fn(obj) end)
    elseif n == 1 then
        ok, result = pcall(function() return fn(obj, a) end)
    else
        ok, result = pcall(function() return fn(obj, a, b) end)
    end
    return ok, result
end

local function safeToString(obj)
    if obj == nil then return "" end
    local ok, value = pcall(function() return tostring(obj) end)
    if ok and value ~= nil then return tostring(value) end
    return ""
end

local function stringStartsWith(value, prefix)
    return string.sub(value or "", 1, string.len(prefix)) == prefix
end

local function looksLikeJavaChannelCollection(obj)
    local s = safeToString(obj)
    if s == "" then return false end
    -- B42.19 prints the Java ArrayList as: [zombie.radio.scripting.RadioChannel@...]
    if stringStartsWith(s, "[") and string.find(s, "RadioChannel@", 1, true) then return true end
    if string.find(s, "java.util", 1, true) and string.find(s, "RadioChannel", 1, true) then return true end
    return false
end

local function looksLikeJavaRadioChannel(obj)
    local s = safeToString(obj)
    if s == "" or stringStartsWith(s, "[") then return false end
    return string.find(s, "RadioChannel@", 1, true) ~= nil
end

local function looksLikeEmptyOrPlainJavaCollection(obj)
    local s = safeToString(obj)
    if s == "" then return false end
    -- B42.19 MP can hand back an empty Java collection rendered as [] while
    -- AEBS is not yet exposed client-side. Do not probe values() on it: Kahlua
    -- logs attempted-index errors even when wrapped in pcall.
    if s == "[]" then return true end
    if stringStartsWith(s, "[") and not string.find(s, "RadioChannel@", 1, true) then return true end
    if string.find(s, "java.util", 1, true) and not string.find(s, "RadioChannel", 1, true) then return true end
    return false
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

local function getPartItem(part)
    if not part or not part.getInventoryItem then return nil end
    local ok, item = pcall(function() return part:getInventoryItem() end)
    if ok then return item end
    return nil
end

local function addItemToPlayer(playerObj, fullType)
    if not playerObj or not fullType or not playerObj.getInventory then return false end
    local inv = playerObj:getInventory()
    if not inv or not inv.AddItem then return false end
    local ok = pcall(function() inv:AddItem(fullType) end)
    return ok == true
end

local function getItemModData(item)
    if not item or not item.getModData then return nil end
    local ok, md = pcall(function() return item:getModData() end)
    if ok then return md end
    return nil
end

local function setItemDisplayName(item, name)
    if not item or not name then return false end
    for _, method in ipairs({"setName", "setCustomName", "setDisplayName"}) do
        if item[method] then
            local ok = pcall(function() item[method](item, name) end)
            if ok then return true end
        end
    end
    return false
end

local function copyItemCondition(fromItem, toItem)
    if not fromItem or not toItem then return end
    if fromItem.getCondition and toItem.setCondition then
        local ok, cond = pcall(function() return fromItem:getCondition() end)
        if ok and cond ~= nil then pcall(function() toItem:setCondition(cond) end) end
    end
end

local function markItemAsAutoTuneRadio(item, originalFullType, originalName)
    if not item then return false end
    local md = getItemModData(item)
    if md then
        md.gSVU4AutoTuneMilitaryRadio = true
        if originalFullType then md.gSVU4OriginalRadioType = tostring(originalFullType) end
        if originalName then md.gSVU4OriginalRadioName = tostring(originalName) end
    end
    setItemDisplayName(item, "Auto Tune Military Radio")
    return true
end

local function itemName(item)
    if not item then return nil end
    for _, method in ipairs({"getName", "getDisplayName"}) do
        if item[method] then
            local ok, value = pcall(function() return item[method](item) end)
            if ok and value then return tostring(value) end
        end
    end
    return nil
end

function Radio._tryRequireRadioAPI()
    if RadioAPI then return end
    for _, path in ipairs({"Radio/RadioAPI", "radio/RadioAPI", "RadioAPI"}) do
        local ok, api = pcall(require, path)
        if ok and api then
            RadioAPI = api
            return
        end
        if RadioAPI then return end
    end
end

local function valueLooksLikeAEBS(value)
    if value == nil then return false end
    local s = string.lower(tostring(value))
    return string.find(s, string.lower(Radio.AEBS_UUID), 1, true) ~= nil
        or string.find(s, "automated emergency broadcast", 1, true) ~= nil
        or string.find(s, "emergency broadcast", 1, true) ~= nil
end

local function parseFrequency(value)
    if value == nil then return nil end
    local n = tonumber(value)
    if n then
        if n > 0 and n < 200 then return math.floor(n * 1000 + 0.5) end
        return math.floor(n + 0.5)
    end
    local s = tostring(value)
    local mhz = string.match(s, "(%d+%.?%d*)%s*[mM][hH][zZ]")
    if mhz then return math.floor((tonumber(mhz) or 0) * 1000 + 0.5) end
    local digits = string.match(s, "(%d%d%d%d%d%d?)")
    if digits then return tonumber(digits) end
    return nil
end


-- B42.19 reliability fallback:
-- ZomboidRadio.Init prints the generated AEBS channel before the player can
-- install/use this upgrade, e.g.:
-- name = Automated Emergency Broadcast System, freq = 93400, cat = Emergency, uuid = EMRG-711984
-- Found radio channel: Automated Emergency Broadcast System, freq = EMRG-711984, freqcheck = 93400
-- The Java API shape has varied between loads/mod stacks, so safely capture
-- the exact generated frequency from that init print as a deterministic fallback.
local function installAEBSPrintCapture()
    if _G.GSVU4_AEBS_PRINT_CAPTURE_ACTIVE then return end
    if type(print) ~= "function" then return end

    local originalPrint = print
    _G.GSVU4_AEBS_PRINT_CAPTURE_ACTIVE = true
    _G.GSVU4_AEBS_ORIGINAL_PRINT = originalPrint

    print = function(...)
        local argCount = select("#", ...)
        local msg = ""
        if argCount > 0 then
            local parts = {}
            for i = 1, argCount do
                local value = select(i, ...)
                local ok, text = pcall(tostring, value)
                parts[#parts + 1] = ok and text or ""
            end
            msg = table.concat(parts, "\t")
        end

        if msg ~= "" and (string.find(msg, "Automated Emergency Broadcast System", 1, true) or string.find(msg, Radio.AEBS_UUID, 1, true)) then
            local rawFreq = string.match(msg, "freqcheck%s*=%s*(%d+)")
            if not rawFreq then rawFreq = string.match(msg, "freq%s*=%s*(%d+)") end
            local parsed = parseFrequency(rawFreq)
            if parsed and parsed > 0 then
                if Radio.CachedAEBSFrequency ~= parsed then
                    Radio.CachedAEBSFrequency = parsed
                    Radio.LastAEBSLookupFailedMs = nil
                end
            end
        end

        return originalPrint(...)
    end
end

installAEBSPrintCapture()

local function tryGetFrequencyFromChannel(channel)
    if not channel then return nil end

    local identityMatch = false
    local identityChecked = false

    -- B42.19 RadioChannel method names are case-sensitive from Lua.
    -- The game log shows the AEBS channel exposes values like:
    -- name = Automated Emergency Broadcast System, cat = Emergency,
    -- uuid = EMRG-711984, freqcheck = <actual frequency>.
    -- Keep both lower and capitalized Java-style variants here.
    for _, method in ipairs({
        "getUUID", "GetUUID", "getUuid", "GetUuid",
        "getGUID", "GetGUID", "getGuid", "GetGuid",
        "getId", "GetId", "getID", "GetID",
        "getName", "GetName", "getChannelName", "GetChannelName",
        "getTitle", "GetTitle", "getCategory", "GetCategory"
    }) do
        local ok, value = callMethod(channel, method)
        if ok and value ~= nil then
            identityChecked = true
            if valueLooksLikeAEBS(value) then identityMatch = true end
        end
    end

    -- If the object exposes identifying data and none of it looks like AEBS,
    -- do not risk using a random normal radio channel frequency.
    if identityChecked and not identityMatch then return nil end

    for _, method in ipairs({
        "getFrequency", "GetFrequency", "getFreq", "GetFreq",
        "getFrequencyInt", "GetFrequencyInt",
        "getFreqCheck", "GetFreqCheck", "getFrequencyCheck", "GetFrequencyCheck",
        "getRadioFrequency", "GetRadioFrequency"
    }) do
        local ok, freq = callMethod(channel, method)
        local parsed = ok and parseFrequency(freq) or nil
        if parsed then return parsed end
    end

    return nil
end

local function tryGetChannelByUUID(source)
    if not source then return nil end
    for _, method in ipairs({"getChannelByUUID", "GetChannelByUUID", "getChannelByUuid", "getRadioChannelByUUID"}) do
        local ok, channel = callMethod(source, method, Radio.AEBS_UUID)
        if ok and channel then
            local freq = tryGetFrequencyFromChannel(channel)
            if freq then return freq end
        end
    end
    return nil
end

local function tryScanChannelCollection(collection, depth)
    if not collection then return nil end
    depth = depth or 0
    if depth > 3 then return nil end

    if type(collection) == "table" then
        for _, channel in pairs(collection) do
            local freq = tryScanChannelCollection(channel, depth + 1)
            if freq then return freq end
        end
        return nil
    end

    -- B42.19 can hand us a Java ArrayList of RadioChannel objects. Do NOT
    -- probe channel methods on that list first, because Kahlua logs an error
    -- even inside pcall when indexing a missing Java method such as getUUID.
    if looksLikeJavaChannelCollection(collection) then
        local okIt, it = callMethod(collection, "iterator")
        if okIt and it then
            local guard = 0
            while guard < 500 do
                guard = guard + 1
                local okHas, has = callMethod(it, "hasNext")
                if not okHas or not has then break end
                local okNext, channel = callMethod(it, "next")
                if okNext and channel then
                    local freq = tryScanChannelCollection(channel, depth + 1)
                    if freq then return freq end
                end
            end
        end

        local okSize, size = callMethod(collection, "size")
        if okSize and tonumber(size) then
            for i = 0, tonumber(size) - 1 do
                local okGet, channel = callMethod(collection, "get", i)
                if okGet and channel then
                    local freq = tryScanChannelCollection(channel, depth + 1)
                    if freq then return freq end
                end
            end
        end
        return nil
    end

    if looksLikeJavaRadioChannel(collection) then
        return tryGetFrequencyFromChannel(collection)
    end

    if looksLikeEmptyOrPlainJavaCollection(collection) then
        return nil
    end

    -- Unknown Java object: only try Map-style values(), not channel identity
    -- probes. This avoids console spam from indexing arbitrary Java objects.
    local okValues, values = callMethod(collection, "values")
    if okValues and values then
        local freq = tryScanChannelCollection(values, depth + 1)
        if freq then return freq end
    end

    return nil
end

local function looksLikeRadioScriptManager(source)
    if not source then return false end
    local ok, value = pcall(function() return tostring(source) end)
    if ok and value and string.find(tostring(value), "RadioScriptManager", 1, true) then return true end
    return false
end

local function tryScanChannels(source)
    -- B42.19 signature-safe fallback:
    -- On RadioScriptManager, getChannels() is the no-argument method.
    -- Avoid getChannelsByCategory/getChannelList variants here because the
    -- wrong Java signature still prints errors even when wrapped in pcall.
    if not looksLikeRadioScriptManager(source) then return nil end
    local ok, collection = callMethod(source, "getChannels")
    if ok and collection then
        local freq = tryScanChannelCollection(collection, 0)
        if freq then return freq end
    end
    return nil
end

local function trySource(source)
    local freq = tryGetChannelByUUID(source)
    if tonumber(freq) then return tonumber(freq) end
    return tryScanChannels(source)
end

function Radio.getAEBSFrequency()
    if Radio.CachedAEBSFrequency then return Radio.CachedAEBSFrequency end

    local now = nowMs()
    if Radio.LastAEBSLookupFailedMs and now ~= 0 and now - Radio.LastAEBSLookupFailedMs < 5000 then
        return nil
    end

    Radio._tryRequireRadioAPI()

    local sources = {}

    if RadioAPI and RadioAPI.getInstance then
        local okApi, radioAPI = pcall(function() return RadioAPI.getInstance() end)
        if okApi and radioAPI then sources[#sources + 1] = radioAPI end
    end

    if getRadioAPI then
        local ok, radioAPI = pcall(function() return getRadioAPI() end)
        if ok and radioAPI then sources[#sources + 1] = radioAPI end
    end

    if ZomboidRadio and ZomboidRadio.getInstance then
        local ok, zr = pcall(function() return ZomboidRadio.getInstance() end)
        if ok and zr then sources[#sources + 1] = zr end
    end

    if getZomboidRadio then
        local ok, zr = pcall(function() return getZomboidRadio() end)
        if ok and zr then sources[#sources + 1] = zr end
    end

    if RadioScriptManager and RadioScriptManager.getInstance then
        local ok, mgr = pcall(function() return RadioScriptManager.getInstance() end)
        if ok and mgr then sources[#sources + 1] = mgr end
    end

    if getRadioScriptManager then
        local ok, mgr = pcall(function() return getRadioScriptManager() end)
        if ok and mgr then sources[#sources + 1] = mgr end
    end

    -- Avoid unsafe broad/category scans. trySource only performs UUID lookup.

    for _, source in ipairs(sources) do
        local okFreq, freq = pcall(function() return trySource(source) end)
        if okFreq and tonumber(freq) then
            Radio.CachedAEBSFrequency = tonumber(freq)

            return Radio.CachedAEBSFrequency
        end
    end

    Radio.LastAEBSLookupFailedMs = nowMs()
    return nil
end

function Radio.hasUpgrade(vehicle)
    if not vehicle or not vehicle.getModData then return false end
    local vdata = vehicle:getModData()
    local up = vdata and vdata.gUpgrades and vdata.gUpgrades.AutoTuneMilitaryRadio or nil
    return up ~= nil and up.grade ~= nil
end

function Radio.getRadioPart(vehicle)
    if not vehicle or not vehicle.getPartById then return nil end
    local ok, part = pcall(function() return vehicle:getPartById("Radio") end)
    if ok then return part end
    return nil
end

function Radio.isAutoTuneRadioPartInstalled(vehicle)
    local part = Radio.getRadioPart(vehicle)
    local item = getPartItem(part)
    local md = getItemModData(item)
    if md and md.gSVU4AutoTuneMilitaryRadio == true then return true end
    return false
end

function Radio.replaceVehicleRadioItem(vehicle, playerObj, silent)
    if not vehicle then return false, "vehicle missing" end
    local radioPart = Radio.getRadioPart(vehicle)
    if not radioPart then return false, "vehicle Radio part missing" end

    local currentItem = getPartItem(radioPart)
    if not currentItem then return false, "vehicle has no radio item to upgrade" end

    local currentMd = getItemModData(currentItem)
    if currentMd and currentMd.gSVU4AutoTuneMilitaryRadio == true then
        markItemAsAutoTuneRadio(currentItem, currentMd.gSVU4OriginalRadioType, currentMd.gSVU4OriginalRadioName)
        return true, "already installed"
    end

    local currentFullType = itemFullType(currentItem)
    local currentName = itemName(currentItem)
    if not currentFullType then return false, "current radio type unavailable" end

    local vdata = vehicle.getModData and vehicle:getModData() or nil
    if vdata then
        vdata.gAutoTuneMilitaryRadioOriginalRadioType = currentFullType
        vdata.gAutoTuneMilitaryRadioOriginalRadioName = currentName
    end

    -- Important B42 safety note:
    -- The vehicle Radio part expects a fully vanilla-compatible radio item.
    -- A custom Type=Radio item can throw Vanilla Vehicles.lua:Radio errors.
    -- So we create a fresh instance of the same vanilla radio type, mark/rename
    -- that instance as the Auto Tune unit, and place it in the vehicle slot.
    if playerObj then
        addItemToPlayer(playerObj, currentFullType)
    end

    local newItem = currentItem
    if instanceItem and playerObj then
        local okItem, candidate = pcall(function() return instanceItem(currentFullType) end)
        if okItem and candidate then
            newItem = candidate
            copyItemCondition(currentItem, newItem)
        end
    end

    markItemAsAutoTuneRadio(newItem, currentFullType, currentName)

    if newItem ~= currentItem then
        local okSet, err = pcall(function() radioPart:setInventoryItem(newItem) end)
        if not okSet then return false, "could not replace vehicle radio: " .. tostring(err) end
    else
        -- If no installer is available, safely upgrade the radio currently in the slot.
        pcall(function() radioPart:setInventoryItem(newItem) end)
    end

    if vehicle.transmitPartItem then pcall(function() vehicle:transmitPartItem(radioPart) end) end
    if vehicle.transmitPartModData then pcall(function() vehicle:transmitPartModData(radioPart) end) end
    if vehicle.transmitModData then pcall(function() vehicle:transmitModData() end) end

    return true, "replaced"
end

function Radio.getDeviceData(vehicle)
    local radioPart = Radio.getRadioPart(vehicle)
    if not radioPart then return nil, radioPart end

    if radioPart.getDeviceData then
        local ok, data = pcall(function() return radioPart:getDeviceData() end)
        if ok and data then return data, radioPart end
    end

    local item = getPartItem(radioPart)
    if item and item.getDeviceData then
        local ok, data = pcall(function() return item:getDeviceData() end)
        if ok and data then return data, radioPart end
    end

    return nil, radioPart
end

function Radio.applyUnlimitedRange(deviceData)
    if not deviceData then return false end
    local changed = false
    for _, method in ipairs({"setIsTwoWay", "setTwoWay", "setCanTransmit"}) do
        local ok = callMethod(deviceData, method, true)
        changed = ok or changed
    end
    for _, method in ipairs({"setTransmitRange", "setMicRange", "setMaxRange", "setRange"}) do
        local ok = callMethod(deviceData, method, Radio.UNLIMITED_RANGE)
        changed = ok or changed
    end
    return changed
end

local function syncDeviceData(deviceData, vehicle, radioPart)
    if deviceData then
        -- B42.19 exposes some Java methods such as save/update that require
        -- extra arguments. Calling them with only self is caught by pcall, but
        -- still prints noisy "expected 2 arguments" console errors. Only call
        -- the no-argument transmit methods that are safe for this device data.
        for _, method in ipairs({"transmitDeviceDataState", "transmitDeviceData", "transmitPresets"}) do
            if deviceData[method] then pcall(function() deviceData[method](deviceData) end) end
        end
    end
    if vehicle and radioPart and vehicle.transmitPartModData then pcall(function() vehicle:transmitPartModData(radioPart) end) end
    if vehicle and radioPart and vehicle.transmitPartItem then pcall(function() vehicle:transmitPartItem(radioPart) end) end
    if vehicle and vehicle.transmitModData then pcall(function() vehicle:transmitModData() end) end
end

local function setDeviceDisplayName(deviceData)
    if not deviceData then return false end
    local changed = false
    for _, method in ipairs({"setDeviceName", "setName", "setCustomName", "setDisplayName"}) do
        if deviceData[method] then
            local ok = pcall(function() deviceData[method](deviceData, "Auto Tune Military Radio") end)
            changed = ok or changed
        end
    end
    return changed
end

local function addOrUpdatePreset(deviceData, name, freq)
    if not deviceData or not freq then return false, "device/frequency missing" end
    local freqNum = tonumber(freq)
    if not freqNum then return false, "frequency invalid" end

    -- B42-safe preset write. Avoid broad signature guessing because failed
    -- Java method calls can still surface in the console even under pcall.
    if deviceData.addPreset then
        local ok, err = pcall(function() deviceData:addPreset(name, freqNum) end)
        if ok then return true, "preset programmed" end
        return false, tostring(err)
    end

    return false, "device has no addPreset method"
end

local function tuneFrequency(deviceData, freq)
    if not deviceData or not freq then return false, "device/frequency missing" end
    local freqNum = tonumber(freq)
    if not freqNum then return false, "frequency invalid" end

    if deviceData.setChannel then
        local ok, err = pcall(function() deviceData:setChannel(freqNum) end)
        if ok then return true, "channel tuned" end
        return false, tostring(err)
    end

    return false, "device has no setChannel method"
end

function Radio.programEmergencyPreset(vehicle)
    if not vehicle or not Radio.hasUpgrade(vehicle) then return false, "upgrade not installed" end
    Radio.replaceVehicleRadioItem(vehicle, nil, true)

    local deviceData, radioPart = Radio.getDeviceData(vehicle)
    if not deviceData then

        return false, "vehicle radio device missing"
    end

    local freq = Radio.getAEBSFrequency()
    if not freq then

        return false, "AEBS frequency unavailable"
    end

    local presetOk, presetMsg = addOrUpdatePreset(deviceData, Radio.PRESET_NAME, freq)
    -- Some B42.19 vehicle-radio device data objects expose setChannel but not
    -- addPreset. Tune the active channel here as a fallback so the upgrade works
    -- immediately and does not rely on the later engine-running client pass.
    local tuneOk, tuneMsg = tuneFrequency(deviceData, freq)
    setDeviceDisplayName(deviceData)
    Radio.applyUnlimitedRange(deviceData)

    local vdata = vehicle:getModData()
    if vdata then
        vdata.gAutoTuneMilitaryRadioPresetProgrammed = presetOk == true
        vdata.gAutoTuneMilitaryRadioFrequency = freq
        vdata.gAutoTuneMilitaryRadioRange = Radio.UNLIMITED_RANGE
        vdata.gAutoTuneMilitaryRadioLastTune = getTimestampMs and getTimestampMs() or 0
        vdata.gAutoTuneMilitaryRadioLastTuneOk = tuneOk == true
    end

    syncDeviceData(deviceData, vehicle, radioPart)

    if tuneOk then return true, freq end
    return presetOk == true, presetOk and freq or tostring(presetMsg)
end

function Radio.autoTuneVehicleRadio(vehicle)
    if not vehicle or not Radio.hasUpgrade(vehicle) then return false, "upgrade not installed" end
    Radio.replaceVehicleRadioItem(vehicle, nil, true)

    local deviceData, radioPart = Radio.getDeviceData(vehicle)
    if not deviceData then

        return false, "vehicle radio device missing"
    end

    local freq = Radio.getAEBSFrequency()
    if not freq then

        return false, "AEBS frequency unavailable"
    end

    local presetOk, presetMsg = addOrUpdatePreset(deviceData, Radio.PRESET_NAME, freq)
    local tuneOk, tuneMsg = tuneFrequency(deviceData, freq)
    setDeviceDisplayName(deviceData)
    Radio.applyUnlimitedRange(deviceData)

    local vdata = vehicle:getModData()
    if vdata then
        vdata.gAutoTuneMilitaryRadioPresetProgrammed = presetOk == true
        vdata.gAutoTuneMilitaryRadioFrequency = freq
        vdata.gAutoTuneMilitaryRadioRange = Radio.UNLIMITED_RANGE
        vdata.gAutoTuneMilitaryRadioLastTune = getTimestampMs and getTimestampMs() or 0
        vdata.gAutoTuneMilitaryRadioLastTuneOk = tuneOk == true
    end

    syncDeviceData(deviceData, vehicle, radioPart)

    if tuneOk then return true, freq end
    if presetOk then return true, "preset only " .. tostring(freq) end
    return false, tostring(presetMsg) .. " / " .. tostring(tuneMsg)
end
