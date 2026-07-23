if isServer() and not isClient() then return end

require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"
require "ISUI/ISModalDialog"
require "DCS_UI_HelpWindow"
require "DCS_UI_Scale"
require "DCS_Translate"

DCS_UI_ShopAdmin = {}
DCS_UI_ShopAdmin.instance = nil

local FONT_SM = UIFont.Small
local FONT_MD = UIFont.Medium
local S = DCS_UI_Scale.s
local fontHgt = DCS_UI_Scale.fontHgt
local fontHgtMd = DCS_UI_Scale.fontHgtMd
local PAD = S(10)
local PANEL_W = S(540)
local PANEL_H = S(610)
local ROW_H = S(80)
local BTN_H = fontHgt + S(9)
local ITEMS_PER_PAGE = 5

local COL_BG = { r=0.12, g=0.12, b=0.12 }
local COL_ACCENT = { r=0.95, g=0.75, b=0.20 }
local COL_TEXT = { r=0.90, g=0.90, b=0.90 }
local COL_DIM = { r=0.60, g=0.60, b=0.60 }
local COL_GREEN = { r=0.30, g=0.80, b=0.35 }
local COL_RED = { r=0.90, g=0.30, b=0.30 }
local COL_ROW_ALT = { r=0.10, g=0.10, b=0.10 }
local COL_YELLOW = { r=0.95, g=0.75, b=0.20 }

local function hasShopAdminAccess()
    if isSinglePlayer and isSinglePlayer() then return true end
    local player = getSpecificPlayer(0)
    if not player then return false end
    local role = player:getRole()
    local hasTool = role and role.hasAdminTool and role:hasAdminTool()
    if hasTool then return true end
    return isAdmin and isAdmin() or false
end

local function getItemIcon(itemId)
    local sm = getScriptManager and getScriptManager()
    if not sm then return nil end
    local scriptItem = sm:FindItem(itemId)
    if scriptItem then
        local icon = nil
        local icons = scriptItem:getIconsForTexture()
        if icons and not icons:isEmpty() then icon = icons:get(0) end
        if not icon then icon = scriptItem:getIcon() end
        if icon then return tryGetTexture("Item_" .. icon) end
    end
    return nil
end

