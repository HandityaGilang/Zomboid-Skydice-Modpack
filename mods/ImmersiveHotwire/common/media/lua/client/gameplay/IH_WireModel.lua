local M = {}

function M.newWire(seed, index, texId, role, color, rolesTable)
    local roles = rolesTable or (role and { [role] = true } or {})
    return {
        id = index,
        texId = texId,
        role = role,
        roles = roles,
        color = color,
        cut = false,
        cutPending = nil,
        tapePending = nil,
        taped = false,
        hidden = false,
        tailHidden = false,
        homeX = nil,
        homeY = nil,
        lastAngleDeg = nil,
        mergedColors = nil,
        mergedOffsets = nil,
        mergedLeftColor = nil,
        mergedCenterColor = nil,
        mergedRightColor = nil,
    }
end

function M.cloneWire(wire)
    local roles = {}
    for role, has in pairs(wire.roles) do
        roles[role] = has
    end
    local clone = {}
    for k, v in pairs(wire) do
        clone[k] = v
    end
    clone.roles = roles
    if wire.mergedColors then
        clone.mergedColors = {}
        for i = 1, #wire.mergedColors do
            clone.mergedColors[i] = wire.mergedColors[i]
        end
    end
    if wire.mergedOffsets then
        clone.mergedOffsets = {}
        for i = 1, #wire.mergedOffsets do
            clone.mergedOffsets[i] = wire.mergedOffsets[i]
        end
    end
    return clone
end

function M.countRoles(wire)
    local count = 0
    for _, has in pairs(wire.roles) do
        if has then
            count = count + 1
        end
    end
    return count
end

function M.getBaseAngle(wire, angles)
    local baseAngles = angles.BASE
    local baseAngle = baseAngles[wire.texId] or 0
    local roleCount = M.countRoles(wire)
    if roleCount >= 3 then
        return angles.MERGED3 or baseAngle
    end
    if roleCount == 2 then
        return angles.MERGED2 or baseAngle
    end
    return baseAngle
end

return M
