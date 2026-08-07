require("ISUI/ISPanelJoypad")

TABAS_BathRadialStanceMenu = ISPanelJoypad:derive("TABAS_BathRadialStanceMenu")
TABAS_BathRadialStanceMenu.instances = {}

local TABAS_AnimVariables = require("Bathing/TABAS_AnimVariables")
local TABAS_BathRadialUtils = require("UI/TABAS_BathRadialUtils")
local TABAS_Panel = require("UI/TABAS_PanelUtils")
local CONST = require("UI/TABAS_PanelConst")

local FONT_HGT_SMALL = CONST.SCALE.HGT_SMALL
local HGT_BUTTON = CONST.SCALE.HGT_BUTTON
local BETWEEN_SPACING = CONST.SCALE.BETWEEN_SPACING
local BORDER_SPACING = CONST.SCALE.BORDER_SPACING
local DEFAULT_OPTION_TEXTURE = getTexture("media/ui/Entity/BTN_Missing_Icon_48x48.png")

local OPTIONS = {
    idle = { texture = getTexture("media/ui/radial/tabas_stance_idle.png"), text = getText("IGUI_TABAS_Radial_Idle") },
    elbowl = { texture = getTexture("media/ui/radial/tabas_stance_left.png"), text = getText("IGUI_TABAS_Radial_ElbowL") },
    elbowr = { texture = getTexture("media/ui/radial/tabas_stance_right.png"), text = getText("IGUI_TABAS_Radial_ElbowR") },
    lookup = { texture = getTexture("media/ui/radial/tabas_stance_lookup.png"), text = getText("IGUI_TABAS_Radial_LookUp") },
    relax = { texture = getTexture("media/ui/radial/tabas_stance_relax.png"), text = getText("IGUI_TABAS_Radial_Relax") },
    sit = { texture = getTexture("media/ui/radial/tabas_stance_sit.png"), text = getText("IGUI_TABAS_Radial_Sit") },
}

