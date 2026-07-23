if isServer() and not isClient() then return end

require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "ISUI/ISButton"
require "ISUI/ISLabel"
require "ISUI/ISTextEntryBox"
require "DCS_UI_Scale"
require "DCS_Translate"

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

DCS_UI_Shop = {}
DCS_UI_Shop.instance = nil

local FONT_SM = UIFont.Small
local FONT_MD = UIFont.Medium
local S = DCS_UI_Scale.s
local fontHgt = DCS_UI_Scale.fontHgt
local fontHgtMd = DCS_UI_Scale.fontHgtMd

local function truncateText(text, font, maxWidth)
    if not text or not font then return text or "" end
    local tmgr = getTextManager()
    if tmgr:MeasureStringX(font, text) <= maxWidth then return text end
    while #text > 0 and tmgr:MeasureStringX(font, text .. "...") > maxWidth do
        text = string.sub(text, 1, #text - 1)
    end
    return text .. "..."
end

local SHOP_W = math.max(S(480), fontHgt * 25 + S(5))
local SHOP_H = S(600) + fontHgt
local TAB_H = fontHgt + S(9)
local PAD = S(10)
local ROW_H = fontHgtMd + S(39)
local FOOTER_H = fontHgt * 3 + S(4)
local BTN_H = fontHgt + S(9)
local TITLE_BAR_H = fontHgt + S(1)

local AMOUNT_W = math.max(S(280), fontHgt * 15)
local AMOUNT_H = math.max(S(250), fontHgt * 12 + S(26))
local CONFIRM_W = math.max(S(320), fontHgt * 17)
local CONFIRM_H = math.max(S(200), fontHgt * 10 + S(14))

local COL_BG = { r=0.12, g=0.12, b=0.12 }
local COL_ACCENT = { r=0.95, g=0.75, b=0.20 }
local COL_PENDING = { r=0.70, g=0.70, b=0.70 }
local COL_TAB_INACT = { r=0.10, g=0.10, b=0.10 }
local COL_STOCK_LOW = { r=0.90, g=0.30, b=0.30 }
local COL_STOCK_OK = { r=0.30, g=0.80, b=0.35 }

local function getItemIcon(itemId)
    local sm = getScriptManager and getScriptManager()
    if not sm then return nil end
    local scriptItem = sm:FindItem(itemId)
    if scriptItem then
        local icon = nil
        local icons = scriptItem:getIconsForTexture()
        if icons and not icons:isEmpty() then
            icon = icons:get(0)
        end
        if not icon then
            icon = scriptItem:getIcon()
        end
        if icon then
            return getTexture("Item_" .. icon)
        end
    end
    return nil
end

local function categoriseItemForShop(scriptItem, itemId)
    return DCS_ShopCategoryResolver.resolve(scriptItem, itemId)
end

local function resolveShopItemClient(itemId)
    local def = nil
    for _, item in ipairs(DCS_Challenges.Shop or {}) do
        if item.itemId == itemId then def = item; break end
    end
    if not def then return nil end
    local cfg = DCS_Sync.State.shopConfig or {}
    local resolved = {}
    for k, v in pairs(def) do resolved[k] = v end
    if cfg.customCosts and cfg.customCosts[itemId] then resolved.cost = cfg.customCosts[itemId] end
    if cfg.customStock and cfg.customStock[itemId] then resolved.quantities = cfg.customStock[itemId] end
    resolved.category = DCS_ShopCategoryResolver.resolveFromItemId(itemId)
    if not resolved.displayName then
        local sm = getScriptManager and getScriptManager()
        if sm then
            local si = nil
            if sm.FindItem then si = sm:FindItem(itemId) end
            if not si and sm.getItem then si = sm:getItem(itemId) end
            if si then
                if si.getDisplayName then
                    local dn = si:getDisplayName()
                    if dn and dn ~= "" then resolved.displayName = dn end
                end
            end
        end
        resolved.displayName = resolved.displayName or itemId
    end
    return resolved
end

local function isShopItemEnabled(itemId)
    local cfg = DCS_Sync.State.shopConfig or {}
    local items = cfg.enabledItems or {}
    for _, id in ipairs(items) do
        if id == itemId then return true end
    end
    return false
end

DCS_Shop_Window = ISCollapsableWindow:derive("DCS_Shop_Window")

function DCS_Shop_Window:new(x, y, side, npc)
    local o = ISCollapsableWindow.new(self, x, y, SHOP_W, SHOP_H)
    o.moveWithMouse = true
    o.anchorLeft = true
    o.anchorRight = true
    o.anchorTop = true
    o.anchorBottom = true
    o.resizable = false
    o.activeCategory = "All"
    o.side = (side == "west") and "west" or "east"
    o.traderNPC = npc
    return o
end

function DCS_Shop_Window:createChildren()
    ISCollapsableWindow.createChildren(self)

    local titleBarH = TITLE_BAR_H
    local catY = titleBarH + PAD

    self.categoryTabs = {}
    local row1 = { "All", "Tools", "Weapons", "Equipment", "Clothing" }
    local row2 = { "Medical", "Food", "Literature", "Materials", "Other" }
    local totalTabW = SHOP_W - PAD * 2
    local tabW = math.floor(totalTabW / 5)
    local tabH = S(20)

    local function makeTab(name, col, r)
        local displayName = name
        if SHOP_TAB_DISPLAY and SHOP_TAB_DISPLAY[name] then
            displayName = SHOP_TAB_DISPLAY[name]
        else
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
            displayName = SHOP_TAB_DISPLAY[name] or name
        end
        local tab = ISButton:new(PAD + (col - 1) * tabW, catY + (r - 1) * (tabH + S(2)), tabW, tabH,
            displayName, self, DCS_Shop_Window.onCategoryTab)
        tab:initialise()
        tab:instantiate()
        tab.background = true
        tab.isBaseBackgroundVisible = true
        tab.borderColor = { r=0.30, g=0.30, b=0.30, a=1.0 }
        self:addChild(tab)
        self.categoryTabs[name] = tab
    end

    for i, name in ipairs(row1) do makeTab(name, i, 1) end
    for i, name in ipairs(row2) do makeTab(name, i, 2) end

    self:updateTabColors()

    local listY = catY + (tabH + S(2)) * 2 + PAD
    local listH = SHOP_H - listY - FOOTER_H - PAD * 2

    self.itemList = ISScrollingListBox:new(PAD, listY, SHOP_W - PAD * 2, listH)
    self.itemList:initialise()
    self.itemList:instantiate()
    self.itemList.itemheight = ROW_H
    self.itemList.selected = 0
    self.itemList.font = FONT_SM
    self.itemList.doDrawItem = DCS_Shop_Window.drawItemRow
    self.itemList.drawBorder = true
    if self.itemList.vscroll then
        self.itemList.vscroll:setVisible(false)
    end
    self.itemList:setOnMouseDownFunction(self, DCS_Shop_Window.onItemClicked)
    self:addChild(self.itemList)

    DCS_Sync.Events.subscribe(DCS_Sync.Events.onShopStockUpdated,
        function(stock) self:refreshList() end)
    DCS_Sync.Events.subscribe(DCS_Sync.Events.onPurchaseResult,
        function(success, newTotal, itemId) self:refreshList() end)
    DCS_Sync.Events.subscribe(DCS_Sync.Events.onShopConfigUpdated,
        function(config) self:refreshList() end)
end

function DCS_Shop_Window:initialise()
    ISCollapsableWindow.initialise(self)
end

local PROXIMITY_CLOSE_DIST = 5

function DCS_Shop_Window:update()
    ISCollapsableWindow.update(self)

    local npc = self.traderNPC
    if not npc then return end

    local player = getSpecificPlayer(0)
    if not player then return end

    local shouldClose = false
    if not npc:getSquare() then
        shouldClose = true
    elseif instanceof(npc, "IsoGameCharacter") and npc:isDead() then
        shouldClose = true
    else
        local dx = player:getX() - npc:getX()
        local dy = player:getY() - npc:getY()
        if (dx * dx + dy * dy) > (PROXIMITY_CLOSE_DIST * PROXIMITY_CLOSE_DIST) then
            shouldClose = true
        end
    end
    if shouldClose then
        self:close()
    end
end

function DCS_Shop_Window:updateTabColors()
    for name, tab in pairs(self.categoryTabs) do
        local displayName = getTabDisplay()[name] or name
        if name == self.activeCategory then
            tab.textColor = { r = COL_ACCENT.r, g = COL_ACCENT.g, b = COL_ACCENT.b, a = 1 }
        else
            tab.textColor = { r = 1.0, g = 1.0, b = 1.0, a = 1 }
        end
        tab:setTitle(displayName)
    end
end

function DCS_Shop_Window:onCategoryTab(btn)
    local title = btn and btn.title or "All"
    local category = "All"
    for key, display in pairs(getTabDisplay()) do
        if display == title then category = key; break end
    end
    self.activeCategory = category
    self:updateTabColors()
    self:refreshList()
end

function DCS_Shop_Window:refreshList()
    self.itemList:clear()

    local shopItems = DCS_Challenges.Shop or {}
    local stock = DCS_Sync.State.shopStock or {}
    local stockCount = 0
    for _ in pairs(stock) do stockCount = stockCount + 1 end
    DCS_dprint("[DCS_SHOP] refreshList: shopStock has " .. stockCount .. " entries")
    local currency = DCS_Sync.State.currency or 0
    local activeCat = self.activeCategory
    local shopConfig = DCS_Sync.State.shopConfig or {}

    local sideList = (DCS_Sync.State.shopTraderItems or {})[self.side] or {}
    local sideItems = {}
    for _, id in ipairs(sideList) do sideItems[id] = true end
    local allowAll = (#sideList == 0)
    DCS_dprint("[DCS_SHOP] Shop refreshList: side=" .. tostring(self.side) .. " sideList=" .. #sideList .. " allowAll=" .. tostring(allowAll))
    local function inSide(itemId)
        return allowAll or sideItems[itemId] == true
    end

    local defIds = {}
    for _, item in ipairs(shopItems) do
        defIds[item.itemId] = true
    end

    local shownCount = 0
    local stockZeroCount = 0
    for _, item in ipairs(shopItems) do
        if isShopItemEnabled(item.itemId) and inSide(item.itemId) then
            local resolved = resolveShopItemClient(item.itemId) or item
            if activeCat == "All" or resolved.category == activeCat then
                local itemStock = stock[item.itemId] or 0
                if itemStock == 0 then stockZeroCount = stockZeroCount + 1 end
                local canBuy = itemStock > 0 and currency >= resolved.cost
                local icon = getItemIcon(item.itemId)
                shownCount = shownCount + 1

                local entry = self.itemList:addItem(resolved.displayName, {
                    itemData = resolved,
                    stock = itemStock,
                    canBuy = canBuy,
                    icon = icon,
                })
                entry.height = ROW_H
            end
        end
    end
    DCS_dprint("[DCS_SHOP] refreshList: shown=" .. shownCount .. " stockZero=" .. stockZeroCount)

    for _, itemId in ipairs(shopConfig.enabledItems or {}) do
        if not defIds[itemId] and inSide(itemId) then
            local sm = getScriptManager and getScriptManager()
            if sm then
                local si = sm:FindItem(itemId)
                if si then
                    local displayName = si:getDisplayName() or itemId
                    local cost = (shopConfig.customCosts and shopConfig.customCosts[itemId]) or 5
                    local cat = categoriseItemForShop(si, itemId)
                    if activeCat == "All" or cat == activeCat then
                        local itemStock = stock[itemId] or 0
                        local canBuy = itemStock > 0 and currency >= cost
                        local icon = getItemIcon(itemId)
                        local entry = self.itemList:addItem(displayName, {
                            itemData = { itemId = itemId, displayName = displayName, cost = cost, category = cat },
                            stock = itemStock,
                            canBuy = canBuy,
                            icon = icon,
                        })
                        entry.height = ROW_H
                    end
                end
            end
        end
    end
end

function DCS_Shop_Window:drawItemRow(y, entry, alt)
    local data = entry.item
    local item = data.itemData
    local w = self:getWidth()
    local rowH = entry.height or ROW_H
    local stock = data.stock
    local canBuy = data.canBuy
    local icon = data.icon
    local currency = DCS_Sync.State.currency or 0

    if alt then
        self:drawRect(0, y, w, rowH - S(1),
            0.25, COL_TAB_INACT.r, COL_TAB_INACT.g, COL_TAB_INACT.b)
    end

    local iconSize = math.floor(fontHgt * 1.68)
    local iconX = PAD
    local iconY = y + math.floor((rowH - iconSize) / 2)
    if icon then
        self:drawTextureScaled(icon, iconX, iconY, iconSize, iconSize, 1)
    else
        self:drawRect(iconX, iconY, iconSize, iconSize, 0.5, 0.3, 0.3, 0.3)
        self:drawRectBorder(iconX, iconY, iconSize, iconSize, 0.5, 0.5, 0.5, 0.5)
    end

    local btnW = math.max(math.floor(fontHgt * 3.68), S(80))
    local btnH = fontHgt + S(7)
    local btnX = w - btnW - PAD
    local btnY = y + math.floor((rowH - btnH) / 2)

    local textX = iconX + iconSize + math.floor(PAD * 0.8)
    local nameCol = canBuy and { r=0.95, g=0.95, b=0.95 } or { r=0.60, g=0.60, b=0.60 }
    local maxNameW = btnX - textX - S(6) - getTextManager():MeasureStringX(FONT_MD, "MMM")
    self:drawText(truncateText(item.displayName, FONT_MD, maxNameW), textX, y + math.floor(PAD * 0.3),
        nameCol.r, nameCol.g, nameCol.b, 0.90, FONT_MD)

    local costStr = getText("IGUI_DCS_Shop_Cost", item.cost)
    self:drawText(costStr, textX, y + fontHgtMd + math.floor(PAD * 0.6) - S(5),
        0.90, 0.90, 0.90, 0.90, FONT_SM)

    local stockStr = getText("IGUI_DCS_Shop_Stock", stock)
    if stock > 0 then
        self:drawText(stockStr, textX, y + fontHgtMd + fontHgt + math.floor(PAD * 0.4) - S(5),
            0.90, 0.90, 0.90, 0.85, FONT_SM)
    else
        self:drawText(stockStr, textX, y + fontHgtMd + fontHgt + math.floor(PAD * 0.4) - S(5),
            COL_STOCK_LOW.r, COL_STOCK_LOW.g, COL_STOCK_LOW.b, 0.85, FONT_SM)
    end

    if canBuy then
        self:drawRect(btnX, btnY, btnW, btnH, 0.85,
            COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
        self:drawRectBorder(btnX, btnY, btnW, btnH, 0.60,
            COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
        local tmgr = getTextManager()
        local textH = tmgr:getFontHeight(FONT_MD)
        self:drawTextCentre(getText("IGUI_DCS_Shop_Buy"), btnX + btnW / 2, btnY + math.floor((btnH - textH) / 2),
            0.10, 0.10, 0.10, 1, FONT_MD)
    else
        self:drawRect(btnX, btnY, btnW, btnH, 0.50, 0.30, 0.30, 0.30)
        self:drawRectBorder(btnX, btnY, btnW, btnH, 0.40, 0.40, 0.40, 0.40)
        local tmgr = getTextManager()
        local textH = tmgr:getFontHeight(FONT_MD)
        self:drawTextCentre(getText("IGUI_DCS_Shop_Buy"), btnX + btnW / 2, btnY + math.floor((btnH - textH) / 2),
            0.50, 0.50, 0.50, 0.60, FONT_MD)
    end

    return y + rowH
end

function DCS_Shop_Window.onItemClicked(target, data)
    if not data or not data.itemData then return end
    if not data.canBuy then return end

    local mouseX = target:getMouseX()
    local w = target:getWidth()
    local btnW = math.max(math.floor(fontHgt * 3.68), S(80))
    local btnX = w - btnW - PAD

    if mouseX < btnX then return end

    DCS_Shop_AmountDialog.open(data.itemData, DCS_UI_Shop.instance)
end

function DCS_Shop_Window:prerender()
    ISCollapsableWindow.prerender(self)
end

local function getResetCountdown()
    local h = (DCS_Config and DCS_Config.RESET_INTERVAL_HOURS) or 24
    if type(h) ~= "number" or h <= 0 then h = 24 end
    local interval = math.floor(h * 3600)
    local now = os.time()
    local nextReset = (math.floor(now / interval) + 1) * interval
    local remaining = nextReset - now
    local hours = math.floor(remaining / 3600)
    local minutes = math.floor((remaining % 3600) / 60)
    if hours > 0 then
        return getText("IGUI_DCS_Panel_Countdown_HM", hours, minutes)
    else
        return getText("IGUI_DCS_Panel_Countdown_M", minutes)
    end
end

function DCS_Shop_Window:render()
    ISCollapsableWindow.render(self)

    local titleBarH = TITLE_BAR_H
    local catY = titleBarH + PAD

    local row1Keys = { "All", "Tools", "Weapons", "Equipment", "Clothing" }
    local row2Keys = { "Medical", "Food", "Literature", "Materials", "Other" }
    local totalTabW = self.width - PAD * 2
    local tabW = math.floor(totalTabW / 5)
    local tabH = S(20)

    local tabIdx = 1
    local tabRow = 1
    for i, key in ipairs(row1Keys) do
        if key == self.activeCategory then tabIdx = i; tabRow = 1; break end
    end
    for i, key in ipairs(row2Keys) do
        if key == self.activeCategory then tabIdx = i; tabRow = 2; break end
    end
    self:drawRect(PAD + (tabIdx - 1) * tabW, catY + (tabRow - 1) * (tabH + S(2)) + tabH - S(2), tabW, S(2),
        1, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)

    local currency = DCS_Sync.State.currency or 0
    local listEndY = self.itemList:getY() + self.itemList:getHeight()
    local footerY = listEndY + PAD

    self:drawRect(0, footerY, self.width, self.height - footerY, 0.92, COL_BG.r, COL_BG.g, COL_BG.b)
    self:drawRect(0, footerY, self.width, S(1), 0.50, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)

    local tmgr = getTextManager()
    local centerX = self.width / 2
    local footerH = self.height - footerY
    local textH = fontHgt * 2
    local textY = footerY + math.floor((footerH - textH) / 2)

    local tokenStr = getText("IGUI_DCS_Shop_AvailableTokens", currency)
    self:drawTextCentre(tokenStr, centerX, textY,
        COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b, 1, FONT_SM)

    local countdown = getResetCountdown()
    local resetStr = getText("IGUI_DCS_Shop_ResetCountdown", countdown:match("%d.*$") or countdown)
    self:drawTextCentre(resetStr, centerX, textY + fontHgt,
        0.70, 0.70, 0.70, 0.90, FONT_SM)
end

function DCS_Shop_Window:close()
    DCS_Sync.saveWindowPos("shop" .. self.side, self:getX(), self:getY())
    if DCS_Shop_AmountDialog.instance then
        DCS_Shop_AmountDialog.instance:close()
    end
    if DCS_Shop_ConfirmDialog.instance then
        DCS_Shop_ConfirmDialog.instance:close()
    end
    self:setVisible(false)
    self:removeFromUIManager()
    DCS_UI_Shop.instance = nil
end

DCS_Shop_AmountDialog = {}
DCS_Shop_AmountDialog.instance = nil

DCS_AmountDialog_Window = ISCollapsableWindow:derive("DCS_AmountDialog_Window")

function DCS_AmountDialog_Window:new(x, y, itemData, previousWindow)
    local o = ISCollapsableWindow.new(self, x, y, AMOUNT_W, AMOUNT_H)
    o.moveWithMouse = true
    o.resizable = false
    o.itemData = itemData
    o.quantity = 1
    o.previousWindow = previousWindow
    return o
end

function DCS_AmountDialog_Window:createChildren()
    ISCollapsableWindow.createChildren(self)

    local item = self.itemData
    local centerX = self.width / 2
    local stock = DCS_Sync.State.shopStock[item.itemId] or 0
    local icon = getItemIcon(item.itemId)
    self._icon = icon
    self._stock = stock

    local y = S(30)
    self._iconY = y
    y = y + S(38)
    self._titleY = y
    y = y + S(35)
    self._costY = y
    y = y + S(28)
    self._stockY = y
    y = y + S(24)

    local qtyGroupW = S(36) + S(4) + S(70) + S(4) + S(36) + S(4) + S(60)
    local qtyX = centerX - qtyGroupW / 2

    self.btnMinus = ISButton:new(qtyX, y, S(36), S(24), "-", self,
        DCS_AmountDialog_Window.onDecrease)
    self.btnMinus:initialise()
    self.btnMinus:instantiate()
    self:addChild(self.btnMinus)

    self.qtyEntry = ISTextEntryBox:new("1", qtyX + S(40), y, S(70), S(24))
    self.qtyEntry:initialise()
    self.qtyEntry:instantiate()
    self.qtyEntry:setOnlyNumbers(true)
    self.qtyEntry.javaObject = self.qtyEntry.javaObject
    self:addChild(self.qtyEntry)

    self.btnPlus = ISButton:new(qtyX + S(114), y, S(36), S(24), "+", self,
        DCS_AmountDialog_Window.onIncrease)
    self.btnPlus:initialise()
    self.btnPlus:instantiate()
    self:addChild(self.btnPlus)

    self.btnMax = ISButton:new(qtyX + S(154), y, S(60), S(24), getText("IGUI_DCS_Shop_Max"), self,
        DCS_AmountDialog_Window.onMax)
    self.btnMax:initialise()
    self.btnMax:instantiate()
    self:addChild(self.btnMax)
    y = y + S(32)

    self.lblTotal = ISLabel:new(centerX, y, S(20), "", 1, 0.85, 0.2, 1, FONT_SM, true)
    self.lblTotal:initialise()
    self.lblTotal.center = true
    self:addChild(self.lblTotal)
    self:updateTotal()
    y = y + S(24)

    local btnGroupW = S(120) + S(8) + S(120)
    local btnX = centerX - btnGroupW / 2
    self._btnY = y + S(4)

    self.btnBuy = ISButton:new(btnX, self._btnY, S(120), BTN_H, getText("IGUI_DCS_Shop_Buy"), self,
        DCS_AmountDialog_Window.onBuy)
    self.btnBuy:initialise()
    self.btnBuy:instantiate()
    self.btnBuy:enableAcceptColor()
    self:addChild(self.btnBuy)

    self.btnCancel = ISButton:new(btnX + S(128), self._btnY, S(120), BTN_H, getText("IGUI_DCS_Shop_Cancel"), self,
        DCS_AmountDialog_Window.onCancel)
    self.btnCancel:initialise()
    self.btnCancel:instantiate()
    self.btnCancel:enableCancelColor()
    self:addChild(self.btnCancel)
end

function DCS_AmountDialog_Window:initialise()
    ISCollapsableWindow.initialise(self)
end

function DCS_AmountDialog_Window:updateTotal()
    local item = self.itemData
    local qty = self.quantity or 1
    local total = item.cost * qty
    local currency = DCS_Sync.State.currency or 0

    if self.lblTotal then
        self.lblTotal:setName(getText("IGUI_DCS_Shop_TotalCost", total))
        self.lblTotal.r = COL_ACCENT.r
        self.lblTotal.g = COL_ACCENT.g
        self.lblTotal.b = COL_ACCENT.b
    end
end

function DCS_AmountDialog_Window:onDecrease()
    self.quantity = math.max(1, (self.quantity or 1) - 1)
    if self.qtyEntry then
        self.qtyEntry:setText(tostring(self.quantity))
    end
    self:updateTotal()
end

function DCS_AmountDialog_Window:onIncrease()
    local stock = DCS_Sync.State.shopStock[self.itemData.itemId] or 0
    local currency = DCS_Sync.State.currency or 0
    local maxByStock = stock
    local maxByGold = math.floor(currency / self.itemData.cost)
    local maxQty = math.min(maxByStock, maxByGold)
    self.quantity = math.min(maxQty, (self.quantity or 1) + 1)
    if self.qtyEntry then
        self.qtyEntry:setText(tostring(self.quantity))
    end
    self:updateTotal()
end

function DCS_AmountDialog_Window:onMax()
    local stock = DCS_Sync.State.shopStock[self.itemData.itemId] or 0
    local currency = DCS_Sync.State.currency or 0
    local maxByStock = stock
    local maxByGold = math.floor(currency / self.itemData.cost)
    self.quantity = math.max(1, math.min(maxByStock, maxByGold))
    if self.qtyEntry then
        self.qtyEntry:setText(tostring(self.quantity))
    end
    self:updateTotal()
end

function DCS_AmountDialog_Window:onCancel()
    local prev = self.previousWindow
    self:close()
    if prev and prev.setVisible then
        prev:setVisible(true)
    end
end

function DCS_AmountDialog_Window:onBuy()
    local text = self.qtyEntry and self.qtyEntry:getText() or "1"
    local qty = tonumber(text) or 1
    qty = math.max(1, qty)
    self.quantity = qty

    self:setVisible(false)
    DCS_Shop_ConfirmDialog.open(self.itemData, self.quantity, self)
end

function DCS_AmountDialog_Window:prerender()
    ISCollapsableWindow.prerender(self)
    self:drawRect(0, S(20), self.width, S(2), 1, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
    local item = self.itemData
    local centerX = self.width / 2
    if self._icon then
        self:drawTextureScaled(self._icon, centerX - S(16), self._iconY, S(32), S(32), 1)
    end
    self:drawTextCentre(truncateText(item.displayName, FONT_MD, self.width - S(20)), centerX, self._titleY,
        0.95, 0.95, 0.95, 1, FONT_MD)
    self:drawTextCentre(getText("IGUI_DCS_Shop_CostEach", item.cost), centerX, self._costY,
        0.85, 0.85, 0.85, 0.90, FONT_SM)
    self:drawTextCentre(getText("IGUI_DCS_Shop_Stock", self._stock), centerX, self._stockY,
        0.85, 0.85, 0.85, 0.90, FONT_SM)
end

function DCS_AmountDialog_Window:close()
    self:setVisible(false)
    self:removeFromUIManager()
    DCS_Shop_AmountDialog.instance = nil
end

function DCS_Shop_AmountDialog.open(itemData, previousWindow)
    if DCS_Shop_AmountDialog.instance then
        DCS_Shop_AmountDialog.instance:close()
    end

    if previousWindow and previousWindow.setVisible then
        previousWindow:setVisible(false)
    end

    local screenW = getPlayerScreenWidth(0)
    local screenH = getPlayerScreenHeight(0)
    local x = math.floor((screenW - AMOUNT_W) / 2)
    local y = math.floor((screenH - AMOUNT_H) / 2)

    local win = DCS_AmountDialog_Window:new(x, y, itemData, previousWindow)
    win:initialise()
    win:instantiate()
    win:addToUIManager()
    win:setTitle(getText("IGUI_DCS_Shop_SelectQuantity"))
    DCS_Shop_AmountDialog.instance = win
end

DCS_Shop_ConfirmDialog = {}
DCS_Shop_ConfirmDialog.instance = nil

DCS_ConfirmDialog_Window = ISCollapsableWindow:derive("DCS_ConfirmDialog_Window")

function DCS_ConfirmDialog_Window:new(x, y, itemData, quantity, previousWindow)
    local o = ISCollapsableWindow.new(self, x, y, CONFIRM_W, CONFIRM_H)
    o.moveWithMouse = true
    o.resizable = false
    o.itemData = itemData
    o.quantity = quantity or 1
    o.previousWindow = previousWindow
    return o
end

function DCS_ConfirmDialog_Window:createChildren()
    ISCollapsableWindow.createChildren(self)

    local item = self.itemData
    local qty = self.quantity
    local total = item.cost * qty
    local currency = DCS_Sync.State.currency or 0
    local remaining = currency - total
    local centerX = self.width / 2
    local icon = getItemIcon(item.itemId)

    self._icon = icon
    self._confirmStr = tostring(qty) .. "x " .. item.displayName .. " - " .. tostring(total) .. " " .. getText("IGUI_DCS_Shop_Tokens")
    self._currency = currency

    local btnGroupW = S(120) + S(16) + S(120)
    local btnX = centerX - btnGroupW / 2
    local btnY = CONFIRM_H - S(38)

    local canAfford = remaining >= 0
    self.btnConfirm = ISButton:new(btnX, btnY, S(120), BTN_H, getText("IGUI_DCS_Shop_Buy"), self,
        DCS_ConfirmDialog_Window.onConfirm)
    self.btnConfirm:initialise()
    self.btnConfirm:instantiate()
    self.btnConfirm.enable = canAfford
    self.btnConfirm:enableAcceptColor()
    self:addChild(self.btnConfirm)

    self.btnCancel = ISButton:new(btnX + S(136), btnY, S(120), BTN_H, getText("IGUI_DCS_Shop_Cancel"), self,
        DCS_ConfirmDialog_Window.onCancel)
    self.btnCancel:initialise()
    self.btnCancel:instantiate()
    self.btnCancel:enableCancelColor()
    self:addChild(self.btnCancel)
end

function DCS_ConfirmDialog_Window:initialise()
    ISCollapsableWindow.initialise(self)
end

function DCS_ConfirmDialog_Window:onCancel()
    local prev = self.previousWindow
    self:close()
    if prev and prev.setVisible then
        prev:setVisible(true)
    end
end

function DCS_ConfirmDialog_Window:onConfirm()
    local item = self.itemData
    local qty = self.quantity
    DCS_Sync.requestPurchase(item.itemId, item.cost, qty)
    DCS_Sync.showToast(getText("IGUI_DCS_Shop_Purchased", qty, item.displayName), "complete")
    local prev = self.previousWindow
    self:close()
    if DCS_Shop_AmountDialog.instance then
        DCS_Shop_AmountDialog.instance:close()
    end
    if DCS_UI_Shop.instance then
        DCS_UI_Shop.instance:setVisible(true)
    end
end

function DCS_ConfirmDialog_Window:prerender()
    ISCollapsableWindow.prerender(self)
    self:drawRect(0, S(20), self.width, S(2), 1, COL_ACCENT.r, COL_ACCENT.g, COL_ACCENT.b)
    local item = self.itemData
    local centerX = self.width / 2
    local y = S(30)
    if self._icon then
        self:drawTextureScaled(self._icon, centerX - S(16), y, S(32), S(32), 1)
    end
    y = y + S(38)
    self:drawTextCentre(truncateText(item.displayName, FONT_MD, self.width - S(20)), centerX, y, 0.95, 0.95, 0.95, 1, FONT_MD)
    y = y + S(32)
    self:drawTextCentre(truncateText(self._confirmStr or "", FONT_SM, self.width - S(20)), centerX, y, 0.85, 0.85, 0.85, 0.90, FONT_SM)
    y = y + S(27)
    self:drawTextCentre(getText("IGUI_DCS_Shop_CurrentTokens", self._currency or 0), centerX, y,
        0.85, 0.85, 0.85, 0.90, FONT_SM)
end

function DCS_ConfirmDialog_Window:close()
    self:setVisible(false)
    self:removeFromUIManager()
    DCS_Shop_ConfirmDialog.instance = nil
end

function DCS_Shop_ConfirmDialog.open(itemData, quantity, previousWindow)
    if DCS_Shop_ConfirmDialog.instance then
        DCS_Shop_ConfirmDialog.instance:close()
    end

    local screenW = getPlayerScreenWidth(0)
    local screenH = getPlayerScreenHeight(0)
    local x = math.floor((screenW - CONFIRM_W) / 2)
    local y = math.floor((screenH - CONFIRM_H) / 2)

    local win = DCS_ConfirmDialog_Window:new(x, y, itemData, quantity, previousWindow)
    win:initialise()
    win:instantiate()
    win:addToUIManager()
    win:setTitle(getText("IGUI_DCS_Shop_ConfirmPurchase"))
    DCS_Shop_ConfirmDialog.instance = win
end

local SIDE_LABEL = { east = getText("IGUI_DCS_Shop_East"), west = getText("IGUI_DCS_Shop_West") }

function DCS_UI_Shop.open(side, npc)
    side = (side == "west") and "west" or "east"

    if DCS_UI_Shop.instance then
        DCS_UI_Shop.instance:close()
    end

    local player = getSpecificPlayer(0)
    if not player then return end

    sendClientCommand(player, "DailyChallengeSystem", "requestSync", {})

    local screenW = getPlayerScreenWidth(0)
    local screenH = getPlayerScreenHeight(0)

    local x, y = DCS_Sync.getWindowPos("shop" .. side,
        math.floor((screenW - SHOP_W) / 2), math.floor((screenH - SHOP_H) / 2))
    x = math.max(0, math.min(x, screenW - SHOP_W))
    y = math.max(0, math.min(y, screenH - SHOP_H))

    local win = DCS_Shop_Window:new(x, y, side, npc)
    win:initialise()
    win:instantiate()
    win:addToUIManager()
    win:setTitle(getText("IGUI_DCS_Shop_Title"))
    win:refreshList()

    DCS_UI_Shop.instance = win
end

function DCS_UI_Shop.close()
    if DCS_UI_Shop.instance then
        DCS_UI_Shop.instance:close()
    end
end

function DCS_UI_Shop.toggle()
    if DCS_UI_Shop.instance and DCS_UI_Shop.instance:getIsVisible() then
        DCS_UI_Shop.close()
    else
        DCS_UI_Shop.open()
    end
end
