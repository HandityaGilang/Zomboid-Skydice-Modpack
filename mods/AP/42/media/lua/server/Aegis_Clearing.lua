-- Area clearing: stateless, checks fresh on every call whether the chosen
-- rectangle still has vegetation. If so, this pass removes ONLY vegetation
-- (trees/bushes/grass). If the area is already vegetation free (e.g. the same
-- rectangle confirmed a second time), the pass removes EVERYTHING except the
-- floor. No stored "already handled" state needed, the result depends only
-- on the current world state.
-- Runs sliced over OnTick, each object removal triggers synchronous
-- recalc/pathfinding/room updates server side (bytecode verified,
-- zombie.iso.IsoGridSquare.transmitRemoveItemFromSquare), so a rectangle
-- with hundreds of objects must not run in one go.
--
-- Each object is captured before removal (same principle as Aegis_Backup.lua,
-- but as in-memory Lua tables instead of pipe text, no file persistence
-- needed. "Undo last change" is meant as an immediate correction, not a
-- long term backup). Per admin ONLY the most recent clearing is kept (no
-- history, overwrites itself), once undone the record is cleared.
-- Trees (IsoTree) and some device classes (generator, corpse, curtain,
-- stove etc.) can never be rebuilt cleanly, same limit as Aegis_Backup.lua,
-- documented in its file header. These are only counted as "not restorable",
-- no rebuild attempt.
if isClient() then return end

require "Aegis_Roles"
require "Aegis_Log"
require "Aegis_Moderation"

local BUDGET = 24        -- tiles per tick while clearing
local REST_BUDGET = 16   -- tiles per tick while undoing
local MAX_EDGE = 24

local function sendToClient(player, command, args)
    if isServer() then
        sendServerCommand(player, AegisShared.MODULE, command, args)
    else
        triggerEvent("OnServerCommand", AegisShared.MODULE, command, args)
    end
end

local function denyAccess(player)
    sendToClient(player, "denied", { area = "tools" })
end

local function hasVegetation(sq)
    local objects = sq:getObjects()
    for i = 0, objects:size() - 1 do
        if AegisShared.isVegetation(objects:get(i)) then return true end
    end
    return false
end

-- ---------- Capture: object to table (modeled on Aegis_Backup.lua, ----------
-- ---------- no text serialization here, stays in memory only)        ----------

-- same limit as Aegis_Backup.lua: these classes lose their logic as a
-- bare IsoObject, no rebuild attempt
local NOT_BUILDABLE = {
    "IsoTree", "IsoGenerator", "IsoMannequin", "IsoDeadBody", "IsoCurtain",
    "IsoStove", "IsoFireplace", "IsoBarbecue", "IsoTelevision", "IsoRadio",
    "IsoWaveSignal", "IsoLightSwitch", "IsoCombinationWasherDryer",
    "IsoClothingDryer", "IsoClothingWasher", "IsoCompost",
}

local function notRestorable(obj)
    if instanceof(obj, "IsoWorldInventoryObject") then return true end
    if instanceof(obj, "IsoBarricade") then return true end
    for _, cls in ipairs(NOT_BUILDABLE) do
        if instanceof(obj, cls) then return true end
    end
    local hasFluid = false
    pcall(function() hasFluid = obj:hasFluid() end)
    return hasFluid
end

local function spriteOf(obj)
    local name = ""
    pcall(function() name = obj:getSpriteName() or "" end)
    return name
end

local function northOf(obj)
    -- IsoObject has no getNorth, only doors, windows, window frames and
    -- thumpables do; calling it on anything else throws through pcall
    local hasNorth = false
    pcall(function()
        hasNorth = instanceof(obj, "IsoDoor") or instanceof(obj, "IsoWindow")
            or instanceof(obj, "IsoWindowFrame") or instanceof(obj, "IsoThumpable")
    end)
    if not hasNorth then return false end
    local north = false
    pcall(function() north = obj:getNorth() == true end)
    return north
end

