local AE_MPPlayerUtils = {}

local AE_EnvironmentDetector = require("AnimalsEssentials/Core/AE_EnvironmentDetector")
--- @return table Array of player objects, empty if none found
function AE_MPPlayerUtils.getPlayersAsLuaTable()
    local players = {}
    
    -- Defensive SP/MP handling
    local success, result = pcall(function()
        if AE_EnvironmentDetector.isSinglePlayer() then
            -- Single-player: Direct access
            local player = getSpecificPlayer(0)
            if player and not player:isDead() then
                return {player}
            end
            return {}
        else
            -- Multiplayer: Java ArrayList → Lua table conversion
            local onlinePlayers = getOnlinePlayers()
            if not onlinePlayers then
                return {}
            end
            
            local luaTable = {}
            for i = 0, onlinePlayers:size() - 1 do
                local player = onlinePlayers:get(i)
                if player and not player:isDead() then
                    table.insert(luaTable, player)
                end
            end
            return luaTable
        end
    end)
    
    if success and result then
        return result
    end
    
    -- Fallback: Emergency iteration (defensive pattern)
    print("[AE_MPPlayerUtils] Primary enumeration failed, using emergency fallback")
    return AE_MPPlayerUtils.getPlayersDefensiveFallback()
end

--- Emergency fallback player enumeration (defensive pattern)
--- @return table Array of player objects
function AE_MPPlayerUtils.getPlayersDefensiveFallback()
    local players = {}
    
    if AE_EnvironmentDetector.isSinglePlayer() then
        local player = getSpecificPlayer(0)
        if player and not player:isDead() then
            return {player}
        end
        return {}
    end
    
    -- Emergency iteration method (0-15) with pcall protection
    for i = 0, 15 do
        local success, player = pcall(function()
            return getSpecificPlayer(i)
        end)
        
        if success and player and not player:isDead() then
            table.insert(players, player)
        end
    end
    
    return players
end

--- Get count of online players (defensive, no enumeration)
--- @return number Number of online players
function AE_MPPlayerUtils.getPlayersCount()
    local success, result = pcall(function()
        if AE_EnvironmentDetector.isSinglePlayer() then
            local player = getSpecificPlayer(0)
            return player and not player:isDead() and 1 or 0
        else
            local onlinePlayers = getOnlinePlayers()
            if not onlinePlayers then
                return 0
            end
            
            local count = 0
            for i = 0, onlinePlayers:size() - 1 do
                local player = onlinePlayers:get(i)
                if player and not player:isDead() then
                    count = count + 1
                end
            end
            return count
        end
    end)
    
    if success and result then
        return result
    end
    
    -- Fallback: Use table conversion count
    local players = AE_MPPlayerUtils.getPlayersDefensiveFallback()
    return #players
end

--- Safe iteration over online players with callback
--- @param callback function Function to call for each player: callback(player, index)
--- @return number Number of players successfully processed
function AE_MPPlayerUtils.iterateOnlinePlayers(callback)
    if not callback or type(callback) ~= "function" then
        print("[AE_MPPlayerUtils] ERROR: Invalid callback provided to iterateOnlinePlayers")
        return 0
    end
    
    local players = AE_MPPlayerUtils.getPlayersAsLuaTable()
    local processedCount = 0
    
    for i, player in ipairs(players) do
        local success, result = pcall(function()
            return callback(player, i)
        end)
        
        if success then
            processedCount = processedCount + 1
        else
            print("[AE_MPPlayerUtils] Error processing player " .. tostring(i) .. ": " .. tostring(result))
        end
    end
    
    return processedCount
end


--- Validate that a player connection is stable and valid
--- @param player IsoPlayer The player to validate
--- @return boolean True if player is valid and connected
function AE_MPPlayerUtils.validatePlayerConnection(player)
    if not player then
        return false
    end
    
    local success, result = pcall(function()
        -- Basic validation
        if player:isDead() then
            return false
        end
        
        if AE_EnvironmentDetector.isMultiplayer() then
            -- Check if player has valid online ID
            local onlineID = player:getOnlineID()
            if not onlineID or onlineID < 0 then
                return false
            end
            
            -- Additional MP validation could be added here
            return true
        else
            -- SP validation
            return player == getSpecificPlayer(0)
        end
    end)
    
    return success and result
end

--- Get player by online ID (defensive lookup)
--- @param targetID number The online ID to search for
--- @return IsoPlayer|nil Player object or nil if not found
function AE_MPPlayerUtils.getPlayerByOnlineID(targetID)
    if not targetID or targetID < 0 then
        return nil
    end
    
    local success, result = pcall(function()
        if AE_EnvironmentDetector.isSinglePlayer() then
            local player = getSpecificPlayer(0)
            if player and player:getOnlineID() == targetID then
                return player
            end
            return nil
        else
            local onlinePlayers = getOnlinePlayers()
            if not onlinePlayers then
                return nil
            end
            
            for i = 0, onlinePlayers:size() - 1 do
                local player = onlinePlayers:get(i)
                if player and player:getOnlineID() == targetID then
                    return player
                end
            end
            return nil
        end
    end)
    
    if success and result then
        return result
    end
    
    -- Fallback: Use defensive enumeration
    local players = AE_MPPlayerUtils.getPlayersDefensiveFallback()
    for _, player in ipairs(players) do
        if player:getOnlineID() == targetID then
            return player
        end
    end
    
    return nil
end


--- Check if multiplayer environment is ready and stable
--- @return boolean True if MP environment is stable
function AE_MPPlayerUtils.isMultiplayerReady()
    if AE_EnvironmentDetector.isSinglePlayer() then
        return true -- SP is always "ready"
    end
    
    local success, result = pcall(function()
        if isClient() then
            return false -- Client should not use server utilities
        end
        
        -- Test that getOnlinePlayers is accessible
        local onlinePlayers = getOnlinePlayers()
        return onlinePlayers ~= nil
    end)
    
    return success and result
end

--- Get environment information for debugging
--- @return table Environment info table
function AE_MPPlayerUtils.getEnvironmentInfo()
    local info = {
        isMP = AE_EnvironmentDetector.isMultiplayer(),
        isServer = isServer(),
        isClient = isClient(),
        timestamp = getGameTime() and getGameTime():getWorldAgeHours() or 0
    }
    
    -- Safe player count
    local success, count = pcall(function()
        return AE_MPPlayerUtils.getPlayersCount()
    end)
    info.playerCount = success and count or 0
    
    -- MP environment readiness
    info.mpReady = AE_MPPlayerUtils.isMultiplayerReady()
    
    return info
end


--- Get module version and capability information
--- @return table Module info
function AE_MPPlayerUtils.getModuleInfo()
    return {
        name = "AE_MPPlayerUtils",
        version = "1.0.0",
        description = "Standardized MP player utilities with defensive patterns",
        capabilities = {
            "getPlayersAsLuaTable",
            "getPlayersCount", 
            "iterateOnlinePlayers",
            "validatePlayerConnection",
            "getPlayerByOnlineID",
            "isMultiplayerReady",
            "getEnvironmentInfo"
        },
        patterns = {
            "Java ArrayList → Lua table conversion",
            "Defensive fallback enumeration",
            "SP/MP compatibility",
            "pcall error protection"
        }
    }
end

print("[AE_MPPlayerUtils] MP Player Utilities module loaded - providing standardized defensive patterns")

return AE_MPPlayerUtils