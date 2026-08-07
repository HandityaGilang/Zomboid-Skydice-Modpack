require "ISUI/ISPanelJoypad"
local PSR = require "PSR/Utilities"

local PSRWindowsSumaryTab = ISPanelJoypad:derive("PSRWindowsSumaryTab")

function PSRWindowsSumaryTab:initialise()
	ISPanelJoypad.initialise(self)

	-- House
	self.imageHouse = ISImage:new(321, 185, 254, 185, self.textureHouse)
	self.imageHouse.scaledWidth = 254
	self.imageHouse.scaledHeight = 185
	self.imageHouse:initialise()
	self.imageHouse.parent = self
    self:addChild(self.imageHouse)

	-- Cables
	self.imageCables = ISImage:new(52, 358, 403, 24, self.textureCables)
	self.imageCables.scaledWidth = 403
	self.imageCables.scaledHeight = 24
	self.imageCables:initialise()
	self.imageCables.parent = self
    self:addChild(self.imageCables)

	-- Battery
	self.imageBattery = ISImage:new(16, 302, 76, 69, self.textureBattery)
	self.imageBattery.scaledWidth = 76
	self.imageBattery.scaledHeight = 69
	self.imageBattery:initialise()
	self.imageBattery.parent = self
    self:addChild(self.imageBattery)

	self.imageBatteryCross = ISImage:new(17, 305, 72, 72, self.textureCross)
	self.imageBatteryCross.scaledWidth = 72
	self.imageBatteryCross.scaledHeight = 72
	self.imageBatteryCross:initialise()
	self.imageBatteryCross.parent = self
    self:addChild(self.imageBatteryCross)

	-- Sun and radiation

	self.imageSun = ISImage:new(0, 0, 128, 128, self.textureSun)
	self.imageSun.scaledWidth = 128
	self.imageSun.scaledHeight = 128
	self.imageSun:initialise()
	self.imageSun.parent = self
    self:addChild(self.imageSun)


	-- Moon
	self.imageMoon = ISImage:new(0, 0, 128, 128, self.textureMoon)
	self.imageMoon.scaledWidth = 128
	self.imageMoon.scaledHeight = 128
	self.imageMoon:initialise()
	self.imageMoon.parent = self
    self:addChild(self.imageMoon)

	-- Solar Panel (two modes)
	self.imageSolarPanel = ISImage:new(123, 267, 155, 103, self.textureSolarPanel)
	self.imageSolarPanel.scaledWidth = 155
	self.imageSolarPanel.scaledHeight = 103
	self.imageSolarPanel:initialise()
	self.imageSolarPanel.parent = self
    self:addChild(self.imageSolarPanel)
	self.imageSolarPanel:setVisible(false)

	self.imageSolarPanelNoEnergy = ISImage:new(123, 267, 155, 103, self.textureSolarPanelNoEnergy)
	self.imageSolarPanelNoEnergy.scaledWidth = 155
	self.imageSolarPanelNoEnergy.scaledHeight = 103
	self.imageSolarPanelNoEnergy:initialise()
	self.imageSolarPanelNoEnergy.parent = self
    self:addChild(self.imageSolarPanelNoEnergy)

	self.imageSolarPanelCross = ISImage:new(166, 268, 72, 72, self.textureCross)
	self.imageSolarPanelCross.scaledWidth = 72
	self.imageSolarPanelCross.scaledHeight = 72
	self.imageSolarPanelCross:initialise()
	self.imageSolarPanelCross.parent = self
    self:addChild(self.imageSolarPanelCross)

	-- Fix the daytime/nightime icon
	if PSR.isDayTime() then
		self.imageSun:setVisible(true)
		self.imageMoon:setVisible(false)
		self.night = false
	else
		self.imageSun:setVisible(false)
		self.imageMoon:setVisible(true)
		self.night = true
	end
end

function PSRWindowsSumaryTab:createChildren()
	self:setScrollChildren(true)
	self:addScrollBars()
end

function PSRWindowsSumaryTab:setVisible(visible)
    self.javaObject:setVisible(visible)
	if visible then
		self:setWidthAndParentWidth(580)
		self:setHeightAndParentHeight(390)
		self.currentFrame = 0
	end
end

local function fmtTime(h)
	h = math.abs(h)
	local d  = math.floor(h / 24)
	local hh = math.floor(h % 24)
	local m  = math.floor((h - math.floor(h)) * 60)
	return string.format("%dd %dh %dm", d, hh, m)
end

