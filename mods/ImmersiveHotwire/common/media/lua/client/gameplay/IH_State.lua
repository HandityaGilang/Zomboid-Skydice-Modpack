local SandboxSettings = require "config/IH_SandboxSettings"
local Actions = require "gameplay/IH_Actions"

local M = {}

local function recomputeReadyToTouch(self)
    self.readyToTouch = false
    for _, wire in ipairs(self.wires) do
        if wire.roles and wire.roles.battery and wire.roles.ignition then
            self.readyToTouch = true
            return true
        end
    end
    return false
end

local function resetWireState(wire)
    wire.cut = false
    wire.cutPending = nil
    wire.tapePending = nil
    wire.taped = false
    wire.hidden = false
    wire.tailHidden = false
    wire.mergedColors = nil
    wire.mergedOffsets = nil
    wire.mergedLeftColor = nil
    wire.mergedCenterColor = nil
    wire.mergedRightColor = nil
end

local function buildWireState(self)
    local wires = {}
    local connections = self.wireConnections
    for i, wire in ipairs(self.wires) do
        local target = connections and connections[i]
        if type(target) == "number" then
            wires[i] = { target = target }
        elseif wire.taped then
            wires[i] = "taped"
        elseif wire.cut then
            wires[i] = "cut"
        end
    end
    return wires
end

function M.getBoundVehicle(self)
    if self.boundVehicle then
        return self.boundVehicle
    end
    local player = self.playerObj
    if player then
        return player:getVehicle()
    end
    return nil
end

function M.collectPersistedState(self)
    return {
        screw1Done = self.screw1Done == true,
        screw2Done = self.screw2Done == true,
        version = SandboxSettings.DATA_VERSION,
        wires = buildWireState(self),
    }
end

function M.applyPersistedState(self)
    local vehicle = M.getBoundVehicle(self)
    if not vehicle then
        return false
    end
    local md = vehicle:getModData()
    local data = md.IH
    if type(data) ~= "table" then
        return false
    end
    self._ihRev = data._rev or self._ihRev
    if data.screw1Done ~= nil then
        self.screw1Done = data.screw1Done == true
    end
    if data.screw2Done ~= nil then
        self.screw2Done = data.screw2Done == true
    end
    if self.screw1Done and self.screw2Done then
        self.panelOpen = true
    end
    for _, wire in ipairs(self.wires) do
        resetWireState(wire)
    end

    local wireStates = data.wires
    local connections = {}
    local hasConnections = false
    if type(wireStates) == "table" then
        for i, wire in ipairs(self.wires) do
            local entry = wireStates[i]
            if entry == "cut" then
                wire.cut = true
            elseif entry == "taped" then
                wire.taped = true
                wire.tailHidden = true
            elseif type(entry) == "table" then
                local target = entry.target
                if type(target) == "number" and target >= 1 and target <= #self.wires then
                    connections[i] = target
                    connections[target] = target
                    hasConnections = true
                    wire.cut = true
                end
            end
        end
    else
        local cuts = data.cuts
        local taped = data.taped
        local oldConnections = data.connections
        if type(cuts) == "table" or type(taped) == "table" or type(oldConnections) == "table" then
            for i, wire in ipairs(self.wires) do
                if type(cuts) == "table" and cuts[i] then
                    wire.cut = true
                end
                if type(taped) == "table" and taped[i] then
                    wire.taped = true
                    wire.cut = false
                    wire.tailHidden = true
                end
            end
            if type(oldConnections) == "table" then
                for i, target in pairs(oldConnections) do
                    if type(target) == "number" and target >= 1 and target <= #self.wires and target ~= i then
                        connections[i] = target
                        connections[target] = target
                        hasConnections = true
                        if self.wires[i] then
                            self.wires[i].cut = true
                        end
                        if self.wires[target] then
                            self.wires[target].cut = true
                        end
                    end
                end
            end
        end
    end
    recomputeReadyToTouch(self)
    if hasConnections then
        self.pendingMergeState = connections
        self.wireConnections = connections
    else
        self.pendingMergeState = nil
        self.wireConnections = {}
    end
    return true
end

