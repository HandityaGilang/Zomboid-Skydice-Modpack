--[[
	Replace the original hair/beard combos with our modal grid menus.

	Highlights:
	- Modal-only hair/beard panels.
	- Top-right cluster inside each panel: [CONTROLS] [Stubble] [Color].
	- Live slider changes (rows/cols/avatar size) via IHM_LiveConfig.
	- Robust rebuild: no nil-calls, modal remains open & focused.
	- Color picker capture to avoid click-through.

	All comments are in English.
]]
if isServer() then return end
require "improvedhairmenu/InGame/IHM_GridControls"
do
    local LC = rawget(_G, "IHM_LiveConfig")
    if LC and (LC.cache.use_modal == nil or LC.cache.use_modal == false) then
        pcall(function() LC:updateAndSave("use_modal", true) end)
    end
end
local _ok = pcall(require, "improvedhairmenu/ModOptions")
local FONT_HGT_SMALL  = getTextManager():getFontHeight(UIFont.Small)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)

local function is_low_res()
	-- Vanilla convention; ensure menus stay modal on small screens.
	return (getCore():getScreenHeight() <= 900)
end

-- ======== SMALL UTILITIES =====================================================
local function _clampInt(v, lo, hi)
    v = tonumber(v) or lo
    if v < lo then return lo end
    if v > hi then return hi end
    return math.floor(v + 0.5)
end

local function _avatarPxFromStep(n) -- 1..7 -> 32..128 (step 16)
    n = _clampInt(n or 5, 1, 7)
    return 32 + ((n - 1) * 16)
end

-- Read a live value (IHM_LiveConfig first, then ImprovedHairMenu.settings)
local function _getLive(key, default)
    -- 1) live session values from IHM_LiveConfig (sliders / IHM_live.ini)
    local LC = rawget(_G, "IHM_LiveConfig")
    if LC and LC.cache and LC.cache[key] ~= nil then
        return LC.cache[key]
    end
    -- 2) fallback to persisted settings
    local S = ImprovedHairMenu and ImprovedHairMenu.settings
    if S and S[key] ~= nil then
        return S[key]
    end
    return default
end

-- Live settings resolver (NO refreshFromPZAPI; trust the live values)
local function _resolveSettings(isBeard)
    -- Immer modal: verhindert, dass der Inline-Panel-Ersatz den Button verdrängt
    local use_modal = true

    -- Avatar size from live "avatar_size" step (1..7) -> pixels.
    local avatar_px = _avatarPxFromStep(_getLive("avatar_size", 5))

    -- Wir steuern beide (Hair/Beard) mit denselben Grid-Werten.
    local rows = _clampInt(_getLive("modal_rows", 8), 1, 10)
    local cols = _clampInt(_getLive("modal_cols", 6), 1, 10)

    return use_modal, avatar_px, { rows = rows, cols = cols }
end

-- Bridge: make sure live writes also touch ImprovedHairMenu.settings (if present)
do
	local LC = rawget(_G, "IHM_LiveConfig")
	if LC and not LC._ihm_bridge_patched then
		local orig = LC.updateAndSave
		LC.updateAndSave = function(self, key, val)
			if ImprovedHairMenu and ImprovedHairMenu.settings then
				ImprovedHairMenu.settings[key] = val
			end
			if orig then return orig(self, key, val) end
		end
		LC._ihm_bridge_patched = true
	end
end

-- Returns the *equipped* display name for hair/beard (never nil)
local function _IHM_getEquippedDisplayName(isBeard)
    local desc = MainScreen.instance and MainScreen.instance.desc
    if not desc then return "" end
    local hv  = desc:getHumanVisual()
    local id  = isBeard and hv:getBeardModel() or hv:getHairModel()
    if not id or id == "" then
        return isBeard and getText("IGUI_Beard_None") or getText("IGUI_Hair_None")
    end
    local key = (isBeard and "IGUI_Beard_" or "IGUI_Hair_") .. id
    local txt = getText(key)
    -- getText returns the key itself if missing – guard that:
    if txt == key then
        return (isBeard and "Beard " or "Hair ") .. tostring(id)
    end
    return txt or ""
end

