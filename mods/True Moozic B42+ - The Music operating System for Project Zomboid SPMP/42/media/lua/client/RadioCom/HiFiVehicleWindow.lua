require "ISUI/ISCollapsableWindow"
require "RadioCom/RadioWindowModules/RWMElement"
require "RadioCom/RadioWindowModules/RWMPanel"
require "RadioCom/RadioWindowModules/RWMGeneral"
require "RadioCom/RadioWindowModules/RWMPower"
require "RadioCom/RadioWindowModules/RWMGridPower"
require "RadioCom/RadioWindowModules/RWMSignal"
require "RadioCom/RadioWindowModules/RWMVolume"
require "RadioCom/RadioWindowModules/RWMChannel"
require "RadioCom/Panels/HiFiCDPanel"
require "RadioCom/Panels/HiFiCassettePanel"

HiFiVehicleWindow = ISCollapsableWindow:derive("HiFiVehicleWindow")
HiFiVehicleWindow.instances = {}

------------------------------------------------------------------------
-- Volume module with the MP client-volume checkbox (same behavior as
-- HiFiVolumePanel / TCRWMVolume: when enabled, the slider controls the
-- LOCAL volume multiplier instead of the shared device volume)
------------------------------------------------------------------------

local HiFiVehicleVolume = RWMVolume:derive("HiFiVehicleVolume")

function HiFiVehicleVolume:createChildren()
    RWMVolume.createChildren(self)
    -- Parent binds the literal RWMVolume.onVolumeChange; rebind to ours.
    self.volumeBar.onVolumeChange = HiFiVehicleVolume.onVolumeChange

    if isClient() then
        self.clientVolBox = ISTickBox:new(self.volumeBar:getX(), self.volumeBar:getBottom()+4, 18, 18, "", self, HiFiVehicleVolume.onClientVolumeToggle)
        self.clientVolBox:initialise()
        self.clientVolBox:addOption(getText("IGUI_TCClientVolume"))
        self.clientVolBox.tooltip = getText("IGUI_TCClientVolume_Tooltip")
        self.clientVolBox.selected[1] = false
        self:addChild(self.clientVolBox)
        self:setHeight(self.clientVolBox:getBottom() + 6)
    end
end

function HiFiVehicleVolume:clientVolKey()
    return TCMusic.getClientVolumeKeyFor and TCMusic.getClientVolumeKeyFor(self.device, self.deviceType) or nil
end

function HiFiVehicleVolume:onClientVolumeToggle(index, selected)
    local key = self:clientVolKey()
    if not key then return end
    if selected then
        TCMusic.setClientVolume(key, (self.deviceData and self.deviceData:getDeviceVolume()) or 1.0)
    else
        TCMusic.setClientVolume(key, nil)
    end
end

function HiFiVehicleVolume:onVolumeChange(_newVol)
    local cvKey = self:clientVolKey()
    if cvKey and TCMusic.isClientVolumeActive and TCMusic.isClientVolumeActive(cvKey) then
        -- Local mode for THIS vehicle only.
        TCMusic.setClientVolume(cvKey, _newVol / self.volumeBar:getVolumeSteps())
        return
    end
    RWMVolume.onVolumeChange(self, _newVol)
end

function HiFiVehicleVolume:update()
    local cvKey = self:clientVolKey()
    local cvActive = cvKey and TCMusic.isClientVolumeActive and TCMusic.isClientVolumeActive(cvKey) or false
    if self.clientVolBox then
        self.clientVolBox.selected[1] = cvActive
    end
    if cvActive then
        -- Local mode: the slider shows/controls this vehicle's local volume.
        ISPanel.update(self)
        self.speakerButton:setEnableControls(true)
        self.volumeBar:setEnableControls(true)
        self.volumeBar:setVolume(math.floor(((TCMusic.getClientVolume(cvKey) or 1.0) + 0.05) * self.volumeBar:getVolumeSteps()))
        return
    end
    RWMVolume.update(self)
end

------------------------------------------------------------------------
-- RWMPanel wrappers so HiFi panels work inside RWMElement
------------------------------------------------------------------------

local HiFiVehicleCDModule = RWMPanel:derive("HiFiVehicleCDModule")

function HiFiVehicleCDModule:createChildren()
    self.inner = HiFiCDPanel:new(0, 0, self.width, 0)
    self.inner:initialise()
    self:addChild(self.inner)
    self:setHeight(self.inner:getHeight())
end

function HiFiVehicleCDModule:readFromObject(_player, _device, _deviceData, _deviceType)
    RWMPanel.readFromObject(self, _player, _device, _deviceData, _deviceType)
    if self.inner then
        self.inner:readFromObject(_player, _device, _deviceData, _deviceType)
        self:setHeight(self.inner:getHeight())
    end
    return true
