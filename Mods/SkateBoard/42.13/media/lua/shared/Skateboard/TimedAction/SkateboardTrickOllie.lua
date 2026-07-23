require("TimedActions/ISBaseTimedAction")
require("Skateboard/SkateboardCore")
require("Skateboard/SkateboardOptions")

SkateboardTrickOllie = ISBaseTimedAction:derive("SkateboardTrickOllie")

local Core = Skateboard.Core

---@param player IsoPlayer
---@param force boolean|nil
---@return nil
local function syncOllieState(player, force)
    if isClient() and Skateboard and Skateboard.Client and Skateboard.Client.syncState then
        Skateboard.Client.syncState(player, force)
    end
end

---@return boolean
function SkateboardTrickOllie:isValid()
    return true
end

---@return boolean
function SkateboardTrickOllie:waitToStart()
    return false
end

---@return nil
function SkateboardTrickOllie:update()
end

---@return nil
function SkateboardTrickOllie:start()
    self.character:setVariable(Core.PlayerVars.OllieStarted, "true")
    syncOllieState(self.character, true)
    Skateboard.Client.updateOllieSounds(self.character)
end

---@return nil
function SkateboardTrickOllie:stop()
end

---@return nil
function SkateboardTrickOllie:perform()
    ISBaseTimedAction.perform(self)
end

---@return nil
function SkateboardTrickOllie:complete()
end

---@param player IsoPlayer
---@return SkateboardTrickOllie
function SkateboardTrickOllie:new(player)
    local o = ISBaseTimedAction.new(self, player)
    o.maxTime = o:getDuration()
    o.character = player
    o.stopOnWalk = false
    o.stopOnRun = false
    o.useProgressBar = false

    o.character:setVariable(Core.PlayerVars.Ollie, "true")
    o.character:setVariable(Core.PlayerVars.OllieStarted, "false")

    return o
end

---@return number
function SkateboardTrickOllie:getDuration()
    if self.character:isTimedActionInstant() then
        return 1
    end

    return 1
end

return SkateboardTrickOllie
