--[[
    Nicotine.lua - Server-Side Nicotine Processing
    
    Handles server-authoritative nicotine calculations:
    - Puff processing (addiction gain, withdrawal relief)
    - Passive decay (nicotine level, addiction level)
    - Withdrawal effects (boredom, unhappiness)
    - Dynamic Smoker trait management
    
    Configuration is defined in shared/NicotineSystem.lua
    This file only adds server-specific processing functions.
]]

require 'Core'
require 'Data'
require 'NicotineSystem'  -- Load shared config

--- Server-side initialization ensures UpdateDynamicConfig runs
-- The shared NicotineSystem.lua defines UpdateDynamicConfig with the correct formula
-- This wrapper ensures it's called on the server when a player connects
-- @param player IsoPlayer
function NicotineSystem:initializeServer(player)
    -- Data.getNicotine handles initialization
    TrueSmoking.Data.getNicotine(player)
    
    -- Call the shared UpdateDynamicConfig to set correct decay rates
    -- This is critical in MP where the shared OnCreatePlayer event doesn't run on dedicated server
    if self.UpdateDynamicConfig then
        self:UpdateDynamicConfig(player)
        TrueSmoking.debug(string.format('Server: Initialized decay rates - ADDICTION_DECAY_PER_MINUTE=%.6f', 
            self.Config.ADDICTION_DECAY_PER_MINUTE or 0))
    end
end

--------------------------------------------------------------------------------
-- Puff Processing (Client → Server)
--------------------------------------------------------------------------------

TrueSmoking.Nicotine = TrueSmoking.Nicotine or {}

--- Process a single puff and apply nicotine effects
-- @param player IsoPlayer
-- @param nicotineContent number Base nicotine content of the item
-- @param puffPercent number Percentage of item consumed (0.0-1.0)
function TrueSmoking.Nicotine.applyPuff(player, nicotineContent, puffPercent)
    local data = TrueSmoking.Data.getNicotine(player)
    if not data then return end
    
    local cfg = NicotineSystem.Config
    local rawAmount = nicotineContent * puffPercent
    local puffFraction = rawAmount / math.max(nicotineContent, 1)
    
    -- Full nicotine intake (tolerance removed for realism)
    local effectiveIntake = rawAmount
    
    -- Diminishing returns at high nicotine (overflow handling)
    if data.nicotineLevel > 85 then
        local reduction = (data.nicotineLevel - 85) / 25
        effectiveIntake = effectiveIntake * (1 - math.min(reduction, 0.5))
    end
    
    -- Apply nicotine with overflow handling
    if data.nicotineLevel + effectiveIntake > 100 then
        data.nicotineOverflow = data.nicotineOverflow + (data.nicotineLevel + effectiveIntake - 100)
        data.nicotineLevel = 100
    else
        data.nicotineLevel = data.nicotineLevel + effectiveIntake
    end
    
    -- Reduce withdrawal
    data.withdrawalLevel = math.max(0, data.withdrawalLevel - cfg.WITHDRAWAL_RELIEF_PER_PUFF * puffFraction)
    
    -- Increase addiction (consistent gain rate)
    local effectiveGain = cfg.ADDICTION_GAIN_PER_PUFF * puffFraction
    data.addictionLevel = math.min(100, data.addictionLevel + effectiveGain)
end

