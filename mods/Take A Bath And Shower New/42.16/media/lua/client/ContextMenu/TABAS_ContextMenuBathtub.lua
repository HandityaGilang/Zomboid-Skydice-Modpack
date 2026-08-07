local TABAS_ContextMenuBathtub = {}

local TABAS_Utils = require("TABAS_Utils")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_MoveUtils = require("TABAS_MoveUtils")
local TABAS_Common = require("ContextMenu/TABAS_ContextMenuCommon")
local TABAS_ShowerMenu = require("ContextMenu/TABAS_ContextMenuShower")
local TABAS_MenuOnTakeBath = require("ContextMenu/TABAS_ContextMenuOnTakeBath")
local TABAS_BathShared = require("ContextMenu/TABAS_ContextMenuBathShared")
local TABAS_OutfitManagement = require("TABAS_OutfitManagement")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")

local COLOR_RED = "<RGB:1,0.5,0.5>"

local function restoreOrphanBathtub(bathObj)
    local sq = bathObj and bathObj:getSquare()
    if not sq then return end

    sendClientCommand("tabas_object", "restoreOrphanBathtub", {
        x = sq:getX(),
        y = sq:getY(),
        z = sq:getZ(),
    })
end

function TABAS_ContextMenuBathtub.addOrphanRestoreMenu(player, bathObj, context)
    if not bathObj or not context then return end

    local displayName = ISWorldObjectContextMenu.getMoveableDisplayName(bathObj) or "Bathtub"
    local mainMenu = context:addOptionOnTop(displayName)
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(mainMenu, subMenu)
    mainMenu.iconTexture = getTexture("media/ui/Icons/tabas_tubicon32.png")

    subMenu:addDebugOption("Restore Orphan Bathtub", bathObj, restoreOrphanBathtub)
end

function TABAS_ContextMenuBathtub.createMenu(player, bathObj, context)
    if not bathObj then return end

    local faucetObj, tubObj = TABAS_Iso.getFullyBathObject(bathObj)
    if not faucetObj or not tubObj then
        TABAS_ContextMenuBathtub.addOrphanRestoreMenu(player, bathObj, context)
        return
    end

    local tfc_Base = TABAS_Iso.getTfcBaseOnBathObject(faucetObj)
    if not tfc_Base then return end

    local displayName = ISWorldObjectContextMenu.getMoveableDisplayName(faucetObj)

    if context:getOptionFromName(displayName) then
        context:removeOptionByName(displayName)
    end

    local mainMenu = context:addOptionOnTop(displayName)
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(mainMenu, subMenu)
    mainMenu.iconTexture = getTexture("media/ui/Icons/tabas_tubicon32.png")

    local ctx = TABAS_BathShared.buildMenuContext(player, faucetObj, tubObj, tfc_Base)
    if ctx.hasTfc then
        context.dontShowLiquidOption = true

        local tfcName = tfc_Base:getTfcName()
        if tfcName and context:getOptionFromName(tfcName) then
            context:removeOptionByName(tfcName)
        end
    end

    if TABAS_MenuOnTakeBath.isTakingBath(player) then
        TABAS_MenuOnTakeBath.createMenuOnTakeBath(player, faucetObj, tubObj, tfc_Base, subMenu)
        return
    end

    if ctx.using then
        mainMenu.notAvailable = true

        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = COLOR_RED .. getText("ContextMenu_TABAS_CurrentlyUsing")
        mainMenu.toolTip = tooltip

        TABAS_BathShared.addCommonDebugMenu(player, faucetObj, tubObj, tfc_Base, subMenu, ctx)
        return
    end

    TABAS_BathShared.addTfcInfoMenu(player, tfc_Base, subMenu, ctx)
    TABAS_ContextMenuBathtub.doTakeBathMenu(player, tfc_Base, subMenu)
    TABAS_BathShared.addTubFluidContainerMenu(player, tfc_Base, subMenu, ctx)
    TABAS_BathShared.addSetTemperatureMenu(player, faucetObj, subMenu, ctx)
    TABAS_BathShared.addShowerMenu(player, faucetObj, subMenu)
    TABAS_BathShared.addFaucetMenu(player, faucetObj, subMenu)
    TABAS_BathShared.addImprovedTubMenu(player, faucetObj, tubObj, subMenu, ctx)
    TABAS_BathShared.addCommonDebugMenu(player, faucetObj, tubObj, tfc_Base, subMenu, ctx)
