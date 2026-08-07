--//////////////////////////////////////////////////--
--    Reactive Sound Events - Scream Scene
--    Handles generation of scream scenes (no firearms)
--//////////////////////////////////////////////////--

local CombatScene = require "ReactiveSE/ReactiveSE_CombatScene"

local ReactiveSE_ScreamScene = {}

---Generates a scream scene (Single Corpse, no firearms, with zombies)
---@param x number
---@param y number
---@param z number
---@param settings table
---@return boolean success, table|nil corpseDataList
function ReactiveSE_ScreamScene.Spawn(x, y, z, settings)
    return CombatScene.Spawn(x, y, z, settings, {
        minCorpses = 1,
        maxCorpses = 1,
        noFirearms = true,
        maxZombies = settings.screamZombieCount or 0
    })
end

return ReactiveSE_ScreamScene
