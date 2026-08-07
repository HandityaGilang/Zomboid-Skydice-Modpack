-- require("UI/TABAS_TubFluidContainerInfoUI")

local TABAS_BathRadialMenu = {}

local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_TakeBathSession = require("Bathing/TABAS_TakeBathSession")
local TABAS_AnimVariables = require("Bathing/TABAS_AnimVariables")

local DEFAULT_OPTION_TEXTURE = getTexture("media/ui/Entity/BTN_Missing_Icon_48x48.png")

local OPTIONS = {
    getout = { texture = getTexture("media/ui/radial/tabas_getout.png"), text = getText("IGUI_TABAS_Radial_GetOutBath") },
    back = { texture = getTexture("media/ui/emotes/back.png"), text = getText("IGUI_TABAS_Radial_Back") },
    info = { texture = getTexture("media/ui/inventoryPanes/Button_Info.png"), text = getText("IGUI_TABAS_Radial_OpenInfo") },
    close = { texture = getTexture("media/ui/emotes/back_red.png"), text = getText("UI_Close") },
    stance = { texture = getTexture("media/ui/radial/tabas_stancechange.png"), text = getText("IGUI_TABAS_Radial_StanceChange") },
    wash = { texture = getTexture("media/ui/radial/tabas_washself.png"), text = getText("IGUI_TABAS_Radial_WashSelf") },
    -- wash part
    arms = { texture = getTexture("media/ui/radial/tabas_wash_arms.png"), text = getText("IGUI_TABAS_Radial_Arms") },
    face = { texture = getTexture("media/ui/radial/tabas_wash_face.png"), text = getText("IGUI_TABAS_Radial_Face") },
    legs = { texture = getTexture("media/ui/radial/tabas_wash_legs.png"), text = getText("IGUI_TABAS_Radial_Legs") },
    -- stances
    idle = { texture = getTexture("media/ui/radial/tabas_stance_idle.png"), text = getText("IGUI_TABAS_Radial_Idle") },
    elbowl = { texture = getTexture("media/ui/radial/tabas_stance_left.png"), text = getText("IGUI_TABAS_Radial_ElbowL") },
    elbowr = { texture = getTexture("media/ui/radial/tabas_stance_right.png"), text = getText("IGUI_TABAS_Radial_ElbowR") },
    lookup = { texture = getTexture("media/ui/radial/tabas_stance_lookup.png"), text = getText("IGUI_TABAS_Radial_LookUp") },
    relax = { texture = getTexture("media/ui/radial/tabas_stance_relax.png"), text = getText("IGUI_TABAS_Radial_Relax") },
    sit = { texture = getTexture("media/ui/radial/tabas_stance_sit.png"), text = getText("IGUI_TABAS_Radial_Sit") },
}

local OPTION_KEYS = {
    Arms = "arms",
    Face = "face",
    FaceF = "face",
    Legs = "legs",
    LegsF = "legs",
    Idle = "idle",
    ElbowL = "elbowl",
    ElbowLF = "elbowl",
    ElbowR = "elbowr",
    ElbowRF = "elbowr",
    LookUp = "lookup",
    LookUpF = "lookup",
    Relax = "relax",
    Sit = "sit",
    SitF = "sit",
}

local function getCurrentAction(playerObj)
    local queue = playerObj and ISTimedActionQueue.getTimedActionQueue(playerObj) or nil
    return queue and queue.queue and queue.queue[1] or nil
end

local function prepareRadialAction(playerObj, session)
    if not playerObj or not session or session.isFinished then
        return false
    end

    local curAction = getCurrentAction(playerObj)
    if curAction and curAction.Type == "TABAS_TakeBathOut" then
        return false
    end

    session.isAutoMode = false
    session.isStopping = false
    session.curStance = playerObj:getVariableString("TABAS_BathStance")

    if curAction then
        ISTimedActionQueue.clear(playerObj)
    end

    return TABAS_BathingUtils.isTakingBath(playerObj)
end

function TABAS_BathRadialMenu.canOpen(playerObj)
    if isGamePaused() then return false end
    if not playerObj or playerObj:isDead() then return false end
    if playerObj:getVehicle() then return false end
    if not TABAS_BathingUtils.isTakingBath(playerObj) then return false end
    return TABAS_TakeBathSession:get(playerObj) ~= nil
end

function TABAS_BathRadialMenu.getSession(playerObj)
    if not TABAS_BathRadialMenu.canOpen(playerObj) then
        return nil
    end
    return TABAS_TakeBathSession:get(playerObj)
end

function TABAS_BathRadialMenu.getNextStance(playerObj, session)
    if not playerObj or not session then return nil end

    local stances = TABAS_AnimVariables.getStances("BATH", playerObj:isFemale(), true)
    local current = session.curStance or playerObj:getVariableString("TABAS_BathStance")
    if not stances then return nil end

    for i = 1, #stances do
        if stances[i] ~= current then
            return stances[i], current
        end
    end

    return nil, current
end

function TABAS_BathRadialMenu.getStanceChoices(playerObj)
    if not playerObj then return {} end
    local stances = TABAS_AnimVariables.getStances("BATH", playerObj:isFemale(), false)
    table.insert(stances, 1, "Idle")
    return stances
end

function TABAS_BathRadialMenu.getWashChoices(playerObj)
    if not playerObj then return {} end
    return TABAS_AnimVariables.getWashParts("BATH", playerObj:isFemale(), false)
end

function TABAS_BathRadialMenu.getOption(name)
    local optionKey = OPTION_KEYS[name]
    return OPTIONS[optionKey] or {
        texture = DEFAULT_OPTION_TEXTURE,
        text = tostring(name or "")
    }
end

