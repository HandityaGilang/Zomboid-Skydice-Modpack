-- PK42SkinAction.lua
local SU = require "Utils/PK42SharedUtils"
-- TimedAction: remove a pele do cadáver humano/zumbi.
-- Funciona para corpo no chão (self.corpse) ou no gancho (self.hook).

require "TimedActions/ISBaseTimedAction"

PK42SkinAction = ISBaseTimedAction:derive("PK42SkinAction")

function PK42SkinAction:isValid()
    if self.hook then
        local status = SU.hook_GetStatus(self.hook)
        return status == "Corpse" or status == "CorpseBleeded"
    end
    if not self.corpse or not self.sq then return false end
    return not self.corpse:getModData()["PK42Skinned"]
end

function PK42SkinAction:waitToStart()
    self.character:faceThisObject(self.hook or self.corpse)
    return self.character:shouldBeTurning()
end

function PK42SkinAction:update()
    self.character:faceThisObject(self.hook or self.corpse)
    self.character:setMetabolicTarget(Metabolics.HeavyWork)
end

function PK42SkinAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", self.hook and "Mid" or "Low")
    self.sound = self.character:getEmitter():playSound("Meat_A2")
end

function PK42SkinAction:stop()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopSound(self.sound)
        self.sound = nil
    end
    ISBaseTimedAction.stop(self)
end

function PK42SkinAction:perform()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopSound(self.sound)
        self.sound = nil
    end
    ISBaseTimedAction.perform(self)
end

function PK42SkinAction:complete()
    if self.hook then
        local args = {
            hookX = self.hook:getSquare():getX(),
            hookY = self.hook:getSquare():getY(),
            hookZ = self.hook:getSquare():getZ(),
        }
        if isServer() or not isClient() then
            PK42ServerLogic.SkinCorpseOnHook(self.character, args)
        else
            sendClientCommand(self.character, "PK42", "SkinCorpseOnHook", args)
        end
        return true
    end

    local hv = self.corpse.getHumanVisual and self.corpse:getHumanVisual()
    if hv then
        local skinned = SU.isPlayerCorpse(self.corpse)
            and "M_HumanBody04_Skinned"
            or  "M_ZedBody04_Skinned"
        hv:setSkinTextureName(skinned)
    end

    local args = {
        corpseId       = SU.corpse_GetID(self.corpse),
        corpseX        = self.sq:getX(),
        corpseY        = self.sq:getY(),
        corpseZ        = self.sq:getZ(),
        isPlayerCorpse = SU.isPlayerCorpse(self.corpse),
    }
    if isServer() or not isClient() then
        PK42ServerLogic.SkinCorpse(self.character, args)
    else
        sendClientCommand(self.character, "PK42", "SkinCorpse", args)
    end

    return true
end

function PK42SkinAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    local time = 800
    local butchering = self.character:getPerkLevel(Perks.Butchering)
    if butchering > 0 then time = time - (butchering * 20) end
    if self.character:hasTrait(CharacterTrait.HEMOPHOBIC) then
        time = math.floor(time * 1.30)
    end
    time = math.max(20, time)
    if self.hook then time = math.floor(time / 2) end
    return time
end

-- Para corpo no chão: PK42SkinAction:new(character, corpse, sq)
-- Para gancho:        PK42SkinAction:new(character, nil, nil, hook)
function PK42SkinAction:new(character, corpse, sq, hook)
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