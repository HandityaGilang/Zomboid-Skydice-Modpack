local CD = CompanionDogs
CD.Keybinds = CD.Keybinds or {}

-- Handler de keybind customizado. Le o mapa de teclas por jogador de CD.Settings (NAO getCore():getKey) e dispara os
-- comandos do cao pelo mesmo pipeline CD.request seguro em MP que os botoes do radial/status usam. Nao da pra consumir uma
-- tecla em Lua para suprimir a acao vanilla na mesma tecla, entao: os padroes ficam sem bind, a UI de rebind avisa em caso de
-- conflito, e este handler so roda em jogo (nao em menus / entrada de texto).

-- A UI de settings arma uma captura de um disparo setando captureCb; a proxima tecla pressionada e entregue a ela.
function CD.Keybinds.beginCapture(cb)
    CD.Keybinds.captureCb = cb
end

-- Varredura de conflito: a tecla escolhida contra toda acao nativa que aceita bind (tabela global keyBinding + getCore():getKey)
-- E nossas proprias acoes do cao. Retorna uma lista de nomes legiveis que ja usam a tecla.
function CD.Keybinds.findConflicts(code, exceptId)
    local names = {}
    if not code or code == 0 then return names end
    pcall(function()
        if keyBinding then
            for _, e in ipairs(keyBinding) do
                local nm = e and e.value
                if nm and nm ~= "" then
                    local cur = getCore():getKey(nm)
                    if cur and cur ~= 0 and cur == code then
                        names[#names + 1] = nm
                    end
                end
            end
        end
    end)
    local keys = CD.Settings and CD.Settings.data and CD.Settings.data.keys
    if keys then
        for id, c in pairs(keys) do
            if id ~= exceptId and c ~= 0 and c == code then
                local a = CD.Settings.ACTION_BY_ID[id]
                names[#names + 1] = (a and getText(a.label)) or id
            end
        end
    end
    return names
end

local function isBlocked()
    local blocked = false
    pcall(function()
        if not (MainScreen and MainScreen.instance and MainScreen.instance.inGame) then blocked = true; return end
        if MainScreen.instance.getIsVisible and MainScreen.instance:getIsVisible() then blocked = true; return end
        if ISTextBox and ISTextBox.instance then blocked = true; return end
        if ISChat and ISChat.instance and ISChat.instance.textEntry
            and ISChat.instance.textEntry.javaObject and ISChat.instance.textEntry:isFocused() then
            blocked = true; return
        end
    end)
    return blocked
end

local function fire(id)
    local spec = CD.Settings.ACTION_BY_ID[id]
    if not spec then return end
    local player = getPlayer()
    if not player then return end

    if spec.special == "status" then
        if CD.openDogStatus then CD.openDogStatus(player) end
        return
    end

    local dog = CD.getCompanionAnimal(player)
    if not dog then
        pcall(function() HaloTextHelper.addText(player, getText("IGUI_PD_NoCompanionNear")) end)
        return
    end

    if spec.gesture then pcall(function() player:playEmote(spec.gesture) end) end
    if spec.callout then pcall(function() player:Callout(false) end) end

    if spec.special == "protect" then
        local on = false
        pcall(function() on = CD.getAutoProtect(dog) end)
        CD.request("setautoprotect", dog, { on = not on })
        return
    end

    if spec.special == "hunt" then
        local on = false
        pcall(function() on = CD.getHuntMode(dog) end)
        CD.request("sethuntmode", dog, { on = not on })
        return
    end

    local extra = nil
    if spec.args then
        extra = {}
        for k, v in pairs(spec.args) do extra[k] = v end
    end
    CD.request(spec.cmd, dog, extra)
    pcall(function() player:setJoypadIgnoreAimUntilCentered(true) end)
end

local function onKeyStartPressed(key)
    -- modo de captura (rebind): engole a proxima tecla para a UI de settings
    if CD.Keybinds.captureCb then
        local cb = CD.Keybinds.captureCb
        CD.Keybinds.captureCb = nil
        if key == Keyboard.KEY_ESCAPE then cb(nil) else cb(key) end
        return
    end
    if not key or key == 0 then return end
    if isBlocked() then return end
    local keys = CD.Settings and CD.Settings.data and CD.Settings.data.keys
    if not keys then return end
    for _, spec in ipairs(CD.Settings.ACTIONS) do
        if keys[spec.id] == key then
            fire(spec.id)
            return
        end
    end
end

if isClient() or not isServer() then
    Events.OnKeyStartPressed.Add(onKeyStartPressed)
end
