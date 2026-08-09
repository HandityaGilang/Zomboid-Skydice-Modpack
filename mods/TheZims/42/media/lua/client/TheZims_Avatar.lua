--[[
    A cabeca do personagem no meio da roda.

    O jogo ja sabe desenhar o personagem dentro da UI: ISUI3DModel envolve o
    UI3DModel do Java. O enquadramento de rosto usado aqui e o mesmo de
    CharacterCreationAvatar:setFacePreview -- zoom 14, yOffset -0.85 -- em vez
    de valores chutados.

    O painel NAO e filho do menu de contexto. Menu de contexto e um objeto unico
    por jogador, reaproveitado, e os submenus sao instancias separadas; pendurar
    o avatar em um deles faria a cabeca sumir ao entrar num submenu. Em vez
    disso ele e um elemento solto no UIManager, que o render da roda posiciona e
    traz para frente a cada quadro.

    Como ninguem avisa "o menu fechou", o painel se esconde sozinho: o render
    carimba um horario a cada quadro e o proprio prerender do painel some se
    esse carimbo ficar velho.
]]

TheZims = TheZims or {}
local Avatar = {}
TheZims.Avatar = Avatar

local STALE_MS = 60

Avatar.panel = nil
Avatar.failed = false

--[[
    Altura do modelo a partir do zoom.

    Os dois nao sao independentes: subir o zoom sem acertar o yOffset empurra a
    cabeca para fora do quadro.

    Esta reta passa por dois pontos medidos NESTE painel (quadrado, ~100px):

        zoom 14  ->  yOffset -0.85
        zoom 20  ->  yOffset -0.90

    Inclinacao: -1/120 por unidade de zoom.

    A versao anterior usava -0.05, extrapolada dos valores de
    CharacterCreationAvatar. Estava 6x forte demais e por isso zoom 21 e 24
    apagavam o personagem: em 21 ela pedia -1.20 quando o certo era -0.91. A
    licao e que o yOffset e relativo ao painel, e o da tela de criacao e alto e
    grande enquanto o nosso e pequeno e quadrado - os valores de la nao
    transferem.
]]
function Avatar.yOffsetPara(zoom)
    return -0.85 - (zoom - 14) / 120
end

--- Zoom e altura efetivos, ja com o ajuste fino aplicado.
function Avatar.enquadramento()
    local C = TheZims.CFG
    local zoom = C.avatarZoom or 14
    local y = C.avatarYOffset or Avatar.yOffsetPara(zoom)
    return zoom, y + (C.avatarYNudge or 0)
end

--[[
    O personagem vira em DEGRAUS. Nao da para ser continuo, e o motivo e da
    engine, nao de falta de tentativa:

      1. setXOffset/setYOffset sao continuos, mas TRANSLADAM - o modelo
         escorrega para o lado em vez de virar. Foi rejeitado com razao.
      2. UI3DModel.setAngle(float) parecia a saida, mas NAO EXISTE. O nome
         aparece no constant pool da classe so porque ela chama setAngle em
         AnimatedModel/IsoGameCharacter internamente. Chamar dava
         "Object tried to call nil" e dois erros na tela.

    O que o wrapper de fato expoe para orientacao e setDirection(IsoDirections),
    com 8 posicoes fixas. Entao o giro e discreto, ponto final.

    Para o degrau incomodar o minimo possivel:

      * so tres posicoes por padrao (SE, S, SW), o suficiente para ler como
         "olhou para o lado" sem o modelo rodopiar;
      * histerese nos limiares, para nao piscar entre duas posicoes quando o
         cursor passeia bem em cima da fronteira;
      * com o cursor sobre uma pilula o alvo e o angulo daquela opcao, entao na
         pratica ele fica parado a maior parte do tempo.

    As quatro direcoes de tras existem mas nao sao usadas: virar para N
    mostraria a nuca.
]]

local PASSOS_3 = { "SW", "S", "SE" }
local PASSOS_5 = { "W", "SW", "S", "SE", "E" }

--- Guarda para onde olhar. nil = de frente. O giro acontece no passo abaixo.
function Avatar.lookAt(angulo)
    Avatar.alvoAngulo = angulo
end

