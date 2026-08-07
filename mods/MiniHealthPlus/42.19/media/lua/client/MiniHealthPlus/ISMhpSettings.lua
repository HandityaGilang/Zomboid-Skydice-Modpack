ISMhpSettings = ISPanel:derive("ISMhpSettings")

function ISMhpSettings:new(x,y,width,owner)
	local panel = {}
	panel = ISPanel:new(x,y,width,50)
	setmetatable(panel, self)
	self.__index = self

	panel.defaultWidth = math.max(width or 240, 240)
	panel.width = panel.defaultWidth
	panel.owner = owner
	panel.uiScale = 1.0

	panel.moving = false
	panel.dragging = false
	panel.dragOffsetX = 0
	panel.dragOffsetY = 0
	panel.useCustomPosition = false

	panel.pendingBlinkSpeed = 14
	panel.blinkSpeedButton = nil

	return panel
end

function ISMhpSettings:setScale(scale)
	self.uiScale = 1.0
	self:refreshLayout()
end

function ISMhpSettings:getLayoutMetrics()
	local titleFont = UIFont.Medium
	local optionFont = UIFont.Small

	local titleH = getTextManager():getFontHeight(titleFont)
	local optionH = getTextManager():getFontHeight(optionFont)

	local pad = math.max(8, math.floor(optionH * 0.45 + 0.5))
	local btnH = math.max(25, optionH + 8)
	local btnText = getText("IGUI_RadioSave")
	local btnW = math.max(100, getTextManager():MeasureStringX(UIFont.Small, btnText) + pad * 3)

	return {
		titleFont = titleFont,
		titleH = titleH,
		optionFont = optionFont,
		optionH = optionH,
		pad = pad,
		btnH = btnH,
		btnW = btnW,
	}
end

function ISMhpSettings:getHeaderHeight()
	local m = self:getLayoutMetrics()
	return m.pad + m.titleH + m.pad
end

function ISMhpSettings:getDesiredPanelWidth(m)
	m = m or self:getLayoutMetrics()

	local title = getText("UI_MHP_Settings")
	local contentWidth = getTextManager():MeasureStringX(m.titleFont, title)

	if m.btnW > contentWidth then
		contentWidth = m.btnW
	end

	if self.tickBox and self.tickBox.options then
		local optionIndent = self.tickBox.leftMargin or 0
		local optionBoxSize = self.tickBox.boxSize or math.max(m.optionH + 4, 18)
		local optionTextGap = self.tickBox.textGap or math.max(8, m.pad)

		for _, optionText in ipairs(self.tickBox.options) do
			local textW = getTextManager():MeasureStringX(m.optionFont, tostring(optionText or ""))
			local rowW = optionIndent + optionBoxSize + optionTextGap + textW
			if rowW > contentWidth then
				contentWidth = rowW
			end
		end
	end

	local buttonText = self:getBlinkSpeedButtonTitle()
	local textW = getTextManager():MeasureStringX(UIFont.Small, tostring(buttonText or ""))
	local rowW = textW + m.pad * 4
	if rowW > contentWidth then
		contentWidth = rowW
	end

	return math.max(self.defaultWidth or 240, math.ceil(contentWidth + m.pad * 2 + 12))
end

function ISMhpSettings:clampToScreen()
	local screenW = getCore():getScreenWidth()
	local screenH = getCore():getScreenHeight()

	local x = self:getX()
	local y = self:getY()

	if x + self:getWidth() > screenW then
		x = screenW - self:getWidth()
	end
	if y + self:getHeight() > screenH then
		y = screenH - self:getHeight()
	end
	if x < 0 then
		x = 0
	end
	if y < 0 then
		y = 0
	end

	self:setX(x)
	self:setY(y)
end

function ISMhpSettings:getOptionsHeight()
	if not self.tickBox then
		return 0
	end

	local optionCount = self.tickBox:getOptionCount()
	if optionCount <= 0 then
		return 0
	end

	local tickSpacing = 10
	return optionCount * self.tickBox.itemHgt + (optionCount - 1) * tickSpacing
end

function ISMhpSettings:syncPendingFromOwner()
	if not self.owner then
		return
	end

	self.pendingBlinkSpeed = self.owner.blinkSpeed or 14
end

function ISMhpSettings:getBlinkSpeedButtonTitle()
	local mhpClass = TwisTonFire_MHP and (TwisTonFire_MHP.MiniHealthPanel or TwisTonFire_MHP.ISMiniHealth)
	local speedText = tostring(self.pendingBlinkSpeed)

	if mhpClass and mhpClass.getBlinkSpeedDisplayTextFor then
		speedText = mhpClass.getBlinkSpeedDisplayTextFor(self.pendingBlinkSpeed)
	end

	return getText("UI_MHP_AnimationSpeed") .. ": " .. speedText
end

function ISMhpSettings:refreshCustomControls()
	if self.blinkSpeedButton then
		self.blinkSpeedButton:setTitle(self:getBlinkSpeedButtonTitle())
	end
end

