---@class SkateboardCore
Skateboard = Skateboard or {}
Skateboard.Core = Skateboard.Core or {}

local Core = Skateboard.Core

Core.ItemTypePrefix = "Skateboard"
Core.ItemFullType = "Skateboard.Skateboard"
Core.ModOptionsId = "SkateboardMod"
Core.SyncModule = "SkateboardSync"

Core.State = Core.State or {
    isEquipping = false
}

Core.PlayerVars = {
    Active = "SkateboardActive",
    Held = "SkateboardHeld",
    Rolling = "SkateboardRolling",
    RollingTimestamp = "SkateboardRollingTimestamp",
    ToHandPlayed = "SkateboardToHandPlayed",
    IdleToAimPlaying = "IdleToAimPlaying",
    WalkSpeed = "SkateboardWalkSpeed",
    RunSpeed = "SkateboardRunSpeed",
    Speed = "SkateboardSpeed",
    Ollie = "SkateboardOllie",
    OllieStarted = "SkateboardOllieStarted"
}

---@nodiscard
---@param typeString string|nil
---@return boolean
function Core.isSkateboardType(typeString)
    if not typeString then
        return false
    end

    return string.find(typeString, "^Skateboard") ~= nil
end

---@nodiscard
---@param item InventoryItem|nil
---@return boolean
function Core.isSkateboardItem(item)
    if not item then
        return false
    end

    return Core.isSkateboardType(item:getType())
end

---@nodiscard
---@param rawItem InventoryItem|IsoWorldInventoryObject|nil
---@return InventoryItem|nil
function Core.getInventoryItem(rawItem)
    if instanceof(rawItem, "InventoryItem") then
        return rawItem
    end

    if rawItem and rawItem.getItem then
        return rawItem:getItem()
    end

    return nil
end

---@nodiscard
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function Core.getDistance2D(x1, y1, x2, y2)
    local dx = math.abs(x2 - x1)
    local dy = math.abs(y2 - y1)
    return math.sqrt(dx * dx + dy * dy)
end

Core.runAfter = function(seconds, callback, ...)
    local elapsed = 0 --[[@as number]]
    local gameTime = GameTime.getInstance()
    local args = {...}

    local function tick()
        elapsed = elapsed + gameTime:getTimeDelta()
        if elapsed < seconds then
            return
        end

        Events.OnTick.Remove(tick)
        callback(unpack(args))
    end

    Events.OnTick.Add(tick)

    return function()
        Events.OnTick.Remove(tick)
    end
end

---@nodiscard
---@param lastTimestamp number
---@param player IsoPlayer
---@param radius number
---@return number
function Core.throttleAddSound(lastTimestamp, player, radius)
    local now = getTimestampMs()
    if now - lastTimestamp < 2000 then
        return lastTimestamp
    end

    addSound(nil, player:getX(), player:getY(), player:getZ(), radius, radius)
    return now
end

return Core
