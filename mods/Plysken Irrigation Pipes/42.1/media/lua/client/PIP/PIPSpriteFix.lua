-- PIPSpriteFix.lua (CLIENT) — durcissement d'AFFICHAGE : re-applique le sprite des pipes au chargement.
--
-- ⚠️ v1.3.0 — CE FICHIER A CHANGE DE ROLE, NE PAS LE SUPPRIMER.
-- La cause racine decrite ci-dessous (sprites par CHEMIN DE TEXTURE, sans .tiles) est CORRIGEE :
-- PIP declare desormais un vrai tiledef (`pip_tiledef 3120`) + un pack (`pip_tileset`), et
-- PIP.SPRITE_BY_TYPE contient des NOMS DE TUILES resolvables au rechargement.
-- Mais ce balayage devient le MIGRATEUR des saves existantes : il part de `md.PIP_pipeType`
-- (persiste en save) et applique SPRITE_BY_TYPE[type] -> une pipe posee AVANT la bascule
-- recoit automatiquement le NOUVEAU sprite, sans que le joueur ait quoi que ce soit a faire.
-- Sans lui, toutes les pipes des saves d'avant la v1.3.0 garderaient une reference morte.
-- ⇒ A conserver tant que des saves d'avant la bascule circulent ; suppression envisageable
--    dans une version ULTERIEURE seulement (et il restera un filet anti-regression utile).
--
-- POURQUOI (signal joueur 2026-06-27, SP) : la pipe etait un IsoObject.new(sq, "<chemin PNG>", "PIP_WaterPipe")
-- (PIP.SPRITE_BY_TYPE = chemins de texture BRUTS, PAS des tiles declarees ; aucun .tiles dans le mod).
-- Le moteur affiche la texture par chemin a la pose, mais chez CERTAINS joueurs le sprite n'est pas
-- re-resolu au reload (interference d'un mod tiers la plus probable : meme version de jeu, le Commandeur
-- ne reproduit pas) => pipes INVISIBLES apres reload (reseau OK, 0 erreur). getSprite(path) fonctionne
-- bien sur cette version (les pipes du Commandeur s'affichent) -> il suffit de RE-FORCER le sprite au load.
--
-- CHOIX DU HOOK (teste pas a pas 2026-06-27) :
--  * OnObjectAdded (client) ne fire PAS pour les chunks streames depuis save (cookbook B42) -> ecarte.
--  * MapObjects.OnLoadWithSprite ne matche PAS notre sprite-par-chemin non-tile (teste : 0 callback) -> ecarte.
--  * LoadGridsquare fire bien mais, au reload, les cases-pipe de la zone de spawn streament AVANT que le
--    registre de positions soit construit -> elles passent le hook a vide (teste : set=17 mais 0 re-sprite).
--  => SOLUTION : BALAYAGE des positions connues (lues du ModData PIP_Network, on a les coords) sur les
--     premieres frames apres le boot (jusqu'a ce que toutes les pipes chargees soient re-sprites), PLUS
--     LoadGridsquare (pre-filtre O(1) via le registre) pour les pipes qui streament en VOYAGE apres le boot.
--
-- RENDU PUR -> MP-SAFE : aucun etat autoritaire touche (pas de modData ecrit, pas de transmit/commande/BFS)
--   => desync/grief impossibles ; on ne re-teste pas la logique reseau v1.2.4.
-- PERF : balayage = O(nb de pipes) sur ~1s au boot puis stop ; LoadGridsquare = pre-filtre O(1) (aucun
--   getObjects sur les cases vides). 3 CONTEXTES : fichier client/ (jamais sur serveur dedie pur) + garde.

require "PIP/PIPShared"

PIP._pipePos = PIP._pipePos or {}   -- registre client {cle "x_y_z" -> true} pour le pre-filtre LoadGridsquare

local function pipesList()
    local md = (ModData and ModData.getOrCreate) and ModData.getOrCreate("PIP_Network") or nil
    return md and md.pipes or nil
end

local function rebuildSet(pipes)
    local set, n = {}, 0
    if pipes then
        for _, p in ipairs(pipes) do
            if p.x then set[PIP.key(p.x, p.y, p.z)] = true; n = n + 1 end
        end
    end
    PIP._pipePos = set
    return n
end

-- re-attache le sprite correct a la pipe presente sur la case (idempotent). Retourne true si applique.
local function applySprite(sq)
    local pipe = PIP.findPipeObject(sq)
    if not pipe then return false end
    local md = pipe.getModData and pipe:getModData() or nil
    local path = md and md.PIP_pipeType and PIP.SPRITE_BY_TYPE[md.PIP_pipeType]
    if not path then return false end
    local spr = getSprite(path)
    if not (spr and pipe.setSprite) then return false end   -- texture non resolue -> ne pas effacer
    pipe:setSprite(spr)
    return true
end

-- balaye toutes les positions de pipes connues ; re-sprite celles dont le chunk est charge.
local function sweep()
    if isServer() and not isClient() then return 0, 0 end
    local pipes = pipesList()
    local total = rebuildSet(pipes)
    local cell = getWorld() and getWorld():getCell()
    if not (cell and pipes) then return 0, total end
    local applied = 0
    for _, p in ipairs(pipes) do
        if p.x then
            local sq = cell:getGridSquare(p.x, p.y, p.z)
            if sq and applySprite(sq) then applied = applied + 1 end
        end
    end
    return applied, total
end

-- LIVE : une pipe qui (re)stream apres le boot (voyage). Pre-filtre O(1) -> aucun getObjects sur case vide.
local function onLoadSquare(sq)
    if isServer() and not isClient() then return end
    if sq and PIP._pipePos[PIP.key(sq:getX(), sq:getY(), sq:getZ())] then applySprite(sq) end
end

-- BOOT : les cases-pipe streament parfois avant que le registre soit pret -> on balaye sur les premieres
-- frames, jusqu'a ce que toutes les pipes chargees soient re-sprites (ou ~1s max), puis on s'arrete.
local burst = 0
local function bootSweep()
    burst = burst + 1
    local applied, total = sweep()
    if burst == 1 or applied == total then PIP.dbg("sprite sweep (boot): applied", applied, "/", total) end
    if (total > 0 and applied >= total) or burst >= 60 then
        if Events.OnTick then Events.OnTick.Remove(bootSweep) end
    end
end

if Events.OnGameStart then
    Events.OnGameStart.Add(function() burst = 0; if Events.OnTick then Events.OnTick.Add(bootSweep) end end)
end
if Events.EveryOneMinute then
    Events.EveryOneMinute.Add(function() local a, t = sweep(); PIP.dbg("sprite sweep (1min): applied", a, "/", t) end)
end
if Events.LoadGridsquare then Events.LoadGridsquare.Add(onLoadSquare) end

-- OUTIL DEV (inerte en prod : fonction JAMAIS appelee automatiquement). Pour VALIDER le fix sans avoir
-- le bug : en jeu avec -debug, ouvrir la console Lua et taper  PIP.devBreakAllPipeSprites()  -> casse
-- l'affichage de toutes les pipes chargees autour du joueur (setSprite(nil)) = SIMULE le bug. Puis
-- sauver + RELANCER LE JEU -> le balayage boot doit les re-rendre. Prouve la reparation cote Commandeur.
function PIP.devBreakAllPipeSprites()
    local cell = getWorld() and getWorld():getCell()
    if not cell then print("[PIP][DEV] no cell"); return 0 end
    local player = getPlayer()
    local px = player and math.floor(player:getX()) or 0
    local py = player and math.floor(player:getY()) or 0
    local pz = player and player:getZ() or 0
    local n = 0
    for x = px - 60, px + 60 do
        for y = py - 60, py + 60 do
            local sq = cell:getGridSquare(x, y, pz)
            local pipe = sq and PIP.findPipeObject(sq)
            if pipe and pipe.setSprite then pipe:setSprite(nil); n = n + 1 end
        end
    end
    print("[PIP][DEV] broke " .. n .. " pipe sprites around player (save + relaunch should restore them)")
    return n
end
