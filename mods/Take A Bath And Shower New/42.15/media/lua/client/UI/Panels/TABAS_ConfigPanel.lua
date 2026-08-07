
require("ISUI/ISPanelJoypad")

TABAS_ConfigPanel = ISPanelJoypad:derive("TABAS_ConfigPanel")
TABAS_ConfigPanel.instance = nil

local CONST = require("UI/TABAS_PanelConst")
local FONT_HGT_SMALL = CONST.SCALE.HGT_SMALL
local FONT_HGT_MEDIUM = CONST.SCALE.HGT_MEDIUM
local HGT_BUTTON = CONST.SCALE.HGT_BUTTON
local BORDER_SPACING = CONST.SCALE.BORDER_SPACING

function TABAS_ConfigPanel.openPanel(x, y, playerObj)
    if TABAS_ConfigPanel.instance == nil then
        local ui = TABAS_ConfigPanel:new(x, y, 500, 400, playerObj)
        ui:initialise()
        ui:addToUIManager()
        ui:centerOnScreen(playerObj:getPlayerNum())
        TABAS_ConfigPanel.instance = ui

        local player = playerObj:getPlayerNum()
        if JoypadState.players[player+1] then
            ui.prevFocus = JoypadState.players[player+1].focus
            setJoypadFocus(player, ui)
        end
    end
    return TABAS_ConfigPanel.instance
end

function TABAS_ConfigPanel:createChildren()
    ISPanelJoypad.createChildren(self)
    local x = BORDER_SPACING*2
    local y = FONT_HGT_MEDIUM + BORDER_SPACING
    local btnWidth = 80
    self.btnClose = ISButton:new(0, 0, btnWidth, HGT_BUTTON, getText("UI_Close"), self, self.onClick)
    self.btnClose.internal = "CLOSE"
    self.btnClose:initialise()
    self.btnClose:instantiate()
    self:addChild(self.btnClose)

    self.btnReset = ISButton:new(0, 0, HGT_BUTTON, HGT_BUTTON, "", self, self.onClick)
    self.btnReset.internal = "RESET"
    self.btnReset:initialise()
    self.btnReset:instantiate()
    self.btnReset:setTooltip(getText("IGUI_PlayerStats_ResetToDefault"))
    self.btnReset:setImage(self.tex_resetIcon)
    self:addChild(self.btnReset)

    self.options = {
        {type = "label", text = getText("IGUI_TABAS_Config_General"), tooltip = ""},
        {type = "combobox", name = "DisplayBathtubMenu", default = 1},
        {type = "tickbox", name = "DisplaysAvailableShower", default = true},
        {type = "tickbox", name = "DisplayTubWaterDirtyLevel", default = false},
        {type = "tickbox", name = "DisplayTubSpacialTooltip", default = true},
        {type = "tickbox", name = "DisplayImproveOption", default = true},
        {type = "tickbox", name = "EnabledShowerSteamAnim", default = true},
        {type = "tickbox", name = "WashOffMakeup", default = true},
        {type = "tickbox", name = "AfterBathingDrySelf", default = true},
        {type = "tickbox", name = "AutoTakeBathMode", default = true},
        {type = "textentry", name = "DontMindWatchedBy", default = ""},

        {type = "label", text = getText("IGUI_TABAS_Config_AutoClothesChange"), tooltip = getText("UI_TABAS_AutoClothesChange_tooltip")},
        {type = "tickbox", name = "AutoClothesChange", default = true},
        {type = "combobox", name = "WearingActionTime", default = 1},
        {type = "tickbox", name = "NotTakeoff_Watches", default = false},
        {type = "tickbox", name = "NotTakeOff_Accessories", default = false},
        {type = "tickbox", name = "NotTakeOff_Glasses", default = false},
        {type = "tickbox", name = "NotTakeOff_Belts", default = false},

        {type = "label", text = getText("IGUI_TABAS_Config_DropsItems"), tooltip = getText("UI_TABAS_DropEquippedItems_tooltip")},
        {type = "tickbox", name = "DropEquippedItemsAll", default = false},
        {type = "tickbox", name = "DropEquippedItemsBack", default = true},
        {type = "tickbox", name = "DropEquippedItemsContainer", default = true},
        {type = "tickbox", name = "DropEquippedItemsAttached", default = false},
        {type = "tickbox", name = "DropEquippedItemsHand", default = false},
        {type = "tickbox", name = "DropEquippedItemsClothing", default = false},
        {type = "slider", name = "DropEquippedItemsWeight", default = 4},
    }
    local lblWidth = 0
    for i=1, #self.options do
        local op = self.options[i]
        if op.name then
            lblWidth = math.max(lblWidth, getTextManager():MeasureStringX(UIFont.Small, getText("UI_TABAS_" .. op.name)))
        end
    end
    for i=1, #self.options do
        local op = self.options[i]
        if op.type == "label" then
            y = self:addLabelAndTips(op.text, op.tooltip, x, y)
        elseif op.type == "tickbox" then
            y = self:addTickBoxOption(op.name, x, y, lblWidth, HGT_BUTTON)
        elseif op.type == "combobox" then
            y = self:addComboBoxOption(op.name, x, y, lblWidth, HGT_BUTTON)
        elseif op.type == "slider" then
            y = self:addSliderOption(op.name, x, y, lblWidth, HGT_BUTTON)
        elseif op.type == "textentry" then
            y = self:addTextEntryOption(op.name, x, y, lblWidth, HGT_BUTTON)
        end
    end

    self:setHeight(y + HGT_BUTTON + BORDER_SPACING*4)
    self.btnReset:setX(HGT_BUTTON + BORDER_SPACING)
    self.btnReset:setY(self:getBottom() - HGT_BUTTON - BORDER_SPACING)
    self.btnClose:setX(self:getWidth()/2 - btnWidth/2)
    self.btnClose:setY(self:getBottom() - HGT_BUTTON - BORDER_SPACING)
