--[[
    The Zims - menu radial estilo The Sims para Project Zomboid Build 42.

    Todos os arquivos penduram no global `TheZims` e leem a config na hora do
    uso, entao a ordem de carregamento entre TheZims_*.lua nao importa.

    As preferencias do jogador ficam num arquivo local, nao nas sandbox options:
        C:/Users/<voce>/Zomboid/TheZims.ini
    Mesma decisao do DeathLogMP - isto e gosto de cada um, nao regra do servidor.
]]

TheZims = TheZims or {}

TheZims.CFG = {
    -- Chave geral. A tecla de atalho inverte isso em tempo real.
    enabled = true,

    -- Quais menus de contexto viram roda.
    --   "world" -> so o menu de clique direito no mundo (recomendado)
    --   "all"   -> todos, incluindo os paineis de inventario
    applyTo = "world",

    -- ---------------------------------------------------------- geometria
    -- Preenchidos por aplicarTamanho(); ver TAMANHOS abaixo.
    innerRadius = 50,
    pillRadius = 84,
    labelMaxWidth = 150,

    --[[
        Quatro opcoes por lado, oito por pagina, como no The Sims.

        Posicao fixa em coluna nao tem como sobrepor. A versao anterior
        espalhava as opcoes por angulo no circulo inteiro e, com muitas opcoes,
        pilulas vizinhas caiam em alturas parecidas e se cruzavam.

        Topo e base sao navegacao (voltar e "Mais..."), nunca opcao.
    ]]
    -- "roda"    -> arco em volta da cabeca, como no The Sims (padrao)
    -- "colunas" -> duas colunas retas dos lados
    layout = "roda",
    -- Folga horizontal minima entre a cabeca e a borda interna de qualquer
    -- pilula. E o que impede uma pilula de angulo ingreme de nascer em cima do
    -- rosto: a 60 graus o recuo natural seria cos(60)*raio, menor que a cabeca.
    headClearance = 14,
    --[[
        A roda e uma ELIPSE: o raio vertical e uma fracao do horizontal.

        Nao e escolha estetica. Com raio igual nos dois eixos, a roda de 7
        ocupava 166px de altura e a coluna de 8 ocupava 126 - dava um salto de
        40px ao virar a pagina, que se via como o menu "pulando". Com 0.75 a
        diferenca cai para 2px e a troca de arranjo passa despercebida.
    ]]
    pillRadiusYFactor = 0.75,
    slotsPerSide = 4,
    --[[
        Respiro vertical entre pilulas da mesma coluna.

        Comecou em 8 e ficou tudo grudado: a altura da linha virava ~30px para
        uma pilula de ~22, sobrando 8px de folga. O arranjo antigo, por angulo,
        separava as pilulas em ~45px sem querer - era isso que dava a impressao
        de espaco. Aqui a folga tem que ser pedida explicitamente.
    ]]
    rowGap = 20,
    -- Afastamento extra de "Anterior" e "Mais...". Voltou a zero: com a pagina
    -- cheia caindo para coluna, as opcoes ja ficam alinhadas e a navegacao nao
    -- precisa mais se defender do arco.
    navGap = 0,
    hitPadding = 80,     -- o quanto a faixa clicavel cresce para fora
    pixelsPerSegment = 4, -- 1 quad por N pixels de arco; menor = mais redondo

    -- ------------------------------------------------------------ pilulas
    pillPadX = 13,
    pillPadY = 5,
    pillHoverGrow = 2,
    -- Raio do orbe em relacao a altura da pilula. Subiu de 0.60 porque o icone
    -- dentro dele estava pequeno demais para se reconhecer de relance.
    orbScale = 0.70,
    -- Diametro do icone em relacao ao raio do orbe. 1.55 deixa o icone ocupando
    -- ~78% do circulo: enche sem encostar na borda.
    iconScale = 1.55,
    labelFont = UIFont.Small,

    -- ------------------------------------------------------------- avatar
    showAvatar = true,
    --[[
        Enquadramento: SO O ROSTO, como no The Sims.

        Mexa apenas no avatarZoom. Maior = mais perto do rosto. O yOffset sai
        dele sozinho (TheZims_Avatar.yOffsetPara) e nao deve ser fixado a mao:
        os dois andam juntos, e subir um sem o outro joga a cabeca para fora do
        quadro - foi exatamente o que aconteceu quando tentei 24 com -1.18, que
        deveria ser -1.35.

        A conta vem dos dois pontos de calibracao do proprio jogo, em
        CharacterCreationAvatar: (zoom -3, yOffset 0) para corpo inteiro e
        (zoom 14, yOffset -0.85) para rosto. Os dois caem numa reta de
        inclinacao -0.05.

        A reta esta calibrada com dois pontos medidos NESTE painel: zoom 14 com
        yOffset -0.85 e zoom 20 com -0.90 (ver TheZims_Avatar.yOffsetPara).
        Os valores da tela de criacao de personagem nao servem aqui - o painel
        dela e alto e grande, o nosso e pequeno e quadrado, e o yOffset e
        relativo ao painel.

        O ajuste tambem esta na janela (K), com o rosto ao vivo do lado.
    ]]
    avatarZoom = 20,
    -- Deixe nil para derivar do zoom. So preencha para forcar um valor.
    avatarYOffset = nil,
    -- Ajuste fino de altura, somado ao valor derivado. Negativo sobe a cabeca.
    avatarYNudge = 0,
    --[[
        Diametro do painel = innerRadius * 2 * avatarScale.

        NAO e um controle de zoom. O painel e uma janela sobre o modelo: painel
        maior mostra MAIS corpo no mesmo tamanho, nao um rosto maior. Foi o erro
        da tentativa anterior - 1.40 aqui apareceu com o corpo inteiro.
        Mantenha em 1.0 para o corte fechado no rosto.
    ]]
    avatarScale = 1.0,
    -- O personagem vira na direcao do mouse e trava na opcao sob o cursor.
    avatarFollowMouse = true,
    -- Inverte o lado do giro, caso saia espelhado.
    avatarMirror = false,
    --[[
        Quantas posicoes o giro usa: 3 (SW, S, SE) ou 5 (acrescenta W e E, dois
        perfis completos).

        NAO existe giro continuo. O UI3DModel so orienta o modelo por
        setDirection(IsoDirections), que tem 8 posicoes fixas; setAngle nao e
        um metodo dele. Entao o movimento e em degraus por limitacao da engine,
        e 3 posicoes e o que menos chama atencao.
    ]]
    avatarTurnSteps = 3,
    --[[
        Camada continua que disfarca o degrau do giro.

        avatarLean   - amplitude do balanco horizontal que acompanha o mouse.
                       Pequena de proposito: alta demais e a translacao domina e
                       o personagem volta a escorregar em vez de virar.
                       0 desliga e o giro fica seco de novo.
        avatarLeanTau- constante de tempo da suavizacao, em segundos.
        avatarTurnKick- empurrao contrario no instante da troca de orientacao,
                       que decai em ~100ms e cobre o salto.
    ]]
    avatarLean = 0.025,
    avatarLeanTau = 0.14,
    avatarTurnKick = 0.02,
    -- O circulo escuro atras da cabeca: solido ate solidFrac do raio e some
    -- ate fadeFrac. Sem aro, so o esmaecido.
    hubSolidFrac = 0.62,
    hubFadeFrac = 1.22,
    hubFadeBands = 22, -- mais faixas = degrade mais liso, sem aneis visiveis


    -- ------------------------------------------------------------ demais
    openMs = 120,          -- animacao de abertura; 0 desliga
    hoverSound = true,
    hoverSoundName = "UIActivateButton",
    clickSound = true,
    -- Registrado em media/scripts/TheZimsSounds.txt. "UISelectListItem" e o
    -- som ja embutido no PZ, usado quando o jogador escolhe "Padrao do jogo".
    clickSoundName = "TheZimsClick",
    clickSoundVanilla = "UISelectListItem",
    showHoverWedge = false,
    debug = false,
    -- Substitui o menu real por 20 opcoes dificeis, para testar o pior caso
    -- sem ter que cacar um objeto lotado no mundo.
    debugFakeMenu = false,
    --[[
        DEMONSTRACAO: finge que a DLC deste id nao esta instalada, para ver o
        aviso e o botao de download sem desinstalar nada. So visual - o mod
        continua carregado e funcionando.

        Para demonstrar de novo: = "ZimPie". Desligado depois de aprovado o
        visual do fluxo de download.
    ]]
    debugFingirAusente = false,
}