-- one container level deep (compromise: covers the vast majority,
-- bags inside bags inside furniture are skipped on undo)
local function captureContainers(obj)
    local list = {}
    local count = 0
    pcall(function() count = obj:getContainerCount() end)
    for ci = 0, count - 1 do
        local cont = nil
        pcall(function() cont = obj:getContainerByIndex(ci) end)
        if cont then
            local items = {}
            pcall(function()
                local is = cont:getItems()
                for i = 0, is:size() - 1 do
                    local it = is:get(i)
                    if it then
                        local e = { full = it:getFullType() }
                        pcall(function() e.cond = it:getCondition() end)
                        pcall(function() e.condMax = it:getConditionMax() end)
                        pcall(function() e.uses = it:getCurrentUses() end)
                        if instanceof(it, "DrainableComboItem") then
                            pcall(function() e.usesFloat = it:getCurrentUsesFloat() end)
                        end
                        table.insert(items, e)
                    end
                end
            end)
            table.insert(list, { idx = ci, items = items })
        end
    end
    return list
end

local function captureObject(obj, floor)
    if obj == floor then
        return { kind = "F", sprite = spriteOf(obj) }
    end
    if notRestorable(obj) then
        return nil
    end
    if instanceof(obj, "IsoDoor") then
        local e = { kind = "D", sprite = spriteOf(obj), north = northOf(obj) }
        pcall(function()
            e.open = obj:IsOpen()
            e.locked = obj:isLocked()
            e.hp = obj:getHealth()
            e.maxhp = obj:getMaxHealth()
        end)
        return e
    end
    if instanceof(obj, "IsoWindow") then
        local e = { kind = "W", sprite = spriteOf(obj), north = northOf(obj) }
        pcall(function()
            e.smashed = obj:isSmashed()
            e.locked = obj:isLocked()
            e.open = obj:IsOpen()
        end)
        return e
    end
    if instanceof(obj, "IsoWindowFrame") then
        return { kind = "WF", sprite = spriteOf(obj), north = northOf(obj) }
    end
    if instanceof(obj, "IsoThumpable") then
        local e = { kind = "T", sprite = spriteOf(obj), north = northOf(obj), container = captureContainers(obj) }
        pcall(function()
            e.name = obj:getName()
            e.hp = obj:getHealth()
            e.maxhp = obj:getMaxHealth()
        end)
        return e
    end
    local sprite = spriteOf(obj)
    if sprite == "" then return nil end
    return { kind = "O", sprite = sprite, container = captureContainers(obj) }
end

-- removes only vegetation; false is safe, vegetation is never multi-tile
-- (bytecode verified: IsoTree/bush sprites use no SpriteConfig grids)
local function removeVegetation(sq, x, y, z, job)
    local objects = sq:getObjects()
    local n = 0
    local block = nil
    for i = objects:size() - 1, 0, -1 do
        local obj = objects:get(i)
        if obj and AegisShared.isVegetation(obj) then
            local ok, captured = pcall(captureObject, obj, nil)
            if ok and captured then
                block = block or { x = x, y = y, z = z, objects = {} }
                table.insert(block.objects, captured)
            else
                job.notRestorable = job.notRestorable + 1
            end
            local ok2 = pcall(function() sq:transmitRemoveItemFromSquare(obj, false) end)
            if ok2 then n = n + 1 end
        end
    end
    if block then table.insert(job.blocks, block) end
    return n
end

-- transmitRemoveItemFromSquare returns -1 and removes NOTHING when the
-- object carries a sprite grid whose partner tiles are missing, and it
-- throws nothing while doing so. Trusting pcall alone counted those as
-- removed and left the piece standing. Orphans like that can only go
-- without the multi tile flag, and that is safe precisely because the
-- partners are already gone
local function removeOne(sq, obj)
    local removed = -1
    local ok = pcall(function() removed = sq:transmitRemoveItemFromSquare(obj, true) end)
    if ok and (tonumber(removed) or -1) >= 0 then return true end
    removed = -1
    ok = pcall(function() removed = sq:transmitRemoveItemFromSquare(obj, false) end)
    return ok and (tonumber(removed) or -1) >= 0
