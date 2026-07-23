local CD = CompanionDogs
CD.Settings = CD.Settings or {}

-- Configuracoes de CLIENT por jogador: volume mestre de som (+mute) e os keybindings customizados dos comandos do cao.
-- Fonte unica da verdade = o arquivo abaixo (NAO a tabela keyBinding nativa / Options>Controls). Tudo no client.

CD.Settings.FILE = "CompanionDogs_settings.ini"

-- Lista ordenada de acoes bindaveis (guia as linhas de rebind E o handler de teclas). Reusa as specs de cmd do radial
-- e os labels i18n existentes. cmd/args roteiam por CD.request como os botoes do radial/status; as especiais
-- (janela de status, toggle de auto-protect) sao tratadas no handler de teclas.
CD.Settings.ACTIONS = {
    { id = "cd_come",    label = "IGUI_PD_CmdCome",    cmd = "come",        gesture = "comehere" },
    { id = "cd_follow",  label = "IGUI_PD_CmdFollow",  cmd = "setstate",    gesture = "followme", args = { state = CD.STATE_FOLLOW } },
    { id = "cd_stay",    label = "IGUI_PD_CmdStay",    cmd = "setstate",    gesture = "stop",     args = { state = CD.STATE_STAY } },
    { id = "cd_guard",   label = "IGUI_PD_CmdGuard",   cmd = "setstate",    gesture = "stop",     args = { state = CD.STATE_GUARD } },
    { id = "cd_bring",   label = "IGUI_PD_CmdFetch",   cmd = "teleport",    gesture = "comehere", callout = true },
    { id = "cd_attack",  label = "IGUI_PD_CmdAttack",  cmd = "attack",      gesture = "signalfire" },
    { id = "cd_alert",   label = "IGUI_PD_AlertOn",    cmd = "setalertmode", args = { mode = "full" } },
    { id = "cd_quiet",   label = "IGUI_PD_AlertQuiet", cmd = "setalertmode", args = { mode = "quiet" } },
    { id = "cd_silent",  label = "IGUI_PD_AlertSilent",cmd = "setalertmode", args = { mode = "silent" } },
    { id = "cd_protect", label = "IGUI_PD_AutoProtect",special = "protect" },
    { id = "cd_hunt",    label = "IGUI_PD_HuntMode",   special = "hunt" },
    { id = "cd_status",  label = "IGUI_PD_Inspect",    special = "status" },
}

CD.Settings.ACTION_BY_ID = {}
for _, spec in ipairs(CD.Settings.ACTIONS) do CD.Settings.ACTION_BY_ID[spec.id] = spec end

-- Padroes: todas as teclas sem bind (0) para haver ZERO conflitos de cara; o jogador opta por acao.
-- showTexts = preferencia por client do jogador de ver os halos flutuantes do cao + as linhas de status do name-tag.
-- volume/mute = Volume geral (master, multiplica tudo); catVol/catMute = por-categoria de som (Latido/Efeitos/Ambiente).
CD.Settings.DEFAULTS = { volume = 1.0, mute = false, showTexts = true, showMoodles = true, keys = {} }
for _, spec in ipairs(CD.Settings.ACTIONS) do CD.Settings.DEFAULTS.keys[spec.id] = 0 end

local function freshData()
    local D = CD.Settings.DEFAULTS
    local d = { volume = D.volume, mute = D.mute, showTexts = D.showTexts, showMoodles = D.showMoodles,
                keys = {}, windows = {}, catVol = {}, catMute = {} }
    for k, v in pairs(D.keys) do d.keys[k] = v end
    for _, c in ipairs(CD.SOUND_CATEGORIES) do d.catVol[c] = 1.0; d.catMute[c] = false end
    return d
end

CD.Settings.data = CD.Settings.data or freshData()

function CD.Settings.getCatVolume(cat)
    local d = CD.Settings.data
    local v = d and d.catVol and d.catVol[cat]
    return type(v) == "number" and v or 1.0
end

