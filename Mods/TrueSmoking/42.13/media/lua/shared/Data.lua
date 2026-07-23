--[[
    Data.lua - Centralized ModData Access Layer
    
    All code should use these helpers instead of direct getModData() calls.
    This provides:
    - Automatic initialization of data structures
    - Legacy field migration from older saves
    - Validation and corruption recovery
    - Consistent data access patterns
]]

require 'Core'

TrueSmoking.Data = TrueSmoking.Data or {}

--------------------------------------------------------------------------------
-- Smoking Data (TrueSmoking ModData)
--------------------------------------------------------------------------------

local SMOKING_DEFAULTS = {
    isSmoking = false,
    takingPuff = false,
    smokable = nil,
    visualItem = nil,
    statsToApply = {},
    puffBuffer = {},
    eatSound = '',
    lightingEatSound = '',
    lastActivity = '',
    pendingCigaretteId = nil,  -- Used to pass cigarette ID from server to client
}

--- Get or initialize smoking data for a player
-- @param player IsoPlayer
-- @return table TrueSmoking ModData
function TrueSmoking.Data.getSmoking(player)
    if not player then return nil end
    local modData = player:getModData()
    
    if not modData.TrueSmoking then
        modData.TrueSmoking = TrueSmoking.deepCopy(SMOKING_DEFAULTS)
    else
        -- Ensure all fields exist
        for key, default in pairs(SMOKING_DEFAULTS) do
            if modData.TrueSmoking[key] == nil then
                if type(default) == 'table' then
                    modData.TrueSmoking[key] = {}
                else
                    modData.TrueSmoking[key] = default
                end
            end
        end
    end
    
    return modData.TrueSmoking
end

-- Legacy alias
TrueSmoking.Data.getSmokingData = TrueSmoking.Data.getSmoking

--------------------------------------------------------------------------------
-- Nicotine Data (nicotineSystem ModData)
--------------------------------------------------------------------------------

local NICOTINE_DEFAULTS = {
    nicotineLevel = 0,
    addictionLevel = 0,
    withdrawalLevel = 0,
    addictionTime = 0,
    nicotineTime = 0,
    unhappinessCap = 0,
    boredomCap = 0,
    nicotineOverflow = 0,
}

--- Get or initialize nicotine system data for a player
-- @param player IsoPlayer
-- @return table nicotineSystem ModData
function TrueSmoking.Data.getNicotine(player)
    if not player then return nil end
    local modData = player:getModData()
    
    if not modData.nicotineSystem then
        -- Check if nicotine system is enabled before setting smoker values
        local nicotineEnabled = TrueSmoking.Options and TrueSmoking.Options.UseNicotineSystem
        local isSmoker = player:hasTrait(CharacterTrait.SMOKER)
        
        -- Get threshold from NicotineSystem config if available
        local smokerThreshold = 70
        if NicotineSystem and NicotineSystem.Config then
            smokerThreshold = NicotineSystem.Config.SMOKER_TRAIT_GAIN_THRESHOLD or 70
        end
        
        -- Only set addiction/withdrawal if nicotine system is enabled AND player is smoker
        local startAddiction = (nicotineEnabled and isSmoker) and (smokerThreshold * 1.2) or 0
        local startWithdrawal = (nicotineEnabled and isSmoker) and 35 or 0
        
        modData.nicotineSystem = {
            nicotineLevel = 0,
            addictionLevel = startAddiction,
            withdrawalLevel = startWithdrawal,
            addictionTime = 0,
            nicotineTime = 0,
            unhappinessCap = 0,
            boredomCap = 0,
            nicotineOverflow = 0,
        }
    else
        -- Ensure all fields exist
        for key, default in pairs(NICOTINE_DEFAULTS) do
            if modData.nicotineSystem[key] == nil then
                modData.nicotineSystem[key] = default
            end
        end
    end
    
    return modData.nicotineSystem
end

--------------------------------------------------------------------------------
-- State Management
--------------------------------------------------------------------------------

--- Clear all smoking state (used on death, disconnect, etc)
-- @param player IsoPlayer
function TrueSmoking.Data.clearSmokingState(player)
    local data = TrueSmoking.Data.getSmoking(player)
    if not data then return end
    
    data.isSmoking = false
    data.takingPuff = false
    data.smokable = nil
    data.visualItem = nil
    data.statsToApply = {}
    data.puffBuffer = {}
    data.lastActivity = ''
end

--- Validate and repair corrupted smoking state
-- @param player IsoPlayer
-- @return table Validated smoking data
function TrueSmoking.Data.validate(player)
    local data = TrueSmoking.Data.getSmoking(player)
    if not data then return nil end
    
    -- Fix impossible state: smoking without smokable
    if data.isSmoking and not data.smokable then
        data.isSmoking = false
        data.takingPuff = false
        if isClient() then
            sendClientCommand(player, 'TrueSmoking', 'updatePlayerData', {
                { isSmoking = false, takingPuff = false }
            })
        end
    end
    
    -- Ensure tables exist
    if type(data.statsToApply) ~= 'table' then data.statsToApply = {} end
    if type(data.puffBuffer) ~= 'table' then data.puffBuffer = {} end
    
    return data
end