--- Escolhe a posicao a partir da componente horizontal, com histerese: sair de
--- um estado exige ir mais longe do que entrar nele.
local function escolherPasso(cm, atual, passos)
    local n = #passos
    local entra = 1 / n * 1.15
    local sai = entra * 0.62

    local alvo = math.floor((cm + 1) / 2 * n) + 1
    if alvo < 1 then alvo = 1 elseif alvo > n then alvo = n end
    local nome = passos[alvo]

    if atual and atual ~= nome then
        -- Perto da fronteira, fica onde esta.
        local centroAtual = nil
        for i, v in ipairs(passos) do
            if v == atual then centroAtual = (i - 0.5) / n * 2 - 1 end
        end
        if centroAtual and math.abs(cm - centroAtual) < sai then
            return atual
        end
    end
    return nome
end

--[[
    O giro e em degraus, mas o degrau da para DISFARCAR.

    Duas camadas trabalhando juntas:

      1. A orientacao real, discreta (setDirection).
      2. Um balanco horizontal continuo e pequeno (setXOffset), acompanhando o
         mouse com suavizacao exponencial.

    A segunda camada e o truque. Sozinha ela so faz o modelo escorregar - foi
    rejeitada com razao quando era a unica coisa acontecendo. Somada a rotacao
    de verdade, ela mantem alguma coisa SEMPRE se movendo, e o olho passa a ler
    o conjunto como movimento continuo em vez de um corte seco.

    Alem disso, no instante em que a orientacao troca, o balanco leva um empurrao
    no sentido CONTRARIO ao giro, que decai em ~100ms. E amortecimento classico:
    o deslocamento contrario cobre o salto e o retorno suave devolve a posicao.
    Sem ele o degrau aparece como um piscar; com ele parece que a cabeca virou.

    A amplitude e proposital e pequena (avatarLean). Alta demais e a translacao
    volta a dominar e vira o escorregao de antes.
]]
local function passoDeGiro(p, yBase)
    local C = TheZims.CFG

    -- A altura nunca muda: quem vira a cabeca nao sobe nem desce.
    if p.zimYSet ~= yBase then
        pcall(function() p:setYOffset(yBase) end)
        p.zimYSet = yBase
    end

    local passos = (C.avatarTurnSteps == 5) and PASSOS_5 or PASSOS_3
    local cm = 0
    local nome = "S"
    if C.avatarFollowMouse and Avatar.alvoAngulo then
        cm = math.cos(math.rad(Avatar.alvoAngulo))
        if C.avatarMirror then cm = -cm end
        nome = escolherPasso(cm, p.zimDir, passos)
    end

    -- ---- camada 1: a orientacao, em degraus
    if p.zimDir ~= nome then
        local antes = p.zimDir
        local ok = pcall(function() p:setDirection(IsoDirections[nome]) end)
        if ok then
            if antes then
                -- Empurrao contrario ao giro, para cobrir o salto.
                local iAntes, iDepois = 0, 0
                for i, v in ipairs(passos) do
                    if v == antes then iAntes = i end
                    if v == nome then iDepois = i end
                end
                local sentido = (iDepois > iAntes) and 1 or -1
                p.zimKick = -sentido * (C.avatarTurnKick or 0.02)
            end
            p.zimDir = nome
        end
    end

    -- ---- camada 2: o balanco continuo
    local agora = getTimestampMs()
    -- Limita o dt para uma travada do jogo nao dar um pulo.
    local dt = math.min(100, agora - (p.zimLeanMs or agora)) / 1000
    p.zimLeanMs = agora

    local alvo = cm * (C.avatarLean or 0.025)
    local k = 1 - math.exp(-dt / (C.avatarLeanTau or 0.14))
    p.zimLeanX = (p.zimLeanX or 0) + (alvo - (p.zimLeanX or 0)) * k
    -- O empurrao decai sozinho.
    p.zimKick = (p.zimKick or 0) * math.exp(-dt / 0.10)

    local x = p.zimLeanX + p.zimKick
    -- Menos de meio milesimo nao muda pixel nenhum; evita conversa a toa com
    -- o Java quando o cursor esta parado.
    if math.abs(x - (p.zimXSet or 999)) > 0.0005 then
        pcall(function() p:setXOffset(x) end)
        p.zimXSet = x
    end
end

