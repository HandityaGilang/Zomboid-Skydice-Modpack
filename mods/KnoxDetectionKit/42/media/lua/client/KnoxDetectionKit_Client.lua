--
-- Knox Detection Kit — Client Module
-- Context menu, result polling via OnPlayerUpdate, HaloText feedback.
--

require "KnoxDetectionKit_Shared"
require "KnoxDetectionKit_BloodTestAction"
require "TimedActions/ISTimedActionQueue"
require "ISUI/ISInventoryPaneContextMenu"

local TAG = "[KnoxDetectionKit]"

print(TAG .. " Client module loaded")

-- ---------------------------------------------------------------------------
-- State tracking for the local player's pending test
-- ---------------------------------------------------------------------------
local pendingTest = nil  -- { readyAt, infected, lastReminderHour }
local showResult         -- forward declaration (used in onServerCommand before definition)

-- ---------------------------------------------------------------------------
-- Context menu — "Run Blood Test" when right-clicking the kit
-- ---------------------------------------------------------------------------
local function onUseKit(playerObj, item)
    ISTimedActionQueue.add(KnoxDetectionKitBloodTestAction:new(playerObj, item))
end

local function onFillInventoryObjectContextMenu(playerNum, context, items)
    local playerObj = getSpecificPlayer(playerNum)
    if not playerObj then return end

    for i = 1, #items do
        local testItem = items[i]
        if not instanceof(testItem, "InventoryItem") then
            testItem = testItem.items[1]
        end
        if testItem and testItem:getFullType() == "Base.KnoxDetectionKit" then
            local option = context:addOption(getText("ContextMenu_RunBloodTest"), playerObj, onUseKit, testItem)
            -- Disable if a test is already pending
            if pendingTest then
                option.notAvailable = true
                local tooltip = ISInventoryPaneContextMenu.addToolTip()
                tooltip.description = "A blood test is already in progress."
                option.toolTip = tooltip
            end
            return
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)

-- ---------------------------------------------------------------------------
-- OnServerCommand — receives test confirmation from server
-- ---------------------------------------------------------------------------
local function onServerCommand(module, command, args)
    if module ~= KnoxDetectionKit.MOD_ID then return end

    if command == KnoxDetectionKit.CMD_RESULT then
        local player = getPlayer()

        if args.phase == "error" then
            if player then
                HaloTextHelper.addTextWithArrow(player, args.message or "Test failed.", true, 255, 50, 50)
            end
            print(TAG .. " Server error: " .. tostring(args.message))
            return
        end

        if args.phase == "started" then
            local waitMinutes = args.waitMinutes or 120
            local infected = args.infected == 1
            pendingTest = {
                readyAt = args.readyAt,
                infected = infected,
                lastReminderHour = -1,
            }

            -- Mirror to client ModData for persistence across reconnects
            -- Store infected as 1/0 — ModData drops boolean true
            if player then
                local modData = player:getModData()
                modData.KnoxDetectionKit_resultReady = args.readyAt
                modData.KnoxDetectionKit_infected = infected and 1 or 0
            end

            if player then
                if waitMinutes <= 0 then
                    -- Instant results
                    showResult(player)
                else
                    HaloTextHelper.addTextWithArrow(player, "Blood sample taken. Results in " .. tostring(waitMinutes) .. "m.", true, 200, 200, 200)
                    print(TAG .. " Test started, results in " .. tostring(waitMinutes) .. " minutes")
                end
            end
        end
    end
end

Events.OnServerCommand.Add(onServerCommand)

-- ---------------------------------------------------------------------------
-- Show the final result
-- ---------------------------------------------------------------------------
showResult = function(player)
    if not pendingTest then return end

    if pendingTest.infected then
        HaloTextHelper.addTextWithArrow(player, "Test Result: POSITIVE - Knox Virus Detected", true, 255, 50, 50)
        print(TAG .. " Result: POSITIVE")
    else
        HaloTextHelper.addTextWithArrow(player, "Test Result: Negative", true, 50, 255, 50)
        print(TAG .. " Result: Negative")
    end

    pendingTest = nil

    -- Clear ModData to prevent stale restoration on rejoin
    local modData = player:getModData()
    modData.KnoxDetectionKit_resultReady = nil
    modData.KnoxDetectionKit_infected = nil
end

-- ---------------------------------------------------------------------------
-- OnPlayerUpdate — poll for result readiness + show periodic reminders
-- ---------------------------------------------------------------------------
local checkCounter = 0

local function onPlayerUpdate(player)
    if not pendingTest then return end

    -- Only check every ~60 frames to avoid spamming
    checkCounter = checkCounter + 1
    if checkCounter < 60 then return end
    checkCounter = 0

    local gameHours = getGameTime():getWorldAgeHours()

    if gameHours >= pendingTest.readyAt then
        showResult(player)
        return
    end

    -- Show a periodic reminder every in-game hour
    local currentHour = math.floor(gameHours)
    if currentHour ~= pendingTest.lastReminderHour then
        pendingTest.lastReminderHour = currentHour
        local remainingMin = math.ceil((pendingTest.readyAt - gameHours) * 60)
        if remainingMin > 0 then
            HaloTextHelper.addTextWithArrow(player, "Awaiting test results... (" .. tostring(remainingMin) .. "m)", true, 180, 180, 100)
        end
    end
end

Events.OnPlayerUpdate.Add(onPlayerUpdate)

-- ---------------------------------------------------------------------------
-- Restore pending test from ModData on game load
-- ---------------------------------------------------------------------------
local function onGameStart()
    local player = getPlayer()
    if not player then return end

    local modData = player:getModData()
    if modData.KnoxDetectionKit_resultReady then
        pendingTest = {
            readyAt = modData.KnoxDetectionKit_resultReady,
            infected = modData.KnoxDetectionKit_infected == 1,
            lastReminderHour = -1,
        }
        print(TAG .. " Restored pending test from ModData")
    end
end

Events.OnGameStart.Add(onGameStart)

-- ---------------------------------------------------------------------------
-- Clear pending test on player death
-- ---------------------------------------------------------------------------
local function onPlayerDeath(player)
    if not pendingTest then return end

    print(TAG .. " Player died, clearing pending test")
    pendingTest = nil

    local modData = player:getModData()
    modData.KnoxDetectionKit_resultReady = nil
    modData.KnoxDetectionKit_infected = nil
end

Events.OnPlayerDeath.Add(onPlayerDeath)
