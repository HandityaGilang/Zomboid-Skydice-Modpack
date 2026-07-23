CompanionDogs = CompanionDogs or {}
local CD = CompanionDogs

CD.MODULE = "CompanionDogs"

CD.BREED = "brown"
CD.TYPES = { dogpup = true, dogfemale = true, dogmale = true,
             gspup = true, gsfemale = true, gsmale = true,
             retrieverpup = true, retrieverfemale = true, retrievermale = true,
             huskypup = true, huskyfemale = true, huskymale = true }
CD.SPAWN_TYPES = { "dogmale", "dogfemale" }

CD.TRUST_MAX = 100
CD.FEED_TRUST_GAIN = 25
CD.FEED_TRUST_PER_HUNGER = 1.0
CD.TAME_THRESHOLD = 100

-- Breeding / filhotes (Fase A). Reproducao e simulada em ModData (timer/parto/blend proprios); a engine so
-- entra no auto-crescimento de estagio (dogpup -> adulto). Ver breeding-rules.md.
CD.GENE_MUTATION = 0.06          -- jitter +-6% no blend de cada gene do filhote (mantem variancia entre geracoes)
CD.GESTATION_DAYS = 4           -- duracao da gestacao em dias-jogo (sandbox GestationDays)
CD.MATURITY_DAYS = 90           -- pup -> adulto (casa o nativo dogpup ageToGrow = 3*30)
CD.BREED_COOLDOWN_DAYS = 7      -- cooldown da femea pos-parto (espelha timeBeforeNextPregnancy das defs)
CD.BREED_LOYALTY_FRAC = 0.6     -- piso de lealdade pra cruzar, como fracao de TRUST_MAX
CD.BREED_RANGE = 2             -- distancia <= esta (tiles) = a femea chegou no macho e concebe
CD.BREED_WELLFED_MAX = 0.5     -- fome/sede precisam estar abaixo disto (0..1) pra cruzar
CD.BREED_LEASH = 40            -- distancia max femea<->macho durante a aproximacao antes de abortar
CD.BREED_APPROACH_TIMEOUT_MIN = 10   -- a femea desiste de ir ate o macho apos isso (min-jogo)
CD.BREED_CHANCE_PER_DAY = 5    -- % por dia de um casal proximo conceber sozinho (sandbox BreedChancePerDay); rolado por hora; 0 = desligado
CD.BREED_NEARTERM_FRAC = 0.25  -- ultimo pedaco da gestacao (fracao) em que o indicador vira "Parto proximo"
CD.PUPPY_BORN_LOYALTY = 50     -- filhote nasce com meia lealdade (criado != domado do zero)
CD.PUPPY_SIZE = 0.6            -- escala visual do filhote (setSize); pinada todo sweep ate a maturacao (Fase B)

CD.STATE_FOLLOW = "follow"
CD.STATE_STAY = "stay"
CD.STATE_GUARD = "guard"
-- Cooldown por CAO entre chamadas do Trazer da tela Meus Caes (min-jogo); carimbo em pd.kennel[token].recallAtMin.
CD.KENNEL_RECALL_COOLDOWN_MIN = 120
-- Registro de colo orfao (sem item no inventario e sem cao pra re-anexar) vira Perdido depois desta janela (ms reais).
CD.CARRIED_STALE_MS = 60000
CD.GUARD_RADIUS = 10
CD.GUARD_RETURN_DIST = 2
CD.FOLLOW_START_DIST = 2
CD.FOLLOW_RUN_DIST = 5
CD.TELEPORT_DIST = 24
-- A recuperacao por teleporte do auto-follow encaixa o cachorro ATRAS do dono (owner - forward * TELEPORT_BACK_DIST), nao em cima dele,
-- entao nao aparece de surpresa na frente do player. Recua para 1 tile / o tile do dono se estiver bloqueado.
CD.TELEPORT_BACK_DIST = 2
-- Follow entre andares: quando o dono muda de andar o cachorro tenta PATH subindo/descendo a escada (o A* da engine e
-- multi-andar para animais). Se nao alcancar o andar do dono dentro deste numero de follow ticks (sem rota de escada /
-- o pathfinder nativo recusa), followOwner recua para o antigo teleporte de recuperacao para nunca ficar preso um andar
-- abaixo. ~30 ticks ~ alguns segundos em COMPANION_TICK_INTERVAL.
CD.STAIR_CLIMB_MAX_TRIES = 30
-- Salto de cerca baixa: um cachorro seguindo pula uma cerca baixa (HoppableN/W) quando atravessar o deixa mais perto do
-- dono e o dono esta dentro de FENCE_HOP_DETECT_DIST tiles. FENCE_HOP_STEP e a velocidade do glide (fracao da travessia por
-- OnTick; 0.03 ~ meio segundo): O botao de ajuste (menor = mais lento, mais suave). Ver pz-b42-animal-fence-climb.
CD.FENCE_HOP_DETECT_DIST = 20   -- pula enquanto PERSEGUE (o dono do outro lado de uma cerca costuma estar >8 tiles depois que corre)
CD.FENCE_HOP_STEP = 0.021  -- fracao do glide por OnTick, ajustada para casar aproximadamente com o clipe cdJump @ SpeedScale 2.3
CD.FENCE_HOP_DURATION_MS = 800  -- duracao REAL do hop (wall-clock). Progresso baseado em TEMPO, nao em frames: o server dedicado roda a ~10fps e o client a ~60fps, entao um hop por-frame levava 0.8s no client e 4.8s no server (desync que travava o cao). Tempo iguala os dois.
CD.FENCE_HOP_ARC = 0.3     -- elevacao do entity-Z (pernas de Run galopam por baixo = um salto de impulso). 0.5 era "grilo" (alto demais)
-- OFF: o cao seguindo so pula cerca BAIXA (Hoppable*), igual ao vault de combate. Tudo que e TallHoppable* fica de fora,
-- porque na engine essa flag nao quer dizer "cerca", quer dizer "muro escalavel": ela cobre tanto o alambrado vazado
-- (fencing_01_58, MetalWire + WallWTrans) quanto muro solido (log wall walls_logs_*/carpentry_02_80-82, cerca alta de
-- madeira fencing_01_8-12, chapa fencing_01_40-42). true = volta a pular so a metade VAZADA (alambrado + grade de
-- barras), nunca a solida. Ver pz-b42-animal-fence-climb.
CD.FENCE_HOP_TALL = false
CD.FENCE_GHOST_SCAN = 8         -- ghost: tiles a varrer de um cachorro PARADO em direcao ao dono buscando uma cerca bloqueante;
                                -- o cachorro CAMINHA ate o tile proximo dessa cerca (nao pula de longe) e ai salta
                                -- a queima-roupa, entao um alcance maior so significa que ele vai para a cerca mais cedo
CD.FENCE_GHOST_STALL_MS = 400   -- por quanto tempo o cachorro precisa ficar CONFINADO (dentro de FENCE_STALL_RADIUS) antes do ghost
CD.FENCE_STALL_RADIUS = 0.8     -- raio de deslocamento liquido (tiles): sair dele re-ancora = "ainda seguindo", entao um
                                -- cachorro so conta como encurralado quando preso dentro deste raio por FENCE_GHOST_STALL_MS
CD.FENCE_HOP_LAND_BLEND = 0.82  -- fracao do glide na qual o clipe de salto comeca a mesclar de volta para idle (pouso suave)
-- A travessia precisa reduzir a distancia ate o dono em pelo menos isto (tiles ao quadrado), medido de CENTRO-DE-TILE a
-- CENTRO-DE-TILE (nao a pos sub-tile oscilante do cachorro) para que um cachorro paradinho perto de uma cerca nao fique piscando atravessa/volta.
-- Pequeno: centro-de-tile + prevencao de overshoot + settle + recross-block ja matam o vai-e-vem A<->B; isto e so um
-- epsilon para desempatar distancias exatas. Mantenha perto de 0 para que uma travessia legitima e proxima em direcao ao dono sempre dispare.
CD.FENCE_HOP_MIN_GAIN = 0.05
-- Anti ping-pong: tempo REAL (getTimestampMs, imune a velocidade do game-time: um minuto de jogo pode passar em menos de um segundo).
-- COOLDOWN_MS e a folga de assentamento apos um pulo (cachorro caminha em direcao ao dono antes de qualquer re-deteccao); RECROSS_BLOCK_MS
-- proibe re-atravessar a MESMA borda para nao quicar A->B->A (ainda pode atravessar uma cerca DIFERENTE mais cedo).
CD.FENCE_HOP_COOLDOWN_MS = 1500
CD.FENCE_RECROSS_BLOCK_MS = 1500
-- Mover de travessia de cerca customizado (nosso proprio, sem A* da engine perto de cercas). Assim que uma cerca esta entre o cachorro e o dono
-- conduzimos o cachorro nos mesmos ate o tile proximo da cerca e encadeamos pulos ate a linha ate o dono ficar livre de cercas, em vez de
-- devolver ao A* (que trata cercas pulaveis como paredes -> path falha -> cachorro gruda na cerca). STEER_*_SPEED e
-- a velocidade do glide manual (tiles por SEGUNDO, baseada em tempo para ser independente de FPS) enquanto corre/caminha ate a cerca.
CD.STEER_RUN_SPEED = 3.6
CD.STEER_WALK_SPEED = 1.8
-- Teto do dt (ms) do passo do steer. O steer e chamado a cada ~200ms no servidor dedicado (~10fps, FOLLOW_TICK_INTERVAL=2),
-- nao a cada frame. Com o teto antigo de 50ms o cao andava 1/4 da velocidade ate a cerca (os "passos travados"). 250 cobre o
-- intervalo real do servidor; ainda limita um trancao se o steer for re-entrado depois de uma pausa longa (_steerMs obsoleto).
CD.STEER_MAX_DT_MS = 250
-- Anti-marcha para o salto de cerca. O cachorro salta ANSIOSAMENTE em direcao ao dono (ele pula, que e o que queremos); para parar a
-- oscilacao "salta e volta / caminha a cerca", apos um salto proibimos saltar na direcao OPOSTA por
-- FENCE_BACKBLOCK_MS. Travessias para frente/perpendiculares continuam permitidas para encadear uma cerca longa; so nao pode reverter.
-- Robusto, barato, MP-safe (sem flood-fill, sem devolucao ao A* que congela um cachorro numa cerca, sem teleporte de watchdog).
CD.FENCE_BACKBLOCK_MS = 2000
-- Decisao alternativa EXPERIMENTAL (padrao OFF). Inunda o lado do cachorro e so salta quando o dono esta murado /
-- o caminho ao redor e longo. Matou o pulo + congelou o cachorro nas cercas + causou teleportes de watchdog no MP, entao esta OFF;
-- o salta-ansioso + back-block acima e o comportamento de producao. Mantido aqui atras da flag para referencia / trabalho futuro.
CD.FENCE_REACH_MODE = false
CD.REGION_TTL_MS = 300
CD.REGION_RADIUS = 22
CD.REGION_MAX_TILES = 240
-- Flood de alcancabilidade do COMBATE (selecao de alvo; independente do FENCE_REACH_MODE acima, roda em SP e server).
-- Janela 12 cobre o ATTACK_COMMAND_RADIUS; teto 700 > area da janela (25x25=625) pra em campo aberto o flood terminar
-- sem truncar (nao-membro so reprova alvo quando o flood e completo; truncado degrada pro comportamento antigo).
CD.COMBAT_REGION_RADIUS = 12
CD.COMBAT_REGION_MAX_TILES = 700
CD.VAULT_DETOUR_FACTOR = 2.5
-- Selecao de alvo do combate: um zumbi so e alvo valido se o caminho A PE ate ele (profundidade do flood; cerca conta
-- como parede pois em combate o cao NAO pula, so contorna) nao for um desvio grande demais vs a distancia em linha reta:
-- profundidade <= dist * COMBAT_DETOUR_FACTOR + COMBAT_DETOUR_ADD. Rejeita o zumbi "atras da cerca" que so da pra alcancar
-- dando a volta longa (o cao ia orbitar a cerca sem fim); contorno curto em volta de parede/quina segue valido.
CD.COMBAT_DETOUR_FACTOR = 1.5
CD.COMBAT_DETOUR_ADD = 2
-- Watchdog de liveness (rede de seguranca): se o cachorro fica CONFINADO sem progresso real de gap por PROG_STUCK_MS, reposiciona
-- ele de forma limpa ao lado do dono (reusa teleportRecover) para que um erro de calculo do flood nunca o deixe marchando/encalhado.
CD.PROG_STUCK_MS = 1500
CD.PROG_EPS = 0.35            -- reducao minima de gap (tiles) que conta como progresso
CD.PROG_REPOSITION_COOLDOWN_MS = 2000
-- Acabamento MP. O pulo e perfeito no SP (o cachorro e o objeto autoritativo local) mas um cliente remoto re-deriva a
-- pos/facing do cachorro de pacotes de servidor ~1Hz e periodicamente apaga nossas anim vars (NetworkCharacterAI.resetState ->
-- clearVariables), entao o salto pode aparecer de lado / cabeca pra cima. O replay do cliente re-afirma cdJump+facing a cada frame para
-- combater isso (sempre ligado). Dois botoes extras, ambos padrao OFF (validar in-game antes de ligar):
CD.FENCE_HOP_REDIRECT = false   -- EXPERIMENTAL: tambem escreve os alvos de convergencia da propria engine (networkAi) para mover
                                -- o cachorro AO LONGO do nosso arco em vez de brigar com ele; auto-desativa se os campos nao forem
                                -- escreviveis por Lua, entao nunca pode quebrar o replay seguro.
