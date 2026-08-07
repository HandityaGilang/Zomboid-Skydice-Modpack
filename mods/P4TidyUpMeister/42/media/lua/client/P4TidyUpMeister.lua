local P4TidyUpMeister = {}

P4TidyUpMeister.player = nil
P4TidyUpMeister.needsReequip = false
P4TidyUpMeister.doNotReequip = false
P4TidyUpMeister.ignoreStop = false
P4TidyUpMeister.primaryItem = nil
P4TidyUpMeister.isPrimaryActivated = false
P4TidyUpMeister.secondaryItem = nil
P4TidyUpMeister.isSecondaryActivated = false
P4TidyUpMeister.wornItems = {}
P4TidyUpMeister.transferredItems = {}
P4TidyUpMeister.floorItems = {}
P4TidyUpMeister.worldRotations = {}
P4TidyUpMeister.useInventoryTetris = false
P4TidyUpMeister.isReequipping = false

P4TidyUpMeister.temp = {}
P4TidyUpMeister.temp.needsReequip = false
P4TidyUpMeister.temp.ignoreStop = false
P4TidyUpMeister.temp.primaryItem = nil
P4TidyUpMeister.temp.isPrimaryActivated = false
P4TidyUpMeister.temp.secondaryItem = nil
P4TidyUpMeister.temp.isSecondaryActivated = false
P4TidyUpMeister.temp.wornItems = {}
P4TidyUpMeister.temp.transferredItems = {}
P4TidyUpMeister.temp.floorItems = {}
P4TidyUpMeister.temp.worldRotations = {}

P4TidyUpMeister.Messages_ToDoReequip = getText("UI_P4TidyUpMeister_Messages_ToDoReequip")
P4TidyUpMeister.Messages_ToDoNotReequip = getText("UI_P4TidyUpMeister_Messages_ToDoNotReequip")
P4TidyUpMeister.ContextMenu_ToDoReequip = getText("ContextMenu_P4TidyUpMeister_ToDoReequip")
P4TidyUpMeister.ContextMenu_ToDoNotReequip = getText("ContextMenu_P4TidyUpMeister_ToDoNotReequip")

-- *****************************************************************************
-- * Options
-- *****************************************************************************

P4TidyUpMeister.options = {
	ForceReequip = nil,
	UseContextMenu = nil,
	RestoreLocation = nil,
	EnableBuild = nil,
	EnableFirearms = nil,
	EnableFitness = nil,
	EnableEatFood = nil,
	EnableTakePills = nil,
	EnableReading = nil,
	EnableMedical = nil,
	EnableTailoring = nil,
	EnableLightFire = nil,
	EnableRefueling = nil,
}

P4TidyUpMeister.initOption = function()
	local options = PZAPI.ModOptions:create("P4TidyUpMeister", "Tidy Up Meister")
	P4TidyUpMeister.options.ForceReequip = options:addTickBox("ForceReequip", getText("UI_P4TidyUpMeister_Options_ForceReequip_Name"), false, getText("UI_P4TidyUpMeister_Options_ForceReequip_Tooltip"))
	P4TidyUpMeister.options.UseContextMenu = options:addTickBox("UseContextMenu", getText("UI_P4TidyUpMeister_Options_UseContextMenu_Name"), true, getText("UI_P4TidyUpMeister_Options_UseContextMenu_Tooltip"))
	P4TidyUpMeister.options.RestoreLocation = options:addTickBox("RestoreLocation", getText("UI_P4TidyUpMeister_Options_RestoreLocation_Name"), true, getText("UI_P4TidyUpMeister_Options_RestoreLocation_Tooltip"))
	P4TidyUpMeister.options.EnableBuild = options:addTickBox("EnableBuild", getText("UI_P4TidyUpMeister_Options_EnableBuild_Name"), true, getText("UI_P4TidyUpMeister_Options_EnableBuild_Tooltip"))
	P4TidyUpMeister.options.EnableFirearms = options:addTickBox("EnableFirearms", getText("UI_P4TidyUpMeister_Options_EnableFirearms_Name"), true, getText("UI_P4TidyUpMeister_Options_EnableFirearms_Tooltip"))
	P4TidyUpMeister.options.EnableFitness = options:addTickBox("EnableFitness", getText("UI_P4TidyUpMeister_Options_EnableFitness_Name"), true, getText("UI_P4TidyUpMeister_Options_EnableFitness_Tooltip"))
	P4TidyUpMeister.options.EnableEatFood = options:addTickBox("EnableEatFood", getText("UI_P4TidyUpMeister_Options_EnableEatFood_Name"), true, getText("UI_P4TidyUpMeister_Options_EnableEatFood_Tooltip"))
	P4TidyUpMeister.options.EnableTakePills = options:addTickBox("EnableTakePills", getText("UI_P4TidyUpMeister_Options_EnableTakePills_Name"), true, getText("UI_P4TidyUpMeister_Options_EnableTakePills_Tooltip"))
	P4TidyUpMeister.options.EnableReading = options:addTickBox("EnableReading", getText("UI_P4TidyUpMeister_Options_EnableReading_Name"), true, getText("UI_P4TidyUpMeister_Options_EnableReading_Tooltip"))
	P4TidyUpMeister.options.EnableMedical = options:addTickBox("EnableMedical", getText("UI_P4TidyUpMeister_Options_EnableMedical_Name"), true, getText("UI_P4TidyUpMeister_Options_EnableMedical_Tooltip"))
	P4TidyUpMeister.options.EnableTailoring = options:addTickBox("EnableTailoring", getText("UI_P4TidyUpMeister_Options_EnableTailoring_Name"), true, getText("UI_P4TidyUpMeister_Options_EnableTailoring_Tooltip"))
	P4TidyUpMeister.options.EnableLightFire = options:addTickBox("EnableLightFire", getText("UI_P4TidyUpMeister_Options_EnableLightFire_Name"), true, getText("UI_P4TidyUpMeister_Options_EnableLightFire_Tooltip"))
	P4TidyUpMeister.options.EnableRefueling = options:addTickBox("EnableRefueling", getText("UI_P4TidyUpMeister_Options_EnableRefueling_Name"), true, getText("UI_P4TidyUpMeister_Options_EnableRefueling_Tooltip"))
end
P4TidyUpMeister.initOption()

-- *****************************************************************************
-- * ModData functions
-- *****************************************************************************

P4TidyUpMeister.setDoNotReequip = function()
	local modData = P4TidyUpMeister.player:getModData()
	if not modData.P4TidyUpMeister then
		modData.P4TidyUpMeister = {}
		modData.P4TidyUpMeister.doNotReequip = false
	end
	P4TidyUpMeister.doNotReequip = modData.P4TidyUpMeister.doNotReequip
end

