require "ISUI/ISPanel"
require "ISUI/ISButton"
require "util/IH_DebugUtils"

local Controller = require "ui/IH_Controller"
local ToolsSync = require "net/IH_ToolsSync"
local Layout = require "ui/IH_Layout"
local Labels = require "ui/IH_Labels"
local Textures = require "render/IH_Textures"
local RenderConfig = require "render/IH_RenderConfig"
local Config = require "config/IH_Config"
local State = require "gameplay/IH_State"
local Actions = require "gameplay/IH_Actions"
local Utils = require "util/IH_Utils"
local SandboxSettings = require "config/IH_SandboxSettings"
local Drag = require "ui/IH_Drag"
local WireModel = require "gameplay/IH_WireModel"
local SparkGameplay = require "gameplay/IH_SparkGameplay"
local SparkVfx = require "render/IH_SparkVfx"
local Render = require "render/IH_Render"
local WireSeed = require "util/IH_WireSeed"

IH_HotwireWindow = IH_HotwireWindow or {}

IHWindow = ISPanel:derive("IHWindow")

local WIRE_ROLE_COLORS = RenderConfig.WIRE_ROLE_COLORS
local UI = RenderConfig.UI
local WIRES = RenderConfig.WIRES
local TEXT = RenderConfig.getTextTable()
local ROLES = Config.ROLES
local HOVER_ALPHA = RenderConfig.HOVER_ALPHA
local getTools = ToolsSync.get

local isPointOverWire = Controller.isPointOverWire
local isPointOverTail = Controller.isPointOverTail

local IH_nextRand = Utils.nextRand
local IH_shuffle = Utils.shuffle
local applyUnderDash = Actions.IH_UnderDash_Apply
local clearUnderDash = Actions.IH_UnderDash_Clear

IHWindow.onScrew = Controller.onScrew
IHWindow.onWireMouseDown = Controller.onWireMouseDown
IHWindow.isBlocked = Controller.isBlocked
IHWindow.update = Controller.update
IHWindow.getWireButtonAt = Controller.getWireButtonAt
IHWindow.startDrag = Controller.startDrag
IHWindow.resetDrag = Controller.resetDrag
IHWindow.attemptDropOnTarget = Controller.attemptDropOnTarget
IHWindow.attemptTapeOnTail = Controller.attemptTapeOnTail
IHWindow.finishHotwire = Controller.finishHotwire
IHWindow.onMouseDown = Controller.onMouseDown
IHWindow.onMouseUp = Controller.onMouseUp
IHWindow.raiseWireToFront = Controller.raiseWireToFront
IHWindow.areAllWiresCut = Controller.areAllWiresCut
IHWindow.isPointOverTail = Controller.isPointOverTail
IHWindow.canTapeWire = Controller.canTapeWire
IHWindow.getDuctTapeItem = Controller.getDuctTapeItem
IHWindow.updateUiVisibility = Layout.updateUiVisibility
IHWindow.loadTextures = Textures.loadTextures
IHWindow.getWireTexture = Textures.getWireTexture
IHWindow.getWireTailTexture = Textures.getWireTailTexture
IHWindow.getWireCutLayers = Textures.getWireCutLayers
IHWindow.getWireTailLayers = Textures.getWireTailLayers
IHWindow.getMerged2Layers = Textures.getMerged2Layers
IHWindow.getMerged3Layers = Textures.getMerged3Layers
IHWindow.getBoundVehicle = State.getBoundVehicle
IHWindow.collectPersistedState = State.collectPersistedState
IHWindow.applyPersistedState = State.applyPersistedState
IHWindow.applyPredictedState = State.applyPredictedState
IHWindow.applyPersistedMerges = State.applyPersistedMerges
IHWindow.savePersistedState = State.savePersistedState
IHWindow.buildRoleLabelMap = Labels.buildRoleLabelMap
IHWindow.buildRoleLabel = Labels.buildRoleLabel
IHWindow.formatWireLabel = Labels.formatWireLabel
IHWindow.formatWireAction = Labels.formatWireAction

function IHWindow:wireHasRole(wire, role)
    return wire.roles[role] == true
end

local function normalizeItemTagName(name)
    if type(name) ~= "string" then
        return nil
    end
    local trimmed = name:gsub("^%s+", ""):gsub("%s+$", "")
    if trimmed == "" then
        return nil
    end
    return trimmed
