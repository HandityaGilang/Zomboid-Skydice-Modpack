require "RadioCom/HiFiWindow"
require "RadioCom/HiFiVehicleWindow"
require "HiFiDefinitions"

-- Register the HiFi Stereo as a custom device that opens the HiFi window
-- instead of the default ISRadioWindow

if not HiFiDevices then HiFiDevices = {} end
HiFiDevices["Tsarcraft.TM_HiFiStereo"] = true

-- Load tick handlers AFTER HiFiDevices is set (they reference HiFiDevices)
require "HiFiVehicleTick"
require "HiFiWorldTick"

-- Hook ISRadioWindow.activate to redirect HiFi devices to HiFiWindow.
-- Installed twice: once now (covers any callers that bind early) and again on
-- OnGameStart so we wrap whatever other mods (ISTCRadioWindow, SWTC, etc.)
-- ended up installing as the final activate. Idempotency is guaranteed by
-- the ISRadioWindow._tcHiFiHook guard so we never wrap our own wrapper.

local function installHiFiHook()
    if not ISRadioWindow or not ISRadioWindow.activate then return end
    if ISRadioWindow._tcHiFiHook then return end
    ISRadioWindow._tcHiFiHook = true

    local _originalISRadioWindowActivate = ISRadioWindow.activate

    local function detectHiFiFullType(_item)
        if instanceof(_item, "Radio") then
            return _item:getFullType()
        end
        if not instanceof(_item, "IsoWaveSignal") then return nil end
        local md = _item.getModData and _item:getModData() or nil
        if md and md.hifiDeviceType and HiFiDevices[md.hifiDeviceType] then
            return md.hifiDeviceType
        end
        if instanceof(_item, "IsoWorldInventoryObject") and _item.getItem then
            local it = _item:getItem()
            if it and it.getFullType and HiFiDevices[it:getFullType()] then
                if md then md.hifiDeviceType = it:getFullType() end
                return it:getFullType()
            end
        end
        local sq = _item.getSquare and _item:getSquare() or nil
        if sq then
            local wobjs = sq:getWorldObjects()
            if wobjs then
                for i = 0, wobjs:size() - 1 do
                    local w = wobjs:get(i)
                    if instanceof(w, "IsoWorldInventoryObject") then
                        local it = w:getItem()
                        if it and it.getFullType and HiFiDevices[it:getFullType()] then
                            if md then md.hifiDeviceType = it:getFullType() end
                            return it:getFullType()
                        end
                    end
                end
            end
        end
        return nil
    end

    function ISRadioWindow.activate(_player, _item, bol)
        if _player == getPlayer() then
            -- Vehicle radio: check if the installed item is a HiFi
            if instanceof(_item, "VehiclePart") then
                local invItem = _item:getInventoryItem()
                if invItem and HiFiDevices[invItem:getFullType()] then
                    HiFiVehicleWindow.activate(_player, _item)
                    return
                end
            end

            local ft = detectHiFiFullType(_item)
            if ft and HiFiDevices[ft] then
                HiFiWindow.activate(_player, _item)
                return
            end
        end
        _originalISRadioWindowActivate(_player, _item, bol)
    end
end

installHiFiHook()

-- Re-wrap after all other mods have installed their own activate hooks.
-- Reset the guard so installHiFiHook re-runs once on OnGameStart.
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function()
        ISRadioWindow._tcHiFiHook = nil
        installHiFiHook()
    end)
end

