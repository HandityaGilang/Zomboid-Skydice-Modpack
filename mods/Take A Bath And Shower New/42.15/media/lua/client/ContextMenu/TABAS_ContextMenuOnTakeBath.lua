local TABAS_ContextMenuOnTakeBath = {}

local TABAS_Utils = require("TABAS_Utils")
local TABAS_Common = require("ContextMenu/TABAS_ContextMenuCommon")
local TABAS_BathShared = require("ContextMenu/TABAS_ContextMenuBathShared")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_TakeBathSession = require("Bathing/TABAS_TakeBathSession")

local COLOR_RED = "<RGB:1,0.5,0.5>"
local COLOR_GREEN = "<RGB:0.5,1,0.5>"

local TFC_MENU_BATHING = {
    fill = true,
    empty = true,
    removeStopper = false,
    putStopper = false,
    vanillaFluid = true,
    fluidTransfer = true,
}

local OPTION_KEYS_TO_REMOVE_ON_TAKE_BATH = {
    "ContextMenu_SitGround",
}

local function addTooltipRow(rows, label, value, maxValue, isBoolean)
    table.insert(rows, { label = label, value = value, maxValue = maxValue, isBoolean = isBoolean, })
end

local function buildTooltipDescription(rows)
    local description = ""
    local labelWidth = 0
    local valueWidth = 0
    local font = UIFont[getCore():getOptionTooltipFont()] or UIFont.Small

    for i = 1, #rows do
        local row = rows[i]
        if row and row.label then
            labelWidth = math.max(labelWidth, getTextManager():MeasureStringX(font, row.label .. ":") + 20)
        end
    end

    for i = 1, #rows do
        local row = rows[i]
        if row and row.spacer then
            description = description == "" and "" or description .. " <LINE> "
        elseif row and row.label and row.value ~= nil then
            local valueText = tostring(row.value)
            local lineText
            if row.isBoolean then
                valueText = row.value and getText("UI_Yes") or getText("UI_No")
                lineText = TABAS_Common.formatLabelAndBoolean(row.label, labelWidth, row.value)
            elseif row.maxValue ~= nil then
                valueText = string.format("%s / %s", row.value, row.maxValue)
                lineText = TABAS_Common.formatLabelAndInteger(row.label, labelWidth, row.value, row.maxValue)
            else
                lineText = TABAS_Common.formatLabelAndValue(row.label, labelWidth, valueText)
            end

            valueWidth = math.max(valueWidth, getTextManager():MeasureStringX(font, valueText) + 20)
            description = description == "" and lineText or (description .. " <LINE> " .. lineText)
        end
    end

    return description, labelWidth + valueWidth + 20
end

local function getSessionStateText(session)
    if not session then
        return getText("UI_No")
    end
    if session.isFinished then
        return getText("ContextMenu_TABAS_BathSessionFinished")
    end
    if session.isStopping then
        return getText("ContextMenu_TABAS_BathSessionStopping")
    end
    if session.isAutoMode then
        return getText("ContextMenu_TABAS_BathSessionAuto")
    end
    return getText("ContextMenu_TABAS_BathSessionManual")
end

local function getComfortStateText(session)
    if not session or not session.comfortReady then
        return getText("ContextMenu_TABAS_BathStatusPending")
    end

    local state = session.comfort and session.comfort.lastState or nil
    if state == "COOLING" then
        return getText("ContextMenu_TABAS_BathComfortCooling")
    end
    if state == "WARMING" then
        return getText("ContextMenu_TABAS_BathComfortWarming")
    end
    if state == "DISCOMFY" then
        return getText("ContextMenu_TABAS_BathComfortDiscomfy")
    end
    return getText("ContextMenu_TABAS_BathComfortNormal")
end

local function getGazeStateText(session)
    if not session or not session.gaze then
        return getText("ContextMenu_TABAS_BathStatusPending")
    end
    return session.gaze.active and getText("UI_Yes") or getText("UI_No")
end

function TABAS_ContextMenuOnTakeBath.removeBlockedOptions(context)
    if not context then return end

    for i=1, #OPTION_KEYS_TO_REMOVE_ON_TAKE_BATH do
        context:removeOptionByName(getText(OPTION_KEYS_TO_REMOVE_ON_TAKE_BATH[i]))
    end
end

function TABAS_ContextMenuOnTakeBath.isTakingBath(player)
    local playerObj = getSpecificPlayer(player)
    return TABAS_BathingUtils.isTakingBath(playerObj)
end

function TABAS_ContextMenuOnTakeBath.createMenuOnTakeBath(player, faucetObj, tubObj, tfc_Base, worldObjects, test, subMenu)
    local playerObj = getSpecificPlayer(player)
    local ctx = TABAS_BathShared.buildMenuContext(player, faucetObj, tubObj, tfc_Base)

    TABAS_ContextMenuOnTakeBath.addBathActionRadialMenu(playerObj, subMenu)
    TABAS_ContextMenuOnTakeBath.addBathStatusMenu(playerObj, subMenu)

    TABAS_BathShared.addTfcInfoMenu(player, tfc_Base, subMenu, ctx)
    TABAS_BathShared.addTubFluidContainerMenu(player, tfc_Base, subMenu, ctx, TFC_MENU_BATHING)
    TABAS_BathShared.addSetTemperatureMenu(player, faucetObj, subMenu, ctx)
    TABAS_BathShared.addFaucetMenu(player, faucetObj, worldObjects, test, subMenu)
    TABAS_BathShared.addShowerMenu(player, faucetObj, subMenu)
    TABAS_BathShared.addCommonDebugMenu(player, faucetObj, tubObj, tfc_Base, subMenu, ctx)
