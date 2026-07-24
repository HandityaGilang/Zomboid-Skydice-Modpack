require "ISUI/ISCollapsableWindow"
require "RadioCom/ISRadioAction"
require "RadioCom/Panels/HiFiCDPanel"
require "RadioCom/Panels/HiFiCassettePanel"
require "RadioCom/Panels/HiFiVinylPanel"
require "RadioCom/Panels/HiFiVolumePanel"

HiFiWindow = ISCollapsableWindow:derive("HiFiWindow")
HiFiWindow.instances = {}

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10
local SECTION_HDR = FONT_HGT_SMALL + 6

function HiFiWindow.activate(_player, _deviceObject)
    local playerNum = _player:getPlayerNum()
    _player:setVariable("ExerciseStarted", false)
    _player:setVariable("ExerciseEnded", true)

    local win
    if HiFiWindow.instances[playerNum] then
        win = HiFiWindow.instances[playerNum]
    else
        local w = 320 + (getCore():getOptionFontSizeReal() * 50)
        win = HiFiWindow:new(100, 100, w, 600, _player)
        win:initialise()
        win:instantiate()
        if playerNum == 0 then
            ISLayoutManager.RegisterWindow("HiFiWindow_Layout", ISCollapsableWindow, win)
        end
        HiFiWindow.instances[playerNum] = win
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

function HiFiWindow.isActive(_player, _deviceObject)
    local playerNum = _player:getPlayerNum()
    if HiFiWindow.instances[playerNum] then
        return HiFiWindow.instances[playerNum]:isVisible()
    end
    return false
end

function HiFiWindow:initialise()
    ISCollapsableWindow.initialise(self)
end

function HiFiWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local w = self.width

    -- Power button
    local pwrW = 100
    self.powerBtn = ISButton:new(UI_BORDER_SPACING, 0, pwrW, SECTION_HDR,
        getText("ContextMenu_Turn_On"), self, HiFiWindow.onTogglePower)
    self.powerBtn:initialise()
    self.powerBtn.backgroundColor = {r=0,g=0,b=0,a=0}
    self.powerBtn.backgroundColorMouseOver = {r=1,g=1,b=1,a=0.1}
    self.powerBtn.borderColor = {r=1,g=1,b=1,a=0.3}
    self:addChild(self.powerBtn)

    -- Volume panel
    self.volumePanel = HiFiVolumePanel:new(0, 0, w, 100)
    self.volumePanel:initialise()
    self:addChild(self.volumePanel)

    -- Vinyl panel
    self.vinylPanel = HiFiVinylPanel:new(0, 0, w, 100)
    self.vinylPanel:initialise()
    self:addChild(self.vinylPanel)

    -- Cassette panel
    self.cassettePanel = HiFiCassettePanel:new(0, 0, w, 100)
    self.cassettePanel:initialise()
    self:addChild(self.cassettePanel)

    -- CD panel
    self.cdPanel = HiFiCDPanel:new(0, 0, w, 100)
    self.cdPanel:initialise()
    self:addChild(self.cdPanel)
end

local dist = 10
function HiFiWindow:update()
    ISCollapsableWindow.update(self)
    if self:getIsVisible() then
        if self.deviceType and self.device and self.player and self.deviceData then
            -- Update power button label
            if self.powerBtn then
                if self.deviceData:getIsTurnedOn() then
                    self.powerBtn:setTitle(getText("ContextMenu_Turn_Off"))
                else
                    self.powerBtn:setTitle(getText("ContextMenu_Turn_On"))
                end
            end
            if self.deviceType == "IsoObject" then
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
    self:close()
end

