-- IHM_GridControls.lua — popup with sliders for grid controls
-- Place at: media/lua/client/improvedhairmenu/InGame/IHM_GridControls.lua
if isServer() then return end
require "ISUI/ISCollapsableWindow"
require "ISUI/ISPanel"
require "ISUI/ISLabel"
require "ISUI/ISButton"
require "RadioCom/ISUIRadio/ISSliderPanel"
local _ok = pcall(require, "improvedhairmenu/ModOptions")
IHM_GridControlsWindow = ISCollapsableWindow:derive("IHM_GridControlsWindow")

local PAD   = 10
local GAP_Y = 10
local LBL_W = 120
local VAL_W = 40
local SL_W  = 220
local ROW_H = 24

local function _clampInt(v, lo, hi)
    v = tonumber(v) or lo
    if v < lo then return lo end
    if v > hi then return hi end
    return math.floor(v + 0.5)
end

local function _avatarPxFromStep(n) -- 1..7 -> 32..128 step 16
    n = _clampInt(n or 5, 1, 7)
    return 32 + ((n - 1) * 16)
end

function IHM_GridControlsWindow:new(x, y, w, h, owner, opts)
    local o = ISCollapsableWindow.new(self, x, y, w, h)
    o.owner   = owner
    o.opts    = opts or {}
    o.resizable = false
    o.moveWithMouse = true
    o:setWantKeyEvents(true)
    return o
end

function IHM_GridControlsWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
	-- Pull latest live overrides so the sliders start on the saved values
	if IHM_LiveConfig and ImprovedHairMenu and ImprovedHairMenu.settings then
		pcall(function()
			IHM_LiveConfig:load()
			IHM_LiveConfig:applyToSettings(ImprovedHairMenu.settings)
		end)
	end
	
    local title = (getText and getText("CONTROLS")) or "Controls"
    self:setTitle(title)

    local S = ImprovedHairMenu and ImprovedHairMenu.settings or {}

    local rows = _clampInt((S.modal_rows or 8), 1, 10)
    local cols = _clampInt((S.modal_cols or 6), 1, 10)
    local asz  = _clampInt((S.avatar_size or 5), 1, 7)

    self._sliders = {}
    self._labels  = {}
    self._cache   = { modal_rows = rows, modal_cols = cols, avatar_size = asz }

    local y = self:titleBarHeight() + PAD

    local function addSliderRow(labelText, key, min, max, step, cur, fmtFn)
        local lbl = ISLabel:new(PAD, y, ROW_H, labelText, 1,1,1,1, UIFont.Small, true)
        lbl:initialise(); lbl:instantiate()
        self:addChild(lbl)

        local valLbl = ISLabel:new(PAD + LBL_W + SL_W + 6, y, ROW_H, "", 0.85,0.85,0.85,1, UIFont.Small, true)
        valLbl:initialise(); valLbl:instantiate()
        self:addChild(valLbl)

        local win = self
        local sl = ISSliderPanel:new(PAD + LBL_W, y - 2, SL_W, ROW_H,
            function(_, v)
                local iv = _clampInt(v, min, max)
                if IHM_LiveConfig then IHM_LiveConfig:updateAndSave(key, iv) end
                valLbl.name = fmtFn and fmtFn(iv) or tostring(iv)
                win._cache[key] = iv
            end,
            nil)
        sl:initialise()
        sl:setDoButtons(true)
        sl:setValues(min, max, step, step, true)
        sl:setCurrentValue(cur, true)

        -- Rebuild NUR bei Loslassen (Maus + +/- Buttons)
        local baseOnMouseUp = sl.onMouseUp
        function sl:onMouseUp(...)
            if baseOnMouseUp then baseOnMouseUp(self, ...) end
            if win.opts and win.opts.onChange then win.opts.onChange() end
        end

        self:addChild(sl)

        valLbl.name = fmtFn and fmtFn(cur) or tostring(cur)
        self._sliders[key] = sl
        self._labels[key]  = valLbl

        y = y + ROW_H + GAP_Y
    end

    addSliderRow((getText and getText("IGUI_IHM_modal_rows")) or "Rows",
                 "modal_rows", 1, 10, 1, rows,
                 function(v) return tostring(v) end)
    addSliderRow((getText and getText("IGUI_IHM_modal_cols")) or "Columns",
                 "modal_cols", 1, 10, 1, cols,
                 function(v) return tostring(v) end)
    addSliderRow((getText and getText("IGUI_IHM_avatar_size")) or "Avatar size",
                 "avatar_size", 1, 7, 1, asz,
                 function(v) return tostring(v) .. " (" .. _avatarPxFromStep(v) .. "px)" end)

    local btnW, btnH = 80, 22
    local closeBtn = ISButton:new(self:getWidth() - PAD - btnW, self:getHeight() - PAD - btnH, btnW, btnH,
        (getText and getText("UI_Close")) or "Close", self, function() self:close() end)
    closeBtn:initialise(); closeBtn:instantiate()
    self:addChild(closeBtn)
end

function IHM_GridControlsWindow:prerender()
    -- Auto-close if the owner hair menu is no longer visible.
    if not self.owner
        or (self.owner.getIsVisible and not self.owner:getIsVisible())
        or (self.owner.isVisible and not self.owner:isVisible())
    then
        self:close()
        return
    end

    ISCollapsableWindow.prerender(self)
    if not self._sliders then return end

    local function sync(key, fmtFn)
        local sl = self._sliders[key]; local lbl = self._labels[key]
        if not sl then return end
        local cur = math.floor(sl:getCurrentValue() + 0.5)
        if key == "avatar_size" then
            if cur < 1 then cur = 1 elseif cur > 7  then cur = 7  end
        else
            if cur < 1 then cur = 1 elseif cur > 10 then cur = 10 end
        end
        if self._cache[key] ~= cur then
            self._cache[key] = cur
            if IHM_LiveConfig then IHM_LiveConfig:updateAndSave(key, cur) end
            if lbl then
                if fmtFn then lbl.name = fmtFn(cur) else lbl.name = tostring(cur) end
            end
        end
    end

    sync("modal_rows", function(v) return tostring(v) end)
    sync("modal_cols", function(v) return tostring(v) end)
    sync("avatar_size", function(v) return tostring(v) .. " (" .. (32 + ((v - 1) * 16)) .. "px)" end)
end

function IHM_GridControlsWindow:close()
    -- Clear back-reference on the owner if it points to this window
    if self.owner and self.owner._controlsWin == self then
        self.owner._controlsWin = nil
    end
    self:setVisible(false)
    self:removeFromUIManager()
end

-- Static opener
function IHM_GridControlsWindow.open(owner, opts)
    local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
    local W, H = 420, 170
    local x = math.floor((sw - W) / 2)
    local y = math.floor((sh - H) / 2)
    local win = IHM_GridControlsWindow:new(x, y, W, H, owner, opts)
    win:initialise()
    win:addToUIManager()
    win:setVisible(true)
    if win.setAlwaysOnTop then win:setAlwaysOnTop(true) else win:bringToTop() end
    return win
end