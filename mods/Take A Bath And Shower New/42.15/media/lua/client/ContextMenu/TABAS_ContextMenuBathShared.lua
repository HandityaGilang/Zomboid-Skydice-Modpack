local TABAS_ContextMenuBathShared = {}

local TABAS_Utils = require("TABAS_Utils")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_WaterReader = require("TABAS_WaterReader")
local TABAS_Common = require("ContextMenu/TABAS_ContextMenuCommon")
local TABAS_CommonDebug = require("ContextMenu/TABAS_ContextMenuCommonDebug")
local TABAS_ImprovedTubMenu = require("ContextMenu/TABAS_ImprovedTubMenu")
local TABAS_ShowerMenu = require("ContextMenu/TABAS_ContextMenuShower")
local TFC_Menu = require("TubFluidContainer/TABAS_TubFluidContainerMenu")
local TFC_DebugMenu = require("TubFluidContainer/TABAS_TubFluidContainerDebugMenu")

local COLOR_RED = "<RGB:1,0.5,0.5>"

local function isEnabled(opts, key)
    if not opts then return true end
    if opts[key] == nil then return true end
    return opts[key]
end

function TABAS_ContextMenuBathShared.buildMenuContext(player, faucetObj, tubObj, tfc_Base)
    local playerObj = getSpecificPlayer(player)
    local displayMenu = TABAS_Utils.ModOptionsValue("DisplayBathtubMenu")

    return {
        playerObj = playerObj,
        displayMenu = displayMenu,
        showUIMenu = displayMenu <= 2,
        showContextMenu = displayMenu == 1 or displayMenu == 3,
        isDebug = TABAS_Utils.DEBUG_ENABLE,
        hasTfc = tfc_Base and tfc_Base:hasTfc() or false,
        using = playerObj and TABAS_Utils.isCurrentlyUsing(playerObj, faucetObj, tubObj) or false,
    }
end

function TABAS_ContextMenuBathShared.addTfcInfoMenu(player, tfc_Base, subMenu, ctx)
    if not ctx or not ctx.showUIMenu or not tfc_Base or not subMenu then return end
    TFC_Menu.doInfoMenu(player, tfc_Base, subMenu)
end

function TABAS_ContextMenuBathShared.addTubFluidContainerMenu(player, tfc_Base, subMenu, ctx, opts)
    if not ctx or not ctx.showContextMenu or not tfc_Base or not subMenu then return end

    if ctx.hasTfc then
        local tfcMenu = subMenu:addOption(getText("ContextMenu_TABAS_TubFluidContainer"))
        local tfcSubMenu = ISContextMenu:getNew(subMenu)
        subMenu:addSubMenu(tfcMenu, tfcSubMenu)
        tfcMenu.iconTexture = getTexture("media/ui/Icons/tabas_tubicon.png")

        local temperatureConcept = SandboxVars.TakeABathAndShower.WaterTemperatureConcept
        local enableReheat = SandboxVars.TakeABathAndShower.EnableReheat
        local canHot = TABAS_Iso.canHot(tfc_Base.bathObject)

        if isEnabled(opts, "fill") and not tfc_Base:isFull() then
            TFC_Menu.doFillTubWaterMenu(player, tfc_Base, tfcSubMenu, canHot)
        end

        if tfc_Base:hasFluid() then
            if isEnabled(opts, "empty") then
                TFC_Menu.doEmptyTubWaterMenu(player, tfc_Base, tfcSubMenu)
            end

            if isEnabled(opts, "reheat") and temperatureConcept and enableReheat and canHot then
                TFC_Menu.doReheatTubWater(player, tfc_Base, subMenu)
            end
        else
            if isEnabled(opts, "removeStopper") then
                TFC_Menu.doRemoveTubStopperMenu(player, tfc_Base, tfcSubMenu)
            end
        end

        if isEnabled(opts, "addBathSalt") and not tfc_Base:isEmpty() then
            TFC_Menu.doAddBathSaltMenu(player, tfc_Base, subMenu)
        end

        if isEnabled(opts, "vanillaFluid") then
            TABAS_Common.vanillaFluidMenu(player, nil, nil, tfc_Base.tfcObject, tfcSubMenu)
        end

        if isEnabled(opts, "fluidTransfer") then
            local fluidContainer = tfc_Base:getTubFluidContainer()
            tfcSubMenu:addOption(getText("Fluid_Transfer_Fluids"), player, ISWorldObjectContextMenu.onFluidTransfer, fluidContainer)
        end

        if ctx.isDebug and isEnabled(opts, "debug") then
            TFC_DebugMenu.doDebugMenu(player, tfc_Base, tfcSubMenu)
        end
    else
        if isEnabled(opts, "putStopper") then
            TFC_Menu.doPutTubStopperMenu(player, tfc_Base, subMenu)
        end
    end
end

function TABAS_ContextMenuBathShared.addSetTemperatureMenu(player, faucetObj, subMenu, ctx)
    if not ctx or not ctx.showContextMenu or not faucetObj or not subMenu then return end
    TABAS_Common.setTemperatureMenu(player, faucetObj, subMenu)
end

function TABAS_ContextMenuBathShared.addShowerMenu(player, faucetObj, subMenu)
    if not faucetObj or not subMenu then return end
    if TABAS_Iso.isBathWithShower(faucetObj) then
        TABAS_ShowerMenu.doShowerMenu(player, faucetObj, subMenu, true)
    end
end

function TABAS_ContextMenuBathShared.addFaucetMenu(player, faucetObj, worldObjects, test, subMenu)
    if not faucetObj or not subMenu then return end

    local faucetMenu = subMenu:addOption(getText("ContextMenu_TABAS_FaucetMenu"))
    local waterSourceCount = TABAS_WaterReader.getExternalContainerCount(faucetObj)
    faucetMenu.iconTexture = getTexture("media/ui/Icons/tabas_bathFaucet.png")

    local canBeWaterPiped = faucetObj:getModData().canBeWaterPiped
    local notPiped = waterSourceCount == 0 and canBeWaterPiped
    if notPiped then
        faucetMenu.notAvailable = true
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = COLOR_RED .. getText("ContextMenu_TABAS_NotPiped")
        faucetMenu.toolTip = tooltip
        return
    end

    local faucetSubMenu = ISContextMenu:getNew(subMenu)
    subMenu:addSubMenu(faucetMenu, faucetSubMenu)
    TABAS_Common.vanillaFluidMenu(player, worldObjects, test, faucetObj, faucetSubMenu)

    -- currently bug by vanilla fluid menu
    faucetMenu.notAvailable = true
end

function TABAS_ContextMenuBathShared.addImprovedTubMenu(player, faucetObj, tubObj, subMenu, ctx)
    if not faucetObj or not tubObj or not subMenu then return end
    if TABAS_Utils.ModOptionsValue("DisplayImproveOption") then
        TABAS_ImprovedTubMenu.doImproveTubMenu(player, faucetObj, tubObj, ctx and ctx.hasTfc, subMenu, ctx and ctx.isDebug)
    end
end

function TABAS_ContextMenuBathShared.addCommonDebugMenu(player, faucetObj, tubObj, tfc_Base, subMenu, ctx)
    if not ctx or not ctx.isDebug or not faucetObj or not subMenu then return end

    TABAS_CommonDebug.doDebugMenu(player, faucetObj, subMenu, tubObj)

    if ctx.hasTfc and ctx.displayMenu == 2 then
        TFC_DebugMenu.doDebugMenu(player, tfc_Base, subMenu)
    end
end

return TABAS_ContextMenuBathShared
