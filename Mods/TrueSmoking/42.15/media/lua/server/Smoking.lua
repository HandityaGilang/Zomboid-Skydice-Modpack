--[[
    Smoking.lua - Server-Side Smoking System
    
    Server-authoritative stat application and coordination.
    Stats are buffered on client, sent frequently (~1 sec), and applied here.
    This file handles:
    - Stat application from client buffers (server-authoritative)
    - Nicotine system processing (decay, withdrawal, addiction)
    - Data synchronization to clients
]]

require 'Core'
require 'Data'
require 'Nicotine'

SmokingSystem = SmokingSystem or {}

-- Load sandbox options on server startup (critical for MP dedicated servers)
if isServer() then
    Events.OnInitGlobalModData.Add(function()
        TrueSmoking.loadSandboxOptions()
        TrueSmoking.debug('Server: Loaded sandbox options')
    end)
end

--------------------------------------------------------------------------------
-- Stat Application (called when receiving BufferedStats from client)
--------------------------------------------------------------------------------

--- Apply buffered stat changes for a player
-- Called immediately when receiving BufferedStats command from client.
-- Server is authoritative for all stat changes.
-- Client uses CharacterStat enum key names directly (STRESS, BOREDOM, etc.)
-- @param player IsoPlayer
-- @param stats table Stat deltas from client buffer
function SmokingSystem:applyStats(player, stats)
    if not player or not stats then return end
    
    local playerStats = player:getStats()
    if not playerStats then return end
    
    local appliedCount = 0
    
    for stat, value in pairs(stats) do
        -- Handle special non-CharacterStat values
        if stat == 'TIME_SINCE_LAST_SMOKE' then
            -- Reduce timeSinceLastSmoke
            local current = player:getTimeSinceLastSmoke()
            local newValue = math.max(0, current - value)
            player:setTimeSinceLastSmoke(newValue)
            appliedCount = appliedCount + 1
            
        elseif stat == 'RESET_TIME_SINCE_LAST_SMOKE' then
            -- Non-smoker reset
            player:setTimeSinceLastSmoke(0)
            appliedCount = appliedCount + 1
            
        elseif stat == 'RESET_NICOTINE_WITHDRAWAL' then
            -- Non-smoker reset
            playerStats:set(CharacterStat.NICOTINE_WITHDRAWAL, 0)
            appliedCount = appliedCount + 1
            
        elseif type(value) == 'number' and value > 0 then
            -- Positive value = reduce stat (beneficial)
            -- Client uses exact CharacterStat enum names (STRESS, BOREDOM, etc.)
            local charStat = CharacterStat[stat]
            if charStat then
                playerStats:remove(charStat, value)
                appliedCount = appliedCount + 1
            end
            
        elseif type(value) == 'number' and value < 0 then
            -- Negative value = increase stat (detrimental, like food sickness)
            local charStat = CharacterStat[stat]
            if charStat then
                playerStats:add(charStat, math.abs(value))
                appliedCount = appliedCount + 1
            end
        end
    end
    
    if appliedCount > 0 and TrueSmoking.DEBUG then
        -- TrueSmoking.debug('Applied ' .. appliedCount .. ' stats for ' .. player:getDisplayName())
    end
end

--------------------------------------------------------------------------------
-- Minute Loop (Nicotine System Only)
--------------------------------------------------------------------------------

-- Track if we've logged that the event is firing (to avoid spam)
local hasLoggedEventFiring = false

Events.EveryOneMinute.Add(function()
    -- Debug: confirm event is firing
    if not hasLoggedEventFiring then
        TrueSmoking.debug('EveryOneMinute handler registered and firing (isServer=' .. tostring(isServer()) .. ', isClient=' .. tostring(isClient()) .. ')')
        hasLoggedEventFiring = true
    end
    
    if isServer() then
        -- Multiplayer server
        local players = getOnlinePlayers()
        if not players then return end
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            if player then
                -- Process nicotine system (addiction, withdrawal, decay)
                if TrueSmoking.Options.UseNicotineSystem and TrueSmoking.Nicotine and TrueSmoking.Nicotine.updatePlayer then
                    TrueSmoking.Nicotine.updatePlayer(player)
                end
                
                -- Sync nicotine data to client
                if TrueSmoking.Options.UseNicotineSystem and TrueSmoking.Nicotine and TrueSmoking.Nicotine.syncToClient then
                    TrueSmoking.Nicotine.syncToClient(player)
                end
            end
        end
    elseif not isClient() then
        -- Singleplayer: both client and server logic runs in same context
        local numPlayers = getNumActivePlayers()
        for i = 0, numPlayers - 1 do
            local player = getSpecificPlayer(i)
            if player and instanceof(player, 'IsoPlayer') then
                -- Process nicotine system
                if TrueSmoking.Options.UseNicotineSystem and TrueSmoking.Nicotine and TrueSmoking.Nicotine.updatePlayer then
                    TrueSmoking.Nicotine.updatePlayer(player)
                end
            end
        end
    end
end)
