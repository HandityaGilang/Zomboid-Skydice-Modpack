local Masks = require "render/IH_Masks"
local RenderConfig = require "render/IH_RenderConfig"
local Config = require "config/IH_Config"
local SandboxSettings = require "config/IH_SandboxSettings"
local Utils = require "util/IH_Utils"
local WireModel = require "gameplay/IH_WireModel"
local Rules = require "gameplay/IH_Rules"
local SparkVfx = require "render/IH_SparkVfx"
local Drag = require "ui/IH_Drag"
local State = require "gameplay/IH_State"
local Actions = require "gameplay/IH_Actions"
local ToolsSync = require "net/IH_ToolsSync"
local ANGLES = RenderConfig.ANGLES
local SPARK = Config.SPARK
local WIRES = RenderConfig.WIRES
local getTools = ToolsSync.get
local DUCT_TAPE = "Base.DuctTape"
local UNSCREW_REWARD_CMD = "UnscrewReward"

local function shouldMarkHotwired(wire)
    return wire.roles.battery == true or wire.roles.starter == true or wire.roles.ignition == true
end

local function recomputeReadyToTouch(self)
    self.readyToTouch = false
    for _, wire in ipairs(self.wires) do
        if wire.roles and wire.roles.battery and wire.roles.ignition then
            self.readyToTouch = true
            return
        end
    end
end

local function unmergeWire(self, targetIndex)
    local targetWire = self.wires[targetIndex]
    if WireModel.countRoles(targetWire) < 2 then
        return false
    end
    local mergedRoles = targetWire.roles
    for _, wire in ipairs(self.wires) do
        if wire.hidden and wire.role and mergedRoles[wire.role] then
            wire.hidden = false
            wire.roles = { [wire.role] = true }
            wire.mergedColors = nil
            wire.mergedOffsets = nil
            wire.mergedLeftColor = nil
            wire.mergedCenterColor = nil
            wire.mergedRightColor = nil
            wire.label = self:formatWireLabel(wire.roles)
        end
    end
    local targetRole = targetWire.role
    targetWire.roles = targetRole and { [targetRole] = true } or {}
    targetWire.mergedColors = nil
    targetWire.mergedOffsets = nil
    targetWire.mergedLeftColor = nil
    targetWire.mergedCenterColor = nil
    targetWire.mergedRightColor = nil
    targetWire.label = self:formatWireLabel(targetWire.roles)
    recomputeReadyToTouch(self)
    self:updateUiVisibility()
    local connections = self.wireConnections
    if type(connections) == "table" then
        for i, v in pairs(connections) do
            if i == targetIndex or v == targetIndex then
                connections[i] = nil
            end
        end
    end
    self:savePersistedState()
    return true
end

local function areCriticalWiresTaped(self)
    local hasBattery = false
    local hasIgnition = false
    local hasStarter = false
    for _, wire in ipairs(self.wires) do
        if wire.roles and (wire.taped or wire.cut ~= true) then
            if wire.roles.battery then
                hasBattery = true
            end
            if wire.roles.ignition then
                hasIgnition = true
            end
            if wire.roles.starter then
                hasStarter = true
            end
        end
    end
    return hasBattery and hasIgnition and hasStarter
end

local function clearHotwiredIfTaped(self)
    if not areCriticalWiresTaped(self) then
        return
    end
    local vehicle = State.getBoundVehicle(self)
    if not vehicle then
        return
    end
    if isClient() then
        sendClientCommand(self.playerObj, "IH", "ClearHotwired", {
            vehicleId = vehicle:getId(),
        })
        return
    end
    Actions.clearHotwired(vehicle)
end

local M = {}

function M.isPointOverWire(slot, wire, px, py)
    local texId = wire.texId or 1
    local angleDeg = wire.lastAngleDeg or 0
    local scale = slot.scale or 1
    if angleDeg ~= 0 then
        local pivotX, pivotY = Utils.getWirePivot(slot.x, slot.y, slot.h, scale, WIRES.PIVOT_X, WIRES.PIVOT_Y)
        local theta = math.rad(-angleDeg)
        local ox = px - pivotX
        local oy = py - pivotY
        local cosT = math.cos(theta)
        local sinT = math.sin(theta)
        px = (ox * cosT) - (oy * sinT) + pivotX
        py = (ox * sinT) + (oy * cosT) + pivotY
    end
    local lx = px - slot.x
    local ly = py - slot.y
    if scale ~= 1 then
        lx = lx / scale
        ly = ly / scale
    end
    local roleCount = WireModel.countRoles(wire)
    if roleCount >= 3 then
        return Masks.containsMerged3(lx, ly)
    elseif roleCount == 2 then
        return Masks.containsMerged2(lx, ly)
    end
    return Masks.contains(texId, lx, ly, wire.cut)
