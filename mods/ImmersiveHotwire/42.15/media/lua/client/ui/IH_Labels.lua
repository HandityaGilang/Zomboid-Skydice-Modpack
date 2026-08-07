local RenderConfig = require "render/IH_RenderConfig"
local Config = require "config/IH_Config"
local Utils = require "util/IH_Utils"

local TEXT = RenderConfig.getTextTable()
local ROLE_LABELS = TEXT.ROLE_LABELS
local ROLES = Config.ROLES
local KEY_FORMAT_ACTION_BATTERY_WIRE = "IGUI_IH_Format_Action_Battery_Wire"
local KEY_FORMAT_ACTION_WIRE_POSSIBLY = "IGUI_IH_Format_Action_Wire_Possibly"
local KEY_FORMAT_ACTION_WIRE_LABELED = "IGUI_IH_Format_Action_Wire_Labeled"

local Labels = {}

function Labels.buildRoleLabelMap(self, seed)
    local level = self.mechanicsLevel or 0
    local map = {}
    if level <= 0 then
        return map
    end
    local count = (seed % 2) + 3
    local includeAccessory = count == 4

    local function addRoles(source)
        for _, role in ipairs(source) do
            map[role] = ROLE_LABELS[role]
        end
    end

    if level >= 2 then
        addRoles(ROLES.BASE)
        if includeAccessory then
            addRoles(ROLES.EXTRA)
        end
        return map
    end

    map.battery = ROLE_LABELS.battery
    local roles = {}
    for _, role in ipairs(ROLES.BASE) do
        if role ~= "battery" then
            roles[#roles + 1] = role
        end
    end
    if includeAccessory then
        for _, role in ipairs(ROLES.EXTRA) do
            if role ~= "battery" then
                roles[#roles + 1] = role
            end
        end
    end
    local shuffled = {}
    for i = 1, #roles do
        shuffled[i] = roles[i]
    end
    Utils.shuffle(shuffled, seed + 111)
    for i = 1, #roles do
        map[roles[i]] = ROLE_LABELS[shuffled[i]]
    end
    return map
end

function Labels.buildRoleLabel(self, roles)
    local order = ROLES.LABEL_ORDER
    local parts = {}
    local map = self.roleLabelMap
    local level = self.mechanicsLevel or 0
    for _, role in ipairs(order) do
        if roles[role] then
            local displayRole = map[role]
            if displayRole then
                local label = displayRole:gsub("^%l", string.upper)
                if level == 1 and role ~= "battery" then
                    label = TEXT.LABEL_POSSIBLY_PREFIX .. label
                end
                table.insert(parts, label)
            end
        end
    end
    return Utils.joinWithAnd(parts, TEXT.LABEL_SEP_MIDDLE, TEXT.LABEL_SEP_LAST)
end

function Labels.formatWireLabel(self, roles)
    local label = self:buildRoleLabel(roles)
    return label ~= "" and label or nil
end

local function formatActionText(key, action, suffix)
    if suffix ~= nil then
        return getText(key, action, suffix)
    end
    return getText(key, action)
end

function Labels.formatWireAction(self, action, wire)
    local level = self.mechanicsLevel or 0
    if level <= 0 then
        return action
    end

    local label = self:buildRoleLabel(wire.roles)
    if label == "" then
        return action
    end

    local labelLower = label:lower()
    if level == 1 then
        local hasBattery = wire.roles.battery == true
        local order = ROLES.LABEL_ORDER
        local map = self.roleLabelMap
        local possibleParts = {}
        local rawParts = {}
        for _, role in ipairs(order) do
            if role ~= "battery" and wire.roles[role] then
                local displayRole = map[role] or role
                local lower = displayRole:lower()
                rawParts[#rawParts + 1] = lower
                possibleParts[#possibleParts + 1] = TEXT.LABEL_POSSIBLY_PREFIX .. lower
            end
        end
        if hasBattery then
            if #possibleParts == 0 then
                return formatActionText(KEY_FORMAT_ACTION_BATTERY_WIRE, action)
            end
            local parts = { ROLE_LABELS.battery }
            for i = 1, #possibleParts do
                parts[#parts + 1] = possibleParts[i]
            end
            local suffix = Utils.joinWithAnd(parts, TEXT.LABEL_SEP_MIDDLE, TEXT.LABEL_SEP_LAST)
            return formatActionText(KEY_FORMAT_ACTION_WIRE_LABELED, action, suffix)
        end
        if #rawParts == 1 then
            return formatActionText(KEY_FORMAT_ACTION_WIRE_POSSIBLY, action, rawParts[1])
        end
        local suffix = Utils.joinWithAnd(possibleParts, TEXT.LABEL_SEP_MIDDLE, TEXT.LABEL_SEP_LAST)
        return formatActionText(KEY_FORMAT_ACTION_WIRE_LABELED, action, suffix)
    end
    return formatActionText(KEY_FORMAT_ACTION_WIRE_LABELED, action, labelLower)
end

return Labels
