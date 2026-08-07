-- PIPContextMenu.lua (CLIENT) — menu de pose / retrait de pipe.
-- Adapté de WaterPipeMenu (Cluster Barrels). i18n : libellés via getText (18 langues).

require "PIP/PIPShared"

PIPMenu = {}

function PIPMenu.onPlace(worldobjects, player, pipeItem, sprite, ptype)
    local plObj = getSpecificPlayer(player)
    local cell = getCell()
    if PIP.ensurePipeClass then PIP.ensurePipeClass() end   -- définit la classe au runtime (ISBuildingObject garanti chargé)
    if not (plObj and cell and PIPPipe) then return end
    local pipe = PIPPipe:new(player, pipeItem, sprite, ptype)
    cell:setDrag(pipe, plObj:getPlayerNum())
end

function PIPMenu.onRemove(worldobjects, player, pipeObject, square, time)
    local plObj = getSpecificPlayer(player)
    if not plObj then return end   -- garde de coherence avec onPlace/onEnrich (walkAdj(nil) = crash)
    if luautils.walkAdj(plObj, square) then
        ISTimedActionQueue.add(PIPRemovePipeAction:new(plObj, pipeObject, square, time))
    end
end

function PIPMenu.onShowNetwork(worldobjects, player, x, y, z)
    if PIP.UI and PIP.UI.showNetwork then PIP.UI.showNetwork(x, y, z) end
end

function PIPMenu.onHideNetwork(worldobjects)
    if PIP.UI and PIP.UI.clearHighlight then PIP.UI.clearHighlight() end
end

-- Un item est-il un sac de compost ("compost") ou d'engrais ("fert") ? Type vanilla garanti
-- (CompostBag / Fertilizer) + tag (couvre les items moddés équivalents).
local function fertMatches(it, kind)
    -- Type vanilla UNIQUEMENT (CompostBag / Fertilizer). On N'utilise PAS item:hasTag(String) :
    -- "No implementation found for function: hasTag" sur certaines classes (ex. Clothing) -> crash au
    -- scan de l'inventaire, et pcall ne capture pas les RuntimeException Java (feedback-kahlua-pcall-java).
    -- Le support des engrais moddés par tag viendra avec l'API tag B42 vérifiée in-game.
    if kind == "compost" then
        return it:getType() == "CompostBag"
    end
    return it:getType() == "Fertilizer"
end

-- Cherche un sac de compost/engrais dans l'inventaire, RECURSIF (descend dans les sacs portés),
-- comme la vanilla (containsTagRecurse). Retourne le 1er item trouvé (pour le consommer).
function PIPMenu.findFertItem(inv, kind)
    if not (inv and inv.getItems) then return nil end
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it then
            if fertMatches(it, kind) then return it end
            local sub = it.getInventory and it:getInventory() or nil
            if sub and sub ~= inv then
                local found = PIPMenu.findFertItem(sub, kind)
                if found then return found end
            end
        end
    end
    return nil
end

-- Verse UNE DOSE d'un sac (Drainable) dans l'eau d'irrigation d'un barrel connecté. La consommation
-- (1 dose via item:Use + EmptySandbag compost) se fait à la fin de l'action : autoritaire serveur en
-- MP (PIPEnrichAction), local en SP/host. shortType/fullType passés à l'action pour cibler le sac.
function PIPMenu.onEnrich(worldobjects, player, x, y, z, kind)
    local plObj = getSpecificPlayer(player)
    if not plObj then return end
    local item = PIPMenu.findFertItem(plObj:getInventory(), kind)
    if not item then return end
    local square = getSquare(x, y, z)
    if not square then return end
    -- Marche jusqu'au barrel (ou reste si deja adjacent) PUIS verse (barre de progression).
    -- La consommation du sac + l'ajout des charges se font a la FIN de l'action (PIPEnrichAction).
    if luautils.walkAdj(plObj, square) then
        ISTimedActionQueue.add(PIPEnrichAction:new(plObj, x, y, z, kind, item:getType(), item:getFullType()))
    end
end

