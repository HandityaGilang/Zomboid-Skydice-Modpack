require "ISBaseObject"

local TABAS_BathingBenefits = ISBaseObject:derive("TABAS_BathingBenefits")

local TABAS_Utils = require("TABAS_Utils")
require "Compat/TABAS_Compat"
local BathSaltDefs = require("TABAS_BathSaltDefs")

TABAS_BathingBenefits.BaseBenefits = {
    BATH   = {"ANGER", "FATIGUE_BASE", "SANITY", "STRESS", "INTOXICATION_INC", "BOREDOM", "UNHAPPINESS", "STIFFNESS_BASE"},
    SHOWER = {"ANGER", "STRESS", "BOREDOM", "UNHAPPINESS"},
}

local Factor = {
    ANGER = 0.003,
    FATIGUE = 0.24,
    FATIGUE_BASE = 0.03,
    SANITY = 0.024,
    STRESS = 2.4,
    INTOXICATION = 4.8,
    INTOXICATION_INC = 2.4,

    PAIN = 0.04,
    HEALTH = 0.07,
    BOREDOM = 0.06,
    UNHAPPINESS = 0.03,
    COLD = 5,

    ADDITIONAL_PAIN = 4,
    ADDITIONAL_PAIN_INC = 4,

    BURN = 1.2,
    BITE = 0.024,
    CUT = 0.48,
    DEEP_WOUND = 6,
    SCRATCH = 1.2,
    STITCH = 2.4,
    FRACTURE = 3.0,

    STIFFNESS = 2.5,
    STIFFNESS_BASE = 1.8,

    WOUND_INFECTION = 1.2,
    SUSTAIN_PILL = 600,
    SUSTAIN_COMPRESS = 10.0,
}

local BodyTemperature = {
    MIN = 20.0,
    MAX = 42.0,
    NORMAL = 37.0,
    SAFE_COOLING = 36.7,
    COOL_NEUTRAL = 36.8,
    CHILLY = 36.5,
    HOT = 37.5,
}

local AmbientTemperature = {
    COLD = 10.0,
    MILD = 20.0,
    HOT = 30.0,
    VERY_HOT = 35.0,
}

local WaterTemperature = {
    VERY_COLD = 25.0,
    COOL = 35.0,
    WARM = 38.0,
    HOT = 43.0,
    VERY_HOT = 44.0,
    SCALDING = 45.0,
    EXTREME = 50.0,
}

local function clamp(value, minValue, maxValue)
    if value < minValue then return minValue end
    if value > maxValue then return maxValue end
    return value
end

local BenefitForStats = {
    ANGER = function(s, m) if s:isAboveMinimum(CharacterStat.ANGER) then s:remove(CharacterStat.ANGER, Factor.ANGER * m) return true end return false end,
    BOREDOM = function(s, m) if s:isAboveMinimum(CharacterStat.BOREDOM) then s:remove(CharacterStat.BOREDOM, Factor.BOREDOM * m) return true end return false end,
    FATIGUE = function(s, m) if s:get(CharacterStat.FATIGUE) > 0.45 then s:remove(CharacterStat.FATIGUE, Factor.FATIGUE * m) return true end return false end,
    FATIGUE_BASE = function(s, m) if s:get(CharacterStat.FATIGUE) > 0.65 then s:remove(CharacterStat.FATIGUE, Factor.FATIGUE_BASE * m) return true end return false end,
    SANITY = function(s, m) if not s:isAtMaximum(CharacterStat.SANITY) then s:add(CharacterStat.SANITY, Factor.SANITY * m) return true end return false end,
    STRESS = function(s, m) if s:isAboveMinimum(CharacterStat.STRESS) then s:remove(CharacterStat.STRESS, Factor.STRESS * m) return true end return false end,
    PAIN = function(s, m) if s:isAboveMinimum(CharacterStat.PAIN) then s:remove(CharacterStat.PAIN, Factor.PAIN * m) return true end return false end,
    INTOXICATION = function(s, m) if s:isAboveMinimum(CharacterStat.INTOXICATION) then s:remove(CharacterStat.INTOXICATION, Factor.INTOXICATION * m) return true end return false end,
    INTOXICATION_INC = function(s, m) if s:get(CharacterStat.INTOXICATION) > 10.0 then s:add(CharacterStat.INTOXICATION, Factor.INTOXICATION_INC * m) return true end return false end,
    UNHAPPINESS = function(s, m) if s:isAboveMinimum(CharacterStat.UNHAPPINESS) then s:remove(CharacterStat.UNHAPPINESS, Factor.UNHAPPINESS * m) return true end return false end,
    ADD_BOREDOM = function (s, m) if not s:isAtMaximum(CharacterStat.BOREDOM) then s:add(CharacterStat.BOREDOM, Factor.BOREDOM * m) return true end return false end,
}