-- ======== LIST BUILDING + POST INIT ==========================================
-- Build the display list (Hair/Beard) with getter/setter names so VisualAvatar can apply models.
local function _IHM_buildListFromGame(desc, isBeard)
    local out = {}
    if not desc then return out end

    local function push(id, disp, getter, setter)
        out[#out+1] = { id = id, display = disp or id, selected = false, getterName = getter, setterName = setter }
    end

    if isBeard then
        local styles = getAllBeardStyles()
        if styles and styles.size then
            for i = 1, styles:size() do
                local id   = styles:get(i-1)
                local disp = (id == "" and getText("IGUI_Beard_None")) or getText("IGUI_Beard_" .. id) or id
                push(id, disp, "getBeardModel", "setBeardModel")
            end
        end
    else
        local female = desc:isFemale()
        local styles = getAllHairStyles(female)
        if styles and styles.size then
            for i = 1, styles:size() do
                local id = styles:get(i-1)
                local label
                if id == "" then label = getText("IGUI_Hair_Bald")
                else label = getText("IGUI_Hair_" .. id) or id end
                local hs = female and getHairStylesInstance():FindFemaleStyle(id) or getHairStylesInstance():FindMaleStyle(id)
                if not hs or not hs:isNoChoose() then
                    push(id, label, "getHairModel", "setHairModel")
                end
            end
        end
    end
    return out
end

-- Desc -> list -> select current -> visuals
local function _IHM_postInitPanel(self, panel, isBeard)
    if not panel then return end
    local desc = MainScreen.instance and MainScreen.instance.desc
    if panel.setDesc then panel:setDesc(desc) end

    local list = _IHM_buildListFromGame(desc, isBeard)
    if panel.setHairList then panel:setHairList(list) end

    -- Mark current selection
    if desc and #list > 0 and panel.setSelectedInfo then
        local hv = desc:getHumanVisual()
        local current = isBeard and hv:getBeardModel() or hv:getHairModel()
        local idx = 1
        for i = 1, #list do if list[i].id == current then idx = i break end end
        panel:setSelectedInfo(list[idx])
    end

    if panel.applyVisual then panel:applyVisual(desc) end
	 if not panel.onSelect then
        panel.onSelect = function(info)
            local desc = MainScreen.instance and MainScreen.instance.desc
            if not desc then return end
            if info and info.id then
                local hv = desc:getHumanVisual()
                if isBeard then hv:setBeardModel(info.id) else hv:setHairModel(info.id) end
            end

            -- Header- oder Main-Avatar aktualisieren
            local avatarPanel =
                (CharacterCreationHeader and CharacterCreationHeader.instance and CharacterCreationHeader.instance.avatarPanel)
                or
                (CharacterCreationMain and CharacterCreationMain.instance and CharacterCreationMain.instance.avatarPanel)

            if avatarPanel and avatarPanel.setSurvivorDesc then
                avatarPanel:setSurvivorDesc(desc)
            end
            if self.disableBtn then self:disableBtn() end
        end
    end
end

-- ======== TOP-RIGHT CLUSTER (CONTROLS / STUBBLE / COLOR) =====================
local function _IHM_layoutTopRightControls(panel)
    if not panel then return end
    local pad   = 8
    local gap   = 6
    local y     = math.floor(FONT_HGT_SMALL / 2)
    local right = panel:getWidth() - pad

    -- Color button (rightmost)
    local colorBtn = panel.hairColorBtn
    if colorBtn then
        local bw = colorBtn:getWidth()
        colorBtn:setX(right - bw)
        colorBtn:setY(y)
        right = right - bw - gap
    end

    -- Stubble to the left of color
    local stubble = panel.stubbleTickBox
    if stubble then
        local stbW = (stubble.getWidth and stubble:getWidth()) or (FONT_HGT_SMALL - 2)
        stubble:setX(right - stbW)
        stubble:setY(y)
        right = right - stbW - gap
    end

    -- Controls to the left of stubble (supports hairControlsBtn or beardControlsBtn)
    local ctrl = panel.hairControlsBtn or panel.beardControlsBtn
    if ctrl then
        local cw = ctrl:getWidth()
        ctrl:setX(math.max(pad, right - cw))
        ctrl:setY(y - 1) -- slight visual nudge
    end
end

-- Close the grid controls window if it's open (supports several patterns).
local function _IHM_closeControls(self)
    local W = rawget(_G, "IHM_GridControlsWindow")
    -- 1) Known singleton instance
    if W and W.instance and W.instance.close then
        pcall(function() W.instance:close() end)
    end
    -- 2) getInstance() pattern
    if W and W.getInstance then
        local inst = nil
        pcall(function() inst = W:getInstance() end)
        if inst and inst.close then pcall(function() inst:close() end) end
    end
    -- 3) stored on 'self' when we opened it
    if self and self._ihmControlsWindow and self._ihmControlsWindow.close then
        pcall(function() self._ihmControlsWindow:close() end)
        self._ihmControlsWindow = nil
    end
    -- 4) optional bulk close
    if W and W.closeAll then pcall(function() W:closeAll() end) end
end

