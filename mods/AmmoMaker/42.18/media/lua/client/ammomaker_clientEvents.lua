--Ammo Maker by STIMP_TM

local function onReloading(player, weapon)

	ammoMakerHandleCasingEvents(player, weapon, "reloading");

end

local function onRacking(player, weapon)

	ammoMakerHandleCasingEvents(player, weapon, "racking");

end

Events.OnPressReloadButton.Add(onReloading);
Events.OnPressRackButton.Add(onRacking);