end

local function hasInventoryTag(inv, name)
    local tagName = normalizeItemTagName(name)
    if not tagName then
        return false
    end
    local ok, tag = pcall(function()
        return ItemTag.get(ResourceLocation.of(tagName))
    end)
    if not ok or not tag then
        return false
    end
    return inv:containsTagRecurse(tag)
end

function IHWindow:hasTool(typeName, tagName)
    local player = self.playerObj
    if not player then
        return false
    end
    local inv = player:getInventory()
    if type(typeName) == "table" then
        for _, name in ipairs(typeName) do
            if inv:containsTypeRecurse(name) then
                return true
            end
        end
    elseif type(typeName) == "string" and inv:containsTypeRecurse(typeName) then
        return true
    end
    if type(tagName) == "table" then
        for _, name in ipairs(tagName) do
            if hasInventoryTag(inv, name) then
                return true
            end
        end
        return false
    end
    if type(tagName) == "string" then
        return hasInventoryTag(inv, tagName)
    end
    return false
end

function IHWindow:isGamePaused()
    return getGameSpeed() == 0
end

local function getWireClipRect(self)
    local cx = math.floor(self.panelX)
    local cy = math.floor(self.panelY)
    local cw = math.floor(self.panelW)
    local ch = math.floor(self.panelH)
    local shiftY = (self.contentY + self.contentH) - self.wireGroupY
    cy = math.floor(self.panelY - shiftY)
    local scale = self.panelScale
    local rightTrim = math.floor(245 * scale)
    cw = cw - rightTrim
    return cx, cy, cw, ch
end

local function applyWireClip(self, cx, cy, cw, ch)
    self:setStencilRect(cx, cy, cw, ch)
end

local function clearWireClip(self)
    self:clearStencilRect()
end

local function isPointInRect(px, py, rx, ry, rw, rh)
    return px >= rx and py >= ry and px <= (rx + rw) and py <= (ry + rh)
end

local function easeAngle(self, targetAngleDeg, easeMs)
    local nowMs = getTimestampMs()
    if self.dragging.angleDeg == nil then
        self.dragging.angleDeg = targetAngleDeg
    else
        local dt = math.max(0, nowMs - (self.dragging.angleMs or nowMs))
        local t = math.min(dt / easeMs, 1)
        local eased = 1 - ((1 - t) * (1 - t) * (1 - t))
        self.dragging.angleDeg = self.dragging.angleDeg + (targetAngleDeg - self.dragging.angleDeg) * eased
    end
    self.dragging.angleMs = nowMs
    return self.dragging.angleDeg
end

local function renderWireAtSlot(self, slot, wire, alpha, angleDeg)
    local layers = Render.buildWireLayers(self.textures, wire)
    if #layers == 0 then
        return
    end
    Render.drawWire(self, slot, layers, { angle = angleDeg, alpha = alpha })
end

local function findHoverIndex(self, mx, my, drawOrder)
    if mx < 0 or my < 0 or mx > self.width or my > self.height then
        return nil
    end
    for i = #drawOrder, 1, -1 do
        local idx = drawOrder[i]
        local slot = self.wireSlots[idx]
        if slot.visible then
            local wireIndex = slot.internal or idx
            local wire = self.wires[wireIndex]
            if isPointOverWire(slot, wire, mx, my) then
                return wireIndex
            end
        end
    end
    return nil
end

local function findHoverTailIndex(self, mx, my, drawOrder)
    if mx < 0 or my < 0 or mx > self.width or my > self.height then
        return nil
    end

    if not self.dragging then
        return nil
    end

    for i = #drawOrder, 1, -1 do
        local idx = drawOrder[i]
        local slot = self.wireSlots[idx]
        local wireIndex = slot.internal or idx
        local wire = self.wires[wireIndex]

        if wireIndex == self.dragging.index then
            if wire.cut and not wire.tailHidden then
                local tailSlot = slot
                if self.dragging and self.dragging.index == wireIndex then
                    tailSlot = {
                        x = self.dragging.homeX or slot.x,
                        y = self.dragging.homeY or slot.y,
                        w = slot.w,
                        h = slot.h,
                        scale = slot.scale,
                    }
                end

                if isPointOverTail(tailSlot, wire, mx, my) then
                    return wireIndex
                end
            end
        end
    end
    return nil