function ISMhpSettings:onBlinkSpeedButton()
	local presets = { 6, 8, 10, 14, 18 }
	local current = tonumber(self.pendingBlinkSpeed) or 10
	local nextIndex = 1

	for i = 1, #presets do
		if presets[i] == current then
			nextIndex = i + 1
			break
		end
	end

	if nextIndex > #presets then
		nextIndex = 1
	end

	self.pendingBlinkSpeed = presets[nextIndex]

	-- Apply immediately to the live panel, but do not save yet.
	if self.owner then
		self.owner:setBlinkSpeed(self.pendingBlinkSpeed)

		-- Restart the pulse so the player can immediately notice the change.
		self.owner.blinkTime = 0
	end

	self:refreshCustomControls()
	self:refreshLayout()
end

function ISMhpSettings:refreshLayout()
	local m = self:getLayoutMetrics()
	local titleY = m.pad
	local contentY = titleY + m.titleH + m.pad
	local buttonGap = m.pad
	local bottomPad = m.pad
	local tickSpacing = 10

	if self.tickBox then
		self.tickBox:setFont(m.optionFont)
		self.tickBox.leftMargin = 0
		self.tickBox.textGap = math.max(8, m.pad)
		self.tickBox.boxSize = math.max(m.optionH + 4, 18)
		self.tickBox.itemGap = 0
		self.tickBox.fontHgt = getTextManager():getFontHeight(self.tickBox.font)
		self.tickBox.itemHgt = math.max(self.tickBox.boxSize, self.tickBox.fontHgt)
	end

	self:refreshCustomControls()

	local targetWidth = self:getDesiredPanelWidth(m)
	self.width = targetWidth
	self:setWidth(targetWidth)

	if self.tickBox then
		local optionCount = self.tickBox:getOptionCount()
		local tickHeight = 0

		if optionCount > 0 then
			tickHeight = optionCount * self.tickBox.itemHgt + (optionCount - 1) * tickSpacing
		end

		self.tickBox:setX(m.pad)
		self.tickBox:setY(contentY)
		self.tickBox:setWidth(math.max(10, self:getWidth() - m.pad * 2))
		self.tickBox:setHeight(tickHeight)
	end

	local controlsY = contentY
	if self.tickBox then
		controlsY = self.tickBox:getY() + self:getOptionsHeight() + buttonGap
	end

	local fullWidth = math.max(10, self:getWidth() - m.pad * 2)

	if self.blinkSpeedButton then
		self.blinkSpeedButton:setX(m.pad)
		self.blinkSpeedButton:setY(controlsY)
		self.blinkSpeedButton:setWidth(fullWidth)
		self.blinkSpeedButton:setHeight(m.btnH)
		controlsY = controlsY + m.btnH + buttonGap
	end

	if self.ok then
		self.ok:setWidth(m.btnW)
		self.ok:setHeight(m.btnH)
		self.ok:setX(math.floor((self:getWidth() - m.btnW) / 2))
		self.ok:setY(controlsY)
	end

	local newHeight = controlsY + m.btnH + bottomPad
	self:setHeight(newHeight)
end

function ISMhpSettings:initialise()
	ISPanel.initialise(self)
end

function ISMhpSettings:createChildren()
	local m = self:getLayoutMetrics()

	self:syncPendingFromOwner()

	if self.ok then
		self:removeChild(self.ok)
		self.ok = nil
	end

	if self.tickBox then
		self:removeChild(self.tickBox)
		self.tickBox = nil
	end

	if self.blinkSpeedButton then
		self:removeChild(self.blinkSpeedButton)
		self.blinkSpeedButton = nil
	end

	self.ok = ISButton:new(10, 10, m.btnW, m.btnH, getText("IGUI_RadioSave"), self, ISMhpSettings.validateButton)
	self.ok.internal = "SAVE"
	self.ok.anchorTop = true
	self.ok.anchorBottom = false
	self.ok:initialise()
	self.ok:instantiate()
	self.ok.borderColor = {r=1, g=1, b=1, a=0.1}
	self:addChild(self.ok)

	self.tickBox = ISTickBox:new(10, 10, math.max(10, self:getWidth() - m.pad * 2), math.max(m.optionH + 4, 18), "", self, self.onTicked)
	self.tickBox.choicesColor = {r=1, g=1, b=1, a=1}
	self.tickBox.leftMargin = 0
	self.tickBox:setFont(m.optionFont)
	self:addChild(self.tickBox)

	self.blinkSpeedButton = ISButton:new(10, 10, math.max(10, self:getWidth() - m.pad * 2), m.btnH, "", self, ISMhpSettings.onBlinkSpeedButton)
	self.blinkSpeedButton:initialise()
	self.blinkSpeedButton:instantiate()
	self.blinkSpeedButton.borderColor = {r=1, g=1, b=1, a=0.1}
	self:addChild(self.blinkSpeedButton)

	self:refreshCustomControls()
	self:refreshLayout()
end

function ISMhpSettings:getOpen()
	return self.isOpen;
end

