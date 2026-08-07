require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISMouseDrag"
require "ISUI/ISToolTipInv"
require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISInventoryTransferAction"
require "TimedActions/ISTimedActionQueue"

SWTCBagPanel = ISPanel:derive("SWTCBagPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local ROW_HEIGHT = FONT_HGT_SMALL + 8
local UI_BORDER_SPACING = 10
local treeexpicon = getTexture("media/ui/inventoryPanes/Button_TreeExpanded.png")
local treecolicon = getTexture("media/ui/inventoryPanes/Button_TreeCollapsed.png")

function SWTCBagPanel:initialise()
    ISPanel.initialise(self)
end

function SWTCBagPanel:createChildren()
    self.currentEquippedBag = self:detectEquippedBag()
    self.selectedIndex = nil
    self.selected = {}
    self.mouseOverOption = 0
    self.dragging = nil
    self.draggingX = 0
    self.draggingY = 0
    self.dragStarted = false
    self.downX = 0
    self.downY = 0
    self.firstSelect = nil
    self.previousMouseUp = nil
    self.toolRender = nil
    self.player = nil
    self.scrollY = 0
    self.maxScrollY = 0
    self.scrollBarDragging = false
    self.scrollBarDragOffset = 0
    self.scrollBarWidth = 12
end

function SWTCBagPanel:detectEquippedBag()
    if not self.player then return nil end
    local inv = self.player:getInventory()
    local items = inv:getItems()
    for i = 0, items:size()-1 do
        local item = items:get(i)
        if item and item:getFullType() == "Base.Bag_CDbag" and self.player:isEquipped(item) then
            local bodyLocation = item:getBodyLocation()
            if bodyLocation == "FannyPackFront" then
                return item
            end
        end
    end
    return nil
end

function SWTCBagPanel:getBagItems()
    if not self.currentEquippedBag or not self.currentEquippedBag:getInventory() then return {} end
    local bagContainer = self.currentEquippedBag:getInventory()
    local items = {}
    local bagItems = bagContainer:getItems()
    for i = 0, bagItems:size()-1 do
        local item = bagItems:get(i)
        if item:getFullType() == "Base.Disc_Retail"
            or (item:getModData() and item:getModData().CustomMusicCD)
            or (item.hasTag and item:hasTag("Music")) then
            table.insert(items, item)
        end
    end
    return items
end

local function getFontEnum()
    local font = getCore():getOptionInventoryFont()
    if font == "Large" then
        return UIFont.Large
    elseif font == "Small" then
        return UIFont.Small
    end
    return UIFont.Medium
end

function SWTCBagPanel:getStackedItems()
    local items = self:getBagItems()
    local groups = {}
    local groupMap = {}
    for _, item in ipairs(items) do
        local name = item:getName()
        if not groupMap[name] then
            local group = { name = name, items = {}, collapsed = true }
            table.insert(groups, group)
            groupMap[name] = group
        end
        table.insert(groupMap[name].items, item)
    end
    if not self._collapseState then self._collapseState = {} end
    for _, group in ipairs(groups) do
        if self._collapseState[group.name] ~= nil then
            group.collapsed = self._collapseState[group.name]
        end
    end
    return groups
end

function SWTCBagPanel:refreshVisibleRows()
    self.visibleRows = {}
    local groups = self:getStackedItems()
    for _, group in ipairs(groups) do
        table.insert(self.visibleRows, { type = "group", group = group })
        if not group.collapsed then
            for i, item in ipairs(group.items) do
                table.insert(self.visibleRows, { type = "item", group = group, item = item, idx = i })
            end
        end
    end
end

function SWTCBagPanel:getVisibleRows()
    if not self.visibleRows then self:refreshVisibleRows() end
    return self.visibleRows
end

function SWTCBagPanel:getContentHeight()
    local rows = self:getVisibleRows()
    return #rows * ROW_HEIGHT + UI_BORDER_SPACING * 2
end

function SWTCBagPanel:updateScrollValues()
    local contentH = self:getContentHeight()
    self.maxScrollY = math.max(0, contentH - self.height)
    if self.scrollY > self.maxScrollY then
        self.scrollY = self.maxScrollY
    end
    if self.scrollY < 0 then
        self.scrollY = 0
    end
end

function SWTCBagPanel:forceRefresh()
    self:refreshVisibleRows()
    if self.invalidate then self:invalidate() end
end

function SWTCBagPanel:prerender()
    ISPanel.prerender(self)
    self:updateScrollValues()
    self:forceRefresh()
    local contentW = self.width - self.scrollBarWidth
    self:setStencilRect(0, 0, contentW, self.height)
    local rows = self:getVisibleRows()
    local fontEnum = getFontEnum()
    local fontHgt = getTextManager():getFontFromEnum(fontEnum):getLineHeight()
    local itemHgt = math.ceil(math.max(18, fontHgt))
    local iconSize = math.min(itemHgt-2, 32)
    local y = UI_BORDER_SPACING - self.scrollY
    for i, row in ipairs(rows) do
        local isGroup = row.type == "group"
        local isItem = row.type == "item"
        local indent = isItem and 24 or 0
        local itemHgt = ROW_HEIGHT
        if isGroup then
            self:drawRect(2, y, self.width-4, itemHgt, 0.2, 0, 0, 0)
        elseif isItem then
            local zebra = (i % 2 == 0)
            if zebra then
                self:drawRect(2+indent, y, self.width-4-indent, itemHgt, 0.02, 1, 1, 1)
            else
                self:drawRect(2+indent, y, self.width-4-indent, itemHgt, 0.2, 0, 0, 0)
            end
        end
        if isGroup then
            self:drawRect(2, y+itemHgt-1, self.width-4, 1, 0.2, 1, 1, 1)
        end
        local isSelected = self.selected[i]
        local isMouseOver = (self.mouseOverOption == i)
        local isDraggingThisRow = false
        if ISMouseDrag.dragging and ISMouseDrag.draggingFocus == self then
            local dragItem = isGroup and self:getRowItem(row) or row.item
            for _, v in ipairs(ISMouseDrag.dragging) do
                if v == dragItem then isDraggingThisRow = true break end
            end
        end
        if isDraggingThisRow then
            self:drawRect(2+indent, y, self.width-4-indent, itemHgt, 0.35, 1, 1, 1)
        end
        if isSelected then
            self:drawRect(2+indent, y-2, self.width-4-indent, itemHgt, 0.20, 1.0, 1.0, 1.0)
        elseif isMouseOver then
            self:drawRect(2+indent, y-2, self.width-4-indent, itemHgt, 0.05, 1.0, 1.0, 1.0)
        end
        if isGroup and #row.group.items > 1 then
            local iconSize = 15
            local iconX = 8
            local iconY = y + (itemHgt - iconSize) / 2
            local icon = row.group.collapsed and treecolicon or treeexpicon
            if icon then
                self:drawTextureScaled(icon, iconX, iconY, iconSize, iconSize, 1, 1, 1, 0.8)
            end
        end
        local iconSize = 15
        local iconX = 8 + indent
        local iconY = y + (itemHgt - iconSize) / 2
        local tex, texSize, texX, texY
        if isGroup then
            local firstItem = row.group.items[1]
            tex = firstItem and firstItem:getTex()
            texSize = math.min(itemHgt-2, 22)
            texX = iconX + iconSize + 6
            texY = y + (itemHgt - texSize) / 2
        elseif isItem then
            tex = row.item and row.item:getTex()
            texSize = math.min(itemHgt-2, 22)
            texX = iconX + iconSize + 6
            texY = y + (itemHgt - texSize) / 2
        end
        if tex then
            self:drawTextureScaled(tex, texX, texY, texSize, texSize, 1, 1, 1, 1)
        end
        local textColor = {r=0.7, g=0.7, b=0.7, a=1.0}
        if isSelected then textColor = {r=1.0, g=1.0, b=1.0, a=1.0} end
        local textY = y + (itemHgt - fontHgt) / 2
        local maxTextW = contentW - (texX+texSize+8) - 8
        if isGroup then
            local text = row.group.name
            if #row.group.items > 1 then
                text = text .. " (" .. #row.group.items .. ")"
            end
            self:drawText(text, texX+texSize+8, textY, textColor.r, textColor.g, textColor.b, textColor.a, fontEnum, maxTextW)
        elseif isItem then
            self:drawText(row.item:getName(), texX+texSize+8, textY, textColor.r, textColor.g, textColor.b, textColor.a, fontEnum, maxTextW)
        end
        if ISMouseDrag.dragging and ISMouseDrag.draggingFocus ~= self then
            local mouseX = getMouseX() - self:getAbsoluteX()
            local mouseY = getMouseY() - self:getAbsoluteY()
            local hoverRowIdx = self:rowAt(mouseX, mouseY)
            if hoverRowIdx == i then
                self:drawRect(0, y, self.width, itemHgt, 0.3, 1, 1, 1)
            end
        end
        y = y + itemHgt
    end
    self:clearStencilRect()
    if self.maxScrollY > 0 then
        local scrollBarTexBg = getTexture("media/ui/Scrollbar_Vertical_Background.png")
        local scrollBarTexThumb = getTexture("media/ui/Scrollbar_Vertical_Thumb.png")
        local barX = self.width - self.scrollBarWidth
        local barY = 0
        local barW = self.scrollBarWidth
        local barH = self.height
        local contentH = self:getContentHeight()
        local thumbH = math.max(30, barH * barH / contentH)
        local thumbY = (self.scrollY / self.maxScrollY) * (barH - thumbH)
        if scrollBarTexBg then
            self:drawTextureScaled(scrollBarTexBg, barX, barY, barW, barH, 1, 1, 1, 1)
        else
            self:drawRect(barX, barY, barW, barH, 0.2, 0.5, 0.5, 0.5)
        end
        if scrollBarTexThumb then
            self:drawTextureScaled(scrollBarTexThumb, barX, barY + thumbY, barW, thumbH, 1, 1, 1, 1)
        else
            self:drawRect(barX, barY + thumbY, barW, thumbH, 0.7, 0.8, 0.8, 0.8)
        end
    end
end

function SWTCBagPanel:rowAt(x, y)
    local contentW = self.width - self.scrollBarWidth
    if x < 0 or x >= contentW then return -1 end
    if y < 0 or y >= self.height then return -1 end
    local rows = self:getVisibleRows()
    local row = math.floor((y + self.scrollY - UI_BORDER_SPACING) / ROW_HEIGHT) + 1
    if row < 1 or row > #rows then return -1 end
    return row
end

function SWTCBagPanel:selectIndex(index)
    local rows = self:getVisibleRows()
    local row = rows[index]
    if not row then return end
    self.selected = {}
    self.selected[index] = true
end

function SWTCBagPanel:getRowItem(row)
    if row.type == "group" then
        return row.group.items[1]
    elseif row.type == "item" then
        return row.item
    end
    return nil
end

function SWTCBagPanel:onRightMouseUp(x, y)
    local playerNum = self.player and (instanceof(self.player, "IsoPlayer") and self.player:getPlayerNum() or self.player) or 0
    if playerNum ~= 0 then return end
    
    local playerObj = getSpecificPlayer(playerNum)
    local isInInv = true
    local rows = self:getVisibleRows()
    
    if #rows == 0 then
        return
    end
    
    if self.selected == nil then
        self.selected = {}
    end
    
    local rowIdx = self:rowAt(x, y)
    if rowIdx > 0 and not self.selected[rowIdx] then
        self.selected = {}
        self:selectIndex(rowIdx)
    end
    
    local contextMenuItems = {}
    for k, v in pairs(self.selected) do
        if v then
            local row = rows[k]
            local item = row and self:getRowItem(row)
            if item then
                table.insert(contextMenuItems, item)
            end
        end
    end
    
    if self.toolRender then
        self.toolRender:setVisible(false)
    end
    
    if #contextMenuItems > 0 then
        local menu = ISInventoryPaneContextMenu.createMenu(playerNum, isInInv, contextMenuItems, self:getAbsoluteX()+x, self:getAbsoluteY()+y)
        local function isCustomCD(item)
            local itemType = item:getType()
            return SWTCCDAlbums and SWTCCDAlbums[itemType] ~= nil
        end
        local function isOriginalCD(item)
            return item:getFullType() == "Base.Disc_Retail" and item:isRecordedMedia()
        end
        for _, item in ipairs(contextMenuItems) do
            if (isCustomCD(item) or isOriginalCD(item)) then
                menu:addOption(getText("IGUI_SWTC_ChangeCD"), self, function(bagPanel)
                    local parentWindow = bagPanel.parentWindow
                    local mediaPanel = parentWindow and parentWindow.mediaPanel
                    if not mediaPanel then
                        return
                    end
                    if mediaPanel.replaceMedia then
                        mediaPanel:replaceMedia(item)
                    end
                end)
                menu:addOption(getText("IGUI_SWTC_InsertCD"), self, function(bagPanel)
                    local parentWindow = bagPanel.parentWindow
                    local mediaPanel = parentWindow and parentWindow.mediaPanel
                    if not mediaPanel then
                        return
                    end
                    if mediaPanel.addMedia then
                        mediaPanel:addMedia({item})
                    end
                end)
                break
            end
        end
        if menu and menu.numOptions > 1 and JoypadState.players[playerNum+1] then
            menu.mouseOver = 1
            setJoypadFocus(playerNum, menu)
        end
    end
    return true
end

function SWTCBagPanel:updateTooltip()
    if not self:isReallyVisible() then
        return
    end
    
    local item = nil
    if not self.dragging and self:isMouseOver() then
        local x = self:getMouseX()
        local y = self:getMouseY()
        local rowIdx = self:rowAt(x, y)
        local rows = self:getVisibleRows()
        local row = rows[rowIdx]
        item = row and self:getRowItem(row)
    end
    
    local playerNum = self.player and (instanceof(self.player, "IsoPlayer") and self.player:getPlayerNum() or self.player) or 0
    if getPlayerContextMenu(playerNum):isAnyVisible() then
        item = nil
    end
    
    if item and self.toolRender and (item == self.toolRender.item) and self.toolRender:isVisible() then
        return
    end
    
    if item then
        if self.toolRender then
            self.toolRender:setItem(item)
            self.toolRender:setVisible(true)
            self.toolRender:addToUIManager()
            self.toolRender:bringToTop()
        else
            self.toolRender = ISToolTipInv:new(item)
            self.toolRender:initialise()
            self.toolRender:addToUIManager()
            self.toolRender:setVisible(true)
            self.toolRender:setOwner(self)
            self.toolRender:setCharacter(getSpecificPlayer(playerNum))
        end
        self.toolRender.followMouse = true
    elseif self.toolRender then
        self.toolRender:removeFromUIManager()
        self.toolRender:setVisible(false)
    end
end

function SWTCBagPanel:update()
    local currentBag = self:detectEquippedBag()
    if currentBag ~= self.currentEquippedBag then
        self.currentEquippedBag = currentBag
        self.selectedIndex = nil
        self.selectedItem = nil
        self.selected = {}
        self.scrollY = 0
    end
    self:updateScrollValues()
    self:updateTooltip()
    local remove = nil
    if self.currentEquippedBag then
        local bagContainer = self.currentEquippedBag:getInventory()
        for i, v in pairs(self.selected) do
            local rows = self:getVisibleRows()
            local row = rows[i]
            local item = row and self:getRowItem(row)
            if item and instanceof(item, "InventoryItem") then
                if item:getContainer() ~= bagContainer then
                    if remove == nil then
                        remove = {}
                    end
                    remove[i] = i
                end
            end
        end
        if remove ~= nil then
            for i, v in pairs(remove) do
                self.selected[v] = nil
            end
        end
    end
end

function SWTCBagPanel:setVisible(visible)
    ISPanel.setVisible(self, visible)
    if not visible then
        self.currentEquippedBag = nil
        self.selectedIndex = nil
        self.selectedItem = nil
        self.selected = {}
        self.scrollY = 0
        if self.toolRender then
            self.toolRender:removeFromUIManager()
            self.toolRender:setVisible(false)
        end
    else
        self.currentEquippedBag = self:detectEquippedBag()
        self:updateScrollValues()
    end
end

function SWTCBagPanel:clear()
    self.currentEquippedBag = nil
    self.selectedIndex = nil
    self.selectedItem = nil
    self.selected = {}
    self.scrollY = 0
    if self.toolRender then
        self.toolRender:removeFromUIManager()
        self.toolRender:setVisible(false)
        self.toolRender = nil
    end
end

function SWTCBagPanel:readFromObject(player, deviceObject, deviceData, deviceType)
    self.player = player
    if self.parent and self.parent.setExpanded then
        self.parent:setExpanded(true)
    end
    local typeName = deviceObject and deviceObject:getType()
   -- if typeName ~= "CDplayer" and typeName ~= "StarWalkman" then
   --     return false
   -- end
    return true
end

function SWTCBagPanel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.currentEquippedBag = nil
    o.selectedIndex = nil
    o.selectedItem = nil
    o.selected = {}
    o.mouseOverOption = 0
    o.dragging = nil
    o.draggingX = 0
    o.draggingY = 0
    o.dragStarted = false
    o.downX = 0
    o.downY = 0
    o.firstSelect = nil
    o.previousMouseUp = nil
    o.toolRender = nil
    o.player = nil
    o.background = true
    o.backgroundColor = {r=0.2, g=0.2, b=0.2, a=0.3}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    return o
end

function SWTCBagPanel:onMouseWheel(del)
    if self.maxScrollY > 0 then
        self.scrollY = self.scrollY + del * ROW_HEIGHT * 2
        if self.scrollY < 0 then self.scrollY = 0 end
        if self.scrollY > self.maxScrollY then self.scrollY = self.maxScrollY end
        return true
    end
    return false
end

function SWTCBagPanel:onMouseDown(x, y)
    local rowIdx = self:rowAt(x, y)
    if rowIdx > 0 then
        local rows = self:getVisibleRows()
        local row = rows[rowIdx]
        if row and row.type == "group" and #row.group.items > 1 then
            local iconSize = 15
            local iconX = 2
            local rowY = (rowIdx-1)*ROW_HEIGHT + UI_BORDER_SPACING - self.scrollY
            local iconY = rowY + (ROW_HEIGHT - iconSize) / 2
            if x >= iconX and x <= iconX+iconSize and y >= iconY and y <= iconY+iconSize then
                row.group.collapsed = not row.group.collapsed
                if not self._collapseState then self._collapseState = {} end
                self._collapseState[row.group.name] = row.group.collapsed
                self:forceRefresh()
                return true
            end
        end
        self.selected = {}
        self.selected[rowIdx] = true
    else
        self.selected = {}
    end
end

function SWTCBagPanel:onMouseDownOutside(x, y)
    self.selected = {}
end 