local function truncateText(text, font, maxWidth)
    if not text or not font then return text or "" end
    local tmgr = getTextManager()
    if tmgr:MeasureStringX(font, text) <= maxWidth then return text end
    while #text > 0 and tmgr:MeasureStringX(font, text .. "...") > maxWidth do
        text = string.sub(text, 1, #text - 1)
    end
    return text .. "..."
end

local _activeValueDlg = nil
local _shopEditorBeforeDlg = nil

local function closeValueDlg()
    if _activeValueDlg then
        _activeValueDlg:setVisible(false)
        _activeValueDlg:removeFromUIManager()
        _activeValueDlg = nil
    end
    if _shopEditorBeforeDlg then
        _shopEditorBeforeDlg:setVisible(true)
        _shopEditorBeforeDlg = nil
    end
end

DCS_ShopValueDialog = {}
function DCS_ShopValueDialog.open(title, currentValue, callback)
    closeValueDlg()
    local screenW = getPlayerScreenWidth(0)
    local screenH = getPlayerScreenHeight(0)
    local dlgW = S(280)
    local dlgH = S(110)
    local x = math.floor((screenW - dlgW) / 2)
    local y = math.floor((screenH - dlgH) / 2)

    local panel = ISCollapsableWindow:new(x, y, dlgW, dlgH)
    panel.moveWithMouse = true
    panel.resizable = false
    panel:initialise()
    panel:instantiate()
    panel:setTitle(title)

    local entry = ISTextEntryBox:new(tostring(currentValue), PAD, S(35), dlgW - PAD * 2, fontHgt + S(5))
    entry:initialise()
    entry:instantiate()
    entry:setOnlyNumbers(true)
    entry.javaObject = entry.javaObject
    panel:addChild(entry)
    panel.entry = entry

    local okBtn = ISButton:new(dlgW / 2 - S(58), dlgH - S(34), S(55), fontHgt + S(7), getText("IGUI_DCS_ShopAdmin_OK"), panel,
        function(target, btn, x, y)
            local val = tonumber(entry:getText()) or 0
            closeValueDlg()
            if callback then callback(val) end
        end)
    okBtn:initialise()
    okBtn:instantiate()
    okBtn:enableAcceptColor()
    panel:addChild(okBtn)

    local cancelBtn = ISButton:new(dlgW / 2 + S(3), dlgH - S(34), S(55), fontHgt + S(7), getText("IGUI_DCS_ShopAdmin_Cancel"), panel,
        function(target, btn, x, y) closeValueDlg() end)
    cancelBtn:initialise()
    cancelBtn:instantiate()
    cancelBtn:enableCancelColor()
    panel:addChild(cancelBtn)

    if DCS_UI_ShopAdmin.instance then
        _shopEditorBeforeDlg = DCS_UI_ShopAdmin.instance
        DCS_UI_ShopAdmin.instance:setVisible(false)
    end

    panel:setVisible(true)
    panel:addToUIManager()
    _activeValueDlg = panel
    entry:focus()
end

DCS_ShopAdmin_Window = ISCollapsableWindow:derive("DCS_ShopAdmin_Window")

function DCS_ShopAdmin_Window:new(x, y)
    local o = ISCollapsableWindow.new(self, x, y, PANEL_W, PANEL_H)
    o.moveWithMouse = true
    o.resizable = false
    o.pendingChanges = { enabledItems = {}, customCosts = {}, customStock = {} }
    return o
end

local SHOP_TAB_KEYS = { "All", "Tools", "Weapons", "Equipment", "Clothing", "Medical", "Food", "Literature", "Materials", "Other" }
local SHOP_TAB_DISPLAY = nil
local function getTabDisplay()
    if not SHOP_TAB_DISPLAY then
        SHOP_TAB_DISPLAY = {
            All = getText("IGUI_DCS_Shop_All"),
            Tools = getText("IGUI_DCS_Shop_TabTools"),
            Weapons = getText("IGUI_DCS_Shop_TabWeapons"),
            Equipment = getText("IGUI_DCS_Shop_TabEquipment"),
            Clothing = getText("IGUI_DCS_Shop_TabClothing"),
            Medical = getText("IGUI_DCS_Shop_TabMedical"),
            Food = getText("IGUI_DCS_Shop_TabFood"),
            Literature = getText("IGUI_DCS_Shop_TabLiterature"),
            Materials = getText("IGUI_DCS_Shop_TabMaterials"),
            Other = getText("IGUI_DCS_Shop_TabOther"),
        }
    end
    return SHOP_TAB_DISPLAY
end

local function resolveTabCategory(title)
    for key, display in pairs(getTabDisplay()) do
        if display == title then return key end
    end
    return title
end

function DCS_ShopAdmin_Window:createChildren()
    ISCollapsableWindow.createChildren(self)

    local titleH = fontHgt + S(1)
    local y = titleH + PAD

    if self.infoButton then
        self.infoButton:setVisible(true)
        self.infoButton.onclick = DCS_ShopAdmin_Window.onHelp
        self.infoButton.target = self
        self.infoButton.tooltip = getText("IGUI_DCS_ShopAdmin_HelpButtonTooltip")
    end

    self.searchEntry = ISTextEntryBox:new("", PAD, y, PANEL_W - PAD * 2, fontHgt + S(5))
    self.searchEntry:initialise()
    self.searchEntry:instantiate()
    self.searchEntry.javaObject = self.searchEntry.javaObject
    self.searchEntry:setPlaceholderText(getText("IGUI_DCS_ShopAdmin_SearchPlaceholder"))
    self.lastSearchText = ""
    self:addChild(self.searchEntry)
    y = y + S(30)

    local defItems = DCS_Challenges.Shop or {}
    self.lblInfo = ISLabel:new(PAD, y, S(16), "",
        COL_DIM.r, COL_DIM.g, COL_DIM.b, 1, FONT_SM, true)
    self.lblInfo:initialise()
    self:addChild(self.lblInfo)
    y = y + S(18)

    local row1 = { "All", "Tools", "Weapons", "Equipment", "Clothing" }
    local row2 = { "Medical", "Food", "Literature", "Materials", "Other" }
    local totalTabW = PANEL_W - PAD * 2
    local tabW = math.floor(totalTabW / 5)
    local tabH = S(20)
    self.catTabs = {}
    self.activeCategory = "All"

    local function makeTab(name, col, r)
        local displayName = getTabDisplay()[name] or name
        local tab = ISButton:new(PAD + (col - 1) * tabW, y + (r - 1) * (tabH + S(2)), tabW, tabH,
            displayName, self, DCS_ShopAdmin_Window.onCategoryTab)
        tab:initialise()
        tab:instantiate()
        tab.background = true
        tab.isBaseBackgroundVisible = true
        tab.borderColor = { r=0.30, g=0.30, b=0.30, a=1.0 }
        self:addChild(tab)
        self.catTabs[name] = tab
    end

    for i, name in ipairs(row1) do makeTab(name, i, 1) end
    for i, name in ipairs(row2) do makeTab(name, i, 2) end
    self:updateTabColors()
    y = y + (tabH + S(2)) * 2 + S(4)

    self.currentPage = 1
    self.totalPages = 1
    self.allShopItems = {}
    self.filteredItems = {}
    self.displayItems = {}

    local listH = ITEMS_PER_PAGE * ROW_H + S(2)
    self.itemList = ISScrollingListBox:new(PAD, y, PANEL_W - PAD * 2, listH)
    self.itemList:initialise()
    self.itemList:instantiate()
    self.itemList.itemheight = ROW_H
    self.itemList.selected = 0
    self.itemList.font = FONT_SM
    self.itemList.doDrawItem = DCS_ShopAdmin_Window.drawItemRow
    self.itemList.drawBorder = true
    self.itemList:setOnMouseDownFunction(self, DCS_ShopAdmin_Window.onRowClicked)
    if self.itemList.vscroll then
        self.itemList.vscroll:setVisible(false)
    end
    self:addChild(self.itemList)

    local yBtn = PANEL_H - BTN_H - S(8)
    local gap = S(8)

    self.btnAddItems = ISButton:new(PAD, yBtn, S(100), BTN_H,
        getText("IGUI_DCS_ShopAdmin_AddSelected"), self, DCS_ShopAdmin_Window.onAddItems)
    self.btnAddItems:initialise()
    self.btnAddItems:instantiate()
    self:addChild(self.btnAddItems)

    self.btnSave = ISButton:new(PAD, yBtn, S(80), BTN_H,
        getText("IGUI_DCS_ShopAdmin_Save"), self, DCS_ShopAdmin_Window.onSave)
    self.btnSave:initialise()
    self.btnSave:instantiate()
    self.btnSave:enableAcceptColor()
    self:addChild(self.btnSave)

    self.btnCancel = ISButton:new(0, yBtn, S(80), BTN_H,
        getText("IGUI_DCS_ShopAdmin_Cancel"), self, DCS_ShopAdmin_Window.onCancel)
    self.btnCancel:initialise()
    self.btnCancel:instantiate()
    self.btnCancel:enableCancelColor()
    self:addChild(self.btnCancel)

    local tmgr = getTextManager()
    local function fitWidth(b, minW)
        local w = math.max(minW, tmgr:MeasureStringX(b.font or FONT_SM, b.title or "") + S(20))
        b:setWidth(w)
        return w
    end
    local saveW = fitWidth(self.btnSave, S(80))
    local addW = fitWidth(self.btnAddItems, S(100))
    local cancelW = fitWidth(self.btnCancel, S(80))
    self.btnSave:setX(PAD)
    self.btnAddItems:setX(math.floor((PANEL_W - addW) / 2))
    self.btnCancel:setX(PANEL_W - PAD - cancelW)

    local pagY = PANEL_H - BTN_H - S(8) - BTN_H - S(8)
    local btnPagW = S(60)
    local pagH = BTN_H

    self.btnPrev = ISButton:new(PAD, pagY, btnPagW, pagH,
        getText("IGUI_DCS_ShopAdmin_Prev"), self, DCS_ShopAdmin_Window.onPrevPage)
    self.btnPrev:initialise()
    self.btnPrev:instantiate()
    self:addChild(self.btnPrev)

    self.pageEntry = ISTextEntryBox:new("1", PAD + btnPagW + S(4), pagY, S(40), pagH)
    self.pageEntry:initialise()
    self.pageEntry:instantiate()
    self.pageEntry.font = FONT_SM
    self.pageEntry:setOnlyNumbers(true)
    self.pageEntry.onCommandEntered = function(_)
        self:onPageEntry()
    end
    self:addChild(self.pageEntry)

    self.pageLabel = ISLabel:new(PAD + btnPagW + S(48), pagY + S(4), S(16),
        getText("IGUI_DCS_ShopAdmin_PageLabel", 1),
        COL_DIM.r, COL_DIM.g, COL_DIM.b, 1, FONT_SM, true)
    self.pageLabel:initialise()
    self:addChild(self.pageLabel)

    self.btnNext = ISButton:new(PANEL_W - PAD - btnPagW, pagY, btnPagW, pagH,
        getText("IGUI_DCS_ShopAdmin_Next"), self, DCS_ShopAdmin_Window.onNextPage)
    self.btnNext:initialise()
    self.btnNext:instantiate()
    self:addChild(self.btnNext)

    self:loadConfig()
    self:rebuildItems()
end

function DCS_ShopAdmin_Window:initialise()
    ISCollapsableWindow.initialise(self)
end

function DCS_ShopAdmin_Window:loadConfig()
    local cfg = DCS_Sync.State.shopConfig or {}
    self.pendingChanges = { enabledItems = {}, customCosts = {}, customStock = {} }

    for _, id in ipairs(cfg.enabledItems or {}) do
        self.pendingChanges.enabledItems[#self.pendingChanges.enabledItems + 1] = id
    end
    if cfg.customCosts then
        for k, v in pairs(cfg.customCosts) do self.pendingChanges.customCosts[k] = v end
    end
    if cfg.customStock then
        for k, v in pairs(cfg.customStock) do self.pendingChanges.customStock[k] = v end
    end
end

function DCS_ShopAdmin_Window:isItemEnabled(itemId)
    for _, id in ipairs(self.pendingChanges.enabledItems) do
        if id == itemId then return true end
    end
    return false
end

function DCS_ShopAdmin_Window:toggleItem(itemId)
    local newEnabled = {}
    for _, id in ipairs(self.pendingChanges.enabledItems) do
        if id ~= itemId then newEnabled[#newEnabled + 1] = id end
    end
    if not self:isItemEnabled(itemId) then
        newEnabled[#newEnabled + 1] = itemId
    end
    self.pendingChanges.enabledItems = newEnabled
end

function DCS_ShopAdmin_Window:rebuildItems()
    self.itemList:clear()

    local cfg = DCS_Sync.State.shopConfig or {}
    if not cfg.enabledItems or #cfg.enabledItems == 0 then
        local player = getSpecificPlayer(0)
        if player then
            sendClientCommand(player, "DailyChallengeSystem", "requestSync", {})
        end
    end

    self.allShopItems = {}
    local defItems = DCS_Challenges.Shop or {}
    local defIds = {}
    local sm = getScriptManager and getScriptManager()
    local debugNameCount = 0

    local nameLookup = {}
    if sm then
        local allScriptItems = sm:getAllItems()
        if allScriptItems then
            for i = 0, allScriptItems:size() - 1 do
                local si = allScriptItems:get(i)
                if si then
                    local ft = si:getFullName()
                    local dn = si:getDisplayName()
                    if ft and dn and dn ~= "" then
                        nameLookup[ft] = dn
                    end
                end
            end
        end
    end
    local lookupCount = 0
    for _ in pairs(nameLookup) do lookupCount = lookupCount + 1 end
    DCS_dprint("[DCS_SHOP] rebuildItems: nameLookup has " .. lookupCount .. " entries")
    local debugCount = 0
    for k, v in pairs(nameLookup) do
        if debugCount < 3 then
            DCS_dprint("[DCS_SHOP]   nameLookup[" .. k .. "] = " .. v)
            debugCount = debugCount + 1
        end
    end

    for _, item in ipairs(defItems) do
        defIds[item.itemId] = true
        if self:isItemEnabled(item.itemId) then
            local cost = self.pendingChanges.customCosts[item.itemId] or item.cost
            local sr = self.pendingChanges.customStock[item.itemId] or item.quantities
            local icon = getItemIcon(item.itemId)
            local displayName = nameLookup[item.itemId] or item.itemId
            local category = DCS_ShopCategoryResolver.resolveFromItemId(item.itemId)
            self.allShopItems[#self.allShopItems + 1] = {
                itemData = item, enabled = true,
                cost = cost, stockMin = sr and sr[1] or 1, stockMax = sr and sr[2] or 1,
                icon = icon, displayName = displayName, category = category,
            }
        end
    end

    for _, itemId in ipairs(self.pendingChanges.enabledItems) do
        if not defIds[itemId] then
            local cost = self.pendingChanges.customCosts[itemId] or 5
            local sr = self.pendingChanges.customStock[itemId] or {1, 3}
            local icon = getItemIcon(itemId)
            local displayName = nameLookup[itemId] or itemId
            local category = DCS_ShopCategoryResolver.resolveFromItemId(itemId)
            local pseudoItem = { itemId = itemId, displayName = displayName, cost = cost, quantities = sr }
            self.allShopItems[#self.allShopItems + 1] = {
                itemData = pseudoItem, enabled = true,
                cost = cost, stockMin = sr[1] or 1, stockMax = sr[2] or 1,
                icon = icon, displayName = displayName, category = category,
            }
        end
    end

    self:filterAndShowPage()

    if self.lblInfo then
        self.lblInfo:setName(getText("IGUI_DCS_ShopAdmin_ItemCount", #self.allShopItems))
    end
end

function DCS_ShopAdmin_Window:showPage()
    self.itemList:clear()
    local startIdx = (self.currentPage - 1) * ITEMS_PER_PAGE + 1
    local endIdx = math.min(startIdx + ITEMS_PER_PAGE - 1, #self.filteredItems)
    for i = startIdx, endIdx do
        local item = self.filteredItems[i]
        if item then
            self.itemList:addItem(item.displayName, item)
        end
    end
    if self.pageEntry then self.pageEntry:setText(tostring(self.currentPage)) end
    if self.pageLabel then
        self.pageLabel:setName(getText("IGUI_DCS_ShopAdmin_PageLabel", self.totalPages))
    end
    if self.btnPrev then self.btnPrev.enable = self.currentPage > 1 end
    if self.btnNext then self.btnNext.enable = self.currentPage < self.totalPages end
end

function DCS_ShopAdmin_Window:updateTabColors()
    for name, tab in pairs(self.catTabs) do
        local displayName = getTabDisplay()[name] or name
        if name == self.activeCategory then
            tab.textColor = { r = COL_ACCENT.r, g = COL_ACCENT.g, b = COL_ACCENT.b, a = 1 }
        else
            tab.textColor = { r = 1.0, g = 1.0, b = 1.0, a = 1 }
        end
        tab:setTitle(displayName)
    end
end

function DCS_ShopAdmin_Window:onCategoryTab(btn)
    local title = btn and btn.title or "All"
    self.activeCategory = resolveTabCategory(title)
    self.currentPage = 1
    DCS_dprint("[DCS_SHOP] onCategoryTab: title=" .. tostring(title) .. " category=" .. tostring(self.activeCategory))
    self:updateTabColors()
    self:filterAndShowPage()
end

function DCS_ShopAdmin_Window:onSearchChanged()
    local searchText = self.searchEntry:getText() or ""
    if searchText ~= self.lastSearchText then
        self.lastSearchText = searchText
        self.currentPage = 1
        self:filterAndShowPage()
    end
end

function DCS_ShopAdmin_Window:filterAndShowPage()
    self.filteredItems = {}
    local searchText = string.lower(self.searchEntry:getText() or "")
    for _, item in ipairs(self.allShopItems) do
        local matchCat = self.activeCategory == "All" or item.category == self.activeCategory
        local matchSearch = searchText == ""
            or string.find(string.lower(item.displayName or ""), searchText, 1, true)
            or string.find(string.lower(item.itemData and item.itemData.itemId or ""), searchText, 1, true)
        if matchCat and matchSearch then
            self.filteredItems[#self.filteredItems + 1] = item
        end
    end
    DCS_dprint("[DCS_SHOP] filterAndShowPage: category=" .. tostring(self.activeCategory) .. " filtered=" .. #self.filteredItems .. " of " .. #self.allShopItems)
    local totalItems = #self.filteredItems
    self.totalPages = math.max(1, math.ceil(totalItems / ITEMS_PER_PAGE))
    self.currentPage = math.min(self.currentPage, self.totalPages)
    if self.lblInfo then
        self.lblInfo:setName(getText("IGUI_DCS_ShopAdmin_FilteredCount", totalItems))
    end
    self:showPage()
end

function DCS_ShopAdmin_Window:onPrevPage()
    if self.currentPage > 1 then
        self.currentPage = self.currentPage - 1
        self:showPage()
    end
end

function DCS_ShopAdmin_Window:onNextPage()
    if self.currentPage < self.totalPages then
        self.currentPage = self.currentPage + 1
        self:showPage()
    end
end

function DCS_ShopAdmin_Window:onPageEntry()
    local text = self.pageEntry:getText()
    local page = tonumber(text)
    if page and page >= 1 and page <= self.totalPages then
        self.currentPage = page
        self:showPage()
    end
end

function DCS_ShopAdmin_Window.onRowClicked(target, data)
    if not data or not data.itemData then return end
    local self = target
    local itemId = data.itemData.itemId

    local mouseX = target:getMouseX() - self.itemList:getX()
    local w = self.itemList:getWidth()

    if mouseX and mouseX > w - S(50) then
        self:toggleItem(itemId)
        self:rebuildItems()
        return
    end

    if mouseX and mouseX >= S(90) and mouseX <= S(160) then
        DCS_ShopValueDialog.open(getText("IGUI_DCS_ShopAdmin_EditCost"), data.cost or 0, function(newVal)
            if newVal and newVal > 0 then
                data.cost = newVal
                self.pendingChanges.customCosts[itemId] = newVal
            end
        end)
        return
    end

    if mouseX and mouseX >= S(225) and mouseX <= S(285) then
        DCS_ShopValueDialog.open(getText("IGUI_DCS_ShopAdmin_EditStockMin"), data.stockMin or 1, function(newVal)
            if newVal and newVal > 0 then
                data.stockMin = newVal
                self.pendingChanges.customStock[itemId] = { newVal, data.stockMax or 3 }
            end
        end)
        return
    end

    if mouseX and mouseX >= S(325) and mouseX <= S(385) then
        DCS_ShopValueDialog.open(getText("IGUI_DCS_ShopAdmin_EditStockMax"), data.stockMax or 3, function(newVal)
            if newVal and newVal > 0 then
                data.stockMax = newVal
                self.pendingChanges.customStock[itemId] = { data.stockMin or 1, newVal }
            end
        end)
        return
    end
end

function DCS_ShopAdmin_Window:drawItemRow(y, entry, alt)
    local data = entry.item
    local item = data.itemData
    local w = self:getWidth()
    local rowH = entry.height or ROW_H
    local icon = data.icon
    local enabled = data.enabled

    if alt then
        self:drawRect(0, y, w, rowH - S(1), 0.25, COL_ROW_ALT.r, COL_ROW_ALT.g, COL_ROW_ALT.b)
    end

    local iconX = S(14)
    local iconY = y + S(14)
    if icon then
        self:drawTextureScaled(icon, iconX, iconY, S(32), S(32), 1)
    else
        self:drawRect(iconX, iconY, S(32), S(32), 0.5, 0.3, 0.3, 0.3)
        self:drawRectBorder(iconX, iconY, S(32), S(32), 0.5, 0.5, 0.5, 0.5)
    end

    local textX = iconX + S(44)
    local nameCol = enabled and COL_TEXT or COL_DIM
    local maxNameW = w - textX - S(60)
    self:drawText(truncateText(data.displayName, FONT_MD, maxNameW), textX, y + S(4),
        nameCol.r, nameCol.g, nameCol.b, 0.90, FONT_MD)

    local maxIdW = w - textX - S(60)
    self:drawText(truncateText(item.itemId, FONT_SM, maxIdW), textX, y + S(32),
        COL_DIM.r, COL_DIM.g, COL_DIM.b, 0.70, FONT_SM)

    local checkSize = S(18)
    local checkX = w - checkSize - S(16)
    local checkY = y + math.floor((rowH - checkSize) / 2)
    self:drawRectBorder(checkX, checkY, checkSize, checkSize, 0.6, 0.6, 0.6, 0.6)
    if enabled then
        self:drawRect(checkX + S(3), checkY + S(3), checkSize - S(6), checkSize - S(6), 1,
            COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
    end

    local labelY = y + S(56)
    self:drawText(getText("IGUI_DCS_ShopAdmin_Cost"), textX, labelY,
        0.90, 0.90, 0.90, 0.90, FONT_SM)
    self:drawText(getText("IGUI_DCS_ShopAdmin_StockMin"), textX + S(112), labelY,
        0.90, 0.90, 0.90, 0.90, FONT_SM)
    self:drawText(getText("IGUI_DCS_ShopAdmin_StockMax"), textX + S(210), labelY,
        0.90, 0.90, 0.90, 0.90, FONT_SM)

    local fieldY = labelY
    self:drawText(tostring(data.cost or 0), textX + S(48), fieldY,
        COL_YELLOW.r, COL_YELLOW.g, COL_YELLOW.b, 0.95, FONT_SM)
    self:drawText(tostring(data.stockMin or 0), textX + S(180), fieldY,
        COL_YELLOW.r, COL_YELLOW.g, COL_YELLOW.b, 0.95, FONT_SM)
    self:drawText(tostring(data.stockMax or 0), textX + S(280), fieldY,
        COL_YELLOW.r, COL_YELLOW.g, COL_YELLOW.b, 0.95, FONT_SM)

    return y + rowH
end

function DCS_ShopAdmin_Window:onSave()
    local player = getSpecificPlayer(0)
    if not player then return end
    for _, entry in ipairs(self.itemList.items) do
        local data = entry.item
        local item = data.itemData
        local itemId = item.itemId
        if data.cost and data.cost > 0 then
            self.pendingChanges.customCosts[itemId] = data.cost
        end
        if data.stockMin and data.stockMax and data.stockMin > 0 and data.stockMax >= data.stockMin then
            self.pendingChanges.customStock[itemId] = { data.stockMin, data.stockMax }
        end
    end
    sendClientCommand(player, "DailyChallengeSystem", "shopAdminApply", {
        enabledItems = self.pendingChanges.enabledItems,
        customCosts = self.pendingChanges.customCosts,
        customStock = self.pendingChanges.customStock,
    })
    DCS_Sync.showToast(getText("IGUI_DCS_ShopAdmin_TraderConfigApplied"), "complete")
    if DCS_UI_Shop.instance then
        DCS_UI_Shop.instance:refreshList()
    end
    self:close()
end

function DCS_ShopAdmin_Window:onCancel()
    self:close()
end

function DCS_ShopAdmin_Window:onAddItems()
    DCS_ShopAddItemsWindow.open(self)
end

function DCS_ShopAdmin_Window:onHelp()
    DCS_UI_HelpWindow.open(getText("IGUI_DCS_ShopAdmin_HelpTitle"), {
        getText("IGUI_DCS_ShopAdmin_HelpHeading"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpIntro"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpSectionItemList"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpItemList"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpCheckbox"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpCostField"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpStockFields"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpSectionButtons"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpAddItems"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpSave"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpCancel"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpSectionTips"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpTipSave"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpTipDisabled"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpTipStock"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpSectionPricing"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpPricingIntro"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpPricingTier1"),
        getText("IGUI_DCS_ShopAdmin_HelpPricingTier2"),
        getText("IGUI_DCS_ShopAdmin_HelpPricingTier3"),
        getText("IGUI_DCS_ShopAdmin_HelpPricingTier4"),
        "",
        getText("IGUI_DCS_ShopAdmin_HelpPricingMax"),
    })
end

function DCS_ShopAdmin_Window:prerender()
    ISCollapsableWindow.prerender(self)
    self:drawRect(0, fontHgt + S(1), self.width, S(2), 1, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
    if self.searchEntry then
        local searchText = self.searchEntry:getText() or ""
        if searchText ~= (self.lastSearchText or "") then
            self.lastSearchText = searchText
            self.currentPage = 1
            self:filterAndShowPage()
        end
    end
end

function DCS_ShopAdmin_Window:close()
    DCS_Sync.saveWindowPos("shopadmin", self:getX(), self:getY())
    self:setVisible(false)
    self:removeFromUIManager()
    DCS_UI_ShopAdmin.instance = nil
end

DCS_ShopAddItemsWindow = {}
DCS_ShopAddItemsWindow.instance = nil

local ADD_W = S(440)
local ADD_H = S(1010)
local ADD_ROW_H = S(40)
local ADD_ITEMS_PER_PAGE = 20

DCS_ShopAddItems_Panel = ISCollapsableWindow:derive("DCS_ShopAddItems_Panel")

function DCS_ShopAddItems_Panel:new(x, y, adminWindow)
    local o = ISCollapsableWindow.new(self, x, y, ADD_W, ADD_H)
    o.moveWithMouse = true
    o.resizable = false
    o.adminWindow = adminWindow
    o.activeCategory = "All"
    return o
end

function DCS_ShopAddItems_Panel:createChildren()
    ISCollapsableWindow.createChildren(self)

    local titleH = fontHgt + S(1)
    local y = titleH + PAD

    self.searchEntry = ISTextEntryBox:new("", PAD, y, ADD_W - PAD * 2, fontHgt + S(5))
    self.searchEntry:initialise()
    self.searchEntry:instantiate()
    self.searchEntry.javaObject = self.searchEntry.javaObject
    self.searchEntry:setPlaceholderText(getText("IGUI_DCS_ShopAdmin_SearchPlaceholder"))
    self.lastSearchText = ""
    self:addChild(self.searchEntry)
    y = y + S(30)

    self.lblInfo = ISLabel:new(PAD, y, S(16), "",
        COL_DIM.r, COL_DIM.g, COL_DIM.b, 1, FONT_SM, true)
    self.lblInfo:initialise()
    self:addChild(self.lblInfo)
    y = y + S(18)

    local row1 = { "All", "Tools", "Weapons", "Equipment", "Clothing" }
    local row2 = { "Medical", "Food", "Literature", "Materials", "Other" }
    local totalTabW = ADD_W - PAD * 2
    local tabW = math.floor(totalTabW / 5)
    local tabH = S(20)
    self.catTabs = {}

    local function makeTab(name, col, r)
        local displayName = getTabDisplay()[name] or name
        local tab = ISButton:new(PAD + (col - 1) * tabW, y + (r - 1) * (tabH + S(2)), tabW, tabH,
            displayName, self, DCS_ShopAddItems_Panel.onCategoryTab)
        tab:initialise()
        tab:instantiate()
        tab.background = true
        tab.isBaseBackgroundVisible = true
        tab.borderColor = { r=0.30, g=0.30, b=0.30, a=1.0 }
        self:addChild(tab)
        self.catTabs[name] = tab
    end

    for i, name in ipairs(row1) do makeTab(name, i, 1) end
    for i, name in ipairs(row2) do makeTab(name, i, 2) end
    self:updateTabColors()
    y = y + (tabH + S(2)) * 2 + S(4)

    local listH = ADD_ITEMS_PER_PAGE * ADD_ROW_H
    self.itemList = ISScrollingListBox:new(PAD, y, ADD_W - PAD * 2, listH)
    self.itemList:initialise()
    self.itemList:instantiate()
    self.itemList.itemheight = ADD_ROW_H
    self.itemList.selected = 0
    self.itemList.font = FONT_SM
    self.itemList.doDrawItem = DCS_ShopAddItems_Panel.drawItemRow
    self.itemList.drawBorder = true
    self.itemList:setOnMouseDownFunction(self, DCS_ShopAddItems_Panel.onItemClicked)
    if self.itemList.vscroll then self.itemList.vscroll:setVisible(false) end
    self:addChild(self.itemList)
    y = y + listH + S(4)

    local pagY = ADD_H - BTN_H - S(8) - BTN_H - S(8)
    local pagH = fontHgt + S(5)
    local btnPagW = S(70)

    self.btnPrev = ISButton:new(PAD, pagY, btnPagW, pagH,
        getText("IGUI_DCS_ShopAdmin_Prev"), self, DCS_ShopAddItems_Panel.onPrevPage)
    self.btnPrev:initialise()
    self.btnPrev:instantiate()
    self:addChild(self.btnPrev)

    self.pageEntry = ISTextEntryBox:new("1", PAD + btnPagW + S(6), pagY, S(40), pagH)
    self.pageEntry:initialise()
    self.pageEntry:instantiate()
    self.pageEntry:setOnlyNumbers(true)
    self.pageEntry.javaObject = self.pageEntry.javaObject
    self.pageEntry.onCommandEntered = function(_)
        self:onPageInput()
    end
    self:addChild(self.pageEntry)

    self.pageLabel = ISLabel:new(PAD + btnPagW + S(52), pagY + S(4), S(16), getText("IGUI_DCS_ShopAdmin_PageLabel", 1),
        COL_DIM.r, COL_DIM.g, COL_DIM.b, 1, FONT_SM, true)
    self.pageLabel:initialise()
    self:addChild(self.pageLabel)

    self.btnNext = ISButton:new(ADD_W - PAD - btnPagW, pagY, btnPagW, pagH,
        getText("IGUI_DCS_ShopAdmin_Next"), self, DCS_ShopAddItems_Panel.onNextPage)
    self.btnNext:initialise()
    self.btnNext:instantiate()
    self:addChild(self.btnNext)

    y = y + pagH + S(18)

    self.btnSave = ISButton:new(PAD, y, S(80), BTN_H,
        getText("IGUI_DCS_ShopAdmin_Save"), self, DCS_ShopAddItems_Panel.onAdd)
    self.btnSave:initialise()
    self.btnSave:instantiate()
    self.btnSave:enableAcceptColor()
    self:addChild(self.btnSave)

    self.btnCancel = ISButton:new(ADD_W - PAD - S(80), y, S(80), BTN_H,
        getText("IGUI_DCS_ShopAdmin_Cancel"), self, DCS_ShopAddItems_Panel.onCancel)
    self.btnCancel:initialise()
    self.btnCancel:instantiate()
    self.btnCancel:enableCancelColor()
    self:addChild(self.btnCancel)

    local defaultIds = {}
    for _, item in ipairs(DCS_Challenges.Shop or {}) do
        defaultIds[item.itemId] = true
    end
    local cfg = DCS_Sync.State.shopConfig or {}
    local enabledSet = {}
    for _, id in ipairs(cfg.enabledItems or {}) do enabledSet[id] = true end
    local allDefaultsLoaded = true
    for id in pairs(defaultIds) do
        if not enabledSet[id] then allDefaultsLoaded = false; break end
    end
    self.defaultsLoaded = allDefaultsLoaded

    self.btnToggleDefaults = ISButton:new(0, y, S(180), BTN_H,
        allDefaultsLoaded and getText("IGUI_DCS_ShopAdmin_DisableDefaults")
                          or getText("IGUI_DCS_ShopAdmin_EnableDefaults"),
        self, DCS_ShopAddItems_Panel.onToggleDefaults)
    self.btnToggleDefaults:initialise()
    self.btnToggleDefaults:instantiate()
    self.btnToggleDefaults.tooltip = getText("IGUI_DCS_ShopAdmin_ToggleDefaultsTooltip")
    self:addChild(self.btnToggleDefaults)

    local tmgr = getTextManager()
    local function fitWidth(b, minW)
        local w = math.max(minW, tmgr:MeasureStringX(b.font or FONT_SM, b.title or "") + S(20))
        b:setWidth(w)
        return w
    end
    local toggleW = fitWidth(self.btnToggleDefaults, S(180))
    self.btnToggleDefaults:setX(math.floor((ADD_W - toggleW) / 2))

    self.currentPage = 1
    self.filteredItems = {}
    self.totalPages = 1

    self.checkedItems = {}
    self.allItems = {}
    self._itemByType = {}
    self._lastSearchTime = 0
    self._searchDebounceMs = 200
    self:loadAllItems()
    self:filterItems()

    self.itemList.adminPanel = self
end

function DCS_ShopAddItems_Panel:initialise()
    ISCollapsableWindow.initialise(self)
end

function DCS_ShopAddItems_Panel:updateTabColors()
    for name, tab in pairs(self.catTabs) do
        local displayName = getTabDisplay()[name] or name
        if name == self.activeCategory then
            tab.textColor = { r = COL_ACCENT.r, g = COL_ACCENT.g, b = COL_ACCENT.b, a = 1 }
        else
            tab.textColor = { r = 1.0, g = 1.0, b = 1.0, a = 1 }
        end
        tab:setTitle(displayName)
    end
end

function DCS_ShopAddItems_Panel:onCategoryTab(btn)
    local title = btn and btn.title or "All"
    self.activeCategory = resolveTabCategory(title)
    self.currentPage = 1
    self:updateTabColors()
    self:filterItems()
end

local EXCLUDED_ITEM_TYPES = {
    ["Base.FISH_DEV_ITEM"] = true,
    ["Base.Mov_FlagAdmin"] = true,
    ["Base.WaterDrop"] = true,
    ["Base.MysteryCan_Open"] = true,
    ["Base.Stairs"] = true,
    ["Base.DebugFluid"] = true,
    ["Base.TestDebugWater"] = true,
    ["Base.TestWaterMug"] = true,
    ["Base.TestMug"] = true,
    ["Base.TestHotDrink"] = true,
    ["Base.Hat_SantaHatDebug"] = true,
    ["Base.DentedCan_Open"] = true,
    ["Base.YardstickDEBUG"] = true,
    ["Base.Animal_Item_Dummy"] = true,
    ["Base.WaterRationCan_Open"] = true,
    ["Base.BucketWaterDebug"] = true,
}

function DCS_ShopAddItems_Panel:loadAllItems()
    if _allItemsCache and (os.time() - _allItemsCacheTime) < 60 then
        self.allItems = _allItemsCache
        return
    end
    self.allItems = {}
    local sm = getScriptManager and getScriptManager()
    if not sm then return end
    local allScriptItems = sm:getAllItems()
    if not allScriptItems then return end

    local enabledIds = {}
    if self.adminWindow and self.adminWindow.pendingChanges then
        for _, id in ipairs(self.adminWindow.pendingChanges.enabledItems or {}) do
            enabledIds[id] = true
        end
    end

    local otherCount = 0
    for i = 0, allScriptItems:size() - 1 do
        local si = allScriptItems:get(i)
        if si then
            local ft = si:getFullName()
            local dn = si:getDisplayName()
            if ft and EXCLUDED_ITEM_TYPES[ft] then
            elseif dn and string.find(string.lower(dn), "debug", 1, true) then
            elseif ft and string.find(string.lower(ft), "debug", 1, true) then
            elseif ft and dn and dn ~= ""
                and not si:getObsolete() and not si:isHidden() then
                local cat = self:categoriseItem(si, ft)
                if cat then
                    local icon = getItemIcon(ft) or false
                    self.allItems[#self.allItems + 1] = {
                        fullType = ft, displayName = dn,
                        category = cat, checked = enabledIds[ft] or false,
                        icon = icon,
                    }
                    if cat == "Other" then
                        otherCount = otherCount + 1
                        if otherCount <= 50 then
                            local displayCat = si.getDisplayCategory and si:getDisplayCategory() or "nil"
                            DCS_dprint("[DCS_SHOP] Other category: " .. ft .. " (DisplayCategory=" .. displayCat .. ")")
                        end
                    end
                end
            end
        end
    end
    DCS_dprint("[DCS_SHOP] loadAllItems: " .. #self.allItems .. " items loaded, " .. otherCount .. " in Other category")
    table.sort(self.allItems, function(a, b) return a.displayName < b.displayName end)
    _allItemsCache = self.allItems
    _allItemsCacheTime = os.time()

    self._itemByType = {}
    for _, item in ipairs(self.allItems) do
        self._itemByType[item.fullType] = item
    end
end

function DCS_ShopAddItems_Panel:categoriseItem(scriptItem, fullType)
    return DCS_ShopCategoryResolver.resolve(scriptItem, fullType)
end

function DCS_ShopAddItems_Panel:filterItems()
    self.filteredItems = {}
    local searchText = ""
    if self.searchEntry then searchText = string.lower(self.searchEntry:getText() or "") end

    if searchText ~= "" and #searchText < 2 then
        self.lblInfo:setName(getText("IGUI_DCS_ShopAdmin_SearchHint"))
        self.totalPages = 1
        self.currentPage = 1
        self:showPage()
        return
    end

    for _, item in ipairs(self.allItems) do
        local matchCat = self.activeCategory == "All" or item.category == self.activeCategory
        local matchSearch = searchText == ""
            or string.find(string.lower(item.displayName), searchText, 1, true)
            or string.find(string.lower(item.fullType), searchText, 1, true)
        if matchCat and matchSearch then
            self.filteredItems[#self.filteredItems + 1] = item
        end
    end

    self.totalPages = math.max(1, math.ceil(#self.filteredItems / ADD_ITEMS_PER_PAGE))
    self.currentPage = math.min(self.currentPage, self.totalPages)
    self:showPage()
end

function DCS_ShopAddItems_Panel:showPage()
    self.itemList:clear()
    local startIdx = (self.currentPage - 1) * ADD_ITEMS_PER_PAGE + 1
    local endIdx = math.min(startIdx + ADD_ITEMS_PER_PAGE - 1, #self.filteredItems)
    for i = startIdx, endIdx do
        local item = self.filteredItems[i]
        local entry = self.itemList:addItem(item.displayName, item)
        entry.height = ADD_ROW_H
    end

    if #self.filteredItems > 0 then
        self.lblInfo:setName(getText("IGUI_DCS_ShopAdmin_FilteredCount", #self.filteredItems))
    else
        self.lblInfo:setName(getText("IGUI_DCS_ShopAdmin_ZeroCount"))
    end

    if self.pageEntry then self.pageEntry:setText(tostring(self.currentPage)) end
    if self.pageLabel then self.pageLabel:setName(getText("IGUI_DCS_ShopAdmin_PageLabel", self.totalPages)) end
    if self.btnPrev then self.btnPrev.enable = self.currentPage > 1 end
    if self.btnNext then self.btnNext.enable = self.currentPage < self.totalPages end
end

function DCS_ShopAddItems_Panel:onPrevPage()
    if self.currentPage > 1 then
        self.currentPage = self.currentPage - 1
        self:showPage()
    end
end

function DCS_ShopAddItems_Panel:onNextPage()
    if self.currentPage < self.totalPages then
        self.currentPage = self.currentPage + 1
        self:showPage()
    end
end

function DCS_ShopAddItems_Panel:onPageInput()
    local page = tonumber(self.pageEntry:getText()) or 1
    page = math.max(1, math.min(page, self.totalPages))
    self.currentPage = page
    self:showPage()
end

function DCS_ShopAddItems_Panel:drawItemRow(y, entry, alt)
    local data = entry.item
    local w = self:getWidth()
    if alt then self:drawRect(0, y, w, ADD_ROW_H - S(1), 0.25, COL_ROW_ALT.r, COL_ROW_ALT.g, COL_ROW_ALT.b) end

    local iconX = S(14)
    local iconY = y + S(6)
    local icon = data.icon
    if icon == false then icon = nil end
    if icon then
        self:drawTextureScaled(icon, iconX, iconY, S(28), S(28), 1)
    else
        self:drawRect(iconX, iconY, S(28), S(28), 0.5, 0.3, 0.3, 0.3)
        self:drawRectBorder(iconX, iconY, S(28), S(28), 0.5, 0.5, 0.5, 0.5)
    end

    local textX = iconX + S(36)
    local checkSize = S(16)
    local checkX = w - checkSize - S(20)
    local checkY = y + math.floor((ADD_ROW_H - checkSize) / 2)

    local maxTextW = checkX - textX - S(8) - getTextManager():MeasureStringX(FONT_SM, "MMM")
    self:drawText(truncateText(data.displayName, FONT_SM, maxTextW), textX, y + S(1),
        0.90, 0.90, 0.90, 0.90, FONT_SM)
    self:drawText(truncateText(data.fullType, FONT_SM, maxTextW), textX, y + S(18),
        COL_DIM.r, COL_DIM.g, COL_DIM.b, 0.60, FONT_SM)

    self:drawRectBorder(checkX, checkY, checkSize, checkSize, 0.6, 0.6, 0.6, 0.6)
    if data.checked then
        self:drawRect(checkX + S(2), checkY + S(2), checkSize - S(4), checkSize - S(4), 1,
            COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
    end
    return y + ADD_ROW_H
end

function DCS_ShopAddItems_Panel.onItemClicked(target, data)
    if not data or not data.fullType then return end
    data.checked = not data.checked
    local panel = target.adminPanel
    if panel and panel._itemByType then
        local item = panel._itemByType[data.fullType]
        if item then item.checked = data.checked end
    end
end

function DCS_ShopAddItems_Panel:onAdd()
    if not self.adminWindow then return end
    local added = 0
    local removed = 0

    local checkedIds = {}
    for _, item in ipairs(self.allItems) do
        if item.checked then
            checkedIds[item.fullType] = true
        end
    end

    local newEnabled = {}
    for _, id in ipairs(self.adminWindow.pendingChanges.enabledItems) do
        if checkedIds[id] then
            newEnabled[#newEnabled + 1] = id
        else
            removed = removed + 1
        end
    end

    for _, item in ipairs(self.allItems) do
        if item.checked then
            local exists = false
            for _, id in ipairs(newEnabled) do
                if id == item.fullType then exists = true; break end
            end
            if not exists then
                newEnabled[#newEnabled + 1] = item.fullType
                added = added + 1
            end
        end
    end

    self.adminWindow.pendingChanges.enabledItems = newEnabled

    _allItemsCache = nil
    _allItemsCacheTime = 0

    if self._pendingToggleDefaults ~= nil then
        local player = getSpecificPlayer(0)
        if player then
            sendClientCommand(player, "DailyChallengeSystem", "toggleDefaultItems", { enable = self._pendingToggleDefaults })
        end
        self._pendingToggleDefaults = nil
    end

    if added > 0 or removed > 0 then
        self.adminWindow:rebuildItems()
        local msg = getText("IGUI_DCS_ShopAdmin_AddedItems", added)
        if removed > 0 then
            msg = msg .. " | Removed: " .. removed
        end
        DCS_Sync.showToast(msg, "complete")
    end
    self:close()
end

function DCS_ShopAddItems_Panel:onCloseBtn() self:close() end

function DCS_ShopAddItems_Panel:onCancel()
    self._pendingToggleDefaults = nil
    _allItemsCache = nil
    _allItemsCacheTime = 0
    self:close()
end

function DCS_ShopAddItems_Panel:onToggleDefaults()
    local enable = not self.defaultsLoaded

    local defaultIds = {}
    for _, item in ipairs(DCS_Challenges.Shop or {}) do
        defaultIds[item.itemId] = true
    end
    for _, item in ipairs(self.allItems or {}) do
        if defaultIds[item.fullType] then
            item.checked = enable
        end
    end
    self.defaultsLoaded = enable

    if self.btnToggleDefaults then
        self.btnToggleDefaults:setTitle(
            enable and getText("IGUI_DCS_ShopAdmin_DisableDefaults")
                   or getText("IGUI_DCS_ShopAdmin_EnableDefaults")
        )
    end

    self:filterItems()

    self._pendingToggleDefaults = enable
end

function DCS_ShopAddItems_Panel:onToggleDefaultsResult(args)
    if not args then return end
    self.defaultsLoaded = args.enabled

    if self.btnToggleDefaults then
        self.btnToggleDefaults:setTitle(
            args.enabled and getText("IGUI_DCS_ShopAdmin_DisableDefaults")
                          or getText("IGUI_DCS_ShopAdmin_EnableDefaults")
        )
    end

    local defaultIds = {}
    for _, item in ipairs(DCS_Challenges.Shop or {}) do
        defaultIds[item.itemId] = true
    end

    for _, item in ipairs(self.allItems or {}) do
        if defaultIds[item.fullType] then
            item.checked = args.enabled
        end
    end

    _allItemsCache = nil
    _allItemsCacheTime = 0

    self:filterItems()

    local player = getSpecificPlayer(0)
    if player then
        sendClientCommand(player, "DailyChallengeSystem", "requestSync", {})
    end
end

function DCS_ShopAddItems_Panel:prerender()
    ISCollapsableWindow.prerender(self)
    self:drawRect(0, fontHgt + S(1), self.width, S(2), 1, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
    if self.searchEntry then
        local currentText = self.searchEntry:getText() or ""
        if currentText ~= self.lastSearchText then
            local now = os.time() * 1000
            if (now - self._lastSearchTime) >= self._searchDebounceMs then
                self.lastSearchText = currentText
                self._lastSearchTime = now
                self.currentPage = 1
                self:filterItems()
            end
        end
    end
    if self.pageEntry and not self.pageEntry:isFocused() then
        local pageText = self.pageEntry:getText() or ""
        local page = tonumber(pageText) or 1
        if page ~= self.currentPage then
            self.currentPage = math.max(1, math.min(page, self.totalPages))
            self:showPage()
        end
    end
end

function DCS_ShopAddItems_Panel:close()
    DCS_Sync.saveWindowPos("additems", self:getX(), self:getY())
    self:setVisible(false)
    self:removeFromUIManager()
    DCS_ShopAddItemsWindow.instance = nil
end

function DCS_ShopAddItemsWindow.open(adminWindow)
    if DCS_ShopAddItemsWindow.instance then DCS_ShopAddItemsWindow.instance:close() end
    local screenW = getPlayerScreenWidth(0)
    local screenH = getPlayerScreenHeight(0)
    local winH = math.min(ADD_H, screenH - 20)
    local x, y = DCS_Sync.getWindowPos("additems",
        math.floor((screenW - ADD_W) / 2), math.max(10, math.floor((screenH - winH) / 2)))
    x = math.max(0, math.min(x, screenW - ADD_W))
    y = math.max(0, math.min(y, screenH - winH))
    local win = DCS_ShopAddItems_Panel:new(x, y, adminWindow)
    win:setHeight(winH)
    win:initialise()
    win:instantiate()
    win:addToUIManager()
    win:setTitle(getText("IGUI_DCS_ShopAdmin_AddItemsTitle"))
    DCS_ShopAddItemsWindow.instance = win
end

function DCS_UI_ShopAdmin.open()
    if not hasShopAdminAccess() then print("[DCS] Shop Admin: access denied"); return end
    if DCS_UI_ShopAdmin.instance then DCS_UI_ShopAdmin.instance:setVisible(true); return end
    local player = getSpecificPlayer(0)
    if player then
        sendClientCommand(player, "DailyChallengeSystem", "requestSync", {})
    end
    local screenW = getPlayerScreenWidth(0)
    local screenH = getPlayerScreenHeight(0)
    local x, y = DCS_Sync.getWindowPos("shopadmin",
        math.floor((screenW - PANEL_W) / 2), math.floor((screenH - PANEL_H) / 2))
    x = math.max(0, math.min(x, screenW - PANEL_W))
    y = math.max(0, math.min(y, screenH - PANEL_H))
    local win = DCS_ShopAdmin_Window:new(x, y)
    win:initialise()
    win:instantiate()
    win:addToUIManager()
    win:setTitle(getText("IGUI_DCS_ShopAdmin_Title"))
    DCS_UI_ShopAdmin.instance = win
end

function DCS_UI_ShopAdmin.close()
    if DCS_UI_ShopAdmin.instance then DCS_UI_ShopAdmin.instance:close() end
end

function DCS_UI_ShopAdmin.toggle()
    if DCS_UI_ShopAdmin.instance and DCS_UI_ShopAdmin.instance:getIsVisible() then
        DCS_UI_ShopAdmin.close()
    else
        DCS_UI_ShopAdmin.open()
    end
end