P4TidyUpMeister.toggleDoNotReequip = function()
	local modData = P4TidyUpMeister.player:getModData()
	modData.P4TidyUpMeister.doNotReequip = not modData.P4TidyUpMeister.doNotReequip
	P4TidyUpMeister.doNotReequip = modData.P4TidyUpMeister.doNotReequip
	if P4TidyUpMeister.doNotReequip then
		P4TidyUpMeister.showInfo(P4TidyUpMeister.Messages_ToDoNotReequip)
	else
		P4TidyUpMeister.showInfo(P4TidyUpMeister.Messages_ToDoReequip)
	end
end

-- *****************************************************************************
-- * Overwrite functions
-- *****************************************************************************

-- [SET] Most actions via context menu
P4TidyUpMeister.ISWorldObjectContextMenu_equip = ISWorldObjectContextMenu.equip
function ISWorldObjectContextMenu.equip(...)
	-- Even if already have tools equipped, this function will always be called, so start the hook here.
	P4TidyUpMeister.set(P4TidyUpMeister.player)
	return P4TidyUpMeister.ISWorldObjectContextMenu_equip(...)
end

-- [SET] Common
P4TidyUpMeister.ISInventoryPaneContextMenu_onEmptyWaterContainer = ISInventoryPaneContextMenu.onEmptyWaterContainer
function ISInventoryPaneContextMenu.onEmptyWaterContainer(...)
	P4TidyUpMeister.set(P4TidyUpMeister.player)
	P4TidyUpMeister.ISInventoryPaneContextMenu_onEmptyWaterContainer(...)
end

-- [SET] Common
P4TidyUpMeister.ISInventoryPaneContextMenu_onDumpContents = ISInventoryPaneContextMenu.onDumpContents
function ISInventoryPaneContextMenu.onDumpContents(...)
	P4TidyUpMeister.set(P4TidyUpMeister.player)
	P4TidyUpMeister.ISInventoryPaneContextMenu_onDumpContents(...)
end

-- [SET] Build
P4TidyUpMeister.ISBuildAction_new = ISBuildAction.new
function ISBuildAction:new(...)
	if P4TidyUpMeister.options.EnableBuild.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	return P4TidyUpMeister.ISBuildAction_new(self, ...)
end

-- [SET] Build
P4TidyUpMeister.ISBuildMenu_onMultiStageBuildSelected = ISBuildMenu.onMultiStageBuildSelected
function ISBuildMenu.onMultiStageBuildSelected(...)
	if P4TidyUpMeister.options.EnableBuild.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISBuildMenu_onMultiStageBuildSelected(...)
end

-- [SET] Firearms (Upgrade weapon)
P4TidyUpMeister.ISInventoryPaneContextMenu_onUpgradeWeapon = ISInventoryPaneContextMenu.onUpgradeWeapon
function ISInventoryPaneContextMenu.onUpgradeWeapon(...)
	if P4TidyUpMeister.options.EnableFirearms.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onUpgradeWeapon(...)
end

-- [SET] Firearms (Remove upgrade weapon)
P4TidyUpMeister.ISInventoryPaneContextMenu_onRemoveUpgradeWeapon = ISInventoryPaneContextMenu.onRemoveUpgradeWeapon
function ISInventoryPaneContextMenu.onRemoveUpgradeWeapon(...)
	if P4TidyUpMeister.options.EnableFirearms.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onRemoveUpgradeWeapon(...)
end

-- [SET] Firearms (Insert magazine)
P4TidyUpMeister.ISInventoryPaneContextMenu_onInsertMagazine = ISInventoryPaneContextMenu.onInsertMagazine
function ISInventoryPaneContextMenu.onInsertMagazine(...)
	if P4TidyUpMeister.options.EnableFirearms.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onInsertMagazine(...)
end

-- [SET] Firearms (Eject magazine)
P4TidyUpMeister.ISInventoryPaneContextMenu_onEjectMagazine = ISInventoryPaneContextMenu.onEjectMagazine
function ISInventoryPaneContextMenu.onEjectMagazine(...)
	if P4TidyUpMeister.options.EnableFirearms.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onEjectMagazine(...)
end

-- [SET] Firearms (Load bullets into firearm)
P4TidyUpMeister.ISInventoryPaneContextMenu_onLoadBulletsIntoFirearm = ISInventoryPaneContextMenu.onLoadBulletsIntoFirearm
function ISInventoryPaneContextMenu.onLoadBulletsIntoFirearm(...)
	if P4TidyUpMeister.options.EnableFirearms.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onLoadBulletsIntoFirearm(...)
end

-- [SET] Firearms (Unload bullets from firearm)
P4TidyUpMeister.ISInventoryPaneContextMenu_onUnloadBulletsFromFirearm = ISInventoryPaneContextMenu.onUnloadBulletsFromFirearm
function ISInventoryPaneContextMenu.onUnloadBulletsFromFirearm(...)
	if P4TidyUpMeister.options.EnableFirearms.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onUnloadBulletsFromFirearm(...)
end

-- [SET] Firearms (Load bullets in magazine)
P4TidyUpMeister.ISInventoryPaneContextMenu_onLoadBulletsInMagazine = ISInventoryPaneContextMenu.onLoadBulletsInMagazine
function ISInventoryPaneContextMenu.onLoadBulletsInMagazine(...)
	if P4TidyUpMeister.options.EnableFirearms.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onLoadBulletsInMagazine(...)
end

-- [SET] Firearms (Load bullets in magazine)
P4TidyUpMeister.ISInventoryPaneContextMenu_onUnloadBulletsFromMagazine = ISInventoryPaneContextMenu.onUnloadBulletsFromMagazine
function ISInventoryPaneContextMenu.onUnloadBulletsFromMagazine(...)
	if P4TidyUpMeister.options.EnableFirearms.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onUnloadBulletsFromMagazine(...)
end

-- [SET] Firearms (Rack gun)
P4TidyUpMeister.ISInventoryPaneContextMenu_onRackGun = ISInventoryPaneContextMenu.onRackGun
function ISInventoryPaneContextMenu.onRackGun(...)
	if P4TidyUpMeister.options.EnableFirearms.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onRackGun(...)
end

-- [SET] Fitness
P4TidyUpMeister.ISFitnessAction_new = ISFitnessAction.new
function ISFitnessAction:new(...)
	if P4TidyUpMeister.options.EnableFitness.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player, true)
	end
	return P4TidyUpMeister.ISFitnessAction_new(self, ...)
end

-- [SET] Eat food
P4TidyUpMeister.ISInventoryPaneContextMenu_onEatItems = ISInventoryPaneContextMenu.onEatItems
function ISInventoryPaneContextMenu.onEatItems(...)
	if P4TidyUpMeister.options.EnableEatFood.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onEatItems(...)
end

