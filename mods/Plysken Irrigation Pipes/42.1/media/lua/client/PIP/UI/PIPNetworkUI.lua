-- PIPNetworkUI.lua (CLIENT) - highlight du reseau au clic (QOL).
-- Clic-droit sur une pipe -> Show Network -> surligne les OBJETS pipe (bleu) + barrel (vert) du meme
-- group ID + halo-note (pipes / barrels / eau du pool). Hide Network pour enlever.
--
-- 2 points B42 importants :
--  * Highlight sur l'IsoObject (setHighlighted/setHighlightColor), PAS sur la case.
--  * Le highlight d'objet est RESET par le rendu chaque frame -> il faut le RE-APPLIQUER en continu
--    (comme les curseurs vanilla ISRemovePlantCursor/ISExtinguishCursor le font dans leur render).
--  * Barrels lus depuis le ModData (source de verite persistante), pas la table memoire PIP.Marked
--    (qui peut etre incomplete apres un reload).
-- SP : lit PIP.Network / le store ModData (accessibles en solo). MP dedie -> UI = v1.1.

require "PIP/PIPShared"

PIP = PIP or {}
PIP.UI = PIP.UI or { highlighted = {} }   -- liste de { obj, r, g, b, a }

function PIP.UI.clearHighlight()
    for _, h in ipairs(PIP.UI.highlighted) do
        if h.obj and h.obj.setHighlighted then pcall(function() h.obj:setHighlighted(false) end) end
    end
    PIP.UI.highlighted = {}
end

function PIP.UI.isActive() return #PIP.UI.highlighted > 0 end

local function add(obj, r, g, b, a)
    if obj and obj.setHighlighted then
        PIP.UI.highlighted[#PIP.UI.highlighted + 1] = { obj = obj, r = r, g = g, b = b, a = a }
    end
end

-- Re-applique le highlight chaque frame (sinon le rendu le reset). Fonction statique (pas de closure
-- allouee par objet/frame) + purge des objets decharges (getSquare nil) pour ne pas tourner a vide.
local function applyOne(obj, r, g, b, a)
    obj:setHighlighted(true, false)
    obj:setHighlightColor(r, g, b, a)
end
local function reapply()
    local list = PIP.UI.highlighted
    for i = #list, 1, -1 do
        local h = list[i]
        local obj = h.obj
        if obj and obj.setHighlighted and obj.getSquare and obj:getSquare() then
            pcall(applyOne, obj, h.r, h.g, h.b, h.a)
        else
            table.remove(list, i)   -- objet decharge / invalide -> retire du highlight
        end
    end
end
if Events.OnTick then Events.OnTick.Add(reapply) end

-- BFS 100% CLIENT (SP / host / dedie unifie) : on part de la pipe cliquee et on surligne la
-- composante connectee VISIBLE (objets charges), sans dependre de PIP.Network (serveur-only en dedie).
-- Connectivite via les helpers shared (findPipeObject / areConnected / getTypeIdx). Barrels lus en
-- via PIP.findBarrelOnSquare (shared, robuste) + leur eau (synchronisee). Pas de gid cote client (cosmetique).
local function idxOfPipe(obj)
    local md = obj and obj:getModData()
    return PIP.getTypeIdx(md and md.PIP_pipeType)
end

function PIP.UI.showNetwork(x, y, z)
    PIP.UI.clearHighlight()
    local cell = getCell()
    if not cell then return end
    local startSq = cell:getGridSquare(x, y, z)
    if not (startSq and PIP.findPipeObject(startSq)) then return end

    local visited, barrelsSeen = {}, {}
    local nPipes, nBarrels, pool = 0, 0, 0
    local q, qi = { { x = x, y = y, z = z } }, 1
    visited[PIP.key(x, y, z)] = true

    while qi <= #q do
        local cur = q[qi]; qi = qi + 1
        local sq = cell:getGridSquare(cur.x, cur.y, cur.z)
        local obj = sq and PIP.findPipeObject(sq) or nil
        if obj then
            add(obj, 0.2, 0.6, 1.0, 0.9)   -- pipe : bleu
            nPipes = nPipes + 1
            local curIdx = idxOfPipe(obj)
            for _, d in ipairs(PIP.DIRS_CARD) do
                local nx, ny, nz = cur.x + d[1], cur.y + d[2], cur.z
                local nsq = cell:getGridSquare(nx, ny, nz)
                if nsq then
                    -- 1) pipe voisine directionnellement connectee
                    local nobj = PIP.findPipeObject(nsq)
                    if nobj then
                        local nk = PIP.key(nx, ny, nz)
                        if not visited[nk] then
                            local nidx = idxOfPipe(nobj)
                            if curIdx ~= 0 and nidx ~= 0
                               and PIP.areConnected(curIdx, nidx, cur.x, cur.y, cur.z, nx, ny, nz) then
                                visited[nk] = true
                                q[#q + 1] = { x = nx, y = ny, z = nz }
                            end
                        end
                    end
                    -- 2) barrel voisin (connecte tout cote) -> surligne + cumule l'eau, et traverse
                    --    vers les pipes de l'autre cote du barrel (comme le reseau serveur).
                    local bk = PIP.key(nx, ny, nz)
                    if not barrelsSeen[bk] then
                        local barrel = PIP.findBarrelOnSquare(nsq)
                        if barrel then
                            barrelsSeen[bk] = true
                            add(barrel, 0.2, 1.0, 0.4, 0.9)   -- barrel : vert
                            nBarrels = nBarrels + 1
                            pcall(function()
                                local fc = barrel:getFluidContainer()
                                if fc then pool = pool + (fc:getPrimaryFluidAmount() or 0) end
                            end)
                            -- traversee : pipes de l'autre cote du barrel
                            for _, bd in ipairs(PIP.DIRS_CARD) do
                                local px, py = nx + bd[1], ny + bd[2]
                                local pk = PIP.key(px, py, nz)
                                if not visited[pk] then
                                    local psq = cell:getGridSquare(px, py, nz)
                                    local pobj = psq and PIP.findPipeObject(psq) or nil
                                    if pobj then
                                        local pidx = idxOfPipe(pobj)
                                        if pidx ~= 0 and PIP.areConnected(pidx, 12, px, py, nz, nx, ny, nz) then
                                            visited[pk] = true
                                            q[#q + 1] = { x = px, y = py, z = nz }
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local pl = getPlayer()
    if pl and pl.setHaloNote then
        pcall(function()
            pl:setHaloNote(getText("IGUI_PIP_NetworkInfoLocal", nPipes, nBarrels, math.floor(pool)),
                120, 200, 255, 300)
        end)
    end
end
