local CD = CompanionDogs

-- O forage scout roda no CLIENT DO DONO, onde as posicoes de forage existem (forageData, modData do client). No
-- modo PURIST o cao so rastreia critters vivos (sapos/insetos). Mas o forage do B42 nao pre-existe: um critter
-- so se materializa quando ALGUEM procura (a afinidade de sprite cria um icone num sprite de planta proximo sob demanda),
-- entao apenas LER o pool atras de critters nao acha nada. Por isso o faro do cao funciona como o olho da engine: quando um critter
-- esta de fato disponivel agora (rolamos a loot table, que respeita mes/clima/hora do dia, mudo de dia, etc.)
-- FIXAMOS um icone de forage de critter real numa square valida perto do cao, tirado do orcamento itemsLeft da propria zona (sem
-- inflar), e batemos heartbeat dessa tile pro server (~1/game-min, como o AutoProtect). O companion loop do host entao
-- leva o cao ate la e aponta; o dono procura naquele ponto e coleta o critter (a +12 de visao ajuda). Se
-- nao houver critter fora, nao mandamos nada e o cao simplesmente fica quieto. Todas as chamadas de engine sao protegidas por pcall.

local lastRunMin = {}   -- playerNum -> ultimo game-minute em que rodamos o scan (throttled)
local lastTarget = {}   -- playerNum -> ultimo alvo escolhido {x,y,z} (histerese)
local lastSniffMin = {} -- zoneID -> ultimo game-minute em que farejamos (colocamos) um novo critter (throttle anti-litter)

-- Icone de forage de critter EXISTENTE mais proximo dentro de HUNT_FORAGE_SCOUT_RADIUS do cao (com histerese), ou nil.
local function nearestCritterIcon(zd, dx, dy, dz, prev)
    if not zd.forageIcons then return nil end
    local R2 = (CD.HUNT_FORAGE_SCOUT_RADIUS or 20) ^ 2
    local cats = CD.HUNT_FORAGE_SCOUT_CATEGORIES or {}
    local best, bestD, prevD
    for _, icon in pairs(zd.forageIcons) do
        if icon and icon.x and icon.y and cats[icon.catName] then
            local ix, iy = math.floor(icon.x), math.floor(icon.y)
            local gx, gy = ix - dx, iy - dy
            local dd = gx * gx + gy * gy
            if dd <= R2 then
                if not bestD or dd < bestD then best = { x = ix, y = iy, z = math.floor(icon.z or dz) }; bestD = dd end
                if prev and ix == prev.x and iy == prev.y then prevD = dd end
            end
        end
    end
    -- mantem o alvo anterior se ele ainda for um icone valido a no maximo ~2 tiles a mais que o mais proximo.
    if prev and prevD and bestD and math.sqrt(prevD) <= math.sqrt(bestD) + 2 then
        return { x = prev.x, y = prev.y, z = prev.z }
    end
    return best
end

