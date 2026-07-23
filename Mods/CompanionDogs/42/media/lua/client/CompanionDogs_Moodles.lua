require "ISUI/ISUIElement"

local CD = CompanionDogs

-- "Moodles" de cão: um ícone de conforto no HUD (e efeito contínuo) mostrado enquanto um companion está perto.
-- Isto é um overlay CUSTOM, NÃO um MoodleType nativo. A engine do B42 expõe MoodleType.register(id)
-- para o Lua, mas um tipo registrado por mod é inútil: Moodle.Update() fixa tipos desconhecidos no nível 0 sem
-- setter público, o mapa de ícones do MoodleTextureSet é hard-coded (sem textura -> NPE), e getGoodBadNeutral
-- força um tint vermelho "bad". Então desenhamos nosso próprio ícone estilo moodle e aplicamos o efeito nós mesmos.
-- O registry é genérico para que breeds futuros se encaixem (ex.: Husky "Warmed"): uma imagem base de cão + um badge.

CD.DogMoodles = CD.DogMoodles or {}

local function dogIsCaredFor(dog)
    -- Custo simétrico: um cão faminto/desidratado não dá conforto.
    local h, t = 0, 0
    pcall(function() h = dog:getHunger() or 0 end)
    pcall(function() t = dog:getThirst() or 0 end)
    return h < CD.MOODLE_NEGLECT_MAX and t < CD.MOODLE_NEGLECT_MAX
end

CD.DogMoodles[#CD.DogMoodles + 1] = {
    id = "breedHappy",
    breed = "caramelo", -- SOMENTE o caramelo ativa este mood específico; breeds futuros ganham o seu próprio
    nameKey = "IGUI_PD_Moodle_BreedHappy",
    descKey = "IGUI_PD_Moodle_BreedHappy_desc",
    icon = "CD_Moodle_BreedHappy",  -- ícone baked autocontido (fallback se o frame nativo estiver indisponível)
    fg = "CD_MoodHappyFG",          -- cão+badge transparente desenhado SOBRE o frame nativo do moodle
    -- retorna o nível do moodle (0 = inativo). breedHappy é um simples on/off (nível 1) por enquanto.
    condition = function(player, dog)
        if not dog or dog:isDead() then return 0 end
        if CD.getBreed(dog) ~= "caramelo" then return 0 end
        if CD.isDisloyal(dog) then return 0 end
        if CD.isSick(dog) then return 0 end -- um cão desmaiando por uma refeição tóxica não pode te confortar (o moodle de doente aparece no lugar)
        if not dogIsCaredFor(dog) then return 0 end
        return 1
    end,
    -- conforto contínuo: reduz Unhappiness + Boredom (escala 0-100) proporcional aos game-minutes decorridos.
    apply = function(player, dog, elapsedMin)
        CD.relieveMood(player, CD.moodleReliefPerMin() * elapsedMin)
    end,
}

-- "Courage" do Pastor Alemão: um cão de guarda corajoso ao seu lado dissipa o medo -> o Panic do dono diminui
-- continuamente (em vez do Unhappiness/Boredom do Caramelo). Travado por breed, então substitui limpo
-- o "Good Company" para pastores. Panic é um campo nativo de Stats (0-100); o dirigimos diretamente.
CD.DogMoodles[#CD.DogMoodles + 1] = {
    id = "courage",
    breed = "germanshepherd",
    nameKey = "IGUI_PD_Moodle_GSCourage",
    descKey = "IGUI_PD_Moodle_GSCourage_desc",
    icon = "CD_Moodle_GSCourage",
    fg = "CD_MoodCourageFG",
    tintR = 0.93, tintG = 0.70, tintB = 0.20, -- frame âmbar de "courage" (o do caramelo continua verde)
    condition = function(player, dog)
        if not dog or dog:isDead() then return 0 end
        if CD.getBreed(dog) ~= "germanshepherd" then return 0 end
        if CD.isDisloyal(dog) then return 0 end
        if CD.isSick(dog) then return 0 end -- intoxicado: sem courage enquanto o cão está doente (o moodle de doente aparece no lugar)
        if not dogIsCaredFor(dog) then return 0 end
        return 1
    end,
    apply = function(player, dog, elapsedMin)
        local n = CD.couragePanicReliefPerMin() * elapsedMin
        if n <= 0 then return end
        pcall(function()
            player:getStats():remove(CharacterStat.PANIC, n) -- Panic é um CharacterStat (0-100), sem getPanic/setPanic
        end)
    end,
}

