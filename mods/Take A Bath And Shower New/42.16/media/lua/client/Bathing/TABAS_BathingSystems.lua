local TABAS_BathingSystems = {}

local TABAS_Utils = require("TABAS_Utils")
local TABAS_BathingUtils = require("Bathing/TABAS_BathingUtils")
local TABAS_Moodles = require("TABAS_Moodles")
require "Compat/TABAS_Compat"

local GAZE_CHECK_INTERVAL_SEC = 1.5
local GAZE_ACTIVATE_SEC = 1.5
local GAZE_DEACTIVATE_SEC = 0.8
local BENEFIT_DELAY_SEC = 120
local WET_DELAY_SEC = 120
local COMFORT_DELAY_SEC = 300
local WORN_WET_INTERVAL_SEC = 2.0
local THERMAL_COMPAT_INTERVAL_SEC = 1.0
local MF_MOODLE_NAMES = {
    bathingWet = "Wet_Bathing",
    cooling = "CoolingBody",
    warming = "WarmingBody",
    feelingGaze = "FeelingGaze",
}

TABAS_BathingSystems.WaterState = {}
TABAS_BathingSystems.ThermalCompat = {}
TABAS_BathingSystems.WornWet = {}
TABAS_BathingSystems.BathingWet = {}
TABAS_BathingSystems.Benefit = {}
TABAS_BathingSystems.Comforted = {}
TABAS_BathingSystems.FeelingGaze = {}
TABAS_BathingSystems.Moodles = {}

local function buildIgnoreUserSet(csv)
    local set = {}
    if not csv then return set end

    csv = tostring(csv)
    for token in csv:gmatch("([^,]+)") do
        token = token:gsub("^%s+", ""):gsub("%s+$", "")
        if token ~= "" then
            set[token] = true
        end
    end
    return set
end

--------------------------------------------------------

function TABAS_BathingSystems.WaterState:new(manager)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.manager = manager
    o.stopped = true
    o.ended = true
    return o
end

function TABAS_BathingSystems.WaterState:reset()
    self.manager.waterState = TABAS_BathingUtils.defaultBathWaterState()
    self.manager.isHotWater = false
end

function TABAS_BathingSystems.WaterState:onSessionStart(mode)
    self.ended = mode ~= "BATH"
    self.stopped = self.ended
    self:reset()
end

function TABAS_BathingSystems.WaterState:onSessionEnd()
    self.stopped = true
    self:reset()
    self.ended = true
end

function TABAS_BathingSystems.WaterState:update()
    if self.manager.mode ~= "BATH" or not self.manager.session or not self.manager.sessionActive then
        self:reset()
        return
    end

    local tfc_Base = self.manager.session:getTfc()
    self.manager.waterState = TABAS_BathingUtils.getBathWaterState(tfc_Base)
    self.manager.isHotWater = tfc_Base and tfc_Base:isHotWater() or false
end

--------------------------------------------------------

function TABAS_BathingSystems.ThermalCompat:new(manager)
    if not TABAS_Compat.RealisticTemperature then return nil end

    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.manager = manager
    o.stopped = true
    o.ended = true
    o.readySec = BENEFIT_DELAY_SEC
    o.nextCheckSec = 0
    o.lastCheckSec = 0
    return o
end

function TABAS_BathingSystems.ThermalCompat:onSessionStart(mode)
    self.readySec = BENEFIT_DELAY_SEC
    self.nextCheckSec = self.readySec
    self.lastCheckSec = self.readySec
    self.ended = not (mode == "BATH" or mode == "SHOWER")
    self.stopped = self.ended
end

function TABAS_BathingSystems.ThermalCompat:onSessionEnd()
    self.stopped = true
    self.ended = true
end

function TABAS_BathingSystems.ThermalCompat:getWaterTemperature()
    if self.manager.mode == "BATH" then
        local waterState = self.manager.waterState or TABAS_BathingUtils.defaultBathWaterState()
        if waterState.hasFluid ~= true or waterState.canWet ~= true then return nil end
        return waterState.waterTemp or 22.0
    end

    if self.manager.mode == "SHOWER" then
        local session = self.manager.session
        local showerObj = session and session.showerObj
        local md = showerObj and showerObj:getModData()
        if session and session.isHotWater == true then
            return (md and md.idealTemperature) or session.waterTemp or 40.0
        end
        return 22.0
    end

    return nil
