local M = {}
local runtime 
local var = {
    lightColor = {
        taillight = {
            {0.25, 0.11, 0.11},
            {0.20, 0.11, 0.11},
        },
        stoplight = {
            {0.35, 0.11, 0.11},
            {0.3, 0.11, 0.11},
        },
        reverseLight = {
            {0.4, 0.4, 0.4},
            {0.3, 0.3, 0.3},
            {0.22, 0.22, 0.22},            
        }        
    },

    specialExt = {
        TrailerAdvert = -3,
        TrailerFirst = -2.8,
        TrailerSecond = -2.5,
        TrailerCover = -2.5,
        Trailer = -2.5,
        TrailerGenerator = -2,
        Trailer_Horsebox = - 3,
        TrailerHome = 3,
        TrailerHomeHartman = -3,
        TrailerHomeExplorer = -3,
    },
    -- {x, y, color index, radius}
    taillightPositions = {
        {0, 0.3, 1, 2},
        {0, -0.3, 1, 2},
        {-0.3, 0, 2, 3},
        {-0.6, 0, 2, 4},
    },
    -- {x, y, color index, radius}
    stoplightPositions = {
        {0, 0.3, 1, 2},
        {0, -0.3, 1, 2},
        {-0.3, 0, 2, 3},
        {-0.6, 0, 2, 4},
    },
    -- {x, y, color index, radius}
    reverseLightPositions = {

        {0, 0.7, 1, 2},
        {0, 1.3, 1, 2},
        {-0.3, 1, 1, 2},

        {-1, 0.7, 2, 3},          
        {-1, 1.3, 2, 3}, 
        {-1.3, 1, 2, 3}, 

        {-1.5, 0.7, 2, 4},          
        {-1.5, 1.3, 2, 4}, 
        {-1.8, 1, 2, 4}, 

    },
    pid = 0
}

function M.initLights()
    var.pid = getPlayer():getPlayerNum()
    runtime = require "Taillight_Mod_Zomboid/Taillight_Mod_Zomboid_runtime.lua"
end

function M.configVanillaTaillight(part, r, g, b)
	local xOffset = 0.5
	local yOffset = 1.6
	local distance = 3
	local intensity = 0.2
	local dot = 0.75
	local focusing = ZombRand(200)

    local params = part:getTable("headlight")
    if params then
        xOffset = tonumber(params.xOffset) or xOffset
        dot = tonumber(params.dot) or dot
        focusing = tonumber(params.focusing) or focusing
    end

    if part:getId() == "HeadlightRearLeft" then
        part:createSpotLightColor(xOffset, -yOffset, distance, intensity, dot, focusing, r, g, b)
    elseif part:getId() == "HeadlightRearRight" then
        part:createSpotLightColor(-xOffset, -yOffset, distance, intensity, dot, focusing, r, g, b)
    end
end

function M.toggleVanillaTaillight(vehicle, active)
    local r, g, b = 1.0, 0.0, 0.0
    if active == false then r, g, b = 0.0, 0.0, 0.0 end

    local taillight_L = vehicle:getPartById("HeadlightRearLeft")
    local taillight_R = vehicle:getPartById("HeadlightRearRight")
    
    if taillight_L then M.configVanillaTaillight(taillight_L, r, g, b) end
    if taillight_R then M.configVanillaTaillight(taillight_R, r, g, b) end
end

function M.calculateSpeedOffset(speed)
        local delay = 1 / 40
        local offset = speed * delay
        return offset
end

function M.calculateDriftOffset(lv, fv, speed)
        local vx, vz = lv:x(), lv:z()    
        local fx, fz = fv:x(), fv:z()
        local lv_dir = 0
        local fv_dir = 0

        if vz ~= 0 then lv_dir = math.floor(math.atan(vx / vz) * 180 / math.pi) end
        if fz ~= 0 then fv_dir = math.floor(math.atan(fx / fz) * 180 / math.pi) end    

        local dif = math.floor(fv_dir) - math.floor(lv_dir)

        if dif < -90 then
            dif = dif + 180
        elseif dif > 90 then
            dif = dif - 180
        end
        
        local speed_multiplier = speed/122
        local offset = speed_multiplier * 4 * math.sin(math.rad(dif))
        if offset == nil then offset = 0 end
        return offset
end

