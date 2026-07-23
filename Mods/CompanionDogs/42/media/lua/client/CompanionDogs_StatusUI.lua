require "ISUI/ISCollapsableWindow"
require "ISUI/ISButton"
require "ISUI/ISEquippedItem"
require "ISUI/ISTextBox"
require "ISUI/ISModalDialog"
require "ISUI/ISContextMenu"
require "ISUI/ISTabPanel"

local CD = CompanionDogs

-- O "menu" do cachorro: uma janela redimensionavel (ISCDStatusWindow) no estilo da tela de info do player:
-- cabecalho fixo (avatar 3D + nome + raca + selo) e um ISTabPanel com uma aba por categoria. Com cao-alvo
-- (vivo ou proxy do veiculo) monta as 4 abas: Skills and Status (lealdade/necessidades/skills/genes), Comandos,
-- Meus Caes e Configuracoes; sem cao (fallback da patinha com vinculo) monta so Meus Caes + Configuracoes. Cada
-- aba e um viewport rolavel proprio (padrao CD.UI); a geometria e a ultima aba persistem via CD.Settings.

-- Enquanto o dono dirige, o companheiro e DELETADO do mundo (animais sempre renderizam) e seu estado completo
-- fica preservado em pd.stash no player (sincronizado com o client). Esse proxy deixa a janela de status ler esse
-- snapshot pelos MESMOS getters que ela usa num cachorro vivo: getModData() sustenta todo helper baseado em
-- CD.data(a) (loyalty/stress/badge/state/alertMode/skills/genes), e os tres getters de necessidade retornam os
-- valores congelados. Sempre re-resolve pd.stash a partir do dono (transmitModData substitui a tabela no MP), entao
-- mutacoes de feed/rename aparecem no proximo frame. isExistInTheWorld e true para o render nao fechar sozinho; o
-- ramo stashed do render cuida de fechar ao desmontar.
local function makeStashProxy(owner)
    local md = {}
    local function rec() return CD.playerData(owner).stash end
    return {
        getModData = function()
            local r = rec()
            md.CompanionDogs = (r and r.data) or {}
            return md
        end,
        getHunger = function() local r = rec(); return (r and r.hunger) or 0 end,
        getThirst = function() local r = rec(); return (r and r.thirst) or 0 end,
        getHealth = function() local r = rec(); return (r and r.hp) or 1 end,
        isExistInTheWorld = function() return true end,
    }
end

-- Mesma elegibilidade/escopo do feed/water do menu de contexto (listFoods/findWater em CompanionDogs_ContextMenu).
-- Duplicado como locais no mesmo arquivo de proposito (os originais sao file-locals la; isso segue a convencao de
-- file-local da base de codigo e evita um require entre arquivos).
local function cdEachCarriedItem(container, fn)
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        fn(item)
        if instanceof(item, "InventoryContainer") then
            local inner = item:getInventory()
            if inner then cdEachCarriedItem(inner, fn) end
        end
    end
end

