local TABAS_Iso = require("TABAS_Iso")
local TABAS_GameTimes = require("TABAS_GameTimes")
local TABAS_Sounds = require("TABAS_Sounds")
local TABAS_Utils = require("TABAS_Utils")

local TABAS_ShowerFx = {}
TABAS_ShowerFx.registered = {}
TABAS_ShowerFx.cleanuped = false

----------------------- Values -----------------------

local SHOWER_WATER_NAME = "ShowerWater"
local SHOWER_STEAM_NAME = "ShowerSteam"

local CLEANUP_MISS_LIMIT = 60

local SHOWER_LOOP_SOUND = "tabas_shower_water"
local FRAMES_WATER = 5
local ADVANCE_EVERY_TICKS = 2

local STEAM_START_DELAY_TICKS = 45
local STEAM_SPAWN_INTERVAL_TICKS = 12

local STEAM_ALIVE_TICKS = 320
local STEAM_ALIVE_TICKS_MIN = 120
local STEAM_ALIVE_TICKS_MAX = 240
local STEAM_ALIVE_TICKS_FAST = 100

local STEAM_MAX_PUFFS = 3
local STEAM_MIN_AGE_BEFORE_NEXT = 160

local STEAM_BODY_FADE_IN = 0.010
local STEAM_BODY_FADE_OUT = 0.020

local STEAM_PUFF_FADE_IN = 0.03
local STEAM_PUFF_FADE_OUT = 0.04
local STEAM_PUFF_FADE_OUT_FAST = 0.08

local CLEANUP_RADIUS_TILES = 30
local CLEANUP_PER_TICK = 450
local CLEANUP_DELAY_TICKS = 120


----------------------- Utility -----------------------

local function keyOf(x, y, z)
    return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end

local function getSquareAt(x, y, z)
    local cell = getCell()
    if not cell then return nil end
    return cell:getGridSquare(x, y, z)
end

local function removeShowerFxObj(obj, transmit)
    if not obj then return end
    local sq = obj:getSquare()
    if not sq then return end

    sq:RemoveTileObject(obj)
    if transmit and isClient() then
        sq:transmitRemoveItemFromSquareOnClients(obj)
    end
end

local function isShowerWaterObj(obj)
    if not obj then return false end
    return obj:getName() and obj:getName() == SHOWER_WATER_NAME
end

local function isShowerSteamObj(obj)
    if not obj then return false end
    return obj:getName() and obj:getName() == SHOWER_STEAM_NAME
end

local function getWaterObjectOnSquare(sq)
    if not sq then return end
    local objects = sq:getSpecialObjects()
    for i=0, objects:size()-1 do
        local obj = objects:get(i)
        if obj and obj:getName() and obj:getName() == SHOWER_WATER_NAME then
            return obj
        end
    end
end

local function getSteamObjectOnSquare(sq)
    if not sq then return end
    local objects = sq:getSpecialObjects()
    for i=0, objects:size()-1 do
        local obj = objects:get(i)
        if obj and obj:getName() and obj:getName() == SHOWER_STEAM_NAME then
            return obj
        end
    end
end

local function isHotWater(waterObj)
    if not waterObj then return false end
    local md = waterObj:getModData()
    return md and md.isHotWater == true
end

----------------------- Sound -----------------------

local function stopShowerSound(entry)
    if not entry then return end
    if entry.emitter then
        entry.emitter:stopAll()
    end
    entry.sound = nil
    entry.emitter = nil
    entry.soundOn = false
end

local function ensureShowerSound(entry)
    if not entry or entry.soundOn then return end

    local world = getWorld()
    if not world then return end

    local emitter = world:getFreeEmitter(entry.x + 0.5, entry.y + 0.5, entry.z)
    if not emitter then return end

    entry.sound = TABAS_Sounds.playEmitterSoundLoopedImpl(emitter, SHOWER_LOOP_SOUND)
    entry.emitter = emitter
    entry.soundOn = true
end

----------------------- Sprite -----------------------

