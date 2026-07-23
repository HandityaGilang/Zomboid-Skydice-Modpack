-- From "Open All Containers [B41]" mod -- Author = carlesturo

OAC = {}

OAC.keyBind = {
	name = "OpenOrClose",
	key = Keyboard.KEY_E,
}

if ModOptions and ModOptions.AddKeyBinding then
	ModOptions:AddKeyBinding("[Player Control]",OAC.keyBind)
end

OAC.options = {
  autoOpen = true,
  autoClose = false,
}

if ModOptions and ModOptions.getInstance then
	ModOptions:getInstance(OAC.options, "3465040406", "OpenAllContainers")
end