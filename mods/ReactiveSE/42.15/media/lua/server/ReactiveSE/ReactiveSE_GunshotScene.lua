--//////////////////////////////////////////////////--
--    Reactive Sound Events - Gunshot Scene (Single)
--    Handles generation of a single corpse scene (Gunshot event)
--    Delegates to ReactiveSE_CombatScene
--//////////////////////////////////////////////////--

local CombatScene = require "ReactiveSE/ReactiveSE_CombatScene"

local ReactiveSE_GunshotScene = {}

---Generates a simple gunshot scene (Single Corpse)
---@param x number
---@param y number
---@param z number
---@param settings table
---@return boolean success, table|nil corpseDataList
function ReactiveSE_GunshotScene.Spawn(x, y, z, settings)
    return CombatScene.Spawn(x, y, z, settings, {
        minCorpses = 1,
        maxCorpses = 1,
        stealChanceMod = 0.5
    })
end

return ReactiveSE_GunshotScene
