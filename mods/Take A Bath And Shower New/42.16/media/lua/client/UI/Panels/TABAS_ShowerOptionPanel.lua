require("ISUI/ISPanelJoypad")

TABAS_ShowerOptionPanel = ISPanelJoypad:derive("TABAS_ShowerOptionPanel")

local TABAS_Utils = require("TABAS_Utils")
local TABAS_Iso = require("TABAS_Iso")
local TABAS_Panel = require("UI/TABAS_PanelUtils")

local CONST = require("UI/TABAS_PanelConst")
local FONT_HGT_SMALL = CONST.SCALE.HGT_SMALL
local HGT_BUTTON = CONST.SCALE.HGT_BUTTON
local BORDER_SPACING = CONST.SCALE.BORDER_SPACING

function TABAS_ShowerOptionPanel:initialise()
    ISPanelJoypad.initialise(self)
end

function TABAS_ShowerOptionPanel:createChildren()
    ISPanelJoypad.createChildren(self)
    local x, y = BORDER_SPACING, BORDER_SPACING
    local btnScale = self.btnScale
    self.btnTakeShower = TABAS_Panel.addButton(x, y, btnScale, btnScale, self.tex_showerHot, nil, self.text_takeShowerHot, self, self.onClick, true)
    self.btnTakeShower.internal = "TAKESHOWER"

    x = x + BORDER_SPACING
    y = self.btnTakeShower:getBottom() + FONT_HGT_SMALL
    btnScale = btnScale - BORDER_SPACING*2
    self.btnToggle = TABAS_Panel.addButton(x, y, btnScale, btnScale, self.tex_swapIcon, nil, nil, self, self.onClick, true)
    self.btnToggle.internal = "SHOWERTOGGLE"
    self.btnToggle:setFont(UIFont.Small)
    self.btnToggle.value = TABAS_Iso.canHot(self.showerObj)
end

function TABAS_ShowerOptionPanel:prerender()
    ISPanelJoypad.prerender(self)

    -- if self.warnState ~= "none" then
    --     local size = FONT_HGT_SMALL
    --     local x = self:getWidth() - size - BORDER_SPACING
    --     local y = BORDER_SPACING

    --     if self.warnState == "disabled" then
    --         -- red
    --         self:drawTextureScaled(self.tex_cautionIcon, x, y, size, size, 1, 0.9, 0.2, 0.2)
    --     elseif self.warnState == "low" then
    --         -- yellow
    --         self:drawTextureScaled(self.tex_cautionIcon, x, y, size, size, 1, 0.95, 0.85, 0.2)
    --     end
    -- end
end

function TABAS_ShowerOptionPanel:update()
end

function TABAS_ShowerOptionPanel:onClick(_btn)
    if _btn.internal == "SHOWERTOGGLE" and self.btnToggle:isEnabled() then
        self.btnToggle.value = not self.btnToggle.value
        return
    end

    if _btn.internal == "TAKESHOWER" and self._mainPanel then
        local mainPanel = self._mainPanel
        local actionQueue = ISTimedActionQueue.getTimedActionQueue(self.playerObj)
        local doAction = actionQueue.queue[1] ~= nil
        if doAction then return end

        local player = self.playerObj:getPlayerNum()
        local towel = mainPanel.entryPanel:getStoredItem()
        local keepClothes = not mainPanel.entryPanel.tglAutoCC.toggleState
        local makeOff = mainPanel.entryPanel.tglMakeOff.toggleState
        local useHot = self.btnToggle.value
        local TakeShowerContext = require("ContextMenu/TABAS_ContextMenuShower")

        TakeShowerContext.onTakeShowerInBath(player, self.tfc_Base.bathObject, nil, nil, nil, towel, keepClothes, makeOff, useHot)
        if not mainPanel.pinned then
            mainPanel:close()
        end
    end
end

function TABAS_ShowerOptionPanel:render()
    ISPanelJoypad.render(self)
	self:renderJoypadFocus()
end

