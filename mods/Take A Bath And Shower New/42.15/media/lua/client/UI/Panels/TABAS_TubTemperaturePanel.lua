require("ISUI/ISPanelJoypad")

TABAS_TubTemperaturePanel = ISPanelJoypad:derive("TABAS_TubTemperaturePanel")

local TABAS_Utils = require("TABAS_Utils")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_Panel = require("UI/TABAS_PanelUtils")
local TABAS_Common = require("ContextMenu/TABAS_ContextMenuCommon")
local TFC_Menu = require("TubFluidContainer/TABAS_TubFluidContainerMenu")

local CONST = require("UI/TABAS_PanelConst")
local FONT_HGT_SMALL = CONST.SCALE.HGT_SMALL
local HGT_BUTTON = CONST.SCALE.HGT_BUTTON
local BORDER_SPACING = CONST.SCALE.BORDER_SPACING

function TABAS_TubTemperaturePanel:initialise()
    ISPanelJoypad.initialise(self)
end

function TABAS_TubTemperaturePanel:createChildren()
    local btnScale = self.btnScale
    self.status = {
        curTempe = {
            texture =  CONST.TEXTURE.tub_waterTemp,
            tooltip = getText("ContextMenu_TABAS_CurrentTemperature"),
            func = TABAS_TubTemperaturePanel.getCurrentTemp,
        },
        setTempe = {
            texture =  CONST.TEXTURE.tub_setTemp,
            tooltip = getText("ContextMenu_TABAS_SetTemperature"),
            func = TABAS_TubTemperaturePanel.getTempSetting,
        },
    }
    local x = self:getWidth()/2 - btnScale * 1.5
    local y = FONT_HGT_SMALL + BORDER_SPACING*2
    self.statusY = y
    x, y = TABAS_Panel.addStatusButtonAndLabel(self, x, y+ BORDER_SPACING)

    local btnSetTempe = self.status.setTempe
    btnSetTempe.button:setX(self:getWidth()/2 + btnScale/2)
    btnSetTempe.label.originalX = btnSetTempe.button:getX() + btnScale/2
    btnSetTempe.label.customData.x = btnSetTempe.button:getX() + btnScale/2

    x = self.status.curTempe.button:getX() + btnScale/2 - HGT_BUTTON/2
    y = y + btnScale
    self.btnReheat = TABAS_Panel.addButton(x, y, HGT_BUTTON, HGT_BUTTON, self.tex_stopIcon, "", getText("ContextMenu_TABAS_ReheatTubWater"), self, self.onClick, true)
    self.btnReheat.internal = "REHEAT"
    -- self.btnReheat.actual = "reheat" -- can be "reheat", "stop"
    self:updateButtons()

    x = self.status.setTempe.button:getX() + btnScale/2 - HGT_BUTTON/2
    self.btnSetTempe = TABAS_Panel.addButton(x, y, HGT_BUTTON, HGT_BUTTON, self.tex_SetTempeIcon, "", getText("ContextMenu_TABAS_SetTemperature"), self, self.onClick, true)
    self.btnSetTempe.internal = "SETTEMPE"

    self:setHeight(self.btnSetTempe:getBottom() + BORDER_SPACING*2)
end

function TABAS_TubTemperaturePanel.getCurrentTemp(tfc_Base)
    local currentTemperature = tfc_Base:getWaterTemperature()
    return TABAS_Utils.formatedCelsiusOrFahrenheit(currentTemperature)
end

function TABAS_TubTemperaturePanel.getTempSetting(tfc_Base)
    local setTemperature = tfc_Base:getBathData("idealTemperature") or 40
    return TABAS_Utils.formatedCelsiusOrFahrenheit(setTemperature)
end

function TABAS_TubTemperaturePanel:getCurrentTemperature()
    return self.tfc_Base:getWaterTemperature()
end

function TABAS_TubTemperaturePanel:getTargetTemperature()
    return self.tfc_Base:getBathData("idealTemperature") or 40
end

function TABAS_TubTemperaturePanel:update()
    if self._managedByParent then return end
    self:updateButtons()
    self:refreshStatus(false)
end

