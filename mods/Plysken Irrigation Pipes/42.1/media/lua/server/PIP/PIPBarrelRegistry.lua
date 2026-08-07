-- PIPBarrelRegistry.lua (SERVER) - detection, registre et acces des rain barrels en B42.
--
-- Resout le blocage qui a tue les portages B42 : `getSquare()` renvoie nil hors chunk -> barrels
-- hors render range invisibles. Solution (pattern PFR) : registre PERSISTANT des positions (ModData
-- global, survit save + sync MP) + re-fetch via CRainBarrelSystem:getIsoObjectOnSquare quand le chunk
-- est charge + scan radius autour des joueurs pour rattraper les barrels non encore vus.
--
-- API B42 (verifiees dans Cluster Barrels) :
--   CRainBarrelSystem.instance:getIsoObjectOnSquare(sq) -> IsoObject barrel ou nil
--   barrel:getFluidContainer() -> getPrimaryFluidAmount() / adjustAmount() / Empty() / addFluid(FluidType.X, n)

require "PIP/PIPShared"

PIP = PIP or {}
PIP.Barrels = PIP.Barrels or {}

local REGISTRY_KEY = "PIP_Network"
PIP.Marked = PIP.Marked or {}      -- "x:y:z" -> { id = gid }

local function bkey(x, y, z) return x .. ":" .. y .. ":" .. z end

-- Détection des rain barrels : voir PIP.findBarrelOnSquare (PIPShared) — helper robuste indépendant
-- des GlobalObjectSystem (CRainBarrelSystem client-only + SRainBarrelSystem:isValidIsoObject stubbé
-- false en B42 = tous deux inutilisables côté serveur dédié).

-- Store persistant (pipes + barrels + nextId). Pattern PFR (ModData.getOrCreate + transmit).
function PIP.Barrels.store()
    if not (ModData and ModData.getOrCreate) then return nil end
    local md = ModData.getOrCreate(REGISTRY_KEY)
    md.pipes   = md.pipes   or {}
    md.barrels = md.barrels or {}
    md.nextId  = md.nextId  or 1
    return md
end

function PIP.Barrels.transmit()
    if ModData and ModData.transmit then pcall(function() ModData.transmit(REGISTRY_KEY) end) end
end

function PIP.Barrels.getNextId()
    local md = PIP.Barrels.store(); if not md then return 1 end
    local id = md.nextId or 1
    md.nextId = id + 1
    return id
end

-- Quantite d'eau d'un barrel (litres) via la methode IsoObject vanilla `getFluidAmount()`
-- (= ce que lit SRainBarrelGlobalObject:stateFromIsoObject). nil-safe.
function PIP.Barrels.getFluidAmount(barrel)
    if not (barrel and barrel.getFluidAmount) then return nil end
    local ok, amt = pcall(function() return barrel:getFluidAmount() end)
    if ok then return amt end
    return nil
end

-- Fixer le niveau d'eau d'un barrel (litres) AVEC sync client + sprite.
-- ⚠️ MP : modifier le FluidContainer brut (adjustAmount/Empty/addFluid) change l'eau server-side mais
-- NE met PAS a jour le sprite (niveau visible) ni les clients -> eau invisible + barrel « bloque ».
-- Le chemin vanilla = le SRainBarrelGlobalObject : set waterAmount + `stateToIsoObject` (emptyFluid +
-- addFluid + waterMax + changeSprite + transmitModData/transmitUpdatedSpriteToClients). On l'emploie.
function PIP.Barrels.setWater(barrel, liters)
    if not (barrel and barrel.getX) then return end
    if liters < 0 then liters = 0 end
    pcall(function()
        if SRainBarrelSystem and SRainBarrelSystem.instance then
            local lo = SRainBarrelSystem.instance:getLuaObjectAt(barrel:getX(), barrel:getY(), barrel:getZ())
            if lo then
                lo.waterAmount = liters
                lo:stateToIsoObject(barrel)   -- sync complet (fluide + sprite + clients)
                return
            end
        end
        -- fallback (systeme/luaObject absent) : set direct + transmit (sprite peut rester stale).
        -- capturer le FluidType AVANT emptyFluid : si FluidType nil, NE PAS vider (sinon eau perdue).
        local tainted = barrel.isTaintedWater and barrel:isTaintedWater()
        local ft = FluidType and (tainted and FluidType.TaintedWater or FluidType.Water) or nil
        if liters > 0 and not ft then return end   -- pas de FluidType -> abandon, on preserve l'eau
        barrel:emptyFluid()
        if liters > 0 then barrel:addFluid(ft, liters) end
        if barrel.transmitModData then barrel:transmitModData() end
    end)
