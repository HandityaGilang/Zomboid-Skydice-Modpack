local M = {}

local RenderConfig = require "render/IH_RenderConfig"
local Utils = require "util/IH_Utils"
local WIRES = RenderConfig.WIRES
local UI = RenderConfig.UI

local function updateVisibilityFlags(self, slots, wires)
    local showScrews = not self.panelOpen
    self.screw1Visible = showScrews and not self.screw1Done
    self.screw2Visible = showScrews and not self.screw2Done

    local showWires = self.panelOpen
    for _, slot in ipairs(slots) do
        local wire = wires[slot.internal]
        slot.visible = showWires and not wire.hidden
    end
end

local function computeContentRect(self)
    local PAD = UI.PAD
    local HEADER_H = UI.HEADER_H
    local FOOTER_H = UI.FOOTER_H

    local contentX = PAD
    local contentY = HEADER_H + PAD
    local contentW = self.width - (PAD * 2)
    local contentH = self.height - HEADER_H - FOOTER_H - (PAD * 2)

    if contentW < 1 then contentW = 1 end
    if contentH < 1 then contentH = 1 end

    self.contentX = contentX
    self.contentY = contentY
    self.contentW = contentW
    self.contentH = contentH

    return contentX, contentY, contentW, contentH
end

local function computePanelRect(self, contentX, contentY, contentW, contentH)
    local panelW = UI.PANEL_W or 901
    local panelH = UI.PANEL_H or 599
    if self.textures.panel then
        panelW = self.textures.panel:getWidthOrig()
        panelH = self.textures.panel:getHeightOrig()
    end

    local scale = contentW / panelW
    local scaleMax = UI.SCALE_MAX or 1.0
    local scaleMin = UI.SCALE_MIN or 0.1
    scale = Utils.clamp(scale, scaleMin, scaleMax)
    self.panelScale = scale

    local scaledPanelW = panelW * scale
    local scaledPanelH = panelH * scale

    self.panelX = contentX + (contentW - scaledPanelW) / 2
    self.panelY = contentY + (contentH - scaledPanelH) / 2
    self.panelW = scaledPanelW
    self.panelH = scaledPanelH

    return scale
end

local function layoutScrews(self, scale)
    local screwW = UI.SCREW_W or 30
    local screwH = UI.SCREW_H or 30
    if self.textures.screw then
        screwW = self.textures.screw:getWidthOrig()
        screwH = self.textures.screw:getHeightOrig()
    end

    self.screwW = screwW * scale
    self.screwH = screwH * scale

    self.screwDrawX1 = self.panelX + ((UI.SCREW_POS_X1 or 275) * scale)
    self.screwDrawX2 = self.panelX + ((UI.SCREW_POS_X2 or 596) * scale)
    self.screwDrawY = self.panelY + ((UI.SCREW_POS_Y or 250) * scale)
end

local function layoutWires(self, slots, wires, contentX, contentY, contentW, contentH, scale)
    local baseWireW = slots[1] and (slots[1].baseW or slots[1].w) or 0
    local wireW = baseWireW * scale
    local groupW = wireW + ((#slots - 1) * WIRES.STACK_STEP_X * scale)
    local anchorX = contentX + ((contentW - groupW) / 2) + (WIRES.STACK_START_X * scale)
    local anchorY = (contentY + contentH) - (WIRES.STACK_START_Y * scale)
    self.wireGroupX = anchorX
    self.wireGroupY = anchorY
    self.wireGroupW = groupW

    local groupMinY = nil
    local groupMaxY = nil
    for i, slot in ipairs(slots) do
        local baseW = slot.baseW or slot.w
        local baseH = slot.baseH or slot.h

        slot.w = baseW * scale
        slot.h = baseH * scale
        slot.scale = scale

        local stepX = (i - 1) * WIRES.STACK_STEP_X * scale
        local stepY = (i - 1) * WIRES.STACK_STEP_Y * scale
        local jitter = ((wires[i] and wires[i].jitterX) or 0) * scale

        local x = anchorX + stepX + jitter
        local y = anchorY - slot.h + stepY

        slot.x = x
        slot.y = y

        if wires[i] then
            wires[i].homeX = x
            wires[i].homeY = y
        end
        if not groupMinY or y < groupMinY then
            groupMinY = y
        end
        local slotMaxY = y + slot.h
        if not groupMaxY or slotMaxY > groupMaxY then
            groupMaxY = slotMaxY
        end
    end
    self.wireGroupH = (groupMaxY and groupMinY) and (groupMaxY - groupMinY) or 0
end

function M.updateUiVisibility(self)
    local slots = self.wireSlots
    local wires = self.wires
    updateVisibilityFlags(self, slots, wires)

    local contentX, contentY, contentW, contentH = computeContentRect(self)
    local scale = computePanelRect(self, contentX, contentY, contentW, contentH)
    layoutScrews(self, scale)
    layoutWires(self, slots, wires, contentX, contentY, contentW, contentH, scale)

    local closeW = UI.CLOSE_BTN_W or 120
    local closeH = UI.CLOSE_BTN_H or 28

    self.closeBtn:setWidth(closeW)
    self.closeBtn:setHeight(closeH)
    self.closeBtn:setX((self.width - closeW) / 2)
    local closeOffset = UI.CLOSE_BTN_OFFSET_Y or 0
    self.closeBtn:setY(self.height - closeH - closeOffset)
end

return M



