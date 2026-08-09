--[[
    Primitivas de desenho.

    A camada de UI do PZ nao tem circulo nem poligono livre, mas
    ISUIElement:drawPolygon aceita quatro vertices soltos:

        drawPolygon(tex, x1,y1, x2,y2, x3,y3, x4,y4, r,g,b,a)

    Com isso da para montar setor de anel (tira de quads ao longo do arco),
    disco, e a pilula do The Sims 2 (retangulo + duas tampas redondas).

    Coordenadas sao LOCAIS ao elemento, igual drawRect/drawText.
]]

TheZims = TheZims or {}
local Draw = {}
TheZims.Draw = Draw

local cos, sin, rad, max, min, floor = math.cos, math.sin, math.rad, math.max, math.min, math.floor

-- drawPolygon lida melhor com textura real do que com nil, e Texture.getWhite()
-- e o que o proprio jogo usa para preenchimento solido
-- (ver ISContextMenu:addColorBoxOption).
local whiteTex = nil
local function white()
    if whiteTex == nil then
        local ok, tex = pcall(function() return Texture.getWhite() end)
        whiteTex = ok and tex or false
    end
    if whiteTex == false then return nil end
    return whiteTex
end

--- Setor de anel preenchido, de a0 a a1 (graus, horario, 0 = direita).
function Draw.wedge(ui, cx, cy, r0, r1, a0, a1, col)
    if a1 <= a0 or r1 <= r0 then return end

    -- Subdivide por comprimento de arco, nao por angulo: um ponto de 2px e um
    -- anel de 130px ficam ambos lisos o suficiente e nada alem disso.
    local arcLen = rad(a1 - a0) * r1
    local segs = max(2, min(64, floor(arcLen / TheZims.CFG.pixelsPerSegment + 0.5)))
    local step = (a1 - a0) / segs
    local tex = white()

    for i = 0, segs - 1 do
        local t0 = rad(a0 + step * i)
        local t1 = rad(a0 + step * (i + 1))
        local c0, s0 = cos(t0), sin(t0)
        local c1, s1 = cos(t1), sin(t1)

        ui:drawPolygon(tex,
            cx + c0 * r0, cy + s0 * r0,
            cx + c0 * r1, cy + s0 * r1,
            cx + c1 * r1, cy + s1 * r1,
            cx + c1 * r0, cy + s1 * r0,
            col.r, col.g, col.b, col.a)
    end
end

function Draw.disc(ui, cx, cy, r, col)
    Draw.wedge(ui, cx, cy, 0, r, 0, 360, col)
end

function Draw.ring(ui, cx, cy, r, thickness, col)
    Draw.wedge(ui, cx, cy, r - thickness, r, 0, 360, col)
end

--- Disco solido ate rSolid que vai sumindo ate rFade, sem aro nenhum.
--- E o fundo da cabeca: um aro desenhado deixa uma borda dura e transforma o
--- avatar num adesivo colado na tela; o esmaecido faz ele nascer do cenario.
--- Sem gradiente por vertice no drawPolygon, o degrade sai como aneis finos.
--- As faixas se sobrepoem meio pixel, senao aparece costura entre elas.
function Draw.fadeDisc(ui, cx, cy, rSolid, rFade, col, bands)
    bands = bands or 14
    Draw.disc(ui, cx, cy, rSolid, col)
    if rFade <= rSolid then return end

    local step = (rFade - rSolid) / bands
    for i = 0, bands - 1 do
        local r0 = rSolid + step * i
        local a = col.a * (1 - (i + 0.5) / bands)
        Draw.wedge(ui, cx, cy, r0, r0 + step + 0.5, 0, 360,
            { r = col.r, g = col.g, b = col.b, a = a })
    end
end

--- Pilula: retangulo com as duas pontas arredondadas, como os botoes do
--- menu do The Sims 2. `hi` e a faixa de brilho do terco superior; pode ser nil.
function Draw.pill(ui, x, y, w, h, col, hi)
    if h <= 0 then return end
    if w < h then w = h end
    local r = h / 2

    Draw.disc(ui, x + r, y + r, r, col)
    Draw.disc(ui, x + w - r, y + r, r, col)
    ui:drawRect(x + r, y, w - h, h, col.a, col.r, col.g, col.b)

    --[[
        Brilho do terco superior, seguindo o CONTORNO da pilula.

        A versao anterior era um drawRect de x+r ate x+w-r, ou seja, so o corpo
        reto - o brilho batia numa parede vertical e as duas tampas ficavam
        sem ele. Aparecia como um retangulo claro flutuando no meio.

        Aqui cada linha horizontal e recortada na largura real da pilula
        naquela altura: dentro das tampas a meia-largura e sqrt(r^2 - dy^2), o
        que faz o brilho acompanhar a curva ate a ponta.
    ]]
    if hi then
        local yc = y + r
        local ate = y + h * 0.38
        local py = y + 1
        while py < ate do
            local dy = yc - py
            local dx = (math.abs(dy) < r) and math.sqrt(r * r - dy * dy) or 0
            local x0 = x + r - dx
            local x1 = x + w - r + dx
            ui:drawRect(x0, py, x1 - x0, 1, hi.a, hi.r, hi.g, hi.b)
            py = py + 1
        end
    end