function TABAS_TubTemperaturePanel:updateButtons()
    local btnReheatActual
    if self.tfc_Base:isActivated("reheat") then
        btnReheatActual = "stop"
    else
        btnReheatActual = "reheat"
    end
    if self.btnReheat.actual ~= btnReheatActual then
        if btnReheatActual == "reheat" then
            self.btnReheat:setImage(self.tex_ReheatIcon)
            self.btnReheat:setTooltip(getText("ContextMenu_TABAS_ReheatTubWater"))
        else
            self.btnReheat:setImage(self.tex_stopIcon)
            self.btnReheat:setTooltip(getText("ContextMenu_TABAS_ReheatTubWaterStop"))
        end
        self.btnReheat.actual = btnReheatActual
    end
    local enable = true
    if self.btnReheat.actual == "reheat" then
        if not self.tfc_Base:hasTfc() or not self.tfc_Base:hasFluid() or not TABAS_Iso.canHot(self.tfc_Base.bathObject) then
            enable = false
        else
            local currentTempe = self:getCurrentTemperature()
            local idealTemperature = self:getTargetTemperature() or 0
            if currentTempe >= idealTemperature or self.tfc_Base:isActivated() then
                enable = false
            end
        end
    end
    if self.notAvailable then
        -- self.btnSetTempe:setEnable(false)
        self.btnReheat:setEnable(false)
    else
        -- self.btnSetTempe:setEnable(true)
        self.btnReheat:setEnable(enable)
    end
end

function TABAS_TubTemperaturePanel:onClick(_btn)
    if _btn.internal == "REHEAT" then
        if self.btnReheat.actual == "reheat" then
            TFC_Menu.onReheatTubWater(self.tfc_Base, self.playerObj:getPlayerNum(), true)
        elseif self.btnReheat.actual == "stop" then
            TFC_Menu.onReheatTubWater(self.tfc_Base, self.playerObj:getPlayerNum(), false)
        end
    elseif _btn.internal == "SETTEMPE" then
        TABAS_Common.onOpenSetTempeUI(self.tfc_Base.bathObject, self.playerObj)
    end
end

function TABAS_TubTemperaturePanel:prerender()
    ISPanelJoypad.prerender(self)

    local currentTempe = self:getCurrentTemperature()
    if self.tfc_Base:hasFluid() then
        if currentTempe >= 44 then
            self:drawTextureScaled(self.tex_cautionIcon, BORDER_SPACING, BORDER_SPACING, FONT_HGT_SMALL, FONT_HGT_SMALL, 1, 0.9, 0.3, 0.1)
        elseif currentTempe < 36 then
            self:drawTextureScaled(self.tex_cautionIcon, BORDER_SPACING, BORDER_SPACING, FONT_HGT_SMALL, FONT_HGT_SMALL, 1, 0.5, 0.8, 0.9)
        end
    end

    self:drawTextCentre(self.title, self:getWidth() / 2, BORDER_SPACING, self.labelColor.r, self.labelColor.g, self.labelColor.b, self.labelColor.a, UIFont.Small)
    for k, v in pairs(self.status) do
        TABAS_Panel.prerenderStatusBox(self, v)
    end
end

function TABAS_TubTemperaturePanel:render()
    ISPanelJoypad.render(self)

    for _, v in pairs(self.status) do
        TABAS_Panel.renderStatusValue(self, v)
    end
end

function TABAS_TubTemperaturePanel:refreshStatus(force)
    if not self.status then return end
    TABAS_Panel.refreshStatusTable(self.status, self.tfc_Base, force == true)
end

function TABAS_TubTemperaturePanel:onLoseJoypadFocus(joypadData)
    ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
end

function TABAS_TubTemperaturePanel:new (x, y, playerObj, tfc_Base)
    local btnScale = HGT_BUTTON * 1.25
    local width = btnScale * 5 + BORDER_SPACING * 4
    local height = btnScale + FONT_HGT_SMALL + BORDER_SPACING * 4 + BORDER_SPACING * 2

    local o = ISPanelJoypad:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y
    o.notAvailable = false

    local colors = CONST.COLOR
    o.backgroundColor = colors.backgroundColor
    o.labelColor = colors.labelColor
    o.textColor = colors.textColor

    o.btnScale = btnScale
    o.title = getText("IGUI_TABAS_BathtubInfo_Temperature")
    o.tex_ReheatIcon = getTexture("media/ui/Icons/tabas_tubReheat.png")
    o.tex_stopIcon = getTexture("media/ui/Icons/tabas_stopIcon.png")
    o.tex_SetTempeIcon = getTexture("media/ui/Icons/tabas_temperatureSetting.png")
    o.tex_cautionIcon = CONST.TEXTURE.cautionIcon
    o.width = width
    o.height = height

    o.playerObj = playerObj
    o.tfc_Base = tfc_Base
    return o
end