-- [SET] Eat food (Drink)
P4TidyUpMeister.ISInventoryPaneContextMenu_onDrinkForThirst = ISInventoryPaneContextMenu.onDrinkForThirst
function ISInventoryPaneContextMenu.onDrinkForThirst(...)
	if P4TidyUpMeister.options.EnableEatFood.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onDrinkForThirst(...)
end

-- [SET] Eat food (Drink)
P4TidyUpMeister.ISInventoryPaneContextMenu_onDrink = ISInventoryPaneContextMenu.onDrink
function ISInventoryPaneContextMenu.onDrink(...)
	if P4TidyUpMeister.options.EnableEatFood.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onDrink(...)
end

-- [SET] Eat food (Drink)
P4TidyUpMeister.ISInventoryPaneContextMenu_onDrinkFluid = ISInventoryPaneContextMenu.onDrinkFluid
function ISInventoryPaneContextMenu.onDrinkFluid(...)
	if P4TidyUpMeister.options.EnableEatFood.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onDrinkFluid(...)
end

-- [SET] Take pills
P4TidyUpMeister.ISInventoryPaneContextMenu_onPillsItems = ISInventoryPaneContextMenu.onPillsItems
function ISInventoryPaneContextMenu.onPillsItems(...)
	if P4TidyUpMeister.options.EnableTakePills.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onPillsItems(...)
end

-- [SET] Reading
P4TidyUpMeister.ISInventoryPaneContextMenu_onLiteratureItems = ISInventoryPaneContextMenu.onLiteratureItems
function ISInventoryPaneContextMenu.onLiteratureItems(...)
	if P4TidyUpMeister.options.EnableReading.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onLiteratureItems(...)
end

-- [SET] Medical (Health Panel)
P4TidyUpMeister.HealthPanelAction_new = HealthPanelAction.new
function HealthPanelAction:new(...)
	if P4TidyUpMeister.options.EnableMedical.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	return P4TidyUpMeister.HealthPanelAction_new(self, ...)
end

-- [SET] Medical (DryMyself)
P4TidyUpMeister.ISInventoryPaneContextMenu_onDryMyself = ISInventoryPaneContextMenu.onDryMyself
function ISInventoryPaneContextMenu.onDryMyself(...)
	if P4TidyUpMeister.options.EnableMedical.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onDryMyself(...)
end

P4TidyUpMeister.ISDryMyself_stop = ISDryMyself.stop
function ISDryMyself:stop()
	-- Reset is called when action is stopped, so it needs to evacuate and revert.
	P4TidyUpMeister.evacuate()
	P4TidyUpMeister.ISDryMyself_stop(self)
	P4TidyUpMeister.revert()
	P4TidyUpMeister.reequip(P4TidyUpMeister.player)
end

-- [SET] Tailoring (Repair)
P4TidyUpMeister.ISInventoryPaneContextMenu_repairClothing = ISInventoryPaneContextMenu.repairClothing
function ISInventoryPaneContextMenu.repairClothing(...)
	if P4TidyUpMeister.options.EnableTailoring.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_repairClothing(...)
end

-- [SET] Tailoring (Remove patch)
P4TidyUpMeister.ISInventoryPaneContextMenu_removePatch = ISInventoryPaneContextMenu.removePatch
function ISInventoryPaneContextMenu.removePatch(...)
	if P4TidyUpMeister.options.EnableTailoring.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_removePatch(...)
end

-- [SET] Mechanics (Install part)
P4TidyUpMeister.ISVehiclePartMenu_onInstallPart = ISVehiclePartMenu.onInstallPart
function ISVehiclePartMenu.onInstallPart(...)
	-- Notice : Mechanics is always be processed as the basic function.
	P4TidyUpMeister.set(P4TidyUpMeister.player)
	P4TidyUpMeister.ISVehiclePartMenu_onInstallPart(...)
end

-- [SET] Mechanics (Uninstall part)
P4TidyUpMeister.ISVehiclePartMenu_onUninstallPart = ISVehiclePartMenu.onUninstallPart
function ISVehiclePartMenu.onUninstallPart(...)
	-- Notice : Mechanics is always be processed as the basic function.
	P4TidyUpMeister.set(P4TidyUpMeister.player)
	P4TidyUpMeister.ISVehiclePartMenu_onUninstallPart(...)
end

-- [SET] Mechanics (Fix)
P4TidyUpMeister.ISInventoryPaneContextMenu_onFix = ISInventoryPaneContextMenu.onFix
function ISInventoryPaneContextMenu.onFix(...)
	-- Notice : Mechanics is always be processed as the basic function.
	P4TidyUpMeister.set(P4TidyUpMeister.player)
	P4TidyUpMeister.ISInventoryPaneContextMenu_onFix(...)
end

-- [SET] Light fire (Campfire/BBQ/Fireplace)
P4TidyUpMeister.ISCampingMenu_onLightFromLiterature = ISCampingMenu.onLightFromLiterature
function ISCampingMenu.onLightFromLiterature(...)
	if P4TidyUpMeister.options.EnableLightFire.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISCampingMenu_onLightFromLiterature(...)
end

-- [SET] Light fire (Campfire/BBQ/Fireplace)
P4TidyUpMeister.ISCampingMenu_onLightFromPetrol = ISCampingMenu.onLightFromPetrol
function ISCampingMenu.onLightFromPetrol(...)
	if P4TidyUpMeister.options.EnableLightFire.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISCampingMenu_onLightFromPetrol(...)
end

-- [SET] Light fire (Campfire/BBQ/Fireplace)
P4TidyUpMeister.ISCampingMenu_onLightFromKindle = ISCampingMenu.onLightFromKindle
function ISCampingMenu.onLightFromKindle(...)
	if P4TidyUpMeister.options.EnableLightFire.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player, true)
	end
	P4TidyUpMeister.ISCampingMenu_onLightFromKindle(...)
end

-- [SET] Refueling (Add Fuel)
P4TidyUpMeister.ISVehiclePartMenu_onAddFuelNew = ISVehiclePartMenu.onAddFuelNew
function ISVehiclePartMenu.onAddFuelNew(...)
	if P4TidyUpMeister.options.EnableRefueling.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISVehiclePartMenu_onAddFuelNew(...)
end

-- [SET] Refueling (Take Fuel)
P4TidyUpMeister.ISWorldObjectContextMenu_onTakeFuel = ISWorldObjectContextMenu.onTakeFuel
function ISWorldObjectContextMenu.onTakeFuel(...)
	if P4TidyUpMeister.options.EnableRefueling.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISWorldObjectContextMenu_onTakeFuel(...)
end

-- [SET] Refueling (Take Fuel)
P4TidyUpMeister.ISWorldObjectContextMenu_onTakeFuelNew = ISWorldObjectContextMenu.onTakeFuelNew
function ISWorldObjectContextMenu.onTakeFuelNew(...)
	if P4TidyUpMeister.options.EnableRefueling.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISWorldObjectContextMenu_onTakeFuelNew(...)
