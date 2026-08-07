require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"

-- Janela da cangalha do companheiro: duas listas de mover-com-clique estilizadas como o inventario vanilla (icone +
-- nome + peso, linhas alternadas, cabecalhos de coluna). Esquerda = seu inventario (clique para depositar), direita =
-- a bolsa do cachorro (clique para retirar). Todos os movimentos de item sao autoritativos no server (CD.request ->
-- CD.Server.bagput/bagtake); a janela so exibe os registros que o server devolve via "bagdata" e re-le o inventario
-- vivo do player. A bolsa vive como registros planos no ModData do cachorro (ver CompanionDogs_Util.lua).
local CD = CompanionDogs

ISCDBagWindow = ISCollapsableWindow:derive("ISCDBagWindow")
CD.BagWindow = CD.BagWindow or {}

local PAD = 8
local HEADER_H = 18
local ROW_H = 24

local function cdItemWeight(it)
    local w = 0
    pcall(function() w = it:getUnequippedWeight() end)
    if not w or w <= 0 then pcall(function() w = it:getWeight() end) end
    return w or 0
end

-- Uma linha no estilo do inventario vanilla: faixa alternada, icone, nome (esquerda), peso (direita, cinza), separador fino.
local function cdDrawRow(self, y, item, alt)
    if not item.height then item.height = self.itemheight end
    local h = item.height
    if (y + self:getYScroll() + h < 0) or (y + self:getYScroll() >= self.height) then
        return y + h
    end
    local w = self:getWidth()
    if alt then self:drawRect(0, y, w, h, 0.06, 1, 1, 1) end
    if self.selected == item.index then
        self:drawSelection(0, y, w, h - 1)
    elseif self.mouseoverselected == item.index and self:isMouseOver() and not self:isMouseOverScrollBar() then
        self:drawMouseOverHighlight(0, y, w, h - 1)
    end
    local d = item.item
    local sz = h - 6
    if d and d.tex then
        pcall(function() self:drawTextureScaledAspect(d.tex, 3, y + 3, sz, sz, 1, 1, 1, 1) end)
    end
    local ty = y + (h - self.fontHgt) / 2
    if d and d.weight then
        local ws = string.format("%.2f", d.weight)
        local wx = w - getTextManager():MeasureStringX(self.font, ws) - 6
        self:drawText(ws, wx, ty, 0.62, 0.62, 0.62, 1, self.font)
    end
    self:drawText(item.text, h + 2, ty, 0.9, 0.9, 0.9, 1, self.font)
    self:drawRect(0, y + h - 1, w, 1, 0.25, 0.4, 0.4, 0.4)
    return y + h
end

local function eligibleForDeposit(item)
    if not item then return false end
    if CD.isSaddlebagType(item:getFullType()) then return false end
    if instanceof(item, "InventoryContainer") then return false end   -- registros planos nao guardam bolsa aninhada
    if instanceof(item, "AnimalInventoryItem") then return false end  -- nunca depositar o proprio cachorro
    local eq = false
    pcall(function() eq = item:isEquipped() end)                      -- roupa vestida OU arma na mao
    if eq then return false end
    return true
end