--- Azul escuro com texto branco: o padrao pedido. E tambem o ponto de partida
--- do seletor de cor, entao mexer aqui muda o "restaurar padroes".
TheZims.COR_FUNDO_PADRAO = { r = 0.106, g = 0.231, b = 0.435 }
TheZims.COR_TEXTO_PADRAO = { r = 1.000, g = 1.000, b = 1.000 }

--- Presets de tamanho. Sao tres numeros que andam juntos; mexer em um so
--- desencaixa a roda, por isso viram conjunto em vez de tres ajustes soltos.
--[[
    Angulos da roda, um conjunto por quantidade de opcoes.
    0 = direita, -90 = cima, +90 = baixo.

    Sao tabelados, e nao 360/N, porque a divisao uniforme colocava pilulas
    vizinhas em alturas quase iguais e elas se cruzavam. Cada conjunto aqui foi
    conferido: nenhuma sobreposicao vertical do mesmo lado e nenhuma invadindo
    a cabeca.

    O topo e a base ficam livres de proposito - sao da paginacao.

    Acima de 8 nao existe conjunto: e onde a paginacao entra.
]]
TheZims.ANGULOS = {
    [1] = { 0 },
    [2] = { 0, 180 },
    [3] = { -32, 32, 180 },
    [4] = { -32, 32, 148, 212 },
    [5] = { -52, 0, 52, 148, 212 },
    [6] = { -52, 0, 52, 128, 180, 232 },
    [7] = { -60, -20, 20, 60, 128, 180, 232 },
    [8] = { -60, -20, 20, 60, 120, 160, 200, 240 },
}