function PSRWindowsSumaryTab:render()
	local pb = self.parent.parent.luaPB
	if not (pb and pb:getIsoObject()) then return self.parent.parent:close() end

	-- Update every ~1 sec
	if self.currentFrame == 0 then
		pb:updateFromIsoObject()
		self.maxCapacity = pb.maxcapacity or 0
		self.charge = pb.charge or 0
		self.drain = pb.drain or 0
		self.batteryLevel = self.maxCapacity > 0 and self.charge / self.maxCapacity or 0
		self.panelsMaxInput = pb.luaSystem:getMaxSolarOutput(pb.npanels or 0)
		self.panelsInput = pb.luaSystem:getModifiedSolarOutput(pb.npanels or 0)
		self.difference = self.panelsInput - (pb:shouldDrain() and self.drain or 0)

		if PSR.isDayTime() then
			if (self.night == true) then
				self.imageSun:setVisible(true)
				self.imageMoon:setVisible(false)
				self.night = false
			end
		else
			if (self.night == false) then
				self.imageSun:setVisible(false)
				self.imageMoon:setVisible(true)
				self.night = true
			end
		end

		if (pb.batteries or 0) > 0 then
			if (self.thereAreBatteries == false) then
				self.imageBatteryCross:setVisible(false)
				self.thereAreBatteries = true
			end
		else
			if (self.thereAreBatteries == true) then
				self.imageBatteryCross:setVisible(true)
				self.thereAreBatteries = false
			end
		end

		if (pb.npanels or 0) > 0 then
			if (self.thereArePanels == false) then
				self.imageSolarPanelCross:setVisible(false)
				self.thereArePanels = true
			end
		else
			if (self.thereArePanels == true) then
				self.imageSolarPanelCross:setVisible(true)
				self.thereArePanels = false
			end
		end

		if self.difference > 0 then
			if (self.batteryCharging == false) then
				self.imageSolarPanel:setVisible(true)
				self.imageSolarPanelNoEnergy:setVisible(false)
				self.batteryCharging = true
			end
		else
			if (self.batteryCharging == true) then
				self.imageSolarPanel:setVisible(false)
				self.imageSolarPanelNoEnergy:setVisible(true)
				self.batteryCharging = false
			end
		end

		local networkTotalPanels, linkedPanelInfo, networkCharge, networkDrain = PSR.WorldUtil.getLinkedBanksPanelInfo(pb)
		self.hasLinkedBanks = #linkedPanelInfo > 0
		self.networkCharge = networkCharge
		self.networkDrain  = networkDrain
		self.networkRechargeText = nil
		if self.hasLinkedBanks and networkTotalPanels > 0 then
			local networkSolar = pb.luaSystem:getModifiedSolarOutput(networkTotalPanels)
			local netRate = networkSolar - (pb:shouldDrain() and self.drain or 0)
			if netRate > 0 and self.maxCapacity > 0 and self.charge < self.maxCapacity then
				local h = math.floor((self.maxCapacity - self.charge) / netRate)
				local m = math.floor(((self.maxCapacity - self.charge) / netRate - h) * 60)
				self.networkRechargeText = string.format("%dh %02dm", h, m)
			end
		end

		self.currentFrame = self.fps - 1
	else
		self.currentFrame = self.currentFrame - 1
	end

	-- Summary box
	local line = getTextManager():getFontHeight(UIFont.Small)
	local rectX, rectY, rectW = self.sumBox.x, 20, self.sumBox.width
	local text_x = self.sumBox.textX
	local text_x2 = text_x + self.sumBox.pad1
	local text_y = 30
	local el = 1 + (self.hasLinkedBanks and self.networkRechargeText and 1 or 0)
	local nl = self.hasLinkedBanks and 1 or 0
	local rectH = 25 + line * (5 + el + nl)
	self:drawRect(rectX, rectY, rectW, rectH, 0.5, 0.16, 0.16, 0.16)
	self:drawRectBorder(rectX, rectY, rectW, rectH, 1, 1, 1, 1)

	-- Linked Network row
	self:drawTextRight(getText("IGUI_PSRWindow_Details_LinkedNetwork") .. ":", text_x, text_y + line * 0, 0, 1, 0, 1, UIFont.Small)
	if self.hasLinkedBanks then
		self:drawText(getText("UI_Yes"), text_x2, text_y + line * 0, 0, 1, 0, 1, UIFont.Small)
		if self.networkRechargeText then
			self:drawTextRight(getText("IGUI_PSRWindow_Details_NetworkRecharge") .. ":", text_x, text_y + line * 1, 0, 1, 0, 1, UIFont.Small)
			self:drawText(self.networkRechargeText, text_x2, text_y + line * 1, 0, 1, 0, 1, UIFont.Small)
		end
	else
		self:drawText(getText("UI_No"), text_x2, text_y + line * 0, 0, 1, 0, 1, UIFont.Small)
	end

	-- Summary text (shifted by el)
	self:drawTextRight(getText("IGUI_PSRWindowsSumaryTab_PanelsStatus") .. ":", text_x, text_y + line * el, 0, 1, 0, 1, UIFont.Small)
	self:drawTextRight(getText("IGUI_PSRWindowsSumaryTab_PanelCount") .. ":", text_x, text_y + line * (el + 1), 0, 1, 0, 1, UIFont.Small)
	self:drawTextRight(getText("IGUI_PSRWindowsSumaryTab_BatteryLevel") .. ":", text_x, text_y + line * (el + 2), 0, 1, 0, 1, UIFont.Small)

	-- Solar panels status
	if (self.drain > self.panelsMaxInput) then
		self:drawText(getText("IGUI_PSRWindowsSumaryTab_NoEnoughPanels"), text_x2, text_y + line * el, 0, 1, 0, 1, UIFont.Small)
	elseif (self.drain > self.panelsInput) then
		self:drawText(getText("IGUI_PSRWindowsSumaryTab_NoEnoughSun"), text_x2, text_y + line * el, 0, 1, 0, 1, UIFont.Small)
	else
		self:drawText(getText("IGUI_PSRWindowsSumaryTab_Working"), text_x2, text_y + line * el, 0, 1, 0, 1, UIFont.Small)
	end
	self:drawText(tostring(pb.npanels or 0), text_x2, text_y + line * (el + 1), 0, 1, 0, 1, UIFont.Small)

	if (self.maxCapacity > 0) then
		self:drawText(string.format("%d%%", self.batteryLevel * 100), text_x2, text_y + line * (el + 2), 0, 1, 0, 1, UIFont.Small)

		if (self.difference > 0) then
			if self.maxCapacity == self.charge then
				self:drawTextRight(getText("IGUI_PSRWindowsSumaryTab_BatteryStatus") .. ":", text_x, text_y + line * (el + 3), 0, 1, 0, 1, UIFont.Small)
				self:drawText(getText("IGUI_PSRWindowsSumaryTab_FullyCharged"), text_x2, text_y + line * (el + 3), 0, 1, 0, 1, UIFont.Small)
			else
				self:drawTextRight(getText("IGUI_PSRWindowsSumaryTab_ChargedIn"), text_x, text_y + line * (el + 3), 0, 1, 0, 1, UIFont.Small)
				self:drawText(fmtTime((self.maxCapacity - self.charge) / self.difference), text_x2, text_y + line * (el + 3), 0, 1, 0, 1, UIFont.Small)
			end
		elseif (self.difference < 0) then
			if (self.charge == 0) then
				self:drawTextRight(getText("IGUI_PSRWindowsSumaryTab_BatteryStatus") .. ":", text_x, text_y + line * (el + 3), 0, 1, 0, 1, UIFont.Small)
				self:drawText(getText("IGUI_PSRWindowsSumaryTab_FullyDischarged"), text_x2, text_y + line * (el + 3), 0, 1, 0, 1, UIFont.Small)
			else
				self:drawTextRight(getText("IGUI_PSRWindowsSumaryTab_DischargedIn"), text_x, text_y + line * (el + 3), 0, 1, 0, 1, UIFont.Small)
				self:drawText(fmtTime(math.abs(self.charge / self.difference)), text_x2, text_y + line * (el + 3), 0, 1, 0, 1, UIFont.Small)
			end
		else
			self:drawText(getText("IGUI_PSRWindowsSumaryTab_NotCharging"), text_x2, text_y + line * (el + 3), 0, 1, 0, 1, UIFont.Small)
		end
		if self.charge > 0 and self.drain > 0 then
			self:drawTextRight(getText("IGUI_PSRWindowsSumaryTab_BatteryRemaining"), text_x, text_y + line * (el + 4), 0, 1, 0, 1, UIFont.Small)
			self:drawText(fmtTime(self.charge / self.drain), text_x2, text_y + line * (el + 4), 0, 1, 0, 1, UIFont.Small)
		end
	else
		self:drawText(getText("IGUI_PSRWindowsSumaryTab_NoBatteries"), text_x2, text_y + line * (el + 2), 0, 1, 0, 1, UIFont.Small)
		self:drawText(getText("IGUI_PSRWindowsSumaryTab_NotCharging"), text_x2, text_y + line * (el + 3), 0, 1, 0, 1, UIFont.Small)
	end
	if self.hasLinkedBanks then
		self:drawTextRight(getText("IGUI_PSRWindowsSumaryTab_NetworkReserves") .. ":", text_x, text_y + line * (el + 5), 0, 1, 0, 1, UIFont.Small)
		if self.networkDrain > 0 and self.networkCharge > 0 then
			self:drawText(fmtTime(self.networkCharge / self.networkDrain), text_x2, text_y + line * (el + 5), 0, 1, 0, 1, UIFont.Small)
		else
			self:drawText("-", text_x2, text_y + line * (el + 5), 0, 1, 0, 1, UIFont.Small)
		end
	end
