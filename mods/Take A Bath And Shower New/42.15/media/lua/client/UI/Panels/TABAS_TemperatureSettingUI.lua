require "ISUI/ISPanelJoypad"

TABAS_TemperatureSettingUI = ISPanelJoypad:derive("TABAS_TemperatureSettingUI")

local TABAS_Iso = require("TABAS_Iso")
local WaterReader = require("TABAS_WaterReader")
local CONST = require("UI/TABAS_PanelConst")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
local UI_BORDER_SPACING = 10
local BUTTON_HGT = FONT_HGT_SMALL + 6

function TABAS_TemperatureSettingUI.OpenPanel(playerObj, object)
    if TABAS_TemperatureSettingUI.instance == nil then
        local ui
        ui = TABAS_TemperatureSettingUI:new(0,0,400,200, object, playerObj)
        ui:initialise()
        ui:addToUIManager()
        TABAS_TemperatureSettingUI.instance = ui
        local player = playerObj:getPlayerNum()

        if JoypadState.players[player+1] then
            ui.prevFocus = JoypadState.players[player+1].focus
            setJoypadFocus(player, ui)
        end
        TABAS_TemperatureSettingUI.instance = ui
    end
    return TABAS_TemperatureSettingUI.instance
end

function TABAS_TemperatureSettingUI:initialise()
    ISPanelJoypad.initialise(self)
end
function TABAS_TemperatureSettingUI:createChildren()
    ISPanelJoypad.createChildren(self)

    local btnWid = 100
    local btnHgt = math.max(25, FONT_HGT_SMALL + 3 * 2)
    local padBottom = 10

    self.title = ISLabel:new (self.width/2, (BUTTON_HGT-FONT_HGT_SMALL)/2, FONT_HGT_SMALL, ISWorldObjectContextMenu.getMoveableDisplayName(self.object), 1, 1, 1, 1, UIFont.Medium, false);
    self:addChild(self.title)

    self.tempKnob = ISKnob:new(20,40,getTexture("media/ui/Knobs/KnobDial.png"), getTexture("media/ui/Knobs/TABAS_KnobBGFarhen.png"), getText("IGUI_Temperature"), self.character)
    self.tempKnob:initialise()
    self.tempKnob:instantiate()
    self.tempKnob.onMouseUpFct = TABAS_TemperatureSettingUI.ChangeKnob
    self.tempKnob.target = self
    self.tempKnob.switchSound = "ToggleTemp"
    self:addChild(self.tempKnob)

    self.tempType = ISTickBox:new(20, self.tempKnob.y + self.tempKnob.height + 10, getTextManager():MeasureStringX(UIFont.Small, getText("IGUI_Oven_Fahrenheit")) + 20, 18, "", self, TABAS_TemperatureSettingUI.onChangeTempType)
    self.tempType:initialise()
    self.tempType:instantiate()
    self.tempType:addOption(getText("IGUI_Oven_Fahrenheit"))
    self.tempType:addOption(getText("IGUI_Oven_Celsius"))
    self.tempType.selected[1] = not getCore():isCelsius()
    self.tempType.selected[2] = getCore():isCelsius()
    self:addChild(self.tempType)

    self:changeTempType()

    self.close = ISButton:new(self:getWidth() / 2, self.tempType:getBottom() + 5, btnWid, btnHgt + 5, getText("UI_Close"), self, TABAS_TemperatureSettingUI.onClick)
    self.close.internal = "CLOSE"
    self.close:initialise()
    self.close:instantiate()
    self.close.borderColor = self.buttonBorderColor
    self:addChild(self.close)

    self:setHeight(self.close:getBottom() + padBottom)
    self:setWidth(self.tempKnob:getRight() + UI_BORDER_SPACING*2)
    
    self.title:setX((self.width - self.title.width)/2)
    self.close:setX((self.width - btnWid) / 2)

    self:addKnobValues()
    self:updateButtons()

    self:insertNewLineOfButtons(self.tempKnob, self.tempKnob)
	self:insertNewLineOfButtons(self.close)
    local col = self.borderColor
    self:drawRectBorder(0, 0, self.width, self.height, col.a, col.r, col.g, col.b);
end

function TABAS_TemperatureSettingUI:onChangeTempType(clickedOption, enabled)
    self.tempType.selected[1] = false
    self.tempType.selected[2] = false
    self.tempType.selected[clickedOption] = true
    getCore():setCelsius(self.tempType.selected[2])
    getCore():saveOptions()
    self:changeTempType()
end

function TABAS_TemperatureSettingUI:changeTempType()
    if not getCore():isCelsius() then -- farenheit
        self.tempKnob.valuesBg = getTexture("media/ui/Knobs/TABAS_KnobBGFarhen.png")
    else -- celsius
        self.tempKnob.valuesBg = getTexture("media/ui/Knobs/TABAS_KnobBGCelcius.png")
    end
end

