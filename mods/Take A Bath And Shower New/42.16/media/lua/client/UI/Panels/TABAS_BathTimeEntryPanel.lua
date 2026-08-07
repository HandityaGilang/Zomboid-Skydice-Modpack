require("ISUI/ISPanelJoypad")

TABAS_BathTimeEntryPanel = ISPanelJoypad:derive("TABAS_BathTimeEntryPanel")

local TABAS_Utils = require("TABAS_Utils")
local TABAS_Panel = require("UI/TABAS_PanelUtils")

local CONST = require("UI/TABAS_PanelConst")
local FONT_HGT_SMALL = CONST.SCALE.HGT_SMALL
local BORDER_SPACING = CONST.SCALE.BORDER_SPACING
local HGT_BUTTON = CONST.SCALE.HGT_BUTTON

function TABAS_BathTimeEntryPanel:initialise()
    ISPanelJoypad.initialise(self)
end

function TABAS_BathTimeEntryPanel:createToggle(x, y, width, height, onToggled)
    local toggle = ISWidgetAutoToggle:new(x, y, width, height, false, self, onToggled)
    toggle:initialise()
    toggle.onMouseDown = function(widget, mouseX, mouseY)
        if self.interactionDisabled then
            return
        end
        return ISWidgetAutoToggle.onMouseDown(widget, mouseX, mouseY)
    end
    return toggle
end