-- Computes required min width so header text won't overlap right-side mini controls
local function _IHM_minPanelWidth(panel)
    if not panel then return 260 end
    local tm   = getTextManager()
    local font = UIFont.Small

    -- Left fixed bits: arrows + spacing + "page/total"
    local leftStart = (panel.pageRightButton and panel.pageRightButton:getRight() or 30) + 10
    local pages     = tostring(panel.pageCurrent or 1) .. "/" ..
                      tostring((panel.getNumberOfPages and panel:getNumberOfPages()) or 1)
    local pagesW    = tm:MeasureStringX(font, pages)

    -- Equipped title (hair/beard) – this is what the header actually shows
    local equipped  = _IHM_getEquippedDisplayName(panel.isBeard)
    local titleW    = tm:MeasureStringX(font, equipped)

    -- Right-side mini controls currently attached to the panel
    local rightW = 0
    local pad    = 8
    local ctrl   = panel.hairControlsBtn or panel.beardControlsBtn
    if panel.stubbleTickBox then rightW = rightW + panel.stubbleTickBox:getWidth() + pad end
    if panel.hairColorBtn   then rightW = rightW + panel.hairColorBtn:getWidth()   + pad end
    if ctrl                 then rightW = rightW + ctrl:getWidth()                 + pad end

    -- 40 = our fixed width we reserve after the page label
    -- +10 paddings on both sides
    local required = leftStart + pagesW + 40 + titleW + 10 + rightW + 10
    return math.max(260, math.floor(required))
end

-- Clamp rows/cols/avatar to fit on screen; return clamped values + minPanelW
local function _IHM_fitGridToScreen(avatar_px, rows, cols, boundsW, boundsH)
    local screenW = boundsW or getCore():getScreenWidth()
    local screenH = boundsH or getCore():getScreenHeight()
    local maxW = math.max(320, screenW - 80)
    local maxH = math.max(240, screenH - 120)

    -- conservative layout estimate for panel size
    local cellPad = 10
    local sidePad = 16
    local topPad  = 40  -- titlebar etc.
    local function estimateWH(a, r, c)
        local w = c * (a + cellPad) + sidePad * 2
        local h = r * (a + cellPad) + topPad + sidePad
        return w, h
    end

    local w, h = estimateWH(avatar_px, rows, cols)
    -- shrink columns first to fit width
    while w > maxW and cols > 1 do
        cols = cols - 1
        w, h = estimateWH(avatar_px, rows, cols)
    end
    -- then shrink rows to fit height
    while h > maxH and rows > 1 do
        rows = rows - 1
        w, h = estimateWH(avatar_px, rows, cols)
    end
    -- if still too big with 1x1, reduce avatar size stepwise
    while (w > maxW or h > maxH) and avatar_px > 32 do
        avatar_px = avatar_px - 16
        w, h = estimateWH(avatar_px, rows, cols)
    end

    -- minimal width so the top-right cluster & titlebar are always usable
    local minPanelW = math.min(maxW, _IHM_minPanelWidth())
    return avatar_px, rows, cols, minPanelW
end

local _IHM_rebuildMenu
-- Ensure the in-panel CONTROLS button exists (works for hair and beard).
-- isBeard = false for hair panel, true for beard panel.
local function _IHM_ensureControlsButton(self, panel, isBeard)
    if not panel then return end

    local ctrlLbl   = (getText and getText("CONTROLS")) or "Controls"
    local measured  = getTextManager():MeasureStringX(UIFont.Small, ctrlLbl)
    local ctrlW     = math.min(78, math.max(54, measured + 12)) -- compact but readable
    local ctrlH     = FONT_HGT_SMALL + 2
    local propName  = isBeard and "beardControlsBtn" or "hairControlsBtn"

    if not panel[propName] then
        local btn = ISButton:new(0, 0, ctrlW, ctrlH, ctrlLbl, self, function()
			local win = IHM_GridControlsWindow.open(self, {
				onChange = function()
					-- keep modal open while rebuilding
					self._IHM_suppressScrimClose = true
					if _IHM_rebuildMenu then
						_IHM_rebuildMenu(self, false)  -- Hair
						_IHM_rebuildMenu(self, true)   -- Beard
					end
					self._IHM_suppressScrimClose = false
					if self.hairMenu  then _IHM_layoutTopRightControls(self.hairMenu)  end
					if self.beardMenu then _IHM_layoutTopRightControls(self.beardMenu) end
				end
			})
			-- remember controls window (if open() returns one)
			if win ~= nil then self._ihmControlsWindow = win end
		end)
        btn:initialise(); btn:instantiate()
        if btn.setBorderRGBA then btn:setBorderRGBA(0.3,0.3,0.3,0.9) end
        btn:setDisplayBackground(true)
        btn:setBackgroundRGBA(0,0,0,0.15)

        panel:addChild(btn)
        panel[propName] = btn
    else
        local btn = panel[propName]
        btn:setWidth(ctrlW); btn:setHeight(ctrlH)
        panel:addChild(btn) -- re-parent on rebuild
    end

    _IHM_layoutTopRightControls(panel)
end