-- Rola um critter disponivel (respeita hora/estacao) e fixa na square valida mais proxima do cao, tirado do
-- orcamento itemsLeft da zona. Retorna a square {x,y,z} ou nil (nenhum critter fora agora / nenhuma square valida / sem orcamento).
local function sniffOutCritter(zd, dx, dy)
    if (zd.itemsLeft or 0) < 1 then return nil end
    local placeCats = CD.HUNT_FORAGE_SCOUT_PLACE_CATEGORIES or {}
    local itemType, catName
    for _ = 1, (CD.HUNT_FORAGE_SCOUT_ROLLS or 30) do
        local it, cn = forageSystem.pickRandomItemType(zd.name)
        if it and cn and placeCats[cn] and forageSystem.itemDefs[it] then itemType, catName = it, cn; break end
    end
    if not itemType then return nil end
    local itemDef = forageSystem.itemDefs[itemType]
    local catDef = forageSystem.catDefs[catName]
    if not itemDef or not catDef then return nil end
    local cell = getCell()
    if not cell then return nil end

    local occupied = {}
    if zd.forageIcons then
        for _, icon in pairs(zd.forageIcons) do
            if icon and icon.x and icon.y then occupied[math.floor(icon.x) .. "," .. math.floor(icon.y)] = true end
        end
    end

    local R = CD.HUNT_FORAGE_SCOUT_PLACE_RADIUS or 12
    local R2 = R * R
    -- pega a square valida MAIS DISTANTE dentro do alcance, pra o cao de fato liderar algumas tiles em vez de apontar pro proprio pe
    local bestX, bestY, bestD
    for gx = -R, R do
        for gy = -R, R do
            local dd = gx * gx + gy * gy
            if dd <= R2 and (not bestD or dd > bestD) then
                local sx, sy = dx + gx, dy + gy
                if not occupied[sx .. "," .. sy] then
                    local sq = cell:getGridSquare(sx, sy, 0)
                    if sq and forageSystem.isValidSquare(sq, itemDef, catDef) then
                        bestX, bestY, bestD = sx, sy, dd
                    end
                end
            end
        end
    end
    if not bestX then return nil end

    local id = getRandomUUID()
    local icon = {
        id = id, zoneid = zd.id, x = bestX, y = bestY, z = 0,
        catName = catName, itemType = itemType, isBonusIcon = true, canRollForSearchFocus = false,
    }
    zd.forageIcons[id] = icon
    forageClient.updateIcon(zd, id, icon)
    forageSystem.takeItem(zd, 1)
    return { x = bestX, y = bestY, z = 0 }
end

-- Zona de forage na tile do cao, ou (para bordas de estrada/campo onde a tile do proprio cao nao tem) na tile do dono ou
-- num anel curto ao redor do cao. O primeiro hit vence.
local function findZoneNear(dx, dy, ox, oy)
    local zd
    pcall(function() zd = forageSystem.getForageZoneAt(dx, dy) end)
    if zd then return zd end
    if ox and oy then
        pcall(function() zd = forageSystem.getForageZoneAt(ox, oy) end)
        if zd then return zd end
    end
    local p = CD.HUNT_FORAGE_SCOUT_ZONE_PROBE or 4
    local dirs = { { p, 0 }, { -p, 0 }, { 0, p }, { 0, -p }, { p, p }, { p, -p }, { -p, p }, { -p, -p } }
    for _, d in ipairs(dirs) do
        pcall(function() zd = forageSystem.getForageZoneAt(dx + d[1], dy + d[2]) end)
        if zd then return zd end
    end
    return nil
end

local function detectForageTarget(dx, dy, dz, ox, oy, prev, now)
    local zd = findZoneNear(dx, dy, ox, oy)
    if not zd then return nil end
    -- 1) leva ate um critter que ja esta la (de graca; ex.: deixado nao coletado por uma busca anterior)
    local existing = nearestCritterIcon(zd, dx, dy, dz, prev)
    if existing then return existing end
    -- 2) caso contrario fareja um novo, throttled por zona pra o cao nao espalhar critters enquanto o dono perambula
    local cd = CD.HUNT_FORAGE_RETRY_COOLDOWN_MIN or 10
    if lastSniffMin[zd.id] and (now - lastSniffMin[zd.id]) < cd then return nil end
    local placed
    pcall(function() placed = sniffOutCritter(zd, dx, dy) end)
    if placed then lastSniffMin[zd.id] = now end
    return placed
end

local function onForageScout(player)
    if not player or not forageSystem then return end
    if not CD.huntEnabled() or not CD.huntForagePointEnabled() then return end
    local pn = player:getPlayerNum()

    local now = math.floor(CD.worldMinutes())
    if lastRunMin[pn] == now then return end
    lastRunMin[pn] = now

    local dog = CD.getCompanionAnimal(player)
    if not dog or not CD.getHuntMode(dog) then lastTarget[pn] = nil; return end

    local dx, dy, dz = math.floor(dog:getX()), math.floor(dog:getY()), math.floor(dog:getZ())
    local ox, oy = math.floor(player:getX()), math.floor(player:getY())
    local target = detectForageTarget(dx, dy, dz, ox, oy, lastTarget[pn], now)
    lastTarget[pn] = target
    if target then
        CD.request("foragescout", dog, { x = target.x, y = target.y, z = target.z })
    end
end

if isClient() or not isServer() then
    Events.OnPlayerUpdate.Add(onForageScout)
end
