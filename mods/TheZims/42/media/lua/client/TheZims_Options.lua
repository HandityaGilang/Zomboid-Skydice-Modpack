--[[
    The Zims - janela de configuracao.

    Mesmo desenho do DeathLogMP: o PZ nao tem tela de opcoes por mod no vanilla,
    entao a nossa evita depender do mod "Mod Options".

    Abre por atalho, configuravel em Opcoes > Controles > [The Zims].

    O padrao e K, nao L: o DeathLogMP ja usa L (DeathLogMP_History.lua) e os dois
    mods rodam no mesmo servidor. Com a mesma tecla, um L abriria as duas
    janelas. Se voce tirar o DeathLog, troque para L em Opcoes.

    A previa a direita e desenhada com as mesmas primitivas da roda de verdade,
    entao tamanho e cor mudam na hora, sem precisar fechar e clicar no mundo.
]]

if isServer() then return end

require "ISUI/ISColorPicker"
--[[
    O slider do PZ nao mora em ISUI: ele foi escrito para a tela do radio e
    ficou em RadioCom/ISUIRadio. E uma classe normal e serve para qualquer coisa,
    mas o caminho nao e adivinhavel - sem este require, ISSliderPanel pode ser
    nil dependendo da ordem de carga e a aba Comportamento morre inteira.
]]
require "RadioCom/ISUIRadio/ISSliderPanel"

TheZims = TheZims or {}

local BIND = "TheZims_Options"
local BIND_TOGGLE = "TheZims_Toggle"
do
    -- Os dois atalhos ficam sob um unico cabecalho. Registrar o cabecalho em
    -- dois arquivos faria "[The Zims]" aparecer duas vezes na tela de opcoes.
    local cab = {}; cab.value = "[The Zims]"
    table.insert(keyBinding, cab)
    local b = {}; b.value = BIND; b.key = Keyboard.KEY_K
    table.insert(keyBinding, b)
    local t = {}; t.value = BIND_TOGGLE; t.key = Keyboard.KEY_NONE
    table.insert(keyBinding, t)
end

local function txt(chave, padrao)
    local ok, s = pcall(getText, chave)
    if ok and s and s ~= chave then return s end
    return padrao
end

--[[
    Secoes de outros mods desta familia, anexadas ao fim da coluna.

    Existe para o ZimActions nao precisar de janela propria e de outra tecla:
    sao mods do mesmo servidor, e duas telas de opcao quase iguais so
    confundem quem joga.

    A dependencia so anda num sentido - o The Zims nao sabe quem se
    registrou, e nada aqui quebra se ninguem registrar. Quem se registra e
    que decide se o The Zims esta presente, e some em silencio quando nao
    esta.

        TheZims.registrarSecao("ZimActions", function(janela, x, y, largura)
            ...cria filhos com janela:addChild(...)
            return y  -- o Y logo abaixo do que foi criado
        end)
]]
TheZims.secoesExtras = TheZims.secoesExtras or {}

function TheZims.registrarSecao(nome, construir)
    if type(nome) ~= "string" or type(construir) ~= "function" then return end
    for _, s in ipairs(TheZims.secoesExtras) do
        -- Recarregar o Lua chama isto de novo; substituir evita secao dobrada.
        if s.nome == nome then s.construir = construir; return end
    end
    table.insert(TheZims.secoesExtras, { nome = nome, construir = construir })
end

local PAD, BOX, COMBO_H, BTN_H, ROW = 10, 16, 22, 24, 30
local LABEL_W = 132

--[[
    A coluna da esquerda deixou de ser uma faixa de abas e virou uma PRATELEIRA
    DE CARTOES, cada um com a capa do mod.

    Por isso as medidas mudaram tanto: 26px de altura cabiam so texto, e e a
    arte que faz a coluna ser reconhecivel de relance -- o nome sozinho exigia
    leitura.
]]
--[[
    O cartao E a imagem: sem texto nenhum quando o mod tem arte.

    96 de altura e o ponto em que a arte larga (1,7:1) preenche quase todo o
    cartao com aspect-fit - em 62 ela virava um selo pequeno flutuando no
    meio. Quem nao tem arte ainda cai no nome centrado, para o cartao nunca
    ficar em branco.
]]
local ABA_W, ABA_H = 186, 96
local ABA_GAP = 8
local MENU_TOPO = 22           -- altura do rotulo "Menu" acima dos cartoes
local BARRA_H = 30             -- a barra de titulo, cheia, no alto da janela

--[[
    Recuo interno do painel de conteudo -- o "padding" das telas do The Sims 2.

    Tudo que entra no painel azul respeita isto nos quatro lados. Antes cada
    trecho usava um numero proprio (14 aqui, PAD ali, nada acolÃ¡) e o resultado
    era conteudo encostando na quina arredondada de um lado e sobrando do
    outro.

    CONT_TOPO desce abaixo do titulo da secao que o render desenha no alto do
    painel. Render e createChildren precisam concordar nele, senao o primeiro
    widget senta em cima do texto.
]]
local CONT_PAD  = 16
local CONT_TOPO = 294

--[[
    ORDEM IMPORTA neste arquivo: `local` so e enxergado por funcoes definidas
    DEPOIS dele. Uma constante declarada perto de quem usa, mas abaixo de outro
    consumidor, vira busca global -> nil, e a janela nem abre:

        [TheZims] falha ao abrir a janela: Object tried to call nil
        em createChildren

    Nao confie no "esta definida no arquivo" - o que vale e estar definida
    antes de quem usa.
]]
--- Raio dos cantos do painel. 14 e o ponto onde ainda le como placa moldada;
--- acima disso comeca a virar bolha e o conteudo perde canto util.
local RAIO_PAINEL = 14



--[[
    O estilo da janela. FIXO, nas cores padrao do mod.

    Duas tentativas anteriores erraram por lados opostos: uma fixou o
    azul-lavanda das telas do The Sims 2 -- painel claro chapado sobre o mundo
    escuro do PZ, parecia recortado de outro programa; a outra fez a janela
    seguir a cor escolhida no seletor, e ai ela mudava de cara toda vez que se
    mexia no Zim Pie.

    O seletor de cor configura A RODA, nao o programa. Trocar a cor da roda para
    combinar com o cabelo do personagem nao deveria repintar a janela de opcoes
    junto -- e o equivalente a mudar o tema do Windows ao trocar o papel de
    parede de um jogo.

    Por isso sai de TheZims.COLORS, que e a paleta padrao e nunca muda. A UNICA
    coisa da janela que continua seguindo o jogador e a previa da roda, que e
    justamente o que ele esta ajustando.

    Calculado uma vez: a tabela nao depende de nada que mude, e este estilo e
    pedido varias vezes por quadro.
]]
local ESTILO_CACHE = nil

--- Clareia em direcao ao branco. k=0 devolve a cor, k=1 devolve branco.
local function claro(c, k, a)
    return { r = c.r + (1 - c.r) * k,
             g = c.g + (1 - c.g) * k,
             b = c.b + (1 - c.b) * k,
             a = a or 1 }
end

--- Escurece em direcao ao preto.
local function escuro(c, k, a)
    return { r = c.r * (1 - k), g = c.g * (1 - k), b = c.b * (1 - k), a = a or 1 }
end

local function estilo()
    if ESTILO_CACHE then return ESTILO_CACHE end
    local C = TheZims.COLORS
    local P = C.pill              -- o azul padrao do mod
    local B = C.pillBorder

    --[[
        Painel CLARO, com tudo derivado do mesmo azul.

        Assim o fundo continua claro -- que e o que da a leitura de "caixa de
        jogo" do The Sims -- sem depender do lavanda do desenho de exemplo. Como
        tudo sai de uma cor so, mudar o azul padrao do mod reajusta a janela
        inteira em harmonia.

        Fundo claro obriga TEXTO ESCURO: as duas coisas andam juntas, e trocar
        so uma foi o que quebrou a legibilidade nas tentativas anteriores.
    ]]
    ESTILO_CACHE = {
        -- 0.62 e o ponto medido contra a referencia: claro o bastante para o
        -- texto escuro descansar, mas ainda AZUL. Acima de ~0.75 vira cinza
        -- lavado e perde a identidade do mod.
        fundo  = claro(P, 0.62, 0.98),
        borda  = B,
        brilho = { r = 1, g = 1, b = 1, a = 0.30 },

        -- A barra do topo fica no azul CHEIO: e a unica faixa escura, e e o que
        -- amarra a janela a identidade do mod.
        barra      = P,
        barraSobre = { r = P.r * 1.35, g = P.g * 1.35, b = P.b * 1.25, a = 1 },
        barraTexto = { r = 1, g = 1, b = 1, a = 1 },

        -- Painel da direita um tom acima do fundo: separa sem linha divisoria.
        conteudo      = claro(P, 0.86),
        conteudoTexto = escuro(P, 0.62),
        conteudoFraco = escuro(P, 0.28),
        conteudoAviso = { r = 0.72, g = 0.26, b = 0.10, a = 1 },

        cartao      = claro(P, 0.93),
        cartaoSobre = claro(P, 0.82),
        cartaoAtivo = claro(P, 0.66),

        botao      = claro(P, 0.68),
        botaoSobre = claro(P, 0.80),
        texto      = escuro(P, 0.62),
        textoFraco = escuro(P, 0.24),

        --[[
            Botao indisponivel: chapado, alpha 1. A versao com transparencia
            deixava o fundo atravessar e ele ficava encardido em vez de
            desligado. A borda tambem recua -- borda forte le como clicavel, e o
            olho ia justamente para o unico botao que nao faz nada.
        ]]
        botaoOff = claro(C.pillDisabled, 0.55),
        bordaOff = claro(B, 0.45),
        textoOff = claro(escuro(P, 0.62), 0.42),
    }
    return ESTILO_CACHE
end