-- pillRadius e a distancia do centro ate a borda INTERNA da coluna. Precisa
-- folgar sobre innerRadius, senao a pilula encosta no esmaecido da cabeca.
TheZims.TAMANHOS = {
    compacto = { innerRadius = 44, pillRadius = 80,  labelMaxWidth = 120 },
    normal   = { innerRadius = 50, pillRadius = 96,  labelMaxWidth = 150 },
    grande   = { innerRadius = 60, pillRadius = 116, labelMaxWidth = 180 },
}

function TheZims.aplicarTamanho(nome)
    local t = TheZims.TAMANHOS[nome] or TheZims.TAMANHOS.normal
    TheZims.CFG.innerRadius = t.innerRadius
    TheZims.CFG.pillRadius = t.pillRadius
    TheZims.CFG.labelMaxWidth = t.labelMaxWidth
    TheZims.PREF.tamanho = TheZims.TAMANHOS[nome] and nome or "normal"
    -- O avatar foi criado com o diametro antigo; refaz na proxima abertura.
    if TheZims.Avatar and TheZims.Avatar.resize then TheZims.Avatar.resize() end
end

-- Paleta de reserva em azul escuro com texto branco. So aparece se o
-- TheZims_Theme nao tiver carregado; no uso normal a paleta e sempre gerada a
-- partir de corFundo (modo fixo) ou do chapeu/cabelo (modo personagem).
TheZims.COLORS = {
    pillBorder   = { r = 0.04, g = 0.09, b = 0.18, a = 0.95 },
    pill         = { r = 0.11, g = 0.23, b = 0.44, a = 0.93 },
    pillHi       = { r = 0.22, g = 0.38, b = 0.63, a = 0.45 },
    pillHover    = { r = 0.20, g = 0.38, b = 0.68, a = 0.98 },
    pillHiHover  = { r = 0.38, g = 0.57, b = 0.85, a = 0.50 },
    pillDisabled = { r = 0.14, g = 0.17, b = 0.24, a = 0.78 },

    orb          = { r = 0.15, g = 0.30, b = 0.54, a = 0.96 },
    orbHover     = { r = 0.32, g = 0.51, b = 0.80, a = 1.00 },
    orbHi        = { r = 0.55, g = 0.72, b = 0.96, a = 0.55 },

    text         = { r = 1.00, g = 1.00, b = 1.00, a = 1.00 },
    textDisabled = { r = 0.62, g = 0.64, b = 0.73, a = 0.90 },

    hubBack      = { r = 0.02, g = 0.02, b = 0.03, a = 0.92 },
    hoverWedge   = { r = 0.45, g = 0.50, b = 0.85, a = 0.13 },
}

