if ISMusicVehicleMenu == nil then ISMusicVehicleMenu = {} end

if not ISMusicVehicleMenu.oldShowRadialMenu then
    ISMusicVehicleMenu.oldShowRadialMenu = ISVehicleMenu.showRadialMenu
end

function ISVehicleMenu.showRadialMenu(playerObj)
    ISMusicVehicleMenu.oldShowRadialMenu(playerObj)
    ISMusicVehicleMenu.showRadialMenu(playerObj)
end

function ISMusicVehicleMenu.showRadialMenu(playerObj)
    local isPaused = UIManager.getSpeedControls() and UIManager.getSpeedControls():getCurrentGameSpeed() == 0
    if isPaused then return end
    local vehicle = playerObj:getVehicle()
    if vehicle then
        local menu = getPlayerRadialMenu(playerObj:getPlayerNum())
        local seat = vehicle:getSeat(playerObj)
        if seat <= 1 then
            -- NOTE: the vanilla "Device options" slice is left untouched -
            -- the base game radio UI and other mods still need it. Our own
            -- vehicle radio/HiFi UIs open via the cassette slice below.
            for partIndex=1,vehicle:getPartCount() do
                local part = vehicle:getPartByIndex(partIndex-1)
                if part:getDeviceData() and part:getInventoryItem() then
                    local ft = part:getInventoryItem():getFullType()
                    if TCMusic.VehicleMusicPlayer[ft] or (HiFiDevices and HiFiDevices[ft]) then
                        menu:addSlice(getText("IGUI_MusicOptionsCar"), getTexture("media/ui/vehicle_tape.png"), ISMusicVehicleMenu.onSignalDevice, playerObj, part)
                    end
                end
            end
        end
        
    end
end

-- Cassette "Music options" slice callback: the ONLY way the mod's vehicle
-- radio/HiFi window opens. ISVehicleMenu.onSignalDevice is NOT touched:
-- the vanilla "Device options" slice (and the dashboard radio icon) always
-- opens the BASE-GAME radio UI - for our devices too - so other mods and
-- the vanilla flow keep working untouched.
function ISMusicVehicleMenu.onSignalDevice(playerObj, part)
    if not part:getModData().tcmusic then
        part:getModData().tcmusic = {}
        part:getModData().tcmusic.mediaItem = nil
        part:getModData().tcmusic.needSpeaker = nil
    end
    local invItem = part:getInventoryItem()
    if invItem and HiFiDevices and HiFiDevices[invItem:getFullType()] and HiFiVehicleWindow then
        HiFiVehicleWindow.activate(playerObj, part)
        return
    end
    ISTCBoomboxWindow.activate(playerObj, part)
end

-- If an older build of this file already overrode ISVehicleMenu.onSignalDevice
-- in this session, restore the vanilla one.
if ISMusicVehicleMenu.oldOnSignalDevice then
    ISVehicleMenu.onSignalDevice = ISMusicVehicleMenu.oldOnSignalDevice
    ISMusicVehicleMenu.oldOnSignalDevice = nil
end