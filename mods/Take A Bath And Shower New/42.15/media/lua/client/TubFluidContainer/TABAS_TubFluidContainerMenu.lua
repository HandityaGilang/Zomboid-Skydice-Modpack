local TABAS_TubFluidContainerMenu = {}

local TABAS_Utils = require("TABAS_Utils")
local TABAS_Common = require("ContextMenu/TABAS_ContextMenuCommon")
local WaterReader = require("TABAS_WaterReader")
local BathSaltDefs = require("TABAS_BathSaltDefs")
local TABAS_MoveUtils = require("TABAS_MoveUtils")

local COLOR_RED = "<RGB:1,0.5,0.5>"

function TABAS_TubFluidContainerMenu.requestTFCWatch(playerObj, x, y, z, facing, ms)
    ms = ms or 4000
    sendClientCommand(playerObj, "tabas_tfc", "Watch", {
        x = x, y = y, z = z,
        facing = facing,
        ms = ms
    })
end

-- BathSalt Tooltip
local function bathSaltTooltip(def)
    local font = UIFont[getCore():getOptionTooltipFont()] or UIFont.Small
    local text = getText("IGUI_TABAS_BathSalt_Benefits")
    local x = getTextManager():MeasureStringX(font, text) + 20
    local setX = " <SETX:" .. x .. "> "

    local category
    for i=1, #def.benefitCategories do
        category = def.benefitCategories[i]
        if category then
            text = text .. setX .. getText("IGUI_TABAS_BathBenefit_" .. category) .. " <LINE> "
        end
    end
    return text
end

function TABAS_TubFluidContainerMenu.doInfoMenu(player, tfc_Base, subMenu)
    local option = subMenu:addOption(getText("IGUI_TABAS_BathtubInfo_Title"), player, TABAS_TubFluidContainerMenu.onTubFluidContainerInfo, tfc_Base)
    option.iconTexture = getTexture("media/ui/inventoryPanes/Button_Info.png")
end

function TABAS_TubFluidContainerMenu.onTubFluidContainerInfo(player, tfc_Base)
	local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    local modData = playerObj:getModData()
    if modData and modData.tabas_IsBathing then
        TABAS_TubFluidContainerInfoUI.OpenPanel(playerObj, tfc_Base)
        return
    end

	local square = tfc_Base:getSquare()
    local subSquare = tfc_Base:getLinkedSquare()
    if square and subSquare then
        local dist = square:DistToProper(playerObj)
        local dist2 = subSquare:DistToProper(playerObj)
        if dist > dist2 then
            square = subSquare
        end
        if TABAS_MoveUtils.walkToAdjTub(playerObj, tfc_Base.bathObject, true) then
            ISTimedActionQueue.add(TABAS_OpenPanelAction:new(playerObj, tfc_Base))
        end
    end
end

function TABAS_TubFluidContainerMenu.doPutTubStopperMenu(player, tfc_Base, subMenu)
    local option = subMenu:addOption(getText("ContextMenu_TABAS_PutTubStopper"), player, TABAS_TubFluidContainerMenu.onTubStopperAction, tfc_Base, true)
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    local icon = "media/ui/Icons/tabas_tubStopperin.png"
    option.iconTexture = getTexture(icon)
    tooltip.description = getText("ContextMenu_TABAS_PutTubStopper_tooltip")
    option.toolTip = tooltip
end

function TABAS_TubFluidContainerMenu.doRemoveTubStopperMenu(player, tfc_Base, subMenu)
    local option = subMenu:addOption(getText("ContextMenu_TABAS_RemoveTubStopper"), player, TABAS_TubFluidContainerMenu.onTubStopperAction, tfc_Base, false)
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    local icon = "media/ui/Icons/tabas_tubstopperout.png"
    option.iconTexture = getTexture(icon)
    tooltip.description = getText("ContextMenu_TABAS_RemoveTubStopper_tooltip")
    option.toolTip = tooltip
end


function  TABAS_TubFluidContainerMenu.onTubStopperAction(player, tfc_Base, plug)
    local playerObj = getSpecificPlayer(player)
    if not TABAS_MoveUtils.walkToAdjTub(playerObj, tfc_Base.bathObject, true) then return end
    if plug then
        ISTimedActionQueue.add(TABAS_TubStopperPutAction:new(playerObj, tfc_Base))
    else
        ISTimedActionQueue.add(TABAS_TubStopperRemoveAction:new(playerObj, tfc_Base))
    end