function CD.Settings.isCatMuted(cat)
    local d = CD.Settings.data
    return d and d.catMute and d.catMute[cat] == true or false
end

-- Fator de volume final para um som: master * categoria * volume de efeitos do JOGO. Zero se o master OU a categoria
-- estiver mutado. Sem soundName (ou som sem categoria) = so master (retrocompat com a barra unica antiga).
-- O fator do jogo so entra nos nossos .ogg soltos (CD.SOUND_NONBANK): eles tocam num channel group cru, fora do VCA
-- "Settings_Sfx", entao o slider de efeitos do jogo NAO os alcancava. Sons de banco (ZombieBite) ja passam pelo VCA;
-- aplicar o fator neles atenuaria duas vezes.
function CD.Settings.getVolumeFactor(soundName)
    local d = CD.Settings.data
    if not d then return 1.0 end
    if d.mute then return 0 end
    local f = d.volume or 1.0
    local cat = soundName and CD.SOUND_CATEGORY and CD.SOUND_CATEGORY[soundName]
    if cat then
        if CD.Settings.isCatMuted(cat) then return 0 end
        f = f * CD.Settings.getCatVolume(cat)
    end
    if soundName and CD.SOUND_NONBANK and CD.SOUND_NONBANK[soundName] then
        local game = 1.0
        pcall(function() game = math.max(0, math.min(10, getCore():getOptionSoundVolume() or 10)) / 10 end)
        f = f * game
    end
    return f
end

function CD.Settings.isMuted() return CD.Settings.data and CD.Settings.data.mute == true end
function CD.Settings.getShowTexts() return not (CD.Settings.data and CD.Settings.data.showTexts == false) end
function CD.Settings.getShowMoodles() return not (CD.Settings.data and CD.Settings.data.showMoodles == false) end
function CD.Settings.getKey(id) return (CD.Settings.data and CD.Settings.data.keys[id]) or 0 end

function CD.Settings.keyName(code)
    code = math.floor(tonumber(code) or 0)
    if code == 0 then return getText("IGUI_PD_KeyUnbound") end
    -- O getKeyName global trata codigos de mouse (>=10000=Mouse.BTN_OFFSET); NUNCA Keyboard.getKeyName (array de 256 -> AIOOBE, impossivel de pegar com pcall).
    if (code > 0 and code < 256) or code >= 10000 then
        local name
        pcall(function() name = getKeyName(code) end)
        if name and name ~= "" then return name end
    end
    return "#" .. tostring(code)
end

function CD.Settings.save()
    pcall(function()
        local w = getFileWriter(CD.Settings.FILE, true, false)
        if not w then return end
        local d = CD.Settings.data
        w:write("volume=" .. tostring(d.volume) .. "\r\n")
        w:write("mute=" .. tostring(d.mute) .. "\r\n")
        w:write("showTexts=" .. tostring(d.showTexts) .. "\r\n")
        w:write("showMoodles=" .. tostring(d.showMoodles) .. "\r\n")
        if d.dogwinTab and d.dogwinTab ~= "" then
            w:write("dogwinTab=" .. tostring(d.dogwinTab) .. "\r\n")
        end
        for id, code in pairs(d.keys) do
            w:write("key." .. id .. "=" .. tostring(code) .. "\r\n")
        end
        for _, c in ipairs(CD.SOUND_CATEGORIES) do
            w:write("catvol." .. c .. "=" .. tostring(d.catVol[c]) .. "\r\n")
            w:write("catmute." .. c .. "=" .. tostring(d.catMute[c]) .. "\r\n")
        end
        for name, r in pairs(d.windows or {}) do
            if r and r.x and r.y and r.w and r.h then
                w:write("win." .. name .. ".x=" .. tostring(math.floor(r.x)) .. "\r\n")
                w:write("win." .. name .. ".y=" .. tostring(math.floor(r.y)) .. "\r\n")
                w:write("win." .. name .. ".w=" .. tostring(math.floor(r.w)) .. "\r\n")
                w:write("win." .. name .. ".h=" .. tostring(math.floor(r.h)) .. "\r\n")
            end
        end
        w:close()
    end)
