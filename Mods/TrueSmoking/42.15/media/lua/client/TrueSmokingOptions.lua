local config = {}
TrueSmoking = TrueSmoking or {}

local options = PZAPI.ModOptions:create('TrueSmoking', 'True Smoking')

-- define your options here .....
options:addKeyBind('keySmoke', getText('IGUI_TRUESMOKING_KEY_SMOKE'), Keyboard.KEY_K,
    getText('IGUI_TRUESMOKING_KEY_SMOKE_DESC'))
options:addTickBox('FindSmoke', getText('IGUI_TRUESMOKING_FIND_SMOKE'), true, getText('IGUI_TRUESMOKING_FIND_SMOKE_DESC'))
options:addKeyBind('keyStopSmoke', getText('IGUI_TRUESMOKING_KEY_STOP_SMOKE'), Keyboard.KEY_SEMICOLON,
    getText('IGUI_TRUESMOKING_KEY_STOP_SMOKE_DESC'))
options:addTickBox('KeepLit', getText('IGUI_TRUESMOKING_KEEP_LIT'), true, getText('IGUI_TRUESMOKING_KEEP_LIT_DESC'))
options:addTickBox('AutoPutOut', getText('IGUI_TRUESMOKING_AUTO_PUT_OUT'), true,
    getText('IGUI_TRUESMOKING_AUTO_PUT_OUT_DESC'))
options:addSeparator()
options:addTickBox('PassivePuffing', getText('IGUI_TRUESMOKING_PASSIVE_SMOKING'), false,
    getText('IGUI_TRUESMOKING_PASSIVE_SMOKING_DESC'))
options:addSlider('PassivePuffMinTime', getText('IGUI_TRUESMOKING_PASSIVE_MIN_TIME'), 5, 60, 15, 1,
    getText('IGUI_TRUESMOKING_PASSIVE_MIN_TIME_DESC'))
options:addSlider('PassivePuffMaxTime', getText('IGUI_TRUESMOKING_PASSIVE_MAX_TIME'), 10, 120, 45, 1,
    getText('IGUI_TRUESMOKING_PASSIVE_MAX_TIME_DESC'))
options:addSeparator()
options:addTickBox('HidePuffActionBar', getText('IGUI_TRUESMOKING_HIDE_PUFF_ACTION_BAR'), false,
    getText('IGUI_TRUESMOKING_HIDE_PUFF_ACTION_BAR_DESC'))
options:addTickBox('HideAllActionBars', getText('IGUI_TRUESMOKING_HIDE_ALL_ACTION_BARS'), false,
    getText('IGUI_TRUESMOKING_HIDE_ALL_ACTION_BARS_DESC'))
options:addTickBox('HideMoodles', getText('IGUI_TRUESMOKING_HIDE_MOODLES'), false,
    getText('IGUI_TRUESMOKING_HIDE_MOODLES_DESC'))
options:addTickBox('ShowSmokePercent', getText('IGUI_TRUESMOKING_SHOW_SMOKE_PERCENT'), false,
    getText('IGUI_TRUESMOKING_SHOW_SMOKE_PERCENT_DESC'))
options:addTickBox('DebugMoodles', getText('IGUI_TRUESMOKING_DEBUG_MOODLES'), false,
    getText('IGUI_TRUESMOKING_DEBUG_MOODLES_DESC'))

-- options:addButton('TestButton', '100 nicotine', '100 nicotine', function()
--     local data = getPlayer():getModData().nicotineSystem
--     data.nicotineLevel = 100
-- end)
-- options:addButton('TestButton2', '100 addiction', '100 addiction', function()
--     local data = getPlayer():getModData().nicotineSystem
--     data.addictionLevel = data.addictionLevel + 100
-- end)
-- options:addButton('TestButton1', '100 withdrawal', '100 withdrawal', function()
--     local data = getPlayer():getModData().nicotineSystem
--     data.withdrawalLevel = data.withdrawalLevel + 100
-- end)
-- options:addButton('TestButton3', '0 levels', '0 levels', function()
--     local data = getPlayer():getModData().nicotineSystem
--     data.nicotineLevel = 0
--     data.addictionLevel = 0
--     data.withdrawalLevel = 0
-- end)

-- options:addButton('TestButton3', '0 levels', '0 levels', function()
--     sendClientCommand(getPlayer(), 'TrueSmoking', 'addSmokable', { 'Base.CigaretteSingle' })
-- end)

options:addSeparator()

-- This is a helper function that will automatically populate the 'config' table.
--- Retrieve each option as: config.'ID'
options.apply = function(self)
    for k, v in pairs(self.dict) do
        if v.type == 'multipletickbox' then
            for i = 1, #v.values do
                config[(k .. '_' .. tostring(i))] = v:getValue(i)
            end
        elseif v.type == 'button' then
            -- do nothing
        else
            config[k] = v:getValue()
        end
    end
end

Events.OnMainMenuEnter.Add(function()
    options:apply()
end)

-- Apply config when entering a game (for key binding changes)
Events.OnInitWorld.Add(function()
    options:apply()
end)

TrueSmoking.Config = config

-- We now return the `config` object, so it can be used as a module!
return config