end

function PSRWindowsSumaryTab:new(x, y, width, height)
	local o = ISPanelJoypad.new(self, x, y, width, height)
	o:noBackground()

	-- Textures
	o.textureBattery = getTexture("media/ui/PSR_battery.png")
	o.textureCables = getTexture("media/ui/PSR_cables.png")
	o.textureHouse = getTexture("media/ui/PSR_house.png")
	o.textureSolarPanel = getTexture("media/ui/PSR_solar_panel.png")
	o.textureSolarPanelNoEnergy = getTexture("media/ui/PSR_solar_panel_no_energy.png")
	o.textureCross = getTexture("media/ui/PSR_cross.png")
	o.textureSun = getTexture("media/ui/PSR_sun.png")
	o.textureMoon = getTexture("media/ui/PSR_moon.png")

	local maxMeasured = o.measureTexts()
	local maxLR = maxMeasured.left + maxMeasured.right
	o.sumBox = {}
	if maxLR > 580 then -- resize?
		o.sumBox.x = 0
		o.sumBox.width = 580
		o.sumBox.pad1 = 1
		o.sumBox.textX = maxMeasured.left
	elseif maxLR > 570 then
		o.sumBox.x = 0
		o.sumBox.width = 580
		o.sumBox.pad1 = 580 - maxLR
		o.sumBox.textX = maxMeasured.left
	elseif maxLR > 530 then
		o.sumBox.x = 0
		o.sumBox.width = 580
		o.sumBox.pad1 = 10
		o.sumBox.textX = maxMeasured.left + math.floor((570-maxLR) / 2)
	elseif maxLR > 490 then
		o.sumBox.x = math.floor((570 - maxLR) / 2)
		o.sumBox.width = maxLR + 50
		o.sumBox.pad1 = 10
		o.sumBox.textX = o.sumBox.x + 20 + maxMeasured.left
	else
		o.sumBox.x = 510 - maxLR
		o.sumBox.width = maxLR + 50
		o.sumBox.pad1 = 10
		o.sumBox.textX = o.sumBox.x + 20 + maxMeasured.left
	end

	-- Used variables
	o.currentFrame = 0
	o.thereAreBatteries = false
	o.thereArePanels = false
	o.panelsMaxInput = 0
	o.panelsInput = 0
	o.batteryLevel = 0
	o.batteryCharging = false
	o.difference = 0
	o.night = false
	o.hasLinkedBanks = false
	o.networkRechargeText = nil
	o.networkCharge = 0
	o.networkDrain  = 0

	o.fps = getCore():getOptionUIRenderFPS()
   return o
