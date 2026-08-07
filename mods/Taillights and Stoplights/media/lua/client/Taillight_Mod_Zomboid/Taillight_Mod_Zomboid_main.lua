local ISTimer = require "Taillight_Mod_Zomboid/Taillight_Mod_Zomboid_ISTimer"
local runtime = require "Taillight_Mod_Zomboid/Taillight_Mod_Zomboid_runtime.lua"
local lights = require "Taillight_Mod_Zomboid/Taillight_Mod_Zomboid_lights.lua"

local listSize = 0

-- function OnKeyStartPressed(key)
--     if key == Keyboard.KEY_T then
--         print("Preparing for reset...")
--         print("Stopping the timer...")
--         runtime.runtimeUpdateTimer:stop()
--         print("Clearing the ISTimer data...")
--         ISTimer.IDMax = 1;
--         ISTimer.Timers = {};
--         print("Removing active lights")
--         for i = 1, #runtime.vehiclesKeyIdList do
--             local vehicle = runtime.getVehicleByKeyId(runtime.vehiclesKeyIdList[i])
--             lights.addRemoveLamppostsFromCell(vehicle, false)
--         end
--         print("Ready to reload")
--     end
    
--     if key == Keyboard.KEY_Y then
--         ModOptions:loadFile()
--         print("Reverse lights: " .. tostring(TaillightsHaibane.SETTINGS.options.reverseLight))
--     end
-- end

local function onExitVehicle(character)
    local vehicle = runtime.currentVehicle
    local trailer = runtime.currentTrailer
    runtime.currentVehicle = nil
    runtime.currentTrailer = nil
    runtime.turnOffLights(vehicle)
end

local function onEnterVehicle(character)
    local vehicle = character:getVehicle()
    runtime.currentVehicle = vehicle
    runtime.currentTrailer = vehicle:getVehicleTowing()
end

local function checkIfPlayerIsInVehicle()
    local player = getPlayer()
    local vehicle = player:getVehicle()
    if vehicle then
        onEnterVehicle(player)
    end
end

local function initEvents(regions)
    runtime.initRuntime()
    runtime.createRuntimeTimer()
    lights.initLights()
    checkIfPlayerIsInVehicle()

    -- Events.OnKeyStartPressed.Add(OnKeyStartPressed)
    Events.OnEnterVehicle.Add(onEnterVehicle)
    Events.OnExitVehicle.Add(onExitVehicle)
    runtime.runtimeUpdateTimer:start()
 end

local function onTick(tick)
    local cell = getCell()
    if not cell then return end

    local list = cell:getVehicles()
    if not list then return end

    local size = list:size()
    if size ~= listSize then
        listSize = size
        return
    end

    Events.OnTick.Remove(onTick)
    initEvents()
end

local function onInitWorld()
    Events.OnTick.Add(onTick)
end

if  Taillight_Mod_Zomboid_HOT_RELOAD then
    initEvents()
else
    Taillight_Mod_Zomboid_HOT_RELOAD = true
    Events.OnInitWorld.Add(onInitWorld)
end


