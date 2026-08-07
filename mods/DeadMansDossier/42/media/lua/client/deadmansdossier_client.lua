--
-- Dead Man's Dossier — Client Module
-- Context menu for dossier assembly, server command handling,
-- player-initiated stash location verification, and map markers.
--

require "deadmansdossier_shared"
require "timedactions/dmd_assembledossieraction"
require "timedactions/dmd_verifylocationaction"
require "timedactions/dmd_abandonmissionaction"
require "deadmansdossier_mapmarker"

local TAG = "[DeadMansDossier]"

print(TAG .. " Client module loaded")

-- ---------------------------------------------------------------------------
-- Localisation
--
-- Keys MUST start with `IGUI_` and live in Translate/<LOCALE>/IG_UI.json.
-- Translator.getTextInternal dispatches on the key PREFIX to a fixed set of
-- maps, each loaded from a hardcoded filename (Translator.java BY_NAME) —
-- there is NO per-mod translation file. An unrecognised prefix misses every map
-- and getText() returns the key string itself. `%1`/`%2` placeholders are
-- rewritten to Java format specifiers at load time, so getText(key, a, b) works.
-- ---------------------------------------------------------------------------
local function L(key, ...)
    return getText("IGUI_DMD_" .. key, ...)
end

--- Translated display name for a tier ("Police", "Military", …).
local function tierLabel(tierKey)
    if not tierKey or not DeadMansDossier.TIERS[tierKey] then return "?" end
    return L("Tier_" .. tierKey)
end

-- ---------------------------------------------------------------------------
-- Helper: count how many pages the player has for a given tier
-- ---------------------------------------------------------------------------
local function countOwnedPages(player, tierKey)
    local tier = DeadMansDossier.TIERS[tierKey]
    if not tier then return 0 end
    local inv = player:getInventory()
    local count = 0
    for _, pageType in ipairs(tier.pages) do
        if inv:containsTypeRecurse(pageType) then
            count = count + 1
        end
    end
    return count
end

-- ---------------------------------------------------------------------------
-- Helper: find which tier a page item belongs to
-- ---------------------------------------------------------------------------
local function getTierKeyForItem(item)
    local fullType = item:getFullType()
    return DeadMansDossier.PAGE_TO_TIER[fullType]
end

-- ---------------------------------------------------------------------------
-- Context menu: assemble dossier when right-clicking a page
-- ---------------------------------------------------------------------------
local function onAssembleClick(player, tierKey, item)
    print(TAG .. " Starting assemble for tier: " .. tostring(tierKey))
    local character = getSpecificPlayer(player)
    if not character then return end
    ISTimedActionQueue.add(DMD_AssembleDossierAction:new(character, tierKey, item))
end

local function onFillInventoryContextMenu(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    local addedTiers = {}

    -- items can be wrapped in an extra table layer
    for _, v in ipairs(items) do
        local item = v
        if type(v) == "table" then
            item = v.items[1]
        end

        if item and item.getFullType then
            local tierKey = getTierKeyForItem(item)
            if tierKey and not addedTiers[tierKey] then
                addedTiers[tierKey] = true
                local tier = DeadMansDossier.TIERS[tierKey]
                local ownedCount = countOwnedPages(player, tierKey)
                local totalPages = #tier.pages
                local allPresent = (ownedCount == totalPages)
                print(TAG .. " Right-clicked page: " .. item:getFullType() .. ", tier: " .. tierKey
                    .. ", pages: " .. ownedCount .. "/" .. totalPages)
                if allPresent then
                    context:addOption(L("Assemble", tierLabel(tierKey)), playerNum, onAssembleClick, tierKey, item)
                else
                    local label = L("AssembleIncomplete", tierLabel(tierKey), ownedCount, totalPages)
                    local option = context:addOption(label, nil)
                    option.notAvailable = true
                end
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryContextMenu)

-- ---------------------------------------------------------------------------
-- Proximity hint color mapping
-- ---------------------------------------------------------------------------
local HINT_COLORS = {
    veryclose = { r = 255, g = 50,  b = 50  },  -- red
    warm      = { r = 255, g = 150, b = 50  },  -- orange
    nearby    = { r = 255, g = 255, b = 50  },  -- yellow
}