--- Chave geral consultada por todos os hooks.
function TheZims.isOn()
    return TheZims.CFG.enabled == true
end

function TheZims.log(msg)
    if TheZims.CFG.debug then
        print("[TheZims] " .. tostring(msg))
    end
end

------------------------------------------------------------------
-- Preferencias em disco
------------------------------------------------------------------
local ARQUIVO = "TheZims.ini"

TheZims.PREF = TheZims.PREF or {
    ligado = true,
    tamanho = "normal",
    mostrarCabeca = true,
    corFundo = { r = 0.106, g = 0.231, b = 0.435 },
    corTexto = { r = 1, g = 1, b = 1 },
    som = true,                                         -- ao passar o mouse
    somClique = "mod",                                  -- "mod" | "vanilla" | "off"
    zoomRosto = 20,                                     -- ajustavel na janela
    alturaRosto = 0,                                    -- ajuste fino, em passos de 0.05
    olharMouse = true,
    espelharOlhar = false,
    arranjo = "roda",                                   -- "roda" | "colunas"
    --[[
        Modo de teste: NAO e gravado no .ini e NAO e lido dele.

        E ferramenta de desenvolvimento, nao ajuste de jogador. Nao persistindo,
        ele sempre nasce desligado a cada partida - entao nao ha como uma versao
        publicada sair com ele ativo, nem por descuido nosso nem por alguem que
        deixou marcado e esqueceu.

        Para usar: marcar na janela (K). Vale so ate fechar o jogo.
    ]]
    menuDeTeste = false,
    fatiaDeDirecao = false,
    animacao = true,
    ondeAplicar = "world",
    --[[
        O aviso de "faltou a DLC do menu" ja foi visto?

        Persistido para aparecer UMA VEZ e nunca mais. Quem decidir nao instalar
        a DLC nao deve ser cobrado a cada partida - a escolha e dele, e repetir
        o aviso seria empurrar, nao informar.
    ]]
    avisoDlcVisto = false,
}