end

-- a floor the build brush laid down is fair game: it replaced whatever was
-- there, so protecting it would leave the admin no way back. Map floors
-- stay protected, removing those would tear holes into the world
local function ownFloor(obj)
    local stamped = false
    pcall(function()
        stamped = obj:hasModData() and obj:getModData().aegisBuild ~= nil
    end)
    return stamped
end

-- removes everything except the floor; true so multi-tile objects (large
-- doors/furniture) clean up their neighbor tiles instead of leaving
-- remnants (bytecode: the flag only applies if the object really is
-- multi-tile, otherwise harmless). Same "obj ~= floor" guard as
-- Aegis_Backup.lua:restoreSquare keeps existing floors safe automatically
local function removeAll(sq, x, y, z, job)
    local objects = sq:getObjects()
    local floor = sq:getFloor()
    -- keep passing the real floor to captureObject, it identifies the floor
    -- by that comparison and stores it as one; only the removal guard drops
    local keep = floor
    if keep and ownFloor(keep) then keep = nil end
    local n = 0
    local block = nil
    for i = objects:size() - 1, 0, -1 do
        local obj = objects:get(i)
        if obj and obj ~= keep then
            local ok, captured = pcall(captureObject, obj, floor)
            if ok and captured then
                block = block or { x = x, y = y, z = z, objects = {} }
                table.insert(block.objects, captured)
            else
                job.notRestorable = job.notRestorable + 1
            end
            if removeOne(sq, obj) then n = n + 1 else job.notRemoved = job.notRemoved + 1 end
        end
    end
    if block then table.insert(job.blocks, block) end
    return n
end

-- ---------- Restore: table to object (modeled on buildObject) ----------
local function buildItem(def)
    local it = nil
    pcall(function() it = instanceItem(def.full) end)
    if not it then return nil end
    if def.condMax then pcall(function() it:setConditionMax(def.condMax) end) end
    if def.cond then pcall(function() it:setCondition(def.cond) end) end
    if def.usesFloat then
        pcall(function() it:setCurrentUsesFloat(def.usesFloat) end)
    elseif def.uses then
        pcall(function() it:setCurrentUses(def.uses) end)
    end
    return it
end

local function restoreContainers(obj, list)
    if not list then return end
    for _, c in ipairs(list) do
        local cont = nil
        pcall(function() cont = obj:getContainerByIndex(c.idx) end)
        if cont then
            for _, def in ipairs(c.items) do
                local it = buildItem(def)
                if it then
                    pcall(function()
                        cont:AddItem(it)
                        sendAddItemToContainer(cont, it)
                    end)
                end
            end
        end
    end
end

local function buildObject(cell, sq, e)
    local sprite = e.sprite
    if not sprite or sprite == "" then return nil end
    local obj = nil
    if e.kind == "T" then
        obj = IsoThumpable.new(cell, sq, sprite, e.north == true, {})
        if e.name and e.name ~= "" then pcall(function() obj:setName(e.name) end) end
        if e.maxhp then pcall(function() obj:setMaxHealth(e.maxhp) end) end
        if e.hp then pcall(function() obj:setHealth(e.hp) end) end
    elseif e.kind == "D" then
        obj = IsoDoor.new(cell, sq, sprite, e.north == true)
        pcall(function()
            if e.open ~= nil then obj:setOpen(e.open) end
            if e.locked ~= nil then obj:setLocked(e.locked) end
            if e.hp then obj:setHealth(e.hp) end
        end)
    elseif e.kind == "W" then
        obj = IsoWindow.new(cell, sq, getSprite(sprite), e.north == true)
        pcall(function()
            if e.smashed ~= nil then obj:setSmashed(e.smashed) end
            if e.locked ~= nil then obj:setIsLocked(e.locked) end
        end)
    elseif e.kind == "WF" then
        obj = IsoWindowFrame.new(cell, sq, getSprite(sprite), e.north == true)
    elseif e.kind == "O" then
        obj = IsoObject.new(cell, sq, sprite)
    end
    if not obj then return nil end
    if e.kind == "O" then
        sq:transmitAddObjectToSquare(obj, sq:getObjects():size())
    else
        sq:AddSpecialObject(obj, sq:getObjects():size())
        pcall(function() obj:transmitCompleteItemToClients() end)
        if e.kind == "D" or e.kind == "W" then
            pcall(function() obj:syncIsoObject(false, 0, nil, nil) end)
        end
        triggerEvent("OnObjectAdded", obj)
    end
    restoreContainers(obj, e.container)
    return obj