-- ---------------------------------------------------------------------------
-- Server command listener: handle results from the server
-- ---------------------------------------------------------------------------
local function onServerCommand(module, command, args)
    if module ~= DeadMansDossier.MOD_ID then return end

    -- PZ drops empty tables during network serialization, so a command sent
    -- with {} arrives here as nil. Every branch below indexes args directly,
    -- so normalise before any of them run.
    args = args or {}

    local player = getPlayer()
    if not player then return end

    print(TAG .. " Received server command: " .. tostring(command))

    if command == DeadMansDossier.CMD_ASSEMBLE_RESULT then
        print(TAG .. " AssembleResult: success=" .. tostring(args.success)
            .. ", stash=" .. tostring(args.stashLabel or args.message or ""))
        if args.success then
            -- Remove consumed pages from local inventory (server already removed them
            -- server-side; we sync the client here to avoid sendRemoveItemFromContainer
            -- which crashes for deeply nested containers)
            local tier = args.tierKey and DeadMansDossier.TIERS[args.tierKey]
            if tier then
                local inv = player:getInventory()
                for _, pageType in ipairs(tier.pages) do
                    local page = inv:getFirstTypeRecurse(pageType)
                    if page then
                        local container = page:getContainer() or inv
                        container:Remove(page)
                    end
                end
            end
            local stashLabel = args.stashLabel or "Unknown"
            HaloTextHelper.addTextWithArrow(player, L("StashLocated", stashLabel), true, 0, 255, 0)
            -- Add map marker for the stash
            if args.tierKey and args.stashX and args.stashY then
                DeadMansDossier.addStashMarker(args.tierKey, args.stashX, args.stashY, args.stashLabel)
            end
        else
            -- The server sends a message KEY, not text, so each player sees the
            -- failure in their own client locale rather than the server's.
            local msg = args.messageKey and L(args.messageKey) or L("AssembleFail")
            HaloTextHelper.addTextWithArrow(player, msg, true, 255, 50, 50)
        end

    elseif command == DeadMansDossier.CMD_REWARD_GRANTED then
        print(TAG .. " RewardGranted: tier=" .. tostring(args.tierKey) .. ", hasMoreMissions=" .. tostring(args.hasMoreMissions))
        -- Remove consumed dossier from local inventory (server already removed it)
        local tier = args.tierKey and DeadMansDossier.TIERS[args.tierKey]
        if tier then
            local inv = player:getInventory()
            local dossier = inv:getFirstTypeRecurse(tier.result)
            if dossier then
                local container = dossier:getContainer() or inv
                container:Remove(dossier)
            end
        end
        HaloTextHelper.addTextWithArrow(player, L("RewardGranted"), true, 255, 215, 0)
        -- Remove map marker for completed mission
        if args.tierKey then
            DeadMansDossier.removeStashMarker(args.tierKey)
        end

    elseif command == DeadMansDossier.CMD_NOT_CLOSE then
        print(TAG .. " Not close enough to any stash")
        HaloTextHelper.addTextWithArrow(player, L("NotCloseEnough"), true, 255, 150, 50)
        -- Restore any missing map markers from mission data
        if args.missions then
            for _, m in ipairs(args.missions) do
                if m.tierKey and m.stashX and m.stashY and not DeadMansDossier.activeMarkers[m.tierKey] then
                    DeadMansDossier.addStashMarker(m.tierKey, m.stashX, m.stashY, m.stashLabel)
                    print(TAG .. " Restored missing marker for " .. m.tierKey)
                end
            end
        end

    elseif command == DeadMansDossier.CMD_PROXIMITY_HINT then
        local band = args.band
        local tierKey = args.tierKey or "Unknown"
        local label = tierLabel(tierKey)
        local color = HINT_COLORS[band] or { r = 255, g = 150, b = 50 }
        local msg
        if band == "veryclose" then
            msg = L("ProximityVeryClose", label)
        elseif band == "warm" then
            msg = L("ProximityWarm", label)
        elseif band == "nearby" then
            msg = L("ProximityNearby", label)
        else
            msg = L("NotCloseEnough")
        end
        print(TAG .. " Proximity hint: band=" .. tostring(band) .. ", tier=" .. tierKey)
        HaloTextHelper.addTextWithArrow(player, msg, true, color.r, color.g, color.b)
        -- Restore map marker if missing
        if tierKey ~= "Unknown" and args.stashX and args.stashY and not DeadMansDossier.activeMarkers[tierKey] then
            DeadMansDossier.addStashMarker(tierKey, args.stashX, args.stashY, args.stashLabel)
            print(TAG .. " Restored missing marker for " .. tierKey)
        end

    elseif command == DeadMansDossier.CMD_ABANDON_RESULT then
        print(TAG .. " AbandonResult: success=" .. tostring(args.success) .. ", tier=" .. tostring(args.tierKey))
        if args.success then
            -- Remove dossier from local inventory
            local tier = args.tierKey and DeadMansDossier.TIERS[args.tierKey]
            if tier then
                local inv = player:getInventory()
                local dossier = inv:getFirstTypeRecurse(tier.result)
                if dossier then
                    local container = dossier:getContainer() or inv
                    container:Remove(dossier)
                end
            end
            -- Remove map marker
            if args.tierKey then
                DeadMansDossier.removeStashMarker(args.tierKey)
            end
            HaloTextHelper.addTextWithArrow(player, L("MissionAbandoned", tierLabel(args.tierKey)), true, 200, 200, 200)
        else
            local msg = args.messageKey and L(args.messageKey) or L("AbandonFail")
            HaloTextHelper.addTextWithArrow(player, msg, true, 255, 50, 50)
        end

    elseif command == DeadMansDossier.CMD_SYNC_MISSIONS then
        print(TAG .. " Received mission sync")
        local missionList = args.missions
        if missionList then
            for _, m in ipairs(missionList) do
                if m.tierKey and m.stashX and m.stashY then
                    DeadMansDossier.addStashMarker(m.tierKey, m.stashX, m.stashY, m.stashLabel)
                end
            end
            print(TAG .. " Restored " .. #missionList .. " map marker(s)")
        end
        -- Clear pending sync flag so View Stash Map knows if sync succeeded
        if DeadMansDossier._pendingMapSync then
            local syncTier = DeadMansDossier._pendingMapSync
            if DeadMansDossier.activeMarkers[syncTier] then
                -- Sync restored the marker — clear flag
                DeadMansDossier._pendingMapSync = nil
            end
            -- If marker still missing after sync, flag stays so next click shows "lost" message
        end

    elseif command == DeadMansDossier.CMD_MISSION_UPDATE then
        print(TAG .. " MissionUpdate: hasActiveMission=" .. tostring(args.hasActiveMission))

    elseif command == DeadMansDossier.CMD_TEST_DISTRIBUTIONS_RESULT then
        -- Test-only: store distribution check result for test assertion
        DeadMansDossier._testDistResult = args
        print(TAG .. " TestDistributionsResult: success=" .. tostring(args.success)
            .. ", missing=" .. tostring(args.missingCount))

    elseif command == DeadMansDossier.CMD_TEST_CUSTOM_REWARDS_RESULT then
        -- Test-only: store custom rewards test result for test assertion
        DeadMansDossier._testCustomRewardsResult = args
        print(TAG .. " TestCustomRewardsResult: success=" .. tostring(args.success)
            .. ", errors=" .. tostring(args.errorCount))
    end
end

Events.OnServerCommand.Add(onServerCommand)

-- ---------------------------------------------------------------------------
-- Completed dossier context menu: "Verify Stash Location" + "View Stash Map"
-- ---------------------------------------------------------------------------
local function onVerifyLocationClick(playerNum, item)
    local character = getSpecificPlayer(playerNum)
    if not character then return end
    ISTimedActionQueue.add(DMD_VerifyLocationAction:new(character, item))
end

local function onViewStashMapClick(playerNum, tierKey)
    if DeadMansDossier.activeMarkers[tierKey] then
        DeadMansDossier.openStashMap(playerNum, tierKey)
    else
        -- Marker missing (e.g. after server restart) — request sync, inform player
        -- If mission data was also lost (rollback), the sync will return empty and
        -- the marker won't be restored. The player can still Abandon to discard.
        if not DeadMansDossier._pendingMapSync then
            DeadMansDossier._pendingMapSync = tierKey
            print(TAG .. " View Stash Map: marker missing for " .. tierKey .. ", requesting mission sync")
            local player = getSpecificPlayer(playerNum)
            sendClientCommand(
                player,
                DeadMansDossier.MOD_ID,
                DeadMansDossier.CMD_REQUEST_MISSIONS,
                {}
            )
            if player then
                HaloTextHelper.addTextWithArrow(player, L("RestoringMarker"), true, 200, 200, 200)
            end
        else
            -- Already tried syncing and marker still missing — mission data is gone
            DeadMansDossier._pendingMapSync = nil
            local player = getSpecificPlayer(playerNum)
            if player then
                HaloTextHelper.addTextWithArrow(player, L("MarkerLost"), true, 255, 150, 50)
            end
        end
    end
end

local function onAbandonMissionClick(playerNum, tierKey, item)
    local character = getSpecificPlayer(playerNum)
    if not character then return end
    ISTimedActionQueue.add(DMD_AbandonMissionAction:new(character, tierKey, item))
end

local function onFillInventoryContextMenuForDossier(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player then return end

    -- Check if any selected item is a completed dossier
    for _, v in ipairs(items) do
        local item = v
        if type(v) == "table" then
            item = v.items[1]
        end

        if item and item.getFullType then
            for tierKey, tier in pairs(DeadMansDossier.TIERS) do
                if item:getFullType() == tier.result then
                    -- "View Stash Map" — opens world map centered on stash
                    -- Always show; if marker is missing, request sync from server
                    context:addOption(L("ViewMap", tierLabel(tierKey)), playerNum, onViewStashMapClick, tierKey)
                    -- "Verify Stash Location" — proximity check with progress bar
                    context:addOption(L("VerifyLocation", tierLabel(tierKey)), playerNum, onVerifyLocationClick, item)
                    -- "Abandon Mission" — discard dossier and clear mission
                    context:addOption(L("AbandonMission", tierLabel(tierKey)), playerNum, onAbandonMissionClick, tierKey, item)
                    return  -- one set of options is enough
                end
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryContextMenuForDossier)

-- ---------------------------------------------------------------------------
-- Player death handler: notify server to clear missions, clear local markers.
-- OnPlayerDeath only fires client-side in MP, so we send a command to the
-- server which is authoritative over mission data in GlobalModData.
-- ---------------------------------------------------------------------------
local function onPlayerDeath(player)
    print(TAG .. " Player died, notifying server to clear missions")
    sendClientCommand(
        player,
        DeadMansDossier.MOD_ID,
        DeadMansDossier.CMD_PLAYER_DIED,
        {}
    )
    -- Clear all client-side map markers
    for tierKey, _ in pairs(DeadMansDossier.activeMarkers) do
        DeadMansDossier.removeStashMarker(tierKey)
    end
end

Events.OnPlayerDeath.Add(onPlayerDeath)

-- ---------------------------------------------------------------------------
-- On first tick: request active missions from server for map marker persistence.
-- We use OnTick instead of OnCreatePlayer/OnGameStart because sendClientCommand
-- requires GameClient.ingame == true, which is only set in IngameState.UpdateStuff()
-- right before OnTick fires. During OnCreatePlayer/OnGameStart, ingame is still
-- false and sendClientCommand silently routes to SinglePlayerClient (a no-op in MP).
-- ---------------------------------------------------------------------------
local missionSyncRequested = false
local missionSyncTickRegistered = false
local onTickRequestMissions  -- forward declaration (add/remove reference it)

local function addMissionSyncTick()
    if missionSyncTickRegistered then return end
    missionSyncTickRegistered = true
    Events.OnTick.Add(onTickRequestMissions)
end

local function removeMissionSyncTick()
    if not missionSyncTickRegistered then return end
    missionSyncTickRegistered = false
    Events.OnTick.Remove(onTickRequestMissions)
end

onTickRequestMissions = function()
    if missionSyncRequested then
        removeMissionSyncTick()
        return
    end

    -- No local player yet: keep waiting rather than firing into the void.
    local player = getPlayer()
    if not player then return end

    missionSyncRequested = true
    removeMissionSyncTick()

    print(TAG .. " Requesting active missions for map markers (first tick)")
    sendClientCommand(
        player,
        DeadMansDossier.MOD_ID,
        DeadMansDossier.CMD_REQUEST_MISSIONS,
        {}
    )
end

addMissionSyncTick()

-- Re-arm on returning to the main menu (i.e. disconnecting). Without this,
-- missionSyncRequested stays true for the lifetime of the game process, so a
-- disconnect → reconnect within one session never re-requests missions and the
-- stash map markers silently never come back.
local function onMainMenuEnterResetSync()
    missionSyncRequested = false
    for tierKey, _ in pairs(DeadMansDossier.activeMarkers) do
        DeadMansDossier.removeStashMarker(tierKey)
    end
    addMissionSyncTick()
    print(TAG .. " Client mission-sync state reset")
end

Events.OnMainMenuEnter.Add(onMainMenuEnterResetSync)