local function waterSpriteName(facing, frame0)
    if not frame0 or frame0 < 0 then
        return TABAS_Iso.getSpritesTable("ShowerBlank", "sprite" .. facing)
    else
        local sprites = TABAS_Iso.getSpritesTable("ShowerWater", "sprite" .. facing)
        if sprites and sprites[frame0 + 1] then
            return sprites[frame0 + 1]
        end
    end
    return nil
end

local function steamSpriteName(type, variant) -- variant 1 or 2
    local sprites = TABAS_Iso.getSpritesTable("ShowerSteam", type)
    if sprites and sprites[variant] then
        return sprites[variant]
    end
    return nil
end

----------------------- Steam Puff -----------------------

local function ensureSteamObj(entry, sq)
    if not sq or not entry then return nil end

    -- reuse existing host object if present on entry/square
    if entry.steamObj and entry.steamObj:getSquare() == sq then
        return entry.steamObj
    end

    local existing = getSteamObjectOnSquare(sq)
    if existing then
        if not existing:getAttachedAnimSprite() then
            existing:setAttachedAnimSprite(ArrayList.new())
        end
        entry.steamObj = existing
        return existing
    end

    -- create invisible host object (attached sprites will be drawn on it)
    local spriteName = steamSpriteName("body", ZombRand(1,3))
    local obj = IsoObject.new(getCell(), sq, spriteName)
    obj:setName(SHOWER_STEAM_NAME)
    obj:setAttachedAnimSprite(ArrayList.new())
    sq:AddSpecialObject(obj)

    -- body alpha state init
    obj:setAlphaAndTarget(0)

    entry.steamBodyAlpha = 0

    entry.steamObj = obj
    return obj
end

local function applyInstance(inst, alpha)
    if not inst then return end
    inst:SetAlpha(alpha)
    inst:SetTargetAlpha(alpha)
end

local function spawnSteamPuff(entry, sq, spawnCount)
    if not sq then return end

    local steamObj = ensureSteamObj(entry, sq)
    if not steamObj then return nil end

    local list = steamObj:getAttachedAnimSprite()
    if not list then
        steamObj:setAttachedAnimSprite(ArrayList.new())
        list = steamObj:getAttachedAnimSprite()
    end

    local odd = ((spawnCount or 1) % 2) == 1
    if (entry.facing == "E" or entry.facing == "N") then
        odd = not odd
    end

    local spriteType, variant
    if odd then
        spriteType = "puffL"
        variant = ZombRand(1,5) -- 1-4
    else
        spriteType = "puffR"
        variant = ZombRand(1,5)
    end

    local puff = {
        inst = nil,
        alpha = 0,
        variant = variant,
        age = 0,
        aliveTick = ZombRand(STEAM_ALIVE_TICKS_MIN, STEAM_ALIVE_TICKS_MAX),
        dead = false,
    }

    local spriteName = steamSpriteName(spriteType, puff.variant)
    if not spriteName then return nil end

    local inst = getSprite(spriteName):newInstance()
    puff.inst = inst

    applyInstance(inst, puff.alpha)
    list:add(inst)
    return puff
end

local function updateSteamBody(entry, allowSpawn, dt)
    local steamObj = entry.steamObj
    if not steamObj then return end

    dt = dt or 1

    local alpha = entry.steamBodyAlpha or 0
    if allowSpawn then
        alpha = math.min(1, alpha + (STEAM_BODY_FADE_IN * dt))
    else
        alpha = math.max(0, alpha - (STEAM_BODY_FADE_OUT * dt))
    end
    entry.steamBodyAlpha = alpha

    steamObj:setAlphaAndTarget(alpha)
end

local function updatePuff(entry, puff, doing, dt)
    if not puff or puff.dead then return end
    if not puff.inst then
        puff.dead = true
        return
    end
    dt = dt or 1
    -- alpha
    local alive = doing and puff.aliveTick or STEAM_ALIVE_TICKS_FAST
    puff.age = puff.age + dt
    if puff.age < alive then
        -- fade in
        puff.alpha = math.min(1, puff.alpha + (STEAM_PUFF_FADE_IN * dt))
    else
        -- fade out
        local fadeout = doing and STEAM_PUFF_FADE_OUT or STEAM_PUFF_FADE_OUT_FAST
        puff.alpha = math.max(0, puff.alpha - (fadeout * dt))
        if puff.alpha <= 0.001 then
            local steamObj = entry.steamObj
            local list = steamObj and steamObj:getAttachedAnimSprite() or nil
            if list then
                list:remove(puff.inst)
            end
            puff.inst = nil
            puff.dead = true
            return
        end
    end

    applyInstance(puff.inst, puff.alpha)
