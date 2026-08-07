--========================================================
-- GSVU4 Fill Jerry Can Tank - Timed Action
-- Transfers fluid FROM an inventory container INTO a
-- mounted jerry can tank. Uses a pour animation.
-- Time: 5 seconds per litre transferred (min 30, max 120)
--========================================================

require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "GoresSVU4Core/GSVU4_Upgrades_Config"
require "VehicleArmor_ActionHelpers"

GSVU4FillJerryCanTank = ISBaseTimedAction:derive("GSVU4FillJerryCanTank")

function GSVU4FillJerryCanTank:isValid()
    if not self.character or not self.vehicle then return false end
    if VehicleArmor_IsCharacterInVehicle and VehicleArmor_IsCharacterInVehicle(self.character) then return false end
    if VehicleArmor_IsCharacterNearVehicle and not VehicleArmor_IsCharacterNearVehicle(self.character, self.vehicle, 5.5) then return false end

    -- Confirm tank still exists and has space
    local tanks = GSVU4UpgradesConfig.getJerryCanTanks(self.vehicle)
    if not tanks or not tanks[self.tankIdx] then return false end
    local tank = tanks[self.tankIdx]
    local cap = tonumber(tank.capacity) or 20
    local amt = tonumber(tank.amount)   or 0
    if cap - amt < 0.01 then return false end

    -- Confirm source item is still in inventory with fluid
    local inv = self.character.getInventory and self.character:getInventory()
    if not inv then return false end
    local src = self.source
    if not src or not src.item then return false end
    -- Check effective amount in source
    local md = src.item.getModData and src.item:getModData() or nil
    if md and md.GSVU4_FluidRemaining ~= nil then
        if (tonumber(md.GSVU4_FluidRemaining) or 0) < 0.01 then return false end
    end
    return true
end

function GSVU4FillJerryCanTank:start()
    -- Pour animation - character tips container into tank
    self:setActionAnim("Loot")
end

function GSVU4FillJerryCanTank:stop()
    ISBaseTimedAction.stop(self)
end

function GSVU4FillJerryCanTank:perform()
    if not self:isValid() then
        ISBaseTimedAction.perform(self); return
    end

    local tanks = GSVU4UpgradesConfig.getJerryCanTanks(self.vehicle)
    local tank  = tanks[self.tankIdx]
    local cap   = tonumber(tank.capacity) or 20
    local amt   = tonumber(tank.amount)   or 0
    local space = cap - amt
    local src   = self.source

    -- Read actual available amount from source
    local inv = self.character.getInventory and self.character:getInventory()
    local srcAmt = src.amount
    local md = src.item.getModData and src.item:getModData() or nil
    if md and md.GSVU4_FluidRemaining ~= nil then
        srcAmt = tonumber(md.GSVU4_FluidRemaining) or srcAmt
    end

    local take   = math.min(srcAmt, space, self.amount)
    local newSrc = srcAmt - take

    -- Update source item (remove if empty, else update modData)
    if newSrc < 0.001 then
        if inv and inv.Remove then pcall(function() inv:Remove(src.item) end) end
    else
        if md then md.GSVU4_FluidRemaining = newSrc end
    end

    -- Update tank
    tank.amount = math.min(cap, amt + take)
    if src.fluidName and src.fluidName ~= "" then
        tank.fluidType = src.fluidName
    end

    if self.vehicle.transmitModData then self.vehicle:transmitModData() end
    if self.character then
        self.character:Say(string.format("Filled %.1fL of %s into tank %d.",
            take, src.fluidName or "fluid", self.tankIdx))
    end

    ISBaseTimedAction.perform(self)
end

function GSVU4FillJerryCanTank:new(character, vehicle, tankIdx, source, amount)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index  = self
    o.character   = character
    o.vehicle     = vehicle
    o.tankIdx     = tankIdx
    o.source      = source
    o.amount      = amount or 20
    o.stopOnWalk  = true
    o.stopOnRun   = true
    o.stopOnAim   = false
    -- ~5 seconds per litre, min 30, max 120 ticks
    o.maxTime     = math.max(30, math.min(120, math.floor((amount or 20) * 5)))
    return o
end
