-- jb_BugsInLightsRenderer.lua

local BugPatterns = require("jb_BugPatterns")
local randy = newrandom()

-- getTexture can come back nil if it runs before the texture is loaded
local bugtex
local function getBugTex()
    if not bugtex then
        bugtex = getTexture("media/textures/Item_jb_buginlight_0.png")
    end
    return bugtex
end

-- do math stuff now so we don't have to do it on the fly as much
local DIVISIONS = 1024 -- I dont think we needed 1024 divisions but yolo
local SIN_TABLE = {}
local COS_TABLE = {}
for i = 0, DIVISIONS - 1 do
    local angle = (i / DIVISIONS) * (math.pi * 2)
    SIN_TABLE[i] = math.sin(angle)
    COS_TABLE[i] = math.cos(angle)
end

local function tsin(angle)
    local i = math.floor((angle % (math.pi * 2)) / (math.pi * 2) * DIVISIONS) % DIVISIONS
    return SIN_TABLE[i]
end

local function tcos(angle)
    local i = math.floor((angle % (math.pi * 2)) / (math.pi * 2) * DIVISIONS) % DIVISIONS
    return COS_TABLE[i]
end

-- call the render only if we can see the bug
local LOSHandlers = {
    Clear = function(bug, zoom) bug:render(zoom) end,
    ClearThroughOpenDoor = function(bug, zoom) bug:render(zoom) end,
    ClearThroughWindow = function(bug, zoom) bug:render(zoom) end,
    -- you can't see shit
    Blocked = function(bug, zoom) end,
    ClearThroughClosedDoor = function(bug, zoom) end,
}

local function handleLOS(result, bug, zoom)
    local handler = LOSHandlers[tostring(result)]
    if handler then handler(bug, zoom) end
end

-- what is "bug"
local Bug = {}
Bug.__index = Bug

function Bug:new(playerNum, square, x, y, z, pattern)
    local o = setmetatable({}, Bug)

    o.pattern = pattern
    o.square = square
    o.playerNum = playerNum
    o.lightX, o.lightY, o.lightZ = x, y, z

    o.bugX = x + ZombRandFloat(-0.35, 0.35)
    o.bugY = y + ZombRandFloat(-0.35, 0.35)
    o.bugZ = math.max(0.5, z - ZombRandFloat(-0.25, 0.25))

    o.vx = randy:random() * pattern.speed
    o.vy = randy:random() * pattern.speed
    o.vz = randy:random() * pattern.speed * 0.5

    o.size = pattern.size
    o.frameCount = 0

    o.lifespan = randy:random(pattern.minFrames, pattern.maxFrames) * 0.016
    o.age = 0

    o.timer = 0
    o.updateInterval = 0.01 + (randy:random() * 0.02)

    o.bugItem = instanceItem(pattern.model)
    o.bugItem:setTexture(getBugTex())

    -- MAKE SURE THESE ARE COMMENTED OUT BEFORE YOU UPLOAD BRO
    --o.bugTestItem = instanceItem("Base.Baseball")
    --o.bugTestItem:setWorldScale(0.3)

    o.state = "approach"
    o.targetX = o.lightX
    o.targetY = o.lightY
    o.targetZ = o.lightZ

    o.yaw = 0
    o.yawOffset = pattern.yawOffset -- yaw see this?

    return o
end

function Bug:update(dt)
    -- Thank you to the Game Physics Cookbook and googly search( mostly stackexchange) for helping me through this nightmare
    
    self.age = self.age + dt
    if self.age > self.lifespan then return false end

    self.timer = self.timer + dt
    if self.timer < self.updateInterval then return true end
    self.timer = 0

    local pattern = self.pattern

    -- we don't have a target on the first run through, so use the light
    local dx = (self.targetX or self.lightX) - self.bugX
    local dy = (self.targetY or self.lightY) - self.bugY
    local dz = (self.targetZ or self.lightZ) - self.bugZ
    local dist = math.sqrt(dx * dx + dy * dy + dz * dz)

    -- slow the bugger down around the edges
    local maxDist = pattern.areaOfInterest * 1.5
    if dist > maxDist then
        self.bugX = self.lightX + (dx / dist) * maxDist
        self.bugY = self.lightY + (dy / dist) * maxDist
        self.bugZ = self.lightZ + (dz / dist) * maxDist
        self.vx, self.vy, self.vz = self.vx * 0.1, self.vy * 0.1, self.vz * 0.1
    end

    -- go towards the light, my son
    if self.state == "approach" then
        local unitDist = math.sqrt(dx * dx + dy * dy)
        local uDx, uDy = 0, 0
        if unitDist > 0 then uDx, uDy = dx / unitDist, dy / unitDist end

        local pullStrength = math.min(pattern.lightAttraction * (dist + 0.5), 0.08)

        self.vx = self.vx + uDx * pullStrength + ((randy:random() * 2 - 1) * pattern.crazyFactor)
        self.vy = self.vy + uDy * pullStrength + ((randy:random() * 2 - 1) * pattern.crazyFactor)
        self.vz = self.vz + dz * pullStrength + ((randy:random() * 2 - 1) * pattern.crazyFactor)

        -- we flew too close to the sun! let's bounce
        if dist < 0.1 then
            self.state = "bouncing"
            self.bounceFrames = 0
            self.maxBounceFrames = randy:random(10, 25)
            self:pickBounceTarget(randy)
        end

    -- I'm a bouncy boy. let's get away from this bright light
    elseif self.state == "bouncing" then
        self.vx = self.vx + dx * 0.03 + ((randy:random() * 2 - 1) * pattern.crazyFactor * 2)
        self.vy = self.vy + dy * 0.03 + ((randy:random() * 2 - 1) * pattern.crazyFactor * 2)
        self.vz = self.vz + dz * 0.03 + ((randy:random() * 2 - 1) * pattern.crazyFactor)

        if dist < 0.08 then self:pickBounceTarget(randy) end
        self.bounceFrames = self.bounceFrames + 1

        if self.bounceFrames > self.maxBounceFrames then
            self.state = "approach"
            local angle = randy:random() * math.pi * 2
            local flingDist = ZombRandFloat(0.01, pattern.areaOfInterest)
            self.targetX = self.lightX + tcos(angle) * flingDist
            self.targetY = self.lightY + tsin(angle) * flingDist
            self.targetZ = math.max(-0.9, self.lightZ + ZombRandFloat(-0.8, 0.1))
            self.vx, self.vy = tcos(angle) * pattern.speed, tsin(angle) * pattern.speed
        end
    end

    -- slow your roll
    local damping = 0.98
    self.vx, self.vy, self.vz = self.vx * damping, self.vy * damping, self.vz * damping

    -- only change the yaw if we're moving so we don't get too much flickering
    local speed = math.sqrt(self.vx * self.vx + self.vy * self.vy)
    if speed > 0.0001 then
        local targetYaw = math.deg(math.atan2(self.vy, self.vx))
        local diff = targetYaw - self.yaw
        while diff > 180 do diff = diff - 360 end
        while diff < -180 do diff = diff + 360 end
        self.yaw = self.yaw + diff * 0.2
    end

    -- how the fuck did all that math not crash this?
    self.bugX = self.bugX + self.vx * 0.2
    self.bugY = self.bugY + self.vy * 0.2
    self.bugZ = math.max(0.5, self.bugZ + self.vz * 0.2)

    return true
