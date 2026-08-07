-- TMBanListWindow.lua (client)
-- BAN MUSIC LIST admin/debug UI.
-- Two categorized lists (per music addon): PLAYABLE and BANNED. Drag a song
-- (or double-click it) to move it between the lists, then press SET to apply.
-- Banned songs cannot be inserted/played on any TrueMoozic device by regular
-- players; the "Admins/debug bypass" tickbox controls whether staff keep
-- access to banned songs.
require "ISUI/ISCollapsableWindow"
require "ISUI/ISScrollingListBox"
require "TMBanListDefs"

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
local PAD = 10

------------------------------------------------------------------------
-- Drag-aware list
------------------------------------------------------------------------

TMBanDragList = ISScrollingListBox:derive("TMBanDragList")

function TMBanDragList:onMouseDown(x, y)
    ISScrollingListBox.onMouseDown(self, x, y)
    local win = self.banWindow
    if not win then return end
    local row = self:rowAt(x, y)
    if row and row >= 1 and row <= #self.items then
        local data = self.items[row].item
        if data and data.header then
            -- Click a category header to collapse/expand its song list.
            win.collapsed[data.collapseKey] = not win.collapsed[data.collapseKey] or nil
            win.dragCandidate = nil
            win:rebuild()
            return
        end
        if data and data.entry then
            win.dragCandidate = {
                list = self,
                entry = data.entry,
                startX = getMouseX(),
                startY = getMouseY(),
            }
        end
    end
end

local function maybeStartDrag(self)
    local win = self.banWindow
    if not win or win.dragging or not win.dragCandidate then return end
    local dx = getMouseX() - win.dragCandidate.startX
    local dy = getMouseY() - win.dragCandidate.startY
    if (dx * dx + dy * dy) >= 36 then
        win.dragging = win.dragCandidate
    end
end

function TMBanDragList:onMouseMove(dx, dy)
    ISScrollingListBox.onMouseMove(self, dx, dy)
    maybeStartDrag(self)
end

function TMBanDragList:onMouseMoveOutside(dx, dy)
    ISScrollingListBox.onMouseMoveOutside(self, dx, dy)
    maybeStartDrag(self)
end

function TMBanDragList:onMouseUp(x, y)
    ISScrollingListBox.onMouseUp(self, x, y)
    if self.banWindow then self.banWindow:endDrag() end
end

function TMBanDragList:onMouseUpOutside(x, y)
    ISScrollingListBox.onMouseUpOutside(self, x, y)
    if self.banWindow then self.banWindow:endDrag() end
end

function TMBanDragList:onMouseDoubleClick(x, y)
    -- Accessibility fallback: double-click moves the song to the other list.
    local win = self.banWindow
    if not win then return end
    local row = self:rowAt(x, y)
    if row and row >= 1 and row <= #self.items then
        local data = self.items[row].item
        if data and data.entry then
            win.dragCandidate = nil
            win.dragging = nil
            win:moveEntry(data.entry, self ~= win.bannedList)
        end
    end
end

function TMBanDragList:doDrawItem(y, item, alt)
    local data = item.item
    if data and data.header then
        -- Addon category header row (click to collapse/expand).
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.85, 0.16, 0.16, 0.22)
        local arrow = data.collapsed and "[+]" or "[-]"
        local label = arrow .. " " .. data.text .. " (" .. tostring(data.count or 0) .. ")"
        self:drawText(label, 8, y + (self.itemheight - FONT_HGT_SMALL) / 2, 0.95, 0.82, 0.45, 1, UIFont.Small)
        return y + self.itemheight
    end

    if self.selected == item.index then
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.3, 0.7, 0.35, 0.15)
    elseif alt then
        self:drawRect(0, y, self:getWidth(), self.itemheight - 1, 0.15, 0.25, 0.25, 0.28)
    end
    self:drawRectBorder(0, y, self:getWidth(), self.itemheight, 0.15, 1, 1, 1)

    local entry = data and data.entry or nil
    if entry then
        local r, g, b = 0.9, 0.9, 0.9
        if self.banWindow and self == self.banWindow.bannedList then
            r, g, b = 1, 0.55, 0.55
        end
        self:drawText(entry.display, 22, y + (self.itemheight - FONT_HGT_SMALL) / 2, r, g, b, 1, UIFont.Small)
        local tag = "[" .. tostring(entry.kind) .. "]"
        local tagW = getTextManager():MeasureStringX(UIFont.Small, tag)
        self:drawText(tag, self:getWidth() - tagW - 14, y + (self.itemheight - FONT_HGT_SMALL) / 2, 0.55, 0.6, 0.7, 1, UIFont.Small)
    end
    return y + self.itemheight
end

------------------------------------------------------------------------
-- Window
------------------------------------------------------------------------

TMBanListWindow = ISCollapsableWindow:derive("TMBanListWindow")
TMBanListWindow.instance = nil

function TMBanListWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    local th = self:titleBarHeight()
    local y = th + PAD

    local listW = math.floor((self.width - PAD * 3) / 2)
    local bottomBlock = FONT_HGT_SMALL * 3 + 22 + PAD * 3   -- warn text + tickbox + button
    local listH = self.height - y - FONT_HGT_SMALL - 4 - bottomBlock

    self.playableLabel = ISLabel:new(PAD, y, FONT_HGT_SMALL, getText("IGUI_TMBan_Playable"), 0.6, 1, 0.6, 1, UIFont.Small, true)
    self:addChild(self.playableLabel)
    self.bannedLabel = ISLabel:new(PAD * 2 + listW, y, FONT_HGT_SMALL, getText("IGUI_TMBan_Banned"), 1, 0.5, 0.5, 1, UIFont.Small, true)
    self:addChild(self.bannedLabel)
    y = y + FONT_HGT_SMALL + 4

    self.playableList = TMBanDragList:new(PAD, y, listW, listH)
    self.playableList:initialise()
    self.playableList:instantiate()
    self.playableList.itemheight = FONT_HGT_SMALL + 8
    self.playableList.drawBorder = true
    self.playableList.banWindow = self
    self:addChild(self.playableList)

    self.bannedList = TMBanDragList:new(PAD * 2 + listW, y, listW, listH)
    self.bannedList:initialise()
    self.bannedList:instantiate()
    self.bannedList.itemheight = FONT_HGT_SMALL + 8
    self.bannedList.drawBorder = true
    self.bannedList.banWindow = self
    self:addChild(self.bannedList)

    y = y + listH + PAD

    self.bypassBox = ISTickBox:new(PAD, y, 18, 18, "", self, TMBanListWindow.onBypassToggle)
    self.bypassBox:initialise()
    self.bypassBox:addOption(getText("IGUI_TMBan_Bypass"))
    self.bypassBox.tooltip = getText("IGUI_TMBan_Bypass_Tooltip")
    self.bypassBox.selected[1] = self.bypass and true or false
    self:addChild(self.bypassBox)

    local btnW = 110
    self.setButton = ISButton:new(self.width - PAD - btnW, y - 2, btnW, 22, getText("IGUI_TMBan_Set"), self, TMBanListWindow.onSetPressed)
    self.setButton:initialise()
    self.setButton.backgroundColor = { r = 0.6, g = 0.15, b = 0.15, a = 0.8 }
    self:addChild(self.setButton)

    self:rebuild()
end

function TMBanListWindow:onBypassToggle(index, selected)
    self.bypass = selected and true or false
end

------------------------------------------------------------------------
-- List building (always regrouped per addon module)
------------------------------------------------------------------------

