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
    -- Identidade de ENGINE: nao faz sentido no ModData (o copyFrom apaga o ModData de qualquer jeito, e o cao
    -- RESPAWNADO ganha um animalId NOVO no init). Vive so no snapshot, que o kennelSnapshot pos-respawn refresca.
    data.animalId = nil
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

-- ADOCAO POR PROVA (anti-gemeo). O drop de um cao carregado reconstroi o animal via copyFrom, que APAGA o
-- getModData(): o cao continua vivo e ao lado do dono, mas sem vinculo e invisivel a todo predicado do mod
-- (todos casam por isCompanion/uid/companionToken, que moram no ModData apagado). Ate aqui o unico desfecho era
-- declarar "Perdido" e, no Trazer, RESPAWNAR -- o gemeo permanente do relato de duplicacao. Isto procura o cao
-- FISICO e recarimba o vinculo NELE, em vez de cunhar um segundo.
--
-- NAO e a adocao por fingerprint (breed+sexo) descartada no projeto: aquela ADIVINHAVA. A chave aqui e o
-- animalId, id de ENGINE que sobrevive ao copyFrom (IsoAnimal:1914) E ao save/load (o load chama init(), que
-- sorteia um id novo, e a linha SEGUINTE o sobrescreve com o valor salvo -- :1336/:1338), gravado no canil
-- enquanto o cao comprovadamente era do dono. Regras duras: sem animalId no snapshot (save antigo) NAO ha
-- fallback nenhum, recusa; familia de mesh entra como gate ADICIONAL e conjuntivo (o espaco e so
-- Rand.Next(10000) -- :1421 --, entao o id sozinho nao basta pra carimbar em cima de um cao selvagem qualquer);
-- dois candidatos casando (colisao de id) = recusa em ambos. So olha cao SEM vinculo: companion (seu ou de outro
-- player) nunca e alvo. E so roda ONDE O RESPAWN JA RODARIA -- nunca cria um cao, so evita que um seja criado.
--
-- maxDist (opcional) limita a busca a um raio ao redor do dono. O Trazer NAO passa (o jogador pediu de proposito, e
-- o cao pode estar em qualquer canto da cell); o reaper de fantasma passa, porque age sozinho e em silencio: acao
-- automatica leva o gate mais duro que a acao explicita.
CD.adoptByAnimalId = function(player, tok, snap, maxDist)
    if not player or tok == nil or type(snap) ~= "table" then return nil end
    local want = snap.animalId
    if want == nil then
        if CD.ADOPT_DEBUG then
            print(string.format("[CD-ADOPT] token=%s sem animalId no snapshot (save anterior ao campo): recusa, sem fallback",
                tostring(tok)))
        end
        return nil
    end
    local cell = getCell()
    if not cell then return nil end
    local list = nil
    pcall(function() list = cell:getAnimals() end)
    if not list then return nil end
    -- Compara a FAMILIA de mesh (typePrefix), nao a key de raca: num cao sem ModData o CD.getBreed cai pro
    -- byType, que colapsa racas irmas da mesma mesh -- exigir a key exata recusaria adocao legitima.
    local wantFam = CD.BREEDS[snap.breed] and CD.BREEDS[snap.breed].typePrefix
    local px, py = player:getX(), player:getY()
    local found = nil
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if a and CD.isDog(a) and not CD.isCompanion(a) then
            local aid, hp, sq = nil, 0, nil
            pcall(function() aid = a:getAnimalID(); hp = a:getHealth(); sq = a:getSquare() end)
            local fam = CD.BREEDS[CD.getBreed(a)] and CD.BREEDS[CD.getBreed(a)].typePrefix
            local near = maxDist == nil
                or (math.abs(a:getX() - px) <= maxDist and math.abs(a:getY() - py) <= maxDist)
            local ok = aid == want and hp > 0 and sq ~= nil and near
                and (wantFam == nil or fam == nil or wantFam == fam)
            if CD.ADOPT_DEBUG then
                print(string.format("[CD-ADOPT] token=%s candidato aid=%s(quero %s) fam=%s(quero %s) hp=%.0f perto=%s -> %s",
                    tostring(tok), tostring(aid), tostring(want), tostring(fam), tostring(wantFam),
                    hp or 0, maxDist == nil and "s/limite" or tostring(near), ok and "CASOU" or "recusado"))
            end
            if ok then
                if found then
                    -- Colisao de id (o espaco e so 10 mil): com dois corpos elegiveis nao ha como saber qual e o
                    -- seu, e carimbar no errado seria pior que respawnar. Recusa os dois e deixa o caller seguir.
                    if CD.ADOPT_DEBUG then
                        print(string.format("[CD-ADOPT] token=%s AMBIGUO: 2 caes sem vinculo casaram aid=%s, nao carimba em nenhum",
                            tostring(tok), tostring(want)))
                    end
                    return nil
                end
                found = a
            end
        end
    end
    if not found then
        if CD.ADOPT_DEBUG then
            print(string.format("[CD-ADOPT] token=%s nenhum cao sem vinculo casou aid=%s: caller segue pro caminho antigo",
                tostring(tok), tostring(want)))
        end
        return nil
    end

    local pd = CD.playerData(player)
    pcall(function() found:getModData().CompanionDogs = recFromKennelSnap(player, pd, tok, snap).data end)
    if not CD.isCompanion(found) then return nil end   -- carimbo falhou: nada feito, o caller segue o caminho antigo
    pcall(function() found:setWild(false) end)
    pcall(function() found:setShootable(false) end)
    pcall(function() found:setIsInvincible(true) end)   -- copyFrom nao copia invincible NEM shootable
    CD.transmit(found)
    if CD.hasBag(found) then pcall(function() CD.applyBagVisual(found) end) end
    pd.companions = pd.companions or {}
    pd.companions[tok] = true
    if pd.token == nil then pd.token = tok; pd.name = CD.data(found).name end
    CD.ensureUid(found)
    snap.uid = CD.data(found).uid   -- identidade compartilhada: se uma copia velha carregar depois, o reaper por uid a come
    if CD.bumpCanonical then CD.bumpCanonical(player, found) end
    snap.lost = nil
    if CD.kennelSnapshot then CD.kennelSnapshot(player, found) end
    pcall(function() player:transmitModData() end)
    return found
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
        -- Distingue "a adocao funcionou" de "a Camada 1 ja tinha resolvido e a adocao nem foi chamada": os dois
        -- terminam com um cao com vinculo na tela, entao so o log separa.
        if CD.ADOPT_DEBUG then
            print(string.format("[CD-ADOPT] Trazer token=%s: cao VIVO com vinculo ja na cell, teleporta (adocao nao foi consultada)",
                tostring(tok)))
        end
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
    -- Ultimo desvio antes do respawn: o cao pode estar VIVO e perto, so sem vinculo (drop -> copyFrom). Recarimbar
    -- nele resolve o Trazer sem cunhar um gemeo. Dai pra frente e identico ao ramo do cao vivo la em cima --
    -- inclusive o gate de lealdade no carimbo do cooldown (o teleport recusa desleal, nao gasta a chamada) e a
    -- notificacao, que o proprio CD.Server.teleport emite.
    local orphan = CD.adoptByAnimalId(player, tok, snap)
    if orphan then
        if not CD.isDisloyal(orphan) then stampRecall(player, pd, tok, now) end
        CD.Server.teleport(player, { __animal = orphan })
        if CD.kennelSnapshot then CD.kennelSnapshot(player, orphan) end
        return
    end
    if not CD.respawnCompanion then return end

    -- Ponto onde o gemeo nasce. Se um orfao sem vinculo estiver por perto quando esta linha imprimir, a adocao
    -- deixou passar (id ausente/divergente, familia errada, ou dois candidatos) e vale investigar QUAL gate barrou.
    if CD.ADOPT_DEBUG then
        print(string.format("[CD-ADOPT] Trazer token=%s: caiu no RESPAWN (nenhum orfao casou) -- daqui sai um cao NOVO",
            tostring(tok)))
    end
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