--[[
    As caixas de marcar, no estilo The Sims 2.

    O ISTickBox do jogo desenha um quadradinho com borda e, quando marcado, uma
    textura de tique na cor "good highlight" -- o verde do PZ, que nao acompanha
    a cor do mod e destoa da roda inteira.

    Trocamos o `render` da INSTANCIA e desenhamos bolinhas. Tudo o mais continua
    do ISTickBox: clique, foco de joystick, opcoes desabilitadas. Reimplementar
    isso do zero seria refazer 324 linhas para mudar um desenho.

    A geometria abaixo e copia fiel da do vanilla -- `UI_BORDER_SPACING` = 10,
    a centralizacao vertical, o `itemHgt`. Isso NAO e detalhe: o onMouseUp do
    ISTickBox usa a mesma conta para descobrir em qual linha voce clicou. Se o
    desenho e o clique discordarem, marca-se a opcao errada.
]]
local TICK_ESPACO = 10   -- o UI_BORDER_SPACING do ISTickBox.lua

local function desenharCaixas(tb)
    local D = TheZims.Draw
    if not D or not D.radio then return end
    local S = estilo()

    local total = #tb.options * (tb.itemHgt + TICK_ESPACO) - TICK_ESPACO
    local y = (tb.height - total) / 2
    local textDY = (tb.itemHgt - tb.fontHgt) / 2
    local r = tb.boxSize / 2

    for i, nome in ipairs(tb.options) do
        local desabilitada = tb.disabledOptions and tb.disabledOptions[nome] and true or false
        local sobre = tb:isMouseOver() and tb.mouseOverOption == i and tb.enable and not desabilitada
        local marcada = tb.selected[i] == true

        local cx = tb.leftMargin + r
        local cy = y + tb.itemHgt / 2

        -- Aro escuro, miolo no tom do painel: e a bolinha do The Sims 2, que
        -- e delineada por fora e preenchida por dentro.
        local aro   = S.borda
        local marca = S.borda
        local dentro = sobre and S.botaoSobre or S.botao

        if desabilitada then
            aro    = { r = aro.r,    g = aro.g,    b = aro.b,    a = 0.40 }
            marca  = { r = marca.r,  g = marca.g,  b = marca.b,  a = 0.40 }
            dentro = { r = dentro.r, g = dentro.g, b = dentro.b, a = 0.45 }
        end

        D.radio(tb, cx, cy, r, marcada, aro, marca, dentro)

        local tc = desabilitada and S.textoFraco or S.texto
        local a = desabilitada and 0.55 or 1
        tb:drawText(nome, tb.leftMargin + tb.boxSize + tb.textGap, y + textDY,
            tc.r, tc.g, tc.b, a, tb.font)

        y = y + tb.itemHgt + TICK_ESPACO
    end
end

--- Aplica o visual do mod a um ISTickBox ja criado.
local function estilizarCaixas(tb)
    tb.render = desenharCaixas
    return tb
end

--[[
    Botao no estilo The Sims 2: pilula com borda, texto centrado, e um brilho
    de topo que so aparece sob o cursor.

    Mesmo arranjo das abas -- o ISButton continua dono do clique e do estado, e
    so o desenho e nosso. As cores vanilla sao zeradas na criacao, senao o
    retangulo cinza aparece por baixo das quinas.
]]
local function desenharBotao(botao)
    local D = TheZims.Draw
    if not D or not D.pillOutlined then return end
    local S = estilo()

    local ligado = botao.enable ~= false
    local sobre  = ligado and botao:isMouseOver()

    -- Botao claro com borda marinho grossa, como o "Apply Changes" da
    -- referencia. A borda de 2px e o que da o ar de moldado; com 1px ele volta
    -- a parecer um retangulo pintado.
    local fill, borda = nil, S.borda
    local textoClaro = false
    if botao.zimCorFundo then
        -- Os botoes de cor SAO a amostra: o preenchimento e a cor escolhida.
        local c = botao.zimCorFundo
        local k = sobre and 1.12 or 1
        fill = { r = math.min(1, c.r * k), g = math.min(1, c.g * k), b = math.min(1, c.b * k), a = 1 }
    elseif botao.zimToggleOn ~= nil then
        --[[
            O interruptor da DLC fala pelo PREENCHIMENTO: ligado fica no claro
            normal; desligado vira o azul padrao CHEIO com texto branco. Cheio,
            e nao acinzentado, de proposito - desligado e um estado valido que
            o jogador escolheu, nao um botao quebrado.
        ]]
        if botao.zimToggleOn then
            fill = sobre and S.botaoSobre or S.botao
        else
            fill = sobre and S.barraSobre or S.barra
            textoClaro = true
        end
    elseif not ligado then
        fill, borda = S.botaoOff, S.bordaOff
    else
        fill = sobre and S.botaoSobre or S.botao
    end

    -- Sem brilho de topo quando desligado: o brilho e o que da volume, e volume
    -- e exatamente o que um botao morto nao deve ter.
    D.pillOutlined(botao, 0, 0, botao.width, botao.height,
        fill, (sobre and ligado) and S.brilho or nil, borda, 2)

    -- Os dois botoes de cor mostram a cor escolhida no proprio fundo, entao o
    -- rotulo sai preto ou branco conforme a luminancia -- senao ele some quando
    -- o jogador pega um fundo claro.
    local tc = S.texto
    if botao.zimCorFundo then
        local l = botao.zimCorFundo.r * 0.299 + botao.zimCorFundo.g * 0.587 + botao.zimCorFundo.b * 0.114
        local v = (l > 0.6) and 0 or 1
        tc = { r = v, g = v, b = v, a = 1 }
    end

    -- Desligado usa uma cor PROPRIA, nao a normal escurecida. Multiplicar o
    -- marinho por 0.55 so o deixava mais escuro ainda -- lia como enfase, o
    -- oposto do pretendido. O cinza-azulado abaixo recua de verdade.
    if not ligado and not botao.zimCorFundo then tc = S.textoOff end
    if textoClaro then tc = S.barraTexto end

    local rot = D.fitText(UIFont.Small, botao.title or "", botao.width - 14)
    local tw = getTextManager():MeasureStringX(UIFont.Small, rot)
    local fh = getTextManager():getFontHeight(UIFont.Small)

    --[[
        Icone de download no botao de obter a DLC: seta para baixo caindo numa
        bandeja. Desenhado com as primitivas, nao com textura - recolore junto
        com o texto e nao adiciona arquivo nenhum.

        A haste e a bandeja sao retangulos; a ponta e um drawPolygon de tres
        vertices uteis (o quarto repete o terceiro - a API sempre pede quatro).
    ]]
    if botao.zimBaixar then
        local icone = 12
        local cx0 = (botao.width - tw - icone - 6) / 2
        local cy0 = botao.height / 2
        local m = cx0 + icone / 2
        botao:drawRect(m - 1.5, cy0 - 6, 3, 6, 1, tc.r, tc.g, tc.b)
        -- drawPolygon prefere textura real a nil (ver TheZims_Draw).
        local okT, texB = pcall(function() return Texture.getWhite() end)
        botao:drawPolygon(okT and texB or nil,
            m - 4.5, cy0, m + 4.5, cy0, m, cy0 + 4.5, m, cy0 + 4.5,
            tc.r, tc.g, tc.b, 1)
        botao:drawRect(cx0, cy0 + 6, icone, 2, 1, tc.r, tc.g, tc.b)
        botao:drawText(rot, cx0 + icone + 6, (botao.height - fh) / 2,
            tc.r, tc.g, tc.b, 1, UIFont.Small)
        return
    end

    botao:drawText(rot, (botao.width - tw) / 2, (botao.height - fh) / 2,
        tc.r, tc.g, tc.b, 1, UIFont.Small)
end

--- Zera o desenho vanilla de um ISButton e instala o nosso.
local function estilizarBotao(b)
    b.backgroundColor          = { r = 0, g = 0, b = 0, a = 0 }
    b.backgroundColorMouseOver = { r = 0, g = 0, b = 0, a = 0 }
    b.borderColor              = { r = 0, g = 0, b = 0, a = 0 }
    b.textColor                = { r = 0, g = 0, b = 0, a = 0 }
    b.render = function(botao)
        ISButton.render(botao)
        desenharBotao(botao)
    end
    return b
end

--[[
    Mesma ideia do estilizarBotao, para o ISSliderPanel: o widget do PZ continua
    cuidando de arrastar, clicar e limitar o valor, e so o DESENHO e nosso.

    O pegador e centrado em `bar.x + bar.w * fracao`, que e exatamente a conta
    que o onMouseMove do proprio slider faz ao converter cursor em valor. Se ele
    fosse desenhado deslocado - como o vanilla faz, que ancora pela esquerda -
    o pegador iria parar visualmente ao lado do ponto onde o clique cai, e o
    controle pareceria calibrado errado.

    `setDoButtons(false)` ANTES do initialise: e o paginate, chamado la dentro,
    que decide se a barra ocupa a largura toda ou abre espaco para as setinhas.
    Depois disso a geometria ja esta montada e mudar a flag nao a refaz.
]]
local function estilizarSlider(s)
    s.background = false
    s:setDoButtons(false)

    s.render = function(sl)
        local D = TheZims.Draw
        local bar = sl.sliderBarDim
        -- Sem a biblioteca de desenho ou antes do primeiro paginate, devolve o
        -- desenho de fabrica: feio, mas funcional, em vez de barra invisivel.
        if not D or not D.pillOutlined or not bar then return ISSliderPanel.render(sl) end
        local S = estilo()

        local trilhoH = 6
        local ty = (sl.height - trilhoH) / 2

        D.pillOutlined(sl, bar.x, ty, bar.w, trilhoH, S.botaoOff, nil, S.bordaOff, 1)

        local faixa = sl.maxValue - sl.minValue
        local frac = (faixa ~= 0) and ((sl.currentValue - sl.minValue) / faixa) or 0
        frac = math.max(0, math.min(1, frac))

        -- A parte cheia nunca fica mais curta que a propria altura: abaixo
        -- disso a pilula degenera e o zero vira um pontinho solto na esquerda.
        if frac > 0 then
            D.pillOutlined(sl, bar.x, ty, math.max(trilhoH, bar.w * frac), trilhoH,
                S.barra, nil, S.borda, 1)
        end

        local sobre = sl.dragInside or sl:isMouseOver()
        local pw, ph = 12, sl.height - 2
        D.pillOutlined(sl, bar.x + bar.w * frac - pw / 2, 1, pw, ph,
            sobre and S.botaoSobre or S.botao, sobre and S.brilho or nil, S.borda, 2)
    end
    return s