function HiFiWindow:prerender()
    self:stayOnSplitScreen()
    ISCollapsableWindow.prerender(self)

    local y = self:titleBarHeight() + 1

    -- Power button row
    if self.powerBtn then
        self.powerBtn:setY(y)
        y = y + self.powerBtn:getHeight() + 2
    end

    -- Volume (no label needed, controls are self-explanatory)
    if self.volumePanel then
        self.volumePanel:setY(y)
        self.volumePanel:setWidth(self.width)
        y = y + self.volumePanel:getHeight() + 2
    end

    -- Vinyl section
    if self.vinylPanel then
        self:drawRect(0, y, self.width, SECTION_HDR, 0.2, 0.8, 0.6, 0.2)
        self:drawText("Vinyl", UI_BORDER_SPACING, y + 2, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
        y = y + SECTION_HDR
        self.vinylPanel:setY(y)
        self.vinylPanel:setWidth(self.width)
        y = y + math.max(self.vinylPanel:getHeight(), 1) + 2
    end

    -- Cassette section
    if self.cassettePanel then
        self:drawRect(0, y, self.width, SECTION_HDR, 0.2, 0.2, 0.8, 0.2)
        self:drawText("Cassette", UI_BORDER_SPACING, y + 2, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
        y = y + SECTION_HDR
        self.cassettePanel:setY(y)
        self.cassettePanel:setWidth(self.width)
        y = y + math.max(self.cassettePanel:getHeight(), 1) + 2
    end

    -- CD section
    if self.cdPanel then
        self:drawRect(0, y, self.width, SECTION_HDR, 0.2, 0.17, 0.69, 0.76)
        self:drawText("CD", UI_BORDER_SPACING, y + 2, 1.0, 1.0, 1.0, 1.0, UIFont.Small)
        y = y + SECTION_HDR
        self.cdPanel:setY(y)
        self.cdPanel:setWidth(self.width)
        y = y + math.max(self.cdPanel:getHeight(), 1) + 2
    end

    self:setHeight(y)
end

function HiFiWindow:stayOnSplitScreen()
    ISUIElement.stayOnSplitScreen(self, self.playerNum)
end

function HiFiWindow:render()
    ISCollapsableWindow.render(self)
end

function HiFiWindow:close()
    -- Do NOT stop audio or set isPlaying to false here.
    -- Music should keep playing after UI close.
    -- It only stops when the player turns power off.

    ISCollapsableWindow.close(self)
    if JoypadState.players[self.playerNum + 1] then
        if getFocusForPlayer(self.playerNum) == self then
            setJoypadFocus(self.playerNum, nil)
        end
    end
    self:removeFromUIManager()
    self:clear()
end

function HiFiWindow:onTogglePower()
    if self.player and self.device and self.deviceData then
        -- World radios can transiently exist without a square; vanilla ISRadioAction
        -- will NPE in canBePoweredHere() if queued in that state.
        if self.deviceType == "IsoObject" then
            local dsq = self.device.getSquare and self.device:getSquare() or nil
            if not dsq then
                return
            end
        end

        local canPower = false
        if self.deviceData:getIsBatteryPowered() and self.deviceData:getPower() > 0 then
            canPower = true
        else
            local sq = nil
            if instanceof(self.device, "IsoObject") and self.device.getSquare then
                sq = self.device:getSquare()
            elseif instanceof(self.device, "InventoryItem") then
                sq = self.player:getCurrentSquare()
            end
            if sq then
                canPower = sq:hasGridPower() or (SandboxVars.AllowExteriorGenerator and sq:haveElectricity())
            end
        end
        if canPower then
            -- Use ISRadioAction to toggle safely; it handles the Java-side
            -- square validation that setIsTurnedOn() requires internally.
            ISTimedActionQueue.add(ISRadioAction:new("ToggleOnOff", self.player, self.device))
        end
    end
end

function HiFiWindow:clear()
    self.drawJoypadFocus = false
    self.player = nil
    self.device = nil
    self.deviceData = nil
    self.deviceType = nil
    if self.volumePanel and self.volumePanel.clear then self.volumePanel:clear() end
    if self.vinylPanel and self.vinylPanel.clear then self.vinylPanel:clear() end
    if self.cassettePanel and self.cassettePanel.clear then self.cassettePanel:clear() end
    if self.cdPanel and self.cdPanel.clear then self.cdPanel:clear() end
end

function HiFiWindow:readFromObject(_player, _deviceObject)
    self:clear()
    self.player = _player
    self.device = _deviceObject

    if self.device then
        self.deviceType = (instanceof(self.device, "Radio") and "InventoryItem")
            or (instanceof(self.device, "IsoWaveSignal") and "IsoObject")
            or nil
        if self.deviceType and self.device.getDeviceData then
            self.deviceData = self.device:getDeviceData()
            self.title = "HiFi Stereo"
        end
    end

    if not self.player or not self.device or not self.deviceData or not self.deviceType then
        self:clear()
        return
    end

    local md = self.device:getModData()
    if not md.hifiCD then md.hifiCD = {} end
    if not md.hifiTape then md.hifiTape = {} end
    if not md.hifiVinyl then md.hifiVinyl = {} end

    if self.deviceType == "IsoObject" and HiFiWorldAudio then
        HiFiWorldAudio.register(self.device)
    end

    if self.volumePanel then
        self.volumePanel:readFromObject(self.player, self.device, self.deviceData, self.deviceType)
    end
    if self.vinylPanel then
        self.vinylPanel:readFromObject(self.player, self.device, self.deviceData, self.deviceType)
    end
    if self.cassettePanel then
        self.cassettePanel:readFromObject(self.player, self.device, self.deviceData, self.deviceType)
    end
    if self.cdPanel then
        self.cdPanel:readFromObject(self.player, self.device, self.deviceData, self.deviceType)
    end
end

function HiFiWindow:new(x, y, width, height, player)
    local o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    o.playerNum = player:getPlayerNum()
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.pin = true
    o.isCollapsed = false
    o.title = "HiFi Stereo"
    o.resizable = false
    o.drawFrame = true
    o.device = nil
    o.deviceData = nil
    o.deviceType = nil
    o.overrideBPrompt = true
    return o
end

function HiFiWindow:onLoseJoypadFocus()
    self.drawJoypadFocus = false
end

function HiFiWindow:onGainJoypadFocus()
    self.drawJoypadFocus = true
end

function HiFiWindow:onJoypadDown(button)
    if button == Joypad.BButton then
        self:close()
    end
end

function HiFiWindow:getBPrompt()
    return getText("IGUI_RadioClose")
end