CD.FENCE_HOP_MP_BLINK = false   -- FALLBACK: em clientes remotos esconde o cachorro durante o pulo e o re-exibe no tile de
                                -- pouso (travessia instantanea, sem artefatos) em vez do salto animado.
-- Suavidade das BORDAS do salto de cerca em MP (2026-06-25). O GLIDE do pulo replica bem (cliente possui setX), mas a APROXIMACAO e
-- o POUSO devolvem o cachorro ao remote-mover da engine, que briga com ele: na aproximacao o A* do proprio cliente
-- (MP_CLIENT_ASTAR_RENDER) trata a cerca pulavel como uma PAREDE e anda-no-lugar ate o pulo chegar ("para,
-- da dois passos, pensa"); no pouso o realx defasado de ~800ms arrasta o cachorro DE VOLTA para a cerca ("volta pra cerca,
-- gira"). Fix = alargar a janela de propriedade do cliente alem de ambas as bordas. Ver pz-b42-animal-fence-climb / pz-b42-animal-mp-position-sync.
CD.FENCE_NEAR_TTL = 1200         -- ms que um cliente suprime seu proprio A* assim que o servidor sinaliza uma cerca atravessavel na linha
                                 -- (para o cachorro dead-reckon RETO na cerca em vez de desviar/marchar). Auto-expira.
CD.FENCE_HOP_SETTLE_MS = 300     -- ms que o cliente continua POSSUINDO o cachorro APOS o pouso (segura o tile de pouso + vira pra
                                 -- frente + A* off) para a engine nao arrastar/extrapolar ele de volta pra cerca antes de pacotes
                                 -- Static novos substituirem a previsao Moving defasada. ~bate com o re-path da passada pesada do
                                 -- servidor (~330ms) pra devolver bem na hora que o follow normal volta. Maior = cachorro atrasa de um dono correndo.
CD.FENCE_LAND_PUSH_MS = 1200
-- Apos um pouso, fazer o SERVIDOR transmitir a posicao autoritativa do cao pra que o CLIENTE desenhe o caminho real (reto
-- pro dono) por este tempo, em vez do remote-render quebrado da engine (que levava o cao pra cerca). Reusa o follow-stream.
CD.FENCE_LAND_STREAM_MS = 2000
-- Mesma ideia, mas durante a APROXIMACAO (o cao conduzido-na-mao ate a borda da cerca antes de pular). Movimento na-mao nao
-- replica liso pela sync nativa, entao o stream faz o cliente interpolar = sem "passos travados" antes do pulo. Janela curta,
-- re-armada a cada passo do steer; expira logo apos o cao parar de steerar (o broadcast do hop assume durante o pulo).
CD.FENCE_STEER_STREAM_MS = 500
-- Janela do driver por-tick do steer (tickFenceSteer): re-armada a cada passada eager (~200ms); o cao e movido a cada tick do
-- servidor enquanto ela esta fresca. So precisa exceder o intervalo da passada eager; expira logo apos o cao sair do modo cerca.
CD.FENCE_STEER_DRIVE_MS = 500
-- Opcao: usar o stream customizado (setX no cliente) OU deixar a sincronizacao NATIVA desenhar (realx fresco).
-- O stream marca _followStreaming e DESLIGA o dense-sync nativo (que o motor usa pra desenhar o animal remoto),
-- entao o setX move getX mas o motor desenha no realx velho (a cerca). false = dense-native puro (motor desenha).
CD.FENCE_LAND_USE_STREAM = true
CD.FENCE_LAND_GLIDE = true      -- land-glide (hand-drive pos pos-pulo): conduz o cao na mao ate o dono e solta so em idle estavel (releaseLandGlide). Reativado c/ FENCE_HOP_MP; ver mp_jump_animation.md.
-- Pulo de cerca em servidor (MP/dedicado). O land-glide contorna o congelamento do animador pos-pulo conduzindo TODO o
-- movimento na mao e devolvendo o controle so quando o cao alcancou o dono parado (idle estavel), entao nao depende dos
-- overrides globais m_BlendTime=0. false = cao contorna a cerca via pathing normal (o comportamento de revert).
CD.FENCE_HOP_MP = true
-- Apos um pouso, manter o A* DO CLIENTE desligado por este tempo. O A* do cliente trata a cerca como PAREDE, entao se ele
-- reativa enquanto o cao ainda esta do lado da cerca ele fica "andando colado" nela (wall-hug) por ~1-2s. Com ele off o
-- cao usa dead-reckoning reto rumo a previsao (que o re-path no pouso aponta pro dono) = vai direto pra voce sem grudar.
CD.FENCE_POST_LAND_ASTAR_OFF_MS = 2000
CD.LAND_GLIDE_TELEPORT_NOTE = true   -- pos-hop o land-glide conduz na mao ate o cao ALCANCAR o dono parado; so entao solta pro follow normal (sem probe: o animador do servidor nao recupera no meio do movimento)
-- Server: quando uma cerca atravessavel e confirmada na linha reta em direcao ao dono, o cachorro so precisa ficar CONFINADO
-- por isto (ms) antes de saltar, em vez do FENCE_GHOST_STALL_MS completo (~400). O confine curto ainda distingue
-- "o A* esta genuinamente preso na cerca" de "tem um portao aberto bem aqui" (o A* leva o cachorro por um portao => nunca
-- confinado => sem pulo), entao nao faz o cachorro pular sem necessidade; so commita ~250ms mais cedo uma vez realmente encurralado.
-- Defina 0 para o mais agressivo (pula no instante em que uma cerca esta na linha). Anti-oscilacao = back-block + recross.
CD.FENCE_ONLINE_STALL_MS = 150
-- Fall guard (anti-crash). Um companheiro (IsoAnimal) parado num square SEM PISO (um tile de escada "suspensa" de map-mod,
-- ou um tile de arvore/folhagem que a engine nao trata como piso solido) cai no caminho de fall/land HUMANO da engine
-- (updateFalling -> DoLand -> handleLandingImpact -> fallenOnKnees -> addHole), que NPEa a cada frame porque um
-- animal nao tem humanVisual. Suprimimos os acumuladores de queda a cada tick (o impacto nunca alcanca o limite de
-- fallenOnKnees) e, apos este debounce, encaixamos o cachorro de volta num tile com piso. Ver tickFallGuard.
CD.FALL_GUARD_DEBOUNCE_MS = 150     -- square sem piso/nil precisa persistir por isto (tempo real) antes de teleportar-recuperar
CD.FALL_RECOVER_COOLDOWN_MS = 1500  -- apos uma recuperacao, suspende a re-deteccao de fence-hop por isto (quebra o loop queda<->refollow)
-- Teleport-follow: um salto do dono num unico tick maior que isto (tiles) e tratado como um teleporte (admin/map/debug),
-- trazendo o cachorro em FOLLOW ativo. Defina bem acima de qualquer movimento legitimo de um tick (sprint e ~0.13 tiles/tick) mas baixo
-- o suficiente para pegar ate teleportes de debug CURTOS: um salto menor fica a cargo do follow normal (o cachorro so corre ate).
CD.TELEPORT_JUMP_MIN = 6
-- Teleport-follow: quando um teleporte de admin/map (ou entrar numa celula de Project RV Interior, salas hardcoded em x>=22560)
-- manda o dono para alem do raio de carga, o cachorro em FOLLOW ativo ja descarregou, entao ele e respawnado no dono
-- e carimbado como a encarnacao canonica (bumpCanonical / pd.uidGen). O original deixado para tras mantem uma gen mais antiga
-- e e ceifado no load por processNearbyDogs, sem precisar de co-load (ver CompanionDogs_Companion.lua).
-- Apos detectar um teleporte, continua tentando trazer por este numero de ticks. Num SERVER dedicado/coop o chunk de
-- destino do dono pode levar alguns SEGUNDOS para carregar apos um teleporte distante (getCurrentSquare fica nil ate la),
-- entao isto e generoso; o retry e barato e para no instante em que o cachorro e trazido.
CD.TELEPORT_BRING_TRIES = 300
-- Compat com Project RV Interior: aquele mod estaciona seus interiores acessiveis numa faixa distante fixa (salas hardcoded em x>=22560,
-- y>=12060). Um tile nesse limite ou acima esta "dentro de um interior de RV". Usado para detectar SAIR do interior: o mod re-assenta
-- o motorista na saida, o que de outra forma re-suprimiria o trazer e abandonaria o cachorro la (ver bringActiveOnTeleport).
CD.RV_INTERIOR_MIN_X = 22500
CD.RV_INTERIOR_MIN_Y = 12000
-- Auto-cura de slot fantasma (reapPhantomCompanions): um companheiro que morreu por um caminho da engine que driblou a permadeath
-- (ex. um roadkill na breve janela de respawn pre-invencivel num save pre-fix) deixa seu token em pd.companions
-- para sempre: o corpo sai de getAnimals() entao nada o limpa, o mapa-mundi mantem uma pata congelada e o
-- limite MaxCompanions fica cheio. O token so e limpo quando provadamente sumiu: o dono esta dentro do
-- raio de carga de chunk de sua ultima ancora viva e nenhum cachorro vivo com esse token carrega, sustentado por este numero de
-- game-minutes (a tolerancia cobre os poucos segundos que um chunk MP leva para carregar; um cachorro meramente estacionado longe nunca
-- aciona porque o dono nao esta perto de sua ancora).
CD.PHANTOM_LOST_GRACE_MIN = 3
CD.RECALL_OVERRIDE_MIN = 1
-- Auto-protect: enquanto o dono faz uma acao vulneravel/estacionaria, um toggle por cachorro torna o cachorro num
-- guarda temporario ancorado no dono. O cliente (CompanionDogs_AutoProtect.lua) emite o heartbeat "dono vulneravel"
-- ~uma vez por game-minute e envia um OFF explicito quando a acao termina; o server trata o cachorro como protegendo
-- enquanto worldMinutes() < d.protectUntilMin. A janela e um FAILSAFE generoso de game-minute (cobre um OFF perdido /
-- um disconnect / um tick de fast-forward que pula varios game-minutes antes do loop re-ler); o
-- OFF explicito e o que solta o cachorro prontamente quando o dono de fato termina.
CD.AUTO_PROTECT_WINDOW_MIN = 5
-- Nomes de classes de timed-action de Lua que contam como uma acao vulneravel e estacionaria do dono (alem de sleep / sit-on-ground
-- / isReading, que sao lidos direto do player). Qualquer acao cujo Type contenha "Fish" tambem conta. Estenda
-- este conjunto para incluir mais acoes longas no auto-protect.
CD.AUTO_PROTECT_ACTIONS = {
    ISReadABook = true,
    ISEatFoodAction = true,
    ISFishingAction = true,
}
CD.ZOMBIE_ATTACK_RADIUS = 8
-- Em FOLLOW o cao so engaja zumbi AUTONOMAMENTE (auto-protect/dono lutando) dentro deste raio do DONO, nao dos 8
-- tiles ao redor do proprio cao: em follow ele protege uma bolha em torno de voce em vez de sair caÃ§ando longe
-- atras de cerca. O comando explicito Atacar mantem o alcance amplo (ATTACK_COMMAND_RADIUS).
CD.FOLLOW_DEFEND_RADIUS = 5
CD.FOLLOW_DEFEND_DROP = 8      -- solta o alvo engajado que sair desta bolha em torno do dono (histerese vs o raio de aquisicao)
CD.COMPANION_TICK_INTERVAL = 20
-- A logica completa do companheiro (scans de combat/sentinel/hunt/upkeep) roda a cada COMPANION_TICK_INTERVAL ticks; essa
-- cadencia e grossa demais para um FOLLOW suave (o cachorro alcanca o dono e fica idle entre as passadas, onde o
-- wanderIdle da engine o re-paths para um tile aleatorio = "segue de forma erratica" no MP). Um mantenedor de follow leve
-- re-conduz so o seguidor ativo nesta frequencia, fechando a janela de wander sem pagar os scans pesados mais vezes.
CD.FOLLOW_TICK_INTERVAL = 2
-- Throttle de re-path do followOwner. PathFindBehavior2.setData() (rodado por todo pathToCharacter/pathToLocation) CANCELA
-- a requisicao ASYNC de A* em voo SEM guarda de igualdade de goal, entao o mantenedor por tick re-emitindo a cada passada mantinha
-- o path perpetuamente nao resolvido = o cachorro "corre no lugar" sem transladar. Fix: re-emitir SO na mudanca de TILE do dono,
-- e nunca com mais frequencia que FOLLOW_REPATH_MS (real-ms; deixa o A* async resolver antes de cancelarmos).
-- FOLLOW_STALL_* e o backstop baseado em tempo para um cachorro genuinamente bloqueado (nao re-armamos mais o
-- anti-stuck WalkingOnTheSpot da engine). Ver memoria pz-b42-pathto-setdata-cancels-async-astar.
CD.FOLLOW_REPATH_MS = 250        -- min real-ms entre re-emissoes reais de pathToCharacter enquanto rastreia um dono em movimento
CD.FOLLOW_STALL_EPS = 0.05       -- deslocamento (tiles por passada de follow) abaixo do qual o cachorro conta como "nao avancando"
CD.FOLLOW_STALL_REPATH_MS = 600  -- nao-avancando por este tempo no mesmo goal -> forca um re-path
-- (RC5) O A* async roda em UMA thread worker compartilhada. Num servidor dedicado carregado a busca indoor/inalcancavel
-- resolve mais devagar que o stall de 600ms acima, entao cancelar-e-reemitir (setData) ficava matando antes dela retornar
-- OU uma rota (por uma porta aberta) OU um Failed (para auto-abrir uma fechada) -> "cÃ£o nÃ£o entra em casa no MP, no SP
-- entra". Quando o dono esta PARADO (mesmo tile de goal) deixa a busca em voo cozinhar por este tempo antes de cancelar.
CD.FOLLOW_PATH_RESOLVE_MS = 1500
-- Backstop nunca-encalhar: quando o cachorro esta provadamente preso abaixo de TELEPORT_DIST (a engine reportou o path Failed
-- (shouldFollowWall) recentemente E o gap em linha reta nao encolheu por STUCK_TELEPORT_MS) encaixa ele atras do dono
-- (mesma primitiva que a leash >24 usa) e empurra a posicao aos clientes. Janela > FOLLOW_PATH_RESOLVE_MS para a busca
-- sempre ter a primeira chance (o cachorro prefere CAMINHAR; so teleporta quando genuinamente nao ha rota de animal).
CD.STUCK_TELEPORT_ENABLE = true
CD.STUCK_TELEPORT_MS = 3000           -- sem progresso de gap em linha reta por este tempo (+ inalcancavel confirmado) -> snap
CD.STUCK_RECENT_FAIL_MS = 2500        -- o Failed da engine (shouldFollowWall) deve ter disparado dentro desta janela
CD.STUCK_TELEPORT_COOLDOWN_MS = 3000  -- min real-ms entre stuck-snaps consecutivos
-- Suavidade MP (server-side): o PZ sincroniza a posicao do animal para clientes remotos so a ~1.25Hz (AnimalSynchronizationManager,
-- hardcoded 800/1000ms), entao o cachorro ativo visivelmente fica para tras de um dono em movimento. Forcamos pacotes de posicao fora de cadencia para
-- o cachorro ativo em MOVIMENTO via IsoAnimal.sendExtraUpdateToClients() para os clientes interpolarem rumo a alvos frescos. Server-only ->
-- beneficia TODO cliente, ate os nao-patcheados. No-op no SP (nao isServer). Ver pz-b42-animal-mp-position-sync.
CD.MP_DENSE_FOLLOW_SYNC = true   -- chave mestra do dense follow/combat position sync no MP
CD.DENSE_SYNC_MS = 50            -- min real-ms entre pacotes de posicao forcados por cachorro (~20Hz; o caminho A/B sem briga)
-- So forca o pacote fora de cadencia quando o cachorro de fato TRANSLADOU desde o ultimo push. isMoving() retorna true enquanto
-- o cachorro anda-no-lugar num node bloqueado (estrangulamento indoor / porta fechada), e um pacote redundante ali so
-- amplifica a Prediction em linha reta do cliente. Um delta de posicao real e o sinal honesto de "se moveu".
CD.DENSE_SYNC_MIN_MOVE = 0.02    -- min tiles movidos na janela DENSE_SYNC_MS para justificar um pacote forcado
-- (RC5b) Grade de navegacao nativa desatualizada. Num servidor DEDICADO, quando um cliente REMOTO abre uma porta que estava FECHADA no
-- boot do servidor, o servidor roda setOpen + RecalcAllWithNeighbours mas NAO PolygonalMap2.squareChanged (so o caminho host/direto
-- ToggleDoorActual o chama), entao a grade A* nativa que o cachorro usa mantem a porta BLOQUEADA pra sempre -> "porta aberta
-- passa, mas porta que estava fechada no boot o cao nunca reconhece". (Portas abertas no boot ja entram passaveis; SP/host usam
-- o caminho direto = funciona.) Fix: quando o path do cachorro falha perto de uma porta ABERTA, faz o que o caminho do host faz: chama
-- RecalcAllWithNeighbours(true) + setSquareChanged() no square da porta para invalidar a grade nativa.
CD.DOOR_NAV_REFRESH = true
CD.DOOR_REFRESH_SCAN = 3          -- raio (tiles) ao redor de um cachorro preso para procurar portas abertas-mas-desatualizadas para re-abencoar
CD.DOOR_REFRESH_SCAN_MS = 750     -- throttle do scan por cachorro enquanto o path continua falhando
CD.DOOR_REFRESH_COOLDOWN_MS = 8000 -- re-abencoa um dado square de porta no maximo nesta frequencia (a grade fica atualizada)
-- Render A* client-side em MP (dedicado). No modo dense-native o cliente remoto dead-reckon a posicao de um animal numa
-- linha RETA entre os pacotes autoritativos esparsos, entao uma rota curva (ao redor de moveis / por uma porta a varios
-- tiles) renderiza como o cachorro raspando uma parede. setHasObstacleOnPath(true) na copia remota vira o PROPRIO
-- remote-mover da engine (branch forcePathFinder de IsoPlayer.updateRemotePlayer) de dead-reckoning linear para A* CLIENT-SIDE
-- rumo ao alvo autoritativo, entao caminha o path curvo real. A flag e um setter publico real e NUNCA e
-- sobrescrita pelo sync de AnimalPacket, entao persiste. O server so diz a cada cliente proximo qual dog id e um seguidor
-- ativo; o cliente afirma a flag por tick. Pareia com FOLLOW_STREAM=false; e no-op quando o stream custom possui
-- o cachorro (aquele caminho dirige setX direto e o A* do cliente brigaria com ele). Ver companiondogs-custom-mp-position-replication.
CD.MP_CLIENT_ASTAR_RENDER = true
CD.ASTAR_FLAG_MS = 400   -- intervalo de re-sinal do server por cachorro (o cliente expira a flag apos ~3x isto sem refresh)
-- Watchdog de stuck: o A* do cliente (pfb2) anda-no-lugar (desliza parado) numa porta/estrangulamento quando seu path ate o
-- alvo autoritativo cruza uma porta fechada a varios tiles -> o cachorro "congela pensando" por ~10s. Quando um cachorro
-- flagueado para de AVANCAR por ASTAR_STUCK_MS LIBERAMOS a flag por ASTAR_STUCK_COOL_MS, para o sync nativo da engine
-- carrega-lo reto pelo estrangulamento (uma breve passagem, como dense-native puro), depois o A* retoma para o proximo
-- segmento curvo. No fim: "desliza um pouco + passa" em vez de "preso 10s deslizando".
CD.ASTAR_STUCK_MS = 600        -- flagueado-mas-nao-avancando por este tempo (ms) -> libera A* (deixa o sync nativo passar o estrangulamento)
CD.ASTAR_STUCK_COOL_MS = 1500  -- mantem o A* liberado por este tempo (ms) para o sync nativo carregar o cachorro pela porta
CD.ASTAR_STUCK_EPS = 0.01      -- min tiles de avanco por tick para contar como "movendo" (abaixo = deslizando parado)
-- Replicacao de follow MP custom (NOSSA PROPRIA, dribla o sync de animal step-and-snap a 1Hz da engine + sua Prediction
-- em linha reta que renderiza um path curvo indoor/de porta numa parede e depois snap). O server faz stream do transform
-- autoritativo do cachorro ativo a ~15Hz; cada cliente renderiza um path INTERPOLADO suave FOLLOW_INTERP_DELAY_MS no PASSADO
-- (nunca extrapolando). No-op no SP (gateado por server). Ver companiondogs-custom-mp-position-replication.
CD.FOLLOW_STREAM = false            -- chave mestra do stream de posicao de follow custom (OFF = dense-native A/B, sem briga com o engine-mover)
CD.FOLLOW_STREAM_MS = 50            -- min real-ms entre frames transmitidos por cachorro (~20Hz)
CD.FOLLOW_STREAM_RANGE = 40         -- so transmite enquanto algum player esta dentro deste numero de tiles (abaixo da virtualizacao ~52-60)
-- FOLLOW_INTERP_DELAY_MS: o cliente renderiza este tanto no PASSADO para que duas amostras reais sempre cerquem o ponto de render.
-- DEVE exceder o pior tempo de chegada entre frames (intervalo de envio + jitter), ou o renderTime ultrapassa a amostra mais nova,
-- o cliente da HOLD (congela) e depois pula quando o proximo frame chega = "stutter + teleporta um passo", na cadencia de envio.
-- ~3x o intervalo de envio da margem para um tick de server irregular / um pacote perdido. Aumente se ainda engasgar;
-- abaixe se o cachorro visivelmente atrasa o dono (150ms = ~0.5 tile atras numa corrida, imperceptivel).
CD.FOLLOW_INTERP_DELAY_MS = 150     -- renderiza este tanto no passado (>= ~3x FOLLOW_STREAM_MS para absorver o jitter de envio)
CD.FOLLOW_STREAM_TIMEOUT_MS = 500   -- cliente: sem frame por este tempo -> libera o cachorro de volta ao sync nativo da engine
CD.FOLLOW_STREAM_BUF = 20           -- tamanho do ring-buffer do cliente (amostras mantidas por cachorro; ~1s de historico a 20Hz)
-- Quando o buffer brevemente esvazia (renderTime alem da amostra mais nova, ex. um tick de server irregular / um pacote atrasado),
-- continua ao longo da velocidade do ultimo segmento por ESTA janela clampada em vez de congelar (o "stutter"), depois HOLD.
-- Curto + clampado para nunca correr numa parede como a predicao ilimitada da engine. 0 = HOLD puro (sem extrapolar).
CD.FOLLOW_EXTRAP_MAX_MS = 80
-- NOTA: um engine-redirect (escrever networkAi.predictionType/targetX para impedir o remote-mover da engine de brigar com
-- nosso setX) NAO e possivel neste build: Kahlua nao consegue indexar campos Java (nai.targetX lanca "index of non-table")
-- e NetworkCharacterAI nao tem metodos setter. Entao o proprio remote-mover da engine (IsoPlayer.updateRemotePlayer ->
-- moveToPoint rumo a realx/extrapolado, ~1Hz) roda inevitavelmente; com o stream custom ON o residual e um pequeno
-- empurrao por passo. A alternativa sem-briga e o dense NATIVE sync abaixo (FOLLOW_STREAM=false): deixa o mover da engine
-- perseguir um alvo FRESCO. Aumenta DENSE_SYNC_MS para esse A/B. Ver companiondogs-custom-mp-position-replication.
-- Suavidade MP: a engine so sincroniza a posicao de um animal para clientes remotos a cada 800-1000ms e o cliente
-- dead-reckon entre os pacotes (zombie/network/fields/character/Prediction). Um cachorro parado a forca (holdStill +
-- animalSpeed=0) envia uma predicao Static que o CONGELA nos clientes remotos ate o proximo pacote = "preso e depois
-- solavanco". Entao so paramos a forca (e suprimimos wanderIdle) quando o DONO esta genuinamente parado; enquanto o dono
-- se move o cachorro fica num estado de pathing (predicao Moving) para o cliente renderizar movimento continuo.
-- ownerStationary = o dono nao moveu mais que OWNER_STILL_EPS tiles por OWNER_STILL_MS real-ms. OWNER_STILL_MS
-- deve exceder a taxa de rede de posicao do player (~200ms, NetworkAIParams.CHARACTER_UPDATE_RATE_MS) para um dono ANDANDO
-- resetar a ancora antes de disparar; so um dono realmente parado acumula alem disso.
CD.OWNER_STILL_EPS = 0.10
CD.OWNER_STILL_MS = 450
-- Apenas cadencia de GAIT (velocidade visual das pernas). NOTA: no regime do node-mover (bPathfind forcado) a engine seta
-- a velocidade de TRAVEL = getDeferredMovement().getLength() = a magnitude do root-motion do Translation_Data no GLB, NAO
-- esta var (animalSpeed nao tem efeito de travel ali). Entao a SPEED real de walk/run do cachorro e ajustada escalando o
-- root motion do GLB. Magnitudes atuais: walk +1.427, run +3.252 (o pass de "+30% speed" de 2026-06-14 = o anterior
-- validado walk +1.098 / run +2.50 escalado x1.3, via _scale_rootmotion.py lendo o GLB deployado com um
-- fator POSITIVO 1.3, preserva o sinal +Z/yaw 180; equiv. fator PREYAW x-4.16 walk / x-2.76 run a partir do
-- base raccoon 0.343/1.18). Mantenha estas cadencias = as antigas 3.2/2.1 tambem escaladas x1.3 para a cadencia das pernas acompanhar o
-- travel (preserva a razao validada de foot-slide, tudo so se move proporcionalmente mais rapido).
CD.WALK_ANIM_SPEED = 4.16
CD.RUN_ANIM_SPEED = 2.73
-- Recuperacao de bond de trailer de animal (recoverTraileredDogs): por quantos ticks throttled um bond capturado no trailer e
-- mantido enquanto o cachorro esta irresoluvel (trailer levado a um chunk descarregado) antes do registro ser descartado. A
-- engine recarrega o cachorro no trailer COM seu ModData, entao uma re-captura acontece no reload antes de qualquer remocao.
CD.TRAILER_RECOVER_MAX_RETRIES = 5