end

--- Pilula com contorno: desenha uma maior atras, na cor da borda.
function Draw.pillOutlined(ui, x, y, w, h, fill, hi, border, bw)
    bw = bw or 1
    if border then
        Draw.pill(ui, x - bw, y - bw, w + bw * 2, h + bw * 2, border, nil)
    end
    Draw.pill(ui, x, y, w, h, fill, hi)
end

--- Orbe do The Sims 2: disco com contorno e um brilho deslocado para cima.
function Draw.orb(ui, cx, cy, r, col, border, hi)
    if border then Draw.disc(ui, cx, cy, r + 1, border) end
    Draw.disc(ui, cx, cy, r, col)
    if hi then Draw.disc(ui, cx, cy - r * 0.28, r * 0.42, hi) end
end

--- Corta o texto para caber em maxW com reticencias, sem quebrar sequencia
--- UTF-8. Nome de opcao em portugues e cheio de caractere multibyte e um corte
--- por byte deixaria lixo no fim.
function Draw.fitText(font, text, maxW)
    local tm = getTextManager()
    if not text or text == "" then return "" end
    if tm:MeasureStringX(font, text) <= maxW then return text end

    local ell = "..."
    local lo, hi = 0, #text
    while lo < hi do
        local mid = floor((lo + hi + 1) / 2)
        if tm:MeasureStringX(font, text:sub(1, mid) .. ell) <= maxW then
            lo = mid
        else
            hi = mid - 1
        end
    end

    -- Recua qualquer sequencia UTF-8 partida: primeiro os bytes de continuacao
    -- (0x80..0xBF), depois o byte lider que abriu a sequencia cortada.
    while lo > 0 do
        local b = text:byte(lo)
        if b and b >= 0x80 and b < 0xC0 then lo = lo - 1 else break end
    end
    if lo > 0 then
        local b = text:byte(lo)
        if b and b >= 0xC0 then lo = lo - 1 end
    end

    if lo <= 0 then return ell end
    return text:sub(1, lo) .. ell
end

-- ==================================================================
--  Painel estilo The Sims 2
-- ==================================================================

--[[
    Retangulo de cantos arredondados, com raio a nossa escolha.

    Nao da para usar Draw.pill aqui: a pilula sempre arredonda pela METADE da
    altura, o que num painel de 400px de altura devolveria um estadio, nao um
    painel. Aqui o raio e independente do tamanho.

    Montagem: tres retangulos formando uma cruz, mais um quarto de disco em cada
    canto. A cruz evita costura no meio, que apareceria se fossem dois
    retangulos sobrepostos.
]]
function Draw.roundRect(ui, x, y, w, h, r, col)
    if w <= 0 or h <= 0 then return end
    r = min(r, min(w, h) / 2)
    if r <= 0 then
        ui:drawRect(x, y, w, h, col.a, col.r, col.g, col.b)
        return
    end

    ui:drawRect(x + r, y,         w - r * 2, h,         col.a, col.r, col.g, col.b)
    ui:drawRect(x,     y + r,     r,         h - r * 2, col.a, col.r, col.g, col.b)
    ui:drawRect(x + w - r, y + r, r,         h - r * 2, col.a, col.r, col.g, col.b)

    -- 0 grau aponta para a direita e o angulo cresce no sentido do y crescente,
    -- que na tela e para baixo. Dai a ordem dos quadrantes abaixo.
    Draw.wedge(ui, x + r,     y + r,     0, r, 180, 270, col)
    Draw.wedge(ui, x + w - r, y + r,     0, r, 270, 360, col)
    Draw.wedge(ui, x + w - r, y + h - r, 0, r,   0,  90, col)
    Draw.wedge(ui, x + r,     y + h - r, 0, r,  90, 180, col)
end