end

-- Re-fetch l'IsoObject barrel a une position (nil si chunk non charge : on NE conclut RIEN).
function PIP.Barrels.fetchAt(x, y, z)
    local sq = getSquare(x, y, z)
    if not sq then return nil end
    return PIP.findBarrelOnSquare(sq)
end

-- Barrels relies a une pipe (cases cardinales adjacentes, connexion directionnelle pipe<->barrel).
function PIP.Barrels.getConnected(pipeObj)
    local out = {}
    if not (pipeObj and pipeObj.getSquare and pipeObj:getSquare()) then return out end
    local sq = pipeObj:getSquare()
    local md = pipeObj:getModData()
    local t = md and md.PIP_pipeType
    local idx = t and PIP.getTypeIdx(t) or 0
    if idx == 0 then return out end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    for _, d in ipairs(PIP.DIRS_CARD) do
        local cx, cy = x + d[1], y + d[2]
        local csq = getSquare(cx, cy, z)
        if csq then
            local barrel = PIP.findBarrelOnSquare(csq)
            if barrel and PIP.areConnected(idx, 12, x, y, z, cx, cy, z) then
                out[#out + 1] = barrel
            end
        end
    end
    return out
end

-- mark / unmark / isMarked : memoire PIP.Marked + persistance ModData.barrels (server-side).
function PIP.Barrels.mark(barrel, id)
    if not (barrel and barrel.getSquare and barrel:getSquare()) then return end
    local sq = barrel:getSquare()
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local k = bkey(x, y, z)
    local e = PIP.Marked[k] or {}
    if id and id > 0 then e.id = id end
    PIP.Marked[k] = e
    if isClient() and not isServer() then return end
    local md = PIP.Barrels.store(); if not md then return end
    -- NB : PAS de transmit() ici. mark() est appelé en boucle (assignIdAndUnify/reassignFresh/loadPipe)
    -- -> 1 transmit/barrel = spam réseau. Les appelants batchent UN seul PIP.Barrels.transmit() à la fin.
    for i = 1, #md.barrels do
        local b = md.barrels[i]
        if b.x == x and b.y == y and b.z == z then
            if id and id > 0 then md.barrels[i].id = id end
            return
        end
    end
    if id and id > 0 then
        md.barrels[#md.barrels + 1] = { x = x, y = y, z = z, id = id }
    end
end

function PIP.Barrels.unmark(barrel)
    if not (barrel and barrel.getSquare and barrel:getSquare()) then return end
    local sq = barrel:getSquare()
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    PIP.Marked[bkey(x, y, z)] = nil
    if isClient() and not isServer() then return end
    local md = PIP.Barrels.store(); if not md then return end
    for i = #md.barrels, 1, -1 do
        local b = md.barrels[i]
        if b.x == x and b.y == y and b.z == z then table.remove(md.barrels, i); PIP.Barrels.transmit(); break end
    end
end

-- Unmark tous les barrels d'un group id (utilise a la scission de reseau pour repartir a zero).
function PIP.Barrels.unmarkByGroup(gid)
    if not (gid and gid > 0) then return end
    for k, e in pairs(PIP.Marked) do
        if e and e.id == gid then PIP.Marked[k] = nil end
    end
    if isClient() and not isServer() then return end
    local md = PIP.Barrels.store(); if not md then return end
    for i = #md.barrels, 1, -1 do
        if md.barrels[i].id == gid then table.remove(md.barrels, i) end
    end
end

function PIP.Barrels.groupId(barrel)
    if not (barrel and barrel.getSquare and barrel:getSquare()) then return nil end
    local sq = barrel:getSquare()
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    local k = bkey(x, y, z)
    local e = PIP.Marked[k]
    if e and e.id then return e.id end
    -- Fallback (audit 2026-06-27) : PIP.Marked est une table VOLATILE, peuplee au boot (seedFromModData,
    -- chunks charges only) + incrementalement (OnObjectAdded/actions). Au stream/reload, un barrel marque
    -- peut charger AVANT d'etre re-seede -> groupId renvoyait nil -> barrel exclu du tick (arrosage/pool
    -- silencieusement inactif) alors que son id PERSISTANT vit dans md.barrels (source de verite, comme
    -- les pipes). On lit md.barrels en secours ET on re-seed PIP.Marked (auto-reparation, appels suivants O(1)).
    local md = PIP.Barrels.store()
    if md and md.barrels then
        for _, b in ipairs(md.barrels) do
            if b.x == x and b.y == y and b.z == z and b.id and b.id > 0 then
                PIP.Marked[k] = { id = b.id }
                return b.id
            end
        end
    end
    return nil
end

-- (Re)peupler PIP.Marked depuis le ModData au chargement, en re-fetchant les IsoObject presents.
function PIP.Barrels.seedFromModData()
    local md = PIP.Barrels.store(); if not md then return end
    for i = #md.barrels, 1, -1 do
        local b = md.barrels[i]
        local sq = getSquare(b.x, b.y, b.z)
        if sq then                                       -- chunk charge : on peut conclure
            local barrel = PIP.Barrels.fetchAt(b.x, b.y, b.z)
            if barrel then
                PIP.Marked[bkey(b.x, b.y, b.z)] = { id = b.id }
                local _ch = (md.fertCharges or {})[bkey(b.x, b.y, b.z)]   -- restaure l'affichage des charges au load (mirror modData)
                if _ch then PIP.Barrels.syncBarrelModData(barrel, _ch.c or 0, _ch.f or 0) end
            else                                         -- barrel disparu (detruit) -> purge (anti-fuite)
                PIP.Marked[bkey(b.x, b.y, b.z)] = nil
                table.remove(md.barrels, i)
                if md.fertCharges then md.fertCharges[bkey(b.x, b.y, b.z)] = nil end  -- charges meurent avec le barrel
            end
        end
        -- chunk non charge : on ne conclut RIEN (on garde l'entree)
    end
end

-- Re-valide les barrels marques via le REGISTRE de pipes (fiable meme hors render range) : un barrel
-- qui ne touche plus aucune pipe connectee est unmarke. Purge la pollution (marquages obsoletes).
function PIP.Barrels.revalidate()
    local md = PIP.Barrels.store(); if not md then return end
    if not (PIP.Network and PIP.Network.getPipeAt) then return end
    for i = #md.barrels, 1, -1 do
        local b = md.barrels[i]
        local connected = false
        for _, d in ipairs(PIP.DIRS_CARD) do
            local rec = PIP.Network.getPipeAt(b.x + d[1], b.y + d[2], b.z)
            if rec and rec.pipeType then
                local idx = PIP.getTypeIdx(rec.pipeType)
                if idx ~= 0 and PIP.areConnected(idx, 12, b.x + d[1], b.y + d[2], b.z, b.x, b.y, b.z) then
                    connected = true; break
                end
            end
        end
        if not connected then
            PIP.Marked[bkey(b.x, b.y, b.z)] = nil
            table.remove(md.barrels, i)
        end
    end
    PIP.Barrels.transmit()
end

-- Tous les barrels marques actuellement charges (IsoObject), via le store.
function PIP.Barrels.getAllMarked()
    local res = {}
    local md = PIP.Barrels.store(); if not md then return res end
    for _, b in ipairs(md.barrels) do
        if b.id and b.id > 0 then
            local barrel = PIP.Barrels.fetchAt(b.x, b.y, b.z)
            if barrel then res[#res + 1] = barrel end
        end
    end
    return res
end

------------------------------------------------------------------------------
-- FERTIGATION (v1.2) : charges d'engrais/compost par barrel, indexees par POSITION dans un
-- sous-store DEDIE (md.fertCharges), PAS dans md.barrels (qui est churne aux changements de
-- topologie : unmark/reassign). Survit save + sync MP + chunks decharges. Poolees par groupe au
-- tick. Server-side only (le store n'existe qu'au serveur/SP). Decouplees de l'eau (volume) : ce
-- sont des "doses-plantes", pas des litres.
------------------------------------------------------------------------------
local function chargeStore()
    local md = PIP.Barrels.store(); if not md then return nil end
    md.fertCharges = md.fertCharges or {}
    return md.fertCharges
end

-- Miroir des charges du baril sur le modData de son IsoObject + transmit. POURQUOI : le store global
-- ModData (md.fertCharges) ne se synchronise PAS de facon fiable vers les clients distants (le reste
-- de PIP recalcule client-side au lieu de s'y fier). Le modData d'un IsoObject, lui, se sync via
-- transmitModData (pattern PSR/PFR). L'affichage client (ligne « Reservoir ») lit PIP_fc/PIP_ff ici.
function PIP.Barrels.syncBarrelModData(barrel, c, f)
    if not (barrel and barrel.getModData) then return end
    local bmd = barrel:getModData()
    bmd.PIP_fc = c or 0
    bmd.PIP_ff = f or 0
    if barrel.transmitModData then pcall(function() barrel:transmitModData() end) end
end

-- Ajoute n charges d'un type ("compost"|"fert") au barrel (par position). Transmit (action ponctuelle).
function PIP.Barrels.addCharges(barrel, kind, n)
    if isClient() and not isServer() then return end
    if not (barrel and barrel.getSquare and barrel:getSquare()) or not n or n <= 0 then return end
    local store = chargeStore(); if not store then return end
    local sq = barrel:getSquare()
    local k = bkey(sq:getX(), sq:getY(), sq:getZ())
    local e = store[k] or { c = 0, f = 0 }
    if kind == "compost" then e.c = (e.c or 0) + n else e.f = (e.f or 0) + n end
    store[k] = e
    PIP.Barrels.transmit()
    PIP.Barrels.syncBarrelModData(barrel, e.c, e.f)   -- sync affichage client (MP)
    PIP.dbg(string.format("addCharges %s +%d @ %s (c=%d f=%d)", tostring(kind), n, k, e.c or 0, e.f or 0))
end

-- Total {c=, f=} des charges d'un GROUPE (somme des barrels marques de ce gid). Server-side.
function PIP.Barrels.getGroupCharges(gid)
    local res = { c = 0, f = 0 }
    if not (gid and gid > 0) then return res end
    local store = chargeStore(); if not store then return res end
    for k, e in pairs(PIP.Marked) do
        if e and e.id == gid then
            local ch = store[k]
            if ch then res.c = res.c + (ch.c or 0); res.f = res.f + (ch.f or 0) end
        end
    end
    return res
end

-- Consomme 1 charge d'un type sur un barrel du groupe (le premier qui en a). PAS de transmit ici
-- (le tick batche UN PIP.Barrels.transmit() a la fin). Retourne true si consomme.
function PIP.Barrels.consumeCharge(gid, kind)
    if not (gid and gid > 0) then return false end
    local store = chargeStore(); if not store then return false end
    local field = (kind == "compost") and "c" or "f"
    for k, e in pairs(PIP.Marked) do
        if e and e.id == gid then
            local ch = store[k]
            if ch and (ch[field] or 0) > 0 then
                ch[field] = ch[field] - 1
                local bx, by, bz = k:match("^(-?%d+):(-?%d+):(-?%d+)$")   -- maj modData du baril consomme (sync affichage)
                if bx then
                    local barrel = PIP.Barrels.fetchAt(tonumber(bx), tonumber(by), tonumber(bz))
                    if barrel then PIP.Barrels.syncBarrelModData(barrel, ch.c or 0, ch.f or 0) end
                end
                return true
            end
        end
    end
    return false
end
