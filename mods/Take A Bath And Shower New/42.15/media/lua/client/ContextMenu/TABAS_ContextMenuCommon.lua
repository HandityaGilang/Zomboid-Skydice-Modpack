local TABAS_ContextMenuCommon = {}

function TABAS_ContextMenuCommon.formatWaterAmount(label, setX, value, maxValue, col)
	-- Water tiles have waterAmount=9999
	-- Piped water has waterAmount=10000
	if maxValue >= 9999 then
		return string.format("%s: <SETX:%d> %s", label, setX, getText("Tooltip_WaterUnlimited"))
	end
    if col and type(col) == "table" then
        return string.format("%s: <SETX:%d> <PUSHRGB:%d,%d,%d> %s <POPRGB>L / %sL", label, setX, col[1], col[2], col[3], round(value, 2), round(maxValue, 2))
    else
        return string.format("%s: <SETX:%d> %sL / %sL", label, setX, round(value, 2), round(maxValue, 2))
    end
end

function TABAS_ContextMenuCommon.formatLabelAndBoolean(label, setX, value)
    if value then
        return string.format("%s: <SETX:%d> %s", label, setX, getText("UI_Yes"))
    else
        return string.format("%s: <SETX:%d> %s", label, setX, getText("UI_No"))
    end
end

function TABAS_ContextMenuCommon.formatLabelAndValue(label, setX, value)
    return string.format("%s: <SETX:%d> %s", label, setX, value)
end

function TABAS_ContextMenuCommon.formatLabelAndInteger(label, setX, value, maxValue)
    if maxValue then
        return string.format("%s: <SETX:%d> %s / %s", label, setX, value, maxValue)
    else
        return string.format("%s: <SETX:%d> %s", label, setX, value)
    end
end

function TABAS_ContextMenuCommon.vanillaFluidMenu(player, worldObjects, test, bathingObj, context)

end

function TABAS_ContextMenuCommon.setTemperatureMenu(player, object, context)
    local playerObj = getSpecificPlayer(player)
    local option = context:addOption(getText("ContextMenu_TABAS_SetTemperature"), object, TABAS_ContextMenuCommon.onOpenSetTempeUI, playerObj)
    local icon = "media/ui/Icons/tabas_temperatureSetting.png"
    option.iconTexture = getTexture(icon)
end

function TABAS_ContextMenuCommon.onOpenSetTempeUI(object, playerObj)
    local TABAS_MoveUtils = require("TABAS_MoveUtils")
    if TABAS_MoveUtils.walkToAdjTub(playerObj, object, true) then
        ISTimedActionQueue.add(TABAS_OpenSetTemperatureUIAction:new(playerObj, object))
    end
end

return TABAS_ContextMenuCommon