end

function TABAS_BathingSystems.ThermalCompat:update(nowH, elapsedSec, tm)
    if self.stopped or not self.manager.sessionActive then return end
    if elapsedSec < self.nextCheckSec then return end

    local deltaSec = elapsedSec - (self.lastCheckSec or elapsedSec)
    if deltaSec < 0 then deltaSec = 0 end
    self.lastCheckSec = elapsedSec
    self.nextCheckSec = elapsedSec + THERMAL_COMPAT_INTERVAL_SEC

    local waterTemp = self:getWaterTemperature()
    if not waterTemp then return end

    TABAS_Compat.applyRealisticTemperatureBathingTemperature(
        self.manager.character,
        waterTemp,
        deltaSec / 60.0,
        self.manager.worldTemp
    )
end

function TABAS_BathingSystems.ThermalCompat:destroy()
    self.stopped = true
    self.ended = true
end

--------------------------------------------------------

function TABAS_BathingSystems.WornWet:new(manager)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.manager = manager
    o.stopped = true
    o.ended = true
    return o
end

function TABAS_BathingSystems.WornWet:onSessionStart(mode)
    self.nextCheckSec = WORN_WET_INTERVAL_SEC
    self.stopped = false
    self.ended = false
end

function TABAS_BathingSystems.WornWet:onSessionEnd()
    self.stopped = true
    self.ended = true
    self.nextCheckSec = 0
end

function TABAS_BathingSystems.WornWet:canWet()
    if self.manager.mode == "BATH" then
        local waterState = self.manager.waterState or TABAS_BathingUtils.defaultBathWaterState()
        return waterState.canWet == true
    end

    if self.manager.mode == "SHOWER" then
        local session = self.manager.session
        local showerObj = session and session.showerObj
        return showerObj and showerObj:hasFluid()
    end

    return false
end

function TABAS_BathingSystems.WornWet:update(nowH, elapsedSec, tm)
    if self.stopped or not self.manager.sessionActive then return end

    if elapsedSec < self.nextCheckSec then return end

    self.nextCheckSec = elapsedSec + WORN_WET_INTERVAL_SEC
    local wornItems = self.manager.character:getWornItems()
    if self:canWet() then
        TABAS_BathingUtils.wetWornItems(self.manager.character, wornItems, 25)
    end
end

function TABAS_BathingSystems.WornWet:destroy()
    self.stopped = true
    self.ended = true
end

--------------------------------------------------------

function TABAS_BathingSystems.Benefit:new(manager)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.manager = manager
    o.stopped = true
    o.ended = true
    o.readySec = WET_DELAY_SEC
    o.applied = false
    return o
end

function TABAS_BathingSystems.Benefit:onSessionStart(mode)
    local supportedMode = (mode == "BATH") or (mode == "SHOWER")
    self.readySec = BENEFIT_DELAY_SEC
    self.applied = false
    self.ended = not supportedMode
    self.stopped = self.ended
end

function TABAS_BathingSystems.Benefit:onSessionEnd()
    if self.applied then
        TABAS_BathingUtils.stopBathingBenefit(self.manager.character)
    end
    self.applied = false
    self.stopped = true
    self.ended = true
end

function TABAS_BathingSystems.Benefit:update(nowH, elapsedSec, tm)
    if self.stopped or not self.manager.sessionActive or self.applied then return end
    if elapsedSec < self.readySec then return end

    local mode = self.manager.mode
    local session = self.manager.session
    if not session then return end

    local sq = nil
    if mode == "BATH" then
        local waterState = self.manager.waterState or TABAS_BathingUtils.defaultBathWaterState()
        if not waterState.canBenefit then
            return
        end
        sq = session.baseSq
    elseif mode == "SHOWER" then
        sq = session.square or (session.showerObj and session.showerObj:getSquare())
    else
        return
    end

    if sq then
        TABAS_BathingUtils.startBathingBenefit(self.manager.character, mode, sq:getX(), sq:getY(), sq:getZ())
        self.applied = true
        self.stopped = true
        self.ended = true
    end
end

--------------------------------------------------------