function TABAS_BathTimeEntryPanel:createChildren()
	local btnScale = self.btnScale
	local x = BORDER_SPACING*2
	local y = FONT_HGT_SMALL + BORDER_SPACING*2
	local toggleY = self.btnScale + FONT_HGT_SMALL*1.2 + BORDER_SPACING*2
	local toggleH = FONT_HGT_SMALL * 1.2
	self.buttons = {}

	self.btnInfo = TABAS_Panel.addButton(BORDER_SPACING, BORDER_SPACING, FONT_HGT_SMALL, FONT_HGT_SMALL, self.tex_infoIcon, nil, getText("IGUI_TABAS_EntryConfigInfo"), self, nil, false)
	self.btnInfo.enable = false

	-- make off
	self.btnMakeOff = TABAS_Panel.addButton(x, y, btnScale, btnScale, self.tex_makeoff, nil, "", self, self.onClick, false)
	self.btnMakeOff.tooltipLabel = getText("UI_TABAS_WashOffMakeup")
	self.btnMakeOff.internal = "MAKEOFF"
	table.insert(self.buttons, self.btnMakeOff)

	self.tglMakeOff = self:createToggle(x, toggleY, btnScale, toggleH, self.onMakeOffToggled)
	self.tglMakeOff.value = self.modOptions:getOption("WashOffMakeup"):getValue()
	self:addChild(self.tglMakeOff)

	x = x + btnScale + BORDER_SPACING*2
	-- auto cloth change
	self.btnAutoCC = TABAS_Panel.addButton(x, y, btnScale, btnScale, self.tex_autoCC, nil, "", self, self.onClick, false)
	self.btnAutoCC.internal = "ACC"
	self.btnAutoCC.tooltipLabel = getText("UI_TABAS_AutoClothesChange")
	table.insert(self.buttons, self.btnAutoCC)

	self.tglAutoCC = self:createToggle(x, toggleY, btnScale, toggleH, self.onAutoCCToggled)
	self.tglAutoCC.value = self.modOptions:getOption("AutoClothesChange"):getValue()
	self:addChild(self.tglAutoCC)

	x = x + btnScale + BORDER_SPACING*2

	-- bath towel drop box
    self.bathtowelDropBox = ISItemDropBox:new (x, y, btnScale, btnScale, true, self, self.addItem, self.removeItem, self.verifyItem, nil )
    self.bathtowelDropBox.allowDropAlways = true
    self.bathtowelDropBox.onMouseDown = TABAS_BathTimeEntryPanel.clickedDropBox
    self.bathtowelDropBox:setToolTip(true, getText("IGUI_TABAS_BathTowelDropBoxTooltip"))
    self.bathtowelDropBox.player = self.playerObj
    self.bathtowelDropBox:initialise()
    self.bathtowelDropBox.background = false
    -- self.bathtowelDropBox.doHighlight = false
    self.bathtowelDropBox.doBackDropTex = true
    self.bathtowelDropBox.backgroundColorHL = {r=0, g=0, b=0, a=0}
    self.bathtowelDropBox.borderColorHL = {r=0, g=0, b=0, a=0}
    self.bathtowelDropBox:setBackDropTex(self.tex_towel, 0.8, 0.2,0.2,0.2)
    self.bathtowelDropBox.toolTipTextItem = getText("Fluid_Dropbox_Remove")
    self:addChild(self.bathtowelDropBox)
    if getJoypadData(self.playerObj:getPlayerNum()) then
        self.bathtowelDropBoxJoypad = TABAS_Panel.addButton(x, y, btnScale, btnScale, nil, "", "", self, self.onClick, false)
        self.bathtowelDropBoxJoypad.internal = "DROPBOX"
		self.bathtowelDropBoxJoypad.tooltipLabel = getText("IGUI_TABAS_BathTowelDropBoxTooltip")
        self.bathtowelDropBoxJoypad.backgroundColor = {r=0, g=0, b=0, a=0}
		table.insert(self.buttons, self.bathtowelDropBoxJoypad)
	else
		table.insert(self.buttons, self.bathtowelDropBox)
    end

	-- auto dry
	self.tglAutoDry = self:createToggle(x, toggleY, btnScale, toggleH, self.onAutoDryToggled)
	self.tglAutoDry.value = self.modOptions:getOption("AfterBathingDrySelf"):getValue()
	self:addChild(self.tglAutoDry)

	if self.tglAutoDry.value then
		self:addItemAux(TABAS_Utils.getAvailableTowel(self.playerObj))
	end

	x = x + btnScale + BORDER_SPACING*2
	-- bath mode
	self.btnAutoMode = TABAS_Panel.addButton(x, y, btnScale, btnScale, self.tex_bathingTime, nil, "", self, self.onClick, false)
	self.btnAutoMode.tooltipLabel = getText("UI_TABAS_AutoTakeBathMode")
	self.btnAutoMode.internal = "AUTOMODE"
	table.insert(self.buttons, self.btnAutoMode)

    self.tglAutoMode = self:createToggle(x, toggleY, btnScale, toggleH, self.onAutoModeToggled)
    self.tglAutoMode.value = self.modOptions:getOption("AutoTakeBathMode"):getValue()
    self:addChild(self.tglAutoMode)

	self:setWidth(self.btnAutoMode:getRight() + BORDER_SPACING*2)
	self:setHeight(self.btnAutoMode:getBottom() + toggleH + BORDER_SPACING*3)
	self.btnInfo:setX(self:getWidth() - self.btnInfo:getWidth() - BORDER_SPACING)
    self:setInteractionDisabled(self.interactionDisabled == true)
end

function TABAS_BathTimeEntryPanel:onMakeOffToggled(_newState)
	self.tglMakeOff.value = _newState
end

function TABAS_BathTimeEntryPanel:onAutoCCToggled(_newState)
	self.tglAutoCC.value = _newState
end

function TABAS_BathTimeEntryPanel:onAutoModeToggled(_newState)
    self.tglAutoMode.value = _newState
end

function TABAS_BathTimeEntryPanel:onAutoDryToggled(_newState)
	if not _newState and self.bathtowelDropBox.storedItem ~= nil then
		self:removeItem()
	end
	self.tglAutoDry.value = _newState
end

function TABAS_BathTimeEntryPanel:refreshFast()
    local towel = self.bathtowelDropBox.storedItem
    self.validTowel = towel and TABAS_Utils.isAvailableBathTowel(towel) or false
end

