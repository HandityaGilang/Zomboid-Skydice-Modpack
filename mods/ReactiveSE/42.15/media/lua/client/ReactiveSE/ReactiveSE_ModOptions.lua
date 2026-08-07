--//////////////////////////////////////////////////--
--    Reactive Sound Events - Mod Options
--    Client-side options for UI customization
--//////////////////////////////////////////////////--

local config = {}

local function RSE_CreateModOptions()
    local options = PZAPI.ModOptions:create("ReactiveSE", "Reactive Sound Events")
    options:addTitle("Sound Indicator")
    options:addDescription("Customize the visual indicator for distant sound events")

    options:addTickBox("IndicatorEnabled", "Show sound indicator", true,
        "Display a visual indicator pointing toward sound events")

    -- Arrow color (default: white)
    options:addColorPicker("ArrowColor", "Arrow color",
        1, 1, 1, 1, -- White
        "Color of the directional arrow")

    -- Base circle color (default: PZ grey)
    options:addColorPicker("BaseColor", "Circle color",
        0.4, 0.4, 0.4, 1, -- PZ UI grey
        "Color of the background circle")

    -- Base opacity slider
    options:addSlider("BaseOpacity", "Circle opacity",
        0, 1, 0.1, 0.7, -- Default 70% opacity
        "Transparency of the background circle (0 = invisible, 1 = solid)")

    -- Marker duration slider
    options:addSlider("SoundMarkerDuration", "Sound marker duration",
        10, 240, 5, 60, -- Default 60 seconds
        "How long the indicator stays visible (in seconds) when a sound event happens")

    options:addSlider("SceneMarkerDuration", "Scene marker duration",
        10, 120, 5, 30, -- Default 30 seconds
        "How long the indicator stays visible (in seconds) when a scene the player apporaches a scene")

    options:addTickBox("UseColoredIcons", "Use colored icons", false, "Use colored versions of event icons")

    options:addTitle("Event Colors")
    options:addDescription("Customize the background colors for each event")

    options:addColorPicker("ColorAnimal", "Animal",
        0.667, 0.890, 0.663, 1, "Color for Animal events")

    options:addColorPicker("ColorGunfight", "Gunfight",
        0.910, 0.725, 0.725, 1, "Color for Gunfight events")

    options:addColorPicker("ColorGunshot", "Gunshot",
        0.910, 0.725, 0.725, 1, "Color for Gunshot events")

    options:addColorPicker("ColorScream", "Scream",
        0.910, 0.725, 0.725, 1, "Color for Scream events")

    options:addColorPicker("ColorVehicleCrash", "Vehicle Crash",
        0.988, 0.910, 0.596, 1, "Color for Vehicle Crash events")

    options:addColorPicker("ColorWeather", "Weather",
        0.651, 0.769, 0.878, 1, "Color for Weather events")

    options:addColorPicker("ColorZombie", "Zombie",
        0.910, 0.725, 0.725, 1, "Color for Zombie events")

    options:addTitle("Context Menu")
    options:addDescription("Customize the context menu options")

    options:addTickBox("MarkIntelIcon", "Show mark intel icon", true, "Display the mark intel icon")

    -- Auto-populate config on apply
    options.apply = function(self)
        for k, v in pairs(self.dict) do
            if v.type == "multipletickbox" then
                for i = 1, #v.values do
                    config[k .. "_" .. tostring(i)] = v:getValue(i)
                end
            elseif v.type ~= "button" then
                config[k] = v:getValue()
            end
        end
    end
end

Events.OnGameBoot.Add(RSE_CreateModOptions)
Events.OnMainMenuEnter.Add(function()
    local options = PZAPI.ModOptions:getOptions("ReactiveSE")
    if options then options:apply() end
end)

return config