end

function Bug:pickBounceTarget(randy)
    local angle = randy:random() * math.pi * 2
    local radius = ZombRandFloat(0.03, 0.12)
    self.targetX = self.bugX + tcos(angle) * radius
    self.targetY = self.bugY + tsin(angle) * radius
    self.targetZ = math.max(0.1, self.lightZ + ZombRandFloat(-0.3, 0.1))
end

function Bug:render(zoom)
    local cell   = getCell()
    local square = cell:getOrCreateGridSquare(self.lightX, self.lightY, self.lightZ)

    if square then
        local modOptions = PZAPI.ModOptions:getOptions("JB_BugOptions")
        
        local dist = math.sqrt((self.bugX - self.lightX) ^ 2 + (self.bugY - self.lightY) ^ 2)
        local alpha = 1.0 - math.min(dist / self.pattern.areaOfInterest, 1.0)
        local renderYaw = self.yaw + (self.pattern.yawOffset)

        self.bugItem:setWorldAlpha(alpha)
        self.bugItem:setWorldScale(self.size * (zoom >= 1 and zoom or 1))

        if modOptions and modOptions:getOption("JB_BugOptions_SizeOfBugs") then
            local size = modOptions:getOption("JB_BugOptions_SizeOfBugs"):getValue(1)
            self.bugItem:setWorldScale(self.size * size)
        end

        -- MAKE SURE THIS IS COMMENTED OUT BEFORE YOU UPLOAD YOU FRICKIN DING DONG
        --Render3DItem(self.bugTestItem, square, self.lightX, self.lightY, self.lightZ, 0)

        -- check that we have the texture and grab it if we don't
        if not self.bugItem:getTex() then
            self.bugItem:setTexture(getBugTex())
            if not self.bugItem:getTex() then return end
        end

        Render3DItem(self.bugItem, square, self.bugX, self.bugY, self.bugZ, renderYaw)
    end
end

local BugManager = {
    -- so weak. idk if PZ lua even cares about weak keys but here we are
    activeBugs = {},
    squareCounts = setmetatable({}, { __mode = "k" })
}

function BugManager.addBug(playerNum, square, x, y, z, pattern)
    local bug = Bug:new(playerNum, square, x, y, z, pattern)
    table.insert(BugManager.activeBugs, bug)
    BugManager.squareCounts[square] = (BugManager.squareCounts[square] or 0) + 1
end

function BugManager.getBugCountPerLight(square)
    return BugManager.squareCounts[square] or 0
end

function BugManager.updateAll()
    local bugs = BugManager.activeBugs
    local dt = getGameTime():getTimeDelta()

    for i = #bugs, 1, -1 do
        local bug = bugs[i]
        if not bug then return end

        if not bug:update(dt) then
            if bug.square then
                local current = BugManager.squareCounts[bug.square] or 1
                BugManager.squareCounts[bug.square] = math.max(0, current - 1)
            end
            table.remove(bugs, i)
        end
    end
end

function BugManager.renderAll()
    if #BugManager.activeBugs == 0 then return end

    local zoom = getCore():getZoom(0)
    local cell = getCell()
    local player = getPlayer()

    for _, bug in ipairs(BugManager.activeBugs) do
        if bug.square and bug.square:IsOnScreen() then
            local px, py, pz = player:getX(), player:getY(), player:getZ()
            local sx, sy, sz = bug.square:getX(), bug.square:getY(), bug.square:getZ()
            local losResult  = LosUtil.lineClear(cell, sx, sy, sz, px, py, pz, false)
            handleLOS(losResult, bug, zoom) -- this will call bug:render if needed
        end
    end
end

Events.RenderOpaqueObjectsInWorld.Add(BugManager.renderAll) -- the only event that Render3DItem works with
Events.OnRenderTick.Add(BugManager.updateAll) -- keep them buggies updated even if we aren't rendering it atm

BugManager.Pattern = BugPatterns

return BugManager
