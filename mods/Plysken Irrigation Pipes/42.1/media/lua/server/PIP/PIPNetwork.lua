-- PIPNetwork.lua (SERVER) - reseau de pipes : registre, connectivite (BFS), group ID.
-- Adapte du WaterPipe.lua de Cluster Barrels (qui marche en B42), simplifie : ModData global only
-- (pas de fichier .bin), noms PIP, nil-safe. Un reseau = composante connexe de pipes reliees entre
-- elles ET via les barrels ; chaque composante recoit un groupId (= min des IDs existants, sinon next).

require "PIP/PIPShared"
require "PIP/PIPBarrelRegistry"

PIP = PIP or {}
PIP.Network = PIP.Network or { pipes = {}, byKey = {} }

local function isSrv() return not (isClient() and not isServer()) end
local function nkey(x, y, z) return x .. "_" .. y .. "_" .. z end

function PIP.Network.getPipeAt(x, y, z) return PIP.Network.byKey[nkey(x, y, z)] end

-- Voisin pipe cardinal, seulement s'il est directionnellement connecte.
local function neighborIfConnected(fromObj, nx, ny, nz)
    local sq = getSquare(nx, ny, nz); if not sq then return nil end
    local nb = PIP.findPipeObject(sq); if not nb then return nil end
    local amd = fromObj and fromObj:getModData()
    local aT = amd and amd.PIP_pipeType
    local bmd = nb:getModData()
    local bT = bmd and bmd.PIP_pipeType
    if not (aT and bT) then return nil end
    local aIdx, bIdx = PIP.getTypeIdx(aT), PIP.getTypeIdx(bT)
    if aIdx == 0 or bIdx == 0 then return nil end
    local fsq = fromObj:getSquare(); if not fsq then return nil end
    if PIP.areConnected(aIdx, bIdx, fsq:getX(), fsq:getY(), fsq:getZ(), nx, ny, nz) then return nb end
    return nil
end

