require "ISUI/ISCollapsableWindow"
local PSR = require "PSR/Utilities"

local PSRStatusWindow = ISCollapsableWindow:derive("PSRStatusWindow")

function PSRStatusWindow:new(x, y, width, height)
	local o = ISCollapsableWindow.new(self,x, y, width, height)
	o.title = getText("IGUI_PSRWindowsStatus_Title")
	o:setResizable(false)

	PSRStatusWindow.instance = o
	return o
end

function PSRStatusWindow:createChildren()
	ISCollapsableWindow.createChildren(self);
	local th = self:titleBarHeight()
	self.panel = ISTabPanel:new(0, th, self.width, self.height-th)
	self.panel:initialise()
	self.panel.equalTabWidth = false
	self:addChild(self.panel)

	self.summaryView = PSR.StatusWindowSummaryView:new(0, 8, self.width, self.height-8)
	self.summaryView:initialise()
    self.summaryView.infoText = getText("IGUI_PSRWindowsSumaryTab_InfoText")
	self.panel:addView(getText("IGUI_PSRWindowsSumaryTab_TabTitle"), self.summaryView)
	self:setInfo(self.summaryView.infoText) --need first time we open window

	self.detailsView = PSR.StatusWindowDetailsView:new(0, 8, self.width, self.height-8)
	self.detailsView:initialise()
	self.panel:addView(getText("IGUI_PSRWindow_Details_TabTitle"), self.detailsView)

	self.debugView = PSR.StatusWindowDebugView:new(0, 8, 200, 25)
	self.debugView:initialise()
	self.panel:addView("Debug", self.debugView)
end

function PSRStatusWindow.OnOpenPanel(player,square)
	local instance = PSRStatusWindow.instance
	if not instance then
		instance = PSRStatusWindow:new(100, 100, 580, 400)
		if ISLayoutManager and ISLayoutManager.RegisterWindow then
			ISLayoutManager.RegisterWindow('PSRstatuswindow', PSRStatusWindow, instance)
		end
	else
		if instance.panel.activeView and instance.panel:getActiveViewIndex() ~= 1 then
			instance.panel:activateView(getText("IGUI_PSRWindowsSumaryTab_TabTitle"))
		end
		instance.summaryView.currentFrame = 0
	end

	instance.player = player
	instance.playerObj = getSpecificPlayer(player)
	instance.square = square
	instance.luaPB = PSR.PBSystem_Client:getLuaObjectAt(square:getX(),square:getY(),square:getZ())
	if not instance.luaPB then
		local PowerBank = require("PSR/Powerbank/PowerBankObject_Client")
		local isoGen = PSR.PBSystem_Client:getIsoObjectOnSquare(square)
		if isoGen then
			local pb = { x = square:getX(), y = square:getY(), z = square:getZ(), luaSystem = PSR.PBSystem_Client }
			setmetatable(pb, PowerBank)
			pb:updateFromIsoObject()
			instance.luaPB = pb
		end
	end

	instance:addToUIManager()
end

function PSRStatusWindow:close()
	self:removeFromUIManager()
	if JoypadState.players[self.player+1] then setPrevFocusForPlayer(self.player) end
end

PSR.StatusWindow = PSRStatusWindow