function TABAS_BathTimeEntryPanel:setInteractionDisabled(disabled)
    disabled = disabled == true
    if self.interactionDisabled == disabled then
        return
    end
    self.interactionDisabled = disabled

    if self.btnMakeOff then
        self.btnMakeOff:setEnable(not disabled)
    end
    if self.btnAutoCC then
        self.btnAutoCC:setEnable(not disabled)
    end
    if self.btnAutoMode then
        self.btnAutoMode:setEnable(not disabled)
    end
    if self.bathtowelDropBoxJoypad then
        self.bathtowelDropBoxJoypad:setEnable(not disabled)
    end
    if self.bathtowelDropBox then
        self.bathtowelDropBox.mouseEnabled = not disabled
        -- self.bathtowelDropBox.isLocked = disabled
        self.bathtowelDropBox.mouseOverState = 0
        if disabled then
            self.bathtowelDropBox:deactivateToolTip()
        end
    end
end

function TABAS_BathTimeEntryPanel:refreshUI(force)
    local changed = false
    if self.tglMakeOff.toggleState ~= self.tglMakeOff.value then
        self.tglMakeOff.toggleState = self.tglMakeOff.value
        changed = true
    end
    if self.tglAutoCC.toggleState ~= self.tglAutoCC.value then
        self.tglAutoCC.toggleState = self.tglAutoCC.value
        changed = true
    end
    if self.tglAutoMode.toggleState ~= self.tglAutoMode.value then
        self.tglAutoMode.toggleState = self.tglAutoMode.value
        changed = true
    end

    local towel = self.bathtowelDropBox.storedItem
    local autoDryState = towel ~= nil
    if self.tglAutoDry.toggleState ~= autoDryState then
        self.tglAutoDry.toggleState = autoDryState
        changed = true
    end

    if force or changed then
        self:updateTooltips()
    end

    if self.bathtowelDropBoxJoypad then
        local prev = self._lastTowel
        if force or prev ~= towel then
            self._lastTowel = towel
            if towel then
                local icon = towel:getIcon()
                local size = self.bathtowelDropBoxJoypad:getWidth() - 4
                self.bathtowelDropBoxJoypad:setImage(icon)
                self.bathtowelDropBoxJoypad:forceImageSize(size, size)
            else
                self.bathtowelDropBoxJoypad:setImage(nil)
            end
        end
    end
end

function TABAS_BathTimeEntryPanel:update()
    if self._managedByParent then return end
    self:refreshFast()
    self:refreshUI(false)
end

function TABAS_BathTimeEntryPanel:updateTooltips()
	local value = self.tglMakeOff.toggleState and ": ON" or ": OFF"
	self.btnMakeOff:setTooltip(self.btnMakeOff.tooltipLabel .. value)
	value = self.tglAutoCC.toggleState and ": ON" or ": OFF"
	self.btnAutoCC:setTooltip(self.btnAutoCC.tooltipLabel ..  value)
    value = self.tglAutoMode.toggleState and ": AUTO" or ": MANUAL"
	self.btnAutoMode:setTooltip(self.btnAutoMode.tooltipLabel .. value)
	if self.bathtowelDropBoxJoypad then
		local bTooltip = self.bathtowelDropBoxJoypad.joypadFocused or self.bathtowelDropBoxJoypad:isMouseOver()
		local text
		if bTooltip ~= self.bathtowelDropBoxJoypad.doTooltip then
			self.bathtowelDropBoxJoypad.doTooltip = bTooltip
			text = bTooltip and self.bathtowelDropBoxJoypad.tooltipLabel or nil
			self.bathtowelDropBoxJoypad:setTooltip(text)
		end
	end
end

