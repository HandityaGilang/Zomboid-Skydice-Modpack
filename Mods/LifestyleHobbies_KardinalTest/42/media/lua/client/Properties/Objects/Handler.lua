--------------------------------------------------------------------------------------------------
--        ----      |              |            |         |                |    --    |      ----            --
--        ----      |              |            |         |                |    --       |      ----            --
--        ----      |        -------       -----|     ---------        -----          -      ----       -------
--        ----      |            ---            |         -----        ------        --      ----            --
--        ----      |            ---            |         -----        -------          ---      ----            --
--        ----      |        -------       ----------     -----        -------         ---      ----       -------
--            |      |        -------            |         -----        -------         ---          |            --
--            |      |        -------            |          -----        -------         ---          |            --
--------------------------------------------------------------------------------------------------

require "LSEffectsJukeboxFunctions"

local Scheduler = require("LifestyleCore/LSK_Scheduler")
local SpatialIndex = require("LifestyleCore/LSK_SpatialIndexClient")
local LSInteractiveObjs = {}

LSInteractiveObjs.Jukebox = function(thisPlayer, object)
    if object and object:hasModData() and object:getModData().OnOff and
    object:getModData().OnOff == "on" and object:getModData().OnPlay and
    object:getModData().OnPlay ~= "nothing" and tostring(object:getModData().Style) ~= nil then
        local style = object:getModData().Style
        if (not object:getModData().Emitter) or (not object:getModData().OnPlayEMITTER) then
            object:getModData().OnPlay = "nothing"
            object:getModData().Length = 3
            object:getModData().genre = "JukeboxAfterTurnOn"
            OnJukeboxStyleChange(object:getX(), object:getY(), object:getZ(), style, 3, "JukeboxAfterTurnOn")            
        end
        if thisPlayer:getModData().IsListeningToDJ then thisPlayer:getModData().IsListeningToJukebox = false; return; end
        thisPlayer:getModData().IsListeningToJukebox = true
        if (not thisPlayer:getModData().IsListeningToMusicStyle) or
        tostring(thisPlayer:getModData().IsListeningToMusicStyle) ~= tostring(style) then
            thisPlayer:getModData().IsListeningToMusicStyle = tostring(style)
        end
    else
    thisPlayer:getModData().IsListeningToJukebox = false
    end
end

LSInteractiveObjs.DiscoBall = function(thisPlayer, object)
    --tbd
end

LSInteractiveObjs.DiscoFloor = function(thisPlayer, object)
    --tbd
end

LSInteractiveObjs.GFClock = function(thisPlayer, object)
    --tbd
end

LSInteractiveObjs.Hygienator = function(thisPlayer, object)
    --tbd
end

local function getPropertyName(object, property)
    local properties = object:getSprite() and object:getSprite():getProperties()
    if properties and properties:has(property) then
        return properties:get(property)
    end
    return nil
end

local function processInteractiveObject(thisPlayer, object)
    local customName = getPropertyName(object, "CustomName")
    local groupName = getPropertyName(object, "GroupName")
    local name = customName or groupName
    if not name then
        return
    end
    local handler = LSInteractiveObjs[name:gsub(" ", "")]
    if handler then
        handler(thisPlayer, object)
    end
end

local discoveryOffsets = {}
local discoveryCursor = 1
local discoveryCenterX = nil
local discoveryCenterY = nil
local discoveryCenterZ = nil
local FALLBACK_RADIUS = 12
local FALLBACK_SQUARES_PER_RUN = 6

for radius = 0, FALLBACK_RADIUS do
    for offsetX = -radius, radius do
        for offsetY = -radius, radius do
            if math.max(math.abs(offsetX), math.abs(offsetY)) == radius then
                table.insert(discoveryOffsets, { x = offsetX, y = offsetY })
            end
        end
    end
end

local function discoverSquare(x, y, z)
    local square = getCell():getGridSquare(x, y, z)
    if not square then
        return
    end
    local objects = square:getObjects()
    for index = 0, objects:size() - 1 do
        SpatialIndex.register(objects:get(index))
    end
end

local function runFallbackDiscovery(context)
    local thisPlayer = context.player
    local playerX = math.floor(thisPlayer:getX())
    local playerY = math.floor(thisPlayer:getY())
    local playerZ = math.floor(thisPlayer:getZ())
    if discoveryCenterX == nil or discoveryCenterZ ~= playerZ or
    math.abs(playerX - discoveryCenterX) >= 5 or math.abs(playerY - discoveryCenterY) >= 5 then
        discoveryCenterX = playerX
        discoveryCenterY = playerY
        discoveryCenterZ = playerZ
        discoveryCursor = 1
    end

    for _ = 1, FALLBACK_SQUARES_PER_RUN do
        local offset = discoveryOffsets[discoveryCursor]
        if not offset then
            discoveryCursor = 1
            return
        end
        discoverSquare(discoveryCenterX + offset.x, discoveryCenterY + offset.y, discoveryCenterZ)
        discoveryCursor = discoveryCursor + 1
    end
end

local function updateNearbyInteractiveObjects(context)
    local thisPlayer = context.player
    local nearby = SpatialIndex.queryNearbyPlayer("interactive", thisPlayer, 8)
    local hasJukebox = false
    for index = 1, #nearby do
        local object = nearby[index]
        if getPropertyName(object, "CustomName") == "Jukebox" then
            hasJukebox = true
        end
        processInteractiveObject(thisPlayer, object)
    end
    if thisPlayer:getModData().IsListeningToJukebox and not hasJukebox then
        thisPlayer:getModData().IsListeningToJukebox = false
    end
end

Scheduler.register("LifestyleObjects.Discovery", Scheduler.LANES.FAST, runFallbackDiscovery, {
    playerIndex = 0,
    allowAsleep = true,
})

Scheduler.register("LifestyleObjects.NearbyEffects", Scheduler.LANES.NORMAL, updateNearbyInteractiveObjects, {
    playerIndex = 0,
    allowAsleep = true,
})
