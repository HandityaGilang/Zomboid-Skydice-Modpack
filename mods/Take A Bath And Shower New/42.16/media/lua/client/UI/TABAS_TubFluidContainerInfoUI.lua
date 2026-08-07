require("ISUI/ISPanelJoypad")

-- ** UI for Tub Fluid Container referenced by ISFluidInfoUI. ** 

TABAS_TubFluidContainerInfoUI = ISPanelJoypad:derive("TABAS_TubFluidContainerInfoUI")

TABAS_TubFluidContainerInfoUI.players = {}

local TABAS_Panel = require("UI/TABAS_PanelUtils")
local TABAS_Utils = require("TABAS_Utils")
local TABAS_GameTimes = require("TABAS_GameTimes")

local CONST = require("UI/TABAS_PanelConst")
local FONT_HGT_SMALL = CONST.SCALE.HGT_SMALL
local FONT_HGT_MEDIUM = CONST.SCALE.HGT_MEDIUM
local BETWEEN_SPACING = CONST.SCALE.BETWEEN_SPACING
local BORDER_SPACING = CONST.SCALE.BORDER_SPACING

local MAX_PANEL_DIST = 5
local MAX_PANEL_DIST_PINNED = 15
local PANEL_W = 820
local PANEL_H = 500
local WATCH_TTL_MS = 5000
local WATCH_REFRESH_MS = 4000

local BATHING_PHASE_ANCHOR_ACTIONS = {
    TABAS_TakeBathIn = true,
    TABAS_TakeBathOut = true,
    TABAS_TakeShower = true,
    TABAS_ClimbOverTubEdge = true,
    TABAS_DrySelf = true,
    BTO_WipeMySelf = true,
    TABAS_ReEquipItems = true,
    TABAS_ReAttachHotbar = true,
}

local BATHING_PHASE_WALK_ACTIONS = {
    ISWalkToTimedAction = true,
    ISWalkToTimedActionF = true,
}

local BATHING_PHASE_ACTION_TEXT_KEYS = {
    TABAS_ClimbOverTubEdge = "IGUI_TABAS_Bathing_Preparing",
    TABAS_TakeBathIn = "IGUI_TABAS_Bathing_Preparing",
    TABAS_TakeBathOut = "IGUI_TABAS_Bathing",
    TABAS_TakeShower = "IGUI_TABAS_Bathing_Showering",
    TABAS_DrySelf = "IGUI_TABAS_Bathing_Drying",
    BTO_WipeMySelf = "IGUI_TABAS_Bathing_Drying",
    ISUnequipAction = "IGUI_TABAS_Bathing_Undressing",
    TABAS_DetachHotbarItem = "IGUI_TABAS_Bathing_Undressing",
    TABAS_ReAttachHotbar = "IGUI_TABAS_Bathing_Dressing",
    ISWearClothing = "IGUI_TABAS_Bathing_Dressing",
    ISEquipWeaponAction = "IGUI_TABAS_Bathing_Dressing",
    TABAS_ReEquipItems = "IGUI_TABAS_Bathing_Dressing",
}

local function getPlayerState(playerNum)
    local this = TABAS_TubFluidContainerInfoUI
    if not this.players[playerNum] then
        this.players[playerNum] = {}
    end
    return this.players[playerNum]
end

function TABAS_TubFluidContainerInfoUI.setBathingPhaseStarted(playerObj)
    if not playerObj then return end

    local playerState = getPlayerState(playerObj:getPlayerNum())
    playerState.bathingPhaseStarted = true

    local instance = playerState.instance
    if instance then
        instance:markDirty()
        instance._forceStatusRefresh = true
    end
end