end

-- [SET] Refueling (Take Fuel)
P4TidyUpMeister.ISVehiclePartMenu_onTakeFuelNew = ISVehiclePartMenu.onTakeFuelNew
function ISVehiclePartMenu.onTakeFuelNew(...)
	if P4TidyUpMeister.options.EnableRefueling.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISVehiclePartMenu_onTakeFuelNew(...)
end

-- [SET] Refueling (Add Gasoline)
P4TidyUpMeister.ISVehiclePartMenu_onAddGasoline = ISVehiclePartMenu.onAddGasoline
function ISVehiclePartMenu.onAddGasoline(...)
	if P4TidyUpMeister.options.EnableRefueling.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISVehiclePartMenu_onAddGasoline(...)
end

-- [SET] Refueling (Take Gasoline)
P4TidyUpMeister.ISVehiclePartMenu_onTakeGasoline = ISVehiclePartMenu.onTakeGasoline
function ISVehiclePartMenu.onTakeGasoline(...)
	if P4TidyUpMeister.options.EnableRefueling.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISVehiclePartMenu_onTakeGasoline(...)
end

-- [SET] Fishing (Add Bait)
P4TidyUpMeister.AIAttachLureAction_new = AIAttachLureAction.new
function AIAttachLureAction:new(...)
	P4TidyUpMeister.set(P4TidyUpMeister.player)
	return P4TidyUpMeister.AIAttachLureAction_new(self, ...)
end

-- [SET] Fishing (Remove Bait)
P4TidyUpMeister.AIRemoveLureAction_new = AIRemoveLureAction.new
function AIRemoveLureAction:new(...)
	P4TidyUpMeister.set(P4TidyUpMeister.player)
	return P4TidyUpMeister.AIRemoveLureAction_new(self, ...)
end

P4TidyUpMeister.ISInventoryTransferAction_new = ISInventoryTransferAction.new
function ISInventoryTransferAction:new(player, item, srcContainer, destContainer, time)
	P4TidyUpMeister.setTransferredItem(item)
	return P4TidyUpMeister.ISInventoryTransferAction_new(self, player, item, srcContainer, destContainer, time)
end

P4TidyUpMeister.ISInventoryTransferAction_start = ISInventoryTransferAction.start
function ISInventoryTransferAction:start()
	P4TidyUpMeister.setTransferredItem(self.item)
	P4TidyUpMeister.ISInventoryTransferAction_start(self)
end

P4TidyUpMeister.ISBaseTimedAction_stop = ISBaseTimedAction.stop
function ISBaseTimedAction:stop()
	if P4TidyUpMeister.player == self.character then
		P4TidyUpMeister.ISBaseTimedAction_stop(self)
		if not P4TidyUpMeister.ignoreStop then
			if P4TidyUpMeister.options.ForceReequip.value then
				P4TidyUpMeister.forceReequip(self.character)
			else
				P4TidyUpMeister.reset()
			end
		end
	end
end

