local M = {}

function M.canStartDrag(state, wire)
    if not state.panelOpen then
        return false
    end
    if state.dragging then
        return false
    end
    if wire.cutPending then
        return false
    end
    if not wire.cut then
        return false
    end
    return true
end

function M.canCutWire(state, wire)
    if not state.panelOpen then
        return false
    end
    if wire.cutPending then
        return false
    end
    return wire.cut ~= true
end

function M.canDropOn(state, dragWire, targetWire)
    if not state.panelOpen then
        return false
    end
    if dragWire == targetWire then
        return false
    end
    if not dragWire.cut or not targetWire.cut then
        return false
    end
    return true
end

function M.isStarterInvolved(dragWire, targetWire)
    return dragWire.role == "starter" or targetWire.role == "starter"
end

local function hasRole(wire, role)
    return wire.roles[role] == true
end

function M.isDangerCombo(dragWire, targetWire)
    if not M.isStarterInvolved(dragWire, targetWire) then
        return false
    end
    local hasBattery = hasRole(dragWire, "battery") or hasRole(targetWire, "battery")
    local hasIgnition = hasRole(dragWire, "ignition") or hasRole(targetWire, "ignition")
    return hasBattery and not hasIgnition
end

function M.isHotwireCombo(dragWire, targetWire)
    if not M.isStarterInvolved(dragWire, targetWire) then
        return false
    end
    local hasBattery = hasRole(dragWire, "battery") or hasRole(targetWire, "battery")
    local hasIgnition = hasRole(dragWire, "ignition") or hasRole(targetWire, "ignition")
    return hasBattery and hasIgnition
end

return M