function TABAS_BathTimeEntryPanel:prerender()
    ISPanelJoypad.prerender(self)
	self:drawText(self.title, BORDER_SPACING, BORDER_SPACING, self.labelColor.r, self.labelColor.g, self.labelColor.b, self.labelColor.a, UIFont.Small)

	-- button backgrounds
	local btnBGColor = {r=0.2, g=0.2, b=0.2, a=1}
	local backgroundColorMouseOver = {r=0.3, g=0.3, b=0.3, a=1.0}
	for i=1, #self.buttons do
		local btn = self.buttons[i]
		if btn.isButton then
			btn.fade:setFadeIn((btn.mouseOver and btn:isMouseOver()) and btn.enable or btn.joypadFocused or false)
		elseif btn.mouseOverState then -- for ISItemDropBox
			if btn.fade == nil then
				btn.fade = UITransition.new()
			end
			btn.fade:setFadeIn(btn.mouseOverState > 0 or btn.isLocked or btn.joypadFocused or false)
		end
		btn.fade:update()
		local f = btn.fade:fraction()
		local fill = {r=0.4, g=0.4, b=0.4, a=1}
		if btn.pressed then
			btn.backgroundColorPressed = btn.backgroundColorPressed or {}
			btn.backgroundColorPressed.r = backgroundColorMouseOver.r * 0.5
			btn.backgroundColorPressed.g = backgroundColorMouseOver.g * 0.5
			btn.backgroundColorPressed.b = backgroundColorMouseOver.b * 0.5
			btn.backgroundColorPressed.a = backgroundColorMouseOver.a
			fill = btn.backgroundColorPressed
		elseif btn.mouseOverState and btn.mouseOverState > 1 then
			fill = backgroundColorMouseOver
		end
		local c = {
			fill.a * f + btnBGColor.a * (1 - f),
			fill.r * f + btnBGColor.r * (1 - f),
			fill.g * f + btnBGColor.g * (1 - f),
			fill.b * f + btnBGColor.b * (1 - f)
		}
		self:drawTextureScaled(self.bg_button, btn:getX()-2, btn:getY()-2, self.btnScale+4, self.btnScale+4, c[1], c[2], c[3], c[4])
	end
	-- invalid towel border
	if self.bathtowelDropBox.storedItem and not self.validTowel then
		self:drawRectBorder(self.bathtowelDropBox:getX()-2, self.bathtowelDropBox:getY()-2, self.btnScale+4, self.btnScale+4, 1, 1, 0, 0)
	end
end

function TABAS_BathTimeEntryPanel:render()
    ISPanelJoypad.render(self)
	self:renderJoypadFocus()
end

function TABAS_BathTimeEntryPanel:onClick(_btn)
	if self.interactionDisabled then
		return
	end
	if _btn.internal == "MAKEOFF" then
		self.tglMakeOff.toggleState = not self.tglMakeOff.toggleState
		return self:onMakeOffToggled(self.tglMakeOff.toggleState)
	elseif _btn.internal == "ACC" then
		self.tglAutoCC.toggleState = not self.tglAutoCC.toggleState
		return self:onAutoCCToggled(self.tglAutoCC.toggleState)
	elseif _btn.internal == "AUTOMODE" then
        self.tglAutoMode.toggleState = not self.tglAutoMode.toggleState
        return self:onAutoModeToggled(self.tglAutoMode.toggleState)
	elseif _btn.internal == "DROPBOX" then
		return self:setOrClearItem()
	end
end

function TABAS_BathTimeEntryPanel:getStoredItem()
	if self.validTowel then
		return self.bathtowelDropBox.storedItem
	end
end

function TABAS_BathTimeEntryPanel:setOrClearItem()
    if self.interactionDisabled then return end
    if not self.bathtowelDropBox:isVisible() then return end
    if self.bathtowelDropBox.boxOccupied then
        self.bathtowelDropBox:onRightMouseUp(0, 0) -- remove item
    else
        self.bathtowelDropBox:onMouseDown(0, 0) -- choose item via context menu
    end
end

