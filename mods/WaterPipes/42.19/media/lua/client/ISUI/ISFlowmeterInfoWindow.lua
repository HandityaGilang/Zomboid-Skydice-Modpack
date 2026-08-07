require "ISUI/ISCollapsableWindow"

ISFlowmeterInfoWindow = ISCollapsableWindow:derive("ISFlowmeterInfoWindow")
ISFlowmeterInfoWindow.windows = {}

function ISFlowmeterInfoWindow:createChildren()
	ISCollapsableWindow.createChildren(self)
	self.panel = ISToolTip:new()
	self.panel.followMouse = false
	self.panel:initialise()
	self:setObject(self.object)
	self:addView(self.panel)
end

function ISFlowmeterInfoWindow:update()
	ISCollapsableWindow.update(self)
	
	self.panel.maxLineWidth = 400
	self.panel.description = ISFlowmeterInfoWindow.getRichText(self.object, true);

	if self:getIsVisible() and (not self.object or self.object:getObjectIndex() == -1) then
		if self.joyfocus then
			self.joyfocus.focus = nil
			updateJoypadFocus(self.joyfocus)
		end
		self:removeFromUIManager()
		return
	end

	self:setWidth(self.panel:getWidth())
	self:setHeight(self:titleBarHeight() + self.panel:getHeight())
end

function ISFlowmeterInfoWindow:setObject(object)
	self.object = object
	self.panel:setName("Flowmeter")
	self.panel:setTexture(object:getTextureName())
--	self.panel.description = ISFlowmeterInfoWindow.getRichText(object, true)
end

function ISFlowmeterInfoWindow.getRichText(object)

    local flowmeter = WPVirtual.FlowmeterGet(object:getX(), object:getY(), object:getZ())

    local d = ""

    if not flowmeter then return "" end

    d = d .. "<RGB:1,1,1>" .. getText("ContextMenu_WP_Flow") .. ": <SPACE>"
    d = d .. string.format("%.2f", flowmeter.f / 100) .. "L/m <LINE>"
    
	return d
end

function ISFlowmeterInfoWindow:onGainJoypadFocus(joypadData)
	self.drawJoypadFocus = true
end

function ISFlowmeterInfoWindow:onJoypadDown(button)
	if button == Joypad.BButton then
		self:removeFromUIManager()
		setJoypadFocus(self.playerNum, nil)
	end
end

function ISFlowmeterInfoWindow:close()
	self:removeFromUIManager()
end

function ISFlowmeterInfoWindow:new(x, y, character, object)
	local width = 320
	local height = 16 + 64 + 16 + 16
	local o = ISCollapsableWindow:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.playerNum = character:getPlayerNum()
	o.object = object
	o:setResizable(false)
	return o
end
