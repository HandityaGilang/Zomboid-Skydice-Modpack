if isServer() and not isClient() then return end

DCS_ObjectOverlay = DCS_ObjectOverlay or {}
local M = DCS_ObjectOverlay

local seen = {}
local activePins = {}
local texCache = {}
local badTex = {}
local traderVisited = {}

local function overlayPathFor(objType)
    local cfgs = DCS_Challenges and DCS_Challenges.ObjectSprites
    local cfg = cfgs and objType and cfgs[objType]
    return cfg and cfg.overlay
end

local function loadTex(path)
    if not path then return nil end
    if badTex[path] then return nil end
    local t = texCache[path]
    if t ~= nil then return t end
    t = getTexture(path)
    if not t then
        badTex[path] = true
        print("[DCS_OBJ] overlay texture '" .. tostring(path) .. "' could not be loaded "
            .. "— check the path and that it is packed.")
        return nil
    end
    texCache[path] = t
    return t
end

local function isChallengeActive(chId)
    if traderVisited[chId] then return false end
    if DCS_Sync and DCS_Sync.isCompleted then
        return not DCS_Sync.isCompleted(chId)
    end
    return true
end

local TRADER_MATCH_R = 30
local PIN_VISIBLE_R = 5

local function isCurrentObject(otype, chId, side, sq)
    local S = DCS_Sync and DCS_Sync.State
    if not S then return true end
    if otype == "trader" then
        local tl = S.traderLocations
        local loc = tl and side and tl[side]
        if not loc or not loc.x or not loc.y or not sq then return false end
        return math.abs(sq:getX() - loc.x) <= TRADER_MATCH_R
           and math.abs(sq:getY() - loc.y) <= TRADER_MATCH_R
    end
    local ids = S.challengeIDs
    if not ids then return true end
    for _, id in ipairs(ids) do
        if id == chId then return true end
    end
    return false
end

function M.markTraderVisited(chId)
    if not chId then return end
    traderVisited[chId] = true
    local obj = seen[chId]
    if obj then M.applyOverlay(obj) end
end

function M.applyOverlay(obj)
    if not obj then return end
    local md = obj:getModData()
    if not md or not md.IsDCSObject then return end
    local chId = md.DCSChallengeId
    if not chId then return end

    local path = overlayPathFor(md.DCSObjectType)
    if not path then return end

    seen[chId] = obj

    local sq = obj:getSquare()
    local otype = md.DCSObjectType
    local side = md.DCSObjectSide

    if isChallengeActive(chId) and isCurrentObject(otype, chId, side, sq) then
        local tex = loadTex(path)
        if tex then
            activePins[chId] = { obj = obj, tex = tex, otype = otype, side = side, chId = chId }
        end
    else
        activePins[chId] = nil
    end
end

function M.refreshAll()
    for chId, obj in pairs(seen) do
        local sq = obj:getSquare()
        if sq then
            local md = obj:getModData()
            local otype = md and md.DCSObjectType
            local side = md and md.DCSObjectSide
            if md and md.IsDCSObject and isCurrentObject(otype, chId, side, sq) then
                M.applyOverlay(obj)
            else
                seen[chId] = nil
                activePins[chId] = nil
            end
        else
            seen[chId] = nil
            activePins[chId] = nil
        end
    end
end

local PIN_W, PIN_H = 128, 256
local PIN_NUDGE_Y = 64

local function hasActivePins()
    for _ in pairs(activePins) do return true end
    return false
end

local function onPostRender()
    if not (DCS_Config and DCS_Config.USE_OBJECTS) then return end
    if not hasActivePins() then return end
    local player = getSpecificPlayer(0)
    if not player then return end
    local pz = math.floor(player:getZ() + 0.5)
    local ppx, ppy = player:getX(), player:getY()
    local w, h = PIN_W, PIN_H

    for chId, pin in pairs(activePins) do
        local obj = pin.obj
        local tex = pin.tex
        local sq = obj:getSquare()
        if sq and tex and not isCurrentObject(pin.otype, pin.chId, pin.side, sq) then
            activePins[chId] = nil
        elseif sq and tex then
            local ox, oy, oz = sq:getX(), sq:getY(), sq:getZ()
            local withinRange = math.abs(ox - ppx) <= PIN_VISIBLE_R and math.abs(oy - ppy) <= PIN_VISIBLE_R
            if withinRange and math.floor(oz + 0.5) == pz then
                local visible = sq:isCouldSee(0)
                if visible then
                    local px = IsoUtils.XToScreenExact(ox, oy, oz, 0) - w / 2
                    local py = IsoUtils.YToScreenExact(ox, oy, oz, 0) - h + PIN_NUDGE_Y
                    tex:render(px, py, w, h)
                end
            end
        end
    end