-- Imunidade a roadkill de veiculo: companheiros sao PERMANENTEMENTE invenciveis (tickCompanionInvincible re-afirma). Roadkill e um
-- setHealth(0) instantaneo que so isInvincible() bloqueia; tambem congela hunger/thirst nativos, entao o loop de upkeep dirige os needs na mao.

-- Imunidade a fogo amigo de arma de fogo. setShootable(false) e driblado para armas MIRADAS (CombatManager.calculateHitListWeapon),
-- entao dentro deste raio o gun guard seta duas alavancas enquanto um player mira/atira:
--   * setInvulnerable (GOD_MODE): remove o cachorro da hit list (CombatManager.removeTargetObjects), mas e um NO-OP no
--     SP sem -debug (gate isCheatAllowed); cobre co-op/-debug.
--   * setIsInvincible (flag de IsoAnimal, nao um cheat): bloqueia setHealth a distancia no SP normal.
-- Ambos pausam needs, entao o guard fica CONTEXTUAL. (Cachorro nunca se vira contra o dono: goAttack e server-gated, false no SP.)
CD.GUN_RISK_RADIUS = 10
-- Histerese: mantem o gun guard ligado por este numero de ticks apos o player parar de mirar/atacar, para que o
-- tick de tiro real seja sempre coberto (a engine pode resolver o tiro um tick antes do nosso guard reativo re-scanear).
CD.GUN_GUARD_HOLD_TICKS = 12
-- Fallback do snap de passagem de bala (snapDogOffAimLine): quando o cao na linha de tiro nao cabe num tile lateral
-- livre, ele e snapado para este numero de tiles ATRAS do dono (oposto a mira). Nao ha mais steer continuo ao mirar.
CD.GUN_BEHIND_DIST = 2
-- O server nao consegue ler o input de mira de um player REMOTO (setIsAiming vem do input local), entao cada cliente da ping
-- ao server enquanto mira e o server trata aquele player como ameaca de arma de fogo por este numero de server ticks
-- apos o ultimo ping (o TTL se auto-cura se um ping/stop for perdido). DEVE exceder o intervalo de ping do cliente
-- (AIM_HINT_SEND_INTERVAL=45) com folga (fps do client e tps do server nao andam em lockstep): 120 = ~2s @ 60tps, ~2.7x o periodo do ping.
CD.GUN_AIM_HINT_TTL = 120
-- Passagem de bala no SP: no frame EXATO do disparo (evento OnWeaponSwingHitPoint, dispara um statement antes de a
-- engine montar a hit list em CombatManager) o cachorro na linha de mira e snapado pra fora dela, entao a engine monta
-- a lista sem ele e a bala segue pro zumbi atras (sem sangue/flinch/stress no cao). Um animal e alvo se a distancia
-- perpendicular dele ao raio de mira for < este valor (a engine usa BALLISTICS_CONTROLLER_DISTANCE_THRESHOLD=2.75; usamos
-- margem). So roda quando isGodMod() e false (SP): em co-op/-debug o GOD_MODE ja tira o cao da lista.
CD.GUN_PASSTHRU_MARGIN = 3.0

