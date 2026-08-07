if isClient() then return end

local TABAS_BathingBenefitDriver = {}

local TABAS_BathingBenefits = require("Bathing/TABAS_BathingBenefits")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_Utils = require("TABAS_Utils")
local TABAS_Iso = require("TABAS_Iso")
local TFC_Utils = require("TubFluidContainer/TABAS_TubFluidContainerSystemUtils")

function TABAS_BathingBenefitDriver:new(player, mode, x, y, z)
    if not player then return nil end
    if mode ~= "BATH" and mode ~= "SHOWER" then return nil end

    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.playerKey = TABAS_Utils.getPlayerKey(player)
    o.mode = mode
    o.x = x
    o.y = y
    o.z = z
    o.ended = false
    o.tfc_Base = nil
    o.benefit = TABAS_BathingBenefits:new(player, mode)
    if not o.benefit then return nil end
    return o
end

function TABAS_BathingBenefitDriver:destroy()
    if self.ended then return end
    self.ended = true
    self.benefit = nil
end

function TABAS_BathingBenefitDriver:isValid(player)
    if not player or player:isDead() then return false end
    local md = player:getModData()
    if not md or not md.tabas_IsBathing then
        return false
    end
    return true
end

function TABAS_BathingBenefitDriver:getWornItemCount()
    local wornItems = self.player and self.player:getWornItems()
    if not wornItems then return 0 end
    return TABAS_Utils.countWornClothesAfterExclusions(wornItems)
end

function TABAS_BathingBenefitDriver:apply()
    local benefit = self.benefit
    if not benefit then
        return false
    end

    if self.mode == "BATH" then
        local tfc_Base = self.tfc_Base
        if not tfc_Base then
            tfc_Base = TFC_Utils.getTfcBaseOnServer(self.x, self.y, self.z)
            if not tfc_Base then return false end
            self.tfc_Base = tfc_Base
        end

        local waterState = TABAS_BathingUtils.getBathWaterState(tfc_Base)
        if not waterState.canBenefit then return "paused" end

        benefit:setContext({
            bathSalt = tfc_Base:getWaterData("bathSalt"),
            dirtyLevel = tfc_Base:getWaterData("dirtyLevel"),
            wornItemCount = self:getWornItemCount(),
            waterTemp = waterState.waterTemp,
            amountRatio = tfc_Base:getRatio() or 0,
        })

        benefit:apply()
        return true
    end

    local showerObj = TABAS_Iso.getShowerObjectAt(self.x, self.y, self.z, true)
    if not showerObj then return false end

    local md = showerObj:getModData()
    local canHot = TABAS_Iso.canHot(showerObj)
    local waterTemp = canHot and ((md and md.idealTemperature) or 40.0) or 22.0
    benefit:setContext({
        wornItemCount = self:getWornItemCount(),
        waterTemp = waterTemp,
        amountRatio = 1,
    })
    benefit:apply()
    return true
end

function TABAS_BathingBenefitDriver:pause()
    return self.benefit ~= nil
end

function TABAS_BathingBenefitDriver:update()
    if self.ended then return false end

    if not self:isValid(self.player) then
        self:destroy()
        return false
    end

    local applied = self:apply()
    if applied == "paused" then
        if self:pause() then return true end
        self:destroy()
        return false
    end

    if not applied then
        self:destroy()
        return false
    end

    return true
end

return TABAS_BathingBenefitDriver
