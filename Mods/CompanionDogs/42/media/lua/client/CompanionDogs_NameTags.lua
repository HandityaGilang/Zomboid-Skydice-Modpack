require "ISUI/ISUIElement"

local CD = CompanionDogs

local HEAD_OFFSET = 55
local TAG_W = 260   -- largura de layout usada para centralizar o texto; NAO o hit-rect do elemento (ver :new)
local LINE_H = 16   -- altura por linha dos rotulos empilhados sobre a cabeca (alerta / status / nome)
local TAG_RADIUS = 14

local ISCDNameTag = ISUIElement:derive("ISCDNameTag")

-- Esta tag e PURAMENTE cosmetica e nunca pode participar do hit-testing do mouse, ou a engine come os
-- cliques-direitos/mira onde ela flutua -> uma "deadzone" em volta do cachorro (sem menu de contexto, e voce nao
-- consegue INICIAR a postura de combate com o cursor sobre ela). setConsumeMouseEvents(false) NAO basta: o caminho de
-- botao direito da engine e so por bounds e ignora isso (UIManager.isOverElement + UIElement.onRightMouseDown/Up
-- retornam TRUE para os handlers vazios herdados -> consumedRClick -> Mouse.UIBlockButtonDown(1) +
-- OnObjectRightMouseButtonUp suprimido). Correcao: manter o hit-rect do elemento em ZERO. O "mx < x + width" do
-- isOverElement nunca casa quando width == 0, entao a tag fica invisivel para todo caminho de mouse (consumo de
-- clique, menu de contexto, e a troca de cursor da mira). O texto e desenhado a partir de TAG_W/LINE_H mais o x/y do
-- elemento, entao ele fica centralizado acima do cachorro apesar do tamanho 0.
function ISCDNameTag:new(playerNum)
    local o = ISUIElement:new(0, 0, 0, 0)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = playerNum
    o:setRenderThisPlayerOnly(playerNum)
    o:setFollowGameWorld(true)
    o.draw = false
    return o
end

function ISCDNameTag:instantiate()
    ISUIElement.instantiate(self)
    -- Reforco extra para o caminho do cursor/mira (o hit-rect 0 ja cobre isso).
    self.javaObject:setConsumeMouseEvents(false)
end

