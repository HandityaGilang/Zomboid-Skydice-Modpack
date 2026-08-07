local TABAS_ContextMenuShower = {}

local TABAS_Utils = require("TABAS_Utils")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_Common = require("ContextMenu/TABAS_ContextMenuCommon")
local TABAS_CommonDebug = require("ContextMenu/TABAS_ContextMenuCommonDebug")
local TABAS_ImprovedTubMenu = require("ContextMenu/TABAS_ImprovedTubMenu")
local TABAS_OutfitManagement = require("TABAS_OutfitManagement")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_MoveUtils = require("TABAS_MoveUtils")
local WaterReader = require("TABAS_WaterReader")

local COLOR_RED = "<RGB:1,0.5,0.5>"
-- local COLOR_YELLOW = " <RGB:1,1,0.5> "

function TABAS_ContextMenuShower.createMenu(player, showerObj, context)
    if showerObj == nil then return end

    local displayName = ISWorldObjectContextMenu.getMoveableDisplayName(showerObj)

    -- Remove vanilla menu. They will be added back later.
    if context:getOptionFromName(displayName) then
        context:removeOptionByName(displayName)
    end

    local mainMenu = context:addOptionOnTop(displayName)
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(mainMenu, subMenu)
    local texture = getTexture(showerObj:getSpriteName())
    if texture then
        mainMenu.iconTexture = texture:splitIcon()
    end

    local using = TABAS_Utils.isCurrentlyUsing(getSpecificPlayer(player), showerObj)
    if using then
        mainMenu.notAvailable = true
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = COLOR_RED .. getText("ContextMenu_TABAS_CurrentlyUsing")
        mainMenu.toolTip = tooltip
    else
        TABAS_ContextMenuShower.doShowerMenu(player, showerObj, subMenu, false)
        TABAS_Common.setTemperatureMenu(player, showerObj, subMenu)
        TABAS_Common.vanillaFluidMenu(player, showerObj, subMenu)

        if TABAS_Utils.ModOptionsValue("DisplayImproveOption") then
            TABAS_ImprovedTubMenu.doImproveShowerMenu(player, showerObj, subMenu)
        end
    end
    -- Common Debug Menu
    if TABAS_Utils.DEBUG_ENABLE then
        TABAS_CommonDebug.doDebugMenu(player, showerObj, subMenu)
    end
end