CD.STRIKE_DIST = 1.5
CD.HIT_DAMAGE = 0.6
-- Uma breed sub-letal (caramelo, breed canKill=false) consegue desgastar um zumbi + derruba-lo mas NUNCA da o
-- golpe final: seus golpes prendem o zumbi neste piso de health em vez de mata-lo (dono/breed forte termina).
CD.SUBLETHAL_HEALTH_FLOOR = 0.1
-- Ledger de dano do cao por zumbi (MP): se o mesmo zumbi nao leva golpe por este tempo (game-minutes), a entrada e
-- tratada como stale e RE-SEMEADA da vida atual (cobre zumbi que sarou/saiu e reuso de onlineID). Ver strikeExchange.
CD.ZDMG_STALE_MIN = 2
CD.HIT_COOLDOWN_MIN = 0.25
-- Knockdown agora e uma chance-por-golpe escalada pelo nivel de Combat (CD.knockdownChance); este cooldown e so o
-- piso anti-stunlock (min de golpes entre knockdowns = KNOCKDOWN_COOLDOWN_MIN / HIT_COOLDOWN_MIN).
CD.KNOCKDOWN_COOLDOWN_MIN = 0.5
CD.KNOCKDOWN_CHANCE_BASE = 0.10
CD.KNOCKDOWN_CHANCE_PER_LEVEL = 0.04
CD.KNOCKDOWN_CHANCE_CAP = 0.50
CD.RETREAT_HEALTH_FRAC = 0.1
CD.COMBAT_INITIATIVE = false
CD.ATTACK_COMMAND_WINDOW_MIN = 2
CD.ATTACK_COMMAND_RADIUS = 12
-- Backstop de inalcancabilidade do combate: cao PARADO, sem ganho de gap por este tempo (ou A* Failed
-- persistente), dropa o lock e poe o alvo num cooldown curto que o scan pula (nunca blacklist permanente).
CD.COMBAT_STALL_MS = 2500
-- Deslocamento liquido (tiles) do ancora de progresso que um cao perseguindo pode andar antes de ser tratado como
-- desvio real (re-ancora e reseta o timer). Um contorno legitimo de parede anda alem disso (e fecha o gap ao virar
-- a esquina); ficar dentro do raio sem nunca melhorar o gap = orbitando cerca -> o backstop dispara e dropa o alvo.
CD.COMBAT_STALL_RADIUS = 2.5
CD.COMBAT_UNREACH_MS = 12000
-- SP: o cao PODE pular cerca BAIXA (picket/trilho baixo, Hoppable*) em combate pra alcancar o zumbi (reusa o glide do
-- follow). Arame medio/corrente (TallHoppable), muro alto e servidor ficam SEM pular (o cao contorna). false = antigo.
CD.COMBAT_FENCE_HOP = true
-- Estende o pulo de cerca baixa em combate ao SERVIDOR (co-op/dedicado), reusando a maquinaria de MP do follow
-- (FENCE_HOP_MP + land-glide) com um land-glide de COMBATE (conduz na mao ate o zumbi, nao o dono). false = servidor
-- contorna a cerca em combate (comportamento antigo); SP nao e afetado por este flag.
CD.COMBAT_FENCE_HOP_MP = true
CD.COMBAT_STRESS_PER_STRIKE = 0.025
CD.COMBAT_STRESS_RECOVERY_PER_DAY = 12
CD.RETREAT_BACK_DIST = 3
-- Anti-flap do recuo (hoje so por vida baixa; o teto por quantidade de zumbis foi removido): uma vez recuando, o
-- cachorro continua por pelo menos este numero de game-minutes, para a condicao oscilando na borda nao ping-pong
-- ele para-frente-ao-zumbi e depois de-volta-atras-do-dono. Espelha a convencao de janela d.<x>UntilMin.
CD.RETREAT_MIN_DURATION_MIN = 0.5
CD.BITE_SOUND = "ZombieBite"
CD.BARK_SOUND = "CDDogBark"
CD.GROWL_SOUND = "CDDogGrowl"
CD.PET_SOUND = "CDDogPet"
CD.BARK_COOLDOWN_MIN = 2.5

-- Vira-latas selvagens latem ocasionalmente para atmosfera. Puramente cosmetico (client-side, sem addSound) entao NUNCA atrai zumbis; so cachorros nao-companheiros fazem, num cooldown por cachorro randomizado.
CD.WILD_BARK_ENABLED = true
CD.WILD_BARK_SOUND = "CDDogBarkAmbient"
CD.WILD_BARK_MIN_SEC = 120
CD.WILD_BARK_MAX_SEC = 260

-- Categoria de volume por som, para os sliders separados do settings (Latido/Efeitos/Ambiente). O fator final e
-- master * categoria (ver CD.Settings.getVolumeFactor). Mapeado por NOME para nao mudar o protocolo de som do co-op
-- (o broadcast so carrega o nome). Sons ausentes caem no master puro.
CD.SOUND_CATEGORY = {
    CDDogBark = "bark", CDDogGrowl = "bark",
    CDDogIdle = "bark", CDDogWhine = "bark", CDDogDeath = "bark", CDDogPickup = "bark",
    ZombieBite = "fx", CDDogEat = "fx", CDDogDrink = "fx", CDDogPet = "fx",
    CDDogBarkAmbient = "ambient",
}
CD.SOUND_CATEGORIES = { "bark", "fx", "ambient" }   -- ordem de exibicao no settings

-- Nossos sons de .ogg SOLTO. A engine os toca como canal cru no channelGroupInGameNonBankSounds, que NAO fica sob o
-- VCA "Settings_Sfx" -> o slider de efeitos do proprio jogo nao os atinge (jogador zerava o som do jogo e o cao
-- continuava no talo). CD.Settings.getVolumeFactor multiplica o fator destes pelo volume de efeitos do jogo. Sons de
-- banco (ZombieBite, PutItemInBag) ficam de fora: o VCA ja os atenua, aplicar de novo atenuaria duas vezes.
CD.SOUND_NONBANK = {
    CDDogBark = true, CDDogBarkAmbient = true, CDDogGrowl = true, CDDogWhine = true, CDDogIdle = true,
    CDDogPickup = true, CDDogPet = true, CDDogDeath = true, CDDogEat = true, CDDogDrink = true,
}
-- Sons com loop = true no script: o ref fica guardado (CD.soundRefs) pro slider valer AO VIVO neles, e nao so no proximo play.
CD.SOUND_LOOPED = { CDDogEat = true, CDDogDrink = true }
-- Vozes que a engine tocava por conta propria (dog_sounds) e ficavam FORA do volume/mute do mod. O idle passou a ser
-- dirigido pelo Lua (tickDogIdleVoice); as raras que sobraram levam um backstop de stopSoundByName quando mutadas.
CD.ENGINE_VOICES = { "CDDogWhine", "CDDogDeath", "CDDogPickup" }

-- Bufo/resfolego ocioso. Era o binding "idle" de dog_sounds (tocado pela ENGINE, logo imune ao mute); agora e emitido
-- pelo mod, no mesmo molde do latido ambiente, pra respeitar volume/mute. Vale pra todo cao nosso (companheiro e vadio).
CD.IDLE_VOICE_ENABLED = true
CD.IDLE_VOICE_SOUND = "CDDogIdle"
CD.IDLE_VOICE_MIN_SEC = 100
CD.IDLE_VOICE_MAX_SEC = 110

