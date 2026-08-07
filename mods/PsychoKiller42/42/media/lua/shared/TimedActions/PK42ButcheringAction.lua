-- PK42ButcheringAction.lua
local SU = require "Utils/PK42SharedUtils"
-- TimedAction: esquarteja cadáver humano/zumbi.
-- Funciona para corpo no chão (self.corpse) ou no gancho (self.hook).

require "TimedActions/ISBaseTimedAction"

PK42ButcheringAction = ISBaseTimedAction:derive("PK42ButcheringAction")

function PK42ButcheringAction:isValid()
    if self.hook then
        local status = SU.hook_GetStatus(self.hook)
        return status == "Corpse"        or status == "Skinned"
            or status == "CorpseBleeded" or status == "SkinnedBleeded"
    end
    return self.corpse ~= nil and self.sq ~= nil
end

function PK42ButcheringAction:waitToStart()
    self.character:faceThisObject(self.hook or self.corpse)
    return self.character:shouldBeTurning()
end

function PK42ButcheringAction:update()
    self.character:faceThisObject(self.hook or self.corpse)
    self.character:setMetabolicTarget(Metabolics.HeavyWork)
end

function PK42ButcheringAction:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", self.hook and "Mid" or "Low")
    self.sound = self.character:getEmitter():playSound("Meat_A2")
end

function PK42ButcheringAction:stop()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopSound(self.sound)
        self.sound = nil
    end
    ISBaseTimedAction.stop(self)
end

function PK42ButcheringAction:perform()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        self.character:getEmitter():stopSound(self.sound)
        self.sound = nil
    end
    ISBaseTimedAction.perform(self)
end

function PK42ButcheringAction:complete()
    if self.hook then
        local args = {
            hookX = self.hook:getSquare():getX(),
            hookY = self.hook:getSquare():getY(),
            hookZ = self.hook:getSquare():getZ(),
        }
        
        if isServer() or not isClient() then
            PK42ServerLogic.ButcherCorpseOnHook(self.character, args)
        else
            sendClientCommand(self.character, "PK42", "ButcherCorpseOnHook", args)
        end
        return true
    end


    -- isZombie para fins de ossos só é zumbi se NÃO for humano/NPC.
    local isPlayerCorpse = SU.isPlayerCorpse(self.corpse)
    local args = {
        corpseId       = SU.corpse_GetID(self.corpse),
        corpseX        = self.sq:getX(),
        corpseY        = self.sq:getY(),
        corpseZ        = self.sq:getZ(),
        isPlayerCorpse = isPlayerCorpse,
        isZombie       = not isPlayerCorpse,
    }

    if isServer() or not isClient() then
        PK42ServerLogic.ButcherCorpse(self.character, args)
    else
        sendClientCommand(self.character, "PK42", "ButcherCorpse", args)
    end

    return true
end

function PK42ButcheringAction:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    local time = 900
    local butchering = self.character:getPerkLevel(Perks.Butchering)
    if butchering > 0 then time = time - (butchering * 20) end
    if self.character:hasTrait(CharacterTrait.HEMOPHOBIC) then
        time = math.floor(time * 1.30)
    end
    time = math.max(30, time)
    if self.hook then time = math.floor(time / 2) end
    return time
end

-- Para corpo no chão: PK42ButcheringAction:new(character, corpse, sq)
-- Para gancho:        PK42ButcheringAction:new(character, nil, nil, hook)
function PK42ButcheringAction:new(character, corpse, sq, hook)
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