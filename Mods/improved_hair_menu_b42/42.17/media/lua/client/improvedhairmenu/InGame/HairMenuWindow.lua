if isServer() then return end
require "improvedhairmenu/InGame/IHM_GridControls"
local _ok = pcall(require, "improvedhairmenu/ModOptions")
HairMenuPanelWindow = ISCollapsableWindowJoypad:derive("HairMenuPanelWindow")

local function _IHM_getInGameLiveValue(primaryKey, legacyKey, defaultValue, minValue, maxValue)
    local function clampInt(v, lo, hi)
        v = tonumber(v)
        if not v then return nil end
        v = math.floor(v + 0.5)
        if v < lo then v = lo end
        if v > hi then v = hi end
        return v
    end

    local LC = rawget(_G, "IHM_LiveConfig")
    if LC and LC.load then
        pcall(function() LC:load() end)
    end

    if LC and LC.cache then
        local v = LC.cache[primaryKey]
        if v == nil and legacyKey then
            v = LC.cache[legacyKey]
        end
        v = clampInt(v, minValue, maxValue)
        if v ~= nil then
            return v
        end
    end

    local S = ImprovedHairMenu and ImprovedHairMenu.settings
    if S then
        local v = S[primaryKey]
        if v == nil and legacyKey then
            v = S[legacyKey]
        end
        v = clampInt(v, minValue, maxValue)
        if v ~= nil then
            return v
        end
    end

    return defaultValue
end

function HairMenuPanelWindow:new(x, y, width, height, playerNum, char, hairlist, isbeard)
	local o = ISCollapsableWindowJoypad.new(self, x, y, width, height)
	o.char = char
	o.hairList = hairlist
	o.onSelect = nil
	o.isbeard = isbeard
	o.playerNum = playerNum
	return o
end

function HairMenuPanelWindow:render()
	ISCollapsableWindowJoypad.render(self)

	if JoypadState.players[self.playerNum+1] then
		if JoypadState.players[self.playerNum+1].focus == self then
			self:drawRectBorder(0, 0, self:getWidth(), self:getHeight(), 0.4, 0.2, 1.0, 1.0);
			self:drawRectBorder(1, 1, self:getWidth()-2, self:getHeight()-2, 0.4, 0.2, 1.0, 1.0);
		end
	end
end

function HairMenuPanelWindow:createChildren()
    ISCollapsableWindowJoypad.createChildren(self)
    self.resizable = false

    self:rebuildPanel()

    function self:installControlsButton()
        if self._controlsBtn then
            self:removeChild(self._controlsBtn)
            self._controlsBtn = nil
        end

        local th = self:titleBarHeight()
        local smallH = getTextManager():getFontHeight(UIFont.Small)
        local btnH = math.max(22, smallH + 6)
        local title = (getText and getText("CONTROLS")) or "Controls"
        local btnW = math.max(96, getTextManager():MeasureStringX(UIFont.Small, title) + 24)
        local y = th + math.max(4, math.floor(smallH * 0.25))
        local x = self:getWidth() - btnW - 8
        if x < 8 then x = 8 end

        local b = ISButton:new(x, y, btnW, btnH, title, self, function()
            if self._controlsWin and self._controlsWin.close then
                pcall(function() self._controlsWin:close() end)
                self._controlsWin = nil
            end

            self._controlsWin = IHM_GridControlsWindow.open(self, {
                context = "ingame",
                onChange = function()
                    self:rebuildPanel()
                end,
            })
        end)
        b:initialise()
        b:instantiate()
        if b.setBorderRGBA then b:setBorderRGBA(0.3, 0.3, 0.3, 0.9) end
        b:setDisplayBackground(true)
        b:setBackgroundRGBA(0, 0, 0, 0.15)

        self:addChild(b)
        self._controlsBtn = b
    end

    self:installControlsButton()

    if not self._setVisibleWrapped then
        local _setVisible = self.setVisible
        self.setVisible = function(s, visible, ...)
            local result = _setVisible(s, visible, ...)
            if visible == false and s._controlsWin and s._controlsWin.close then
                pcall(function() s._controlsWin:close() end)
                s._controlsWin = nil
            end
            return result
        end
        self._setVisibleWrapped = true
    end
end

