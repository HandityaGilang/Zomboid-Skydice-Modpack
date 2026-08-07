require "ISBaseObject"

local TABAS_BathingBenefits = ISBaseObject:derive("TABAS_BathingBenefits")

local TABAS_Utils = require("TABAS_Utils")
local BathSaltDefs = require("TABAS_BathSaltDefs")
local TABAS_GameTimes = require("TABAS_GameTimes")

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

function TABAS_BathingBenefits:apply(temperature, amountRatio)
    if self.character:isGodMod() then return end

    local md = self.character:getModData()
    if not md or not md.tabas_IsBathing then return end

    local benefitData = md.tabas_BathingBenefit
    if not benefitData then return end

    local nowHours = TABAS_GameTimes.getWorldAgeHours()
    local lastH = benefitData._lastH
    if not lastH then
        benefitData._lastH = nowHours
        return
    end

    local deltaH = nowHours - lastH
    if deltaH < 0 then deltaH = 0 end

    local maxDeltaH = 3/60
    if deltaH > maxDeltaH then deltaH = maxDeltaH end
    local m = deltaH * 60
    if m < 0.02 then return end

    benefitData._lastH = nowHours

    local discomfort = (self.wornItemCount > 0) or (self.dirtyLevel > 30)
    local comforted = md.tabas_Comforted == true
    local watched = md.tabas_FeelingGaze or 0
    local soaked = self.wornItemCount > 3

    local stats = self.character:getStats()
    local bodyDamage = self.character:getBodyDamage()

    local aMul = amountRatio or 1 -- water amount multiplier
    local tMul = 1 -- temperature multiplier
    local dMul = self.dirtMultiplier
    local tempeDiff = temperature - 38
    if tempeDiff < -1 then
        tMul = 0.5
    elseif tempeDiff > 0 then
        tMul = math.min(3, 1 + tempeDiff * 0.25)
    end

    local changed = {}   -- key -> true
    local delta = {}     -- key -> number
    local function mark(key, d)
        changed[key] = true
        if d then delta[key] = (delta[key] or 0) + d end
    end

    for i=1, #self.benefits do
        local benefit = self.benefits[i]
        if benefit then
            if benefit == "UNHAPPINESS" and (comforted or discomfort or soaked) then
                if discomfort or soaked then
                    -- do nothing
                else
                    if BenefitForStats.UNHAPPINESS(stats, m * 2 * tMul * dMul) then
                        local d = Factor.UNHAPPINESS * m * 2 * tMul * dMul
                        mark("UNHAPPINESS", -d)
                    end
                end
            elseif benefit == "STRESS" and watched > 0 then
                -- add stress from gaze
                if self.negativeBenefit and stats:add(CharacterStat.STRESS, Factor.STRESS * watched * m * 3) then
                    local d = Factor.STRESS * watched * m * 3
                    mark("UNHAPPINESS", d)
                end
            elseif benefit == "BOREDOM" and self.dirtyLevel > 30 then
                -- add boredom from dirty water
                if self.negativeBenefit and BenefitForStats.ADD_BOREDOM(stats, m * (self.dirtyLevel * 0.25)) then
                    local d = Factor.BOREDOM * m * (self.dirtyLevel * 0.25)
                    mark("BOREDOM", d)
                end
            elseif BenefitForStats[benefit] then
                if BenefitForStats[benefit](stats, m * tMul * dMul) then
                    local d = (Factor[benefit] or 0) * m * tMul * dMul
                    mark(benefit, benefit == "SANITY" and d or -d)
                end
            elseif BenefitForBody[benefit] then
                if BenefitForBody[benefit](bodyDamage, m * aMul * dMul) then
                    local d = Factor[benefit] * m * dMul
                    mark(benefit, d)
                end
            elseif BenefitsForChar[benefit] then
                if BenefitsForChar[benefit](self.character, m * dMul) then
                    local d = Factor.SUSTAIN_PILL * m * dMul
                    mark(benefit, d)
                end
            elseif BenefitForBodyParts[benefit] then
                local bodyParts = bodyDamage:getBodyParts()
                for j=0,BodyPartType.ToIndex(BodyPartType.MAX) - 1 do
                    local part = bodyParts:get(j)
                    if part then
                        if BenefitForBodyParts[benefit](part, m * tMul * dMul) then
                            local d
                            if benefit == "INJURIES_SUSTAIN" or benefit == "FRACTURE_SUSTAIN" or benefit == "WOUND_INFECTION_SUSTAIN" then
                                d = Factor.SUSTAIN_COMPRESS * m * tMul * dMul
                            else
                                d = Factor[benefit] * m * tMul * dMul
                            end
                            mark(benefit, d)
                        end
                    end
                end
            end
        end
    end

    -- Adjusts body temperature according to water temperature until a certain level of Moodles occurs.
    local curTemp = stats:get(CharacterStat.TEMPERATURE)
    local target
    if temperature >= 38.0 then
        if temperature >= 50 then target = 41.0
        elseif temperature >= 45 then target = 40.0
        elseif temperature >= 44 then target = 39.0
        elseif temperature >= 43 then target = 37.5
        else target = 37.0
        end
    else
        if temperature < 25 then target = 25.0
        elseif temperature < 35 then target = 30.0
        elseif temperature < 38 then target = 36.5
        else target = 36.5
        end
    end

    local diff = target - curTemp
    local deadZone = 0.3
    local ad = math.abs(diff)
    if ad > deadZone then
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

        local step = perMin * m
        if step > rem then step = rem end

        if diff > 0 then
            stats:add(CharacterStat.TEMPERATURE, step)
        else
            stats:remove(CharacterStat.TEMPERATURE, step)
        end
    end
    local afterTemp = stats:get(CharacterStat.TEMPERATURE)
    if afterTemp ~= curTemp then
        mark("TEMPERATURE", afterTemp - curTemp)
    end

    -- provides a rest buff (endurance)
    if not stats:isAtMaximum(CharacterStat.ENDURANCE) then
        local curEdr = stats:get(CharacterStat.ENDURANCE)
        local fatigueMod = 1 - stats:get(CharacterStat.FATIGUE) * 0.8
        local recoveryMod = self.character:getRecoveryMod()
        local recovery = fatigueMod * recoveryMod * self.enduranceMultiplier * m
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

