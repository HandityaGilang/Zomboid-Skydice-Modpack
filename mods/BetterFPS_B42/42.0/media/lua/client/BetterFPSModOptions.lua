SystemDisabler.setUncappedFPS(true)

local config = {
    keyBind = nil,
    checkBox = nil,
    textEntry = nil,
    multiBox = nil,
    comboBox = nil,
    colorPick = nil,
    slider = nil,
    button = nil
}

local comboValues = {
    ["8x8"] = 1,
    ["32x32"] = 3,
    ["56x56"] = 5,
    ["80x80"] = 7,
    ["104x104"] = 9,
    ["128x128"] = 11,
    ["152x152 (Default)"] = 13,
    ["176x176"] = 15,
    ["200x200 (B41 nearest default value)"] = 17,
    ["224x224"] = 19,
    ["248x248"] = 21,
    ["272x272"] = 23,
    ["296x296"] = 25,
    ["320x320"] = 27,
    ["344x344"] = 29
}

local sortedLabels = {}
for label, _ in pairs(comboValues) do
    table.insert(sortedLabels, label)
end

table.sort(sortedLabels, function(a, b)
    return comboValues[a] < comboValues[b]
end)

local function applyBetterFps()
    local options = PZAPI.ModOptions:getOptions("BetterFPS")
    if not options then return end

    local option = options:getOption("BetterFPS_RenderDistance")
    if not option then return end

    local selectedIndex = option:getValue()
    if not selectedIndex then return end

    local selectedLabel

    if config.comboBox and config.comboBox.items then
        selectedLabel = config.comboBox.items[selectedIndex] and config.comboBox.items[selectedIndex].text
    end

    if not selectedLabel then
        if selectedIndex >= 1 and selectedIndex <= #sortedLabels then
            selectedLabel = sortedLabels[selectedIndex]
        else
            return
        end
    end

    local numericValue = comboValues[selectedLabel]
    if numericValue then
        if IsoChunkMap and type(IsoChunkMap.setMaxRenderDistance) == "function" then
			IsoChunkMap.setMaxRenderDistance(numericValue)
		else
			print(getText("IGUI_BetterFPS_Error"))
		end

    end
end

local function BetterFpsConfig()
    local options = PZAPI.ModOptions:create("BetterFPS", "BetterFPS")
    options:addTitle(getText("UI_options_BetterFPS_title"))

    config.comboBox = options:addComboBox("BetterFPS_RenderDistance", getText("UI_options_BetterFPS"), getText("UI_options_BetterFPS_tooltip"))

    for _, label in ipairs(sortedLabels) do
        config.comboBox:addItem(label, label == "152x152 (Default)")
    end
    options.apply = function(self)
        applyBetterFps()
    end
end

Events.OnGameBoot.Add(function()
    PZAPI.ModOptions:load()
end)

Events.OnCreateUI.Add(function()
    applyBetterFps()
end)

BetterFpsConfig()
Events.OnGameStateEnter.Add(applyBetterFps)
