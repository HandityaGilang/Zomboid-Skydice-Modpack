local TABAS_BathingManager = {}

local TABAS_BathingSystems = require("Bathing/TABAS_BathingSystems")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_GameTimes = require("TABAS_GameTimes")
local TABAS_Utils = require("TABAS_Utils")

local UPDATE_ORDER = {
    "WaterState",
    "ThermalCompat",
    "WornWet",
    "Benefit",
    "BathingWet",
    "Comforted",
    "FeelingGaze",
    "Moodles",
}

function TABAS_BathingManager:new(character)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.character = character
    o.playerNum = character:getPlayerNum()
    o.startH = nil
    o.nowH = nil
    o.elapsedSec = 0
    o.sessionActive = false
    o.systems = {}

    o:initSystems()
    return o
end

function TABAS_BathingManager:initSystems()
    self.systems.WaterState = TABAS_BathingSystems.WaterState:new(self)
    self.systems.ThermalCompat = TABAS_BathingSystems.ThermalCompat:new(self)
    self.systems.WornWet = TABAS_BathingSystems.WornWet:new(self)
    self.systems.Benefit = TABAS_BathingSystems.Benefit:new(self)
    self.systems.BathingWet = TABAS_BathingSystems.BathingWet:new(self)
    self.systems.Comforted = TABAS_BathingSystems.Comforted:new(self)
    self.systems.FeelingGaze = TABAS_BathingSystems.FeelingGaze:new(self)
    self.systems.Moodles = TABAS_BathingSystems.Moodles:new(self)
end

function TABAS_BathingManager:eventHooks()
    if self.onTickFunc then
        return
    end

    self.onTickFunc = function()
        self:update()
    end
    Events.OnTick.Add(self.onTickFunc)
end

function TABAS_BathingManager:removeEventHooks()
    if self.onTickFunc then
        Events.OnTick.Remove(self.onTickFunc)
        self.onTickFunc = nil
    end
end

function TABAS_BathingManager:allSystemsEnded()
    for _, name in ipairs(UPDATE_ORDER) do
        local system = self.systems[name]
        if system and not system.ended then
            return false
        end
    end
    return true
end

function TABAS_BathingManager:attachSession(mode, session)
    self.mode = mode
    self.session = session
    self.startH = session.startH or TABAS_GameTimes.getWorldAgeHours()
    self.nowH = self.startH
    self.elapsedSec = 0
    self.sessionActive = false
    self.completed = false
    self.endedH = nil

    for _, name in ipairs(UPDATE_ORDER) do
        local system = self.systems[name]
        if system and system.onSessionStart then
            system:onSessionStart(mode, session)
        end
    end

    self:eventHooks()
end

function TABAS_BathingManager:detachSession(completed)
    local endH = TABAS_GameTimes.getWorldAgeHours()

    self.session = nil
    self.sessionActive = false
    self.completed = completed == true
    self.endedH = endH

    for _, name in ipairs(UPDATE_ORDER) do
        local system = self.systems[name]
        if system and system.onSessionEnd then
            system:onSessionEnd(endH, self.completed)
        end
    end

    if self:allSystemsEnded() then
        self:removeEventHooks()
    end
end

function TABAS_BathingManager:isSessionActive()
    if self.mode == "BATH" then
        return self.session ~= nil
            and not self.session.isFinished
            and TABAS_BathingUtils.isTakingBath(self.character)
    end

    if self.mode == "SHOWER" then
        return self.session ~= nil
            and self.session.started
            and not self.session.finished
    end

    return false
end

function TABAS_BathingManager:update()
    if not self.character or self.character:isDead() then
        return
    end

    if self:allSystemsEnded() then
        self:removeEventHooks()
        return
    end

    self.sessionActive = self:isSessionActive()
    self.nowH = TABAS_GameTimes.getWorldAgeHours()

    if not self.startH then
        self.startH = self.nowH
    end
    self.elapsedSec = math.max(0, (self.nowH - self.startH) * 3600)

    self.worldTemp = TABAS_Utils.getWorldTemperature()

    if self.mode == "SHOWER" and self.session then
        self.isHotWater = self.session.isHotWater == true
    elseif self.mode ~= "BATH" then
        self.isHotWater = false
    end

    local tm = TABAS_GameTimes:getMultiplier()
    for _, name in ipairs(UPDATE_ORDER) do
        local system = self.systems[name]
        if system and system.update and not system.ended then
            system:update(self.nowH, self.elapsedSec, tm)
        end
    end

    if self:allSystemsEnded() then
        self:removeEventHooks()
    end
end

function TABAS_BathingManager:destroy()
    for _, name in ipairs(UPDATE_ORDER) do
        local system = self.systems[name]
        if system and system.destroy then
            system:destroy()
        end
    end
    self:removeEventHooks()
end

return TABAS_BathingManager