end

local function restoreBlock(job, block)
    local sq = getSquare(block.x, block.y, block.z)
    if not sq then
        job.notLoaded = job.notLoaded + 1
        return
    end
    local cell = getCell()
    for _, e in ipairs(block.objects) do
        if e.kind == "F" then
            if sq:getFloor() == nil and e.sprite ~= "" then
                pcall(function()
                    local newObj = IsoObject.new(cell, sq, e.sprite)
                    sq:transmitAddObjectToSquare(newObj, 0)
                end)
            end
        else
            local ok = pcall(buildObject, cell, sq, e)
            if ok then job.restored = job.restored + 1 end
        end
    end
    pcall(function() sq:RecalcProperties() end)
end

-- per admin only the most recent clearing, no history
local lastClearing = {}

-- ---------- Job handling: one clearing at a time, in slices ----------
local queue = {}
local active = nil

local function step(job)
    local budget = BUDGET
    while job.pos <= #job.columns and budget > 0 do
        local col = job.columns[job.pos]
        job.pos = job.pos + 1
        budget = budget - 1
        local sq = getSquare(col.x, col.y, job.z)
        if sq then
            if job.mode == "vegetation" then
                job.removed = job.removed + removeVegetation(sq, col.x, col.y, job.z, job)
            else
                job.removed = job.removed + removeAll(sq, col.x, col.y, job.z, job)
            end
            job.tiles = job.tiles + 1
        else
            job.notLoaded = job.notLoaded + 1
        end
    end
    if job.pos > #job.columns then
        local text = string.format("Area cleared (%s, %dx%d at %d,%d,%d): %d tiles, %d objects removed, %d not loaded, %d not restorable, %d refused by engine",
            job.mode, job.w, job.h, job.x, job.y, job.z, job.tiles, job.removed, job.notLoaded, job.notRestorable, job.notRemoved)
        AegisLog.write("Actions", job.adminName, "Clearing", text)
        -- remember as most recent clearing for undo, even if nothing was
        -- captured (undo is then simply a no-op)
        lastClearing[job.adminName] = {
            time = AegisShared.realTime(), mode = job.mode,
            x = job.x, y = job.y, z = job.z, w = job.w, h = job.h,
            blocks = job.blocks, notRestorable = job.notRestorable,
        }
        if job.player then
            pcall(function()
                sendToClient(job.player, "clearingDone", {
                    mode = job.mode, tiles = job.tiles, removed = job.removed,
                    notLoaded = job.notLoaded, notRestorable = job.notRestorable,
                })
            end)
        end
        return true
    end
    return false
end

local restoreQueue = {}
local restoreActive = nil

local function restoreStep(job)
    local budget = REST_BUDGET
    while job.pos <= #job.blocks and budget > 0 do
        local block = job.blocks[job.pos]
        job.pos = job.pos + 1
        budget = budget - 1
        pcall(restoreBlock, job, block)
    end
    if job.pos > #job.blocks then
        local text = string.format("Clearing undone (%dx%d at %d,%d,%d): %d objects restored, %d not loaded",
            job.w, job.h, job.x, job.y, job.z, job.restored, job.notLoaded)
        AegisLog.write("Actions", job.adminName, "Clearing", text)
        if job.player then
            pcall(function()
                sendToClient(job.player, "clearingUndoDone", {
                    restored = job.restored, notLoaded = job.notLoaded,
                })
            end)
        end
        return true
    end
    return false