function TABAS_BathingSystems.BathingWet:new(manager)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.manager = manager
    o.started = false
    o.stopped = true
    o.ended = true
    o.readySec = WET_DELAY_SEC
    return o
end

function TABAS_BathingSystems.BathingWet:onSessionStart(mode)
    self.started = false
    self.stopped = false
    self.ended = false
    self.maxWetTime = (mode == "BATH") and 900 or 600
    self.wetTime = 0
    self.effectiveSoakSec = 0
    self.lastElapsedSec = 0
end

function TABAS_BathingSystems.BathingWet:onSessionEnd(endH, completed)
    self.stopped = true
    if self.wetTime > 0 then
        self.wetEndH = endH + (self.wetTime / 3600)
        local graceSec = completed and 180 or 30
        self.wetGraceEndH = endH + (graceSec / 3600)
        triggerEvent("OnBathingWetStart", self.manager.character)
    end
end

function TABAS_BathingSystems.BathingWet:update(nowH, elapsedSec, tm)
    local deltaSec = elapsedSec - self.lastElapsedSec
    if deltaSec < 0 then
        deltaSec = 0
    end
    self.lastElapsedSec = elapsedSec

    if not self.stopped and self.manager.sessionActive and elapsedSec >= self.readySec then
        if self.manager.mode == "BATH" then
            local waterState = self.manager.waterState or TABAS_BathingUtils.defaultBathWaterState()
            local soakRate = waterState.wetRate or 0

            if soakRate > 0 and deltaSec > 0 then
                self.started = true
                self.effectiveSoakSec = self.effectiveSoakSec + (deltaSec * soakRate)
                local progress = math.min(1, self.effectiveSoakSec / WET_DELAY_SEC)
                self.wetTime = math.floor(self.maxWetTime * progress + 0.5)
            end
        elseif deltaSec > 0 then
            self.started = true
            self.wetTime = math.min(self.maxWetTime, (self.wetTime or 0) + tm)
        end
    end

    local character = self.manager.character
    local curWetness = character:getStats():get(CharacterStat.WETNESS)
    if curWetness > 10 then
        TABAS_Utils.decreaseCharacterWetness(character, curWetness)
    end

    local wetEndH = self.wetEndH or 0
    if self.stopped and wetEndH > 0 and wetEndH <= nowH then
        TABAS_Utils.increaseCharacterWetness(character, 45)
        self:destroy()
        triggerEvent("OnBathingStateFinished", self.manager.character)
        return
    end

    if self.stopped and curWetness >= 20 then
        self:destroy()
        triggerEvent("OnBathingStateFinished", self.manager.character)
        return
    end

    local wetGraceEndH = self.wetGraceEndH or 0
    if self.stopped and wetEndH <= nowH and wetGraceEndH <= nowH then
        self:destroy()
        triggerEvent("OnBathingStateFinished", self.manager.character)
    end
end

function TABAS_BathingSystems.BathingWet:destroy()
    self.stopped = true
    self.ended = true
end

--------------------------------------------------------

function TABAS_BathingSystems.Comforted:new(manager)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.manager = manager
    o.stopped = true
    o.ended = true
    o.readySec = COMFORT_DELAY_SEC
    o.lastState = nil
    return o
end

function TABAS_BathingSystems.Comforted:onSessionStart(mode)
    local supportedMode = (mode == "BATH") or (mode == "SHOWER")
    self.readySec = COMFORT_DELAY_SEC
    self.lastState = nil
    self.ended = not supportedMode
    self.stopped = self.ended
end

function TABAS_BathingSystems.Comforted:onSessionEnd()
    self.stopped = true
    self.lastState = nil
    self.ended = true
end

function TABAS_BathingSystems.Comforted:update(nowH, elapsedSec, tm)
    if self.stopped or not self.manager.sessionActive then
        self.lastState = nil
        return
    end

    if elapsedSec < self.readySec then
        return
    end

    local waterState = self.manager.waterState or TABAS_BathingUtils.defaultBathWaterState()
    local canComfort = false
    if self.manager.mode == "BATH" then
        canComfort = waterState.canComfort == true
    elseif self.manager.mode == "SHOWER" then
        canComfort = true
    end

    if not canComfort then
        self.lastState = nil
        return
    end

    local state = nil
    if self.manager.isHotWater then
        if self.manager.worldTemp <= 30 then
            state = "WARMING"
        end
    elseif self.manager.worldTemp >= 30 then
        state = "COOLING"
    end

    if state == "WARMING" or state == "COOLING" then
        self:applyPlayerStat(tm)
    end

    self.lastState = state