end

function TABAS_TubFluidContainerMenu.doAddBathSaltMenu(player, tfc_Base, subMenu)
    local playerObj = getSpecificPlayer(player)
    local validItems = TABAS_Utils.getNearbyItems(playerObj, nil, 1, nil, TABAS_Tag.BathSalt, TABAS_Utils.predicateDrainableComboItem)
    if not validItems or validItems:isEmpty() then return end

    local bathSaltOption = subMenu:addOption(getText("ContextMenu_TABAS_AddBathSalt"))
    local icon = "media/ui/Icons/tabas_addBathSalt.png"
    bathSaltOption.iconTexture = getTexture(icon)
    local bathSaltSubMenu = ISContextMenu:getNew(subMenu)
    subMenu:addSubMenu(bathSaltOption, bathSaltSubMenu)
    
    local addedItems = {}
    for i=1, validItems:size() do
        local item = validItems:get(i-1)
        if item then
            local def = BathSaltDefs.getDef(item:getType())
            if def then
                local name = getText(def.name)
                if not addedItems[name] then
                    addedItems[name] = {item=item, def=def}
                else
                    if addedItems[name].item:getCurrentUsesFloat() < item:getCurrentUsesFloat() then
                        addedItems[name].item = item
                    end
                end
            end
        end
    end
    for i,v in pairs(addedItems) do
        local insertOption = bathSaltSubMenu:addGetUpOption(i, player, TABAS_TubFluidContainerMenu.onAddBathSalt, tfc_Base, v.def, v.item)
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        insertOption.iconTexture = v.item:getIcon()
        if tfc_Base:canAddBathSalt(v.def.type) then
            tooltip.description = bathSaltTooltip(v.def)
        else
            insertOption.notAvailable = true
            tooltip.description = getText("ContextMenu_TABAS_AddBathSaltNotAvailable")
        end
        insertOption.toolTip = tooltip
    end
end

function TABAS_TubFluidContainerMenu.onAddBathSalt(player, tfc_Base, def, item)
    local playerObj = getSpecificPlayer(player)
    local returnToContainer = nil
    if not TABAS_MoveUtils.walkToAdjTub(playerObj, tfc_Base.bathObject, true) then return end

    if item:getContainer() ~= playerObj:getInventory() then
        returnToContainer = item:getContainer()
    end
    if returnToContainer and returnToContainer:getSquare() then
        if not luautils.walk(playerObj, returnToContainer:getSquare(), true) then
            return
        end
    end
    -- ISWorldObjectContextMenu.transferIfNeeded(playerObj, item)
    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item)
    -- Do it again in case you have to go to a remote location to retrieve it.
    if not TABAS_MoveUtils.walkToAdjTub(playerObj, tfc_Base.bathObject, true) then return end
    ISTimedActionQueue.add(TABAS_AddBathSalt:new(playerObj, tfc_Base, def, item, returnToContainer))
end

local function getFillFluid(tfc_Base)
    local bathSaltType = tfc_Base:getWaterData("bathSalt")
    local bathSaltFluid = bathSaltType and BathSaltDefs.getFluid(bathSaltType) or nil
    if bathSaltFluid then
        return bathSaltFluid
    end
    return Fluid.Water
end

