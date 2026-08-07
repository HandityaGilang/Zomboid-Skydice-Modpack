local CD = CompanionDogs

-- Breeding / filhotes (Fase A). Reproducao 100% simulada em ModData: concepcao (CD.conceive), timer de gestacao
-- absoluto contra a idade do mundo (CD.tickGestation), e parto que sorteia a ninhada com genetica/ascendencia
-- blendadas (CD.whelpLitter). A engine so cuida do auto-crescimento de estagio (dogpup -> adulto). Server-only.
-- Ver breeding-rules.md.

-- Sorteia o tamanho da ninhada a partir da faixa litter da raca da MAE (vira-lata = ninhada maior).
function CD.rollLitterSize(dam)
    local r = CD.getBreedDef(dam).litter or { 1, 2 }
    local lo, hi = r[1], r[2]
    if hi < lo then hi = lo end
    return lo + ZombRand(0, hi - lo + 1)
end

-- Concepcao: fotografa o MACHO dentro da femea (genes/ascendencia/uid/nome/raca) pra ele poder descarregar/morrer
-- sem perder a heranca, e arma o timer absoluto de gestacao. gestMinutes opcional (debug usa curto). Server-only.
function CD.conceive(dam, sire, gestMinutes)
    if isClient() then return end
    if not dam or not sire then return end
    if CD.isPuppy(dam) or CD.isPuppy(sire) then return end   -- filhote nunca concebe (net final p/ todo caller)
    local d = CD.data(dam)
    local sd = CD.data(sire)
    d.pregnant = true
    d.gestEndMin = CD.worldMinutes() + (gestMinutes or CD.gestationMinutes())
    d.litterSize = CD.rollLitterSize(dam)
    d.sireGenes = CD.deepCopy(sd.genes)
    d.sireLineage = CD.deepCopy(CD.getLineage(sire))
    d.sireUid = CD.ensureUid(sire)
    d.sireName = sd.name
    d.sireBreed = CD.getBreed(sire)
    CD.transmit(dam)
end

-- ===== Aproximacao: a femea anda ate o macho antes de conceber ======================================

-- Acha um cao carregado pelo uid (onlineID muda no reload; o uid e estavel). Scan da cell.
function CD.findDogByUid(uid)
    if not uid then return nil end
    local cell = getCell()
    if not cell then return nil end
    local list = cell:getAnimals()
    if not list then return nil end
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if a and CD.isDog(a) and CD.data(a).uid == uid then return a end
    end
    return nil
end

-- Marca a femea pra ir ate o macho; tickBreedingApproach conduz e concebe ao chegar. Server-only.
function CD.startBreedingApproach(dam, sire)
    if isClient() then return end
    if not dam or not sire then return end
    if CD.isPuppy(dam) or CD.isPuppy(sire) then return end   -- filhote nunca cruza (rede de seguranca p/ todo caller, inclui debug)
    local d = CD.data(dam)
    d.breedTarget = CD.ensureUid(sire)     -- identidade estavel do macho
    d.breedTargetId = sire:getOnlineID()   -- atalho de resolucao por sessao
    d.breedSinceMin = CD.worldMinutes()
    d.breedPathTile = nil
    -- solta a fixacao passiva pra ela andar (tickCompanionInvincible ignora femeas com breedTarget)
    pcall(function()
        local b = dam:getBehavior()
        if b and b.setBlockMovement then b:setBlockMovement(false) end
    end)
    CD.transmit(dam)
end

-- Cancela a aproximacao (macho sumiu/longe/timeout); a femea volta ao normal.
function CD.abortBreeding(dam)
    if isClient() then return end
    local d = CD.data(dam)
    d.breedTarget = nil
    d.breedTargetId = nil
    d.breedSinceMin = nil
    d.breedPathTile = nil
    CD.transmit(dam)
end

-- Conduz uma femea com breedTarget ate o macho; concebe ao chegar, aborta no timeout/perda/leash.
function CD.driveBreedingApproach(female, now)
    local d = CD.data(female)
    if d.breedSinceMin and (now - d.breedSinceMin) > (CD.BREED_APPROACH_TIMEOUT_MIN or 10) then
        CD.abortBreeding(female); return
    end
    local sire = (d.breedTargetId and getAnimal(d.breedTargetId)) or CD.findDogByUid(d.breedTarget)
    if not sire or not CD.isDog(sire) or sire:isDead() then CD.abortBreeding(female); return end
    if math.floor(sire:getZ()) ~= math.floor(female:getZ()) or CD.dist2D(female, sire) > (CD.BREED_LEASH or 40) then
        CD.abortBreeding(female); return
    end
    if CD.dist2D(female, sire) <= (CD.BREED_RANGE or 2) then
        pcall(function() female:faceThisObject(sire) end)
        CD.conceive(female, sire, nil)
        d.breedTarget = nil; d.breedTargetId = nil; d.breedSinceMin = nil; d.breedPathTile = nil
        CD.transmit(female)
        local owner = CD.getOwnerPlayer(female)
        if owner then CD.notifyOwner(owner, "bred", { name = d.name }) end
        return
    end
    -- caminha ate o macho: solta o hold + pateia, re-emitindo SO quando o tile-alvo muda (re-emitir cancela o A* async)
    pcall(function()
        local b = female:getBehavior()
        if b and b.setBlockMovement then b:setBlockMovement(false) end
    end)
    local tile = math.floor(sire:getX()) .. "," .. math.floor(sire:getY())
    if d.breedPathTile ~= tile then
        d.breedPathTile = tile
        pcall(function() female:faceThisObject(sire) end)
        -- pathToLocation (coords) e mais seguro que pathToCharacter pra um ALVO animal (este e o fallback do followOwner)
        pcall(function() female:pathToLocation(sire:getX(), sire:getY(), sire:getZ()) end)
        pcall(function() female:setVariable("bPathfind", true) end)
    end