function TABAS_TubFluidContainerInfoUI.OpenPanel(playerObj, tfc_Base)
    local playerNum = playerObj:getPlayerNum()

    local x = getMouseX() + 10
    local y = getMouseY() + 10
    local adjustPos = true
    local playerState = getPlayerState(playerNum)
    if playerState.instance then
        playerState.instance:close()
    end
    if playerState.x and playerState.y then
        x = playerState.x
        y = playerState.y
        adjustPos = false
    end

    local ui = TABAS_TubFluidContainerInfoUI:new(x, y, PANEL_W, PANEL_H, playerObj, tfc_Base)
    ui:initialise()
    ui:instantiate()
    ui.pinned = playerState.pinned == true
    ui:setVisible(true)
    ui:addToUIManager()

    playerState.instance = ui

    -- first time open panel and isoobject then middle of screen.
    if adjustPos then
        ui:centerOnScreen(playerNum)
        playerState.x = ui.x
        playerState.y = ui.y
    end

    if getJoypadData(playerNum) then
        setJoypadFocus(playerNum, ui)
    end
end

function TABAS_TubFluidContainerInfoUI:initialise()
    ISPanelJoypad.initialise(self)
end

function TABAS_TubFluidContainerInfoUI:createChildren()
    ISPanelJoypad.createChildren(self)

    local x = BORDER_SPACING
    local y = self.titleHeigh + BORDER_SPACING * 1.5
    local addPanel = function(class, targetPanel, anchor, setW, setH)
        local panel = class:new(x, y, self.playerObj, self.tfc_Base)
        if not panel then return end
        panel:initialise()
        panel:instantiate()
        self:addChild(panel)
        if targetPanel and anchor then
            self:layoutPanel(panel, targetPanel, anchor, setW, setH)
        end
        return panel
    end
    -- bathtub status panel.
    self.tubStatusPanel = addPanel(TABAS_TubStatusPanel)
    self.tubStatusPanel:setX(self.tubStatusPanel:getX() + BORDER_SPACING)
    -- tub water status panel.
    self.tubWaterStatusPanel = addPanel(TABAS_TubWaterStatusPanel, self.tubStatusPanel, "BOTTOM", self.tubStatusPanel:getWidth())
    -- temperature panel
    self.temperaturePanel = addPanel(TABAS_TubTemperaturePanel, self.tubStatusPanel, "RIGHT")
    -- bath salt panel
    self.bathSaltPanel = addPanel(TABAS_BathSaltDropBoxPanel, self.temperaturePanel, "RIGHT", nil, self.temperaturePanel:getHeight())

    -- tub fluid container panel
    local panelWidth = self.temperaturePanel:getWidth()+self.bathSaltPanel:getWidth()+BETWEEN_SPACING
    self.tfcPanel = TABAS_TubFluidContainerPanel:new(self.temperaturePanel:getX(), self.temperaturePanel:getBottom()+BETWEEN_SPACING, panelWidth, panelWidth * 0.55, self.playerObj, self.tfc_Base)
    self.tfcPanel:initialise()
    self.tfcPanel:instantiate()
    self:addChild(self.tfcPanel)

    -- bath action panel
    self.actionPanel = addPanel(TABAS_BathActionPanel, self.tfcPanel, "BOTTOM", self.tfcPanel:getWidth())
    self.actionPanel._mainPanel = self
    self.actionPanel:setTitleWidth(self.tfcPanel:getWidth())

    -- bath time entry panel.
    self.entryPanel = addPanel(TABAS_BathTimeEntryPanel, self.tfcPanel, "LEFT")
    self.entryPanel:setY(self.actionPanel:getBottom() - self.entryPanel:getHeight())

    self.autoBathTimePanel = addPanel(TABAS_AutoBathTimePanel, self.entryPanel, "TOP")
    self.autoBathTimePanel:setX(self.entryPanel:getRight() - self.autoBathTimePanel:getWidth())
    self.autoBathTimePanel._entryPanel = self.entryPanel

    -- take shower button (only within shower)
    self.showerPanel = addPanel(TABAS_ShowerOptionPanel, self.entryPanel, "LEFT")
    if self.showerPanel then
        self.showerPanel:setHeight(self.entryPanel:getHeight())
        self.showerPanel._managedByParent = true
        self.showerPanel._mainPanel = self
    end

    self.bathSessionPanel = TABAS_BathSessionPanel:new(self.entryPanel:getX(), self.entryPanel:getY(), self.entryPanel:getWidth(), self.entryPanel:getHeight(), self.playerObj, self.tfc_Base)
    self.bathSessionPanel:initialise()
    self.bathSessionPanel:instantiate()
    self:layoutPanel(self.bathSessionPanel, self.entryPanel, "SAME", self.entryPanel:getWidth(), self.entryPanel:getHeight())
    self.bathSessionPanel:setVisible(false)
    self:addChild(self.bathSessionPanel)

    self:setWidth(self.actionPanel:getRight() + BORDER_SPACING)
    self:setHeight(self.actionPanel:getBottom() + BORDER_SPACING*2)

    x = BORDER_SPACING/2
    y = FONT_HGT_SMALL / 6  + 2
    local btnScale = FONT_HGT_SMALL

    -- close button
    self.btnClose = TABAS_Panel.addButton(x, y, btnScale, btnScale, self.tex_closeButton, nil, nil, self, self.onClick, false)
    self.btnClose.internal = "CLOSE"

    -- tutorial button
    if TABAS_Compat.TABAS_TG then
        x = self.btnClose:getRight() + BETWEEN_SPACING
        self.btnTutorial = TABAS_Panel.addButton(x, y, btnScale, btnScale, self.tex_tutorialButton, nil, nil, self, self.onClick, false)
        self.btnTutorial.internal = "TUTORIAL"
    end

    -- pin button
    x = self:getWidth() - btnScale - BORDER_SPACING/2
    self.btnPin = TABAS_Panel.addButton(x, y, btnScale, btnScale, self.tex_pinButton, nil, nil, self, self.onClick, false)
    self.btnPin.internal = "PIN"
    self.pinned = false

    -- child panels are tick-managed by parent
    self.tubStatusPanel._managedByParent = true
    self.tubWaterStatusPanel._managedByParent = true
    self.temperaturePanel._managedByParent = true
    self.tfcPanel._managedByParent = true
    self.bathSaltPanel._managedByParent = true
    self.entryPanel._managedByParent = true
    self.autoBathTimePanel._managedByParent = true
    self.actionPanel._managedByParent = true
    self.bathSessionPanel._managedByParent = true

    -- for joypad focus
    self.entryPanel._mainPanel = self
