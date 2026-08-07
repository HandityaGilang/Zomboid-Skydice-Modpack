-- TrueMoozic client-side volume control (PER-DEVICE).
-- Each device UI has a checkbox; while it's ticked, the volume slider adjusts
-- a LOCAL listening volume for THAT DEVICE ONLY, on this client only. The
-- shared device volume (what everyone else hears) is untouched, and other
-- devices keep following their own sliders normally.
require "TCMusicDefenitions"

-- devices: key -> 0..1 local override. Presence of a key = override active.
-- Key formats:
--   "I:<itemId>"     portable (inventory) devices
--   "XY:<x>-<y>-<z>" placed world devices (boombox, HiFi, jukebox, vinyl)
--   "V:<vehicleId>"  vehicle radios / vehicle HiFis
TCMusic.ClientVolume = TCMusic.ClientVolume or {}
TCMusic.ClientVolume.devices = TCMusic.ClientVolume.devices or {}
-- Legacy globals pinned inert: the old design was a GLOBAL multiplier that
-- hijacked every device's slider at once. Anything still reading these must
-- see "disabled".
TCMusic.ClientVolume.enabled = false
TCMusic.ClientVolume.value = 1.0

local SAVE_FILE = "TrueMoozicClientVolume.ini"

-- Resolve the per-device key from a device object + its UI deviceType.
function TCMusic.getClientVolumeKeyFor(device, deviceType)
    if not device then return nil end
    if deviceType == "VehiclePart" then
        local veh = device.getVehicle and device:getVehicle() or nil
        if veh then return "V:" .. tostring(veh:getId()) end
        return nil
    end
    if deviceType == "InventoryItem" and device.getID then
        return "I:" .. tostring(device:getID())
    end
    if device.getSquare and device.getX and device.getY and device.getZ then
        return "XY:" .. tostring(device:getX()) .. "-" .. tostring(device:getY()) .. "-" .. tostring(device:getZ())
    end
    if device.getID then
        return "I:" .. tostring(device:getID())
    end
    return nil
end

-- Key for a placed world source known only by coordinates (listen paths).
function TCMusic.worldVolKey(x, y, z)
    if x == nil then return nil end
    return "XY:" .. tostring(x) .. "-" .. tostring(y) .. "-" .. tostring(z)
end

-- MP-only: in singleplayer the regular device volume is enough.
function TCMusic.isClientVolumeActive(key)
    if not isClient() or not key then return false end
    return TCMusic.ClientVolume.devices[key] ~= nil
end

function TCMusic.getClientVolume(key)
    if not key then return nil end
    return TCMusic.ClientVolume.devices[key]
end

-- value=nil clears the override for that device.
function TCMusic.setClientVolume(key, value)
    if not key then return end
    if value ~= nil then
        value = tonumber(value) or 1.0
        if value < 0 then value = 0 end
        if value > 1 then value = 1 end
    end
    TCMusic.ClientVolume.devices[key] = value
    TCMusic.saveClientVolume()
end

-- Legacy shim: the global multiplier no longer exists.
function TCMusic.getClientVolumeKoef()
    return 1.0
end

-- The volume base a listen path should use for a given device key. A local
-- override REPLACES the shared/server volume for that device only, so the
-- client has the full 0..1 range regardless of what the device is set to.
function TCMusic.getListenVolume(serverVol, key)
    if isClient() and key then
        local v = TCMusic.ClientVolume.devices[key]
        if v ~= nil then return v end
    end
    return serverVol or 0
end

function TCMusic.saveClientVolume()
    local writer = getFileWriter(SAVE_FILE, true, false)
    if not writer then return end
    for k, v in pairs(TCMusic.ClientVolume.devices) do
        writer:write("dev:" .. tostring(k) .. "=" .. tostring(v) .. "\n")
    end
    writer:close()
end

function TCMusic.loadClientVolume()
    local reader = getFileReader(SAVE_FILE, false)
    if not reader then return end
    local line = reader:readLine()
    while line do
        local k, v = string.match(line, "^dev:(.+)=([%d%.]+)$")
        if k and v then
            local num = tonumber(v)
            if num then
                if num < 0 then num = 0 end
                if num > 1 then num = 1 end
                TCMusic.ClientVolume.devices[k] = num
            end
        end
        line = reader:readLine()
    end
    reader:close()
end

-- Immediately re-applies the local volume to the local player's own playing
-- portable device (the only sound handle the UI can reach synchronously).
function TCMusic.applyClientVolumeToOwnDevice(player, deviceData, key)
    if not player then return end
    -- Echo-proof base volume: prefer the live session's volume (walkman /
    -- boombox); DeviceData can be stale after a server item echo.
    local base = deviceData and deviceData:getDeviceVolume() or 1.0
    local ws = TCMusic.WalkmanSession
    if ws and key == ("I:" .. tostring(ws.itemId)) and ws.volume ~= nil then
        base = ws.volume
    end
    local bs = TCMusic.BoomboxSession
    if bs and key == ("I:" .. tostring(bs.itemId)) then
        if bs.volume ~= nil then base = bs.volume end
        if bs.soundId then
            player:getEmitter():setVolume(bs.soundId, TCMusic.getListenVolume(base, key) * 0.4)
            return
        end
    end
    local tmid = player:getModData().tcmusicid
    if tmid then
        player:getEmitter():setVolume(tmid, TCMusic.getListenVolume(base, key) * 0.4)
    end
end

Events.OnGameStart.Add(TCMusic.loadClientVolume)
