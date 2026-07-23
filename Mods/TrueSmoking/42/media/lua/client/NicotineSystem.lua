NicotineSystem = NicotineSystem or {}
NicotineSystem.__index = NicotineSystem

NicotineSystem.DefaultOptions = {
    DaysToDetox = 30,
    SmokerTraitDecayMultiplier = 0.65,
    DaysToAddiction = 42,
    DaysToPeakWithdrawal = 3,
}

NicotineSystem.Options = NicotineSystem.DefaultOptions

NicotineSystem.Config = {
    ACTIVE_SMOKING_BONUS            = 2.2,
    EXERCISE_DECAY_BONUS_MULTIPLIER = 1.3,

    ADDICTION_GAIN_PER_MINUTE       = 0.00045,
    ADDICTION_GAIN_PER_PUFF         = 0.88,

    WITHDRAWAL_GAIN_PER_MINUTE      = 0.020,
    WITHDRAWAL_RELIEF_PER_PUFF      = 11.0,
    WITHDRAWAL_NICOTINE_RELIEF_RATE = 0.07,
    WITHDRAWAL_PEAK_GAIN_PER_MINUTE = 0.02315,

    NICOTINE_THRESHOLD              = 8.0,
    NICOTINE_DECAY_PER_MINUTE       = 0.005,

    SMOKER_TRAIT_GAIN_THRESHOLD     = 70,
    SMOKER_TRAIT_LOSE_THRESHOLD     = 15,

    UNHAPPYNESS_FROM_WITHDRAWAL     = 0.35,
    BOREDOM_FROM_WITHDRAWAL         = 0.45,
    FATIGUE_FROM_NICOTINE           = 0.00195,
    HUNGER_FROM_NICOTINE            = 0.00115,
    STRESS_FROM_NICOTINE            = 0.00012,

    OVERFLOW_LEAK_RATE            = 0.05,
}

function NicotineSystem:UpdateDynamicConfig(player)
    local daysToZero    = math.max(1, self.Options.DaysToDetox or 30)
    local daysToAddict  = math.max(1, self.Options.DaysToAddiction or 42)
    local daysToPeak    = math.max(1, self.Options.DaysToPeakWithdrawal or 3)
    local avgCigsPerDay = 3
    local maxAddiction  = 100

    local data          = player:getModData().nicotineSystem
    if not data then
        self:initialize(player)
        data = player:getModData().nicotineSystem
    end

    local minutesInDetox                          = daysToZero * 24 * 60
    local baseDecay                               = data.addictionLevel / minutesInDetox
    self.Config.ADDICTION_DECAY_PER_MINUTE        = baseDecay
    self.Config.ADDICTION_DECAY_PER_MINUTE_SMOKER = baseDecay * self.Options.SmokerTraitDecayMultiplier

    local totalCigsToCap                          = avgCigsPerDay * daysToAddict
    local addictionPerCig                         = maxAddiction / totalCigsToCap * 1.15 -- +15% buffer for feel

    self.Config.ADDICTION_PER_CIGARETTE           = addictionPerCig

    local passiveDaily                            = 3.0 / daysToAddict
    self.Config.ADDICTION_GAIN_PER_MINUTE         = math.max(0.00001, passiveDaily / 1440)

    local minutesToPeak = daysToPeak * 24 * 60
    local basePeakGain  = 100 / minutesToPeak

    self.Config.WITHDRAWAL_PEAK_GAIN_PER_MINUTE = basePeakGain / 1.5
end

function NicotineSystem:initialize(player)
    local data = player:getModData()
    if not data.nicotineSystem then
        data.nicotineSystem = {
            nicotineLevel   = 0,
            addictionLevel  = player:HasTrait("Smoker") and self.Config.SMOKER_TRAIT_GAIN_THRESHOLD * 1.2 or 0,
            withdrawalLevel = player:HasTrait("Smoker") and 35 or 0,
            AddictionTime   = 0,
            nicotineTime    = 0,
            unhappinessCap  = 0,
            boredomCap      = 0,
            nicotineOverflow = 0,
        }
    else
        local defaults = {
            nicotineLevel   = 0,
            addictionLevel  = 0,
            withdrawalLevel = 0,
            AddictionTime   = 0,
            nicotineTime    = 0,
            unhappinessCap  = 0,
            boredomCap      = 0,
            nicotineOverflow = 0,
        }
        for field, defaultValue in pairs(defaults) do
            if data.nicotineSystem[field] == nil then
                data.nicotineSystem[field] = defaultValue
            end
        end
    end
