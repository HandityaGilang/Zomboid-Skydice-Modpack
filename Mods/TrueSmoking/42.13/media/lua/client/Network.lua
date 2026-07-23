--[[
    Network.lua - Client-Side Command Handler
    
    Processes commands from server:
    - SyncData: Update local smoking ModData
    - SyncNicData: Update local nicotine ModData
    - addTrait/removeTrait: Update traits locally
    
    Also sends buffered puffs to server every minute.
]]

require 'Core'
require 'Data'

--------------------------------------------------------------------------------
-- Server Command Handler
--------------------------------------------------------------------------------

function TrueSmoking.onServerCommand(module, command, args)
    if module ~= 'TrueSmoking' then return end
    
    local player = getPlayer()
    if not player then return end
    
    ----------------------------------------------------------------
    -- Data Sync
    ----------------------------------------------------------------
    
    if command == 'SyncData' then
        if not args then return end
        
        local md = player:getModData()
        md.TrueSmoking = md.TrueSmoking or {}
        
        for key, value in pairs(args) do
            -- Client controls isSmoking locally - don't overwrite
            if key ~= 'isSmoking' then
                md.TrueSmoking[key] = value
            end
        end
    end
    
    if command == 'SyncNicData' then
        if not args then return end
        
        -- Remove internal flag before storing
        args.requested = nil
        
        local md = player:getModData()
        md.nicotineSystem = md.nicotineSystem or {}
        
        for key, value in pairs(args) do
            local oldVal = md.nicotineSystem[key]
            if value < 0.0001 then value = 0 end  -- Prevent tiny float values
            md.nicotineSystem[key] = value
            
            if key == 'nicotineLevel' and oldVal ~= value then
                TrueSmoking.debug('Nicotine synced: ' .. tostring(oldVal) .. ' -> ' .. tostring(value))
            end
        end
    end
    
    ----------------------------------------------------------------
    -- Traits
    ----------------------------------------------------------------
    
    if command == 'addTrait' then
        local traitName = args[1]
        if traitName and CharacterTrait[traitName] then
            if not player:hasTrait(CharacterTrait[traitName]) then
                player:getCharacterTraits():add(CharacterTrait[traitName])
            end
        end
    end
    
    if command == 'removeTrait' then
        local traitName = args[1]
        if traitName and CharacterTrait[traitName] then
            if player:hasTrait(CharacterTrait[traitName]) then
                player:getCharacterTraits():remove(CharacterTrait[traitName])
            end
        end
    end

    ----------------------------------------------------------------
    -- Item Creation Callbacks
    ----------------------------------------------------------------

    if command == 'cigaretteCreated' then
        -- Server created a cigarette from pack - store ID for LightSmoke:perform() to retrieve
        local cigaretteId = args and args.cigaretteId
        if cigaretteId then
            local data = TrueSmoking.Data.getSmoking(player)
            if data then
                data.pendingCigaretteId = cigaretteId
                TrueSmoking.debug('cigaretteCreated - Stored pending cigarette ID: ' .. tostring(cigaretteId))
            end
        end
    end
end

Events.OnServerCommand.Add(TrueSmoking.onServerCommand)

--------------------------------------------------------------------------------
-- Buffer Senders
--------------------------------------------------------------------------------

-- Send buffered stats to server frequently (every ~1 second via tick counter)
-- This is more frequent than EveryOneMinute to combat natural stat regen.
-- Server applies stats immediately upon receiving them.
local statSendTickCounter = 0
local STAT_SEND_INTERVAL = 30  -- Send every ~30 ticks (~1 second at 30fps)

Events.OnPlayerUpdate.Add(function(player)
    if not player then return end
    
    statSendTickCounter = statSendTickCounter + 1
    if statSendTickCounter < STAT_SEND_INTERVAL then return end
    statSendTickCounter = 0
    
    local data = TrueSmoking.Data.getSmoking(player)
    if not data or not data.statsToApply then return end
    
    -- Check if there are any stats to send
    local hasStats = false
    for _ in pairs(data.statsToApply) do
        hasStats = true
        break
    end
    if not hasStats then return end
    
    -- Send to server (works in both SP and MP)
    -- In SP: sendClientCommand triggers OnClientCommand immediately
    -- In MP: sendClientCommand sends over network to server
    sendClientCommand(player, 'TrueSmoking', 'BufferedStats', { stats = data.statsToApply })
    
    -- Clear buffer after sending
    data.statsToApply = {}
end)

-- Send buffered puffs to server every minute (nicotine system is less time-sensitive)
Events.EveryOneMinute.Add(function()
    local player = getPlayer()
    if not player then return end
    
    local data = TrueSmoking.Data.getSmoking(player)
    if not data or not data.puffBuffer or #data.puffBuffer == 0 then return end
    
    -- Send to server (works in both SP and MP)
    sendClientCommand(player, 'TrueSmoking', 'BufferedPuffs', { puffs = data.puffBuffer })
    -- TrueSmoking.debug('Sent ' .. #data.puffBuffer .. ' buffered puffs to server')
    
    data.puffBuffer = {}
end)