function TABAS_BathTimeEntryPanel:clickedDropBox(_x, _y)
    local self = self.parent
    if self.interactionDisabled then return end
	local validItems
	if TABAS_Compat.BTO then
		validItems = TABAS_Utils.getNearbyItems(self.playerObj, nil, 1, nil, BTO_Tag.Wipeable, TABAS_Utils.predicateBathTowel)
	else
		validItems = TABAS_Utils.getNearbyItems(self.playerObj, nil, 1, "BathTowel", nil, TABAS_Utils.predicateBathTowel)
	end
    if not validItems or validItems:isEmpty() then return end
    local box = self.bathtowelDropBox
    local playerNum = self.playerObj:getPlayerNum()
    local oldFocus = JoypadState.players[playerNum+1] and JoypadState.players[playerNum+1].focus or nil
    local x = box:getAbsoluteX() + box:getWidth()
    local y = box:getAbsoluteY() + box:getY()
    local context = ISContextMenu.get(playerNum, x, y)
	local item, name, option
    for i=1, validItems:size() do
		item = validItems:get(i-1)
		if item then
			name = item:getName()
			option = context:addOption(name, self.bathtowelDropBox, ISItemDropBox.onDropItem, item)
			if TABAS_Compat.BTO and item:hasTag(BTO_Tag.Wipeable) then
				self.bathTowelTooltip(item, option)
			end
			option.iconTexture = item:getIcon()
		end
    end
    context:setAlwaysOnTop(true)
    if oldFocus then
        context.origin = oldFocus
        context.mouseOver = 1
        setJoypadFocus(playerNum, context)
    end
end

function TABAS_BathTimeEntryPanel:addItem(_items)
    local list = ArrayList.new()
    for i=1, #_items do
        local item = _items[i]
        if not list:contains(item) then
            list:add(item)
        end
    end
    if list:size() == 1 then
       self:addItemAux(_items[1])
       return
    end
    local playerNum = self.playerObj:getPlayerNum()
    local context = ISContextMenu.get(playerNum, self.bathtowelDropBox:getAbsoluteX()+16, self.bathtowelDropBox:getAbsoluteY()+16)
    list:clear()
    for i=1, #_items do
        local item = _items[i]
        if not list:contains(item) then
            local option = context:addOption(item:getName(), self, self.addItemAux, item)
            local icon = item:getIcon()
            option.iconTexture = icon
			if not TABAS_Utils.isAvailableBathTowel(item) then
				option.notAvailable = true
			end
            list:add(item)
        end
    end
    context.mouseOver = 1
end

function TABAS_BathTimeEntryPanel:addItemAux(_item)
	if not _item then return end
    self.bathtowelDropBox:setStoredItem( _item )
	self.bathtowelDropBox:setToolTip(_item:getTooltip())
end

function TABAS_BathTimeEntryPanel:removeItem()
    self.bathtowelDropBox:setStoredItem(nil)
end

function TABAS_BathTimeEntryPanel:verifyItem(_item)
	return TABAS_Utils.predicateBathTowel(_item)
end