-- BFS : visite toute la composante (pipes cardinales + traversee via barrels). visitor(x,y,z,obj).
function PIP.Network.visitConnected(startObj, visitor)
    if not (startObj and visitor and startObj:getSquare()) then return end
    local sq0 = startObj:getSquare()
    local q, qi, visited = { { x = sq0:getX(), y = sq0:getY(), z = sq0:getZ(), obj = startObj } }, 1, {}
    visited[nkey(sq0:getX(), sq0:getY(), sq0:getZ())] = true
    while qi <= #q do
        local cur = q[qi]; qi = qi + 1
        local curObj = cur.obj
        if not curObj then
            local cs = getSquare(cur.x, cur.y, cur.z)
            curObj = cs and PIP.findPipeObject(cs) or nil
        end
        if curObj then
            visitor(cur.x, cur.y, cur.z, curObj)
            -- 1) pipes cardinales connectees
            for _, d in ipairs(PIP.DIRS_CARD) do
                local nx, ny = cur.x + d[1], cur.y + d[2]
                local nObj = neighborIfConnected(curObj, nx, ny, cur.z)
                if nObj and PIP.Network.getPipeAt(nx, ny, cur.z) then   -- enregistree only (exclut la pipe retiree mais pas encore disparue du monde)
                    local k = nkey(nx, ny, cur.z)
                    if not visited[k] then visited[k] = true; q[#q + 1] = { x = nx, y = ny, z = cur.z, obj = nObj } end
                end
            end
            -- 2) traversee des barrels relies -> pipes de l'autre cote
            for _, barrel in ipairs(PIP.Barrels.getConnected(curObj)) do
                local bsq = barrel.getSquare and barrel:getSquare() or nil
                if bsq then
                    local bx, by, bz = bsq:getX(), bsq:getY(), bsq:getZ()
                    for _, bd in ipairs(PIP.DIRS_CARD) do
                        local px, py = bx + bd[1], by + bd[2]
                        local psq = getSquare(px, py, bz)
                        local pObj = psq and PIP.findPipeObject(psq) or nil
                        if pObj and PIP.Network.getPipeAt(px, py, bz) then   -- enregistree only
                            local pmd = pObj:getModData()
                            local t = pmd and pmd.PIP_pipeType
                            local idx = t and PIP.getTypeIdx(t) or 0
                            if idx ~= 0 and PIP.areConnected(idx, 12, px, py, bz, bx, by, bz) then
                                local k2 = nkey(px, py, bz)
                                if not visited[k2] then visited[k2] = true; q[#q + 1] = { x = px, y = py, z = bz, obj = pObj } end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Assigne le group id (min existant, sinon nouveau) a toute la composante + marque les barrels relies.
function PIP.Network.assignIdAndUnify(pipeObj)
    if not isSrv() then return end
    if not (pipeObj and pipeObj:getSquare()) then return end
    local visitedList, existingIds = {}, {}
    PIP.Network.visitConnected(pipeObj, function(px, py, pz, pobj)
        local rec = PIP.Network.getPipeAt(px, py, pz)
        if rec then
            visitedList[#visitedList + 1] = { rec = rec, obj = pobj }
            if rec.id and rec.id > 0 then existingIds[#existingIds + 1] = rec.id end
        end
    end)
    if #visitedList == 0 then return end
    local gid
    if #existingIds > 0 then
        gid = existingIds[1]
        for i = 2, #existingIds do if existingIds[i] < gid then gid = existingIds[i] end end
    else
        gid = PIP.Barrels.getNextId()
    end
    local md = PIP.Barrels.store()
    for _, it in ipairs(visitedList) do
        if it.rec.id ~= gid then
            it.rec.id = gid
            if md then
                for i = 1, #md.pipes do
                    local d = md.pipes[i]
                    if d.x == it.rec.x and d.y == it.rec.y and d.z == it.rec.z then md.pipes[i].id = gid; break end
                end
            end
        end
    end
    local nb = 0
    for _, it in ipairs(visitedList) do
        for _, barrel in ipairs(PIP.Barrels.getConnected(it.obj)) do
            PIP.Barrels.mark(barrel, gid); nb = nb + 1
        end
    end
    PIP.Barrels.transmit()
    PIP.dbg(string.format("network gid=%d pipes=%d barrelsMarked=%d", gid, #visitedList, nb))
end

-- Enregistre une pipe (memoire + ModData) puis (re)calcule son groupe.
function PIP.Network.loadPipe(obj)
    if not isSrv() then return end
    if not (obj and obj.getSquare and obj:getSquare()) then return end
    local sq = obj:getSquare()
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local existing = PIP.Network.getPipeAt(x, y, z)
    local pType = obj:getModData().PIP_pipeType
    if not existing then
        local rec = { x = x, y = y, z = z, pipeType = pType, id = nil }
        PIP.Network.pipes[#PIP.Network.pipes + 1] = rec
        PIP.Network.byKey[nkey(x, y, z)] = rec
        local md = PIP.Barrels.store()
        if md then md.pipes[#md.pipes + 1] = { x = x, y = y, z = z, pipeType = pType, id = nil } end
        PIP.Network.assignIdAndUnify(obj)
    elseif (existing.id == nil) or (existing.id <= 0) then
        PIP.Network.assignIdAndUnify(obj)
    end
    -- Robustesse load : marquer les barrels connectes a cette pipe s'ils ne le sont pas deja
    -- (reseau charge depuis la save, OU barrel marque avant le fix CRain->SRain = jamais detecte serveur).
    -- Idempotent (skip si deja un gid). getConnected utilise PIP.findBarrelOnSquare (correct serveur dedie).
    local rec = PIP.Network.getPipeAt(x, y, z)
    if rec and rec.id and rec.id > 0 then
        local marked = false
        for _, barrel in ipairs(PIP.Barrels.getConnected(obj)) do
            if not PIP.Barrels.groupId(barrel) then PIP.Barrels.mark(barrel, rec.id); marked = true end
        end
        if marked then PIP.Barrels.transmit() end   -- 1 seul transmit (mark() ne transmet plus)
    end
end

-- Re-colorise une composante connexe avec un gid FRAIS (apres retrait, pour separer une scission).
-- `done` (set de cases) evite de re-traiter une composante deja coloree dans le meme recompute.
function PIP.Network.reassignFresh(pipeObj, done)
    if not isSrv() then return end
    if not (pipeObj and pipeObj:getSquare()) then return end
    local s0 = pipeObj:getSquare()
    if done[nkey(s0:getX(), s0:getY(), s0:getZ())] then return end
    local visitedList = {}
    PIP.Network.visitConnected(pipeObj, function(px, py, pz, pobj)
        local rec = PIP.Network.getPipeAt(px, py, pz)
        if rec then visitedList[#visitedList + 1] = { rec = rec, obj = pobj }; done[nkey(px, py, pz)] = true end
    end)
    if #visitedList == 0 then return end
    local gid = PIP.Barrels.getNextId()
    local md = PIP.Barrels.store()
    for _, it in ipairs(visitedList) do
        it.rec.id = gid
        if md then
            for i = 1, #md.pipes do
                local dd = md.pipes[i]
                if dd.x == it.rec.x and dd.y == it.rec.y and dd.z == it.rec.z then md.pipes[i].id = gid; break end
            end
        end
    end
    local nb = 0
    for _, it in ipairs(visitedList) do
        for _, barrel in ipairs(PIP.Barrels.getConnected(it.obj)) do PIP.Barrels.mark(barrel, gid); nb = nb + 1 end
    end
    PIP.dbg(string.format("reassignFresh gid=%d pipes=%d barrels=%d", gid, #visitedList, nb))
end

-- Recalcul apres retrait : la scission d'un reseau doit donner des group ids DISTINCTS.
-- On purge les barrels des anciens gids touches (pipe retiree + voisins), puis on re-colorise chaque
-- composante voisine restante avec un gid frais (les barrels encore connectes sont re-marques).
function PIP.Network.recomputeAround(x, y, z, removedGid)
    if not isSrv() then return end
    local oldGids = {}
    if removedGid and removedGid > 0 then oldGids[removedGid] = true end
    for _, d in ipairs(PIP.DIRS_CARD) do
        local rec = PIP.Network.getPipeAt(x + d[1], y + d[2], z)
        if rec and rec.id and rec.id > 0 then oldGids[rec.id] = true end
    end
    for gid in pairs(oldGids) do PIP.Barrels.unmarkByGroup(gid) end
    local done = {}
    for _, d in ipairs(PIP.DIRS_CARD) do
        local psq = getSquare(x + d[1], y + d[2], z)
        local p = psq and PIP.findPipeObject(psq) or nil
        if p then PIP.Network.reassignFresh(p, done) end
    end
    PIP.Barrels.transmit()
end

-- Retire une pipe du registre (memoire + ModData) + recalcule autour (scission-aware).
function PIP.Network.removePipeAt(x, y, z)
    if not isSrv() then return end
    local rec = PIP.Network.getPipeAt(x, y, z)
    local removedGid = rec and rec.id or nil
    PIP.dbg(string.format("removePipeAt (%d,%d) removedGid=%s", x, y, tostring(removedGid)))
    PIP.Network.byKey[nkey(x, y, z)] = nil
    for i = #PIP.Network.pipes, 1, -1 do
        local p = PIP.Network.pipes[i]
        if p.x == x and p.y == y and p.z == z then table.remove(PIP.Network.pipes, i) end
    end
    local md = PIP.Barrels.store()
    if md then
        for i = #md.pipes, 1, -1 do
            local p = md.pipes[i]
            if p.x == x and p.y == y and p.z == z then table.remove(md.pipes, i); break end
        end
    end
    PIP.Network.recomputeAround(x, y, z, removedGid)
    PIP.Barrels.transmit()
end

-- Chargement initial des pipes depuis le ModData (+ re-seed des barrels marques).
function PIP.Network.loadAll()
    if not isSrv() then return end
    if PIP.Network._loaded then return end
    PIP.Network.pipes, PIP.Network.byKey = {}, {}
    local md = PIP.Barrels.store()
    if md then
        for _, p in ipairs(md.pipes) do
            local rec = { x = p.x, y = p.y, z = p.z, pipeType = p.pipeType, id = (p.id and p.id > 0) and p.id or nil }
            PIP.Network.pipes[#PIP.Network.pipes + 1] = rec
            PIP.Network.byKey[nkey(rec.x, rec.y, rec.z)] = rec
        end
    end
    PIP.Barrels.seedFromModData()
    if PIP.Barrels.revalidate then PIP.Barrels.revalidate() end  -- purge les barrels marques plus connectes (anti-pollution)
    PIP.Network._loaded = true
    PIP.dbg("network loaded " .. #PIP.Network.pipes .. " pipes from ModData")
end

------------------------------------------------------------------------------
-- Events
------------------------------------------------------------------------------
local function onObjectAdded(obj)
    if not isSrv() or not obj then return end
    local sq = obj.getSquare and obj:getSquare() or nil
    if obj.getName and obj:getName() == PIP.OBJ_NAME then
        -- PERF MP : ne traiter QUE les pipes reellement NEUVES. Si la pipe est deja dans le registre
        -- (reload de chunk / re-fire de l'event au streaming), NE RIEN faire -> evite getConnected +
        -- un eventuel BFS/transmit a chaque reapparition. La POSE joueur arrive ici AVANT enregistrement
        -- (getPipeAt = nil) -> loadPipe complet (BFS+transmit) bien execute.
        if sq and not PIP.Network.getPipeAt(sq:getX(), sq:getY(), sq:getZ()) then PIP.Network.loadPipe(obj) end
        return
    end
    -- barrel pose : reassigner depuis une pipe voisine (ce qui le marquera)
    if sq then
        local barrel = PIP.findBarrelOnSquare(sq)
        if barrel then
            if PIP.Barrels.groupId(barrel) then return end   -- PERF MP : barrel deja marque (connu) -> pas de BFS/transmit sur reload de chunk
            for _, d in ipairs(PIP.DIRS_CARD) do
                local psq = getSquare(sq:getX() + d[1], sq:getY() + d[2], sq:getZ())
                local p = psq and PIP.findPipeObject(psq) or nil
                if p then PIP.Network.assignIdAndUnify(p); break end
            end
        end
    end
end

local function onObjectRemoved(obj)
    if not isSrv() or not obj then return end
    local sq = obj.getSquare and obj:getSquare() or nil
    if obj.getName and obj:getName() == PIP.OBJ_NAME then
        return  -- retrait d'une pipe gere par PIP.removePipeObject (timing correct, apres DeleteTileObject)
    end
    if sq then
        -- PERF MP (fix bug joueur 2026-06-23) : ne recalculer/broadcaster QUE si l'objet retire est
        -- un BARREL (lui seul mediate la connectivite du reseau). Avant : recomputeAround -> transmit()
        -- ModData INCONDITIONNEL etait appele pour TOUT objet non-pipe retire (zombie mort, item ramasse,
        -- cadavre...) -> un broadcast reseau a chaque churn d'objet sur le serveur = flood (contribue a la
        -- desync, pire avec le temps/serveur peuple). Un objet non-barrel ne change pas la topologie.
        -- `barrel == obj` garantit qu'on agit seulement quand le barrel LUI-MEME est retire (et pas quand
        -- on retire un autre objet pose sur la meme case qu'un barrel -> evite aussi un unmark a tort).
        local barrel = PIP.findBarrelOnSquare(sq)
        if barrel and barrel == obj then
            PIP.Barrels.unmark(barrel)
            PIP.Network.recomputeAround(sq:getX(), sq:getY(), sq:getZ())
        end
    end
end

local function onLoadGridsquare(sq)
    if not isSrv() or not sq then return end
    -- PERF MP (fix bug joueur 2026-06-23 : desync/chunks noirs sur dedie en voyageant).
    -- LoadGridsquare fire PAR CASE (des milliers/s en voiture). L'ancien code faisait getObjects +
    -- loadPipe a chaque case -> loadPipe pouvait declencher un BFS reseau (assignIdAndUnify) + un
    -- ModData.transmit (broadcast de TOUT l'etat reseau, qui grossit avec la ferme) -> ces BFS et
    -- broadcasts en rafale etouffaient le streaming de chunks (meme thread + meme bande passante serveur)
    -- => chunks qui ne chargent plus, desync. Pire en voyageant / grosse ferme / dans le temps.
    -- FIX : le reseau est DEJA entierement connu depuis le ModData (loadAll au boot) ; un chunk qui
    -- stream NE change PAS la topologie. Donc on ne recalcule RIEN ici :
    --   * case sans pipe (quasi toutes) -> sortie O(1) via le registre, AUCUN getObjects ;
    --   * case avec pipe connue -> rien a faire (deja enregistree + id charge au boot, barrels marques
    --     par seedFromModData ; le tick d'arrosage re-fetch les IsoObjects vivants lui-meme).
    -- Le BFS + transmit restent UNIQUEMENT sur l'action joueur (OnObjectAdded / pose-retrait).
    if not PIP.Network.getPipeAt(sq:getX(), sq:getY(), sq:getZ()) then return end
end

-- Gardes defensifs : un event peut etre absent selon la version (comme le fait Cluster Barrels).
-- B42 : le retrait d'objet est OnObjectAboutToBeRemoved (PFR), pas OnObjectRemoved (nil en B42).
if Events.OnObjectAdded then Events.OnObjectAdded.Add(onObjectAdded) end
if Events.OnObjectAboutToBeRemoved then Events.OnObjectAboutToBeRemoved.Add(onObjectRemoved) end
if Events.LoadGridsquare then Events.LoadGridsquare.Add(onLoadGridsquare) end
if Events.OnGameStart then Events.OnGameStart.Add(PIP.Network.loadAll) end
if Events.OnGameTimeLoaded then Events.OnGameTimeLoaded.Add(PIP.Network.loadAll) end