--[[
    A FAMILIA - o catalogo de "DLC" da aba Principal.

    Cada entrada e um mod irmao. O `id` tem que bater exatamente com o `id=` do
    mod.info do outro mod: e por ele que `getModInfoByID` acha o mod, e essa e a
    unica forma de distinguir INSTALADO de ATIVO.

    Antes isto era `ZimBalloons ~= nil`, checando o global. Nao servia: o global
    so nasce se o mod chegou a carregar, entao instalado-porem-desativado e
    nao-instalado davam a mesma resposta - e a janela dizia "ausente" para um
    mod que o jogador tem ali, so precisando marcar na lista.

    `workshop` so existe para o que ja foi publicado. Sem id nao ha para onde
    mandar o jogador, e o cartao mostra "em breve" em vez de um botao que abriria
    a Steam numa pagina inexistente.

    O Death Log MP NAO entra aqui. Ele e nosso, mas nao e do universo The Zims:
    nao depende deste mod, nao estende nada dele e funciona sozinho num servidor
    sem The Zims instalado. Misturar os dois no mesmo catalogo venderia como
    expansao o que e outro produto.

    O proprio The Zims NAO entra na lista. Ele e a prateleira, nao um item
    dela: o titulo no topo da aba ja diz o nome, e uma capa "The Zims" no meio
    das expansoes sugeriria que da para instalar a base separadamente do que ela
    ja e. Quem esta olhando a janela obviamente tem a base.

    `aba` e o nome que a DLC usa em TheZims.registrarSecao. E por ele que o
    botao "Abrir opcoes" acha para onde ir; sem casar, o botao vira "Ver na
    Steam" mesmo com o mod instalado.

    `construcao = true` marca DLC que ainda estamos escrevendo. Ela aparece na
    estante com o botao DESABILITADO e escrito "Em construcao", em vez de
    sumir da lista ate ficar pronta -- mostrar o que vem faz parte do que a
    janela serve para dizer, e evita a pergunta "o mod so tem isso?".
]]
TheZims.FAMILIA = {
    --[[
        `essencial` = sem esta DLC a base nao serve para nada.

        E o que o aviso de "base sozinha" consulta. Perguntar "alguma DLC esta
        ativa?" nao servia: quem tivesse o Zim Actions marcado passava no teste
        e nunca era avisado de que o MENU sumiu - que e exatamente o caso de
        quem atualiza vindo da versao antiga.

        `workshop` fica nil ate publicar. Assim que o item existir, cole o id
        aqui: e ele que faz o botao "Obter na Steam" do cartao levar a algum
        lugar, no lugar de um "Em breve" desabilitado.
    ]]
    { id = "ZimPie",      workshop = "3779890822", chave = "DlcPie", aba = "Zim Pie", essencial = true },
    -- Existe e carrega, mas nunca foi testado em jogo nem publicado: para quem
    -- joga, e o mesmo que nao existir ainda.
    { id = "ZimBalloons", workshop = nil, chave = "DlcBalloons", aba = "Zim Balloons", construcao = true },
    -- Funciona, mas ainda nao passou por teste de jogador. Fica em construcao
    -- ate o acabamento; so o Zim Pie esta pronto para quem joga.
    { id = "ZimActions",  workshop = nil, chave = "DlcActions",  aba = "ZimActions", construcao = true },
    { id = "ZimBath",     workshop = nil, chave = "DlcBath",     aba = "Zim Bath",  construcao = true },
    { id = "ZimPanel",    workshop = nil, chave = "DlcPanel",    aba = "Zim Panel", construcao = true },
}

--[[
    O interruptor de cada DLC na janela: como LER se esta ligada e como
    ALTERNAR. Por expansao, porque cada uma guarda o proprio "ligado" num
    lugar diferente - o do Zim Pie e a preferencia `ligado` da base.

    Sem entrada aqui a aba mostra o botao desabilitado: e o caso das DLCs que
    ainda nao tem um liga/desliga proprio. Nao e o mesmo que ativar o MOD na
    lista do jogo - isso exige recarregar o Lua e nao da para fazer daqui.
]]
TheZims.DLC_CHAVE = {
    ZimPie = {
        ler = function() return TheZims.PREF.ligado ~= false end,
        alternar = function()
            TheZims.PREF.ligado = not (TheZims.PREF.ligado ~= false)
            TheZims.aplicarPrefs()
            TheZims.salvarPrefs()
        end,
    },
}

