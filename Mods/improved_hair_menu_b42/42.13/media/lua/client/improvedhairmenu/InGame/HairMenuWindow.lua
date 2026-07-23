if isServer() then return end
require "improvedhairmenu/InGame/IHM_GridControls"
local _ok = pcall(require, "improvedhairmenu/ModOptions")
HairMenuPanelWindow = ISCollapsableWindowJoypad:derive("HairMenuPanelWindow")

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

    -- Build grid
    self:rebuildPanel()

    -- Single button that opens the popup with sliders
    function self:installControlsButton()
        if self._controlsBtn then
            self:removeChild(self._controlsBtn)
            self._controlsBtn = nil
        end
        local th = self:titleBarHeight()
        local y  = th + 4
        local x  = self.hairPanel:getX() + self.hairPanel:getWidth() - 100
        if x < 8 then x = 8 end

        local title = (getText and getText("CONTROLS")) or "Controls"
        local b = ISButton:new(x, y, 96, 20, title, self, function()
            -- Close any previous controls window (safety)
            if self._controlsWin and self._controlsWin.close then
                pcall(function() self._controlsWin:close() end)
                self._controlsWin = nil
            end
            -- Open and keep a handle so we can close it when this window hides
            self._controlsWin = IHM_GridControlsWindow.open(self, {
                onChange = function()
                    -- Values are written to IHM_live.ini; just rebuild the grid live.
                    self:rebuildPanel()
                end
            })
        end)
        b:initialise(); b:instantiate()
        if b.setBorderRGBA then b:setBorderRGBA(0.3,0.3,0.3,0.9) end
        b:setDisplayBackground(true)
        b:setBackgroundRGBA(0,0,0,0.15)

        self:addChild(b)
        self._controlsBtn = b
    end

    self:installControlsButton()

    -- Wrap setVisible(false) to also close the controls window automatically.
    if not self._setVisibleWrapped then
        local _setVisible = self.setVisible
        self.setVisible = function(s, v, ...)
            local r = _setVisible(s, v, ...)
            if v == false and s._controlsWin and s._controlsWin.close then
                pcall(function() s._controlsWin:close() end)
                s._controlsWin = nil
            end
            return r
        end
        self._setVisibleWrapped = true
    end
end

function HairMenuPanelWindow:rebuildPanel()
    local th = self:titleBarHeight()

    -- -------- LIVE-FIRST SETTINGS RESOLUTION ---------------------------------
    local rows, cols, avatar_px

    -- 1) Read live (slider) values from IHM_LiveConfig cache if present
    do
        local LC = rawget(_G, "IHM_LiveConfig")
        if LC and LC.load then pcall(function() LC:load() end) end
        local cache = LC and LC.cache
        if cache then
            local function clampInt(v, lo, hi)
                v = tonumber(v)
                if not v then return nil end
                v = math.floor(v + 0.5)
                if v < lo then v = lo end
                if v > hi then v = hi end
                return v
            end
            local function pxFromStep(step) -- step 1..7 -> 32..128 (step 16)
                step = clampInt(step, 1, 7) or 5
                return 32 + ((step - 1) * 16)
            end

            local step = cache.avatar_size
            if step ~= nil then avatar_px = pxFromStep(step) end
            rows = clampInt(cache.modal_rows, 1, 10) or rows
            cols = clampInt(cache.modal_cols, 1, 10) or cols
        end
    end

    -- 2) Fallback to persisted settings getters (existing mod options)
    if not avatar_px or not rows or not cols then
        local S = ImprovedHairMenu and ImprovedHairMenu.settings
        if S then
            if (not avatar_px) and S.get_avatar_size then
                avatar_px = tonumber(S:get_avatar_size()) or avatar_px
            end
            if (not rows or not cols) and S.get_menu_size then
                local cfg = S:get_menu_size(self.isbeard)
                if cfg then
                    rows = tonumber(cfg.rows) or rows
                    cols = tonumber(cfg.cols)  or cols
                end
            end
        end
    end

    -- 3) Final defaults + clamps (robust)
    avatar_px = tonumber(avatar_px) or 96
    rows      = math.max(1, math.min(10, math.floor(tonumber(rows) or 2)))
    cols      = math.max(1, math.min(10, math.floor(tonumber(cols) or 3)))
    -- -------------------------------------------------------------------------

    if self.hairPanel then self:removeChild(self.hairPanel) end

    self.hairPanel = HairMenuPanel:new(0, th, avatar_px, avatar_px, rows, cols, 3, self.isbeard)
    self.hairPanel.showSelectedName = false
    self.hairPanel:initialise()
    self.hairPanel:setChar(self.char)
    self.hairPanel.onSelect = function(select_name)
        if self.onSelect then self.onSelect(select_name) end
    end
    self.hairPanel:setHairList(self.hairList)
    self:addChild(self.hairPanel)

    -- Resize & center window to new panel
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    self:setWidth(self.hairPanel:getWidth())
    local desiredH = th + self.hairPanel:getHeight()
    local maxH     = math.floor(sh * 0.90)
    self:setHeight(math.min(desiredH, maxH))
    self:setX((sw - self:getWidth()) / 2)
    self:setY((sh - self:getHeight()) / 2)

    -- Recreate live controls so they anchor correctly
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