end

function HiFiVehicleCDModule:prerender()
    ISPanel.prerender(self)
    if self.inner then
        self.inner:setWidth(self.width)
        self:setHeight(self.inner:getHeight())
    end
end

function HiFiVehicleCDModule:update()
    RWMPanel.update(self)
end

function HiFiVehicleCDModule:clear()
    RWMPanel.clear(self)
    if self.inner and self.inner.clear then self.inner:clear() end
end

------------------------------------------------------------------------

local HiFiVehicleCassetteModule = RWMPanel:derive("HiFiVehicleCassetteModule")

function HiFiVehicleCassetteModule:createChildren()
    self.inner = HiFiCassettePanel:new(0, 0, self.width, 0)
    self.inner:initialise()
    self:addChild(self.inner)
    self:setHeight(self.inner:getHeight())
end

function HiFiVehicleCassetteModule:readFromObject(_player, _device, _deviceData, _deviceType)
    RWMPanel.readFromObject(self, _player, _device, _deviceData, _deviceType)
    if self.inner then
        self.inner:readFromObject(_player, _device, _deviceData, _deviceType)
        self:setHeight(self.inner:getHeight())
    end
    return true
end

function HiFiVehicleCassetteModule:prerender()
    ISPanel.prerender(self)
    if self.inner then
        self.inner:setWidth(self.width)
        self:setHeight(self.inner:getHeight())
    end
end

function HiFiVehicleCassetteModule:update()
    RWMPanel.update(self)
end

function HiFiVehicleCassetteModule:clear()
    RWMPanel.clear(self)
    if self.inner and self.inner.clear then self.inner:clear() end
end

------------------------------------------------------------------------
-- HiFiVehicleWindow
------------------------------------------------------------------------

function HiFiVehicleWindow.activate(_player, _deviceObject)
    local playerNum = _player:getPlayerNum()
    _player:setVariable("ExerciseStarted", false)
    _player:setVariable("ExerciseEnded", true)

    local win
    if HiFiVehicleWindow.instances[playerNum] then
        win = HiFiVehicleWindow.instances[playerNum]
    else
        local w = 320 + (getCore():getOptionFontSizeReal() * 50)
        win = HiFiVehicleWindow:new(100, 100, w, 600, _player)
        win:initialise()
        win:instantiate()
        if playerNum == 0 then
            ISLayoutManager.RegisterWindow("HiFiVehicleWindow_Layout", ISCollapsableWindow, win)
        end
        HiFiVehicleWindow.instances[playerNum] = win
    end
    win:readFromObject(_player, _deviceObject)
    win:addToUIManager()
    win:setVisible(true)

    if JoypadState.players[playerNum + 1] then
        if getFocusForPlayer(playerNum) then getFocusForPlayer(playerNum):setVisible(false) end
        if getPlayerInventory(playerNum) then getPlayerInventory(playerNum):close() end
        if getPlayerLoot(playerNum) then getPlayerLoot(playerNum):close() end
        setJoypadFocus(playerNum, win)
    end
    return win
end

function HiFiVehicleWindow.isActive(_player, _deviceObject)
    local playerNum = _player:getPlayerNum()
    if HiFiVehicleWindow.instances[playerNum] then
        return HiFiVehicleWindow.instances[playerNum]:isVisible()
    end
    return false
end

function HiFiVehicleWindow.closeIfActive(_player, _deviceObject)
    if HiFiVehicleWindow.isActive(_player, _deviceObject) then
        HiFiVehicleWindow.instances[_player:getPlayerNum()]:close()
    end
end

function HiFiVehicleWindow:initialise()
    ISCollapsableWindow.initialise(self)
end

function HiFiVehicleWindow:addModule(_module, _title, _startExpanded)
    local element = RWMElement:new(0, 0, self.width, 0, _module, _title)
    element.isExpanded = _startExpanded
    element:initialise()
    self:addChild(element)
    table.insert(self.modules, {enabled = true, element = element})
end

function HiFiVehicleWindow:createChildren()
    ISCollapsableWindow.createChildren(self)
    self.modules = {}
    local w = self.width

    self:addModule(RWMGeneral:new(0, 0, w, 0),                    getText("IGUI_RadioGeneral"),  true)
    self:addModule(RWMPower:new(0, 0, w, 0),                      getText("IGUI_RadioPower"),    true)
    self:addModule(RWMGridPower:new(0, 0, w, 0),                  getText("IGUI_RadioPower"),    true)
    self:addModule(RWMSignal:new(0, 0, w, 0),                     getText("IGUI_RadioSignal"),   true)
    self:addModule(HiFiVehicleVolume:new(0, 0, w, 0),             getText("IGUI_RadioVolume"),   true)
    self:addModule(HiFiVehicleCassetteModule:new(0, 0, w, 0),     "Cassette",                    true)
    self:addModule(HiFiVehicleCDModule:new(0, 0, w, 0),           "CD",                          true)
    self:addModule(RWMChannel:new(0, 0, w, 0),                    getText("IGUI_RadioChannel"),  true)