function TABAS_ShowerOptionPanel:refreshShowerPanel(availabilityState)
    local mainPanel = self._mainPanel
    if not mainPanel then return end

    availabilityState = availabilityState or mainPanel._availabilityState or mainPanel:checkAvailability()
    if not availabilityState then return end

    local bathingPhaseStarted = availabilityState.bathingPhaseStarted == true
    local using = availabilityState.using == true
    local canHot = mainPanel.tubStatusPanel:isCanHot()
    local piped = mainPanel.tubStatusPanel:isPiped()
    local faucet = mainPanel.tubStatusPanel:getFaucetWater()
    local waterTemp = mainPanel.temperaturePanel:getCurrentTemperature()
    local setTemp = mainPanel.temperaturePanel:getTargetTemperature()

    local waterRequired = SandboxVars.TakeABathAndShower.ShowerConsumeWater
    local tooHot = (waterTemp > 45) or (setTemp > 45)
    local notEnoughMin = faucet < 10
    local lowWater = (faucet >= 10) and (faucet < waterRequired)

    local canUseShower = (not bathingPhaseStarted) and (not using) and (not notEnoughMin) and (not tooHot)

    self.notAvailable = not canUseShower
    self.btnTakeShower:setEnable(canUseShower)
    self.btnToggle:setEnable(canUseShower and canHot)

    if not canHot and self.btnToggle.value then
        self.btnToggle.value = false
    end

    local isHot = self.btnToggle.value and canHot
    if self._isHot ~= isHot then
        self._isHot = isHot
        self.btnTakeShower:setImage(isHot and self.tex_showerHot or self.tex_showerCold)
    end

    -- base tooltip
    local baseTooltip = isHot and self.text_takeShowerHot or self.text_takeShowerCold
    local tooltip = baseTooltip

    -- unavailable: tooltip overwrite
    if bathingPhaseStarted then
        tooltip = availabilityState.bathingPhaseText or getText("IGUI_TABAS_Bathing_Preparing")
    elseif using then
        tooltip = getText("ContextMenu_TABAS_CurrentlyUsing")
    elseif not piped and notEnoughMin then
        tooltip = getText("ContextMenu_TABAS_NotPiped")
    elseif tooHot then
        tooltip = getText("ContextMenu_TABAS_TooHot")
    elseif notEnoughMin then
        tooltip = getText("ContextMenu_TABAS_NotEnoughWater")
    else
        -- available: append warning
        if lowWater then
            tooltip = tooltip .. " <LINE> " ..
                getText("ContextMenu_TABAS_RequiredWater") .. ": " .. tostring(waterRequired) .. "L"
        end
        if isHot and not canHot then
            tooltip = tooltip .. " <LINE> " .. getText("ContextMenu_TABAS_ElectricityRequired")
        end
    end

    self.btnTakeShower:setTooltip(tooltip)

    -- warning icon
    if using or (not piped) or tooHot or notEnoughMin then
        self.warnState = "disabled"
    elseif lowWater then
        self.warnState = "low"
    else
        self.warnState = "none"
    end
end

function TABAS_ShowerOptionPanel:onGainJoypadFocus(joypadData)
	ISPanelJoypad.onGainJoypadFocus(self, joypadData)
	self.joypadIndex = 1
    self.joypadIndexY = 1
	self.joypadButtons = {}
    self.joypadButtonsY = {}
	self:insertNewLineOfButtons(self.btnTakeShower)
	self:insertNewLineOfButtons(self.btnToggle)
    self:restoreJoypadFocus(joypadData)
end

function TABAS_ShowerOptionPanel:onLoseJoypadFocus(joypadData)
    ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
	-- self.prevJoypadIndex = self.joypadIndex
	self:clearJoypadFocus(joypadData)
end

function TABAS_ShowerOptionPanel:onJoypadDown(button, joypadData)
    if button == Joypad.BButton then
        self._mainPanel:close()
        return
    end
    if button == Joypad.RBumper then
		self:setJoypadFocused(false, joypadData)
        if self._mainPanel and self._mainPanel.entryPanel and self._mainPanel.entryPanel:isReallyVisible() then
            setJoypadFocus(self.playerObj:getPlayerNum(), self._mainPanel.entryPanel)
        elseif self._mainPanel then
            setJoypadFocus(self.playerObj:getPlayerNum(), self._mainPanel)
        end
		return
    end
    ISPanelJoypad.onJoypadDown(self, button, joypadData)
end

function TABAS_ShowerOptionPanel:getBPrompt()
    return getText("UI_Close")
end

function TABAS_ShowerOptionPanel:isValidPrompt()
    return self:isReallyVisible()
end

function TABAS_ShowerOptionPanel:getAPrompt()
    return getText("IGUI_TABAS_SelectButton")
end

function TABAS_ShowerOptionPanel:getLBPrompt()
    return nil
end

function TABAS_ShowerOptionPanel:getRBPrompt()
    return getText("IGUI_TABAS_SelectOptions")
end

function TABAS_ShowerOptionPanel:new (x, y, playerObj, tfc_Base)
    local bathObject = tfc_Base and tfc_Base.bathObject
    if not bathObject or not TABAS_Iso.isBathWithShower(bathObject) then
        return nil
    end
    local btnScale = HGT_BUTTON * 1.75
    local width = btnScale + BORDER_SPACING *2
    local height = btnScale + HGT_BUTTON + BORDER_SPACING * 2

    local o = ISPanelJoypad:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y
    o.labelColor = CONST.COLOR.labelColor

    local texture = CONST.TEXTURE
    o.tex_swapIcon = texture.swapIcon
    o.tex_showerHot = texture.showerHot
    o.tex_showerCold = texture.showerCold
    o.tex_cautionIcon = texture.cautionIcon

    o.text_takeShowerHot = getText("ContextMenu_TABAS_TakeShowerHot")
    o.text_takeShowerCold = getText("ContextMenu_TABAS_TakeShowerCold")

    o.width = width
    o.height = height
    o.btnScale = btnScale
    o.playerObj = playerObj
    o.tfc_Base = tfc_Base
    o.showerObj = bathObject
    o.notAvailable = false
    o.warnState = "none"
    o.overrideBPrompt = true
    return o
end
