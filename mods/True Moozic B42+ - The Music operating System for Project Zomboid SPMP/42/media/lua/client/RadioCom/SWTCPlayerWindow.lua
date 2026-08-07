
require "ISUI/ISCollapsableWindow"
require "RadioCom/RadioWindowModules/RWMGeneral"
require "RadioCom/RadioWindowModules/RWMPower"
require "RadioCom/RadioWindowModules/RWMGridPower"
require "RadioCom/RadioWindowModules/RWMSignal"
require "RadioCom/RadioWindowModules/SWTCRWMVolume"
require "RadioCom/RadioWindowModules/RWMMicrophone"
require "RadioCom/RadioWindowModules/RWMMedia"
require "RadioCom/RadioWindowModules/RWMChannel"
require "RadioCom/RadioWindowModules/RWMChannelTV"
require "RadioCom/RadioWindowModules/RWMElement"
require "RadioCom/RadioWindowModules/SWTCRWMMedia"

SWTCPlayerWindow = ISCollapsableWindow:derive("SWTCPlayerWindow")
SWTCPlayerWindow.instances = {}

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local BUTTON_HGT = FONT_HGT_SMALL + 6
local UI_BORDER_SPACING = 10

function SWTCPlayerWindow.activate(_player, _deviceObject)
    local playerNum = _player:getPlayerNum()    
    local cdWindow
    _player:setVariable("ExerciseStarted", false)
    _player:setVariable("ExerciseEnded", true)
    
    if SWTCPlayerWindow.instances[playerNum] then
        cdWindow = SWTCPlayerWindow.instances[playerNum]
    else
        cdWindow = SWTCPlayerWindow:new(100, 100, 250 + (getCore():getOptionFontSizeReal() * 50), 500, _player)
        cdWindow:initialise()
        cdWindow:instantiate()
        
        if playerNum == 0 then
            ISLayoutManager.RegisterWindow('SWTCPlayerWindow_Layout', ISCollapsableWindow, cdWindow)
        end
        SWTCPlayerWindow.instances[playerNum] = cdWindow
    end    
    cdWindow:readFromObject(_player, _deviceObject)
    cdWindow:addToUIManager()
    cdWindow:setVisible(true)
    
    if JoypadState.players[playerNum+1] then
        if getFocusForPlayer(playerNum) then 
            getFocusForPlayer(playerNum):setVisible(false) 
        end
        if getPlayerInventory(playerNum) then 
            getPlayerInventory(playerNum):close() 
        end
        if getPlayerLoot(playerNum) then 
            getPlayerLoot(playerNum):close() 
        end
        setJoypadFocus(playerNum, cdWindow)
    end
    
    return cdWindow
end

function SWTCPlayerWindow.isActive(_player, _deviceObject)
    local playerNum = _player:getPlayerNum()
    
    if SWTCPlayerWindow.instances[playerNum] then
        local cdWindow = SWTCPlayerWindow.instances[playerNum]
        cdWindow:readFromObject(_player, _deviceObject)
        return cdWindow:isVisible()
    end
    
    return false
end

function SWTCPlayerWindow.closeIfActive(_player, _deviceObject)
    local playerNum = _player:getPlayerNum()
    
    if SWTCPlayerWindow.instances[playerNum] then
        local cdWindow = SWTCPlayerWindow.instances[playerNum]
        cdWindow:readFromObject(_player, _deviceObject)
        cdWindow:close()
    end
end

function SWTCPlayerWindow:initialise()
    ISCollapsableWindow.initialise(self)
end

