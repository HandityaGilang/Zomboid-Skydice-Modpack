-- =========================================================================
-- LagCleaner3000Server.lua  v2.3
-- Server optimization: aggressive automatic ground item cleanup
-- Scans every game minute, cleanup time configurable in minutes (min: 1min)
--
-- CLEANED (everything loose on the ground = IsoWorldInventoryObject):
--   - Items dropped by players (not placed via "Place" menu)
--   - Tree debris (logs, branches, planks, twigs after chopping)
--   - World-spawned loot on the ground (not inside containers)
--   - Corpse loot dropped on ground
--   - ANY IsoWorldInventoryObject that was NOT intentionally placed
--
-- NEVER CLEANED:
--   - Items placed by players via "Place" (isIgnoreRemoveSandbox = true)
--   - Furniture, barricades, constructions (IsoObject subclasses)
--   - Moveables placed by players (IsoMoveableObject)
--   - Items inside containers (shelves, bags, crates, fridges, etc.)
--   - Base building (walls, floors, stairs, doors, windows)
--   - Generators, rain collectors, traps
--
-- Removal uses vanilla pattern (ISRemoveItemTool):
--   sq:transmitRemoveItemFromSquare(worldObj) -> syncs to all clients
--   sq:removeWorldObject(worldObj)            -> server-side removal
-- =========================================================================

if not isServer() then return end

local LC3K = {}

local TAG_TIME   = "LC3K_T"   -- modData key: hour when first seen on ground
local TAG_PLACED = "LC3K_P"   -- modData key: item was explicitly placed by mod
local CHUNK_SIZE = 10         -- PZ chunk width/height in tiles

-- ---------------------------------------------------------
-- Configuration from SandboxVars (Sandbox Options panel)
-- ---------------------------------------------------------
local function getCfg()
    local sv = SandboxVars.LagCleaner3000 or {}
    local minutes = tonumber(sv.CleanupMinutes) or 1440
    return {
        enabled        = sv.Enabled ~= false,
        cleanupMinutes = minutes,
        cleanupHours   = minutes / 60,
        scanRadius     = tonumber(sv.ScanRadius)   or 50,
        maxZ           = tonumber(sv.MaxZLevel)     or 3,
        logEnabled     = sv.LogCleanups ~= false,
    }
end

-- ---------------------------------------------------------
-- Safely remove a world inventory object from a square
-- Follows vanilla pattern from ISRemoveItemTool:
--   sq:transmitRemoveItemFromSquare(worldObj) -> broadcast to clients
--   sq:removeWorldObject(worldObj)            -> remove from square
--   item:setWorldItem(nil)                    -> clear back-reference
-- ---------------------------------------------------------
local function removeWorldItem(sq, worldObj, item)
    -- Step 1: broadcast removal to all connected clients
    sq:transmitRemoveItemFromSquare(worldObj)

    -- Step 2: remove the IsoWorldInventoryObject from the square
    sq:removeWorldObject(worldObj)

    -- Step 3: clear back-reference on the InventoryItem
    if item and item.setWorldItem then
        item:setWorldItem(nil)
    end

    return true
end

-- ---------------------------------------------------------
-- Process one grid square: tag new ground items, remove expired
-- AGGRESSIVE: every IsoWorldInventoryObject gets processed
-- ---------------------------------------------------------
local function processSquare(sq, now, maxAge)
    local objs = sq:getObjects()
    if not objs then return 0 end

    local size = objs:size()
    if size == 0 then return 0 end

    local removed = 0

    -- Iterate backwards: removals don't shift remaining indices
    for i = size - 1, 0, -1 do
        local obj = objs:get(i)

        -- IsoWorldInventoryObject = loose item on the ground
        -- This is the ONLY class for dropped/spawned ground items
        -- Placed objects (furniture, barricades, moveables) are different classes
        if instanceof(obj, "IsoWorldInventoryObject") then
            -- Skip items placed by players (vanilla flag from ISDropWorldItemAction)
            -- isIgnoreRemoveSandbox() = true means the player intentionally placed this item
            if obj.isIgnoreRemoveSandbox and obj:isIgnoreRemoveSandbox() then
                -- Intentionally placed item, never clean
            else
                local item = obj:getItem()
                if item then
                    local md = item:getModData()

                    -- Skip items explicitly marked as "placed" by another mod
                    if not md[TAG_PLACED] then
                        local t = md[TAG_TIME]

                        if not t then
                            -- First detection: stamp current world-age hour
                            md[TAG_TIME] = now
                        else
                            t = tonumber(t) or now
                            if (now - t) >= maxAge then
                                removeWorldItem(sq, obj, item)
                                removed = removed + 1
                            end
                        end
                    end
                end
            end
        end
    end

    return removed
