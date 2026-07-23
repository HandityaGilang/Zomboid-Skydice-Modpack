--[[
    Moodles.lua - Moodle Display Handler (Refactored)

    Updates smoking and nicotine moodles for all active players.
    Uses MoodleFramework for custom moodle rendering.
]]

require 'MF_ISMoodle'
require 'Core'
require 'Data'

--------------------------------------------------------------------------------
-- Moodle Setup
--------------------------------------------------------------------------------

MF.createMoodle('TS_Smoking_New')
MF.createMoodle('TS_Smoking_Old')
MF.createMoodle('TS_Nicotine')
MF.createMoodle('TS_Nicotine_Old')

--- Get the active smoking moodle ID based on UseNewMoodle option
local function getSmokingMoodleId()
    if TrueSmoking.Options.UseNewMoodle == false then
        return 'TS_Smoking_Old'
    end
    return 'TS_Smoking_New'
end

--- Get the active nicotine moodle ID based on UseNewMoodle option
local function getNicotineMoodleId()
    if TrueSmoking.Options.UseNewMoodle == false then
        return 'TS_Nicotine_Old'
    end
    return 'TS_Nicotine'
end

--------------------------------------------------------------------------------
-- Smoking Moodle
--------------------------------------------------------------------------------

--- Check if a MoodleFramework moodle's ModData is initialized and safe to use
-- MF.getMoodle() can return a stale object before OnCreatePlayer has initialized
-- the player's ModData, causing null index errors inside setValue/getValue.
local function isMoodleReady(player, moodleId)
    local modData = player:getModData()
    return modData and modData.Moodles and modData.Moodles[moodleId]
end

--- Update the smoking progress moodle
-- @param player IsoPlayer
function TrueSmoking.updateSmokingMoodle(player)
    if player:isDead() then return end

    local playerNum = player:getPlayerNum()
    local activeId = getSmokingMoodleId()
    local inactiveId = activeId == 'TS_Smoking_New' and 'TS_Smoking_Old' or 'TS_Smoking_New'

    -- Hide the inactive style moodle
    local inactiveMoodle = MF.getMoodle(inactiveId, playerNum)
    if inactiveMoodle and inactiveMoodle.setValue and isMoodleReady(player, inactiveId) then inactiveMoodle:setValue(0.5) end

    local moodle = MF.getMoodle(activeId, playerNum)
    if not moodle or not moodle.setThresholds or not isMoodleReady(player, activeId) then return end

    local data = TrueSmoking.Data.getSmoking(player)
    local ref = TrueSmoking.getPlayerRef(player)
    local smokable = ref and ref.smokable

    -- Default to hidden (desync is handled by validateState on init)
    if not data or not data.isSmoking or not smokable or not smokable.smokeLength then
        moodle:setValue(0.5)
        return
    end

    -- Calculate percentage
    local percent = smokable.smokeLength / smokable.originalSmokeLength
    percent = math.max(0, math.min(1, percent))

    -- Check if moodles should be hidden
    local config = TrueSmoking.Config or {}
    if config['HideMoodles'] then
        moodle:setValue(0.5)
        return
    end

    -- Set thresholds and value
    moodle:setThresholds(0.10, 0.20, 0.35, 0.4999, 0.5001, 0.65, 0.85, 0.90)
    moodle:setValue(percent)

    -- Format display text
    local litText = smokable.smokeLit and 'lit' or 'out'
    local estimate

    if config['ShowSmokePercent'] then
        estimate = string.format('%.1f%%', percent * 100)
    else
        local fractions = {
            [0] = '< 1/8',
            [10] = '~ 1/8',
            [20] = '~ 2/8',
            [30] = '~ 3/8',
            [40] = '~ 4/8',
            [50] = '~ 5/8',
            [60] = '~ 6/8',
            [80] = '~ 7/8',
            [90] = '~ 8/8'
        }
        estimate = '~'
        for threshold, text in pairs(fractions) do
            if percent * 100 >= threshold then
                estimate = text
            end
        end
    end

    -- Debug info
    local debugInfo = ''
    if config['DebugMoodles'] then
        debugInfo = TrueSmoking.getSmokingDebugInfo(smokable)
    end

    moodle:setDescription(
        moodle:getGoodBadNeutral(),
        moodle:getLevel(),
        getText('Moodles_smoking_Custom', litText, estimate) .. debugInfo
    )
