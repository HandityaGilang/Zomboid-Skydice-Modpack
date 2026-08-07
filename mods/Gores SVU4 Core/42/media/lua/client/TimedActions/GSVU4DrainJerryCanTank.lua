--========================================================
-- GSVU4 Drain Jerry Can Tank - Timed Action
-- Transfers fluid FROM a mounted jerry can tank INTO an
-- inventory container. Uses a pour animation.
-- Time: 5 seconds per litre transferred (min 30, max 120)
--========================================================

require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISTimedActionQueue"
require "GoresSVU4Core/GSVU4_Upgrades_Config"
require "VehicleArmor_ActionHelpers"

GSVU4DrainJerryCanTank = ISBaseTimedAction:derive("GSVU4DrainJerryCanTank")

function GSVU4DrainJerryCanTank:isValid()
    if not self.character or not self.vehicle then return false end
    if VehicleArmor_IsCharacterInVehicle and VehicleArmor_IsCharacterInVehicle(self.character) then return false end
    if VehicleArmor_IsCharacterNearVehicle and not VehicleArmor_IsCharacterNearVehicle(self.character, self.vehicle, 5.5) then return false end

    local tanks = GSVU4UpgradesConfig.getJerryCanTanks(self.vehicle)
    if not tanks or not tanks[self.tankIdx] then return false end
    local tank = tanks[self.tankIdx]
    if (tonumber(tank.amount) or 0) < 0.01 then return false end

    -- Confirm destination item is still in inventory with space
    local inv = self.character.getInventory and self.character:getInventory()
    if not inv then return false end
    local dst = self.dest
    if not dst or not dst.item then return false end
    local md = dst.item.getModData and dst.item:getModData() or nil
    local dstAmt = dst.amount
    if md and md.GSVU4_FluidRemaining ~= nil then dstAmt = tonumber(md.GSVU4_FluidRemaining) or dstAmt end
    if (dst.capacity or 20) - dstAmt < 0.01 then return false end

    return true
end

function GSVU4DrainJerryCanTank:start()
    self:setActionAnim("Loot")
end

function GSVU4DrainJerryCanTank:stop()
    ISBaseTimedAction.stop(self)
end

function GSVU4DrainJerryCanTank:perform()
    if not self:isValid() then
        ISBaseTimedAction.perform(self); return
    end

    local tanks = GSVU4UpgradesConfig.getJerryCanTanks(self.vehicle)
    local tank  = tanks[self.tankIdx]
    local dst   = self.dest

    -- Current tank amount
    local tankAmt = tonumber(tank.amount) or 0

    -- Current destination amount (may have been updated by modData)
    local md = dst.item.getModData and dst.item:getModData() or nil
    local dstAmt = dst.amount
    if md and md.GSVU4_FluidRemaining ~= nil then dstAmt = tonumber(md.GSVU4_FluidRemaining) or dstAmt end
    local dstSpace = (dst.capacity or 20) - dstAmt

    local pour = math.min(dstSpace, tankAmt, self.amount)
    if pour < 0.001 then ISBaseTimedAction.perform(self); return end

    -- Write to destination modData
    if md then md.GSVU4_FluidRemaining = dstAmt + pour end

    -- Update tank
    tank.amount = math.max(0, tankAmt - pour)
    if tank.amount < 0.01 then tank.fluidType = nil end

    if self.vehicle.transmitModData then self.vehicle:transmitModData() end
    if self.character then
        self.character:Say(string.format("Drained %.1fL from tank %d into container.",
            pour, self.tankIdx))
    end

    ISBaseTimedAction.perform(self)
end

function GSVU4DrainJerryCanTank:new(character, vehicle, tankIdx, dest, amount)
    local o = ISBaseTimedAction:new(character)
    setmetatable(o, self)
    self.__index  = self
    o.character   = character
    o.vehicle     = vehicle
    o.tankIdx     = tankIdx
    o.dest        = dest
    o.amount      = amount or 20
    o.stopOnWalk  = true
    o.stopOnRun   = true
    o.stopOnAim   = false
    o.maxTime     = math.max(30, math.min(120, math.floor((amount or 20) * 5)))
    return o
end