-- mode = BATH | SHOWER
function TABAS_BathingBenefits:new(character, mode, bathSalt, dirtyLevel)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    if not character then return end
    local md = character:getModData()
    if not md or not md.tabas_IsBathing then return end

    o.character = character
    local wornItems = character:getWornItems()
    o.wornItemCount = TABAS_Utils.getWornClothesCountExcluded(wornItems, true)
    o.dirtyLevel = dirtyLevel or 0
    if o.dirtyLevel < 20 then
        o.dirtMultiplier = 1
    else
        o.dirtMultiplier = 0.2
    end

    o.benefits = {}
    local base = TABAS_BathingBenefits.BaseBenefits[mode]
    for i=1, #base do
        o.benefits[i] = base[i]
    end
    if bathSalt then
        local def = BathSaltDefs.BathSaltTypes[bathSalt]
        local bathSaltBenefits = BathSaltDefs.getBathSaltBenefits(def)
        for i=1, #bathSaltBenefits do
            table.insert(o.benefits, bathSaltBenefits[i])
        end
    end

    local enduranceMod = (mode == "BATH") and 0.03 or 0.01
    local enduranceRegenMul = getSandboxOptions():getEnduranceRegenMultiplier()
    o.enduranceMultiplier = enduranceMod * enduranceRegenMul
    o.negativeBenefit = SandboxVars.TakeABathAndShower.DisableNegativeEffectsOfBathing
    return o
end

return TABAS_BathingBenefits