end

function TABAS_ConfigPanel:addLabelAndTips(text, tooltip, x, y)
    local col = self.labelColor
    local label = ISLabel:new(x, y, FONT_HGT_SMALL, text, col.r, col.g, col.b, col.a, UIFont.Small, true)
    label:initialise()
    label:instantiate()
    self:addChild(label)
    if tooltip then
        label:setTooltip(tooltip)
    end
    return y + FONT_HGT_SMALL + BORDER_SPACING/2
end

function TABAS_ConfigPanel:addTickBoxOption(name, x, y, w, h)
    local option = self.modOptions:getOption(name)
    if option ~= nil and option.type == "tickbox" then
        local tickBox = ISTickBox:new(x, y, w, h, "", self, self.onTickBox, name)
        tickBox:initialise()
        tickBox:instantiate()
        tickBox.selected[1] = option:getValue()
        tickBox:addOption(option.name, option)
        tickBox.tooltip = option.tooltip
        self:addChild(tickBox)
        self[name] = tickBox
    end
    return y + h + BORDER_SPACING
end

function TABAS_ConfigPanel:addComboBoxOption(name, x, y, w, h)
    local option = self.modOptions:getOption(name)
    if option ~= nil and option.type == "combobox" then
        local col = self.textColor
        local comboLabel = ISLabel:new(x, y, FONT_HGT_SMALL, option.name, col.r, col.g, col.b, col.a, UIFont.Small, true)
        self:addChild(comboLabel)
        comboLabel.tooltip = option.tooltip
        y = y + FONT_HGT_SMALL + BORDER_SPACING

        local comboBox = ISComboBox:new(x, y, w, h, self, self.onComboBox, name)
        comboBox:initialise()
        comboBox:instantiate()
        comboBox.customData = option
        comboBox.selected = option:getValue()
        self:addChild(comboBox)
        for i=1, #option.values do
            local item = option.values[i]
            comboBox:addOption(item)
        end
        self[name] = comboBox
    end
    return y + h + BORDER_SPACING
end

function TABAS_ConfigPanel:addSliderOption(name, x, y, w, h)
    local option = self.modOptions:getOption(name)
    if option ~= nil and option.type == "slider" then
        local col = self.textColor
        local sliderLabel = ISLabel:new(x, y, FONT_HGT_SMALL, option.name, col.r, col.g, col.b, col.a, UIFont.Small, true)
        sliderLabel:initialise()
        sliderLabel:instantiate()
        self:addChild(sliderLabel)
        sliderLabel.tooltip = option.tooltip
        y = y + FONT_HGT_SMALL + BORDER_SPACING

        local valueLabel = ISLabel:new(x, y, FONT_HGT_SMALL, "XX.X", col.r, col.g, col.b, col.a, UIFont.Small, true)
        valueLabel:initialise()
        valueLabel:instantiate()
        self:addChild(valueLabel)

        local lblWidth =  valueLabel:getWidth()+FONT_HGT_SMALL+BORDER_SPACING
        local slider = ISSliderPanel:new(x + lblWidth, y, w - lblWidth, h, self, self.onSliderChange)
        slider:initialise()
        slider:instantiate()
        slider:setValues(option.min, option.max, option.step, 1, true)
        slider:setCurrentValue(option:getValue(), true)
        slider.valueLabel = valueLabel
        slider.customData = option
        self:addChild(slider)
        self[name] = slider
    end
    return y + h + BORDER_SPACING
end

