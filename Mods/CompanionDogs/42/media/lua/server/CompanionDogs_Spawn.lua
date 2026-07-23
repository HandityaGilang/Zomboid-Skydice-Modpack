local CD = CompanionDogs

local SPAWN_KEY = CD.MODULE .. "_StraySpawns"

local function spawnStore()
    return ModData.getOrCreate(SPAWN_KEY)
end

-- Conjunto local da sessao (em memoria, nunca persistido) de chunks cujos predios ja foram todos decididos no store.
-- Permite ao onLoadChunk pular a varredura da grade nos recarregamentos constantes de uma cidade estabelecida. Reconstruido
-- do store persistente a cada sessao; limpo por resetStraySpawns para o re-roll do admin reprocessar. Chaveado pelo tile de origem do chunk.
local processedChunks = {}

-- Admin/debug: apaga toda decisao de spawn por predio para que casas/delegacias possam sortear um stray de novo no proximo
-- LoadChunk. Essas decisoes ficam no ModData global (o save), NAO nos arquivos do mod: reinstalar o mod nunca as
-- reseta, entao esta e a unica alavanca aquem de um world wipe. Chunks ja carregados nao re-sorteiam ate
-- descarregar e recarregar (admin se afasta / faz relog).
function CD.resetStraySpawns()
    local store = spawnStore()
    local n = 0
    for k in pairs(store) do store[k] = nil; n = n + 1 end
    for k in pairs(processedChunks) do processedChunks[k] = nil end  -- unico caminho que limpa o store; o memo precisa acompanhar
    return n
end

local function notify(player, command, args)
    if isServer() then
        sendServerCommand(player, CD.MODULE, command, args)
    elseif CD.clientNotify then
        CD.clientNotify(command, args)
    end
end

CD.Server = CD.Server or {}
-- Re-roll so para admin (roteado por OnClientCommand como CD.Server.spawn). Reusa o gate de debug-spawn.
CD.Server.resetspawns = function(player, args)
    if not CD.debugAllowed(player) then return end
    local n = CD.resetStraySpawns()
    notify(player, "spawnsreset", { count = n })
end

-- Um predio conta como policia/militar se qualquer um de seus comodos tem nome de delegacia/prisao/arsenal. Nao existe
-- isPoliceStation() nativo no B42, entao farejamos os nomes dos comodos (BuildingDef:getRooms() -> RoomDef:getName()).
local POLICE_ROOM_KEYS = { "police", "prison", "jail", "military", "army", "barracks", "gunstore", "armory" }
function CD.isPoliceLikeBuilding(def)
    if not def or not def.getRooms then return false end
    local rooms
    local ok = pcall(function() rooms = def:getRooms() end)
    if not ok or not rooms then return false end
    for i = 0, rooms:size() - 1 do
        local rd = rooms:get(i)
        local nm = rd and rd:getName()
        if nm then
            nm = string.lower(nm)
            for _, k in ipairs(POLICE_ROOM_KEYS) do
                if string.find(nm, k, 1, true) then return true end
            end
        end
    end
    return false
end

-- Um predio conta como pet shop/veterinario se algum comodo tem nome do ramo. Mesma tecnica do police-like (sem API
-- nativa): farejamos os nomes dos comodos. Diferente de casa/delegacia (1 raca fixa), aqui o husky aparece o ano
-- todo (o local em si e fonte de caes), sem o gate de inverno do spawn ao ar livre.
local PETVET_ROOM_KEYS = { "petstore", "petshop", "veterinar", "vetrenar", "animalshelter", "kennel", "sanctuary" }
function CD.isPetVetBuilding(def)
    if not def or not def.getRooms then return false end
    local rooms
    local ok = pcall(function() rooms = def:getRooms() end)
    if not ok or not rooms then return false end
    for i = 0, rooms:size() - 1 do
        local rd = rooms:get(i)
        local nm = rd and rd:getName()
        if nm then
            nm = string.lower(nm)
            for _, k in ipairs(PETVET_ROOM_KEYS) do
                if string.find(nm, k, 1, true) then return true end
            end
        end
    end
    return false
end