-- *****************************************************************************
-- * For Compatible functions
-- *****************************************************************************
P4TidyUpMeister.loadFunctions = function()
	-- Bath Towels Overhaul
	if BathTowelsOverhaulContext then
		P4TidyUpMeister.BathTowelsOverhaul = {}

		-- [SET] Bath Towels Overhaul (Wipe Myself)
		P4TidyUpMeister.BathTowelsOverhaul.BathTowelsOverhaulContext_wipeMySelf = BathTowelsOverhaulContext.wipeMySelf
		function BathTowelsOverhaulContext.wipeMySelf(...)
			P4TidyUpMeister.set(P4TidyUpMeister.player)
			P4TidyUpMeister.BathTowelsOverhaul.BathTowelsOverhaulContext_wipeMySelf(...)
		end
	end

	-- Better Lockpicking
	if BetLock and BobbyPinActionAnim and CrowbarActionAnim then
		P4TidyUpMeister.BetterLockpicking = {}

		-- [SET] Better Lockpicking (Door with Pin)
		P4TidyUpMeister.BetterLockpicking.BetLock_UI_goToDoorBobbyPin = BetLock.UI.goToDoorBobbyPin
		function BetLock.UI.goToDoorBobbyPin(...)
			-- Reset is called when action is stopped, so it needs to evacuate and revert.
			P4TidyUpMeister.set(P4TidyUpMeister.player, true)
			P4TidyUpMeister.evacuate()
			return P4TidyUpMeister.BetterLockpicking.BetLock_UI_goToDoorBobbyPin(...)
		end

		-- [SET] Better Lockpicking (Door with crowbar)
		P4TidyUpMeister.BetterLockpicking.BetLock_UI_goToDoorCrowbar = BetLock.UI.goToDoorCrowbar
		function BetLock.UI.goToDoorCrowbar(...)
			-- Reset is called when action is stopped, so it needs to evacuate and revert.
			P4TidyUpMeister.set(P4TidyUpMeister.player, true)
			P4TidyUpMeister.evacuate()
			return P4TidyUpMeister.BetterLockpicking.BetLock_UI_goToDoorCrowbar(...)
		end

		-- [SET] Better Lockpicking (Window with crowbar)
		P4TidyUpMeister.BetterLockpicking.BetLock_UI_goToWindowCrowbar = BetLock.UI.goToWindowCrowbar
		function BetLock.UI.goToWindowCrowbar(...)
			-- Reset is called when action is stopped, so it needs to evacuate and revert.
			P4TidyUpMeister.set(P4TidyUpMeister.player, true)
			P4TidyUpMeister.evacuate()
			return P4TidyUpMeister.BetterLockpicking.BetLock_UI_goToWindowCrowbar(...)
		end

		-- [SET] Better Lockpicking (Vehicle door with Pin)
		P4TidyUpMeister.BetterLockpicking.BetLock_UI_startLockpickingVehicleDoorBobbyPin = BetLock.UI.startLockpickingVehicleDoorBobbyPin
		function BetLock.UI.startLockpickingVehicleDoorBobbyPin(...)
			-- Reset is called when action is stopped, so it needs to evacuate and revert.
			P4TidyUpMeister.set(P4TidyUpMeister.player, true)
			P4TidyUpMeister.evacuate()
			return P4TidyUpMeister.BetterLockpicking.BetLock_UI_startLockpickingVehicleDoorBobbyPin(...)
		end

		-- [SET] Better Lockpicking (Vehicle door with crowbar)
		P4TidyUpMeister.BetterLockpicking.BetLock_UI_startLockpickingVehicleDoorCrowbar = BetLock.UI.startLockpickingVehicleDoorCrowbar
		function BetLock.UI.startLockpickingVehicleDoorCrowbar(...)
			-- Reset is called when action is stopped, so it needs to evacuate and revert.
			P4TidyUpMeister.set(P4TidyUpMeister.player, true)
			P4TidyUpMeister.evacuate()
			return P4TidyUpMeister.BetterLockpicking.BetLock_UI_startLockpickingVehicleDoorCrowbar(...)
		end

		P4TidyUpMeister.BetterLockpicking.BobbyPinActionAnim_perform = BobbyPinActionAnim.perform
		function BobbyPinActionAnim:perform()
			P4TidyUpMeister.BetterLockpicking.BobbyPinActionAnim_perform(self)
			P4TidyUpMeister.revert()
			P4TidyUpMeister.reequip(P4TidyUpMeister.player)
		end

		P4TidyUpMeister.BetterLockpicking.CrowbarActionAnim_perform = CrowbarActionAnim.perform
		function CrowbarActionAnim:perform()
			P4TidyUpMeister.BetterLockpicking.CrowbarActionAnim_perform(self)
			P4TidyUpMeister.revert()
			P4TidyUpMeister.reequip(P4TidyUpMeister.player)
		end
	end

	-- Common Sense
	if CSUtils and CSISTimedAction then
		P4TidyUpMeister.CommonSense = {}
		P4TidyUpMeister.CommonSense.isPrySuccess = false

		-- [SET] Common Sense (Pry door)
		P4TidyUpMeister.CommonSense.CSUtils_PryEntityOpen = CSUtils.PryEntityOpen
		function CSUtils.PryEntityOpen(...)
			-- Reset is called when action is stopped, so it needs to evacuate and revert.
			P4TidyUpMeister.set(P4TidyUpMeister.player)
			P4TidyUpMeister.evacuate()
			-- Once the flag is turned off, explicitly execute reequip later.
			P4TidyUpMeister.needsReequip = false
			P4TidyUpMeister.CommonSense.isPrySuccess = false
			P4TidyUpMeister.CommonSense.CSUtils_PryEntityOpen(...)
		end

		-- [SET] Common Sense (Pry vehicle door)
		P4TidyUpMeister.CommonSense.CSUtils_PryVehicleOpen = CSUtils.PryVehicleOpen
		function CSUtils.PryVehicleOpen(...)
			-- Reset is called when action is stopped, so it needs to evacuate and revert.
			P4TidyUpMeister.set(P4TidyUpMeister.player)
			P4TidyUpMeister.evacuate()
			-- Once the flag is turned off, explicitly execute reequip later.
			P4TidyUpMeister.needsReequip = false
			P4TidyUpMeister.CommonSense.CSUtils_PryVehicleOpen(...)
		end

		P4TidyUpMeister.CommonSense.CSUtils_PrySuccessfully = CSUtils.PrySuccessfully
		function CSUtils.PrySuccessfully(...)
			P4TidyUpMeister.CommonSense.isPrySuccess = P4TidyUpMeister.CommonSense.CSUtils_PrySuccessfully(...)
			return P4TidyUpMeister.CommonSense.isPrySuccess
		end

		P4TidyUpMeister.CSISTimedAction_TryReturnTool = CSISTimedAction.TryReturnTool
		function CSISTimedAction:TryReturnTool()
			if P4TidyUpMeister.doNotReequip then
				P4TidyUpMeister.CSISTimedAction_TryReturnTool(self)
			end
		end

		P4TidyUpMeister.CommonSense.CSISTimedAction_stop = CSISTimedAction.stop
		function CSISTimedAction:stop()
			P4TidyUpMeister.CommonSense.CSISTimedAction_stop(self)
			if not P4TidyUpMeister.CommonSense.isPrySuccess then
				if P4TidyUpMeister.options.ForceReequip.value then
					P4TidyUpMeister.revert()
					P4TidyUpMeister.forceReequip(self.character)
				else
					P4TidyUpMeister.reset()
				end
			end
			P4TidyUpMeister.CommonSense.isPrySuccess = false
		end

		P4TidyUpMeister.CommonSense.CSISTimedAction_perform = CSISTimedAction.perform
		function CSISTimedAction:perform()
			P4TidyUpMeister.CommonSense.CSISTimedAction_perform(self)
			P4TidyUpMeister.revert()
			P4TidyUpMeister.reequip(P4TidyUpMeister.player)
			P4TidyUpMeister.CommonSense.isPrySuccess = false
		end
	end

	-- Picking Meister
	if P4PickingMeister then
		P4TidyUpMeister.P4PickingMeister = {}

		-- [SET] Picking Meister (Open and Eat)
		P4TidyUpMeister.P4PickingMeister.onOpenAndEat = P4PickingMeister.onOpenAndEat
		function P4PickingMeister.onOpenAndEat(...)
			if P4TidyUpMeister.options.EnableEatFood.value then
				P4TidyUpMeister.set(P4TidyUpMeister.player)
			end
			P4TidyUpMeister.P4PickingMeister.onOpenAndEat(...)
		end

		-- [SET] Picking Meister (Open and Drink)
		P4TidyUpMeister.P4PickingMeister.onOpenAndDrink = P4PickingMeister.onOpenAndDrink
		function P4PickingMeister.onOpenAndDrink(...)
			if P4TidyUpMeister.options.EnableEatFood.value then
				P4TidyUpMeister.set(P4TidyUpMeister.player)
			end
			P4TidyUpMeister.P4PickingMeister.onOpenAndDrink(...)
		end

		P4TidyUpMeister.P4PickingMeister.Actions_addOrDropItem = P4PickingMeister.Actions_addOrDropItem
		function P4PickingMeister.Actions_addOrDropItem(player, item)
			for transferItem,containerInfo in pairs(P4TidyUpMeister.transferredItems) do
				if instanceof(transferItem, "Food") then
					P4TidyUpMeister.transferredItems[item] = containerInfo
					break
				end
			end
			P4TidyUpMeister.P4PickingMeister.Actions_addOrDropItem(player, item)
		end

		-- [SET] Picking Meister (Retrieve All Ammo)
		P4TidyUpMeister.P4PickingMeister.onRetrieveAllAmmo = P4PickingMeister.onRetrieveAllAmmo
		function P4PickingMeister.onRetrieveAllAmmo(...)
			if P4TidyUpMeister.options.EnableFirearms.value then
				P4TidyUpMeister.set(P4TidyUpMeister.player)
			end
			P4TidyUpMeister.P4PickingMeister.onRetrieveAllAmmo(...)
		end
	end

	-- Skill Recovery Journal
	if ReadSkillRecoveryJournal and WriteSkillRecoveryJournal then
		P4TidyUpMeister.SkillRecoveryJournal = {}
		P4TidyUpMeister.SkillRecoveryJournal.contextSRJ = require("Skill Recovery Journal Context")

		-- [SET] Skill Recovery Journal (readItems)
		P4TidyUpMeister.SkillRecoveryJournal.contextSRJ_readItems = P4TidyUpMeister.SkillRecoveryJournal.contextSRJ.readItems
		function P4TidyUpMeister.SkillRecoveryJournal.contextSRJ.readItems(...)
			P4TidyUpMeister.set(P4TidyUpMeister.player)
			P4TidyUpMeister.evacuate()
			P4TidyUpMeister.SkillRecoveryJournal.contextSRJ_readItems(...)
		end

		-- [SET] Skill Recovery Journal (writeItems)
		P4TidyUpMeister.SkillRecoveryJournal.contextSRJ_writeItems = P4TidyUpMeister.SkillRecoveryJournal.contextSRJ.writeItems
		function P4TidyUpMeister.SkillRecoveryJournal.contextSRJ.writeItems(...)
			P4TidyUpMeister.set(P4TidyUpMeister.player)
			P4TidyUpMeister.evacuate()
			P4TidyUpMeister.SkillRecoveryJournal.contextSRJ_writeItems(...)
		end

		P4TidyUpMeister.SkillRecoveryJournal.ReadSkillRecoveryJournal_stop = ReadSkillRecoveryJournal.stop
		function ReadSkillRecoveryJournal:stop()
			P4TidyUpMeister.SkillRecoveryJournal.ReadSkillRecoveryJournal_stop(self)
			P4TidyUpMeister.revert()
			P4TidyUpMeister.reequip(P4TidyUpMeister.player)
		end

		P4TidyUpMeister.SkillRecoveryJournal.WriteSkillRecoveryJournal_stop = WriteSkillRecoveryJournal.stop
		function WriteSkillRecoveryJournal:stop()
			P4TidyUpMeister.SkillRecoveryJournal.WriteSkillRecoveryJournal_stop(self)
			P4TidyUpMeister.revert()
			P4TidyUpMeister.reequip(P4TidyUpMeister.player)
		end
	end
