require "ISUI/Maps/ISWorldMap"
require "ISUI/Maps/ISMiniMap"

local CD = CompanionDogs

-- Desenha um marcador de pata para CADA cao com vinculo do jogador no mapa do mundo E no minimapa. O cao ATIVO
-- (o que te segue) usa a pata MARROM; os caes passivos que voce deixa para tras (ex.: em casa) usam a pata CINZA,
-- e o mapa do mundo ainda rotula cada pata com o nome do cao para distinguir varios caes facilmente. Enquanto um cao esta carregado
-- perto de voce o marcador o segue ao vivo; quando ele descarrega (voce se afastou, ou ele esta parado em casa) o marcador fica
-- no ultimo ponto visto, para voce achar um cao que deixou em algum lugar. Puramente client e cosmetico: cada jogador
-- rastreia os SEUS proprios caes, nada e enviado pela rede alem do proprio ModData do jogador, e as patas sao desenhadas como overlays
-- (sem map symbol) para nunca serem salvas como marcadores fantasma.
--
-- Fonte dos "meus caes" = pd.companions (o conjunto de tokens mantido no server por makeCompanion/release/death,
-- independente do limite MaxCompanions). A ultima posicao conhecida por cao fica em pd.dogPositions, persistida no
-- ModData do jogador para um cao parado em casa ainda aparecer depois de um relog. Um cao liberado/morto sai de pd.companions
-- no server, entao sua pata simplesmente deixa de ser desenhada (e sua entrada de posicao e removida).

local MARKER_TEX = "media/textures/CDDogPaw_64.png"          -- marrom: cao ATIVO
local MARKER_TEX_GREY = "media/textures/CDDogPawGrey_64.png" -- cinza: caes passivos / nao selecionados
local TRACK_THROTTLE = 10  -- intervalo de OnTick entre atualizacoes de posicao (~3-4x/seg, suave o bastante para um mapa)
local MM_ICON = 14         -- tamanho do marcador no minimapa (px)
local WM_ICON = 20         -- tamanho do marcador no mapa do mundo completo (px)
-- A cor agora vem da PROPRIA textura (identidade nova do mod); o desenho usa tint neutro.
-- Estes tons valem so para o ROTULO de nome no mapa do mundo (fundo claro): marrom escuro / cinza medio.
local LBL_ACTIVE_R, LBL_ACTIVE_G, LBL_ACTIVE_B = 0.31, 0.23, 0.16
local LBL_PASSIVE_R, LBL_PASSIVE_G, LBL_PASSIVE_B = 0.42, 0.42, 0.42

local markers = {}         -- lista de nivel de modulo reconstruida a cada updateTracked: { {x,y,z,name,active}, ... }
local markerTex = nil
local markerTexGrey = nil

local function texture(active)
    if markerTex == nil then markerTex = getTexture(MARKER_TEX) end
    if markerTexGrey == nil then markerTexGrey = getTexture(MARKER_TEX_GREY) end
    if active then return markerTex end
    return markerTexGrey or markerTex
end

local trackTick = 0
local sendEvery = 60       -- janela de envio pro server (~10s); so envia tokens cuja TILE mudou
local sendCount = 0
local lastSent = {}        -- token -> {x,y,z,name} da ultima posicao enviada

