--//////////////////////////////////////////////////--
--    Reactive Sound Events - Gunfight Scene
--    Handles generation of gunfight scenes
--    Delegates to ReactiveSE_CombatScene
--//////////////////////////////////////////////////--

local CombatScene = require "ReactiveSE/ReactiveSE_CombatScene"

local ReactiveSE_GunfightScene = {}

---Generates a detailed gunfight scene
---@param x number
---@param y number
---@param z number
---@param settings table
---@return boolean success, table|nil corpseDataList
function ReactiveSE_GunfightScene.Spawn(x, y, z, settings)
    return CombatScene.Spawn(x, y, z, settings, {
        minCorpses = 2,
        maxCorpses = settings.corpseCount
    })
end

return ReactiveSE_GunfightScene
