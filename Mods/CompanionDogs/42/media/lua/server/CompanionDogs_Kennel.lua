-- Recall do canil (tela "Meus Caes"): traz um companheiro por TOKEN, mesmo descarregado ou deletado por outro mod.
-- Arquivo proprio: Companion.lua esta no teto de 200 locals do Kahlua e Commands.lua so resolve animal CARREGADO.
local CD = CompanionDogs

CD.Server = CD.Server or {}

-- Duplicata file-local de proposito (convencao anti stale-cache de shared, ver Companion.lua/findCarriedDogItem):
-- companion vivo carregado com EXATAMENTE este token, cell-wide.
local function liveOwnedDogWithToken(player, tok)
    if tok == nil then return nil end
    local cell = getCell()
    if not cell then return nil end
    local list = cell:getAnimals()
    if not list then return nil end
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if CD.isDog(a) and CD.isCompanion(a) and CD.isOwnedBy(a, player)
           and CD.data(a).companionToken == tok then
            return a
        end
    end
    return nil
end

-- Monta o registro de crash-recovery (formato do respawnCompanion) a partir do snapshot do canil.
local function recFromKennelSnap(player, pd, tok, snap)
    local data = CD.deepCopy(snap)
    -- Campos so-do-snapshot nao pertencem ao d.* do cao.
    data.fp = nil
    data.savedAtMin = nil
    data.lost = nil
    data.x, data.y, data.z = nil, nil, nil
    data.age, data.hunger, data.thirst, data.hp = nil, nil, nil, nil
    data.lastKennelMin = nil
    data.recallAtMin = nil
    data.companion = true
    data.ownerName = player:getUsername()
    data.ownerKey = CD.ownerKey(player)
    data.companionToken = tok
    -- Sem cao ativo, o recuperado assume o posto (espelha adoptOrphan); pd.token so e escrito APOS o spawn dar certo.
    data.state = (pd.token == nil or tok == pd.token) and CD.STATE_FOLLOW or CD.STATE_STAY
    return {
        type = CD.breedAnimalType(data.breed, data.isPup and "pup" or data.sex),
        female = (data.sex == "female"),
        age = snap.age,
        hp = snap.hp,
        hunger = snap.hunger,
        thirst = snap.thirst,
        data = data,
    }
end

-- Carimba a chamada no snapshot (cooldown por cao). O kennelSnapshot posterior preserva campos desconhecidos do
-- snap, entao o carimbo sobrevive ao refresh; cria a entrada se o cao vivo ainda nao tinha (tier live de save antigo).
local function stampRecall(player, pd, tok, now)
    pd.kennel = pd.kennel or {}
    pd.kennel[tok] = pd.kennel[tok] or { companionToken = tok }
    pd.kennel[tok].recallAtMin = now
    pcall(function() player:transmitModData() end)
end