end

--- ISColorPicker:setInitialColor espera algo com getR/getG/getB, no estilo das
--- cores do lado Java. Nossas cores sao tabelas {r,g,b}, entao vira um adaptador.
local function corComGetters(c)
    return {
        getR = function() return c.r end,
        getG = function() return c.g end,
        getB = function() return c.b end,
    }
end

------------------------------------------------------------------
TheZimsOptions = ISCollapsableWindow:derive("TheZimsOptions")
TheZimsOptions.instancia = nil

--[[
    A janela continua sendo uma ISCollapsableWindow -- e dela que vem arrastar,
    fechar e recolher, e reimplementar isso seria trabalho sem ganho.

    O que desligamos e so o DESENHO dela: `drawFrame` apaga a barra de titulo e
    a borda, `background` apaga o corpo. O que sobra e uma janela funcional e
    invisivel, e a moldura estilo The Sims 2 e desenhada por nos no prerender.

    Pintar por cima em vez de desligar nao serviria: a barra de titulo vanilla
    usa uma textura fixa (`titlebarbkg`) que nao acompanha a cor do mod, e ela
    apareceria por baixo nas quinas arredondadas.
]]
function TheZimsOptions:new(x, y, w, h)
    local o = ISCollapsableWindow:new(x, y, w, h)
    setmetatable(o, self); self.__index = self
    o.title = txt("IGUI_TheZims_WindowTitle", "The Zims")
    o.resizable = false
    o.drawFrame = false
    o.background = false
    return o
end

function TheZimsOptions:prerender()
    ISCollapsableWindow.prerender(self)
    local S = estilo()

    local D = TheZims.Draw
    if not D or not D.panel then return end

    -- Moldura, na cor derivada do tema do jogador.
    D.panel(self, 0, 0, self.width, self.height, RAIO_PAINEL,
        S.fundo, S.borda, S.brilho, 2)

    --[[
        Barra de titulo CHEIA, de ponta a ponta, no tom do tema.

        Ela e recortada para nao vazar pelos cantos arredondados do painel: o
        topo tem o mesmo raio da moldura, a base e reta. Sem isso, as quinas do
        retangulo apareceriam para fora da curva.
    ]]
    D.roundRect(self, 2, 2, self.width - 4, BARRA_H, RAIO_PAINEL - 2, S.barra)
    self:drawRect(2, 2 + BARRA_H - RAIO_PAINEL, self.width - 4, RAIO_PAINEL,
        S.barra.a, S.barra.r, S.barra.g, S.barra.b)

    local tit = self.title or ""
    local tw = getTextManager():MeasureStringX(UIFont.Medium, tit)
    local fhT = getTextManager():getFontHeight(UIFont.Medium)
    self:drawText(tit, (self.width - tw) / 2, 2 + (BARRA_H - fhT) / 2,
        S.barraTexto.r, S.barraTexto.g, S.barraTexto.b, 1, UIFont.Medium)

    -- Rotulo da coluna.
    self:drawText(txt("IGUI_TheZims_Menu", "Menu"), PAD + 2, BARRA_H + PAD,
        S.texto.r, S.texto.g, S.texto.b, 1, UIFont.Small)

    --[[
        O painel de conteudo da direita.

        Azul vivo contra o lavanda da moldura: a separacao vem da cor, nao de
        uma linha divisoria, que e o que o desenho pedia. A borda marinho o
        amarra ao resto -- sem ela, ele flutuaria como um adesivo.
    ]]
    local cx = PAD + ABA_W + PAD
    local cy = BARRA_H + PAD
    local cw = self.width - cx - PAD
    local ch = self.height - cy - PAD
    D.roundRect(self, cx - 2, cy - 2, cw + 4, ch + 4, 8, S.borda)
    D.roundRect(self, cx, cy, cw, ch, 6, S.conteudo)
    self.zimConteudo = { x = cx, y = cy, w = cw, h = ch }

    --[[
        Barra de rolagem da coluna, colada a direita dos cartoes.

        So existe quando os cartoes nao cabem: Draw.scrollbar nao desenha nada
        com fracao >= 1, entao com poucos mods a coluna fica limpa e a barra
        aparece sozinha quando a familia crescer.
    ]]
    if D.scrollbar then
        local topo = BARRA_H + PAD + MENU_TOPO
        local alturaUtil = self.height - topo - PAD
        local alturaTotal = #self.abas * (ABA_H + ABA_GAP)
        if alturaTotal > 0 then
            local excesso = alturaTotal - alturaUtil
            local pos = (excesso > 0) and ((self.menuScroll or 0) / excesso) or 0
            D.scrollbar(self, PAD + ABA_W + 2, topo, 8, alturaUtil,
                alturaUtil / alturaTotal, pos,
                S.cartao, S.barra, S.borda)
        end
    end
end

--[[
    Abas na lateral esquerda.

    Verticais, e nao a fileira horizontal do DeathLogMP, porque aqui a lista
    cresce: cada mod irmao que se registrar vira uma aba. Na horizontal elas
    acabariam espremidas ou quebrando linha.

    Botao comum com o campo `internal`, mesmo padrao do DeathLogMP - nao
    ISTabPanel. Cada aba controla a visibilidade dos proprios widgets, o que
    permite uma aba so de texto (a Principal) sem widget nenhum.
]]
--[[
    Cada aba continua sendo um ISButton -- clique, foco e teclado vem de graca --
    com o desenho proprio acrescentado ao `render` da instancia.

    NAO existe gancho `onrender` no ISButton; conferi no ISButton.lua antes,
    depois de ja ter escrito o codigo errado uma vez. O que existe e o proprio
    `render`, que so desenha imagem e texto. Como estes botoes nao tem imagem e
    tem a cor do texto zerada, chamar o original e depois o nosso nao perde nada
    e preserva qualquer comportamento que ele venha a ganhar.

    O fundo e a borda saem no `prerender` do ISButton, por isso as cores sao
    zeradas na criacao em vez de aqui.
]]
local function desenharAba(botao)
    local janela = botao.parent
    local D = TheZims.Draw
    if not D or not D.roundRect then return end

    local S = estilo()
    local ativa = (janela.abaAtual == botao.internal)
    local sobre = botao:isMouseOver()
    local w, h = botao.width, botao.height
    local raio = 8

    -- A sombra e o que diz "isto e clicavel". Sob o cursor ela cresce, o que le
    -- como o cartao levantando da pagina. Cartao em construcao nao levanta: ele
    -- nao e clicavel, e prometer relevo seria mentir.
    D.shadow(botao, 0, 0, w, h, raio, 4,
        (sobre and not botao.zimConstrucao) and 5 or 3)

    local fill = ativa and S.cartaoAtivo or (sobre and S.cartaoSobre or S.cartao)
    D.roundRect(botao, 0, 0, w, h, raio, S.borda)
    D.roundRect(botao, 2, 2, w - 4, h - 4, raio - 2, fill)

    -- Barra da esquerda na aba aberta: diz qual esta selecionada sem depender
    -- de distinguir dois tons de branco.
    if ativa then
        D.roundRect(botao, 2, 2, 5, h - 4, 2, S.barra)
    end

    --[[
        DLC em construcao: o cartao e um AVISO, nao uma porta.

        Azul cheio com texto branco - o mesmo tratamento do botao desligado no
        resto da janela - e sem arte. Nao ha pagina por tras: clicar nao faz
        nada (o botao nasce com setEnable(false)), porque abrir uma pagina vazia
        de algo que ainda nao existe promete conteudo que nao ha.

        Fica na estante de proposito: dizer o que vem faz parte do que a coluna
        serve para contar.
    ]]
    if botao.zimConstrucao then
        D.roundRect(botao, 0, 0, w, h, raio, S.borda)
        D.roundRect(botao, 2, 2, w - 4, h - 4, raio - 2, S.barra)

        local tm3 = getTextManager()
        local bt = S.barraTexto
        local nome = D.fitText(UIFont.Small, botao.title or "", w - 16)
        local nw = tm3:MeasureStringX(UIFont.Small, nome)
        local fh = tm3:getFontHeight(UIFont.Small)
        botao:drawText(nome, (w - nw) / 2, h / 2 - fh - 1, bt.r, bt.g, bt.b, 1, UIFont.Small)

        local sub = txt("IGUI_TheZims_DlcBuilding", "Em construcao")
        local sw = tm3:MeasureStringX(UIFont.Small, sub)
        botao:drawText(sub, (w - sw) / 2, h / 2 + 3, bt.r, bt.g, bt.b, 0.75, UIFont.Small)
        return
    end

    if botao.zimArte then
        --[[
            A arte PREENCHE o cartao, nao e encaixada nele.

            Com aspect-fit, cada arte encaixava conforme a propria proporcao -
            a do Sobre e 2.09:1, a do Zim Pie 1.70:1, e o cartao 2.00:1 - entao
            uma sobrava nas laterais e a outra em cima e embaixo. Lado a lado
            na coluna, os dois cartoes nao batiam.

            Aqui a escala vem do MAIOR fator (cobrir, nao caber) e o excedente
            e cortado pelo stencil. Toda arte enche o cartao igual, qualquer que
            seja a proporcao dela - inclusive as que voce ainda vai desenhar.
        ]]
        local ix, iy = 3, 3
        local iw, ih = w - 6, h - 6
        local aw, ah = iw, ih
        pcall(function()
            local tw2, th2 = botao.zimArte:getWidth(), botao.zimArte:getHeight()
            if tw2 and th2 and tw2 > 0 and th2 > 0 then
                local k = math.max(iw / tw2, ih / th2)
                aw, ah = tw2 * k, th2 * k
            end
        end)
        botao:setStencilRect(ix, iy, iw, ih)
        botao:drawTextureScaled(botao.zimArte,
            ix + (iw - aw) / 2, iy + (ih - ah) / 2, aw, ah, 1, 1, 1, 1)
        botao:clearStencilRect()
        -- Reafirma a barra de ativa POR CIMA da arte, senao ela some.
        if ativa then
            D.roundRect(botao, 2, 2, 5, h - 4, 2, S.barra)
        end
    else
        -- Sem arte: o nome centrado segura o lugar.
        local tc = ativa and S.texto or S.textoFraco
        local rot = D.fitText(UIFont.Small, botao.title or "", w - 16)
        local tw2 = getTextManager():MeasureStringX(UIFont.Small, rot)
        local fh = getTextManager():getFontHeight(UIFont.Small)
        botao:drawText(rot, (w - tw2) / 2, (h - fh) / 2, tc.r, tc.g, tc.b, 1, UIFont.Small)
    end
