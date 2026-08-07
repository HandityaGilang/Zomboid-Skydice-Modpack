-- PK42ActionPutCorpseOnHook.lua
-- TimedAction: coloca um IsoDeadBody no gancho PK42.
-- Remove o corpo do mundo e envia ao servidor para trocar o sprite.

local SU = require "Utils/PK42SharedUtils"
require "TimedActions/ISBaseTimedAction"

PK42ActionPutCorpseOnHook = ISBaseTimedAction:derive("PK42ActionPutCorpseOnHook")

function PK42ActionPutCorpseOnHook:isValid()
    if not self.corpse or not self.hook then return false end
    return SU.hook_GetStatus(self.hook) == "Empty"
end

function PK42ActionPutCorpseOnHook:waitToStart()
    self.character:faceThisObject(self.hook)
    return self.character:shouldBeTurning()
end

function PK42ActionPutCorpseOnHook:update()
    self.character:faceThisObject(self.hook)
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function PK42ActionPutCorpseOnHook:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Mid")
    self.sound = self.character:playSound("ButcheringAddCorpse")
end

function PK42ActionPutCorpseOnHook:stop()
    if self.sound then
        self.character:stopOrTriggerSound(self.sound)
    end
    ISBaseTimedAction.stop(self)
end

function PK42ActionPutCorpseOnHook:perform()
    if self.sound then
        self.character:stopOrTriggerSound(self.sound)
    end
    ISBaseTimedAction.perform(self)
end

function PK42ActionPutCorpseOnHook:complete()
    local corpseSq = self.corpse:getSquare()

    local objectIDAsLong = nil
    if self.corpse.getObjectIDAsLong then
        local ok, id = pcall(function() return self.corpse:getObjectIDAsLong() end)
        if ok then objectIDAsLong = id end
    end

    local md = {}
    if self.corpse.getModData then
        local ok, data = pcall(function() return self.corpse:getModData() end)
        if ok and data then md = data end
    end

    local okS, isSkeleton = pcall(function() return self.corpse:isSkeleton() end)

    -- SU.isPlayerCorpse() checa a textura de skin: detecta NPCs humanos (Bandits)
    local isPlayerCorpse = SU.isPlayerCorpse(self.corpse)
    local skeleton       = okS and isSkeleton or false
    local skinned        = md["PK42Skinned"] == true
    local bleeded        = (tonumber(md["BloodQty"]) or 2.5) <= 0

    local initialStatus
    if skeleton then
        initialStatus = "Skeleton"
    elseif skinned then
        initialStatus = bleeded and "SkinnedBleeded" or "Skinned"
    else
        initialStatus = bleeded and "CorpseBleeded"  or "Corpse"
    end
    
    local deathTime = nil
    if self.corpse.getDeathTime then
        local ok, t = pcall(function() return self.corpse:getDeathTime() end)
        if ok and t then deathTime = t end
    end
    deathTime = deathTime or md["deathTime"] or getGameTime():getWorldAgeHours()

    sendClientCommand(
        self.character,
        "PK42",
        "PutCorpseOnHook",
        {
            objectIDAsLong = objectIDAsLong,
            corpseX        = corpseSq and corpseSq:getX() or 0,
            corpseY        = corpseSq and corpseSq:getY() or 0,
            corpseZ        = corpseSq and corpseSq:getZ() or 0,
            hookX          = self.hook:getSquare():getX(),
            hookY          = self.hook:getSquare():getY(),
            hookZ          = self.hook:getSquare():getZ(),
            initialStatus  = initialStatus,
            isPlayerCorpse = isPlayerCorpse,
            isZombie       = not isPlayerCorpse,
            isSkeleton     = skeleton,
            isSkinned      = skinned,
            deathTime      = deathTime,
            bloodQty       = md["BloodQty"] or 2.5,
            meatRatio      = md["meatRatio"] or 1.0,
            deathAge       = md["deathAge"] or 0,
            rotStage       = md["animalRotStage"] or 0,
        }
    )

    return true
end

function PK42ActionPutCorpseOnHook:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    local time = 300 - (self.character:getPerkLevel(Perks.Butchering) * 10)
    return math.max(40, time)
end

function PK42ActionPutCorpseOnHook:new(character, corpse, hook)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self

    o.character  = character
    o.corpse     = corpse
    o.hook       = hook
    o.stopOnWalk = true
    o.stopOnRun  = true
    o.maxTime    = o:getDuration()

    return o
end