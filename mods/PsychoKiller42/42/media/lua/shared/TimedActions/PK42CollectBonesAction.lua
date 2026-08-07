-- PK42CollectBonesAction.lua
-- TimedAction: coleta ossos de um skeleton humano.
-- Funciona para corpo no chão (self.corpse) ou no gancho (self.hook).

local SU = require "Utils/PK42SharedUtils"

require "TimedActions/ISBaseTimedAction"

PK42CollectBonesAction = ISBaseTimedAction:derive("PK42CollectBonesAction")

function PK42CollectBonesAction:isValid()
    if self.hook then
        return SU.hook_GetStatus(self.hook) == "Skeleton"
    end
    if not self.corpse or not self.sq then return false end
    local ok, isSkeleton = pcall(function() return self.corpse:isSkeleton() end)
    return ok and isSkeleton
end

function PK42CollectBonesAction:waitToStart()
    self.character:faceThisObject(self.hook or self.corpse)
    return self.character:shouldBeTurning()
end

function PK42CollectBonesAction:update()
    self.character:faceThisObject(self.hook or self.corpse)
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function PK42CollectBonesAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", self.hook and "Mid" or "Low")
    self.sound = self.character:getEmitter():playSound("PZ_InventoryMove")
end

function PK42CollectBonesAction:stop()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopSound(self.sound)
        self.sound = nil
    end
    ISBaseTimedAction.stop(self)
end

function PK42CollectBonesAction:perform()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopSound(self.sound)
        self.sound = nil
    end
    ISBaseTimedAction.perform(self)
end

function PK42CollectBonesAction:complete()
    if self.hook then
        sendClientCommand(self.character, "PK42", "CollectBonesOnHook", {
            hookX = self.hook:getSquare():getX(),
            hookY = self.hook:getSquare():getY(),
            hookZ = self.hook:getSquare():getZ(),
        })
        return true
    end

    --local corpMd     = self.corpse:getModData()
    local isPlayerCorpse = SU.isPlayerCorpse(self.corpse)

    sendClientCommand(self.character, "PK42", "CollectBones", {
        corpseId       = SU.corpse_GetID(self.corpse),
        corpseX        = self.sq:getX(),
        corpseY        = self.sq:getY(),
        corpseZ        = self.sq:getZ(),
        isPlayerCorpse = isPlayerCorpse,
    })

    return true
end

function PK42CollectBonesAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    local time = 300
    local butchering = self.character:getPerkLevel(Perks.Butchering)
    if butchering > 0 then time = time - (butchering * 10) end
    time = math.max(20, time)
    if self.hook then time = math.floor(time / 2) end
    return time
end

-- Para corpo no chão: PK42CollectBonesAction:new(character, corpse, sq)
-- Para gancho:        PK42CollectBonesAction:new(character, nil, nil, hook)
function PK42CollectBonesAction:new(character, corpse, sq, hook)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self

    o.character  = character
    o.corpse     = corpse
    o.sq         = sq
    o.hook       = hook
    o.stopOnWalk = true
    o.stopOnRun  = true
    o.maxTime    = o:getDuration()

    return o
end