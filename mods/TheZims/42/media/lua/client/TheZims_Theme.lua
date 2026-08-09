--[[
    Monta a familia de cores da roda a partir de duas escolhas do jogador: a cor
    de fundo e a cor do texto.

    Tudo o mais - borda, brilho, orbe, foco, pilula do submenu, texto apagado -
    sai da cor de fundo por deslocamento em HSL, preservando o matiz. Assim
    trocar uma cor recolore o conjunto inteiro de forma coerente, em vez de
    exigir dez ajustes soltos.
]]

TheZims = TheZims or {}
local Theme = {}
TheZims.Theme = Theme

local max, min, floor = math.max, math.min, math.floor

local function clamp(v, lo, hi) return max(lo, min(hi, v)) end

local function rgbToHsl(r, g, b)
    local mx, mn = max(r, g, b), min(r, g, b)
    local l = (mx + mn) / 2
    local h, s, d = 0, 0, mx - mn
    if d > 0.0001 then
        s = (l > 0.5) and (d / (2 - mx - mn)) or (d / (mx + mn))
        if mx == r then h = (g - b) / d + ((g < b) and 6 or 0)
        elseif mx == g then h = (b - r) / d + 2
        else h = (r - g) / d + 4 end
        h = h / 6
    end
    return h, s, l
end

local function hue2rgb(p, q, t)
    if t < 0 then t = t + 1 end
    if t > 1 then t = t - 1 end
    if t < 1 / 6 then return p + (q - p) * 6 * t end
    if t < 1 / 2 then return q end
    if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
    return p
end

local function hslToRgb(h, s, l)
    if s <= 0.0001 then return l, l, l end
    local q = (l < 0.5) and (l * (1 + s)) or (l + s - l * s)
    local p = 2 * l - q
    return hue2rgb(p, q, h + 1 / 3), hue2rgb(p, q, h), hue2rgb(p, q, h - 1 / 3)
end

--- Uma cor da familia: mesmo matiz, luminosidade e saturacao deslocadas.
local function shade(h, s, l, dl, ds, a)
    local r, g, b = hslToRgb(h, clamp(s + (ds or 0), 0, 1), clamp(l + dl, 0.03, 0.97))
    return { r = r, g = g, b = b, a = a }
end

--[[
    Monta o conjunto inteiro de cores a partir de um RGB de origem.

    `ajustar` decide o quanto a cor crua e respeitada. Hoje sempre chega false:
    o jogador escolheu a cor a dedo, e empurrar ela para uma faixa "segura"
    seria desobedecer a escolha - fica so um piso de luminosidade para o
    contorno nao sumir no preto absoluto.

    O ramo `true` ficou de uma versao que tirava a cor do cabelo ou do chapeu,
    onde a cor crua nao era confiavel (cabelo preto virava pilula ilegivel).
    Continua aqui porque e barato e util se um dia entrar outra fonte de cor
    automatica.

    `corTexto` sobrescreve a cor do texto, que no modo fixo tambem e escolhida.
]]
function Theme.paletteFrom(r, g, b, ajustar, corTexto)
    local h, s, l = rgbToHsl(r, g, b)

    if ajustar then
        if s < 0.10 then
            -- Sem matiz util (preto, branco, grisalho): aco neutro levemente
            -- frio, em vez de inventar uma cor que o personagem nao tem.
            h, s, l = 0.60, 0.07, 0.46
        else
            s = clamp(s, 0.34, 0.72)
            l = clamp(l, 0.40, 0.58)
        end
    else
        l = clamp(l, 0.10, 0.90)
    end

    local texto = corTexto and { r = corTexto.r, g = corTexto.g, b = corTexto.b, a = 1 }
        or { r = 1, g = 1, b = 1, a = 1 }

    return {
        pillBorder   = shade(h, s, l, -0.32, 0.05, 0.95),
        pill         = shade(h, s, l,  0.00, 0.00, 0.93),
        pillHi       = shade(h, s, l,  0.16, -0.05, 0.45),
        pillHover    = shade(h, s, l,  0.19, 0.04, 0.98),
        pillHiHover  = shade(h, s, l,  0.34, -0.10, 0.50),
        pillDisabled = shade(h, s * 0.25, l, -0.20, 0, 0.78),

        -- A pilula do centro dentro de um submenu: o nivel de onde voce veio.
        -- Escura de proposito, para o olho separar na hora "o que eu escolhi"
        -- das opcoes novas em volta, que ficam no tom normal.
        pillParent      = shade(h, s, l, -0.20, -0.04, 0.95),
        pillParentHi    = shade(h, s, l, -0.06, -0.08, 0.30),
        pillParentHover = shade(h, s, l, -0.10, 0.00, 0.97),

        orb          = shade(h, s, l,  0.08, 0.02, 0.96),
        orbHover     = shade(h, s, l,  0.28, 0.02, 1.00),
        orbHi        = shade(h, s, l,  0.44, -0.15, 0.55),

        text         = texto,
        -- Opcao indisponivel: mesma cor do texto, so apagada. Cinza fixo
        -- brigaria com texto escuro escolhido pelo jogador.
        textDisabled = { r = texto.r * 0.55, g = texto.g * 0.55, b = texto.b * 0.55, a = 0.90 },

        hubBack      = { r = 0.02, g = 0.02, b = 0.03, a = 0.92 },
        hoverWedge   = shade(h, s, l, 0.10, 0, 0.13),
    }
end

--- Paleta em uso, montada a partir das cores escolhidas pelo jogador.
--- Recalculada so quando alguma delas muda, nao a cada quadro.
function Theme.current(player)
    local P = TheZims.PREF
    local corFundo = (P and P.corFundo) or TheZims.COR_FUNDO_PADRAO
    local corTexto = (P and P.corTexto) or TheZims.COR_TEXTO_PADRAO

    local key = string.format("%d,%d,%d,%d,%d,%d",
        floor(corFundo.r * 255), floor(corFundo.g * 255), floor(corFundo.b * 255),
        floor(corTexto.r * 255), floor(corTexto.g * 255), floor(corTexto.b * 255))

    if Theme._key ~= key then
        Theme._key = key
        -- `ajustar` falso: a cor foi escolhida a dedo, entao e respeitada.
        Theme._palette = Theme.paletteFrom(corFundo.r, corFundo.g, corFundo.b, false, corTexto)
        TheZims.log("paleta -> " .. key)
    end
    return Theme._palette or TheZims.COLORS
end

--- Forca o recalculo na proxima consulta (usado ao trocar a opcao no menu).
function Theme.invalidate()
    Theme._key = nil
    Theme._palette = nil
end
