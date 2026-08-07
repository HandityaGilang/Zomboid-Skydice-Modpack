require("ISUI/ISPanelJoypad")

TABAS_BathRadialWashMenu = ISPanelJoypad:derive("TABAS_BathRadialWashMenu")
TABAS_BathRadialWashMenu.instances = {}

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
    arms = { texture = getTexture("media/ui/radial/tabas_wash_arms.png"), text = getText("IGUI_TABAS_Radial_Arms") },
    face = { texture = getTexture("media/ui/radial/tabas_wash_face.png"), text = getText("IGUI_TABAS_Radial_Face") },
    legs = { texture = getTexture("media/ui/radial/tabas_wash_legs.png"), text = getText("IGUI_TABAS_Radial_Legs") },
}

local OPTION_KEYS = {
    Arms = "arms",
    Face = "face",
    FaceF = "face",
    Legs = "legs",
    LegsF = "legs",
}

function TABAS_BathRadialWashMenu.getWashChoices(playerObj)
    if not playerObj then return {} end
    return TABAS_AnimVariables.getWashParts("BATH", playerObj:isFemale(), false)
end

function TABAS_BathRadialWashMenu.getOption(name)
    local optionKey = OPTION_KEYS[name]
    return OPTIONS[optionKey] or {
        texture = DEFAULT_OPTION_TEXTURE,
        text = tostring(name or "")
    }
end

function TABAS_BathRadialWashMenu.onWashSelf(playerObj, washPart)
    local session = TABAS_BathRadialUtils.getSession(playerObj)
    if not session or not TABAS_BathRadialUtils.prepareAction(playerObj, session) then return end
    ISTimedActionQueue.add(TABAS_TakeBathWashSelf:new(playerObj, session, washPart))
end

function TABAS_BathRadialWashMenu.OpenPanel(playerObj)
    if not TABAS_BathRadialUtils.canOpen(playerObj) then return nil end

    local playerNum = playerObj:getPlayerNum()
    local current = TABAS_BathRadialWashMenu.instances[playerNum]
    if current and current.isReallyVisible and current:isReallyVisible() then
        current:close()
    end

    local ui = TABAS_BathRadialWashMenu:new(0, 0, playerObj)
    ui:initialise()
    ui:instantiate()
    ui:centerOnScreen(playerNum)
    ui:setVisible(true)
    ui:addToUIManager()
    TABAS_BathRadialWashMenu.instances[playerNum] = ui

    if JoypadState.players[playerNum + 1] then
        setJoypadFocus(playerNum, ui)
    end

    return ui
end

function TABAS_BathRadialWashMenu:initialise()
    ISPanelJoypad.initialise(self)
end

function TABAS_BathRadialWashMenu:createChildren()
    ISPanelJoypad.createChildren(self)

    local btnW = self.btnWidth
    local btnH = self.btnHeight
    local x = BORDER_SPACING
    local y = FONT_HGT_SMALL + BORDER_SPACING * 3

    self.buttons = {}
    for i = 1, #self.parts do
        local part = self.parts[i]
        local option = TABAS_BathRadialWashMenu.getOption(part)
        local btn = TABAS_Panel.addButton(x, y, btnW, btnH, option.texture, nil, nil, self, self.onClick, false)
        btn.internal = "WASH_PART"
        btn.washPart = part
        btn.optionText = option.text
        btn:setFont(UIFont.Small)
        btn:setBorderRGBA(0, 0, 0, 0)
        table.insert(self.buttons, btn)
        x = btn:getRight() + BETWEEN_SPACING
    end

    self.btnClose = TABAS_Panel.addButton(x, y, btnW, btnH, self.texClose, nil, nil, self, self.onClick, false)
    self.btnClose.internal = "CLOSE"
    self.btnClose.optionText = getText("UI_Close")
    self.btnClose:setFont(UIFont.Small)
    self.btnClose:setBorderRGBA(0, 0, 0, 0)
    table.insert(self.buttons, self.btnClose)
end

function TABAS_BathRadialWashMenu:onClick(btn)
    if not btn then return end

    if btn.internal == "CLOSE" then
        self:close()
        return
    end

    if btn.internal == "WASH_PART" and btn.washPart then
        self:close()
        TABAS_BathRadialWashMenu.onWashSelf(self.playerObj, btn.washPart)
    end
end

function TABAS_BathRadialWashMenu:close()
    TABAS_BathRadialWashMenu.instances[self.playerNum] = nil
    self:setVisible(false)
    self:removeFromUIManager()

    if JoypadState.players[self.playerNum + 1] then
        setJoypadFocus(self.playerNum, nil)
    end
end

function TABAS_BathRadialWashMenu:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData)

    self.joypadButtons = {}
    self.joypadButtonsY = {}

    self:insertNewListOfButtons(self.buttons)

    self.joypadIndexY = 1
    self.joypadIndex = 1
    self.joypadButtons = self.joypadButtonsY[self.joypadIndexY]
    self:restoreJoypadFocus(joypadData)
    -- self:setISButtonForB(self.btnClose)
end

function TABAS_BathRadialWashMenu:onLoseJoypadFocus(joypadData)
    ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
    self:clearJoypadFocus(joypadData)
end

function TABAS_BathRadialWashMenu:onJoypadDown(button, joypadData)
    ISPanelJoypad.onJoypadDown(self, button, joypadData)
    if button == Joypad.BButton then
        self:close()
    end
end

function TABAS_BathRadialWashMenu:getBPrompt()
    return getText("UI_Close")
end

function TABAS_BathRadialWashMenu:isValidPrompt()
    return self:isReallyVisible()
end

function TABAS_BathRadialWashMenu:getAPrompt()
    return getText("IGUI_TABAS_SelectButton")
end

function TABAS_BathRadialWashMenu:getSelectedButton()
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

function TABAS_BathRadialWashMenu:prerender()
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

function TABAS_BathRadialWashMenu:render()
    ISPanelJoypad.render(self)
end

function TABAS_BathRadialWashMenu:new(x, y, playerObj)
    local btnW = math.max(72, FONT_HGT_SMALL * 6)
    local btnH = math.max(64, HGT_BUTTON * 3)
    local width = BORDER_SPACING * 2 + btnW * 4 + BETWEEN_SPACING * 3
    local height = FONT_HGT_SMALL + BORDER_SPACING * 5 + btnH

    local o = ISPanelJoypad.new(self, x, y, width, height)

    o.playerObj = playerObj
    o.playerNum = playerObj:getPlayerNum()
    o.parts = TABAS_BathRadialWashMenu.getWashChoices(playerObj)
    o.title = getText("IGUI_TABAS_Radial_WashSelf")
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

return TABAS_BathRadialWashMenu