-- "Keen Nose" do Golden: o auxílio de faro de um caçador/retriever. Enquanto um golden próximo, alimentado e leal
-- estiver por perto, o dono aprende Foraging/Trapping/Aiming mais rápido (um multiplicador de XP persistente, setado
-- enquanto ativo e limpo na desativação) e forrageia mais longe (o raio de visão extra vive em CompanionDogs_Forage.lua).
-- Travado por breed, então substitui limpo o "Good Company" para goldens.
-- Dois fatos da engine dirigem a implementação (CFR-verificados): (1) o multiplicador é por personagem e
-- PERSISTENTE, então deve ser limpo na borda active->inactive ou o boost permanece sem o cão;
-- (2) a engine mantém UM multiplicador por perk e os skill books usam o mesmo slot, então nunca baixamos um
-- multiplicador de book maior (max vence, sem empilhar) e só o limpamos de volta quando o valor vivo é o nosso.
-- Chamamos o método de XP no player LOCAL diretamente (não o addXpMultiplier global, que é no-op num
-- client MP): o XP de foraging/trapping/aiming é concedido client-side, então o multiplicador pertence aqui.
local goldenPerks
local function resolveGoldenPerks()
    if goldenPerks ~= nil then return goldenPerks end
    goldenPerks = {}
    if Perks then
        if Perks.PlantScavenging then goldenPerks[#goldenPerks + 1] = Perks.PlantScavenging end -- "Foraging" (forrageamento)
        if Perks.Trapping then goldenPerks[#goldenPerks + 1] = Perks.Trapping end
        if Perks.Aiming then goldenPerks[#goldenPerks + 1] = Perks.Aiming end
    end
    return goldenPerks
end

local function applyGoldenXP(player)
    if not player then return end
    local perks = resolveGoldenPerks()
    if #perks == 0 then return end
    local mult = CD.goldenXPMult()
    local maxLvl = CD.SKILL_MAX_LEVEL or 10
    pcall(function()
        local xp = player:getXp()
        for _, p in ipairs(perks) do
            if xp:getMultiplier(p) < mult then xp:addXpMultiplier(p, mult, 1, maxLvl) end -- nunca baixa um mult de book maior
        end
    end)
end

local function clearGoldenXP(player)
    if not player then return end
    local perks = resolveGoldenPerks()
    if #perks == 0 then return end
    local mult = CD.goldenXPMult()
    local maxLvl = CD.SKILL_MAX_LEVEL or 10
    pcall(function()
        local xp = player:getXp()
        for _, p in ipairs(perks) do
            local cur = xp:getMultiplier(p)                                       -- 0 = nenhum, >1 turbina no AddXP
            if cur > 0 and cur <= mult then xp:addXpMultiplier(p, 1.0, 1, maxLvl) end -- limpa SO o nosso, deixa os books
        end
    end)
end

CD.DogMoodles[#CD.DogMoodles + 1] = {
    id = "keennose",
    breed = "retriever",
    nameKey = "IGUI_PD_Moodle_GoldenNose",
    descKey = "IGUI_PD_Moodle_GoldenNose_desc",
    icon = "CD_Moodle_GoldenNose",
    fg = "CD_MoodGoldenNoseFG",
    tintR = 0.56, tintG = 0.80, tintB = 0.26, -- frame verde "forrageador" (distinto do verde do caramelo / âmbar do GS)
    condition = function(player, dog)
        if not dog or dog:isDead() then return 0 end
        if CD.getBreed(dog) ~= "retriever" then return 0 end
        if CD.isDisloyal(dog) then return 0 end
        if CD.isSick(dog) then return 0 end
        if not dogIsCaredFor(dog) then return 0 end
        return 1
    end,
    apply = function(player, dog, elapsedMin)
        applyGoldenXP(player)
    end,
    onDeactivate = function(player)
        clearGoldenXP(player)
    end,
}

-- "Aquecido" do Husky: um husky vivo, alimentado e leal por perto te mantem aquecido e ajuda a carregar peso.
-- O moodle aparece SEMPRE que ha um husky cuidado por perto (como as outras racas), nao so quando ja esta frio.
-- Dois efeitos: (1) alivio de peso, sempre ativo enquanto o moodle esta on (bonus de maxWeight do dono); (2) calor
-- diegetico: o cao vira uma fonte de calor MOVEL (IsoHeatSource, a mesma API da lareira) no proprio tile, mas SO
-- enquanto o dono esta de fato esfriando (TEMPERATURE < ENTER, desliga ao reaquecer >= EXIT, histerese), pra nao
-- superaquecer num dia quente. Travado por breed. maxWeight nao e serializado (a Forca o recomputa em runtime),
-- entao um relog auto-cura sem drift do bonus.
-- Estado per-player: fonte de calor ativa, tile dela, bonus de carga aplicado e o flag de histerese de frio.
local huskyHeat = {}        -- pn -> IsoHeatSource ativo
local huskyHeatTile = {}    -- pn -> "x,y,z" do ultimo registro (re-registra so quando o cao muda de tile)
local huskyCarry = {}       -- pn -> bonus de maxWeight aplicado (para restaurar)
local huskyWarm = {}        -- pn -> true enquanto na janela de frio (histerese ENTER/EXIT)

local function bodyTemp(player)
    local t = 37
    pcall(function() t = player:getStats():get(CharacterStat.TEMPERATURE) end)
    return t or 37
end

local function clearHuskyHeat(player, pn)
    local hs = huskyHeat[pn]
    if hs then
        pcall(function() getCell():removeHeatSource(hs) end)
        huskyHeat[pn] = nil; huskyHeatTile[pn] = nil
    end
    local bonus = huskyCarry[pn]
    if bonus and player then
        -- devolve o bonus de peso maximo (getMaxWeight e o que a checagem de excesso de peso usa; o inventario do
        -- personagem ignora o capacity proprio e le o maxWeight do personagem, verificado no decomp).
        pcall(function() player:setMaxWeight(player:getMaxWeight() - bonus) end)
        huskyCarry[pn] = nil
    end
    huskyWarm[pn] = nil
end

CD.DogMoodles[#CD.DogMoodles + 1] = {
    id = "warmed",
    breed = "husky",
    nameKey = "IGUI_PD_Moodle_Warmed",
    descKey = "IGUI_PD_Moodle_Warmed_desc",
    icon = "CD_Moodle_Warmed",
    fg = "CD_MoodWarmedFG",
    tintR = 0.95, tintG = 0.52, tintB = 0.20, -- frame quente/laranja (distinto dos verdes/ambar)
    condition = function(player, dog)
        if not dog or dog:isDead() then return 0 end
        if CD.getBreed(dog) ~= "husky" then return 0 end
        if CD.isDisloyal(dog) then return 0 end
        if CD.isSick(dog) then return 0 end
        if not dogIsCaredFor(dog) then return 0 end
        return 1 -- visivel sempre perto do husky cuidado (como as outras racas); o calor so atua quando ha frio
    end,
    apply = function(player, dog, elapsedMin)
        local pn = player:getPlayerNum()
        -- alivio de peso: bonus de peso maximo do dono (aplicado uma vez enquanto ativo), o que reduz o moodle
        -- nativo de excesso de peso (HEAVY_LOAD) e sua lentidao -> "o husky carrega um pouco do seu peso".
        if not huskyCarry[pn] then
            local bonus = CD.HUSKY_CARRY_BONUS or 2
            local ok = pcall(function() player:setMaxWeight(player:getMaxWeight() + bonus) end)
            if ok then huskyCarry[pn] = bonus end
        end
        -- folego: o husky te mantem em ritmo. Repoe um pouco de endurance (0-1) por game-minute; a engine drena via
        -- exert() ao correr/lutar, entao isto liquida contra o dreno -> o dono cansa mais devagar (clamp 1.0 na engine).
        local endN = (CD.HUSKY_ENDURANCE_PER_MIN or 0.02) * (elapsedMin or 0)
        if endN > 0 then pcall(function() player:getStats():add(CharacterStat.ENDURANCE, endN) end) end
        -- calor: o cao vira fonte de calor movel SO enquanto o dono esta esfriando (histerese ENTER/EXIT), pra nao
        -- superaquecer num dia quente; reaquecido, remove a fonte (mantendo o alivio de peso ate o moodle desligar).
        local t = bodyTemp(player)
        if huskyWarm[pn] then
            if t >= (CD.HUSKY_COLD_EXIT or 37.4) then huskyWarm[pn] = false end
        else
            if t < (CD.HUSKY_COLD_ENTER or 37.0) then huskyWarm[pn] = true end
        end
        if huskyWarm[pn] and dog and dog:getSquare() then
            -- fonte de calor no tile do cao. Guarda `dog and dog:getSquare()`: o apply roda com dog=nil quando o cão
            -- viaja COM o dono (colo/veículo) ou no grace (ver o ramo de nil-dog no onPlayerUpdate), e pode ter dog vivo
            -- sem square em limpeza -> sem a guarda, o getX/getSquare estourava. Com dog ausente, cai no elseif e remove
            -- a fonte de calor (o cão não está no mundo). `and` faz curto-circuito, então nunca indexa nil.
            pcall(function()
                local x, y, z = math.floor(dog:getX()), math.floor(dog:getY()), math.floor(dog:getZ())
                local tile = x .. "," .. y .. "," .. z
                if huskyHeatTile[pn] ~= tile then
                    if huskyHeat[pn] then getCell():removeHeatSource(huskyHeat[pn]) end
                    local hs = IsoHeatSource.new(x, y, z, CD.HUSKY_WARMTH_RADIUS or 3, CD.HUSKY_WARMTH_TEMP or 28)
                    getCell():addHeatSource(hs)
                    huskyHeat[pn] = hs; huskyHeatTile[pn] = tile
                end
            end)
        elseif huskyHeat[pn] then
            pcall(function() getCell():removeHeatSource(huskyHeat[pn]) end)
            huskyHeat[pn] = nil; huskyHeatTile[pn] = nil
        end
    end,
    onDeactivate = function(player)
        if player then clearHuskyHeat(player, player:getPlayerNum()) end
    end,
}

-- "Intoxicated": aparece depois que o dono dá uma comida tóxica (CD.isBadDogFood -> CD.Server.feed seta um
-- d.sickUntilMin temporizado). NÃO é travado por breed (qualquer cão) e é puramente informativo: sem efeito
-- contínuo nos stats do dono (sem `apply`), só te avisa que o cão está passando mal. Mesmo estilo de cão-no-centro
-- dos outros moodles de cão, com um pequeno badge verde "enjoado" (a cara de doente vanilla) no slot de badge (_dogrig/make_sick_icons.py).
CD.DogMoodles[#CD.DogMoodles + 1] = {
    id = "sick",
    nameKey = "IGUI_PD_Moodle_Sick",
    descKey = "IGUI_PD_Moodle_Sick_desc",
    icon = "CD_Moodle_Sick",         -- ícone baked autocontido (frame oliva + cão + badge de doente)
    fg = "CD_MoodSickFG",            -- cão transparente + badge de doente desenhado sobre o frame nativo
    tintR = 0.52, tintG = 0.60, tintB = 0.28, -- frame oliva-doente suave (distinto do verde feliz / âmbar de courage)
    condition = function(player, dog)
        if not dog or dog:isDead() then return 0 end
        return CD.isSick(dog) and 1 or 0
    end,
}

-- "Hungry"/"Thirsty": reflete a fome/sede NATIVA do cão (`getHunger`/`getThirst`, 0..1) no HUD, no mesmo
-- limiar de aviso que já dispara o HaloText (`CD.HUNGER_WARN`/`THIRST_WARN`=0.6). Não travados por breed,
-- puramente informativos (sem `apply`): o badge é o ícone vanilla de fome/sede do player (garfo+faca / copo)
-- sobre o cão-no-centro, frame laranja/azul (_dogrig/make_need_icons.py). O loop só roda com o cão no raio,
-- então some ao afastar; some também ao alimentar/dar água (a fome/sede cai abaixo do limiar).
CD.DogMoodles[#CD.DogMoodles + 1] = {
    id = "hunger",
    nameKey = "IGUI_PD_Moodle_Hunger",
    descKey = "IGUI_PD_Moodle_Hunger_desc",
    icon = "CD_Moodle_Hunger",
    fg = "CD_MoodHungerFG",
    tintR = 0.90, tintG = 0.48, tintB = 0.18, -- frame laranja "com fome"
    condition = function(player, dog)
        if not dog or dog:isDead() then return 0 end
        local h = 0
        pcall(function() h = dog:getHunger() or 0 end)
        return h >= (CD.HUNGER_WARN or 0.6) and 1 or 0
    end,
}

CD.DogMoodles[#CD.DogMoodles + 1] = {
    id = "thirst",
    nameKey = "IGUI_PD_Moodle_Thirst",
    descKey = "IGUI_PD_Moodle_Thirst_desc",
    icon = "CD_Moodle_Thirst",
    fg = "CD_MoodThirstFG",
    tintR = 0.30, tintG = 0.58, tintB = 0.86, -- frame azul "com sede"
    condition = function(player, dog)
        if not dog or dog:isDead() then return 0 end
        local t = 0
        pcall(function() t = dog:getThirst() or 0 end)
        return t >= (CD.THIRST_WARN or 0.6) and 1 or 0
    end,
}

-- "Bem Descansado": moodle BOM e TEMPORIZADO (não por proximidade). Dormir perto do cão abre uma janela
-- (CompanionDogs_Bonding.lua -> CD.startRestedBuff) que dura algumas horas depois de acordar: dormiu protegido
-- pelo cão, acorda calmo e descansado. Enquanto ativo (`condition` lê o timestamp em ModData), `apply` acalma
-- (pânico/estresse/tristeza) e descansa (fadiga) de leve. Frame verde "bom" default + badge de lua crescente.
CD.DogMoodles[#CD.DogMoodles + 1] = {
    id = "rested",
    timed = true,
    nameKey = "IGUI_PD_Moodle_Rested",
    descKey = "IGUI_PD_Moodle_Rested_desc",
    icon = "CD_Moodle_Rested",
    fg = "CD_MoodRestedFG",
    condition = function(player)
        if not player then return 0 end
        -- guarda contra skew de carga (Config sem a fn ainda): some em vez de spammar no pcall
        if not CD.restedBuffEnabled or not CD.restedBuffEnabled() then return 0 end
        local pd = CD.playerData(player)
        local u = pd and pd.restedUntilMin
        return (u and CD.worldMinutes() < u) and 1 or 0
    end,
    apply = function(player, dog, elapsedMin)
        CD.applyRestedBuff(player, elapsedMin)
    end,
}

-- Cache por player de quais dog-moodles estão ativos (lido pelo overlay do HUD) + horário do último tick.
local activeByPlayer = {}
local lastMin = {}
local graceLeft = {}            -- por player: ticks para manter um mood congelado depois que o cão some, enquanto
local STASH_GRACE_TICKS = 3     -- esperamos a flag stash/carry propagar (~1.5 game-min; cobre latência de MP)

-- Commita o conjunto ativo e dispara onDeactivate para qualquer mood que acabou de desligar. Alguns moods (o
-- Keen Nose do golden) guardam um estado persistente (um multiplicador de XP) que deve ser limpo na borda active->inactive.
local prevActiveIds = {}        -- por playerNum: set { id = true } dos moods ativos no último commit
local function commitActive(pn, player, active)
    activeByPlayer[pn] = active
    local nowIds = {}
    if active then for _, it in ipairs(active) do nowIds[it.def.id] = true end end
    local prev = prevActiveIds[pn]
    if prev then
        for _, def in ipairs(CD.DogMoodles) do
            if def.onDeactivate and prev[def.id] and not nowIds[def.id] then
                pcall(function() def.onDeactivate(player) end)
            end
        end
    end
    prevActiveIds[pn] = nowIds
end

-- Avalia os moodles TEMPORIZADOS (def.timed), que independem de um cão por perto (ex.: "Bem Descansado"
-- continua valendo depois que o cão se afasta). Aplica o efeito por tick e devolve os ativos.
local function evalTimed(player, elapsed)
    local out
    for _, def in ipairs(CD.DogMoodles) do
        if def.timed then
            local level = 0
            local ok = pcall(function() level = def.condition(player, nil) or 0 end)
            if ok and level and level > 0 then
                out = out or {}
                out[#out + 1] = { def = def, level = level }
                if def.apply then pcall(function() def.apply(player, nil, elapsed) end) end
            end
        end
    end
    return out
end

local function onPlayerUpdate(player)
    if not player then return end
    if not CD.dogMoodlesEnabled() then return end
    local pn = player:getPlayerNum()
    if player:isDead() then
        commitActive(pn, player, nil)
        lastMin[pn] = nil
        return
    end
    -- limita o scan de proximidade + efeito por game-minutes (findNearbyCompanion varre um quadrado de tiles)
    local now = CD.worldMinutes()
    local prev = lastMin[pn]
    if prev == nil then lastMin[pn] = now; return end
    local elapsed = now - prev
    if elapsed < CD.MOODLE_TICK_MIN then return end
    lastMin[pn] = now
    if elapsed > CD.MOODLE_ELAPSED_CAP then elapsed = CD.MOODLE_ELAPSED_CAP end
    if elapsed < 0 then elapsed = 0 end

    local dog = CD.findNearbyCompanion(player, CD.moodleHappyRadius())
    if not dog then
        -- Sem cão carregado: os moodles TEMPORIZADOS continuam (avaliados sempre); os de PROXIMIDADE só ficam
        -- congelados enquanto o cão viaja COM o dono (deletado montado num veículo / carregado nas mãos), sinal
        -- autoritativo = registro stash/carry no ModData do dono (o mesmo do marcador de mapa) + um grace curto
        -- que cobre a latência de MP logo após montar. Um cão em Stay / morto nunca recebe o registro, então seu
        -- mood de proximidade cai assim que o grace acaba.
        local active = evalTimed(player, elapsed)
        local pd = CD.playerData(player)
        local withMe = pd and (pd.stash ~= nil or pd.carried ~= nil)
        local prox
        local prevSet = activeByPlayer[pn]
        if prevSet then
            for _, it in ipairs(prevSet) do
                if not it.def.timed then prox = prox or {}; prox[#prox + 1] = it end
            end
        end
        local grace = graceLeft[pn] or 0
        if prox and #prox > 0 and (withMe or grace > 0) then
            if not withMe then graceLeft[pn] = grace - 1 end
            for _, it in ipairs(prox) do
                if it.def.apply then pcall(function() it.def.apply(player, nil, elapsed) end) end
                active = active or {}
                active[#active + 1] = it
            end
        else
            graceLeft[pn] = 0
        end
        commitActive(pn, player, active)
        return
    end

    -- Com o cão por perto: avalia TODOS os moodles em ordem do registry (as condições temporizadas ignoram o cão).
    local active
    local proxActive = false
    for _, def in ipairs(CD.DogMoodles) do
        local level = 0
        local ok = pcall(function() level = def.condition(player, dog) or 0 end)
        if ok and level and level > 0 then
            active = active or {}
            active[#active + 1] = { def = def, level = level }
            if not def.timed then proxActive = true end
            if def.apply then pcall(function() def.apply(player, dog, elapsed) end) end
        end
    end
    commitActive(pn, player, active)
    -- Semeia o grace SÓ p/ moods de proximidade (o temporizado não depende do cão): se o cão despawnar no próximo
    -- tick (montando num veículo) seguimos mostrando o mood de proximidade até a flag stash chegar.
    graceLeft[pn] = proxActive and STASH_GRACE_TICKS or 0
end

local MOODLE_SIZES = { 32, 48, 64, 80, 96, 128 }
local RIGHT_MARGIN = 10
local COLUMN_GAP = 6
local FALLBACK_TOP_Y = 120

local texCache = {}
local function loadIcon(base, size)
    local key = base .. "_" .. size
    local cached = texCache[key]
    if cached ~= nil then return cached or nil end
    local t = getTexture("media/textures/" .. base .. "_" .. size .. ".png")
        or getTexture("media/textures/" .. base .. "_48.png")
        or getTexture(base .. "_" .. size)
    texCache[key] = t or false
    return t
end

-- Frame nativo do moodle (para nosso ícone bater igual aos moodles vanilla: mesma forma redonda + borda branca).
-- A própria engine carrega isso via Texture.getSharedTexture("media/ui/Moodles/<size>/_Moodles_*.png").
local FRAME_R, FRAME_G, FRAME_B = 0.32, 0.82, 0.36 -- tint verde vívido de "good mood" multiplicado sobre o BG cinza
local frameCache = {}
local function loadFrame(name, size)
    local key = name .. "_" .. size
    local cached = frameCache[key]
    if cached ~= nil then return cached or nil end
    local t = getTexture("media/ui/Moodles/" .. size .. "/" .. name .. ".png")
    frameCache[key] = t or false
    return t
end

-- Acompanha o tamanho de moodle configurado pelo player para nossos ícones alinharem com a coluna vanilla.
local function moodleSize()
    local mui = MoodlesUI and MoodlesUI.getInstance and MoodlesUI.getInstance()
    if mui then
        local w = 0
        pcall(function() w = mui:getWidth() end)
        if w and w >= 32 then return w end
    end
    local s = 48
    pcall(function()
        local opt = getCore():getOptionMoodleSize()
        s = MOODLE_SIZES[opt] or 48
    end)
    return s
end

local ISCDMoodleStack = ISUIElement:derive("ISCDMoodleStack")

function ISCDMoodleStack:new(playerNum)
    local o = ISUIElement:new(0, 0, 48, 48)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = playerNum
    o:setRenderThisPlayerOnly(playerNum)
    o.draw = false
    o.size = 48
    o.rowStep = 58
    o.items = nil
    return o
end

-- Overlay passivo: nunca engole clique NEM hover destinado ao mundo/outra UI. setConsumeMouseEvents(false)
-- faz o caminho base de move/wheel devolver false, pra a coluna nunca curto-circuitar o dispatch de hover e
-- roubar o mouseOverOption do inventario por baixo (mesma blindagem do ISCDNameTag).
function ISCDMoodleStack:instantiate()
    ISUIElement.instantiate(self)
    self.javaObject:setConsumeMouseEvents(false)
end

function ISCDMoodleStack:onMouseDown(x, y) return false end
function ISCDMoodleStack:onMouseDownOutside(x, y) return false end
function ISCDMoodleStack:onRightMouseDown(x, y) return false end
function ISCDMoodleStack:onMouseMove(dx, dy) return false end
function ISCDMoodleStack:onMouseMoveOutside(dx, dy) return false end

function ISCDMoodleStack:prerender()
    self.draw = false
    self:setWidth(0); self:setHeight(0)   -- colapsa o hit-rect quando ocioso; reabre so quando desenha de fato
    if not CD.dogMoodlesEnabled() then return end
    -- Pref de exibição por player: esconde o ícone do HUD mantendo o efeito (aplicado em onPlayerUpdate, sem gate).
    if CD.Settings and CD.Settings.getShowMoodles and not CD.Settings.getShowMoodles() then return end
    local items = activeByPlayer[self.playerNum]
    if not items or #items == 0 then return end
    local player = getSpecificPlayer(self.playerNum)
    if not player or player:isDead() then return end

    local size = moodleSize()
    local rowStep = size + 10
    local screenW = getCore():getScreenWidth()
    -- Renderiza como NOSSA PRÓPRIA coluna logo à ESQUERDA da coluna nativa de moodles. A engine não
    -- expõe de forma confiável ao Lua a posição/contagem ao vivo do stack nativo, então tentar anexar ABAIXO dos
    -- moodles vanilla causava sobreposições; uma coluna adjacente nunca colide, seja lá o que estiver ativo.
    local iconX = screenW - RIGHT_MARGIN - (size * 2) - COLUMN_GAP

    -- Ancora no topo da coluna nativa de moodles, mas só CONFIA no getY() quando ele faz sentido: num client
    -- server/co-op observamos MoodlesUI:getY() retornar um valor perto do fundo, o que jogava nosso ícone para
    -- a base da tela. Limita à porção de cima da tela, senão usa o fallback fixo.
    local topY = FALLBACK_TOP_Y
    local mui = MoodlesUI and MoodlesUI.getInstance and MoodlesUI.getInstance()
    if mui then
        local y
        pcall(function() y = mui:getY() end)
        local screenH = getCore():getScreenHeight()
        if y and y >= 0 and screenH and y <= screenH * 0.45 then topY = y end
    end

    self.size = size
    self.rowStep = rowStep
    self.items = items
    self:setX(iconX)
    self:setY(topY)
    self:setWidth(size)
    self:setHeight(#items * rowStep)
    self.draw = true
end

function ISCDMoodleStack:drawMoodleTip(def, ry, size)
    local name = getText(def.nameKey)
    local desc = getText(def.descKey)
    local tm = getTextManager()
    local font = UIFont.Small
    local fh = tm:getFontHeight(font)
    local tw = math.max(tm:MeasureStringX(font, name), tm:MeasureStringX(font, desc))
    local pad = 6
    local boxW = tw + pad * 2
    local boxH = fh * 2 + pad * 2
    local boxX = -boxW - 8
    local boxY = ry + (size - boxH) / 2
    self:drawRect(boxX, boxY, boxW, boxH, 0.85, 0, 0, 0)
    self:drawRectBorder(boxX, boxY, boxW, boxH, 0.4, 1, 1, 1)
    self:drawText(name, boxX + pad, boxY + pad, 1, 1, 1, 1, font)
    self:drawText(desc, boxX + pad, boxY + pad + fh, 0.82, 0.82, 0.82, 1, font)
end

function ISCDMoodleStack:render()
    if not self.draw or not self.items then return end
    local size = self.size
    local rowStep = self.rowStep
    -- Reaproveita o frame nativo do moodle (bg redondo + contorno branco) para bater igual aos moodles vanilla.
    local bg = loadFrame("_Moodles_BGsolid", size)
    local outline = loadFrame("_Moodles_BGoutline", size)
    local mx = getMouseX() - self:getAbsoluteX()
    local my = getMouseY() - self:getAbsoluteY()
    for i, it in ipairs(self.items) do
        local ry = (i - 1) * rowStep
        if bg and outline then
            local tr, tg, tb = it.def.tintR or FRAME_R, it.def.tintG or FRAME_G, it.def.tintB or FRAME_B
            self:drawTextureScaled(bg, 0, ry, size, size, 1, tr, tg, tb)                -- tint do frame por mood
            self:drawTextureScaled(outline, 0, ry, size, size, 1, 1, 1, 1)              -- borda branca
            local fg = loadIcon(it.def.fg or it.def.icon, size)
            if fg then self:drawTextureScaled(fg, 0, ry, size, size, 1, 1, 1, 1) end     -- cão marrom + badge
        else
            -- frame nativo indisponível: cai para nosso ícone baked autocontido
            local baked = loadIcon(it.def.icon, size)
            if baked then self:drawTextureScaled(baked, 0, ry, size, size, 1, 1, 1, 1) end
        end
        if mx >= 0 and mx <= size and my >= ry and my <= ry + size then
            self:drawMoodleTip(it.def, ry, size)
        end
    end
end

local stacks = {}
local function ensureStack(playerNum)
    if stacks[playerNum] then return end
    local o = ISCDMoodleStack:new(playerNum)
    o:initialise()
    o:instantiate()
    o:addToUIManager()
    -- Renderiza ATRÁS da MoodlesUI nativa. Nossa coluna fica logo à esquerda dos moodles vanilla, que é
    -- exatamente onde a engine desenha o tooltip de hover de um moodle nativo (MoodlesUI.render: caixa em x = -10 -
    -- width - 6, estendendo para a esquerda a partir da coluna). Adicionado por último ao UIManager, nosso ícone
    -- senão desenhava POR CIMA desse tooltip, escondendo-o (reportado: texto do moodle nativo ilegível atrás do ícone).
    -- backMost() nos move para a frente da lista de UI, então o tooltip nativo renderiza sobre nosso ícone.
    o:backMost()
    stacks[playerNum] = o
end

if isClient() or not isServer() then
    Events.OnPlayerUpdate.Add(onPlayerUpdate)
    Events.OnCreatePlayer.Add(ensureStack)
end