end

local getWireDrawOrder

local function rotatePoint(x, y, pivotX, pivotY, angleDeg)
    local angle = math.rad(angleDeg)
    local cosT = math.cos(angle)
    local sinT = math.sin(angle)
    local ox = x - pivotX
    local oy = y - pivotY
    return (ox * cosT) - (oy * sinT) + pivotX, (ox * sinT) + (oy * cosT) + pivotY
end


local function renderDragging(self)
    if not self.dragging then
        return
    end
    local slot = self.dragging.slot

    local wire = self.wires[self.dragging.index]
    local layers = Render.buildWireLayers(self.textures, wire)
    if #layers > 0 then

        local mouseX = self:getMouseX()
        local mouseY = self:getMouseY()

        local ROTATE_EASE_MS = WIRES.ROTATE_EASE_MS or 500
        local targetAngleDeg = Drag.update(self, mouseX, mouseY)
        local angleDeg = easeAngle(self, targetAngleDeg, ROTATE_EASE_MS)
        wire.lastAngleDeg = angleDeg
        Render.drawWire(self, slot, layers, { angle = angleDeg, alpha = 1.0 })

        local scale = slot.scale or 1
        local mergedCount = WireModel.countRoles(wire)
        local dragAnchor
        if mergedCount >= 3 then
            dragAnchor = WIRES.DRAG_ANCHOR_MERGED3
        elseif mergedCount == 2 then
            dragAnchor = WIRES.DRAG_ANCHOR_MERGED2
        else
            dragAnchor = WIRES.DRAG_ANCHORS[wire.texId or 1]
        end

        local anchorX = slot.x + (dragAnchor.x * scale)
        local anchorY = slot.y + slot.h - (dragAnchor.y * scale)
        local pivotX, pivotY = Utils.getWirePivot(slot.x, slot.y, slot.h, scale, WIRES.PIVOT_X, WIRES.PIVOT_Y)
        local rotX, rotY = rotatePoint(anchorX, anchorY, pivotX, pivotY, angleDeg)

        local absX = self:getAbsoluteX()
        local absY = self:getAbsoluteY()
        local x1 = mouseX + absX
        local y1 = mouseY + absY
        local x2 = rotX + absX
        local y2 = rotY + absY

        if SandboxSettings.isDragLineEnabled() then
            local dx = x2 - x1
            local dy = y2 - y1
            local len = math.sqrt((dx * dx) + (dy * dy))
            if len > 0 then
                local ux = dx / len
                local uy = dy / len
                local nx = -uy
                local ny = ux
                local dash = 6
                local gap = 10
                local step = dash + gap
                local thickness = 2
                local half = thickness * 0.5
                local lineTex = self.textures.line
                local colors
                local offsets
                if mergedCount >= 3 then
                    local mergedColors = wire.mergedColors or {
                        wire.mergedLeftColor or wire.color,
                        wire.mergedCenterColor or wire.color,
                        wire.mergedRightColor or wire.color,
                    }
                    colors = {
                        { Render.getTint(mergedColors[1]) },
                        { Render.getTint(mergedColors[2]) },
                        { Render.getTint(mergedColors[3]) },
                    }
                    offsets = { -1, 0, 1 }
                elseif mergedCount == 2 then
                    local leftColor = wire.mergedLeftColor or wire.color
                    local rightColor = wire.mergedRightColor or wire.color
                    colors = {
                        { Render.getTint(leftColor) },
                        { Render.getTint(rightColor) },
                    }
                    offsets = { -0.5, 0.5 }
                else
                    colors = { { Render.getTint(wire.color) } }
                    offsets = { 0 }
                end
                local t = 0
                while t < len do
                    local segLen = math.min(dash, len - t)
                    local sx = x1 + (ux * t)
                    local sy = y1 + (uy * t)
                    local ex = sx + (ux * segLen)
                    local ey = sy + (uy * segLen)
                    for i = 1, #colors do
                        local offset = offsets[i] * thickness
                        local ox = nx * offset
                        local oy = ny * offset
                        local r, g, b = colors[i][1], colors[i][2], colors[i][3]
                        self:drawTextureAllPoint(
                            lineTex,
                            sx + ox + (nx * half), sy + oy + (ny * half),
                            ex + ox + (nx * half), ey + oy + (ny * half),
                            ex + ox - (nx * half), ey + oy - (ny * half),
                            sx + ox - (nx * half), sy + oy - (ny * half),
                            r, g, b, 0.3
                        )
                    end
                    t = t + step
                end
            end
        end
    else
        self:drawRect(slot.x, slot.y, slot.w, slot.h, UI.DRAG_FALLBACK_ALPHA or 0.2, 1, 1, 1)
        self:drawRectBorder(slot.x, slot.y, slot.w, slot.h, UI.DRAG_FALLBACK_BORDER_ALPHA or 0.8, 1, 1, 1)
    end
