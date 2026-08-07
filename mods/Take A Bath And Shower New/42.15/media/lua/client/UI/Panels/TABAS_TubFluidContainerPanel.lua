require("ISUI/ISPanelJoypad")

TABAS_TubFluidContainerPanel = ISPanelJoypad:derive("TABAS_TubFluidContainerPanel")

local TABAS_Panel = require("UI/TABAS_PanelUtils")
local TABAS_MoveUtils = require("TABAS_MoveUtils")

local CONST = require("UI/TABAS_PanelConst")
local FONT_HGT_SMALL = CONST.SCALE.HGT_SMALL
local HGT_BUTTON = CONST.SCALE.HGT_BUTTON
local BETWEEN_SPACING = CONST.SCALE.BETWEEN_SPACING
local BORDER_SPACING = CONST.SCALE.BORDER_SPACING


function TABAS_TubFluidContainerPanel:initialise()
    ISPanelJoypad.initialise(self)
end

function TABAS_TubFluidContainerPanel:createChildren()
    local btnText = ""
    local btnScale = self.btnScale
    local btnX = BORDER_SPACING*2
    local btnY = HGT_BUTTON
    self.btnFill = TABAS_Panel.addButton(btnX, btnY, btnScale, btnScale, self.tex_fillIcon, btnText, getText("ContextMenu_TABAS_FillTubWater"), self, self.onClick, true)
    self.btnFill.internal = "FILL"

    btnY = self.height/2 - btnScale/2 + BORDER_SPACING
    self.btnStop = TABAS_Panel.addButton(btnX, btnY, btnScale, btnScale, self.tex_stopIcon, btnText, nil, self, self.onClick, true)
    self.btnStop.internal = "STOP"

    btnY = self.height - btnScale - BORDER_SPACING*2
    self.btnEmpty = TABAS_Panel.addButton(btnX, btnY, btnScale, btnScale, self.tex_stopIcon, btnText, getText("ContextMenu_TABAS_EmptyTubWater"), self, self.onClick, true)
    self.btnEmpty.internal = "EMPTY"
    -- self.btnEmpty.actual = "empty" -- can be "empty", "put", "remove"
    self:updateButtons()

    self.tubX = self.btnEmpty:getRight() + HGT_BUTTON
    self.tubY = HGT_BUTTON
    self.tubHeight = self.tubY + self.btnEmpty:getY()-HGT_BUTTON/2
    local barWidth = self.tubWidth - self.tubBGSpacing*2
    local barHeight = self.tubHeight - self.tubBGSpacing*3
    self.fluidBar = ISFluidBar:new(self.tubX + self.tubBGSpacing, self.tubY + self.tubBGSpacing*2, barWidth, barHeight, self.playerObj)
    self.fluidBar:initialise()
    self.fluidBar:instantiate()
    self.fluidBar.bubblesTex = nil

    self:addChild(self.fluidBar)

    self:setFluidContainer()

    if self.container and self.container:getFluidContainer() then
        self.fluidBar:setContainer(self.container:getFluidContainer())
    end
end

function TABAS_TubFluidContainerPanel:prerender()
    ISPanelJoypad.prerender(self)
    -- tub background texture
    self:drawTextureScaled(self.tex_tubBG, self.tubX, self.tubY, self.tubWidth, self.tubHeight, 0.9, 1, 1, 1)
end

function TABAS_TubFluidContainerPanel:render()
    ISPanelJoypad.render(self)
    -- self:renderJoypadFocus()
end

function TABAS_TubFluidContainerPanel:update()
end

function TABAS_TubFluidContainerPanel:updateButtons()
    local hasTfc = self.tfc_Base:hasTfc()
    local hasFluid = self.tfc_Base:hasFluid()
    local btnEmptyActual
    if not hasTfc then
        if self.container ~= nil or self._tfcRef ~= nil then
            self.container = nil
            self._tfcRef = nil
            if self.fluidBar then
                self.fluidBar:setContainer(nil)
            end
        end
    else
        local tfc = self.tfc_Base:getTubFluidContainer()
        if self.container and not ISFluidUtil.validateContainer(self.container) then
            self.container = nil
        end

        if self._tfcRef ~= tfc or self.container == nil then
            self._tfcRef = tfc
            self:setFluidContainer()
            if self.fluidBar then
                self.fluidBar:setContainer(self.container and self.container:getFluidContainer() or nil)
            end
        end
    end

    if not hasTfc then
        btnEmptyActual = "put"
    elseif hasTfc and not hasFluid then
        btnEmptyActual = "remove"
    else
        btnEmptyActual = "empty"
    end

    if self.btnEmpty.actual ~= btnEmptyActual then
        self.btnEmpty:setImage(self.tex_emptyIcons[btnEmptyActual])
        self.btnEmpty:setTooltip(self.emptyTooltips[btnEmptyActual])
        self.btnEmpty.actual = btnEmptyActual
    end

    if self.notAvailable then
        self.btnStop:setEnable(false)
        self.btnEmpty:setEnable(false)
        self.btnFill:setEnable(false)
    else
        local tfcActivated = self.tfc_Base:isActivated("fill") or self.tfc_Base:isActivated("empty")
        self.btnStop:setEnable(tfcActivated)
        self.btnEmpty:setEnable(not tfcActivated)
        self.btnFill:setEnable(hasTfc and not tfcActivated and self.tfc_Base.bathObject:hasFluid() and not self.tfc_Base:isActivated("fill"))
    end
