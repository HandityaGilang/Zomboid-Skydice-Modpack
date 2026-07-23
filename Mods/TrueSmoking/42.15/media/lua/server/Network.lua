--[[
    Network.lua - Server-Side Command Handler

    Processes commands from clients:
    - updatePlayerData: Update smoking ModData
    - updatePlayerNicData: Update nicotine ModData
    - BufferedPuffs: Receive puff events for nicotine processing
    - BufferedStats: Receive stat deltas for server-authoritative application
    - requestData/requestNicotineData: Send data to client
    - equipVisualItem/removeVisualItem: Manage face masks
    - addTrait/removeTrait: Trait management
    - addSmokable: Add item to inventory
]]

require 'Core'
require 'Data'
require 'Visuals'
require 'Smoking'

--------------------------------------------------------------------------------
-- Command Handler
--------------------------------------------------------------------------------

function TrueSmoking.onClientCommand(module, command, playerRaw, args)
    if module ~= 'TrueSmoking' then return end

    -- Resolve player object
    local player
    if not isClient() and not isServer() then
        player = playerRaw -- Singleplayer
    else
        player = getPlayerByOnlineID(playerRaw:getOnlineID()) or playerRaw
    end

    if not player then return end

    -- Normalize args (handle array-wrapped tables)
    local function normalizeArgs(a)
        if type(a) ~= 'table' then return a end
        if type(a[1]) == 'table' then return a[1] end
        return a
    end

    ----------------------------------------------------------------
    -- Data Updates
    ----------------------------------------------------------------

    if command == 'updatePlayerData' then
        local data = normalizeArgs(args)
        if type(data) ~= 'table' then return end

        local md = player:getModData()
        md.TrueSmoking = md.TrueSmoking or {}

        for key, value in pairs(data) do
            md.TrueSmoking[key] = value
        end
    end

    if command == 'updatePlayerNicData' then
        local data = normalizeArgs(args)
        if type(data) ~= 'table' then return end

        local md = player:getModData()
        md.nicotineSystem = md.nicotineSystem or {}

        for key, value in pairs(data) do
            md.nicotineSystem[key] = value
        end
        
        -- Don't immediately sync back - let the change persist
        -- The next minute tick will handle syncing after processing
    end

    if command == 'updateItemData' then
        local item = args[1]
        local data = args[2]
        if item and data then
            for k, v in pairs(data) do
                item:getModData()[k] = v
            end
        end
    end

    ----------------------------------------------------------------
    -- Puff Buffer Processing
    ----------------------------------------------------------------

    if command == 'BufferedPuffs' then
        local argsTable = normalizeArgs(args)
        local puffs = argsTable and argsTable.puffs or argsTable
        if type(puffs) ~= 'table' then return end

        local md = player:getModData()
        md.TrueSmoking = md.TrueSmoking or {}
        md.TrueSmoking.puffBuffer = md.TrueSmoking.puffBuffer or {}

        local appended = 0
        for _, puff in ipairs(puffs) do
            if type(puff) == 'table' then
                local nic = tonumber(puff.nicotineContent) or 0
                local percent = tonumber(puff.puffPercent) or 0

                -- Validate ranges to prevent cheating
                if percent > 0 and percent <= 1.5 and nic >= 0 and nic <= 10000 then
                    table.insert(md.TrueSmoking.puffBuffer, { nicotineContent = nic, puffPercent = percent })
                    appended = appended + 1
                end
            end
        end

        if appended > 0 then
            -- TrueSmoking.debug('Received ' .. appended .. ' puffs from ' .. player:getDisplayName())
            if TrueSmoking.Nicotine and TrueSmoking.Nicotine.processPuffBuffer then
                TrueSmoking.Nicotine.processPuffBuffer(player)
            end
        end
    end

    ----------------------------------------------------------------
    -- Buffered Stats Processing (Server-Authoritative)
    ----------------------------------------------------------------

    if command == 'BufferedStats' then
        local argsTable = normalizeArgs(args)
        local stats = argsTable and argsTable.stats or argsTable
        if type(stats) ~= 'table' then return end

        -- Validate and sanitize stat values
        local validatedStats = {}
        local validCount = 0
        for stat, value in pairs(stats) do
            -- Only allow numeric values within reasonable ranges
            if type(value) == 'number' and value == value then -- NaN check
                -- Cap to prevent cheating (max reasonable delta per sync)
                local capped = math.max(-10, math.min(10, value))
                if capped ~= 0 then
                    validatedStats[stat] = capped
                    validCount = validCount + 1
                end
            end
        end

        if validCount > 0 then
            -- TrueSmoking.debug('Received ' .. validCount .. ' stat updates from ' .. player:getDisplayName())
            -- Apply stats immediately using SmokingSystem
            if SmokingSystem and SmokingSystem.applyStats then
                SmokingSystem:applyStats(player, validatedStats)
            end
        end
    end

    ----------------------------------------------------------------
    -- Data Requests
    ----------------------------------------------------------------

    if command == 'requestData' then
        local data = TrueSmoking.Data.getSmoking(player)
        sendServerCommand(player, 'TrueSmoking', 'SyncData', data)
    end

    if command == 'requestNicotineData' then
        TrueSmoking.Nicotine.syncToClient(player)
    end

    if command == 'validateState' then
        TrueSmoking.onClientCommand_validateState(player)
    end

    ----------------------------------------------------------------
    -- Visual Items
    ----------------------------------------------------------------

    if command == 'equipVisualItem' then
        local argsTable = normalizeArgs(args)
        
        -- Expect format { fullType, options }
        local fullType = argsTable.fullType
        local options = argsTable.options
        
        if not fullType or not options or not options.ManageHeadGear then return end

        -- Use Visuals.lua to get mask type (handles NO_VISUAL_PATTERNS correctly)
        local maskType = false
        if TrueSmoking.Visuals and TrueSmoking.Visuals.getMaskType then
            -- Create temporary item to check visual
            local tempItem = instanceItem(fullType)
            if tempItem then
                maskType = TrueSmoking.Visuals.getMaskType(tempItem)
            end
        end
        
        -- Fallback to pattern matching (legacy support)
        if maskType == nil then
            local lowerType = fullType:lower()
            -- Check for no-visual patterns
            if lowerType:find('bong') or lowerType:find('can') then
                maskType = false
            elseif lowerType:find('pipe') then
                maskType = 'Base.Mask_Pipe'
            elseif lowerType:find('cigar[^e]') or lowerType:find('cigar$') then
                maskType = 'Base.Mask_Cigar'
            elseif lowerType:find('cigarillo') then
                maskType = 'Base.Mask_Cigarillo'
            else
                maskType = 'Base.Mask_Cigarette'
            end
        end

        -- Only equip if maskType is valid (not false)
        if maskType and maskType ~= false then
            local mask = instanceItem(maskType)
            if mask and not player:getWornItem(TrueSmoking.registries.mask) then
                -- Use the registered body location to avoid conflicts with other clothing
                -- setWornItem auto-sends SyncClothingPacket in MP
                player:setWornItem(TrueSmoking.registries.mask, mask)
            end
        end
    end

    if command == 'removeVisualItem' then
        local argsTable = normalizeArgs(args)
        local options = argsTable.options or argsTable[1] or argsTable
        if not options or not options.ManageHeadGear then return end

        local mask = player:getWornItem(TrueSmoking.registries.mask)
        if mask then
            player:removeWornItem(mask)
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
    -- Inventory
    ----------------------------------------------------------------

    if command == 'addSmokable' then
        local itemName = args[1]
        local data = args[2]

        local item = player:getInventory():AddItem(itemName)
        if item and data and data.SmokeLength then
            item:getModData().SmokeLength = data.SmokeLength
        end
        sendAddItemToContainer(player:getInventory(), item)
    end

    if command == 'replaceItem' then
        local replaceType = args[1]
        if replaceType and replaceType ~= '' then
            local newItem = player:getInventory():AddItem(replaceType)
            if newItem then
                sendAddItemToContainer(player:getInventory(), newItem)
            end
        end
    end

    if command == 'createCigaretteFromPack' then
        local argsTable = normalizeArgs(args)
        local packId = argsTable.packId
        local cigType = argsTable.cigType or 'Base.CigaretteSingle'

        if not packId then return end

        -- Find pack in player inventory or worn containers (backpacks, bags, etc.)
        local pack = TrueSmoking.getItemFromPlayerContainers(player, packId)
        if not pack or not instanceof(pack, 'Drainable') then
            TrueSmoking.debug('createCigaretteFromPack - Pack not found: ' .. tostring(packId))
            return
        end

        -- Check pack has uses remaining
        if pack:getCurrentUsesFloat() <= 0 then
            TrueSmoking.debug('createCigaretteFromPack - Pack empty')
            return
        end

        -- Create cigarette in inventory
        local cigarette = player:getInventory():AddItem(cigType)
        if not cigarette then
            TrueSmoking.debug('createCigaretteFromPack - Failed to create cigarette')
            return
        end

        -- Transfer any stored partial smoke data from pack
        local packData = pack:getModData()
        if packData.Cigs then
            for cigId, cigInfo in pairs(packData.Cigs) do
                cigarette:getModData().OriginalSmokeLength = cigInfo.OriginalSmokeLength
                cigarette:getModData().SmokeLength = cigInfo.SmokeLength
                packData.Cigs[cigId] = nil
                break
            end
        end

        -- Reduce pack uses
        pack:setUsedDelta(pack:getCurrentUsesFloat() - pack:getUseDelta())

        -- Store cigarette ID in player ModData for client to retrieve
        local md = player:getModData()
        md.TrueSmoking = md.TrueSmoking or {}
        md.TrueSmoking.pendingCigaretteId = cigarette:getID()

        -- Sync item to client
        sendAddItemToContainer(player:getInventory(), cigarette)
        sendItemStats(pack)

        -- Notify client
        sendServerCommand(player, 'TrueSmoking', 'cigaretteCreated', {
            cigaretteId = cigarette:getID(),
            packId = packId
        })

        TrueSmoking.debug('createCigaretteFromPack - Created cigarette ID: ' .. cigarette:getID())
    end