end

function TABAS_ContextMenuOnTakeBath.addBathActionRadialMenu(playerObj, subMenu)
    local option = subMenu:addOption(getText("ContextMenu_TABAS_BathActionRadial"), playerObj, TABAS_ContextMenuOnTakeBath.onOpenBathActionRadialMenu)
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip.description = getText("ContextMenu_TABAS_BathActionRadial_tooltip")
    if getJoypadData(playerObj:getPlayerNum()) then
        tooltip.description = tooltip.description .. " <BR> " .. COLOR_GREEN .. getText("ContextMenu_TABAS_BathActionRadial_tooltip2")
    end
    option.toolTip = tooltip
    option.iconTexture = getTexture("media/ui/Icons/tabas_bath_actionmenu.png")
end

function TABAS_ContextMenuOnTakeBath.onOpenBathActionRadialMenu(playerObj)
    local TABAS_BathRadialMenu = require("UI/TABAS_BathRadialMenu")
    return TABAS_BathRadialMenu.display(playerObj)
end

function TABAS_ContextMenuOnTakeBath.addBathStatusMenu(playerObj, subMenu)
    local option = subMenu:addOption(getText("ContextMenu_TABAS_CheckBathStatus"), playerObj)

    local session = TABAS_TakeBathSession:get(playerObj)
    local remainingMinutes = session and session:getRemainingMinutes() or 0
    local stance = session and (session.curStance or playerObj:getVariableString("TABAS_BathStance")) or ""
    if stance == nil or stance == "" then
        stance = getText("ContextMenu_TABAS_BathStatusPending")
    end

    local rows = {}
    -- BathStatus Tooltip Rows
    addTooltipRow(rows, getText("ContextMenu_TABAS_BathSession"), getSessionStateText(session))
    addTooltipRow(rows, getText("ContextMenu_TABAS_BathRemainingTime"), tostring(math.ceil(remainingMinutes)) .. getText("IGUI_Gametime_minutes"))
    addTooltipRow(rows, getText("ContextMenu_TABAS_BathCurrentStance"), stance)
    addTooltipRow(rows, getText("ContextMenu_TABAS_BathWashProgress"), string.format("%d / %d", session and (session.washCount or 0) or 0, session and (session.autoWashTargetCount or 0) or 0))
    -- addTooltipRow(rows, getText("ContextMenu_TABAS_BathAutoStance"), session and session.autoStanceEnabled, nil, true)
    -- addTooltipRow(rows, getText("ContextMenu_TABAS_BathAutoExt"), session and session.autoExtEnabled, nil, true)
    addTooltipRow(rows, getText("ContextMenu_TABAS_BathComfort"), getComfortStateText(session))
    addTooltipRow(rows, getText("ContextMenu_TABAS_BathFeelingGaze"), getGazeStateText(session))
    addTooltipRow(rows, getText("ContextMenu_TABAS_WaterReserved"), tostring(round(session and (session.consumedWater or 0) or 0, 2)) .. "L")
    table.insert(rows, { spacer = true })

    -- WashSelf Tooltip Rows
    local waterRequired = TABAS_TakeBathWashSelf.getRequiredWater(playerObj, true)
    local makeOff = TABAS_Utils.ModOptionsValue("WashOffMakeup")
    local bodyBlood, bodyDirt = TABAS_Utils.getBodyBloodAndDirt(playerObj)
    local bodyGrime = TABAS_Utils.getBodyGrimeDisplay(playerObj)
    if bodyBlood > 0 then
        addTooltipRow(rows, getText("Tooltip_clothing_bloody"), bodyBlood, 100)
    end
    if bodyDirt > 0 then
        addTooltipRow(rows, getText("Tooltip_clothing_dirty"), bodyDirt, 100)
    end
    if bodyGrime > 0 then
        addTooltipRow(rows, getText("ContextMenu_TABAS_BodyGrime"), bodyGrime, 100)
    end
    addTooltipRow(rows, getText("ContextMenu_TABAS_BathWashRequiredWater"), waterRequired .. "L")
    if makeOff then
        addTooltipRow(rows, getText("ContextMenu_TABAS_RemoveMakeup"), true, nil, true)
    end

    local description, width = buildTooltipDescription(rows)
    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip.defaultMyWidth = width
    tooltip.description = description
    option.toolTip = tooltip
    option.iconTexture = getTexture("media/ui/Icons/tabas_bathing_info.png")
end

function TABAS_ContextMenuOnTakeBath.onCheckBathStatus(_playerObj)
    return
end

function TABAS_ContextMenuOnTakeBath.onGetOutBath(playerObj, bathObj, towel)
    local session = TABAS_TakeBathSession:get(playerObj)
    if not session then return end
    ISTimedActionQueue.add(TABAS_TakeBathOut:new(playerObj, session, nil, towel))
end


return TABAS_ContextMenuOnTakeBath