end

function TABAS_BathingSystems.Comforted:destroy()
    self.stopped = true
    self.ended = true
end

function TABAS_BathingSystems.Comforted:applyPlayerStat(tm)
    local character = self.manager.character
    character:getStats():remove(CharacterStat.UNHAPPINESS, 0.03 * tm)
    if isClient() then
        sendPlayerStat(character, CharacterStat.UNHAPPINESS)
    end
end

--------------------------------------------------------

function TABAS_BathingSystems.FeelingGaze:new(manager)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.manager = manager
    o.stopped = true
    o.ended = true
    o.range = 8
    o.ignoreZed = false
    o.ignoreUsers = buildIgnoreUserSet(TABAS_Utils.ModOptionsValue("DontMindWatchedBy") or "")
    return o
end

function TABAS_BathingSystems.FeelingGaze:onSessionStart(mode)
    local disabled = SandboxVars.TakeABathAndShower.DisableFeelingStressByGaze == true
    self.active = false
    self.count = 0
    self.nextInterval = 0
    self.lastCheckSec = 0
    self.seenAcc = 0.0
    self.unseenAcc = 0.0
    self.ended = disabled
    self.stopped = disabled
end

function TABAS_BathingSystems.FeelingGaze:onSessionEnd()
    self.stopped = true
    self.active = false
    self.count = 0
    self.nextInterval = 0
    self.seenAcc = 0.0
    self.unseenAcc = 0.0
    self.ended = true
end

function TABAS_BathingSystems.FeelingGaze:update(nowH, elapsedSec, tm)
    if self.stopped or not self.manager.sessionActive then
        return
    end

    if elapsedSec < self.nextInterval then
        return
    end

    local deltaSec = math.max(elapsedSec - self.lastCheckSec, 0)
    self.lastCheckSec = elapsedSec
    self.nextInterval = elapsedSec + GAZE_CHECK_INTERVAL_SEC

    local count = self:isBeingWatched(self.manager.character)
    self.count = count

    if count > 0 then
        self.seenAcc = math.min(self.seenAcc + deltaSec, 10.0)
        self.unseenAcc = 0.0
    else
        self.unseenAcc = math.min(self.unseenAcc + deltaSec, 10.0)
        self.seenAcc = 0.0
    end

    if (not self.active) and self.seenAcc >= GAZE_ACTIVATE_SEC then
        self.active = true
    elseif self.active and self.unseenAcc >= GAZE_DEACTIVATE_SEC then
        self.active = false
    end

    self:applyPlayerStat()
end

function TABAS_BathingSystems.FeelingGaze:isBeingWatched(character)
    if not character then return 0 end

    local r2 = self.range * self.range
    local x0 = character:getX()
    local y0 = character:getY()
    local z0 = character:getZ()
    local seen = 0

    local players = getOnlinePlayers()
    if players then
        for i = 0, players:size() - 1 do
            local p = players:get(i)
            if p ~= character and p:getZ() == z0 and not p:isAnimal() then
                local userName = p:getUsername()
                if not (userName and self.ignoreUsers[userName]) then
                    local dx = p:getX() - x0
                    local dy = p:getY() - y0
                    if (dx * dx + dy * dy) <= r2 and p:CanSee(character) then
                        seen = seen + 1
                        if seen >= 4 then
                            return seen
                        end
                    end
                end
            end
        end
    end

    if not self.ignoreZed then
        local cell = getCell()
        local zombies = cell and cell:getZombieList()
        if zombies then
            for i = 0, zombies:size() - 1 do
                local z = zombies:get(i)
                if z and z:getZ() == z0 then
                    local dx = z:getX() - x0
                    local dy = z:getY() - y0
                    if (dx * dx + dy * dy) <= r2 and z:CanSee(character) then
                        seen = seen + 1
                        if seen >= 4 then
                            return seen
                        end
                    end
                end
            end
        end
    end

    return seen