--- Nome de exibicao quando o mod NAO esta instalado - ai nao ha mod.info para
--- perguntar. Com o mod presente preferimos sempre `modInfo:getName()`, que ja
--- vem no idioma dele.
TheZims.NOME_PADRAO = {
    -- Tem de bater com o `name=` do mod.info dele: a janela usa
    -- modInfo:getName() quando o mod esta instalado e cai aqui quando nao esta.
    -- Nomes diferentes fariam o mesmo cartao mudar de titulo conforme o estado.
    ZimPie      = "The Zims - Menu Style DLC",
    ZimBalloons = "Zim Balloons",
    ZimActions  = "Zim Actions",
    ZimBath     = "Zim Bath",
    ZimPanel    = "Zim Panel",
}

--[[
    A capa de cada expansao, no formato de caixa de jogo.

    Mora no NOSSO mod, nao no mod que ela representa: a capa do Zim Panel
    precisa aparecer na prateleira ANTES de o Zim Panel existir - e esse o ponto
    de mostrar o que ainda vem. Se dependesse do arquivo estar no outro mod, so
    apareceria depois de instalado, quando ja nao serve para nada.

    Faltando o arquivo, o cartao cai no poster do proprio mod e, na falta dele,
    num quadro vazio - nunca some, para a prateleira nao mudar de forma.
]]
function TheZims.arteDaExpansao(id)
    local t = nil
    pcall(function() t = getTexture("media/ui/TheZims_DLC_" .. id .. ".png") end)
    return t
end

--[[
    Estado real de cada mod da familia, calculado UMA vez por abertura da
    janela. Mod nao aparece nem some no meio da sessao, entao recalcular por
    quadro seria varrer a lista de ativos 60 vezes por segundo a toa.

    Devolve: "ativo" | "inativo" (instalado, desmarcado) | "ausente".
]]
function TheZims.estadoDaFamilia()
    local ativos = {}
    pcall(function()
        local lista = getActivatedMods()
        for i = 0, lista:size() - 1 do
            ativos[lista:get(i)] = true
        end
    end)

    local out = {}
    for _, m in ipairs(TheZims.FAMILIA) do
        local info = nil
        pcall(function() info = getModInfoByID(m.id) end)

        local estado
        if not info then estado = "ausente"
        elseif ativos[m.id] then estado = "ativo"
        else estado = "inativo" end

        --[[
            Modo demonstracao: trata este id como ausente e empresta o item da
            Workshop do The Zims como alvo do botao de download - e o unico id
            publicado, entao o overlay abre uma pagina REAL para testar o
            fluxo inteiro. Some sozinho quando debugFingirAusente = false.
        ]]
        local demoWorkshop = nil
        if TheZims.CFG.debugFingirAusente == m.id then
            estado = "ausente"
            demoWorkshop = "3778403871"
        end

        -- Ordem de preferencia da arte: capa nossa -> poster do proprio mod ->
        -- nada. A capa vem primeiro porque e a unica que existe para expansao
        -- ainda nao lancada, e a unica no formato de caixa.
        local poster = TheZims.arteDaExpansao(m.id)
        if not poster and info then
            pcall(function()
                if info:getPosterCount() > 0 then poster = getTexture(info:getPoster(0)) end
            end)
        end

        local nome = TheZims.NOME_PADRAO[m.id] or m.id
        if info then pcall(function() nome = info:getName() or nome end) end

        --[[
            `getModVersion()` devolve STRING VAZIA quando o mod.info nao traz a
            linha, nao nil. O teste ingenuo `if versao then` passava e o cartao
            saia escrito "instalado v" -- com o "v" solto e nada depois.
            Normalizamos para nil aqui, para quem le nao precisar saber disso.
        ]]
        local versao = nil
        if info then pcall(function() versao = info:getModVersion() end) end
        if type(versao) ~= "string" or versao == "" then versao = nil end

        out[m.id] = { estado = estado, poster = poster, nome = nome, versao = versao,
                      def = m, workshop = m.workshop or demoWorkshop }
    end
    return out
end

local function paraBool(s) return s == "true" or s == "1" end