end

function IHWindow:getElectronicsHotwireChance()
    local level = Actions.getPerkLevel(self.playerObj, Perks.Electricity)

    if level <= 1 then return 0.45 end
    if level == 2 then return 0.60 end
    if level == 3 then return 0.80 end
    return 0.90
end

function IHWindow:getElectronicsSparkChance()
    local level = Actions.getPerkLevel(self.playerObj, Perks.Electricity)

    if level <= 1 then return 0.90 end
    if level == 2 then return 0.50 end
    if level == 3 then return 0.10 end
    return 0
end

function IHWindow:hasBatteryCharge()
    local player = self.playerObj
    local vehicle = player and player:getVehicle() or nil
    return Actions.hasBatteryCharge(vehicle)
end

function IHWindow:getScrewSize()
    if self.screwW and self.screwH then
        return self.screwW, self.screwH
    end
    local screwW = UI.SCREW_W
    local screwH = UI.SCREW_H
    if self.textures and self.textures.screw then
        screwW = self.textures.screw:getWidthOrig()
        screwH = self.textures.screw:getHeightOrig()
    end
    local scale = self.panelScale or 1
    return screwW * scale, screwH * scale
end

function IHWindow:initialise()
    ISPanel.initialise(self)

    self:loadTextures()
    local slotW = UI.DEFAULT_WIRE_SLOT_W
    local slotH = UI.DEFAULT_WIRE_SLOT_H

    local sampleWire = nil
    if self.textures and self.textures.wires then
        sampleWire = self.textures.wires[1]
    end
    if sampleWire then
        slotW = sampleWire:getWidthOrig()
        slotH = sampleWire:getHeightOrig()
    end

    local closeW = UI.CLOSE_BTN_W or 120
    local closeH = UI.CLOSE_BTN_H or 28
    self.closeBtn = ISButton:new(0, 0, closeW, closeH, TEXT.CLOSE, self, IHWindow.onClose)

    self:addChild(self.closeBtn)

    self.wireSlots = {}
    for i = 1, self.wireCount do
        local x = 0
        local y = 0
        table.insert(self.wireSlots, {
            x = x,
            y = y,
            baseW = slotW,
            baseH = slotH,
            w = slotW,
            h = slotH,
            scale = 1,
            internal = i,
            visible = false,
        })
    end

    self:updateUiVisibility()
    if self.pendingMergeState then
        self:applyPersistedMerges()
        self.pendingMergeState = nil
        self:updateUiVisibility()
    end
end

function IHWindow:clearUnderDashEffect()
    if self._underDashCleared then
        return
    end
    self._underDashCleared = true
    clearUnderDash(self.playerObj)
end

function IHWindow:removeFromUIManager()
    self:clearUnderDashEffect()
    if IH_HotwireWindow.hotwireUI == self then
        IH_HotwireWindow.hotwireUI = nil
    end
    ISPanel.removeFromUIManager(self)
end

function IHWindow:onClose()
    self:removeFromUIManager()
end

function IHWindow:playUISound(name)
    local sm = getSoundManager()
    if sm then
        sm:PlaySound(name, false, 1.0)
    elseif self.playerObj then
        self.playerObj:playSound(name)
    end
end

function IHWindow:prerender()
    ISPanel.prerender(self)
    if self.textures.background then
        self:drawTextureScaled(self.textures.background, self.contentX, self.contentY, self.contentW, self.contentH, 1, 1, 1, 1)
    end
    local title = TEXT.TITLE
    local font = UIFont.Medium
    local textW = getTextManager():MeasureStringX(font, title)
    local x = (self.width - textW) / 2
    local titleY = UI.TITLE_Y or 16
    self:drawText(title, x, titleY, 1, 1, 1, 1, font)