end

function CD.Settings.load()
    CD.Settings.data = freshData()
    pcall(function()
        local r = getFileReader(CD.Settings.FILE, false)
        if not r then return end
        local line = r:readLine()
        while line ~= nil do
            local k, v = line:match("^%s*([^=]-)%s*=%s*(.-)%s*$")
            if k and v then
                if k == "volume" then
                    local n = tonumber(v)
                    if n then CD.Settings.data.volume = math.max(0, math.min(1, n)) end
                elseif k == "mute" then
                    CD.Settings.data.mute = (v == "true")
                elseif k == "showTexts" then
                    CD.Settings.data.showTexts = (v ~= "false")
                elseif k == "showMoodles" then
                    CD.Settings.data.showMoodles = (v ~= "false")
                elseif k == "dogwinTab" then
                    if v ~= "" then CD.Settings.data.dogwinTab = v end
                elseif k:match("^catvol%.(.+)$") then
                    local c = k:match("^catvol%.(.+)$")
                    local n = tonumber(v)
                    if c and n and CD.Settings.data.catVol[c] ~= nil then
                        CD.Settings.data.catVol[c] = math.max(0, math.min(1, n))
                    end
                elseif k:match("^catmute%.(.+)$") then
                    local c = k:match("^catmute%.(.+)$")
                    if c and CD.Settings.data.catMute[c] ~= nil then
                        CD.Settings.data.catMute[c] = (v == "true")
                    end
                else
                    local id = k:match("^key%.(.+)$")
                    local wname, wfield = k:match("^win%.(.+)%.([xywh])$")
                    if id and CD.Settings.data.keys[id] ~= nil then
                        local n = tonumber(v)
                        if n then CD.Settings.data.keys[id] = math.floor(n) end
                    elseif wname and wfield then
                        local n = tonumber(v)
                        if n then
                            local rec = CD.Settings.data.windows[wname] or {}
                            rec[wfield] = math.floor(n)
                            CD.Settings.data.windows[wname] = rec
                        end
                    end
                end
            end
            line = r:readLine()
        end
        r:close()
    end)
end

-- Todo setter de som chama CD.refreshSoundVolumes: sons em LOOP ja tocando (comer/beber) so pegariam o valor novo no
-- proximo play, e o jogador le esse atraso como "mexer no volume nao funciona".
function CD.Settings.setVolume(v)
    if type(v) ~= "number" then return end
    CD.Settings.data.volume = math.max(0, math.min(1, v))
    CD.Settings.save()
    CD.refreshSoundVolumes()
end

function CD.Settings.setMute(b)
    CD.Settings.data.mute = (b == true)
    CD.Settings.save()
    CD.refreshSoundVolumes()
end

function CD.Settings.setCatVolume(cat, v)
    if type(v) ~= "number" or CD.Settings.data.catVol[cat] == nil then return end
    CD.Settings.data.catVol[cat] = math.max(0, math.min(1, v))
    CD.Settings.save()
    CD.refreshSoundVolumes()
end

function CD.Settings.setCatMute(cat, b)
    if CD.Settings.data.catMute[cat] == nil then return end
    CD.Settings.data.catMute[cat] = (b == true)
    CD.Settings.save()
    CD.refreshSoundVolumes()
end

function CD.Settings.setShowTexts(b)
    CD.Settings.data.showTexts = (b ~= false)
    CD.Settings.save()
end

function CD.Settings.setShowMoodles(b)
    CD.Settings.data.showMoodles = (b ~= false)
    CD.Settings.save()
end

function CD.Settings.setKey(id, code)
    if CD.Settings.data.keys[id] == nil then return end
    CD.Settings.data.keys[id] = math.floor(tonumber(code) or 0)
    CD.Settings.save()
end

-- Ultima aba ativa da janela unificada do cao (id interno, nao o rotulo traduzido).
function CD.Settings.getLastTab()
    return CD.Settings.data and CD.Settings.data.dogwinTab