end

-- ---------------------------------------------------------
-- Main scan: iterate loaded chunks around each online player
-- ---------------------------------------------------------
function LC3K.scan()
    local cfg = getCfg()
    if not cfg.enabled then return end

    local cell = getCell()
    if not cell then return end

    local players = getOnlinePlayers()
    if not players or players:size() == 0 then return end

    local now         = getGameTime():getWorldAgeHours()
    local maxAge      = cfg.cleanupHours
    local chunkRadius = math.ceil(cfg.scanRadius / CHUNK_SIZE)
    local seen        = {}
    local totalClean  = 0

    for p = 0, players:size() - 1 do
        local pl  = players:get(p)
        local pcx = math.floor(pl:getX() / CHUNK_SIZE)
        local pcy = math.floor(pl:getY() / CHUNK_SIZE)

        for cx = pcx - chunkRadius, pcx + chunkRadius do
            for cy = pcy - chunkRadius, pcy + chunkRadius do
                local key = cx * 131072 + cy

                if not seen[key] then
                    seen[key] = true

                    local bx = cx * CHUNK_SIZE
                    local by = cy * CHUNK_SIZE

                    for z = 0, cfg.maxZ do
                        for lx = 0, CHUNK_SIZE - 1 do
                            for ly = 0, CHUNK_SIZE - 1 do
                                local sq = cell:getGridSquare(bx + lx, by + ly, z)
                                if sq then
                                    totalClean = totalClean
                                        + processSquare(sq, now, maxAge)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if totalClean > 0 and cfg.logEnabled then
        print("[LagCleaner3000] Cleaned " .. tostring(totalClean)
            .. " ground items (age > " .. tostring(cfg.cleanupMinutes) .. "min)")
    end
end

-- ---------------------------------------------------------
-- Stamp items immediately when a player drops them
-- This guarantees the timer starts at the exact drop moment
-- ---------------------------------------------------------
local function onPlayerDropItem(player, item)
    if not item then return end
    local md = item:getModData()
    if not md[TAG_TIME] then
        md[TAG_TIME] = getGameTime():getWorldAgeHours()
    end
end

-- ---------------------------------------------------------
-- Admin command: force an immediate cleanup scan
-- ---------------------------------------------------------
local function onClientCommand(module, command, player, args)
    if module ~= "LagCleaner3000" then return end

    if command == "forceScan" then
        if player:getAccessLevel() ~= "" then
            LC3K.scan()
            sendServerCommand(player, "LagCleaner3000", "scanDone", {})
            print("[LagCleaner3000] Force scan by " .. tostring(player:getUsername()))
        end
    end
end

-- ---------------------------------------------------------
-- Register server events
-- ---------------------------------------------------------
Events.EveryOneMinute.Add(LC3K.scan)
Events.OnClientCommand.Add(onClientCommand)

-- Hook player item drops to stamp them immediately
if Events.OnPlayerDropItem then
    Events.OnPlayerDropItem.Add(onPlayerDropItem)
end

local cfg = getCfg()
print("[LagCleaner3000] v2.3 loaded | Enabled: " .. tostring(cfg.enabled)
    .. " | Cleanup: " .. tostring(cfg.cleanupMinutes) .. "min"
    .. " | Radius: " .. tostring(cfg.scanRadius) .. " tiles"
    .. " | Scan: every game minute")