end

-- Varre os caes carregados e conduz os que estao indo cruzar. Chamado do companionTick (bloco pesado).
function CD.tickBreedingApproach()
    if isClient() then return end
    if not CD.breedingEnabled() then return end
    local cell = getCell()
    if not cell then return end
    local list = cell:getAnimals()
    if not list then return end
    local now = CD.worldMinutes()
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if a and CD.isDog(a) and CD.isCompanion(a) and CD.data(a).breedTarget then
            CD.driveBreedingApproach(a, now)
        end
    end
end

-- Parto: spawna a ninhada no tile da mae. Por filhote: blenda a ascendencia dos pais, sorteia o mesh ponderado por
-- ela, blenda os 4 genes do mod, e carimba pedigree. Re-clampa ao slot livre de cap AGORA (decisao: filhote conta no
-- limite desde o nascimento). Encerra a gravidez mesmo se 0 nasceram (cap cheio) pra a femea nao ficar presa prenhe.
function CD.whelpLitter(dam, owner)
    if isClient() then return end
    if not dam or not owner then return end
    local d = CD.data(dam)
    if not d.pregnant then return end

    local lim = CD.maxCompanions()
    local n = d.litterSize or 1
    if lim > 0 then
        local free = lim - CD.companionCount(owner)
        if free < 0 then free = 0 end
        if n > free then n = free end
    end

    local born = 0
    if n > 0 then
        local damGenes = d.genes
        local damLineage = CD.getLineage(dam)
        local sireGenes = d.sireGenes
        local sireLineage = d.sireLineage or { [d.sireBreed or CD.DEFAULT_BREED] = 1.0 }
        local damX, damY, damZ = dam:getX(), dam:getY(), dam:getZ()
        local damName = d.name
        local damUid = CD.ensureUid(dam)
        local damBreed = CD.getBreed(dam)
        local gen = (d.generation or 1) + 1

        for _ = 1, n do
            local lineage = CD.blendLineage(damLineage, sireLineage)
            local domKey = CD.lineageRoll(lineage)
            local sex = (ZombRand(0, 2) == 0) and "male" or "female"
            local pupType = CD.breedAnimalType(domKey, "pup")
            local pup = CD.spawnDog(damX, damY, damZ, pupType, CD.breedEngineName(domKey))
            if pup then
                -- recem-nascido: desfaz o randomizeAge do spawnDog (que sorteia idade aleatoria). IsoAnimal NAO tem
                -- setAge (so AnimalData), entao setAge no animal era no-op e o filhote nascia com idade aleatoria
                -- (e maturava em tempo aleatorio). setAgeDebug zera idade E hoursSurvived (daysSurvived deriva dele).
                pcall(function() if pup.setAgeDebug then pup:setAgeDebug(0) end end)
                -- nasce pequeno: escala fixa de filhote (pinada por tickCompanionInvincible ate a maturacao da Fase B).
                -- size vive no AnimalData (getData()), nao no IsoAnimal; setSizeForced ignora o clamp min/max do tipo
                -- (setSize estouraria pra cima ate o minSize da raca, deixando o filhote grande).
                pcall(function()
                    local dt = pup:getData()
                    if dt and dt.setSizeForced then dt:setSizeForced(CD.PUPPY_SIZE or 0.6) end
                end)
                CD.makePuppy(pup, owner, {
                    genes        = CD.blendGenes(damGenes, sireGenes, lineage),
                    lineage      = lineage,
                    breed        = domKey,
                    sex          = sex,
                    generation   = gen,
                    motherUid    = damUid,
                    fatherUid    = d.sireUid,
                    motherName   = damName,
                    fatherName   = d.sireName,
                    motherBreed  = damBreed,
                    fatherBreed  = d.sireBreed,
                })
                CD.transmit(pup)
                born = born + 1
            end
        end
    end

    d.pregnant = nil
    d.gestEndMin = nil
    d.litterSize = nil
    d.sireGenes = nil
    d.sireLineage = nil
    d.sireUid = nil
    d.sireName = nil
    d.sireBreed = nil
    d.lastWhelpMin = CD.worldMinutes()
    CD.transmit(dam)
    pcall(function() owner:transmitModData() end)
    CD.notifyOwner(owner, "whelped", { count = born, name = d.name })
end

-- Avanca a gestacao: varre os caes carregados, e qualquer femea companheira com a gestacao vencida (stamp absoluto)
-- pari. Coleta antes de parir (whelp adiciona animais a cell -> nao mexer na lista durante a iteracao). Adia se o
-- dono esta offline (precisa do player pra contabilizar pd.companions/cap e transmitir). Chamado do companionTick.
function CD.tickGestation()
    if isClient() then return end
    if not CD.breedingEnabled() then return end
    local cell = getCell()
    if not cell then return end
    local list = cell:getAnimals()
    if not list then return end
    local now = CD.worldMinutes()
    local due
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if a and CD.isDog(a) and CD.isCompanion(a) then
            local d = CD.data(a)
            if d.pregnant and d.gestEndMin and now >= d.gestEndMin then
                due = due or {}
                due[#due + 1] = a
            end
        end
    end
    if not due then return end
    for _, dam in ipairs(due) do
        local owner = CD.getOwnerPlayer(dam)
        if owner then CD.whelpLitter(dam, owner) end
    end
end