function M.applyPredictedState(self, state)
    if type(state) ~= "table" then
        return false
    end
    if state.screw1Done ~= nil then
        self.screw1Done = state.screw1Done == true
    end
    if state.screw2Done ~= nil then
        self.screw2Done = state.screw2Done == true
    end
    if self.screw1Done and self.screw2Done then
        self.panelOpen = true
    end
    for _, wire in ipairs(self.wires) do
        resetWireState(wire)
    end
    local wireStates = state.wires
    if type(wireStates) ~= "table" then
        return false
    end
    local connections = {}
    local hasConnections = false
    for i, wire in ipairs(self.wires) do
        local entry = wireStates[i]
        if entry == "cut" then
            wire.cut = true
        elseif entry == "taped" then
            wire.taped = true
            wire.tailHidden = true
        elseif type(entry) == "table" then
            local target = entry.target
            if type(target) == "number" and target >= 1 and target <= #self.wires then
                connections[i] = target
                connections[target] = target
                hasConnections = true
                wire.cut = true
            end
        end
    end
    recomputeReadyToTouch(self)
    if hasConnections then
        self.pendingMergeState = connections
        self.wireConnections = connections
    else
        self.pendingMergeState = nil
        self.wireConnections = {}
    end
    return true
end

function M.applyPersistedMerges(self)
    local connections = self.pendingMergeState
    local wires = self.wires
    local slots = self.wireSlots
    local count = #wires
    local groups = {}
    local hasGroups = false
    for i = 1, count do
        local target = connections[i]
        if type(target) == "number" and target >= 1 and target <= count then
            local group = groups[target]
            if not group then
                group = { target }
                groups[target] = group
                hasGroups = true
            end
            if i ~= target then
                group[#group + 1] = i
            end
        end
    end
    if not hasGroups then
        return false
    end
    for targetIndex, members in pairs(groups) do
        local targetWire = wires[targetIndex]
        if targetWire then
            for _, idx in ipairs(members) do
                local wire = wires[idx]
                if wire and wire.roles then
                    for role, has in pairs(wire.roles) do
                        if has then
                            targetWire.roles[role] = true
                        end
                    end
                end
            end
            local formatWireLabel = self.formatWireLabel
            if formatWireLabel then
                targetWire.label = formatWireLabel(self, targetWire.roles)
            end

            local ordered = {}
            for i = 1, #members do
                ordered[i] = members[i]
            end
            table.sort(ordered, function(a, b)
                local slotA = slots[a]
                local slotB = slots[b]
                local ax = slotA and slotA.x or 0
                local bx = slotB and slotB.x or 0
                return ax < bx
            end)

            local targetSlot = slots[targetIndex]
            local baseX = targetSlot and targetSlot.x or 0
            local mergedColors = {}
            local mergedOffsets = {}
            for i = 1, #ordered do
                local idx = ordered[i]
                local wire = wires[idx]
                local slot = slots[idx]
                mergedColors[i] = (wire and wire.color) or targetWire.color
                local x = slot and slot.x or baseX
                mergedOffsets[i] = x - baseX
            end
            if #mergedColors >= 2 then
                targetWire.mergedColors = mergedColors
                targetWire.mergedOffsets = mergedOffsets
                if #mergedColors >= 3 then
                    targetWire.mergedLeftColor = mergedColors[1]
                    targetWire.mergedCenterColor = mergedColors[2]
                    targetWire.mergedRightColor = mergedColors[3]
                else
                    targetWire.mergedLeftColor = mergedColors[1]
                    targetWire.mergedRightColor = mergedColors[2]
                    targetWire.mergedCenterColor = nil
                end
            end

            for _, idx in ipairs(members) do
                if idx ~= targetIndex then
                    local wire = wires[idx]
                    if wire then
                        wire.hidden = true
                    end
                end
            end
        end
    end
    recomputeReadyToTouch(self)
    return true
end

function M.savePersistedState(self)
    local vehicle = M.getBoundVehicle(self)
    if not vehicle then
        return
    end
    local state = M.collectPersistedState(self)
    if isClient() then
        sendClientCommand(self.playerObj, "IH", "UpdateState", {
            vehicleId = vehicle:getId(),
            state = state,
        })
        return
    end
    Actions.applyHotwireState(vehicle, state, #self.wires, SandboxSettings.DATA_VERSION, self.playerObj)
end

return M