local BenefitForBody = {
    COLD = function(b, m) if b:getColdStrength() > 0 then b:setColdStrength(b:getColdStrength() - b:getColdProgressionRate() * Factor.COLD * m) return true end return false end,
    HEALTH = function(b, m) if b:getOverallBodyHealth() < 100 then b:AddGeneralHealth(Factor.HEALTH * m) return true end return false end,
}

local BenefitsForChar = {
    SLEEP_SUSTAIN = function(c, m) if c:getSleepingTabletEffect() < 4000.0 then c:setSleepingTabletEffect(c:getSleepingTabletEffect() + Factor.SUSTAIN_PILL * m) return true end return false end,
    PANIC_SUSTAIN = function(c, m) if c:getBetaEffect() < 4000.0 then c:setBetaEffect(c:getBetaEffect() + Factor.SUSTAIN_PILL * m) return true end return false end,
    ANTI_DEPRESS_SUSTAIN = function(c, m) if c:getDepressEffect() < 4000.0 then c:setDepressEffect(c:getDepressEffect() + Factor.SUSTAIN_PILL * m) return true end return false end,
    PAIN_SUSTAIN = function(c, m) if c:getPainEffect() < 4000.0 then c:setPainEffect(c:getPainEffect() + Factor.SUSTAIN_PILL * m) return true end return false end,
}

local BenefitForBodyParts = {
    ADDITIONAL_PAIN = function(p, m) if p:getAdditionalPain() > 0 then p:setAdditionalPain(p:getAdditionalPain() - Factor.ADDITIONAL_PAIN * m) return true end return false end,
    ADDITIONAL_PAIN_INC = function(p, m) if p:HasInjury() then p:setAdditionalPain(p:getAdditionalPain() + Factor.ADDITIONAL_PAIN_INC * m) return true end return false end,
    PART_HEALTH = function(p, m) if p:getHealth() < 100 then p:AddHealth(Factor.HEALTH * m) return true end return false end,
    BURN = function(p, m)
        if p:getBurnTime() > 0 then
            p:setBurnTime(p:getBurnTime() - Factor.BURN * m)
            if p:isNeedBurnWash() then
                p:setLastTimeBurnWash(0)
                p:setNeedBurnWash(false)
            end
            return true
        end
        return false
    end,
    FRACTURE = function(p, m) if p:getFractureTime() > 0 then p:setFractureTime(p:getFractureTime() - Factor.FRACTURE * m) return true end return false end,
    BITE = function(p, m) if p:getBiteTime() > 0 then p:setBiteTime(p:getBiteTime() - Factor.BITE * m) return true end return false end,
    CUT = function(p, m) if p:getCutTime() > 0 then p:setCutTime(p:getCutTime() - Factor.CUT * m) return true end return false end,
    DEEP_WOUND = function(p, m) if p:getDeepWoundTime() > 0 then p:setDeepWoundTime(p:getDeepWoundTime() - Factor.DEEP_WOUND * m) return true end return false end,
    SCRATCH = function(p, m) if p:getScratchTime() > 0 then p:setScratchTime(p:getScratchTime() - Factor.SCRATCH * m) return true end return false end,
    STITCH = function(p, m) if p:getStitchTime() > 0 then p:setStitchTime(p:getStitchTime() - Factor.STITCH * m) return true end return false end,
    STIFFNESS = function(p, m) if p:getStiffness() > 0 then p:setStiffness(p:getStiffness() - Factor.STIFFNESS * m) return true end return false end,
    STIFFNESS_BASE = function(p, m) if p:getStiffness() > 0 then p:setStiffness(p:getStiffness() - Factor.STIFFNESS_BASE * m) return true end return false end,
    WOUND_INFECTION = function(p, m) if p:getWoundInfectionLevel() > 0 then p:setWoundInfectionLevel(p:getWoundInfectionLevel() - Factor.WOUND_INFECTION * m) return true end return false end,
    INJURIES_SUSTAIN = function(p, m) if p:HasInjury() and p:getPlantainFactor() < 30 then p:setPlantainFactor(p:getPlantainFactor() + Factor.SUSTAIN_COMPRESS * m) return true end return false end,
    FRACTURE_SUSTAIN = function(p, m) if p:getFractureTime() > 0 and p:getComfreyFactor() < 30 then p:setComfreyFactor(p:getComfreyFactor() + Factor.SUSTAIN_COMPRESS * m) return true end return false end,
    WOUND_INFECTION_SUSTAIN = function(p, m) if p:getWoundInfectionLevel() > 0 and p:getGarlicFactor() < 30 then p:setGarlicFactor(p:getGarlicFactor() + Factor.SUSTAIN_COMPRESS * m) return true end return false end,
}