end

function TABAS_TubFluidContainerInfoUI:layoutPanel(panel, targetPanel, anchor, width, height)
    if anchor == "SAME" then
        panel:setX(targetPanel:getX())
        panel:setY(targetPanel:getY())
    elseif anchor == "LEFT" then
        panel:setX(targetPanel:getX() - panel:getWidth() - BETWEEN_SPACING)
        panel:setY(targetPanel:getY())
    elseif anchor == "RIGHT" then
        panel:setX(targetPanel:getRight() + BETWEEN_SPACING)
        panel:setY(targetPanel:getY())
    elseif anchor == "BOTTOM" then
        panel:setX(targetPanel:getX())
        panel:setY(targetPanel:getBottom() + BETWEEN_SPACING)
    elseif anchor == "TOP" then
        panel:setX(targetPanel:getX())
        panel:setY(targetPanel:getY() - panel:getHeight() - BETWEEN_SPACING)
    end
    if width then
        panel:setWidth(width)
    end
    if height then
        panel:setHeight(height)
    end
end

function TABAS_TubFluidContainerInfoUI:prerender()
    ISPanelJoypad.prerender(self)
    local col = CONST.COLOR.borderColor
    -- title text
    self:drawTextureScaled(self.tex_titleBG, 0, 0, self:getWidth() - 2, self.titleHeigh - 1, 1, 1, 1, 1);
    self:drawRectBorder(0, 0, self:getWidth(), self.titleHeigh, col.a, col.r, col.g, col.b)
    self:drawTextCentre(self.title, self:getWidth() / 2, 1, 1, 1, 1, 1, UIFont.Medium)

    -- bathing action guide text
    if self._availabilityState and self._availabilityState.takingBath then
        local anchorPanel = self.showerPanel or self.entryPanel
        if not anchorPanel then return end

        local textCol = CONST.COLOR.textColor
        local x = BORDER_SPACING * 3
        local y = self.tubWaterStatusPanel:getBottom() + BORDER_SPACING
        local valueX = x + getTextManager():MeasureStringX(UIFont.Small, "W : ")
        for key, text in pairs(self.bathingActionKeyGuides) do
            self:drawText(tostring(key), x, y, textCol.r, textCol.g, textCol.b, textCol.a, UIFont.Small)
            self:drawText(": " .. getText(text), valueX, y, textCol.r, textCol.g, textCol.b, textCol.a, UIFont.Small)
            y = y + FONT_HGT_SMALL
        end
    end