end

function M.isPointOverTail(slot, wire, px, py)
    local texId = wire.texId
    local scale = slot.scale
    local lx = px - slot.x
    local ly = py - slot.y
    if scale ~= 1 then
        lx = lx / scale
        ly = ly / scale
    end
    return Masks.containsTail(texId, lx, ly)
end

function M.canTapeWire(self, wire)
    return wire.cut == true and not wire.taped and not wire.hidden and not wire.tapePending and WireModel.countRoles(wire) == 1
end

function M.getDuctTapeItem(self)
    local player = self.playerObj
    if not player then
        return nil
    end
    local inv = player:getInventory()
    return inv:getFirstTypeEvalRecurse(DUCT_TAPE, function(item)
        return item:getCurrentUsesFloat() > 0
    end)
end

function M.attemptTapeOnTail(self, dragIndex, mouseX, mouseY)
    if self.migrationLocked then
        return false
    end
    local wire = self.wires[dragIndex]
    if not M.canTapeWire(self, wire) then
        return false
    end
    local tapeItem = nil
    if SandboxSettings.isDucttapeNeededToUnhotwire() then
        tapeItem = M.getDuctTapeItem(self)
        if not tapeItem then
            return false
        end
    end
    local slot = self.dragging and self.dragging.slot or self.wireSlots[dragIndex]
    local tailSlot = slot
    if self.dragging and self.dragging.index == dragIndex then
        local homeX = self.dragging.homeX or slot.x
        local homeY = self.dragging.homeY or slot.y
        tailSlot = {
            x = homeX,
            y = homeY,
            w = slot.w,
            h = slot.h,
            scale = slot.scale,
        }
    end
    if not M.isPointOverTail(tailSlot, wire, mouseX, mouseY) then
        return false
    end
    wire.tapePending = getTimestampMs() + 1000
    self.actionLock = "tape"
    self:playUISound("PZ_DuctTape")
    wire.lastAngleDeg = 0
    if self.dragging then
        self.dragging.angleDeg = 0
        self.dragging.slot.visible = true
        self.dragging = nil
    end
    self:updateUiVisibility()
    return true
end

function M.isBlocked(self, checkLock)
    if checkLock ~= false and self.actionLock then
        return true
    end
    if self:isGamePaused() then
        return true
    end
    return false
end

local function onScrew(self, index)
    if self.migrationLocked then
        return
    end
    if self:isBlocked() then
        return
    end
    if not self:hasTool(getTools("SCREWDRIVERS"), getTools("SCREWDRIVERS_TAGS")) then
        return
    end
    local pendingKey = index == 1 and "screw1Pending" or "screw2Pending"
    self.actionLock = "screw"
    self[pendingKey] = getTimestampMs() + 2500
    self:playUISound("IH_Screw")
end

M.onScrew = onScrew

local function resolveScrewPending(self, now, pendingKey, doneKey)
    if not self[pendingKey] or now < self[pendingKey] then
        return false
    end
    self[pendingKey] = nil
    self[doneKey] = true
    self.actionLock = nil
    if isClient() then
        local vehicle = State.getBoundVehicle(self)
        sendClientCommand(self.playerObj, "IH", UNSCREW_REWARD_CMD, {
            vehicleId = vehicle and vehicle:getId() or nil,
        })
    else
        self.playerObj:getInventory():AddItem("Base.Screws")
    end
    return true
end

function M.onWireMouseDown(self, slot, x, y)
    if self.migrationLocked then
        return
    end
    if self:isBlocked() then
        return
    end
    local idx = slot.internal
    local wire = self.wires[idx]
    local panelX = slot.x + x
    local panelY = slot.y + y
    if not M.isPointOverWire(slot, wire, panelX, panelY) then
        return
    end
    if isAltKeyDown() then
        if unmergeWire(self, idx) then
            return
        end
    end
    if Rules.canCutWire(self, wire) then
        if not wire.taped then
            if not self:hasTool(getTools("PLIERS"), getTools("PLIERS_TAGS")) then
                return
            end
        end
        if wire.taped then
            self.actionLock = "untape"
        else
            self.actionLock = "wire"
        end
        wire.cutPending = getTimestampMs() + 800
        self:updateUiVisibility()
        if wire.taped then
            self:playUISound("PZ_DuctTape")
        else
            self:playUISound("IH_Wire")
        end
        return
    end

    if Rules.canStartDrag(self, wire) then
        self:startDrag(slot, idx, panelX, panelY)
    end
