require("Skateboard/SkateboardCore")

---@class SkateboardOptions
Skateboard = Skateboard or {}
Skateboard.Options = Skateboard.Options or {}

local Options = Skateboard.Options
local Core = Skateboard.Core

Options.Key = {
    SoundVolume = "SkateboardSoundVolume",
    SoundRange = "SkateboardSoundRange",
    EquipKey = "SkateboardEquipButton",
    OllieKey = "SkateboardOllieButton",
    WalkSpeedMultiplier = "SkateboardWalkSpeedMultiplier",
    RunSpeedMultiplier = "SkateboardRunSpeedMultiplier",
    ImmersiveMode = "SkateboardImmersiveMode"
}

---@return nil
function Options.register()
    if not (PZAPI and PZAPI.ModOptions and Keyboard) then
        return
    end

    local options = PZAPI.ModOptions:create(Core.ModOptionsId, "Skateboard")

    options:addDescription("Change the volume and sound range of Skateboard sounds.")
    options:addSlider(
        Options.Key.SoundVolume,
        "Skateboard Sound Volume (Default 0.40)",
        0.01,
        1,
        0.01,
        0.40,
        "Set sound volume of skateboard sounds."
    )
    options:addSlider(
        Options.Key.SoundRange,
        "Skateboard Sound Range (Default 15)",
        1,
        30,
        1,
        15,
        "Set the range that the sounds of the skateboard can be heard."
    )

    options:addDescription("Skateboard Speed (Singleplayer)")
    options:addSlider(
        Options.Key.WalkSpeedMultiplier,
        "Skateboard Speed Slow (Default 1.7)",
        0.1,
        5,
        0.1,
        1.7,
        "Set your player speed when riding the skateboard and not holding SHIFT. (Affects singleplayer only, for MP this is handled in sandbox options)"
    )
    options:addSlider(
        Options.Key.RunSpeedMultiplier,
        "Skateboard Speed Fast (Default 2.5)",
        0.1,
        5,
        0.1,
        2.5,
        "Set your player speed when riding the skateboard and holding SHIFT. (Affects singleplayer only, for MP this is handled in sandbox options)"
    )
    options:addTickBox(
        Options.Key.ImmersiveMode,
        "Immersive Mode",
        true,
        "When enabled you will be slower on rough surfaces like gravel/sand. (Affects singleplayer only, for MP this is handled in sandbox options)"
    )

    options:addDescription("Skateboard Controls")
    options:addKeyBind(
        Options.Key.EquipKey,
        "Change button to equip the skateboard.",
        Keyboard.KEY_E,
        "Change the keybind that makes you hop on the skateboard."
    )
    options:addKeyBind(
        Options.Key.OllieKey,
        "Change button to do an Ollie",
        Keyboard.KEY_G,
        "Change the keybind that makes you perform an ollie while on a skateboard."
    )
end

---@nodiscard
---@return ModOptions|nil
function Options.get()
    if not (PZAPI and PZAPI.ModOptions) then
        return nil
    end

    return PZAPI.ModOptions:getOptions(Core.ModOptionsId)
end

Options.register()

return Options