function TABAS_BathRadialMenu.fillWashMenu(menu, playerObj)
    local parts = TABAS_BathRadialMenu.getWashChoices(playerObj)

    if parts[1] then
        local option = TABAS_BathRadialMenu.getOption(parts[1])
        menu:addSlice(option.text, option.texture, TABAS_BathRadialMenu.onWashSelf, playerObj, parts[1])
    end
    if parts[2] then
        local option = TABAS_BathRadialMenu.getOption(parts[2])
        menu:addSlice(option.text, option.texture, TABAS_BathRadialMenu.onWashSelf, playerObj, parts[2])
    end

    menu:addSlice(OPTIONS.back.text, OPTIONS.back.texture, TABAS_BathRadialMenu.fillMenu, playerObj)

    if parts[3] then
        local option = TABAS_BathRadialMenu.getOption(parts[3])
        menu:addSlice(option.text, option.texture, TABAS_BathRadialMenu.onWashSelf, playerObj, parts[3])
    end

    for i = 4, #parts do
        local part = parts[i]
        local option = TABAS_BathRadialMenu.getOption(part)
        menu:addSlice(option.text, option.texture, TABAS_BathRadialMenu.onWashSelf, playerObj, part)
    end
end

function TABAS_BathRadialMenu.onGetOut(playerObj)
    local session = TABAS_BathRadialMenu.getSession(playerObj)
    if not session or not prepareRadialAction(playerObj, session) then return end
    ISTimedActionQueue.add(TABAS_TakeBathOut:new(playerObj, session))
end

function TABAS_BathRadialMenu.onWashSelf(playerObj, washPart)
    local session = TABAS_BathRadialMenu.getSession(playerObj)
    if not session or not prepareRadialAction(playerObj, session) then return end
    ISTimedActionQueue.add(TABAS_TakeBathWashSelf:new(playerObj, session, nil, washPart))
end

function TABAS_BathRadialMenu.onStanceChange(playerObj, stanceTo)
    local session = TABAS_BathRadialMenu.getSession(playerObj)
    if not session or not prepareRadialAction(playerObj, session) then return end

    local current = session.curStance or playerObj:getVariableString("TABAS_BathStance")
    if not stanceTo then
        stanceTo = TABAS_BathRadialMenu.getNextStance(playerObj, session)
    end
    if not stanceTo then return end
    if current == stanceTo then return end

    ISTimedActionQueue.add(TABAS_TakeBathStanceChange:new(playerObj, stanceTo, current))
    session.curStance = stanceTo
end

function TABAS_BathRadialMenu.onOpenWashMenu(playerObj)
    return TABAS_BathRadialMenu.fillMenu(playerObj, "WASH")
end

function TABAS_BathRadialMenu.onOpenStanceMenu(playerObj)
    return TABAS_BathRadialMenu.fillMenu(playerObj, "STANCE")
end

function TABAS_BathRadialMenu.onOpenInfoUI(playerObj)
    local session = TABAS_BathRadialMenu.getSession(playerObj)
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
        local joypadData = JoypadState.players[playerNum + 1]
        local focus = joypadData and joypadData.focus or nil
        if focus == menu or (menu.ownsJoypadFocus and menu:ownsJoypadFocus(focus)) then
            setJoypadFocus(playerNum, nil)
        end
        playerObj:setJoypadIgnoreAimUntilCentered(false)
        setPlayerMovementActive(playerNum, true)
    end

    menu:removeFromUIManager()
    return true
end

function TABAS_BathRadialMenu.onCloseMenu(playerObj)
    return TABAS_BathRadialMenu.close(playerObj)
end

function TABAS_BathRadialMenu.fillMenu(playerObj, submenu)
    if not TABAS_BathRadialMenu.canOpen(playerObj) then return false end

    local menu = getPlayerRadialMenu(playerObj:getPlayerNum())
    menu:clear()

    if submenu == "STANCE" then
        local current = playerObj:getVariableString("TABAS_BathStance")
        local stances = TABAS_BathRadialMenu.getStanceChoices(playerObj)
        for i = 1, #stances do
            local stance = stances[i]
            local option = TABAS_BathRadialMenu.getOption(stance)
            local label = option.text
            if stance == current then
                label = label .. " *"
            end
            menu:addSlice(label, option.texture, TABAS_BathRadialMenu.onStanceChange, playerObj, stance)
        end
        menu:addSlice(OPTIONS.back.text, OPTIONS.back.texture, TABAS_BathRadialMenu.fillMenu, playerObj)
    elseif submenu == "WASH" then
        TABAS_BathRadialMenu.fillWashMenu(menu, playerObj)
    else
        menu:addSlice(OPTIONS.getout.text, OPTIONS.getout.texture, TABAS_BathRadialMenu.onGetOut, playerObj)
        menu:addSlice(OPTIONS.stance.text, OPTIONS.stance.texture, TABAS_BathRadialMenu.onOpenStanceMenu, playerObj)
        menu:addSlice(OPTIONS.info.text, OPTIONS.info.texture, TABAS_BathRadialMenu.onOpenInfoUI, playerObj)
        menu:addSlice(OPTIONS.close.text, OPTIONS.close.texture, TABAS_BathRadialMenu.onCloseMenu, playerObj)
        menu:addSlice(OPTIONS.wash.text, OPTIONS.wash.texture, TABAS_BathRadialMenu.onOpenWashMenu, playerObj)
    end

    return TABAS_BathRadialMenu.display(playerObj, true)
end

function TABAS_BathRadialMenu.display(playerObj, skipFill)
    if not TABAS_BathRadialMenu.canOpen(playerObj) then return false end

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
        setPlayerMovementActive(playerNum, false)
    end
    return true
end

return TABAS_BathRadialMenu
