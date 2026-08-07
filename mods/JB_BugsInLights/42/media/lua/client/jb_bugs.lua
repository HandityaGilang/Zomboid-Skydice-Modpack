-- jb_bugs.lua

if ModSelector.Model and ModSelector.Model.categories and not ModSelector.Model.categories["Jim Beam's Mods"] then
    ModSelector.Model.categories["Jim Beam's Mods"] = "Item_Plush_CthulhuEye"
end

JBBugsInLights = JBBugsInLights or {}
local BugManager = require("jb_BugsInLightsRenderer")
local BugPatterns = require("jb_BugPatterns")
local LightOffsets = require("jb_light_offsets")
local SPAWN_TIMER = 0
local SPAWN_INTERVAL = 0.01
local MAX_BUGS_PER_LIGHT = 25

function JBBugsInLights.getSpawnLimit()
    local modOptions = PZAPI.ModOptions:getOptions("JB_BugOptions")
    if not modOptions then return 0 end

    local gt = getGameTime()
    local cm = getClimateManager()
    
    local tempFactor = 1 
    local rainFactor = 1
    local nightFactor = 1
    local activeDayNightOpt = modOptions:getOption("JB_BugOptions_AcitveDayAndNight")
    
    if activeDayNightOpt and not activeDayNightOpt:getValue() then
        nightFactor = cm:getNightStrength()
        if nightFactor < 0.3 then return 0 end
    end

    local activeAllYearOpt = modOptions:getOption("JB_BugOptions_ActiveAllYear")
    if activeAllYearOpt and not activeAllYearOpt:getValue() then
        local day = (gt:getMonth() + 1) * 30 + gt:getDay()
        if day < 90 or day > 260 then return 0 end
    end
    
    local environAffectsOpt = modOptions:getOption("JB_BugOptions_EnvironAffectsSpawn")
    if environAffectsOpt and environAffectsOpt:getValue() then
        local temp = cm:getTemperature()
        tempFactor = 0
        if temp >= 25 then 
            tempFactor = 1
        elseif temp > 13 then
            tempFactor = (temp - 13) / 12
        end
    
        if tempFactor <= 0 then return 0 end
        
        rainFactor = 1 - math.min(cm:getPrecipitationIntensity(), 1)
    end

    local maxBugsValue = 5
    local bugsPerLightOpt = modOptions:getOption("JB_BugOptions_BugsPerLight")
    if bugsPerLightOpt then
        maxBugsValue = tonumber(bugsPerLightOpt:getValue()) or 5
    end

    local finalLimit = maxBugsValue * rainFactor * tempFactor * nightFactor
    
    return math.floor(finalLimit)
end


local function attemptSpawn(playerNum, square, x, y, z, maxBugs)
    if not square then return end
    local bugCountPerLight = BugManager.getBugCountPerLight(square)
    if bugCountPerLight >= maxBugs then return end
    BugManager.addBug(playerNum, square, x, y, z, BugPatterns.random())
end

local function isLOSValid(result)
    local str = tostring(result)

    local valid = {
        ["Clear"] = true,
        ["ClearThroughOpenDoor"] = true,
        ["ClearThroughWindow"] = true,
    }

    return valid[str] == true
end

function JBBugsInLights.spawnCycle()
    local playerObj = getPlayer()
    if not playerObj or playerObj:getZ() < 0 then
        return
    end

    local maxBugs = JBBugsInLights.getSpawnLimit()

    local cell = getCell()
    local lamps = cell:getLamppostPositions()
    if not lamps then  return end
    local playerNum = playerObj:getPlayerNum()
    local modOptions = PZAPI.ModOptions:getOptions("JB_BugOptions")
    local activeDayNightOpt = modOptions:getOption("JB_BugOptions_AcitveDayAndNight")

    for i = 0, lamps:size() - 1 do

        local lamp = lamps:get(i)

        if lamp:isActive() or activeDayNightOpt:getValue() then -- is this thing on?
            local x, y, z = lamp:getX(), lamp:getY(), lamp:getZ()
            local px, py, pz = playerObj:getX(), playerObj:getY(), playerObj:getZ()
            local square = cell:getGridSquare(x, y, z)

            --use the javvaaa things
            local losResult = LosUtil.lineClear(cell, x, y, z, px, py, pz, false)
            local hasLos = isLOSValid(losResult)

            --I tried with isOutside but it's not reliable. not hasRoomDef works better
            if square and square:IsOnScreen() and hasLos and not square:hasRoomDef() then

                local objs = square:getObjects()

                for j = 0, objs:size() - 1 do
                    local obj = objs:get(j)
                    if obj and not instanceof(obj, "IsoFire") then -- fires are light sources duh
                        local sprite = obj:getSprite()
                        local spriteName = sprite and sprite:getName()
                        local offset = spriteName and LightOffsets[spriteName]

                        if offset then
                            -- std light
                            attemptSpawn(playerNum, square,
                                x + (offset.offsetX or 0),
                                y + (offset.offsetY or 0),
                                z + (offset.offsetZ or z),
                                maxBugs)

                            -- dbl lights
                            if spriteName == "lighting_outdoor_01_6" then
                                attemptSpawn(playerNum, square,
                                    x + (offset.offsetX or 0) + 1,
                                    y + (offset.offsetY or 0),
                                    z + (offset.offsetZ or z),
                                    maxBugs)

                            elseif spriteName == "lighting_outdoor_01_7" then
                                attemptSpawn(playerNum, square,
                                    x + (offset.offsetX or 0),
                                    y + (offset.offsetY or 0) + 1,
                                    z + (offset.offsetZ or z),
                                    maxBugs)

                            elseif spriteName == "lighting_outdoor_01_53" then
                                attemptSpawn(playerNum, square,
                                    x + (offset.offsetX or 0) + 1,
                                    y + (offset.offsetY or 0),
                                    z + (offset.offsetZ or z),
                                    maxBugs)

                            elseif spriteName == "lighting_outdoor_01_54" then
                                attemptSpawn(playerNum, square,
                                    x + (offset.offsetX or 0),
                                    y + (offset.offsetY or 0) - 0.8,
                                    z + (offset.offsetZ or z),
                                    maxBugs)
                            end
                        end
                    end
                end
            end
        end
    end
end

Events.OnGameTimeLoaded.Add(function()

    --getGameTime():setTimeOfDay(0) -- MAKE IT THE WITCHING HOUR AHHHHH TURN IT OFF BEFORE YOU UPLOAD

    Events.OnTick.Add(function()
        local dt = getGameTime():getTimeDelta() -- like delta force, but for time

        SPAWN_TIMER = SPAWN_TIMER + dt
        if SPAWN_TIMER >= SPAWN_INTERVAL then -- I'm leaving the interval at 0.01 for now, which feels correct
            SPAWN_TIMER = 0
            JBBugsInLights.spawnCycle()
        end
    
    end)
end)