end

function TABAS_TubFluidContainerInfoUI:renderMainPanelFocus()
    if not self.joypadIndex or not self.joypadIndexY then
        return
    end
    local row = self.joypadButtonsY and self.joypadButtonsY[self.joypadIndexY]
    local button = row and row[self.joypadIndex]
    local parent = button and button.parent
    if parent and parent.joypadFocused and parent.renderJoypadFocus then
        parent:renderJoypadFocus()
    end
end

function TABAS_TubFluidContainerInfoUI:render()
    ISPanelJoypad.render(self)
    self:renderMainPanelFocus()
end

function TABAS_TubFluidContainerInfoUI:markDirty(dirty)
    if dirty == "fast" then
        self._dirtyFast = true
    elseif dirty == "slow" then
        self._dirtySlow = true
    else
        self._dirtyFast = true
        self._dirtySlow = true
    end
end

local function getCurrentQueueActionType(playerObj)
    local actionQueue = ISTimedActionQueue.getTimedActionQueue(playerObj)
    local queue = actionQueue and actionQueue.queue or nil
    if not queue or #queue == 0 then return nil end

    local action = queue[1]
    return action and action.Type or nil
end

local function getQueueActionTypes(playerObj)
    local actionQueue = ISTimedActionQueue.getTimedActionQueue(playerObj)
    local queue = actionQueue and actionQueue.queue or nil
    if not queue or #queue == 0 then
        return nil
    end
    return queue
end

local function hasBathingTrackedAction(queue)
    if not queue then return false end

    for i = 1, #queue do
        local actionType = queue[i] and queue[i].Type or nil
        if actionType and not BATHING_PHASE_WALK_ACTIONS[actionType]
        and (BATHING_PHASE_ANCHOR_ACTIONS[actionType] or BATHING_PHASE_ACTION_TEXT_KEYS[actionType]) then
            return true
        end
    end

    return false
end

local function findQueuedBathingTextKey(queue, startIndex)
    if not queue then return nil end

    for i = startIndex or 1, #queue do
        local actionType = queue[i] and queue[i].Type or nil
        if actionType and not BATHING_PHASE_WALK_ACTIONS[actionType] then
            local textKey = BATHING_PHASE_ACTION_TEXT_KEYS[actionType]
            if textKey then
                return textKey, actionType
            end
        end
    end

    return nil
end

function TABAS_TubFluidContainerInfoUI:resolveBathingPhaseState()
    local playerState = getPlayerState(self.playerNum)
    local md = self.playerObj and self.playerObj:getModData()
    local isBathing = md and md.tabas_IsBathing == true
    local takingBath = isBathing
        and self.playerObj:getVariableBoolean("TABAS_TakeBath")
        and self.playerObj:getVariableBoolean("TABAS_BathStarted")

    local queue = getQueueActionTypes(self.playerObj)
    local curActionType = getCurrentQueueActionType(self.playerObj)
    local hasTrackedAction = hasBathingTrackedAction(queue)
    local isPhaseWalk = curActionType and BATHING_PHASE_WALK_ACTIONS[curActionType] == true

    if takingBath or isBathing or hasTrackedAction or (playerState.bathingPhaseStarted and isPhaseWalk) then
        playerState.bathingPhaseStarted = true
    elseif playerState.bathingPhaseStarted then
        playerState.bathingPhaseStarted = nil
        playerState.lastBathingPhaseTextKey = nil
    end

    local textKey = nil
    if curActionType and not BATHING_PHASE_WALK_ACTIONS[curActionType] then
        textKey = BATHING_PHASE_ACTION_TEXT_KEYS[curActionType]
    end
    if not textKey then
        textKey = findQueuedBathingTextKey(queue, 1)
    end
    if not textKey then
        if takingBath then
            textKey = "IGUI_TABAS_Bathing"
        elseif playerState.bathingPhaseStarted then
            textKey = playerState.lastBathingPhaseTextKey or self.text_preparing
        else
            textKey = self.text_preparing
        end
    end

    if playerState.bathingPhaseStarted then
        playerState.lastBathingPhaseTextKey = textKey
    end

    return {
        takingBath = takingBath,
        bathingPhaseStarted = playerState.bathingPhaseStarted == true,
        bathingPhaseText = getText(textKey),
    }