local function updateTracked()
    trackTick = trackTick + 1
    if trackTick < TRACK_THROTTLE then return end
    trackTick = 0
    if not CD.showMapMarker() then markers = {}; return end
    local player = getPlayer()
    if not player then return end
    local pd = CD.playerData(player)
    pd.dogPositions = pd.dogPositions or {}

    -- Passo ao vivo: registra a posicao+nome de cada companheiro proprio atualmente carregado na cell (ativo OU
    -- passivo). Mesmo formato de varredura do CD.getCompanionAnimal, coletando todos eles.
    local liveTokens = {}
    local cell = getCell()
    if cell then
        local list = cell:getAnimals()
        if list then
            for i = 0, list:size() - 1 do
                local a = list:get(i)
                if a and CD.isDog(a) and CD.isCompanion(a) and CD.isOwnedBy(a, player) and not a:isDead() then
                    local t = CD.data(a).companionToken
                    if t ~= nil then
                        pd.dogPositions[t] = { x = a:getX(), y = a:getY(), z = a:getZ(),
                                               name = CD.data(a).name or CD.breedNoun(a) }
                        liveTokens[t] = true
                    end
                end
            end
        end
    end

    -- O cao ATIVO viajando COM o dono (deletado enquanto montado, ou carregado nas maos) nao tem animal carregado,
    -- entao prende o marcador ao dono para ele andar com o carro em vez de congelar onde voce entrou. So o cao
    -- ativo pode ser guardado/carregado; caes parados nao tem esse registro e corretamente ficam no lugar.
    if (pd.stash ~= nil or pd.carried ~= nil) and pd.token ~= nil then
        local prev = pd.dogPositions[pd.token]
        pd.dogPositions[pd.token] = { x = player:getX(), y = player:getY(), z = player:getZ(),
                                      name = (prev and prev.name) or pd.name or CD.breedNoun(nil) }
    end

    -- Semente de migracao: um save anterior a este recurso tem o pd.lastPos de cao unico mas ainda sem dogPositions.
    if pd.token ~= nil and pd.lastPos and pd.dogPositions[pd.token] == nil then
        pd.dogPositions[pd.token] = { x = pd.lastPos.x, y = pd.lastPos.y, z = pd.lastPos.z, name = pd.name }
    end

    -- Semente do canil: cao vinculado cuja posicao este client nunca viu (relog/outra maquina/dedicado) adota o
    -- "visto por ultimo" do snapshot do server (pd.kennel e transmitido com o ModData do jogador).
    if type(pd.kennel) == "table" then
        for t, snap in pairs(pd.kennel) do
            if pd.dogPositions[t] == nil and type(snap) == "table" and snap.x then
                pd.dogPositions[t] = { x = snap.x, y = snap.y, z = snap.z or 0, name = snap.name }
            end
        end
    end

    -- Quais tokens sao "meus": o conjunto de propriedade (autoritativo) + tudo carregado neste tick + o token ativo.
    local myTokens = {}
    if type(pd.companions) == "table" then for t in pairs(pd.companions) do myTokens[t] = true end end
    for t in pairs(liveTokens) do myTokens[t] = true end
    if pd.token ~= nil then myTokens[pd.token] = true end

    -- Poda posicoes de caes que nao sao mais meus (liberados/mortos e nao carregados) para a pata sumir.
    for t in pairs(pd.dogPositions) do
        if not myTokens[t] then pd.dogPositions[t] = nil; lastSent[t] = nil end
    end

    -- Reconstroi a lista de desenho.
    local out = {}
    for t in pairs(myTokens) do
        local p = pd.dogPositions[t]
        if p and p.x then
            out[#out + 1] = { x = p.x, y = p.y, z = p.z, name = p.name, active = (t == pd.token) }
        end
    end
    markers = out

    -- Persiste o "visto por ultimo" no server via comando pequeno (delta): so tokens cuja tile mudou desde o
    -- ultimo envio. Substitui o antigo player:transmitModData() do client, que reenviava o ModData INTEIRO do
    -- player a cada ~5s e podia sobrescrever escritas server-side concorrentes (pd.stash/pd.kennel).
    sendCount = sendCount + 1
    if sendCount >= sendEvery then
        sendCount = 0
        local list = {}
        for t, p in pairs(pd.dogPositions) do
            local fx, fy, fz = math.floor(p.x), math.floor(p.y), math.floor(p.z or 0)
            local ls = lastSent[t]
            if not ls or ls.x ~= fx or ls.y ~= fy or ls.z ~= fz or ls.name ~= p.name then
                list[#list + 1] = { t = t, x = fx, y = fy, z = fz, name = p.name }
                lastSent[t] = { x = fx, y = fy, z = fz, name = p.name }
            end
        end
        if #list > 0 then pcall(function() CD.request("dogpos", nil, { list = list }) end) end
    end
end

-- Projeta cada cao rastreado nesta UI de mapa e desenha sua pata (+ nome no mapa do mundo). No minimapa, limita
-- a borda da viewport para um cao fora de vista ainda indicar uma direcao; no mapa do mundo, desenha no ponto projetado real.
local function drawMarker(mapUI, iconSize, clampToEdge)
    if #markers == 0 then return end
    if not CD.showMapMarker() then return end
    local api = mapUI.mapAPI
    if not api then return end
    local half = iconSize / 2
    local w, h = mapUI:getWidth(), mapUI:getHeight()
    -- Um pcall ao redor do loop, nao uma closure por marcador por frame.
    pcall(function()
        for _, m in ipairs(markers) do
            local tex = texture(m.active)
            local sx, sy = api:worldToUIX(m.x, m.y), api:worldToUIY(m.x, m.y)
            if sx ~= nil and tex then
                if clampToEdge then
                    if sx < half then sx = half elseif sx > w - half then sx = w - half end
                    if sy < half then sy = half elseif sy > h - half then sy = h - half end
                end
                mapUI:drawTextureScaledAspect(tex, sx - half, sy - half, iconSize, iconSize, 1.0, 1.0, 1.0, 1.0)
                -- Rotulo de nome: so no mapa do mundo (o minimapa e pequeno demais e ficaria poluido).
                if not clampToEdge and m.name and m.name ~= "" then
                    local r, g, b
                    if m.active then r, g, b = LBL_ACTIVE_R, LBL_ACTIVE_G, LBL_ACTIVE_B
                    else r, g, b = LBL_PASSIVE_R, LBL_PASSIVE_G, LBL_PASSIVE_B end
                    mapUI:drawText(m.name, sx + half + 2, sy - 7, r, g, b, 1.0, UIFont.Small)
                end
            end
        end
    end)
end

local origWorldPrerender = ISWorldMap.prerender
function ISWorldMap:prerender()
    origWorldPrerender(self)
    drawMarker(self, WM_ICON, false)
end

local origMiniPrerender = ISMiniMapInner.prerender
function ISMiniMapInner:prerender()
    origMiniPrerender(self)
    drawMarker(self, MM_ICON, true)
end

if isClient() or not isServer() then
    Events.OnTick.Add(updateTracked)
end
