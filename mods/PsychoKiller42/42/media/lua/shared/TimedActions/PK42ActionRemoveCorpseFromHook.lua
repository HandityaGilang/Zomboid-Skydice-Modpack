-- PK42ActionRemoveCorpseFromHook.lua
local SU = require "Utils/PK42SharedUtils"
-- TimedAction: remove o corpo do gancho.
-- Servidor recria o IsoDeadBody no square com o estado correto.

require "TimedActions/ISBaseTimedAction"

PK42ActionRemoveCorpseFromHook = ISBaseTimedAction:derive("PK42ActionRemoveCorpseFromHook")

function PK42ActionRemoveCorpseFromHook:isValid()
    if not self.hook then return false end
    return SU.hook_GetStatus(self.hook) ~= "Empty"
end

function PK42ActionRemoveCorpseFromHook:waitToStart()
    self.character:faceThisObject(self.hook)
    return self.character:shouldBeTurning()
end

function PK42ActionRemoveCorpseFromHook:update()
    self.character:faceThisObject(self.hook)
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function PK42ActionRemoveCorpseFromHook:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Mid")
    self.sound = self.character:playSound("ButcheringRemoveCorpse")
end

function PK42ActionRemoveCorpseFromHook:stop()
    if self.sound then
        self.character:stopOrTriggerSound(self.sound)
    end
    ISBaseTimedAction.stop(self)
end

function PK42ActionRemoveCorpseFromHook:perform()
    if self.sound then
        self.character:stopOrTriggerSound(self.sound)
    end
    ISBaseTimedAction.perform(self)
end

function PK42ActionRemoveCorpseFromHook:complete()
    sendClientCommand(
        self.character,
        "PK42",
        "RemoveCorpseFromHook",
        {
            hookX = self.hook:getSquare():getX(),
            hookY = self.hook:getSquare():getY(),
            hookZ = self.hook:getSquare():getZ(),
        }
    )
    return true
end

function PK42ActionRemoveCorpseFromHook:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    local time = 200 - (self.character:getPerkLevel(Perks.Butchering) * 10)
    return math.max(40, time)
end

function PK42ActionRemoveCorpseFromHook:new(character, hook)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self

    o.character  = character
    o.hook       = hook
    o.stopOnWalk = true
    o.stopOnRun  = true
    o.maxTime    = o:getDuration()

    return o
end