end

-- *****************************************************************************
-- * Event trigger functions
-- *****************************************************************************

P4TidyUpMeister.OnLoad = function()
	P4TidyUpMeister.loadFunctions()
end
Events.OnLoad.Add(P4TidyUpMeister.OnLoad)

P4TidyUpMeister.OnCreatePlayer = function(playerIndex, player)
	P4TidyUpMeister.player = player
	P4TidyUpMeister.useInventoryTetris = getActivatedMods():contains("INVENTORY_TETRIS")
	P4TidyUpMeister.setDoNotReequip()
end
Events.OnCreatePlayer.Add(P4TidyUpMeister.OnCreatePlayer)

P4TidyUpMeister.OnFillWorldObjectContextMenu = function(player, context, worldObjects, test)
	if P4TidyUpMeister.options.UseContextMenu.value then
		if P4TidyUpMeister.doNotReequip then
			context:addOption(P4TidyUpMeister.ContextMenu_ToDoReequip, nil, P4TidyUpMeister.toggleDoNotReequip)
		else
			context:addOption(P4TidyUpMeister.ContextMenu_ToDoNotReequip, nil, P4TidyUpMeister.toggleDoNotReequip)
		end
	end
end
Events.OnFillWorldObjectContextMenu.Add(P4TidyUpMeister.OnFillWorldObjectContextMenu)

P4TidyUpMeister.OnPlayerUpdate = function(player)
	if P4TidyUpMeister.player ~= player then
		return
	end
	if P4TidyUpMeister.needsReequip and not player:hasTimedActions() then
		P4TidyUpMeister.reequip(player)
	end
	if (not P4TidyUpMeister.needsReequip) and (not player:hasTimedActions()) then
		P4TidyUpMeister.floorItems = {}
		P4TidyUpMeister.worldRotations = {}
	end
end
Events.OnPlayerUpdate.Add(P4TidyUpMeister.OnPlayerUpdate)

-- *****************************************************************************
-- * Reequip functions
-- *****************************************************************************

P4TidyUpMeister.set = function(player, ignoreStop)
	if (not P4TidyUpMeister.needsReequip) and (not P4TidyUpMeister.doNotReequip) then
		P4TidyUpMeister.needsReequip = true
		P4TidyUpMeister.ignoreStop = ignoreStop
		P4TidyUpMeister.primaryItem = player:getPrimaryHandItem()
		if P4TidyUpMeister.primaryItem and P4TidyUpMeister.primaryItem:canBeActivated() then
			P4TidyUpMeister.isPrimaryActivated = P4TidyUpMeister.primaryItem:isActivated()
		end
		P4TidyUpMeister.secondaryItem = player:getSecondaryHandItem()
		if P4TidyUpMeister.secondaryItem and P4TidyUpMeister.secondaryItem:canBeActivated() then
			P4TidyUpMeister.isSecondaryActivated = P4TidyUpMeister.secondaryItem:isActivated()
		end
		local wornItems = player:getWornItems()
		for i=0, wornItems:size()-1 do
			local wornItem = wornItems:get(i)
			P4TidyUpMeister.wornItems[wornItem:getLocation()] = wornItem:getItem()
		end
	end
end

P4TidyUpMeister.setTransferredItem = function(item)
	if (not P4TidyUpMeister.doNotReequip) and item then
		local srcContainer = item:getContainer()
		if srcContainer then
			local containerInfo = {}
			containerInfo.container = srcContainer
			containerInfo.gridInfo = P4TidyUpMeister.getGridInfo(P4TidyUpMeister.player, item, srcContainer)
			if P4TidyUpMeister.needsReequip then
				if (not P4TidyUpMeister.transferredItems[item]) and (srcContainer:getType() ~= "none") then
					P4TidyUpMeister.transferredItems[item] = containerInfo
				end
				if srcContainer:getType() == "floor" then
					P4TidyUpMeister.setFloorItem(P4TidyUpMeister.floorItems, P4TidyUpMeister.worldRotations, item)
				end
			elseif P4TidyUpMeister.temp.needsReequip then
				if (not P4TidyUpMeister.temp.transferredItems[item]) and (srcContainer:getType() ~= "none") then
					P4TidyUpMeister.temp.transferredItems[item] = containerInfo
				end
				if srcContainer:getType() == "floor" then
					P4TidyUpMeister.setFloorItem(P4TidyUpMeister.temp.floorItems, P4TidyUpMeister.worldRotations, item)
				end
			end
		end
	end
end

P4TidyUpMeister.reset = function()
	if not P4TidyUpMeister.isReequipping then
		P4TidyUpMeister.needsReequip = false
		P4TidyUpMeister.ignoreStop = false
		P4TidyUpMeister.primaryItem = nil
		P4TidyUpMeister.isPrimaryActivated = false
		P4TidyUpMeister.secondaryItem = nil
		P4TidyUpMeister.isSecondaryActivated = false
		P4TidyUpMeister.wornItems = {}
		P4TidyUpMeister.transferredItems = {}
	end
end

