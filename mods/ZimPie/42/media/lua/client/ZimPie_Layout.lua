--[[
    Layout: transforma a lista de opcoes do menu em pilulas posicionadas, e faz
    o caminho inverso, do mouse para a opcao.

    Duas coisas saem de self.options antes do layout:

      * entradas isDefaultOption. No modo "menu de contexto unico" o jogo poe
        uma entrada de volta por nivel de ancestral (ISContextMenu:addDefaultOptions).
        Elas nao entram na roda; viram o clique no centro.
      * tudo que passa de maxSlices, que vai para as paginas seguintes.
]]

--[[
    NAO ha saida antecipada aqui, e isso e proposital.

    Havia: `if not TheZims then return end`. Parecia inofensivo -- sem a base
    nao ha o que posicionar -- mas `TheZims` e uma global que so passa a existir
    depois que o Lua do The Zims roda, e a ordem entre MODS segue a lista do
    jogador, nao o alfabeto. Carregando este arquivo antes da base, ele saia
    sem nunca definir `ZimPie.Layout`.

    E ai o estrago era maior que "o mod some em silencio": o ZimPie_Patch,
    quando arrumado para nao desistir, instala os substitutos e chama
    `ZimPie.Layout` na hora de desenhar. Um Layout nil ali e erro por quadro
    com a roda aberta, nao ausencia limpa.

    Este arquivo so define uma tabela de funcoes. Nada aqui EXECUTA nada da
    base no carregamento -- as funcoes usam TheZims por dentro, e todas elas so
    sao chamadas depois do portao do isZimMenu, com o jogo inteiro carregado.
    Definir sempre e o comportamento correto e o mais barato.
]]

ZimPie = ZimPie or {}
local Layout = {}
ZimPie.Layout = Layout

local atan2, sqrt, floor, ceil, cos, sin, rad = math.atan2, math.sqrt, math.floor, math.ceil, math.cos, math.sin, math.rad

--[[
    Lado do elemento quadrado que contem a roda.

    Isto e medido do conteudo real, nao do pior caso. O elemento captura mouse
    em todo o seu retangulo, entao um quadrado de "cabe qualquer coisa" (~616px)
    engolia o clique direito em metade da tela e o jogador nao conseguia abrir o
    menu em outro objeto.

    Fica SIMETRICO de proposito - o maior alcance em qualquer direcao, dobrado.
    Uma caixa justa mas assimetrica deslocaria o centro do elemento para longe do
    centro da roda, e todo o resto (hit-test, render, avatar) assume
    centro = width/2.
]]
function Layout.boxSize(menu)
    local c = TheZims.CFG
    local lay = menu and menu.zimLayout
    if lay and lay.extent then
        return ceil(lay.extent + 10) * 2
    end
    -- Antes do primeiro build ainda nao ha pilulas medidas; limite generoso.
    local reach = c.pillRadius + c.labelMaxWidth + c.pillPadX * 2 + 48
    return ceil(reach) * 2
end