--[[
    A moldura do painel.

    Tres camadas, de fora para dentro: borda, corpo e brilho de topo. E o mesmo
    truque da pilula, so que num raio fixo -- o que da a leitura de "placa
    moldada" da interface do The Sims 2, em vez de caixa reta.

    O brilho e recortado no contorno, como na pilula: nas linhas que cruzam o
    canto a meia-largura vem de sqrt(r^2 - dy^2), senao ele bateria numa parede
    vertical e deixaria um retangulo claro flutuando no topo.
]]
function Draw.panel(ui, x, y, w, h, r, fill, border, brilho, bw)
    bw = bw or 2
    if border then
        Draw.roundRect(ui, x, y, w, h, r, border)
    end
    Draw.roundRect(ui, x + bw, y + bw, w - bw * 2, h - bw * 2, max(0, r - bw), fill)

    if brilho then
        local ix, iy = x + bw, y + bw
        local iw, ih = w - bw * 2, h - bw * 2
        local ir = max(0, r - bw)
        local ate = iy + min(ih * 0.30, ir + 14)
        local py = iy + 1
        while py < ate do
            local dx = 0
            local dy = (iy + ir) - py          -- so o topo curva
            if dy > 0 and dy < ir then
                dx = ir - math.sqrt(ir * ir - dy * dy)
            end
            ui:drawRect(ix + dx, py, iw - dx * 2, 1, brilho.a, brilho.r, brilho.g, brilho.b)
            py = py + 1
        end
    end
end

--[[
    A bolinha de ligar/desligar -- anel vazio quando desmarcada, anel com disco
    dentro quando marcada.

    Substitui o ISTickBox do jogo, que desenha um quadradinho de textura fixa e
    nao acompanha a cor do mod. Como e desenhada, ela recolore junto com o tema.

    O disco de dentro nao encosta no anel de proposito: o vao e o que faz a
    marca parecer acesa em vez de um circulo chapado.
]]
--[[
    Sombra projetada sob um retangulo arredondado.

    Nao ha desfoque na camada de UI do PZ, entao a maciez vem de camadas: varios
    contornos concentricos, cada um um pouco maior e mais fraco. Tres ou quatro
    ja bastam -- acima disso o custo sobe e o olho nao distingue.

    O deslocamento e so para baixo e para a direita, como sombra de luz vinda de
    cima e da esquerda. Sombra centrada nao le como relevo, le como borrao.
]]
function Draw.shadow(ui, x, y, w, h, r, camadas, alcance, col)
    camadas = camadas or 4
    alcance = alcance or 3
    col = col or { r = 0, g = 0, b = 0, a = 0.30 }
    for i = camadas, 1, -1 do
        local e = (alcance * i) / camadas          -- expansao desta camada
        local a = col.a * (1 - (i - 1) / camadas) * 0.55
        Draw.roundRect(ui, x - e + alcance * 0.6, y - e + alcance * 0.9,
            w + e * 2, h + e * 2, r + e,
            { r = col.r, g = col.g, b = col.b, a = a })
    end
end

--[[
    Barra de rolagem no estilo The Sims 2: trilho em pilula, punho em pilula.

    Nao ha seta em cima nem embaixo - na referencia tambem nao ha. O trilho e um
    pouco mais claro que o painel e o punho e mais escuro, entao a leitura de
    "isto desliza" vem do contraste entre os dois, sem precisar de icone.

    `frac` e a fracao visivel (0..1); `pos` e onde a janela esta (0..1). Com
    frac >= 1 nao ha o que rolar e nada e desenhado, e o chamador nem precisa
    saber disso - assim a barra some sozinha quando o conteudo encolhe.

    Devolve as coordenadas do punho, para quem quiser tratar arrasto.
]]
function Draw.scrollbar(ui, x, y, w, h, frac, pos, trilho, punho, borda)
    if not frac or frac >= 1 then return nil end
    frac = max(0.08, frac)                 -- punho minimo, senao vira um ponto
    pos  = max(0, min(1, pos or 0))

    local r = w / 2
    Draw.roundRect(ui, x, y, w, h, r, trilho)
    if borda then
        Draw.roundRect(ui, x, y, w, h, r, borda)
        Draw.roundRect(ui, x + 1, y + 1, w - 2, h - 2, max(0, r - 1), trilho)
    end

    local ph = max(w * 1.6, h * frac)      -- punho nunca mais curto que redondo
    local py = y + (h - ph) * pos
    Draw.roundRect(ui, x, py, w, ph, r, punho)

    return x, py, w, ph
end

function Draw.radio(ui, cx, cy, r, marcado, aro, marca, dentro)
    if dentro then
        Draw.disc(ui, cx, cy, r - 1, dentro)
    end
    Draw.ring(ui, cx, cy, r, max(1.5, r * 0.18), aro)
    if marcado then
        Draw.disc(ui, cx, cy, r * 0.48, marca)
    end
end