function TABAS_BathingBenefits.getAmbientTemperature()
    return TABAS_Utils.getWorldTemperature()
end

function TABAS_BathingBenefits.getTemperatureTarget(waterTemp, ambientTemp)
    local temperature = waterTemp or 22.0
    local ambient = ambientTemp
    if ambient == nil then
        ambient = TABAS_BathingBenefits.getAmbientTemperature()
    end
    ambient = tonumber(ambient) or AmbientTemperature.MILD

    local target = BodyTemperature.NORMAL

    if temperature >= WaterTemperature.WARM then
        if temperature >= WaterTemperature.EXTREME then
            target = 41.0
        elseif temperature >= WaterTemperature.SCALDING then
            target = 40.0
        elseif temperature >= WaterTemperature.VERY_HOT then
            target = 39.0
        elseif temperature >= WaterTemperature.HOT then
            target = BodyTemperature.HOT
        elseif ambient >= AmbientTemperature.VERY_HOT then
            target = BodyTemperature.HOT
        else
            target = BodyTemperature.NORMAL
        end
    elseif temperature < WaterTemperature.VERY_COLD then
        if ambient >= AmbientTemperature.HOT then
            target = BodyTemperature.SAFE_COOLING
        elseif ambient >= AmbientTemperature.MILD then
            target = BodyTemperature.CHILLY - 0.1
        elseif ambient >= AmbientTemperature.COLD then
            target = 35.8
        else
            target = 35.0
        end
    elseif temperature < WaterTemperature.COOL then
        if ambient >= AmbientTemperature.HOT then
            target = BodyTemperature.SAFE_COOLING
        elseif ambient >= AmbientTemperature.MILD then
            target = BodyTemperature.COOL_NEUTRAL
        elseif ambient >= AmbientTemperature.COLD then
            target = BodyTemperature.CHILLY - 0.1
        else
            target = 36.2
        end
    else
        target = BodyTemperature.COOL_NEUTRAL
    end

    return clamp(target, BodyTemperature.MIN, BodyTemperature.MAX)
end

