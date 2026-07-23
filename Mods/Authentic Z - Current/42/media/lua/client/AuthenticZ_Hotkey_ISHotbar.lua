--This file is dedicated towards adding new keyBindings for the hotbar slots
require "Hotbar/ISHotbar"
require "ISUI/ISPanelJoypad"

if ISHotbar then
    function ISHotbar:getSlotForKey(key)
        if not getCore then
            return -1
        end

        local core = getCore()
        if not core then
            return -1
        end

        for slot = 1, 20 do
            if core:isKey("Hotbar " .. tostring(slot), key) then
                return slot
            end
        end

        return -1
    end
end

local existingBindings = {}

if keyBinding then
    for _, bind in ipairs(keyBinding) do
        if bind and bind.value then
            existingBindings[bind.value] = true
        end
    end
end

local function addBinding(value, key)
    if not keyBinding or not value or existingBindings[value] then
        return
    end
    table.insert(keyBinding, { value = value, key = key })
    existingBindings[value] = true
end

addBinding("[SlingBindings]")

if Keyboard then
    addBinding("Hotbar 9", Keyboard.KEY_9)
    addBinding("Hotbar 10", Keyboard.KEY_0)
else
    addBinding("Hotbar 9", 10)
    addBinding("Hotbar 10", 11)
end

addBinding("Hotbar 11", 65)
addBinding("Hotbar 12", 66)
addBinding("Hotbar 13", 67)
addBinding("Hotbar 14", 68)
addBinding("Hotbar 15", 69)
addBinding("Hotbar 16", 70)
addBinding("Hotbar 17", 71)
addBinding("Hotbar 18", 72)
addBinding("Hotbar 19", 73)
addBinding("Hotbar 20", 74)