function TABAS_TubFluidContainerMenu.doFillTubWaterMenu(player, tfc_Base, subMenu, canHot)
    if tfc_Base:isActivated("empty") then return end
    if not tfc_Base:isActivated("fill") then
        local option = subMenu:addOption(getText("ContextMenu_TABAS_FillTubWater"), tfc_Base, TABAS_TubFluidContainerMenu.onFillTubWater, player, true)
        local icon = "media/ui/Icons/tabas_filltub.png"
        local tooltip = ISWorldObjectContextMenu.addToolTip()

        local temperatureConcept = SandboxVars.TakeABathAndShower.WaterTemperatureConcept
        local bathObject = tfc_Base.bathObject
        local waterAmount = WaterReader.getWaterAmount(bathObject)
        local waterCapacity = WaterReader.getWaterCapacity(bathObject)
        local waterSourceCount = WaterReader.getExternalContainerCount(bathObject)
        local tubCapacity = tfc_Base:getCapacity()
        local tubAmount = tfc_Base:getAmount()
        local tubFreeCapacity = tfc_Base:getFreeCapacity()
        -- local canHot = TABAS_Iso.canHot(bathObject)
        local notPiped = waterSourceCount == 0 and bathObject:getModData().canBeWaterPiped
        local idealTemperature = tfc_Base:getBathData("idealTemperature") or 40
        local fillFluid = getFillFluid(tfc_Base)

        if notPiped then
            option.notAvailable = true
            tooltip.description = tooltip.description .. COLOR_RED .. getText("ContextMenu_TABAS_NotPiped")
        elseif waterAmount == 0 then
            option.notAvailable = true
            tooltip.description = tooltip.description .. COLOR_RED .. getText("ContextMenu_TABAS_NotEnoughWater")
        elseif not tfc_Base:canAddFluid(fillFluid) then
            option.notAvailable = true
            tooltip.description = tooltip.description .. COLOR_RED .. getText("ContextMenu_TABAS_CanNotMixWater")
        else
            local lineBreaks = " <BR> "
            local width = 0
            local font = UIFont[getCore():getOptionTooltipFont()] or UIFont.Small
            width = math.max(width, getTextManager():MeasureStringX(font, getText("ContextMenu_TABAS_TubWaterAmount") .. ":") + 20)
            width = math.max(width, getTextManager():MeasureStringX(font, getText("ContextMenu_TABAS_TubFreeCapacity") .. ":") + 20)
            width = math.max(width, getTextManager():MeasureStringX(font, getText("ContextMenu_TABAS_WaterFromFaucet") .. ":") + 20)
            width = math.max(width, getTextManager():MeasureStringX(font, getText("ContextMenu_TABAS_SetTemperature") .. ":") + 20)
            tooltip.defaultMyWidth = width
            tooltip.description = TABAS_Common.formatWaterAmount(getText("ContextMenu_TABAS_WaterFromFaucet"), width, waterAmount, waterCapacity)
            if waterSourceCount > 0 then
                tooltip.description = tooltip.description .. " / " .. tostring(waterSourceCount)
            end
            tooltip.description = tooltip.description .. lineBreaks ..  TABAS_Common.formatWaterAmount(getText("ContextMenu_TABAS_TubWaterAmount"), width, tubAmount, tubCapacity)
            tooltip.description = tooltip.description .. " <LINE> " ..  TABAS_Common.formatLabelAndValue(getText("ContextMenu_TABAS_TubFreeCapacity"), width, round(tubFreeCapacity, 2) .. "L")
            if temperatureConcept then
                tooltip.description = tooltip.description .. " <LINE> " ..  TABAS_Common.formatLabelAndValue(getText("ContextMenu_TABAS_SetTemperature"), width, TABAS_Utils.formatedCelsiusOrFahrenheit(idealTemperature))
                if canHot and idealTemperature >= 38 then
                    icon = "media/ui/Icons/tabas_filltub_hot.png"
                else
                    icon = "media/ui/Icons/tabas_filltub_cold.png"
                end
                if not canHot then
                    tooltip.description = tooltip.description .. lineBreaks .. COLOR_RED .. getText("ContextMenu_TABAS_ElectricityRequired")
                    lineBreaks = " <LINE> "
                end
            end
            if waterAmount < tubFreeCapacity then
                tooltip.description = tooltip.description .. lineBreaks .. COLOR_RED .. getText("ContextMenu_TABAS_NotEnoughWaterToFill")
            end
        end
        option.iconTexture = getTexture(icon)
        option.toolTip = tooltip
    else
        local option = subMenu:addOption(getText("ContextMenu_TABAS_FillTubWaterStop"), tfc_Base, TABAS_TubFluidContainerMenu.onFillTubWater, player, false)
        local icon = "media/ui/Icons/tabas_bathfaucet.png"
        option.iconTexture = getTexture(icon)
    end
end

function TABAS_TubFluidContainerMenu.onFillTubWater(tfc_Base, player, turnOn)
    local playerObj = getSpecificPlayer(player)
    if not TABAS_MoveUtils.walkToAdjTub(playerObj, tfc_Base.bathObject, true) then return end
    ISTimedActionQueue.add(TABAS_TubWaterAction:new(playerObj, tfc_Base, "fill", turnOn))
end