function TABAS_BathingBenefits.stepTemperatureTowards(current, target, minutes)
    minutes = tonumber(minutes) or 1.0
    if not current or not target or minutes <= 0 then
        return current, 0
    end

    local diff = target - current
    local deadZone = 0.3
    local ad = math.abs(diff)
    if ad <= deadZone then
        return current, 0
    end

    local rem = ad - deadZone
    local boostStart = 3.0
    local maxPerMin = 2.0
    local minPerMin = 0.05
    local perMin
    if rem >= boostStart then
        perMin = maxPerMin
    else
        perMin = (rem / boostStart) * maxPerMin
        if perMin < minPerMin then perMin = minPerMin end
    end

    local step = math.min(perMin * minutes, rem)
    if diff < 0 then step = -step end
    return current + step, step
end

function TABAS_BathingBenefits.applyBodyTemperature(stats, waterTemp, minutes, ambientTemp)
    if not stats then return false, 0 end

    local bodyTemp = stats:get(CharacterStat.TEMPERATURE)
    local target = TABAS_BathingBenefits.getTemperatureTarget(waterTemp, ambientTemp)
    local nextTemp, delta = TABAS_BathingBenefits.stepTemperatureTowards(bodyTemp, target, minutes)
    if delta == 0 then
        return false, 0
    end

    if delta > 0 then
        stats:add(CharacterStat.TEMPERATURE, delta)
    else
        stats:remove(CharacterStat.TEMPERATURE, -delta)
    end
    return true, stats:get(CharacterStat.TEMPERATURE) - bodyTemp
end