end

function TABAS_TubFluidContainerPanel:onClick(_btn)
    local actionQueue = ISTimedActionQueue.getTimedActionQueue(self.playerObj)
    local doAction = actionQueue.queue[1] ~= nil
    if doAction then return end

    if _btn.internal == "STOP" then
        if self.tfc_Base:isActivated("fill") then
            if not TABAS_MoveUtils.walkToAdjTub(self.playerObj, self.tfc_Base.bathObject, true) then return end
            ISTimedActionQueue.add(TABAS_TubWaterAction:new(self.playerObj, self.tfc_Base, "fill", false))
        elseif self.tfc_Base:isActivated("empty") then
            if not TABAS_MoveUtils.walkToAdjTub(self.playerObj, self.tfc_Base.bathObject, true) then return end
            ISTimedActionQueue.add(TABAS_TubWaterAction:new(self.playerObj, self.tfc_Base, "empty", false))
        end
    elseif _btn.internal == "FILL" then
        if not TABAS_MoveUtils.walkToAdjTub(self.playerObj, self.tfc_Base.bathObject, true) then return end
        ISTimedActionQueue.add(TABAS_TubWaterAction:new(self.playerObj, self.tfc_Base, "fill", true))
    elseif _btn.internal == "EMPTY" then
        if self.btnEmpty.actual == "empty" then
            if not TABAS_MoveUtils.walkToAdjTub(self.playerObj, self.tfc_Base.bathObject, true) then return end
            ISTimedActionQueue.add(TABAS_TubWaterAction:new(self.playerObj, self.tfc_Base, "empty", true))
        elseif self.btnEmpty.actual == "put" then
            if not TABAS_MoveUtils.walkToAdjTub(self.playerObj, self.tfc_Base.bathObject, true) then return end
            ISTimedActionQueue.add(TABAS_TubStopperPutAction:new(self.playerObj, self.tfc_Base))
        elseif self.btnEmpty.actual == "remove" then
            if not TABAS_MoveUtils.walkToAdjTub(self.playerObj, self.tfc_Base.bathObject, true) then return end
            ISTimedActionQueue.add(TABAS_TubStopperRemoveAction:new(self.playerObj, self.tfc_Base))
        end
    end
end

-- function TABAS_TubFluidContainerPanel:onGainJoypadFocus(joypadData)
--     ISPanelJoypad.onGainJoypadFocus(self, joypadData)
-- end

-- function TABAS_TubFluidContainerPanel:onJoypadDown(button, joypadData)
--     ISPanelJoypad.onJoypadDown(self, button, joypadData)
-- end

function TABAS_TubFluidContainerPanel:onLoseJoypadFocus(joypadData)
    ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
end

function TABAS_TubFluidContainerPanel:setFluidContainer()
    local tfc = self.tfc_Base:getTubFluidContainer()
    if tfc then
        local fluidContainer = ISFluidContainer:new(tfc)
        if fluidContainer and ISFluidUtil.validateContainer(fluidContainer) then
            self.container = fluidContainer
            return
        end
    end
    self.container = nil
end

function TABAS_TubFluidContainerPanel:new (x, y, width, height, playerObj, tfc_Base)
    local btnScale = HGT_BUTTON * 1.65
    local minimumWidth = btnScale + BORDER_SPACING*2 + BETWEEN_SPACING*2 + btnScale*4
    local o = ISPanelJoypad:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.x = x
    o.y = y

    o.minimumWidth = 256 + btnScale
    o.minimumHeight = 128 + btnScale/2
    o.width = math.max(minimumWidth, width)
    o.height = height
    o.tubBGSpacing = FONT_HGT_SMALL*0.55
    o.tubWidth = o.width - btnScale - BORDER_SPACING*2 - BETWEEN_SPACING*2 - o.tubBGSpacing*2
    o.tubHeight = o.tubWidth * 0.60
    o.btnScale = btnScale
    o.playerObj = playerObj
    o.tfc_Base = tfc_Base
    o.notAvailable = false

    local texture = CONST.TEXTURE
    o.tex_fillIcon = texture.tub_fillIcon
    o.tex_stopIcon = texture.tub_stopIcon
    o.tex_emptyIcons = {
        empty = texture.tub_emptyIcon,
        remove = texture.tub_removeIcon,
        put = texture.tub_putIcon
    }
    o.emptyTooltips = {
        empty = getText("ContextMenu_TABAS_EmptyTubWater"),
        remove = getText("ContextMenu_TABAS_RemoveTubStopper"),
        put = getText("ContextMenu_TABAS_PutTubStopper")
    }
    o.tex_tubBG = getTexture("media/ui/Backgrounds/tabas_tubFluidContainerBG.png")
    return o
end