-- ======== REBUILD (MODAL-ONLY) ===============================================
function _IHM_rebuildMenu(self, isBeard)
    local _, avatar_px, ms = _resolveSettings(isBeard)
    local pw, ph = self:getWidth(), self:getHeight()
	avatar_px, ms.rows, ms.cols, _IHM_minW = _IHM_fitGridToScreen(avatar_px, ms.rows, ms.cols, pw, ph)

    local panelKey  = isBeard and "beardMenu" or "hairMenu"
    local buttonKey = isBeard and "beardMenuButton" or "hairMenuButton"
    local scrimKey  = isBeard and "beardMenuScrim" or "hairMenuScrim"

    local old = self[panelKey]
    local btn = self[buttonKey]
    local modalOpen = (self[scrimKey] ~= nil) or (btn and btn.expanded)

	local oldOnSelect = old and old.onSelect or nil
    local oldOnClose = old and old.onClose or nil
    local oldColor   = old and old.hairColorBtn or nil
    local oldStubble = old and old.stubbleTickBox or nil
    local oldCtrl    = old and (old.hairControlsBtn or old.beardControlsBtn) or nil

    if old then
        if oldColor   then old:removeChild(oldColor)   end
        if oldStubble then old:removeChild(oldStubble) end
        if oldCtrl    then old:removeChild(oldCtrl)    end
        pcall(function() self:removeChild(old) end)
    end

   local panelType = rawget(_G, "HairMenuPanelModal")
    if not panelType then
        pcall(require, "improvedhairmenu/HairMenuPanelModal")
        panelType = rawget(_G, "HairMenuPanelModal")
    end
    if not panelType then
        pcall(require, "improvedhairmenu/HairMenuPanel")
        panelType = rawget(_G, "HairMenuPanel")
    end
    if not panelType then
        print("[IHM] _IHM_rebuildMenu: No HairMenuPanelModal/HairMenuPanel available; aborting rebuild.")
        return
    end

    local newPanel = panelType:new(0, 0, avatar_px, avatar_px, ms.rows, ms.cols, 3, isBeard)
    newPanel:initialise()
    _IHM_postInitPanel(self, newPanel, isBeard)
	if oldOnSelect then newPanel.onSelect = oldOnSelect end

    -- Reattach mini-controls
    if oldColor   then newPanel:addChild(oldColor);   newPanel.hairColorBtn   = oldColor   end
    if oldStubble then newPanel:addChild(oldStubble); newPanel.stubbleTickBox = oldStubble end
    if oldCtrl    then
        newPanel:addChild(oldCtrl)
        if isBeard then newPanel.beardControlsBtn = oldCtrl else newPanel.hairControlsBtn = oldCtrl end
    else
        _IHM_ensureControlsButton(self, newPanel, isBeard)
    end

    if oldOnClose then newPanel.onClose = oldOnClose end
    self[panelKey] = newPanel
    if btn then btn.attachedMenu = newPanel end

    -- -------- width clamp incl. equipped title + right cluster, then center grid
    do
        local sw   = getCore():getScreenWidth()
        local maxW = math.max(320, sw - 80)
        local w0   = newPanel:getWidth()

        local pad, gap = 8, 6
        local tm, font = getTextManager(), UIFont.Small

        local arrowsW = 0
        if newPanel.pageLeftButton  then arrowsW = arrowsW + newPanel.pageLeftButton:getWidth()  end
        if newPanel.pageRightButton then arrowsW = arrowsW + newPanel.pageRightButton:getWidth() end
        local pagesStr = tostring(newPanel.pageCurrent or 1) .. "/" ..
                         tostring((newPanel.getNumberOfPages and newPanel:getNumberOfPages()) or 1)
        local pagesW   = tm:MeasureStringX(font, pagesStr)

        local disp = _IHM_getEquippedDisplayName(isBeard) or ""
        local titleW    = tm:MeasureStringX(font, disp)

        local leftW = pad + arrowsW + gap + pagesW + gap + titleW + pad

        local rightW = pad
        local ctrl = newPanel.hairControlsBtn or newPanel.beardControlsBtn
        if ctrl                 then rightW = rightW + ctrl:getWidth()                 + gap end
        if newPanel.stubbleTickBox then rightW = rightW + newPanel.stubbleTickBox:getWidth() + gap end
        if newPanel.hairColorBtn   then rightW = rightW + newPanel.hairColorBtn:getWidth()   + gap end
        rightW = rightW + pad

        local minHeaderW = leftW + rightW

        local minGeneric = _IHM_minW or 260
        local targetW    = math.min(maxW, math.max(w0, minGeneric, minHeaderW)) + 8 

        if targetW ~= w0 and newPanel.setWidth then
            newPanel:setWidth(targetW)
        end

        local gridW = (newPanel.gridCols * newPanel.gridSizeX) + (newPanel.gap * (newPanel.gridCols - 1))
        local left  = math.max(8, math.floor((newPanel:getWidth() - gridW) / 2))

        if newPanel.avatarList then
            for i = 1, #newPanel.avatarList do
                local av = newPanel.avatarList[i]
                if av then
                    local col = ((i - 1) % newPanel.gridCols) + 1
                    local x   = left + (col - 1) * (newPanel.gridSizeX + newPanel.gap)
                    av:setX(x)
                end
            end
        end
    end
    -- ---------------------------------------------------------------------------

    if modalOpen then
        -- Keep it open and centered; keep button expanded & focus
        self:addChild(newPanel)
        newPanel:setX((self:getWidth()  / 2) - (newPanel:getWidth()  / 2))
        newPanel:setY((self:getHeight() / 2) - (newPanel:getHeight() / 2))
        if newPanel.bringToTop then newPanel:bringToTop() end
        if btn then btn.expanded = true end
        if newPanel.setJoypadFocused then newPanel:setJoypadFocused(true, nil) end
    end

    _IHM_layoutTopRightControls(newPanel)