end

local function cleanupPuffs(entry)
    local puffs = entry.puffs
    if not puffs then
        entry.puffsAliveCount = 0
        return
    end

    local alive = 0
    for i = #puffs, 1, -1 do
        if puffs[i].dead then
            table.remove(puffs, i)
        else
            alive = alive + 1
        end
    end
    entry.puffsAliveCount = alive
end

----------------------- Main Function -----------------------

local function refreshObject(entry)
    local sq = entry.square or getSquareAt(entry.x, entry.y, entry.z)
    if not sq then
        entry.waterObj = nil
        stopShowerSound(entry)
        return false
    end
    local showerObj = TABAS_Iso.getShowerObjectOnSquare(sq, true)
    if not showerObj then
        entry.showerObj = nil
        stopShowerSound(entry)
    end
    local waterObj = getWaterObjectOnSquare(sq)
    if not waterObj then
        entry.waterObj = nil
        stopShowerSound(entry)
        return false
    end
    entry.showerObj = showerObj
    entry.waterObj = waterObj
    entry.isHotWater = isHotWater(waterObj)
    return sq
end

local function onRemoveRegistered(entry)
    -- remove attached puff instances
    if entry.puffs and entry.steamObj then
        local list = entry.steamObj:getAttachedAnimSprite()
        if list then
            for i = 1, #entry.puffs do
                local puff = entry.puffs[i]
                if puff and puff.inst then
                    list:remove(puff.inst)
                    puff.inst = nil
                end
            end
        end
    end
    entry.puffs = {}
    entry.puffsAliveCount = 0

    if entry.steamObj then
        removeShowerFxObj(entry.steamObj)
        entry.steamObj = nil
    end
end

local function updateShowerFx(entry, dt)
    dt = dt or 1
    -- shower water
    if entry.waterObj ~= nil then
        entry.animTick = (entry.animTick or 0) + dt
        while entry.animTick >= ADVANCE_EVERY_TICKS do
            entry.animTick = entry.animTick - ADVANCE_EVERY_TICKS
            entry.frame = (entry.frame + 1) % FRAMES_WATER   -- 0..4
            local sprite = waterSpriteName(entry.facing, entry.frame)
            if sprite then
                entry.waterObj:setSpriteFromName(sprite)
            end
        end
        ensureShowerSound(entry)
    end

    -- steam puffs
    local allowSpawn = entry.waterObj ~= nil and entry.isHotWater
    local sq = entry.square
    if allowSpawn then
        if not entry.steamIsAllowed then
            entry.steamDelay = STEAM_START_DELAY_TICKS
        end
        entry.steamIsAllowed = true

        if (entry.steamDelay or 0) > 0 then
            entry.steamDelay = math.max(0, (entry.steamDelay or 0) - dt)
            entry.spawnTick = 0
            allowSpawn = false
        end
    else
        entry.steamIsAllowed = false
        entry.steamDelay = 0
    end

    local puffEnabled = TABAS_Utils.ModOptionsValue("EnabledShowerSteamAnim")
    local allowPuff = allowSpawn and puffEnabled

    if not puffEnabled and (entry.puffsAliveCount or 0) > 0 then
        if entry.steamObj then
            local list = entry.steamObj:getAttachedAnimSprite()
            if list and entry.puffs then
                for i = 1, #entry.puffs do
                    local puff = entry.puffs[i]
                    if puff and puff.inst then
                        list:remove(puff.inst)
                        puff.inst = nil
                    end
                end
            end
        end
        entry.puffs = {}
        entry.puffsAliveCount = 0
        entry.spawnTick = 0
    end

    if allowSpawn and sq then
        ensureSteamObj(entry, sq)
    end
    if entry.steamObj then
        updateSteamBody(entry, allowSpawn, dt)
    end

    if allowPuff and sq then
        entry.spawnTick = (entry.spawnTick or 0) + dt
        if entry.spawnTick >= STEAM_SPAWN_INTERVAL_TICKS then
            entry.spawnTick = entry.spawnTick - STEAM_SPAWN_INTERVAL_TICKS

            local alive = (entry.puffsAliveCount or 0)
            local canSpawn = alive < STEAM_MAX_PUFFS

            if canSpawn and alive == 1 and entry.puffs and entry.puffs[1] then
                local p1 = entry.puffs[1]
                if (p1.age or 0) < STEAM_MIN_AGE_BEFORE_NEXT then canSpawn = false end
            end

            if canSpawn then
                entry.steamSpawnCount = (entry.steamSpawnCount or 0) + 1
                local puff = spawnSteamPuff(entry, sq, entry.steamSpawnCount)
                if puff then
                    table.insert(entry.puffs, puff)
                    entry.puffsAliveCount = (entry.puffsAliveCount or 0) + 1
                end
            end
        end
    end

    if entry.puffs then
        for i=1, #entry.puffs do
            updatePuff(entry, entry.puffs[i], allowPuff, dt)
        end
    end
    cleanupPuffs(entry)
