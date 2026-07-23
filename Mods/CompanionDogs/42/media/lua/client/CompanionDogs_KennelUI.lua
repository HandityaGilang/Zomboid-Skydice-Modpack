require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISUI3DModel"
require "ISUI/ISCollapsableWindow"
require "ISUI/ISTextEntryBox"

-- Aba "Meus Caes" da janela unificada do cao (ISCDStatusWindow): lista TODOS os caes vinculados do player
-- (pd.companions + pd.kennel, transmitidos pelo server) com estado de alcance e acoes por cao. Cada linha e um
-- painel com retrato ao estilo do trailer de animais vanilla: cao carregado na cell = avatar 3D ao vivo
-- (ISUI3DModel, sem drag-rotate); cao longe/perdido/no colo/no veiculo = retrato estatico por raca
-- (CDPortrait_<raca>.png) com fallback pro icone da patinha. O Trazer funciona mesmo com o cao
-- descarregado/perdido: vivo na cell vai pelo teleport normal; senao pede o recall por TOKEN
-- (CD.Server.recall respawna do snapshot do canil).
local CD = CompanionDogs

ISCDKennelView = ISPanel:derive("ISCDKennelView")
ISCDKennelScroll = ISPanel:derive("ISCDKennelScroll")
ISCDKennelRow = ISPanel:derive("ISCDKennelRow")
ISCDDogAvatar = ISUI3DModel:derive("ISCDDogAvatar")

local PAD = 8
local ROW_H = 120
local AV_PAD = 4
local BTN_H = 22
local REFRESH_TICKS = 20

local C_NEAR = { r = 0.55, g = 0.85, b = 0.45 }
local C_WITH = { r = 1.00, g = 0.65, b = 0.10 }
local C_LOST = { r = 0.92, g = 0.28, b = 0.22 }
local C_FAR  = { r = 0.70, g = 0.70, b = 0.70 }

-- Nivel derivado do XP cumulativo (mesma curva triangular de CD.getSkillLevel, que exige um animal vivo).
local function cdLevelFromXp(xp)
    xp = tonumber(xp) or 0
    local level, need = 0, 0
    while level < (CD.SKILL_MAX_LEVEL or 10) do
        need = need + (CD.SKILL_XP_BASE or 20) * (level + 1)
        if xp < need then break end
        level = level + 1
    end
    return level
end

