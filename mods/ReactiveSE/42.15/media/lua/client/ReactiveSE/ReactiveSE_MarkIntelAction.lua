---@diagnostic disable: undefined-field, inject-field, param-type-mismatch, return-type-mismatch
--//////////////////////////////////////////////////--
--    Reactive Sound Events - Mark Intel Action
--    Timed action for marking radio intel on map
--//////////////////////////////////////////////////--

require "TimedActions/ISBaseTimedAction"
local RadioMarkers = require "ReactiveSE/ReactiveSE_RadioMarkers"

---@class ReactiveSE_MarkIntelAction : ISBaseTimedAction
---@field pen InventoryItem
---@field sceneX number
---@field sceneY number
---@field sceneID string
---@field sceneType string|nil
local ReactiveSE_MarkIntelAction = ISBaseTimedAction:derive("ReactiveSE_MarkIntelAction")

--//////////////////////////////////////////////////--
--          Constants                              --
--//////////////////////////////////////////////////--

local ACTION_TIME = 100 -- Ticks (~3-4 seconds)

--//////////////////////////////////////////////////--
--          Constructor                            --
--//////////////////////////////////////////////////--

---Creates a new mark intel action
---@param character IsoPlayer The player performing the action
---@param pen InventoryItem The writing tool to use
---@param sceneX number World X coordinate
---@param sceneY number World Y coordinate
---@param sceneID string Scene identifier
---@param sceneType string|nil Scene type (e.g., "Gunfight", "Zombie")
---@return ReactiveSE_MarkIntelAction
function ReactiveSE_MarkIntelAction:new(character, pen, sceneX, sceneY, sceneID, sceneType)
    local o = ISBaseTimedAction.new(self, character)
    o.pen = pen
    o.sceneX = sceneX
    o.sceneY = sceneY
    o.sceneID = sceneID
    o.sceneType = sceneType
    o.maxTime = ACTION_TIME
    o.stopOnWalk = true
    o.stopOnRun = true
    return o
end

--//////////////////////////////////////////////////--
--          Action Lifecycle                       --
--//////////////////////////////////////////////////--

function ReactiveSE_MarkIntelAction:isValid()
    return self.character:getInventory():contains(self.pen)
end

function ReactiveSE_MarkIntelAction:start()
    self:setOverrideHandModelsString(nil, "Base.Map", true)
    self:setActionAnim(CharacterActionAnims.Read)
    self:setAnimVariable("PerformingAction", "read")
    self:setAnimVariable("ReadType", "photo")
end

function ReactiveSE_MarkIntelAction:stop()
    self:restoreWeaponType()
    ISBaseTimedAction.stop(self)
end

function ReactiveSE_MarkIntelAction:perform()
    self:restoreWeaponType()

    getSoundManager():playUISound("MapAddNote")

    RadioMarkers.CreateMapSymbol(self.sceneX, self.sceneY, self.sceneID, self.sceneType)

    -- Complete action
    ISBaseTimedAction.perform(self)
end

return ReactiveSE_MarkIntelAction