end

----------------------- Register -----------------------

local function tickRegistry()
    local dt = TABAS_GameTimes.getMultiplier() or 1
    -- dt = math.min(dt, 10)
    for k, entry in pairs(TABAS_ShowerFx.registered) do
        refreshObject(entry)
        if entry.showerObj == nil and entry.waterObj ~= nil then
            entry.noBodyTicks = (entry.noBodyTicks or 0) + 1
            if entry.noBodyTicks > 60 then
                entry.waterObj = nil
            end
        else
            entry.noBodyTicks = 0
        end

        local exist = (entry.waterObj ~= nil) or (entry.puffsAliveCount > 0)

        if exist then
            entry.missingTicks = 0
        else
            entry.missingTicks = (entry.missingTicks or 0) + 1
        end

        updateShowerFx(entry, dt)

        if (entry.missingTicks or 0) >= CLEANUP_MISS_LIMIT then
            local canRemove = (entry.puffsAliveCount or 0) <= 0
            if canRemove then
                stopShowerSound(entry)
                onRemoveRegistered(entry)
                TABAS_ShowerFx.registered[k] = nil
            end
        end
    end
end

local function tryRegisterFromSquare(sq)
    if not sq then return end

    local showerObj = TABAS_Iso.getShowerObjectOnSquare(sq, true)
    local waterObj = getWaterObjectOnSquare(sq)
    -- local steamObj = getSteamObjectOnSquare(sq)

    if not waterObj then
        return
    end
    local facing = TABAS_Iso.getObjectFacing(showerObj) or TABAS_Iso.getObjectFacing(waterObj) or "S"

    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local key = keyOf(x,y,z)
    local entry = TABAS_ShowerFx.registered[key]
    if not entry then
        entry = {
            x = x, y = y, z = z,
            square = sq,
            key = key,
            showerObj = showerObj,
            waterObj = waterObj,
            facing = facing,
            isHotWater = isHotWater(waterObj),
            missingTicks = 0,
            animTick = 0,
            frame = 0,
            soundOn = false,
            emitter = nil,

            steamObj = nil,
            puffs = {},
            puffsAliveCount = 0,
            steamSpawnCount = 0,
            spawnTick = 0
        }

        TABAS_ShowerFx.registered[key] = entry
        return
    end

    -- refresh registered
    entry.square = sq
    entry.showerObj = showerObj
    entry.waterObj  = waterObj
    entry.facing = facing
    entry.isHotWater = isHotWater(waterObj)
    entry.missingTicks = 0
end

local function tryRegisterFromObject(object)
    if not object then return end
    if not isShowerWaterObj(object) then return end

    local sq = object:getSquare()
    if sq then
        tryRegisterFromSquare(sq)
    end
end