function HairMenuPanelWindow:rebuildPanel()
    local th = self:titleBarHeight()

    local function clampInt(v, lo, hi)
        v = tonumber(v)
        if not v then return nil end
        v = math.floor(v + 0.5)
        if v < lo then v = lo end
        if v > hi then v = hi end
        return v
    end

    local function pxFromStep(step)
        step = clampInt(step, 1, 7) or 5
        return 32 + ((step - 1) * 16)
    end

    local rows = _IHM_getInGameLiveValue("ig_modal_rows", "modal_rows", 2, 1, 10)
    local cols = _IHM_getInGameLiveValue("ig_modal_cols", "modal_cols", 3, 1, 10)
    local avatarStep = _IHM_getInGameLiveValue("ig_avatar_size", "avatar_size", 5, 1, 7)
    local avatar_px = pxFromStep(avatarStep)

    if self.hairPanel then
        self:removeChild(self.hairPanel)
    end

    self.hairPanel = HairMenuPanel:new(0, th, avatar_px, avatar_px, rows, cols, 3, self.isbeard)
    self.hairPanel.showSelectedName = true
    self.hairPanel:initialise()
    self.hairPanel:setChar(self.char)
    self.hairPanel.onSelect = function(selection)
        if self.onSelect then
            self.onSelect(selection)
        end
    end
    self.hairPanel:setHairList(self.hairList)
    self:addChild(self.hairPanel)

    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local title = (getText and getText("CONTROLS")) or "Controls"
    local ctrlW = math.max(96, getTextManager():MeasureStringX(UIFont.Small, title) + 24)
    local targetW = math.max(self.hairPanel:getWidth(), ctrlW + 16)
    local desiredH = th + self.hairPanel:getHeight()
    local maxH = math.floor(sh * 0.90)

    self:setWidth(targetW)
    self:setHeight(math.min(desiredH, maxH))
    self.hairPanel:setX(math.floor((targetW - self.hairPanel:getWidth()) / 2))
    self.hairPanel:setY(th)

    self:setX((sw - self:getWidth()) / 2)
    self:setY((sh - self:getHeight()) / 2)

    if self.installControlsButton then
        self:installControlsButton()
    end
end

function HairMenuPanelWindow:close()
    -- Close the Controls popup first (if present)
    if self._controlsWin and self._controlsWin.close then
        pcall(function() self._controlsWin:close() end)
        self._controlsWin = nil
    end

    self:setVisible(false)
    self:removeFromUIManager()
    if JoypadState.players[self.playerNum+1] then
        setJoypadFocus(self.playerNum, self.returnFocus)
    end
end

function HairMenuPanelWindow:onLoseJoypadFocus(joypadData)
	ISCollapsableWindowJoypad.onLoseJoypadFocus(self, joypadData)
	self.hairPanel:setJoypadFocused(false)
end

function HairMenuPanelWindow:onGainJoypadFocus(joypadData)
	ISCollapsableWindowJoypad.onGainJoypadFocus(self, joypadData)
	self.hairPanel:setJoypadFocused(true)
end

function HairMenuPanelWindow:onJoypadDown(button, joypadData)
	if button == Joypad.BButton then
		self:close()
	end
	self.hairPanel:onJoypadDown(button, joypadData)
	ISCollapsableWindowJoypad.onJoypadDown(self, joypadData)
end

function HairMenuPanelWindow:onJoypadDirLeft(joypadData)
	self.hairPanel:onJoypadDirLeft(joypadData)
	ISCollapsableWindowJoypad.onJoypadDirLeft(self, joypadData)
end

function HairMenuPanelWindow:onJoypadDirRight(joypadData)
	self.hairPanel:onJoypadDirRight(joypadData)
	ISCollapsableWindowJoypad.onJoypadDirRight(self, joypadData)
end

function HairMenuPanelWindow:onJoypadDirUp(joypadData)
	self.hairPanel:onJoypadDirUp(joypadData)
	ISCollapsableWindowJoypad.onJoypadDirUp(self, joypadData)
end

function HairMenuPanelWindow:onJoypadDirDown(joypadData)
	self.hairPanel:onJoypadDirDown(joypadData)
	ISCollapsableWindowJoypad.onJoypadDirDown(self, joypadData)
end