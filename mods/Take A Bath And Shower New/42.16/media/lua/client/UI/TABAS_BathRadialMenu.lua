-- require("UI/TABAS_TubFluidContainerInfoUI")

local TABAS_BathRadialMenu = {}

local TABAS_BathRadialWashMenu = require("UI/TABAS_BathRadialWashMenu")
local TABAS_BathRadialStanceMenu = require("UI/TABAS_BathRadialStanceMenu")
local TABAS_BathRadialUtils = require("UI/TABAS_BathRadialUtils")

local OPTIONS = {
    getout = { texture = getTexture("media/ui/radial/tabas_getout.png"), text = getText("IGUI_TABAS_Radial_GetOutBath") },
    info = { texture = getTexture("media/ui/inventoryPanes/Button_Info.png"), text = getText("IGUI_TABAS_Radial_OpenInfo") },
    close = { texture = getTexture("media/ui/emotes/back_red.png"), text = getText("UI_Close") },
    stance = { texture = getTexture("media/ui/radial/tabas_stancechange.png"), text = getText("IGUI_TABAS_Radial_StanceChange") },
    wash = { texture = getTexture("media/ui/radial/tabas_washself.png"), text = getText("IGUI_TABAS_Radial_WashSelf") },
}

function TABAS_BathRadialMenu.onGetOut(playerObj)
    local session = TABAS_BathRadialUtils.getSession(playerObj)
    if not session or not TABAS_BathRadialUtils.prepareAction(playerObj, session) then return end
    ISTimedActionQueue.add(TABAS_TakeBathOut:new(playerObj, session))
end

function TABAS_BathRadialMenu.onOpenWashMenu(playerObj)
    return TABAS_BathRadialWashMenu.OpenPanel(playerObj)
end

function TABAS_BathRadialMenu.onOpenStanceMenu(playerObj)
    return TABAS_BathRadialStanceMenu.OpenPanel(playerObj)
end

function TABAS_BathRadialMenu.onOpenInfoUI(playerObj)
    local session = TABAS_BathRadialUtils.getSession(playerObj)
    if not session then return false end

    local tfc_Base = session:getTfc()
    if not tfc_Base then return false end

    TABAS_TubFluidContainerInfoUI.OpenPanel(playerObj, tfc_Base)
    return true
end

function TABAS_BathRadialMenu.close(playerObj)
    if not playerObj then return false end

    local playerNum = playerObj:getPlayerNum()
    local menu = getPlayerRadialMenu(playerNum)
    if not menu or not menu:isReallyVisible() then
        return false
    end

    if JoypadState.players[playerNum + 1] then
        setJoypadFocus(playerNum, nil)
        playerObj:setJoypadIgnoreAimUntilCentered(false)
        TABAS_BathRadialUtils.setInputActive(playerNum, true)
    end

    menu:removeFromUIManager()
    return true
end

function TABAS_BathRadialMenu.onCloseMenu(playerObj)
    return TABAS_BathRadialMenu.close(playerObj)
end

function TABAS_BathRadialMenu.fillMenu(playerObj)
    if not TABAS_BathRadialUtils.canOpen(playerObj) then return false end

    local menu = getPlayerRadialMenu(playerObj:getPlayerNum())
    menu:clear()

    menu:addSlice(OPTIONS.getout.text, OPTIONS.getout.texture, TABAS_BathRadialMenu.onGetOut, playerObj)
    menu:addSlice(OPTIONS.stance.text, OPTIONS.stance.texture, TABAS_BathRadialMenu.onOpenStanceMenu, playerObj)
    menu:addSlice(OPTIONS.info.text, OPTIONS.info.texture, TABAS_BathRadialMenu.onOpenInfoUI, playerObj)
    menu:addSlice(OPTIONS.close.text, OPTIONS.close.texture, TABAS_BathRadialMenu.onCloseMenu, playerObj)
    menu:addSlice(OPTIONS.wash.text, OPTIONS.wash.texture, TABAS_BathRadialMenu.onOpenWashMenu, playerObj)

    return TABAS_BathRadialMenu.display(playerObj, true)
end

function TABAS_BathRadialMenu.display(playerObj, skipFill)
    if not TABAS_BathRadialUtils.canOpen(playerObj) then return false end

    local playerNum = playerObj:getPlayerNum()
    local menu = getPlayerRadialMenu(playerNum)
    if not skipFill then
        TABAS_BathRadialMenu.fillMenu(playerObj)
        return true
    end
    if menu:isEmpty() then return false end

    menu:setX(getPlayerScreenLeft(playerNum) + getPlayerScreenWidth(playerNum) / 2 - menu:getWidth() / 2)
    menu:setY(getPlayerScreenTop(playerNum) + getPlayerScreenHeight(playerNum) / 2 - menu:getHeight() / 2)
    menu:addToUIManager()
    if JoypadState.players[playerNum + 1] then
        menu:setHideWhenButtonReleased(Joypad.DPadUp)
        setJoypadFocus(playerNum, menu)
        playerObj:setJoypadIgnoreAimUntilCentered(true)
        TABAS_BathRadialUtils.setInputActive(playerNum, false)
    end
    return true
end

return TABAS_BathRadialMenu