P4TidyUpMeister.evacuate = function()
	P4TidyUpMeister.temp.needsReequip = P4TidyUpMeister.needsReequip
	P4TidyUpMeister.temp.ignoreStop = P4TidyUpMeister.ignoreStop
	P4TidyUpMeister.temp.primaryItem = P4TidyUpMeister.primaryItem
	P4TidyUpMeister.temp.isPrimaryActivated = P4TidyUpMeister.isPrimaryActivated
	P4TidyUpMeister.temp.secondaryItem = P4TidyUpMeister.secondaryItem
	P4TidyUpMeister.temp.isSecondaryActivated = P4TidyUpMeister.isSecondaryActivated
	P4TidyUpMeister.temp.wornItems = P4TidyUpMeister.wornItems
	P4TidyUpMeister.temp.transferredItems = P4TidyUpMeister.transferredItems
	P4TidyUpMeister.temp.floorItems = P4TidyUpMeister.floorItems
	P4TidyUpMeister.temp.worldRotations = P4TidyUpMeister.worldRotations
end

P4TidyUpMeister.revert = function()
	P4TidyUpMeister.needsReequip = P4TidyUpMeister.temp.needsReequip
	P4TidyUpMeister.ignoreStop = P4TidyUpMeister.temp.ignoreStop
	P4TidyUpMeister.primaryItem = P4TidyUpMeister.temp.primaryItem
	P4TidyUpMeister.isPrimaryActivated = P4TidyUpMeister.temp.isPrimaryActivated
	P4TidyUpMeister.secondaryItem = P4TidyUpMeister.temp.secondaryItem
	P4TidyUpMeister.isSecondaryActivated = P4TidyUpMeister.temp.isSecondaryActivated
	P4TidyUpMeister.wornItems = P4TidyUpMeister.temp.wornItems
	P4TidyUpMeister.transferredItems = P4TidyUpMeister.temp.transferredItems
	P4TidyUpMeister.floorItems = P4TidyUpMeister.temp.floorItems
	P4TidyUpMeister.worldRotations = P4TidyUpMeister.temp.worldRotations
	P4TidyUpMeister.temp.needsReequip = false
	P4TidyUpMeister.temp.ignoreStop = false
	P4TidyUpMeister.temp.primaryItem = nil
	P4TidyUpMeister.temp.isPrimaryActivated = false
	P4TidyUpMeister.temp.secondaryItem = nil
	P4TidyUpMeister.temp.isSecondaryActivated = false
	P4TidyUpMeister.temp.wornItems = {}
	P4TidyUpMeister.temp.transferredItems = {}
	P4TidyUpMeister.temp.floorItems = {}
	P4TidyUpMeister.temp.worldRotations = {}
end

P4TidyUpMeister.reequip = function(player)
	if P4TidyUpMeister.needsReequip and not P4TidyUpMeister.doNotReequip then
		P4TidyUpMeister.isReequipping = true
		local primaryItem = player:getPrimaryHandItem()
		local secondaryItem = player:getSecondaryHandItem()
		-- Check twoHands before
		local bTwoHands = false
		if P4TidyUpMeister.primaryItem and (P4TidyUpMeister.primaryItem == P4TidyUpMeister.secondaryItem) then
			bTwoHands = true
		end
		-- Check twoHans after
		local aTwoHands = false
		if primaryItem and (primaryItem == secondaryItem) then
			aTwoHands = true
		end
		-- Reequip primary item
		if P4TidyUpMeister.primaryItem then
			ISTimedActionQueue.add(ISEquipWeaponAction:new(player, P4TidyUpMeister.primaryItem, 50, true, bTwoHands))
			ISTimedActionQueue.add(P4RestoreAction:new(player, P4TidyUpMeister.primaryItem, P4TidyUpMeister.isPrimaryActivated, 0))
		else
			if primaryItem then
				ISTimedActionQueue.add(ISUnequipAction:new(player, primaryItem, 50))
			end
		end
		-- Reequip secondary item
		if P4TidyUpMeister.secondaryItem then
			if not bTwoHands then
				ISTimedActionQueue.add(ISEquipWeaponAction:new(player, P4TidyUpMeister.secondaryItem, 50, false, false))
				ISTimedActionQueue.add(P4RestoreAction:new(player, P4TidyUpMeister.secondaryItem, P4TidyUpMeister.isSecondaryActivated, 0))
			end
		else
			if secondaryItem and not aTwoHands then
				ISTimedActionQueue.add(ISUnequipAction:new(player, secondaryItem, 50))
			end
		end
		-- Reequip worn items
		local wornItems = {}
		local tempItems = player:getWornItems()
		for i=0, tempItems:size()-1 do
			local wornItem = tempItems:get(i)
			local location = wornItem:getLocation()
			wornItems[location] = wornItem:getItem()
			if not P4TidyUpMeister.wornItems[location] then
				ISTimedActionQueue.add(ISUnequipAction:new(player, wornItem:getItem(), 50))
			end
		end
		for location,wornItem in pairs(P4TidyUpMeister.wornItems) do
			if wornItem ~= wornItems[location] then
				ISTimedActionQueue.add(ISWearClothing:new(player, wornItem, 50))
			end
		end
		-- Transfer items to srcContainer
		local inventory = player:getInventory()
		local playerLoot = getPlayerLoot(player:getPlayerNum())
		for item,containerInfo in pairs(P4TidyUpMeister.transferredItems) do
			local destContainer = containerInfo.container
			local needsTransfer = false
			for _,backpack in ipairs(playerLoot.backpacks) do
				if backpack.inventory == destContainer then
					needsTransfer = true
					break
				end
			end
			if not needsTransfer then
				local containingItem = destContainer:getContainingItem()
				if containingItem then
					needsTransfer = inventory:containsRecursive(containingItem)
				end
			end
			if needsTransfer then
				local gridInfo = containerInfo.gridInfo
				if inventory:contains(item) then
					local action = ISInventoryTransferAction:new(player, item, inventory, destContainer)
					if gridInfo then
						action.setTetrisTarget(action, gridInfo.x, gridInfo.y, gridInfo.gridIndex, gridInfo.isRotated)
					end
					ISTimedActionQueue.add(action)
				else
					local replaceItem = item:getReplaceOnUse()
					if not replaceItem and instanceof(item, "DrainableComboItem") then
						replaceItem = item:getReplaceOnDeplete()
					end
					if not replaceItem then
						replaceItem = item:getReplaceType("PetrolSource")
					end
					if replaceItem then
						local invItems = inventory:getItems()
						for i=0, invItems:size()-1 do
							local invItem = invItems:get(i)
							if replaceItem == invItem:getType() or replaceItem == invItem:getFullType() then
								local action = ISInventoryTransferAction:new(player, invItem, inventory, destContainer)
								if gridInfo then
									action.setTetrisTarget(action, gridInfo.x, gridInfo.y, gridInfo.gridIndex, gridInfo.isRotated)
								end
								ISTimedActionQueue.add(action)
								break
							end
						end
					end
				end
			end
		end
		P4TidyUpMeister.isReequipping = false
		P4TidyUpMeister.reset()
	end
