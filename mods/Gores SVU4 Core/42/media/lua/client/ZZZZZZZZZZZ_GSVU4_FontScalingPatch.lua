--========================================================
-- GORE'S SVU4 CORE - FONT / UI SCALING PATCH
--========================================================
require "VehicleArmor_UI"

local PREFIX = "[Gore's SVU4 Core FontScaling] "

local function textHeight(font)
    if getTextManager and UIFont then
        local ok, h = pcall(function() return getTextManager():getFontHeight(font or UIFont.Small) end)
        if ok and tonumber(h) then return tonumber(h) end
    end
    return 14
end

local function scaledButtonHeight() return math.max(28, textHeight(UIFont.Small) + 12) end
local function scaledRowHeight() return math.max(22, textHeight(UIFont.Small) + 8) end

local function measureTitle(button)
    if not button or not button.getTitle or not getTextManager or not UIFont then return 0 end
    local okTitle, title = pcall(function() return button:getTitle() end)
    if not okTitle or not title then return 0 end
    local okW, width = pcall(function() return getTextManager():MeasureStringX(UIFont.Small, tostring(title)) end)
    if okW and tonumber(width) then return tonumber(width) end
    return 0
end

local function setButtonSafe(button, minWidth)
    if not button then return end
    local h = scaledButtonHeight()
    local w = minWidth or (button.getWidth and button:getWidth() or 0)
    local titleW = measureTitle(button)
    if titleW > 0 then w = math.max(w, titleW + 24) end
    if button.setHeight then button:setHeight(h) end
    if button.setWidth then button:setWidth(w) end
end

local function safeSetY(control, y) if control and control.setY then control:setY(y) end end
local function safeSetHeight(control, h) if control and control.setHeight then control:setHeight(h) end end

local function applyKnownButtonScaling(self)
    if not self then return end
    local minMain = math.max(135, textHeight(UIFont.Small) * 8)
    setButtonSafe(self.actionButton, minMain)
    setButtonSafe(self.repairButton, minMain)
    setButtonSafe(self.installAllButton, minMain)
    setButtonSafe(self.repairAllButton, minMain)
    setButtonSafe(self.uninstallAllButton, minMain)
    setButtonSafe(self.clearInstallSelectionButton, 120)
    setButtonSafe(self.sortButton, 95)
    setButtonSafe(self.filterButton, 95)
    setButtonSafe(self.closeButton, scaledButtonHeight())
    if self.gradeButtons then for _, btn in pairs(self.gradeButtons) do setButtonSafe(btn, 105) end end
    if self.gsvu4AdminButtons then for _, btn in pairs(self.gsvu4AdminButtons) do setButtonSafe(btn, 110) end end
end

local function applyListScaling(self)
    if not self then return end
    local rowH = scaledRowHeight()
    if self.partsList then
        if self.partsList.itemheight then self.partsList.itemheight = rowH end
        if self.partsList.itemHeight then self.partsList.itemHeight = rowH end
    end
    if self.overviewList then
        if self.overviewList.itemheight then self.overviewList.itemheight = rowH end
        if self.overviewList.itemHeight then self.overviewList.itemHeight = rowH end
    end
end

local function applyBottomLayout(self)
    if not self or not self.getHeight then return end
    local h = scaledButtonHeight()
    local bottomY = self:getHeight() - h - 8
    local buttons = { self.actionButton, self.repairButton, self.installAllButton, self.repairAllButton, self.uninstallAllButton }
    for _, btn in ipairs(buttons) do safeSetY(btn, bottomY); safeSetHeight(btn, h) end
    local reserve = h + 18
    if self.detailBox and self.detailBox.getY and self.detailBox.setHeight then
        self.detailBox:setHeight(math.max(80, self:getHeight() - self.detailBox:getY() - reserve))
    end
    if self.overviewBox and self.overviewBox.getY and self.overviewBox.setHeight then
        self.overviewBox:setHeight(math.max(80, self:getHeight() - self.overviewBox:getY() - reserve))
    end
end

local function applyFontScaling(self)
    applyKnownButtonScaling(self); applyListScaling(self); applyBottomLayout(self)
end

if VehicleArmorWindow and not VehicleArmorWindow.GSVU4_FontScalingWrapped then
    local oldCreateChildren = VehicleArmorWindow.createChildren
    function VehicleArmorWindow:createChildren()
        if oldCreateChildren then oldCreateChildren(self) end
        applyFontScaling(self)
    end
    local oldUpdateBulkButtons = VehicleArmorWindow.updateBulkButtons
    function VehicleArmorWindow:updateBulkButtons(report)
        if oldUpdateBulkButtons then oldUpdateBulkButtons(self, report) end
        applyKnownButtonScaling(self); applyBottomLayout(self)
    end
    local oldPopulateParts = VehicleArmorWindow.populateParts
    function VehicleArmorWindow:populateParts()
        if oldPopulateParts then oldPopulateParts(self) end
        applyListScaling(self)
    end
    local oldPrerender = VehicleArmorWindow.prerender
    function VehicleArmorWindow:prerender()
        if oldPrerender then oldPrerender(self) end
        local h = scaledButtonHeight()
        if self.gsvu4LastFontButtonHeight ~= h then
            self.gsvu4LastFontButtonHeight = h
            applyFontScaling(self)
        end
    end
    VehicleArmorWindow.GSVU4_FontScalingWrapped = true
end
