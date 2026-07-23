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

local function _IHM_resolutionScale()
    local h = getCore():getScreenHeight()
    return math.max(1.0, math.min(2.0, h / 1080))
end

local function _IHM_maxAvatarPxForBounds(rows, cols, boundsW, boundsH)
    local screenW = boundsW or getCore():getScreenWidth()
    local screenH = boundsH or getCore():getScreenHeight()

    local maxW = math.max(320, screenW - 80)
    local maxH = math.max(240, screenH - 120)

    local gap = 3
    local reserveW = 40
    local reserveH = 64

    local byW = math.floor((maxW - reserveW - (gap * math.max(0, cols - 1))) / math.max(1, cols))
    local byH = math.floor((maxH - reserveH - (gap * math.max(0, rows - 1))) / math.max(1, rows))

    return math.max(32, math.min(byW, byH))
end

local function _IHM_effectiveAvatarPx(step, rows, cols, boundsW, boundsH)
    local base = _avatarPxFromStep(step)
    local scaled = math.floor((base * _IHM_resolutionScale()) + 0.5)
    local maxAvatar = _IHM_maxAvatarPxForBounds(rows, cols, boundsW, boundsH)
    local effective = math.max(32, math.min(scaled, maxAvatar))
    return base, effective
end

local function _IHM_avatarSizeText(step, rows, cols, boundsW, boundsH)
    local base, effective = _IHM_effectiveAvatarPx(step, rows, cols, boundsW, boundsH)
    if effective ~= base then
        return tostring(step) .. " (" .. base .. "px -> " .. effective .. "px)"
    end
    return tostring(step) .. " (" .. base .. "px)"
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

    if IHM_LiveConfig and ImprovedHairMenu and ImprovedHairMenu.settings then
        pcall(function()
            IHM_LiveConfig:load()
            IHM_LiveConfig:applyToSettings(ImprovedHairMenu.settings)
        end)
    end

    local tm = getTextManager()
    local font = UIFont.Small
    local smallH = tm:getFontHeight(font)
    local pad = math.max(10, math.floor(smallH * 0.6))
    local gapY = math.max(8, math.floor(smallH * 0.5))
    local rowH = math.max(24, smallH + 8)

    local title = (getText and getText("CONTROLS")) or "Controls"
    self:setTitle(title)

    local rowsText = (getText and getText("IGUI_IHM_modal_rows")) or "Rows"
    local colsText = (getText and getText("IGUI_IHM_modal_cols")) or "Columns"
    local sizeText = (getText and getText("IGUI_IHM_avatar_size")) or "Avatar size"
    local closeText = (getText and getText("UI_Close")) or "Close"

    local S = ImprovedHairMenu and ImprovedHairMenu.settings or {}
    local rows = _clampInt((S.modal_rows or 8), 1, 10)
    local cols = _clampInt((S.modal_cols or 6), 1, 10)
    local asz = _clampInt((S.avatar_size or 5), 1, 7)

    self._sliders = {}
    self._labels = {}
    self._cache = { modal_rows = rows, modal_cols = cols, avatar_size = asz }

    local labelW = 0
    for _, txt in ipairs({ rowsText, colsText, sizeText }) do
        labelW = math.max(labelW, tm:MeasureStringX(font, txt))
    end
    labelW = labelW + 12

    local valueW = math.max(92, tm:MeasureStringX(font, "7 (128px -> 256px)") + 10)
    local sliderW = math.max(220, math.floor(getCore():getScreenWidth() * 0.18))
    local btnW = math.max(80, tm:MeasureStringX(font, closeText) + 20)
    local btnH = math.max(22, smallH + 8)

    local totalW = pad * 2 + labelW + sliderW + 6 + valueW
    local totalH = self:titleBarHeight() + pad + ((rowH + gapY) * 3) - gapY + gapY + btnH + pad
    self:setWidth(totalW)
    self:setHeight(totalH)

    local y = self:titleBarHeight() + pad

    local function addSliderRow(labelText, key, min, max, step, cur, fmtFn)
        local lbl = ISLabel:new(pad, y, rowH, labelText, 1, 1, 1, 1, font, true)
        lbl:initialise()
        lbl:instantiate()
        self:addChild(lbl)

        local valLbl = ISLabel:new(pad + labelW + sliderW + 6, y, rowH, "", 0.85, 0.85, 0.85, 1, font, true)
        valLbl:initialise()
        valLbl:instantiate()
        self:addChild(valLbl)

        local win = self
        local sl = ISSliderPanel:new(
            pad + labelW,
            y - 2,
            sliderW,
            rowH,
        function(_, value)
            local iv = _clampInt(value, min, max)
            if IHM_LiveConfig then IHM_LiveConfig:updateAndSave(key, iv) end
            win._cache[key] = iv
            valLbl.name = fmtFn and fmtFn(iv) or tostring(iv)

            if key == "modal_rows" or key == "modal_cols" then
                local aSl = win._sliders and win._sliders.avatar_size
                local aLbl = win._labels and win._labels.avatar_size
                if aSl and aLbl then
                    local av = _clampInt(aSl:getCurrentValue(), 1, 7)
                    aLbl.name = _IHM_avatarSizeText(
                        av,
                        win._cache.modal_rows or 8,
                        win._cache.modal_cols or 6
                    )
                end
            end
        end,
            nil
        )
        sl:initialise()
        sl:setDoButtons(true)
        sl:setValues(min, max, step, step, true)
        sl:setCurrentValue(cur, true)

        local baseOnMouseUp = sl.onMouseUp
        function sl:onMouseUp(...)
            if baseOnMouseUp then baseOnMouseUp(self, ...) end
            if win.opts and win.opts.onChange then win.opts.onChange() end
        end

        self:addChild(sl)

        valLbl.name = fmtFn and fmtFn(cur) or tostring(cur)
        self._sliders[key] = sl
        self._labels[key] = valLbl

        y = y + rowH + gapY
    end

    addSliderRow(rowsText, "modal_rows", 1, 10, 1, rows, function(v) return tostring(v) end)
    addSliderRow(colsText, "modal_cols", 1, 10, 1, cols, function(v) return tostring(v) end)
    addSliderRow(sizeText, "avatar_size", 1, 7, 1, asz, function(v)
        return _IHM_avatarSizeText(
            v,
            self._cache.modal_rows or rows,
            self._cache.modal_cols or cols
        )
    end)

    local closeBtn = ISButton:new(self:getWidth() - pad - btnW, self:getHeight() - pad - btnH, btnW, btnH, closeText, self, function()
        self:close()
    end)
    closeBtn:initialise()
    closeBtn:instantiate()
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
    sync("avatar_size", function(v)
    local aSl = self._sliders and self._sliders.avatar_size
    local aLbl = self._labels and self._labels.avatar_size
    if aSl and aLbl then
        local av = _clampInt(aSl:getCurrentValue(), 1, 7)
        aLbl.name = _IHM_avatarSizeText(
            av,
            self._cache.modal_rows or 8,
            self._cache.modal_cols or 6
        )
    end
        return _IHM_avatarSizeText(
            v,
            self._cache.modal_rows or 8,
            self._cache.modal_cols or 6
        )
    end)
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
    local win = IHM_GridControlsWindow:new(0, 0, 420, 170, owner, opts)
    win:initialise()
    win:setX(math.floor((sw - win:getWidth()) / 2))
    win:setY(math.floor((sh - win:getHeight()) / 2))
    win:addToUIManager()
    win:setVisible(true)
    if win.setAlwaysOnTop then win:setAlwaysOnTop(true) else win:bringToTop() end
    return win
end