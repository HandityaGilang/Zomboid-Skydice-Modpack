local MOD_ID = "simpleStatus"

local ssOptions = {}

local function setup()
    local opt = PZAPI.ModOptions:create(MOD_ID, "Simple Status")
    ssOptions.toggleKey = opt:addKeyBind("toggleKey", getText("IGUI_SS_OPT_TOGGLEKEY"), Keyboard.KEY_BACKSLASH, nil)
    ssOptions.lockedKey = opt:addKeyBind("lockedKey", getText("IGUI_SS_OPT_LOCKKEY"), Keyboard.KEY_L, nil)
end

setup()

return ssOptions