end

function CD.Settings.setLastTab(name)
    if type(name) ~= "string" or name == "" then return end
    if CD.Settings.data.dogwinTab == name then return end
    CD.Settings.data.dogwinTab = name
    CD.Settings.save()
end

-- Geometria da janela (tamanho + posicao) por janela nomeada. Preferencia de client so de exibicao, entao fica no INI.
function CD.Settings.getWindowRect(name)
    local r = CD.Settings.data and CD.Settings.data.windows and CD.Settings.data.windows[name]
    if r and r.x and r.y and r.w and r.h then
        return { x = r.x, y = r.y, w = r.w, h = r.h }
    end
    return nil
end

function CD.Settings.setWindowRect(name, x, y, w, h)
    if not name then return end
    if not (x and y and w and h) then return end
    CD.Settings.data.windows = CD.Settings.data.windows or {}
    CD.Settings.data.windows[name] = { x = math.floor(x), y = math.floor(y), w = math.floor(w), h = math.floor(h) }
    CD.Settings.save()
end

-- Gatilho de auto-feed: o nivel de fome/sede (0.1..1.0) no qual o cao busca uma tigela por conta propria. Diferente de volume/teclas
-- (so client), o SERVER le isso, entao fica no ModData do PLAYER (replica + persiste com o save), nao no
-- INI. Sem valor -> cai de volta para o padrao sandbox TroughFeedTrigger.
function CD.Settings.getFeedTrigger()
    local p = getSpecificPlayer(0)
    local md = p and p:getModData()
    local v = md and md.cdFeedTrigger
    if type(v) == "number" then return v end
    return (CD.troughFeedTrigger and CD.troughFeedTrigger()) or 0.5
end

function CD.Settings.setFeedTrigger(v)
    if type(v) ~= "number" then return end
    v = math.max(0.1, math.min(1.0, v))
    local p = getSpecificPlayer(0)
    if not p then return end
    local md = p:getModData()
    if md.cdFeedTrigger == v then return end
    md.cdFeedTrigger = v
    -- Comando pequeno em vez de transmitModData: o server grava a copia autoritativa (CD.Server.feedtrigger)
    -- sem o client reenviar o ModData inteiro do player a cada passo do slider.
    pcall(function() CD.request("feedtrigger", nil, { value = v }) end)
end

if isClient() or not isServer() then
    CD.Settings.load()
    Events.OnGameStart.Add(CD.Settings.load)
end

-- ===================== encanamento compartilhado de resize + scroll de janela =====================
-- Mora aqui (um arquivo de client sempre carregado) em vez de um arquivo novo, para nao bater no problema do
-- novo-arquivo-nao-dispara e porque os helpers de janela ja dependem da persistencia de geometria acima. Duas partes:
--  * Helpers de view: um ISPanel interno que rola seu desenho imediato + botoes filhos. A engine desloca
--    o drawText/drawRect proprio do elemento pelo seu yScroll E desloca os filhos (scrollChildren + scrollWithParent do filho),
--    enquanto getMouseX/Y compensam, entao desenhos, botoes e hover ficam todos consistentes no espaco de conteudo. Um stencil
--    nos limites da propria view recorta o overflow sem mexer na barra de titulo / widgets de resize da janela.
--  * Helpers de janela: tornam uma ISCollapsableWindow redimensionavel, a abrem num tamanho que cabe na tela e persistem sua
--    geometria (tamanho + posicao) no INI de settings.
CD.UI = CD.UI or {}

CD.UI.SCROLLBAR_W = 17
CD.UI.WHEEL_STEP = 40
CD.UI.SCREEN_FRAC = 0.90   -- altura padrao de abertura limitada a esta fracao da tela

function CD.UI.clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi else return v end
end

-- Chame do :instantiate() da view. ISPanel.instantiate cria o javaObject e roda o createChildren da view
-- (que constroi os botoes); a scrollbar e adicionada depois para renderizar por cima. scrollChildren faz os botoes
-- acompanharem view.yScroll; a propria scrollbar seta scrollWithParent=false para ficar parada.
function CD.UI.viewInstantiate(view)
    ISPanel.instantiate(view)
    view:addScrollBars(false)
    view:setScrollChildren(true)