end

--[[
    `arteId` e opcional e aceita duas formas:

      "ZimPie"                  -> a capa daquela DLC (arteDaExpansao)
      "media/ui/qualquer.png"   -> textura direta, para o cartao do Sobre, que
                                   nao e DLC e nao tem capa propria

    Sem arte o cartao cai no nome centrado; com arte, ele e so a imagem.
]]
function TheZimsOptions:criarAba(id, rotulo, arteId, construcao)
    local n = #self.abas
    local b = ISButton:new(PAD, BARRA_H + PAD + MENU_TOPO + n * (ABA_H + ABA_GAP),
        ABA_W, ABA_H, rotulo, self, TheZimsOptions.aoTrocarAba)
    b.internal = id
    if arteId then
        if string.find(arteId, "/", 1, true) then
            pcall(function() b.zimArte = getTexture(arteId) end)
        elseif TheZims.arteDaExpansao then
            b.zimArte = TheZims.arteDaExpansao(arteId)
        end
    end
    b:initialise(); self:addChild(b)

    -- Apaga o botao vanilla e deixa so o nosso desenho. O texto tambem sai:
    -- desenhamos com a cor do tema e com corte proprio no render.
    b.backgroundColor      = { r = 0, g = 0, b = 0, a = 0 }
    b.backgroundColorMouseOver = { r = 0, g = 0, b = 0, a = 0 }
    b.borderColor          = { r = 0, g = 0, b = 0, a = 0 }
    b.textColor            = { r = 0, g = 0, b = 0, a = 0 }
    b.render = function(botao)
        ISButton.render(botao)
        desenharAba(botao)
    end

    -- Em construcao: cartao morto. Nao clica, nao abre pagina.
    if construcao then
        b.zimConstrucao = true
        b:setEnable(false)
    end

    local aba = { id = id, rotulo = rotulo, botao = b, widgets = {},
                  construcao = construcao and true or false }
    table.insert(self.abas, aba)
    return aba
end

--- Registra um widget como pertencente a uma aba, para sumir junto com ela.
function TheZimsOptions:naAba(aba, w)
    table.insert(aba.widgets, w)
    return w
end

function TheZimsOptions:aoTrocarAba(botao)
    self:mostrarAba(botao.internal)
end

--[[
    Rolagem da coluna de cartoes.

    Os cartoes sao ISButtons com posicao propria, entao rolar e REPOSICIONAR:
    cada roda de mouse desloca todos os botoes e o desenho segue. Nao ha
    stencil aqui; o que sai da area util e escondido de verdade
    (setVisible), senao o cartao vazaria por cima da barra de titulo.

    So age com o cursor sobre a faixa da coluna, para nao roubar a roda do
    mouse de quem esta sobre o conteudo - la ela ja tem dono (combos).
]]
function TheZimsOptions:rolarMenu(delta)
    local alturaUtil = self.height - (BARRA_H + PAD + MENU_TOPO) - PAD
    local alturaTotal = #self.abas * (ABA_H + ABA_GAP)
    local excesso = alturaTotal - alturaUtil
    if excesso <= 0 then return false end

    self.menuScroll = math.max(0, math.min(excesso, (self.menuScroll or 0) + delta * 40))

    local topo = BARRA_H + PAD + MENU_TOPO
    for n, aba in ipairs(self.abas) do
        local y = topo + (n - 1) * (ABA_H + ABA_GAP) - self.menuScroll
        aba.botao:setY(y)
        aba.botao:setVisible(y >= topo - 4 and y + ABA_H <= self.height - PAD + 4)
    end
    return true
end

function TheZimsOptions:onMouseWheel(del)
    local mx = self:getMouseX()
    if mx <= PAD + ABA_W + PAD then
        if self:rolarMenu(del) then return true end
        return true
    end

    --[[
        Sobre o painel de conteudo, a roda rola o texto da pagina Sobre.

        O limite sai do que o render mediu no quadro anterior (`aboutAltura`),
        entao nao ha altura fixa a manter em dois lugares: mudar o texto ou o
        idioma reajusta o limite sozinho.
    ]]
    if self.abaAtual == "principal" and self.aboutArea then
        local maximo = math.max(0, (self.aboutAltura or 0) - self.aboutArea.h)
        if maximo > 0 then
            self.aboutScroll = math.max(0, math.min(maximo, (self.aboutScroll or 0) + del * 32))
            return true
        end
    end

    return ISCollapsableWindow.onMouseWheel and ISCollapsableWindow.onMouseWheel(self, del) or false
end

--[[
    Trocar de aba agora so mexe em VISIBILIDADE. A cor saiu daqui de proposito:
    `desenharAba` le `self.abaAtual` a cada quadro, entao a aba ativa se pinta
    sozinha e ainda reage ao mouse por cima disso.

    Pintar aqui era pior que redundante: `setBackgroundRGBA` reativaria o fundo
    do botao vanilla que zeramos na criacao, e o quadrado voltaria por baixo da
    pilula.
]]
function TheZimsOptions:mostrarAba(id)
    self.abaAtual = id
    -- Voltar ao Sobre depois de ler ate o fim deve recomecar do topo.
    if id == "principal" then self.aboutScroll = 0 end

    --[[
        Aba de mod AUSENTE mostra so o essencial: descricao (desenhada no
        render), aviso e botao de download. Os ajustes ficam escondidos -
        oferecer configuracao de algo que nao esta instalado e promessa vazia,
        e com o modo demonstracao ligado ficaria obvio o porque: os ajustes do
        Zim Pie apareceriam sob um aviso de "nao instalado".

        `zimSempre` marca o que sobrevive (o proprio botao de download).
    ]]
    local ausente = false
    for _, d in ipairs(TheZims.FAMILIA) do
        if (d.id == id or d.aba == id) and self.familia and self.familia[d.id]
           and self.familia[d.id].estado == "ausente" then ausente = true end
    end

    for _, aba in ipairs(self.abas) do
        local visivel = (aba.id == id)
        for _, w in ipairs(aba.widgets) do
            local v = visivel and (not ausente or w.zimSempre == true)
            pcall(function() w:setVisible(v) end)
        end
    end
end