end
Events.OnPostRender.Add(onPostRender)

local function onLoadGridsquare(square)
    if not (DCS_Config and DCS_Config.USE_OBJECTS) then return end
    if not square then return end
    local objs = square:getObjects()
    if not objs then return end
    local n = objs:size()
    if n == 0 then return end
    for i = 0, n - 1 do
        local o = objs:get(i)
        if o then
            local md = o:getModData()
            if md and md.IsDCSObject then
                M.applyOverlay(o)
            end
        end
    end
end
Events.LoadGridsquare.Add(onLoadGridsquare)

local SCAN_INTERVAL = 120
local SCAN_RADIUS = 12
local scanTick = 0
local function onTickScan()
    if not (DCS_Config and DCS_Config.USE_OBJECTS) then return end
    scanTick = scanTick + 1
    if scanTick < SCAN_INTERVAL then return end
    scanTick = 0
    local player = getSpecificPlayer(0)
    if not player then return end
    local cell = getCell and getCell() or nil
    if not cell then return end
    local px, py, pz = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
    for dx = -SCAN_RADIUS, SCAN_RADIUS do
        for dy = -SCAN_RADIUS, SCAN_RADIUS do
            local sq = cell:getGridSquare(px + dx, py + dy, pz)
            if sq then
                local objs = sq:getObjects()
                if objs then
                    local n = objs:size()
                    for i = 0, n - 1 do
                        local o = objs:get(i)
                        if o then
                            local md = o:getModData()
                            if md and md.IsDCSObject then
                                M.applyOverlay(o)
                            end
                        end
                    end
                end
            end
        end
    end
end
Events.OnTick.Add(onTickScan)

local function subscribe()
    if not (DCS_Sync and DCS_Sync.Events and DCS_Sync.Events.subscribe) then return end
    local refresh = function() M.refreshAll() end
    DCS_Sync.Events.subscribe(DCS_Sync.Events.onProgressUpdated, refresh)
    DCS_Sync.Events.subscribe(DCS_Sync.Events.onChallengesUpdated, refresh)
    DCS_Sync.Events.subscribe(DCS_Sync.Events.onDailyReset, function()
        for k in pairs(traderVisited) do traderVisited[k] = nil end
        M.refreshAll()
    end)
end
Events.OnGameStart.Add(subscribe)

local function onServerCommand(module, command, args)
    if module ~= "DailyChallengeSystem" then return end
    if command ~= "objectStateCheckClient" then return end

    DCS_dprint("[DCS] ####################")
    DCS_dprint("[DCS] Client Overlay State Check")
    DCS_dprint("[DCS]   seen entries=" .. tostring(#(function() local r={} for k in pairs(seen) do r[#r+1]=k end; return r end)()))
    DCS_dprint("[DCS]   activePins entries=" .. tostring(#(function() local r={} for k in pairs(activePins) do r[#r+1]=k end; return r end)()))

    local challengeIDs = DCS_Sync and DCS_Sync.State and DCS_Sync.State.challengeIDs or {}
    local challengeSet = {}
    for _, id in ipairs(challengeIDs) do challengeSet[id] = true end

    local orphans = 0
    for chId, obj in pairs(seen) do
        local sq = obj and obj:getSquare()
        local inToday = challengeSet[chId] or false
        local status = "OK"
        if not sq then
            status = "[NO SQUARE]"
        elseif not inToday then
            status = "[ORPHANED — not in today's challengeIDs]"
            orphans = orphans + 1
        end
        DCS_dprint("[DCS]   seen[" .. chId .. "] sq=" .. tostring(sq ~= nil)
            .. " inToday=" .. tostring(inToday) .. " -> " .. status)
    end

    for chId, pin in pairs(activePins) do
        local obj = pin.obj
        local tex = pin.tex
        local sq = obj and obj:getSquare()
        local inToday = challengeSet[chId] or false
        local status = "OK"
        if not sq then
            status = "[NO SQUARE]"
        elseif not tex then
            status = "[NO TEXTURE]"
        elseif not inToday then
            status = "[ORPHANED — not in today's challengeIDs]"
            orphans = orphans + 1
        end
        DCS_dprint("[DCS]   activePin[" .. chId .. "] sq=" .. tostring(sq ~= nil)
            .. " tex=" .. tostring(tex ~= nil)
            .. " inToday=" .. tostring(inToday) .. " -> " .. status)
    end

    DCS_dprint("[DCS]   ORPHANED PINS: " .. orphans)
    DCS_dprint("[DCS] ####################")
end
Events.OnServerCommand.Add(onServerCommand)

return DCS_ObjectOverlay