--- Cor gravada como "r,g,b" com tres casas. Guardar em texto simples mantem o
--- .ini legivel e editavel a mao, igual ao resto do arquivo.
local function corParaTexto(c)
    return string.format("%.3f,%.3f,%.3f", c.r or 0, c.g or 0, c.b or 0)
end

local function textoParaCor(s, padrao)
    local r, g, b = string.match(s, "^%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)%s*$")
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if not (r and g and b) then return padrao end
    local function lim(v) return math.max(0, math.min(1, v)) end
    return { r = lim(r), g = lim(g), b = lim(b) }
end

--- Joga PREF dentro de CFG. Tudo que a janela mexe passa por aqui.
function TheZims.aplicarPrefs()
    local P, C = TheZims.PREF, TheZims.CFG
    C.enabled = P.ligado ~= false
    C.showAvatar = P.mostrarCabeca ~= false
    C.hoverSound = P.som ~= false
    C.clickSound = P.somClique ~= "off"
    C.showHoverWedge = P.fatiaDeDirecao == true
    C.openMs = (P.animacao ~= false) and 120 or 0
    C.applyTo = (P.ondeAplicar == "all") and "all" or "world"
    C.avatarZoom = P.zoomRosto or 20
    C.avatarYNudge = P.alturaRosto or 0
    C.avatarFollowMouse = P.olharMouse ~= false
    C.avatarMirror = P.espelharOlhar == true
    C.layout = (P.arranjo == "colunas") and "colunas" or "roda"
    C.debugFakeMenu = P.menuDeTeste == true
    TheZims.aplicarTamanho(P.tamanho)
    if TheZims.Theme then TheZims.Theme.invalidate() end
end

--- Nome do som de clique conforme a escolha do jogador. Devolve nil quando
--- desligado, para quem toca nao precisar checar duas coisas.
function TheZims.somDeClique()
    local escolha = TheZims.PREF.somClique
    if escolha == "off" then return nil end
    if escolha == "vanilla" then return TheZims.CFG.clickSoundVanilla end
    return TheZims.CFG.clickSoundName
end

--[[
    Toca um som de UI da familia.

    POR QUE A FUNCAO CONTINUA EXISTINDO SEM A BARRA DE VOLUME
    ---------------------------------------------------------
    Ela nasceu para aplicar o volume proprio do mod: `playUISound(nome)` nao
    aceita volume - a assinatura no jar e `(Ljava/lang/String;)J`, so o nome -
    e o jeito era pegar o handle FMOD devolvido e chamar `setVolume(J, F)` no
    `getUIEmitter()`. Funcionava, mas a barra saiu da tela: quem quer o som do
    jogo mais baixo ja tem o controle de UI nas opcoes do PZ, e mais um lugar
    para o mesmo ajuste so confunde. Os sons voltam a sair no volume normal.

    O NOME fica. O Zim Pie ja publicado (item 3779890822) chama
    `TheZims.tocarSomUI` nos dois sons do menu circular; some-la aqui deixaria o
    menu circular mudo na maquina de quem instalou a DLC antes desta versao.
    Como e ele quem toca hover e clique, a base tem que continuar oferecendo o
    ponto de entrada mesmo agora que nao faz mais nada alem de repassar.

    E se um dia a barra voltar, ela volta so aqui dentro.
]]
function TheZims.tocarSomUI(nome)
    if not nome then return end
    pcall(function() getSoundManager():playUISound(nome) end)
end

