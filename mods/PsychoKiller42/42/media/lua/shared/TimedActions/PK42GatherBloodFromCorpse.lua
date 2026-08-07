-- PK42GatherBloodFromCorpse.lua
local SU = require "Utils/PK42SharedUtils"
require "TimedActions/ISBaseTimedAction"

PK42GatherBloodFromCorpse = ISBaseTimedAction:derive("PK42GatherBloodFromCorpse")

function PK42GatherBloodFromCorpse:isValid()
    if isClient() then
        if self.started then return true end
        if not ButcheringUtil.isHookUsingSameCharacter(self.hook, self.character) then
            return false
        end
    end
    local qty = tonumber(self.hook:getModData().PK42BloodQty) or 0
    return qty > 0
end

function PK42GatherBloodFromCorpse:waitToStart()
    self.character:faceThisObject(self.hook)
    return self.character:shouldBeTurning()
end

-- Transfere sangue proporcionalmente ao tempo decorrido (dt)
--- @param dt number quantidade de "tempo" (mesma unidade de self.timer) decorrida neste frame.
function PK42GatherBloodFromCorpse:updateBucket(dt)
    local md = self.hook:getModData()
    local qty = tonumber(md.PK42BloodQty) or 0
    if qty <= 0 or not self.bucket then return end

    local fluidName = md.PK42IsPlayerCorpse and "HumanBlood" or "ZombieBlood"

    -- Taxa de coleta: literPerTick litros a cada timePerLiter unidades de timer.
    local rate = self.literPerTick / self.timePerLiter
    local rest = math.min(qty, (dt or self.timePerLiter) * rate)
    if rest <= 0 then return end

    if ZombRand(20 + (self.perkLevel * 3)) then
        self.character:addBlood(nil, true, false, false)
        syncVisuals(self.character)
    end

    self.bucket:getFluidContainer():addFluid(fluidName, rest)
    self.bucket:sendSyncEntity(nil)

    md.PK42BloodQty = math.max(0, qty - rest)
    self.hook:transmitModData()

    if md.PK42BloodQty <= 0 then
        md.PK42BloodQty = 0
        if self.bucket then self.bucket:setJobDelta(0.0) end
        -- Grava PK42HookStatus para que o render() do painel exiba o PNG correto.
        local newStatus = md.PK42IsSkinned and "SkinnedBleeded" or "CorpseBleeded"
        md.PK42HookStatus = newStatus
        self.hook:transmitModData()
        SU.hook_SwapSprite(self.hook, newStatus)
        self.hook:sync()
    end

    if self.bucket:getFluidContainer():isFull() then
        if self.bucket then self.bucket:setJobDelta(0.0) end
        self.bucket = self.character:getInventory():getFirstAvailableFluidContainer(fluidName)
    end

    if not self.bucket or (tonumber(md.PK42BloodQty) or 0) <= 0 then
        if isServer() then
            self.netAction:forceComplete()
        else
            self:forceStop()
        end
        return
    end
end

function PK42GatherBloodFromCorpse:update()
    self.character:faceThisObject(self.hook)

    if self.bucket then
        self.bucket:setJobDelta(self:getJobDelta())
    end

    if not isClient() then
        local dt = getGameTime():getMultiplier()
        self.timer = self.timer + dt -- fix
        self:updateBucket(dt)
    end

    if self.luaHook then
        self.luaHook.doingAction = true
        self.luaHook.actionText  = getText("IGUI_Animal_GatheringBlood")
        self.luaHook:updateProgressBar(self:getJobDelta())
    end
end

function PK42GatherBloodFromCorpse:serverStart()
    if not self.hook:getUsingPlayer() then
        ButcheringUtil.setUsingPlayerForHook(self.hook, self.character)
    end
    local period = self.timePerLiter * 20
    emulateAnimEvent(self.netAction, period, "update", nil)
end

function PK42GatherBloodFromCorpse:serverStop()
    if ButcheringUtil.isHookUsingSameCharacter(self.hook, self.character) then
        ButcheringUtil.setUsingPlayerForHook(self.hook, nil)
    end