function TABAS_TemperatureSettingUI:ChangeKnob()
    self.object:getModData().idealTemperature = self.tempKnob:getValue()
    -- send updated info once we finish dragging the knobs
    if not self.tempKnob.dragging then
        self.object:transmitModData()
    end
end

function TABAS_TemperatureSettingUI:update()
    self:updateButtons()
    if self.character:DistTo(self.object:getX(), self.object:getY()) > self.closeDist then
        self:setVisible(false)
        self:removeFromUIManager()
    end
end

function TABAS_TemperatureSettingUI:updateButtons()
    if not self.tempKnob.dragging then
        local setTempe = self.object:getModData().idealTemperature or 40
        self.tempKnob:setKnobPosition(setTempe)
    end
end

function TABAS_TemperatureSettingUI:addKnobValues()
    self.tempKnob:addValue(0, 35)
    self.tempKnob:addValue(18, 36)
    self.tempKnob:addValue(36, 37)
    self.tempKnob:addValue(54, 38)
    self.tempKnob:addValue(72, 39)
    self.tempKnob:addValue(90, 40)
    self.tempKnob:addValue(108, 41)
    self.tempKnob:addValue(126, 42)
    self.tempKnob:addValue(144, 43)
    self.tempKnob:addValue(162, 44)
    self.tempKnob:addValue(180, 45)
    self.tempKnob:addValue(220, 50)
    self.tempKnob:addValue(270, 80)
    self.tempKnob:addValue(300, 100)
end

function TABAS_TemperatureSettingUI:render()
    ISPanelJoypad.render(self)
    local waterAmount = WaterReader.getWaterAmount(self.object)
    local waterSourceCount = WaterReader.getExternalContainerCount(self.object)
    local piped = waterSourceCount > 0 and not self.object:getModData().canBeWaterPiped
    local powerd = TABAS_Iso.canHot(self.object)

    local iconScale = 20
    local x = self.tempKnob:getX() - iconScale + UI_BORDER_SPACING
    local col = piped and 1 or 0.5
    self:drawTextureScaled(self.pipedTex, x, self.tempKnob:getY(), iconScale, iconScale, 0.9, col, col, col)
    col = waterAmount > 0 and 1 or 0.5
    self:drawTextureScaled(self.waterTex, x, self.tempKnob:getY() + iconScale+10, iconScale, iconScale, 0.9, col, col, col)
    col = powerd and 1 or 0.5
    self:drawTextureScaled(self.powerdTex, x, self.tempKnob:getY() + (iconScale+10)*2, iconScale, iconScale, 0.9, col, col, col)
end

function TABAS_TemperatureSettingUI:prerender()
    ISPanelJoypad.prerender(self)
end

function TABAS_TemperatureSettingUI:onClick(button)
    if button.internal == "CLOSE" then
        TABAS_TemperatureSettingUI.instance = nil
        self:setVisible(false)
        self:removeFromUIManager()
		local player = self.character:getPlayerNum()
        if JoypadState.players[player+1] then
            setJoypadFocus(player, self.prevFocus)
        end
    end
end

function TABAS_TemperatureSettingUI:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData)
    self.joypadIndexY = 1
    self.joypadIndex = 1
    self.joypadButtons = self.joypadButtonsY[self.joypadIndexY]
    self.joypadButtons[self.joypadIndex]:setJoypadFocused(true)
    self:setISButtonForB(self.close)
end

function TABAS_TemperatureSettingUI:onJoypadDown(button)
    ISPanelJoypad.onJoypadDown(self, button)
    if button == Joypad.BButton then
        self:onClick(self.close)
    end
end

function TABAS_TemperatureSettingUI:onLoseJoypadFocus(joypadData)
	ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
    self:clearJoypadFocus(joypadData)
end

--************************************************************************--
--** TABAS_TemperatureSettingUI:new
--**
--************************************************************************--
function TABAS_TemperatureSettingUI:new(x, y, width, height, object, character)
    local o = {}
    o = ISPanelJoypad:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
	local player = character:getPlayerNum()
    if y == 0 then
        o.y = getPlayerScreenTop(player) + (getPlayerScreenHeight(player) - height) / 2
        o:setY(o.y)
    end
    if x == 0 then
        o.x = getPlayerScreenLeft(player) + (getPlayerScreenWidth(player) - width) / 2
        o:setX(o.x)
    end
    o.backgroundColor.a = 0.75
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.buttonBorderColor = {r=1, g=1, b=1, a=0.1}
    o.width = width
    o.height = height
    o.character = character
    o.object = object
    o.closeDist = 6

    local texture = CONST.TEXTURE
    o.waterTex = texture.waterIcon
    o.pipedTex = texture.pipedIcon
    o.powerdTex = texture.powerdIcon

    o.moveWithMouse = true
	o.anchorLeft = true
    o.anchorRight = true
    o.anchorTop = true
    o.anchorBottom = true
    return o
end