end

-- ======== COLOR PICKER: APPLY TO BOTH GRIDS ==================================
local _IHM_onHairColorPicked = CharacterCreationMain.onHairColorPicked
function CharacterCreationMain:onHairColorPicked(color, mouseUp)
    _IHM_onHairColorPicked(self, color, mouseUp)

    local desc = MainScreen.instance and MainScreen.instance.desc
    if not desc then return end

    local header = CharacterCreationHeader and CharacterCreationHeader.instance
    if header and header.avatarPanel and header.avatarPanel.setSurvivorDesc then
        header.avatarPanel:setSurvivorDesc(desc)
    end

    local function refreshGrid(panel)
        if not panel then return end
        if panel.setDesc then panel:setDesc(desc) end
        if panel.applyVisual then panel:applyVisual(desc) end
    end

    refreshGrid(self.hairMenu)
    refreshGrid(self.beardMenu)

    if self.disableBtn then self:disableBtn() end
end

--################################################################################
--## Hair Styles (modal only)                                                    ##
--################################################################################
function CharacterCreationMain:createHairTypeBtn()
    local use_modal, avatar_size, menu_size = _resolveSettings(false)
    local comboHgt = getTextManager():getFontHeight(UIFont.Small) + 3 * 2

    local x0 = self.xOffset or 0
    local w0 = self.comboWid or 0

    -- Header + divider
    local lbl = ISLabel:new(
        x0, self.yOffset,
        getTextManager():getFontHeight(UIFont.Medium),
        getText("UI_characreation_hair"),
        1,1,1,1, UIFont.Medium, true
    )
    lbl:initialise(); lbl:instantiate()
    self.characterPanel:addChild(lbl)

    local rect = ISRect:new(
        x0,
        self.yOffset + getTextManager():getFontHeight(UIFont.Medium) + 5,
        300, 1, 1, 0.3, 0.3, 0.3
    )
    rect:setAnchorRight(false)
    rect:initialise(); rect:instantiate()
    self.characterPanel:addChild(rect)

    self.yOffset = self.yOffset + getTextManager():getFontHeight(UIFont.Medium) + 15

    -- Keep the vanilla combobox invisible for compatibility.
    self.hairTypeCombo = ISComboBox:new(
        x0 + 90, self.yOffset, w0, comboHgt,
        self, CharacterCreationMain.onHairTypeSelected
    )
    self.hairTypeCombo:initialise()
    self.characterPanel:addChild(self.hairTypeCombo)
    self.hairTypeCombo:setVisible(false)
    self.hairType = 0

    -- Modal hair panel
    local panelType = rawget(_G, "HairMenuPanelModal")
    if not panelType then
        pcall(require, "improvedhairmenu/HairMenuPanelModal")
        panelType = rawget(_G, "HairMenuPanelModal")
    end
    if not panelType then
        pcall(require, "improvedhairmenu/HairMenuPanel")
        panelType = rawget(_G, "HairMenuPanel")
    end
    self.hairMenu = panelType:new(
        x0, self.yOffset,
        avatar_size, avatar_size,
        menu_size.rows, menu_size.cols, 3, false
    )
    self.hairMenu:initialise()
    _IHM_postInitPanel(self, self.hairMenu, false)

    -- Selection callback: update visual + header avatar, then close modal
    self.hairMenu.onSelect = function(info)
        local desc = MainScreen.instance and MainScreen.instance.desc
        if not desc then return end

        self.hairType = 1
        if info and info.id then
            desc:getHumanVisual():setHairModel(info.id)
        end

        -- Refresh header/main avatar preview
        local avatarPanel =
            (CharacterCreationHeader and CharacterCreationHeader.instance and CharacterCreationHeader.instance.avatarPanel)
            or
            (CharacterCreationMain and CharacterCreationMain.instance and CharacterCreationMain.instance.avatarPanel)

        if avatarPanel and avatarPanel.setSurvivorDesc then
            avatarPanel:setSurvivorDesc(desc)
        end

        if self.disableBtn then self:disableBtn() end

        -- NEW: Close the preview modal after a successful selection
        if self.hairMenu and self.hairMenu.onClose then
            self.hairMenu:onClose()
        end
    end

    if use_modal then
        -- Modal open/close; scrim ignores mouse-up while we rebuild via sliders.
        local function makeScrim(parent, closeFn)
            local scrim = ISPanel:new(0, 0, parent:getWidth(), parent:getHeight())
            scrim:initialise(); scrim:instantiate()
            scrim.background = true
            scrim.backgroundColor = { r=0, g=0, b=0, a=0 }
            scrim:setAnchorRight(true); scrim:setAnchorBottom(true)
            function scrim:onMouseDown(...)      return true end
            function scrim:onRightMouseDown(...) return true end
            function scrim:onMouseUp(...)
                if parent._IHM_suppressScrimClose then return true end
                closeFn(); return true
            end
            function scrim:onRightMouseUp(...)
                if parent._IHM_suppressScrimClose then return true end
                closeFn(); return true
            end
            return scrim
        end

        local function showMenu(target)
            -- (1) Create scrim
            target.hairMenuScrim = makeScrim(target, function()
                if target.hairMenu and target.hairMenu.onClose then target.hairMenu:onClose() end
            end)
            target:addChild(target.hairMenuScrim)

            -- (2) Live rebuild so slider changes take effect
            _IHM_rebuildMenu(target, false)

            -- (3) Modal state/focus and center panel
            target.hairMenuButton.expanded = true
            if target.hairMenuButton.attachedMenu and target.hairMenuButton.attachedMenu.setJoypadFocused then
                target.hairMenuButton.attachedMenu:setJoypadFocused(true, nil)
            end

            -- (4) Ensure panel is parented and centered
            target:removeChild(target.hairMenu)
            target:addChild(target.hairMenu)
            target.hairMenu:setX((target:getWidth()  / 2) - (target.hairMenu:getWidth()  / 2))
            target.hairMenu:setY((target:getHeight() / 2) - (target.hairMenu:getHeight() / 2))

            -- (5) Place the top-right cluster
            _IHM_layoutTopRightControls(target.hairMenu)
        end

        self.hairMenu.onClose = function()
            self:removeChild(self.hairMenu)
            if self.hairMenuScrim then
                self:removeChild(self.hairMenuScrim)
                self.hairMenuScrim = nil
            end
            if self.hairMenuButton then
                self.hairMenuButton.expanded = false
                self.hairMenuButton.attachedMenu:setJoypadFocused(false, nil)
            end
            _IHM_closeControls(self)
        end

        -- Single "Open" button (no Controls button next to it)
        self.hairMenuButton = ISButton:new(
            x0, self.yOffset,
            90, getTextManager():getFontHeight(UIFont.Small)*2,
            getText("IGUI_Open"), self, showMenu
        )
        self.hairMenuButton:initialise(); self.hairMenuButton:instantiate()
        self.hairMenuButton.isHairMenuButton = true
        self.hairMenuButton.isButton = nil
        self.hairMenuButton.expanded = false
        self.hairMenuButton.attachedMenu = self.hairMenu

        local setJoypadFocused = self.hairMenuButton.setJoypadFocused
        self.hairMenuButton.setJoypadFocused = function(btn, focused, joypadData)
            btn.focused = focused
            if btn.expanded then
                btn.attachedMenu:setJoypadFocused(focused, joypadData)
            else
                btn.attachedMenu:setJoypadFocused(false, joypadData)
            end
            setJoypadFocused(btn, focused, joypadData)
        end

        self.characterPanel:addChild(self.hairMenuButton)
        self.yOffset = self.yOffset + self.hairMenuButton:getHeight() + 5
    else
        -- Inline fallback (kept for safety)
        self.characterPanel:addChild(self.hairMenu)
        self.yOffset = self.yOffset + self.hairMenu:getHeight() + 5
    end

    -- Hair color presets
    local hairColors = MainScreen.instance.desc:getCommonHairColor()
    local hairColors1, info = {}, ColorInfo.new()
    for i = 1, hairColors:size() do
        local c = hairColors:get(i-1)
        info:set(c:getRedFloat(), c:getGreenFloat(), c:getBlueFloat(), 1)
        table.insert(hairColors1, { r=info:getR(), g=info:getG(), b=info:getB() })
    end

    -- Hair color button (top-right, on the panel)
    local hairColorBtn = ISButton:new(0, 0, 40, FONT_HGT_SMALL, "", self, CharacterCreationMain.onHairColorMouseDown)
    hairColorBtn:initialise(); hairColorBtn:instantiate()
    local color = hairColors1[1]
    hairColorBtn.backgroundColor = { r=color.r, g=color.g, b=color.b, a=1 }
    self.hairMenu:addChild(hairColorBtn)
    self.hairMenu.hairColorBtn = hairColorBtn
    self.hairColorButton = hairColorBtn

    -- Color picker (kept off-screen until used)
    self.colorPickerHair = ISColorPicker:new(0, 0, nil)
    self.colorPickerHair:initialise()
    self.colorPickerHair.keepOnScreen = true
    self.colorPickerHair.pickedTarget = self
    self.colorPickerHair.resetFocusTo = self.characterPanel
    self.colorPickerHair:setColors(hairColors1, math.min(#hairColors1, 10), math.ceil(#hairColors1/10))
    local _picked  = self.colorPickerHair.picked
    function self.colorPickerHair:picked(hide)  _picked(self, hide) end
    local _picked2 = self.colorPickerHair.picked2
    function self.colorPickerHair:picked2(hide) _picked2(self, hide) end

    -- Stubble toggle lives on the hair panel (top-right)
    local stLblH = FONT_HGT_SMALL
    self.hairStubbleLbl = ISLabel:new(x0, self.yOffset + stLblH, comboHgt, getText("UI_Stubble"), 1,1,1,1, UIFont.Small)
    self.hairStubbleLbl:initialise(); self.hairStubbleLbl:instantiate()
    self.characterPanel:addChild(self.hairStubbleLbl)

    self.hairStubbleTickBox = ISTickBox:new(0, 0, stLblH-2, stLblH-2, "", self, CharacterCreationMain.onShavedHairSelected)
    self.hairStubbleTickBox:initialise()
    self.hairStubbleTickBox:addOption("")
    self.hairStubbleTickBox.tooltip = getText("UI_Stubble")
    self.hairMenu:addChild(self.hairStubbleTickBox)
    self.hairMenu.stubbleTickBox = self.hairStubbleTickBox

    -- Controls button + layout cluster
    _IHM_ensureControlsButton(self, self.hairMenu, false)
    _IHM_layoutTopRightControls(self.hairMenu)
end

-- Color picker mouse capture to prevent click-through on tiles
local base_CharacterCreationMain_onHairColorMouseDown = CharacterCreationMain.onHairColorMouseDown
function CharacterCreationMain:onHairColorMouseDown(button, x, y)
	base_CharacterCreationMain_onHairColorMouseDown(self, button, x, y)
	self.colorPickerHair:setCapture(true)
end

--################################################################################
--## Beard Styles (modal only)                                                   ##
--################################################################################
function CharacterCreationMain:createBeardTypeBtn()
    local use_modal, avatar_size, menu_size = _resolveSettings(true)
    local comboHgt = getTextManager():getFontHeight(UIFont.Small) + 3 * 2

    local x0 = self.xOffset or 0
    local w0 = self.comboWid or 0

    -- Invisible vanilla scaffolding
    self.beardLbl = ISLabel:new(
        x0, self.yOffset,
        getTextManager():getFontHeight(UIFont.Medium),
        getText("UI_characreation_beard"),
        1,1,1,1, UIFont.Medium, true
    )
    self.beardLbl:initialise(); self.beardLbl:instantiate(); self.beardLbl:setVisible(false)
    self.characterPanel:addChild(self.beardLbl)

    self.beardRect = ISRect:new(
        x0,
        self.yOffset + getTextManager():getFontHeight(UIFont.Medium) + 5,
        300, 1, 1, 0.3, 0.3, 0.3
    )
    self.beardRect:setAnchorRight(false)
    self.beardRect:initialise(); self.beardRect:instantiate(); self.beardRect:setVisible(false)
    self.characterPanel:addChild(self.beardRect)

    self.yOffset = self.yOffset + getTextManager():getFontHeight(UIFont.Medium) + 15

    self.beardTypeLbl = ISLabel:new(x0 + 70, self.yOffset, comboHgt, getText("UI_characreation_beardtype"), 1,1,1,1, UIFont.Small)
    self.beardTypeLbl:initialise(); self.beardTypeLbl:instantiate(); self.beardTypeLbl:setVisible(false)
    self.characterPanel:addChild(self.beardTypeLbl)

    self.beardTypeCombo = ISComboBox:new(
        x0 + 90, self.yOffset, w0, comboHgt,
        self, CharacterCreationMain.onBeardTypeSelected
    )
    self.beardTypeCombo:initialise()
    self.beardTypeCombo:setVisible(false)
    self.characterPanel:addChild(self.beardTypeCombo)

    -- Modal-only beard panel
    local panelType = rawget(_G, "HairMenuPanelModal")
    if not panelType then
        pcall(require, "improvedhairmenu/HairMenuPanelModal")
        panelType = rawget(_G, "HairMenuPanelModal")
    end
    if not panelType then
        pcall(require, "improvedhairmenu/HairMenuPanel")
        panelType = rawget(_G, "HairMenuPanel")
    end
    self.beardMenu = panelType:new(
        x0, self.yOffset,
        avatar_size, avatar_size,
        menu_size.rows, menu_size.cols, 3, true
    )
    self.beardMenu:initialise()
    _IHM_postInitPanel(self, self.beardMenu, true)

    -- Selection callback: update visual + header avatar, then close modal
    self.beardMenu.onSelect = function(info)
        local desc = MainScreen.instance and MainScreen.instance.desc
        if not desc then return end

        if info and info.id then
            desc:getHumanVisual():setBeardModel(info.id)
        end

        local avatarPanel =
            (CharacterCreationHeader and CharacterCreationHeader.instance and CharacterCreationHeader.instance.avatarPanel)
            or
            (CharacterCreationMain and CharacterCreationMain.instance and CharacterCreationMain.instance.avatarPanel)

        if avatarPanel and avatarPanel.setSurvivorDesc then
            avatarPanel:setSurvivorDesc(desc)
        end

        if self.disableBtn then self:disableBtn() end

        -- NEW: Close the preview modal after a successful selection
        if self.beardMenu and self.beardMenu.onClose then
            self.beardMenu:onClose()
        end
    end

    if use_modal then
        local function makeScrim(parent, closeFn)
            local scrim = ISPanel:new(0, 0, parent:getWidth(), parent:getHeight())
            scrim:initialise(); scrim:instantiate()
            scrim.background = true
            scrim.backgroundColor = { r=0, g=0, b=0, a=0 }
            scrim:setAnchorRight(true); scrim:setAnchorBottom(true)
            function scrim:onMouseDown(...)      return true end
            function scrim:onRightMouseDown(...) return true end
            function scrim:onMouseUp(...)
                if parent._IHM_suppressScrimClose then return true end
                closeFn(); return true
            end
            function scrim:onRightMouseUp(...)
                if parent._IHM_suppressScrimClose then return true end
                closeFn(); return true
            end
            return scrim
        end

        local function showMenu(target)
            -- (1) Create scrim
            target.beardMenuScrim = makeScrim(target, function()
                if target.beardMenu and target.beardMenu.onClose then target.beardMenu:onClose() end
            end)
            target:addChild(target.beardMenuScrim)

            -- (2) Live rebuild so slider changes take effect
            _IHM_rebuildMenu(target, true)

            -- (3) Modal state/focus and center panel
            target.beardMenuButton.expanded = true
            if target.beardMenuButton.attachedMenu and target.beardMenuButton.attachedMenu.setJoypadFocused then
                target.beardMenuButton.attachedMenu:setJoypadFocused(true, nil)
            end

            -- (4) Ensure panel is parented and centered
            target:removeChild(target.beardMenu)
            target:addChild(target.beardMenu)
            target.beardMenu:setX((target:getWidth()  / 2) - (target.beardMenu:getWidth()  / 2))
            target.beardMenu:setY((target:getHeight() / 2) - (target.beardMenu:getHeight() / 2))

            -- (5) Place the top-right cluster
            _IHM_layoutTopRightControls(target.beardMenu)
        end

        self.beardMenu.onClose = function()
            self:removeChild(self.beardMenu)
            if self.beardMenuScrim then
                self:removeChild(self.beardMenuScrim)
                self.beardMenuScrim = nil
            end
            if self.beardMenuButton then
                self.beardMenuButton.expanded = false
                self.beardMenuButton.attachedMenu:setJoypadFocused(false, nil)
            end
            _IHM_closeControls(self)
        end

        -- Single "Open" button for beard
        self.beardMenuButton = ISButton:new(
            x0, self.yOffset,
            90, getTextManager():getFontHeight(UIFont.Small)*2,
            getText("IGUI_Open"), self, showMenu
        )
        self.beardMenuButton:initialise(); self.beardMenuButton:instantiate()
        self.beardMenuButton.isHairMenuButton = true
        self.beardMenuButton.isButton = nil
        self.beardMenuButton.expanded = false
        self.beardMenuButton.attachedMenu = self.beardMenu

        local setJoypadFocused = self.beardMenuButton.setJoypadFocused
        self.beardMenuButton.setJoypadFocused = function(btn, focused, joypadData)
            btn.focused = focused
            if btn.expanded then
                btn.attachedMenu:setJoypadFocused(focused, joypadData)
            else
                btn.attachedMenu:setJoypadFocused(false, joypadData)
            end
            setJoypadFocused(btn, focused, joypadData)
        end

        self.characterPanel:addChild(self.beardMenuButton)
        self.yOffset = self.yOffset + self.beardMenuButton:getHeight() + 5
    else
        self.characterPanel:addChild(self.beardMenu)
        self.yOffset = self.yOffset + self.beardMenu:getHeight() + 5
    end

    -- Stubble lives on the beard panel (top-right).
    local stLblH = FONT_HGT_SMALL
    self.beardStubbleLbl = ISLabel:new(x0 + 70, self.yOffset, comboHgt, getText("UI_Stubble"), 1,1,1,1, UIFont.Small)
    self.beardStubbleLbl:initialise(); self.beardStubbleLbl:instantiate()
    self.characterPanel:addChild(self.beardStubbleLbl)

    self.beardStubbleTickBox = ISTickBox:new(0, 0, stLblH-2, stLblH-2, "", self, CharacterCreationMain.onBeardStubbleSelected)
    self.beardStubbleTickBox:initialise()
    self.beardStubbleTickBox:addOption("")
    self.beardStubbleTickBox.tooltip = getText("UI_Stubble")
    self.beardMenu:addChild(self.beardStubbleTickBox)
    self.beardMenu.stubbleTickBox = self.beardStubbleTickBox

    -- Controls button + layout cluster
    _IHM_ensureControlsButton(self, self.beardMenu, true)
    _IHM_layoutTopRightControls(self.beardMenu)

    self.yOffset = self.yOffset + comboHgt + 10
end