-- Coleta cada item depositavel que o player tem, recursando nas mochilas vestidas e seus sub-containers para a lista
-- de deposito mostrar a carga onde quer que ela esteja (o server ja resolve recursivamente via getItemById). Os
-- proprios itens container sao pulados (recursamos o conteudo deles no lugar).
local function collectDepositable(inv, out, depth)
    if not inv or depth > 6 then return end
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local it = items:get(i)
        if instanceof(it, "InventoryContainer") then
            local sub = nil
            pcall(function() sub = it:getInventory() end)
            collectDepositable(sub, out, depth + 1)
        elseif eligibleForDeposit(it) then
            out[#out + 1] = it
        end
    end
end

function ISCDBagWindow:new(x, y, w, h)
    local o = ISCollapsableWindow.new(self, x, y, w, h)
    o.records = {}
    o.cap = 0
    o.playerNum = 0
    o.resizable = true
    o:setTitle(getText("IGUI_PD_BagWindowTitle"))
    return o
end

-- Geometria de coluna/lista para o tamanho atual da janela (duas colunas iguais sob a linha de cabecalho, acima da
-- faixa de resize de baixo). Tambem publica headerY/invX/bagX/colW usados pelo prerender + os handlers de clique. Retorna listTop, colW, listH.
function ISCDBagWindow:listGeom()
    local top = self:titleBarHeight() + PAD
    local listTop = top + HEADER_H
    local rh = self:resizeWidgetHeight()
    local colW = math.floor((self.width - PAD * 3) / 2)
    if colW < 40 then colW = 40 end
    local listH = self.height - listTop - PAD - rh
    if listH < 40 then listH = 40 end
    self.headerY = top
    self.invX = PAD
    self.bagX = PAD * 2 + colW
    self.colW = colW
    return listTop, colW, listH
end

function ISCDBagWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local rowFont = UIFont.Small
    local rowFontHgt = getTextManager():getFontHeight(rowFont)
    -- Cria as listas ja no tamanho correto de cara: um ISScrollingListBox construido pequeno e redimensionado perde a
    -- geometria interna da scrollbar (o delta da ancora e descartado quando o open faz setWidth+setHeight num frame so),
    -- deixando a scrollbar presa no canto. O drag-resize depois so aplica pequenos deltas por frame que as ancoras tratam de boa.
    local listTop, colW, listH = self:listGeom()

    self.invList = ISScrollingListBox:new(self.invX, listTop, colW, listH)
    self.invList:initialise()
    self.invList.itemheight = ROW_H
    self.invList.font = rowFont
    self.invList.fontHgt = rowFontHgt
    self.invList.drawBorder = true
    self.invList.doDrawItem = cdDrawRow
    self.invList:setOnMouseDownFunction(self, self.onDeposit)
    self:addChild(self.invList)

    self.bagList = ISScrollingListBox:new(self.bagX, listTop, colW, listH)
    self.bagList:initialise()
    self.bagList.itemheight = ROW_H
    self.bagList.font = rowFont
    self.bagList.fontHgt = rowFontHgt
    self.bagList.drawBorder = true
    self.bagList.doDrawItem = cdDrawRow
    self.bagList:setOnMouseDownFunction(self, self.onWithdraw)
    self:addChild(self.bagList)

    CD.UI.initResizable(self, "bag", 420, 260)
    self:refresh()
end

-- Reposiciona as duas listas para o tamanho atual da janela. As listas rolam seu proprio conteudo, entao isso so
-- move/redimensiona elas; a scrollbar acompanha via deltas de ancora por frame (as listas foram criadas em tamanho cheio, ver createChildren).
function ISCDBagWindow:layoutLists()
    if not (self.invList and self.bagList) then return end
    local listTop, colW, listH = self:listGeom()
    self.invList:setX(self.invX); self.invList:setY(listTop)
    self.invList:setWidth(colW);  self.invList:setHeight(listH)
    self.bagList:setX(self.bagX); self.bagList:setY(listTop)
    self.bagList:setWidth(colW);  self.bagList:setHeight(listH)
end

function ISCDBagWindow:reflow()
    self:layoutLists()
end

function ISCDBagWindow:prerender()
    ISCollapsableWindow.prerender(self)
    if not self.headerY then return end
    local fy = self.headerY + (HEADER_H - getTextManager():getFontHeight(UIFont.Small)) / 2
    self:drawRect(self.invX, self.headerY, self.colW, HEADER_H, 0.4, 0.12, 0.12, 0.12)
    self:drawRect(self.bagX, self.headerY, self.colW, HEADER_H, 0.4, 0.12, 0.12, 0.12)
    self:drawText(getText("IGUI_PD_BagYours"), self.invX + 4, fy, 0.8, 0.8, 0.8, 1, UIFont.Small)
    local used = (CD.bagWeight and CD.bagWeight(self.records)) or 0
    local bagHdr = getText("IGUI_PD_BagCapacity", string.format("%.1f", used), tostring(self.cap or 0))
    self:drawText(bagHdr, self.bagX + 4, fy, 0.8, 0.8, 0.8, 1, UIFont.Small)
end

-- Roteia um movimento de bolsa pelo id persistente do cachorro, nao pelo self.animal vivo: getAnimal() retorna nil no
-- instante em que o cachorro virtualiza alem de ~52-60 tiles, entao um objeto de animal capturado antes fica obsoleto e o
-- clique faria um no-op silencioso. O server resolve o cachorro do zero a partir de args.id a cada chamada.
function ISCDBagWindow:sendBag(command, extra)
    if not self.animalId then return end
    extra = extra or {}
    extra.id = self.animalId
    if isClient() then
        sendClientCommand(CD.MODULE, command, extra)
    elseif CD.Server and CD.Server[command] then
        extra.__animal = self.animal or getAnimal(self.animalId)
        CD.Server[command](getPlayer(), extra)
    end
end

function ISCDBagWindow:cdHalo(key, name)
    if not (CD.showNotifications == nil or CD.showNotifications()) then return end
    local pl = getSpecificPlayer(self.playerNum) or getPlayer()
    if pl then pcall(function() HaloTextHelper.addText(pl, getText(key, name or "")) end) end
end

function ISCDBagWindow:onDeposit(data)
    if data and data.item then
        self:sendBag("bagput", { itemId = data.item:getID() })
        self:cdHalo("IGUI_PD_BagStored", data.item:getName())
        -- anotacoes de mapa vivem em MapItem.symbols (acessor @HiddenFromLua); nao da pra preservar no round-trip.
        local isMap = false; pcall(function() isMap = data.item:IsMap() end)
        if isMap then self:cdHalo("IGUI_PD_BagMapNoAnnot") end
    end
end

function ISCDBagWindow:onWithdraw(data)
    if data and data.index then
        self:sendBag("bagtake", { index = data.index })
        local r = self.records and self.records[data.index]
        if r then local disp = instanceItem(r.t); if disp then self:cdHalo("IGUI_PD_BagTaken", disp:getName()) end end
    end
end

-- Uma linha por tipo de item (empilhamento estilo vanilla): "Nome (xN)" com o peso total da pilha. Um clique move UM
-- item daquele tipo (o representante); a lista e re-derivada no proximo refresh entao a contagem so decrementa.
function ISCDBagWindow:refresh()
    if not self.bagList or not self.invList then return end

    -- Lado da bolsa: agrupa os registros planos por tipo, mantem a ordem de primeira aparicao, lembra os indices de registro de cada grupo.
    self.bagList:clear()
    -- agrupa por tipo + nome custom: itens renomeados aparecem com o proprio nome e nao se fundem com os sem-nome
    local bGroups, bOrder = {}, {}
    for i, r in ipairs(self.records or {}) do
        local key = r.t .. "\0" .. (r.name or "")
        local g = bGroups[key]
        if not g then g = { t = r.t, name = r.name, indices = {} }; bGroups[key] = g; bOrder[#bOrder + 1] = key end
        g.indices[#g.indices + 1] = i
    end
    for _, key in ipairs(bOrder) do
        local g = bGroups[key]
        local n = #g.indices
        local name, tex, w = g.t, nil, 0
        local disp = instanceItem(g.t)
        if disp then name = disp:getName(); pcall(function() tex = disp:getTexture() end); w = cdItemWeight(disp) end
        if g.name then name = g.name end
        local label = (n > 1) and (name .. " (x" .. n .. ")") or name
        self.bagList:addItem(label, { index = g.indices[1], count = n, tex = tex, weight = w * n })
    end

    -- Lado do inventario: inventario vivo do player recursado nas bolsas vestidas / sub-containers; itens equipados,
    -- containers e a propria cangalha sao filtrados, depois itens identicos sao agrupados.
    self.invList:clear()
    local player = getSpecificPlayer(self.playerNum) or getPlayer()
    local inv = player and player:getInventory()
    if inv then
        local depositable = {}
        collectDepositable(inv, depositable, 0)
        local iGroups, iOrder = {}, {}
        for _, it in ipairs(depositable) do
            local key = it:getFullType()
            local g = iGroups[key]
            if not g then
                local tex = nil; pcall(function() tex = it:getTexture() end)
                g = { items = {}, name = it:getName(), tex = tex, w = cdItemWeight(it) }
                iGroups[key] = g; iOrder[#iOrder + 1] = key
            end
            g.items[#g.items + 1] = it
        end
        for _, key in ipairs(iOrder) do
            local g = iGroups[key]
            local n = #g.items
            local label = (n > 1) and (g.name .. " (x" .. n .. ")") or g.name
            self.invList:addItem(label, { item = g.items[1], count = n, tex = g.tex, weight = g.w * n })
        end
    end
end

function ISCDBagWindow:setData(cap, records)
    self.cap = cap or self.cap or 0
    self.records = records or {}
    self:refresh()
end

function ISCDBagWindow:close()
    CD.UI.persist(self)
    CD.BagWindow.instance = nil
    ISCollapsableWindow.close(self)
    self:removeFromUIManager()
end

-- A abertura e dirigida por request: pergunta ao server; a resposta "bagdata" cria/atualiza a janela (entao menu de
-- contexto, radial e qualquer botao futuro so chamam isso).
function CD.openBagWindow(animal)
    if not animal then return end
    CD.BagWindow = CD.BagWindow or {}
    CD.BagWindow.liveAnimal = animal   -- mantem a ref viva: getAnimal(onlineID) retorna nil no single player
    CD.request("bagopen", animal)
end

function CD.BagWindow.onData(args)
    if not args or not args.id then return end
    local animal = getAnimal(args.id) or CD.BagWindow.liveAnimal
    local w = CD.BagWindow.instance
    if not w then
        w = ISCDBagWindow:new(0, 0, 800, 580)
        w:initialise()
        w:instantiate()
        CD.UI.applyOpenGeometry(w, "bag", 800, 580)
        w:addToUIManager()
        CD.BagWindow.instance = w
    end
    w.animal = animal
    w.animalId = args.id
    w:setData(args.cap, args.items)
    w:setVisible(true)
    w:bringToTop()
end
