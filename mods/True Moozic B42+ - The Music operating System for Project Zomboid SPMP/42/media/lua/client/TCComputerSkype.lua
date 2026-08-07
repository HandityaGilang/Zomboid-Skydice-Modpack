--[[
    TCComputerSkype.lua
    Plays the Skype ringtone when the player stands within 2 tiles of a base-game
    computer tile (sprite property CustomName ~ "computer"). Probabilistic fire
    with a multi-day cooldown after both pass and fail rolls, so it is not
    spammy and not RAM heavy.

    Sandbox (PZTrueMusicSandbox):
      SkypeRingChance         - integer 0..100, % chance per eligible roll
      SkypeRingCooldownDays   - integer days to wait after any roll
    Sandbox (PZTrueMoozicDebug):
      SkypeRingDebugAlwaysFire - boolean, ignore chance + cooldown, always play
                                 (with a small real-time throttle per tile so it
                                 does not stack).
]]

local SCAN_RADIUS = 2          -- tiles around player to scan
local TICK_INTERVAL = 30       -- ticks between scans (~1s real time)
local DEBUG_PER_TILE_REAL_SEC = 6 -- min real seconds between debug fires per tile

-- per-tile state, keyed by "x,y,z"
local nextRollDays = {}        -- in-game day (number) when this tile becomes eligible again
local lastDebugRealSec = {}    -- os.time() of last debug fire per tile
local tickCounter = 0

local function tileKey(x, y, z)
    return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end

local function getSandbox()
    return SandboxVars and SandboxVars.PZTrueMusicSandbox or nil
end

local function getDebugFlag()
    local sb = SandboxVars and SandboxVars.PZTrueMusicSandbox or nil
    if sb and sb.SkypeRingDebugAlwaysFire then return true end
    return false
end

local function dbgPrint(msg)
    if getDebugFlag() then
        print(msg)
    end
end

-- Sprite-name patterns that identify a base-game desktop computer.
-- Vanilla appliances_com_01_72..75 are the four directional desktop computers.
local COMPUTER_SPRITE_PATTERNS = {
    "^appliances_com_01_7[2-5]$",
}

local function spriteName(obj)
    if not obj then return nil end
    local sprite = obj.getSprite and obj:getSprite() or nil
    if not sprite then return nil end
    if sprite.getName then return sprite:getName() end
    return nil
end

local function isComputerName(name)
    if not name then return false end
    for i = 1, #COMPUTER_SPRITE_PATTERNS do
        if string.find(name, COMPUTER_SPRITE_PATTERNS[i]) then
            return true
        end
    end
    return false
end

local function playSkypeAt(square, debugFire)
    if not square then return end
    local world = getWorld()
    if not world then
        dbgPrint("[SkypeDbg] FAIL: getWorld() nil")
        return
    end
    local emitter = world:getFreeEmitter(square:getX() + 0.5, square:getY() + 0.5, square:getZ())
    if not emitter then
        dbgPrint("[SkypeDbg] FAIL: getFreeEmitter returned nil")
        return
    end
    local handle = emitter:playSound("Skype")
    dbgPrint("[SkypeDbg] PLAY at " .. tostring(square:getX()) .. "," .. tostring(square:getY()) .. "," .. tostring(square:getZ()) .. " handle=" .. tostring(handle))
end

local function tryFireForObject(obj, square, debugFire, sb)
    local key = tileKey(square:getX(), square:getY(), square:getZ())

    if debugFire then
        local now = os.time()
        local last = lastDebugRealSec[key] or 0
        if now - last < DEBUG_PER_TILE_REAL_SEC then return end
        lastDebugRealSec[key] = now
        playSkypeAt(square, true)
        return
    end

    if not sb then return end
    local gt = getGameTime()
    if not gt then return end
    local nowDays = gt:getWorldAgeHours() / 24.0

    local nextDay = nextRollDays[key]
    if nextDay and nowDays < nextDay then return end

    local chance = sb.SkypeRingChance or 5
    if chance < 0 then chance = 0 end
    if chance > 100 then chance = 100 end
    local roll = ZombRand(100)
    local cooldown = sb.SkypeRingCooldownDays or 47
    if cooldown < 1 then cooldown = 1 end
    nextRollDays[key] = nowDays + cooldown

    if roll < chance then
        playSkypeAt(square, false)
    end
end

local function scanSquare(sq, debugFire, sb, stats)
    if not sq then return end

    local lists = {
        sq.getObjects and sq:getObjects() or nil,
        sq.getSpecialObjects and sq:getSpecialObjects() or nil,
        sq.getStaticMovingObjects and sq:getStaticMovingObjects() or nil,
    }

    for li = 1, #lists do
        local list = lists[li]
        if list and list.size then
            local n = list:size()
            for i = 0, n - 1 do
                local obj = list:get(i)
                stats.objsScanned = stats.objsScanned + 1
                local name = spriteName(obj)
                if name then
                    stats.namedSeen = stats.namedSeen + 1
                    if #stats.sampleNames < 8 then
                        stats.sampleNames[#stats.sampleNames + 1] = name
                    end
                    if isComputerName(name) then
                        stats.matched = stats.matched + 1
                        tryFireForObject(obj, sq, debugFire, sb)
                    end
                end
            end
        end
    end
end

local function onTick()
    tickCounter = tickCounter + 1
    if (tickCounter % TICK_INTERVAL) ~= 0 then return end

    local player = getPlayer()
    if not player then return end

    local sb = getSandbox()
    local debugFire = getDebugFlag()
    -- Holiday easter-egg toggle. Default ON when option is missing (older saves).
    -- Debug-fire bypasses the toggle so testing still works.
    if (not debugFire) and sb and sb.SkypeRingEnabled == false then return end
    -- if not in debug and no sandbox available, nothing to do
    if not debugFire and not sb then return end

    local cell = getCell()
    if not cell then
        dbgPrint("[SkypeDbg] no cell")
        return
    end

    local px = math.floor(player:getX())
    local py = math.floor(player:getY())
    local pz = math.floor(player:getZ())

    local stats = { objsScanned = 0, namedSeen = 0, matched = 0, sampleNames = {} }

    for dx = -SCAN_RADIUS, SCAN_RADIUS do
        for dy = -SCAN_RADIUS, SCAN_RADIUS do
            local sq = cell:getGridSquare(px + dx, py + dy, pz)
            if sq then
                scanSquare(sq, debugFire, sb, stats)
            end
        end
    end

    if debugFire then
        local sample = ""
        for i = 1, #stats.sampleNames do
            sample = sample .. (i > 1 and "," or "") .. stats.sampleNames[i]
        end
        dbgPrint("[SkypeDbg] scan @ " .. px .. "," .. py .. "," .. pz ..
            " objs=" .. stats.objsScanned ..
            " named=" .. stats.namedSeen ..
            " matched=" .. stats.matched ..
            " samples=[" .. sample .. "]")
    end
end

Events.OnTick.Add(onTick)