end

Events.OnCreatePlayer.Add(function(_, player)
    NicotineSystem:initialize(player)
    NicotineSystem:UpdateDynamicConfig(player)
end)

function NicotineSystem:GameTimeUpdate(player)
    if not player or player:isDead() then return end

    local data = player:getModData().nicotineSystem
    if not data then
        self:initialize(player)
        data = player:getModData().nicotineSystem
    end

    local stats     = player:getStats()
    local bd        = player:getBodyDamage()
    local tableRef  = TrueSmoking and TrueSmoking:getPlayerReference(player)
    local isSmoking = tableRef and tableRef.Smokable and tableRef.Smokable.smokeLit
    local lastSmoke = player:getTimeSinceLastSmoke()

    if not isSmoking then
        data.nicotineLevel = data.nicotineLevel * (1 - self.Config.NICOTINE_DECAY_PER_MINUTE)
        data.nicotineLevel = math.max(0, data.nicotineLevel)
        if data.nicotineOverflow > 0 then
            local leakAmount = data.nicotineOverflow * self.Config.OVERFLOW_LEAK_RATE
            if data.nicotineLevel + leakAmount > 100 then
                leakAmount = 100 - data.nicotineLevel
                data.nicotineLevel = 100
                data.nicotineLevel = math.min(100, data.nicotineLevel + leakAmount)
            else
                data.nicotineLevel = data.nicotineLevel + leakAmount
            end
            data.nicotineOverflow = data.nicotineOverflow - leakAmount
        end
    end

    if data.nicotineLevel > 0.01 then
        local minutesToZero = data.nicotineLevel / self.Config.NICOTINE_DECAY_PER_MINUTE
        local hoursToZero   = minutesToZero / 10 / 60

        data.nicotineTime   = math.floor(hoursToZero * 10 + 0.5) / 10 / .6
    else
        data.nicotineTime = 0.0
    end

    local lowNicotine = data.nicotineLevel < self.Config.NICOTINE_THRESHOLD

    if lowNicotine and data.addictionLevel > 8 then
        local intensityMultiplier = 1.0 + (data.addictionLevel / 100) * 0.5

        local hoursSinceLastSmoke = lastSmoke
        local earlyBoost = math.min(hoursSinceLastSmoke / 24, 2.0)
        intensityMultiplier = intensityMultiplier + earlyBoost * 0.15

        local gain = self.Config.WITHDRAWAL_PEAK_GAIN_PER_MINUTE * intensityMultiplier

        data.withdrawalLevel = math.min(100, data.withdrawalLevel + gain)
    else
        local relief = 0
        if isSmoking then
            relief = self.Config.WITHDRAWAL_RELIEF_PER_PUFF
        elseif data.nicotineLevel > 20 then
            relief = self.Config.WITHDRAWAL_NICOTINE_RELIEF_RATE * (data.nicotineLevel / 100)
        end
        data.withdrawalLevel = math.max(0, data.withdrawalLevel - relief)
    end

    if data.withdrawalLevel > 1 then
        local w = data.withdrawalLevel / 100
        local unhappinessCap = 20 + w
        local boredomCap = 25 + w

        data.unhappinessCap = unhappinessCap
        data.boredomCap = boredomCap

        if bd:getUnhappynessLevel() < unhappinessCap then
            bd:setUnhappynessLevel(math.min(unhappinessCap, bd:getUnhappynessLevel() + self.Config.UNHAPPYNESS_FROM_WITHDRAWAL))
        end
        if bd:getBoredomLevel() < boredomCap then
            bd:setBoredomLevel(math.min(boredomCap, bd:getBoredomLevel() + self.Config.BOREDOM_FROM_WITHDRAWAL))
        end
    end

    if data.nicotineLevel > 5 then
        local strength = math.min(data.nicotineLevel / 100, 1.0) -- 0–1 scale

        local fatigueReduction = self.Config.FATIGUE_FROM_NICOTINE * strength -- ~0.025 per minute at full nicotine
        stats:setFatigue(math.max(0, stats:getFatigue() - fatigueReduction))

        local hungerReduction = self.Config.HUNGER_FROM_NICOTINE * strength -- ~0.00054 per minute → ~0.78 per day at max
        stats:setHunger(math.max(0, stats:getHunger() - hungerReduction))

        if stats:getStress() > 0 then
            stats:setStress(math.max(0, (stats:getStress() - stats:getStressFromCigarettes()) - (self.Config.STRESS_FROM_NICOTINE * strength)))
        end
    end

    if data.nicotineLevel > 8 then
        local gain = self.Config.ADDICTION_GAIN_PER_MINUTE
        if isSmoking then gain = gain * self.Config.ACTIVE_SMOKING_BONUS end
        local factor = math.min(data.nicotineLevel / 60, 1.6)
        data.addictionLevel = data.addictionLevel + (gain * factor)
    else
        if lowNicotine and data.withdrawalLevel >= 0 and not isSmoking then
            if not self.Config.ADDICTION_DECAY_PER_MINUTE then self:UpdateDynamicConfig(player) end
            local baseDecay = player:HasTrait("Smoker")
                and self.Config.ADDICTION_DECAY_PER_MINUTE_SMOKER
                or self.Config.ADDICTION_DECAY_PER_MINUTE

            local fatigue = player:getStats():getFatigue()
            local exerciseBonus = 1.0
            if fatigue > 0.7 then
                local bonusStrength = (fatigue - 0.7) / 0.3
                exerciseBonus = 1.0 + bonusStrength * (self.Config.EXERCISE_DECAY_BONUS_MULTIPLIER - 1.0)
            end

            local finalDecay = baseDecay * exerciseBonus
            data.addictionLevel = math.max(0, data.addictionLevel - finalDecay)

            if data.addictionLevel > 0 then
                local minutesLeft = data.addictionLevel / finalDecay
                data.AddictionTime = math.ceil(minutesLeft / 1440 * 10) / 10
            end
        end
    end

    if TrueSmoking and TrueSmoking.Options and TrueSmoking.Options.DynamicSmokerTrait then
        if data.addictionLevel >= self.Config.SMOKER_TRAIT_GAIN_THRESHOLD and not player:HasTrait("Smoker") then
            player:getTraits():add("Smoker")
            if HaloTextHelper then
                HaloTextHelper.addTextWithArrow(player, getText("UI_TRUESMOKING_BECAME_SMOKER"), true,
                    HaloTextHelper.getColorRed())
            end
        elseif data.addictionLevel < self.Config.SMOKER_TRAIT_LOSE_THRESHOLD and player:HasTrait("Smoker") then
            player:getTraits():remove("Smoker")
            stats:setStressFromCigarettes(0)
            data.boredomCap = 0
            data.unhappinessCap = 0
            if HaloTextHelper then
                HaloTextHelper.addTextWithArrow(player, getText("UI_TRUESMOKING_QUIT_SMOKING"), true,
                    HaloTextHelper.getColorGreen())
            end
        end
    end
