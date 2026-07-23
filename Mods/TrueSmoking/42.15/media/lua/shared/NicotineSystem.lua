--[[
    NicotineSystem.lua - Nicotine System Configuration (Single Source of Truth)
    
    Defines all nicotine system constants and provides initialization.
    Server-side processing is in server/Nicotine.lua.
    
    This is the ONLY place NicotineSystem.Config should be defined.
]]

require 'Core'
require 'Data'

NicotineSystem = NicotineSystem or {}
NicotineSystem.__index = NicotineSystem

--------------------------------------------------------------------------------
-- Default Options (overwritten by sandbox settings in Init.lua)
--------------------------------------------------------------------------------

NicotineSystem.DefaultOptions = {
    DaysToDetox = 30,                    -- Days to lose 100% addiction (constant decay rate)
    DaysToAddiction = 42,                -- Days of regular smoking to max addiction
    DaysToPeakWithdrawal = 3,            -- Days to reach peak withdrawal
    SmokerTraitDecayMultiplier = 0.75,   -- Smoker trait slows decay by 25%
}

NicotineSystem.Options = TrueSmoking.deepCopy(NicotineSystem.DefaultOptions)

--------------------------------------------------------------------------------
-- Configuration Constants
--------------------------------------------------------------------------------

NicotineSystem.Config = {
    -- Smoking bonuses
    ACTIVE_SMOKING_BONUS            = 2.2,   -- Addiction gain multiplier while smoking
    EXERCISE_DECAY_BONUS_MULTIPLIER = 1.3,   -- Faster addiction decay when exercising
    
    -- Addiction rates (per-minute base values, scaled by sandbox settings)
    ADDICTION_GAIN_PER_MINUTE       = 0.00045,
    ADDICTION_GAIN_PER_PUFF         = 0.88,
    ADDICTION_DECAY_PER_MINUTE      = 0.0001,    -- Recalculated dynamically
    ADDICTION_DECAY_PER_MINUTE_SMOKER = 0.00007,
    ADDICTION_PER_CIGARETTE         = 0.8,
    
    -- Withdrawal rates
    WITHDRAWAL_GAIN_PER_MINUTE      = 0.010,     -- Base rate when addicted
    WITHDRAWAL_RELIEF_PER_PUFF      = 0.55,      -- Per actual puff action
    WITHDRAWAL_RELIEF_PER_MINUTE    = 2.5,       -- Per minute while actively smoking
    WITHDRAWAL_NICOTINE_RELIEF_RATE = 0.14,      -- Relief from high nicotine level
    WITHDRAWAL_PEAK_GAIN_PER_MINUTE = 0.01157,   -- Tuned for ~1-2 day progression to peak
    
    -- Nicotine thresholds
    NICOTINE_THRESHOLD              = 8.0,       -- Below this, withdrawal kicks in
    NICOTINE_DECAY_PER_MINUTE       = 0.00694,   -- ~100 minute half-life (more realistic)
    OVERFLOW_LEAK_RATE              = 0.05,      -- How fast excess nicotine leaks back
    
    -- Dynamic Smoker trait thresholds
    SMOKER_TRAIT_GAIN_THRESHOLD     = 70,        -- Addiction level to gain Smoker trait
    SMOKER_TRAIT_LOSE_THRESHOLD     = 15,        -- Addiction level to lose Smoker trait
    
    -- Passive effects per minute (minor, mostly for nicotine system immersion)
    UNHAPPINESS_FROM_WITHDRAWAL     = 0.25,      -- Reduced for less crippling withdrawal
    BOREDOM_FROM_WITHDRAWAL         = 0.35,      -- Reduced for less crippling withdrawal
    FATIGUE_FROM_NICOTINE           = 0.0025,   -- Applied only above threshold, higher impact
    HUNGER_FROM_NICOTINE            = 0.0025,   -- Applied only above threshold, higher impact
    STRESS_FROM_NICOTINE            = 0.0017,    -- 0.10 total at 100% nicotine over ~100min half-life
    NICOTINE_EFFECT_THRESHOLD       = 45,        -- Lowered threshold for more accessible buffs
}

--------------------------------------------------------------------------------
-- Dynamic Configuration
--------------------------------------------------------------------------------

--- Recalculate decay rates based on player addiction level and sandbox options
-- @param player IsoPlayer
function NicotineSystem:UpdateDynamicConfig(player)
    local daysToZero    = math.max(1, self.Options.DaysToDetox or 30)
    local daysToAddict  = math.max(1, self.Options.DaysToAddiction or 42)
    local daysToPeak    = math.max(1, self.Options.DaysToPeakWithdrawal or 3)
    local avgCigsPerDay = 3
    local maxAddiction  = 100

    local data = TrueSmoking.Data.getNicotine(player)
    if not data then return end

    -- Constant decay rate: 100% addiction lost over daysToZero
    local minutesInDetox = daysToZero * 24 * 60
    local baseDecay = 100 / minutesInDetox  -- 0.00231 for 30 days
    self.Config.ADDICTION_DECAY_PER_MINUTE = baseDecay
    self.Config.ADDICTION_DECAY_PER_MINUTE_SMOKER = baseDecay * self.Options.SmokerTraitDecayMultiplier

    local totalCigsToCap = avgCigsPerDay * daysToAddict
    self.Config.ADDICTION_PER_CIGARETTE = (maxAddiction / totalCigsToCap) * 1.15

    local passiveDaily = 3.0 / daysToAddict
    self.Config.ADDICTION_GAIN_PER_MINUTE = math.max(0.00001, passiveDaily / 1440)

    local minutesToPeak = daysToPeak * 24 * 60
    -- For 1-2 day flow: 1.5 days = 2160 minutes to reach 100 withdrawal
    -- Base rate: 100 / 2160 = ~0.046 per minute
    -- With intensity multipliers (1.0-2.0x), effective rate is 0.046-0.092
    -- Divide by 4 for gentler progression
    self.Config.WITHDRAWAL_PEAK_GAIN_PER_MINUTE = (100 / (1.5 * 24 * 60)) / 4
end

--- Initialize nicotine data for a player
-- Delegates to Data.getNicotine which handles all initialization logic
-- @param player IsoPlayer
function NicotineSystem:initialize(player)
    -- Data.getNicotine handles initialization with proper defaults
    TrueSmoking.Data.getNicotine(player)
end

--------------------------------------------------------------------------------
-- Event Registration
--------------------------------------------------------------------------------

Events.OnCreatePlayer.Add(function(_, player)
    NicotineSystem:initialize(player)
    NicotineSystem:UpdateDynamicConfig(player)
end)
