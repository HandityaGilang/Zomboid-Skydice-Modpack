--[[
    DebugUI.lua - Debug Window for TrueSmoking ModData

    Press F8 to toggle the debug window showing:
    - TrueSmoking ModData values
    - NicotineSystem ModData values
    - Sliders to adjust values in real-time
]]

require 'ISUI/ISPanel'
require 'Core'
require 'Data'

TrueSmoking.DebugUI = TrueSmoking.DebugUI or {}
local DebugUI = TrueSmoking.DebugUI

--------------------------------------------------------------------------------
-- Debug Window Class
--------------------------------------------------------------------------------

TSDebugWindow = ISPanel:derive('TSDebugWindow')

function TSDebugWindow:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.9 }
    o.moveWithMouse = true
    o.player = getPlayer()
    o.sliders = {}
    o.labels = {}
    o.sections = {}

    return o
end

function TSDebugWindow:createChildren()
    ISPanel.createChildren(self)

    local y = 10
    local padding = 5
    local sliderHeight = 20
    local labelWidth = 200
    local sliderWidth = 250

    -- Title
    local title = ISLabel:new(10, y, 20, 'TrueSmoking Debug Panel', 1, 1, 1, 1, UIFont.Medium, true)
    self:addChild(title)
    y = y + 30

    -- Close button
    local btnClose = ISButton:new(self.width - 80, 5, 70, 25, 'Close', self, TSDebugWindow.close)
    self:addChild(btnClose)

    -- Refresh button
    local btnRefresh = ISButton:new(self.width - 160, 5, 70, 25, 'Refresh', self, TSDebugWindow.refreshData)
    self:addChild(btnRefresh)

    -- TrueSmoking ModData Section
    y = self:addSection('TrueSmoking ModData', y, padding)

    local smokingFields = {
        { 'isSmoking',  'boolean', false, true },
        { 'takingPuff', 'boolean', false, true },
        { 'smokeLit',   'boolean', false, true },
    }

    for _, field in ipairs(smokingFields) do
        y = self:addField('smoking', field[1], field[2], field[3], field[4], y, padding, labelWidth, sliderWidth,
            sliderHeight)
    end

    y = y + 15

    -- Nicotine System Section
    y = self:addSection('Nicotine System', y, padding)

    local nicotineFields = {
        { 'nicotineLevel',   'number', 0, 100 },
        { 'addictionLevel',  'number', 0, 100 },
        { 'withdrawalLevel', 'number', 0, 100 },
    }

    for _, field in ipairs(nicotineFields) do
        y = self:addField('nicotine', field[1], field[2], field[3], field[4], y, padding, labelWidth, sliderWidth,
            sliderHeight)
    end

    y = y + 15

    -- Player Stats Section
    y = self:addSection('Player Stats (Read-Only)', y, padding)

    local statFields = {
        { 'hunger',             'stat',    0, 1 },
        { 'fatigue',            'stat',    0, 1 },
        { 'boredom',            'stat',    0, 100 },
        { 'unhappiness',        'stat',    0, 100 },
        { 'stress',             'stat',    0, 1 },
        { 'nicotineWithdrawal', 'stat',    0, 0.51 },
        { 'timeSinceLastSmoke', 'special', 0, 10000 },
    }

    for _, field in ipairs(statFields) do
        y = self:addStatDisplay(field[1], field[3], field[4], y, padding, labelWidth, sliderWidth)
    end

    self:setHeight(y + 20)
end

function TSDebugWindow:addSection(title, y, padding)
    local section = ISLabel:new(10, y, 20, title, 1, 1, 0.5, 1, UIFont.Medium, true)
    self:addChild(section)
    table.insert(self.sections, section)
    return y + 25
end