end

--------------------------------------------------------------------------------
-- Nicotine Moodle
--------------------------------------------------------------------------------

--- Update the nicotine/withdrawal moodle
-- @param player IsoPlayer
function TrueSmoking.updateNicotineMoodle(player)
    if player:isDead() then return end
    
    -- Don't show or process nicotine moodle if system is disabled
    if not TrueSmoking.Options.UseNicotineSystem then return end

    local playerNum = player:getPlayerNum()
    local activeId = getNicotineMoodleId()
    local inactiveId = activeId == 'TS_Nicotine' and 'TS_Nicotine_Old' or 'TS_Nicotine'

    -- Hide the inactive style moodle
    local inactiveMoodle = MF.getMoodle(inactiveId, playerNum)
    if inactiveMoodle and inactiveMoodle.setValue and isMoodleReady(player, inactiveId) then inactiveMoodle:setValue(0.5) end

    local moodle = MF.getMoodle(activeId, playerNum)
    if not moodle or not moodle.setThresholds or not isMoodleReady(player, activeId) then return end

    local data = TrueSmoking.Data.getNicotine(player)
    if not data then return end

    local config = TrueSmoking.Config or {}
    local showDebug = config['DebugMoodles']
    local hideMoodles = config['HideMoodles']

    -- Show when in withdrawal or debug mode (hide if player has lost addiction/smoker trait)
    local hasAddiction = player:hasTrait(CharacterTrait.SMOKER)
        or data.addictionLevel >= NicotineSystem.Config.SMOKER_TRAIT_LOSE_THRESHOLD
    local shouldShow = showDebug or (hasAddiction and data.withdrawalLevel > 15 and data.nicotineLevel < 8)

    local moodleValue = 0.5 -- Hidden/neutral

    if shouldShow and not hideMoodles then
        local withdrawalNorm = math.min(data.withdrawalLevel / 100.0, 1.0)
        moodleValue = 1.0 - withdrawalNorm -- 1.0 = good, 0.0 = bad
    end

    moodle:setThresholds(0.10, 0.20, 0.35, 0.4999, 0.5001, 0.65, 0.85, 0.90)
    moodle:setValue(moodleValue)

    if shouldShow and not hideMoodles then
        -- Title based on addiction level
        local addiction = data.addictionLevel
        local titleKey

        if addiction >= 87.5 then
            titleKey = 'Moodles_TS_Nicotine_Bad_lvl4'
        elseif addiction >= 75 then
            titleKey = 'Moodles_TS_Nicotine_Bad_lvl3'
        elseif addiction >= 62.5 then
            titleKey = 'Moodles_TS_Nicotine_Bad_lvl2'
        elseif addiction >= 50 then
            titleKey = 'Moodles_TS_Nicotine_Bad_lvl1'
        elseif addiction >= 37.5 then
            titleKey = 'Moodles_TS_Nicotine_Good_lvl1'
        elseif addiction >= 25 then
            titleKey = 'Moodles_TS_Nicotine_Good_lvl2'
        elseif addiction >= 12.5 then
            titleKey = 'Moodles_TS_Nicotine_Good_lvl3'
        else
            titleKey = 'Moodles_TS_Nicotine_Good_lvl4'
        end

        local level = moodle:getLevel()
        local gbn = moodle:getGoodBadNeutral()

        if level > 0 and gbn ~= 0 then
            moodle:setTitle(gbn, level, getText(titleKey))
        end

        -- Description based on withdrawal
        local descKey
        if data.withdrawalLevel >= 80 then
            descKey = 'Moodles_TS_Nicotine_withdrawal_4'
        elseif data.withdrawalLevel >= 60 then
            descKey = 'Moodles_TS_Nicotine_withdrawal_3'
        elseif data.withdrawalLevel >= 40 then
            descKey = 'Moodles_TS_Nicotine_withdrawal_2'
        elseif data.withdrawalLevel >= 20 then
            descKey = 'Moodles_TS_Nicotine_withdrawal_1'
        else
            descKey = 'Moodles_TS_Nicotine_withdrawal_0'
        end

        local debugInfo = ''
        if showDebug then
            debugInfo = TrueSmoking.getNicotineDebugInfo(data)
        end

        moodle:setDescription(gbn, level, getText(descKey) .. debugInfo)
    end
