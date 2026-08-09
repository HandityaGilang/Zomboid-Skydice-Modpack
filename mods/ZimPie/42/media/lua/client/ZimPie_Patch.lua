--[[
    Mexe so na APRESENTACAO do ISContextMenu.

    Nada aqui toca em como as opcoes sao montadas. O jogo e os outros mods
    continuam enchendo o menu pelo caminho normal -- OnFillWorldObjectContextMenu,
    addOption, addSubMenu -- e este arquivo apenas desenha essa mesma lista como
    roda e resolve o clique por posicao em vez de por linha. E por isso que
    opcao de mod de terceiro aparece na roda de graca.

    Substituidos: prerender, render, onMouseMove, onMouseUp, onMouseWheel,
    getIndexAt, topmostMenuWithMouse, calcWidth, calcHeight, isOptionSingleMenu,
    displaySubMenu, displayAncestor, mais envelopes em ISContextMenu.get e
    ISWorldObjectContextMenu.createMenu.

    Todo substituto cai no original guardado quando o menu nao e roda, entao
    desligar o mod em tempo real devolve o comportamento de fabrica.
]]

-- Os dois requires importam: garantem que as classes existem antes de pegarmos
-- referencia para os metodos. Sem o segundo, o envelope de createMenu pode virar
-- no-op dependendo da ordem de carregamento, e o menu do mundo nunca seria
-- marcado -- o mod pareceria nao fazer nada.
require "ISUI/ISContextMenu"
require "ISUI/ISWorldObjectContextMenu"
require "ISUI/ISUI3DModel"

--[[
    A BASE E CONFERIDA EM TEMPO DE EXECUCAO, NAO AQUI NO CARREGAMENTO.

    A primeira versao deste arquivo comecava com `if not TheZims then return end`.
    Parecia prudente e era um defeito grave: `TheZims` e uma global que so
    existe depois que o TheZims_Config.lua roda, e a ordem em que o PZ carrega
    o Lua de MODS DIFERENTES segue a lista de mods do jogador, nao o alfabeto.

    Quem tivesse o Zim Pie antes do The Zims na lista carregava este arquivo
    com `TheZims` ainda nil. O arquivo desistia inteiro, nenhum substituto era
    instalado, e o jogador via o menu vertical de fabrica -- sem erro no
    console, sem nada. "Os dois mods ativos e nao acontece nada", que foi
    exatamente o relato de tres pessoas na Workshop no mesmo dia.

    Aqui em casa nunca aparecia, porque nesta maquina o The Zims calha de vir
    antes. E o pior tipo de bug: invisivel para quem escreve, total para parte
    de quem usa.

    A protecao continua existindo, so que no lugar certo. Os doze substitutos
    perguntam `isZimMenu()` antes de fazer qualquer coisa e caem no original
    guardado quando a resposta e nao -- conferido um por um. Basta `isZimMenu`
    responder nao quando a base falta, e o menu do jogo fica intacto para todo
    mundo, inclusive para os outros mods.

    E ha uma vantagem de graca: instalado sempre, o mod passa a funcionar mesmo
    para quem ative o The Zims depois, sem precisar reordenar lista nenhuma.
]]

ZimPie = ZimPie or {}

local Draw, Layout, Avatar = nil, nil, nil
local function D() Draw = Draw or TheZims.Draw; return Draw end
local function L() Layout = Layout or ZimPie.Layout; return Layout end
local function A() Avatar = Avatar or TheZims.Avatar; return Avatar end

local cos, sin, rad, floor, min, max = math.cos, math.sin, math.rad, math.floor, math.min, math.max

-- ------------------------------------------------------------- originais
local V = {
    prerender            = ISContextMenu.prerender,
    render               = ISContextMenu.render,
    onMouseMove          = ISContextMenu.onMouseMove,
    onMouseUp            = ISContextMenu.onMouseUp,
    onMouseWheel         = ISContextMenu.onMouseWheel,
    getIndexAt           = ISContextMenu.getIndexAt,
    topmostMenuWithMouse = ISContextMenu.topmostMenuWithMouse,
    calcWidth            = ISContextMenu.calcWidth,
    calcHeight           = ISContextMenu.calcHeight,
    isOptionSingleMenu   = ISContextMenu.isOptionSingleMenu,
    displaySubMenu       = ISContextMenu.displaySubMenu,
    displayAncestor      = ISContextMenu.displayAncestor,
    get                  = ISContextMenu.get,
    -- Navegacao por controle: substituida so quando o menu e roda.
    onJoypadDirUp        = ISContextMenu.onJoypadDirUp,
    onJoypadDirDown      = ISContextMenu.onJoypadDirDown,
    onJoypadDirLeft      = ISContextMenu.onJoypadDirLeft,
    onJoypadDirRight     = ISContextMenu.onJoypadDirRight,
    onJoypadDown         = ISContextMenu.onJoypadDown,
}
ZimPie._vanilla = V

-- --------------------------------------------------------------- apoio

--- Sobe ate o menu raiz. Submenu guarda um menu de verdade em .parent; a raiz
--- tem .parent nil ou a tabela vazia criada em ISContextMenu:new.
local function rootOf(menu)
    local m, guard = menu, 0
    while guard < 32 do
        local p = m.parent
        if type(p) ~= "table" or p.options == nil then break end
        m = p
        guard = guard + 1
    end
    return m
end

--[[
    O BONECO PARA ENQUANTO A RODA ESTA ABERTA NO CONTROLE.

    O analogico esquerdo faz duas coisas ao mesmo tempo: aponta a fatia e anda
    com o personagem. Escolher uma opcao virava uma caminhada -- as vezes para
    longe do proprio objeto que se ia usar.

    `setBlockMovement` e a API do jogo para isto, e o ISOnScreenKeyboard usa o
    mesmo padrao ao abrir o teclado virtual. Copiei dele a parte que importa:
    SO DEVOLVER O QUE NOS TOMAMOS. Se o jogador ja estava bloqueado por outro
    motivo -- outro mod, uma acao do jogo -- nao mexemos, e sobretudo nao
    destravamos ao fechar. Destravar por engano seria pior que o problema
    original.

    So vale para controle. No mouse o personagem nao anda com o menu aberto, e
    bloquear ali afetaria quem nem usa a roda.
]]
ZimPie._travado = ZimPie._travado or {}

local function travarMovimento(playerNum, ligar)
    if playerNum == nil then return end
    pcall(function()
        local p = getSpecificPlayer(playerNum)
        if not p then return end
        if ligar then
            if ZimPie._travado[playerNum] then return end
            -- Ja bloqueado por outra coisa: nao e nosso, nao encostamos.
            if p:isBlockMovement() then return end
            ZimPie._travado[playerNum] = true
            p:setBlockMovement(true)
        else
            if not ZimPie._travado[playerNum] then return end
            ZimPie._travado[playerNum] = nil
            p:setBlockMovement(false)
        end
    end)
end

--[[
    A REDE. Roda a cada quadro, independente do menu.

    Destravar dentro do proprio menu nao basta: ele pode sumir por caminhos que
    nao controlamos -- morte, troca de personagem, outro mod fechando tudo, um
    erro em qualquer lugar do render. Qualquer um desses deixaria o jogador
    preso no lugar, sem entender por que, e sem nada na tela explicando.

    Por isso a condicao aqui e positiva e checada sempre: "existe uma roda
    visivel e com foco de controle?" Se a resposta e nao, seja qual for o
    motivo, o bloqueio sai. Um quadro de atraso e imperceptivel; um travamento
    permanente nao.
]]
Events.OnTick.Add(function()
    for playerNum in pairs(ZimPie._travado) do
        local ok = false
        pcall(function()
            --[[
                Segue o FOCO, e nao o menu raiz.

                A primeira versao perguntava por `getPlayerContextMenu`, que
                devolve a raiz. Com um submenu aberto a raiz esta escondida e
                sem foco, entao o bloqueio saia e o boneco voltava a andar
                justamente dentro do submenu -- o lugar onde ele mais atrapalha.

                `JoypadState.players[n+1].focus` aponta para o menu que esta
                mesmo recebendo a entrada, seja ele raiz ou o terceiro nivel.

                `foco.isZimMenu ~= nil` antes de chamar: o foco pode estar em
                qualquer elemento da interface -- inventario, janela de
                artesanato -- e chamar um metodo que so o menu de contexto tem
                daria erro a cada quadro.
            ]]
            local jd = JoypadState and JoypadState.players and JoypadState.players[playerNum + 1]
            local foco = jd and jd.focus
            ok = foco ~= nil and foco.isZimMenu ~= nil
                 and foco:getIsVisible() and foco:isZimMenu()
        end)
        if not ok then travarMovimento(playerNum, false) end
    end
end)