--- Cria o painel na primeira vez que for pedido. Devolve nil se a API 3D nao
--- existir nesta versao -- nesse caso a roda simplesmente fica sem cabeca.
function Avatar.get()
    if Avatar.panel then return Avatar.panel end
    if Avatar.failed then return nil end

    local ok, panel = pcall(function()
        local size = TheZims.CFG.innerRadius * 2 * (TheZims.CFG.avatarScale or 1)
        local p = ISUI3DModel:new(0, 0, size, size)
        p:setVisible(false)
        p:addToUIManager() -- instancia o javaObject por dentro

        p:setIsometric(false)
        p:setDirection(IsoDirections.S)
        p:setState("idle")
        local zoom, yoff = Avatar.enquadramento()
        p:setZoom(zoom)
        p:setYOffset(yoff)
        p:setXOffset(0)
        p.zimZoom, p.zimYOff = zoom, yoff

        -- Some sozinho quando o menu para de pedir por ele.
        local basePrerender = p.prerender
        p.prerender = function(self)
            basePrerender(self)
            if getTimestampMs() - (self.zimLastUsed or 0) > STALE_MS then
                self:setVisible(false)
            end
        end

        --[[
            O painel fica POR CIMA do miolo, entao ele - e nao o menu - recebe o
            clique na cabeca. Tentar torna-lo transparente com
            setWantMouseEvents(false) nao e confiavel aqui: ISUI3DModel
            SUBSTITUI ISUIElement:instantiate() por uma versao que so copia
            x/y/largura/altura e nunca chama setConsumeMouseEvents, entao o
            estado de captura vem do construtor Java e nao do Lua.

            Em vez de brigar com isso, o painel assume o clique de proposito e
            repassa para o menu dono. Funciona respeitando ou nao a flag.
            De quebra mata o arrastar-para-girar do ISUI3DModel, que roubaria o
            clique e giraria o personagem.
        ]]
        p:setWantMouseEvents(true)

        p.onMouseDown = function() return true end
        p.onMouseUp = function()
            -- Sem dono e o caso da previa na janela de opcoes: ali o painel e
            -- so demonstracao, entao o clique nao faz nada.
            local menu = Avatar.owner
            if menu and menu.zimHubAction and menu:getIsVisible() then
                menu:zimHubAction()
            end
            return true
        end
        p.onRightMouseDown = function() return true end
        p.onRightMouseUp = function()
            local menu = Avatar.owner
            if menu and menu.closeAll then pcall(function() menu:closeAll() end) end
            Avatar.hide()
            return true
        end
        -- Sem rotacao: o menu nao e um provador de roupa.
        p.onMouseMove = function() return true end
        p.onMouseMoveOutside = function() return true end
        p.onMouseUpOutside = function() return true end

        return p
    end)

    if not ok or not panel then
        Avatar.failed = true
        print("[TheZims] avatar 3D indisponivel, seguindo sem a cabeca: " .. tostring(panel))
        return nil
    end

    Avatar.panel = panel
    return panel
end

--- Mostra a cabeca de `character` centrada em (cx, cy), em coordenadas de tela.
-- `menu` e quem esta desenhando: o painel repassa o clique para ele.
function Avatar.showAt(character, cx, cy, diameter, menu)
    if not TheZims.CFG.showAvatar then return end
    local p = Avatar.get()
    if not p or not character then return end
    Avatar.owner = menu

    pcall(function()
        if p.zimCharacter ~= character then
            p:setCharacter(character)
            p.zimCharacter = character
        end
        -- Reaplica o zoom se ele mudou. O painel e criado uma vez so, entao sem
        -- isto mexer no avatarZoom exigiria reiniciar o jogo.
        local zoom, yoff = Avatar.enquadramento()
        if p.zimZoom ~= zoom then
            p:setZoom(zoom)
            p.zimZoom = zoom
            TheZims.log(string.format("enquadramento -> zoom %s, yOffset %.2f", tostring(zoom), yoff))
        end
        passoDeGiro(p, yoff)
        if p.width ~= diameter then
            p:setWidth(diameter)
            p:setHeight(diameter)
        end
        p:setX(cx - diameter / 2)
        p:setY(cy - diameter / 2)
        p.zimLastUsed = getTimestampMs()
        p:setVisible(true)
        p:bringToTop() -- por cima do fundo do miolo, dentro do buraco da roda
    end)
end

function Avatar.hide()
    if Avatar.panel then
        pcall(function() Avatar.panel:setVisible(false) end)
    end
end

--- Chamado ao trocar o preset de tamanho. showAt ja reajusta largura e altura,
--- entao aqui basta esconder para nao piscar no diametro antigo.
function Avatar.resize()
    Avatar.hide()
end