end

function M.update(self)
    ISPanel.update(self)

    if self:isBlocked(false) then
        self:onClose()
        return
    end

    local player = self.playerObj
    if not player then
        self:onClose()
        return
    end
    local vehicle = player:getVehicle()
    if not vehicle then
        self:onClose()
        return
    end
    if self.boundVehicle and vehicle ~= self.boundVehicle then
        self:onClose()
        return
    end
    if self.boundSeat ~= nil then
        local seat = vehicle:getSeat(player)
        if seat ~= self.boundSeat then
            self:onClose()
            return
        end
    end

    local md = vehicle:getModData()
    local ih = md.IH
    if type(ih) ~= "table" then
        ih = {}
    end
    local rev = ih._rev or 0
    if self._ihRev ~= rev then
        self._ihRev = rev
        if self:applyPersistedState() then
            if self.pendingMergeState then
                self:applyPersistedMerges()
                self.pendingMergeState = nil
            end
        end
        if self.migrationLocked then
            self.migrationLocked = nil
        end
        self:updateUiVisibility()
    end

    local now = getTimestampMs()
    local dirty = false
    local persistDirty = false

    if resolveScrewPending(self, now, "screw1Pending", "screw1Done") then
        dirty = true
        persistDirty = true
    end
    if resolveScrewPending(self, now, "screw2Pending", "screw2Done") then
        dirty = true
        persistDirty = true
    end
    if self.screw1Done and self.screw2Done and not self.panelOpen then
        self.panelOpen = true
        dirty = true
    end

    for i, wire in ipairs(self.wires) do
        if wire.cutPending and now >= wire.cutPending then
            wire.cutPending = nil
            wire.cut = true
            wire.taped = false
            wire.tailHidden = nil
            self.actionLock = nil
            dirty = true
            persistDirty = true
            if shouldMarkHotwired(wire) then
                if isClient() then
                    sendClientCommand(self.playerObj, "IH", "SetHotwired", {
                        vehicleId = vehicle:getId(),
                    })
                else
                    Actions.setHotwired(vehicle)
                end
            end
        end
        if wire.tapePending and now >= wire.tapePending then
            wire.tapePending = nil
            local canApply = true
            if SandboxSettings.isDucttapeNeededToUnhotwire() then
                local tapeItem = M.getDuctTapeItem(self)
                if tapeItem then
                    local uses = tapeItem:getCurrentUsesFloat()
                    local useDelta = tapeItem:getUseDelta()
                    local nextUses = uses - useDelta
                    if nextUses < 0 then
                        nextUses = 0
                    end
                    tapeItem:setUsedDelta(nextUses)
                else
                    self.actionLock = nil
                    canApply = false
                end
            end
            if canApply then
                wire.taped = true
                wire.cut = false
                wire.cutPending = nil
                wire.tailHidden = true
                self.actionLock = nil
                dirty = true
                persistDirty = true
                clearHotwiredIfTaped(self)
                self:raiseWireToFront(i)
            end
        end
    end

    if persistDirty then
        self:savePersistedState()
    end

    if dirty then
        self:updateUiVisibility()
    end
end