end

Events.OnClientCommand.Add(TrueSmoking.onClientCommand)

--------------------------------------------------------------------------------
-- Connection Handling
--------------------------------------------------------------------------------

local function clearSmokingStateForPlayer(player)
    if not player then return end

    TrueSmoking.Data.clearSmokingState(player)
    player:transmitModData()

    local data = TrueSmoking.Data.getSmoking(player)
    sendServerCommand(player, 'TrueSmoking', 'SyncData', data)
end

-- Track players pending delayed reset: { [onlineID] = timestampMs }
local pendingDelayedReset = {}
local DELAYED_RESET_MS = 15000 -- 15 seconds

-- Expose for external access if needed
TrueSmoking.pendingDelayedReset = pendingDelayedReset
TrueSmoking.DELAYED_RESET_MS = DELAYED_RESET_MS

-- Periodic check for delayed resets
-- OnPlayerFullyConnected/OnPlayerConnect/OnPlayerDisconnect don't exist in B42 API
Events.EveryOneMinute.Add(function()
    if not isServer() then return end
    if not TrueSmoking.pendingDelayedReset then return end

    local now = getTimestampMs()
    local players = getOnlinePlayers()
    if not players then return end

    -- Build list of completed resets to avoid modifying table during iteration
    local toRemove = {}

    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            local pid = player:getOnlineID()
            local requestTime = pendingDelayedReset[pid]

            if requestTime and (now - requestTime) >= DELAYED_RESET_MS then
                -- 15 seconds have passed, do the reset
                table.insert(toRemove, pid)

                local md = player:getModData()
                if md and md.TrueSmoking and md.TrueSmoking.isSmoking then
                    TrueSmoking.debug('Delayed reset - clearing stale isSmoking for ' .. player:getDisplayName())
                    clearSmokingStateForPlayer(player)
                end
            end
        end
    end

    -- Clean up completed resets
    for _, pid in ipairs(toRemove) do
        pendingDelayedReset[pid] = nil
    end
end)

-- Handle validation request from client - schedules delayed reset
-- Client sends 'validateState' on init, reset fires 15 seconds later
function TrueSmoking.onClientCommand_validateState(player)
    if not player then return end

    local pid = player:getOnlineID()
    if not pendingDelayedReset[pid] then
        pendingDelayedReset[pid] = getTimestampMs()
        TrueSmoking.debug('validateState - scheduled delayed reset for ' .. player:getDisplayName())
    end
end
