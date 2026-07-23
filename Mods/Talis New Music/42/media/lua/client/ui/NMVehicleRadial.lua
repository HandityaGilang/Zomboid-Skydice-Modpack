-- Vehicle radial injection for New Music vehicle controls.
-- Canonical UI path is NMDeviceUI -> NMDeviceWindow.
NMVehicleRadial = NMVehicleRadial or {}
NMVehicleRadial.hookInstalled = NMVehicleRadial.hookInstalled or false
NMVehicleRadial.nextHookAttemptMs = NMVehicleRadial.nextHookAttemptMs or 0

local function nowMs()
    if getTimestampMs then
        local ms = tonumber(getTimestampMs())
        if ms then return ms end
    end
    if getTimestamp then
        local ts = tonumber(getTimestamp())
        if ts then return ts * 1000 end
    end
    return 0
end

local function onVehicleRadialSignal(playerObj, part)
    if not playerObj or not part then return end
    local vehicle = part.getVehicle and part:getVehicle() or playerObj:getVehicle()
    if not vehicle then return end
    local profile = NMDeviceProfiles.getVehicleProfile(part)
    if not profile then return end
    NMDeviceUI.openForVehicle(playerObj:getPlayerNum(), vehicle, part)
end

local function injectVehicleRadialMenu(playerObj)
    if not playerObj then return end
    local vehicle = playerObj:getVehicle()
    if not vehicle then return end

    local seat = vehicle:getSeat(playerObj)
    if seat < 0 or seat > 1 then return end

    local menu = getPlayerRadialMenu and getPlayerRadialMenu(playerObj:getPlayerNum()) or nil
    if not menu then return end

    local icon = getTexture and getTexture("media/textures/UI/UI_NM_VehicleRadial.png") or nil
    for partIndex = 1, vehicle:getPartCount() do
        local part = vehicle:getPartByIndex(partIndex - 1)
        local profile = NMDeviceProfiles.getVehicleProfile(part)
        if profile then
            menu:addSlice(NMTranslations.ui("NewMusic", "New Music"), icon, onVehicleRadialSignal, playerObj, part)
            return
        end
    end
end

function NMVehicleRadial.installHook()
    if NMVehicleRadial.hookInstalled == true then
        return true
    end

    local now = nowMs()
    local nextMs = tonumber(NMVehicleRadial.nextHookAttemptMs) or 0
    if now > 0 and now < nextMs then
        return false
    end
    NMVehicleRadial.nextHookAttemptMs = now + 2000

    if not ISVehicleMenu or type(ISVehicleMenu.showRadialMenu) ~= "function" then return end
    if ISVehicleMenu.NMShowRadialMenuOld then
        NMVehicleRadial.hookInstalled = true
        return true
    end

    ISVehicleMenu.NMShowRadialMenuOld = ISVehicleMenu.showRadialMenu
    ISVehicleMenu.showRadialMenu = function(playerObj)
        ISVehicleMenu.NMShowRadialMenuOld(playerObj)
        injectVehicleRadialMenu(playerObj)
    end

    NMVehicleRadial.hookInstalled = true
    return true
end


