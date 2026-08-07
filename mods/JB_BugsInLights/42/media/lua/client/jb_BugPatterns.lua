--jb_BugPatterns.lua

local BugPattern = {}
BugPattern.__index = BugPattern

function BugPattern.random()
    local i = ZombRand(1, #BugPattern.presets + 1)
    return BugPattern.presets[i]
end

function BugPattern.addBug(config)
    config = config or {}
    local newBugPattern = BugPattern:new(config)
    table.insert(BugPattern.presets, newBugPattern)
    return newBugPattern
end

--[[

Adding your own bugs

model: This is the name of the 3D item model used for the bug, like "Base.Plushabug"
size: This determines the scale of the 3D item. 1.0 represents the full size of the item, a good range would be 0.05 to 0.8 for bugs
speed: This sets the base velocity applied to the bug during movement. A good range is 0.0001 to 0.01, since higher values can cause the bug to move too fast to see
yawOffset: This is a degree adjustment used to ensure the "front" of your 3D model faces the actual direction of travel. The range is 0 to 360, and typical values are 0, 90 or 180 depending on how the model was exported
crazyFactor: This controls the amount of random "jitter" or "crazy"" added to the bug's velocity every frame. A good range is 0.00001 to 0.02; higher values create frantic, crack-head movement, while lower values looks like a steady drift
lightAttraction: This is how strongly the bug is "pulled" toward the light source. A range of 0.001 to 0.5 is good. Higher values make the bugs stick too close to the light source
areaOfInterest: This is the radius in squares/tiles around the light source where the bug will spend its life. A good range is 0.1 to 1.5
minFrames and maxFrames: This defines the lifespan of a single bug instance in update ticks before it despawns. A suitable range is 30 to 600, which is roughly 1 to 10 seconds of activity at 60 FPS

Example mod put in lua/client:

local BugPattern = require("jb_BugPatterns")
local bug = {
    model           = "Base.Plushabug",
    size            = 0.06,
    speed           = 0.001,
    yawOffset       = 90,
    crazyFactor     = 0.01,
    lightAttraction = 0.001,
    areaOfInterest  = 0.5,
    minFrames       = 180,
    maxFrames       = 600,
}

BugPattern.addBug(bug)

--The bugs don't start ticking away until OnGameTimeLoaded

]]

function BugPattern:new(o)
    o = o or {}
    setmetatable(o, BugPattern)
    o.speed = o.speed
    o.model = o.model
    o.size = o.size
    o.yawOffset = o.yawOffset
    o.crazyFactor = o.crazyFactor
    o.lightAttraction = o.lightAttraction
    o.areaOfInterest = o.areaOfInterest
    o.minFrames = o.minFrames
    o.maxFrames = o.maxFrames
    return o
end

BugPattern.Moth = BugPattern:new({
    model           = "Base.Plushabug",
    size            = 0.06,
    speed           = 0.001,
    yawOffset       = 180,
    crazyFactor     = 0.000001,
    lightAttraction = 0.3,
    areaOfInterest  = 0.3,
    minFrames       = 30,
    maxFrames       = 90,
})

BugPattern.Junebug = BugPattern:new({
    model           = "Base.Acorn",
    size            = 0.3,
    speed           = 0.0001,
    yawOffset       = 90,
    crazyFactor     = 0.01,
    lightAttraction = 0.001,
    areaOfInterest  = 0.5,
    minFrames       = 180,
    maxFrames       = 600,
})

BugPattern.Gnat = BugPattern:new({
    model           = "Base.Pillbug",
    size            = 0.5,
    speed           = 0.01,
    yawOffset       = 90,
    crazyFactor     = 0.01,
    lightAttraction = 0.1,
    areaOfInterest  = 0.25,
    minFrames       = 60,
    maxFrames       = 180,
})

BugPattern.LadyBug = BugPattern:new({
    model           = "Base.Ladybug",
    size            = 0.7,
    speed           = 0.001,
    yawOffset       = 90,
    crazyFactor     = 0.001,
    lightAttraction = 0.01,
    areaOfInterest  = 0.25,
    minFrames       = 60,
    maxFrames       = 180,

})

BugPattern.presets = {
    BugPattern.Moth,
    BugPattern.Junebug,
    BugPattern.Gnat,
    BugPattern.LadyBug,
}

return BugPattern