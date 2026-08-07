require("ISUI/ISPanelJoypad")

TABAS_BathActionPanel = ISPanelJoypad:derive("TABAS_BathActionPanel")

local TABAS_Panel = require("UI/TABAS_PanelUtils")

local CONST = require("UI/TABAS_PanelConst")
local FONT_HGT_SMALL = CONST.SCALE.HGT_SMALL
local FONT_HGT_MEDIUM = CONST.SCALE.HGT_MEDIUM
local BETWEEN_SPACING = CONST.SCALE.BETWEEN_SPACING
local BORDER_SPACING = CONST.SCALE.BORDER_SPACING

function TABAS_BathActionPanel:initialise()
    ISPanelJoypad.initialise(self)
end

function TABAS_BathActionPanel:createChildren()
    ISPanelJoypad.createChildren(self)

    self.btnScale = FONT_HGT_SMALL * 1.25
    local x = BORDER_SPACING
    local y = BORDER_SPACING
    local btnScale = self.btnScale
    local takeBathWidth = self.width - btnScale * 2 - BETWEEN_SPACING * 2 - BORDER_SPACING * 2

    self.btnBathActions = TABAS_Panel.addButton(x, y, btnScale, btnScale, self.tex_bathActions, nil, nil, self, self.onClick, true)
    self.btnBathActions.internal = "BATH_ACTIONS"
    self.btnBathActions:setEnable(false)
    local text = self.text_bathActions
    if getJoypadData(self.playerObj:getPlayerNum()) then
        text = text .. " <BR> <RGB:0.5,1,0.5> " .. getText("ContextMenu_TABAS_BathActionRadial_tooltip2")
    end
    self.btnBathActions:setTooltip(text)

    x = self.btnBathActions:getRight() + BETWEEN_SPACING
    self.btnTakeBath = TABAS_Panel.addButton(x, y, takeBathWidth, FONT_HGT_MEDIUM, nil, self.text_takeBath, nil, self, self.onClick, true)
    self.btnTakeBath.internal = "TAKEBATH"
    self.btnTakeBath:setFont(UIFont.Medium)

    x = self.btnTakeBath:getRight() + BETWEEN_SPACING
    self.btnConfig = TABAS_Panel.addButton(x, y, btnScale, btnScale, self.tex_config, nil, nil, self, self.onClick, true)
    self.btnConfig.internal = "CONFIG"
    self.btnConfig:setTooltip(self.text_config)
end

function TABAS_BathActionPanel:setTitleWidth(width)
    self.btnTakeBath:setWidth(width - self.btnScale*2 - BETWEEN_SPACING * 2 - BORDER_SPACING * 2)
    self.btnConfig:setX(self.btnTakeBath:getRight() + BETWEEN_SPACING)
end

function TABAS_BathActionPanel:onClick(_btn)
    local mainPanel = self._mainPanel
    if not self._mainPanel then return end

    if _btn.internal == "CONFIG" then
        if mainPanel.configPanel.instance ~= nil then
            mainPanel.configPanel:close()
            mainPanel.configPanel = nil
        else
            mainPanel.configPanel = TABAS_ConfigPanel.openPanel(0, 0, self.playerObj)
        end
        return
    end

    if _btn.internal == "BATH_ACTIONS" then
        local TABAS_BathRadialMenu = require("UI/TABAS_BathRadialMenu")
        mainPanel:clearMainPanelFocus()
        TABAS_BathRadialMenu.display(self.playerObj)
        -- self:close()
        return
    end

    if _btn.internal == "TAKEBATH" and not mainPanel.isTakingBath then
        local actionQueue = ISTimedActionQueue.getTimedActionQueue(self.playerObj)
        local doAction = actionQueue.queue[1] ~= nil
        if doAction then return end

        local player = self.playerObj:getPlayerNum()
        local bathTime = mainPanel.autoBathTimePanel:getEntryTime()
        local isAutoMode = mainPanel.entryPanel:isAutoModeEnabled()
        local towel = mainPanel.entryPanel:getStoredItem()
        local keepClothes = not mainPanel.entryPanel.tglAutoCC.toggleState
        local makeOff = not mainPanel.entryPanel.tglMakeOff.toggleState
        local TakeBathContext = require("ContextMenu/TABAS_ContextMenuBathtub")
        TakeBathContext.onTakeBath(player, self.tfc_Base, towel, keepClothes, makeOff, bathTime, isAutoMode)
        mainPanel:markDirty()
        mainPanel._forceStatusRefresh = true
        if not mainPanel.pinned then
            mainPanel:close()
        end
    end
end

function TABAS_BathActionPanel:setTakeBathTitle(title)
    if self.btnTakeBath and self._takeBathTitle ~= title then
        self._takeBathTitle = title
        self.btnTakeBath:setTitle(title)
    end
end

function TABAS_BathActionPanel:updateAvailability(tooltip, enabled, takingBath)
    if self.btnTakeBath then
        self.btnTakeBath:setTooltip(tooltip)
        self.btnTakeBath:setEnable(enabled == true)
    end
    if self.btnBathActions then
        self.btnBathActions:setEnable(takingBath == true)
    end
end

function TABAS_BathActionPanel:new(x, y, playerObj, tfc_Base)
    local btnScale = FONT_HGT_SMALL * 1.25
    local width = btnScale * 2 + FONT_HGT_MEDIUM * 7 + BETWEEN_SPACING * 2 + BORDER_SPACING * 2
    local height = math.max(btnScale, FONT_HGT_MEDIUM) + BORDER_SPACING * 2

    local o = ISPanelJoypad:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y
    o.width = width
    o.height = height
    o.playerObj = playerObj
    o.tfc_Base = tfc_Base
    o.text_takeBath = getText("IGUI_TABAS_TakeBath")
    o.text_bathActions = getText("IGUI_TABAS_BathActions")
    o.text_config = getText("IGUI_TABAS_OpenConfig")
    o.tex_bathActions = CONST.TEXTURE.bath_actionmenu
    o.tex_config = CONST.TEXTURE.configIcon
    o.backgroundColor = CONST.COLOR.backgroundColor
    return o
end