function TSDebugWindow:addField(dataType, fieldName, valueType, minValue, maxValue, y, padding, labelWidth, sliderWidth,
                                sliderHeight)
    -- Label
    local label = ISLabel:new(10, y + 3, 20, fieldName .. ':', 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(label)

    -- Value label
    local valueLabel = ISLabel:new(labelWidth + sliderWidth + 20, y + 3, 20, '0', 1, 1, 1, 1, UIFont.Small, true)
    self:addChild(valueLabel)

    if valueType == 'boolean' then
        -- Checkbox
        local checkbox = ISTickBox:new(labelWidth + 10, y, 20, 20, '', self, TSDebugWindow.onCheckboxChange)
        checkbox.dataType = dataType
        checkbox.fieldName = fieldName
        self:addChild(checkbox)

        self.sliders[dataType .. '.' .. fieldName] = {
            checkbox = checkbox,
            label = valueLabel,
            type = 'boolean'
        }
    else
        -- Slider
        local slider = ISSliderPanel:new(labelWidth + 10, y, sliderWidth, sliderHeight, self,
            TSDebugWindow.onSliderChange)
        slider:setValues(minValue, maxValue, 0.01, 0.01, true)
        slider:setCurrentValue(minValue)
        slider.dataType = dataType
        slider.fieldName = fieldName
        self:addChild(slider)

        self.sliders[dataType .. '.' .. fieldName] = {
            slider = slider,
            label = valueLabel,
            type = 'number',
            min = minValue,
            max = maxValue
        }
    end

    self.labels[dataType .. '.' .. fieldName] = valueLabel

    return y + sliderHeight + padding
end

function TSDebugWindow:addStatDisplay(statName, minValue, maxValue, y, padding, labelWidth, sliderWidth)
    -- Label
    local label = ISLabel:new(10, y + 3, 20, statName .. ':', 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    self:addChild(label)

    -- Value label (read-only)
    local valueLabel = ISLabel:new(labelWidth + 10, y + 3, 20, '0', 0.7, 0.7, 0.7, 1, UIFont.Small, true)
    self:addChild(valueLabel)

    self.labels['stat.' .. statName] = valueLabel

    return y + 20 + padding
end

function TSDebugWindow:onSliderChange(newValue, slider)
    if not self.player or not slider then return end
    
    -- Skip if we're refreshing from server data to prevent feedback loop
    if self.isRefreshing then return end

    local dataType = slider.dataType
    local fieldName = slider.fieldName

    -- Safety check: if custom data not found on slider, try to find it in our stored sliders
    if not dataType or not fieldName then
        for key, control in pairs(self.sliders) do
            if control.slider == slider then
                dataType = control.slider.dataType
                fieldName = control.slider.fieldName
                break
            end
        end
    end

    if not dataType or not fieldName then
        print("TRUESMOKING::DEBUG Warning: slider callback missing dataType or fieldName")
        return
    end

    local key = dataType .. '.' .. fieldName

    -- Update label
    if self.labels[key] then
        self.labels[key]:setName(string.format('%.2f', newValue))
    end

    -- Update ModData
    if dataType == 'smoking' then
        local data = TrueSmoking.Data.getSmoking(self.player)
        if data then
            data[fieldName] = newValue
            -- Sync to server
            sendClientCommand(self.player, 'TrueSmoking', 'updatePlayerData', { [fieldName] = newValue })
        end
    elseif dataType == 'nicotine' then
        local data = TrueSmoking.Data.getNicotine(self.player)
        if data then
            data[fieldName] = newValue
            -- Sync to server
            sendClientCommand(self.player, 'TrueSmoking', 'updatePlayerNicData', { [fieldName] = newValue })
        end
    end
end

function TSDebugWindow:onCheckboxChange(index, selected, checkbox)
    if not self.player or not checkbox then return end
    
    -- Skip if we're refreshing from server data to prevent feedback loop
    if self.isRefreshing then return end

    local dataType = checkbox.dataType
    local fieldName = checkbox.fieldName

    -- Safety check
    if not dataType or not fieldName then
        for key, control in pairs(self.sliders) do
            if control.checkbox == checkbox then
                dataType = control.checkbox.dataType
                fieldName = control.checkbox.fieldName
                break
            end
        end
    end

    if not dataType or not fieldName then
        print("TRUESMOKING::DEBUG Warning: checkbox callback missing dataType or fieldName")
        return
    end

    local key = dataType .. '.' .. fieldName

    -- Update label
    if self.labels[key] then
        self.labels[key]:setName(tostring(selected))
    end

    -- Update ModData
    if dataType == 'smoking' then
        local data = TrueSmoking.Data.getSmoking(self.player)
        if data then
            data[fieldName] = selected
            sendClientCommand(self.player, 'TrueSmoking', 'updatePlayerData', { [fieldName] = selected })
        end
    elseif dataType == 'nicotine' then
        local data = TrueSmoking.Data.getNicotine(self.player)
        if data then
            data[fieldName] = selected
            sendClientCommand(self.player, 'TrueSmoking', 'updatePlayerNicData', { [fieldName] = selected })
        end
    end
end

function TSDebugWindow:refreshData()
    if not self.player then return end
    
    -- Suppress callbacks during refresh to prevent feedback loop
    self.isRefreshing = true

    local smokingData = TrueSmoking.Data.getSmoking(self.player)
    local nicData = TrueSmoking.Data.getNicotine(self.player)
    local stats = self.player:getStats()
    local ref = TrueSmoking.getPlayerRef(self.player)
    local smokable = ref and ref.smokable

    -- Update smoking fields
    for field, control in pairs(self.sliders) do
        if control.type == 'boolean' and field:find('^smoking%.') then
            local fieldName = field:match('%.(.+)$')
            local value = nil

            -- Special case: smokeLit comes from smokable instance, not ModData
            if fieldName == 'smokeLit' and smokable then
                value = smokable.smokeLit == true
            elseif smokingData and smokingData[fieldName] ~= nil then
                value = smokingData[fieldName] == true
            end

            if value ~= nil then
                control.checkbox.selected[1] = value
                control.label:setName(tostring(value))
            end
        elseif control.type == 'number' and field:find('^smoking%.') then
            local fieldName = field:match('%.(.+)$')
            if smokingData and smokingData[fieldName] ~= nil then
                control.slider:setCurrentValue(tonumber(smokingData[fieldName]) or 0)
                control.label:setName(string.format('%.2f', smokingData[fieldName]))
            end
        end
    end

    -- Update nicotine fields
    for field, control in pairs(self.sliders) do
        if control.type == 'boolean' and field:find('^nicotine%.') then
            local fieldName = field:match('%.(.+)$')
            if nicData and nicData[fieldName] ~= nil then
                local boolValue = nicData[fieldName] == true
                control.checkbox.selected[1] = boolValue
                control.label:setName(tostring(boolValue))
            end
        elseif control.type == 'number' and field:find('^nicotine%.') then
            local fieldName = field:match('%.(.+)$')
            if nicData and nicData[fieldName] ~= nil then
                control.slider:setCurrentValue(tonumber(nicData[fieldName]) or 0)
                control.label:setName(string.format('%.2f', nicData[fieldName]))
            end
        end
    end

    -- Update stat displays (read-only)
    if stats then
        if self.labels['stat.hunger'] then
            self.labels['stat.hunger']:setName(string.format('%.3f', stats:get(CharacterStat.HUNGER)))
        end
        if self.labels['stat.fatigue'] then
            self.labels['stat.fatigue']:setName(string.format('%.3f', stats:get(CharacterStat.FATIGUE)))
        end
        if self.labels['stat.boredom'] then
            self.labels['stat.boredom']:setName(string.format('%.1f', stats:get(CharacterStat.BOREDOM)))
        end
        if self.labels['stat.unhappiness'] then
            self.labels['stat.unhappiness']:setName(string.format('%.1f', stats:get(CharacterStat.UNHAPPINESS)))
        end
        if self.labels['stat.stress'] then
            self.labels['stat.stress']:setName(string.format('%.3f', stats:get(CharacterStat.STRESS)))
        end
        if self.labels['stat.nicotineWithdrawal'] then
            self.labels['stat.nicotineWithdrawal']:setName(string.format('%.3f',
                stats:get(CharacterStat.NICOTINE_WITHDRAWAL)))
        end
        if self.labels['stat.timeSinceLastSmoke'] then
            self.labels['stat.timeSinceLastSmoke']:setName(string.format('%.1f', self.player:getTimeSinceLastSmoke()))
        end
    end
    
    -- Re-enable callbacks after refresh completes
    self.isRefreshing = false
end

function TSDebugWindow:update()
    ISPanel.update(self)

    -- Auto-refresh every 30 frames
    if not self.updateCounter then
        self.updateCounter = 0
    end

    self.updateCounter = self.updateCounter + 1
    if self.updateCounter >= 30 then
        self.updateCounter = 0
        self:refreshData()
    end
end

function TSDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function TSDebugWindow:onMouseDownOutside(x, y)
    -- Don't close on outside click
    return false
end

--------------------------------------------------------------------------------
-- Global Instance Management
--------------------------------------------------------------------------------

DebugUI.window = nil

function DebugUI.toggle()
    if DebugUI.window and DebugUI.window:isVisible() then
        DebugUI.window:close()
        DebugUI.window = nil
    else
        local width = 500
        local height = 600
        local x = (getCore():getScreenWidth() - width) / 2
        local y = (getCore():getScreenHeight() - height) / 2

        DebugUI.window = TSDebugWindow:new(x, y, width, height)
        DebugUI.window:initialise()
        DebugUI.window:addToUIManager()
        DebugUI.window:refreshData()
    end
end

-- F8 keybind
function DebugUI.onKeyPress(key)
    if not TrueSmoking.DEBUG then return end
    if key == Keyboard.KEY_F4 then
        DebugUI.toggle()
    end
end

Events.OnKeyPressed.Add(DebugUI.onKeyPress)

return DebugUI