local OPTION_KEYS = {
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

function TABAS_BathRadialStanceMenu.getStanceChoices(playerObj)
    if not playerObj then return {} end
    local stances = TABAS_AnimVariables.getStances("BATH", playerObj:isFemale(), false)
    table.insert(stances, 1, "Idle")
    return stances
end

function TABAS_BathRadialStanceMenu.getOption(name)
    local optionKey = OPTION_KEYS[name]
    return OPTIONS[optionKey] or {
        texture = DEFAULT_OPTION_TEXTURE,
        text = tostring(name or "")
    }
end

function TABAS_BathRadialStanceMenu.onStanceChange(playerObj, stanceTo)
    local session = TABAS_BathRadialUtils.getSession(playerObj)
    if not session or not TABAS_BathRadialUtils.prepareAction(playerObj, session, false) then return end

    local current = TABAS_BathRadialUtils.getQueuedBathStanceTarget(playerObj, session.curStance or playerObj:getVariableString("TABAS_BathStance"))
    if not stanceTo or current == stanceTo then return end

    ISTimedActionQueue.add(TABAS_TakeBathStanceChange:new(playerObj, session, stanceTo, current))
end

function TABAS_BathRadialStanceMenu.toggleAutoStance(playerObj)
    local session = TABAS_BathRadialUtils.getSession(playerObj)
    if not session then return nil end

    session.autoStanceEnabled = not session.autoStanceEnabled
    local answer = session.autoStanceEnabled and "ON" or "OFF"
    playerObj:Say(getText("ContextMenu_TABAS_BathAutoStance") .. ": " .. answer)
    return session.autoStanceEnabled
end

function TABAS_BathRadialStanceMenu.OpenPanel(playerObj)
    if not TABAS_BathRadialUtils.canOpen(playerObj) then return nil end

    local playerNum = playerObj:getPlayerNum()
    local current = TABAS_BathRadialStanceMenu.instances[playerNum]
    if current and current.isReallyVisible and current:isReallyVisible() then
        current:close()
    end

    local ui = TABAS_BathRadialStanceMenu:new(0, 0, playerObj)
    ui:initialise()
    ui:instantiate()
    ui:centerOnScreen(playerNum)
    ui:setVisible(true)
    ui:addToUIManager()
    TABAS_BathRadialStanceMenu.instances[playerNum] = ui

    if JoypadState.players[playerNum + 1] then
        setJoypadFocus(playerNum, ui)
    end

    return ui
end

function TABAS_BathRadialStanceMenu:initialise()
    ISPanelJoypad.initialise(self)
end

function TABAS_BathRadialStanceMenu:createChildren()
    ISPanelJoypad.createChildren(self)

    local btnW = self.btnWidth
    local btnH = self.btnHeight
    local x = BORDER_SPACING
    local y = FONT_HGT_SMALL + BORDER_SPACING * 3

    self.buttons = {}
    self.buttonRows = {}

    local firstRow = {}
    for i = 1, math.min(3, #self.stances) do
        local stance = self.stances[i]
        local option = TABAS_BathRadialStanceMenu.getOption(stance)
        local btn = TABAS_Panel.addButton(x, y, btnW, btnH, option.texture, nil, nil, self, self.onClick, false)
        btn.internal = "STANCE"
        btn.stanceTo = stance
        btn.optionText = stance == self.currentStance and (option.text .. " *") or option.text
        btn:setFont(UIFont.Small)
        btn:setBorderRGBA(0, 0, 0, 0)
        table.insert(firstRow, btn)
        table.insert(self.buttons, btn)
        x = btn:getRight() + BETWEEN_SPACING
    end

    self.btnClose = TABAS_Panel.addButton(x, y, btnW, btnH, self.texClose, nil, nil, self, self.onClick, false)
    self.btnClose.internal = "CLOSE"
    self.btnClose.optionText = getText("UI_Close")
    self.btnClose:setFont(UIFont.Small)
    self.btnClose:setBorderRGBA(0, 0, 0, 0)
    table.insert(firstRow, self.btnClose)
    table.insert(self.buttons, self.btnClose)
    table.insert(self.buttonRows, firstRow)

    local secondRow = {}
    y = y + btnH + BETWEEN_SPACING
    x = BORDER_SPACING
    for i = 4, #self.stances do
        local stance = self.stances[i]
        local option = TABAS_BathRadialStanceMenu.getOption(stance)
        local btn = TABAS_Panel.addButton(x, y, btnW, btnH, option.texture, nil, nil, self, self.onClick, false)
        btn.internal = "STANCE"
        btn.stanceTo = stance
        btn.optionText = stance == self.currentStance and (option.text .. " *") or option.text
        btn:setFont(UIFont.Small)
        btn:setBorderRGBA(0, 0, 0, 0)
        table.insert(secondRow, btn)
        table.insert(self.buttons, btn)
        x = btn:getRight() + BETWEEN_SPACING
    end

    self.btnAutoStance = TABAS_Panel.addButton(x, y, btnW, btnH, nil, self.autoStanceButtonText, nil, self, self.onClick, false)
    self.btnAutoStance.internal = "AUTO_STANCE"
    self.btnAutoStance.optionText = self.autoStanceOptionText
    self.btnAutoStance:setFont(UIFont.Small)
    self.btnAutoStance:setBorderRGBA(0, 0, 0, 0)
    table.insert(secondRow, self.btnAutoStance)
    table.insert(self.buttons, self.btnAutoStance)

    if #secondRow > 0 then
        table.insert(self.buttonRows, secondRow)
    end
end

function TABAS_BathRadialStanceMenu:onClick(btn)
    if not btn then return end

    if btn.internal == "CLOSE" then
        self:close()
        return
    end

    if btn.internal == "STANCE" and btn.stanceTo then
        self:close()
        TABAS_BathRadialStanceMenu.onStanceChange(self.playerObj, btn.stanceTo)
        return
    end

    if btn.internal == "AUTO_STANCE" then
        self.autoStanceEnabled = TABAS_BathRadialStanceMenu.toggleAutoStance(self.playerObj) == true
        self.btnAutoStance:setTitle("Auto: " .. (self.autoStanceEnabled and "ON" or "OFF"))
    end
end

function TABAS_BathRadialStanceMenu:close()
    TABAS_BathRadialStanceMenu.instances[self.playerNum] = nil
    self:setVisible(false)
    self:removeFromUIManager()

    if JoypadState.players[self.playerNum + 1] then
        setJoypadFocus(self.playerNum, nil)
    end
end

function TABAS_BathRadialStanceMenu:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData)

    self.joypadButtons = {}
    self.joypadButtonsY = {}
    for i = 1, #self.buttonRows do
        self:insertNewListOfButtons(self.buttonRows[i])
    end

    self.joypadIndexY = 1
    self.joypadIndex = 1
    self.joypadButtons = self.joypadButtonsY[self.joypadIndexY]
    self:restoreJoypadFocus(joypadData)
end

function TABAS_BathRadialStanceMenu:onLoseJoypadFocus(joypadData)
    ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
    self:clearJoypadFocus(joypadData)
end

function TABAS_BathRadialStanceMenu:onJoypadDown(button, joypadData)
    ISPanelJoypad.onJoypadDown(self, button, joypadData)
    if button == Joypad.BButton then
        self:close()
    end
end

function TABAS_BathRadialStanceMenu:getBPrompt()
    return getText("UI_Close")
end

function TABAS_BathRadialStanceMenu:isValidPrompt()
    return self:isReallyVisible()
end

function TABAS_BathRadialStanceMenu:getAPrompt()
    return getText("IGUI_TABAS_SelectButton")
end

function TABAS_BathRadialStanceMenu:getSelectedButton()
    for i = 1, #self.buttons do
        local btn = self.buttons[i]
        if btn.mouseOver then
            return btn
        end
    end

    if self.joypadButtons and self.joypadIndex then
        return self.joypadButtons[self.joypadIndex]
    end

    return nil
end

function TABAS_BathRadialStanceMenu:prerender()
    ISPanelJoypad.prerender(self)

    local btnBGColor = { r = 0.2, g = 0.2, b = 0.2, a = 1 }
    local backgroundColorMouseOver = { r = 0.3, g = 0.3, b = 0.3, a = 1 }
    for i = 1, #self.buttons do
        local btn = self.buttons[i]
        btn.fade:setFadeIn((btn.mouseOver and btn:isMouseOver()) and btn.enable or btn.joypadFocused or false)
        btn.fade:update()
        local f = btn.fade:fraction()
        local fill = { r = 0.4, g = 0.4, b = 0.4, a = 1 }
        if btn.pressed then
            btn.backgroundColorPressed = btn.backgroundColorPressed or {}
            btn.backgroundColorPressed.r = backgroundColorMouseOver.r * 0.5
            btn.backgroundColorPressed.g = backgroundColorMouseOver.g * 0.5
            btn.backgroundColorPressed.b = backgroundColorMouseOver.b * 0.5
            btn.backgroundColorPressed.a = backgroundColorMouseOver.a
            fill = btn.backgroundColorPressed
        end
        local c = {
            fill.a * f + btnBGColor.a * (1 - f),
            fill.r * f + btnBGColor.r * (1 - f),
            fill.g * f + btnBGColor.g * (1 - f),
            fill.b * f + btnBGColor.b * (1 - f),
        }
        self:drawTextureScaled(self.bg_button, btn:getX() - 2, btn:getY() - 2, btn:getWidth() + 4, btn:getHeight() + 4, c[1], c[2], c[3], c[4])
    end

    local selected = self:getSelectedButton()
    local text = selected and selected.optionText or self.title
    self:drawTextCentre(text, self.width / 2, BORDER_SPACING, 1, 1, 1, 1, UIFont.Medium)
end

function TABAS_BathRadialStanceMenu:render()
    ISPanelJoypad.render(self)
end

function TABAS_BathRadialStanceMenu:new(x, y, playerObj)
    local btnW = math.max(72, FONT_HGT_SMALL * 6)
    local btnH = math.max(64, HGT_BUTTON * 3)
    local width = BORDER_SPACING * 2 + btnW * 4 + BETWEEN_SPACING * 3
    local height = FONT_HGT_SMALL + BORDER_SPACING * 6 + btnH * 2 + BETWEEN_SPACING
    local session = TABAS_BathRadialUtils.getSession(playerObj)

    local o = ISPanelJoypad.new(self, x, y, width, height)

    o.playerObj = playerObj
    o.playerNum = playerObj:getPlayerNum()
    o.stances = TABAS_BathRadialStanceMenu.getStanceChoices(playerObj)
    o.currentStance = playerObj:getVariableString("TABAS_BathStance")
    o.title = getText("IGUI_TABAS_Radial_StanceChange")
    o.autoStanceEnabled = session and session.autoStanceEnabled == true
    o.autoStanceButtonText = "Auto: " .. (o.autoStanceEnabled and "ON" or "OFF")
    o.autoStanceOptionText = getText("ContextMenu_TABAS_BathAutoStance")
    o.btnWidth = btnW
    o.btnHeight = btnH
    o.texClose = getTexture("media/ui/emotes/back_red.png")
    o.bg_button = CONST.TEXTURE.bg_button
    o.background = true
    o.backgroundColor = CONST.COLOR.backgroundColorDark
    o.borderColor = CONST.COLOR.borderOuterColor
    o.moveWithMouse = true
    o.overrideBPrompt = true
    return o
end

return TABAS_BathRadialStanceMenu
