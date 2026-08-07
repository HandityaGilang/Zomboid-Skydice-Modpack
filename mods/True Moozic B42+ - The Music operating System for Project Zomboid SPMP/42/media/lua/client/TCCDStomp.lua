-- TCCDStomp.lua
-- CDs lying on the ground get scratched when a player or zombie walks over
-- them. Each stomp raises the tier one step: 0% -> 25% -> 50% -> 100%.
-- Detection is client-side (tile-change of the local player and nearby
-- zombies); the authoritative scratch is applied on the server via the
-- 'truemusic'/'stompCD' command, with the local copy stamped too for
-- immediate name/tooltip feedback.

require "TCMusicDefenitions"

local STOMP_COOLDOWN_MS = 1500
local ZOMBIE_SCAN_TICKS = 20
local ZOMBIE_SCAN_RANGE = 30

-- Local per-item cooldown (item id -> last stomp ms) so one crossing
-- doesn't fire multiple times before the server round trip.
local lastStompMs = {}

local function stompSquare(sq)
    if not sq or not sq.getWorldObjects then return end
    local wobjs = sq:getWorldObjects()
    if not wobjs or wobjs:size() == 0 then return end
    local now = getTimestampMs()
    for i = 0, wobjs:size() - 1 do
        local wobj = wobjs:get(i)
        if instanceof(wobj, "IsoWorldInventoryObject") then
            local it = wobj:getItem()
            if it and TCMusic.isScratchableCDItem and TCMusic.isScratchableCDItem(it) then
                local id = it:getID()
                local md = it:getModData()
                local cur = md.TMScratch or 0
                local last = lastStompMs[id] or md.TMStompMs
                if cur < 100 and not (last and (now - last) < STOMP_COOLDOWN_MS) then
                    lastStompMs[id] = now
                    md.TMStompMs = now
                    local nextTier = TCMusic.getStompNextTier(cur)
                    if isClient() then
                        -- Local stamp for immediate feedback; server is authoritative.
                        TCMusic.setScratchTier(it, nextTier, true)
                        sendClientCommand(getPlayer(), "truemusic", "stompCD", {
                            x = sq:getX(), y = sq:getY(), z = sq:getZ(),
                            itemId = tostring(id),
                        })
                    else
                        TCMusic.setScratchTier(it, nextTier, true)
                    end
                end
            end
        end
    end
end

------------------------------------------------------------
-- Local player: stomp when the player moves onto a new tile.
------------------------------------------------------------
local lastPlayerTile = nil

local function onPlayerUpdate(player)
    if player ~= getPlayer() then return end
    if player:getVehicle() then
        lastPlayerTile = nil
        return
    end
    local tx = math.floor(player:getX())
    local ty = math.floor(player:getY())
    local tz = math.floor(player:getZ())
    local key = tx .. ":" .. ty .. ":" .. tz
    if key == lastPlayerTile then return end
    lastPlayerTile = key
    stompSquare(getCell():getGridSquare(tx, ty, tz))
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)

------------------------------------------------------------
-- Zombies: periodic scan of loaded zombies near the local player;
-- stomp when a zombie moves onto a new tile.
------------------------------------------------------------
local zombieTick = 0

local function onTickZombies()
    zombieTick = zombieTick + 1
    if zombieTick < ZOMBIE_SCAN_TICKS then return end
    zombieTick = 0

    local player = getPlayer()
    if not player then return end
    local cell = getCell()
    if not cell or not cell.getZombieList then return end
    local zombies = cell:getZombieList()
    if not zombies then return end

    local px = player:getX()
    local py = player:getY()

    for i = 0, zombies:size() - 1 do
        local z = zombies:get(i)
        if z and not z:isDead() then
            local zx = z:getX()
            local zy = z:getY()
            if math.abs(zx - px) <= ZOMBIE_SCAN_RANGE and math.abs(zy - py) <= ZOMBIE_SCAN_RANGE then
                local tx = math.floor(zx)
                local ty = math.floor(zy)
                local tz = math.floor(z:getZ())
                local key = tx .. ":" .. ty .. ":" .. tz
                local zmd = z:getModData()
                if zmd.TMLastTile ~= key then
                    zmd.TMLastTile = key
                    stompSquare(cell:getGridSquare(tx, ty, tz))
                end
            end
        end
    end
end

Events.OnTick.Add(onTickZombies)
