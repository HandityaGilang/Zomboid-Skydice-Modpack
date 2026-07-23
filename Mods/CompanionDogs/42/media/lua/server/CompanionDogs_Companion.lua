local CD = CompanionDogs

local function worldMinutes()
    return getGameTime():getWorldAgeHours() * 60
end

-- Define a fome/sede do companheiro com o fallback CharacterStat-ou-setter-legado, protegido pra um handle obsoleto nao estourar.
local function setNeed(animal, kind, value)
    pcall(function()
        local stats = animal:getStats()
        if kind == "thirst" then
            if CharacterStat then stats:set(CharacterStat.THIRST, value)
            elseif stats.setThirst then stats:setThirst(value) end
        else
            if CharacterStat then stats:set(CharacterStat.HUNGER, value)
            elseif stats.setHunger then stats:setHunger(value) end
        end
    end)
end

local function emitSound(animal, sound)
    if isServer() then
        sendServerCommand(CD.MODULE, "sound", { id = animal:getOnlineID(), sound = sound })
    else
        CD.playAnimalSound(animal, sound)
    end
end

-- Para um som pelo nome em todo client (espelho de emitSound). Os clips de comer/beber (CDDogEat/CDDogDrink) fazem LOOP, e
-- playSound nunca para sozinho, entao um play one-shot ficaria em loop pra sempre depois que o cao termina. Iniciamos
-- ele ao entrar no estado "eating" e paramos aqui ao sair (setAutoFeedTag e o unico ponto de estrangulamento pra isso).
local function emitStopSound(animal, sound)
    if isServer() then
        sendServerCommand(CD.MODULE, "stopsound", { id = animal:getOnlineID(), sound = sound })
    else
        CD.stopAnimalSound(animal, sound)
    end
end

-- NOTA: animais sempre renderizam. setInvisible/alpha NAO suprimem o modelo de um IsoAnimal (a engine forca
-- o alpha de volta pra 1.0 em checkAlphaAndTargetAlpha, e o caminho de render ignora a flag invisible). Entao enquanto
-- o dono dirige, o cao e DELETADO (ver stashMounted) e respawnado ao descer, em vez de escondido no
-- lugar. Esse e o unico jeito de ele ficar invisivel pra todo player em qualquer zoom, inclusive pela rede em MP.

-- Consolidadas numa tabela unica pelo limite de 200 locals do Kahlua no chunk principal (estourar = arquivo inteiro nao compila).
local pendingClears = { anim = {}, eat = {}, idle = {} }
local lastAttackVar = {}
local idleVarNext = {}
local lastIdleVar = {}
local restState, calmSince, restBeat = {}, {}, {}

-- Escolhe de `vars` garantidamente diferente de `last` (alternancia estrita, sem chance de repetir); cai pro var unico.
local function pickDistinct(vars, last)
    if #vars <= 1 then return vars[1] end
    local i = ZombRand(#vars) + 1
    if vars[i] == last then i = (i % #vars) + 1 end
    return vars[i]
end

-- A alternancia seta um var DIFERENTE por mordida; limpa TODOS eles antes de setar um pra que dois nunca fiquem true ao mesmo tempo
-- (um var vazado = pose de ataque travada pra sempre). Limpar um var ja false e inofensivo.
local function clearAttackVars(animal)
    local vars = CD.ATTACK_ANIM_VARS or { CD.ATTACK_ANIM_VAR }
    for i = 1, #vars do
        pcall(function() animal:setVariable(vars[i], false) end)
    end
end

local function setAttackVar(animal, on, var)
    clearAttackVars(animal)
    if on then pcall(function() animal:setVariable(var or CD.ATTACK_ANIM_VAR, true) end) end
end

-- A anim de comer e um bool que o animNode cdEat usa pra tocar Rac_Eat. A animacao e do lado do client, entao a transmite pra todo client
-- (espelho de emitSound/emitAnim); num listen host o proprio client do host recebe o comando e a toca. Usada tanto
-- de forma SUSTENTADA (dwell de auto-feed, alternado por setAutoFeedTag) quanto como PULSO temporizado (feed-na-mao/domar, ver CD.pulseEatAnim).
local function emitEatVar(animal, on, var)
    var = var or CD.EAT_ANIM_VAR
    if isServer() then
        sendServerCommand(CD.MODULE, "animvar", { id = animal:getOnlineID(), var = var, on = on and true or false })
    else
        pcall(function() animal:setVariable(var, on and true or false) end)
    end
end

-- Variacao de idle. A alternancia de idle nativa (BaseAnimalBehavior.wanderIdle) nunca roda num companheiro (early-out de blockMovement,
-- decompilado), entao a gente conduz a variedade de idle parado: quando alcancado + calmo o cao ocasionalmente toca um
-- variante aleatorio (cdIdle2/cdIdle3 -> Rac_Idle02/03) e depois limpa de volta pro idle base. Mesmo padrao de bool cosmetico do cdEat;
-- reutiliza emitEatVar (broadcast generico "animvar") pra que SP+MP renderizem.
local function updateIdleVariation(animal)
    if not CD.IDLE_ANIM_ENABLED then return end
    local vars = CD.IDLE_ANIM_VARS
    if not vars or #vars == 0 then return end
    local oid = animal:getOnlineID()
    if pendingClears.idle[oid] or restState[oid] then return end   -- ja tocando, ou descansando (cdRest e dono da pose)
    local now = getTimestampMs()
    local nxt = idleVarNext[oid]
    if nxt == nil then idleVarNext[oid] = now + ZombRand(CD.IDLE_GAP_MIN_MS, CD.IDLE_GAP_MAX_MS); return end
    if now < nxt then return end
    local var = pickDistinct(vars, lastIdleVar[oid])
    lastIdleVar[oid] = var
    emitEatVar(animal, true, var)
    pendingClears.idle[oid] = { animal = animal, deadlineMs = now + CD.IDLE_ANIM_MS, var = var }
    idleVarNext[oid] = now + CD.IDLE_ANIM_MS + ZombRand(CD.IDLE_GAP_MIN_MS, CD.IDLE_GAP_MAX_MS)
end

-- Derruba qualquer variante de idle ativo AGORA (chamado de letMove/emitAnim/setRest) pra que o clip de idle cosmetico nunca sobreponha um
-- walk, ataque, ou o sit (= "desliza/pose errada"). O clear temporizado em processAnimClears e o fallback quando em idle.
local function clearIdleVariation(animal)
    local oid = animal:getOnlineID()
    local e = pendingClears.idle[oid]
    if e then emitEatVar(animal, false, e.var); pendingClears.idle[oid] = nil end
end

-- Anim de deitar/descansar. O var BOOL cosmetico cdRest conduz nosso idle node customizado (cdRest.xml -> Rac_IdleLyingDown; clip ja
-- nos GLBs dos caes), espelhando cdEat/cdAttack. Nao da pra usar o idleAction="sit" da engine porque BaseAnimalBehavior.checkSit
-- forca-limpa o idleAction em companheiros (attachedPlayer) -> flicker. Transmitido feito emitEatVar pra que clients MP renderizem.
-- Disparado por borda a partir de restState (sem spam de rede por tick) + um reassert periodico (cobre um client entrando no alcance de render
-- no meio do descanso). calmSince impoe um dwell parado antes de deitar. (restState/calmSince/restBeat declarados la em cima.)

local function emitRestVar(animal, on)
    if isServer() then
        sendServerCommand(CD.MODULE, "animvar", { id = animal:getOnlineID(), var = CD.REST_ANIM_VAR, on = on and true or false })
    else
        pcall(function() animal:setVariable(CD.REST_ANIM_VAR, on and true or false) end)
    end
end

local function setRest(animal, on)
    local id = animal:getOnlineID()
    on = on and true or false
    if (restState[id] or false) ~= on then
        restState[id] = on
        if on then clearIdleVariation(animal) end   -- sentando: derruba qualquer variante de idle-em-pe remanescente
        emitRestVar(animal, on)
        restBeat[id] = worldMinutes()
    elseif on and worldMinutes() - (restBeat[id] or 0) >= (CD.REST_REASSERT_MIN or 2.0) then
        emitRestVar(animal, true)
        restBeat[id] = worldMinutes()
    end
end

-- Forca ficar em pe e quebra a sequencia de calma: usado por todo caminho de nao-descanso (movendo, combate, panico, auto-feed, ...)
-- pra que o dwell reinicie antes do cao poder deitar de novo (ex.: ele nao deita no instante em que volta de uma perseguicao).
local function standUp(animal)
    calmSince[animal:getOnlineID()] = nil
    setRest(animal, false)
end

-- Chamar SOMENTE dos holds genuinamente parados (Stay, ancora de Guard postada). Deita assim que calmo e idle passado o dwell;
-- levanta no momento em que uma ameaca e vista (alertTier), combate/retirada esta ativo, ou o cao esta ocupado em auto-feed.
local function updateRest(animal, d)
    if not CD.REST_ANIM_ENABLED then return end
    local id = animal:getOnlineID()
    if not (d.autoFeeding or d.inCombat or d.retreating) and d.alertTier == nil then
        calmSince[id] = calmSince[id] or worldMinutes()
        if worldMinutes() - calmSince[id] >= (CD.REST_DWELL_MIN or 1.0) then setRest(animal, true) end
    else
        standUp(animal)
    end
end

-- Toca o clip de comer num cao por uma janela curta, depois limpa automatico (a mastigada do feed-na-mao / domesticacao). Conduzido pelo server pra
-- que transmita pra todo client e funcione em SP; chamado de CD.Server.feed que cobre TANTO alimentar um companheiro quanto
-- alimentar um vira-lata pra domar. Exposto em CD pra que CompanionDogs_Commands consiga alcancar.
local function pulseFeedAnim(animal, var, silent)
    if not animal then return end
    emitEatVar(animal, true, var)
    -- Som curto do cao mastigando/lambendo junto com o pulso; para os dois nomes antes pra nunca empilhar dois loops.
    -- `silent` = pulso usado como POSE (farejar/rastreio, cabeca baixa), nao como refeicao: so a anim, sem som.
    local snd = nil
    if not silent then
        snd = (var == CD.DRINK_ANIM_VAR) and CD.FEED_SOUNDS.water or CD.FEED_SOUNDS.food
        emitStopSound(animal, CD.FEED_SOUNDS.food)
        emitStopSound(animal, CD.FEED_SOUNDS.water)
        pcall(function() emitSound(animal, snd) end)
    end
    pcall(function()
        pendingClears.eat[animal:getOnlineID()] = { animal = animal, deadlineMs = getTimestampMs() + (CD.HANDFEED_EAT_MS or 3000), var = var, sound = snd }
    end)
end
function CD.pulseEatAnim(animal, silent) pulseFeedAnim(animal, CD.EAT_ANIM_VAR, silent) end
function CD.pulseDrinkAnim(animal, silent) pulseFeedAnim(animal, CD.DRINK_ANIM_VAR, silent) end
-- Pose de farejar (aponto de caca / ponto de forrageio). Sempre silenciosa: e um gesto, nao uma refeicao.
function CD.pulseSniffAnim(animal) pulseFeedAnim(animal, CD.SNIFF_ANIM_VAR, true) end

local function processAnimClears()
    local now
    for id, e in pairs(pendingClears.anim) do
        now = now or getTimestampMs()
        if now >= e.deadlineMs then
            setAttackVar(e.animal, false, e.var)
            pendingClears.anim[id] = nil
        end
    end
    for id, e in pairs(pendingClears.eat) do
        now = now or getTimestampMs()
        if now >= e.deadlineMs then
            emitEatVar(e.animal, false, e.var)
            if e.sound then pcall(function() emitStopSound(e.animal, e.sound) end) end
            pendingClears.eat[id] = nil
        end
    end
    for id, e in pairs(pendingClears.idle) do
        now = now or getTimestampMs()
        if now >= e.deadlineMs then
            emitEatVar(e.animal, false, e.var)
            pendingClears.idle[id] = nil
        end
    end
end

local function emitAnim(animal)
    if not CD.ATTACK_ANIM_ENABLED then return end
    clearIdleVariation(animal)
    local vars = CD.ATTACK_ANIM_VARS or { CD.ATTACK_ANIM_VAR }
    local oid = animal:getOnlineID()
    local var = pickDistinct(vars, lastAttackVar[oid])
    lastAttackVar[oid] = var
    if isServer() then
        sendServerCommand(CD.MODULE, "anim", { id = oid, var = var })
    else
        setAttackVar(animal, true, var)
        pendingClears.anim[oid] = { animal = animal, deadlineMs = getTimestampMs() + CD.ATTACK_ANIM_MS, var = var }
    end
end

-- O z:knockDown do lado do server nao replica; transmite a posicao do zumbi pra que clients derrubem a copia deles.
local function emitKnockdown(z)
    if isServer() then
        sendServerCommand(CD.MODULE, "knockdown", { zx = z:getX(), zy = z:getY(), zz = z:getZ() })
    else
        pcall(function() z:knockDown(false) end)
    end
end

local function eachOnlinePlayer(fn)
    if isServer() then
        local players = getOnlinePlayers()
        for i = 0, players:size() - 1 do fn(players:get(i)) end
    else
        local p = getPlayer()
        if p then fn(p) end
    end
end

-- Contabilidade de presenca do dono (acumulada por reconcileOwnerPresence abaixo). As necessidades de um companheiro sao conduzidas a mao pelo
-- relogio do mundo, que segue avancando no server enquanto o dono esta DESCONECTADO mesmo o cao nao sendo
-- processado, entao o primeiro upkeep apos reconectar de outra forma despejaria todo o intervalo offline (limitado a
-- UPKEEP_MAX_CATCHUP_MIN, ou seja, um pico de fome de 6h a cada retorno). Isto subtrai os minutos offline acumulados
-- de um intervalo decorrido pra que aquele trecho seja excluido. E um NO-OP sempre que o dono nao tem debito, que e o
-- caso durante TODO jogo online normal, INCLUSIVE dirigindo, entao nunca altera o acrescimo na estrada/fast-forward.
local function applyOfflineDebt(owner, elapsed)
    if not owner or elapsed <= 0 then return elapsed end
    local pd = CD.playerData(owner)
    local debt = pd.offlineDebtMin or 0
    if debt <= 0 then return elapsed end
    local use = debt < elapsed and debt or elapsed
    pd.offlineDebtMin = debt - use
    return elapsed - use
end

-- Supressao do auto-wander da engine. BaseAnimalBehavior.wanderIdle() (chamado a cada tick de AnimalIdleState /
-- AnimalWalkState) re-pathea um animal pra um square aleatorio dentro de +-8 tiles do attachedPlayer dele, SEM
-- nenhum gate de isWild()/companheiro (verificado por decomp CFR), entao um companheiro em STAY, alcancado, guardando-na-ancora ou
-- plantado e sequestrado e sai andando ("nao fica", "nao obedece quando perto", "segue erraticamente").
-- setBlockMovement(true) para o cao E levanta a flag blockMovement do behavior, que e o PRIMEIRO
-- early-out que wanderIdle checa, entao a engine para de auto-pathear ele. Os proprios pathToCharacter/
-- pathToLocation do mod ainda movem o cao: AnimalPathFindState / PathFindBehavior2.update ignoram a flag, e
-- wanderIdle nem chega a ser chamado enquanto um path esta executando (so nos estados Idle/Walk). Entao isto mata SO
-- o wander auto-iniciado da engine, nunca o follow/combate conduzido pelo mod. Re-afirmado a cada tick em que o cao deve
-- segurar (a flag limpa automatico depois de ~8000 game-units; o loop re-afirma bem antes).
local function holdStill(animal)
    pcall(function()
        local b = animal:getBehavior()
        if b and b.setBlockMovement then b:setBlockMovement(true) end
    end)
end

-- Contraparte de holdStill: limpa blockMovement pra que o cao possa ser MOVIDO pelo mod. DEVE ser chamado antes de qualquer
-- pathToCharacter/pathToLocation emitido pelo mod, porque holdStill() deixa blockMovement=true (e chamou
-- stopAllMovementNow). Se isso persistir, o cao acaba num estado de movimento sem path onde a engine o dirige por
-- root motion bruto em vez do pathfinder, o que o manda pro lado ERRADO ("sai andando / passo pra frente-pra tras").
-- setBlockMovement(false) so limpa a flag (sem parar), entao o novo path conduz o cao em direcao ao dono.
local function letMove(animal)
    clearIdleVariation(animal)
    pcall(function()
        local b = animal:getBehavior()
        if b and b.setBlockMovement then b:setBlockMovement(false) end
    end)
    -- O steer da cerca desliga o deferredMovement (root motion) pra conduzir na mao; a velocidade de um animal em PATH
    -- vem da magnitude do root motion, entao se ficar off o cao em path fica com velocidade ZERO (corre no lugar). Religa.
    pcall(function() if animal.setDeferredMovementEnabled then animal:setDeferredMovementEnabled(true) end end)
end

-- Correcao pra "sai andando enquanto encara pra frente": numa linha livre o pathToAux da engine (IsoGameCharacter) seta
-- bPathfind=false, movendo o cao por root motion bruto cujo sinal aponta PRA LONGE nos nossos clips GLB. Forcar bPathfind=true
-- depois de cada path do mod trava o node mover imune a sinal (PathFindBehavior2) que sempre vai em direcao ao dono.
local function forcePathfind(animal)
    pcall(function() animal:setVariable("bPathfind", true) end)
end

-- Simples "andar/correr o cao ate um tile": letMove -> seta vars de gait -> path -> forca o node mover. Os varios pontos de combate/parada
-- setam os vars inline (eles agrupam chamadas de face/stop/attack); isto cobre os chamadores limpos de ir-pra-um-local.
local function moveTo(animal, running, speed, x, y, z)
    letMove(animal)
    pcall(function()
        animal:setVariable("animalRunning", running)
        animal:setVariable("animalSpeed", speed)
        animal:pathToLocation(x, y, z)
    end)
    forcePathfind(animal)
end

-- ============ Salto de cerca baixa (o cao PULA uma cerca baixa pra seguir) ============
-- O trigger nativo de escalada quase nunca dispara durante o follow (o A* da engine conduz o cao EM VOLTA de uma cerca em vez
-- de colidir de frente), entao a gente detecta um cruzamento de forma PROATIVA e conduz um glide suave por OnTick atravessando.
-- climbOverFence() entra no estado nativo `climbfence`, que toca o clip Rac_ClimbUp, agora remodelado no
-- GLB com um ARCO de corpo em model-space (ver _replace_climb_clips.py) pra que o cruzamento PARECA um pulo. O arco e
-- deformacao de mesh (imune a gravidade da engine); este glide so carrega x/y. Ver memoria pz-b42-animal-fence-climb.
local fenceHopping = {}   -- onlineID -> animal, caes em meio ao glide; avancados a cada OnTick por tickFenceHops
local landStreaming = {}  -- onlineID -> {animal, untilMs}: janela de follow-stream pos-pouso (client desenha o caminho autoritativo)
local fenceSteering = {}  -- onlineID -> animal: caes conduzidos-na-mao ate a borda da cerca (driver por-tick, fonte continua p/ o stream)
local landGlide = {}      -- onlineID -> {animal, startMs, lastMs, probeMs, goodProbes, ox, oy, stillSince}: apos um hop o animador do SERVIDOR congela (peso do blend de locomocao preso em ~0 = root motion 0 = engine nao translada); conduzimos a posicao do cao na mao ate o dono e soltamos quando o engine recupera / o cao chega num dono parado.
local landSettling = {}   -- onlineID -> {animal, untilMs, lastMs}: apos um pouso, forca pacotes de posicao novos por uma
                          -- janela curta pra previsao Moving defasada (rumo a cerca) do cliente nao arrastar ele de volta. Ver tickFenceLandPush.

local FENCE_DIRS
local function fenceDirs()
    if not FENCE_DIRS then
        FENCE_DIRS = {
            { dx = 0, dy = -1, dir = IsoDirections.N }, { dx = 0, dy = 1, dir = IsoDirections.S },
            { dx = -1, dy = 0, dir = IsoDirections.W }, { dx = 1, dy = 0, dir = IsoDirections.E },
        }
    end
    return FENCE_DIRS
end

-- Chave sem ordem pra ARESTA de cerca compartilhada por dois tiles cardinalmente adjacentes (pra que A->B e B->A tenham o mesmo hash). Usada pra
-- proibir recruzar a mesma aresta por uma janela curta = a cura estrutural pro ping-pong A<->B.
local function edgeKey(ax, ay, bx, by)
    return string.format("%d:%d:%d:%d", math.min(ax, bx), math.min(ay, by), math.max(ax, bx), math.max(ay, by))
end

-- SO cerca BAIXA (Hoppable*): picket, trilho baixo, mureta, corrimao. Usa a posse de aresta da engine: a aresta OESTE
-- pertence ao square leste, a aresta NORTE ao square sul. Usado pelo vault de COMBATE e como base do fenceCrossable.
function CD.lowFenceCrossable(from, to, dx, dy)
    local ok = false
    pcall(function()
        if dx > 0 then     ok = to:has(IsoFlagType.HoppableW)
        elseif dx < 0 then ok = from:has(IsoFlagType.HoppableW)
        elseif dy > 0 then ok = to:has(IsoFlagType.HoppableN)
        else               ok = from:has(IsoFlagType.HoppableN)
        end
    end)
    return ok
end

-- PERMISSIVO: existe QUALQUER aresta hoppable aqui (baixa ou alta, saltavel ou nao)? Nao e decisao de travessia; serve
-- pra "tem cerca nesta aresta?" no calculo de overshoot do pouso, onde tratar um muro solido como "sem cerca" faria o
-- cao pousar um tile alem, atravessando o muro de graca.
local function fenceEdge(from, to, dx, dy)
    local ok = false
    pcall(function()
        if dx > 0 then     ok = to:has(IsoFlagType.HoppableW) or to:has(IsoFlagType.TallHoppableW)
        elseif dx < 0 then ok = from:has(IsoFlagType.HoppableW) or from:has(IsoFlagType.TallHoppableW)
        elseif dy > 0 then ok = to:has(IsoFlagType.HoppableN) or to:has(IsoFlagType.TallHoppableN)
        else               ok = from:has(IsoFlagType.HoppableN) or from:has(IsoFlagType.TallHoppableN)
        end
    end)
    return ok
end

-- O cao PODE cruzar a aresta cardinal de `from` pra `to` (passo dx,dy)? Duas familias:
--   1. cerca BAIXA (Hoppable*) -> sempre.
--   2. cerca de altura media VAZADA -> TallHoppable* E Wall*Trans no MESMO square dono da aresta. TallHoppable* sozinho
--      NAO basta: na engine ela nao quer dizer "cerca saltavel", quer dizer "muro escalavel", e cobre tanto o alambrado
--      (MetalWire, WallNTrans) e a grade de barras (MetalBars, WallNTrans) quanto o muro SOLIDO que o cao nao deve pular:
--      log wall de madeira redonda (walls_logs_*, carpentry_02_80-82), cerca alta de madeira (fencing_01_8-12, _72-75) e
--      chapa metalica (fencing_01_40-42) -- todos WallN/WallW opacos. O flag Trans e o que separa os dois grupos.
-- Pro ramo 2 a gente ainda espelha os gates do SquareUpdateTask.canClimbOverWall da engine (CantClimb, dentro de predio,
-- solido), que e o que impede escalar parede interna de casa. O alambrado industrial alto (fencing_01_48-53) ja cai fora
-- sozinho: tem CantClimb e NENHUMA flag hoppable.
local function fenceCrossable(from, to, dx, dy)
    if CD.lowFenceCrossable(from, to, dx, dy) then return true end
    if not CD.FENCE_HOP_TALL then return false end
    local ok = false
    pcall(function()
        local owner, tall, trans
        if dx > 0 then     owner, tall, trans = to,   IsoFlagType.TallHoppableW, IsoFlagType.WallWTrans
        elseif dx < 0 then owner, tall, trans = from, IsoFlagType.TallHoppableW, IsoFlagType.WallWTrans
        elseif dy > 0 then owner, tall, trans = to,   IsoFlagType.TallHoppableN, IsoFlagType.WallNTrans
        else               owner, tall, trans = from, IsoFlagType.TallHoppableN, IsoFlagType.WallNTrans
        end
        if not (owner:has(tall) and owner:has(trans)) then return end
        if from:has(IsoFlagType.CantClimb) or to:has(IsoFlagType.CantClimb) then return end
        if from:getBuilding() ~= nil or to:getBuilding() ~= nil then return end
        if from:isSolid() or from:isSolidTrans() or to:isSolid() or to:isSolidTrans() then return end
        ok = true
    end)
    return ok
end

-- Retorna dir, targetSquare, edgeKey quando saltar uma cerca BAIXA ou de ARAME-MEDIO do tile do cao pra um vizinho
-- cardinal deixa o cao MAIS PERTO do dono (ver fenceCrossable: Hoppable* + a cerca media VAZADA, nunca muro solido).
-- Pula qualquer aresta ainda dentro da janela de bloqueio-de-recruzamento (d.recrossUntilMs) pra que o cao nao volte por cima da
-- cerca que acabou de transpor; ele ainda pode cruzar uma aresta DIFERENTE neste mesmo tick.
local function findFenceCrossing(animal, ref, d, now, crossPred)
    local cur = animal:getCurrentSquare()
    if not cur then return nil end
    local cell = getCell()
    local cross = crossPred or fenceCrossable
    local ox, oy = ref:getX(), ref:getY()
    -- Mede a partir do CENTRO DO TILE do cao, nao da posicao fracionaria dele: a oscilacao sub-tile enquanto idle ao lado de uma
    -- cerca e o que fazia o teste "o lado de la esta mais perto?" inverter a cada frame (cruza / cruza de volta = pulo infinito).
    local cx, cy = cur:getX() + 0.5, cur:getY() + 0.5
    local curGap = (ox - cx) * (ox - cx) + (oy - cy) * (oy - cy)
    local minGain = CD.FENCE_HOP_MIN_GAIN or 0.05
    local blockedKey = (d and d.recrossUntilMs and now < d.recrossUntilMs) and d.recrossEdge or nil
    local bd = (d and d.backBlockUntilMs and now < d.backBlockUntilMs) and d.backBlockDir or nil   -- proibe reverter logo apos um salto
    for _, e in ipairs(fenceDirs()) do
        local adj = (not (bd and e.dx == bd.dx and e.dy == bd.dy))
            and cell:getGridSquare(cur:getX() + e.dx, cur:getY() + e.dy, cur:getZ()) or nil
        if adj then
            if cross(cur, adj, e.dx, e.dy) then
                local key = edgeKey(cur:getX(), cur:getY(), adj:getX(), adj:getY())
                local ax, ay = adj:getX() + 0.5, adj:getY() + 0.5
                -- exige uma melhora CLARA (margem), pra que um cruzamento marginal/igual nunca dispare; e o tile de
                -- pouso precisa ter chao (nunca saltar pra um tile suspenso -> queda da engine -> NPE de fallenOnKnees)
                if key ~= blockedKey and CD.squareHasFloor(adj)
                   and (ox - ax) * (ox - ax) + (oy - ay) * (oy - ay) <= curGap - minGain then
                    return adj, e.dx, e.dy, key
                end
            end
        end
    end
    return nil
end

-- Cruzamento FANTASMA: marcha cardinalmente do cao em direcao ao dono ate maxTiles. Retorna o tile distante + passo unitario +
-- edgeKey da PRIMEIRA cerca saltavel encontrada no caminho. Para (nil) numa parede solida / aresta nao-hoppable pra que a gente nunca
-- atravesse o cao por dentro de um predio. E isso que desprende o cao quando o A* o encaixotou: nao precisa do cao estar
-- cardinalmente adjacente: quando o cao trava seguindo, a gente acha a cerca bloqueadora e o desliza por cima.
local function findFenceTowardOwner(animal, ref, maxTiles, d, now, crossPred)
    local cur = animal:getCurrentSquare()
    if not cur then return nil end
    local cell = getCell()
    local cz = cur:getZ()
    local cross = crossPred or fenceCrossable
    local tx, ty = math.floor(ref:getX()), math.floor(ref:getY())
    local blockedKey = (d and d.recrossUntilMs and now < d.recrossUntilMs) and d.recrossEdge or nil
    local bd = (d and d.backBlockUntilMs and now < d.backBlockUntilMs) and d.backBlockDir or nil   -- proibe reverter logo apos um salto
    local ax, ay, aSq = cur:getX(), cur:getY(), cur
    for _ = 1, (maxTiles or 5) do
        local ddx, ddy = tx - ax, ty - ay
        if ddx == 0 and ddy == 0 then return nil end
        -- primario = eixo dominante em direcao ao dono; secundario = o outro eixo (se houver). Testa AMBOS por uma aresta
        -- saltavel a cada passo pra que uma cerca perpendicular a QUALQUER eixo seja achada: um cao andando PARALELO a uma cerca
        -- (dono fora da diagonal) costumava marchar passando do cruzamento e nunca saltar.
        local px, py = 0, 0
        if math.abs(ddx) >= math.abs(ddy) then px = (ddx > 0) and 1 or -1 else py = (ddy > 0) and 1 or -1 end
        local steps = { { px, py } }
        if ddx ~= 0 and px == 0 then steps[#steps + 1] = { (ddx > 0) and 1 or -1, 0 } end
        if ddy ~= 0 and py == 0 then steps[#steps + 1] = { 0, (ddy > 0) and 1 or -1 } end
        for _, s in ipairs(steps) do
            if not (bd and s[1] == bd.dx and s[2] == bd.dy) then
                local bSq = cell:getGridSquare(ax + s[1], ay + s[2], cz)
                if bSq and CD.squareHasFloor(bSq) and cross(aSq, bSq, s[1], s[2]) then
                    local key = edgeKey(aSq:getX(), aSq:getY(), bSq:getX(), bSq:getY())
                    if key ~= blockedKey then return bSq, s[1], s[2], key, aSq end   -- aSq = o tile de aproximacao do LADO PROXIMO
                end
            end
        end
        local nb = cell:getGridSquare(ax + px, ay + py, cz)   -- sem cruzamento aqui: avanca um tile ao longo do eixo primario
        if not nb then return nil end
        local wall = false   -- uma parede real (nao-hoppable) bloqueia a linha -> deixa o cao desviar, nao atravessa fantasma
        pcall(function() wall = aSq:isWallTo(nb) or nb:isSolid() or nb:isSolidTrans() end)
        if wall then return nil end
        ax, ay, aSq = ax + px, ay + py, nb
    end
    return nil
end

-- Flood de alcancabilidade (o teste de SE-deve-saltar). BFS no lado ATUAL do cao: tiles alcancaveis SEM cruzar uma
-- cerca saltavel ou parede real, limitado por REGION_RADIUS / REGION_MAX_TILES. Retorna ownerInside (o dono e
-- alcancavel neste lado afinal) e ownerDepth (quantos tiles tem o caminho EM VOLTA). O chamador salta a menos que o caminho
-- em volta seja curto. Alcancabilidade binaria nao tem sinal pra inverter (sem oscilacao); ownerDepth mantem o cao pulando cercas
-- longas em vez de caminhar ate um portao distante. Para cedo quando o dono e alcancado. Cacheado por tile-do-cao.
local function buildSideRegion(animal, owner, d, now)
    local cur = animal:getCurrentSquare()
    if not cur then return nil end
    local cz = cur:getZ()
    local sx, sy = cur:getX(), cur:getY()
    local dogKey = string.format("%d:%d:%d", sx, sy, cz)
    if d.region and d.region.stamp and (now - d.region.stamp) < (CD.REGION_TTL_MS or 300)
       and d.region.dogKey == dogKey then
        return d.region
    end
    local cell = getCell()
    local oTileKey = string.format("%d:%d", math.floor(owner:getX()), math.floor(owner:getY()))
    local radius = CD.REGION_RADIUS or 22
    local maxTiles = CD.REGION_MAX_TILES or 240
    local startKey = string.format("%d:%d", sx, sy)
    local visited = { [startKey] = true }
    local queue = { cur }
    local qdepth = { 0 }
    local qi, count, truncated = 1, 1, false
    local ownerInside = (startKey == oTileKey)
    local ownerDepth = ownerInside and 0 or nil
    while qi <= #queue and not ownerInside do        -- para quando o dono e alcancado (alcancavel -> mede o desvio)
        local sq = queue[qi]; local depth = qdepth[qi]; qi = qi + 1
        local cx0, cy0 = sq:getX(), sq:getY()
        for _, e in ipairs(fenceDirs()) do
            local nx, ny = cx0 + e.dx, cy0 + e.dy
            -- cercas crossable E paredes reais sao fronteiras (nao floodam atravessando); fica dentro do raio
            if math.abs(nx - sx) <= radius and math.abs(ny - sy) <= radius then
                local nkey = string.format("%d:%d", nx, ny)
                if not visited[nkey] then
                    local nb = cell:getGridSquare(nx, ny, cz)
                    if nb and not fenceCrossable(sq, nb, e.dx, e.dy) then
                        local wall = false
                        pcall(function() wall = sq:isWallTo(nb) or nb:isSolid() or nb:isSolidTrans() end)
                        if not wall and CD.squareHasFloor(nb) then
                            if count >= maxTiles then truncated = true
                            else
                                visited[nkey] = true
                                count = count + 1
                                queue[#queue + 1] = nb
                                qdepth[#qdepth + 1] = depth + 1
                                if nkey == oTileKey then ownerInside = true; ownerDepth = depth + 1 end
                            end
                        end
                    end
                end
            end
        end
    end
    d.region = { stamp = now, dogKey = dogKey, ownerInside = ownerInside, ownerDepth = ownerDepth, truncated = truncated }
    return d.region
end

-- Regiao de alcancabilidade do COMBATE (generaliza buildSideRegion): flood COMPLETO do lado do cao (sem early-stop no
-- dono), com porta fechada e VEICULO tambem como fronteira, retendo o set de tiles pro teste de pertencimento na
-- selecao de alvo (LOS nao e alcancabilidade: cerca/carro passam como "linha livre" no LosUtil). Cache proprio fora de
-- d.* (o set nao pode ir pro ModData: serializa/transmite) e SEM o gate isServer()/FENCE_REACH_MODE do follow: roda em
-- SP e server. "Nao-membro" so prova inalcancavel quando o flood terminou sem truncar e o tile esta dentro da janela;
-- fora disso o chamador trata como alcancavel (degrada pro comportamento antigo, nunca recusa alvo legitimo).
CD.combatRegionCache = {}
-- Cooldown de alvo inalcancavel (backstop, combat-plan item 6): por cao (onlineID), zumbi (ref do objeto) ->
-- deadline ms. Fora de d.* (refs de objeto Java nao podem ir pro ModData); poda preguicosa no scan.
CD.combatUnreach = {}
function CD.combatReachRegion(animal)
    local cur = animal:getCurrentSquare()
    if not cur then return nil end
    local now = getTimestampMs()
    local cz = cur:getZ()
    local sx, sy = cur:getX(), cur:getY()
    local aid = animal:getOnlineID()
    local dogKey = string.format("%d:%d:%d", sx, sy, cz)
    local c = CD.combatRegionCache[aid]
    if c and c.dogKey == dogKey and (now - c.stamp) < (CD.REGION_TTL_MS or 300) then return c end
    local cell = getCell()
    if not cell then return nil end
    local radius = CD.COMBAT_REGION_RADIUS or 12
    local maxTiles = CD.COMBAT_REGION_MAX_TILES or 700
    -- Uma cerca BAIXA (picket) e ATRAVESSAVEL no flood (o cao pula ela no combate) -> zumbi do outro lado vira
    -- alcancavel. Arame/muro: a cerca continua fronteira. SP sempre; servidor so com COMBAT_FENCE_HOP_MP (flag off =
    -- servidor trata toda cerca como fronteira, byte-identico ao antigo). Gate raiz com CD.COMBAT_FENCE_HOP.
    local vaultLow = CD.COMBAT_FENCE_HOP and ((not isServer()) or CD.COMBAT_FENCE_HOP_MP)
    local set = { [string.format("%d:%d", sx, sy)] = 0 }   -- valor = profundidade BFS (passos a pe); 0 no tile do cao
    local queue = { cur }
    local qi, count, truncated = 1, 1, false
    while qi <= #queue do
        local sq = queue[qi]; qi = qi + 1
        local cx0, cy0 = sq:getX(), sq:getY()
        local cd0 = set[string.format("%d:%d", cx0, cy0)] or 0
        for _, e in ipairs(fenceDirs()) do
            local nx, ny = cx0 + e.dx, cy0 + e.dy
            if math.abs(nx - sx) <= radius and math.abs(ny - sy) <= radius then
                local nkey = string.format("%d:%d", nx, ny)
                if not set[nkey] then
                    local nb = cell:getGridSquare(nx, ny, cz)
                    if nb then
                        if fenceCrossable(sq, nb, e.dx, e.dy) then
                            -- aresta de cerca: em SP o cao atravessa uma cerca BAIXA (picket) -> depth+1; arame/corrente
                            -- (TallHoppable) e servidor ficam como FRONTEIRA (o combate nao pula esses / nao pula em server)
                            if vaultLow and CD.lowFenceCrossable(sq, nb, e.dx, e.dy) and CD.squareHasFloor(nb) then
                                if count >= maxTiles then truncated = true
                                else
                                    set[nkey] = cd0 + 1
                                    count = count + 1
                                    queue[#queue + 1] = nb
                                end
                            end
                        else
                            local wall = false
                            pcall(function() wall = sq:isWallTo(nb) or nb:isSolid() or nb:isSolidTrans() end)
                            if not wall then
                                -- pcall separado: se uma das APIs faltar, a outra fronteira ainda vale
                                pcall(function()
                                    wall = (sq.isDoorBlockedTo ~= nil and sq:isDoorBlockedTo(nb))
                                        or (nb.isVehicleIntersecting ~= nil and nb:isVehicleIntersecting())
                                end)
                            end
                            if not wall and CD.squareHasFloor(nb) then
                                if count >= maxTiles then truncated = true
                                else
                                    set[nkey] = cd0 + 1
                                    count = count + 1
                                    queue[#queue + 1] = nb
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    c = { stamp = now, dogKey = dogKey, set = set, sx = sx, sy = sy, radius = radius, truncated = truncated }
    CD.combatRegionCache[aid] = c
    return c
end

-- Inicia o glide do salto da posicao ATUAL do cao ate um tile de pouso alem da cerca (toSq, ou um tile alem
-- em direcao ao dono pra um salto mais longo, nunca passando do dono). dx,dy e o passo unitario do cruzamento (funciona quer
-- toSq esteja adjacente ou varios tiles distante = o caso fantasma). Setamos ClimbFence=true pra que a engine toque o clip
-- climbfence (Rac_ClimbUp = o salto Jump_run enxertado) pro visual; tickFenceHops conduz X/Y + o arco Z e limpa a
-- flag no pouso (dispara-e-esquece, nunca dependendo do evento de anim ClimbDone). clearClimbVars primeiro mata qualquer resquicio.
local function startFenceHop(animal, toSq, dx, dy, owner, key)
    local d = CD.data(animal)
    CD.clearClimbVars(animal)
    pcall(function() animal:stopAllMovementNow() end)
    local cell = getCell()
    local fz = toSq:getZ()
    -- nunca pousa o cao num tile sem chao: a engine o trata como suspenso e roda o caminho de queda/pouso HUMANO no
    -- animal (fallenOnKnees -> addHole -> NPE a cada frame). Pula o hop e deixa o follow normal / o fall guard agir.
    if not CD.squareHasFloor(toSq) then return end
    local cx, cy, ex, ey = toSq:getX() + 0.5, toSq:getY() + 0.5, toSq:getX(), toSq:getY()
    local beyond = cell:getGridSquare(toSq:getX() + dx, toSq:getY() + dy, fz)
    local openBeyond = false
    pcall(function()
        -- fenceEdge (permissivo) + isWallTo, nao fenceCrossable: um muro que o cao NAO pode pular tambem tem que barrar o
        -- overshoot, senao o pouso estendido o atravessaria de graca.
        openBeyond = beyond ~= nil and not beyond:isSolid() and not beyond:isSolidTrans()
                     and not fenceEdge(toSq, beyond, dx, dy)
                     and not toSq:isWallTo(beyond)
                     and CD.squareHasFloor(beyond)
    end)
    if openBeyond and owner then
        local ox, oy = owner:getX(), owner:getY()
        local bx, by = beyond:getX() + 0.5, beyond:getY() + 0.5
        if (ox - bx) ^ 2 + (oy - by) ^ 2 < (ox - cx) ^ 2 + (oy - cy) ^ 2 then
            cx, cy, ex, ey = bx, by, beyond:getX(), beyond:getY()
        end
    end
    -- encara a direcao do cruzamento pra que o cao salte PRA FRENTE, nao de lado ("estatua de lado"); re-afirmado por tick
    local dir = (dx > 0 and IsoDirections.E) or (dx < 0 and IsoDirections.W) or (dy > 0 and IsoDirections.S) or IsoDirections.N
    d.fenceHop = { sx = animal:getX(), sy = animal:getY(), sz = animal:getZ(),
                   cx = cx, cy = cy, ex = ex, ey = ey, z = fz, prog = 0, edge = key, dir = dir,
                   startMs = getTimestampMs() }
    fenceHopping[animal:getOnlineID()] = animal
    -- Anti-pace: depois de saltar em (dx,dy), proibe saltar na direcao OPOSTA por uma janela pra que o cao nao volte
    -- por cima da cerca (o corner-pace). Cruzamentos pra frente/perpendiculares seguem permitidos, entao encadear uma cerca longa funciona.
    d.backBlockDir = { dx = -dx, dy = -dy }
    d.backBlockUntilMs = getTimestampMs() + (CD.FENCE_BACKBLOCK_MS or 2000)
    -- Toca o clip de SALTO via o idle node cdJump. O glide-na-mao e lido como IDLE pela engine (setX com nx=x = sem
    -- velocidade), entao o node da camada idle o mostra (animalRunning so congelava o clip de corrida = a "estatua"). Transmite
    -- feito cdEat pra que SP+MP renderizem. Mantem animalRunning off (fica idle) e encara a direcao do salto.
    emitEatVar(animal, true, CD.JUMP_ANIM_VAR or "cdJump")
    pcall(function()
        animal:setVariable("animalRunning", false)
        animal:setDir(dir)
        -- Tambem seta o VETOR pra frente em direcao ao cruzamento: um client remoto re-deriva o facing a cada frame a partir do
        -- networkAi.direction sincronizado (IsoPlayer.updateRemotePlayer), entao a menos que a direcao AUTORITATIVA seja a linha
        -- do salto o cao pula de lado/gira. setForwardDirection semeia o valor que e sincronizado. Ver pz-b42-animal-mp-position-sync.
        if dx ~= 0 or dy ~= 0 then animal:setForwardDirection(dx, dy) end
    end)
    -- MP: o glide do server por tick abaixo NAO replica suavemente (a pos do animal sincroniza so ~1x/s, o glide de velocidade-zero
    -- nao carrega dead-reckoning entao congela-e-snapa, e o arco Z e arredondado na rede). Transmite o
    -- hop pra que cada client reproduza o MESMO glide na copia local dele (CompanionDogs_Client.tickClientFenceHops). SP
    -- nao precisa de broadcast (sem clients; o glide do server renderiza direto). Ver memoria pz-b42-animal-mp-position-sync.
    if isServer() then
        local dirIdx; pcall(function() dirIdx = dir:ordinal() end)   -- IsoDirections nao tem index(); ordinal() faz round-trip com o fromIndex() do client
        sendServerCommand(CD.MODULE, "fencehop", {
            id = animal:getOnlineID(),
            sx = d.fenceHop.sx, sy = d.fenceHop.sy, sz = d.fenceHop.sz,
            cx = cx, cy = cy, z = fz, dir = dirIdx, dx = dx, dy = dy,   -- vetor de cruzamento bruto: client o encara quando o indice de dir falha o round-trip
            step = CD.FENCE_HOP_STEP, arc = CD.FENCE_HOP_ARC,
        })
        -- Forca um pacote fora-de-cadencia AGORA pra que a direcao do salto (e o estado Static-durante-glide) cheguem aos clients no
        -- frame 1 do hop em vez de ate ~800ms depois: a engine re-encara um animal remoto a partir da direcao
        -- sincronizada a cada frame, entao uma direcao obsoleta aqui e o "pulo de lado / gira". Protegido por pcall (no-op em SP).
        pcall(function() animal:sendExtraUpdateToClients() end)
    end
end

-- Por OnTick: carrega o cao do inicio dele ate o tile de pouso (smoothstep horizontal = decolagem/pouso suavizados,
-- menos mecanico) com um arco Z parabolico (pico no meio do hop). setZ/setNextZ sao protegidos pra que um setter ausente nao
-- quebre o cruzamento X/Y. No pouso ele seta um cooldown curto pra que uma re-deteccao marginal de "mais perto" nao o faca ir e
-- voltar por cima da cerca. (Sem `next()` no Lua do PZ -> itera pairs direto.)
local function tickFenceHops()
    for id, animal in pairs(fenceHopping) do
        local stop = true
        pcall(function()
            if not animal:isExistInTheWorld() then return end
            local d = CD.data(animal)
            local h = d and d.fenceHop
            if not h then return end
            h.prog = h.startMs and math.min(1, (getTimestampMs() - h.startMs) / (CD.FENCE_HOP_DURATION_MS or 800))
                     or math.min(1, h.prog + (CD.FENCE_HOP_STEP or 0.05))
            local p = h.prog
            local ph = p * p * (3 - 2 * p)                              -- smoothstep horizontal
            local arc = (CD.FENCE_HOP_ARC or 0.5) * 4 * p * (1 - p)     -- parabola: 0 nas pontas, pico no meio
            local nx = h.sx + (h.cx - h.sx) * ph
            local ny = h.sy + (h.cy - h.sy) * ph
            local nz = h.sz + (h.z - h.sz) * ph + arc
            animal:setX(nx); animal:setY(ny); animal:setNextX(nx); animal:setNextY(ny)
            pcall(function() animal:setZ(nz); if animal.setNextZ then animal:setNextZ(nz) end end)
            if h.dir then pcall(function() animal:setDir(h.dir) end) end   -- mantem encarando o salto, nao de lado
            -- Comeca a blendar SAINDO do clip de salto um pouco ANTES do toque pra que o cao assente em idle ao pousar
            -- em vez de snapar da pose aerea (o "deforma ao cair"). A descida termina o blend.
            if not h.cleared and p >= (CD.FENCE_HOP_LAND_BLEND or 0.82) then
                h.cleared = true
                emitEatVar(animal, false, CD.JUMP_ANIM_VAR or "cdJump")
            end
            if p >= 1 then
                animal:setX(h.cx); animal:setY(h.cy); animal:setNextX(h.cx); animal:setNextY(h.cy)
                pcall(function() animal:setZ(h.z); if animal.setNextZ then animal:setNextZ(h.z) end end)
                local s = getCell():getGridSquare(h.ex, h.ey, h.z)
                -- so confirma o cao no tile de pouso se ele de fato tiver chao; se perdeu (ou nunca teve
                -- um), deixa pro tickFallGuard recuperar: confirmar num tile sem chao = NPE de queda da engine
                if s and CD.squareHasFloor(s) then animal:setCurrent(s) end
                d.fenceHop = nil
                emitEatVar(animal, false, CD.JUMP_ANIM_VAR or "cdJump")       -- encerra o clip de salto (broadcast)
                pcall(function()
                    animal:setVariable("ClimbFence", false)
                    animal:setVariable("climbDown", false)
                    animal:setVariable("ClimbingFence", false)
                end)
                local now = getTimestampMs()
                d.fenceHopUntilMs = now + (CD.FENCE_HOP_COOLDOWN_MS or 800)   -- gap geral curto (tempo real)
                if h.edge then                                                -- proibe voltar por cima desta aresta
                    d.recrossEdge = h.edge
                    d.recrossUntilMs = now + (CD.FENCE_RECROSS_BLOCK_MS or 4000)
                end
                d.fenceTraversal = nil                  -- assenta no follow normal ao pousar (sem re-steer fantasma na cerca)
                if d.region then d.region.stamp = 0 end -- reach-mode: reconstroi a regiao a partir do NOVO lado no proximo tick
                letMove(animal)                                     -- religa blockMovement+deferredMovement (o land-glide assume a posicao no proximo tick)
                -- O animador do SERVIDOR congela apos o hop: o clip de locomocao certo (Rac_Run) e selecionado mas seu peso de
                -- blend fica preso em ~0 (root motion 0 -> engine nao translada), e mover posicao (teleport/resetModel) NAO destrava
                -- (confirmado por decomp do motor de anim + log rootSpd=0). Conduzimos a posicao do cao na mao ate o dono via
                -- tickLandGlide (mesma tecnica do glide do pulo e do steer da cerca, que funcionam) e soltamos pro follow normal.
                -- Pouso de COMBATE no servidor: conduz na mao ate o ZUMBI (land-glide de combate, tickLandGlide/g.combat) e
                -- PULA o ROOT-FIX-pro-dono abaixo (senao arrastaria o cao de volta pra cerca). SP e follow ficam no caminho
                -- de hoje (byte-inalterado). Ver CD.COMBAT_FENCE_HOP_MP.
                local combatLanding = d.combatHop and isServer()
                d.combatHop = nil
                if combatLanding then
                    landGlide[id] = { animal = animal, startMs = now, combat = true }
                elseif CD.FENCE_LAND_GLIDE and isServer() then
                    -- SP-only: o congelamento do animador pos-hop e do SERVIDOR; em single-player o glide e
                    -- desnecessario e nocivo (setX com deferredMovement off = anima idle enquanto desliza =
                    -- "estatua"). Em SP cai no ROOT FIX abaixo (re-path normal) que anima certo.
                    landGlide[id] = { animal = animal, startMs = now }
                end
                -- MP: diz aos clients pra snap-confirmar o glide local deles no centro de pouso (cobre um client que
                -- streamou no meio do hop, ou cujo prog do glide derivou do server). Casa com "fencehop".
                -- ROOT FIX pra "teleporta pra tras / anda colado na cerca": re-path em direcao ao dono IMEDIATAMENTE no
                -- pouso pra que o cao ja esteja Moving-EM-DIRECAO-ao-dono desde o primeiro pacote de sync, em vez de ficar Static
                -- na cerca (cuja previsao obsoleta o client remoto extrapola DE VOLTA pra cerca). O followOwner pesado
                -- assume no proximo ciclo; pre-semeia a contabilidade dele pra que nao cancele este path.
                if not combatLanding then
                    local owner = CD.getOwnerPlayer and CD.getOwnerPlayer(animal) or nil
                    if owner and owner:getCurrentSquare()
                       and math.floor(owner:getZ()) == math.floor(animal:getZ())
                       and CD.dist2D(animal, owner) <= (CD.TELEPORT_DIST or 24) then
                        pcall(function()
                            letMove(animal)
                            animal:setVariable("animalRunning", true)
                            animal:setVariable("animalSpeed", CD.runAnimSpeed())
                            local ddx, ddy = owner:getX() - animal:getX(), owner:getY() - animal:getY()
                            local dl = math.sqrt(ddx * ddx + ddy * ddy)
                            if dl > 0.01 then animal:setForwardDirection(ddx / dl, ddy / dl) end
                            if not pcall(function() animal:pathToCharacter(owner) end) then
                                animal:pathToLocation(math.floor(owner:getX()), math.floor(owner:getY()), math.floor(owner:getZ()))
                            end
                            forcePathfind(animal)
                        end)
                        d.running = true
                        d.followPathTile = { x = math.floor(owner:getX()), y = math.floor(owner:getY()), z = math.floor(owner:getZ()) }
                        d.followPathMs = now
                        d.followLastX, d.followLastY, d.followStallMs = animal:getX(), animal:getY(), now
                    end
                end
                if isServer() then
                    sendServerCommand(CD.MODULE, "fencehopend", { id = id, x = h.cx, y = h.cy, z = h.z })
                    -- Forca um pacote fresco de posicao fora-de-cadencia imediatamente: sem ele o proximo pacote nativo (ate
                    -- ~800ms adiante) ainda carrega o realx pre-hop OBSOLETO perto da cerca, e o remote-mover da engine
                    -- arrasta o cao DE VOLTA pra la ("volta pra cerca, gira"). Isto poe o realx autoritativo ALEM
                    -- da cerca em ~100ms; a janela de settle do client (FENCE_HOP_SETTLE_MS) cobre o gap. No-op em SP (pcall).
                    pcall(function() animal:sendExtraUpdateToClients() end)
                    landSettling[id] = { animal = animal, untilMs = now + (CD.FENCE_LAND_PUSH_MS or 450), lastMs = now }
                    if CD.FENCE_LAND_USE_STREAM then landStreaming[id] = { animal = animal, untilMs = now + (CD.FENCE_LAND_STREAM_MS or 2000) } end
                end
                return
            end
            stop = false  -- ainda no meio do hop
        end)
        if stop then fenceHopping[id] = nil end
    end
end

-- Apos um salto, segue forcando pacotes de posicao novos por FENCE_LAND_PUSH_MS pra que o client receba de forma confiavel um
-- pacote Static-no-pouso (cancela a previsao Moving obsoleta dele rumo a cerca) mesmo se o push unico de pouso
-- cair no UDP. Por OnTick, a cada ~50ms, no-op em SP (pcall). Removido quando a janela expira ou o cao some.
local function tickFenceLandPush()
    if not isServer() then landSettling = {}; return end
    local now = getTimestampMs()
    for id, rec in pairs(landSettling) do
        local drop = true
        pcall(function()
            local a = rec.animal
            if not a or not a:isExistInTheWorld() or now >= rec.untilMs then return end
            drop = false
            if not rec.lastMs or (now - rec.lastMs) >= 50 then
                rec.lastMs = now
                pcall(function() a:sendExtraUpdateToClients() end)
            end
        end)
        if drop then landSettling[id] = nil end
    end
end

-- Limpa os vars nativos de climb + o registro de glide. Chamado em teleport/Trazer/Stay/Guard pra que um cao nunca fique
-- parado no meio de um climb (um var ClimbFence travado o congelaria "correndo no lugar"). Na tabela CD pra que Commands.lua
-- (um arquivo separado) tambem possa chamar.
function CD.clearClimbVars(animal)
    pcall(function()
        animal:setVariable("ClimbFence", false)
        animal:setVariable("ClimbingFence", false)
        animal:setVariable("climbDown", false)
    end)
    emitEatVar(animal, false, CD.JUMP_ANIM_VAR or "cdJump")   -- nunca deixa o cao preso na pose de salto
    local d = CD.data(animal)
    if d then
        d.fenceHop = nil; d.fenceTraversal = nil   -- derruba a flag de traversal pra que o A* retome limpo
        d.region = nil; d.progBestGap = nil; d.progSinceMs = nil; d.progRepositionUntilMs = nil
        d.backBlockDir = nil; d.backBlockUntilMs = nil
        d.fenceSteer = nil
    end
    pcall(function() fenceHopping[animal:getOnlineID()] = nil end)
    pcall(function() fenceSteering[animal:getOnlineID()] = nil end)
    pcall(function() landGlide[animal:getOnlineID()] = nil end)
end

-- True quando um personagem em pe em `sq` NAO sera tratado como suspenso pela engine (entao nao cai). Espelha
-- IsoGridSquare.TreatAsSolidFloor (solidfloor OU escadas OU superficie inclinada): isSolidFloor() retorna aquele resultado
-- cacheado, getFloor() e a checagem direta do objeto-chao: qualquer um passando = chao seguro. Protegido por pcall (o square pode
-- estar obsoleto/descarregado). Pousar num tile sem chao e o NPE fallenOnKnees->addHole em animais; ver tickFallGuard.
function CD.squareHasFloor(sq)
    if not sq then return false end
    local ok = false
    pcall(function() ok = sq:isSolidFloor() or sq:getFloor() ~= nil end)
    return ok
end

-- Um alvo zumbi vivo e ameacador. Exclui corpos que o dono esta agarrando/arrastando/carregando:
-- a engine reanima um corpo carregado num IsoZombie de verdade (health > 0, entao isDead()==false) marcado
-- reanimatedForGrappleOnly (IsoDeadBody.reanimate/reanimateZombieForGrapple), ele fica no square do
-- dono e o cao de outra forma continuaria mordendo o corpo que o dono esta carregando.
local function isThreatZombie(o)
    if not instanceof(o, "IsoZombie") or o:isDead() then return false end
    -- Compat mods de NPC (HDX Strangers etc.): NPC e um IsoZombie marcado, nunca alvo. Ver CD.NPC_MARKER_VARS.
    if CD.isFriendlyNPC(o) then return false end
    -- Compat True Companions: ignora companheiros recrutados (sao IsoZombie com a var "Bandit").
    if BanditBrain then
        local isBandit = false
        pcall(function() isBandit = o:getVariableBoolean("Bandit") end)
        if isBandit then
            local b = BanditBrain.Get(o)
            if b and b.recruited then return false end
        end
    end
    local grappleOnly = false
    pcall(function() grappleOnly = o.isReanimatedForGrappleOnly and o:isReanimatedForGrappleOnly() end)
    return not grappleOnly
end

-- True se uma parede ou porta fechada esta entre os dois objetos (LosUtil percorre em 3D). Copia local do
-- padrao sentinelLOS pra que o caminho do sentinel fique intocado; nil-safe e degrada pra "nao bloqueado" se a
-- API da engine estiver ausente, entao um zumbi so e rejeitado quando o LOS reporta positivamente um bloqueador.
local function pathBlocked(fromObj, toObj)
    if not LosUtil or not LosUtil.lineClearCollide then return false end
    local blocked = false
    pcall(function()
        blocked = LosUtil.lineClearCollide(
            math.floor(toObj:getX()), math.floor(toObj:getY()), math.floor(toObj:getZ()),
            math.floor(fromObj:getX()), math.floor(fromObj:getY()), math.floor(fromObj:getZ()),
            false)
    end)
    return blocked
end

-- Escolhe o melhor alvo de engajamento em vez do mais-proximo-do-cao bruto. LOS livre (pathBlocked) e so PREFERENCIA
-- de desempate; quem decide se um candidato pode ser selecionado e a ALCANCABILIDADE A PE (CD.combatReachRegion):
-- zumbi provadamente murado/atras de cerca ou carro nunca entra na lista (LOS ve cerca/carro como "livre", dai os
-- travamentos encarando parede/carro). A janela de coleta e owner-inclusiva quando `ref` e o dono (follow/protect/
-- comando): centrada no ponto medio cao-dono e alargada ate R+6, pra ameaca colada no dono a >radius do cao entrar
-- (o "zumbi me atacando por tras que o cao ignora"). Guarda (ref = cao) mantem a janela antiga. Um zumbi que ja mira
-- o dono ou o cao e ranqueado primeiro e dribla o gate de ANDAR (autodefesa entre andares). Retorna
-- (alvo, count, threatensUs): count = ameacas no raio do CAO (conduz golpe/threat), threatensUs = qualquer coletado
-- mirando dono/cao. allowNil=true (follow proativo) retorna nil sem alcancavel (reagrupa); false (comando/guarda)
-- cai pro mais proximo ALCANCAVEL (obedece quando da, e honesto quando nao da: nil -> clearAttack/posto).
local SCAN_LOS_CAP = 8
local function scanZombies(animal, radius, owner, ref, allowNil)
    local cell = getCell()
    if not cell then return nil, 0, false end
    local ax = math.floor(animal:getX())
    local ay = math.floor(animal:getY())
    local az = math.floor(animal:getZ())
    local R = math.ceil(radius)
    local refZ = ref and math.floor(ref:getZ()) or az
    local cx, cy, Rwin = ax, ay, R
    local ownerSide = ref ~= nil and ref ~= animal
    if ownerSide then
        local dOR = CD.dist2D(animal, ref)
        if dOR > 1 then
            cx = math.floor((animal:getX() + ref:getX()) / 2)
            cy = math.floor((animal:getY() + ref:getY()) / 2)
            Rwin = math.min(R + math.ceil(dOR / 2), R + 6)
        end
    end
    local region, regionTried
    local unr = CD.combatUnreach[animal:getOnlineID()]
    local unrNow = unr and getTimestampMs() or 0
    local cands, count, threatensUs = {}, 0, false
    for dx = -Rwin, Rwin do
        for dy = -Rwin, Rwin do
            local sq = cell:getGridSquare(cx + dx, cy + dy, az)
            if sq then
                local mo = sq:getMovingObjects()
                if mo then
                    for i = 0, mo:size() - 1 do
                        local o = mo:get(i)
                        -- Zumbi em cooldown de inalcancavel (backstop) e pulado ate expirar (poda na passagem)
                        local coolUntil = unr and unr[o]
                        if coolUntil and coolUntil <= unrNow then unr[o] = nil; coolUntil = nil end
                        if not coolUntil and isThreatZombie(o) then
                            local dDog = CD.dist2D(animal, o)
                            local dRef = ref and CD.dist2D(ref, o) or dDog
                            if dDog <= radius or (ownerSide and dRef <= radius) then
                                local tgtOwner, tgtDog = false, false
                                pcall(function()
                                    local t = o:getTarget()
                                    if owner and t == owner then tgtOwner = true end
                                    if t == animal then tgtDog = true end
                                end)
                                if tgtOwner or tgtDog then threatensUs = true end
                                -- Regiao construida preguicosamente (so ha custo quando existe ameaca por perto);
                                -- nao-membro so REPROVA com flood completo + mesmo andar + dentro da janela.
                                if not regionTried then
                                    regionTried = true
                                    region = CD.combatReachRegion(animal)
                                end
                                local reach = true
                                if region and math.floor(o:getZ()) == az then
                                    local zx, zy = math.floor(o:getX()), math.floor(o:getY())
                                    local depth = region.set[zx .. ":" .. zy]
                                    local inWindow = math.abs(zx - region.sx) <= region.radius
                                        and math.abs(zy - region.sy) <= region.radius
                                    if not region.truncated and inWindow then
                                        if not depth then
                                            reach = false   -- inalcancavel a pe dentro do raio (parede/cerca sem volta)
                                        elseif depth > dDog * (CD.COMBAT_DETOUR_FACTOR or 1.5) + (CD.COMBAT_DETOUR_ADD or 2) then
                                            reach = false   -- so alcancavel por desvio grande (atras de cerca) -> nao persegue, orbitaria
                                        end
                                    end
                                end
                                if dDog <= radius then count = count + 1 end
                                if reach then
                                    cands[#cands + 1] = {
                                        o = o, dDog = dDog, dRef = dRef,
                                        active = tgtOwner or tgtDog,
                                        sameZ = math.floor(o:getZ()) == refZ,
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if #cands == 0 then return nil, count, threatensUs end

    table.sort(cands, function(a, b)
        if a.active ~= b.active then return a.active end
        if a.dRef ~= b.dRef then return a.dRef < b.dRef end
        return a.dDog < b.dDog
    end)

    local fallback, tested = nil, 0
    for _, c in ipairs(cands) do
        if c.active or c.sameZ then
            if not fallback then fallback = c.o end
            if tested < SCAN_LOS_CAP then
                tested = tested + 1
                if not pathBlocked(animal, c.o) then return c.o, count, threatensUs end
            end
        end
    end

    -- Nenhum com linha livre: LOS bloqueada != inalcancavel (o A* contorna parede/arvore), entao cai pro mais
    -- proximo ALCANCAVEL no MESMO ANDAR mesmo em follow (interior/floresta = LOS quase nunca livre).
    if fallback then return fallback, count, threatensUs end
    -- Sem candidato no andar/ativo: follow reagrupa (nil, nao corre cross-z); ordem/guarda cai pro mais-proximo-do-ref.
    if allowNil then return nil, count, threatensUs end
    return cands[1].o, count, threatensUs
end

local function playerFighting(owner)
    local attacking = false
    pcall(function() attacking = owner.isAttacking and owner:isAttacking() end)
    return attacking
end

local function warnRefusalInCombat(animal, owner, d)
    if not owner or not playerFighting(owner) then return end
    local now = worldMinutes()
    if d.lastRefuseWarnMin and (now - d.lastRefuseWarnMin) < CD.REFUSE_WARN_COOLDOWN_MIN then return end
    d.lastRefuseWarnMin = now
    CD.notifyOwner(owner, "refused", { reason = CD.refusalReason(animal), name = d.name, breed = CD.getBreed(animal) })
end

-- Sinaliza o dono uma vez quando o cao cruza pra cima entrando em panico (tier >= 2). Re-arma depois que ele acalma abaixo do tier 2.
local function updatePanicNotify(animal, owner, d)
    local tier = CD.panicTier(animal)
    if tier >= 2 and (d.lastPanicTier or 0) < 2 then
        CD.notifyOwner(owner, "panic", { name = d.name, breed = CD.getBreed(animal) })
    end
    d.lastPanicTier = tier
end

local combatTarget = {}
-- Refs vivas do objeto de presa pra caca, keyed pelo onlineID do cao (espelha combatTarget). Mantemos uma referencia DIRETA
-- em vez de re-resolver via getAnimal(onlineID) a cada tick: esse round-trip retorna nil pra presa selvagem (esp. SP), entao
-- o cao soltava + readquiria o alvo a cada scan -> "tracking" piscando + um passo e volta pro follow, e ele
-- so matava presa que por acaso escaneasse JA no alcance de bote. O objeto escaneado em si esta ok; so o lookup nao estava.
local huntPreyRef = {}
-- Mesma ideia pro track grudento do cervo ferido: uma ref direta em vez de getAnimal(d.woundedPrey.id) (nil pra presa selvagem SP,
-- o que zeraria d.woundedPrey a cada tick = halo "feriu um cervo" repetido + hold quebrado). Gated por d.woundedPrey.
local huntWoundedRef = {}

-- Caes atualmente "no colo" (dono dirigindo), snapados a cada tick pra tracking suave.
local mountedDogs = {}

-- Caes em FOLLOW ativo pra mante-los movendo suavemente entre as passadas pesadas de COMPANION_TICK_INTERVAL (keyed onlineID ->
-- animal). Registrados por followOwner (o unico mover de follow continuo) e limpos no topo de updateCompanion,
-- entao guarda exatamente os caes cuja ultima passada pesada terminou em follow simples; maintainFollowers os re-conduz a cada
-- FOLLOW_TICK_INTERVAL. reapDogState derruba a linha no unload/morte; o maintainer tambem auto-derruba entradas obsoletas.
local followMaintainDogs = {}

-- Mesma ideia pra caes em COMBATE (aproximacao/bote/retirada): o bloco de combate so re-conduz o movimento a cada
-- COMPANION_TICK_INTERVAL, entao o cao corria em direcao a uma posicao de zumbi defasada em 20 ticks e o client MP interpolava
-- as reversoes bruscas de rumo em "avanca pra frente e corre pra tras". maintainCombat re-conduz so a POSICAO
-- (em direcao ao combatTarget FRESCO / tile de retirada) a cada FOLLOW_TICK_INTERVAL; as DECISOES de bote/scan/retirada
-- ficam no loop pesado de 20 ticks. Keyed onlineID -> animal; d.combatMode diz aproximacao/bote/retirada.
local combatMaintainDogs = {}

-- Caes companheiros atualmente guardados num trailer de animal. Keyed por onlineID -> {onlineID, data, ownerName,
-- retries}. Dentro de um trailer o cao e um IsoAnimal VIVO em vehicle:getAnimals() com o ModData dele intacto;
-- a remocao o reconstroi via copyFrom (a engine descarta getModData() -> reverte pra "wild"), mas o onlineID e
-- preservado, entao a gente captura o bond do objeto vivo no trailer e o re-attacha ao cao reconstruido por id.
-- Espelha a reconciliacao de carry-drop (recoverCarriedDogs). Ver recoverTraileredDogs.
local trailerRecords = {}

-- Predicado pro recall do canil (CompanionDogs_Kennel.lua): cao guardado em trailer e VIVO em vehicle:getAnimals()
-- mas invisivel a cell:getAnimals(); sem esta checagem o recall respawnaria uma duplicata. trailerRecords e
-- file-local de proposito; exposto como closure (zero locals novos).
-- Exige POSSE: token e sequencia POR JOGADOR, entao sem o filtro de dono o cao token 1 de QUALQUER jogador guardado
-- num trailer fazia o recall do MEU cao token 1 cair no ramo de trailer e ser recusado ("esta num veiculo").
CD.tokenTrailered = function(player, tok)
    if tok == nil or player == nil then return false end
    local key = CD.ownerKey(player)
    for _, rec in pairs(trailerRecords) do
        if rec.data and rec.data.companionToken == tok then
            local mine = false
            if rec.ownerKey ~= nil and rec.ownerKey ~= "" then
                mine = rec.ownerKey == key
            elseif rec.ownerName ~= nil and rec.ownerName ~= "" then
                mine = rec.ownerName == player:getUsername()
            end
            if mine then return true end
        end
    end
    return false
end

-- Imunidade a fogo: ultimo HP saudavel conhecido por companheiro carregado (keyed por onlineID), rastreado a cada
-- tick sem queimar pra que tickCompanionFire restaure a fatia de HP que um frame de fogo rouba antes da gente apagar.
local fireBaseline = {}

-- Imunidade a fogo: ultimo tile SEM fogo conhecido por cao guardado (keyed por onlineID, coords). Destino de
-- fallback do escape quando o anel de busca falha (cao cercado por fogo alem do raio), pra ele nunca ficar preso
-- VISIVELMENTE queimando num tile `burning` que o FireCheck da engine reacende todo frame.
local fireSafeTile = {}

-- Scavenge virtual de caes NAO-companion (stray/selvagem/solto): needs sao nativas (>0.8 a engine drena a vida ate
-- matar) e o auto-feed de tigela e so de companion, entao um stray carregado por muito tempo morreria de fome. Ele
-- "se vira sozinho": roll por hora de jogo acima do trigger + scavenge forcado antes do dreno letal (nunca morre de
-- fome). Do-block porque o chunk esta no teto de 200 locals: o estado vive como upvalue, funcoes expostas em CD.
do
    -- world-hours do proximo roll por cao (keyed por onlineID valido); sem ModData, nao deixa residuo num cao domavel
    local nextRoll = {}
    function CD.strayScavenge(a)
        local h, t = 0, 0
        pcall(function() h = a:getHunger() or 0; t = a:getThirst() or 0 end)
        local trig = CD.STRAY_SCAVENGE_TRIGGER or 0.7
        if h < trig and t < trig then return end
        local force = CD.STRAY_SCAVENGE_FORCE or 0.78
        local ate = h >= force
        local drank = t >= force
        if not (ate and drank) then
            local id = a:getOnlineID()
            if id ~= nil and id >= 0 then
                local now = getGameTime():getWorldAgeHours()
                local nxt = nextRoll[id]
                if nxt == nil or now >= nxt then
                    nextRoll[id] = now + 1
                    -- primeira vez acima do trigger so arma o timer (sem refeicao instantanea no primeiro sweep)
                    if nxt ~= nil and ZombRand(100) < (CD.STRAY_SCAVENGE_CHANCE or 40) then
                        ate = ate or h >= trig
                        drank = drank or t >= trig
                    end
                end
            end
        end
        local lvl = CD.STRAY_SCAVENGE_LEVEL or 0.15
        if ate then setNeed(a, "hunger", lvl) end
        if drank then setNeed(a, "thirst", lvl) end
        -- pulso cosmetico (anim+som, SP+MP, auto-clear); comer vence quando ambos dispararam no mesmo sweep
        if ate then pcall(function() CD.pulseEatAnim(a) end)
        elseif drank then pcall(function() CD.pulseDrinkAnim(a) end) end
    end
    function CD.strayScavengePrune(present)
        for id in pairs(nextRoll) do
            if not present[id] then nextRoll[id] = nil end
        end
    end
end

-- Imunidade a arma de fogo: caes companheiros guardados neste tick por tickGunGuard porque um player perto esta mirando/atacando
-- com uma arma de fogo. DUAS alavancas (ver CD.GUN_RISK_RADIUS no Config pro porque completo):
--   * GOD_MODE (setInvulnerable) remove o cao da hit list da arma (CombatManager.removeTargetObjects) =
--     transparencia total, mas e um cheat gated por isCheatAllowed() -> um NO-OP em SP sem -debug. Cobre co-op/-debug.
--   * setIsInvincible (flag de IsoAnimal, nao um cheat) bloqueia o setHealth a distancia -> cobre SP normal. Compartilhado com o
--     guard de veiculo (roadkill), entao o RELEASE dele e coordenado: derruba so quando nem o guard nem o mount o querem.
-- gunGuardUntil[id] = deadline em tick pro hold de histerese. Autoridade SP/dedicated; o client espelha GOD_MODE.
local gunGuarded = {}
local gunGuardUntil = {}
local gunGuardTick = 0
-- Deadline em tick por player a partir do ping "estou mirando uma arma" de um client remoto (CD.Server.aimhint). Deixa isFirearmThreat
-- tratar um dono REMOTO como ameaca durante o aim-hold puro (o server nao le o input local de mira dele), pra que a
-- direcao atras-do-dono seja proativa em co-op/dedicated, nao so reativa na animacao de tiro pela rede.
local clientAimHintUntil = {}

-- Teleport-follow (admin/map-debug, e entrar numa cell de Project RV Interior): a logica de follow so escaneia ~28 tiles
-- em volta do dono, entao um salto grande cai muito alem disso e o cao ativo nunca e mandado vir; alem do raio de carga
-- (~52-60 tiles) a engine virtualiza (deleta) ele no mesmo frame. Estas tabelas so-server (sem churn de ModData)
-- conduzem um detector de salto por tick. lastOwnerTile = tile anterior por dono. activeDogSnapshot = um registro de recuperacao vivo
-- do cao ativo (atualizado em updateCompanion) pra que um que ja DESCARREGOU possa ser respawnado no dono. O
-- respawn e estampado canonico (bumpCanonical / pd.uidGen); o original deixado pra tras mantem uma gen MAIS VELHA e e reapado
-- na carga por processNearbyDogs, sem precisar de co-load, entao funciona atravessando a fronteira interior/mundo do RV (que o antigo
-- keeper-watch nao conseguia cobrir, ja que o proprio keeper virtualizava na saida).
local lastOwnerTile = {}
local activeDogSnapshot = {}
local pendingTeleportBring = {}
-- Janela de recuperacao pra SAIR de uma cell de Project RV Interior: o mod re-assenta o motorista na saida, o que re-monta o
-- dono e suprimiria o bring normal (abandonando o cao no interior). Esta janela traz o cao pro
-- mundo mesmo montado, pra que o caminho de mount o re-stashe pelo resto da viagem. Ver bringActiveOnTeleport.
local rvExitBring = {}
-- Timers de "token nao-visto-desde" do reaper de fantasma, keyed [ownerOnlineID][token] -> worldMinutes. So-RAM (NAO
-- ModData de player) DE PROPOSITO: a graca precisa reiniciar fresca a cada sessao, senao um timer deixado em meio a graca no logout,
-- combinado com worldMinutes monotonico, estaria instantaneamente passado da graca no relog e poderia reapar um cao parado ainda vivo
-- durante os poucos ticks em que o chunk dele volta a streamar. Limpado por token por clearCompanionSlot; reconstruido sob demanda.
local phantomLostSince = {}

-- Local no mesmo arquivo (nao CD.deepCopy): um arquivo shared/ cacheado obsoleto pode ler um helper CD.* como nil; um local nao.
-- Snapshota ModData por VALOR pra que o respawn ganhe uma tabela independente (o gen stamp dele nao pode aliasar o original).
local function cdDeepCopy(t)
    if type(t) ~= "table" then return t end
    local r = {}
    for k, v in pairs(t) do r[k] = cdDeepCopy(v) end
    return r
end

-- Identidade de teleport. Toda vez que o cao ativo e TRAZIDO atravessando um teleport (relocado quando ainda carregado, ou
-- respawnado do snapshot quando descarregado), ele vira a encarnacao canonica: incrementa uma geracao por-uid no
-- ModData do DONO (persiste e sobrevive ao reload; o onlineID NAO) e estampa o cao trazido com ela.
-- Qualquer OUTRA instancia de mesmo-uid deixada pra tras (ex.: o original abandonado no mundo quando o dono entra numa cell
-- de RV Interior em x>=22560, que NUNCA pode co-carregar com o respawn) mantem uma gen MAIS VELHA e e reapada na carga por
-- processNearbyDogs, sem precisar que os dois fiquem carregados juntos.
local function bumpCanonical(owner, dog)
    local u = CD.data(dog).uid
    if not u or not owner then return end
    local pd = CD.playerData(owner)
    pd.uidGen = pd.uidGen or {}
    pd.uidGen[u] = (pd.uidGen[u] or 0) + 1
    CD.data(dog).gen = pd.uidGen[u]
    pcall(function() owner:transmitModData() end)
    CD.transmit(dog)
end
CD.bumpCanonical = bumpCanonical   -- exposto pro recall do canil (CompanionDogs_Kennel.lua); zero locals novos

-- Mantem o estado do snapshot de recuperacao do cao ATIVO em sync no INSTANTE em que um comando o muda. activeDogSnapshot.data e um
-- deepCopy atualizado so a cada COMPANION_TICK_INTERVAL, entao sem isto uma saida de RV dentro dessa janela leria um FOLLOW
-- obsoleto e o snapshot-seed do rvexit / a parte (c) do attemptTeleportBring arrastaria pra fora do interior um cao que acabou de receber Stay
-- (quebrando "Stay pra deixar pra tras"). Chamado de CD.Server.setstate. So o cao ativo tem snapshot.
function CD.stampActiveSnapshotState(player, animal, state)
    if not player or not animal then return end
    if CD.data(animal).companionToken ~= CD.playerData(player).token then return end
    local snap = activeDogSnapshot[player:getOnlineID()]
    if snap and snap.data then snap.data.state = state end
end

local function clearAttack(animal, d)
    d.attackUntilMin = nil
    d.attackArmed = nil
    combatTarget[animal:getOnlineID()] = nil
end

-- Teleport de recuperacao (failsafe de coleira): snapa o cao alguns tiles ATRAS do dono em vez de em cima dele,
-- pra que nao apareca na frente do player (o caso disruptivo). Mesma matematica de "atras" do Bring/fetch
-- (owner - forwardDirection * dist). Tenta TELEPORT_BACK_DIST, depois 1 tile, depois o proprio tile do dono.
local function teleportRecover(animal, owner)
    local sq = owner:getCurrentSquare()
    if not sq then return false end -- square de destino do dono ainda nao carregado (MP: server ainda streamando) -> chamador deve repetir
    animal:stopAllMovementNow()
    CD.clearClimbVars(animal) -- um snap no meio do vault nao pode deixar o cao parado em climbfence ("corre no lugar")
    local bz = sq:getZ()
    local bx, by, tsq = sq:getX() + 0.5, sq:getY() + 0.5, sq
    pcall(function()
        local f = owner:getForwardDirection()
        if not f then return end
        local cell = getCell()
        for _, dist in ipairs({ CD.TELEPORT_BACK_DIST or 2, 1 }) do
            local nx = (sq:getX() + 0.5) - f:getX() * dist
            local ny = (sq:getY() + 0.5) - f:getY() * dist
            local s = cell:getGridSquare(math.floor(nx), math.floor(ny), bz)
            if s and not s:isSolid() and not s:isSolidTrans() and CD.squareHasFloor(s) then
                bx, by, tsq = nx, ny, s
                return
            end
        end
    end)
    local ok, err = pcall(function()
        animal:setX(bx)
        animal:setY(by)
        animal:setZ(bz)
        animal:setCurrent(tsq)
    end)
    return ok
end

-- Libera toda linha de module-state por-onlineID pra um cao saindo do jogo de vez (morte / delete de clone obsoleto). onlineID
-- muda a cada reload, entao sem isto estas tabelas vazavam. NAO chamado em stash/unload (temporario; mountedDogs e
-- de posse de tickMountedDogs e o cao volta via respawnCompanion).
-- Apos um fence-hop o animador do SERVIDOR congela: o clip de locomocao certo (Rac_Run) e selecionado mas seu peso de blend fica
-- preso em ~0 (log: rootSpd=0, Weight ~1e-19), entao a translacao por root motion e zero e o cao fica parado com path e estado
-- corretos; mover posicao (teleport/resetModel) NAO destrava. Solucao: conduzimos a posicao do cao na mao ate o dono (mesma
-- tecnica de steerToFenceTile/tickFenceHops: bloqueia o mover da engine, toca o clip, avanca setX nos mesmos por tick) e soltamos
-- pro follow normal quando o root motion do engine volta (probe) ou o cao alcanca um dono parado.
local function releaseLandGlide(animal, owner, d, now)
    -- Handoff LIMPO: entrega o cao ao follow normal no MESMO estado do ramo "alcancou + dono parado"
    -- (holdStill + idle + followPathTile=nil). O follow normal cold-starta um path fresco quando o dono sair de
    -- novo, a partir desse idle estavel, que e o caso que JA funciona. Soltar a partir de um estado
    -- congelado-em-movimento (o bug antigo) entregava um blend ja corrompido que o engine nunca recuperava.
    pcall(function()
        if animal.setDeferredMovementEnabled then animal:setDeferredMovementEnabled(true) end
        animal:setVariable("animalRunning", false)
        animal:setVariable("animalSpeed", 1.0)
    end)
    d.running = nil
    holdStill(animal)
    updateIdleVariation(animal)
    d.followPathTile = nil
    landGlide[animal:getOnlineID()] = nil
end

local function tickLandGlide()
    if not CD.FENCE_LAND_GLIDE then return end
    local now = getTimestampMs()
    for id, g in pairs(landGlide) do
        local drop = true
        pcall(function()
            local animal = g.animal
            if not animal or not animal:isExistInTheWorld() then return end
            local d = CD.data(animal)
            if not d or d.fenceHop then return end                       -- um novo hop comecou: tickFenceHops e dono
            -- Pouso de COMBATE (server-only, armado no tickFenceHops): conduz na mao ate o ZUMBI, nao ao dono. Solta no
            -- alcance de golpe pro maintainCombat assumir; se o zumbi some, cai no glide de dono (volta pro dono, limpo).
            if g.combat then
                local z = combatTarget[id]
                local zvalid = false
                pcall(function()
                    zvalid = z ~= nil and not z:isDead() and z:getSquare() ~= nil
                        and math.floor(z:getZ()) == math.floor(animal:getZ())
                end)
                if not zvalid then
                    g.combat = nil   -- zumbi morreu/sumiu: fall-through pro glide de dono abaixo
                else
                    local zx, zy = z:getX(), z:getY()
                    local x, y = animal:getX(), animal:getY()
                    local ddx, ddy = zx - x, zy - y
                    local dist = math.sqrt(ddx * ddx + ddy * ddy)
                    if dist <= (CD.STRIKE_DIST or 1.0) + 0.2 then   -- alcancou: handoff pro maintainCombat (o hold no alcance = idle que recupera o animador)
                        pcall(function() letMove(animal) end)
                        combatMaintainDogs[id] = animal
                        landGlide[id] = nil
                        return
                    end
                    local cowner = CD.getOwnerPlayer and CD.getOwnerPlayer(animal) or nil   -- coleira: nunca longe demais do dono
                    if cowner and CD.dist2D(animal, cowner) > (CD.TELEPORT_DIST or 24) then
                        if not teleportRecover(animal, cowner) then drop = false end
                        return
                    end
                    local dt = now - (g.lastMs or now)
                    local maxdt = CD.STEER_MAX_DT_MS or 250
                    if dt < 0 then dt = 0 elseif dt > maxdt then dt = maxdt end
                    g.lastMs = now
                    local run = dist > (CD.FOLLOW_RUN_DIST or 5)
                    pcall(function()
                        local b = animal:getBehavior()
                        if b and b.setBlockMovement then b:setBlockMovement(true) end
                        if animal.setDeferredMovementEnabled then animal:setDeferredMovementEnabled(false) end
                        animal:setVariable("animalRunning", run and true or false)
                        animal:setVariable("animalSpeed", run and CD.runAnimSpeed() or CD.walkAnimSpeed())
                    end)
                    local step = (run and (CD.STEER_RUN_SPEED or 3.6) or (CD.STEER_WALK_SPEED or 1.8)) * dt / 1000
                    local stopGap = (CD.STRIKE_DIST or 1.0)
                    local nx, ny = x, y
                    if dist > stopGap then
                        local sstep = math.min(step, dist - stopGap)
                        nx, ny = x + ddx / dist * sstep, y + ddy / dist * sstep
                    end
                    if dist > 1e-3 then pcall(function() animal:setForwardDirection(ddx / dist, ddy / dist) end) end
                    pcall(function() animal:setX(nx); animal:setY(ny); animal:setNextX(nx); animal:setNextY(ny) end)
                    if CD.FENCE_LAND_USE_STREAM and isServer() then   -- reusa o stream MP (client desenha o caminho continuo)
                        local rec = landStreaming[id]
                        if rec then rec.animal = animal; rec.untilMs = now + 1000
                        else landStreaming[id] = { animal = animal, untilMs = now + 1000 } end
                    end
                    drop = false   -- continua no proximo tick
                    return
                end
            end
            local owner = CD.getOwnerPlayer and CD.getOwnerPlayer(animal) or nil
            if not owner or not owner:getCurrentSquare() then drop = false; return end   -- MP: dono ainda nao streamado, tenta de novo
            if math.floor(owner:getZ()) ~= math.floor(animal:getZ()) then return end     -- andar diferente: deixa o follow normal pathar escada

            local ox, oy = owner:getX(), owner:getY()
            local x, y = animal:getX(), animal:getY()
            local ddx, ddy = ox - x, oy - y
            local dist = math.sqrt(ddx * ddx + ddy * ddy)

            if dist > (CD.TELEPORT_DIST or 24) then                       -- coleira: longe demais -> snap failsafe
                if not teleportRecover(animal, owner) then drop = false end
                return
            end

            -- Rastreia o dono parado no proprio registro do glide (reseta no instante em que o dono se move).
            if g.ox and (math.abs(ox - g.ox) + math.abs(oy - g.oy)) < (CD.OWNER_STILL_EPS or 0.1) then
                g.stillSince = g.stillSince or now
            else
                g.ox, g.oy, g.stillSince = ox, oy, nil
            end

            -- Solta SO quando o cao ALCANCOU (dist <= FOLLOW_START_DIST) E o dono esta parado ha OWNER_STILL_MS: handoff
            -- a partir do mesmo idle estavel que o follow normal cold-starta com sucesso. Enquanto o dono anda OU o cao ainda
            -- nao alcancou, segue conduzindo na mao -- o animador do servidor fica congelado pos-hop (blend de locomocao preso
            -- em ~0, rootSpd=0), entao soltar no meio do movimento volta a travar (confirmado em log: gap cresce, cao parado).
            -- alcancou (margem 0.3 pra o cao estacionado em stopGap soltar de fato) + dono parado -> handoff pro engine.
            -- Com os overrides de animset blendTime=0 (nos de locomocao snapam pra peso cheio) o engine volta a translado o
            -- cao pos-hop, entao soltar nao trava mais (causa-raiz: thrash da maquina de estados recriava o no de locomocao com peso 0).
            if dist <= (CD.FOLLOW_START_DIST or 2) + 0.3
               and g.stillSince and (now - g.stillSince) >= (CD.OWNER_STILL_MS or 450) then
                releaseLandGlide(animal, owner, d, now); return
            end

            -- passo conduzido-na-mao em direcao ao dono (clone de steerToFenceTile; para na FOLLOW_START_DIST)
            local dt = now - (g.lastMs or now)
            local maxdt = CD.STEER_MAX_DT_MS or 250
            if dt < 0 then dt = 0 elseif dt > maxdt then dt = maxdt end
            g.lastMs = now
            local run = dist > (CD.FOLLOW_RUN_DIST or 5)
            pcall(function()
                local b = animal:getBehavior()
                if b and b.setBlockMovement then b:setBlockMovement(true) end
                if animal.setDeferredMovementEnabled then animal:setDeferredMovementEnabled(false) end
                animal:setVariable("animalRunning", run and true or false)
                animal:setVariable("animalSpeed", run and CD.runAnimSpeed() or CD.walkAnimSpeed())
            end)
            local step = (run and (CD.STEER_RUN_SPEED or 3.6) or (CD.STEER_WALK_SPEED or 1.8)) * dt / 1000
            local stopGap = CD.FOLLOW_START_DIST or 2
            local nx, ny = x, y
            if dist > stopGap then
                local sstep = math.min(step, dist - stopGap)
                nx, ny = x + ddx / dist * sstep, y + ddy / dist * sstep
            end
            if dist > 1e-3 then pcall(function() animal:setForwardDirection(ddx / dist, ddy / dist) end) end
            pcall(function() animal:setX(nx); animal:setY(ny); animal:setNextX(nx); animal:setNextY(ny) end)
            if CD.FENCE_LAND_USE_STREAM and isServer() then              -- reusa o stream MP (client desenha o caminho continuo)
                local rec = landStreaming[id]
                if rec then rec.animal = animal; rec.untilMs = now + 1000
                else landStreaming[id] = { animal = animal, untilMs = now + 1000 } end
            end
            drop = false   -- continua no proximo tick
        end)
        if drop then landGlide[id] = nil end
    end
end

local function reapDogState(id)
    if id == nil then return end
    landGlide[id] = nil
    pendingClears.anim[id] = nil
    -- Para o som do pulso antes de descartar a entrada: reap de cao AINDA no mundo (dedup por geracao) deixava o loop orfao pra sempre.
    do
        local e = pendingClears.eat[id]
        if e and e.sound then pcall(function() emitStopSound(e.animal, e.sound) end) end
    end
    pendingClears.eat[id] = nil
    pendingClears.idle[id] = nil
    lastAttackVar[id] = nil
    idleVarNext[id] = nil
    lastIdleVar[id] = nil
    restState[id] = nil
    calmSince[id] = nil
    restBeat[id] = nil
    combatTarget[id] = nil
    fireBaseline[id] = nil
    fireSafeTile[id] = nil
    gunGuarded[id] = nil
    gunGuardUntil[id] = nil
    mountedDogs[id] = nil
    followMaintainDogs[id] = nil
    combatMaintainDogs[id] = nil
    fenceHopping[id] = nil
end

-- O ModData do dono persiste mesmo enquanto o cao esta tirado do mundo, entao guarda um registro de recuperacao
-- la. Se o jogo salva enquanto o cao esta stashado (ex.: sair/crashar sentado num veiculo), o cao
-- e respawnado desse registro no proximo desembarque (ver recoverStashedDogs). data e todo o ModData
-- CompanionDogs do cao (bond/nome/skills/estado); o genome da engine nao e guardado, a raca "marrom" e re-sorteada.
-- Em CD.* (nao local): o chunk esta NO teto de 200 locals do Kahlua (limite por local ATIVO no parser, nao por linha).
function CD.buildStashRecord(animal)
    return {
        type = animal:getAnimalType(),
        female = animal:isFemale() == true,
        age = animal:getAge(),
        hp = animal:getHealth(),
        -- needs sao lidas ao vivo (sem cache de ModData); snapshota elas pra que a janela de status "no veiculo" tenha
        -- numeros pra mostrar e alimentar/dar-agua-dirigindo tenha uma base pra mutar. O upkeep fica suspenso enquanto
        -- montado (o cao deletado nao e processado), entao estas ficam acuradas pela viagem toda. gunHungerSave
        -- espelha o snapshot de gun-guard da janela pra que um stash tirado no meio da mira nao seja um 0 transitorio.
        hunger = CD.data(animal).gunHungerSave or animal:getHunger(),
        thirst = animal:getThirst(),
        -- timestamp pra que a viagem possa seguir avancando fome/sede na taxa de upkeep (tickMountedDogs).
        lastNeedMin = worldMinutes(),
        data = CD.data(animal),
    }
end

-- Em CD.* (nao local): teto de 200 locals do chunk (ver CD.buildStashRecord acima).
function CD.writeStashRecord(animal, owner)
    if not owner then return end
    pcall(function()
        CD.playerData(owner).stash = CD.buildStashRecord(animal)
        -- Snapshot durável fresco antes de esconder o cao no veiculo: recuperavel se o dono morrer com o cao
        -- stashado (o pd.stash some com o personagem; ver L725). O animal ainda esta vivo aqui.
        if CD.kennelSnapshot then CD.kennelSnapshot(owner, animal) end
        owner:transmitModData()
    end)
end

function CD.clearStashRecord(owner)
    if not owner then return end
    pcall(function()
        local pd = CD.playerData(owner)
        if pd.stash then pd.stash = nil; owner:transmitModData() end
    end)
end

-- Restaura um companheiro a partir do objeto de cao stashado (deletado) e/ou do seu registro de recuperacao: spawna um
-- novo animal sincronizado na rede junto ao dono, copia o genome/estado de engine do cao antigo via copyFrom (mantem o
-- visual exato, mas copyFrom descarta nosso ModData) e re-aplica o vinculo. Usado tanto no desembarque quanto na recuperacao de crash.
-- atSq (opcional) respawna NAQUELE square em vez de junto ao dono (retorno "no posto" do stash offline).
local function respawnCompanion(oldDog, owner, rec, atSq)
    local sq = atSq or (owner and owner:getCurrentSquare())
    if not sq then return nil end
    local atype = (rec and rec.type) or "dogmale"
    if oldDog then pcall(function() atype = oldDog:getAnimalType() or atype end) end
    -- Mantem o engine breed da raca funcional pra que a textura fique certa num respawn limpo (tipos gs nao tem
    -- "brown"); no caminho do oldDog o copyFrom restaura o visual de qualquer jeito, mas isto tambem cobre a recuperacao de crash.
    local fbreed = (oldDog and CD.data(oldDog).breed) or (rec and rec.data and rec.data.breed) or CD.DEFAULT_BREED
    local dog = CD.spawnDog(sq:getX(), sq:getY(), sq:getZ(), atype, CD.breedEngineName(fbreed))
    if not dog then return nil end
    if oldDog then
        pcall(function() dog:copyFrom(oldDog) end)
    elseif rec then
        -- recuperacao de crash (sem objeto em memoria): restaura o que o registro guardou; o genome e re-sorteado a partir da raca.
        pcall(function()
            if rec.female ~= nil and dog.setFemale then dog:setFemale(rec.female) end
            if rec.age and dog.setAgeDebug then dog:setAgeDebug(rec.age) end
            if rec.hp then dog:setHealth(rec.hp) end
        end)
    end
    local src = (oldDog and CD.data(oldDog)) or (rec and rec.data)
    if src then dog:getModData().CompanionDogs = src end
    -- Marca d'agua contra snapshot stale: reidrata skills/campos ausentes do canil durável (nunca regride).
    if owner then pcall(function() CD.restoreFromKennel(owner, dog) end) end
    -- O visual da saddlebag (itens anexados) e descartado pelo copyFrom assim como o ModData; re-aplica ele.
    if CD.hasBag(dog) then pcall(function() CD.applyBagVisual(dog) end) end
    -- Re-aplica as needs congeladas do registro ao cao novo. O caminho de desembarque usa copyFrom(oldDog), que
    -- carrega a fome/sede/HP congeladas do objeto DELETADO, mas alimentar/dar agua dirigindo so mutou o
    -- registro (rec.hunger/thirst/hp), entao sem isto a refeicao seria perdida silenciosamente no desembarque. No
    -- caso sem alimentacao estes valores sao iguais aos que o copyFrom ja restaurou, entao e um re-set inofensivo. Tambem preenche
    -- fome/sede na recuperacao de crash (sem oldDog), o que o copyFrom nao conseguiria.
    if rec then
        if rec.hunger ~= nil then setNeed(dog, "hunger", rec.hunger) end
        if rec.thirst ~= nil then setNeed(dog, "thirst", rec.thirst) end
        if rec.hp ~= nil then pcall(function() dog:setHealth(rec.hp) end) end
    end
    local nd = CD.data(dog)
    nd.mounted = nil
    nd.stashed = nil
    nd.lastInvisMin = nil
    -- Um respawn poe o cao num square novo; descarta qualquer follow path-state obsoleto pra que a primeira passada de follow emita um
    -- path limpo em vez de ler um followPathTile residual como "mesmo goal" e se recusar a re-pathar.
    nd.followPathTile = nil
    nd.followPathMs = nil
    nd.followStallMs = nil
    nd.followLastX = nil
    nd.followLastY = nil
    -- Ja avancamos fome/sede durante a viagem (advanceMountedNeeds); reseta o relogio de upkeep pra que o
    -- primeiro updateUpkeep apos o desembarque nao recupere a viagem inteira de novo por cima dela (contagem dupla).
    nd.lastUpkeepMin = worldMinutes()
    -- Relogio de needs resetado pro agora, entao descarta a divida offline acumulada (senao ela depois congela o acrescimo online).
    nd.ownerId = nil   -- id de SESSAO: nunca mais gravado (ver CD.isOwnedBy)
    if owner then CD.playerData(owner).offlineDebtMin = 0 end
    pcall(function() dog:setShootable(false) end)
    pcall(function() dog:setCollidable(true) end)
    -- Garante a imunidade a roadkill AGORA, nao na proxima passada de updateCompanion/tickCompanionInvincible (ambas limitadas a
    -- COMPANION_TICK_INTERVAL). Um respawn novo solto junto a um dono MONTADO (o caminho de re-assento na saida da RV, ver rvExitBring)
    -- cai no square do veiculo em movimento e ficava ali DESPROTEGIDO por ate um intervalo de tick inteiro; roadkill e um
    -- setHealth(0) instantaneo que so isInvincible() bloqueia, entao o trailer atropelava o cao antes de ele conseguir re-armar:
    -- uma morte por um caminho de engine que ignora o permadeath (sem limpeza de slot/mapa) e criava um corpo duplicado a cada
    -- transicao de RV. Fecha a janela pra todo caminho de respawn (saida da RV, desembarque, trazer por teleport, recuperacao de crash).
    pcall(function() dog:setIsInvincible(true) end)
    -- Semeia o maintainer de follow por-tick imediatamente pra que um cao respawnado no desembarque/teleport siga desde o tick um,
    -- em vez de ficar travado (ex.: contra o carro que acabou de deixar, "preso ao sair do carro") por ate um
    -- COMPANION_TICK_INTERVAL inteiro ate a passada pesada registra-lo. letMove limpa qualquer blockMovement obsoleto pra que o primeiro
    -- path do maintainer de fato o conduza. A passada pesada re-limpa/re-adiciona conforme seu ciclo normal; so o cao
    -- FOLLOW ativo e respawnado aqui.
    if CD.getState(dog) == CD.STATE_FOLLOW then
        followMaintainDogs[dog:getOnlineID()] = dog
        letMove(dog)
    end
    CD.transmit(dog)
    return dog
end
CD.respawnCompanion = respawnCompanion   -- exposto pro recall do canil (CompanionDogs_Kennel.lua); zero locals novos

-- Maturacao (Fase B): troca um FILHOTE pelo ADULTO da mesma raca/sexo PRESERVANDO todo o d.* (vinculo, genes, skills,
-- linhagem, pedigree, bag, uid, companionToken). A engine cresceria sozinha aos 90 dias via grow(), que cria um animal
-- novo e DESCARTA nosso ModData; por isso suprimimos a engine (pin de hoursSurvived em todo filhote, tickCompanionInvincible)
-- e fazemos a troca aqui. Espelha respawnCompanion mas com o tipo ADULTO. deepCopy do d.* + bumpCanonical garante que o
-- reaper de geracao mantenha o adulto (geracao maior) e descarte o filhote antigo se coexistirem. Adulto nasce PASSIVO
-- (mantem STATE_STAY + token); o jogador faz Select pra ativar. Server-only.
local function maturePup(pup)
    local owner = CD.getOwnerPlayer(pup)
    if not owner then return end   -- dono offline/longe: adia (filhote esta parado; matura quando o dono carregar)
    local d = CD.data(pup)
    local breed = CD.getBreed(pup)
    local sex = d.sex or CD.animalSex(pup) or "male"
    if sex == "pup" then sex = "male" end
    local adultType = CD.breedAnimalType(breed, sex)
    local px, py, pz = pup:getX(), pup:getY(), pup:getZ()
    local adult = CD.spawnDog(px, py, pz, adultType, CD.breedEngineName(breed))
    if not adult then return end   -- square nao-carregavel: mantem o filhote, re-tenta no proximo sweep
    pcall(function() adult:setAgeDebug(CD.maturityDays()) end)   -- idade adulta sensata (desfaz o randomizeAge do spawn)
    -- copia INDEPENDENTE do d.* do filhote (deepCopy, nao referencia compartilhada) pra o bumpCanonical de fato
    -- diferenciar o adulto do filhote pro reaper. Limpa as flags de filhote.
    local ad = CD.deepCopy(d)
    ad.isPup = nil
    ad.growthPaused = nil
    adult:getModData().CompanionDogs = ad
    local nd = CD.data(adult)
    nd.maxHealth = adult:getHealth()
    nd.lastUpkeepMin = worldMinutes()   -- zera o relogio de upkeep (se virar ativo depois, sem catch-up retroativo)
    nd.ownerId = nil
    pcall(function() adult:setShootable(false) end)
    pcall(function() adult:setIsInvincible(true) end)
    pcall(function() adult:setWild(false) end)
    if CD.hasBag(adult) then pcall(function() CD.applyBagVisual(adult) end) end
    if CD.getState(adult) == CD.STATE_FOLLOW then followMaintainDogs[adult:getOnlineID()] = adult end
    bumpCanonical(owner, adult)   -- geracao maior -> reaper mantem o adulto, descarta o filhote antigo
    CD.transmit(adult)
    pcall(function() owner:transmitModData() end)
    local pupId = pup:getOnlineID()
    reapDogState(pupId)
    pcall(function() pup:delete() end)
    CD.notifyOwner(owner, "matured", { name = nd.name })
end

-- Varre os filhotes carregados e matura os que venceram o prazo (d.bornMin + maturityMinutes), exceto os pausados
-- (d.growthPaused = filhote pra sempre). Timer de tempo-de-mundo absoluto (igual gestacao): conta mesmo virtualizado,
-- dispara quando o filhote recarrega. Coleta antes de maturar (maturePup deleta/spawna -> mutaria a lista da cell).
local function tickMaturation()
    if isClient() then return end
    if not CD.breedingEnabled() then return end
    local cell = getCell()
    if not cell then return end
    local list = cell:getAnimals()
    if not list then return end
    local now = CD.worldMinutes()
    local mins = CD.maturityMinutes()
    local due
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if a and CD.isDog(a) and CD.isCompanion(a) and CD.isPuppy(a) then
            local d = CD.data(a)
            if not d.growthPaused and now >= (d.bornMin or 0) + mins then
                due = due or {}
                due[#due + 1] = a
            end
        end
    end
    if not due then return end
    for _, pup in ipairs(due) do maturePup(pup) end
end

-- Enquanto o dono dirige, o cao e DELETADO (nao escondido, animais sempre renderizam). delete() transmite o
-- despawn a todo client (AnimalSynchronizationManager.delete); removeFromWorld sozinho e local-only e
-- deixava um fantasma congelado e atropelavel nos clients de co-op/dedicated. O estado e preservado no registro de
-- recuperacao e no objeto em memoria, e uma copia nova e respawnada no desembarque (ver respawnCompanion).
local function stashMounted(animal, owner, d)
    if d.stashed then return end
    d.stashed = true
    CD.writeStashRecord(animal, owner)
    pcall(function()
        animal:stopAllMovementNow()
        animal:delete()
    end)
end

local function mountRefresh(animal, owner, d)
    stashMounted(animal, owner, d)
end

-- Retorna true quando a recuperacao esta CONCLUIDA (respawnado, ou dono ausente -> desiste aqui), false quando o chamador deve MANTER
-- o cao em mountedDogs e tentar de novo no proximo tick. O retry e o fix de MP da RV sentada: ao desmontar, o square do dono fica
-- nil por SEGUNDOS enquanto o destino do far-teleport faz streaming (SP resolve na hora, por isso o SP "funciona
-- bem"), entao respawnCompanion falha; se ai dropamos o cao de mountedDogs (como antes) a recuperacao e rebaixada pro
-- caminho de 20 ticks recoverStashedDogs -> o "entra/sai da RV rapido e o cao lagga / fica pra tras" no MP. Mante-lo
-- em mountedDogs deixa tickMountedDogs re-rodar isto a CADA tick ate o square resolver. Restrito so a dono-carregado-
-- mas-square-nil (dono offline -> done=true, sem vazamento; recoverStashedDogs respawna na reconexao).
local function mountClear(animal, d)
    local was = d.mounted
    d.mounted = nil
    local owner = CD.getOwnerPlayer(animal)
    local done = true
    if owner then
        -- So dropa o registro depois que o respawn de fato deu certo, pra que uma falha transitoria (dono sem square por
        -- um tick) nao possa perder o cao. respawnCompanion retorna nil enquanto owner:getCurrentSquare() e nil (stream de MP).
        if respawnCompanion(animal, owner, CD.playerData(owner).stash) then
            d.stashed = nil
            CD.clearStashRecord(owner)
        else
            -- Dono presente mas square nao pronto -> mantem em mountedDogs, tenta de novo no proximo tick. MANTEM d.stashed=true pra que um
            -- re-mount durante essa janela de retry faca early-return em stashMounted em vez de re-delete()ar o cao morto.
            done = false
        end
    end
    -- dono offline (desconexao): deixa o registro pra que recoverStashedDogs o respawne na reconexao; done=true (sem vazamento).
    if was then CD.transmit(animal) end
    return done
end

-- True quando este jogador esta mirando/atacando com uma arma de fogo de longo alcance. Usado SO pelo gun guard
-- (tickGunGuard, imunidade); o steer de followOwner que tambem o usava foi removido (o ghost de hit-list cobre o
-- fogo amigo). Definido LOCALMENTE (nao via CD.* do Util compartilhado) de proposito: o
-- integrated server faz cache do conteudo dos arquivos compartilhados, entao um helper CD.* recem-adicionado pode ler de volta nil no server
-- mesmo este arquivo estando fresco (isso nos pegou: "tried to call nil" em CD.isPlayerAimingFirearm). Um local do mesmo arquivo
-- nao pode desync. Engaja cedo (mirando OU em pleno ataque OU na animacao hostil de mira/tiro) pra que um clique rapido seja pego.
local function isFirearmThreat(player)
    if not player then return false end
    local ranged = false
    pcall(function()
        local w = player:getPrimaryHandItem()
        ranged = w ~= nil and instanceof(w, "HandWeapon") and w:isRanged() == true
    end)
    if not ranged then return false end
    local threat = false
    pcall(function()
        threat = player:isAiming() == true
            or (player.isAttacking and player:isAttacking() == true)
            or (player.isPerformingHostileAnimation and player:isPerformingHostileAnimation() == true)
    end)
    if threat then return true end
    -- Jogador remoto: o server nao consegue ler o aim input local dele (setIsAiming vem do inputState), entao o
    -- acima so dispara durante a animacao de ataque em rede dele. O client pinga CD.Server.aimhint enquanto mira;
    -- trata isso como ameaca ate o prazo TTL, pra que a direcao seja proativa em co-op/dedicated tambem.
    local id = player.getOnlineID and player:getOnlineID()
    return id ~= nil and (clientAimHintUntil[id] or 0) >= gunGuardTick
end

-- O client remoto diz ao server que esta mirando/atirando (o server nao ve o aim input remoto). Carimba um
-- prazo TTL; o client re-pinga enquanto mira e o prazo expira sozinho quando ele para/desconecta.
CD.Server = CD.Server or {}
function CD.Server.aimhint(player)
    if not player or not player.getOnlineID then return end
    clientAimHintUntil[player:getOnlineID()] = gunGuardTick + (CD.GUN_AIM_HINT_TTL or 120)
end

-- Passagem de bala no SP como FANTASMA (feature "cao nao leva tiro"): a mira ignora o cao (setShootable) E a bala o
-- ATRAVESSA, SEM teleporte, igual ao MP. setIsInvincible so anula o DANO: o cao continua na hit list de uma arma MIRADA
-- (CombatManager: animais driblam isShootable/isValidTarget), entao absorve a bala (zumbi atras nao leva) + toma sangue/
-- flinch/stress. O GOD_MODE que tira o cao da hit list e NO-OP no SP sem -debug. Em SP replicamos o GOD_MODE tirando o cao
-- da object list da cell no frame EXATO do disparo (OnWeaponSwingHitPoint dispara um statement ANTES de calculateHitInfoList
-- montar a lista): a lista sai sem ele -> a bala segue reto pro zumbi e nada de hitConsequences roda no cao. Re-add ADIADO
-- pro proximo tick (re-adicionar no mesmo handler o poria de volta ANTES da lista ser montada). getObjectList() pode nao ser
-- mutavel via Lua (o vanilla so usa a copia getObjectListForLua); por isso ha o backstop ghost.onHit (setAvoidDamage)
-- que garante ZERO sangue/dano/susto mesmo se a remocao nao pegar (nesse caso o cao "engole" a bala sem se machucar, sem
-- teleporte). SP-only: isServer() barra host/dedicated (GOD_MODE ja resolve la); isGodMod por-cao cobre o SP-com-debug.
-- Tudo num unico local (limite de 200 locais no chunk do arquivo). ghost.removed = onlineID -> cao tirado da lista.
local ghost = { removed = {} }
function ghost.onFire(owner, weapon)
    if not owner or not weapon then return end
    if isServer() then return end   -- so SP (MP e co-op ja resolvidos pelo GOD_MODE)
    local ranged = false
    pcall(function() ranged = instanceof(weapon, "HandWeapon") and weapon:isRanged() == true end)
    if not ranged then return end
    local cell = getCell()
    if not cell then return end
    local list = cell:getAnimals()
    if not list then return end
    local removed = 0
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if a and CD.isDog(a) and CD.isCompanion(a) then
            local skip = false
            pcall(function() if a:isGodMod() == true then skip = true end end)   -- co-op/-debug: GOD_MODE ja resolve
            if not skip then
                -- SEM gate de direcao/Z/raio: a inclusao da engine (isHittableBallisticsTarget) e "a <2.75 tiles do
                -- ponto de mira OU do SEGMENTO cano->alvo, incluindo a ponta", entao o cao no CALCANHAR (atras/ao lado,
                -- posicao natural de follow) esta SEMPRE na hit list; um gate dot>0 o deixava de fora da remocao e ele
                -- comia a bala quando nao havia alvo melhor no cone (o sangue vem de applyRangeHitLocationDamage, que
                -- roda ANTES do backstop avoidDamage). Remover TODO companion e inofensivo: o re-add ocorre no OnTick
                -- do MESMO frame (antes do render), entao nem pisca.
                pcall(function() cell:getObjectList():remove(a) end)   -- tira da lista que a hit list snapshota
                -- Array (nao chaveado por id): colisao/erro de getOnlineID nunca pode perder um cao do re-add.
                ghost.removed[#ghost.removed + 1] = a
                ghost.any = true
                removed = removed + 1
            end
        end
    end
end

-- Re-add adiado (proximo tick, DEPOIS de a hit list do disparo ser montada). Idempotente (Set); pcall-guarded.
-- NAO usa next() (nao existe no Kahlua do PZ): early-out por flag ghost.any setada em onFire.
function ghost.readd()
    if not ghost.any then return end
    local cell = getCell()
    if not cell then return end   -- cell indisponivel: ghost.any fica true e tenta de novo no proximo tick
    ghost.any = false
    local list = ghost.removed
    ghost.removed = {}
    for i = 1, #list do
        pcall(function() cell:getObjectList():add(list[i]) end)
    end
end

-- Backstop: mesmo que a remocao da object list nao funcione via Lua, o tiro que chega no cao nao causa NADA e ele NAO
-- teleporta. OnWeaponHitCharacter dispara DENTRO de IsoGameCharacter.Hit, ANTES do check `if(avoidDamage) return 0`;
-- setando avoidDamage=true aqui, Hit retorna 0 e hitConsequences (sangue/flinch/stress/dano) nunca roda. Por-hit (cobre
-- cada projetil de shotgun). So o cao companheiro.
function ghost.onHit(wielder, victim, weapon, damage)
    if victim and CD.isDog(victim) and CD.isCompanion(victim) then
        pcall(function() victim:setAvoidDamage(true) end)
    end
end

-- Anchor de movimento do dono por onlineID do dono: { x, y, sinceMs } = onde/quando o dono foi visto se mover por ultimo. Usado
-- pra distinguir "dono parado" de "dono andando" pra que so paremos o cao de vez (predicao de rede Static) quando parado.
local ownerMoveState = {}

-- (RC5b) Re-abencoa o nav grid nativo pra portas ABERTAS perto de um cao cujo path acabou de falhar. Num dedicated server, um
-- client remoto abrindo uma porta de dobradica que estava FECHADA no boot atualiza a porta VIVA (isOpen()=true) mas nunca chama
-- PolygonalMap2.squareChanged no server, entao o A* nativo mantem a passagem bloqueada e o cao nao consegue pathar pra dentro. Nos
-- repetimos o que o caminho do host/direto faz, RecalcAllWithNeighbours(true) + setSquareChanged() (que CHAMA
-- squareChanged), no square de cada porta aberta. Limitado por cao; cada square de porta e re-abencoado no maximo uma vez por
-- cooldown (o grid entao fica atualizado). So server-side (o mover ja roda la). Retorna true se tocou
-- uma porta (o chamador nao precisa re-pathar: o rebuild nativo assincrono cai dentro de um frame ou dois e o follow normal rota pra dentro).
local doorRefreshAt = {}   -- "x,y,z" -> ms do ultimo refresh
local function refreshDoorsAround(cell, ccx, ccy, ccz, R, cool, now)
    local did = false
    for dx = -R, R do
        for dy = -R, R do
            local sq = cell:getGridSquare(ccx + dx, ccy + dy, ccz)
            if sq then
                local objs = sq:getObjects()
                local n = objs and objs:size() or 0
                for i = 0, n - 1 do
                    local o = objs:get(i)
                    if o and instanceof(o, "IsoDoor") then
                        local open = false
                        pcall(function() open = o:isOpen() end)
                        if open then
                            local key = sq:getX() .. "," .. sq:getY() .. "," .. ccz
                            if not doorRefreshAt[key] or (now - doorRefreshAt[key]) >= cool then
                                doorRefreshAt[key] = now
                                pcall(function() sq:RecalcAllWithNeighbours(true) end)
                                pcall(function() sq:setSquareChanged() end)   -- a chamada que o caminho de remote door-open pula
                                did = true
                            end
                        end
                    end
                end
            end
        end
    end
    return did
end

local function refreshOpenDoorsNear(animal, owner, d, now)
    if not CD.DOOR_NAV_REFRESH then return false end
    if d.doorScanMs and (now - d.doorScanMs) < (CD.DOOR_REFRESH_SCAN_MS or 750) then return false end
    d.doorScanMs = now
    local cell = getCell()
    if not cell then return false end
    local R = CD.DOOR_REFRESH_SCAN or 3
    local cool = CD.DOOR_REFRESH_COOLDOWN_MS or 8000
    local did = false
    -- Escaneia perto do CAO (uma porta onde ele esta preso, o caso "entrar pela frente") E perto do DONO (uma porta que ele acabou
    -- de abrir e atravessar, longe do cao, o caso "sair pelos fundos"). A porta obsoleta recem-aberta fica
    -- ao lado de quem a abriu, entao o scan centrado no dono e o que pega uma porta dos fundos que o cao ainda nao alcancou.
    local cur = animal:getCurrentSquare()
    if cur then did = refreshDoorsAround(cell, cur:getX(), cur:getY(), cur:getZ(), R, cool, now) or did end
    local osq = owner:getCurrentSquare()
    if osq then did = refreshDoorsAround(cell, osq:getX(), osq:getY(), osq:getZ(), R, cool, now) or did end
    return did
end

-- NOSSO glide pelo chao ate um tile alvo durante uma travessia de cerca: bloqueia o mover da engine (sem A*, sem wanderIdle), toca o
-- clip de run/walk SEM o root motion dele, e avanca a posicao em direcao ao centro do tile nos mesmos. Densifica pros clients pra que
-- a aproximacao fique aceitavel nos clients remotos (um replay client-side dedicated dessa caminhada e um passo posterior; o
-- hop em si ja e replicado). Usado so enquanto d.fenceTraversal esta setado; followOwner retorna logo apos.
local function steerToFenceTile(animal, owner, targetSq, run, d, now)
    -- passo baseado em tempo: dedupa uma chamada dupla no mesmo frame (maintainer + passada pesada ambos chamam followOwner) pra ~0 e e
    -- independente de FPS. Clampa pra que um _steerMs obsoleto (re-entrado apos um gap) nao possa fazer o cao dar um trancao.
    local dt = now - (d._steerMs or now)
    local maxdt = CD.STEER_MAX_DT_MS or 250
    if dt < 0 then dt = 0 elseif dt > maxdt then dt = maxdt end
    d._steerMs = now
    local tx, ty = targetSq:getX() + 0.5, targetSq:getY() + 0.5
    local x, y = animal:getX(), animal:getY()
    local ddx, ddy = tx - x, ty - y
    local dist = math.sqrt(ddx * ddx + ddy * ddy)
    pcall(function()
        local b = animal:getBehavior()
        if b and b.setBlockMovement then b:setBlockMovement(true) end                          -- a engine nunca o move
        if animal.setDeferredMovementEnabled then animal:setDeferredMovementEnabled(false) end -- o clip de run toca mas nao se auto-translada
        animal:setVariable("animalRunning", run and true or false)
        animal:setVariable("animalSpeed", run and CD.runAnimSpeed() or CD.walkAnimSpeed())
    end)
    local step = (run and (CD.STEER_RUN_SPEED or 3.6) or (CD.STEER_WALK_SPEED or 1.8)) * dt / 1000
    local nx, ny
    if dist <= step or dist < 1e-3 then nx, ny = tx, ty else nx, ny = x + ddx / dist * step, y + ddy / dist * step end
    if dist > 1e-3 then pcall(function() animal:setForwardDirection(ddx / dist, ddy / dist) end) end
    pcall(function() animal:setX(nx); animal:setY(ny); animal:setNextX(nx); animal:setNextY(ny) end)
    if CD.FENCE_LAND_USE_STREAM and isServer() then
        local sid = animal:getOnlineID()
        local rec = landStreaming[sid]
        if rec then rec.animal = animal; rec.untilMs = now + (CD.FENCE_STEER_STREAM_MS or 500)
        else landStreaming[sid] = { animal = animal, untilMs = now + (CD.FENCE_STEER_STREAM_MS or 500) } end
    end
    if CD.MP_DENSE_FOLLOW_SYNC and isServer() then
        if not d._denseSyncMs or (now - d._denseSyncMs) >= (CD.DENSE_SYNC_MS or 100) then
            d._denseSyncMs = now
            pcall(function() animal:sendExtraUpdateToClients() end)
        end
    end
end

-- Driver por-OnTick do steer: avanca a aproximacao conduzida-na-mao a CADA tick do servidor (nao so na passada followOwner de ~200ms),
-- pra que a posicao transmitida seja um caminho CONTINUO que o client interpola liso (o move-na-mao a 200ms parecia teleporte).
-- Espelha tickFenceHops. O bloco eager arma d.fenceSteer + fenceSteering; aqui so movemos.
local function tickFenceSteer()
    if not isServer() then fenceSteering = {}; return end
    local now = getTimestampMs()
    for id, animal in pairs(fenceSteering) do
        local drop = true
        pcall(function()
            if not animal or not animal:isExistInTheWorld() then return end
            local d = CD.data(animal)
            local st = d and d.fenceSteer
            if not st or now >= st.untilMs or d.fenceHop then return end
            drop = false
            local cs = animal:getCurrentSquare()
            if cs and cs:getX() == st.tx and cs:getY() == st.ty then return end   -- chegou: segura; a passada eager pula
            local owner = CD.getOwnerPlayer and CD.getOwnerPlayer(animal)
            if not owner then return end
            local sq = getCell():getGridSquare(st.tx, st.ty, st.tz)
            if sq then steerToFenceTile(animal, owner, sq, st.run, d, now) end
        end)
        if drop then
            fenceSteering[id] = nil
            pcall(function() local d = CD.data(animal); if d then d.fenceSteer = nil end end)
        end
    end
end

-- Pulo de cerca BAIXA em COMBATE (SP): conduz o cao ate a cerca baixa entre ele e o zumbi e o faz SALTAR pra alcancar
-- (reusa o glide do follow: startFenceHop/tickFenceHops). Stateless, re-derivado a cada passada -- NAO usa
-- d.fenceSteer/fenceSteering (server-only), entao um flip follow<->combate nunca deixa estado de travessia conflitante.
-- So cerca BAIXA (lowFenceCrossable); arame/muro/servidor caem fora (isServer/gate) e o cao contorna via A*.
-- Retorna true quando tratou a travessia nesta passada (o chamador segura o resto do combate).
function CD.tryCombatVault(animal, z, d, now)
    if not CD.COMBAT_FENCE_HOP then return false end
    if isServer() and not CD.COMBAT_FENCE_HOP_MP then return false end   -- servidor so pula com o flag de MP
    -- 1) queima-roupa: cao cardinalmente numa cerca baixa cujo lado de la aproxima o zumbi -> salta agora
    local toSq, dx, dy, key = findFenceCrossing(animal, z, d, now, CD.lowFenceCrossable)
    if toSq then
        d.cstall = nil
        d.combatHop = true   -- marca o pouso como de combate (tickFenceHops arma o land-glide rumo ao zumbi, nao ao dono)
        startFenceHop(animal, toSq, dx, dy, z, key)
        return true
    end
    -- 2) cerca baixa na LINHA ate o zumbi -> conduz ate ela e salta. SEM gate de shouldFollowWall: ele vem FALSE mesmo
    -- quando o A* nao alcanca o zumbi murado (era exatamente o motivo do vault nunca disparar). Uma cerca baixa ENTRE
    -- o cao e o zumbi ja e o caso de pular; findFenceTowardOwner so retorna quando ha uma cerca baixa na linha.
    -- Um passo por passada (o driver re-deriva na proxima).
    local fSq, fdx, fdy, fkey, nearSq = findFenceTowardOwner(animal, z, CD.FENCE_GHOST_SCAN or 8, d, now, CD.lowFenceCrossable)
    if fSq and nearSq then
        local cs = animal:getCurrentSquare()
        if cs and cs:getX() == nearSq:getX() and cs:getY() == nearSq:getY() then
            d.cstall = nil
            d.combatHop = true   -- marca o pouso como de combate (ver acima)
            startFenceHop(animal, fSq, fdx, fdy, z, fkey)
        else
            steerToFenceTile(animal, z, nearSq, true, d, now)
        end
        return true
    end
    return false
end

-- So MP: diz a cada client proximo pra parar de rodar seu PROPRIO A* em direcao ao dono enquanto uma cerca atravessavel esta na linha.
-- Uma cerca pulavel e uma PAREDE pro PolygonalMap2 do client, entao o A* client-side dele (setHasObstacleOnPath) anda/desvia da
-- cerca = o cao "para, da dois passos, pensa" antes do salto. O client dropa a flag por FENCE_NEAR_TTL neste
-- sinal (CompanionDogs_Client.onFenceNear). Limitado por cao; no-op em SP. O TTL auto-limpa; a propria
-- supressao do hop (clientFenceHops) assume assim que o salto comeca. Ver pz-b42-animal-fence-climb.
local function signalFenceNear(animal, d, now)
    -- So faz sentido quando o client de fato esta rodando seu proprio render de A* (a coisa que estamos suprimindo). Espelha o
    -- gate de tickAstarFlag pra que nao transmitamos (nem vazemos uma flag de client) quando esse caminho esta desligado ou o stream custom e dono dele.
    if not isServer() or not CD.MP_CLIENT_ASTAR_RENDER or CD.FOLLOW_STREAM then return end
    if d._fenceNearMs and (now - d._fenceNearMs) < 200 then return end
    d._fenceNearMs = now
    pcall(function() sendServerCommand(CD.MODULE, "fencenear", { id = animal:getOnlineID() }) end)
end

-- Rede de seguranca de liveness pro FENCE_REACH_MODE: um reposicionamento limpo junto ao dono (reusa teleportRecover, ja
-- MP-retry-safe e escolhe um tile livre com chao atras do dono). Usado so quando o cao esta comprovadamente preso.
local function doRepositionToOwner(animal, owner, d, now)
    CD.clearClimbVars(animal)
    pcall(function() animal:stopAllMovementNow() end)
    if not teleportRecover(animal, owner) then return false end   -- square do dono ainda sem stream -> tenta de novo no proximo tick
    pcall(function() CD.transmit(animal) end)                     -- forca a nova posicao pros clients (sem slide)
    d.progRepositionUntilMs = now + (CD.PROG_REPOSITION_COOLDOWN_MS or 2000)
    d.progBestGap = nil; d.progSinceMs = nil
    return true
end

-- Retorna true (e reposiciona) so quando o cao esteve CONFINADO (o sinal fenceStall existente) E nao fez nenhum
-- progresso real de gap por PROG_STUCK_MS. O AND de duas partes significa que um cao andando legitimamente um desvio longo (que sai
-- do raio de stall e re-ancora) nunca dispara isto; so um cao de fato encurralado/andando em loop dispara. Nunca abandona o cao.
local function updateProgressWatchdog(animal, owner, d, gap, now)
    if gap <= (CD.FOLLOW_START_DIST or 2) then d.progBestGap = nil; d.progSinceMs = nil; return false end
    if d.progRepositionUntilMs and now < d.progRepositionUntilMs then return false end
    if (not d.progBestGap) or gap <= d.progBestGap - (CD.PROG_EPS or 0.35) then
        d.progBestGap = gap; d.progSinceMs = now; return false   -- progresso real: reseta a janela
    end
    local confined = d.fenceStallMs and (now - d.fenceStallMs) >= (CD.FENCE_GHOST_STALL_MS or 400)
    local nogain = d.progSinceMs and (now - d.progSinceMs) >= (CD.PROG_STUCK_MS or 1500)
    if confined and nogain then return doRepositionToOwner(animal, owner, d, now) end
    return false
end

-- Salvaguarda anti-encalhe (RC5). Independente do FENCE_REACH_MODE (que vai como false, entao o updateProgressWatchdog acima fica
-- dormente). Dispara teleportRecover SO quando o cao e genuinamente inalcancavel dentro da distancia de coleira: a engine
-- reportou o path Failed recentemente (d.pathFailMs, setado no bloco da porta) E o gap em linha reta nao encolheu por
-- STUCK_TELEPORT_MS. O sinal de stall e GAP-PROGRESS, nao deslocamento, porque um cao se arrastando ao longo de uma parede esta
-- "se movendo" mas nao se aproximando. A janela e mais longa que FOLLOW_PATH_RESOLVE_MS pra que uma busca resolvendo sempre ganhe
-- primeiro (uma rota real -> o cao ANDA pra dentro, o gap encolhe, isto reseta); so um dono sem rota chega no snap. Apos
-- o snap, empurra a nova posicao fora da cadencia pra que os clients remotos nao deadreckonem atravessando o salto.
local function tryStuckTeleport(animal, owner, d, gap, now)
    if CD.STUCK_TELEPORT_ENABLE == false then return false end
    if gap <= (CD.FOLLOW_START_DIST or 2) or gap > (CD.TELEPORT_DIST or 24) then
        d.stuckBestGap = nil; d.stuckSinceMs = nil; return false        -- alcancou, ou alem da coleira: nao e nosso caso
    end
    if d.fenceHop or d.fenceTraversal then return false end             -- um salto e dono da posicao do cao
    if d.fenceHopUntilMs and now < d.fenceHopUntilMs then return false end
    if d.fallRecoverUntilMs and now < d.fallRecoverUntilMs then return false end
    if d.stuckTeleportUntilMs and now < d.stuckTeleportUntilMs then return false end
    if (not d.stuckBestGap) or gap <= d.stuckBestGap - (CD.PROG_EPS or 0.35) then
        d.stuckBestGap = gap; d.stuckSinceMs = now; return false        -- chegou mais perto: reseta a janela
    end
    local failedRecently = d.pathFailMs and (now - d.pathFailMs) <= (CD.STUCK_RECENT_FAIL_MS or 2500)
    local noGain = d.stuckSinceMs and (now - d.stuckSinceMs) >= (CD.STUCK_TELEPORT_MS or 3000)
    if not (failedRecently and noGain) then return false end
    if not doRepositionToOwner(animal, owner, d, now) then return false end   -- square do dono ainda sem stream: tenta de novo no proximo tick
    if isServer() then pcall(function() animal:sendExtraUpdateToClients() end) end
    d.stuckTeleportUntilMs = now + (CD.STUCK_TELEPORT_COOLDOWN_MS or 3000)
    d.stuckBestGap = nil; d.stuckSinceMs = nil; d.pathFailMs = nil; d.followPathTile = nil
    return true
end

-- (RC5b, proativo) O scan reativo acima so roda quando o path do cao FALHA. Mas se uma porta dos fundos obsoleta-fechada tem
-- QUALQUER desvio valido longo (ex.: a porta da frente, ja refrescada), o A* do cao TEM SUCESSO pelo desvio, entao o path
-- nunca falha e o cao anda o caminho longo / "se perde". Pega o momento em que o DONO atravessa uma porta: quando o
-- square dele anda pra um cardinalmente-adjacente com uma porta ABERTA naquela borda, ele acabou de abrir+cruzar, entao re-abencoa
-- (o remote-open no server a deixou obsoleta no grid nativo). Isto corrige o grid ANTES do cao se comprometer com o desvio.
local function refreshOwnerCrossedDoor(owner, d, now)
    if not CD.DOOR_NAV_REFRESH then return end
    local osq = owner:getCurrentSquare()
    if not osq then return end
    local ox, oy, oz = osq:getX(), osq:getY(), osq:getZ()
    local px, py, pz = d.ownerDoorX, d.ownerDoorY, d.ownerDoorZ
    d.ownerDoorX, d.ownerDoorY, d.ownerDoorZ = ox, oy, oz
    if px == nil or pz ~= oz then return end                       -- primeira amostra, ou mudou de andar
    if math.abs(ox - px) + math.abs(oy - py) ~= 1 then return end  -- nao foi um unico passo cardinal (nenhuma borda de porta cruzada)
    local cell = getCell()
    if not cell then return end
    local prev = cell:getGridSquare(px, py, pz)
    if not prev then return end
    pcall(function()
        local door = prev:getDoorTo(osq)
        if door and instanceof(door, "IsoDoor") and door:isOpen() then
            local sq = door:getSquare() or osq
            local key = sq:getX() .. "," .. sq:getY() .. "," .. sq:getZ()
            if not doorRefreshAt[key] or (now - doorRefreshAt[key]) >= (CD.DOOR_REFRESH_COOLDOWN_MS or 8000) then
                doorRefreshAt[key] = now
                pcall(function() sq:RecalcAllWithNeighbours(true) end)
                pcall(function() sq:setSquareChanged() end)
            end
        end
    end)
end

local function followOwner(animal, owner)
    -- Este e o unico mover de follow continuo, entao registrar aqui marca o cao pro maintainer por-tick
    -- (maintainFollowers). updateCompanion limpa a linha no topo dela, entao ele sobrevive so enquanto a passada pesada
    -- continua terminando em follow; uma troca pra combat/guard/stay/etc. o dropa na proxima passada pesada.
    followMaintainDogs[animal:getOnlineID()] = animal
    if not owner:getCurrentSquare() then return end
    local d = CD.data(animal)
    refreshOwnerCrossedDoor(owner, d, getTimestampMs())   -- re-abencoa qualquer porta que o dono acabou de atravessar (grid obsoleto)
    standUp(animal)
    local gap = CD.dist2D(animal, owner)

    -- Em pleno salto: tickFenceHops e dono do cao (lerp atravessando + arco em Z). Segura parado pra que o wanderIdle da engine nao possa
    -- brigar com o glide, e nao re-patha; o hop se limpa sozinho em ~0.5s.
    if d.fenceHop then
        if fenceHopping[animal:getOnlineID()] then holdStill(animal); return end
        CD.clearClimbVars(animal)   -- hop ORFAO (fenceHop persistido em ModData, hop interrompido por reload/restart): limpa e segue follow normal
    end

    -- Rede de seguranca de ClimbFence (roda ANTES dos early returns do bloco de cerca, pra que um residuo nunca fique setado enquanto o
    -- ghost esta dirigindo): nos dirigimos ClimbFence nos mesmos pro CLIP de salto e o limpamos na aterrissagem. Se a engine
    -- algum dia o deixa setado SEM estar em pleno glide, o bob de escalada nativo levanta o Z do cao e o name tag pisca apagando
    -- (ele se esconde quando o andar do cao != o do dono), alem de o cao poder congelar "correndo no lugar". Nos somos donos de toda
    -- travessia via o glide, entao limpa qualquer residuo aqui a cada tick.
    do
        local stuck = false
        pcall(function() stuck = animal:getVariableBoolean("ClimbFence") end)
        if stuck then CD.clearClimbVars(animal) end
    end

    -- Failsafe de coleira: longe demais no plano X/Y = snap de volta atras do dono (inalterado).
    if gap > CD.TELEPORT_DIST then
        teleportRecover(animal, owner)
        d.running = nil
        d.climbTries = nil
        d.followPathTile = nil
        d.fenceTraversal = nil
        d.region = nil
        return
    end

    -- Andar diferente (dono subiu/desceu escadas): PATHA o cao pelas escadas em vez de teleportar. O
    -- A* da engine e multi-floor pra animais e IsoMovingObject.doStairs() levanta o z do cao (verificado por
    -- decomp, canClimbStairs e codigo morto). O detalhe: pathToAux seta bPathfind=false pra um alvo cross-z,
    -- jogando o cao na caminhada reta clear-line que nunca rota pra uma escadaria, entao forcePathfind
    -- ele pra AnimalPathFindState (mesmo fix de causa-raiz do bug horizontal "anda pra longe"). O teleport fica so
    -- como failsafe de STUCK: se ele nao consegue alcancar o andar do dono dentro de STAIR_CLIMB_MAX_TRIES follow ticks (sem
    -- rota de escada / pathfinder nativo recusa), recorre ao snap antigo pra que o comportamento nunca regrida.
    if math.floor(owner:getZ()) ~= math.floor(animal:getZ()) then
        d.followPathTile = nil
        d.climbTries = (d.climbTries or 0) + 1
        if d.climbTries > (CD.STAIR_CLIMB_MAX_TRIES or 30) then
            teleportRecover(animal, owner)
            d.running = nil
            d.climbTries = nil
            return
        end
        d.running = true
        letMove(animal)
        pcall(function()
            animal:setVariable("animalRunning", true)
            animal:setVariable("animalSpeed", CD.runAnimSpeed())
        end)
        if not pcall(function() animal:pathToCharacter(owner) end) then
            pcall(function()
                animal:pathToLocation(math.floor(owner:getX()), math.floor(owner:getY()), math.floor(owner:getZ()))
            end)
        end
        forcePathfind(animal)
        return
    end
    d.climbTries = nil

    -- RC1 door follow. A engine vira shouldFollowWall=true no instante em que o A* falha (porta fechada, que animal nao
    -- consegue abrir, ou qualquer alvo bloqueado) e ai wanderia colado na parede. Nos somos donos de todo movimento de
    -- follow, entao limpa a cada tick; e quando ele ESTAVA setado (o path acabou de falhar), uma porta aberta depois do
    -- boot do server (perto do cao OU do dono) pode estar obsoleta no grid nativo (o remote-open nunca a invalidou).
    -- Re-abencoa; o follow normal ai rota atravessando ela. Porta FECHADA o cao nao abre: contorna ou espera o dono abrir.
    do
        local fw = false
        pcall(function() fw = animal:shouldFollowWall() end)
        if fw then
            d.pathFailMs = getTimestampMs()   -- a engine retornou Failed (inalcancavel): arma o backstop de stuck-teleport
            pcall(function() animal:setShouldFollowWall(false) end)
            refreshOpenDoorsNear(animal, owner, d, getTimestampMs())
        end
    end

    -- Rastreador de stall pro fallback do GHOST. "Encurralado" = o cao nao ESCAPOU de um raio pequeno por um tempo: esta preso
    -- numa cerca que o A* nao rota pra atravessar (pressionado contra ela, ou andando paralelo). O deslocamento LIQUIDO de um anchor e
    -- a pista: um cao SEGUINDO ou DESVIANDO fica saindo do raio e re-ancora, entao o follow normal nunca dispara
    -- isto; so um cao de fato confinado dispara. (Um "nao se movendo" por-tick errava um cao andando ao longo da cerca; um por-tick
    -- "nao se aproximando" disparava falso em toda aproximacao normal e CONGELAVA o cao perto de cercas, a regressao.)
    do
        local px, py = animal:getX(), animal:getY()
        local r = CD.FENCE_STALL_RADIUS or 0.8
        if (not d.fenceAnchorX) or gap <= (CD.FOLLOW_START_DIST or 2)
           or (math.abs(px - d.fenceAnchorX) + math.abs(py - d.fenceAnchorY)) > r then
            d.fenceAnchorX, d.fenceAnchorY, d.fenceAnchorMs = px, py, getTimestampMs()
            d.fenceStallMs = nil
        else
            d.fenceStallMs = d.fenceAnchorMs   -- confinado desde que o anchor foi plantado
        end
    end

    -- Decisao de travessia de cerca. DEVE rodar antes do ramo "alcancou, segura parado" abaixo (atravessando uma cerca o gap em
    -- linha reta e minusculo, entao aquele ramo congelaria o cao no lado ERRADO). CD.FENCE_REACH_MODE escolhe a regra:
    -- o novo teste de alcancabilidade BINARIO (vault so quando o dono esta comprovadamente murado -> sem oscilacao), ou a
    -- travessia LEGADA por linha reta "mais perto?" (o caminho de revert). Ambos reusam startFenceHop/steerToFenceTile.
    local now = getTimestampMs()
    -- Pulo de cerca em servidor (MP/dedicado) gateado por CD.FENCE_HOP_MP. O animador do servidor congela o root motion
    -- pos-pulo (causa-raiz em mp_jump_animation.md), mas o land-glide contorna isso conduzindo o cao na mao ate o dono e
    -- soltando so em idle estavel (releaseLandGlide), entao o pulo funciona em servidor com FENCE_HOP_MP=true. Com o flag
    -- off o cao CONTORNA a cerca via pathing normal (cai pro pathToCharacter abaixo). Em SP o pulo segue sempre ativo.
    if isServer() and not CD.FENCE_HOP_MP then
        d.fenceTraversal = nil; d.fenceSteer = nil   -- MP off: sem pulo; nunca deixa estado de travessia residual prender o cao
    elseif gap <= (CD.FENCE_HOP_DETECT_DIST or 20)
       and not (d.fallRecoverUntilMs and now < d.fallRecoverUntilMs) then
        if CD.FENCE_REACH_MODE then
            -- Watchdog primeiro (nunca abandona o cao). Depois: ONDE atravessar = a cerca pulavel na linha em direcao ao
            -- dono (a queima-roupa, perto do cao). SE atravessar = vault A NAO SER QUE exista um caminho CURTO em volta (dono
            -- alcancavel deste lado via um desvio nao muito mais longo que a linha reta). A alcancabilidade binaria nao tem
            -- sinal pra virar (sem pacing); a razao de desvio mantem o cao PULANDO cercas longas em vez de marchar ate um portao.
            if updateProgressWatchdog(animal, owner, d, gap, now) then return end
            local fSq, fdx, fdy, fkey, nearSq = findFenceTowardOwner(animal, owner, CD.FENCE_GHOST_SCAN or 8, d, now)
            if fSq and nearSq then
                signalFenceNear(animal, d, now)   -- MP: suprime o A* do client na aproximacao (Fix A)
                local region = buildSideRegion(animal, owner, d, now)
                local shortWalkAround = region and not region.truncated and region.ownerInside
                    and region.ownerDepth and region.ownerDepth <= gap * (CD.VAULT_DETOUR_FACTOR or 1.6) + 3
                if shortWalkAround then
                    d.fenceTraversal = nil   -- existe um caminho proximo em volta: anda por ele (A*), sem vault
                else
                    d.fenceTraversal = true   -- murado, OU o caminho em volta e longo, OU desconhecido -> PULA em direcao ao dono
                    local curS = animal:getCurrentSquare()
                    if curS and nearSq:getX() == curS:getX() and nearSq:getY() == curS:getY() then
                        startFenceHop(animal, fSq, fdx, fdy, owner, fkey)
                    else
                        steerToFenceTile(animal, owner, nearSq, gap > (CD.FOLLOW_RUN_DIST or 5), d, now)
                    end
                    return
                end
            end
        else
            -- Vault ANSIOSO (o comportamento que vai no release). O anti-pace e o back-block + recross-block. SEM gate de cooldown: esse
            -- gate fazia o cao re-detectar nada por ~1.5s apos um hop, entao ele andava via A* em direcao a cerca recem-
            -- cruzada ate o gate expirar (o "volta pra cerca por 1-2s"). Agora ele se assenta em follow imediatamente.
            -- 1) A queima-roupa: cardinalmente EM uma cerca atravessavel que aproxima o cao -> salta agora.
            local toSq, dx, dy, key = findFenceCrossing(animal, owner, d, now)
            if toSq then
                signalFenceNear(animal, d, now)   -- MP: mata o A* proprio do client neste frame pra que ele nao ande ao longo da cerca
                d.fenceTraversal = true
                startFenceHop(animal, toSq, dx, dy, owner, key)
                return
            end
            -- 2) Ghost-steer ate uma cerca atravessavel na linha em direcao ao dono. Escaneia a CADA tick (nao so quando encurralado) pra que
            -- possamos dizer aos clients pra pararem de brigar com a cerca usando o A* deles no instante em que uma esta a caminho (Fix A,
            -- "para, da dois passos, pensa"), e commitamos o vault apos so um confine CURTO (FENCE_ONLINE_STALL_MS)
            -- em vez do gate encurralado completo de ~400ms (Fix B). O confine curto ainda evita vaultar num portao aberto:
            -- o A* anda o cao ATRAVES de um portao entao ele nunca fica confinado -> fenceStallMs nunca arma -> sem vault.
            local fSq, fdx, fdy, fkey, nearSq = findFenceTowardOwner(animal, owner, CD.FENCE_GHOST_SCAN or 5, d, now)
            if fSq and nearSq then
                signalFenceNear(animal, d, now)
                local need = CD.FENCE_ONLINE_STALL_MS or (CD.FENCE_GHOST_STALL_MS or 400)
                local boxed = d.fenceStallMs and (now - d.fenceStallMs) >= need
                if boxed then
                    d.fenceTraversal = true
                    local curS = animal:getCurrentSquare()
                    if curS and nearSq:getX() == curS:getX() and nearSq:getY() == curS:getY() then
                        startFenceHop(animal, fSq, fdx, fdy, owner, fkey)
                        return
                    end
                    local srun = gap > (CD.FOLLOW_RUN_DIST or 5)
                    d.fenceSteer = { tx = nearSq:getX(), ty = nearSq:getY(), tz = nearSq:getZ(),
                                     run = srun, untilMs = now + (CD.FENCE_STEER_DRIVE_MS or 500) }
                    fenceSteering[animal:getOnlineID()] = animal
                    steerToFenceTile(animal, owner, nearSq, srun, d, now)   -- primeiro passo imediato; tickFenceSteer continua por tick
                    return
                end
            else
                d.fenceTraversal = nil
            end
        end
    end

    -- Salvaguarda anti-encalhe: snap pro dono se o cao esta comprovadamente incapaz de alcanca-lo dentro da distancia de coleira
    -- (genuinamente sem rota animal, ex.: o dono esta num lugar que so uma janela/escada alcanca). Roda a cada tick pra rastrear
    -- gap-progress; so teleporta em inalcancavel-confirmado + sem-progresso, pra que uma aproximacao normal (ou de resolucao lenta) nunca
    -- seja interrompida. Ver [[pz-b42-companion-dedicated-pathing-indoors-doors]] RC5.
    if tryStuckTeleport(animal, owner, d, gap, now) then return end

    -- Rastreador de movimento do dono. A engine sincroniza a posicao do animal pros clients remotos so a cada 800-1000ms e o
    -- client dead-reckona entre pacotes; um cao parado de vez manda uma predicao Static que CONGELA nos clients
    -- remotos ate o proximo pacote ("travado e depois trancao"). Entao so para de vez quando o dono esta genuinamente parado.
    -- ownerStationary = o dono nao se moveu > OWNER_STILL_EPS por OWNER_STILL_MS (o anchor reseta no instante
    -- em que uma posicao fresca em rede mostra movimento, entao um dono andando nunca dispara, ver Config).
    local oid = owner:getOnlineID()
    local nowMs = getTimestampMs()
    local ox, oy = owner:getX(), owner:getY()
    local oms = ownerMoveState[oid]
    local ownerStationary = false
    if oms and (math.abs(ox - oms.x) + math.abs(oy - oms.y)) < (CD.OWNER_STILL_EPS or 0.1) then
        ownerStationary = (nowMs - oms.sinceMs) >= (CD.OWNER_STILL_MS or 450)
    else
        ownerMoveState[oid] = { x = ox, y = oy, sinceMs = nowMs }
    end

    -- Quando alcancou, cai explicitamente pra idle/walk. Deixar as run vars obsoletas fazia o cao
    -- manter o clip de run (e o root motion rapido de run) depois de chegar ao dono.
    if gap <= CD.FOLLOW_START_DIST then
        if ownerStationary then
            d.running = nil
            pcall(function()
                animal:setVariable("animalRunning", false)
                animal:setVariable("animalSpeed", 1.0)
            end)
            -- Dono parado: ativamente para e bloqueia o wanderIdle da engine, senao ele anda o cao "idle" pra um
            -- tile aleatorio +-8 em volta do dono. A predicao Static de rede e ok aqui (o cao DEVERIA estar parado, entao o
            -- congelamento no client e invisivel). O mod re-patha no momento em que o dono sai de novo (o executor ignora blockMovement).
            holdStill(animal)
            updateIdleVariation(animal)
            d.followPathTile = nil
            return
        end
        -- Dono ainda SE MOVENDO mas estamos perto: NAO para de vez (essa predicao Static congela o cao nos clients
        -- remotos = "travado"). Cai pra logica de walk/path pra que ele mantenha uma predicao Moving e o client
        -- renderize movimento continuo; o ramo acima o segura no momento em que o dono de fato para.
    end

    -- Corre com histerese pra que nao oscile walk/run em torno de FOLLOW_RUN_DIST (o que parecia rajadas aleatorias).
    local run = d.running == true
    if gap > CD.FOLLOW_RUN_DIST then run = true
    elseif gap <= CD.FOLLOW_START_DIST + 1 then run = false end
    d.running = run

    pcall(function()
        animal:setVariable("animalSpeed", run and CD.runAnimSpeed() or CD.walkAnimSpeed())
        animal:setVariable("animalRunning", run)
    end)

    -- Re-emitir pathToCharacter NAO e barato: PathFindBehavior2.setData() CANCELA a requisicao A* em voo (assincrona)
    -- sem guard de igualdade de goal, entao o re-pathing do maintainer de ~2 ticks a cada passada mantinha o path perpetuamente
    -- nao resolvido = o cao toca o clip de run SEM transladar ("parado com animacao de movimento") e nunca
    -- se compromete com uma rota. Um unico pathTo* e fire-and-forget (AnimalPathFindState o anda no por no sozinho).
    -- Entao re-emite SO quando o TILE do dono mudou, limitado a >= FOLLOW_REPATH_MS (real-ms) pra que nunca cancelemos o A*
    -- mais rapido do que ele resolve; senao so re-afirma forcePathfind (so a var bPathfind, sem setData) pra manter o
    -- node mover no path vivo. Ver memoria pz-b42-pathto-setdata-cancels-async-astar.
    local otx, oty, otz = math.floor(owner:getX()), math.floor(owner:getY()), math.floor(owner:getZ())
    local pt = d.followPathTile
    local sameGoal = pt and pt.x == otx and pt.y == oty and pt.z == otz

    -- Backstop de stall (real-ms): nao re-armamos mais o WalkingOnTheSpot da engine a cada tick, entao se o cao nao
    -- avancou por FOLLOW_STALL_REPATH_MS, forca um re-path pra recuperar um cao genuinamente bloqueado.
    local px, py = animal:getX(), animal:getY()
    local moved = d.followLastX and (math.abs(px - d.followLastX) + math.abs(py - d.followLastY)) or 999
    if moved >= (CD.FOLLOW_STALL_EPS or 0.05) then d.followLastX, d.followLastY, d.followStallMs = px, py, nowMs end
    local stalled = d.followStallMs and (nowMs - d.followStallMs) >= (CD.FOLLOW_STALL_REPATH_MS or 600)
    local sinceIssue = (d.followPathMs and (nowMs - d.followPathMs)) or 999999

    -- Dono PARADO (sameGoal): nao cancela o A* assincrono em voo antes que ele possa resolver (Fix A, RC5). Nunca cancela
    -- enquanto o cao ainda esta avancando (nao stalled), e mesmo quando stalled da a busca FOLLOW_PATH_RESOLVE_MS desde
    -- a ultima emissao pra terminar: um dedicated server carregado resolve a busca interna mais devagar que o stall de 600ms, entao
    -- a cadencia antiga ficava matando ele e o cao nunca recebia a rota por uma porta aberta. So depois da janela de
    -- resolucao completa sem avanco e que caimos num cancel-e-reemite (o retry periodico lento).
    if sameGoal and (not stalled or sinceIssue < (CD.FOLLOW_PATH_RESOLVE_MS or 1500)) then
        forcePathfind(animal); return
    end
    if not sameGoal and not stalled and sinceIssue < (CD.FOLLOW_REPATH_MS or 250) then
        forcePathfind(animal); return                                  -- dono se moveu mas o ultimo A* ainda resolvendo: nao cancela
    end

    d.followPathTile = { x = otx, y = oty, z = otz }
    d.followPathMs = nowMs
    d.followLastX, d.followLastY, d.followStallMs = px, py, nowMs

    -- Limpa qualquer blockMovement remanescente (de um tick anterior de alcancou/segura) pra que o path abaixo de fato conduza
    -- o cao; senao ele fica num estado sem-path e o root motion o direciona pro lado errado.
    letMove(animal)
    if not pcall(function() animal:pathToCharacter(owner) end) then
        pcall(function() animal:pathToLocation(otx, oty, otz) end)
    end
    -- Sobrescreve o bPathfind=false clear-line do pathToAux pra que o cao use o node mover (em direcao ao dono),
    -- nao o root motion sem-path (pra longe). DEVE vir APOS pathToCharacter/pathToLocation (eles o setam false).
    forcePathfind(animal)
end

local function bark(animal)
    local d = CD.data(animal)
    local now = worldMinutes()
    if d.lastBarkMin and (now - d.lastBarkMin) < CD.BARK_COOLDOWN_MIN then return false end
    d.lastBarkMin = now
    emitSound(animal, CD.BARK_SOUND)
    return true
end

-- O dano do zumbi NAO passa por hitConsequences (que armava flee = bug "parece fugir"). Em MP dedicado o setHealth
-- parcial nao gruda (zumbi client-owned reseta), entao o dano vira um ledger proprio por zumbi + Kill() ao zerar; ver
-- pz-b42-zombie-sethealth-mp-nopersist e o bloco de dano abaixo. SP segue no getHealth direto (persiste).
local function strikeExchange(animal, z, count)
    -- Zumbi ja morto ou em morte: em MP o lock do combatTarget segura a ref por 1-2 ticks apos z:Kill (isDead()
    -- so vira depois que a morte replica), entao um re-golpe recontava a kill (bug "1 morte a cada 2 ataques" no
    -- servidor). getHealth()<=0 pega a janela que isDead() ainda nao pegou; pcall protege ref stale (zumbi invisivel).
    local zdead = true
    pcall(function() zdead = z == nil or z:isDead() or z:getHealth() <= 0 end)
    if zdead then return end
    local d = CD.data(animal)
    local now = worldMinutes()
    if d.lastHitMin and (now - d.lastHitMin) < CD.HIT_COOLDOWN_MIN then return end
    d.lastHitMin = now

    emitSound(animal, CD.BITE_SOUND)
    emitAnim(animal)

    if CD.breedCanKnockdown(animal)
        and (not d.lastKnockMin or (now - d.lastKnockMin) >= CD.knockdownCooldown())
        and ZombRand(0, 1000) < CD.knockdownChance(animal) * 1000 then
        emitKnockdown(z)
        d.lastKnockMin = now
    end

    local xpRate = CD.combatXPRate(animal)
    local killed = false
    local dmg, ledger = -1, -1
    pcall(function()
        local canKill = CD.breedCanKill(animal)
        dmg = CD.effectiveHitDamage(animal)
        -- MP dedicado: o z:setHealth() PARCIAL server-side NAO gruda (o cliente dono do zumbi sobrescreve a vida de
        -- volta pra cheia no proximo sync), entao o dano nunca acumulava e o zumbi era imortal pro cao. Rastreamos a
        -- vida restante num LEDGER proprio por onlineID do zumbi (semeado da vida real no 1o golpe, re-semeado se ficou
        -- stale) e chamamos Kill() ao zerar (o Kill, evento de morte, replica). Em SP o zumbi nao tem onlineID unico e o
        -- setHealth persiste, entao caimos no caminho antigo direto pelo getHealth. Ver pz-b42-zombie-sethealth-mp-nopersist.
        local zid = z:getOnlineID()
        local useLedger = zid ~= nil and zid > 0
        local remaining
        if useLedger then
            CD.zdmg = CD.zdmg or {}
            local rec = CD.zdmg[zid]
            if not rec or (now - (rec.t or now)) > (CD.ZDMG_STALE_MIN or 2) then rec = { hp = z:getHealth() } end
            -- min() aproveita dano do dono/jogador (a vida caiu de verdade) sem ser enganado pelo reset, que SOBE a vida.
            rec.hp = math.min(rec.hp, z:getHealth()) - dmg
            rec.t = now
            CD.zdmg[zid] = rec
            remaining = rec.hp
        else
            remaining = z:getHealth() - dmg
        end
        ledger = remaining
        if remaining <= 0 and canKill then
            killed = true
            if useLedger then CD.zdmg[zid] = nil end
            -- Zera a vida ANTES de Kill: um re-golpe do mesmo tick/lock (MP) ve getHealth()<=0 e sai no guard de topo.
            z:setHealth(0)
            z:Kill(animal)
            -- Dedicado: o Kill() server-side acima NAO gruda (zumbi client-owned reseta pra vivo -> loop matar/reviver).
            -- Delega a morte ao cliente do DONO (autoritativo pros zumbis perto do cao), que mata pelo caminho real.
            if useLedger then
                pcall(function()
                    local ownr = CD.getOwnerPlayer(animal)
                    if ownr then sendServerCommand(ownr, CD.MODULE, "killzombie", { id = zid, zx = z:getX(), zy = z:getY(), zz = z:getZ() }) end
                end)
            end
        else
            -- Raca sub-letal (caramelo): prende no piso, nunca finaliza (dono/breed forte termina).
            if not canKill and remaining < CD.SUBLETHAL_HEALTH_FLOOR then
                remaining = CD.SUBLETHAL_HEALTH_FLOOR
                if useLedger then CD.zdmg[zid].hp = remaining end
                ledger = remaining
            end
            z:setHealth(math.max(remaining, 0))   -- feedback visual + correto em SP/host onde setHealth gruda (no dedicado reseta, inofensivo)
        end
    end)
    -- Veredito do golpe do cao. `ledger` = vida restante RASTREADA pelo mod (getHealth reseta no dedicado e enganaria).
    CD.addSkillXP(animal, "combat", CD.COMBAT_XP_PER_STRIKE * xpRate)
    if killed then
        CD.addSkillXP(animal, "combat", CD.COMBAT_XP_PER_KILL * xpRate)
        CD.recordDogZombieKill(animal)
    end

    -- So por golpe (de lutar), sem escalar pela quantidade de zumbis em volta: o cao so entra em panico depois de lutar um tempo, nao no instante em que encara um grupo.
    CD.addCombatStress(animal, CD.effectiveCombatStress(animal))
    CD.transmit(animal)
end

-- Sucessao multi-cao na morte do cao ativo. Limpar pd.token deixa um sobrevivente ainda carregado em limbo:
-- o fallback sem-token de getCompanionAnimal faz o client MOSTRA-LO como o companheiro, mas maybeUpdate nao o
-- conduz e tickCompanionInvincible o prende (setBlockMovement), entao ele parece "auto-selecionado" mas congelado ate um
-- reload re-adota-lo. Promove o companheiro carregado mais proximo aqui (espelho de CD.Server.select) pra que o sobrevivente
-- assuma e siga de imediato. Morte e um evento de sucessao deterministico, nao o auto-select por proximidade que
-- maybeUpdate deliberadamente recusa, entao so este caminho promove.
local function promoteSuccessor(owner, dead)
    if not owner then return end
    local pd = CD.playerData(owner)
    if pd.token ~= nil then return end
    local cell = getCell()
    if not cell then return end
    local list = cell:getAnimals()
    if not list then return end
    local ox, oy = owner:getX(), owner:getY()
    local best, bestD = nil, nil
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if a ~= dead and CD.isDog(a) and CD.isCompanion(a) and CD.isOwnedBy(a, owner)
           and CD.data(a).companionToken ~= nil then
            local dx, dy = a:getX() - ox, a:getY() - oy
            local dd = dx * dx + dy * dy
            if not bestD or dd < bestD then best, bestD = a, dd end
        end
    end
    if not best then return end
    local d = CD.data(best)
    pd.token = d.companionToken
    pd.name = d.name
    pd.companions = pd.companions or {}
    pd.companions[d.companionToken] = true
    CD.setState(best, CD.STATE_FOLLOW)
    d.lastUpkeepMin = nil
    d.standDown = true
    if not CD.isDisloyal(best) then
        d.recallUntilMin = worldMinutes() + CD.RECALL_OVERRIDE_MIN
        letMove(best)
        pcall(function() best:pathToCharacter(owner) end)
        forcePathfind(best)
    end
    CD.transmit(best)
    pcall(function() owner:transmitModData() end)
    CD.notifyOwner(owner, "selected", { id = best:getOnlineID(), name = d.name, breed = CD.getBreed(best) })
end

-- Libera a contabilidade owner-side de um companheiro quando ele sai do jogo de vez (morte por QUALQUER caminho, ou um reap de
-- fantasma-perdido): dropa o token+nome ativo se era o cao ativo, libera o slot MaxCompanions, notifica o dono e
-- promove um sucessor carregado. `animal` pode ser nil: o reaper de fantasma nao tem objeto vivo (o corpo ja se foi ha muito).
-- NAO da Kill: chamadores segurando um corpo morto vivo fazem isso eles mesmos; o reaper nao tem nada pra matar.
local function clearCompanionSlot(owner, token, name, breed, animal)
    -- Dropa a saddlebag (item + cargo) no tile do cao pra que o dono possa recupera-la. So mortes reais chegam
    -- aqui (permadeath + a varredura de morte da engine); os reaps silenciosos de gemeo-teleport / clone-obsoleto usam a:delete()
    -- SEM clearCompanionSlot, entao uma bag de gemeo deep-copy nunca e derramada em dobro. spillBag e idempotente
    -- (ele zera d.bag), e o reaper de fantasma passa animal=nil (nada pra derramar).
    if animal then pcall(function() CD.spillBag(animal) end) end
    if not owner then return end
    local pd = CD.playerData(owner)
    if token ~= nil and token == pd.token then pd.token = nil; pd.name = nil end
    -- Libera o slot de limite de companheiros (MaxCompanions) e dropa a contabilidade de reaper-de-fantasma pra este token.
    if token ~= nil then
        if type(pd.companions) == "table" then pd.companions[token] = nil end
        if type(pd.tokenAnchor) == "table" then pd.tokenAnchor[token] = nil end
        if CD.clearKennel then CD.clearKennel(owner, token) end   -- some com o snapshot durável do cao morto
        local lp = phantomLostSince[CD.ownerKey(owner)]
        if lp then lp[token] = nil end
    end
    pcall(function() owner:transmitModData() end)
    CD.notifyOwner(owner, "died", { name = name, breed = breed })
    promoteSuccessor(owner, animal)
end

local function permadeath(animal, owner, d)
    if d.diedNotified then return end
    d.diedNotified = true
    clearCompanionSlot(owner, d.companionToken, d.name, CD.getBreed(animal), animal)
    -- Levanta a invencibilidade permanente a roadkill + o GOD_MODE do gun guard pra que a morte por negligencia de fato ocorra
    -- (ambos bloqueiam/defletem a morte se deixados ligados). tickCompanionInvincible nao vai re-arma-la: o cao nao e mais companheiro.
    reapDogState(animal:getOnlineID())
    pcall(function() animal:setIsInvincible(false) end)
    pcall(function() animal:setInvulnerable(false) end)
    pcall(function() animal:Kill(animal) end)
end

local function updateUpkeep(animal, owner, d)
    local now = worldMinutes()
    local last = d.lastUpkeepMin
    if last and (now - last) < CD.UPKEEP_INTERVAL_MIN then return end
    local elapsedMin = (last and now > last) and (now - last) or 0
    d.lastUpkeepMin = now
    -- Congela as needs pelo tempo que o dono ficou desconectado (acumulado por reconcileOwnerPresence): o relogio do mundo
    -- segue rodando enquanto ele esta offline mas o cao nao e processado, entao sem isto o primeiro upkeep pos-reconexao
    -- despeja o span offline inteiro. No-op durante toda jogatina online, entao o acrescimo on-road/fast-forward fica inalterado.
    elapsedMin = applyOfflineDebt(owner, elapsedMin)

    local hunger, thirst, health = 0, 0, 1
    pcall(function()
        hunger = animal:getHunger()
        thirst = animal:getThirst()
        health = animal:getHealth()
    end)

    -- A invencibilidade permanente congelou o acrescimo nativo de fome/sede da engine e o dreno de HP > 0.8 dela, entao dirige
    -- ambos aqui. Limita o catch-up pra que um cao parado fora do alcance do loop nao de pico de fome no retorno do dono.
    if elapsedMin > 0 then
        local step = math.min(elapsedMin, CD.UPKEEP_MAX_CATCHUP_MIN or 360)
        local dDay = step / 1440
        hunger = math.min(1, hunger + (CD.HUNGER_PER_DAY or 0.30) * dDay)
        thirst = math.min(1, thirst + (CD.THIRST_PER_DAY or 0.60) * dDay)
        setNeed(animal, "hunger", hunger)
        setNeed(animal, "thirst", thirst)
        -- Dreno de HP por negligencia. Reducoes de setHealth sao bloqueadas enquanto invencivel, entao desliga pra exatamente estes dois
        -- statements adjacentes: nenhum update da engine (logo nenhum roadkill de colisao com veiculo) se intercala entre os
        -- bytecodes de Lua, entao isto nao abre janela de roadkill. Alimenta o check de permadeath health <= 0 logo abaixo.
        local severe = CD.SEVERE_NEED or 0.8
        if hunger > severe or thirst > severe then
            local drain = (CD.NEGLECT_HEALTH_LOSS_PER_DAY or 3.0) * dDay
            if drain > 0 then
                health = health - drain
                pcall(function()
                    animal:setIsInvincible(false)
                    animal:setHealth(health)
                    animal:setIsInvincible(true)
                end)
            end
        end
    end

    if health <= 0 then permadeath(animal, owner, d); return end

    -- Intoxicado por uma refeicao toxica: a vida sangra gradualmente em direcao a um piso nao-letal (uma refeicao ruim adoece, ela
    -- nunca mata, so a negligencia mata). Reducoes de setHealth sao bloqueadas enquanto invencivel, entao desliga pra exatamente
    -- o set (mesmo truque de no-interleave do dreno de negligencia acima). O regen abaixo fica gateado enquanto doente pra que ele
    -- nao possa desfazer o dreno. Para no piso, entao nunca pode alcancar o caminho de permadeath <=0.
    if elapsedMin > 0 and CD.isSick(animal) then
        local base = d.maxHealth or 1
        if base <= 0 then base = 1 end
        local floor = (CD.TOXIC_SICK_HEALTH_FLOOR or 0.2) * base
        if health > floor then
            local nh = health - (CD.TOXIC_SICK_DRAIN_PER_DAY or 3.0) * (elapsedMin / 1440)
            if nh < floor then nh = floor end
            pcall(function()
                animal:setIsInvincible(false)
                animal:setHealth(nh)
                animal:setIsInvincible(true)
            end)
            health = nh
        end
    end

    if elapsedMin > 0 and CD.healthRegenPerDay() > 0 and not d.inCombat and not CD.isSick(animal) then
        local needMax = CD.healthRegenNeedMax()
        local care = 1
        if needMax > 0 then
            care = math.min(1 - hunger / needMax, 1 - thirst / needMax)
        end
        if care < 0 then care = 0 elseif care > 1 then care = 1 end
        local base = d.maxHealth or 1
        if base <= 0 then base = 1 end
        if care > 0 and health < base then
            local nh = math.min(base, health + CD.healthRegenPerDay() * (elapsedMin / 1440) * care)
            pcall(function() animal:setHealth(nh) end)
            health = nh
        end
    end

    if elapsedMin > 0 and not d.inCombat and CD.combatStressRecoveryPerDay() > 0 then
        CD.addCombatStress(animal, -CD.combatStressRecoveryPerDay() * (elapsedMin / 1440))
    end

    if elapsedMin > 0 then
        local neglect = (hunger > CD.HUNGER_WARN or thirst > CD.THIRST_WARN) and CD.NEGLECT_MULT or 1
        local dec = CD.loyaltyDecayPerDay() * (elapsedMin / 1440) * neglect
        if dec > 0 then CD.setLoyalty(animal, CD.loyalty(animal) - dec) end
    end

    local loyaltyDeficit = 1 - (CD.loyalty(animal) / CD.TRUST_MAX)
    local needsStress = (CD.STRESS_W_HUNGER * hunger
        + CD.STRESS_W_THIRST * thirst
        + CD.STRESS_W_HEALTH * (1 - health)
        + CD.STRESS_W_LOYALTY * loyaltyDeficit) * CD.stressGeneMult(animal)
    CD.setStress(animal, needsStress)
    -- O stressLevel da engine e vestigial pra companheiros e nao pode decair enquanto invencivel (caes domados herdam 50-80 selvagem); mantem zerado pra que nenhum vocal/comportamento de stress nativo dispare. O mod e dono do stress (CD.getStress) e dos vocais.
    pcall(function() animal:setDebugStress(0) end)
    local stress = CD.getStress(animal)

    if CD.stressBarkEnabled()
        and stress >= CD.STRESS_BARK_THRESHOLD
        and CD.getAlertMode(animal) == "full"
        and (not d.lastStressBarkMin or (now - d.lastStressBarkMin) >= CD.STRESS_BARK_COOLDOWN_MIN) then
        d.lastStressBarkMin = now
        bark(animal)
        if CD.stressAttractsZombies() then
            pcall(function()
                addSound(animal, math.floor(animal:getX()), math.floor(animal:getY()), math.floor(animal:getZ()),
                    CD.STRESS_BARK_RADIUS, CD.STRESS_BARK_VOLUME)
            end)
        end
    end

    if CD.woundedEnabled() then
        local base = d.maxHealth or 1
        if base <= 0 then base = 1 end
        local frac = health / base

        local wasHurt = d.wounded == true
        local wasCrit = d.woundedCritical == true

        local crit = wasCrit
        if not crit and frac <= CD.criticalEnterFrac() then crit = true
        elseif crit and frac >= CD.criticalExitFrac() then crit = false end

        local hurt = wasHurt
        if not hurt and frac <= CD.woundedEnterFrac() then hurt = true
        elseif hurt and frac >= CD.woundedExitFrac() then hurt = false end
        if crit then hurt = true end

        d.woundedCritical = crit
        d.wounded = hurt

        if crit and not wasCrit then
            CD.notifyOwner(owner, "woundedcritical", { name = d.name, breed = CD.getBreed(animal) })
        elseif hurt and not wasHurt and not crit then
            CD.notifyOwner(owner, "wounded", { name = d.name, breed = CD.getBreed(animal) })
        elseif not hurt and wasHurt then
            CD.notifyOwner(owner, "recovered", { name = d.name, breed = CD.getBreed(animal) })
        end
    else
        d.wounded = false
        d.woundedCritical = false
    end

    -- O estado "intoxicado" da refeicao toxica e temporizado: limpa quando a janela passa pra que o moodle de doente do HUD caia
    -- (o CD.transmit no fim de updateUpkeep sincroniza a flag limpa pro client do dono).
    if d.sickUntilMin and now >= d.sickUntilMin then
        d.sickUntilMin = nil
    end

    local warnKind
    if CD.isDisloyal(animal) then warnKind = "disloyal"
    elseif hunger > CD.HUNGER_WARN then warnKind = "hungry"
    elseif thirst > CD.THIRST_WARN then warnKind = "thirsty" end
    if warnKind ~= d.lastWarn then
        d.lastWarn = warnKind
        if warnKind then CD.notifyOwner(owner, "warn", { kind = warnKind, breed = CD.getBreed(animal) }) end
    end

    -- So transmite quando algo client-visivel do upkeep mudou (loyalty/stress/doente/ferido): evita reenviar o
    -- ModData inteiro do cao a cada passada. Resolucao da assinatura = resolucao das barras da UI (0.01).
    local sig = string.format("%d|%.2f|%.2f|%s|%s|%s",
        math.floor(CD.loyalty(animal) + 0.5), stress, d.combatStress or 0,
        tostring(d.sickUntilMin ~= nil), tostring(d.wounded), tostring(d.woundedCritical))
    if sig ~= d.upkeepSig then
        d.upkeepSig = sig
        CD.transmit(animal)
    end
end

local function retreat(animal, owner, z)
    local ox, oy = owner:getX(), owner:getY()
    local dx, dy = ox - z:getX(), oy - z:getY()
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.01 then dx, dy, len = 0, 1, 1 end
    local tx = math.floor(ox + (dx / len) * CD.RETREAT_BACK_DIST)
    local ty = math.floor(oy + (dy / len) * CD.RETREAT_BACK_DIST)
    local tz = math.floor(owner:getZ())
    -- Guardado pra que maintainCombat re-conduza o recuo suavemente entre as passadas de 20 ticks (espelho de d.followPathTile).
    CD.data(animal).retreatTile = { x = tx, y = ty, z = tz }
    pcall(function()
        animal:setAttackedBy(nil)
        animal:setDebugStress(0)
        animal:setVariable("animalSpeed", CD.runAnimSpeed())
        animal:setVariable("animalRunning", true)
        letMove(animal)
        animal:pathToLocation(tx, ty, tz)
        forcePathfind(animal)
    end)
end

-- Anda o cao de volta ao seu posto e segura la. O anchor por padrao e o posto de guarda (d.guardX/Y/Z) mas pode ser
-- sobrescrito (o auto-protect passa o owner-anchor d.protectX/Y/Z pra que nunca atropele um posto de Guard real).
local function returnToAnchor(animal, d, ax, ay, az)
    ax = ax or d.guardX
    ay = ay or d.guardY
    az = az or d.guardZ
    if not ax then return end
    local dx = animal:getX() - ax
    local dy = animal:getY() - ay
    if (dx * dx + dy * dy) > (CD.GUARD_RETURN_DIST * CD.GUARD_RETURN_DIST) then
        standUp(animal)
        pcall(function()
            animal:setVariable("animalSpeed", 1.0)
            animal:setVariable("animalRunning", false)
            letMove(animal)
            animal:pathToLocation(math.floor(ax), math.floor(ay), math.floor(az or animal:getZ()))
            forcePathfind(animal)
        end)
    else
        -- Postado no anchor: segura la. Sem isto o wanderIdle da engine afasta o guarda do seu posto.
        holdStill(animal)
        updateRest(animal, d)
    end
end

local function scanSentinelZombies(animal, radius)
    local cell = getCell()
    if not cell then return nil, 0, 0 end
    local ax = math.floor(animal:getX())
    local ay = math.floor(animal:getY())
    local az = math.floor(animal:getZ())
    local R = math.ceil(radius)
    local best, bestDist, count = nil, radius, 0
    for dx = -R, R do
        for dy = -R, R do
            local sq = cell:getGridSquare(ax + dx, ay + dy, az)
            if sq then
                local mo = sq:getMovingObjects()
                if mo then
                    for i = 0, mo:size() - 1 do
                        local o = mo:get(i)
                        if isThreatZombie(o) then
                            local dd = CD.dist2D(animal, o)
                            if dd <= radius then
                                count = count + 1
                                if dd <= bestDist then best, bestDist = o, dd end
                            end
                        end
                    end
                end
            end
        end
    end
    if not best then return nil, 0, 0 end
    return best, bestDist, count
end

local function sentinelLOS(animal, target)
    if not LosUtil or not LosUtil.lineClearCollide then return nil end
    local ok, blocked = pcall(function()
        return LosUtil.lineClearCollide(
            math.floor(target:getX()), math.floor(target:getY()), math.floor(target:getZ()),
            math.floor(animal:getX()), math.floor(animal:getY()), math.floor(animal:getZ()),
            false)
    end)
    if not ok then return nil end
    return blocked
end

local function updateSentinel(animal, owner, d)
    local spd = getGameSpeed and getGameSpeed()
    if spd and spd > 1 then return end
    if owner.isAsleep then
        local asleep = false
        pcall(function() asleep = owner:isAsleep() end)
        if asleep then return end
    end

    local now = worldMinutes()
    if d.lastSentinelScanMin and (now - d.lastSentinelScanMin) < CD.SENTINEL_SCAN_INTERVAL_MIN then
        return
    end
    d.lastSentinelScanMin = now

    local prevTier = d.alertTier
    local mode = CD.getAlertMode(animal)
    local silent = mode == "silent"
    local quiet = mode == "quiet"
    -- Silent = "Nenhum alerta de zumbi vindo do sentinel deste cao" (IGUI_PD_AlertSilentDesc): sem linha de alerta
    -- no head-stack e sem som. Limpa qualquer tier preso de um modo anterior e sai antes de escanear.
    if silent then
        d.alertTier = nil
        if prevTier ~= nil then CD.transmit(animal) end
        return
    end
    local radius = quiet and CD.sentinelQuietRadius() or CD.effectiveSentinelRadius(animal)
    local nearest, dist, count = scanSentinelZombies(animal, radius)

    if not nearest then
        -- Histerese: segura a mensagem fixada no head um tempinho apos a ultima deteccao pra que um zumbi
        -- piscando na borda do raio (ou um travado/bugado) nao fique piscando o texto nem re-disparando som.
        if not (d.alertTier and d.lastDetectMin and (now - d.lastDetectMin) < CD.SENTINEL_ALERT_HOLD_MIN) then
            d.alertTier = nil
            if prevTier ~= nil then CD.transmit(animal) end
        end
        return
    end
    d.lastDetectMin = now

    local st = CD.getState(animal)
    local autoProtectOn = CD.autoProtectEnabled() and CD.getAutoProtect(animal)
    local protecting = autoProtectOn and d.protectUntilMin and now < d.protectUntilMin
    local engageR = (st == CD.STATE_GUARD or protecting) and CD.GUARD_RADIUS
        or ((st == CD.STATE_FOLLOW) and CD.FOLLOW_DEFEND_RADIUS or nil)
    -- Em follow o combate autonomo agora mede do DONO (bolha de defesa), entao a supressao de alerta segue a mesma
    -- regra: zumbi 3-8 do dono deixa de ser suprimido e volta a alertar (o cao nao vai carregar nele).
    local engageDist = dist
    if st == CD.STATE_FOLLOW then pcall(function() engageDist = CD.dist2D(owner, nearest) end) end
    if not quiet and CD.combatEnabled() and engageR and engageDist <= engageR then
        local commanded = d.attackUntilMin and now < d.attackUntilMin
        -- Espelho do gate REAL de engajar: defend (auto-protect + zumbi mirando dono/cao OU dono lutando) ignora
        -- standDown, e protect age como Guard; sem o espelho o sentinel alertaria por zumbi que o combate ja ataca.
        local willEngage = st == CD.STATE_GUARD or protecting or commanded
            or (autoProtectOn and playerFighting(owner))
            or (not d.standDown and (CD.combatInitiative() or playerFighting(owner)))
        if not willEngage and autoProtectOn then
            pcall(function()
                local t = nearest:getTarget()
                if t == owner or t == animal then willEngage = true end
            end)
        end
        if willEngage then
            d.alertTier = nil
            if prevTier ~= nil then CD.transmit(animal) end
            return
        end
    end

    local seen = (sentinelLOS(animal, nearest) == false)
    local alarm = dist <= CD.SENTINEL_CLOSE_DIST
        or count >= CD.SENTINEL_ALARM_COUNT
        or (seen and dist <= CD.SENTINEL_SEEN_DIST)
    -- O tier define a mensagem FIXADA no head (silent ja retornou acima; quiet limita a "aware").
    local tier = (alarm and not quiet) and "alarm" or "aware"
    local escalated = prevTier ~= tier

    if CD.getState(animal) ~= CD.STATE_FOLLOW or CD.dist2D(animal, owner) <= CD.FOLLOW_START_DIST then
        pcall(function() animal:faceThisObject(nearest) end)
    end

    -- O som esta desacoplado da mensagem e agora e raro (silent ja retornou, entao aqui sempre emitimos som):
    -- o latido so dispara quando a ameaca escala PRA CIMA virando alarm e o rosnado so numa deteccao nova (ou num
    -- cooldown longo). Um zumbi oscilando entre tiers nao consegue re-spammar: bark() mantem o proprio floor e o
    -- caminho de rosnado novo (prevTier==nil) tem floor de BARK_COOLDOWN_MIN, entao um flicker/toggle de engajar que
    -- fica zerando prevTier nao burla o espacamento (esse disjunto prevTier==nil sem tempo era o bug do loop de rosnado).
    if tier == "alarm" then
        local escalatedUp = prevTier ~= "alarm"
        if escalatedUp or not d.lastAlarmBarkMin or (now - d.lastAlarmBarkMin) >= CD.SENTINEL_ALARM_BARK_COOLDOWN_MIN then
            if bark(animal) then
                d.lastAlarmBarkMin = now
                if CD.sentinelBarkAttracts()
                    and (not d.lastSentinelNoiseMin or (now - d.lastSentinelNoiseMin) >= CD.SENTINEL_NOISE_COOLDOWN_MIN) then
                    d.lastSentinelNoiseMin = now
                    pcall(function()
                        addSound(animal, math.floor(animal:getX()), math.floor(animal:getY()), math.floor(animal:getZ()),
                            CD.SENTINEL_BARK_RADIUS, CD.SENTINEL_BARK_VOLUME)
                    end)
                end
            end
        end
    elseif (prevTier == nil and (not d.lastGrowlMin or (now - d.lastGrowlMin) >= CD.BARK_COOLDOWN_MIN))
        or not d.lastGrowlMin or (now - d.lastGrowlMin) >= CD.SENTINEL_AWARE_COOLDOWN_MIN then
        d.lastGrowlMin = now
        emitSound(animal, CD.GROWL_SOUND)
    end

    if prevTier == nil then
        CD.addSkillXP(animal, "scent", CD.SCENT_XP_PER_DETECT)
    end

    d.alertTier = tier
    if escalated then CD.transmit(animal) end
end

-- Auto-feed: um companheiro com fome/sede se serve sozinho de um Feeding Trough colocado ("tigela de cao"). Tudo isso
-- e server-authoritative (roda no loop do companion) e consome o estoque do trough, o custo simetrico. NUNCA concede
-- lealdade (isso continua sendo mecanica de mao/carinho). Uma vez comprometido, IGNORA zumbis e outras distracoes;
-- so um comando do owner (ou um veiculo / uma tigela inalcancavel) interrompe. Ver CompanionDogs_Config.lua (TROUGH_*).

-- O que um cao come de um IsoFeedingTrough vanilla (que guarda itens reais): comida de cao + os eat-types do trough
-- (CD.isTroughFood). Nossa propria tigela e mais ampla (CD.isBowlFood) ja que o conteudo dela e so pontos, nao o item.
local function troughItemEdible(item)
    return CD.isTroughFood(item)
end

local function troughHasFood(trough)
    local cont
    pcall(function() cont = trough:getContainer() end)
    if not cont then return false end
    local items = cont:getItems()
    if not items then return false end
    for i = 0, items:size() - 1 do
        if troughItemEdible(items:get(i)) then return true end
    end
    return false
end

local function troughHasWater(trough)
    local w = 0
    pcall(function() w = trough:getWater() end)
    return w ~= nil and w > 0
end

-- Consome cerca de uma refeicao do trough. Um item Food solto e comido inteiro; um saco de racao (DrainableComboItem)
-- cede ~0.5 de fome em usos e so e removido quando esvazia. A remocao de item inteiro e replicada do jeito que o
-- proprio eat path da engine faz (AnimalData.eatItem: GameServer.sendRemoveItemFromContainer antes do container.Remove,
-- gated no server) pra que clients co-op nao vejam um item fantasma no trough. Esse loop so roda server/SP-side
-- (companionTick e registrado atras de `not isClient()`), entao o delete server-side nunca aciona o AntiCheat do client.
local function consumeTroughFood(trough)
    local cont
    pcall(function() cont = trough:getContainer() end)
    if not cont then return end
    local items = cont:getItems()
    if not items then return end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if troughItemEdible(item) then
            local done = false
            pcall(function()
                if instanceof(item, "DrainableComboItem") then
                    -- DrainableComboItem NAO tem getter getUsedDelta() (so o setter); le o preenchimento via
                    -- getCurrentUsesFloat() (0..1). Drena ~5 usos por refeicao, removendo o saco so quando esvazia.
                    local du = (item.getUseDelta and item:getUseDelta()) or 0.1
                    local cur = (item.getCurrentUsesFloat and item:getCurrentUsesFloat()) or 1
                    local target = cur - du * 5
                    if target <= 0.0001 then
                        if isServer() then sendRemoveItemFromContainer(cont, item) end
                        cont:Remove(item)
                    else
                        item:setUsedDelta(target)
                        if item.syncItemFields then item:syncItemFields() end
                    end
                else
                    -- Food comum (incl. racao seca de cao): drena uma porcao do seu valor de fome por refeicao (pra que um
                    -- DogFoodBag grande dure varias refeicoes); remove o item inteiro so quando sobra pouco pra uma porcao.
                    local hc = (item.getHungerChange and item:getHungerChange()) or 0  -- negativo
                    local portion = CD.TROUGH_FOOD_PORTION or 10
                    if hc >= -portion then
                        -- Trata ReplaceOnUse pra Food (deixa a lata/pote vazio); remove raw pra nao-Food (grama/feno).
                        if instanceof(item, "Food") then
                            item:setHungChange(0); item:UseAndSync()
                        else
                            if isServer() then sendRemoveItemFromContainer(cont, item) end
                            cont:Remove(item)
                        end
                    else
                        if item.multiplyFoodValues then item:multiplyFoodValues((hc + portion) / hc) end
                        if item.syncItemFields then item:syncItemFields() end
                    end
                end
                done = true
            end)
            if done then
                -- Espelha o sync de comer no trough da engine (AnimalData.eatItem): marca o container dirty + sincroniza
                -- os fields do item pra que um drain parcial chegue nos clients co-op do mesmo jeito que o feed vanilla faz.
                pcall(function() cont:setDrawDirty(true) end)
                pcall(function() trough:checkOverlayAfterAnimalEat() end)
                pcall(function() trough:updateLuaObject() end)
                return
            end
        end
    end
end

local function consumeTroughWater(trough, amount)
    pcall(function() trough:removeWater(amount) end)
    pcall(function() trough:checkOverlayAfterAnimalEat() end)
    -- Espelha AnimalData.drink: atualiza o estado do global-object do trough (SFeedingTrough) pra que a agua persista no server.
    pcall(function() trough:updateLuaObject() end)
end

local function troughAt(x, y, z)
    local cell = getCell()
    if not cell then return nil end
    local sq = cell:getGridSquare(x, y, z)
    if not sq then return nil end
    local objs = sq:getObjects()
    if not objs then return nil end
    for i = 0, objs:size() - 1 do
        local o = objs:get(i)
        if instanceof(o, "IsoFeedingTrough") then return o end
    end
    return nil
end

-- Nossa PROPRIA tigela largada (CompanionDogs_Config.DISH_TYPE): a estacao de alimentacao E o item de inventario do
-- mundo, e guarda comida XOR agua no seu ModData como um budget de restauracao 0..100 (cdFoodMeals = pontos de comida,
-- cdWater = pontos de agua; nunca os dois). Tudo isso roda server/SP-side (companionTick), entao leituras/escritas sao
-- authoritative + safe.
local function dishStock(item, kind)
    local md = item:getModData()
    if kind == "water" then return md.cdWater or 0 end
    return md.cdFoodMeals or 0
end

-- A tigela num square que ainda tem estoque do tipo desejado ("food"/"water"): retorna (worldObj, item) ou nil.
-- Uma unica tigela guarda os dois, entao o tipo vem da necessidade do chamador, nao do item.
local function dishAt(x, y, z, wantKind)
    local cell = getCell()
    if not cell then return nil end
    local sq = cell:getGridSquare(x, y, z)
    if not sq then return nil end
    local wobs = sq.getWorldObjects and sq:getWorldObjects()
    if not wobs then return nil end
    for i = 0, wobs:size() - 1 do
        local wo = wobs:get(i)
        local item = wo.getItem and wo:getItem()
        if item and CD.isDishType(item:getFullType()) and dishStock(item, wantKind) > 0 then
            return wo, item
        end
    end
    return nil
end

-- Consome `points` do budget de comida da tigela + atualiza o visual (a tigela volta ao modelo vazio quando o estoque
-- chega a 0); transmitModData replica o novo estoque E a troca de modelo pros clients co-op.
-- NOTA: estes so atualizam o ModData do item + o VISUAL no mundo (refreshDishModel). O numero de ESTOQUE que o client ve
-- e replicado separadamente via CD.broadcastDishStock no meal-landing (o antigo item:transmitModData() aqui era dead
-- code, InventoryItem nao tem esse metodo, entao um client de dedicated-server nunca via o drain).
local function consumeDishFood(item, points)
    pcall(function()
        local md = item:getModData()
        md.cdFoodMeals = math.max(0, (md.cdFoodMeals or 0) - (points or 0))
        if CD.refreshDishModel then CD.refreshDishModel(item) end
    end)
end

local function consumeDishWater(item, amount)
    pcall(function()
        local md = item:getModData()
        md.cdWater = math.max(0, (md.cdWater or 0) - amount)
        if CD.refreshDishModel then CD.refreshDishModel(item) end
    end)
end

-- Fonte de alimentacao com estoque mais proxima do cao: um IsoFeedingTrough construido pelo player OU uma das NOSSAS
-- tigelas largadas (o item E a estacao). Retorna (obj, kind, x, y, z, isDish, item) onde obj e pra onde o cao encara/mede,
-- o x/y/z e o square inteiro pra onde fazer path, isDish marca uma tigela (o item carrega o estoque), ou nil se nada no raio.
local function findTroughNear(animal, radius, wantFood, wantWater)
    local cell = getCell()
    if not cell then return nil end
    local ax = math.floor(animal:getX())
    local ay = math.floor(animal:getY())
    local az = math.floor(animal:getZ())
    local R = math.ceil(radius)
    local best, bestKind, bestDist, bestDish, bestItem = nil, nil, radius + 1, false, nil
    local bx, by, bz
    for dx = -R, R do
        for dy = -R, R do
            local sq = cell:getGridSquare(ax + dx, ay + dy, az)
            if sq then
                local objs = sq:getObjects()
                if objs then
                    for i = 0, objs:size() - 1 do
                        local o = objs:get(i)
                        if instanceof(o, "IsoFeedingTrough") then
                            local kind
                            if wantFood and troughHasFood(o) then kind = "food"
                            elseif wantWater and troughHasWater(o) then kind = "water" end
                            if kind then
                                local dist = CD.dist2D(animal, o)
                                if dist <= radius and dist < bestDist then
                                    best, bestKind, bestDist, bestDish, bestItem = o, kind, dist, false, nil
                                    bx, by, bz = o:getX(), o:getY(), o:getZ()
                                end
                            end
                        end
                    end
                end
                -- nossa tigela largada (guarda comida E agua no seu ModData): escolhe o tipo que o cao precisa + que tem estoque
                local wobs = sq.getWorldObjects and sq:getWorldObjects()
                if wobs then
                    for i = 0, wobs:size() - 1 do
                        local wo = wobs:get(i)
                        local item = wo.getItem and wo:getItem()
                        if item and CD.isDishType(item:getFullType()) then
                            local kind
                            if wantFood and dishStock(item, "food") > 0 then kind = "food"
                            elseif wantWater and dishStock(item, "water") > 0 then kind = "water" end
                            if kind then
                                local dist = CD.dist2D(animal, wo)
                                if dist <= radius and dist < bestDist then
                                    best, bestKind, bestDist, bestDish, bestItem = wo, kind, dist, true, item
                                    bx, by, bz = sq:getX(), sq:getY(), sq:getZ()
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if best then return best, bestKind, bx, by, bz, bestDish, bestItem end
    return nil
end

-- Anda ate o tile da tigela com a disciplina de path do followOwner (ver pz-b42-pathto-setdata-cancels-async-astar):
-- pathToLocation cancela o A* assincrono em voo, entao emite SO em goal novo / stall de progresso / path falho, e nunca
-- mais rapido que FOLLOW_PATH_RESOLVE_MS; nas demais passadas so re-afirma o node mover (bPathfind, sem setData).
local function walkToFeedTile(animal, d, gx, gy, gz, run, nowMs)
    letMove(animal)
    pcall(function()
        animal:setVariable("animalRunning", run == true)
        animal:setVariable("animalSpeed", run and CD.runAnimSpeed() or CD.walkAnimSpeed())
    end)
    -- shouldFollowWall residual = o A* retornou Failed (mesmo tratamento do follow): limpa e conta como pedido de re-path.
    local pathFailed = false
    pcall(function() pathFailed = animal:shouldFollowWall() end)
    if pathFailed then pcall(function() animal:setShouldFollowWall(false) end) end
    local pt = d.feedPathTile
    local sameGoal = pt and pt.x == gx and pt.y == gy and pt.z == gz
    local sinceIssue = (sameGoal and d.feedPathMs) and (nowMs - d.feedPathMs) or 999999
    local stalled = d.feedProgressMs and (nowMs - d.feedProgressMs) >= (CD.TROUGH_REPATH_STALL_MS or 1200)
    if sameGoal and sinceIssue < (CD.FOLLOW_PATH_RESOLVE_MS or 1500) then forcePathfind(animal); return end
    if sameGoal and not stalled and not pathFailed then forcePathfind(animal); return end
    d.feedPathTile = { x = gx, y = gy, z = gz }
    d.feedPathMs = nowMs
    pcall(function() animal:pathToLocation(gx, gy, gz) end)
    forcePathfind(animal)
end

-- O indicador "indo comer" / "comendo" que o owner ve (nametag). Transmit so na mudanca pra que replique no co-op.
local function setAutoFeedTag(animal, d, state, kind)
    if d.autoFeeding == state and d.autoFeedKind == kind then return end
    -- Saindo do estado "eating" (refeicao concluida, ou alimentacao cancelada): para o som de comer em loop + a animacao de comer.
    -- Cobre TODO caminho de saida ja que este e o unico que escreve d.autoFeeding.
    if d.autoFeeding == "eating" then
        pcall(function() emitStopSound(animal, CD.FEED_SOUNDS.food) end)
        pcall(function() emitStopSound(animal, CD.FEED_SOUNDS.water) end)
        emitEatVar(animal, false, CD.EAT_ANIM_VAR)
        emitEatVar(animal, false, CD.DRINK_ANIM_VAR)
    end
    d.autoFeeding = state
    -- "food"/"water" pra que o nametag possa dizer beber em vez de comer. Limpo junto com o estado.
    d.autoFeedKind = state and kind or nil
    -- Fora de "going": derruba a contabilidade da caminhada (path/progresso/gait) pra proxima viagem comecar limpa.
    if state ~= "going" then
        d.feedPathTile = nil; d.feedPathMs = nil; d.feedBestGap = nil; d.feedProgressMs = nil; d.feedRun = nil
    end
    -- Entrando em "eating": segura o clip de comer (ou o clip de beber pra agua) durante o dwell.
    if state == "eating" then emitEatVar(animal, true, (kind == "water") and CD.DRINK_ANIM_VAR or CD.EAT_ANIM_VAR) end
    CD.transmit(animal)
end

-- Retorna true quando assumiu o movimento/idle do cao neste tick (andando ate ou comendo numa tigela).
local function tryAutoFeed(animal, owner, d)
    local hunger, thirst = 0, 0
    pcall(function()
        hunger = animal:getHunger()
        thirst = animal:getThirst()
    end)
    local trigger = CD.troughFeedTrigger(owner)
    local hungry = hunger >= trigger
    local thirsty = thirst >= trigger
    if not hungry and not thirsty then
        d.feedingTrough = nil
        d.feedStartMin = nil
        d.autoFeedRetryMs = nil
        setAutoFeedTag(animal, d, nil)
        return false
    end

    -- Esfriando depois de desistir de uma tigela inalcancavel: se comporta normalmente por um tempo antes de tentar de novo.
    if d.autoFeedRetryMs and getTimestampMs() < d.autoFeedRetryMs then
        setAutoFeedTag(animal, d, nil)
        return false
    end

    -- Nunca sai de um veiculo pra se alimentar.
    local inVehicle = false
    pcall(function() inVehicle = animal:getVehicle() ~= nil end)
    if inVehicle then setAutoFeedTag(animal, d, nil); return false end

    -- Nao abandona um ataque COMANDADO pelo player pra ir comer: espera a janela do ataque acabar.
    if d.attackUntilMin and worldMinutes() < d.attackUntilMin then
        setAutoFeedTag(animal, d, nil)
        return false
    end
    -- Um comando do owner (Follow/Stay/Guard/select carimba d.feedYieldUntilMin) interrompe a auto-alimentacao pra que o
    -- cao obedeca AGORA. Este e o UNICO interrupt: um cao se alimentando ignora zumbis e toda outra distracao (ver abaixo).
    -- Solta a tigela cacheada pra que ele nao a readquira no mesmo tick.
    if d.feedYieldUntilMin and worldMinutes() < d.feedYieldUntilMin then
        d.feedingTrough = nil
        d.feedStartMin = nil
        setAutoFeedTag(animal, d, nil)
        return false
    end
    -- Durante o FOLLOW, nao COMECA a andar ate uma tigela que ja esta alem da coleira (deixa a teleport-recovery do
    -- followOwner rodar em vez disso). Mas uma vez COMPROMETIDO com uma tigela (d.feedingTrough setado), a coleira NAO
    -- deve abortar a viagem: o owner se afastando, ou pulando uma cerca que o cao precisa CONTORNAR, faz dist2D disparar
    -- transitoriamente alem da coleira e cancelaria a refeicao no meio do caminho (por design, SO um comando do owner
    -- interrompe um feed). O raio de aquisicao (16 a partir do cao) mais o give-up por falta de progresso ja limitam o
    -- quanto ele pode se afastar. Stay/Guard fica postado longe de proposito, entao isto so se aplica ao follow.
    if owner and not d.feedingTrough and CD.getState(animal) == CD.STATE_FOLLOW and CD.dist2D(animal, owner) > CD.TELEPORT_DIST then
        setAutoFeedTag(animal, d, nil)
        return false
    end

    -- Resolve uma fonte de alimentacao alvo: revalida a cacheada a cada tick (troughs/tigelas nao se movem); rescans com throttle.
    local trough, kind, tx, ty, tz, isDish, feedItem
    local cache = d.feedingTrough
    local transientMiss = false
    if cache then
        local hit = false
        if cache.dish then
            local wo, item = dishAt(cache.x, cache.y, cache.z, cache.kind)  -- ja filtrado pra cache.kind + com estoque
            if wo then
                trough, kind, tx, ty, tz, isDish, feedItem = wo, cache.kind, cache.x, cache.y, cache.z, true, item
                hit = true
            end
        else
            local t = troughAt(cache.x, cache.y, cache.z)
            if t and ((cache.kind == "food" and troughHasFood(t)) or (cache.kind == "water" and troughHasWater(t))) then
                trough, kind, tx, ty, tz, isDish, feedItem = t, cache.kind, cache.x, cache.y, cache.z, false, nil
                hit = true
            end
        end
        if hit then
            d.feedMissCount = nil
        else
            -- MISS na revalidacao. Um miss de UM frame so (um refresh de square no co-op, uma leitura momentanea de estoque)
            -- NAO deve soltar o cache e entregar o cao ao branch de panico/follow abaixo. Esse ping-pong e o bug "cao nervoso
            -- oscila entre comer e recuar". Tolera alguns misses consecutivos, mantendo o compromisso com o tile cacheado;
            -- so apos FEED_MISS_TOLERANCE misses (uma tigela genuinamente esvaziada / removida) solta o alvo.
            d.feedMissCount = (d.feedMissCount or 0) + 1
            if d.feedMissCount >= (CD.FEED_MISS_TOLERANCE or 3) then
                d.feedingTrough = nil; d.feedStartMin = nil; d.feedMissCount = nil
            else
                transientMiss = true
            end
        end
    end
    -- Mantem o controle atraves de um miss transitorio: continua andando ate o tile cacheado (ou segura se ja estiver la)
    -- pra que o controle nunca pule pro branch de panico por um frame. No proximo tick re-resolve a tigela e retoma a logica
    -- normal de gap/comer. O give-up por falta de progresso e o cap de miss ficam sendo os backstops reais pra uma tigela inalcancavel / sumida.
    if transientMiss and cache then
        local cx, cy, cz = cache.x, cache.y, cache.z
        local ddx, ddy = animal:getX() - (cx + 0.5), animal:getY() - (cy + 0.5)
        if math.sqrt(ddx * ddx + ddy * ddy) > CD.TROUGH_REACH_DIST then
            setAutoFeedTag(animal, d, "going", cache.kind)
            walkToFeedTile(animal, d, math.floor(cx), math.floor(cy), math.floor(cz), d.feedRun == true, getTimestampMs())
        else
            pcall(function()
                animal:setVariable("animalRunning", false)
                animal:setVariable("animalSpeed", 0)
                animal:stopAllMovementNow()
            end)
            holdStill(animal)
        end
        return true
    end
    if not trough then
        local nowScan = getTimestampMs()
        if d.lastTroughScanMs and (nowScan - d.lastTroughScanMs) < (CD.TROUGH_SCAN_THROTTLE_MS or 2000) then
            setAutoFeedTag(animal, d, nil)
            return false
        end
        d.lastTroughScanMs = nowScan
        local t, k, ox, oy, oz, dsh, item = findTroughNear(animal, CD.troughFeedRadius(), hungry, thirsty)
        if not t then setAutoFeedTag(animal, d, nil); return false end
        trough, kind, tx, ty, tz, isDish, feedItem = t, k, ox, oy, oz, dsh, item
        d.feedingTrough = { x = ox, y = oy, z = oz, kind = k, dish = dsh }
        d.feedBestGap = nil; d.feedProgressMs = nil; d.feedPathTile = nil  -- alvo novo: progresso/path zeram, nada herdado da caminhada anterior
    end

    -- Um cao comprometido com o feed IGNORA zumbis (e todo o resto): uma vez indo ate / comendo numa tigela, so um comando
    -- do owner o interrompe (tratado acima). O cao e invencivel ao melee dos zumbis, entao isto e safe; o owner ainda pode
    -- ordenar um ataque pra puxa-lo pra briga. Solta qualquer lock de combate velho pra que a recuperacao de HP e de
    -- combat-stress do updateUpkeep (ambas gated em `not d.inCombat`) retomem enquanto o cao come. E isso que deixa uma refeicao tirar um panico.
    if d.inCombat or d.retreating then CD.setInCombat(animal, d, false); d.retreating = false end
    combatTarget[animal:getOnlineID()] = nil

    -- Mede ate o CENTRO do TILE da tigela, nao CD.dist2D: o getX() do trough/tigela e o canto inteiro do tile (IsoObject) ja
    -- que animal:getX() e continuo (~tile+0.5), entao dist2D le ~0.7 a menos mesmo com o cao em pe SOBRE o tile da tigela e
    -- o cap de 0.85 nunca era alcancado -> "chegou perto, parou, nunca comeu". Espelha o branch transientMiss acima.
    local gdx, gdy = animal:getX() - (tx + 0.5), animal:getY() - (ty + 0.5)
    local gap = math.sqrt(gdx * gdx + gdy * gdy)
    if gap > CD.TROUGH_REACH_DIST then
        local nowMs = getTimestampMs()
        -- Progresso = minimo monotono do gap (tolera contornos que afastam temporariamente). Distancia nunca desiste
        -- sozinha; so a falta TOTAL de progresso por TROUGH_GIVEUP_STALL_MS desiste (ms reais: caminhada e tempo real,
        -- game-min escala com o day length e estourava viagens legitimas).
        if not d.feedBestGap or gap < d.feedBestGap - (CD.TROUGH_PROGRESS_EPS or 0.25) then
            d.feedBestGap = gap
            d.feedProgressMs = nowMs
        end
        if (nowMs - d.feedProgressMs) > (CD.TROUGH_GIVEUP_STALL_MS or 15000) then
            -- Nao consegue chegar na tigela (murada / sem caminho). Desiste pra que o cao nao fique preso andando e ignorando
            -- o owner; retoma o comportamento normal e nao tenta de novo por um tempo.
            d.feedingTrough = nil
            d.autoFeedRetryMs = nowMs + (CD.TROUGH_RETRY_COOLDOWN_MS or 45000)
            setAutoFeedTag(animal, d, nil)
            return false
        end
        -- Corre quando longe (mesma histerese do follow) pra um cao com fome nao levar uma era ate uma tigela a 16 tiles.
        local run = d.feedRun == true
        if gap > (CD.FOLLOW_RUN_DIST or 5) then run = true
        elseif gap <= (CD.FOLLOW_START_DIST or 2) + 1 then run = false end
        d.feedRun = run
        setAutoFeedTag(animal, d, "going", kind)
        walkToFeedTile(animal, d, math.floor(tx), math.floor(ty), math.floor(tz), run, nowMs)
        return true
    end

    -- Na tigela: encara, fixa, espera o dwell, e ai a refeicao acontece.
    pcall(function()
        animal:setVariable("animalRunning", false)
        animal:setVariable("animalSpeed", 0)
        animal:faceThisObject(trough)
        animal:stopAllMovementNow()
    end)
    holdStill(animal)

    local now = worldMinutes()
    if d.autoFeeding ~= "eating" then
        d.feedStartMin = now
        setAutoFeedTag(animal, d, "eating", kind)
        pcall(function() emitSound(animal, CD.FEED_SOUNDS[kind] or CD.FEED_SOUNDS.food) end)
        return true
    end
    if not d.feedStartMin or (now - d.feedStartMin) < CD.TROUGH_EAT_DWELL_MIN then
        return true
    end

    -- A refeicao acontece: corta a necessidade, drena a fonte, alivia um pouco de stress (ajuda a quebrar um panico vindo de
    -- necessidades). Sem lealdade. Nossa tigela e um budget de restauracao 0..100 limitado por visita pela config de restore E
    -- pelo estoque que sobra. O cao come/bebe so o que PRECISA (foodApplied = min(cap por visita, necessidade atual)) e a tigela
    -- perde exatamente isso, entao completar 10 de fome custa 10 da tigela, nao os 50 inteiros. Um trough vanilla mantem seu drain fixo por gole.
    local foodRestore, waterRestore = CD.troughHungerRestore(), CD.troughThirstRestore()
    if isDish then
        if kind == "water" then waterRestore = math.min(waterRestore, dishStock(feedItem, "water") / 100)
        else foodRestore = math.min(foodRestore, dishStock(feedItem, "food") / 100) end
    end
    local foodApplied = math.min(foodRestore, hunger)
    local waterApplied = math.min(waterRestore, thirst)
    if kind == "water" then
        setNeed(animal, "thirst", math.max(0, thirst - waterApplied))
    else
        setNeed(animal, "hunger", math.max(0, hunger - foodApplied))
    end
    if kind == "water" then
        if isDish then consumeDishWater(feedItem, waterApplied * 100)
        else consumeTroughWater(trough, CD.TROUGH_WATER_PER_DRINK) end
    else
        if isDish then consumeDishFood(feedItem, foodApplied * 100)
        else consumeTroughFood(trough) end
    end
    -- Replica o estoque drenado pra que um client de dedicated-server olhando a tigela a veja baixar conforme o cao come.
    if isDish and CD.broadcastDishStock then
        pcall(function() CD.broadcastDishStock(tx, ty, tz, feedItem:getModData()) end)
    end
    CD.addCombatStress(animal, -0.2)
    d.feedingTrough = nil
    d.feedStartMin = nil
    d.autoFeedRetryMs = nil
    d.lastTroughEatMin = now
    setAutoFeedTag(animal, d, nil)
    CD.transmit(animal)
    return true
end

-- ===== Caca assistida ==================================================================================
-- Um companheiro em modo Hunt (toggle por cao) rastreia caca selvagem enquanto esta em Follow e, uma vez treinado,
-- persegue e abate. Server-authoritative (roda no loop do companion), espelha os templates de auto-feed/combate. Os niveis
-- liberam a capacidade: qualquer nivel aponta/rastreia, HuntSmallLevel abate caca pequena, HuntLargeLevel desgasta caca grande.
-- Custo simetrico: o cao deixa o lado do owner, a perseguicao late (addSound -> atrai zumbis), caca grande pode
-- machuca-lo, ele pode se afastar (coleira + cooldown de desistencia), e cacar abre o apetite. Animais selvagens spawnam
-- via as AnimalZones de floresta/rural da engine, entao cacar e naturalmente uma atividade do campo (nada pra cacar na cidade).

-- Classificacao de presa por tipo de animal. isWild() ja filtra pra fauna selvagem (coelho/cervo/guaxinim/camundongo/rato);
-- isto separa pequena vs grande e exclui qualquer coisa nao reconhecida (caes, futuros grandes predadores) retornando nil.
local HUNT_SMALL_PREFIX = { "rab", "raccoon", "mouse", "rat", "squirrel" }
local HUNT_LARGE_TYPES = { fawn = true, doe = true, buck = true, deer = true }
local function huntPreyClass(o)
    local t = o.getAnimalType and o:getAnimalType()
    if not t then return nil end
    if HUNT_LARGE_TYPES[t] then return "large" end
    for _, p in ipairs(HUNT_SMALL_PREFIX) do
        if string.sub(t, 1, string.len(p)) == p then return "small" end
    end
    return nil
end

local function isHuntablePrey(animal, o)
    if o == animal or not instanceof(o, "IsoAnimal") then return false end
    local wild = false
    pcall(function() wild = o:isWild() end)          -- companions/strays sao setWild(false) -> excluidos
    if not wild then return false end
    local dead = true
    pcall(function() dead = o:isDead() end)
    if dead then return false end
    return huntPreyClass(o) ~= nil
end

-- Animal selvagem cacavel mais proximo do cao (espelho de scanZombies, usando sq:getAnimals()).
local function scanWildAnimals(animal, radius)
    local cell = getCell()
    if not cell then return nil, 0 end
    local ax, ay, az = math.floor(animal:getX()), math.floor(animal:getY()), math.floor(animal:getZ())
    local R = math.ceil(radius)
    local best, bestDist, count = nil, radius, 0
    for dx = -R, R do
        for dy = -R, R do
            local sq = cell:getGridSquare(ax + dx, ay + dy, az)
            if sq then
                local list = sq:getAnimals()
                if list then
                    for i = 0, list:size() - 1 do
                        local o = list:get(i)
                        if isHuntablePrey(animal, o) then
                            local dd = CD.dist2D(animal, o)
                            if dd <= radius then
                                count = count + 1
                                if dd <= bestDist then best, bestDist = o, dd end
                            end
                        end
                    end
                end
            end
        end
    end
    return best, count
end

-- O selo de nametag "tracking"/"chasing"/"retrieving". Transmit so na mudanca pra que replique no co-op.
local function setHuntTag(animal, d, state)
    if d.hunting == state then return end
    d.hunting = state
    CD.transmit(animal)
end

local function addHuntXP(animal, amount)
    CD.addSkillXP(animal, "hunt", amount * CD.huntXPRate())
end

-- Latido de caca: reusa o cooldown global de latido; o addSound (atrai zumbis) e gated + throttled como o sentinel.
local function huntBark(animal, d)
    if not bark(animal) then return end
    if not CD.huntBarkAttracts() then return end
    local now = worldMinutes()
    if d.lastHuntNoiseMin and (now - d.lastHuntNoiseMin) < CD.SENTINEL_NOISE_COOLDOWN_MIN then return end
    d.lastHuntNoiseMin = now
    pcall(function()
        addSound(animal, math.floor(animal:getX()), math.floor(animal:getY()), math.floor(animal:getZ()),
            CD.HUNT_BARK_RADIUS, CD.HUNT_BARK_VOLUME)
    end)
end

local function bumpHuntHunger(animal)
    pcall(function()
        local h = math.min(1, (animal:getHunger() or 0) + CD.huntHungerPerHunt())
        setNeed(animal, "hunger", h)
    end)
end

-- Solta a presa atual + o latch de alerta + o timeout de caminhada (perdida/desistida/morta). Mantem o cooldown de desistencia setado pelo chamador.
local function dropHuntTarget(animal, d)
    local id = animal:getOnlineID()
    -- libera um cervo que estavamos prendendo (ver o bloco de hold "PIN the deer") pra que ele possa se mover de novo se sobreviveu.
    local held = huntWoundedRef[id]
    if held then pcall(function() local b = held:getBehavior(); if b and b.setBlockMovement then b:setBlockMovement(false) end end) end
    huntPreyRef[id] = nil
    huntWoundedRef[id] = nil
    d.huntTargetId = nil
    d.huntGoingSinceMin = nil
    d.huntPointSinceMin = nil
    d.huntPointed = nil
    d.huntAlerted = nil
    d.huntGoalTx = nil
    d.huntGoalTy = nil
    d.huntProbeMs = nil
    d.huntSniffXp = nil
    setHuntTag(animal, d, nil)
end

-- Best-effort: move a carcaca do animal de onde ele morreu pro square do owner (a entrega do "retrieve"). O abate
-- ja largou um IsoDeadBody butcherable (setHealth(0)+killed); a realocamos via o proprio caminho addCorpse da engine
-- (mesma chamada que ButcheringUtil/ISAnimalContextMenu usam). Totalmente guarded: se o corpo nao puder ser achado/movido
-- ele so fica onde caiu. Pendente de validacao in-game.
local function relocateCorpseToOwner(kx, ky, kz, owner)
    local cell = getCell()
    if not cell or not owner then return end
    local ksq = cell:getGridSquare(kx, ky, kz)
    if not ksq then return end
    local osq = owner:getCurrentSquare()
        or cell:getGridSquare(math.floor(owner:getX()), math.floor(owner:getY()), math.floor(owner:getZ()))
    if not osq or osq == ksq then return end
    local bodies = ksq.getDeadBodys and ksq:getDeadBodys()
    if not bodies then return end
    for i = bodies:size() - 1, 0, -1 do
        local body = bodies:get(i)
        local isAnimalCorpse = false
        pcall(function() isAnimalCorpse = body:getModData() and body:getModData()["AnimalType"] ~= nil end)
        if isAnimalCorpse then
            pcall(function() body:removeFromWorld() end)
            pcall(function() body:removeFromSquare() end)
            pcall(function() osq:addCorpse(body, false) end)
            return
        end
    end
end

-- Um golpe na presa dentro do alcance. Caca pequena -> morta + creditada ao owner (carcaca butcherable) A MENOS que o cao
-- esteja com fome, caso em que ele come o que pegou (sem carcaca; o food governor + auto-alimentacao). Caca grande -> desgaste
-- sub-letal (nunca morta sozinho; o owner finaliza), e o cervo pode chutar o cao de volta (stress + um pequeno ferimento).
local function huntStrike(animal, owner, prey, d, cls, huntLevel)
    local now = worldMinutes()
    if d.lastHuntHitMin and (now - d.lastHuntHitMin) < CD.HUNT_HIT_COOLDOWN_MIN then return end

    if cls == "large" then
        local h = 1
        pcall(function() h = prey:getHealth() end)
        if h <= CD.HUNT_DEER_WOUND_FLOOR + 0.001 then
            -- desgastado ate o floor: SEGURA o cervo pro owner (selo + um alerta), ficando nele (o branch ENGAGE
            -- o re-prende se ele fugir). Se o owner nao finalizar dentro de HUNT_DEER_HOLD_MIN, o cao o finaliza
            -- sozinho (o owner ainda fica creditado com a carcaca butcherable), entao um cervo preso nunca e desperdicado.
            d.huntDeerHeldSinceMin = d.huntDeerHeldSinceMin or now
            setHuntTag(animal, d, "holding")
            pcall(function() animal:faceThisObject(prey) end)
            if not d.huntDeerHeldNotified then
                d.huntDeerHeldNotified = true
                CD.notifyOwner(owner, "huntwoundeddeer", { id = animal:getOnlineID(), breed = CD.getBreed(animal) })
            end
            if (now - d.huntDeerHeldSinceMin) > CD.HUNT_DEER_HOLD_MIN then
                local finished = false
                pcall(function() prey:setHealth(0); prey:killed(owner); finished = true end)
                if finished then
                    d.preyKills = (d.preyKills or 0) + 1
                    addHuntXP(animal, CD.HUNT_XP_PER_SMALL_KILL)
                    bumpHuntHunger(animal)
                    CD.notifyOwner(owner, "huntkill", { id = animal:getOnlineID(), breed = CD.getBreed(animal) })
                end
                d.woundedPrey = nil; d.huntDeerHeldSinceMin = nil; d.huntDeerHeldNotified = nil
                dropHuntTarget(animal, d)
            end
            return
        end
        d.huntDeerHeldSinceMin = nil
        d.lastHuntHitMin = now
        emitSound(animal, CD.BITE_SOUND)
        emitAnim(animal)
        pcall(function()
            local nh = h - CD.HUNT_DEER_WOUND
            if nh < CD.HUNT_DEER_WOUND_FLOOR then nh = CD.HUNT_DEER_WOUND_FLOOR end
            prey:setHealth(nh)
        end)
        addHuntXP(animal, CD.HUNT_XP_PER_LARGE_HIT)
        bumpHuntHunger(animal)
        -- marca como presa ferida pra que o cao continue rastreando/guiando o owner mesmo se ela fugir do player (ref direta
        -- pra que o hold sobreviva no SP; a janela sticky dura mais que o timer do hold pra que nao expire antes da finalizacao).
        d.woundedPrey = { id = prey:getOnlineID(), untilMin = now + CD.HUNT_DEER_HOLD_MIN + CD.HUNT_GOING_TIMEOUT_MIN }
        huntWoundedRef[animal:getOnlineID()] = prey
        if CD.huntDeerCanHurtDog() and ZombRand(0, 1000) < CD.HUNT_DEER_DOG_HURT_CHANCE * 1000 then
            CD.addCombatStress(animal, CD.huntDeerDogStress())
            -- fere o cao: a invencibilidade precisa ser tirada pra aplicar o dano, depois re-afirmada (sem interleave), como o updateUpkeep.
            -- Floor em 0.05 pra que um cervo possa FERIR o cao mas nunca MATA-lo (permadeath fica so por neglect, por design).
            pcall(function()
                animal:setIsInvincible(false)
                animal:setHealth(math.max(0.05, animal:getHealth() - CD.HUNT_DEER_DOG_DAMAGE))
                animal:setIsInvincible(true)
            end)
        end
        CD.transmit(animal)
        return
    end

    -- caca pequena
    d.lastHuntHitMin = now
    emitSound(animal, CD.BITE_SOUND)
    emitAnim(animal)
    local kx, ky, kz = math.floor(prey:getX()), math.floor(prey:getY()), math.floor(prey:getZ())
    local hungry = false
    pcall(function() hungry = (animal:getHunger() or 0) >= CD.troughFeedTrigger(owner) end)
    if hungry then
        -- o cao come o que pegou: sem carcaca pro owner (governor + auto-feed). delete() e o despawn network-correct.
        pcall(function() prey:delete() end)
        pcall(function()
            local nh = math.max(0, (animal:getHunger() or 0) - CD.troughHungerRestore())
            setNeed(animal, "hunger", nh)
        end)
        d.preyKills = (d.preyKills or 0) + 1
        addHuntXP(animal, CD.HUNT_XP_PER_SMALL_KILL)
        CD.addCombatStress(animal, -0.05)
        dropHuntTarget(animal, d)
        CD.transmit(animal)
        return
    end

    -- mata + credita o owner -> a engine larga um corpo butcherable no square da presa.
    local killed = false
    pcall(function()
        prey:setHealth(0)
        prey:killed(owner)
        killed = true
    end)
    if not killed then dropHuntTarget(animal, d); return end
    d.preyKills = (d.preyKills or 0) + 1
    addHuntXP(animal, CD.HUNT_XP_PER_SMALL_KILL)
    bumpHuntHunger(animal)
    d.huntTargetId = nil
    d.huntAlerted = nil
    -- entrega o abate ao owner em nivel alto; senao deixa onde caiu e so faz o halo.
    if CD.huntFetchEnabled() and huntLevel >= CD.huntFetchLevel() then
        d.huntRetrieve = { x = kx, y = ky, z = kz, untilMin = now + CD.HUNT_DELIVER_TIMEOUT_MIN, picked = false }
        setHuntTag(animal, d, "retrieving")
    else
        setHuntTag(animal, d, nil)
        CD.notifyOwner(owner, "huntkill", { id = animal:getOnlineID(), breed = CD.getBreed(animal) })
    end
    CD.transmit(animal)
end

-- O cao esta em modo Hunt sem presa selvagem por perto: se o CLIENT DO OWNER avistou um item de forage REAL perto do cao
-- (d.forageScoutTarget, setado por CompanionDogs_ForageScout.lua -> CD.Server.foragescout), ele leva o cao ate la, congela/
-- aponta (selo "foraging"), late uma vez + fareja + avisa o owner pra entrar no Search Mode, e ganha um pouco de Hunt XP. Depois
-- reporta + retorna (cooldown). Sem alvo do client (sem forage no alcance) -> o cao nao faz o scout. Nunca congela.
local function tryForagePoint(animal, owner, d)
    if not CD.huntForagePointEnabled() then
        if d.hunting == "foraging" then setHuntTag(animal, d, nil) end
        d.forageSpot = nil
        return false
    end
    local now = worldMinutes()
    if d.forageRetryMin and now < d.forageRetryMin then
        if d.hunting == "foraging" then setHuntTag(animal, d, nil) end
        d.forageSpot = nil
        return false
    end

    -- resolve o ponto a partir do alvo de forrageio fornecido pelo client do owner (o icone de forage REAL mais proximo do cao). Ele
    -- carrega um TTL; o client reenvia a cada game-minute enquanto persiste. Sem alvo (sem forage no alcance) -> sem scout.
    local tgt = d.forageScoutTarget
    if tgt and now > (tgt.untilMin or 0) then d.forageScoutTarget = nil; tgt = nil end
    if not tgt then
        if d.hunting == "foraging" then setHuntTag(animal, d, nil) end
        d.forageSpot = nil
        return false
    end
    local spot = d.forageSpot
    if not spot or spot.x ~= tgt.x or spot.y ~= tgt.y then
        spot = { x = tgt.x, y = tgt.y, z = tgt.z }
        d.forageSpot = spot
        d.foragePointSinceMin = nil
        d.forageGoingSinceMin = nil
        d.forageAlerted = nil
    end

    setHuntTag(animal, d, "foraging")
    local gx = animal:getX() - (spot.x + 0.5)
    local gy = animal:getY() - (spot.y + 0.5)
    if math.sqrt(gx * gx + gy * gy) > CD.FORAGE_ARRIVE_DIST then
        d.foragePointSinceMin = nil
        d.forageGoingSinceMin = d.forageGoingSinceMin or now
        if (now - d.forageGoingSinceMin) > CD.HUNT_GOING_TIMEOUT_MIN then
            -- nao consegue alcancar o ponto (bloqueado por agua/parede): desiste + esfria pra o cao voltar ao owner.
            d.forageRetryMin = now + CD.HUNT_FORAGE_RETRY_COOLDOWN_MIN
            d.forageSpot = nil; d.forageGoingSinceMin = nil
            setHuntTag(animal, d, nil)
            return false
        end
        moveTo(animal, false, CD.walkAnimSpeed(), spot.x, spot.y, spot.z)
        return true
    end
    d.forageGoingSinceMin = nil

    -- no ponto: reporta uma vez (bark + halo + XP), segura um instante apontando, depois desiste + esfria + volta ao owner.
    d.foragePointSinceMin = d.foragePointSinceMin or now
    if not d.forageAlerted then
        d.forageAlerted = true
        huntBark(animal, d)
        -- focinho no chao: pose de faro (Rac_Sniff). Pulso server-driven, limpa sozinho depois de alguns segundos + faz
        -- broadcast pros clients, entao sem cleanup manual nos caminhos de desistencia.
        pcall(function() CD.pulseSniffAnim(animal) end)
        CD.notifyOwner(owner, "foragefound", { id = animal:getOnlineID(), breed = CD.getBreed(animal) })
        if not d.lastHuntXpMin or (now - d.lastHuntXpMin) >= CD.HUNT_XP_COOLDOWN_MIN then
            d.lastHuntXpMin = now
            addHuntXP(animal, CD.HUNT_XP_PER_FORAGE_POINT)
        end
    end
    if (now - d.foragePointSinceMin) > CD.HUNT_FORAGE_POINT_DWELL_MIN then
        d.forageRetryMin = now + CD.HUNT_FORAGE_RETRY_COOLDOWN_MIN
        d.forageSpot = nil; d.foragePointSinceMin = nil; d.forageAlerted = nil
        setHuntTag(animal, d, nil)
        return false
    end
    pcall(function()
        animal:setVariable("animalRunning", false)
        animal:setVariable("animalSpeed", 0)
        animal:stopAllMovementNow()
    end)
    pcall(function() animal:faceLocation(spot.x, spot.y) end)
    holdStill(animal)
    return true
end

-- Retorna true quando assumiu o movimento/idle do cao neste tick (rastreando/perseguindo/recuperando presa).
local function tryHunt(animal, owner, d)
    if not CD.huntEnabled() or not CD.getHuntMode(animal) then
        if d.hunting then dropHuntTarget(animal, d) end
        if d.huntCooling then d.huntCooling = nil; CD.transmit(animal) end
        d.woundedPrey = nil; d.huntRetrieve = nil
        return false
    end
    -- fast-forward / owner dormindo: suprimido como o sentinel (nao caca durante o fast-forward do sono). Limpa o
    -- selo pra uma tag "chasing"/"tracking" nao grudar no head-stack enquanto pausado (huntRetrieve/woundedPrey retomam).
    local spd = getGameSpeed and getGameSpeed()
    if spd and spd > 1 then if d.hunting then setHuntTag(animal, d, nil) end; return false end
    if owner.isAsleep then
        local asleep = false
        pcall(function() asleep = owner:isAsleep() end)
        if asleep then if d.hunting then setHuntTag(animal, d, nil) end; return false end
    end
    -- nunca sai de um vehicle pra cacar.
    local inVehicle = false
    pcall(function() inVehicle = animal:getVehicle() ~= nil end)
    if inVehicle then if d.hunting then dropHuntTarget(animal, d) end; return false end

    local now = worldMinutes()
    -- um comando do owner (Follow/Stay/Guard/select carimba feedYieldUntilMin) ou um ataque comandado tira o cao da caca.
    if (d.feedYieldUntilMin and now < d.feedYieldUntilMin) or (d.attackUntilMin and now < d.attackUntilMin) then
        if d.hunting then dropHuntTarget(animal, d) end
        d.huntRetrieve = nil
        return false
    end

    local huntLevel = CD.getSkillLevel(animal, "hunt")

    -- (1) Leva um abate recente ao owner (maior sub-prioridade da caca).
    if d.huntRetrieve then
        local r = d.huntRetrieve
        if now > (r.untilMin or 0) then
            CD.notifyOwner(owner, "huntkill", { id = animal:getOnlineID(), breed = CD.getBreed(animal) })
            d.huntRetrieve = nil; setHuntTag(animal, d, nil)
            return false
        end
        setHuntTag(animal, d, "retrieving")
        if not r.picked then
            local gx = animal:getX() - (r.x + 0.5)
            local gy = animal:getY() - (r.y + 0.5)
            if math.sqrt(gx * gx + gy * gy) > CD.HUNT_STRIKE_DIST then
                letMove(animal)
                pcall(function()
                    animal:setVariable("animalRunning", false)
                    animal:setVariable("animalSpeed", CD.walkAnimSpeed())
                    animal:pathToLocation(r.x, r.y, r.z)
                end)
                forcePathfind(animal)
                return true
            end
            r.picked = true
        end
        local gap = CD.dist2D(animal, owner)
        if gap > CD.FOLLOW_START_DIST then
            letMove(animal)
            pcall(function()
                animal:setVariable("animalRunning", gap > CD.FOLLOW_RUN_DIST)
                animal:setVariable("animalSpeed", CD.walkAnimSpeed())
                animal:pathToCharacter(owner)
            end)
            forcePathfind(animal)
            return true
        end
        pcall(function() relocateCorpseToOwner(r.x, r.y, r.z, owner) end)
        CD.notifyOwner(owner, "huntdelivered", { id = animal:getOnlineID(), breed = CD.getBreed(animal) })
        d.huntRetrieve = nil
        setHuntTag(animal, d, nil)
        return true
    end

    -- esfriando depois de desistir de uma presa impossivel de pegar. Campo proprio (nao um selo de d.hunting) porque
    -- d.hunting nao-nil significa "tem objetivo de movimento proprio" pra cancelShoutNudge; aqui o cao esta so seguindo.
    if d.huntRetryMin and now < d.huntRetryMin then
        if d.hunting then dropHuntTarget(animal, d) end
        if not d.huntCooling then d.huntCooling = true; CD.transmit(animal) end
        return false
    end
    if d.huntCooling then d.huntCooling = nil; CD.transmit(animal) end

    -- (2) Resolve a presa: um animal grande ferido que estamos rastreando (grudento, guia o owner) > o alvo em cache > um rescan.
    local prey, preyCls
    if d.woundedPrey then
        if now < (d.woundedPrey.untilMin or 0) then
            local wp = huntWoundedRef[animal:getOnlineID()]
            local alive = false
            if wp then pcall(function() alive = not wp:isDead() end) end
            if alive then prey, preyCls = wp, "large"
            else d.woundedPrey = nil; d.huntDeerHeldNotified = nil end
        else
            d.woundedPrey = nil; d.huntDeerHeldNotified = nil
        end
    end
    local dogId = animal:getOnlineID()
    if not prey and huntPreyRef[dogId] then
        local t = huntPreyRef[dogId]
        local ok = false
        pcall(function() ok = isHuntablePrey(animal, t) and CD.dist2D(animal, t) <= CD.huntMaxLeash() end)
        if ok then
            prey, preyCls = t, huntPreyClass(t)
        else
            huntPreyRef[dogId] = nil; d.huntTargetId = nil; d.huntAlerted = nil
        end
    end
    if not prey then
        -- coleira em relacao ao owner: nao inicia uma caca se ja estiver longe demais (mantem preso tambem o cao em autonomia parada).
        if owner and CD.dist2D(animal, owner) > CD.huntMaxLeash() then
            if d.hunting then dropHuntTarget(animal, d) end
            d.forageSpot = nil
            return false
        end
        -- (re)scan de presa selvagem com throttle. Entre scans (e quando nenhuma e achada), o cao faz scout de forage no lugar.
        if not d.lastHuntScanMin or (now - d.lastHuntScanMin) >= CD.HUNT_SCAN_THROTTLE_MIN then
            d.lastHuntScanMin = now
            local nearest = scanWildAnimals(animal, CD.effectiveHuntRadius(animal))
            if nearest then
                prey, preyCls = nearest, huntPreyClass(nearest)
                huntPreyRef[dogId] = nearest
                pcall(function() d.huntTargetId = prey:getOnlineID() end)
                d.huntGoingSinceMin = nil
                d.huntAlerted = nil
            end
        end
        if not prey then
            -- presa vista ha muito pouco tempo: mantem o cao perto do owner pronto pra readquirir em vez de sair pra
            -- forragear (perseguir/apontar > forrageio). Um coelho fugindo sai do alcance do scan por um instante; isso evita
            -- que o cao se desgrude pra uma criatura de forage nessa brecha.
            if d.lastPreySeenMin and (now - d.lastPreySeenMin) < CD.HUNT_PREY_FORGET_MIN then
                if d.hunting then dropHuntTarget(animal, d) end
                d.forageSpot = nil
                return false
            end
            -- sem presa selvagem: recorre a fazer scout de um ponto de forage ("entrar no Search Mode"). Presa sempre tem prioridade.
            if d.hunting and d.hunting ~= "foraging" then dropHuntTarget(animal, d) end
            if tryForagePoint(animal, owner, d) then return true end
            if d.hunting then dropHuntTarget(animal, d) end
            return false
        end
    end
    d.lastPreySeenMin = now  -- presa em maos neste tick (scan ou alvo retido): atualiza pra o forage ceder a ela

    -- coleira de seguranca numa perseguicao em andamento.
    if owner and CD.dist2D(animal, owner) > CD.huntMaxLeash() then
        d.huntTargetId = nil; d.woundedPrey = nil
        d.huntRetryMin = now + CD.HUNT_RETRY_COOLDOWN_MIN
        dropHuntTarget(animal, d)
        return false
    end

    -- limpa qualquer lock de combate velho pra recuperacao de stress/HP (condicionada a not inCombat) nao ficar travada durante a caca.
    if d.inCombat or d.retreating then CD.setInCombat(animal, d, false); d.retreating = false end
    combatTarget[animal:getOnlineID()] = nil

    -- borda de deteccao (primeira aquisicao desta presa): late uma vez + um halo de aponto + XP com throttle. Travado em d.huntAlerted.
    if not d.huntAlerted then
        d.huntAlerted = true
        huntBark(animal, d)
        CD.notifyOwner(owner, "huntpoint", { id = animal:getOnlineID(), breed = CD.getBreed(animal) })
        if not d.lastHuntXpMin or (now - d.lastHuntXpMin) >= CD.HUNT_XP_COOLDOWN_MIN then
            d.lastHuntXpMin = now
            addHuntXP(animal, CD.HUNT_XP_PER_DETECT)
        end
    end

    local canEngage = (preyCls == "small" and huntLevel >= CD.huntSmallLevel())
        or (preyCls == "large" and huntLevel >= CD.huntLargeLevel())
    local gap = CD.dist2D(animal, prey)

    if not canEngage then
        -- so APONTAR/RASTREAR (abaixo do nivel de engaje da presa): chega perto, encara, segura um instante, depois REPORTA e volta
        -- ao owner em vez de congelar ao lado de caca que nao consegue abater. Aponta de novo depois do cooldown de desistencia.
        -- O selo e setado DENTRO de cada branch ("tracking" indo ate a presa, "sniffing" parado em cima do rastro);
        -- seta-lo aqui fora faria ele alternar tracking<->sniffing a cada pass = um transmit por pass.
        -- Histerese pra uma presa em movimento nao fazer o cao ficar trotando ate ela + refarejando: trota UMA vez ate o alcance de aponto,
        -- depois TRAVA (d.huntPointed) e SEGURA/observa parado. So reaproxima quando a presa vagou bem pra longe
        -- (> REAPPROACH_DIST); esse reposicionamento genuino tambem renova o dwell pra o cao continuar observando uma presa em movimento.
        local reapproach = d.huntPointed and gap > CD.HUNT_POINT_REAPPROACH_DIST
        if (not d.huntPointed and gap > CD.HUNT_POINT_DIST) or reapproach then
            setHuntTag(animal, d, "tracking")
            if reapproach then d.huntPointSinceMin = nil end
            d.huntPointed = nil
            d.huntPoseBeatMs = nil
            -- Re-emitir pathToLocation todo tick cancela o A* assincrono em voo (o cao "corre no lugar"), mas emitir
            -- SO quando o tile da presa muda trava o cao de vez se qualquer outro sistema cancelou o path (ele fica
            -- parado a meio caminho, nunca chega no alcance de aponto). Entao: re-emite no tile novo OU quando o cao
            -- esta ha mais de 1.2s sem sair do lugar.
            local nowMs = getTimestampMs()
            local ax, ay = animal:getX(), animal:getY()
            local stalled = false
            if not d.huntProbeMs or (nowMs - d.huntProbeMs) >= 1200 then
                stalled = d.huntProbeMs ~= nil
                    and math.abs(ax - d.huntProbeX) < 0.2 and math.abs(ay - d.huntProbeY) < 0.2
                d.huntProbeMs, d.huntProbeX, d.huntProbeY = nowMs, ax, ay
            end
            local tx, ty = math.floor(prey:getX()), math.floor(prey:getY())
            if stalled or d.huntGoalTx ~= tx or d.huntGoalTy ~= ty then
                d.huntGoalTx, d.huntGoalTy = tx, ty
                moveTo(animal, true, CD.runAnimSpeed(), tx, ty, math.floor(prey:getZ()))
            end
        else
            -- Chegou: selo proprio "farejando" (nao mais so "rastreando"). Vai no NAMETAG, nao num halo: a engine so
            -- desenha haloNote em playerIsSelf(), entao texto sobre o cao so existe pela tag do mod.
            setHuntTag(animal, d, "sniffing")
            -- XP por farejar, UMA vez por presa (latch limpo no dropHuntTarget). Fica na borda de chegada e nao no fim
            -- do dwell porque presa em movimento reseta o dwell o tempo todo -- o cao farejaria e nunca receberia nada.
            -- Sem o throttle de 3min do detect: aquele acabou de gastar, e esta borda ja e limitada por presa.
            if not d.huntSniffXp then
                d.huntSniffXp = true
                addHuntXP(animal, CD.HUNT_XP_PER_SNIFF)
            end
            d.huntPointed = true
            d.huntGoalTx, d.huntGoalTy, d.huntProbeMs = nil, nil, nil
            d.huntPointSinceMin = d.huntPointSinceMin or now
            if (now - d.huntPointSinceMin) > CD.HUNT_POINT_DWELL_MIN then
                d.huntPointSinceMin = nil
                d.huntPointed = nil
                d.huntPoseBeatMs = nil
                pcall(function() emitEatVar(animal, false, CD.SNIFF_ANIM_VAR) end)
                d.huntRetryMin = now + CD.HUNT_RETRY_COOLDOWN_MIN
                dropHuntTarget(animal, d)
                return false
            end
            pcall(function()
                animal:setVariable("animalRunning", false)
                animal:setVariable("animalSpeed", 0)
                animal:faceThisObject(prey)
                animal:stopAllMovementNow()
            end)
            holdStill(animal)
            -- pose de faro agachada (Rac_Sniff); sobrevive ao standUp do call-site, diferente da var de descanso deitado.
            -- Re-pulsa num beat de tempo-real ja que cada pulso limpa sozinho em ~3s.
            local nowMs = getTimestampMs()
            if not d.huntPoseBeatMs or (nowMs - d.huntPoseBeatMs) >= 2500 then
                d.huntPoseBeatMs = nowMs
                pcall(function() CD.pulseSniffAnim(animal) end)
            end
        end
        return true
    end

    -- ENGAJAR: persegue, depois golpeia quando no alcance.
    if gap > CD.HUNT_STRIKE_DIST then
        setHuntTag(animal, d, "chasing")
        d.huntGoingSinceMin = d.huntGoingSinceMin or now
        if (now - d.huntGoingSinceMin) > CD.HUNT_GOING_TIMEOUT_MIN then
            -- nao consegue pegar: desiste desta presa + esfria pra o cao voltar ao owner.
            d.woundedPrey = nil
            d.huntRetryMin = now + CD.HUNT_RETRY_COOLDOWN_MIN
            dropHuntTarget(animal, d)
            return false
        end
        letMove(animal)
        pcall(function()
            animal:setVariable("animalSpeed", CD.runAnimSpeed())
            animal:setVariable("animalRunning", true)
            animal:faceThisObject(prey)
            animal:pathToCharacter(prey)
        end)
        forcePathfind(animal)
        return true
    end
    -- no alcance de golpe: o cao esta EM CIMA da presa. Caca grande = encurralou/segura o cervo (selo "holding" enquanto o
    -- desgasta E enquanto o segura no chao); caca pequena e abatida instantaneamente, entao o selo mal aparece.
    setHuntTag(animal, d, preyCls == "large" and "holding" or "chasing")
    d.huntGoingSinceMin = nil
    if preyCls == "large" then
        -- PRENDE o cervo pra ele realmente FICAR seguro em vez de sair andando (limpa o gatilho de fuga + suprime novos
        -- caminhos de fuga via blockMovement + cancela o movimento atual + encara o cao). Liberado em dropHuntTarget.
        pcall(function()
            prey:setAttackedBy(nil)
            prey:stopAllMovementNow()
            prey:setVariable("animalRunning", false)
            prey:setVariable("animalSpeed", 0)
            local pb = prey:getBehavior()
            if pb and pb.setBlockMovement then pb:setBlockMovement(true) end
            prey:faceThisObject(animal)
        end)
    end
    pcall(function()
        animal:setVariable("animalRunning", false)
        animal:setVariable("animalSpeed", 0)
        animal:faceThisObject(prey)
        animal:stopAllMovementNow()
    end)
    holdStill(animal)
    huntStrike(animal, owner, prey, d, preyCls, huntLevel)
    return true
end
-- ===== fim da caca assistida ==============================================================================

local function updateCompanion(animal, owner)
    local d = CD.data(animal)

    -- No meio do salto: pula esta passada pesada inteira (combat/sentinel/hunt/auto-feed/state/re-path iriam todos atropelar a
    -- travessia nativa de climbfence que tickFenceHops esta conduzindo). Mantem o cao no follow maintainer leve
    -- (followOwner cede em d.fenceHop) e invencivel; a passada pesada retoma assim que ele pousa (<1s).
    if d.fenceHop then
        -- No meio de um pulo de COMBATE (vault de cerca baixa), mantem o cao no combat maintainer pra que ao pousar ele
        -- retome perseguicao/golpe; um pulo de FOLLOW (combatMaintainDogs nao setado) segue indo pro follow maintainer.
        local hid = animal:getOnlineID()
        if combatMaintainDogs[hid] then combatMaintainDogs[hid] = animal
        else followMaintainDogs[hid] = animal end
        pcall(function() animal:setIsInvincible(true) end)
        return
    end

    -- Solta os registros do follow/combat maintainer por-tick; o bloco de combate re-adiciona combatMaintainDogs so se
    -- esta passada terminar engajando/recuando, e followOwner re-adiciona followMaintainDogs so se terminar em follow puro.
    -- Qualquer outro desfecho (guard/stay/hunt/auto-feed/disloyal/panic/wounded/mounted) deixa ambos limpos, entao nenhum
    -- maintainer continua dirigindo um cao que a passada pesada entregou a outro comportamento. Os dois sao mutuamente exclusivos por passada.
    followMaintainDogs[animal:getOnlineID()] = nil
    combatMaintainDogs[animal:getOnlineID()] = nil

    pcall(function() animal:setShootable(false) end)

    -- Skills sumidas num companion vivo (copyFrom parcial / serializacao perdeu a sub-tabela): reidrata do canil
    -- durável em vez de zerar em silencio (marca d'agua, nunca regride); initSkills fecha o caso sem snapshot.
    if not d.skills then
        CD.restoreFromKennel(owner, animal)
        CD.initSkills(animal)
    end

    if CD.upkeepEnabled() then updateUpkeep(animal, owner, d) end

    -- Espelha o snapshot durável do cao ativo periodicamente (captura o XP parcial ganho lutando/farejando).
    if not d.lastKennelMin or (worldMinutes() - d.lastKennelMin) >= (CD.KENNEL_MIRROR_MIN or 30) then
        d.lastKennelMin = worldMinutes()
        CD.kennelSnapshot(owner, animal)
    end

    -- Imunidade permanente a roadkill: um companion e SEMPRE invencivel (reafirmado aqui e por tickCompanionInvincible
    -- pra caes fora do alcance deste owner-loop). As needs/permadeath que isso congelaria sao dirigidas a mao
    -- em updateUpkeep acima. Veja CompanionDogs_Config.lua pra o porque.
    local mounted = CD.isMounted(owner)
    local id = animal:getOnlineID()
    pcall(function() animal:setIsInvincible(true) end)

    -- Indo cruzar: a aproximacao (tickBreedingApproach) conduz este cao ate o macho; pula follow/combat/sentinel/hunt
    -- desta passada pra nao brigar com o path. Upkeep ja rodou acima; os registros de maintainer ja foram limpos.
    if d.breedTarget then return end

    -- Reaplica o visual da saddlebag depois de um save/reload: a engine NAO persiste os attached items de um IsoAnimal
    -- (IsoAnimal.save/load serializam ModData mas nao attachedItems), entao a mesh some no load mesmo que os registros
    -- da bag sobrevivam. Os sites de copyFrom reaplicam; isto cobre o load simples de chunk/save. O nil-check de getAttachedItem
    -- faz disparar uma vez por load (depois do qual o attach fica non-nil pela sessao), nao a cada tick.
    if CD.hasBag(animal) then
        local missing = false
        pcall(function() missing = animal:getAttachedItem("saddlebags_l") == nil end)
        if missing then pcall(function() CD.applyBagVisual(animal) end) end
    end

    -- Teleport-follow: preenche um uid estavel por-cao (lazy; persiste via o proprio ModData do cao, sem transmit) e
    -- mantem um snapshot de recovery vivo do cao ATIVO pra um teleport distante que o descarregue poder respawna-lo no owner
    -- (bringActiveOnTeleport) e depois deduplicar o gemeo abandonado por uid. Pulado enquanto mounted (esse caminho dono do cao).
    if not mounted then
        if not d.uid then
            d.uid = tostring(getTimestampMs()) .. "-" .. tostring(ZombRand(0, 2147483647))
        end
        pcall(function()
            activeDogSnapshot[owner:getOnlineID()] = {
                type = animal:getAnimalType(),
                female = animal:isFemale() == true,
                age = animal:getAge(),
                hp = animal:getHealth(),
                hunger = animal:getHunger(),
                thirst = animal:getThirst(),
                -- por VALOR (atualizado a cada tick em que este cao esta carregado): guarda o ultimo estado conhecido pro respawn,
                -- e da ao respawn uma tabela ModData independente pra o carimbo de gen nunca virar alias do original.
                data = cdDeepCopy(d),
            }
        end)
    end

    -- Guarda de fogo amigo: com adef.attackBack=false (pra caes SELVAGENS fugirem ao apanhar), um golpe acidental do owner ainda
    -- roda hitConsequences->setAttackedBy(owner) no companion, o que armaria fleeFromAttacker (fugir do owner).
    -- O cao e invencivel (sem dano), entao so limpa attackedBy a cada tick. Ele nunca foge NEM luta contra o owner.
    pcall(function() animal:setAttackedBy(nil) end)

    -- So um cao em FOLLOW vem junto quando o owner sai dirigindo. Um cao mandado ficar em Stay ou Guard e deixado
    -- onde esta, entao o owner pode deixa-lo pra tras so comandando "Stay" antes de entrar no vehicle.
    if mounted and CD.getState(animal) == CD.STATE_FOLLOW then
        -- Para a refeicao antes de o cao ser stashed/delete()d: so setAutoFeedTag para o foley de comer em loop.
        if d.autoFeeding then setAutoFeedTag(animal, d, nil) end
        CD.setInCombat(animal, d, false)
        d.retreating = false
        d.alertTier = nil
        if not d.mounted then d.mounted = true; CD.transmit(animal) end
        mountedDogs[animal:getOnlineID()] = animal
        -- Escreve o registro de recovery AGORA, na BORDA de mount. O delete em si fica adiado pra tickMountedDogs (abaixo),
        -- mas pd.stash precisa existir ANTES de o player poder agir: entrar num Project RV Interior (vehicle:exit + teleport distante)
        -- na brecha de >=1 tick antes de tickMountedDogs escrever pd.stash deixava o cao SEM registro de recovery -> mountClear
        -- batia num square de interior nil (streaming do coop) e recoverStashedDogs nao tinha nada pra reter, entao o cao era
        -- abandonado (o intermitente "as vezes nao segue pra dentro do RV"). Com pd.stash garantido aqui, todo
        -- timing de entrada colapsa no caminho confiavel de recoverStashedDogs. Idempotente (stashMounted o sobrescreve um
        -- tick depois); seguro (recoverStashedDogs faz early-return enquanto o owner ainda esta mounted, entao nao pode agir cedo demais).
        if owner and not CD.playerData(owner).stash then CD.writeStashRecord(animal, owner) end
        -- O stash em si (delete) e o respawn ao desmontar sao ambos dirigidos por tickMountedDogs, que
        -- itera nossa propria tabela; faze-lo aqui mutaria o mundo no meio do loop de processNearbyDogs
        -- (que esta iterando a lista de animais de um square) e corromperia essa iteracao.
        return
    end

    updatePanicNotify(animal, owner, d)

    -- A alimentacao self-service tem prioridade sobre a logica de combate/panico/follow abaixo e, uma vez comprometida, IGNORA
    -- zumbis e toda outra distracao: so um comando do owner (ou estar num vehicle / um bowl inalcancavel) a interrompe
    -- (tudo tratado dentro). Um cao com fome/sede pode quebrar seu proprio panico movido por needs num bowl abastecido, e um
    -- cao disloyal ainda consegue comer.
    if tryAutoFeed(animal, owner, d) then standUp(animal); return end

    if CD.isDisloyal(animal) then
        d.alertTier = nil
        CD.setInCombat(animal, d, false)
        standUp(animal)
        warnRefusalInCombat(animal, owner, d)
        return
    end

    if CD.getStress(animal) >= CD.breedPanicThreshold(animal) then
        d.alertTier = nil
        CD.setInCombat(animal, d, false)
        d.retreating = false
        d.standDown = true
        warnRefusalInCombat(animal, owner, d)
        standUp(animal)
        if CD.getState(animal) ~= CD.STATE_STAY then followOwner(animal, owner) else holdStill(animal) end
        return
    end

    if CD.isWoundedCritical(animal) then
        d.alertTier = nil
        CD.setInCombat(animal, d, false)
        d.retreating = false
        warnRefusalInCombat(animal, owner, d)
        standUp(animal)
        if CD.getState(animal) ~= CD.STATE_STAY then followOwner(animal, owner) else holdStill(animal) end
        return
    end

    local state = CD.getState(animal)
    local realGuard = state == CD.STATE_GUARD

    -- Auto-protect: enquanto o owner esta no meio de uma acao vulneravel (o client manda heartbeats de d.protectUntilMin) e o toggle
    -- por-cao esta ligado, o cao vira um guarda temporario ancorado no owner, independente do seu estado salvo. A
    -- ancora e capturada uma vez na borda de ativacao (o ponto do owner quando a acao comecou) e limpa quando a
    -- janela expira, entao o cao reverte pra Follow/Stay sozinho sem nunca tocar em d.state. Herda os
    -- gates de disloyal/panic/wounded-critical acima (eles retornam primeiro), exatamente como um Guard manual.
    -- Um Guard REAL nunca cede a ancora pro protect (captura gateada; o posto vence tambem no move-tail).
    local protecting = CD.autoProtectEnabled() and CD.getAutoProtect(animal)
        and d.protectUntilMin and worldMinutes() < d.protectUntilMin
    -- Dono em MOVIMENTO nao prende o cao na ancora de protect (hardening do estudo S9, cobre janela orfa de
    -- OFF perdido): a ancora ACOMPANHA o dono andando e congela quando ele para; o move-tail decide por ownerStill.
    local ownerStill = false
    if protecting then
        pcall(function()
            local oid = owner:getOnlineID()
            local ox, oy = owner:getX(), owner:getY()
            local nowMs = getTimestampMs()
            local oms = ownerMoveState[oid]
            if oms and (math.abs(ox - oms.x) + math.abs(oy - oms.y)) < (CD.OWNER_STILL_EPS or 0.1) then
                ownerStill = (nowMs - oms.sinceMs) >= (CD.OWNER_STILL_MS or 450)
            else
                ownerMoveState[oid] = { x = ox, y = oy, sinceMs = nowMs }
            end
        end)
    end
    if protecting and not realGuard then
        if not d.protectX or not ownerStill then
            d.protectX, d.protectY, d.protectZ = owner:getX(), owner:getY(), owner:getZ()
        end
    elseif d.protectX then
        d.protectX, d.protectY, d.protectZ = nil, nil, nil
    end

    local inRecall = d.recallUntilMin and worldMinutes() < d.recallUntilMin
    if CD.sentinelEnabled() and not inRecall then
        updateSentinel(animal, owner, d)
    else
        if d.alertTier ~= nil then d.alertTier = nil; CD.transmit(animal) end
    end

    if state == CD.STATE_STAY and not protecting then
        -- Caca autonoma (sandbox, desligada por padrao): um cao de nivel alto caca mesmo parado em Stay.
        if CD.huntEnabled() and CD.huntAutonomyEnabled() and CD.getHuntMode(animal)
            and CD.getSkillLevel(animal, "hunt") >= CD.huntAutonomyLevel()
            and tryHunt(animal, owner, d) then standUp(animal); return end
        holdStill(animal); updateRest(animal, d); return
    end
    -- protecting age como um Guard temporario pra logica de combate/engaje abaixo (GUARD_RADIUS + sempre engajar,
    -- ignora standDown, contorna o curto-circuito de recall pra poder lutar). realGuard mantem o Guard de estado salvo
    -- separado pra o passo de move final voltar a ancora correta.
    local guarding = realGuard or protecting

    if not guarding and d.recallUntilMin and worldMinutes() < d.recallUntilMin then
        CD.setInCombat(animal, d, false)
        d.retreating = false
        followOwner(animal, owner)
        return
    end

    if CD.combatEnabled() then
        local engageRadius = guarding and CD.GUARD_RADIUS or CD.ZOMBIE_ATTACK_RADIUS
        -- Um guard de verdade ranqueia/filtra por andar em torno da sua ancora (o cao); follow/auto-protect em torno do owner.
        local engageRef = realGuard and animal or owner
        local nearest, count, threatensUs = scanZombies(animal, engageRadius, owner, engageRef, not guarding)
        local commanded = d.attackUntilMin and worldMinutes() < d.attackUntilMin
        local autoProtectOn = CD.autoProtectEnabled() and CD.getAutoProtect(animal)
        local ownerFighting = playerFighting(owner)
        -- Auto-protecao e uma ordem de defesa explicita do dono e VENCE o standDown (mandar seguir/vir nao desliga a
        -- defesa que o dono ligou): reage a zumbi que mira o dono/cao (threatensUs) e ajuda enquanto o dono luta.
        -- So a iniciativa global (combatInitiative) continua suprimida por standDown.
        local defend = autoProtectOn and (threatensUs or ownerFighting)

        local engageZ = combatTarget[id]
        if engageZ and d.standDown and not guarding and not defend then
            combatTarget[id] = nil
            engageZ = nil
        end
        if engageZ then
            -- Solta o lock se o alvo morreu, despawnou (sem square -> ref velha de "zumbi invisivel" no co-op), saiu da coleira, ou nao pode ser resolvido.
            -- Guard real: coleira medida do POSTO (d.guardX), nao do cao (raio ambulante encadeava alvos mapa afora).
            local invalid = true
            pcall(function()
                if realGuard and not commanded then
                    local gx, gy = d.guardX or animal:getX(), d.guardY or animal:getY()
                    local zx, zy = engageZ:getX(), engageZ:getY()
                    invalid = engageZ:isDead() or engageZ:getSquare() == nil
                        or ((zx - gx) * (zx - gx) + (zy - gy) * (zy - gy)) > (CD.GUARD_RADIUS * CD.GUARD_RADIUS)
                elseif commanded then
                    invalid = engageZ:isDead() or engageZ:getSquare() == nil
                        or CD.dist2D(animal, engageZ) > CD.ATTACK_COMMAND_RADIUS
                elseif guarding then
                    -- auto-protect (guarda temporario): coleira medida do cao, raio de guarda, como antes
                    invalid = engageZ:isDead() or engageZ:getSquare() == nil
                        or CD.dist2D(animal, engageZ) > engageRadius
                else
                    -- follow puro: coleira amarrada ao DONO (o dono se afastando derruba o alvo = cura o "nao volta")
                    invalid = engageZ:isDead() or engageZ:getSquare() == nil
                        or CD.dist2D(owner, engageZ) > CD.FOLLOW_DEFEND_DROP
                end
            end)
            if invalid then
                combatTarget[id] = nil
                engageZ = nil
                d.cstall = nil
                if commanded then clearAttack(animal, d) end
            end
        end

        if not engageZ then
            if commanded and d.attackArmed then
                d.attackArmed = nil
                -- Comando "atacar mais proximo" e do CAO: ref = animal (ranqueia por dDog, janela centrada nele).
                engageZ = scanZombies(animal, CD.ATTACK_COMMAND_RADIUS, owner, animal, false)
                if not engageZ then
                    clearAttack(animal, d)
                    -- Fallback honesto (item 7): obedeceu, mas nada alcancavel no raio; o halo explica o "nao foi".
                    CD.notifyOwner(owner, "notarget", { name = d.name, breed = CD.getBreed(animal) })
                end
            elseif not commanded and nearest
                and (guarding or defend or (not d.standDown and (CD.combatInitiative() or ownerFighting))) then
                -- Aquisicao do Guard real tambem amarrada ao posto: zumbi fora do raio do posto nao inicia engajamento.
                if realGuard then
                    local inPost = false
                    pcall(function()
                        local gx, gy = d.guardX or animal:getX(), d.guardY or animal:getY()
                        local zx, zy = nearest:getX(), nearest:getY()
                        inPost = ((zx - gx) * (zx - gx) + (zy - gy) * (zy - gy)) <= (CD.GUARD_RADIUS * CD.GUARD_RADIUS)
                    end)
                    if inPost then engageZ = nearest end
                elseif guarding then
                    -- auto-protect (guarda temporario ancorado no dono): engaja no raio de guarda, como antes
                    engageZ = nearest
                else
                    -- follow puro: engaja autonomo SO perto do DONO (bolha de defesa), nao 8 tiles ao redor do cao
                    local near = true
                    pcall(function() near = CD.dist2D(owner, nearest) <= CD.FOLLOW_DEFEND_RADIUS end)
                    if near then engageZ = nearest end
                end
            end
            if engageZ then
                combatTarget[id] = engageZ; d.cstall = nil
            end
        end

        if engageZ then
            standUp(animal)
            d.combatFollowVault = not guarding   -- so combate em follow-mode pula cerca baixa; guard/protect ficam ancorados (A*-only)
            if not d.inCombat then CD.setInCombat(animal, d, true); bark(animal) end

            local base = d.maxHealth or animal:getHealth()
            -- Recuo SO por vida baixa (teto por quantidade de zumbis REMOVIDO por decisao de design: o cao enfrenta
            -- a horda; quem o limita e o dano que toma). O dwell segura o recuo pra nao flapar na borda da condicao.
            local lowHealth = animal:getHealth() <= CD.retreatHealthFrac() * base
            local dwellOver = not d.retreatUntilMin or worldMinutes() >= d.retreatUntilMin
            local retreatNow = lowHealth or (d.retreating and not dwellOver)
            if retreatNow then
                if commanded then clearAttack(animal, d) end
                combatTarget[id] = nil
                d.cstall = nil
                if not d.retreating then
                    d.retreating = true; bark(animal)
                    d.retreatUntilMin = worldMinutes() + (CD.RETREAT_MIN_DURATION_MIN or 0.5)
                end
                d.combatMode = "retreat"
                combatMaintainDogs[id] = animal
                retreat(animal, owner, engageZ)
                return
            end
            d.retreating = false

            local gap = CD.dist2D(animal, engageZ)
            -- Nunca morde atravessando uma parede/porta fechada: um zumbi colado do outro lado fica dentro de STRIKE_DIST
            -- (~1 tile atravessando a parede), entao sem isto ele acertaria golpes atraves da parede. Se bloqueado, re-path
            -- em vez de golpear (o A* da engine vai pra um tile aberto; se nao houver, o cao so segura, sem dano).
            local blocked = pathBlocked(animal, engageZ)
            pcall(function()
                animal:setAttackedBy(nil)
                animal:setDebugStress(0)
                animal:faceThisObject(engageZ)
            end)
            -- Pulo de cerca BAIXA em combate (SP, so follow-mode): zumbi atras de uma picket -> conduz ate a cerca e SALTA
            -- em vez de tentar contornar (o glide roda no tickFenceHops). Segura o resto do combate desta passada.
            if not guarding and CD.tryCombatVault(animal, engageZ, d, getTimestampMs()) then
                d.combatMode = "approach"
                combatMaintainDogs[id] = animal
                return
            end
            -- Backstop de inalcancabilidade (combat-plan item 6): a regiao aprovou (ou nao pode provar nada) mas o
            -- A* nao chega: cao PARADO, sem ganho de gap (Failed persistente acelera) -> dropa o lock + cooldown
            -- curto no zumbi (o scan pula) em vez de re-pathear pra sempre encarando o obstaculo. Debounce por
            -- posicao: detour legitimo (contornando parede) mantem o cao em movimento e NUNCA dispara.
            if gap > CD.STRIKE_DIST or blocked then
                local nowMs = getTimestampMs()
                local st = d.cstall
                if not st then st = { bg = gap, ax = animal:getX(), ay = animal:getY(), sfw = 0 }; d.cstall = st end
                -- Deslocamento LIQUIDO desde o ancora de progresso (nao o movimento por-tick: andar ao longo de uma
                -- cerca conta como movimento mas nao e progresso). Desvio real re-ancora; orbita fica presa no raio.
                local net = math.abs(animal:getX() - st.ax) + math.abs(animal:getY() - st.ay)
                local gained = gap + 0.2 < st.bg
                if gained then st.bg = gap end
                if gained or net > (CD.COMBAT_STALL_RADIUS or 2.5) then
                    st.ax, st.ay = animal:getX(), animal:getY()
                    st.ms = nil
                    st.sfw = 0
                else
                    st.ms = st.ms or nowMs
                    local sfw = false
                    pcall(function() sfw = animal:shouldFollowWall() == true end)
                    st.sfw = sfw and (st.sfw + 1) or 0
                end
                if st.sfw >= 2 or (st.ms and (nowMs - st.ms) > (CD.COMBAT_STALL_MS or 2500)) then
                    local unr = CD.combatUnreach[id]
                    if not unr then unr = {}; CD.combatUnreach[id] = unr end
                    unr[engageZ] = nowMs + (CD.COMBAT_UNREACH_MS or 12000)
                    combatTarget[id] = nil
                    d.cstall = nil
                    d.combatMode = nil
                    combatMaintainDogs[id] = nil
                    CD.setInCombat(animal, d, false)
                    if commanded then
                        clearAttack(animal, d)
                        CD.notifyOwner(owner, "notarget", { name = d.name, breed = CD.getBreed(animal) })
                    end
                    engageZ = nil   -- cai pro move-tail desta passada (posto/follow), sem return
                end
            else
                d.cstall = nil
            end
            if engageZ then
                if gap > CD.STRIKE_DIST or blocked then
                    pcall(function()
                        animal:setVariable("animalSpeed", CD.runAnimSpeed())
                        -- Sempre dispara pra fechar distancia num hostil: animalRunning seleciona o clip de RUN (magnitude
                        -- de root-motion ~2x do WALK = velocidade real de deslocamento), entao a heuristica de andar-quando-perto
                        -- gap>FOLLOW_RUN_DIST (certa pra seguir o owner) deixava um zumbi kitado superar a aproximacao
                        -- final do cao. Corre ate STRIKE_DIST pra ele de fato alcancar um alvo em movimento.
                        animal:setVariable("animalRunning", true)
                        letMove(animal)
                        animal:pathToCharacter(engageZ)
                        forcePathfind(animal)
                    end)
                else
                    pcall(function()
                        animal:setVariable("animalRunning", false)
                        animal:setVariable("animalSpeed", 0)
                        animal:stopAllMovementNow()
                    end)
                    -- Plantado no alvo pra golpear: bloqueia o wander da engine pra ele nao se afastar do zumbi
                    -- entre golpes (reaproxima sozinho no proximo tick se o zumbi sair de STRIKE_DIST).
                    holdStill(animal)
                    strikeExchange(animal, engageZ, count)
                end
                -- Registra o combat maintainer por-tick pra a APROXIMACAO/plant ficar suave entre as passadas de 20 ticks
                -- (ele re-dirige rumo ao combatTarget vivo e planta no alcance de golpe; o golpe em si fica aqui).
                d.combatMode = "approach"
                combatMaintainDogs[id] = animal
                return
            end
        end
        combatTarget[id] = nil
        CD.setInCombat(animal, d, false)
        d.retreating = false
        d.cstall = nil
    end

    -- Caca assistida: em Follow sem zumbi engajado acima, o cao rastreia/persegue caca selvagem no modo Hunt.
    -- Roda depois do combate (um zumbi sempre tem precedencia sobre presa) e depois dos gates de recall/guard.
    if not guarding and state == CD.STATE_FOLLOW then
        if tryHunt(animal, owner, d) then standUp(animal); return end
    end

    -- Guard REAL vence o protect: um cao com posto salvo defende o POSTO, nunca vira guarda movel do dono.
    if realGuard then
        returnToAnchor(animal, d)
    elseif protecting then
        if ownerStill then
            returnToAnchor(animal, d, d.protectX, d.protectY, d.protectZ)
        elseif state == CD.STATE_STAY then
            -- Stay + protect + dono andando: nao vira follow (Stay manda); guarda de novo quando ele parar.
            holdStill(animal)
        else
            followOwner(animal, owner)
        end
    else
        followOwner(animal, owner)
    end
end

local function maybeUpdate(animal, player)
    local d = CD.data(animal)
    local pd = CD.playerData(player)
    if pd.token == nil then
        -- Multi-dog: a ativacao e EXPLICITA (tame ou o comando "select"), NUNCA por presenca. So um companion
        -- legado SEM token (save pre-token) e adotado uma vez aqui, pra migra-lo. Um cao com token cujo
        -- owner nao tem selecao ativa (ex.: o ativo morreu) fica PASSIVO ate o player o selecionar.
        if d.companionToken ~= nil then return end
        pd.seq = (pd.seq or 0) + 1
        pd.token = pd.seq
        pd.name = d.name
        d.companionToken = pd.seq
        CD.transmit(animal)
    elseif d.companionToken ~= pd.token then
        -- Nao e o companion ativo deste player: pula o controle neste tick. NUNCA setWild aqui.
        -- O antigo CD.demote() tornava caes de token velho selvagens; com a rotatividade de onlineID entre
        -- restarts de server o id reusado de um player batia com o token do cao ERRADO e o cao saia vagando
        -- como animal selvagem (= o bug "caes sumiram"). O cao ativo e escolhido explicitamente (tame/select).
        return
    end
    updateCompanion(animal, player)
end

local function processNearbyDogs(player)
    local px = math.floor(player:getX())
    local py = math.floor(player:getY())
    local pz = math.floor(player:getZ())
    local cell = getCell()
    if not cell then return end
    local R = CD.TELEPORT_DIST + 4
    -- Coleta primeiro (nunca muta o mundo enquanto itera a lista de animais de um square).
    local pd = CD.playerData(player)
    local present, matchesToken, deadDogs = nil, false, nil
    for dx = -R, R do
        for dy = -R, R do
            local sq = cell:getGridSquare(px + dx, py + dy, pz)
            if sq then
                local list = sq:getAnimals()
                if list then
                    for i = 0, list:size() - 1 do
                        local a = list:get(i)
                        if CD.isDog(a) and CD.isCompanion(a) and CD.isOwnedBy(a, player) then
                            local deadDog = false
                            pcall(function() deadDog = a:isDead() or a:getHealth() <= 0 end)
                            if deadDog then
                                -- Um companion proprio na lista MORTO (uma morte da engine: um roadkill na breve
                                -- janela de respawn pre-invencivel, ou um save pre-fix, que nunca passou pela
                                -- permadeath) e coletado pra cleanup abaixo; NAO pode contar como cao vivo presente.
                                deadDogs = deadDogs or {}
                                deadDogs[#deadDogs + 1] = a
                            else
                                present = present or {}
                                present[#present + 1] = a
                                if CD.data(a).companionToken == pd.token then matchesToken = true end
                                -- Reconciliador anti-fantasma: um companion pode sair da objectList da cell e nunca voltar
                                -- (ex.: crash entre o remove do ghost.onFire e o re-add) -> congela, some de getAnimals() e
                                -- nenhum tick do mod o alcanca mais. O scan daqui e por SQUARE (getMovingObjects, lista
                                -- independente), entao ele segue visivel AQUI: re-insere na objectList qualquer companion
                                -- ausente, curando fantasmas de qualquer origem (incl. saves ja afetados) em <=1 tick pesado.
                                pcall(function()
                                    local ol = cell:getObjectList()
                                    if not ol:contains(a) then
                                        ol:add(a)
                                    end
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
    -- Um companion achado MORTO na lista (uma morte da engine que contornou a permadeath) -> roda a contabilidade de morte
    -- aqui pra liberar a pata do world-map e o slot de MaxCompanions; a engine transforma o corpo num corpse, nos
    -- nao o matamos de novo. Defesa em profundidade: com o respawn agora invencivel isto deve ser raro.
    if deadDogs then
        pd.uidGen = pd.uidGen or {}
        for _, a in ipairs(deadDogs) do
            local da = CD.data(a)
            local u = da.uid
            if u ~= nil and (da.gen or 0) < (pd.uidGen[u] or 0) then
                -- Gemeo de teleport velho: o original abandonado num teleport distante/de RV-interior compartilha o uid
                -- E o companionToken do respawn canonico (o snapshot e um deepCopy) mas mantem um gen MAIS VELHO. Ele deve ser
                -- deletado SILENCIOSAMENTE pelo gen-reaper (a:delete(), sem corpse/notify). Se carregar MORTO (sua propria breve
                -- janela de roadkill nao-invencivel pos-reload) NAO pode passar por clearCompanionSlot: isso anularia
                -- pd.token + liberaria o slot pro cao canonico VIVO ao lado do owner. Reapa como o gen-reaper.
                reapDogState(a:getOnlineID())
                pcall(function() a:delete() end)
            elseif not da.diedNotified then
                da.diedNotified = true
                clearCompanionSlot(player, da.companionToken, da.name, CD.getBreed(a), a)
                reapDogState(a:getOnlineID())
            end
        end
    end

    -- Follow entre andares: o scan acima e travado em z no andar do owner (pz), entao quando o owner sobe
    -- escadas o companion deixado um andar abaixo fica invisivel pra este loop e nunca e mandado seguir. Acha o
    -- companion carregado em toda a cell e, se estiver num andar DIFERENTE, processa ele tambem pra followOwner poder path-a-lo
    -- escada acima. Apenas suplemento: a reconciliacao de token/orfao abaixo continua chaveada no conjunto
    -- `present` do mesmo andar (um cao de outro andar nao pode contar como evidencia de orfao).
    -- So paga o lookup em toda a cell quando o player TEM um companion ativo (pd.token) que NAO foi achado no
    -- seu andar neste tick. Follow no mesmo andar (matchesToken) e players sem companion nunca o disparam.
    local crossFloor = nil
    if pd.token ~= nil and not matchesToken then
        local c = CD.getCompanionAnimal(player)
        if c and math.floor(c:getZ()) ~= pz then crossFloor = c end
    end

    if not present and not crossFloor then
        return
    end
    -- Multi-dog: NAO reconcilia o token ativo a partir de presenca. Um cao proprio carregado que nao
    -- bate com pd.token e so um companion PASSIVO (outro cao do player); ele fica passivo e e
    -- fixado por tickCompanionInvincible ate o player o selecionar explicitamente. (Este bloco antes limpava
    -- pd.token pra maybeUpdate adotar o cao presente, o que trocava o cao ativo por mera proximidade
    -- (exatamente o comportamento nao-deterministico que a feature de select explicito substitui).)
    if present then
        -- Auto-cura o conjunto de limite de companions (MaxCompanions): registra qualquer cao proprio carregado cujo token ainda nao
        -- esta rastreado (cobre saves multi-dog legados/emergentes feitos antes do conjunto existir). Idempotente;
        -- transmite so quando ele de fato cresce, entao isto e no-op no estado estavel.
        local grew = false
        -- Reaping de clones de teleport. Um teleport-bring (bringActiveOnTeleport) carimba o cao que traz com a
        -- geracao atual por-uid (pd.uidGen, ModData do owner) via bumpCanonical. A instancia deixada pra tras num teleport
        -- distante (ex.: o original abandonado no mundo quando o owner entra numa cell de Project RV Interior em
        -- x>=22560, que NUNCA pode co-carregar com o respawn) mantem um gen MAIS VELHO e e deletada no momento em que seu
        -- chunk carrega perto do owner (sem precisar de co-load). Pra clones de mesmo gen que DE FATO co-carregam (ex.: saves legados
        -- de antes do gen existir), mantem o de maior gen / pd.token-ativo / primeiro e deleta o resto. uid e
        -- por-cao, entao caes bonded genuinamente diferentes (uids distintos) nunca sao tocados. Isto tambem drena rebanhos
        -- de clones pre-existentes: uma vez que o cao ativo e trazido, os restantes ficam atras do gen dele e reapam ao serem vistos.
        pd.uidGen = pd.uidGen or {}
        local keeperByUid = {}
        for _, a in ipairs(present) do
            local u = CD.data(a).uid
            if u ~= nil then
                local g = CD.data(a).gen or 0
                local k = keeperByUid[u]
                local kg = k and (CD.data(k).gen or 0) or -1
                if g > kg
                   or (g == kg and CD.data(a).companionToken == pd.token and CD.data(k).companionToken ~= pd.token) then
                    keeperByUid[u] = a
                end
            end
        end
        local survivors = {}
        for _, a in ipairs(present) do
            local u = CD.data(a).uid
            local stale = u ~= nil and (keeperByUid[u] ~= a or (CD.data(a).gen or 0) < (pd.uidGen[u] or 0))
            if stale then
                local vt = CD.data(a).companionToken
                -- So limpa o slot de token orfao SO do clone (legado re-mintado): clone e canonico sao o mesmo
                -- cao e na regra compartilham o token; limpar orfanaria o sobrevivente (ver CD.cloneSlotShouldClear).
                local k = keeperByUid[u]
                local ktok = (k ~= nil and k ~= a) and CD.data(k).companionToken or nil
                if CD.cloneSlotShouldClear and CD.cloneSlotShouldClear(pd, vt, ktok) and pd.companions ~= nil then pd.companions[vt] = nil end
                reapDogState(a:getOnlineID())
                pcall(function() a:delete() end)
                grew = true
            else
                survivors[#survivors + 1] = a
            end
        end
        present = survivors
        local seenToken = {}
        for _, a in ipairs(present) do
            local da = CD.data(a)
            local t = da.companionToken
            -- Reparo de colisao: se dois caes carregados do owner compartilham um companionToken (pode acontecer quando
            -- pd.seq foi resetado pela morte do personagem enquanto caes antigos mantiveram seus tokens), AMBOS leem como o
            -- companion ativo e nenhum oferece "Select". Cunha um token unico novo pro duplicado pra exatamente
            -- um cao bater com pd.token. O primeiro cao visto fica com o token; duplicados posteriores sao re-cunhados.
            if t ~= nil and seenToken[t] then
                local m = pd.seq or 0
                if type(pd.companions) == "table" then for k in pairs(pd.companions) do if k > m then m = k end end end
                m = m + 1
                pd.seq = m
                da.companionToken = m
                t = m
                CD.transmit(a)
                grew = true
            end
            if t ~= nil then
                seenToken[t] = true
                if type(pd.companions) ~= "table" then pd.companions = {} end
                if not pd.companions[t] then pd.companions[t] = true; grew = true end
                -- Ultima posicao conhecida por token, server-authoritative. O pd.dogPositions do marcador de mapa e
                -- escrito pelo client (ausente no server em MP), entao reapPhantomCompanions mantem o proprio anchor aqui pra
                -- distinguir um cao morto (owner em cima do anchor, nada carrega) de um apenas parado longe.
                -- ModData so de server (sem transmit); persiste com o save.
                pd.tokenAnchor = pd.tokenAnchor or {}
                pd.tokenAnchor[t] = { x = math.floor(a:getX()), y = math.floor(a:getY()), z = math.floor(a:getZ()) }
            end
            -- Re-aplica o visual da saddlebag apos um reload tambem pros caes PASSIVOS com bag (updateCompanion so roda pro
            -- ativo). Mesmo nil-check uma-vez-por-load do updateCompanion; a engine derruba os itens anexados no load.
            if CD.hasBag(a) then
                local missing = false
                pcall(function() missing = a:getAttachedItem("saddlebags_l") == nil end)
                if missing then pcall(function() CD.applyBagVisual(a) end) end
            end
            -- Migracao da chave de dono estavel: cao de save antigo (owned via ownerName legado) ganha d.ownerKey
            -- do dono atual ao carregar perto dele. Idempotente; a partir dai a posse casa pela chave estavel (Steam
            -- ID) e sobrevive a morte do personagem. So carimba quando muda pra nao spammar transmit.
            -- Só carimba quando AUSENTE (save antigo). Nunca re-escreve por diferença de valor: evita churn per-tick
            -- de CD.transmit se a chave variar, e o isOwnedBy/getOwnerPlayer são UNIÃO (o ownerName legado cobre até lá).
            if da.ownerKey == nil or da.ownerKey == "" then
                local ok = CD.ownerKey(player)
                if ok ~= nil and ok ~= "" then
                    da.ownerKey = ok
                    CD.transmit(a)
                end
            end
            -- Espelho do canil pros PASSIVOS (o do ativo vive em updateCompanion); tambem backfill de saves antigos.
            if CD.kennelMirror then CD.kennelMirror(player, a) end
            maybeUpdate(a, player)
        end
        if grew then pcall(function() player:transmitModData() end) end
    end
    if crossFloor then
        maybeUpdate(crossFloor, player)
    end
end

-- Mantem caes guardados no owner a cada tick (o loop pesado abaixo so roda a cada COMPANION_TICK_INTERVAL). Des-esconde/restaura quando o owner sai do veiculo ou se afasta.
-- O cao montado e deletado, entao updateUpkeep nunca roda pra ele e fome/sede ficariam congeladas por
-- toda a viagem. Avanca eles no registro de stash na MESMA taxa de upkeep manual (o cao e invencivel,
-- entao nao ha acrescimo nativo a espelhar; updateUpkeep usa HUNGER_PER_DAY/THIRST_PER_DAY). Throttle no
-- intervalo de upkeep e cap como updateUpkeep; respawnCompanion aplica isso ao desmontar. Vida/lealdade ficam
-- congeladas de proposito: o cao nao pode morrer durante a viagem, e updateUpkeep retoma isso assim que ele volta.
local function advanceMountedNeeds(owner)
    if not CD.upkeepEnabled() then return end
    local pd = CD.playerData(owner)
    local rec = pd.stash
    if not rec then return end
    local now = worldMinutes()
    local last = rec.lastNeedMin
    if not last then rec.lastNeedMin = now; return end
    local elapsed = now - last
    if elapsed < (CD.UPKEEP_INTERVAL_MIN or 1) then return end
    rec.lastNeedMin = now
    -- Mesmo freeze offline do updateUpkeep, pra um cao guardado num veiculo durante um disconnect. A divida e 0 durante
    -- direcao online normal, entao o acrescimo na estrada e preservado EXATAMENTE: a viagem nunca para de alimentar a fome.
    elapsed = applyOfflineDebt(owner, elapsed)
    if elapsed <= 0 then return end
    local step = math.min(elapsed, CD.UPKEEP_MAX_CATCHUP_MIN or 360)
    local dDay = step / 1440
    rec.hunger = math.min(1, (rec.hunger or 0) + (CD.HUNGER_PER_DAY or 0.30) * dDay)
    rec.thirst = math.min(1, (rec.thirst or 0) + (CD.THIRST_PER_DAY or 0.60) * dDay)
    owner:transmitModData()
end

local function tickMountedDogs()
    for id, animal in pairs(mountedDogs) do
        local keep = false
        pcall(function()
            local owner = CD.getOwnerPlayer(animal)
            if owner and CD.isMounted(owner) then
                mountRefresh(animal, owner, CD.data(animal))
                advanceMountedNeeds(owner)
                keep = true
            end
        end)
        if not keep then
            local done = true
            pcall(function() done = mountClear(animal, CD.data(animal)) end)
            -- Mantem o cao em mountedDogs (retry no proximo tick) so enquanto mountClear ainda nao conseguiu respawnar (owner
            -- presente mas square ainda carregando em MP). Done (recuperado / owner foi embora), tira a linha.
            if done then mountedDogs[id] = nil end
        end
    end
end

-- Roadkill: re-afirmacao da invencibilidade permanente, INDEPENDENTE do owner. Roadkill e um
-- setHealth(0) instantaneo que setHealth so honra via isInvincible(). makeCompanion/updateCompanion ja ligam isso,
-- mas updateCompanion so roda perto do owner online do cao e a flag de invencivel nao sobrevive a save/reload
-- nem a um copyFrom (pickup/drop), entao um cao deixado em stay/guard, atras de um owner dirigindo, ao lado de um motorista co-op, ou
-- recem-recarregado poderia ficar desprotegido. Isto varre cada animal carregado e re-afirma setIsInvincible(true) em cada
-- companion (barato: throttle no COMPANION_TICK_INTERVAL via companionTick). So liga a imunidade; o
-- unico lugar que desliga e permadeath/demote. As necessidades que isto congela sao dirigidas por updateUpkeep.
local function tickCompanionInvincible()
    local cell = getCell()
    if not cell then return end
    local wildInv = CD.wildDogsInvincible()
    -- Sandbox DespawnOnOwnerOffline: so em servidor MP (em SP getOwnerPlayer nunca retorna nil).
    local offlineDespawn = isServer() and CD.despawnOnOwnerOffline()
    local toStash = {}
    -- Players online (SP: getPlayer; MP: todos), montado uma vez e reusado por todo companion pra fixar a aceitacao do grito.
    local players = {}
    eachOnlinePlayer(function(p) if p then players[#players + 1] = p end end)
    pcall(function()
        local list = cell:getAnimals()
        if not list then return end
        for i = 0, list:size() - 1 do
            local a = list:get(i)
            if a and CD.isDog(a) and not CD.isCompanion(a) then
                -- Easy-mode (WildDogsInvincible): um cao nao-companion (stray/selvagem/solto) e indestrutivel enquanto a
                -- opcao esta ligada. So a flag (bloqueia o caminho setHealth de melee/firearm/roadkill/neglect); fogo e
                -- tratado por tickCompanionFire. Sem re-afirmar a wild-flag / holdStill (isso e coisa de companion-follow).
                if wildInv and not a:isInvincible() then pcall(function() a:setIsInvincible(true) end) end
                -- scavenge virtual: stray com fome/sede "se vira sozinho" (nunca morre de fome); no-op sob
                -- WildDogsInvincible (invencivel congela o acumulo de needs)
                CD.strayScavenge(a)
            elseif a and CD.isDog(a) and CD.isCompanion(a) then
                if not a:isInvincible() then pcall(function() a:setIsInvincible(true) end) end
                -- Nao-miravel: shootable e default TRUE (IsoMovingObject) e reseta em copyFrom/reload; a engine nunca
                -- re-habilita, mas updateCompanion so re-afirma no cao ATIVO, entao os PASSIVOS (nao-selecionados)
                -- voltavam a ser miraveis pela mira/auto-aim. Re-afirma aqui p/ TODO companion, como a invencibilidade.
                pcall(function() if a:isShootable() then a:setShootable(false) end end)
                -- Filhote: mantem a escala pequena fixa (a engine re-deriva tamanho pela idade; sem este pin ele "cresce"
                -- de volta). size vive no AnimalData (getData()), nao no IsoAnimal; setSizeForced ignora o clamp
                -- min/max do tipo. So reforca quando o tamanho derivou (evita reescrever originalSize todo sweep).
                -- Removido na maturacao (Fase B), que troca pro tipo adulto.
                if CD.data(a).isPup then pcall(function()
                    local dt = a:getData()
                    if dt and dt.setSizeForced then
                        local want = CD.PUPPY_SIZE or 0.6
                        if not dt.getSize or math.abs(dt:getSize() - want) > 0.01 then dt:setSizeForced(want) end
                    end
                    -- Suprime o crescimento NATIVO de TODO filhote: a engine cresceria via grow() (que DESCARTA nosso
                    -- ModData -> cao orfao) quando getDaysSurvived() >= ageToGrow (90 cravado em DogDefinitions). daysSurvived
                    -- deriva de hoursSurvived, entao seguramos hoursSurvived 2 dias abaixo de 90 -> checkStages nunca dispara.
                    -- A maturacao REAL (preservando o vinculo) e feita por tickMaturation no prazo configuravel (MaturityDays).
                    -- Usa a CONSTANTE MATURITY_DAYS (=90, casa o ageToGrow nativo), NAO o sandbox: o limite da engine e fixo.
                    -- d.growthPaused nao afeta este cap (so gateia tickMaturation); filhote pausado = pup pra sempre.
                    if a.getHoursSurvived and a.setHoursSurvived then
                        local capHours = ((CD.MATURITY_DAYS or 90) - 2) * 24
                        if a:getHoursSurvived() > capHours then a:setHoursSurvived(capHours) end
                    end
                end) end
                -- A flag `wild` da engine (como a flag de invencivel acima) NAO sobrevive a save/reload,
                -- e eventos de perigo (ex.: o owner gritando) podem virar um companion de volta pra wild. Um companion
                -- wild ignora followOwner e roda a IA de wander/flee da engine ("anda como um stray,
                -- foge ao grito, nao segue"). makeCompanion seta wild=false so uma vez na hora do tame, entao
                -- re-afirma aqui a cada sweep, independente do owner, pra um cao recarregado/assustado se re-domesticar.
                pcall(function()
                    if a.setWild then
                        a:setWild(false)
                    end
                end)
                -- Grito: a engine faz um companion FUGIR quando um humano grita perto (respondToSound). Aceitacao > 40 pelo
                -- gritante e o unico ramo que nao foge, entao fixa-a alta pra cada player online (cobre o grito de QUALQUER
                -- um, SP e MP); tambem reforca fleeFromChr (dono correndo). Ver CD.calmAcceptance.
                for pi = 1, #players do CD.calmAcceptance(a, players[pi]) end
                -- Multi-dog: fixa companions PASSIVOS (qualquer cao do owner que nao seja o ATIVO dele) pra que o
                -- wanderIdle da engine nao os arraste em direcao ao owner. updateCompanion dirige o cao ativo
                -- (e limpa o hold antes de pathar), entao so caes nao-ativos sao segurados aqui. Um owner que nao
                -- conseguimos resolver (offline/longe), trata como passivo e segura ele onde esta.
                local owner = CD.getOwnerPlayer(a)
                -- Dono OFFLINE (ownerName sem match online) + sandbox ligada: guarda o cao fora do mundo. Coleta e
                -- deleta APOS o loop (delete no meio encolhe a lista java e estoura o get(i)); cao legado sem
                -- ownerName fica de fora (sem chave de registro).
                if offlineDespawn and owner == nil and CD.data(a).ownerName then
                    toStash[#toStash + 1] = a
                else
                    local activeForOwner = owner ~= nil and CD.data(a).companionToken == CD.playerData(owner).token
                    -- femea indo cruzar (breedTarget) precisa andar ate o macho: nao a fixa, mesmo passiva.
                    if not activeForOwner and not CD.data(a).breedTarget then holdStill(a) end
                end
            end
        end
    end)
    for i = 1, #toStash do CD.offlineStashDog(toStash[i]) end
end

-- Quao longe procurar um tile seguro ao tirar um cao de um tile em chamas. Local (nao e sandbox option): imunidade
-- a fogo e incondicional, como imunidade a roadkill/firearm. Cobertura extra do anel; o fallback de ultimo-tile-seguro
-- (fireSafeTile) cobre quando o cao esta cercado de fogo alem deste raio.
local FIRE_ESCAPE_RADIUS = 6

-- Taxa de dano de fogo por frame da engine (IsoGameCharacter.fireKillRate); um animal toma `*0.9` disso por
-- GameTime.multiplier a cada update(). O restore por-tick e ESTRUTURALMENTE 1 tick atrasado (roda depois do
-- update() que aplica o dano), entao em multiplier alto (fast-forward/sono) um unico frame pode zerar um cao
-- de vida baixa antes do proximo restore. Usado pra um piso de HP que sobrevive a UM frame mesmo nesse regime.
local FIRE_KILL_RATE = 0.0038

-- Um square que pegaria/queimaria um IsoAnimal parado: o FireCheck da engine reacende na flag de chao `burning`,
-- e um objeto IsoFire (fogo que se espalha) esta no tile. Uma lareira/churrasqueira acesa (hasFireObject) e um
-- fogo CONTIDO sem a flag `burning`, entao nunca acende o cao (excluido, pra ele poder descansar perto de uma fogueira).
local function squareHasFire(sq)
    local r = false
    pcall(function() r = sq:getProperties():has(IsoFlagType.burning) or sq:haveFire() end)
    return r
end

-- Tile caminhavel mais proximo, sem fogo e sem agua, pra colocar o cao, buscado anel por anel; dentro do primeiro anel
-- que tiver algum candidato, o mais perto de (towardX,towardY) vence pra o cao ficar perto do owner.
local function findFireEscapeTile(cell, sq, towardX, towardY)
    local cx, cy, cz = sq:getX(), sq:getY(), sq:getZ()
    local best, bestD = nil, nil
    for r = 1, FIRE_ESCAPE_RADIUS do
        for dx = -r, r do
            for dy = -r, r do
                if math.max(math.abs(dx), math.abs(dy)) == r then
                    local s = cell:getGridSquare(cx + dx, cy + dy, cz)
                    if s and s:isFree(false) and not s:getProperties():has(IsoFlagType.water)
                       and not squareHasFire(s) then
                        local ddx, ddy = (cx + dx) - towardX, (cy + dy) - towardY
                        local d = ddx * ddx + ddy * ddy
                        if not bestD or d < bestD then best, bestD = s, d end
                    end
                end
            end
        end
        if best then break end
    end
    return best
end

-- Imunidade a fogo + evasao. setIsInvincible NAO para o fogo: ReduceHealthWhenBurning() roteia o dano de queimadura
-- de um IsoAnimal por CombatManager.applyDamage, que subtrai vida direto (ignorando IsoAnimal.setHealth,
-- o unico lugar onde isInvincible() e honrado); seu unico escape nativo e o cheat GOD_MODE, um no-op em SP sem
-- -debug. Entao um molotov / predio em chamas / fogueira mataria um companion "invencivel", quebrando a promessa de "morte so
-- por negligencia". Roda a CADA tick (nao no bloco throttle): dano de fogo e por-frame e FireCheck() reacende
-- qualquer IsoAnimal cujo square tenha a flag `burning`, entao precisamos (1) StopBurning + restaurar o HP roubado do frame
-- (setHealth pra CIMA e permitido enquanto invencivel) a partir da baseline sem-fogo pra ele nunca tomar dano de fogo LIQUIDO, e
-- (2) tirar ele do tile em chamas pro mais proximo seguro (em direcao ao owner) pra ele nao ficar parado/piscando no fogo.
-- Caes num veiculo/trailer ja estao a salvo do fogo (FireCheck retorna cedo em getVehicle()!=null); caes montados/parados
-- estao fora do mundo. Entao varrer a lista de animais da cell basta.
local function tickCompanionFire()
    local cell = getCell()
    if not cell then return end
    local wildInv = CD.wildDogsInvincible()
    pcall(function()
        local list = cell:getAnimals()
        if not list then return end
        for i = 0, list:size() - 1 do
            local a = list:get(i)
            -- Companions sempre; caes nao-companion tambem quando WildDogsInvincible esta ligado (setIsInvincible nao
            -- para o fogo, entao a promessa de indestrutivel precisa desse guard). getOwnerPlayer e nil pra um cao wild, entao a
            -- busca de escape-tile so cai de volta pra propria posicao do cao (ja tratado abaixo).
            if a and CD.isDog(a) and (CD.isCompanion(a) or wildInv) then
                local id = a:getOnlineID()
                -- onlineID pode ser nil/-1 num cao recem-spawnado antes de ser atribuido; dois caes nesse estado
                -- colidiriam na mesma chave e trocariam baseline/safe-tile. So usa as tabelas (estado cross-tick) com
                -- um id valido; sem ele, ainda apaga/escapa do fogo neste tick com uma baseline local (sem persistir).
                local validId = id ~= nil and id >= 0
                local sq = a:getSquare()
                local danger = sq ~= nil and squareHasFire(sq)
                if a:isOnFire() or danger then
                    -- Baseline = HP a segurar contra o fogo. Persiste (e inicializa no 1o contato) so com id valido;
                    -- sem id usa o HP atual deste frame. setHealth pra cima e permitido enquanto invencivel.
                    local base
                    if validId then
                        base = fireBaseline[id]
                        if not base then base = a:getHealth(); fireBaseline[id] = base end
                    else
                        base = a:getHealth()
                    end
                    -- Piso de sobrevivencia ciente do multiplier: o restore e 1 tick atrasado, entao em fast-forward/sono
                    -- (multiplier alto) garante que o cao termine o frame acima do dano de UM frame de fogo. ~0 em
                    -- velocidade normal (nao cura um cao legitimamente ferido); so sobe quando o fogo de 1 frame seria letal.
                    local mult = 1.0
                    pcall(function() mult = getGameTime():getMultiplier() end)
                    local target = base
                    local survive = math.min(0.9, FIRE_KILL_RATE * 0.9 * mult * 1.5)
                    if survive > target then target = survive end
                    if a:getHealth() < target then
                        pcall(function() a:setHealth(target) end)
                    end
                    if a:isOnFire() then pcall(function() a:StopBurning() end) end
                    if danger then
                        local tx, ty = a:getX(), a:getY()
                        pcall(function()
                            local owner = CD.getOwnerPlayer(a)
                            local os = owner and owner:getCurrentSquare()
                            if os then tx, ty = os:getX(), os:getY() end
                        end)
                        local esc = findFireEscapeTile(cell, sq, tx, ty)
                        -- Fallback p/ o ultimo tile seguro conhecido quando o anel falha (cao cercado por fogo alem do
                        -- raio, ex.: predio em chamas): sem um destino o cao fica preso no tile `burning` e o FireCheck
                        -- da engine o reacende todo frame = VISIVELMENTE queimando mesmo com o HP restaurado. Re-fetcha
                        -- o square por coords (nil se descarregou) e aplica o MESMO predicado do anel (livre, sem agua,
                        -- com chao, sem fogo) pra nao teletransportar pra um tile bloqueado/agua.
                        if validId and not (esc and CD.squareHasFloor(esc)) then
                            local safe = fireSafeTile[id]
                            if safe then
                                local ss = cell:getGridSquare(safe.x, safe.y, safe.z)
                                if ss and ss:isFree(false) and not ss:getProperties():has(IsoFlagType.water)
                                   and CD.squareHasFloor(ss) and not squareHasFire(ss) then
                                    esc = ss
                                end
                            end
                        end
                        if esc and CD.squareHasFloor(esc) then
                            pcall(function()
                                a:stopAllMovementNow()
                                a:setX(esc:getX() + 0.5)
                                a:setY(esc:getY() + 0.5)
                                a:setZ(esc:getZ())
                                a:setCurrent(esc)
                            end)
                        end
                    end
                elseif validId then
                    fireBaseline[id] = a:getHealth()
                    -- Ultimo tile sem fogo: destino de fallback do escape acima. So coords (re-fetch valida liveness);
                    -- reusa a tabela existente in-place pra nao alocar todo tick sem fogo (path comum, sem throttle).
                    if sq then
                        local t = fireSafeTile[id]
                        if t then t.x, t.y, t.z = sq:getX(), sq:getY(), sq:getZ()
                        else fireSafeTile[id] = { x = sq:getX(), y = sq:getY(), z = sq:getZ() } end
                    end
                end
            end
        end
    end)
end

-- Evita leak de fireBaseline/fireSafeTile: reapDogState (o unico clearer dessas tabelas) so roda pra COMPANIONS,
-- entao entradas de caes NAO-companion (strays sob WildDogsInvincible, que entram no guard de fogo acima) nunca
-- seriam liberadas e cresceriam sem limite numa sessao longa com spawn de vira-latas. Varre no bloco throttled e
-- descarta ids que nao estao mais entre os animais carregados da cell (companions montados/guardados saem da lista
-- e sao podados tambem: inofensivo, a baseline re-inicializa no proximo tick sem fogo quando voltam ao mundo).
local function pruneFireState()
    local cell = getCell()
    if not cell then return end
    pcall(function()
        local list = cell:getAnimals()
        if not list then return end
        local present = {}
        for i = 0, list:size() - 1 do
            local a = list:get(i)
            if a then
                local id = a:getOnlineID()
                if id then present[id] = true end
            end
        end
        for id in pairs(fireBaseline) do
            if not present[id] then fireBaseline[id] = nil end
        end
        for id in pairs(fireSafeTile) do
            if not present[id] then fireSafeTile[id] = nil end
        end
        CD.strayScavengePrune(present)
    end)
end

-- (isFirearmThreat e definido mais cedo neste arquivo; hoje SO o tickGunGuard o usa, o steer de followOwner foi
-- removido. Local no mesmo arquivo de proposito, veja a nota daquela definicao.)

-- Liga/desliga o guard de firearm num cao. GOD_MODE (setInvulnerable) deixa isGodMod() true, o que tira o cao
-- de CombatManager.removeTargetObjects, uma arma mirada nunca o alveja (sem hit nenhum). Efeito colateral:
-- IsoGameCharacter.update() zera CharacterStat.HUNGER a cada tick sob GOD_MODE, entao tiramos um snapshot da fome quando
-- o guard liga e restauramos quando ele desliga (na pratica pausando a fome pela breve janela de mira).
-- THIRST nao e resetado pelo GOD_MODE, entao fica intacto. (setIsInvincible nao e mais tocado aqui: companions
-- sao permanentemente invenciveis, entao o setHealth a distancia ja esta bloqueado; este guard so adiciona a
-- transparencia total do GOD_MODE por cima, util em co-op/-debug onde tira o cao da lista de hits da arma por inteiro.)
local function setGunGuard(animal, on)
    local d = CD.data(animal)
    if on then
        pcall(function() animal:setInvulnerable(true) end)
        if d.gunHungerSave == nil then
            pcall(function() d.gunHungerSave = animal:getHunger() end)
            CD.transmit(animal) -- sincroniza o snapshot pra status bar mostrar o valor congelado (co-op tambem)
        end
    else
        pcall(function() animal:setInvulnerable(false) end)
        if d.gunHungerSave ~= nil then
            local h = d.gunHungerSave
            d.gunHungerSave = nil
            setNeed(animal, "hunger", h)
            CD.transmit(animal)
        end
    end
end

-- Imunidade a firearm: guard a CADA tick, INDEPENDENTE do owner. A engine ignora
-- setShootable pra firearms MIRADAS em animais, entao enquanto qualquer player proximo mira/ataca com firearm guardamos
-- caes companions com GOD_MODE, que os tira da lista de hits onde cheats sao permitidos (o
-- setIsInvincible permanente ja bloqueia o setHealth a distancia em todo lugar, veja setGunGuard). HISTERESE: o guard de cada cao no alcance e mantido ate um
-- deadline em ticks (GUN_GUARD_HOLD_TICKS apos a ultima ameaca), pra o tick de fogo nao escapar por um gap de re-scan.
-- Autoridade SP/dedicated; o client do atirador espelha GOD_MODE na propria copia (sua lista de alvos local).
local function tickGunGuard()
    gunGuardTick = gunGuardTick + 1
    local cell = getCell()
    if not cell then return end
    local aimers = nil
    eachOnlinePlayer(function(p)
        if p and isFirearmThreat(p) then
            aimers = aimers or {}
            aimers[#aimers + 1] = { x = p:getX(), y = p:getY(), z = math.floor(p:getZ()) }
        end
    end)

    if aimers then
        local R = CD.GUN_RISK_RADIUS or 10
        local R2 = R * R
        local hold = CD.GUN_GUARD_HOLD_TICKS or 12
        -- Uma passada por cell:getAnimals() no lugar do sweep 21x21 de getGridSquare POR aimer (custava ~441
        -- getGridSquare * nAimers por tick): para cada companion, testa distancia (Lua) ao aimer mais proximo no mesmo
        -- andar. O par guard/hold/release abaixo e preservado. (Numa dedicated a lista tem TODOS os animais carregados no
        -- server, entao um registry por-companion seria o passo seguinte; ainda assim isto e ordens de magnitude mais barato.)
        local list = cell:getAnimals()
        if list then
            for i = 0, list:size() - 1 do
                local a = list:get(i)
                if a and CD.isDog(a) and CD.isCompanion(a) then
                    local ax, ay, az = a:getX(), a:getY(), math.floor(a:getZ())
                    local near = false
                    for j = 1, #aimers do
                        local p = aimers[j]
                        if p.z == az then
                            local dx, dy = ax - p.x, ay - p.y
                            if dx * dx + dy * dy <= R2 then near = true; break end
                        end
                    end
                    if near then
                        local id = a:getOnlineID()
                        -- Reticle: nega o auto-aim TODO tick enquanto miram (cao passivo perto reabria shootable no ativo
                        -- dentro da janela de 20t do updateCompanion; tickGunGuard roda por tick sob mira, entao some).
                        pcall(function() if a:isShootable() then a:setShootable(false) end end)
                        if not gunGuarded[id] then
                            gunGuarded[id] = a
                            setGunGuard(a, true)
                        end
                        gunGuardUntil[id] = gunGuardTick + hold
                    end
                end
            end
        end
    end

    -- Solta so os caes cujo deadline de hold ja passou (histerese), nao no instante que a mira para.
    for id, a in pairs(gunGuarded) do
        if (gunGuardUntil[id] or 0) <= gunGuardTick then
            setGunGuard(a, false)
            gunGuarded[id] = nil
            gunGuardUntil[id] = nil
        end
    end
end

-- Um registro de recovery de carry/stash/trailer ainda e NOSSO se o token do cao for qualquer um dos caes bonded do player:
-- o ATIVO OU um passivo. Multi-dog + Select move pd.token pra outro cao enquanto o cao deslocado
-- fica em pd.companions, entao um gate so-ativo (== pd.token) jogaria fora por engano um registro ainda valido e o
-- cao reconstruido por copyFrom voltaria pra wild. Fallback legado (== pd.token) cobre saves pre-multi-dog cujo
-- conjunto pd.companions pode nao listar o token ativo. Local no mesmo arquivo (nao CD.*): trap de shared-cache do server-VM.
local function recordStillBonded(pd, tok)
    if tok == nil then return false end
    if type(pd.companions) == "table" and pd.companions[tok] then return true end
    return tok == pd.token
end

-- Existe um companion vivo, no mundo, com este token EXATO ja carregado pro owner? Usado pra decidir se um
-- cao guardado ainda precisa de respawn, seguro pra multi-dog (diferente de CD.getCompanionAnimal, que retorna QUALQUER
-- companion do dono, entao um cao carregado diferente cancelaria por engano o respawn do cao guardado).
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

-- Local no mesmo arquivo (NAO CD.findCarriedDogItem) de proposito: um helper CD.* recem-adicionado num arquivo shared/ pode
-- retornar nil no server VM (cache stale de shared-file, um trap conhecido do CompanionDogs), e isto roda num
-- tick de server. Duplicar as ~10 linhas aqui garante que resolve. (CD.isDog ja existe, entao e seguro.)
-- Definido aqui (acima de recoverStashedDogs) pra o recovery de stash conseguir distinguir um cao carregado-no-inventario.
local function findCarriedDogItem(player)
    if not player then return nil end
    local inv = player:getInventory()
    if not inv then return nil end
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and instanceof(it, "AnimalInventoryItem") then
            local a = nil
            pcall(function() a = it:getAnimal() end)
            if a and CD.isDog(a) then return it, a end
        end
    end
    return nil
end

-- Seguro pra multi-dog: existe um companion com EXATAMENTE este token sendo carregado agora no inventario do owner? findCarriedDogItem
-- retorna so o PRIMEIRO AnimalInventoryItem, entao nao responde "este token esta sendo carregado" quando dois caes estao nas maos.
-- Usado pelos guards anti-duplicata (o cao carregado tomou removeFromWorld(), entao nenhum scan de cell o ve).
-- Exige POSSE (token e por-jogador): carregar no colo o cao de OUTRO jogador com o mesmo numero de token respondia
-- "sim" e fazia o chamador DESCARTAR o registro de stash do meu proprio cao -> cao perdido de vez.
local function carryingDogWithToken(player, tok)
    if not player or tok == nil then return false end
    local inv = player:getInventory()
    if not inv then return false end
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if it and instanceof(it, "AnimalInventoryItem") then
            local a = nil
            pcall(function() a = it:getAnimal() end)
            if a and CD.isDog(a) and CD.isOwnedBy(a, player) and CD.data(a).companionToken == tok then return true end
        end
    end
    return false
end

-- Respawna um companion que foi perdido porque o jogo salvou enquanto ele estava guardado num veiculo. Roda so
-- quando o owner NAO esta montado no momento (montado, um cao ausente e o estado guardado esperado) e
-- nao existe companion vivo. Auto-limpa o registro pra disparar uma vez. Reload-enquanto-sentado tambem e tratado:
-- isMounted continua true no reload, entao o recovery espera ate o player sair do veiculo da proxima vez.
local function recoverStashedDogs()
    eachOnlinePlayer(function(player)
        local pd = CD.playerData(player)
        local rec = pd.stash
        if not rec then return end
        -- O stash e valido enquanto seu token ainda for um dos caes bonded do player (ativo OU passivo:
        -- um Select no meio da viagem pode rebaixar o cao guardado pra passivo). So descarta quando o token saiu do
        -- conjunto de bond (solto/substituido/re-domesticado), pra nao ressuscitar um companion fantasma.
        local stok = rec.data and rec.data.companionToken
        if not recordStillBonded(pd, stok) then
            pd.stash = nil
            pcall(function() player:transmitModData() end)
            return
        end
        if CD.isMounted(player) then return end
        -- Multi-dog: so pula o respawn se ESTE cao guardado exato ja estiver vivo. getCompanionAnimal retornaria
        -- um companion carregado DIFERENTE e cancelaria o respawn por engano, perdendo o cao guardado (deletado).
        if liveOwnedDogWithToken(player, stok) then
            pd.stash = nil
            pcall(function() player:transmitModData() end)
            return
        end
        -- Carregado (AnimalInventoryItem) tomou removeFromWorld(), entao NAO esta em getCell():getAnimals() e
        -- liveOwnedDogWithToken nao o ve. Respawnar a partir de um stash stale coexistente aqui cria uma DUPLICATA
        -- ao lado do cao carregado (o report do RV "pega o cao, aparece um segundo"). Mesmo cao, descarta o stash.
        if carryingDogWithToken(player, stok) then
            pd.stash = nil
            pcall(function() player:transmitModData() end)
            return
        end
        local fresh = respawnCompanion(nil, player, rec)
        if fresh then
            -- Carimba este respawn de desmonte como canonical (cunha uid se faltar) pra o gen reaper poder colapsar um twin
            -- de interior abandonado deixado pelo caminho de saida snapshot-seed (rvexit fallback) quando o owner re-entra no RV.
            -- Espelha attemptTeleportBring (b)/(c). Pro desmonte de driving-stash simples nao ha twin, e inofensivo.
            local fd = CD.data(fresh)
            if not fd.uid then fd.uid = tostring(getTimestampMs()) .. "-" .. tostring(ZombRand(0, 2147483647)) end
            bumpCanonical(player, fresh)
            pd.stash = nil
            pcall(function() player:transmitModData() end)
        end
    end)
end

-- Sandbox DespawnOnOwnerOffline (default off): com o dono OFFLINE o servidor guarda o cao fora do mundo e o devolve
-- na reconexao. O registro NAO pode viver em pd.stash (sem objeto player com o dono offline), entao vai num ModData
-- GLOBAL keyed por ownerName -> { [token] = rec } (persiste sozinho no servidor, como o SPAWN_KEY do Spawn.lua).
-- Do-block: o chunk esta no teto de 200 locals; funcoes expostas em CD.* (chamadas em call-time, ordem no arquivo ok).
do
    local KEY = CD.MODULE .. "_OfflineStash"
    local function store() return ModData.getOrCreate(KEY) end

    -- Despawn de um companion carregado cujo dono esta offline. Chamado por tickCompanionInvincible FORA do loop de
    -- iteracao (delete no meio encolhe a lista java e estoura o get(i)). Espelha stashMounted + convertCarriedToStash.
    function CD.offlineStashDog(animal)
        local d = CD.data(animal)
        local tok = d.companionToken
        -- Keyed pela chave de dono ESTAVEL (lida do proprio cao; o dono esta offline, sem player pra computar).
        -- Sobrevive a troca de nome; cai no ownerName legado quando o cao ainda nao migrou.
        local key = (d.ownerKey ~= nil and d.ownerKey ~= "") and d.ownerKey or d.ownerName
        if not key or key == "" or not tok then return end
        d.stashed = true
        local rec = CD.buildStashRecord(animal)
        rec.x = math.floor(animal:getX()); rec.y = math.floor(animal:getY()); rec.z = math.floor(animal:getZ())
        local s = store()
        s[key] = s[key] or {}
        s[key][tok] = rec
        local oid = animal:getOnlineID()
        pcall(function()
            animal:stopAllMovementNow()
            animal:delete()
        end)
        reapDogState(oid)
    end

    -- Este token esta guardado fora do mundo no stash de dono-offline? O reaper de fantasma precisa saber: um cao
    -- guardado nao esta em cell:getAnimals(), e sem isto ele era julgado "perdido" quando o dono reconectava em cima
    -- do anchor e o respawn ainda nao tinha rodado (dono montado / square ainda em streaming).
    function CD.offlineStashHas(player, tok)
        if not player or tok == nil then return false end
        local s = store()
        local recs = s[CD.ownerKey(player)] or s[player:getUsername()]
        return type(recs) == "table" and recs[tok] ~= nil
    end

    -- Devolve os caes guardados de cada dono ONLINE. Cao ativo em FOLLOW volta junto ao dono (espelha
    -- recoverStashedDogs, espera desmontar); STAY/GUARD/passivo volta NO POSTO quando o square carregar
    -- (retry barato a cada passada; enquanto isso segue guardado com as needs congeladas).
    function CD.recoverOfflineStashes()
        eachOnlinePlayer(function(player)
            local s = store()
            local name = player:getUsername()
            -- Prefere o bucket da chave estavel (Steam ID); cai no bucket legado por username (stashes de antes da migracao).
            local key = CD.ownerKey(player)
            local bucketKey = (key and s[key]) and key or name
            local recs = bucketKey and s[bucketKey]
            if not recs then return end
            local pd = CD.playerData(player)
            local toks = {}
            for tok in pairs(recs) do toks[#toks + 1] = tok end
            for i = 1, #toks do
                local tok = toks[i]
                local rec = recs[tok]
                local drop = false
                if not rec or not rec.data or not recordStillBonded(pd, tok) then
                    drop = true
                elseif pd.stash and pd.stash.data and pd.stash.data.companionToken == tok then
                    drop = true   -- mesmo cao ja tem stash de veiculo (caminho validado vence)
                elseif liveOwnedDogWithToken(player, tok) or carryingDogWithToken(player, tok) then
                    drop = true
                else
                    local follow = (rec.data.state or CD.STATE_FOLLOW) == CD.STATE_FOLLOW and tok == pd.token
                    local ready, atSq = true, nil
                    if follow then
                        if CD.isMounted(player) then ready = false end
                    else
                        atSq = rec.x and getCell() and getCell():getGridSquare(rec.x, rec.y, rec.z) or nil
                        if not atSq then ready = false end
                    end
                    if ready then
                        local fresh = respawnCompanion(nil, player, rec, atSq)
                        if fresh then
                            local fd = CD.data(fresh)
                            if not fd.uid then fd.uid = tostring(getTimestampMs()) .. "-" .. tostring(ZombRand(0, 2147483647)) end
                            bumpCanonical(player, fresh)
                            drop = true
                        end
                    end
                end
                if drop then recs[tok] = nil end
            end
            local empty = true
            for _ in pairs(recs) do empty = false; break end   -- next() nao existe no Kahlua do PZ
            if empty then s[bucketKey] = nil end
        end)
    end
end

-- Canil GLOBAL durável (nível-mundo): espelho do pd.kennel que SOBREVIVE à morte do personagem (o pd por-personagem
-- é apagado). Keyed pela CHAVE DE DONO ESTÁVEL (Steam ID) -> { [token] = snapshot }, mesmo formato do pd.kennel[token].
-- Persiste sozinho no save/servidor (padrão do _OfflineStash / SPAWN_KEY). Um personagem novo (SP) ou player reconectado
-- (MP) reconstrói o pd.kennel a partir daqui (reclaimKennelFromGlobal) e pode dar recall de qualquer lugar, sem alcançar
-- o cão. Do-block: o chunk está no teto de 200 locals do Kahlua, então só KEY é local; as funções vão em CD.*.
do
    local KEY = CD.MODULE .. "_Kennel"
    local function store() return ModData.getOrCreate(KEY) end

    -- Grava/atualiza o snapshot durável de um cão sob a chave estável do dono. Deep-copy pra não aliasar a tabela do
    -- pd.kennel (ModData por-personagem) dentro do ModData global. No-op sem chave/token.
    function CD.kennelGlobalPut(ownerKey, tok, snap)
        if ownerKey == nil or ownerKey == "" or tok == nil or type(snap) ~= "table" then return end
        local s = store()
        s[ownerKey] = s[ownerKey] or {}
        s[ownerKey][tok] = CD.deepCopy(snap)
    end

    -- Retorna a tabela { [token] = snapshot } do dono (referência viva do store), ou nil.
    function CD.kennelGlobalGet(ownerKey)
        if ownerKey == nil or ownerKey == "" then return nil end
        return store()[ownerKey]
    end

    -- Store inteiro { [ownerKey] = { [token] = snapshot } }. Só o reparo de posse (CD.repairOwnership) usa: ele
    -- precisa cruzar buckets pra achar o MESMO cão (uid) registrado sob dois donos.
    function CD.kennelGlobalAll()
        return store()
    end

    -- Remove uma entrada (cão solto/vínculo quebrado); limpa o bucket do dono quando esvazia.
    function CD.kennelGlobalDrop(ownerKey, tok)
        if ownerKey == nil or ownerKey == "" or tok == nil then return end
        local s = store()
        local recs = s[ownerKey]
        if type(recs) ~= "table" then return end
        recs[tok] = nil
        local empty = true
        for _ in pairs(recs) do empty = false; break end   -- next() nao existe no Kahlua do PZ
        if empty then s[ownerKey] = nil end
    end
end

-- Um cao carregado (item Animal nativo nas maos) nunca pode ficar como um hand-item dropavel enquanto o owner esta num
-- veiculo: desequipar (ex.: trocar pra uma arma no meio da viagem) materializa um cao wild NOVO no
-- tile do owner, debaixo do carro em movimento, e o roadkill da setHealth(0) antes de recoverCarriedDogs (proximo tick throttle)
-- conseguir re-armar a imunidade (uma morte silenciosa e permanente). Entao converte o carry no STASH dentro-do-veiculo (o mesmo
-- snapshot seguro que um cao em follow usa enquanto dirige): tira um snapshot do animal vivo na mao, dropa o item, passa o
-- respawn de desmonte pra recoverStashedDogs. Idempotente; retorna true se converteu.
function CD.convertCarriedToStash(player)
    if not player or not CD.isMounted(player) then return false end
    local item, held = findCarriedDogItem(player)
    if not (item and held and CD.isDog(held) and CD.isOwnedBy(held, player) and CD.isCompanion(held)) then
        return false
    end
    local pd = CD.playerData(player)
    local oid = held:getOnlineID()
    CD.writeStashRecord(held, player)
    pd.carried = nil
    -- Remove o hand-item SEM o spawn drop-to-world da engine, pra nenhum cao materializar debaixo do carro. Uma
    -- remocao server-side TEM que sincronizar com o client (sendRemoveItemFromContainer ANTES de Remove); um Remove cru
    -- deixa um item ghost no client cujo drop nunca completa (travado em "Dropping"). Espelha o caminho de drop do dish.
    local cont = (item.getContainer and item:getContainer()) or player:getInventory()
    if isServer() then pcall(function() sendRemoveItemFromContainer(cont, item) end) end
    pcall(function() cont:Remove(item) end)
    reapDogState(oid)
    pcall(function() player:transmitModData() end)
    return true
end

-- A borda do client (CompanionDogs_Carry.lua OnPlayerUpdate) dispara isto no instante em que o owner entra num veiculo
-- ainda segurando o cao, fechando a corrida de ate-COMPANION_TICK_INTERVAL antes que ele possa equipar uma arma.
-- Idempotente com o caminho de server-tick recoverCarriedDogs.
CD.Server.stashcarried = function(player, args)
    CD.convertCarriedToStash(player)
end

-- O owner carrega o cao como o item Animal nativo (segurado nas duas maos). No drop a engine reconstroi
-- um cao NOVO via copyFrom, que DERRUBA nosso getModData(), o cao volta pra nao-companion ("wild").
-- Nao ha evento Lua no drop, entao reconcilia aqui: o onlineID e preservado no pickup->drop
-- (copyFrom + AnimalInstanceManager.add o re-setam), entao quando um cao nao-companion com o
-- onlineID do registro carregado aparece no mundo, re-anexamos o bond. Nunca spawna (a engine ja fez no drop), sem
-- duplicatas. Enquanto ainda nas maos do owner, mantem o upkeep rodando pra as necessidades caírem mesmo no bolso.
local function recoverCarriedDogs()
    eachOnlinePlayer(function(player)
        local pd = CD.playerData(player)
        local item, held = findCarriedDogItem(player)

        -- (1) CARREGANDO AGORA: detectado 100% no SERVER varrendo o inventario do owner pelo item Animal
        -- nativo. Isto NAO precisa de comando de client nem arquivo client-side: num dedicated server o
        -- hook de pickup (client/) nem e carregado, entao o antigo caminho "o client manda o bond" nunca disparava
        -- (o log de server nao mostrava carry nenhum). O item mantem o ModData completo e autoritativo do cao; registra
        -- seu onlineID pra re-anexar no drop. Tambem mantem as necessidades rodando e trata morte na mao.
        if held and CD.isDog(held) and CD.isOwnedBy(held, player) and CD.isCompanion(held) then
            local d = CD.data(held)
            local oid = held:getOnlineID()
            if not pd.carried or pd.carried.onlineID ~= oid then
                pd.carried = { onlineID = oid, data = d }
                -- carried (nas maos) e stashed (num veiculo) sao mutuamente exclusivos; um stash pra ESTE mesmo cao
                -- agora e stale (espelha CD.Server.carry). Deixar la deixaria recoverStashedDogs respawnar um twin.
                if pd.stash and pd.stash.data and pd.stash.data.companionToken == d.companionToken then pd.stash = nil end
                -- Entrada durável recuperável se o dono morrer com o cao no colo (ver L725); idempotente.
                if CD.kennelSeedFromData and d.companionToken then CD.kennelSeedFromData(player, d.companionToken, d) end
                pcall(function() player:transmitModData() end)
            else
                pd.carried.data = d -- mantem o registro apontando pro bond vivo (que decai) pro restore no drop
                pd.carried.missingMs = nil
            end

            local hp = 1
            pcall(function() hp = held:getHealth() end)
            if hp <= 0 then
                -- Morreu nas maos do owner por negligencia. Limpeza segura best-effort: notifica, limpa o bond +
                -- registro, remove o item morto (evita animal:Kill() num animal preso ao inventario).
                if not d.diedNotified then
                    d.diedNotified = true
                    if d.companionToken == pd.token then pd.token = nil; pd.name = nil end
                    -- Libera o slot do limite de companions (MaxCompanions).
                    if d.companionToken ~= nil and type(pd.companions) == "table" then pd.companions[d.companionToken] = nil end
                    if CD.clearKennel then CD.clearKennel(player, d.companionToken) end
                    CD.notifyOwner(player, "died", { name = d.name, breed = CD.getBreed(held) })
                    promoteSuccessor(player, held)
                end
                local dcont = (item.getContainer and item:getContainer()) or player:getInventory()
                if isServer() then pcall(function() sendRemoveItemFromContainer(dcont, item) end) end
                pcall(function() dcont:Remove(item) end)
                pd.carried = nil
                reapDogState(oid)
                pcall(function() player:transmitModData() end)
                return
            end
            -- Num veiculo: guarda como o stash seguro dentro-do-veiculo em vez de manter um hand-item dropavel (rede de
            -- seguranca de server-tick; a borda do client normalmente vence antes; tambem cobre um carry recuperado de save/crash no meio da viagem).
            if CD.convertCarriedToStash(player) then return end
            -- Caes passivos ficam congelados (sem necessidades); so o cao ativo acumula, como um passivo no mundo.
            if CD.upkeepEnabled() and d.companionToken == pd.token then
                pcall(function() updateUpkeep(held, player, d) end)
            end
            return
        end

        -- (2) NAO carregando. Com um registro de carry arquivado, o cao acabou de ser dropado (a engine reconstruiu via
        -- copyFrom, apagando nosso ModData). O onlineID sobrevive ao pickup->drop, entao acha o cao reconstruido no mundo
        -- e re-anexa o bond. Nunca spawna (a engine ja fez), sem duplicatas.
        local rec = pd.carried
        if not rec then return end
        -- Pertencimento, nao igualdade de token-ativo: um cao carregado pode ser passivo na hora do drop (carrega e Select
        -- outro, ou carregando um cao ja passivo). Re-anexa enquanto seu token ainda estiver bonded.
        if not recordStillBonded(pd, rec.data and rec.data.companionToken) then
            pd.carried = nil
            pcall(function() player:transmitModData() end)
            return
        end
        local dog = nil
        pcall(function() dog = getAnimal(rec.onlineID) end)
        local inWorld = false
        pcall(function() inWorld = dog ~= nil and dog:getSquare() ~= nil end)
        if dog and inWorld and CD.isDog(dog) and not CD.isCompanion(dog) then
            pcall(function() dog:getModData().CompanionDogs = rec.data end)
            local nd = CD.data(dog)
            nd.mounted = nil
            nd.stashed = nil
            nd.diedNotified = nil
            nd.ownerId = nil
            pcall(function() CD.restoreFromKennel(player, dog) end)   -- marca d'agua contra record stale
            pcall(function() dog:setWild(false) end)
            pcall(function() dog:setShootable(false) end)
            -- Re-afirma imunidade a roadkill (copyFrom limpou); espelha o caminho do trailer.
            pcall(function() dog:setIsInvincible(true) end)
            CD.transmit(dog)
            if CD.hasBag(dog) then pcall(function() CD.applyBagVisual(dog) end) end
            pd.carried = nil
            pcall(function() player:transmitModData() end)
        end
        -- senao: cao dropado nao carregado/resolvivel neste tick, mantem o registro e tenta de novo no proximo tick.
        -- Mas registro ORFAO (sem item em lugar NENHUM do inventario e sem cao pra re-anexar; item deletado por
        -- mod ou relog trocou o onlineID) travaria "No seu colo" pra sempre: depois da janela vira Perdido (recall recupera).
        if pd.carried ~= nil then
            local tok = rec.data and rec.data.companionToken
            if tok ~= nil and CD.carriedTokenAnywhere and not CD.carriedTokenAnywhere(player, tok) then
                local nowMs = 0
                pcall(function() nowMs = getTimestampMs() end)
                rec.missingMs = rec.missingMs or nowMs
                if nowMs - rec.missingMs >= (CD.CARRIED_STALE_MS or 60000) then
                    pd.carried = nil
                    -- Sem snapshot no canil (vinculo pre-0.6.1), o proprio registro de colo tem o ModData completo: semeia.
                    if CD.kennelSeedFromData then CD.kennelSeedFromData(player, tok, rec.data) end
                    local marked = CD.markCompanionLost and CD.markCompanionLost(player, tok)
                    if marked then
                        CD.notifyOwner(player, "lost", { name = rec.data.name, breed = rec.data.breed })
                    end
                    pcall(function() player:transmitModData() end)
                end
            else
                rec.missingMs = nil
            end
        end
    end)
end

-- Um companion guardado num animal trailer e um IsoAnimal VIVO em vehicle:getAnimals() com seu ModData (bond)
-- intacto, mas removeAnimalFromTrailer (e o AnimalCommandPacket RemoveAnimalFromTrailer do MP) o reconstroi
-- via copyFrom, que DERRUBA getModData(), o cao volta pra nao-companion ("wild") e perde lealdade/skills/
-- owner. O onlineID sobrevive a reconstrucao (AnimalInstanceManager.add(newDog, oldOnlineID)), entao este tick 100%
-- server-side (sem arquivo client / sem comando de rede, a licao de dedicated-server do fix do carry) varre as
-- listas autoritativas dentro-do-trailer, captura o bond do objeto vivo, e re-anexa ao cao reconstruido
-- por id apos a remocao. Cobre AMBAS as variantes de remocao: "Remove" (dropado no mundo) e "Grab" (pra maos): o
-- cao reconstruido nas maos tambem e nao-companion, e restaurar o bond passa seu eventual drop pra recoverCarriedDogs.
local function recoverTraileredDogs()
    local cell = getCell()
    if not cell then return end
    local seen = {}
    -- Clones stale a ejetar (marca d'agua uid/gen): coletados durante a varredura e processados DEPOIS dela
    -- (removeAnimalFromTrailer muta vehicle.animals; mutar no meio do for quebraria o indice do ArrayList).
    local evict = {}

    -- (1) CAPTURA: a lista de animais de cada veiculo carregado e o armazem server-authoritative dos animais no trailer.
    -- getCell():getVehicles() retorna um Java HashSet (sem :get(i), "tried to call nil"); copia pra um
    -- ArrayList (um global Lua do PZ) pra iteracao indexada, o workaround padrao do PZ pra um Set.
    pcall(function()
        local set = cell:getVehicles()
        if not set then return end
        local vehicles = ArrayList.new()
        vehicles:addAll(set)
        for i = 0, vehicles:size() - 1 do
            local v = vehicles:get(i)
            local animals = nil
            pcall(function() animals = v:getAnimals() end)
            if animals then
                for j = 0, animals:size() - 1 do
                    local a = animals:get(j)
                    if a and CD.isDog(a) and CD.isCompanion(a) then
                        local oid = a:getOnlineID()
                        local d = CD.data(a)
                        -- Marca d'agua uid/gen: um clone stale entombado no trailer (o recall respawnou o canonico
                        -- enquanto o trailer estava descarregado) nunca aparece em cell:getAnimals(), entao os
                        -- reapers de cell nao o alcancam. Drena aqui: ejeta pelo caminho da engine + delete.
                        local staleClone, owner = false, nil
                        if d.uid ~= nil then
                            owner = CD.getOwnerPlayer(a)
                            if owner then
                                local wm = CD.playerData(owner).uidGen
                                if type(wm) == "table" and wm[d.uid] ~= nil and (d.gen or 0) < wm[d.uid] then staleClone = true end
                            end
                        end
                        if staleClone then
                            evict[#evict + 1] = { a = a, v = v, owner = owner }
                        else
                            local rec = trailerRecords[oid]
                            if not rec then
                                trailerRecords[oid] = { onlineID = oid, data = d, ownerName = d.ownerName, ownerKey = d.ownerKey }
                            else
                                rec.data = d
                                rec.ownerName = d.ownerName
                                rec.ownerKey = d.ownerKey
                                rec.retries = nil
                            end
                            seen[oid] = true
                            -- Companions parados estao fora da lista de animais da cell, entao tickCompanionInvincible nunca
                            -- os alcanca: re-afirma a imunidade aqui pra negligencia nao matar um cao guardado num trailer.
                            if not a:isInvincible() then pcall(function() a:setIsInvincible(true) end) end
                        end
                    end
                end
            end
        end
    end)

    -- (1b) DRENO: ejeta cada clone stale pela mesma sequencia server-side que a engine usa quando um player tira o
    -- animal (remove -> addToWorld -> broadcast, ver ISRemoveAnimalFromTrailer:complete), e deleta o cao reconstruido
    -- no MESMO tick (sem flash no server; o broadcast + delete convergem nos clients). Libera capacidade do trailer.
    for e = 1, #evict do
        local ev = evict[e]
        local oid = nil
        pcall(function() oid = ev.a:getOnlineID() end)
        pcall(function()
            local gone = ev.v:removeAnimalFromTrailer(ev.a)
            if gone and instanceof(gone, "IsoAnimal") then gone:addToWorld() end
            sendRemoveAnimalFromTrailer(ev.a, ev.owner, ev.v)
            if gone and instanceof(gone, "IsoAnimal") then
                reapDogState(gone:getOnlineID())
                gone:delete()
            end
        end)
        if oid ~= nil then trailerRecords[oid] = nil end
    end

    -- (2) RE-ANEXA: um cao registrado que nao esta mais em nenhum trailer acabou de ser removido, a engine o reconstruiu via
    -- copyFrom (bond foi-se) mas manteve o onlineID. Acha ele e restaura o bond.
    for oid, rec in pairs(trailerRecords) do
        if not seen[oid] then
            -- Guard stale leve: se o owner esta online e o token ativo dele nao bate mais com este bond
            -- (solto/substituido/re-domesticado), descarta o registro em vez de ressuscitar um companion fantasma.
            local stale = rec.data == nil
            if not stale then
                pcall(function()
                    local players = getOnlinePlayers()
                    if players and (rec.ownerKey or rec.ownerName) then
                        for i = 0, players:size() - 1 do
                            local p = players:get(i)
                            local match = false
                            if rec.ownerKey ~= nil and rec.ownerKey ~= "" then
                                match = CD.ownerKey(p) == rec.ownerKey
                            else
                                match = p:getUsername() == rec.ownerName
                            end
                            if p and match then
                                local pd = CD.playerData(p)
                                -- Pertencimento, nao igualdade de token-ativo: um cao passivo guardado num trailer e um
                                -- estado multi-dog normal. So fica stale quando o token saiu do conjunto de bond por inteiro.
                                if rec.data.companionToken ~= nil
                                   and not recordStillBonded(pd, rec.data.companionToken) then
                                    stale = true
                                end
                                -- Marca d'agua uid/gen: o bond capturado e de um clone stale (gen atras do canonico do
                                -- dono). Nao re-anexar: o cao reconstruido pela remocao manual e deletado abaixo.
                                if rec.data.uid ~= nil and type(pd.uidGen) == "table" and pd.uidGen[rec.data.uid] ~= nil
                                   and (rec.data.gen or 0) < pd.uidGen[rec.data.uid] then
                                    rec.staleClone = true
                                end
                            end
                        end
                    end
                end)
            end
            if stale then
                trailerRecords[oid] = nil
            else
                local dog = nil
                pcall(function() dog = getAnimal(oid) end)
                if dog and CD.isDog(dog) then
                    if rec.staleClone then
                        -- Clone stale removido do trailer por um player: deleta o cao reconstruido (bond-less) em vez
                        -- de ressuscitar o bond velho. Se ja e companion (algo re-anexou antes), os reapers de cell
                        -- resolvem pelo gen; so descarta o registro.
                        if not CD.isCompanion(dog) then
                            reapDogState(oid)
                            pcall(function() dog:delete() end)
                        end
                        trailerRecords[oid] = nil
                    elseif not CD.isCompanion(dog) then
                        -- O cao reconstruido sem ModData: re-anexa o bond capturado. Sem gate de getSquare(): isto
                        -- cobre tanto "dropado no mundo" (tem square) quanto "agarrado pras maos" (sem square); no
                        -- segundo caso restaurar companion=true passa pra recoverCarriedDogs.
                        pcall(function() dog:getModData().CompanionDogs = rec.data end)
                        local nd = CD.data(dog)
                        nd.mounted = nil
                        nd.stashed = nil
                        nd.diedNotified = nil
                        nd.ownerId = nil
                        pcall(function()
                            local owner = CD.getOwnerPlayer(dog)
                            if owner then
                                CD.restoreFromKennel(owner, dog)   -- marca d'agua contra record stale
                            end
                        end)
                        pcall(function() dog:setWild(false) end)
                        pcall(function() dog:setShootable(false) end)
                        pcall(function() dog:setIsInvincible(true) end)
                        CD.transmit(dog)
                        if CD.hasBag(dog) then pcall(function() CD.applyBagVisual(dog) end) end
                        trailerRecords[oid] = nil
                    else
                        -- Resolve pra um companion: se esta no mundo ja esta ok (descarta o registro); se nao tem
                        -- square ainda esta no trailer (uma falha transitoria de getVehicles()), mantem e espera.
                        local inWorld = false
                        pcall(function() inWorld = dog:getSquare() ~= nil end)
                        if inWorld then trailerRecords[oid] = nil end
                    end
                else
                    -- Nao resolvivel neste tick (chunk descarregado, ex.: trailer dirigido pra longe). Mantem e tenta
                    -- de novo; a engine recarrega o cao no trailer COM seu ModData do blob do veiculo, entao o proximo
                    -- scan o re-captura antes do player poder remover. Descarta apos algumas falhas pra limitar a tabela.
                    rec.retries = (rec.retries or 0) + 1
                    if rec.retries > (CD.TRAILER_RECOVER_MAX_RETRIES or 5) then
                        trailerRecords[oid] = nil
                    end
                end
            end
        end
    end
end

-- Extracao do recall (tela Meus Caes): tira o cao do TRAILER de verdade e o devolve vivo ao chamador, em vez de
-- recusar/respawnar (respawn duplicaria: o cao em trailer vive em vehicle:getAnimals(), invisivel aos reapers de
-- cell). Usa a MESMA sequencia server-side da engine de quando um player remove o animal (remove -> addToWorld ->
-- broadcast MP, ver ISRemoveAnimalFromTrailer:complete; em B42 o complete roda no server), e re-anexa o bond
-- capturado ANTES da remocao (o copyFrom da engine descarta o ModData), o mesmo re-attach de recoverTraileredDogs.
-- Requer posse do CHAMADOR (tokens sao sequencias POR JOGADOR: o mesmo numero pode existir pra donos diferentes) e
-- pula clone gen-stale (janela curta antes do dreno do scan: extrai-lo ressuscitaria o gemeo do canonico vivo).
-- CD.* (nao local): Companion.lua esta no teto de 200 locals do Kahlua. Retorna o cao re-vinculado, ou nil.
CD.trailerExtract = function(player, tok)
    if not player or tok == nil then return nil end
    local pd = CD.playerData(player)
    local found, foundVeh = nil, nil
    pcall(function()
        local set = getCell():getVehicles()
        if not set then return end
        local vehicles = ArrayList.new()
        vehicles:addAll(set)
        for i = 0, vehicles:size() - 1 do
            local v = vehicles:get(i)
            local animals = nil
            pcall(function() animals = v:getAnimals() end)
            if animals then
                for j = 0, animals:size() - 1 do
                    local a = animals:get(j)
                    if a and CD.isDog(a) and CD.isCompanion(a) and CD.isOwnedBy(a, player)
                       and CD.data(a).companionToken == tok then
                        local d = CD.data(a)
                        local wm = type(pd.uidGen) == "table" and d.uid ~= nil and pd.uidGen[d.uid] or nil
                        if wm == nil or (d.gen or 0) >= wm then
                            found, foundVeh = a, v
                            return
                        end
                    end
                end
            end
        end
    end)
    if not found or not foundVeh then return nil end
    -- Bond por VALOR antes da remocao; o objeto `found` morre no copyFrom da engine.
    local data = cdDeepCopy(CD.data(found))
    local oldOid = found:getOnlineID()
    local newDog = nil
    pcall(function()
        newDog = foundVeh:removeAnimalFromTrailer(found)
        if newDog and instanceof(newDog, "IsoAnimal") then newDog:addToWorld() end
        sendRemoveAnimalFromTrailer(found, player, foundVeh)
    end)
    if oldOid ~= nil then trailerRecords[oldOid] = nil end
    if not newDog or not instanceof(newDog, "IsoAnimal") then return nil end
    pcall(function() newDog:getModData().CompanionDogs = data end)
    local nd = CD.data(newDog)
    nd.mounted = nil
    nd.stashed = nil
    nd.diedNotified = nil
    nd.ownerId = nil
    pcall(function() CD.restoreFromKennel(player, newDog) end)
    pcall(function() newDog:setWild(false) end)
    pcall(function() newDog:setShootable(false) end)
    pcall(function() newDog:setIsInvincible(true) end)
    CD.transmit(newDog)
    if CD.hasBag(newDog) then pcall(function() CD.applyBagVisual(newDog) end) end
    return newDog
end

-- Detecta uma transicao genuina offline->online de cada owner e banca os minutos que ele ficou fora como uma
-- divida (consumida por applyOfflineDebt em updateUpkeep / advanceMountedNeeds) pra que o companion de um owner
-- desconectado nao acumule needs enquanto ele esta fora. A presenca e rastreada por PERTENCIMENTO A UM CONJUNTO ao
-- longo dos ticks, NAO por um limite de tempo: durante o fast-forward o owner permanece em getOnlinePlayers() todo
-- tick, entao nenhuma transicao dispara e o acumulo on-road / fast-forward fica intocado; a divida e bancada so
-- quando um id que estava ausente reaparece. pd.lastSeenMin / pd.offlineDebtMin vivem no ModData do player
-- (persistem com o save), entao a divida sobrevive aos varios ticks que um chunk pode levar pra recarregar o cao
-- apos reconectar, e tambem cobre o downtime de restart do server.
local onlinePresent = {}
local function reconcileOwnerPresence()
    local now = worldMinutes()
    local current = {}
    eachOnlinePlayer(function(player)
        local id = player:getOnlineID()
        current[id] = true
        local pd = CD.playerData(player)
        if not onlinePresent[id] and pd.token ~= nil and pd.lastSeenMin then
            local gap = now - pd.lastSeenMin
            if gap > 0 then pd.offlineDebtMin = (pd.offlineDebtMin or 0) + gap end
        end
        pd.lastSeenMin = now
    end)
    onlinePresent = current
end

-- (O cao ativo trazido por um teleport distante via bringActiveOnTeleport deixa o original pra tras como um gemeo
-- de mesmo uid. Ele e colapsado em processNearbyDogs no momento em que co-carrega com o respawn (a passada keeper-by-uid
-- de la), que e robusta atraves da fronteira RV-interior/mundo que o antigo keeper-watch nao conseguia atravessar.)

-- Traz o companion ativo pro owner apos um teleport detectado. (a) Ainda carregado: reposiciona ele atras do
-- owner (isto tambem o re-vincula na area carregada, evitando a virtualizacao iminente). (b) Ja descarregado:
-- respawna ele no owner a partir do snapshot vivo; o original deixado pra tras compartilha o uid do cao e e
-- colapsado por processNearbyDogs quando os dois co-carregam. Retorna true uma vez tratado pra que o loop de
-- retry possa parar; false significa "tenta de novo no proximo tick" (ex.: a square de destino do owner ainda nao
-- estava pronta). So o cao ATIVO em FOLLOW vem; caes em Stay/Guard/passivos ficam onde estao (inclusive um cao
-- parado dentro de um interior de RV).
local function attemptTeleportBring(player, pid, pd)
    -- (a) cao ainda carregado.
    local dog = CD.getCompanionAnimal(player)
    if dog and CD.isOwnedBy(dog, player) and CD.data(dog).companionToken == pd.token then
        -- STALE-GUARD: uma copia carregada cujo gen esta ATRAS da marca canonica (pd.uidGen[uid]) NAO e a instancia
        -- boa - e um clone velho (ex.: o cao que voce deixou parado no interior do RV; ao dar recall de fora, o recall
        -- respawnou a copia canonica no mundo com gen maior). Promove-la aqui invertia os gens e o reaper acabava
        -- ceifando a copia FOLLOW recallada, sobrando a parada. Entao NAO traz/promove: cai pra parte (c), que respawna
        -- a canonica do snapshot (FOLLOW, gen maior), e o reaper cell-wide ceifa esta copia stale. Ver companiondogs-rv-interior-dup.
        local u = CD.data(dog).uid
        local hw = (u and type(pd.uidGen) == "table") and pd.uidGen[u] or nil
        if u and hw and (CD.data(dog).gen or 0) < hw then
            -- copia stale: nao promove, cai pro respawn canonico da parte (c)
        else
            if CD.getState(dog) == CD.STATE_FOLLOW then
                -- square de destino ainda nao carregada (MP: server ainda fazendo streaming dela), segue tentando, nao desiste.
                if not teleportRecover(dog, player) then return false end
                local dd = CD.data(dog); dd.running = nil; dd.climbTries = nil
                CD.transmit(dog) -- teleportRecover so setou a posicao; empurra pros clients (MP) pro cao nao ficar na tile antiga.
            end
            -- Esta instancia carregada e a que esta com o owner, torna ela canonica pra qualquer orfao de mesmo uid ser ceifado.
            bumpCanonical(player, dog)
            -- Reap deterministico no MOMENTO da transicao: se o owner acabou de re-entrar no RV, o canonico foi
            -- teleportado pro interior onde a copia parada (stale) mora - e o unico instante em que as duas co-carregam.
            -- Roda so em janela de bring (raro), nao por-tick-por-player. Ver companiondogs-rv-interior-dup.
            if CD.reapClonesCellWide then CD.reapClonesCellWide() end
            return true
        end
    end
    -- (b) NOVO: o estado autoritativo de um cao DIRIGIDO e pd.stash, nao activeDogSnapshot (o snapshot para de
    -- atualizar no momento em que o owner monta, entao fica DESATUALIZADO durante toda a viagem, e e nil apos um
    -- relog-while-seated, onde o caminho antigo so-snapshot abaixo retornava true e ABANDONAVA o cao no RV). Respawna
    -- do stash primeiro. So quando NAO montado: um owner montado (o RV re-senta o motorista na saida) esta
    -- corretamente "dirigindo", entao o cao fica stashed e reaparece no dismount; respawna-lo no veiculo em movimento
    -- so pra re-stashar no proximo tick deixaria um cao vivo, nao rastreado ao lado do veiculo. Gate de FOLLOW pra que
    -- um cao comandado Stay/Guard enquanto dirige seja deixado pra tras (espelha o gate de snapshot abaixo); guards de
    -- carry/live pra que isto nunca crie um gemeo.
    local rec = pd.stash
    if rec then
        if CD.isMounted(player) then return true end -- mantem stashed; mountClear/dismount respawna ele
        local stok = rec.data and rec.data.companionToken
        local sstate = (rec.data and rec.data.state) or CD.STATE_FOLLOW
        if recordStillBonded(pd, stok) and sstate == CD.STATE_FOLLOW
           and not carryingDogWithToken(player, stok) and not liveOwnedDogWithToken(player, stok) then
            local fresh = respawnCompanion(nil, player, rec)
            if not fresh then return false end -- square do owner nil (MP streaming), retry, mantem o stash
            local fd = CD.data(fresh); fd.running = nil; fd.climbTries = nil
            -- Cunhagem defensiva de uid (espelha a parte c): um cao stashed antes de qualquer tick not-mounted preencher
            -- seu uid teria rec.data.uid=nil, entao bumpCanonical (que faz early-return em uid nil) nao conseguiria
            -- carimbar a gen e o gen-reaper nao conseguiria colapsar um gemeo abandonado. Cunha aqui pro carimbo pegar.
            if not fd.uid then fd.uid = tostring(getTimestampMs()) .. "-" .. tostring(ZombRand(0, 2147483647)) end
            CD.clearStashRecord(player)
            bumpCanonical(player, fresh)
            return true
        end
        return true -- token foi-se / nao FOLLOW / carregado / ja vivo, nada pra trazer do stash
    end

    -- (c) cao ja descarregado e nao stashed (entrada a pe no RV / teleport de admin), respawna do snapshot.
    -- snap.data e um deepCopy atualizado a cada COMPANION_TICK_INTERVAL (NAO uma referencia viva). Dois guards de
    -- desatualizacao: seu STATE e mantido atual no instante em que um Stay/Guard pousa (CD.stampActiveSnapshotState),
    -- entao um cao parado dentro de um RV e deixado pra tras; e sua IDENTIDADE pode atrasar um Select (o snapshot ainda
    -- descreve o cao ATIVO ANTIGO por ~20 ticks), entao exige companionToken == pd.token antes de respawnar, nunca
    -- ressuscita um cao desatualizado que nao e mais o ativo.
    local snap = activeDogSnapshot[pid]
    local snapState = snap and snap.data and (snap.data.state or CD.STATE_FOLLOW)
    if not snap or snap.data.companionToken ~= pd.token or snapState ~= CD.STATE_FOLLOW then return true end
    -- Espelha o mount guard da parte (b): um owner re-sentado (re-seat na saida do RV) NAO deve ter um cao respawnado
    -- do snapshot no veiculo em movimento. rvexit agora semeia pd.stash (entao a parte b cuida dele), entao isto
    -- normalmente e ignorado; este e o belt-and-suspenders pra qualquer tick em que pd.stash nao foi semeado mas o
    -- owner esta montado (o cao reaparece no dismount).
    if CD.isMounted(player) then return true end
    -- respawn falha enquanto a square de destino do owner ainda esta em streaming (MP), segue tentando.
    local fresh = respawnCompanion(nil, player, snap)
    if not fresh then return false end
    local fd = CD.data(fresh); fd.running = nil; fd.climbTries = nil
    -- o uid normalmente entra junto nos dados do snapshot; cunha defensivamente pra que o gen reaper
    -- (processNearbyDogs) nunca chaveie em nil quando o gemeo original abandonado carregar depois.
    if not fd.uid then
        fd.uid = tostring(getTimestampMs()) .. "-" .. tostring(ZombRand(0, 2147483647))
    end
    -- Este respawn e a encarnacao canonica; o original deixado pra tras mantem uma gen mais antiga e e ceifado na carga.
    bumpCanonical(player, fresh)
    -- Reap deterministico: se o respawn caiu dentro do interior do RV (owner re-entrou a pe), a copia parada co-carrega
    -- aqui e e ceifada de imediato em vez de esperar o disparo throttled do reaper (que vinha errando a janela curta).
    if CD.reapClonesCellWide then CD.reapClonesCellWide() end
    -- snapshot deixado de proposito no lugar (uma copia profunda dos dados do cao) pra que um segundo teleport rapido
    -- tambem recupere; updateCompanion o atualiza, e pd.token o controla assim que o cao e liberado.
    return true
end

-- Detector de teleport do owner por tick. Compara a tile do owner com o tick anterior; um salto maior que o scan de
-- follow (~28 tiles) e um teleport de admin/mapa (nao existe evento de teleport em Lua, so o delta de posicao). Arma
-- uma janela curta de retry e traz o cao (o retry cobre o chunk de destino levando um tick ou dois pra terminar de
-- carregar). Pula owners montados/em veiculo (esses caminhos cuidam do cao) e o primeiro avistamento (so baseline).
local function bringActiveOnTeleport(player)
    local pid = player:getOnlineID()
    local px, py = math.floor(player:getX()), math.floor(player:getY())
    local prev = lastOwnerTile[pid]
    lastOwnerTile[pid] = { x = px, y = py }
    local pd = CD.playerData(player)

    -- O cao ativo esta nas maos do owner (carregado como item), nunca traz/respawna de um snapshot aqui: criaria uma
    -- duplicata ao lado do cao carregado. Checa o inventario VIVO, nao so a flag throttled pd.carried: pd.carried e
    -- setada so no tick pesado (a cada COMPANION_TICK_INTERVAL) ou pela rede, mas isto roda TODO tick e a janela de
    -- rvExit/teleport respawna do snapshot todo tick, entao o intervalo antes de pd.carried ser setada respawnaria um
    -- gemeo de um cao recem-pego (o exato relato "spawna do meu lado enquanto esta no inventario"). Preciso por token
    -- pra que carregar um cao passivo DIFERENTE nao suprima um bring legitimo do cao ativo.
    -- (lastOwnerTile foi atualizada acima, entao nenhum salto falso dispara no momento em que o carry termina.)
    local activeCarried = (pd.carried and pd.carried.data and pd.carried.data.companionToken == pd.token)
        or carryingDogWithToken(player, pd.token)
    if activeCarried then rvExitBring[pid] = nil; pendingTeleportBring[pid] = nil; return end

    -- Saindo de uma cell de Project RV Interior (tile anterior dentro da faixa distante, agora fora). O mod RE-SENTA o
    -- motorista na saida (RVFunction.ReturnPlayerToSeat), o que re-monta o owner. Arma uma janela de retry propria (um
    -- re-seat rapido nao consegue cortar curto) e roda attemptTeleportBring: enquanto o owner esta RE-MONTADO ele MANTEM
    -- o cao stashed (o isMounted guard da parte b) pra que reapareca no dismount final via mountClear, sem respawn no
    -- veiculo em movimento; se o owner esta des-montado quando isto roda (a breve janela pre-re-seat, ou um cao de
    -- interior vivo ainda carregado) reposiciona/respawna ele no owner. Copias de interior desatualizadas sao ceifadas
    -- na carga pelo gen reaper.
    -- O > estrito casa com o detector de borda do client (CompanionDogs_RVIntegration.lua) e o CheckIfInRV do mod de RV,
    -- entao o fallback do server e o sinal deterministico do client concordam na tile de fronteira exata x==MINX/y==MINY.
    local minx, miny = CD.RV_INTERIOR_MIN_X or 22500, CD.RV_INTERIOR_MIN_Y or 12000
    if prev and prev.x > minx and prev.y > miny and not (px > minx and py > miny) then
        rvExitBring[pid] = CD.TELEPORT_BRING_TRIES or 300
    end
    if rvExitBring[pid] then
        if pd.token == nil or attemptTeleportBring(player, pid, pd) then
            rvExitBring[pid] = nil
        else
            rvExitBring[pid] = rvExitBring[pid] - 1
            if rvExitBring[pid] <= 0 then rvExitBring[pid] = nil end
        end
        return
    end

    if CD.isMounted(player) then pendingTeleportBring[pid] = nil; return end
    local inVehicle = false
    pcall(function() inVehicle = player:getVehicle() ~= nil end)
    if inVehicle then pendingTeleportBring[pid] = nil; return end
    -- Um cao stashed pertence ao caminho de mount (dirigindo, ou entrando num interior de RV pelo banco do motorista).
    -- Deixa esse caminho fazer o respawn unico; um teleport bring aqui spawnaria uma segunda instancia de um snapshot desatualizado.
    if pd.stash ~= nil then pendingTeleportBring[pid] = nil; return end
    if prev then
        local dx, dy = px - prev.x, py - prev.y
        local jump = CD.TELEPORT_JUMP_MIN or 6
        if dx * dx + dy * dy > jump * jump then
            pendingTeleportBring[pid] = CD.TELEPORT_BRING_TRIES or 20
        end
    end
    local tries = pendingTeleportBring[pid]
    if not tries then return end
    if pd.token == nil then pendingTeleportBring[pid] = nil; return end
    if attemptTeleportBring(player, pid, pd) then
        pendingTeleportBring[pid] = nil
    elseif tries <= 1 then
        pendingTeleportBring[pid] = nil
    else
        pendingTeleportBring[pid] = tries - 1
    end
end

-- Integracao deterministica com Project RV. Em vez de inferir a transicao pro RV-interior por um delta de posicao do
-- lado do server (que atrasa o vehicle:exit + far-teleport + re-seat client-driven do mod de RV: em MP a square/posicao
-- do server ficam desatualizadas por segundos, entao o cao "as vezes nao vinha junto"), o client
-- (CompanionDogs_RVIntegration.lua) detecta a BORDA do proprio predicado "dentro" do mod de RV (getX>RV_INTERIOR_MIN_X
-- e getY>RV_INTERIOR_MIN_Y) e dispara estes. Eles so ARMAM as janelas de bring existentes e comprovadas, sem nova
-- logica de respawn. A deteccao de faixa/salto do lado do server em bringActiveOnTeleport fica como fallback; armar a
-- mesma janela duas vezes e idempotente (attemptTeleportBring reposiciona o cao carregado em vez de duplicar, e o gen
-- reaper colapsa qualquer gemeo desatualizado). O skip de pd.carried em bringActiveOnTeleport ainda protege ambos contra um cao nas maos.
CD.Server.rvexit = function(player)
    if not player then return end
    local pd = CD.playerData(player)
    -- Um cao que te SEGUIU dentro do RV e um animal vivo a pe SEM pd.stash (foi des-stashed quando trazido pra dentro).
    -- Na saida ele virtualiza no momento em que o chunk do interior descarrega, e a unica recuperacao restante (respawn
    -- por snapshot, attemptTeleportBring parte c) NAO conhece mount e nao tem retry de square-nil de MP que sobreviva ao
    -- re-seat: o cao e respawnado no veiculo re-sentado em movimento (escondido) ou abandonado no interior ("fica preso
    -- dentro", so MP). Em vez disso, roteia ele pro caminho de stash COMPROVADO: enquanto des-montado, a parte (b)
    -- stash-first o respawna no owner todo tick ao longo da janela de square-nil do MP; enquanto re-sentado (montado) ele
    -- fica stashed e recoverStashedDogs o respawna no dismount real.
    -- (1) Captura primaria: a borda do client dispara logo apos o teleport do GetOutFromRV, o unico momento em que o cao
    -- frequentemente ainda esta carregado (em MP a posicao atrasada do owner no server mantem o chunk do interior
    -- carregado um pouco mais). Snapshota o cao VIVO em pd.stash, depois o deleta pra que nao persista como gemeo
    -- virtualizado. So deleta uma vez que esteja escrito com seguranca.
    local sawParkedLive = false
    if pd.token and not pd.stash then
        local dog = CD.getCompanionAnimal(player)
        if dog and CD.isOwnedBy(dog, player) and CD.data(dog).companionToken == pd.token then
            if CD.getState(dog) == CD.STATE_FOLLOW then
                CD.writeStashRecord(dog, player)
                if pd.stash then
                    CD.data(dog).stashed = true -- simetria com stashMounted (nao lido aqui; o cao nao esta em mountedDogs)
                    pcall(function() dog:stopAllMovementNow(); dog:delete() end)
                end
            else
                sawParkedLive = true -- cao vivo esta parado (Stay/Guard), deixa no interior, nao semeia de um snapshot
            end
        end
    end
    -- (2) Fallback ja-virtualizado (MP: o server descarregou o chunk do interior antes deste comando ser processado,
    -- entao a captura viva acima nao achou nada). Semeia pd.stash do snapshot vivo (atualizado enquanto o cao seguia
    -- dentro; CD.stampActiveSnapshotState mantem seu state preciso no instante em que um Stay/Guard pousa, entao nao pode ser um
    -- FOLLOW desatualizado) pra que o mesmo caminho mount-aware comprovado cuide dele em vez da parte (c) cega a mount.
    -- Sem cao vivo pra deletar; a copia virtualizada abandonada e colapsada pelo gen reaper na re-entrada
    -- (recoverStashedDogs agora carimba o respawn como canonico). Pulado se o cao vivo acabou de ser visto em Stay/Guard
    -- (belt-and-suspenders contra um snapshot desatualizado).
    if pd.token and not pd.stash and not sawParkedLive then
        local snap = activeDogSnapshot[player:getOnlineID()]
        local sstate = snap and snap.data and (snap.data.state or CD.STATE_FOLLOW)
        -- companionToken == pd.token: ignora um snapshot cuja IDENTIDADE esta desatualizada apos um Select (ainda
        -- descreve o cao ATIVO ANTIGO por ~20 ticks), pra que nunca semeie o stash de / arraste pra fora o cao errado (rebaixado).
        if snap and snap.data.companionToken == pd.token and sstate == CD.STATE_FOLLOW then
            local sd = cdDeepCopy(snap.data)
            if not sd.uid then sd.uid = tostring(getTimestampMs()) .. "-" .. tostring(ZombRand(0, 2147483647)) end
            pd.stash = { type = snap.type, female = snap.female, age = snap.age, hp = snap.hp,
                         hunger = snap.hunger, thirst = snap.thirst, lastNeedMin = worldMinutes(), data = sd }
            pcall(function() player:transmitModData() end)
        end
    end
    rvExitBring[player:getOnlineID()] = CD.TELEPORT_BRING_TRIES or 300
end
CD.Server.rventer = function(player)
    if not player then return end
    -- Entrada a pe no RV: arma o teleport bring generico (reposiciona o cao vivo / respawna do snapshot na tile de
    -- interior do owner). RV sentado/dirigido: o cao esta em pd.stash e recoverStashedDogs (agora carry-aware, com seu
    -- proprio retry de MP-streaming) o respawna dentro; pendingTeleportBring faz early-return em pd.stash, entao isto
    -- e um no-op inofensivo nesse caso.
    pendingTeleportBring[player:getOnlineID()] = CD.TELEPORT_BRING_TRIES or 20
end

-- Auto-cura de um slot de companion fantasma. Um companion que morre por um caminho da engine que pula a permadeath
-- (um atropelamento na janela de respawn pre-invencivel num save pre-fix, ou qualquer morte futura nao prevista) deixa
-- seu token em pd.companions pra sempre: o corpo sai de getAnimals(), entao nada nunca limpa o slot, o mapa do mundo
-- mantem uma pata congelada e o limite MaxCompanions fica cheio (o reporter nao conseguia mais domesticar um cao novo
-- depois do morto). Limpa esse token SOMENTE quando ele esta comprovadamente perdido: o owner esta dentro do raio de
-- chunk-load do ultimo anchor vivo do token e NENHUM cao vivo com esse token esta carregado em lugar nenhum da cell,
-- sustentado alem de um grace curto (cobre os segundos que um chunk de MP leva pra fazer streaming). Um cao apenas
-- parado longe (Stay/Guard) nunca dispara isto: o owner nao esta perto do seu anchor, e no momento em que ele volta o
-- cao carrega vivo e reseta o timer bem dentro do grace. liveOwnedDogWithToken e cell-wide, entao um cao parado em
-- qualquer lugar da cell carregada conta como vivo; combinado com o gate near-anchor (que garante que o chunk do anchor
-- esta carregado), "ausente" significa perdido.
local function reapPhantomCompanions(player)
    local pd = CD.playerData(player)
    if type(pd.companions) ~= "table" then return end
    -- Confia em "nenhum cao carregado = perdido" so depois que a square do proprio owner esta carregada: logo apos um
    -- teleport/relog ela e nil por segundos enquanto o chunk de destino faz streaming, e concluir "perdido" ai seria um falso positivo.
    local osq = nil
    pcall(function() osq = player:getCurrentSquare() end)
    if not osq then return end
    local cell = getCell()
    if not cell then return end
    pd.tokenAnchor = pd.tokenAnchor or {}
    -- Chaveado pela chave ESTAVEL do dono: o onlineID e o indice do slot de conexao, entao quem entra depois herdava
    -- os timers de graca de quem saiu.
    local pid = CD.ownerKey(player)
    phantomLostSince[pid] = phantomLostSince[pid] or {}
    local lost = phantomLostSince[pid]
    -- Semente de recuperacao legacy/SP: um slot travado pre-fix nunca foi processado vivo de novo, entao nao tem anchor
    -- de server. Adota a ultima posicao conhecida do marcador de mapa do client (pd.dogPositions, presente em
    -- SP/coop-host; um server dedicado puro pode nao ter, esses raros slots pre-fix precisam de um clear de admin). Daqui
    -- pra frente o anchor vivo e canonico.
    if type(pd.dogPositions) == "table" then
        for t, p in pairs(pd.dogPositions) do
            if pd.companions[t] and not pd.tokenAnchor[t] and p and p.x and p.y then
                pd.tokenAnchor[t] = { x = math.floor(p.x), y = math.floor(p.y), z = math.floor(p.z or 0) }
            end
        end
    end
    local now = worldMinutes()
    local px, py = math.floor(player:getX()), math.floor(player:getY())
    local R = (CD.TELEPORT_DIST or 24) + 4
    local grace = CD.PHANTOM_LOST_GRACE_MIN or 3
    local changed = false
    -- Snapshota o conjunto de tokens primeiro; clearCompanionSlot muta pd.companions.
    local tokens = {}
    for t in pairs(pd.companions) do tokens[#tokens + 1] = t end
    for _, t in ipairs(tokens) do
        local alive = liveOwnedDogWithToken(player, t) ~= nil
        if not alive then
            -- Contabilizado por outro subsistema (stash de direcao / carregado nas maos / guardado no trailer /
            -- guardado fora do mundo pelo despawn de dono-offline), nao perdido.
            local stok = pd.stash and pd.stash.data and pd.stash.data.companionToken
            local ctok = pd.carried and pd.carried.data and pd.carried.data.companionToken
            if t == stok or t == ctok then
                alive = true
            elseif CD.offlineStashHas and CD.offlineStashHas(player, t) then
                alive = true
            elseif CD.tokenTrailered and CD.tokenTrailered(player, t) then
                alive = true
            end
        end
        if alive then
            lost[t] = nil
        else
            local anc = pd.tokenAnchor[t]
            -- Exige que a PROPRIA square do anchor esteja carregada antes de confiar em "nenhum cao aqui": um chunk
            -- ainda nao streamado (MP, logo apos um teleport) le como vazio independente do grace dependente do tamanho
            -- do dia. Com a square carregada e liveOwnedDogWithToken (cell-wide) ainda nil, o cao realmente se foi, nao so nao-streamado.
            local ancLoaded = false
            if anc then pcall(function() ancLoaded = cell:getGridSquare(anc.x, anc.y, anc.z) ~= nil end) end
            if anc and ancLoaded and math.abs(px - anc.x) <= R and math.abs(py - anc.y) <= R then
                lost[t] = lost[t] or now
                if (now - lost[t]) >= grace then
                    local nm = (type(pd.dogPositions) == "table" and pd.dogPositions[t] and pd.dogPositions[t].name)
                        or (t == pd.token and pd.name) or nil
                    -- Com snapshot no canil o cao vira PERDIDO (recuperavel pelo Trazer da tela Meus Caes) em vez de ter o
                    -- vinculo limpo; anchor/pd.dogPositions ficam como "visto por ultimo". Sem snapshot (save antigo): limpeza legada.
                    local marked = CD.markCompanionLost and CD.markCompanionLost(player, t)
                    if marked ~= nil then
                        if marked then
                            CD.notifyOwner(player, "lost", { name = nm, breed = pd.kennel[t] and pd.kennel[t].breed })
                            changed = true
                        end
                    else
                        clearCompanionSlot(player, t, nm, nil, nil)
                        pd.tokenAnchor[t] = nil
                        if type(pd.dogPositions) == "table" then pd.dogPositions[t] = nil end
                        changed = true
                    end
                    lost[t] = nil
                end
            else
                -- Owner nao esta perto do anchor (ou nao ha nenhum ainda): um cao parado longe vive aqui, nao da pra concluir. Reseta.
                lost[t] = nil
            end
        end
    end
    if changed then pcall(function() player:transmitModData() end) end
end

-- Reaper de clones por-uid CELL-WIDE: varre a CELULA INTEIRA (nao so os caes perto do dono, como o keeperByUid do
-- present-loop) e remove copias duplicadas do MESMO cao. uid e unico por cao (o copyFrom da engine o copia, entao clone
-- e original compartilham uid); gen sobe SO no canonico (bumpCanonical). Assim o clone abandonado do RV (mem
-- companiondogs-rv-interior-dup) e reapado assim que o chunk dele carrega em QUALQUER lugar, sem exigir co-load colado no
-- dono. CD.* (nao `local function`) por causa do teto de 200 locals do chunk (ver [[pz-kahlua-200-locals-limit]]). Roda
-- so server/SP (companionTick ja e gated por `not isClient()`; o guard aqui e cinto-e-suspensorio).
CD.reapClonesCellWide = function()
    if isClient() then return end
    local cell = getCell()
    if not cell then return end
    local list = nil
    pcall(function() list = cell:getAnimals() end)
    if not list then return end
    -- Deleta um clone com seguranca: reap de estado + delete. O slot de companions so e solto quando o token e
    -- orfao SO do clone (legado re-mintado) -- keeperTok e o token do keeper carregado (nil no backstop de grupo-1,
    -- onde o canonico com o MESMO token existe em outro lugar e limpar o orfanaria; ver CD.cloneSlotShouldClear).
    local function reapDup(owner, a, why, keeperTok)
        if owner then
            local pd = CD.playerData(owner)
            local vt = CD.data(a).companionToken
            if CD.cloneSlotShouldClear and CD.cloneSlotShouldClear(pd, vt, keeperTok) and pd.companions ~= nil then pd.companions[vt] = nil end
        end
        reapDogState(a:getOnlineID())
        pcall(function() a:delete() end)
    end
    -- Agrupa por uid os companions carregados (uid unico por cao -> caes distintos nunca colidem).
    local byUid = {}
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        local ok = false
        pcall(function() ok = a and CD.isDog(a) and CD.isCompanion(a) and not a:isDead() end)
        if ok then
            local u = CD.data(a).uid
            if u ~= nil then
                local g = byUid[u]; if not g then g = {}; byUid[u] = g end
                g[#g + 1] = a
            end
        end
    end
    for u, dogs in pairs(byUid) do
        local owner = CD.getOwnerPlayer(dogs[1])   -- todo o grupo e o mesmo cao -> mesmo dono
        local ptoken = owner and CD.playerData(owner).token or nil
        if #dogs > 1 then
            -- Keeper = maior gen; empate -> o que bate com o token ativo do dono; senao o primeiro. Deleta o resto.
            local keeper = dogs[1]
            for k = 2, #dogs do
                local a = dogs[k]
                local ag = CD.data(a).gen or 0
                local kg = CD.data(keeper).gen or 0
                if ag > kg or (ag == kg and ptoken ~= nil and CD.data(a).companionToken == ptoken and CD.data(keeper).companionToken ~= ptoken) then
                    keeper = a
                end
            end
            for k = 1, #dogs do
                if dogs[k] ~= keeper then reapDup(owner, dogs[k], "dup-cell-wide keeper-perdeu", CD.data(keeper).companionToken) end
            end
        elseif owner then
            -- Grupo de 1: backstop pro clone velho solto quando o canonico ainda nao carregou. Deleta se ficou pra tras
            -- da marca d'agua canonica do dono (pd.uidGen[uid], subida por bumpCanonical no trazer/recall/respawn).
            local pd = CD.playerData(owner)
            local canonGen = type(pd.uidGen) == "table" and pd.uidGen[u] or nil
            if canonGen ~= nil and (CD.data(dogs[1]).gen or 0) < canonGen then
                reapDup(owner, dogs[1], "backstop gen<" .. tostring(canonGen), nil)
            end
        end
    end
end

-- REPARO de posse (saves ja corrompidos pela perna ownerId do isOwnedBy, ver CD.isOwnedBy). O estrago gravado nao se
-- desfaz sozinho: o canil GLOBAL tem o mesmo cao (mesmo uid) registrado sob dois donos, e o pd do intruso lista o
-- token alheio. Ponto a favor: o cao VIVO continua sabendo quem e o dono verdadeiro (o roubo passivo por espelhamento
-- nunca reescreveu d.ownerKey; so um recall reescrevia, e esse caso e irrecuperavel por codigo).
--
-- Verdade por uid, em ordem de confianca:
--   1. cao vivo carregado com esse uid -> d.ownerKey dele;
--   2. entrada do canil cujo snapshot carimba o PROPRIO bucket (snap.ownerKey == chave do bucket).
-- Com a verdade em maos: derruba o uid de todo bucket alheio e limpa o espelho por-personagem do intruso. Sem verdade
-- (cao descarregado e snapshots velhos sem ownerKey) nao chuta: espera o cao carregar, quando o espelho carimba.
-- Idempotente e barato em regime estavel (nao escreve nada quando nao ha divergencia). CD.* (teto de 200 locals).
CD.repairOwnership = function()
    if isClient() then return end
    if not (CD.kennelGlobalAll and CD.kennelGlobalDrop) then return end
    -- Throttle: varre o canil global inteiro, entao 1x por minuto de jogo basta (o dano ja esta parado pelo isOwnedBy;
    -- isto e so a faxina). Sem isto rodaria a cada COMPANION_TICK_INTERVAL.
    local nowMin = worldMinutes()
    if CD._repairMin ~= nil and (nowMin - CD._repairMin) < 1 then return end
    CD._repairMin = nowMin
    local s = CD.kennelGlobalAll()
    if type(s) ~= "table" then return end

    -- Dono verdadeiro por uid, a partir dos caes VIVOS. Tambem expurga o d.ownerId (id de sessao) que envenenava a posse.
    local truth = {}
    local cell = getCell()
    if cell then
        local list = nil
        pcall(function() list = cell:getAnimals() end)
        if list then
            for i = 0, list:size() - 1 do
                local a = list:get(i)
                local ok = false
                pcall(function() ok = a and CD.isDog(a) and CD.isCompanion(a) end)
                if ok then
                    local d = CD.data(a)
                    if d.ownerId ~= nil then d.ownerId = nil; CD.transmit(a) end
                    -- Carimbo de ownerKey feito pelo INTRUSO num cao de save antigo (sem ownerKey): a migracao de
                    -- processNearbyDogs escreve SO a ownerKey, nunca o ownerName. Em MP os dois sao o mesmo login pra
                    -- qualquer cao legitimo, entao divergencia = carimbo errado, e o ownerName sobreviveu como
                    -- testemunha do dono real. Restaura. (So MP: em SP a ownerKey e o Steam ID e diverge do nome do
                    -- personagem por natureza.)
                    if isServer() and d.ownerKey ~= nil and d.ownerKey ~= "" and d.ownerName ~= nil and d.ownerName ~= ""
                       and d.ownerKey ~= d.ownerName then
                        print(string.format("[CD-FIX] carimbo de dono errado: uid=%s ownerKey=%s -> %s (ownerName)",
                            tostring(d.uid), tostring(d.ownerKey), tostring(d.ownerName)))
                        d.ownerKey = d.ownerName
                        CD.transmit(a)
                    end
                    if d.uid ~= nil and d.ownerKey ~= nil and d.ownerKey ~= "" then truth[d.uid] = d.ownerKey end
                end
            end
        end
    end
    -- Indexa o canil global por uid e completa a verdade com os snapshots auto-carimbados.
    local byUid = {}
    for key, recs in pairs(s) do
        if type(recs) == "table" then
            for tok, snap in pairs(recs) do
                if type(snap) == "table" and snap.uid ~= nil then
                    local g = byUid[snap.uid]
                    if not g then g = {}; byUid[snap.uid] = g end
                    g[#g + 1] = { key = key, tok = tok }
                    if truth[snap.uid] == nil and snap.ownerKey ~= nil and snap.ownerKey == key then
                        truth[snap.uid] = key
                    end
                end
            end
        end
    end
    -- Derruba o uid de todo bucket que nao e o do dono verdadeiro (inclusive quando a entrada roubada e a UNICA:
    -- o dono real re-espelha o cao no proximo load perto dele, entao nao ha o que preservar no bucket errado).
    local stolen = {}
    for uid, entries in pairs(byUid) do
        local owner = truth[uid]
        if owner ~= nil then
            for i = 1, #entries do
                local e = entries[i]
                if e.key ~= owner then
                    print(string.format("[CD-FIX] canil roubado: uid=%s tirado de %s (token %s), dono real=%s",
                        tostring(uid), tostring(e.key), tostring(e.tok), tostring(owner)))
                    CD.kennelGlobalDrop(e.key, e.tok)
                    stolen[e.key] = stolen[e.key] or {}
                    stolen[e.key][e.tok] = uid
                end
            end
        end
    end
    -- Limpa o espelho por-personagem do intruso ONLINE (o offline e limpo quando reconectar: o passe roda a cada tick
    -- pesado e o pd dele so existe enquanto online).
    eachOnlinePlayer(function(player)
        local key = CD.ownerKey(player)
        local pd = CD.playerData(player)
        local drops = stolen[key]
        -- Alem do que acabou de cair do global, varre o proprio pd: uma entrada cujo snapshot aponta OUTRO dono, ou
        -- cujo uid pertence a outro dono, nao e dele.
        if type(pd.kennel) == "table" then
            for tok, snap in pairs(pd.kennel) do
                if type(snap) == "table" then
                    local bad = (snap.ownerKey ~= nil and snap.ownerKey ~= "" and snap.ownerKey ~= key)
                        or (snap.uid ~= nil and truth[snap.uid] ~= nil and truth[snap.uid] ~= key)
                    if bad then
                        drops = drops or {}
                        drops[tok] = snap.uid
                    end
                end
            end
        end
        if not drops then return end
        local changed = false
        for tok, uid in pairs(drops) do
            print(string.format("[CD-FIX] espelho roubado: %s perde o token %s (uid=%s)",
                tostring(key), tostring(tok), tostring(uid)))
            if type(pd.kennel) == "table" then pd.kennel[tok] = nil end
            if type(pd.companions) == "table" then pd.companions[tok] = nil end
            if type(pd.tokenAnchor) == "table" then pd.tokenAnchor[tok] = nil end
            if type(pd.dogPositions) == "table" then pd.dogPositions[tok] = nil end
            if pd.token == tok then pd.token = nil; pd.name = nil end
            changed = true
        end
        if changed then pcall(function() player:transmitModData() end) end
    end)
end

-- Run-to-tile protegido pro combat maintainer: pula reemitir o path enquanto o cao ainda avanca rumo a MESMA tile, e
-- re-afirma forcePathfind todo tick pra que o node mover nunca caia pra root motion sem-path (o over-run de alvo
-- desatualizado). pathFn emite o pathToCharacter(zombie) / pathToLocation(tile) de fato. O 0.02 aqui e o throttle de
-- combate legacy (um zumbi em movimento muda a tile-alvo constantemente, entao isto raramente importa).
local function combatDriveTile(animal, d, otx, oty, otz, pathFn)
    pcall(function()
        animal:setVariable("animalSpeed", CD.runAnimSpeed())
        animal:setVariable("animalRunning", true)
    end)
    local px, py = animal:getX(), animal:getY()
    local moved = d.combatLastX and (math.abs(px - d.combatLastX) + math.abs(py - d.combatLastY)) or 999
    d.combatLastX, d.combatLastY = px, py
    local pt = d.combatPathTile
    if pt and pt.x == otx and pt.y == oty and pt.z == otz and moved >= 0.02 then
        forcePathfind(animal)
        return
    end
    d.combatPathTile = { x = otx, y = oty, z = otz }
    letMove(animal)
    pcall(pathFn)
    forcePathfind(animal)
end

-- Suaviza a POSICAO de combate entre as passadas pesadas de 20 ticks (as DECISOES de strike/scan/retreat ficam la).
-- Pra um cao que se aproxima, re-conduz rumo a posicao FRESCA do zumbi a cada tick leve e planta no momento em que
-- esta no alcance de strike (pra parar JUNTO ao zumbi em vez de deslizar adiante por root motion desatualizada); pra um
-- cao em retreat, re-conduz rumo a tile de retreat armazenada. Nunca golpeia (o loop pesado aplica os golpes no HIT_COOLDOWN_MIN).
local function maintainCombat()
    for id, animal in pairs(combatMaintainDogs) do
        local keep = false
        pcall(function()
            if not animal:isExistInTheWorld() then return end
            local owner = CD.getOwnerPlayer(animal)
            if not owner then return end
            keep = true
            local d = CD.data(animal)
            if d.fenceHop then return end   -- no meio de um vault de cerca: tickFenceHops conduz o glide; nao brigar com ele (keep segue true)
            if isServer() and landGlide[id] then return end   -- pos-pouso no servidor: o land-glide de combate conduz ate o zumbi; nao brigar (SP nao defere, sobrepoe o glide de dono)
            -- Rede de seguranca "nunca travar na cerca": em combate o cao NAO pula cerca (canClimbFences=false), so
            -- contorna, entao um ClimbFence setado pela engine (colisao frontal numa aresta pulavel) e o bug de "correr no
            -- lugar" sem saida (o watchdog de ClimbFence do followOwner nao roda em combate). Limpa todo tick de combate.
            pcall(function()
                if animal:getVariableBoolean("ClimbFence") then CD.clearClimbVars(animal) end
            end)
            if d.combatMode == "retreat" then
                local rt = d.retreatTile
                if rt then
                    combatDriveTile(animal, d, rt.x, rt.y, rt.z, function() animal:pathToLocation(rt.x, rt.y, rt.z) end)
                end
                return
            end
            -- approach / strike: re-conduz rumo ao alvo vivo, mas so quando ele ainda e uma ameaca valida e alcancavel.
            local z = combatTarget[id]
            local valid = false
            pcall(function()
                valid = z ~= nil and not z:isDead() and z:getSquare() ~= nil
                    and math.floor(z:getZ()) == math.floor(animal:getZ())
            end)
            if not valid then pcall(function() letMove(animal) end); return end   -- alvo morreu mid-steer: reabilita mov. (evita freeze curto)
            pcall(function() animal:faceThisObject(z) end)
            -- Pulo de cerca baixa (SP, follow-mode): zumbi ficou atras de picket -> conduz/salta em vez de contornar.
            if d.combatFollowVault and CD.tryCombatVault(animal, z, d, getTimestampMs()) then return end
            -- Planta pro golpe SO em posicao de fato (dentro de STRIKE_DIST E linha livre). LOS bloqueada com o zumbi
            -- LONGE != inalcancavel: persegue e deixa o A* contornar parede/arvore (interior/floresta), senao o cao
            -- congela atras de toda parede. Nao golpeia atravessando (isso fica na passada pesada).
            if CD.dist2D(animal, z) <= CD.STRIKE_DIST and not pathBlocked(animal, z) then
                pcall(function()
                    animal:setVariable("animalRunning", false)
                    animal:setVariable("animalSpeed", 0)
                    animal:stopAllMovementNow()
                end)
                holdStill(animal)
                d.combatPathTile = nil
            else
                combatDriveTile(animal, d, math.floor(z:getX()), math.floor(z:getY()), math.floor(z:getZ()),
                    function() animal:pathToCharacter(z) end)
            end
        end)
        if not keep then combatMaintainDogs[id] = nil end
    end
end

-- Mantem os caes ativos em FOLLOW se movendo suavemente ENTRE as passadas pesadas de COMPANION_TICK_INTERVAL.
-- Re-conduz so os caes que followOwner registrou (entao nunca sobrepoe combat/guard/stay/etc., que limpam a linha), e
-- so no MESMO andar dentro da coleira; subir escada entre andares e o teleport de coleira ficam por conta do loop
-- pesado (rodar o ramo de escada por tick queimaria STAIR_CLIMB_MAX_TRIES numa fracao de segundo). followOwner e
-- throttled internamente (re-pathea so na mudanca de tile do owner / travamento), entao isto e barato: um check de dist + um A* ocasional.
local function maintainFollowers()
    for id, animal in pairs(followMaintainDogs) do
        local keep = false
        pcall(function()
            if not animal:isExistInTheWorld() then return end
            local owner = CD.getOwnerPlayer(animal)
            if not owner then return end
            keep = true
            if CD.data(animal).breedTarget then return end   -- breeding: a aproximacao conduz este cao, nao o follow
            local _fok = math.floor(owner:getZ()) == math.floor(animal:getZ())
            local _gap = CD.dist2D(animal, owner)
            if _fok and _gap <= CD.TELEPORT_DIST then
                followOwner(animal, owner)
            end
        end)
        if not keep then followMaintainDogs[id] = nil end
    end
end

-- Heranca em SP: quando o player morre e comeca um personagem NOVO, o ownership chaveia em getUsername() (o nome do
-- personagem em SP, que muda), entao o companion antigo le como "nao seu", e o gate notyourdog bloqueia ate
-- re-domestica-lo, deixando um orfao invencivel impossivel de reaver. Re-vincula qualquer companion orfao ao player
-- atual (CD.adoptOrphan preserva skills/genes/lealdade). Oportunista: o cao pode estar descarregado quando o novo
-- personagem spawna, entao adotamos no momento em que ele carrega perto do player (tickCompanionInvincible mantem todo
-- companion invencivel enquanto isso, independente de owner, entao o orfao sobrevive intacto ate ser alcancado). SO
-- EM SP: em MP o username persiste atraves da morte entao o cao continua owned, e uma varredura sem guard deixaria
-- qualquer player roubar um orfao; o gate de single-player (getNumActivePlayers()==1) tambem descarta split-screen ("de quem e o orfao" e ambiguo la).
local function tickAdoptOrphans()
    if isServer() or isClient() then return end
    if getNumActivePlayers() ~= 1 then return end
    local player = getPlayer()
    if not player or player:isDead() then return end
    local cell = getCell()
    if not cell then return end
    pcall(function()
        local list = cell:getAnimals()
        if not list then return end
        for i = 0, list:size() - 1 do
            local a = list:get(i)
            if a and CD.isDog(a) and CD.isCompanion(a) and not a:isDead() and not CD.isOwnedBy(a, player) then
                CD.adoptOrphan(a, player)
                CD.notifyOwner(player, "inherited", { id = a:getOnlineID(), name = CD.data(a).name, breed = CD.getBreed(a) })
            end
        end
    end)
end

-- Fall guard anti-crash. Um IsoAnimal parado numa square SEM CHAO (uma tile de escada "suspensa" de map-mod, ou uma
-- tile de arvore/folhagem que a engine nao trata como chao solido) cai no caminho HUMANO de fall/land da engine
-- (updateFalling -> DoLand -> handleLandingImpact -> fallenOnKnees -> addHole), que da NPE todo frame porque um animal
-- nao tem humanVisual. Nao da pra corrigir a engine, entao todo tick zeramos os acumuladores de queda pra que o
-- impacto nunca alcance o limiar de fallenOnKnees (robusto a ordenacao: no maximo um frame de gravidade acumula entre
-- resets). setLastFallSpeed/setbFalling/setFallTime sao publicos em IsoGameCharacter (verificado por CFR); envoltos em
-- pcall caso a exposicao em Lua difira, caso em que o teleport-recover abaixo ainda pega um cao genuinamente sem chao.
local function suppressFall(animal)
    pcall(function() animal:setLastFallSpeed(0) end)
    pcall(function() animal:setbFalling(false) end)
    pcall(function() animal:setFallTime(0) end)
end

local function fallGuardOne(animal, now)
    if not animal:isExistInTheWorld() then return end
    suppressFall(animal)
    local d = CD.data(animal)
    if not d then return end
    if d.fenceHop then d.floorlessSince = nil; return end   -- mid-vault: o arco legitimamente o mantem acima da tile
    if CD.squareHasFloor(animal:getCurrentSquare()) then d.floorlessSince = nil; return end
    -- square sem chao / nil: debounce de alguns frames pra que um frame transitorio (ex.: streaming de chunk MP) nao teleporte
    if not d.floorlessSince then d.floorlessSince = now; return end
    if now - d.floorlessSince < (CD.FALL_GUARD_DEBOUNCE_MS or 150) then return end
    d.floorlessSince = nil
    local owner = CD.getOwnerPlayer(animal)
    if not owner then return end
    CD.clearClimbVars(animal)
    if teleportRecover(animal, owner) then
        d.fallRecoverUntilMs = now + (CD.FALL_RECOVER_COOLDOWN_MS or 1500)
        CD.transmit(animal)
    end
end

-- Grito, parte 2: com a aceitacao alta (CD.calmAcceptance) o cao nao FOGE mais, mas o ramo "vem" do respondToSound puxa o
-- cao rumo ao dono a cada frame do grito; a separacao o empurra de volta e o followOwner reage = "1-2 passos ao grito".
-- Os logs mostraram que o cao alterna held<->dirigido perto de um dono PARADO, entao d.held nao basta. Sinal certo =
-- "deve estar imovel AGORA": STAY, ou FOLLOW com o DONO parado e o cao ja assentado; e SEM objetivo proprio de movimento
-- (auto-comer/caca/combate/recuo/forrageio/recall/auto-protect/breeding/pulo). Grava a ancora e faz SNAP de volta a cada
-- drift, por OnTick (deslocamento liquido zero). Ancora com gap <= FOLLOW_START_DIST -> followOwner ja HOLD (nao briga).
local SHOUT_LOCK_STILL_MS = 400
local function cancelShoutNudge(animal)
    local d = CD.data(animal)
    if d.fenceHop or d.breedTarget or d.autoFeeding or d.hunting or d.inCombat or d.retreating
       or d.huntTargetId or d.forageGoingSinceMin or d.recallUntilMin or d.protectX then
        d.lockX = nil; return
    end
    local state = CD.getState(animal)
    local shouldLock = false
    if state == CD.STATE_STAY then
        shouldLock = true
    elseif state == CD.STATE_FOLLOW then
        local owner = CD.getOwnerPlayer(animal)
        if owner then
            local ox, oy = owner:getX(), owner:getY()
            local nowMs = getTimestampMs()
            if not d._olx or (math.abs(ox - d._olx) + math.abs(oy - d._oly)) >= (CD.OWNER_STILL_EPS or 0.1) then
                d._olx, d._oly, d._ostill = ox, oy, nowMs   -- dono se moveu: reinicia o cronometro de "parado"
            end
            local ownerStill = (nowMs - (d._ostill or nowMs)) >= SHOUT_LOCK_STILL_MS
            -- engata quando o cao esta assentado (gap <= START); ja engatado (d.lockX) segue travado ate o dono andar
            if ownerStill and (d.lockX or CD.dist2D(animal, owner) <= (CD.FOLLOW_START_DIST or 2)) then
                shouldLock = true
            end
        end
    end
    if not shouldLock then d.lockX = nil; return end

    local x, y = animal:getX(), animal:getY()
    if not d.lockX then
        d.lockX, d.lockY, d.lockZ = x, y, animal:getZ()
        return
    end
    local drift = math.abs(x - d.lockX) + math.abs(y - d.lockY)
    if drift > 0.05 then
        pcall(function() animal:stopAllMovementNow() end)
        pcall(function()
            local ax, ay, az = d.lockX, d.lockY, d.lockZ
            animal:setX(ax); animal:setY(ay); animal:setNextX(ax); animal:setNextY(ay)
            animal:setZ(az); if animal.setNextZ then animal:setNextZ(az) end
        end)
    end
end

-- Cobre TODO cao carregado, nao so os ativos em FOLLOW/COMBAT. O reset de acumulador por frame so previne o crash de
-- pouso pra um cao em que ele roda NESTE frame, entao um cao em stay/guard/passivo/auto-feed/hunt (ou um stray que
-- andou pra uma tile alta/sem chao) costumava cair livremente sem reset e ainda batia no NPE de fallenOnKnees num pouso
-- forte (>=1.5 tiles). cell:getAnimals() e o conjunto exato que a engine esta atualizando = o conjunto exato que pode
-- dar crash (a mesma varredura que tickCompanionFire/tickCompanionInvincible usam). Companions ganham o guard completo
-- (suppress + teleport-recover sem chao rumo ao owner); um cao nao-companion nao tem owner pra recuperar rumo, entao
-- ganha o suppress so-anti-crash (um efeito colateral e que nao toma mais dano de queda, uma troca inofensiva por nunca dar NPE-crash no server).
local function tickFallGuard()
    local now = getTimestampMs()
    local cell = getCell()
    if not cell then return end
    pcall(function()
        local list = cell:getAnimals()
        if not list then return end
        for i = 0, list:size() - 1 do
            local a = list:get(i)
            if a and CD.isDog(a) then
                if CD.isCompanion(a) then
                    pcall(fallGuardOne, a, now)
                    pcall(cancelShoutNudge, a)   -- cancela o "1-2 passos ao grito" (path injetado pelo respondToSound) num cao que deve ficar parado
                else
                    pcall(suppressFall, a)
                end
            end
        end
    end)
end

-- Suavidade do follow em MP. O PZ sincroniza a posicao de um animal pros clients remotos so a ~1.25Hz
-- (AnimalSynchronizationManager, hardcoded 800/1000ms). Pro cao ATIVO em movimento esse atraso e bem visivel: ele
-- arrasta atras de um owner que vira com uma correcao de rumo uma vez por segundo. IsoAnimal expoe
-- sendExtraUpdateToClients(), o PROPRIO force fora de cadencia da engine (ela o usa na morte): enfileira o cao +
-- setExtraUpdate de toda conexao RELEVANTE (filtrada por alcance internamente). Chama-lo a ~10Hz enquanto o cao se
-- move faz os clients remotos interpolarem rumo a alvos frescos em vez de pular uma vez por segundo. SERVER-autoritativo,
-- sem codigo de client, ajuda TODO client, mesmo nao-patcheado. Veja pz-b42-animal-mp-position-sync.
local function pushDenseSync(animal, now)
    local d = CD.data(animal)
    -- Mid-vault: o replay por client (tickClientFenceHops) cuida do visual. Um force-push de 10Hz do glide do server numa
    -- fase de frame diferente puxa a copia do client = o "congela depois snap". O baseline de 1Hz + fencehopend cobrem isto.
    if d and d.fenceHop then return end
    if d and d._followStreaming then return end   -- o follow stream custom cuida deste cao; nao adiciona pacotes dense nativos
    if d._denseSyncMs and (now - d._denseSyncMs) < (CD.DENSE_SYNC_MS or 100) then return end
    -- So empurra quando o cao de fato TRANSLADOU desde o ultimo push. isMoving() le true enquanto o cao anda-no-lugar
    -- num node bloqueado (gargalo interno / porta fechada), onde um pacote redundante fora de cadencia so amplifica a
    -- Prediction em linha reta do client. Um delta de posicao real e o sinal honesto de "ele se moveu".
    local px, py
    pcall(function() px, py = animal:getX(), animal:getY() end)
    if not px then return end
    local moved = d._denseLastX and (math.abs(px - d._denseLastX) + math.abs(py - d._denseLastY)) or 999
    d._denseLastX, d._denseLastY = px, py
    d._denseSyncMs = now   -- avanca a janela de avaliacao de ~100ms toda passada pra que `moved` seja um delta estavel por janela
    if moved < (CD.DENSE_SYNC_MIN_MOVE or 0.02) then return end
    pcall(function() animal:sendExtraUpdateToClients() end)
end

-- Caes ativos em FOLLOW + COMBAT sao os que se movem e valem densificar (mutuamente exclusivos por passada, dai o id guard).
local function tickDenseSync()
    if not CD.MP_DENSE_FOLLOW_SYNC or not isServer() then return end
    local now = getTimestampMs()
    for _, animal in pairs(followMaintainDogs) do pcall(pushDenseSync, animal, now) end
    for id, animal in pairs(combatMaintainDogs) do
        if not followMaintainDogs[id] then pcall(pushDenseSync, animal, now) end
    end
end

-- ===== MP follow: replicacao de posicao custom (stream do server) ============================================
-- A engine sincroniza a posicao de um animal pros clients remotos so a ~1Hz e o client a extrapola em LINHA RETA
-- (dead-reckoning de Prediction): um path interno/de porta curvo renderiza como o cao andando contra uma parede e
-- depois snapando. Nos contornamos isso: streamamos o transform autoritativo do cao ATIVO a ~15Hz e deixamos cada
-- client renderizar um path INTERPOLADO suave (CompanionDogs_Client.tickFollowStreamClient). O server continua
-- autoritativo (followOwner conduz o cao real); isto so ESPELHA a posicao dele, entao a copia renderizada nunca passa
-- do teleport guard distToReal>10 da engine. Limitado por alcance no server. Veja memory companiondogs-custom-mp-position-replication.
local followStreamActive = {}   -- onlineID -> animal atualmente streamado (pra podermos enviar followstop quando ele para)

local function anyFollowViewerNear(animal)
    local list = getOnlinePlayers()
    if not list then return false end
    local ax, ay = animal:getX(), animal:getY()
    local range = CD.FOLLOW_STREAM_RANGE or 40
    for i = 0, list:size() - 1 do
        local p = list:get(i)
        if p and (math.abs(p:getX() - ax) + math.abs(p:getY() - ay)) <= range then return true end
    end
    return false
end

local function stopFollowStream(id, animal)
    followStreamActive[id] = nil
    if animal then
        local d = CD.data(animal)
        if d then d._followStreaming = nil; d._followStreamMs = nil end
    end
    pcall(function()
        local args = { id = id }
        if animal and animal:isExistInTheWorld() then
            args.x, args.y, args.z = animal:getX(), animal:getY(), animal:getZ()
        end
        sendServerCommand(CD.MODULE, "followstop", args)
    end)
end

local function pushFollowStream(animal, now)
    local d = CD.data(animal)
    if not d or d.fenceHop then return end   -- o fence-vault cuida do broadcast + glide do client durante um hop
    local id = animal:getOnlineID()
    if not anyFollowViewerNear(animal) then
        if followStreamActive[id] then stopFollowStream(id, animal) end
        return
    end
    if d._followStreamMs and (now - d._followStreamMs) < (CD.FOLLOW_STREAM_MS or 66) then return end
    d._followStreamMs = now
    d._followSeq = (d._followSeq or 0) + 1
    d._followStreaming = true
    followStreamActive[id] = animal
    local fx, fy = 0, 1
    pcall(function() local f = animal:getForwardDirection(); if f then fx, fy = f:getX(), f:getY() end end)
    local run = false
    pcall(function() run = animal:getVariableBoolean("animalRunning") end)
    sendServerCommand(CD.MODULE, "follow", {
        id = id, x = animal:getX(), y = animal:getY(), z = animal:getZ(),
        fx = fx, fy = fy, run = run, seq = d._followSeq,
    })
end

-- Pos-pouso: streama a posicao autoritativa do cao pros clients por uma janela curta pra que o CLIENT desenhe o cao
-- onde o SERVER de fato esta (direto pro owner). Os logs do server provaram que o path autoritativo e perfeito; o
-- andar-pra-tras e puramente o remote-render da engine. Reaproveita o follow-stream comprovado (pushFollowStream ->
-- interpolacao onFollowFrame/tickFollowStreamClient do client). Para o stream (libera o client pro sync nativo) quando a janela expira.
local function tickLandStream()
    if not isServer() then landStreaming = {}; return end
    local now = getTimestampMs()
    for id, rec in pairs(landStreaming) do
        local drop = true
        pcall(function()
            local a = rec.animal
            if not a or not a:isExistInTheWorld() or now >= rec.untilMs then return end
            drop = false
            pushFollowStream(a, now)
        end)
        if drop then
            landStreaming[id] = nil
            pcall(function() stopFollowStream(id, rec.animal) end)
        end
    end
end

local function tickFollowStream()
    if not CD.FOLLOW_STREAM or not isServer() then return end
    local now = getTimestampMs()
    for _, animal in pairs(followMaintainDogs) do pcall(pushFollowStream, animal, now) end
    for id, animal in pairs(combatMaintainDogs) do
        if not followMaintainDogs[id] then pcall(pushFollowStream, animal, now) end
    end
    -- um cao que saiu dos registros ativos (un-follow / stay / guard / pickup) para de receber frames acima; avisa os
    -- clients pra libera-lo pra que nao segurem uma tile desatualizada (o client tambem tem um backstop de staleness).
    for id, animal in pairs(followStreamActive) do
        if not (followMaintainDogs[id] or combatMaintainDogs[id]) then pcall(stopFollowStream, id, animal) end
    end
end

-- ===== MP flag de render A* no client (companion dense-native) ===============================================
-- No modo dense-native o client dead-reckona a posicao de um animal em LINHA RETA entre pacotes autoritativos
-- esparsos: uma rota curva ao redor de moveis / atraves de uma porta renderiza como o cao raspando a parede. Nos
-- viramos o PROPRIO remote-mover da engine pra A* no client setando setHasObstacleOnPath(true) na copia remota (ele
-- persiste, AnimalPacket nunca o limpa). O server so diz a cada client proximo qual id de cao e um follower ativo; o
-- client afirma a flag por tick (CompanionDogs_Client.tickAstarRenderClient). Veja companiondogs-custom-mp-position-replication.
local astarFlagActive = {}   -- onlineID -> animal atualmente flagado (pra podermos enviar astarstop quando ele para)

local function stopAstarFlag(id, animal)
    astarFlagActive[id] = nil
    if animal then local d = CD.data(animal); if d then d._astarFlagMs = nil end end
    pcall(function() sendServerCommand(CD.MODULE, "astarstop", { id = id }) end)
end

local function pushAstarFlag(animal, now)
    local d = CD.data(animal)
    if not d or d.fenceHop then return end   -- o fence-vault conduz setX diretamente; o A* do client brigaria com ele
    local id = animal:getOnlineID()
    if not anyFollowViewerNear(animal) then
        if astarFlagActive[id] then stopAstarFlag(id, animal) end
        return
    end
    if d._astarFlagMs and (now - d._astarFlagMs) < (CD.ASTAR_FLAG_MS or 400) then return end
    d._astarFlagMs = now
    astarFlagActive[id] = animal
    pcall(function() sendServerCommand(CD.MODULE, "astar", { id = id }) end)
end

local function tickAstarFlag()
    if not CD.MP_CLIENT_ASTAR_RENDER or CD.FOLLOW_STREAM or not isServer() then return end
    local now = getTimestampMs()
    for _, animal in pairs(followMaintainDogs) do pcall(pushAstarFlag, animal, now) end
    for id, animal in pairs(combatMaintainDogs) do
        if not followMaintainDogs[id] then pcall(pushAstarFlag, animal, now) end
    end
    for id, animal in pairs(astarFlagActive) do
        if not (followMaintainDogs[id] or combatMaintainDogs[id]) then pcall(stopAstarFlag, id, animal) end
    end
end

-- Reconstroi o espelho POR-PERSONAGEM (pd.kennel/pd.companions) a partir do canil GLOBAL durável, keyed pela chave
-- estavel do dono. Fecha o buraco da morte/menu/quit: o pd por-personagem morre com o personagem (SP) ou nao existe ate
-- reconectar (MP), mas o canil global persiste, entao um personagem NOVO (mesmo Steam ID) ou um player reconectado
-- recupera a lista "Meus Caes" e pode dar recall de qualquer lugar SEM precisar reencontrar o cao. Idempotente e barato
-- em regime estavel (nao sobrescreve entradas do pd; so preenche as que faltam). NAO seta pd.token (o cao ativo e
-- escolhido quando carrega perto / no recall). Entradas soltas (demote) sao removidas do global, entao nao ressuscitam.
-- CD.* em vez de `local function`: Companion.lua está no teto de 200 locals ATIVOS do chunk Kahlua; um local novo no
-- nível do chunk faz o arquivo INTEIRO não compilar (AIOOBE em new_localvar). Ver [[pz-kahlua-200-locals-limit]].
CD.reclaimKennelFromGlobal = function(player)
    if not player then return end
    local recs = CD.kennelGlobalGet and CD.kennelGlobalGet(CD.ownerKey(player))
    if type(recs) ~= "table" then return end
    local pd = CD.playerData(player)
    pd.kennel = pd.kennel or {}
    pd.companions = pd.companions or {}
    local changed, n = false, 0
    for tok, snap in pairs(recs) do
        if pd.kennel[tok] == nil and type(snap) == "table" then
            pd.kennel[tok] = CD.deepCopy(snap)
            changed = true; n = n + 1
        end
        if not pd.companions[tok] then pd.companions[tok] = true; changed = true end
    end
    if changed then
        pcall(function() player:transmitModData() end)
    end
end

local counter = 0
local followCounter = 0
local function companionTick()
    reconcileOwnerPresence()
    processAnimClears()
    tickMountedDogs()
    tickFenceHops()   -- por OnTick (sem throttle) pra que o glide do fence-vault seja suave, como tickMountedDogs
    tickFenceSteer()  -- por OnTick: avanca a aproximacao da cerca conduzida na mao todo tick (fonte continua pro stream)
    tickFenceLandPush()   -- por OnTick: forca pacotes frescos brevemente apos um pouso (anti back-drag)
    tickLandGlide()       -- pos-hop: conduz o cao na mao ate o dono (engine nao translada por animador travado); solta quando recupera/chega
    tickLandStream()      -- pos-pouso: streama a pos autoritativa pro client desenhar o path REAL (nao o render da engine)
    tickFallGuard()   -- anti-crash por OnTick: mantem TODO cao carregado fora do caminho humano de fall/land da engine (NPE de fallenOnKnees)
    tickGunGuard()
    tickCompanionFire()
    eachOnlinePlayer(bringActiveOnTeleport)
    followCounter = followCounter + 1
    if followCounter >= (CD.FOLLOW_TICK_INTERVAL or 2) then
        followCounter = 0
        maintainFollowers()
        maintainCombat()
    end
    tickDenseSync()   -- MP: forca pacotes de posicao mais densos pro cao ativo em movimento (throttled por cao internamente)
    tickFollowStream()  -- MP: nosso proprio stream de posicao a ~15Hz pro cao ativo (o client renderiza um path interpolado)
    tickAstarFlag()   -- MP dense-native: marca o cao ativo pra que cada client renderize seu path curvo real via A*
    counter = counter + 1
    if counter < CD.COMPANION_TICK_INTERVAL then return end
    counter = 0
    tickCompanionInvincible()
    if CD.tickBreedingApproach then CD.tickBreedingApproach() end   -- breeding: femea indo cruzar anda ate o macho (Breeding.lua)
    if CD.tickGestation then CD.tickGestation() end   -- breeding: femeas prenhes com gestacao vencida parem (Breeding.lua)
    if CD.tickPassiveBreeding then CD.tickPassiveBreeding() end   -- breeding: casal elegivel concebe sozinho (chance/hora, Commands.lua)
    tickMaturation()   -- breeding: filhotes que venceram o prazo viram adultos (Fase B), preservando o vinculo
    pruneFireState()   -- libera fireBaseline/fireSafeTile de caes que sairam da cell (reapDogState so cobre companions)
    tickAdoptOrphans()
    CD.repairOwnership()   -- ANTES do reclaim: expulsa cao alheio do canil, senao o reclaim o traria de volta pro pd
    eachOnlinePlayer(CD.reclaimKennelFromGlobal)   -- morte/menu/quit: recupera "Meus Caes" do canil global durável
    recoverStashedDogs()
    CD.recoverOfflineStashes()   -- sandbox DespawnOnOwnerOffline: devolve caes guardados de donos que reconectaram
    recoverCarriedDogs()
    recoverTraileredDogs()
    eachOnlinePlayer(processNearbyDogs)
    eachOnlinePlayer(reapPhantomCompanions)
    CD.reapClonesCellWide()   -- dedup por-uid na cell inteira (pega o clone do RV sem exigir co-load perto do dono)
end

if not isClient() then
    Events.OnTick.Add(companionTick)
    Events.OnWeaponSwingHitPoint.Add(ghost.onFire)         -- SP: bala fantasma (tira o cao da hit list no disparo)
    Events.OnTick.Add(ghost.readd)                         -- re-add adiado dos caes fantasma no tick seguinte
    Events.OnWeaponHitCharacter.Add(ghost.onHit)           -- backstop: cao nunca leva sangue/dano do tiro (sem teleporte)
end