function TABAS_ConfigPanel:addTextEntryOption(name, x, y, w, h)
    local option = self.modOptions:getOption(name)
    if option ~= nil and option.type == "textentry" then
        local col = self.textColor
        local entryLabel = ISLabel:new(x, y, FONT_HGT_SMALL, option.name, col.r, col.g, col.b, col.a, UIFont.Small, true)
        entryLabel:initialise()
        entryLabel:instantiate()
        self:addChild(entryLabel)
        entryLabel.tooltip = option.tooltip

        y = y + FONT_HGT_SMALL + BORDER_SPACING

        local entryW = math.max(120, w)
        local entry = ISTextEntryBox:new(tostring(option:getValue() or ""), x, y, entryW, h)
        entry:initialise()
        entry:instantiate()
        entry.tooltip = option.tooltip

        entry.onCommandEntered = function(box)
            local opt = box.customData
            if opt then
                opt:setValue(box:getText() or "")
            end
        end

        -- entry.onTextChange = function(box)
        --     local opt = box.customData
        --     if opt then
        --         opt:setValue(box:getText() or "")
        --     end
        -- end

        entry.customData = option
        self:addChild(entry)
        self[name] = entry
    end
    return y + h + BORDER_SPACING
end


function TABAS_ConfigPanel:render()
    self:renderJoypadFocus()
end

function TABAS_ConfigPanel:prerender()
    ISPanelJoypad.prerender(self)
    local col = self.borderColor
    self:drawTextCentre(self.title, self:getWidth() / 2, 1, 1, 1, 1, 1, UIFont.Medium)
    -- self:drawRectBorder(BORDER_SPACING*4, self.dropsTooltip:getY(), self:getWidth()-BORDER_SPACING*8, 1, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
end

function TABAS_ConfigPanel:update()
    for i=1, #self.options do
        local op = self.options[i]
        if op and op.type == "slider" then
            local slider = self[op.name]
            if slider and slider.valueLabel then
                slider.valueLabel:setName(tostring(slider:getCurrentValue()))
            end
        end
    end
end

function TABAS_ConfigPanel:onTickBox(index, selected, arg)
	local option = self[arg].optionData[index]
    if option == nil then return end

	option:setValue(selected)
end

function TABAS_ConfigPanel:onComboBox(comboBox, arg)
	local option = self[arg].customData
    if option == nil then return end

	option:setValue(comboBox.selected)
end

function TABAS_ConfigPanel:onSliderChange(newVal, slider)
    local option = slider.customData
    if option == nil then return end

    option:setValue(newVal)
end

function TABAS_ConfigPanel:onClick(_btn)
    if _btn.internal == "CLOSE" then
        self:close()
    elseif _btn.internal == "RESET" then
        for i=1, #self.options do
            local op = self.options[i]
            if op and self[op.name] then
                local option = self[op.name]
                if option.customData then
                    if option.customData.type == "slider" then
                        option.customData:setValue(op.default)
                        option:setCurrentValue(option.customData:getValue(), true)
                    elseif option.customData.type == "combobox" then
                        option.customData:setValue(op.default)
                        option.selected = option.customData:getValue()
                    elseif option.customData.type == "textentry" then
                        option.customData:setValue(op.default or "")
                        option:setText(tostring(option.customData:getValue() or ""))
                    else
                        option.customData:setValue(op.default)
                    end
                elseif option.optionData[1] then
                    option.optionData[1]:setValue(op.default)
                    option.selected[1] = option.optionData[1]:getValue()
                end
            end
        end
    end
end

function TABAS_ConfigPanel:close()
    PZAPI.ModOptions:save()
    TABAS_ConfigPanel.instance = nil
    self:setVisible(false)
    self:removeFromUIManager()
    local player = self.character:getPlayerNum()
    if JoypadState.players[player+1] then
        setJoypadFocus(player, self.prevFocus)
    end
end

function TABAS_ConfigPanel:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData)
    self.joypadIndexY = 1
    self.joypadIndex = 1
    self.joypadButtons = {}
    self.joypadButtonsY = {}

    for i=1, #self.options do
        local op = self.options[i]
        if op and self[op.name] then
            self:insertNewLineOfButtons(self[op.name])
        end
    end
    self:insertNewLineOfButtons(self.btnReset, self.btnClose)
    self:setISButtonForB(self.btnClose)
end

function TABAS_ConfigPanel:onJoypadDown(button)
    ISPanelJoypad.onJoypadDown(self, button)
    if button == Joypad.BButton then
        self:close()
    end
end

function TABAS_ConfigPanel:onLoseJoypadFocus(joypadData)
	ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
    self:clearJoypadFocus(joypadData)
end

function TABAS_ConfigPanel:new(x, y, width, height, character)
    local o = ISPanelJoypad.new(self, x, y, width, height)
    o.background = true
    o.borderColor = CONST.COLOR.borderOuterColor
    o.backgroundColor = CONST.COLOR.backgroundColorDark
    o.labelColor = CONST.COLOR.labelColor
    o.textColor = {r=0.9, g=0.9, b=0.9, a=0.9}

    o.character = character
    o.modOptions = PZAPI.ModOptions:getOptions("TakeABathAndShower")
    o.title = getText("IGUI_TABAS_Config_Title")
    o.tex_resetIcon = CONST.TEXTURE.resetIcon
    o.moveWithMouse = true
    return o
end

