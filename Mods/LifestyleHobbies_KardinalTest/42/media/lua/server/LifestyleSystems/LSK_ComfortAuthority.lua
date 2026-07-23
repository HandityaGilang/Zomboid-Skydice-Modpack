require "LifestyleSystems/LSK_SystemDefinitions"

LifestyleSecure = LifestyleSecure or {}
local Comfort = {}
local Defs = LifestyleSecure.SystemDefinitions
local Limits = Defs.Comfort

function Comfort.sanitizeState(data)
    data = type(data) == "table" and data or {}
    return {
        need = Defs.clamp(data.need, Limits.needMin, Limits.needMax) or Limits.needMin,
        value = Defs.clamp(data.value, Limits.needMin, Limits.needMax) or Limits.needMin,
        bedQuality = Defs.clamp(data.bedQuality, 0, 100) or 0,
    }
end

function Comfort.setState(player, data)
    local state = Defs.systemState(player, "Comfort")
    if not state then
        return false, "invalid_player"
    end
    state.comfort = Comfort.sanitizeState(data)
    return true, state.comfort
end

local function ownsItemType(player, fullType)
    fullType = Defs.identifier(fullType)
    if not player or not fullType then
        return false, nil
    end
    if player.getWornItems then
        local worn = player:getWornItems()
        if worn then
            for i = 0, worn:size() - 1 do
                local wornItem = worn:get(i)
                local item = wornItem and wornItem.getItem and wornItem:getItem() or nil
                if item and item.getFullType and item:getFullType() == fullType then
                    return true, item
                end
            end
        end
    end
    local inventory = player.getInventory and player:getInventory() or nil
    if not inventory then
        return false, nil
    end
    local items = inventory:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item.getFullType and item:getFullType() == fullType then
            return true, item
        end
    end
    return false, nil
end

function Comfort.validatePreset(player, presetName, itemTypes)
    if not Limits.presetNames[presetName] or type(itemTypes) ~= "table"
        or #itemTypes > Limits.maxPresetItems then
        return false, "invalid_preset"
    end
    local result = {}
    local seen = {}
    for i = 1, #itemTypes do
        local fullType = Defs.identifier(tostring(itemTypes[i] or ""))
        if not fullType or seen[fullType] then
            return false, "invalid_item_type"
        end
        local owned = ownsItemType(player, fullType)
        if not owned then
            return false, "item_not_owned"
        end
        seen[fullType] = true
        result[#result + 1] = fullType
    end
    return true, result
end

function Comfort.savePreset(player, presetName, itemTypes)
    local valid, result = Comfort.validatePreset(player, presetName, itemTypes)
    if not valid then
        return false, result
    end
    local state = Defs.systemState(player, "Comfort")
    state.wardrobe = type(state.wardrobe) == "table" and state.wardrobe or {}
    state.wardrobe[presetName] = result
    return true, result
end

function Comfort.resolvePreset(player, presetName)
    if not Limits.presetNames[presetName] then
        return false, "invalid_preset"
    end
    local state = Defs.systemState(player, "Comfort")
    local stored = state and state.wardrobe and state.wardrobe[presetName] or {}
    local validTypes = {}
    local items = {}
    for i = 1, math.min(#stored, Limits.maxPresetItems) do
        local owned, item = ownsItemType(player, stored[i])
        if owned then
            validTypes[#validTypes + 1] = stored[i]
            items[#items + 1] = item
        end
    end
    state.wardrobe = type(state.wardrobe) == "table" and state.wardrobe or {}
    state.wardrobe[presetName] = validTypes
    return true, items
end

return Comfort
