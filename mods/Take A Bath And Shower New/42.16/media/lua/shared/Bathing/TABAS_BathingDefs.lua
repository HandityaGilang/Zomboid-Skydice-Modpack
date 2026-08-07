local TABAS_BathingDefs = {}

TABAS_BathingDefs.ActionBlocklist = {
    ISWalkToTimedAction = true,
    ISWalkToTimedActionF = true,
    ISClimbOverFence = true,
    ISClimbSheetRopeAction = true,
    ISClimbThroughWindow = true,
    ISDigStairsAction = true,
    ISSitOnGround = true,
}

-- Disallowed actions when the bath water level is full.
-- TABAS_BathingDefs.ActionDisallowedFull = {
--     ISReadABook = true,
--     ISReadWorldMap = true,
--     ISEatFoodAction = true,
-- }

TABAS_BathingDefs.ActionWhitelist = {
    -- read book
    ISReadABook = true,
    ISReadWorldMap = true,
    -- food / drink
    ISEatFoodAction = true,
    ISDrinkFromBottle = true,
    ISDrinkFromContainer = true,
    -- fluid actions
    ISDrinkFluidAction = true,
    ISFluidEmptyAction = true,
    ISTakeWaterAction = true,
    ISFluidTransferAction = true,
    -- clothing
    ISCleanBandage = true,
    ISClothingExtraAction = true,
    ISUnequipAction = true,
    ISWashClothing = true,
    ISWearClothing = true,
    ISWringClothing = true,
    -- items
    ISAddItemInRecipe = true,
    ISHandcraftAction = true,
    ISDropWorldItemAction = true,
    ISInventoryTransferAction = true,
    ISResearchRecipe = true,
    ISExtendedPlacementAction = true,
    -- medical
    ISApplyBandage = true,
    ISCleanBurn = true,
    ISComfreyCataplasm = true,
    ISGarlicCataplasm = true,
    ISPlantainCataplasm = true,
    ISRemoveBandage = true,
    ISDisinfect = true,
    ISTakePillAction = true,
    ISStitch = true,
    ISRemoveStitch = true,
    ISRemoveGlass = true,
    ISRemoveBullet = true,
    -- misc
    ISWaitWhileGettingUp = true,
    ISRadioAction = true,
    ISDeviveBatteryAction = true,
    ISEquipWeaponAction = true,
    ISDumpContentsAction = true,
    ISDumpWaterAction = true,
    ISWashYourself = true,
    ISWakeOtherPlayer = true,
    -- panel actions
    ISFluidPanelAction = true,
}

local TakeBathActions = {
    TABAS_TakeBathOut = true,
    TABAS_TakeBathWashSelf = true,
    TABAS_TakeBathStanceChange = true,
    -- TABAS_TakeShower = true,

    TABAS_AddBathSalt = true,
    TABAS_TubStopperAction = true,
    TABAS_TubStopperRemoveAction = true,
    TABAS_TubWaterAction = true,

    TABAS_OpenPanelAction = true,
    TABAS_OpenSetTemperatureUIAction = true,
}

for k, v in pairs(TakeBathActions) do
    TABAS_BathingDefs.ActionWhitelist[k] = v
end

TABAS_BathingDefs.CursorWhitelist = {
    ISPlace3DItemCursor = true,
}

return TABAS_BathingDefs