function TABAS_ContextMenuShower.doShowerMenu(player, object, context, inBath)
    local playerObj = getSpecificPlayer(player)

    local temperatureConcept = SandboxVars.TakeABathAndShower.WaterTemperatureConcept
    local waterRequired = SandboxVars.TakeABathAndShower.ShowerConsumeWater

    local soapList1 = {} -- inventory
    local soapList2 = {} -- worldItem
    local soapRemaining = 0
    local soapRequired = ISWashYourself.GetRequiredSoap(playerObj)
    if soapRequired > 0 then
        soapList1, soapRemaining = TABAS_TakeShower.getSoapsInInventory(playerObj, soapRemaining)
        soapList2, soapRemaining = TABAS_TakeShower.getSoapIdsOnSquare(object:getSquare(), soapRemaining)
    end
    local waterAmount = WaterReader.getWaterAmount(object)
    local waterCapacity = WaterReader.getWaterCapacity(object)
    local waterSourceCount = WaterReader.getExternalContainerCount(object)

    local canHot = TABAS_Iso.canHot(object)
    local temperature = 22.0
    if canHot then
        temperature = object:getModData().idealTemperature or 40.0
    end

    local isNotPiped = waterSourceCount == 0 and object:getModData().canBeWaterPiped

    local requireTowel = TABAS_Utils.ModOptionsValue("AfterBathingDrySelf")
    local towel = nil
    if requireTowel then
        towel = TABAS_Utils.getAvailableTowel(playerObj)
    end
    local keepClothes = not TABAS_Utils.ModOptionsValue("AutoClothesChange")
    local makeOff = TABAS_Utils.ModOptionsValue("WashOffMakeup")
    local bodyBlood, bodyDirt = TABAS_Utils.getBodyBloodAndDirt(playerObj)
    local bodyGrime = TABAS_Utils.getBodyGrimeDisplay(playerObj)

    local onTakeShower = inBath and TABAS_ContextMenuShower.onTakeShowerInBath or TABAS_ContextMenuShower.onTakeShower

    local subOptionTooltip = function(optionName, usesHot)
        local option = context:addGetUpOption(optionName, player, onTakeShower, object, soapList1, soapList2, soapRequired, towel, keepClothes, makeOff, usesHot)
        local iconPath = "media/ui/Icons/tabas_shower"
        local icon
        if temperatureConcept then
            if usesHot and temperature >= 38 then
                icon = iconPath .. "_hot.png"
            else
                icon = iconPath .. "_cold.png"
            end
        else
            icon = iconPath .. ".png"
        end
        option.iconTexture = getTexture(icon)

        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = ""
        if isNotPiped or temperature > 45 then
            option.notAvailable = true
            if isNotPiped then
                tooltip.description = COLOR_RED .. getText("ContextMenu_TABAS_NotPiped")
            else
                tooltip.description = COLOR_RED .. getText("ContextMenu_TABAS_TooHot")
            end
        else
            local width = 0
            local font = UIFont[getCore():getOptionTooltipFont()] or UIFont.Small
            width = math.max(width, getTextManager():MeasureStringX(font, getText("ContextMenu_WaterName") .. ":") + 20)
            width = math.max(width, getTextManager():MeasureStringX(font, getText("ContextMenu_TABAS_RequiredWater") .. ":") + 20)
            width = math.max(width, getTextManager():MeasureStringX(font, getText("ContextMenu_TABAS_SoapRemain") .. ":") + 20)
            width = math.max(width, getTextManager():MeasureStringX(font, getText("ContextMenu_TABAS_SoapRequired") .. ":") + 20)
            width = math.max(width, getTextManager():MeasureStringX(font, getText("ContextMenu_TABAS_UseTowel") .. ":") + 20)

            tooltip.defaultMyWidth = width

            local col = waterAmount < waterRequired and {1, 1, 0.5}
            tooltip.description = tooltip.description .. TABAS_Common.formatWaterAmount(getText("ContextMenu_WaterName"), width, waterAmount, waterCapacity, col)
            if waterSourceCount > 0 then
                tooltip.description = tooltip.description .. " / " .. tostring(waterSourceCount)
            end
            tooltip.description = tooltip.description .. " <LINE> " .. TABAS_Common.formatLabelAndValue(getText("ContextMenu_TABAS_RequiredWater"), width, waterRequired .. "L")
            if temperatureConcept then
                tooltip.description = tooltip.description .. " <LINE> " ..  TABAS_Common.formatLabelAndValue(getText("ContextMenu_TABAS_SetTemperature"), width, TABAS_Utils.formatedCelsiusOrFahrenheit(temperature))
            end
            if bodyBlood > 0 then
                tooltip.description = tooltip.description .. " <LINE> " .. TABAS_Common.formatLabelAndInteger(getText("Tooltip_clothing_bloody"), width, bodyBlood, 100)
            end
            if bodyDirt > 0 then
                tooltip.description = tooltip.description .. " <LINE> " .. TABAS_Common.formatLabelAndInteger(getText("Tooltip_clothing_dirty"), width, bodyDirt, 100)
            end
            if bodyGrime > 0 then
                tooltip.description = tooltip.description .. " <LINE> " .. TABAS_Common.formatLabelAndInteger(getText("ContextMenu_TABAS_BodyGrime"), width, bodyGrime, 100)
            end
            if soapRequired > 0 then
                tooltip.description = tooltip.description .. " <LINE> " .. TABAS_Common.formatLabelAndInteger(getText("ContextMenu_TABAS_SoapRemain"), width, soapRemaining)
                tooltip.description = tooltip.description .. " <LINE> " .. TABAS_Common.formatLabelAndInteger(getText("ContextMenu_TABAS_SoapRequired"), width, soapRequired)
                local availableSoap = (soapRequired <= soapRemaining)
                tooltip.description = tooltip.description .. " <LINE> " .. TABAS_Common.formatLabelAndBoolean(getText("ContextMenu_TABAS_UseSoap"), width, availableSoap)
            else
                tooltip.description = tooltip.description .. " <LINE> " .. TABAS_Common.formatLabelAndValue(getText("ContextMenu_TABAS_UseSoap"), width, getText("ContextMenu_TABAS_SoapNoNeed"))
            end
            if requireTowel then
                local canDry = towel ~= nil
                tooltip.description = tooltip.description .. " <LINE> " .. TABAS_Common.formatLabelAndBoolean(getText("ContextMenu_TABAS_UseTowel"), width, canDry)
            end
            if waterAmount < 10 then
                option.notAvailable = true
                tooltip.description = tooltip.description .. " <BR> " .. COLOR_RED .. getText("ContextMenu_TABAS_NotEnoughWater")
            elseif usesHot and not canHot then
                option.notAvailable = true
                tooltip.description = tooltip.description .. " <BR> " .. COLOR_RED .. getText("ContextMenu_TABAS_ElectricityRequired")
            end
        end
        option.toolTip = tooltip
    end

    if temperatureConcept then
        if TABAS_Utils.ModOptionsValue("DisplaysAvailableShower") then
            if canHot and temperature >= 35 then
                subOptionTooltip(getText("ContextMenu_TABAS_TakeShowerHot"), true)
            else
                subOptionTooltip(getText("ContextMenu_TABAS_TakeShowerCold"), false)
            end
        else
            subOptionTooltip(getText("ContextMenu_TABAS_TakeShowerHot"), true)
            subOptionTooltip(getText("ContextMenu_TABAS_TakeShowerCold"), false)
        end
    else
        subOptionTooltip(getText("ContextMenu_TABAS_TakeShowerHot"), true)
    end