end

function TABAS_TubFluidContainerInfoUI:checkAvailability()
    if not self.tfc_Base then return end

    local phaseState = self:resolveBathingPhaseState()
    local bathingPhaseStarted = phaseState.bathingPhaseStarted
    local bathingPhaseText = phaseState.bathingPhaseText
    local alreadyInTub = TABAS_Utils.isAleadyInTub(self.playerObj, self.tfc_Base)
    local using = TABAS_Utils.isCurrentlyUsing(self.playerObj, self.tfc_Base.bathObject, self.tfc_Base.linkedBathObject)
    local unavailable = bathingPhaseStarted or using
    local panelUnavailable = unavailable and not phaseState.takingBath
    local titleText = bathingPhaseStarted and bathingPhaseText or (using and self.text_using or self.text_takeBath)

    self.bathingPhaseStarted = bathingPhaseStarted
    self.isTakingBath = phaseState.takingBath

    if self._takeBathTitle ~= titleText then
        self._takeBathTitle = titleText
        self.actionPanel:setTakeBathTitle(self._takeBathTitle)
    end

    local tooltip = nil
    local notAvailable = false

    if bathingPhaseStarted then
        tooltip = nil
    elseif using then
        tooltip = self.text_using
    else
        tooltip, notAvailable = self.tfc_Base:getTakeBathWarningText("")
        tooltip = tooltip ~= "" and tooltip or nil
    end

    if self.actionPanel then
        self.actionPanel:updateAvailability(tooltip, (not unavailable) and notAvailable == false, phaseState.takingBath)
    end

    self.tfcPanel.notAvailable = panelUnavailable
    self.temperaturePanel.notAvailable = panelUnavailable

    if self.entryPanel then
        self.entryPanel:setInteractionDisabled(bathingPhaseStarted or alreadyInTub)
        self.entryPanel:setVisible(not bathingPhaseStarted)
    end
    if self.autoBathTimePanel then
        self.autoBathTimePanel:setVisible(not bathingPhaseStarted)
        self.autoBathTimePanel:syncEnabled()
    end

    if self.bathSessionPanel then
        self.bathSessionPanel:setBathingPhaseState(bathingPhaseStarted, bathingPhaseText)
        self.bathSessionPanel:setVisible(bathingPhaseStarted)
    end

    if bathingPhaseStarted and self.playerNum ~= nil and JoypadState.players[self.playerNum + 1] then
        local joypadData = JoypadState.players[self.playerNum + 1]
        local focus = joypadData and joypadData.focus or nil
        if focus == self.entryPanel or focus == self.autoBathTimePanel or focus == self.showerPanel then
            setJoypadFocus(self.playerNum, self)
        end
    end

    self._availabilityState = {
        takingBath = phaseState.takingBath,
        bathingPhaseStarted = bathingPhaseStarted,
        bathingPhaseText = bathingPhaseText,
        alreadyInTub = alreadyInTub,
        using = using,
        unavailable = unavailable,
    }

    return self._availabilityState
end

function TABAS_TubFluidContainerInfoUI:syncForClient()
    if not isClient() or not self:isReallyVisible() then return end
    local nowMs = getTimestampMs()
    if nowMs >= self._nextWatchMs then
        local square = self.tfc_Base and self.tfc_Base:getSquare()
        if square then
            self._nextWatchMs = nowMs + WATCH_REFRESH_MS
            sendClientCommand(self.playerObj, "tabas_tfc", "watch", { x = square:getX(), y = square:getY(), z = square:getZ(), ms = WATCH_TTL_MS })
        end
    end