function TABAS_TubFluidContainerMenu.doEmptyTubWaterMenu(player, tfc_Base, subMenu)
    if tfc_Base:isActivated("fill") then return end
    if not tfc_Base:isActivated("empty") then
        local option = subMenu:addOption(getText("ContextMenu_TABAS_EmptyTubWater"), tfc_Base, TABAS_TubFluidContainerMenu.onEmptyTubWater, player, true)
        local icon = "media/ui/Icons/tabas_tubstopperout.png"
        option.iconTexture = getTexture(icon)
        
        local tubCapacity = tfc_Base:getCapacity()
        local tubAmount = tfc_Base:getAmount()
        local font = UIFont[getCore():getOptionTooltipFont()] or UIFont.Small
        local width = getTextManager():MeasureStringX(font, getText("ContextMenu_TABAS_TubWaterAmount") .. ":") + 10
        
        local tooltip = ISWorldObjectContextMenu.addToolTip()
        tooltip.description = tooltip.description .. TABAS_Common.formatWaterAmount(getText("ContextMenu_TABAS_TubWaterAmount"), width, tubAmount, tubCapacity)
        tooltip.description = getText("ContextMenu_TABAS_EmptyTubWater_tooltip")
        option.toolTip = tooltip
    else
        local option = subMenu:addOption(getText("ContextMenu_TABAS_EmptyTubWaterStop"), tfc_Base, TABAS_TubFluidContainerMenu.onEmptyTubWater, player, false)
        local icon = "media/ui/Icons/tabas_tubstopperin.png"
        option.iconTexture = getTexture(icon)
    end
end

function TABAS_TubFluidContainerMenu.onEmptyTubWater(tfc_Base, player, turnOn)
    local playerObj = getSpecificPlayer(player)
    if not TABAS_MoveUtils.walkToAdjTub(playerObj, tfc_Base.bathObject, true) then return end
    ISTimedActionQueue.add(TABAS_TubWaterAction:new(playerObj, tfc_Base, "empty", turnOn))
end

function TABAS_TubFluidContainerMenu.doReheatTubWater(player, tfc_Base, subMenu)
    if tfc_Base:isActivated("fill") or tfc_Base:isActivated("empty") then return end
    if not tfc_Base:isActivated("reheat") then
        local currentTemperature = tfc_Base:getWaterTemperature()
        local idealTemperature = tfc_Base:getBathData("idealTemperature") or 40

        local option = subMenu:addOption(getText("ContextMenu_TABAS_ReheatTubWater"), tfc_Base, TABAS_TubFluidContainerMenu.onReheatTubWater, player, true)
        local icon = "media/ui/Icons/tabas_tubreheat.png"
        option.iconTexture = getTexture(icon)

        local width = 0
        local font = UIFont[getCore():getOptionTooltipFont()] or UIFont.Small
        width = math.max(width, getTextManager():MeasureStringX(font, getText("ContextMenu_TABAS_CurrentTemperature") .. ":") + 20)
        width = math.max(width, getTextManager():MeasureStringX(font, getText("ContextMenu_TABAS_SetTemperature") .. ": ") + 20)

        local tooltip = ISWorldObjectContextMenu.addToolTip()
        local formatedTemp = TABAS_Utils.formatedCelsiusOrFahrenheit(currentTemperature)
        tooltip.description = TABAS_Common.formatLabelAndValue(getText("ContextMenu_TABAS_CurrentTemperature"), width, formatedTemp)
        formatedTemp = TABAS_Utils.formatedCelsiusOrFahrenheit(idealTemperature)
        tooltip.description = tooltip.description .. " <LINE> " ..  TABAS_Common.formatLabelAndValue(getText("ContextMenu_TABAS_SetTemperature"), width, formatedTemp)
        option.toolTip = tooltip
        if currentTemperature >= idealTemperature then
            option.notAvailable = true
        end
    else
        local option = subMenu:addOption(getText("ContextMenu_TABAS_ReheatTubWaterStop"), tfc_Base, TABAS_TubFluidContainerMenu.onReheatTubWater, player, false)
        local icon = "media/ui/Icons/tabas_tubreheat.png"
        option.iconTexture = getTexture(icon)
    end
end

function TABAS_TubFluidContainerMenu.onReheatTubWater(tfc_Base, player, turnOn)
    local playerObj = getSpecificPlayer(player)
    if not TABAS_MoveUtils.walkToAdjTub(playerObj, tfc_Base.bathObject, true) then return end
    ISTimedActionQueue.add(TABAS_TubWaterAction:new(playerObj, tfc_Base, "reheat", turnOn))
end

return TABAS_TubFluidContainerMenu