function TABAS_BathTimeEntryPanel.bathTowelTooltip(towel, option)
	local toolTip = TABAS_Panel.addItemTooltip()
    local labelCol = " <RGB:1,1,0.8> "
    local greenCol = " <RGB:0.5,1,0.5> "
    local yellowCol = " <RGB:1,1,0.5> "
    local redCol = " <RGB:1,0.5,0.5> "
    local whiteCol = " <RGB:1,1,1> "
    local text
    local textCol
    local valueText
    local towelWet = math.ceil(towel:getWetness() or 0)
    local towelDirt = towel:getDirtiness()
    local towelBlood = math.ceil(towel:getBloodLevel() or 0)
	local wipeBloodAndDirt = SandboxVars.BathTowelsOverhaul.WipesBloodAndDirt
	local showNumValue = PZAPI.ModOptions:getOptions("BathTowelsOverhaul"):getOption("DrySelfContextTooltip"):getValue() == 3
	local towelAbsorb = towel:getModData().Absorbency or 0

	local stainsTooltip

	toolTip.maxLineWidth = 500
	local font = UIFont.Small
	local labelWidth = 0
	labelWidth = math.max(labelWidth, getTextManager():MeasureStringX(font, getText("IGUI_BathTowelsOverhaul_Absorbency") .. ": "))
	labelWidth = math.max(labelWidth, getTextManager():MeasureStringX(font, getText("IGUI_BathTowelsOverhaul_TowelWetness") .. ": "))
	labelWidth = math.max(labelWidth, getTextManager():MeasureStringX(font, getText("IGUI_BathTowelsOverhaul_BodyWetness") .. ": "))
	labelWidth = math.max(labelWidth, getTextManager():MeasureStringX(font, getText("IGUI_BathTowelsOverhaul_NotWetness")))
	-- towel status
	-- towelAbsorbency
	if showNumValue then
		valueText = towelAbsorb or "N"
	else
		if towelAbsorb <= 10 then
			valueText = getText("IGUI_BathTowelsOverhaul_NotGood")
		elseif towelAbsorb < 50 then
			valueText = getText("IGUI_BathTowelsOverhaul_Normal")
		elseif towelAbsorb >= 80 then
			valueText = getText("IGUI_BathTowelsOverhaul_Great")
		else
			valueText = getText("IGUI_BathTowelsOverhaul_Good")
		end
	end
	text = string.format("<LEFT> %s: <RIGHT> <SETX:%d> %s <LINE> ", getText("IGUI_BathTowelsOverhaul_Absorbency"), labelWidth, valueText)
	toolTip.description = toolTip.description .. labelCol .. text
	-- towelWet
	if towelWet < 5 then
		valueText = getText("IGUI_BathTowelsOverhaul_Dry")
		textCol = greenCol
	elseif towelWet < 15 then
		valueText = getText("IGUI_BathTowelsOverhaul_Slightly")
		textCol = whiteCol
	elseif towelWet < 40 then
		valueText = getText("IGUI_BathTowelsOverhaul_Moist")
		textCol = yellowCol
	elseif towelWet > 80 then
		valueText = getText("IGUI_BathTowelsOverhaul_Soaked")
		textCol = redCol
	else
		valueText = getText("IGUI_BathTowelsOverhaul_Wet")
		textCol = yellowCol
	end
	if showNumValue then
		valueText = towelWet
	end
	text = string.format("<LEFT> %s: <RIGHT> <SETX:%d> %s %s <LINE> ", getText("IGUI_StatsAndBody_Wetness"), labelWidth, textCol, valueText)
	toolTip.description = toolTip.description .. labelCol .. text


	if wipeBloodAndDirt then
		stainsTooltip = function(stainName, stain)
			if stain < 5 then
				valueText = getText("IGUI_BathTowelsOverhaul_Clean")
				textCol = greenCol
			elseif stain < 20 then
				valueText = getText("IGUI_BathTowelsOverhaul_Slightly")
				textCol = whiteCol
			elseif stain < 50 then
				valueText = getText("IGUI_BathTowelsOverhaul_Dirty")
				textCol = yellowCol
			elseif stain > 80 then
				valueText = getText("IGUI_BathTowelsOverhaul_Grubby")
				textCol = redCol
			else
				valueText = getText("IGUI_BathTowelsOverhaul_Filthy")
				textCol = yellowCol
			end
			if showNumValue then
				valueText = stain
			end
			text = string.format("<LEFT> %s: <RIGHT> <SETX:%d> %s %s <LINE> ", getText("IGUI_ClothingName_" .. stainName), labelWidth, textCol, valueText)
			toolTip.description = toolTip.description .. labelCol .. text
		end
		stainsTooltip("Bloody", towelBlood)
		stainsTooltip("Dirty", towelDirt)
	end
	option.toolTip = toolTip
	if not TABAS_Utils.isAvailableBathTowel(towel) then
		option.notAvailable = true
	end
end

function TABAS_BathTimeEntryPanel:isAutoModeEnabled()
    return self.tglAutoMode and self.tglAutoMode.toggleState == true
end

