-- PIPShared.lua — Plysken Irrigation Pipes : constantes, config sandbox, connectivité.
-- Chargé client ET serveur (utilitaires purs). Connectivité reprise du code B42 fonctionnel de
-- Cluster Barrels (table ALLOWED_DIRS testée avec les sprites réutilisés — garder la cohérence).

PIP = PIP or {}

-- Debug gaté (comme PFR). DEV : force a true (independant de la sandbox, car une save existante
-- fige DebugLogs=false). A REMETTRE false / retirer DEV_FORCE_DEBUG avant publication (comme PFR_DEBUG).
PIP.DEV_FORCE_DEBUG = false  -- prod : refreshDebug() pilote via la sandbox DebugLogs (defaut false)
-- Force la fertigation ON (bypass sandbox) — utile pour tester sur une save existante (sandbox B42 =
-- binaire map_sand.bin, une option ajoutee apres creation reste au defaut). PROD = false (l'option
-- sandbox EnableFertigation, defaut on, pilote la feature).
PIP.DEV_FORCE_FERTIGATION = false
PIP.DEBUG = false
function PIP.dbg(...) if PIP.DEBUG then print("[PIP]", ...) end end

------------------------------------------------------------------------------
-- CONFIG SANDBOX (sandbox-first : point de lecture unique, garde `or <defaut>`).
------------------------------------------------------------------------------
function PIP.getConfig()
    local sv = (SandboxVars and SandboxVars.PIP) or {}
    return {
        enableAutoWatering         = (sv.EnableAutoWatering ~= false),
        wateringInterval           = math.max(1, sv.WateringInterval or 10),   -- clamp >=1 (0 = truthy en Lua -> arroserait chaque minute)
        wateringRadius             = sv.WateringRadius or 0,
        smartPipes                 = (sv.SmartPipes ~= false),
        smartPipesFillMax          = sv.SmartPipesFillMax or 20,
        sharedWaterPool            = (sv.SharedWaterPool ~= false),
        -- Fertigation (v1.2) : sandbox default = true (cf. sandbox-options.txt). On lit `~= false`
        -- comme les options soeurs ci-dessus -> absent (save creee avant v1.2, var pas dans map_sand.bin)
        -- = ON par defaut (honore le defaut declare), seul un EnableFertigation explicitement false coupe.
        -- (L'ancien `== true` cassait les saves existantes en SP : var nil -> off, alors que MP regenere
        -- sa config sandbox au boot -> on. D'ou "MP ok, SP plus d'options".)
        enableFertigation          = (PIP.DEV_FORCE_FERTIGATION == true) or (sv.EnableFertigation ~= false),
        fertigationSkill           = math.max(0, math.min(10, sv.FertigationSkill or 5)),  -- influe sur la chance de bonusYield (jamais sur la securite)
        chargesPerBag              = math.max(1, sv.ChargesPerBag or 10),                   -- doses-plantes par sac versé
        debugLogs                  = (sv.DebugLogs == true),
    }
end
function PIP.refreshDebug() PIP.DEBUG = PIP.DEV_FORCE_DEBUG or PIP.getConfig().debugLogs end

function PIP.key(x, y, z) return x .. "_" .. y .. "_" .. z end

-- Fertigation (v1.2.3) : consomme UNE dose (UseDelta) d'un sac Drainable (compost/engrais) du type
-- donné, RECURSIF (descend dans les sacs portés, comme findFertItem). item:Use() décrémente d'un
-- UseDelta ET applique automatiquement le ReplaceOnDeplete (un CompostBag vidé devient un
-- Base.EmptySandbag rendu dans le MÊME container = inventaire du joueur ; le Fertilizer n'a pas de
-- ReplaceOnDeplete -> disparaît une fois vide). Pattern vanilla = ISAddCompost:complete (item:Use()).
-- Retourne true si une dose a été consommée. Partagé client (SP/host) + serveur (dédié, autoritaire).
function PIP.useOneDrainable(inv, shortType)
    if not (inv and inv.getItems and shortType) then return false end
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it then
            if it:getType() == shortType and it.getCurrentUses and it:getCurrentUses() > 0 then
                it:Use()   -- 1 dose + ReplaceOnDeplete auto (EmptySandbag pour le compost)
                return true
            end
            local sub = it.getInventory and it:getInventory() or nil
            if sub and sub ~= inv and PIP.useOneDrainable(sub, shortType) then return true end
        end
    end
    return false
end

------------------------------------------------------------------------------
-- TYPES DE PIPE : pipeType (string) -> nom de TUILE + index de connectivité.
-- L'orientation/connectivité de chaque forme est celle du mod source (mêmes images),
-- mais les sprites sont désormais des tuiles déclarées par NOUS (voir ci-dessous).
------------------------------------------------------------------------------
-- v1.3.0 : passage de CHEMINS DE TEXTURE BRUTS a de VRAIES TUILES declarees.
-- Avant, chaque type pointait "media/textures/Item_PipeXX.png" : le moteur n'avait
-- aucun NOM a resoudre au rechargement d'une save -> pipes INVISIBLES apres reload
-- chez certains joueurs (RISKS 2026-06-27), colmate par PIPSpriteFix.
-- Desormais : common/media/texturepacks/pip_tileset.pack (les PIXELS, footer 0xDEADBEEF)
--           + common/media/pip_tiledef.tiles            (l'IDENTITE, sheet pip_tileset_01)
--           + mod.info : pack=pip_tileset / tiledef=pip_tiledef 3120
-- Le nom d'un sprite est <sheet>_<index> ; l'index vient de l'ORDRE de generation.
-- 🔴 CET ORDRE EST UN CONTRAT : le changer renommerait les sprites et casserait les
--    tuyaux deja poses dans les saves. Generateur : scratchpad/make_pip_assets.py.
-- 🔄 MIGRATION DES SAVES : gratuite. Le type est persiste dans md.PIP_pipeType, et
--    PIPSpriteFix re-applique SPRITE_BY_TYPE[type] a chaque chargement -> les pipes
--    existantes recoivent le nouveau sprite toutes seules. NE PAS retirer PIPSpriteFix
--    tant que des saves d'avant la bascule circulent (voir son en-tete).
PIP.SPRITE_BY_TYPE = {
    lineOption  = "pip_tileset_01_0",    -- ligne E-O
    lineOption2 = "pip_tileset_01_1",    -- ligne N-S
    crossOption = "pip_tileset_01_2",
    neOption    = "pip_tileset_01_3",
    nwOption    = "pip_tileset_01_4",
    seOption    = "pip_tileset_01_5",
    swOption    = "pip_tileset_01_6",
    tnOption    = "pip_tileset_01_7",
    tsOption    = "pip_tileset_01_8",
    teOption    = "pip_tileset_01_9",
    twOption    = "pip_tileset_01_10",
}

PIP.DIRS_CARD = { {0,-1}, {0,1}, {1,0}, {-1,0} }

local TYPE_IDX = {
    lineOption = 2, lineOption2 = 1, crossOption = 3,
    neOption = 4, nwOption = 5, seOption = 6, swOption = 7,
    tnOption = 8, tsOption = 9, teOption = 10, twOption = 11, barrel = 12,
}
function PIP.getTypeIdx(pipeType) return TYPE_IDX[pipeType] or 0 end

-- Directions ouvertes par index (repris du code source testé — l'orientation suit les sprites).
PIP.ALLOWED_DIRS_BY_TYPE = {
    [1]  = { N=true, S=true },
    [2]  = { E=true, W=true },
    [3]  = { N=true, E=true, S=true, W=true },
    [4]  = { W=true, S=true },
    [5]  = { E=true, S=true },
    [6]  = { N=true, W=true },
    [7]  = { N=true, E=true },
    [8]  = { E=true, W=true, N=true },
    [9]  = { S=true, E=true, W=true },
    [10] = { N=true, E=true, S=true },
    [11] = { N=true, W=true, S=true },
    [12] = { N=true, E=true, S=true, W=true },  -- barrel : connecte tout
}

-- Deux éléments (pipes/barrel) adjacents sont-ils connectés ? (cardinal, même z)
function PIP.areConnected(idxA, idxB, xA, yA, zA, xB, yB, zB)
    if zA ~= zB then return false end
    local dx, dy = xB - xA, yB - yA
    if (dx ~= 0 and dy ~= 0) or (math.abs(dx) + math.abs(dy) ~= 1) then return false end
    local dir
    if dy == -1 then dir = 'N' elseif dy == 1 then dir = 'S'
    elseif dx == 1 then dir = 'E' elseif dx == -1 then dir = 'W' else return false end
    local opposite = { N='S', S='N', E='W', W='E' }
    local a, b = PIP.ALLOWED_DIRS_BY_TYPE[idxA], PIP.ALLOWED_DIRS_BY_TYPE[idxB]
    if not a or not b then return false end
    return (a[dir] == true) and (b[opposite[dir]] == true)
end

-- Nom de l'IsoObject pipe dans le monde + helper de recherche sur une case.
PIP.OBJ_NAME = "PIP_WaterPipe"
function PIP.findPipeObject(square)
    if not (square and square.getObjects) then return nil end
    local objs = square:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o and o:getName() == PIP.OBJ_NAME then return o end
    end
    return nil
end

-- Détection robuste d'un rain barrel sur une case, SANS dépendre des GlobalObjectSystem.
-- ⚠️ B42 : `CRainBarrelSystem` est CLIENT-only (nil serveur dédié) ET `SRainBarrelSystem:isValidIsoObject`
-- est STUBBÉ `return false` en vanilla (détection serveur cassée) -> aucun des deux ne marche serveur.
-- On réplique la vraie règle (celle de CRainBarrelSystem côté client) : IsoThumpable + propriété OBJET
-- `CustomName == "Rain Collector Barrel"`. Marche client ET serveur, mêmes barrels partout.
function PIP.findBarrelOnSquare(square)
    if not (square and square.getObjects) then return nil end
    local objs = square:getObjects()
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if o and instanceof(o, "IsoThumpable") then
            local ok, name = pcall(function()
                local p = o:getProperties()
                return p and p:get("CustomName") or nil
            end)
            if ok and name == "Rain Collector Barrel" then return o end
        end
    end
    return nil
end

-- Validation MP : le joueur a-t-il le DROIT d'agir sur cette case ? (anti-grief/anti-client-modifie léger,
-- modèle de confiance co-op). Le serveur ne fait pas confiance aveugle aux coords d'une commande.
-- Tolérant : la pose marche à la case adjacente (~1 tuile) -> on autorise jusqu'à `maxDist` (défaut 3).
function PIP.playerNearby(player, x, y, z, maxDist)
    if not (player and player.getX) then return false end
    maxDist = maxDist or 3
    local ok, near = pcall(function()
        if math.abs(player:getZ() - z) > 1 then return false end
        local dx = player:getX() - (x + 0.5)
        local dy = player:getY() - (y + 0.5)
        return (dx * dx + dy * dy) <= (maxDist * maxDist)
    end)
    return ok and near or false
end

-- Retrait d'une pipe du monde + redonne l'item au joueur. Client & serveur.
function PIP.removePipeObject(pipeObject, character)
    if not pipeObject then return end
    local sq = pipeObject.getSquare and pipeObject:getSquare() or nil
    if not sq then return end
    local x, y, z = sq:getX(), sq:getY(), sq:getZ()
    sq:transmitRemoveItemFromSquare(pipeObject)
    sq:RemoveTileObject(pipeObject)
    sq:DeleteTileObject(pipeObject)
    -- Recalcul reseau APRES le retrait effectif (l'objet est parti -> le BFS detecte la scission et
    -- les barrels devenus orphelins sont unmarkes). Serveur autoritaire ; en MP dedie le client a deja
    -- delegue via sendClientCommand, donc removePipeObject ne tourne ici que serveur/SP/host.
    if not (isClient() and not isServer()) and PIP.Network and PIP.Network.removePipeAt then
        PIP.Network.removePipeAt(x, y, z)
    end
    -- NB : on ne rend PLUS l'item ici. Le retour de la WaterPipe se fait CÔTÉ CLIENT dans
    -- PIPRemovePipeAction:perform (joueur local -> sync immédiat). Un AddItem côté serveur dédié
    -- ne sync pas au client avant reconnexion (cf. PSR returnItemToNearbyPlayer), et
    -- character:sendObjectChange('addItemOfType',...) N'EXISTE PAS en B42 (No implementation found).
end

-- Charges {c=, f=} du GROUPE d'un barrel (par position), pour l'UI. CLIENT+SERVEUR : lit le store
-- ModData synchronise (md.barrels + md.fertCharges), pas PIP.Marked (server-only) -> marche aussi sur
-- un client dedie. Cle position = "x:y:z" (meme format que PIPBarrelRegistry.bkey).
function PIP.getGroupChargesAt(x, y, z)
    local res = { c = 0, f = 0 }
    if not (ModData and ModData.getOrCreate) then return res end
    local md = ModData.getOrCreate("PIP_Network")
    if not (md and md.barrels) then return res end
    local store = md.fertCharges or {}
    local function k(a, b, c) return a .. ":" .. b .. ":" .. c end
    local gid
    for _, bb in ipairs(md.barrels) do
        if bb.x == x and bb.y == y and bb.z == z then gid = bb.id; break end
    end
    if gid then
        for _, bb in ipairs(md.barrels) do
            if bb.id == gid then
                local ch = store[k(bb.x, bb.y, bb.z)]
                if ch then res.c = res.c + (ch.c or 0); res.f = res.f + (ch.f or 0) end
            end
        end
    else
        local ch = store[k(x, y, z)]
        if ch then res.c = ch.c or 0; res.f = ch.f or 0 end
    end
    return res
end

return PIP