--[[
    Verdadeiro quando este menu deve ser desenhado como roda.

    Este `if` e o unico portao do mod. Os doze substitutos perguntam por ele
    antes de agir, e todos caem no metodo vanilla guardado quando a resposta e
    nao -- entao "a base nao esta ai" e apenas mais um motivo para responder
    nao, tratado no mesmo lugar que "o jogador desligou" e "este menu nao e do
    mundo".

    A checagem de `TheZims` vem primeiro e e por existencia, nao por conteudo:
    se a base faltar, `TheZims.isOn()` indexaria um nil e estouraria a cada
    clique do direito -- em vez de simplesmente devolver o menu de fabrica.
]]
function ISContextMenu:isZimMenu()
    if not TheZims or not TheZims.isOn then return false end
    if not TheZims.isOn() then return false end
    local root = rootOf(self)
    if TheZims.CFG.applyTo == "all" then
        return root.zimEligible == true or root.zimInventory == true
    end
    return root.zimEligible == true
end

local function fade(c, a)
    return { r = c.r, g = c.g, b = c.b, a = c.a * a }
end

--[[
    Os dois tocam por TheZims.tocarSomUI, nao por playUISound direto.

    E ela que aplica o volume escolhido na barrinha da janela - `playUISound`
    sozinha nao aceita volume, e o ajuste depende do handle que ela devolve.
    Chamar playUISound aqui faria estes dois sons ignorarem a barrinha enquanto
    todo o resto a respeita, que e o pior tipo de bug: some quando o jogador
    testa com o volume no meio e volta quando ele esquece.

    O `and ... or nil` na chamada mantem o mod vivo contra uma base antiga, sem
    a funcao: fica sem som em vez de erro na tela.
]]
local function playHoverSound()
    if not TheZims.CFG.hoverSound then return end
    if TheZims.tocarSomUI then TheZims.tocarSomUI(TheZims.CFG.hoverSoundName) end
end

--- Toca ao confirmar uma escolha, inclusive ao virar pagina. O nome vem de
--- TheZims.somDeClique(), que devolve nil quando o jogador desligou, ou o som
--- embutido do PZ quando ele escolheu "Padrao do jogo".
local function playClickSound()
    local nome = TheZims.somDeClique and TheZims.somDeClique() or nil
    if not nome then return end
    if TheZims.tocarSomUI then TheZims.tocarSomUI(nome) end
end

--- Cores da pilula e do texto conforme o estado da opcao.
-- `C` e a paleta ja resolvida do quadro (personagem ou reserva), passada de
-- fora para nao consultar o visual do personagem uma vez por pilula.
local function optionColors(C, opt, hovered)
    if opt.isDisabled or opt.notAvailable then
        return C.pillDisabled, C.textDisabled, C.pillDisabled, nil
    end
    local fill = hovered and C.pillHover or C.pill
    local hi   = hovered and C.pillHiHover or C.pillHi
    local orb  = hovered and C.orbHover or C.orb
    local text = C.text
    if opt.badColor or opt.goodColor then
        local hc = opt.badColor and getCore():getBadHighlitedColor() or getCore():getGoodHighlitedColor()
        text = { r = hc:getR(), g = hc:getG(), b = hc:getB(), a = 1 }
    end
    return fill, text, orb, hi
end

-- ----------------------------------------------------------- geometria

--[[
    Liga e desliga a captura de mouse do elemento.

    O menu e um quadrado em volta da roda, e um elemento que captura mouse come
    TODO o seu retangulo - inclusive os cantos vazios. Era por isso que o clique
    direito em outro objeto perto da roda nao fazia nada: o evento morria aqui e
    nunca chegava ao mundo.

    Com a captura desligada enquanto o cursor esta no vazio, o clique atravessa
    e o jogo abre o menu novo normalmente.
]]
local function setConsume(menu, want)
    if menu.zimConsuming == want then return end
    menu.zimConsuming = want
    pcall(function()
        if menu.javaObject then menu.javaObject:setConsumeMouseEvents(want) end
    end)
end

local function position(menu)
    local size = L().boxSize(menu)
    if menu.width ~= size then menu:setWidth(size) end
    if menu.height ~= size then menu:setHeight(size) end

    -- setX/setY nao podem passar pelo clamp generico de tela, senao a roda
    -- deixa de nascer sob o cursor; o centro e limitado aqui embaixo.
    menu.keepOnScreen = false

    local root = rootOf(menu)
    local cx = root.zimCenterX or menu.requestX or (getCore():getScreenWidth() / 2)
    local cy = root.zimCenterY or menu.requestY or (getCore():getScreenHeight() / 2)

    local margin = TheZims.CFG.pillRadius + 10
    cx = max(margin, min(getCore():getScreenWidth() - margin, cx))
    cy = max(margin, min(getCore():getScreenHeight() - margin, cy))

    menu.zimCX, menu.zimCY = cx, cy
    menu:setX(cx - size / 2)
    menu:setY(cy - size / 2)
end

--- Recalcula o que o cursor esta apontando. Roda todo quadro, porque o cursor
--- pode ficar parado sobre a cabeca sem nunca disparar onMouseMove.
local function updateHover(menu)
    --[[
        Com o controle no comando, o MOUSE NAO MANDA.

        Este updateHover roda a cada quadro e escrevia o destaque a partir da
        posicao do cursor. Num controle o cursor fica parado onde estava, entao
        ele apagava a cada quadro a opcao que o jogador tinha acabado de
        escolher com o analogico -- a navegacao parecia nao funcionar.

        `joyfocus` e posto pelo setJoypadFocus do proprio jogo (ISButtonPrompt
        faz isso ao abrir o menu do mundo por controle).
    ]]
    if menu.joyfocus then return end

    local mx = getMouseX() - menu.x
    local my = getMouseY() - menu.y
    local kind, slice = L().hitTest(menu, mx, my)

    local prev = menu.zimHoverKey
    menu.zimHoverKind = kind
    menu.zimHoverSlice = slice

    if kind == "slice" and slice.kind == "option" then
        menu.mouseOver = slice.index
        menu.zimHoverKey = "o" .. tostring(slice.index)
    else
        menu.mouseOver = -1
        menu.zimHoverKey = kind
    end

    if menu.zimHoverKey ~= prev and kind == "slice" then
        playHoverSound()
    end
end

-- ------------------------------------------------------------ ciclo de vida

ISContextMenu.get = function(player, x, y)
    --[[
        Limpar as marcas ANTES de delegar, nao depois.

        O `get` vanilla chama `setSlideGoalY` la dentro, e esse metodo pergunta
        `isOptionSingleMenu()` - que nos substituimos. Como o ctx e um singleton
        reaproveitado, nesse instante `zimEligible` ainda e do menu ANTERIOR, e a
        nossa resposta saia baseada nele. O menu seguinte herdava a decisao do
        anterior, o que fazia o defeito aparecer so as vezes.
    ]]
    local anterior = getPlayerContextMenu(player)
    if anterior then
        anterior.zimEligible, anterior.zimInventory = false, false
    end

    local ctx = V.get(player, x, y)

    -- Consome a marca posta pelo envelope de ISWorldObjectContextMenu abaixo.
    -- Ela se limpa sozinha, entao menu aberto de qualquer outro lugar nunca e
    -- marcado por engano.
    ctx.zimEligible  = (ZimPie._worldRequest == true)
    ctx.zimInventory = (ZimPie._invRequest == true)
    ZimPie._worldRequest = false
    ZimPie._invRequest   = false

    ctx.zimPage = 1
    ctx.zimOpenAt = getTimestampMs()
    ctx.zimLayout = nil
    ctx.zimHoverKey, ctx.zimHoverKind, ctx.zimHoverSlice = nil, nil, nil
    ctx.zimArmed = false -- so fecha por clique no vazio depois de soltar o botao

    -- Mexer no menu SO quando ele vai mesmo virar roda. O `slideGoal` que
    -- zeramos aqui e o que faz o menu vanilla deslizar ao abrir; apagar isso
    -- num menu que nao e nosso tira a animacao de entrada de qualquer outro
    -- mod que abra menu de contexto (as barras de filtro e o menu de cabelo
    -- do NeatUI, por exemplo). Perguntamos ao mesmo criterio do desenho.
    if ctx:isZimMenu() then
        ctx.zimCenterX, ctx.zimCenterY = x, y
        ctx.slideGoalX, ctx.slideGoalY = nil, nil
    end
    return ctx