function TABAS_BathingBenefits:apply()
    if not self.character then return end
    if self.character:isGodMod() then return end

    local stats = self.character:getStats()
    local bodyDamage = self.character:getBodyDamage()

    local soaked = (self.wornItemCount > 0) or (self.dirtyLevel > 30)
    local waterTemp = self.waterTemp or 22.0
    local amountRatio = self.amountRatio or 1
    local tempMultiplier = self.temperatureMultiplier or 1
    local dirtMultiplier = self.dirtMultiplier

    local changed = {}   -- key -> true
    local delta = {}     -- key -> number
    local function mark(key, d)
        changed[key] = true
        if d then delta[key] = (delta[key] or 0) + d end
    end

    for i=1, #self.benefits do
        local benefit = self.benefits[i]
        if benefit then
            if benefit == "UNHAPPINESS" and soaked then
                -- do nothing
            elseif benefit == "BOREDOM" and self.dirtyLevel > 30 then
                -- add boredom from dirty water
                if self.negativeBenefit and BenefitForStats.ADD_BOREDOM(stats, self.dirtyLevel * 0.25) then
                    local d = Factor.BOREDOM * (self.dirtyLevel * 0.25)
                    mark("BOREDOM", d)
                end
            elseif BenefitForStats[benefit] then
                if BenefitForStats[benefit](stats, tempMultiplier * dirtMultiplier) then
                    local d = (Factor[benefit] or 0) * tempMultiplier * dirtMultiplier
                    mark(benefit, benefit == "SANITY" and d or -d)
                end
            elseif BenefitForBody[benefit] then
                if BenefitForBody[benefit](bodyDamage, amountRatio * dirtMultiplier) then
                    local d = Factor[benefit] * dirtMultiplier
                    mark(benefit, d)
                end
            elseif BenefitsForChar[benefit] then
                if BenefitsForChar[benefit](self.character, dirtMultiplier) then
                    local d = Factor.SUSTAIN_PILL * dirtMultiplier
                    mark(benefit, d)
                end
            elseif BenefitForBodyParts[benefit] then
                local bodyParts = bodyDamage:getBodyParts()
                for j=0,BodyPartType.ToIndex(BodyPartType.MAX) - 1 do
                    local part = bodyParts:get(j)
                    if part then
                        if BenefitForBodyParts[benefit](part, tempMultiplier * dirtMultiplier) then
                            local d
                            if benefit == "INJURIES_SUSTAIN" or benefit == "FRACTURE_SUSTAIN" or benefit == "WOUND_INFECTION_SUSTAIN" then
                                d = Factor.SUSTAIN_COMPRESS * tempMultiplier * dirtMultiplier
                            else
                                d = Factor[benefit] * tempMultiplier * dirtMultiplier
                            end
                            mark(benefit, d)
                        end
                    end
                end
            end
        end
    end

    if not TABAS_Compat.RealisticTemperature then
        local changedTemp, tempDelta = TABAS_BathingBenefits.applyBodyTemperature(stats, waterTemp, 1.0)
        if changedTemp then
            mark("TEMPERATURE", tempDelta)
        end
    end

    -- provides a rest buff (endurance)
    if not stats:isAtMaximum(CharacterStat.ENDURANCE) then
        local curEdr = stats:get(CharacterStat.ENDURANCE)
        local fatigueMod = 1 - stats:get(CharacterStat.FATIGUE) * 0.8
        local recoveryMod = self.character:getRecoveryMod()
        local recovery = fatigueMod * recoveryMod * self.enduranceMultiplier
        stats:add(CharacterStat.ENDURANCE, recovery)
        local afterEdr = stats:get(CharacterStat.ENDURANCE)
        if afterEdr ~= curEdr then
            mark("ENDURANCE", afterEdr - curEdr)
        end
    end

    if TABAS_Utils.DEBUG_BENEFIT_PRINT then
        local function printChanged(prefix)
            local list = {}
            for k,_ in pairs(changed) do
                local d = delta[k]
                if d then
                    list[#list+1] = k .. "=" .. string.format("%.4f", d)
                else
                    list[#list+1] = k
                end
            end
            if #list > 0 then
                table.sort(list)
                print(prefix .. table.concat(list, " "))
            end
        end
        printChanged("[TABAS] benefits changed: ")
    end
end

function TABAS_BathingBenefits:rebuildBenefits()
    self.benefits = {}

    local base = TABAS_BathingBenefits.BaseBenefits[self.mode] or {}
    for i=1, #base do
        self.benefits[i] = base[i]
    end

    if self.bathSalt then
        local def = BathSaltDefs.BathSaltTypes[self.bathSalt]
        local bathSaltBenefits = BathSaltDefs.getBathSaltBenefits(def)
        for i=1, #bathSaltBenefits do
            table.insert(self.benefits, bathSaltBenefits[i])
        end
    end
end

function TABAS_BathingBenefits:setContext(context)
    context = context or {}

    self.wornItemCount = context.wornItemCount or 0
    self.dirtyLevel = context.dirtyLevel or 0
    self.waterTemp = context.waterTemp or 22.0
    self.amountRatio = context.amountRatio or 1

    self.dirtMultiplier = self.dirtyLevel < 20 and 1 or 0.2

    local tempDiff = self.waterTemp - 38
    if tempDiff < -1 then
        self.temperatureMultiplier = 0.5
    elseif tempDiff > 0 then
        self.temperatureMultiplier = math.min(3, 1 + tempDiff * 0.25)
    else
        self.temperatureMultiplier = 1
    end

    if self.bathSalt ~= context.bathSalt then
        self.bathSalt = context.bathSalt
        self:rebuildBenefits()
    end
end

-- mode = BATH | SHOWER
function TABAS_BathingBenefits:new(character, mode)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    if not character then return end

    o.character = character
    o.mode = mode
    o.bathSalt = nil
    o.wornItemCount = 0
    o.dirtyLevel = 0
    o.dirtMultiplier = 1
    o.waterTemp = 22.0
    o.temperatureMultiplier = 1
    o.amountRatio = 1
    o.benefits = {}

    local enduranceMod = (mode == "BATH") and 0.03 or 0.01
    local enduranceRegenMul = getSandboxOptions():getEnduranceRegenMultiplier()
    o.enduranceMultiplier = enduranceMod * enduranceRegenMul
    o.negativeBenefit = SandboxVars.TakeABathAndShower.DisableNegativeEffectsOfBathing
    o:rebuildBenefits()
    return o
end

return TABAS_BathingBenefits
