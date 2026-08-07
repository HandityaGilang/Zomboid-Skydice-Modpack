-- PIPCommands.lua (SERVER) — handlers MP des commandes client.
-- En MP dédié, le client pose l'objet (transmis) puis envoie 'pipePlaced' ; le serveur enregistre.

require "PIP/PIPShared"

-- Rend UNE WaterPipe au joueur de façon AUTORITAIRE (côté serveur).
-- ⚠️ Ne JAMAIS se contenter d'un AddItem côté client (ancien 'givePipe') : sur dédié — et pour un joueur
-- DISTANT d'un listen-host — l'inventaire est server-authoritative, donc un item ajouté seulement chez le
-- client est inconnu du serveur et DISPARAÎT à la reconnexion (constaté en jeu 2026-07-30 : pipe bien
-- retirée du sol, mais plus dans l'inventaire après déco/reco).
-- C'est le pendant exact du retrait autoritaire déjà fait pour 'placePipe' ci-dessous : le principe était
-- appliqué pour CONSOMMER un item, pas pour en RENDRE un.
-- Idiome vanilla : AddItem serveur PUIS sendAddItemToContainer (FishingNet.lua:74, camping_tent.lua:194).
local function givePipeTo(player)
    if not (player and player:getInventory()) then return end
    local inv = player:getInventory()
    local it = inv:AddItem("PIP.WaterPipe")
    if it and sendAddItemToContainer then sendAddItemToContainer(inv, it) end
    PIP.dbg("givePipeTo (server, autoritaire) ->", tostring(it ~= nil))
end

local function onClientCommand(module, command, player, args)
    if module ~= "PIP" then return end
    if isClient() and not isServer() then return end
    PIP.dbg("server OnClientCommand recu: "..tostring(command))
    if command == "placePipe" and args then
        -- création AUTORITAIRE côté serveur (l'item a déjà été consommé côté client dans l'action).
        -- Validation : joueur à portée (anti-grief) + case libre. Sur TOUT refus -> REFUND via givePipeTo
        -- (sinon item perdu : ex. 2 joueurs posent sur la même case, le 2e SKIP sans rien récupérer).
        local sq = getSquare(args.x, args.y, args.z)
        local sprite = args.pipeType and PIP.SPRITE_BY_TYPE[args.pipeType]
        local nearOk = (not player) or PIP.playerNearby(player, args.x, args.y, args.z)   -- fail-open si player nil (SP)
        if sq and sprite and nearOk and not PIP.findPipeObject(sq) then
            local obj = IsoObject.new(sq, sprite, PIP.OBJ_NAME)
            local md = obj:getModData()
            md.PIP_isPipe = true
            md.PIP_pipeType = args.pipeType
            sq:AddTileObject(obj)
            obj:transmitCompleteItemToClients()        -- sync serveur -> clients
            if PIP.Placement and PIP.Placement.registerPipe then
                PIP.Placement.registerPipe(obj)
            end
            -- Retrait AUTORITAIRE serveur (dedie) : le Remove client-side de PIPPlaceAction ne persiste
            -- pas dans l'inventaire server-authoritative -> sinon les pipes reapparaissent a la reco (dup).
            -- isLocalPlayer = SP/host (le joueur local a deja retire cote client) -> ne pas re-retirer.
            if player and not player:isLocalPlayer() and player:getInventory() then
                player:getInventory():Remove("WaterPipe")
            end
            PIP.dbg("placePipe (server) OK", args.pipeType, args.x, args.y, args.z)
        else
            PIP.dbg("placePipe (server) REFUS+refund sq="..tostring(sq))
            givePipeTo(player)
        end
    elseif command == "removePipe" and args then
        if player and not PIP.playerNearby(player, args.x, args.y, args.z) then return end   -- anti-grief MP (fail-open si player nil SP ; aucun item consommé -> pas de refund)
        local sq = getSquare(args.x, args.y, args.z)
        local obj = sq and PIP.findPipeObject(sq)
        if obj then
            PIP.removePipeObject(obj)
            -- item rendu SEULEMENT apres retrait reel (autoritaire) -> pas de dup si 2 joueurs visent la meme pipe
            givePipeTo(player)
        end
    elseif command == "enrich" and args then
        -- Fertigation (v1.2) : ajoute des charges (engrais/compost) au barrel SI relié a un reseau.
        -- Sinon REFUND l'item (deja consomme cote client, comme placePipe). Anti-grief : joueur a portee.
        -- Valide kind ∈ {compost,fert} (anti-commande malformee -> sinon refund). [audit 2026-06-10]
        local validKind = (args.kind == "compost" or args.kind == "fert")
        local barrel = validKind and PIP.Barrels.fetchAt(args.x, args.y, args.z) or nil
        local nearOk = (not player) or PIP.playerNearby(player, args.x, args.y, args.z)
        local gid = barrel and PIP.Barrels.groupId(barrel) or nil
        if barrel and nearOk and gid and gid > 0 then
            -- Consommation AUTORITAIRE serveur d'UNE dose (dedie = joueur distant). En SP/host le joueur
            -- local a deja consomme la dose dans perform (isLocalPlayer). useOneDrainable applique le
            -- ReplaceOnDeplete cote serveur (EmptySandbag compost rendu au joueur) -> sync au client.
            -- Pas de dose disponible -> pas de charges (sac epuise entre-temps).
            -- Anti-spoof (audit 2026-06-27) : on derive le type ATTENDU de `kind` (deja valide {compost,fert})
            -- au lieu de faire confiance a `args.shortType` (fourni par le client). Cote legitime fertMatches
            -- ne produit que CompostBag/Fertilizer -> equivalent ; bloque un client modifie qui ferait
            -- compter un autre Drainable (de moindre valeur) comme une dose de compost/engrais.
            local expected = (args.kind == "compost") and "CompostBag" or "Fertilizer"
            local consumed = true
            if player and not player:isLocalPlayer() then
                consumed = PIP.useOneDrainable(player:getInventory(), expected)
            end
            if consumed then
                local cfg = PIP.getConfig()
                PIP.Barrels.addCharges(barrel, args.kind, cfg.chargesPerBag)
                PIP.dbg("enrich OK", tostring(args.kind), args.x, args.y, args.z, "gid="..tostring(gid))
                -- Feedback (c) : confirme au joueur le versement (halo "+N doses"), fiable (apres ajout reel).
                if player then sendServerCommand(player, 'PIP', 'enriched', { n = cfg.chargesPerBag }) end
            end
        else
            -- Barrel non relie / hors portee : aucune consommation optimiste cote client -> rien a refund, halo seul.
            PIP.dbg("enrich REFUS (barrel non relie/hors portee)")
            if player then sendServerCommand(player, 'PIP', 'notConnected', {}) end
        end
    end
end

Events.OnClientCommand.Add(onClientCommand)