end

function TABAS_TubFluidContainerInfoUI:update()
    local worldMs = TABAS_GameTimes.getWorldAgeMs()
    -- sync data for client
    self:syncForClient()

    -- delay update data
    if self._forceRefreshOnce or self._dirtyFast or worldMs >= self._nextFastMs then
        self._dirtyFast = false
        self._nextFastMs = worldMs + (self._fastIntervalMs or 120)

        local availabilityState = self:checkAvailability()
        if self.showerPanel then
            self.showerPanel:refreshShowerPanel(availabilityState)
        end

        self.tfcPanel:updateButtons()
        self.temperaturePanel:updateButtons()
        self.bathSaltPanel:refreshFast()
        self.entryPanel:refreshFast()
    end

    -- ---- Slow tick
    if self._forceRefreshOnce or self._forceStatusRefresh or self._dirtySlow or worldMs >= self._nextSlowMs then
        self._dirtySlow = false
        self._nextSlowMs = worldMs + (self._slowIntervalMs or 600)

        -- Status panels
        self.tubStatusPanel:refreshStatus(self._forceRefreshOnce)
        self.tubWaterStatusPanel:refreshStatus(self._forceRefreshOnce)
        self.temperaturePanel:refreshStatus(self._forceRefreshOnce)

        -- BathSalt
        self.bathSaltPanel:refreshSlow(self._forceRefreshOnce)

        -- EntryPanel
        self.entryPanel:refreshUI(self._forceRefreshOnce)
        self.autoBathTimePanel:syncEnabled()
    end

    if isClient() then -- Always refresh in SP.
        self._forceRefreshOnce = false
    end

    -- check distance
    local col = self.pinned and CONST.COLOR.variableColor or {r=0.5, g=0.5, b=0.5, a=1}
    self.btnPin:setTextureRGBA(col.r, col.g, col.b, col.a)

    local dist = self.pinned and MAX_PANEL_DIST_PINNED or MAX_PANEL_DIST

    if self.tfc_Base and self.tfc_Base:getSquare() and self.playerObj then
        local square = self.tfc_Base:getSquare()
        if self.playerObj:getX() < square:getX()-dist or self.playerObj:getX() > square:getX()+dist
        or self.playerObj:getY() < square:getY()-dist or self.playerObj:getY() > square:getY()+dist then
            self:close()
            return
        end
    else
        self:close()
        return
    end
end

function TABAS_TubFluidContainerInfoUI:ownsJoypadFocus(focus)
    if not focus then return false end
    if focus == self then return true end
    if focus._mainPanel == self then return true end

    local parent = focus.parent
    while parent do
        if parent == self then
            return true
        end
        parent = parent.parent
    end
    return false
end

function TABAS_TubFluidContainerInfoUI:close()
    if self.configPanel and self.configPanel.instance ~= nil then
        self.configPanel:close()
    end

    local tutorial = self.tutorialPanel
    if tutorial and tutorial:isReallyVisible() then
        if tutorial._mainPanel == self then
            tutorial._mainPanel = nil
        end
    end
    self.tutorialPanel = nil

    if self.playerObj then
        if TABAS_TubFluidContainerInfoUI.players[self.playerNum] then
            TABAS_TubFluidContainerInfoUI.players[self.playerNum].instance = nil
            TABAS_TubFluidContainerInfoUI.players[self.playerNum].x = self:getX()
            TABAS_TubFluidContainerInfoUI.players[self.playerNum].y = self:getY()
            TABAS_TubFluidContainerInfoUI.players[self.playerNum].pinned = self.pinned == true
        end
        if tutorial and tutorial:isReallyVisible() then

        elseif JoypadState.players[self.playerNum+1] then
            local joypadData = JoypadState.players[self.playerNum + 1]
            local focus = joypadData and joypadData.focus or nil
            if self:ownsJoypadFocus(focus) then
                setJoypadFocus(self.playerNum, nil)
            end
        end
    end

    self:setVisible(false)
    self:removeFromUIManager()
    TABAS_Panel.releaseTooltips()