end

function IHWindow:renderClosedPanel(mx, my)
    local tooltipText = nil
    if self.textures.panel then
        self:drawTextureScaled(self.textures.panel, self.panelX, self.panelY, self.panelW, self.panelH, 1, 1, 1, 1)
    end

    if self.textures.screw then
        local screwW, screwH = self:getScrewSize()
        local showScrew1 = not self.screw1Done
        local showScrew2 = not self.screw2Done
        local hoverAny = false
        if showScrew1 then
            local hover = isPointInRect(mx, my, self.screwDrawX1, self.screwDrawY, screwW, screwH)
            local alpha = hover and HOVER_ALPHA or 1
            self:drawTextureScaled(self.textures.screw, self.screwDrawX1, self.screwDrawY, screwW, screwH, alpha, 1, 1, 1)
            hoverAny = hoverAny or hover
        end
        if showScrew2 then
            local hover = isPointInRect(mx, my, self.screwDrawX2, self.screwDrawY, screwW, screwH)
            local alpha = hover and HOVER_ALPHA or 1
            self:drawTextureScaled(self.textures.screw, self.screwDrawX2, self.screwDrawY, screwW, screwH, alpha, 1, 1, 1)
            hoverAny = hoverAny or hover
        end
        if hoverAny then
            tooltipText = self:hasTool(getTools("SCREWDRIVERS"), getTools("SCREWDRIVERS_TAGS")) and TEXT.UNSCREW or TEXT.NEED_SCREWDRIVER
        end
    end

    Render.drawTooltip(self, mx, my, tooltipText)
end

function IHWindow:render()
    ISPanel.render(self)

    local mx = self:getMouseX()
    local my = self:getMouseY()
    local tooltipText = nil
    if not self.panelOpen then
        self:renderClosedPanel(mx, my)
        return
    end

    local cx, cy, cw, ch = getWireClipRect(self)

    applyWireClip(self, cx, cy, cw, ch)
    local drawOrder = getWireDrawOrder(self)
    local hoverIndex = findHoverIndex(self, mx, my, drawOrder)
    local hoverTailIndex = findHoverTailIndex(self, mx, my, drawOrder)
    for _, idx in ipairs(drawOrder) do
        local slot = self.wireSlots[idx]
        local wireIndex = slot.internal or idx
        local wire = self.wires[wireIndex]
        if not wire.hidden and slot.visible then
            local isDraggingThis = self.dragging and self.dragging.index == wireIndex
            if not isDraggingThis then
                local alpha = 1.0
                if wire.cutPending then alpha = 0.6 end
                if hoverIndex == wireIndex then alpha = HOVER_ALPHA end
                renderWireAtSlot(self, slot, wire, alpha, wire.lastAngleDeg)
            end
        end
    end
    Render.drawWireTails(self, hoverTailIndex, HOVER_ALPHA)
    if hoverIndex then
        local wire = self.wires[hoverIndex]
        if not wire.cutPending then
            if self.dragging then
                if hoverIndex ~= self.dragging.index and wire.cut then
                    tooltipText = self:formatWireAction(TEXT.CONNECT, wire)
                end
            else
                if wire.cut then
                    tooltipText = self:formatWireAction(TEXT.DRAG, wire)
                    if WireModel.countRoles(wire) >= 2 then
                        tooltipText = string.format("%s\n%s", tooltipText, TEXT.DISCONNECT)
                    end
                elseif wire.taped then
                    tooltipText = self:formatWireAction(TEXT.UNTAPE, wire)
                elseif self:hasTool(getTools("PLIERS"), getTools("PLIERS_TAGS")) then
                    tooltipText = self:formatWireAction(TEXT.CUT, wire)
                else
                    tooltipText = TEXT.NEED_PLIERS
                end
            end
        end
    end
    if self.dragging and hoverTailIndex then
        if SandboxSettings.isDucttapeNeededToUnhotwire() and not self:getDuctTapeItem() then
            tooltipText = TEXT.NEED_DUCT_TAPE
        else
            local wire = self.wires[hoverTailIndex]
            tooltipText = self:formatWireAction(TEXT.TAPE, wire)
        end
    end

    renderDragging(self)
    clearWireClip(self)

    if self.textures.panelOpen then
        self:drawTextureScaled(self.textures.panelOpen, self.panelX, self.panelY, self.panelW, self.panelH, 1, 1, 1, 1)
    end

    Render.drawTooltip(self, mx, my, tooltipText)