end

function HiFiVehicleWindow:update()
    ISCollapsableWindow.update(self)
    if self:getIsVisible() then
        if self.player and self.device and self.deviceData then
            if self.deviceType == "VehiclePart" then
                -- Close if radio was uninstalled
                if self.device:getItemType() and not self.device:getInventoryItem() then
                    self:close()
                    return
                end
                -- Close if player left the vehicle
                if not self.player:getVehicle() then
                    self:close()
                    return
                end
            elseif self.deviceType == "IsoObject" then
                local dist = 10
                if self.device:getSquare() and
                    self.player:getX() > self.device:getX() - dist and
                    self.player:getX() < self.device:getX() + dist and
                    self.player:getY() > self.device:getY() - dist and
                    self.player:getY() < self.device:getY() + dist then
                    return
                end
                self:close()
                return
            end
            return
        end
    end
    self:close()
end

function HiFiVehicleWindow:prerender()
    self:stayOnSplitScreen()
    ISCollapsableWindow.prerender(self)

    local y = self:titleBarHeight() + 1
    for _, module in ipairs(self.modules) do
        if module.enabled then
            module.element:setVisible(true)
            module.element:setY(y)
            module.element:setWidth(self.width)
            module.element:calculateHeights()
            y = y + module.element:getHeight()
        else
            module.element:setVisible(false)
        end
    end
    self:setHeight(y)
end

function HiFiVehicleWindow:stayOnSplitScreen()
    ISUIElement.stayOnSplitScreen(self, self.playerNum)
end

function HiFiVehicleWindow:render()
    ISCollapsableWindow.render(self)
end

function HiFiVehicleWindow:close()
    -- Do NOT stop audio or set isPlaying to false here.
    -- Music should keep playing after UI close / vehicle exit.
    -- It only stops when the player turns power off, or the vehicle
    -- battery dies / is removed (handled by device power logic).

    ISCollapsableWindow.close(self)
    if JoypadState.players[self.playerNum + 1] then
        if getFocusForPlayer(self.playerNum) == self then
            setJoypadFocus(self.playerNum, nil)
        end
    end
    self:removeFromUIManager()
    self:clear()
end

function HiFiVehicleWindow:clear()
    self.drawJoypadFocus = false
    self.player = nil
    self.device = nil
    self.deviceData = nil
    self.deviceType = nil
    for _, module in ipairs(self.modules) do
        if module.element and module.element.clear then
            module.element:clear()
        end
    end
end

function HiFiVehicleWindow:readFromObject(_player, _deviceObject)
    self:clear()
    self.player = _player
    self.device = _deviceObject

    if self.device then
        self.deviceType = (instanceof(self.device, "Radio") and "InventoryItem")
            or (instanceof(self.device, "IsoWaveSignal") and "IsoObject")
            or (instanceof(self.device, "VehiclePart") and "VehiclePart")
            or nil
        if self.device.getDeviceData then
            self.deviceData = self.device:getDeviceData()
            self.title = "HiFi Stereo (Vehicle)"
        end
    end

    if not self.player or not self.device or not self.deviceData or not self.deviceType then
        self:clear()
        return
    end

    -- Initialize HiFi modData on the device
    local md = self.device:getModData()
    if not md.hifiCD then md.hifiCD = {} end
    if not md.hifiTape then md.hifiTape = {} end

    -- Read into all modules
    for _, module in ipairs(self.modules) do
        local enabled = module.element:readFromObject(self.player, self.device, self.deviceData, self.deviceType)
        module.enabled = enabled ~= false
        module.element:setVisible(module.enabled)
    end
end

function HiFiVehicleWindow:new(x, y, width, height, player)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.playerNum = player:getPlayerNum()
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.pin = true
    o.isCollapsed = false
    o.title = "HiFi Stereo (Vehicle)"
    o.resizable = false
    o.drawFrame = true
    o.modules = {}
    o.device = nil
    o.deviceData = nil
    o.deviceType = nil
    o.overrideBPrompt = true
    return o
end

function HiFiVehicleWindow:onLoseJoypadFocus()
    self.drawJoypadFocus = false
end

function HiFiVehicleWindow:onGainJoypadFocus()
    self.drawJoypadFocus = true
end

function HiFiVehicleWindow:onJoypadDown(button)
    if button == Joypad.BButton then
        self:close()
    end
end

function HiFiVehicleWindow:getBPrompt()
    return getText("IGUI_RadioClose")
end
