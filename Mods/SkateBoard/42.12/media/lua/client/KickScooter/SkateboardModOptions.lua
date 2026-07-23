local config = {
    skateboardSoundVolume = nil,
    skateboardSoundRange = nil,
    skateboardWalkSpeedMultiplier = nil,
    skateboardRunSpeedMultiplier = nil,
    skateboardImmersiveMode = nil,
    skateboardOllieButton = nil,
    skateboardEquipButton = nil
}

local function SkateboardConfig()
    local options = PZAPI.ModOptions:create("SkateboardMod", "Skateboard")

    options:addDescription("Change the volume and sound range of Skateboard sounds.")
    config.skateboardSoundVolume = options:addSlider("SkateboardSoundVolume", "Skateboard Sound Volume (Default 0.40)", 0.01, 1, 0.01, 0.40, "Set sound volume of skateboard sounds.")
    config.skateboardSoundRange = options:addSlider("SkateboardSoundRange", "Skateboard Sound Range (Default 15)", 1, 30, 1, 15, "Set the range that the sounds of the skateboard can be heard.")

    options:addDescription("Change the speed of the skateboard. Slow is when you're not holding SHIFT, Fast is when you're holding SHIFT.")
    config.skateboardWalkSpeedMultiplier = options:addSlider("SpeedMultSlow", "Skateboard Speed Slow (Default 1.7)", 0.1, 5, 0.1, 1.7, "Set your player speed when riding the skateboard and not holding SHIFT.")
    config.skateboardRunSpeedMultiplier = options:addSlider("SpeedMultFast", "Skateboard Speed Fast (Default 2.5)", 0.1, 5, 0.1, 2.5, "Set your player speed when riding the skateboard and holding SHIFT.")

    options:addDescription("Skateboard Gameplay Options")
    config.skateboardImmersiveMode = options:addTickBox("SkateboardImmersive", "Immersive Mode", true, "Toggle Immersive mode. When enabled you will be slower on rough surfaces like gravel/sand.")
    config.skateboardEquipButton = options:addKeyBind("SkateboardEquipButton", "Change button to equip the skateboard.", Keyboard.KEY_E, "Change the keybind that makes you hop on the skateboard.")
    config.skateboardOllieButton = options:addKeyBind("SkateboardOllieButton", "Change button to do an Ollie", Keyboard.KEY_G, "Change the keybind that makes you perform an ollie while on a skateboard.")
end

SkateboardConfig()