function SWTCPlayerWindow:close()
    if self.device and self.device.isActivated and self.device:isActivated() then
        self.device:setActivated(false)
    end
    if self.player and self.device then
        local isAccessible = false
        
        if self.player:getPrimaryHandItem() == self.device or 
           self.player:getSecondaryHandItem() == self.device then
            isAccessible = true
        end
        
        if not isAccessible and instanceof(self.device, "InventoryItem") and self.device:getAttachedSlot() > -1 then
            local hotbar = getPlayerHotbar(self.player:getPlayerNum())
            if hotbar and hotbar:isInHotbar(self.device) then
                isAccessible = true
            end
        end
        
        if not isAccessible and instanceof(self.device, "IsoObject") and self.device:getSquare() then
            local dist = 10
            if self.player:getX() > self.device:getX() - dist and 
               self.player:getX() < self.device:getX() + dist and 
               self.player:getY() > self.device:getY() - dist and 
               self.player:getY() < self.device:getY() + dist then
                isAccessible = true
            end
        end
        
        if not isAccessible and instanceof(self.device, "VehiclePart") and self.device:getVehicle() then
            local vehicle = self.device:getVehicle()
            local dist = 10
            if self.player:getX() > vehicle:getX() - dist and 
               self.player:getX() < vehicle:getX() + dist and 
               self.player:getY() > vehicle:getY() - dist and 
               self.player:getY() < vehicle:getY() + dist then
                isAccessible = true
            end
        end
        
        if not isAccessible then
            local deviceId = nil
            
            if instanceof(self.device, "InventoryItem") then
                deviceId = "item_" .. self.device:getID()
            elseif instanceof(self.device, "IsoObject") then
                deviceId = "world_" .. self.device:getX() .. "_" .. self.device:getY() .. "_" .. self.device:getZ()
            elseif instanceof(self.device, "VehiclePart") and self.device:getVehicle() then
                deviceId = "vehicle_" .. self.device:getVehicle():getId() .. "_" .. self.device:getType()
            end
            
            if deviceId and self.player:getModData().customMusicIds and self.player:getModData().customMusicIds[deviceId] then
                self.player:getEmitter():stopSound(self.player:getModData().customMusicIds[deviceId])
                self.player:getModData().customMusicIds[deviceId] = nil
                
                if self.player:getModData().originalMusicVolume then
                    getCore():setOptionMusicVolume(self.player:getModData().originalMusicVolume)
                    self.player:getModData().originalMusicVolume = nil
                end
                
                if self.device:getModData().customMusic then
                    self.device:getModData().customMusic.isPlaying = false
                end
            end
        end
    end
    
    ISCollapsableWindow.close(self)
    if JoypadState.players[self.playerNum+1] then
        if getFocusForPlayer(self.playerNum)==self or (self.subFocus and getFocusForPlayer(self.playerNum)==self.subFocus) then
            setJoypadFocus(self.playerNum, nil)
        end
    end
    self:removeFromUIManager()
    self:clear()
    self.subFocus = nil
end

function SWTCPlayerWindow:addModule(_modulePanel, _moduleName, _enable)
    local module = {}
    module.enabled = _enable
    module.element = RWMElement:new(0, 0, self.width, 0, _modulePanel, _moduleName, self)
    table.insert(self.modules, module)
    self:addChild(module.element)
end

function SWTCPlayerWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    
    self:addModule(RWMGeneral:new(0, 0, self.width, 0), getText("IGUI_RadioGeneral"), true)
    self:addModule(RWMPower:new(0, 0, self.width, 0), getText("IGUI_RadioPower"), true)
    self:addModule(RWMGridPower:new(0, 0, self.width, 0), getText("IGUI_RadioPower"), true)
    self:addModule(RWMSignal:new(0, 0, self.width, 0), getText("IGUI_RadioSignal"), true)
    self:addModule(SWTCRWMVolume:new(0, 0, self.width, 0), getText("IGUI_RadioVolume"), true)
    self:addModule(RWMMicrophone:new(0, 0, self.width, 0), getText("IGUI_RadioMicrophone"), true)
    self:addModule(RWMChannel:new(0, 0, self.width, 0), getText("IGUI_RadioChannel"), true)
    self:addModule(RWMChannelTV:new(0, 0, self.width, 0), getText("IGUI_RadioChannel"), true)
    local mediaPanel = SWTCRWMMedia:new(0, 0, self.width, 0)
    mediaPanel.parentWindow = self
    self.mediaPanel = mediaPanel
    self:addModule(mediaPanel, getText("IGUI_RadioMedia"), true)
end