-- Trazer universal por token. Ordem: cooldown por cao (2h-jogo) -> vivo na cell -> teleport existente (gate de
-- lealdade incluso); no colo / no veiculo -> recusa (ja esta com o player, recall duplicaria); senao
-- respawn-from-kennel + bumpCanonical (a copia antiga, se existir num chunk descarregado, tem gen menor e e comida
-- pelo reaper quando carregar). SEM gate de lealdade no respawn: resgate de cao perdido, nao ordem de obediencia.
CD.Server.recall = function(player, args)
    if not player then return end
    local tok = args and tonumber(args.token)
    if tok == nil then return end
    local pd = CD.playerData(player)
    local snap = pd.kennel and pd.kennel[tok]
    -- Fallback do canil GLOBAL durável: um recall logo apos morte/reconexao pode chegar antes do reclaim throttled
    -- repovoar o pd.kennel. Semeia a entrada por-personagem a partir do global (keyed pela chave estavel do dono).
    if not snap and CD.kennelGlobalGet then
        local g = CD.kennelGlobalGet(CD.ownerKey(player))
        if g and g[tok] then
            pd.kennel = pd.kennel or {}
            pd.kennel[tok] = CD.deepCopy(g[tok])
            snap = pd.kennel[tok]
        end
    end

    -- Cooldown por cao entre chamadas (2h de jogo): o carimbo vive no snapshot (transmitido, a UI desabilita o botao).
    local now = CD.worldMinutes()
    local cd = CD.KENNEL_RECALL_COOLDOWN_MIN or 120
    if snap and snap.recallAtMin and (now - snap.recallAtMin) < cd then
        CD.notifyOwner(player, "refused", { reason = "recallcd", name = snap.name, breed = snap.breed })
        return
    end

    local live = liveOwnedDogWithToken(player, tok)
    if live then
        if not CD.isDisloyal(live) then stampRecall(player, pd, tok, now) end   -- teleport recusaria desleal; nao gasta a chamada
        CD.Server.teleport(player, { __animal = live })
        if CD.kennelSnapshot then CD.kennelSnapshot(player, live) end   -- posicao fresca + limpa .lost
        return
    end

    local ctok = pd.carried and pd.carried.data and pd.carried.data.companionToken
    if tok == ctok then
        CD.notifyOwner(player, "refused", { reason = "carried", name = snap and snap.name, breed = snap and snap.breed })
        return
    end
    local stok = pd.stash and pd.stash.data and pd.stash.data.companionToken
    if tok == stok then
        CD.notifyOwner(player, "refused", { reason = "invehicle", name = snap and snap.name, breed = snap and snap.breed })
        return
    end
    -- Trailer de animais: cao vivo fora da cell (vehicle:getAnimals()); respawnar aqui duplicaria. Em vez de
    -- recusar, EXTRAI de verdade (CD.trailerExtract: remocao pela sequencia da engine + re-attach do bond) e
    -- teleporta, como um cao vivo. Dono dirigindo -> recusa (pode ser o proprio comboio que reboca o trailer;
    -- nao teleportar o cao pra fora em movimento). Falha transitoria de extracao -> recusa, retry no proximo clique.
    if CD.tokenTrailered and CD.tokenTrailered(player, tok) then
        local driving = false
        pcall(function() driving = (CD.isMounted and CD.isMounted(player)) or player:getVehicle() ~= nil end)
        if not driving and CD.trailerExtract then
            local dog = CD.trailerExtract(player, tok)
            if dog then
                if not CD.isDisloyal(dog) then stampRecall(player, pd, tok, now) end
                CD.Server.teleport(player, { __animal = dog })
                if CD.kennelSnapshot then CD.kennelSnapshot(player, dog) end
                return
            end
        end
        CD.notifyOwner(player, "refused", { reason = "invehicle", name = snap and snap.name, breed = snap and snap.breed })
        return
    end

    if not snap then
        CD.notifyOwner(player, "refused", { reason = "nodata" })
        return
    end
    if not CD.respawnCompanion then return end

    local dog = CD.respawnCompanion(nil, player, recFromKennelSnap(player, pd, tok, snap))
    if not dog then
        CD.notifyOwner(player, "refused", { reason = "nodata" })
        return
    end
    -- ATENCAO: se o cao original estava parado numa cell nao-coloaded (interior do RV), este respawn cria uma 2a copia.
    if pd.token == nil then pd.token = tok; pd.name = CD.data(dog).name end
    CD.ensureUid(dog)
    snap.uid = CD.data(dog).uid   -- snapshot antigo sem uid passa a compartilhar a identidade cunhada agora
    if CD.bumpCanonical then CD.bumpCanonical(player, dog) end
    if CD.data(dog).isPup then
        pcall(function() dog:getData():setSizeForced(CD.PUPPY_SIZE) end)
    end
    pd.companions = pd.companions or {}
    pd.companions[tok] = true
    snap.lost = nil
    stampRecall(player, pd, tok, now)
    if CD.kennelSnapshot then CD.kennelSnapshot(player, dog) end
    CD.notifyOwner(player, "teleported", { id = dog:getOnlineID(), breed = CD.getBreed(dog) })
end