end

function CD.UI.viewMouseWheel(view, del)
    view:setYScroll(view:getYScroll() - del * CD.UI.WHEEL_STEP) -- setYScroll limita ao intervalo rolavel
    return true
end

-- Largura de conteudo: a largura da view menos a calha da scrollbar. Reservada incondicionalmente para o layout ser estavel (sem
-- oscilacao de reflow quando a scrollbar aparece/some).
function CD.UI.viewContentW(view)
    return view.width - CD.UI.SCROLLBAR_W
end

function CD.UI.viewBeginRender(view)
    view:setStencilRect(0, 0, view.width, view.height)
end

function CD.UI.viewEndRender(view)
    view:clearStencilRect()
end

-- Define largura+altura e entao reflow UMA vez. O ISResizeWidget base chama target:setWidth(x) E target:setHeight(y)
-- separadamente; reflow em cada um chamaria o setWidth da view interna duas vezes no mesmo frame, e a segunda chamada
-- sobrescreve lastwidth, entao o delta de ancora da engine (que move a scrollbar) calcula como zero e a scrollbar
-- para de acompanhar o resize. Rotear todo resize por um unico reflow mantem o delta intacto.
function CD.UI.applyResize(win, w, h)
    ISCollapsableWindow.setWidth(win, w)
    ISCollapsableWindow.setHeight(win, h)
    if win.reflow then win:reflow() end
end

-- Rode no FIM do createChildren da janela (os widgets de resize ja existem do createChildren base).
-- O hook resizeFunction faz o ISResizeWidget rotear todo o arraste por applyResize (um reflow) em vez do seu
-- padrao setWidth-depois-setHeight (dois reflows).
function CD.UI.initResizable(win, name, minW, minH)
    win.cdLayoutName = name
    win.minimumWidth = minW
    win.minimumHeight = minH
    win:setResizable(true)
    local function rf(target, w, h) CD.UI.applyResize(target, w, h) end
    if win.resizeWidget then win.resizeWidget.resizeFunction = rf end
    if win.resizeWidget2 then win.resizeWidget2.resizeFunction = rf end
end

-- Posiciona a janela ao abrir: restaura o rect salvo se houver (limitado a tela), senao centraliza na
-- largura padrao e numa altura que cabe na tela (para conteudo alto abrir ja rolavel em telas pequenas).
function CD.UI.applyOpenGeometry(win, name, defW, naturalH)
    local core = getCore()
    local sw, sh = core:getScreenWidth(), core:getScreenHeight()
    local minW = win.minimumWidth or 120
    local minH = win.minimumHeight or 120
    local rect = CD.Settings and CD.Settings.getWindowRect and CD.Settings.getWindowRect(name)
    local w, h, x, y
    if rect then
        w = CD.UI.clamp(rect.w, minW, sw)
        h = CD.UI.clamp(rect.h, minH, sh)
        x = CD.UI.clamp(rect.x, 0, math.max(0, sw - w))
        y = CD.UI.clamp(rect.y, 0, math.max(0, sh - h))
    else
        w = math.max(minW, math.min(defW, sw))
        h = math.max(minH, math.min(naturalH, math.floor(sh * CD.UI.SCREEN_FRAC)))
        x = math.floor(sw / 2 - w / 2)
        y = math.floor(sh / 2 - h / 2)
        if x < 0 then x = 0 end
        if y < 0 then y = 0 end
    end
    CD.UI.applyResize(win, w, h)
    win:setX(x)
    win:setY(y)
end

function CD.UI.persist(win)
    if not (win.cdLayoutName and CD.Settings and CD.Settings.setWindowRect) then return end
    CD.Settings.setWindowRect(win.cdLayoutName, win:getX(), win:getY(), win:getWidth(), win:getHeight())
end