local dist = 10
function SWTCPlayerWindow:update()
    ISCollapsableWindow.update(self)
    
    if self:getIsVisible() then
        if self.deviceData and self.deviceType == "VehiclePart" then
            local part = self.deviceData:getParent()
            if part and part:getItemType() and not part:getItemType():isEmpty() and not part:getInventoryItem() then
                self:close()
                return
            end
        end

        if self.deviceType and self.device and self.player and self.deviceData then		
            if self.deviceType == "InventoryItem" then 
                local isAccessible = false
                
                if self.player:getPrimaryHandItem() == self.device or 
                   self.player:getSecondaryHandItem() == self.device then
                    isAccessible = true
                end
                
                if not isAccessible and self.device:getAttachedSlot() > -1 then
                    local hotbar = getPlayerHotbar(self.player:getPlayerNum())
                    if hotbar and hotbar:isInHotbar(self.device) then
                        isAccessible = true
                    end
                end
                
                if isAccessible then
                    return
                end
            elseif self.deviceType == "IsoObject" or self.deviceType == "VehiclePart" then 
                if self.device:getSquare() and 
                   self.player:getX() > self.device:getX() - dist and 
                   self.player:getX() < self.device:getX() + dist and 
                   self.player:getY() > self.device:getY() - dist and 
                   self.player:getY() < self.device:getY() + dist then
                    return
                end
            end
        end
    end

    if self.deviceData and self.deviceType == "InventoryItem" then        
        self.deviceData:setIsTurnedOn(false)
    end

    self:close()
end

function SWTCPlayerWindow:prerender()
    self:stayOnSplitScreen()
    ISCollapsableWindow.prerender(self)
    
    local cnt = 0
    local ymod = self:titleBarHeight() + 1
    for i = 1, #self.modules do
        if self.modules[i].enabled then
            self.modules[i].element:setY(ymod)
            ymod = ymod + self.modules[i].element:getHeight() + 1
        else
            self.modules[i].element:setVisible(false)
        end
    end
    self:setHeight(ymod)
end

function SWTCPlayerWindow:stayOnSplitScreen()
    ISUIElement.stayOnSplitScreen(self, self.playerNum)
end

function SWTCPlayerWindow:render()
    ISCollapsableWindow.render(self)
end

function SWTCPlayerWindow:clear()
    self.drawJoypadFocus = false
    self.player = nil
    self.device = nil
    self.deviceData = nil
    self.deviceType = nil
    self.hotKeyPanels = {}
    
    for i = 1, #self.modules do
        self.modules[i].enabled = false
        self.modules[i].element:clear()
    end
end

function SWTCPlayerWindow:readFromObject(_player, _deviceObject)
    self:clear()
    self.player = _player
    self.device = _deviceObject
    
    if self.device then
        self.deviceType = (instanceof(self.device, "Radio") and "InventoryItem") or
                         (instanceof(self.device, "IsoWaveSignal") and "IsoObject") or
                         (instanceof(self.device, "VehiclePart") and "VehiclePart")
        
        if self.deviceType and self.device.getDeviceData then
            self.deviceData = self.device:getDeviceData()
            self.title = self.deviceData:getDeviceName() or "Unknown Device"
        end
    end
    
    if not self.player or not self.device or not self.deviceData or not self.deviceType then
        self:clear()
        return
    end
    
    for i = 1, #self.modules do
        self.modules[i].enabled = self.modules[i].element:readFromObject(self.player, self.device, self.deviceData, self.deviceType)
        self.modules[i].element:setVisible(self.modules[i].enabled)
        
        if self.modules[i].enabled then
            if self.modules[i].element.titleText == getText("IGUI_RadioPower") then
                self.hotKeyPanels.power = self.modules[i].element.subpanel
            elseif self.modules[i].element.titleText == getText("IGUI_RadioVolume") then
                self.hotKeyPanels.volume = self.modules[i].element.subpanel
            elseif self.modules[i].element.titleText == getText("IGUI_RadioMicrophone") then
                self.hotKeyPanels.microphone = self.modules[i].element.subpanel
            end
        end
    end
end