end

function TABAS_ContextMenuBathtub.doTakeBathMenu(player, tfc_Base, context)
    local playerObj = getSpecificPlayer(player)
    if not playerObj or not tfc_Base or not tfc_Base:hasTfc() then return end

    local requireTowel = TABAS_Utils.ModOptionsValue("AfterBathingDrySelf")
    local towel = nil
    if requireTowel then
        towel = TABAS_Utils.getAvailableTowel(playerObj)
    end

    local keepClothes = not TABAS_Utils.ModOptionsValue("AutoClothesChange")
    local makeOff = TABAS_Utils.ModOptionsValue("WashOffMakeup")
    local isAutoMode = TABAS_Utils.ModOptionsValue("AutoTakeBathMode") == true
    local bathTime = isAutoMode and 20 or 0

    local option = context:addGetUpOption(getText("ContextMenu_TABAS_TakeBath"), player, TABAS_ContextMenuBathtub.onTakeBath, tfc_Base, towel, keepClothes, makeOff, bathTime, isAutoMode)
    option.iconTexture = getTexture("media/ui/Icons/tabas_takeBath.png")

    local tooltip = ISWorldObjectContextMenu.addToolTip()

    local tubCapacity = tfc_Base:getCapacity()
    local tubAmount = tfc_Base:getAmount()
    local temperature = tfc_Base:getWaterTemperature()
    local bathSalt = tfc_Base:getWaterData("bathSalt")
    local dirtyLevel = tfc_Base:getDirtyLevelString()

    local width = 0
    local font = UIFont[getCore():getOptionTooltipFont()] or UIFont.Small
    width = math.max(width, getTextManager():MeasureStringX(font, getText("IGUI_TABAS_BathTime") .. ":") + 20)
    width = math.max(width, getTextManager():MeasureStringX(font, getText("ContextMenu_TABAS_TubWaterAmount") .. ":") + 20)
    width = math.max(width, getTextManager():MeasureStringX(font, getText("ContextMenu_TABAS_BathTemperature") .. ":") + 20)
    width = math.max(width, getTextManager():MeasureStringX(font, getText("ContextMenu_TABAS_BathSalt") .. ":") + 20)
    width = math.max(width, getTextManager():MeasureStringX(font, getText("ContextMenu_TABAS_UseTowel") .. ":") + 20)

    tooltip.defaultMyWidth = width
    tooltip.description = TABAS_Common.formatWaterAmount(getText("ContextMenu_TABAS_TubWaterAmount"), width, tubAmount, tubCapacity)
    tooltip.description = tooltip.description .. " <LINE> " .. TABAS_Common.formatLabelAndValue(getText("ContextMenu_TABAS_BathTemperature"), width, TABAS_Utils.formatedCelsiusOrFahrenheit(temperature))
    local bathTimeText = isAutoMode and (tostring(bathTime) .. getText("IGUI_Gametime_minutes")) or "-"
    tooltip.description = tooltip.description .. " <LINE> " .. TABAS_Common.formatLabelAndValue(getText("IGUI_TABAS_BathTime"), width, bathTimeText)
    if bathSalt then
        tooltip.description = tooltip.description .. " <LINE> " .. TABAS_Common.formatLabelAndValue(getText("ContextMenu_TABAS_BathSalt"), width, getText("IGUI_TABAS_BathSalt_" .. bathSalt))
    end
    tooltip.description = tooltip.description .. " <LINE> " .. TABAS_Common.formatLabelAndValue(getText("IGUI_TABAS_BathtubInfo_Dirty"), width, dirtyLevel)
    if requireTowel then
        tooltip.description = tooltip.description .. " <LINE> " .. TABAS_Common.formatLabelAndBoolean(getText("ContextMenu_TABAS_UseTowel"), width, towel ~= nil)
    end

    local warningText, notAvailable = tfc_Base:getTakeBathWarningText(" <BR> ")
    tooltip.description = tooltip.description .. warningText

    option.notAvailable = notAvailable
    option.toolTip = tooltip