-- Classes base de predio (contrato de addon: ver CD.registerBuildingClass no Config). Exclusivas
-- entre si na ordem de registro, espelhando o elseif historico house > police > petvet.
CD.registerBuildingClass("house", function(def) return def:isResidential() and not def:isShop() end, { exclusive = true })
CD.registerBuildingClass("police", CD.isPoliceLikeBuilding, { exclusive = true })
CD.registerBuildingClass("petvet", CD.isPetVetBuilding, { exclusive = true })

-- Monta uma spec de stray ({atype, breed, kind}) para uma key de raca, com sexo aleatorio (espelha o ramo do GS).
function CD.makeStrayKind(breedKey)
    local sex = (ZombRand(0, 2) == 0) and "male" or "female"
    return {
        atype = CD.breedAnimalType(breedKey, sex),
        breed = CD.breedEngineName(breedKey),
        kind  = breedKey,
    }
end

-- Fallback do passo sem breed explicito (o caramelo): a costura de raca por local que morava aqui
-- (GS em delegacia) virou o campo breed dos CD.StraySpawnDefs.
function CD.chooseStrayKind(def, square)
    local types = CD.SPAWN_TYPES
    return { atype = types[ZombRand(0, #types) + 1], breed = CD.BREED, kind = CD.DEFAULT_BREED }
end

-- forceBreedKey forca uma raca especifica (o passo aditivo do golden); senao chooseStrayKind decide por local.
function CD.spawnStray(square, houseDef, forceBreedKey)
    if not square then return nil end
    local kind = forceBreedKey and CD.makeStrayKind(forceBreedKey) or CD.chooseStrayKind(houseDef, square)
    if not kind then return nil end
    local a = CD.spawnDog(square:getX(), square:getY(), square:getZ(), kind.atype, kind.breed)
    if a then
        if kind.kind then CD.setBreed(a, kind.kind); CD.transmit(a) end
    end
    return a
end

-- Sorteia um spawn de 1-por-predio para um conjunto de predios, deduplicado para sempre no store (ate a decisao "nao" e
-- registrada para nao re-sortear e saturar). So um predio escolhido-mas-com-posicionamento-falho fica sem marcar.
-- keySuffix isola um passo independente nos MESMOS predios (o roll aditivo do golden usa "|g", entao uma casa
-- pode sortear um golden em cima do seu caramelo); forceBreedKey forca a raca desse passo.
local function rollBuildings(buildings, chancePct, candidates, store, keySuffix, forceBreedKey)
    if not buildings then return end
    for key, def in pairs(buildings) do
        local skey = keySuffix and (key .. keySuffix) or key
        if not store[skey] then
            if ZombRand(0, 100) >= chancePct then
                store[skey] = true
            elseif #candidates > 0 then
                local sq = table.remove(candidates, ZombRand(0, #candidates) + 1)
                if CD.spawnStray(sq, def, forceBreedKey) then store[skey] = true end
            end
        end
    end
end

-- True se qualquer square da lista le como urbano. O gate urbano e lido de squares EXTERNOS (rua/quintal)
-- porque esses carregam o zoneamento da cidade que os interiores dos predios nao tem: o square interno de uma casa
-- de cidade grande costuma ficar sem tag, o que fazia chunks residenciais inteiros lerem como nao-urbanos e abortar o spawn em silencio.
local function anyUrban(list)
    if not list then return false end
    for i = 1, #list do
        if CD.isUrbanSquare(list[i]) then return true end
    end
    return false
end

-- True quando toda chave de store que rollBuildings consultaria ja esta setada: para cada passo de
-- CD.StraySpawnDefs com gate aberto, todo predio do bucket da classe precisa da sua key (key..suffix).
-- Quando todas estao setadas rollBuildings e um no-op puro, entao a varredura + gate urbano que so o
-- alimentam podem ser totalmente pulados. Passo com gate fechado (ex.: husky fora do inverno) e ignorado
-- para nao quebrar o memo (senao a chave dele nunca seria setada e a varredura completa rodaria a cada
-- reload o ano todo). Um predio com posicionamento FALHO fica sem marcar, entao isso continua false
-- para ele e o caminho completo de retry ainda roda.
local function allBuildingsDecided(buckets, store)
    for _, sdef in ipairs(CD.StraySpawnDefs) do
        if not sdef.gate or sdef.gate() then
            local set = buckets[sdef.class]
            if set then
                local suffix = sdef.suffix or ""
                for key in pairs(set) do
                    if not store[key .. suffix] then return false end
                end
            end
        end
    end
    return true
end

-- Tile de origem do chunk como key de memo estavel (mesma derivacao para o check e para o set). Usa o square (0,0,0) que a
-- varredura ja usa; square nil so significa que esse chunk nao esta em cache (degradacao segura).
local function chunkKey(chunk)
    local sq = chunk:getGridSquare(0, 0, 0)
    return sq and (sq:getX() .. "," .. sq:getY()) or nil
end

local function onLoadChunk(chunk)
    if not CD.urbanSpawnEnabled() then return end
    if not chunk then return end

    local ckey = chunkKey(chunk)
    if ckey and processedChunks[ckey] then return end

    -- Classifica cada predio do chunk contra CD.BuildingClasses: classes exclusivas seguem a ordem de
    -- registro e param na primeira que casa (preserva o elseif historico house > police > petvet);
    -- classes aditivas (addon) sempre sao testadas, entao um galpao residencial pode entrar em 2 buckets
    -- (o suffix por passo isola as chaves do store).
    local buckets, anyBuilding = {}, false
    for ly = 0, 7 do
        for lx = 0, 7 do
            local sq = chunk:getGridSquare(lx, ly, 0)
            local b = sq and sq:getBuilding()
            local def = b and b:getDef()
            if def then
                local key = def:getX()..","..def:getY()..","..def:getX2()..","..def:getY2()
                local exclusiveTaken = false
                for _, cname in ipairs(CD.BuildingClassOrder) do
                    local cls = CD.BuildingClasses[cname]
                    if not (cls.exclusive and exclusiveTaken) then
                        local ok, hit = pcall(cls.match, def)
                        if ok and hit then
                            buckets[cname] = buckets[cname] or {}
                            buckets[cname][key] = def
                            anyBuilding = true
                            if cls.exclusive then exclusiveTaken = true end
                        end
                    end
                end
            end
        end
    end
    if not anyBuilding then return end

    local store = spawnStore()
    -- Todo predio ja decidido -> rollBuildings seria um no-op, entao pula a varredura de tiles livres + gate urbano.
    -- Memoize SO aqui (nunca depois de um roll): um predio com posicionamento falho fica sem marcar, mantem isso false e assim
    -- nunca e memoizado para fora do seu retry.
    if allBuildingsDecided(buckets, store) then
        if ckey then processedChunks[ckey] = true end
        return
    end

    -- Tiles livres externos (rua/quintal) sao preferidos para o stray aparecer vagando do lado de fora; mas um chunk
    -- residencial denso muitas vezes nao tem nenhum no proprio chunk (casas geminadas do centro, ou uma casa cujo quintal cai num
    -- chunk vizinho). Cai de volta para qualquer tile livre (incl. dentro do predio): o chunk que detectou a
    -- casa sempre contem ao menos os squares da propria casa, entao uma casa detectada sempre consegue posicionar seu stray.
    local outdoor, anyFree
    for ly = 0, 7 do
        for lx = 0, 7 do
            local sq = chunk:getGridSquare(lx, ly, 0)
            if sq and not sq:isWaterSquare() and sq:isFree(true) and sq:isSolidFloor() then
                if not sq:getBuilding() and sq:isOutside() then
                    outdoor = outdoor or {}
                    outdoor[#outdoor + 1] = sq
                else
                    anyFree = anyFree or {}
                    anyFree[#anyFree + 1] = sq
                end
            end
        end
    end

    local candidates = outdoor or anyFree
    if not candidates then return end

    -- Gate urbano por passo: o comportamento historico (chunk nao-urbano nao spawna nada) segue valendo
    -- para as classes base; uma classe com skipUrbanGate (ex.: industrial de addon fora de TownZone)
    -- rola mesmo em chunk nao-urbano.
    local urbanOK = anyUrban(outdoor) or anyUrban(anyFree)

    for _, sdef in ipairs(CD.StraySpawnDefs) do
        local cls = CD.BuildingClasses[sdef.class]
        if cls and (urbanOK or cls.skipUrbanGate) and (not sdef.gate or sdef.gate()) then
            rollBuildings(buckets[sdef.class], sdef.chance(), candidates, store, sdef.suffix, sdef.breed)
        end
    end
end

if not isClient() then
    Events.OnInitGlobalModData.Add(function() spawnStore() end)
    Events.LoadChunk.Add(onLoadChunk)
end