function TABAS_BathTimeEntryPanel:onGainJoypadFocus(joypadData)
	ISPanelJoypad.onGainJoypadFocus(self, joypadData)
	self.joypadButtons = {}
    self.joypadButtonsY = {}
    if self._mainPanel and self._mainPanel.autoBathTimePanel then
        self:insertNewLineOfButtons(self._mainPanel.autoBathTimePanel.btnMinus, self._mainPanel.autoBathTimePanel.btnPlus)
    end
	self:insertNewLineOfButtons(self.btnMakeOff, self.btnAutoCC, self.bathtowelDropBoxJoypad, self.btnAutoMode, self.btnInfo)
    if self.prevJoypadIndex and self.prevJoypadIndexY then
	    self.joypadIndex = self.prevJoypadIndex
        self.joypadIndexY = self.prevJoypadIndexY
    else
        self.joypadIndex = 4
        self.joypadIndexY = 2
    end
    self:restoreJoypadFocus(joypadData)
end

function TABAS_BathTimeEntryPanel:onLoseJoypadFocus(joypadData)
    ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
	self.prevJoypadIndex = self.joypadIndex
    self.prevJoypadIndexY = self.joypadIndexY
	self:clearJoypadFocus(joypadData)
end

function TABAS_BathTimeEntryPanel:onJoypadDown(button, joypadData)
    if button == Joypad.BButton then
        self._mainPanel:close()
        return
    end
    if button == Joypad.RBumper then
		self:setJoypadFocused(false, joypadData)
        setJoypadFocus(self.playerObj:getPlayerNum(), self._mainPanel)
		self:onLoseJoypadFocus(joypadData)
		return
	end
	if button == Joypad.LBumper and self._mainPanel.showerPanel then
		self:setJoypadFocused(false, joypadData)
        setJoypadFocus(self.playerObj:getPlayerNum(), self._mainPanel.showerPanel)
		self:onLoseJoypadFocus(joypadData)
		return
    end
    ISPanelJoypad.onJoypadDown(self, button, joypadData)
end

function TABAS_BathTimeEntryPanel:getBPrompt()
    return getText("UI_Close")
end

function TABAS_BathTimeEntryPanel:isValidPrompt()
    return self:isReallyVisible()
end

function TABAS_BathTimeEntryPanel:getAPrompt()
    if self.interactionDisabled then
        return nil
    end
    return getText("IGUI_TABAS_SelectButton")
end

function TABAS_BathTimeEntryPanel:getLBPrompt()
    if self._mainPanel and self._mainPanel.showerPanel then
        return getText("IGUI_TABAS_SelectShower")
    end
    return nil
end

function TABAS_BathTimeEntryPanel:getRBPrompt()
    return getText("IGUI_TABAS_SelectMain")
end

function TABAS_BathTimeEntryPanel:new (x, y, playerObj, tfc_Base)
	local btnScale = HGT_BUTTON * 1.55
    local width = HGT_BUTTON*3 + BORDER_SPACING*7 + btnScale

    local height = HGT_BUTTON*3 + btnScale + BORDER_SPACING*2
    local o = ISPanelJoypad:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y
	o.labelColor = CONST.COLOR.labelColor
	o.btnScale = btnScale
	o.title = getText("IGUI_TABAS_BathtubInfo_HowTakeBath")

	local texture = CONST.TEXTURE
	o.tex_makeoff = texture.makeoff
	o.tex_towel = texture.towel
	o.tex_autoCC = texture.autoCC
	o.tex_autoDry = texture.autoDry
	o.tex_bathingTime = texture.bathingTime
	o.tex_infoIcon = texture.infoButton_small
	o.bg_button = texture.bg_button

    o.width = width
    o.height = height
	o.playerObj = playerObj
	o.tfc_Base = tfc_Base
	o.towel = nil
	o.modOptions = PZAPI.ModOptions:getOptions("TakeABathAndShower")
	o.disableJoypadNavigation = true
	o.overrideBPrompt = true
    o.interactionDisabled = false
	return o
end