end

function TABAS_TubFluidContainerInfoUI:clickedDropBox(x, y)
    self.bathSaltPanel:clickedDropBox(x, y)
end

function TABAS_TubFluidContainerInfoUI:toggleTutorialPanel()
    if not TABAS_TutorialPanel then return end

    local panel = self.tutorialPanel
    if panel and not panel:isReallyVisible() then
        self.tutorialPanel = nil
        panel = nil
    end

    if panel and panel._mainPanel ~= self then
        self.tutorialPanel = nil
        panel = nil
    end

    if panel then
        panel:close()
        return
    end

    panel = TABAS_TutorialPanel.openPanel(self.playerObj, self)
    self.tutorialPanel = panel

    if panel and self.playerNum ~= nil and JoypadState.players[self.playerNum + 1] then
        setJoypadFocus(self.playerNum, panel)
    end
end

function TABAS_TubFluidContainerInfoUI:onClick(_btn)
    if _btn.internal == "CLOSE" then
        return self:close()
    elseif _btn.internal == "PIN" then
        self.pinned = not self.pinned
        return
    elseif _btn.internal == "TUTORIAL" then
        self:toggleTutorialPanel()
        return
    end

    self:markDirty()
    self._forceStatusRefresh = true
end

function TABAS_TubFluidContainerInfoUI:clearMainPanelFocus()
    local panels = {
        self.temperaturePanel,
        self.bathSaltPanel,
        self.tfcPanel,
        self.actionPanel,
    }
    for i = 1, #panels do
        local panel = panels[i]
        if panel and panel.setJoypadFocused then
            panel:setJoypadFocused(false)
        end
    end
end

function TABAS_TubFluidContainerInfoUI:updateMainPanelFocus()
    if not self.joypadIndex or self.joypadIndex <= 0 then
        return
    end
    local row = self.joypadButtonsY and self.joypadButtonsY[self.joypadIndexY]
    local button = row and row[self.joypadIndex]
    if not button then
        return
    end
    local parent = button.parent
    if parent and parent.setJoypadFocused then
        parent:setJoypadFocused(true)
    end
end

function TABAS_TubFluidContainerInfoUI:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData)
    self.joypadButtons = {}
    self.joypadButtonsY = {}
    self:insertNewLineOfButtons(self.temperaturePanel.btnReheat, self.temperaturePanel.btnSetTempe, self.bathSaltPanel.btnAdd, self.bathSaltPanel.itemDropBoxJoypad)
    self:insertNewLineOfButtons(self.tfcPanel.btnFill)
    self:insertNewLineOfButtons(self.tfcPanel.btnStop)
    self:insertNewLineOfButtons(self.tfcPanel.btnEmpty)
    self:insertNewLineOfButtons(self.actionPanel.btnTakeBath, self.actionPanel.btnConfig)

    if self.prevJoypadIndex and self.prevJoypadIndexY then
        self.joypadIndex = self.prevJoypadIndex
        self.joypadIndexY = self.prevJoypadIndexY
    else
        self.joypadIndexY = #self.joypadButtonsY
        self.joypadIndex = 1
    end
    self.joypadButtons = self.joypadButtonsY[self.joypadIndexY] or {}
    self:restoreJoypadFocus(joypadData)
    self:updateMainPanelFocus()
end

function TABAS_TubFluidContainerInfoUI:onLoseJoypadFocus(joypadData)
    ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
    self.prevJoypadIndex = self.joypadIndex
    self.prevJoypadIndexY = self.joypadIndexY
    self:clearMainPanelFocus()
    self:clearJoypadFocus(joypadData)
end

function TABAS_TubFluidContainerInfoUI:onJoypadDown(button, joypadData)
    if button == Joypad.BButton then
        self:close()
        return
    end
    if button == Joypad.XButton then
        self.pinned = not self.pinned
        getSoundManager():playUISound("UIActivateButton")
        return
    end
    if button == Joypad.LBumper then
        if not self.entryPanel or not self.entryPanel:isReallyVisible() then
            return
        end
        self:clearMainPanelFocus()
        joypadData.focus:setJoypadFocused(false, joypadData)
        setJoypadFocus(self.playerNum, self.entryPanel)
        return
    end
    ISPanelJoypad.onJoypadDown(self, button, joypadData)