local function cdSkillsSummary(animal, snapSkills)
    local parts = {}
    for _, s in ipairs(CD.SKILLS or {}) do
        local lv = 0
        if animal then
            pcall(function() lv = CD.getSkillLevel(animal, s) end)
        elseif type(snapSkills) == "table" then
            lv = cdLevelFromXp(snapSkills[s])
        end
        if lv > 0 then
            parts[#parts + 1] = getText("IGUI_PD_Skill_" .. s) .. " " .. tostring(lv)
        end
    end
    return table.concat(parts, "  ")
end

local function cdSexLabel(sex, isPup)
    if isPup then return getText("IGUI_PD_Puppy") end
    if sex == "female" then return getText("IGUI_PD_Sex_Female") end
    if sex == "male" then return getText("IGUI_PD_Sex_Male") end
    return nil
end

-- Minutos restantes do cooldown de chamada deste cao (nil = livre). Mesmo relogio/constante do server.
local function cdRecallWait(snap)
    if not (snap and snap.recallAtMin) then return nil end
    local rem = (CD.KENNEL_RECALL_COOLDOWN_MIN or 120) - ((CD.worldMinutes() or 0) - snap.recallAtMin)
    if rem > 0 then return rem end
    return nil
end

local function cdCooldownLabel(mins)
    if mins >= 60 then
        return getText("IGUI_PD_KennelRecallIn", tostring(math.ceil(mins / 60)) .. "h")
    end
    return getText("IGUI_PD_KennelRecallIn", tostring(math.max(1, math.ceil(mins))) .. "min")
end

-- "visto ha Xh/Xd" a partir do timestamp do snapshot (minutos de mundo, sincronizados em MP).
local function cdLastSeen(savedAtMin)
    if not savedAtMin then return nil end
    local mins = math.max(0, (CD.worldMinutes() or 0) - savedAtMin)
    local hours = math.floor(mins / 60)
    if hours >= 48 then
        return getText("IGUI_PD_KennelLastSeenDays", tostring(math.floor(hours / 24)))
    end
    if hours < 1 then hours = 1 end
    return getText("IGUI_PD_KennelLastSeen", tostring(hours))
end

local function cdFitText(font, txt, maxW)
    if getTextManager():MeasureStringX(font, txt) <= maxW then return txt end
    local s = txt
    while #s > 1 and getTextManager():MeasureStringX(font, s .. "...") > maxW do
        s = string.sub(s, 1, #s - 1)
    end
    return s .. "..."
end

-- Retrato estatico por raca pro cao sem IsoAnimal carregado; cai na patinha enquanto a arte nao existir.
local portraitCache = {}
local function cdPortrait(breedKey)
    breedKey = breedKey or "default"
    local tex = portraitCache[breedKey]
    if tex == nil then
        tex = getTexture("media/textures/CDPortrait_" .. breedKey .. ".png")
            or getTexture("media/textures/CDDogPaw_48.png")
            or false
        portraitCache[breedKey] = tex
    end
    return tex or nil
end

-- ===================== avatar 3D (padrao ISVehicleAnimal3DModel do trailer) =====================

function ISCDDogAvatar:instantiate()
    ISUI3DModel.instantiate(self)
    self:setIsometric(false)
end

-- clique atravessa pro painel da linha; sem drag-rotate
function ISCDDogAvatar:onMouseDown() return false end
function ISCDDogAvatar:onMouseMove() return false end
function ISCDDogAvatar:onMouseMoveOutside() return false end
function ISCDDogAvatar:onMouseUp() return false end
function ISCDDogAvatar:onMouseUpOutside() return false end

-- setCharacter SO quando o animal resolvido muda (nunca por frame; churn de re-apply ja causou bugs no mod).
function ISCDDogAvatar:bindAnimal(animal)
    if self.boundAnimal == animal then return end
    self.boundAnimal = animal
    if animal then
        pcall(function()
            self:setAnimSetName(animal:GetAnimSetName())
            self:setCharacter(animal)
            self:setState("idle")
        end)
        self:setVisible(true)
    else
        self:setVisible(false)
    end
end

-- Enquadramento por frame (zoom/offset escalam com o tamanho vivo do animal), como o trailer vanilla faz.
function ISCDDogAvatar:applyFrame()
    local animal = self.boundAnimal
    if not animal then return end
    pcall(function()
        local def = AnimalAvatarDefinition[animal:getAnimalType()]
        if not def then return end
        local size = animal:getData():getSize()
        self:setZoom((def.trailerZoom + (self.zoomAdd or 0)) * size)
        self:setXOffset(def.trailerXoffset * size)
        self:setYOffset(def.trailerYoffset * size)
        self:setDirection(def.trailerDir)
        self:setVariable("TrailerAnimation", "idle1")
    end)
end

-- ===================== painel de linha =====================

function ISCDKennelRow:new(x, y, w, h)
    local o = ISPanel.new(self, x, y, w, h)
    o.background = false
    return o
end

function ISCDKennelRow:createChildren()
    local s = self.height - AV_PAD * 2
    self.avatar = ISCDDogAvatar:new(AV_PAD, AV_PAD, s, s)
    self.avatar:initialise()
    self:addChild(self.avatar)
    self.avatar:setVisible(false)
end

function ISCDKennelRow:onMouseDown(x, y)
    if self.kennelView and self.rowData then
        self.kennelView.selectedToken = self.rowData.token
    end
    return true
end

function ISCDKennelRow:prerender()
    local r = self.rowData
    if not r then return end
    local w, h = self.width, self.height
    local kv = self.kennelView

    if self.altRow then self:drawRect(0, 0, w, h, 0.06, 1, 1, 1) end
    if kv and kv.selectedToken == r.token then
        self:drawRect(0, 0, w, h - 1, 0.30, 0.20, 0.40, 0.60)
        self:drawRectBorder(0, 0, w, h - 1, 0.6, 0.35, 0.55, 0.80)
    elseif self:isMouseOver() then
        self:drawRect(0, 0, w, h - 1, 0.08, 1, 1, 1)
    end

    -- celula do retrato
    local s = h - AV_PAD * 2
    self:drawRectBorder(AV_PAD - 1, AV_PAD - 1, s + 2, s + 2, 1, 0.3, 0.3, 0.3)
    if kv and kv.avatarBg then
        self:drawTextureScaled(kv.avatarBg, AV_PAD, AV_PAD, s, s, 1, 0.4, 0.4, 0.4)
    end
    if self.avatar and self.avatar.boundAnimal then
        self.avatar:applyFrame()
    else
        local tex = cdPortrait(r.breedKey)
        if tex then
            self:drawTextureScaled(tex, AV_PAD + 4, AV_PAD + 4, s - 8, s - 8, 1, 1, 1, 1)
        end
    end

    -- textos em duas linhas centralizadas na altura da linha: nome + raca/sexo (esq.) e status colorido (dir.);
    -- embaixo skills e "visto ha"
    local font = UIFont.Small
    local fhh = getTextManager():getFontHeight(font)
    local tx = AV_PAD * 2 + s + 6
    local y1 = math.floor(h / 2) - fhh - 4
    local y2 = math.floor(h / 2) + 4

    local sw = getTextManager():MeasureStringX(font, r.statusText or "")
    self:drawText(r.statusText or "", w - sw - 6, y1, r.statusColor.r, r.statusColor.g, r.statusColor.b, 1, font)
    if r.active then
        local at = getTextManager():MeasureStringX(font, r.activeText)
        self:drawText(r.activeText, w - at - 6, y2, 0.55, 0.85, 0.45, 1, font)
    end

    local maxW = math.max(10, w - tx - sw - 12)
    self:drawText(cdFitText(font, r.title, maxW), tx, y1, 0.92, 0.92, 0.92, 1, font)
    if r.subText and r.subText ~= "" then
        self:drawText(cdFitText(font, r.subText, maxW), tx, y2, 0.62, 0.62, 0.62, 1, font)
    end

    self:drawRect(0, h - 1, w, 1, 0.25, 0.4, 0.4, 0.4)
end

-- ===================== area rolavel da lista =====================

function ISCDKennelScroll:new(x, y, w, h)
    local o = ISPanel.new(self, x, y, w, h)
    o.background = false
    return o
end

function ISCDKennelScroll:instantiate() CD.UI.viewInstantiate(self) end
function ISCDKennelScroll:onMouseWheel(del) return CD.UI.viewMouseWheel(self, del) end
function ISCDKennelScroll:prerender() CD.UI.viewBeginRender(self) end

function ISCDKennelScroll:render()
    local kv = self.kennelView
    if kv and #(kv.rowsData or {}) == 0 then
        local msg = getText("IGUI_PD_KennelEmpty")
        local mw = getTextManager():MeasureStringX(UIFont.Small, msg)
        self:drawText(msg, math.max(0, (self.width - mw) / 2), 20, 0.65, 0.65, 0.65, 1, UIFont.Small)
    end
    CD.UI.viewEndRender(self)
end

-- ===================== view da aba =====================

function ISCDKennelView:new(x, y, w, h)
    local o = ISPanel.new(self, x, y, w, h)
    o.background = false
    o.refreshTick = REFRESH_TICKS
    o.avatarBg = getTexture("media/ui/avatarBackgroundWhite.png")
    o.rowsData = {}
    o.rowPanels = {}
    return o
end

function ISCDKennelView:player()
    return getSpecificPlayer(self.playerNum or 0) or getPlayer()
end

function ISCDKennelView:createChildren()
    self.scroll = ISCDKennelScroll:new(PAD, PAD, math.max(20, self.width - PAD * 2), math.max(20, self.height - PAD * 3 - BTN_H))
    self.scroll.kennelView = self
    self:addChild(self.scroll)

    self.fetchBtn = ISButton:new(0, 0, 10, BTN_H, getText("IGUI_PD_CmdFetch"), self, ISCDKennelView.onFetch)
    self.fetchBtn:initialise()
    self:addChild(self.fetchBtn)
    self.statusBtn = ISButton:new(0, 0, 10, BTN_H, getText("IGUI_PD_Inspect"), self, ISCDKennelView.onStatus)
    self.statusBtn:initialise()
    self:addChild(self.statusBtn)
    self.selectBtn = ISButton:new(0, 0, 10, BTN_H, getText("IGUI_PD_KennelBtnSelect"), self, ISCDKennelView.onSelect)
    self.selectBtn:initialise()
    self:addChild(self.selectBtn)

    self:layout()
    self:refreshRows()
end

function ISCDKennelView:layout()
    if not self.scroll then return end
    local listH = self.height - PAD * 3 - BTN_H
    if listH < 60 then listH = 60 end
    local listW = self.width - PAD * 2
    if listW < 120 then listW = 120 end
    self.scroll:setX(PAD); self.scroll:setY(PAD)
    self.scroll:setWidth(listW); self.scroll:setHeight(listH)

    local btnY = PAD + listH + PAD
    local bw = math.floor((listW - PAD * 2) / 3)
    self.fetchBtn:setX(PAD); self.fetchBtn:setY(btnY); self.fetchBtn:setWidth(bw)
    self.statusBtn:setX(PAD * 2 + bw); self.statusBtn:setY(btnY); self.statusBtn:setWidth(bw)
    self.selectBtn:setX(PAD * 3 + bw * 2); self.selectBtn:setY(btnY); self.selectBtn:setWidth(bw)

    local cw = CD.UI.viewContentW(self.scroll)
    for _, rp in ipairs(self.rowPanels) do rp:setWidth(cw) end
    self.scroll:setScrollHeight(#self.rowsData * ROW_H)
end

-- Reconstroi as linhas a partir do ModData transmitido + um unico scan da cell pros caes carregados; os paineis
-- de linha sao poolados e re-vinculados (o avatar so re-aplica setCharacter quando o animal do token MUDA).
function ISCDKennelView:refreshRows()
    if not self.scroll then return end
    local player = self:player()
    if not player then return end
    local pd = CD.playerData(player)

    local tokens = {}
    if type(pd.companions) == "table" then for t in pairs(pd.companions) do tokens[t] = true end end
    if type(pd.kennel) == "table" then for t in pairs(pd.kennel) do tokens[t] = true end end
    if pd.token ~= nil then tokens[pd.token] = true end

    local liveByToken = {}
    local cell = getCell()
    if cell then
        local list = cell:getAnimals()
        if list then
            for i = 0, list:size() - 1 do
                local a = list:get(i)
                if a and CD.isDog(a) and CD.isCompanion(a) and CD.isOwnedBy(a, player) and not a:isDead() then
                    local t = CD.data(a).companionToken
                    if t ~= nil then liveByToken[t] = a end
                end
            end
        end
    end
    local ctok = pd.carried and pd.carried.data and pd.carried.data.companionToken
    local stok = pd.stash and pd.stash.data and pd.stash.data.companionToken

    local rows = {}
    for t in pairs(tokens) do
        local snap = type(pd.kennel) == "table" and pd.kennel[t] or nil
        local animal = liveByToken[t]
        local d = animal and CD.data(animal) or nil
        local pos = type(pd.dogPositions) == "table" and pd.dogPositions[t] or nil
        local name = (d and d.name) or (snap and snap.name) or (pos and pos.name)
        local breedKey = (d and d.breed) or (snap and snap.breed)
        local sex = (d and (d.sex or CD.animalSex(animal))) or (snap and snap.sex)
        local isPup = (d and d.isPup) or (snap and snap.isPup)

        local breedNoun = CD.breedNounFromKey and CD.breedNounFromKey(breedKey) or getText("IGUI_PD_DogDefaultName")
        local title = breedNoun
        local sexLabel = cdSexLabel(sex, isPup)
        if sexLabel then title = title .. " (" .. sexLabel .. ")" end
        if name and name ~= "" then title = name .. "  -  " .. title end

        local statusText, statusColor, lastSeen
        if animal then
            statusText, statusColor = getText("IGUI_PD_KennelStatusNear"), C_NEAR
            local badge = CD.statusBadge and CD.statusBadge(animal)
            if badge then statusText = statusText .. " · " .. getText(badge.key) end
        elseif t == ctok then
            statusText, statusColor = getText("IGUI_PD_KennelStatusCarried"), C_WITH
        elseif t == stok then
            statusText, statusColor = getText("IGUI_PD_InVehicleBanner"), C_WITH
        elseif snap and snap.lost then
            statusText, statusColor = getText("IGUI_PD_KennelStatusLost"), C_LOST
            lastSeen = cdLastSeen(snap.savedAtMin)
        elseif snap then
            statusText, statusColor = getText("IGUI_PD_KennelStatusFar"), C_FAR
            lastSeen = cdLastSeen(snap.savedAtMin)
        else
            statusText, statusColor = getText("IGUI_PD_KennelStatusNoData"), C_FAR
        end

        local sub = cdSkillsSummary(animal, snap and snap.skills)
        if lastSeen then sub = (sub ~= "" and (sub .. "  ·  ") or "") .. lastSeen end
        local recallWait = cdRecallWait(snap)
        if recallWait then sub = (sub ~= "" and (sub .. "  ·  ") or "") .. cdCooldownLabel(recallWait) end

        rows[#rows + 1] = {
            token = t, animal = animal, snap = snap, breedKey = breedKey,
            recallWait = recallWait,
            withYou = (t == ctok or t == stok),   -- ja esta com o player; recall duplicaria (server recusa, client nem oferece)
            title = title, subText = sub,
            statusText = statusText, statusColor = statusColor,
            active = (t == pd.token), activeText = getText("IGUI_PD_KennelActive"),
            sortName = name or breedNoun,
        }
    end

    table.sort(rows, function(a, b)
        if a.active ~= b.active then return a.active end
        if (a.animal ~= nil) ~= (b.animal ~= nil) then return a.animal ~= nil end
        if a.sortName ~= b.sortName then return a.sortName < b.sortName end
        return a.token < b.token
    end)

    self.rowsData = rows
    if self.selectedToken ~= nil then
        local found = false
        for _, r in ipairs(rows) do
            if r.token == self.selectedToken then found = true; break end
        end
        if not found then self.selectedToken = nil end
    end

    local cw = CD.UI.viewContentW(self.scroll)
    for i, r in ipairs(rows) do
        local rp = self.rowPanels[i]
        if not rp then
            rp = ISCDKennelRow:new(0, (i - 1) * ROW_H, cw, ROW_H)
            rp.kennelView = self
            rp:initialise()
            self.scroll:addChild(rp)
            self.rowPanels[i] = rp
        end
        rp.rowData = r
        rp.altRow = (i % 2 == 0)
        rp:setY((i - 1) * ROW_H)
        rp:setWidth(cw)
        rp:setVisible(true)
        rp.avatar:bindAnimal(r.animal)
    end
    for i = #rows + 1, #self.rowPanels do
        local rp = self.rowPanels[i]
        rp.rowData = nil
        rp:setVisible(false)
        rp.avatar:bindAnimal(nil)
    end
    self.scroll:setScrollHeight(#rows * ROW_H)
end

function ISCDKennelView:selectedRow()
    if self.selectedToken == nil then return nil end
    for _, r in ipairs(self.rowsData or {}) do
        if r.token == self.selectedToken then return r end
    end
    return nil
end

function ISCDKennelView:prerender()
    self.refreshTick = (self.refreshTick or 0) + 1
    if self.refreshTick >= REFRESH_TICKS then
        self.refreshTick = 0
        self:refreshRows()
    end
    local row = self:selectedRow()
    self.fetchBtn:setEnable(row ~= nil and row.recallWait == nil
        and (row.animal ~= nil or (row.snap ~= nil and not row.withYou)))
    self.statusBtn:setEnable(row ~= nil and row.animal ~= nil)
    self.selectBtn:setEnable(row ~= nil and row.animal ~= nil and not row.active)
end

function ISCDKennelView:render()
    if self.scroll then
        self:drawRectBorder(self.scroll.x, self.scroll.y, self.scroll.width, self.scroll.height, 0.5, 0.4, 0.4, 0.4)
    end
end

local function cdCallout(player)
    if not player then return end
    pcall(function()
        player:playEmote("comehere")
        player:Callout(false)
    end)
end

function ISCDKennelView:onRecallConfirm(button)
    if button.internal ~= "YES" then return end
    local tok = self.pendingRecallToken
    self.pendingRecallToken = nil
    if tok == nil then return end
    cdCallout(self:player())
    CD.requestStashed("recall", { token = tok })
end

function ISCDKennelView:onFetch()
    local row = self:selectedRow()
    if not row or row.recallWait then return end
    if row.animal then
        cdCallout(self:player())
        CD.request("teleport", row.animal)
        return
    end
    if not row.snap or row.withYou then return end
    -- Recall de longe respawna do canil: confirma (o assobio alto atrai zumbis, mesmo custo do Trazer).
    self.pendingRecallToken = row.token
    local modal = ISModalDialog:new(0, 0, 340, 140,
        getText("IGUI_PD_KennelRecallConfirm", row.sortName), true, self, ISCDKennelView.onRecallConfirm, self.playerNum or 0)
    modal:initialise()
    modal:addToUIManager()
end

-- Troca o cao-alvo da janela: fecha e reabre mirando o cao da linha, ja na aba Status.
function ISCDKennelView:onStatus()
    local row = self:selectedRow()
    if row and row.animal and ISCDStatusWindow and ISCDStatusWindow.OpenFor then
        ISCDStatusWindow.OpenFor(row.animal, "status")
    end
end

function ISCDKennelView:onSelect()
    local row = self:selectedRow()
    if row and row.animal then
        CD.request("select", row.animal)
    end
end

-- ===================== janela admin: registro global de donos e caes =====================
-- Aberta pelo submenu de debug do context menu (gate CD.debugAllowed). Pede ao server o canil global inteiro
-- (CD.Server.kenneladmin) e lista dono -> caes em texto simples; Refresh repede, Log imprime no console
-- (triagem de tickets fora do jogo). Mora neste arquivo (ja carregado) pra nao criar .lua novo.

ISCDAdminKennelWindow = ISCollapsableWindow:derive("ISCDAdminKennelWindow")
ISCDAdminKennelScroll = ISPanel:derive("ISCDAdminKennelScroll")

local ADM_ROW_H = 18
local ADM_MIN_W, ADM_MIN_H = 360, 220
local ADM_DEF_W, ADM_DEF_H = 480, 380

-- Status compacto de um cao do payload: Missing, senao "visto ha Xh" + coordenadas do ultimo snapshot.
local function cdAdminStatus(dog, now)
    if dog.lost then return getText("IGUI_PD_KennelStatusLost"), true end
    local s = ""
    if dog.savedAtMin and now then
        local hrs = math.max(0, math.floor((now - dog.savedAtMin) / 60 + 0.5))
        s = getText("IGUI_PD_KennelLastSeen", tostring(hrs))
    end
    if dog.x then
        local coord = "(" .. tostring(dog.x) .. "," .. tostring(dog.y) .. "," .. tostring(dog.z or 0) .. ")"
        s = (s ~= "" and (s .. "  ") or "") .. coord
    end
    return s, false
end

function ISCDAdminKennelScroll:instantiate() CD.UI.viewInstantiate(self) end
function ISCDAdminKennelScroll:onMouseWheel(del) return CD.UI.viewMouseWheel(self, del) end
function ISCDAdminKennelScroll:prerender() CD.UI.viewBeginRender(self) end

function ISCDAdminKennelScroll:render()
    local win = self.adminWin
    local lines = (win and win.lines) or {}
    if #lines == 0 then
        local msg = getText((win and win.waiting) and "IGUI_PD_AdminKennelWait" or "IGUI_PD_AdminKennelEmpty")
        local mw = getTextManager():MeasureStringX(UIFont.Small, msg)
        self:drawText(msg, math.max(0, (self.width - mw) / 2), 20, 0.65, 0.65, 0.65, 1, UIFont.Small)
    else
        local y = 4
        for _, ln in ipairs(lines) do
            self:drawText(ln.text, 6 + (ln.lvl or 0) * 16, y, ln.r, ln.g, ln.b, 1, UIFont.Small)
            y = y + ADM_ROW_H
        end
    end
    CD.UI.viewEndRender(self)
end

function ISCDAdminKennelWindow:new(x, y, w, h)
    local o = ISCollapsableWindow.new(self, x, y, w, h)
    o.title = getText("IGUI_PD_AdminKennelTitle")
    o.lines = {}
    o.data = nil
    o.lastFilter = ""
    o.waiting = true
    return o
end

function ISCDAdminKennelWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    self.searchLbl = getText("IGUI_PD_AdminSearch")
    self.searchLblW = getTextManager():MeasureStringX(UIFont.Small, self.searchLbl)
    self.searchEntry = ISTextEntryBox:new("", 0, 0, 10, BTN_H)
    self.searchEntry:initialise()
    self.searchEntry:instantiate()
    self:addChild(self.searchEntry)
    self.scroll = ISCDAdminKennelScroll:new(PAD, self:titleBarHeight() + PAD, 20, 20)
    self.scroll.adminWin = self
    self:addChild(self.scroll)
    self.refreshBtn = ISButton:new(0, 0, 10, BTN_H, getText("IGUI_PD_AdminRefresh"), self, ISCDAdminKennelWindow.onRefresh)
    self.refreshBtn:initialise()
    self:addChild(self.refreshBtn)
    self.logBtn = ISButton:new(0, 0, 10, BTN_H, getText("IGUI_PD_AdminLog"), self, ISCDAdminKennelWindow.onLog)
    self.logBtn:initialise()
    self:addChild(self.logBtn)
    CD.UI.initResizable(self, "dogadmin", ADM_MIN_W, ADM_MIN_H)
    self:reflow()
end

function ISCDAdminKennelWindow:reflow()
    if not self.scroll then return end
    local top = self:titleBarHeight()
    local rh = self:resizeWidgetHeight()
    local rowY = top + PAD
    local lblW = self.searchLblW or 60
    if self.searchEntry then
        self.searchEntry:setX(PAD + lblW + 6); self.searchEntry:setY(rowY)
        self.searchEntry:setWidth(math.max(80, self.width - PAD * 2 - lblW - 6))
        self.searchEntry:setHeight(BTN_H)
    end
    local listY = rowY + BTN_H + PAD
    local listW = math.max(120, self.width - PAD * 2)
    local listH = math.max(60, self.height - listY - PAD * 2 - BTN_H - rh)
    self.scroll:setX(PAD); self.scroll:setY(listY)
    self.scroll:setWidth(listW); self.scroll:setHeight(listH)
    self.scroll:setScrollHeight(#self.lines * ADM_ROW_H + 8)
    local btnY = listY + listH + PAD
    local bw = math.floor((listW - PAD) / 2)
    self.refreshBtn:setX(PAD); self.refreshBtn:setY(btnY); self.refreshBtn:setWidth(bw)
    self.logBtn:setX(PAD * 2 + bw); self.logBtn:setY(btnY); self.logBtn:setWidth(bw)
end

-- Rotulo do campo de busca + filtro reativo: reconstroi as linhas quando o texto digitado muda.
function ISCDAdminKennelWindow:render()
    ISCollapsableWindow.render(self)
    if self.searchEntry and not self.isCollapsed then
        self:drawText(self.searchLbl or "", PAD, self.searchEntry:getY() + 4, 0.75, 0.75, 0.75, 1, UIFont.Small)
    end
end

function ISCDAdminKennelWindow:prerender()
    ISCollapsableWindow.prerender(self)
    local f = ""
    if self.searchEntry then pcall(function() f = self.searchEntry:getText() or "" end) end
    if f ~= self.lastFilter then
        self.lastFilter = f
        self:rebuildLines()
    end
end

-- Reconstroi as linhas visiveis do ultimo payload, filtrando donos pelo texto da busca (nome OU chave,
-- case-insensitive). Cada cao mostra nome/raca/sexo/status e uma sub-linha com as skills do snapshot.
function ISCDAdminKennelWindow:rebuildLines()
    local lines = {}
    local data = self.data
    if data then
        local filter = tostring(self.lastFilter or ""):lower()
        for _, o in ipairs(data.owners) do
            local oname = tostring(o.name or o.key or "?")
            if filter == "" or oname:lower():find(filter, 1, true) or tostring(o.key or ""):lower():find(filter, 1, true) then
                local dogs = type(o.dogs) == "table" and o.dogs or {}
                local label = oname
                if o.name and o.key and o.name ~= o.key then label = label .. " (" .. tostring(o.key) .. ")" end
                label = label .. "  [" .. getText(o.online and "IGUI_PD_AdminOnline" or "IGUI_PD_AdminOffline") .. "]"
                    .. "  -  " .. getText("IGUI_PD_AdminDogCount", tostring(#dogs))
                lines[#lines + 1] = { text = label, r = 0.95, g = 0.88, b = 0.55, lvl = 0 }
                for _, dog in ipairs(dogs) do
                    local noun = (CD.breedNounFromKey and CD.breedNounFromKey(dog.breed)) or tostring(dog.breed or "?")
                    local title = noun
                    local sexLabel = cdSexLabel(dog.sex, dog.isPup)
                    if sexLabel then title = title .. " (" .. sexLabel .. ")" end
                    if dog.name and dog.name ~= "" then title = tostring(dog.name) .. "  -  " .. title end
                    local st, isLost = cdAdminStatus(dog, data.now)
                    if st ~= "" then title = title .. "   " .. st end
                    if isLost then
                        lines[#lines + 1] = { text = title, r = C_LOST.r, g = C_LOST.g, b = C_LOST.b, lvl = 1 }
                    else
                        lines[#lines + 1] = { text = title, r = 0.82, g = 0.82, b = 0.82, lvl = 1 }
                    end
                    local sk = cdSkillsSummary(nil, dog.skills)
                    if sk ~= "" then
                        lines[#lines + 1] = { text = sk, r = 0.58, g = 0.68, b = 0.80, lvl = 2 }
                    end
                end
            end
        end
    end
    self.lines = lines
    self:reflow()
end

function ISCDAdminKennelWindow:onRefresh()
    self.waiting = true
    self.lines = {}
    self:reflow()
    pcall(function() CD.request("kenneladmin", nil, {}) end)
end

function ISCDAdminKennelWindow:onLog()
    print("[CompanionDogs] admin dog registry dump:")
    for _, ln in ipairs(self.lines or {}) do
        print(string.rep("    ", ln.lvl or 0) .. ln.text)
    end
end

function ISCDAdminKennelWindow:close()
    CD.UI.persist(self)
    ISCollapsableWindow.close(self)
    self:removeFromUIManager()
    if ISCDAdminKennelWindow.instance == self then ISCDAdminKennelWindow.instance = nil end
end

function CD.onKennelAdminList(payload)
    local win = ISCDAdminKennelWindow.instance
    if not win then return end
    win.waiting = false
    local owners = (type(payload) == "table" and type(payload.owners) == "table") and payload.owners or {}
    table.sort(owners, function(a, b)
        return tostring(a.name or a.key or ""):lower() < tostring(b.name or b.key or ""):lower()
    end)
    for _, o in ipairs(owners) do
        if type(o.dogs) == "table" then
            table.sort(o.dogs, function(a, b) return tostring(a.name or ""):lower() < tostring(b.name or ""):lower() end)
        end
    end
    win.data = { owners = owners, now = (type(payload) == "table") and payload.now or nil }
    win:rebuildLines()
end

function CD.openAdminKennel(playerObj)
    if ISCDAdminKennelWindow.instance then ISCDAdminKennelWindow.instance:close() end
    local win = ISCDAdminKennelWindow:new(0, 0, ADM_DEF_W, ADM_DEF_H)
    win:initialise()
    win:instantiate()
    CD.UI.applyOpenGeometry(win, "dogadmin", ADM_DEF_W, ADM_DEF_H)
    win:addToUIManager()
    ISCDAdminKennelWindow.instance = win
    pcall(function() CD.request("kenneladmin", nil, {}) end)
end