end

function TABAS_ContextMenuShower.onTakeShower(player, object, soapList1, soapList2, comsumeSoap, towel, keepClothes, makeOff, useHot)
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local facing = TABAS_Iso.getObjectFacing(object)

    local prepSq = TABAS_MoveUtils.findPrepareSquare(playerObj, object, facing)

    if not prepSq then
        playerObj:Say(getText("IGUI_TABAS_Unreachable"))
        return
    end

    local objectSq = object:getSquare()

    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, prepSq))

    if towel then
        ISWorldObjectContextMenu.transferIfNeeded(playerObj, towel)
    end
    if not keepClothes then
        TABAS_OutfitManagement.onUnEquipActionQueue(playerObj, prepSq)
    end
    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, objectSq))

    ISTimedActionQueue.add(TABAS_TakeShower:new(playerObj, object, objectSq, facing, soapList1, soapList2, comsumeSoap, makeOff, useHot, false))

    ISTimedActionQueue.add(ISWalkToTimedAction:new(playerObj, prepSq))

    ISTimedActionQueue.add(TABAS_DrySelf:new(playerObj, towel, false))
    if not keepClothes then
        TABAS_OutfitManagement.onReEquipActionQueue(playerObj)
    end
end

function TABAS_ContextMenuShower.onTakeShowerInBath(player, object, soapList1, soapList2, comsumeSoap, towel, keepClothes, makeOff, useHot)
    if not TABAS_Iso.isBathFaucet(object) then return end
    local tfc_Base = TABAS_Iso.getTfcBaseOnBathObject(object)
    if not tfc_Base then
        TABAS_Utils.debugPrint("onTakeShowerInBath", "Invalid tfc_base!")
        return
    end
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local facing = TABAS_Iso.getObjectFacing(object)
    local baseSq = object:getSquare()

    if TABAS_BathingUtils.isWaterTooHot(tfc_Base) then
        TABAS_BathingUtils.sayTooHot(playerObj)
        return
    end

    -- do instantly shower
    if TABAS_Utils.isAleadyInTub(playerObj, tfc_Base) then
        local primary = playerObj:getPrimaryHandItem()
        local secondary = playerObj:getSecondaryHandItem()
        if primary then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, primary, 20))
        end
        if secondary and secondary ~= primary then
            ISTimedActionQueue.add(ISUnequipAction:new(playerObj, secondary, 20))
        end
        TABAS_MoveUtils.walkToTarget(playerObj, baseSq)
        TABAS_TubFluidContainerInfoUI.setBathingPhaseStarted(playerObj)
        ISTimedActionQueue.add(TABAS_TakeShower:new(playerObj, object, baseSq, facing, soapList1, soapList2, comsumeSoap, makeOff, useHot, true))
        return
    end

    -- prepare showering.
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
    ISTimedActionQueue.add(TABAS_TakeShower:new(playerObj, object, baseSq, facing, soapList1, soapList2, comsumeSoap, makeOff, useHot, true))

    TABAS_MoveUtils.onExitTheTub(playerObj, baseSq, prepSq, targetSq)

    ISTimedActionQueue.add(TABAS_DrySelf:new(playerObj, towel, false))
    if not keepClothes then
        TABAS_OutfitManagement.onReEquipActionQueue(playerObj)
    end
end

return TABAS_ContextMenuShower