function SWTCPlayerWindow:new(x, y, width, height, player)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.x = x
    o.y = y
    o.player = player
    o.playerNum = player:getPlayerNum()
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.width = width
    o.height = height
    o.anchorLeft = true
    o.anchorRight = false
    o.anchorTop = true
    o.anchorBottom = false
    o.pin = true
    o.isCollapsed = false
    o.collapseCounter = 0
    o.title = "Custom CD Player - No Limits"
    o.resizable = false
    o.drawFrame = true
    
    o.device = nil
    o.deviceData = nil
    o.modules = {}
    o.overrideBPrompt = true
    o.subFocus = nil
    o.hotKeyPanels = {}
    o.isJoypadWindow = false
    
    return o
end

function SWTCPlayerWindow:onLoseJoypadFocus(joypadData)
    self.drawJoypadFocus = false
end

function SWTCPlayerWindow:onGainJoypadFocus(joypadData)
    self.drawJoypadFocus = true
end

local interval = 20
function SWTCPlayerWindow:onJoypadDirUp()
    self:setY(self:getY()-interval)
end

function SWTCPlayerWindow:onJoypadDirDown()
    self:setY(self:getY()+interval)
end

function SWTCPlayerWindow:onJoypadDirLeft()
    self:setX(self:getX()-interval)
end

function SWTCPlayerWindow:onJoypadDirRight()
    self:setX(self:getX()+interval)
end

function SWTCPlayerWindow:onJoypadDown(button)
    if button == Joypad.AButton and self.hotKeyPanels.power then
        self.hotKeyPanels.power:onJoypadDown(Joypad.AButton)
    elseif button == Joypad.BButton then
        self:close()
    elseif button == Joypad.YButton and self.hotKeyPanels.volume then
        self.hotKeyPanels.volume:onJoypadDown(Joypad.YButton)
    elseif button == Joypad.XButton and self.hotKeyPanels.microphone then
        self.hotKeyPanels.microphone:onJoypadDown(Joypad.AButton)
    elseif button == Joypad.LBumper then
        self:unfocusSelf(false)
    elseif button == Joypad.RBumper then
        self:focusNext()
    end
end

function SWTCPlayerWindow:getAPrompt()
    if self.hotKeyPanels.power then
        return getText("IGUI_Hotkey")..": "..self.hotKeyPanels.power:getAPrompt()
    end
    return nil
end

function SWTCPlayerWindow:getBPrompt()
    return getText("IGUI_RadioClose")
end

function SWTCPlayerWindow:getXPrompt()
    if self.hotKeyPanels.microphone then
        return getText("IGUI_Hotkey")..": "..self.hotKeyPanels.microphone:getAPrompt()
    end
    return nil
end

function SWTCPlayerWindow:getYPrompt()
    if self.hotKeyPanels.volume then
        return getText("IGUI_Hotkey")..": "..self.hotKeyPanels.volume:getYPrompt()
    end
    return nil
end

function SWTCPlayerWindow:getLBPrompt()
    return getText("IGUI_RadioReleaseFocus")
end

function SWTCPlayerWindow:getRBPrompt()
    return getText("IGUI_RadioSelectInner")
end

function SWTCPlayerWindow:unfocusSelf()
    setJoypadFocus(self.playerNum, nil)
end

function SWTCPlayerWindow:focusSelf()
    self.subFocus = nil
    setJoypadFocus(self.playerNum, self)
end

function SWTCPlayerWindow:isValidPrompt()
    return (self.player and self.device and self.deviceData)
end

function SWTCPlayerWindow:focusNext(_up)
    local first = nil
    local last = nil
    local found = false
    local nextFocus = nil
    for i=1,#self.modules do
        if self.modules[i].enabled then
            if not first then first = self.modules[i] end
            if found and not _up and not nextFocus then
                nextFocus = self.modules[i]
            end
            if self.subFocus and self.subFocus==self.modules[i] then
                found = true
                if last~=nil and _up then
                    nextFocus = last
                end
            end
            last = self.modules[i]
        end
    end
    if not nextFocus then
        if _up then
            nextFocus = last
        else
            nextFocus = first
        end
    end
    self:setSubFocus(nextFocus)
end

function SWTCPlayerWindow:setSubFocus(_newFocus)
    if not _newFocus or not _newFocus.element then
        self:focusSelf()
    else
        self.subFocus = _newFocus
        _newFocus.element:setFocus(self.playerNum, self)
    end
end