end

function PK42GatherBloodFromCorpse:animEvent(event, parameter)
    -- Fallback redundante (na prática raramente dispara, já que "period" costuma
    -- exceder a duração da ação). Passa um tick cheio caso chegue a disparar.
    if isServer() and event == "update" then
        self:updateBucket(self.timePerLiter)
    end
end

function PK42GatherBloodFromCorpse:start()
    self:setActionAnim("Loot")
    self.character:reportEvent("EventLootItem")
    if self.bucket then
        self.bucket:setJobType(getText("IGUI_Animal_GatheringBlood"))
    end
    if self.luaHook then
        self.luaHook.hook:setPlayRemovingBloodSound(true)
    end
    self.maxTime = self:getDuration()
    self.started = true
end

function PK42GatherBloodFromCorpse:forceStop()
    if self.luaHook then
        self.luaHook.hook:setPlayRemovingBloodSound(false)
        self.luaHook.doingAction = false
    end
    if self.bucket then self.bucket:setJobDelta(0.0) end
    ISBaseTimedAction.stop(self)
end

function PK42GatherBloodFromCorpse:stop()
    if self.luaHook then
        self.luaHook.hook:setPlayRemovingBloodSound(false)
        self.luaHook.doingAction = false
    end
    if self.bucket then self.bucket:setJobDelta(0.0) end
    ISBaseTimedAction.stop(self)
end

function PK42GatherBloodFromCorpse:perform()
    if self.luaHook then
        self.luaHook.doingAction = false
        self.luaHook:pkUpdateButtons()
    end
    if self.bucket then self.bucket:setJobDelta(0.0) end
    ISBaseTimedAction.perform(self)
end

function PK42GatherBloodFromCorpse:complete()
    if isClient() and not ButcheringUtil.isHookUsingSameCharacter(self.hook, self.character) then
        return false
    end

    -- garante que qualquer resto de sangue ainda não processado seja transferido ao concluir a ação normalmente
    -- (evita perda residual por arredondamento ou por a ação terminar bem no limite).
    if not isClient() and self.bucket then
        local qtyRestante = tonumber(self.hook:getModData().PK42BloodQty) or 0
        if qtyRestante > 0 then
            self:updateBucket(qtyRestante * self.timePerLiter / self.literPerTick)
        end
    end

    if self.luaHook then
        self.luaHook.doingAction = false
        self.luaHook:pkUpdateButtons()
    end
    if self.bucket then self.bucket:setJobDelta(0.0) end
    ButcheringUtil.setUsingPlayerForHook(self.hook, nil)
    return true
end

function PK42GatherBloodFromCorpse:getDuration()
    local md    = self.hook:getModData()
    local blood = tonumber(md.PK42BloodQty) or 0

    local totalSpace = 0
    local items = self.character:getInventory():getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local fc   = item.getFluidContainer and item:getFluidContainer()
        if fc and not fc:isFull() then
            if fc:isEmpty() then
                totalSpace = totalSpace + fc:getCapacity()
            else
                local primary = fc:getPrimaryFluid()
                if primary then
                    local name = primary:getFluidTypeString()
                    if name == "HumanBlood" or name == "ZombieBlood" then
                        totalSpace = totalSpace + (fc:getCapacity() - fc:getAmount())
                    end
                end
            end
        end
    end

    local amountToGet = math.min(blood, totalSpace)
    return 2 + (amountToGet * self.timePerLiter * (1 / self.literPerTick))
end

function PK42GatherBloodFromCorpse:new(character, hook, luaHookUI, bucket)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self

    o.character    = character
    o.hook         = hook
    o.luaHook      = luaHookUI
    o.bucket       = bucket
    o.timePerLiter = 30
    o.literPerTick = 0.5
    o.timer        = 0
    o.lastTimer    = 0
    o.perkLevel    = character:getPerkLevel(Perks.Butchering)
    o.started      = false
    o.stopOnWalk   = true
    o.stopOnRun    = true
    o.maxTime      = o:getDuration()

    return o
end