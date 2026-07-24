--[[
    HiFiVehicleSpawnRarity.lua  (server-side)

    After the vanilla Vehicles.Create.Radio picks a random radio for a
    vehicle, this hook checks whether it chose a HiFi Stereo.  If so,
    it re-rolls with a configurable chance (default 30%).  On failure
    the HiFi is swapped for a vanilla radio.

    This runs on the server so the result is authoritative in MP.
]]

local HIFI_SPAWN_CHANCE = 30   -- percentage chance a vehicle spawns with HiFi

local _originalCreateRadio = Vehicles.Create.Radio

function Vehicles.Create.Radio(vehicle, part)
    -- Let the vanilla function do its thing (picks item, creates DeviceData)
    _originalCreateRadio(vehicle, part)

    -- Check what was installed
    local invItem = part:getInventoryItem()
    if not invItem then return end

    local fullType = invItem:getFullType()
    if fullType == "Tsarcraft.TM_HiFiStereo" then
        -- Roll for rarity
        if ZombRand(100) >= HIFI_SPAWN_CHANCE then
            -- Failed the roll — swap to a vanilla radio
            local replacement = "Base.RadioBlack"
            if vehicle:getScript() and vehicle:getScript():getName() then
                local name = vehicle:getScript():getName()
                if name:contains("Modern") or name:contains("Luxury") then
                    replacement = "Base.RadioRed"
                end
            end

            local newItem = instanceItem(replacement)
            if newItem then
                local conditionMultiply = 100 / newItem:getConditionMax()
                newItem:setConditionMax(newItem:getConditionMax() * conditionMultiply)
                newItem:setConditionNoSound(newItem:getCondition() * conditionMultiply)
                part:setRandomCondition(newItem)
                part:setInventoryItem(newItem)

                -- Rebuild DeviceData from the replacement item
                local dd = part:getDeviceData()
                local srcDD = newItem:getDeviceData()
                if dd and srcDD then
                    dd:setDeviceName(srcDD:getDeviceName())
                    dd:setIsTwoWay(srcDD:getIsTwoWay())
                    dd:setTransmitRange(srcDD:getTransmitRange())
                    dd:setMicRange(srcDD:getMicRange())
                    dd:setBaseVolumeRange(srcDD:getBaseVolumeRange())
                    dd:setIsPortable(false)
                    dd:setIsTelevision(srcDD:getIsTelevision())
                    dd:setMinChannelRange(srcDD:getMinChannelRange())
                    dd:setMaxChannelRange(srcDD:getMaxChannelRange())
                    dd:setIsBatteryPowered(false)
                    dd:setIsHighTier(srcDD:getIsHighTier())
                    dd:setUseDelta(srcDD:getUseDelta())
                    dd:setMediaType(srcDD:getMediaType())
                end
            end
        end
    end
end