function M.calculateRotationOffset(ox, oy, vehicle)
        local vx, vy = vehicle:getX(), vehicle:getY()

        local speed_offset = 0
        local rotation_offset = 0

        local lv = Vector3f.new()
        vehicle:getLinearVelocity(lv)
        local fv = Vector3f.new()
        vehicle:getForwardVector(fv) 

        local speed = vehicle:getCurrentSpeedKmHour()           
        speed_offset = M.calculateSpeedOffset(speed)
        rotation_offset = M.calculateDriftOffset(lv, fv, speed)
         
        local angX = fv:x()
        local angY = fv:z()

        ox = ox + speed_offset
        oy = oy + rotation_offset

        local x = ox * angX - oy * angY
        local y = ox * angY + oy * angX

        local x = vx + x
        local y = vy + y

        return x, y
end

function M.addRemoveLamppostsFromCell(vehicle, state)
    local keyId = vehicle:getKeyId()
    local lightInstances = runtime.vehicles[keyId].lightData.lightInstances
    local cell = getCell()

    for i = 1, #lightInstances do
        if state == true then 
            cell:addLamppost(lightInstances[i]) 
        elseif state == false then
            cell:removeLamppost(lightInstances[i])
            lightInstances[i] = nil
        end
    end
end

function M.isTileVisible(x, y)
    local square = getSquare(x, y, 0)
    if square then return square:isCanSee(var.pid) end
 end

function M.getExtentsVehicle(vehicle)
    local area = vehicle:getScript():getAreaById("TruckBed")
    local name = vehicle:getScript():getName()
    local ext

    local part = vehicle:getPartById("HeadlightRearLeft")
    local params
    if part then params = part:getTable("headlight") end
    if params then
        ext = tonumber(params.yOffset) + 1
        ext = -ext
        return ext
    end

    if var.specialExt[name] then ext = var.specialExt[name] return ext end

    if area then 
        ext = (area:getY() - area:getH()) - 0.5
    else 
        ext = -3
    end
    return ext
end
 
function M.LightInstances(vehicle, light)
    local color 
    local positions
    local canSee
    local brightness = {0, 0, 0}

    if light == "taillight" then
        color = var.lightColor.taillight
        positions = var.taillightPositions
        brightness[1] = TaillightModZomboid.getOptBRed()
        
    elseif light == "stoplight" then
        color = var.lightColor.stoplight
        positions = var.stoplightPositions
        brightness[1] = TaillightModZomboid.getOptBRed()
    elseif light == "reverseLight" then
        color = var.lightColor.reverseLight
        positions = var.reverseLightPositions
        brightness[1] = TaillightModZomboid.getOptBReverse()
        brightness[2] = brightness[1]
        brightness[3] = brightness[1]
    else
        return
    end

    local ext = M.getExtentsVehicle(vehicle)
    local keyId = vehicle:getKeyId()    
    local lightInstances = runtime.vehicles[keyId].lightData.lightInstances


    
    for i = 1, #positions do
        local pos = positions[i]
        local x, y  = M.calculateRotationOffset(ext + pos[1], pos[2], vehicle)
        if vehicle == runtime.currentTrailer or vehicle == runtime.currentVehicle or TaillightModZomboid.getOptAlwaysVisible() == true then
            canSee = true
        else
            canSee = M.isTileVisible(x, y)
        end

        if canSee then
            lightInstances[#lightInstances + 1] = IsoLightSource.new(
                            x,
                            y,
                            0,
                            color[pos[3]][1] + brightness[1],
                            color[pos[3]][2] + brightness[2],
                            color[pos[3]][3] + brightness[3],
                            pos[4]
                        )
        end
    end
end

function M.addRefreshLightInstances(vehicle)
    local keyId = vehicle:getKeyId()
    local lightData = runtime.vehicles[keyId].lightData
    
    M.addRemoveLamppostsFromCell(vehicle, false)

    if lightData.isStopLightOn == true then
        M.LightInstances(vehicle, "stoplight")   
    elseif lightData.isLightOn == true then
        M.LightInstances(vehicle, "taillight")      
    end

    if lightData.isReverseLightOn == true then
        M.LightInstances(vehicle, "reverseLight")  
    end
    
    M.addRemoveLamppostsFromCell(vehicle, true)
end

return M