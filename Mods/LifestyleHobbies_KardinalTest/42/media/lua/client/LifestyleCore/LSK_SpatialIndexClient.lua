local Scheduler = require("LifestyleCore/LSK_Scheduler")
local SpatialIndex = require("LifestyleCore/LSK_SpatialIndex")
local legacyList = require("Properties/Objects/List")

SpatialIndex.configureLegacyList(legacyList)

local function registerObject(object)
    SpatialIndex.register(object)
end

local function unregisterObject(object)
    SpatialIndex.unregister(object)
end

local function registerSquare(square)
    if not square then
        return
    end
    local objects = square:getObjects()
    if not objects then
        return
    end
    for index = 0, objects:size() - 1 do
        SpatialIndex.register(objects:get(index))
    end
end

if not SpatialIndex._clientEventsInstalled then
    Events.OnObjectAdded.Add(registerObject)
    Events.OnObjectAboutToBeRemoved.Add(unregisterObject)
    Events.LoadGridsquare.Add(registerSquare)
    SpatialIndex._clientEventsInstalled = true
end

Scheduler.register("LSKSpatialIndex.Prune", Scheduler.LANES.SLOW, function()
    SpatialIndex.prune(256)
end, {
    requirePlayer = false,
    allowDead = true,
    allowAsleep = true,
})

return SpatialIndex