end

getWireDrawOrder = function(self)
    local slots = self.wireSlots
    local count = #slots
    if not self.wireDrawOrder or #self.wireDrawOrder ~= count then
        self.wireDrawOrder = {}
        for i = 1, count do
            self.wireDrawOrder[i] = i
        end
    end
    return self.wireDrawOrder
end

function IHWindow:canMergeWireRoles(a, b)
    if self:wireHasRole(a, "starter") or self:wireHasRole(b, "starter") then
        return false
    end
    return true
end

function IHWindow:mergeWireRoles(targetWire, dragWire, leftColor, rightColor, mergedColors, mergedOffsets)
    for role, has in pairs(dragWire.roles) do
        if has then
            targetWire.roles[role] = true
        end
    end
    targetWire.label = self:formatWireLabel(targetWire.roles)
    if mergedColors and #mergedColors >= 2 then
        local cleaned = {}
        for i = 1, #mergedColors do
            cleaned[i] = mergedColors[i] or targetWire.color or dragWire.color or "red"
        end
        targetWire.mergedColors = cleaned
        if mergedOffsets and #mergedOffsets == #cleaned then
            targetWire.mergedOffsets = mergedOffsets
        else
            targetWire.mergedOffsets = nil
        end
        if #cleaned >= 3 then
            targetWire.mergedLeftColor = cleaned[1]
            targetWire.mergedCenterColor = cleaned[2]
            targetWire.mergedRightColor = cleaned[3]
        else
            targetWire.mergedLeftColor = cleaned[1]
            targetWire.mergedRightColor = cleaned[2]
            targetWire.mergedCenterColor = nil
        end
    else
        targetWire.mergedLeftColor = leftColor or targetWire.mergedLeftColor or targetWire.color
        targetWire.mergedRightColor = rightColor or targetWire.mergedRightColor or targetWire.color
    end
end

function IHWindow:applySparkEffects()
    if not SparkGameplay.apply(self) then
        return false
    end
    SparkVfx.apply(self)
    return true
end