function TheZimsOptions:createChildren()
    ISCollapsableWindow.createChildren(self)
    local th = self:titleBarHeight()
    local P = TheZims.PREF
    self.abas = {}

    --[[
        O conteudo nasce DENTRO do painel azul da direita, com folga propria:
        encostar na quina arredondada dele fica apertado.

        O +44 no y desce abaixo do titulo da secao que o render desenha no topo
        do painel. Render e createChildren precisam concordar nesse numero,
        senao a primeira caixa de marcar senta em cima do texto.
    ]]
    local x0 = PAD + ABA_W + PAD + CONT_PAD
    -- Sem a previa a coluna pode alargar, mas com teto: combo de 700px vira fita.
    local colW = math.min(self.width - (PAD + ABA_W + PAD) - CONT_PAD * 2 - PAD, 520)
    local y = BARRA_H + PAD + CONT_TOPO

    -- Aba 1: so a arte, como as outras. Sem widget nenhum; o conteudo e
    -- desenhado no render.
    self:criarAba("principal", txt("IGUI_TheZims_TabMain", "Sobre"),
        "media/ui/TheZims_Hero.png")

    --[[
        O Zim Pie ocupa DUAS abas, nao uma.

        Numa coluna so eram catorze controles seguidos, e achar "Aplicar em"
        no meio deles exigia ler a lista inteira. A divisao segue a pergunta
        que o jogador faz: "como ela se parece" contra "quando ela age".

        As caixas de marcar tiveram de virar DOIS ISTickBox. Um widget so nao
        pode aparecer em duas abas - a visibilidade e por widget inteiro, nao
        por linha - entao cada aba tem o seu, com o proprio manipulador. Os
        indices de cada um sao independentes; nao ha mais uma numeracao de 1 a
        8 valendo para tudo.
    ]]
    --[[
        UMA aba por MOD, nao por categoria de ajuste.

        Antes a coluna listava "Aparencia" e "Comportamento" no mesmo nivel dos
        mods, e a lista de mods ficava no painel da direita -- invertido. Quem
        abria a janela via categorias de ajuste soltas, sem saber de que mod
        eram, e precisava caÃ§ar as expansoes num canto.

        Agora a coluna e a estante: Sobre + um cartao por expansao. Aparencia e
        Comportamento sao ajustes DO ZIM PIE, entao vivem dentro dele -- e a
        janela passa a responder "de que mod e isto?" antes de mostrar
        qualquer ajuste.
    ]]
    local abaVisual = self:criarAba("ZimPie", "Zim Pie", "ZimPie")
    local abaComp   = abaVisual

    -- ================================================== ABA: APARENCIA
    local yV = y

    --[[
        A lista de caixas ENCOLHEU de proposito, e cada ausencia tem motivo:

        - "Inverter o lado do olhar" saiu: ajuste fino demais para expor; o
          padrao serve. A preferencia continua existindo no .ini para quem ja
          tinha mudado.
        - "Usar o menu circular" saiu: virou o interruptor grande no topo da
          pagina - dois controles para a mesma coisa so geram duvida sobre qual
          vale.
        - "Modo de teste" saiu da tela: e ferramenta nossa de desenvolvimento,
          continua funcionando por codigo, mas jogador nao precisa ver.
    ]]
    self.caixasVisual = ISTickBox:new(x0, yV, colW, BOX, "", self, TheZimsOptions.aoMarcarVisual)
    self.caixasVisual:initialise()
    self.caixasVisual:addOption(txt("IGUI_TheZims_OptHead",   "Mostrar a cabeca no centro"))
    self.caixasVisual:addOption(txt("IGUI_TheZims_OptLook",   "Cabeca acompanha o mouse"))
    self.caixasVisual:addOption(txt("IGUI_TheZims_OptWedge",  "Marcar a direcao ativa"))
    self.caixasVisual:addOption(txt("IGUI_TheZims_OptAnim",   "Animacao de abertura"))
    self.caixasVisual:setSelected(1, P.mostrarCabeca ~= false)
    self.caixasVisual:setSelected(2, P.olharMouse    ~= false)
    self.caixasVisual:setSelected(3, P.fatiaDeDirecao == true)
    self.caixasVisual:setSelected(4, P.animacao      ~= false)
    estilizarCaixas(self.caixasVisual)
    self:addChild(self.caixasVisual); self:naAba(abaVisual, self.caixasVisual)
    yV = yV + (self.caixasVisual:getHeight() or BOX * 4) + PAD + 8

    --[[
        Cores: tres botoes lado a lado.

        Os dois primeiros SAO a amostra da cor que abrem - o preenchimento deles
        e a propria escolha, via `zimCorFundo` (ver desenharBotao). O terceiro
        NAO recebe esse campo de proposito: ele nao representa cor nenhuma, e
        pintar ele de azul o faria parecer uma terceira cor escolhivel.
    ]]
    -- Rotulo com linha propria e folga dos dois lados: colado nas caixas acima
    -- ele lia como legenda da ultima caixa, nao como titulo do grupo de cores.
    local SL = estilo()
    self.rotCores = ISLabel:new(x0, yV, BTN_H,
        txt("IGUI_TheZims_Colors", "Cores:"), SL.texto.r, SL.texto.g, SL.texto.b, 1, UIFont.Small, true)
    self.rotCores:initialise(); self:addChild(self.rotCores); self:naAba(abaVisual, self.rotCores)
    yV = yV + 26
    local terW = (colW - PAD * 2) / 3
    self.btnFundo = ISButton:new(x0, yV, terW, BTN_H,
        txt("IGUI_TheZims_ColorBg", "Fundo"), self, TheZimsOptions.aoAbrirCorFundo)
    estilizarBotao(self.btnFundo):initialise(); self:addChild(self.btnFundo); self:naAba(abaVisual, self.btnFundo)

    self.btnTexto = ISButton:new(x0 + terW + PAD, yV, terW, BTN_H,
        txt("IGUI_TheZims_ColorText", "Texto"), self, TheZimsOptions.aoAbrirCorTexto)
    estilizarBotao(self.btnTexto):initialise(); self:addChild(self.btnTexto); self:naAba(abaVisual, self.btnTexto)

    self.btnCorPadrao = ISButton:new(x0 + (terW + PAD) * 2, yV, terW, BTN_H,
        txt("IGUI_TheZims_ColorReset", "Padrao"), self, TheZimsOptions.aoRestaurarCores)
    estilizarBotao(self.btnCorPadrao):initialise(); self:addChild(self.btnCorPadrao)
    self:naAba(abaVisual, self.btnCorPadrao)
    yV = yV + BTN_H + PAD

    --[[
        O combo de Arranjo saiu: a roda ja vira colunas SOZINHA quando a pagina
        tem 8 opcoes - e a unica situacao em que colunas resolvem algo. Manter o
        seletor era oferecer uma escolha que o mod ja faz melhor no automatico.
        `arranjo` forcado em "roda" na carga (ver carregarPrefs).
    ]]
    self.comboTam = self:linhaCombo(txt("IGUI_TheZims_Size", "Tamanho da roda:"), x0, yV, colW,
        TheZimsOptions.aoTrocarTamanho, {
            { txt("IGUI_TheZims_SizeS", "Compacto"), "compacto" },
            { txt("IGUI_TheZims_SizeM", "Normal"),   "normal" },
            { txt("IGUI_TheZims_SizeL", "Grande"),   "grande" },
        }, (P.tamanho == "compacto" and 1) or (P.tamanho == "grande" and 3) or 2, abaVisual)
    yV = yV + ROW

    -- ============================================= ABA: COMPORTAMENTO
    --[[
        Continua de onde a aparencia parou, nao volta ao topo.

        Enquanto eram duas abas, cada grupo comecava no mesmo `y` -- so um
        aparecia por vez, entao nao havia conflito. Agora que dividem a aba do
        Zim Pie, reiniciar o y empilharia os dois no mesmo lugar.
    ]]
    local yC = yV + PAD + 6

    --[[
        Sobrou UMA caixa de comportamento: o som ao passar o mouse.

        "Aplicar em" e "Som do clique" sairam da tela a pedido - os padroes
        (so o mundo, som do mod) servem, e as preferencias continuam vivas no
        .ini para quem ja tinha mudado. O "Restaurar padroes" mudou de casa:
        vive na coluna do interruptor, ao lado da arte.
    ]]
    self.caixasComp = ISTickBox:new(x0, yC, colW, BOX, "", self, TheZimsOptions.aoMarcarComp)
    self.caixasComp:initialise()
    self.caixasComp:addOption(txt("IGUI_TheZims_OptSound", "Som ao passar o mouse"))
    self.caixasComp:setSelected(1, P.som ~= false)
    estilizarCaixas(self.caixasComp)
    self:addChild(self.caixasComp); self:naAba(abaComp, self.caixasComp)
    yC = yC + (self.caixasComp:getHeight() or BOX) + PAD


    --[[
        Restaurar padroes: na coluna a direita da arte, abaixo do interruptor
        (que fica em BARRA_H+PAD+12 com o rotulo em cima; ver o laco dos
        interruptores). Os dois formam o bloco de "controles do mod" -- ligar,
        desligar, zerar -- separado dos ajustes finos la embaixo.
    ]]
    local ctlX = PAD + ABA_W + PAD + CONT_PAD + 340 + CONT_PAD
    self.btnPadrao = ISButton:new(ctlX, BARRA_H + PAD + 12 + 20 + 30 + 10, 170, BTN_H,
        txt("IGUI_TheZims_Reset", "Restaurar padroes"), self, TheZimsOptions.aoRestaurar)
    estilizarBotao(self.btnPadrao):initialise(); self:addChild(self.btnPadrao); self:naAba(abaComp, self.btnPadrao)

    local maiorY = math.max(yV, yC)

    --[[
        Cada mod irmao registrado vira UMA ABA propria, nao mais um trecho
        empilhado no fim desta coluna.

        A API `registrarSecao` continua identica - quem ja usa nao precisa mudar
        nada. Para saber quais widgets sao de qual aba sem exigir isso do irmao,
        o addChild e envolvido durante a construcao dele e devolvido em seguida.
        Atribuir em `self` sombreia o metodo da metatabela; apagar o campo
        devolve o original.
    ]]
    for _, s in ipairs(TheZims.secoesExtras) do
        --[[
            A marca de construcao vale mesmo para irmao que REGISTROU secao.

            Sem isto o Zim Actions escapava: ele se registra por conta propria e
            a aba dele nascia aqui, sem passar pelo laco da FAMILIA que aplica
            a marca. O cartao continuava clicavel e abria os ajustes de um mod
            que decidimos nao expor ainda.
        ]]
        local emObra = false
        for _, d in ipairs(TheZims.FAMILIA) do
            if (d.aba == s.nome or d.id == s.nome) and d.construcao then emObra = true end
        end

        local aba = self:criarAba(s.nome, s.nome, s.nome:gsub("%s+", ""), emObra)
        local capturados = {}
        local addOriginal = self.addChild
        self.addChild = function(janela, filho)
            table.insert(capturados, filho)
            return addOriginal(janela, filho)
        end
        local ok, novoY = pcall(s.construir, self, x0, y, colW)
        self.addChild = nil   -- volta ao metodo da metatabela
        for _, w in ipairs(capturados) do self:naAba(aba, w) end
        if ok and type(novoY) == "number" then
            maiorY = math.max(maiorY, novoY)
        elseif not ok then
            print("[TheZims] secao '" .. tostring(s.nome) .. "' falhou: " .. tostring(novoY))
        end
    end

    --[[
        Expansoes SEM secao registrada tambem ganham cartao.

        Sao as que ainda nao existem (Zim Panel) ou que nao tem ajuste nenhum
        (Zim Balloons). Sem isto elas sumiam da coluna, e a estante deixava de
        contar o que vem por ai -- que era metade do motivo de existir.

        A aba nasce vazia de widgets; o painel da direita e que mostra a
        descricao e o botao de obter na Steam.
    ]]
    for _, def in ipairs(TheZims.FAMILIA) do
        local jaTem = false
        for _, aba in ipairs(self.abas) do
            if aba.id == def.id or aba.id == def.aba then jaTem = true end
        end
        if not jaTem then
            self:criarAba(def.id, TheZims.NOME_PADRAO[def.id] or def.id, def.id, def.construcao)
        end
    end

    --[[
        O interruptor de cada DLC, ao lado da arte no cabecalho.

        E um ISButton preso a aba do mod, entao aparece e some com ela. O
        rotulo e decidido POR QUADRO no render - "Ativado"/"Desativado" conforme
        o gancho em TheZims.DLC_CHAVE - porque o estado muda por fora tambem
        (a tecla de atalho da roda alterna o mesmo `ligado`).

        DLC sem gancho ganha o botao desabilitado: melhor um botao morto
        explicando-se do que um espaco vazio onde os outros mods tem controle.
    ]]
    -- O estado da familia e lido aqui (uma vez) porque o interruptor decide a
    -- propria cara por ele: ligar/desligar para mod presente, baixar para
    -- ausente.
    self.familia = self.familia or TheZims.estadoDaFamilia()

    for _, def in ipairs(TheZims.FAMILIA) do
        local abaDoMod = nil
        for _, aba in ipairs(self.abas) do
            if aba.id == def.id or aba.id == def.aba then abaDoMod = aba end
        end
        if abaDoMod and not def.construcao then
            local m = self.familia[def.id]
            local ausente = m and m.estado == "ausente"
            -- +20 abre espaco para o rotulo "Ativar ou desativar o mod" que o
            -- render desenha logo acima do botao.
            local tgX = PAD + ABA_W + PAD + CONT_PAD + 340 + CONT_PAD
            local tg = ISButton:new(tgX, BARRA_H + PAD + 12 + 20, 170, 30,
                "", self, TheZimsOptions.aoAlternarDlc)
            tg.internal = def.id
            -- Mod ausente: o mesmo botao vira o DOWNLOAD. Guardar o id aqui
            -- decide o clique (abrir a Steam) e o rotulo.
            if ausente then tg.zimBaixar = m and m.workshop end
            -- Sobrevive ao modo "mod ausente" do mostrarAba: o aviso e o botao
            -- de baixar sao exatamente o que a aba precisa mostrar.
            tg.zimSempre = true
            estilizarBotao(tg)
            tg.render = function(b)
                local g = TheZims.DLC_CHAVE and TheZims.DLC_CHAVE[b.internal]
                if b.zimBaixar then
                    b.title = txt("IGUI_TheZims_DlcGet", "Obter na Steam")
                    b.zimToggleOn = nil
                elseif b.zimConstrucao then
                    -- DLC que ainda estamos escrevendo: dito com todas as
                    -- letras, em vez do "Em breve" generico que tanto serve
                    -- para o que esta pronto e nao publicado quanto para o que
                    -- ainda nem comecou.
                    b.title = txt("IGUI_TheZims_DlcBuilding", "Em construcao")
                    b.zimToggleOn = nil
                elseif b.zimAusente then
                    b.title = txt("IGUI_TheZims_DlcSoon", "Em breve")
                    b.zimToggleOn = nil
                elseif g and g.ler then
                    local lig = false
                    pcall(function() lig = g.ler() end)
                    b.title = lig and txt("IGUI_TheZims_DlcOn", "Ativado")
                                   or txt("IGUI_TheZims_DlcOff", "Desativado")
                    -- O desenho le isto para trocar a cor: claro quando ligado,
                    -- o azul padrao cheio quando desligado.
                    b.zimToggleOn = lig
                else
                    b.title = txt("IGUI_TheZims_DlcSoon", "Em breve")
                    b.zimToggleOn = nil
                end
                ISButton.render(b)
                desenharBotao(b)
            end
            tg:initialise()
            if def.construcao then
                -- Em construcao manda sobre tudo: mesmo que a DLC ja esteja
                -- instalada aqui no nosso ambiente, quem joga ve "em
                -- construcao" e o botao morto.
                tg.zimConstrucao = true
                tg.zimBaixar = nil
                tg:setEnable(false)
            elseif ausente then
                tg.zimAusente = true
                -- Sem pagina para abrir (DLC nao publicada), o botao e so aviso.
                if not tg.zimBaixar then tg:setEnable(false) end
            elseif not (TheZims.DLC_CHAVE and TheZims.DLC_CHAVE[def.id]) then
                tg:setEnable(false)
            end
            self:addChild(tg); self:naAba(abaDoMod, tg)
        end
    end

    --[[
        Os botoes da prateleira da Principal foram REMOVIDOS.

        A coluna da esquerda ja e a estante: um cartao por DLC, com a arte de
        cada uma, e clicar leva para a pagina dela - onde estao o estado, o
        interruptor e o botao de obter na Steam. Repetir capas e botoes no meio
        da Principal era a mesma lista duas vezes, com dois lugares para o
        mesmo estado divergir.
    ]]

    -- A janela tem que caber a aba mais alta E a faixa de cartoes.
    local alturaAbas = BARRA_H + PAD + MENU_TOPO + #self.abas * (ABA_H + ABA_GAP)
    self:setHeight(math.max(maiorY, alturaAbas, BARRA_H + 260) + PAD)

    self:atualizarBotoesDeCor()
    self:mostrarAba("principal")