end

function PSRWindowsSumaryTab.measureTexts()
	local textTable = {
		left = {
			"IGUI_PSRWindowsSumaryTab_PanelsStatus",
			"IGUI_PSRWindowsSumaryTab_PanelCount",
			"IGUI_PSRWindowsSumaryTab_BatteryLevel",
			"IGUI_PSRWindowsSumaryTab_BatteryStatus",
			"IGUI_PSRWindowsSumaryTab_ChargedIn",
			"IGUI_PSRWindowsSumaryTab_DischargedIn",
			"IGUI_PSRWindowsSumaryTab_BatteryRemaining",
			"IGUI_PSRWindow_Details_LinkedNetwork",
			"IGUI_PSRWindow_Details_NetworkRecharge",
			"IGUI_PSRWindowsSumaryTab_NetworkReserves",
		},
		right = {
			"IGUI_PSRWindowsSumaryTab_NoEnoughPanels",
			"IGUI_PSRWindowsSumaryTab_NoEnoughSun",
			"IGUI_PSRWindowsSumaryTab_FullyCharged",
			"IGUI_PSRWindowsSumaryTab_FullyDischarged",
			"IGUI_PSRWindowsSumaryTab_NotCharging",
			"IGUI_PSRWindowsSumaryTab_NoBatteries",
		}
	}

	local max = { left = 0, right = 0}
	for type,texts in pairs(textTable) do
		for _,text in ipairs(texts) do
			local width = getTextManager():MeasureStringX(UIFont.Small, getText(text))
			max[type] = math.max(max[type], width)
		end
	end

	return max
end

PSR.StatusWindowSummaryView = PSRWindowsSumaryTab