end

--------------------------------------------------------------------------------
-- Debug Info Formatters
--------------------------------------------------------------------------------

--- Format smoking debug info for moodle
-- @param smokable SmokableItem
-- @return string Debug text
function TrueSmoking.getSmokingDebugInfo(smokable)
    if not smokable then return '' end

    local text = '\n\n[DEBUG INFO]'
    text = text .. string.format('\nLength: %.2f / %.2f', smokable.smokeLength, smokable.originalSmokeLength)
    text = text .. string.format('\nRemaining: %.1f%%', (smokable.smokeLength / smokable.originalSmokeLength) * 100)
    text = text .. string.format('\nLit: %s', smokable.smokeLit and 'Yes' or 'No')
    text = text .. string.format('\nPuff%%: %.6f', smokable.puffPercent)

    text = text .. '\n\n[Burn]'
    text = text .. string.format('\nRate: %.8f', smokable.burnRate)
    text = text .. string.format('\nMin/Max: %.8f / %.8f', smokable.burnMin, smokable.burnMax)
    text = text .. string.format('\nDecay: %.8f', smokable.decayRate)

    if smokable.smokeLit and smokable.smokeLength > 0 and smokable.burnRate > 0 then
        local timeLeft = smokable.smokeLength / smokable.burnRate
        text = text .. string.format('\n\nETA: ~%dm %ds', math.floor(timeLeft / 60), math.floor(timeLeft % 60))
    end

    return text
end

--- Format nicotine debug info for moodle
-- @param data table Nicotine data
-- @return string Debug text
function TrueSmoking.getNicotineDebugInfo(data)
    if not data then return '' end

    local text = '\n\n[DEBUG INFO]'
    text = text .. '\n[Nicotine]'
    text = text .. string.format('\nLevel: %.2f%%', tonumber(data.nicotineLevel) or 0)
    text = text .. string.format('\nTime: %.1f hours', tonumber(data.nicotineTime) or 0)
    text = text .. string.format('\nOverflow: %.2f%%', tonumber(data.nicotineOverflow) or 0)

    text = text .. '\n\n[Addiction]'
    text = text .. string.format('\nLevel: %.3f', tonumber(data.addictionLevel) or 0)
    text = text .. string.format('\nTime: %.1f days', tonumber(data.addictionTime) or 0)

    text = text .. '\n\n[Withdrawal]'
    text = text .. string.format('\nLevel: %.1f%%', tonumber(data.withdrawalLevel) or 0)

    text = text .. '\n\n[Caps]'
    text = text .. string.format('\nUnhappiness: %.2f', tonumber(data.unhappinessCap) or 0)
    text = text .. string.format('\nBoredom: %.2f', tonumber(data.boredomCap) or 0)

    return text
end

--------------------------------------------------------------------------------
-- Update Loop (Throttled Tick-Based)
--------------------------------------------------------------------------------

-- Throttle configuration: Update every ~15 ticks (~0.5 seconds at 30 FPS)
local MOODLE_UPDATE_INTERVAL = 30

-- Track tick counters per player (keyed by online ID)
local moodleUpdateCounters = {}

Events.OnPlayerUpdate.Add(function(player)
    if not player then return end

    -- Get or initialize tick counter for this player
    local playerId = player:getOnlineID()
    local counter = moodleUpdateCounters[playerId] or 0

    -- Increment counter and check if we should update
    counter = counter + 1
    if counter >= MOODLE_UPDATE_INTERVAL then
        -- Reset counter
        counter = 0

        -- Update both moodles
        TrueSmoking.updateSmokingMoodle(player)
        TrueSmoking.updateNicotineMoodle(player)
    end

    -- Store updated counter
    moodleUpdateCounters[playerId] = counter
end)