end



--[[
    O interruptor do cabecalho. Dois papeis no mesmo botao:

    - mod PRESENTE: delega ao gancho da DLC, que sabe onde o "ligado" mora.
    - mod AUSENTE com pagina publicada: abre o overlay da Steam DIRETO no item,
      onde o jogador assina. E o metodo do proprio jogo (MissedModsPanel usa
      exatamente isso para mods faltantes de servidor); nao existe assinatura
      direta por Lua - SubscribeItem vive no Java e nao e exposto. Depois de
      assinar, o mod so carrega ao reiniciar e marcar na lista - dai o aviso
      no rotulo acima do botao.
]]
function TheZimsOptions:aoAlternarDlc(botao)
    if botao.zimBaixar then
        --[[
            O overlay E dentro do jogo: a mesma camada do Shift+Tab, desenhada
            por cima da tela, com o jogo rodando atras. O jogador assina ali e
            a Steam baixa em segundo plano, sem sair do PZ.

            O `else` cobre quem DESLIGOU o overlay nas opcoes da Steam - ai
            nao ha camada para abrir e o navegador externo e o unico caminho.
            E o mesmo par que o proprio jogo usa (MainScreen:onClickReportBug).
        ]]
        pcall(function()
            if isSteamOverlayEnabled() then
                activateSteamOverlayToWorkshopItem(botao.zimBaixar)
            else
                openUrl("https://steamcommunity.com/sharedfiles/filedetails/?id=" .. botao.zimBaixar)
            end
        end)
        return
    end
    local g = TheZims.DLC_CHAVE and TheZims.DLC_CHAVE[botao.internal]
    if g and g.alternar then pcall(g.alternar) end
end

--- Rotulo + combo numa linha. Devolve o combo. `aba` e opcional: quando vem,
--- rotulo e combo somem junto com ela.
function TheZimsOptions:linhaCombo(rotulo, x, y, largura, aoMudar, opcoes, selecionado, aba)
    local S = estilo()
    local lbl = ISLabel:new(x, y + 4, COMBO_H, rotulo, S.texto.r, S.texto.g, S.texto.b, 1, UIFont.Small, true)
    lbl:initialise(); self:addChild(lbl)

    local combo = ISComboBox:new(x + LABEL_W, y, largura - LABEL_W, COMBO_H, self, aoMudar)
    combo:initialise()
    for _, o in ipairs(opcoes) do combo:addOptionWithData(o[1], o[2]) end
    combo.selected = selecionado
    self:addChild(combo)

    if aba then self:naAba(aba, lbl); self:naAba(aba, combo) end
    return combo
end

--- Cada botao mostra a propria cor no fundo, com o rotulo em preto ou branco
--- conforme a luminancia: branco sobre fundo claro sumiria.
function TheZimsOptions:atualizarBotoesDeCor()
    local P = TheZims.PREF
    -- Guardado para desenharBotao decidir preto ou branco no rotulo.
    self.btnFundo.zimCorFundo = P.corFundo
    self.btnTexto.zimCorFundo = P.corTexto
    self.btnFundo.backgroundColor = { r = P.corFundo.r, g = P.corFundo.g, b = P.corFundo.b, a = 1 }
    self.btnTexto.backgroundColor = { r = P.corTexto.r, g = P.corTexto.g, b = P.corTexto.b, a = 1 }
    local lum = P.corFundo.r * 0.299 + P.corFundo.g * 0.587 + P.corFundo.b * 0.114
    local c = (lum > 0.6) and 0 or 1
    self.btnFundo.textColor = { r = c, g = c, b = c, a = 1 }
    local lum2 = P.corTexto.r * 0.299 + P.corTexto.g * 0.587 + P.corTexto.b * 0.114
    local c2 = (lum2 > 0.6) and 0 or 1
    self.btnTexto.textColor = { r = c2, g = c2, b = c2, a = 1 }
end

local function abrirSeletor(janela, corAtual, callback)
    local picker = ISColorPicker:new(0, 0)
    picker:initialise()
    picker.pickedTarget = janela
    picker:setPickedFunc(callback)
    pcall(function() picker:setInitialColor(corComGetters(corAtual)) end)
    picker:setX(janela:getAbsoluteX() + PAD)
    picker:setY(janela:getAbsoluteY() + janela:titleBarHeight() + 60)
    picker:addToUIManager()
    picker:bringToTop()
    return picker
end

function TheZimsOptions:aoAbrirCorFundo()
    abrirSeletor(self, TheZims.PREF.corFundo, TheZimsOptions.aoEscolherFundo)
end

function TheZimsOptions:aoAbrirCorTexto()
    abrirSeletor(self, TheZims.PREF.corTexto, TheZimsOptions.aoEscolherTexto)
end

function TheZimsOptions:aoEscolherFundo(cor)
    if not cor then return end
    TheZims.PREF.corFundo = { r = cor.r, g = cor.g, b = cor.b }
    self:salvarEAplicar()
end

function TheZimsOptions:aoEscolherTexto(cor)
    if not cor then return end
    TheZims.PREF.corTexto = { r = cor.r, g = cor.g, b = cor.b }
    self:salvarEAplicar()
end