function TheZims.carregarPrefs()
    local ok = pcall(function()
        local r = getFileReader(ARQUIVO, true)
        if not r then return end
        local linha = r:readLine()
        while linha do
            local chave, valor = string.match(linha, "^%s*([%w_]+)%s*=%s*(.-)%s*$")
            if chave and valor then
                if chave == "ligado"          then TheZims.PREF.ligado = paraBool(valor)
                elseif chave == "mostrarCabeca"   then TheZims.PREF.mostrarCabeca = paraBool(valor)
                elseif chave == "som"             then TheZims.PREF.som = paraBool(valor)
                elseif chave == "fatiaDeDirecao"  then TheZims.PREF.fatiaDeDirecao = paraBool(valor)
                elseif chave == "animacao"        then TheZims.PREF.animacao = paraBool(valor)
                elseif chave == "corFundo"        then
                    TheZims.PREF.corFundo = textoParaCor(valor, TheZims.COR_FUNDO_PADRAO)
                elseif chave == "corTexto"        then
                    TheZims.PREF.corTexto = textoParaCor(valor, TheZims.COR_TEXTO_PADRAO)
                elseif chave == "somClique"       then
                    TheZims.PREF.somClique = (valor == "vanilla" and "vanilla")
                        or (valor == "off" and "off") or "mod"
                elseif chave == "zoomRosto"       then
                    TheZims.PREF.zoomRosto = tonumber(valor) or 20
                elseif chave == "alturaRosto"     then
                    TheZims.PREF.alturaRosto = tonumber(valor) or 0
                elseif chave == "avisoDlcVisto"   then
                    TheZims.PREF.avisoDlcVisto = paraBool(valor)
                elseif chave == "olharMouse"      then
                    TheZims.PREF.olharMouse = paraBool(valor)
                elseif chave == "espelharOlhar"   then
                    TheZims.PREF.espelharOlhar = paraBool(valor)
                -- "arranjo" deixou de ser lido: a roda vira colunas sozinha
                -- quando a pagina tem 8 opcoes, e o seletor saiu da janela.
                -- Quem tinha "colunas" salvo volta ao padrao.
                -- "menuDeTeste" nao e lido de proposito: ver a nota em PREF.
                elseif chave == "tamanho"         then
                    TheZims.PREF.tamanho = TheZims.TAMANHOS[valor] and valor or "normal"
                elseif chave == "ondeAplicar"     then
                    TheZims.PREF.ondeAplicar = (valor == "all") and "all" or "world"
                end
            end
            linha = r:readLine()
        end
        r:close()
    end)
    if not ok then print("[TheZims] nao consegui ler " .. ARQUIVO .. ", usando padroes") end
    TheZims.aplicarPrefs()
    return TheZims.PREF
end

function TheZims.salvarPrefs()
    local ok = pcall(function()
        local w = getFileWriter(ARQUIVO, true, false)   -- cria, nao acrescenta
        if not w then return end
        w:write("# The Zims - preferencias deste jogador\r\n")
        w:write("# Apagar este arquivo restaura os padroes.\r\n")
        w:write("# Cores sao r,g,b de 0 a 1.\r\n")
        for _, k in ipairs({ "ligado", "tamanho", "mostrarCabeca",
                             "som", "somClique",
                             "fatiaDeDirecao", "animacao",
                             "ondeAplicar", "zoomRosto", "alturaRosto",
                             "olharMouse", "espelharOlhar", "arranjo", "avisoDlcVisto" }) do
            w:write(k .. "=" .. tostring(TheZims.PREF[k]) .. "\r\n")
        end
        w:write("corFundo=" .. corParaTexto(TheZims.PREF.corFundo) .. "\r\n")
        w:write("corTexto=" .. corParaTexto(TheZims.PREF.corTexto) .. "\r\n")
        w:close()
    end)
    if not ok then print("[TheZims] nao consegui gravar " .. ARQUIVO) end
end

if not isServer() then
    Events.OnGameStart.Add(function()
        TheZims.carregarPrefs()
        print(string.format("[TheZims] prefs: ligado=%s tamanho=%s cabeca=%s clique=%s",
            tostring(TheZims.PREF.ligado), tostring(TheZims.PREF.tamanho),
            tostring(TheZims.PREF.mostrarCabeca), tostring(TheZims.PREF.somClique)))
    end)
end