end

function TABAS_TubFluidContainerInfoUI:onJoypadDirUp(joypadData)
    ISPanelJoypad.onJoypadDirUp(self, joypadData)
    self:updateMainPanelFocus()
end

function TABAS_TubFluidContainerInfoUI:onJoypadDirDown(joypadData)
    ISPanelJoypad.onJoypadDirDown(self, joypadData)
    self:updateMainPanelFocus()
end

function TABAS_TubFluidContainerInfoUI:onJoypadDirLeft(joypadData)
    ISPanelJoypad.onJoypadDirLeft(self, joypadData)
    self:updateMainPanelFocus()
end

function TABAS_TubFluidContainerInfoUI:onJoypadDirRight(joypadData)
    ISPanelJoypad.onJoypadDirRight(self, joypadData)
    self:updateMainPanelFocus()
end

function TABAS_TubFluidContainerInfoUI:getBPrompt()
    return getText("UI_Close")
end

function TABAS_TubFluidContainerInfoUI:isValidPrompt()
    return self:isReallyVisible()
end

function TABAS_TubFluidContainerInfoUI:getAPrompt()
    return getText("IGUI_TABAS_SelectButton")
end

function TABAS_TubFluidContainerInfoUI:getXPrompt()
    if self.pinned then
        return getText("IGUI_TABAS_Unpin")
    end
    return getText("IGUI_TABAS_Pin")
end

function TABAS_TubFluidContainerInfoUI:getLBPrompt()
    return self.entryPanel and self.entryPanel:isReallyVisible() and getText("IGUI_TABAS_SelectOption") or nil
end

function TABAS_TubFluidContainerInfoUI:getRBPrompt()
    return nil
end

function TABAS_TubFluidContainerInfoUI:new(x, y, width, height, playerObj, tfc_Base)
    local o = ISPanelJoypad.new(self, x, y, width, height)
    o.title = getText("IGUI_TABAS_BathtubInfo_Title")
    o.titleHeigh = FONT_HGT_MEDIUM
    o.backgroundColor = CONST.COLOR.backgroundColorDark

    local texture = CONST.TEXTURE
    o.tex_infoIcon = texture.infoButton_small
    o.tex_pinButton = texture.pinButton
    o.tex_closeButton = texture.closeButton
    o.tex_tutorialButton = texture.infoButton
    o.tex_titleBG = texture.bg_title
    o.tex_statusBG = texture.bg_status
    o.tex_btnBG = texture.bg_button
    o.text_takeBath = getText("IGUI_TABAS_TakeBath")
    o.text_using = getText("ContextMenu_TABAS_CurrentlyUsing")
    o.text_bathingGuideTitle = "Bath Controls"
    o.text_preparing = "IGUI_TABAS_Bathing_Preparing"
    o.bathingActionKeyGuides = {
        ["W"] = getText("IGUI_TABAS_Radial_GetOutBath"),
        ["A"] = getText("IGUI_TABAS_Radial_WashSelf"),
        ["D"] = getText("IGUI_TABAS_Radial_StanceChange"),
        ["S"] = getText("IGUI_TABAS_Radial_SwitchAutoStance"),
    }
    o.moveWithMouse = true

	o.pinned = false
    o.playerObj = playerObj
    o.playerNum = playerObj:getPlayerNum()
    o.tfc_Base = tfc_Base

    o.isMain = true
    o.tutorialLastPage = 1
    o.tutorialPanel = nil

    o._nextWatchMs = 0
    o._nextFastMs = 0
    o._nextSlowMs = 0
    o._dirtyFast = true
    o._dirtySlow = true
    o._fastIntervalMs = 120
    o._slowIntervalMs = 600
    o._forceRefreshOnce = true
    o.joypadButtons = {}
    o.joypadButtonsY = {}
    o.overrideBPrompt = true

    o._managedPanels = true
    return o
end