--[[
    Volta SO as duas cores ao padrao.

    Separado do "Restaurar padroes" da aba Comportamento de proposito: ate agora
    aquele era a unica saida para quem tinha escolhido uma cor e queria o azul de
    volta, e ele leva junto tamanho, arranjo, sons, zoom do rosto e todo o resto.
    Perder oito ajustes para desfazer um e o tipo de coisa que faz o jogador nao
    experimentar cor nenhuma.

    Copia campo a campo em vez de apontar para COR_FUNDO_PADRAO: `textoParaCor`
    devolve a propria tabela padrao quando a linha do .ini nao parseia, e PREF
    guardando uma referencia a ela significaria que a proxima escolha no seletor
    reescreveria a constante.
]]
function TheZimsOptions:aoRestaurarCores()
    local F, T = TheZims.COR_FUNDO_PADRAO, TheZims.COR_TEXTO_PADRAO
    TheZims.PREF.corFundo = { r = F.r, g = F.g, b = F.b }
    TheZims.PREF.corTexto = { r = T.r, g = T.g, b = T.b }
    -- salvarEAplicar ja repinta os dois botoes-amostra e invalida o tema, entao
    -- a roda da previa ao lado troca de cor no mesmo quadro.
    self:salvarEAplicar()
end

function TheZimsOptions:salvarEAplicar()
    TheZims.aplicarPrefs()
    TheZims.salvarPrefs()
    self:atualizarBotoesDeCor()
end

--- Os indices tem que casar com a ORDEM dos addOption; ao tirar uma caixa da
--- tela, o mapa aqui muda junto ou toda caixa abaixo dela grava na
--- preferencia errada.
function TheZimsOptions:aoMarcarVisual(indice, marcado)
    local P = TheZims.PREF
    if indice == 1 then P.mostrarCabeca = marcado
    elseif indice == 2 then P.olharMouse = marcado
    elseif indice == 3 then P.fatiaDeDirecao = marcado
    elseif indice == 4 then P.animacao = marcado end
    self:salvarEAplicar()
end

--- Sobrou uma caixa de comportamento: o som de hover.
function TheZimsOptions:aoMarcarComp(indice, marcado)
    if indice == 1 then TheZims.PREF.som = marcado end
    self:salvarEAplicar()
end

function TheZimsOptions:aoTrocarSomClique(combo)
    TheZims.PREF.somClique = combo:getOptionData(combo.selected) or "mod"
    self:salvarEAplicar()
    -- Toca na hora, para a escolha ser audivel sem ter que fechar a janela e ir
    -- abrir um menu no mundo so para saber como o clique ficou.
    TheZims.tocarSomUI(TheZims.somDeClique())
end

function TheZimsOptions:aoTrocarArranjo(combo)
    TheZims.PREF.arranjo = combo:getOptionData(combo.selected) or "roda"
    self:salvarEAplicar()
end

function TheZimsOptions:aoTrocarTamanho(combo)
    TheZims.PREF.tamanho = combo:getOptionData(combo.selected) or "normal"
    self:salvarEAplicar()
end

function TheZimsOptions:aoTrocarOnde(combo)
    TheZims.PREF.ondeAplicar = combo:getOptionData(combo.selected) or "world"
    self:salvarEAplicar()
end

function TheZimsOptions:aoRestaurar()
    local P = TheZims.PREF
    P.ligado, P.tamanho, P.mostrarCabeca = true, "normal", true
    P.som, P.somClique = true, "mod"
    P.fatiaDeDirecao, P.animacao, P.ondeAplicar = false, true, "world"
    -- 20 / altura 0 e o par medido em jogo (yOffset efetivo -0.90).
    P.zoomRosto, P.alturaRosto = 20, 0
    P.olharMouse, P.espelharOlhar, P.arranjo = true, false, "roda"
    P.menuDeTeste = false
    P.corFundo = { r = TheZims.COR_FUNDO_PADRAO.r, g = TheZims.COR_FUNDO_PADRAO.g, b = TheZims.COR_FUNDO_PADRAO.b }
    P.corTexto = { r = TheZims.COR_TEXTO_PADRAO.r, g = TheZims.COR_TEXTO_PADRAO.g, b = TheZims.COR_TEXTO_PADRAO.b }
    self:salvarEAplicar()

    --[[
        So os widgets que EXISTEM. comboClique/comboArranjo/comboOnde sairam da
        tela; indexa-los aqui seria nil e o Restaurar estouraria - exatamente o
        tipo de resto que a remocao de um widget costuma deixar para tras.
    ]]
    -- Aparencia: cabeca, olhar, fatia, animacao
    self.caixasVisual:setSelected(1, true); self.caixasVisual:setSelected(2, true)
    self.caixasVisual:setSelected(3, false); self.caixasVisual:setSelected(4, true)
    -- Comportamento: som de hover
    self.caixasComp:setSelected(1, true)
    self.comboTam.selected = 2
end

--[[
    Aba Principal: um resumo do que o mod faz e do estado de cada coisa.

    Desenhada como texto no render, sem widget nenhum. E so leitura - criar
    ISLabel para cada linha so daria trabalho de mostrar e esconder.
]]
function TheZimsOptions:renderPrincipal()
    local S = estilo()
    local D = TheZims.Draw
    --[[
        As coordenadas saem de BARRA_H + PAD + CONT_PAD, como todo o resto.

        Antes usavam `self:titleBarHeight()`, herdado de quando a janela tinha
        a barra vanilla -- por isso o titulo encostava na borda do painel e os
        botoes das capas nao batiam com as capas desenhadas: render e
        createChildren partiam de origens diferentes.
    ]]
    local x = PAD + ABA_W + PAD + CONT_PAD
    local y = BARRA_H + PAD + CONT_PAD
    local largura = self.width - x - PAD - CONT_PAD

    --[[
        A pagina Sobre e A ARTE, e mais nada.

        A prateleira de capas saiu daqui: a coluna da esquerda JA e a estante -
        um cartao por DLC, cada um com a propria arte. Repetir as mesmas quatro
        capas no meio da pagina era mostrar duas vezes a mesma lista, e ainda
        obrigava a duplicar estado, nome e botao em dois lugares que podiam
        divergir.

        Sem a estante embaixo, a arte volta a usar a LARGURA CHEIA do painel. A
        altura sai da proporcao real da imagem, lida na hora: trocar o recorte
        da arte reajusta o quadro sozinho, sem tarja e sem eu recalibrar nada.
    ]]
    local heroi = nil
    pcall(function() heroi = getTexture("media/ui/TheZims_Hero.png") end)

    if heroi then
        local HERO_H = math.floor(largura / 2.09)
        pcall(function()
            local iw, ih = heroi:getWidth(), heroi:getHeight()
            if iw and ih and iw > 0 then HERO_H = math.floor(largura * ih / iw) end
        end)

        --[[
            A arte cede espaco ao TEXTO, nao o contrario.

            Antes ela usava toda a altura disponivel e a pagina virava so uma
            imagem - quem abria o mod pela primeira vez nao lia em lugar nenhum
            o que ele faz. Aqui a arte fica com no maximo 45% do painel e o
            resto e explicacao.
        ]]
        local teto = math.floor((self.height - y - PAD - CONT_PAD) * 0.45)
        local w2 = largura
        if HERO_H > teto then
            w2 = math.floor(largura * teto / HERO_H)
            HERO_H = teto
        end
        local x2 = x + math.floor((largura - w2) / 2)

        if D and D.roundRect then
            D.roundRect(self, x2 - 2, y - 2, w2 + 4, HERO_H + 4, 8, S.borda)
        end
        self:drawRect(x2, y, w2, HERO_H, 1, 0.05, 0.06, 0.08)
        self:drawTextureScaledAspect(heroi, x2, y, w2, HERO_H, 1, 1, 1, 1)
        y = y + HERO_H + 16
    end

    --[[
        O texto de apresentacao.

        Sintaxe da traducao, para caber tudo numa chave so por idioma:
          "|"  separa paragrafos
          "#"  no inicio de um paragrafo faz dele um TITULO de secao

        Uma chave por idioma e muito mais facil de manter que dez, e nenhum dos
        dois marcadores aparece na tela.

        A rolagem e feita movendo o Y de desenho (`aboutScroll`) e cortando com
        stencil na area util - o texto e desenhado, nao sao widgets, entao nao
        ha o que mover de verdade.
    ]]
    local corpo = txt("IGUI_TheZims_AboutBody", "The Zims e a base.")

    local tm4 = getTextManager()
    local fhP = tm4:getFontHeight(UIFont.Medium)
    local fh  = tm4:getFontHeight(UIFont.Small)

    local areaY = y
    local areaH = self.height - areaY - PAD - CONT_PAD
    if areaH < 40 then areaH = 40 end

    self:setStencilRect(x, areaY, largura, areaH)
    local dy = areaY - (self.aboutScroll or 0)

    for trecho in string.gmatch(corpo, "[^|]+") do
        local titulo = string.sub(trecho, 1, 1) == "#"
        local texto  = titulo and string.sub(trecho, 2) or trecho
        local fonte  = titulo and UIFont.Medium or UIFont.Small
        local alt    = titulo and fhP or fh
        local cor    = titulo and S.texto or S.textoFraco

        if titulo then dy = dy + 6 end

        local linha = ""
        for palavra in string.gmatch(texto, "%S+") do
            local teste = (linha == "") and palavra or (linha .. " " .. palavra)
            if tm4:MeasureStringX(fonte, teste) > largura then
                self:drawText(linha, x, dy, cor.r, cor.g, cor.b, 1, fonte)
                dy = dy + alt + 3
                linha = palavra
            else
                linha = teste
            end
        end
        if linha ~= "" then
            self:drawText(linha, x, dy, cor.r, cor.g, cor.b, 1, fonte)
            dy = dy + alt + 3
        end
        dy = dy + 8
    end
    self:clearStencilRect()

    -- Altura total, para o limite da rolagem e para a barra saber a proporcao.
    self.aboutAltura = (dy + (self.aboutScroll or 0)) - areaY
    self.aboutArea   = { y = areaY, h = areaH }

    if D and D.scrollbar and self.aboutAltura > areaH then
        D.scrollbar(self, x + largura - 8, areaY, 8, areaH,
            areaH / self.aboutAltura,
            (self.aboutScroll or 0) / math.max(1, self.aboutAltura - areaH),
            S.cartao, S.barra, S.borda)
    end
end