local function partition(menu)
    local real, back = {}, {}
    for i, opt in ipairs(menu.options) do
        if opt.isDefaultOption then
            back[#back + 1] = opt
        else
            real[#real + 1] = { opt = opt, index = i }
        end
    end
    return real, back
end

--[[
    Geometria de uma pilula, em offsets a partir do centro da roda.

    `lado`  -1 coluna da esquerda, +1 coluna da direita, 0 centralizada (o
            "Mais..." embaixo).
    `iy`    altura do centro da pilula, ja calculada por quem chama.

    A pilula encosta a borda interna na coluna (a pillRadius do centro) e cresce
    para fora. As colunas nunca invadem o meio, entao a cabeca fica sempre livre.
]]
--[[
    `ancoraX` e a distancia do centro ate a borda interna da pilula. No modo
    colunas e sempre pillRadius; na roda varia com o angulo, com um piso.

    `comOrbe` decide se a pilula reserva espaco para o circulo. So vale a pena
    quando ha icone para por dentro dele: orbe vazio nao informa nada e vira
    ruido repetido em toda opcao. Sem orbe, o texto fica centrado na pilula
    inteira, com a mesma margem dos dois lados.
]]
local function placePill(s, text, full, lado, iy, ancoraX, comOrbe)
    local c = TheZims.CFG
    local tm = getTextManager()
    local fh = tm:getFontHeight(c.labelFont)
    ancoraX = ancoraX or c.pillRadius

    local ph = fh + c.pillPadY * 2
    local orbR = ph * c.orbScale
    local tw = tm:MeasureStringX(c.labelFont, text)

    --[[
        O orbe fica a cavalo na ponta da pilula voltada para o centro: metade
        dele entra na pilula, metade sobra para fora. A parte que entra ocupa
        1.5 * orbR contados daquela ponta, e o texto mora no que sobra - uma
        margem de cada lado, exatamente.
    ]]
    local espacoOrbe = comOrbe and (orbR * 1.5) or 0
    local pw = tw + c.pillPadX * 2 + espacoOrbe

    local px
    if lado > 0 then
        px = ancoraX
    elseif lado < 0 then
        px = -ancoraX - pw
    else
        px = -pw / 2
    end

    local paraEsquerda = (lado < 0)

    s.text = text
    s.fullText = full
    s.lado = lado
    s.pw, s.ph = pw, ph
    s.px, s.py = px, iy - ph / 2
    s.temOrbe = comOrbe and true or false
    s.orbR = orbR
    -- Orbe na ponta voltada para o centro.
    s.orbX = paraEsquerda and (px + pw - orbR * 0.5) or (px + orbR * 0.5)
    s.orbY = iy
    -- Com orbe o texto se afasta dele; sem orbe fica centrado na pilula.
    s.textX = (paraEsquerda or not comOrbe) and (px + c.pillPadX)
        or (px + espacoOrbe + c.pillPadX)
    s.textY = iy - fh / 2

    -- Angulo do centro da pilula. Nao posiciona nada - serve para a cabeca 3D
    -- saber para onde virar e para a fatia opcional de direcao.
    local mx, my = px + pw / 2, iy
    s.mid = math.deg(atan2(my, mx))
    s.a0, s.a1 = s.mid - 20, s.mid + 20
end

-- Exposto para o render remontar a pilula em foco com o nome inteiro, sem
-- mexer na geometria que o hit-test ja esta usando.
Layout.place = placePill

--[[
    Monta (ou remonta) menu.zimLayout para a pagina atual.

    O arranjo e o do The Sims, e nao por estilo: posicao FIXA em coluna nao tem
    como sobrepor. A distribuicao anterior espalhava as opcoes por angulo no
    circulo inteiro, e com muitas opcoes as pilulas vizinhas caiam em alturas
    parecidas e se cruzavam - era o "bugado" que apareceu nos comentarios.

        [ pagina anterior / voltar ]
      opcao 5            opcao 1
      opcao 6   CABECA   opcao 2
      opcao 7            opcao 3
      opcao 8            opcao 4
        [ Mais... ]

    Quatro por lado, oito por pagina. Topo e base sao navegacao, nunca opcao:
    o topo volta (de pagina ou de submenu) e a base avanca a pagina. Assim a
    quantidade de opcoes na tela e sempre a mesma e o menu nunca muda de forma.
]]
function Layout.build(menu)
    local c = TheZims.CFG
    local real, back = partition(menu)
    local porLado = c.slotsPerSide or 4
    local perPage = porLado * 2

    local n = #real
    local pageCount = math.max(1, ceil(n / perPage))
    local page = menu.zimPage or 1
    if page > pageCount then page = pageCount end
    if page < 1 then page = 1 end
    menu.zimPage = page

    local first = (page - 1) * perPage + 1
    local last = math.min(n, page * perPage)
    local visiveis = {}
    for i = first, last do
        visiveis[#visiveis + 1] = { opt = real[i].opt, index = real[i].index }
    end

    --[[
        Duas regras juntas, e sao elas que dao o equilibrio:

        1. LADO POR PARIDADE. Impares a esquerda, pares a direita - ou seja, a
           ordem de leitura anda por linha, nao por coluna:

               opcao 1            opcao 2
               opcao 3   CABECA   opcao 4

        2. CADA COLUNA CENTRADA POR CONTA PROPRIA. E o que produz o
           escalonamento quando o total e impar, em vez de deixar um buraco no
           fim de uma coluna. Com 5 opcoes a esquerda tem 3 e a direita 2, e as
           duas ficam centradas na cabeca:

               opcao 1
               opcao 3   CABECA   opcao 2
               opcao 5            opcao 4

        Com 2 opcoes cada coluna tem uma so, ambas na altura da cabeca.
    ]]
    local tm = getTextManager()
    local alturaLinha = tm:getFontHeight(c.labelFont) + c.pillPadY * 2 + (c.rowGap or 20)
    local slices = {}
    local linhas

    local function porPill(v, lado, iy, ancoraX)
        local s = { kind = "option", opt = v.opt, index = v.index }
        local nome = v.opt.name or ""
        -- So reserva o circulo se houver mesmo o que desenhar dentro dele.
        local temIcone = (v.opt.iconTexture or v.opt.itemForTexture or v.opt.color) and true or false
        placePill(s, TheZims.Draw.fitText(c.labelFont, nome, c.labelMaxWidth), nome,
            lado, iy, ancoraX, temIcone)
        slices[#slices + 1] = s
    end

    --[[
        Pagina cheia cai para coluna, mesmo no modo roda.

        O arco e bonito com poucas opcoes, mas com as oito ele fica apertado:
        os angulos dos extremos recuam ate o piso e as pilulas acabam quase
        alinhadas de qualquer jeito - so que sem o respiro regular que a coluna
        da. Entao a roda vale ate sete, e a oitava opcao muda o arranjo.

        Como a paginacao enche as paginas em ordem, na pratica isso significa:
        paginas cheias em coluna, a ultima (parcial) em roda.
    ]]
    local emColunas = (c.layout == "colunas") or (#visiveis >= perPage)

    if emColunas then
        --[[
            Duas colunas retas. Lado por paridade (impares a esquerda), e cada
            coluna centrada por conta propria - e isso que escalona quando o
            total e impar em vez de deixar um buraco no fim de uma coluna.
        ]]
        local esq, dir = {}, {}
        for i, v in ipairs(visiveis) do
            if i % 2 == 1 then esq[#esq + 1] = v else dir[#dir + 1] = v end
        end
        linhas = math.max(#esq, #dir)
        for k, v in ipairs(esq) do porPill(v, -1, (k - (#esq + 1) / 2) * alturaLinha) end
        for k, v in ipairs(dir) do porPill(v, 1, (k - (#dir + 1) / 2) * alturaLinha) end
    else
        --[[
            Roda: arco em volta da cabeca, como no The Sims.

            Os angulos saem de TheZims.ANGULOS, tabelados por quantidade. Nao e
            360/N porque a divisao uniforme punha vizinhas em alturas quase
            iguais e elas se cruzavam.

            O recuo horizontal tem PISO. Sem ele, uma pilula a 60 graus recuaria
            so cos(60)*raio - menos que o raio da cabeca - e nasceria em cima do
            rosto. Com o piso, a roda vira um arco: bem aberta na altura dos
            olhos, mais fechada em cima e embaixo. E o formato do pie menu.
        ]]
        local angulos = TheZims.ANGULOS[#visiveis]
        local minX = c.innerRadius + (c.headClearance or 14)
        -- Elipse: raio vertical menor que o horizontal, para a altura bater com
        -- a do modo coluna e a troca de arranjo nao dar salto.
        local raioY = c.pillRadius * (c.pillRadiusYFactor or 0.75)
        local maiorY = 0
        for i, v in ipairs(visiveis) do
            local a = rad(angulos[i])
            local cx0, sy0 = cos(a), sin(a)
            local iy = sy0 * raioY
            local lado = (cx0 >= 0) and 1 or -1
            local ancora = math.max(math.abs(cx0) * c.pillRadius, minX)
            porPill(v, lado, iy, ancora)
            maiorY = math.max(maiorY, math.abs(iy))
        end
        -- Converte o alcance vertical em "linhas" para a navegacao usar a mesma
        -- conta de altura dos dois modos.
        linhas = (maiorY * 2) / alturaLinha
    end

    --[[
        Navegacao acima e abaixo da cabeca.

        A altura sai de fora da coluna mais longa, com um piso que garante folga
        sobre a propria cabeca. Sem esse piso, um menu de duas opcoes (uma linha
        so) jogava a navegacao praticamente em cima do rosto.

        SO paginacao entra aqui. "Voltar" nao: dentro de um submenu quem faz
        esse papel e a pilula escura do centro, e ter as duas era pedir para o
        jogador clicar na errada.
    ]]
    -- `navGap` afasta as duas da roda. Coladas nas opcoes elas competiam pela
    -- atencao; separadas, lem como uma barra a parte.
    local navY = math.max(
        ((linhas + 1) / 2) * alturaLinha,
        c.innerRadius + alturaLinha * 0.9
    ) + (c.navGap or 16)

    --[[
        Sem volta circular: cada seta so aparece quando existe para onde ir.

        Na ultima pagina o "Mais..." oferecia voltar para a 1/3, o que le como
        avancar e faz o jogador achar que perdeu opcoes. Na primeira, o
        "Anterior" era igualmente sem sentido.
    ]]
    if page > 1 then
        local rot = getText("IGUI_TheZims_Prev") .. " " .. (page - 1) .. "/" .. pageCount
        local s = { kind = "prev", label = rot }
        placePill(s, TheZims.Draw.fitText(c.labelFont, rot, c.labelMaxWidth), rot, 0, -navY, nil, false)
        slices[#slices + 1] = s
    end
    if page < pageCount then
        local rot = getText("IGUI_TheZims_More") .. " " .. (page + 1) .. "/" .. pageCount
        local s = { kind = "more", label = rot }
        placePill(s, TheZims.Draw.fitText(c.labelFont, rot, c.labelMaxWidth), rot, 0, navY, nil, false)
        slices[#slices + 1] = s
    end

    -- Alcance real do conteudo, a partir do centro.
    local extent = c.pillRadius + 20
    for _, s in ipairs(slices) do
        extent = math.max(extent,
            math.abs(s.px), math.abs(s.px + s.pw),
            math.abs(s.py), math.abs(s.py + s.ph))
    end

    --[[
        Menor distancia vertical entre pilulas do MESMO lado.

        E daqui que sai a tolerancia do clique, nao de alturaLinha: na roda as
        pilulas ficam mais juntas que uma linha de coluna, e usar a altura da
        coluna faria as faixas de duas opcoes vizinhas se sobreporem - clicar
        entre elas acertaria a errada.
    ]]
    local menorGap = alturaLinha
    for _, a in ipairs(slices) do
        for _, b in ipairs(slices) do
            if a ~= b and a.lado == b.lado and a.lado ~= 0 then
                local d = math.abs((a.py + a.ph / 2) - (b.py + b.ph / 2))
                if d > 0.5 and d < menorGap then menorGap = d end
            end
        end
    end

    menu.zimLayout = {
        slices = slices, back = back,
        page = page, pageCount = pageCount, paged = (pageCount > 1),
        total = n, extent = extent, alturaLinha = alturaLinha,
        menorGap = menorGap,
    }
    return menu.zimLayout
end

function Layout.get(menu)
    return menu.zimLayout or Layout.build(menu)
end

--[[
    Testa um ponto em coordenadas locais do elemento.

    Devolve:
      "slice", tabelaDaFatia
      "hub",   nil   - dentro do miolo (cabeca)
      "out",   nil   - fora da roda; quem chama trata como cancelar

    A ordem importa. Primeiro o retangulo exato da pilula, para o clique bater
    onde o olho ve. Depois o anel tolerante entre a cabeca e um pouco alem das
    pilulas, resolvido por angulo - e isso que da a mira facil do menu radial,
    sem transformar a tela inteira em area clicavel.
]]
function Layout.hitTest(menu, mx, my)
    local c = TheZims.CFG
    local lay = Layout.get(menu)

    local cx, cy = menu.width / 2, menu.height / 2
    local dx, dy = mx - cx, my - cy

    -- 1. Retangulo exato: o clique bate onde o olho ve.
    for _, s in ipairs(lay.slices) do
        if dx >= s.px and dx <= s.px + s.pw and dy >= s.py and dy <= s.py + s.ph then
            return "slice", s
        end
    end

    if sqrt(dx * dx + dy * dy) < c.innerRadius then
        return "hub", nil
    end

    --[[
        2. Faixa da linha, generosa.

        Com o arranjo em coluna nao existe mais setor angular, entao a
        tolerancia vira geometrica: a faixa horizontal da pilula cresce para
        fora ate `hitPadding` e na vertical ate a metade do espaco entre linhas.

        Cresce so PARA FORA de proposito. Se crescesse para dentro, as duas
        colunas se encontrariam no meio e o clique na cabeca viraria uma opcao.
    ]]
    -- Metade do menor espacamento real: nunca invade a faixa da vizinha.
    local folgaY = (lay.menorGap or lay.alturaLinha or 28) / 2
    local pad = c.hitPadding or 80
    for _, s in ipairs(lay.slices) do
        local x0, x1 = s.px, s.px + s.pw
        if s.lado > 0 then x1 = x1 + pad
        elseif s.lado < 0 then x0 = x0 - pad
        else x0, x1 = x0 - pad * 0.5, x1 + pad * 0.5 end

        local yc = s.py + s.ph / 2
        if dx >= x0 and dx <= x1 and math.abs(dy - yc) <= folgaY then
            return "slice", s
        end
    end

    return "out", nil
end

--- A entrada de volta que o centro aciona: o pai imediato. addDefaultOptions
--- empilha cada ancestral no topo em sequencia, entao o ancestral mais distante
--- fica em primeiro e o pai imediato em ultimo.
function Layout.backOption(menu)
    local lay = Layout.get(menu)
    return lay.back[#lay.back]
end

--- Muda de pagina. Para nos extremos em vez de dar a volta, pelo mesmo motivo
--- das setas: passar da ultima para a primeira le como avancar.
function Layout.flipPage(menu, delta)
    local lay = Layout.get(menu)
    if not lay.paged then return false end
    local p = math.max(1, math.min(lay.pageCount, lay.page + delta))
    if p == lay.page then return false end
    menu.zimPage = p
    Layout.build(menu)
    return true
end
