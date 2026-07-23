--[[
	This is the actual menu element.

	By being a separate UI element it can be implemented in both the character creation menu and in-game hair options.
]]
if isServer() then return end
local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

local function _IHM_clipToWidth(font, s, maxw)
    if not s or s == "" then return "" end
    local tm = getTextManager()
    if tm:MeasureStringX(font, s) <= maxw then return s end
    local ell  = "..."
    local ellW = tm:MeasureStringX(font, ell)
    local res  = s
    while #res > 0 and (tm:MeasureStringX(font, res) + ellW) > maxw do
        res = string.sub(res, 1, #res - 1)
    end
    return res .. ell
end

local header_height = FONT_HGT_SMALL + 14

local function predicateAvatarIsSelectable(avatar)
	return avatar and avatar.selectable == true
end

local base = ISPanelJoypad
HairMenuPanel = base:derive("HairMenuPanel")

local function IHM_HMP_smallFontHgt()
    return getTextManager():getFontHeight(UIFont.Small)
end

local function IHM_HMP_headerHeight()
    local smallH = IHM_HMP_smallFontHgt()
    return math.max(smallH + 14, 28)
end

local function IHM_HMP_navButtonSize()
    local smallH = IHM_HMP_smallFontHgt()
    return math.max(18, smallH + 4)
end

local function IHM_HMP_headerPad()
    local smallH = IHM_HMP_smallFontHgt()
    return math.max(5, math.floor(smallH * 0.4))
end

function HairMenuPanel:render()
    ISPanelJoypad.render(self)

    if not self.pageLeftButton or not self.pageRightButton then
        return
    end

    local tm = getTextManager()
    local font = UIFont.Small
    local smallH = tm:getFontHeight(font)
    local textY = self.pageLeftButton:getY() + math.floor((self.pageLeftButton:getHeight() - smallH) / 2)
    local xLeft = self.pageRightButton:getRight() + math.max(6, math.floor(self.pageRightButton:getWidth() / 3))

    local pages = tostring(self.pageCurrent) .. "/" .. tostring(self:getNumberOfPages())
    self:drawText(pages, xLeft, textY, 0.9, 0.9, 0.9, 0.9, font)
    xLeft = xLeft + tm:MeasureStringX(font, pages) + math.max(10, math.floor(smallH * 0.75))

    local rightW = 0
    local gap = math.max(6, math.floor(smallH * 0.35))
    local ctrl = self.hairControlsBtn or self.beardControlsBtn
    if self.hairColorBtn then
        rightW = rightW + self.hairColorBtn:getWidth() + gap
    end
    if self.stubbleTickBox then
        rightW = rightW + self.stubbleTickBox:getWidth() + gap
    end
    if ctrl then
        rightW = rightW + ctrl:getWidth() + gap
    end

    local xRightLimit = self:getWidth() - rightW - IHM_HMP_headerPad()
    local maxTitleW = math.max(0, xRightLimit - xLeft)

    local titleInfo = self.selectedHairInfo

    if self.joypadCursor and self.avatarList and self.avatarList[self.joypadCursor] and self.avatarList[self.joypadCursor].selectable then
        local hoveredInfo = self.avatarList[self.joypadCursor].visualItem
        if type(hoveredInfo) == "table" and hoveredInfo.display then
            titleInfo = hoveredInfo
        end
    end

    if self.showSelectedName and titleInfo and type(titleInfo) == "table" then
        local title = _IHM_clipToWidth(font, titleInfo.display or "", maxTitleW)
        self:drawText(title, xLeft, textY, 0.9, 0.9, 0.9, 0.9, font)
    end
end

function HairMenuPanel:new(x, y, size_x, size_y, rows, cols, gap, isBeard)
    size_x = size_x or 96
    size_y = size_y or 96
    rows   = rows or 2
    cols   = cols or 4
    gap    = gap or 3

    local headerH = IHM_HMP_headerHeight()
    local o = base.new(self, x, y, (size_x * cols) + (gap * (cols - 1)), (size_y * rows) + (gap * (rows - 1)) + headerH)
    o.isHairMenu = true
    o.gridSizeX = size_x
    o.gridSizeY = size_y
    o.gridRows = rows
    o.gridCols = cols
    o.pageSize = rows * cols
    o.gap = gap
    o.avatarList = {}
    o.info = {}
    o.pageCurrent = 1
    o.onSelect = nil
    o.isBeard = isBeard
    o.showSelectedName = true
    o.joypadCursor = 1
    o.selectedHairInfo = { id = "", display = "" }
    o.headerHeight = headerH
    return o
end

function HairMenuPanel:initialise()
    local pageBtnSize = IHM_HMP_navButtonSize()
    local headerPad = IHM_HMP_headerPad()
    local headerH = math.max(IHM_HMP_headerHeight(), pageBtnSize + headerPad * 2)
    local arrowGap = math.max(5, math.floor(pageBtnSize / 3))

    self.headerHeight = headerH
    self.offset_x = 0
    self.offset_y = headerH

    self.pageLeftButton = ISButton:new(5, headerPad, pageBtnSize, pageBtnSize, "", self, self.onChangePageButton)
    self.pageLeftButton.internal = "PREV"
    self.pageLeftButton:initialise()
    self.pageLeftButton:instantiate()
    self.pageLeftButton:setImage(getTexture("media/ui/ArrowLeft.png"))
    self:addChild(self.pageLeftButton)

    self.pageRightButton = ISButton:new(self.pageLeftButton:getRight() + arrowGap, headerPad, pageBtnSize, pageBtnSize, "", self, self.onChangePageButton)
    self.pageRightButton.internal = "NEXT"
    self.pageRightButton:initialise()
    self.pageRightButton:instantiate()
    self.pageRightButton:setImage(getTexture("media/ui/ArrowRight.png"))
    self:addChild(self.pageRightButton)

    for h = 1, self.gridRows do
        for v = 1, self.gridCols do
            local idx = ((h - 1) * self.gridCols) + v
            local x = ((v - 1) * self.gridSizeX) + (self.gap * (v - 1))
            local y = self.offset_y + ((h - 1) * self.gridSizeY) + (self.gap * (h - 1))
            local hairAvatar = HairAvatar:new(x, y, self.gridSizeX, self.gridSizeY)
            hairAvatar:initialise()
            hairAvatar:instantiate()
            hairAvatar:setVisible(true)
            hairAvatar.panelIndex = idx
            hairAvatar.onSelect = function(avatar)
                self:onAvatarSelect(avatar)
            end

            hairAvatar.onMouseMove = function(avatar, mx, my)
                HairAvatar.onMouseMove(avatar, mx, my)
                self:setCursor(avatar.panelIndex)
            end

            hairAvatar.onMouseMoveOutside = function(avatar, mx, my)
                HairAvatar.onMouseMoveOutside(avatar, mx, my)
                if self.joypadFocus then return end
                if self.joypadCursor == avatar.panelIndex then
                    self:setCursor(nil)
                end
            end

            self:addChild(hairAvatar)
            self.avatarList[idx] = hairAvatar
        end
    end

    self.offset_y = self.offset_y + (self.gridRows * self.gridSizeY) + (self.gap * (self.gridRows - 1))
    self:setHeight(self.offset_y)
end

function HairMenuPanel:onAvatarSelect(hairAvatar)
	self:selectInfo(hairAvatar.visualItem)
end

-- Silently updates the hair info selection, avoiding triggering the `onSelect` callback which can cause infinite loops.
function HairMenuPanel:setSelectedInfo(hairInfo)
	-- XXX: This function has to allow for nil as beard menus might be initialized to nil if starting with a female character.
	if self.selectedHairInfo then self.selectedHairInfo.selected = false end
	self.selectedHairInfo = hairInfo
	if self.selectedHairInfo then self.selectedHairInfo.selected = true end
end

function HairMenuPanel:selectInfo(hairInfo)
	if type(hairInfo) == "number" then hairInfo = self.info[hairInfo] end
	if not hairInfo then print("HairMenuPanel:selectInfo(): info shouldn't be nil") return end
	self:setSelectedInfo(hairInfo)
	if self.onSelect then self.onSelect(hairInfo) end
end

function HairMenuPanel:setDesc(desc)
	for i=1,#self.avatarList do
		self.avatarList[i]:setDesc(desc)
	end
end

function HairMenuPanel:setChar(desc)
	for i=1,#self.avatarList do
		self.avatarList[i]:setChar(desc)
	end
end

function HairMenuPanel:applyVisual(desc)
	for i=1,#self.avatarList do
		self.avatarList[i]:applyVisual()
	end
end

function HairMenuPanel:setHairList(list)
	if type(list) ~= "table" then
		print("HairMenuPanel:setHairList() given a non-table value, ignoring and setting to blank table.")
		self.info = {}
	else
		self.info = list
	end
	self:showPage(1)
end

-- #########
-- # Pages #
-- #########

function HairMenuPanel:onChangePageButton(button,x,y)
	if button.internal == "NEXT" then 
		self:changePage(1)
	elseif button.internal == "PREV" then 
		self:changePage(-1)
	end
end

function HairMenuPanel:getNumberOfPages()
	return math.ceil(#self.info / self.pageSize)
end

function HairMenuPanel:getCurrentPageSize()
	-- HACK: Only the last page has less than pageSize elements
	if self:getNumberOfPages() ~= self.pageCurrent then
		return self.pageSize
	else
		return #self.info % self.pageSize
	end
end

function HairMenuPanel:changePage(step)
	self:showPage(ImprovedHairMenu.math.wrap(self.pageCurrent + step, 1, self:getNumberOfPages()))
end

function HairMenuPanel:showPage(page_number)
	self.pageCurrent = page_number
	for i=1,self.pageSize do
		local info = self.info[((page_number-1) * self.pageSize) + i]
		if info then 
			self.avatarList[i].selectable = true
			self.avatarList[i]:setVisualItem(info)
			self.avatarList[i]:applyVisual()
			self.avatarList[i]:setVisible(true)
		else
			self.avatarList[i].selectable = false
			self.avatarList[i]:setVisible(false)
		end
	end

	if self.joypadFocus then
		self:makeCursorValid()
	else
		self:setCursor(nil)
	end
end

-- ##########
-- # Cursor #
-- ##########

function HairMenuPanel:getValidCursor(index)
	-- NOTE: index 1 will always be valid as the page wouldn't exist if there wasn't at least 1 element.
	local cursor = ImprovedHairMenu.math.clamp(index, 1, self.pageSize)
	if not self.avatarList[cursor].selectable == true then 
		for i=0,self.pageSize do
			local new_cursor = ImprovedHairMenu.math.wrap(cursor - i, 1, self.pageSize) -- NOTE: Move downwards as avatars are seqential.
			if self.avatarList[new_cursor].selectable == true then 
				cursor = new_cursor
				break
			end
		end
	end
	return cursor
end

function HairMenuPanel:setCursor(index)
	if self.joypadCursor then
		-- NOTE: Clear old cursor. this should avoid a double cursor as long as everyone uses this function.
		self.avatarList[self.joypadCursor]:setCursor(false)
	end

	if not index then
		self.joypadCursor = nil
		return
	end

	self.joypadCursor = self:getValidCursor(index)
	self.avatarList[self.joypadCursor]:setCursor(true)
end

function HairMenuPanel:makeCursorValid()
	self:setCursor(self:getValidCursor(self.joypadCursor))
end

--##################
--Controller Support
--##################

--[[ NOTE:
	We never actually get the joypad focus onto this element.
	Similar to how vanilla handles this (see `ISPanelJoypad`) we forward events from the panel to the element.
 ]]

function HairMenuPanel:ensureCursor()
	if not self.joypadCursor then
		self:setCursor(1)
	end
end

function HairMenuPanel:stepCursor(direction)
	self:ensureCursor()

	local direction = ImprovedHairMenu.math.sign(direction)

	-- NOTE: `stepCursor` is only called by joypad events we don't need any flags for joypad usage
	if direction ~= 0 then
		if self.joypadCursor + direction > self:getCurrentPageSize() then
			self:changePage(1)
			self:setCursor(1)
			return
		elseif self.joypadCursor + direction < 1 then
			self:changePage(-1)
			self:setCursor(self.pageSize)
			return
		end
	end

	self:setCursor(self.joypadCursor + direction)
end

-- Determines if the next joypad press should move outside the menu
function HairMenuPanel:isNextDownOutside()
	if not self.joypadCursor then
		return true
	end
	return not predicateAvatarIsSelectable(self.avatarList[self.joypadCursor + self.gridCols])
end

-- Determines if the next joypad press should move outside the menu
function HairMenuPanel:isNextUpOutside()
	if not self.joypadCursor then
		return true
	end
	return not predicateAvatarIsSelectable(self.avatarList[self.joypadCursor - self.gridCols])
end

function HairMenuPanel:setJoypadFocused(focused, joypadData)
	-- XXX: This function has to at least exist as vanilla calls it on any element that doesn't directly recieve focus
	self.joypadFocus = focused
	if focused then
		self:setCursor(1)
	else
		self:setCursor(nil)
	end
end

function HairMenuPanel:onJoypadDown(button, joypadData)
	if button == Joypad.RBumper then self:changePage(1) end
	if button == Joypad.LBumper then self:changePage(-1) end
	if button == Joypad.AButton then
		self:ensureCursor()
		if self.avatarList[self.joypadCursor] then self.avatarList[self.joypadCursor]:select() end
	end
	if button == Joypad.XButton then
		if self.stubbleTickBox then self.stubbleTickBox:forceClick() end
	end
	if button == Joypad.YButton then
		if self.hairColorBtn then self.hairColorBtn:forceClick() end
	end
end

function HairMenuPanel:onJoypadDirLeft(joypadData)  self:stepCursor(-1) end
function HairMenuPanel:onJoypadDirRight(joypadData) self:stepCursor(1)  end

function HairMenuPanel:onJoypadDirDown(joypadData)
	self:ensureCursor()
	local i = self.joypadCursor + self.gridCols
	if predicateAvatarIsSelectable(self.avatarList[i]) then
		self:setCursor(i)
	end
end

function HairMenuPanel:onJoypadDirUp(joypadData)
	self:ensureCursor()
	local i = self.joypadCursor - self.gridCols
	if predicateAvatarIsSelectable(self.avatarList[i]) then
		self:setCursor(i)
	end
end