function PIPMenu.doMenu(player, context, worldobjects)
    local plObj = getSpecificPlayer(player)
    if not plObj then return end
    local cfg = PIP.getConfig()

    -- une pipe sur une des cases ciblées ? (option retrait)
    local removeTarget, removeSquare
    for _, object in ipairs(worldobjects) do
        local sq = object.getSquare and object:getSquare() or nil
        local p = sq and PIP.findPipeObject(sq)
        if p then removeTarget = p; removeSquare = sq; break end
    end

    -- item pipe disponible ? (option pose)
    local inv = plObj:getInventory()
    local hand = plObj:getSecondaryHandItem()
    local pipeItem
    if hand and hand:getType() == "WaterPipe" then pipeItem = hand
    elseif inv:contains("WaterPipe") then pipeItem = inv:FindAndReturn("WaterPipe") end

    -- Fertigation (v1.2) : un barrel sur une case ciblée + un sac d'engrais/compost en inventaire.
    local barrelSq, hasCompost, hasFert
    if cfg.enableFertigation then
        for _, object in ipairs(worldobjects) do
            local sq = object.getSquare and object:getSquare() or nil
            if sq and PIP.findBarrelOnSquare(sq) then barrelSq = sq; break end
        end
        if barrelSq then
            hasCompost = PIPMenu.findFertItem(inv, "compost") ~= nil
            hasFert    = PIPMenu.findFertItem(inv, "fert") ~= nil
        end
    end
    local enrichAvail   = barrelSq and (hasCompost or hasFert)
    local showBarrelInfo = cfg.enableFertigation and barrelSq   -- ligne d'info (doses) meme sans sac

    -- Culture fertilisee/compostee sur une case ciblee ? (ligne d'info clic droit, v1.2). Affichee
    -- UNIQUEMENT si la culture a recu qqch (engrais a vie : fertilizer>0 ; compost ce cycle) -> pas de
    -- bruit sur les cultures non traitees. Lecture du modData de l'IsoObject (synchro client via
    -- stateToIsoObject:toModData + transmitModData).
    local cropFert, cropComp, showCropInfo = false, false, false
    if cfg.enableFertigation then
        for _, object in ipairs(worldobjects) do
            local sq = object.getSquare and object:getSquare() or nil
            local plant = (sq and sq.getFarmingPlant) and sq:getFarmingPlant() or nil
            local md = (plant and plant.getModData) and plant:getModData() or nil
            if md then
                local f = (type(md.fertilizer) == "number" and md.fertilizer > 0)
                local c = (md.compost == true or md.compost == "true")
                if f or c then cropFert, cropComp, showCropInfo = f, c, true; break end
            end
        end
    end

    if not pipeItem and not removeTarget and not enrichAvail and not showBarrelInfo and not showCropInfo then return end

    local top = context:addOption(getText("ContextMenu_PIP_IrrigationPipe"), worldobjects, nil)
    local sub = context:getNew(context)
    context:addSubMenu(top, sub)

    if showBarrelInfo then
        local bx, by, bz = barrelSq:getX(), barrelSq:getY(), barrelSq:getZ()
        -- (a) ligne d'info non-cliquable : doses stockees dans CE baril. Lu sur le modData de l'IsoObject
        -- (sync FIABLE en MP via transmitModData ; le store global ModData ne sync pas vers les clients).
        local barrel = PIP.findBarrelOnSquare(barrelSq)
        local bmd = (barrel and barrel.getModData) and barrel:getModData() or nil
        local cf = (bmd and tonumber(bmd.PIP_ff)) or 0
        local cc = (bmd and tonumber(bmd.PIP_fc)) or 0
        local info = sub:addOption(getText("ContextMenu_PIP_StoredDoses", tostring(math.floor(cf)), tostring(math.floor(cc))), worldobjects, nil)
        info.notAvailable = true
        if hasCompost then
            sub:addOption(getText("ContextMenu_PIP_PourCompost"), worldobjects, PIPMenu.onEnrich, player, bx, by, bz, "compost")
        end
        if hasFert then
            sub:addOption(getText("ContextMenu_PIP_PourFertilizer"), worldobjects, PIPMenu.onEnrich, player, bx, by, bz, "fert")
        end
    end

    if showCropInfo then
        -- Pas de glyphes ✓/✗ (la police PZ ne les rend pas). On affiche directement ce qui est fait
        -- (la ligne n'apparait que si fertilisee et/ou compostee).
        local key = (cropFert and cropComp) and "ContextMenu_PIP_CropBoth"
            or (cropFert and "ContextMenu_PIP_CropFertilized" or "ContextMenu_PIP_CropComposted")
        local cinfo = sub:addOption(getText(key), worldobjects, nil)
        cinfo.notAvailable = true   -- ligne d'info non-cliquable
    end

    if removeTarget then
        sub:addOption(getText("ContextMenu_PIP_RemovePipe"), worldobjects, PIPMenu.onRemove, player, removeTarget, removeSquare, 30)
        -- highlight reseau : 100% client-side (BFS visible), donc dispo en SP/host/dedie sans PIP.Network.
        sub:addOption(getText("ContextMenu_PIP_ShowNetwork"), worldobjects, PIPMenu.onShowNetwork, player,
            removeSquare:getX(), removeSquare:getY(), removeSquare:getZ())
        if PIP.UI and PIP.UI.isActive and PIP.UI.isActive() then
            sub:addOption(getText("ContextMenu_PIP_HideNetwork"), worldobjects, PIPMenu.onHideNetwork)
        end
    end

    if pipeItem then
        local placeOpt = sub:addOption(getText("ContextMenu_PIP_PlacePipe"), worldobjects, nil)
        local shapes = sub:getNew(sub)
        context:addSubMenu(placeOpt, shapes)
        local function addShape(key, ptype)
            local sprite = PIP.SPRITE_BY_TYPE[ptype]
            local label = getText(key)
            local o = shapes:addOption(label, worldobjects, PIPMenu.onPlace, player, pipeItem, sprite, ptype)
            local tt = ISWorldObjectContextMenu.addToolTip()
            tt:setTexture(sprite); tt.description = label
            o.toolTip = tt
        end
        addShape("ContextMenu_PIP_LineEW",   "lineOption")
        addShape("ContextMenu_PIP_LineNS",   "lineOption2")
        addShape("ContextMenu_PIP_Cross",    "crossOption")
        addShape("ContextMenu_PIP_CornerNE", "neOption")
        addShape("ContextMenu_PIP_CornerNW", "nwOption")
        addShape("ContextMenu_PIP_CornerSE", "seOption")
        addShape("ContextMenu_PIP_CornerSW", "swOption")
        addShape("ContextMenu_PIP_TNorth",   "tnOption")
        addShape("ContextMenu_PIP_TSouth",   "tsOption")
        addShape("ContextMenu_PIP_TEast",    "teOption")
        addShape("ContextMenu_PIP_TWest",    "twOption")
    end
end

Events.OnFillWorldObjectContextMenu.Add(PIPMenu.doMenu)