function M.getWireButtonAt(self, x, y, excludeIndex)
    local slots = self.wireSlots
    local wires = self.wires
    local indices = {}
    if self.wireDrawOrder and #self.wireDrawOrder > 0 then
        for i = #self.wireDrawOrder, 1, -1 do
            indices[#indices + 1] = self.wireDrawOrder[i]
        end
    else
        for i = #slots, 1, -1 do
            indices[#indices + 1] = i
        end
    end

    for i = 1, #indices do
        local idx = indices[i]
        local slot = slots[idx]
        if slot.visible then
            local wireIndex = slot.internal or idx
            if wireIndex ~= excludeIndex then
                local wire = wires[wireIndex]
                if M.isPointOverWire(slot, wire, x, y) then
                    return slot, wireIndex
                end
            end
        end
    end
    return nil, nil
end

function M.startDrag(self, slot, index, x, y)
    Drag.begin(self, slot, index, x, y)
end

function M.resetDrag(self)
    Drag.cancel(self)
end

function M.raiseWireToFront(self, index)
    local count = self.wireCount or #self.wires
    if count <= 0 then
        return
    end
    if not self.wireDrawOrder or #self.wireDrawOrder ~= count then
        self.wireDrawOrder = {}
        for i = 1, count do
            self.wireDrawOrder[i] = i
        end
    end
    local order = self.wireDrawOrder
    local found = nil
    for i = 1, #order do
        if order[i] == index then
            found = i
            break
        end
    end
    if found then
        table.remove(order, found)
    end
    table.insert(order, index)
end

function M.attemptDropOnTarget(self, dragIndex, targetIndex, x, y)
    if self.migrationLocked then
        self:resetDrag()
        return false
    end
    local dragWire = self.wires[dragIndex]
    local targetWire = self.wires[targetIndex]
    if not Rules.canDropOn(self, dragWire, targetWire) then
        self:resetDrag()
        return false
    end

    if self.readyToTouch and Rules.isStarterInvolved(dragWire, targetWire) then
        if not Rules.isHotwireCombo(dragWire, targetWire) then
            self:resetDrag()
            return false
        end

        local kickSign = SparkVfx.kickSignFromDrag(self.dragging.startMouseX, x)
        local kickWire = dragWire
        self:resetDrag()
        self:finishHotwire(kickWire, kickSign)
        return false
    end

    if Rules.isStarterInvolved(dragWire, targetWire) then
        if Rules.isDangerCombo(dragWire, targetWire) then
            local spark = Drag.trySpark(self, {
                startX = self.dragging.startMouseX,
                endX = x,
            })
            self:resetDrag()
            if spark.didSpark then
                local baseAngle = WireModel.getBaseAngle(dragWire, ANGLES)
                SparkVfx.applyKick(dragWire, baseAngle, spark.sign, spark.magnitude, ANGLES.LIMIT)
            end
        else
            self:resetDrag()
        end
        return false
    end

    if not self:canMergeWireRoles(dragWire, targetWire) then
        self:resetDrag()
        return false
    end

    local leftColor = nil
    local rightColor = nil
    local dragSlot = self.wireSlots[dragIndex]
    local targetSlot = self.wireSlots[targetIndex]
    local dragX = dragSlot.x
    local targetX = targetSlot.x

    local mergedColors = nil
    local mergedOffsets = nil

    local pairWire = nil
    local newWire = nil
    local newX = nil
    if dragWire.mergedColors and #dragWire.mergedColors == 2 and dragWire.mergedOffsets and #dragWire.mergedOffsets == 2 then
        pairWire = dragWire
        newWire = targetWire
        newX = targetX
    elseif targetWire.mergedColors and #targetWire.mergedColors == 2 and targetWire.mergedOffsets and #targetWire.mergedOffsets == 2 then
        pairWire = targetWire
        newWire = dragWire
        newX = dragX
    end

    if pairWire then
        local left = pairWire.mergedColors[1]
        local right = pairWire.mergedColors[2]
        local pairBaseX = (pairWire == dragWire) and dragX or targetX
        local leftAbsX = pairBaseX + pairWire.mergedOffsets[1]
        local rightAbsX = pairBaseX + pairWire.mergedOffsets[2]
        local pairMinX = math.min(leftAbsX, rightAbsX)
        local pairMaxX = math.max(leftAbsX, rightAbsX)
        local targetBaseX = targetX
        local pairSlotX = pairBaseX
        if newX >= pairSlotX then
            mergedColors = { left, right, newWire.color }
            mergedOffsets = { pairMinX - targetBaseX, pairMaxX - targetBaseX, newX - targetBaseX }
        else
            mergedColors = { newWire.color, left, right }
            mergedOffsets = { newX - targetBaseX, pairMinX - targetBaseX, pairMaxX - targetBaseX }
        end
        leftColor = mergedColors[1]
        rightColor = mergedColors[2]
    else
        local firstColor = targetWire.color
        local secondColor = dragWire.color
        local firstX = targetX
        local secondX = dragX
        if secondX < firstX then
            firstColor, secondColor = secondColor, firstColor
            firstX, secondX = secondX, firstX
        end
        mergedColors = { firstColor, secondColor }
        mergedOffsets = { firstX - targetX, secondX - targetX }
        leftColor = mergedColors[1]
        rightColor = mergedColors[2]
    end

    self:mergeWireRoles(targetWire, dragWire, leftColor, rightColor, mergedColors, mergedOffsets)
    dragWire.hidden = true
    self.dragging.slot.visible = false
    self.dragging = nil
    if self:wireHasRole(targetWire, "battery") and self:wireHasRole(targetWire, "ignition") then
        self.readyToTouch = true
    end
    self:updateUiVisibility()
    local connections = self.wireConnections
    if type(connections) ~= "table" then
        connections = {}
        self.wireConnections = connections
    end
    connections[dragIndex] = targetIndex
    connections[targetIndex] = targetIndex
    if pairWire == dragWire then
        for i, v in pairs(connections) do
            if v == dragIndex then
                connections[i] = targetIndex
            end
        end
    end
    self:savePersistedState()
    M.raiseWireToFront(self, targetIndex)
    return true
end

function M.finishHotwire(self, kickWire, kickSign)
    local vehicle = self.playerObj:getVehicle()
    if not self:hasBatteryCharge() then
        return false
    end
    self:playUISound("IH_Starter")

    local chance = self:getElectronicsHotwireChance()
    local ok = Utils.rollChance(chance)
    if ok then
        if isClient() then
            sendClientCommand(self.playerObj, "IH", "HotwireSuccess", {
                vehicleId = vehicle:getId(),
                drainPercent = SPARK.BATTERY_DRAIN,
            })
            self:removeFromUIManager()
            return true
        end
        Actions.applyHotwireSuccess(vehicle)
        Actions.drainBattery(vehicle, SPARK.BATTERY_DRAIN, true)
        self:removeFromUIManager()
        return true
    end
    if isClient() then
        sendClientCommand(self.playerObj, "IH", "AddAlarmRisk", {
            vehicleId = vehicle:getId(),
            amount = SandboxSettings.ALARM.ADD_FAIL_START,
        })
    else
        Actions.IH_AddAlarmRisk(vehicle, SandboxSettings.ALARM.ADD_FAIL_START, self.playerObj)
    end
    if kickWire then
        local kickMin = math.floor((RenderConfig.SPARK.KICK_MIN or 0) / 2)
        local kickMax = math.floor((RenderConfig.SPARK.KICK_MAX or 0) / 2)
        if kickMax < kickMin then kickMax = kickMin end
        local kickMagnitude = SparkVfx.rollKickMagnitude(kickMin, kickMax)
        local baseAngle = WireModel.getBaseAngle(kickWire, ANGLES)
        SparkVfx.applyKick(kickWire, baseAngle, kickSign, kickMagnitude, ANGLES.LIMIT)
    end
    return false
end

function M.onMouseDown(self, x, y)
    if self:isBlocked(false) then
        return ISPanel.onMouseDown(self, x, y)
    end
    if self.migrationLocked then
        if self.panelOpen and self.closeBtn:isVisible() and self.closeBtn:isMouseOver() then
            return ISPanel.onMouseDown(self, x, y)
        end
        return true
    end
    if not self.panelOpen then
        local screwW, screwH = self:getScrewSize()
        local function hitScrew(px, py, sx, sy)
            return px >= sx and py >= sy and px <= (sx + screwW) and py <= (sy + screwH)
        end
        if self.screw1Visible and hitScrew(x, y, self.screwDrawX1, self.screwDrawY) then
            self:onScrew(1)
            return true
        end
        if self.screw2Visible and hitScrew(x, y, self.screwDrawX2, self.screwDrawY) then
            self:onScrew(2)
            return true
        end
    end

    if self.panelOpen then
        if self.closeBtn:isVisible() and self.closeBtn:isMouseOver() then
            return ISPanel.onMouseDown(self, x, y)
        end
        local mx = self:getMouseX()
        local my = self:getMouseY()
        local slot, idx = self:getWireButtonAt(mx, my, nil)
        if slot and idx then
            self:onWireMouseDown(slot, mx - slot.x, my - slot.y)
            return true
        end
    end

    return ISPanel.onMouseDown(self, x, y)
end

function M.onMouseUp(self, x, y)
    if self:isBlocked(false) then
        return ISPanel.onMouseUp(self, x, y)
    end
    if not self.dragging then
        return ISPanel.onMouseUp(self, x, y)
    end
    return Drag.finish(self, x, y)
end

function M.areAllWiresCut(self)
    for _, wire in ipairs(self.wires) do
        if not wire.cut then
            return false
        end
    end
    return true
end

return M