end

P4TidyUpMeister.forceReequip = function(player)
	if P4TidyUpMeister.needsReequip then
		player:setPrimaryHandItem(P4TidyUpMeister.primaryItem)
		player:setSecondaryHandItem(P4TidyUpMeister.secondaryItem)
		P4TidyUpMeister.reset()
	end
end

-- *****************************************************************************
-- * RestoreLocation functions
-- *****************************************************************************

P4TidyUpMeister.setFloorItem = function(floorItems, worldRotations, item)
	if P4TidyUpMeister.options.RestoreLocation.value then
		local worldItem = item:getWorldItem()
		if worldItem then
			local worldRotation = {
				x = item:getWorldXRotation(),
				y = item:getWorldYRotation(),
				z = item:getWorldZRotation()
			}
			local fullType = item:getFullType()
			floorItems[fullType] = worldItem
			worldRotations[fullType] = worldRotation
			local replaceItem = item:getReplaceOnUseFullType()
			if replaceItem then
				floorItems[replaceItem] = worldItem
				worldRotations[replaceItem] = worldRotation
			end
			if instanceof(item, "DrainableComboItem") then
				replaceItem = item:getReplaceOnDepleteFullType()
				if replaceItem then
					floorItems[replaceItem] = worldItem
					worldRotations[replaceItem] = worldRotation
				end
			end
		end
	end
end

P4TidyUpMeister.ISCraftingUI_craft = ISCraftingUI.craft
function ISCraftingUI:craft(button, all)
	if P4TidyUpMeister.options.RestoreLocation.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISCraftingUI_craft(self, button, all)
end

P4TidyUpMeister.ISInventoryPaneContextMenu_OnCraft = ISInventoryPaneContextMenu.OnCraft
function ISInventoryPaneContextMenu.OnCraft(selectedItem, recipe, player, all)
	if P4TidyUpMeister.options.RestoreLocation.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_OnCraft(selectedItem, recipe, player, all)
end

P4TidyUpMeister.ISCraftingUI_addItemInEvolvedRecipe = ISCraftingUI.addItemInEvolvedRecipe
function ISCraftingUI:addItemInEvolvedRecipe(button)
	if P4TidyUpMeister.options.RestoreLocation.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISCraftingUI_addItemInEvolvedRecipe(self, button)
end

P4TidyUpMeister.ISInventoryPaneContextMenu_onAddItemInEvoRecipe = ISInventoryPaneContextMenu.onAddItemInEvoRecipe
function ISInventoryPaneContextMenu.onAddItemInEvoRecipe(recipe, baseItem, usedItem, player)
	if P4TidyUpMeister.options.RestoreLocation.value then
		P4TidyUpMeister.set(P4TidyUpMeister.player)
	end
	P4TidyUpMeister.ISInventoryPaneContextMenu_onAddItemInEvoRecipe(recipe, baseItem, usedItem, player)
end

P4TidyUpMeister.ISInventoryTransferAction_getNotFullFloorSquare = ISInventoryTransferAction.getNotFullFloorSquare
function ISInventoryTransferAction:getNotFullFloorSquare(item)
	local dstSquare = P4TidyUpMeister.ISInventoryTransferAction_getNotFullFloorSquare(self, item)
	if P4TidyUpMeister.options.RestoreLocation.value then
		local floorItem = P4TidyUpMeister.floorItems[item:getFullType()]
		if floorItem then
			local srcSquare = floorItem:getSquare()
			if srcSquare then
				local diffX = math.abs(srcSquare:getX() - dstSquare:getX())
				local diffY = math.abs(srcSquare:getY() - dstSquare:getY())
				local diffZ = math.abs(srcSquare:getZ() - dstSquare:getZ())
				if diffX <= 1 and diffY <= 1 and diffZ == 0 then
					return srcSquare
				end
			end
		end
	end
	return dstSquare
end

P4TidyUpMeister.ISInventoryTransferAction_GetDropItemOffset = ISInventoryTransferAction.GetDropItemOffset
function ISInventoryTransferAction.GetDropItemOffset(character, square, item)
	if P4TidyUpMeister.options.RestoreLocation.value then
		local floorItem = P4TidyUpMeister.floorItems[item:getFullType()]
		if floorItem then
			return floorItem:getOffX(), floorItem:getOffY(), floorItem:getOffZ()
		end
	end
	return P4TidyUpMeister.ISInventoryTransferAction_GetDropItemOffset(character, square, item)
end

P4TidyUpMeister.ISTransferAction_GetDropItemOffset = ISTransferAction.GetDropItemOffset
function ISTransferAction.GetDropItemOffset(character, square, item)
	if P4TidyUpMeister.options.RestoreLocation.value and item then
		local floorItem = P4TidyUpMeister.floorItems[item:getFullType()]
		if floorItem then
			return floorItem:getOffX(), floorItem:getOffY(), floorItem:getOffZ()
		end
	end
	return P4TidyUpMeister.ISTransferAction_GetDropItemOffset(character, square, item)
end

P4TidyUpMeister.ISTransferAction_transferItem = ISTransferAction.transferItem
function ISTransferAction:transferItem(character, item, srcContainer, destContainer, dropSquare)
	local result = P4TidyUpMeister.ISTransferAction_transferItem(self, character, item, srcContainer, destContainer, dropSquare)
	if P4TidyUpMeister.options.RestoreLocation.value and result then
		local worldRotation = P4TidyUpMeister.worldRotations[item:getFullType()]
		if worldRotation and destContainer:getType() == "floor" then
			result:setWorldXRotation(worldRotation.x)
			result:setWorldYRotation(worldRotation.y)
			result:setWorldZRotation(worldRotation.z)
		end
	end
	return result
end

-- *****************************************************************************
-- * Utility functions
-- *****************************************************************************

P4TidyUpMeister.getGridInfo = function(player, item, srcContainer)
	if P4TidyUpMeister.useInventoryTetris then
		local srcContainerGrid = ItemContainerGrid.FindInstance(srcContainer, player:getPlayerNum())
		if srcContainerGrid then
			for _,grid in ipairs(srcContainerGrid.grids) do
				for _,stack in ipairs(grid.persistentData.stacks) do
					if stack.itemIDs[item:getID()] then
						local gridInfo = {}
						gridInfo.gridIndex = grid.gridIndex
						gridInfo.x = stack.x
						gridInfo.y = stack.y
						gridInfo.isRotated = stack.isRotated
						return gridInfo
					end
				end
			end
		end
	end
	return nil
end

P4TidyUpMeister.showInfo = function(message)
	P4TidyUpMeister.player:Say(message, 0.607, 0.717, 1.000, UIFont.Dialogue, 15, "radio")
end