end

function NicotineSystem:smoke(player, rawAmountPerPuff, nicotineContent)
    local data = player:getModData().nicotineSystem
    if not data then return end

    local maxAddiction = 100
    local puffFraction = rawAmountPerPuff / nicotineContent

    local tolerance = math.min(data.addictionLevel / 100, 0.25)
    local effectiveIntake = rawAmountPerPuff * (1.0 - tolerance)

    if data.nicotineLevel > 70 then
        local reduction = (data.nicotineLevel - 70) / 50
        effectiveIntake = effectiveIntake * (1 - math.min(reduction, 0.65))
    end

    if data.nicotineLevel + effectiveIntake > 100 then
        local overflow = (data.nicotineLevel + effectiveIntake) - 100
        data.nicotineOverflow = data.nicotineOverflow + overflow
        data.nicotineLevel = 100
    else
        data.nicotineLevel = data.nicotineLevel + effectiveIntake
    end

    data.withdrawalLevel = math.max(0, data.withdrawalLevel - self.Config.WITHDRAWAL_RELIEF_PER_PUFF * puffFraction)

    local addictionTolerance = data.addictionLevel / maxAddiction
    local effectiveGain = self.Config.ADDICTION_GAIN_PER_PUFF * puffFraction *
        (1.0 - math.min(addictionTolerance * 0.85, 0.85))

    data.addictionLevel = math.min(maxAddiction, data.addictionLevel + effectiveGain)
end