end

--[[
    Modo de teste: joga fora o menu real e poe 20 opcoes no lugar.

    Existe porque o caso que quebra o layout e justamente o que quase nunca
    aparece jogando - menu lotado, nome enorme, opcao desabilitada e submenu ao
    mesmo tempo. Clicar em meio mundo procurando um objeto assim e perda de
    tempo; aqui qualquer clique produz o pior caso na hora.

    As 20 opcoes sao de proposito irregulares: nomes de 3 a 60 caracteres,
    algumas cinzas, algumas com submenu, algumas com cor de aviso.
]]
local NOMES_TESTE = {
    "Ok", "Beber", "Desmontar",
    "Sentar no chao", "Andar ate aqui agora",
    "Cadeira de Carvalho Vermelho Envernizada da Vovo",
    "Pegar", "Inspecionar o objeto com atencao",
    "Abrir", "Trancar a porta com a chave enferrujada",
    "Dormir ate de manha", "Costurar", "Jardinagem",
    "Colocar um item muito comprido dentro do recipiente enorme",
    "Fechar", "Limpar sangue", "Ler",
    "Desmontar com a chave de fenda e guardar as pecas",
    "Fumar", "Gritar por socorro",
}

function ZimPie.menuDeTeste(ctx)
    ctx:clear()
    for i, nome in ipairs(NOMES_TESTE) do
        local o = ctx:addOption(i .. ". " .. nome, nil, function() end)
        -- Um pouco de cada estado, espalhado, para ver todos na mesma tela.
        if i % 7 == 0 then o.isDisabled = true end
        if i % 9 == 0 then o.notAvailable = true end
        if i % 5 == 0 then o.badColor = true end
        if i % 6 == 0 then o.goodColor = true end
        if i % 4 == 0 then
            local sub = ISContextMenu:getNew(ctx)
            ctx:addSubMenu(o, sub)
            for k = 1, 5 do
                sub:addOption("Sub " .. i .. "." .. k .. " opcao de teste", nil, function() end)
            end
        end
    end
    TheZims.log("menu de teste: " .. #NOMES_TESTE .. " opcoes")
end

--[[
    Envelope do inventario, irmao do de mundo logo abaixo.

    Sem ele, "Mundo e inventario" nao tinha como saber o que e inventario e
    acabava valendo para QUALQUER menu de contexto - inclusive os que outros
    mods abrem na propria interface (lista de penteados, barra de filtro de
    craft). Virar aquilo em roda nao e o que a opcao promete.

    O jogo tem duas portas de entrada, e as duas sao atribuicoes de campo, nao
    `function X.y()`, por isso o envelope guarda o valor em vez de chamar a
    global depois.
]]
if ISInventoryPaneContextMenu then
    for _, porta in ipairs({ "createMenu", "createMenuNoItems" }) do
        local vanilla = ISInventoryPaneContextMenu[porta]
        if vanilla then
            ISInventoryPaneContextMenu[porta] = function(...)
                ZimPie._invRequest = true
                local ok, result = pcall(vanilla, ...)
                ZimPie._invRequest = false
                if not ok then error(result) end
                return result
            end
        end
    end
end

--[[
    A MARCA DO MENU DO MUNDO VEM DE UM EVENTO, NAO DO ENVELOPE ABAIXO.

    O envelope de `createMenu` funcionava, mas dependia de ninguem mais
    reatribuir aquela funcao depois de nos -- e o Neat Building reatribui.

    O que ele faz (disablecontextmenuwhendrag.lua):

        _NB_old_createMenu = _NB_old_createMenu or createMenu   -- guarda
        ...
        createMenu = NB_createMenu_wrapper                      -- instala

    A segunda linha roda dentro de um callback (NB_RegisterUiToggleCallback),
    ou seja, DEPOIS que todos os arquivos carregaram. E incondicional: joga
    fora o que estiver la.

    Com o Zim Pie carregando primeiro, o `_NB_old_createMenu` deles captura o
    NOSSO envelope, a corrente passa por nos e tudo funciona. Carregando
    depois, eles ja guardaram o vanilla; quando o callback reaplica, o nosso
    envelope some da corrente. `_worldRequest` nunca e marcado, `isZimMenu`
    responde nao, e sai o menu vertical. Nenhuma ordem de ARQUIVO resolve
    isso, porque atribuicao por evento sempre vence carregamento.

    Foi exatamente o que os jogadores descobriram na mao: "coloque os dois
    mods do Zims ACIMA do NeatUI Framework". A receita funciona e ninguem
    deveria precisar dela.

    OnPreFillWorldObjectContextMenu resolve na raiz. O evento dispara DENTRO
    do createMenu vanilla (ISWorldObjectContextMenu.lua:190), depois do
    ISContextMenu.get da linha 164 -- entao o `context` que ele entrega e o
    menu ja criado, e podemos marca-lo direto. Um mod nao consegue tirar outro
    de uma lista de eventos por atribuicao; para nos apagar teria que remover
    o nosso handler pelo nome, o que ninguem faz por acidente.

    O envelope abaixo FICA, e nao e redundancia: ele ainda serve ao
    debugFakeMenu, e quando somos nos os primeiros a carregar ele marca antes
    do evento, sem custo. Duas rotas para a mesma marca, e a que sobrevive a
    qualquer ordem e a de cima.
]]
if Events and Events.OnPreFillWorldObjectContextMenu then
    Events.OnPreFillWorldObjectContextMenu.Add(function(_player, context, _worldobjects, _test)
        if context then context.zimEligible = true end
    end)
end

if ISWorldObjectContextMenu and ISWorldObjectContextMenu.createMenu then
    local vanillaCreate = ISWorldObjectContextMenu.createMenu
    ISWorldObjectContextMenu.createMenu = function(player, worldobjects, x, y, test)
        ZimPie._worldRequest = true
        local result = vanillaCreate(player, worldobjects, x, y, test)
        ZimPie._worldRequest = false

        -- Depois do menu real estar montado, para o teste refletir o mesmo
        -- caminho de criacao que o jogo usa - inclusive as opcoes de outros mods
        -- sendo descartadas, que e o ponto.
        -- `TheZims and` porque este envelope roda em TODO clique com o botao
        -- direito no mundo, esteja a base presente ou nao. E o unico ponto do
        -- arquivo que executa fora do portao do isZimMenu.
        if TheZims and TheZims.CFG.debugFakeMenu and not test then
            local ctx = getPlayerContextMenu(player)
            if ctx then pcall(ZimPie.menuDeTeste, ctx) end
        end
        return result
    end
else
    -- Barulhento de proposito. Falha silenciosa aqui parece "o mod nao faz
    -- nada", que e bem mais dificil de diagnosticar que uma linha no console.
    print("[TheZims] ERRO: ISWorldObjectContextMenu.createMenu nao encontrado; " ..
          "o menu do mundo vai continuar vertical.")
end

-- Forcar o modo de menu unico nos da de graca as entradas de volta
-- (addDefaultOptions) e a troca de submenu no lugar, que e exatamente o modelo
-- de navegacao que uma roda precisa.
function ISContextMenu:isOptionSingleMenu()
    if self:isZimMenu() then return true end
    return V.isOptionSingleMenu(self)
end

function ISContextMenu:calcHeight()
    if not self:isZimMenu() then return V.calcHeight(self) end
    local size = L().boxSize(self)
    self.scrollAreaHeight = size
    self:setHeight(size)
    self:setScrollHeight(0)
end

function ISContextMenu:calcWidth()
    if not self:isZimMenu() then return V.calcWidth(self) end
    return L().boxSize(self)
end

--- O que o centro faz: sobe um nivel se houver para onde voltar, senao fecha.
--- Vive aqui porque duas coisas disparam isso - o clique no miolo e o clique no
--- proprio avatar 3D, que fica por cima e tem os eventos de mouse dele.
function ISContextMenu:zimHubAction()
    local back = L().backOption(self)
    if back and back.onSelect then
        playClickSound()
        ISContextMenu.globalPlayerContext = self.player
        back.onSelect(back.target, back.param1, back.param2, back.param3, back.param4,
            back.param5, back.param6, back.param7, back.param8, back.param9, back.param10)
    else
        self:closeAll()
        A().hide()
    end
end

function ISContextMenu:displaySubMenu(subMenu, option)
    if not self:isZimMenu() then return V.displaySubMenu(self, subMenu, option) end

    -- Lido ANTES de esconder: a troca de foco la embaixo limpa este campo do
    -- menu que perde, e ai a pergunta ja nao teria resposta.
    local tinhaFoco = self.joyfocus ~= nil

    self:hideSelf()
    subMenu.zimPage = 1
    subMenu.zimLayout = nil
    subMenu.zimOpenAt = getTimestampMs()
    subMenu.slideGoalX, subMenu.slideGoalY = nil, nil
    subMenu.mouseOver = -1
    subMenu.mouseOut = false
    subMenu:addDefaultOptions()
    subMenu:setVisible(true)

    --[[
        O FOCO DO CONTROLE VAI JUNTO.

        Sem esta linha o primeiro nivel funcionava e o submenu ficava morto --
        nada destacado, A sem efeito, nem com uma opcao so na tela.

        A razao: `joyfocus` continuava no menu PAI, que `hideSelf` acabou de
        esconder. O jogo entrega a entrada do controle ao elemento focado, e
        esse elemento estava invisivel. O submenu nascia com joyfocus nil,
        entao o bloco do analogico no prerender nem chegava a rodar para ele.

        O vanilla faz exatamente isto no onJoypadDown (ISContextMenu.lua:254);
        perdemos ao substituir o metodo sem trazer a linha junto.

        `tinhaFoco` porque quem joga no mouse nao tem foco de controle nenhum,
        e chamar setJoypadFocus ali daria o comando ao controle de quem nao
        pediu.
    ]]
    if tinhaFoco then
        pcall(setJoypadFocus, self.player, subMenu)
    end
end

function ISContextMenu:displayAncestor(ancestor)
    if not self:isZimMenu() then return V.displayAncestor(self, ancestor) end

    local tinhaFoco = self.joyfocus ~= nil

    self:hideSelf()
    ancestor.zimLayout = nil
    ancestor.zimOpenAt = getTimestampMs()
    ancestor.slideGoalX, ancestor.slideGoalY = nil, nil
    ancestor.mouseOver = -1
    ancestor.mouseOut = false
    ancestor:setVisible(true)

    -- A volta e o mesmo problema espelhado: sem devolver o foco, o B levaria a
    -- um menu visivel que nao recebe entrada nenhuma. Um caminho so consertado
    -- deixaria o jogador entrar e nao conseguir sair.
    if tinhaFoco then
        pcall(setJoypadFocus, self.player, ancestor)
    end
end

-- ----------------------------------------------------------------- entrada

function ISContextMenu:getIndexAt(x, y)
    if not self:isZimMenu() then return V.getIndexAt(self, x, y) end
    local kind, slice = L().hitTest(self, x, y)
    if kind == "slice" and slice.kind == "option" then
        return slice.index
    end
    return -1
end

function ISContextMenu:onMouseMove(dx, dy)
    if not self:isZimMenu() then return V.onMouseMove(self, dx, dy) end
    self.mouseOut = false
    if self:topmostMenuWithMouse(getMouseX(), getMouseY()) ~= self then return end

    local previous = self.mouseOver
    updateHover(self)
    if self.subMenu and self.mouseOver ~= previous then
        self.subMenu:hideSelfAndChildren2()
        self.subMenu = nil
    end
end

function ISContextMenu:onMouseWheel(del)
    if not self:isZimMenu() then return V.onMouseWheel(self, del) end
    L().flipPage(self, del > 0 and 1 or -1)
    updateHover(self)
    return true
end

function ISContextMenu:onMouseUp(x, y)
    if not self:isZimMenu() then return V.onMouseUp(self, x, y) end
    if not self:getIsVisible() then return end

    local kind, slice = L().hitTest(self, x, y)

    if kind == "hub" then
        self:zimHubAction()
        return
    end

    -- Clique no vazio dentro da caixa: fecha. Normalmente nem chega aqui, porque
    -- a captura de mouse esta desligada nessa area (ver setConsume) e o evento
    -- vai direto para o mundo -- mas se chegar, fechar e a resposta certa.
    if kind == "out" or not slice then
        self:closeAll()
        A().hide()
        return
    end

    self:zimSelecionar(slice)
end

--[[
    Confirmar uma fatia. Ponto UNICO de escolha: o clique do mouse e o botao A
    do controle passam os dois por aqui.

    Estava embutido no onMouseUp. Ao ligar o controle, ou eu duplicava tudo -
    incluindo o destravar do tempo pausado, que e facil esquecer num dos dois -
    ou extraia. Extrair garante que mouse e controle nunca divirjam no que
    acontece ao escolher.
]]
function ISContextMenu:zimSelecionar(slice)
    if not slice then return end

    -- Topo e base sao navegacao, nunca opcao.
    if slice.kind == "more" or slice.kind == "prev" then
        playClickSound()
        L().flipPage(self, slice.kind == "more" and 1 or -1)
        updateHover(self)
        return
    end

    local option = self.options[slice.index]
    if option == nil then return end

    -- Espelha ISContextMenu:onMouseUp. Escolher fecha a arvore inteira; opcao
    -- que so abre submenu troca a roda no lugar.
    if option.onSelect ~= nil and not option.notAvailable and not option.isDisabled then
        playClickSound()
        ISContextMenu.globalPlayerContext = self.player
        self:closeAll()

        --[[
            Escolher uma acao com o jogo PAUSADO destrava o tempo primeiro.

            Sem isto o clique parecia morto: a roda abre pausada (o clique
            direito do mundo nao checa pausa), mas o handler de quase toda
            opcao comeca com `if isGamePaused() then return end` - o clique
            chegava la e morria em silencio, sem erro e sem efeito.

            Nao da para executar acoes com o tempo parado - acao e simulacao,
            precisa do relogio andando. O que da e o que oito dialogos do
            proprio jogo fazem (ISSleepDialog, ISAlarmClockDialog...):
            SetCurrentGameSpeed(1) antes de agir. Escolher "Dormir" na roda
            pausada passa a significar "toca o tempo e dorme", que e o que o
            jogador quis dizer.

            Multiplayer nao pausa, entao a velocidade nunca e 0 la e isto
            nunca dispara.
        ]]
        pcall(function()
            local sc = UIManager.getSpeedControls()
            if sc and sc:getCurrentGameSpeed() == 0 then
                sc:SetCurrentGameSpeed(1)
            end
        end)

        option.onSelect(option.target, option.param1, option.param2, option.param3, option.param4,
            option.param5, option.param6, option.param7, option.param8, option.param9, option.param10)
    elseif option.subOption ~= nil then
        local subMenu = self:getSubMenu(option.subOption)
        if subMenu then
            playClickSound()
            subMenu.mouseOver = -1
            self:displaySubMenu(subMenu, option)
        end
    end
end

-- ------------------------------------------------------- controle

--[[
    NAVEGACAO POR CONTROLE.

    O menu vanilla anda pela LISTA: cima/baixo pulam um indice. Numa roda isso
    nao serve - o indice 3 pode estar em cima do 1, do outro lado da cabeca.
    Aqui a navegacao e por GEOMETRIA: cada fatia guarda `px`/`py` (posicao real
    na tela, ver Layout.placePill), e mover e procurar a fatia mais proxima na
    direcao pedida.

    Nao existe leitura de eixo analogico no Lua do PZ - procurei em todo o
    media/lua e nao ha getXAxis nem equivalente. O radial de armas do jogo
    resolve isso com `getSliceIndexFromJoypad`, que vive no javaObject do
    ISRadialMenu e nao existe no ISContextMenu. Entao a roda usa os quatro
    eventos discretos que o jogo entrega, que numa disposicao em duas colunas
    e o gesto natural mesmo: cima/baixo andam na coluna, esquerda/direita
    trocam de lado.
]]
local function fatiasDeOpcao(menu)
    local lay = menu.zimLayout
    if not lay or not lay.slices then return {} end
    local out = {}
    for _, s in ipairs(lay.slices) do
        if s.kind == "option" then out[#out + 1] = s end
    end
    return out
end

--- Centro de uma fatia, em coordenadas relativas ao centro da roda.
local function centroDa(s)
    return s.px + s.pw / 2, s.py + s.ph / 2
end

--- A fatia atualmente destacada, ou nil.
local function fatiaAtual(menu)
    for _, s in ipairs(fatiasDeOpcao(menu)) do
        if s.index == menu.mouseOver then return s end
    end
    return nil
end

--- Aponta o destaque para uma fatia e mantem o resto do estado coerente.
--[[
    `silencioso` existe por causa de um detalhe que custou uma sessao de teste.

    O `Layout.build` reconstroi as fatias A CADA QUADRO -- tabelas novas, nao as
    mesmas com valores atualizados. E o render decide o destaque por IDENTIDADE
    de objeto (`s == hoverSlice`). Ou seja: `zimHoverSlice` precisa ser
    reapontado para a fatia do quadro ATUAL toda vez, ou vira referencia para um
    objeto que ja nao esta na lista, e nenhuma fatia aparece destacada.

    A primeira versao so chamava esta funcao quando o indice mudava, para o som
    de destaque nao tocar 60 vezes por segundo com o analogico parado. O som
    ficou certo e o destaque sumiu: acendia por um quadro e apagava.

    Separar as duas coisas resolve as duas. Os campos sao reescritos sempre; o
    som toca so quando o alvo muda de verdade.
]]
local function focar(menu, s, silencioso)
    if not s then return false end
    menu.mouseOver = s.index
    menu.zimHoverKind = "slice"
    menu.zimHoverSlice = s
    menu.zimHoverKey = "o" .. tostring(s.index)
    if not silencioso then playHoverSound() end
    return true
end

--[[
    Vizinha na direcao (dx, dy).

    O criterio nao e so "a mais proxima": exige que a candidata esteja de fato
    naquele lado (projecao positiva) e penaliza o desvio lateral. Sem isso,
    apertar para baixo saltava para a coluna oposta sempre que houvesse uma
    pilula um pouco mais perto na diagonal.
]]
local function vizinha(menu, dx, dy)
    local atual = fatiaAtual(menu)
    local lista = fatiasDeOpcao(menu)
    if #lista == 0 then return nil end
    if not atual then return lista[1] end

    local ax, ay = centroDa(atual)
    local melhor, melhorCusto = nil, nil
    for _, s in ipairs(lista) do
        if s ~= atual then
            local sx, sy = centroDa(s)
            local vx, vy = sx - ax, sy - ay
            local aoLongo = vx * dx + vy * dy          -- avanco na direcao
            local lateral = math.abs(vx * dy - vy * dx) -- desvio perpendicular
            if aoLongo > 1 then
                local custo = aoLongo + lateral * 2.5
                if not melhorCusto or custo < melhorCusto then
                    melhor, melhorCusto = s, custo
                end
            end
        end
    end
    return melhor
end

--[[
    Ao ganhar o foco do controle, destaca a primeira opcao.

    O ISButtonPrompt ja poe `mouseOver = 1` ao abrir por controle, mas 1 e o
    indice na LISTA de opcoes -- que numa roda com paginacao pode ser uma
    entrada de "voltar" (isDefaultOption), que nao vira pilula. Sem isto o
    jogador abria a roda sem nada destacado e a primeira direcao so servia para
    escolher onde comecar.

    Nao ha `onGainJoypadFocus` no ISContextMenu vanilla para cair de volta, por
    isso nao ha delegacao aqui.
]]
function ISContextMenu:onGainJoypadFocus(joypadData)
    --[[
        ESTA LINHA E O CONSERTO. Ela vem antes de tudo, inclusive do isZimMenu.

        `self.joyfocus` e a convencao do jogo para "este elemento esta sob o
        controle", e quem a grava e o ISUIElement:onGainJoypadFocus -- uma
        funcao de uma linha so: `self.joyfocus = joypadData`. Ao definir o
        nosso proprio onGainJoypadFocus no ISContextMenu, sombreamos o herdado
        e nunca chamamos ele. O campo ficava nil PARA SEMPRE.

        E ai o updateHover, que roda a cada quadro e comeca com
        `if menu.joyfocus then return end`, nunca retornava: recalculava o
        destaque pela posicao do cursor -- parado, porque quem joga de controle
        nao mexe o mouse -- e apagava no mesmo quadro a fatia que o direcional
        tinha acabado de escolher.

        O sintoma era exato e enganoso: o som de mudanca TOCAVA (o `focar`
        rodou) e a tela nao mudava (o updateHover desfez em seguida). Parecia
        problema de desenho; era de uma atribuicao que faltava.

        A mesma falta explicava a cabeca seguir o mouse: o avatar mira em
        `hoverSlice.mid` quando existe fatia destacada, e so cai no cursor
        quando nao existe. Com o destaque sendo zerado todo quadro, sobrava o
        cursor. Um conserto, tres sintomas.

        E vem ANTES do `isZimMenu` de proposito. Este metodo sombreia o
        herdado para TODO menu de contexto, inclusive os que nao viram roda.
        Sair antes de gravar o campo quebraria o foco de controle em menu de
        terceiro -- o oposto do que o mod promete.

        Nao ha `onLoseJoypadFocus` nosso, entao o do ISUIElement continua
        valendo e limpa o campo sozinho quando o foco sai.

        DELEGAR, e nao repetir a linha. A primeira correcao foi escrever
        `self.joyfocus = joypadData` aqui: resolve hoje e envelhece mal, porque
        se uma build futura fizer o herdado guardar mais alguma coisa, nos
        deixariamos de receber sem ninguem notar.

        Chamar o ancestral e o idioma que os proprios mods de controle usam --
        conferido no NeatUI_Hairstyler, que faz
        `ISPanelJoypad.onGainJoypadFocus(self, joypadData)` antes do resto em
        todos os quatro paineis dele. `ISContextMenu` deriva de `ISPanel`, que
        nao define o metodo; a chamada sobe pelo metatable ate o ISUIElement.
    ]]
    ISPanel.onGainJoypadFocus(self, joypadData)

    if not self:isZimMenu() then return end

    --[[
        A tentativa aqui quase sempre falha, e esta certo assim.

        Neste ponto o menu acabou de receber o foco e ainda nao passou por um
        prerender, entao `zimLayout` e nil e a lista vem vazia. Deixamos o
        recado e quem resolve e o prerender, com o layout ja construido.

        A tentativa fica porque nao custa nada e cobre o caso de o menu ja ter
        desenhado ao menos uma vez antes de reganhar o foco -- volta de submenu,
        por exemplo.
    ]]
    self.zimJoyFocoPendente = true
    local lista = fatiasDeOpcao(self)
    if lista[1] then focar(self, lista[1]) end
end

function ISContextMenu:onJoypadDirUp()
    if not self:isZimMenu() then return V.onJoypadDirUp(self) end
    focar(self, vizinha(self, 0, -1))
end

function ISContextMenu:onJoypadDirDown()
    if not self:isZimMenu() then return V.onJoypadDirDown(self) end
    focar(self, vizinha(self, 0, 1))
end

--[[
    DIRECAO SO MOVE. Entrar e voltar sao dos BOTOES.

    Estas duas funcoes faziam mais: sem vizinha a direita, a direita ENTRAVA no
    submenu; sem vizinha a esquerda, a esquerda VOLTAVA um nivel. Copiei o
    modelo do menu vertical do vanilla, onde direita e mesmo o gesto de entrar.

    Num menu vertical aquilo faz sentido: a lista so tem um eixo, e a direcao
    horizontal esta sobrando. Numa RODA as quatro direcoes sao todas usadas
    para escolher, e ai o mesmo gesto passa a significar duas coisas
    dependendo de onde voce esta -- move quando ha vizinha, confirma quando
    nao ha. Nao da para prever nem aprender: voce empurra para a direita
    esperando andar mais um e cai dentro de um submenu.

    Com X confirmando, Circulo voltando e LB/RB paginando, cada gesto tem um
    dono. Direcao move, e so.
]]
function ISContextMenu:onJoypadDirLeft()
    if not self:isZimMenu() then return V.onJoypadDirLeft(self) end
    focar(self, vizinha(self, -1, 0))
end

function ISContextMenu:onJoypadDirRight()
    if not self:isZimMenu() then return V.onJoypadDirRight(self) end
    focar(self, vizinha(self, 1, 0))
end

--[[
    A = confirmar, B = voltar/fechar.

    Reaproveita o mesmo caminho do clique do mouse (zimSelecionar), para
    controle e mouse nunca divergirem no que acontece ao escolher - inclusive
    no destravar do tempo quando o jogo esta pausado.
]]
function ISContextMenu:onJoypadDown(button)
    if not self:isZimMenu() then return V.onJoypadDown(self, button) end

    if button == Joypad.AButton then
        local s = fatiaAtual(self)

        --[[
            Rede de seguranca: A sem nada destacado FOCA, nao age.

            O prerender ja garante um destaque valido, mas se por qualquer
            caminho o `mouseOver` apontar para uma opcao sem fatia, o A antes
            simplesmente nao fazia nada -- e "o botao nao responde" e o pior
            retorno possivel para quem joga de controle, porque nao distingue
            de mod quebrado.

            Focar em vez de selecionar e deliberado: escolher sozinho uma opcao
            que o jogador nao viu destacada pode demolir uma parede. Um toque
            destaca, o seguinte confirma.
        ]]
        if not s then
            local lista = fatiasDeOpcao(self)
            if lista[1] then focar(self, lista[1]) end
            return
        end

        self:zimSelecionar(s)
        return
    end

    --[[
        PAGINA nos gatilhos de ombro.

        No controle a paginacao simplesmente nao existia, e a causa e estrutural:
        a lista apontavel vem de `fatiasDeOpcao`, que filtra `kind == "option"`.
        As setas de pagina sao `kind == "prev"` e `"more"` -- ficam de fora de
        proposito, porque no mouse elas sao alvos de clique e nao opcoes.
        Resultado: com o analogico nao havia para onde apontar para virar
        pagina.

        Poderia incluir as setas entre os alvos angulares, mas seria pior: elas
        ocupariam duas direcoes da roda que hoje sao opcoes de verdade, e o
        jogador teria que mirar numa seta em vez de simplesmente virar.

        LB/RB e o gesto certo, e o mesmo que qualquer jogo usa para abas. Nao
        disputa direcao com nada, funciona igual no D-pad e no analogico, e
        deixa a roda inteira livre para o conteudo.
    ]]
    if button == Joypad.LBumper or button == Joypad.RBumper then
        local dir = (button == Joypad.RBumper) and 1 or -1
        if L().flipPage(self, dir) then
            playClickSound()
            -- Pagina nova, fatias novas: o indice antigo nao existe mais. Zerar
            -- faz o prerender focar a primeira da pagina em vez de deixar a
            -- roda sem destaque nenhum.
            self.mouseOver = -1
        end
        return
    end

    if button == Joypad.BButton then
        if L().backOption(self) then
            self:zimHubAction()
        else
            self:closeAll()
        end
        return
    end

    return V.onJoypadDown(self, button)
end

function ISContextMenu:topmostMenuWithMouse(x, y)
    if not self:isZimMenu() then return V.topmostMenuWithMouse(self, x, y) end
    local ctx = getPlayerContextMenu(self.player)
    if not ctx then return nil end

    local function inside(m)
        if not m:isVisible() then return false end
        return x >= m.x and x < m.x + m.width and y >= m.y and y < m.y + m.height
    end

    local menu = nil
    if self == ctx and inside(self) then menu = self end
    for i = 1, #ctx.instanceMap do
        local m = ctx.instanceMap[i]
        if inside(m) then menu = m end
    end
    return menu
end

-- --------------------------------------------------------------- desenho

function ISContextMenu:prerender()
    if not self:isZimMenu() then
        -- O menu vertical de fabrica conta com a captura de mouse ligada. Se uma
        -- roda desligou antes, devolve antes de delegar.
        if self.zimConsuming == false then setConsume(self, true) end
        return V.prerender(self)
    end

    if displayCursorReminder == nil then
        displayCursorReminder = getCore():isDisplayCursor()
        getCore():setDisplayCursor(true)
    end
    if self:isEmpty() then
        self:setX(100000) -- estacionamento fora da tela, igual ao original
        return
    end

    self:addDefaultOptions()
    L().build(self)
    position(self)

    --[[
        FOCO INICIAL DO CONTROLE, aqui e nao no onGainJoypadFocus.

        O jogador de controle relatou nao conseguir selecionar nada na roda, e a
        causa e de ordem: `onGainJoypadFocus` dispara quando o menu RECEBE o
        foco, que acontece antes do primeiro prerender. Naquele instante
        `zimLayout` ainda e nil -- ele nasce no `L().build` logo acima -- entao
        `fatiasDeOpcao` devolvia lista vazia e nada era focado.

        O `mouseOver` ficava com o que o vanilla tivesse posto. E o vanilla
        aponta para o espaco de indices de `self.options`, que inclui as
        entradas padrao (`addDefaultOptions`) -- e essas nos TIRAMOS da roda de
        proposito: viram o clique no centro. Resultado: `mouseOver` apontando
        para uma opcao sem fatia nenhuma, `fatiaAtual` devolvendo nil, e o A
        sem nada para confirmar. Nao "as vezes": sempre, para todo controle.

        Aqui o layout ja existe. E a condicao nao e so a bandeira: se o
        `mouseOver` herdado nao corresponde a fatia alguma, corrigimos de
        qualquer jeito -- cobre tambem a volta de um submenu e a troca de
        pagina, onde o indice antigo pode nao existir mais.
    ]]
    if self.joyfocus then
        --[[
            APONTAR, e nao caminhar.

            A primeira versao navegava por vizinhanca: de onde estou, qual e a
            fatia mais proxima para cima/baixo/lado. Funciona numa lista e e
            ruim numa RODA -- num circulo "para cima" e ambiguo, duas fatias
            competem pelo mesmo gesto, e o resultado parece aleatorio. Era
            reclamacao justa: nada de interativo, so tentativa e erro.

            Agora o direcional aponta. Le-se o angulo do analogico e acende a
            fatia daquele angulo, que e como funciona a roda de armas de
            qualquer jogo -- e o unico modelo que um menu radial pode ter sem
            frustrar.

            `s.mid` ja existe: o layout grava nele o angulo de cada fatia a
            partir do centro (ZimPie_Layout, `s.mid = deg(atan2(my, mx))`). Os
            dois usam a mesma convencao de tela, com Y crescendo para baixo e o
            analogico devolvendo Y negativo para cima, entao os angulos casam
            direto, sem conversao.
        ]]
        -- Trava o andar enquanto a roda manda. `travarAndar ~= false` para a
        -- opcao nascer ligada mesmo em quem ja tem o .ini de uma versao antiga,
        -- onde a chave nem existe.
        if TheZims.CFG.travarAndar ~= false then
            travarMovimento(self.player, true)
        end

        local id = self.joyfocus.id
        local ax, ay = 0, 0
        pcall(function()
            -- Os DOIS analogicos. Quem joga espera usar o esquerdo; o direito
            -- fica porque e o que o vanilla usa em painel com foco, e aceitar
            -- ambos nao custa nada. Vence o que estiver mais deslocado.
            local mx, my = getJoypadMovementAxisX(id), getJoypadMovementAxisY(id)
            local rx, ry = getJoypadAimingAxisX(id),   getJoypadAimingAxisY(id)
            if (rx * rx + ry * ry) > (mx * mx + my * my) then ax, ay = rx, ry
            else ax, ay = mx, my end
        end)

        local forca = math.sqrt(ax * ax + ay * ay)

        --[[
            Zona morta alta de proposito.

            Analogico em repouso raramente devolve zero limpo, e um limite
            baixo faria a selecao tremer sozinha entre duas fatias vizinhas.
            0.5 exige um gesto deliberado -- e num menu radial o gesto E
            deliberado por natureza: voce aponta para o que quer.
        ]]
        if forca > 0.5 then
            local alvoAng = math.deg(math.atan2(ay, ax))
            local melhor, melhorDif = nil, nil
            for _, s in ipairs(fatiasDeOpcao(self)) do
                if s.mid then
                    -- Diferenca angular menor, atravessando o corte dos 180.
                    local d = math.abs((((s.mid - alvoAng) % 360) + 540) % 360 - 180)
                    if not melhorDif or d < melhorDif then melhor, melhorDif = s, d end
                end
            end
            --[[
                Refoca SEMPRE; o que muda e so o som.

                Reapontar todo quadro nao e desperdicio: as fatias sao objetos
                novos a cada build, e o render compara por identidade. Guardar
                a do quadro anterior deixa a roda sem nenhum destaque aceso.
            ]]
            if melhor then
                focar(self, melhor, melhor.index == self.mouseOver)
            end
        end

        --[[
            Garantir SEMPRE um destaque valido enquanto o controle manda.

            Sem isto a roda abria sem nada aceso e o A nao tinha o que
            confirmar -- e o jogador nao tem como adivinhar que precisa mexer o
            analogico primeiro. Tambem cobre a volta de submenu e a troca de
            pagina, onde o indice anterior pode nao existir mais.

            Fica FORA do `if forca`, para valer tambem com o direcional parado,
            que e o estado no instante em que o menu abre.
        ]]
        local atual = fatiaAtual(self)
        if atual then
            --[[
                Reaponta em silencio para a fatia DESTE quadro.

                `fatiaAtual` casa por indice, entao ela acha a fatia certa mesmo
                depois do rebuild -- mas se pararmos aqui, `zimHoverSlice`
                continua guardando o objeto do quadro anterior e o render nao
                acha destaque nenhum.

                Este e o caminho que roda com o analogico em REPOUSO, que e o
                estado logo depois de abrir o menu e a maior parte do tempo.
                Sem esta linha o destaque so apareceria enquanto o direcional
                estivesse empurrado.
            ]]
            focar(self, atual, true)
        else
            local lista = fatiasDeOpcao(self)
            if lista[1] then focar(self, lista[1]) end
        end
        self.zimJoyFocoPendente = nil
    end

    updateHover(self)

    local emCima = (self.zimHoverKind == "slice") or (self.zimHoverKind == "hub")
    setConsume(self, emCima)

    -- "Armado" so depois que todos os botoes forem soltos. Sem isso, o proprio
    -- clique direito que abriu o menu poderia fecha-lo no mesmo quadro.
    if not self.zimArmed then
        if not (isMouseButtonDown(0) or isMouseButtonDown(1)) then
            self.zimArmed = true
        end
    elseif not emCima and (isMouseButtonDown(0) or isMouseButtonDown(1)) then
        -- Apertou no vazio: fecha aqui. A captura ja esta desligada, entao o
        -- mesmo clique segue para o mundo e abre o menu do proximo objeto.
        self:closeAll()
        A().hide()
    end
end

function ISContextMenu:render()
    if not self:isZimMenu() then return V.render(self) end
    self.visibleCheck = true
    if self:isEmpty() then return end

    local C = TheZims.CFG
    local lay = L().get(self)
    local cx, cy = self.width / 2, self.height / 2
    local tm = getTextManager()

    -- Paleta do quadro: tirada do chapeu ou do cabelo do personagem, com
    -- cache por cor de origem dentro do proprio Theme.
    local player = getSpecificPlayer(self.player)
    local COL = TheZims.Theme and TheZims.Theme.current(player) or TheZims.COLORS

    -- Abertura com desaceleracao: a roda cresce e aparece.
    local t = 1
    if C.openMs > 0 and self.zimOpenAt then
        t = max(0, min(1, (getTimestampMs() - self.zimOpenAt) / C.openMs))
    end
    local ease = 1 - (1 - t) * (1 - t)
    local alpha = ease

    local hoverSlice = (self.zimHoverKind == "slice") and self.zimHoverSlice or nil
    local highlighted, showedTooltip = nil, false

    -- Dentro de um submenu o centro deixa de ser o rosto e passa a ser a opcao
    -- que abriu este nivel, igual a referencia. Serve de titulo e de botao de
    -- voltar ao mesmo tempo.
    local back = L().backOption(self)
    local emSubmenu = (back ~= nil)

    -- ---- fundo do miolo: solido no meio, sumindo nas bordas.
    -- Sem aro de proposito -- borda dura faz o miolo virar adesivo colado na
    -- tela; o esmaecido deixa ele nascer do cenario.
    --
    -- Vale em TODO nivel, nao so no inicial. Quem ocupa o centro muda (cabeca,
    -- foto da opcao, nome), mas o problema e o mesmo em qualquer um deles: sem
    -- este fundo a arte fica solta sobre o cenario do jogo e some quando cai
    -- num ponto claro.
    D().fadeDisc(self, cx, cy,
        C.innerRadius * C.hubSolidFrac, C.innerRadius * C.hubFadeFrac,
        fade(COL.hubBack, alpha), C.hubFadeBands)

    -- ---- fatia fraca ligando o centro a pilula em foco (desligada por padrao)
    -- O raio externo sai da propria pilula: com o arranjo em coluna nao existe
    -- mais um raio unico para todas, e `angularSlack` deixou de existir junto
    -- com o hit-test angular.
    if C.showHoverWedge and hoverSlice then
        local alcance = math.max(math.abs(hoverSlice.px), math.abs(hoverSlice.px + hoverSlice.pw))
        D().wedge(self, cx, cy, C.innerRadius, alcance,
            hoverSlice.a0, hoverSlice.a1, fade(COL.hoverWedge, alpha))
    end

    self.currentOptionRect = {
        x = self.x + cx - C.innerRadius, y = self.y + cy - C.innerRadius,
        width = C.innerRadius * 2, height = C.innerRadius * 2,
    }

    -- ---- pilulas
    for _, s in ipairs(lay.slices) do
        local hovered = (s == hoverSlice)

        -- A pilula em foco mostra o nome inteiro. Recalculada numa copia, para
        -- o hit-test continuar usando a geometria estavel montada no layout.
        local geo = s
        if hovered and s.fullText ~= s.text then
            geo = { kind = s.kind }
            -- Recalculada com o mesmo estado de orbe, senao a pilula em foco
            -- mudaria de largura por outro motivo alem do texto.
            L().place(geo, s.fullText, s.fullText, s.lado, s.py + s.ph / 2,
                math.abs(s.lado > 0 and s.px or (s.px + s.pw)), s.temOrbe)
        end

        local fill, textCol, orbCol, hiCol
        if s.kind ~= "option" then
            -- Navegacao (voltar / Mais...): tom mais escuro, para o olho
            -- separar na hora "mudar de pagina" de "fazer alguma coisa".
            fill = hovered and (COL.pillParentHover or COL.pillHover) or (COL.pillParent or COL.pill)
            hiCol = COL.pillParentHi or COL.pillHi
            orbCol = hovered and COL.orbHover or COL.orb
            textCol = COL.text
        else
            fill, textCol, orbCol, hiCol = optionColors(COL, s.opt, hovered)
        end

        local grow = hovered and C.pillHoverGrow or 0
        local px, py = cx + geo.px - grow, cy + geo.py - grow
        local pw, ph = geo.pw + grow * 2, geo.ph + grow * 2

        D().pillOutlined(self, px, py, pw, ph,
            fade(fill, alpha), hiCol and fade(hiCol, alpha) or nil,
            fade(COL.pillBorder, alpha), 1)

        -- Orbe SO quando ha icone para por dentro. Circulo vazio repetido em
        -- toda opcao vira ruido, e sem ele a pilula fica limpa - o texto ja
        -- nasce centrado porque o layout nao reservou o espaco.
        if s.temOrbe then
            -- Sem o brilho interno quando ha icone: os dois disputavam o mesmo
            -- espaco e o simbolo ficava lavado. O orbe aqui e moldura, nao
            -- enfeite.
            D().orb(self, cx + geo.orbX, cy + geo.orbY, geo.orbR,
                fade(orbCol, alpha), fade(COL.pillBorder, alpha), nil)
            local isz = geo.orbR * (C.iconScale or 1.55)
            pcall(function()
                self:renderOptionTextureOrColor(s.opt,
                    cx + geo.orbX - isz / 2, cy + geo.orbY - isz / 2, isz, isz)
            end)
        end

        self:drawText(geo.text, cx + geo.textX, cy + geo.textY,
            textCol.r, textCol.g, textCol.b, textCol.a * alpha, C.labelFont)

        if hovered then
            self.currentOptionRect = {
                x = self.x + px, y = self.y + py, width = pw, height = ph,
            }
            if s.kind == "option" then
                highlighted = s.opt
                if s.opt.toolTip and not self:isMouseOut() then
                    self:showTooltip(s.opt)
                    showedTooltip = true
                end
            end
        end
    end

    -- ---- a cabeca do personagem, por cima do miolo. Ela passa da parte
    -- solida do fundo e cai dentro do esmaecido, que e o efeito procurado.
    --[[
        O CENTRO CONTA EM QUE NIVEL VOCE ESTA.

          menu inicial  -> a cabeca do personagem
          submenu       -> a FOTO da opcao em que voce clicou
          sem foto      -> o nome dela sobre o fundo escurecido

        A foto e a mesma que ja aparece no orbe da opcao, desenhada pelo
        `renderOptionTextureOrColor` do proprio ISContextMenu -- entao ela cobre
        de graca tudo que o jogo e os outros mods sabem ilustrar: sprite de
        objeto, icone de item, cor chapada.

        Trocar a cabeca pela foto e o que faz parecer selecao: voce clicou na
        janela, a janela vai para o meio e as opcoes dela ficam em volta. A
        cabeca no centro de um submenu nao dizia nada -- o personagem nao e o
        assunto ali.
    ]]
    --[[
        A opcao que abriu este submenu -- a de verdade, com a foto.

        NAO da para usar o `back` aqui, e essa foi a pegadinha. O `back` vem de
        `isDefaultOption`, e essas entradas sao SINTETICAS: o
        `ISContextMenu:addDefaultOptions` monta cada uma com

            option = self:addOptionOnTop(option.name, ...)

        ou seja, copia so o NOME. iconTexture, itemForTexture e color ficam para
        tras. Por isso o centro acertava o texto ("Janela", "Poltrona Verde") e
        nunca achava foto nenhuma.

        A opcao original mora no menu PAI, e o proprio jogo sabe onde:
        `getIndexForSubMenu` devolve o indice da opcao cujo submenu e este.
    ]]
    local paiReal = nil
    if emSubmenu then
        local pai = self.parent
        if pai and pai.getIndexForSubMenu then
            local idx = pai:getIndexForSubMenu(self)
            if idx and idx ~= -1 then paiReal = pai.options[idx] end
        end
    end

    local fotoDoPai = paiReal and
        (paiReal.iconTexture or paiReal.itemForTexture or paiReal.color) and true or false

    if emSubmenu then
        -- Em submenu a cabeca nunca aparece, com foto ou sem.
        A().hide()
    end

    if fotoDoPai then
        --[[
            Sem moldura e sem orbe: o esmaecido do miolo ja separa a foto do
            fundo, e um anel em volta faria a janela parecer mais um botao
            clicavel em vez do assunto da roda.

            1.5x o innerRadius e o maior tamanho que ainda cabe na parte solida
            do miolo. Acima disso a foto invade o esmaecido e as pontas somem.
        ]]
        local isz = C.innerRadius * 1.5
        pcall(function()
            self:renderOptionTextureOrColor(paiReal, cx - isz / 2, cy - isz / 2, isz, isz)
        end)

    elseif emSubmenu then
        -- Sem foto: o nome e a unica coisa que diz onde voce esta, entao fica a
        -- pilula escura -- tom diferente das opcoes em volta, para separar o que
        -- ja foi escolhido do que ainda da para escolher.
        local hubHover = (self.zimHoverKind == "hub")
        local nome = D().fitText(C.labelFont, back.name or "", C.pillRadius * 1.15)
        local tw = tm:MeasureStringX(C.labelFont, nome)
        local fhc = tm:getFontHeight(C.labelFont)
        local ph = fhc + C.pillPadY * 2 + 2
        local pw = tw + C.pillPadX * 2
        D().pillOutlined(self, cx - pw / 2, cy - ph / 2, pw, ph,
            fade(hubHover and (COL.pillParentHover or COL.pillHover) or (COL.pillParent or COL.pill), alpha),
            fade(COL.pillParentHi or COL.pillHi, alpha),
            fade(COL.pillBorder, alpha), 1)
        self:drawText(nome, cx - tw / 2, cy - fhc / 2,
            COL.text.r * 0.82, COL.text.g * 0.82, COL.text.b * 0.82,
            COL.text.a * alpha, C.labelFont)

    elseif C.showAvatar and player and alpha > 0.5 then
        -- Menu inicial: o personagem. Ele passa da parte solida do miolo e cai
        -- dentro do esmaecido, que e o efeito procurado.
        A().showAt(player, self.x + cx, self.y + cy,
            C.innerRadius * 2 * (C.avatarScale or 1), self)

        --[[
            Para onde ele se inclina. Com o cursor solto, segue o mouse; assim
            que encosta numa pilula, trava no angulo daquela opcao -- e o que a
            referencia faz.

            Travar no `mid` da fatia, e nao no mouse, importa: a pilula e larga,
            e seguir o cursor dentro dela faria a cabeca oscilar enquanto voce
            so desliza sobre o mesmo item.
        ]]
        local olhar = nil
        if hoverSlice then
            olhar = hoverSlice.mid
        elseif self.zimHoverKind ~= "hub" then
            local dx = getMouseX() - (self.x + cx)
            local dy = getMouseY() - (self.y + cy)
            if dx * dx + dy * dy > 16 then
                olhar = math.deg(math.atan2(dy, dx))
            end
        end
        A().lookAt(olhar)
    end

    -- Mantem os contratos de destaque/tooltip que outros mods esperam.
    self:checkHighlightedOption(highlighted)
    if not showedTooltip and self.player == 0 then
        self:hideToolTip()
    end
end

--[[
    Ultima linha do arquivo, e portanto a unica que roda no CARREGAMENTO com
    `TheZims` possivelmente ainda nil. Sem a guarda, ela sozinha recriaria o
    defeito que este arquivo acabou de consertar -- e de um jeito pior, porque
    estouraria depois de os doze substitutos ja estarem instalados.

    As demais linhas com `TheZims.` acima rodam todas dentro de metodos que so
    executam depois do portao do isZimMenu, quando o jogo inteiro ja carregou e
    a base existe se estiver instalada.
]]
if TheZims and TheZims.log then TheZims.log("ISContextMenu patched") end
