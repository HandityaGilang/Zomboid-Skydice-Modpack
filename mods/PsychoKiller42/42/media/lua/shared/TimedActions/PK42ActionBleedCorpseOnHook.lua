-- PK42ActionBleedCorpseOnHook.lua
-- Equivalente ao ISCutAnimalOnHook, mas para IsoDeadBody humano no gancho.

require "TimedActions/ISBaseTimedAction"

PK42ActionBleedCorpseOnHook = ISBaseTimedAction:derive("PK42ActionBleedCorpseOnHook")

function PK42ActionBleedCorpseOnHook:isValid()
    if not self.hook then return false end
    -- Em multiplayer cliente, aguarda lock do gancho (igual ISCutAnimalOnHook)
    if isClient() and not ButcheringUtil.isHookUsingSameCharacter(self.hook, self.character) then
        return false
    end
    local md = self.hook:getModData()
    return (tonumber(md.PK42BloodQty) or 0) > 0
end

function PK42ActionBleedCorpseOnHook:waitToStart()
    self.character:faceThisObject(self.hook)
    return self.character:shouldBeTurning()
end

function PK42ActionBleedCorpseOnHook:update()
    self.character:faceThisObject(self.hook)
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function PK42ActionBleedCorpseOnHook:serverStart()
    if not self.hook:getUsingPlayer() then
        ButcheringUtil.setUsingPlayerForHook(self.hook, self.character)
    end
end

function PK42ActionBleedCorpseOnHook:serverStop()
    if ButcheringUtil.isHookUsingSameCharacter(self.hook, self.character) then
        ButcheringUtil.setUsingPlayerForHook(self.hook, nil)
    end
end

function PK42ActionBleedCorpseOnHook:start()
    self:setActionAnim("Loot")
    self.character:SetVariable("LootPosition", "Mid")
    self.character:reportEvent("EventLootItem")
    -- Som de sangramento (mesmo som do vanilla)
    self.hook:setPlayRemovingBloodSound(true)
    self.hook:setLuaHook(self.luaHook)
end

function PK42ActionBleedCorpseOnHook:stop()
    self.hook:setPlayRemovingBloodSound(false)
    ISBaseTimedAction.stop(self)
end

function PK42ActionBleedCorpseOnHook:perform()
    self.hook:setPlayRemovingBloodSound(false)
    ISBaseTimedAction.perform(self)
end

function PK42ActionBleedCorpseOnHook:complete()
    if isClient() and not ButcheringUtil.isHookUsingSameCharacter(self.hook, self.character) then
        return false
    end

    if not self.bucket then
        -- Sem recipiente = sangra no chão.
        if isServer() or not isClient() then
            PK42ServerLogic.BleedCorpseOnHook(self.character, {
                hookX = self.hook:getSquare():getX(),
                hookY = self.hook:getSquare():getY(),
                hookZ = self.hook:getSquare():getZ(),
            })
        else
            sendClientCommand(
                self.character,
                "PK42",
                "BleedCorpseOnHook",
                {
                    hookX = self.hook:getSquare():getX(),
                    hookY = self.hook:getSquare():getY(),
                    hookZ = self.hook:getSquare():getZ(),
                }
            )
        end
    end

    -- Com recipiente: PK42GatherBloodFromCorpse (enfileirado pelo caller)
    ButcheringUtil.setUsingPlayerForHook(self.hook, nil)
    return true
end

function PK42ActionBleedCorpseOnHook:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    -- Mesma fórmula do ISCutAnimalOnHook vanilla
    return 150 - (self.character:getPerkLevel(Perks.Butchering) * 10)
end

---@param character  IsoPlayer
---@param hook       IsoObject    objeto do gancho
---@param luaHookUI  ISButcherHookUI   referência ao painel
---@param bucket     InventoryItem|nil  recipiente selecionado (nil = sangrar no chão)
function PK42ActionBleedCorpseOnHook:new(character, hook, luaHookUI, bucket)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self

    o.character  = character
    o.hook       = hook
    o.luaHook    = luaHookUI
    o.bucket     = bucket
    o.stopOnWalk = true
    o.stopOnRun  = true
    o.maxTime    = o:getDuration()

    return o
end