--- Process all buffered puffs from client
-- Called from SmokingSystem on minute tick and when receiving BufferedPuffs command
-- @param player IsoPlayer
function TrueSmoking.Nicotine.processPuffBuffer(player)
    local smokingData = TrueSmoking.Data.getSmoking(player)
    if not smokingData or not smokingData.puffBuffer then return end
    
    local buffer = smokingData.puffBuffer
    if #buffer == 0 then return end
    
    -- TrueSmoking.debug('Processing ' .. #buffer .. ' buffered puffs')
    
    for _, puff in ipairs(buffer) do
        TrueSmoking.Nicotine.applyPuff(player, puff.nicotineContent, puff.puffPercent)
    end
    
    -- Clear buffer
    smokingData.puffBuffer = {}
    
    -- Sync back to client
    if isServer() then
        TrueSmoking.Nicotine.syncToClient(player)
    end
end

--- Sync nicotine data to client
-- @param player IsoPlayer
function TrueSmoking.Nicotine.syncToClient(player)
    local data = TrueSmoking.Data.getNicotine(player)
    if not data or not isServer() then return end
    
    sendServerCommand(player, 'TrueSmoking', 'SyncNicData', {
        requested = true,
        nicotineLevel = data.nicotineLevel,
        nicotineOverflow = data.nicotineOverflow,
        withdrawalLevel = data.withdrawalLevel,
        addictionLevel = data.addictionLevel,
        addictionTime = data.addictionTime,
        nicotineTime = data.nicotineTime,
        unhappinessCap = data.unhappinessCap,
        boredomCap = data.boredomCap,
    })
end

--------------------------------------------------------------------------------
-- Minute Tick Processing
--------------------------------------------------------------------------------

--- Process nicotine decay, withdrawal, and effects for a player
-- Called every game minute from SmokingSystem
-- @param player IsoPlayer
function TrueSmoking.Nicotine.updatePlayer(player)
    if not player then return end
    
    local data = TrueSmoking.Data.getNicotine(player)
    if not data then return end
    
    local cfg = NicotineSystem.Config
    local stats = player:getStats()
    local smokingData = TrueSmoking.Data.getSmoking(player)
    local isSmoking = smokingData and smokingData.isSmoking
    
    -- Process any buffered puffs
    TrueSmoking.Nicotine.processPuffBuffer(player)
    
    -- Only decay when not actively smoking
    if not isSmoking then
        -- Nicotine decay (exponential half-life)
        local decayMultiplier = 1 - cfg.NICOTINE_DECAY_PER_MINUTE
        data.nicotineLevel = math.max(0, data.nicotineLevel * decayMultiplier)
        
        -- Overflow leak into main nicotine
        if data.nicotineOverflow > 0 then
            local leak = data.nicotineOverflow * cfg.OVERFLOW_LEAK_RATE
            local space = 100 - data.nicotineLevel
            if space > 0 then
                leak = math.min(leak, space)
                data.nicotineLevel = math.min(100, data.nicotineLevel + leak)
                data.nicotineOverflow = math.max(0, data.nicotineOverflow - leak)
            end
        end
        
        -- Update time estimate (approximate time to reach ~1% nicotine)
        if data.nicotineLevel > 1 then
            -- Exponential decay: time = ln(current/target) / ln(1 + rate)
            -- Approximate to ~1% nicotine for practical "time until depleted"
            local decayRate = cfg.NICOTINE_DECAY_PER_MINUTE
            local minutesToNearZero = math.log(data.nicotineLevel / 1.0) / math.log(1.0 + decayRate)
            -- Convert to hours (game time), accounting for EveryOneMinute = 1 game minute
            data.nicotineTime = minutesToNearZero / 60
        else
            data.nicotineTime = 0
        end
    end
    
    local lowNicotine = data.nicotineLevel < cfg.NICOTINE_THRESHOLD
    
    -- Withdrawal effects when low on nicotine and addicted
    if lowNicotine and data.addictionLevel > 8 and not isSmoking then
        local w = data.withdrawalLevel / 100
        data.unhappinessCap = 20 * w
        data.boredomCap = 25 * w
        
        -- Apply unhappiness/boredom up to cap
        if stats:get(CharacterStat.UNHAPPINESS) < data.unhappinessCap then
            stats:set(CharacterStat.UNHAPPINESS, math.min(data.unhappinessCap,
                stats:get(CharacterStat.UNHAPPINESS) + cfg.UNHAPPINESS_FROM_WITHDRAWAL))
        end
        if stats:get(CharacterStat.BOREDOM) < data.boredomCap then
            stats:set(CharacterStat.BOREDOM, math.min(data.boredomCap,
                stats:get(CharacterStat.BOREDOM) + cfg.BOREDOM_FROM_WITHDRAWAL))
        end
        
        -- Increase withdrawal
        local intensity = 1.0 + (data.addictionLevel / 100) * 0.5
        local hoursSinceSmoke = player:getTimeSinceLastSmoke()
        intensity = intensity + math.min(hoursSinceSmoke / 24, 2.0) * 0.15
        data.withdrawalLevel = math.min(100, data.withdrawalLevel + cfg.WITHDRAWAL_PEAK_GAIN_PER_MINUTE * intensity)
    else
        -- Relief from withdrawal when nicotine is high or actively smoking
        local relief = 0
        if isSmoking then
            -- Active smoking provides significant withdrawal relief
            relief = cfg.WITHDRAWAL_RELIEF_PER_MINUTE or 2.5
        elseif data.nicotineLevel > 20 then
            -- High nicotine level provides passive relief
            relief = cfg.WITHDRAWAL_NICOTINE_RELIEF_RATE * (data.nicotineLevel / 100)
        end
        data.withdrawalLevel = math.max(0, data.withdrawalLevel - relief)
    end
    
    -- Threshold-based nicotine benefits (higher impact, shorter duration)
    if data.nicotineLevel >= (cfg.NICOTINE_EFFECT_THRESHOLD or 70) then
        -- Calculate strength based on how far above threshold (70-100 range)
        local threshold = cfg.NICOTINE_EFFECT_THRESHOLD or 70
        local strength = math.min((data.nicotineLevel - threshold) / (100 - threshold), 1.0)

        -- Get sandbox multipliers (default 0.25 for subtle effect)
        local fatigueMult = TrueSmoking.Options.FatigueReduction or 0.25
        local hungerMult = TrueSmoking.Options.HungerReduction or 0.25

        -- Higher impact fatigue reduction (only above threshold, scaled by sandbox option)
        local currentFatigue = stats:get(CharacterStat.FATIGUE)
        if currentFatigue > 0 and fatigueMult > 0 then
            stats:set(CharacterStat.FATIGUE, math.max(0, currentFatigue - cfg.FATIGUE_FROM_NICOTINE * strength * fatigueMult))
        end

        -- Higher impact hunger suppression (only above threshold, scaled by sandbox option)
        local currentHunger = stats:get(CharacterStat.HUNGER)
        if currentHunger > 0 and hungerMult > 0 then
            stats:set(CharacterStat.HUNGER, math.max(0, currentHunger - cfg.HUNGER_FROM_NICOTINE * strength * hungerMult))
        end
    end
    
    -- Passive stress relief scales with nicotine level (0.10 total at 100% nicotine)
    if data.nicotineLevel > 5 then
        local strength = math.min(data.nicotineLevel / 100, 1.0)
        local currentStress = stats:get(CharacterStat.STRESS)
        if currentStress > 0 then
            stats:set(CharacterStat.STRESS, math.max(0, currentStress - cfg.STRESS_FROM_NICOTINE * strength))
        end
    end

    -- Suppress vanilla stress buildup while nicotine is active
    -- This prevents rapid stress spike when nicotine depletes by keeping vanilla counters low
    -- Once nicotine drops below threshold, stressFromCigarettes and timeSinceLastSmoke accumulate naturally from 0
    local STRESS_SUPPRESSION_THRESHOLD = 55
    if data.nicotineLevel >= STRESS_SUPPRESSION_THRESHOLD then
        -- Reset vanilla stress counters while nicotine is satisfying the craving
        if stats.setStressFromCigarettes then
            stats:setStressFromCigarettes(0)
        end
        if player.setTimeSinceLastSmoke then
            player:setTimeSinceLastSmoke(0)
        end
    end

    -- Passive addiction gain when nicotine levels are sufficient (whether smoking or not)
    if data.nicotineLevel >= cfg.NICOTINE_THRESHOLD then
        local baseGain = cfg.ADDICTION_GAIN_PER_MINUTE
        local factor = math.min(data.nicotineLevel / 60, 1.6)
        
        -- Active smoking provides bonus multiplier
        if isSmoking then
            baseGain = baseGain * cfg.ACTIVE_SMOKING_BONUS
        end
        
        data.addictionLevel = math.min(100, data.addictionLevel + baseGain * factor)
    end
    
    -- Addiction decay when in withdrawal
    if lowNicotine and data.withdrawalLevel >= 0 and not isSmoking then
        -- Ensure decay rate is properly initialized (critical for MP server)
        -- The default value is 0.0001, correct value for 30 days is ~0.00231
        if not cfg.ADDICTION_DECAY_PER_MINUTE or cfg.ADDICTION_DECAY_PER_MINUTE < 0.001 then
            NicotineSystem:UpdateDynamicConfig(player)
        end
        
        local baseDecay = player:hasTrait(CharacterTrait.SMOKER) 
            and cfg.ADDICTION_DECAY_PER_MINUTE_SMOKER 
            or cfg.ADDICTION_DECAY_PER_MINUTE
        
        -- Exercise bonus
        local fatigue = stats:get(CharacterStat.FATIGUE)
        local exerciseBonus = 1.0
        if fatigue > 0.7 then
            exerciseBonus = 1.0 + ((fatigue - 0.7) / 0.3) * (cfg.EXERCISE_DECAY_BONUS_MULTIPLIER - 1.0)
        end
        
        local finalDecay = baseDecay * exerciseBonus
        data.addictionLevel = math.max(0, data.addictionLevel - finalDecay)
        
        -- Time estimate (approximate days to reach ~1% addiction)
        if data.addictionLevel > 1 then
            -- Linear decay to ~1% addiction for practical "time until clean"
            local minutesToNearZero = (data.addictionLevel - 1.0) / finalDecay
            -- Convert to days, accounting for EveryOneMinute = 1 game minute
            data.addictionTime = math.ceil(minutesToNearZero / (60 * 24) * 10) / 10
        else
            data.addictionTime = 0
        end
    end
    
    -- Dynamic SMOKER trait
    if TrueSmoking.Options and TrueSmoking.Options.DynamicSmokerTrait then
        if data.addictionLevel >= cfg.SMOKER_TRAIT_GAIN_THRESHOLD and not player:hasTrait(CharacterTrait.SMOKER) then
            player:getCharacterTraits():add(CharacterTrait.SMOKER)
            data.traitMessageShown = nil  -- Reset flag when gaining trait
            -- Sync trait change to client in MP
            sendServerCommand(player, 'TrueSmoking', 'addTrait', { 'SMOKER' })
            if HaloTextHelper then
                HaloTextHelper.addTextWithArrow(player, getText('UI_TRUESMOKING_BECAME_SMOKER'), true, HaloTextHelper.getColorRed())
            end
        elseif data.addictionLevel < cfg.SMOKER_TRAIT_LOSE_THRESHOLD and player:hasTrait(CharacterTrait.SMOKER) then
            player:getCharacterTraits():remove(CharacterTrait.SMOKER)
            stats:reset(CharacterStat.NICOTINE_WITHDRAWAL)
            data.boredomCap = 0
            data.unhappinessCap = 0
            -- Sync trait change to client in MP
            sendServerCommand(player, 'TrueSmoking', 'removeTrait', { 'SMOKER' })
            -- Only show message once per trait loss
            if not data.traitMessageShown then
                data.traitMessageShown = true
                if HaloTextHelper then
                    HaloTextHelper.addTextWithArrow(player, getText('UI_TRUESMOKING_QUIT_SMOKING'), true, HaloTextHelper.getColorGreen())
                end
            end
        elseif data.addictionLevel >= cfg.SMOKER_TRAIT_LOSE_THRESHOLD then
            -- Reset message flag when addiction goes back above threshold
            data.traitMessageShown = nil
        end
    end
    
    -- Sync all nicotine data changes back to client in MP
    if isServer() then
        TrueSmoking.Nicotine.syncToClient(player)
    end
end

--------------------------------------------------------------------------------
-- Event Registration
--------------------------------------------------------------------------------

Events.OnCreatePlayer.Add(function(_, player)
    NicotineSystem:initializeServer(player)
end)