end

function TABAS_ContextMenuBathtub.onTakeBath(player, tfc_Base, towel, keepClothes, makeOff, bathTime, isAutoMode)
    if not tfc_Base then return end

    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local object = tfc_Base.bathObject
    local facing = tfc_Base.facing
    local baseSq = tfc_Base:getSquare()
    if isAutoMode == nil then
        isAutoMode = TABAS_Utils.ModOptionsValue("AutoTakeBathMode") == true
    else
        isAutoMode = isAutoMode == true
    end
    if not isAutoMode then
        bathTime = 0
    end

    if TABAS_BathingUtils.isWaterTooHot(tfc_Base) then
        TABAS_BathingUtils.sayTooHot(playerObj)
        return
    end

    if TABAS_Utils.isAleadyInTub(playerObj, tfc_Base) then
        -- Already being in the tub means there is no reserved exit route,
        -- so start in manual mode and don't carry a towel reservation.
        isAutoMode = false
        bathTime = 0
        towel = nil

        local primary = playerObj:getPrimaryHandItem()
        local secondary = playerObj:getSecondaryHandItem()

        if primary then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, primary, 20))
        end
        if secondary and secondary ~= primary then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, secondary, 20))
        end

        local curSq = playerObj:getCurrentSquare()
        if baseSq ~= curSq then
            TABAS_MoveUtils.walkToTarget(playerObj, baseSq)
        else
            TABAS_MoveUtils.walkToTarget(playerObj, curSq)
        end

        TABAS_TubFluidContainerInfoUI.setBathingPhaseStarted(playerObj)
        ISTimedActionQueue.add(TABAS_TakeBathIn:new(playerObj, object, nil, nil, makeOff, bathTime, isAutoMode, towel))
        return
    end

    local prepSq, targetSq = TABAS_MoveUtils.findPrepareAndTargetSquare(playerObj, object, facing)
    if not prepSq then
        playerObj:Say(getText("IGUI_TABAS_Unreachable"))
        return
    end

    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, prepSq))

    if towel then
        ISWorldObjectContextMenu.transferIfNeeded(playerObj, towel)
    end
    if not keepClothes then
        TABAS_OutfitManagement.onUnEquipActionQueue(playerObj, prepSq)
    end
    if not TABAS_MoveUtils.onEnterTheTub(playerObj, baseSq, prepSq, targetSq, tfc_Base) then
        return
    end

    TABAS_TubFluidContainerInfoUI.setBathingPhaseStarted(playerObj)
    ISTimedActionQueue.add(TABAS_TakeBathIn:new(playerObj, object, prepSq, targetSq, makeOff, bathTime, isAutoMode, towel))
end

local function TABAS_CreateContextMenu(player, context, worldObjects, test)
    if test and ISWorldObjectContextMenu.Test then return true end

    if TABAS_MenuOnTakeBath.isTakingBath(player) then
        TABAS_MenuOnTakeBath.removeBlockedOptions(context)
    end

    local object, type = TABAS_Iso.getBathingObjectFromWorldObjects(worldObjects)
    if not object or not type then return end

    if type == "Bathtub" then
        TABAS_ContextMenuBathtub.createMenu(player, object, context)
    elseif type == "Shower" then
        TABAS_ShowerMenu.createMenu(player, object, context)
    end
end

Events.OnFillWorldObjectContextMenu.Add(TABAS_CreateContextMenu)

return TABAS_ContextMenuBathtub