end

Events.OnTick.Add(function()
    if not active then
        if #queue > 0 then active = table.remove(queue, 1) end
    end
    if active then
        local ok, finished = pcall(step, active)
        if not ok then
            print("[Aegis] Clearing: step failed: " .. tostring(finished))
            active = nil
        elseif finished then
            active = nil
        end
    end

    if not restoreActive then
        if #restoreQueue > 0 then restoreActive = table.remove(restoreQueue, 1) end
    end
    if restoreActive then
        local ok, finished = pcall(restoreStep, restoreActive)
        if not ok then
            print("[Aegis] Clearing undo: step failed: " .. tostring(finished))
            restoreActive = nil
        elseif finished then
            restoreActive = nil
        end
    end
end)

local Commands = {}

Commands.clearing = function(player, args)
    if not AegisRoles.canArea(player, "tools") then denyAccess(player) return end
    if not args then return end
    local x = math.floor(tonumber(args.x) or 0)
    local y = math.floor(tonumber(args.y) or 0)
    local z = math.floor(tonumber(args.z) or 0)
    local w = math.floor(tonumber(args.w) or 0)
    local h = math.floor(tonumber(args.h) or 0)
    if w < 1 or h < 1 or w > MAX_EDGE or h > MAX_EDGE then return end
    if #queue >= 3 then
        -- no spam from rapid repeat confirms, but the client has to know
        -- (modeled on Aegis_Backup.lua: sendToClient with ok=false/reason)
        sendToClient(player, "clearingStart", { ok = false, reason = "full" })
        return
    end

    -- decide the mode upfront over the WHOLE area: if vegetation remains
    -- anywhere, this pass clears ONLY vegetation, no matter how many tiles
    -- are already empty. Read only (no removal), fine to run synchronously
    -- at max 24x24=576 tiles; bails out as soon as the first vegetation
    -- is found
    local mode = "all"
    for tx = x, x + w - 1 do
        for ty = y, y + h - 1 do
            local sq = getSquare(tx, ty, z)
            if sq and hasVegetation(sq) then
                mode = "vegetation"
                break
            end
        end
        if mode == "vegetation" then break end
    end

    local columns = {}
    for tx = x, x + w - 1 do
        for ty = y, y + h - 1 do
            table.insert(columns, { x = tx, y = ty })
        end
    end

    table.insert(queue, {
        columns = columns, pos = 1, z = z, x = x, y = y, w = w, h = h,
        mode = mode, tiles = 0, removed = 0, notLoaded = 0,
        notRestorable = 0, notRemoved = 0, blocks = {},
        adminName = player:getUsername(), player = player,
    })
end

-- undoes ONLY this admin's most recent clearing, once. The record is
-- cleared afterwards, no repeat undo possible
Commands.clearingUndo = function(player, args)
    if not AegisRoles.canArea(player, "tools") then denyAccess(player) return end
    local admin = player:getUsername()
    local j = lastClearing[admin]
    if not j then
        sendToClient(player, "clearingUndoDone", { none = true })
        return
    end
    lastClearing[admin] = nil
    if #j.blocks == 0 then
        sendToClient(player, "clearingUndoDone", { restored = 0, notLoaded = 0 })
        return
    end
    table.insert(restoreQueue, {
        blocks = j.blocks, pos = 1, z = j.z, x = j.x, y = j.y, w = j.w, h = j.h,
        restored = 0, notLoaded = 0,
        adminName = admin, player = player,
    })
end

local function onClientCommand(module, command, player, args)
    if module ~= AegisShared.MODULE then return end
    -- suspended admins may not use any Aegis area
    if AegisModeration.isSuspended(player) then return end
    if Commands[command] then Commands[command](player, args) end
end

Events.OnClientCommand.Add(onClientCommand)