end

function TABAS_BathingSystems.FeelingGaze:applyPlayerStat()
    if self.count <= 0 then return end

    local stress = (self.count > 2) and 0.65 or 0.45
    local character = self.manager.character
    local curStress = character:getStats():get(CharacterStat.STRESS)
    if curStress < stress then
        character:getStats():set(CharacterStat.STRESS, stress)
        if isClient() then
            sendPlayerStat(character, CharacterStat.STRESS)
        end
    end
end

function TABAS_BathingSystems.FeelingGaze:destroy()
    self.stopped = true
    self.ended = true
end

--------------------------------------------------------

function TABAS_BathingSystems.Moodles:new(manager)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.manager = manager
    o.playerNum = manager.playerNum
    o.stopped = not (MF and MF.getMoodle ~= nil)
    o.ended = o.stopped
    return o
end

function TABAS_BathingSystems.Moodles:onSessionStart(mode)
    self.stopped = not (MF and MF.getMoodle ~= nil)
    self.ended = self.stopped
end

function TABAS_BathingSystems.Moodles:onSessionEnd()
end

function TABAS_BathingSystems.Moodles:destroy()
    self:clearMoodle("bathingWet")
    self:clearMoodle("cooling")
    self:clearMoodle("warming")
    self:clearMoodle("feelingGaze")
    self.stopped = true
    self.ended = true
end

function TABAS_BathingSystems.Moodles:setMoodleValue(key, value)
    local moodleName = MF_MOODLE_NAMES[key]
    if not moodleName then return end
    TABAS_Moodles.setMFMoodleValue(moodleName, self.playerNum, value)
end

function TABAS_BathingSystems.Moodles:clearMoodle(key)
    local moodleName = MF_MOODLE_NAMES[key]
    if not moodleName then return end
    TABAS_Moodles.setMFMoodleValue(moodleName, self.playerNum, 0.5)
end

function TABAS_BathingSystems.Moodles:update(nowH, elapsedSec, tm)
    local wetSystem = self.manager.systems.BathingWet
    local comfortedSystem = self.manager.systems.Comforted
    local gazeSystem = self.manager.systems.FeelingGaze

    -- bathingWet
    local wetValue = 0.5
    if wetSystem then
        local wetEndH = wetSystem.wetEndH or 0
        local wetGraceEndH = wetSystem.wetGraceEndH or 0

        if wetSystem.started and not wetSystem.stopped then
            wetValue = 1.0
        elseif wetGraceEndH > nowH then
            wetValue = 1.0
        elseif wetEndH > nowH then
            if ((wetEndH - nowH) * 3600) <= 240 then
                wetValue = 0.6
            else
                wetValue = 0.7
            end
        end
    end
    if wetValue == 0.5 then
        self:clearMoodle("bathingWet")
    else
        self:setMoodleValue("bathingWet", wetValue)
    end

    -- warming / cooling
    local warmingValue = 0.5
    local coolingValue = 0.5
    if comfortedSystem then
        if comfortedSystem.lastState == "WARMING" then
            warmingValue = 1.0
        elseif comfortedSystem.lastState == "COOLING" then
            coolingValue = 1.0
        end
    end
    if warmingValue == 0.5 then
        self:clearMoodle("warming")
    else
        self:setMoodleValue("warming", warmingValue)
    end
    if coolingValue == 0.5 then
        self:clearMoodle("cooling")
    else
        self:setMoodleValue("cooling", coolingValue)
    end

    -- feelingGaze
    local gazeValue = 0.5
    if gazeSystem then
        if gazeSystem.active then
            local count = gazeSystem.count or 0
            if count == 1 then
                gazeValue = 0.4
            elseif count == 2 then
                gazeValue = 0.3
            elseif count == 3 then
                gazeValue = 0.2
            elseif count >= 4 then
                gazeValue = 0.1
            end
        end
    end
    if gazeValue == 0.5 then
        self:clearMoodle("feelingGaze")
    else
        self:setMoodleValue("feelingGaze", gazeValue)
    end

    if wetSystem.ended and comfortedSystem.ended and gazeSystem.ended then
        self.stopped = true
        self.ended = true
    end
end

return TABAS_BathingSystems