local function pickWireColor(role, seed, mechanicsLevel)
    if mechanicsLevel <= 0 then
        return "gray"
    end
    if mechanicsLevel == 1 and role ~= "battery" then
        return "gray"
    end
    local list = WIRE_ROLE_COLORS[role]
    if not list or #list == 0 then
        return "red"
    end
    if #list == 1 then
        return list[1]
    end
    local idx = (seed % #list) + 1
    return list[idx]
end

local function IH_buildWires(self, vehicleId)
    local count = (vehicleId % 2) + 3
    local roles = { ROLES.BASE[1], ROLES.BASE[2], ROLES.BASE[3] }
    local extraRoles = { ROLES.EXTRA[1] }
    local wires = {}

    local seed = vehicleId
    if count == 4 then
        seed = IH_nextRand(seed + 7)
        local idx = (seed % #extraRoles) + 1
        table.insert(roles, extraRoles[idx])
    end

    IH_shuffle(roles, seed)

    for i = 1, #roles do
        local role = roles[i]
        local colorSeed = IH_nextRand(vehicleId + i * 17)
        local color = pickWireColor(role, colorSeed, self.mechanicsLevel)

        local wire = WireModel.newWire(seed, i, nil, role, color, { [role] = true })
        wire.label = self:formatWireLabel(wire.roles)
        wires[i] = wire
    end

    return wires
end

local function applyPremodHotwiredState(playerObj, vehicle)
    IH_HotwireWindow._migrateSentById = IH_HotwireWindow._migrateSentById or {}
    IH_HotwireWindow._pendingMigrationById = IH_HotwireWindow._pendingMigrationById or {}
    return Actions.ensureHotwiredMigrated(
        vehicle,
        playerObj,
        IH_HotwireWindow._migrateSentById,
        250,
        IH_HotwireWindow._pendingMigrationById,
        getTimestampMs
    )
end

function IHWindow:new(playerObj, x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.playerObj = playerObj
    o.screw1Done = false
    o.screw2Done = false
    o.panelOpen = false
    o.screw1Pending = nil
    o.screw2Pending = nil
    o.readyToTouch = false
    o.whiteConnected = false
    o.brownTouched = false
    o.screwInProgress = false
    o.wireConnections = {}

    local vehicle = playerObj and playerObj:getVehicle() or nil
    local vehicleId = WireSeed.getStableHotwireId(vehicle)

    o.mechanicsLevel = Actions.getHotwireSkill(o.playerObj)
    o.roleLabelMap = o:buildRoleLabelMap(vehicleId)
    o.wires = IH_buildWires(o, vehicleId)

    local texIds = { 1, 2, 3, 4 }
    local seed = vehicleId + 4242
    for i = 1, #o.wires do
        seed = IH_nextRand(seed + i * 31)
        local r = (seed % 41) - 20
        o.wires[i].jitterX = r
    end
    IH_shuffle(texIds, vehicleId + 999)

    for i = 1, #o.wires do
        o.wires[i].texId = texIds[i]
    end
    o.wireCount = #o.wires

    o.persistedStateLoaded = o:applyPersistedState()

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 }
    o.borderColor = { r = 0.45, g = 0.45, b = 0.45, a = 1 }
    return o
end

local outsideClickRegistered = false
local burglarOpenPending = false

local function registerOutsideClickHandler()
    if outsideClickRegistered then
        return
    end
    outsideClickRegistered = true

    Events.OnMouseDown.Add(function()
    local ui = IH_HotwireWindow.hotwireUI
        if not ui or not ui:isReallyVisible() then
            return
        end
        if ui:isMouseOver() then
            return
        end
        ui:onClose()
    end)
end

local function isBurglar(playerObj)
    local prof = tostring(playerObj:getDescriptor():getCharacterProfession()):lower()
    return prof == "burglar" or prof:match(":%s*burglar$") ~= nil
end

local function hasOpenCutsInModData(vehicle)
    local md = vehicle:getModData()
    local data = md.IH
    if type(data) ~= "table" then
        return false
    end
    if data.screw1Done ~= true or data.screw2Done ~= true then
        return false
    end
    local wires = data.wires
    if type(wires) == "table" then
        for _, entry in pairs(wires) do
            if entry == "cut" or type(entry) == "table" then
                return true
            end
        end
        return false
    end
    local cuts = data.cuts
    if type(cuts) ~= "table" then
        return false
    end
    for _, cut in pairs(cuts) do
        if cut then
            return true
        end
    end
    return false
end

local function playBreakSound()
    local sm = getSoundManager()
    if sm then
        sm:PlaySound("IH_Break", false, 1.0)
    end
end

local function applyBurglarSetup(ui)
    ui.screw1Done = true
    ui.screw2Done = true
    ui.screw1Pending = nil
    ui.screw2Pending = nil
    ui.panelOpen = true
    for _, wire in ipairs(ui.wires) do
        wire.cut = true
        wire.cutPending = nil
    end
    ui:updateUiVisibility()
    local vehicle = ui:getBoundVehicle()
    if vehicle then
        if isClient() then
            sendClientCommand(ui.playerObj, "IH", "SetHotwired", {
                vehicleId = vehicle:getId(),
            })
        else
            Actions.setHotwired(vehicle)
        end
    end
    ui:savePersistedState()
end

local function createHotwireUI(playerObj, x, y, w, h, boundVehicle)
    local ui = IHWindow:new(playerObj, x, y, w, h)
    ui:initialise()
    ui:addToUIManager()
    applyUnderDash(playerObj)
    ui.boundVehicle = boundVehicle
    ui.boundSeat = ui.boundVehicle:getSeat(playerObj)
    return ui
end

local function requestStableIdAndDelayOpen(playerObj)
    local vehicle = playerObj and playerObj:getVehicle() or nil
    if not vehicle then
        return false
    end
    local md = vehicle:getModData()
    local stableId = md and md.IH_StableId
    if type(stableId) == "number" and stableId > 0 then
        return true
    end
    IH_HotwireWindow._pendingOpenById = IH_HotwireWindow._pendingOpenById or {}
    local vid = vehicle:getId()
    if IH_HotwireWindow._pendingOpenById[vid] then
        return false
    end
    IH_HotwireWindow._pendingOpenById[vid] = true
    sendClientCommand(playerObj, "IH", "EnsureStableId", { vehicleId = vid })
    local function delayedOpen()
        local v = playerObj and playerObj:getVehicle() or nil
        if not v or v:getId() ~= vid then
            Events.OnTick.Remove(delayedOpen)
            IH_HotwireWindow._pendingOpenById[vid] = nil
            return
        end
        local md2 = v:getModData()
        local sid = md2 and md2.IH_StableId
        if type(sid) ~= "number" or sid <= 0 then
            return
        end
        Events.OnTick.Remove(delayedOpen)
        IH_HotwireWindow._pendingOpenById[vid] = nil
        IH_HotwireWindow.showHotwireWindow(playerObj)
    end
    Events.OnTick.Add(delayedOpen)
    return false
end

function IH_HotwireWindow.showHotwireWindow(playerObj)
    if not requestStableIdAndDelayOpen(playerObj) then
        return
    end
    if isClient() then
        ToolsSync.refreshOnOpen()
    end
    registerOutsideClickHandler()
    if IH_HotwireWindow.hotwireUI and IH_HotwireWindow.hotwireUI:isReallyVisible() then
        return
    end
    if burglarOpenPending then
        return
    end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()

    local panelTex = getTexture("media/textures/panel.png")
    local panelW = panelTex and panelTex:getWidthOrig() or UI.PANEL_W or 901
    local panelH = panelTex and panelTex:getHeightOrig() or UI.PANEL_H or 599

    local PAD = UI.PAD
    local HEADER_H = UI.HEADER_H

    local maxW = screenW * UI.MAX_W_RATIO
    local minW = UI.MIN_W or 0
    local capW = UI.MAX_W or maxW
    local w = Utils.clamp(maxW, minW, capW)

    local contentW = w - (PAD * 2)
    local scale = contentW / panelW
    local scaleMax = UI.SCALE_MAX or 1.0
    local scaleMin = UI.SCALE_MIN or 0.1
    scale = Utils.clamp(scale, scaleMin, scaleMax)
    local contentH = panelH * scale

    local h = HEADER_H + (PAD * 2) + contentH

    local x = (screenW / 2) - (w / 2)
    local y = (screenH / 2) - (h / 2)

    local boundVehicle = playerObj and playerObj:getVehicle() or nil
    applyPremodHotwiredState(playerObj, boundVehicle)
    if isBurglar(playerObj) then
        if hasOpenCutsInModData(boundVehicle) then
            local ui = createHotwireUI(playerObj, x, y, w, h, boundVehicle)
            applyBurglarSetup(ui)
            IH_HotwireWindow.hotwireUI = ui
            return
        end
        playBreakSound()
        burglarOpenPending = true
        local startMs = getTimestampMs()
        local function delayedOpen()
            if (getTimestampMs() - startMs) < 2000 then
                return
            end
            Events.OnTick.Remove(delayedOpen)
            burglarOpenPending = false
            local currentVehicle = playerObj and playerObj:getVehicle() or nil
            local ui = createHotwireUI(playerObj, x, y, w, h, currentVehicle)
            applyBurglarSetup(ui)
            IH_HotwireWindow.hotwireUI = ui
        end
        Events.OnTick.Add(delayedOpen)
        return
    end

    local ui = createHotwireUI(playerObj, x, y, w, h, boundVehicle)
    if boundVehicle and IH_HotwireWindow._pendingMigrationById then
        local vid = boundVehicle:getId()
        local pending = IH_HotwireWindow._pendingMigrationById[vid]
        if pending then
            local ih = boundVehicle:getModData().IH
            if not (type(ih) == "table" and ih._version == SandboxSettings.DATA_VERSION) then
                if ui:applyPredictedState(pending) then
                    if ui.pendingMergeState then
                        ui:applyPersistedMerges()
                        ui.pendingMergeState = nil
                    end
                    ui:updateUiVisibility()
                    ui.migrationLocked = true
                end
            else
                IH_HotwireWindow._pendingMigrationById[vid] = nil
            end
        end
    end
    IH_HotwireWindow.hotwireUI = ui
end

ISVehicleMenu.onHotwire = function(playerObj)
    IH_HotwireWindow.showHotwireWindow(playerObj)
end

return IH_HotwireWindow