function TMBanListWindow:rebuild()
    self.catalog = self.catalog or TMBanList.buildCatalog()
    local cat = self.catalog

    self.playableList:clear()
    self.bannedList:clear()

    local playCount, banCount = 0, 0
    for _, module in ipairs(cat.order) do
        local playRows, banRows = {}, {}
        for _, entry in ipairs(cat.byModule[module]) do
            if self.pendingBanned[entry.fullType] then
                banRows[#banRows + 1] = entry
            else
                playRows[#playRows + 1] = entry
            end
        end
        if #playRows > 0 then
            local key = "P:" .. module
            local isCollapsed = self.collapsed[key] and true or false
            self.playableList:addItem(module, { header = true, text = module, collapseKey = key, collapsed = isCollapsed, count = #playRows })
            if not isCollapsed then
                for _, entry in ipairs(playRows) do
                    self.playableList:addItem(entry.display, { entry = entry })
                end
            end
            playCount = playCount + #playRows
        end
        if #banRows > 0 then
            local key = "B:" .. module
            local isCollapsed = self.collapsed[key] and true or false
            self.bannedList:addItem(module, { header = true, text = module, collapseKey = key, collapsed = isCollapsed, count = #banRows })
            if not isCollapsed then
                for _, entry in ipairs(banRows) do
                    self.bannedList:addItem(entry.display, { entry = entry })
                end
            end
            banCount = banCount + #banRows
        end
    end

    self.playableLabel:setName(getText("IGUI_TMBan_Playable") .. " (" .. playCount .. ")")
    self.bannedLabel:setName(getText("IGUI_TMBan_Banned") .. " (" .. banCount .. ")")
end

-- toBanned=true moves the entry into the BANNED list, false back to playable.
function TMBanListWindow:moveEntry(entry, toBanned)
    if toBanned then
        self.pendingBanned[entry.fullType] = true
    else
        self.pendingBanned[entry.fullType] = nil
    end
    -- Auto-expand the destination category so the user sees where it landed.
    local module = string.match(entry.fullType, "^([^%.]+)%.") or "?"
    self.collapsed[(toBanned and "B:" or "P:") .. module] = nil
    self:rebuild()
end

------------------------------------------------------------------------
-- Drag handling
------------------------------------------------------------------------

local function mouseOver(el)
    if not el then return false end
    local mx, my = getMouseX(), getMouseY()
    local ax, ay = el:getAbsoluteX(), el:getAbsoluteY()
    return mx >= ax and mx <= ax + el:getWidth() and my >= ay and my <= ay + el:getHeight()
end

function TMBanListWindow:endDrag()
    local drag = self.dragging
    self.dragCandidate = nil
    self.dragging = nil
    if not drag then return end
    if mouseOver(self.bannedList) then
        self:moveEntry(drag.entry, true)
    elseif mouseOver(self.playableList) then
        self:moveEntry(drag.entry, false)
    end
end

function TMBanListWindow:onMouseUp(x, y)
    ISCollapsableWindow.onMouseUp(self, x, y)
    self:endDrag()
end

function TMBanListWindow:onMouseUpOutside(x, y)
    ISCollapsableWindow.onMouseUpOutside(self, x, y)
    self:endDrag()
end

function TMBanListWindow:render()
    ISCollapsableWindow.render(self)

    -- Warning line above the SET button.
    local warnY = self.setButton and (self.setButton:getY() + 26) or (self.height - FONT_HGT_SMALL * 2)
    self:drawText(getText("IGUI_TMBan_Warning1"), PAD, warnY, 1, 0.75, 0.35, 1, UIFont.Small)
    self:drawText(getText("IGUI_TMBan_Warning2"), PAD, warnY + FONT_HGT_SMALL + 2, 1, 0.75, 0.35, 1, UIFont.Small)

    -- Drag ghost following the mouse.
    if self.dragging then
        local mx = getMouseX() - self:getAbsoluteX()
        local my = getMouseY() - self:getAbsoluteY()
        local label = self.dragging.entry.display
        local w = getTextManager():MeasureStringX(UIFont.Small, label) + 12
        self:drawRect(mx + 10, my - 4, w, FONT_HGT_SMALL + 8, 0.85, 0.1, 0.1, 0.14)
        self:drawRectBorder(mx + 10, my - 4, w, FONT_HGT_SMALL + 8, 0.8, 0.9, 0.7, 0.3)
        self:drawText(label, mx + 16, my, 1, 1, 1, 1, UIFont.Small)
        -- Drop-target highlight.
        local target = nil
        if mouseOver(self.bannedList) then target = self.bannedList
        elseif mouseOver(self.playableList) then target = self.playableList end
        if target then
            self:drawRectBorder(target:getX(), target:getY(), target:getWidth(), target:getHeight(), 0.9, 0.9, 0.8, 0.3)
        end
    end
end

------------------------------------------------------------------------
-- SET (apply) with confirmation warning
------------------------------------------------------------------------

function TMBanListWindow:onSetPressed()
    local modal = ISModalDialog:new(getCore():getScreenWidth() / 2 - 200, getCore():getScreenHeight() / 2 - 75,
        400, 150, getText("IGUI_TMBan_ConfirmText"), true, self, TMBanListWindow.onConfirmSet)
    modal:initialise()
    modal:addToUIManager()
    modal.moveWithMouse = true
end

function TMBanListWindow:onConfirmSet(button)
    if not button or button.internal ~= "YES" then return end

    -- Fresh copy for transmission/application.
    local banned = {}
    for fullType in pairs(self.pendingBanned) do
        banned[fullType] = true
    end

    if isClient() then
        sendClientCommand(self.player, "TMBanList", "set", { banned = banned, bypass = self.bypass })
        -- Optimistic local apply; the server broadcast confirms/corrects.
        local d = TMBanList.getData()
        d.banned = banned
        d.bypass = self.bypass
    else
        -- SP / hosted: apply directly (global ModData persists in the save).
        local d = TMBanList.getData()
        d.banned = banned
        d.bypass = self.bypass
        d.rev = (d.rev or 0) + 1
    end

    local count = 0
    for _ in pairs(banned) do count = count + 1 end
    if self.player and self.player.setHaloNote then
        self.player:setHaloNote(getText("IGUI_TMBan_Applied", count), 120, 255, 120, 300)
    end
end

------------------------------------------------------------------------
-- Lifecycle
------------------------------------------------------------------------

function TMBanListWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    if TMBanListWindow.instance == self then
        TMBanListWindow.instance = nil
    end
end

function TMBanListWindow:new(x, y, width, height, player)
    local o = ISCollapsableWindow.new(self, x, y, width, height)
    o.title = getText("IGUI_TMBan_Title")
    o.player = player
    o.resizable = false
    o.pendingBanned = {}
    o.collapsed = {}   -- ["P:<module>"/"B:<module>"] = true when the category is folded
    local d = TMBanList.getData()
    for fullType in pairs(d.banned or {}) do
        o.pendingBanned[fullType] = true
    end
    o.bypass = d.bypass ~= false
    return o
end

function TMBanListWindow.toggle(player)
    if TMBanListWindow.instance then
        TMBanListWindow.instance:close()
        return
    end
    if isClient() then
        ModData.request(TMBanList.MODDATA_KEY)
    end
    local w, h = 620, 520
    local win = TMBanListWindow:new((getCore():getScreenWidth() - w) / 2, (getCore():getScreenHeight() - h) / 2, w, h, player)
    win:initialise()
    win:addToUIManager()
    win:setVisible(true)
    TMBanListWindow.instance = win
end
