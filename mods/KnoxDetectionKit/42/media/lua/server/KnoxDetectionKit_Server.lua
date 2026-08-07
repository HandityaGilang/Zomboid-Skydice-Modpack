--
-- Knox Detection Kit — Server Module
-- Checks infection status server-side, stores result in player ModData,
-- and sends the result back to the client after the configured wait time.
--

require "KnoxDetectionKit_Shared"

local TAG = "[KnoxDetectionKit]"

print(TAG .. " Server module loaded")

-- ---------------------------------------------------------------------------
-- Anti-spam cooldown tracker (username -> timestamp in ms)
-- ---------------------------------------------------------------------------
local lastTestAttempt = {}
local TEST_COOLDOWN_MS = 5000

-- ---------------------------------------------------------------------------
-- Sandbox helpers
-- ---------------------------------------------------------------------------
local function getWaitMinutes()
    if SandboxVars and SandboxVars.KnoxDetectionKit and SandboxVars.KnoxDetectionKit.WaitMinutes then
        return SandboxVars.KnoxDetectionKit.WaitMinutes
    end
    return 120
end

-- ---------------------------------------------------------------------------
-- Get player display name for logging
-- ---------------------------------------------------------------------------
local function playerName(player)
    return player:getDisplayName() or player:getUsername() or "survivor"
end

-- ---------------------------------------------------------------------------
-- Send a TestResult back to the requesting client
-- ---------------------------------------------------------------------------
local function sendResult(player, args)
    sendServerCommand(player, KnoxDetectionKit.MOD_ID, KnoxDetectionKit.CMD_RESULT, args)
end

-- ---------------------------------------------------------------------------
-- Check if player has real Knox Infection via CharacterStat or BodyDamage
-- ---------------------------------------------------------------------------
local function isKnoxInfected(player)
    -- Check CharacterStat first (primary in B42.13+)
    local stats = player:getStats()
    if stats then
        local ok, val = pcall(function() return stats:get(CharacterStat.ZOMBIE_INFECTION) end)
        if ok and val and val > 0 then
            return true
        end
    end
    -- Fallback to BodyDamage (singleplayer only — isInfected() is always false in MP)
    -- NOTE: IsFakeInfected() deliberately excluded — fake infection is a wound infection,
    -- not Knox. The kit's purpose is to distinguish real Knox from fake.
    local bodyDamage = player:getBodyDamage()
    if bodyDamage then
        local ok, infected = pcall(function() return bodyDamage:isInfected() end)
        if ok and infected then return true end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Handle RunTest command from client
-- ---------------------------------------------------------------------------
local function handleRunTest(player, args)
    local itemID = args and args.itemID
    if not itemID then
        print(TAG .. " RunTest missing itemID from " .. playerName(player))
        sendResult(player, { phase = "error", message = "Invalid request." })
        return
    end

    local item = player:getInventory():getItemWithID(itemID)
    if not item then
        print(TAG .. " Item " .. tostring(itemID) .. " not found for " .. playerName(player))
        sendResult(player, { phase = "error", message = "Kit not found." })
        return
    end

    if item:getFullType() ~= "Base.KnoxDetectionKit" then
        print(TAG .. " Item " .. tostring(itemID) .. " is not KnoxDetectionKit")
        sendResult(player, { phase = "error", message = "Invalid item." })
        return
    end

    -- Wrap the mutation + result in pcall to prevent crashes from killing the handler
    local ok, err = pcall(function()
        -- Remove the kit (consumed on use)
        player:getInventory():Remove(item)
        sendRemoveItemFromContainer(player:getInventory(), item)

        -- Check infection status NOW (server-authoritative)
        local infected = isKnoxInfected(player)
        print(TAG .. " " .. playerName(player) .. " ran blood test — infected=" .. tostring(infected))

        -- Store result and timestamp in player ModData
        local modData = player:getModData()
        local waitMinutes = getWaitMinutes()
        local gameHours = getGameTime():getWorldAgeHours()

        modData.KnoxDetectionKit_resultReady = gameHours + (waitMinutes / 60)
        modData.KnoxDetectionKit_infected = infected and 1 or 0

        -- Send confirmation to client with wait info
        -- Encode boolean as 1/0 for network serialization safety
        sendResult(player, {
            phase = "started",
            waitMinutes = waitMinutes,
            readyAt = modData.KnoxDetectionKit_resultReady,
            infected = infected and 1 or 0,
        })
    end)
    if not ok then
        print(TAG .. " ERROR in handleRunTest: " .. tostring(err))
        sendResult(player, { phase = "error", message = "Internal error." })
    end
end

-- ---------------------------------------------------------------------------
-- OnClientCommand handler
-- ---------------------------------------------------------------------------
local function onClientCommand(module, command, player, args)
    if module ~= KnoxDetectionKit.MOD_ID then return end

    if command == KnoxDetectionKit.CMD_RUN_TEST then
        -- Anti-spam cooldown
        local username = player:getUsername() or ""
        local now = getTimestampMs()
        if lastTestAttempt[username] and (now - lastTestAttempt[username]) < TEST_COOLDOWN_MS then
            print(TAG .. " Rate limited RunTest from " .. playerName(player))
            return
        end
        lastTestAttempt[username] = now

        -- Network may deliver `args` as null when the client sent an empty/unset table.
        -- Use defensive access here so we don't crash before reaching handleRunTest's
        -- own validation (which already nil-checks via `args and args.itemID`).
        print(TAG .. " Received RunTest from " .. playerName(player) .. " itemID=" .. tostring(args and args.itemID))
        handleRunTest(player, args)
    end
end

Events.OnClientCommand.Add(onClientCommand)