local function onObjectAboutToBeRemoved(object)
    if not object or not TABAS_Iso.isShowerObject(object, true) then return end
    local sq = object:getSquare()
    if not sq then return end

    local key = keyOf(sq:getX(), sq:getY(), sq:getZ())
    local entry = TABAS_ShowerFx.registered[key]
    if entry then
        stopShowerSound(entry)
        entry.showerObj = nil
        entry.waterObj = nil
        entry.isHotWater = false
    end
end

local function cleanupNearbySteamFx(player, radiusTiles, perTick)
    if not player then return end
    local psq = player:getSquare()
    if not psq then return end

    radiusTiles = radiusTiles or CLEANUP_RADIUS_TILES
    perTick = perTick or CLEANUP_PER_TICK

    local cx, cy, cz = psq:getX(), psq:getY(), psq:getZ()
    local minX, maxX = cx - radiusTiles, cx + radiusTiles
    local minY, maxY = cy - radiusTiles, cy + radiusTiles

    -- build queue
    local queue = {}
    for y = minY, maxY do
        for x = minX, maxX do
            queue[#queue+1] = { x = x, y = y }
        end
    end

    local idx = 1
    local function tickFxRemove()
        local cell = getCell()
        if not cell then
            Events.OnTick.Remove(tickFxRemove)
            return
        end

        local n = 0
        while idx <= #queue and n < perTick do
            local q = queue[idx]
            idx = idx + 1
            n = n + 1

            local sq = cell:getGridSquare(q.x, q.y, cz)
            if sq then
                local objects = sq:getSpecialObjects()
                for i = objects:size() - 1, 0, -1 do
                    local obj = objects:get(i)
                    if isShowerSteamObj(obj) then
                        removeShowerFxObj(obj)
                    elseif isShowerWaterObj(obj) then
                        removeShowerFxObj(obj, true)
                    end
                end
            end
        end

        if idx > #queue then
            Events.OnTick.Remove(tickFxRemove)
        end
    end

    Events.OnTick.Add(tickFxRemove)
end

local function scheduleCleanupOnLoad(playerIndex, player)
    if TABAS_ShowerFx.cleanuped then return end
    TABAS_ShowerFx.cleanuped = true

    local delay = CLEANUP_DELAY_TICKS
    local t = 0

    local function cleanupWaiter()
        t = t + 1
        if t >= delay then
            Events.OnTick.Remove(cleanupWaiter)
            cleanupNearbySteamFx(player, CLEANUP_RADIUS_TILES, CLEANUP_PER_TICK)
        end
    end

    Events.OnTick.Add(cleanupWaiter)
end


local function cleanupObjects(objects, square)
    for i=1, #objects do
        local obj = objects[i]
        if isShowerSteamObj(obj) then
            removeShowerFxObj(obj)
        elseif isShowerWaterObj(obj) then
            removeShowerFxObj(obj, true)
        end
    end
end

-- Just in case the game crashes.
local function showerFxCleanupMenu(player, context, worldObjects, test)
    if not worldObjects then return end

    local remains = {}
    local sq
    for i=1, #worldObjects do
        local obj = worldObjects[i]
        if obj then
            sq = worldObjects[i]:getSquare()
            if sq then
                local x, y, z = sq:getX(), sq:getY(), sq:getZ()
                local key = keyOf(x,y,z)
                local entry = TABAS_ShowerFx.registered[key]
                if entry then return end

                if (isShowerWaterObj(obj) or isShowerSteamObj(obj)) then
                    remains[i] = obj
                end
            end
        end
    end

    if #remains > 0 then
        context:addOptionOnTop(getText("Cleaning up shower Fx"), remains, cleanupObjects, sq)
    end
end


----------------------- Events -----------------------

Events.OnTick.Add(tickRegistry)
Events.OnObjectAdded.Add(tryRegisterFromObject)
Events.OnObjectAboutToBeRemoved.Add(onObjectAboutToBeRemoved)
Events.OnCreatePlayer.Add(scheduleCleanupOnLoad)
Events.OnPlayerDeath.Add(scheduleCleanupOnLoad)
-- Events.OnFillWorldObjectContextMenu.Add(showerFxCleanupMenu)