--- Previa desenhada com as mesmas primitivas da roda de verdade, em escala.
function TheZimsOptions:render()
    ISCollapsableWindow.render(self)
    local S = estilo()
    local Draw = TheZims.Draw
    if not Draw then return end

    if self.abaAtual == "principal" then
        self:renderPrincipal()
        return
    end

    --[[
        Cabecalho de apresentacao da aba: o NOME do mod em grande e, logo
        abaixo, o que ele e e o que ele faz. So entao vem os ajustes.

        E o que faz a aba responder "onde estou?" sem depender do cartao da
        coluna - e para as expansoes ainda sem ajuste nenhum (Zim Panel), essa
        apresentacao E o conteudo.

        O filtro antigo era por "aparencia"/"comportamento", abas que deixaram
        de existir quando os ajustes se fundiram na aba do mod - a previa da
        roda tinha morrido junto, em silencio.
    ]]
    local def = nil
    for _, d in ipairs(TheZims.FAMILIA) do
        if d.id == self.abaAtual or d.aba == self.abaAtual then def = d end
    end
    if not def then return end

    local hx = PAD + ABA_W + PAD + CONT_PAD
    local hy = BARRA_H + PAD + 12
    local hw = self.width - hx - PAD - CONT_PAD

    --[[
        A pagina do mod, de cima para baixo:

          [ arte grande, titulo POR CIMA dela ]   [ botao ligar/desligar ]
          o que o mod e e o que ele faz
          ...e so entao os ajustes

        O titulo vai sobreposto no canto superior ESQUERDO da arte, com uma
        sombra dura de 1px por baixo - sem ela o branco some nas areas claras
        da imagem. `drawTextureScaledAspect` porque a arte e 1,7:1 e o Scaled
        puro a esticaria.

        O botao ao lado e um widget de verdade, criado no createChildren e
        preso a aba; aqui so se desenha o que nao e clicavel.
    ]]
    local arte = TheZims.arteDaExpansao and TheZims.arteDaExpansao(def.id)
    local nome = TheZims.NOME_PADRAO[def.id] or def.id
    local IMG_W, IMG_H = 340, 200
    if arte then
        local D2 = TheZims.Draw
        if D2 and D2.roundRect then
            D2.roundRect(self, hx - 2, hy - 2, IMG_W + 4, IMG_H + 4, 6, S.borda)
        end
        self:drawTextureScaledAspect(arte, hx, hy, IMG_W, IMG_H, 1, 1, 1, 1)
        self:drawText(nome, hx + 13, hy + 9, 0, 0, 0, 0.85, UIFont.Medium)
        self:drawText(nome, hx + 12, hy + 8, 1, 1, 1, 1, UIFont.Medium)
        hy = hy + IMG_H + 10
    else
        self:drawText(nome, hx, hy, S.texto.r, S.texto.g, S.texto.b, 1, UIFont.Medium)
        hy = hy + 26
    end

    -- Quebra por palavra na largura do painel; MeasureStringX decide onde.
    local desc = txt("IGUI_TheZims_" .. def.chave, def.id)
    local tm2 = getTextManager()
    local linha = ""
    for palavra in string.gmatch(desc, "%S+") do
        local teste = (linha == "") and palavra or (linha .. " " .. palavra)
        if tm2:MeasureStringX(UIFont.Small, teste) > hw then
            self:drawText(linha, hx, hy, S.textoFraco.r, S.textoFraco.g, S.textoFraco.b, 1, UIFont.Small)
            hy = hy + 17
            linha = palavra
        else
            linha = teste
        end
    end
    if linha ~= "" then
        self:drawText(linha, hx, hy, S.textoFraco.r, S.textoFraco.g, S.textoFraco.b, 1, UIFont.Small)
    end

    --[[
        Rotulo acima do botao. Muda com o estado do mod:
          presente -> "Ativar ou desativar o mod"
          ausente  -> o AVISO, na cor quente: "Este mod nao esta instalado"
    ]]
    local m2 = self.familia and self.familia[def.id]
    local ausente = (m2 and m2.estado == "ausente") or def.construcao
    local lx = PAD + ABA_W + PAD + CONT_PAD + 340 + CONT_PAD

    if def.construcao then
        self:drawText(txt("IGUI_TheZims_DlcBuildingLabel", "Esta DLC ainda esta sendo construida"),
            lx, BARRA_H + PAD + 12,
            S.conteudoAviso.r, S.conteudoAviso.g, S.conteudoAviso.b, 1, UIFont.Small)
        self:drawText(txt("IGUI_TheZims_DlcBuildingHint", "Ela aparece aqui quando estiver pronta"),
            lx, BARRA_H + PAD + 12 + 20 + 30 + 8,
            S.textoFraco.r, S.textoFraco.g, S.textoFraco.b, 1, UIFont.Small)
    elseif ausente then
        self:drawText(txt("IGUI_TheZims_DlcNotInstalled", "Esta DLC ainda nao esta instalada"),
            lx, BARRA_H + PAD + 12,
            S.conteudoAviso.r, S.conteudoAviso.g, S.conteudoAviso.b, 1, UIFont.Small)
        -- A letra miuda do fluxo Steam: assinar nao carrega a DLC na hora.
        self:drawText(txt("IGUI_TheZims_DlcRestart", "Assine na Steam, reinicie o jogo e marque na lista de mods"),
            lx, BARRA_H + PAD + 12 + 20 + 30 + 8,
            S.textoFraco.r, S.textoFraco.g, S.textoFraco.b, 1, UIFont.Small)
    else
        self:drawText(txt("IGUI_TheZims_DlcToggleLabel", "Ativar ou desativar esta DLC"),
            lx, BARRA_H + PAD + 12, S.texto.r, S.texto.g, S.texto.b, 1, UIFont.Small)

        --[[
            A versao instalada, lida do mod.info da propria DLC via
            getModVersion. So aparece instalada e com versao declarada -
            getModVersion devolve string vazia quando a linha falta, e o
            estadoDaFamilia ja normaliza isso para nil.
        ]]
        if m2 and m2.versao then
            local vy = BARRA_H + PAD + 12 + 20 + 30 + 10
            if self.abaAtual == "ZimPie" then vy = vy + BTN_H + 8 end
            self:drawText(txt("IGUI_TheZims_DlcVersion", "Versao instalada") .. ": v" .. tostring(m2.versao),
                lx, vy, S.textoFraco.r, S.textoFraco.g, S.textoFraco.b, 1, UIFont.Small)
        end
    end

    -- Deste ponto para baixo, so a aba do Zim Pie tem ajustes - e nenhum
    -- ajuste aparece para mod ausente.
    if ausente or self.abaAtual ~= "ZimPie" then return end

    --[[
        Titulo da secao de ajustes, entre a descricao e a primeira caixa.

        A PREVIA AO VIVO saiu daqui: nunca coube direito ao lado dos ajustes e
        brigava por largura com tudo. Vai voltar noutro lugar - candidato
        natural e um quadro proprio na aba, ou um "ver no jogo" que abre a roda
        de verdade - mas isso e desenho para a proxima rodada.
    ]]
    self:drawText(txt("IGUI_TheZims_DlcConfig", "Configuracoes da DLC"),
        PAD + ABA_W + PAD + CONT_PAD, BARRA_H + PAD + CONT_TOPO - 30,
        S.texto.r, S.texto.g, S.texto.b, 1, UIFont.Medium)
end

function TheZimsOptions:close()
    ISCollapsableWindow.close(self)
    self:removeFromUIManager()
    TheZimsOptions.instancia = nil
end

------------------------------------------------------------------
function TheZims.alternarJanela()
    if TheZimsOptions.instancia then
        TheZimsOptions.instancia:close()
        return
    end
    local lt, at = getCore():getScreenWidth(), getCore():getScreenHeight()
    -- Mais larga por causa da faixa de abas na esquerda. A altura e so de
    -- partida: createChildren mede o conteudo e reajusta.
    --[[
        A altura vem do CONTEUDO, nao de um chute. A aba mais alta (Zim Pie:
        8 caixas, 4 combos, cores e restaurar) precisa de ~560 + o padding; um
        valor menor aqui fazia o setHeight do createChildren esticar a janela
        depois, e a coluna de cartoes ficava com um vao morto embaixo.
    ]]
    local w, h = 990, 640
    local ok, j = pcall(function()
        local win = TheZimsOptions:new((lt - w) / 2, (at - h) / 2, w, h)
        win:initialise(); win:addToUIManager()
        return win
    end)
    if ok then TheZimsOptions.instancia = j
    else print("[TheZims] falha ao abrir a janela: " .. tostring(j)) end
end

--- Liga/desliga a roda sem abrir a janela. Como todo hook do TheZims_Patch cai
--- no original quando isZimMenu() e falso, isto devolve o menu de fabrica
--- inteiro, sem reiniciar.
local function alternarLigado()
    TheZims.PREF.ligado = not (TheZims.PREF.ligado ~= false)
    TheZims.aplicarPrefs()
    TheZims.salvarPrefs()

    pcall(function()
        local ctx = getPlayerContextMenu(0)
        if ctx and ctx.isAnyVisible and ctx:isAnyVisible() then ctx:closeAll() end
    end)
    if TheZims.Avatar then TheZims.Avatar.hide() end

    if TheZimsOptions.instancia and TheZimsOptions.instancia.caixas then
        TheZimsOptions.instancia.caixas:setSelected(1, TheZims.PREF.ligado)
    end
    pcall(function()
        HaloTextHelper.addText(getSpecificPlayer(0),
            getText(TheZims.PREF.ligado and "IGUI_TheZims_On" or "IGUI_TheZims_Off"))
    end)
end

Events.OnKeyPressed.Add(function(tecla)
    if tecla == nil or tecla == 0 then return end
    if tecla == getCore():getKey(BIND) then
        TheZims.alternarJanela()
    elseif tecla == getCore():getKey(BIND_TOGGLE) then
        alternarLigado()
    end
end)

print("[TheZims] opcoes prontas - abra com a tecla em Opcoes > Controles > [The Zims]")
