local TFC_DebugMenu = {}

local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")

function TFC_DebugMenu.sendTFCDebugCommand(playerObj, tfc_Base, command, args)
    args = args or {}
    args.x = tfc_Base.x
    args.y = tfc_Base.y
    args.z = tfc_Base.z
    args.facing = tfc_Base.facing
    sendClientCommand(playerObj, 'tabas_tfc', command, args)
end

function TFC_DebugMenu.doDebugMenu(player, tfc_Base, subMenu)
    if not tfc_Base then return end

    local playerObj = getSpecificPlayer(player)
    local debugMenu = subMenu:addDebugOption("TFC Debug:")
    local debugSubMenu = ISContextMenu:getNew(subMenu)
    subMenu:addSubMenu(debugMenu, debugSubMenu)
    -- Fill Water
    TFC_DebugMenu.debugFillWater(playerObj, tfc_Base, debugSubMenu, subMenu)
    -- Fill Fluid Full
    TFC_DebugMenu.debugFillFluid(playerObj, tfc_Base, debugSubMenu, subMenu)

    -- Set Temperature 22.0
    debugSubMenu:addOption("Set Temperature: 22C", playerObj, TFC_DebugMenu.sendTFCDebugCommand, tfc_Base, 'setTemperature', {value=TFC_Utils.DefaultTemperature})
    -- Set Temperature 42.0
    debugSubMenu:addOption("Set Temperature: 42C", playerObj, TFC_DebugMenu.sendTFCDebugCommand, tfc_Base, 'setTemperature', {value=42.0})
    -- Water to Dirt +25
    debugSubMenu:addOption("Water to Dirt +25", playerObj, TFC_DebugMenu.sendTFCDebugCommand, tfc_Base, 'waterToDirt', {value=25})
    -- Water to Clean
    debugSubMenu:addOption("Water to Clean", playerObj, TFC_DebugMenu.sendTFCDebugCommand, tfc_Base, 'waterToClean')
    -- Reset This tfc_Base Object
    debugSubMenu:addOption("Clear This TFC", playerObj, TFC_DebugMenu.sendTFCDebugCommand, tfc_Base, 'clearThisTfc')
    -- Clear Activate
    debugSubMenu:addOption("Clear All Activate", playerObj, TFC_DebugMenu.sendTFCDebugCommand, tfc_Base, 'clearAllActivate')
    -- Clerr All tfc_Base
    debugSubMenu:addOption("Clear All TFC", TFC_DebugMenu.clearAllTfc)
end

function TFC_DebugMenu.debugFillWater(playerObj, tfc_Base, debugSubMenu, subMenu)
    local fillWaterOption = debugSubMenu:addOption("Fill Water:")
    local fillWaterSubMenu = ISContextMenu:getNew(subMenu)
    debugSubMenu:addSubMenu(fillWaterOption, fillWaterSubMenu)

    fillWaterSubMenu:addOption("Low (5%)", playerObj, TFC_DebugMenu.sendTFCDebugCommand, tfc_Base, 'filledWaterTo', {value=TFC_Utils.Filled_Low})
    fillWaterSubMenu:addOption("HalfLow (30%)", playerObj, TFC_DebugMenu.sendTFCDebugCommand, tfc_Base, 'filledWaterTo', {value=TFC_Utils.Filled_HalfLow})
    fillWaterSubMenu:addOption("Half (55%)", playerObj, TFC_DebugMenu.sendTFCDebugCommand, tfc_Base, 'filledWaterTo', {value=TFC_Utils.Filled_Half})
    fillWaterSubMenu:addOption("Full (80%)", playerObj, TFC_DebugMenu.sendTFCDebugCommand, tfc_Base, 'filledWaterTo', {value=TFC_Utils.Filled_Full})
    fillWaterSubMenu:addOption("Full (100%)", playerObj, TFC_DebugMenu.sendTFCDebugCommand, tfc_Base, 'filledWaterTo', {value=1})
end

function TFC_DebugMenu.debugFillFluid(playerObj, tfc_Base, debugSubMenu, subMenu)
    local debugFluidOption = subMenu:addDebugOption("Add Fluid:")
    local addFluidSubMenu = ISContextMenu:getNew(subMenu)
    debugSubMenu:addSubMenu(debugFluidOption, addFluidSubMenu)
    -- Debug Add Fluid
    local fluidNames = FluidType.getAllFluidName()
    for i=0, fluidNames:size() -1 do
        local fluidType = FluidType.FromNameLower(fluidNames:get(i))
        if Fluid.Get(fluidType) ~= nil then
            addFluidSubMenu:addOption(fluidNames:get(i), playerObj, TFC_DebugMenu.sendTFCDebugCommand, tfc_Base, 'fillFluid', {fluidType=tostring(fluidType)})
        end
    end
end

function TFC_DebugMenu.clearAllTfc()
    sendClientCommand(getSpecificPlayer(0), 'tabas_tfc', 'clearAllTfc', {})
end

return TFC_DebugMenu