-- A anim de ataque e COSMETICA: node cdAttack MESCLADO no estado idle do animset do raccoon (um NOME de animset forkado nao carrega).
CD.ATTACK_ANIM_ENABLED = true
CD.ATTACK_ANIM_VAR = "cdAttack"
CD.ATTACK_ANIM_VARS = { "cdAttack", "cdAttack2", "cdAttack3" }   -- a mordida alterna aleatoriamente entre estes (cdAttack*.xml)
CD.ATTACK_ANIM_MS = 1200
-- Anim de comer: mesmo merge cosmetico (node cdEat no animset idle do raccoon, clip Rac_Eat enxertado nos GLBs do cachorro). Mantida
-- ON durante toda a permanencia "comendo" do auto-feed (bool sustentado, sem auto-clear) e limpa quando o cachorro sai da tigela.
CD.EAT_ANIM_VAR = "cdEat"
CD.DRINK_ANIM_VAR = "cdDrink"       -- clip de beber Rac_Drink (agua do bebedouro + agua na mao); cosmetico, mesmo padrao do cdEat
-- Anim de farejar: node cdSniff -> clip Rac_Sniff, sintetizado do Crouch_Idle do pacote lowpoly com a cabeca inclinada
-- pro chao + bob de focinho, e enxertado nos 4 GLBs (_dogrig/forge/_add_sniff_clip.py). Antes o faro reusava o cdEat,
-- e o cao parecia estar COMENDO a presa que ele so estava apontando.
CD.SNIFF_ANIM_VAR = "cdSniff"
CD.FEED_SOUNDS = { food = "CDDogEat", water = "CDDogDrink" }   -- loops (sounds_companiondogs.txt); campo de CD (nao local) pelo limite de 200 locals do Companion.lua
-- Anim de pulo do salto de cerca: node cdJump (AnimSets/raccoon/idle/cdJump.xml) toca o clip Rac_Jump (as rotacoes de perna do
-- Jump_run lowpoly enxertadas nos GLBs). Setada durante o glide (cachorro esta idle -> node da idle-layer a toca), limpa no pouso.
CD.JUMP_ANIM_VAR = "cdJump"
CD.HANDFEED_EAT_MS = 3000           -- por quanto tempo o cachorro toca o clip de comer ao ser alimentado na mao / domesticado (um pulso temporizado, server-driven)
-- Anim de descansar/deitar. O caminho nativo idleAction="sit" da engine NAO PODE ser usado num companheiro: BaseAnimalBehavior.checkSit
-- forca-limpa idleAction para qualquer animal com um attachedPlayer (decompilado), e o node vanilla idleSit re-entra e
-- snap sem descer -> flicker. Em vez disso dirigimos nossa PROPRIA var bool (cdRest) num node idle custom
-- (AnimSets/raccoon/idle/cdRest.xml, priority 10, clip Rac_IdleLyingDown) que a engine nunca toca: exatamente o
-- padrao de merge cosmetico do cdEat/cdAttack. Puramente cosmetico; o cachorro se deita (blend) enquanto parado em Stay ou postado numa
-- ancora de Guard sem ameaca, e se levanta (blend de volta) quando comandado/alertado.
CD.REST_ANIM_ENABLED = true
CD.REST_ANIM_VAR     = "cdRest"
CD.REST_DWELL_MIN    = 1.0          -- game-minutes calmamente parado antes de deitar (para nao cair a cada paradinha breve)
CD.REST_REASSERT_MIN = 2.0          -- re-broadcast periodico enquanto descansa (cobre um cliente entrando no render range no meio do descanso, MP)
-- Variacao de idle. A alternancia de idle nativa da engine (BaseAnimalBehavior.wanderIdle escolhe idle1/idle2) NUNCA dispara
-- num companheiro: wanderIdle retorna cedo em blockMovement (decompilado), que mantemos ON para parar o auto-wander, entao
-- idleEmoteChance/idleTypeNbr estao mortos para nossos cachorros. Dirigimos nos mesmos: quando alcancado e calmo o cachorro ocasionalmente
-- toca uma variante de idle-em-pe aleatoria (cdIdle2/cdIdle3 -> Rac_Idle02/03, ja nos GLBs) e depois volta ao idle base.
CD.IDLE_ANIM_ENABLED  = true
CD.IDLE_ANIM_VARS     = { "cdIdle2", "cdIdle3" }   -- variantes em-pe (cdIdle2/3.xml); o idle base e o clip padrao
CD.IDLE_ANIM_MS       = 4200        -- um ciclo COMPLETO do clip de idle (os clips Rac_Idle sao loops seamless de ~4.167s); uma
                                    -- janela menor cortava o clip no meio e snapava de volta ao base ("rapido, reseta no meio")
CD.IDLE_GAP_MIN_MS    = 9000        -- min real-ms entre variantes de idle
CD.IDLE_GAP_MAX_MS    = 22000       -- max real-ms entre variantes de idle
-- A animacao do player de agachar+mao "oferecer comida" (espelha a adef.feedByHandAnim do cachorro em DogDefinitions); reusada
-- ao encher a tigela para parecer alimentacao na mao.
CD.FEED_BY_HAND_ANIM = "AnimalLureLow"

CD.SENTINEL_RADIUS = 18
CD.SENTINEL_QUIET_RADIUS = 10
CD.SENTINEL_SEEN_DIST = 12
CD.SENTINEL_CLOSE_DIST = 6
CD.SENTINEL_ALARM_COUNT = 3
CD.SENTINEL_SCAN_INTERVAL_MIN = 0.5
CD.SENTINEL_AWARE_COOLDOWN_MIN = 20  -- espacamento dos rosnados; a mensagem fixada na cabeca agora carrega o aviso continuo de "detectando"
CD.SENTINEL_NOISE_COOLDOWN_MIN = 6
CD.SENTINEL_ALERT_HOLD_MIN = 2       -- mantem o alerta fixado por este tempo apos a ultima deteccao (anti-flicker em zumbis de borda/bugados)
CD.SENTINEL_ALARM_BARK_COOLDOWN_MIN = 20 -- latido de alarme audivel so na escalada, depois este espacamento
CD.SENTINEL_BARK_RADIUS = 16
CD.SENTINEL_BARK_VOLUME = 6

CD.UPKEEP_INTERVAL_MIN = 3
CD.LOYALTY_DECAY_PER_DAY = 12
CD.NEGLECT_MULT = 3
CD.LOYALTY_FLOOR = 30
CD.FEED_LOYALTY_GAIN = 15
CD.FEED_HUNGER_RESTORE = 0.5
CD.WATER_THIRST_RESTORE = 0.5
CD.FEED_HEALTH_BONUS = 0.10
-- Comida toxica (CD.isBadDogFood): alimentar com ela deixa o cachorro doente em vez de ajudar. Bond/trust sao perdidos (nunca
-- ganhos) e o stress sobe na hora; o custo de HEALTH NAO e instantaneo: enquanto intoxicado, a health do cachorro
-- sangra gradualmente (TOXIC_SICK_DRAIN_PER_DAY) mas nunca abaixo de TOXIC_SICK_HEALTH_FLOOR (uma refeicao ruim adoece,
-- nunca mata: so o descuido real mata, ver NEGLECT_HEALTH_LOSS_PER_DAY).
CD.TOXIC_LOYALTY_PENALTY = 20
CD.TOXIC_TRUST_PENALTY = 15
CD.TOXIC_STRESS = 0.3
-- Por quanto tempo (game-minutes) o cachorro fica "intoxicado" apos uma refeicao toxica: o moodle de doente no HUD aparece e o
-- dreno gradual de health roda por esta janela, depois e limpo em updateUpkeep. 120 = 2 game-hours (use 60 para 1h);
-- outra refeicao ruim renova a janela. O piso de 20% ainda o protege de morrer por mais que ele coma.
CD.TOXIC_SICK_MIN = 120
CD.TOXIC_SICK_HEALTH_FLOOR = 0.2   -- a intoxicacao dreni a health no maximo ate esta fracao do max (nunca letal)
-- Fracao de HP/dia perdida enquanto doente. Casada com a janela de 2h: ~0.8 perdido numa janela inteira sem tratamento, entao UMA refeicao
-- ruim afunda um cachorro com health cheia ate o piso de 20% no momento em que a doenca passa, depois ele se cura de volta.
CD.TOXIC_SICK_DRAIN_PER_DAY = 9.6
-- Alimentacao parcial: uma refeicao consome do item de comida so o quanto o cachorro precisa (hunger para um companheiro,
-- trust-para-domesticar para um vira-lata) e mantem o resto no inventario. Esta e a menor mordida possivel,
-- entao um cachorro ja satisfeito ainda custa um pouco de comida em vez de ser um reforco gratis de loyalty/health.
CD.FEED_MIN_BITE = 0.05
-- Needs manuais (porque a invencibilidade permanente congela o acumulo nativo de hunger/thirst e o dreno de HP da engine).
-- Os defaults espelham o ritmo nativo do caramelo adulto: hungerMultiplier 0.008 / thirstMultiplier 0.016 por game-HOUR
-- (DogDefinitions) x ~1.6 fator de gene de resistencia neutro x 24h. Ajuste aqui ao gosto; leia defensivamente no server.
CD.HUNGER_PER_DAY = 0.30
CD.THIRST_PER_DAY = 0.60
-- HP perdida por dia enquanto hunger OU thirst esta severa (> SEVERE_NEED), conduzindo a permadeath-por-descuido (o proprio
-- dreno > 0.8 da engine em AnimalData.updateHealth e suprimido por isInvincible). Aproximadamente simetrico com o regen (3.0).
CD.NEGLECT_HEALTH_LOSS_PER_DAY = 3.0
CD.SEVERE_NEED = 0.8
-- Limite de um unico passo de catch-up de upkeep: um cachorro estacionado longe do dono (fora do alcance do loop) pausa, e no
-- retorno do dono elapsedMin pode ser enorme, entao clampa para os needs alcancarem suavemente em vez de um pico instantaneo de fome.
CD.UPKEEP_MAX_CATCHUP_MIN = 360
CD.HUNGER_WARN = 0.6
CD.THIRST_WARN = 0.6
CD.STRESS_W_HUNGER = 0.5
CD.STRESS_W_THIRST = 0.3
CD.STRESS_W_HEALTH = 0.4
CD.STRESS_W_LOYALTY = 0.3
CD.STRESS_BARK_THRESHOLD = 0.5
CD.STRESS_PANIC_THRESHOLD = 0.80
-- Niveis graduados de exibicao de panico: 1=Nervoso (tambem o ponto de stress-bark), 2=Em panico (= panico funcional, para de lutar), 3=Apavorado.
CD.PANIC_TIER1_FRAC = 0.50
CD.PANIC_TIER2_FRAC = 0.80
CD.PANIC_TIER3_FRAC = 1.00
-- Auto-alimentacao a partir de um Bebedouro (Feeding Trough) colocado ("tigela de cachorro"). Um companheiro com fome/sede caminha ate um
-- bebedouro abastecido no alcance e come/bebe sozinho, drenando o estoque do bebedouro (o custo simetrico: mantenha-o cheio).
-- A alimentacao self-service sustenta apenas os NEEDS: nunca constroi loyalty (isso ainda exige sua mao/carinho), entao um
-- cachorro descuidado sobrevive na tigela mas continua desleal ate voce se reconectar. Bloqueada APENAS por um zumbi no alcance ou
-- por estar num veiculo; roda em qualquer estado/condicao (ate panico/desleal, comer e o que quebra um panico movido por needs).
CD.TROUGH_FEED_TRIGGER = 0.5        -- procura a tigela quando hunger OU thirst alcanca isto (0..1); abaixo do nivel de aviso 0.6 para reabastecer cedo
CD.TROUGH_FEED_RADIUS = 16          -- tiles varridos ao redor do cachorro buscando um bebedouro abastecido
CD.TROUGH_REACH_DIST = 0.85         -- distancia ao CENTRO DO TILE da tigela em/abaixo da qual o cachorro esta "na tigela" (medida com compensacao de centro em tryAutoFeed, NAO dist2D crua). 0.85 > a distancia maxima de 0.707 do canto do tile, entao qualquer ponto no tile da tigela conta e um tile adjacente (~1.0) nao. NAO o baixe de volta para valores de dist2D; o give-up por falta de progresso protege contra um tile bloqueado
CD.TROUGH_HUNGER_RESTORE = 0.5      -- hunger removida por refeicao (espelha a alimentacao na mao)
CD.TROUGH_THIRST_RESTORE = 0.5      -- thirst removida por bebida (espelha a agua na mao)
CD.TROUGH_WATER_PER_DRINK = 30      -- agua (unidades de fluido) drenada do bebedouro por bebida
CD.TROUGH_EAT_DWELL_MIN = 3         -- game-minutes que o cachorro permanece na tigela antes da refeicao se concretizar ("comendo" visivel)
-- Caminhada ate a tigela em MS REAIS (nao game-minutes: a caminhada acontece em tempo real, e game-min escala com o
-- day length do server, o que fazia o timeout estourar viagens legitimas e o cooldown durar minutos reais).
CD.TROUGH_SCAN_THROTTLE_MS = 2000    -- ms reais entre os (caros) scans de square por um bebedouro (so com fome/sede e sem alvo)
CD.TROUGH_REPATH_STALL_MS = 1200     -- sem progresso rumo a tigela por este tempo -> re-emite o path (respeitando FOLLOW_PATH_RESOLVE_MS)
CD.TROUGH_GIVEUP_STALL_MS = 15000    -- sem progresso NENHUM por este tempo -> tigela inalcancavel (murada / sem path), desiste
CD.TROUGH_RETRY_COOLDOWN_MS = 45000  -- apos desistir, retoma o comportamento normal e nao tenta a auto-alimentacao de novo por este tempo
CD.TROUGH_PROGRESS_EPS = 0.25        -- encurtar o gap ate a tigela nisto conta como progresso (minimo monotono, tolera contornos)
CD.FEED_COMMAND_YIELD_MIN = 5       -- apos um comando do dono (Follow/Stay/Guard/select), suspende a auto-alimentacao por este tempo para o cachorro obedecer AGORA
CD.FEED_MISS_TOLERANCE = 3          -- revalidacoes consecutivas falhas da tigela em cache (refreshes transitorios de square em co-op) toleradas antes de descartar o alvo; impede um cachorro estressado de oscilar entre comer e o branch de panico
-- O que um cachorro come de um bebedouro: espelha o eatTypeTrough do DogDefinitions (animalFeedType/foodType) MAIS DogFood
-- (o saco de racao seca `DogFoodBag` e latas abertas `DogfoodOpen`, FoodType=DogFood, o enchimento natural da tigela).
CD.TROUGH_EAT_TYPES = { AnimalFeed = true, Grass = true, Hay = true, Vegetables = true, Fruits = true, DogFood = true }
-- Itens de racao comestiveis por TYPE COMPLETO (a lata aberta + o saco seco tambem casam via FoodType=DogFood). A lata LACRADA
-- `Base.Dogfood` deliberadamente NAO esta aqui: e CantEat / 0-hunger, entao o cachorro so a destruiria inteira por uma
-- refeicao, entao o player deve abri-la (-> Base.DogfoodOpen, que dura ~3 refeicoes) primeiro.
CD.TROUGH_EAT_ITEMS = { ["Base.DogfoodOpen"] = true, ["Base.DogFoodBag"] = true }
-- Um item Food comum no bebedouro e drenado parcialmente por refeicao (nao removido inteiro), entao um saco grande (ex. DogFoodBag)
-- dura varias refeicoes em vez de sumir numa so. Este e o valor de hunger de RUNTIME do item (fracao 0..1, = o
-- HungerChange do script / 100, ex. DogFoodBag -60 -> -0.6), entao uma porcao de 0.1 = ~6 refeicoes de um saco.
CD.TROUGH_FOOD_PORTION = 0.1
-- Nossa PROPRIA tigela (um unico item colocavel que E a estacao de alimentacao; ver companiondogs_bowl.txt). Uma tigela largada
-- guarda seu estoque no ModData do item como um ORCAMENTO DE RESTAURACAO 0..100 = quanto de hunger/thirst (como 0-100% da
-- barra do cachorro) ela ainda pode devolver: cdFoodMeals (pontos de comida) OU cdWater (pontos de agua). Como o bebedouro vanilla, ela guarda
-- comida XOR agua (nunca ambos): os comandos de encher recusam o tipo oposto ate a tigela ser esvaziada (a opcao de contexto "Empty the bowl"
-- descarta o estoque para trocar). A auto-alimentacao varre tigelas largadas junto com bebedouros vanilla. Cada visita de
-- alimentacao restaura a quantia por visita (TROUGH_*_RESTORE) OU o que sobrar do orcamento, sacando essa mesma quantia da
-- tigela, entao UMA tigela cheia restaura ate 100 de hunger/thirst no total. Adicionar comida soma seu valor de hunger em pontos
-- (abs(getHungerChange)*100, ex. um DogFoodBag = 60); adicionar agua enche ate o max e drena um tanto da fonte.
CD.DISH_TYPE = "Base.CompanionDogsBowl"
CD.DISH_MAX_MEALS = 100            -- limite do orcamento de comida (0..100 = ate uma barra de hunger cheia por tigela). Adicionar e
                                   -- REJEITADO se um item de comida inteiro nao couber por completo, entao uma tigela quase cheia nunca
                                   -- engole silenciosamente o excedente de um pacote grande (um DogFoodBag = 60 pontos, cabe a partir do vazio)