function ISCDNameTag:prerender()
    self.draw = false
    self.lines = nil
    if not CD.showNameTags() then return end
    local player = getSpecificPlayer(self.playerNum)
    if not player or player:isDead() then return end
    -- O cachorro e atribuido a cada frame pelo gerenciador do pool (refreshTags); nil significa que este slot esta ocioso.
    local dog = self.dog
    if not dog then return end
    -- Esconde a tag enquanto o cachorro esta guardado num veiculo (ele fica invisivel nesse caso).
    local hidden = false
    pcall(function() hidden = dog:isInvisible() end)
    if hidden then return end
    if math.floor(dog:getZ()) ~= math.floor(player:getZ()) then return end

    -- Monta a pilha sobre a cabeca de cima para baixo; cada entrada e sua propria linha para nada se sobrepor.
    local lines = {}
    if CD.isOwnedBy(dog, player) then
        -- Seu proprio cachorro: a pilha de status vivo (alerta, badge de estado, auto-feed, caca). Limitada pela
        -- configuracao de client por player "Show dog status texts" (CD.showNotifications); so o nome permanece quando desligada.
        if CD.showNotifications() then
            -- Linha de alerta: fixada enquanto a sentinela esta detectando (o server a limpa via histerese quando a ameaca some).
            local tier = CD.data(dog).alertTier
            if tier == "alarm" then
                lines[#lines + 1] = { text = getText("IGUI_PD_AlertAlarm", CD.breedNoun(dog)), r = 0.98, g = 0.45, b = 0.20 }
            elseif tier == "aware" then
                lines[#lines + 1] = { text = getText("IGUI_PD_AlertAware", CD.breedNoun(dog)), r = 0.96, g = 0.86, b = 0.32 }
            end
            -- Badge de status: estado persistente de stress/ferida/lealdade (Nervous/Panicking/Terrified/Wounded/Disloyal).
            local bd = CD.statusBadge(dog)
            if bd then
                lines[#lines + 1] = { text = getText(bd.key), r = bd.r, g = bd.g, b = bd.b }
            end
            -- Acao de auto-feed: o cachorro saiu por conta propria para comer/beber numa tigela abastecida (o server seta d.autoFeeding).
            local feeding = CD.data(dog).autoFeeding
            local drink = CD.data(dog).autoFeedKind == "water"
            if feeding == "going" then
                lines[#lines + 1] = { text = getText(drink and "IGUI_PD_AutoFeedGoingDrink" or "IGUI_PD_AutoFeedGoing"), r = 0.55, g = 0.85, b = 0.45 }
            elseif feeding == "eating" then
                lines[#lines + 1] = { text = getText(drink and "IGUI_PD_AutoFeedDrinking" or "IGUI_PD_AutoFeedEating"), r = 0.55, g = 0.85, b = 0.45 }
            end
            -- Acao de caca: o cachorro esta rastreando/perseguindo/buscando caca selvagem (o server seta d.hunting).
            local hunting = CD.data(dog).hunting
            if hunting == "tracking" then
                lines[#lines + 1] = { text = getText("IGUI_PD_HuntTracking"), r = 0.82, g = 0.72, b = 0.42 }
            elseif hunting == "sniffing" then
                lines[#lines + 1] = { text = getText("IGUI_PD_HuntSniffing"), r = 0.62, g = 0.86, b = 0.52 }
            elseif hunting == "chasing" then
                lines[#lines + 1] = { text = getText("IGUI_PD_HuntChasing"), r = 0.88, g = 0.66, b = 0.34 }
            elseif hunting == "holding" then
                lines[#lines + 1] = { text = getText("IGUI_PD_HuntHolding"), r = 0.90, g = 0.45, b = 0.40 }
            elseif hunting == "retrieving" then
                lines[#lines + 1] = { text = getText("IGUI_PD_HuntRetrieving"), r = 0.70, g = 0.80, b = 0.50 }
            elseif hunting == "foraging" then
                lines[#lines + 1] = { text = getText("IGUI_PD_HuntForaging"), r = 0.62, g = 0.80, b = 0.55 }
            elseif CD.data(dog).huntCooling then
                -- Caca ligada mas em cooldown depois de desistir de uma presa: sem isso o cao parece so estar ignorando o modo.
                lines[#lines + 1] = { text = getText("IGUI_PD_HuntCooldown"), r = 0.60, g = 0.60, b = 0.62 }
            end
        end
        -- Gravida: sinalizacao persistente sobre a cabeca (sempre, independente do toggle de status texts).
        if CD.isPregnant(dog) then
            lines[#lines + 1] = { text = CD.pregnancyLabel(dog), r = 0.96, g = 0.55, b = 0.80 }
        end
        -- Nome do cachorro: sempre por ultimo para ficar mais perto da cabeca.
        lines[#lines + 1] = { text = CD.data(dog).name or CD.breedNoun(dog), r = 1, g = 1, b = 1 }
    else
        -- Cachorro de outro player (MP): so identidade, o owner (acima) e o nome do cachorro (mais perto da cabeca).
        local owner = CD.data(dog).ownerName
        if owner and owner ~= "" then
            lines[#lines + 1] = { text = getText("IGUI_PD_OwnerTag", owner), r = 0.70, g = 0.78, b = 0.92 }
        end
        if CD.isPregnant(dog) then
            lines[#lines + 1] = { text = CD.pregnancyLabel(dog), r = 0.96, g = 0.55, b = 0.80 }
        end
        lines[#lines + 1] = { text = CD.data(dog).name or CD.breedNoun(dog), r = 1, g = 1, b = 1 }
    end
    self.lines = lines

    local off = HEAD_OFFSET / getCore():getZoom(self.playerNum)
    local sx = isoToScreenX(self.playerNum, dog:getX(), dog:getY(), dog:getZ()) - getPlayerScreenLeft(self.playerNum)
    local sy = isoToScreenY(self.playerNum, dog:getX(), dog:getY(), dog:getZ()) - getPlayerScreenTop(self.playerNum) - off
    self:setX(sx - TAG_W / 2)
    self:setY(sy - #lines * LINE_H)
    self.draw = true
end

function ISCDNameTag:render()
    if not self.draw or not self.lines then return end
    local cx = TAG_W / 2
    for i = 1, #self.lines do
        local ln = self.lines[i]
        local y = (i - 1) * LINE_H
        self:drawTextCentre(ln.text, cx + 1, y + 1, 0, 0, 0, 0.7, UIFont.Small)
        self:drawTextCentre(ln.text, cx, y, ln.r, ln.g, ln.b, 1, UIFont.Small)
    end
end

-- Um pool de elementos de tag por player local; cada elemento fica ligado a um unico cachorro (definido por refreshTags).
local pools = {}

local function ensurePool(playerNum)
    if not pools[playerNum] then pools[playerNum] = {} end
    return pools[playerNum]
end

local function tagSlot(playerNum, index)
    local pool = ensurePool(playerNum)
    local o = pool[index]
    if not o then
        o = ISCDNameTag:new(playerNum)
        o:initialise()
        o:instantiate()
        o:addToUIManager()
        pool[index] = o
    end
    return o
end

-- Todo cachorro companheiro por perto (qualquer owner), assim o MP mostra os cachorros de outros players tambem. Percorre a
-- lista de animais da cell (mesma fonte de CD.getCompanionAnimal) em vez de varrer squares.
local function gatherCompanions(player, radius)
    local out = {}
    local cell = getCell()
    if not cell then return out end
    local list = cell:getAnimals()
    if not list then return out end
    local pz = math.floor(player:getZ())
    for i = 0, list:size() - 1 do
        local a = list:get(i)
        if CD.isDog(a) and not a:isDead() and CD.isCompanion(a)
           and math.floor(a:getZ()) == pz and CD.dist2D(a, player) <= radius then
            out[#out + 1] = a
        end
    end
    return out
end

-- Reatribui o pool a cada tick: uma tag por cachorro companheiro por perto, slots ociosos limpos. O prerender faz o
-- posicionamento/visibilidade por frame a partir do cachorro que entregamos aqui.
local function refreshTags(playerNum)
    local pool = ensurePool(playerNum)
    local player = getSpecificPlayer(playerNum)
    local n = 0
    if player and not player:isDead() and CD.showNameTags() then
        local dogs = gatherCompanions(player, TAG_RADIUS)
        for _, dog in ipairs(dogs) do
            n = n + 1
            tagSlot(playerNum, n).dog = dog
        end
    end
    for j = n + 1, #pool do pool[j].dog = nil end
end

if isClient() or not isServer() then
    Events.OnCreatePlayer.Add(function(playerNum)
        ensurePool(playerNum)
    end)

    Events.OnTick.Add(function()
        for playerNum = 0, getNumActivePlayers() - 1 do
            refreshTags(playerNum)
        end
    end)
end