function ISMhpSettings:setOpen(isOpen, x, y, width)
	self:setVisible(isOpen)

	if isOpen then
		self:syncPendingFromOwner()

		local targetWidth = self.defaultWidth or 240
		self.width = targetWidth
		self:setWidth(targetWidth)
		self:refreshCustomControls()
		self:refreshLayout()

		if not self.useCustomPosition then
			self:setX(x)
			self:setY(y)
		end

		self:clampToScreen()
	end

	if isOpen and not self.isOpen then
		self:addToUIManager()
	elseif not isOpen and self.isOpen then
		self:removeFromUIManager()
	end

	self.isOpen = isOpen
end

function ISMhpSettings:populateOptions()
	local owner = self.owner
	self.setFunction = {}

	if self.tickBox then
		self.tickBox:clearOptions()
	end

	self:addOption(getText("UI_MHP_AlwaysOnTop"), owner.alwaysOnTopUI == true, function(panelOwner, selected)
		panelOwner:toggleAlwaysOnTopUI(selected)
	end)
	
	self:addOption(getText("UI_MHP_AlwaysVisible"), owner.alwaysShow, function(panelOwner, selected)
		panelOwner:toggleAlwaysShow(selected)
	end)

	self:addOption(getText("UI_MHP_HealthBar"), owner.showHpBar, function(panelOwner, selected)
		panelOwner:toggleHpBar(selected)
	end)

	self:addOption(getText("UI_MHP_MuscleStrains"), owner.showStrains, function(panelOwner, selected)
		panelOwner:toggleStrains(selected)
	end)

	self:addOption(getText("UI_MHP_LockWindow"), not owner.moveWithMouse, function(panelOwner, selected)
		panelOwner:toggleLock(not selected)
	end)

		self:addOption(getText("UI_MHP_HoverBackground"), owner.showHoverBackground, function(panelOwner, selected)
		panelOwner:toggleHoverBackground(selected)
	end)

	if type(TwisTonFire_MHP_IsBetterCharacterInfoActive) == "function"
	and TwisTonFire_MHP_IsBetterCharacterInfoActive() then
		self:addOption(getText("UI_MHP_BCIAvatarOnIdle"), owner.showBCIAvatarOnIdle == true, function(panelOwner, selected)
			panelOwner:toggleBCIAvatarOnIdle(selected)
		end)
	end

	self:refreshLayout()
end

function ISMhpSettings:addOption(text, selected, setFunction)
    local n = self.tickBox:addOption(text)
    self.tickBox:setSelected(n, selected)
    self.setFunction[n] = setFunction
end

function ISMhpSettings:validateButton()
	local owner = self.owner
	if not owner then
		self:setOpen(false, 0, 0, 0)
		return
	end

	for i = 1, #self.tickBox.options do
		self.setFunction[i](owner, self.tickBox:isSelected(i))
	end

	owner:setBlinkSpeed(self.pendingBlinkSpeed)
	owner:writeConfig()

	self:setOpen(false, 0, 0, 0)

	if TwisTonFire_MHP_RequestFullRefresh then
		TwisTonFire_MHP_RequestFullRefresh()
	elseif MHP_RequestFullRefresh then
		MHP_RequestFullRefresh()
	end

	if TwisTonFire_MHP_RefreshModOptions then
		TwisTonFire_MHP_RefreshModOptions()
	end
end

function ISMhpSettings:onMouseDown(x, y)
	if y <= self:getHeaderHeight() then
		self.moving = true
		self.dragging = false
		self.dragOffsetX = x
		self.dragOffsetY = y
		self:setCapture(true)
		return true
	end

	return ISPanel.onMouseDown(self, x, y)
end

function ISMhpSettings:onMouseMove(dx, dy)
	if self.moving then
		self.dragging = true
		self.useCustomPosition = true
		self:setX(self:getX() + dx)
		self:setY(self:getY() + dy)
		self:clampToScreen()
		return true
	end

	return ISPanel.onMouseMove(self, dx, dy)
end

function ISMhpSettings:onMouseMoveOutside(dx, dy)
	if self.moving then
		self.dragging = true
		self.useCustomPosition = true
		self:setX(self:getX() + dx)
		self:setY(self:getY() + dy)
		self:clampToScreen()
		return true
	end

	return ISPanel.onMouseMoveOutside(self, dx, dy)
end

function ISMhpSettings:onMouseUp(x, y)
	if self.moving then
		self.moving = false
		self:setCapture(false)
		return true
	end

	return ISPanel.onMouseUp(self, x, y)
end

function ISMhpSettings:onMouseUpOutside(x, y)
	if self.moving then
		self.moving = false
		self:setCapture(false)
		return true
	end

	return ISPanel.onMouseUpOutside(self, x, y)
end

function ISMhpSettings:prerender()
	local m = self:getLayoutMetrics()
	local title = getText("UI_MHP_Settings")
	local titleX = math.floor((self.width - getTextManager():MeasureStringX(m.titleFont, title)) / 2)

	self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
	self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
	self:drawText(title, titleX, m.pad, 1, 1, 1, 1, m.titleFont)
end