CD.DISH_MAX_WATER = 100            -- limite do orcamento de agua (0..100 = ate uma barra de thirst cheia por tigela)
CD.DISH_WATER_SOURCE_DRAIN = 0.5   -- fluido removido da fonte de agua do player por "add water" na tigela (o caminho de agua na mao em Commands.lua drena um valor separado fixo de 0.2)
-- Fluidos cosmeticos que dirigem o visual AO VIVO da tigela (CompanionDogs_Util.refreshDishModel enche o FluidContainer do item
-- para refletir seu estoque; a engine renderiza WaterDish_Fluid tingido pela cor do fluido e re-snapshota ao vivo). Comida = um
-- fluido marrom, agua = um fluido azul, vazio = sem fluido (tigela cinza). Ambos sao Industrial (nao-agua) entao a tigela nunca e
-- uma fonte de agua. Definido em companiondogs_bowl.txt. A tigela guarda comida XOR agua, entao so um se aplica de cada vez.
CD.DISH_FLUID_FOOD = "CompanionDogsKibble"
CD.DISH_FLUID_WATER = "CompanionDogsBowlWater"
-- Scavenge virtual de caes NAO-companion (stray/selvagem/solto): needs sao nativas e >0.8 a engine drena a vida,
-- e o auto-feed de tigela e so de companion, entao um stray carregado por muito tempo morreria de fome. Ele "se vira
-- sozinho": roll por hora de jogo enquanto acima do trigger + piso forcado antes do dreno letal. Sempre ligado.
CD.STRAY_SCAVENGE_TRIGGER = 0.7   -- rola "achou comida/agua" quando hunger OU thirst alcanca isto (0..1)
CD.STRAY_SCAVENGE_FORCE = 0.78    -- piso garantido: scavenge incondicional antes do dreno letal de 0.8 da engine
CD.STRAY_SCAVENGE_CHANCE = 40     -- % de chance por hora de jogo enquanto acima do trigger
CD.STRAY_SCAVENGE_LEVEL = 0.15    -- necessidade apos o scavenge (nao zera: selvagem vive "meio faminto")
CD.STRESS_BARK_RADIUS = 30
CD.STRESS_BARK_VOLUME = 9
CD.STRESS_BARK_COOLDOWN_MIN = 60 -- bem menos latidos de stress; o badge de status fixado e a dica persistente (e so dispara em modo Alert completo)
CD.REFUSE_WARN_COOLDOWN_MIN = 3

CD.WOUNDED_ENTER_FRAC = 0.30
CD.WOUNDED_EXIT_FRAC = 0.40
CD.CRITICAL_ENTER_FRAC = 0.10
CD.CRITICAL_EXIT_FRAC = 0.20
CD.HEALTH_REGEN_PER_DAY = 3.0
CD.HEALTH_REGEN_NEED_MAX = 0.5

CD.PET_MOOD_RELIEF = 2
CD.PET_COOLDOWN_MIN = 90
CD.PET_STRESS_RELIEF = 0.10
CD.PET_LOYALTY_GAIN = 2
-- Calma temporaria do carinho: desconta do estresse TOTAL (CD.getStress) e decai linearmente ate a duracao.
CD.PET_CALM_RELIEF = 0.25
CD.PET_CALM_DURATION_MIN = 180
CD.SLEEP_MOOD_RELIEF = 2
CD.SLEEP_NEAR_RADIUS = 8

-- Buff "Bem Descansado": dormir perto do cao abre uma janela temporizada (ao acordar) que acalma e descansa
-- o dono. Aplicado no player LOCAL por tick (CD.applyRestedBuff) durante CD.restedBuffDurationMin. Rates GENTIS
-- de proposito (nao zera de uma vez; Endurance/stamina fica de fora p/ nao virar stamina infinita).
CD.RESTED_BUFF_DURATION_MIN = 120   -- 2h de jogo (sandbox RestedBuffHours sobrepoe)
CD.RESTED_PANIC_PER_MIN = 1.0       -- Panic (0-100) removido por game-minute
CD.RESTED_STRESS_PER_MIN = 0.006    -- Stress (0-1) removido por game-minute
CD.RESTED_FATIGUE_PER_MIN = 0.0025  -- Fatigue (0-1) removido por game-minute ("cansa mais devagar")
CD.RESTED_MOOD_PER_MIN = 1.0        -- Unhappiness+Boredom (0-100) removido por game-minute

-- Moodles do cachorro (conforto por proximidade). Enquanto um companheiro alimentado e leal esta perto, os moodles
-- Unhappy/Bored do dono aliviam continuamente e um icone de humor do companheiro aparece no HUD. Desenhado por um overlay
-- custom, NAO um MoodleType nativo (o MoodleType do B42 registra a partir de Lua mas Moodle.Update fixa tipos desconhecidos
-- no nivel 0 sem setter e MoodleTextureSet e hard-coded, entao a stack nativa nao consegue hospeda-lo).
CD.MOODLE_HAPPY_RADIUS = 8
CD.MOODLE_RELIEF_PER_MIN = 1.5     -- pontos (escala 0-100) removidos de Unhappiness+Boredom por game-minute
CD.MOODLE_TICK_MIN = 0.5           -- min game-minutes entre os ticks de humor (limita o scan de proximidade)
CD.MOODLE_ELAPSED_CAP = 10         -- limite de game-min decorridos aplicados por tick (protecao de fast-forward)
CD.MOODLE_NEGLECT_MAX = 0.75       -- cachorro com fome/sede demais (nativo 0-1) -> sem conforto (custo simetrico)
CD.COURAGE_PANIC_RELIEF_PER_MIN = 3 -- pontos de panico (0-100) eliminados por game-minute pelo humor Courage do pastor
CD.GOLDEN_XP_MULT = 1.2             -- multiplicador de XP do dono (Foraging/Trapping/Aiming) enquanto um golden alimentado e leal esta perto
CD.GOLDEN_FORAGE_VISION_EXTRA = 4   -- tiles extras de visao de foraging de um golden, alem do bonus universal de companheiro
-- Husky "Aquecido": o moodle aparece sempre que ha um husky cuidado por perto (como as outras racas). O cao vira uma
-- fonte de calor movel (IsoHeatSource, mesma API da lareira) no proprio tile SO quando o dono esta esfriando
-- (TEMPERATURE < ENTER), e a termorregulacao da engine o aquece (o moodle nativo de hipotermia cede sozinho);
-- reaquecido (>= EXIT, histerese) a fonte e removida pra nao superaquecer num dia quente. Temp branda vs a fogueira (35).
CD.HUSKY_WARMTH_TEMP = 28           -- temperatura-alvo da fonte de calor do husky (C); fogueira = 35
CD.HUSKY_WARMTH_RADIUS = 3          -- raio (tiles) da fonte de calor do husky
CD.HUSKY_COLD_ENTER = 37.0         -- temperatura corporal do dono (C) abaixo da qual a fonte de calor liga
CD.HUSKY_COLD_EXIT = 37.4          -- e acima da qual desliga (histerese, evita liga/desliga em loop)
CD.HUSKY_CARRY_BONUS = 2           -- bonus de peso maximo do dono (setMaxWeight) enquanto um husky cuidado esta perto (alivio de peso; base 8)
CD.HUSKY_ENDURANCE_PER_MIN = 0.001 -- endurance (0-1) reposto por game-minute pelo husky (folego SUTIL: ~0.67x a regen
                                   -- natural parado, ImobileEnduranceIncrease*48 ~= 0.0015; liquida de leve contra o exert() de correr)

CD.COMBAT_XP_PER_STRIKE = 1
CD.COMBAT_XP_PER_KILL = 5
CD.SCENT_XP_PER_DETECT = 1
CD.OBEDIENCE_XP_PER_CMD = 2
CD.OBEDIENCE_XP_COOLDOWN_MIN = 5
CD.SKILL_XP_RATE = 0.5

-- Caca assistida (a skill Hunt, "modo Hunt" opt-in por cachorro). Um companheiro em modo Hunt rastreia/aponta caca selvagem
-- (coelho/rato/raccoon/cervo), abate caca pequena no HUNT_SMALL_LEVEL e caca grande no HUNT_LARGE_LEVEL, creditando a
-- carcaca ao dono. Cacar e uma atividade rural/florestal (animais selvagens spawnam via AnimalZones; nenhum na cidade).
-- Custo simetrico: o cachorro deixa o lado do dono, a perseguicao late (pode atrair zumbis), caca grande pode feri-lo,
-- e cacar abre o apetite (HUNT_HUNGER_PER_HUNT). Os niveis gateiam a capacidade; o sandbox ajusta os limiares.
CD.HUNT_RADIUS = 16                 -- tiles varridos ao redor do cachorro por presa selvagem (escalado pelo nivel de Hunt)
CD.HUNT_MAX_LEASH = 32             -- desiste + volta ao dono se o cachorro chegar a esta distancia perseguindo (o backstop de "se perde")
CD.HUNT_SMALL_LEVEL = 3            -- nivel de Hunt para abater caca pequena (coelho/rato/camundongo/raccoon)
CD.HUNT_LARGE_LEVEL = 6           -- nivel de Hunt para engajar caca grande (cervo)
CD.HUNT_FETCH_LEVEL = 6           -- nivel de Hunt para trazer um abate de volta ao dono
CD.HUNT_AUTONOMY_LEVEL = 6        -- nivel de Hunt para caca autonoma (gateada por sandbox, off por padrao)
CD.HUNT_POINT_DIST = 4.5          -- quao perto o cachorro caminha de uma presa que ele apenas APONTA (abaixo do seu nivel de engajamento); longe o bastante pra leitura de "apontou de longe", nao de "colou no bicho"
CD.HUNT_POINT_REAPPROACH_DIST = 8 -- uma vez apontando+observando, a presa precisa vagar ESTA distancia antes do cachorro trotar ate ela de novo (histerese: fareja uma vez, segura, espera ela se afastar)
CD.FORAGE_ARRIVE_DIST = 2.5       -- raio de chegada num PONTO DE FORRAGEIO (nao numa presa): aqui o cao precisa marcar o lugar exato pra voce buscar, entao ele chega perto, ao contrario do aponto de caca
CD.HUNT_POINT_DWELL_MIN = 4       -- game-minutes que o cachorro observa agachado um ponto (abaixo do seu nivel de engajamento) antes de reporta-lo + voltar ao dono
CD.HUNT_STRIKE_DIST = 1.6         -- dist2D em/abaixo da qual o cachorro pode abater a presa (>diagonal 1.41 para uma presa diagonalmente adjacente ser alcancavel, nao perseguida pra sempre)
CD.HUNT_SCAN_THROTTLE_MIN = 0.25  -- game-minutes entre scans de animal selvagem; baixo para a presa ser adquirida rapido e preceder o foraging (scan so roda enquanto o cachorro nao tem alvo)
CD.HUNT_PREY_FORGET_MIN = 2       -- apos ver a presa pela ultima vez, impede o cachorro de sair vagando para forragear por este tempo (a presenca da presa suprime o forage)
CD.HUNT_GOING_TIMEOUT_MIN = 8     -- desiste de perseguir uma presa que nao consegue pegar/alcancar apos este tempo
CD.HUNT_RETRY_COOLDOWN_MIN = 20   -- apos desistir, retoma o follow normal e nao tenta cacar de novo por este tempo
CD.HUNT_XP_COOLDOWN_MIN = 3       -- min game-minutes entre concessoes de XP por deteccao de ponto
CD.HUNT_HIT_COOLDOWN_MIN = 0.25   -- min game-minutes entre golpes de caca
CD.HUNT_BARK_RADIUS = 16          -- raio de addSound de um latido de caca (atrai zumbis quando HuntBarkAttracts ligado)
CD.HUNT_BARK_VOLUME = 6
CD.HUNT_HUNGER_PER_HUNT = 0.06    -- hunger (0..1) que o cachorro ganha por abate / por golpe em cervo (ele abre o apetite)
CD.HUNT_DEER_WOUND = 0.12         -- health (0..1) que um cervo perde por golpe do cachorro (sub-letal; o dono termina)
CD.HUNT_DEER_WOUND_FLOOR = 0.08   -- o cachorro leva um cervo ate esta health, depois o SEGURA para o dono
CD.HUNT_DEER_HOLD_MIN = 20        -- game-minutes que o cachorro segura um cervo desgastado esperando o dono; passado isso, o cachorro termina o abate sozinho (o dono ainda e creditado)
CD.HUNT_DEER_DOG_HURT_CHANCE = 0.25 -- chance por golpe em cervo de o cervo ferir o cachorro de volta
CD.HUNT_DEER_DOG_STRESS = 0.15    -- combat-stress que o cachorro recebe de um contra-ataque do cervo
CD.HUNT_DEER_DOG_DAMAGE = 0.05    -- health (0..1) que o cachorro perde de um contra-ataque do cervo
CD.HUNT_XP_PER_DETECT = 1         -- XP de Hunt na borda de uma deteccao de ponto/rastro
CD.HUNT_XP_PER_SNIFF = 3          -- XP de Hunt quando o cao chega na presa e agacha pra farejar (uma vez por presa; o detect acima e so o "sentiu de longe")
CD.HUNT_XP_PER_OWNER_KILL = 3     -- XP de Hunt quando o dono mata caca selvagem perto do cachorro (a rampa de entrada L0->L1)
CD.HUNT_XP_PER_SMALL_KILL = 5     -- XP de Hunt quando o cachorro abate caca pequena
CD.HUNT_XP_PER_LARGE_HIT = 2      -- XP de Hunt por golpe do cachorro em caca grande
CD.HUNT_DELIVER_TIMEOUT_MIN = 5   -- desiste de levar um abate de volta ao dono apos este tempo (deixa onde morreu)
CD.HUNT_XP_RATE = 1.0             -- multiplicador extra no XP de caca (alem do SkillXPRate global)
CD.HUNT_FORAGE_RADIUS_BONUS = 12  -- tiles adicionados a visao de foraging do dono enquanto um cachorro de caca alimentado+leal esta perto (o
                                  -- faro do cachorro compensa o baixo skill de Foraging: a visao nativa nivel-0 e so ~3 tiles; a engine
                                  -- limita o total em 15, e effectiveForageBonus rampa isso de ~metade em Hunt L0 ate cheio em L10)