local function cdListFoods(playerObj)
    local groups, order = {}, {}
    cdEachCarriedItem(playerObj:getInventory(), function(item)
        if instanceof(item, "Food") and not item:isRotten() and item:getHungerChange() < 0 then
            local key = item:getFullType()
            local g = groups[key]
            if g then
                g.count = g.count + 1
            else
                g = { item = item, count = 1, name = item:getName(), bad = CD.isBadDogFood(item) }
                groups[key] = g
                order[#order + 1] = g
            end
        end
    end)
    table.sort(order, function(a, b) return a.name < b.name end)
    return order
end

-- Para agua nao importa de qual fonte ela vem, entao usa a primeira disponivel (igual ao findWater do menu de
-- contexto fora do veiculo, sem seletor). getAllWaterFluidSources nao recursa em bags, entao desce nelas.
local function cdFirstWaterIn(container)
    local list = container:getAllWaterFluidSources(true)
    if list and list:size() > 0 then return list:get(0) end
    local items = container:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if instanceof(item, "InventoryContainer") then
            local inner = item:getInventory()
            local found = inner and cdFirstWaterIn(inner)
            if found then return found end
        end
    end
    return nil
end

local function cdFirstWater(playerObj)
    return cdFirstWaterIn(playerObj:getInventory())
end

ISCDStatusWindow = ISCollapsableWindow:derive("ISCDStatusWindow")
ISCDTabView = ISPanel:derive("ISCDTabView")
ISCDStatusView = ISCDTabView:derive("ISCDStatusView")
ISCDCommandsView = ISCDTabView:derive("ISCDCommandsView")
ISCDLockedView = ISCDTabView:derive("ISCDLockedView")

local HEART_FULL = "media/ui/Sidebar/48/Heart_On_48.png"
local HEART_EMPTY = "media/ui/Sidebar/48/Heart_Off_48.png"
local HEART_COUNT = 5
local HEART_SIZE = 22
local HEART_GAP = 5

local WIN_W = 480
local MIN_W = 340
local MIN_H = 240
local PAD = 16
local SECT_GAP = 14
local ROW_GAP = 7
local DIVIDER_GAP = 12
local BTN_H = 28
local BTN_GAP = 8

-- cabecalho fixo entre a barra de titulo e as abas
local HDR_H = 124
local HDR_PAD = 10
local HDR_AV = 112

-- abas compactas: o ISTabPanel crava UIFont.Small; usamos NewSmall desenhada ESCALADA (drawTextZoomed) SO no
-- nosso painel, pois o enum de fontes nao vai abaixo do NewSmall. TAB_ZOOM=0.5 = metade do tamanho da fonte.
local TAB_FONT = UIFont.NewSmall
local TAB_ZOOM = 0.90
local TAB_H_PAD = 8

local NEED_BAR_H = 14
local NEED_LABEL_W = 86
local NEED_VALUE_W = 42

local SKILL_BAR_H = 15
local SKILL_LABEL_W = 96
local SKILL_CELLS = 10
local SKILL_CELL_GAP = 3
local SKILL_TIP_W = 224

local TRAIT_BAR_H = 11
local TRAIT_LABEL_W = 116
local TRAIT_WORD_W = 60

local LBL = { r = 0.78, g = 0.80, b = 0.78 }
local DIV = { r = 1.0, g = 1.0, b = 1.0, a = 0.14 }
local BAR_BG = { r = 0.10, g = 0.10, b = 0.10, a = 0.85 }
local SKILL_FILL = { r = 0.45, g = 0.66, b = 0.40 }
local SKILL_PROG = { r = 0.62, g = 0.78, b = 0.55 }
local CELL_BG = { r = 0.09, g = 0.09, b = 0.09 }
local TRAIT_FILL = { r = 0.55, g = 0.62, b = 0.40 }

local function fh(font) return getTextManager():getFontHeight(font) end
local function strW(font, s) return getTextManager():MeasureStringX(font, s) end
local function lerp(a, b, t) return a + (b - a) * t end

local function cdLoadPaw(w)
    return getTexture("media/textures/CDDogPaw_" .. w .. ".png")
        or getTexture("media/ui/CompanionDogs/Paw_" .. w .. ".png")
        or getTexture("CDDogPaw_" .. w)
end

local function severityColor(sev)
    if sev < 0 then sev = 0 elseif sev > 1 then sev = 1 end
    if sev < 0.5 then
        local t = sev / 0.5
        return lerp(0.40, 0.85, t), lerp(0.70, 0.72, t), lerp(0.34, 0.28, t)
    end
    local t = (sev - 0.5) / 0.5
    return lerp(0.85, 0.80, t), lerp(0.72, 0.27, t), lerp(0.28, 0.24, t)
end

local function wrapText(font, text, maxW)
    local lines = {}
    local line = ""
    for word in string.gmatch(text or "", "%S+") do
        local test = (line == "") and word or (line .. " " .. word)
        if line ~= "" and strW(font, test) > maxW then
            lines[#lines + 1] = line
            line = word
        else
            line = test
        end
    end
    if line ~= "" then lines[#lines + 1] = line end
    return lines
end

-- Tooltip, limitada a faixa VISIVEL do viewport rolado (topo em espaco de conteudo = -getYScroll()).
local function renderTip(win, lines, mx, my)
    local font = UIFont.Small
    local fhs = fh(font)
    local pad = 8
    local w = 0
    for _, l in ipairs(lines) do w = math.max(w, strW(font, l.t)) end
    w = w + pad * 2
    local h = #lines * fhs + pad * 2

    local visTop = -win:getYScroll()
    local visBot = visTop + win:getHeight()
    local tx = mx + 16
    local ty = my + 10
    if tx + w > win.width then tx = win.width - w - 2 end
    if tx < 2 then tx = 2 end
    if ty + h > visBot then ty = visBot - h - 2 end
    if ty < visTop then ty = visTop end

    win:drawRect(tx, ty, w, h, 0.93, 0.06, 0.06, 0.06)
    win:drawRectBorder(tx, ty, w, h, 0.85, 0.5, 0.5, 0.5)
    local ly = ty + pad
    for _, l in ipairs(lines) do
        if l.t ~= "" then win:drawText(l.t, tx + pad, ly, l.c[1], l.c[2], l.c[3], 1, font) end
        ly = ly + fhs
    end
end

-- ===================== base das views de aba (viewport rolavel) =====================

function ISCDTabView:new(x, y, w, h)
    local o = ISPanel.new(self, x, y, w, h)
    o.background = false
    o.heartOn = getTexture(HEART_FULL)
    o.heartOff = getTexture(HEART_EMPTY)
    return o
end

function ISCDTabView:instantiate() CD.UI.viewInstantiate(self) end
function ISCDTabView:onMouseWheel(del) return CD.UI.viewMouseWheel(self, del) end

function ISCDTabView:dogName()
    local name
    pcall(function() name = CD.data(self.animal).name end)
    return name or CD.breedNoun(self.animal)
end

function ISCDTabView:layout()
    local L = self:doLayout()
    self:setScrollHeight(L.contentH)
end

function ISCDTabView:prerender()
    CD.UI.viewBeginRender(self)
end

function ISCDTabView:render()
    self:drawContent()
    CD.UI.viewEndRender(self)
end

function ISCDTabView:makeBtn(w, text, onclick, internal)
    local b = ISButton:new(0, 0, w, BTN_H, text, self, onclick)
    b.internal = internal
    b:initialise()
    b:instantiate()
    b:setDisplayBackground(true)
    self:addChild(b)
    return b
end

function ISCDTabView:markActive(btn, active)
    if not btn then return end
    if active then
        btn:setBackgroundRGBA(0.24, 0.52, 0.30, 0.85)
        btn:setBorderRGBA(0.50, 0.85, 0.55, 1.0)
        btn.backgroundColorMouseOver = { r = 0.30, g = 0.62, b = 0.36, a = 0.95 }
    else
        btn:setBackgroundRGBA(0.10, 0.10, 0.10, 0.70)
        btn:setBorderRGBA(0.45, 0.45, 0.45, 0.70)
        btn.backgroundColorMouseOver = { r = 0.25, g = 0.25, b = 0.25, a = 0.85 }
    end
end

function ISCDTabView:drawDivider(y)
    local cw = CD.UI.viewContentW(self)
    self:drawRect(PAD, y, cw - PAD * 2, 1, DIV.a, DIV.r, DIV.g, DIV.b)
end

function ISCDTabView:drawNeedBar(label, y, fill, severity)
    local cw = CD.UI.viewContentW(self)
    local right = cw - PAD
    local sm = fh(UIFont.Small)
    local labelY = y + math.floor((NEED_BAR_H - sm) / 2)
    self:drawText(label, PAD, labelY, 0.92, 0.92, 0.92, 1, UIFont.Small)

    local valText = string.format("%d%%", math.floor(fill * 100 + 0.5))
    self:drawText(valText, right - strW(UIFont.Small, valText), labelY, 0.82, 0.82, 0.82, 1, UIFont.Small)

    local barX = PAD + NEED_LABEL_W
    local barW = (right - NEED_VALUE_W - 6) - barX
    if barW < 12 then barW = 12 end
    self:drawRect(barX, y, barW, NEED_BAR_H, BAR_BG.a, BAR_BG.r, BAR_BG.g, BAR_BG.b)
    self:drawRectBorder(barX, y, barW, NEED_BAR_H, 0.5, 0, 0, 0)
    local f = fill; if f < 0 then f = 0 elseif f > 1 then f = 1 end
    if f > 0 then
        local r, g, b = severityColor(severity)
        self:drawRect(barX + 1, y + 1, math.floor((barW - 2) * f), NEED_BAR_H - 2, 0.95, r, g, b)
    end
end

function ISCDTabView:drawSkillBar(label, y, level, into, need)
    local cw = CD.UI.viewContentW(self)
    local right = cw - PAD
    local sm = fh(UIFont.Small)
    local labelY = y + math.floor((SKILL_BAR_H - sm) / 2)
    self:drawText(label, PAD, labelY, 0.92, 0.92, 0.92, 1, UIFont.Small)

    local barX = PAD + SKILL_LABEL_W
    local barW = right - barX
    if barW < SKILL_CELLS then barW = SKILL_CELLS end
    local cellW = (barW - SKILL_CELL_GAP * (SKILL_CELLS - 1)) / SKILL_CELLS
    local frac = (need > 0) and (into / need) or 1
    if frac < 0 then frac = 0 elseif frac > 1 then frac = 1 end

    for i = 1, SKILL_CELLS do
        local cx = math.floor(barX + (i - 1) * (cellW + SKILL_CELL_GAP))
        local cw2 = math.floor(cellW + 0.5)
        self:drawRect(cx, y, cw2, SKILL_BAR_H, 0.85, CELL_BG.r, CELL_BG.g, CELL_BG.b)
        if i <= level then
            self:drawRect(cx, y, cw2, SKILL_BAR_H, 0.95, SKILL_FILL.r, SKILL_FILL.g, SKILL_FILL.b)
        elseif i == level + 1 and frac > 0 then
            self:drawRect(cx, y, math.max(1, math.floor(cw2 * frac)), SKILL_BAR_H, 0.95, SKILL_PROG.r, SKILL_PROG.g, SKILL_PROG.b)
        end
        self:drawRectBorder(cx, y, cw2, SKILL_BAR_H, 0.5, 0.55, 0.55, 0.55)
    end
end

function ISCDTabView:drawSkillTip(tip, mx, my)
    local font = UIFont.Small
    local title = getText("IGUI_PD_Skill_" .. tip.skill) .. "  " .. getText("IGUI_PD_SkillLevelFmt", tostring(tip.level))
    local xpLine
    if tip.level >= CD.SKILL_MAX_LEVEL then
        xpLine = "XP: MAX"
    else
        xpLine = string.format("XP: %d / %d", math.floor(tip.into), math.floor(tip.need))
    end

    local lines = { { t = title, c = { 1, 1, 1 } }, { t = xpLine, c = { 0.72, 0.82, 0.92 } } }
    if tip.mult and tip.mult ~= 1 then
        lines[#lines + 1] = { t = string.format("XP x%.1f", tip.mult), c = { 0.72, 0.82, 0.92 } }
    end
    lines[#lines + 1] = { t = "", c = { 1, 1, 1 } }
    local breedNoun = CD.breedNoun(self.animal)
    for _, l in ipairs(wrapText(font, getText("IGUI_PD_SkillDesc_" .. tip.skill, breedNoun), SKILL_TIP_W)) do
        lines[#lines + 1] = { t = l, c = { 0.84, 0.84, 0.84 } }
    end

    renderTip(self, lines, mx, my)
end

function ISCDTabView:drawInfoTip(title, body, mx, my)
    local font = UIFont.Small
    local lines = { { t = title, c = { 1, 1, 1 } }, { t = "", c = { 1, 1, 1 } } }
    for _, l in ipairs(wrapText(font, body, SKILL_TIP_W)) do
        lines[#lines + 1] = { t = l, c = { 0.84, 0.84, 0.84 } }
    end
    renderTip(self, lines, mx, my)
end

function ISCDTabView:drawTraitBar(label, y, ratio)
    local cw = CD.UI.viewContentW(self)
    local right = cw - PAD
    local sm = fh(UIFont.Small)
    local labelY = y + math.floor((TRAIT_BAR_H - sm) / 2)
    self:drawText(label, PAD, labelY, 0.92, 0.92, 0.92, 1, UIFont.Small)

    local wordKey = "IGUI_PD_TraitAvg"
    if ratio < 0.34 then wordKey = "IGUI_PD_TraitLow"
    elseif ratio > 0.66 then wordKey = "IGUI_PD_TraitHigh" end
    local word = getText(wordKey)
    self:drawText(word, right - strW(UIFont.Small, word), labelY, 0.78, 0.78, 0.78, 1, UIFont.Small)

    local barX = PAD + TRAIT_LABEL_W
    local barW = (right - TRAIT_WORD_W - 6) - barX
    if barW < 12 then barW = 12 end
    self:drawRect(barX, y, barW, TRAIT_BAR_H, BAR_BG.a, BAR_BG.r, BAR_BG.g, BAR_BG.b)
    self:drawRectBorder(barX, y, barW, TRAIT_BAR_H, 0.5, 0, 0, 0)
    if ratio > 0 then
        self:drawRect(barX + 1, y + 1, math.floor((barW - 2) * ratio), TRAIT_BAR_H - 2, 0.95, TRAIT_FILL.r, TRAIT_FILL.g, TRAIT_FILL.b)
    end
end

-- ===================== aba "Skills and Status" (lealdade + necessidades + skills + raca/genes) =====================

function ISCDStatusView:doLayout()
    local L = {}
    local sm = fh(UIFont.Small)
    local y = PAD

    L.loyaltyLabelY = y;    y = y + sm + ROW_GAP
    L.heartsY = y;          y = y + HEART_SIZE + SECT_GAP

    L.div1 = y;             y = y + 1 + DIVIDER_GAP

    L.needsLabelY = y;      y = y + sm + ROW_GAP
    L.needsY = y
    L.needRowH = math.max(sm, NEED_BAR_H) + ROW_GAP
    y = y + L.needRowH * 4 - ROW_GAP + SECT_GAP

    L.div2 = y;             y = y + 1 + DIVIDER_GAP

    L.skillsLabelY = y;     y = y + sm + ROW_GAP
    L.skillsY = y
    L.skillRowH = math.max(sm, SKILL_BAR_H) + ROW_GAP
    y = y + L.skillRowH * #CD.SKILLS - ROW_GAP + SECT_GAP

    L.div3 = y;             y = y + 1 + DIVIDER_GAP

    L.genomeLabelY = y;     y = y + sm + ROW_GAP
    L.breedRowY = y;        y = y + sm + ROW_GAP
    L.genomeY = y
    L.traitRowH = math.max(sm, TRAIT_BAR_H) + ROW_GAP
    y = y + L.traitRowH * 3 - ROW_GAP

    y = y + PAD
    L.contentH = y
    self.L = L
    return L
end

function ISCDStatusView:drawContent()
    local L = self.L
    if not L then return end
    local a = self.animal
    local breedNoun = CD.breedNoun(a)
    local cw = CD.UI.viewContentW(self)
    local x = PAD

    local over = self:isMouseOver() or self:isMouseOverChild()
    local mx, my = self:getMouseX(), self:getMouseY()
    local infoTip = nil
    local tip = nil
    local function hoverRow(y, h)
        return over and my >= y and my < y + h and mx >= PAD and mx <= cw - PAD
    end
    local function hoverRect(bx, y, w, h)
        return over and mx >= bx and mx < bx + w and my >= y and my < y + h
    end

    self:drawText(getText("IGUI_PD_LoyaltyLabel"), x, L.loyaltyLabelY, LBL.r, LBL.g, LBL.b, 1, UIFont.Small)
    local loyalty = 0
    pcall(function() loyalty = CD.loyalty(a) end)
    local maxL = CD.TRUST_MAX
    local filled = math.floor((loyalty / maxL) * HEART_COUNT + 0.5)
    if filled < 0 then filled = 0 elseif filled > HEART_COUNT then filled = HEART_COUNT end
    local hy = L.heartsY
    local hx = x
    for i = 1, HEART_COUNT do
        local tex = (i <= filled) and self.heartOn or self.heartOff
        self:drawTextureScaled(tex, hx, hy, HEART_SIZE, HEART_SIZE, 1, 1, 1, 1)
        hx = hx + HEART_SIZE + HEART_GAP
    end
    local numY = hy + (HEART_SIZE - fh(UIFont.Small)) / 2
    self:drawText(math.floor(loyalty) .. "/" .. maxL, hx + 8, numY, 1, 1, 1, 1, UIFont.Small)
    if hoverRow(L.loyaltyLabelY, (L.heartsY - L.loyaltyLabelY) + HEART_SIZE) then
        infoTip = { title = getText("IGUI_PD_LoyaltyLabel"), body = getText("IGUI_PD_LoyaltyDesc", breedNoun) }
    end

    self:drawDivider(L.div1)

    self:drawText(getText("IGUI_PD_NeedsLabel"), x, L.needsLabelY, LBL.r, LBL.g, LBL.b, 1, UIFont.Small)
    local hunger, thirst, health, stress = 0, 0, 1, 0
    -- Enquanto o GOD_MODE do guarda de arma de fogo esta ligado (player mirando por perto), a engine zera a fome viva a
    -- cada tick; mostra o snapshot que o guarda congelou para a barra nao piscar para "cheia" (e restaurada ao soltar).
    pcall(function() hunger = CD.data(a).gunHungerSave or a:getHunger() end)
    pcall(function() thirst = a:getThirst() end)
    pcall(function() health = a:getHealth() end)
    pcall(function() stress = CD.getStress(a) end)
    local ny = L.needsY
    self:drawNeedBar(getText("IGUI_PD_Need_hunger"), ny, hunger, hunger)
    if hoverRow(ny, L.needRowH) then infoTip = { title = getText("IGUI_PD_Need_hunger"), body = getText("IGUI_PD_NeedDesc_hunger", breedNoun) } end
    ny = ny + L.needRowH
    self:drawNeedBar(getText("IGUI_PD_Need_thirst"), ny, thirst, thirst)
    if hoverRow(ny, L.needRowH) then infoTip = { title = getText("IGUI_PD_Need_thirst"), body = getText("IGUI_PD_NeedDesc_thirst", breedNoun) } end
    ny = ny + L.needRowH
    self:drawNeedBar(getText("IGUI_PD_Need_health"), ny, health, 1 - health)
    if hoverRow(ny, L.needRowH) then infoTip = { title = getText("IGUI_PD_Need_health"), body = getText("IGUI_PD_NeedDesc_health", breedNoun) } end
    ny = ny + L.needRowH
    self:drawNeedBar(getText("IGUI_PD_Need_stress"), ny, stress, stress)
    if hoverRow(ny, L.needRowH) then infoTip = { title = getText("IGUI_PD_Need_stress"), body = getText("IGUI_PD_NeedDesc_stress", breedNoun) } end

    self:drawDivider(L.div2)

    self:drawText(getText("IGUI_PD_SkillsLabel"), x, L.skillsLabelY, LBL.r, LBL.g, LBL.b, 1, UIFont.Small)
    local sy = L.skillsY
    for _, skill in ipairs(CD.SKILLS) do
        local level, into, need = 0, 0, 1
        pcall(function() level, into, need = CD.skillProgress(a, skill) end)
        self:drawSkillBar(getText("IGUI_PD_Skill_" .. skill), sy, level, into, need)
        if over and my >= sy and my < sy + L.skillRowH and mx >= PAD and mx <= cw - PAD then
            local mult = 1
            pcall(function() mult = CD.getBreedDef(a).xpMult[skill] or 1 end)
            tip = { skill = skill, level = level, into = into, need = need, mult = mult }
        end
        sy = sy + L.skillRowH
    end

    self:drawDivider(L.div3)

    self:drawText(getText("IGUI_PD_GenomeLabel"), x, L.genomeLabelY, LBL.r, LBL.g, LBL.b, 1, UIFont.Small)
    if hoverRow(L.genomeLabelY, fh(UIFont.Small) + ROW_GAP) then
        infoTip = { title = getText("IGUI_PD_GenomeLabel"), body = getText("IGUI_PD_GenomeDesc", breedNoun) }
    end
    local breedName = breedNoun
    local mestico = false
    pcall(function() mestico = CD.isMestico(a) end)
    if mestico then breedName = breedName .. " (" .. getText("IGUI_PD_Mestico") .. ")" end
    -- idade (Filhote/Adulto) anexada na mesma linha
    local ageTxt = breedNoun
    pcall(function() ageTxt = CD.ageNoun(a) end)
    local breedText = getText("IGUI_PD_BreedLabel") .. ": " .. breedName .. ", " .. ageTxt
    self:drawText(breedText, x, L.breedRowY, 0.72, 0.82, 0.92, 1, UIFont.Small)
    if hoverRect(PAD, L.breedRowY, strW(UIFont.Small, breedText), fh(UIFont.Small)) then
        local bkey = CD.DEFAULT_BREED
        pcall(function() bkey = CD.getBreed(a) end)
        local body = getText("IGUI_PD_BreedDesc_" .. bkey)
        if mestico then
            local ll = ""
            pcall(function() ll = CD.lineageLabel(a) end)
            if ll ~= "" then body = ll .. " \n " .. body end
        end
        infoTip = { title = breedName, body = body }
    end
    local ty = L.genomeY
    for _, gene in ipairs({ "strength", "aggressiveness", "resistance" }) do
        local ratio = 0.5
        pcall(function() ratio = CD.geneRatio(a, gene) end)
        self:drawTraitBar(getText("IGUI_PD_Gene_" .. gene), ty, ratio)
        if hoverRow(ty, L.traitRowH) then
            infoTip = { title = getText("IGUI_PD_Gene_" .. gene), body = getText("IGUI_PD_GeneDesc_" .. gene, breedNoun) }
        end
        ty = ty + L.traitRowH
    end

    if tip then
        self:drawSkillTip(tip, mx, my)
    elseif infoTip then
        self:drawInfoTip(infoTip.title, infoTip.body, mx, my)
    end
end

-- ===================== aba Comandos (todos os botoes) =====================

function ISCDCommandsView:doLayout()
    local L = {}
    local sm = fh(UIFont.Small)
    local y = PAD

    L.modeLabelY = y;       y = y + sm + ROW_GAP
    L.modeBtnY = y;         y = y + BTN_H + SECT_GAP

    L.alertLabelY = y;      y = y + sm + ROW_GAP
    L.alertBtnY = y;        y = y + BTN_H + SECT_GAP

    L.protectLabelY = y;    y = y + sm + ROW_GAP
    L.protectBtnY = y;      y = y + BTN_H + SECT_GAP

    L.huntLabelY = y;       y = y + sm + ROW_GAP
    L.huntBtnY = y;         y = y + BTN_H + SECT_GAP

    if self.showBag then
        L.bagBtnY = y;      y = y + BTN_H + SECT_GAP
    end

    L.actionsLabelY = y;    y = y + sm + ROW_GAP
    L.actionBtnY = y;       y = y + BTN_H

    y = y + PAD
    L.contentH = y
    self.L = L
    return L
end

function ISCDCommandsView:createChildren()
    self.showBag = false
    pcall(function() self.showBag = (not self.stashed) and CD.hasBag(self.animal) == true end)
    self:doLayout()

    self.followBtn = self:makeBtn(10, getText("IGUI_PD_CmdFollow"), ISCDCommandsView.onModeFollow, "CDFOLLOW")
    self.stayBtn   = self:makeBtn(10, getText("IGUI_PD_CmdStay"), ISCDCommandsView.onModeStay, "CDSTAY")
    self.guardBtn  = self:makeBtn(10, getText("IGUI_PD_CmdGuard"), ISCDCommandsView.onModeGuard, "CDGUARD")

    self.alertBtn  = self:makeBtn(10, getText("IGUI_PD_AlertOn"), ISCDCommandsView.onAlertFull, "CDALERTON")
    self.quietBtn  = self:makeBtn(10, getText("IGUI_PD_AlertQuiet"), ISCDCommandsView.onAlertQuiet, "CDALERTQUIET")
    self.silentBtn = self:makeBtn(10, getText("IGUI_PD_AlertSilent"), ISCDCommandsView.onAlertSilent, "CDALERTSILENT")

    self.protectBtn = self:makeBtn(10, getText("IGUI_PD_AutoProtect"), ISCDCommandsView.onToggleProtect, "CDPROTECT")
    self.huntBtn = self:makeBtn(10, getText("IGUI_PD_HuntMode"), ISCDCommandsView.onToggleHunt, "CDHUNT")

    if self.showBag then
        self.bagBtn = self:makeBtn(10, getText("IGUI_PD_OpenBag"), ISCDCommandsView.onOpenBag, "CDBAG")
    end

    self.fetchBtn   = self:makeBtn(10, getText("IGUI_PD_CmdFetch"), ISCDCommandsView.onFetch, "CDFETCH")
    self.renameBtn  = self:makeBtn(10, getText("IGUI_PD_BtnRename"), ISCDCommandsView.onRenameBtn, "CDRENAME")
    self.releaseBtn = self:makeBtn(10, getText("IGUI_PD_BtnRelease"), ISCDCommandsView.onReleaseBtn, "CDRELEASE")
    local bn = CD.breedNoun(self.animal)
    self.fetchBtn:setTooltip(getText("IGUI_PD_CmdFetchDesc", bn))
    self.renameBtn:setTooltip(getText("IGUI_PD_BtnRenameDesc", bn))
    self.releaseBtn:setTooltip(getText("IGUI_PD_BtnReleaseDesc", bn))
    self:markActive(self.fetchBtn, false)
    self:markActive(self.renameBtn, false)
    self:markActive(self.releaseBtn, false)

    if self.stashed then self:applyStashedMode() end

    self:layout()
end

-- Reposiciona + redimensiona cada botao para a largura de conteudo atual (view menos a calha da scrollbar), depois
-- publica a altura do conteudo para a scrollbar saber o range rolavel.
function ISCDCommandsView:layout()
    local L = self:doLayout()
    local cw = CD.UI.viewContentW(self)
    local w3 = math.floor((cw - PAD * 2 - BTN_GAP * 2) / 3)
    if w3 < 10 then w3 = 10 end
    local function col(i) return PAD + (w3 + BTN_GAP) * i end
    local fullW = cw - PAD * 2

    self.followBtn:setX(col(0)); self.followBtn:setY(L.modeBtnY); self.followBtn:setWidth(w3)
    self.stayBtn:setX(col(1));   self.stayBtn:setY(L.modeBtnY);   self.stayBtn:setWidth(w3)
    self.guardBtn:setX(col(2));  self.guardBtn:setY(L.modeBtnY);  self.guardBtn:setWidth(w3)

    self.alertBtn:setX(col(0));  self.alertBtn:setY(L.alertBtnY);  self.alertBtn:setWidth(w3)
    self.quietBtn:setX(col(1));  self.quietBtn:setY(L.alertBtnY);  self.quietBtn:setWidth(w3)
    self.silentBtn:setX(col(2)); self.silentBtn:setY(L.alertBtnY); self.silentBtn:setWidth(w3)

    self.protectBtn:setX(PAD); self.protectBtn:setY(L.protectBtnY); self.protectBtn:setWidth(fullW)
    self.huntBtn:setX(PAD);    self.huntBtn:setY(L.huntBtnY);       self.huntBtn:setWidth(fullW)

    if self.bagBtn and L.bagBtnY then
        self.bagBtn:setX(PAD); self.bagBtn:setY(L.bagBtnY); self.bagBtn:setWidth(fullW)
    end

    self.fetchBtn:setX(col(0));   self.fetchBtn:setY(L.actionBtnY);   self.fetchBtn:setWidth(w3)
    self.renameBtn:setX(col(1));  self.renameBtn:setY(L.actionBtnY);  self.renameBtn:setWidth(w3)
    self.releaseBtn:setX(col(2)); self.releaseBtn:setY(L.actionBtnY); self.releaseBtn:setWidth(w3)

    self:setScrollHeight(L.contentH)
end

-- Modo "no veiculo": o cachorro vivo sumiu, entao desabilita tudo que precisa dele (modo/sentinela/trazer/soltar),
-- e reaproveita a linha de acoes em Feed / Water / Rename (as unicas acoes que conseguem mutar o registro do stash
-- e ser aplicadas ao desmontar). Os botoes ficam de fato desabilitados (setEnable) para um clique nao alcancar os
-- caminhos CD.request que so funcionam com o cachorro vivo.
function ISCDCommandsView:applyStashedMode()
    local tip = getText("IGUI_PD_DrivingDisabledTip")
    for _, b in ipairs({ self.followBtn, self.stayBtn, self.guardBtn, self.alertBtn, self.quietBtn, self.silentBtn, self.protectBtn, self.huntBtn }) do
        if b then b:setEnable(false); b:setTooltip(tip) end
    end
    self.fetchBtn.title = getText("IGUI_PD_FeedCompanion")
    self.fetchBtn.onclick = ISCDCommandsView.onFeedStashed
    self.fetchBtn:setTooltip(nil)
    self.releaseBtn.title = getText("IGUI_PD_Water")
    self.releaseBtn.onclick = ISCDCommandsView.onWaterStashed
    self.releaseBtn:setTooltip(nil)
    -- renameBtn mantem seu label/onclick; onRenameBtn/onRenameApply se ramificam em view.stashed.
end

function ISCDCommandsView:prerender()
    if not self.stashed then -- botoes de modo/alerta ficam desabilitados e estaticos ao dirigir; nao reacender
        local state = CD.STATE_FOLLOW
        pcall(function() state = CD.getState(self.animal) end)
        self:markActive(self.followBtn, state == CD.STATE_FOLLOW)
        self:markActive(self.stayBtn, state == CD.STATE_STAY)
        self:markActive(self.guardBtn, state == CD.STATE_GUARD)

        local mode = "full"
        pcall(function() mode = CD.getAlertMode(self.animal) end)
        self:markActive(self.alertBtn, mode == "full")
        self:markActive(self.quietBtn, mode == "quiet")
        self:markActive(self.silentBtn, mode == "silent")

        local protect = false
        pcall(function() protect = CD.getAutoProtect(self.animal) end)
        self:markActive(self.protectBtn, protect)
        if self.protectBtn then
            self.protectBtn.title = getText(protect and "IGUI_PD_AutoProtectOn" or "IGUI_PD_AutoProtectOff")
        end

        local hunt = false
        pcall(function() hunt = CD.getHuntMode(self.animal) end)
        self:markActive(self.huntBtn, hunt)
        if self.huntBtn then
            self.huntBtn.title = getText(hunt and "IGUI_PD_HuntModeOn" or "IGUI_PD_HuntModeOff")
        end
    end
    CD.UI.viewBeginRender(self)
end

function ISCDCommandsView:drawContent()
    local L = self.L
    if not L then return end
    local breedNoun = CD.breedNoun(self.animal)
    local cw = CD.UI.viewContentW(self)
    local x = PAD

    local over = self:isMouseOver() or self:isMouseOverChild()
    local mx, my = self:getMouseX(), self:getMouseY()
    local infoTip = nil
    local function hoverRect(bx, y, w, h)
        return over and mx >= bx and mx < bx + w and my >= y and my < y + h
    end

    self:drawText(getText("IGUI_PD_ModeLabel"), x, L.modeLabelY, LBL.r, LBL.g, LBL.b, 1, UIFont.Small)
    self:drawText(getText("IGUI_PD_SentinelLabel"), x, L.alertLabelY, LBL.r, LBL.g, LBL.b, 1, UIFont.Small)
    self:drawText(getText("IGUI_PD_AutoProtectLabel"), x, L.protectLabelY, LBL.r, LBL.g, LBL.b, 1, UIFont.Small)
    self:drawText(getText("IGUI_PD_HuntLabel"), x, L.huntLabelY, LBL.r, LBL.g, LBL.b, 1, UIFont.Small)
    self:drawText(getText("IGUI_PD_ActionsLabel"), x, L.actionsLabelY, LBL.r, LBL.g, LBL.b, 1, UIFont.Small)

    local w3 = math.floor((cw - PAD * 2 - BTN_GAP * 2) / 3)
    local function btnX(c) return PAD + (w3 + BTN_GAP) * c end
    local modeCells = {
        { key = "IGUI_PD_CmdFollow", desc = "IGUI_PD_CmdFollowDesc" },
        { key = "IGUI_PD_CmdStay",   desc = "IGUI_PD_CmdStayDesc" },
        { key = "IGUI_PD_CmdGuard",  desc = "IGUI_PD_CmdGuardDesc" },
    }
    local alertCells = {
        { key = "IGUI_PD_AlertOn",     desc = "IGUI_PD_AlertFullDesc" },
        { key = "IGUI_PD_AlertQuiet",  desc = "IGUI_PD_AlertQuietDesc" },
        { key = "IGUI_PD_AlertSilent", desc = "IGUI_PD_AlertSilentDesc" },
    }
    for c, cell in ipairs(modeCells) do
        if hoverRect(btnX(c - 1), L.modeBtnY, w3, BTN_H) then
            infoTip = { title = getText(cell.key), body = getText(cell.desc, breedNoun) }
        end
    end
    for c, cell in ipairs(alertCells) do
        if hoverRect(btnX(c - 1), L.alertBtnY, w3, BTN_H) then
            infoTip = { title = getText(cell.key), body = getText(cell.desc, breedNoun) }
        end
    end
    if hoverRect(PAD, L.protectBtnY, cw - PAD * 2, BTN_H) then
        infoTip = { title = getText("IGUI_PD_AutoProtect"), body = getText("IGUI_PD_AutoProtectDesc", breedNoun) }
    end
    if hoverRect(PAD, L.huntBtnY, cw - PAD * 2, BTN_H) then
        infoTip = { title = getText("IGUI_PD_HuntMode"), body = getText("IGUI_PD_HuntModeDesc", breedNoun) }
    end

    if infoTip then
        self:drawInfoTip(infoTip.title, infoTip.body, mx, my)
    end
end

function ISCDCommandsView:setMode(state)
    if self.stashed or not self.animal then return end
    CD.request("setstate", self.animal, { state = state })
end

function ISCDCommandsView:setAlertMode(mode)
    if self.stashed or not self.animal then return end
    CD.request("setalertmode", self.animal, { mode = mode })
end

function ISCDCommandsView.onModeFollow(view) view:setMode(CD.STATE_FOLLOW) end
function ISCDCommandsView.onModeStay(view)   view:setMode(CD.STATE_STAY) end
function ISCDCommandsView.onModeGuard(view)  view:setMode(CD.STATE_GUARD) end
function ISCDCommandsView.onAlertFull(view)   view:setAlertMode("full") end
function ISCDCommandsView.onAlertQuiet(view)  view:setAlertMode("quiet") end
function ISCDCommandsView.onAlertSilent(view) view:setAlertMode("silent") end

function ISCDCommandsView.onToggleProtect(view)
    if view.stashed or not view.animal then return end
    local on = false
    pcall(function() on = CD.getAutoProtect(view.animal) end)
    CD.request("setautoprotect", view.animal, { on = not on })
end

function ISCDCommandsView.onToggleHunt(view)
    if view.stashed or not view.animal then return end
    local on = false
    pcall(function() on = CD.getHuntMode(view.animal) end)
    CD.request("sethuntmode", view.animal, { on = not on })
end

function ISCDCommandsView.onFetch(view)
    if not view.animal then return end
    local p = getPlayer()
    if p then
        pcall(function() p:playEmote("comehere") end)
        pcall(function() p:Callout(false) end)
    end
    CD.request("teleport", view.animal)
end

function ISCDCommandsView.onOpenBag(view)
    if view and view.animal and CD.openBagWindow then CD.openBagWindow(view.animal) end
end

local function onRenameApply(target, button, view)
    if button.internal == "OK" then
        local text = button.parent.entry:getText()
        if view.stashed then
            CD.requestStashed("renamestashed", { text = text })
        else
            CD.request("rename", view.animal, { text = text })
        end
    end
end

function ISCDCommandsView.onRenameBtn(view)
    local animal = view.animal
    if not animal then return end
    local cur = ""
    pcall(function() cur = CD.data(animal).name or "" end)
    local player = getPlayer()
    local modal = ISTextBox:new(0, 0, 290, 180, getText("IGUI_PD_RenameTitle", CD.breedNoun(animal)), cur, nil,
        onRenameApply, player and player:getPlayerNum() or 0, view)
    modal:initialise()
    modal:addToUIManager()
end

-- Alimentar ao dirigir: sem cachorro vivo e sem acao temporizada, entao calcula a mordida (CD.computeBite) e envia
-- um comando com escopo no player que consome o item no server e muta o registro do stash (aplicado ao cachorro vivo
-- ao desmontar).
function ISCDCommandsView.doFeedStashed(view, player, food)
    player = player or view.owner or getPlayer()
    if not (player and food) then return end
    local inv = player:getInventory()
    if not inv:contains(food) then return end

    local need
    pcall(function() need = view.animal:getHunger() end)
    local bite = CD.computeBite(food, need)
    -- Consumo proporcional (igual ao feed na mao): encolhe a comida ate a sobra, sem desperdicio.
    CD.requestStashed("feedstashed", { hunger = bite.hunger, thirst = bite.thirst, partialFrac = bite.partialFrac, foodId = food:getID() })
end

function ISCDCommandsView.onFeedStashed(view)
    local player = view.owner or getPlayer()
    if not player then return end
    local foods = cdListFoods(player)
    if #foods == 0 then
        HaloTextHelper.addText(player, getText("IGUI_PD_NeedFood"))
        return
    end
    if #foods == 1 then
        ISCDCommandsView.doFeedStashed(view, player, foods[1].item)
        return
    end
    local menu = ISContextMenu.get(player:getPlayerNum(), getMouseX(), getMouseY())
    for _, g in ipairs(foods) do
        local label = g.count > 1 and (g.name .. " (" .. g.count .. ")") or g.name
        local opt = menu:addOption(label, view, ISCDCommandsView.doFeedStashed, player, g.item)
        opt.iconTexture = g.item:getTexture()
        if g.bad then
            opt.color = { r = 1, g = 0.35, b = 0.35 }
            menu.cdBadLabels = menu.cdBadLabels or {}
            menu.cdBadLabels[opt.name] = true
            local tooltip = ISWorldObjectContextMenu.addToolTip()
            tooltip:setName(g.name)
            tooltip.description = "<RGB:1,0.35,0.35>" .. getText("IGUI_PD_BadFood")
            opt.toolTip = tooltip
        end
    end
end

function ISCDCommandsView.onWaterStashed(view)
    local player = view.owner or getPlayer()
    if not player then return end
    local item = cdFirstWater(player)
    if not item then
        HaloTextHelper.addText(player, getText("IGUI_PD_NeedWater"))
        return
    end
    CD.requestStashed("waterstashed", { waterId = item:getID() })
end

local function onReleaseConfirm(target, button)
    local internal = (type(button) == "table") and button.internal or button
    if internal == "YES" and target and target.animal then
        CD.request("release", target.animal)
        if target.window then target.window:close() end
    end
end

function ISCDCommandsView.onReleaseBtn(view)
    if not view.animal then return end
    local p = getPlayer()
    local modal = ISModalDialog:new(0, 0, 340, 140,
        getText("IGUI_PD_ReleaseConfirm", view:dogName()), true, view, onReleaseConfirm,
        p and p:getPlayerNum() or 0)
    modal:initialise()
    modal:addToUIManager()
end

-- ===================== aba travada (sem cao: por-cao desabilitada) =====================

-- Placeholder das abas por-cao no modo sem-cao: elas nunca ficam ativas (o clique e bloqueado na
-- barra de abas), entao esta view so existe como rede de seguranca e para manter o padrao de viewport.
-- Centraliza a mensagem "faca amizade com um cao antes".
function ISCDLockedView:doLayout()
    self.L = { contentH = self.height or 1 }
    return self.L
end

function ISCDLockedView:drawContent()
    local msg = getText("IGUI_PD_TabLockedTip")
    local cw = CD.UI.viewContentW(self)
    local mw = strW(UIFont.Small, msg)
    self:drawText(msg, math.max(PAD, (cw - mw) / 2), 24, 0.62, 0.62, 0.62, 1, UIFont.Small)
end

-- ===================== janela host (cabecalho + abas) =====================

function ISCDStatusWindow:new(x, y, width, height, animal)
    local o = ISCollapsableWindow.new(self, x, y, width, height)
    o.animal = animal
    o.resizable = true
    o.avatarBg = getTexture("media/ui/avatarBackgroundWhite.png")
    o:setTitle(o:dogName())
    return o
end

function ISCDStatusWindow:dogName()
    if not self.animal then return getText("IGUI_PD_KennelTitle") end
    local name
    pcall(function() name = CD.data(self.animal).name end)
    if name then return name end
    local bn
    pcall(function() bn = CD.breedNoun(self.animal) end)
    return bn or getText("IGUI_PD_DogDefaultName")
end

function ISCDStatusWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    local top = self:titleBarHeight()
    local rh = self:resizeWidgetHeight()
    -- cabecalho fixo sempre visivel (com avatar 3D quando ha cao vivo; placeholder "sem cao" caso contrario)
    self.hdrH = HDR_H

    local pw = self.width
    local ph = math.max(1, self.height - top - self.hdrH - rh)
    self.panel = ISTabPanel:new(0, top + self.hdrH, pw, ph)
    self.panel:initialise()
    self.panel.equalTabWidth = false
    self.panel.centerTabs = false
    self.panel.tabPadX = 16
    self.panel.target = self
    self.panel.onActivateView = ISCDStatusWindow.onTabActivated
    -- barra de abas baixa + rotulo NewSmall desenhado a metade (drawTextZoomed); o ISTabPanel chama
    -- self:drawTextCentre so pro rotulo da aba, entao reescrevemos essa chamada como texto escalado e
    -- centralizado na mao (nao existe DrawTextCentre com zoom).
    self.panel.tabHeight = math.ceil(getTextManager():getFontHeight(TAB_FONT) * TAB_ZOOM) + TAB_H_PAD
    self.panel.cdLocked = {}
    self.panel.drawTextCentre = function(pnl, str, x, y, r, g, b, a, font)
        local tm = getTextManager()
        local tw = tm:MeasureStringX(TAB_FONT, str) * TAB_ZOOM
        local th = tm:getFontHeight(TAB_FONT) * TAB_ZOOM
        if pnl.cdLocked[str] then r, g, b = 0.45, 0.45, 0.45 end -- aba desabilitada = rotulo escurecido
        pnl:drawTextZoomed(str, x - tw / 2, math.floor((pnl.tabHeight - th) / 2), TAB_ZOOM, r, g, b, a, TAB_FONT)
    end
    -- bloqueia o clique/ativacao das abas travadas (sem tocar o som de troca de aba)
    local baseOnMouseDown = self.panel.onMouseDown
    self.panel.onMouseDown = function(pnl, x, y)
        if pnl:getMouseY() >= 0 and pnl:getMouseY() < pnl.tabHeight then
            local idx = pnl:getTabIndexAtX(pnl:getMouseX())
            local vo = pnl.viewList and pnl.viewList[idx]
            if vo and pnl.cdLocked[vo.name] then return end
        end
        return baseOnMouseDown(pnl, x, y)
    end
    self:addChild(self.panel)

    self.views = {}
    local vh = math.max(1, ph - self.panel.tabHeight)
    local function addTab(id, label, view)
        view.cdTabId = id
        view.window = self
        view.animal = self.animal
        view.stashed = self.stashed
        view.owner = self.owner
        self.panel:addView(label, view)
        self.views[#self.views + 1] = view
    end

    -- abas por-cao: com cao vivo/stash usam as views reais; sem cao viram placeholders travados (escuros,
    -- nao clicaveis, tooltip "faca amizade com um cao antes"), mas seguem presentes para o menu ser explorable.
    local statusLabel = getText("IGUI_PD_TabSkillsStatus")
    local commandsLabel = getText("IGUI_PD_TabCommands")
    if self.animal then
        addTab("status",   statusLabel,   ISCDStatusView:new(0, 0, pw, vh))
        addTab("commands", commandsLabel, ISCDCommandsView:new(0, 0, pw, vh))
    else
        addTab("status",   statusLabel,   ISCDLockedView:new(0, 0, pw, vh))
        addTab("commands", commandsLabel, ISCDLockedView:new(0, 0, pw, vh))
        self.panel.cdLocked[statusLabel] = true
        self.panel.cdLocked[commandsLabel] = true
    end
    local kennel = ISCDKennelView:new(0, 0, pw, vh)
    kennel.playerNum = self.playerNum or 0
    addTab("kennel", getText("IGUI_PD_KennelTitle"), kennel)
    self.kennelView = kennel
    local settings = ISCDSettingsView:new(0, 0, pw, vh)
    addTab("settings", getText("IGUI_PD_ConfigsBtn"), settings)
    self.settingsView = settings
    self:fitTabs()

    -- avatar 3D do cabecalho (so com cachorro vivo; no veiculo o cabecalho cai pro icone da patinha)
    if self.animal and not self.stashed then
        local av = ISCDDogAvatar:new(HDR_PAD, top + math.floor((HDR_H - HDR_AV) / 2), HDR_AV, HDR_AV)
        av:initialise()
        self:addChild(av)
        av:bindAnimal(self.animal)
        self.headerAvatar = av
    end

    CD.UI.initResizable(self, "dogwin", MIN_W, MIN_H)
end

-- Abas preenchem TODA a largura, mas com o espaco distribuido PROPORCIONAL ao texto de cada uma (respiro
-- relativo igual, sem esticar aba curta a toa como fazia o equalTabWidth). Recalcula no open e a cada resize.
-- A largura natural mede a fonte JA escalada (o addView do ISTabPanel mede em UIFont.Small cheio, o que
-- deixaria a aba larga demais pro texto pequeno). Se a soma natural ja passar da largura, mantem o natural e o
-- ISTabPanel liga o scroll horizontal nativo. inset=1 e gap=1 sao os do ISTabPanel.
function ISCDStatusWindow:fitTabs()
    local p = self.panel
    if not p or not p.viewList then return end
    local n = #p.viewList
    if n == 0 then return end
    local tm = getTextManager()
    local nat, sumNat = {}, 0
    for i, vo in ipairs(p.viewList) do
        nat[i] = math.ceil(tm:MeasureStringX(TAB_FONT, vo.name) * TAB_ZOOM) + p.tabPadX
        sumNat = sumNat + nat[i]
    end
    local avail = p.width - 2 - (n - 1)
    if sumNat <= 0 or avail <= sumNat then
        for i, vo in ipairs(p.viewList) do vo.tabWidth = nat[i] end
        return
    end
    -- reparte a largura na proporcao do tamanho natural; o arredondamento acumulado vai pra ultima aba
    -- encostar na borda sem sobra.
    local acc = 0
    for i, vo in ipairs(p.viewList) do
        local w = (i < n) and math.floor(nat[i] * avail / sumNat) or (avail - acc)
        acc = acc + w
        vo.tabWidth = w
    end
end

function ISCDStatusWindow:reflow()
    if not self.panel then return end
    local top = self:titleBarHeight()
    local rh = self:resizeWidgetHeight()
    self.panel:setX(0)
    self.panel:setY(top + (self.hdrH or 0))
    self.panel:setWidth(self.width)
    self.panel:setHeight(math.max(1, self.height - top - (self.hdrH or 0) - rh))
    self:fitTabs()
    local vh = math.max(1, self.panel.height - self.panel.tabHeight)
    for _, v in ipairs(self.views or {}) do
        v:setY(self.panel.tabHeight)
        v:setWidth(self.panel.width)
        v:setHeight(vh)
        if v.layout then v:layout() end
    end
end

-- Persiste a ultima aba ativa (por id interno, o rotulo muda com o idioma) e cancela captura de keybind pendente
-- ao sair da aba de configuracoes.
function ISCDStatusWindow.onTabActivated(win, panel)
    local v = panel:getActiveView()
    if not v then return end
    if v.cdTabId and CD.Settings.setLastTab then CD.Settings.setLastTab(v.cdTabId) end
    if win.settingsView and v ~= win.settingsView then
        win.settingsView.capturingId = nil
        if CD.Keybinds then CD.Keybinds.captureCb = nil end
    end
end

function ISCDStatusWindow:activateTabId(id)
    if not (id and self.panel) then return false end
    for _, vo in ipairs(self.panel.viewList) do
        if vo.view.cdTabId == id then
            if self.panel.cdLocked[vo.name] then return false end -- nunca aterrissar numa aba travada
            self.panel:activateView(vo.name)
            return true
        end
    end
    return false
end

-- Fecha sozinha quando o cachorro some (ou, ao dirigir, quando o dono sai do veiculo e o stash e limpo).
-- No modo sem cao (so Meus Caes + Configuracoes) nunca fecha sozinha.
function ISCDStatusWindow:checkShouldClose()
    if not self.animal then return false end
    if self.stashed then
        local owner = self.owner
        local hasStash = false
        pcall(function() hasStash = owner ~= nil and CD.isMounted(owner) and CD.playerData(owner).stash ~= nil end)
        if not hasStash then self:close(); return true end
    else
        local alive = false
        local a = self.animal
        if a then pcall(function() alive = a:isExistInTheWorld() end) end
        if not alive then self:close(); return true end
    end
    return false
end

function ISCDStatusWindow:drawHeader()
    if self.isCollapsed then return end
    local top = self:titleBarHeight()
    local ax = HDR_PAD
    local ay = top + math.floor((HDR_H - HDR_AV) / 2)
    self:drawRectBorder(ax - 1, ay - 1, HDR_AV + 2, HDR_AV + 2, 1, 0.3, 0.3, 0.3)
    if self.avatarBg then
        self:drawTextureScaled(self.avatarBg, ax, ay, HDR_AV, HDR_AV, 1, 0.4, 0.4, 0.4)
    end

    -- modo sem-cao: caixa de avatar com a patinha CINZA esmaecida + placeholder no lugar do nome/raca/abates
    if not self.animal then
        local paw = getTexture("media/textures/CDDogPawGrey_48.png") or cdLoadPaw(48)
        if paw then self:drawTextureScaled(paw, ax + 8, ay + 8, HDR_AV - 16, HDR_AV - 16, 0.5, 1, 1, 1) end
        local tx = ax + HDR_AV + 12
        local msg = getText("IGUI_PD_KennelEmpty")
        local ty = ay + math.floor((HDR_AV - fh(UIFont.Medium)) / 2)
        self:drawText(msg, tx, ty, 0.72, 0.72, 0.72, 1, UIFont.Medium)
        return
    end
    local av = self.headerAvatar
    if av and av.boundAnimal then
        av:applyFrame()
    else
        local paw = cdLoadPaw(48)
        if paw then self:drawTextureScaled(paw, ax + 8, ay + 8, HDR_AV - 16, HDR_AV - 16, 1, 1, 1, 1) end
    end

    local a = self.animal
    local tx = ax + HDR_AV + 12
    local mdH = fh(UIFont.Medium)
    local smH = fh(UIFont.Small)
    -- nome + raca + abates centralizados verticalmente na altura do avatar
    local blockH = mdH + 6 + smH + 4 + smH
    local nameY = ay + math.max(2, math.floor((HDR_AV - blockH) / 2))
    self:drawText(self:dogName(), tx, nameY, 1, 1, 1, 1, UIFont.Medium)

    local breedName = CD.breedNoun(a)
    pcall(function() if CD.isMestico(a) then breedName = breedName .. " (" .. getText("IGUI_PD_Mestico") .. ")" end end)
    local line = getText("IGUI_PD_BreedLabel") .. ": " .. breedName
    pcall(function() line = line .. ", " .. CD.ageNoun(a) end)
    local lineY = nameY + mdH + 6
    self:drawText(line, tx, lineY, 0.72, 0.82, 0.92, 1, UIFont.Small)

    -- abates do proprio cao (zumbis + caca), lidos ao vivo do ModData
    local zk, pk = 0, 0
    pcall(function() local d = CD.data(a); zk = d.zombieKills or 0; pk = d.preyKills or 0 end)
    local killsY = lineY + smH + 4
    self:drawText(getText("IGUI_PD_KillsLabel") .. ": " .. getText("IGUI_PD_KillsFmt", tostring(zk), tostring(pk)),
        tx, killsY, 0.72, 0.82, 0.92, 1, UIFont.Small)

    local badge
    pcall(function() badge = CD.statusBadge(a) end)
    if badge then
        local wtxt = getText(badge.key)
        self:drawText(wtxt, self.width - 12 - strW(UIFont.Small, wtxt), nameY + 2, badge.r, badge.g, badge.b, 1, UIFont.Small)
    end
    if self.stashed then
        local btxt = getText("IGUI_PD_InVehicleBanner")
        self:drawText(btxt, self.width - 12 - strW(UIFont.Small, btxt), lineY, 0.70, 0.80, 0.95, 1, UIFont.Small)
    end
end

function ISCDStatusWindow:prerender()
    if self:checkShouldClose() then return end
    self:setTitle(self:dogName())
    ISCollapsableWindow.prerender(self)
    self:drawHeader()
end

-- Tooltip da aba desabilitada: o ISTabPanel nao tem tooltip de aba, entao desenhamos no render (que roda POR
-- CIMA dos filhos) quando o mouse esta sobre a barra de abas em cima de uma aba travada.
function ISCDStatusWindow:drawLockedTabTip()
    local p = self.panel
    if self.isCollapsed or not (p and p.cdLocked) then return end
    local pmy = p:getMouseY()
    if not (p:isMouseOver() and pmy >= 0 and pmy < p.tabHeight) then return end
    local idx = p:getTabIndexAtX(p:getMouseX())
    local vo = p.viewList and p.viewList[idx]
    if not (vo and p.cdLocked[vo.name]) then return end

    local font = UIFont.Small
    local txt = getText("IGUI_PD_TabLockedTip")
    local pad = 8
    local w = strW(font, txt) + pad * 2
    local h = fh(font) + pad * 2
    local mx, my = self:getMouseX(), self:getMouseY()
    local tx = mx + 14
    local ty = my + 16
    if tx + w > self.width then tx = self.width - w - 2 end
    if tx < 2 then tx = 2 end
    if ty + h > self.height then ty = my - h - 6 end
    self:drawRect(tx, ty, w, h, 0.93, 0.06, 0.06, 0.06)
    self:drawRectBorder(tx, ty, w, h, 0.85, 0.5, 0.5, 0.5)
    self:drawText(txt, tx + pad, ty + pad, 0.86, 0.86, 0.86, 1, font)
end

function ISCDStatusWindow:render()
    ISCollapsableWindow.render(self)
    self:drawLockedTabTip()
end

function ISCDStatusWindow:close()
    CD.UI.persist(self)
    if self.settingsView then self.settingsView.capturingId = nil end
    if CD.Keybinds then CD.Keybinds.captureCb = nil end
    ISCollapsableWindow.close(self)
    self:removeFromUIManager()
    if ISCDStatusWindow.instance == self then
        ISCDStatusWindow.instance = nil
    end
end

local function openDogWindow(animal, stashed, owner, tabId)
    if ISCDStatusWindow.instance then
        ISCDStatusWindow.instance:close()
    end
    local win = ISCDStatusWindow:new(0, 0, WIN_W, 480, animal)
    win.stashed = stashed
    win.owner = owner
    pcall(function() if owner then win.playerNum = owner:getPlayerNum() end end)
    win:initialise()
    win:instantiate()
    local top = win:titleBarHeight()
    local rh = win:resizeWidgetHeight()
    local maxC = 320
    for _, v in ipairs(win.views or {}) do
        if v.L and v.L.contentH and v.L.contentH > maxC then maxC = v.L.contentH end
    end
    local naturalH = top + (win.hdrH or 0) + ((win.panel and win.panel.tabHeight) or 0) + maxC + rh
    CD.UI.applyOpenGeometry(win, "dogwin", WIN_W, naturalH)
    win:addToUIManager()
    ISCDStatusWindow.instance = win
    -- a aba inicial padrao do ISTabPanel e a primeira (status); no modo sem-cao ela esta travada, entao se a
    -- aba desejada nao ativar (nao existe ou travada) caimos na primeira aba NAO-travada (com cao = status;
    -- sem cao = Meus Caes).
    local wantTab = tabId or (CD.Settings.getLastTab and CD.Settings.getLastTab())
    if not win:activateTabId(wantTab) and win.panel then
        for _, vo in ipairs(win.panel.viewList) do
            if not win.panel.cdLocked[vo.name] then
                win.panel:activateView(vo.name)
                break
            end
        end
    end
    return win
end

function ISCDStatusWindow.OpenFor(animal, tabId)
    if not animal then return end
    openDogWindow(animal, nil, nil, tabId)
end

function ISCDStatusWindow.OpenStashed(playerObj, tabId)
    if not playerObj then return end
    openDogWindow(makeStashProxy(playerObj), true, playerObj, tabId)
end

function ISCDStatusWindow.OpenKennelOnly(playerObj, tabId)
    openDogWindow(nil, nil, playerObj, tabId or "kennel")
end

-- Abre a janela unificada ja numa aba, com o melhor alvo disponivel (cao vivo > stash do veiculo > modo sem cao).
function CD.openDogWindowTab(playerObj, tabId)
    local p = playerObj or getPlayer()
    if not p then return end
    local dog = CD.getCompanionAnimal(p)
    if dog then
        ISCDStatusWindow.OpenFor(dog, tabId)
    elseif CD.isMounted(p) and CD.playerData(p).stash then
        ISCDStatusWindow.OpenStashed(p, tabId)
    else
        ISCDStatusWindow.OpenKennelOnly(p, tabId or "kennel")
    end
end

function CD.openKennel(playerObj)
    CD.openDogWindowTab(playerObj, "kennel")
end

function CD.openDogStatus(playerObj)
    if ISCDStatusWindow.instance then
        ISCDStatusWindow.instance:close()
        return
    end
    local dog = CD.getCompanionAnimal(playerObj)
    if dog then
        ISCDStatusWindow.OpenFor(dog)
    elseif playerObj and CD.isMounted(playerObj) and CD.playerData(playerObj).stash then
        ISCDStatusWindow.OpenStashed(playerObj)
    elseif playerObj then
        -- Sem cao vivo por perto (com ou sem vinculo registrado): a patinha SEMPRE abre a janela no modo
        -- sem-cao, na aba Meus Caes. Configuracoes e Meus Caes independem de ter um cao carregado; as abas
        -- por-cao aparecem desabilitadas. (Recall de cao longe/perdido continua pela lista de Meus Caes.)
        ISCDStatusWindow.OpenKennelOnly(playerObj)
    end
end

local function onDogStatusButton(panel)
    CD.openDogStatus(panel and panel.chr)
end

local ISEquippedItem_createChildren = ISEquippedItem.createChildren
function ISEquippedItem:createChildren()
    ISEquippedItem_createChildren(self)
    local ref = self.mainHand or self.offHand or self.invBtn or self.healthBtn
    if not ref then return end
    local w = ref:getWidth()
    local h = math.floor(w * 0.75)
    local btn = ISButton:new(0, self:getHeight() + 5, w, h, "", self, onDogStatusButton)
    btn.internal = "CDDOGSTATUS"
    btn:initialise()
    btn:instantiate()
    btn:setDisplayBackground(false)
    -- pata marrom = janela aberta; cinza = fechada (troca no prerender)
    btn.cdTexOn = cdLoadPaw(w)
    btn.cdTexOff = getTexture("media/textures/CDDogPawGrey_" .. w .. ".png") or btn.cdTexOn
    local tex = btn.cdTexOff or btn.cdTexOn
    if tex then btn:setImage(tex) end
    btn:setTooltip(getText("IGUI_PD_HUDTooltip"))
    self:addChild(btn)
    self.cdDogStatusBtn = btn
end

local ISEquippedItem_prerender = ISEquippedItem.prerender
function ISEquippedItem:prerender()
    ISEquippedItem_prerender(self)
    local btn = self.cdDogStatusBtn
    if not btn then return end
    local wantTex = (ISCDStatusWindow.instance ~= nil) and btn.cdTexOn or btn.cdTexOff
    if wantTex and btn.image ~= wantTex then btn:setImage(wantTex) end
    local w = btn:getWidth()
    local maxBottom = 0
    local globalMaxBottom = 0
    local kids = self.children
    if kids then
        for _, c in pairs(kids) do
            if c ~= btn and c.getY and c.getHeight
                and (not c.getIsVisible or c:getIsVisible()) then
                local b = c:getY() + c:getHeight()
                if b > globalMaxBottom then globalMaxBottom = b end
                if c.getWidth and math.abs(c:getWidth() - w) <= 4 and b > maxBottom then
                    maxBottom = b
                end
            end
        end
    end
    local ty = maxBottom + (UI_BORDER_SPACING or 10) + 5
    if math.abs((btn:getY() or 0) - ty) > 0.5 then
        btn:setY(ty)
    end
    self:setHeight(math.max(globalMaxBottom, ty + btn:getHeight()))
end
