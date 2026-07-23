-- From "Open All Containers [B42]" mod -- Author = carlesturo

OAC = {}

OAC.options = {
	tickRate = nil,
    keyBind = nil,
	autoOpen = nil,
	autoClose = nil
}

OAC.initOptions = function()
    local options = PZAPI.ModOptions:create("OAC", "Open All Containers")

	OAC.options.tickRate = options:addSlider("OAC_tickRate", getText("UI_options_OAC_tickRate"), 10, 60, 10, 60)
    OAC.options.keyBind = options:addKeyBind("OAC_keyBind", getText("UI_options_OAC_keyBind"), Keyboard.KEY_E)
	OAC.options.autoOpen = options:addTickBox("OAC_autoOpen", getText("UI_options_OAC_autoOpen"), true, getText("UI_options_OAC_autoOpen_tooltip"))
	OAC.options.autoClose = options:addTickBox("OAC_autoClose", getText("UI_options_OAC_autoClose"), false, getText("UI_options_OAC_autoClose_tooltip"))
end

OAC.initOptions()