CD.HUNT_FORAGE_CATEGORY_BONUS = 0.5 -- fracao extra na deteccao de foraging de Animals/Insects/Tracks/DeadAnimals (o cachorro farreja a caca)
CD.HUNT_FORAGE_SCOUT_RADIUS = 20       -- tiles que o CLIENTE DO DONO busca ao redor do cachorro por um icone de forage de bicho JA EXISTENTE
CD.HUNT_FORAGE_SCOUT_TTL_MIN = 3       -- game-minutes que um alvo de forage enviado pelo cliente continua valido no server entre os heartbeats
CD.HUNT_FORAGE_SCOUT_CATEGORIES = { Animals = true, Insects = true, DeadAnimals = true } -- icones de bicho existentes ate os quais o faro do cachorro guia
CD.HUNT_FORAGE_SCOUT_PLACE_CATEGORIES = { Animals = true, Insects = true } -- so bichos vivos sao farejados e fixados num square
CD.HUNT_FORAGE_SCOUT_PLACE_RADIUS = 12 -- tiles ao redor do cachorro onde um bicho farejado e colocado (o cachorro guia ~ate aqui, nao em cima de voce)
CD.HUNT_FORAGE_SCOUT_ZONE_PROBE = 4    -- tiles que o cliente sonda por uma zona de forage proxima quando o proprio tile do cachorro nao tem nenhuma (bordas de estrada/campo)
CD.HUNT_FORAGE_SCOUT_ROLLS = 30        -- rolagens de bicho por scan; alto para a deteccao ser CONFIAVEL quando ha bichos (ainda gateada por tempo/estacao: insetos mudos de dia, sapos mais raros)
CD.HUNT_FORAGE_POINT_DWELL_MIN = 2.0   -- game-minutes que o cachorro segura um ponto de forage antes de reporta-lo + voltar ao dono
CD.HUNT_FORAGE_RETRY_COOLDOWN_MIN = 10 -- game-minutes de silencio apos cada achado (era 35; ESTE e o principal botao de "ele perde alguns": menor = acha com mais frequencia)
CD.HUNT_XP_PER_FORAGE_POINT = 1        -- XP de Hunt quando o cachorro escoteia uma area de forage (a rampa de entrada L0->L1 em florestas sem presa selvagem)

CD.URBAN_SPAWN_ENABLED = true
CD.STRAY_CHANCE_PER_HOUSE = 20
CD.POLICE_SHEPHERD_CHANCE = 20     -- % de chance de um predio policial/militar spawnar um Pastor Alemao de rua
CD.GOLDEN_STRAY_RARITY = 4         -- a rolagem por casa do golden = chance do caramelo / isto (aditivo, 4x mais raro)
CD.HUSKY_STRAY_RARITY = 8          -- rolagem por casa do husky (so no inverno) = chance do caramelo / isto (8x mais raro)
CD.HUSKY_PETVET_CHANCE = 10        -- % por predio de pet shop/veterinario spawnar um husky (escala com DogSpawnMultiplier)

function CD.sandbox()
    return SandboxVars and SandboxVars.CompanionDogs or nil
end

function CD.tameThreshold()
    local sv = CD.sandbox()
    return (sv and sv.TameThreshold) or CD.TAME_THRESHOLD
end

-- 0 = sem limite (padrao). Quando > 0, um player nao pode domesticar mais que esta quantidade de cachorros vinculados de uma vez.
function CD.maxCompanions()
    local sv = CD.sandbox()
    return (sv and sv.MaxCompanions) or 0
end

function CD.breedingEnabled()
    local sv = CD.sandbox()
    if sv == nil then return true end
    return sv.BreedingEnabled ~= false
end

-- Gestacao em minutos-jogo (sandbox GestationDays -> dias). gestEndMin e um stamp absoluto contra a idade do mundo,
-- entao a gestacao roda mesmo com a femea descarregada/virtualizada ou o dono offline (o relogio do mundo nao para).
function CD.gestationMinutes()
    local sv = CD.sandbox()
    local days = (sv and sv.GestationDays) or CD.GESTATION_DAYS
    return days * 24 * 60
end

function CD.breedCooldownMinutes()
    return (CD.BREED_COOLDOWN_DAYS or 7) * 24 * 60
end

-- Dias-de-jogo pra um filhote virar adulto (sandbox MaturityDays). A maturacao roda por timer de tempo-de-mundo
-- absoluto (d.bornMin + maturityMinutes), nao pela idade nativa, pra honrar este valor configuravel.
function CD.maturityDays()
    local sv = CD.sandbox()
    return (sv and sv.MaturityDays) or CD.MATURITY_DAYS
end

function CD.maturityMinutes()
    return CD.maturityDays() * 24 * 60
end

-- % por dia de um casal proximo (mesmo dono, adultos, elegiveis) conceber sozinho. Rolado por hora-de-jogo
-- (p_hora = isto/100/24). 0 = cruzamento passivo desligado (so a acao explicita/debug concebe).
function CD.breedChancePerDay()
    local sv = CD.sandbox()
    return (sv and sv.BreedChancePerDay) or CD.BREED_CHANCE_PER_DAY
end

function CD.breedLoyaltyFloor()
    return CD.TRUST_MAX * (CD.BREED_LOYALTY_FRAC or 0.6)
end

function CD.feedTrustGain()
    return CD.FEED_TRUST_GAIN
end

function CD.feedTrustPerHunger()
    return CD.FEED_TRUST_PER_HUNGER
end

function CD.combatEnabled()
    local sv = CD.sandbox()
    if sv == nil then return true end
    return sv.CombatEnabled ~= false
end

function CD.hitDamage()
    local sv = CD.sandbox()
    local mult = (sv and sv.DogDamageMultiplier) or 1
    return CD.HIT_DAMAGE * mult
end

function CD.knockdownEnabled()
    return true
end

function CD.knockdownCooldown()
    return CD.KNOCKDOWN_COOLDOWN_MIN
end

function CD.retreatHealthFrac()
    return CD.RETREAT_HEALTH_FRAC
end

function CD.runAnimSpeed()
    return CD.RUN_ANIM_SPEED
end

function CD.walkAnimSpeed()
    return CD.WALK_ANIM_SPEED
end

function CD.combatInitiative()
    return CD.COMBAT_INITIATIVE
end

function CD.attackCommandWindowMin()
    return CD.ATTACK_COMMAND_WINDOW_MIN
end

function CD.allowDebugSpawn()
    local sv = CD.sandbox()
    if sv == nil then return true end
    return sv.AllowDebugSpawn ~= false
end

-- Gate das ferramentas de debug do mod: sandbox AllowDebugSpawn ligado E ( admin no multiplayer | -debug no single-player ).
function CD.debugAllowed(player)
    if not CD.allowDebugSpawn() then return false end
    if isClient() or isServer() then
        local adm = false
        pcall(function()
            -- Sem player explicito (menu do client), resolve o player local e le o access level: e a mesma
            -- autoridade que o server confere e e confiavel no client do dedicado, ao contrario do isAdmin() (reserva).
            local p = player
            if not (p and p.getAccessLevel) then p = getPlayer() end
            if p and p.getAccessLevel then
                adm = string.lower(tostring(p:getAccessLevel() or "")) == "admin"
            else
                adm = isAdmin() == true
            end
        end)
        return adm
    end
    local dbg = false
    pcall(function() dbg = getDebug() == true end)
    return dbg
end

function CD.upkeepEnabled()
    local sv = CD.sandbox()
    if sv == nil then return true end
    return sv.UpkeepEnabled ~= false
end

function CD.loyaltyDecayPerDay()
    local sv = CD.sandbox()
    return (sv and sv.LoyaltyDecayPerDay) or CD.LOYALTY_DECAY_PER_DAY
end

function CD.loyaltyFloor()
    return CD.LOYALTY_FLOOR
end

function CD.feedHungerRestore()
    return CD.FEED_HUNGER_RESTORE
end

function CD.waterThirstRestore()
    return CD.WATER_THIRST_RESTORE
end

-- Override por player (ModData cdFeedTrigger do owner, setado pela janela de Settings do mod) tem prioridade sobre o
-- padrao de sandbox do servidor. owner pode ser nil (ex. lookup de default da UI) -> cai de volta para sandbox / constante.
function CD.troughFeedTrigger(owner)
    if owner then
        local md = owner:getModData()
        local v = md and md.cdFeedTrigger
        if type(v) == "number" then return v end
    end
    return CD.TROUGH_FEED_TRIGGER
end

function CD.troughFeedRadius()
    return CD.TROUGH_FEED_RADIUS
end

function CD.troughHungerRestore()
    return CD.TROUGH_HUNGER_RESTORE
end

function CD.troughThirstRestore()
    return CD.TROUGH_THIRST_RESTORE
end

function CD.huntEnabled()
    local sv = CD.sandbox()
    if sv == nil then return true end
    return sv.HuntEnabled ~= false
end

-- O resto dos botoes de caca sao FIXOS NO CODIGO (sem poluir o sandbox; so o HuntEnabled mestre e exposto). Ajuste as
-- consts CD.HUNT_* acima; os gates de nivel usam as consts *_LEVEL. Booleans: fetch/forage/forage-point on, autonomia off,
-- deer-hurts-dog + bark-attracts on.
function CD.huntRadius() return CD.HUNT_RADIUS end
function CD.huntMaxLeash() return CD.HUNT_MAX_LEASH end
function CD.huntSmallLevel() return CD.HUNT_SMALL_LEVEL end
function CD.huntLargeLevel() return CD.HUNT_LARGE_LEVEL end
function CD.huntFetchEnabled() return true end
function CD.huntFetchLevel() return CD.HUNT_FETCH_LEVEL end
function CD.huntAutonomyEnabled() return false end
function CD.huntAutonomyLevel() return CD.HUNT_AUTONOMY_LEVEL end
function CD.huntDeerCanHurtDog() return true end
function CD.huntDeerDogStress() return CD.HUNT_DEER_DOG_STRESS end
function CD.huntHungerPerHunt() return CD.HUNT_HUNGER_PER_HUNT end
function CD.huntBarkAttracts() return true end
function CD.huntXPRate() return CD.HUNT_XP_RATE end
function CD.huntForageBonusEnabled() return true end
function CD.huntForageRadiusBonus() return CD.HUNT_FORAGE_RADIUS_BONUS end
function CD.huntForageCategoryBonus() return CD.HUNT_FORAGE_CATEGORY_BONUS end
function CD.huntForagePointEnabled() return true end

