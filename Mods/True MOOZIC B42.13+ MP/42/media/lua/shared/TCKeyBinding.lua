-- Register True Moozic keybinds in the core key bindings menu.
if keyBinding then
    local bind = {}
    bind.value = "[TrueMoozic]"
    table.insert(keyBinding, bind)

    local function addBind(name, key)
        local b = {}
        b.value = name
        b.key = key
        table.insert(keyBinding, b)
    end

    addBind("TrueMoozic_PlayStop", Keyboard.KEY_NUMPAD0)
    addBind("TrueMoozic_OnOff", Keyboard.KEY_NUMPAD1)
    addBind("TrueMoozic_VolUp", Keyboard.KEY_ADD)
    addBind("TrueMoozic_VolDown", Keyboard.KEY_SUBTRACT)
    addBind("TrueMoozic_DeviceOptions", Keyboard.KEY_NONE)
end