function CD.feedHealthBonus()
    return CD.FEED_HEALTH_BONUS
end

function CD.woundedEnabled()
    return true
end

function CD.woundedEnterFrac()
    return CD.WOUNDED_ENTER_FRAC
end

function CD.woundedExitFrac()
    return CD.WOUNDED_EXIT_FRAC
end

function CD.criticalEnterFrac()
    return CD.CRITICAL_ENTER_FRAC
end

function CD.criticalExitFrac()
    return CD.CRITICAL_EXIT_FRAC
end

function CD.healthRegenPerDay()
    return CD.HEALTH_REGEN_PER_DAY
end

function CD.healthRegenNeedMax()
    return CD.HEALTH_REGEN_NEED_MAX
end

function CD.combatStressPerStrike()
    return CD.COMBAT_STRESS_PER_STRIKE
end

function CD.combatStressRecoveryPerDay()
    return CD.COMBAT_STRESS_RECOVERY_PER_DAY
end

function CD.stressBarkEnabled()
    return false
end

-- Um unico toggle de sandbox cobre todo barulho de cachorro que atrai zumbis (stress bark + alert bark). Os dois getters
-- nomeados abaixo sao wrappers finos mantidos para seus callers existentes.
function CD.noiseAttractsZombies()
    local sv = CD.sandbox()
    if sv == nil then return true end
    return sv.DogNoiseAttractsZombies ~= false
end

function CD.stressAttractsZombies()
    return CD.noiseAttractsZombies()
end

function CD.sentinelEnabled()
    local sv = CD.sandbox()
    if sv == nil then return true end
    return sv.SentinelEnabled ~= false
end

function CD.autoProtectEnabled()
    local sv = CD.sandbox()
    if sv == nil then return true end
    return sv.AutoProtectEnabled ~= false
end

function CD.sentinelBarkAttracts()
    return CD.noiseAttractsZombies()
end

function CD.sentinelRadius()
    return CD.SENTINEL_RADIUS
end

function CD.sentinelQuietRadius()
    return CD.SENTINEL_QUIET_RADIUS
end

function CD.bondingEnabled()
    local sv = CD.sandbox()
    if sv == nil then return true end
    return sv.BondingEnabled ~= false
end

function CD.petMoodRelief()
    return CD.PET_MOOD_RELIEF
end

function CD.petCooldownMin()
    return CD.PET_COOLDOWN_MIN
end

function CD.sleepMoodRelief()
    return CD.SLEEP_MOOD_RELIEF
end

function CD.sleepNearRadius()
    return CD.SLEEP_NEAR_RADIUS
end

function CD.restedBuffEnabled()
    local sv = CD.sandbox()
    if sv == nil then return true end
    return sv.RestedBuffEnabled ~= false
end

function CD.restedBuffDurationMin()
    local sv = CD.sandbox()
    local h = sv and sv.RestedBuffHours
    if type(h) ~= "number" or h <= 0 then return CD.RESTED_BUFF_DURATION_MIN end
    return h * 60
end

function CD.dogMoodlesEnabled()
    return true
end

function CD.moodleHappyRadius()
    return CD.MOODLE_HAPPY_RADIUS
end

function CD.moodleReliefPerMin()
    return CD.MOODLE_RELIEF_PER_MIN
end

function CD.couragePanicReliefPerMin()
    return CD.COURAGE_PANIC_RELIEF_PER_MIN
end

function CD.goldenXPMult()
    return CD.GOLDEN_XP_MULT
end

function CD.goldenForageVisionExtra()
    return CD.GOLDEN_FORAGE_VISION_EXTRA
end

function CD.skillsEnabled()
    local sv = CD.sandbox()
    if sv == nil then return true end
    return sv.SkillsEnabled ~= false
end

function CD.genomeEffects()
    return true
end

function CD.skillXPRate()
    local sv = CD.sandbox()
    return (sv and sv.SkillXPRate) or CD.SKILL_XP_RATE
end

function CD.showNameTags()
    local sv = CD.sandbox()
    if sv == nil then return true end
    return sv.ShowNameTags ~= false
end

function CD.showMapMarker()
    local sv = CD.sandbox()
    if sv == nil then return true end
    return sv.ShowMapMarker ~= false
end

-- Preferencia de CLIENT por player (nao sandbox): se mostra os halos flutuantes do cachorro + as linhas de status do
-- name-tag. Respaldada por CompanionDogs_settings.ini via CD.Settings; so lida no client
-- (Client.lua / NameTags.lua). CD.Settings e nil num servidor dedicado -> padrao mostrado.
function CD.showNotifications()
    if CD.Settings and CD.Settings.getShowTexts then return CD.Settings.getShowTexts() end
    return true
end

function CD.urbanSpawnEnabled()
    local sv = CD.sandbox()
    if sv == nil then return CD.URBAN_SPAWN_ENABLED end
    return sv.UrbanSpawnEnabled ~= false
end

-- Toggle de modo facil (padrao off): torna todo cachorro NAO-companheiro (de rua / selvagem / liberado) imatavel, para que um vira-lata
-- que voce encontre seja sempre seguro de domesticar. Aplicado em runtime (os valores de durabilidade da definicao sao lidos no boot, antes
-- de SandboxVars existir) pelas varreduras tickCompanionInvincible / tickCompanionFire. Companheiros ja sao invenciveis de qualquer forma.
function CD.wildDogsInvincible()
    local sv = CD.sandbox()
    if sv == nil then return false end
    return sv.WildDogsInvincible == true
end

-- Toggle (padrao ON): as mortes de zumbi feitas pelo cao tambem somam ao contador nativo "Zombie Kills" do dono
-- (tela de info do personagem). O contador por-cao (cabecalho da janela) roda sempre, independente disto.
function CD.countDogKillsForPlayer()
    local sv = CD.sandbox()
    if sv == nil then return true end
    return sv.CountDogKillsForPlayer ~= false
end

-- Regra de servidor MP (padrao ON): com o dono OFFLINE o servidor guarda o cao fora do mundo (registro em ModData
-- global) e o devolve na reconexao. Ver tickCompanionInvincible / CD.recoverOfflineStashes em Companion.lua.
-- `~= false` (padrao default-true) tambem liga em save de servidor existente, onde a chave nova nao esta baked.
function CD.despawnOnOwnerOffline()
    local sv = CD.sandbox()
    if sv == nil then return true end
    return sv.DespawnOnOwnerOffline ~= false
end

-- Um unico botao de sandbox escala o spawn natural das tres breeds (caramelo / golden / shepherd); as taxas BASE por breed
-- sao fixas no codigo (constantes acima), preservando suas proporcoes. 0 = sem spawn natural.
function CD.dogSpawnMultiplier()
    local sv = CD.sandbox()
    local m = sv and sv.DogSpawnMultiplier
    if m == nil then m = 1.0 end
    if m < 0 then m = 0 end
    return m
end

function CD.strayChancePerHouse()
    return CD.STRAY_CHANCE_PER_HOUSE * CD.dogSpawnMultiplier()
end

function CD.policeShepherdChance()
    return CD.POLICE_SHEPHERD_CHANCE * CD.dogSpawnMultiplier()
end

-- Quantas vezes mais raro que o caramelo o golden e (sua propria rolagem por casa, aditiva). Fixo no codigo, >= 1.
function CD.goldenStrayRarity()
    local r = CD.GOLDEN_STRAY_RARITY
    if r < 1 then r = 1 end
    return r
end

-- Chance de spawn por casa do golden, atrelada a do caramelo para acompanhar qualquer mudanca de StrayChancePerHouse.
function CD.goldenStrayChance()
    return CD.strayChancePerHouse() / CD.goldenStrayRarity()
end

-- True so na estacao de inverno (SEASON_WINTER=5 da engine). O husky de rua so aparece ao ar livre no frio.
function CD.isWinter()
    local id = -1
    pcall(function() id = getClimateManager():getSeasonId() end)
    if id < 0 then pcall(function() id = ClimateManager.getInstance():getSeasonId() end) end
    return id == 5
end

-- Chance de spawn por casa do husky (so roda no inverno), atrelada a do caramelo (mais raro que o golden).
function CD.huskyStrayChance()
    local r = CD.HUSKY_STRAY_RARITY
    if not r or r < 1 then r = 8 end
    return CD.strayChancePerHouse() / r
end

-- Chance por predio de pet shop/veterinario spawnar um husky (sem gate de estacao; o local em si e fonte de caes).
function CD.huskyPetVetChance()
    return (CD.HUSKY_PETVET_CHANCE or 10) * CD.dogSpawnMultiplier()
end

-- ===== Registry de spawn selvagem (contrato de addon) =============================================
-- Classes de predio: name -> { match=fn(def)->bool, exclusive, skipUrbanGate }. As 3 classes base
-- (house/police/petvet, registradas em Spawn.lua) sao EXCLUSIVAS entre si na ordem de registro
-- (preserva o elseif historico); classes de addon aditivas (exclusive=false) casam por cima delas.
-- skipUrbanGate deixa a classe rolar em chunk nao-urbano (ex.: industrial fora de TownZone).
CD.BuildingClasses = {}
CD.BuildingClassOrder = {}
function CD.registerBuildingClass(name, matchFn, opts)
    if not name or type(matchFn) ~= "function" or CD.BuildingClasses[name] then return end
    opts = opts or {}
    CD.BuildingClasses[name] = {
        match = matchFn,
        exclusive = opts.exclusive == true,
        skipUrbanGate = opts.skipUrbanGate == true,
    }
    CD.BuildingClassOrder[#CD.BuildingClassOrder + 1] = name
end

-- Passos de spawn 1-por-predio, rolados na ordem da lista: { id, class, chance=fn()->pct,
-- suffix (parte da chave do store: NUNCA mudar num save vivo), breed (nil = caramelo via
-- chooseStrayKind), gate=fn()->bool opcional (ex.: inverno) }. A classe e resolvida na hora do
-- roll (a ordem de load entre mods nao garante que ela exista no registro do passo).
CD.StraySpawnDefs = {}
function CD.registerStraySpawns(list)
    if type(list) ~= "table" then return end
    for _, sdef in ipairs(list) do
        if sdef.id and sdef.class and type(sdef.chance) == "function" then
            CD.StraySpawnDefs[#CD.StraySpawnDefs + 1] = sdef
        end
    end
end

-- Passos base. Suffixes historicos (nil, |g, |h, |hv) preservados: sao chave do store persistido.
CD.registerStraySpawns({
    { id = "caramelo", class = "house",  chance = CD.strayChancePerHouse },
    { id = "golden",   class = "house",  chance = CD.goldenStrayChance,    suffix = "|g",  breed = "retriever" },
    { id = "gs",       class = "police", chance = CD.policeShepherdChance, breed = "germanshepherd" },
    { id = "huskyw",   class = "house",  chance = CD.huskyStrayChance,     suffix = "|h",  breed = "husky", gate = CD.isWinter },
    { id = "huskypv",  class = "petvet", chance = CD.huskyPetVetChance,    suffix = "|hv", breed = "husky" },
})

-- "Este square esta numa town/city": o gate que mantem vira-latas caramelo urbanos (nao em cabanas de floresta). O
-- getZoneType() sozinho e nao-confiavel em squares de INTERIOR de predio (frequentemente sem tag numa cidade grande, o que fazia
-- chunks residenciais inteiros lerem como nao-urbanos e abortarem o spawn), entao isto tambem aceita os outros sinais de town
-- da engine (zona de densidade de zumbi, zona de loot, regiao de mapa nomeada). Chame-o num square OUTDOOR (rua/quintal) quando
-- possivel, esses carregam o zoneamento que os interiores nao tem.
-- A nivel de modulo (nao um closure por chamada) para isUrbanSquare nao alocar um por square; isto roda em cada
-- tile livre de cada chunk durante o scan de spawn. PRECISA ser declarado antes de isUrbanSquare (uma ref nil adiantada
-- faria pcall(nil) falhar e quebrar silenciosamente todo spawn urbano). Retorna um boolean real.
local function checkUrban(sq)
    local zt = sq.getZoneType and sq:getZoneType()
    if zt == "TownZone" or zt == "TownZones" or zt == "TrailerPark" then return true end
    local sz = sq.getSquareZombiesType and sq:getSquareZombiesType()
    if sz ~= nil and sz ~= "" and sz ~= "Forest" and sz ~= "DeepForest" then return true end
    local lz = sq.getLootZone and sq:getLootZone()
    if lz ~= nil and lz ~= "" then return true end
    local rg = sq.getSquareRegion and sq:getSquareRegion()
    if rg ~= nil and rg ~= "" and rg ~= "General" then return true end
    return false
end

function CD.isUrbanSquare(sq)
    if not sq then return false end
    local ok, urban = pcall(checkUrban, sq)
    return ok and urban == true
end